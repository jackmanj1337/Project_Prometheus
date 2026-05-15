extends Node
# Central dispatcher for skill effects. Called by CombatResolver, TurnManager,
# GridManager, etc. All skill logic lives here; callers pass a context dict and
# receive it back modified.

# ---- Movement Override Stubs (A4 — implement in M9) ----

func get_move_cost_override(_unit: Node, _terrain: String) -> int:
	return -1  # [STUB — implement in M9]


func can_pass_through_enemies(_unit: Node) -> bool:
	return false  # [STUB — implement in M9]


func can_phase_through(_unit: Node, _terrain: String) -> bool:
	return false  # [STUB — implement in M9]


# Called at trigger points (on_combat_start, on_combat_apply_modifiers, on_damaged,
# start_of_turn, etc.). Iterates the unit's skill list and fires every matching skill.
# Rolls activation_chance_stat / activation_divisor before dispatching — a single
# activation path used by all skills so per-skill duplicate rolls are not needed.
func apply_trigger(unit: Node, trigger: String, context: Dictionary) -> Dictionary:
	if unit == null or not is_instance_valid(unit) or unit.data == null:
		return context
	var dm := get_node_or_null("/root/DataManager")
	if dm == null:
		return context
	# Check both equipped skills and permanent mastery skills.
	var all_skills: Array[String] = []
	all_skills.append_array(unit.data.skills)
	all_skills.append_array(unit.data.mastery_skills)
	for skill_id in all_skills:
		var skill: SkillData = dm.get_skill(skill_id)
		if skill == null:
			continue
		if skill.trigger != trigger:
			continue
		# Enforce per-map use limit (C-3 fix: was never checked for non-combat triggers).
		if skill.max_uses_per_map != -1:
			var used: int = unit.data.skill_use_counters.get(skill.effect_id, 0)
			if used >= skill.max_uses_per_map:
				continue
		# Roll activation chance from data if a stat is specified.
		if skill.activation_chance_stat != "":
			var stat_val: int = unit.get_effective_stat(skill.activation_chance_stat)
			var chance: int = stat_val / max(1, skill.activation_divisor)
			if (randi() % 100) >= chance:
				continue
		context = _execute_skill(skill, unit, context)
		if skill.max_uses_per_map != -1:
			unit.data.skill_use_counters[skill.effect_id] = \
				unit.data.skill_use_counters.get(skill.effect_id, 0) + 1
	return context


func _execute_skill(skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	match skill.effect_id:
		"renewal":    return _apply_renewal(skill, unit, context)
		"vantage":    return _apply_vantage(skill, unit, context)
		"nihil":      return _apply_nihil(skill, unit, context)
		"resolve":    return _apply_resolve(skill, unit, context)
		"wrath":      return _apply_wrath(skill, unit, context)
		"miracle":    return _apply_miracle(skill, unit, context)
		"stat_bonus": return _apply_stat_bonus(skill, unit, context)
		"faire":      return _apply_faire(skill, unit, context)
		"breaker":    return _apply_breaker(skill, unit, context)
		"charm":         return _apply_charm(skill, unit, context)
		"anathema":      return _apply_anathema(skill, unit, context)
		"daunt":         return _apply_daunt(skill, unit, context)
		"s_rank_mastery": return _apply_s_rank_mastery(skill, unit, context)
		_:
			push_warning("SkillHandler: unknown effect_id '%s'" % skill.effect_id)
	return context


# ---- Individual skill implementations ----

# S-rank mastery: +Hit, +Crit, +Dmg when attacking with a weapon type the unit holds at S rank.
# Fires once per combat (on_combat_start); bonuses flow through atk_mod/def_mod so they appear
# correctly in previews and are cleared by clear_combat_modifiers() after the fight.
func _apply_s_rank_mastery(skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	var is_atk: bool = (unit == context.get("attacker"))
	var w: WeaponData = context.get("attacker_weapon") if is_atk else context.get("defender_weapon")
	if w == null:
		return context
	# Only apply when the unit actually has S rank in the weapon they're currently wielding.
	if not unit.data.proficiencies.has(w.weapon_type):
		return context
	if unit.data.proficiencies[w.weapon_type].get("rank", "E") != "S":
		return context
	var mod: Dictionary = context["atk_mod"] if is_atk else context["def_mod"]
	mod["accuracy"] += skill.effect_params.get("hit_bonus", 10)
	mod["crit"]     += skill.effect_params.get("crit_bonus", 5)
	mod["damage"]   += skill.effect_params.get("dmg_bonus", 1)
	return context

func _apply_renewal(_skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	var amount: int = maxi(1, floori(unit.data.max_hp * 0.10))
	unit.heal(amount)
	return context


# Defender attacks first this combat. Only fires for the defending unit.
func _apply_vantage(_skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	if unit != context.get("defender"):
		return context
	context["flags"]["vantage"] = true
	return context


# Negate the opponent's battle skills this combat.
func _apply_nihil(_skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	if unit == context.get("attacker"):
		context["defender_skills_blocked"] = true
	else:
		context["attacker_skills_blocked"] = true
	return context


# +50% STR, MAG, SKL, SPD when HP ≤ 50%. Applied as "combat" duration modifiers so they flow
# through all stat functions (damage, accuracy, follow-up threshold) correctly and are
# automatically cleared by CombatResolver.clear_combat_modifiers() after the fight.
func _apply_resolve(_skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	if unit.data.hp * 2 > unit.data.max_hp:
		return context
	unit.add_modifier("strength",  floori(unit.data.strength * 0.5), "resolve", -1, "combat")
	unit.add_modifier("magic",     floori(unit.data.magic    * 0.5), "resolve", -1, "combat")
	unit.add_modifier("skill",     floori(unit.data.skill    * 0.5), "resolve", -1, "combat")
	unit.add_modifier("speed",     floori(unit.data.speed    * 0.5), "resolve", -1, "combat")
	return context


# +50 Critical when HP ≤ 50%. Writes to atk_mod or def_mod based on role.
func _apply_wrath(_skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	if unit.data.hp * 2 > unit.data.max_hp:
		return context
	var mod: Dictionary = context["atk_mod"] if (unit == context.get("attacker")) else context["def_mod"]
	mod["crit"] += 50
	return context


# Survive a fatal blow at 1 HP (on_damaged trigger).
# Activation roll is handled by apply_trigger — this function only runs when the proc succeeds.
func _apply_miracle(_skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	var dmg: int = context.get("damage", 0)
	if dmg <= 0:
		return context
	var sim_hp: int = context.get("current_sim_hp", unit.data.hp)
	if dmg < sim_hp:
		return context
	# Guarantee survival: reduce damage to leave exactly 1 HP remaining.
	context["damage"] = sim_hp - 1
	return context


# +N damage when attacking with the matching weapon type.
func _apply_faire(skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	var is_atk: bool = (unit == context.get("attacker"))
	var w: WeaponData = context.get("attacker_weapon") if is_atk else context.get("defender_weapon")
	if w == null or w.weapon_type != skill.effect_params.get("weapon_type", ""):
		return context
	var mod: Dictionary = context["atk_mod"] if is_atk else context["def_mod"]
	mod["damage"] += skill.effect_params.get("bonus", 5)
	return context


# Attacker side: +N hit vs opponent weapon type. Defender side: +N dodge vs that type.
func _apply_breaker(skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	var is_atk: bool = (unit == context.get("attacker"))
	var opp_w: WeaponData = context.get("defender_weapon") if is_atk else context.get("attacker_weapon")
	if opp_w == null or opp_w.weapon_type != skill.effect_params.get("weapon_type", ""):
		return context
	var mod: Dictionary = context["atk_mod"] if is_atk else context["def_mod"]
	if is_atk:
		mod["accuracy"] += skill.effect_params.get("hit", 50)
	else:
		mod["dodge"] += skill.effect_params.get("dodge", 50)
	return context


# Generic stat bonus from effect_params (hit/crit/str keys).
# No skill .tres uses this yet — implement fully in M9.
func _apply_stat_bonus(_skill: SkillData, _unit: Node, context: Dictionary) -> Dictionary:
	return context  # [STUB — M9]


# ---- Aura skills (on_combat_apply_modifiers) ----
# These fire once per nearby unit before combat; unit is the aura bearer.
# No skill .tres uses these yet — implement fully in M9 (also fix §2.1 charm double-count then).

func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


# +10 hit and +10 dodge to allies within radius.
func _apply_charm(_skill: SkillData, _unit: Node, context: Dictionary) -> Dictionary:
	return context  # [STUB — M9]


# -10 hit and -10 dodge to enemies within radius.
func _apply_anathema(_skill: SkillData, _unit: Node, context: Dictionary) -> Dictionary:
	return context  # [STUB — M9]


# -10 hit and -10 crit to enemies within radius.
func _apply_daunt(_skill: SkillData, _unit: Node, context: Dictionary) -> Dictionary:
	return context  # [STUB — M9]
