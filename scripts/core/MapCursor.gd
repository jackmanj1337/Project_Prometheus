class_name MapCursor extends Node2D
# The player's tile-position cursor. Handles keyboard, mouse, and camera scrolling.
# Emits EventBus.cursor_moved on every tile change so HUD panels can react.
#
# Three concerns have been sliced out into RefCounted helpers: MapCursorTargeting
# (attack/staff flow, D-2), MapCursorSelection (unit selection + move planning, D-3),
# and MapCursorInput (key decode + auto-repeat, D-3). MapCursor keeps the cursor FSM,
# camera, menus, and the thin input/mouse receiver shells.
#
# State machine: see State enum below and the transition diagram above _on_confirm().

# Camera-pan trigger distance — the default when SettingsManager is unavailable
# (headless tests). The live value is read per-scroll via _camera_edge_buffer()
# so the in-game Camera Pan Buffer setting (#17) takes effect immediately.
# Key-repeat timings now live in MapCursorInput.
const CAMERA_EDGE_BUFFER: int = GameConstants.CURSOR_CAMERA_EDGE_BUFFER
const SaveCodec = preload("res://scripts/save/SaveCodec.gd")

var current_tile: Vector2i = Vector2i(0, 0)
var _grid: GridManager = null
var _camera: Camera2D = null  # held only for null checks + test reads; production writes go through _camera_ctrl
var _turn: TurnManager = null
# Faction id this cursor currently drives (M14 stage 1). Defaults to "blue"
# (the player) so behaviour stays unchanged until stage 5 routes a non-blue
# hotseat phase through the cursor. Threaded to both slices on setup().
var _controlling_faction: String = "blue"

# All camera writes (scroll, AI tracking, PT4 #2 save/restore) go through this
# controller (B4). Built either by GameMap and passed in via setup(), or built
# in setup() if only a raw Camera2D was provided (test convenience).
const CameraControllerS = preload("res://scripts/core/CameraController.gd")
var _camera_ctrl: RefCounted = null

# State machine — see GDD_01 MapCursor section
enum State {
	FREE,            # default; cursor moves freely
	UNIT_SELECTED,   # a player unit is highlighted; movement overlay shown
	UNIT_MOVED,      # unit has moved; ActionMenu is open
	TARGETING,       # MapCursorTargeting owns the flow (attack or staff heal)
	LOCKED,          # input suppressed (animation, enemy phase)
}
var _state: State = State.FREE

# Unit selection + movement-path planning — see MapCursorSelection.gd (D-3 slice).
# The cursor FSM stays here; this object owns the selected unit and its move range.
var _selection: MapCursorSelection = MapCursorSelection.new()

# Attack / staff-heal targeting flow — see MapCursorTargeting.gd. The cursor FSM
# above stays here; this object owns the CHOOSING/PREVIEWING sub-state.
var _targeting: MapCursorTargeting = MapCursorTargeting.new()

# Keyboard decoding + held-key auto-repeat — see MapCursorInput.gd (D-3 slice).
# Named _input_handler, not _input, to avoid colliding with the _input() callback.
var _input_handler: MapCursorInput = MapCursorInput.new()

# Assign these in the editor — the menu nodes that live in the HUD layer.
# Typed as Node so the script compiles in headless test mode where class_name lookup fails.
@export var action_menu: Node = null
@export var item_menu: Node = null
@export var map_menu: Node = null
@export var attack_preview: Node = null
@export var settings_screen: Node = null
@export var weapon_menu: Node = null
@export var unit_details: Node = null
@export var promotion_screen: Node = null
@export var reclass_screen: Node = null

# ── [TUR] Threat watch-set + danger-mode (B6-MRD slice 2) ────────────────────
# _danger_mode: which threat overlay the danger-zone action currently shows. A
# fixed value-set (guarded by check_docs against GDD_07). MMB over empty terrain
# cycles it; the manual cycle order is DANGER_MODE_CYCLE.
const DANGER_MODE_NONE := "none"
const DANGER_MODE_FULL := "full"
const DANGER_MODE_SELECTED := "selected"
const DANGER_MODE_COMBINED := "combined"
const DANGER_MODE_CYCLE: Array[String] = [
	DANGER_MODE_FULL, DANGER_MODE_SELECTED, DANGER_MODE_COMBINED, DANGER_MODE_NONE,
]
const DEBUG_SHARED_CELL_MODE_CYCLE: Array[String] = [
	GridManager.SHARED_CELL_SINGLE,
	GridManager.SHARED_CELL_BORDER_THROUGH,
	GridManager.SHARED_CELL_STACKED,
]
# The full danger-mode value-set as string literals — the parseable source of
# truth for the check_docs guard that keeps GDD_07 in sync (DoD#2, mirrors the
# mouse_cursor value-set check).
const VALID_DANGER_MODES: Array[String] = ["none", "full", "selected", "combined"]
var _danger_mode: String = DANGER_MODE_NONE
# Hand-picked hostile enemies whose threat the player is watching, stored as
# stable unit ids (not refs) so a defeated enemy prunes cleanly and a save can
# round-trip them ([TUR-3]/[TUR-4]). Used as a set: id -> true.
var _watch_set: Dictionary = {}
# World-space container for the watched-enemy "D" markers ([TUR-2]); built lazily.
var _watch_marker_layer: Node2D = null

# ── [MRD-2]/[MRD-4] Hover-to-peek range (B6-MRD slice 3) ─────────────────────
# Hold peek_range (E) in FREE state to preview the unit under the cursor's
# move+attack reach as an opaque top layer. Computed ONCE per hovered unit and
# cached — moving to a DIFFERENT unit recomputes; staying on one reuses the cache
# (no per-cursor-tick flood). _peek_compute_count is a test hook for cache hits.
var _peek_active: bool = false
var _peek_unit: Node = null
var _peek_move: Array[Vector2i] = []
var _peek_attack: Array[Vector2i] = []
var _peek_compute_count: int = 0

# ── Movement path arrows (B6-MRD slice 4) ────────────────────────────────────
# While a unit is selected, a directional chain from it along the cheapest path
# to the cursor tile, recomputed only for the current cursor tile ([MRD-4] B).
var _path_arrow_layer: Node2D = null
var _path_arrow_tiles: Array[Vector2i] = []
# True while the level-up screen is on-screen. Suppresses all cursor input
# independently of _state, so a post-combat _finish_action setting _state=FREE
# can't re-enable the cursor underneath the level-up screen (#12).
var _input_suppressed: bool = false
# True while the "end turn with unacted units?" ConfirmationDialog is open.
# Prevents _on_map_menu_closed from unlocking the cursor before the dialog resolves.
var _awaiting_end_turn_confirm: bool = false
var _map_menu_suspend_available: bool = false
var _context_menu_anchor: Dictionary = {}
# True while a deferred re-anchor pass is pending (V027-03b): rapid zoom steps
# coalesce into one next-frame re-place instead of stacking awaits.
var _reanchor_queued: bool = false

# Held map-zoom repeat. Trigger axes do not emit keyboard-style repeat events, so
# _process polls action strength and steps the discrete zoom level on a timer.
const ZOOM_REPEAT_DELAY: float = GameConstants.CURSOR_KEY_REPEAT_DELAY
const ZOOM_PRESS_THRESHOLD: float = 0.25
const ZOOM_REPEAT_RATE_FAST: float = 0.12
const ZOOM_REPEAT_RATE_SLOW: float = 0.35
var _zoom_held_direction: int = 0
var _zoom_held_timer: float = 0.0


# ── Setup & Lifecycle ──────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("map_cursor")
	# The @export NodePaths to the HUDLayer menus resolve to null at scene-build
	# time — the menus are declared after MapCursor in GameMap.tscn, so they don't
	# exist yet when the exports are applied. _ready() runs after the whole tree is
	# built, so re-resolve any that came back null before wiring their signals.
	_resolve_menu_refs()
	if action_menu:
		action_menu.action_chosen.connect(_on_action_chosen)
		action_menu.hidden_by_cancel.connect(_on_action_menu_cancelled)
	if item_menu:
		item_menu.item_chosen.connect(_on_item_chosen)
		item_menu.cancelled.connect(_on_item_menu_cancelled)
	if weapon_menu:
		weapon_menu.weapon_chosen.connect(_on_weapon_chosen)
		weapon_menu.cancelled.connect(_on_weapon_menu_cancelled)
	if unit_details:
		unit_details.closed.connect(_on_unit_details_closed)
	if map_menu:
		map_menu.end_turn_requested.connect(_on_end_turn_requested)
		map_menu.menu_closed.connect(_on_map_menu_closed)
		map_menu.settings_requested.connect(_on_settings_requested)
		if map_menu.has_signal("suspend_and_quit_requested"):
			map_menu.suspend_and_quit_requested.connect(_on_suspend_and_quit_requested)
		map_menu.quit_to_menu_requested.connect(_on_quit_to_menu_requested)
	if settings_screen:
		settings_screen.back_pressed.connect(_on_settings_closed)
	# Lock cursor during enemy phase; unlock when player phase starts
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.phase_changed.connect(_on_phase_changed)
		# Freeze the cursor while the level-up screen is up (#12).
		bus.level_up_started.connect(_on_level_up_started)
		bus.level_up_finished.connect(_on_level_up_finished)
		bus.promotion_started.connect(_on_level_up_started)
		bus.promotion_finished.connect(_on_level_up_finished)
		bus.reclass_started.connect(_on_level_up_started)
		bus.reclass_finished.connect(_on_level_up_finished)
		# Prune a defeated enemy from the threat watch set ([TUR-4]).
		bus.unit_died.connect(_on_unit_died)
		# Refresh the hover-peek + movement path arrows on a cursor move ([MRD-2/4]).
		bus.cursor_moved.connect(_on_cursor_moved_overlays)
	# React to the targeting flow finishing or being backed out of.
	_targeting.completed.connect(_on_targeting_completed)
	_targeting.cancelled.connect(_on_targeting_cancelled)
	_targeting.pair_up_resolved.connect(_on_pair_up_resolved)
	_targeting.separate_resolved.connect(_on_separate_resolved)


# Fallback lookup for the menu @exports — see _ready(). Each path mirrors the
# NodePath set on the export in GameMap.tscn; only applied when the export is
# null so an editor-assigned reference still wins.
func _resolve_menu_refs() -> void:
	if action_menu == null:
		action_menu = get_node_or_null("../HUDLayer/ActionMenu")
	if item_menu == null:
		item_menu = get_node_or_null("../HUDLayer/ItemMenu")
	if map_menu == null:
		map_menu = get_node_or_null("../HUDLayer/MapMenu")
	if attack_preview == null:
		attack_preview = get_node_or_null("../HUDLayer/AttackPreview")
	if settings_screen == null:
		settings_screen = get_node_or_null("../SettingsLayer/SettingsScreen")
	if weapon_menu == null:
		weapon_menu = get_node_or_null("../HUDLayer/WeaponMenu")
	if unit_details == null:
		unit_details = get_node_or_null("../UnitDetailsLayer/UnitDetailsScreen")
	if promotion_screen == null:
		promotion_screen = get_node_or_null("../PromotionLayer/PromotionScreen")
	if reclass_screen == null:
		reclass_screen = get_node_or_null("../ReclassLayer/ReclassScreen")


func _on_phase_changed(new_phase: int, _faction_id: String = "") -> void:
	# Capture the *outgoing* faction's camera view BEFORE reassigning
	# _controlling_faction. With multi-faction hotseat (M14 stage 5) every
	# Phase.ENEMY transition fires phase_changed, so blue → green → red → blue
	# used to overwrite blue's saved view on the green→red hop. Saving against
	# the outgoing faction id keeps each faction's view independent (code
	# review 2026-06-09).
	var outgoing_faction: String = _controlling_faction
	if _faction_id != "":
		set_controlling_faction(_faction_id)
	if new_phase == GameState.Phase.ENEMY:
		if _camera_ctrl != null:
			_camera_ctrl.save_view(outgoing_faction)
		lock()
	else:
		# Restore the incoming faction's saved camera (PT4 #2). Then run the
		# existing PT3 #5 safety net so a cursor outside the resulting view is
		# panned back in — covers the rare case where the saved view no longer
		# contains the cursor (e.g. End Turn from a far-panned position).
		if _camera_ctrl != null:
			_camera_ctrl.restore_view(_controlling_faction)
		_scroll_camera_if_needed()
		unlock()


# Level-up screen opened — suppress cursor input until it closes (#12).
func _on_level_up_started() -> void:
	_input_suppressed = true
	_input_handler.clear_repeat()


# Level-up queue exhausted — the cursor may resume.
func _on_level_up_finished() -> void:
	_input_suppressed = false


func setup(grid: GridManager, camera: Camera2D, turn: TurnManager = null,
		camera_ctrl: RefCounted = null, controlling_faction: String = "blue") -> void:
	_grid = grid
	_camera = camera
	_turn = turn
	_controlling_faction = controlling_faction
	# Accept a pre-built CameraController (GameMap path — there should be exactly
	# one in production so the save/restore state is shared) or build a fresh one
	# from the camera (test path — _make_cursor passes only a Camera2D).
	if camera_ctrl != null:
		_camera_ctrl = camera_ctrl
	elif camera != null:
		_camera_ctrl = CameraControllerS.new()
		_camera_ctrl.setup(camera, grid)
	position = _grid.tile_to_world(current_tile)
	# Inject the targeting flow's scene-tree dependencies now that _grid is known.
	_targeting.setup(_grid, attack_preview, get_node_or_null("/root/CombatResolver"),
		_controlling_faction, _turn)
	# AttackPreview needs the camera + camera controller so it can anchor
	# itself beside the defender and pan the view when the panel does not
	# fit. has_method guard keeps test stubs (StubPreview) working.
	if attack_preview != null and attack_preview.has_method("setup"):
		attack_preview.setup(_camera, _grid, _camera_ctrl)
	# The selection slice needs the grid + turn manager for its queries.
	_selection.setup(_grid, _turn, _controlling_faction)


# Called when the active controlling faction changes mid-map (M14 stage 5 —
# hotseat hand-off). Re-points the selection + targeting slices so the cursor
# starts respecting the new faction's units immediately.
func set_controlling_faction(faction_id: String) -> void:
	_controlling_faction = faction_id
	_selection.set_controlling_faction(faction_id)
	_targeting.set_controlling_faction(faction_id)


# ── Input Handling ──────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if _handle_debug_shared_cell_mode_cycle(event):
		return
	if _input_suppressed or _state == State.LOCKED:
		return
	# Map zoom (Display & Accessibility item 1): scroll wheel / +/-/0. Handled
	# before the cursor-move branches so a scroll-to-zoom isn't also read as a
	# mouse button. Zoom re-frames on the cursor's current tile and persists the
	# chosen level so it survives map changes and restarts.
	if _is_fresh_action_press(event, "zoom_in"):
		_apply_zoom_step(1)
		_arm_zoom_repeat(1)
		return
	if _is_fresh_action_press(event, "zoom_out"):
		_apply_zoom_step(-1)
		_arm_zoom_repeat(-1)
		return
	if _is_fresh_action_press(event, "zoom_reset"):
		_apply_zoom_reset()
		_clear_zoom_repeat()
		return
	if event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	elif event is InputEventMouseButton and event.pressed:
		_handle_mouse_button(event)
	elif _is_discrete_pressed_event(event):
		_handle_discrete_press(event)


func _process(delta: float) -> void:
	# Auto-repeat only applies to free cursor movement. If the state changed
	# while a key was held (e.g. confirmed into TARGETING), drop the held dir
	# so the cursor doesn't drift out of a menu/targeting context.
	if _input_suppressed:
		_input_handler.clear_repeat()
		_clear_zoom_repeat()
		return
	if _state == State.LOCKED:
		_input_handler.clear_repeat()
		_clear_zoom_repeat()
		return
	var zoom_dir := _poll_held_zoom(delta)
	if zoom_dir != 0:
		_apply_zoom_step(zoom_dir)
	if _state != State.FREE and _state != State.UNIT_SELECTED:
		_input_handler.clear_repeat()
		return
	var d := _input_handler.poll_direction(delta)
	if d != Vector2i.ZERO:
		move_cursor(d)


func _is_discrete_pressed_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventJoypadButton:
		return event.pressed
	if event is InputEventAction:
		return event.pressed
	return false


func _is_fresh_action_press(event: InputEvent, action: String) -> bool:
	if event is InputEventKey and event.echo:
		return false
	return event.is_action_pressed(action)


func _handle_debug_shared_cell_mode_cycle(event: InputEvent) -> bool:
	if not OS.is_debug_build() or _grid == null:
		return false
	if event is InputEventKey and event.echo:
		return false
	if not event.is_action_pressed("debug_cycle_mrd_shared_overlay"):
		return false
	var idx := DEBUG_SHARED_CELL_MODE_CYCLE.find(_grid.shared_cell_mode)
	var next_idx := 0 if idx == -1 else (idx + 1) % DEBUG_SHARED_CELL_MODE_CYCLE.size()
	_grid.set_shared_cell_mode(DEBUG_SHARED_CELL_MODE_CYCLE[next_idx])
	_repaint_current_overlay_state()
	print("MRD shared-cell overlay mode: %s" % _grid.shared_cell_mode)
	return true


func _repaint_current_overlay_state() -> void:
	if _peek_active:
		_repaint_with_peek()
	elif _state == State.UNIT_SELECTED:
		_repaint_selection_overlays()
	elif _state == State.TARGETING:
		_repaint_targeting_overlays()
	else:
		repaint()


func _handle_discrete_press(event: InputEvent) -> void:
	# MapCursorInput decodes the event into a state-agnostic intent; the FSM here
	# decides what a MOVE means per _state (free move / target cycle / ignored).
	var decoded := _input_handler.decode(event)
	match decoded["intent"]:
		MapCursorInput.Intent.MOVE:
			var dir: Vector2i = decoded["dir"]
			match _state:
				State.FREE, State.UNIT_SELECTED:
					# Free cursor movement, with held-key auto-repeat.
					move_cursor(dir)
					_input_handler.arm_repeat(dir)
				State.TARGETING:
					# Arrows step between valid targets instead of moving freely.
					_cycle_target(dir)
				# UNIT_MOVED (ActionMenu owns input) ignores direction keys entirely.
		MapCursorInput.Intent.CONFIRM:
			_on_confirm()
		MapCursorInput.Intent.CANCEL:
			_on_cancel()
		MapCursorInput.Intent.NEXT_UNIT:
			_cycle_to_next_unit(1)
		MapCursorInput.Intent.PREV_UNIT:
			_cycle_to_next_unit(-1)
		MapCursorInput.Intent.OPEN_MENU:
			if _state == State.FREE:
				_open_map_menu()
		MapCursorInput.Intent.OPEN_SETTINGS:
			_open_settings_via_hotkey()
		MapCursorInput.Intent.INSPECT_UNIT:
			_open_unit_details()


# Resets cursor key-repeat on release, and flips the enemy danger-zone
# toggle on a show_danger_zone press or a middle-mouse click (#12).
func _input(event: InputEvent) -> void:
	if _input_suppressed:
		return
	if event is InputEventKey:
		if not event.pressed:
			# Clear cursor repeat when the held direction key is released.
			_input_handler.note_released(event)
			# Release the hover-peek when its hold key comes up.
			if event.is_action_released("peek_range"):
				_end_peek()
		elif not event.echo and event.is_action_pressed("show_danger_zone"):
			_on_danger_zone_press()
		elif not event.echo and event.is_action_pressed("peek_range"):
			_begin_peek()
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_MIDDLE:
			_on_danger_zone_press()
	elif event is InputEventJoypadButton:
		# Gamepad arm of the danger-zone resolver (gamepad plan §4): a pad-bound
		# show_danger_zone press (R3) routes through the SAME resolver as Q/MMB,
		# and peek_range gets press/release parity. Without this branch the
		# key/mouse type gates above silently drop all joypad events. The
		# project.godot joypad bindings land with gamepad plan slice 1.
		if event.pressed:
			if event.is_action_pressed("show_danger_zone"):
				_on_danger_zone_press()
			elif event.is_action_pressed("peek_range"):
				_begin_peek()
		else:
			_input_handler.note_released(event)
			if event.is_action_released("peek_range"):
				_end_peek()


# [TUR-3] The single danger-zone resolver — MMB / show_danger_zone (and, later,
# gamepad R3 through the same path). FREE state only (a selected unit's move
# range owns the overlay otherwise, #13). Over a hostile attack-capable enemy it
# toggles that enemy's watch-set membership; over anything else it cycles the
# display mode. Then repaints from current positions.
func _on_danger_zone_press() -> void:
	if _grid == null or _state != State.FREE:
		return
	var u := _grid.get_unit_at(current_tile)
	if u != null and _is_watchable_enemy(u):
		_toggle_watch_member(u)
	else:
		_cycle_danger_mode()
	repaint()


# A hostile, living, attack-capable enemy the player can add to the watch set.
# Attack-capability reuses get_unit_threat_tiles (empty for a healer/dead unit).
func _is_watchable_enemy(u: Node) -> bool:
	if u == null or not ("team" in u) or u.data == null or u.data.hp <= 0:
		return false
	if not _is_hostile_to_controller(u):
		return false
	return not _grid.get_unit_threat_tiles(u).is_empty()


func _is_hostile_to_controller(u: Node) -> bool:
	var gs := get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("are_hostile"):
		return gs.are_hostile(_controlling_faction, u.team)
	return u.team != _controlling_faction  # headless fallback (binary hostility)


# Add/remove an enemy from _watch_set, auto-promoting/demoting the mode on the
# empty<->non-empty transition without clobbering a faction layer already up.
func _toggle_watch_member(u: Node) -> void:
	var id: String = u.data.unit_id
	if id == "":
		return
	var was_empty := _watch_set.is_empty()
	if _watch_set.has(id):
		_watch_set.erase(id)
	else:
		_watch_set[id] = true
	if was_empty and not _watch_set.is_empty():
		# First enemy added: none→selected, full→combined ([TUR-4]).
		if _danger_mode == DANGER_MODE_NONE:
			_danger_mode = DANGER_MODE_SELECTED
		elif _danger_mode == DANGER_MODE_FULL:
			_danger_mode = DANGER_MODE_COMBINED
	elif not was_empty and _watch_set.is_empty():
		# Last enemy removed: selected→none, combined→full.
		_auto_demote_on_empty()


func _auto_demote_on_empty() -> void:
	if _danger_mode == DANGER_MODE_SELECTED:
		_danger_mode = DANGER_MODE_NONE
	elif _danger_mode == DANGER_MODE_COMBINED:
		_danger_mode = DANGER_MODE_FULL


# MMB over empty terrain cycles full→selected→combined→none→full (start none→full).
func _cycle_danger_mode() -> void:
	var i := DANGER_MODE_CYCLE.find(_danger_mode)
	_danger_mode = DANGER_MODE_CYCLE[(i + 1) % DANGER_MODE_CYCLE.size()]


# [TUR] Recompute + paint the threat overlay from _danger_mode + _watch_set (in
# the registry's precedence order so watch wins shared cells in `combined`), then
# the watched-enemy markers. Recomputes from CURRENT positions, so it is never
# stale after enemies move. Called after every edit and on return to FREE.
func repaint() -> void:
	if _grid == null:
		return
	var specs := _build_threat_specs()
	if _peek_active:
		_add_peek_specs(specs)  # peek sits on top of the threat overlay
	_grid.repaint_overlays(specs)
	_render_watch_markers()


# Merge transient interaction overlays into the retained threat/watch layers.
# Selection and targeting own their local tile sets; MapCursor owns the
# cross-mode threat state, so the composition happens here ([MRD-7]).
func _repaint_composed_overlays(extra_specs: Dictionary = {}) -> void:
	if _grid == null:
		return
	var specs := _build_threat_specs()
	for id in extra_specs:
		specs[id] = extra_specs[id]
	_grid.repaint_overlays(specs)
	_render_watch_markers()


func _repaint_selection_overlays() -> void:
	_repaint_composed_overlays(_selection.overlay_specs())


func _repaint_targeting_overlays() -> void:
	_repaint_composed_overlays(_targeting.overlay_specs())


# The base threat overlay specs from _danger_mode + _watch_set (prunes first).
func _build_threat_specs() -> Dictionary:
	_prune_watch_set()
	var specs: Dictionary = {}
	var show_faction := _danger_mode == DANGER_MODE_FULL or _danger_mode == DANGER_MODE_COMBINED
	var show_watch := _danger_mode == DANGER_MODE_SELECTED or _danger_mode == DANGER_MODE_COMBINED
	if show_faction:
		specs[GridManager.OVERLAY_LAYER_FACTION_THREAT] = {
			"tiles": _grid.get_enemy_danger_tiles(_controlling_faction),
			"source": GridManager.OVERLAY_DARK_RED,
		}
	if show_watch:
		specs[GridManager.OVERLAY_LAYER_WATCH_THREAT] = {
			"tiles": _watch_set_threat_tiles(),
			"source": GridManager.OVERLAY_DARKER_RED,
		}
	return specs


# The living units whose ids are in _watch_set, resolved from GameState.
func _watched_units() -> Array:
	var out: Array = []
	var gs := get_node_or_null("/root/GameState")
	var units: Variant = gs.get("all_units") if gs != null else null
	if not (units is Array):
		return out
	for u in units:
		if u == null or u.data == null:
			continue
		if _watch_set.has(u.data.unit_id) and u.data.hp > 0:
			out.append(u)
	return out


func _watch_set_threat_tiles() -> Array[Vector2i]:
	var seen: Dictionary = {}
	for u in _watched_units():
		for t in _grid.get_unit_threat_tiles(u):
			seen[t] = true
	var out: Array[Vector2i] = []
	for t in seen.keys():
		out.append(t)
	return out


# Drop ids for enemies no longer present/alive; auto-demote if that empties the
# set. Keeps the persistent set honest across phases, deaths, and (later) loads.
func _prune_watch_set() -> void:
	if _watch_set.is_empty():
		return
	var present: Dictionary = {}
	var gs := get_node_or_null("/root/GameState")
	var units: Variant = gs.get("all_units") if gs != null else null
	if units is Array:
		for u in units:
			if u != null and u.data != null and u.data.hp > 0:
				present[u.data.unit_id] = true
	var removed_any := false
	for id in _watch_set.keys():
		if not present.has(id):
			_watch_set.erase(id)
			removed_any = true
	if removed_any and _watch_set.is_empty():
		_auto_demote_on_empty()


# A watched enemy died — prune it (repaint only while its overlay could show).
func _on_unit_died(_unit: Node) -> void:
	if _watch_set.is_empty():
		return
	_prune_watch_set()
	if _state == State.FREE:
		repaint()


# ── [TUR-2] Watched-enemy "D" markers ────────────────────────────────────────
# Rendered whenever the set is non-empty, independent of _danger_mode, so the
# player always sees which enemies are watched. Placeholder glyph — flagged for
# the UI polish pass to review (likely an eye icon).
func _watched_marker_tiles() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for u in _watched_units():
		out.append(u.tile_position)
	return out


func _render_watch_markers() -> void:
	if _watch_marker_layer == null:
		_watch_marker_layer = Node2D.new()
		_watch_marker_layer.name = "WatchMarkers"
		# Parent under the (static, world-origin) grid when it's in the tree so the
		# markers sit in world space and don't ride the moving cursor.
		if _grid != null and _grid.is_inside_tree():
			_grid.add_child(_watch_marker_layer)
		elif get_parent() != null:
			get_parent().add_child(_watch_marker_layer)
		else:
			add_child(_watch_marker_layer)
	_clear_watch_markers()
	if _grid == null:
		return
	for tile in _watched_marker_tiles():
		var lbl := Label.new()
		lbl.text = "D"
		lbl.position = _grid.tile_to_world(tile) \
			+ Vector2(GameConstants.TILE_SIZE * 0.6, GameConstants.TILE_SIZE * 0.5)
		_watch_marker_layer.add_child(lbl)


func _clear_watch_markers() -> void:
	if _watch_marker_layer == null:
		return
	for c in _watch_marker_layer.get_children():
		c.queue_free()


# Clears the danger-overlay PAINT (and markers) but RETAINS _watch_set +
# _danger_mode, so a teardown (selection, enemy phase, menu) hides the visual
# while a later return-to-FREE repaint recomputes it fresh ([TUR] §5).
func _clear_overlay_paint() -> void:
	if _grid != null:
		_grid.clear_overlays()
	_clear_watch_markers()
	_clear_path_arrows()


# ── [MRD-2]/[MRD-4] Hover-to-peek ────────────────────────────────────────────
# Arm the peek and paint the hovered unit's reach. FREE state only, so it can't
# fight a selected unit's move overlay.
func _begin_peek() -> void:
	if _grid == null or _state != State.FREE:
		return
	_peek_active = true
	_peek_unit = null  # force a compute for the current hover
	_refresh_peek()


# Recompute the peek only when the hovered unit CHANGES; reuse the cache otherwise
# ([MRD-4] B — computed once on press, no per-cursor-tick recompute).
func _refresh_peek() -> void:
	if not _peek_active or _grid == null:
		return
	if _state != State.FREE:
		_cancel_peek(false)
		return
	var u := _grid.get_unit_at(current_tile)
	if u != _peek_unit:
		_peek_unit = u
		if u != null:
			_peek_move = _grid.get_movement_range(u)
			if not _peek_move.has(u.tile_position):
				_peek_move.append(u.tile_position)
			# Attack reach beyond the move footprint (so blue move / red attack read
			# distinctly, like a normal selection).
			var move_set: Dictionary = {}
			for t in _peek_move:
				move_set[t] = true
			_peek_attack = []
			for t in _grid.get_all_attack_tiles(u, _peek_move):
				if not move_set.has(t):
					_peek_attack.append(t)
			_peek_compute_count += 1
		else:
			_peek_move = []
			_peek_attack = []
	_repaint_with_peek()


func _cancel_peek(restore_free_overlay: bool) -> void:
	_peek_active = false
	_peek_unit = null
	_peek_move = []
	_peek_attack = []
	if restore_free_overlay and _state == State.FREE:
		repaint()


func _on_cursor_moved_overlays(_tile: Vector2i) -> void:
	if _peek_active:
		_refresh_peek()
	if _state == State.UNIT_SELECTED:
		_refresh_path_arrows()


# Release the peek and restore the base overlay (threat, or cleared).
func _end_peek() -> void:
	if not _peek_active:
		return
	_cancel_peek(true)


func _add_peek_specs(specs: Dictionary) -> void:
	specs[GridManager.OVERLAY_LAYER_HOVER_PEEK] = {
		"tiles": _peek_move, "source": GridManager.OVERLAY_BLUE,
	}
	specs[GridManager.OVERLAY_LAYER_HOVER_PEEK_ATTACK] = {
		"tiles": _peek_attack, "source": GridManager.OVERLAY_RED,
	}


func _repaint_with_peek() -> void:
	if _grid == null:
		return
	var specs := _build_threat_specs()
	_add_peek_specs(specs)
	_grid.repaint_overlays(specs)
	_render_watch_markers()


# ── Movement path arrows ─────────────────────────────────────────────────────
# Recompute + draw the selected unit's cheapest path to the cursor. Clears when
# no unit is selected or the cursor isn't a reachable destination (empty path).
# Only the (cheap) path to the current cursor tile is recomputed — no range work.
func _refresh_path_arrows() -> void:
	if _grid == null:
		return
	var unit: Node = _selection.selected_unit if _selection != null else null
	if _state != State.UNIT_SELECTED or unit == null:
		_path_arrow_tiles = []
	else:
		_path_arrow_tiles = _grid.get_movement_path(unit, current_tile)
	_render_path_arrows()


# The consecutive step deltas of the drawn path — the test-facing surface.
func _path_arrow_directions() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for i in range(1, _path_arrow_tiles.size()):
		out.append(_path_arrow_tiles[i] - _path_arrow_tiles[i - 1])
	return out


func _render_path_arrows() -> void:
	if _path_arrow_layer == null:
		_path_arrow_layer = Node2D.new()
		_path_arrow_layer.name = "PathArrows"
		if _grid != null and _grid.is_inside_tree():
			_grid.add_child(_path_arrow_layer)
		elif get_parent() != null:
			get_parent().add_child(_path_arrow_layer)
		else:
			add_child(_path_arrow_layer)
		_path_arrow_layer.z_index = 100  # above the blue move-range overlay
	for c in _path_arrow_layer.get_children():
		c.queue_free()
	if _grid == null or _path_arrow_tiles.size() < 2:
		return
	# A polyline through the path's tile centres — a no-art path indicator (UI
	# polish may swap for directional arrow-tile art).
	var line := Line2D.new()
	line.width = 6.0
	var half := Vector2(GameConstants.TILE_SIZE, GameConstants.TILE_SIZE) * 0.5
	for t in _path_arrow_tiles:
		line.add_point(_grid.tile_to_world(t) + half)
	_path_arrow_layer.add_child(line)


func _clear_path_arrows() -> void:
	_path_arrow_tiles = []
	if _path_arrow_layer != null:
		for c in _path_arrow_layer.get_children():
			c.queue_free()


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _camera == null or _grid == null:
		return
	# Only follow mode lets hover drive the cursor. Click mode is touch-friendly:
	# hover is inert and the left button handles relocate-then-confirm instead.
	if _mouse_cursor_mode() != "follow":
		return
	var tile := _mouse_tile_at(event.position)
	match _state:
		State.FREE, State.UNIT_SELECTED:
			# Mouse motion now pans the camera intentionally when the pointer
			# reaches the viewport edge, then recomputes the pointed-at tile in
			# the new view. Cursor moves still skip the keyboard edge-scroll path,
			# which avoids the old camera-feedback runaway while restoring basic
			# mouse-driven map scrolling.
			if _maybe_pan_camera_for_mouse(event.position):
				tile = _mouse_tile_at(event.position)
			tile = _clamp_tile_to_view(tile)
			if tile != current_tile:
				_set_tile(tile, true)
		State.TARGETING:
			_handle_targeting_mouse_motion(tile)
		# UNIT_MOVED (menu open) ignores mouse motion.


# Mouse motion in TARGETING snaps the cursor to the valid target nearest the pointer.
# The mode gate is already enforced once in _handle_mouse_motion above, so this runs
# only when mouse_cursor == "follow".
func _handle_targeting_mouse_motion(tile: Vector2i) -> void:
	if not _targeting.can_change_target():
		return  # frozen while the attack preview is showing
	var nearest := _nearest_target_tile(tile)
	if nearest != current_tile:
		_set_tile(nearest)


func _nearest_target_tile(tile: Vector2i) -> Vector2i:
	var tiles := _targeting.target_tiles()
	if tiles.is_empty():
		return current_tile
	var nearest: Vector2i = tiles[0]
	var best: int = _manhattan(tile, nearest)
	for t in tiles:
		var d := _manhattan(tile, t)
		if d < best:
			best = d
			nearest = t
	return nearest


# Step the cursor to the next/previous valid target. Right/Down advance, Left/Up
# go back; the list wraps. dir is a unit cardinal vector decoded by MapCursorInput.
func _cycle_target(dir: Vector2i) -> void:
	if not _targeting.can_change_target():
		return  # frozen while the attack preview is showing
	var tiles := _targeting.target_tiles()
	if tiles.is_empty():
		return
	var idx: int = tiles.find(current_tile)
	if idx == -1:
		idx = 0
	var step: int = 1 if (dir.x > 0 or dir.y > 0) else -1
	idx = (idx + step + tiles.size()) % tiles.size()
	_set_tile(tiles[idx])


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if _mouse_cursor_mode() == "click":
			if _try_cycle_terrain_panel_at(event.position):
				return
			if _state == State.FREE or _state == State.UNIT_SELECTED or _state == State.TARGETING:
				var tile := _mouse_tile_at(event.position)
				if _state == State.TARGETING:
					tile = _nearest_target_tile(tile)
				else:
					tile = _clamp_tile_to_view(tile)
				if tile != current_tile:
					_set_tile(tile, true)
					return
		_on_confirm()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_on_cancel()


func move_cursor(direction: Vector2i) -> void:
	_set_tile(current_tile + direction)


# Public entry point for code outside the input flow (e.g. GameMap placing the
# initial cursor after units spawn, #9) to move the cursor onto a tile and let
# the HUD react. No camera scroll — the caller positions the camera itself.
func center_on_tile(tile: Vector2i) -> void:
	current_tile = tile
	if _grid != null:
		position = _grid.tile_to_world(current_tile)
	if is_inside_tree():
		var bus := get_node_or_null("/root/EventBus")
		if bus:
			bus.cursor_moved.emit(current_tile)


func _set_tile(tile: Vector2i, from_mouse: bool = false) -> void:
	# Clamp to map bounds (using GridManager's known map_width/height)
	if _grid != null:
		tile.x = clamp(tile.x, 0, _grid.map_width - 1)
		tile.y = clamp(tile.y, 0, _grid.map_height - 1)
	if tile == current_tile:
		return
	current_tile = tile
	if _grid != null:
		position = _grid.tile_to_world(current_tile)
		# Skip edge-scroll for mouse-driven cursor moves — see _handle_mouse_motion.
		if not from_mouse:
			_scroll_camera_if_needed()
	# Emit only when running inside a tree with EventBus loaded;
	# tests that load this script via --script don't have autoloads available.
	if is_inside_tree():
		var bus := get_node_or_null("/root/EventBus")
		if bus:
			bus.cursor_moved.emit(current_tile)


# Returns `tile` clamped to the camera's currently visible tile rect. Used to
# pin the mouse-driven cursor inside the view so it can't push the camera
# (playtest 3 #7). Thin delegation to CameraController.clamp_tile_to_view (B4).
func _clamp_tile_to_view(tile: Vector2i) -> Vector2i:
	if _camera_ctrl == null:
		return tile
	return _camera_ctrl.clamp_tile_to_view(tile)


func _mouse_tile_at(screen_pos: Vector2) -> Vector2i:
	var world := get_viewport().canvas_transform.affine_inverse() * screen_pos
	return _grid.world_to_tile(world)


func _maybe_pan_camera_for_mouse(screen_pos: Vector2) -> bool:
	if _camera_ctrl == null or _camera == null:
		return false
	var view: Vector2 = get_viewport().get_visible_rect().size
	var px_buffer: float = float(_camera_edge_buffer() * GameConstants.TILE_SIZE)
	if px_buffer <= 0.0:
		return false
	var delta := Vector2i.ZERO
	if screen_pos.x <= px_buffer:
		delta.x = -1
	elif screen_pos.x >= view.x - px_buffer:
		delta.x = 1
	if screen_pos.y <= px_buffer:
		delta.y = -1
	elif screen_pos.y >= view.y - px_buffer:
		delta.y = 1
	return _camera_ctrl.nudge_by_tiles(delta)


func _mouse_cursor_mode() -> String:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm == null:
		return "follow"
	if sm.has_method("normalize_mouse_cursor_mode"):
		return String(sm.call("normalize_mouse_cursor_mode", sm.mouse_cursor))
	var mode := String(sm.mouse_cursor)
	if mode == "disabled":
		return "disabled"
	if mode == "click" or mode == "snap":
		return "click"
	return "follow"


func _try_cycle_terrain_panel_at(screen_pos: Vector2) -> bool:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null or not hud.has_method("terrain_corner_contains_screen_position") \
			or not hud.has_method("cycle_terrain_more_page"):
		return false
	if not bool(hud.call("terrain_corner_contains_screen_position", screen_pos)):
		return false
	hud.call("cycle_terrain_more_page")
	return true


# ── State Machine ──────────────────────────────────────────────────────────
#
# State transitions:
# free          →(confirm on player unit)→  unit_selected
# free          →(confirm/cancel on empty tile, or the open_menu key)→ map menu (locked)
# unit_selected →(confirm on move tile) →  unit_moved  (ActionMenu shown)
# unit_selected →(cancel)              →  free
# unit_moved    →[ActionMenu: attack]  →  targeting   (MapCursorTargeting, ATTACK)
# unit_moved    →[ActionMenu: staff]   →  targeting   (MapCursorTargeting, STAFF)
# unit_moved    →[ActionMenu: item]    →  free  (item used, no target required)
# unit_moved    →[ActionMenu: wait]    →  free
# unit_moved    →[ActionMenu: cancel]  →  unit_selected  (undo move)
# targeting     →(MapCursorTargeting `completed`)→  free  (action resolved)
# targeting     →(MapCursorTargeting `cancelled`)→  unit_moved  (back to ActionMenu)
# While in `targeting`, confirm/cancel are delegated to MapCursorTargeting, which
# tracks the choosing-vs-previewing sub-state internally.
func _on_confirm() -> void:
	match _state:
		State.FREE:
			_try_select_unit_at_cursor()
		State.UNIT_SELECTED:
			_try_move_selected_to_cursor()
		State.UNIT_MOVED:
			pass  # ActionMenu drives confirms here; fallback in _show_action_menu when menu is null
		State.TARGETING:
			_targeting.handle_confirm(current_tile)


func _on_cancel() -> void:
	match _state:
		State.FREE:
			# Cancel on an empty tile opens the map menu (GDD_07); over an
			# unselected unit it opens that unit's character sheet (V021-16) — there
			# is no active selection to deselect in FREE, so the two don't clash.
			if _is_cursor_on_empty_tile():
				_open_map_menu()
			else:
				_open_unit_details()
		State.UNIT_SELECTED:
			_deselect()
		State.UNIT_MOVED:
			# ActionMenu._input fires first and emits hidden_by_cancel → _on_action_menu_cancelled.
			# This is a safety fallback for when action_menu is null.
			if action_menu == null:
				_undo_move_and_reselect()
		State.TARGETING:
			_targeting.handle_cancel()


# ── State: FREE — unit selection ────────────────────────────────────────────

# True when the cursor sits on a tile with no unit — the trigger for the
# confirm/cancel-on-empty-tile map-menu open.
func _is_cursor_on_empty_tile() -> bool:
	return _grid != null and _grid.get_unit_at(current_tile) == null


func _try_select_unit_at_cursor() -> void:
	_cancel_peek(false)
	# The danger overlay shares the one overlay layer with the selection overlays.
	# Clear the paint before selecting so it can't bleed through the move range
	# (#13); _watch_set + _danger_mode are retained and repaint on return to FREE.
	_clear_overlay_paint()
	# MapCursorSelection does the grid validation + overlay painting; the FSM state
	# write and the EventBus relay stay here (a RefCounted slice can't get_node).
	if _selection.select_at(current_tile):
		_state = State.UNIT_SELECTED
		_repaint_selection_overlays()
		_refresh_path_arrows()  # draw the initial path to the cursor tile
		var bus := get_node_or_null("/root/EventBus")
		if bus:
			bus.unit_selected.emit(_selection.selected_unit)
	elif _is_cursor_on_empty_tile():
		# Confirm on an empty tile opens the map menu (GDD_07).
		_open_map_menu()


# ── State: UNIT_SELECTED — movement ─────────────────────────────────────────

func _try_move_selected_to_cursor() -> void:
	# plan_path_to returns [] (and does nothing) for an illegal destination — the
	# cursor then simply stays in UNIT_SELECTED.
	var path := _selection.plan_path_to(current_tile)
	if path.is_empty():
		return
	_state = State.LOCKED  # block input during the move animation
	_clear_path_arrows()   # the unit is committing to the path; drop the preview
	await _selection.selected_unit.move_along_path(path)
	_state = State.UNIT_MOVED
	_show_action_menu()


func _deselect() -> void:
	_selection.clear()
	_state = State.FREE
	_clear_path_arrows()
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.unit_deselected.emit()
	repaint()  # back to FREE: restore any retained threat overlay


# ── State: UNIT_MOVED — ActionMenu dispatch ──────────────────────────────────

# Position a HUD menu one tile to the right of `tile`, but flip it to the left
# and clamp it inside the viewport if it would otherwise run off-screen
# (playtest 3 #4). Used by every per-unit popup — Action / Item / Weapon menus —
# so the fix lands in one place. Call this AFTER the menu's show_for() so its
# real size is known (menus hide unavailable rows, so the height varies).
func _place_menu_near(menu: Node, tile: Vector2i, remember_anchor: bool = true) -> void:
	if menu == null or _grid == null:
		return
	var world_pos := _grid.tile_to_world(tile)
	var screen_pos: Vector2 = get_viewport().canvas_transform * world_pos
	var view: Vector2 = get_viewport().get_visible_rect().size
	# size is updated after show_for() populates the menu; for containers this
	# matches get_combined_minimum_size(). Fall back to the latter when size is 0.
	var menu_size: Vector2 = menu.size
	if menu_size.x <= 0 or menu_size.y <= 0:
		menu_size = menu.get_combined_minimum_size()
	if menu is Control:
		menu_size *= (menu as Control).scale
	# Anchor to the tile's FAR edge plus a small constant gap (V027-02), the same
	# model AttackPreview._reposition_for() uses. The tile-width term must scale
	# with zoom (screen_pos is the tile's top-LEFT corner; the menu goes beyond the
	# far edge), but the gap past the edge stays constant — V025-03's real intent.
	# Capping the whole offset at one unzoomed tile made the menu sit INSIDE the
	# zoomed tile at zoom > 1, drifting over the unit (v0.2.7 §1.3).
	var tile_px: float = float(GameConstants.TILE_SIZE)
	if _camera != null and _camera.zoom.x > 0.0:
		tile_px *= _camera.zoom.x
	const EDGE_GAP_PX := 4.0
	# Side stickiness (V025-03): keep the side chosen last time this same menu was
	# placed (only across REPOSITIONS — a fresh open resets to the right), and only
	# flip when the sticky side genuinely no longer fits. Without this, a small
	# zoom/cursor change flipped the side and the menu jumped across the unit.
	var sticky_side: String = ""
	if not remember_anchor and _context_menu_anchor.get("menu", null) == menu:
		sticky_side = String(_context_menu_anchor.get("side", ""))
	var side: String = sticky_side if sticky_side != "" else "right"
	var right_x: float = screen_pos.x + tile_px + EDGE_GAP_PX
	var left_x: float = screen_pos.x - menu_size.x - EDGE_GAP_PX
	# Flip only when the preferred side can't fit at all.
	if side == "right" and right_x + menu_size.x > view.x:
		side = "left"
	elif side == "left" and left_x < 0.0:
		side = "right"
	var pos := Vector2(right_x if side == "right" else left_x, screen_pos.y)
	pos.x = clampf(pos.x, 0.0, maxf(0.0, view.x - menu_size.x))
	pos.y = clampf(pos.y, 0.0, maxf(0.0, view.y - menu_size.y))
	menu.position = pos
	if remember_anchor:
		_context_menu_anchor = {"menu": menu, "tile": tile, "side": side}
	elif _context_menu_anchor.get("menu", null) == menu:
		_context_menu_anchor["side"] = side  # keep stickiness fresh across zoom


# The shared zoom-reposition hook: re-anchors the open context menu AND the visible
# attack preview (V025-04c) so both track their unit when the map zoom changes.
# Runs once now, then once more one frame later (V027-03b belt-and-braces): any
# transform or layout change that lands after this call heals automatically — the
# automated version of the tester's manual "zoom past max" no-op re-place.
func _reposition_context_menu_anchor() -> void:
	_reposition_anchors_now()
	if _reanchor_queued or not is_inside_tree():
		return
	_reanchor_queued = true  # coalesce: rapid zoom steps share one deferred pass
	await get_tree().process_frame
	_reanchor_queued = false
	_reposition_anchors_now()


func _reposition_anchors_now() -> void:
	# Re-anchor the combat preview beside its defender (no-op when hidden).
	if attack_preview != null and attack_preview.has_method("reposition"):
		attack_preview.reposition()
	if _context_menu_anchor.is_empty():
		return
	var menu: Node = _context_menu_anchor.get("menu", null)
	if menu == null or not is_instance_valid(menu):
		_context_menu_anchor.clear()
		return
	if menu is CanvasItem and not (menu as CanvasItem).visible:
		_context_menu_anchor.clear()
		return
	_place_menu_near(menu, _context_menu_anchor.get("tile", current_tile), false)


func _show_action_menu() -> void:
	if action_menu == null:
		# No menu wired up — fall back to Wait so the unit can always complete its turn
		_commit_wait()
		return
	# show_for() before placement — ActionMenu hides unavailable rows, so the
	# real height is only known once the contents are populated (playtest 3 #4).
	# Passing _turn lets the menu compute the M16 Seize gate.
	action_menu.show_for(_selection.selected_unit, _grid, _turn)
	_place_menu_near(action_menu, _selection.selected_unit.tile_position)


# Fired when ActionMenu's cancel key is pressed while the menu is open
func _on_action_menu_cancelled() -> void:
	# Ignore stale cancel signals that arrive while the move tween is still running.
	if _state == State.LOCKED:
		return
	_undo_move_and_reselect()


# Route the player's chosen action to the appropriate handler
func _on_action_chosen(action: String) -> void:
	match action:
		"attack":
			_enter_targeting(MapCursorTargeting.Mode.ATTACK)
		"staff":
			_enter_targeting(MapCursorTargeting.Mode.STAFF)
		"item":
			_use_item()
		"equip":
			_open_weapon_menu()
		"seize":
			_commit_seize()
		"escape":
			_commit_escape()
		"swap_roles":
			_commit_swap_roles()
		"pair_up":
			_enter_targeting(MapCursorTargeting.Mode.PAIR_UP)
		"separate":
			_enter_targeting(MapCursorTargeting.Mode.SEPARATE)
		"wait":
			_commit_wait()


const _PairUpRegistryScript = preload("res://scripts/autoloads/PairUpRegistry.gd")


# Pair Up resolved: register the pairing, hide the support off-grid (Q2: only
# the lead occupies a tile while paired), and mark both units DONE. The lead
# is selected_unit so _finish_action handles its DONE; the support needs a
# manual set_unit_state because it was never the selected unit. Step 6c
# (Separate) restores the support to an adjacent free tile of the lead — the
# Awakening rule positions Separate relative to the lead, not the support's
# pre-pair tile, so we deliberately do not stash a "return to" coord here.
func _on_pair_up_resolved(lead: Node, support: Node) -> void:
	if lead == null or support == null or lead.data == null or support.data == null:
		_finish_action()
		return
	var registry := get_node_or_null("/root/PairUpRegistry")
	if registry == null or not registry.call("pair", lead.data.unit_id, support.data.unit_id):
		# Pairing refused (campaign disabled, ids mismatched, already paired) —
		# do NOT consume the unit's action. Restore focus to the acting unit and
		# reopen the ActionMenu so the player can choose something else.
		_state = State.UNIT_MOVED
		_set_tile(lead.tile_position)
		_show_action_menu()
		return
	# Move the support off the grid: GridManager.get_unit_at compares
	# tile_position by equality, so the OFF_MAP_TILE sentinel removes the
	# support from every tile query for a real map cell. visible = false
	# keeps the sprite from rendering on the lead's tile.
	support.tile_position = _PairUpRegistryScript.OFF_MAP_TILE
	support.visible = false
	# Committed pair action advances the RNG chain (§3: [unit_id, partner]).
	if _turn != null:
		_turn.commit_action_event("pair_up",
			[lead.data.unit_id, support.data.unit_id] as Array[String])
	if _turn != null and is_instance_valid(support) and support.data.hp > 0:
		_turn.set_unit_state(support, TurnManager.UnitState.DONE)
	# _finish_action marks the lead DONE and clears selection. The lead stays
	# on its original tile per Q2.
	_finish_action()


# Swaps lead and support roles within the selected unit's Pair Up. Ends the
# unit's turn alongside other ActionMenu choices.
#
# swap_roles() only flips the registry's role labels; it does NOT move the units.
# Without a physical swap the on-map unit stays put while the registry now thinks
# the hidden, off-map unit is the lead and the visible unit is the support — the
# Swap-does-nothing regression (playtest v0.1.4 #2). So mirror _on_pair_up_resolved:
# the new lead (the old support) takes the on-map tile and becomes visible, and the
# old lead moves to OFF_MAP_TILE and hides. The new lead is then handed to
# _finish_action so the cursor settles on the tile the pair actually occupies
# rather than the (-1, -1) sentinel.
func _commit_swap_roles() -> void:
	var old_lead: Node = _selection.selected_unit  # on-map unit before the swap
	if old_lead != null and old_lead.data != null and old_lead.data.unit_id != "":
		var registry := get_node_or_null("/root/PairUpRegistry")
		var gs := get_node_or_null("/root/GameState")
		# Resolve the partner BEFORE mutating any roles, so the registry is never
		# left with roles flipped but positions not swapped — i.e. an on-map unit
		# tagged "support" (code review 2026-06-14 #2). get_partner_id is role-
		# independent, so it returns the same partner before the swap. Both units
		# are alive whenever Swap is offered in normal play; this is a defensive
		# guard. Only flip roles once we know we can complete the position swap.
		var new_lead: Node = null
		if registry != null and gs != null and gs.has_method("find_unit_by_id"):
			new_lead = gs.find_unit_by_id(registry.call("get_partner_id", old_lead.data.unit_id))
		if is_instance_valid(new_lead) and new_lead.data != null \
				and registry.has_method("swap_roles") \
				and registry.call("swap_roles", old_lead.data.unit_id):
			var lead_tile: Vector2i = old_lead.tile_position
			old_lead.tile_position = _PairUpRegistryScript.OFF_MAP_TILE
			old_lead.visible = false
			if new_lead.has_method("snap_to_tile"):
				new_lead.snap_to_tile(lead_tile)
			else:
				new_lead.tile_position = lead_tile
			new_lead.visible = true
			# Committed swap advances the RNG chain (§3: [unit_id, partner]).
			if _turn != null:
				_turn.commit_action_event("swap",
					[old_lead.data.unit_id, new_lead.data.unit_id] as Array[String])
			# Swap spends the joint action: the off-map old lead is marked DONE
			# here; the on-map new lead is handed to _finish_action below.
			if _turn != null and old_lead.data.hp > 0:
				_turn.set_unit_state(old_lead, TurnManager.UnitState.DONE)
			_selection.selected_unit = new_lead
	_finish_action()


# Separate resolved: place the support back onto the chosen adjacent tile,
# make it visible again, clear the pair, and end both units' turns.
func _on_separate_resolved(lead: Node, support: Node, target_tile: Vector2i) -> void:
	if lead == null or support == null or lead.data == null or support.data == null:
		_finish_action()
		return
	var registry := get_node_or_null("/root/PairUpRegistry")
	if registry == null or not registry.call("separate", lead.data.unit_id):
		_state = State.UNIT_MOVED
		_set_tile(lead.tile_position)
		_show_action_menu()
		return
	if support.has_method("snap_to_tile"):
		support.snap_to_tile(target_tile)
	else:
		support.tile_position = target_tile
	support.visible = true
	# Committed separate advances the RNG chain (§3: [unit_id, partner_or_tile]).
	if _turn != null:
		_turn.commit_action_event("separate",
			[lead.data.unit_id, TurnManager.tile_field(target_tile)] as Array[String])
	if _turn != null and is_instance_valid(support) and support.data.hp > 0:
		_turn.set_unit_state(support, TurnManager.UnitState.DONE)
	_finish_action()


# M16 stage 3: Seize commits the unit's turn the same way Wait does. The
# TurnManager records the {tile, unit_id, faction} triple and re-evaluates
# objectives — a seize-victory or seize-defeat may resolve the map here.
func _commit_seize() -> void:
	if _turn != null and _selection.selected_unit != null:
		var u: Node = _selection.selected_unit
		# Commit the RNG event before record_seize — seizing can resolve the
		# map, and the chain must already include this action if it does.
		_turn.commit_action_event("seize", [
			_turn.unit_event_id(u), TurnManager.tile_field(u.tile_position),
		] as Array[String])
		_turn.record_seize(u)
	_finish_action()


# Post-2026-05-20 review: Escape is now a deliberate ActionMenu entry (was
# auto-fire on zone entry under Decision 5). TurnManager.record_escape
# unregisters the unit and queue_frees it, then re-evaluates objectives.
# _finish_action is NOT called — record_escape already removed the unit from
# _unit_states / _original_tiles and the unit is being freed, so there is no
# unit to mark DONE. The cursor flow falls back to FREE via _selection.clear().
func _commit_escape() -> void:
	if _turn == null or _selection.selected_unit == null:
		_finish_action()
		return
	# Commit the RNG event before record_escape — it frees the unit and erases
	# its TurnManager bookkeeping, so the record must be built first.
	_turn.commit_action_event("escape", [
		_turn.unit_event_id(_selection.selected_unit),
		TurnManager.tile_field(_selection.selected_unit.tile_position),
	] as Array[String])
	_turn.record_escape(_selection.selected_unit)
	# selected_unit is now queue_freed; mirror _finish_action's bookkeeping
	# without touching the (freed) unit.
	_selection.clear()
	_state = State.FREE
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.unit_deselected.emit()
	repaint()  # back to FREE: restore any retained threat overlay


# ── State: TARGETING — delegated to MapCursorTargeting ───────────────────────

# Hand off to the targeting flow. begin() returns the valid target tiles; if there
# are none (ActionMenu should have prevented this) reopen the menu instead.
func _enter_targeting(mode: int) -> void:
	var tiles := _targeting.begin(mode, _selection.selected_unit)
	if tiles.is_empty():
		_show_action_menu()
		return
	_state = State.TARGETING
	_repaint_targeting_overlays()
	# Snap the cursor to the first valid target via _set_tile, so cursor_moved fires
	# (HUD updates to the target) and the camera scrolls to keep it on screen.
	_set_tile(tiles[0])


# MapCursorTargeting resolved the action (combat done / heal applied).
func _on_targeting_completed() -> void:
	_finish_action()


# Player backed out of target choice — return to the ActionMenu.
func _on_targeting_cancelled() -> void:
	_state = State.UNIT_MOVED
	# Snap the cursor back onto the acting unit (#9). Without this the cursor is
	# left on the last highlighted enemy tile, away from the unit taking the
	# action — mirrors how _enter_targeting snapped it onto the first target.
	if _selection.selected_unit != null:
		_set_tile(_selection.selected_unit.tile_position)
	_show_action_menu()


# ── Item Use ────────────────────────────────────────────────────────────────

func _use_item() -> void:
	if _selection.selected_unit == null or _selection.selected_unit.data == null:
		_show_action_menu()
		return
	if item_menu != null:
		# Show the item submenu; result arrives via _on_item_chosen / _on_item_menu_cancelled
		item_menu.show_for(_selection.selected_unit)
		_place_menu_near(item_menu, _selection.selected_unit.tile_position)
		return
	# Fallback when ItemMenu is not wired: consume first valid item automatically
	for entry in _selection.selected_unit.data.inventory:
		if entry.is_item() and entry.has_uses():
			_apply_item_effect(entry)
			break
	_finish_action()


func _on_item_chosen(entry: InventoryEntry) -> void:
	if _selection.selected_unit == null:
		_finish_action()
		return
	if _apply_item_effect(entry):
		_finish_action()


func _on_item_menu_cancelled() -> void:
	_show_action_menu()


func _apply_item_effect(entry: InventoryEntry) -> bool:
	var ih := get_node_or_null("/root/ItemHandler")
	if ih == null:
		push_warning("MapCursor: ItemHandler autoload not found")
		return true
	var item: ItemData = ih.get_item_data(entry)
	if item != null and item.effect_id == "promote" and promotion_screen != null:
		_pending_item_id = entry.item_id
		promotion_screen.open_for(_selection.selected_unit, entry,
			Callable(self, "_on_promotion_item_confirmed"),
			Callable(self, "_on_promotion_item_cancelled"))
		return false
	if item != null and item.effect_id == "reclass" and reclass_screen != null:
		_pending_item_id = entry.item_id
		reclass_screen.open_for(_selection.selected_unit, entry,
			Callable(self, "_on_promotion_item_confirmed"),
			Callable(self, "_on_promotion_item_cancelled"))
		return false
	_commit_item_event(entry.item_id)
	ih.apply_item(_selection.selected_unit, entry)
	return true


# RNG event for a committed item use (§3: [unit_id, from_tile, to_tile, item_id]).
# Committed before apply_item so any future item-granted EXP/level-up chains
# AFTER the item event, matching the attack→levelup ordering rule (§4).
func _commit_item_event(item_id: String) -> void:
	if _turn == null or _selection.selected_unit == null:
		return
	var record: Array[String] = _turn.make_move_record(_selection.selected_unit)
	record.append(item_id)
	_turn.commit_action_event("item", record)


# Stashed by _apply_item_effect while a promotion/reclass screen is open, so the
# confirm callback can commit the RNG event for the item that opened it.
var _pending_item_id: String = ""


func _on_promotion_item_confirmed() -> void:
	_commit_item_event(_pending_item_id)
	_pending_item_id = ""
	_finish_action()


func _on_promotion_item_cancelled() -> void:
	_show_action_menu()


# ── Weapon Swap (#8) ─────────────────────────────────────────────────────────
#
# Equipping is free: it doesn't consume the action. The flow stays in UNIT_MOVED
# — picking a weapon or cancelling just reopens the ActionMenu, which re-evaluates
# Attack/Staff availability against the newly equipped weapon.

func _open_weapon_menu() -> void:
	if weapon_menu == null or _selection.selected_unit == null:
		_show_action_menu()  # no menu wired / no unit — fall back to the ActionMenu
		return
	weapon_menu.show_for(_selection.selected_unit)
	_place_menu_near(weapon_menu, _selection.selected_unit.tile_position)


func _on_weapon_chosen(entry: InventoryEntry) -> void:
	if _selection.selected_unit != null:
		_selection.selected_unit.set_equipped_weapon(entry)
	_show_action_menu()


func _on_weapon_menu_cancelled() -> void:
	_show_action_menu()


# ── Shared Action Completion ─────────────────────────────────────────────────

# Commit the move as a Wait action — unit is marked DONE via _finish_action().
func _commit_wait() -> void:
	# Wait is a committed action: it advances the RNG chain (RNG-1) so it can
	# re-seed later dice — the design's accepted Wait-to-reroll exploit (RNG-3).
	if _turn != null and _selection.selected_unit != null:
		_turn.commit_action_event("wait", _turn.make_move_record(_selection.selected_unit))
	_finish_action()


# Cancel from unit_moved: snap the unit back to its pre-move tile and re-enter selection.
func _undo_move_and_reselect() -> void:
	if _state == State.LOCKED:
		return
	# The LOCKED guard owns _state; the slice handles the undo + overlay recompute.
	_selection.undo_and_reselect()
	_state = State.UNIT_SELECTED
	# W6f: snap the cursor back onto the unit after a movement cancel, mirroring
	# _on_targeting_cancelled. Otherwise the cursor is stranded on the cancelled
	# destination, away from the unit that still owns the action.
	if _selection.selected_unit != null:
		_set_tile(_selection.selected_unit.tile_position)
	_repaint_selection_overlays()


func _finish_action() -> void:
	# Mark the acting unit DONE so it can't be selected again this turn. Skip this
	# when the unit died mid-action (mutual kill / Vantage counter-kill): it is
	# already out of TurnManager._unit_states, and set_unit_state would re-insert a
	# stale freed-node key.
	var u := _selection.selected_unit
	if is_instance_valid(u) and u != null and u.data != null and u.data.hp > 0:
		_set_tile(u.tile_position)
	if _turn != null and is_instance_valid(u) and u.data != null and u.data.hp > 0:
		_turn.set_unit_state(u, TurnManager.UnitState.DONE)
	_selection.clear()
	_state = State.FREE
	# Tell the HUD the unit is no longer selected. Without this the HUD stays
	# latched on the unit that just acted and stops following the cursor (#6).
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.unit_deselected.emit()
	repaint()  # back to FREE: restore any retained threat overlay


# ── Map Menu / End Turn ──────────────────────────────────────────────────────

# Cycles the cursor to the next/previous player unit that can still act.
# step +1 = forward (Tab / next_unit), step -1 = backward (Shift+Tab / prev_unit).
# Wraps around. Uses can_unit_act so MOVED units (mid-action) are included, not
# just READY ones.
func _cycle_to_next_unit(step: int) -> void:
	if _state != State.FREE or _turn == null:
		return
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return
	var actable_units: Array[Node] = []
	for u in gs.get_living_player_units():
		if _turn.can_unit_act(u):
			actable_units.append(u)
	if actable_units.is_empty():
		return
	# Find the unit currently under the cursor, if any.
	var current_idx: int = -1
	for i in actable_units.size():
		if actable_units[i].tile_position == current_tile:
			current_idx = i
			break
	var target_idx: int
	if current_idx == -1:
		# Cursor not on an actable unit — forward starts at the first, backward
		# at the last, so a single press always lands somewhere sensible.
		target_idx = 0 if step > 0 else actable_units.size() - 1
	else:
		target_idx = (current_idx + step + actable_units.size()) % actable_units.size()
	_set_tile(actable_units[target_idx].tile_position)


func _open_map_menu() -> void:
	if map_menu == null:
		return
	_map_menu_suspend_available = can_capture_suspend()
	if map_menu.has_method("set_suspend_available"):
		map_menu.call("set_suspend_available", _map_menu_suspend_available)
	lock()
	map_menu.open()
	# Consume the triggering press. Without this the same keystroke keeps
	# propagating to MapMenu._unhandled_input, which treats open_menu/cancel as
	# a close — flickering the menu shut on the very keystroke that opened it.
	if is_inside_tree():
		get_viewport().set_input_as_handled()


func can_capture_suspend() -> bool:
	if _state != State.FREE or _input_suppressed:
		return false
	# V030-SUS-01 (c): gate Suspend & Quit to the blue player phase only (v1
	# answer). A non-blue capture (e.g. debug-hotseating the red team) restores
	# a phase that locks the cursor but never re-enters the awaited faction
	# scheduler, so resume comes up with a frozen cursor and no way to act. The
	# blue-phase gate sidesteps that until restore can re-enter the scheduler.
	# With this gate, start_map_from_suspend never restores a non-blue phase, so
	# the debug-hotseat latch re-derivation there (TurnManager.gd:135) is moot.
	var gs := get_node_or_null("/root/GameState")
	return gs != null and gs.is_player_turn()


func capture_suspend_ui_state() -> Dictionary:
	_prune_watch_set()
	return {
		"cursor_tile": current_tile,
		"mode": "free",
		"watch_set": _watch_set.keys(),
		"danger_mode": _danger_mode,
	}


func apply_suspend_ui_state(suspend_state: Dictionary) -> void:
	var tile: Vector2i = current_tile
	if suspend_state.has("cursor_tile"):
		tile = SaveCodec.vector2i_from_dict(suspend_state["cursor_tile"], current_tile)
	_watch_set.clear()
	for unit_id in suspend_state.get("watch_set", []):
		var id: String = String(unit_id)
		if id != "":
			_watch_set[id] = true
	var mode: String = String(suspend_state.get("danger_mode", DANGER_MODE_NONE))
	_danger_mode = mode if mode in VALID_DANGER_MODES else DANGER_MODE_NONE
	_set_tile(tile)
	repaint()


func _on_end_turn_requested() -> void:
	if _turn == null:
		return
	var faction_id: String = _turn.active_faction()
	if faction_id == "":
		faction_id = "blue"
	if _turn.are_all_units_done(faction_id):
		_turn.request_end_phase()
		return
	# Some units haven't acted — keep cursor locked and ask for confirmation.
	_awaiting_end_turn_confirm = true
	var dlg := ConfirmationDialog.new()
	dlg.dialog_text = "Some units have not acted yet.\nEnd turn anyway?"
	dlg.confirmed.connect(func():
		_awaiting_end_turn_confirm = false
		_turn.request_end_phase()
		dlg.queue_free()
	)
	dlg.canceled.connect(func():
		_awaiting_end_turn_confirm = false
		unlock()
		dlg.queue_free()
	)
	get_tree().root.add_child(dlg)
	dlg.popup_centered()
	# Focus the Cancel button, not OK (#15/#16): the safe choice is the default,
	# so a mashed or held confirm key dismisses the prompt instead of ending the
	# turn early. The game cancel key still closes it via the dialog's ui_cancel.
	dlg.get_cancel_button().grab_focus()


func _on_map_menu_closed() -> void:
	_map_menu_suspend_available = false
	if _awaiting_end_turn_confirm:
		return
	if _turn != null and not _turn.is_locally_controlled_faction(_turn.active_faction()):
		return
	unlock()


func _on_suspend_and_quit_requested() -> void:
	if not _can_write_suspend_from_menu():
		push_error("MapCursor: suspend requested outside a free local-control boundary")
		_map_menu_suspend_available = false
		unlock()
		return
	var dlg := ConfirmationDialog.new()
	dlg.dialog_text = "Suspend and return to the main menu?\nYou can continue from this point later."
	dlg.confirmed.connect(func():
		dlg.queue_free()
		if _write_suspend_save():
			_return_to_main_menu()
		else:
			_map_menu_suspend_available = false
			_show_suspend_failed_dialog()
	)
	dlg.canceled.connect(func():
		_map_menu_suspend_available = false
		dlg.queue_free()
		if _turn != null and not _turn.is_locally_controlled_faction(_turn.active_faction()):
			return
		unlock()
	)
	get_tree().root.add_child(dlg)
	dlg.popup_centered()
	dlg.get_cancel_button().grab_focus()


func _on_quit_to_menu_requested() -> void:
	var dlg := ConfirmationDialog.new()
	dlg.dialog_text = "Return to the main menu?\nUnsaved map progress will be lost."
	dlg.confirmed.connect(func():
		dlg.queue_free()
		_return_to_main_menu()
	)
	dlg.canceled.connect(func():
		dlg.queue_free()
		if _turn != null and not _turn.is_locally_controlled_faction(_turn.active_faction()):
			return
		unlock()
	)
	get_tree().root.add_child(dlg)
	dlg.popup_centered()
	dlg.get_cancel_button().grab_focus()


func _can_write_suspend_from_menu() -> bool:
	if _input_suppressed:
		return false
	if _map_menu_suspend_available:
		if _turn != null:
			return _turn.is_locally_controlled_faction(_turn.active_faction())
		var gs := get_node_or_null("/root/GameState")
		return gs != null and gs.is_player_turn()
	return can_capture_suspend()


func _write_suspend_save() -> bool:
	if not _can_write_suspend_from_menu():
		return false
	var gs := get_node_or_null("/root/GameState")
	var save_manager := get_node_or_null("/root/SaveManager")
	if gs == null or not gs.has_method("capture_suspend_save"):
		push_error("MapCursor: GameState cannot capture suspend save")
		return false
	if save_manager == null or not save_manager.has_method("save_suspend"):
		push_error("MapCursor: SaveManager cannot write suspend save")
		return false
	var save: Variant = gs.call("capture_suspend_save", _turn, self)
	if save == null:
		push_error("MapCursor: suspend capture returned null")
		return false
	return bool(save_manager.call("save_suspend", save))


func _show_suspend_failed_dialog() -> void:
	var dlg := AcceptDialog.new()
	dlg.dialog_text = "Suspend save failed.\nMap progress was not saved."
	dlg.confirmed.connect(func():
		dlg.queue_free()
		if _turn != null and not _turn.is_locally_controlled_faction(_turn.active_faction()):
			return
		unlock()
	)
	get_tree().root.add_child(dlg)
	dlg.popup_centered()
	dlg.get_ok_button().grab_focus()


func _return_to_main_menu() -> void:
	_map_menu_suspend_available = false
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.call("reset_map_state")
	get_tree().change_scene_to_file("res://scenes/core/Boot.tscn")


# ── Settings ─────────────────────────────────────────────────────────────────

# open_settings hotkey (#3). Opens Settings from free roam, or from a unit
# selection — the selection is dropped first. Ignored mid-action (ActionMenu /
# targeting) so a half-finished action can't be stranded behind the overlay.
func _open_settings_via_hotkey() -> void:
	if _state == State.UNIT_SELECTED:
		_deselect()
	elif _state != State.FREE:
		return
	_open_settings()


# Map-menu "Settings" button (#3). The map menu has hidden itself; the cursor is
# already LOCKED — just show the settings overlay.
func _on_settings_requested() -> void:
	_open_settings()


# Shows the settings overlay and locks the cursor until it is closed.
func _open_settings() -> void:
	if settings_screen == null:
		return
	lock()
	settings_screen.open()


# Settings closed (Back / cancel) — unlock unless the enemy phase owns the lock.
func _on_settings_closed() -> void:
	if _turn != null:
		if not _turn.is_locally_controlled_faction(_turn.active_faction()):
			return
		unlock()
		return
	var gs := get_node_or_null("/root/GameState")
	if gs != null and not gs.is_player_turn():
		return
	unlock()


# ── Unit Details (#1) ────────────────────────────────────────────────────────

# inspect_unit hotkey. Opens the read-only details page for the unit under the
# cursor. Available in free roam and while a unit is selected; ignored mid-action
# so a half-finished action can't be stranded. Uses the _input_suppressed flag
# (not lock()) so a live unit selection and its overlays survive the inspection.
func _open_unit_details() -> void:
	if unit_details == null or _grid == null:
		return
	if _state != State.FREE and _state != State.UNIT_SELECTED:
		return
	var unit := _grid.get_unit_at(current_tile)
	if unit == null:
		return
	_input_suppressed = true
	_input_handler.clear_repeat()
	_clear_zoom_repeat()
	unit_details.open(unit)
	# Consume the triggering press so UnitDetailsScreen._unhandled_input doesn't
	# treat the same inspect_unit keystroke as a close.
	if is_inside_tree():
		get_viewport().set_input_as_handled()


# Details page closed — resume cursor input. The FSM _state was never touched,
# so a unit that was selected stays selected.
func _on_unit_details_closed() -> void:
	_input_suppressed = false


# ── Lock / Unlock ────────────────────────────────────────────────────────────

func lock() -> void:
	_state = State.LOCKED
	_input_handler.clear_repeat()
	_clear_zoom_repeat()
	# Clear the danger-overlay paint when input is suppressed (map menu, enemy
	# phase) so a stale threat area isn't shown after enemies move; the watch-set
	# and mode are retained and repainted on return to FREE.
	_clear_overlay_paint()


func unlock() -> void:
	_state = State.FREE
	repaint()  # back to FREE: recompute the retained threat overlay from current positions


# Called by TurnManager when a temporary debug controller handoff ends. It backs
# out of uncommitted player choices so a normally AI-controlled phase can resume
# from a clean state instead of inheriting a half-open menu or moved unit.
func cancel_transient_control_for_handoff() -> void:
	_input_handler.clear_repeat()
	_clear_zoom_repeat()
	_awaiting_end_turn_confirm = false
	_context_menu_anchor.clear()
	_hide_if_visible(action_menu)
	_hide_if_visible(item_menu)
	_hide_if_visible(weapon_menu)
	_hide_if_visible(map_menu)
	_hide_if_visible(settings_screen)
	_hide_if_visible(unit_details)
	if attack_preview != null and attack_preview.has_method("hide_preview"):
		attack_preview.hide_preview()
	if _state == State.TARGETING:
		_targeting.abort()
	if _state == State.UNIT_MOVED or _state == State.TARGETING:
		_selection.undo_and_reselect()
	_selection.clear()
	_clear_overlay_paint()
	_input_suppressed = false
	_state = State.FREE
	repaint()  # back to FREE: restore any retained threat overlay
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.unit_deselected.emit()


func _hide_if_visible(node: Node) -> void:
	if node != null and node.has_method("hide"):
		node.hide()


# ── Camera Scrolling ─────────────────────────────────────────────────────────

# The live camera-pan buffer — the player-set value (#17) when SettingsManager
# is loaded, otherwise the GameConstants default. Clamped to 0-5 as belt-and-
# braces: SettingsManager also clamps on load, but guarding here keeps the
# scroll math sound regardless of how the value was set.
func _camera_edge_buffer() -> int:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm != null:
		return clampi(sm.camera_edge_buffer, 0, 5)
	return CAMERA_EDGE_BUFFER


# Applies an absolute map-zoom index from UI code outside the cursor input flow.
# Re-frames on the live cursor tile and returns the clamped index actually used.
func apply_zoom_index(index: int) -> int:
	if _camera_ctrl == null:
		return index
	var applied: int = _camera_ctrl.set_zoom_index(index, current_tile, _camera_edge_buffer())
	_reposition_context_menu_anchor()
	return applied


# Steps the map zoom one level (direction +1 in / -1 out), re-framing on the
# cursor, then persists the resulting index. No-op without a camera controller.
func _apply_zoom_step(direction: int) -> void:
	if _camera_ctrl == null:
		return
	var idx: int = _camera_ctrl.step_zoom(direction, current_tile, _camera_edge_buffer())
	_persist_zoom_index(idx)
	_reposition_context_menu_anchor()


# Resets the map zoom to the default 1× level, re-framing on the cursor.
func _apply_zoom_reset() -> void:
	if _camera_ctrl == null:
		return
	var idx: int = _camera_ctrl.reset_zoom(current_tile, _camera_edge_buffer())
	_persist_zoom_index(idx)
	_reposition_context_menu_anchor()


func _arm_zoom_repeat(direction: int) -> void:
	if direction == 0:
		_clear_zoom_repeat()
		return
	_zoom_held_direction = direction
	_zoom_held_timer = ZOOM_REPEAT_DELAY


func _clear_zoom_repeat() -> void:
	_zoom_held_direction = 0
	_zoom_held_timer = 0.0


func _poll_held_zoom(delta: float) -> int:
	var zoom_in_strength := Input.get_action_strength("zoom_in")
	var zoom_out_strength := Input.get_action_strength("zoom_out")
	var strength: float = maxf(zoom_in_strength, zoom_out_strength)
	if strength < ZOOM_PRESS_THRESHOLD:
		_clear_zoom_repeat()
		return 0
	var direction := 1 if zoom_in_strength >= zoom_out_strength else -1
	if direction != _zoom_held_direction:
		_arm_zoom_repeat(direction)
		return direction
	_zoom_held_timer -= delta
	if _zoom_held_timer <= 0.0:
		_zoom_held_timer = _zoom_repeat_rate(strength)
		return _zoom_held_direction
	return 0


func _zoom_repeat_rate(strength: float) -> float:
	var t: float = clampf((strength - ZOOM_PRESS_THRESHOLD) / (1.0 - ZOOM_PRESS_THRESHOLD),
		0.0, 1.0)
	return lerpf(ZOOM_REPEAT_RATE_SLOW, ZOOM_REPEAT_RATE_FAST, t)


# Writes the chosen zoom index back to SettingsManager so it survives map changes
# and restarts. Silently skips when SettingsManager isn't present (headless tests).
func _persist_zoom_index(idx: int) -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm != null:
		sm.set("map_zoom_index", idx)
		sm.call("save")


# When the cursor approaches the screen edge, pan the camera to keep it visible.
# Thin delegation to CameraController.keep_cursor_in_view (B4).
func _scroll_camera_if_needed() -> void:
	if _camera_ctrl == null:
		return
	_camera_ctrl.keep_cursor_in_view(current_tile, _camera_edge_buffer())
