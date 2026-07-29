extends SceneTree
# Run once with:
#   godot --headless --path /workspace --script res://scripts/tools/generate_placeholder_assets.gd
# Generates solid-color PNGs for terrain and overlay tiles, plus unit/cursor sprites.
# Re-running overwrites — safe to invoke after edits.

# Preload instead of autoload access — _init() runs before autoloads are live.
const GameConstants = preload("res://scripts/shared/GameConstants.gd")

# Terrain palette (subjective; readable on a default editor background)
const TERRAIN_COLORS := {
	"plain": Color(0.55, 0.78, 0.40, 1.0),  # green
	"forest": Color(0.20, 0.50, 0.20, 1.0),  # dark green
	"mountain": Color(0.45, 0.35, 0.25, 1.0),  # brown
	"fort": Color(0.70, 0.65, 0.55, 1.0),  # tan
	"sea": Color(0.20, 0.40, 0.85, 1.0),  # blue
	"desert": Color(0.95, 0.85, 0.55, 1.0),  # sand
	"wall": Color(0.20, 0.20, 0.20, 1.0),  # dark gray
}

# Overlay tiles — semi-transparent
const OVERLAY_COLORS := {
	"blue": Color(0.30, 0.50, 1.00, 0.45),  # movement
	"red": Color(1.00, 0.30, 0.30, 0.45),  # attack
	"green": Color(1.00, 0.55, 0.10, 0.45),  # heal — orange for contrast (#6)
	"dark_red": Color(0.55, 0.10, 0.10, 0.45),  # enemy danger (faction threat, src 3)
	# Watch-set threat (src 4, [TUR-2]) — a darker, more opaque red so a hand-picked
	# enemy's threat reads distinctly INSIDE the broader dark_red faction cloud.
	"darker_red": Color(0.32, 0.00, 0.00, 0.60),
}

const OVERLAY_SHARED_BORDER_PAIRS := {
	"blue_on_dark_red": ["dark_red", "blue"],
	"red_on_dark_red": ["dark_red", "red"],
	"green_on_dark_red": ["dark_red", "green"],
	"blue_on_darker_red": ["darker_red", "blue"],
	"red_on_darker_red": ["darker_red", "red"],
	"green_on_darker_red": ["darker_red", "green"],
}

const PERIMETER_THREAT_SOURCES := ["dark_red", "darker_red"]
const PERIMETER_MASK_COUNT := 15
const PERIMETER_EDGE_TOP := 1
const PERIMETER_EDGE_RIGHT := 2
const PERIMETER_EDGE_BOTTOM := 4
const PERIMETER_EDGE_LEFT := 8
const PERIMETER_COLOR := Color(1.0, 0.88, 0.25, 0.95)

# Unit sprite colors (simple rectangle by team for now)
const UNIT_COLORS := {
	"player": Color(0.30, 0.55, 0.95, 1.0),  # blue
	"enemy": Color(0.95, 0.35, 0.35, 1.0),  # red
}


func _init() -> void:
	for name in TERRAIN_COLORS.keys():
		_save_solid_png("res://assets/sprites/terrain/%s.png" % name, TERRAIN_COLORS[name])
	for name in OVERLAY_COLORS.keys():
		_save_solid_png("res://assets/sprites/ui/overlay_%s.png" % name, OVERLAY_COLORS[name])
	for name in OVERLAY_SHARED_BORDER_PAIRS.keys():
		var pair: Array = OVERLAY_SHARED_BORDER_PAIRS[name]
		_save_shared_border_png(
			"res://assets/sprites/ui/overlay_%s.png" % name,
			OVERLAY_COLORS[pair[0]],
			OVERLAY_COLORS[pair[1]]
		)
	for name in PERIMETER_THREAT_SOURCES:
		for mask in range(1, PERIMETER_MASK_COUNT + 1):
			_save_perimeter_png(
				"res://assets/sprites/ui/overlay_%s_perimeter_%02d.png" % [name, mask],
				OVERLAY_COLORS[name],
				mask
			)
	for name in UNIT_COLORS.keys():
		_save_solid_png("res://assets/sprites/units/unit_%s.png" % name, UNIT_COLORS[name])
	# Cursor: white outlined hollow square
	_save_cursor_png("res://assets/sprites/cursor/cursor.png")
	print("Placeholder assets generated.")
	quit()


func _save_solid_png(path: String, color: Color) -> void:
	var img := Image.create(
		GameConstants.TILE_SIZE, GameConstants.TILE_SIZE, false, Image.FORMAT_RGBA8
	)
	img.fill(color)
	var abs_path := ProjectSettings.globalize_path(path)
	img.save_png(abs_path)


# Combined shared-cell prototype tile: the center keeps the threat colour while
# the movement/target colour is a strong border, so one TileMapLayer can show
# both meanings on the same tile ([MRD-7]).
func _save_shared_border_png(path: String, fill_color: Color, border_color: Color) -> void:
	var img := Image.create(
		GameConstants.TILE_SIZE, GameConstants.TILE_SIZE, false, Image.FORMAT_RGBA8
	)
	img.fill(fill_color)
	var border: int = 6
	for x in GameConstants.TILE_SIZE:
		for y in GameConstants.TILE_SIZE:
			if (
				x < border
				or x >= GameConstants.TILE_SIZE - border
				or y < border
				or y >= GameConstants.TILE_SIZE - border
			):
				img.set_pixel(x, y, Color(border_color.r, border_color.g, border_color.b, 0.85))
	var abs_path := ProjectSettings.globalize_path(path)
	img.save_png(abs_path)


func _save_perimeter_png(path: String, fill_color: Color, mask: int) -> void:
	var img := Image.create(
		GameConstants.TILE_SIZE, GameConstants.TILE_SIZE, false, Image.FORMAT_RGBA8
	)
	img.fill(fill_color)
	var border: int = 4
	for x in GameConstants.TILE_SIZE:
		for y in GameConstants.TILE_SIZE:
			var draw := false
			if (mask & PERIMETER_EDGE_TOP) != 0 and y < border:
				draw = true
			if (mask & PERIMETER_EDGE_RIGHT) != 0 and x >= GameConstants.TILE_SIZE - border:
				draw = true
			if (mask & PERIMETER_EDGE_BOTTOM) != 0 and y >= GameConstants.TILE_SIZE - border:
				draw = true
			if (mask & PERIMETER_EDGE_LEFT) != 0 and x < border:
				draw = true
			if draw:
				img.set_pixel(x, y, PERIMETER_COLOR)
	var abs_path := ProjectSettings.globalize_path(path)
	img.save_png(abs_path)


# Hollow 4-pixel-thick white outline; transparent center
func _save_cursor_png(path: String) -> void:
	var img := Image.create(
		GameConstants.TILE_SIZE, GameConstants.TILE_SIZE, false, Image.FORMAT_RGBA8
	)
	img.fill(Color(0, 0, 0, 0))
	var border: int = 3
	for x in GameConstants.TILE_SIZE:
		for y in GameConstants.TILE_SIZE:
			if (
				x < border
				or x >= GameConstants.TILE_SIZE - border
				or y < border
				or y >= GameConstants.TILE_SIZE - border
			):
				img.set_pixel(x, y, Color(1, 1, 1, 1))
	var abs_path := ProjectSettings.globalize_path(path)
	img.save_png(abs_path)
