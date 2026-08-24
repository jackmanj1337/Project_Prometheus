extends Control
# B4-PREP-DEPLOYMENT: pure between-map deployment authoring and manual save.

const DeploymentPlanS = preload("res://scripts/shared/DeploymentPlan.gd")
const FocusNavigatorS = preload("res://scripts/shared/FocusNavigator.gd")

@onready var _title: Label = $Margin/VBox/Title
@onready var _summary: Label = $Margin/VBox/Summary
@onready var _rules_summary: Label = $Margin/VBox/RulesSummary
@onready var _rows: VBoxContainer = $Margin/VBox/Scroll/Rows
@onready var _validation: Label = $Margin/VBox/Validation
@onready var _begin_button: Button = $Margin/VBox/Actions/BeginButton
@onready var _return_button: Button = $Margin/VBox/Actions/ReturnButton
@onready var _save_status: Label = $Margin/VBox/SaveStatus
@onready var _overwrite_confirm: ConfirmationDialog = $OverwriteConfirm

var _node: CampaignNode = null
var _map_data: BattleMapDef = null
var _eligible: Array[UnitData] = []
var _selected_ids: Array[String] = []
var _pending_overwrite_slot_id := ""
var _focus_nav: RefCounted


func _ready() -> void:
	_focus_nav = FocusNavigatorS.new(self, $Margin/VBox/Scroll)
	_begin_button.pressed.connect(_on_begin)
	_return_button.pressed.connect(_on_return_to_campaign_map)
	$Margin/VBox/SaveBox/SaveButton.pressed.connect(_on_save)
	_overwrite_confirm.confirmed.connect(_on_overwrite_confirmed)
	if not _load_launch_context():
		# availability-todo: AVAILABILITY-REASON-REMEDIATION-2026-08-21 — the launch context failed to load
		_begin_button.disabled = true
		return
	_return_button.visible = _is_revisited_hub()
	_seed_selection()
	_rebuild_rows()
	_refresh_validation()
	call_deferred("_grab_initial_focus")


func _grab_initial_focus() -> void:
	_focus_nav.grab_default()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _is_revisited_hub():
		_on_return_to_campaign_map()
		get_viewport().set_input_as_handled()
		return
	if _focus_nav != null and _focus_nav.consume_direction(event):
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _focus_nav != null:
		_focus_nav.poll(delta)


func _load_launch_context() -> bool:
	var cm := get_node_or_null("/root/CampaignManager")
	var gs := get_node_or_null("/root/GameState")
	if cm == null or gs == null or not bool(cm.call("is_campaign_active")):
		_validation.text = "No campaign battle is ready."
		return false
	_node = (
		cm.call("get_hub_node") if cm.has_method("get_hub_node") else cm.call("get_current_node")
	)
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
	if bool(cm.call("is_revisiting_current_hub")) and not _node.repeatable_battle:
		_summary.text = "Cleared hub revisited. This battle is not repeatable."
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
	var focus_key := _focused_row_key()
	for child in _rows.get_children():
		child.queue_free()
		_rows.remove_child(child)
	for unit in _eligible:
		var row := HBoxContainer.new()
		row.name = "Unit_%s" % unit.unit_id
		var toggle := CheckButton.new()
		toggle.text = unit.unit_name if unit.unit_name != "" else unit.unit_id
		toggle.button_pressed = unit.unit_id in _selected_ids
		# availability-todo: AVAILABILITY-REASON-REMEDIATION-2026-08-21 — this unit is required by the node
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
		# availability-allow: list-position arrow at the end of its travel, not a gate
		up.disabled = position <= 0
		up.pressed.connect(_move_unit.bind(unit.unit_id, -1))
		row.add_child(up)
		var down := Button.new()
		down.text = "Down"
		# availability-allow: list-position arrow at the end of its travel, not a gate
		down.disabled = position < 0 or position >= _selected_ids.size() - 1
		down.pressed.connect(_move_unit.bind(unit.unit_id, 1))
		row.add_child(down)
		_rows.add_child(row)
	_restore_row_focus(focus_key)


func _focused_row_key() -> Dictionary:
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null or not _rows.is_ancestor_of(focused):
		return {}
	var row := focused.get_parent()
	return {"row": row.name, "control": focused.name}


func _restore_row_focus(key: Dictionary) -> void:
	if key.is_empty():
		return
	var row := _rows.get_node_or_null(String(key["row"]))
	var control := row.get_node_or_null(String(key["control"])) if row != null else null
	if control is Control and not (control is BaseButton and control.disabled):
		(control as Control).call_deferred("grab_focus")


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
	var cm := get_node_or_null("/root/CampaignManager")
	if (
		cm != null
		and cm.has_method("is_revisiting_current_hub")
		and bool(cm.call("is_revisiting_current_hub"))
		and not _node.repeatable_battle
	):
		errors.append("This cleared node's battle is one-shot.")
	# availability-todo: AVAILABILITY-REASON-REMEDIATION-2026-08-21 — reason is in _validation.text, which focus never announces
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


func _is_revisited_hub() -> bool:
	var cm := get_node_or_null("/root/CampaignManager")
	return (
		cm != null
		and cm.has_method("is_revisiting_current_hub")
		and bool(cm.call("is_revisiting_current_hub"))
	)


func _on_return_to_campaign_map() -> void:
	var cm := get_node_or_null("/root/CampaignManager")
	if cm != null and cm.has_method("return_from_revisited_hub"):
		cm.call("return_from_revisited_hub")


func _on_save() -> void:
	var existing_id := _same_label_slot_id(_manual_save_label())
	if existing_id != "":
		_pending_overwrite_slot_id = existing_id
		_overwrite_confirm.popup_centered()
		return
	_write_manual_save("")


func _on_overwrite_confirmed() -> void:
	var old_slot_id := _pending_overwrite_slot_id
	_pending_overwrite_slot_id = ""
	_write_manual_save(old_slot_id)


func _write_manual_save(old_slot_id: String) -> void:
	var cm := get_node_or_null("/root/CampaignManager")
	if cm == null:
		return
	var label := _manual_save_label()
	# Replace reuses the existing slot id: an in-place overwrite of an existing
	# manual slot is permitted even when the class is full, so Replace is atomic
	# (no headroom needed, no orphan on failure) and never hits the cap (V053-04).
	if old_slot_id != "":
		_save_status.text = (
			"Saved." if bool(cm.call("write_campaign_slot", old_slot_id, label)) else "Save failed."
		)
		return
	# A brand-new slot needs budget. Diagnose a cap-full refusal up front so the
	# player sees the reason instead of the bare "Save failed." (V053-04).
	var sm := get_node_or_null("/root/SaveManager")
	if sm != null and sm.has_method("manual_slot_budget"):
		var budget: Dictionary = sm.call("manual_slot_budget", "between_map")
		if bool(budget.get("full", false)):
			_save_status.text = (
				"All %d campaign save slots are in use — delete one from Load Game."
				% int(budget.get("cap", 0))
			)
			return
	var id := _next_manual_slot_id()
	_save_status.text = (
		"Saved." if bool(cm.call("write_campaign_slot", id, label)) else "Save failed."
	)


func _manual_save_label() -> String:
	var chapter: String = _node.label if _node != null and _node.label != "" else _title.text
	return "%s — Prep" % chapter


func _same_label_slot_id(label: String) -> String:
	var sm := get_node_or_null("/root/SaveManager")
	if sm == null:
		return ""
	for row in sm.call("list_slots"):
		if String(row.get("label", "")) == label:
			return String(row.get("slot_id", ""))
	return ""


func _next_manual_slot_id(timestamp: int = -1) -> String:
	var chapter_id: String = _node.node_id if _node != null else "chapter"
	var base := "%s-prep-%d" % [_filename_slug(chapter_id), _timestamp_msec(timestamp)]
	var sm := get_node_or_null("/root/SaveManager")
	var candidate := base
	var suffix := 2
	while sm != null and bool(sm.call("has_slot", candidate)):
		candidate = "%s-%d" % [base, suffix]
		suffix += 1
	return candidate


func _timestamp_msec(override: int) -> int:
	return override if override >= 0 else int(Time.get_unix_time_from_system() * 1000.0)


func _filename_slug(value: String) -> String:
	var out := ""
	for character in value.to_lower():
		out += character if character in "abcdefghijklmnopqrstuvwxyz0123456789" else "-"
	while "--" in out:
		out = out.replace("--", "-")
	return out.trim_prefix("-").trim_suffix("-") if out.strip_edges() != "" else "chapter"
