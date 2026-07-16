extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_more_info_content.gd
# Verifies the shared MoreInfoContent description source: known keys return
# their authored text, unknown keys fall through to a fallback rather than
# crashing, and category routing covers the surfaces Phase 1 exposes
# (character sheet, combat preview, terrain HUD).

const MoreInfoContent = preload("res://scripts/shared/MoreInfoContent.gd")


func _init() -> void:
	print("=== MoreInfoContent Test ===")
	var passed := 0
	var failed := 0

	# ---- known stat lookup ----------------------------------------------
	var str_text := MoreInfoContent.describe("stat", "strength")
	if "Physical" in str_text and str_text != MoreInfoContent.FALLBACK_TEXT:
		print("OK  describe(stat, strength) returns authored description")
		passed += 1
	else:
		print("FAIL stat lookup: %s" % str_text)
		failed += 1

	if (
		MoreInfoContent.has_description("stat", "strength")
		and not MoreInfoContent.has_description("stat", "made_up_stat")
	):
		print("OK  has_description distinguishes authored vs missing entries")
		passed += 1
	else:
		print("FAIL has_description")
		failed += 1

	# ---- unknown key in known category -> fallback ----------------------
	var unknown := MoreInfoContent.describe("stat", "made_up_stat")
	if unknown == MoreInfoContent.FALLBACK_TEXT:
		print("OK  unknown key falls back to placeholder text")
		passed += 1
	else:
		print("FAIL fallback for unknown key: %s" % unknown)
		failed += 1

	# ---- generic-bucket categories: any key returns the generic text ----
	# Inventory uses keyed entries ("weapon", "item"); wexp uses a generic
	# fallback so every weapon-rank row gets the same description without an
	# entry per track. Phase 1 doesn't need per-track copy yet.
	var any_wexp := MoreInfoContent.describe("wexp", "lance")
	if "Weapon experience" in any_wexp:
		print("OK  wexp generic fallback applies to any track id")
		passed += 1
	else:
		print("FAIL wexp generic: %s" % any_wexp)
		failed += 1

	# ---- unknown category -> fallback (no crash) ------------------------
	var bad_category := MoreInfoContent.describe("not_a_category", "whatever")
	if bad_category == MoreInfoContent.FALLBACK_TEXT:
		print("OK  unknown category returns fallback, never crashes")
		passed += 1
	else:
		print("FAIL unknown category: %s" % bad_category)
		failed += 1

	# ---- coverage checks for Phase 1 surfaces ---------------------------
	# Keep the smoke check for the broad categories the three Phase 1
	# surfaces touch.
	var required: Array = [
		["stat", "strength"],
		["combat_field", "hit"],
		["combat_field", "triangle"],
		["combat_field", "effectiveness"],
		["terrain", "forest"],
		["tile_action", "seize"],
		["inventory", "weapon"],
	]
	var coverage_ok := true
	for pair in required:
		if not MoreInfoContent.has_description(pair[0], pair[1]):
			coverage_ok = false
			print("FAIL coverage missing: %s/%s" % [pair[0], pair[1]])
			failed += 1
	if coverage_ok:
		print("OK  Phase 1 surfaces all have at least one authored entry")
		passed += 1

	# Terrain HUD should have authored copy for every terrain id currently
	# surfaced by GridManager, so normal play never falls through to the
	# placeholder text on common tiles.
	var terrain_ids: Array[String] = [
		"plain",
		"forest",
		"mountain",
		"fort",
		"sea",
		"desert",
		"wall",
	]
	var terrain_ok := true
	for terrain_id in terrain_ids:
		if not MoreInfoContent.has_description("terrain", terrain_id):
			terrain_ok = false
			print("FAIL terrain coverage missing: %s" % terrain_id)
			failed += 1
	if terrain_ok:
		print("OK  terrain descriptions cover every GridManager terrain id")
		passed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
