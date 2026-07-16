extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_stat_registry.gd
# Tests the StatRegistry vocabulary — the non-schema slice of the author-extensible
# stat model [STM]. This is the single stat-id/label vocabulary that replaced the
# ~5 hardcoded copies (ClassData.STAT_KEYS, Unit._GROWTH_STATS, DataManager
# _VALID_STATS, LevelUpScreen._STAT_NAMES, StatBreakdown.STAT_LABELS).

const StatRegistry = preload("res://scripts/core/StatRegistry.gd")
const StatBreakdown = preload("res://scripts/shared/StatBreakdown.gd")


func _init() -> void:
	print("=== StatRegistry Test ===")
	var passed := 0
	var failed := 0

	# ---- GROWTH_STAT_IDS: exact set + ORDER (RNG determinism depends on order:
	# growth_random draws one roll per stat in this order — test_unit_stats §5) ----
	var expected_growth: Array[String] = [
		"hp", "strength", "magic", "defense", "resistance", "skill", "speed", "luck"
	]
	if StatRegistry.GROWTH_STAT_IDS == expected_growth:
		print("OK  GROWTH_STAT_IDS = canonical 8 stats in growth-roll order")
		passed += 1
	else:
		print("FAIL GROWTH_STAT_IDS = %s" % str(StatRegistry.GROWTH_STAT_IDS))
		failed += 1

	# ---- is_growth_stat: growth stats accepted; non-growth (display-only) and
	# unknown rejected — matches the old DataManager._VALID_STATS membership ----
	if StatRegistry.is_growth_stat("luck") and StatRegistry.is_growth_stat("hp"):
		print("OK  is_growth_stat accepts growth stats")
		passed += 1
	else:
		print("FAIL is_growth_stat rejected a growth stat")
		failed += 1

	if not StatRegistry.is_growth_stat("movement") and not StatRegistry.is_growth_stat("charisma"):
		print("OK  is_growth_stat rejects display-only + unknown stats")
		passed += 1
	else:
		print("FAIL is_growth_stat accepted a non-growth stat")
		failed += 1

	# ---- label_for: canonical labels, incl. Luck reconciled to "Lck" ----
	if (
		StatRegistry.label_for("luck") == "Lck"
		and StatRegistry.label_for("hp") == "HP"
		and StatRegistry.label_for("line_of_sight") == "LoS"
	):
		print("OK  label_for returns canonical labels (Luck -> 'Lck')")
		passed += 1
	else:
		print("FAIL label_for label mismatch (luck=%s)" % StatRegistry.label_for("luck"))
		failed += 1

	# ---- label_for: unknown stat falls back to capitalised id (never crashes UI) ----
	if StatRegistry.label_for("charisma") == "Charisma":
		print("OK  label_for falls back to capitalised id for unknown stat")
		passed += 1
	else:
		print("FAIL label_for fallback = %s" % StatRegistry.label_for("charisma"))
		failed += 1

	# ---- STAT_LABELS covers every display stat id (no known stat renders via the
	# capitalise fallback — consistency lock between the id lists and the labels) ----
	var missing_label: Array[String] = []
	for id in StatRegistry.display_stat_ids():
		if not StatRegistry.STAT_LABELS.has(id):
			missing_label.append(id)
	if missing_label.is_empty():
		print("OK  every display stat id has an explicit label")
		passed += 1
	else:
		print("FAIL display stat ids missing a label: %s" % str(missing_label))
		failed += 1

	# ---- display_stat_ids: growth stats then display-only, no duplicates ----
	var display: Array[String] = StatRegistry.display_stat_ids()
	var expected_display_size: int = (
		StatRegistry.GROWTH_STAT_IDS.size() + StatRegistry.DISPLAY_ONLY_STAT_IDS.size()
	)
	if (
		display.size() == expected_display_size
		and display[0] == "hp"
		and display[display.size() - 1] == "line_of_sight"
	):
		print("OK  display_stat_ids = growth + display-only in sheet order")
		passed += 1
	else:
		print("FAIL display_stat_ids = %s" % str(display))
		failed += 1

	# ---- Wiring proof: the former hardcoded copies now resolve to the registry ----
	if ClassData.STAT_KEYS == StatRegistry.GROWTH_STAT_IDS:
		print("OK  ClassData.STAT_KEYS sources StatRegistry.GROWTH_STAT_IDS")
		passed += 1
	else:
		print("FAIL ClassData.STAT_KEYS not wired to StatRegistry")
		failed += 1

	# ---- StatBreakdown.label_for_stat delegates to the registry (Luck now 'Lck') ----
	if StatBreakdown.label_for_stat("luck") == "Lck":
		print("OK  StatBreakdown.label_for_stat delegates to StatRegistry")
		passed += 1
	else:
		print("FAIL StatBreakdown.label_for_stat = %s" % StatBreakdown.label_for_stat("luck"))
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
