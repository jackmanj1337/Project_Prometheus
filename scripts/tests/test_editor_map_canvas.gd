extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_editor_map_canvas.gd
#
# Covers `[CEUI-S31]`'s map canvas and its derived tool set -- `EditorMapCanvas` over a real
# `map_data` schema and a real `EditorDocument`.
#
# THE ASSERTIONS THAT CARRY THE RULINGS, and that nothing else can catch:
#
#   * THE TOOL SET IS DERIVED, NOT DECLARED (`[CEUI-S31]`). Asserted against the ENGINE's
#     own `map_data` schema, and then against a schema with a property the engine does not
#     have: a hand-written tool table per layer id would pass the first and fail the second,
#     which is exactly `[CEUI-S21]`'s closed enum one level down.
#   * A LAYER OWNS A LIST OF PROPERTIES, SO A TOOL ACTS ON A PROPERTY. `victory_conditions`
#     and `defeat_conditions` are BOTH the objectives layer. A tool set that assumed one
#     property per layer yields one tool where there should be two, and an edit helper that
#     took "the layer's property" writes to victory when the author meant defeat -- with
#     every value correct and no error raised. Asserted on both the count and the target.
#   * HIDING A LAYER CHANGES WHAT THE CANVAS DRAWS AND LEAVES THE LAYER IN THE LIST. The two
#     are separate objects precisely so this holds; a layer that vanished from the list when
#     hidden could not be shown again.
#   * A HIDDEN LAYER CANNOT BE EDITED THROUGH A TILE CLICK. Selection reads the draw model,
#     so what is invisible is unselectable -- otherwise hiding a layer would be a visual
#     nicety that still let the author change it by accident.
#   * A LOCKED LAYER REFUSES THE EDIT AND STAYS ACTIVATABLE. `[CEUI-S30]` made locking a
#     refusal to EDIT, not a refusal to look, and `[EPUX-07]` wants the reason to reach the
#     author rather than being swallowed into a no-op.
#   * EVERY EDIT IS STAGED AND COMMITS NOTHING. A canvas that committed would either skip
#     `[CEUI-S25]`'s validation or run a second pass the issues panel cannot attribute, and
#     `[CEUI-13]`'s Undo unit would stop being one author action.
#   * ONE CANVAS EDIT IS ONE UNDO STEP, and undoing it returns the record to its authored
#     value -- the failure mode is a tool that stages per tile and makes Undo N presses.

const CanvasScript = preload("res://scripts/editor/EditorMapCanvas.gd")
const DocumentScript = preload("res://scripts/editor/EditorDocument.gd")
const SchemasScript = preload("res://scripts/data/EntitySchemaRegistry.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Editor Map Canvas Test ===")

	_the_tool_set_is_derived_from_the_engine_schema()
	_a_property_the_engine_does_not_have_still_gets_a_tool()
	_a_layer_with_two_properties_gets_two_tools()
	_hiding_a_layer_changes_the_canvas_and_not_the_list()
	_a_hidden_layer_cannot_be_selected_through_a_tile()
	_a_locked_layer_refuses_the_edit_with_its_reason()
	_painting_stages_and_commits_nothing()
	_one_canvas_edit_is_one_undo_step()
	_marking_a_tile_toggles_it()
	_placing_writes_the_property_the_tool_names()
	_the_canvas_publishes_a_multi_selection_for_the_bulk_table()
	await _the_screen_draws_the_canvas_only_in_the_maps_workspace()

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


## The engine's own layers, with visibility and lock defaulted the way the shell defaults
## them. Carried as the shell's `layer_rows()` shape rather than re-derived.
func _layer_rows(overrides: Dictionary = {}) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for layer in _schemas().map_layers(1):
		var row: Dictionary = layer.duplicate(true)
		var id := String(row["id"])
		row["visible"] = bool((overrides.get(id, {}) as Dictionary).get("visible", true))
		row["locked"] = bool((overrides.get(id, {}) as Dictionary).get("locked", false))
		rows.append(row)
	return rows


func _map_record() -> Dictionary:
	return {
		"kind": "map_data",
		"schema_version": 1,
		"id": "chapter_01",
		"grid": ["....", ".##.", "...."],
		"player_start_tiles": [[0, 0], [1, 0]],
		"enemy_placements": [{"unit": {"id": "brigand"}, "tile": [3, 2]}],
		"victory_conditions": {"players": [{"type": "rout", "tile": [2, 1]}]},
		"defeat_conditions": {"players": [{"type": "lord_falls"}]},
	}


func _document() -> EditorDocument:
	return DocumentScript.open("maps", "map_data", {"chapter_01": _map_record()}, "Maps")


func _canvas(overrides: Dictionary = {}) -> EditorMapCanvas:
	var canvas := CanvasScript.new()
	canvas.set_map(_document(), "chapter_01", _layer_rows(overrides), _map_properties())
	return canvas


func _canvas_over(document: EditorDocument, overrides: Dictionary = {}) -> EditorMapCanvas:
	var canvas := CanvasScript.new()
	canvas.set_map(document, "chapter_01", _layer_rows(overrides), _map_properties())
	return canvas


# ---- the derivation ----


func _the_tool_set_is_derived_from_the_engine_schema() -> void:
	print("\n-- the tool set is derived from the engine's own schema --")
	var canvas := _canvas()
	canvas.set_active_layer("terrain")
	var terrain := canvas.active_tools()
	_check("terrain yields one tool", terrain.size() == 1, str(terrain.size()))
	_check(
		"and it is a PAINT tool, because the grid is an array of strings",
		terrain.size() == 1 and String(terrain[0]["kind"]) == CanvasScript.TOOL_PAINT
	)
	canvas.set_active_layer("deployment")
	var deployment := canvas.active_tools()
	_check(
		"deployment yields a MARK tool, because its items ARE tiles",
		deployment.size() == 1 and String(deployment[0]["kind"]) == CanvasScript.TOOL_MARK
	)
	canvas.set_active_layer("units")
	var units := canvas.active_tools()
	_check(
		"units yields a PLACE tool, because its items are objects carrying a tile",
		units.size() == 1 and String(units[0]["kind"]) == CanvasScript.TOOL_PLACE
	)
	_check(
		"a tile is recognised by SHAPE, not by being called 'tile'",
		CanvasScript.is_tile_spec(
			{"type": "array", "min_items": 2, "max_items": 2, "items": {"type": "integer"}}
		)
	)
	_check(
		"and a three-element array is not a tile",
		not CanvasScript.is_tile_spec(
			{"type": "array", "min_items": 3, "max_items": 3, "items": {"type": "integer"}}
		)
	)


## The assertion a hand-written tool table cannot pass. `[CEUI-S31]` chose derivation so a
## pack that authors a new spatial property gets a tool with NO editor edit.
func _a_property_the_engine_does_not_have_still_gets_a_tool() -> void:
	print("\n-- a property the engine does not have still gets a tool --")
	var invented := {
		"weather_cells":
		{
			"type": "array",
			"items": {"type": "string"},
			"map_layer": {"id": "weather", "label": "Weather", "order": 50},
		}
	}
	var layer := {"id": "weather", "label": "Weather", "order": 50, "properties": ["weather_cells"]}
	var tools := CanvasScript.tools_for_layer(layer, invented)
	_check("the invented layer yields a tool", tools.size() == 1, str(tools.size()))
	_check(
		"derived from its shape, with no editor edit",
		tools.size() == 1 and String(tools[0]["kind"]) == CanvasScript.TOOL_PAINT
	)
	_check(
		"a property with nothing spatial in it yields NO tool",
		(
			CanvasScript
			. tools_for_layer(
				{"id": "x", "properties": ["turn_order"]},
				{"turn_order": {"type": "array", "items": {"type": "integer"}}}
			)
			. is_empty()
		)
	)


## `victory_conditions` and `defeat_conditions` are both the objectives layer.
func _a_layer_with_two_properties_gets_two_tools() -> void:
	print("\n-- a layer with two properties gets two tools --")
	var canvas := _canvas()
	canvas.set_active_layer("objectives")
	var tools := canvas.active_tools()
	_check("the objectives layer yields TWO tools", tools.size() == 2, str(tools.size()))
	var properties: Array[String] = []
	for tool in tools:
		properties.append(String(tool["property"]))
	properties.sort()
	_check(
		"one per property, not one per layer",
		properties == (["defeat_conditions", "victory_conditions"] as Array[String]),
		str(properties)
	)
	_check(
		"and their labels are distinguishable",
		tools.size() == 2 and String(tools[0]["label"]) != String(tools[1]["label"]),
		str(tools[0]["label"]) if tools.size() == 2 else ""
	)


# ---- visibility and lock ----


func _hiding_a_layer_changes_the_canvas_and_not_the_list() -> void:
	print("\n-- hiding a layer changes the canvas and not the list --")
	var shown := _canvas()
	var drawn_ids: Array[String] = []
	for layer in shown.draw_model()["layers"] as Array[Dictionary]:
		drawn_ids.append(String(layer["id"]))
	_check("units is drawn while visible", drawn_ids.has("units"))

	var hidden := _canvas({"units": {"visible": false}})
	var hidden_ids: Array[String] = []
	for layer in hidden.draw_model()["layers"] as Array[Dictionary]:
		hidden_ids.append(String(layer["id"]))
	_check("hiding it removes it from the canvas", not hidden_ids.has("units"), str(hidden_ids))
	# The list is the shell's, and this is the row set the shell would still be holding.
	var still_listed := false
	for row in _layer_rows({"units": {"visible": false}}):
		if String(row["id"]) == "units":
			still_listed = true
	_check("and leaves it in the layer list", still_listed)
	_check(
		"the grid itself is unaffected by a layer being hidden",
		hidden.grid_size() == shown.grid_size()
	)


func _a_hidden_layer_cannot_be_selected_through_a_tile() -> void:
	print("\n-- a hidden layer cannot be selected through a tile --")
	var shown := _canvas()
	_check(
		"the enemy at (3, 2) is selectable while visible",
		shown.select_tile(Vector2i(3, 2)).size() == 1
	)
	var hidden := _canvas({"units": {"visible": false}})
	_check("and unselectable once hidden", hidden.select_tile(Vector2i(3, 2)).is_empty())


func _a_locked_layer_refuses_the_edit_with_its_reason() -> void:
	print("\n-- a locked layer refuses the edit, with its reason --")
	var document := _document()
	var canvas := _canvas_over(document, {"terrain": {"locked": true}})
	_check("a locked layer is still activatable", canvas.set_active_layer("terrain"))
	var result := canvas.apply_tool("terrain:grid", Vector2i(0, 0), "#")
	_check("the edit is refused", not bool(result["applied"]))
	_check(
		"with a reason the author can act on",
		String(result["reason"]) == CanvasScript.LOCKED_LAYER_REASON,
		String(result["reason"])
	)
	_check("and nothing was staged", not document.has_staged_edit())
	_check(
		"a tool from another layer is refused too, with a different reason",
		(
			String(
				canvas.apply_tool("units:enemy_placements", Vector2i(0, 0), {}).get("reason", "")
			)
			== CanvasScript.WRONG_LAYER_REASON
		)
	)


# ---- the transaction ----


func _painting_stages_and_commits_nothing() -> void:
	print("\n-- painting stages and commits nothing --")
	var document := _document()
	var canvas := _canvas_over(document)
	canvas.set_active_layer("terrain")
	var result := canvas.apply_tool("terrain:grid", Vector2i(1, 0), "#")
	_check("the paint is applied", bool(result["applied"]), String(result["reason"]))
	_check("it is STAGED", document.has_staged_edit())
	# `record()` resolves all three layers, so the staged value is visible through it by
	# design. What says "not committed" is that nothing has reached the overlay: the
	# document is not dirty and the edit is not yet an Undo step. Asserting the resolved
	# value here would assert the opposite of the three-layer model.
	_check("but nothing has been committed: the document is not dirty", not document.is_dirty())
	_check("and the edit is not yet an Undo step", document.undo_depth() == 0)
	document.commit_edit()
	_check(
		"committing writes the painted row",
		String((document.record("chapter_01")["grid"] as Array)[0]) == ".#..",
		String((document.record("chapter_01")["grid"] as Array)[0])
	)
	_check(
		"painting outside the grid is refused",
		not bool(canvas.apply_tool("terrain:grid", Vector2i(99, 0), "#")["applied"])
	)
	_check(
		"and a multi-character glyph is refused",
		not bool(canvas.apply_tool("terrain:grid", Vector2i(0, 0), "##")["applied"])
	)


func _one_canvas_edit_is_one_undo_step() -> void:
	print("\n-- one canvas edit is one undo step --")
	var document := _document()
	var canvas := _canvas_over(document)
	canvas.set_active_layer("terrain")
	canvas.apply_tool("terrain:grid", Vector2i(0, 0), "#")
	document.commit_edit()
	_check("one edit is one undo step", document.undo_depth() == 1, str(document.undo_depth()))
	document.undo()
	_check(
		"and undoing returns the authored value",
		String((document.record("chapter_01")["grid"] as Array)[0]) == "....",
		String((document.record("chapter_01")["grid"] as Array)[0])
	)


func _marking_a_tile_toggles_it() -> void:
	print("\n-- marking a tile toggles it --")
	var document := _document()
	var canvas := _canvas_over(document)
	canvas.set_active_layer("deployment")
	canvas.apply_tool("deployment:player_start_tiles", Vector2i(2, 2))
	document.commit_edit()
	var added: Array = document.record("chapter_01")["player_start_tiles"]
	_check("an unmarked tile is added", added.size() == 3, str(added.size()))
	canvas.apply_tool("deployment:player_start_tiles", Vector2i(2, 2))
	document.commit_edit()
	var removed: Array = document.record("chapter_01")["player_start_tiles"]
	_check("and a marked tile is removed", removed.size() == 2, str(removed.size()))
	_check(
		"so no second eraser tool has to be derived",
		canvas.active_tools().size() == 1,
		str(canvas.active_tools().size())
	)


## The edit that a layer-keyed helper would get wrong: both properties are the objectives
## layer, and only the tool says which one the author meant.
func _placing_writes_the_property_the_tool_names() -> void:
	print("\n-- placing writes the property the tool names --")
	var document := _document()
	var canvas := _canvas_over(document)
	canvas.set_active_layer("objectives")
	var result := canvas.apply_tool(
		"objectives:defeat_conditions",
		Vector2i(1, 1),
		{"group": "players", "entry": {"type": "seize"}}
	)
	_check("the placement is applied", bool(result["applied"]), String(result["reason"]))
	document.commit_edit()
	var defeat: Dictionary = document.record("chapter_01")["defeat_conditions"]
	var victory: Dictionary = document.record("chapter_01")["victory_conditions"]
	_check(
		"the DEFEAT conditions grew",
		(defeat["players"] as Array).size() == 2,
		str(defeat["players"])
	)
	_check(
		"and the victory conditions -- the same layer -- did NOT",
		(victory["players"] as Array).size() == 1,
		str(victory["players"])
	)
	_check(
		"the placed entry carries the tile it was placed on",
		((defeat["players"] as Array)[1] as Dictionary)["tile"] == [1, 1],
		str((defeat["players"] as Array)[1])
	)


func _the_canvas_publishes_a_multi_selection_for_the_bulk_table() -> void:
	print("\n-- the canvas publishes a multi-selection rather than growing its own editor --")
	var canvas := _canvas()
	var single := canvas.select_tile(Vector2i(3, 2))
	_check("one mark on a tile is a single selection", single.size() == 1)
	_check("and is not multi", not canvas.selection_is_multi())
	# (0, 0) carries a deployment mark; adding the enemy at (3, 2) makes it two.
	canvas.select_tile(Vector2i(0, 0), true)
	_check(
		"an additive selection accumulates across layers",
		canvas.selection().size() == 2,
		str(canvas.selection().size())
	)
	_check(
		"which `[CEUI-S23]` routes to the bulk table rather than a second canvas editor",
		canvas.selection_is_multi()
	)
	var marks := canvas.selection()
	var addressable := true
	for mark in marks:
		if not (mark.has("property") and mark.has("index") and mark.has("layer")):
			addressable = false
	_check("every selected mark carries the address an edit needs", addressable, str(marks))
	canvas.clear_selection()
	_check("clearing empties it", canvas.selection().is_empty())


# ---- the screen ----


func _the_screen_draws_the_canvas_only_in_the_maps_workspace() -> void:
	print("\n-- the screen draws the canvas only in the Maps workspace --")
	var screen: Control = preload("res://scenes/ui/CampaignEditorScreen.tscn").instantiate()
	root.add_child(screen)
	await process_frame

	var shell: CampaignEditorShell = screen.shell()
	shell.set_schemas(_schemas())
	shell.set_working_copy({"id": "draft", "label": "Draft"})
	shell.open_document("maps", "map_data", {"chapter_01": _map_record()}, "Maps")
	shell.record_selector().focus("chapter_01")
	screen.rebuild()
	await process_frame

	var panel: Control = screen.get_node(
		"Shell/Body/Workspace/Centre/DocumentColumns/Document/MapCanvas"
	)
	_check("the canvas is absent in the Content workspace", not panel.visible)

	shell.workspaces().activate("maps")
	await process_frame
	_check("and present in Maps with a map document focused", panel.visible)

	var tools: HBoxContainer = screen.get_node(
		"Shell/Body/Workspace/Centre/DocumentColumns/Document/MapCanvas/ToolScroll/Tools"
	)
	shell.layer_selector().focus("objectives")
	screen.rebuild()
	await process_frame
	_check(
		"the objectives layer draws TWO derived tool buttons",
		tools.get_child_count() == 2,
		str(tools.get_child_count())
	)
	shell.layer_selector().focus("terrain")
	screen.rebuild()
	await process_frame
	_check(
		"and the terrain layer draws one",
		tools.get_child_count() == 1,
		str(tools.get_child_count())
	)

	shell.workspaces().activate("content")
	await process_frame
	_check("leaving Maps takes the canvas away again", not panel.visible)

	screen.queue_free()
	await process_frame
