extends SceneTree
# Session 8 adopter proof: the condition lifecycle and the stat overlay, driven
# against the AUTHORED Fire-Emblem proving-grounds pack rather than a fixture.
#
# The unit tests for both halves live elsewhere -- test_condition_manager.gd for
# the rules and the transactions, test_combat.gd for the formulas. What this
# proves is the thing neither of them can: that a condition somebody AUTHORED,
# reached through the same Tier-2 campaign source select_campaign() uses, applies
# and ticks and expires and debuffs a real fight, with no engine edit behind it.
# The engine ships zero condition ids, so if this pack's content were wrong there
# would be nothing to fall back on.
#
# The pack is located by scripts/tests/support/adopter_pack.gd; an unreachable
# pack FAILS wherever pack repos exist and skips only where none do.

const UnitScene = preload("res://scenes/units/Unit.tscn")
const EffectTransactionScript = preload("res://scripts/actions/EffectTransaction.gd")
const ActionContextScript = preload("res://scripts/actions/ActionContext.gd")
const ConditionModel = preload("res://scripts/conditions/ConditionModel.gd")
const AdopterPack = preload("res://scripts/tests/support/adopter_pack.gd")

const PACK_RELATIVE_PATH := "Project_Prometheus_Campaign_Pack_FE/packs/proving_grounds"
const PACK_ID := "prometheus-proving-grounds-internal-fe"
const PACK_VERSION := "0.1.0"
const ROSTER_ID := "roster_map_950_promotion_validation"

## The catalogue entry ids this proof cannot run without. Asserted before the
## first check so a checkout that predates the authored content is diagnosed
## once, instead of surfacing as a dozen bare FAIL lines with no error text.
const REQUIRED_ENTRY_IDS: Array[String] = [
	"conditions__proving_venom",
	"conditions__proving_drowse",
	"conditions__proving_ward",
	"tick_sources__proving_pulse",
	"effect_compositions__proving_venom_tick",
]

const VENOM := "proving_venom"
const DROWSE := "proving_drowse"
const WARD := "proving_ward"
const PULSE := "proving_pulse"

var _passed := 0
var _failed := 0


func _check(value: bool, label: String) -> void:
	if value:
		print("OK  %s" % label)
		_passed += 1
	else:
		print("FAIL %s" % label)
		_failed += 1


func _unit_from_roster(roster: Array, unit_id: String, tile: Vector2i, team: String) -> Node:
	for data in roster:
		if String(data.unit_id) != unit_id:
			continue
		var unit: Node = UnitScene.instantiate()
		root.add_child(unit)
		unit.initialize(data.duplicate(true), tile, team)
		return unit
	return null


func _turns_of(unit: Node, condition_id: String) -> int:
	var index := ConditionModel.index_of(
		ConditionModel.normalize(unit.data.conditions), condition_id
	)
	if index < 0:
		return -99
	return int(ConditionModel.normalize(unit.data.conditions)[index]["turns_remaining"])


func _init() -> void:
	print("=== Session 8 FE Pack Adopter Proof ===")
	await process_frame
	var data_manager := root.get_node_or_null("DataManager")
	var conditions := root.get_node_or_null("ConditionManager")
	var runner := root.get_node_or_null("ActionEffectRunner")
	var located := AdopterPack.locate(PACK_RELATIVE_PATH)
	if located["state"] == AdopterPack.ABSENT:
		print("SKIP: session 8 pack proof -- %s" % located["detail"])
		print("  The authored condition adopter coverage is NOT verified in this environment.")
		quit(0)
		return
	if located["state"] == AdopterPack.MISSING:
		print("FAIL session 8 pack proof -- %s" % located["detail"])
		print("\nResults: 0 passed, 1 failed")
		quit(1)
		return
	var content := AdopterPack.require_entries(located["path"], REQUIRED_ENTRY_IDS)
	if not content["ok"]:
		print("FAIL session 8 pack proof -- %s" % content["detail"])
		print("\nResults: 0 passed, 1 failed")
		quit(1)
		return
	if data_manager == null or conditions == null or runner == null:
		print(
			"FAIL the DataManager, ConditionManager and ActionEffectRunner autoloads are required"
		)
		print("\nResults: 0 passed, 1 failed")
		quit(1)
		return

	if not data_manager.select_tier2_campaign_source(located["path"], PACK_ID, PACK_VERSION):
		print("FAIL selecting the authored FE campaign source")
		quit(1)
		return
	print("OK  the authored FE proving-grounds campaign source is selected")
	_passed += 1

	# ---- the pack's conditions reached the live registry ----
	_check(
		(
			conditions.definition(VENOM) != null
			and conditions.definition(DROWSE) != null
			and conditions.definition(WARD) != null
		),
		"three conditions authored by the pack are live in the registry"
	)
	_check(
		(
			conditions.tick_source(PULSE) != null
			and String(conditions.tick_source(PULSE).publisher) == "authored"
		),
		"the pack's own tick source is live and is not an engine lifecycle point"
	)
	_check(
		(
			conditions.definitions().keys().all(func(id): return conditions.definition(id) != null)
			and conditions.definitions().size() == 3
		),
		"the engine contributed no condition ids of its own"
	)

	var roster: Array = data_manager.get_campaign_pack_roster(ROSTER_ID)
	var subject := _unit_from_roster(roster, "m950_cavalier", Vector2i(1, 0), "red")
	var attacker := _unit_from_roster(roster, "m950_mercenary", Vector2i(0, 0), "blue")
	if subject == null or attacker == null:
		print("FAIL the authored roster did not yield both proof units")
		quit(1)
		return
	print("OK  two units are deployed from the authored map_950 roster")
	_passed += 1

	# ---- applying an authored condition ----
	var defense_before: int = subject.get_effective_stat("defense")
	var apply := EffectTransactionScript.new()
	var report: Dictionary = conditions.prepare_apply(apply, subject, VENOM)
	_check(
		bool(report.get("ok", false)) and subject.data.conditions.is_empty(),
		"preparing the authored venom writes nothing to the live unit"
	)
	_check(
		subject.get_effective_stat("defense", apply.sink) == defense_before - 2,
		"the authored debuff is readable through the transaction before anything commits"
	)
	apply.commit()
	apply.flush_presentation(root.get_node_or_null("EventBus"))
	_check(
		(
			_turns_of(subject, VENOM) == 3
			and subject.get_effective_stat("defense") == defense_before - 2
		),
		"committing lands the condition with the duration and debuff the pack authored"
	)

	# ---- the debuff reaches a real fight ----
	var combat := root.get_node_or_null("CombatResolver")
	var forecast: Dictionary = combat.preview_combat(attacker, subject)
	var cured := EffectTransactionScript.new()
	conditions.prepare_remove(cured, subject, VENOM)
	cured.commit()
	combat.clear_exchange_projection_cache()
	var clean_forecast: Dictionary = combat.preview_combat(attacker, subject)
	_check(
		int(forecast["attacker_damage"]) > int(clean_forecast["attacker_damage"]),
		"an authored condition's stat debuff changes the damage a forecast reports"
	)

	# ---- the authored tick source, fired as the effect of an authored action ----
	var restore := EffectTransactionScript.new()
	conditions.prepare_apply(restore, subject, VENOM)
	conditions.prepare_apply(restore, subject, DROWSE)
	restore.commit()
	var hp_before: int = subject.data.hp
	var pulse := EffectTransactionScript.new()
	var context = ActionContextScript.new("condition", {"actor": subject, "target": subject})
	context.effect_sink = pulse.sink
	context.state_view = pulse.sink.state_view
	context.transaction = pulse
	var pulse_result = runner.prepare_composition("proving_pulse_effect", context)
	_check(pulse_result.ok, "an authored composition fires the pack's own named tick source")
	pulse.commit()
	_check(
		subject.data.hp == hp_before - 2 and _turns_of(subject, VENOM) == 2,
		"the pulse deals the authored tick damage and advances the venom's duration"
	)
	_check(
		_turns_of(subject, DROWSE) == 2,
		"...and leaves the condition that did not subscribe to that source untouched"
	)

	# ---- expiry through the engine's own published source ----
	var phase_sources: Array = conditions.sources_for_lifecycle("phase_start")
	_check(
		phase_sources.has("phase_start"),
		"the engine publishes its phase-start source for the pack's conditions to subscribe to"
	)
	for _index in 2:
		var tick := EffectTransactionScript.new()
		conditions.prepare_tick(tick, subject, "phase_start")
		tick.commit()
	_check(
		(
			not conditions.has_condition(subject, VENOM)
			and subject.get_effective_stat("defense") == defense_before
		),
		"the venom expires on schedule and takes its stat debuff with it"
	)

	# ---- immunity is authored, not engine-owned ----
	var ward := EffectTransactionScript.new()
	conditions.prepare_apply(ward, attacker, WARD)
	ward.commit()
	var refused := EffectTransactionScript.new()
	var refusal: Dictionary = conditions.prepare_apply(refused, attacker, VENOM)
	_check(
		(
			not bool(refusal.get("ok", false))
			and String(refusal.get("code", "")) == "immune"
			and attacker.data.conditions.size() == 1
		),
		"the pack's ward refuses the pack's poison, with no engine table involved"
	)

	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
