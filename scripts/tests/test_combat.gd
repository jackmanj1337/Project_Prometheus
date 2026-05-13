extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_combat.gd
# Verifies CombatResolver math: hit, damage, crit, triangle, effective, EXP, counterattack, follow-up.
# Uses mock unit objects so no scene tree is needed.

const GameConst   = preload("res://scripts/shared/GameConstants.gd")
const WeaponDataS = preload("res://scripts/resources/WeaponData.gd")
const UnitDataS   = preload("res://scripts/resources/UnitData.gd")
const CombatRes   = preload("res://scripts/core/CombatResolver.gd")

# ---------- Minimal mock unit (extends Node so it passes Node-typed params) ----------
class MockUnit extends Node:
	var data: Resource
	var tile_position: Vector2i = Vector2i.ZERO
	var team: String = "player"
	var _weapon: Resource = null
	var _qualities: Array = []
	var _skills: Array = []

	func setup(unit_data: Resource, tile: Vector2i, _team: String) -> void:
		data = unit_data
		tile_position = tile
		team = _team

	func get_equipped_weapon() -> Resource:
		return _weapon

	func get_equipped_weapon_entry() -> Dictionary:
		if _weapon == null: return {}
		return {"weapon_id": _weapon.get("id"), "type": "weapon", "uses_remaining": 99}

	func has_quality(q: String) -> bool:
		return q in _qualities

	func has_skill(s: String) -> bool:
		return s in _skills

	func battle_speed(_w: Resource = null) -> int:
		var w: Resource = _w if _w else _weapon
		if w == null: return data.get("speed")
		return data.get("speed") - maxi(0, w.get("wt") - data.get("strength"))

	func accuracy(_w: Resource = null) -> int:
		var w: Resource = _w if _w else _weapon
		var acc: int = data.get("skill") * 2 + data.get("luck")
		if w: acc += w.get("hit")
		return acc

	func dodge(_w: Resource = null) -> int:
		return battle_speed(_w) * 2 + data.get("luck")

	func crit_rate(_w: Resource = null) -> int:
		var w: Resource = _w if _w else _weapon
		return data.get("skill") / 2 + (w.get("crit") if w else 0)

	func crit_avoid() -> int:
		return data.get("luck")

	func get_terrain_def_bonus() -> int:
		return 0

	func get_terrain_dodge_bonus() -> int:
		return 0

	func _has_s_rank(_w: Resource) -> bool:
		return false

	func get_effective_stat(stat_name: String) -> int:
		var base = data.get(stat_name)
		var total: int = int(base) if base != null else 0
		for mod in data.active_modifiers:
			if mod.get("stat", "") == stat_name:
				total += mod.get("delta", 0)
		return max(0, total)

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
		return _weapon_uses <= 0

	func take_damage(amount: int) -> void:
		data.hp = max(0, data.hp - amount)

	func add_wexp(_type: String, _amount: int) -> bool:
		return false

	func clear_combat_modifiers() -> void:
		pass

	func handle_death() -> void:
		pass


func _make_weapon(p: Dictionary) -> Resource:
	var w = WeaponDataS.new()
	w.id           = p.get("id", "test")
	w.weapon_type  = p.get("weapon_type", "sword")
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
	w.magic_triangle_type = p.get("magic_triangle_type", "")
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
	u.setup(ud, p.get("tile", Vector2i.ZERO), p.get("team", "player"))
	u._weapon = p.get("weapon", null)
	u._qualities = p.get("qualities", [])
	return u


func _init() -> void:
	print("=== Combat Resolver Test ===")
	var passed := 0
	var failed := 0

	var cr := CombatRes.new()
	root.add_child(cr)  # must be in tree for get_node_or_null autoload lookups

	# Weapons
	var iron_sword  = _make_weapon({"id":"iron_sword","weapon_type":"sword","mt":6,"hit":85,"crit":0,"range_min":1,"range_max":1,"wt":7})
	var iron_lance  = _make_weapon({"id":"iron_lance","weapon_type":"lance","mt":7,"hit":80,"crit":0,"range_min":1,"range_max":1,"wt":8})
	var iron_bow    = _make_weapon({"id":"iron_bow","weapon_type":"bow","mt":6,"hit":85,"crit":0,"range_min":2,"range_max":2,"wt":5,"effect_tags":["effective_flying"]})
	var javelin     = _make_weapon({"id":"javelin","weapon_type":"lance","mt":6,"hit":75,"crit":0,"range_min":1,"range_max":2,"wt":11})
	var fire_tome   = _make_weapon({"id":"fire","weapon_type":"fire","mt":4,"hit":80,"crit":0,"range_min":1,"range_max":2,"wt":2,"uses_mag":true,"effect_tags":["effective_beast"],"magic_triangle_type":"fire"})

	# --- Test: basic damage and hit (both use same type = no triangle modifier) ---
	var atk = _make_unit({"name":"Attacker","strength":10,"magic":0,"defense":5,"resistance":2,"skill":10,"speed":10,"luck":5,"weapon":iron_sword})
	# Defender uses a bow (no triangle vs sword) to ensure neutral matchup
	var def = _make_unit({"name":"Defender","strength":8,"magic":0,"defense":4,"resistance":2,"skill":8,"speed":8,"luck":4,"team":"enemy","tile":Vector2i(1,0),"weapon":iron_bow})

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
	var def_lance = _make_unit({"name":"Lancedef","defense":4,"skill":8,"speed":8,"luck":4,"team":"enemy","tile":Vector2i(1,0),"weapon":iron_lance})
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
	var def2 = _make_unit({"name":"Swordsman","strength":8,"defense":4,"skill":8,"speed":8,"luck":4,"team":"enemy","tile":Vector2i(1,0),"weapon":iron_sword})
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
	var pegasus = _make_unit({"name":"Pegasus","strength":6,"defense":2,"skill":7,"speed":12,"luck":5,"team":"enemy","tile":Vector2i(0,0),"qualities":["flying"]})
	var dmg_eff = cr.compute_damage(archer, pegasus, iron_bow)
	# mt=6*3=18 (effective); base_stat=8; atk=8+18=26; def=2; dmg=24
	if dmg_eff == 24:
		print("OK  effective weapon damage: %d" % dmg_eff)
		passed += 1
	else:
		print("FAIL effective weapon damage: got %d, want 24" % dmg_eff)
		failed += 1

	# Non-flying enemy → not effective → normal mt
	var non_flying = _make_unit({"name":"Soldier","strength":6,"defense":2,"skill":7,"speed":10,"luck":4,"team":"enemy","tile":Vector2i(0,0)})
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
	var slow = _make_unit({"name":"Slow","speed":9,"weapon":iron_lance,"tile":Vector2i(1,0),"team":"enemy"})
	var fu = cr.get_follow_up_attacker(fast, slow)
	if fu == fast:
		print("OK  follow-up: fast unit attacks twice")
		passed += 1
	else:
		print("FAIL follow-up: expected fast unit, got %s" % str(fu))
		failed += 1

	var even_a = _make_unit({"name":"EvenA","speed":10,"weapon":iron_sword})
	var even_b = _make_unit({"name":"EvenB","speed":10,"weapon":iron_lance,"tile":Vector2i(1,0),"team":"enemy"})
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

	# --- Damage minimum 0 ---
	var tanky = _make_unit({"name":"Tank","defense":20,"team":"enemy","tile":Vector2i(1,0),"weapon":iron_lance})
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

	# --- Mutual-kill: both attacker_died and defender_died can be true (BUG-01) ---
	# Both units have 1 HP and deal far more than 1 damage — guaranteed mutual kill
	# when both hit. Use 100% hit weapons to eliminate RNG.
	var overkill_sword = _make_weapon({"id":"ok_sword","weapon_type":"sword","mt":50,"hit":100,"crit":0,"range_min":1,"range_max":1,"wt":1})
	var overkill_lance = _make_weapon({"id":"ok_lance","weapon_type":"lance","mt":50,"hit":100,"crit":0,"range_min":1,"range_max":1,"wt":1})
	var glass_atk = _make_unit({"name":"GlassAtk","strength":30,"defense":0,"skill":50,"speed":10,"luck":0,"hp":1,"max_hp":1,"weapon":overkill_sword})
	var glass_def = _make_unit({"name":"GlassDef","strength":30,"defense":0,"skill":50,"speed":10,"luck":0,"hp":1,"max_hp":1,"team":"enemy","tile":Vector2i(1,0),"weapon":overkill_lance})
	var mk_result := cr.resolve_combat(glass_atk, glass_def)
	if mk_result["attacker_died"] and mk_result["defender_died"]:
		print("OK  mutual kill: both attacker_died and defender_died are true")
		passed += 1
	else:
		print("FAIL mutual kill: attacker_died=%s defender_died=%s" % [mk_result["attacker_died"], mk_result["defender_died"]])
		failed += 1

	# --- Brave weapon follow-up fires full strike count (BUG-02) ---
	# Fast attacker (SPD 15 vs 9, delta=6 ≥ 4) with Brave weapon (strikes=2).
	# Defender has no weapon and enough HP to survive all hits.
	# Expected: 2 initial strikes + 2 follow-up strikes = 4 exchanges total.
	var brave_sword = _make_weapon({"id":"brave_sword","weapon_type":"sword","mt":1,"hit":100,"crit":0,"range_min":1,"range_max":1,"wt":1,"strikes_per_attack":2})
	var brave_atk = _make_unit({"name":"BraveAtk","strength":5,"defense":0,"skill":10,"speed":15,"luck":0,"hp":30,"max_hp":30,"weapon":brave_sword})
	var tanky_slow_def = _make_unit({"name":"TankySlow","strength":0,"defense":10,"skill":0,"speed":9,"luck":0,"hp":200,"max_hp":200,"team":"enemy","tile":Vector2i(1,0)})
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
	var h2_def_base = _make_unit({"name":"H2DefBase","defense":4,"team":"enemy","tile":Vector2i(1,0)})
	var h2_def_buff = _make_unit({"name":"H2DefBuff","defense":4,"team":"enemy","tile":Vector2i(1,0)})
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
	var gk_def = _make_unit({"name":"GKDef","strength":8,"defense":3,"skill":10,"speed":10,"luck":5,"team":"enemy","tile":Vector2i(0,0),"weapon":gk_bow})
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
	var break_def = _make_unit({"name":"BreakDef","strength":5,"defense":0,"skill":5,"speed":5,"luck":3,"hp":50,"max_hp":50,"team":"enemy","tile":Vector2i(1,0)})
	break_atk._weapon_uses = 1
	var break_result := cr.resolve_combat(break_atk, break_def)
	cr.apply_combat_result(break_result, break_atk, break_def)
	# Damage per hit = STR(10) + mt(5) - DEF(0) = 15. Only 1 hit should land → HP = 35.
	if break_def.data.hp == 35:
		print("OK  mid-combat break: weapon breaking stops further attacks (hp=%d)" % break_def.data.hp)
		passed += 1
	else:
		print("FAIL mid-combat break: expected hp=35, got %d" % break_def.data.hp)
		failed += 1

	cr.queue_free()
	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
