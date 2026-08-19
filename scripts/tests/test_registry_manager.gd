extends SceneTree
# Headless coverage for the Band 2 registry manifest foundation.

const RegistryCatalogScript = preload("res://scripts/registries/RegistryCatalog.gd")
const RegistryEntryScript = preload("res://scripts/resources/RegistryEntry.gd")


func _init() -> void:
	print("=== RegistryManager Test ===")
	var passed := 0
	var failed := 0

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

	manager.queue_free()
	await process_frame
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


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
