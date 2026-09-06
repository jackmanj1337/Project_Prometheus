extends SceneTree
# Headless coverage for the Band 2 registry manifest foundation.

const RegistryCatalogScript = preload("res://scripts/registries/RegistryCatalog.gd")
const RegistryEntryScript = preload("res://scripts/resources/RegistryEntry.gd")

var passed := 0
var failed := 0
var _worker_mode := false
var _worker_marker := ""
var _worker_role := ""


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var worker_index := args.find("--registry-concurrency-worker")
	if worker_index >= 0 and worker_index + 2 < args.size():
		_worker_mode = true
		_worker_marker = String(args[worker_index + 1])
		_worker_role = String(args[worker_index + 2])
		call_deferred("_run_concurrency_worker")
		return
	print("=== RegistryManager Test ===")

	var catalog = RegistryCatalogScript.new()
	catalog.register_primitive_handler("test_handler")

	var first = _entry("alpha", "test_handler")
	var duplicate = _entry("alpha", "test_handler")
	if (
		catalog.register_entry(first).is_empty()
		and not catalog.register_entry(duplicate).is_empty()
		and catalog.entry("test_family", "alpha") == first
	):
		print("OK  duplicate ids fail without replacing the first entry")
		passed += 1
	else:
		print("FAIL duplicate id handling")
		failed += 1

	var unknown = _entry("unknown", "missing_handler")
	var unknown_errors: Array[String] = catalog.register_entry(unknown)
	if unknown_errors.any(
		func(error): return "unknown primitive handler 'missing_handler'" in error
	):
		print("OK  unknown primitive handlers fail validation")
		passed += 1
	else:
		print("FAIL unknown handler errors: %s" % [unknown_errors])
		failed += 1

	var malformed = _entry("malformed", "test_handler")
	malformed.params_schema = {"amount": {"default": 1}}
	var schema_errors: Array[String] = catalog.register_entry(malformed)
	if schema_errors.any(func(error): return "needs a schema dictionary with type" in error):
		print("OK  malformed parameter schemas fail validation")
		passed += 1
	else:
		print("FAIL malformed schema errors: %s" % [schema_errors])
		failed += 1

	var undocumented_mutation = _entry("undocumented_mutation", "test_handler")
	undocumented_mutation.kind = "mutation"
	var mutation_errors: Array[String] = catalog.register_entry(undocumented_mutation)
	if mutation_errors.any(func(error): return "must declare save_fields" in error):
		print("OK  mutating primitives must declare their save fields")
		passed += 1
	else:
		print("FAIL missing mutation save-field guard: %s" % [mutation_errors])
		failed += 1

	var later = _entry("zeta", "test_handler")
	later.priority = 0
	var sooner = _entry("beta", "test_handler")
	sooner.priority = -1
	catalog.register_entry(later)
	catalog.register_entry(sooner)
	if catalog.ids("test_family") == ["beta", "alpha", "zeta"]:
		print("OK  ids sort by priority then stable id")
		passed += 1
	else:
		print("FAIL deterministic ids: %s" % [catalog.ids("test_family")])
		failed += 1

	# A new data record using an already-approved primitive requires no catalog
	# code edit: this is the core author-extensibility property.
	var data_defined = _entry("campaign_entry", "test_handler")
	if (
		catalog.register_entry(data_defined).is_empty()
		and catalog.has_entry("test_family", "campaign_entry")
	):
		print("OK  a data-defined entry loads without an engine switch edit")
		passed += 1
	else:
		print("FAIL data-defined entry registration")
		failed += 1

	var manager: Node = load("res://scripts/autoloads/RegistryManager.gd").new()
	manager.name = "RegistryManager"
	root.add_child(manager)
	await process_frame
	if (
		manager.load_errors().is_empty()
		and manager.has_entry("action_primitives", "apply_active_modifier")
		and manager.has_entry("resource_types", "party_gold")
		and manager.has_entry("resource_types", "unit_gold")
		and manager.has_entry("occupancy_policies", "nearest_free")
		and manager.has_entry("objective_conditions", "rout")
		and manager.has_entry("item_effects", "heal_flat")
	):
		print("OK  export-safe preset manifests load all required registry families")
		passed += 1
	else:
		print("FAIL preset loading: %s" % [manager.load_errors()])
		failed += 1

	var alternate_source := "user://test_registry_manager/alternate_source"
	var alternate_written := _write_registry_source(alternate_source)
	var alternate_errors: Array[String] = manager.reload_presets(alternate_source)
	if (
		alternate_written
		and alternate_errors.is_empty()
		and manager.has_entry("action_primitives", "fixture_action")
		and manager.has_entry("resource_types", "fixture_resource")
		and manager.has_entry("occupancy_policies", "fixture_occupancy")
		and not manager.has_entry("resource_types", "party_gold")
	):
		print("OK  reload strictly replaces presets from the selected content source")
		passed += 1
	else:
		print(
			(
				"FAIL alternate registry source: written=%s errors=%s"
				% [alternate_written, alternate_errors]
			)
		)
		failed += 1

	var partial_source := "user://test_registry_manager/partial_source"
	var partial_written := _write_registry_family(
		partial_source, "action_primitives", "partial_action", "apply_active_modifier"
	)
	var partial_errors: Array[String] = manager.reload_presets(partial_source)
	var reports_resource: bool = partial_errors.any(
		func(error): return "required family 'resource_types'" in error
	)
	var reports_occupancy: bool = partial_errors.any(
		func(error): return "required family 'occupancy_policies'" in error
	)
	if (
		partial_written
		and manager.has_entry("action_primitives", "partial_action")
		and manager.ids("resource_types").is_empty()
		and manager.ids("occupancy_policies").is_empty()
		and reports_resource
		and reports_occupancy
	):
		print("OK  omitted registry families stay empty and report loud errors")
		passed += 1
	else:
		print("FAIL strict missing-family handling: %s" % [partial_errors])
		failed += 1
	manager.reload_presets()

	# A missing registry snapshot must never turn the live catalogue into null. This
	# is the exact shape of the resume default: ContentSession.registry_snapshot is an
	# empty dictionary when a session was captured before the registry committed.
	var diagnostics := root.get_node_or_null("DiagnosticsLog")
	if diagnostics != null:
		diagnostics.print_records = false
		diagnostics.reset()
	manager.activate_engine_baseline()
	var before_snapshot: Dictionary = manager.capture_snapshot()
	var rejected_restore: Variant = manager.call("restore_snapshot", {})
	var restore_record := _last_diagnostic(diagnostics, "registry_snapshot_restore")
	if (
		rejected_restore is bool
		and not rejected_restore
		and manager.has_entry("action_primitives", "apply_hp_delta")
		and manager.load_errors().any(
			func(error): return "snapshot has no catalogue" in String(error)
		)
		and not restore_record.is_empty()
		and "outcome=refused" in String(restore_record.get("fields", ""))
	):
		print("OK  empty registry snapshots are refused without clearing the live catalogue")
		passed += 1
	else:
		print(
			(
				"FAIL empty snapshot guard: result=%s has_apply_hp_delta=%s errors=%s record=%s"
				% [
					rejected_restore,
					manager.has_entry("action_primitives", "apply_hp_delta"),
					manager.load_errors(),
					restore_record,
				]
			)
		)
		failed += 1
	manager.restore_snapshot(before_snapshot)

	var commit_record := _last_diagnostic(diagnostics, "registry_commit")
	manager.deactivate()
	var deactivate_record := _last_diagnostic(diagnostics, "registry_deactivate")
	if not commit_record.is_empty() and not deactivate_record.is_empty():
		print("OK  registry commits and deactivations are recorded")
		passed += 1
	else:
		print(
			(
				"FAIL registry lifecycle diagnostics: commit=%s deactivate=%s"
				% [commit_record, deactivate_record]
			)
		)
		failed += 1
	manager.activate_engine_baseline()

	await _test_concurrent_instances()

	manager.queue_free()
	await process_frame
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _run_concurrency_worker() -> void:
	await process_frame
	var manager: Node = root.get_node_or_null("RegistryManager")
	var ok := manager != null and bool(manager.call("activate_engine_baseline"))
	_write_marker("ready-%s" % _worker_role, {"pid": OS.get_process_id(), "ok": ok})
	await _wait_for_marker("go")
	if _worker_role == "mutator":
		var data_manager := root.get_node_or_null("DataManager")
		for _i in 4:
			if data_manager != null:
				data_manager.call("activate_project_data_compatibility", "res://data")
				data_manager.call("deactivate_campaign_package")
			ok = ok and bool(manager.call("activate_engine_baseline"))
	else:
		for _i in 16:
			ok = ok and manager.has_entry("action_primitives", "apply_hp_delta")
			await process_frame
	_write_marker("done-%s" % _worker_role, {"pid": OS.get_process_id(), "ok": ok})
	quit(0 if ok else 1)


func _test_concurrent_instances() -> void:
	var marker := "user://test_registry_manager/concurrent_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(marker))
	var common_args := PackedStringArray(
		[
			"--headless",
			"--path",
			ProjectSettings.globalize_path("res://"),
			"--script",
			"res://scripts/tests/test_registry_manager.gd",
			"--",
			"--registry-concurrency-worker",
			ProjectSettings.globalize_path(marker),
		]
	)
	var observer_args := common_args.duplicate()
	observer_args.append("observer")
	var mutator_args := common_args.duplicate()
	mutator_args.append("mutator")
	var observer_pid := OS.create_process(OS.get_executable_path(), observer_args)
	var mutator_pid := OS.create_process(OS.get_executable_path(), mutator_args)
	var launched := observer_pid > 0 and mutator_pid > 0
	var ready := await _wait_for_markers(marker, ["ready-observer", "ready-mutator"], 240)
	# Always release a launched child, even when its peer failed to start; otherwise
	# a failed process launch leaves a headless Godot worker behind indefinitely.
	_write_marker_at(marker, "go", {})
	var finished := await _wait_for_markers(marker, ["done-observer", "done-mutator"], 360)
	var observer_result := _read_marker(marker, "done-observer")
	var mutator_result := _read_marker(marker, "done-mutator")
	var ok := (
		launched
		and ready
		and finished
		and bool(observer_result.get("ok", false))
		and bool(mutator_result.get("ok", false))
	)
	if ok:
		print("OK  concurrent instances preserve the action primitive catalogue")
		passed += 1
	else:
		print(
			(
				"FAIL concurrent registry probe: launched=%s ready=%s finished=%s observer=%s mutator=%s"
				% [launched, ready, finished, observer_result, mutator_result]
			)
		)
		failed += 1
	for name in ["ready-observer", "ready-mutator", "done-observer", "done-mutator", "go"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(marker.path_join(name)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(marker))


func _wait_for_markers(marker: String, names: Array, frames: int) -> bool:
	for _i in frames:
		var all_present := true
		for name in names:
			if not FileAccess.file_exists(marker.path_join(String(name))):
				all_present = false
		if all_present:
			return true
		await process_frame
	return false


func _wait_for_marker(name: String) -> void:
	while not FileAccess.file_exists(_worker_marker.path_join(name)):
		await process_frame


func _write_marker(name: String, payload: Dictionary) -> void:
	_write_marker_at(_worker_marker, name, payload)


func _write_marker_at(marker: String, name: String, payload: Dictionary) -> void:
	var file := FileAccess.open(marker.path_join(name), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(payload))
		file.close()


func _read_marker(marker: String, name: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(marker.path_join(name)))
	return value if value is Dictionary else {}


func _last_diagnostic(diagnostics: Node, event: String) -> Dictionary:
	if diagnostics == null:
		return {}
	for index in range(diagnostics.records.size() - 1, -1, -1):
		var record: Dictionary = diagnostics.records[index]
		if String(record.get("event", "")) == event:
			return record
	return {}


func _entry(id: String, handler: String):
	var result = RegistryEntryScript.new()
	result.id = id
	result.family = "test_family"
	result.label_key = "registry.test.%s" % id
	result.owner_feature = "TEST"
	result.kind = "test"
	result.primitive_handler = handler
	result.params_schema = {"value": {"type": "int", "default": 0}}
	result.docs_text = "Test registry entry."
	result.test_fixture = {"value": 1}
	return result


func _write_registry_source(source: String) -> bool:
	return (
		_write_registry_family(
			source, "action_primitives", "fixture_action", "apply_active_modifier"
		)
		and _write_registry_family(
			source, "resource_types", "fixture_resource", "party_gold_wallet"
		)
		and _write_registry_family(
			source, "occupancy_policies", "fixture_occupancy", "require_empty_placement"
		)
		and _write_registry_family(source, "objective_conditions", "fixture_objective", "rout")
		and _write_registry_family(source, "item_effects", "fixture_item", "heal_flat")
		and _write_registry_family(
			source, "campaign_vars", "fixture_variable", "campaign_var_value"
		)
	)


func _write_registry_family(source: String, family: String, id: String, handler: String) -> bool:
	var directory := source.path_join("registries").path_join(family)
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) != OK:
		return false
	var entry = _entry(id, handler)
	entry.family = family
	return ResourceSaver.save(entry, directory.path_join("%s.tres" % id)) == OK
