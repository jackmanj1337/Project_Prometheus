extends Node
# Central dispatcher for skill effects. Called by CombatResolver, TurnManager,
# GridManager, etc. All skill logic lives here; callers pass a context dict and
# receive it back modified.

# Explicit preloads: SkillHandler is an autoload and parses before the global
# class cache is populated, so the registries are addressed by path.
const SkillEffectRegistryScript = preload("res://scripts/registries/SkillEffectRegistry.gd")
const SkillContributionRegistryScript = preload(
	"res://scripts/registries/SkillContributionRegistry.gd"
)

var _effect_registry := SkillEffectRegistryScript.new()
# Passive, query-only skills are declared contributions rather than effects: the
# engine asks them a question, they never fire and never mutate. See
# SkillContributionRegistry for why the five hand-written query loops that used
# to live below became one.
var _contribution_registry := SkillContributionRegistryScript.new()

# Per-combat skill use counters: skill.id → times fired this combat. Reset by
# reset_combat_uses() at the start of each combat (see CombatResolver). Separate
# from UnitData.skill_use_counters, which is the per-map tally.
# Keyed by skill.id rather than effect_id so two skills sharing an effect_id
# (e.g. two "stat_bonus" variants for Str+2 and Mag+2) keep isolated counters
# instead of sharing a single quota. Code review 2026-06-10 issue 2.6.
var _combat_skill_uses: Dictionary = {}

# Skills Nihil cannot negate — they still activate when this unit's combat skills
# are blocked. Matched against SkillData.id. s_rank_mastery is an earned, permanent
# mastery bonus (innate, not a battle skill). nihil's own negate pre-pass is already
# structurally exempt (it runs before the blocked flags are read), but it is listed
# here so the whole exemption rule is stated in one place.
const NIHIL_EXEMPT_SKILLS: Array[String] = ["s_rank_mastery", "nihil"]


func _ready() -> void:
	var errors := _effect_registry.register_builtins(self)
	errors.append_array(_contribution_registry.register_builtins(self))
	for error in errors:
		push_error(error)


# ---- Passive movement queries ----


func get_move_cost_override(unit: Node, terrain: String) -> int:
	return int(
		_contribution_registry.resolve(
			"move_cost_override", _skills_for(unit), {"terrain": terrain}
		)
	)


func can_pass_through_enemies(unit: Node) -> bool:
	return bool(_contribution_registry.resolve("pass_through_enemies", _skills_for(unit)))


func can_phase_through(unit: Node, terrain: String) -> bool:
	return bool(
		_contribution_registry.resolve(
			"phase_through_terrain", _skills_for(unit), {"terrain": terrain}
		)
	)


func get_wexp_multiplier(unit: Node, track: String) -> int:
	if unit == null or unit.data == null or track == "":
		return 1
	return int(
		_contribution_registry.resolve("wexp_multiplier", _skills_for(unit), {"track": track})
	)


func get_staff_heal_bonus(unit: Node) -> int:
	if unit == null or unit.data == null:
		return 0
	return int(_contribution_registry.resolve("staff_heal_bonus", _skills_for(unit)))


# Stamps a combat-duration modifier through the shared primitive when the caller
# owns a transaction, and directly when it does not. Resolve and the "+2" skills
# each reached for unit.add_modifier() by hand before this; the sink is where
# that rule lives now, together with the reason these stay live.
func _apply_combat_modifier(
	unit: Node, context: Dictionary, stat: String, delta: int, source: String
) -> void:
	var sink: Variant = context.get("effect_sink")
	if sink != null:
		sink.add_combat_modifier(unit, stat, delta, source, -1, "combat")
	else:
		unit.add_modifier(stat, delta, source, -1, "combat")


# ---- Contribution resolvers ----
# Each reports what ONE skill contributes to one query, or null when it does not
# apply. The registry owns the iteration, the availability gate and the combine
# rule; these own only the skill's own rule.


func _contribute_move_cost(skill: SkillData, context: Dictionary) -> Variant:
	var excluded: Array = skill.effect_params.get("excluded_terrain", ["wall", "sea"])
	if String(context.get("terrain", "")) in excluded:
		return null
	return int(skill.effect_params.get("move_cost", 1))


func _contribute_true(_skill: SkillData, _context: Dictionary) -> Variant:
	return true


func _contribute_phase(skill: SkillData, context: Dictionary) -> Variant:
	var allowed: Array = skill.effect_params.get("terrain", ["wall"])
	return true if String(context.get("terrain", "")) in allowed else null


func _contribute_wexp_multiplier(skill: SkillData, context: Dictionary) -> Variant:
	var applies_to: Array = skill.effect_params.get("tracks", [])
	if not applies_to.is_empty() and not (String(context.get("track", "")) in applies_to):
		return null
	return int(skill.effect_params.get("wexp_multiplier", 1))


func _contribute_staff_heal(skill: SkillData, _context: Dictionary) -> Variant:
	return int(skill.effect_params.get("heal_bonus", 0))


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
func apply_trigger(
	unit: Node,
	trigger: String,
	context: Dictionary,
	preview: bool = false,
	skills_blocked: bool = false,
	dry_run: bool = false
) -> Dictionary:
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
		# Keyed by skill.id so two skills sharing effect_id don't share a counter.
		if skill.max_uses_per_map != -1:
			var used: int = unit.data.skill_use_counters.get(skill.id, 0)
			if used >= skill.max_uses_per_map:
				continue
		# Enforce per-combat use limit (scoped by reset_combat_uses()).
		if skill.max_uses_per_combat != -1:
			var combat_used: int = _combat_skill_uses.get(skill.id, 0)
			if combat_used >= skill.max_uses_per_combat:
				continue
		# Roll activation chance from data if a stat is specified. The draw comes
		# from the current event's private RNG (context["rng"], seeded by
		# RngService.begin_event — RNG-1); previews never reach here (skipped
		# above), so a missing RNG in a live path is a plumbing bug: fail loudly
		# and draw nothing rather than silently desync the dice chain with raw RNG.
		if skill.activation_chance_stat != "":
			var rng: RandomNumberGenerator = context.get("rng")
			if rng == null:
				push_error(
					(
						"SkillHandler: '%s' activation roll without context[\"rng\"] — " % skill.id
						+ "begin an RNG event before non-preview triggers (RNG-1)"
					)
				)
				continue
			var stat_val: int = unit.get_effective_stat(
				skill.activation_chance_stat, context.get("effect_sink")
			)
			var chance: int = stat_val / max(1, skill.activation_divisor)
			if rng.randi_range(0, 99) >= chance:  # rng-allow: draw from the RngService event RNG (RNG-1)
				continue
		# Only count a use when the effect actually committed: a handler that
		# declines (wrong weapon type, HP above threshold, Miracle on a non-lethal
		# hit) returns false and must not burn a limited use.
		var outcome: Dictionary = _execute_skill(skill, unit, context)
		var fired: bool = bool(outcome["fired"])
		if fired and not (outcome["steps"] as Array).is_empty():
			var prepared: Array = context.get("skill_steps", [])
			prepared.append_array(outcome["steps"])
			context["skill_steps"] = prepared
		# dry_run suppresses counter persistence only — the effect above still ran.
		if fired and not dry_run:
			if skill.max_uses_per_map != -1:
				_bump_map_use(unit, skill.id, context)
			if skill.max_uses_per_combat != -1:
				_combat_skill_uses[skill.id] = _combat_skill_uses.get(skill.id, 0) + 1
	return context


# The per-map use counter is SAVED state, so where it is written depends on
# whether the caller owns a transaction. Every durable trigger caller must own
# one: combat joins the fight transaction and phase-start skills join the
# transaction prepared by TurnManager.
#
# This is the split that mattered: the counter used to be written the instant a
# skill fired, which meant a fight that was rolled and then abandoned had
# already spent the skill. A prepared counter is spent only if the fight is.
func _bump_map_use(unit: Node, skill_id: String, context: Dictionary) -> void:
	var sink: Variant = context.get("effect_sink")
	if sink == null:
		push_error("SkillHandler: durable skill counter prepared without an effect sink")
		return
	sink.bump_counter("skill_use:%s" % skill_id, unit, "skill_use_counters", skill_id)


# Dispatches one skill and returns its result: whether the effect applied, and
# the journal steps it prepared.
#
# The bare bool this used to return said only "did it fire", which was enough
# for the use counter and nothing else — a triggered skill that prepared a
# durable change reported no more than one that adjusted a number in the context
# dict. The step ids are what let a caller show, replay or audit what a skill
# actually did in a fight.
func _execute_skill(skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	var declined := {"fired": false, "steps": [] as Array}
	# Legacy maps and saves may still carry authored stubs. Keep those records
	# loadable, but release-unavailable effects stay inert and quiet in play.
	if not skill.is_available_for_release():
		return declined
	if not _effect_registry.has_effect(skill.effect_id):
		push_error(
			"SkillHandler: unknown effect_id '%s' — register an engine handler" % skill.effect_id
		)
		return declined
	var outcome: Variant = _effect_registry.execute(skill.effect_id, skill, unit, context)
	if outcome is Dictionary:
		return {"fired": bool(outcome.get("fired", false)), "steps": outcome.get("steps", [])}
	return {"fired": bool(outcome), "steps": [] as Array}


# ---- Individual skill implementations ----
# Each returns true when its effect applied, false when it declined (so apply_trigger
# only consumes a limited use on a real activation). Context dicts are mutated in
# place (Dictionary is a reference type), so the bool is the only return value needed.


# S-rank mastery: +Hit, +Crit, +Dmg when attacking with a weapon type the unit holds at S rank.
# Fires once per combat (on_combat_start); bonuses flow through atk_mod/def_mod so they appear
# correctly in previews and die with the transaction that prepared them.
func _apply_s_rank_mastery(skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	var is_atk: bool = unit == context.get("attacker")
	var w: WeaponData = context.get("attacker_weapon") if is_atk else context.get("defender_weapon")
	if w == null:
		return {"fired": false, "steps": [] as Array}
	if unit.get_weapon_rank(w.wexp_track) != "S":
		return {"fired": false, "steps": [] as Array}
	var mod: Dictionary = context["atk_mod"] if is_atk else context["def_mod"]
	mod["accuracy"] += skill.effect_params.get("hit_bonus", 10)
	mod["crit"] += skill.effect_params.get("crit_bonus", 5)
	mod["damage"] += skill.effect_params.get("dmg_bonus", 1)
	return {"fired": true, "steps": [] as Array}


func _apply_renewal(_skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	# Heal 10% of max HP, rounded down (GDD_02:76), but always at least 1.
	var amount: int = maxi(1, floori(unit.data.max_hp * GameConstants.PERCENT_HP_HEAL_FRACTION))
	var sink: Variant = context.get("effect_sink")
	if sink == null:
		push_error("SkillHandler: Renewal prepared without an effect sink")
		return {"fired": false, "steps": [] as Array}
	var step_id := "renewal:%d" % unit.get_instance_id()
	sink.heal(step_id, unit, amount)
	return {"fired": true, "steps": [step_id] as Array}


# Defender attacks first this combat. Only fires for the defending unit.
func _apply_vantage(_skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	if unit != context.get("defender"):
		return {"fired": false, "steps": [] as Array}
	context["flags"]["vantage"] = true
	return {"fired": true, "steps": [] as Array}


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
func _apply_nihil(_skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	if unit == context.get("attacker"):
		context["defender_skills_blocked"] = true
	else:
		context["attacker_skills_blocked"] = true
	return {"fired": true, "steps": [] as Array}


# +50% STR, MAG, SKL, SPD when HP ≤ 50%. Prepared as "combat" duration modifiers so they
# flow through all stat functions (damage, accuracy, follow-up threshold) correctly. They
# are never written live, so nothing has to revert them: an abandoned forecast drops the
# scratch layer with its transaction.
func _apply_resolve(_skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	if unit.data.hp * 2 > unit.data.max_hp:
		return {"fired": false, "steps": [] as Array}
	# Distinct source per stat: one modifier per source, so a single "resolve"
	# source would leave only the last stat applied (the other three wiped).
	#
	# The base each bonus is computed from is read THROUGH the sink, so Resolve
	# stacking on a pair-up bonus sees that bonus — it is prepared, not live, and
	# a live read would have quietly gone back to the unbuffed number the moment
	# pair-up stopped writing live state.
	var sink: Variant = context.get("effect_sink")
	for stat in ["strength", "magic", "skill", "speed"]:
		_apply_combat_modifier(
			unit,
			context,
			String(stat),
			floori(unit.get_effective_stat(String(stat), sink) * 0.5),
			"resolve_%s" % stat
		)
	return {"fired": true, "steps": [] as Array}


# +50 Critical when HP ≤ 50%. Writes to atk_mod or def_mod based on role.
func _apply_wrath(_skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	if unit.data.hp * 2 > unit.data.max_hp:
		return {"fired": false, "steps": [] as Array}
	var mod: Dictionary = (
		context["atk_mod"] if (unit == context.get("attacker")) else context["def_mod"]
	)
	mod["crit"] += 50
	return {"fired": true, "steps": [] as Array}


# Survive a fatal blow at 1 HP (on_damaged trigger).
# Activation roll is handled by apply_trigger — this function only runs when the proc succeeds.
# Returns false on a non-lethal hit so a use-limited Miracle isn't burned for nothing.
func _apply_miracle(_skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	var dmg: int = context.get("damage", 0)
	if dmg <= 0:
		return {"fired": false, "steps": [] as Array}
	var sim_hp: int = context.get("current_sim_hp", unit.data.hp)
	if dmg < sim_hp:
		return {"fired": false, "steps": [] as Array}
	# Guarantee survival: reduce damage to leave exactly 1 HP remaining.
	context["damage"] = sim_hp - 1
	return {"fired": true, "steps": [] as Array}


# +N damage when attacking with the matching weapon type.
func _apply_faire(skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	var is_atk: bool = unit == context.get("attacker")
	var w: WeaponData = context.get("attacker_weapon") if is_atk else context.get("defender_weapon")
	if w == null or w.combat_family != skill.effect_params.get("weapon_type", ""):
		return {"fired": false, "steps": [] as Array}
	var mod: Dictionary = context["atk_mod"] if is_atk else context["def_mod"]
	mod["damage"] += skill.effect_params.get("bonus", 5)
	return {"fired": true, "steps": [] as Array}


# Attacker side: +N hit vs opponent weapon type. Defender side: +N dodge vs that type.
func _apply_breaker(skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	var is_atk: bool = unit == context.get("attacker")
	var opp_w: WeaponData = (
		context.get("defender_weapon") if is_atk else context.get("attacker_weapon")
	)
	if opp_w == null or opp_w.combat_family != skill.effect_params.get("weapon_type", ""):
		return {"fired": false, "steps": [] as Array}
	var mod: Dictionary = context["atk_mod"] if is_atk else context["def_mod"]
	if is_atk:
		mod["accuracy"] += skill.effect_params.get("hit", 50)
	else:
		mod["dodge"] += skill.effect_params.get("dodge", 50)
	return {"fired": true, "steps": [] as Array}


# Generic stat bonus from effect_params ({"stat": String, "amount": int}).
# Used by the FE:A "+2" skills (Skill +2, Defense +2, Magic +2). Applied as a
# combat-duration modifier so all downstream formulas read the adjusted stat via
# get_effective_stat() without duplicating per-stat combat math here.
func _apply_stat_bonus(skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	if unit == null or unit.data == null:
		return {"fired": false, "steps": [] as Array}
	var stat: String = String(skill.effect_params.get("stat", ""))
	var amount: int = int(skill.effect_params.get("amount", 0))
	if stat == "" or amount == 0:
		return {"fired": false, "steps": [] as Array}
	_apply_combat_modifier(unit, context, stat, amount, "skill:%s" % skill.id)
	return {"fired": true, "steps": [] as Array}


func _apply_prescience(skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	if unit != context.get("attacker"):
		return {"fired": false, "steps": [] as Array}
	var mod: Dictionary = context["atk_mod"]
	mod["accuracy"] += int(skill.effect_params.get("hit", 0))
	mod["dodge"] += int(skill.effect_params.get("avoid", 0))
	return {"fired": true, "steps": [] as Array}


func _apply_patience(skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	if unit != context.get("defender"):
		return {"fired": false, "steps": [] as Array}
	var mod: Dictionary = context["def_mod"]
	mod["accuracy"] += int(skill.effect_params.get("hit", 0))
	mod["dodge"] += int(skill.effect_params.get("avoid", 0))
	return {"fired": true, "steps": [] as Array}


func _apply_focus(skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
	var radius: int = int(skill.effect_params.get("radius", 3))
	if _has_ally_within(unit, radius):
		return {"fired": false, "steps": [] as Array}
	var mod: Dictionary = (
		context["atk_mod"] if unit == context.get("attacker") else context["def_mod"]
	)
	mod["crit"] += int(skill.effect_params.get("crit", 0))
	return {"fired": true, "steps": [] as Array}


func _skills_for(unit: Node) -> Array[SkillData]:
	var out: Array[SkillData] = []
	if unit == null or unit.data == null:
		return out
	var dm := get_node_or_null("/root/DataManager")
	if dm == null:
		return out
	var ids: Array[String] = []
	ids.append_array(unit.data.skills)
	ids.append_array(unit.data.mastery_skills)
	for skill_id in ids:
		var skill: SkillData = dm.get_skill(skill_id)
		if skill != null:
			out.append(skill)
	return out


func _has_ally_within(unit: Node, radius: int) -> bool:
	if unit == null or radius < 0:
		return false
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return false
	for other in gs.all_units:
		if (
			other == unit
			or not is_instance_valid(other)
			or other.data == null
			or other.data.hp <= 0
		):
			continue
		var is_ally: bool = false
		if gs.has_method("are_hostile"):
			is_ally = not gs.are_hostile(unit.team, other.team)
		else:
			is_ally = unit.team == other.team
		if not is_ally:
			continue
		var dist: int = (
			absi(unit.tile_position.x - other.tile_position.x)
			+ absi(unit.tile_position.y - other.tile_position.y)
		)
		if dist <= radius:
			return true
	return false


# Stub appliers warn ONCE per skill id per session, not every combat. A single
# armsthrift-bearer fighting all map otherwise floods godot.log (the v0.1.4 pass
# logged armsthrift ×80, dash ×25). The M9 reminder still surfaces once; it just
# stops repeating so real ERRORs are not buried.
var _stub_warned: Dictionary = {}


func _warn_stub_once(where: String, skill_id: String) -> void:
	if _stub_warned.has(skill_id):
		return
	_stub_warned[skill_id] = true
	push_warning(
		"%s: stub called for '%s' — implement in M9 (repeats suppressed)" % [where, skill_id]
	)


# Shared stub for the FE:A base-class skills whose effects land in M9. Declining
# (false) means no use is consumed and combat/preview math is unaffected.
func _apply_unimplemented(skill: SkillData, _unit: Node, _context: Dictionary) -> Dictionary:
	_warn_stub_once("SkillHandler._apply_unimplemented", skill.id)
	return {"fired": false, "steps": [] as Array}


# ---- Aura skills (on_combat_apply_modifiers) ----
# These fire once per nearby unit before combat; unit is the aura bearer.
# No skill .tres uses these yet — implement fully in M9 (also fix §2.1 charm double-count then).


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


# +10 hit and +10 dodge to allies within radius.
func _apply_charm(skill: SkillData, _unit: Node, _context: Dictionary) -> Dictionary:
	_warn_stub_once("SkillHandler._apply_charm", skill.id)
	return {"fired": false, "steps": [] as Array}


# -10 hit and -10 dodge to enemies within radius.
func _apply_anathema(skill: SkillData, _unit: Node, _context: Dictionary) -> Dictionary:
	_warn_stub_once("SkillHandler._apply_anathema", skill.id)
	return {"fired": false, "steps": [] as Array}


# -10 hit and -10 crit to enemies within radius.
func _apply_daunt(skill: SkillData, _unit: Node, _context: Dictionary) -> Dictionary:
	_warn_stub_once("SkillHandler._apply_daunt", skill.id)
	return {"fired": false, "steps": [] as Array}
