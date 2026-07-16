extends SceneTree


func _init() -> void:
	print("=== Skill Release Availability Test ===")
	var passed := 0
	var failed := 0
	var dm: Node = load("res://scripts/autoloads/DataManager.gd").new()
	dm.name = "DataManager"
	root.add_child(dm)
	await process_frame

	var armsthrift: SkillData = dm.get_skill("armsthrift")
	var discipline: SkillData = dm.get_skill("discipline")
	var synthetic := SkillData.new()
	synthetic.id = "future_stub"
	synthetic.release_available = false
	if (
		armsthrift != null
		and not armsthrift.is_available_for_release()
		and not synthetic.is_available_for_release()
		and discipline != null
		and discipline.is_available_for_release()
	):
		print("OK  metadata excludes stubs and retains implemented skills")
		passed += 1
	else:
		print("FAIL release availability metadata")
		failed += 1

	var handler: Node = load("res://scripts/skills/SkillHandler.gd").new()
	root.add_child(handler)
	await process_frame
	var context := {"unchanged": true}
	var executed: bool = handler._execute_skill(armsthrift, null, context)
	if not executed and context == {"unchanged": true} and handler._stub_warned.is_empty():
		print("OK  release-unavailable legacy stubs stay inert and quiet")
		passed += 1
	else:
		print("FAIL stub execution safety")
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
