class_name EditorCampaignGraph extends RefCounted
# `[CEUI-S32]`'s campaign-structure graph. Unlike the objective outline, this graph is
# the canonical presentation of authored campaign nodes and their `next` edges. The model
# owns no new ids, edges, or positions: every value is derived from the campaign record so
# the graph can never drift from the JSON the author will save.

const SubjectScript = preload("res://scripts/editor/EditorSubject.gd")

const NO_RECORD_REASON := "Open a campaign record to inspect its structure graph."
const INVALID_NODE_REASON := "A campaign node is missing its authored node_id."

var _document: EditorDocument = null
var _record_id := ""


func set_record(document: EditorDocument, record_id: String) -> void:
	_document = document
	_record_id = record_id


func has_record() -> bool:
	return (
		_document != null
		and _record_id != ""
		and _document.has_record(_record_id)
		and _document.kind == "campaign"
	)


func start_node_id() -> String:
	if not has_record():
		return ""
	return String(_document.value(_record_id, "start_node_id", ""))


## Returns the canonical nodes in authored array order. `position` is a derived view hint;
## it is intentionally absent from the authored record and is recomputed every call.
func nodes() -> Array[Dictionary]:
	var graph := structure()
	return graph.get("nodes", []) as Array[Dictionary]


## Returns `{start_node_id, nodes, edges}`. A malformed successor is retained as an edge and
## marked `known=false`, so the editor shows the author's actual data instead of repairing it.
func structure() -> Dictionary:
	if not has_record():
		return {}
	var raw_nodes: Variant = _document.value(_record_id, "nodes", [])
	if not raw_nodes is Array:
		return {"start_node_id": start_node_id(), "nodes": [], "edges": []}
	var authored: Array = raw_nodes
	var ids: Array[String] = []
	var by_id: Dictionary = {}
	for index in range(authored.size()):
		var raw: Variant = authored[index]
		var node: Dictionary = raw as Dictionary if raw is Dictionary else {}
		var node_id := String(node.get("node_id", ""))
		ids.append(node_id)
		if node_id != "":
			by_id[node_id] = index

	var levels := _levels(authored, ids, by_id)
	var max_reachable_level := 0
	for level in levels:
		max_reachable_level = maxi(max_reachable_level, int(level))
	var columns: Dictionary = {}
	var result_nodes: Array[Dictionary] = []
	for index in range(authored.size()):
		var raw: Variant = authored[index]
		var authored_node: Dictionary = raw as Dictionary if raw is Dictionary else {}
		var node_id := ids[index]
		var level := int(levels[index])
		var display_level := level if level >= 0 else max_reachable_level + 1
		var column := int(columns.get(level, 0))
		columns[level] = column + 1
		(
			result_nodes
			. append(
				{
					"id": node_id,
					"label": String(authored_node.get("label", node_id)),
					"map_id": String(authored_node.get("map_id", "")),
					"next": _string_array(authored_node.get("next", [])),
					"index": index,
					"is_start": node_id != "" and node_id == start_node_id(),
					"reachable_from_start": level >= 0,
					"level": level,
					"position": Vector2(32.0 + column * 260.0, 32.0 + display_level * 128.0),
					"subject": SubjectScript.for_item(_record_id, "nodes", index),
				}
			)
		)

	var edges: Array[Dictionary] = []
	for index in range(authored.size()):
		var authored_node: Dictionary = (
			authored[index] as Dictionary if authored[index] is Dictionary else {}
		)
		var from_id := ids[index]
		for successor in _string_array(authored_node.get("next", [])):
			(
				edges
				. append(
					{
						"from": from_id,
						"to": successor,
						"known": by_id.has(successor),
					}
				)
			)
	return {"start_node_id": start_node_id(), "nodes": result_nodes, "edges": edges}


func node(node_id: String) -> Dictionary:
	for entry in nodes():
		if String(entry["id"]) == node_id:
			return entry
	return {}


func subjects_for(node_ids: Array) -> Array[Dictionary]:
	var wanted: Dictionary = {}
	for node_id in node_ids:
		wanted[String(node_id)] = true
	var out: Array[Dictionary] = []
	for entry in nodes():
		if wanted.has(String(entry["id"])):
			out.append((entry["subject"] as Dictionary).duplicate(true))
	return out


func validation_rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not has_record():
		return out
	var graph := structure()
	var ids: Dictionary = {}
	for entry in graph["nodes"] as Array[Dictionary]:
		var node_id := String(entry["id"])
		if node_id == "":
			out.append({"index": int(entry["index"]), "reason": INVALID_NODE_REASON})
		else:
			ids[node_id] = true
	if start_node_id() != "" and not ids.has(start_node_id()):
		out.append({"index": -1, "reason": "The campaign start node is not present in nodes[]."})
	for edge in graph["edges"] as Array[Dictionary]:
		if not bool(edge["known"]):
			(
				out
				. append(
					{
						"index": -1,
						"reason":
						(
							"Node '%s' points to unknown successor '%s'."
							% [String(edge["from"]), String(edge["to"])]
						),
					}
				)
			)
	return out


func _levels(authored: Array, ids: Array[String], by_id: Dictionary) -> Array[int]:
	var levels: Array[int] = []
	levels.resize(authored.size())
	for index in range(levels.size()):
		levels[index] = -1
	var start: Variant = by_id.get(start_node_id(), -1)
	if start is int and int(start) >= 0:
		levels[int(start)] = 0
		var queue: Array[int] = [int(start)]
		var cursor := 0
		while cursor < queue.size():
			var current := queue[cursor]
			cursor += 1
			var current_node: Dictionary = (
				authored[current] as Dictionary if authored[current] is Dictionary else {}
			)
			for successor in _string_array(current_node.get("next", [])):
				var target: Variant = by_id.get(successor, -1)
				if target is int and int(target) >= 0 and levels[int(target)] < 0:
					levels[int(target)] = levels[current] + 1
					queue.append(int(target))
	return levels


func _string_array(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for entry in value as Array:
			out.append(String(entry))
	return out
