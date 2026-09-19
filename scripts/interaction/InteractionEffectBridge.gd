class_name InteractionEffectBridge
extends RefCounted
# The EFFECT BRIDGE for authored trait interactions — slice 4 of
# AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10. It is the one place a resolved interaction
# stops being a description and becomes something that runs: composition ids are looked up
# in the registry catalogue, magnitudes leave fixed point, and the whole lot is prepared
# into the caller's transaction through `ActionPrimitiveRunner`. `[ITR-1..7]`.
#
# IT IS TWO CALLS, NOT ONE, and the split is the point. `plan()` is pure — no registry
# writes, no transaction, no unit touched — so a FORECAST and an EXECUTION can share it
# and be reading the same answer by construction rather than by two call sites agreeing.
# `apply()` is the half that prepares. `[ITR-6]` asked for one truth for consumers; two
# implementations of "what would this interaction do" is exactly how `preview_combat()`
# and `project_exchange()` drifted apart.
#
# WHAT IT READS. `InteractionRuleResolver.resolve()`'s envelope, and specifically
# `envelope.effects` — the flat, composed, ordered list. `records[i].effects` is that SAME
# list split per profile, so a consumer that walks both applies everything twice. This
# file reads `effects` and never `records`; `records` and `groups` are provenance for a
# reader, not a second work list.
#
# THE SINGLE CONVERSION OUT OF FIXED POINT. Every magnitude in the envelope is in units of
# `FormulaEvaluator.SCALE`, because that is the representation the whole value-term
# pipeline computes in. Exactly one boundary leaves it: here, through
# `FormulaEvaluator.to_int()`, at the moment a magnitude becomes a primitive's parameter.
# A consumer that reads `magnitude_fixed` and passes 3000 to a primitive expecting 3 is
# the defect the `_fixed` suffix exists to prevent, and the reason the planned effect
# carries BOTH numbers is so a diagnostic can show the authored one without re-deriving it.
#
# WHAT IT DOES NOT DO. It does not bind subjects: `plan()` is handed an envelope that was
# already resolved against bound subjects, and `apply()` is handed a context whose
# `subjects` the DOMAIN ADAPTER filled. Slice 5's combat adapter is that binder for
# `combat`, and it is the row's completion bar — this file is the seam it calls, not the
# caller itself.
#
# Authority: the `[ITR-1..7]` rulings. Resolve them through `GDD_Feature_Index.md` rather
# than by path.

const Formula = preload("res://scripts/req/FormulaEvaluator.gd")
const Schema = preload("res://scripts/interaction/InteractionProfileSchema.gd")
const Result = preload("res://scripts/actions/ActionResult.gd")

# The shape `plan()` returns. `effects` is what `apply()` executes, in envelope order;
# `skipped` is every payload that will NOT run and the reason it will not, because "my
# rule matched, the pack validated, and nothing happened" is the failure this system is
# most able to produce silently; `errors` is the bridge's own refusals.
const PLAN_FIELDS: Array[String] = ["context", "effects", "skipped", "errors"]

# One planned effect. `magnitude_fixed` is carried beside `magnitude` so a readout can
# show what the author's value term produced without multiplying back up and guessing at
# the rounding. `step_overrides` is the finished argument for
# `ActionPrimitiveRunner.prepare_composition()`.
const EFFECT_FIELDS: Array[String] = [
	"composition_id",
	"rule_id",
	"stack_group",
	"composed_from",
	"target",
	"params",
	"magnitude",
	"magnitude_fixed",
	"reads_magnitude",
	"step_overrides",
]

# Why a payload will not run. Each is a sentence a reader can act on rather than a code.
const SKIP_UNKNOWN_COMPOSITION := "composition '%s' is not in the registry catalogue; the pack that declares it is not active"
const SKIP_UNAVAILABLE := "its magnitude could not be evaluated and composition '%s' binds one at step '%s'"
const SKIP_UNDECLARED_PARAM := "composition '%s' step '%s' binds the magnitude to parameter '%s', which primitive '%s' does not declare"

# The key a step uses to declare that it reads the authored magnitude. Declared here
# beside the reader so the registry entry and the bridge cannot disagree about its
# spelling; `RegistryCatalog` checks its shape when the entry registers.
const MAGNITUDE_PARAM := "magnitude_param"


# Turns a resolved envelope into the work `apply()` will do, WITHOUT doing any of it.
#
# `deps` carries:
#   "catalog" — a RegistryCatalog or RegistryManager (anything answering `has_entry`
#               and `entry`), REQUIRED; there is no composition without one
#   "round"   — the rounding mode for the fixed-point conversion (optional, "half_up")
#
# A missing catalogue is reported rather than skipped, for the same reason the schema
# reports one: silence would turn "nothing could be resolved" into "nothing applies", and
# those are opposite facts about a fight.
static func plan(envelope: Dictionary, deps: Dictionary = {}) -> Dictionary:
	var errors: Array[String] = []
	var effects: Array[Dictionary] = []
	var skipped: Array[Dictionary] = []
	var context_id := String(envelope.get("context", ""))
	var catalog: Variant = deps.get("catalog")
	var round_mode := String(deps.get("round", "half_up"))

	# Checked against the CONTRACT rather than against the one key this file happens to
	# read, so a caller that hands over a hand-built dictionary is told it is not an
	# envelope instead of being quietly treated as an empty one.
	for field in Schema.ENVELOPE_FIELDS:
		if not envelope.has(field):
			errors.append("the envelope is missing '%s'; this is not a resolver envelope" % field)
	if not errors.is_empty():
		return _plan(context_id, effects, skipped, errors)
	if catalog == null or not catalog.has_method("has_entry") or not catalog.has_method("entry"):
		errors.append("no registry catalogue was supplied; no composition can be resolved")
		return _plan(context_id, effects, skipped, errors)

	# The resolver already reported its own errors; carrying them forward means a caller
	# that only ever looks at the plan still sees them. It does NOT stop the bridge: the
	# resolver returns the records it could resolve alongside the errors it could not,
	# and dropping the good ones because a sibling profile was unreadable would turn a
	# reported problem into a silent behaviour change.
	for message in envelope.get("errors", []):
		errors.append("resolver: %s" % String(message))

	for payload in envelope["effects"]:
		var effect := payload as Dictionary
		var composition_id := String(effect.get("composition_id", ""))
		if not catalog.has_entry("effect_compositions", composition_id):
			skipped.append(_skipped(effect, SKIP_UNKNOWN_COMPOSITION % composition_id))
			continue
		var steps: Array = catalog.entry("effect_compositions", composition_id).composition
		var planned := _plan_effect(effect, composition_id, steps, catalog, round_mode)
		if planned.has("skip"):
			skipped.append(_skipped(effect, String(planned["skip"])))
			continue
		effects.append(planned["effect"] as Dictionary)

	return _plan(context_id, effects, skipped, errors)


# UNAVAILABLE MAGNITUDES, the ruling slice 3 left open.
#
# `all` is the only stack policy that does not read a magnitude, so it is the only one
# that passes an `available: false` payload through to here. The answer is NOT a blanket
# one in either direction. Dropping every such payload would contradict the reason the
# case exists: a composition that binds no magnitude at all — a flag, a condition, "this
# unit cannot double" — is unaffected by a number nobody was going to read, and refusing
# it would make an unevaluable value term silently disable an effect that never wanted one.
# Running every such payload is worse: a composition that DOES bind a magnitude would be
# handed a number the author's formula could not produce, which is inventing one.
#
# So the STEP decides, by declaring `magnitude_param` or not. That keeps the engine from
# branching on composition ids — the registry entry says what it reads, exactly as it
# already says which primitive it runs and which parameters that primitive takes.
static func _plan_effect(
	effect: Dictionary, composition_id: String, steps: Array, catalog: Variant, round_mode: String
) -> Dictionary:
	var available := bool(effect.get("available", true))
	var magnitude_fixed := int(effect.get("magnitude_fixed", Formula.SCALE))
	var magnitude := Formula.to_int(magnitude_fixed, round_mode)
	var params: Dictionary = (effect.get("params", {}) as Dictionary).duplicate(true)
	var target := String(effect.get("target", ""))
	var reads_magnitude := false
	var step_overrides: Dictionary = {}

	for step in steps:
		var entry_step := step as Dictionary
		var step_id := String(entry_step.get("step_id", ""))
		var override: Dictionary = {"params": params.duplicate(true)}
		# THE AUTHORED TARGET WINS OVER THE STEP'S, but only for a SUBJECT. An interaction
		# profile binds subjects and nothing else, so `target`/`equipped_target` is a
		# statement it is entitled to make and the composition's own subject key is the
		# generic one it was registered with. A step aimed at a tile, a party or the
		# campaign is aimed at something no profile can name, so it is left alone.
		if String((entry_step.get("target", {}) as Dictionary).get("kind", "")) == "subject":
			override["target"] = {"kind": "subject", "key": target}
		if entry_step.has(MAGNITUDE_PARAM):
			var param_id := String(entry_step[MAGNITUDE_PARAM])
			var primitive_id := String(entry_step.get("primitive_id", ""))
			if not _declares_param(catalog, primitive_id, param_id):
				return {
					"skip":
					SKIP_UNDECLARED_PARAM % [composition_id, step_id, param_id, primitive_id]
				}
			if not available:
				return {"skip": SKIP_UNAVAILABLE % [composition_id, step_id]}
			reads_magnitude = true
			(override["params"] as Dictionary)[param_id] = magnitude
		step_overrides[step_id] = override

	return {
		"effect":
		{
			"composition_id": composition_id,
			"rule_id": String(effect.get("rule_id", "")),
			"stack_group": String(effect.get("stack_group", "")),
			"composed_from": (effect.get("composed_from", []) as Array).duplicate(true),
			"target": target,
			"params": params,
			"magnitude": magnitude,
			"magnitude_fixed": magnitude_fixed,
			"reads_magnitude": reads_magnitude,
			"step_overrides": step_overrides,
		}
	}


# A primitive that declares no parameters at all still answers this honestly: an entry
# with an empty `params_schema` declares nothing, so binding a magnitude to it is the
# authoring mistake this refuses rather than a special case to wave through.
static func _declares_param(catalog: Variant, primitive_id: String, param_id: String) -> bool:
	if not catalog.has_entry("action_primitives", primitive_id):
		return false
	return (catalog.entry("action_primitives", primitive_id).params_schema as Dictionary).has(
		param_id
	)


# Prepares every planned effect into `context`'s transaction, in envelope order.
#
# IT COMMITS NOTHING. `prepare_composition` appends to the caller's journal and the caller
# decides whether that journal is committed or dropped — which is what lets a forecast run
# the identical code path as a live exchange and then throw the transaction away.
#
# A FAILURE ABORTS THE WHOLE APPLY. By the time an interaction reaches here its pack has
# been through `InteractionProfileSchema.validate()` at activation, so a refusal at this
# point is an engine fault, not authored data. The standing answer to bad authored
# arithmetic is to refuse it at load and never to fail half-applied mid-combat, so
# returning the failure with the transaction uncommitted is what "never half-applied"
# means here: the caller drops the journal and the fight is where it was.
# `runner` is typed as an Object, not an ActionPrimitiveRunner, because in production it is
# the `ActionEffectRunner` AUTOLOAD -- a Node wrapping one. Typing the parameter RefCounted
# made the shipped runner the one thing that could not be passed, which the first adapter
# discovered by being unable to call its own seam.
#
# `on_effect` IS HOW A DOMAIN ADAPTER ATTRIBUTES WHAT ITS CHANNEL RECORDS, and slice 6 is
# why it exists. A composition writes wherever its primitives write; the bridge cannot know
# that combat's `apply_combat_term` lands a number on a ledger, and the ledger cannot know
# which authored rule it came from, because a step carries a `step_id` and not a rule. The
# alternative was to correlate the ledger's entries with the plan's effects by ORDER, which
# is true right up to the first composition that writes twice or not at all — and then the
# readout names the wrong rule, silently, in front of the player. So the bridge says which
# planned effect it is about to run, once, before running it, and the adapter decides what
# that means for its own channel. It is deliberately a notification and not a filter: a
# callable that refuses cannot stop an effect, because "what applies" was settled by the
# resolver and re-deciding it here would be a second composition pass.
static func apply(
	plan_result: Dictionary, runner: Object, context: RefCounted, on_effect: Callable = Callable()
) -> ActionResult:
	if runner == null or not runner.has_method("prepare_composition"):
		return Result.failure("no_runner", "An action primitive runner is required.")
	if context == null:
		return Result.failure("invalid_context", "Action context is required.")
	var aggregate := Result.success()
	# THE SUBJECT MAP IS RESTORED BETWEEN COMPOSITIONS, and the first adapter is what found
	# out why. `ActionPrimitiveRunner._resolve_target` resolves a step's target by writing it
	# to `subjects["target"]` -- so after one effect aimed at `source` has run, the key
	# `target` no longer holds the target the CALLER bound, and the next effect aimed at
	# `target` resolves to the previous effect's subject instead. One rule granting the
	# attacker a bonus and taking one from the defender would have applied both to the
	# attacker. Restoring the caller's bindings before each composition is the fix that keeps
	# the runner's convention intact.
	var bound_subjects: Dictionary = (context.subjects as Dictionary).duplicate()
	for planned in plan_result.get("effects", []):
		var effect := planned as Dictionary
		context.subjects = bound_subjects.duplicate()
		if on_effect.is_valid():
			on_effect.call(effect)
		var composition_result: ActionResult = runner.prepare_composition(
			String(effect["composition_id"]), context, effect["step_overrides"] as Dictionary
		)
		composition_result.step_id = String(effect["composition_id"])
		if not composition_result.ok:
			return composition_result
		aggregate.steps.append(composition_result)
		for field in composition_result.save_fields_touched:
			if not aggregate.save_fields_touched.has(field):
				aggregate.save_fields_touched.append(field)
		for affected in composition_result.affected_ids:
			if not aggregate.affected_ids.has(affected):
				aggregate.affected_ids.append(affected)
		aggregate.messages.append_array(composition_result.messages)
	return aggregate


static func _plan(
	context_id: String,
	effects: Array[Dictionary],
	skipped: Array[Dictionary],
	errors: Array[String]
) -> Dictionary:
	return {
		"context": context_id,
		"effects": effects,
		"skipped": skipped,
		"errors": errors,
	}


static func _skipped(effect: Dictionary, reason: String) -> Dictionary:
	return {
		"composition_id": String(effect.get("composition_id", "")),
		"rule_id": String(effect.get("rule_id", "")),
		"stack_group": String(effect.get("stack_group", "")),
		"reason": reason,
	}
