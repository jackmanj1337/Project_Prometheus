class_name ContentTreeDescriptor extends RefCounted
# adopter-todo: EDITOR-SHELL-TREE-V1-2026-09-07
# `[CEUI-S21]` and `[CEUI-S30]`: one generated descriptor produces every category in the
# campaign editor's left tree, and every layer in its map canvas.
#
# WHAT THE RULING ACTUALLY FORBIDS. Not "a list in GDScript" -- the engine is GDScript --
# but the EDITOR enumerating content families. `CEUI-2` rejected hand-coded categories
# because adding a content family would then mean editing the editor, which is the
# closed-enum smell `AGENTS.md` bans one level up from where it usually appears. So this
# file contains no list of families. It asks the two registries what exists:
#
#   * `EntitySchemaRegistry` for schema-bearing document kinds (class, map_data, weapon,
#     ...), with `CONTENT_PRESENTATION` declared beside those schemas; and
#   * `RegistryCatalog` for registry families (action_primitives, item_effects, ...), with
#     `FAMILY_PRESENTATION` declared beside `REQUIRED_FAMILIES`.
#
# The ruling explicitly does NOT require merging the two registries, and this does not
# merge them. It requires that whatever the editor reads is declared data both contribute
# to, which is what a descriptor built from both of them is.
#
# WHY A RUNTIME FAMILY STILL GETS A CATEGORY. `RegistryCatalog` admits entries under any
# family, including one no engine constant names -- that is the open registry working as
# designed. A descriptor that showed only declared families would hide authored content
# from the author who wrote it, so an undeclared family gets a category built from its own
# id, sorted last, and flagged `declared: false` so a surface can say so.

const RegistryCatalogScript = preload("res://scripts/registries/RegistryCatalog.gd")
const EntitySchemasScript = preload("res://scripts/data/EntitySchemaRegistry.gd")

## Group ordering for a family nothing declared. Far enough out that every declared group
## sorts ahead of it without the declarations having to know it exists.
const UNDECLARED_GROUP := "other"
const UNDECLARED_GROUP_ORDER := 1000


## The whole tree, in display order.
##
## Both arguments are optional so a caller that only wants the schema side (or is running
## before any pack is active) does not have to build a catalogue it will not read.
static func build(
	schemas: EntitySchemaRegistry = null, catalogue: RegistryCatalog = null
) -> Array[Dictionary]:
	var categories: Array[Dictionary] = []
	categories.append_array(schema_categories(schemas))
	categories.append_array(registry_categories(catalogue))
	categories.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _before(a, b))
	return categories


## Categories from the schema-bearing document kinds. One category per KIND, not per
## (kind, version): a schema version is a document detail, and an author who has both
## versions of a kind in a pack has one place to find them, so the versions ride along on
## the category rather than splitting it.
static func schema_categories(schemas: EntitySchemaRegistry = null) -> Array[Dictionary]:
	var registry: EntitySchemaRegistry = (
		schemas if schemas != null else EntitySchemasScript.with_core_schemas()
	)
	var by_kind: Dictionary = {}
	var order: Array[String] = []
	for registered in registry.registered_kinds():
		var kind := String(registered["kind"])
		if not by_kind.has(kind):
			by_kind[kind] = _category(
				kind, "entity_schema", EntitySchemasScript.CONTENT_PRESENTATION.get(kind, {})
			)
			by_kind[kind]["schema_versions"] = [] as Array[int]
			order.append(kind)
		(by_kind[kind]["schema_versions"] as Array[int]).append(int(registered["version"]))
	var out: Array[Dictionary] = []
	for kind in order:
		out.append(by_kind[kind])
	return out


## Categories from the registry families. The union of what the engine DECLARES and what
## the live catalogue actually HOLDS -- see the header on why the second half matters.
static func registry_categories(catalogue: RegistryCatalog = null) -> Array[Dictionary]:
	var seen: Dictionary = {}
	var families: Array[String] = []
	for family in RegistryCatalogScript.declared_families():
		if not seen.has(family):
			seen[family] = true
			families.append(family)
	if catalogue != null:
		for family in catalogue.populated_families():
			if not seen.has(family):
				seen[family] = true
				families.append(family)
	var out: Array[Dictionary] = []
	for family in families:
		var category := _category(
			family, "registry_catalog", RegistryCatalogScript.FAMILY_PRESENTATION.get(family, {})
		)
		category["required"] = family in RegistryCatalogScript.REQUIRED_FAMILIES
		if catalogue != null:
			category["entry_ids"] = catalogue.ids(family)
		out.append(category)
	return out


## `[CEUI-S30]`, applied one level down: the map canvas's layers, derived from the map
## schema's authored collections. Delegated rather than reimplemented -- the schema is
## where the declaration lives, so the registry is where the derivation belongs.
static func map_layers(schemas: EntitySchemaRegistry = null, version: int = 1) -> Array[Dictionary]:
	var registry: EntitySchemaRegistry = (
		schemas if schemas != null else EntitySchemasScript.with_core_schemas()
	)
	return registry.map_layers(version)


## A category an author would never have written by hand: the id, humanized. It exists so
## an undeclared family is legible rather than absent, not so declarations are optional.
static func fallback_label(id: String) -> String:
	return id.replace("_", " ").capitalize()


static func _category(id: String, source: String, presentation: Dictionary) -> Dictionary:
	var declared := not presentation.is_empty()
	return {
		"id": id,
		"source": source,
		"declared": declared,
		"label": String(presentation.get("label", fallback_label(id))),
		"group": String(presentation.get("group", UNDECLARED_GROUP)),
		"group_order": int(presentation.get("group_order", UNDECLARED_GROUP_ORDER)),
		"order": int(presentation.get("order", 0)),
	}


static func _before(a: Dictionary, b: Dictionary) -> bool:
	if int(a["group_order"]) != int(b["group_order"]):
		return int(a["group_order"]) < int(b["group_order"])
	if String(a["group"]) != String(b["group"]):
		return String(a["group"]) < String(b["group"])
	if int(a["order"]) != int(b["order"]):
		return int(a["order"]) < int(b["order"])
	return String(a["id"]) < String(b["id"])
