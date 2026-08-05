extends "res://scripts/ui/ModalScreen.gd"
# Settings screen: audio sliders, gameplay toggles, an editable keybinding list,
# and a back button. Reads values from SettingsManager on open(); writes back on
# every change. A full-rect opaque Dimmer makes the screen modal (#1); the inner
# content lives in a ScrollContainer so it never overflows the panel.
#
# Extends ModalScreen (B3) for the shared hide-on-ready + cancel-to-close
# wiring; this script overrides _close() to also emit back_pressed.
#
# Enum settings (the seven OptionButtons) are driven by _ENUM_SETTINGS below
# (B5 / 05-19 review §4). Adding a new enum setting is one schema row plus a
# named OptionButton in the scene — no new @onready / connect / _on_*_changed
# triplet per setting. Sliders and the keybindings list stay hand-
# wired because their shape (signal, label-update, value range) doesn't fit
# the OptionButton template.
#
# Scene: SettingsScreen > Dimmer + Panel > ScrollContainer > VBox > rows.

signal back_pressed

# Shared key-display helper — renders modifiers (Shift/Ctrl/Alt) so prev_unit
# (Shift+Tab) is distinguishable from next_unit (Tab) in the list (#3).
const InputDisplay = preload("res://scripts/shared/InputDisplay.gd")
# Source of truth for the Map Zoom slider's range + factor labels (Display &
# Accessibility item 1). The stored setting is an index into ZOOM_LEVELS.
const CameraControllerS = preload("res://scripts/core/CameraController.gd")
# In-map per-panel HUD layout editor (item 4), launched by the button below.
const HudLayoutEditorS = preload("res://scripts/ui/HudLayoutEditor.gd")
# 15s confirm-or-revert dialog for risky display changes (resolution / window mode).
const DisplayConfirmDialogS = preload("res://scripts/ui/DisplayConfirmDialog.gd")

const _SETTINGS_LABEL_COLUMN_WIDTH: float = 340.0
const _SETTINGS_ROW_SEPARATION: int = 8
const _KEYBIND_SLOT_KBD := "kbd"
const _KEYBIND_SLOT_PAD := "pad"
const _KEYBIND_CONFLICT_COLOR := Color(1.0, 0.55, 0.55)

@onready var _scroll: ScrollContainer = $Panel/ScrollContainer
@onready var _vbox: VBoxContainer = $Panel/ScrollContainer/Margin/VBox
@onready var _slider_master: HSlider = _vbox.get_node("HBoxMaster/SliderMaster")
@onready var _slider_music: HSlider = _vbox.get_node("HBoxMusic/SliderMusic")
@onready var _slider_sfx: HSlider = _vbox.get_node("HBoxSFX/SliderSFX")
@onready var _label_master: Label = _vbox.get_node("HBoxMaster/LabelMaster")
@onready var _label_music: Label = _vbox.get_node("HBoxMusic/LabelMusic")
@onready var _label_sfx: Label = _vbox.get_node("HBoxSFX/LabelSFX")
@onready var _slider_camera_buffer: HSlider = _vbox.get_node("HBoxCameraBuffer/SliderCameraBuffer")
@onready var _label_camera_buffer: Label = _vbox.get_node("HBoxCameraBuffer/LabelCameraBuffer")
@onready var _slider_map_zoom: HSlider = _vbox.get_node("HBoxMapZoom/SliderMapZoom")
@onready var _label_map_zoom: Label = _vbox.get_node("HBoxMapZoom/LabelMapZoom")
@onready var _slider_grid_dim: HSlider = _vbox.get_node("HBoxGridDim/SliderGridDim")
@onready var _label_grid_dim: Label = _vbox.get_node("HBoxGridDim/LabelGridDim")
@onready var _slider_menu_scale: HSlider = _vbox.get_node("HBoxUIScale/SliderUIScale")
@onready var _label_menu_scale: Label = _vbox.get_node("HBoxUIScale/LabelUIScale")
@onready
var _slider_viewport_scale: HSlider = _vbox.get_node("HBoxViewportScale/SliderViewportScale")
@onready
var _opt_game_view_preset: OptionButton = _vbox.get_node("HBoxGameViewPreset/OptGameViewPreset")
@onready var _slider_game_view_size: HSlider = _vbox.get_node("HBoxGameViewSize/SliderGameViewSize")
@onready var _label_game_view_size: Label = _vbox.get_node("HBoxGameViewSize/LabelGameViewSize")
@onready
var _slider_game_view_offset: HSlider = _vbox.get_node("HBoxGameViewOffset/SliderGameViewOffset")
@onready
var _label_game_view_offset: Label = _vbox.get_node("HBoxGameViewOffset/LabelGameViewOffset")
@onready
var _opt_game_view_aspect: OptionButton = _vbox.get_node("HBoxGameViewAspect/OptGameViewAspect")
@onready var _btn_reset_game_view: Button = _vbox.get_node("BtnResetGameView")
@onready var _label_viewport_scale: Label = _vbox.get_node("HBoxViewportScale/LabelViewportScale")
@onready
var _label_resolution_applied: Label = _vbox.get_node("HBoxResolution/LabelResolutionApplied")
@onready var _keybind_list: VBoxContainer = _vbox.get_node("KeybindList")
@onready var _btn_edit_hud: Button = _vbox.get_node("BtnEditHudLayout")
@onready var _btn_back: Button = _vbox.get_node("BtnBack")

var _pending_keybindings: Dictionary = {}
var _keybind_rows: Dictionary = {}
var _keybind_conflicts: Dictionary = {}
var _keybind_conflict_slots: Dictionary = {}
var _capturing_action: String = ""
var _capturing_slot: String = ""
var _btn_apply_keybindings: Button = null
var _btn_revert_keybindings: Button = null
var _display_refresh_queued: bool = false

# Data-driven schema for the OptionButton-style settings. Each row:
#   key:    SettingsManager field name (used for both get/set)
#   node:   path under _vbox to the OptionButton
#   values: ordered list of valid SettingsManager values (Variant)
#   labels: ordered display strings, parallel to `values`
#   hidden: optional bool — when true, the OptionButton is set invisible (used
#           for inert scaffolded settings like combat_animations until their
#           system lands)
#
# Adding a new enum setting:
#   1. Declare the @export/var on SettingsManager.gd (load/save still names it
#      explicitly, since it's a Godot field with a default).
#   2. Add a row here.
#   3. Add an OptionButton node to SettingsScreen.tscn at the named path.
const _ENUM_SETTINGS: Array = [
	{
		"key": "combat_animations",
		"node": "OptCombatAnim",
		"values": ["all", "player_only", "enemy_only", "none"],
		"labels": ["All", "Player Only", "Enemy Only", "None"],
		"hidden": true,  # no combat-animation system yet
	},
	{
		"key": "movement_speed",
		"node": "HBoxMovementSpeed/OptMovementSpeed",
		"values": ["normal", "fast", "instant"],
		"labels": ["Normal", "Fast", "Instant"],
	},
	{
		"key": "phase_banner",
		"node": "HBoxPhaseBanner/OptPhaseBanner",
		"values": ["show", "skip"],
		"labels": ["Show", "Skip"],
	},
	{
		"key": "level_up_screen",
		"node": "HBoxLevelUp/OptLevelUpScreen",
		"values": ["show", "auto", "skip"],
		"labels": ["Show", "Auto", "Skip"],
	},
	{
		# B6-INPUT input-mode/focus seam: the active input scheme. "availability" marks
		# this row for the gray-state pass — modes unsupported on the current platform
		# (e.g. Touch on desktop) are shown DISABLED, not hidden, so the vocabulary stays
		# visible/self-documenting while the engine's resolver still falls back at runtime.
		"key": "input_mode",
		"node": "HBoxInputMode/OptInputMode",
		"values": ["auto", "gamepad", "touch", "mouse_keyboard"],
		"labels": ["Auto", "Gamepad", "Touch", "Mouse & Keyboard"],
		"availability": true,
	},
	{
		"key": "text_entry_mode",
		"node": "HBoxTextEntryMode/OptTextEntryMode",
		"values": ["auto", "grid", "hardware", "system"],
		"labels": ["Auto", "On-screen Grid", "Hardware Keyboard", "System Keyboard"],
	},
	{
		"key": "mouse_cursor",
		"node": "HBoxMouseCursor/OptMouseCursor",
		"values": ["follow", "click", "disabled"],
		"labels": ["Follow", "Click", "Off"],
	},
	{
		"key": "auto_end_turn",
		"node": "HBoxAutoEndTurn/OptAutoEndTurn",
		"values": [false, true],
		"labels": ["Off", "On"],
	},
	{
		# Display & Accessibility item 2. "apply" re-runs the SettingsManager method
		# so the change takes effect live (not just on next launch). "confirm" routes
		# the change through the 15s confirm-or-revert dialog (a wrong fullscreen/
		# resolution can leave the screen unusable), so the new value is applied but
		# only persisted on confirm.
		"key": "window_mode",
		"node": "HBoxWindowMode/OptWindowMode",
		"values": ["windowed", "borderless", "fullscreen"],
		"labels": ["Windowed", "Borderless", "Fullscreen"],
		"apply": "_apply_display",
		"confirm": true,
	},
	{
		"key": "resolution",
		"node": "HBoxResolution/OptResolution",
		"values": ["1280x720", "1600x900", "1920x1080", "2560x1440", "3840x2160"],
		"labels":
		["1280 x 720", "1600 x 900", "1920 x 1080", "2560 x 1440 (1440p)", "3840 x 2160 (4K)"],
		"apply": "_apply_display",
		"confirm": true,
	},
]


# V031-GP-01: Settings scrolls with focus; route the base class's lookahead
# nudge at the shared ScrollContainer so scale-aware context stays visible.
func _focus_scroll_container() -> ScrollContainer:
	return _scroll


func _ready() -> void:
	# E1: window mode + resolution are confirm-gated DisplayServer controls that Web
	# can't honour. Hide those rows where display config isn't supported so the web
	# build never shows a dropdown + 15s confirm dialog that can't apply. Desktop keeps
	# every row. Defaults true if SettingsManager is somehow absent (desktop assumption).
	var sm_for_display := get_node_or_null("/root/SettingsManager")
	var display_supported: bool = (
		sm_for_display == null or sm_for_display.call("is_display_config_supported")
	)

	_setup_game_view_rows()

	# Schema-driven enum settings (B5).
	for s in _ENUM_SETTINGS:
		var btn: OptionButton = _vbox.get_node(s["node"])
		_populate_option_button(btn, s["labels"])
		# bind() partials the schema row into the handler so we have one
		# generic _on_enum_setting_changed instead of seven hand-rolled ones.
		btn.item_selected.connect(_on_enum_setting_changed.bind(s))
		# Gray-state rows (B6-INPUT input_mode): disable the items whose value is not
		# available on this platform instead of hiding the whole row.
		if s.get("availability", false):
			_apply_mode_availability(btn, s)
		if s.get("hidden", false):
			btn.visible = false
		# Confirm-gated rows are the DisplayServer ones (window mode / resolution);
		# hide their whole HBox row on platforms that can't apply them (E1).
		if s.get("confirm", false) and not display_supported:
			var row := btn.get_parent()
			if row is Control:
				(row as Control).visible = false

	# Hand-wired sliders (different shape — value range, value label, save path).
	_slider_master.min_value = 0
	_slider_master.max_value = 100
	_slider_master.step = 1
	_slider_music.min_value = 0
	_slider_music.max_value = 100
	_slider_music.step = 1
	_slider_sfx.min_value = 0
	_slider_sfx.max_value = 100
	_slider_sfx.step = 1
	_slider_camera_buffer.min_value = 0
	_slider_camera_buffer.max_value = 5
	_slider_camera_buffer.step = 1
	# Size the zoom slider from CameraController.ZOOM_LEVELS so adding a level only
	# touches that one array. The slider value IS the stored index.
	_slider_map_zoom.min_value = 0
	_slider_map_zoom.max_value = CameraControllerS.ZOOM_LEVELS.size() - 1
	_slider_map_zoom.step = 1
	_slider_grid_dim.min_value = 0.0
	_slider_grid_dim.max_value = 0.5
	_slider_grid_dim.step = 0.05
	# Menu-scale slider sized from SettingsManager.MENU_SCALE_LEVELS; value IS the index.
	var sm_for_range := get_node_or_null("/root/SettingsManager")
	if sm_for_range != null:
		_slider_menu_scale.min_value = 0
		_slider_menu_scale.max_value = sm_for_range.MENU_SCALE_LEVELS.size() - 1
		_slider_menu_scale.step = 1
		# Viewport Scale slider: value IS the content_scale_factor (a float, not an index),
		# stepped by 0.5 to match the identity-diagonal snap. Range = the supported clamp.
		_slider_viewport_scale.min_value = sm_for_range.CONTENT_SCALE_FACTOR_MIN
		_slider_viewport_scale.max_value = sm_for_range.CONTENT_SCALE_FACTOR_MAX
		_slider_viewport_scale.step = 0.5

	_slider_master.value_changed.connect(_on_master_changed)
	_slider_music.value_changed.connect(_on_music_changed)
	_slider_sfx.value_changed.connect(_on_sfx_changed)
	_slider_camera_buffer.value_changed.connect(_on_camera_buffer_changed)
	_slider_map_zoom.value_changed.connect(_on_map_zoom_changed)
	_slider_grid_dim.value_changed.connect(_on_grid_dim_changed)
	_slider_menu_scale.value_changed.connect(_on_menu_scale_changed)
	# Menu Scale applies on drag RELEASE, not live per-step (V025-01a): re-scaling the
	# screen mid-drag moves the slider track under the cursor, so the value oscillates
	# between adjacent steps. During a drag we only preview the factor in the label.
	_slider_menu_scale.drag_started.connect(_on_menu_scale_drag_started)
	_slider_menu_scale.drag_ended.connect(_on_menu_scale_drag_ended)
	# Viewport Scale re-scales the whole screen too, so it shares Menu Scale's V025-01a
	# drag policy: preview the label live, commit + apply on release only.
	_slider_viewport_scale.value_changed.connect(_on_viewport_scale_changed)
	_slider_viewport_scale.drag_started.connect(_on_viewport_scale_drag_started)
	_slider_viewport_scale.drag_ended.connect(_on_viewport_scale_drag_ended)
	_btn_edit_hud.pressed.connect(_on_edit_hud_layout)
	_btn_back.pressed.connect(_on_back)
	# V027-04b: follow OS drag-resize write-backs live while the screen is open.
	if sm_for_display != null:
		if sm_for_display.has_signal("resolution_written_back"):
			sm_for_display.connect("resolution_written_back", _on_resolution_written_back)
		if sm_for_display.has_signal("display_size_changed"):
			sm_for_display.connect("display_size_changed", _on_display_size_changed)
	_populate_keybindings()
	super._ready()


func open() -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm == null:
		return
	# Sliders + their value labels.
	_slider_master.value = sm.get("master_volume")
	_slider_music.value = sm.get("music_volume")
	_slider_sfx.value = sm.get("sfx_volume")
	_sync_game_view_rows()
	_label_master.text = "%d" % sm.get("master_volume")
	_label_music.text = "%d" % sm.get("music_volume")
	_label_sfx.text = "%d" % sm.get("sfx_volume")
	_slider_camera_buffer.value = sm.get("camera_edge_buffer")
	_label_camera_buffer.text = "%d" % sm.get("camera_edge_buffer")
	_slider_map_zoom.value = sm.get("map_zoom_index")
	_label_map_zoom.text = _zoom_label(sm.get("map_zoom_index"))
	_slider_grid_dim.value = sm.get("grid_dim")
	_label_grid_dim.text = _grid_dim_label(sm.get("grid_dim"))
	_slider_menu_scale.value = sm.get("menu_scale_index")
	_label_menu_scale.text = _menu_scale_label(sm, sm.get("menu_scale_index"))
	var csf: float = sm.get("content_scale_factor")
	_slider_viewport_scale.set_value_no_signal(csf)
	_label_viewport_scale.text = _viewport_scale_label(csf)
	# Schema-driven enum settings: select the index of the stored value (B5).
	# Resolution re-syncs through its own helper — the saved value can be a
	# non-preset "WxH" written back from an OS drag (V027-04b/Q5), which the
	# plain find() would silently render as the first preset.
	for s in _ENUM_SETTINGS:
		if String(s["key"]) == "resolution":
			_sync_resolution_dropdown(sm)
			continue
		var btn: OptionButton = _vbox.get_node(s["node"])
		var values: Array = s["values"]
		btn.selected = maxi(0, values.find(sm.get(s["key"])))
	# The HUD layout editor edits the live in-map HUD, so the button is only usable
	# when a HUD exists (i.e. Settings opened via the in-map Map Menu, not the title).
	_btn_edit_hud.disabled = get_tree().get_first_node_in_group("hud") == null
	_refresh_applied_size()
	_discard_pending_keybindings()
	show()
	_stabilize_settings_rows()
	_btn_back.grab_focus()


func _input(event: InputEvent) -> void:
	if _capturing_action == "":
		super._input(event)
		return
	get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_abort_keybind_capture()
		return
	if not _event_matches_slot(event, _capturing_slot):
		return
	if event is InputEventJoypadMotion and absf(event.axis_value) < 0.5:
		return
	if not (event is InputEventJoypadMotion) and not event.is_pressed():
		return
	var captured := event.duplicate()
	if captured is InputEventKey:
		captured.echo = false
		captured.pressed = false
	elif captured is InputEventMouseButton:
		captured.pressed = false
	elif captured is InputEventJoypadButton:
		captured.pressed = false
	elif captured is InputEventJoypadMotion:
		captured.axis_value = -1.0 if captured.axis_value < 0.0 else 1.0
	_stage_keybind_event(_capturing_action, _capturing_slot, captured)


# While capturing a new keybind the modal must not steal ui_up/ui_down: the base
# ModalScreen polls those actions directly for focus repeat, so holding a
# direction to rebind it would scroll focus off the capture row. Opting out here
# suppresses both the base _process nav and the _input consumption during capture.
# Also opt out while the HUD layout editor is open: the base polls the Input
# singleton every frame, which set_input_as_handled() in the editor cannot stop,
# so the tester saw settings focus scrolling under the open editor (V053-05).
func _modal_focus_repeat_enabled() -> bool:
	return _capturing_action == "" and not _hud_editor_open


# V023-01 covered the horizontal axis (stable row columns); rows above the Menu
# Scale slider still change height with the new font size, which shifted the
# slider vertically out from under the pointer mid-drag. Anchor the row: capture
# its on-screen y before the re-scale and restore it by scrolling.
func apply_menu_scale(factor: float) -> void:
	var row: Control = null
	if _slider_menu_scale != null:
		row = _slider_menu_scale.get_parent() as Control
	var anchor_active: bool = visible and row != null and _scroll != null
	var row_y: float = row.global_position.y if anchor_active else 0.0
	super.apply_menu_scale(factor)
	_stabilize_settings_rows()
	if not anchor_active:
		return
	# Container layout is deferred, so the shifted position is only measurable on
	# the next frame. scroll_vertical clamps itself, so when the scrollbar is at
	# an extreme a small residual shift can remain — acceptable, still on screen.
	await get_tree().process_frame
	if is_instance_valid(row) and is_instance_valid(_scroll) and visible:
		_scroll.scroll_vertical += roundi(row.global_position.y - row_y)


# B6-INPUT focus seam: on a live switch to gamepad while Settings is open, land focus
# on Back — the same entry point open() uses — rather than the first slider deep in the
# scrollable list.
func _focus_default() -> Control:
	return _btn_back


func _close() -> void:
	# Subclass override: emit back_pressed (consumed by MainMenu and MapMenu's
	# Settings button) in addition to ModalScreen.closed. Then super() emits
	# closed and hides.
	back_pressed.emit()
	super._close()


func _on_master_changed(value: float) -> void:
	_label_master.text = "%d" % int(value)
	var sm := get_node_or_null("/root/SettingsManager")
	if sm:
		sm.call("set_volume", "Master", int(value))


func _on_music_changed(value: float) -> void:
	_label_music.text = "%d" % int(value)
	var sm := get_node_or_null("/root/SettingsManager")
	if sm:
		sm.call("set_volume", "Music", int(value))


func _on_sfx_changed(value: float) -> void:
	_label_sfx.text = "%d" % int(value)
	var sm := get_node_or_null("/root/SettingsManager")
	if sm:
		sm.call("set_volume", "SFX", int(value))


# Generic handler for every row in _ENUM_SETTINGS (B5). bind() partials the
# schema row in at connect time, so item_selected delivers (index, schema_row).
# Writes the chosen value to SettingsManager and saves.
func _on_enum_setting_changed(index: int, schema_row: Dictionary) -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm == null:
		return
	var values: Array = schema_row["values"]
	if index < 0 or index >= values.size():
		# Out-of-schema index: either defensive, or the trailing display-only
		# "Custom (WxH)" resolution item (V027-04b) — already the current value.
		return
	# Risky display changes (resolution / window mode) apply immediately but defer the
	# save behind a confirm-or-revert dialog, so a setting that blanks the screen
	# auto-reverts (item 2 safety). Everything else saves straight away.
	if schema_row.get("confirm", false):
		_change_with_confirm(sm, schema_row, index)
		return
	sm.set(schema_row["key"], values[index])
	sm.call("save")
	# Optional per-row hook: re-apply the setting so it takes effect immediately
	# (e.g. window mode / resolution via DisplayServer), not only on next launch.
	if schema_row.has("apply"):
		sm.call(schema_row["apply"])


# Applies a confirm-gated display change: the new value is set + applied (so the
# player sees it) but NOT saved yet. A DisplayConfirmDialog then either persists it
# (Keep) or restores the previous value, re-applies, and resets the dropdown
# (Revert / 15s timeout). The modal dialog blocks further changes meanwhile.
func _change_with_confirm(sm: Object, schema_row: Dictionary, index: int) -> void:
	var key: String = schema_row["key"]
	var values: Array = schema_row["values"]
	var prev_value: Variant = sm.get(key)
	var prev_index: int = values.find(prev_value)
	# Apply the new value live; do NOT save until confirmed.
	sm.set(key, values[index])
	if schema_row.has("apply"):
		sm.call(schema_row["apply"])
	_refresh_applied_size()  # V025-06: reflect the clamped window size in-game

	var dlg: CanvasLayer = DisplayConfirmDialogS.new()
	add_child(dlg)
	dlg.kept.connect(
		func() -> void:
			sm.call("save")
			# Keeping a preset drops a leftover "Custom (WxH)" item (V027-04b).
			if key == "resolution":
				_sync_resolution_dropdown(sm)
	)
	dlg.reverted.connect(
		func() -> void:
			sm.set(key, prev_value)
			if schema_row.has("apply"):
				sm.call(schema_row["apply"])
			_refresh_applied_size()
			# Cfg was never saved with the new value, so the restore is in-memory only.
			# Resolution re-syncs through its helper — the previous value can be a
			# non-preset write-back, which prev_index (find == -1) can't restore.
			if key == "resolution":
				_sync_resolution_dropdown(sm)
			else:
				var btn: OptionButton = _vbox.get_node(schema_row["node"])
				btn.selected = maxi(0, prev_index)
	)
	dlg.start()


# V027-04b (Q5): rebuilds the Resolution dropdown from the preset schema and
# selects the saved value. A non-preset value (an OS drag-resize write-back)
# gets a trailing display-only "Custom (WxH)" item; re-syncing after a preset
# is chosen drops that item again. Selecting the Custom item itself is a no-op
# (its index is outside the schema's values, which the generic handler ignores).
func _sync_resolution_dropdown(sm: Object) -> void:
	for s in _ENUM_SETTINGS:
		if String(s["key"]) != "resolution":
			continue
		var btn: OptionButton = _vbox.get_node(s["node"])
		_populate_option_button(btn, s["labels"])
		var value: String = String(sm.get("resolution"))
		var idx: int = (s["values"] as Array).find(value)
		if idx >= 0:
			btn.selected = idx
		else:
			btn.add_item("Custom (%s)" % value)
			btn.selected = btn.item_count - 1
		return


# Live re-sync while the screen is open: an OS drag-resize wrote the applied
# size into the saved resolution (V027-04b) — follow it in the dropdown/readout.
func _on_resolution_written_back() -> void:
	if not visible:
		return
	var sm := get_node_or_null("/root/SettingsManager")
	if sm != null:
		_sync_resolution_dropdown(sm)
		_refresh_applied_size()


func _on_display_size_changed() -> void:
	if not visible or _display_refresh_queued:
		return
	_display_refresh_queued = true
	_refresh_display_size_deferred.call_deferred()


func _refresh_display_size_deferred() -> void:
	_display_refresh_queued = false
	if visible:
		_refresh_applied_size()


# V025-06: in windowed mode the requested resolution is clamped into the screen's
# usable rect (so a 4K request on a 4K panel yields a smaller window, with desktop
# visible around it — working as designed). Show the actually-applied size next to the
# Resolution dropdown so the clamp is self-explaining. Blank when the applied size
# equals the request.
# V027-05c (Q6): outside Windowed the dropdown is inert, so gray it out (the saved
# request stays intact underneath and re-enables on return to Windowed) and pin the
# readout to the native display size — the explainer text alone did not prevent the
# "which resolution am I actually on?" confusion.
func _refresh_applied_size() -> void:
	if _label_resolution_applied == null:
		return
	var sm := get_node_or_null("/root/SettingsManager")
	if sm == null:
		_label_resolution_applied.text = ""
		return
	var windowed: bool = String(sm.get("window_mode")) == "windowed"
	_set_resolution_row_enabled(windowed)
	if not windowed:
		var native: Vector2i = DisplayServer.screen_get_size(
			DisplayServer.window_get_current_screen()
		)
		_label_resolution_applied.text = _applied_size_text(false, false, Vector2i.ZERO, native, {})
		return
	# V028-02/Q1: render from the structured window-size status so a preset REQUEST and
	# a custom OBSERVED client size are not conflated. A custom size (OS resize
	# write-back) is already the applied client size, so it is shown as-is and never
	# re-run through the 16:9 request clamp — the source of the old
	# "Custom (3840x2071) -> applied 3563x2004" nonsense.
	var status: Dictionary = sm.call("windowed_size_status")
	_label_resolution_applied.text = _applied_size_text(
		true, _display_window_is_maximized(), _display_window_client_size(), Vector2i.ZERO, status
	)


func _applied_size_text(
	windowed: bool, maximized: bool, live_client: Vector2i, native: Vector2i, status: Dictionary
) -> String:
	if not windowed:
		return "native %dx%d" % [native.x, native.y] if native != Vector2i.ZERO else ""
	if maximized:
		return (
			"Maximized (%dx%d)" % [live_client.x, live_client.y]
			if live_client != Vector2i.ZERO
			else "Maximized"
		)
	if String(status.get("kind", "preset")) == "custom":
		var client: Vector2i = status.get("applied", Vector2i.ZERO)
		return "client %dx%d" % [client.x, client.y] if client != Vector2i.ZERO else ""
	var requested: Vector2i = status.get("requested", Vector2i.ZERO)
	var applied: Vector2i = status.get("applied", Vector2i.ZERO)
	if applied != Vector2i.ZERO and applied != requested:
		return "→ applied %dx%d" % [applied.x, applied.y]
	return ""


func _display_window_is_maximized() -> bool:
	return (
		DisplayServer.get_name() != "headless"
		and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED
	)


func _display_window_client_size() -> Vector2i:
	return (
		DisplayServer.window_get_size() if DisplayServer.get_name() != "headless" else Vector2i.ZERO
	)


# B6-INPUT gray-state selector: reads InputModeManager.available_modes() (a
# platform-availability dict keyed by mode value) and disables the dropdown items
# whose value is unsupported here. Auto/Gamepad/Mouse&Keyboard stay live on desktop;
# Touch shows disabled (visible but unselectable). InputModeManager's resolver still
# falls back at runtime if a saved value is unavailable, so a stale saved mode is safe.
func _apply_mode_availability(btn: OptionButton, schema_row: Dictionary) -> void:
	var imm := get_node_or_null("/root/InputModeManager")
	if imm == null:
		return
	var available: Dictionary = imm.call("available_modes")
	var values: Array = schema_row["values"]
	for i in values.size():
		btn.set_item_disabled(i, not bool(available.get(String(values[i]), true)))


func _set_resolution_row_enabled(enabled: bool) -> void:
	for s in _ENUM_SETTINGS:
		if String(s["key"]) == "resolution":
			var btn: OptionButton = _vbox.get_node(s["node"])
			btn.disabled = not enabled
			return


func _on_camera_buffer_changed(value: float) -> void:
	_label_camera_buffer.text = "%d" % int(value)
	var sm := get_node_or_null("/root/SettingsManager")
	if sm:
		sm.set("camera_edge_buffer", int(value))
		sm.call("save")


# The Map Zoom slider value IS the stored index into CameraController.ZOOM_LEVELS;
# the label shows the human-readable factor (e.g. "1.5x"). When a map is active,
# the live MapCursor applies the level immediately and re-frames on the cursor.
func _on_map_zoom_changed(value: float) -> void:
	var idx: int = clampi(int(value), 0, CameraControllerS.ZOOM_LEVELS.size() - 1)
	var cursor := get_tree().get_first_node_in_group("map_cursor")
	if cursor != null and cursor.has_method("apply_zoom_index"):
		idx = int(cursor.call("apply_zoom_index", idx))
		_slider_map_zoom.set_value_no_signal(idx)
	_label_map_zoom.text = _zoom_label(idx)
	var sm := get_node_or_null("/root/SettingsManager")
	if sm:
		sm.set("map_zoom_index", idx)
		sm.call("save")


# Grid-dim slider ([MRD-5]): fade the terrain layer live and persist. The setter
# clamps + applies + saves, so this just relays the value and refreshes the label.
func _on_grid_dim_changed(value: float) -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm != null and sm.has_method("set_grid_dim"):
		sm.call("set_grid_dim", value)
	_label_grid_dim.text = _grid_dim_label(value)


# Formats grid_dim (0.0-0.5) as a percentage, e.g. 0.25 -> "25%".
func _grid_dim_label(value: float) -> String:
	return "%d%%" % roundi(value * 100.0)


# Formats a zoom index as a factor label, e.g. 3 -> "1.0x". Clamps defensively so a
# stale stored index never indexes past the array.
func _zoom_label(index: int) -> String:
	var levels := CameraControllerS.ZOOM_LEVELS
	var i: int = clampi(index, 0, levels.size() - 1)
	return "%sx" % str(levels[i])


# True while the player is dragging the Menu Scale grabber. Used to suppress the
# live re-scale during a drag (V025-01a) — see the drag_started/ended connections.
var _menu_scale_dragging: bool = false


func _on_menu_scale_drag_started() -> void:
	_menu_scale_dragging = true


# Drag finished: commit + apply the final value once. (`value_changed` on HSlider is
# whether the value moved during the drag; we commit regardless so a release that
# lands back on the start value still re-applies cleanly.)
func _on_menu_scale_drag_ended(_value_changed: bool) -> void:
	_menu_scale_dragging = false
	_commit_menu_scale(_slider_menu_scale.value, true)


# Menu-scale slider: value IS the stored index into SettingsManager.MENU_SCALE_LEVELS.
# During a drag we only preview the label (apply_live=false) so the track geometry
# doesn't shift under the cursor; keyboard/step changes (no drag active) apply live.
func _on_menu_scale_changed(value: float) -> void:
	_commit_menu_scale(value, not _menu_scale_dragging)


# Updates the preview label always; only when apply_live is true does it store the
# index, re-apply the scale to every menu/modal panel, and save. During a drag it is
# false, so nothing is mutated or re-scaled until release — the label just previews
# the pending factor, leaving the slider track geometry stable under the cursor.
func _commit_menu_scale(value: float, apply_live: bool) -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm == null:
		return
	var idx: int = clampi(int(value), 0, sm.MENU_SCALE_LEVELS.size() - 1)
	_label_menu_scale.text = _menu_scale_label(sm, idx)
	if apply_live:
		sm.set("menu_scale_index", idx)
		sm.call("_apply_menu_scale")
		sm.call("save")


# Formats a menu-scale index as a factor label, e.g. 1 -> "1.0x". Defensively clamped.
func _menu_scale_label(sm: Object, index: int) -> String:
	var levels: Array = sm.MENU_SCALE_LEVELS
	var i: int = clampi(index, 0, levels.size() - 1)
	return "%sx" % str(levels[i])


# True while the player is dragging the Viewport Scale grabber. Suppresses the live
# re-scale mid-drag (same track-shift reason as Menu Scale, V025-01a).
var _viewport_scale_dragging: bool = false


func _on_viewport_scale_drag_started() -> void:
	_viewport_scale_dragging = true


# Drag finished: commit + apply the final factor once (regardless of whether the value
# moved during the drag, so a release back on the start value still re-applies cleanly).
func _on_viewport_scale_drag_ended(_value_changed: bool) -> void:
	_viewport_scale_dragging = false
	_commit_viewport_scale(_slider_viewport_scale.value, true)


# Viewport Scale slider: value IS the content_scale_factor. During a drag we only
# preview the label (apply_live=false) so re-scaling the screen doesn't shift the track
# under the cursor; keyboard/step changes (no drag active) apply live.
func _on_viewport_scale_changed(value: float) -> void:
	_commit_viewport_scale(value, not _viewport_scale_dragging)


# Updates the preview label always; only when apply_live is true does it push the factor
# through SettingsManager.set_content_scale_factor (which normalizes, applies to the
# window, re-reconciles menu scale, and saves). The slider is re-synced to the applied
# value in case the setter clamped it.
func _commit_viewport_scale(value: float, apply_live: bool) -> void:
	_label_viewport_scale.text = _viewport_scale_label(value)
	if not apply_live:
		return
	var sm := get_node_or_null("/root/SettingsManager")
	if sm == null or not sm.has_method("set_content_scale_factor"):
		return
	var applied: float = sm.call("set_content_scale_factor", value)
	_slider_viewport_scale.set_value_no_signal(applied)
	_label_viewport_scale.text = _viewport_scale_label(applied)


# Formats a content scale factor as a label, e.g. 1.5 -> "1.5x". A lower factor reveals
# more map tiles; a higher one shows fewer, larger tiles.
func _viewport_scale_label(factor: float) -> String:
	return "%sx" % str(snappedf(factor, 0.5))


# Tracks whether the HUD layout editor this screen spawned is open, so the base
# focus-repeat poll can be suppressed for its lifetime (V053-05).
var _hud_editor_open: bool = false


# Launches the in-map HUD layout editor over the live HUD (item 4). The editor sits
# on a high CanvasLayer above this screen; Settings stays open underneath (keeping its
# modal cursor suppression) and is revealed again when the editor closes.
func _on_edit_hud_layout() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null:
		return
	var editor: CanvasLayer = HudLayoutEditorS.new()
	# Pause our focus-repeat poll for the editor's whole lifetime; the editor's
	# `closed` signal re-enables it (V053-05).
	_hud_editor_open = true
	editor.closed.connect(_on_hud_editor_closed)
	get_tree().root.add_child(editor)
	editor.open(hud)


func _on_hud_editor_closed() -> void:
	_hud_editor_open = false


func _on_back() -> void:
	# Routes through _close() so the back button and cancel-key paths share
	# the same teardown (B3). _close emits back_pressed + closed and hides.
	_close()


func _populate_option_button(btn: OptionButton, labels: Array) -> void:
	# Untyped Array on purpose (B5): schema labels arrive via Dictionary lookup,
	# which yields a plain Array even when the literal was Array[String]. Each
	# item is read via String() so non-string entries would still render harmlessly.
	btn.clear()
	for lbl in labels:
		btn.add_item(String(lbl))


# Optional display order for known actions. Actions not listed here are still
# shown after these, sorted by action id, so adding a new player action to the
# InputMap does not require a SettingsScreen edit.
const _KEYBIND_ORDER_HINTS: Array[String] = [
	"cursor_up",
	"cursor_down",
	"cursor_left",
	"cursor_right",
	"confirm",
	"cancel",
	"next_unit",
	"prev_unit",
	"show_danger_zone",
	"peek_range",
	"open_menu",
	"open_settings",
	"inspect_unit",
	"more_info",
	"zoom_in",
	"zoom_out",
	"zoom_reset",
]

# Optional display labels. Missing entries fall back to a humanized action id.
const _KEYBIND_LABEL_OVERRIDES := {
	"cursor_up": "Move Up",
	"cursor_down": "Move Down",
	"cursor_left": "Move Left",
	"cursor_right": "Move Right",
	"confirm": "Confirm",
	"cancel": "Cancel / Back",
	"next_unit": "Next Unit",
	"prev_unit": "Previous Unit",
	"open_menu": "Map Menu",
	"open_settings": "Settings",
	"inspect_unit": "Unit Details",
	"more_info": "More Info",
	"show_danger_zone": "Toggle Threat Range",
	"peek_range": "Peek Range",
	"zoom_in": "Zoom In",
	"zoom_out": "Zoom Out",
	"zoom_reset": "Reset Zoom",
}

# Debug-only label overrides. Debug actions are discovered from InputMap by
# prefix and shown read-only only when OS.is_debug_build().
# Each toggles a GameState debug aid; the toggle handler itself lives on
# GameState._unhandled_input and is also gated on OS.is_debug_build().
const _DEBUG_KEYBIND_LABEL_OVERRIDES := {
	"debug_toggle_force_levelup": "Debug: Force Level Up",
	"debug_toggle_growth_boost": "Debug: Growth Boost",
	# V026-01c: the F9 hotseat override was toggleable but never listed here, so
	# the in-game controls panel didn't show it (v0.2.6 playtest §1.1 report).
	"debug_toggle_hotseat_override": "Debug: Hotseat All Factions",
}


# Builds the binding rows from the live InputMap (#8). Regular game actions are
# editable for their keyboard/mouse slot; debug-only rows stay read-only.
# Debug-only rows are appended in debug builds so they show right after the
# regular bindings — release builds never render them.
func _populate_keybindings() -> void:
	for child in _keybind_list.get_children():
		child.queue_free()
	_keybind_rows = {}
	for action in _editable_keybind_actions():
		_add_keybind_row(action, _keybind_display_label(action), true)
	if OS.is_debug_build():
		for action in _debug_keybind_actions():
			_add_keybind_row(action, _keybind_display_label(action), false)
	_add_keybind_footer()
	_refresh_keybind_rows()


func _editable_keybind_actions() -> Array[String]:
	var out: Array[String] = []
	for raw_action in InputMap.get_actions():
		var action := String(raw_action)
		if _is_editable_keybind_action(action):
			out.append(action)
	out.sort_custom(_sort_keybind_actions)
	return out


func _debug_keybind_actions() -> Array[String]:
	var out: Array[String] = []
	for raw_action in InputMap.get_actions():
		var action := String(raw_action)
		if _is_debug_keybind_action(action):
			out.append(action)
	out.sort()
	return out


func _is_editable_keybind_action(action: String) -> bool:
	return (
		InputMap.has_action(action)
		and not action.begins_with("ui_")
		and not _is_debug_keybind_action(action)
	)


func _is_debug_keybind_action(action: String) -> bool:
	return action.begins_with("debug_")


func _sort_keybind_actions(a: String, b: String) -> bool:
	var ai := _KEYBIND_ORDER_HINTS.find(a)
	var bi := _KEYBIND_ORDER_HINTS.find(b)
	if ai == -1 and bi == -1:
		return a < b
	if ai == -1:
		return false
	if bi == -1:
		return true
	return ai < bi


func _keybind_display_label(action: String) -> String:
	if _KEYBIND_LABEL_OVERRIDES.has(action):
		return String(_KEYBIND_LABEL_OVERRIDES[action])
	if _DEBUG_KEYBIND_LABEL_OVERRIDES.has(action):
		return String(_DEBUG_KEYBIND_LABEL_OVERRIDES[action])
	return action.replace("_", " ").capitalize()


# Helper: builds one row in the keybinding list. Extracted so both the regular
# and debug-only loops can reuse it. Silently skips actions not in InputMap.
func _add_keybind_row(action: String, label: String, editable: bool) -> void:
	if not InputMap.has_action(action):
		return
	var row := HBoxContainer.new()
	row.set_meta("keybind_action", action)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := Label.new()
	name_label.text = label
	name_label.custom_minimum_size = Vector2(200, 0)
	var key_label := Label.new()
	key_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_label.clip_text = true
	key_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(name_label)
	row.add_child(key_label)
	var rebind_button: Button = null
	var clear_button: Button = null
	if editable:
		rebind_button = Button.new()
		rebind_button.name = "BtnRebind_%s" % action
		rebind_button.text = "K&M"
		rebind_button.custom_minimum_size = Vector2(92, 0)
		rebind_button.pressed.connect(
			func() -> void: _begin_keybind_capture(action, _KEYBIND_SLOT_KBD)
		)
		row.add_child(rebind_button)
		var pad_button := Button.new()
		pad_button.name = "BtnPadRebind_%s" % action
		pad_button.text = "Pad"
		pad_button.custom_minimum_size = Vector2(72, 0)
		pad_button.pressed.connect(
			func() -> void: _begin_keybind_capture(action, _KEYBIND_SLOT_PAD)
		)
		row.add_child(pad_button)
		clear_button = Button.new()
		clear_button.name = "BtnClear_%s" % action
		clear_button.text = "Clear"
		clear_button.custom_minimum_size = Vector2(72, 0)
		clear_button.pressed.connect(func() -> void: _clear_pending_keybind(action))
		row.add_child(clear_button)
	_keybind_rows[action] = {
		"row": row,
		"label": key_label,
		"rebind": rebind_button,
		"pad_rebind": row.get_node_or_null("BtnPadRebind_%s" % action),
		"clear": clear_button,
		"editable": editable,
	}
	_keybind_list.add_child(row)


func _add_keybind_footer() -> void:
	var row := HBoxContainer.new()
	row.name = "KeybindActions"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	_btn_apply_keybindings = Button.new()
	_btn_apply_keybindings.name = "BtnApplyKeybindings"
	_btn_apply_keybindings.text = "Apply"
	_btn_apply_keybindings.pressed.connect(_apply_pending_keybindings)
	row.add_child(_btn_apply_keybindings)
	_btn_revert_keybindings = Button.new()
	_btn_revert_keybindings.name = "BtnRevertKeybindings"
	_btn_revert_keybindings.text = "Revert"
	_btn_revert_keybindings.pressed.connect(_discard_pending_keybindings)
	row.add_child(_btn_revert_keybindings)
	var reset_button := Button.new()
	reset_button.name = "BtnResetKeybindings"
	reset_button.text = "Reset Controls"
	reset_button.pressed.connect(_reset_keybindings_to_defaults)
	row.add_child(reset_button)
	_keybind_list.add_child(row)


func _begin_keybind_capture(action: String, slot: String) -> void:
	if not _is_editable_keybind_action(action):
		return
	if slot != _KEYBIND_SLOT_KBD and slot != _KEYBIND_SLOT_PAD:
		return
	_capturing_action = action
	_capturing_slot = slot
	_refresh_keybind_rows()


func _abort_keybind_capture() -> void:
	_capturing_action = ""
	_capturing_slot = ""
	_refresh_keybind_rows()


func _stage_keybind_event(action: String, slot: String, event: InputEvent) -> void:
	var slots: Dictionary = _pending_keybindings.get(action, {}).duplicate()
	slots[slot] = event
	_pending_keybindings[action] = slots
	_capturing_action = ""
	_capturing_slot = ""
	_refresh_keybind_rows()


func _clear_pending_keybind(action: String) -> void:
	var slot := _first_conflict_slot(action)
	if slot == "":
		slot = _KEYBIND_SLOT_KBD
	var slots: Dictionary = _pending_keybindings.get(action, {}).duplicate()
	slots[slot] = ""
	_pending_keybindings[action] = slots
	_capturing_action = ""
	_capturing_slot = ""
	_refresh_keybind_rows()


func _apply_pending_keybindings() -> void:
	if _pending_keybindings.is_empty() or not _keybind_conflicts.is_empty():
		return
	var sm := get_node_or_null("/root/SettingsManager")
	if sm != null and sm.has_method("apply_keybindings"):
		sm.call("apply_keybindings", _pending_keybindings)
	_pending_keybindings.clear()
	_capturing_action = ""
	_capturing_slot = ""
	_populate_keybindings()


func _discard_pending_keybindings() -> void:
	_pending_keybindings.clear()
	_capturing_action = ""
	_capturing_slot = ""
	_populate_keybindings()


func _reset_keybindings_to_defaults() -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm != null:
		sm.call("reset_section_to_defaults", "controls")
	_pending_keybindings.clear()
	_capturing_action = ""
	_capturing_slot = ""
	_populate_keybindings()


func _refresh_keybind_rows() -> void:
	_recompute_keybind_conflicts()
	for action in _keybind_rows:
		var info: Dictionary = _keybind_rows[action]
		var row: HBoxContainer = info["row"]
		var label: Label = info["label"]
		var rebind_button: Button = info["rebind"]
		var pad_button: Button = info["pad_rebind"]
		var clear_button: Button = info["clear"]
		var conflict: bool = _keybind_conflicts.has(action)
		label.text = _keybind_label_for_action(action)
		row.modulate = _KEYBIND_CONFLICT_COLOR if conflict else Color.WHITE
		if rebind_button != null:
			rebind_button.text = (
				"Press key..."
				if _capturing_action == action and _capturing_slot == _KEYBIND_SLOT_KBD
				else "K&M"
			)
		if pad_button != null:
			pad_button.text = (
				"Press pad..."
				if _capturing_action == action and _capturing_slot == _KEYBIND_SLOT_PAD
				else "Pad"
			)
		if clear_button != null:
			clear_button.visible = conflict
	if _btn_apply_keybindings != null:
		_btn_apply_keybindings.disabled = (
			_pending_keybindings.is_empty() or not _keybind_conflicts.is_empty()
		)
	if _btn_revert_keybindings != null:
		_btn_revert_keybindings.disabled = _pending_keybindings.is_empty()


func _recompute_keybind_conflicts() -> void:
	_keybind_conflicts = {}
	_keybind_conflict_slots = {}
	for slot in [_KEYBIND_SLOT_KBD, _KEYBIND_SLOT_PAD]:
		var seen := {}
		for action in _editable_keybind_actions():
			var event := _effective_slot_event(action, slot)
			if event == null:
				continue
			var sig := _event_signature(event)
			if sig == "":
				continue
			if not seen.has(sig):
				seen[sig] = []
			(seen[sig] as Array).append(action)
		for sig in seen:
			var actions: Array = seen[sig]
			if actions.size() < 2:
				continue
			for action in actions:
				_keybind_conflicts[action] = true
				if not _keybind_conflict_slots.has(action):
					_keybind_conflict_slots[action] = {}
				(_keybind_conflict_slots[action] as Dictionary)[slot] = true


func _keybind_label_for_action(action: String) -> String:
	var labels: Array[String] = []
	var kbd := _effective_slot_event(action, _KEYBIND_SLOT_KBD)
	labels.append(_binding_label_for_row(kbd) if kbd != null else "(unbound)")
	if (
		_pending_keybindings.has(action)
		and (_pending_keybindings[action] as Dictionary).has(_KEYBIND_SLOT_PAD)
	):
		var pad := _effective_slot_event(action, _KEYBIND_SLOT_PAD)
		if pad != null:
			labels.append(_binding_label_for_row(pad))
	elif InputMap.has_action(action):
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				var pad_label := _binding_label_for_row(event)
				if pad_label != "":
					labels.append(pad_label)
	return " / ".join(labels)


func _binding_label_for_row(event: InputEvent) -> String:
	if event is InputEventJoypadButton:
		var brand := InputDisplay.active_pad_brand_for_tree(self)
		return InputDisplay.joypad_button_label(
			(event as InputEventJoypadButton).button_index, brand
		)
	return InputDisplay.binding_to_string(event)


func _effective_slot_event(action: String, slot: String) -> InputEvent:
	if _pending_keybindings.has(action):
		var slots: Dictionary = _pending_keybindings[action]
		if slots.has(slot):
			var slot_value: Variant = slots.get(slot, null)
			if slot_value is InputEvent:
				return slot_value
			return null
	if not InputMap.has_action(action):
		return null
	for event in InputMap.action_get_events(action):
		if _event_matches_slot(event, slot):
			return event
	return null


func _event_matches_slot(event: Variant, slot: String) -> bool:
	if slot == _KEYBIND_SLOT_KBD:
		return event is InputEventKey or event is InputEventMouseButton
	if slot == _KEYBIND_SLOT_PAD:
		return event is InputEventJoypadButton or event is InputEventJoypadMotion
	return false


func _first_conflict_slot(action: String) -> String:
	if not _keybind_conflict_slots.has(action):
		return ""
	var slots: Dictionary = _keybind_conflict_slots[action]
	if slots.has(_KEYBIND_SLOT_KBD):
		return _KEYBIND_SLOT_KBD
	if slots.has(_KEYBIND_SLOT_PAD):
		return _KEYBIND_SLOT_PAD
	return ""


func _event_signature(event: InputEvent) -> String:
	if event is InputEventKey:
		var code: int = event.keycode if event.keycode != 0 else event.physical_keycode
		return (
			"key:%d:%s:%s:%s:%s"
			% [code, event.ctrl_pressed, event.shift_pressed, event.alt_pressed, event.meta_pressed]
		)
	if event is InputEventMouseButton:
		return "mouse:%d" % event.button_index
	if event is InputEventJoypadButton:
		return "pad_button:%d" % event.button_index
	if event is InputEventJoypadMotion:
		return "pad_axis:%d:%s" % [event.axis, -1 if event.axis_value < 0.0 else 1]
	return ""


# The Settings screen scales live while the player drags Menu Scale. Keep row
# geometry stable so the control column does not drift under the cursor mid-drag.
func _stabilize_settings_rows() -> void:
	if _vbox == null:
		return
	for child in _vbox.get_children():
		if not (child is HBoxContainer):
			continue
		var row := child as HBoxContainer
		row.add_theme_constant_override("separation", _SETTINGS_ROW_SEPARATION)
		if row.get_child_count() == 0 or not (row.get_child(0) is Label):
			continue
		var title := row.get_child(0) as Label
		title.custom_minimum_size.x = _SETTINGS_LABEL_COLUMN_WIDTH
		title.clip_text = true
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


# ── Game View ────────────────────────────────────────────────────────────────
# Presets are a starting point, not a mode: moving either slider switches the
# preset to Custom rather than silently disagreeing with the label above it.

const _GAME_VIEW_PRESET_VALUES: Array[String] = [
	"auto", "fullscreen", "portrait_top", "landscape_pillarbox", "custom"
]
const _GAME_VIEW_PRESET_LABELS: Array[String] = [
	"Automatic", "Fullscreen", "Portrait (top band)", "Landscape (pillarbox)", "Custom"
]


func _setup_game_view_rows() -> void:
	_populate_option_button(_opt_game_view_preset, _GAME_VIEW_PRESET_LABELS)
	_populate_option_button(_opt_game_view_aspect, ["Off", "On"])
	_opt_game_view_preset.item_selected.connect(_on_game_view_preset_changed)
	_opt_game_view_aspect.item_selected.connect(_on_game_view_aspect_changed)
	_slider_game_view_size.value_changed.connect(_on_game_view_size_changed)
	_slider_game_view_offset.value_changed.connect(_on_game_view_offset_changed)
	_btn_reset_game_view.pressed.connect(_on_game_view_reset)
	# Only the web export can act on this — it needs canvas_resize_policy=0, where
	# the shell owns the canvas rectangle. On desktop the canvas IS the window, so
	# the rows would be inert controls that look broken. Hidden, not disabled: there
	# is no platform where a desktop player could ever turn it on.
	if not OS.has_feature("web"):
		for row in [
			_vbox.get_node("HSepGameView"),
			_vbox.get_node("LabelGameView"),
			_vbox.get_node("LabelGameViewHint"),
			_vbox.get_node("HBoxGameViewPreset"),
			_vbox.get_node("HBoxGameViewSize"),
			_vbox.get_node("HBoxGameViewOffset"),
			_vbox.get_node("HBoxGameViewAspect"),
			_btn_reset_game_view,
		]:
			if row is Control:
				(row as Control).visible = false


func _sync_game_view_rows() -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm == null:
		return
	var preset := String(sm.get("game_view_preset"))
	_opt_game_view_preset.select(maxi(0, _GAME_VIEW_PRESET_VALUES.find(preset)))
	_opt_game_view_aspect.select(1 if bool(sm.get("game_view_aspect_locked")) else 0)
	_slider_game_view_size.set_value_no_signal(float(sm.get("game_view_size")))
	_slider_game_view_offset.set_value_no_signal(float(sm.get("game_view_offset")))
	_refresh_game_view_labels()


func _refresh_game_view_labels() -> void:
	_label_game_view_size.text = "%d%%" % roundi(_slider_game_view_size.value * 100.0)
	_label_game_view_offset.text = "%d%%" % roundi(_slider_game_view_offset.value * 100.0)


# One write path for every Game View control, so the clamp, the persist, and the
# live re-layout can never be applied by one route and skipped by another.
func _commit_game_view(preset: String) -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm == null:
		return
	var size: float = sm.call("normalize_game_view_size", _slider_game_view_size.value)
	var offset: float = sm.call("normalize_game_view_offset", _slider_game_view_offset.value, size)
	sm.set("game_view_preset", preset)
	sm.set("game_view_size", size)
	sm.set("game_view_offset", offset)
	sm.set("game_view_aspect_locked", _opt_game_view_aspect.selected == 1)
	sm.call("save")
	# The offset slider is clamped against the size, so a size change can move it.
	_slider_game_view_offset.set_value_no_signal(offset)
	_refresh_game_view_labels()
	var controller := get_node_or_null("/root/ControllerService")
	if controller != null and controller.has_method("refresh_game_view"):
		controller.call("refresh_game_view")


func _on_game_view_preset_changed(index: int) -> void:
	var preset: String = _GAME_VIEW_PRESET_VALUES[clampi(
		index, 0, _GAME_VIEW_PRESET_VALUES.size() - 1
	)]
	var sm := get_node_or_null("/root/SettingsManager")
	if sm != null and preset != "custom":
		var values: Dictionary = sm.get("GAME_VIEW_PRESET_VALUES").get(preset, {})
		_slider_game_view_size.set_value_no_signal(float(values.get("size", 1.0)))
		_slider_game_view_offset.set_value_no_signal(float(values.get("offset", 0.0)))
	_commit_game_view(preset)


func _on_game_view_size_changed(_value: float) -> void:
	_commit_game_view("custom")


func _on_game_view_offset_changed(_value: float) -> void:
	_commit_game_view("custom")


func _on_game_view_aspect_changed(_index: int) -> void:
	_commit_game_view(String(_GAME_VIEW_PRESET_VALUES[_opt_game_view_preset.selected]))


func _on_game_view_reset() -> void:
	_slider_game_view_size.set_value_no_signal(1.0)
	_slider_game_view_offset.set_value_no_signal(0.0)
	_opt_game_view_aspect.select(0)
	_opt_game_view_preset.select(0)
	_commit_game_view("auto")
