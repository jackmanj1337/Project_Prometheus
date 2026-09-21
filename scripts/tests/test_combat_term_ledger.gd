extends SceneTree
# Slice 5 of AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10: THE COMBAT TERM CHANNEL.
#
# Slices 1-4 got an authored interaction as far as a plan. This is the half that lets one
# reach a strike: the engine-declared term vocabulary, the `apply_combat_term` primitive
# that writes into a `CombatTermLedger` instead of into the journal, and the shipped
# registry entries that connect them. The adapter that calls all of it is
# `CombatResolver.strike_forecast()`, tested in `test_combat_interaction_adapter.gd`.
#
# The registry entries are LOADED FROM engine_data rather than re-declared, so this suite
# fails if a shipped composition stops naming a real term or a real parameter. A
# re-declared copy would keep passing while the game shipped a broken one.

const Ledger = preload("res://scripts/combat/CombatTermLedger.gd")
const Bridge = preload("res://scripts/interaction/InteractionEffectBridge.gd")
const Resolver = preload("res://scripts/interaction/InteractionRuleResolver.gd")
const RequirementSystemScript = preload("res://scripts/autoloads/RequirementSystem.gd")
const RegistryCatalogScript = preload("res://scripts/registries/RegistryCatalog.gd")
const RunnerScript = preload("res://scripts/actions/ActionPrimitiveRunner.gd")
const RegistryManagerScript = preload("res://scripts/autoloads/RegistryManager.gd")
const ContextScript = preload("res://scripts/actions/ActionContext.gd")
const RequestScript = preload("res://scripts/actions/ActionRequest.gd")

const PRIMITIVES := "res://engine_data/registries/action_primitives"
const COMPOSITIONS := "res://engine_data/registries/effect_compositions"

# Filled by `_catalog()` and asserted, so a shipped entry that stops validating fails this
# suite instead of printing beside a green run.
var _catalog_errors: Array[String] = []


# A combatant, as the predicates and the ledger see one: authored groups to match on and
# an identity to key terms by.
class StubUnit:
	extends Node

	var groups: Array[String] = []

	func _init(in_groups: Array[String] = []) -> void:
		groups = in_groups


func _init() -> void:
	print("=== Combat Term Ledger Test ===")
	var failed := 0
	failed += _vocabulary_checks()
	failed += _primitive_checks()
	failed += _end_to_end_checks()
	print("=== Combat Term Ledger Results: %d failed ===" % failed)
	quit(1 if failed else 0)


func _vocabulary_checks() -> int:
	var failed := 0
	var ledger = Ledger.new()
	var unit := StubUnit.new()
	var other := StubUnit.new()

	failed += _check(
		(
			Ledger.terms()
			== [
				"accuracy",
				"damage",
				"crit",
				"crit_avoid",
				"dodge",
				"might_multiplier_pct",
				"damage_multiplier_pct"
			]
		),
		"the term vocabulary is the ENGINE's, declared in one place"
	)
	failed += _check(
		not Ledger.is_term("triangle_advantage"),
		"a term the engine does not declare is not a term: a pack names a composition, not a slot"
	)

	failed += _check(ledger.additive(unit, "accuracy") == 0, "an empty ledger contributes nothing")
	failed += _check(
		ledger.multiplier(unit, "might_multiplier_pct") == 1.0,
		"...and multiplies by one, so a fight with no profiles is a fight with no relationships"
	)

	failed += _check(ledger.add("s1", unit, "accuracy", 10) == "", "a declared term records")
	failed += _check(ledger.add("s2", unit, "accuracy", -2) == "", "...and a second contribution")
	failed += _check(
		ledger.additive(unit, "accuracy") == 8, "additive terms SUM: +10 and -2 make +8"
	)
	failed += _check(
		ledger.additive(other, "accuracy") == 0,
		"...and are kept per unit, because a strike has two sides and they are not the same side"
	)

	failed += _check(ledger.add("s3", unit, "might_multiplier_pct", 300) == "", "percent records")
	failed += _check(
		is_equal_approx(ledger.multiplier(unit, "might_multiplier_pct"), 3.0), "300 percent is x3"
	)
	ledger.add("s4", unit, "might_multiplier_pct", 300)
	failed += _check(
		is_equal_approx(ledger.multiplier(unit, "might_multiplier_pct"), 9.0),
		"two percent contributions to one term MULTIPLY: x3 and x3 make x9, not x6"
	)
	failed += _check(
		ledger.add("s5", unit, "no_such_term", 1) != "",
		"an undeclared term is refused with a reason, never recorded as something else"
	)
	failed += _check(
		ledger.add("s6", null, "accuracy", 1) != "", "a term with no unit to apply to is refused"
	)
	failed += _check(
		ledger.contributions(unit).size() == 4,
		"every contribution is kept in order, so a readout can say where a number came from"
	)
	return failed


# The primitive, through a real runner over the SHIPPED entry.
func _primitive_checks() -> int:
	var failed := 0
	var catalog := _catalog()
	var runner = RunnerScript.new(catalog)
	var unit := StubUnit.new()
	var ledger = Ledger.new()

	failed += _check(
		_catalog_errors.is_empty(),
		"every shipped combat-term entry validates: %s" % ", ".join(_catalog_errors)
	)

	var context = ContextScript.new("combat", {"target": unit, "combat_terms": ledger})
	var request = (
		RequestScript
		. from_step(
			{
				"step_id": "term",
				"primitive_id": "apply_combat_term",
				"params": {"term": "accuracy", "delta": 10},
				"target": {"kind": "subject", "key": "target"},
				"required": true,
				"on_failure": "abort",
			}
		)
	)
	var prepared = runner.prepare(request, context)
	failed += _check(prepared.ok, "the shipped primitive prepares through the real runner")
	failed += _check(
		ledger.additive(unit, "accuracy") == 10, "...and the term landed on the ledger"
	)
	failed += _check(
		prepared.save_fields_touched.is_empty() and context.state_view.journal.entries.is_empty(),
		"IT WRITES NOTHING DURABLE: a term lasts one strike and never reaches the journal"
	)

	var no_ledger = ContextScript.new("combat", {"target": unit})
	var refused = runner.prepare(request, no_ledger)
	failed += _check(
		not refused.ok and String(refused.failure_reason["code"]) == "missing_subject",
		"without a ledger subject the primitive is REFUSED, not quietly skipped"
	)

	var bad_term = (
		RequestScript
		. from_step(
			{
				"step_id": "term",
				"primitive_id": "apply_combat_term",
				"params": {"term": "morale", "delta": 1},
				"target": {"kind": "subject", "key": "target"},
				"required": true,
				"on_failure": "abort",
			}
		)
	)
	var bad = runner.prepare(
		bad_term, ContextScript.new("combat", {"target": unit, "combat_terms": Ledger.new()})
	)
	failed += _check(
		not bad.ok and String(bad.failure_reason["code"]) == "invalid_combat_term",
		"a composition naming a term the engine does not declare fails loudly"
	)
	return failed


# A resolved profile, planned by the bridge, applied through the runner, read off the
# ledger — the whole chain the combat adapter runs, with nothing stubbed but the units.
func _end_to_end_checks() -> int:
	var failed := 0
	var requirements := RequirementSystemScript.new()
	requirements._ready()
	var attacker := StubUnit.new(["sword"])
	var defender := StubUnit.new(["axe"])
	var subjects := {
		"source": attacker,
		"target": defender,
		"equipped_source": attacker,
		"equipped_target": defender,
	}
	var profile := {
		"profile_id": "fixture_triangle",
		"context": "combat",
		"subjects": ["source", "target", "equipped_source", "equipped_target"],
		"priority": 100,
		"stack_group": "fixture_group",
		"stack_policy": "highest",
		"stops_below": false,
		"rules":
		[
			{
				"rule_id": "sword_beats_axe",
				"when":
				{
					"op": "all",
					"children":
					[
						{
							"predicate_id": "has_trait",
							"subject": {"kind": "equipped_source"},
							"params": {"id": "sword"},
						},
						{
							"predicate_id": "has_trait",
							"subject": {"kind": "equipped_target"},
							"params": {"id": "axe"},
						},
					],
				},
				"effects":
				[
					{
						"composition_id": "combat_accuracy_modifier",
						"target": "source",
						"magnitude": {"literal": 10},
					},
					{
						"composition_id": "combat_dodge_modifier",
						"target": "target",
						"magnitude": {"op": "neg", "operands": [{"literal": 5}]},
					},
				],
			}
		],
	}
	var catalog := _catalog()
	var envelope := Resolver.resolve([profile], "combat", subjects, {"requirements": requirements})
	var plan := Bridge.plan(envelope, {"catalog": catalog})
	failed += _check(
		plan["errors"].is_empty() and plan["skipped"].is_empty() and plan["effects"].size() == 2,
		"both authored effects plan against the SHIPPED compositions"
	)

	var ledger = Ledger.new()
	var runner = RunnerScript.new(catalog)
	var context = ContextScript.new("combat", subjects.duplicate())
	context.subjects["combat_terms"] = ledger
	var applied = Bridge.apply(plan, runner, context)
	failed += _check(applied.ok, "apply() runs the compositions through the real runner")
	failed += _check(
		ledger.additive(attacker, "accuracy") == 10,
		"the authored magnitude reached the strike as the attacker's accuracy term"
	)
	# The defect this pair of effects exists to catch: `_resolve_target` writes the resolved
	# subject back to `subjects["target"]`, so before the bridge restored the caller's
	# bindings between compositions, the SECOND effect resolved to the FIRST one's subject
	# and both landed on the attacker.
	failed += _check(
		ledger.additive(defender, "dodge") == -5,
		"an effect aimed at the target lands on the TARGET, after one aimed at the source"
	)
	failed += _check(
		ledger.additive(attacker, "dodge") == 0,
		"...and not on the source: the subject map is restored between compositions"
	)
	return failed


# Every engine entry this channel needs, loaded from what the game ships. Returned through
# a RegistryManager because that is what the runner takes in production -- a bare catalogue
# is a RefCounted and would not be the node the engine passes.
func _catalog() -> Node:
	var catalog = RegistryCatalogScript.new()
	for handler_id in RegistryCatalogScript.builtin_primitive_handlers():
		catalog.register_primitive_handler(handler_id)
	var errors: Array[String] = []
	errors.append_array(
		catalog.register_entry(ResourceLoader.load(PRIMITIVES.path_join("apply_combat_term.tres")))
	)
	for file_name in [
		"combat_accuracy_modifier.tres",
		"combat_damage_modifier.tres",
		"combat_crit_modifier.tres",
		"combat_crit_avoid_modifier.tres",
		"combat_dodge_modifier.tres",
		"combat_might_multiplier.tres",
		"combat_damage_multiplier.tres",
	]:
		errors.append_array(
			catalog.register_entry(ResourceLoader.load(COMPOSITIONS.path_join(file_name)))
		)
	_catalog_errors = errors
	var registry := RegistryManagerScript.new()
	root.add_child(registry)
	registry.restore_snapshot({"catalog": catalog, "errors": []})
	return registry


func _check(ok: bool, label: String) -> int:
	print(("OK  " if ok else "FAIL ") + label)
	return 0 if ok else 1
