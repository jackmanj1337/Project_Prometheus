extends SceneTree
# Slice 6 of AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10: THE PLAYER-FACING READOUT `[ITR-6]`.
#
# `CombatInteractionReadout` is the one place that turns a resolution into rows a surface can
# draw. This suite tests it against LEDGERS AND RECORDS IT BUILDS BY HAND rather than through
# a fight, because the questions here are shape questions — which side of a strike a term
# belongs to, how an authored label beats a generic one, what order rows come out in — and a
# fight can only answer them for the one matchup it happens to be. The shipped pack's answers
# are asserted end-to-end in `test_combat_interaction_adapter.gd`, and the panel's rendering
# of these rows in `test_attack_preview_selector.gd`.

const Readout = preload("res://scripts/combat/CombatInteractionReadout.gd")
const Ledger = preload("res://scripts/combat/CombatTermLedger.gd")


class StubUnit:
	extends Node


func _init() -> void:
	print("=== Combat Interaction Readout Test ===")
	var failed := 0
	failed += _contract_checks()
	failed += _attribution_checks()
	failed += _strike_side_checks()
	failed += _presentation_checks()
	failed += _order_checks()
	failed += _composition_checks()
	failed += _detail_checks()
	print("=== Combat Interaction Readout Results: %d failed ===" % failed)
	quit(1 if failed else 0)


# The row and term shapes, asserted in BOTH directions. A surface reads these keys by name, so
# a key this file stops emitting is a blank row and a key it emits without declaring is a key
# no consumer knows to read — the same both-directions assertion the resolver's envelope gets.
func _contract_checks() -> int:
	var failed := 0
	var actor := StubUnit.new()
	var target := StubUnit.new()
	var ledger = Ledger.new()
	ledger.attribute(_effect("hit_bonus", "p", "sword_beats_axe"))
	ledger.add("term", actor, "accuracy", 10)
	ledger.attribute({})

	var rows := Readout.build([_record("p", {})], ledger, actor, target)
	failed += _check(rows.size() == 1, "one contributing profile makes one row")
	if rows.is_empty():
		return failed
	failed += _check(
		_keys(rows[0]) == _sorted(Readout.ROW_FIELDS),
		"a row's keys are EXACTLY ROW_FIELDS: %s" % str(_keys(rows[0]))
	)
	failed += _check(
		_keys((rows[0]["terms"] as Array)[0]) == _sorted(Readout.TERM_FIELDS),
		(
			"a term line's keys are EXACTLY TERM_FIELDS: %s"
			% str(_keys((rows[0]["terms"] as Array)[0]))
		)
	)

	# The empty case is the DEFAULT case: the engine ships no relationships, so a fight in a
	# campaign that authors none must produce no rows at all rather than a neutral placeholder.
	failed += _check(
		Readout.build([], Ledger.new(), actor, target).is_empty(),
		"an empty ledger produces no rows, which is what an unauthored campaign looks like"
	)
	failed += _check(
		Readout.build([], ledger, null, target).is_empty(),
		"...and a missing actor is answered with no rows rather than a crash"
	)
	return failed


# The join slice 6 added: a ledger entry knows which authored rule and profile asked for it.
# Without this the readout can show numbers and not what produced them, which is exactly what
# the interim `attacker_triangle` could not say.
func _attribution_checks() -> int:
	var failed := 0
	var actor := StubUnit.new()
	var ledger = Ledger.new()

	ledger.add("term", actor, "accuracy", 4)
	failed += _check(
		(
			String(ledger.entries[0]["rule_id"]) == ""
			and String(ledger.entries[0]["profile_id"]) == ""
		),
		"an UNATTRIBUTED term is legible as empty ids, not refused: a direct caller is a real case"
	)

	ledger.attribute(_effect("hit_bonus", "triangle", "sword_beats_axe"))
	ledger.add("term", actor, "damage", 2)
	failed += _check(
		(
			String(ledger.entries[1]["rule_id"]) == "sword_beats_axe"
			and String(ledger.entries[1]["profile_id"]) == "triangle"
		),
		"an attributed term names the rule AND the profile the carrier came from"
	)

	# The profile is read off `composed_from[0]` — the carrier — because a planned effect names
	# its rule directly and reaches its profile only through the contributors the resolver
	# attributed it to. An aggregate names every contributor and the carrier is first.
	var aggregate := _effect("hit_bonus", "triangle", "sword_beats_axe")
	(aggregate["composed_from"] as Array).append({"profile_id": "other", "rule_id": "second"})
	ledger.attribute(aggregate)
	ledger.add("term", actor, "crit", 5)
	failed += _check(
		String(ledger.entries[2]["profile_id"]) == "triangle",
		"an AGGREGATE is attributed to its carrier, the first contributor, not the last"
	)

	ledger.attribute({})
	ledger.add("term", actor, "dodge", 1)
	failed += _check(
		String(ledger.entries[3]["rule_id"]) == "",
		"clearing the attribution stops the next composition inheriting the previous one's"
	)
	return failed


# WHICH SIDE OF A STRIKE A TERM BELONGS TO. `strike_forecast` reads the actor's accuracy,
# damage, crit and multipliers and the TARGET's dodge and crit-avoid, so a row is about a
# STRIKE and not about a unit. Getting this wrong reports the defender's authored avoid bonus
# as the attacker's advantage, and drops it from the readout entirely if filtered by unit.
func _strike_side_checks() -> int:
	var failed := 0
	failed += _check(
		(
			Ledger.strike_side("accuracy") == "actor"
			and Ledger.strike_side("might_multiplier_pct") == "actor"
			and Ledger.strike_side("dodge") == "target"
			and Ledger.strike_side("crit_avoid") == "target"
		),
		"the engine declares which side of a strike reads each term"
	)
	# EVERY term must have a side. One added without one would be invisible in every readout
	# while still changing the fight — the silent failure this whole slice exists to close.
	var unsided: Array[String] = []
	for term in Ledger.terms():
		if Ledger.strike_side(term) == "":
			unsided.append(term)
	failed += _check(unsided.is_empty(), "no term is missing a strike side: %s" % str(unsided))

	var actor := StubUnit.new()
	var target := StubUnit.new()
	var ledger = Ledger.new()
	ledger.attribute(_effect("hit_bonus", "p", "r"))
	ledger.add("term", actor, "accuracy", 10)
	# The SAME profile's other effect, aimed at the opponent.
	ledger.add("term", target, "dodge", 5)
	# Read from the wrong side: the actor's own dodge is not part of the actor's strike, it is
	# part of the counter-strike where the actor is the target. It must not appear here twice.
	ledger.add("term", actor, "dodge", 99)
	ledger.attribute({})

	var rows := Readout.build([_record("p", {})], ledger, actor, target)
	failed += _check(rows.size() == 1, "one profile, one row, whichever side its terms landed on")
	if rows.is_empty():
		return failed
	var terms: Array = rows[0]["terms"]
	failed += _check(
		terms.size() == 2,
		"the strike reads two of the three terms recorded: %s" % String(rows[0]["summary"])
	)
	failed += _check(
		String(rows[0]["summary"]) == "+10 Hit, +5 Avoid (opponent)",
		(
			"the opponent's contribution is NAMED as theirs and signed as the author wrote it: %s"
			% String(rows[0]["summary"])
		)
	)
	failed += _check(
		String(rows[0]["direction"]) == "mixed",
		(
			"a bonus to the actor and avoid to the opponent is MIXED, not advantage: %s"
			% String(rows[0]["direction"])
		)
	)
	var avoid := _term_named(terms, "dodge")
	failed += _check(
		String(avoid["on"]) == "target" and not bool(avoid["helps"]),
		"+5 avoid on the opponent does not help the strike, though its value is positive"
	)
	return failed


# AUTHORED PRESENTATION OVER A GENERIC FALLBACK — the 2026-09-10 ruling, in both directions.
func _presentation_checks() -> int:
	var failed := 0
	var actor := StubUnit.new()
	var target := StubUnit.new()

	var authored = Ledger.new()
	authored.attribute(_effect("hit_bonus", "weapon_triangle", "sword_vs_axe"))
	authored.add("term", actor, "accuracy", 10)
	var authored_rows := (
		Readout
		. build(
			[
				_record(
					"weapon_triangle",
					{
						"label_key": "interaction.weapon_triangle",
						"glyph": "✦",
						"color": "#61c454",
						"display_order": 30,
					}
				)
			],
			authored,
			actor,
			target
		)
	)
	failed += _check(
		(
			String(authored_rows[0]["glyph"]) == "✦"
			and String(authored_rows[0]["color"]) == "#61c454"
			and int(authored_rows[0]["display_order"]) == 30
			and bool(authored_rows[0]["authored"])
		),
		"an authored glyph, colour and order are used as written"
	)
	# Nothing has translated `interaction.weapon_triangle`, and showing a player a raw
	# localisation key would be the wrong failure. The key's own last segment is humanised, so
	# the AUTHORED value is still what is read and a real translation replaces it with no
	# change here.
	failed += _check(
		String(authored_rows[0]["label"]) == "Weapon Triangle",
		(
			"an untranslated label_key falls back to its own last segment, humanised: %s"
			% String(authored_rows[0]["label"])
		)
	)

	var generic = Ledger.new()
	generic.attribute(_effect("hit_bonus", "armour_bane", "vs_armour"))
	generic.add("term", actor, "accuracy", -5)
	var generic_rows := Readout.build([_record("armour_bane", {})], generic, actor, target)
	failed += _check(
		(
			String(generic_rows[0]["label"]) == "Armour Bane"
			and String(generic_rows[0]["glyph"]) == Readout.GLYPH_DISADVANTAGE
			and String(generic_rows[0]["color"]) == ""
			and not bool(generic_rows[0]["authored"])
		),
		"a profile declaring nothing renders generically: humanised id, direction glyph, no colour"
	)
	# The colour is left EMPTY rather than defaulted, because this module cannot see the surface
	# that will draw it. `direction` is what it knows; the panel maps that to its own palette.
	failed += _check(
		String(generic_rows[0]["direction"]) == "disadvantage",
		"...and the surface is given a direction to map instead of a colour it did not choose"
	)

	# An author asking for NO glyph is not the same as an author who said nothing, and
	# substituting the generic glyph would overrule them.
	var blank = Ledger.new()
	blank.attribute(_effect("hit_bonus", "p", "r"))
	blank.add("term", actor, "accuracy", 10)
	var blank_rows := Readout.build([_record("p", {"glyph": ""})], blank, actor, target)
	failed += _check(
		String(blank_rows[0]["glyph"]) == "",
		"an explicitly empty authored glyph means no glyph, not the generic one"
	)
	return failed


# The author's order wins; declaration order breaks every tie.
func _order_checks() -> int:
	var failed := 0
	var actor := StubUnit.new()
	var target := StubUnit.new()
	var ledger = Ledger.new()
	# Contributed in the order last, first, middle — so a readout that simply echoed the ledger
	# would come out wrong.
	ledger.attribute(_effect("hit_bonus", "late", "r"))
	ledger.add("term", actor, "accuracy", 1)
	ledger.attribute(_effect("hit_bonus", "early", "r"))
	ledger.add("term", actor, "damage", 1)
	ledger.attribute(_effect("hit_bonus", "unordered_a", "r"))
	ledger.add("term", actor, "crit", 1)
	ledger.attribute(_effect("hit_bonus", "unordered_b", "r"))
	ledger.add("term", actor, "crit", 1)
	ledger.attribute({})

	var records := [
		_record("late", {"display_order": 50}),
		_record("early", {"display_order": 5}),
		_record("unordered_a", {}),
		_record("unordered_b", {}),
	]
	var ids: Array[String] = []
	for row in Readout.build(records, ledger, actor, target):
		ids.append(String(row["profile_id"]))
	# The two unordered profiles sit at 0, ahead of both authored orders, and keep the order
	# their terms were contributed in — which is resolution order. The tie-break is explicit in
	# the comparator because `sort_custom` is not documented as stable.
	failed += _check(
		ids == ["unordered_a", "unordered_b", "early", "late"],
		"authored display_order wins and contribution order breaks the tie: %s" % str(ids)
	)
	return failed


# A profile's row is ITS share of the ledger's totals: additive terms sum, percent terms
# compose, and a term that composed back to the identity is dropped rather than shown as a
# relationship that applied and did nothing.
func _composition_checks() -> int:
	var failed := 0
	var actor := StubUnit.new()
	var target := StubUnit.new()
	var ledger = Ledger.new()
	ledger.attribute(_effect("hit_bonus", "p", "first"))
	ledger.add("term", actor, "accuracy", 10)
	ledger.attribute(_effect("hit_bonus", "p", "second"))
	ledger.add("term", actor, "accuracy", -4)
	ledger.attribute(_effect("might", "p", "third"))
	ledger.add("term", actor, "might_multiplier_pct", 300)
	ledger.attribute(_effect("might", "p", "fourth"))
	ledger.add("term", actor, "might_multiplier_pct", 150)
	ledger.attribute({})

	var rows := Readout.build([_record("p", {})], ledger, actor, target)
	failed += _check(
		String(rows[0]["summary"]) == "+6 Hit, ×4.5 Might",
		(
			"one profile's contributions sum and compose into its own row: %s"
			% String(rows[0]["summary"])
		)
	)
	failed += _check(
		rows[0]["rule_ids"] == ["first", "second", "third", "fourth"],
		"...and every rule that contributed is named once, in order: %s" % str(rows[0]["rule_ids"])
	)
	# The row's percent value is the composed MULTIPLIER, not the authored percent. A consumer
	# printing "×%s" must not need to know the ledger's storage units.
	failed += _check(
		is_equal_approx(float(_term_named(rows[0]["terms"], "might_multiplier_pct")["value"]), 4.5),
		"a percent term reaches the row as a multiplier, not as 450"
	)
	# The ledger's own total for the same unit and term must agree with the row: the row is a
	# share of the arithmetic, never a second computation of it.
	failed += _check(
		(
			is_equal_approx(ledger.multiplier(actor, "might_multiplier_pct"), 4.5)
			and ledger.additive(actor, "accuracy") == 6
		),
		"...and it equals what the STRIKE will use, because both read the same entries"
	)

	var cancelled = Ledger.new()
	cancelled.attribute(_effect("hit_bonus", "p", "up"))
	cancelled.add("term", actor, "accuracy", 5)
	cancelled.attribute(_effect("hit_bonus", "p", "down"))
	cancelled.add("term", actor, "accuracy", -5)
	cancelled.attribute({})
	var cancelled_rows := Readout.build([_record("p", {})], cancelled, actor, target)
	failed += _check(
		(
			cancelled_rows.size() == 1
			and (cancelled_rows[0]["terms"] as Array).is_empty()
			and String(cancelled_rows[0]["direction"]) == "neutral"
		),
		"a profile whose numbers cancel keeps its row and shows no term: it applied, it did nothing"
	)
	return failed


# The More Info body is GENERATED from the resolution. `[ITR-6]` is explicit that the old
# hardcoded triangle sentence is replaced rather than corrected, and it had to be: it described
# a tome triangle the shipping table did not have.
func _detail_checks() -> int:
	var failed := 0
	var actor := StubUnit.new()
	var target := StubUnit.new()
	var ledger = Ledger.new()
	ledger.attribute(_effect("hit_bonus", "weapon_triangle", "sword_vs_axe"))
	ledger.add("term", actor, "accuracy", 10)
	ledger.attribute({})

	var record := _record("weapon_triangle", {"label_key": "interaction.weapon_triangle"})
	record["stack_group"] = "weapon_triangle"
	record["stack_policy"] = "highest"
	record["suppressed_rules"] = [
		{
			"rule_id": "sword_vs_lance",
			"by": {"profile_id": "reaver", "rule_id": "invert", "reason": "suppresses"},
		}
	]
	var detail := String(Readout.build([record], ledger, actor, target)[0]["detail"])
	failed += _check(
		(
			"Weapon Triangle" in detail
			and "+10 Hit" in detail
			and "sword_vs_axe" in detail
			and "'highest'" in detail
		),
		(
			"the description names the relationship, its numbers, its rule and its policy:\\n%s"
			% detail
		)
	)
	failed += _check(
		"sword_vs_lance" in detail and "reaver" in detail,
		"...and a rule of the same profile that was SUPPRESSED says so, and by whom"
	)
	failed += _check(
		not ("fire>wind>thunder" in detail),
		"nothing here restates a relationship the engine no longer owns"
	)
	var player_detail := Readout._detail(
		"Weapon Triangle", ["sword_vs_axe"], "+10 Hit", record, false
	)
	failed += _check(
		(
			("sword_vs_axe" not in player_detail)
			and ("Matched:" not in player_detail)
			and ("Weapon Triangle" in player_detail)
		),
		"player-facing More Info hides raw authoring rule IDs while retaining the relationship copy"
	)
	return failed


# ── helpers ──────────────────────────────────────────────────────────────────


# A planned effect as `InteractionEffectBridge.plan()` shapes it, reduced to the keys the
# ledger's attribution reads. Built here rather than by calling the bridge because this suite
# is about the readout: a bridge failure should fail the bridge's suite.
func _effect(composition_id: String, profile_id: String, rule_id: String) -> Dictionary:
	return {
		"composition_id": composition_id,
		"rule_id": rule_id,
		"stack_group": profile_id,
		"composed_from": [{"profile_id": profile_id, "rule_id": rule_id}],
	}


# A resolver record, reduced to the keys the readout reads. `presentation` is the authored
# readout the record now carries.
func _record(profile_id: String, presentation: Dictionary) -> Dictionary:
	return {
		"profile_id": profile_id,
		"presentation": presentation,
		"stack_group": "",
		"stack_policy": "",
		"suppressed_rules": [],
	}


func _term_named(terms: Variant, term: String) -> Dictionary:
	for entry in terms as Array:
		if String((entry as Dictionary)["term"]) == term:
			return entry as Dictionary
	return {}


func _keys(value: Dictionary) -> Array:
	var keys: Array[String] = []
	for key in value.keys():
		keys.append(String(key))
	keys.sort()
	return keys


func _sorted(value: Array) -> Array:
	var out: Array[String] = []
	for entry in value:
		out.append(String(entry))
	out.sort()
	return out


func _check(ok: bool, label: String) -> int:
	print(("OK  " if ok else "FAIL ") + label)
	return 0 if ok else 1
