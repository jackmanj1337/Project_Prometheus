extends Node
# Stateless combat math engine. resolve_combat() returns a result dict; no unit
# fields are written until apply_combat_result() is called.

# EXP table from GDD_02: index = clamp(attacker_level - defender_level + 6, 0, 12)
const _EXP_TABLE: Array = [
	[59, 20], [57, 19], [53, 18], [47, 16], [41, 14], [35, 12],
	[30, 10],  # index 6 = equal level
	[25, 8], [19, 6], [13, 4], [7, 2], [3, 1], [1, 0],
]

# Weapon types that always lose durability (hit or miss) per GDD_02.
const _ALWAYS_USE_DURABILITY: Array[String] = [
	"bow", "fire", "thunder", "wind", "light", "dark", "staff",
]


# ── Context Construction ─────────────────────────────────────────────────────

# Builds the initial context dict with zero modifiers and default flags.
# Both resolve_combat() and preview_combat() call this first.
func _build_combat_context(attacker: Node, defender: Node) -> Dictionary:
	var aw: WeaponData = attacker.get_equipped_weapon() if attacker else null
	var can_ctr := can_counterattack(defender, attacker.tile_position)
	var dw: WeaponData = defender.get_equipped_weapon() if (defender and can_ctr) else null
	var gs := get_node_or_null("/root/GameState")
	return {
		"attacker":            attacker,
		"defender":            defender,
		"attacker_weapon":     aw,
		"defender_weapon":     dw,
		"is_player_initiated": attacker != null and attacker.team == "player",
		"turn_number":         gs.turn_number if gs else 0,
		"atk_mod": {"accuracy": 0, "damage": 0, "crit": 0, "crit_avoid": 0,
			"dodge": 0, "strikes": 0, "damage_multiplier": 1.0},
		"def_mod": {"accuracy": 0, "damage": 0, "crit": 0, "crit_avoid": 0,
			"dodge": 0, "strikes": 0, "damage_multiplier": 1.0},
		"flags": {
			"vantage":              false,
			"skip_effectiveness":   false,
			"attacker_ignores_def": 0.0,
			"attacker_ignores_res": 0.0,
			"defender_ignores_def": 0.0,
			"defender_ignores_res": 0.0,
			"lifesteal_pct":        0.0,
			"vengeance_bonus":      0,
		}
	}


# Populates atk_mod/def_mod/flags from all sources before the first attack.
# Steps: (1) UnitData.active_modifiers; (2) aura skills from all other units;
# (3) equip-type inventory items; (4) on_combat_start triggers.
func _collect_combat_modifiers(context: Dictionary) -> void:
	var attacker: Node = context["attacker"]
	var defender: Node = context["defender"]
	_apply_unit_data_modifiers(attacker, context["atk_mod"])
	_apply_unit_data_modifiers(defender, context["def_mod"])
	var sh := get_node_or_null("/root/SkillHandler")
	var gs := get_node_or_null("/root/GameState")
	# Aura skills from every other living unit on the map
	if sh and gs:
		for u in gs.all_units:
			if is_instance_valid(u) and u.data != null and u.data.hp > 0 \
					and u != attacker and u != defender:
				sh.apply_trigger(u, "on_combat_apply_modifiers", context)
	_apply_equip_item_modifiers(attacker, context["atk_mod"])
	_apply_equip_item_modifiers(defender, context["def_mod"])
	if sh:
		sh.apply_trigger(attacker, "on_combat_start", context)
		if not context.get("defender_skills_blocked", false):
			sh.apply_trigger(defender, "on_combat_start", context)


func _apply_unit_data_modifiers(unit: Node, mod_dict: Dictionary) -> void:
	if unit == null or unit.data == null:
		return
	for m in unit.data.active_modifiers:
		match m.get("stat", ""):
			"accuracy": mod_dict["accuracy"] += m.get("delta", 0)
			"damage":   mod_dict["damage"]   += m.get("delta", 0)
			"crit":     mod_dict["crit"]     += m.get("delta", 0)
			"dodge":    mod_dict["dodge"]    += m.get("delta", 0)


func _apply_equip_item_modifiers(unit: Node, mod_dict: Dictionary) -> void:
	if unit == null or unit.data == null:
		return
	for entry in unit.data.inventory:
		if entry.get("type", "") != "equip":
			continue
		mod_dict["accuracy"] += entry.get("accuracy", 0)
		mod_dict["damage"]   += entry.get("damage", 0)
		mod_dict["crit"]     += entry.get("crit", 0)
		mod_dict["dodge"]    += entry.get("dodge", 0)


# ── Weapon Triangle ──────────────────────────────────────────────────────────

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


# ── Effectiveness ────────────────────────────────────────────────────────────

# Returns true when the weapon has an effectiveness tag matching a target quality.
# Used as a fallback when compute_damage is called without a context dict.
func _is_effective(weapon: WeaponData, target: Node) -> bool:
	if weapon == null or target == null or not target.has_method("has_quality"):
		return false
	for tag in weapon.effect_tags:
		match tag:
			GameConstants.TAG_EFFECTIVE_FLYING:   if target.has_quality("flying"):   return true
			GameConstants.TAG_EFFECTIVE_ARMOURED: if target.has_quality("armoured"): return true
			GameConstants.TAG_EFFECTIVE_MOUNTED:  if target.has_quality("mounted"):  return true
			GameConstants.TAG_EFFECTIVE_DRAGON:   if target.has_quality("dragon"):   return true
			GameConstants.TAG_EFFECTIVE_BEAST:    if target.has_quality("beast"):    return true
	return false


# Returns 1.0 normally; 3.0 for effective weapon vs target; 4.0 with Giantkiller.
# Returns 1.0 if context.flags.skip_effectiveness is set (Dragonskin / Nullify).
# actor is the unit firing this attack (may differ from context["attacker"] on counter).
func _get_effectiveness_multiplier(weapon: WeaponData, target: Node,
		context: Dictionary, actor: Node = null) -> float:
	if context["flags"]["skip_effectiveness"]:
		return 1.0
	if not _is_effective(weapon, target):
		return 1.0
	# Use the actual attacker in this exchange so a defending Giantkiller gets the 4× too.
	var check_unit: Node = actor if actor != null else context["attacker"]
	if check_unit != null and check_unit.has_method("has_skill") \
			and check_unit.has_skill("giantkiller"):
		return 4.0
	return 3.0


# ── Core Stat Computations ───────────────────────────────────────────────────
# context keys read: "accuracy_bonus" (+hit), "dodge_bonus" (+defender dodge)

func compute_hit_pct(attacker: Node, defender: Node,
		weapon: WeaponData = null, context: Dictionary = {}) -> int:
	var w: WeaponData = weapon if weapon else (attacker.get_equipped_weapon() if attacker else null)
	if w == null:
		return 0
	var acc: int = attacker.accuracy(w) + _triangle_accuracy(attacker, defender) \
		+ context.get("accuracy_bonus", 0)
	var dodge: int = defender.dodge() + defender.get_terrain_dodge_bonus() \
		+ context.get("dodge_bonus", 0)
	return clampi(acc - dodge, 0, 100)


# context keys read: "damage_bonus", "effectiveness_mult" (default: auto-computed),
# "ignore_def_fraction" (0.0–1.0, for Luna etc.)
func compute_damage(attacker: Node, defender: Node,
		weapon: WeaponData = null, context: Dictionary = {}) -> int:
	var w: WeaponData = weapon if weapon else (attacker.get_equipped_weapon() if attacker else null)
	if w == null:
		return 0
	# Use provided effectiveness or compute from tags (backward compat for direct test calls)
	var eff_mult: float = context.get("effectiveness_mult",
		3.0 if _is_effective(w, defender) else 1.0)
	var mt: int = int(w.mt * eff_mult)
	# Use get_effective_stat so temporary stat modifiers (e.g. Resolve) are reflected in damage.
	var base_stat: int
	if attacker.has_method("get_effective_stat"):
		base_stat = attacker.get_effective_stat("magic") if w.uses_mag \
			else attacker.get_effective_stat("strength")
	else:
		base_stat = attacker.data.magic if w.uses_mag else attacker.data.strength
	var s_bonus: int = 1 if (attacker.has_method("_has_s_rank") and attacker._has_s_rank(w)) else 0
	var atk: int = base_stat + mt + s_bonus \
		+ _triangle_damage(attacker, defender) + context.get("damage_bonus", 0)
	var def_stat: int
	if defender.has_method("get_effective_stat"):
		def_stat = defender.get_effective_stat("resistance") if w.uses_mag \
			else defender.get_effective_stat("defense")
	else:
		def_stat = defender.data.resistance if w.uses_mag else defender.data.defense
	var ignore_frac: float = context.get("ignore_def_fraction", 0.0)
	var effective_def: int = int(def_stat * (1.0 - ignore_frac))
	var def_bonus: int = defender.get_terrain_def_bonus()
	return maxi(0, atk - effective_def - def_bonus)


# context keys read: "crit_bonus" (net modifier, attacker crit mod minus defender crit_avoid mod)
func compute_crit_pct(attacker: Node, defender: Node,
		weapon: WeaponData = null, context: Dictionary = {}) -> int:
	var w: WeaponData = weapon if weapon else (attacker.get_equipped_weapon() if attacker else null)
	return clampi(attacker.crit_rate(w) - defender.crit_avoid() \
		+ context.get("crit_bonus", 0), 0, 100)


# ── Sequence Logic ───────────────────────────────────────────────────────────

func can_counterattack(defender: Node, attacker_tile: Vector2i) -> bool:
	var w: WeaponData = defender.get_equipped_weapon()
	if w == null:
		return false
	var dist: int = absi(defender.tile_position.x - attacker_tile.x) \
		+ absi(defender.tile_position.y - attacker_tile.y)
	return dist >= w.get_range_min(defender) and dist <= w.get_range_max(defender)


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


# ── EXP ─────────────────────────────────────────────────────────────────────

func calculate_exp(attacker: Node, defender: Node, killed: bool) -> int:
	var diff: int = attacker.data.level - defender.data.level
	var idx: int = clampi(diff + 6, 0, 12)
	return _EXP_TABLE[idx][0] if killed else _EXP_TABLE[idx][1]


# ── Single-Attack Resolution ─────────────────────────────────────────────────

# Resolves one attack roll. is_counter=true means actor is the defending side.
# target_sim_hp is needed for Miracle to check whether the blow is lethal.
# Returns { attacker, defender, weapon, hit, crit, damage, loses_durability, is_counter }
func _resolve_single_attack(actor: Node, target: Node, context: Dictionary,
		is_counter: bool, target_sim_hp: int) -> Dictionary:
	var sh := get_node_or_null("/root/SkillHandler")
	var weapon: WeaponData = context["defender_weapon"] if is_counter else context["attacker_weapon"]
	var actor_mod: Dictionary = context["def_mod"] if is_counter else context["atk_mod"]
	var target_mod: Dictionary = context["atk_mod"] if is_counter else context["def_mod"]
	var blocked_key: String = "defender_skills_blocked" if is_counter else "attacker_skills_blocked"

	if sh and not context.get(blocked_key, false):
		sh.apply_trigger(actor, "on_attack", context)

	var hit_ctx := {
		"accuracy_bonus": actor_mod["accuracy"],
		"dodge_bonus":    target_mod["dodge"],
	}
	var eff_mult: float = _get_effectiveness_multiplier(weapon, target, context, actor)
	var ignore_key: String = "defender_ignores_def" if is_counter else "attacker_ignores_def"
	var dmg_ctx := {
		"damage_bonus":       actor_mod["damage"],
		"effectiveness_mult": eff_mult,
		"ignore_def_fraction": context["flags"].get(ignore_key, 0.0),
	}
	var crit_ctx := {
		"crit_bonus": actor_mod["crit"] - target_mod["crit_avoid"],
	}

	var hit_pct  := compute_hit_pct(actor, target, weapon, hit_ctx)
	var crit_pct := compute_crit_pct(actor, target, weapon, crit_ctx)
	var base_dmg := compute_damage(actor, target, weapon, dmg_ctx)

	var did_hit: bool  = (randi() % 100) < hit_pct
	var did_crit: bool = false
	var damage: int    = 0

	if did_hit:
		if sh and not context.get(blocked_key, false):
			sh.apply_trigger(actor, "on_hit", context)
		did_crit = (randi() % 100) < crit_pct
		damage = base_dmg * 3 if did_crit else base_dmg
		var dmg_mult: float = actor_mod["damage_multiplier"]
		if dmg_mult != 1.0:
			damage = maxi(0, int(damage * dmg_mult))

		# on_damaged trigger (Miracle uses current_sim_hp to detect lethal hits)
		if sh:
			var is_target_blocked: bool = context.get(
				"attacker_skills_blocked" if is_counter else "defender_skills_blocked", false)
			if not is_target_blocked:
				var dmg_ctx2 := {
					"damage": damage, "current_sim_hp": target_sim_hp,
					"unit": target, "attacker": actor, "defender": target, "weapon": weapon,
				}
				dmg_ctx2 = sh.apply_trigger(target, "on_damaged", dmg_ctx2)
				damage = dmg_ctx2.get("damage", damage)

	# on_kill
	if did_hit and damage >= target_sim_hp and sh and not context.get(blocked_key, false):
		sh.apply_trigger(actor, "on_kill", context)

	var loses_use: bool = false
	if weapon != null:
		loses_use = (weapon.weapon_type in _ALWAYS_USE_DURABILITY) or did_hit

	return {
		"attacker":        actor,
		"defender":        target,
		"weapon":          weapon,
		"hit":             did_hit,
		"crit":            did_crit,
		"damage":          damage,
		"loses_durability": loses_use,
		"is_counter":      is_counter,
	}


# ── Skill Counter Helpers ────────────────────────────────────────────────────

func _skill_available(unit: Node, skill: SkillData) -> bool:
	if skill.max_uses_per_map == -1:
		return true
	return unit.get_skill_uses_remaining(skill.effect_id, skill.max_uses_per_map) > 0


func _consume_skill(unit: Node, skill: SkillData) -> void:
	if skill.max_uses_per_map != -1:
		unit.consume_skill_use(skill.effect_id)


# ── Preview (no RNG, no side effects) ────────────────────────────────────────

# Snapshot the mutable UnitData fields that any on_combat_start skill could touch.
# Restored after _collect_combat_modifiers() so preview has zero side effects on live state.
func _snapshot_unit_state(unit: Node) -> Dictionary:
	if unit == null or unit.data == null:
		return {}
	return {
		"hp":                  unit.data.hp,
		"active_modifiers":    unit.data.active_modifiers.duplicate(true),
		"skill_use_counters":  unit.data.skill_use_counters.duplicate(true),
	}


func _restore_unit_state(unit: Node, snap: Dictionary) -> void:
	if unit == null or unit.data == null or snap.is_empty():
		return
	unit.data.hp                 = snap["hp"]
	unit.data.active_modifiers   = snap["active_modifiers"]
	unit.data.skill_use_counters = snap["skill_use_counters"]


func preview_combat(attacker: Node, defender: Node) -> Dictionary:
	var atk_snap := _snapshot_unit_state(attacker)
	var def_snap := _snapshot_unit_state(defender)
	var context := _build_combat_context(attacker, defender)
	_collect_combat_modifiers(context)
	# Restore immediately — preview must not leave any trace on live unit state.
	_restore_unit_state(attacker, atk_snap)
	_restore_unit_state(defender, def_snap)
	var aw: WeaponData = context["attacker_weapon"]
	var dw: WeaponData = context["defender_weapon"]
	var can_counter: bool = dw != null
	var follow_up := get_follow_up_attacker(attacker, defender)
	var atk_strikes: int = (aw.strikes_per_attack if aw else 1) + context["atk_mod"]["strikes"]
	var def_strikes: int = ((dw.strikes_per_attack if dw else 1) + context["def_mod"]["strikes"]) \
		if can_counter else 0

	var eff_atk: float = _get_effectiveness_multiplier(aw, defender, context, attacker)
	var eff_def: float = _get_effectiveness_multiplier(dw, attacker, context, defender) if can_counter else 1.0

	var atk_hit_ctx  := {"accuracy_bonus": context["atk_mod"]["accuracy"],
		"dodge_bonus": context["def_mod"]["dodge"]}
	var def_hit_ctx  := {"accuracy_bonus": context["def_mod"]["accuracy"],
		"dodge_bonus": context["atk_mod"]["dodge"]}
	var atk_dmg_ctx  := {"damage_bonus": context["atk_mod"]["damage"], "effectiveness_mult": eff_atk}
	var def_dmg_ctx  := {"damage_bonus": context["def_mod"]["damage"], "effectiveness_mult": eff_def}
	var atk_crit_ctx := {"crit_bonus": context["atk_mod"]["crit"] - context["def_mod"]["crit_avoid"]}
	var def_crit_ctx := {"crit_bonus": context["def_mod"]["crit"] - context["atk_mod"]["crit_avoid"]}

	return {
		"attacker_hit":     compute_hit_pct(attacker, defender, aw, atk_hit_ctx),
		"attacker_damage":  compute_damage(attacker, defender, aw, atk_dmg_ctx),
		"attacker_crit":    compute_crit_pct(attacker, defender, aw, atk_crit_ctx),
		"attacker_attacks": (2 if follow_up == attacker else 1) * atk_strikes,
		"can_counter":      can_counter,
		"defender_hit":     compute_hit_pct(defender, attacker, dw, def_hit_ctx) if can_counter else 0,
		"defender_damage":  compute_damage(defender, attacker, dw, def_dmg_ctx) if can_counter else 0,
		"defender_crit":    compute_crit_pct(defender, attacker, dw, def_crit_ctx) if can_counter else 0,
		"defender_attacks": ((2 if follow_up == defender else 1) * def_strikes) if can_counter else 0,
		"attacker_weapon":  aw,
		"defender_weapon":  dw,
	}


# ── Full RNG Resolution ──────────────────────────────────────────────────────

func resolve_combat(attacker: Node, defender: Node) -> Dictionary:
	var context := _build_combat_context(attacker, defender)
	_collect_combat_modifiers(context)
	var sh := get_node_or_null("/root/SkillHandler")

	var aw: WeaponData = context["attacker_weapon"]
	var dw: WeaponData = context["defender_weapon"]
	var can_counter: bool = dw != null
	var atk_strikes: int = (aw.strikes_per_attack if aw else 1) + context["atk_mod"]["strikes"]
	var def_strikes: int = ((dw.strikes_per_attack if dw else 1) + context["def_mod"]["strikes"]) \
		if can_counter else 0
	# Save original before vantage may zero it — follow-up uses the original count.
	var original_def_strikes: int = def_strikes
	var follow_up: Node = get_follow_up_attacker(attacker, defender)

	var exchanges: Array = []
	var atk_sim_hp: int = attacker.data.hp
	var def_sim_hp: int = defender.data.hp

	# Vantage: defender attacks first (set by _apply_vantage in _collect_combat_modifiers)
	if context["flags"]["vantage"] and can_counter:
		for _i in def_strikes:
			if atk_sim_hp <= 0:
				break
			var ex := _resolve_single_attack(defender, attacker, context, true, atk_sim_hp)
			if ex["hit"]:
				atk_sim_hp -= ex["damage"]
			exchanges.append(ex)
		def_strikes = 0  # defender's attacks are spent

	# Attacker's strikes
	for _i in atk_strikes:
		if def_sim_hp <= 0:
			break
		var ex := _resolve_single_attack(attacker, defender, context, false, def_sim_hp)
		if ex["hit"]:
			def_sim_hp -= ex["damage"]
		exchanges.append(ex)

	# Defender counter (skipped if Vantage already used all counter strikes)
	if can_counter and def_strikes > 0 and atk_sim_hp > 0:
		for _i in def_strikes:
			if atk_sim_hp <= 0:
				break
			var ex := _resolve_single_attack(defender, attacker, context, true, atk_sim_hp)
			if ex["hit"]:
				atk_sim_hp -= ex["damage"]
			exchanges.append(ex)

	# Follow-up — loops over all strikes so Brave weapons get their full count.
	if follow_up != null:
		var fu_target: Node  = defender if follow_up == attacker else attacker
		var fu_sim_hp: int   = atk_sim_hp if follow_up == attacker else def_sim_hp
		var tgt_sim_hp: int  = def_sim_hp if follow_up == attacker else atk_sim_hp
		var fu_strikes: int  = atk_strikes if follow_up == attacker else original_def_strikes
		var is_fu_counter: bool = (follow_up == defender)
		if fu_sim_hp > 0 and tgt_sim_hp > 0:
			for _i in fu_strikes:
				if tgt_sim_hp <= 0:
					break
				var ex := _resolve_single_attack(follow_up, fu_target, context, is_fu_counter, tgt_sim_hp)
				ex["is_follow_up"] = true
				if ex["hit"]:
					tgt_sim_hp -= ex["damage"]
					if follow_up == attacker:
						def_sim_hp = tgt_sim_hp
					else:
						atk_sim_hp = tgt_sim_hp
				exchanges.append(ex)

	if sh:
		sh.apply_trigger(attacker, "on_combat_end", context)
		sh.apply_trigger(defender, "on_combat_end", context)

	var defender_died: bool = def_sim_hp <= 0
	var attacker_died: bool = atk_sim_hp <= 0
	var atk_dealt: bool = exchanges.any(func(e): return e["attacker"] == attacker and e["hit"])
	var def_dealt: bool = exchanges.any(func(e): return e["attacker"] == defender and e["hit"])

	return {
		"exchanges":     exchanges,
		"attacker_died": attacker_died,
		"defender_died": defender_died,
		# EXP only for actual contribution: attacker must have landed at least one hit.
		"attacker_exp":  calculate_exp(attacker, defender, defender_died) if atk_dealt else 0,
		"defender_exp":  calculate_exp(defender, attacker, attacker_died) if (def_dealt and not attacker_died) else 0,
		"context":       context,
	}


# ── Apply Combat Result ──────────────────────────────────────────────────────

# Applies the result from resolve_combat: HP changes, durability, EXP, wEXP, death.
func apply_combat_result(result: Dictionary, attacker: Node, defender: Node) -> void:
	var bus := get_node_or_null("/root/EventBus") if is_inside_tree() else null
	if bus:
		bus.combat_started.emit(attacker, defender)

	# Track broken weapons per unit so subsequent exchanges with the same weapon
	# are skipped — a unit whose weapon broke mid-combat can't keep attacking.
	var broken: Dictionary = {}  # Node -> weapon_id String

	for exchange in result["exchanges"]:
		var atk: Node          = exchange["attacker"]
		var def_unit: Node     = exchange["defender"]
		var weapon: WeaponData = exchange.get("weapon", null)
		var weapon_id: String  = weapon.id if weapon != null else ""

		# Weapon broke in an earlier exchange — skip this attack entirely.
		if weapon_id != "" and broken.get(atk, "") == weapon_id:
			continue

		if exchange["loses_durability"] and atk.has_method("use_weapon_durability"):
			if atk.use_weapon_durability(weapon_id):
				broken[atk] = weapon_id

		if exchange["hit"]:
			if weapon != null and atk.has_method("add_wexp"):
				atk.add_wexp(weapon.weapon_type, weapon.wexp)
			def_unit.take_damage(exchange["damage"])
			def_unit.data.damage_taken_this_map += exchange["damage"]
		# No break here — the full exchange list is iterated so both units can die
		# in a mutual-kill scenario and both get handle_death() called below.

	# Award EXP before calling handle_death (queue_free is deferred; nodes are still valid).
	if attacker.is_inside_tree() and result.get("attacker_exp", 0) > 0 \
			and not result["attacker_died"]:
		attacker.add_exp(result["attacker_exp"])
	if defender.is_inside_tree() and result.get("defender_exp", 0) > 0 \
			and not result["defender_died"]:
		defender.add_exp(result["defender_exp"])

	# Clear one-fight buffs from both sides after combat concludes.
	if attacker.has_method("clear_combat_modifiers"):
		attacker.clear_combat_modifiers()
	if defender.has_method("clear_combat_modifiers"):
		defender.clear_combat_modifiers()

	# Handle deaths after all exchanges — defender first so kill credit stays with attacker.
	if result["defender_died"] and defender.has_method("handle_death"):
		defender.handle_death()
	if result["attacker_died"] and attacker.has_method("handle_death"):
		attacker.handle_death()

	if bus:
		bus.combat_resolved.emit(attacker, defender, result)
