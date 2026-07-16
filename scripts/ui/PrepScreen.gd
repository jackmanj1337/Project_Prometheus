extends Control
# B4-PREP-DEPLOYMENT: pure between-map deployment authoring and manual save.

const DeploymentPlanS = preload("res://scripts/shared/DeploymentPlan.gd")

@onready var _title: Label = $Margin/VBox/Title
@onready var _summary: Label = $Margin/VBox/Summary
@onready var _rules_summary: Label = $Margin/VBox/RulesSummary
@onready var _rows: VBoxContainer = $Margin/VBox/Scroll/Rows
@onready var _validation: Label = $Margin/VBox/Validation
@onready var _begin_button: Button = $Margin/VBox/Actions/BeginButton
@onready var _slot_id: LineEdit = $Margin/VBox/SaveBox/SlotId
@onready var _save_label: LineEdit = $Margin/VBox/SaveBox/SaveLabel
@onready var _save_status: Label = $Margin/VBox/SaveStatus

var _node: CampaignNode = null
var _map_data: BattleMapDef = null
var _eligible: Array[UnitData] = []
var _selected_ids: Array[String] = []


func _ready() -> void:
	_begin_button.pressed.connect(_on_begin)
	$Margin/VBox/SaveBox/SaveButton.pressed.connect(_on_save)
	if not _load_launch_context():
		_begin_button.disabled = true
		return
	_seed_selection()
	_rebuild_rows()
	_refresh_validation()


func _load_launch_context() -> bool:
	var cm := get_node_or_null("/root/CampaignManager")
	var gs := get_node_or_null("/root/GameState")
	if cm == null or gs == null or not bool(cm.call("is_campaign_active")):
		_validation.text = "No campaign battle is ready."
		return false
	_node = cm.call("get_current_node")
	var path := String(gs.get("next_map_data_path"))
	if _node == null or path == "":
		_validation.text = "The campaign map could not be prepared."
		return false
	var dm := get_node_or_null("/root/DataManager")
	var resolved: ResolvedBattleData = (
		dm.call("resolve_battle_source", path)
		if dm != null and dm.has_method("resolve_battle_source")
		else null
	)
	_map_data = resolved.battle_map if resolved != null else null
	if _map_data == null:
		_validation.text = "The campaign map data is invalid."
		return false
	for entry in gs.get("player_roster"):
		if (
			entry is UnitData
			and not (entry as UnitData).is_incapacitated
			and not (entry as UnitData).unit_id in _node.excluded_units
		):
			_eligible.append(entry)
	_title.text = _node.label if _node.label != "" else "Battle Prep"
	_summary.text = (
		"Choose up to %s units. Deployment order maps to the numbered start tiles."
		% (
			"%d" % _deployment_limit()
			if _node.deployment_cap != -1
			else "%d" % _map_data.player_start_tiles.size()
		)
	)
	_refresh_rules_summary(gs)
	return true


func _refresh_rules_summary(gs: Node) -> void:
	if not gs.has_method("get_campaign_rule_summary"):
		_rules_summary.text = ""
		return
	var parts: Array[String] = []
	for row in gs.call("get_campaign_rule_summary"):
		var suffix := " [locked]" if bool(row.get("mandated", false)) else ""
		parts.append(
			(
				"%s: %s%s"
				% [String(row.get("rule_id", "")).capitalize(), str(row.get("value", "")), suffix]
			)
		)
	_rules_summary.text = "Rules (read only): %s" % " · ".join(parts)


func _deployment_limit() -> int:
	var limit := _map_data.player_start_tiles.size()
	if _node.deployment_cap != -1:
		limit = mini(limit, _node.deployment_cap)
	return limit


func _seed_selection() -> void:
	var gs := get_node_or_null("/root/GameState")
	var old_plan: Dictionary = gs.get("next_map_deployment") if gs != null else {}
	var ordered: Array[Dictionary] = []
	for unit_id in old_plan:
		var tile_index := _map_data.player_start_tiles.find(old_plan[unit_id])
		if tile_index >= 0:
			ordered.append({"id": String(unit_id), "tile": tile_index})
	ordered.sort_custom(func(a: Dictionary, b: Dictionary): return a["tile"] < b["tile"])
	for entry in ordered:
		if _find_eligible(String(entry["id"])) != null:
			_selected_ids.append(String(entry["id"]))
	for required_id in _node.required_units:
		if _find_eligible(required_id) != null and not required_id in _selected_ids:
			_selected_ids.append(required_id)
	for unit in _eligible:
		if _selected_ids.size() >= _deployment_limit():
			break
		if not unit.unit_id in _selected_ids:
			_selected_ids.append(unit.unit_id)


func _find_eligible(unit_id: String) -> UnitData:
	for unit in _eligible:
		if unit.unit_id == unit_id:
			return unit
	return null


func _rebuild_rows() -> void:
	for child in _rows.get_children():
		child.queue_free()
		_rows.remove_child(child)
	for unit in _eligible:
		var row := HBoxContainer.new()
		row.name = "Unit_%s" % unit.unit_id
		var toggle := CheckButton.new()
		toggle.text = unit.unit_name if unit.unit_name != "" else unit.unit_id
		toggle.button_pressed = unit.unit_id in _selected_ids
		toggle.disabled = unit.unit_id in _node.required_units
		toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		toggle.toggled.connect(_on_unit_toggled.bind(unit.unit_id))
		row.add_child(toggle)
		var position := _selected_ids.find(unit.unit_id)
		var tile := Label.new()
		tile.custom_minimum_size.x = 145
		tile.text = (
			"Bench"
			if position < 0
			else "Start %d  %s" % [position + 1, _map_data.player_start_tiles[position]]
		)
		row.add_child(tile)
		var up := Button.new()
		up.text = "Up"
		up.disabled = position <= 0
		up.pressed.connect(_move_unit.bind(unit.unit_id, -1))
		row.add_child(up)
		var down := Button.new()
		down.text = "Down"
		down.disabled = position < 0 or position >= _selected_ids.size() - 1
		down.pressed.connect(_move_unit.bind(unit.unit_id, 1))
		row.add_child(down)
		_rows.add_child(row)


func _on_unit_toggled(enabled: bool, unit_id: String) -> void:
	if enabled and not unit_id in _selected_ids and _selected_ids.size() < _deployment_limit():
		_selected_ids.append(unit_id)
	elif not enabled and unit_id in _selected_ids and not unit_id in _node.required_units:
		_selected_ids.erase(unit_id)
	_rebuild_rows()
	_refresh_validation()


func _move_unit(unit_id: String, direction: int) -> void:
	var from := _selected_ids.find(unit_id)
	var to := from + direction
	if from < 0 or to < 0 or to >= _selected_ids.size():
		return
	var swap_id := _selected_ids[to]
	_selected_ids[to] = unit_id
	_selected_ids[from] = swap_id
	_rebuild_rows()
	_refresh_validation()


func build_plan() -> Dictionary:
	var plan := {}
	for i in _selected_ids.size():
		if i < _map_data.player_start_tiles.size():
			plan[_selected_ids[i]] = _map_data.player_start_tiles[i]
	return plan


func validation_errors() -> Array[String]:
	var gs := get_node_or_null("/root/GameState")
	var roster: Array[UnitData] = []
	if gs != null:
		for entry in gs.get("player_roster"):
			if entry is UnitData:
				roster.append(entry)
	return DeploymentPlanS.validate(build_plan(), roster, _node, _map_data.player_start_tiles)


func _refresh_validation() -> void:
	var errors := validation_errors()
	_begin_button.disabled = not errors.is_empty()
	_validation.text = "Ready to begin." if errors.is_empty() else errors[0]


func _on_begin() -> void:
	if not validation_errors().is_empty():
		return
	var gs := get_node_or_null("/root/GameState")
	var cm := get_node_or_null("/root/CampaignManager")
	if gs == null or cm == null:
		return
	gs.call("set_next_map_deployment", build_plan())
	cm.call("begin_prepared_battle")


func _on_save() -> void:
	var cm := get_node_or_null("/root/CampaignManager")
	if cm == null:
		return
	var id := _slot_id.text.strip_edges()
	var label := _save_label.text.strip_edges()
	if label == "":
		label = _title.text
	var ok := bool(cm.call("write_campaign_slot", id, label))
	_save_status.text = (
		"Saved." if ok else "Save failed. Use letters, numbers, _ or -, up to 64 characters."
	)
