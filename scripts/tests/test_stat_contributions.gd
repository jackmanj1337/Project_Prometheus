extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_stat_contributions.gd
#
# Verifies StatContributions (the combat-only stat sources the character sheet
# shows) AND — critically — that its numbers match what combat actually applies.
# This is the drift guard the playtest #8.5 lesson demands: the display and the
# combat math must never diverge. For each source we apply it through the real
# combat path and assert the applied modifier equals the collector's row.

const StatContributions = preload("res://scripts/shared/StatContributions.gd")
const UnitScene = preload("res://scenes/units/Unit.tscn")
const SkillDataS = preload("res://scripts/resources/SkillData.gd")

const CAVALIER_PATH := "res://data/roster/test/map_950_promotion_validation/unit_01_cavalier.tres"
const HERO_PATH := "res://data/roster/test/map_950_promotion_validation/unit_12_hero_skill_cap.tres"


func _init() -> void:
	print("=== StatContributions Test ===")
	var passed := 0
	var failed := 0

	await process_frame  # let autoloads attach to root
	var gs := root.get_node_or_null("GameState")
	var reg := root.get_node_or_null("PairUpRegistry")
	var res := root.get_node_or_null("PairUpBonusResolver")
	var dm := root.get_node_or_null("DataManager")
	var cr := root.get_node_or_null("CombatResolver")
	var sh := root.get_node_or_null("SkillHandler")
	if [gs, reg, res, dm, cr, sh].any(func(n): return n == null):
		print("FAIL autoload missing: gs=%s reg=%s res=%s dm=%s cr=%s sh=%s" % [gs, reg, res, dm, cr, sh])
		quit(1)
		return

	var deps := {"registry": reg, "game_state": gs, "resolver": res, "data_manager": dm}

	# ── Empty: a lone unpaired unit with no stat skills contributes nothing ──
	gs.call("reset_map_state")
	reg.call("clear")
	var rules: CampaignRules = gs.get("campaign_rules") as CampaignRules
	rules.pair_up_enabled = true
	var lone: Node = UnitScene.instantiate()
	lone.data = (load(HERO_PATH) as Resource).duplicate(true)
	lone.team = "blue"
	root.add_child(lone)
	gs.call("register_unit", lone)
	if StatContributions.for_stat(lone, "strength", deps).is_empty():
		print("OK  unpaired, skill-less unit yields no combat-only contributions"); passed += 1
	else:
		print("FAIL lone unit contributions: %s" % str(StatContributions.for_stat(lone, "strength", deps)))
		failed += 1

	# ── Pair Up: collector row must equal what CombatResolver applies ────────
	var support: Node = UnitScene.instantiate()
	support.data = (load(CAVALIER_PATH) as Resource).duplicate(true)
	support.team = "blue"
	root.add_child(support)
	gs.call("register_unit", support)
	reg.call("pair", lone.data.unit_id, support.data.unit_id)  # lone = lead

	var coll_str: int = _delta_for(StatContributions.for_stat(lone, "strength", deps), "pair_up")
	# Apply the bonus through the real combat path, then read it back off the unit.
	lone.data.active_modifiers.clear()
	cr._apply_pair_up_bonuses(lone, support)
	var combat_str: int = _applied_combat_delta(lone, "strength", "pair_up")
	lone.clear_combat_modifiers()
	if coll_str == 3 and combat_str == 3:
		print("OK  pair-up: collector (+%d) == combat-applied (+%d) for strength" % [coll_str, combat_str])
		passed += 1
	else:
		print("FAIL pair-up drift: collector=%d combat=%d (want 3/3)" % [coll_str, combat_str]); failed += 1

	# The lead-only rule: the SUPPORT (not a lead) shows no pair-up contribution.
	if _delta_for(StatContributions.for_stat(support, "strength", deps), "pair_up") == 0:
		print("OK  the support side shows no pair-up contribution (lead-only)"); passed += 1
	else:
		print("FAIL support showed a pair-up contribution"); failed += 1

	# ── Personal stat_bonus skill: collector row must equal combat ──────────
	reg.call("clear")
	var skl_unit: Node = UnitScene.instantiate()
	var sd := UnitData.new()
	sd.unit_id = "sc_skill_unit"
	sd.unit_name = "Skill Unit"
	sd.class_id = "knight"
	sd.defense = 10
	sd.skills = ["defense_plus_2"]  # real on_combat_start stat_bonus skill (+2 Def)
	skl_unit.data = sd
	skl_unit.team = "blue"
	root.add_child(skl_unit)
	gs.call("register_unit", skl_unit)

	var coll_def: int = _delta_for(StatContributions.for_stat(skl_unit, "defense", deps), "skill:defense_plus_2")
	skl_unit.data.active_modifiers.clear()
	sh.call("apply_trigger", skl_unit, "on_combat_start", {"attacker": skl_unit, "defender": null})
	var combat_def: int = _applied_combat_delta(skl_unit, "defense", "skill:defense_plus_2")
	skl_unit.clear_combat_modifiers()
	if coll_def == 2 and combat_def == 2:
		print("OK  stat skill: collector (+%d) == combat-applied (+%d) for defense" % [coll_def, combat_def])
		passed += 1
	else:
		print("FAIL stat-skill drift: collector=%d combat=%d (want 2/2)" % [coll_def, combat_def]); failed += 1

	# That skill does not bleed into an unrelated stat.
	if StatContributions.for_stat(skl_unit, "strength", deps).is_empty():
		print("OK  a Defense +2 skill contributes nothing to strength"); passed += 1
	else:
		print("FAIL stat-skill bled into strength"); failed += 1

	reg.call("clear")
	gs.call("reset_map_state")
	lone.queue_free(); support.queue_free(); skl_unit.queue_free()

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


# Sum of collector rows matching a source id (or prefix for namespaced ids).
func _delta_for(rows: Array, source_id: String) -> int:
	var total := 0
	for r in rows:
		if String(r["source_id"]) == source_id:
			total += int(r["delta"])
	return total


# Sum of combat-duration modifiers on the unit whose source matches a prefix.
func _applied_combat_delta(unit: Node, stat: String, source_prefix: String) -> int:
	var total := 0
	for m in unit.data.active_modifiers:
		if String(m.get("stat", "")) != stat:
			continue
		if String(m.get("source", "")).begins_with(source_prefix):
			total += int(m.get("delta", 0))
	return total
