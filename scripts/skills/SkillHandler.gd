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
func apply_trigger(unit: Node, trigger: String, context: Dictionary) -> Dictionary:
	if unit == null or unit.data == null:
		return context
	var dm := get_node_or_null("/root/DataManager")
	if dm == null:
		return context
	for skill_id in unit.data.skills:
		var skill: SkillData = dm.get_skill(skill_id)
		if skill == null:
			continue
		if skill.trigger == trigger:
			context = _execute_skill(skill, unit, context)
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
		"charm":      return _apply_charm(skill, unit, context)
		"anathema":   return _apply_anathema(skill, unit, context)
		"daunt":      return _apply_daunt(skill, unit, context)
		_:
			push_warning("SkillHandler: unknown effect_id '%s'" % skill.effect_id)
	return context


# ---- Individual skill implementations ----

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


# LUK% chance to halve a fatal blow (on_damaged trigger).
func _apply_miracle(_skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	var dmg: int = context.get("damage", 0)
	if dmg <= 0:
		return context
	var sim_hp: int = context.get("current_sim_hp", unit.data.hp)
	if dmg < sim_hp:
		return context
	var luk: int = unit.data.luck if unit.data else 0
	# Guarantee survival: reduce damage to leave exactly 1 HP remaining.
	if (randi() % 100) < luk:
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


# +N hit when opponent is wielding the matching weapon type.
func _apply_breaker(skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	var is_atk: bool = (unit == context.get("attacker"))
	var opp_w: WeaponData = context.get("defender_weapon") if is_atk else context.get("attacker_weapon")
	if opp_w == null or opp_w.weapon_type != skill.effect_params.get("weapon_type", ""):
		return context
	var mod: Dictionary = context["atk_mod"] if is_atk else context["def_mod"]
	mod["accuracy"] += skill.effect_params.get("hit", 50)
	return context


# Generic stat bonus applied from effect_params.
func _apply_stat_bonus(skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	var mod: Dictionary = context["atk_mod"] if (unit == context.get("attacker")) else context["def_mod"]
	var p: Dictionary = skill.effect_params
	if p.has("hit"):  mod["accuracy"] += int(p["hit"])
	if p.has("crit"): mod["crit"]     += int(p["crit"])
	if p.has("str"):  mod["damage"]   += int(p["str"])
	return context


# ---- Aura skills (on_combat_apply_modifiers) ----
# These fire once per nearby unit before combat; unit is the aura bearer.

func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


# +10 hit and +10 dodge to allies within radius.
func _apply_charm(skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	var attacker: Node = context.get("attacker")
	var defender: Node = context.get("defender")
	if attacker == null or defender == null:
		return context
	var radius: int = skill.effect_params.get("radius", 3)
	if unit.team == attacker.team \
			and _manhattan(unit.tile_position, attacker.tile_position) <= radius:
		context["atk_mod"]["accuracy"] += 10
		context["atk_mod"]["dodge"]    += 10
	if unit.team == defender.team \
			and _manhattan(unit.tile_position, defender.tile_position) <= radius:
		context["def_mod"]["accuracy"] += 10
		context["def_mod"]["dodge"]    += 10
	return context


# -10 hit and -10 dodge to enemies within radius.
func _apply_anathema(skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	var attacker: Node = context.get("attacker")
	var defender: Node = context.get("defender")
	if attacker == null or defender == null:
		return context
	var radius: int = skill.effect_params.get("radius", 3)
	if unit.team != attacker.team \
			and _manhattan(unit.tile_position, attacker.tile_position) <= radius:
		context["atk_mod"]["accuracy"] -= 10
		context["atk_mod"]["dodge"]    -= 10
	if unit.team != defender.team \
			and _manhattan(unit.tile_position, defender.tile_position) <= radius:
		context["def_mod"]["accuracy"] -= 10
		context["def_mod"]["dodge"]    -= 10
	return context


# -10 hit and -10 crit to enemies within radius.
func _apply_daunt(skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	var attacker: Node = context.get("attacker")
	var defender: Node = context.get("defender")
	if attacker == null or defender == null:
		return context
	var radius: int = skill.effect_params.get("radius", 3)
	if unit.team != attacker.team \
			and _manhattan(unit.tile_position, attacker.tile_position) <= radius:
		context["atk_mod"]["accuracy"] -= 10
		context["atk_mod"]["crit"]     -= 10
	if unit.team != defender.team \
			and _manhattan(unit.tile_position, defender.tile_position) <= radius:
		context["def_mod"]["accuracy"] -= 10
		context["def_mod"]["crit"]     -= 10
	return context
