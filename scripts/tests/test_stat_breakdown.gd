extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_stat_breakdown.gd
# Verifies the shared StatBreakdown helper used by the More Info surfaces
# (UnitDetailsScreen, AttackPreview, HUD). The helper must never recompute
# stat math — it only explains the result Unit.get_effective_stat() returns —
# and must produce the locked dict shape from
# AGENT/Docs/more_info_mode_plan_2026-05-24.md.

const StatBreakdown = preload("res://scripts/shared/StatBreakdown.gd")


# Minimal Unit-shaped stub. The helper only reads `data` + uses
# get_effective_stat(), so we don't need the full Unit class for these tests.
class StubUnit extends Node:
	var data = null

	func get_effective_stat(stat_name: String) -> int:
		var base = data.get(stat_name)
		var total: int = int(base) if base != null else 0
		for mod in data.active_modifiers:
			if String(mod.get("stat", "")) == stat_name:
				total += int(mod.get("delta", 0))
		return max(0, total)


func _init() -> void:
	print("=== StatBreakdown Test ===")
	var passed := 0
	var failed := 0

	# ---- label_for_stat: known + fallback ---------------------------------
	if StatBreakdown.label_for_stat("strength") == "Str":
		print("OK  label_for_stat known"); passed += 1
	else:
		print("FAIL label_for_stat known"); failed += 1
	if StatBreakdown.label_for_stat("aura") == "Aura":
		print("OK  label_for_stat fallback capitalises unknown stat"); passed += 1
	else:
		print("FAIL label_for_stat fallback: %s" % StatBreakdown.label_for_stat("aura"))
		failed += 1

	# ---- label_for_source: known + raw-id fallback ------------------------
	if StatBreakdown.label_for_source("tonic") == "Tonic" \
			and StatBreakdown.label_for_source("mystery_skill") == "mystery_skill":
		print("OK  label_for_source known + fallback to raw id"); passed += 1
	else:
		print("FAIL label_for_source"); failed += 1

	# ---- format_signed always includes sign -------------------------------
	if StatBreakdown.format_signed(2) == "+2" and StatBreakdown.format_signed(-1) == "-1" \
			and StatBreakdown.format_signed(0) == "+0":
		print("OK  format_signed always includes sign"); passed += 1
	else:
		print("FAIL format_signed"); failed += 1

	# ---- format_duration: turn / map_turn / combat / permanent ------------
	var durations_ok: bool = (
		StatBreakdown.format_duration("turn", 1) == "1 turn"
		and StatBreakdown.format_duration("turn", 3) == "3 turns"
		and StatBreakdown.format_duration("map_turn", 2) == "2 rounds"
		and StatBreakdown.format_duration("combat", 0) == "this combat"
		# V020-08: Pair Up carries the -1 sentinel with a "combat" type; it must
		# render as "this combat", not be swallowed by the negative-remaining "—".
		and StatBreakdown.format_duration("combat", -1) == "this combat"
		and StatBreakdown.format_duration("permanent", -1) == "—"
		and StatBreakdown.format_duration("turn", -1) == "—"
	)
	if durations_ok:
		print("OK  format_duration covers turn/map_turn/combat/permanent"); passed += 1
	else:
		print("FAIL format_duration"); failed += 1

	# ---- null unit returns a safe empty shape -----------------------------
	var empty: Dictionary = StatBreakdown.build(null, "strength")
	if empty["stat"] == "strength" and empty["label"] == "Str" \
			and empty["base"] == 0 and empty["effective"] == 0 \
			and empty["total_delta"] == 0 and empty["mods"] == []:
		print("OK  build(null) returns safe empty shape"); passed += 1
	else:
		print("FAIL build(null): %s" % empty); failed += 1

	# ---- build: stat with no active modifiers -----------------------------
	var d := UnitData.new()
	d.strength = 9
	d.movement = 6
	d.active_modifiers = []
	var unit_a := StubUnit.new()
	unit_a.data = d
	root.add_child(unit_a)

	var no_mods: Dictionary = StatBreakdown.build(unit_a, "strength")
	if no_mods["base"] == 9 and no_mods["effective"] == 9 \
			and no_mods["total_delta"] == 0 and (no_mods["mods"] as Array).is_empty():
		print("OK  build returns base==effective with no mods"); passed += 1
	else:
		print("FAIL build no-mods: %s" % no_mods); failed += 1

	# ---- build: single modifier, friendly label + duration ----------------
	d.active_modifiers = [
		{"stat": "strength", "delta": 2, "source": "tonic",
			"duration": 1, "duration_type": "turn"},
		# Different stat — must not appear in a strength breakdown.
		{"stat": "movement", "delta": 1, "source": "pair_up",
			"duration": -1, "duration_type": "combat"},
	]
	var str_bd: Dictionary = StatBreakdown.build(unit_a, "strength")
	var mods: Array = str_bd["mods"]
	var single_ok: bool = (
		str_bd["base"] == 9 and str_bd["effective"] == 11
		and str_bd["total_delta"] == 2
		and mods.size() == 1
		and (mods[0] as Dictionary)["source_id"] == "tonic"
		and (mods[0] as Dictionary)["source_label"] == "Tonic"
		and (mods[0] as Dictionary)["delta"] == 2
		and (mods[0] as Dictionary)["duration_type"] == "turn"
		and (mods[0] as Dictionary)["remaining"] == 1
	)
	if single_ok:
		print("OK  build filters by stat, includes friendly source + duration"); passed += 1
	else:
		print("FAIL build single-mod: %s" % str_bd); failed += 1

	# ---- build: duplicate same-source rows are grouped --------------------
	# add_modifier() de-duplicates, but other paths may not. The helper must
	# render one row per source so the panel never shows "Tonic +2, Tonic +2".
	d.active_modifiers = [
		{"stat": "strength", "delta": 2, "source": "tonic",
			"duration": 1, "duration_type": "turn"},
		{"stat": "strength", "delta": 2, "source": "tonic",
			"duration": 3, "duration_type": "turn"},
	]
	var grouped: Dictionary = StatBreakdown.build(unit_a, "strength")
	var grouped_mods: Array = grouped["mods"]
	var grouped_ok: bool = (
		grouped_mods.size() == 1
		and (grouped_mods[0] as Dictionary)["delta"] == 4
		and (grouped_mods[0] as Dictionary)["remaining"] == 3
	)
	if grouped_ok:
		print("OK  duplicate same-source rows are summed and keep longest duration")
		passed += 1
	else:
		print("FAIL grouping: %s" % grouped); failed += 1

	# ---- build: unknown source falls back to raw id, not a crash ----------
	d.active_modifiers = [
		{"stat": "strength", "delta": -1, "source": "mystery_skill",
			"duration": -1, "duration_type": "permanent"},
	]
	var unknown: Dictionary = StatBreakdown.build(unit_a, "strength")
	var unknown_mods: Array = unknown["mods"]
	if not unknown_mods.is_empty() \
			and (unknown_mods[0] as Dictionary)["source_label"] == "mystery_skill":
		print("OK  unknown source label falls back to raw id"); passed += 1
	else:
		print("FAIL unknown-source fallback: %s" % unknown); failed += 1

	# ---- helper never goes below zero (mirrors get_effective_stat clamp) --
	d.strength = 1
	d.active_modifiers = [
		{"stat": "strength", "delta": -5, "source": "poison",
			"duration": -1, "duration_type": "permanent"},
	]
	var clamped: Dictionary = StatBreakdown.build(unit_a, "strength")
	if clamped["base"] == 1 and clamped["effective"] == 0 and clamped["total_delta"] == -5:
		print("OK  effective clamps to 0 while total_delta reports the raw sum")
		passed += 1
	else:
		print("FAIL clamp: %s" % clamped); failed += 1

	# ---- class decomposition + caps (class_data supplied) -----------------
	var ClassDataS = load("res://scripts/resources/ClassData.gd")
	var cls = ClassDataS.new()
	cls.display_name = "Cavalier"
	cls.base_strength = 6
	cls.stat_caps = {"strength": 26}  # capped stat
	# (movement deliberately uncapped — not in STAT_KEYS)
	d.strength = 10
	d.movement = 6
	d.active_modifiers = []
	var deco: Dictionary = StatBreakdown.build(unit_a, "strength", cls)
	var deco_ok: bool = (
		deco["base"] == 10
		and deco["personal_base"] == 4      # 10 - class base 6
		and deco["class_base"] == 6
		and deco["cap"] == 26
		and deco["cap_state"] == "capped"
	)
	if deco_ok:
		print("OK  build decomposes base into personal + class and reads the cap"); passed += 1
	else:
		print("FAIL decomposition: %s" % deco); failed += 1

	# movement is outside STAT_KEYS -> intentionally uncapped
	var uncapped: Dictionary = StatBreakdown.build(unit_a, "movement", cls)
	if uncapped["cap_state"] == "uncapped":
		print("OK  stats outside STAT_KEYS report cap_state 'uncapped'"); passed += 1
	else:
		print("FAIL uncapped: %s" % uncapped); failed += 1

	# a capped stat with no cap key authored -> loud 'missing'
	var cls_nocap = ClassDataS.new()
	cls_nocap.base_strength = 5
	cls_nocap.stat_caps = {}  # strength is in STAT_KEYS but has no entry
	var missing: Dictionary = StatBreakdown.build(unit_a, "strength", cls_nocap)
	if missing["cap_state"] == "missing" and missing["cap"] == StatBreakdown.CAP_MISSING:
		print("OK  capped stat with no cap entry reports cap_state 'missing'"); passed += 1
	else:
		print("FAIL missing-cap: %s" % missing); failed += 1

	# no class_data -> 'unknown', personal_base falls back to base
	var unknown_cap: Dictionary = StatBreakdown.build(unit_a, "strength")
	if unknown_cap["cap_state"] == "unknown" and unknown_cap["personal_base"] == int(d.strength):
		print("OK  no class_data reports cap_state 'unknown'"); passed += 1
	else:
		print("FAIL unknown-cap: %s" % unknown_cap); failed += 1

	# ---- authored unit whose stored stat is below class base --------------
	# personal_base must clamp at 0 rather than show a negative value.
	d.strength = 4
	var below = StatBreakdown.build(unit_a, "strength", cls)  # class base 6 > 4
	if below["personal_base"] == 0 and below["class_base"] == 6:
		print("OK  personal_base clamps at 0 when stored stat is below class base"); passed += 1
	else:
		print("FAIL personal clamp: %s" % below); failed += 1

	# ---- extra_mods merge + effective_display -----------------------------
	# Combat-only rows the caller injects are merged into mods and added into
	# effective_display (but not into the live `effective`).
	d.strength = 10
	d.active_modifiers = [
		{"stat": "strength", "delta": 2, "source": "tonic",
			"duration": 1, "duration_type": "turn"},
	]
	var extra: Array = [
		{"source_id": "pair_up", "source_label": "Pair Up", "delta": 3,
			"duration_type": "combat", "remaining": -1},
	]
	var merged: Dictionary = StatBreakdown.build(unit_a, "strength", cls, extra)
	var merged_ok: bool = (
		merged["effective"] == 12            # base 10 + tonic 2 (live engine value)
		and merged["effective_display"] == 15  # + pair-up 3 (display)
		and (merged["mods"] as Array).size() == 2
		and StatBreakdown.label_for_source("pair_up:m1:strength") == "Pair Up"  # prefix label
	)
	if merged_ok:
		print("OK  extra_mods merge into mods and raise effective_display only"); passed += 1
	else:
		print("FAIL extra_mods merge: %s" % merged); failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
