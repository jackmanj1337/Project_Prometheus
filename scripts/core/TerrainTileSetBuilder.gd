class_name TerrainTileSetBuilder extends RefCounted
# Builds the TileSet a map paints with, from the engine's pre-generated sources plus
# whatever art the active pack introduced ([TER-1], [TER-2], owner decisions 2026-08-01).
#
# Why this exists. Rendering used to be a four-way lock: `generate_tilesets.gd` wrote
# one atlas source per terrain with `source_id == terrain index`, `GameMap._paint_terrain`
# resolved grid char -> terrain id -> `tile_source_id` -> `set_cell`, and
# `GridManager.get_terrain_at` read the terrain back off the painted tile's custom
# data. Grid char, terrain id, tile source and stat block were one indivisible thing,
# so a pack could retune terrain numbers but could never add art — the tileset was
# baked into the engine PCK and a pack ships JSON plus media, never a `TileSet`.
#
# This breaks the lock at exactly one point: sources are appended at activation. The
# custom data still carries the TERRAIN id, so `get_terrain_at` and every id-matching
# consumer (AI scoring, tags, tests) are untouched — which is what makes a decorative
# variant cost one atlas source rather than a new terrain identity.
#
# The pack's media is loaded from an absolute path rather than `load()`ed, because pack
# art is not an imported `res://` resource: it arrives as bytes the installer verified
# against a digest.

const GameConstants = preload("res://scripts/shared/GameConstants.gd")

# Name of the custom-data layer `generate_tilesets.gd` writes and
# `GridManager.get_terrain_at` reads. Duplicated as a constant here rather than
# hardcoded at three call sites.
const TERRAIN_TYPE_LAYER := "terrain_type"


# What a build produced. `source_ids` maps variant id -> the source to paint with, so
# `GameMap` never has to know which variants came from the engine and which were built
# here. Errors are collected rather than pushed, so activation can refuse the pack
# atomically instead of half-painting a map.
class Result:
	extends RefCounted
	var tile_set: TileSet = null
	var source_ids: Dictionary = {}
	var errors: Array[String] = []

	func valid() -> bool:
		return errors.is_empty()


# `assets` is the adapter's resolved media map: logical id -> {path, decoded_type}.
# Pass `{}` for the no-pack case, which then simply reuses every engine source.
static func build(registry: TerrainRegistry, base_tile_set: TileSet, assets: Dictionary) -> Result:
	var result := Result.new()
	if base_tile_set == null:
		result.errors.append("TerrainTileSetBuilder: no base tileset to build from")
		return result
	# Duplicated so a failed activation cannot leave the engine's own tileset mutated
	# with a previous pack's sources. `true` copies the atlas sources, not just the
	# TileSet shell.
	var tile_set: TileSet = base_tile_set.duplicate(true)
	result.tile_set = tile_set

	var next_source_id := _first_free_source_id(tile_set)
	for variant_id in registry.variant_ids():
		var engine_source := registry.variant_tile_source_id(variant_id)
		if engine_source >= 0:
			# Pre-generated: the engine already stamped its terrain_type, and the
			# variant shares that terrain by construction.
			result.source_ids[variant_id] = engine_source
			continue
		var asset_id := registry.variant_tile_asset_id(variant_id)
		var record: Variant = assets.get(asset_id, null)
		if not record is Dictionary:
			# Coherence already refuses a variant with neither source nor asset id, so
			# reaching here means the id was authored but the pack did not carry it.
			result.errors.append(
				(
					(
						"TerrainTileSetBuilder: terrain variant '%s' names asset '%s', which the "
						+ "active pack does not provide"
					)
					% [variant_id, asset_id]
				)
			)
			continue
		var texture := _load_pack_texture(String((record as Dictionary).get("path", "")))
		if texture == null:
			result.errors.append(
				(
					(
						"TerrainTileSetBuilder: terrain variant '%s' asset '%s' could not be "
						+ "decoded as an image"
					)
					% [variant_id, asset_id]
				)
			)
			continue
		var source := _atlas_source_for(texture)
		if source == null:
			(
				result
				. errors
				. append(
					(
						(
							"TerrainTileSetBuilder: terrain variant '%s' asset '%s' is smaller than one "
							+ "%dx%d tile"
						)
						% [variant_id, asset_id, GameConstants.TILE_SIZE, GameConstants.TILE_SIZE]
					)
				)
			)
			continue
		# add_source must precede set_custom_data: TileData resolves the custom-data
		# layer by name through a back-reference to the TileSet, which does not exist
		# until the source is attached. Same ordering generate_tilesets.gd documents.
		tile_set.add_source(source, next_source_id)
		var tile_data := source.get_tile_data(Vector2i.ZERO, 0)
		if tile_data != null:
			tile_data.set_custom_data(TERRAIN_TYPE_LAYER, registry.variant_terrain(variant_id))
		result.source_ids[variant_id] = next_source_id
		next_source_id += 1
	return result


# Appending starts above every id the base tileset already uses, so a pack source can
# never shadow an engine one.
static func _first_free_source_id(tile_set: TileSet) -> int:
	var highest := -1
	for i in tile_set.get_source_count():
		highest = maxi(highest, tile_set.get_source_id(i))
	return highest + 1


# Pack art is verified bytes on disk, not an imported resource, so it is decoded
# explicitly. Returns null when the file is missing or is not a decodable image —
# the caller turns that into a diagnostic naming the variant.
static func _load_pack_texture(path: String) -> Texture2D:
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	if image.load(path) != OK or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


# One tile per source, matching the engine's generated layout. A texture smaller than
# a tile has no valid region, which is a real authoring error rather than something to
# silently letterbox.
static func _atlas_source_for(texture: Texture2D) -> TileSetAtlasSource:
	var tile := Vector2i(GameConstants.TILE_SIZE, GameConstants.TILE_SIZE)
	if texture.get_width() < tile.x or texture.get_height() < tile.y:
		return null
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = tile
	source.create_tile(Vector2i.ZERO)
	return source
