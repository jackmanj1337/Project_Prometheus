extends Node
# Persists player preferences to user://settings.cfg via ConfigFile.
# Loaded once at startup; written immediately on every change.

const SETTINGS_PATH := "user://settings.cfg"
const UserDataMigrationScript = preload("res://scripts/shared/UserDataMigration.gd")

# --- Signals ---
# Emitted after save() completes so runtime managers can re-read in-memory
# values without SettingsScreen knowing every consumer.
signal settings_changed
# Emitted after an OS resize is written back into `resolution` (V027-04b/Q5) so
# an open Settings screen can re-sync its Resolution dropdown + applied readout.
signal resolution_written_back
# Emitted after any observed window/viewport resize pass settles. This includes
# maximized/restored transitions that deliberately do not write back `resolution`.
signal display_size_changed

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
# native screen size). RESOLUTION_CHOICES are 16:9 CONVENIENCE PRESETS (1440p/4K are
# native desktop options, V021-19), but under the expand model (UI-VIEWPORT-ASPECT-
# 2026-07-31) the window is no longer constrained to 16:9 — a free OS drag-resize writes
# the actual NON-preset "WxH" here (V027-04b/Q5 full write-back) and the viewport expands
# to fill whatever aspect results. The Settings dropdown shows a non-preset size as "Custom".
var resolution: String = "1280x720"
# The client size _apply_display last requested (V027-04b): a size_changed that
# matches it is our own programmatic resize; anything else while windowed is an
# OS resize (edge drag / maximize) and gets written back into `resolution`.
var _requested_window_size: Vector2i = Vector2i.ZERO
# Last DisplayServer window mode the resize hook observed (V028-03/Q2). Lets the hook
# tell a maximize->windowed transition (restore the saved size) apart from a genuine
# windowed edge drag (write the new size back). -1 until first observed.
var _last_window_mode: int = -1
const RESOLUTION_CHOICES: Array[String] = [
	"1280x720",
	"1600x900",
	"1920x1080",
	"2560x1440",
	"3840x2160",
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
# Grid-dim accessibility knob (B6-MRD slice 5 / [MRD-5]). Fades the TERRAIN
# TileMapLayer only (units + overlays stay full opacity) so threat/range overlays
# read more clearly against busy terrain. 0.0 = no dim, 0.5 = half-faded terrain.
const GRID_DIM_MAX: float = 0.5
var grid_dim: float = 0.0

# --- Content scale (viewport expand model, UI-VIEWPORT-ASPECT-2026-07-31) ---
# With content_scale_size=(0,0) + aspect=EXPAND (project.godot), the logical viewport
# equals window_size / content_scale_factor, so a bigger display at a fixed factor
# reveals MORE map tiles instead of scaling the same view up. Persisted; first launch
# derives the identity-diagonal default (~screen_height/720 snapped to 0.5) so existing
# players see NO change — 1.5x @1080p and 2.0x @1440p both reproduce the legacy 20x11.2
# logical view (measured, design doc viewport_expand_more_tiles_scoping §C.1). This
# replaces MenuScale's old premise that the window factor stays a global 1.
const CONTENT_SCALE_FACTOR_MIN: float = 0.5
const CONTENT_SCALE_FACTOR_MAX: float = 4.0
var content_scale_factor: float = 1.0

# --- Controls ---
const VALID_INPUT_MODES: Array[String] = ["auto", "gamepad", "touch", "mouse_keyboard"]
const VALID_TEXT_ENTRY_MODES: Array[String] = ["auto", "grid", "hardware", "system"]
const VALID_TOUCH_CONTROLS: Array[String] = ["dedicated", "virtual_gamepad"]
# Persisted preference; InputModeManager resolves this into the live active mode.
var input_mode: String = "auto"
var text_entry_mode: String = "auto"
var touch_controls: String = "dedicated"
# "follow"|"click"|"disabled" — how mouse/touch drives the on-map cursor.
# follow: hover moves the cursor and targeting snaps to the nearest valid target.
# click: hover is inert; first click moves the cursor, second same-tile click confirms.
# disabled: mouse motion never moves the cursor. Clicks remain intentional actions.
const VALID_MOUSE_CURSOR_MODES: Array[String] = ["follow", "click", "disabled"]
var mouse_cursor: String = "follow"
# Active profile name plus profile-ready binding maps. Each profile stores only
# player overrides; missing slots fall back to the project InputMap defaults.
const KEYBINDING_DEFAULT_PROFILE := "Default"
const KEYBINDING_SLOT_KBD := "kbd"
const KEYBINDING_SLOT_PAD := "pad"
var active_profile: String = KEYBINDING_DEFAULT_PROFILE
var profiles: Dictionary = {KEYBINDING_DEFAULT_PROFILE: {}}
# Active profile view: { action_name: { "kbd": token, "pad": token } }.
var keybindings: Dictionary = {}

# Baseline ui_* events captured at startup BEFORE the first mirror, so a later
# re-mirror (after rebind_action) can reset ui_accept etc. to their defaults
# (Enter/Space/etc. from project.godot) before re-stamping the current game-key
# events. Without this, rebinding "confirm" from Z to Y would leave Z attached
# to ui_accept indefinitely. Code review 2026-06-10 issue 2.9.
var _ui_baseline_events: Dictionary = {}
# Project InputMap events captured before any user rebind is applied. This lets
# reset/default fallback restore authored keyboard, mouse, and pad defaults.
var _action_baseline_events: Dictionary = {}
var _actions_with_applied_keybindings: Dictionary = {}

const _JOY_BUTTON_TOKENS: Dictionary = {
	JOY_BUTTON_A: "JoyA",
	JOY_BUTTON_B: "JoyB",
	JOY_BUTTON_X: "JoyX",
	JOY_BUTTON_Y: "JoyY",
	JOY_BUTTON_BACK: "JoyView",
	JOY_BUTTON_START: "JoyStart",
	JOY_BUTTON_LEFT_STICK: "JoyL3",
	JOY_BUTTON_RIGHT_STICK: "JoyR3",
	JOY_BUTTON_LEFT_SHOULDER: "JoyLB",
	JOY_BUTTON_RIGHT_SHOULDER: "JoyRB",
	JOY_BUTTON_DPAD_UP: "JoyDpadUp",
	JOY_BUTTON_DPAD_DOWN: "JoyDpadDown",
	JOY_BUTTON_DPAD_LEFT: "JoyDpadLeft",
	JOY_BUTTON_DPAD_RIGHT: "JoyDpadRight",
}
const _JOY_BUTTON_ALIASES: Dictionary = {
	"JoyA": JOY_BUTTON_A,
	"JoyB": JOY_BUTTON_B,
	"JoyX": JOY_BUTTON_X,
	"JoyY": JOY_BUTTON_Y,
	"JoyView": JOY_BUTTON_BACK,
	"View": JOY_BUTTON_BACK,
	"JoyBack": JOY_BUTTON_BACK,
	"JoyStart": JOY_BUTTON_START,
	"Start": JOY_BUTTON_START,
	"JoyL3": JOY_BUTTON_LEFT_STICK,
	"L3": JOY_BUTTON_LEFT_STICK,
	"JoyR3": JOY_BUTTON_RIGHT_STICK,
	"R3": JOY_BUTTON_RIGHT_STICK,
	"JoyLB": JOY_BUTTON_LEFT_SHOULDER,
	"LB": JOY_BUTTON_LEFT_SHOULDER,
	"JoyRB": JOY_BUTTON_RIGHT_SHOULDER,
	"RB": JOY_BUTTON_RIGHT_SHOULDER,
	"JoyDpadUp": JOY_BUTTON_DPAD_UP,
	"DpadUp": JOY_BUTTON_DPAD_UP,
	"JoyDpadDown": JOY_BUTTON_DPAD_DOWN,
	"DpadDown": JOY_BUTTON_DPAD_DOWN,
	"JoyDpadLeft": JOY_BUTTON_DPAD_LEFT,
	"DpadLeft": JOY_BUTTON_DPAD_LEFT,
	"JoyDpadRight": JOY_BUTTON_DPAD_RIGHT,
	"DpadRight": JOY_BUTTON_DPAD_RIGHT,
}


func _ready() -> void:
	# Must precede load_settings(): renaming application/config/name moved
	# user://, so on an existing install the settings file this is about to read
	# still lives under the old directory. This autoload is the first user://
	# reader in the autoload order, which is why the migration hangs here rather
	# than in a service of its own.
	UserDataMigrationScript.run()
	load_settings()
	_apply_audio()
	_apply_display()
	# Apply the global content scale before menu scale: _apply_menu_scale now derives
	# the on-screen menu factor RELATIVE to content_scale_factor, so the factor must be
	# live on the window first.
	_apply_content_scale()
	_apply_menu_scale()
	_apply_keybindings()
	_mirror_game_keys_to_ui()
	_apply_grid_dim()
	# After the content scale is live: the insets are expressed in viewport units,
	# so reading them before _apply_content_scale would divide by a stale factor.
	refresh_web_safe_area()
	# V027-04a: nothing re-applied Menu Scale when the window size changed, so a
	# post-resize content-minimum change (font re-measure under the new stretch
	# scale) grew a live scroll-frame panel off-screen with nobody re-centering
	# it — the V026-01a failure shape, resize-triggered. One hook self-heals this
	# and every future "layout changed under a live menu" variant. Also listen to
	# the root Window: with stretch/aspect=keep, one-axis edge drags can change the
	# OS client size without changing the stretched viewport size.
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	var win := get_window()
	if win != null:
		win.size_changed.connect(_on_window_size_changed)


# Printable gameplay keys (Z/X by default) are also mirrored into Godot's
# generic UI actions. FileDialog consumes those actions before its filename
# LineEdit can type them, so text editors get first ownership of printable input.
func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if (
		not key.pressed
		or key.unicode < 32
		or key.ctrl_pressed
		or key.alt_pressed
		or key.meta_pressed
	):
		return
	# Leave ordinary typing to the native editor. Only intercept printable keys
	# that would otherwise also fire a mirrored menu action before text insertion.
	if not (
		InputMap.event_is_action(key, "confirm")
		or InputMap.event_is_action(key, "cancel")
		or InputMap.event_is_action(key, "ui_accept")
		or InputMap.event_is_action(key, "ui_cancel")
	):
		return
	var focused := _focused_text_editor()
	if focused is LineEdit and (focused as LineEdit).editable:
		var line := focused as LineEdit
		if line.has_selection():
			var from := line.get_selection_from_column()
			line.delete_text(from, line.get_selection_to_column())
			line.caret_column = from
		line.insert_text_at_caret(char(key.unicode))
		focused.get_viewport().set_input_as_handled()
	elif focused is TextEdit and (focused as TextEdit).editable:
		(focused as TextEdit).insert_text_at_caret(char(key.unicode))
		focused.get_viewport().set_input_as_handled()


# FileDialog is a Window/Viewport of its own, so the root viewport cannot see
# its filename editor. Search visible dialogs explicitly before falling back to
# the ordinary scene viewport.
func _focused_text_editor() -> Control:
	var root_focus := get_viewport().gui_get_focus_owner()
	return root_focus if root_focus is LineEdit or root_focus is TextEdit else null


func load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)
	if err != OK:
		# First run or missing file — the declared defaults stay in place, EXCEPT the
		# ones derived from the device rather than authored. content_scale_factor was
		# only derived in the has_section_key branch below, which requires a settings
		# file that exists and merely lacks the key — an UPGRADE. A genuinely fresh
		# install returned here and kept the literal 1.0, so the identity-diagonal
		# default never applied to a new player at all; it survived unnoticed because
		# every developer and every returning tester has a cfg. Measured in a browser
		# on 2026-08-04: an iPhone-emulated first launch reported content=1.0 where the
		# fitted mobile default is 1.5.
		content_scale_factor = _derived_content_scale_factor()
		return

	master_volume = cfg.get_value("audio", "master_volume", master_volume)
	music_volume = cfg.get_value("audio", "music_volume", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx_volume", sfx_volume)

	combat_animations = cfg.get_value("gameplay", "combat_animations", combat_animations)
	movement_speed = cfg.get_value("gameplay", "movement_speed", movement_speed)
	phase_banner = cfg.get_value("gameplay", "phase_banner", phase_banner)
	level_up_screen = cfg.get_value("gameplay", "level_up_screen", level_up_screen)
	auto_end_turn = cfg.get_value("gameplay", "auto_end_turn", auto_end_turn)
	# Clamp on load: the SettingsScreen slider is limited to 0-5, but a hand-edited
	# or corrupt cfg could feed an out-of-range value into the camera-scroll math.
	camera_edge_buffer = clampi(
		cfg.get_value("gameplay", "camera_edge_buffer", camera_edge_buffer), 0, 5
	)
	# Clamp on load: a hand-edited/corrupt cfg or a future change to ZOOM_LEVELS's
	# length must never feed an out-of-range index into the camera. 8 levels today
	# (indices 0–7); the upper bound is a static guard, not a hard contract.
	map_zoom_index = clampi(cfg.get_value("gameplay", "map_zoom_index", map_zoom_index), 0, 7)

	window_mode = cfg.get_value("display", "window_mode", window_mode)
	resolution = cfg.get_value("display", "resolution", resolution)
	# Clamp on load so a stale/corrupt index never indexes past MENU_SCALE_LEVELS.
	# Migration: old builds stored this as ui_scale_index when it scaled the whole GUI.
	# v2 prepends 0.5×, so old index values shift up one slot to preserve the
	# selected factor (old 1 == 1.0×, new 2 == 1.0×). The shift only applies when a
	# value was actually stored — shifting the in-memory default would silently move
	# a cfg that predates the menu-scale setting from 1.0× to 1.25×.
	var has_stored_menu_scale: bool = (
		cfg.has_section_key("display", "menu_scale_index")
		or cfg.has_section_key("display", "ui_scale_index")
	)
	var stored_menu_scale_index: int = cfg.get_value(
		"display", "menu_scale_index", cfg.get_value("display", "ui_scale_index", menu_scale_index)
	)
	var menu_scale_schema_version: int = int(
		cfg.get_value("display", "menu_scale_schema_version", 1)
	)
	if has_stored_menu_scale and menu_scale_schema_version < MENU_SCALE_SCHEMA_VERSION:
		stored_menu_scale_index += 1
	menu_scale_index = clampi(stored_menu_scale_index, 0, MENU_SCALE_LEVELS.size() - 1)
	# Stored as a Dictionary (ConfigFile round-trips Vector2/float Variants). HUD
	# tolerates malformed/partial entries at apply time, so no clamp is needed here.
	hud_layout = cfg.get_value("display", "hud_layout", {})
	# Clamp on load: a hand-edited/corrupt cfg must never feed an out-of-range dim.
	grid_dim = clampf(cfg.get_value("display", "grid_dim", grid_dim), 0.0, GRID_DIM_MAX)
	# Content scale factor: on first launch (no stored key) derive the identity-diagonal
	# default so existing players see no change; otherwise load + clamp. Deliberately NOT
	# force-persisted on derive — re-deriving each launch on the same display yields the
	# same value, and it adapts if the player later moves to a different monitor until
	# they explicitly pick a factor (which save() then stores as a chosen value).
	if cfg.has_section_key("display", "content_scale_factor"):
		content_scale_factor = normalize_content_scale_factor(
			cfg.get_value("display", "content_scale_factor", content_scale_factor)
		)
	else:
		content_scale_factor = _derived_content_scale_factor()

	input_mode = normalize_input_mode(cfg.get_value("controls", "input_mode", input_mode))
	text_entry_mode = normalize_text_entry_mode(
		cfg.get_value("controls", "text_entry_mode", text_entry_mode)
	)
	touch_controls = normalize_touch_controls(
		cfg.get_value("controls", "touch_controls", touch_controls)
	)
	mouse_cursor = _load_mouse_cursor_mode(cfg)
	active_profile = String(cfg.get_value("controls", "active_profile", active_profile))
	var raw_profiles: Variant = cfg.get_value("controls", "profiles", {})
	var migrated_keybindings := false
	if raw_profiles is Dictionary and not (raw_profiles as Dictionary).is_empty():
		profiles = _normalize_keybinding_profiles(raw_profiles)
	else:
		# One-version migration from the old {action: Array[InputEvent]} cfg blob.
		profiles = {
			KEYBINDING_DEFAULT_PROFILE:
			_normalize_keybinding_map(cfg.get_value("controls", "keybindings", {}))
		}
		migrated_keybindings = cfg.has_section_key("controls", "keybindings")
	_ensure_active_keybinding_profile()
	if migrated_keybindings:
		save()
	# Old settings.cfg files may still carry stale permadeath/leveling_method keys
	# under [gameplay] — harmless, they are simply never read.


func save() -> void:
	var cfg := ConfigFile.new()

	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)

	cfg.set_value("gameplay", "combat_animations", combat_animations)
	cfg.set_value("gameplay", "movement_speed", movement_speed)
	cfg.set_value("gameplay", "phase_banner", phase_banner)
	cfg.set_value("gameplay", "level_up_screen", level_up_screen)
	cfg.set_value("gameplay", "auto_end_turn", auto_end_turn)
	cfg.set_value("gameplay", "camera_edge_buffer", camera_edge_buffer)
	cfg.set_value("gameplay", "map_zoom_index", map_zoom_index)

	cfg.set_value("display", "window_mode", window_mode)
	cfg.set_value("display", "resolution", resolution)
	cfg.set_value("display", "menu_scale_index", menu_scale_index)
	cfg.set_value("display", "menu_scale_schema_version", MENU_SCALE_SCHEMA_VERSION)
	cfg.set_value("display", "hud_layout", hud_layout)
	cfg.set_value("display", "grid_dim", grid_dim)
	cfg.set_value("display", "content_scale_factor", content_scale_factor)

	cfg.set_value("controls", "input_mode", input_mode)
	cfg.set_value("controls", "text_entry_mode", text_entry_mode)
	cfg.set_value("controls", "touch_controls", touch_controls)
	# Normalized on load and whenever SettingsScreen sets it; save() writes only
	# the new controls key while legacy gameplay keys remain readable.
	cfg.set_value("controls", "mouse_cursor", mouse_cursor)
	cfg.set_value("controls", "active_profile", active_profile)
	cfg.set_value("controls", "profiles", profiles)

	var err := cfg.save(SETTINGS_PATH)
	if err != OK:
		push_error("SettingsManager: failed to save settings: %s" % error_string(err))
	settings_changed.emit()


# Resets one section ("audio"|"controls"|"gameplay") to defaults and saves.
func reset_section_to_defaults(section: String) -> void:
	match section:
		"audio":
			master_volume = 80
			music_volume = 70
			sfx_volume = 90
			_apply_audio()
		"gameplay":
			combat_animations = "all"
			movement_speed = "normal"
			phase_banner = "show"
			level_up_screen = "show"
			auto_end_turn = true
			camera_edge_buffer = 2
			map_zoom_index = 3
		"display":
			window_mode = "windowed"
			resolution = "1280x720"
			menu_scale_index = 2
			hud_layout = {}
			grid_dim = 0.0
			# Reset re-derives the identity-diagonal default for the current display,
			# matching first-launch behaviour (no-change baseline for this screen).
			content_scale_factor = _derived_content_scale_factor()
			_apply_display()
			_apply_content_scale()
			_apply_menu_scale()
			_apply_grid_dim()
		"controls":
			input_mode = "auto"
			text_entry_mode = "auto"
			touch_controls = "dedicated"
			mouse_cursor = "follow"
			active_profile = KEYBINDING_DEFAULT_PROFILE
			profiles = {KEYBINDING_DEFAULT_PROFILE: {}}
			_ensure_active_keybinding_profile()
			_apply_keybindings()
			_mirror_game_keys_to_ui()
	save()


# Formula per GDD_01: linear_to_db(volume / 100.0).
# Look up by name so bus order in the editor doesn't matter.
# Buses that don't exist yet (Music/SFX must be added in editor) are silently skipped.
func _apply_audio() -> void:
	var master_idx := AudioServer.get_bus_index("Master")
	var music_idx := AudioServer.get_bus_index("Music")
	var sfx_idx := AudioServer.get_bus_index("SFX")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(master_volume / 100.0))
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(music_volume / 100.0))
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(sfx_volume / 100.0))


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
				_requested_window_size = size  # our resize — not an OS drag (V027-04b)
				DisplayServer.window_set_size(size)
				# Re-centre the window on its screen after a resize.
				DisplayServer.window_set_position(
					window_centre_position(usable.position, usable.size, size)
				)


# Top-left position that centres a `size` window on a screen at `origin`/`screen_size`,
# clamped so the position never goes above/left of the screen origin. A window larger
# than the screen therefore keeps its title bar reachable (honouring the chosen size)
# instead of being centred into negative coordinates. Pure + side-effect-free for tests.
func window_centre_position(origin: Vector2i, screen_size: Vector2i, size: Vector2i) -> Vector2i:
	var offset := (screen_size - size) / 2
	return origin + Vector2i(maxi(offset.x, 0), maxi(offset.y, 0))


# Windowed mode should never request a client area so large the OS title bar
# becomes unreachable. Exact monitor-size output belongs to Borderless or
# Fullscreen; this helper keeps Windowed inside the usable screen.
#
# UI-VIEWPORT-ASPECT-2026-07-31 (presets + free resize): clamp each axis INDEPENDENTLY
# to the usable area rather than forcing a 16:9 ratio. Under the expand model a window may
# be any aspect — the viewport expands to fill it — so an over-large or non-16:9 request
# keeps the largest area that still fits the title bar on-screen instead of being
# letterboxed back to 16:9. A request that already fits is returned unchanged.
func windowed_client_size_for_screen(requested: Vector2i, screen_size: Vector2i) -> Vector2i:
	if requested == Vector2i.ZERO or screen_size == Vector2i.ZERO:
		return requested
	var usable := Vector2i(
		maxi(1, screen_size.x - WINDOWED_DECORATION_MARGIN.x),
		maxi(1, screen_size.y - WINDOWED_DECORATION_MARGIN.y)
	)
	return Vector2i(mini(requested.x, usable.x), mini(requested.y, usable.y))


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


# Structured window-size status for the Settings readout (V028-02/Q1). The saved
# `resolution` string carries two DIFFERENT meanings and the readout must not conflate
# them (that produced the "Custom (3840x2071) -> applied 3563x2004" confusion):
#   - a PRESET (one of RESOLUTION_CHOICES) is a REQUEST the usable-rect clamp may shrink
#     before it is applied — so showing "requested -> applied" is meaningful there;
#   - a CUSTOM "WxH" written back by an OS resize (V027-04b) is ALREADY the observed
#     client size and must NOT be re-run through the usable-rect request clamp.
# Keys: "kind" ("preset"|"custom"); "requested" (Vector2i parsed from the saved
# string); "applied" (the clamp result for a preset, identical to requested for custom).
func windowed_size_status() -> Dictionary:
	var requested := _parse_resolution(resolution)
	var is_preset: bool = RESOLUTION_CHOICES.has(resolution)
	var applied := applied_windowed_size() if is_preset else requested
	return {
		"kind": "preset" if is_preset else "custom",
		"requested": requested,
		"applied": applied,
	}


# Parses a "WxH" resolution string to a Vector2i; returns ZERO on a malformed value
# so the caller leaves the window size untouched.
func _parse_resolution(res: String) -> Vector2i:
	var parts := res.split("x")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))


# Single safe-area provider (D5/E6). Insets (left, top, right, bottom) in pixels of
# the unsafe screen margins — notch / rounded corners / home-indicator on mobile,
# zero on desktop. HUD + menu edge-anchoring read this single source via
# get_safe_area_insets(), so the feed lands by writing this one member — no call-site
# re-plumbing. On web it is now fed from the PWA shell (see refresh_web_safe_area);
# DisplayServerWeb implements no get_display_safe_area at all, so without that feed
# the game draws under the Dynamic Island and the home indicator.
var safe_area_insets: Vector4i = Vector4i.ZERO


# The single read seam for safe-area insets (see safe_area_insets). Returns zero on
# desktop, so all edge-anchoring is unchanged there.
func get_safe_area_insets() -> Vector4i:
	return safe_area_insets


# Convert the shell's CSS-pixel insets into the VIEWPORT units the consumers work in.
#
# Two conversions, and both matter. The shell measures in CSS pixels while the engine
# window is sized in backing-buffer pixels, and the ratio between them is NOT reliably
# devicePixelRatio — it depends on the export's hidpi handling. So the ratio is
# MEASURED: window pixels per CSS pixel, from the canvas rect the shell publishes
# alongside the insets. Then viewport units are window pixels divided by the content
# scale factor, because HUD._safe_viewport_rect subtracts these from
# get_viewport_rect().size, which is already post-scale.
#
# Pure and side-effect-free so the arithmetic is unit-testable without a browser.
# Returns ZERO for any degenerate input rather than guessing: a zero-width canvas rect
# means the shell answered before layout, and a bogus scale would move every HUD panel.
static func safe_area_insets_from_shell(
	css_insets: Dictionary, canvas_css_size: Vector2, window_pixels: Vector2i, content_scale: float
) -> Vector4i:
	if canvas_css_size.x <= 0.0 or canvas_css_size.y <= 0.0:
		return Vector4i.ZERO
	if window_pixels.x <= 0 or window_pixels.y <= 0 or content_scale <= 0.0:
		return Vector4i.ZERO
	var pixels_per_css_x := float(window_pixels.x) / canvas_css_size.x
	var pixels_per_css_y := float(window_pixels.y) / canvas_css_size.y
	var left := _css_inset(css_insets, "left") * pixels_per_css_x / content_scale
	var right := _css_inset(css_insets, "right") * pixels_per_css_x / content_scale
	var top := _css_inset(css_insets, "top") * pixels_per_css_y / content_scale
	var bottom := _css_inset(css_insets, "bottom") * pixels_per_css_y / content_scale
	return Vector4i(int(roundf(left)), int(roundf(top)), int(roundf(right)), int(roundf(bottom)))


# A missing, non-numeric or negative inset reads as zero. env(safe-area-inset-*)
# falls back to 0px on every browser that does not implement it, so absence is the
# normal case rather than an error.
static func _css_inset(css_insets: Dictionary, key: String) -> float:
	if not css_insets.has(key):
		return 0.0
	var raw: Variant = css_insets[key]
	if not (raw is float or raw is int):
		return 0.0
	return maxf(float(raw), 0.0)


# Read the shell's published insets and canvas rect and write safe_area_insets.
# Web-only and fail-quiet: a build served through a shell without the bridge (an
# older export, or a plain godot.html) leaves the insets at zero, which is exactly
# the pre-feed behaviour.
func refresh_web_safe_area() -> void:
	if not OS.has_feature("web"):
		return
	var raw: Variant = JavaScriptBridge.eval(
		(
			"(window.PrometheusPWA && window.PrometheusPWA.canvasCssSize)"
			+ " ? JSON.stringify({safe: window.PrometheusPWA.safeArea(),"
			+ " css: window.PrometheusPWA.canvasCssSize()}) : ''"
		),
		true
	)
	var payload := String(raw) if raw != null else ""
	if payload.is_empty():
		return
	var parsed: Variant = JSON.parse_string(payload)
	if not (parsed is Dictionary):
		return
	var data := parsed as Dictionary
	var safe: Variant = data.get("safe", {})
	var css: Variant = data.get("css", {})
	if not (safe is Dictionary and css is Dictionary):
		return
	var css_size := Vector2(
		float((css as Dictionary).get("width", 0.0)), float((css as Dictionary).get("height", 0.0))
	)
	safe_area_insets = safe_area_insets_from_shell(
		safe as Dictionary, css_size, DisplayServer.window_get_size(), content_scale_factor
	)


func get_menu_scale() -> float:
	return MENU_SCALE_LEVELS[clampi(menu_scale_index, 0, MENU_SCALE_LEVELS.size() - 1)]


# On-screen menu scale, reconciled with the global content scale. MenuScale scales
# menu TYPE (font sizes) while content_scale_factor scales the whole canvas; without
# this division the two would MULTIPLY (up to 4x at the extremes). Dividing the menu
# factor by content_scale_factor makes (menu type-scale) x (canvas factor) resolve to
# get_menu_scale() on screen, so a menu keeps the SAME on-screen size regardless of the
# global factor. The global factor then governs only how much map is visible;
# MENU_SCALE stays an independent menu-comfort knob (UI-VIEWPORT-ASPECT-2026-07-31).
# Both call sites funnel through here: SettingsManager._apply_menu_scale (the group
# call) and MenuScale.factor_from_settings (late-instantiated menus self-applying).
func get_effective_menu_scale() -> float:
	return get_menu_scale() / maxf(content_scale_factor, CONTENT_SCALE_FACTOR_MIN)


# Public setter for the viewport content scale factor (the expand-model UI-scale knob:
# a lower factor reveals MORE map tiles, a higher one shows fewer/larger). Normalizes
# into range, applies to the window, re-reconciles menu scale (get_effective_menu_scale
# depends on this factor, so menus must re-apply to keep a fixed on-screen size), and
# persists. No-ops on an unchanged value so a same-value write never re-fires the resize
# hook. Returns the value actually applied (post-normalize) so a UI slider can reflect
# any clamp. Setter, not a bare field write, so callers get all three side effects.
#
# `persist` exists for callers whose value is scoped to one run rather than to the
# user's preferences — the web test bridge seeding a scale from a query parameter. It
# had no way to say that, so an instrumented run wrote its test scale to the settings
# file and a later run that omitted the parameter inherited it.
func set_content_scale_factor(value: float, persist: bool = true) -> float:
	var normalized := normalize_content_scale_factor(value)
	if is_equal_approx(normalized, content_scale_factor):
		return content_scale_factor
	content_scale_factor = normalized
	_apply_content_scale()
	_apply_menu_scale()
	if persist:
		save()
	return content_scale_factor


# True while a deferred menu-scale re-apply is pending (V027-04a): an OS drag
# fires many size_changed events, so they coalesce into one re-apply per settled
# frame instead of one per event.
var _menu_scale_reapply_queued: bool = false


func _on_viewport_size_changed() -> void:
	_queue_resize_refresh("viewport_size_changed")


func _on_window_size_changed() -> void:
	_queue_resize_refresh("window_size_changed")


func _queue_resize_refresh(trace_label: String) -> void:
	# Keep the label in the private signature for stable signal call sites; the
	# retired v0.3.0 resize trace no longer emits in normal builds.
	var _unused_trace_label := trace_label
	if _menu_scale_reapply_queued:
		return
	_menu_scale_reapply_queued = true
	_reapply_menu_scale_after_resize.call_deferred()


func _reapply_menu_scale_after_resize() -> void:
	_menu_scale_reapply_queued = false
	# A device rotation, a browser-chrome collapse and an orientation change all
	# arrive here as a resize, and every one of them changes the safe area. Reading
	# it at the same settled point keeps insets and layout in step instead of
	# leaving the HUD anchored to the previous orientation's notch.
	refresh_web_safe_area()
	# Idempotent: apply_menu_scale overrides scale off each target's captured
	# bases, so re-applying never compounds (the V021-08 contract).
	_apply_menu_scale()
	_maybe_write_back_os_resize()
	display_size_changed.emit()


# V027-04b (Q5 owner decision: FULL write-back): while windowed, an OS EDGE DRAG
# writes the actual client size back into the saved resolution, so the setting follows
# reality. Programmatic resizes are excluded by comparing against the size
# _apply_display requested. Deliberately NO recentre here — re-centring a window the
# user just placed is hostile.
#
# V028-03/Q2 refinement: a Windows MAXIMIZE is a transient window STATE, not a chosen
# windowed resolution, so its client size must NOT be persisted (that produced the
# "Custom (3840x2071)" readout). The policy lives in resize_write_back_action() so it
# is testable headless; this method only supplies the live DisplayServer reads.
func _maybe_write_back_os_resize() -> void:
	# Headless has no real window (tests emit size_changed freely); web has no
	# honourable window config at all.
	if not is_display_config_supported() or DisplayServer.get_name() == "headless":
		return
	var ds_mode := DisplayServer.window_get_mode()
	var action := resize_write_back_action(ds_mode, _last_window_mode)
	_last_window_mode = ds_mode
	match action:
		"write_back":
			apply_resize_write_back(DisplayServer.window_get_size())
		"restore":
			# Just left maximize: restore the chosen windowed size rather than
			# persisting the transient restored client size. _apply_display re-requests
			# the saved resolution (so apply_resize_write_back's own-resize guard makes
			# the follow-up size_changed a no-op).
			_apply_display()


# Pure resize-write-back policy (V028-03/Q2), split from the DisplayServer reads so it
# is testable headless. Given the current window mode and the previously observed one,
# returns the action for an OS resize event:
#   "write_back" — persist the observed client size (a genuine windowed edge drag);
#   "restore"    — the window just left maximize; re-apply the saved windowed size;
#   "ignore"     — not a windowed OS resize we act on (maximize itself, or non-windowed).
func resize_write_back_action(ds_mode: int, last_mode: int) -> String:
	if window_mode != "windowed":
		return "ignore"
	# Never persist the maximized client size — maximize is a window state, not a res.
	if ds_mode == DisplayServer.WINDOW_MODE_MAXIMIZED:
		return "ignore"
	if ds_mode != DisplayServer.WINDOW_MODE_WINDOWED:
		return "ignore"
	if last_mode == DisplayServer.WINDOW_MODE_MAXIMIZED:
		return "restore"
	return "write_back"


# The write-back core, split from the DisplayServer reads so it is testable
# headless: records `actual` as the new saved resolution + request baseline,
# schedules the disk persist, and notifies listeners. No-op for degenerate
# sizes and for the size we ourselves just requested.
#
# V031-DSP-01: the persist is settle-then-save, not per-event. The v0.3.1 live
# return proved a Windows edge drag fires many size events, and this method used
# to run a synchronous ConfigFile save() inside the OS resize modal loop on every
# one of them — heavy main-thread work exactly where the event stream later
# stalled. Memory state and the readout still update per event; the disk write
# coalesces to one save per settled drag.
func apply_resize_write_back(actual: Vector2i) -> void:
	if actual.x <= 0 or actual.y <= 0:
		return
	if actual == _requested_window_size:
		return
	resolution = "%dx%d" % [actual.x, actual.y]
	_requested_window_size = actual
	_queue_resize_settle_save()
	resolution_written_back.emit()


# ── V031-DSP-01: settle-then-persist + poll reconciliation ──────────────────

# One disk write per settled resize instead of one per size event. Re-arming the
# one-shot timer on every write-back means the save fires RESIZE_SETTLE_SAVE_DELAY
# after the LAST observed size change.
const RESIZE_SETTLE_SAVE_DELAY: float = 0.75
var _resize_save_pending: bool = false
var _settle_save_timer: Timer = null


func _queue_resize_settle_save() -> void:
	_resize_save_pending = true
	# Out-of-tree instances (headless policy tests) have no frame loop to run a
	# Timer; persist immediately — the settle window only matters for live drags.
	if not is_inside_tree():
		_flush_resize_settle_save()
		return
	if _settle_save_timer == null:
		_settle_save_timer = Timer.new()
		_settle_save_timer.one_shot = true
		_settle_save_timer.timeout.connect(_flush_resize_settle_save)
		add_child(_settle_save_timer)
	_settle_save_timer.start(RESIZE_SETTLE_SAVE_DELAY)


func _flush_resize_settle_save() -> void:
	if not _resize_save_pending:
		return
	_resize_save_pending = false
	save()


# A quit mid-settle must not lose the dragged size.
func _exit_tree() -> void:
	_flush_resize_settle_save()


# Low-frequency reconciliation poll. The v0.3.1 return proved size-changed
# delivery can stop entirely mid-drag (the one-axis drag stalled at 1125x633
# while the OS window grew to ~975 tall, and no event ever arrived for the
# final size). Comparing the real OS window size against the last observed
# value and feeding the same coalesced refresh path a missed signal would have
# guarantees the readout and saved size converge once the drag ends — even if
# the stall itself is never fully explained.
const RESIZE_POLL_INTERVAL: float = 0.5
var _resize_poll_accum: float = 0.0
var _last_polled_window_size: Vector2i = Vector2i.ZERO


func _process(delta: float) -> void:
	if not is_display_config_supported() or DisplayServer.get_name() == "headless":
		return
	_resize_poll_accum += delta
	if _resize_poll_accum < RESIZE_POLL_INTERVAL:
		return
	_resize_poll_accum = 0.0
	var size := DisplayServer.window_get_size()
	if _last_polled_window_size == Vector2i.ZERO:
		_last_polled_window_size = size
		return
	if size != _last_polled_window_size:
		_last_polled_window_size = size
		_queue_resize_refresh("poll_size_mismatch")


func _window_mode_name(mode: int) -> String:
	match mode:
		DisplayServer.WINDOW_MODE_WINDOWED:
			return "windowed"
		DisplayServer.WINDOW_MODE_MINIMIZED:
			return "minimized"
		DisplayServer.WINDOW_MODE_MAXIMIZED:
			return "maximized"
		DisplayServer.WINDOW_MODE_FULLSCREEN:
			return "fullscreen"
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			return "exclusive_fullscreen"
		_:
			return "unknown:%d" % mode


# Scales menu/modal panels only. The global window content_scale_factor is now owned
# by _apply_content_scale (the viewport expand model), NOT reset to 1.0 here — this
# method only drives per-menu TYPE scaling, reconciled against the global factor via
# get_effective_menu_scale() so menus keep a fixed on-screen size (see that method).
func _apply_menu_scale() -> void:
	if is_inside_tree():
		get_tree().call_group("menu_scale_targets", "apply_menu_scale", get_effective_menu_scale())


# Applies the global viewport content scale (the expand model). content_scale_size=(0,0)
# + aspect=EXPAND drop the fixed 1280x720 base so the logical viewport = window / factor;
# a bigger display at a fixed factor then shows more map tiles. The factor itself is the
# persisted content_scale_factor setting (identity-diagonal default on first launch).
func _apply_content_scale() -> void:
	var win := get_window()
	if win == null:
		return
	# Headless has no display to expand into and its window is a tiny fixed 64x64, so
	# content_scale_size=(0,0) would collapse the logical viewport to 64x64 and make all
	# layout math meaningless. The game never ships headless (it is the test/CI mode), so
	# fall back to the fixed project base there — a stable, deterministic logical viewport
	# equivalent to the pre-expand keep behaviour. Production is unaffected.
	if DisplayServer.get_name() == "headless":
		win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		win.content_scale_size = _project_base_viewport()
		if not is_equal_approx(win.content_scale_factor, 1.0):
			win.content_scale_factor = 1.0
		return
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	win.content_scale_size = Vector2i.ZERO
	# Same-value guard: Window.set_content_scale_factor emits size_changed even for an
	# identical write, which would re-queue the resize hook forever (the loop the old
	# menu-scale reset guarded against).
	if not is_equal_approx(win.content_scale_factor, content_scale_factor):
		win.content_scale_factor = content_scale_factor


# The project's authored base viewport (project.godot display/window/size). Used as the
# fixed logical size under the headless fallback above.
func _project_base_viewport() -> Vector2i:
	return Vector2i(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", 1280)),
		int(ProjectSettings.get_setting("display/window/size/viewport_height", 720)),
	)


# Fades every terrain layer in the "grid_dim_target" group. Terrain only — units
# and overlays stay full opacity ([MRD-5]). GameMap adds its terrain layer to the
# group and applies on load; set_grid_dim re-applies live from the slider.
func _apply_grid_dim() -> void:
	if not is_inside_tree():
		return
	for node in get_tree().get_nodes_in_group("grid_dim_target"):
		if node is CanvasItem:
			node.modulate.a = 1.0 - grid_dim


func set_grid_dim(value: float) -> void:
	grid_dim = clampf(value, 0.0, GRID_DIM_MAX)
	_apply_grid_dim()
	save()


func _apply_keybindings() -> void:
	_capture_action_baseline_if_needed()
	var actions_to_refresh := {}
	for action in _actions_with_applied_keybindings:
		actions_to_refresh[action] = true
	for action in keybindings:
		actions_to_refresh[action] = true
	for action in actions_to_refresh:
		_restore_action_baseline(String(action))
	for action in keybindings:
		_apply_keybinding_slots(String(action), keybindings[action])
	_actions_with_applied_keybindings = {}
	for action in keybindings:
		_actions_with_applied_keybindings[action] = true


func _capture_action_baseline_if_needed() -> void:
	if not _action_baseline_events.is_empty():
		return
	for action in InputMap.get_actions():
		var events: Array[InputEvent] = []
		for event in InputMap.action_get_events(action):
			if event is InputEvent:
				events.append(event)
		_action_baseline_events[action] = events


func _restore_action_baseline(action: String) -> void:
	if not InputMap.has_action(action):
		return
	InputMap.action_erase_events(action)
	for event in _action_baseline_events.get(action, [] as Array[InputEvent]):
		if event is InputEvent:
			InputMap.action_add_event(action, event)


func _apply_keybinding_slots(action: String, slots: Variant) -> void:
	if not InputMap.has_action(action) or not (slots is Dictionary):
		return
	for slot in [KEYBINDING_SLOT_KBD, KEYBINDING_SLOT_PAD]:
		if not (slots as Dictionary).has(slot):
			continue
		_erase_slot_events(action, slot)
		var token := String((slots as Dictionary).get(slot, "")).strip_edges()
		if token == "":
			continue
		var event := _event_from_token(token)
		if event == null or _slot_for_event(event) != slot:
			event = _default_event_for_slot(action, slot)
		if event != null:
			InputMap.action_add_event(action, event)


func _erase_slot_events(action: String, slot: String) -> void:
	var kept: Array[InputEvent] = []
	for event in InputMap.action_get_events(action):
		if _slot_for_event(event) != slot:
			kept.append(event)
	InputMap.action_erase_events(action)
	for event in kept:
		InputMap.action_add_event(action, event)


func _default_event_for_slot(action: String, slot: String) -> InputEvent:
	for event in _action_baseline_events.get(action, [] as Array[InputEvent]):
		if event is InputEvent and _slot_for_event(event) == slot:
			return event
	return null


func _slot_for_event(event: Variant) -> String:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return KEYBINDING_SLOT_PAD
	if event is InputEventKey or event is InputEventMouseButton:
		return KEYBINDING_SLOT_KBD
	return ""


func _normalize_slot_name(slot: String) -> String:
	var value := slot.strip_edges().to_lower()
	match value:
		"keyboard", "key", "mouse", "keyboard_mouse", "keyboard/mouse", "kbd":
			return KEYBINDING_SLOT_KBD
		"gamepad", "joypad", "pad":
			return KEYBINDING_SLOT_PAD
		_:
			return ""


func _normalize_keybinding_profiles(raw_profiles: Variant) -> Dictionary:
	var out := {}
	if not (raw_profiles is Dictionary):
		out[KEYBINDING_DEFAULT_PROFILE] = {}
		return out
	for profile_name in raw_profiles:
		var profile_key := String(profile_name).strip_edges()
		if profile_key == "":
			continue
		out[profile_key] = _normalize_keybinding_map((raw_profiles as Dictionary)[profile_name])
	if out.is_empty():
		out[KEYBINDING_DEFAULT_PROFILE] = {}
	return out


func _normalize_keybinding_map(raw_bindings: Variant) -> Dictionary:
	var out := {}
	if not (raw_bindings is Dictionary):
		return out
	for action in raw_bindings:
		var action_name := String(action)
		var slots := _normalize_keybinding_slots((raw_bindings as Dictionary)[action])
		if not slots.is_empty():
			out[action_name] = slots
	return out


func _normalize_keybinding_slots(raw_slots: Variant) -> Dictionary:
	var out := {}
	if raw_slots is Array:
		for raw_event in raw_slots:
			if not (raw_event is InputEvent):
				continue
			var slot := _slot_for_event(raw_event)
			if slot != "" and not out.has(slot):
				out[slot] = _event_to_token(raw_event)
		return out
	if not (raw_slots is Dictionary):
		return out
	for raw_slot in raw_slots:
		var slot := _normalize_slot_name(String(raw_slot))
		if slot == "":
			continue
		var token: String = _token_from_variant((raw_slots as Dictionary)[raw_slot])
		out[slot] = token
	return out


func _token_from_variant(value: Variant) -> String:
	if value == null:
		return ""
	if value is InputEvent:
		return _event_to_token(value)
	return String(value).strip_edges()


func _ensure_active_keybinding_profile() -> void:
	if active_profile.strip_edges() == "":
		active_profile = KEYBINDING_DEFAULT_PROFILE
	if (
		not profiles.has(KEYBINDING_DEFAULT_PROFILE)
		or not (profiles[KEYBINDING_DEFAULT_PROFILE] is Dictionary)
	):
		profiles[KEYBINDING_DEFAULT_PROFILE] = {}
	if not profiles.has(active_profile) or not (profiles[active_profile] is Dictionary):
		active_profile = KEYBINDING_DEFAULT_PROFILE
	keybindings = profiles[active_profile]


func _sync_active_keybinding_profile() -> void:
	if active_profile.strip_edges() == "":
		active_profile = KEYBINDING_DEFAULT_PROFILE
	if (
		not profiles.has(KEYBINDING_DEFAULT_PROFILE)
		or not (profiles[KEYBINDING_DEFAULT_PROFILE] is Dictionary)
	):
		profiles[KEYBINDING_DEFAULT_PROFILE] = {}
	profiles[active_profile] = keybindings


func _event_to_token(event: InputEvent) -> String:
	if event is InputEventKey:
		var parts: Array[String] = []
		if event.ctrl_pressed:
			parts.append("Ctrl")
		if event.shift_pressed:
			parts.append("Shift")
		if event.alt_pressed:
			parts.append("Alt")
		if event.meta_pressed:
			parts.append("Meta")
		var code: int = event.keycode if event.keycode != 0 else event.physical_keycode
		parts.append(OS.get_keycode_string(code))
		return "+".join(parts)
	if event is InputEventMouseButton:
		return "Mouse%d" % event.button_index
	if event is InputEventJoypadButton:
		return _JOY_BUTTON_TOKENS.get(event.button_index, "JoyButton%d" % event.button_index)
	if event is InputEventJoypadMotion:
		var suffix := "+" if event.axis_value >= 0.0 else "-"
		return "JoyAxis%d%s" % [event.axis, suffix]
	return ""


func _event_from_token(token: String) -> InputEvent:
	var clean := token.strip_edges()
	if clean == "":
		return null
	if clean.begins_with("Mouse"):
		var button_text := clean.trim_prefix("Mouse")
		if button_text.is_valid_int():
			var mouse := InputEventMouseButton.new()
			mouse.device = -1
			mouse.button_index = int(button_text)
			return mouse
	if clean.begins_with("JoyAxis"):
		var axis_text := clean.trim_prefix("JoyAxis")
		var sign := 1.0
		if axis_text.ends_with("-"):
			sign = -1.0
			axis_text = axis_text.trim_suffix("-")
		elif axis_text.ends_with("+"):
			axis_text = axis_text.trim_suffix("+")
		if axis_text.is_valid_int():
			var motion := InputEventJoypadMotion.new()
			motion.device = -1
			motion.axis = int(axis_text)
			motion.axis_value = sign
			return motion
	if _JOY_BUTTON_ALIASES.has(clean):
		var button := InputEventJoypadButton.new()
		button.device = -1
		button.button_index = int(_JOY_BUTTON_ALIASES[clean])
		return button
	if clean.begins_with("JoyButton"):
		var button_text := clean.trim_prefix("JoyButton")
		if button_text.is_valid_int():
			var button := InputEventJoypadButton.new()
			button.device = -1
			button.button_index = int(button_text)
			return button
	return _key_event_from_token(clean)


func _key_event_from_token(token: String) -> InputEventKey:
	var parts := token.split("+", false)
	if parts.is_empty():
		return null
	var key_name := parts[parts.size() - 1].strip_edges()
	var keycode := OS.find_keycode_from_string(key_name)
	if keycode == 0:
		return null
	var event := InputEventKey.new()
	event.device = -1
	event.keycode = keycode
	for i in range(parts.size() - 1):
		match parts[i].strip_edges().to_lower():
			"ctrl", "control":
				event.ctrl_pressed = true
			"shift":
				event.shift_pressed = true
			"alt":
				event.alt_pressed = true
			"meta", "cmd", "command":
				event.meta_pressed = true
			_:
				return null
	return event


const _UI_MIRROR: Dictionary = {
	"ui_up": "cursor_up",
	"ui_down": "cursor_down",
	"ui_left": "cursor_left",
	"ui_right": "cursor_right",
	"ui_accept": "confirm",
	"ui_cancel": "cancel",
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
		"Master":
			master_volume = value
		"Music":
			music_volume = value
		"SFX":
			sfx_volume = value
	_apply_audio()
	save()


func rebind_action(action_name: String, event: InputEvent, device_slot: String = "") -> void:
	var slot := _normalize_slot_name(device_slot) if device_slot != "" else _slot_for_event(event)
	if slot == "":
		push_warning("SettingsManager: unsupported input event for rebind: %s" % event)
		return
	var slots: Dictionary = keybindings.get(action_name, {}).duplicate()
	slots[slot] = _event_to_token(event)
	keybindings[action_name] = slots
	_sync_active_keybinding_profile()
	_apply_keybindings()
	# Re-mirror so the ui_* actions consumed by menus track the new binding —
	# rebinding "confirm" must also re-anchor "ui_accept". _mirror_game_keys_to_ui
	# is idempotent (action_has_event guards every add) so the redundant call on
	# the unchanged actions is cheap. Code review 2026-06-10 issue 2.9.
	_mirror_game_keys_to_ui()
	save()


func apply_keybindings(pending: Dictionary) -> void:
	for action in pending:
		var existing: Dictionary = keybindings.get(String(action), {}).duplicate()
		var slots := _normalize_keybinding_slots(pending[action])
		for slot in slots:
			existing[slot] = slots[slot]
		if existing.is_empty():
			keybindings.erase(String(action))
		else:
			keybindings[String(action)] = existing
	_sync_active_keybinding_profile()
	_apply_keybindings()
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


static func normalize_input_mode(value: Variant) -> String:
	var mode := String(value)
	if mode in VALID_INPUT_MODES:
		return mode
	return "auto"


# Clamps a stored/derived content scale factor into the supported range; a non-finite
# or non-positive value falls back to 1.0 (a corrupt cfg must never blank the viewport).
static func normalize_content_scale_factor(value: Variant) -> float:
	var f := float(value)
	if not is_finite(f) or f <= 0.0:
		return 1.0
	return clampf(f, CONTENT_SCALE_FACTOR_MIN, CONTENT_SCALE_FACTOR_MAX)


# The identity-diagonal factor for a given screen height: (height/720) snapped to 0.5
# and clamped. Pure + side-effect-free (no DisplayServer) so the migration calibration
# is unit-testable: 720->1.0, 1080->1.5, 1440->2.0, 2160->3.0. A non-positive height
# yields the 1.0 neutral. 1.5x @1080p and 2.0x @1440p reproduce the legacy 20x11.2 view.
static func identity_factor_for_height(screen_height: int) -> float:
	if screen_height <= 0:
		return 1.0
	return normalize_content_scale_factor(snappedf(float(screen_height) / 720.0, 0.5))


# Godot tags "mobile" only for a native Android/iOS export; a PWA on a phone is
# tagged web + web_ios / web_android. Lives here rather than in InputModeManager
# because InputModeManager already preloads this script (VALID_INPUT_MODES,
# normalize_input_mode) and the reverse direction would be circular.
const WEB_TOUCH_FEATURES: Array[String] = ["web_ios", "web_android"]


static func has_web_touch_platform() -> bool:
	for feature in WEB_TOUCH_FEATURES:
		if OS.has_feature(feature):
			return true
	return false


# The largest 0.5 step that still fits the 1280x720 design floor inside `window_px`.
#
# The identity factor above is calibrated for a DESKTOP MONITOR at desk distance and
# is derived from the SCREEN size. Neither holds for a phone browser: the screen is
# not the canvas (browser chrome, and an orientation-dependent report), and a 6-inch
# display at arm's length is a different legibility problem from a 27-inch one. On a
# 852x393 CSS canvas the screen-derived answer landed at the 0.5 minimum — the
# smallest UI available — which is exactly the reported "text is physically small".
#
# Fitting to the canvas gives the biggest UI the layouts can take without clipping,
# which is the best answer available before a physical-device pass tunes it. Snapping
# DOWN matters: snapping to nearest (what identity_factor_for_height does) can round
# up past the floor and clip every authored layout.
static func fit_content_scale_factor_for_size(window_px: Vector2i) -> float:
	if window_px.x <= 0 or window_px.y <= 0:
		return 1.0
	var fit := minf(float(window_px.x) / 1280.0, float(window_px.y) / 720.0)
	return normalize_content_scale_factor(floorf(fit / 0.5) * 0.5)


# First-launch / reset default: the identity diagonal for the current display so an
# existing player's view is unchanged. Falls back to 1.0 when no screen is queryable
# (headless), which is also the correct neutral for a 720p display. A mobile browser
# fits the canvas instead — see fit_content_scale_factor_for_size.
#
# [V070-01] The identity diagonal is derived from the SCREEN, but the factor is applied
# to the WINDOW, and project.godot opens that window at 1280x720. On a 3840x2160 desktop
# the two disagree badly: identity says 3.0, the window can only show 1280/3 x 720/3 =
# 427x240 logical px, and the main menu collapses into an unusable strip on first launch.
# The v0.7.0 return caught it with a screenshot. So the default is the SMALLER of what
# the display deserves and what the window can actually show; the player can still raise
# it afterwards, and a maximised window re-derives a larger fit.
func _derived_content_scale_factor() -> float:
	if DisplayServer.get_name() == "headless":
		return 1.0
	if has_web_touch_platform():
		return fit_content_scale_factor_for_size(DisplayServer.window_get_size())
	var screen := DisplayServer.window_get_current_screen()
	var identity := identity_factor_for_height(DisplayServer.screen_get_size(screen).y)
	var fit := fit_content_scale_factor_for_size(DisplayServer.window_get_size())
	return minf(identity, fit)


static func normalize_text_entry_mode(value: Variant) -> String:
	var mode := String(value)
	if mode in VALID_TEXT_ENTRY_MODES:
		return mode
	return "auto"


static func normalize_touch_controls(value: Variant) -> String:
	var mode := String(value)
	if mode in VALID_TOUCH_CONTROLS:
		return mode
	return "dedicated"


func _load_mouse_cursor_mode(cfg: ConfigFile) -> String:
	if cfg.has_section_key("controls", "mouse_cursor"):
		return normalize_mouse_cursor_mode(cfg.get_value("controls", "mouse_cursor", mouse_cursor))
	if cfg.has_section_key("gameplay", "mouse_cursor"):
		return normalize_mouse_cursor_mode(cfg.get_value("gameplay", "mouse_cursor", mouse_cursor))
	# Migration (2026-05-20/2026-06-20): old cfgs used mouse_targeting
	# ("snap"|"disabled") before mouse_cursor existed. Keep it readable.
	if cfg.has_section_key("gameplay", "mouse_targeting"):
		return normalize_mouse_cursor_mode(
			cfg.get_value("gameplay", "mouse_targeting", mouse_cursor)
		)
	return mouse_cursor


# Returns per-tile Tween duration in seconds based on movement_speed setting
func get_movement_speed_seconds() -> float:
	match movement_speed:
		"fast":
			return 0.06
		"instant":
			return 0.0
		_:
			return 0.12
