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
#         HBoxMap
#           Label "Map"
#           OptionButton (node name: OptMap)
#         HBoxPermadeath
#           Label "Permadeath"
#           OptionButton (node name: OptPermadeath)  # Off / On
#         HBoxAutoPromote
#           Label "Auto Promote"
#           OptionButton (node name: OptAutoPromote) # Off / On
#         HBoxLeveling
#           Label "Leveling"
#           OptionButton (node name: OptLeveling)    # Random / Fixed
#         HSeparator
#         Button (node name: BtnStart)
#         Button (node name: BtnBack)

signal back_pressed()

@onready var _opt_map: OptionButton          = $Panel/VBox/HBoxMap/OptMap
@onready var _opt_permadeath: OptionButton = $Panel/VBox/HBoxPermadeath/OptPermadeath
@onready var _opt_auto_promote: OptionButton = $Panel/VBox/HBoxAutoPromote/OptAutoPromote
@onready var _opt_leveling: OptionButton   = $Panel/VBox/HBoxLeveling/OptLeveling
@onready var _opt_pair_up: OptionButton    = $Panel/VBox/HBoxPairUp/OptPairUp
@onready var _btn_start: Button            = $Panel/VBox/BtnStart
@onready var _btn_back: Button             = $Panel/VBox/BtnBack

# OptLeveling index → GameState.campaign_rules.leveling_method value.
const _LEVELING_OPTIONS: Array[String] = ["growth_random", "growth_fixed"]
const _MAP_REGISTRY_PATH := "res://data/maps/map_registry.json"
const _FALLBACK_MAP_OPTIONS: Array[Dictionary] = [
	{
		"id": "map_001",
		"label": "Map 001 - Rout",
		"map_data_path": "res://data/maps/map_001_rout/map_001_data.tres",
		"roster_policy": "default_roster",
		"roster_source": "",
	},
	{
		"id": "map_001_c3_factions",
		"label": "Map 001 - Faction Demo",
		"map_data_path": "res://data/maps/map_001_rout/map_001_c3_factions_data.tres",
		"roster_policy": "default_roster",
		"roster_source": "",
	},
]
var _map_options: Array[Dictionary] = []


func _ready() -> void:
	_map_options = _load_map_options()
	_opt_map.clear()
	for entry in _map_options:
		_opt_map.add_item(entry["label"])
	_opt_permadeath.clear()
	_opt_permadeath.add_item("Off")
	_opt_permadeath.add_item("On")
	_opt_auto_promote.clear()
	_opt_auto_promote.add_item("Off")
	_opt_auto_promote.add_item("On")
	_opt_leveling.clear()
	_opt_leveling.add_item("Random")
	_opt_leveling.add_item("Fixed")
	_opt_pair_up.clear()
	_opt_pair_up.add_item("Off")
	_opt_pair_up.add_item("On")
	_btn_start.pressed.connect(_on_start)
	_btn_back.pressed.connect(_on_back)
	# Persist the rule toggles to GameState the moment they change, so closing the
	# panel WITHOUT pressing Start still remembers them on reopen (playtest v0.1.4
	# #1.2). open() seeds the controls back from these same GameState fields. These
	# are pure per-save flags; the map + roster are only configured on Start.
	# (add_item / setting `.selected` in open() do not emit item_selected, so this
	# never fires spuriously during setup.)
	_opt_permadeath.item_selected.connect(func(_i: int): _persist_rules())
	_opt_auto_promote.item_selected.connect(func(_i: int): _persist_rules())
	_opt_leveling.item_selected.connect(func(_i: int): _persist_rules())
	_opt_pair_up.item_selected.connect(func(_i: int): _persist_rules())
	super._ready()


func open() -> void:
	# Seed the controls from GameState so reopening shows the current choices.
	var gs := get_node_or_null("/root/GameState")
	if gs:
		var rules: CampaignRules = gs.get("campaign_rules") as CampaignRules
		_opt_map.selected = _selected_map_index_for(gs.get("next_map_data_path"))
		if rules != null:
			_opt_permadeath.selected = int(rules.permadeath_enabled)  # 0=Off, 1=On
			_opt_auto_promote.selected = int(rules.auto_promote_at_max_level)  # 0=Off, 1=On
			_opt_leveling.selected = maxi(0, _LEVELING_OPTIONS.find(rules.leveling_method))
			_opt_pair_up.selected = int(rules.pair_up_enabled)  # 0=Off, 1=On
	else:
		_opt_map.selected = 0
	show()
	_btn_start.grab_focus()


func _close() -> void:
	# Subclass override: emit back_pressed (consumed by MainMenu) in addition
	# to ModalScreen.closed.
	back_pressed.emit()
	super._close()


# Writes the current rule-toggle selections onto GameState. Shared by the
# on-change handlers (so a close/reopen without Start remembers them) and by
# _on_start (which additionally configures the map + roster). Pure per-save
# flags — no map or roster side effects.
func _persist_rules() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return
	var rules: CampaignRules = gs.get("campaign_rules") as CampaignRules
	if rules == null:
		push_error("NewGameScreen: GameState.campaign_rules missing — cannot apply rules.")
		return
	rules.permadeath_enabled = bool(_opt_permadeath.selected)  # 0=Off, 1=On
	rules.auto_promote_at_max_level = bool(_opt_auto_promote.selected)  # 0=Off, 1=On
	rules.leveling_method = _LEVELING_OPTIONS[_opt_leveling.selected]
	rules.pair_up_enabled = bool(_opt_pair_up.selected)  # 0=Off, 1=On


func _on_start() -> void:
	# Commit the chosen rules onto GameState, then load the roster and the first map.
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		push_error("NewGameScreen: GameState autoload missing — cannot apply rules or start the map.")
		return
	_persist_rules()
	var map_entry: Dictionary = _map_options[_opt_map.selected]
	gs.call("configure_next_map", map_entry["map_data_path"], map_entry["roster_policy"],
		map_entry.get("roster_source", ""))
	if not _apply_roster_policy(gs, map_entry["roster_policy"], map_entry.get("roster_source", "")):
		push_error("NewGameScreen: roster setup failed for map '%s' (%s)" % [
			map_entry.get("label", map_entry["map_data_path"]),
			map_entry["roster_policy"],
		])
		return
	get_tree().change_scene_to_file("res://scenes/core/GameMap.tscn")


func _on_back() -> void:
	# Back button and cancel key share the _close path so teardown stays in
	# one place (B3).
	_close()


func _selected_map_index_for(map_path: String) -> int:
	for i in _map_options.size():
		if _map_options[i]["map_data_path"] == map_path:
			return i
	return 0


func _apply_roster_policy(gs: Node, roster_policy: String, roster_source: String = "") -> bool:
	match roster_policy:
		"default_roster":
			return bool(gs.call("load_default_roster"))
		"fixed_test_roster":
			if roster_source == "":
				push_warning("NewGameScreen: fixed_test_roster missing roster_source — using default roster")
				return false
			return bool(gs.call("load_roster_from_directory", roster_source, "fixed_test_roster"))
		"keep_current_roster":
			return bool(gs.call("is_roster_ready_for_launch"))
		_:
			push_warning("NewGameScreen: unknown roster policy '%s' — using default roster" % roster_policy)
			return false


func _load_map_options() -> Array[Dictionary]:
	if not FileAccess.file_exists(_MAP_REGISTRY_PATH):
		push_warning("NewGameScreen: map registry missing at %s — using fallback entries" % _MAP_REGISTRY_PATH)
		return _FALLBACK_MAP_OPTIONS.duplicate(true)
	var raw_text := FileAccess.get_file_as_string(_MAP_REGISTRY_PATH)
	var parsed: Variant = JSON.parse_string(raw_text)
	if not (parsed is Array):
		push_warning("NewGameScreen: map registry did not parse as an array — using fallback entries")
		return _FALLBACK_MAP_OPTIONS.duplicate(true)
	var out: Array[Dictionary] = []
	for entry in parsed:
		if not (entry is Dictionary):
			continue
		if entry.get("label", "") == "" or entry.get("map_data_path", "") == "":
			continue
		out.append(entry)
	if out.is_empty():
		push_warning("NewGameScreen: map registry had no valid entries — using fallback entries")
		return _FALLBACK_MAP_OPTIONS.duplicate(true)
	return out
