class_name CampaignEditorShell extends RefCounted
# The campaign editor shell's state, and the ADOPTER for `ContentTreeDescriptor` and
# `RecordSelector` (`EDITOR-SHELL-TREE-V1-2026-09-07`). `[CEUI-1]`'s left tree and
# `[CEUI-S30]`'s map layer list, both as state a headless test can assert.
#
# WHY A MODEL AND NOT THE SCREEN. The same argument `RecordSelector` and `ResponsiveLayout`
# both made: every rule these two rulings state is about STATE -- what categories exist,
# what order they are in, which layer is focused, what a locked layer does when activated.
# A Control cannot be asserted headlessly, and `CampaignEditorScreen` is then a renderer
# with no decisions of its own to get wrong.
#
# THIS FILE NAMES NO CONTENT FAMILY, AND NEITHER MAY ITS CALLERS. `[CEUI-S21]` rejected
# hand-coded categories because adding a content family would then mean editing the
# editor. `ContentTreeDescriptor` is deliberately the only thing that knows what families
# exist; a category list here -- or a `match` on a category id in the screen -- would undo
# the ruling the descriptor implements. The groups the tree draws are DERIVED from the
# categories the descriptor returned, which is why `groups()` builds them by walking the
# descriptor's output rather than declaring a group table.
#
# WHY NO LIVE CATALOGUE IS PASSED BY DEFAULT. `build()` takes an optional `RegistryCatalog`
# and the shell leaves it null unless a caller supplies one. `[CEUI-S13]` makes the editor
# reachable only where no campaign is active, so `RegistryManager`'s live catalogue would
# hold the engine baseline rather than pack content; the catalogue worth showing is the
# WORKING COPY's, and the working copy arrives with the document model in a later slice.
# The argument is kept open so that slice supplies one without touching this file.
#
# LAYER VISIBILITY IS NOT A `RecordSelector` GATE, AND LOCK IS. Both come from `CEUI-23`
# option A -- "named layers with per-layer visibility and lock" -- and they are different
# kinds of thing. Hiding a layer is the author changing what the CANVAS draws; the layer
# stays in the list, because a layer that vanished from the list when hidden could not be
# shown again. Locking a layer is a refusal to edit it, which is exactly the
# focusable-but-not-activatable shape `[EPUX-07]` ruled, so lock goes through the
# selector's availability provider and `activate()` returns the reason.

const DescriptorScript = preload("res://scripts/editor/ContentTreeDescriptor.gd")

## Why `activate()` refuses on a locked layer. Author-facing, because `RecordSelector`
## hands whatever it is given straight to the surface that displays it.
const LOCKED_LAYER_REASON := "This layer is locked. Unlock it to edit."

var _content := RecordSelector.new()
var _layers := RecordSelector.new()
# layer id -> bool. Absent means the default: visible, unlocked.
var _layer_visible: Dictionary = {}
var _layer_locked: Dictionary = {}


func _init() -> void:
	_layers.availability_provider = _layer_availability
	# The descriptor has already sorted both lists into display order, and neither
	# selector may re-sort them: the order IS the ruling's authored output.
	refresh()


## Rebuilds both lists from the descriptor. Both arguments are the descriptor's own, passed
## through unread -- see the header on why the catalogue is usually absent.
func refresh(schemas: EntitySchemaRegistry = null, catalogue: RegistryCatalog = null) -> void:
	var categories := DescriptorScript.build(schemas, catalogue)
	var content_records: Array = []
	for category in categories:
		content_records.append({"id": String(category["id"]), "payload": category})
	_content.set_records(content_records)

	var layer_records: Array = []
	for layer in DescriptorScript.map_layers(schemas):
		layer_records.append({"id": String(layer["id"]), "payload": layer})
	_layers.set_records(layer_records)
	for id in _layer_visible.keys().duplicate():
		if not _layers.has(String(id)):
			_layer_visible.erase(id)
	for id in _layer_locked.keys().duplicate():
		if not _layers.has(String(id)):
			_layer_locked.erase(id)
	_layers.refresh()


# ---- the `[CEUI-1]` left tree ----


## `[CEUI-S15]`'s selector, over the tree's categories. Exposed rather than wrapped: the
## screen needs focus, selection and activation, and a wrapper would be a second selector
## vocabulary for the surface the ruling exists to keep singular.
func content_selector() -> RecordSelector:
	return _content


## The tree's top level, DERIVED from the categories rather than declared. A group exists
## because a category claimed it, it is labelled from its own id, and it sorts by the
## `group_order` its members carry -- so a content family that introduces a new group gets
## one with no edit here, which is the whole of `[CEUI-S21]` applied to the level above
## categories.
##
## `{id, label, order, category_ids}`, in display order.
func groups() -> Array[Dictionary]:
	var by_id: Dictionary = {}
	var order: Array[String] = []
	for row in _content.rows():
		var category: Dictionary = row["payload"]
		var group_id := String(category["group"])
		if not by_id.has(group_id):
			by_id[group_id] = {
				"id": group_id,
				"label": DescriptorScript.fallback_label(group_id),
				"order": int(category["group_order"]),
				"category_ids": [] as Array[String],
			}
			order.append(group_id)
		(by_id[group_id]["category_ids"] as Array[String]).append(String(row["id"]))
	var out: Array[Dictionary] = []
	for group_id in order:
		out.append(by_id[group_id])
	return out


## The focused category's descriptor entry, or `{}` when the tree is empty.
func focused_category() -> Dictionary:
	var row := _content.row(_content.focused_id())
	if row.is_empty():
		return {}
	return row["payload"]


# ---- the `[CEUI-S30]` map layer list ----


func layer_selector() -> RecordSelector:
	return _layers


## `{id, label, order, properties, visible, locked}` per layer, in the schema's order. The
## first four are the descriptor's; the last two are this shell's, because visibility and
## lock are editor session state and not part of the map document.
func layer_rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row in _layers.rows():
		var layer: Dictionary = (row["payload"] as Dictionary).duplicate(true)
		layer["visible"] = is_layer_visible(String(row["id"]))
		layer["locked"] = is_layer_locked(String(row["id"]))
		out.append(layer)
	return out


func is_layer_visible(id: String) -> bool:
	return bool(_layer_visible.get(id, true))


func is_layer_locked(id: String) -> bool:
	return bool(_layer_locked.get(id, false))


## Returns false for a layer the schema does not declare. Hiding a layer never removes it
## from the list -- see the header.
func set_layer_visible(id: String, visible: bool) -> bool:
	if not _layers.has(id):
		return false
	_layer_visible[id] = visible
	return true


## Locking re-runs availability, so the selector drops the layer from its selection if it
## was selected. Focus is deliberately untouched: `[EPUX-07]` keeps a gated entry
## focusable, and locking the layer someone is standing on must not move them.
func set_layer_locked(id: String, locked: bool) -> bool:
	if not _layers.has(id):
		return false
	_layer_locked[id] = locked
	_layers.refresh()
	return true


# ---- `[TSV-24]` state across recomposition ----


## Everything that must survive a resize, a density change or an input-mode change: both
## selectors' state, plus the per-layer visibility and lock the author set. Keyed by id
## throughout, because the descriptor's output is re-derived on every rebuild.
func capture_state() -> Dictionary:
	return {
		"content": _content.capture_state(),
		"layers": _layers.capture_state(),
		"layer_visible": _layer_visible.duplicate(true),
		"layer_locked": _layer_locked.duplicate(true),
	}


func restore_state(state: Dictionary) -> void:
	_layer_visible.clear()
	for id in (state.get("layer_visible", {}) as Dictionary).keys():
		if _layers.has(String(id)):
			_layer_visible[String(id)] = bool((state["layer_visible"] as Dictionary)[id])
	_layer_locked.clear()
	for id in (state.get("layer_locked", {}) as Dictionary).keys():
		if _layers.has(String(id)):
			_layer_locked[String(id)] = bool((state["layer_locked"] as Dictionary)[id])
	_layers.refresh()
	_content.restore_state(state.get("content", {}))
	_layers.restore_state(state.get("layers", {}))


func _layer_availability(id: String, _payload: Variant) -> Dictionary:
	if not is_layer_locked(id):
		return {"available": true, "reason": ""}
	# `GATE_VISIBLE_DISABLED` rather than hidden, explicitly: a locked layer the author
	# cannot see is a layer they cannot unlock.
	return {
		"available": false,
		"reason": LOCKED_LAYER_REASON,
		"gate": RecordSelector.GATE_VISIBLE_DISABLED,
	}
