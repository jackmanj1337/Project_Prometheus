extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_diagnostics_battle_campaign.gd

var passed := 0
var failed := 0


func _init() -> void:
	print("=== Diagnostics battle/campaign test ===")
	await process_frame
	var log: Node = root.get_node_or_null("DiagnosticsLog")
	var bus: Node = root.get_node_or_null("EventBus")
	var campaign: Node = root.get_node_or_null("CampaignManager")
	if log == null or bus == null:
		_check(false, "battle diagnostics dependencies are registered")
	else:
		log.reset()
		if campaign != null:
			campaign.active_campaign_id = "fixture_campaign"
			campaign.current_node_id = "chapter_01"
		var attacker := DummyUnit.new()
		attacker.name = "Attacker"
		var defender := DummyUnit.new()
		defender.name = "Defender"
		root.add_child(attacker)
		root.add_child(defender)
		bus.combat_started.emit(attacker, defender)
		(
			bus
			. combat_resolved
			. emit(
				attacker,
				defender,
				{
					"exchanges":
					[
						{
							"attacker": attacker,
							"defender": defender,
							"hit": true,
							"crit": false,
							"damage": 7,
							"is_counter": false,
						}
					],
					"rng_event_kind": "attack",
					"rng_event_record": ["fixture", "chapter_01"],
					"rng_committed": true,
				}
			)
		)
		bus.phase_changed.emit(1, "blue")
		bus.unit_died.emit(defender)
		bus.unit_leveled_up.emit(attacker, {"str": 1}, ["skill_fixture"])
		bus.item_used.emit(attacker, "vulnerary")
		bus.objective_eval.emit("rout", "blue", true)
		bus.ai_unit_acting.emit(defender)
		bus.reward_committed.emit({"gold_earned": 25, "total_gold": 125})
		bus.map_resolved.emit("blue", [{"group": "allies", "rank": 1}])
		log.flush()
		for event in [
			"combat_started",
			"combat",
			"turn_begin",
			"unit_died",
			"level_up",
			"item_used",
			"objective_eval",
			"ai_activation",
			"gold_delta",
		]:
			_check(_has_event(log, event), "records %s" % event)
		_check(
			_has_event(log, "chapter_start", "campaign"),
			"records chapter_start with campaign identity"
		)
		_check(
			_has_event(log, "chapter_end", "campaign"), "records chapter_end with campaign identity"
		)
		_check(_combat_is_sanitized(log), "combat record keeps rolls while stripping live objects")
		_check(log.error_count() == 0, "expected battle lifecycle events stay at info severity")
		attacker.free()
		defender.free()
	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _check(ok: bool, label: String) -> void:
	if ok:
		print("OK  %s" % label)
		passed += 1
	else:
		print("FAIL %s" % label)
		failed += 1


func _has_event(log: Node, event: String, field: String = "") -> bool:
	for item: Dictionary in log.records:
		if String(item.get("event", "")) != event:
			continue
		if field.is_empty() or String(item.get("fields", "")).contains(field + "="):
			return true
	return false


func _combat_is_sanitized(log: Node) -> bool:
	for item: Dictionary in log.records:
		if String(item.get("event", "")) == "combat":
			var fields := String(item.get("fields", ""))
			return (
				fields.contains("damage")
				and fields.contains("rng_stream")
				and not fields.contains("Object")
			)
	return false


class DummyUnit:
	extends Node
	var team := "red"
	var data: Variant = null
