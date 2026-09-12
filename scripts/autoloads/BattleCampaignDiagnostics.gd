extends Node
# adopter-allow: project.godot registers this subscriber and EventBus drives it in live play.
## Correctness and completability telemetry for a live battle/campaign session.
##
## This subscriber records lifecycle facts already emitted by the game. It deliberately
## keeps result summaries bounded and strips engine objects before handing fields to the
## structured channel, so a combat result cannot serialize a transaction or a live node.

const BATTLE := &"battle"
const CAMPAIGN := &"campaign"

var _bus: Node = null
var _chapter_started := false


func _ready() -> void:
	_bus = get_node_or_null("/root/EventBus")
	if _bus == null:
		return
	_connect("combat_started", Callable(self, "_on_combat_started"))
	_connect("combat_resolved", Callable(self, "_on_combat_resolved"))
	_connect("unit_died", Callable(self, "_on_unit_died"))
	_connect("unit_leveled_up", Callable(self, "_on_level_up"))
	_connect("unit_promoted", Callable(self, "_on_unit_promoted"))
	_connect("unit_reclassed", Callable(self, "_on_unit_reclassed"))
	_connect("phase_changed", Callable(self, "_on_phase_changed"))
	_connect("ai_unit_acting", Callable(self, "_on_ai_activation"))
	_connect("item_used", Callable(self, "_on_item_used"))
	_connect("objective_eval", Callable(self, "_on_objective_eval"))
	_connect("reward_committed", Callable(self, "_on_reward_committed"))
	_connect("map_resolved", Callable(self, "_on_chapter_end"))


func _connect(signal_name: StringName, callback: Callable) -> void:
	if _bus.has_signal(signal_name) and not _bus.is_connected(signal_name, callback):
		_bus.connect(signal_name, callback)


func _on_combat_started(attacker: Node, defender: Node) -> void:
	_record(
		BATTLE,
		&"combat_started",
		{
			"attacker": _unit_identity(attacker),
			"defender": _unit_identity(defender),
			"campaign": _campaign_identity(),
		}
	)


func _on_combat_resolved(attacker: Node, defender: Node, result: Dictionary) -> void:
	_record(
		BATTLE,
		&"combat",
		{
			"attacker": _unit_identity(attacker),
			"defender": _unit_identity(defender),
			"summary": _combat_summary(result),
			"campaign": _campaign_identity(),
		},
		(
			"combat:%s:%s:%s"
			% [_unit_key(attacker), _unit_key(defender), str(result.get("rng_event_record", []))]
		)
	)


func _on_phase_changed(new_phase: int, faction_id: String) -> void:
	var campaign := _campaign_identity()
	if not _chapter_started and not String(campaign.get("campaign_id", "")).is_empty():
		_chapter_started = true
		_record(CAMPAIGN, &"chapter_start", {"campaign": campaign})
	var state := get_node_or_null("/root/GameState")
	_record(
		BATTLE,
		&"turn_begin",
		{
			"turn": int(state.get("turn_number")) if state != null else -1,
			"phase": new_phase,
			"faction": faction_id,
			"living": _living_counts(state),
			"campaign": campaign,
		}
	)


func _on_unit_died(unit: Node) -> void:
	_record(BATTLE, &"unit_died", {"unit": _unit_identity(unit), "campaign": _campaign_identity()})


func _on_level_up(unit: Node, stat_increases: Dictionary, learned_skills: Array) -> void:
	_record(
		BATTLE,
		&"level_up",
		{
			"unit": _unit_identity(unit),
			"stat_increases": stat_increases,
			"learned_skills": learned_skills,
			"campaign": _campaign_identity(),
		}
	)


func _on_unit_promoted(unit: Node, old_class_id: String, new_class_id: String) -> void:
	_record(
		BATTLE,
		&"promotion",
		{
			"unit": _unit_identity(unit),
			"old_class": old_class_id,
			"new_class": new_class_id,
		}
	)


func _on_unit_reclassed(unit: Node, old_class_id: String, new_class_id: String) -> void:
	_record(
		BATTLE,
		&"reclass",
		{
			"unit": _unit_identity(unit),
			"old_class": old_class_id,
			"new_class": new_class_id,
		}
	)


func _on_ai_activation(unit: Node) -> void:
	_record(
		BATTLE,
		&"ai_activation",
		{"unit": _unit_identity(unit), "campaign": _campaign_identity()},
		"ai:%s:%s" % [_unit_key(unit), str(_campaign_identity())]
	)


func _on_item_used(unit: Node, item_id: String) -> void:
	_record(
		BATTLE,
		&"item_used",
		{"unit": _unit_identity(unit), "item_id": item_id, "campaign": _campaign_identity()}
	)


func _on_objective_eval(objective_type: String, faction_id: String, met: bool) -> void:
	_record(
		BATTLE,
		&"objective_eval",
		{
			"objective": objective_type,
			"faction": faction_id,
			"met": met,
			"campaign": _campaign_identity(),
		}
	)


func _on_reward_committed(receipt: Dictionary) -> void:
	_record(
		BATTLE,
		&"gold_delta",
		{
			"delta": int(receipt.get("gold_earned", 0)),
			"total": int(receipt.get("total_gold", 0)),
			"source": "reward_committed",
			"campaign": _campaign_identity(),
		}
	)


func _on_chapter_end(winner_group: String, standings: Array) -> void:
	var campaign := _campaign_identity()
	if String(campaign.get("campaign_id", "")).is_empty():
		return
	_record(
		CAMPAIGN,
		&"chapter_end",
		{
			"winner_group": winner_group,
			"standings": standings,
			"turn":
			(
				int(get_node_or_null("/root/GameState").get("turn_number"))
				if get_node_or_null("/root/GameState") != null
				else -1
			),
			"campaign": campaign,
		}
	)
	_chapter_started = false


func _record(category: StringName, event: StringName, fields: Dictionary, key: String = "") -> void:
	var log := get_node_or_null("/root/DiagnosticsLog")
	if log == null or not log.has_method("record") or not log.is_category_enabled(category):
		return
	log.record(category, event, _sanitize(fields), key)


func _campaign_identity() -> Dictionary:
	var campaign := get_node_or_null("/root/CampaignManager")
	if campaign == null:
		return {"campaign_id": "", "node_id": ""}
	return {
		"campaign_id": String(campaign.get("active_campaign_id")),
		"node_id": String(campaign.get("_active_node_id")),
		"current_node_id": String(campaign.get("current_node_id")),
	}


func _living_counts(state: Node) -> Dictionary:
	if state == null or not state.has_method("get_living_units_of"):
		return {}
	var counts := {}
	for faction in ["blue", "red", "green", "yellow"]:
		var units: Array = state.call("get_living_units_of", faction)
		var hp := 0
		for unit: Node in units:
			var data: Variant = unit.get("data")
			hp += int(data.get("hp")) if data != null else 0
		counts[faction] = {"count": units.size(), "hp": hp}
	return counts


func _combat_summary(result: Dictionary) -> Dictionary:
	var exchanges: Array = []
	for exchange: Dictionary in result.get("exchanges", []):
		(
			exchanges
			. append(
				{
					"attacker": _unit_identity(exchange.get("attacker")),
					"defender": _unit_identity(exchange.get("defender")),
					"hit": bool(exchange.get("hit", false)),
					"crit": bool(exchange.get("crit", false)),
					"damage": int(exchange.get("damage", 0)),
					"is_counter": bool(exchange.get("is_counter", false)),
				}
			)
		)
	return {
		"exchanges": exchanges,
		"attacker_died": bool(result.get("attacker_died", false)),
		"defender_died": bool(result.get("defender_died", false)),
		"rng_stream": String(result.get("rng_event_kind", "")),
		"rng_record": result.get("rng_event_record", []),
		"rng_committed": bool(result.get("rng_committed", false)),
	}


func _unit_key(unit: Variant) -> String:
	return String(_unit_identity(unit).get("id", ""))


func _unit_identity(unit: Variant) -> Dictionary:
	if not unit is Node:
		return {"id": "", "name": ""}
	var node := unit as Node
	var data: Variant = node.get("data")
	if data != null:
		return {
			"id": String(data.get("unit_id")),
			"name": String(data.get("unit_name")),
			"class": String(data.get("class_id")),
		}
	return {"id": str(node.get_instance_id()), "name": String(node.name)}


func _sanitize(value: Variant, depth: int = 0) -> Variant:
	if value is Node:
		return _unit_identity(value)
	if value is Object:
		return "<object:%s>" % value.get_class()
	if (
		value == null
		or value is String
		or value is StringName
		or value is bool
		or value is int
		or value is float
	):
		return value
	if depth > 4:
		return "<depth-limit>"
	if value is Dictionary:
		var result := {}
		for key in value:
			result[String(key)] = _sanitize(value[key], depth + 1)
		return result
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(_sanitize(item, depth + 1))
		return result
	return value
