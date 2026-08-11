extends SceneTree
# TerrainTileSetBuilder is the machinery [TER-1] and [TER-2] share: a decorative
# variant needs its own tile source for exactly the same reason a pack-introduced
# terrain does. Before it existed, rendering was a four-way lock — grid char, terrain
# id, tile source and stat block were one indivisible thing baked into the engine's
# generated tileset — and that lock is why a pack could retune terrain numbers but
# never add art.
#
# The load-bearing assertion in this file is the custom-data one: an appended source
# must stamp the TERRAIN id, not the variant id, or GridManager.get_terrain_at would
# start reporting variants and every id-matching consumer (AI scoring, tags, tests)
# would break at once.

const TerrainRegistryScript = preload("res://scripts/core/TerrainRegistry.gd")
const TerrainTileSetBuilderScript = preload("res://scripts/core/TerrainTileSetBuilder.gd")
const GameConstantsScript = preload("res://scripts/shared/GameConstants.gd")

const BASE_TILESET_PATH := "res://assets/terrain_tileset.tres"


func _init() -> void:
	print("=== Terrain TileSet Builder Test ===")
	var passed := 0
	var failed := 0

	var base: TileSet = load(BASE_TILESET_PATH)
	if base == null:
		print("FAIL could not load the engine tileset at %s" % BASE_TILESET_PATH)
		print("=== Results: 0 passed, 1 failed ===")
		quit(1)
		return

	# Written once and reused: pack art arrives as bytes on disk, not as an imported
	# res:// resource, which is why the builder decodes it explicitly.
	var tile_size: int = GameConstantsScript.TILE_SIZE
	var asset_path := _write_temp_tile(tile_size, Color(0.2, 0.6, 0.3))
	var tiny_path := _write_temp_tile(maxi(1, tile_size / 4), Color(1, 0, 0))

	# --- No pack: every engine source is reused exactly as generated ---
	var engine_only: TerrainRegistry = TerrainRegistryScript.engine_defaults()
	var plain_build = TerrainTileSetBuilderScript.build(engine_only, base, {})
	if (
		plain_build.valid()
		and int(plain_build.source_ids.get("forest", -1)) == engine_only.tile_source_id("forest")
		and plain_build.tile_set.get_source_count() == base.get_source_count()
	):
		print("OK  with no pack active every variant reuses its pre-generated engine source")
		passed += 1
	else:
		print(
			(
				"FAIL engine-only build: errors=%s ids=%s"
				% [plain_build.errors, plain_build.source_ids]
			)
		)
		failed += 1

	# --- [TER-1] a decorative variant gets its own source stamped with the SHARED id ---
	var throned: TerrainRegistry = TerrainRegistryScript.engine_defaults()
	(
		throned
		. apply_variant_document(
			{
				"id": "throne",
				"terrain": "fort",
				"grid_char": "H",
				"display_name": "Throne",
				"tile_asset_id": "throne_tile",
			}
		)
	)
	var assets := {"throne_tile": {"path": asset_path, "decoded_type": "image"}}
	var throne_build = TerrainTileSetBuilderScript.build(throned, base, assets)
	var throne_source := int(throne_build.source_ids.get("throne", -1))
	var stamped := ""
	if throne_build.valid() and throne_source >= 0:
		var source: TileSetSource = throne_build.tile_set.get_source(throne_source)
		if source is TileSetAtlasSource:
			var tile_data := (source as TileSetAtlasSource).get_tile_data(Vector2i.ZERO, 0)
			if tile_data != null:
				stamped = String(
					tile_data.get_custom_data(TerrainTileSetBuilderScript.TERRAIN_TYPE_LAYER)
				)
	if (
		throne_build.valid()
		# Appended above every engine id, so a pack source can never shadow one.
		and throne_source >= base.get_source_count()
		and throne_build.tile_set.get_source_count() == base.get_source_count() + 1
		# The whole point: the tile reports FORT.
		and stamped == "fort"
	):
		print("OK  a variant gets an appended source stamped with its shared terrain id")
		passed += 1
	else:
		print(
			(
				"FAIL variant source: valid=%s id=%d stamped='%s' errors=%s"
				% [throne_build.valid(), throne_source, stamped, throne_build.errors]
			)
		)
		failed += 1

	# The engine's own tileset must not be mutated by a build, or a failed activation
	# would leave the previous pack's sources attached to it.
	if base.get_source_count() == 7:
		print("OK  building does not mutate the engine's generated tileset")
		passed += 1
	else:
		print("FAIL engine tileset was mutated: %d sources" % base.get_source_count())
		failed += 1

	# --- [TER-2] a pack-introduced terrain paints from its own media ---
	var swamped: TerrainRegistry = TerrainRegistryScript.engine_defaults()
	(
		swamped
		. apply_document(
			{
				"id": "swamp",
				"grid_char": "P",
				"display_name": "Swamp",
				"tile_asset_id": "swamp_tile",
				"move_costs": {"infantry": 3},
			}
		)
	)
	var swamp_build = TerrainTileSetBuilderScript.build(
		swamped, base, {"swamp_tile": {"path": asset_path, "decoded_type": "image"}}
	)
	var swamp_stamped := ""
	var swamp_source := int(swamp_build.source_ids.get("swamp", -1))
	if swamp_build.valid() and swamp_source >= 0:
		var source: TileSetSource = swamp_build.tile_set.get_source(swamp_source)
		if source is TileSetAtlasSource:
			var tile_data := (source as TileSetAtlasSource).get_tile_data(Vector2i.ZERO, 0)
			if tile_data != null:
				swamp_stamped = String(
					tile_data.get_custom_data(TerrainTileSetBuilderScript.TERRAIN_TYPE_LAYER)
				)
	if swamp_build.valid() and swamp_stamped == "swamp":
		print("OK  a pack-introduced terrain builds a source that reports its own id ([TER-2])")
		passed += 1
	else:
		print(
			"FAIL introduced terrain: errors=%s stamped='%s'" % [swamp_build.errors, swamp_stamped]
		)
		failed += 1

	# --- Failure cases must be diagnosed, never silently painted as wall ---
	var missing_build = TerrainTileSetBuilderScript.build(swamped, base, {})
	var tiny_build = TerrainTileSetBuilderScript.build(
		swamped, base, {"swamp_tile": {"path": tiny_path, "decoded_type": "image"}}
	)
	var absent_build = TerrainTileSetBuilderScript.build(
		swamped, base, {"swamp_tile": {"path": "/nonexistent/nope.png", "decoded_type": "image"}}
	)
	if (
		not missing_build.valid()
		and not tiny_build.valid()
		and not absent_build.valid()
		# Each diagnostic names the variant, so an author can find the row.
		and missing_build.errors[0].contains("swamp")
		and tiny_build.errors[0].contains("swamp")
	):
		print("OK  unprovided, undersized, and missing art each fail with a named diagnostic")
		passed += 1
	else:
		print(
			(
				"FAIL art failure diagnostics: missing=%s tiny=%s absent=%s"
				% [missing_build.errors, tiny_build.errors, absent_build.errors]
			)
		)
		failed += 1

	DirAccess.remove_absolute(asset_path)
	DirAccess.remove_absolute(tiny_path)

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


# A real PNG on disk, because the builder decodes bytes rather than load()ing an
# imported resource — writing one is the only way to exercise the path it takes.
func _write_temp_tile(size: int, colour: Color) -> String:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(colour)
	var path := OS.get_user_data_dir().path_join(
		"test_terrain_tile_%d_%d.png" % [size, Time.get_ticks_usec()]
	)
	image.save_png(path)
	return path
