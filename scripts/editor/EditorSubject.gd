class_name EditorSubject extends RefCounted
# The ADDRESS of a thing the Inspector or the bulk table edits. `[CEUI-S23]` says any
# multi-selection -- "including a selection made on the map canvas" -- opens `[CEUI-S14]`'s
# bulk table over that selection. Only the address was missing, so this file supplies it
# rather than a second table.
#
# WHY AN ADDRESS AND NOT A RECORD ID. A map document's RECORDS are maps: `open_kind` opens
# one document per content kind holding every record of it, so the Maps document holds
# `chapter_01`, `chapter_02`, ... A canvas selection is of marks WITHIN one map --
# placements, deployment tiles, objective conditions -- and those are not records of that
# document. Bound to a record id, the Inspector over a map selection can only show a form
# for the whole map, which is why clicking one enemy placement showed `chapter_01` with its
# placements rendered as a raw JSON string.
#
# SO A SUBJECT IS EITHER A RECORD OR AN ARRAY ITEM INSIDE ONE:
#
#   RECORD  `{record_id}`                             -- what every subject was until now.
#   ITEM    `{record_id, property, group, index}`      -- `record -> property -> index`,
#           plus the author-named `group` for the grouped shape (`victory_conditions` is an
#           object whose keys are the author's alliance-group names).
#
# THE GROUP IS AN ADDRESS COMPONENT, NOT A SUBJECT KIND. The grouped objectives shape is
# still one item inside one array; giving it its own kind would fork every caller on a
# distinction that changes nothing about what an edit does.
#
# MAKING MAP OBJECTS INTO DOCUMENT RECORDS WAS REJECTED AND THIS IS WHY. They have no ids
# -- their only identity is an array index -- so a document keyed by index-derived ids is
# wrong the moment an insertion shifts them, and `[CEUI-S8]`'s rename, the record selector
# and `[CEUI-S26]`'s object-and-field navigation all assume stable ids. It would also split
# one map across two documents, so `[CEUI-S6]`'s document-scoped transaction would span two
# documents for one author action.
#
# THE RISK INDEX ADDRESSING CARRIES, AND THE RULE THAT CONTAINS IT. An index is only a
# stable address while the array's shape is. So A SELECTION IS RE-DERIVED AFTER ANY COMMIT
# AND DROPPED WHEN ITS PROPERTY'S LENGTH CHANGED OR THE PROPERTY IS GONE -- see
# `capture_lengths()` / `re_derive()`. Dropping only the out-of-range subjects would be
# worse than dropping the selection: the survivors would silently point at different
# objects than the ones the author clicked.
#
# AN EDIT TO AN ITEM STAGES THE WHOLE PROPERTY, WHICH IS WHY ATOMICITY IS FREE.
# `EditorDocument.stage()` is keyed `(record_id, field)` and the field here is the entire
# `enemy_placements` array, so editing three placements' faction stages ONE cell -> one
# commit -> `undo_depth() == 1`, satisfying `[CEUI-13]` by construction rather than by care.

const KIND_RECORD := "record"
const KIND_ITEM := "item"

## Refused when a caller tries to write a field into a mark that has no fields -- a
## deployment tile is `[x, y]`, an array, not an object with properties.
const NO_FIELDS_REASON := "This mark has no fields of its own to edit."


static func for_record(record_id: String) -> Dictionary:
	return {"kind": KIND_RECORD, "record_id": record_id, "property": "", "group": "", "index": -1}


static func for_item(
	record_id: String, property: String, index: int, group: String = ""
) -> Dictionary:
	return {
		"kind": KIND_ITEM,
		"record_id": record_id,
		"property": property,
		"group": group,
		"index": index,
	}


## A canvas mark is `{property, index, group, tile, layer}` -- `EditorMapCanvas` publishes
## exactly the address an edit needs, so this reads it rather than re-deriving it from the
## tile. The record id comes from the caller because the mark is within one map and the
## canvas already knows which.
static func from_mark(record_id: String, mark: Dictionary) -> Dictionary:
	return for_item(
		record_id,
		String(mark.get("property", "")),
		int(mark.get("index", -1)),
		String(mark.get("group", "")),
	)


static func is_item(subject: Dictionary) -> bool:
	return String(subject.get("kind", KIND_RECORD)) == KIND_ITEM


## Identity for de-duplication. Two selections of the same mark are one subject; the tile
## and layer a mark also carries are NOT part of the address, because moving a placement
## does not make it a different placement.
static func key(subject: Dictionary) -> String:
	if not is_item(subject):
		return "%s|" % String(subject.get("record_id", ""))
	return (
		"%s|%s|%s|%d"
		% [
			String(subject.get("record_id", "")),
			String(subject.get("property", "")),
			String(subject.get("group", "")),
			int(subject.get("index", -1)),
		]
	)


## Author-facing. Says which map, which property and which one of them, because "Enemy
## Placements" alone does not tell an author which of six they are editing.
static func label(subject: Dictionary) -> String:
	var record_id := String(subject.get("record_id", ""))
	if not is_item(subject):
		return record_id
	var readable := String(subject.get("property", "")).replace("_", " ").capitalize()
	var group := String(subject.get("group", ""))
	var where := readable if group == "" else "%s / %s" % [readable, group]
	return "%s  -  %s %d" % [record_id, where, int(subject.get("index", -1)) + 1]


# ---- resolving against the document ----


## The ITEM SCHEMA a property's items are described by, derived from the property's own
## shape the same way `EditorMapCanvas` derives its tools -- an array declares `items`, and
## the grouped shape is an object whose `additional_properties` is an array of them. No
## property name is matched on, so a pack property with either shape addresses with no edit
## here.
static func item_schema(property_spec: Variant) -> Dictionary:
	if not (property_spec is Dictionary):
		return {}
	var spec: Dictionary = property_spec
	match String(spec.get("type", "")):
		"array":
			var items: Variant = spec.get("items", null)
			return items if items is Dictionary else {}
		"object":
			var additional: Variant = spec.get("additional_properties", null)
			if not (additional is Dictionary):
				return {}
			var grouped: Variant = (additional as Dictionary).get("items", null)
			return grouped if grouped is Dictionary else {}
		_:
			return {}


## The array a subject indexes into, or `null` when the property or group is absent. For a
## plain array property that is the property's value; for the grouped shape it is the one
## group's array.
static func container(document: EditorDocument, subject: Dictionary) -> Variant:
	if document == null or not is_item(subject):
		return null
	var record_id := String(subject.get("record_id", ""))
	if not document.has_record(record_id):
		return null
	var held: Variant = document.value(record_id, String(subject.get("property", "")), null)
	var group := String(subject.get("group", ""))
	if group == "":
		return held if held is Array else null
	if not (held is Dictionary):
		return null
	var entries: Variant = (held as Dictionary).get(group, null)
	return entries if entries is Array else null


## The addressed item, as `{present, value}`. `present` is false for a property that is
## gone, a group that is gone, and an index past the end -- the three ways an address goes
## stale, all answered the same way so no caller has to tell them apart.
static func resolve(document: EditorDocument, subject: Dictionary) -> Dictionary:
	if not is_item(subject):
		var record_id := String(subject.get("record_id", ""))
		if document == null or not document.has_record(record_id):
			return {"present": false, "value": null}
		return {"present": true, "value": document.record(record_id)}
	var entries: Variant = container(document, subject)
	if not (entries is Array):
		return {"present": false, "value": null}
	var index := int(subject.get("index", -1))
	if index < 0 or index >= (entries as Array).size():
		return {"present": false, "value": null}
	return {"present": true, "value": (entries as Array)[index]}


static func is_resolvable(document: EditorDocument, subject: Dictionary) -> bool:
	return bool(resolve(document, subject)["present"])


## The item's fields, or an empty Dictionary for a mark that is not an object. A deployment
## tile resolves to `[x, y]`, which has no fields -- that is a mark with nothing to edit,
## not an error, and the surface says so instead of inventing fields for it.
static func fields_of(document: EditorDocument, subject: Dictionary) -> Dictionary:
	var resolved := resolve(document, subject)
	if not bool(resolved["present"]):
		return {}
	var value: Variant = resolved["value"]
	return value if value is Dictionary else {}


# ---- writing ----


## The WHOLE property value a write to one item's field produces, ready to stage as one
## cell. Returns `{accepted, reason, property, value}`.
##
## The container is duplicated before the write: `EditorDocument.value()` resolves through
## the saved layer, so mutating what it returns would edit the saved record in place and
## the staged transaction would have nothing to undo.
static func with_field(
	document: EditorDocument, subject: Dictionary, field: String, value: Variant
) -> Dictionary:
	var resolved := resolve(document, subject)
	if not bool(resolved["present"]):
		return {
			"accepted": false,
			"reason": "That selection is no longer in the document.",
			"property": "",
			"value": null
		}
	if not (resolved["value"] is Dictionary):
		return {"accepted": false, "reason": NO_FIELDS_REASON, "property": "", "value": null}
	var property := String(subject.get("property", ""))
	var record_id := String(subject.get("record_id", ""))
	var group := String(subject.get("group", ""))
	var index := int(subject.get("index", -1))
	var held: Variant = document.value(record_id, property, null)
	if group == "":
		if not (held is Array):
			return {
				"accepted": false,
				"reason": "That selection is no longer in the document.",
				"property": "",
				"value": null
			}
		var array: Array = (held as Array).duplicate(true)
		((array[index]) as Dictionary)[field] = value
		return {"accepted": true, "reason": "", "property": property, "value": array}
	if not (held is Dictionary):
		return {
			"accepted": false,
			"reason": "That selection is no longer in the document.",
			"property": "",
			"value": null
		}
	var groups: Dictionary = (held as Dictionary).duplicate(true)
	var entries: Variant = groups.get(group, null)
	if not (entries is Array):
		return {
			"accepted": false,
			"reason": "That selection is no longer in the document.",
			"property": "",
			"value": null
		}
	(((entries as Array)[index]) as Dictionary)[field] = value
	return {"accepted": true, "reason": "", "property": property, "value": groups}


# ---- keeping a selection honest across a commit ----


## The length of every property a selection addresses, keyed by `record|property|group`.
## Captured when the selection is made, so `re_derive()` has something to compare against.
static func capture_lengths(document: EditorDocument, subjects: Array) -> Dictionary:
	var out: Dictionary = {}
	for entry in subjects:
		var subject: Dictionary = entry
		if not is_item(subject):
			continue
		out[_container_key(subject)] = _container_length(document, subject)
	return out


## The selection that is still true of the document, per this file's header rule: a subject
## survives only when its property is still there AND still the same length. A length change
## means an insertion or a deletion moved every index after it, so the addresses the author
## clicked no longer name the objects they clicked.
static func re_derive(document: EditorDocument, subjects: Array, lengths: Dictionary) -> Array:
	var out: Array = []
	for entry in subjects:
		var subject: Dictionary = entry
		if not is_item(subject):
			if is_resolvable(document, subject):
				out.append(subject)
			continue
		var container_key := _container_key(subject)
		var was := int(lengths.get(container_key, -1))
		if was >= 0 and _container_length(document, subject) != was:
			continue
		if is_resolvable(document, subject):
			out.append(subject)
	return out


static func _container_key(subject: Dictionary) -> String:
	return (
		"%s|%s|%s"
		% [
			String(subject.get("record_id", "")),
			String(subject.get("property", "")),
			String(subject.get("group", "")),
		]
	)


## `-1` for a property or group that is absent, which is distinct from an empty array: a
## property emptied by an edit is still there, and a selection into it is stale either way.
static func _container_length(document: EditorDocument, subject: Dictionary) -> int:
	var entries: Variant = container(document, subject)
	return (entries as Array).size() if entries is Array else -1
