extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_data_manager.gd
# Tests DataManager: id-based lookups for the four content catalogues (loaded by
# _ready on add_child) and the weapon-triangle resolution.

func _init() -> void:
	print("=== DataManager Test ===")
	var passed := 0
	var failed := 0

	var dm: Node = load("res://scripts/autoloads/DataManager.gd").new()
	dm.name = "DataManager"
	root.add_child(dm)   # entering the tree runs _ready → loads every catalogue
	await process_frame

	# ---- get_weapon resolves a known weapon id ----
	var sword = dm.get_weapon("iron_sword")
	if sword != null and sword.id == "iron_sword":
		print("OK  get_weapon resolves a known weapon id"); passed += 1
	else:
		print("FAIL get_weapon(iron_sword)"); failed += 1

	# ---- get_weapon returns null for an unknown id (a push_error is expected) ----
	if dm.get_weapon("no_such_weapon") == null:
		print("OK  get_weapon returns null for an unknown id"); passed += 1
	else:
		print("FAIL get_weapon(unknown)"); failed += 1

	# ---- get_item / get_skill / get_class_data resolve known ids ----
	if dm.get_item("vulnerary") != null:
		print("OK  get_item resolves a known item id"); passed += 1
	else:
		print("FAIL get_item(vulnerary)"); failed += 1
	if dm.get_skill("vantage") != null:
		print("OK  get_skill resolves a known skill id"); passed += 1
	else:
		print("FAIL get_skill(vantage)"); failed += 1
	if dm.get_class_data("mercenary") != null:
		print("OK  get_class_data resolves a known class id"); passed += 1
	else:
		print("FAIL get_class_data(mercenary)"); failed += 1

	# ---- weapon triangle: sword beats axe, loses to lance, neutral vs sword ----
	var adv: bool = dm.get_weapon_triangle_result("sword", "axe") == "advantage"
	var dis: bool = dm.get_weapon_triangle_result("sword", "lance") == "disadvantage"
	var neu: bool = dm.get_weapon_triangle_result("sword", "sword") == "neutral"
	if adv and dis and neu:
		print("OK  weapon triangle: sword vs axe / lance / sword")
		passed += 1
	else:
		print("FAIL weapon triangle sword: adv=%s dis=%s neu=%s" % [adv, dis, neu])
		failed += 1

	# ---- weapon triangle: axe beats lance; an unknown type resolves to neutral ----
	var axe_adv: bool = dm.get_weapon_triangle_result("axe", "lance") == "advantage"
	var unknown: bool = dm.get_weapon_triangle_result("frying_pan", "sword") == "neutral"
	if axe_adv and unknown:
		print("OK  weapon triangle: axe beats lance; an unknown type → neutral"); passed += 1
	else:
		print("FAIL weapon triangle: axe_adv=%s unknown=%s" % [axe_adv, unknown])
		failed += 1

	# ---- B6: live data passes new validation cleanly ----
	# All real .tres files must come up clean against the extended checks; if a
	# new family/track/effect_id is added without updating GameConstants or
	# ItemHandler, this catches it before commit.
	var DataManagerS = load("res://scripts/autoloads/DataManager.gd")
	var live_errors: Array[String] = DataManagerS.collect_validation_errors(
		dm._classes, dm._weapons, dm._items, dm._skills)
	if live_errors.is_empty():
		print("OK  live catalogue validates clean against B6 checks"); passed += 1
	else:
		print("FAIL live validation: %s" % [live_errors]); failed += 1

	# ---- B6: bad fixtures fire the right errors ----
	# Hand-build minimal ad-hoc resources and assert each invalid field surfaces.
	# The collector is pure, so we drive it with fixture dicts and never mutate
	# the loaded catalogues.
	var bad_weapon := WeaponData.new()
	bad_weapon.id = "bad_w"
	bad_weapon.combat_family = "sord"  # typo of "sword"
	bad_weapon.wexp_track = "elemental_magik"
	bad_weapon.required_rank = "Z"
	bad_weapon.triangle_family = "frying_pan"
	bad_weapon.effect_tags = ["effective_armored"]  # typo of "armoured"
	var bad_item := ItemData.new()
	bad_item.id = "bad_i"
	bad_item.effect_id = "heal_partial"  # not implemented
	bad_item.effect_params = {
		"allowed_classes": ["no_such_class"],
		"allowed_class_groups": ["no_such_group"],
	}
	var bad_skill := SkillData.new()
	bad_skill.id = "bad_s"
	bad_skill.activation_chance_stat = "charisma"  # not a stat
	bad_skill.effect_params = {"weapon_type": "frying_pan"}
	var ok_class := ClassData.new()
	ok_class.id = "ok_c"
	ok_class.class_groups = ["real_group"]
	var errs: Array[String] = DataManagerS.collect_validation_errors(
		{"ok_c": ok_class}, {"bad_w": bad_weapon}, {"bad_i": bad_item}, {"bad_s": bad_skill})
	# Expect 10: family, track, required rank, triangle family, effect_tag, item
	# effect_id, bad allowed_class, bad allowed_group, skill stat, skill weapon_type.
	var w_type_err: bool   = errs.any(func(e): return "weapon 'bad_w' combat_family 'sord'" in e)
	var w_track_err: bool  = errs.any(func(e): return "weapon 'bad_w' wexp_track 'elemental_magik'" in e)
	var w_rank_err: bool   = errs.any(func(e): return "weapon 'bad_w' required_rank 'Z'" in e)
	var w_tri_err: bool    = errs.any(func(e): return "weapon 'bad_w' triangle_family 'frying_pan'" in e)
	var w_tag_err: bool    = errs.any(func(e): return "weapon 'bad_w' effect_tag 'effective_armored'" in e)
	var i_eff_err: bool    = errs.any(func(e): return "item 'bad_i' effect_id 'heal_partial'" in e)
	var i_class_err: bool  = errs.any(func(e): return "item 'bad_i' allowed_classes 'no_such_class'" in e)
	var i_group_err: bool  = errs.any(func(e): return "item 'bad_i' allowed_class_groups 'no_such_group'" in e)
	var s_stat_err: bool   = errs.any(func(e): return "skill 'bad_s' activation_chance_stat 'charisma'" in e)
	var s_wtype_err: bool  = errs.any(func(e): return "skill 'bad_s' effect_params.weapon_type 'frying_pan'" in e)
	if w_type_err and w_track_err and w_rank_err and w_tri_err and w_tag_err and i_eff_err and i_class_err and i_group_err \
			and s_stat_err and s_wtype_err:
		print("OK  bad fixtures fire all ten new B6 checks"); passed += 1
	else:
		print("FAIL B6 bad fixtures: w_type=%s w_track=%s w_rank=%s w_tri=%s w_tag=%s i_eff=%s i_class=%s i_group=%s s_stat=%s s_wtype=%s errs=%s" % [
			w_type_err, w_track_err, w_rank_err, w_tri_err, w_tag_err, i_eff_err, i_class_err, i_group_err, s_stat_err, s_wtype_err, errs])
		failed += 1

	# ---- Class validation: bad skill_unlocks ref + incomplete stat dict + bad promotes_to ----
	# A class that auto-grants a missing skill, or whose growth table drops a stat
	# key, must fail validation before it can silently misbehave at level-up.
	var bad_class := ClassData.new()
	bad_class.id = "bad_c"
	bad_class.skill_unlocks = {1: "no_such_skill"}
	bad_class.player_growth_rates = {"hp": 50}  # missing the other 7 stat keys
	bad_class.promotes_to = ["no_such_target"]
	bad_class.internal_level_rule = "sideways"
	bad_class.class_availability = "secret"
	bad_class.vulnerability_groups = ["slime"]
	var class_errs: Array[String] = DataManagerS.collect_validation_errors(
		{"bad_c": bad_class}, {}, {}, dm._skills)
	var c_skill_err: bool = class_errs.any(func(e): return "class 'bad_c' skill_unlocks[1] 'no_such_skill'" in e)
	var c_growth_err: bool = class_errs.any(func(e): return "class 'bad_c' player_growth_rates missing stat key" in e)
	var c_promote_err: bool = class_errs.any(func(e): return "class 'bad_c' promotes_to 'no_such_target'" in e)
	var c_rule_err: bool = class_errs.any(func(e): return "class 'bad_c' internal_level_rule 'sideways'" in e)
	var c_availability_err: bool = class_errs.any(func(e): return "class 'bad_c' class_availability 'secret'" in e)
	var c_vuln_err: bool = class_errs.any(func(e): return "class 'bad_c' vulnerability_groups 'slime'" in e)
	if c_skill_err and c_growth_err and c_promote_err and c_rule_err and c_availability_err and c_vuln_err:
		print("OK  bad class fixture fires schema validation for skills, stats, promotion, level rule, availability, and vulnerabilities"); passed += 1
	else:
		print("FAIL class checks: skill=%s growth=%s promote=%s rule=%s availability=%s vuln=%s errs=%s" % [
			c_skill_err, c_growth_err, c_promote_err, c_rule_err, c_availability_err, c_vuln_err, class_errs])
		failed += 1

	# ---- Unit validation: bad class_line_id + bad reclass_options are caught ----
	var bad_unit := UnitData.new()
	bad_unit.unit_id = "bad_u"
	bad_unit.class_id = "cavalier"
	bad_unit.class_line_id = "paladin"
	bad_unit.reclass_options = ["mage", "no_such_class"]
	bad_unit.weapon_wexp = {"fire": 50}
	var unit_errs: Array[String] = DataManagerS.collect_unit_validation_errors([bad_unit], dm._classes)
	var u_line_err: bool = unit_errs.any(func(e): return "unit 'bad_u' class_line_id 'paladin' must point to a tier-1 class" in e)
	var u_missing_err: bool = unit_errs.any(func(e): return "unit 'bad_u' reclass_options 'no_such_class' not found" in e)
	var u_track_err: bool = unit_errs.any(func(e): return "unit 'bad_u' weapon_wexp key 'fire'" in e)
	if u_line_err and u_missing_err and u_track_err:
		print("OK  bad unit fixture fires class_line_id + reclass_options + weapon_wexp checks"); passed += 1
	else:
		print("FAIL unit checks: line=%s missing=%s track=%s errs=%s" % [
			u_line_err, u_missing_err, u_track_err, unit_errs])
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
