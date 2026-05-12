extends Node
# Stateless combat math engine. All methods are pure functions — no fields are
# written here. Apply changes via apply_combat_result() only.

# EXP table from GDD_02: index = clamp(attacker_level - defender_level + 6, 0, 12)
# Each row: [kill_exp, damage_only_exp]
const _EXP_TABLE: Array = [
	[59, 20], [57, 19], [53, 18], [47, 16], [41, 14], [35, 12],
	[30, 10],  # index 6 = equal level
	[25, 8], [19, 6], [13, 4], [7, 2], [3, 1], [1, 0],
]

# Weapon types that always lose durability (hit or miss) per GDD_02.
const _ALWAYS_USE_DURABILITY: Array[String] = [
	"bow", "fire", "thunder", "wind", "light", "dark", "staff",
]

# Weapon triangle sourced from GameConstants — single definition shared with DataManager.


# ---- Weapon Triangle ----

func _get_triangle_result(aw: WeaponData, dw: WeaponData) -> String:
	if aw == null or dw == null:
		return "neutral"
	var atype: String = aw.magic_triangle_type if aw.magic_triangle_type != "" else aw.weapon_type
	var dtype: String = dw.magic_triangle_type if dw.magic_triangle_type != "" else dw.weapon_type
	if GameConstants.WEAPON_TRIANGLE.has(atype):
		var row: Dictionary = GameConstants.WEAPON_TRIANGLE[atype]
		if row.has(dtype):
			return row[dtype]
	return "neutral"


func _triangle_accuracy(attacker: Node, defender: Node) -> int:
	var aw: WeaponData = attacker.get_equipped_weapon() if attacker else null
	var dw: WeaponData = defender.get_equipped_weapon() if defender else null
	var result := _get_triangle_result(aw, dw)
	return 10 if result == "advantage" else (-10 if result == "disadvantage" else 0)


func _triangle_damage(attacker: Node, defender: Node) -> int:
	var aw: WeaponData = attacker.get_equipped_weapon() if attacker else null
	var dw: WeaponData = defender.get_equipped_weapon() if defender else null
	var result := _get_triangle_result(aw, dw)
	return 2 if result == "advantage" else (-2 if result == "disadvantage" else 0)


# ---- Effectiveness ----

# True when the weapon has an effective tag matching the target's class qualities.
func _is_effective(weapon: WeaponData, target: Node) -> bool:
	if weapon == null or target == null or not target.has_method("has_quality"):
		return false
	for tag in weapon.effect_tags:
		match tag:
			GameConstants.TAG_EFFECTIVE_FLYING:
				if target.has_quality("flying"):    return true
			GameConstants.TAG_EFFECTIVE_ARMOURED:
				if target.has_quality("armoured"):  return true
			GameConstants.TAG_EFFECTIVE_MOUNTED:
				if target.has_quality("mounted"):   return true
			GameConstants.TAG_EFFECTIVE_DRAGON:
				if target.has_quality("dragon"):    return true
			GameConstants.TAG_EFFECTIVE_BEAST:
				if target.has_quality("beast"):     return true
	return false


# ---- Core Stat Computations ----

# To-Hit % for one attack, factoring triangle and defender's terrain dodge.
# context can carry "accuracy_bonus" from skills (Resolve, stat_bonus).
func compute_hit_pct(attacker: Node, defender: Node,
		weapon: WeaponData = null, context: Dictionary = {}) -> int:
	var w: WeaponData = weapon if weapon else (attacker.get_equipped_weapon() if attacker else null)
	if w == null:
		return 0
	var acc: int = attacker.accuracy(w)
	acc += _triangle_accuracy(attacker, defender)
	acc += context.get("accuracy_bonus", 0)
	var dodge: int = defender.dodge() + defender.get_terrain_dodge_bonus()
	return clampi(acc - dodge, 0, 100)


# Damage per hit (before crit multiplier), factoring triangle, effectiveness, terrain def.
# context can carry "damage_bonus" from skills (Resolve).
func compute_damage(attacker: Node, defender: Node,
		weapon: WeaponData = null, context: Dictionary = {}) -> int:
	var w: WeaponData = weapon if weapon else (attacker.get_equipped_weapon() if attacker else null)
	if w == null:
		return 0
	# Effective weapons triple Mt (GBA FE convention: base_stat + mt*3 vs base_stat + mt)
	var effective := _is_effective(w, defender)
	var mt: int = w.mt * 3 if effective else w.mt
	var base_stat: int = attacker.data.magic if w.uses_mag else attacker.data.strength
	# S-rank +1 damage (from Unit._has_s_rank, replicated here to avoid calling damage())
	var s_bonus: int = 1 if (attacker.has_method("_has_s_rank") and attacker._has_s_rank(w)) else 0
	var atk: int = base_stat + mt + s_bonus + _triangle_damage(attacker, defender) + context.get("damage_bonus", 0)
	var def_stat: int = defender.data.resistance if w.uses_mag else defender.data.defense
	var def_bonus: int = defender.get_terrain_def_bonus()
	return maxi(0, atk - def_stat - def_bonus)


# Critical hit % for one attack.
# context can carry "crit_bonus" from skills (Wrath, Finesse).
func compute_crit_pct(attacker: Node, defender: Node,
		weapon: WeaponData = null, context: Dictionary = {}) -> int:
	var w: WeaponData = weapon if weapon else (attacker.get_equipped_weapon() if attacker else null)
	return clampi(attacker.crit_rate(w) - defender.crit_avoid() + context.get("crit_bonus", 0), 0, 100)


# ---- Sequence Logic ----

# True if defender can reach attacker's tile with their equipped weapon.
func can_counterattack(defender: Node, attacker_tile: Vector2i) -> bool:
	var w: WeaponData = defender.get_equipped_weapon()
	if w == null:
		return false
	var dist: int = absi(defender.tile_position.x - attacker_tile.x) \
		+ absi(defender.tile_position.y - attacker_tile.y)
	return dist >= w.range_min and dist <= w.range_max


# Returns the unit with a follow-up attack (battle speed diff ≥ 4), or null.
func get_follow_up_attacker(a: Node, b: Node) -> Node:
	if a == null or b == null:
		return null
	var spd_a: int = a.battle_speed()
	var spd_b: int = b.battle_speed()
	if spd_a - spd_b >= 4:
		return a
	if spd_b - spd_a >= 4:
		return b
	return null


# ---- EXP ----

# EXP awarded to attacker after a combat exchange.
func calculate_exp(attacker: Node, defender: Node, killed: bool) -> int:
	var diff: int = attacker.data.level - defender.data.level
	var idx: int = clampi(diff + 6, 0, 12)
	return _EXP_TABLE[idx][0] if killed else _EXP_TABLE[idx][1]


# ---- Preview (no RNG, no side effects) ----

func preview_combat(attacker: Node, defender: Node) -> Dictionary:
	var aw: WeaponData = attacker.get_equipped_weapon()
	var dw: WeaponData = defender.get_equipped_weapon()
	var can_counter := can_counterattack(defender, attacker.tile_position)
	var follow_up := get_follow_up_attacker(attacker, defender)
	return {
		"attacker_hit":     compute_hit_pct(attacker, defender, aw),
		"attacker_damage":  compute_damage(attacker, defender, aw),
		"attacker_crit":    compute_crit_pct(attacker, defender, aw),
		"attacker_attacks": 2 if follow_up == attacker else 1,
		"can_counter":      can_counter,
		"defender_hit":     compute_hit_pct(defender, attacker, dw) if can_counter else 0,
		"defender_damage":  compute_damage(defender, attacker, dw) if can_counter else 0,
		"defender_crit":    compute_crit_pct(defender, attacker, dw) if can_counter else 0,
		"defender_attacks": (2 if follow_up == defender else 1) if can_counter else 0,
		"attacker_weapon":  aw,
		"defender_weapon":  dw,
	}


# ---- Full RNG Resolution ----

# Collects passive skill bonuses from SkillHandler for one attacker.
# Returns dict with accuracy_bonus, damage_bonus, crit_bonus.
func _get_skill_bonuses(unit: Node, weapon: WeaponData, context: Dictionary) -> Dictionary:
	var sh: Node = get_node_or_null("/root/SkillHandler")
	var bonuses := {"accuracy_bonus": 0, "damage_bonus": 0, "crit_bonus": 0,
		"weapon": weapon, "unit": unit}
	if sh == null:
		return bonuses
	# Check which unit this is so we know which blocked flag to honour
	var is_attacker: bool = (unit == context.get("attacker"))
	var blocked_key := "attacker_skills_blocked" if is_attacker else "defender_skills_blocked"
	if context.get(blocked_key, false):
		return bonuses
	return sh.apply_trigger(unit, "passive", bonuses)


# Resolves a single attack roll. Returns a result dict (no unit state changed).
func _resolve_one_attack(atk: Node, def_unit: Node, context: Dictionary) -> Dictionary:
	var weapon: WeaponData = atk.get_equipped_weapon()
	var sk_bonus := _get_skill_bonuses(atk, weapon, context)
	var hit_pct  := compute_hit_pct(atk, def_unit, weapon, sk_bonus)
	var crit_pct := compute_crit_pct(atk, def_unit, weapon, sk_bonus)
	var base_dmg := compute_damage(atk, def_unit, weapon, sk_bonus)

	var did_hit: bool  = (randi() % 100) < hit_pct
	var did_crit: bool = false
	var damage: int    = 0

	if did_hit:
		did_crit = (randi() % 100) < crit_pct
		damage = base_dmg * 3 if did_crit else base_dmg

	# Durability rule: bows/tomes/staves lose use on any use; others only on hit
	var loses_use: bool = false
	if weapon != null:
		loses_use = (weapon.weapon_type in _ALWAYS_USE_DURABILITY) or did_hit

	return {
		"attacker": atk,
		"defender": def_unit,
		"weapon":   weapon,
		"hit":      did_hit,
		"crit":     did_crit,
		"damage":   damage,
		"loses_durability": loses_use,
	}


# Full combat resolution with RNG. Returns result dict; does NOT modify any unit.
func resolve_combat(attacker: Node, defender: Node) -> Dictionary:
	var sh := get_node_or_null("/root/SkillHandler")

	# --- on_combat_start skills ---
	var context: Dictionary = {"attacker": attacker, "defender": defender}
	if sh:
		context = sh.apply_trigger(attacker, "on_combat_start", context)
		if not context.get("defender_skills_blocked", false):
			context = sh.apply_trigger(defender, "on_combat_start", context)

	var vantage_unit: Node   = context.get("vantage_unit", null)
	var can_counter: bool    = can_counterattack(defender, attacker.tile_position)
	var follow_up: Node      = get_follow_up_attacker(attacker, defender)

	# --- Build attack sequence (all upfront per GDD_02) ---
	# Vantage: if defender has it and is the vantage_unit, they go first
	var seq_atk:  Array[Node] = []
	var seq_def:  Array[Node] = []

	if vantage_unit == defender and can_counter:
		seq_atk.append(defender);  seq_def.append(attacker)
		seq_atk.append(attacker);  seq_def.append(defender)
	else:
		seq_atk.append(attacker);  seq_def.append(defender)
		if can_counter:
			seq_atk.append(defender); seq_def.append(attacker)

	if follow_up != null:
		seq_atk.append(follow_up)
		seq_def.append(defender if follow_up == attacker else attacker)

	# --- Resolve each attack, stopping if either unit dies ---
	var exchanges: Array = []
	var atk_sim_hp: int = attacker.data.hp
	var def_sim_hp: int = defender.data.hp

	for i in seq_atk.size():
		var a: Node = seq_atk[i]
		var d: Node = seq_def[i]
		# Stop if either combatant is already dead in the simulation
		var a_hp: int = atk_sim_hp if a == attacker else def_sim_hp
		var d_hp: int = def_sim_hp if d == defender else atk_sim_hp
		if a_hp <= 0 or d_hp <= 0:
			break

		var exchange := _resolve_one_attack(a, d, context)
		exchange["is_follow_up"] = (follow_up != null and i == seq_atk.size() - 1 and a == follow_up)

		if exchange["hit"]:
			var dmg: int = exchange["damage"]
			# Miracle: check on_damaged for defender of this exchange.
			# current_sim_hp is the defender's remaining HP in the simulation (not real HP),
			# so Miracle triggers correctly in multi-hit combats where prior hits landed.
			if sh and dmg >= d_hp:
				var miracle_ctx := {"attacker": a, "defender": d, "damage": dmg,
					"unit": d, "weapon": exchange["weapon"], "current_sim_hp": d_hp}
				var is_d_attacker: bool = (d == attacker)
				if not context.get("attacker_skills_blocked" if is_d_attacker else "defender_skills_blocked", false):
					miracle_ctx = sh.apply_trigger(d, "on_damaged", miracle_ctx)
					dmg = miracle_ctx.get("damage", dmg)
			exchange["damage"] = dmg

			if d == defender:
				def_sim_hp -= dmg
			else:
				atk_sim_hp -= dmg
		exchanges.append(exchange)

	var defender_died: bool = def_sim_hp <= 0
	var attacker_died: bool = atk_sim_hp <= 0
	var atk_dealt: bool = exchanges.any(func(e): return e["attacker"] == attacker and e["hit"])
	var def_dealt: bool = exchanges.any(func(e): return e["attacker"] == defender and e["hit"])

	return {
		"exchanges":     exchanges,
		"attacker_died": attacker_died,
		"defender_died": defender_died,
		"attacker_exp":  calculate_exp(attacker, defender, defender_died) if atk_dealt or defender_died else 0,
		"defender_exp":  calculate_exp(defender, attacker, attacker_died) if (def_dealt and not attacker_died) else 0,
		"context":       context,
	}


# Applies the result from resolve_combat: HP changes, durability, EXP, wEXP, death.
func apply_combat_result(result: Dictionary, attacker: Node, defender: Node) -> void:
	var bus := get_node_or_null("/root/EventBus") if is_inside_tree() else null

	if bus:
		bus.combat_started.emit(attacker, defender)

	for exchange in result["exchanges"]:
		var atk: Node        = exchange["attacker"]
		var def_unit: Node   = exchange["defender"]
		var weapon: WeaponData = exchange.get("weapon", null)

		# Durability
		if exchange["loses_durability"] and atk.has_method("use_weapon_durability"):
			atk.use_weapon_durability()

		if exchange["hit"]:
			# wEXP per successful hit
			if weapon != null and atk.has_method("add_wexp"):
				atk.add_wexp(weapon.weapon_type, weapon.wexp)

			# Apply HP damage
			def_unit.take_damage(exchange["damage"])

			# Death check
			if def_unit.data.hp <= 0 and def_unit.has_method("handle_death"):
				def_unit.handle_death()
				break  # stop further processing

	# Award EXP (only to survivors)
	if attacker.is_inside_tree() and result.get("attacker_exp", 0) > 0 \
			and not result["attacker_died"]:
		attacker.add_exp(result["attacker_exp"])
	if defender.is_inside_tree() and result.get("defender_exp", 0) > 0 \
			and not result["defender_died"]:
		defender.add_exp(result["defender_exp"])

	if bus:
		bus.combat_resolved.emit(attacker, defender, result)
