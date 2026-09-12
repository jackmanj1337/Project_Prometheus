extends Node
## Routes forecasts to their owning resolver without committing live state.

const ProjectionContextScript = preload("res://scripts/projection/ProjectionContext.gd")
const ProjectionResultScript = preload("res://scripts/projection/ProjectionResult.gd")


func project(ctx: RefCounted) -> RefCounted:
	if ctx == null:
		return ProjectionResultScript.failure("missing_context")
	if ctx.budget <= 0:
		return ProjectionResultScript.failure("projection_budget_exhausted")
	if ctx.kind == "combat":
		return _project_combat(ctx)
	if ctx.kind == "effect":
		return _project_effect(ctx)
	return ProjectionResultScript.failure("unknown_projection_kind:%s" % ctx.kind)


func project_combat(attacker: Node, defender: Node, audience: String = "player") -> RefCounted:
	return project(ProjectionContextScript.combat(attacker, defender, audience))


func project_effect(
	composition_id: String, action_context: RefCounted, audience: String = "player"
) -> RefCounted:
	return project(ProjectionContextScript.effect(composition_id, action_context, audience))


func _project_effect(ctx: RefCounted) -> RefCounted:
	if ctx.action_context == null:
		return ProjectionResultScript.failure("missing_action_context")
	var runner := get_node_or_null("/root/ActionEffectRunner")
	if runner == null or not runner.has_method("prepare_composition"):
		return ProjectionResultScript.failure("effect_runner_unavailable")
	var rng_before := _rng_state()
	ctx.action_context.dry_run = true
	ctx.action_context.knowledge_policy = ctx.knowledge_policy
	var prepared: ActionResult = runner.call(
		"prepare_composition", ctx.composition_id, ctx.action_context
	)
	var result := ProjectionResultScript.new()
	if not prepared.ok:
		result.failure_reason = String(prepared.failure_reason.get("code", "effect_prepare_failed"))
		return result
	result.valid = true
	result.state_deltas.assign(prepared.deltas)
	for event_id in prepared.events_emitted:
		result.projected_events.append({"event": event_id})
	result.rng_summary = {
		"committed_draws": 0,
		"prepared_draws": prepared.rng_draws,
		"uncertain": prepared.uncertain.duplicate(true),
	}
	result.knowledge_flags = {"effects": ctx.knowledge_policy}
	if _rng_state() != rng_before:
		result.valid = false
		result.failure_reason = "projection_mutated_live_state"
		result.warnings.append("The effect adapter changed guarded RNG state.")
	return result


func _project_combat(ctx: RefCounted) -> RefCounted:
	if ctx.actor == null:
		return ProjectionResultScript.failure("missing_actor")
	if ctx.targets.is_empty() or ctx.targets[0] == null:
		return ProjectionResultScript.failure("missing_target")
	var resolver := get_node_or_null("/root/CombatResolver")
	if resolver == null or not resolver.has_method("preview_combat"):
		return ProjectionResultScript.failure("combat_resolver_unavailable")

	var rng_before := _rng_state()
	var gold_before: Variant = _party_gold()
	var outcome: Dictionary = resolver.call("preview_combat", ctx.actor, ctx.targets[0])
	var result := ProjectionResultScript.new()
	result.valid = true
	result.visible_outcome = outcome
	result.knowledge_flags = {"outcome": ctx.knowledge_policy}
	result.rng_summary = {
		"mode": ctx.rng_mode,
		"attacker_hit": outcome.get("attacker_hit", 0),
		"attacker_crit": outcome.get("attacker_crit", 0),
		"defender_hit": outcome.get("defender_hit", 0),
		"defender_crit": outcome.get("defender_crit", 0),
		"committed_draws": 0,
	}
	if ctx.audience in ["debug", "test"]:
		result.real_outcome = outcome.duplicate(true)
	if _rng_state() != rng_before or _party_gold() != gold_before:
		result.valid = false
		result.failure_reason = "projection_mutated_live_state"
		result.warnings.append("The combat adapter changed guarded save state.")
	return result


func _rng_state() -> Dictionary:
	var rng := get_node_or_null("/root/RngService")
	return rng.to_save_dict().duplicate(true) if rng != null else {}


func _party_gold() -> Variant:
	var game_state := get_node_or_null("/root/GameState")
	return game_state.party_gold if game_state != null else null
