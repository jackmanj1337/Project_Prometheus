extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_pair_up_bonus_e2e.gd
#
# End-to-end regression for playtest v0.1.5.0 #8.5 ("Pairup did not grant any
# bonuses, and no pairup line showed in lead unit character sheet").
#
# The existing pair-up tests use stub units and synthetic UnitData. This suite
# closes that gap by exercising the FULL live chain with the REAL Map 950 roster:
#
#   real .tres roster -> real Unit nodes -> GameState autoload (register +
#   find_unit_by_id) -> PairUpRegistry autoload (pair) -> PairUpBonusResolver
#   autoload -> HUD._show_unit() -> the "Paired …" panel line.
#
# 8.5 pairs M950_Hero_SkillCap (lead) with M950_Cavalier (support); the handbook
# authors the expected support contribution from the real cavalier stats, so the
# numbers below are the handbook's, asserted against the live pipeline. Heeds the
# 2026-06-14 lesson: assert the failing scenario with a test before calling the
# pipeline correct.

const UnitScene = preload("res://scenes/units/Unit.tscn")
const CAVALIER_PATH := "res://data/roster/test/map_950_promotion_validation/unit_01_cavalier.tres"
const HERO_PATH := "res://data/roster/test/map_950_promotion_validation/unit_12_hero_skill_cap.tres"

# Handbook 8.5 expected support contribution from the authored cavalier stats
# (flat cavalier block + floor(stat / 4) scaling).
const EXPECTED := {
	"strength": 3,   # 1 + floor(10 / 4)
	"defense": 3,    # 1 + floor(10 / 4)
	"speed": 3,      # 1 + floor( 9 / 4)
	"skill": 2,      #     floor( 8 / 4)
	"luck": 1,       #     floor( 4 / 4)
	"magic": 0,      #     floor( 0 / 4)
	"resistance": 0, #     floor( 1 / 4)
}


func _init() -> void:
	print("=== Pair Up Bonus E2E Test (#8.5) ===")
	var passed := 0
	var failed := 0

	# Autoloads attach to root after the first frame in a --script SceneTree run.
	await process_frame
	var gs := root.get_node_or_null("GameState")
	var reg := root.get_node_or_null("PairUpRegistry")
	var res := root.get_node_or_null("PairUpBonusResolver")
	if gs == null or reg == null or res == null:
		print("FAIL autoloads missing: GameState=%s PairUpRegistry=%s PairUpBonusResolver=%s" % [
			gs, reg, res])
		quit(1)
		return

	# Real roster resources — the actual files the build ships and the tester used.
	var hero_data = load(HERO_PATH)
	var cav_data = load(CAVALIER_PATH)
	if hero_data == null or cav_data == null:
		print("FAIL could not load roster: hero=%s cav=%s" % [hero_data, cav_data])
		quit(1)
		return

	# Clean slate, then mimic the live New Game state: Pair Up enabled.
	gs.call("reset_map_state")
	reg.call("clear")
	gs.set("pair_up_enabled", true)

	# Real Unit nodes, duplicated data so the test never mutates the on-disk .tres.
	var hero: Node = UnitScene.instantiate()
	hero.data = hero_data.duplicate(true)
	hero.team = "blue"
	var cav: Node = UnitScene.instantiate()
	cav.data = cav_data.duplicate(true)
	cav.team = "blue"
	root.add_child(hero)
	root.add_child(cav)
	gs.call("register_unit", hero)
	gs.call("register_unit", cav)

	var hero_id: String = hero.data.unit_id
	var cav_id: String = cav.data.unit_id

	# Pair via the registry exactly as the Pair Up action does: initiator = lead.
	var paired: bool = bool(reg.call("pair", hero_id, cav_id))
	if paired and bool(reg.call("is_lead", hero_id)) and bool(reg.call("is_support", cav_id)):
		print("OK  registry pairs hero(lead) + cavalier(support) with Pair Up enabled")
		passed += 1
	else:
		print("FAIL pairing: paired=%s is_lead(hero)=%s is_support(cav)=%s" % [
			paired, reg.call("is_lead", hero_id), reg.call("is_support", cav_id)])
		failed += 1

	# The support sits off-map but must remain resolvable by id (the resolver and
	# the HUD line both depend on this lookup succeeding).
	var found: Node = gs.call("find_unit_by_id", cav_id)
	if found == cav:
		print("OK  GameState.find_unit_by_id resolves the off-map support")
		passed += 1
	else:
		print("FAIL find_unit_by_id(support) = %s, want %s" % [found, cav])
		failed += 1

	# The resolver must return the handbook's non-empty contribution for the real
	# cavalier — the "no bonuses granted" symptom is exactly an empty dict here.
	var bonuses: Dictionary = res.call("bonuses_for", cav)
	var bonus_ok := true
	for stat in EXPECTED.keys():
		if int(bonuses.get(stat, 0)) != int(EXPECTED[stat]):
			bonus_ok = false
	if bonus_ok and not bonuses.is_empty():
		print("OK  resolver returns handbook bonus for the real cavalier: %s" % bonuses)
		passed += 1
	else:
		print("FAIL resolver bonus = %s, want superset of %s" % [bonuses, EXPECTED])
		failed += 1

	# The HUD pair-up line — the second half of the 8.5 report. Loads the real HUD
	# scene and drives the same code path the cursor-hover refresh uses. V021-07: the
	# map HUD names only the support (deltas moved to the `I` sheet, asserted below).
	var packed := load("res://scenes/ui/HUD.tscn")
	if packed != null:
		var hud: Control = packed.instantiate()
		root.add_child(hud)
		await process_frame
		hud._show_unit(hero)
		var pu_label = hud.get_node_or_null("UnitInfoPanel/VBox/PairUpLabel")
		var line_ok: bool = pu_label != null and pu_label.visible \
			and "Support:" in pu_label.text \
			and not ("Paired" in pu_label.text) and not ("+3 Str" in pu_label.text)
		if line_ok:
			print("OK  HUD names the Pair Up support on the paired lead: %s" % pu_label.text)
			passed += 1
		else:
			print("FAIL HUD pair-up line: visible=%s text=%s" % [
				(pu_label.visible if pu_label != null else "<no label>"),
				(pu_label.text if pu_label != null else "<no label>")])
			failed += 1
		hud.queue_free()
	else:
		print("FAIL could not load HUD.tscn")
		failed += 1

	# ── The `I` character sheet now also shows the pair-up contribution ──
	# This is the surface the v0.1.5.0 tester said showed nothing (the line had
	# only ever lived on the HUD panel). The breakdown must list "Pair Up +3" on
	# the lead's Strength and render the effective value green.
	var sheet_packed := load("res://scenes/ui/UnitDetailsScreen.tscn")
	if sheet_packed != null:
		var sheet: Control = sheet_packed.instantiate()
		root.add_child(sheet)
		await process_frame
		sheet.open(hero)
		await process_frame
		sheet._on_entry_clicked("stat:strength")
		var mods_text: String = sheet._info_mods.text
		var sheet_ok: bool = "Pair Up" in mods_text and "+3" in mods_text and "#5fd35f" in mods_text
		if sheet_ok:
			print("OK  I character sheet shows the Pair Up bonus on the lead's Strength (#8.5)")
			passed += 1
		else:
			print("FAIL I-sheet pair-up: %s" % mods_text)
			failed += 1
		sheet.queue_free()
	else:
		print("FAIL could not load UnitDetailsScreen.tscn")
		failed += 1

	# Teardown.
	reg.call("clear")
	gs.call("reset_map_state")
	hero.queue_free()
	cav.queue_free()

	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
