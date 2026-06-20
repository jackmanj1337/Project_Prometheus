extends RefCounted
# Collects a unit's COMBAT-ONLY stat contributions so the character sheet can
# show the same numbers combat applies — even though these modifiers do not live
# in data.active_modifiers outside a fight (they are stamped at combat start with
# duration_type="combat" and cleared afterward).
#
# Today the only combat-only sources that affect the seven base stats are:
#   - Pair Up support bonus  (CombatResolver._apply_pair_up_bonuses)
#   - the unit's own *unconditional* stat_bonus skills, e.g. Strength +2
#     (SkillHandler._apply_stat_bonus)
# Aura skills (charm/anathema/daunt) are M9 stubs and target hit/dodge/crit, not
# the base stats, so they contribute nothing here yet — when M9 implements them
# they get added here AND the drift-guard test below grows to cover them.
#
# Dependencies are INJECTED (a deps dict), not fetched from /root, so this helper
# stays pure and unit-testable, and so the drift-guard test (test_stat_contributions
# .gd) can bind these numbers to what CombatResolver actually applies — the
# playtest #8.5 lesson: never let the display and combat math drift apart.
#
# class_name omitted to skip global class-cache maintenance; preload to use.

const _STAT_BONUS_EFFECT := "stat_bonus"


# Returns combat-only contribution rows for one stat, each shaped like a
# StatBreakdown mod row so they merge straight into the breakdown:
#   {source_id, source_label, delta, duration_type, remaining:-1}
# duration_type is a V021-09 display label (until_separated for Pair Up, permanent
# for always-on stat skills), not the lifecycle tick type.
#
# deps keys (any may be absent — the matching source is then skipped):
#   "registry"     PairUpRegistry  — is_lead / get_partner_id
#   "game_state"   GameState       — find_unit_by_id (resolves the off-map support)
#   "resolver"     PairUpBonusResolver — bonuses_for(support)
#   "data_manager" DataManager     — get_skill(id) for the unit's equipped skills
static func for_stat(unit, stat_name: String, deps: Dictionary) -> Array:
	var out: Array = []
	if unit == null or not is_instance_valid(unit) or unit.get("data") == null:
		return out
	_collect_pair_up(unit, stat_name, deps, out)
	_collect_stat_skills(unit, stat_name, deps, out)
	return out


# Pair Up: mirrors HUD._pairup_bonus_text / CombatResolver._apply_pair_up_bonuses.
# Only a registered LEAD shows the bonus; the support sits off-map but is still
# resolvable by id.
static func _collect_pair_up(unit, stat_name: String, deps: Dictionary, out: Array) -> void:
	var reg = deps.get("registry")
	var gs = deps.get("game_state")
	var res = deps.get("resolver")
	if reg == null or gs == null or res == null:
		return
	var uid: String = String(unit.data.unit_id)
	if uid == "" or not bool(reg.call("is_lead", uid)):
		return
	var support = gs.call("find_unit_by_id", reg.call("get_partner_id", uid))
	if support == null:
		return
	var bonuses: Dictionary = res.call("bonuses_for", support)
	var delta: int = int(bonuses.get(stat_name, 0))
	if delta != 0:
		# Pair Up persists across combats until the pair separates (V021-09), even
		# though combat stamps it as a duration_type="combat" lifecycle modifier.
		out.append(_row("pair_up", "Pair Up", delta, "until_separated"))


# Unconditional personal stat_bonus skills (Skill +2, Defense +2, …). Mirrors
# SkillHandler._apply_stat_bonus and the apply_trigger skill scan: equipped +
# mastery skills, effect_id "stat_bonus", and NO activation roll (deterministic).
# Skills with an activation_chance_stat are conditional and are not shown as
# always-on contributions.
static func _collect_stat_skills(unit, stat_name: String, deps: Dictionary, out: Array) -> void:
	var dm = deps.get("data_manager")
	if dm == null:
		return
	var ids: Array = []
	ids.append_array(unit.data.skills)
	ids.append_array(unit.data.mastery_skills)
	for sid in ids:
		var skill = dm.call("get_skill", sid)
		if skill == null:
			continue
		if String(skill.effect_id) != _STAT_BONUS_EFFECT:
			continue
		if String(skill.activation_chance_stat) != "":
			continue
		if String(skill.effect_params.get("stat", "")) != stat_name:
			continue
		var amount: int = int(skill.effect_params.get("amount", 0))
		if amount != 0:
			var label: String = String(skill.display_name) if String(skill.display_name) != "" else String(skill.id)
			# An unconditional personal stat skill is always on while the unit has it,
			# so it reads as permanent (no expiry) rather than "this combat" (V021-09).
			out.append(_row("skill:%s" % skill.id, label, amount, "permanent"))


static func _row(source_id: String, source_label: String, delta: int,
		duration_type: String = "this_combat") -> Dictionary:
	return {
		"source_id": source_id,
		"source_label": source_label,
		"delta": delta,
		"duration_type": duration_type,
		"remaining": -1,
	}
