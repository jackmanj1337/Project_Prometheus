extends SceneTree
# Finding 1 regression coverage: between-map saves carry the complete mutable
# campaign/party state and reject malformed input before changing live owners.

const SaveDataScript = preload("res://scripts/save/SaveData.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Campaign Save State Test ===")
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
	cm.set_campaign_flag("recruited_guide")
	cm.set_campaign_var("villages_saved", 2)
	gs.party_gold = 450
	gs.party_items = ["vulnerary", "elixir", "vulnerary"] as Array[String]
	gs.player_roster = [_make_unit()] as Array[UnitData]
	gs.mandated_campaign_rules = ["death_mode"] as Array[String]
	var save: RefCounted = gs.capture_campaign_save("Round trip")

	cm.end_campaign()
	gs.party_gold = 1
	gs.party_items = ["elixir"] as Array[String]
	gs.player_roster.clear()
	gs.mandated_campaign_rules.clear()
	_check(
		(
			gs.configure_campaign_resume(save)
			and cm.has_campaign_flag("recruited_guide")
			and cm.get_campaign_var("villages_saved") == 2
			and gs.party_gold == 450
			and gs.party_items == ["vulnerary", "elixir", "vulnerary"]
			and gs.mandated_campaign_rules == ["death_mode"]
		),
		"campaign save restores flags, vars, gold, items, and rule mandates"
	)

	var empty_save: RefCounted = SaveDataScript.from_dict(save.to_dict())
	empty_save.party["convoy"]["entries"] = []
	empty_save.campaign["flags"] = []
	empty_save.campaign["vars"] = {}
	gs.party_items = ["vulnerary"] as Array[String]
	cm.set_campaign_flag("stale_flag")
	cm.set_campaign_var("stale_var", 99)
	_check(
		(
			gs.configure_campaign_resume(empty_save)
			and gs.party_items.is_empty()
			and cm.campaign_flags.is_empty()
			and cm.campaign_vars.is_empty()
		),
		"an explicitly empty slot clears stale party and campaign state"
	)

	var malformed: Dictionary = save.to_dict()
	malformed["campaign"]["flags"] = [""]
	malformed["party"]["convoy"]["entries"] = [
		{
			"entry_type": "item",
			"item_id": "missing_item",
			"uses_remaining": 1,
		}
	]
	gs.party_gold = 777
	gs.party_items = ["elixir"] as Array[String]
	cm.campaign_flags = ["live_flag"] as Array[String]
	_check(
		(
			not gs.configure_campaign_resume(malformed)
			and gs.party_gold == 777
			and gs.party_items == ["elixir"]
			and cm.campaign_flags == ["live_flag"]
		),
		"malformed mutable state fails without partial apply"
	)

	var malformed_patch: Dictionary = save.to_dict()
	malformed_patch["campaign"]["mutable_state"]["rule_patches"] = [{"reason": "missing id"}]
	cm.active_campaign_id = "proving_grounds"
	cm.current_node_id = "node_01_rout"
	cm.campaign_flags = ["unchanged"] as Array[String]
	gs.party_gold = 888
	_check(
		(
			not gs.configure_campaign_resume(malformed_patch)
			and cm.active_campaign_id == "proving_grounds"
			and cm.current_node_id == "node_01_rout"
			and cm.campaign_flags == ["unchanged"]
			and gs.party_gold == 888
		),
		"late mutable-patch rejection occurs before campaign state changes"
	)

	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _make_unit() -> UnitData:
	var unit := UnitData.new()
	unit.unit_id = "save_test_unit"
	unit.unit_name = "Save Test"
	unit.max_hp = 20
	unit.hp = 20
	return unit


func _check(ok: bool, label: String) -> void:
	if ok:
		print("OK  %s" % label)
		_passed += 1
	else:
		print("FAIL %s" % label)
		_failed += 1
