class_name SkillContributionRegistry extends RefCounted

## Declarative contributions from passive, query-only skills.
##
## A passive skill is not an effect. Nothing triggers it, it mutates nothing,
## and it never joins a transaction — the engine ASKS it a question at the
## moment the answer is needed: how much does this tile cost, may this unit
## walk through a wall, how fast does this weapon rank climb. Modelling those as
## effects meant they were dispatched through apply_trigger, returned false so
## as not to burn a use, and were then read by five hand-written loops in
## SkillHandler that each re-implemented "find the skills on this unit with this
## effect id, decide whether each applies, and combine the answers".
##
## Those five loops were the same loop with different combine rules. This is the
## loop, once, with the combine rule declared:
##
##   first  — the first applicable contribution wins (movement cost override)
##   any    — true if any contribution applies (pass, phasing)
##   max    — the largest value contributed (weapon EXP multiplier)
##   sum    — every contribution added together (staff healing)
##
## Registering a contribution takes a resolver that reports what ONE skill
## contributes for one query, or null when it does not apply. Content can add a
## contribution kind without an engine edit, which is the same open-registry
## rule the effect vocabulary follows.

const COMBINE_RULES: Array[String] = ["first", "any", "max", "sum"]

var _entries: Dictionary = {}


func register_contribution(
	kind: String, effect_id: String, combine: String, resolver: Callable, default_value: Variant
) -> Array[String]:
	var errors: Array[String] = []
	if kind.strip_edges().is_empty():
		errors.append("SkillContributionRegistry: contribution kind is empty")
	if effect_id.strip_edges().is_empty():
		errors.append("SkillContributionRegistry: contribution '%s' has no effect id" % kind)
	if not COMBINE_RULES.has(combine):
		errors.append(
			(
				"SkillContributionRegistry: contribution '%s' has unknown combine '%s'"
				% [kind, combine]
			)
		)
	if not resolver.is_valid():
		errors.append("SkillContributionRegistry: contribution '%s' has no resolver" % kind)
	if _entries.has(kind):
		errors.append("SkillContributionRegistry: duplicate contribution kind '%s'" % kind)
	if errors.is_empty():
		_entries[kind] = {
			"effect_id": effect_id,
			"combine": combine,
			"resolver": resolver,
			"default": default_value,
		}
	return errors


func register_builtins(resolver_owner: Object) -> Array[String]:
	var errors: Array[String] = []
	for spec in _builtin_specs():
		errors.append_array(
			register_contribution(
				String(spec["kind"]),
				String(spec["effect_id"]),
				String(spec["combine"]),
				Callable(resolver_owner, String(spec["resolver"])),
				spec["default"]
			)
		)
	return errors


func has_contribution(kind: String) -> bool:
	return _entries.has(kind)


func kinds() -> Array[String]:
	var result: Array[String] = []
	result.assign(_entries.keys())
	result.sort()
	return result


# Effect ids claimed by contributions. These are a real part of the authorable
# skill vocabulary — a pack may write `"effect_id": "swiftfoot"` — they are just
# not dispatched as effects.
static func contribution_effect_ids() -> Array[String]:
	var result: Array[String] = []
	for spec in _builtin_specs():
		var effect_id := String(spec["effect_id"])
		if not result.has(effect_id):
			result.append(effect_id)
	result.sort()
	return result


# Asks every available skill on the unit what it contributes, and combines the
# answers by the declared rule. `skills` is the unit's full skill list; the
# effect id filter and the availability gate are applied here so no caller has
# to remember either.
func resolve(kind: String, skills: Array, context: Dictionary = {}) -> Variant:
	if not _entries.has(kind):
		return null
	var entry: Dictionary = _entries[kind]
	var combine := String(entry["combine"])
	var result: Variant = entry["default"]
	for skill in skills:
		if skill == null or skill.effect_id != String(entry["effect_id"]):
			continue
		if not skill.is_available_for_release():
			continue
		var contribution: Variant = (entry["resolver"] as Callable).call(skill, context)
		if contribution == null:
			continue
		match combine:
			"first":
				return contribution
			"any":
				if bool(contribution):
					return true
			"max":
				result = maxi(int(result), int(contribution))
			"sum":
				result = int(result) + int(contribution)
	return result


static func _builtin_specs() -> Array[Dictionary]:
	return [
		{
			"kind": "move_cost_override",
			"effect_id": "swiftfoot",
			"combine": "first",
			"resolver": "_contribute_move_cost",
			"default": -1,
		},
		{
			"kind": "pass_through_enemies",
			"effect_id": "pass",
			"combine": "any",
			"resolver": "_contribute_true",
			"default": false,
		},
		{
			"kind": "phase_through_terrain",
			"effect_id": "phasing",
			"combine": "any",
			"resolver": "_contribute_phase",
			"default": false,
		},
		{
			"kind": "wexp_multiplier",
			"effect_id": "discipline",
			"combine": "max",
			"resolver": "_contribute_wexp_multiplier",
			"default": 1,
		},
		{
			"kind": "staff_heal_bonus",
			"effect_id": "healtouch",
			"combine": "sum",
			"resolver": "_contribute_staff_heal",
			"default": 0,
		},
	]
