extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_editor_campaign_graph.gd
#
# Covers the canonical campaign structure graph separately from the objective outline:
# authored node order and successors remain authoritative, layout is derived, and the
# graph's node selections use the ordinary EditorSubject address.

const GraphScript = preload("res://scripts/editor/EditorCampaignGraph.gd")
const DocumentScript = preload("res://scripts/editor/EditorDocument.gd")
const WorkspacesScript = preload("res://scripts/editor/EditorWorkspaces.gd")
const SchemasScript = preload("res://scripts/data/EntitySchemaRegistry.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Editor Campaign Graph Test ===")
	_the_graph_preserves_authored_nodes_and_edges()
	_layout_is_derived_from_the_start_node()
	_unreachable_nodes_remain_unreachable_in_the_view()
	_selection_uses_the_existing_item_address()
	_malformed_successors_are_shown_not_repaired()
	await _the_campaign_document_uses_the_canonical_graph_surface()
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % label)
	else:
		_failed += 1
		print("  FAIL: %s%s" % [label, ("  [%s]" % detail) if detail != "" else ""])


func _campaign_record() -> Dictionary:
	return {
		"kind": "campaign",
		"schema_version": 1,
		"id": "branching_skirmish",
		"campaign_id": "branching_skirmish",
		"label": "Branching Skirmish",
		"author_id": "test_author",
		"campaign_version": "1.0.0",
		"start_node_id": "crossroads",
		"nodes":
		[
			{
				"node_id": "crossroads",
				"label": "Chapter 1 - The Crossroads",
				"map_id": "skirmish_01",
				"next": ["river_pass", "ridge_pass"],
			},
			{
				"node_id": "river_pass",
				"label": "Chapter 2 - River Pass",
				"map_id": "skirmish_02",
				"next": [],
			},
			{
				"node_id": "ridge_pass",
				"label": "Chapter 2 - Ridge Pass",
				"map_id": "skirmish_03",
				"next": [],
			},
		],
	}


func _document(record: Dictionary = {}) -> EditorDocument:
	if record.is_empty():
		record = _campaign_record()
	return DocumentScript.open("campaigns", "campaign", {String(record["id"]): record}, "Campaigns")


func _graph(record: Dictionary = {}) -> EditorCampaignGraph:
	if record.is_empty():
		record = _campaign_record()
	var graph := GraphScript.new()
	graph.set_record(_document(record), String(record["id"]))
	return graph


func _the_graph_preserves_authored_nodes_and_edges() -> void:
	print("\n-- authored campaign nodes and successor edges are canonical --")
	var structure := _graph().structure()
	var nodes: Array[Dictionary] = structure["nodes"]
	var edges: Array[Dictionary] = structure["edges"]
	_check(
		"the three authored nodes remain in array order",
		(
			[nodes[0]["id"], nodes[1]["id"], nodes[2]["id"]]
			== ["crossroads", "river_pass", "ridge_pass"]
		)
	)
	_check(
		"the authored start node is retained", String(structure["start_node_id"]) == "crossroads"
	)
	_check("the branch has exactly two authored successors", edges.size() == 2)
	_check(
		"successor order is retained",
		String(edges[0]["to"]) == "river_pass" and String(edges[1]["to"]) == "ridge_pass"
	)
	_check("nodes do not gain a second authored edge table", not nodes[0].has("edges"))


func _layout_is_derived_from_the_start_node() -> void:
	print("\n-- layout is derived from graph reachability --")
	var nodes: Array[Dictionary] = _graph().nodes()
	_check("the start node is level zero", int(nodes[0]["level"]) == 0)
	_check(
		"both successors are on the next level",
		int(nodes[1]["level"]) == 1 and int(nodes[2]["level"]) == 1
	)
	_check(
		"branch siblings receive distinct derived positions",
		nodes[1]["position"] != nodes[2]["position"]
	)
	var before := _graph().structure()
	var after := _graph().structure()
	_check("rebuilding produces the same derived layout", before["nodes"] == after["nodes"])


func _unreachable_nodes_remain_unreachable_in_the_view() -> void:
	print("\n-- disconnected campaign nodes remain visibly unreachable --")
	var record := _campaign_record()
	(record["nodes"] as Array).append(
		{"node_id": "orphan", "label": "Orphan", "map_id": "orphan_map", "next": []}
	)
	var graph := _graph(record)
	var orphan := graph.node("orphan")
	_check("the disconnected node is retained", not orphan.is_empty())
	_check(
		"the disconnected node is not marked reachable", not bool(orphan["reachable_from_start"])
	)
	_check(
		"the disconnected node is laid out after reachable levels",
		float((orphan["position"] as Vector2).y) > 160.0,
		str(orphan["position"])
	)


func _selection_uses_the_existing_item_address() -> void:
	print("\n-- graph node selection uses EditorSubject --")
	var graph := _graph()
	var subjects := graph.subjects_for(["river_pass"])
	_check("one subject is published", subjects.size() == 1)
	_check("the subject addresses campaign nodes", String(subjects[0]["property"]) == "nodes")
	_check("the subject keeps the authored array index", int(subjects[0]["index"]) == 1)
	_check(
		"the subject points at the campaign record",
		String(subjects[0]["record_id"]) == "branching_skirmish"
	)


func _malformed_successors_are_shown_not_repaired() -> void:
	print("\n-- malformed successors remain visible --")
	var record := _campaign_record()
	(record["nodes"] as Array)[0]["next"] = ["missing_node"]
	var graph := _graph(record)
	var edge: Dictionary = graph.structure()["edges"][0]
	_check("the unknown successor remains an edge", String(edge["to"]) == "missing_node")
	_check("the edge is marked unknown", not bool(edge["known"]))
	_check("the graph reports the validation problem", graph.validation_rows().size() == 1)


func _the_campaign_document_uses_the_canonical_graph_surface() -> void:
	print("\n-- the campaign document uses the canonical Graph workspace surface --")
	var packed: PackedScene = load("res://scenes/ui/CampaignEditorScreen.tscn")
	var screen: Node = packed.instantiate()
	root.add_child(screen)
	await process_frame
	var shell = screen.call("shell")
	shell.set_schemas(SchemasScript.with_core_schemas())
	var record := _campaign_record()
	shell.open_document("campaigns", "campaign", {"branching_skirmish": record}, "Campaigns")
	shell.record_selector().focus("branching_skirmish")
	shell.workspaces().activate(WorkspacesScript.GRAPH)
	_screen_rebuild(screen)
	await process_frame
	var campaign_panel: Control = screen.get_node(
		"Shell/Body/Workspace/Centre/DocumentColumns/Document/CampaignGraph"
	)
	var outline_panel: Control = screen.get_node(
		"Shell/Body/Workspace/Centre/DocumentColumns/Document/GraphOutline"
	)
	_check("the campaign graph panel is visible", campaign_panel.visible)
	_check("the objective outline is not used for campaign structure", not outline_panel.visible)
	var view: Control = screen.get_node(
		"Shell/Body/Workspace/Centre/DocumentColumns/Document/CampaignGraph/CanvasScroll/Canvas"
	)
	var rendered_graph: Dictionary = view.call("graph")
	_check(
		"the view receives all authored graph nodes",
		(rendered_graph.get("nodes", []) as Array).size() == 3
	)
	view.emit_signal("node_selected", "river_pass")
	var selection: Array[Dictionary] = shell.subject_selection()
	_check(
		"clicking a graph node routes its authored subject to the shell",
		(
			selection.size() == 1
			and String(selection[0].get("property", "")) == "nodes"
			and int(selection[0].get("index", -1)) == 1
		),
		str(selection)
	)
	screen.queue_free()
	await process_frame


func _screen_rebuild(screen: Node) -> void:
	screen.call("rebuild")
