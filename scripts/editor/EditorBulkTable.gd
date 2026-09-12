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
# THE SELECTION IS OF SUBJECTS, NOT OF RECORD IDS (`EditorSubject`), AND THAT IS WHAT
# FINALLY LETS THE CANVAS ROUTE HERE. The ruling names a canvas selection in terms, but a
# map document's records are MAPS while a canvas selection is of marks WITHIN one map, so
# there was no address a table over record ids could accept. Generalizing the subject
# rather than the table is what keeps this the only multi-edit surface: nothing below this
# line changed to accommodate the canvas, and `[CEUI-S14]`'s reference/structured/identity
# restrictions transfer with no new rules because they are derived per subject by
# `EditorFormModel`.
#
# A SELECTION WITH NO COMMON FIELDS IS NAMED, NOT SHOWN EMPTY. Two enemy placements and a
# deployment tile have no schema in common -- one is an object of five fields, the other is
# `[x, y]` -- so the table says so, consistent with how a refused COLUMN is named rather
# than dropped. An empty table and a table whose columns were all refused look identical.
#
# MIXED IS A STATE, NOT A VALUE. A column whose selected records disagree reports
# `mixed: true` and a null value; writing a placeholder that happened to equal one record's
# value would silently flatten the others on the next commit.

const FormScript = preload("res://scripts/editor/EditorFormModel.gd")
const SubjectScript = preload("res://scripts/editor/EditorSubject.gd")

## Author-facing. A selection of one is not an error, it is the Inspector's job.
const SINGLE_SELECTION_REASON := "Select more than one record to edit them together."
## Author-facing. The selection is real and the table is empty for a reason the author can
## act on -- pick things of the same sort -- so it says which, rather than rendering a
## table with no rows.
const NO_COMMON_FIELDS_REASON := "These objects have no fields in common, so there is nothing to edit together."

var _document: EditorDocument = null
var _schemas: EntitySchemaRegistry = null
var _subjects: Array[Dictionary] = []
# Parallel to `_subjects`: the form for each, so the field derivation is the form's and not
# a second one.
var _forms: Array = []


## `record_ids` is the selection. Order is preserved -- it is the order the surface
## selected them in, and re-sorting would move rows under the author's cursor.
static func over(
	document: EditorDocument, record_ids: Array, schemas: EntitySchemaRegistry = null
) -> EditorBulkTable:
	var subjects: Array = []
	for record_id in record_ids:
		subjects.append(SubjectScript.for_record(String(record_id)))
	return over_subjects(document, subjects, schemas)


## The general selection: any `EditorSubject`s, which is what a canvas multi-selection
## produces. A subject that no longer resolves is DROPPED here rather than carried as an
## empty row -- an address into a property an edit has since removed names nothing, and a
## row for it would offer to edit something that is not there.
static func over_subjects(
	document: EditorDocument, subjects: Array, schemas: EntitySchemaRegistry = null
) -> EditorBulkTable:
	var table := EditorBulkTable.new()
	table._document = document
	table._schemas = schemas
	var seen: Dictionary = {}
	for entry in subjects:
		var subject: Dictionary = entry
		var key := SubjectScript.key(subject)
		if seen.has(key) or not SubjectScript.is_resolvable(document, subject):
			continue
		seen[key] = true
		table._subjects.append(subject)
		table._forms.append(FormScript.over_subject(document, subject, schemas))
	return table


## The RECORD subjects of the selection, in order. Empty for a canvas selection, whose
## subjects are items rather than records -- a caller that wants those wants `subjects()`.
func record_ids() -> Array[String]:
	var out: Array[String] = []
	for subject in _subjects:
		if not SubjectScript.is_item(subject):
			out.append(String(subject["record_id"]))
	return out


func subjects() -> Array[Dictionary]:
	return _subjects.duplicate(true)


func size() -> int:
	return _subjects.size()


func is_active() -> bool:
	return _subjects.size() > 1


## The columns the table offers: fields COMMON to every selected record's schema that are
## scalars or enums. `{name, label, kind, enum_values, value, mixed, values}`.
##
## Common means present in every selected record's field set -- the selection may span two
## schema versions of one kind, and a column only some records have is a column that would
## write a field into records whose schema does not declare it.
func columns() -> Array[Dictionary]:
	if _subjects.is_empty():
		return []
	var counts: Dictionary = {}
	var specs: Dictionary = {}
	# One resolved `{field: value}` per subject, gathered in the same pass. Read from the
	# FORM rather than from the document: an item subject's values live inside an array
	# cell, so `_document.value(record, field)` would resolve the map's own properties and
	# every column would read null.
	var resolved: Array = []
	for form in _forms:
		var values: Dictionary = {}
		for field in (form as EditorFormModel).fields():
			var name := String(field["name"])
			values[name] = field["value"]
			if not bool(field["bulk_editable"]):
				continue
			counts[name] = int(counts.get(name, 0)) + 1
			if not specs.has(name):
				specs[name] = field
		resolved.append(values)
	var names: Array = counts.keys()
	names.sort()
	var out: Array[Dictionary] = []
	for name in names:
		if int(counts[name]) != _subjects.size():
			continue
		var spec: Dictionary = specs[name]
		var values: Array = []
		var mixed := false
		var first: Variant = null
		for index in resolved.size():
			var value: Variant = (resolved[index] as Dictionary).get(String(name), null)
			values.append(value)
			if index == 0:
				first = value
			elif value != first:
				mixed = true
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
	if _subjects.is_empty():
		return []
	var seen: Dictionary = {}
	var out: Array[Dictionary] = []
	for form in _forms:
		for field in (form as EditorFormModel).fields():
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
	var offered_columns := columns()
	var offered := false
	for column in offered_columns:
		if String(column["name"]) == field_name:
			offered = true
			break
	if not offered:
		return {
			"accepted": false,
			"staged": 0,
			"reason":
			(
				NO_COMMON_FIELDS_REASON
				if offered_columns.is_empty()
				else "Not every selected object has that field."
			),
		}
	# ONE staged transaction, still. Each write goes through its subject's form, and every
	# form stages onto the SAME `EditorDocument` without committing, so the caller's single
	# `commit_edit()` is one `[CEUI-13]` Undo unit and one `[CEUI-S25]` validation pass
	# however many subjects there were. For item subjects in one property this collapses
	# further -- to one staged CELL holding the whole edited array -- because each write
	# reads back the array the previous one staged.
	var staged := 0
	var reason := ""
	for form in _forms:
		var outcome: Dictionary = (form as EditorFormModel).set_value(field_name, value)
		if bool(outcome["accepted"]):
			staged += 1
		elif reason == "":
			reason = String(outcome["reason"])
	if staged == 0:
		return {"accepted": false, "staged": 0, "reason": reason}
	# `reason` is carried on a partial write rather than dropped: every offered column is
	# offered because EVERY subject accepts it, so a refusal here means a subject went
	# stale between `over_subjects()` and the write, and swallowing that would leave the
	# author believing the whole selection took the value.
	return {"accepted": true, "staged": staged, "reason": reason}


## Why the table is showing nothing, or "" when it is showing something. `[EPUX-02]`: an
## empty surface has to say what would fill it.
func refusal_reason() -> String:
	if not is_active():
		return SINGLE_SELECTION_REASON
	if not columns().is_empty():
		return ""
	return NO_COMMON_FIELDS_REASON
