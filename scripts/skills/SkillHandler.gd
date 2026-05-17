extends Node
# Central dispatcher for skill effects. Called by CombatResolver, TurnManager,
# GridManager, etc. All skill logic lives here; callers pass a context dict and
# receive it back modified.

# Dispatch table: effect_id → handler Callable. Built in _ready() so methods are bound.
# Add new skills here — typos are a startup error rather than a silent no-op.
var _dispatch: Dictionary = {}

# Per-combat skill use counters: effect_id → times fired this combat. Reset by
# reset_combat_uses() at the start of each combat (see CombatResolver). Separate
# from UnitData.skill_use_counters, which is the per-map tally.
var _combat_skill_uses: Dictionary = {}

# Skills Nihil cannot negate — they still activate when this unit's combat skills
# are blocked. Matched against SkillData.id. s_rank_mastery is an earned, permanent
# mastery bonus (innate, not a battle skill). nihil's own negate pre-pass is already
# structurally exempt (it runs before the blocked flags are read), but it is listed
# here so the whole exemption rule is stated in one place.
const NIHIL_EXEMPT_SKILLS: Array[String] = ["s_rank_mastery", "nihil"]


func _ready() -> void:
	_dispatch = {
		"renewal":       _apply_renewal,
		"vantage":       _apply_vantage,
		"nihil":         _apply_nihil,
		"resolve":       _apply_resolve,
		"wrath":         _apply_wrath,
		"miracle":       _apply_miracle,
		"stat_bonus":    _apply_stat_bonus,
		"faire":         _apply_faire,
		"breaker":       _apply_breaker,
		"charm":         _apply_charm,
		"anathema":      _apply_anathema,
		"daunt":         _apply_daunt,
		"s_rank_mastery": _apply_s_rank_mastery,
	}


# ---- Movement Override Stubs (A4 — implement in M9) ----

func get_move_cost_override(_unit: Node, _terrain: String) -> int:
	return -1  # [STUB — implement in M9]


func can_pass_through_enemies(_unit: Node) -> bool:
	return false  # [STUB — implement in M9]


func can_phase_through(_unit: Node, _terrain: String) -> bool:
	return false  # [STUB — implement in M9]


# Resets the per-combat skill use counters. CombatResolver calls this once at the
# start of every combat (via _collect_combat_modifiers) so max_uses_per_combat is
# scoped to a single fight.
func reset_combat_uses() -> void:
	_combat_skill_uses.clear()


# Called at trigger points (on_combat_start, on_combat_apply_modifiers, on_damaged,
# start_of_turn, etc.). Iterates the unit's skill list and fires every matching skill.
# Rolls activation_chance_stat / activation_divisor before dispatching — a single
# activation path used by all skills so per-skill duplicate rolls are not needed.
#
# preview = true (combat preview only): a skill with a random activation roll is
# excluded from the forecast entirely, even at 100%+ chance, so the preview never
# gambles on a proc. Deterministic skills (HP-threshold buffs like Resolve/Wrath,
# weapon-type bonuses) still apply, so the forecast reflects guaranteed effects.
#
# skills_blocked = true (set by an opponent's Nihil): only skills in
# NIHIL_EXEMPT_SKILLS fire; every other skill on this trigger is skipped. Always
# false for non-combat triggers, which Nihil does not affect.
#
# dry_run = true (combat preview only): skill effects still run so the forecast is
# accurate, but the per-map / per-combat use counters are NOT written — so opening a
# combat preview never burns a limited-use skill's uses (the skill effect is restored
# along with the rest of unit state by preview_combat's snapshot).
func apply_trigger(unit: Node, trigger: String, context: Dictionary,
		preview: bool = false, skills_blocked: bool = false,
		dry_run: bool = false) -> Dictionary:
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
		# Nihil: when this unit's combat skills are negated, fire only the exempt
		# ones. NIHIL_EXEMPT_SKILLS is matched by skill id.
		if skills_blocked and not (skill.id in NIHIL_EXEMPT_SKILLS):
			continue
		# Combat preview must be deterministic — skip any skill that rolls to activate.
		if preview and skill.activation_chance_stat != "":
			continue
		# Enforce per-map use limit (C-3 fix: was never checked for non-combat triggers).
		if skill.max_uses_per_map != -1:
			var used: int = unit.data.skill_use_counters.get(skill.effect_id, 0)
			if used >= skill.max_uses_per_map:
				continue
		# Enforce per-combat use limit (scoped by reset_combat_uses()).
		if skill.max_uses_per_combat != -1:
			var combat_used: int = _combat_skill_uses.get(skill.effect_id, 0)
			if combat_used >= skill.max_uses_per_combat:
				continue
		# Roll activation chance from data if a stat is specified.
		if skill.activation_chance_stat != "":
			var stat_val: int = unit.get_effective_stat(skill.activation_chance_stat)
			var chance: int = stat_val / max(1, skill.activation_divisor)
			if (randi() % 100) >= chance:
				continue
		# Only count a use when the effect actually committed: a handler that
		# declines (wrong weapon type, HP above threshold, Miracle on a non-lethal
		# hit) returns false and must not burn a limited use.
		var fired: bool = _execute_skill(skill, unit, context)
		# dry_run suppresses counter persistence only — the effect above still ran.
		if fired and not dry_run:
			if skill.max_uses_per_map != -1:
				unit.data.skill_use_counters[skill.effect_id] = \
					unit.data.skill_use_counters.get(skill.effect_id, 0) + 1
			if skill.max_uses_per_combat != -1:
				_combat_skill_uses[skill.effect_id] = \
					_combat_skill_uses.get(skill.effect_id, 0) + 1
	return context


# Dispatches one skill. Returns true if the effect committed, false if the handler
# declined to act (the use counters above key off this).
func _execute_skill(skill: SkillData, unit: Node, context: Dictionary) -> bool:
	if not _dispatch.has(skill.effect_id):
		push_error("SkillHandler: unknown effect_id '%s' — add it to _dispatch in _ready()" % skill.effect_id)
		return false
	return _dispatch[skill.effect_id].call(skill, unit, context)


# ---- Individual skill implementations ----
# Each returns true when its effect applied, false when it declined (so apply_trigger
# only consumes a limited use on a real activation). Context dicts are mutated in
# place (Dictionary is a reference type), so the bool is the only return value needed.

# S-rank mastery: +Hit, +Crit, +Dmg when attacking with a weapon type the unit holds at S rank.
# Fires once per combat (on_combat_start); bonuses flow through atk_mod/def_mod so they appear
# correctly in previews and are cleared by clear_combat_modifiers() after the fight.
func _apply_s_rank_mastery(skill: SkillData, unit: Node, context: Dictionary) -> bool:
	var is_atk: bool = (unit == context.get("attacker"))
	var w: WeaponData = context.get("attacker_weapon") if is_atk else context.get("defender_weapon")
	if w == null:
		return false
	# Only apply when the unit actually has S rank in the weapon they're currently wielding.
	if not unit.data.proficiencies.has(w.weapon_type):
		return false
	if unit.data.proficiencies[w.weapon_type].get("rank", "E") != "S":
		return false
	var mod: Dictionary = context["atk_mod"] if is_atk else context["def_mod"]
	mod["accuracy"] += skill.effect_params.get("hit_bonus", 10)
	mod["crit"]     += skill.effect_params.get("crit_bonus", 5)
	mod["damage"]   += skill.effect_params.get("dmg_bonus", 1)
	return true


func _apply_renewal(_skill: SkillData, unit: Node, _context: Dictionary) -> bool:
	# Heal 10% of max HP, rounded down (GDD_02:76), but always at least 1.
	var amount: int = maxi(1, floori(unit.data.max_hp * GameConstants.PERCENT_HP_HEAL_FRACTION))
	unit.heal(amount)
	return true


# Defender attacks first this combat. Only fires for the defending unit.
func _apply_vantage(_skill: SkillData, unit: Node, context: Dictionary) -> bool:
	if unit != context.get("defender"):
		return false
	context["flags"]["vantage"] = true
	return true


# Negate the opponent's battle skills this combat: their combat-trigger skills
# (on_combat_start / on_attack / on_hit / on_kill / on_damaged) are suppressed,
# except any listed in NIHIL_EXEMPT_SKILLS.
#
# Nihil does NOT block — these reach combat outside the negate pass:
#   - buffs/debuffs already in a unit's active_modifiers (applied earlier by an item,
#     a skill, or another unit — read in by _apply_unit_data_modifiers before Nihil);
#   - equip-item modifiers (_apply_equip_item_modifiers);
#   - aura skills from other units on the map (on_combat_apply_modifiers);
#   - passive/untriggered skills, which are never dispatched through apply_trigger.
# It only suppresses the opponent's own skills as they would activate in this fight.
func _apply_nihil(_skill: SkillData, unit: Node, context: Dictionary) -> bool:
	if unit == context.get("attacker"):
		context["defender_skills_blocked"] = true
	else:
		context["attacker_skills_blocked"] = true
	return true


# +50% STR, MAG, SKL, SPD when HP ≤ 50%. Applied as "combat" duration modifiers so they flow
# through all stat functions (damage, accuracy, follow-up threshold) correctly and are
# automatically cleared by CombatResolver.clear_combat_modifiers() after the fight.
func _apply_resolve(_skill: SkillData, unit: Node, _context: Dictionary) -> bool:
	if unit.data.hp * 2 > unit.data.max_hp:
		return false
	# Distinct source per stat: add_modifier() replaces every modifier sharing a
	# source, so a single "resolve" source would leave only the last stat applied
	# (the other three wiped). All four are duration_type "combat", so
	# clear_combat_modifiers() still removes them together after the fight.
	unit.add_modifier("strength", floori(unit.get_effective_stat("strength") * 0.5), "resolve_strength", -1, "combat")
	unit.add_modifier("magic",    floori(unit.get_effective_stat("magic")    * 0.5), "resolve_magic", -1, "combat")
	unit.add_modifier("skill",    floori(unit.get_effective_stat("skill")    * 0.5), "resolve_skill", -1, "combat")
	unit.add_modifier("speed",    floori(unit.get_effective_stat("speed")    * 0.5), "resolve_speed", -1, "combat")
	return true


# +50 Critical when HP ≤ 50%. Writes to atk_mod or def_mod based on role.
func _apply_wrath(_skill: SkillData, unit: Node, context: Dictionary) -> bool:
	if unit.data.hp * 2 > unit.data.max_hp:
		return false
	var mod: Dictionary = context["atk_mod"] if (unit == context.get("attacker")) else context["def_mod"]
	mod["crit"] += 50
	return true


# Survive a fatal blow at 1 HP (on_damaged trigger).
# Activation roll is handled by apply_trigger — this function only runs when the proc succeeds.
# Returns false on a non-lethal hit so a use-limited Miracle isn't burned for nothing.
func _apply_miracle(_skill: SkillData, unit: Node, context: Dictionary) -> bool:
	var dmg: int = context.get("damage", 0)
	if dmg <= 0:
		return false
	var sim_hp: int = context.get("current_sim_hp", unit.data.hp)
	if dmg < sim_hp:
		return false
	# Guarantee survival: reduce damage to leave exactly 1 HP remaining.
	context["damage"] = sim_hp - 1
	return true


# +N damage when attacking with the matching weapon type.
func _apply_faire(skill: SkillData, unit: Node, context: Dictionary) -> bool:
	var is_atk: bool = (unit == context.get("attacker"))
	var w: WeaponData = context.get("attacker_weapon") if is_atk else context.get("defender_weapon")
	if w == null or w.weapon_type != skill.effect_params.get("weapon_type", ""):
		return false
	var mod: Dictionary = context["atk_mod"] if is_atk else context["def_mod"]
	mod["damage"] += skill.effect_params.get("bonus", 5)
	return true


# Attacker side: +N hit vs opponent weapon type. Defender side: +N dodge vs that type.
func _apply_breaker(skill: SkillData, unit: Node, context: Dictionary) -> bool:
	var is_atk: bool = (unit == context.get("attacker"))
	var opp_w: WeaponData = context.get("defender_weapon") if is_atk else context.get("attacker_weapon")
	if opp_w == null or opp_w.weapon_type != skill.effect_params.get("weapon_type", ""):
		return false
	var mod: Dictionary = context["atk_mod"] if is_atk else context["def_mod"]
	if is_atk:
		mod["accuracy"] += skill.effect_params.get("hit", 50)
	else:
		mod["dodge"] += skill.effect_params.get("dodge", 50)
	return true


# Generic stat bonus from effect_params (hit/crit/str keys).
# No skill .tres uses this yet — implement fully in M9.
func _apply_stat_bonus(skill: SkillData, _unit: Node, _context: Dictionary) -> bool:
	push_warning("SkillHandler._apply_stat_bonus: stub called for '%s' — implement in M9" % skill.id)
	return false  # stub did nothing — don't consume a use


# ---- Aura skills (on_combat_apply_modifiers) ----
# These fire once per nearby unit before combat; unit is the aura bearer.
# No skill .tres uses these yet — implement fully in M9 (also fix §2.1 charm double-count then).

func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


# +10 hit and +10 dodge to allies within radius.
func _apply_charm(skill: SkillData, _unit: Node, _context: Dictionary) -> bool:
	push_warning("SkillHandler._apply_charm: stub called for '%s' — implement in M9" % skill.id)
	return false


# -10 hit and -10 dodge to enemies within radius.
func _apply_anathema(skill: SkillData, _unit: Node, _context: Dictionary) -> bool:
	push_warning("SkillHandler._apply_anathema: stub called for '%s' — implement in M9" % skill.id)
	return false


# -10 hit and -10 crit to enemies within radius.
func _apply_daunt(skill: SkillData, _unit: Node, _context: Dictionary) -> bool:
	push_warning("SkillHandler._apply_daunt: stub called for '%s' — implement in M9" % skill.id)
	return false
