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

	# ---- export-safe manifests enumerate the live content catalogues ----
	var ResourceManifest = load("res://scripts/shared/ResourceManifest.gd")
	var manifest_ok: bool = (
		ResourceManifest.load_paths("res://data/classes/").size() == 24
		and ResourceManifest.load_paths("res://data/weapons/").size() == 11
		and ResourceManifest.load_paths("res://data/items/").size() == 7
		and ResourceManifest.load_paths("res://data/skills/").size() == 54
	)
	if manifest_ok:
		print("OK  resource manifests enumerate the live catalogues"); passed += 1
	else:
		print("FAIL resource manifests missing catalogue entries"); failed += 1

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
	if dm.get_weapon("iron_lance") != null and dm.get_skill("discipline") != null:
		print("OK  manifest-backed boot resolves export-critical weapon + skill ids"); passed += 1
	else:
		print("FAIL manifest-backed boot missed export-critical ids"); failed += 1

	# ---- duplicate ids fail loud instead of silently overwriting ----
	var dup_target := {}
	var dup_a := WeaponData.new()
	dup_a.id = "dup_weapon"
	var dup_b := WeaponData.new()
	dup_b.id = "dup_weapon"
	var DataManagerS = load("res://scripts/autoloads/DataManager.gd")
	var first_r: Dictionary = dm.register_loaded_resource(dup_target, dup_a, "res://a.tres")
	var second_r: Dictionary = dm.register_loaded_resource(dup_target, dup_b, "res://b.tres")
	if first_r["result"] == DataManagerS.LoadResult.OK \
			and second_r["result"] == DataManagerS.LoadResult.DUPLICATE_ID \
			and "duplicate resource id 'dup_weapon'" in String(second_r["message"]) \
			and dup_target["dup_weapon"] == dup_a:
		print("OK  register_loaded_resource rejects duplicate ids without overwriting the original")
		passed += 1
	else:
		print("FAIL duplicate-id guard: first=%s second=%s target=%s" % [
			first_r, second_r, dup_target])
		failed += 1

	# ---- missing id / failed load each return their own result code ----
	var miss_target := {}
	var miss_res := WeaponData.new()
	# miss_res.id left as default "" → MISSING_ID
	var miss_r: Dictionary = dm.register_loaded_resource(miss_target, miss_res, "res://m.tres")
	var fail_r: Dictionary = dm.register_loaded_resource(miss_target, null, "res://f.tres")
	if miss_r["result"] == DataManagerS.LoadResult.MISSING_ID \
			and fail_r["result"] == DataManagerS.LoadResult.LOAD_FAILED \
			and miss_target.is_empty():
		print("OK  register_loaded_resource reports MISSING_ID and LOAD_FAILED distinctly")
		passed += 1
	else:
		print("FAIL register_loaded_resource result codes: miss=%s fail=%s target=%s" % [
			miss_r, fail_r, miss_target])
		failed += 1

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
	# (DataManagerS already in scope from the result-code test above.)
	var live_errors: Array[String] = DataManagerS.collect_validation_errors(
		dm._classes, dm._weapons, dm._items, dm._skills)
	if live_errors.is_empty():
		print("OK  live catalogue validates clean against B6 checks"); passed += 1
	else:
		print("FAIL live validation: %s" % [live_errors]); failed += 1

	var live_map_errors: Array[String] = DataManagerS.collect_map_registry_validation_errors(
		"res://data/maps/map_registry.json", dm._classes, dm._items)
	if live_map_errors.is_empty():
		print("OK  live map registry and referenced MapData validate cleanly"); passed += 1
	else:
		print("FAIL live map validation: %s" % [live_map_errors]); failed += 1

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

	# ---- Map/registry validation: bad fixtures fail loud on authoring drift ----
	var bad_map := MapData.new()
	bad_map.tilemap_scene_path = "res://missing_map_scene.tscn"
	bad_map.grid = ["..", ".X."] as Array[String]
	bad_map.player_start_tiles = [Vector2i(0, 0), Vector2i(0, 0), Vector2i(5, 5)] as Array[Vector2i]
	bad_map.camera_start_tile = Vector2i(99, 99)
	bad_map.activation_mode = "ROUND_ROBIN"
	bad_map.reward_items = ["", "missing_item"] as Array[String]
	var dup_green_a := FactionData.new()
	dup_green_a.id = "green"
	dup_green_a.alliance_group = "allies"
	var dup_green_b := FactionData.new()
	dup_green_b.id = "green"
	dup_green_b.alliance_group = "allies"
	bad_map.factions = [dup_green_a, dup_green_b]
	bad_map.turn_order = ["ghost", "ghost"] as Array[String]
	bad_map.enemy_placements = [
		{"unit_data_path": "res://missing_enemy.tres", "tile": Vector2i(9, 9), "faction": "purple", "ai_profile": "berserk"},
		{"tile": Vector2i(1, 1)}
	]
	var bad_rout := ObjectiveCondition.new()
	bad_rout.type = "rout"
	bad_rout.faction_id = "phantoms"
	var bad_seize := ObjectiveCondition.new()
	bad_seize.type = "seize"
	bad_seize.tile = Vector2i(8, 8)
	var bad_escape := ObjectiveCondition.new()
	bad_escape.type = "escape"
	bad_escape.tiles = [Vector2i(4, 4)] as Array[Vector2i]
	var bad_survive := ObjectiveCondition.new()
	bad_survive.type = "survive"
	bad_survive.tiles = [Vector2i(7, 7)] as Array[Vector2i]
	bad_map.victory_conditions = {
		"": [bad_seize],
		"allies": [bad_rout, bad_escape, bad_survive],
		"mystery_group": ["not_a_condition"],
	}
	var bad_map_errors: Array[String] = DataManagerS.collect_map_data_validation_errors(
		bad_map, "res://bad_map.tres", dm._classes, dm._items)
	var m_id_err: bool = bad_map_errors.any(func(e): return "missing MapData.id" in e)
	var m_name_err: bool = bad_map_errors.any(func(e): return "missing display_name" in e)
	var m_scene_err: bool = bad_map_errors.any(func(e): return "tilemap_scene_path 'res://missing_map_scene.tscn' is missing" in e)
	var m_reward_empty_err: bool = bad_map_errors.any(func(e): return "reward_items contains an empty item id" in e)
	var m_reward_missing_err: bool = bad_map_errors.any(func(e): return "reward_items item 'missing_item' not found" in e)
	var m_grid_err: bool = bad_map_errors.any(func(e): return "unknown terrain 'X'" in e)
	var m_grid_len_err: bool = bad_map_errors.any(func(e): return "grid row 1 length 3 != 2" in e)
	var m_start_dup_err: bool = bad_map_errors.any(func(e): return "duplicate player_start_tile" in e)
	var m_start_oob_err: bool = bad_map_errors.any(func(e): return "player_start_tile (5, 5) is outside the grid" in e)
	var m_cam_err: bool = bad_map_errors.any(func(e): return "camera_start_tile" in e)
	var m_mode_err: bool = bad_map_errors.any(func(e): return "activation_mode 'ROUND_ROBIN'" in e)
	var m_turn_err: bool = bad_map_errors.any(func(e): return "turn_order references unknown faction 'ghost'" in e)
	var m_enemy_missing_err: bool = bad_map_errors.any(func(e): return "missing UnitData 'res://missing_enemy.tres'" in e)
	var m_enemy_faction_err: bool = bad_map_errors.any(func(e): return "enemy placement references unknown faction 'purple'" in e)
	var m_enemy_ai_err: bool = bad_map_errors.any(func(e): return "enemy placement ai_profile 'berserk' is not valid" in e)
	var m_enemy_tile_err: bool = bad_map_errors.any(func(e): return "enemy placement tile (9, 9) is outside the grid" in e)
	var m_cond_group_err: bool = bad_map_errors.any(func(e): return "empty group id" in e)
	var m_seize_err: bool = bad_map_errors.any(func(e): return "seize condition" in e and "tile (8, 8) is outside the grid" in e)
	var m_escape_err: bool = bad_map_errors.any(func(e): return "escape condition" in e and "requires unit_ids" in e)
	var m_escape_tile_err: bool = bad_map_errors.any(func(e): return "escape condition" in e and "tile (4, 4) is outside the grid" in e)
	var m_survive_err: bool = bad_map_errors.any(func(e): return "survive condition" in e and "turns > 0" in e)
	var m_survive_tile_err: bool = bad_map_errors.any(func(e): return "survive condition" in e and "tile (7, 7) is outside the grid" in e)
	var m_unknown_group_err: bool = bad_map_errors.any(func(e): return "unknown alliance group 'mystery_group'" in e)
	var m_bad_cond_err: bool = bad_map_errors.any(func(e): return "is not an ObjectiveCondition" in e)
	if m_id_err and m_name_err and m_scene_err and m_reward_empty_err and m_reward_missing_err \
			and m_grid_err and m_grid_len_err and m_start_dup_err and m_start_oob_err and m_cam_err \
			and m_mode_err and m_turn_err and m_enemy_missing_err and m_enemy_faction_err \
			and m_enemy_ai_err and m_enemy_tile_err and m_cond_group_err and m_seize_err \
			and m_escape_err and m_escape_tile_err and m_survive_err and m_survive_tile_err \
			and m_unknown_group_err and m_bad_cond_err:
		print("OK  bad map fixture fires grid, roster, faction, and objective authoring checks"); passed += 1
	else:
		print("FAIL bad map checks: id=%s name=%s scene=%s reward_empty=%s reward_missing=%s grid=%s grid_len=%s start_dup=%s start_oob=%s cam=%s mode=%s turn=%s enemy_missing=%s enemy_faction=%s enemy_ai=%s enemy_tile=%s cond_group=%s seize=%s escape=%s escape_tile=%s survive=%s survive_tile=%s unknown_group=%s bad_cond=%s errs=%s" % [
			m_id_err, m_name_err, m_scene_err, m_reward_empty_err, m_reward_missing_err,
			m_grid_err, m_grid_len_err, m_start_dup_err, m_start_oob_err, m_cam_err,
			m_mode_err, m_turn_err, m_enemy_missing_err, m_enemy_faction_err,
			m_enemy_ai_err, m_enemy_tile_err, m_cond_group_err, m_seize_err,
			m_escape_err, m_escape_tile_err, m_survive_err, m_survive_tile_err,
			m_unknown_group_err, m_bad_cond_err, bad_map_errors])
		failed += 1

	var bad_registry: Array = [
		{
			"id": "map_001",
			"label": "",
			"map_data_path": "res://data/maps/map_001_rout/map_001_data.tres",
			"roster_policy": "fixed_test_roster",
			"roster_source": "",
		},
		{
			"id": "map_001",
			"label": "Duplicate",
			"map_data_path": "res://data/maps/map_001_rout/map_001_data.tres",
			"roster_policy": "bogus_policy",
			"roster_source": "res://data/roster/default/",
		},
	]
	var registry_fixture_errors: Array[String] = []
	var seen_ids := {}
	var seen_paths := {}
	for i in bad_registry.size():
		DataManagerS._validate_map_registry_entry(
			bad_registry[i], i, seen_ids, seen_paths, dm._classes, dm._items, registry_fixture_errors)
	var r_dup_err: bool = registry_fixture_errors.any(func(e): return "duplicate id 'map_001'" in e)
	var r_label_err: bool = registry_fixture_errors.any(func(e): return "missing 'label'" in e)
	var r_policy_err: bool = registry_fixture_errors.any(func(e): return "roster_policy 'bogus_policy'" in e)
	var r_fixed_src_err: bool = registry_fixture_errors.any(func(e): return "fixed_test_roster is missing roster_source" in e)
	var r_path_dup_err: bool = registry_fixture_errors.any(func(e): return "duplicate map_data_path" in e)
	var r_source_should_empty_err: bool = registry_fixture_errors.any(func(e):
		return "roster_source should be empty" in e)
	if r_dup_err and r_label_err and r_policy_err and r_fixed_src_err and r_path_dup_err \
			and r_source_should_empty_err:
		print("OK  bad registry fixture fires duplicate-id, policy, and roster-source checks"); passed += 1
	else:
		print("FAIL bad registry checks: dup=%s label=%s policy=%s fixed_src=%s path_dup=%s source_empty=%s errs=%s" % [
			r_dup_err, r_label_err, r_policy_err, r_fixed_src_err, r_path_dup_err,
			r_source_should_empty_err, registry_fixture_errors])
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

	# ---- 2.10: cross-source unit_id uniqueness ──────────────────────────────
	# A roster unit and an enemy placement sharing a unit_id is a silent runtime
	# disaster: find_unit_by_id returns whichever loaded first, breaking Pair Up
	# lookups in non-obvious ways. The validator now threads a shared dedup dict
	# across the roster pass and the enemy_placements pass.
	var dup_map := MapData.new()
	dup_map.id = "dup_unit_id_check"
	dup_map.display_name = "dup unit_id check"
	dup_map.grid = ["..."] as Array[String]
	dup_map.player_start_tiles = [Vector2i(0, 0)] as Array[Vector2i]
	dup_map.enemy_placements = [
		{"unit_data_path": "res://data/maps/map_001_rout/enemies/e1_soldier.tres",
			"tile": Vector2i(2, 0), "faction": "red", "ai_profile": "basic"},
	]
	# Pre-seed seen_unit_ids as if the roster pass had already registered the
	# same unit_id ("e1_soldier") from a fake roster file. The enemy_placement
	# loader should detect the collision.
	var seen: Dictionary = {"e1_soldier": "roster file 'fake_roster.tres'"}
	var dup_errors: Array[String] = DataManagerS.collect_map_data_validation_errors(
		dup_map, "res://dup_map.tres", dm._classes, dm._items, seen)
	var dup_err_found: bool = dup_errors.any(func(e):
		return "duplicate unit_id 'e1_soldier'" in e and "fake_roster.tres" in e)
	if dup_err_found:
		print("OK  2.10: cross-source duplicate unit_id fires loud"); passed += 1
	else:
		print("FAIL 2.10 cross-source dup: %s" % dup_errors); failed += 1

	# ---- 2.7: hp/max_hp/level invariants ────────────────────────────────────
	# Pre-2026-06-10 a unit with hp=50, max_hp=10 would load fine and render
	# broken in-game. Now caught at boot like the GameState snapshot validator
	# already catches the same shape at runtime.
	var hp_bad := UnitData.new()
	hp_bad.unit_id = "hp_bad"
	hp_bad.class_id = "cavalier"
	hp_bad.level = 0      # below minimum
	hp_bad.max_hp = 0     # below minimum
	hp_bad.hp = -3        # negative
	var hp_max_bad := UnitData.new()
	hp_max_bad.unit_id = "overflow"
	hp_max_bad.class_id = "cavalier"
	hp_max_bad.max_hp = 10
	hp_max_bad.hp = 50    # exceeds max
	var inv_errs: Array[String] = DataManagerS.collect_unit_validation_errors(
		[hp_bad, hp_max_bad], dm._classes)
	var level_err: bool = inv_errs.any(func(e): return "unit 'hp_bad' level must be >= 1" in e)
	var max_err: bool = inv_errs.any(func(e): return "unit 'hp_bad' max_hp must be >= 1" in e)
	var neg_err: bool = inv_errs.any(func(e): return "unit 'hp_bad' hp cannot be negative" in e)
	var over_err: bool = inv_errs.any(func(e): return "unit 'overflow' hp 50 exceeds max_hp 10" in e)
	if level_err and max_err and neg_err and over_err:
		print("OK  2.7: hp/max_hp/level invariants fail loud at validation"); passed += 1
	else:
		print("FAIL 2.7 invariants: level=%s max=%s neg=%s over=%s errs=%s" % [
			level_err, max_err, neg_err, over_err, inv_errs])
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
