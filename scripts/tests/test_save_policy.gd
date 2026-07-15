extends SceneTree

const SaveDataScript = preload("res://scripts/save/SaveData.gd")
const SaveManagerScript = preload("res://scripts/autoloads/SaveManager.gd")
const SavePolicy = preload("res://scripts/save/SavePolicy.gd")
const TriggerRegistry = preload("res://scripts/save/AutosaveTriggerRegistry.gd")

const TEST_DIR := "user://test_save_policy"
var passed := 0
var failed := 0


func _init() -> void:
	print("=== Save Policy Test ===")
	_clean()
	_test_presets()
	_test_warning()
	_test_campaign_authoring()
	_test_trigger_registry()
	_test_rotation_invariant()
	_clean()
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _check(ok: bool, label: String) -> void:
	if ok:
		print("OK  %s" % label); passed += 1
	else:
		print("FAIL %s" % label); failed += 1


func _test_presets() -> void:
	var gba := SavePolicy.classic_gba()
	var single := SavePolicy.single_consumable()
	var thirty := SavePolicy.thirty_interchangeable()
	_check(SavePolicy.validate(gba, SavePolicy.default_autosave_rules(), 4).is_empty()
		and gba.size() == 2 and SavePolicy.is_consumed_on_load(gba, "mid_map")
		and not SavePolicy.is_consumed_on_load(gba, "between_map"),
		"GBA 3+1 preset is data and consumes only its suspend class")
	_check(SavePolicy.validate(single, [], 4).is_empty()
		and int(single[0]["count"]) == 1 and SavePolicy.is_consumed_on_load(single, "mid_map")
		and SavePolicy.is_consumed_on_load(single, "between_map"),
		"single-consumable preset accepts both document kinds")
	_check(SavePolicy.validate(thirty, [], -1).is_empty()
		and int(thirty[0]["count"]) == 30
		and not SavePolicy.is_consumed_on_load(thirty, "mid_map"),
		"30-interchangeable preset is pure policy data")


func _test_warning() -> void:
	_check(not SavePolicy.builder_warnings(SavePolicy.thirty_interchangeable(), 4).is_empty(),
		"durable mid_map plus finite rewind raises the builder warning")
	_check(SavePolicy.builder_warnings(SavePolicy.thirty_interchangeable(), -1).is_empty()
		and SavePolicy.builder_warnings(SavePolicy.classic_gba(), 4).is_empty(),
		"infinite rewind or consumed-on-load mid_map clears the warning")


func _test_campaign_authoring() -> void:
	var errors: Array[String] = []
	var parsed := CampaignData.parse({
		"campaign_id": "policy_campaign", "label": "Policy", "rules": {
			"save_slot_classes": SavePolicy.single_consumable(),
			"autosave_rules": [],
		},
		"nodes": [{"node_id": "start", "label": "Start", "map_id": "map"}],
	}, "policy.json", errors)
	_check(parsed != null and errors.is_empty()
		and parsed.rule_overrides.get("autosave_rules") == [],
		"campaign JSON authors save policy and can disable autosaves with an empty list")
	var bad_errors: Array[String] = []
	CampaignData.parse({
		"campaign_id": "bad_policy", "label": "Bad", "rules": {
			"save_slot_classes": [{"count": 1, "accepts": "sometimes",
				"consumed_on_load": false, "label": "Bad"}],
		},
		"nodes": [{"node_id": "start", "label": "Start", "map_id": "map"}],
	}, "bad_policy.json", bad_errors)
	_check(not bad_errors.is_empty(), "malformed authored slot policy fails campaign validation")


func _test_trigger_registry() -> void:
	var registry := TriggerRegistry.new()
	var calls: Array[String] = []
	var handler := func(trigger_id: String, _context: Dictionary) -> bool:
		calls.append(trigger_id)
		return true
	registry.register("battle_end", handler)
	registry.register("author.custom_event", handler)
	var built_in := registry.dispatch("battle_end")
	var custom := registry.dispatch("author.custom_event")
	_check(built_in == [true] and custom == [true]
		and calls == ["battle_end", "author.custom_event"],
		"built-in and custom trigger ids dispatch through the same open registry")


func _test_rotation_invariant() -> void:
	var manager := SaveManagerScript.new()
	manager.configure_save_dir_for_tests(TEST_DIR)
	var manual_id := "auto_checkpoint_01"
	manager.save_slot(manual_id, _save("Manual sentinel"))
	var manual_before := FileAccess.get_file_as_string(manager.get_slot_path(manual_id))
	var manual_pool_full := manager.save_slot("manual_02", _save("Manual two")) \
		and manager.save_slot("manual_03", _save("Manual three")) \
		and not manager.save_slot("manual_04", _save("Manual four"))
	var mid_consumable := manager.save_slot(SaveManagerScript.MID_MAP_SLOT, _mid_save()) \
		and manager.should_consume_on_load(
			SaveManagerScript.MID_MAP_SLOT, SavePolicy.classic_gba())
	var direct_refused := not manager.save_slot(manual_id, _save("Attack"), "auto", "checkpoint")
	var first := manager.save_automatic("checkpoint", 2, _save("Auto one"))
	var second := manager.save_automatic("checkpoint", 2, _save("Auto two"))
	var other := manager.save_automatic("other_rule", 1, _save("Other rule"))
	var third := manager.save_automatic("checkpoint", 2, _save("Auto three"))
	var checkpoint_rows := 0
	var other_rows := 0
	for row in manager.list_slots():
		if row.get("origin") == "auto" and row.get("rule_id") == "checkpoint":
			checkpoint_rows += 1
		if row.get("origin") == "auto" and row.get("rule_id") == "other_rule":
			other_rows += 1
	_check(manual_pool_full and mid_consumable and direct_refused \
		and first and second and third and other
		and checkpoint_rows == 2 and other_rows == 1
		and FileAccess.get_file_as_string(manager.get_slot_path(manual_id)) == manual_before,
		"manual count is enforced while autosave rotation stays separate and never targets manual/other rules")
	manager.free()


func _save(label: String) -> RefCounted:
	var save: RefCounted = SaveDataScript.new()
	save.save_label = label
	save.campaign["campaign_id"] = "demo"
	save.campaign["node_id"] = "node"
	return SaveDataScript.from_dict(save.to_dict())


func _mid_save() -> RefCounted:
	var save: RefCounted = _save("Suspend")
	save.map_runtime["map_id"] = "map"
	save.map_runtime["map_path"] = "res://data/maps/map_001_rout/map_001_data.tres"
	save.suspend["kind"] = "map"
	save.ledger.append({"reason": "round_start", "entry": {
		"map_runtime": save.map_runtime.duplicate(true),
		"suspend": save.suspend.duplicate(true),
		"party": {"gold": 0, "items": [], "roster": []},
	}})
	return SaveDataScript.from_dict(save.to_dict())


func _clean() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var dir := DirAccess.open(TEST_DIR)
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
