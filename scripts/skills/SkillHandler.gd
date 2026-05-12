extends Node
# Central dispatcher for skill effects. Called by CombatResolver, TurnManager,
# GridManager, etc. All skill logic lives here; callers pass a context dict and
# receive it back modified.

# ---- Movement Override Stubs (A4 — implement in M9) ----

# Returns an override move cost if a skill applies, -1 if no override active.
# Checked by GridManager.get_move_cost() before the terrain table.
# Skills: Acrobat (all non-wall → 1), Swiftfoot (penalized terrain → 1), Nimble (Cat).
func get_move_cost_override(_unit: Node, _terrain: String) -> int:
	return -1  # [STUB — implement in M9]


# Returns true if the unit has the Pass skill (Trickster occult), allowing
# movement through enemy-occupied tiles (but still can't end turn on them).
func can_pass_through_enemies(_unit: Node) -> bool:
	return false  # [STUB — implement in M9]


# Returns true if the unit has the Phasing skill (Sage promotion), allowing
# movement through wall tiles once per turn.
func can_phase_through(_unit: Node, _terrain: String) -> bool:
	return false  # [STUB — implement in M9]

# Called at trigger points (on_combat_start, passive, on_damaged, start_of_turn, etc.)
# Iterates the unit's skill list and fires every matching skill.
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
		_:
			push_warning("SkillHandler: unknown effect_id '%s'" % skill.effect_id)
	return context


# ---- Individual skill implementations ----

# Restore 10% max HP at start of turn.
func _apply_renewal(_skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	var amount: int = maxi(1, floori(unit.data.max_hp * 0.10))
	unit.heal(amount)
	return context


# This unit attacks first in combat (even when defending).
func _apply_vantage(_skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	context["vantage_unit"] = unit
	return context


# Negate all battle-related skills on the opponent for this combat.
func _apply_nihil(_skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	if unit == context.get("attacker"):
		context["defender_skills_blocked"] = true
	else:
		context["attacker_skills_blocked"] = true
	return context


# +50% STR/MAG/SKL/SPD when HP ≤ 50% (passive, applied per-attack in CombatResolver).
func _apply_resolve(_skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	if unit.data.hp * 2 > unit.data.max_hp:
		return context  # not at threshold
	var w: WeaponData = context.get("weapon", null)
	# Damage bonus: +50% of STR or MAG
	var base_stat: int = unit.data.magic if (w != null and w.uses_mag) else unit.data.strength
	context["damage_bonus"] = context.get("damage_bonus", 0) + floori(base_stat * 0.5)
	# Accuracy bonus: SKL portion × 2 (since accuracy uses SKL×2)
	context["accuracy_bonus"] = context.get("accuracy_bonus", 0) + floori(unit.data.skill * 0.5) * 2
	return context


# +50 Critical when HP ≤ 50% (passive).
func _apply_wrath(_skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	if unit.data.hp * 2 <= unit.data.max_hp:
		context["crit_bonus"] = context.get("crit_bonus", 0) + 50
	return context


# LUK% chance to halve a fatal blow (on_damaged trigger).
func _apply_miracle(_skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	var dmg: int = context.get("damage", 0)
	if dmg <= 0:
		return context
	# Only activates if the hit would be fatal
	if dmg < unit.data.hp:
		return context
	var luk: int = unit.data.luck if unit.data else 0
	if (randi() % 100) < luk:
		context["damage"] = maxi(1, dmg / 2)
	return context


# Generic stat bonus (for stat_bonus effect_id with effect_params dict).
func _apply_stat_bonus(skill: SkillData, _unit: Node, context: Dictionary) -> Dictionary:
	var params: Dictionary = skill.effect_params
	if params.has("hit"):  context["accuracy_bonus"] = context.get("accuracy_bonus", 0) + int(params["hit"])
	if params.has("crit"): context["crit_bonus"]     = context.get("crit_bonus", 0)     + int(params["crit"])
	if params.has("str"):  context["damage_bonus"]   = context.get("damage_bonus", 0)   + int(params["str"])
	return context
