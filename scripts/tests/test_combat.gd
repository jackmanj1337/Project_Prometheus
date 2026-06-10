extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_combat.gd
# Verifies CombatResolver math: hit, damage, crit, triangle, effective, EXP, counterattack, follow-up.
# Uses mock unit objects so no scene tree is needed.

const GameConst      = preload("res://scripts/shared/GameConstants.gd")
const WeaponDataS    = preload("res://scripts/resources/WeaponData.gd")
const UnitDataS      = preload("res://scripts/resources/UnitData.gd")
const CombatRes      = preload("res://scripts/core/CombatResolver.gd")
const InventoryEntry = preload("res://scripts/resources/InventoryEntry.gd")
const DataManagerS   = preload("res://scripts/autoloads/DataManager.gd")
const SkillHandlerS  = preload("res://scripts/skills/SkillHandler.gd")

# ---------- Minimal mock unit (extends Node so it passes Node-typed params) ----------
class MockUnit extends Node:
	var data: Resource
	var tile_position: Vector2i = Vector2i.ZERO
	var team: String = "blue"
	var _weapon: Resource = null
	var _qualities: Array = []
	var _skills: Array = []

	func setup(unit_data: Resource, tile: Vector2i, _team: String) -> void:
		data = unit_data
		tile_position = tile
		team = _team

	func get_equipped_weapon() -> Resource:
		return _weapon

	func get_equipped_weapon_entry():  # -> InventoryEntry | null
		if _weapon == null: return null
		var e := InventoryEntry.new()
		e.entry_type = "weapon"
		e.weapon_id = _weapon.get("id")
		# Mirror _weapon_uses so resolve_combat's durability simulation sees the same
		# remaining-use count that use_weapon_durability() decrements.
		e.uses_remaining = _weapon_uses
		return e

	func has_quality(q: String) -> bool:
		return q in _qualities

	func has_skill(s: String) -> bool:
		return s in _skills

	# Combat-stat helpers mirror Unit.gd: all stat reads route through
	# get_effective_stat so a "combat"-duration modifier (Resolve, Wrath,
	# Pair Up bonus, stat_bonus) flows into the same formulas production
	# uses. Code review 2026-06-10 issue 2.5 — without this, tests for
	# modifier-bearing combat exercised a different code path than the
	# real Unit.
	func battle_speed(_w: Resource = null) -> int:
		var w: Resource = _w if _w else _weapon
		if w == null: return get_effective_stat("speed")
		return get_effective_stat("speed") - maxi(0,
			w.get("wt") - get_effective_stat("strength"))

	func accuracy(_w: Resource = null) -> int:
		var w: Resource = _w if _w else _weapon
		var acc: int = get_effective_stat("skill") * 2 + get_effective_stat("luck")
		if w: acc += w.get("hit")
		return acc

	func dodge(_w: Resource = null) -> int:
		return battle_speed(_w) * 2 + get_effective_stat("luck")

	func crit_rate(_w: Resource = null) -> int:
		var w: Resource = _w if _w else _weapon
		return get_effective_stat("skill") / 2 + (w.get("crit") if w else 0)

	func crit_avoid() -> int:
		return get_effective_stat("luck")

	func get_terrain_def_bonus() -> int:
		return 0

	func get_terrain_dodge_bonus() -> int:
		return 0

	func get_effective_stat(stat_name: String) -> int:
		var base = data.get(stat_name)
		var total: int = int(base) if base != null else 0
		for mod in data.active_modifiers:
			if mod.get("stat", "") == stat_name:
				total += mod.get("delta", 0)
		return max(0, total)

	func get_weapon_rank(track: String) -> String:
		return GameConst.weapon_rank_for_wexp(int(data.weapon_wexp.get(track, 0)))

	# Tracks remaining uses for apply_combat_result tests. Default 99 = effectively unlimited.
	var _weapon_uses: int = 99

	func use_weapon_durability(weapon_id: String = "") -> bool:
		if _weapon == null:
			return false
		if weapon_id != "" and _weapon.get("id") != weapon_id:
			return false
		if _weapon_uses <= 0:
			return false
		_weapon_uses -= 1
		if _weapon_uses <= 0:
			_weapon = null
			return true
		return false

	func take_damage(amount: int) -> void:
		data.hp = max(0, data.hp - amount)

	func add_wexp(_type: String, _amount: int) -> bool:
		return false

	func clear_combat_modifiers() -> void:
		pass

	func handle_death() -> void:
		pass

	# Faithful mirror of Unit.add_modifier/remove_modifier — replaces all modifiers
	# sharing a source. The preview-with-Resolve test relies on this exact behavior.
	func add_modifier(stat: String, delta: int, source: String,
			duration: int, duration_type: String) -> void:
		remove_modifier(source)
		data.active_modifiers.append({
			"stat": stat, "delta": delta, "source": source,
			"duration": duration, "duration_type": duration_type})

	func remove_modifier(source: String) -> void:
		data.active_modifiers = data.active_modifiers.filter(
			func(m): return m["source"] != source)


func _make_weapon(p: Dictionary) -> Resource:
	var w = WeaponDataS.new()
	w.id           = p.get("id", "test")
	w.combat_family = p.get("combat_family", p.get("weapon_type", "sword"))
	w.wexp_track    = p.get("wexp_track", GameConst.combat_family_to_wexp_track(w.combat_family))
	w.mt           = p.get("mt", 6)
	w.hit          = p.get("hit", 80)
	w.crit         = p.get("crit", 0)
	w.range_min_formula = str(p.get("range_min", 1))
	w.range_max_formula = str(p.get("range_max", 1))
	w.wt              = p.get("wt", 5)
	w.uses            = p.get("uses", 45)
	w.wexp            = p.get("wexp", 1)
	w.uses_mag        = p.get("uses_mag", false)
	w.strikes_per_attack = p.get("strikes_per_attack", 1)
	w.effect_tags.assign(p.get("effect_tags", []))
	w.required_rank = p.get("required_rank", "E")
	w.triangle_family = p.get("triangle_family", p.get("magic_triangle_type", ""))
	return w


func _make_unit(p: Dictionary) -> MockUnit:
	var ud = UnitDataS.new()
	ud.unit_name  = p.get("name", "Test")
	ud.class_id   = p.get("class_id", "soldier")
	ud.level      = p.get("level", 5)
	ud.hp         = p.get("hp", 30)
	ud.max_hp     = p.get("max_hp", 30)
	ud.strength   = p.get("strength", 10)
	ud.magic      = p.get("magic", 0)
	ud.defense    = p.get("defense", 5)
	ud.resistance = p.get("resistance", 2)
	ud.skill      = p.get("skill", 10)
	ud.speed      = p.get("speed", 10)
	ud.luck       = p.get("luck", 5)
	ud.movement   = p.get("movement", 5)
	ud.skills.assign(p.get("skills", []))
	var u := MockUnit.new()
	u.setup(ud, p.get("tile", Vector2i.ZERO), p.get("team", "blue"))
	u._weapon = p.get("weapon", null)
	u._qualities = p.get("qualities", [])
	return u


func _init() -> void:
	print("=== Combat Resolver Test ===")
	var passed := 0
	var failed := 0

	var cr := CombatRes.new()
	root.add_child(cr)  # must be in tree for get_node_or_null autoload lookups

	# DataManager + SkillHandler under /root so combat skill triggers resolve in
	# tests (used by the preview-with-Resolve case). Mirrors test_skill_item_handler.
	var dm: Node = DataManagerS.new()
	dm.name = "DataManager"
	root.add_child(dm)
	dm._ready()
	var sh: Node = SkillHandlerS.new()
	sh.name = "SkillHandler"
	root.add_child(sh)
	await process_frame

	# Weapons
	var iron_sword  = _make_weapon({"id":"iron_sword","weapon_type":"sword","mt":6,"hit":85,"crit":0,"range_min":1,"range_max":1,"wt":7})
	var iron_lance  = _make_weapon({"id":"iron_lance","weapon_type":"lance","mt":7,"hit":80,"crit":0,"range_min":1,"range_max":1,"wt":8})
	var iron_bow    = _make_weapon({"id":"iron_bow","weapon_type":"bow","mt":6,"hit":85,"crit":0,"range_min":2,"range_max":2,"wt":5,"effect_tags":["effective_flying"]})
	var javelin     = _make_weapon({"id":"javelin","weapon_type":"lance","mt":6,"hit":75,"crit":0,"range_min":1,"range_max":2,"wt":11})
	var fire_tome   = _make_weapon({"id":"fire","weapon_type":"fire","mt":4,"hit":80,"crit":0,"range_min":1,"range_max":2,"wt":2,"uses_mag":true,"effect_tags":["effective_beast"],"magic_triangle_type":"fire"})

	# --- Test: basic damage and hit (both use same type = no triangle modifier) ---
	var atk = _make_unit({"name":"Attacker","strength":10,"magic":0,"defense":5,"resistance":2,"skill":10,"speed":10,"luck":5,"weapon":iron_sword})
	# Defender uses a bow (no triangle vs sword) to ensure neutral matchup
	var def = _make_unit({"name":"Defender","strength":8,"magic":0,"defense":4,"resistance":2,"skill":8,"speed":8,"luck":4,"team":"red","tile":Vector2i(1,0),"weapon":iron_bow})

	var hit = cr.compute_hit_pct(atk, def, iron_sword)
	# Accuracy = 10*2+5+85 = 110; Dodge = (8-max(0,5-8))*2+4 = 8*2+4=20; Hit% = 90 (no triangle)
	if hit == 90:
		print("OK  basic hit pct: %d" % hit)
		passed += 1
	else:
		print("FAIL basic hit pct: got %d, want 90" % hit)
		failed += 1

	var dmg = cr.compute_damage(atk, def, iron_sword)
	# ATK = 10+6 = 16 (no s-rank, no triangle); DEF = 4; DMG = 12
	if dmg == 12:
		print("OK  basic damage: %d" % dmg)
		passed += 1
	else:
		print("FAIL basic damage: got %d, want 12" % dmg)
		failed += 1

	var crit = cr.compute_crit_pct(atk, def, iron_sword)
	# Crit = floor(10/2)+0 - 4 = 5-4 = 1
	if crit == 1:
		print("OK  basic crit pct: %d" % crit)
		passed += 1
	else:
		print("FAIL basic crit pct: got %d, want 1" % crit)
		failed += 1

	# --- Weapon triangle: sword vs lance = disadvantage for sword ---
	var def_lance = _make_unit({"name":"Lancedef","defense":4,"skill":8,"speed":8,"luck":4,"team":"red","tile":Vector2i(1,0),"weapon":iron_lance})
	var hit_disadv = cr.compute_hit_pct(atk, def_lance, iron_sword)
	# acc=110; triangle -10; dodge=(8-0)*2+4=20; hit=110-10-20=80
	if hit_disadv == 80:
		print("OK  weapon triangle disadvantage hit pct: %d" % hit_disadv)
		passed += 1
	else:
		print("FAIL weapon triangle hit pct: got %d, want 80" % hit_disadv)
		failed += 1

	var dmg_disadv = cr.compute_damage(atk, def_lance, iron_sword)
	# atk=10+6-2=14; def=4; dmg=10
	if dmg_disadv == 10:
		print("OK  weapon triangle disadvantage damage: %d" % dmg_disadv)
		passed += 1
	else:
		print("FAIL weapon triangle damage: got %d, want 10" % dmg_disadv)
		failed += 1

	# --- Weapon triangle advantage: lance vs sword ---
	var atk2 = _make_unit({"name":"Lancer","strength":10,"defense":5,"skill":10,"speed":10,"luck":5,"weapon":iron_lance})
	var def2 = _make_unit({"name":"Swordsman","strength":8,"defense":4,"skill":8,"speed":8,"luck":4,"team":"red","tile":Vector2i(1,0),"weapon":iron_sword})
	var hit_adv = cr.compute_hit_pct(atk2, def2, iron_lance)
	# acc = 10*2+5+80 = 105; triangle adv +10 = 115; dodge = 8*2+4 = 20; hit = 115-20 = 95
	if hit_adv == 95:
		print("OK  weapon triangle advantage hit pct: %d" % hit_adv)
		passed += 1
	else:
		print("FAIL weapon triangle advantage hit pct: got %d, want 95" % hit_adv)
		failed += 1

	var dmg_adv = cr.compute_damage(atk2, def2, iron_lance)
	# atk=10+7+2=19; def=4; dmg=15
	if dmg_adv == 15:
		print("OK  weapon triangle advantage damage: %d" % dmg_adv)
		passed += 1
	else:
		print("FAIL weapon triangle advantage damage: got %d, want 15" % dmg_adv)
		failed += 1

	# --- Effective weapon (bow vs flying) ---
	var archer = _make_unit({"name":"Archer","strength":8,"defense":3,"skill":9,"speed":9,"luck":4,"weapon":iron_bow,"tile":Vector2i(0,2)})
	var pegasus = _make_unit({"name":"Pegasus","strength":6,"defense":2,"skill":7,"speed":12,"luck":5,"team":"red","tile":Vector2i(0,0),"qualities":["flying"]})
	var dmg_eff = cr.compute_damage(archer, pegasus, iron_bow)
	# mt=6*3=18 (effective); base_stat=8; atk=8+18=26; def=2; dmg=24
	if dmg_eff == 24:
		print("OK  effective weapon damage: %d" % dmg_eff)
		passed += 1
	else:
		print("FAIL effective weapon damage: got %d, want 24" % dmg_eff)
		failed += 1

	# Non-flying enemy → not effective → normal mt
	var non_flying = _make_unit({"name":"Soldier","strength":6,"defense":2,"skill":7,"speed":10,"luck":4,"team":"red","tile":Vector2i(0,0)})
	var dmg_not_eff = cr.compute_damage(archer, non_flying, iron_bow)
	# mt=6 (not effective); atk=8+6=14; def=2; dmg=12
	if dmg_not_eff == 12:
		print("OK  non-effective same weapon damage: %d" % dmg_not_eff)
		passed += 1
	else:
		print("FAIL non-effective weapon damage: got %d, want 12" % dmg_not_eff)
		failed += 1

	# --- Counterattack range check ---
	# Bow: range_min=2, range_max=2; target at distance 1 cannot counter
	var target_adj = _make_unit({"name":"Adjacent","weapon":iron_sword,"tile":Vector2i(0,0)})
	var bowman = _make_unit({"name":"Bowman","weapon":iron_bow,"tile":Vector2i(0,2)})
	# distance from bowman to target_adj = 2 → can counter
	if cr.can_counterattack(target_adj, bowman.tile_position):
		print("FAIL range check: sword should not reach from tile (0,0) to (0,2) with range 1")
		failed += 1
	else:
		print("OK  melee cannot counter at range 2")
		passed += 1

	var target_melee = _make_unit({"name":"Melee","weapon":iron_sword,"tile":Vector2i(0,1)})
	if not cr.can_counterattack(target_melee, Vector2i(0,0)):
		print("FAIL melee should counter at range 1")
		failed += 1
	else:
		print("OK  melee can counter at range 1")
		passed += 1

	# --- Follow-up ---
	var fast = _make_unit({"name":"Fast","speed":14,"weapon":iron_sword})
	var slow = _make_unit({"name":"Slow","speed":9,"weapon":iron_lance,"tile":Vector2i(1,0),"team":"red"})
	var fu = cr.get_follow_up_attacker(fast, slow)
	if fu == fast:
		print("OK  follow-up: fast unit attacks twice")
		passed += 1
	else:
		print("FAIL follow-up: expected fast unit, got %s" % str(fu))
		failed += 1

	var even_a = _make_unit({"name":"EvenA","speed":10,"weapon":iron_sword})
	var even_b = _make_unit({"name":"EvenB","speed":10,"weapon":iron_lance,"tile":Vector2i(1,0),"team":"red"})
	if cr.get_follow_up_attacker(even_a, even_b) != null:
		print("FAIL no follow-up when speed equal")
		failed += 1
	else:
		print("OK  no follow-up when speed equal")
		passed += 1

	# --- EXP table ---
	var lv5_atk = _make_unit({"level":5})
	var lv5_def = _make_unit({"level":5})
	if cr.calculate_exp(lv5_atk, lv5_def, true) == 30:
		print("OK  EXP kill equal level: 30")
		passed += 1
	else:
		print("FAIL EXP kill equal level: got %d" % cr.calculate_exp(lv5_atk, lv5_def, true))
		failed += 1

	if cr.calculate_exp(lv5_atk, lv5_def, false) == 10:
		print("OK  EXP damage-only equal level: 10")
		passed += 1
	else:
		print("FAIL EXP damage-only: got %d" % cr.calculate_exp(lv5_atk, lv5_def, false))
		failed += 1

	var lv10_atk = _make_unit({"level":10})
	var lv1_def  = _make_unit({"level":1})
	# diff = 9 → clamped to 6+6=12 → index 12 → [1, 0]
	if cr.calculate_exp(lv10_atk, lv1_def, true) == 1:
		print("OK  EXP kill high advantage (cap): 1")
		passed += 1
	else:
		print("FAIL EXP kill high advantage: got %d" % cr.calculate_exp(lv10_atk, lv1_def, true))
		failed += 1

	# diff = 1-10 = -9 → clamped to 0 → [59, 20]
	if cr.calculate_exp(lv1_def, lv10_atk, true) == 59:
		print("OK  EXP kill high underdog (cap): 59")
		passed += 1
	else:
		print("FAIL EXP kill high underdog: got %d" % cr.calculate_exp(lv1_def, lv10_atk, true))
		failed += 1

	# --- DEBUG AID #10: debug_force_levelup makes any hit award 100 EXP ---
	# Only effective in debug builds (the headless test binary is one). Restored
	# to false afterwards so it can't bleed into later assertions.
	var gs_dbg := root.get_node_or_null("GameState")
	if gs_dbg != null:
		gs_dbg.debug_force_levelup = true
		var forced: bool = cr.calculate_exp(lv10_atk, lv1_def, false) == 100
		gs_dbg.debug_force_levelup = false
		var normal: bool = cr.calculate_exp(lv10_atk, lv1_def, false) != 100
		if forced and normal:
			print("OK  debug_force_levelup forces 100 EXP, off restores normal (#10)")
			passed += 1
		else:
			print("FAIL debug_force_levelup: forced=%s normal=%s" % [forced, normal])
			failed += 1
	else:
		print("SKIP debug_force_levelup (GameState autoload absent)")

	# --- Damage minimum 0 ---
	var tanky = _make_unit({"name":"Tank","defense":20,"team":"red","tile":Vector2i(1,0),"weapon":iron_lance})
	var weak  = _make_unit({"name":"Weak","strength":3,"weapon":iron_sword})
	var dmg_zero = cr.compute_damage(weak, tanky, iron_sword)
	# atk=3+6-2=7 (triangle: sword vs lance = -2); def=20; 7-20=-13 → clamp to 0
	if dmg_zero == 0:
		print("OK  damage clamped to 0")
		passed += 1
	else:
		print("FAIL damage not clamped: got %d" % dmg_zero)
		failed += 1

	# --- Preview contains correct fields ---
	var prev = cr.preview_combat(atk, def)
	if prev.has("attacker_hit") and prev.has("defender_hit") and prev.has("can_counter"):
		print("OK  preview_combat returns expected keys")
		passed += 1
	else:
		print("FAIL preview_combat missing keys")
		failed += 1

	# --- More Info preview fields: triangle + effectiveness ---
	# Sword (atk) vs Bow (def) is neutral. Both effective flags must be false
	# and both multipliers must be 1.0 — defaults the UI marker code relies on.
	var neutral_ok: bool = (
		String(prev.get("attacker_triangle", "")) == "neutral"
		and String(prev.get("defender_triangle", "")) == "neutral"
		and bool(prev.get("attacker_effective", true)) == false
		and bool(prev.get("defender_effective", true)) == false
		and float(prev.get("attacker_effectiveness_mult", 0.0)) == 1.0
		and float(prev.get("defender_effectiveness_mult", 0.0)) == 1.0
	)
	if neutral_ok:
		print("OK  preview exposes neutral triangle + no effectiveness as defaults")
		passed += 1
	else:
		print("FAIL preview defaults: %s" % prev); failed += 1

	# Sword vs Lance = sword disadvantage; defender's mirror is advantage.
	var atk_tri := _make_unit({"name":"SwordTri","strength":10,"defense":5,"skill":10,"speed":10,"luck":5,"weapon":iron_sword})
	var def_tri := _make_unit({"name":"LanceTri","strength":8,"defense":4,"skill":8,"speed":8,"luck":4,"team":"red","tile":Vector2i(1,0),"weapon":iron_lance})
	var prev_tri := cr.preview_combat(atk_tri, def_tri)
	if String(prev_tri["attacker_triangle"]) == "disadvantage" \
			and String(prev_tri["defender_triangle"]) == "advantage":
		print("OK  preview triangle: sword vs lance -> attacker disadv, defender adv")
		passed += 1
	else:
		print("FAIL preview triangle: atk=%s def=%s" % [prev_tri["attacker_triangle"], prev_tri["defender_triangle"]])
		failed += 1

	# Bow with effective_flying vs flying defender -> attacker_effective true,
	# multiplier 3.0. (Existing fixture: iron_bow has effective_flying tag.)
	var eff_def := _make_unit({"name":"EffPegasus","strength":8,"defense":4,"skill":10,"speed":12,"luck":6,"team":"red","tile":Vector2i(1,0),"qualities":["flying"],"weapon":iron_sword})
	var eff_atk := _make_unit({"name":"EffArcher","strength":10,"defense":5,"skill":12,"speed":8,"luck":4,"weapon":iron_bow})
	var prev_eff := cr.preview_combat(eff_atk, eff_def)
	if bool(prev_eff["attacker_effective"]) and float(prev_eff["attacker_effectiveness_mult"]) == 3.0:
		print("OK  preview effectiveness: bow vs flyer flags effective ×3")
		passed += 1
	else:
		print("FAIL preview effectiveness: eff=%s mult=%s" % [prev_eff["attacker_effective"], prev_eff["attacker_effectiveness_mult"]])
		failed += 1

	# --- #1: preview reflects deterministic skill modifiers (Resolve) ---
	# A Resolve unit at ≤50% HP gets +50% STR (10→15). preview_combat must show the
	# boosted damage: the modifier is applied before the stat reads and restored
	# after. Before the fix, restore ran first and the preview showed base damage.
	var res_atk = _make_unit({"name":"ResolveAtk","strength":10,"defense":5,"skill":10,"speed":10,"luck":5,"hp":8,"max_hp":30,"weapon":iron_sword,"skills":["resolve"]})
	var res_def = _make_unit({"name":"ResolveDef","strength":8,"defense":4,"skill":8,"speed":14,"luck":4,"team":"red","tile":Vector2i(1,0),"weapon":iron_bow})
	var res_prev = cr.preview_combat(res_atk, res_def)
	# Effective STR 10+5=15; atk=15+mt(6)=21; def=4 → damage 17. Base (unfixed) = 12.
	if res_prev["attacker_damage"] == 17:
		print("OK  #1: preview reflects Resolve STR boost (damage %d)" % res_prev["attacker_damage"])
		passed += 1
	else:
		print("FAIL #1: expected preview attacker_damage 17, got %d" % res_prev["attacker_damage"])
		failed += 1
	# Preview must leave no trace — the Resolve modifiers are restored away.
	if res_atk.data.active_modifiers.is_empty() and res_atk.data.hp == 8:
		print("OK  #1: preview restores unit state (no modifier/HP trace)")
		passed += 1
	else:
		print("FAIL #1: preview left %d modifier(s), hp=%d" \
			% [res_atk.data.active_modifiers.size(), res_atk.data.hp])
		failed += 1

	# --- Nihil: a DEFENDING Nihil bearer negates the attacker's on_combat_start skills ---
	# The old trigger order applied the attacker's skills before the defender's Nihil
	# could fire, so a defending Nihil (e.g. the map boss) negated nothing.
	var nihil_atk = _make_unit({"name":"NihilAtk","strength":10,"defense":5,"skill":10,"speed":10,"luck":5,"weapon":iron_sword,"skills":["swordfaire"]})
	var nihil_def = _make_unit({"name":"NihilDef","strength":8,"defense":4,"skill":8,"speed":8,"luck":4,"team":"red","tile":Vector2i(1,0),"weapon":iron_bow,"skills":["nihil"]})
	var nihil_prev = cr.preview_combat(nihil_atk, nihil_def)
	# Base damage = STR 10 + mt 6 - DEF 4 = 12. Swordfaire would add +5 → 17.
	# The defender's Nihil must negate Swordfaire, leaving the base 12.
	if nihil_prev["attacker_damage"] == 12:
		print("OK  Nihil: defending bearer negates attacker's Swordfaire (damage %d)" % nihil_prev["attacker_damage"])
		passed += 1
	else:
		print("FAIL Nihil: expected attacker_damage 12 (Swordfaire negated), got %d" % nihil_prev["attacker_damage"])
		failed += 1

	# Control: same matchup, no defender Nihil → Swordfaire applies (+5 → 17).
	var ctrl_def = _make_unit({"name":"CtrlDef","strength":8,"defense":4,"skill":8,"speed":8,"luck":4,"team":"red","tile":Vector2i(1,0),"weapon":iron_bow})
	var ctrl_prev = cr.preview_combat(nihil_atk, ctrl_def)
	if ctrl_prev["attacker_damage"] == 17:
		print("OK  Nihil control: Swordfaire applies (+5 → %d) without a defender Nihil" % ctrl_prev["attacker_damage"])
		passed += 1
	else:
		print("FAIL Nihil control: expected attacker_damage 17, got %d" % ctrl_prev["attacker_damage"])
		failed += 1

	# --- Nihil exemption: S-Rank Mastery still fires when the bearer is Nihil-blocked ---
	# NIHIL_EXEMPT_SKILLS keeps s_rank_mastery active even though the defender's Nihil
	# blocks the bearer's combat skills; swordfaire (not exempt) is still negated.
	var exempt_atk = _make_unit({"name":"ExemptAtk","strength":10,"defense":5,"skill":10,"speed":10,"luck":5,"weapon":iron_sword,"skills":["swordfaire","s_rank_mastery"]})
	exempt_atk.data.weapon_wexp = {"sword": 500}
	var exempt_def = _make_unit({"name":"ExemptDef","strength":8,"defense":4,"skill":8,"speed":8,"luck":4,"team":"red","tile":Vector2i(1,0),"weapon":iron_bow,"skills":["nihil"]})
	var exempt_prev = cr.preview_combat(exempt_atk, exempt_def)
	# Base 10+6-4 = 12. Swordfaire (+5) negated; S-Rank Mastery (+1 dmg, exempt) applies → 13.
	if exempt_prev["attacker_damage"] == 13:
		print("OK  Nihil exemption: S-Rank Mastery applies (+1) while Swordfaire is negated")
		passed += 1
	else:
		print("FAIL Nihil exemption: expected attacker_damage 13, got %d" % exempt_prev["attacker_damage"])
		failed += 1

	# --- A one-shot defender does not counterattack (GDD_02:167) ---
	# glass_atk one-shots glass_def. Per GDD_02:167 the exchange stops the moment the
	# defender's HP hits 0 — the dead defender must NOT swing back, so the attacker
	# survives. (Previously the corpse counterattacked — the counter loop had no
	# actor-alive guard; _run_strike_series now supplies it.)
	var overkill_sword = _make_weapon({"id":"ok_sword","weapon_type":"sword","mt":50,"hit":100,"crit":0,"range_min":1,"range_max":1,"wt":1})
	var overkill_lance = _make_weapon({"id":"ok_lance","weapon_type":"lance","mt":50,"hit":100,"crit":0,"range_min":1,"range_max":1,"wt":1})
	var glass_atk = _make_unit({"name":"GlassAtk","strength":30,"defense":0,"skill":50,"speed":10,"luck":0,"hp":1,"max_hp":1,"weapon":overkill_sword})
	var glass_def = _make_unit({"name":"GlassDef","strength":30,"defense":0,"skill":50,"speed":10,"luck":0,"hp":1,"max_hp":1,"team":"red","tile":Vector2i(1,0),"weapon":overkill_lance})
	var mk_result := cr.resolve_combat(glass_atk, glass_def)
	var def_countered: bool = (mk_result["exchanges"] as Array).any(
		func(e): return e["attacker"] == glass_def)
	if mk_result["defender_died"] and not mk_result["attacker_died"] and not def_countered:
		print("OK  one-shot: dead defender does not counterattack; attacker survives")
		passed += 1
	else:
		print("FAIL one-shot counter: def_died=%s atk_died=%s def_countered=%s" \
			% [mk_result["defender_died"], mk_result["attacker_died"], def_countered])
		failed += 1

	# --- apply_combat_result applies every exchange, so a mutual kill still lands (BUG-01) ---
	# resolve_combat can no longer author a both-die fight (GDD_02:167 stops the exchange
	# on the first death). The BUG-01 fix lives in apply_combat_result: it iterates ALL
	# exchanges rather than stopping at the first death. Hand-build a result with two
	# lethal exchanges and confirm both units end up dead.
	var mk_a = _make_unit({"name":"MKA","level":5,"strength":30,"defense":0,"hp":1,"max_hp":1,"weapon":overkill_sword})
	var mk_d = _make_unit({"name":"MKD","level":5,"strength":30,"defense":0,"hp":1,"max_hp":1,"team":"red","tile":Vector2i(1,0),"weapon":overkill_lance})
	var mk_apply := {
		"exchanges": [
			{"attacker": mk_a, "defender": mk_d, "weapon": overkill_sword,
				"hit": true, "crit": false, "damage": 50, "loses_durability": true, "is_counter": false},
			{"attacker": mk_d, "defender": mk_a, "weapon": overkill_lance,
				"hit": true, "crit": false, "damage": 50, "loses_durability": true, "is_counter": true},
		],
		"attacker_died": false, "defender_died": false, "context": {},
	}
	cr.apply_combat_result(mk_apply, mk_a, mk_d)
	if mk_apply["attacker_died"] and mk_apply["defender_died"]:
		print("OK  apply_combat_result iterates all exchanges — mutual kill lands")
		passed += 1
	else:
		print("FAIL apply_combat_result mutual kill: atk_died=%s def_died=%s" \
			% [mk_apply["attacker_died"], mk_apply["defender_died"]])
		failed += 1

	# --- Brave weapon follow-up fires full strike count (BUG-02) ---
	# Fast attacker (SPD 15 vs 9, delta=6 ≥ 4) with Brave weapon (strikes=2).
	# Defender has no weapon and enough HP to survive all hits.
	# Expected: 2 initial strikes + 2 follow-up strikes = 4 exchanges total.
	var brave_sword = _make_weapon({"id":"brave_sword","weapon_type":"sword","mt":1,"hit":100,"crit":0,"range_min":1,"range_max":1,"wt":1,"strikes_per_attack":2})
	var brave_atk = _make_unit({"name":"BraveAtk","strength":5,"defense":0,"skill":10,"speed":15,"luck":0,"hp":30,"max_hp":30,"weapon":brave_sword})
	var tanky_slow_def = _make_unit({"name":"TankySlow","strength":0,"defense":10,"skill":0,"speed":9,"luck":0,"hp":200,"max_hp":200,"team":"red","tile":Vector2i(1,0)})
	var brave_result := cr.resolve_combat(brave_atk, tanky_slow_def)
	var brave_exchanges: int = (brave_result["exchanges"] as Array).size()
	if brave_exchanges == 4:
		print("OK  brave follow-up: 4 exchanges")
		passed += 1
	else:
		print("FAIL brave follow-up: got %d exchanges, want 4" % brave_exchanges)
		failed += 1
	# Verify the last two exchanges are marked as follow-up
	var fu_marked: bool = brave_result["exchanges"][2].get("is_follow_up", false) \
		and brave_result["exchanges"][3].get("is_follow_up", false)
	if fu_marked:
		print("OK  brave follow-up: exchanges [2] and [3] marked is_follow_up")
		passed += 1
	else:
		print("FAIL brave follow-up: is_follow_up not set on follow-up exchanges")
		failed += 1

	# --- H-2: defender stat modifier respected in compute_damage ---
	# Defender with +3 DEF active modifier should take 3 less damage than base.
	var h2_atk = _make_unit({"name":"H2Atk","strength":10,"weapon":iron_sword})
	var h2_def_base = _make_unit({"name":"H2DefBase","defense":4,"team":"red","tile":Vector2i(1,0)})
	var h2_def_buff = _make_unit({"name":"H2DefBuff","defense":4,"team":"red","tile":Vector2i(1,0)})
	h2_def_buff.data.active_modifiers.append({"stat":"defense","delta":3,"duration_type":"turn","duration":1})
	var dmg_base := cr.compute_damage(h2_atk, h2_def_base, iron_sword)
	var dmg_buff := cr.compute_damage(h2_atk, h2_def_buff, iron_sword)
	# base: atk=10+6=16; def=4; dmg=12. buffed: def=7; dmg=9
	if dmg_base == 12 and dmg_buff == 9:
		print("OK  H-2: defender DEF modifier reduces damage (%d→%d)" % [dmg_base, dmg_buff])
		passed += 1
	else:
		print("FAIL H-2: expected 12→9, got %d→%d" % [dmg_base, dmg_buff])
		failed += 1

	# --- H-3: Giantkiller applies when the COUNTER-attacker has the skill ---
	# Defender (counter-attacker) wields a bow (effective vs flying) and has Giantkiller.
	# The attacker is a flying unit. preview_combat defender_damage should be 4x mt.
	var gk_bow = _make_weapon({"id":"gk_bow","weapon_type":"bow","mt":6,"hit":100,"crit":0,"range_min":2,"range_max":2,"effect_tags":["effective_flying"]})
	var gk_atk = _make_unit({"name":"GKAtk","strength":8,"defense":3,"skill":10,"speed":10,"luck":5,"qualities":["flying"],"weapon":iron_sword,"tile":Vector2i(0,2)})
	var gk_def = _make_unit({"name":"GKDef","strength":8,"defense":3,"skill":10,"speed":10,"luck":5,"team":"red","tile":Vector2i(0,0),"weapon":gk_bow})
	gk_def._skills = ["giantkiller"]
	var gk_prev = cr.preview_combat(gk_atk, gk_def)
	# Defender damage: mt=6*4=24 (effective 4× via giantkiller); atk=8+24=32; def_atk_def=3; dmg=29
	if gk_prev["defender_damage"] == 29:
		print("OK  H-3: counter-attacker Giantkiller gives 4× effectiveness damage: %d" % gk_prev["defender_damage"])
		passed += 1
	else:
		print("FAIL H-3: expected defender_damage=29, got %d" % gk_prev["defender_damage"])
		failed += 1

	# --- Mid-combat weapon break stops further attacks ---
	# Brave sword (strikes=2) with 1 use left: first hit breaks it; all subsequent
	# exchanges from the same attacker must be skipped by apply_combat_result.
	# Attacker has SPD 20 vs defender SPD 5 → qualifies for a 2-strike follow-up too,
	# so without the fix 4 hits would land; with the fix only 1 hit lands.
	var break_brave = _make_weapon({"id":"break_brave","weapon_type":"sword","mt":5,"hit":100,"crit":0,"wt":1,"strikes_per_attack":2})
	var break_atk = _make_unit({"name":"BreakAtk","strength":10,"defense":5,"skill":10,"speed":20,"luck":5,"hp":30,"max_hp":30,"weapon":break_brave})
	# luck 5 = crit avoid 5 ≥ attacker crit rate (skill 10 / 2 = 5), so crit% clamps
	# to 0 — the one landing hit can never crit and the HP assertion is deterministic.
	var break_def = _make_unit({"name":"BreakDef","strength":5,"defense":0,"skill":5,"speed":5,"luck":5,"hp":50,"max_hp":50,"team":"red","tile":Vector2i(1,0)})
	break_atk._weapon_uses = 1
	var break_result := cr.resolve_combat(break_atk, break_def)
	# resolve_combat models breakage itself — it must stop after the single strike
	# that breaks the weapon, not simulate all 4 and lean on apply_combat_result.
	if (break_result["exchanges"] as Array).size() == 1:
		print("OK  mid-combat break: resolve_combat stops the series at the break")
		passed += 1
	else:
		print("FAIL mid-combat break: expected 1 exchange, got %d" % (break_result["exchanges"] as Array).size())
		failed += 1
	cr.apply_combat_result(break_result, break_atk, break_def)
	# Damage per hit = STR(10) + mt(5) - DEF(0) = 15. Only 1 hit should land → HP = 35.
	if break_def.data.hp == 35:
		print("OK  mid-combat break: weapon breaking stops further attacks (hp=%d)" % break_def.data.hp)
		passed += 1
	else:
		print("FAIL mid-combat break: expected hp=35, got %d" % break_def.data.hp)
		failed += 1

	# --- A1: defender earns kill-tier EXP when it counter-kills the attacker ---
	# Attacker hits for trivial damage (defender survives); defender counters for a
	# guaranteed kill. The defender must still receive kill-tier EXP — the old code
	# zeroed it out because the attacker died.
	var ck_weak_sword = _make_weapon({"id":"ck_weak","weapon_type":"sword","mt":1,"hit":100,"crit":0,"range_min":1,"range_max":1,"wt":1})
	var ck_kill_sword = _make_weapon({"id":"ck_kill","weapon_type":"sword","mt":50,"hit":100,"crit":0,"range_min":1,"range_max":1,"wt":1})
	var ck_atk = _make_unit({"name":"CKAtk","level":5,"strength":5,"defense":0,"skill":10,"speed":10,"luck":0,"hp":10,"max_hp":10,"weapon":ck_weak_sword})
	var ck_def = _make_unit({"name":"CKDef","level":5,"strength":30,"defense":0,"skill":10,"speed":10,"luck":0,"hp":50,"max_hp":50,"team":"red","tile":Vector2i(1,0),"weapon":ck_kill_sword})
	var ck_result := cr.resolve_combat(ck_atk, ck_def)
	cr.apply_combat_result(ck_result, ck_atk, ck_def)
	# Equal level (5 vs 5) kill EXP = 30 (matches the "EXP kill equal level" case above).
	if ck_result["attacker_died"] and ck_result["defender_exp"] == 30:
		print("OK  A1: counter-kill awards defender kill-tier EXP (%d)" % ck_result["defender_exp"])
		passed += 1
	else:
		print("FAIL A1: attacker_died=%s defender_exp=%d (want died, 30)" % [ck_result["attacker_died"], ck_result["defender_exp"]])
		failed += 1

	# --- Vantage: a counter-killing Vantage defender pre-empts the attacker entirely ---
	# With Vantage the defender strikes first. If that strike kills the attacker, the
	# already-dead attacker must NOT swing back. Regression for the resolve_combat
	# attacker loop missing an atk_sim_hp guard (code review 2026-05-16d, High).
	# Speeds are equal (10 vs 10) so no follow-up muddies the exchange count.
	var van_kill_lance = _make_weapon({"id":"van_kill","weapon_type":"lance","mt":50,"hit":100,"crit":0,"range_min":1,"range_max":1,"wt":1})
	var van_atk = _make_unit({"name":"VanAtk","level":5,"strength":5,"defense":0,"skill":10,"speed":10,"luck":0,"hp":8,"max_hp":8,"weapon":iron_sword})
	var van_def = _make_unit({"name":"VanDef","level":5,"strength":30,"defense":0,"skill":10,"speed":10,"luck":0,"hp":40,"max_hp":40,"team":"red","tile":Vector2i(1,0),"weapon":van_kill_lance,"skills":["vantage"]})
	var van_result := cr.resolve_combat(van_atk, van_def)
	var van_atk_swung: bool = (van_result["exchanges"] as Array).any(
		func(e): return e["attacker"] == van_atk)
	if van_result["attacker_died"] and not van_result["defender_died"] and not van_atk_swung:
		print("OK  Vantage: counter-killed attacker never swings back")
		passed += 1
	else:
		print("FAIL Vantage: attacker_died=%s defender_died=%s attacker_swung=%s" \
			% [van_result["attacker_died"], van_result["defender_died"], van_atk_swung])
		failed += 1
	# Exactly one exchange — the single defender strike that killed the attacker.
	if (van_result["exchanges"] as Array).size() == 1:
		print("OK  Vantage: exactly one exchange (the lethal counter)")
		passed += 1
	else:
		print("FAIL Vantage: expected 1 exchange, got %d" % (van_result["exchanges"] as Array).size())
		failed += 1

	# --- dry_run: combat previews never burn a limited-use skill's uses ---
	# Temporarily make Swordfaire a 1-use-per-map skill. preview_combat must leave
	# skill_use_counters untouched (dry_run), while resolve_combat increments it once.
	# Regression for preview_combat persisting use counters (code review 2026-05-16d).
	var faire_skill = dm.get_skill("swordfaire")
	faire_skill.max_uses_per_map = 1
	var dry_atk = _make_unit({"name":"DryAtk","strength":10,"defense":5,"skill":10,"speed":10,"luck":5,"weapon":iron_sword,"skills":["swordfaire"]})
	var dry_def = _make_unit({"name":"DryDef","strength":8,"defense":4,"skill":8,"speed":8,"luck":4,"team":"red","tile":Vector2i(1,0),"weapon":iron_bow})
	cr.preview_combat(dry_atk, dry_def)
	cr.preview_combat(dry_atk, dry_def)
	# Counter is keyed by skill.id (code review 2026-06-10 issue 2.6), not the
	# shared effect_id "faire" — so the three faire skills don't pool quotas.
	var uses_after_preview: int = dry_atk.data.skill_use_counters.get("swordfaire", 0)
	if uses_after_preview == 0:
		print("OK  dry_run: two previews burn 0 skill uses")
		passed += 1
	else:
		print("FAIL dry_run: previews burned %d use(s), want 0" % uses_after_preview)
		failed += 1
	cr.resolve_combat(dry_atk, dry_def)
	var uses_after_resolve: int = dry_atk.data.skill_use_counters.get("swordfaire", 0)
	if uses_after_resolve == 1:
		print("OK  dry_run: resolve_combat increments the skill use counter")
		passed += 1
	else:
		print("FAIL dry_run: resolve_combat counter = %d, want 1" % uses_after_resolve)
		failed += 1
	faire_skill.max_uses_per_map = -1  # restore the shared DataManager resource

	# --- B2: combat_started fires from resolve_combat, NOT preview_combat ---
	# The signal previously emitted from apply_combat_result, after RNG, so a
	# listener wanting a pre-fight hook would have missed the fight starting and
	# fired only at apply time. Now resolve_combat emits it before any RNG; preview
	# must remain silent so hover forecasts don't trigger fight-start side effects.
	var bus_bs := root.get_node_or_null("EventBus")
	if bus_bs != null:
		var bs_atk = _make_unit({"name":"BsAtk","weapon":iron_sword})
		var bs_def = _make_unit({"name":"BsDef","team":"red","tile":Vector2i(1,0),"weapon":iron_sword})
		var bs_count: Array = [0]  # boxed so the lambda mutates the same int
		var bs_handler := func(_a: Node, _d: Node) -> void:
			bs_count[0] += 1
		bus_bs.combat_started.connect(bs_handler)
		cr.preview_combat(bs_atk, bs_def)
		var preview_silent: bool = bs_count[0] == 0
		cr.resolve_combat(bs_atk, bs_def)
		var resolve_fired: bool = bs_count[0] == 1
		bus_bs.combat_started.disconnect(bs_handler)
		bs_atk.queue_free()
		bs_def.queue_free()
		if preview_silent and resolve_fired:
			print("OK  combat_started fires from resolve_combat, not preview_combat (B2)")
			passed += 1
		else:
			print("FAIL combat_started timing: preview_silent=%s resolve_fired=%s count=%d" % [
				preview_silent, resolve_fired, bs_count[0]])
			failed += 1
	else:
		print("SKIP B2 combat_started timing (EventBus autoload absent)")

	# ── MockUnit modifier flow: a combat-duration modifier must flow through ──
	# accuracy/dodge/crit/battle_speed exactly the way active_modifiers does in
	# production. Pre-2026-06-10, these helpers read raw data.get(...) and the
	# modifier was silently ignored; resolving combat with a stamped modifier
	# now affects hit/dodge/crit (issue 2.5).
	var mod_atk = _make_unit({"name":"ModAtk","skill":10,"luck":5,"speed":10,"strength":10,"weapon":iron_sword})
	var mod_def = _make_unit({"name":"ModDef","skill":8,"luck":4,"speed":8,"strength":8,"team":"red","tile":Vector2i(1,0),"weapon":iron_bow})
	var hit_base: int = cr.compute_hit_pct(mod_atk, mod_def, iron_sword)
	# Stamp +5 skill on attacker; accuracy uses skill*2, so hit should rise by 10.
	mod_atk.data.active_modifiers.append({"stat": "skill", "delta": 5,
		"source": "test", "duration": -1, "duration_type": "combat"})
	var hit_with_skill: int = cr.compute_hit_pct(mod_atk, mod_def, iron_sword)
	# Stamp +6 speed on defender; dodge uses battle_speed*2 + luck, so dodge
	# should rise by 12 and hit should fall further.
	mod_def.data.active_modifiers.append({"stat": "speed", "delta": 6,
		"source": "test", "duration": -1, "duration_type": "combat"})
	var hit_with_both: int = cr.compute_hit_pct(mod_atk, mod_def, iron_sword)
	if hit_with_skill - hit_base == 10 and hit_base - hit_with_both == 2:
		# +10 from attacker skill, then -12 from defender speed, net -2 vs base.
		print("OK  MockUnit modifier flows through accuracy/dodge (issue 2.5)")
		passed += 1
	else:
		print("FAIL MockUnit modifier flow: base=%d skill=%d both=%d (want +10 / -2)" % [
			hit_base, hit_with_skill, hit_with_both])
		failed += 1
	mod_atk.queue_free()
	mod_def.queue_free()

	cr.queue_free()
	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
