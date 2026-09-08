class_name EditorObjectiveOutline extends RefCounted
# `[CEUI-S32]`'s Graph workspace: THE ORDERED OUTLINE OVER AUTHORED TRIGGER AND OBJECTIVE
# LOGIC, and the read-mostly graph PROJECTION of it. Headless state, like every other piece
# of the editor, so the ruling can be asserted without a viewport.
#
# THE OUTLINE IS THE CANONICAL FORM AND THE PROJECTION IS A RENDERING OF IT. `[CEUI-S32]`
# resolved `CEUI-25` to ordered readable cards backed by registered predicates, with links
# into the map, and made any graph "a demand-gated, read-mostly projection over the same
# data and stable IDs -- never a second source format, never a second thing to migrate".
# Three things in this file are that ruling and not style:
#
#   * `projection()` DERIVES from `cards()` on every call and stores nothing. There is no
#     node table, no edge table and NO LAYOUT anywhere in this file. A graph that owned
#     its own layout, or its own edges, would be a second authority over authored triggers
#     -- the author would move a node, the outline would not know, and one of the two would
#     have to win at save time.
#   * A projection node's id IS the card's id, which is the `EditorSubject` address. The
#     projection cannot mint an identity of its own, so it cannot drift from the outline it
#     renders.
#   * It is DEMAND-GATED: `projection()` returns `{}` until something asks for the graph.
#     The outline is what the workspace shows; the graph is what an author opens.
#
# WHICH PROPERTIES ARE THE OUTLINE'S IS DERIVED, NOT DECLARED, and the shape of the
# derivation is the ruling's other half. `[CEUI-S32]` says the cards are "backed by
# REGISTERED predicates and actions" -- `TCV-4`/`REQ`/`EXT` make that vocabulary an open
# registry, so option C's fixed event dropdowns were never available. So an outline
# property is one WHOSE ITEMS ARE IDENTIFIED BY A REGISTRY: an item schema with a REQUIRED
# field carrying a `vocabulary`.
#
# THE WORD "REQUIRED" IS LOAD-BEARING THERE. `enemy_placements` items carry `ai_profile`,
# which has a vocabulary too -- but a placement's identity is its unit and its tile, and
# `ai_profile` is an optional refinement of it. A placement is a MARK, which is
# `[CEUI-S31]`'s canvas; a victory condition's identity IS the registered `type` it
# resolves to, which is what makes it a predicate and puts it in the outline. Matching on
# "has a vocabulary anywhere" would put every placement on the objective outline, and
# matching on the property NAME would be `[CEUI-S21]`'s closed enum one level down: a pack
# that registers its own predicate-backed collection gets an outline with no editor edit.
#
# THE CAMPAIGN STRUCTURE GRAPH IS NOT THIS FILE, AND `[CEUI-S32]` SAYS SO OUTRIGHT.
# "Campaign structure -- nodes and the edges between them -- IS graph-shaped data, so a
# graph is its canonical presentation." That is a different surface over a different
# document with a canonical graph of its own, and building it inside the file whose whole
# subject is "the graph is never canonical" is how the two would end up sharing an
# assumption neither wants. It is `EDITOR-CAMPAIGN-STRUCTURE-GRAPH-2026-09-08`.
#
# EVERY EDIT IS A STAGED TRANSACTION, exactly as on the canvas. Card edits stage onto the
# open `EditorDocument` and commit nothing; the caller commits through
# `CampaignEditorShell.commit_active_edit()` so `[CEUI-S25]`'s incremental validation runs
# and `[CEUI-13]`'s Undo unit stays one author action. An edit to one card stages the WHOLE
# property (`EditorSubject`), so reordering three cards is still one Undo step.

const SubjectScript = preload("res://scripts/editor/EditorSubject.gd")
const CanvasScript = preload("res://scripts/editor/EditorMapCanvas.gd")

## Why an edit refuses. Author-facing per `[EPUX-07]`: a card that silently did nothing is
## indistinguishable from a card that is broken.
const NO_RECORD_REASON := "Open a document with authored objectives to edit its outline."
const NO_CARD_REASON := "That card is no longer in the document."
const UNKNOWN_PREDICATE_REASON := "No registered condition has that id. Register it before authoring against it."
const NOT_AN_OUTLINE_PROPERTY_REASON := "That property holds no registry-backed conditions, so it has no outline."
const AT_EDGE_REASON := "That card is already at the end of its list."

## The two edge kinds a projection draws, and there are only two because the outline has
## only two relationships to render: a card belongs to a group, and a card follows another.
## Neither is authored as an edge -- both are read off the array the outline already is,
## which is what "a projection over the same data" means.
const EDGE_CONTAINS := "contains"
const EDGE_FOLLOWS := "follows"

## Node kinds in the projection. A GROUP node is the author's own alliance-group name; a
## CARD node is one outline card and carries its id.
const NODE_GROUP := "group"
const NODE_CARD := "card"


## The REQUIRED field of `item_spec` that carries a `vocabulary`, or `""`. See the header on
## why required rather than any: it is the difference between a predicate and a mark.
##
## Name order among several, for determinism only -- no schema in the corpus has two, and a
## schema that grows one has not said which is the identity.
static func predicate_field(item_spec: Variant) -> String:
	if not (item_spec is Dictionary):
		return ""
	var spec: Dictionary = item_spec
	var properties: Variant = spec.get("properties", null)
	if not (properties is Dictionary):
		return ""
	var required: Array = spec.get("required", []) as Array
	var names: Array = []
	for name in required:
		names.append(String(name))
	names.sort()
	for name in names:
		var field_spec: Variant = (properties as Dictionary).get(name, null)
		if (
			field_spec is Dictionary
			and String((field_spec as Dictionary).get("vocabulary", "")) != ""
		):
			return String(name)
	return ""


## Every property of `properties` whose items are registry-identified, in the schema's own
## declaration order. The order is not sorted here: it is the order the schema author
## wrote, and `victory_conditions` before `defeat_conditions` is a statement.
static func outline_properties(properties: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for name in properties:
		var item_spec := SubjectScript.item_schema(properties[name])
		if predicate_field(item_spec) != "":
			out.append(String(name))
	return out


## The vocabulary id a property's predicates resolve against, or `""`. The OUTLINE never
## holds the values themselves -- it asks the registry every time through
## `predicate_options()`, because a cached vocabulary is the closed dropdown `[CEUI-S32]`
## refused wearing a cache's clothes.
static func predicate_vocabulary(item_spec: Variant) -> String:
	var field := predicate_field(item_spec)
	if field == "":
		return ""
	var properties: Dictionary = (item_spec as Dictionary).get("properties", {})
	return String((properties.get(field, {}) as Dictionary).get("vocabulary", ""))


var _document: EditorDocument = null
var _record_id: String = ""
## The record schema's `properties`, from the registry the shell holds. Derived once per
## `set_record()` rather than per card: `[CEUI-S21]`'s cost is paid per session already.
var _properties: Dictionary = {}
var _schemas: EntitySchemaRegistry = null
## `[CEUI-S32]`'s demand gate. False means the workspace is showing the outline and nothing
## is asking for a graph, which is the default because the outline is the canonical form.
var _projection_enabled: bool = false


## Points the outline at one record of an open document. `schemas` is the shell's registry
## (`CampaignEditorShell.schemas()`), not one built here -- a second registry per surface is
## `[CEUI-S21]`'s cost paid twice per session.
func set_record(document: EditorDocument, record_id: String, schemas: EntitySchemaRegistry) -> void:
	_document = document
	_record_id = record_id
	_schemas = schemas
	_properties = {}
	if document == null or schemas == null or record_id == "":
		return
	var version := int(document.value(record_id, "schema_version", 1))
	_properties = schemas.schema_for(document.kind, version).get("properties", {})


func has_record() -> bool:
	return (
		_document != null
		and _record_id != ""
		and _document.has_record(_record_id)
		and not _properties.is_empty()
	)


## The outline properties of the CURRENT record's schema.
func properties() -> Array[String]:
	return outline_properties(_properties)


## `[CEUI-S32]`: the registered predicates an author may choose from, read from the
## registry every time. Empty for a property that is not an outline property, which reads
## as "nothing to choose here" rather than as an empty registry.
func predicate_options(property: String) -> Array[String]:
	if _schemas == null:
		return [] as Array[String]
	var vocabulary := predicate_vocabulary(
		SubjectScript.item_schema(_properties.get(property, null))
	)
	if vocabulary == "":
		return [] as Array[String]
	return _schemas.vocabulary_values(vocabulary)


# ---- the outline ----


## The ordered cards, across every outline property of the record.
##
## THE ORDER IS THE AUTHORED ORDER and nothing re-sorts it: property order is the schema's,
## and within a property the card order is the array's index order, which is the thing
## `[CEUI-S32]`'s "ordered readable cards" is about. Author-named GROUPS are sorted by name,
## because a JSON object's key order is not an authoring statement the way an array's index
## order is -- there is no editor action that moves a group up.
##
## Each card is `{id, subject, property, group, index, position, predicate, predicate_field,
## summary, tiles, fields}`. `id` is the `EditorSubject` address, and it is the id the
## projection uses: see the header.
func cards() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not has_record():
		return out
	for property in properties():
		var item_spec := SubjectScript.item_schema(_properties.get(property, null))
		var field := predicate_field(item_spec)
		var held: Variant = _document.value(_record_id, property, null)
		if held is Array:
			out.append_array(_cards_in(property, "", held as Array, item_spec, field))
		elif held is Dictionary:
			var group_names: Array = (held as Dictionary).keys()
			group_names.sort()
			for group in group_names:
				var entries: Variant = (held as Dictionary)[group]
				if entries is Array:
					out.append_array(
						_cards_in(property, String(group), entries as Array, item_spec, field)
					)
	return out


## One card by its id, or `{}`.
func card(card_id: String) -> Dictionary:
	for entry in cards():
		if String(entry["id"]) == card_id:
			return entry
	return {}


## `[CEUI-S32]`'s "with links into the map": the subjects a card selection publishes, which
## is the SAME address the canvas publishes for the same condition. That is what makes the
## link a navigation rather than a copy -- selecting a card in the outline and clicking its
## mark on the canvas put the identical subject in front of the Inspector.
func subjects_for(card_ids: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var wanted: Dictionary = {}
	for id in card_ids:
		wanted[String(id)] = true
	for entry in cards():
		if wanted.has(String(entry["id"])):
			out.append((entry["subject"] as Dictionary).duplicate(true))
	return out


# ---- the `[CEUI-S32]` projection ----


## The demand gate. Off by default: the outline is what the workspace shows.
func set_projection_enabled(enabled: bool) -> void:
	_projection_enabled = enabled


func is_projection_enabled() -> bool:
	return _projection_enabled


## `{nodes, edges}` derived from `cards()` on every call, or `{}` while the gate is closed.
##
## NOTHING HERE IS STORED AND NOTHING HERE HAS A POSITION. Both are the ruling: a stored
## graph would be the second source format `[CEUI-S32]` refused, and a stored position
## would be the second authority -- the one piece of graph state that could not be
## reconstructed from the outline, and so the one that would have to be migrated.
##
## Nodes are `{id, kind, label, card_id}` and edges are `{from, to, kind}`. A group node's
## id is derived from the author's own group name so that it, too, mints no identity.
func projection() -> Dictionary:
	if not _projection_enabled:
		return {}
	var nodes: Array[Dictionary] = []
	var edges: Array[Dictionary] = []
	var seen_groups: Dictionary = {}
	var previous_by_group: Dictionary = {}
	for entry in cards():
		var container_id := "%s|%s" % [String(entry["property"]), String(entry["group"])]
		if not seen_groups.has(container_id):
			seen_groups[container_id] = true
			var readable := String(entry["property"]).replace("_", " ").capitalize()
			var group := String(entry["group"])
			(
				nodes
				. append(
					{
						"id": container_id,
						"kind": NODE_GROUP,
						"label": readable if group == "" else "%s / %s" % [readable, group],
						"card_id": "",
					}
				)
			)
		var card_id := String(entry["id"])
		(
			nodes
			. append(
				{
					"id": card_id,
					"kind": NODE_CARD,
					"label": String(entry["summary"]),
					"card_id": card_id,
				}
			)
		)
		var previous := String(previous_by_group.get(container_id, ""))
		if previous == "":
			edges.append({"from": container_id, "to": card_id, "kind": EDGE_CONTAINS})
		else:
			edges.append({"from": previous, "to": card_id, "kind": EDGE_FOLLOWS})
		previous_by_group[container_id] = card_id
	return {"nodes": nodes, "edges": edges}


# ---- editing, all staged ----


## Repoints one card at another registered predicate. Refuses an id the vocabulary does not
## admit: the registry is OPEN, so anything registered is accepted, but an unregistered id
## would be a dangling reference of exactly the kind `[CEUI-S15]`'s picker exists to
## prevent.
func set_predicate(card_id: String, predicate_id: String) -> Dictionary:
	var entry := card(card_id)
	if entry.is_empty():
		return _refusal(NO_CARD_REASON if has_record() else NO_RECORD_REASON)
	if not predicate_options(String(entry["property"])).has(predicate_id):
		return _refusal(UNKNOWN_PREDICATE_REASON)
	var written := SubjectScript.with_field(
		_document, entry["subject"], String(entry["predicate_field"]), predicate_id
	)
	if not bool(written["accepted"]):
		return _refusal(String(written["reason"]))
	_document.stage(_record_id, String(written["property"]), written["value"])
	return {"applied": true, "reason": ""}


## Appends a card to the end of `property` (and, for the grouped shape, of `group`). Appends
## rather than inserts because the outline's order is the author's: a new condition goes
## where the author is looking, and `move_card()` is how it travels.
func add_card(property: String, group: String, predicate_id: String) -> Dictionary:
	if not has_record():
		return _refusal(NO_RECORD_REASON)
	var item_spec := SubjectScript.item_schema(_properties.get(property, null))
	var field := predicate_field(item_spec)
	if field == "":
		return _refusal(NOT_AN_OUTLINE_PROPERTY_REASON)
	if not predicate_options(property).has(predicate_id):
		return _refusal(UNKNOWN_PREDICATE_REASON)
	var staged: Variant = _with_entries(
		property,
		group,
		func(entries: Array) -> Array:
			entries.append({field: predicate_id})
			return entries
	)
	if staged == null:
		return _refusal(NOT_AN_OUTLINE_PROPERTY_REASON)
	_document.stage(_record_id, property, staged)
	return {"applied": true, "reason": ""}


## Removes one card. This CHANGES THE PROPERTY'S LENGTH, which is exactly the mutation
## `EditorSubject.re_derive()` drops a selection for -- so the caller's next
## `commit_active_edit()` lets go of any canvas or outline selection into this property,
## and that is correct: every index after the removed one now names a different condition.
func remove_card(card_id: String) -> Dictionary:
	var entry := card(card_id)
	if entry.is_empty():
		return _refusal(NO_CARD_REASON if has_record() else NO_RECORD_REASON)
	var index := int(entry["index"])
	var staged: Variant = _with_entries(
		String(entry["property"]),
		String(entry["group"]),
		func(entries: Array) -> Array:
			entries.remove_at(index)
			return entries
	)
	if staged == null:
		return _refusal(NO_CARD_REASON)
	_document.stage(_record_id, String(entry["property"]), staged)
	return {"applied": true, "reason": ""}


## Moves a card by `delta` places within its own group. `[CEUI-S32]` made the ORDER
## canonical data, so reordering is an authoring action rather than a view preference.
##
## IT RETURNS THE NEW CARD ID, AND CALLERS MUST FOLLOW IT. A move keeps the array's LENGTH,
## so `EditorSubject.re_derive()` -- which drops a selection when the length changed -- will
## KEEP a selection whose indices the move has just reassigned, and the author's selection
## would silently be of a different condition. Length is the right rule for insertion and
## deletion and it cannot see a permutation; rather than weaken it for everyone, the one
## operation that permutes says where its card went.
func move_card(card_id: String, delta: int) -> Dictionary:
	var entry := card(card_id)
	if entry.is_empty():
		return _refusal(NO_CARD_REASON if has_record() else NO_RECORD_REASON)
	var index := int(entry["index"])
	var target := index + delta
	var property := String(entry["property"])
	var group := String(entry["group"])
	var current: Variant = _entries_of(property, group)
	if not (current is Array):
		return _refusal(NO_CARD_REASON)
	if delta == 0 or target < 0 or target >= (current as Array).size():
		return _refusal(AT_EDGE_REASON)
	var staged: Variant = _with_entries(
		property,
		group,
		func(entries: Array) -> Array:
			var moved: Variant = entries[index]
			entries.remove_at(index)
			entries.insert(target, moved)
			return entries
	)
	if staged == null:
		return _refusal(NO_CARD_REASON)
	_document.stage(_record_id, property, staged)
	return {
		"applied": true,
		"reason": "",
		"id": SubjectScript.key(SubjectScript.for_item(_record_id, property, target, group)),
	}


# ---- internals ----


func _refusal(reason: String) -> Dictionary:
	return {"applied": false, "reason": reason}


func _cards_in(
	property: String, group: String, entries: Array, item_spec: Dictionary, field: String
) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for index in range(entries.size()):
		var item: Variant = entries[index]
		if not (item is Dictionary):
			continue
		var fields: Dictionary = item
		var subject := SubjectScript.for_item(_record_id, property, index, group)
		var predicate := String(fields.get(field, ""))
		(
			out
			. append(
				{
					"id": SubjectScript.key(subject),
					"subject": subject,
					"property": property,
					"group": group,
					"index": index,
					"position": index + 1,
					"predicate": predicate,
					"predicate_field": field,
					"summary": _summary(predicate, fields, field),
					"tiles": _tiles_of(fields, item_spec),
					"fields": fields.duplicate(true),
				}
			)
		)
	return out


## "Readable", per `[CEUI-S32]`: the predicate first, then whatever else the author set, in
## name order. No field is named here -- a card for a pack's own predicate reads the same
## way as one for `seize`, which is the point of deriving the outline instead of writing it.
func _summary(predicate: String, fields: Dictionary, predicate_field_name: String) -> String:
	var head := predicate.replace("_", " ").capitalize() if predicate != "" else "(no condition)"
	var names: Array = fields.keys()
	names.sort()
	var parts: Array[String] = []
	for name in names:
		if String(name) == predicate_field_name:
			continue
		var value: Variant = fields[name]
		if value == null or (value is Array and (value as Array).is_empty()):
			continue
		if value is String and String(value) == "":
			continue
		parts.append("%s %s" % [String(name).replace("_", " "), _readable(value)])
	return head if parts.is_empty() else "%s  -  %s" % [head, ", ".join(parts)]


func _readable(value: Variant) -> String:
	if value is Array:
		var rendered: Array[String] = []
		for element in value as Array:
			rendered.append(_readable(element))
		return "[%s]" % ", ".join(rendered)
	return str(value)


## The tiles a card links to, read through `EditorMapCanvas`'s own tile-field derivation so
## the outline and the canvas can never disagree about where a condition is. A condition
## with no tiles -- `rout`, `turn_limit` -- links to nothing, which is true of it.
func _tiles_of(fields: Dictionary, item_spec: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for name in CanvasScript.tile_fields(item_spec):
		var held: Variant = fields.get(name, null)
		if held == null:
			continue
		if held is Array and not (held as Array).is_empty() and (held as Array)[0] is Array:
			for element in held as Array:
				out.append(CanvasScript.as_tile(element))
			continue
		out.append(CanvasScript.as_tile(held))
	return out


func _entries_of(property: String, group: String) -> Variant:
	var held: Variant = _document.value(_record_id, property, null)
	if group == "":
		return held if held is Array else null
	if not (held is Dictionary):
		return null
	var entries: Variant = (held as Dictionary).get(group, null)
	return entries if entries is Array else null


## The WHOLE property value that results from `mutate` running over one group's entries,
## ready to stage as one cell. Duplicated before the write, for the reason
## `EditorSubject.with_field()` gives: `value()` resolves through the saved layer, and
## mutating what it returns would edit the saved record in place.
func _with_entries(property: String, group: String, mutate: Callable) -> Variant:
	if not _properties.has(property):
		return null
	var held: Variant = _document.value(_record_id, property, null)
	if group == "":
		var array: Array = (held as Array).duplicate(true) if held is Array else []
		return mutate.call(array)
	var groups: Dictionary = (held as Dictionary).duplicate(true) if held is Dictionary else {}
	var entries: Array = (
		(groups.get(group, []) as Array).duplicate(true) if groups.has(group) else []
	)
	groups[group] = mutate.call(entries)
	return groups
