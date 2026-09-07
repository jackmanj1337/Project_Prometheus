class_name EditorBulkTable extends RefCounted
# `[CEUI-S23]`'s bulk table: the ONLY multi-edit surface in the editor, over a selection of
# records in one open document.
#
# THE INSPECTOR ALWAYS EDITS EXACTLY ONE RECORD. That is the ruling, and this class is its
# other half: any multi-selection -- including one made on the map canvas -- opens this
# table rather than putting a mixed-value state into the form. Building mixed-value editing
# in both places would give one edit two routes with different capabilities, which is the
# reason the ruling pinned the surface at all.
#
# COMMON FIELDS ONLY, AND SCALARS AND ENUMS ONLY. `[CEUI-S14]` restricted the table so that
# references have exactly ONE authoring path -- the typed picker -- because a reference is
# the one field type that can dangle. This class inherits that restriction unchanged rather
# than re-deciding it: `EditorFormModel` derives which fields are bulk-editable from the
# schema, and a field it refuses is refused here WITH THE REASON, never silently dropped.
# A dropped column and an absent column look identical to an author.
#
# ONE EDIT IS ONE STAGED TRANSACTION OVER EVERY SELECTED RECORD (`[CEUI-S6]`). Setting a
# column stages a cell per record and the caller commits once, so a bulk edit across forty
# records is ONE Undo step and ONE `[CEUI-S25]` validation pass. Committing per record
# would make Undo forty presses and validation forty runs of the same check.
#
# MIXED IS A STATE, NOT A VALUE. A column whose selected records disagree reports
# `mixed: true` and a null value; writing a placeholder that happened to equal one record's
# value would silently flatten the others on the next commit.

const FormScript = preload("res://scripts/editor/EditorFormModel.gd")

## Author-facing. A selection of one is not an error, it is the Inspector's job.
const SINGLE_SELECTION_REASON := "Select more than one record to edit them together."

var _document: EditorDocument = null
var _schemas: EntitySchemaRegistry = null
var _record_ids: Array[String] = []
# record id -> EditorFormModel, so the field derivation is the form's and not a second one.
var _forms: Dictionary = {}


## `record_ids` is the selection. Order is preserved -- it is the order the surface
## selected them in, and re-sorting would move rows under the author's cursor.
static func over(
	document: EditorDocument, record_ids: Array, schemas: EntitySchemaRegistry = null
) -> EditorBulkTable:
	var table := EditorBulkTable.new()
	table._document = document
	table._schemas = schemas
	for record_id in record_ids:
		var id := String(record_id)
		if table._record_ids.has(id) or not document.has_record(id):
			continue
		table._record_ids.append(id)
		table._forms[id] = FormScript.over(document, id, schemas)
	return table


func record_ids() -> Array[String]:
	return _record_ids.duplicate()


func size() -> int:
	return _record_ids.size()


func is_active() -> bool:
	return _record_ids.size() > 1


## The columns the table offers: fields COMMON to every selected record's schema that are
## scalars or enums. `{name, label, kind, enum_values, value, mixed, values}`.
##
## Common means present in every selected record's field set -- the selection may span two
## schema versions of one kind, and a column only some records have is a column that would
## write a field into records whose schema does not declare it.
func columns() -> Array[Dictionary]:
	if _record_ids.is_empty():
		return []
	var counts: Dictionary = {}
	var specs: Dictionary = {}
	for record_id in _record_ids:
		for field in (_forms[record_id] as EditorFormModel).fields():
			if not bool(field["bulk_editable"]):
				continue
			var name := String(field["name"])
			counts[name] = int(counts.get(name, 0)) + 1
			if not specs.has(name):
				specs[name] = field
	var names: Array = counts.keys()
	names.sort()
	var out: Array[Dictionary] = []
	for name in names:
		if int(counts[name]) != _record_ids.size():
			continue
		var spec: Dictionary = specs[name]
		var values: Array = []
		var mixed := false
		var first: Variant = null
		var index := 0
		for record_id in _record_ids:
			var value: Variant = _document.value(record_id, String(name), null)
			values.append(value)
			if index == 0:
				first = value
			elif value != first:
				mixed = true
			index += 1
		(
			out
			. append(
				{
					"name": String(name),
					"label": String(spec["label"]),
					"kind": String(spec["kind"]),
					"enum_values": spec["enum_values"],
					# Null when mixed, deliberately: see the header.
					"value": null if mixed else first,
					"mixed": mixed,
					"values": values,
				}
			)
		)
	return out


## Fields the table will NOT offer, with the reason each is refused.
## `{name, label, kind, reason}`. Surfaced rather than dropped so an author looking for a
## column learns where that field IS edited instead of concluding it cannot be.
func refused_columns() -> Array[Dictionary]:
	if _record_ids.is_empty():
		return []
	var seen: Dictionary = {}
	var out: Array[Dictionary] = []
	for record_id in _record_ids:
		for field in (_forms[record_id] as EditorFormModel).fields():
			if bool(field["bulk_editable"]):
				continue
			var name := String(field["name"])
			if seen.has(name):
				continue
			seen[name] = true
			(
				out
				. append(
					{
						"name": name,
						"label": String(field["label"]),
						"kind": String(field["kind"]),
						"reason": String(field["bulk_reason"]),
					}
				)
			)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["name"] < b["name"])
	return out


## Stages one value across the whole selection. `{accepted, staged, reason}`.
##
## Returns the count staged so a caller can tell a refusal from an empty selection, and
## refuses a field the table does not offer WITH the reason that field carries -- the two
## reasons (`REFERENCE_NOT_BULK_REASON`, `STRUCTURED_NOT_BULK_REASON`) come from
## `EditorFormModel`, so there is one wording per refusal in the whole editor.
func set_value(field_name: String, value: Variant) -> Dictionary:
	if not is_active():
		return {"accepted": false, "staged": 0, "reason": SINGLE_SELECTION_REASON}
	for refused in refused_columns():
		if String(refused["name"]) == field_name:
			return {"accepted": false, "staged": 0, "reason": String(refused["reason"])}
	var offered := false
	for column in columns():
		if String(column["name"]) == field_name:
			offered = true
			break
	if not offered:
		return {
			"accepted": false,
			"staged": 0,
			"reason": "Not every selected record has that field.",
		}
	var cells: Array = []
	for record_id in _record_ids:
		cells.append({"record_id": record_id, "field": field_name, "value": value})
	# ONE staged transaction. `EditorDocument.stage_many` is what makes the whole edit a
	# single `[CEUI-13]` Undo unit when the caller commits.
	var staged := _document.stage_many(cells)
	return {"accepted": true, "staged": staged, "reason": ""}
