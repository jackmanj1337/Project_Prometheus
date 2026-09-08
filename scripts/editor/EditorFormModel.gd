class_name EditorFormModel extends RefCounted
# `[CEUI-S14]`'s schema-generated Inspector form, `[CEUI-S15]`'s reference picker and
# `[CEUI-S16]`'s value origins, over one record of one open document.
#
# THE FORM IS GENERATED FROM THE SCHEMA AND THE FIELD KINDS ARE DERIVED, NOT DECLARED.
# `[CEUI-S14]` resolved `CEUI-9` to schema-generated forms explicitly because a bespoke
# screen per content kind needs an engine edit per new content kind -- the closed-enum
# smell the architecture principle names outright. So this file contains no list of
# fields, no list of kinds, and no `match` on a property name. It reads
# `EntitySchemaRegistry.schema_for(kind, version)` and works out what each property is.
#
# THE FOUR FIELD KINDS, AND WHY THE SPLIT IS EXACTLY HERE:
#
#   REFERENCE  a string property carrying a `vocabulary`. This is the one field type that
#              CAN DANGLE, which is the whole reason `[CEUI-S14]` restricted the bulk table
#              and `[CEUI-S15]` made the typed picker the single authoring path. A
#              reference is never bulk-editable and never typed as a raw id.
#   ENUM       a property with an inline `enum`. A closed set with no separate registry
#              behind it, so nothing can dangle and the bulk table may edit it.
#   SCALAR     string, integer, number, boolean. Bulk-editable.
#   STRUCTURED array or object. Form-only: `[CEUI-S14]` ruled "no nested structures" for
#              the table, and a structured value has no meaningful mixed-value state.
#
# The split is derived from `vocabulary`/`enum`/`type` and nothing else, so a schema that
# adds a vocabulary to a field moves that field out of the bulk table with no edit here.
#
# `[CEUI-S16]`: AN UNSET VALUE HAS EXACTLY TWO ORIGINS -- A SCHEMA DEFAULT AND A TEMPLATE
# INSTANCE -- AND NEVER ANOTHER PACK. `ICO-1..6` reversed the base+overlay model, so an
# origin link implemented as a cross-pack pointer would revive exactly what `ICO` removed.
# That is why `set_template()` takes a plain Dictionary the caller copied (`[CEUI-S35]`
# ruled templates copy-on-create) and why there is no pack id anywhere in this file.
#
# THE FORM IS OVER A SUBJECT, WHICH IS A RECORD **OR AN ARRAY ITEM INSIDE ONE**
# (`EditorSubject`). `[CEUI-S14]` pins the Inspector to exactly one subject; it was pinned
# to one RECORD, and on a map document the only record is the whole map -- so clicking one
# enemy placement generated a form for `chapter_01` with its placements rendered as raw
# JSON in a read-only structured field. The schema for an item subject is the property's
# own `items` schema, so every derivation below runs on it unchanged: `unit` is an object
# and stays structured, `ai_profile` carries a vocabulary and stays a reference the bulk
# table refuses, `faction` and `is_boss` are scalars. That the four kinds and the bulk
# restriction survive the generalization WITHOUT BEING RESTATED is the test that the
# subject, not the table, was the thing that needed generalizing.
#
# EVERY EDIT GOES THROUGH THE DOCUMENT. `set_value()` stages; it does not write. The
# staged edit becomes an `[CEUI-13]` Undo unit and schedules `[CEUI-S25]`'s validation only
# when the caller commits, which is the shell's job. A form that wrote records directly
# would be a second mutation path around the transaction.

const SchemasScript = preload("res://scripts/data/EntitySchemaRegistry.gd")
const SubjectScript = preload("res://scripts/editor/EditorSubject.gd")

const FIELD_REFERENCE := "reference"
const FIELD_ENUM := "enum"
const FIELD_SCALAR := "scalar"
const FIELD_STRUCTURED := "structured"

## `[CEUI-S16]`'s two origins for a value the author has not set, plus the two states that
## are not origins at all. `ORIGIN_UNSET` is deliberately distinct from a schema default:
## a field with no default and no template has nothing to reset TO, and offering a reset
## that silently wrote null would be worse than offering none.
const ORIGIN_AUTHORED := "authored"
const ORIGIN_SCHEMA_DEFAULT := "schema_default"
const ORIGIN_TEMPLATE := "template"
const ORIGIN_UNSET := "unset"

## Author-facing refusals. Both name the ruling's reason rather than the mechanism, because
## `[EPUX-07]` puts them in front of someone standing on the field.
const REFERENCE_NOT_BULK_REASON := (
	"References are edited one at a time, through the picker, so a reference cannot be left "
	+ "pointing at nothing."
)
const STRUCTURED_NOT_BULK_REASON := "Nested values are edited in the form, not in the table."
## `[CEUI-S8]`: an id rename offers a usage preview and rewrites references only after an
## explicit per-rename confirmation, preceded by a recovery snapshot. A bulk table cell
## cannot do any of that -- and setting one id across a selection would give several records
## the same id, which is the one edit the document model cannot represent at all.
const IDENTITY_NOT_BULK_REASON := "Renaming an id rewrites references, so it is confirmed one record at a time."

var _document: EditorDocument = null
## The address this form edits. A record subject for every caller that had one before.
var _subject: Dictionary = {}
## The subject's record, which an item subject has too -- it is the record an item's write
## stages onto, because an item edit stages the WHOLE property.
var _record_id: String = ""
var _schemas: EntitySchemaRegistry = null
var _schema: Dictionary = {}
var _template: Dictionary = {}
# field name -> RecordSelector, built lazily. Held so focus survives a repaint: `[TSV-24]`
# is the selector's own contract and rebuilding one per call would defeat it.
var _reference_selectors: Dictionary = {}


## `version` defaults to the record's own `schema_version` when it declares one, because a
## pack may hold two versions of a kind and the record is the only thing that knows which
## it is (`[CEUI-S21]` keeps them under one category for exactly that reason).
static func over(
	document: EditorDocument,
	record_id: String,
	schemas: EntitySchemaRegistry = null,
	version: int = 0
) -> EditorFormModel:
	return over_subject(document, SubjectScript.for_record(record_id), schemas, version)


## The general form: any `EditorSubject`. An item subject generates from the property's
## `items` schema, so a pack property shaped like an array of objects gets a form with no
## edit here -- the same derivation-not-declaration rule the field kinds already follow.
##
## The version is still the RECORD's: a map's items do not carry their own `schema_version`
## and inventing one for them would be a second version authority inside one record.
static func over_subject(
	document: EditorDocument,
	subject: Dictionary,
	schemas: EntitySchemaRegistry = null,
	version: int = 0
) -> EditorFormModel:
	var model := EditorFormModel.new()
	model._document = document
	model._subject = subject.duplicate(true)
	model._record_id = String(subject.get("record_id", ""))
	model._schemas = schemas if schemas != null else SchemasScript.with_core_schemas()
	var resolved := version
	if resolved <= 0:
		resolved = int(document.value(model._record_id, "schema_version", 1))
	var record_schema: Dictionary = model._schemas.schema_for(document.kind, resolved)
	if not SubjectScript.is_item(subject):
		model._schema = record_schema
		return model
	var properties: Dictionary = record_schema.get("properties", {})
	var property := String(subject.get("property", ""))
	model._schema = SubjectScript.item_schema(properties.get(property, null))
	return model


## `[CEUI-31]`/`[CEUI-S35]`: a template instance is COPIED at create time, never inherited
## live. This takes the copy; it does not resolve one, and it holds no reference back to
## whatever produced it.
func set_template(template: Dictionary) -> void:
	_template = template.duplicate(true)


func record_id() -> String:
	return _record_id


func subject() -> Dictionary:
	return _subject.duplicate(true)


func is_item_subject() -> bool:
	return SubjectScript.is_item(_subject)


## Author-facing heading. A record subject is its id; an item subject names the map, the
## property and which one, because "Enemy Placements" alone does not say which of six.
func subject_label() -> String:
	return SubjectScript.label(_subject)


## True when the document's kind has no registered schema. A form over an unschema'd kind
## is empty rather than invented -- the surface says so instead of showing the author a
## blank panel that looks like a loading state.
func has_schema() -> bool:
	return not _schema.is_empty()


## True when the subject has fields to show. Distinct from `has_schema()`: a deployment
## tile IS described by the schema -- as `[x, y]`, an array with no properties -- so it is a
## mark with nothing of its own to edit rather than a kind nobody registered. The two read
## identically as a blank panel and say opposite things to whoever is looking at it.
func has_fields() -> bool:
	return not (_schema.get("properties", {}) as Dictionary).is_empty()


## Every field, in the schema's property order (sorted, because a Dictionary's order is
## not authored). `{name, label, kind, type, required, enum_values, vocabulary,
## constraints, value, origin, is_set, bulk_editable, bulk_reason}`.
func fields() -> Array[Dictionary]:
	var properties: Dictionary = _schema.get("properties", {})
	var names: Array = properties.keys()
	names.sort()
	var required: Array = _schema.get("required", [])
	var values := _values()
	var out: Array[Dictionary] = []
	for name in names:
		var field_name := String(name)
		var spec: Variant = properties[field_name]
		if not (spec is Dictionary):
			continue
		out.append(_field(field_name, spec, required.has(field_name), values))
	return out


func field(field_name: String) -> Dictionary:
	var properties: Dictionary = _schema.get("properties", {})
	if not properties.has(field_name):
		return {}
	var required: Array = _schema.get("required", [])
	return _field(field_name, properties[field_name], required.has(field_name), _values())


func kind_of(field_name: String) -> String:
	var resolved := field(field_name)
	return String(resolved.get("kind", ""))


## `[CEUI-S15]`: the reference picker IS the shared selector, not a second one. Returns
## null for a field that is not a reference -- a selector over a scalar would be the sixth
## instance of the duplicate-mechanism shape the ruling exists to prevent.
##
## The selector is built once per field and kept, so focus and filters survive a repaint.
func reference_selector(field_name: String) -> RecordSelector:
	var resolved := field(field_name)
	if String(resolved.get("kind", "")) != FIELD_REFERENCE:
		return null
	if _reference_selectors.has(field_name):
		return _reference_selectors[field_name]
	var selector := RecordSelector.new()
	var records: Array = []
	for value in _schemas.vocabulary_values(String(resolved["vocabulary"])):
		records.append({"id": value, "payload": {"id": value, "label": value}})
	selector.set_records(records)
	# `.get("value", "")` is NOT enough: the key is always present and its value is null for
	# an unset field, so the default never applies and `String(null)` is a runtime error.
	var raw: Variant = resolved.get("value", null)
	var current := "" if raw == null else String(raw)
	if current != "" and selector.has(current):
		selector.focus(current)
	_reference_selectors[field_name] = selector
	return selector


# ---- editing, all of it staged ----


## Stages a value. Returns `{accepted, reason}` rather than a bool: a refusal that only
## said "no" would leave the surface inventing the reason, which is the shape `[EPUX-07]`
## rules against everywhere else in this shell.
func set_value(field_name: String, value: Variant) -> Dictionary:
	var resolved := field(field_name)
	if resolved.is_empty():
		return {"accepted": false, "reason": "This field is not in the schema."}
	if String(resolved["kind"]) == FIELD_REFERENCE:
		var vocabulary := String(resolved["vocabulary"])
		# The picker's whole job is that a reference cannot be set to something the
		# vocabulary does not admit. Checking here rather than at commit means the author
		# learns it at the moment they chose, not one action later.
		if not _schemas.vocabulary_admits(vocabulary, String(value)):
			return {
				"accepted": false,
				"reason": "'%s' is not a known %s." % [String(value), vocabulary],
			}
	return _stage(field_name, value)


## `[CEUI-S16]`'s per-field reset: back to the origin the value would have if the author
## had never set it. Refuses when there is no origin -- see `ORIGIN_UNSET`.
func reset(field_name: String) -> Dictionary:
	var origin := _origin_value(field_name)
	if not bool(origin["present"]):
		return {
			"accepted": false,
			"reason": "This field has no default or template value to reset to.",
		}
	return _stage(field_name, origin["value"])


func can_reset(field_name: String) -> bool:
	return bool(_origin_value(field_name)["present"])


# ---- internals ----


## The subject's fields, with all three document layers resolved. A record subject is the
## record; an item subject is the addressed item, and an item that is not an object -- a
## deployment tile is `[x, y]` -- resolves to no fields rather than to invented ones.
func _values() -> Dictionary:
	if SubjectScript.is_item(_subject):
		return SubjectScript.fields_of(_document, _subject)
	return _document.record(_record_id)


## THE ONE PLACE THIS FILE WRITES, and the whole reason the generalization is cheap.
##
## A record subject stages the field. An item subject stages THE WHOLE PROPERTY -- the
## edited array, with one field of one item changed -- because `EditorDocument.stage()` is
## keyed `(record_id, field)` and an array item is not a field. That is not a workaround:
## it is what makes a bulk edit across three placements ONE staged cell and therefore ONE
## `[CEUI-13]` Undo step, where routing it through three records would need `stage_many`
## and care. Repeated calls compound correctly because `EditorDocument.value()` resolves
## the staged layer first, so each write reads the array the previous one staged.
func _stage(field_name: String, value: Variant) -> Dictionary:
	if not SubjectScript.is_item(_subject):
		_document.stage(_record_id, field_name, value)
		return {"accepted": true, "reason": ""}
	var write := SubjectScript.with_field(_document, _subject, field_name, value)
	if not bool(write["accepted"]):
		return {"accepted": false, "reason": String(write["reason"])}
	_document.stage(_record_id, String(write["property"]), write["value"])
	return {"accepted": true, "reason": ""}


## `values` is the subject's resolved field set, passed in so a form over forty fields
## resolves the document once rather than once per field.
func _field(
	field_name: String, spec: Dictionary, is_required: bool, values: Dictionary
) -> Dictionary:
	var kind := _kind_for(spec)
	var value: Variant = values.get(field_name, null)
	var is_set: bool = values.has(field_name)
	# DERIVED, not named. `EditorDocument` keys records by id, so the identity field is
	# whichever field mirrors that key -- which is family-agnostic, unlike spelling "id"
	# here and re-introducing the hand-written list `[CEUI-S21]` bans one level up. A
	# document whose records mirror no key simply has no identity field and nothing is
	# refused on this ground.
	#
	# AN ITEM SUBJECT HAS NO IDENTITY FIELD AT ALL, and that is not an omission: an array
	# item's only identity is its index, which is exactly why `[CEUI-S8]`'s rename does not
	# reach it and why a field of one that happened to equal the map's id must not be
	# refused as if renaming it would rewrite references.
	var is_identity: bool = (
		not SubjectScript.is_item(_subject) and value != null and str(value) == _record_id
	)
	var bulk_editable := (kind == FIELD_SCALAR or kind == FIELD_ENUM) and not is_identity
	var bulk_reason := ""
	if is_identity:
		bulk_reason = IDENTITY_NOT_BULK_REASON
	elif kind == FIELD_REFERENCE:
		bulk_reason = REFERENCE_NOT_BULK_REASON
	elif kind == FIELD_STRUCTURED:
		bulk_reason = STRUCTURED_NOT_BULK_REASON
	return {
		"name": field_name,
		# Humanized rather than authored: no schema declares a form label today, and
		# inventing a label table here would be the hand-written list `[CEUI-S21]` bans one
		# level up. A `label` on the property spec would be read first if one appeared.
		"label": String(spec.get("label", field_name.replace("_", " ").capitalize())),
		"kind": kind,
		"type": String(spec.get("type", "")),
		"required": is_required,
		"enum_values": _string_list(spec.get("enum", [])),
		"nullable": _admits_null(spec.get("enum", [])),
		"vocabulary": String(spec.get("vocabulary", "")),
		"constraints": _constraints(spec),
		"value": value,
		"origin": _origin_of(field_name, is_set),
		"is_set": is_set,
		"identity": is_identity,
		"bulk_editable": bulk_editable,
		"bulk_reason": bulk_reason,
	}


## Derived, never declared. A `vocabulary` outranks everything because it is what makes a
## value a REFERENCE -- a string that must resolve against a registry -- and that is the
## property the two rulings key their restrictions on.
func _kind_for(spec: Dictionary) -> String:
	if spec.has("vocabulary"):
		return FIELD_REFERENCE
	if spec.has("enum"):
		return FIELD_ENUM
	match String(spec.get("type", "")):
		"array", "object":
			return FIELD_STRUCTURED
		"string", "integer", "number", "boolean":
			return FIELD_SCALAR
		_:
			# An untyped or unknown property is treated as structured, which is the
			# conservative answer: it stays out of the bulk table rather than being offered
			# there as a scalar it may not be.
			return FIELD_STRUCTURED


func _constraints(spec: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key in ["minimum", "maximum", "min_length", "max_length", "min_items", "max_items"]:
		if spec.has(key):
			out[key] = spec[key]
	return out


func _origin_of(field_name: String, is_set: bool) -> String:
	if is_set:
		return ORIGIN_AUTHORED
	var origin := _origin_value(field_name)
	return String(origin.get("origin", ORIGIN_UNSET))


## Template first, then the schema default. `[CEUI-S16]` names both and does not order
## them; a template instance is the more specific statement about THIS record, so it wins.
## No engine schema declares a `default` today -- the branch is here because the ruling
## names it, and a schema that adds one needs no edit.
func _origin_value(field_name: String) -> Dictionary:
	if _template.has(field_name):
		return {"present": true, "origin": ORIGIN_TEMPLATE, "value": _template[field_name]}
	var properties: Dictionary = _schema.get("properties", {})
	var spec: Variant = properties.get(field_name, {})
	if spec is Dictionary and (spec as Dictionary).has("default"):
		return {
			"present": true,
			"origin": ORIGIN_SCHEMA_DEFAULT,
			"value": (spec as Dictionary)["default"],
		}
	return {"present": false, "origin": ORIGIN_UNSET}


## A null entry in an `enum` is NOT a pickable label -- it is the schema saying the field
## admits being absent. It is dropped from the option list and reported as `nullable`
## instead, because an option rendered as an empty string is indistinguishable from an
## option whose label happens to be empty, and `String(null)` is a runtime error besides.
func _string_list(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for entry in value as Array:
			if entry == null:
				continue
			# `str()`, not `String()`: Godot's String constructor takes only string-like
			# types, so `String(1)` is a runtime error -- and an inline enum of INTEGERS is
			# exactly what the document header uses to declare its admitted schema versions.
			out.append(str(entry))
	return out


func _admits_null(value: Variant) -> bool:
	if not (value is Array):
		return false
	for entry in value as Array:
		if entry == null:
			return true
	return false
