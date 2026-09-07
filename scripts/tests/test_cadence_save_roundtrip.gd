extends SceneTree
# CADENCE-SAVE-ROUNDTRIP-GAP: campaign cadence is durable save state, not a
# runtime-only selection. Exercise both save writers because a suspend save and
# a between-map campaign save share the same campaign envelope contract.

const SaveDataScript = preload("res://scripts/save/SaveData.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Cadence Save Round Trip Test ===")
	var registry_manager: Node = load("res://scripts/autoloads/RegistryManager.gd").new()
	registry_manager.name = "RegistryManager"
	root.add_child(registry_manager)
	var dm: Node = load("res://scripts/autoloads/DataManager.gd").new()
	dm.name = "DataManager"
	root.add_child(dm)
	var cm: Node = load("res://scripts/autoloads/CampaignManager.gd").new()
	cm.name = "CampaignManager"
	root.add_child(cm)
	var gs: Node = load("res://scripts/autoloads/GameState.gd").new()
	gs.name = "GameState"
	root.add_child(gs)
	await process_frame

	cm.start_campaign("proving_grounds")
	gs.player_roster = [_make_unit()] as Array[UnitData]
	cm.increment_cadence_counter("deployments_total", 4)
	cm.cadence_state["latched"]["late_activity"] = true
	cm.cadence_state["last_fired"]["shop_refresh"] = 4
	cm.cadence_state["ticks"]["shop_refresh"] = 2
	cm.cadence_state["active"]["late_activity"] = true
	var expected: Dictionary = cm.cadence_state.duplicate(true)

	var campaign_save: RefCounted = gs.capture_campaign_save("Cadence campaign save")
	var campaign_document: Dictionary = JSON.parse_string(JSON.stringify(campaign_save.to_dict()))
	var campaign_roundtrip: RefCounted = SaveDataScript.from_dict(campaign_document)
	var campaign_payload: Dictionary = campaign_roundtrip.campaign
	_check(
		_cadence_matches(campaign_payload.get("cadence", {}), expected),
		"between-map campaign save carries counters, latches, ticks, and active triggers"
	)

	cm.end_campaign()
	_check(
		(
			gs.configure_campaign_resume(campaign_roundtrip)
			and _cadence_matches(cm.cadence_state, expected)
		),
		"loading a between-map campaign save restores cadence state"
	)

	var suspend_save: RefCounted = gs.capture_suspend_save(null)
	var suspend_document: Dictionary = JSON.parse_string(JSON.stringify(suspend_save.to_dict()))
	var suspend_payload: Dictionary = SaveDataScript.from_dict(suspend_document).campaign
	_check(
		_cadence_matches(suspend_payload.get("cadence", {}), expected),
		"active-map suspend save carries the same cadence state"
	)

	var defaults: RefCounted = SaveDataScript.from_dict({})
	_check(
		defaults.campaign.get("cadence", {}).has_all(
			["counters", "latched", "last_fired", "ticks", "active"]
		),
		"new and legacy saves normalize every cadence state section"
	)

	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _make_unit() -> UnitData:
	var unit := UnitData.new()
	unit.unit_id = "cadence_save_test_unit"
	unit.unit_name = "Cadence Save Test"
	unit.max_hp = 20
	unit.hp = 20
	return unit


func _cadence_matches(actual: Variant, expected: Dictionary) -> bool:
	if not actual is Dictionary:
		return false
	for section in ["latched", "active"]:
		if actual.get(section, {}) != expected.get(section, {}):
			return false
	for section in ["counters", "last_fired", "ticks"]:
		var actual_values: Variant = actual.get(section, {})
		var expected_values: Dictionary = expected.get(section, {})
		if not actual_values is Dictionary or actual_values.size() != expected_values.size():
			return false
		for key in expected_values:
			if not actual_values.has(key) or int(actual_values[key]) != int(expected_values[key]):
				return false
	return true


func _check(ok: bool, label: String, detail: String = "") -> void:
	if ok:
		print("OK  %s" % label)
		_passed += 1
	else:
		print("FAIL %s %s" % [label, detail])
		_failed += 1
