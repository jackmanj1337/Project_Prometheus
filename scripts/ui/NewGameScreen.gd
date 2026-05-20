extends "res://scripts/ui/ModalScreen.gd"
# New Game setup: pick the per-save gameplay rules (permadeath, leveling method),
# then start a fresh run. Implemented as an overlay child of MainMenu — open()/hide()
# like SettingsScreen, with Back returning to MainMenu (no scene reload).
# Extends ModalScreen (B3) for hide-on-ready and cancel-to-close.
#
# Gameplay rules are per-save state, so they are written onto GameState here rather
# than into the global settings.cfg. The save-system milestone will serialize them.
#
# Expected scene structure (see NewGameScreen.tscn):
#   NewGameScreen (Control, full-rect anchor, visible = false)
#     Panel
#       VBox
#         Label "New Game"
#         HBoxPermadeath
#           Label "Permadeath"
#           OptionButton (node name: OptPermadeath)  # Off / On
#         HBoxLeveling
#           Label "Leveling"
#           OptionButton (node name: OptLeveling)    # Random / Fixed
#         HSeparator
#         Button (node name: BtnStart)
#         Button (node name: BtnBack)

signal back_pressed()

@onready var _opt_permadeath: OptionButton = $Panel/VBox/HBoxPermadeath/OptPermadeath
@onready var _opt_leveling: OptionButton   = $Panel/VBox/HBoxLeveling/OptLeveling
@onready var _btn_start: Button            = $Panel/VBox/BtnStart
@onready var _btn_back: Button             = $Panel/VBox/BtnBack

# OptLeveling index → GameState.leveling_method value.
const _LEVELING_OPTIONS: Array[String] = ["growth_random", "growth_fixed"]


func _ready() -> void:
	_opt_permadeath.clear()
	_opt_permadeath.add_item("Off")
	_opt_permadeath.add_item("On")
	_opt_leveling.clear()
	_opt_leveling.add_item("Random")
	_opt_leveling.add_item("Fixed")
	_btn_start.pressed.connect(_on_start)
	_btn_back.pressed.connect(_on_back)
	# hide() is performed by ModalScreen._ready.


func open() -> void:
	# Seed the controls from GameState so reopening shows the current choices.
	var gs := get_node_or_null("/root/GameState")
	if gs:
		_opt_permadeath.selected = int(gs.get("permadeath_enabled"))  # 0=Off, 1=On
		_opt_leveling.selected   = maxi(0, _LEVELING_OPTIONS.find(gs.get("leveling_method")))
	show()
	_btn_start.grab_focus()


func _close() -> void:
	# Subclass override: emit back_pressed (consumed by MainMenu) in addition
	# to ModalScreen.closed.
	back_pressed.emit()
	super._close()


func _on_start() -> void:
	# Commit the chosen rules onto GameState, then load the roster and the first map.
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		push_error("NewGameScreen: GameState autoload missing — cannot apply rules or start the map.")
		return
	gs.set("permadeath_enabled", bool(_opt_permadeath.selected))  # 0=Off, 1=On
	gs.set("leveling_method", _LEVELING_OPTIONS[_opt_leveling.selected])
	gs.call("load_default_roster")
	get_tree().change_scene_to_file("res://scenes/core/GameMap.tscn")


func _on_back() -> void:
	# Back button and cancel key share the _close path so teardown stays in
	# one place (B3).
	_close()
