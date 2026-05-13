extends Control
# Settings screen: audio sliders, gameplay toggles, and a back button.
# Reads initial values from SettingsManager on show(); writes back on every change.
#
# Expected scene structure (create in Godot editor — see GDD_Manual_Tasks.md):
#   SettingsScreen (Control, full-rect anchor)
#     Panel
#       VBox
#         Label "Settings"
#         HBox (Master Volume)
#           Label "Master"
#           HSlider (node name: SliderMaster)
#           Label (node name: LabelMaster)
#         HBox (Music Volume)
#           Label "Music"
#           HSlider (node name: SliderMusic)
#           Label (node name: LabelMusic)
#         HBox (SFX Volume)
#           Label "SFX"
#           HSlider (node name: SliderSFX)
#           Label (node name: LabelSFX)
#         HSeparator
#         OptionButton (node name: OptCombatAnim)   # All / Player Only / Enemy Only / None
#         OptionButton (node name: OptMovementSpeed) # Normal / Fast / Instant
#         OptionButton (node name: OptPhaseBanner)   # Show / Skip
#         OptionButton (node name: OptLevelUpScreen) # Show / Auto / Skip
#         OptionButton (node name: OptPermadeath)    # Off / On
#         HSeparator
#         Button (node name: BtnBack)

signal back_pressed()

@onready var _slider_master: HSlider   = $Panel/VBox/HBoxMaster/SliderMaster
@onready var _slider_music: HSlider    = $Panel/VBox/HBoxMusic/SliderMusic
@onready var _slider_sfx: HSlider      = $Panel/VBox/HBoxSFX/SliderSFX
@onready var _label_master: Label      = $Panel/VBox/HBoxMaster/LabelMaster
@onready var _label_music: Label       = $Panel/VBox/HBoxMusic/LabelMusic
@onready var _label_sfx: Label         = $Panel/VBox/HBoxSFX/LabelSFX
@onready var _opt_combat_anim: OptionButton   = $Panel/VBox/OptCombatAnim
@onready var _opt_movement_speed: OptionButton = $Panel/VBox/OptMovementSpeed
@onready var _opt_phase_banner: OptionButton  = $Panel/VBox/OptPhaseBanner
@onready var _opt_level_up: OptionButton      = $Panel/VBox/OptLevelUpScreen
@onready var _opt_permadeath: OptionButton    = $Panel/VBox/OptPermadeath
@onready var _btn_back: Button                = $Panel/VBox/BtnBack

const _COMBAT_ANIM_OPTIONS: Array[String]    = ["all", "player_only", "enemy_only", "none"]
const _MOVEMENT_SPEED_OPTIONS: Array[String] = ["normal", "fast", "instant"]
const _PHASE_BANNER_OPTIONS: Array[String]   = ["show", "skip"]
const _LEVEL_UP_OPTIONS: Array[String]       = ["show", "auto", "skip"]
const _PERMADEATH_OPTIONS: Array[String]     = ["off", "on"]


func _ready() -> void:
	_populate_option_button(_opt_combat_anim,    ["All", "Player Only", "Enemy Only", "None"])
	_populate_option_button(_opt_movement_speed, ["Normal", "Fast", "Instant"])
	_populate_option_button(_opt_phase_banner,   ["Show", "Skip"])
	_populate_option_button(_opt_level_up,       ["Show", "Auto", "Skip"])
	_populate_option_button(_opt_permadeath,     ["Off", "On"])

	_slider_master.min_value = 0
	_slider_master.max_value = 100
	_slider_master.step      = 1
	_slider_music.min_value  = 0
	_slider_music.max_value  = 100
	_slider_music.step       = 1
	_slider_sfx.min_value    = 0
	_slider_sfx.max_value    = 100
	_slider_sfx.step         = 1

	_slider_master.value_changed.connect(_on_master_changed)
	_slider_music.value_changed.connect(_on_music_changed)
	_slider_sfx.value_changed.connect(_on_sfx_changed)
	_opt_combat_anim.item_selected.connect(_on_combat_anim_selected)
	_opt_movement_speed.item_selected.connect(_on_movement_speed_selected)
	_opt_phase_banner.item_selected.connect(_on_phase_banner_selected)
	_opt_level_up.item_selected.connect(_on_level_up_selected)
	_opt_permadeath.item_selected.connect(_on_permadeath_selected)
	_btn_back.pressed.connect(_on_back)
	hide()


func open() -> void:
	var sm := SettingsManager
	_slider_master.value = sm.master_volume
	_slider_music.value  = sm.music_volume
	_slider_sfx.value    = sm.sfx_volume
	_label_master.text   = "%d" % sm.master_volume
	_label_music.text    = "%d" % sm.music_volume
	_label_sfx.text      = "%d" % sm.sfx_volume
	_opt_combat_anim.selected    = _COMBAT_ANIM_OPTIONS.find(sm.combat_animations)
	_opt_movement_speed.selected = _MOVEMENT_SPEED_OPTIONS.find(sm.movement_speed)
	_opt_phase_banner.selected   = _PHASE_BANNER_OPTIONS.find(sm.phase_banner)
	_opt_level_up.selected       = _LEVEL_UP_OPTIONS.find(sm.level_up_screen)
	_opt_permadeath.selected     = _PERMADEATH_OPTIONS.find(sm.permadeath)
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
	SettingsManager.set_volume("Master", int(value))


func _on_music_changed(value: float) -> void:
	_label_music.text = "%d" % int(value)
	SettingsManager.set_volume("Music", int(value))


func _on_sfx_changed(value: float) -> void:
	_label_sfx.text = "%d" % int(value)
	SettingsManager.set_volume("SFX", int(value))


func _on_combat_anim_selected(index: int) -> void:
	SettingsManager.combat_animations = _COMBAT_ANIM_OPTIONS[index]
	SettingsManager.save()


func _on_movement_speed_selected(index: int) -> void:
	SettingsManager.movement_speed = _MOVEMENT_SPEED_OPTIONS[index]
	SettingsManager.save()


func _on_phase_banner_selected(index: int) -> void:
	SettingsManager.phase_banner = _PHASE_BANNER_OPTIONS[index]
	SettingsManager.save()


func _on_level_up_selected(index: int) -> void:
	SettingsManager.level_up_screen = _LEVEL_UP_OPTIONS[index]
	SettingsManager.save()


func _on_permadeath_selected(index: int) -> void:
	SettingsManager.permadeath = _PERMADEATH_OPTIONS[index]
	SettingsManager.save()


func _on_back() -> void:
	hide()
	back_pressed.emit()


func _populate_option_button(btn: OptionButton, labels: Array[String]) -> void:
	btn.clear()
	for lbl in labels:
		btn.add_item(lbl)
