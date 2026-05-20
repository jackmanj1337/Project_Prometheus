extends RefCounted
# Sole writer of Camera2D.position in production code (B4 / code review 2026-05-19 §4).
# Before extraction, three call sites wrote the camera directly — GameMap.tscn's
# initial placement, GameMap._on_ai_unit_acting (#7), and MapCursor._scroll_camera_
# if_needed — making any "where does the camera go next?" change a three-place
# search. This class owns every write; readers still touch Camera2D.position
# directly via get_camera().
#
# Built once by GameMap and injected into MapCursor.setup() so the cursor's scroll
# math can use it without each layer poking Camera2D directly. Pure RefCounted —
# no scene-tree node of its own — mirrors MapCursor's existing RefCounted-slice
# pattern (MapCursorTargeting / Selection / Input).
#
# All methods are no-ops when _camera or _grid is null so the controller can be
# safely held across scene unloads and unit-test setup steps.

const GameConstants = preload("res://scripts/shared/GameConstants.gd")

var _camera: Camera2D = null
var _grid: Node = null  # GridManager — typed as Node to avoid a cyclic preload

# PT4 #2: snapshot of the player's view at the moment the player phase ends,
# restored at the start of the next player phase. AI-phase tracking (#7) pans
# the camera onto each acting enemy, which would otherwise leave the camera
# adrift wherever the last enemy stood.
var _saved_position: Vector2 = Vector2.ZERO
var _has_saved: bool = false


func setup(camera: Camera2D, grid: Node) -> void:
	_camera = camera
	_grid = grid


# Returns the underlying Camera2D for reads (tests, viewport queries). Production
# code MUST NOT write to its position — call the methods below.
func get_camera() -> Camera2D:
	return _camera


# Smoothing on = camera glides toward writes; off = instant snap. GameMap toggles
# this on phase change so AI tracking is animated and player-phase scroll is snappy.
func set_smoothing(enabled: bool) -> void:
	if _camera != null:
		_camera.position_smoothing_enabled = enabled


# Centres the view on a world position. Use for instant placement (GameMap init).
func center_at(world_pos: Vector2) -> void:
	if _camera != null:
		_camera.position = world_pos


# Centres on a tile's centre (offsets by half a tile from tile_to_world's TL).
# Used by AI camera tracking and any caller that thinks in tiles, not pixels.
func center_on_tile(tile: Vector2i) -> void:
	if _camera == null or _grid == null:
		return
	var half := Vector2(GameConstants.TILE_SIZE, GameConstants.TILE_SIZE) * 0.5
	_camera.position = _grid.tile_to_world(tile) + half


# Pans the view so `cursor_tile` is no closer than `edge_buffer` tiles to any edge.
# Clamps the resulting view to the map bounds so it never shows blank space past
# the map. Was MapCursor._scroll_camera_if_needed; same math, new home.
func keep_cursor_in_view(cursor_tile: Vector2i, edge_buffer: int) -> void:
	if _camera == null or _grid == null:
		return
	var view: Vector2 = _camera.get_viewport().get_visible_rect().size
	var tiles_w: int = int(view.x / GameConstants.TILE_SIZE)
	var tiles_h: int = int(view.y / GameConstants.TILE_SIZE)
	# Camera2D.position is the view CENTRE (anchor_mode = DRAG_CENTER). Convert to
	# the top-left tile so the edge-margin checks are correct — treating centre
	# as top-left is the historical bug that let the cursor scroll off (playtest 1 #2).
	var tl: Vector2i = _grid.world_to_tile(_camera.position - view * 0.5)
	if cursor_tile.x < tl.x + edge_buffer:
		tl.x = cursor_tile.x - edge_buffer
	elif cursor_tile.x > tl.x + tiles_w - edge_buffer - 1:
		tl.x = cursor_tile.x - tiles_w + edge_buffer + 1
	if cursor_tile.y < tl.y + edge_buffer:
		tl.y = cursor_tile.y - edge_buffer
	elif cursor_tile.y > tl.y + tiles_h - edge_buffer - 1:
		tl.y = cursor_tile.y - tiles_h + edge_buffer + 1
	tl.x = clamp(tl.x, 0, max(0, _grid.map_width - tiles_w))
	tl.y = clamp(tl.y, 0, max(0, _grid.map_height - tiles_h))
	_camera.position = _grid.tile_to_world(tl) + view * 0.5


# Clamps a tile to the camera's currently visible tile rect. Used by the
# mouse-cursor handler so a stray mouse move can't push the cursor off-screen
# (playtest 3 #7). No-op when camera/grid unavailable.
func clamp_tile_to_view(tile: Vector2i) -> Vector2i:
	if _camera == null or _grid == null:
		return tile
	var view: Vector2 = _camera.get_viewport().get_visible_rect().size
	var tiles_w: int = int(view.x / GameConstants.TILE_SIZE)
	var tiles_h: int = int(view.y / GameConstants.TILE_SIZE)
	var tl: Vector2i = _grid.world_to_tile(_camera.position - view * 0.5)
	tile.x = clampi(tile.x, tl.x, tl.x + tiles_w - 1)
	tile.y = clampi(tile.y, tl.y, tl.y + tiles_h - 1)
	return tile


# Saves the current camera position. Restored at the next phase change back to
# PLAYER so AI-phase tracking doesn't drag the player to a different view (PT4 #2).
func save_view() -> void:
	if _camera != null:
		_saved_position = _camera.position
		_has_saved = true


# Restores the saved view. Returns true if a restore happened, false if save_view
# has never been called (e.g. very first player phase — GameMap's initial placement
# is the right source then).
func restore_view() -> bool:
	if not _has_saved or _camera == null:
		return false
	_camera.position = _saved_position
	return true
