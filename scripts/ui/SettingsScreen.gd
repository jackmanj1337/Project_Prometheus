extends Control
# Settings screen: audio sliders, gameplay toggles, a read-only keybinding list,
# and a back button. Reads values from SettingsManager on open(); writes back on
# every change. A full-rect opaque Dimmer makes the screen modal (#1); the inner
# content lives in a ScrollContainer so it never overflows the panel.
#
# Scene: SettingsScreen > Dimmer + Panel > ScrollContainer > VBox > rows.
# The keybinding rows under VBox/KeybindList are built at runtime (#8).

signal back_pressed()

# Shared key-display helper — renders modifiers (Shift/Ctrl/Alt) so prev_unit
# (Shift+Tab) is distinguishable from next_unit (Tab) in the list (#3).
const InputDisplay = preload("res://scripts/shared/InputDisplay.gd")

@onready var _vbox: VBoxContainer       = $Panel/ScrollContainer/VBox
@onready var _slider_master: HSlider    = _vbox.get_node("HBoxMaster/SliderMaster")
@onready var _slider_music: HSlider     = _vbox.get_node("HBoxMusic/SliderMusic")
@onready var _slider_sfx: HSlider       = _vbox.get_node("HBoxSFX/SliderSFX")
@onready var _label_master: Label       = _vbox.get_node("HBoxMaster/LabelMaster")
@onready var _label_music: Label        = _vbox.get_node("HBoxMusic/LabelMusic")
@onready var _label_sfx: Label          = _vbox.get_node("HBoxSFX/LabelSFX")
@onready var _opt_combat_anim: OptionButton    = _vbox.get_node("OptCombatAnim")
@onready var _opt_movement_speed: OptionButton = _vbox.get_node("HBoxMovementSpeed/OptMovementSpeed")
@onready var _opt_phase_banner: OptionButton   = _vbox.get_node("HBoxPhaseBanner/OptPhaseBanner")
@onready var _opt_level_up: OptionButton       = _vbox.get_node("HBoxLevelUp/OptLevelUpScreen")
@onready var _opt_mouse_targeting: OptionButton = _vbox.get_node("HBoxMouseTargeting/OptMouseTargeting")
@onready var _opt_auto_end: OptionButton       = _vbox.get_node("HBoxAutoEndTurn/OptAutoEndTurn")
@onready var _slider_camera_buffer: HSlider    = _vbox.get_node("HBoxCameraBuffer/SliderCameraBuffer")
@onready var _label_camera_buffer: Label       = _vbox.get_node("HBoxCameraBuffer/LabelCameraBuffer")
@onready var _keybind_list: VBoxContainer = _vbox.get_node("KeybindList")
@onready var _btn_back: Button          = _vbox.get_node("BtnBack")

const _COMBAT_ANIM_OPTIONS: Array[String]    = ["all", "player_only", "enemy_only", "none"]
const _MOVEMENT_SPEED_OPTIONS: Array[String] = ["normal", "fast", "instant"]
const _PHASE_BANNER_OPTIONS: Array[String]   = ["show", "skip"]
const _LEVEL_UP_OPTIONS: Array[String]       = ["show", "auto", "skip"]
const _MOUSE_TARGETING_OPTIONS: Array[String] = ["snap", "disabled"]


func _ready() -> void:
	_populate_option_button(_opt_combat_anim,    ["All", "Player Only", "Enemy Only", "None"])
	_populate_option_button(_opt_movement_speed, ["Normal", "Fast", "Instant"])
	_populate_option_button(_opt_phase_banner,   ["Show", "Skip"])
	_populate_option_button(_opt_level_up,       ["Show", "Auto", "Skip"])
	_populate_option_button(_opt_mouse_targeting, ["Snap to Target", "Keyboard Only"])
	_populate_option_button(_opt_auto_end, ["Off", "On"])
	# combat_animations has no system behind it yet — hide the inert control so
	# the menu doesn't advertise a setting that does nothing. The SettingsManager
	# field is kept for when the combat-animation system lands.
	_opt_combat_anim.visible = false

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

	_slider_master.value_changed.connect(_on_master_changed)
	_slider_music.value_changed.connect(_on_music_changed)
	_slider_sfx.value_changed.connect(_on_sfx_changed)
	_opt_combat_anim.item_selected.connect(_on_combat_anim_selected)
	_opt_movement_speed.item_selected.connect(_on_movement_speed_selected)
	_opt_phase_banner.item_selected.connect(_on_phase_banner_selected)
	_opt_level_up.item_selected.connect(_on_level_up_selected)
	_opt_mouse_targeting.item_selected.connect(_on_mouse_targeting_selected)
	_opt_auto_end.item_selected.connect(_on_auto_end_selected)
	_slider_camera_buffer.value_changed.connect(_on_camera_buffer_changed)
	_btn_back.pressed.connect(_on_back)
	_populate_keybindings()
	hide()


func open() -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm == null:
		return
	_slider_master.value = sm.get("master_volume")
	_slider_music.value  = sm.get("music_volume")
	_slider_sfx.value    = sm.get("sfx_volume")
	_label_master.text   = "%d" % sm.get("master_volume")
	_label_music.text    = "%d" % sm.get("music_volume")
	_label_sfx.text      = "%d" % sm.get("sfx_volume")
	_opt_combat_anim.selected    = maxi(0, _COMBAT_ANIM_OPTIONS.find(sm.get("combat_animations")))
	_opt_movement_speed.selected = maxi(0, _MOVEMENT_SPEED_OPTIONS.find(sm.get("movement_speed")))
	_opt_phase_banner.selected   = maxi(0, _PHASE_BANNER_OPTIONS.find(sm.get("phase_banner")))
	_opt_level_up.selected       = maxi(0, _LEVEL_UP_OPTIONS.find(sm.get("level_up_screen")))
	_opt_mouse_targeting.selected = maxi(0, _MOUSE_TARGETING_OPTIONS.find(sm.get("mouse_targeting")))
	_opt_auto_end.selected = 1 if sm.get("auto_end_turn") else 0
	_slider_camera_buffer.value = sm.get("camera_edge_buffer")
	_label_camera_buffer.text   = "%d" % sm.get("camera_edge_buffer")
	show()
	_btn_back.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("cancel"):
		_on_back()
		get_viewport().set_input_as_handled()


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


func _on_combat_anim_selected(index: int) -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm:
		sm.set("combat_animations", _COMBAT_ANIM_OPTIONS[index])
		sm.call("save")


func _on_movement_speed_selected(index: int) -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm:
		sm.set("movement_speed", _MOVEMENT_SPEED_OPTIONS[index])
		sm.call("save")


func _on_phase_banner_selected(index: int) -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm:
		sm.set("phase_banner", _PHASE_BANNER_OPTIONS[index])
		sm.call("save")


func _on_level_up_selected(index: int) -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm:
		sm.set("level_up_screen", _LEVEL_UP_OPTIONS[index])
		sm.call("save")


func _on_mouse_targeting_selected(index: int) -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm:
		sm.set("mouse_targeting", _MOUSE_TARGETING_OPTIONS[index])
		sm.call("save")


func _on_auto_end_selected(index: int) -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm:
		sm.set("auto_end_turn", index == 1)  # 0 = Off, 1 = On
		sm.call("save")


func _on_camera_buffer_changed(value: float) -> void:
	_label_camera_buffer.text = "%d" % int(value)
	var sm := get_node_or_null("/root/SettingsManager")
	if sm:
		sm.set("camera_edge_buffer", int(value))
		sm.call("save")


func _on_back() -> void:
	hide()
	back_pressed.emit()


func _populate_option_button(btn: OptionButton, labels: Array[String]) -> void:
	btn.clear()
	for lbl in labels:
		btn.add_item(lbl)


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
	"show_danger_zone": "Toggle Threat Range",
}


# Builds the read-only keybinding rows from the live InputMap (#8). Each row is a
# title label + the key(s) bound to that action. Rebinding is deferred to Phase 2.
func _populate_keybindings() -> void:
	for child in _keybind_list.get_children():
		child.queue_free()
	for action in _KEYBIND_LABELS:
		if not InputMap.has_action(action):
			continue
		# InputDisplay renders modifiers, so Shift+Tab shows as "Shift+Tab" — the
		# previous-unit binding is no longer indistinguishable from "Tab" (#3).
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = _KEYBIND_LABELS[action]
		name_label.custom_minimum_size = Vector2(200, 0)
		var key_label := Label.new()
		key_label.text = InputDisplay.keys_for_action(action)
		row.add_child(name_label)
		row.add_child(key_label)
		_keybind_list.add_child(row)
