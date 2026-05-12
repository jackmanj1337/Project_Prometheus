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


func _make_weapon(p: Dictionary) -> Resource:
	var w = WeaponDataS.new()
	w.id           = p.get("id", "test")
	w.weapon_type  = p.get("weapon_type", "sword")
	w.mt           = p.get("mt", 6)
	w.hit          = p.get("hit", 80)
	w.crit         = p.get("crit", 0)
	w.range_min_formula = str(p.get("range_min", 1))
	w.range_max_formula = str(p.get("range_max", 1))
	w.wt           = p.get("wt", 5)
	w.uses         = p.get("uses", 45)
	w.wexp         = p.get("wexp", 1)
	w.uses_mag     = p.get("uses_mag", false)
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

	cr.queue_free()
	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
