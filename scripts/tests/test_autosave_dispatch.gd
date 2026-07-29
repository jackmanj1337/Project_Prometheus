extends SceneTree

const SavePolicy = preload("res://scripts/save/SavePolicy.gd")
const TEST_DIR := "user://test_autosave_dispatch"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Autosave Dispatch Test ===")
	var passed := 0
	var failed := 0
	_clean()
	var gs: Node = root.get_node("GameState")
	var cm: Node = root.get_node("CampaignManager")
	var sm: Node = root.get_node("SaveManager")
	var old_dir: String = sm.get("save_dir")
	sm.call("configure_save_dir_for_tests", TEST_DIR)
	gs.call("reset_map_state")
	gs.get("campaign_rules").save_slot_classes = SavePolicy.classic_gba()
	var authored_rules: Array[Dictionary] = [
		{
			"rule_id": "progress",
			"trigger": "battle_end",
			"keep": 2,
			"label": "Battle complete",
			"consumed_on_load": false
		},
		{
			"rule_id": "custom",
			"trigger": "author.quest_checkpoint",
			"keep": 1,
			"label": "Quest checkpoint",
			"consumed_on_load": false
		},
	]
	gs.get("campaign_rules").autosave_rules = authored_rules
	cm.call("start_campaign", "proving_grounds")
	var battle_results: Array = cm.call("dispatch_autosave_trigger", "battle_end")
	var custom_results: Array = cm.call("dispatch_autosave_trigger", "author.quest_checkpoint")
	var rows: Array[Dictionary] = sm.call("list_slots")
	var progress := 0
	var custom := 0
	for row in rows:
		if row.get("origin") == "auto" and row.get("rule_id") == "progress":
			progress += 1
		if row.get("origin") == "auto" and row.get("rule_id") == "custom":
			custom += 1
	if battle_results == [true] and custom_results == [true] and progress == 1 and custom == 1:
		print("OK  battle_end and authored custom ids write through independent rule pools")
		passed += 1
	else:
		print("FAIL dispatch results=%s/%s rows=%s" % [battle_results, custom_results, rows])
		failed += 1

	cm.call("end_campaign")
	gs.get("campaign_rules").save_slot_classes = SavePolicy.classic_gba()
	gs.get("campaign_rules").autosave_rules = SavePolicy.default_autosave_rules()
	sm.call("configure_save_dir_for_tests", old_dir)
	_clean()
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _clean() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var dir := DirAccess.open(TEST_DIR)
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
