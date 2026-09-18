class_name CombatTermLedger
extends RefCounted
# The combat adapter's term board — slice 5 of AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10.
#
# An authored interaction reaches a fight the same way every other authored effect does:
# through a registered composition, run by `ActionPrimitiveRunner`. But a weapon-triangle
# bonus is not a durable write. It is a number that exists for ONE strike, is read by
# `CombatResolver.strike_forecast()`, and is gone — it never belongs in the journal, and a
# forecast that computed it three times must not have written anything three times.
#
# So the `apply_combat_term` primitive writes here instead of into the transaction, and
# this ledger is handed to the runner as a SUBJECT. A composition that names the primitive
# outside a combat adapter fails validation with `missing_subject`, which is the loud
# answer; the quiet one would be a bonus that silently evaporated.
#
# THE VOCABULARY IS THE ENGINE'S, exactly as `InteractionProfileSchema.ENGINE_CONTEXTS` is.
# A pack authors WHICH term a composition feeds and WHAT the magnitude is; it does not
# invent a term, because a term names a place in the strike arithmetic and there is no
# such place until the engine makes one. Movement and economy get their own ledger beside
# their own adapter, not entries here.
#
# ADDITIVE VS PERCENT. The additive terms are the units the strike already speaks in:
# accuracy and dodge are hit points of percentage, damage is damage, crit is crit. The
# multiplicative ones are PERCENT — `300` is x3.00 — because an authored magnitude leaves
# fixed point as an integer at the bridge (`[ITR-3]`, slice 4 decision 4), and an integer
# multiplier cannot say x1.5. Percent can say both, and says them in whole numbers.
#
# THE ONE COMBINATION THAT DOES NOT WORK is a percent term under the `multiply` stack
# policy: that policy multiplies the MAGNITUDES, so two x3 contributions authored as 300
# compose to 90000 (x900), not 900 (x9). Percent contributions that reach this ledger
# separately compose multiplicatively here, correctly, which is what `all` and `highest`
# produce. The default pack uses `highest`, and this is written down rather than guarded
# because the guard would have to read a composition's params to know a payload's units —
# which is the branching on composition ids that slice 4 decision 3 refused.

# Terms that SUM. One contribution of +10 and another of -2 make +8.
const ADDITIVE_TERMS: Array[String] = ["accuracy", "damage", "crit", "crit_avoid", "dodge"]

# Terms that MULTIPLY, in percent. `might_multiplier_pct` scales the weapon's might before
# defence is subtracted — where weapon effectiveness has always applied — and
# `damage_multiplier_pct` scales the final figure, crit included, where the live exchange
# has always applied `damage_multiplier`. They are two different numbers and the author
# picks which one a rule feeds.
const PERCENT_TERMS: Array[String] = ["might_multiplier_pct", "damage_multiplier_pct"]

# Percent is expressed against this base: 100 is "unchanged".
const PERCENT_BASE := 100

# Every contribution, in the order it was recorded, for a readout and for a diagnostic
# that has to answer "where did this +10 come from". `[ITR-6]` asks that a consumer read
# the resolution rather than recompute it; this is the combat half of that record.
var entries: Array[Dictionary] = []

var _totals: Dictionary = {}


static func terms() -> Array[String]:
	var out: Array[String] = ADDITIVE_TERMS.duplicate()
	out.append_array(PERCENT_TERMS)
	return out


static func is_percent(term: String) -> bool:
	return PERCENT_TERMS.has(term)


static func is_term(term: String) -> bool:
	return ADDITIVE_TERMS.has(term) or PERCENT_TERMS.has(term)


# Records one contribution. Returns an empty string on success and the reason otherwise,
# because the caller is a primitive handler that has to answer with an ActionResult.
func add(step_id: String, unit: Object, term: String, value: int) -> String:
	if unit == null:
		return "a combat term needs a unit to apply to"
	if not is_term(term):
		return "'%s' is not a combat term; the engine declares %s" % [term, ", ".join(terms())]
	entries.append({"step_id": step_id, "unit": unit, "term": term, "value": value})
	var key := _key(unit, term)
	if is_percent(term):
		# Held as a fixed-point product of ratios so two contributions to one term compose
		# the way multipliers compose, and so the caller is never handed a rounded
		# intermediate to multiply again.
		var previous: float = float(_totals.get(key, 1.0))
		_totals[key] = previous * (float(value) / float(PERCENT_BASE))
	else:
		_totals[key] = int(_totals.get(key, 0)) + value
	return ""


# The summed contribution to an additive term. Zero when nothing contributed, which is the
# same answer an absent interaction system gives — a fight with no authored profiles is a
# fight with no relationships, not a fight with broken arithmetic.
func additive(unit: Object, term: String) -> int:
	return int(_totals.get(_key(unit, term), 0))


# The composed multiplier for a percent term, as the float the damage arithmetic already
# takes. 1.0 when nothing contributed.
func multiplier(unit: Object, term: String) -> float:
	return float(_totals.get(_key(unit, term), 1.0))


# Everything recorded against one unit, for the readout slice 6 owns and for diagnostics.
func contributions(unit: Object) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry in entries:
		if entry["unit"] == unit:
			out.append(entry)
	return out


func is_empty() -> bool:
	return entries.is_empty()


func _key(unit: Object, term: String) -> String:
	return "%d:%s" % [unit.get_instance_id(), term]
