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

# PT4 #2: snapshot of each faction's camera view at the moment its phase ends,
# restored at the start of that faction's next phase. AI-phase tracking (#7)
# pans the camera onto each acting enemy, which would otherwise leave the
# camera adrift wherever the last enemy stood.
#
# Keyed by faction id so hotseat factions (M14 stage 5) each keep their own
# view across rounds — a hotseat green player resumes wherever they left off,
# and an intervening green phase no longer overwrites blue's saved view (code
# review 2026-06-09). save_view() / restore_view() called with no faction id
# stay back-compatible with pre-M14 callers and the test seam.
const _DEFAULT_FACTION_KEY := "blue"
var _saved_positions: Dictionary = {}

# Player-controlled map zoom (Display & Accessibility item 1). Discrete levels are
# presented in the Settings screen as a stepped slider and stepped with the
# scroll wheel / +/-/0 keys. Power-of-two-friendly common stops keep the pixel-snap
# (Rendering/2D/Snap) crisp at the usual zooms; 0.75/1.5/3 are available but shimmer
# slightly. ZOOM_LEVELS is the single source of truth — the slider sizes itself from
# get_zoom_count() and the persisted setting is an index into this array.
const ZOOM_LEVELS: Array[float] = [0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 4.0]
const DEFAULT_ZOOM_INDEX: int = 3  # 1.0× — the unchanged default view
var _zoom_index: int = DEFAULT_ZOOM_INDEX


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


# Pushes the camera's pending position/zoom into the viewport canvas transform NOW.
# Camera2D normally defers that update to the end of the frame, so code that reads
# screen positions (menu/preview anchoring, mouse->tile mapping) right after a
# camera write would compute against the PREVIOUS view — at high zoom the reframe
# moves the camera far, so the anchored panel landed visibly wrong until the next
# no-op zoom input re-ran the placement (V026-03/V026-04a, screenshots in
# archive/evidence 2026-07-04). Called after every write below that callers read
# synchronously.
func _flush_scroll() -> void:
	if _camera != null and _camera.is_inside_tree():
		_camera.force_update_scroll()


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


# World-space size of the visible region. At zoom 1 this equals the viewport
# pixel size; at any other Camera2D.zoom the visible world span is
# viewport_px / zoom (a larger zoom magnifies, so fewer world units are shown).
# Every tile/pan calculation below works in WORLD units, so it must size the view
# through here — using raw viewport pixels would be wrong at any zoom != 1.
func _visible_world_size() -> Vector2:
	var px: Vector2 = _camera.get_viewport().get_visible_rect().size
	var z: Vector2 = _camera.zoom
	# Guard against a zero/unset zoom (would divide-by-zero); treat as 1×.
	var zx: float = z.x if z.x > 0.0 else 1.0
	var zy: float = z.y if z.y > 0.0 else 1.0
	return Vector2(px.x / zx, px.y / zy)


# Pans the view so `cursor_tile` is no closer than `edge_buffer` tiles to any edge.
# Clamps the resulting view to the map bounds so it never shows blank space past
# the map. Was MapCursor._scroll_camera_if_needed; same math, new home.
func keep_cursor_in_view(cursor_tile: Vector2i, edge_buffer: int) -> void:
	if _camera == null or _grid == null:
		return
	var view: Vector2 = _visible_world_size()
	var tiles_w: int = int(view.x / GameConstants.TILE_SIZE)
	var tiles_h: int = int(view.y / GameConstants.TILE_SIZE)
	var edge_x: int = _effective_edge_buffer(edge_buffer, tiles_w)
	var edge_y: int = _effective_edge_buffer(edge_buffer, tiles_h)
	# Camera2D.position is the view CENTRE (anchor_mode = DRAG_CENTER). Convert to
	# the top-left tile so the edge-margin checks are correct — treating centre
	# as top-left is the historical bug that let the cursor scroll off (playtest 1 #2).
	var tl: Vector2i = _grid.world_to_tile(_camera.position - view * 0.5)
	if cursor_tile.x < tl.x + edge_x:
		tl.x = cursor_tile.x - edge_x
	elif cursor_tile.x > tl.x + tiles_w - edge_x - 1:
		tl.x = cursor_tile.x - tiles_w + edge_x + 1
	if cursor_tile.y < tl.y + edge_y:
		tl.y = cursor_tile.y - edge_y
	elif cursor_tile.y > tl.y + tiles_h - edge_y - 1:
		tl.y = cursor_tile.y - tiles_h + edge_y + 1
	tl.x = clamp(tl.x, 0, max(0, _grid.map_width - tiles_w))
	tl.y = clamp(tl.y, 0, max(0, _grid.map_height - tiles_h))
	_camera.position = _grid.tile_to_world(tl) + view * 0.5


func _effective_edge_buffer(edge_buffer: int, visible_tiles: int) -> int:
	# At high zoom the visible span can be only a few tiles. A full 2-tile buffer
	# leaves no stable middle zone, so ordinary one-tile cursor movement can make
	# the camera jump back and forth. Cap the buffer to what the current span can
	# actually support.
	if visible_tiles <= 1:
		return 0
	var max_buffer: int = int((visible_tiles - 1) / 2)
	return clampi(edge_buffer, 0, max_buffer)


# Clamps a tile to the camera's currently visible tile rect. Used by the
# mouse-cursor handler so a stray mouse move can't push the cursor off-screen
# (playtest 3 #7). No-op when camera/grid unavailable.
func clamp_tile_to_view(tile: Vector2i) -> Vector2i:
	if _camera == null or _grid == null:
		return tile
	var view: Vector2 = _visible_world_size()
	var tiles_w: int = int(view.x / GameConstants.TILE_SIZE)
	var tiles_h: int = int(view.y / GameConstants.TILE_SIZE)
	var tl: Vector2i = _grid.world_to_tile(_camera.position - view * 0.5)
	tile.x = clampi(tile.x, tl.x, tl.x + tiles_w - 1)
	tile.y = clampi(tile.y, tl.y, tl.y + tiles_h - 1)
	return tile


# Nudges the camera by a SCREEN-pixel delta, clamped so the view never shows
# blank space past the map. Used by AttackPreview to shift the camera horizontally
# when the preview panel does not fit on either side of the defender on the
# current viewport. Pixel granularity (not whole-tile) so the camera lands
# exactly where the preview needs it, not the nearest tile boundary.
#
# delta_px is in SCREEN pixels (the caller works in canvas/screen space). One
# screen pixel is 1/zoom world units, so divide by zoom before moving the camera,
# which lives in world space — otherwise a zoomed view would over/under-shoot.
func pan_by_pixels(delta_px: Vector2) -> void:
	if _camera == null or _grid == null or delta_px == Vector2.ZERO:
		return
	var z: Vector2 = _camera.zoom
	var world_delta := Vector2(
		delta_px.x / (z.x if z.x > 0.0 else 1.0),
		delta_px.y / (z.y if z.y > 0.0 else 1.0))
	var view: Vector2 = _visible_world_size()
	var half := view * 0.5
	var map_size := Vector2(_grid.map_width, _grid.map_height) * GameConstants.TILE_SIZE
	var target := _camera.position + world_delta
	# Camera position is the view CENTRE. Min centre = half view (so left edge
	# = 0); max centre = map_size - half (so right edge = map_size). Clamp on
	# each axis independently so a tall-but-narrow map still pans horizontally.
	var min_x: float = half.x
	var max_x: float = max(half.x, map_size.x - half.x)
	var min_y: float = half.y
	var max_y: float = max(half.y, map_size.y - half.y)
	target.x = clampf(target.x, min_x, max_x)
	target.y = clampf(target.y, min_y, max_y)
	_camera.position = target
	# AttackPreview re-reads the defender's screen position right after this pan.
	_flush_scroll()


# Nudges the camera by whole tiles, clamped to the authored map bounds. Used by
# mouse-edge camera panning so a moving mouse can scroll the view without
# feeding directly back into cursor->camera recursion.
func nudge_by_tiles(delta: Vector2i) -> bool:
	if _camera == null or _grid == null or delta == Vector2i.ZERO:
		return false
	var view: Vector2 = _visible_world_size()
	var tiles_w: int = int(view.x / GameConstants.TILE_SIZE)
	var tiles_h: int = int(view.y / GameConstants.TILE_SIZE)
	var tl: Vector2i = _grid.world_to_tile(_camera.position - view * 0.5)
	var next_tl := tl + delta
	next_tl.x = clamp(next_tl.x, 0, max(0, _grid.map_width - tiles_w))
	next_tl.y = clamp(next_tl.y, 0, max(0, _grid.map_height - tiles_h))
	if next_tl == tl:
		return false
	_camera.position = _grid.tile_to_world(next_tl) + view * 0.5
	# Mouse edge-panning recomputes the pointed-at tile right after this nudge.
	_flush_scroll()
	return true


# Saves the current camera position for `faction_id`. Restored at the next
# phase change back to that faction so AI-phase tracking doesn't drag the
# camera to a different view (PT4 #2). Empty faction id falls back to the
# default key so pre-M14 callers and tests that didn't track factions still
# round-trip correctly.
func save_view(faction_id: String = "") -> void:
	if _camera == null:
		return
	var key: String = faction_id if faction_id != "" else _DEFAULT_FACTION_KEY
	_saved_positions[key] = _camera.position


# Restores `faction_id`'s saved view. Returns true if a restore happened, false
# if save_view has never been called for that faction (e.g. very first phase —
# GameMap's initial placement is the right source then).
func restore_view(faction_id: String = "") -> bool:
	if _camera == null:
		return false
	var key: String = faction_id if faction_id != "" else _DEFAULT_FACTION_KEY
	if not _saved_positions.has(key):
		return false
	_camera.position = _saved_positions[key]
	return true


# ── Zoom (Display & Accessibility item 1) ─────────────────────────────────────

func get_zoom_index() -> int:
	return _zoom_index


func get_zoom_count() -> int:
	return ZOOM_LEVELS.size()


func get_zoom() -> float:
	return ZOOM_LEVELS[_zoom_index]


# Sets the zoom level + Camera2D.zoom WITHOUT repositioning the view. Used at map
# load (GameMap) to apply the persisted level before the initial center, so the
# clamp/center math downstream sees the right visible span. Returns the clamped
# index actually applied.
func set_zoom_index_silent(index: int) -> int:
	_zoom_index = clampi(index, 0, ZOOM_LEVELS.size() - 1)
	if _camera != null:
		_camera.zoom = Vector2.ONE * ZOOM_LEVELS[_zoom_index]
	return _zoom_index


# Sets the zoom level and re-frames the view on `focus_tile` (the cursor's tile in
# play), keeping the focus on screen and the view inside the map. At low zoom a map
# can be smaller than the viewport on an axis — then that axis is centred instead of
# pinned to the top-left (which would leave blank space on one side). Returns the
# clamped index actually applied.
func set_zoom_index(index: int, focus_tile: Vector2i,
		edge_buffer: int = GameConstants.CURSOR_CAMERA_EDGE_BUFFER) -> int:
	set_zoom_index_silent(index)
	if _camera != null and _grid != null:
		keep_cursor_in_view(focus_tile, edge_buffer)
		_center_axes_smaller_than_view()
	# MapCursor re-anchors the context menu / attack preview immediately after a
	# zoom change — flush so those reads see the new view, not last frame's.
	_flush_scroll()
	return _zoom_index


# Steps one level toward zoom-in (+1) or zoom-out (-1); clamps at the array ends.
func step_zoom(direction: int, focus_tile: Vector2i,
		edge_buffer: int = GameConstants.CURSOR_CAMERA_EDGE_BUFFER) -> int:
	var target: int = clampi(_zoom_index + direction, 0, ZOOM_LEVELS.size() - 1)
	if target == _zoom_index:
		return _zoom_index
	return set_zoom_index(target, focus_tile, edge_buffer)


# Returns to the default 1× level, re-framed on `focus_tile`.
func reset_zoom(focus_tile: Vector2i,
		edge_buffer: int = GameConstants.CURSOR_CAMERA_EDGE_BUFFER) -> int:
	return set_zoom_index(DEFAULT_ZOOM_INDEX, focus_tile, edge_buffer)


# Centres any axis on which the whole map is smaller than the visible span, so a
# zoomed-out view of a small map shows the map centred rather than blank space on
# one side. No-op on axes where the map is at least as large as the view (the
# normal case — keep_cursor_in_view already clamps those correctly).
func _center_axes_smaller_than_view() -> void:
	if _camera == null or _grid == null:
		return
	var view: Vector2 = _visible_world_size()
	var map_size := Vector2(_grid.map_width, _grid.map_height) * GameConstants.TILE_SIZE
	if map_size.x <= view.x:
		_camera.position.x = map_size.x * 0.5
	if map_size.y <= view.y:
		_camera.position.y = map_size.y * 0.5
