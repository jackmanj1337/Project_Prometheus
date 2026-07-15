extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_class_stat_caps.gd
#
# Data-integrity guard (DoD#2 for the character-sheet stat breakdown): every
# PLAYABLE class must author a stat_caps entry for each STAT_KEYS stat. The
# UnitDetailsScreen shows a loud NO_CAP_DEFINED when a capped stat has no entry;
# this test makes that placeholder a genuine-regression signal rather than a
# routine state, by failing the suite if any playable class is missing a cap.

const ClassData = preload("res://scripts/resources/ClassData.gd")
const CLASS_DIR := "res://data/classes/"

# Intentional cap-less placeholder classes: these legitimately have no corpus
# cap data yet, so the character sheet shows NO_CAP_DEFINED for them BY DESIGN
# (playtest v0.1.6.0 stat-breakdown work). Every OTHER playable class must author
# complete caps — that is what this test guards. Remove an entry here once its
# class gets real caps so the guard starts enforcing it.
const KNOWN_CAPLESS := ["soldier"]


func _init() -> void:
	print("=== Class Stat Caps Test ===")
	var passed := 0
	var failed := 0

	var dir := DirAccess.open(CLASS_DIR)
	if dir == null:
		print("FAIL could not open %s" % CLASS_DIR)
		quit(1)
		return

	var checked := 0
	for file_name in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var cls = load(CLASS_DIR + file_name)
		if cls == null:
			print("FAIL could not load %s" % file_name)
			failed += 1
			continue
		# Only playable classes are exercised by the character sheet; non-playable
		# (enemy-only) classes are out of scope for this invariant.
		if String(cls.get("class_availability")) != "playable":
			continue
		var class_id := String(cls.get("id"))
		if class_id in KNOWN_CAPLESS:
			print(
				(
					"note  '%s' is an intentional cap-less placeholder (shows NO_CAP_DEFINED by design)"
					% class_id
				)
			)
			continue
		checked += 1
		var caps: Dictionary = cls.get("stat_caps")
		var missing: Array[String] = []
		for stat in ClassData.STAT_KEYS:
			if caps == null or not caps.has(stat) or int(caps.get(stat, 0)) <= 0:
				missing.append(stat)
		if missing.is_empty():
			passed += 1
		else:
			print(
				(
					"FAIL class '%s' (%s) missing/zero stat_caps: %s"
					% [class_id, file_name, ", ".join(missing)]
				)
			)
			failed += 1

	if checked == 0:
		print("FAIL no playable classes found to check")
		failed += 1
	else:
		print("OK  checked %d playable classes for complete STAT_KEYS caps" % checked)
		passed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
