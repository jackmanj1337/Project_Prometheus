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

const _SETTINGS_LABEL_COLUMN_WIDTH: float = 340.0
const _SETTINGS_ROW_SEPARATION: int = 8

@onready var _scroll: ScrollContainer   = $Panel/ScrollContainer
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
@onready var _slider_menu_scale: HSlider       = _vbox.get_node("HBoxUIScale/SliderUIScale")
@onready var _label_menu_scale: Label          = _vbox.get_node("HBoxUIScale/LabelUIScale")
@onready var _label_resolution_applied: Label = _vbox.get_node("HBoxResolution/LabelResolutionApplied")
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
		"values": ["follow", "click", "disabled"],
		"labels": ["Follow", "Click", "Off"],
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
		"values": ["1280x720", "1600x900", "1920x1080", "2560x1440", "3840x2160"],
		"labels": ["1280 x 720", "1600 x 900", "1920 x 1080", "2560 x 1440 (1440p)",
			"3840 x 2160 (4K)"],
		"apply": "_apply_display", "confirm": true,
	},
]


func _ready() -> void:
	# E1: window mode + resolution are confirm-gated DisplayServer controls that Web
	# can't honour. Hide those rows where display config isn't supported so the web
	# build never shows a dropdown + 15s confirm dialog that can't apply. Desktop keeps
	# every row. Defaults true if SettingsManager is somehow absent (desktop assumption).
	var sm_for_display := get_node_or_null("/root/SettingsManager")
	var display_supported: bool = sm_for_display == null \
		or sm_for_display.call("is_display_config_supported")

	# Schema-driven enum settings (B5).
	for s in _ENUM_SETTINGS:
		var btn: OptionButton = _vbox.get_node(s["node"])
		_populate_option_button(btn, s["labels"])
		# bind() partials the schema row into the handler so we have one
		# generic _on_enum_setting_changed instead of seven hand-rolled ones.
		btn.item_selected.connect(_on_enum_setting_changed.bind(s))
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
	# Menu-scale slider sized from SettingsManager.MENU_SCALE_LEVELS; value IS the index.
	var sm_for_range := get_node_or_null("/root/SettingsManager")
	if sm_for_range != null:
		_slider_menu_scale.min_value = 0
		_slider_menu_scale.max_value = sm_for_range.MENU_SCALE_LEVELS.size() - 1
		_slider_menu_scale.step      = 1

	_slider_master.value_changed.connect(_on_master_changed)
	_slider_music.value_changed.connect(_on_music_changed)
	_slider_sfx.value_changed.connect(_on_sfx_changed)
	_slider_camera_buffer.value_changed.connect(_on_camera_buffer_changed)
	_slider_map_zoom.value_changed.connect(_on_map_zoom_changed)
	_slider_menu_scale.value_changed.connect(_on_menu_scale_changed)
	# Menu Scale applies on drag RELEASE, not live per-step (V025-01a): re-scaling the
	# screen mid-drag moves the slider track under the cursor, so the value oscillates
	# between adjacent steps. During a drag we only preview the factor in the label.
	_slider_menu_scale.drag_started.connect(_on_menu_scale_drag_started)
	_slider_menu_scale.drag_ended.connect(_on_menu_scale_drag_ended)
	_btn_edit_hud.pressed.connect(_on_edit_hud_layout)
	_btn_back.pressed.connect(_on_back)
	_populate_keybindings()
	super._ready()


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
	_slider_menu_scale.value = sm.get("menu_scale_index")
	_label_menu_scale.text   = _menu_scale_label(sm, sm.get("menu_scale_index"))
	# Schema-driven enum settings: select the index of the stored value (B5).
	for s in _ENUM_SETTINGS:
		var btn: OptionButton = _vbox.get_node(s["node"])
		var values: Array = s["values"]
		btn.selected = maxi(0, values.find(sm.get(s["key"])))
	# The HUD layout editor edits the live in-map HUD, so the button is only usable
	# when a HUD exists (i.e. Settings opened via the in-map Map Menu, not the title).
	_btn_edit_hud.disabled = get_tree().get_first_node_in_group("hud") == null
	_refresh_applied_size()
	show()
	_stabilize_settings_rows()
	_btn_back.grab_focus()


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
	_refresh_applied_size()  # V025-06: reflect the clamped window size in-game

	var dlg: CanvasLayer = DisplayConfirmDialogS.new()
	add_child(dlg)
	dlg.kept.connect(func() -> void:
		sm.call("save"))
	dlg.reverted.connect(func() -> void:
		sm.set(key, prev_value)
		if schema_row.has("apply"):
			sm.call(schema_row["apply"])
		_refresh_applied_size()
		# Cfg was never saved with the new value, so the restore is in-memory only.
		var btn: OptionButton = _vbox.get_node(schema_row["node"])
		btn.selected = maxi(0, prev_index))
	dlg.start()


# V025-06: in windowed mode the requested resolution is clamped into the screen's
# usable rect (so a 4K request on a 4K panel yields a smaller window, with desktop
# visible around it — working as designed). Show the actually-applied size next to the
# Resolution dropdown so the clamp is self-explaining. Blank in fullscreen/borderless
# (native size) or when the applied size equals the request.
func _refresh_applied_size() -> void:
	if _label_resolution_applied == null:
		return
	var sm := get_node_or_null("/root/SettingsManager")
	if sm == null or String(sm.get("window_mode")) != "windowed":
		_label_resolution_applied.text = ""
		return
	var requested: Vector2i = sm.call("_parse_resolution", sm.get("resolution"))
	var applied: Vector2i = sm.call("applied_windowed_size")
	if applied != Vector2i.ZERO and applied != requested:
		_label_resolution_applied.text = "→ applied %dx%d" % [applied.x, applied.y]
	else:
		_label_resolution_applied.text = ""


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
