extends Node
# Persists player preferences to user://settings.cfg via ConfigFile.
# Loaded once at startup; written immediately on every change.

const SETTINGS_PATH := "user://settings.cfg"

# --- Audio (0–100 int scale) ---
var master_volume: int = 80
var music_volume: int = 70
var sfx_volume: int = 90

# --- Gameplay ---
# "all"|"player_only"|"enemy_only"|"none"
var combat_animations: String = "all"
# "normal"|"fast"|"instant"
var movement_speed: String = "normal"
# "show"|"skip"
var phase_banner: String = "show"
# "show"|"auto"|"skip"
var level_up_screen: String = "show"
# "follow"|"click"|"disabled" — how mouse/touch drives the on-map cursor.
# follow: hover moves the cursor and targeting snaps to the nearest valid target.
# click: hover is inert; first click moves the cursor, second same-tile click confirms.
# disabled: mouse motion never moves the cursor. Clicks remain intentional actions.
const VALID_MOUSE_CURSOR_MODES: Array[String] = ["follow", "click", "disabled"]
var mouse_cursor: String = "follow"
# Whether the player phase ends automatically once every unit has acted (#2).
var auto_end_turn: bool = true
# Tiles from the viewport edge that trigger a camera pan (#17). Default mirrors
# GameConstants.CURSOR_CAMERA_EDGE_BUFFER; MapCursor reads this at scroll time.
var camera_edge_buffer: int = 2
# Last map-zoom level, as an index into CameraController.ZOOM_LEVELS (Display &
# Accessibility item 1). Default 3 == 1.0× (mirrors CameraController.DEFAULT_ZOOM_INDEX).
# GameMap applies it on map load; MapCursor writes it on every scroll/zoom-key.
var map_zoom_index: int = 3
# NOTE: permadeath and leveling_method are per-save gameplay rules, not global
# preferences — they live on GameState, set via the New Game screen.

# --- Display (Display & Accessibility items 2–3) ---
# Window mode: "windowed" | "borderless" (windowed-fullscreen) | "fullscreen" (exclusive).
var window_mode: String = "windowed"
# Windowed resolution as "WxH"; only applied in windowed mode (fullscreen uses the
# native screen size). Curated 16:9 list — the canvas_items + keep stretch letterboxes
# any non-16:9 screen so absolute-offset scene nodes never push off-screen. 1440p/4K
# are native desktop options (V021-19); all stay 16:9 so the stretch contract holds.
var resolution: String = "1280x720"
const RESOLUTION_CHOICES: Array[String] = [
	"1280x720", "1600x900", "1920x1080", "2560x1440", "3840x2160",
]
# Conservative decoration allowance for titled windowed mode. Godot sizes the
# client area, while the OS adds title bar/borders outside it; keeping this margin
# prevents monitor-sized windowed clients from hiding the title bar.
const WINDOWED_DECORATION_MARGIN: Vector2i = Vector2i(96, 96)
# Menu/modal scale (item 3 split), an index into MENU_SCALE_LEVELS. Default 2 == 1.0×.
# Applied only to menu/modal panels through the "menu_scale_targets" group so HUD
# readouts stay controlled by the HUD Layout editor instead of a global window scale.
var menu_scale_index: int = 2
const MENU_SCALE_SCHEMA_VERSION: int = 2
const MENU_SCALE_LEVELS: Array[float] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
# Per-panel HUD layout (item 4), keyed by stable panel id -> { "offset": Vector2,
# "scale": float }. A missing entry = that panel's authored layout. Edited via the
# in-map "Edit HUD Layout" mode and applied by HUD.apply_layout.
var hud_layout: Dictionary = {}

# --- Controls ---
# { action_name: Array[InputEvent] }; applied to InputMap at startup
var keybindings: Dictionary = {}

# Baseline ui_* events captured at startup BEFORE the first mirror, so a later
# re-mirror (after rebind_action) can reset ui_accept etc. to their defaults
# (Enter/Space/etc. from project.godot) before re-stamping the current game-key
# events. Without this, rebinding "confirm" from Z to Y would leave Z attached
# to ui_accept indefinitely. Code review 2026-06-10 issue 2.9.
var _ui_baseline_events: Dictionary = {}


func _ready() -> void:
	load_settings()
	_apply_audio()
	_apply_display()
	_apply_menu_scale()
	_apply_keybindings()
	_mirror_game_keys_to_ui()
	# V027-04a: nothing re-applied Menu Scale when the window size changed, so a
	# post-resize content-minimum change (font re-measure under the new stretch
	# scale) grew a live scroll-frame panel off-screen with nobody re-centering
	# it — the V026-01a failure shape, resize-triggered. One hook self-heals this
	# and every future "layout changed under a live menu" variant.
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)
	if err != OK:
		# First run or missing file — defaults stay in place
		return

	master_volume = cfg.get_value("audio", "master_volume", master_volume)
	music_volume  = cfg.get_value("audio", "music_volume",  music_volume)
	sfx_volume    = cfg.get_value("audio", "sfx_volume",    sfx_volume)

	combat_animations = cfg.get_value("gameplay", "combat_animations", combat_animations)
	movement_speed    = cfg.get_value("gameplay", "movement_speed",    movement_speed)
	phase_banner      = cfg.get_value("gameplay", "phase_banner",      phase_banner)
	level_up_screen   = cfg.get_value("gameplay", "level_up_screen",   level_up_screen)
	mouse_cursor = normalize_mouse_cursor_mode(
		cfg.get_value("gameplay", "mouse_cursor", mouse_cursor))
	# Migration (2026-05-20/2026-06-20): old cfgs used mouse_targeting
	# ("snap"|"disabled") and then mouse_cursor ("enabled"|"disabled").
	# Keep both generations readable: enabled→follow, snap→click.
	var legacy_mouse: String = cfg.get_value("gameplay", "mouse_targeting", "")
	if legacy_mouse != "":
		mouse_cursor = normalize_mouse_cursor_mode(legacy_mouse)
	auto_end_turn      = cfg.get_value("gameplay", "auto_end_turn",      auto_end_turn)
	# Clamp on load: the SettingsScreen slider is limited to 0-5, but a hand-edited
	# or corrupt cfg could feed an out-of-range value into the camera-scroll math.
	camera_edge_buffer = clampi(
		cfg.get_value("gameplay", "camera_edge_buffer", camera_edge_buffer), 0, 5)
	# Clamp on load: a hand-edited/corrupt cfg or a future change to ZOOM_LEVELS's
	# length must never feed an out-of-range index into the camera. 8 levels today
	# (indices 0–7); the upper bound is a static guard, not a hard contract.
	map_zoom_index = clampi(
		cfg.get_value("gameplay", "map_zoom_index", map_zoom_index), 0, 7)

	window_mode = cfg.get_value("display", "window_mode", window_mode)
	resolution  = cfg.get_value("display", "resolution",  resolution)
	# Clamp on load so a stale/corrupt index never indexes past MENU_SCALE_LEVELS.
	# Migration: old builds stored this as ui_scale_index when it scaled the whole GUI.
	# v2 prepends 0.5×, so old index values shift up one slot to preserve the
	# selected factor (old 1 == 1.0×, new 2 == 1.0×). The shift only applies when a
	# value was actually stored — shifting the in-memory default would silently move
	# a cfg that predates the menu-scale setting from 1.0× to 1.25×.
	var has_stored_menu_scale: bool = cfg.has_section_key("display", "menu_scale_index") \
		or cfg.has_section_key("display", "ui_scale_index")
	var stored_menu_scale_index: int = cfg.get_value("display", "menu_scale_index",
		cfg.get_value("display", "ui_scale_index", menu_scale_index))
	var menu_scale_schema_version: int = int(cfg.get_value(
		"display", "menu_scale_schema_version", 1))
	if has_stored_menu_scale and menu_scale_schema_version < MENU_SCALE_SCHEMA_VERSION:
		stored_menu_scale_index += 1
	menu_scale_index = clampi(stored_menu_scale_index, 0, MENU_SCALE_LEVELS.size() - 1)
	# Stored as a Dictionary (ConfigFile round-trips Vector2/float Variants). HUD
	# tolerates malformed/partial entries at apply time, so no clamp is needed here.
	hud_layout = cfg.get_value("display", "hud_layout", {})

	keybindings = cfg.get_value("controls", "keybindings", {})
	# Old settings.cfg files may still carry stale permadeath/leveling_method keys
	# under [gameplay] — harmless, they are simply never read.


func save() -> void:
	var cfg := ConfigFile.new()

	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "music_volume",  music_volume)
	cfg.set_value("audio", "sfx_volume",    sfx_volume)

	cfg.set_value("gameplay", "combat_animations", combat_animations)
	cfg.set_value("gameplay", "movement_speed",    movement_speed)
	cfg.set_value("gameplay", "phase_banner",      phase_banner)
	cfg.set_value("gameplay", "level_up_screen",   level_up_screen)
	# mouse_cursor is normalized on load and whenever the SettingsScreen sets it, so
	# it is already a canonical value here — save() just persists it (no mutation).
	cfg.set_value("gameplay", "mouse_cursor",      mouse_cursor)
	cfg.set_value("gameplay", "auto_end_turn",      auto_end_turn)
	cfg.set_value("gameplay", "camera_edge_buffer", camera_edge_buffer)
	cfg.set_value("gameplay", "map_zoom_index",     map_zoom_index)

	cfg.set_value("display", "window_mode",    window_mode)
	cfg.set_value("display", "resolution",     resolution)
	cfg.set_value("display", "menu_scale_index", menu_scale_index)
	cfg.set_value("display", "menu_scale_schema_version", MENU_SCALE_SCHEMA_VERSION)
	cfg.set_value("display", "hud_layout",     hud_layout)

	cfg.set_value("controls", "keybindings", keybindings)

	var err := cfg.save(SETTINGS_PATH)
	if err != OK:
		push_error("SettingsManager: failed to save settings: %s" % error_string(err))


# Resets one section ("audio"|"controls"|"gameplay") to defaults and saves.
func reset_section_to_defaults(section: String) -> void:
	match section:
		"audio":
			master_volume = 80
			music_volume  = 70
			sfx_volume    = 90
			_apply_audio()
		"gameplay":
			combat_animations = "all"
			movement_speed    = "normal"
			phase_banner      = "show"
			level_up_screen   = "show"
			mouse_cursor      = "follow"
			auto_end_turn      = true
			camera_edge_buffer = 2
			map_zoom_index     = 3
		"display":
			window_mode    = "windowed"
			resolution     = "1280x720"
			menu_scale_index = 2
			hud_layout     = {}
			_apply_display()
			_apply_menu_scale()
		"controls":
			keybindings = {}
			_apply_keybindings()
	save()


# Formula per GDD_01: linear_to_db(volume / 100.0).
# Look up by name so bus order in the editor doesn't matter.
# Buses that don't exist yet (Music/SFX must be added in editor) are silently skipped.
func _apply_audio() -> void:
	var master_idx := AudioServer.get_bus_index("Master")
	var music_idx  := AudioServer.get_bus_index("Music")
	var sfx_idx    := AudioServer.get_bus_index("SFX")
	if master_idx >= 0: AudioServer.set_bus_volume_db(master_idx, linear_to_db(master_volume / 100.0))
	if music_idx  >= 0: AudioServer.set_bus_volume_db(music_idx,  linear_to_db(music_volume  / 100.0))
	if sfx_idx    >= 0: AudioServer.set_bus_volume_db(sfx_idx,    linear_to_db(sfx_volume    / 100.0))


# True on platforms where window mode + resolution are honourable display controls.
# False on Web, where the canvas is sized/letterboxed by the browser + the stretch
# system, so DisplayServer window resize and the confirm-or-revert dialog are
# meaningless (E1, mobile-web prep). A single seam so neither _apply_display nor the
# Settings screen plumbs the platform check independently. Desktop is unchanged.
func is_display_config_supported() -> bool:
	return not OS.has_feature("web")


# Applies the window mode and (in windowed mode) the chosen resolution via
# DisplayServer. Called at startup and whenever the display settings change. The
# DisplayServer calls are safe no-ops on a headless server, so tests that never run
# _ready() are unaffected. Fullscreen modes use the native screen size, so the
# resolution is only meaningful — and only applied — in windowed mode.
func _apply_display() -> void:
	# E1: Web can't honour a DisplayServer resize/fullscreen change; skip it there so
	# the browser/stretch system stays in control of the canvas.
	if not is_display_config_supported():
		return
	match window_mode:
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		"borderless":
			# Godot's WINDOW_MODE_FULLSCREEN is borderless ("windowed fullscreen").
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		_:  # "windowed"
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var size := _parse_resolution(resolution)
			if size != Vector2i.ZERO:
				var screen := DisplayServer.window_get_current_screen()
				var usable := DisplayServer.screen_get_usable_rect(screen)
				size = windowed_client_size_for_screen(size, usable.size)
				DisplayServer.window_set_size(size)
				# Re-centre the window on its screen after a resize.
				DisplayServer.window_set_position(window_centre_position(
					usable.position, usable.size, size))


# Top-left position that centres a `size` window on a screen at `origin`/`screen_size`,
# clamped so the position never goes above/left of the screen origin. A window larger
# than the screen therefore keeps its title bar reachable (honouring the chosen size)
# instead of being centred into negative coordinates. Pure + side-effect-free for tests.
func window_centre_position(origin: Vector2i, screen_size: Vector2i, size: Vector2i) -> Vector2i:
	var offset := (screen_size - size) / 2
	return origin + Vector2i(maxi(offset.x, 0), maxi(offset.y, 0))


# Windowed mode should never request a client area so large the OS title bar
# becomes unreachable. Exact monitor-size output belongs to Borderless or
# Fullscreen; this helper keeps Windowed inside the usable screen while preserving
# the 16:9 display contract.
func windowed_client_size_for_screen(requested: Vector2i, screen_size: Vector2i) -> Vector2i:
	if requested == Vector2i.ZERO or screen_size == Vector2i.ZERO:
		return requested
	var usable := Vector2i(
		maxi(1, screen_size.x - WINDOWED_DECORATION_MARGIN.x),
		maxi(1, screen_size.y - WINDOWED_DECORATION_MARGIN.y))
	if requested.x <= usable.x and requested.y <= usable.y:
		return requested
	var width: int = mini(requested.x, usable.x)
	var height: int = roundi(float(width) * 9.0 / 16.0)
	if height > usable.y:
		height = mini(requested.y, usable.y)
		width = roundi(float(height) * 16.0 / 9.0)
	return Vector2i(maxi(1, width), maxi(1, height))


# The client size the current windowed resolution actually resolves to on the active
# screen after the usable-rect clamp. Lets the Settings screen explain in-game why a
# 4K request yields a smaller window (V025-06). Returns the raw parsed size when
# display config is unsupported (web) or the screen usable rect can't be read.
func applied_windowed_size() -> Vector2i:
	var size := _parse_resolution(resolution)
	if size == Vector2i.ZERO or not is_display_config_supported():
		return size
	var screen := DisplayServer.window_get_current_screen()
	var usable := DisplayServer.screen_get_usable_rect(screen)
	if usable.size == Vector2i.ZERO:
		return size
	return windowed_client_size_for_screen(size, usable.size)


# Parses a "WxH" resolution string to a Vector2i; returns ZERO on a malformed value
# so the caller leaves the window size untouched.
func _parse_resolution(res: String) -> Vector2i:
	var parts := res.split("x")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))


# Single safe-area provider (D5/E6). Insets (left, top, right, bottom) in pixels of
# the unsafe screen margins — notch / rounded corners / home-indicator on mobile,
# zero on desktop and in the browser (the web shell reserves its bottom inset via CSS
# OUTSIDE the canvas). HUD + menu edge-anchoring read this single source via
# get_safe_area_insets(), so a soon mobile-web release can feed real in-canvas insets
# (from DisplayServer.get_display_safe_area() / JavaScriptBridge) by writing this one
# member — no call-site re-plumbing. Stays ZERO until that feed lands; mobile is
# Deferred as a platform in GDD_10 until then.
var safe_area_insets: Vector4i = Vector4i.ZERO


# The single read seam for safe-area insets (see safe_area_insets). Returns zero on
# desktop, so all edge-anchoring is unchanged there.
func get_safe_area_insets() -> Vector4i:
	return safe_area_insets


func get_menu_scale() -> float:
	return MENU_SCALE_LEVELS[clampi(menu_scale_index, 0, MENU_SCALE_LEVELS.size() - 1)]


# True while a deferred menu-scale re-apply is pending (V027-04a): an OS drag
# fires many size_changed events, so they coalesce into one re-apply per settled
# frame instead of one per event.
var _menu_scale_reapply_queued: bool = false


func _on_viewport_size_changed() -> void:
	if _menu_scale_reapply_queued:
		return
	_menu_scale_reapply_queued = true
	_reapply_menu_scale_after_resize.call_deferred()


func _reapply_menu_scale_after_resize() -> void:
	_menu_scale_reapply_queued = false
	# Idempotent: apply_menu_scale overrides scale off each target's captured
	# bases, so re-applying never compounds (the V021-08 contract).
	_apply_menu_scale()


# Scales menu/modal panels only. The root Window scale is reset to 1.0 so the HUD
# stays at authored size unless the HUD Layout editor changes a specific panel.
func _apply_menu_scale() -> void:
	var win := get_window()
	# Only write the reset when it changes something: Window.set_content_scale_factor
	# emits size_changed even for a same-value write, which would re-queue the
	# V027-04a resize hook forever (re-apply → size_changed → re-apply → …).
	if win != null and win.content_scale_factor != 1.0:
		win.content_scale_factor = 1.0
	if is_inside_tree():
		get_tree().call_group("menu_scale_targets", "apply_menu_scale", get_menu_scale())


func _apply_keybindings() -> void:
	for action in keybindings:
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		for event in keybindings[action]:
			InputMap.action_add_event(action, event)


const _UI_MIRROR: Dictionary = {
	"ui_up": "cursor_up", "ui_down": "cursor_down",
	"ui_left": "cursor_left", "ui_right": "cursor_right",
	"ui_accept": "confirm", "ui_cancel": "cancel",
}


# Snapshots the engine-default ui_* events (Enter/Space on ui_accept etc.)
# the first time the mirror runs. Restored at the top of every subsequent
# mirror call so a later re-mirror after rebind_action() doesn't leave the
# previous binding stuck on ui_accept. Capturing lazily (instead of in _ready)
# means a direct test caller that hits _mirror_game_keys_to_ui without going
# through _ready still gets the right baseline on first call.
func _capture_ui_baseline_if_needed() -> void:
	if not _ui_baseline_events.is_empty():
		return
	for ui_action in _UI_MIRROR:
		if not InputMap.has_action(ui_action):
			continue
		var events: Array[InputEvent] = []
		for event in InputMap.action_get_events(ui_action):
			events.append(event)
		_ui_baseline_events[ui_action] = events


# Mirrors the game's cursor/confirm/cancel keys onto Godot's built-in ui_* actions.
# Menus navigate via ui_* (arrows + Enter/Space by default); without this, the
# game's WASD/Z keys do nothing on a menu (#7). Runs after _apply_keybindings()
# so any user rebind of a game action carries over to the menus too.
#
# Each call first resets every mirrored ui_* action back to its baseline (the
# engine defaults captured in _capture_ui_baseline) before stamping the current
# game-action events on top. This makes the function idempotent across rebinds:
# unbinding "confirm" away from Z removes Z from ui_accept too.
func _mirror_game_keys_to_ui() -> void:
	_capture_ui_baseline_if_needed()
	for ui_action in _UI_MIRROR:
		var game_action: String = _UI_MIRROR[ui_action]
		if not InputMap.has_action(ui_action) or not InputMap.has_action(game_action):
			continue
		# Reset ui_action to its baseline (engine defaults), then re-stamp every
		# current game-action event. action_has_event keeps the add idempotent
		# for events already on the baseline (e.g. arrows on ui_up).
		InputMap.action_erase_events(ui_action)
		for event in _ui_baseline_events.get(ui_action, [] as Array[InputEvent]):
			InputMap.action_add_event(ui_action, event)
		for event in InputMap.action_get_events(game_action):
			if not InputMap.action_has_event(ui_action, event):
				InputMap.action_add_event(ui_action, event)


func set_volume(bus_name: String, value: int) -> void:
	value = clampi(value, 0, 100)
	match bus_name:
		"Master": master_volume = value
		"Music":  music_volume  = value
		"SFX":    sfx_volume    = value
	_apply_audio()
	save()


func rebind_action(action_name: String, event: InputEvent) -> void:
	keybindings[action_name] = [event]
	_apply_keybindings()
	# Re-mirror so the ui_* actions consumed by menus track the new binding —
	# rebinding "confirm" must also re-anchor "ui_accept". _mirror_game_keys_to_ui
	# is idempotent (action_has_event guards every add) so the redundant call on
	# the unchanged actions is cheap. Code review 2026-06-10 issue 2.9.
	_mirror_game_keys_to_ui()
	save()


# Normalizes live and legacy mouse cursor values to the V021-17 vocabulary.
static func normalize_mouse_cursor_mode(value: Variant) -> String:
	var mode := String(value)
	match mode:
		"enabled":
			return "follow"
		"snap":
			return "click"
		"follow", "click", "disabled":
			return mode
	return "follow"


# Returns per-tile Tween duration in seconds based on movement_speed setting
func get_movement_speed_seconds() -> float:
	match movement_speed:
		"fast":    return 0.06
		"instant": return 0.0
		_:         return 0.12
