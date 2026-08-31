extends SceneTree

const Context = preload("res://scripts/actions/ActionContext.gd")
const StateView = preload("res://scripts/actions/EffectStateView.gd")

var _passed := 0
var _failed := 0


func _check(value: bool, label: String) -> void:
	if value:
		print("OK  %s" % label)
		_passed += 1
	else:
		print("FAIL %s" % label)
		_failed += 1


func _context(domain: String, live: Dictionary) -> RefCounted:
	var context = Context.new(domain, {})
	context.target_refs["campaign"] = "prometheus-proving-grounds-internal-fe"
	context.state_view = StateView.new()
	context.state_view.register_authority(
		"campaign",
		func(field, _ref): return live[field],
		func(field, _ref, value): live[field] = value
	)
	return context


func _init() -> void:
	await process_frame
	var data_manager := root.get_node_or_null("DataManager")
	var registry := root.get_node_or_null("RegistryManager")
	var runner := root.get_node_or_null("ActionEffectRunner")
	var projection := root.get_node_or_null("ProjectionService")
	var pack_path := ProjectSettings.globalize_path(
		"res://../Project_Prometheus_Campaign_Pack_FE/packs/proving_grounds"
	)
	# Exact-staged checks run the project from a temporary tree while retaining
	# the invoking workspace as PWD. Resolve the authored sibling from that root
	# so the proof still exercises the real pack rather than a copied fixture.
	if not DirAccess.dir_exists_absolute(pack_path):
		pack_path = (
			OS
			. get_environment("PWD")
			. path_join("../Project_Prometheus_Campaign_Pack_FE/packs/proving_grounds")
			. simplify_path()
		)
	if not DirAccess.dir_exists_absolute(pack_path):
		pack_path = (
			OS
			. get_environment("PWD")
			. path_join("repo/Project_Prometheus_Campaign_Pack_FE/packs/proving_grounds")
			. simplify_path()
		)
	if not DirAccess.dir_exists_absolute(pack_path):
		print("SKIP shared-effect pack proof: sibling FE proving_grounds checkout unavailable")
		quit(0)
		return
	var selected: bool = data_manager.select_tier2_campaign_source(
		pack_path, "prometheus-proving-grounds-internal-fe", "0.1.0"
	)
	_check(
		(
			selected
			and registry.has_entry("action_primitives", "set_session6_proof")
			and registry.has_entry("effect_compositions", "session6_cross_source_proof")
		),
		"selecting the FE campaign loads its authored primitive and composition"
	)
	if not selected:
		print("\nResults: %d passed, %d failed" % [_passed, _failed])
		quit(1)
		return

	var replay_deltas: Array = []
	for domain in ["item", "condition", "story"]:
		var live := {"campaign_vars.session6_proof": false}
		var preview_context := _context(domain, live)
		var preview = projection.project_effect(
			"session6_cross_source_proof", preview_context, "test"
		)
		_check(
			(
				preview.valid
				and not live["campaign_vars.session6_proof"]
				and preview.rng_summary.committed_draws == 0
			),
			"%s source previews through the shared zero-mutation transaction" % domain
		)
		var commit_context := _context(domain, live)
		var committed = runner.commit_composition("session6_cross_source_proof", commit_context)
		if not committed.ok:
			print("Commit failure (%s): %s" % [domain, committed.failure_reason])
		if not live["campaign_vars.session6_proof"]:
			print(
				(
					"Commit evidence (%s): fields=%s deltas=%s"
					% [domain, committed.save_fields_touched, committed.deltas]
				)
			)
		_check(
			(
				committed.ok
				and live["campaign_vars.session6_proof"]
				and committed.save_fields_touched == ["campaign_vars.session6_proof"]
			),
			"%s source commits the same primitive with touched-field evidence" % domain
		)
		replay_deltas.append(committed.deltas)
		var round_trip: Dictionary = bytes_to_var(var_to_bytes(live))
		_check(
			round_trip["campaign_vars.session6_proof"],
			"%s committed outcome survives save/load serialization" % domain
		)
	_check(
		replay_deltas[0] == replay_deltas[1] and replay_deltas[1] == replay_deltas[2],
		"all three authored sources produce identical deterministic journal evidence"
	)

	var stale_live := {"campaign_vars.session6_proof": false}
	var stale_context := _context("story", stale_live)
	var prepared = runner.prepare_composition("session6_cross_source_proof", stale_context)
	stale_live["campaign_vars.session6_proof"] = true
	var stale: Dictionary = stale_context.state_view.commit()
	if stale.ok:
		print("Unexpected stale outcome: %s prepared=%s" % [stale, prepared.failure_reason])
	_check(
		prepared.ok and not stale.ok and stale.code == "stale_precondition",
		"required effect rejects stale state without overwriting the intervening value"
	)

	print("\nResults: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
