class_name RegistryCatalog extends RefCounted

const RegistryEntryScript = preload("res://scripts/resources/RegistryEntry.gd")

const BUILTIN_PRIMITIVE_HANDLERS: Array[String] = [
	"apply_active_modifier",
	"set_state_value",
	"party_gold_wallet",
	"unit_gold_wallet",
	"require_empty_placement",
	"nearest_free_placement",
	"delay_placement",
	"skip_placement",
	"unimplemented_placement",
	"rout",
	"defeat_boss",
	"seize",
	"escape",
	"survive",
	"protect",
	"turn_limit",
	"heal_flat",
	"heal_full",
	"promote",
	"reclass",
	"stat_buff",
	"campaign_var_value",
	"apply_hp_delta",
	"apply_condition",
	"remove_condition",
	"fire_tick_source",
	"reveal_fog_units",
]
const REQUIRED_FAMILIES: Array[String] = [
	"action_primitives",
	"resource_types",
	"occupancy_policies",
	"objective_conditions",
	"item_effects",
	"campaign_vars"
]
const OPTIONAL_FAMILIES: Array[String] = ["effect_compositions", "conditions", "tick_sources"]

# Families whose entries are DECLARATIONS rather than callable primitives. They
# carry no primitive_handler because there is no per-entry runtime handler to
# name: a condition is data the engine-owned condition primitives read, and a
# tick source is an occasion, not an action. Requiring a handler here would have
# forced every authored condition to name a placeholder id, which is how a
# vocabulary starts meaning nothing.
const HANDLERLESS_FAMILIES: Array[String] = ["effect_compositions", "conditions", "tick_sources"]

# `[CEUI-S21]`: the author-facing presentation of every registry family this catalogue
# admits, so the campaign editor's tree is GENERATED from declared data instead of a list
# the editor keeps. `[CSA-17(a)]` already refused "three lists that drift" for the asset
# side; a hand-ordered category list in the editor would be the same smell one level up.
#
# `test_content_tree_descriptor.gd` asserts these keys are exactly
# REQUIRED_FAMILIES + OPTIONAL_FAMILIES. That is the whole enforcement: the two lists
# above decide what the engine ADMITS and this one decides what an author SEES, and a
# family in one but not the other is either an invisible family or an empty category.
#
# A family that appears only at runtime -- a pack registering entries under a family no
# engine constant names -- is still admitted, and the descriptor gives it a category from
# its own id. Failing to show authored content because the engine never heard of it would
# defeat the open registry the ruling is protecting.
const FAMILY_PRESENTATION := {
	"action_primitives": {"group": "rules", "group_order": 60, "order": 20, "label": "Actions"},
	"resource_types": {"group": "rules", "group_order": 60, "order": 30, "label": "Resources"},
	"occupancy_policies": {"group": "rules", "group_order": 60, "order": 40, "label": "Occupancy"},
	"objective_conditions":
	{"group": "rules", "group_order": 60, "order": 50, "label": "Objective conditions"},
	"item_effects": {"group": "rules", "group_order": 60, "order": 60, "label": "Item effects"},
	"campaign_vars": {"group": "rules", "group_order": 60, "order": 70, "label": "Campaign vars"},
	"effect_compositions":
	{"group": "rules", "group_order": 60, "order": 80, "label": "Effect compositions"},
	"conditions": {"group": "rules", "group_order": 60, "order": 90, "label": "Conditions"},
	"tick_sources": {"group": "rules", "group_order": 60, "order": 100, "label": "Tick sources"},
}


## Every family named by an engine constant, sorted. The descriptor unions this with the
## families that actually carry entries, so a pack-declared family is never dropped.
static func declared_families() -> Array[String]:
	var out: Array[String] = []
	for family in REQUIRED_FAMILIES:
		out.append(family)
	for family in OPTIONAL_FAMILIES:
		out.append(family)
	out.sort()
	return out


static func builtin_primitive_handlers() -> Array[String]:
	return BUILTIN_PRIMITIVE_HANDLERS.duplicate()


var _entries: Dictionary = {}
var _primitive_handlers: Dictionary = {}


func register_primitive_handler(handler_id: String) -> Array[String]:
	if handler_id.strip_edges() == "":
		return ["RegistryCatalog: primitive handler id is empty"]
	_primitive_handlers[handler_id] = true
	return []


func register_entry(entry: Resource) -> Array[String]:
	var errors := validate_entry(entry)
	if not errors.is_empty():
		return errors
	var family_entries: Dictionary = _entries.get(entry.family, {})
	if family_entries.has(entry.id):
		return ["RegistryCatalog: duplicate id '%s' in family '%s'" % [entry.id, entry.family]]
	family_entries[entry.id] = entry
	_entries[entry.family] = family_entries
	return []


# `[CEUI-S27]` form of `validate_entry`. The flat array stays the primary implementation
# because forty-odd call sites read it; this puts the same findings behind
# `ValidationRules.RULE_REGISTRY_ENTRY` with the entry as the issue subject, which is what
# lets the editor's issues panel navigate to the offending registry entry instead of
# printing a string with an id embedded in it.
func validate_entry_report(entry: Resource, report: ValidationReport = null) -> ValidationReport:
	var target := report if report != null else ValidationReport.create()
	var subject: Dictionary = {}
	if entry != null:
		subject = {"kind": "registry_entry", "id": entry.id, "family": entry.family}
	target.adopt_errors(ValidationRules.RULE_REGISTRY_ENTRY, validate_entry(entry), subject)
	return target


func validate_entry(entry: Resource) -> Array[String]:
	var errors: Array[String] = []
	if entry == null:
		return ["RegistryCatalog: entry is null"]
	if entry.id.strip_edges() == "":
		errors.append("RegistryCatalog: entry is missing id")
	if entry.family.strip_edges() == "":
		errors.append("RegistryCatalog: entry '%s' is missing family" % entry.id)
	if entry.label_key.strip_edges() == "":
		errors.append("RegistryCatalog: entry '%s' is missing label_key" % entry.id)
	if entry.owner_feature.strip_edges() == "":
		errors.append("RegistryCatalog: entry '%s' is missing owner_feature" % entry.id)
	if entry.version < 1:
		errors.append("RegistryCatalog: entry '%s' version must be >= 1" % entry.id)
	if entry.kind.strip_edges() == "":
		errors.append("RegistryCatalog: entry '%s' is missing kind" % entry.id)
	if entry.family == "effect_compositions":
		return _validate_effect_composition(entry, errors)
	if entry.family in HANDLERLESS_FAMILIES:
		return _validate_declaration(entry, errors)
	if entry.primitive_handler.strip_edges() == "":
		errors.append("RegistryCatalog: entry '%s' is missing primitive_handler" % entry.id)
	elif not _primitive_handlers.has(entry.primitive_handler):
		errors.append(
			(
				"RegistryCatalog: entry '%s' references unknown primitive handler '%s'"
				% [entry.id, entry.primitive_handler]
			)
		)
	for param_id in entry.params_schema.keys():
		var spec: Variant = entry.params_schema[param_id]
		if not (spec is Dictionary) or String(spec.get("type", "")) == "":
			errors.append(
				(
					"RegistryCatalog: entry '%s' parameter '%s' needs a schema dictionary with type"
					% [entry.id, String(param_id)]
				)
			)
	if entry.kind == "mutation" and entry.save_fields.is_empty():
		errors.append("RegistryCatalog: mutating entry '%s' must declare save_fields" % entry.id)
	for part in entry.composition:
		var handler_id := String(part.get("primitive_handler", ""))
		if handler_id == "" or not _primitive_handlers.has(handler_id):
			(
				errors
				. append(
					(
						"RegistryCatalog: entry '%s' composition references unknown primitive handler '%s'"
						% [entry.id, handler_id]
					)
				)
			)
	if entry.docs_text.strip_edges() == "":
		errors.append("RegistryCatalog: entry '%s' is missing docs_text" % entry.id)
	if entry.test_fixture.is_empty():
		errors.append("RegistryCatalog: entry '%s' is missing test_fixture" % entry.id)
	if entry.has_method("validation_errors"):
		errors.append_array(entry.validation_errors())
	return errors


# Declarations still owe documentation and a fixture — the two things that make
# an authored id reviewable — plus whatever their own type checks.
func _validate_declaration(entry: Resource, errors: Array[String]) -> Array[String]:
	if entry.docs_text.strip_edges() == "":
		errors.append("RegistryCatalog: entry '%s' is missing docs_text" % entry.id)
	if entry.test_fixture.is_empty():
		errors.append("RegistryCatalog: entry '%s' is missing test_fixture" % entry.id)
	if entry.has_method("validation_errors"):
		errors.append_array(entry.validation_errors())
	return errors


func _validate_effect_composition(entry: Resource, errors: Array[String]) -> Array[String]:
	var step_ids: Dictionary = {}
	for index in entry.composition.size():
		var step: Dictionary = entry.composition[index]
		var path := "composition[%d]" % index
		var step_id := String(step.get("step_id", ""))
		if step_id == "":
			errors.append("RegistryCatalog: entry '%s' %s is missing step_id" % [entry.id, path])
		elif step_ids.has(step_id):
			errors.append(
				"RegistryCatalog: entry '%s' has duplicate step_id '%s'" % [entry.id, step_id]
			)
		step_ids[step_id] = true
		if String(step.get("primitive_id", "")) == "":
			errors.append(
				"RegistryCatalog: entry '%s' %s is missing primitive_id" % [entry.id, path]
			)
		if not step.has("target") or not step.target is Dictionary:
			errors.append("RegistryCatalog: entry '%s' %s needs a target" % [entry.id, path])
		var required := bool(step.get("required", true))
		var policy := String(step.get("on_failure", "abort"))
		if policy not in ["abort", "skip", "halt"] or (required and policy != "abort"):
			errors.append(
				"RegistryCatalog: entry '%s' %s has invalid failure policy" % [entry.id, path]
			)
	if entry.docs_text.strip_edges() == "":
		errors.append("RegistryCatalog: entry '%s' is missing docs_text" % entry.id)
	if entry.test_fixture.is_empty():
		errors.append("RegistryCatalog: entry '%s' is missing test_fixture" % entry.id)
	return errors


## Families that currently hold at least one entry, including families no engine constant
## names. `ids()` already answers per family; this answers which families exist at all.
func populated_families() -> Array[String]:
	var out: Array[String] = []
	for family in _entries.keys():
		out.append(String(family))
	out.sort()
	return out


func has_entry(family: String, id: String) -> bool:
	return _entries.has(family) and (_entries[family] as Dictionary).has(id)


func entry(family: String, id: String) -> Resource:
	if not has_entry(family, id):
		return null
	return (_entries[family] as Dictionary)[id]


func ids(family: String) -> Array[String]:
	var sorted_entries: Array[Resource] = []
	if _entries.has(family):
		for registry_entry in (_entries[family] as Dictionary).values():
			sorted_entries.append(registry_entry)
	sorted_entries.sort_custom(
		func(a: Resource, b: Resource) -> bool:
			if a.priority != b.priority:
				return a.priority < b.priority
			return a.id < b.id
	)
	var result: Array[String] = []
	for registry_entry in sorted_entries:
		result.append(registry_entry.id)
	return result


## The committed catalogue's resources are the baseline for pack composition.
## Return them in the same deterministic family/id order as `ids()` so a layered
## candidate is reproducible and does not depend on dictionary insertion order.
func all_entries() -> Array[Resource]:
	var result: Array[Resource] = []
	var families := populated_families()
	for family in families:
		for id in ids(family):
			result.append(entry(family, id))
	return result
