extends SceneTree
# Run with:
#   godot --headless --path /workspace --import
#   godot --headless --path /workspace --script res://scripts/tools/generate_tilesets.gd
# Generates terrain_tileset.tres (with terrain_type custom data) and overlay_tileset.tres.
# Each tile is its own TileSetAtlasSource so the source_id == terrain index.

const TILE_SIZE: int = 64

# Source ID order matters: it's how GridManager / GameMap reference tiles.
const TERRAIN_SOURCES := [
	"plain", "forest", "mountain", "fort", "sea", "desert", "wall"
]
const OVERLAY_SOURCES := [
	"blue", "red", "green", "dark_red"
]


func _init() -> void:
	_make_terrain_tileset()
	_make_overlay_tileset()
	print("TileSets written.")
	quit()


func _make_terrain_tileset() -> void:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	# Custom data layer 0: "terrain_type" (String). GridManager reads this.
	tileset.add_custom_data_layer(0)
	tileset.set_custom_data_layer_name(0, "terrain_type")
	tileset.set_custom_data_layer_type(0, TYPE_STRING)

	for i in TERRAIN_SOURCES.size():
		var name: String = TERRAIN_SOURCES[i]
		var tex: Texture2D = load("res://assets/sprites/terrain/%s.png" % name)
		var src := TileSetAtlasSource.new()
		src.texture = tex
		src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
		src.create_tile(Vector2i.ZERO)
		# add_source must come BEFORE set_custom_data — TileData needs a back-reference
		# to the TileSet to resolve the custom_data layer index by name
		tileset.add_source(src, i)
		var tile_data := src.get_tile_data(Vector2i.ZERO, 0)
		tile_data.set_custom_data("terrain_type", name)

	ResourceSaver.save(tileset, "res://assets/terrain_tileset.tres")


func _make_overlay_tileset() -> void:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for i in OVERLAY_SOURCES.size():
		var name: String = OVERLAY_SOURCES[i]
		var tex: Texture2D = load("res://assets/sprites/ui/overlay_%s.png" % name)
		var src := TileSetAtlasSource.new()
		src.texture = tex
		src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
		src.create_tile(Vector2i.ZERO)
		tileset.add_source(src, i)
	ResourceSaver.save(tileset, "res://assets/overlay_tileset.tres")
