extends SceneTree
# The condition lifecycle, built on the shared effect contract (Session 8).
#
# The suite is deliberately split in two. ConditionModel is exercised as pure
# rules with no autoloads and no transaction, because stacking, duration and
# persistence are decisions that should be readable without a scene tree. The
# system is then exercised through REAL transactions against the REAL registry,
# because the claims that matter -- nothing is written until commit, one tick is
# one transaction, a named source ticks only its own subscribers -- are claims
# about the transaction, not about arithmetic.
#
# Fixture definitions are installed by swapping RegistryManager's catalogue
# through capture_snapshot/restore_snapshot, the same seam DataManager's content
# session uses. The engine ships no condition ids by design, so a suite that
# needs one has to author it, exactly like a pack does.

const ConditionModel = preload("res://scripts/conditions/ConditionModel.gd")
const ConditionDefScript = preload("res://scripts/resources/ConditionDef.gd")
const TickSourceDefScript = preload("res://scripts/resources/TickSourceDef.gd")
const RegistryEntryScript = preload("res://scripts/resources/RegistryEntry.gd")
const RegistryCatalogScript = preload("res://scripts/registries/RegistryCatalog.gd")
const EffectTransactionScript = preload("res://scripts/actions/EffectTransaction.gd")
const UnitScene = preload("res://scenes/units/Unit.tscn")
const UnitDataScript = preload("res://scripts/resources/UnitData.gd")
const SaveCodec = preload("res://scripts/save/SaveCodec.gd")

var _passed := 0
var _failed := 0


func _check(value: bool, label: String) -> void:
	if value:
		print("OK  %s" % label)
		_passed += 1
	else:
		print("FAIL %s" % label)
		_failed += 1


# ---- Fixtures ----


func _strings(values: Array) -> Array[String]:
	var typed: Array[String] = []
	for value in values:
		typed.append(String(value))
	return typed


func _dicts(values: Array) -> Array[Dictionary]:
	var typed: Array[Dictionary] = []
	for value in values:
		typed.append(value as Dictionary)
	return typed


func _condition(id: String) -> Resource:
	var def = ConditionDefScript.new()
	def.id = id
	def.family = "conditions"
	def.label_key = "condition.%s" % id
	def.owner_feature = "SHARED-EFFECT-CONDITION-LIFECYCLE-2026-08-31"
	def.kind = "condition"
	def.docs_text = "Fixture condition for the Session 8 suite."
	def.test_fixture = {"fixture": true}
	return def


func _tick_source(id: String, publisher: String, lifecycle: String, scope: String) -> Resource:
	var source = TickSourceDefScript.new()
	source.id = id
	source.family = "tick_sources"
	source.label_key = "registry.tick_source.%s" % id
	source.owner_feature = "SHARED-EFFECT-CONDITION-LIFECYCLE-2026-08-31"
	source.kind = "tick_source"
	source.docs_text = "Fixture tick source for the Session 8 suite."
	source.test_fixture = {"fixture": true}
	source.publisher = publisher
	source.lifecycle = lifecycle
	source.scope_of_firing = scope
	return source


func _venom() -> Resource:
	var def := _condition("fixture_venom")
	def.tick_sources = _strings(["fixture_phase", "fixture_pulse"])
	def.stacking = ConditionModel.STACK_ADD_INSTANCE
	def.max_stacks = 2
	def.default_duration = 2
	def.stat_modifiers = _dicts([{"stat": "defense", "delta": -2}])
	def.tags = _strings(["poison"])
	def.tick_composition = "fixture_venom_tick"
	return def


func _drowse() -> Resource:
	var def := _condition("fixture_drowse")
	def.tick_sources = _strings(["fixture_phase"])
	def.stacking = ConditionModel.STACK_REFRESH
	def.default_duration = 2
	def.tags = _strings(["sleep"])
	return def


func _ward() -> Resource:
	var def := _condition("fixture_ward")
	def.default_duration = ConditionModel.INDEFINITE
	def.immunity_tags = _strings(["poison"])
	def.tags = _strings(["ward"])
	return def


func _lingering() -> Resource:
	var def := _condition("fixture_lingering")
	def.default_duration = ConditionModel.INDEFINITE
	def.persists_across_maps = true
	return def


func _tick_composition() -> Resource:
	var entry = RegistryEntryScript.new()
	entry.id = "fixture_venom_tick"
	entry.family = "effect_compositions"
	entry.label_key = "registry.effect.fixture_venom_tick"
	entry.owner_feature = "SHARED-EFFECT-CONDITION-LIFECYCLE-2026-08-31"
	entry.kind = "composition"
	entry.docs_text = "Fixture periodic consequence: two points of damage."
	entry.test_fixture = {"delta": -2}
	entry.composition = _dicts(
		[
			{
				"step_id": "venom_damage",
				"primitive_id": "apply_hp_delta",
				"params": {"delta": -2},
				"target": {"kind": "subject", "key": "target"},
				"required": true,
				"on_failure": "abort",
			}
		]
	)
	return entry


func _definitions() -> Dictionary:
	var defs := {}
	for def in [_venom(), _drowse(), _ward(), _lingering()]:
		defs[String(def.id)] = def
	return defs


# Builds a catalogue holding the engine action primitives plus the fixtures, and
# installs it. Engine primitives are loaded from engine_data rather than
# re-declared, so a composition step here fails if the shipped primitive changes.
func _install_fixture_catalogue(registry: Node) -> void:
	var catalog = RegistryCatalogScript.new()
	for handler_id in RegistryCatalogScript.builtin_primitive_handlers():
		catalog.register_primitive_handler(handler_id)
	var primitives := "res://engine_data/registries/action_primitives"
	for file_name in ["apply_hp_delta.tres", "apply_condition.tres", "fire_tick_source.tres"]:
		catalog.register_entry(ResourceLoader.load(primitives.path_join(file_name)))
	catalog.register_entry(_tick_source("fixture_phase", "engine", "phase_start", "holder"))
	catalog.register_entry(_tick_source("fixture_pulse", "authored", "", "holder"))
	catalog.register_entry(_tick_composition())
	for def in _definitions().values():
		catalog.register_entry(def)
	registry.restore_snapshot({"catalog": catalog, "errors": []})


func _unit(hp: int = 20, defense: int = 5) -> Node:
	var data = UnitDataScript.new()
	data.unit_id = "fixture_condition_unit_%d" % randi()
	data.unit_name = "Fixture"
	data.max_hp = hp
	data.hp = hp
	data.defense = defense
	var unit: Node = UnitScene.instantiate()
	root.add_child(unit)
	unit.initialize(data, Vector2i.ZERO, "blue")
	return unit


# ---- Pure rules ----


func _test_model() -> void:
	var defs := _definitions()

	# A pre-Session-8 entry has no `stacks`. It is completed on read rather than
	# migrated on disk, which is why the save schema does not move.
	var legacy := ConditionModel.normalize([{"type": "fixture_venom", "turns_remaining": 3}])
	_check(
		legacy.size() == 1 and int(legacy[0]["stacks"]) == 1,
		"a condition entry saved before `stacks` existed normalises to one stack"
	)
	_check(
		ConditionModel.normalize([{"turns_remaining": 3}, "junk"]).is_empty(),
		"an entry with no condition id is dropped rather than carried half-formed"
	)

	var venom: Resource = defs.get("fixture_venom")
	var once := ConditionModel.applied([], venom, 2)
	var twice := ConditionModel.applied(once, venom, 2)
	var thrice := ConditionModel.applied(twice, venom, 2)
	_check(
		int(once[0]["stacks"]) == 1 and int(twice[0]["stacks"]) == 2,
		"add_instance stacks a re-application instead of refreshing it"
	)
	_check(int(thrice[0]["stacks"]) == 2, "add_instance honours the authored stack cap")

	var drowse: Resource = defs["fixture_drowse"]
	var drowsed := ConditionModel.applied(
		[{"type": "fixture_drowse", "turns_remaining": 1, "stacks": 1}], drowse, 2
	)
	_check(
		int(drowsed[0]["turns_remaining"]) == 2 and int(drowsed[0]["stacks"]) == 1,
		"refresh_duration resets the clock and never adds a second instance"
	)

	var take_max := _condition("fixture_take_max")
	take_max.stacking = ConditionModel.STACK_TAKE_MAX
	var kept := ConditionModel.applied(
		[{"type": "fixture_take_max", "turns_remaining": 5, "stacks": 1}], take_max, 2
	)
	_check(
		int(kept[0]["turns_remaining"]) == 5,
		"take_max keeps the longer duration when the shorter one is re-applied"
	)

	# Two conditions, one subscribed to both sources and one to a single source.
	var held := ConditionModel.applied(ConditionModel.applied([], venom, 2), drowse, 2)
	var pulsed := ConditionModel.ticked(held, defs, "fixture_pulse")
	_check(
		(
			(pulsed["ticked"] as Array) == ["fixture_venom"]
			and ConditionModel.index_of(pulsed["conditions"], "fixture_drowse") >= 0
			and (
				int(
					((pulsed["conditions"] as Array)[ConditionModel.index_of(
						pulsed["conditions"], "fixture_drowse"
					)])["turns_remaining"]
				)
				== 2
			)
		),
		"a named source ticks only its own subscribers and leaves the others untouched"
	)

	var phase_once := ConditionModel.ticked(held, defs, "fixture_phase")
	var phase_twice := ConditionModel.ticked(phase_once["conditions"], defs, "fixture_phase")
	_check(
		(phase_twice["expired"] as Array).has("fixture_venom"),
		"a duration reaching zero reports the condition as expired"
	)
	_check(
		ConditionModel.index_of(phase_twice["conditions"], "fixture_venom") < 0,
		"an expired condition is gone from the array the tick produced"
	)

	var indefinite := ConditionModel.ticked(
		[{"type": "fixture_ward", "turns_remaining": -1, "stacks": 1}], defs, "fixture_phase"
	)
	_check(
		(indefinite["expired"] as Array).is_empty(),
		"an indefinite condition is never decremented by a tick it is not subscribed to"
	)

	_check(
		(
			ConditionModel.stat_modifiers(twice, defs).size() == 1
			and int(ConditionModel.stat_modifiers(twice, defs)[0]["delta"]) == -4
		),
		"a stat contribution scales with the number of stacks held"
	)

	var mixed := ConditionModel.applied(
		ConditionModel.applied([], venom, 2), defs["fixture_lingering"], -1
	)
	_check(
		(
			ConditionModel.retained_after(mixed, defs, "map_end").size() == 1
			and (
				String(ConditionModel.retained_after(mixed, defs, "map_end")[0]["type"])
				== "fixture_lingering"
			)
		),
		"conditions are map-scoped unless the definition opts into persisting"
	)
	_check(
		ConditionModel.retained_after(mixed, defs, "death").is_empty(),
		"surviving the map is not enough to survive the holder's death"
	)


# ---- The system, through real transactions ----


func _test_system(conditions: Node) -> void:
	var unit := _unit()

	# Prepare writes nothing. This is the clause the whole architecture turns on,
	# so it is asserted before anything else the system does.
	var transaction := EffectTransactionScript.new()
	var report: Dictionary = conditions.prepare_apply(transaction, unit, "fixture_venom")
	_check(
		bool(report.get("ok", false)) and unit.data.conditions.is_empty(),
		"preparing an application leaves the live unit untouched"
	)
	_check(
		conditions.has_condition(unit, "fixture_venom", transaction.sink),
		"the same transaction can already see the condition it prepared"
	)
	_check(
		transaction.save_fields_touched().has("conditions"),
		"the prepared application declares the save field it will write"
	)
	_check(
		unit.get_effective_stat("defense", transaction.sink) == 3,
		"a prepared condition's stat debuff is visible through the transaction before commit"
	)
	_check(
		unit.get_effective_stat("defense") == 5,
		"...and is NOT visible to a live read, because nothing has been written"
	)
	transaction.commit()
	_check(
		unit.data.conditions.size() == 1 and unit.get_effective_stat("defense") == 3,
		"committing lands the condition and its contribution together"
	)

	# Immunity is condition-owned.
	var warded := _unit()
	var ward_txn := EffectTransactionScript.new()
	conditions.prepare_apply(ward_txn, warded, "fixture_ward")
	ward_txn.commit()
	var blocked := EffectTransactionScript.new()
	var refused: Dictionary = conditions.prepare_apply(blocked, warded, "fixture_venom")
	_check(
		not bool(refused.get("ok", false)) and String(refused.get("code", "")) == "immune",
		"a held ward refuses a condition carrying a tag it blocks"
	)

	# One tick is one transaction: damage and expiry commit together or not at all.
	var ticker := _unit()
	var setup := EffectTransactionScript.new()
	conditions.prepare_apply(setup, ticker, "fixture_venom", 1)
	setup.commit()
	var hp_before: int = ticker.data.hp
	var tick := EffectTransactionScript.new()
	var tick_report: Dictionary = conditions.prepare_tick(tick, ticker, "fixture_phase")
	_check(
		(
			bool(tick_report.get("ok", false))
			and (tick_report["expired"] as Array).has("fixture_venom")
			and ticker.data.hp == hp_before
			and not ticker.data.conditions.is_empty()
		),
		"a tick that both damages and expires prepares both and commits neither yet"
	)
	tick.commit()
	_check(
		ticker.data.hp == hp_before - 2 and ticker.data.conditions.is_empty(),
		"committing the tick applies the final damage AND the expiry in one step"
	)

	# A tick with no subscriber prepares nothing at all.
	var idle := _unit()
	var idle_txn := EffectTransactionScript.new()
	var idle_report: Dictionary = conditions.prepare_tick(idle_txn, idle, "fixture_phase")
	_check(
		bool(idle_report.get("ok", false)) and idle_txn.save_fields_touched().is_empty(),
		"firing a source at a unit holding nothing subscribed prepares no write"
	)

	# The authored source, fired at a holder of both conditions.
	var pulsed := _unit()
	var both := EffectTransactionScript.new()
	conditions.prepare_apply(both, pulsed, "fixture_venom", 2)
	conditions.prepare_apply(both, pulsed, "fixture_drowse", 2)
	both.commit()
	var pulse := EffectTransactionScript.new()
	conditions.prepare_tick(pulse, pulsed, "fixture_pulse")
	pulse.commit()
	var after: Array = pulsed.data.conditions
	_check(
		(
			int(after[ConditionModel.index_of(after, "fixture_venom")]["turns_remaining"]) == 1
			and int(after[ConditionModel.index_of(after, "fixture_drowse")]["turns_remaining"]) == 2
		),
		"an authored tick source advances tick A without advancing tick B"
	)

	# Removal, cleanse and the unknown-condition guard.
	var cured := _unit()
	var cure_setup := EffectTransactionScript.new()
	conditions.prepare_apply(cure_setup, cured, "fixture_venom", 2)
	conditions.prepare_apply(cure_setup, cured, "fixture_drowse", 2)
	cure_setup.commit()
	var cure := EffectTransactionScript.new()
	conditions.prepare_clear(cure, cured)
	cure.commit()
	_check(cured.data.conditions.is_empty(), "a cleanse removes every condition in one transaction")

	var noop := EffectTransactionScript.new()
	var noop_report: Dictionary = conditions.prepare_remove(noop, cured, "fixture_venom")
	_check(
		bool(noop_report.get("ok", false)) and not bool(noop_report.get("changed", true)),
		"curing a unit that holds nothing succeeds and changes nothing"
	)

	var unknown := EffectTransactionScript.new()
	var unknown_report: Dictionary = conditions.prepare_apply(unknown, cured, "not_a_condition")
	_check(
		(
			not bool(unknown_report.get("ok", false))
			and String(unknown_report.get("code", "")) == "unknown_condition"
		),
		"applying an unregistered condition id fails loudly instead of writing a ghost entry"
	)

	# Map end honours the authored opt-in.
	var traveller := _unit()
	var pack := EffectTransactionScript.new()
	conditions.prepare_apply(pack, traveller, "fixture_venom", 2)
	conditions.prepare_apply(pack, traveller, "fixture_lingering")
	pack.commit()
	var map_end := EffectTransactionScript.new()
	conditions.prepare_clear(map_end, traveller, conditions.REASON_MAP_END)
	map_end.commit()
	_check(
		(
			traveller.data.conditions.size() == 1
			and String(traveller.data.conditions[0]["type"]) == "fixture_lingering"
		),
		"map end clears the map-scoped condition and keeps the one authored to persist"
	)

	# Save round-trip, including the legacy entry shape.
	var saved := _unit()
	saved.data.conditions = _dicts([{"type": "fixture_venom", "turns_remaining": 3}])
	var snapshot: Dictionary = SaveCodec.unit_data_to_dict(saved.data)
	var restored = UnitDataScript.new()
	SaveCodec.apply_unit_dict(restored, snapshot)
	_check(
		(
			restored.conditions.size() == 1
			and int(restored.conditions[0]["stacks"]) == 1
			and int(restored.conditions[0]["turns_remaining"]) == 3
		),
		"a save written without `stacks` round-trips and gains the default on load"
	)


func _test_registry_contracts(conditions: Node) -> void:
	_check(
		conditions.sources_for_lifecycle("phase_start") == ["fixture_phase"],
		"the engine finds its published sources by lifecycle, never by condition id"
	)
	_check(
		conditions.sources_for_lifecycle("round_start").is_empty(),
		"a lifecycle nothing subscribed to publishes no source"
	)

	var bad := _condition("fixture_invalid")
	bad.stacking = "not_a_rule"
	bad.default_duration = 0
	_check(
		bad.validation_errors().size() == 2,
		"a condition definition rejects an unknown stacking rule and a zero duration"
	)

	var inert := _condition("fixture_inert")
	inert.tick_sources = _strings(["fixture_phase"])
	inert.default_duration = ConditionModel.INDEFINITE
	_check(
		inert.validation_errors().size() == 1,
		"a condition that subscribes to a tick but neither ticks nor expires is refused"
	)

	var undead := _condition("fixture_undead")
	undead.persists_through_death = true
	_check(
		undead.validation_errors().size() == 1,
		"a condition cannot be authored to survive death but not the map"
	)

	var stray := _tick_source("fixture_stray", "authored", "phase_start", "holder")
	_check(
		stray.validation_errors().size() == 1,
		"an authored tick source may not claim an engine lifecycle point"
	)
	var nameless := _tick_source("fixture_nameless", "engine", "", "holder")
	_check(
		nameless.validation_errors().size() == 1,
		"an engine tick source must name the lifecycle that publishes it"
	)
	var unpublished := _tick_source("fixture_unpublished", "engine", "phase_end", "holder")
	_check(
		unpublished.validation_errors().size() == 1,
		"a lifecycle the engine does not publish is refused rather than admitted and never fired"
	)


func _init() -> void:
	print("=== Condition Lifecycle Test ===")
	await process_frame
	var registry := root.get_node_or_null("RegistryManager")
	var conditions := root.get_node_or_null("ConditionManager")
	if registry == null or conditions == null:
		print("FAIL the RegistryManager and ConditionManager autoloads are required")
		print("\nResults: 0 passed, 1 failed")
		quit(1)
		return
	var restore: Dictionary = registry.capture_snapshot()
	_install_fixture_catalogue(registry)

	_test_model()
	_test_system(conditions)
	_test_registry_contracts(conditions)

	registry.restore_snapshot(restore)
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
