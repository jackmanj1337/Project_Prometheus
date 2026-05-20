extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_data_layer.gd
# Tests that all .tres resource files load correctly without using autoload singletons.

func _init() -> void:
	print("=== Data Layer Test ===")
	var passed := 0
	var failed := 0

	# --- Classes ---
	var class_files := {
		"soldier":    "res://data/classes/soldier.tres",
		"mercenary":  "res://data/classes/mercenary.tres",
		"archer":     "res://data/classes/archer.tres",
		"mage":       "res://data/classes/mage.tres",
		"cleric":     "res://data/classes/cleric.tres",
		"knight":     "res://data/classes/knight.tres",
	}
	for cid in class_files:
		var c = load(class_files[cid])
		if c and c is ClassData and c.id == cid:
			print("OK  class: " + cid)
			passed += 1
		else:
			print("FAIL class: " + cid + " (got: " + str(c) + ")")
			failed += 1

	# --- Weapons ---
	var weapon_files := {
		"iron_sword":  "res://data/weapons/iron_sword.tres",
		"steel_sword": "res://data/weapons/steel_sword.tres",
		"iron_lance":  "res://data/weapons/iron_lance.tres",
		"javelin":     "res://data/weapons/javelin.tres",
		"iron_bow":    "res://data/weapons/iron_bow.tres",
		"fire":        "res://data/weapons/fire.tres",
		"elfire":      "res://data/weapons/elfire.tres",
		"thunder":     "res://data/weapons/thunder.tres",
		"wind":        "res://data/weapons/wind.tres",
		"heal_staff":  "res://data/weapons/heal_staff.tres",
	}
	for wid in weapon_files:
		var w = load(weapon_files[wid])
		if w and w is WeaponData and w.id == wid:
			print("OK  weapon: " + wid)
			passed += 1
		else:
			print("FAIL weapon: " + wid)
			failed += 1

	# --- Items ---
	for iid in ["vulnerary", "elixir"]:
		var it = load("res://data/items/" + iid + ".tres")
		if it and it is ItemData and it.id == iid:
			print("OK  item: " + iid)
			passed += 1
		else:
			print("FAIL item: " + iid)
			failed += 1

	# --- Skills ---
	for sid in ["renewal", "vantage", "nihil", "resolve", "miracle", "wrath",
			"swordfaire", "lancefaire", "bowfaire",
			"swordbreaker", "lancebreaker", "bowbreaker",
			"s_rank_mastery"]:
		var sk = load("res://data/skills/" + sid + ".tres")
		if sk and sk is SkillData and sk.id == sid:
			print("OK  skill: " + sid)
			passed += 1
		else:
			print("FAIL skill: " + sid)
			failed += 1

	# --- Default roster ---
	var roster_files := [
		"res://data/roster/default/unit_01_soldier.tres",
		"res://data/roster/default/unit_02_mercenary.tres",
		"res://data/roster/default/unit_03_archer.tres",
		"res://data/roster/default/unit_04_mage.tres",
		"res://data/roster/default/unit_05_cleric.tres",
		"res://data/roster/default/unit_06_knight.tres",
	]
	for path in roster_files:
		var u = load(path)
		if u and u is UnitData and u.unit_name != "":
			print("OK  roster: " + u.unit_name + " (" + u.class_id + ")")
			passed += 1
		else:
			print("FAIL roster: " + path)
			failed += 1

	# --- Map data ---
	var md = load("res://data/maps/map_001_rout/map_001_data.tres")
	if md and md is MapData and md.id == "map_001":
		print("OK  map_data: map_001 (%d enemies)" % md.enemy_placements.size())
		passed += 1
	else:
		print("FAIL map_data: map_001_data.tres")
		failed += 1

	# --- M16 stage 1: per-group condition fields exist + default empty ---
	# Existing .tres files must load with both dicts empty (legacy fields still
	# drive the evaluator). Stage 2 adds the evaluator changes; stage 1 just
	# pins the schema.
	if md and md.victory_conditions is Dictionary and md.victory_conditions.is_empty():
		print("OK  map_data: victory_conditions defaults empty"); passed += 1
	else:
		print("FAIL map_data: victory_conditions missing or non-empty by default"); failed += 1
	if md and md.defeat_conditions is Dictionary and md.defeat_conditions.is_empty():
		print("OK  map_data: defeat_conditions defaults empty"); passed += 1
	else:
		print("FAIL map_data: defeat_conditions missing or non-empty by default"); failed += 1

	# --- M16 stage 1: ObjectiveCondition resource constructs with defaults ---
	var oc := ObjectiveCondition.new()
	if oc is ObjectiveCondition and oc.type == "rout" and oc.faction_id == "" \
			and oc.unit_ids.is_empty() and oc.tiles.is_empty() \
			and oc.allowed_unit_ids.is_empty() and oc.turns == 0:
		print("OK  ObjectiveCondition: defaults (type=rout, all params empty/0)"); passed += 1
	else:
		print("FAIL ObjectiveCondition defaults — got type=%s, faction_id=%s" % [oc.type, oc.faction_id]); failed += 1

	# --- M16 stage 4: get_display_text() one-liners per type ---
	var dt_rout_all := ObjectiveCondition.new()
	dt_rout_all.type = "rout"
	var dt_rout_named := ObjectiveCondition.new()
	dt_rout_named.type = "rout"; dt_rout_named.faction_id = "red"
	var dt_boss := ObjectiveCondition.new()
	dt_boss.type = "defeat_boss"; dt_boss.unit_ids = ["e8"] as Array[String]
	var dt_esc := ObjectiveCondition.new()
	dt_esc.type = "escape"; dt_esc.unit_ids = ["lord"] as Array[String]
	var dt_surv := ObjectiveCondition.new()
	dt_surv.type = "survive"; dt_surv.turns = 5
	if dt_rout_all.get_display_text() == "Rout all hostiles" \
			and dt_rout_named.get_display_text() == "Rout red" \
			and dt_boss.get_display_text() == "Defeat e8" \
			and dt_esc.get_display_text() == "Escape: lord" \
			and dt_surv.get_display_text() == "Survive 5 turn(s)":
		print("OK  ObjectiveCondition.get_display_text: per-type one-liners"); passed += 1
	else:
		print("FAIL display_text: rout_all=%s rout_red=%s boss=%s esc=%s surv=%s" % [
			dt_rout_all.get_display_text(), dt_rout_named.get_display_text(),
			dt_boss.get_display_text(), dt_esc.get_display_text(),
			dt_surv.get_display_text()]); failed += 1

	# --- Roster unit_id non-empty ---
	for path in roster_files:
		var u = load(path)
		if u and u is UnitData and u.unit_id != "":
			print("OK  unit_id: " + u.unit_id)
			passed += 1
		else:
			print("FAIL unit_id empty in: " + path)
			failed += 1

	# --- Snapshot coverage: every mutable UnitData property must appear in the
	# snapshot dict or in the explicit allowlist of intentionally-excluded fields.
	# Fail if a new @export var is added to UnitData without updating the snapshot.
	var snapshot_keys := [
		"tile_position", "hp", "max_hp", "strength", "magic", "defense",
		"resistance", "skill", "speed", "luck", "exp", "level", "effective_level",
		"proficiencies", "inventory", "conditions", "skills", "mastery_skills",
		"is_incapacitated", "active_modifiers", "skill_use_counters",
		"damage_taken_this_map", "growth_accumulators", "shift_gauge", "is_shifted",
	]
	# Properties intentionally excluded: static identity or between-map state only.
	var snapshot_allowlist := [
		"unit_id", "unit_name", "class_id", "is_promoted", "movement",
		"constitution", "line_of_sight", "gold", "ai_profile", "is_default_roster",
		"shift_profile_id",
	]
	var sample_unit: UnitData = UnitData.new()
	var snapshot_fail := false
	for prop_dict in sample_unit.get_property_list():
		var pname: String = prop_dict["name"]
		var usage: int = prop_dict["usage"]
		# Only check script-level properties (skips built-in Resource fields).
		if not (usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		if pname in snapshot_keys or pname in snapshot_allowlist:
			continue
		print("FAIL snapshot_coverage: UnitData.%s not in snapshot or allowlist" % pname)
		snapshot_fail = true
	if snapshot_fail:
		failed += 1
	else:
		print("OK  snapshot_coverage: all UnitData properties accounted for")
		passed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
