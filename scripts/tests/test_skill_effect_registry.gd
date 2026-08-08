extends SceneTree
# Regression pin for the exact vocabulary moved out of SkillHandler. This keeps
# the consolidation behavior-neutral and distinguishes known inert effects from
# typos that the pack schema must reject.

const RegistryScript = preload("res://scripts/registries/SkillEffectRegistry.gd")
const SkillHandlerScript = preload("res://scripts/skills/SkillHandler.gd")


func _init() -> void:
	print("=== Skill Effect Registry Test ===")
	var passed := 0
	var failed := 0
	var handler: Node = SkillHandlerScript.new()
	var registry := RegistryScript.new()
	var errors := registry.register_builtins(handler)

	var expected_implemented: Array[String] = [
		"anathema",
		"breaker",
		"charm",
		"daunt",
		"discipline",
		"faire",
		"focus",
		"healtouch",
		"miracle",
		"nihil",
		"patience",
		"prescience",
		"renewal",
		"resolve",
		"s_rank_mastery",
		"stat_bonus",
		"vantage",
		"wrath"
	]
	var expected_inert: Array[String] = [
		"aegis",
		"armsthrift",
		"bastion",
		"blessing",
		"boon",
		"challenge",
		"charge",
		"counter",
		"dash",
		"deadeye",
		"deeper_knowledge",
		"diehard",
		"disarm",
		"even_rhythm",
		"flare",
		"hawkeye",
		"holy_aura",
		"indoor_fighter",
		"iron_wall",
		"judgement",
		"lifetaker",
		"multishot",
		"odd_rhythm",
		"outdoor_fighter",
		"pavise",
		"phasing",
		"rally_skill",
		"shadowgift",
		"sol",
		"strike_true",
		"supremacy",
		"swiftfoot",
		"vigilance"
	]
	if errors.is_empty() and registry.implemented_ids() == expected_implemented:
		print("OK  all 18 implemented effect ids survived consolidation")
		passed += 1
	else:
		print("FAIL implemented effect ids changed: %s / %s" % [errors, registry.implemented_ids()])
		failed += 1
	if registry.inert_ids() == expected_inert:
		print("OK  all known inert effect ids remain distinguishable from unknown ids")
		passed += 1
	else:
		print("FAIL inert effect ids changed: %s" % [registry.inert_ids()])
		failed += 1
	if not registry.has_effect("typo_effect"):
		print("OK  an unknown effect id is not admitted")
		passed += 1
	else:
		print("FAIL unknown effect id was admitted")
		failed += 1

	handler.free()
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)
