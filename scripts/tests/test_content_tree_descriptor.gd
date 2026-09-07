extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_content_tree_descriptor.gd
#
# Covers `[CEUI-S21]` (one generated descriptor produces every tree category) and
# `[CEUI-S30]` (map layers are derived from the map schema, not listed in the editor).
#
# The two assertions that carry the ruling, and that nothing else can catch:
#
#   * THE DECLARATION TABLES MATCH THEIR REGISTRIES EXACTLY, IN BOTH DIRECTIONS. A
#     registered kind with no presentation row vanishes from the author's tree; a
#     presentation row with no registered kind puts an empty category in front of them.
#     Neither is visible by reading either file, and both are one line away at all times.
#   * A FAMILY THE ENGINE NEVER HEARD OF STILL GETS A CATEGORY. `RegistryCatalog` admits
#     entries under any family -- that is the open registry the ruling exists to protect
#     -- so a descriptor that showed only declared families would hide authored content
#     from the author who wrote it.
#
# The layer assertions are written as ABSENCES on purpose. `TER-1..10`'s map objects, and
# regions and annotations, are named in `CEUI-23` option A and do not exist in the schema;
# a hardcoded seven-layer list would have shipped them as empty layers, so the test that
# proves the list is derived is the one that says they are not there yet.

const DescriptorScript = preload("res://scripts/editor/ContentTreeDescriptor.gd")
const EntitySchemasScript = preload("res://scripts/data/EntitySchemaRegistry.gd")
const RegistryCatalogScript = preload("res://scripts/registries/RegistryCatalog.gd")
const RegistryEntryScript = preload("res://scripts/resources/RegistryEntry.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Content Tree Descriptor Test ===")

	_presentation_covers_every_registered_kind()
	_family_presentation_covers_every_declared_family()
	_the_tree_is_generated_from_both_registries()
	_display_order_is_group_then_order_then_id()
	_an_undeclared_family_still_gets_a_category()
	_a_populated_family_carries_its_entry_ids()
	_layers_come_from_the_map_schema()
	_unmodelled_layers_are_absent()

	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % label)
	else:
		_failed += 1
		print("  FAIL: %s%s" % [label, ("  -- %s" % detail) if detail != "" else ""])


func _presentation_covers_every_registered_kind() -> void:
	print("\n-- schema presentation matches the schemas --")
	var schemas = EntitySchemasScript.with_core_schemas()
	var registered: Dictionary = {}
	for entry in schemas.registered_kinds():
		registered[String(entry["kind"])] = true
	var declared: Dictionary = {}
	for kind in EntitySchemasScript.CONTENT_PRESENTATION.keys():
		declared[String(kind)] = true

	var undeclared: Array[String] = []
	for kind in registered.keys():
		if not declared.has(kind):
			undeclared.append(String(kind))
	undeclared.sort()
	_check("every registered kind has a presentation row", undeclared.is_empty(), str(undeclared))

	var orphaned: Array[String] = []
	for kind in declared.keys():
		if not registered.has(kind):
			orphaned.append(String(kind))
	orphaned.sort()
	_check("no presentation row without a schema", orphaned.is_empty(), str(orphaned))
	_check("and there are some", registered.size() >= 16, str(registered.size()))


func _family_presentation_covers_every_declared_family() -> void:
	print("\n-- family presentation matches the registry constants --")
	var declared := RegistryCatalogScript.declared_families()
	var presented: Array[String] = []
	for family in RegistryCatalogScript.FAMILY_PRESENTATION.keys():
		presented.append(String(family))
	presented.sort()
	_check(
		"presentation keys are exactly REQUIRED + OPTIONAL",
		presented == declared,
		"%s vs %s" % [str(presented), str(declared)]
	)


func _the_tree_is_generated_from_both_registries() -> void:
	print("\n-- both registries contribute --")
	var tree := DescriptorScript.build()
	var sources: Dictionary = {}
	var ids: Dictionary = {}
	for category in tree:
		sources[String(category["source"])] = true
		ids[String(category["id"])] = true
	_check("schema kinds are present", ids.has("class") and ids.has("map_data"))
	_check("registry families are present", ids.has("item_effects") and ids.has("conditions"))
	_check("both sources are represented", sources.size() == 2, str(sources.keys()))
	_check(
		"every category carries an author-facing label",
		tree.all(func(category: Dictionary) -> bool: return String(category["label"]) != "")
	)
	var class_category: Dictionary = {}
	for category in tree:
		if String(category["id"]) == "class":
			class_category = category
	_check("a schema category names its versions", class_category.get("schema_versions", []) == [1])
	_check("and is marked declared", bool(class_category.get("declared", false)))


func _display_order_is_group_then_order_then_id() -> void:
	print("\n-- display order --")
	var tree := DescriptorScript.build()
	var ordered := true
	for index in range(1, tree.size()):
		var previous: Dictionary = tree[index - 1]
		var current: Dictionary = tree[index]
		if int(previous["group_order"]) > int(current["group_order"]):
			ordered = false
		elif int(previous["group_order"]) == int(current["group_order"]):
			if String(previous["group"]) == String(current["group"]):
				if int(previous["order"]) > int(current["order"]):
					ordered = false
	_check("categories come back grouped and ordered", ordered)
	_check("campaigns lead the tree", String(tree[0]["id"]) == "campaign", str(tree[0]))


func _an_undeclared_family_still_gets_a_category() -> void:
	print("\n-- an undeclared family --")
	var catalogue = RegistryCatalogScript.new()
	catalogue.register_primitive_handler("set_state_value")
	var entry = RegistryEntryScript.new()
	entry.id = "weather_front"
	entry.family = "weather_systems"
	entry.label_key = "weather.front"
	entry.owner_feature = "weather"
	entry.version = 1
	entry.kind = "query"
	entry.primitive_handler = "set_state_value"
	entry.docs_text = "A family no engine constant names."
	entry.test_fixture = {"probe": true}
	var errors: Array[String] = catalogue.register_entry(entry)
	_check("the catalogue admits it", errors.is_empty(), str(errors))

	var tree := DescriptorScript.build(null, catalogue)
	var found: Dictionary = {}
	for category in tree:
		if String(category["id"]) == "weather_systems":
			found = category
	_check("it reaches the tree", not found.is_empty())
	if found.is_empty():
		return
	_check("flagged as undeclared", not bool(found["declared"]))
	_check("with a humanized label", String(found["label"]) == "Weather Systems", found["label"])
	_check(
		"sorted after every declared group",
		int(found["group_order"]) == DescriptorScript.UNDECLARED_GROUP_ORDER
	)
	_check("and it is last", String(tree[tree.size() - 1]["id"]) == "weather_systems")


func _a_populated_family_carries_its_entry_ids() -> void:
	print("\n-- entry ids ride on the category --")
	var catalogue = RegistryCatalogScript.new()
	catalogue.register_primitive_handler("set_state_value")
	for id in ["alpha", "beta"]:
		var entry = RegistryEntryScript.new()
		entry.id = id
		entry.family = "resource_types"
		entry.label_key = "resource.%s" % id
		entry.owner_feature = "economy"
		entry.version = 1
		entry.kind = "query"
		entry.primitive_handler = "set_state_value"
		entry.docs_text = "probe"
		entry.test_fixture = {"probe": true}
		catalogue.register_entry(entry)
	var tree := DescriptorScript.build(null, catalogue)
	for category in tree:
		if String(category["id"]) == "resource_types":
			_check("ids are listed", category.get("entry_ids", []) == ["alpha", "beta"])
			_check("and the family is marked required", bool(category["required"]))


func _layers_come_from_the_map_schema() -> void:
	print("\n-- [CEUI-S30]: layers are derived --")
	var layers := DescriptorScript.map_layers()
	var ids: Array[String] = []
	for layer in layers:
		ids.append(String(layer["id"]))
	_check(
		"the four modelled collections are layers",
		ids == ["terrain", "deployment", "units", "objectives"],
		str(ids)
	)
	for layer in layers:
		if String(layer["id"]) == "objectives":
			_check(
				"two properties can share one layer",
				layer["properties"] == ["defeat_conditions", "victory_conditions"],
				str(layer["properties"])
			)
		if String(layer["id"]) == "terrain":
			_check("terrain is the grid", layer["properties"] == ["grid"])


func _unmodelled_layers_are_absent() -> void:
	print("\n-- and only the derived ones --")
	var ids: Array[String] = []
	for layer in DescriptorScript.map_layers():
		ids.append(String(layer["id"]))
	# CEUI-23 option A named seven. These three have no schema collection, so a derived
	# list must not produce them -- that absence is the proof the list is not hardcoded.
	for absent in ["map_objects", "regions", "annotations"]:
		_check("'%s' is not a layer until it is authored" % absent, not (absent in ids))
