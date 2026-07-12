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
	if catalog.register_entry(first).is_empty() \
			and not catalog.register_entry(duplicate).is_empty() \
			and catalog.entry("test_family", "alpha") == first:
		print("OK  duplicate ids fail without replacing the first entry"); passed += 1
	else:
		print("FAIL duplicate id handling"); failed += 1

	var unknown = _entry("unknown", "missing_handler")
	var unknown_errors: Array[String] = catalog.register_entry(unknown)
	if unknown_errors.any(func(error): return "unknown primitive handler 'missing_handler'" in error):
		print("OK  unknown primitive handlers fail validation"); passed += 1
	else:
		print("FAIL unknown handler errors: %s" % [unknown_errors]); failed += 1

	var malformed = _entry("malformed", "test_handler")
	malformed.params_schema = {"amount": {"default": 1}}
	var schema_errors: Array[String] = catalog.register_entry(malformed)
	if schema_errors.any(func(error): return "needs a schema dictionary with type" in error):
		print("OK  malformed parameter schemas fail validation"); passed += 1
	else:
		print("FAIL malformed schema errors: %s" % [schema_errors]); failed += 1

	var later = _entry("zeta", "test_handler")
	later.priority = 0
	var sooner = _entry("beta", "test_handler")
	sooner.priority = -1
	catalog.register_entry(later)
	catalog.register_entry(sooner)
	if catalog.ids("test_family") == ["beta", "alpha", "zeta"]:
		print("OK  ids sort by priority then stable id"); passed += 1
	else:
		print("FAIL deterministic ids: %s" % [catalog.ids("test_family")]); failed += 1

	# A new data record using an already-approved primitive requires no catalog
	# code edit: this is the core author-extensibility property.
	var data_defined = _entry("campaign_entry", "test_handler")
	if catalog.register_entry(data_defined).is_empty() \
			and catalog.has_entry("test_family", "campaign_entry"):
		print("OK  a data-defined entry loads without an engine switch edit"); passed += 1
	else:
		print("FAIL data-defined entry registration"); failed += 1

	var manager: Node = load("res://scripts/autoloads/RegistryManager.gd").new()
	manager.name = "RegistryManager"
	root.add_child(manager)
	await process_frame
	if manager.load_errors().is_empty() \
			and manager.has_entry("action_primitives", "apply_active_modifier") \
			and manager.has_entry("resource_types", "party_gold") \
			and manager.has_entry("occupancy_policies", "nearest_free"):
		print("OK  export-safe preset manifests load all three starter families"); passed += 1
	else:
		print("FAIL preset loading: %s" % [manager.load_errors()]); failed += 1

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
