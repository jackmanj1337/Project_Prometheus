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
# "enabled"|"disabled" — whether the mouse drives the on-map cursor at all.
# When "enabled", mouse motion moves the cursor in FREE / UNIT_SELECTED states
# and snaps to the nearest valid target in TARGETING. When "disabled", mouse
# motion is ignored entirely so stray bumps don't move the cursor in keyboard
# play (PT4 #1). Mouse *clicks* (confirm/cancel/middle-click danger toggle) are
# intentional acts and remain active in both modes.
var mouse_cursor: String = "enabled"
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
	_apply_keybindings()
	_mirror_game_keys_to_ui()


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
	mouse_cursor      = cfg.get_value("gameplay", "mouse_cursor",      mouse_cursor)
	# Migration (2026-05-20): the setting was renamed from mouse_targeting (values
	# "snap"|"disabled") to mouse_cursor (values "enabled"|"disabled") because the
	# old name covered only the TARGETING state. Honour an old cfg key once so
	# saved preferences survive the rename. Remove this branch once no in-flight
	# cfg files are likely to carry the legacy key.
	var legacy_mouse: String = cfg.get_value("gameplay", "mouse_targeting", "")
	if legacy_mouse != "":
		mouse_cursor = "disabled" if legacy_mouse == "disabled" else "enabled"
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
	cfg.set_value("gameplay", "mouse_cursor",      mouse_cursor)
	cfg.set_value("gameplay", "auto_end_turn",      auto_end_turn)
	cfg.set_value("gameplay", "camera_edge_buffer", camera_edge_buffer)
	cfg.set_value("gameplay", "map_zoom_index",     map_zoom_index)

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
			mouse_cursor      = "enabled"
			auto_end_turn      = true
			camera_edge_buffer = 2
			map_zoom_index     = 3
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


# Returns per-tile Tween duration in seconds based on movement_speed setting
func get_movement_speed_seconds() -> float:
	match movement_speed:
		"fast":    return 0.06
		"instant": return 0.0
		_:         return 0.12
