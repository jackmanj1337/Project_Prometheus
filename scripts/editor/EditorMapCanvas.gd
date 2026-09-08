class_name EditorMapCanvas extends RefCounted
# `[CEUI-S31]`'s map canvas: what the Maps workspace DRAWS for one map record, and the
# tools that act on it. Headless state, like every other piece of the editor, so the
# rulings can be asserted without a viewport.
#
# WHAT THIS DOES NOT OWN. `CampaignEditorShell` already owns `[CEUI-S30]`'s layer list --
# `EntitySchemaRegistry.map_layers()` derives layers from `map_data` properties that
# declare `map_layer`, and per-layer visibility and lock are shell state with
# `LOCKED_LAYER_REASON` returned through `RecordSelector`. This is the canvas those toggles
# were built for. Hiding a layer changes what is DRAWN here and leaves the layer in the
# shell's list, which is the whole point of the two being separate: a layer that vanished
# from the list when hidden could not be shown again.
#
# THE TOOL SET IS DERIVED FROM THE ACTIVE LAYER, NOT DECLARED (`[CEUI-S31]`). It is
# `[CEUI-S21]`'s ruling one level down: a hand-written tool table keyed by layer id would
# be the closed enum the layer descriptor exists to avoid, and it would go stale the first
# time a pack authored a new spatial property. So a tool is derived from the SHAPE of the
# property's schema:
#
#   * an array of strings, one per grid row     -> PAINT     (one character per tile)
#   * an array of tiles                          -> MARK      (a tile is in the list or not)
#   * an array of objects carrying a tile        -> PLACE     (an object sits at a tile)
#   * an object of arrays of such objects        -> PLACE_IN  (the same, inside a named group)
#
# A LAYER OWNS A LIST OF PROPERTIES, SO A TOOL ACTS ON A PROPERTY, NOT ON A LAYER.
# `victory_conditions` and `defeat_conditions` are BOTH the objectives layer, and a tool
# set that assumed one property per layer would silently edit victory conditions when the
# author meant defeat conditions -- with every value correct and no error anywhere.
#
# EVERY EDIT IS A STAGED TRANSACTION. `apply_tool()` stages onto the open `EditorDocument`
# and commits nothing; the caller commits through `CampaignEditorShell.commit_active_edit()`
# so `[CEUI-S25]`'s incremental validation runs and `[CEUI-13]`'s Undo unit stays one
# author action. Writing to `records()` directly would bypass both.

## The four derived tool kinds. Names, not behaviour switches: what each one does comes from
## the property it was derived for.
const TOOL_PAINT := "paint"
const TOOL_MARK := "mark"
const TOOL_PLACE := "place"
const TOOL_PLACE_IN_GROUP := "place_in_group"

## Why a tool refuses on a locked layer. The shell's `LOCKED_LAYER_REASON` is about
## activating a layer in the LIST; this is the same refusal reached by pointing at the
## canvas, and `[EPUX-07]` wants the reason to reach whoever is standing on the surface
## rather than being swallowed.
const LOCKED_LAYER_REASON := "This layer is locked. Unlock it to edit it on the canvas."

## Why a tool refuses when nothing is open, or the tool does not belong to the active layer.
const NO_MAP_REASON := "Open a map to edit it."
const WRONG_LAYER_REASON := "That tool belongs to another layer. Activate its layer first."


## `true` for the `tile` schema -- an array of exactly two integers. Recognised by SHAPE
## rather than by the property being called `tile`, because that is what lets a pack's own
## spatial property get a tool with no editor edit.
static func is_tile_spec(spec: Variant) -> bool:
	if not (spec is Dictionary):
		return false
	var dict: Dictionary = spec
	if String(dict.get("type", "")) != "array":
		return false
	if int(dict.get("min_items", -1)) != 2 or int(dict.get("max_items", -1)) != 2:
		return false
	var items: Variant = dict.get("items", null)
	return items is Dictionary and String((items as Dictionary).get("type", "")) == "integer"


## The tile-carrying fields of an object schema, in name order: a single tile, and arrays of
## tiles (an objective's `tiles`). Both are how an object says where it is.
static func tile_fields(object_spec: Variant) -> Array[String]:
	var out: Array[String] = []
	if not (object_spec is Dictionary):
		return out
	var properties: Variant = (object_spec as Dictionary).get("properties", null)
	if not (properties is Dictionary):
		return out
	var names: Array = (properties as Dictionary).keys()
	names.sort()
	for name in names:
		var spec: Variant = (properties as Dictionary)[name]
		if is_tile_spec(spec):
			out.append(String(name))
			continue
		if (
			spec is Dictionary
			and String((spec as Dictionary).get("type", "")) == "array"
			and is_tile_spec((spec as Dictionary).get("items", null))
		):
			out.append(String(name))
	return out


## `[CEUI-S31]`. One tool per PROPERTY of the layer, derived from that property's schema
## shape. A property with nothing spatial in it yields no tool rather than a disabled one:
## it is not a refusal the author can act on, it is a property that is not on the map.
static func tools_for_layer(layer: Dictionary, map_properties: Dictionary) -> Array[Dictionary]:
	var tools: Array[Dictionary] = []
	var layer_id := String(layer.get("id", ""))
	for property_name in layer.get("properties", []) as Array:
		var name := String(property_name)
		if not map_properties.has(name):
			continue
		var spec: Variant = map_properties[name]
		var kind := _tool_kind_for(spec)
		if kind == "":
			continue
		(
			tools
			. append(
				{
					"id": "%s:%s" % [layer_id, name],
					"layer": layer_id,
					"property": name,
					"kind": kind,
					"label": _tool_label(kind, name),
				}
			)
		)
	return tools


static func _tool_kind_for(spec: Variant) -> String:
	if not (spec is Dictionary):
		return ""
	var dict: Dictionary = spec
	var type := String(dict.get("type", ""))
	if type == "array":
		var items: Variant = dict.get("items", null)
		if is_tile_spec(items):
			return TOOL_MARK
		if items is Dictionary:
			var item_type := String((items as Dictionary).get("type", ""))
			if item_type == "string":
				return TOOL_PAINT
			if item_type == "object" and not tile_fields(items).is_empty():
				return TOOL_PLACE
		return ""
	if type == "object":
		var additional: Variant = dict.get("additional_properties", null)
		if (
			additional is Dictionary
			and String((additional as Dictionary).get("type", "")) == "array"
			and not tile_fields((additional as Dictionary).get("items", null)).is_empty()
		):
			return TOOL_PLACE_IN_GROUP
	return ""


## Author-facing, and it names the PROPERTY rather than the layer, for the same reason the
## tools are per-property: on the objectives layer "Place" twice would be two identical
## buttons that do different things.
static func _tool_label(kind: String, property_name: String) -> String:
	var readable := property_name.replace("_", " ").capitalize()
	match kind:
		TOOL_PAINT:
			return "Paint %s" % readable
		TOOL_MARK:
			return "Mark %s" % readable
		TOOL_PLACE_IN_GROUP:
			return "Place %s in a group" % readable
		_:
			return "Place %s" % readable


var _document: EditorDocument = null
var _record_id: String = ""
# The shell's `layer_rows()`, carried rather than re-derived: visibility and lock are the
# shell's state and a second copy is how two surfaces start disagreeing about what is shown.
var _layers: Array[Dictionary] = []
var _map_properties: Dictionary = {}
var _active_layer: String = ""
# Canvas selection, as `{property, index, group, tile}` references into the map record.
var _selection: Array[Dictionary] = []


## Points the canvas at one record of an open map document. `layers` is
## `CampaignEditorShell.layer_rows()`; `map_properties` is the `map_data` schema's
## `properties`, which is where every tool derivation reads from.
func set_map(
	document: EditorDocument,
	record_id: String,
	layers: Array[Dictionary],
	map_properties: Dictionary
) -> void:
	# Re-pointing the canvas at the SAME record is a refresh, not a new map, so the
	# selection survives it. It must: every commit refreshes the surface, and a selection
	# that cleared itself there could never be the `[CEUI-S23]` subject of the edit that
	# follows. Pointing at a different record (or a different document) is a new map and
	# the old addresses mean nothing in it.
	var same_map := _document == document and _record_id == record_id
	_document = document
	_record_id = record_id
	_layers = layers.duplicate(true)
	_map_properties = map_properties
	if not same_map:
		_selection.clear()
	if _active_layer == "" or not _has_layer(_active_layer):
		_active_layer = String(_layers[0]["id"]) if not _layers.is_empty() else ""


func has_map() -> bool:
	return _document != null and _record_id != "" and _document.has_record(_record_id)


func active_layer() -> String:
	return _active_layer


## Refuses a layer the shell does not have. A LOCKED layer is still activatable here --
## locking is a refusal to EDIT, and `[CEUI-S30]` kept a locked layer focusable so an author
## can look at what it holds without unlocking it. The refusal lands in `apply_tool()`.
func set_active_layer(layer_id: String) -> bool:
	if not _has_layer(layer_id):
		return false
	_active_layer = layer_id
	return true


## `[CEUI-S31]`: derived from the ACTIVE layer, every time. Nothing caches a tool table.
func active_tools() -> Array[Dictionary]:
	for layer in _layers:
		if String(layer["id"]) == _active_layer:
			return tools_for_layer(layer, _map_properties)
	return [] as Array[Dictionary]


## The grid's dimensions in tiles, from the authored rows. Zero when nothing is open, which
## reads as "nothing to draw" rather than as a one-by-one map.
func grid_size() -> Vector2i:
	var rows := _grid_rows()
	if rows.is_empty():
		return Vector2i.ZERO
	var width := 0
	for row in rows:
		width = maxi(width, String(row).length())
	return Vector2i(width, rows.size())


## What the canvas draws: the grid, and one entry per VISIBLE layer carrying the marks that
## layer puts on tiles. A hidden layer is absent from here and present in the shell's list.
##
## Marks carry the property they came from and their index in it, because that is the
## address an edit needs -- a mark that knew only its tile could not be moved back into the
## right one of a layer's two properties.
func draw_model() -> Dictionary:
	var model := {"size": grid_size(), "rows": _grid_rows(), "layers": [] as Array[Dictionary]}
	if not has_map():
		return model
	for layer in _layers:
		if not bool(layer.get("visible", true)):
			continue
		var entry := {
			"id": String(layer["id"]),
			"label": String(layer.get("label", layer["id"])),
			"locked": bool(layer.get("locked", false)),
			"marks": [] as Array[Dictionary],
		}
		for property_name in layer.get("properties", []) as Array:
			(entry["marks"] as Array[Dictionary]).append_array(_marks_for(String(property_name)))
		(model["layers"] as Array[Dictionary]).append(entry)
	return model


## Every mark currently on `tile`, across visible layers only -- an author cannot select
## what they cannot see, and a canvas that returned hidden marks would let a hidden layer be
## edited through a tile click.
func marks_at(tile: Vector2i) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for layer in draw_model()["layers"] as Array[Dictionary]:
		for mark in layer["marks"] as Array[Dictionary]:
			if mark["tile"] == tile:
				var hit: Dictionary = mark.duplicate(true)
				hit["layer"] = String(layer["id"])
				out.append(hit)
	return out


## `[CEUI-S23]`: a selection made on the canvas is a selection, and a MULTI selection is the
## bulk table's -- the canvas does not grow a second multi-edit surface of its own. This
## publishes the selection; routing it is the shell's, exactly as it is for the record list.
func select_tile(tile: Vector2i, additive: bool = false) -> Array[Dictionary]:
	if not additive:
		_selection.clear()
	for mark in marks_at(tile):
		if not _selection.has(mark):
			_selection.append(mark)
	return selection()


func clear_selection() -> void:
	_selection.clear()


func selection() -> Array[Dictionary]:
	return _selection.duplicate(true)


func selection_is_multi() -> bool:
	return _selection.size() > 1


# ---- editing ----


## Stages one tool application onto the open document and COMMITS NOTHING. The caller
## commits through `CampaignEditorShell.commit_active_edit()`, which is the one place a
## document's remembered validator runs; a canvas that committed here would either skip
## `[CEUI-S25]`'s pass or run a second one the panel could not attribute.
##
## Returns `{"applied": bool, "reason": String}` -- a refusal always carries its reason,
## because a tool that silently does nothing on a locked layer is indistinguishable from a
## tool that is broken.
func apply_tool(tool_id: String, tile: Vector2i, value: Variant = null) -> Dictionary:
	if not has_map():
		return {"applied": false, "reason": NO_MAP_REASON}
	var tool: Dictionary = {}
	for candidate in active_tools():
		if String(candidate["id"]) == tool_id:
			tool = candidate
			break
	if tool.is_empty():
		return {"applied": false, "reason": WRONG_LAYER_REASON}
	if _is_locked(String(tool["layer"])):
		return {"applied": false, "reason": LOCKED_LAYER_REASON}

	var property_name := String(tool["property"])
	var current: Variant = _document.value(_record_id, property_name, null)
	var staged: Variant = null
	match String(tool["kind"]):
		TOOL_PAINT:
			staged = _painted_rows(current, tile, value)
		TOOL_MARK:
			staged = _toggled_tile(current, tile)
		TOOL_PLACE:
			staged = _placed_object(property_name, current, tile, value)
		TOOL_PLACE_IN_GROUP:
			staged = _placed_in_group(property_name, current, tile, value)
	if staged == null:
		return {"applied": false, "reason": WRONG_LAYER_REASON}
	_document.stage(_record_id, property_name, staged)
	return {"applied": true, "reason": ""}


## Paints one character. Out-of-bounds is a refusal by returning null rather than growing
## the grid: the grid's size is authored, and a paint that resized it would be a different
## edit wearing a paint tool's clothes.
func _painted_rows(current: Variant, tile: Vector2i, value: Variant) -> Variant:
	if not (current is Array):
		return null
	var rows: Array = (current as Array).duplicate(true)
	if tile.y < 0 or tile.y >= rows.size():
		return null
	var row := String(rows[tile.y])
	if tile.x < 0 or tile.x >= row.length():
		return null
	var glyph := String(value)
	if glyph.length() != 1:
		return null
	rows[tile.y] = row.substr(0, tile.x) + glyph + row.substr(tile.x + 1)
	return rows


## A tile is in the list or it is not, so the tool toggles rather than always adding -- a
## mark tool that only added would need a second eraser tool nothing derives.
func _toggled_tile(current: Variant, tile: Vector2i) -> Variant:
	var tiles: Array = (current as Array).duplicate(true) if current is Array else []
	var wanted := [tile.x, tile.y]
	for index in range(tiles.size()):
		if as_tile(tiles[index]) == tile:
			tiles.remove_at(index)
			return tiles
	tiles.append(wanted)
	return tiles


## Places `value` (an authored object) at `tile`, or MOVES the object already selected there
## when no value is given. The PROPERTY is passed in from the tool, never derived from the
## active layer: `victory_conditions` and `defeat_conditions` are both the objectives layer,
## and a helper that took "the layer's property" would edit the wrong one of the two with
## every value correct and no error anywhere. Both are the same edit to the same property, which is why they
## are one tool rather than a place tool and a move tool that could disagree.
func _placed_object(
	property_name: String, current: Variant, tile: Vector2i, value: Variant
) -> Variant:
	var items: Array = (current as Array).duplicate(true) if current is Array else []
	var fields := tile_fields(_item_spec(_map_properties.get(property_name, {})))
	if fields.is_empty():
		return null
	var field := fields[0]
	if value is Dictionary:
		var placed: Dictionary = (value as Dictionary).duplicate(true)
		placed[field] = [tile.x, tile.y]
		items.append(placed)
		return items
	for entry in _selection:
		if String(entry.get("property", "")) != property_name:
			continue
		var index := int(entry.get("index", -1))
		if index < 0 or index >= items.size() or not (items[index] is Dictionary):
			continue
		var moved: Dictionary = (items[index] as Dictionary).duplicate(true)
		moved[field] = [tile.x, tile.y]
		items[index] = moved
		return items
	return null


## The grouped shape: an object whose keys are author-defined group names. The group comes
## from `value["group"]`, because the names are the author's and nothing here may invent one.
func _placed_in_group(
	property_name: String, current: Variant, tile: Vector2i, value: Variant
) -> Variant:
	if not (value is Dictionary):
		return null
	var payload: Dictionary = value
	var group := String(payload.get("group", ""))
	if group == "":
		return null
	var groups: Dictionary = (
		(current as Dictionary).duplicate(true) if current is Dictionary else {}
	)
	var entries: Array = (
		(groups.get(group, []) as Array).duplicate(true) if groups.has(group) else []
	)
	var spec: Dictionary = _map_properties.get(property_name, {})
	var fields := tile_fields(
		(spec.get("additional_properties", {}) as Dictionary).get("items", null)
	)
	if fields.is_empty():
		return null
	var entry: Dictionary = (payload.get("entry", {}) as Dictionary).duplicate(true)
	entry[fields[0]] = [tile.x, tile.y]
	entries.append(entry)
	groups[group] = entries
	return groups


# ---- reading the record ----


func _grid_rows() -> Array:
	if not has_map():
		return []
	var grid: Variant = _document.value(_record_id, "grid", null)
	return grid if grid is Array else []


## Marks for one property, derived from its schema shape the same way its tool was. A
## property the schema does not describe yields nothing rather than a guess.
func _marks_for(property_name: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not _map_properties.has(property_name):
		return out
	var spec: Variant = _map_properties[property_name]
	var kind := _tool_kind_for(spec)
	var current: Variant = _document.value(_record_id, property_name, null)
	match kind:
		TOOL_MARK:
			if current is Array:
				for index in range((current as Array).size()):
					(
						out
						. append(
							{
								"property": property_name,
								"index": index,
								"group": "",
								"tile": as_tile((current as Array)[index]),
							}
						)
					)
		TOOL_PLACE:
			var fields := tile_fields(_item_spec(spec))
			if current is Array and not fields.is_empty():
				for index in range((current as Array).size()):
					var item: Variant = (current as Array)[index]
					if item is Dictionary:
						(
							out
							. append(
								{
									"property": property_name,
									"index": index,
									"group": "",
									"tile": as_tile((item as Dictionary).get(fields[0], null)),
								}
							)
						)
		TOOL_PLACE_IN_GROUP:
			var item_spec: Variant = (spec as Dictionary).get("additional_properties", {})
			var group_fields := tile_fields((item_spec as Dictionary).get("items", null))
			if current is Dictionary and not group_fields.is_empty():
				var group_names: Array = (current as Dictionary).keys()
				group_names.sort()
				for group in group_names:
					var entries: Variant = (current as Dictionary)[group]
					if not (entries is Array):
						continue
					for index in range((entries as Array).size()):
						var entry: Variant = (entries as Array)[index]
						if not (entry is Dictionary):
							continue
						var located: Variant = (entry as Dictionary).get(group_fields[0], null)
						if located == null:
							continue
						(
							out
							. append(
								{
									"property": property_name,
									"index": index,
									"group": String(group),
									"tile": as_tile(located),
								}
							)
						)
		_:
			pass
	return out


func _item_spec(spec: Variant) -> Variant:
	return (spec as Dictionary).get("items", null) if spec is Dictionary else null


## Reads a tile from whatever the record holds. An array of tiles (an objective's `tiles`)
## reports its FIRST, so a condition covering several tiles still has somewhere to draw.
static func as_tile(value: Variant) -> Vector2i:
	if not (value is Array) or (value as Array).is_empty():
		return Vector2i(-1, -1)
	var array: Array = value
	if array[0] is Array:
		return as_tile(array[0])
	if array.size() < 2:
		return Vector2i(-1, -1)
	return Vector2i(int(array[0]), int(array[1]))


func _has_layer(layer_id: String) -> bool:
	for layer in _layers:
		if String(layer["id"]) == layer_id:
			return true
	return false


func _is_locked(layer_id: String) -> bool:
	for layer in _layers:
		if String(layer["id"]) == layer_id:
			return bool(layer.get("locked", false))
	return false
