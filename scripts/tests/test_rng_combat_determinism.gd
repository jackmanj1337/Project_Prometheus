extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_rng_combat_determinism.gd
# Combat-level RNG determinism (B1-PKGA Slice 1b). Covers the design test
# matrix's T1 (replay determinism), T3 (butterfly + isolation), and T7 (roll-
# order freeze per built-in hit resolver) from
# [GDD-01-RUNTIME-CONTRACTS] §10, plus the
# apply-commits-exactly-once guard and the CampaignRules.hit_formula selection.
#
# Fixture stats are tuned to a 50% hit / 50% crit fight so fixed-seed sequences
# contain a mix of hits, misses, and crits — an all-hit fixture would make the
# T1/T3 log comparisons vacuous.

const CombatRes = preload("res://scripts/core/CombatResolver.gd")
const RngServiceS = preload("res://scripts/autoloads/RngService.gd")
const WeaponDataS = preload("res://scripts/resources/WeaponData.gd")
const UnitDataS = preload("res://scripts/resources/UnitData.gd")
const CampaignRulesS = preload("res://scripts/resources/CampaignRules.gd")

const FIXED_SEED := 424242
const UNIT_HP := 30


# Minimal combat-capable mock (trimmed from test_combat.gd's MockUnit): stat
# reads route through get_effective_stat like production Unit.gd. No inventory
# entry — weapons read as infinite durability, which these tests don't exercise.
class MockUnit:
	extends Node
	var data: Resource
	var tile_position: Vector2i = Vector2i.ZERO
	var team: String = "blue"
	var _weapon: Resource = null

	func get_equipped_weapon() -> Resource:
		return _weapon

	func has_quality(_q: String) -> bool:
		return false

	func has_vulnerability(_g: String) -> bool:
		return false

	func has_skill(_s: String) -> bool:
		return false

	func battle_speed(_w: Resource = null, sink: RefCounted = null) -> int:
		var w: Resource = _w if _w else _weapon
		if w == null:
			return get_effective_stat("speed", sink)
		return (
			get_effective_stat("speed", sink)
			- maxi(0, w.get("wt") - get_effective_stat("strength", sink))
		)

	func accuracy(_w: Resource = null, sink: RefCounted = null) -> int:
		var w: Resource = _w if _w else _weapon
		var acc: int = get_effective_stat("skill", sink) * 2 + get_effective_stat("luck", sink)
		if w:
			acc += w.get("hit")
		return acc

	func dodge(_w: Resource = null, sink: RefCounted = null) -> int:
		return battle_speed(_w, sink) * 2 + get_effective_stat("luck", sink)

	func crit_rate(_w: Resource = null, sink: RefCounted = null) -> int:
		var w: Resource = _w if _w else _weapon
		return get_effective_stat("skill", sink) / 2 + (w.get("crit") if w else 0)

	func crit_avoid(sink: RefCounted = null) -> int:
		return get_effective_stat("luck", sink)

	func get_terrain_def_bonus() -> int:
		return 0

	func get_terrain_dodge_bonus() -> int:
		return 0

	func effective_modifiers(sink: RefCounted = null) -> Array:
		if sink != null and sink.has_method("effective_modifiers"):
			return sink.effective_modifiers(self)
		return data.active_modifiers

	func get_effective_stat(stat_name: String, sink: RefCounted = null) -> int:
		var base = data.get(stat_name)
		var total: int = int(base) if base != null else 0
		for mod in effective_modifiers(sink):
			if mod.get("stat", "") == stat_name:
				total += mod.get("delta", 0)
		return max(0, total)

	func take_damage(amount: int) -> void:
		data.hp = max(0, data.hp - amount)

	func add_wexp(_type: String, _amount: int) -> bool:
		return false

	func clear_combat_modifiers() -> void:
		pass

	func handle_death() -> void:
		pass


var _svc: Node
var _cr: Node


func _mk_unit(unit_id: String, tile: Vector2i, with_weapon: bool) -> MockUnit:
	var d := UnitDataS.new()
	d.unit_id = unit_id
	d.hp = UNIT_HP
	d.max_hp = UNIT_HP
	d.skill = 5  # accuracy 10 (+60 weapon hit = 70); crit_rate 2 (+48 = 50)
	d.luck = 0
	d.speed = 10  # dodge 20 -> hit_pct 50; equal speed -> no follow-up
	d.strength = 10
	d.defense = 5  # damage: 10 str + 0 mt - 5 def = 5 (15 on crit; never lethal)
	var u := MockUnit.new()
	u.data = d
	u.tile_position = tile
	if with_weapon:
		var w := WeaponDataS.new()
		w.id = "det_sword"
		w.combat_family = "sword"
		w.wexp_track = "sword"
		w.mt = 0
		w.hit = 60
		w.crit = 48
		w.wt = 1
		w.uses = 45
		w.range_min_formula = "1"
		w.range_max_formula = "1"
		u._weapon = w
	return u


# Resolve + apply one full attack and return its outcome log; HP is reset after
# so every scripted attack starts from an identical board state.
func _attack(a: MockUnit, d: MockUnit) -> Array:
	var rec: Array[String] = _cr.make_attack_event_record(a, d, a.tile_position)
	var result: Dictionary = _cr.resolve_combat(a, d, rec)
	_cr.apply_combat_result(result, a, d)
	var outcome: Array = []
	for ex in result["exchanges"]:
		outcome.append([ex["hit"], ex["crit"], ex["damage"]])
	a.data.hp = UNIT_HP
	d.data.hp = UNIT_HP
	return outcome


# An 8-attack scripted sequence — each attack is a single ~1.5-bit outcome
# (miss / hit / crit), so 8 of them give two different dice timelines ~1/4000
# odds of colliding on the full log; the fixed seed makes the result stable
# once authored.
func _attack_sequence(a: MockUnit, d: MockUnit, n: int = 8) -> Array:
	var log: Array = []
	for _i in n:
		log.append(_attack(a, d))
	return log


func _init() -> void:
	print("=== Combat RNG Determinism Test (T1/T3/T7) ===")
	var passed := 0
	var failed := 0

	_svc = RngServiceS.new()
	_svc.name = "RngService"
	root.add_child(_svc)
	_cr = CombatRes.new()
	_cr.name = "CombatResolver"
	root.add_child(_cr)
	# GameState stub: campaign_rules is wired later in the suite to exercise the
	# hit_formula selection; the other fields satisfy _build_combat_context.
	var gs_script := GDScript.new()
	gs_script.source_code = "extends Node\nvar campaign_rules = null\nvar turn_number: int = 1\nvar all_units: Array = []\nvar debug_force_levelup: bool = false\n"
	gs_script.reload()
	var gs: Node = gs_script.new()
	gs.name = "GameState"
	root.add_child(gs)
	# Absolute-path autoload lookups (get_node_or_null("/root/...")) only work
	# once the tree is active — wait a frame like the other combat suites.
	await process_frame

	var a := _mk_unit("a1", Vector2i(1, 1), true)
	var d := _mk_unit("d1", Vector2i(2, 1), false)  # unarmed: no counter
	var c := _mk_unit("c1", Vector2i(5, 5), true)
	var d2 := _mk_unit("d2", Vector2i(5, 6), false)

	# ---- sanity: the fixture really is a 50/50 fight ----
	var hit_pct: int = _cr.compute_hit_pct(a, d, a._weapon)
	var crit_pct: int = _cr.compute_crit_pct(a, d, a._weapon)
	if hit_pct == 50 and crit_pct == 50:
		print("OK  fixture: hit_pct=50 crit_pct=50")
		passed += 1
	else:
		print("FAIL fixture: hit=%d crit=%d (want 50/50)" % [hit_pct, crit_pct])
		failed += 1

	# ---- T1: replay determinism for a scripted attack sequence ----
	_svc.start_map(FIXED_SEED)
	var log1: Array = _attack_sequence(a, d)
	_svc.start_map(FIXED_SEED)
	var log2: Array = _attack_sequence(a, d)
	var has_hit := false
	var has_miss := false
	for atk in log1:
		for ex in atk:
			if ex[0]:
				has_hit = true
			else:
				has_miss = true
	if log1 == log2 and has_hit and has_miss:
		print("OK  T1 replay determinism (log has hits AND misses): %s" % str(log1))
		passed += 1
	else:
		print("FAIL T1: %s vs %s (hit=%s miss=%s)" % [str(log1), str(log2), has_hit, has_miss])
		failed += 1

	# ---- T3: butterfly + isolation ----
	_svc.start_map(FIXED_SEED)
	var checkpoint: Dictionary = _svc.to_save_dict()
	var branch_a: Array = _attack_sequence(a, d)

	# (a) repeated twice is identical to itself
	_svc.from_save_dict(checkpoint)
	var branch_a2: Array = _attack_sequence(a, d)
	if branch_a == branch_a2:
		print("OK  T3a probing repeat: identical branch replays identically")
		passed += 1
	else:
		print("FAIL T3a: %s vs %s" % [str(branch_a), str(branch_a2)])
		failed += 1

	# (b) a committed Wait by another unit changes A->B's dice
	_svc.from_save_dict(checkpoint)
	_svc.commit_event("wait", ["c1", "5,5", "5,5"] as Array[String])
	var branch_b: Array = _attack_sequence(a, d)
	if branch_b != branch_a:
		print("OK  T3b butterfly: a committed Wait changes later combat dice")
		passed += 1
	else:
		print("FAIL T3b: identical outcomes despite a committed Wait")
		failed += 1

	# (c) C->D first: C->D's dice differ from A->B's (no roll transfer), and the
	# A->B that follows differs from branch (a)'s (chain advanced by C->D).
	_svc.from_save_dict(checkpoint)
	var branch_cd: Array = _attack_sequence(c, d2)
	var branch_ab_after: Array = _attack_sequence(a, d)
	if branch_cd != branch_a and branch_ab_after != branch_a:
		print("OK  T3c isolation: C->D never inherits A->B's numbers")
		passed += 1
	else:
		print(
			(
				"FAIL T3c: cd=%s ab_after=%s a=%s"
				% [str(branch_cd), str(branch_ab_after), str(branch_a)]
			)
		)
		failed += 1

	# ---- apply_combat_result commits the event exactly once ----
	_svc.start_map(FIXED_SEED)
	var hash_before: int = _svc.history_hash
	var rec: Array[String] = _cr.make_attack_event_record(a, d, a.tile_position)
	var result: Dictionary = _cr.resolve_combat(a, d, rec)
	if _svc.history_hash == hash_before:
		print("OK  resolve_combat draws but does not advance the chain")
		passed += 1
	else:
		print("FAIL resolve_combat advanced history_hash")
		failed += 1
	_cr.apply_combat_result(result, a, d)
	var hash_after: int = _svc.history_hash
	a.data.hp = UNIT_HP
	d.data.hp = UNIT_HP
	_cr.apply_combat_result(result, a, d)  # double apply must not re-commit
	if hash_after != hash_before and _svc.history_hash == hash_after:
		print("OK  apply_combat_result commits exactly once (double apply guarded)")
		passed += 1
	else:
		print(
			(
				"FAIL commit-once: before=%d after=%d now=%d"
				% [hash_before, hash_after, _svc.history_hash]
			)
		)
		failed += 1
	a.data.hp = UNIT_HP
	d.data.hp = UNIT_HP

	# ---- T7: literal predicate fixtures for EACH built-in resolver ----
	var two_ok: bool = (
		_cr.did_hit("two_roll", 50, [30, 40] as Array[int])
		and not _cr.did_hit("two_roll", 50, [60, 50] as Array[int])
		and _cr.did_hit("two_roll", 50, [49, 50] as Array[int])
		and not _cr.did_hit("two_roll", 0, [0, 0] as Array[int])
		and _cr.did_hit("two_roll", 100, [99, 99] as Array[int])
		and _cr.hit_rn_count("two_roll") == 2
	)
	if two_ok:
		print("OK  T7 two_roll literals: floor((r1+r2)/2) < hit, rn_count 2")
		passed += 1
	else:
		print("FAIL T7 two_roll literal outcomes")
		failed += 1

	var single_ok: bool = (
		_cr.did_hit("single_roll", 50, [49] as Array[int])
		and not _cr.did_hit("single_roll", 50, [50] as Array[int])
		and not _cr.did_hit("single_roll", 0, [0] as Array[int])
		and _cr.hit_rn_count("single_roll") == 1
	)
	if single_ok:
		print("OK  T7 single_roll literals: rns[0] < hit, rn_count 1")
		passed += 1
	else:
		print("FAIL T7 single_roll literal outcomes")
		failed += 1

	# ---- T7: draw-order freeze through a real combat (two_roll default) ----
	# Replicate the event RNG by hand: two hit RNs, then a crit RN only on a
	# hit. Any change to the draw count or order breaks this by design.
	_svc.start_map(FIXED_SEED)
	var freeze_rec: Array[String] = _cr.make_attack_event_record(a, d, a.tile_position)
	var mirror: RandomNumberGenerator = _svc.begin_event("attack", freeze_rec)
	var r1: int = mirror.randi_range(0, 99)
	var r2: int = mirror.randi_range(0, 99)
	var want_hit: bool = (r1 + r2) / 2 < 50
	var want_crit: bool = false
	if want_hit:
		want_crit = mirror.randi_range(0, 99) < 50
	var freeze_result: Dictionary = _cr.resolve_combat(a, d, freeze_rec)
	var ex0: Dictionary = freeze_result["exchanges"][0]
	if ex0["hit"] == want_hit and ex0["crit"] == want_crit:
		print("OK  T7 draw-order freeze: 2 hit RNs then crit-only-on-hit (r1=%d r2=%d)" % [r1, r2])
		passed += 1
	else:
		print(
			(
				"FAIL T7 freeze: got hit=%s crit=%s want hit=%s crit=%s"
				% [ex0["hit"], ex0["crit"], want_hit, want_crit]
			)
		)
		failed += 1

	# ---- CampaignRules.hit_formula selects single_roll (CRR-4) ----
	var rules = CampaignRulesS.new()
	rules.hit_formula = "single_roll"
	gs.set("campaign_rules", rules)
	_svc.start_map(FIXED_SEED)
	var sr_mirror: RandomNumberGenerator = _svc.begin_event("attack", freeze_rec)
	var sr1: int = sr_mirror.randi_range(0, 99)
	var sr_want_hit: bool = sr1 < 50
	var sr_want_crit: bool = false
	if sr_want_hit:
		sr_want_crit = sr_mirror.randi_range(0, 99) < 50
	var sr_result: Dictionary = _cr.resolve_combat(a, d, freeze_rec)
	var sr_ex0: Dictionary = sr_result["exchanges"][0]
	if (
		sr_ex0["hit"] == sr_want_hit
		and sr_ex0["crit"] == sr_want_crit
		and sr_result["context"]["hit_formula"] == "single_roll"
	):
		print("OK  CampaignRules.hit_formula=single_roll: 1 hit RN consumed (r1=%d)" % sr1)
		passed += 1
	else:
		print(
			(
				"FAIL hit_formula selection: got hit=%s want=%s formula=%s"
				% [sr_ex0["hit"], sr_want_hit, sr_result["context"]["hit_formula"]]
			)
		)
		failed += 1

	# Unknown formula id falls back to the two_roll default.
	rules.hit_formula = "not_a_resolver"
	var fb_result: Dictionary = _cr.resolve_combat(a, d, freeze_rec)
	gs.set("campaign_rules", null)
	if fb_result["context"]["hit_formula"] == "two_roll":
		print("OK  unknown hit_formula falls back to the two_roll default")
		passed += 1
	else:
		print("FAIL unknown-formula fallback: %s" % fb_result["context"]["hit_formula"])
		failed += 1

	# ---- event record shape (§3): [attacker_id, from, to, defender_id] ----
	var shape: Array[String] = _cr.make_attack_event_record(a, d, Vector2i(0, 1))
	if shape == (["a1", "0,1", "1,1", "d1"] as Array[String]):
		print("OK  attack event record: [attacker_id, from_tile, to_tile, defender_id]")
		passed += 1
	else:
		print("FAIL record shape: %s" % str(shape))
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
