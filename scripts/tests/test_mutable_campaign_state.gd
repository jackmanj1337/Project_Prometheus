extends SceneTree
# Covers the shared Q8/Q13 mutable campaign-state store and three-layer rules.

const GameStateScript = preload("res://scripts/autoloads/GameState.gd")
const SaveDataScript = preload("res://scripts/save/SaveData.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Mutable Campaign State Test ===")
	var bus: Node = load("res://scripts/autoloads/EventBus.gd").new()
	bus.name = "EventBus"
	root.add_child(bus)
	var gs: Node = GameStateScript.new()
	root.add_child(gs)
	var notice: Control = load("res://scenes/ui/RuleFlipNotification.tscn").instantiate()
	root.add_child(notice)
	await process_frame

	gs._apply_campaign_rules_dict({"pair_up_enabled": true, "max_skills": 5})
	_check(gs.get_effective_campaign_rule("pair_up_enabled") == true,
		"campaign defaults are the resolver bottom layer")
	gs.begin_campaign_map_rules({"pair_up_enabled": false, "fixture_rule": "map"})
	_check(gs.get_effective_campaign_rule("pair_up_enabled") == false
			and gs.campaign_rules.pair_up_enabled == false
			and gs.get_effective_campaign_rule("fixture_rule") == "map",
		"per-map data shadows defaults, including an unknown fixture rule id")
	_check(gs.apply_rule_flip("pair_up_enabled", true, "event", "end_of_map")
			and gs.get_effective_campaign_rule("pair_up_enabled") == true
			and gs.mutable_campaign_state.rule_patches.is_empty(),
		"end-of-map flips beat the map layer without entering the patch log")
	_check(notice.visible and notice.get_node("Panel/Label").text.contains("Pair Up Enabled")
			and notice.get_node("Panel/Label").text.contains("event"),
		"the story-flip seam presents a player-facing rule-change notification")
	gs.end_campaign_map_rules()
	_check(gs.get_effective_campaign_rule("pair_up_enabled") == true
			and gs.campaign_rules.pair_up_enabled == true,
		"ending a map clears both temporary layers")

	_check(gs.apply_rule_flip("max_skills", 7, "relic", "permanent")
			and gs.get_effective_campaign_rule("max_skills") == 7
			and gs.campaign_rules.max_skills == 7,
		"a permanent flip appends and applies a campaign-default patch")
	gs.apply_rule_flip("max_skills", 9, "second relic", "permanent")
	_check(gs.mutable_campaign_state.rule_patches.size() == 2
			and gs.get_effective_campaign_rule("max_skills") == 9,
		"patch order is deterministic and last-write wins")

	gs._apply_campaign_rules_dict({"pair_up_enabled": true,
		"mandated_rules": ["pair_up_enabled"]})
	_check(not gs.apply_rule_flip("pair_up_enabled", false, "illegal", "permanent")
			and gs.begin_campaign_map_rules({"pair_up_enabled": false})
			and gs.get_effective_campaign_rule("pair_up_enabled") == true,
		"a mandate rejects both map and triggered overrides")

	gs.mutable_campaign_state.carry_forward_facts["new_fact_from_data"] = {"count": 3}
	gs.mutable_campaign_state.imported_record_ref = {"record_id": "record_a"}
	gs.active_mid_map_rule_overrides["max_inventory"] = 11
	var save: RefCounted = SaveDataScript.new()
	var captured: Dictionary = gs.capture_mutable_campaign_state()
	for key in captured:
		save.campaign[key] = captured[key]
	var roundtrip: RefCounted = SaveDataScript.from_dict(save.to_dict())
	var restored: Node = GameStateScript.new()
	root.add_child(restored)
	restored._apply_campaign_rules_dict({"max_skills": 5, "max_inventory": 8})
	_check(restored.restore_mutable_campaign_state(roundtrip.campaign)
			and restored.get_effective_campaign_rule("max_skills") == 9
			and restored.get_effective_campaign_rule("max_inventory") == 11
			and restored.mutable_campaign_state.carry_forward_facts
				.get("new_fact_from_data", {}).get("count", 0) == 3
			and restored.mutable_campaign_state.imported_record_ref
				.get("record_id", "") == "record_a",
		"patches, open facts, record reference, and active overrides round-trip")
	restored.end_campaign_map_rules()
	_check(restored.get_effective_campaign_rule("max_inventory") == 8,
		"a restored end-of-map override reverts to the persisted bottom layer")

	var legacy: RefCounted = SaveDataScript.from_dict({"campaign": {}})
	var migrated: Node = GameStateScript.new()
	root.add_child(migrated)
	_check(migrated.restore_mutable_campaign_state(legacy.campaign)
			and migrated.mutable_campaign_state.rule_patches.is_empty(),
		"a pre-store save migrates to an empty mutable state")

	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _check(ok: bool, label: String) -> void:
	if ok:
		print("OK  %s" % label)
		_passed += 1
	else:
		print("FAIL %s" % label)
		_failed += 1
