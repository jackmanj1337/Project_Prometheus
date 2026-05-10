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
	for sid in ["renewal", "vantage", "nihil", "resolve", "miracle", "wrath"]:
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

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
