extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_editor_graph_outline.gd
#
# Covers `[CEUI-S32]`'s Graph workspace -- `EditorObjectiveOutline` over a real `map_data`
# schema and a real `EditorDocument`, plus the surface that draws it.
#
# THE ASSERTIONS THAT CARRY THE RULING, and that nothing else can catch:
#
#   * THE OUTLINE'S PROPERTIES ARE DERIVED FROM THE SCHEMA, NOT NAMED. Asserted against the
#     ENGINE's own `map_data` schema, and then against a property the engine does not have.
#     A list of property names would pass the first and fail the second, which is
#     `[CEUI-S21]`'s closed enum one level down.
#   * A PLACEMENT IS NOT AN OUTLINE CARD, even though it carries a vocabulary field. The
#     rule is a REQUIRED field with a vocabulary -- a placement's identity is its unit and
#     its tile, and `ai_profile` is an optional refinement. Matching on "has a vocabulary"
#     puts all six enemy placements on the objective outline with nothing raised anywhere.
#   * THE PREDICATE LIST COMES FROM THE REGISTRY, EVERY TIME. Asserted by registering a
#     predicate the engine never shipped and finding it offered. `[CEUI-S32]` rejected
#     option C's fixed dropdowns outright, and a cached vocabulary is that dropdown with a
#     cache's alibi.
#   * THE PROJECTION IS DEMAND-GATED, and returns nothing until asked.
#   * A PROJECTION NODE'S ID IS THE CARD'S ID, AND NO NODE CARRIES A POSITION. This is the
#     "never a second source format" half. A graph that minted ids could drift from the
#     outline; a graph that stored a layout would own the one piece of state the outline
#     cannot reconstruct, and so the one that would have to be migrated.
#   * THE PROJECTION FOLLOWS AN EDIT WITH NOTHING RE-BUILT, because it is derived on call.
#   * EVERY EDIT IS STAGED AND COMMITS NOTHING, and one card edit is one Undo step -- the
#     same transaction rule the canvas follows, for the same reasons.
#   * REORDERING RETURNS THE CARD'S NEW ID. A move keeps the array's LENGTH, so
#     `EditorSubject.re_derive()` -- which drops a selection only when the length changed --
#     keeps a selection whose indices the move just reassigned. That is the one mutation the
#     length rule cannot see, and this is the assertion that the operation says so.
#   * REMOVING A CARD DOES change the length, so a selection into that property is dropped.
#   * THE OUTLINE'S LINK INTO THE MAP IS THE CANVAS'S OWN ADDRESS. The subject a card
#     publishes is byte-identical to the subject the canvas publishes for the same
#     condition, which is what makes the link a navigation rather than a copy.

const OutlineScript = preload("res://scripts/editor/EditorObjectiveOutline.gd")
const CanvasScript = preload("res://scripts/editor/EditorMapCanvas.gd")
const DocumentScript = preload("res://scripts/editor/EditorDocument.gd")
const SubjectScript = preload("res://scripts/editor/EditorSubject.gd")
const SchemasScript = preload("res://scripts/data/EntitySchemaRegistry.gd")
const ShellScript = preload("res://scripts/editor/CampaignEditorShell.gd")
const WorkspacesScript = preload("res://scripts/editor/EditorWorkspaces.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Editor Graph Outline Test ===")

	_outline_properties_are_derived_from_the_engine_schema()
	_a_placement_is_not_an_outline_card()
	_a_property_the_engine_does_not_have_still_gets_an_outline()
	_cards_are_in_the_authored_order()
	_the_predicate_list_comes_from_the_registry()
	_a_card_links_to_the_map_with_the_canvas_address()
	_the_projection_is_demand_gated()
	_the_projection_borrows_the_outline_ids_and_owns_no_layout()
	_the_projection_follows_an_edit()
	_editing_a_card_stages_and_commits_nothing()
	_one_card_edit_is_one_undo_step()
	_an_unregistered_predicate_is_refused_with_its_reason()
	_reordering_reports_where_the_card_went()
	_removing_a_card_drops_a_selection_into_that_property()
	await _the_screen_draws_the_outline_only_in_the_graph_workspace()

	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % label)
	else:
		_failed += 1
		print("  FAIL: %s%s" % [label, ("  [%s]" % detail) if detail != "" else ""])


func _schemas() -> EntitySchemaRegistry:
	return SchemasScript.with_core_schemas()


func _map_properties() -> Dictionary:
	return _schemas().schema_for("map_data", 1).get("properties", {})


## Two victory conditions in one group and one defeat condition, so order, grouping and the
## two-properties case are all live in the same record.
func _map_record() -> Dictionary:
	return {
		"kind": "map_data",
		"schema_version": 1,
		"id": "chapter_01",
		"grid": ["....", ".##.", "...."],
		"player_start_tiles": [[0, 0], [1, 0]],
		"enemy_placements":
		[{"unit": {"id": "brigand"}, "tile": [3, 2], "ai_profile": "aggressive"}],
		"victory_conditions":
		{"players": [{"type": "seize", "tile": [2, 1]}, {"type": "rout", "faction_id": "bandits"}]},
		"defeat_conditions": {"players": [{"type": "survive", "turns": 5}]},
	}


func _document() -> EditorDocument:
	return DocumentScript.open("maps", "map_data", {"chapter_01": _map_record()}, "Maps")


func _outline_over(
	document: EditorDocument, schemas: EntitySchemaRegistry = null
) -> EditorObjectiveOutline:
	var outline := OutlineScript.new()
	outline.set_record(document, "chapter_01", schemas if schemas != null else _schemas())
	return outline


func _outline() -> EditorObjectiveOutline:
	return _outline_over(_document())


# ---- the derivation ----


func _outline_properties_are_derived_from_the_engine_schema() -> void:
	print("\n-- the outline's properties are derived from the engine's own schema --")
	var properties := _outline().properties()
	_check(
		"the engine's map schema yields exactly two outline properties",
		properties.size() == 2,
		str(properties)
	)
	_check(
		"and they are the two condition properties, in the schema's own order",
		properties == (["victory_conditions", "defeat_conditions"] as Array[String]),
		str(properties)
	)
	_check(
		"the predicate field is the REQUIRED field carrying the vocabulary",
		(
			OutlineScript.predicate_field(
				SubjectScript.item_schema(_map_properties()["victory_conditions"])
			)
			== "type"
		)
	)
	_check(
		"and the vocabulary it names is the open objective-condition registry",
		(
			OutlineScript.predicate_vocabulary(
				SubjectScript.item_schema(_map_properties()["victory_conditions"])
			)
			== "objective_condition"
		)
	)


## The assertion "has a vocabulary anywhere" fails.
func _a_placement_is_not_an_outline_card() -> void:
	print("\n-- a placement carries a vocabulary and is still not an outline card --")
	var placement_spec: Dictionary = SubjectScript.item_schema(
		_map_properties()["enemy_placements"]
	)
	_check(
		"the placement item schema DOES carry a vocabulary field",
		(placement_spec.get("properties", {}) as Dictionary).has("ai_profile")
	)
	_check(
		"but it is not required, so a placement yields no predicate field",
		OutlineScript.predicate_field(placement_spec) == "",
		str(placement_spec.get("required", []))
	)
	var card_properties: Array[String] = []
	for entry in _outline().cards():
		card_properties.append(String(entry["property"]))
	_check(
		"and no card in the outline came from enemy_placements",
		not card_properties.has("enemy_placements"),
		str(card_properties)
	)


## The assertion a hand-written property list cannot pass.
func _a_property_the_engine_does_not_have_still_gets_an_outline() -> void:
	print("\n-- a property the engine does not have still gets an outline --")
	var invented := {
		"village_events":
		{
			"type": "array",
			"items":
			{
				"type": "object",
				"required": ["event"],
				"properties":
				{
					"event": {"type": "string", "vocabulary": "village_event"},
					"tile":
					{
						"type": "array",
						"min_items": 2,
						"max_items": 2,
						"items": {"type": "integer"},
					},
				},
			},
		}
	}
	var derived := OutlineScript.outline_properties(invented)
	_check(
		"the invented property yields an outline",
		derived == (["village_events"] as Array[String]),
		str(derived)
	)
	_check(
		"a property whose required fields carry no vocabulary does NOT",
		(
			OutlineScript
			. outline_properties(
				{
					"factions":
					{
						"type": "array",
						"items":
						{
							"type": "object",
							"required": ["id"],
							"properties": {"id": {"type": "string"}},
						},
					}
				}
			)
			. is_empty()
		)
	)


func _cards_are_in_the_authored_order() -> void:
	print("\n-- the cards are in the authored order --")
	var cards := _outline().cards()
	_check("three conditions yield three cards", cards.size() == 3, str(cards.size()))
	var predicates: Array[String] = []
	for entry in cards:
		predicates.append(String(entry["predicate"]))
	_check(
		"victory before defeat (the schema's order), seize before rout (the array's)",
		predicates == (["seize", "rout", "survive"] as Array[String]),
		str(predicates)
	)
	_check(
		"positions are one-based within their own group",
		(
			int(cards[0]["position"]) == 1
			and int(cards[1]["position"]) == 2
			and int(cards[2]["position"]) == 1
		),
		str([cards[0]["position"], cards[1]["position"], cards[2]["position"]])
	)
	_check(
		"a card is readable without naming any field in the editor",
		(
			String(cards[2]["summary"]).begins_with("Survive")
			and String(cards[2]["summary"]).contains("turns 5")
		),
		String(cards[2]["summary"])
	)


func _the_predicate_list_comes_from_the_registry() -> void:
	print("\n-- the predicate list comes from the registry, every time --")
	var outline := _outline()
	var options := outline.predicate_options("victory_conditions")
	_check(
		"the engine's registered conditions are offered", options.has("seize"), str(options.size())
	)
	# The assertion a hardcoded list cannot pass: a condition the engine never shipped.
	var schemas := _schemas()
	schemas.register_vocabulary("objective_condition", ["escort_the_caravan"])
	var extended := _outline_over(_document(), schemas).predicate_options("victory_conditions")
	_check(
		"and a predicate registered at runtime is offered too, with no editor edit",
		extended.has("escort_the_caravan"),
		str(extended.size())
	)
	_check(
		"a property that is not an outline property offers nothing",
		outline.predicate_options("enemy_placements").is_empty()
	)


func _a_card_links_to_the_map_with_the_canvas_address() -> void:
	print("\n-- a card's link into the map IS the canvas's own address --")
	var document := _document()
	var outline := _outline_over(document)
	var seize := outline.cards()[0]
	_check(
		"the seize card reports the tile it names",
		(seize["tiles"] as Array[Vector2i]) == ([Vector2i(2, 1)] as Array[Vector2i]),
		str(seize["tiles"])
	)
	_check(
		"a condition with no tile links to nothing",
		(outline.cards()[1]["tiles"] as Array[Vector2i]).is_empty()
	)

	var canvas := CanvasScript.new()
	var layers: Array[Dictionary] = []
	for layer in _schemas().map_layers(1):
		var row: Dictionary = layer.duplicate(true)
		row["visible"] = true
		row["locked"] = false
		layers.append(row)
	canvas.set_map(document, "chapter_01", layers, _map_properties())
	var marks := canvas.select_tile(Vector2i(2, 1))
	var from_canvas: Dictionary = {}
	for mark in marks:
		if String(mark["property"]) == "victory_conditions":
			from_canvas = SubjectScript.from_mark("chapter_01", mark)
	_check("the canvas addresses the same condition", not from_canvas.is_empty(), str(marks))
	_check(
		"and the outline publishes the identical subject",
		not from_canvas.is_empty() and SubjectScript.key(from_canvas) == String(seize["id"]),
		"%s vs %s" % [SubjectScript.key(from_canvas), String(seize["id"])]
	)
	var published := outline.subjects_for([String(seize["id"])])
	_check(
		"subjects_for() hands the shell exactly that address",
		published.size() == 1 and SubjectScript.key(published[0]) == String(seize["id"])
	)


# ---- the projection ----


func _the_projection_is_demand_gated() -> void:
	print("\n-- the projection is demand-gated --")
	var outline := _outline()
	_check("nothing asks for a graph by default", not outline.is_projection_enabled())
	_check("so the projection is empty", outline.projection().is_empty())
	outline.set_projection_enabled(true)
	_check("asking for it produces one", not outline.projection().is_empty())


func _the_projection_borrows_the_outline_ids_and_owns_no_layout() -> void:
	print("\n-- the projection borrows the outline's ids and owns no layout --")
	var outline := _outline()
	outline.set_projection_enabled(true)
	var graph := outline.projection()
	var nodes: Array[Dictionary] = graph["nodes"]
	var card_ids: Dictionary = {}
	for entry in outline.cards():
		card_ids[String(entry["id"])] = true
	var card_nodes := 0
	var minted := 0
	var positioned := 0
	for node in nodes:
		if String(node["kind"]) != OutlineScript.NODE_CARD:
			continue
		card_nodes += 1
		if not card_ids.has(String(node["id"])):
			minted += 1
		for key in ["x", "y", "position", "layout", "rect"]:
			if (node as Dictionary).has(key):
				positioned += 1
	_check("every card is a node", card_nodes == 3, str(card_nodes))
	_check("and no node minted an id of its own", minted == 0, str(minted))
	_check("no node carries a position of any kind", positioned == 0, str(positioned))
	var edges: Array[Dictionary] = graph["edges"]
	var follows := 0
	for edge in edges:
		if String(edge["kind"]) == OutlineScript.EDGE_FOLLOWS:
			follows += 1
	_check(
		"the only edges are the ordering the outline already is",
		follows == 1 and edges.size() == 3,
		"%d follows of %d edges" % [follows, edges.size()]
	)


func _the_projection_follows_an_edit() -> void:
	print("\n-- the projection follows an edit with nothing rebuilt --")
	var document := _document()
	var outline := _outline_over(document)
	outline.set_projection_enabled(true)
	var before: Array[Dictionary] = outline.projection()["nodes"]
	var result := outline.add_card("victory_conditions", "players", "rout")
	_check("adding a card is accepted", bool(result["applied"]), String(result["reason"]))
	var after: Array[Dictionary] = outline.projection()["nodes"]
	_check(
		"the projection has the new card without being told",
		after.size() == before.size() + 1,
		"%d -> %d" % [before.size(), after.size()]
	)


# ---- the transaction ----


func _editing_a_card_stages_and_commits_nothing() -> void:
	print("\n-- every card edit is staged and commits nothing --")
	var document := _document()
	var outline := _outline_over(document)
	var card_id := String(outline.cards()[0]["id"])
	var result := outline.set_predicate(card_id, "rout")
	_check("the edit is accepted", bool(result["applied"]), String(result["reason"]))
	_check("it is staged", document.has_staged_edit())
	_check("and the document is NOT dirty, because nothing committed", not document.is_dirty())
	_check(
		"the staged value is readable through the document",
		String(outline.cards()[0]["predicate"]) == "rout"
	)


func _one_card_edit_is_one_undo_step() -> void:
	print("\n-- one card edit is one Undo step --")
	var document := _document()
	var outline := _outline_over(document)
	outline.set_predicate(String(outline.cards()[0]["id"]), "rout")
	document.commit_edit()
	_check("the commit is one Undo step", document.undo_depth() == 1, str(document.undo_depth()))
	document.undo()
	_check(
		"and undoing returns the card to its authored predicate",
		String(outline.cards()[0]["predicate"]) == "seize",
		String(outline.cards()[0]["predicate"])
	)
	_check("leaving the document clean", not document.is_dirty())


func _an_unregistered_predicate_is_refused_with_its_reason() -> void:
	print("\n-- an unregistered predicate is refused, with its reason --")
	var document := _document()
	var outline := _outline_over(document)
	var result := outline.set_predicate(
		String(outline.cards()[0]["id"]), "definitely_not_registered"
	)
	_check("the edit is refused", not bool(result["applied"]))
	_check(
		"and says why, rather than doing nothing",
		String(result["reason"]) == OutlineScript.UNKNOWN_PREDICATE_REASON,
		String(result["reason"])
	)
	_check("nothing was staged", not document.has_staged_edit())
	var added := outline.add_card("enemy_placements", "", "seize")
	_check(
		"adding to a property that has no outline is refused too",
		(
			not bool(added["applied"])
			and String(added["reason"]) == OutlineScript.NOT_AN_OUTLINE_PROPERTY_REASON
		),
		String(added["reason"])
	)


# ---- the two order mutations, which behave differently on purpose ----


func _reordering_reports_where_the_card_went() -> void:
	print("\n-- reordering reports where the card went --")
	var document := _document()
	var outline := _outline_over(document)
	var cards := outline.cards()
	var seize_id := String(cards[0]["id"])
	var lengths := SubjectScript.capture_lengths(document, [cards[0]["subject"]])
	var moved := outline.move_card(seize_id, 1)
	_check("the move is accepted", bool(moved["applied"]), String(moved["reason"]))
	document.commit_edit()
	var reordered := outline.cards()
	_check(
		"the order changed",
		(
			String(reordered[0]["predicate"]) == "rout"
			and String(reordered[1]["predicate"]) == "seize"
		),
		"%s, %s" % [reordered[0]["predicate"], reordered[1]["predicate"]]
	)
	# The hazard, asserted rather than assumed: the length rule cannot see a permutation.
	var kept := SubjectScript.re_derive(document, [cards[0]["subject"]], lengths)
	_check(
		"the length rule KEEPS the old address, because a move does not change the length",
		kept.size() == 1,
		str(kept.size())
	)
	_check(
		"which is why move_card returns the new id for the caller to follow",
		String(moved["id"]) == String(reordered[1]["id"]),
		"%s vs %s" % [String(moved["id"]), String(reordered[1]["id"])]
	)
	_check(
		"moving off the end is refused with its reason",
		(
			not bool(outline.move_card(String(reordered[1]["id"]), 1)["applied"])
			and (
				String(outline.move_card(String(reordered[1]["id"]), 1)["reason"])
				== OutlineScript.AT_EDGE_REASON
			)
		)
	)


func _removing_a_card_drops_a_selection_into_that_property() -> void:
	print("\n-- removing a card drops a selection into that property --")
	var document := _document()
	var outline := _outline_over(document)
	var cards := outline.cards()
	var lengths := SubjectScript.capture_lengths(
		document, [cards[0]["subject"], cards[1]["subject"]]
	)
	var removed := outline.remove_card(String(cards[0]["id"]))
	_check("the removal is accepted", bool(removed["applied"]), String(removed["reason"]))
	document.commit_edit()
	_check("one card fewer", outline.cards().size() == 2, str(outline.cards().size()))
	var kept := SubjectScript.re_derive(
		document, [cards[0]["subject"], cards[1]["subject"]], lengths
	)
	_check(
		"and the selection into that property is dropped, because the length changed",
		kept.is_empty(),
		str(kept.size())
	)


# ---- the surface ----


## `[CEUI-S12]`: the outline is a GRAPH-workspace surface and is absent everywhere else,
## exactly as the canvas is a Maps-workspace surface.
func _the_screen_draws_the_outline_only_in_the_graph_workspace() -> void:
	print("\n-- the screen draws the outline only in the Graph workspace --")
	var packed: PackedScene = load("res://scenes/ui/CampaignEditorScreen.tscn")
	var screen: Node = packed.instantiate()
	root.add_child(screen)
	await process_frame

	var shell: CampaignEditorShell = screen.shell()
	shell.set_schemas(_schemas())
	shell.open_document("maps", "map_data", {"chapter_01": _map_record()}, "Maps")
	shell.record_selector().focus("chapter_01")
	shell.workspaces().activate(WorkspacesScript.GRAPH)
	screen.rebuild()
	await process_frame

	var panel: Control = screen.get_node(
		"Shell/Body/Workspace/Centre/DocumentColumns/Document/GraphOutline"
	)
	_check("the Graph workspace shows the outline", panel.visible)
	var cards: VBoxContainer = screen.get_node(
		"Shell/Body/Workspace/Centre/DocumentColumns/Document/GraphOutline/CardScroll/Cards"
	)
	_check(
		"with one row per authored condition",
		cards.get_child_count() == 3,
		str(cards.get_child_count())
	)

	shell.workspaces().activate(WorkspacesScript.CONTENT)
	await process_frame
	_check("leaving Graph takes it away again", not panel.visible)

	screen.queue_free()
	await process_frame
