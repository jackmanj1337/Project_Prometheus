extends "res://scripts/ui/ModalScreen.gd"
# Settings screen: audio sliders, gameplay toggles, a read-only keybinding list,
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
# triplet per setting. Sliders and the read-only keybindings list stay hand-
# wired because their shape (signal, label-update, value range) doesn't fit
# the OptionButton template.
#
# Scene: SettingsScreen > Dimmer + Panel > ScrollContainer > VBox > rows.

signal back_pressed()

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

@onready var _vbox: VBoxContainer       = $Panel/ScrollContainer/VBox
@onready var _slider_master: HSlider    = _vbox.get_node("HBoxMaster/SliderMaster")
@onready var _slider_music: HSlider     = _vbox.get_node("HBoxMusic/SliderMusic")
@onready var _slider_sfx: HSlider       = _vbox.get_node("HBoxSFX/SliderSFX")
@onready var _label_master: Label       = _vbox.get_node("HBoxMaster/LabelMaster")
@onready var _label_music: Label        = _vbox.get_node("HBoxMusic/LabelMusic")
@onready var _label_sfx: Label          = _vbox.get_node("HBoxSFX/LabelSFX")
@onready var _slider_camera_buffer: HSlider    = _vbox.get_node("HBoxCameraBuffer/SliderCameraBuffer")
@onready var _label_camera_buffer: Label       = _vbox.get_node("HBoxCameraBuffer/LabelCameraBuffer")
@onready var _slider_map_zoom: HSlider         = _vbox.get_node("HBoxMapZoom/SliderMapZoom")
@onready var _label_map_zoom: Label            = _vbox.get_node("HBoxMapZoom/LabelMapZoom")
@onready var _slider_ui_scale: HSlider         = _vbox.get_node("HBoxUIScale/SliderUIScale")
@onready var _label_ui_scale: Label            = _vbox.get_node("HBoxUIScale/LabelUIScale")
@onready var _keybind_list: VBoxContainer = _vbox.get_node("KeybindList")
@onready var _btn_edit_hud: Button      = _vbox.get_node("BtnEditHudLayout")
@onready var _btn_back: Button          = _vbox.get_node("BtnBack")

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
		"key": "combat_animations", "node": "OptCombatAnim",
		"values": ["all", "player_only", "enemy_only", "none"],
		"labels": ["All", "Player Only", "Enemy Only", "None"],
		"hidden": true,  # no combat-animation system yet
	},
	{
		"key": "movement_speed", "node": "HBoxMovementSpeed/OptMovementSpeed",
		"values": ["normal", "fast", "instant"],
		"labels": ["Normal", "Fast", "Instant"],
	},
	{
		"key": "phase_banner", "node": "HBoxPhaseBanner/OptPhaseBanner",
		"values": ["show", "skip"],
		"labels": ["Show", "Skip"],
	},
	{
		"key": "level_up_screen", "node": "HBoxLevelUp/OptLevelUpScreen",
		"values": ["show", "auto", "skip"],
		"labels": ["Show", "Auto", "Skip"],
	},
	{
		"key": "mouse_cursor", "node": "HBoxMouseCursor/OptMouseCursor",
		"values": ["enabled", "disabled"],
		"labels": ["Enabled", "Disabled"],
	},
	{
		"key": "auto_end_turn", "node": "HBoxAutoEndTurn/OptAutoEndTurn",
		"values": [false, true],
		"labels": ["Off", "On"],
	},
	{
		# Display & Accessibility item 2. "apply" re-runs the SettingsManager method
		# so the change takes effect live (not just on next launch). "confirm" routes
		# the change through the 15s confirm-or-revert dialog (a wrong fullscreen/
		# resolution can leave the screen unusable), so the new value is applied but
		# only persisted on confirm.
		"key": "window_mode", "node": "HBoxWindowMode/OptWindowMode",
		"values": ["windowed", "borderless", "fullscreen"],
		"labels": ["Windowed", "Borderless", "Fullscreen"],
		"apply": "_apply_display", "confirm": true,
	},
	{
		"key": "resolution", "node": "HBoxResolution/OptResolution",
		"values": ["1280x720", "1600x900", "1920x1080"],
		"labels": ["1280 x 720", "1600 x 900", "1920 x 1080"],
		"apply": "_apply_display", "confirm": true,
	},
]


func _ready() -> void:
	# Schema-driven enum settings (B5).
	for s in _ENUM_SETTINGS:
		var btn: OptionButton = _vbox.get_node(s["node"])
		_populate_option_button(btn, s["labels"])
		# bind() partials the schema row into the handler so we have one
		# generic _on_enum_setting_changed instead of seven hand-rolled ones.
		btn.item_selected.connect(_on_enum_setting_changed.bind(s))
		if s.get("hidden", false):
			btn.visible = false

	# Hand-wired sliders (different shape — value range, value label, save path).
	_slider_master.min_value = 0
	_slider_master.max_value = 100
	_slider_master.step      = 1
	_slider_music.min_value  = 0
	_slider_music.max_value  = 100
	_slider_music.step       = 1
	_slider_sfx.min_value    = 0
	_slider_sfx.max_value    = 100
	_slider_sfx.step         = 1
	_slider_camera_buffer.min_value = 0
	_slider_camera_buffer.max_value = 5
	_slider_camera_buffer.step      = 1
	# Size the zoom slider from CameraController.ZOOM_LEVELS so adding a level only
	# touches that one array. The slider value IS the stored index.
	_slider_map_zoom.min_value = 0
	_slider_map_zoom.max_value = CameraControllerS.ZOOM_LEVELS.size() - 1
	_slider_map_zoom.step      = 1
	# UI-scale slider sized from SettingsManager.UI_SCALE_LEVELS; value IS the index.
	var sm_for_range := get_node_or_null("/root/SettingsManager")
	if sm_for_range != null:
		_slider_ui_scale.min_value = 0
		_slider_ui_scale.max_value = sm_for_range.UI_SCALE_LEVELS.size() - 1
		_slider_ui_scale.step      = 1

	_slider_master.value_changed.connect(_on_master_changed)
	_slider_music.value_changed.connect(_on_music_changed)
	_slider_sfx.value_changed.connect(_on_sfx_changed)
	_slider_camera_buffer.value_changed.connect(_on_camera_buffer_changed)
	_slider_map_zoom.value_changed.connect(_on_map_zoom_changed)
	_slider_ui_scale.value_changed.connect(_on_ui_scale_changed)
	_btn_edit_hud.pressed.connect(_on_edit_hud_layout)
	_btn_back.pressed.connect(_on_back)
	_populate_keybindings()
	# hide() is performed by ModalScreen._ready — don't duplicate it.


func open() -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm == null:
		return
	# Sliders + their value labels.
	_slider_master.value = sm.get("master_volume")
	_slider_music.value  = sm.get("music_volume")
	_slider_sfx.value    = sm.get("sfx_volume")
	_label_master.text   = "%d" % sm.get("master_volume")
	_label_music.text    = "%d" % sm.get("music_volume")
	_label_sfx.text      = "%d" % sm.get("sfx_volume")
	_slider_camera_buffer.value = sm.get("camera_edge_buffer")
	_label_camera_buffer.text   = "%d" % sm.get("camera_edge_buffer")
	_slider_map_zoom.value = sm.get("map_zoom_index")
	_label_map_zoom.text   = _zoom_label(sm.get("map_zoom_index"))
	_slider_ui_scale.value = sm.get("ui_scale_index")
	_label_ui_scale.text   = _ui_scale_label(sm, sm.get("ui_scale_index"))
	# Schema-driven enum settings: select the index of the stored value (B5).
	for s in _ENUM_SETTINGS:
		var btn: OptionButton = _vbox.get_node(s["node"])
		var values: Array = s["values"]
		btn.selected = maxi(0, values.find(sm.get(s["key"])))
	# The HUD layout editor edits the live in-map HUD, so the button is only usable
	# when a HUD exists (i.e. Settings opened via the in-map Map Menu, not the title).
	_btn_edit_hud.disabled = get_tree().get_first_node_in_group("hud") == null
	show()
	_btn_back.grab_focus()


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
		return  # defensive — OptionButton.item_selected should always be in range
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

	var dlg: CanvasLayer = DisplayConfirmDialogS.new()
	add_child(dlg)
	dlg.kept.connect(func() -> void:
		sm.call("save"))
	dlg.reverted.connect(func() -> void:
		sm.set(key, prev_value)
		if schema_row.has("apply"):
			sm.call(schema_row["apply"])
		# Cfg was never saved with the new value, so the restore is in-memory only.
		var btn: OptionButton = _vbox.get_node(schema_row["node"])
		btn.selected = maxi(0, prev_index))
	dlg.start()


func _on_camera_buffer_changed(value: float) -> void:
	_label_camera_buffer.text = "%d" % int(value)
	var sm := get_node_or_null("/root/SettingsManager")
	if sm:
		sm.set("camera_edge_buffer", int(value))
		sm.call("save")


# The Map Zoom slider value IS the stored index into CameraController.ZOOM_LEVELS;
# the label shows the human-readable factor (e.g. "1.5x"). The new level takes
# effect on the next map load (and immediately if a map is active and re-reads it).
func _on_map_zoom_changed(value: float) -> void:
	var idx: int = int(value)
	_label_map_zoom.text = _zoom_label(idx)
	var sm := get_node_or_null("/root/SettingsManager")
	if sm:
		sm.set("map_zoom_index", idx)
		sm.call("save")


# Formats a zoom index as a factor label, e.g. 3 -> "1.0x". Clamps defensively so a
# stale stored index never indexes past the array.
func _zoom_label(index: int) -> String:
	var levels := CameraControllerS.ZOOM_LEVELS
	var i: int = clampi(index, 0, levels.size() - 1)
	return "%sx" % str(levels[i])


# UI-scale slider: value IS the stored index into SettingsManager.UI_SCALE_LEVELS.
# Applies live via SettingsManager._apply_ui_scale (Window.content_scale_factor).
func _on_ui_scale_changed(value: float) -> void:
	var idx: int = int(value)
	var sm := get_node_or_null("/root/SettingsManager")
	if sm == null:
		return
	_label_ui_scale.text = _ui_scale_label(sm, idx)
	sm.set("ui_scale_index", idx)
	sm.call("_apply_ui_scale")
	sm.call("save")


# Formats a UI-scale index as a factor label, e.g. 1 -> "1.0x". Defensively clamped.
func _ui_scale_label(sm: Object, index: int) -> String:
	var levels: Array = sm.UI_SCALE_LEVELS
	var i: int = clampi(index, 0, levels.size() - 1)
	return "%sx" % str(levels[i])


# Launches the in-map HUD layout editor over the live HUD (item 4). The editor sits
# on a high CanvasLayer above this screen; Settings stays open underneath (keeping its
# modal cursor suppression) and is revealed again when the editor closes.
func _on_edit_hud_layout() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null:
		return
	var editor: CanvasLayer = HudLayoutEditorS.new()
	get_tree().root.add_child(editor)
	editor.open(hud)


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


# Game actions shown in the read-only keybinding list, in display order (#8).
const _KEYBIND_LABELS := {
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
	"show_danger_zone": "Toggle Threat Range",
}

# Debug-only keybindings shown in the list only when OS.is_debug_build().
# Each toggles a GameState debug aid; the toggle handler itself lives on
# GameState._unhandled_input and is also gated on OS.is_debug_build().
const _DEBUG_KEYBIND_LABELS := {
	"debug_toggle_force_levelup": "Debug: Force Level Up",
	"debug_toggle_growth_boost":  "Debug: Growth Boost",
}


# Builds the read-only keybinding rows from the live InputMap (#8). Each row is a
# title label + the key(s) bound to that action. Rebinding is deferred to Phase 2.
# Debug-only rows are appended in debug builds so they show right after the
# regular bindings — release builds never render them.
func _populate_keybindings() -> void:
	for child in _keybind_list.get_children():
		child.queue_free()
	for action in _KEYBIND_LABELS:
		_add_keybind_row(action, _KEYBIND_LABELS[action])
	if OS.is_debug_build():
		for action in _DEBUG_KEYBIND_LABELS:
			_add_keybind_row(action, _DEBUG_KEYBIND_LABELS[action])


# Helper: builds one row in the keybinding list. Extracted so both the regular
# and debug-only loops can reuse it. Silently skips actions not in InputMap.
func _add_keybind_row(action: String, label: String) -> void:
	if not InputMap.has_action(action):
		return
	# InputDisplay renders modifiers, so Shift+Tab shows as "Shift+Tab" — the
	# previous-unit binding is no longer indistinguishable from "Tab" (#3).
	var row := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = label
	name_label.custom_minimum_size = Vector2(200, 0)
	var key_label := Label.new()
	key_label.text = InputDisplay.keys_for_action(action)
	row.add_child(name_label)
	row.add_child(key_label)
	_keybind_list.add_child(row)
