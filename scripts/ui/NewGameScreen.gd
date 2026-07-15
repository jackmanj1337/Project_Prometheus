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
#         HBoxRun
#           Label "Run"
#           OptionButton (node name: OptRun)  # Single Map / Proving Grounds
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

const CampaignPackRegistryScript = preload("res://scripts/resources/CampaignPackRegistry.gd")

@onready var _opt_map: OptionButton          = $Panel/VBox/HBoxMap/OptMap
@onready var _opt_run: OptionButton          = $Panel/VBox/HBoxRun/OptRun
@onready var _opt_permadeath: OptionButton = $Panel/VBox/HBoxPermadeath/OptPermadeath
@onready var _opt_auto_promote: OptionButton = $Panel/VBox/HBoxAutoPromote/OptAutoPromote
@onready var _opt_leveling: OptionButton   = $Panel/VBox/HBoxLeveling/OptLeveling
@onready var _opt_pair_up: OptionButton    = $Panel/VBox/HBoxPairUp/OptPairUp
@onready var _btn_start: Button            = $Panel/VBox/BtnStart
@onready var _btn_manage_campaigns: Button = $Panel/VBox/BtnManageCampaigns
@onready var _btn_back: Button             = $Panel/VBox/BtnBack
@onready var _campaign_library: Control = $CampaignLibraryScreen

# OptLeveling index → GameState.campaign_rules.leveling_method value.
const _LEVELING_OPTIONS: Array[String] = ["growth_random", "growth_fixed"]
const _BUILT_IN_RUN_OPTIONS: Array[Dictionary] = [
	{"label": "Single Map (Developer)", "campaign_id": ""},
	{"label": "The Proving Grounds", "campaign_id": "proving_grounds"},
]
const _MAP_REGISTRY_PATH := "res://data/maps/map_registry.json"
# Temporary v0.3.0 rerun logging for the live-only New Game focus gap. Remove
# after the controller log proves whether focus is stolen, released, or hidden.
const V030_FOCUS_TRACE_ENABLED := true
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
var _run_options: Array[Dictionary] = []


func _ready() -> void:
	_refresh_run_options()
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
	_opt_run.item_selected.connect(_on_run_selected)
	_btn_start.pressed.connect(_on_start)
	_btn_manage_campaigns.pressed.connect(_on_manage_campaigns)
	_btn_back.pressed.connect(_on_back)
	_campaign_library.back_pressed.connect(_on_campaign_library_back)
	_campaign_library.campaigns_changed.connect(_on_campaigns_changed)
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
	_connect_v030_focus_trace()
	super._ready()


func open() -> void:
	_refresh_run_options()
	# Seed the controls from GameState so reopening shows the current choices.
	var gs := get_node_or_null("/root/GameState")
	if gs:
		var rules: CampaignRules = gs.get("campaign_rules") as CampaignRules
		_opt_map.selected = _selected_map_index_for(gs.get("next_map_data_path"))
		_opt_run.selected = 0
		if rules != null:
			_opt_permadeath.selected = int(rules.permadeath_enabled)  # 0=Off, 1=On
			_opt_auto_promote.selected = int(rules.auto_promote_at_max_level)  # 0=Off, 1=On
			_opt_leveling.selected = maxi(0, _LEVELING_OPTIONS.find(rules.leveling_method))
			_opt_pair_up.selected = int(rules.pair_up_enabled)  # 0=Off, 1=On
	else:
		_opt_map.selected = 0
		_opt_run.selected = 0
	_on_run_selected(_opt_run.selected)
	show()
	_btn_start.grab_focus()
	_v030_trace_focus("open_grabbed_start")


func _on_input_mode_changed(mode: String) -> void:
	if not visible:
		return
	_v030_trace_focus("input_mode_changed_before", {"mode": mode})
	super._on_input_mode_changed(mode)
	_v030_trace_focus.call_deferred("input_mode_changed_after", {"mode": mode})


func _input(event: InputEvent) -> void:
	if not visible or not V030_FOCUS_TRACE_ENABLED:
		super._input(event)
		return
	var actions := _v030_direction_actions_for_event(event)
	if actions.is_empty():
		super._input(event)
		return
	_v030_trace_focus("direction_input_before", {
		"actions": ",".join(actions),
		"event": _v030_event_summary(event),
	})
	_v030_trace_focus_after_input.call_deferred(",".join(actions), _v030_event_summary(event))
	super._input(event)


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
	if not _opt_permadeath.disabled:
		rules.permadeath_enabled = bool(_opt_permadeath.selected)  # 0=Off, 1=On
	if not _opt_auto_promote.disabled:
		rules.auto_promote_at_max_level = bool(_opt_auto_promote.selected)  # 0=Off, 1=On
	if not _opt_leveling.disabled:
		rules.leveling_method = _LEVELING_OPTIONS[_opt_leveling.selected]
	if not _opt_pair_up.disabled:
		rules.pair_up_enabled = bool(_opt_pair_up.selected)  # 0=Off, 1=On


func _on_start() -> void:
	# Commit the chosen rules onto GameState, then load the roster and the first map.
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		push_error("NewGameScreen: GameState autoload missing — cannot apply rules or start the map.")
		return
	var run: Dictionary = _run_options[_opt_run.selected]
	if not _activate_run_source(run):
		return
	var campaign_id: String = String(run["campaign_id"])
	if campaign_id != "":
		var cm := get_node_or_null("/root/CampaignManager")
		if cm == null:
			push_error("NewGameScreen: CampaignManager autoload missing — cannot start campaign.")
			return
		if not bool(cm.call("start_campaign", campaign_id)):
			return
		# Campaign defaults seed the controls; only editable defaults write back.
		# Mandates remain locked at the value CampaignManager just applied.
		_persist_rules()
		if not bool(cm.call("launch_current_node")):
			cm.call("end_campaign")
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


func _on_run_selected(index: int) -> void:
	# The map picker remains visible as an explicit developer path, but it is not
	# actionable while a campaign owns progression and map selection.
	_opt_map.disabled = String(_run_options[index]["campaign_id"]) != ""
	_apply_rule_authority(_run_options[index])


func _refresh_run_options() -> void:
	var previous := _run_options[_opt_run.selected].duplicate(true) \
		if not _run_options.is_empty() and _opt_run.selected >= 0 \
			and _opt_run.selected < _run_options.size() else {}
	_run_options = _BUILT_IN_RUN_OPTIONS.duplicate(true)
	var dm := get_node_or_null("/root/DataManager")
	if dm != null and dm.has_method("get_campaign") and dm.has_method("has_campaign"):
		for index in _run_options.size():
			var campaign_id := String(_run_options[index].get("campaign_id", ""))
			if campaign_id.is_empty():
				continue
			if not bool(dm.call("has_campaign", campaign_id)):
				continue
			var campaign: CampaignData = dm.call("get_campaign", campaign_id)
			if campaign != null:
				_run_options[index]["rules"] = _authored_rule_rows(
					campaign.rule_overrides, campaign.mandated_rule_ids)
	var registry := CampaignPackRegistryScript.new(
		CampaignPackRegistryScript.DEFAULT_STORAGE_ROOT)
	for summary in registry.refresh():
		for campaign in summary["campaigns"]:
			_run_options.append({
				"label": "%s — %s %s" % [campaign["label"],
					summary["package_id"], summary["package_version"]],
				"campaign_id": campaign["campaign_id"],
				"package_id": summary["package_id"],
				"package_version": summary["package_version"],
				"package_path": summary["path"],
				"rules": campaign.get("rules", {}).duplicate(true),
			})
	_opt_run.clear()
	for entry in _run_options:
		_opt_run.add_item(entry["label"])
	_opt_run.selected = 0
	if not previous.is_empty():
		for index in _run_options.size():
			if _same_run_identity(_run_options[index], previous):
				_opt_run.selected = index
				break


func _activate_run_source(run: Dictionary) -> bool:
	var dm := get_node_or_null("/root/DataManager")
	if dm == null:
		push_error("NewGameScreen: DataManager unavailable — cannot select campaign content")
		return false
	var package_id := String(run.get("package_id", ""))
	if package_id.is_empty():
		var active: Dictionary = dm.call("active_package_identity") \
			if dm.has_method("active_package_identity") else {}
		if not String(active.get("package_id", "")).is_empty():
			dm.call("select_campaign_source", "res://data")
		return true
	return bool(dm.call("select_tier2_campaign_source",
		String(run["package_path"]), package_id, String(run["package_version"])))


static func _same_run_identity(a: Dictionary, b: Dictionary) -> bool:
	return a.get("campaign_id", "") == b.get("campaign_id", "") \
		and a.get("package_id", "") == b.get("package_id", "") \
		and a.get("package_version", "") == b.get("package_version", "")


func _on_back() -> void:
	# Back button and cancel key share the _close path so teardown stays in
	# one place (B3).
	_close()


func _on_manage_campaigns() -> void:
	_campaign_library.open()


func _on_campaign_library_back() -> void:
	_btn_manage_campaigns.grab_focus()


func _on_campaigns_changed() -> void:
	_refresh_run_options()
	_on_run_selected(_opt_run.selected)


func _apply_rule_authority(run: Dictionary) -> void:
	for control in [_opt_permadeath, _opt_auto_promote, _opt_leveling, _opt_pair_up]:
		(control as OptionButton).disabled = false
	var rows: Dictionary = run.get("rules", {}) if run.get("rules", {}) is Dictionary else {}
	_apply_authored_option(rows, "death_mode", _opt_permadeath,
		func(value: Variant) -> int: return 1 if String(value) == "classic" else 0)
	_apply_authored_option(rows, "auto_promote_at_max_level", _opt_auto_promote,
		func(value: Variant) -> int: return int(bool(value)))
	_apply_authored_option(rows, "leveling_method", _opt_leveling,
		func(value: Variant) -> int: return maxi(0, _LEVELING_OPTIONS.find(String(value))))
	_apply_authored_option(rows, "pair_up_enabled", _opt_pair_up,
		func(value: Variant) -> int: return int(bool(value)))


func _apply_authored_option(rows: Dictionary, rule_id: String,
		control: OptionButton, index_for_value: Callable) -> void:
	if not rows.has(rule_id):
		return
	var authored: Variant = rows[rule_id]
	var value: Variant = authored.get("value") if authored is Dictionary \
		and authored.has("value") else authored
	control.selected = int(index_for_value.call(value))
	control.disabled = authored is Dictionary \
		and String(authored.get("authority", "default")) == "mandate"


static func _authored_rule_rows(overrides: Dictionary,
		mandated: Array[String]) -> Dictionary:
	var rows := {}
	for rule_id in overrides:
		rows[rule_id] = {"value": overrides[rule_id],
			"authority": "mandate" if String(rule_id) in mandated else "default"}
	return rows


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


func _connect_v030_focus_trace() -> void:
	if not V030_FOCUS_TRACE_ENABLED:
		return
	for control in [_opt_run, _opt_map, _opt_permadeath, _opt_auto_promote, _opt_leveling,
			_opt_pair_up, _btn_start, _btn_manage_campaigns, _btn_back]:
		var c := control as Control
		c.focus_entered.connect(_v030_trace_control_focus.bind(c, "entered"))
		c.focus_exited.connect(_v030_trace_control_focus.bind(c, "exited"))


func _v030_direction_actions_for_event(event: InputEvent) -> Array[String]:
	var out: Array[String] = []
	for action in ["ui_up", "ui_down", "cursor_up", "cursor_down"]:
		if event.is_action_pressed(action):
			out.append("%s:pressed" % action)
		elif event.is_action_released(action):
			out.append("%s:released" % action)
	return out


func _v030_trace_control_focus(control: Control, phase: String) -> void:
	_v030_trace_focus("focus_%s" % phase, {"control": _v030_control_label(control)})


func _v030_trace_focus_after_input(actions: String, event_summary: String) -> void:
	_v030_trace_focus("direction_input_after", {
		"actions": actions,
		"event": event_summary,
	})


func _v030_trace_focus(label: String, extra: Dictionary = {}) -> void:
	if not V030_FOCUS_TRACE_ENABLED or not visible or DisplayServer.get_name() == "headless":
		return
	var fields := {
		"label": label,
		"focus": _v030_control_label(get_viewport().gui_get_focus_owner()),
		"map": _opt_map.selected,
		"permadeath": _opt_permadeath.selected,
		"auto_promote": _opt_auto_promote.selected,
		"leveling": _opt_leveling.selected,
		"pair_up": _opt_pair_up.selected,
	}
	for key in extra:
		fields[key] = extra[key]
	print("V030-NG-FOCUS %s" % fields)


func _v030_control_label(control: Control) -> String:
	if control == null:
		return "<none>"
	return String(control.name)


func _v030_event_summary(event: InputEvent) -> String:
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		return "JoyMotion device=%d axis=%d value=%.3f" % [
			motion.device, motion.axis, motion.axis_value]
	if event is InputEventJoypadButton:
		var button := event as InputEventJoypadButton
		return "JoyButton device=%d button=%d pressed=%s" % [
			button.device, button.button_index, button.pressed]
	if event is InputEventKey:
		var key := event as InputEventKey
		return "Key code=%d pressed=%s echo=%s" % [
			key.physical_keycode, key.pressed, key.echo]
	return event.as_text()
