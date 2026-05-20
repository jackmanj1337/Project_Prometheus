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
	# new tag/weapon_type/effect_id is added without updating GameConstants or
	# ItemHandler, this catches it before commit.
	var DataManagerS = load("res://scripts/autoloads/DataManager.gd")
	var live_errors: Array[String] = DataManagerS.collect_validation_errors(
		dm._classes, dm._weapons, dm._items, dm._skills)
	if live_errors.is_empty():
		print("OK  live catalogue validates clean against B6 checks"); passed += 1
	else:
		print("FAIL live validation: %s" % live_errors); failed += 1

	# ---- B6: bad fixtures fire the right errors ----
	# Hand-build minimal ad-hoc resources and assert each invalid field surfaces.
	# The collector is pure, so we drive it with fixture dicts and never mutate
	# the loaded catalogues.
	var bad_weapon := WeaponData.new()
	bad_weapon.id = "bad_w"
	bad_weapon.weapon_type = "sord"  # typo of "sword"
	bad_weapon.effect_tags = ["effective_armored"]  # typo of "armoured"
	var bad_item := ItemData.new()
	bad_item.id = "bad_i"
	bad_item.effect_id = "heal_partial"  # not implemented
	var bad_skill := SkillData.new()
	bad_skill.id = "bad_s"
	bad_skill.activation_chance_stat = "charisma"  # not a stat
	bad_skill.effect_params = {"weapon_type": "frying_pan"}
	var errs: Array[String] = DataManagerS.collect_validation_errors(
		{}, {"bad_w": bad_weapon}, {"bad_i": bad_item}, {"bad_s": bad_skill})
	# Expect 5: weapon_type, effect_tag, item effect_id, skill stat, skill weapon_type.
	var w_type_err: bool   = errs.any(func(e): return "weapon 'bad_w' weapon_type 'sord'" in e)
	var w_tag_err: bool    = errs.any(func(e): return "weapon 'bad_w' effect_tag 'effective_armored'" in e)
	var i_eff_err: bool    = errs.any(func(e): return "item 'bad_i' effect_id 'heal_partial'" in e)
	var s_stat_err: bool   = errs.any(func(e): return "skill 'bad_s' activation_chance_stat 'charisma'" in e)
	var s_wtype_err: bool  = errs.any(func(e): return "skill 'bad_s' effect_params.weapon_type 'frying_pan'" in e)
	if w_type_err and w_tag_err and i_eff_err and s_stat_err and s_wtype_err:
		print("OK  bad fixtures fire all five new B6 checks"); passed += 1
	else:
		print("FAIL B6 bad fixtures: w_type=%s w_tag=%s i_eff=%s s_stat=%s s_wtype=%s errs=%s" % [
			w_type_err, w_tag_err, i_eff_err, s_stat_err, s_wtype_err, errs])
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
