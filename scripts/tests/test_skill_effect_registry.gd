extends SceneTree
# Regression pin for the exact vocabulary moved out of SkillHandler. This keeps
# the consolidation behavior-neutral and distinguishes known inert effects from
# typos that the pack schema must reject.

const RegistryScript = preload("res://scripts/registries/SkillEffectRegistry.gd")
const ContributionScript = preload("res://scripts/registries/SkillContributionRegistry.gd")
const SkillHandlerScript = preload("res://scripts/skills/SkillHandler.gd")


func _init() -> void:
	print("=== Skill Effect Registry Test ===")
	var passed := 0
	var failed := 0
	var handler: Node = SkillHandlerScript.new()
	var registry := RegistryScript.new()
	var errors := registry.register_builtins(handler)
	var contributions := ContributionScript.new()
	var contribution_errors := contributions.register_builtins(handler)

	# Effects FIRE on a trigger. The five passive ids that used to sit here —
	# swiftfoot, pass, phasing, discipline, healtouch — are declared
	# contributions now and are pinned separately below.
	var expected_implemented: Array[String] = [
		"anathema",
		"breaker",
		"charm",
		"daunt",
		"faire",
		"focus",
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
	var expected_contribution_kinds: Array[String] = [
		"move_cost_override",
		"pass_through_enemies",
		"phase_through_terrain",
		"staff_heal_bonus",
		"wexp_multiplier",
	]
	var expected_contribution_effects: Array[String] = [
		"discipline",
		"healtouch",
		"pass",
		"phasing",
		"swiftfoot",
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
		"rally_skill",
		"shadowgift",
		"sol",
		"strike_true",
		"supremacy",
		"vigilance"
	]
	if errors.is_empty() and registry.implemented_ids() == expected_implemented:
		print("OK  implemented effect ids are exactly the triggered effects")
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
	if (
		contribution_errors.is_empty()
		and contributions.kinds() == expected_contribution_kinds
		and ContributionScript.contribution_effect_ids() == expected_contribution_effects
	):
		print("OK  passive skills are declared contributions, not effects")
		passed += 1
	else:
		print(
			(
				"FAIL contribution registry changed: %s / %s / %s"
				% [
					contribution_errors,
					contributions.kinds(),
					ContributionScript.contribution_effect_ids()
				]
			)
		)
		failed += 1

	# The authorable vocabulary must not narrow: a pack may still write any of
	# the passive ids, they are just dispatched as contributions.
	var authorable: Array[String] = RegistryScript.builtin_ids()
	var vocabulary_kept := true
	for contribution_effect in expected_contribution_effects:
		if authorable.has(contribution_effect):
			vocabulary_kept = false
	if vocabulary_kept:
		print("OK  contribution ids left the effect registry rather than being duplicated in it")
		passed += 1
	else:
		print("FAIL a contribution id is still registered as an effect")
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
