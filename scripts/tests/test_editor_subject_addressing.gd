extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_editor_subject_addressing.gd
#
# Covers the Inspector/bulk-table SUBJECT: `EditorSubject`, the item-subject half of
# `EditorFormModel` and `EditorBulkTable`, and the canvas-selection routing in
# `CampaignEditorShell`. `[CEUI-S23]` says any multi-selection -- "including a selection
# made on the map canvas" -- opens `[CEUI-S14]`'s bulk table over that selection; only the
# ADDRESS was missing, and these are the assertions that hold the address honest.
#
# THE ASSERTIONS THAT CARRY THE RULINGS, and that nothing else can catch:
#
#   * THE SINGLE-SELECTION CASE IS THE ONE THAT WAS BROKEN. A map document's only record is
#     the MAP, so an Inspector pinned to a record id showed `chapter_01` -- with its
#     placements as a raw JSON string -- when the author clicked one enemy. The form over a
#     placement subject must show THE PLACEMENT's fields. This is the defect, not a
#     refinement of the multi-edit case.
#   * THE FOUR FIELD KINDS AND THE BULK RESTRICTION TRANSFER WITH NO NEW RULES. `unit` is
#     an object and stays structured; `ai_profile` carries a vocabulary and stays a
#     reference the table refuses; `faction` and `is_boss` are scalars and are offered.
#     That this needed no restatement is the test that the SUBJECT, not the table, was the
#     thing to generalize -- so these are asserted against the real `map_data` schema.
#   * AN ITEM EDIT STAGES THE WHOLE PROPERTY, WHICH IS WHY ATOMICITY IS FREE. Three
#     placements' faction is ONE staged cell -> one commit -> `undo_depth() == 1`. A table
#     that wrote per item would have every value correct and Undo would be three presses.
#   * AN ITEM HAS NO IDENTITY FIELD. Its only identity is its index, so `[CEUI-S8]`'s rename
#     refusal must not fire on an item field that happens to equal the map's id -- that
#     would refuse a legal bulk edit with a reason about rewriting references.
#   * A SELECTION SPANNING TWO KINDS OF OBJECT IS NAMED, NOT SHOWN EMPTY. Two placements and
#     a deployment tile have no common schema; `[EPUX-02]` wants the empty surface to say
#     what would fill it.
#   * A COMMIT THAT CHANGES A PROPERTY'S LENGTH DROPS THE SELECTION. Index addressing is
#     only honest while the shape is: an insertion moves every index after it, and keeping
#     the in-range survivors would silently retarget the author's selection onto different
#     objects with no error anywhere.
#   * THE TABLE DOES NOT TAKE THE CANVAS AWAY. Both were found by RENDERING the screen: a
#     table opened from a canvas selection used to hide the canvas (the record-list rule),
#     which makes the ruled route unusable, and an empty table still drew its column headers
#     over blank space, which reads as a surface that failed rather than as the refusal
#     printed underneath it.
#   * THE TWO SELECTIONS ARE EXCLUSIVE. A canvas selection clears the record selection and
#     the reverse, because `[CEUI-S23]` routes ONE selection to one surface and `EW-6`'s
#     status-bar count has to answer "how many things will this edit touch".

const ShellScript = preload("res://scripts/editor/CampaignEditorShell.gd")
const DocumentScript = preload("res://scripts/editor/EditorDocument.gd")
const FormScript = preload("res://scripts/editor/EditorFormModel.gd")
const BulkTableScript = preload("res://scripts/editor/EditorBulkTable.gd")
const SubjectScript = preload("res://scripts/editor/EditorSubject.gd")
const MapCanvasScript = preload("res://scripts/editor/EditorMapCanvas.gd")
const SchemasScript = preload("res://scripts/data/EntitySchemaRegistry.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Editor Subject Addressing Test ===")

	_an_address_is_a_record_or_an_item_in_one()
	_the_form_over_an_item_is_the_items_schema()
	_the_single_selection_case_shows_the_placement_not_the_map()
	_an_item_edit_stages_the_whole_property_as_one_cell()
	_an_item_has_no_identity_field()
	_the_table_over_placements_is_one_undo_step()
	_a_selection_of_two_kinds_names_its_refusal()
	_a_mark_with_no_fields_says_so()
	_the_grouped_shape_addresses_through_its_group()
	_a_commit_that_changes_a_length_drops_the_selection()
	_the_shell_routes_a_canvas_selection()
	_a_canvas_selection_converts_to_subjects()
	await _the_screen_keeps_the_canvas_under_the_table()

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


## A real `map_data` document, because the whole point of the row is that the engine's own
## map schema -- not a fixture -- has the shape the record-id address could not reach.
## `id` is deliberately `"chapter_01"` and one placement's `faction` is `"chapter_01"` too,
## which is what the identity assertion needs.
func _map_document() -> EditorDocument:
	return (
		DocumentScript
		. open(
			"maps",
			"map_data",
			{
				"chapter_01":
				{
					"kind": "map_data",
					"schema_version": 1,
					"id": "chapter_01",
					"display_name": "Chapter 1",
					"source_refs": [],
					"grid": ["....", "....", "....", "...."],
					"player_start_tiles": [[0, 0], [0, 1]],
					"enemy_placements":
					[
						{
							"unit": {"id": "brigand"},
							"tile": [2, 2],
							"faction": "enemy",
							"is_boss": false
						},
						{
							"unit": {"id": "brigand"},
							"tile": [3, 2],
							"faction": "enemy",
							"is_boss": false
						},
						{
							"unit": {"id": "boss"},
							"tile": [3, 3],
							"faction": "chapter_01",
							"is_boss": true
						},
					],
					"victory_conditions":
					{
						"players":
						[{"type": "rout", "tile": [1, 1]}, {"type": "seize", "tile": [2, 1]}]
					},
				},
			},
			"Maps"
		)
	)


func _placement(index: int, group: String = "") -> Dictionary:
	return SubjectScript.for_item("chapter_01", "enemy_placements", index, group)


func _an_address_is_a_record_or_an_item_in_one() -> void:
	print("\n-- the address itself --")
	var record := SubjectScript.for_record("chapter_01")
	var item := _placement(1)
	_check("a record subject is not an item", not SubjectScript.is_item(record))
	_check("an item subject is", SubjectScript.is_item(item))
	# Two selections of the same mark are ONE subject. The tile is not part of the address:
	# moving a placement does not make it a different placement.
	_check(
		"the key is the address and not the tile",
		SubjectScript.key(item) == SubjectScript.key(_placement(1))
	)
	_check(
		"and distinguishes two items of one property",
		SubjectScript.key(item) != SubjectScript.key(_placement(2))
	)
	_check(
		"the group is part of the address",
		SubjectScript.key(_placement(0, "a")) != SubjectScript.key(_placement(0, "b"))
	)

	var document := _map_document()
	_check("an item in range resolves", SubjectScript.is_resolvable(document, _placement(2)))
	_check(
		"an index past the end does not", not SubjectScript.is_resolvable(document, _placement(9))
	)
	_check(
		"and neither does a property that is not there",
		not SubjectScript.is_resolvable(document, SubjectScript.for_item("chapter_01", "nope", 0))
	)


func _the_form_over_an_item_is_the_items_schema() -> void:
	print("\n-- [CEUI-S14] the kinds transfer to an item with no new rules --")
	var schemas := _schemas()
	var document := _map_document()
	var form := FormScript.over_subject(document, _placement(0), schemas)
	_check("the form has a schema", form.has_schema() and form.has_fields())

	var drawn: Array[String] = []
	for field in form.fields():
		drawn.append(String(field["name"]))
	drawn.sort()
	var placement_spec: Variant = (
		schemas.schema_for("map_data", 1).get("properties", {}) as Dictionary
	)["enemy_placements"]
	var expected: Array[String] = []
	for name in SubjectScript.item_schema(placement_spec).get("properties", {}) as Dictionary:
		expected.append(String(name))
	expected.sort()
	# The item schema and nothing else -- the same assertion the record form carries, so a
	# hand-added field for "the map case" fails here rather than at review.
	_check(
		"the fields are exactly the item schema's properties",
		drawn == expected,
		"drawn=%s expected=%s" % [drawn, expected]
	)

	# THE RESTRICTION TRANSFERS, unrestated. Derived from `vocabulary`/`enum`/`type`.
	_check(
		"unit is an object and stays structured",
		form.kind_of("unit") == FormScript.FIELD_STRUCTURED
	)
	_check(
		"tile is an array and stays structured", form.kind_of("tile") == FormScript.FIELD_STRUCTURED
	)
	_check(
		"ai_profile carries a vocabulary and stays a reference",
		form.kind_of("ai_profile") == FormScript.FIELD_REFERENCE
	)
	_check("faction is a scalar", form.kind_of("faction") == FormScript.FIELD_SCALAR)
	_check("is_boss is a scalar", form.kind_of("is_boss") == FormScript.FIELD_SCALAR)
	_check(
		"and the reference is refused by the table",
		not bool(form.field("ai_profile")["bulk_editable"])
	)
	_check("while the scalars are offered", bool(form.field("faction")["bulk_editable"]))


func _the_single_selection_case_shows_the_placement_not_the_map() -> void:
	print("\n-- the defect: one click showed a form for the whole map --")
	var schemas := _schemas()
	var document := _map_document()
	var map_form := FormScript.over(document, "chapter_01", schemas)
	# What the author used to get: the map's own form, with the placements as one
	# structured field rendered read-only as raw JSON.
	_check(
		"the record form still shows enemy_placements as a structured field",
		map_form.kind_of("enemy_placements") == FormScript.FIELD_STRUCTURED
	)

	var form := FormScript.over_subject(document, _placement(2), schemas)
	_check("the item form's subject is the placement", form.is_item_subject())
	_check("its record is still the map", form.record_id() == "chapter_01")
	_check(
		"and it shows THAT placement's values",
		form.field("faction")["value"] == "chapter_01" and bool(form.field("is_boss")["value"]),
		str(form.field("faction")["value"])
	)
	var other := FormScript.over_subject(document, _placement(0), schemas)
	_check("while its neighbour shows its own", other.field("faction")["value"] == "enemy")
	# The heading has to say which of three, or it names the map three times.
	_check(
		"the label names the property and which one",
		form.subject_label().contains("Enemy Placements") and form.subject_label().contains("3"),
		form.subject_label()
	)


func _an_item_edit_stages_the_whole_property_as_one_cell() -> void:
	print("\n-- an item edit stages the property, not a field --")
	var schemas := _schemas()
	var document := _map_document()
	var form := FormScript.over_subject(document, _placement(0), schemas)
	var outcome := form.set_value("faction", "ally")
	_check("the edit is accepted", bool(outcome["accepted"]), String(outcome["reason"]))

	var cells := document.staged_cells()
	_check("it stages exactly one cell", cells.size() == 1, str(cells.size()))
	_check(
		"and that cell is the WHOLE property",
		cells.size() == 1 and String(cells[0]["field"]) == "enemy_placements",
		"" if cells.is_empty() else String(cells[0]["field"])
	)
	# Not committed: `[CEUI-S25]` validates on commit, and `[CEUI-13]` makes the commit the
	# Undo unit. Resolved-value assertions would pass either way -- `record()` resolves the
	# staged layer -- so this asserts the transaction, per the three-layer model.
	_check("and nothing is committed yet", not document.is_dirty() and document.undo_depth() == 0)

	_check("the staged value is visible through the form", form.field("faction")["value"] == "ally")
	# The neighbours must be intact: the write duplicated the array rather than rebuilding it.
	var neighbour := FormScript.over_subject(document, _placement(1), schemas)
	_check("the other placements are untouched", neighbour.field("faction")["value"] == "enemy")
	var boss := FormScript.over_subject(document, _placement(2), schemas)
	_check("including the third", boss.field("faction")["value"] == "chapter_01")

	document.commit_edit()
	_check("one commit is one Undo step", document.undo_depth() == 1, str(document.undo_depth()))
	document.undo()
	var after := FormScript.over_subject(document, _placement(0), schemas)
	_check("and Undo puts the value back", after.field("faction")["value"] == "enemy")


func _an_item_has_no_identity_field() -> void:
	print("\n-- [CEUI-S8]'s identity refusal does not reach an item --")
	var schemas := _schemas()
	var document := _map_document()
	# The third placement's `faction` is literally "chapter_01", the map's id. On a RECORD
	# the identity field is derived as the one mirroring the document key, and firing that
	# derivation on an item would refuse a legal bulk edit with a reason about rewriting
	# references -- an item's only identity is its index, which no rename touches.
	var form := FormScript.over_subject(document, _placement(2), schemas)
	var field := form.field("faction")
	_check("a field equal to the record id is not an item's identity", not bool(field["identity"]))
	_check("so it stays bulk-editable", bool(field["bulk_editable"]), String(field["bulk_reason"]))

	# ...and the record case is unchanged: the map's own `id` IS its identity.
	var record_form := FormScript.over(document, "chapter_01", schemas)
	_check("while a record's id is still refused", bool(record_form.field("id")["identity"]))


func _the_table_over_placements_is_one_undo_step() -> void:
	print("\n-- [CEUI-S23] the canvas selection reaches the EXISTING table --")
	var schemas := _schemas()
	var document := _map_document()
	var table := BulkTableScript.over_subjects(
		document, [_placement(0), _placement(1), _placement(2)], schemas
	)
	_check("the table is active over three items", table.is_active() and table.size() == 3)
	_check(
		"and reports no record ids, because these are not records", table.record_ids().is_empty()
	)

	var offered: Array[String] = []
	for column in table.columns():
		offered.append(String(column["name"]))
	offered.sort()
	_check(
		"it offers the common scalars only",
		offered == (["faction", "is_boss"] as Array[String]),
		str(offered)
	)
	var refused: Array[String] = []
	for entry in table.refused_columns():
		refused.append(String(entry["name"]))
	_check("and NAMES the reference it refuses", refused.has("ai_profile"), str(refused))
	_check("and the structured ones", refused.has("unit") and refused.has("tile"), str(refused))
	_check("with a reason on each", not String(table.refused_columns()[0]["reason"]).is_empty())

	var faction_column := {}
	for column in table.columns():
		if String(column["name"]) == "faction":
			faction_column = column
	_check("faction disagrees, so it is mixed", bool(faction_column["mixed"]))
	# Mixed carries NO value: a placeholder equal to one item's value would flatten the
	# others on the next commit while every value assertion still passed.
	_check("and carries no value", faction_column["value"] == null)

	var outcome := table.set_value("faction", "ally")
	_check("the bulk edit is accepted", bool(outcome["accepted"]), String(outcome["reason"]))
	_check("across all three", int(outcome["staged"]) == 3, str(outcome["staged"]))
	# THE ATOMICITY ARGUMENT: three items in one property collapse to ONE staged cell,
	# because each write reads back the array the previous one staged.
	_check(
		"staged as ONE cell",
		document.staged_cells().size() == 1,
		str(document.staged_cells().size())
	)
	document.commit_edit()
	_check("and one Undo step", document.undo_depth() == 1, str(document.undo_depth()))

	var after := BulkTableScript.over_subjects(
		document, [_placement(0), _placement(1), _placement(2)], schemas
	)
	for column in after.columns():
		if String(column["name"]) == "faction":
			_check(
				"every item took the value", not bool(column["mixed"]) and column["value"] == "ally"
			)


func _a_selection_of_two_kinds_names_its_refusal() -> void:
	print("\n-- [EPUX-02] an empty table says what would fill it --")
	var schemas := _schemas()
	var document := _map_document()
	# A placement is an object of five fields; a deployment tile is `[x, y]`. Nothing in
	# common, which is a refusal the author can act on rather than a table that failed.
	var table := BulkTableScript.over_subjects(
		document,
		[_placement(0), SubjectScript.for_item("chapter_01", "player_start_tiles", 0)],
		schemas
	)
	_check("the table is active", table.is_active())
	_check("but offers no columns", table.columns().is_empty())
	_check(
		"and says why",
		table.refusal_reason() == BulkTableScript.NO_COMMON_FIELDS_REASON,
		table.refusal_reason()
	)
	var outcome := table.set_value("faction", "ally")
	_check("a write into it is refused with the same reason", not bool(outcome["accepted"]))
	_check("and nothing is staged", not document.has_staged_edit())

	var good := BulkTableScript.over_subjects(document, [_placement(0), _placement(1)], schemas)
	_check("while a homogeneous selection has no refusal", good.refusal_reason() == "")


func _a_mark_with_no_fields_says_so() -> void:
	print("\n-- a deployment tile is described, and has nothing to edit --")
	var schemas := _schemas()
	var document := _map_document()
	var form := FormScript.over_subject(
		document, SubjectScript.for_item("chapter_01", "player_start_tiles", 1), schemas
	)
	# `has_schema()` and `has_fields()` say different things and the surface needs both:
	# "no schema registered" would send an author looking for a schema that is present.
	_check("the tile's schema IS registered", form.has_schema())
	_check("and it has no fields of its own", not form.has_fields() and form.fields().is_empty())
	var outcome := form.set_value("faction", "ally")
	_check("writing a field into it is refused", not bool(outcome["accepted"]))
	_check("with the reason", String(outcome["reason"]) != "", String(outcome["reason"]))


func _the_grouped_shape_addresses_through_its_group() -> void:
	print("\n-- the grouped objectives shape is ONE kind, with the group as an address --")
	var schemas := _schemas()
	var document := _map_document()
	var subject := SubjectScript.for_item("chapter_01", "victory_conditions", 1, "players")
	var form := FormScript.over_subject(document, subject, schemas)
	_check("the form resolves through the group", form.field("type")["value"] == "seize")
	# `type` carries the `objective_condition` vocabulary, so it is a reference and the
	# table refuses it -- derived, not restated for the grouped shape.
	_check("its type is a reference", form.kind_of("type") == FormScript.FIELD_REFERENCE)

	var outcome := form.set_value("turns", 5)
	_check(
		"an edit inside a group is accepted", bool(outcome["accepted"]), String(outcome["reason"])
	)
	var cells := document.staged_cells()
	_check(
		"and stages the whole grouped property",
		cells.size() == 1 and String(cells[0]["field"]) == "victory_conditions"
	)
	var reread := FormScript.over_subject(document, subject, schemas)
	_check("the value lands in the right group entry", int(reread.field("turns")["value"]) == 5)
	var neighbour := FormScript.over_subject(
		document, SubjectScript.for_item("chapter_01", "victory_conditions", 0, "players"), schemas
	)
	_check("and not in its neighbour", not neighbour.field("turns")["is_set"])
	_check(
		"a group that is not there does not resolve",
		not SubjectScript.is_resolvable(
			document, SubjectScript.for_item("chapter_01", "victory_conditions", 0, "enemies")
		)
	)


func _a_commit_that_changes_a_length_drops_the_selection() -> void:
	print("\n-- index addressing is only honest while the shape is --")
	var document := _map_document()
	var selection: Array = [_placement(0), _placement(2)]
	var lengths := SubjectScript.capture_lengths(document, selection)

	# A VALUE-only commit leaves every index naming what it named.
	var form := FormScript.over_subject(document, _placement(0), _schemas())
	form.set_value("faction", "ally")
	document.commit_edit()
	_check(
		"a value edit keeps the selection",
		SubjectScript.re_derive(document, selection, lengths).size() == 2
	)

	# A commit that REMOVES an item moves every index after it. Keeping the in-range
	# survivors would silently retarget the author's selection with no error anywhere.
	var trimmed: Array = (document.value("chapter_01", "enemy_placements", []) as Array).duplicate(
		true
	)
	trimmed.remove_at(0)
	document.stage("chapter_01", "enemy_placements", trimmed)
	document.commit_edit()
	var kept := SubjectScript.re_derive(document, selection, lengths)
	_check(
		"a length change drops the whole selection into that property",
		kept.is_empty(),
		str(kept.size())
	)

	# The property being gone is the same answer, reached differently.
	document.stage("chapter_01", "enemy_placements", null)
	document.commit_edit()
	_check(
		"and so does the property going away",
		SubjectScript.re_derive(document, selection, lengths).is_empty()
	)


func _the_shell_routes_a_canvas_selection() -> void:
	print("\n-- [CEUI-S23] one subject to the form, many to the table --")
	var schemas := _schemas()
	var shell := ShellScript.new()
	shell.set_schemas(schemas)
	var document := _map_document()
	shell.open_document(document.id, document.kind, document.records(), document.title)

	shell.set_subject_selection([_placement(1)])
	var form := shell.inspector_form()
	_check("one subject opens the Inspector over it", form != null and form.is_item_subject())
	_check("on the addressed item", form != null and form.field("tile")["value"] == [3, 2])
	_check("and no table", shell.bulk_table() == null)

	shell.set_subject_selection([_placement(0), _placement(1)])
	_check("two subjects open the table", shell.bulk_table() != null)
	# Not a degenerate case to paper over: the ruling routes it to the table, and a form
	# showing the first of two is the mixed-value state it refused to build twice.
	_check("and close the form", shell.inspector_form() == null)
	_check("the table's size is the selection", shell.bulk_table().size() == 2)
	# `EW-6`: the status bar answers "how many things will this edit touch".
	_check(
		"the status bar counts the subjects",
		int(shell.status_bar_state()["selection_count"]) == 2,
		str(shell.status_bar_state()["selection_count"])
	)

	# THE TWO SELECTIONS ARE EXCLUSIVE, in both directions.
	shell.record_selector().select("chapter_01")
	_check(
		"a canvas selection cleared the record selection",
		shell.record_selector().selected_ids().size() == 1
	)
	shell.set_subject_selection([_placement(0)])
	_check("and setting one again clears it", shell.record_selector().selected_ids().is_empty())
	shell.clear_subject_selection()
	_check("cleared, the record route is back", shell.subject_selection().is_empty())

	# A commit routed through the shell re-derives, so a selection cannot outlive the edit
	# that invalidated it no matter who committed.
	shell.set_subject_selection([_placement(0), _placement(2)])
	var live := shell.documents().active()
	var trimmed: Array = (live.value("chapter_01", "enemy_placements", []) as Array).duplicate(true)
	trimmed.remove_at(0)
	live.stage("chapter_01", "enemy_placements", trimmed)
	shell.commit_active_edit()
	_check(
		"the shell drops a selection its own commit invalidated",
		shell.subject_selection().is_empty(),
		str(shell.subject_selection().size())
	)


func _a_canvas_selection_converts_to_subjects() -> void:
	print("\n-- the canvas already publishes the address; this reads it --")
	var schemas := _schemas()
	var document := _map_document()
	var canvas := MapCanvasScript.new()
	var layers: Array[Dictionary] = []
	for layer in schemas.map_layers(1):
		var row := (layer as Dictionary).duplicate(true)
		row["visible"] = true
		row["locked"] = false
		layers.append(row)
	var properties: Dictionary = schemas.schema_for("map_data", 1).get("properties", {})
	canvas.set_map(document, "chapter_01", layers, properties)

	# Tile [3, 3] carries the boss placement.
	var marks := canvas.select_tile(Vector2i(3, 3))
	_check("the canvas found the mark", marks.size() == 1, str(marks.size()))
	var subject := SubjectScript.from_mark("chapter_01", marks[0])
	_check(
		"which converts to the item's address",
		SubjectScript.key(subject) == SubjectScript.key(_placement(2))
	)
	var form := FormScript.over_subject(document, subject, schemas)
	_check("and the form over it is the boss placement", bool(form.field("is_boss")["value"]))

	# A refresh of the SAME map keeps the selection: every commit refreshes the surface, and
	# a selection that cleared itself there could never be the subject of the next edit.
	canvas.set_map(document, "chapter_01", layers, properties)
	_check("a refresh of the same record keeps the selection", canvas.selection().size() == 1)


func _the_screen_keeps_the_canvas_under_the_table() -> void:
	print("\n-- the surface: both were found by rendering, not by asserting --")
	var screen: Control = preload("res://scenes/ui/CampaignEditorScreen.tscn").instantiate()
	root.add_child(screen)
	await process_frame

	var shell: CampaignEditorShell = screen.shell()
	shell.set_schemas(_schemas())
	shell.set_working_copy({"id": "draft", "label": "Draft"})
	var source := _map_document()
	shell.open_document("maps", "map_data", source.records(), "Maps")
	shell.record_selector().focus("chapter_01")
	shell.workspaces().activate("maps")
	shell.layer_selector().focus("units")
	screen.rebuild()
	await process_frame

	var canvas_panel: Control = screen.get_node(
		"Shell/Body/Workspace/Centre/DocumentColumns/Document/MapCanvas"
	)
	var bulk_panel: Control = screen.get_node(
		"Shell/Body/Workspace/Centre/DocumentColumns/Document/BulkTable"
	)
	var bulk_tree: Tree = screen.get_node(
		"Shell/Body/Workspace/Centre/DocumentColumns/Document/BulkTable/Columns"
	)
	var refused: Label = screen.get_node(
		"Shell/Body/Workspace/Centre/DocumentColumns/Document/BulkTable/Refused"
	)
	var heading: Label = screen.get_node("Shell/Body/Workspace/Inspector/Heading")
	_check("the canvas is up", canvas_panel.visible)

	# ONE mark: the Inspector shows the placement, which is the defect this row closes.
	shell.set_subject_selection([_placement(2)])
	screen.rebuild()
	await process_frame
	_check("one mark heads the Inspector with the mark", heading.text.contains("Enemy Placements"))
	_check("and not with the map alone", heading.text != "chapter_01")
	_check("and opens no table", not bulk_panel.visible)

	# TWO marks: the table opens and THE CANVAS STAYS. A record-list selection still takes
	# the column, but a canvas selection cannot -- it is the surface the author selected on.
	shell.set_subject_selection([_placement(0), _placement(2)])
	screen.rebuild()
	await process_frame
	_check("two marks open the table", bulk_panel.visible)
	_check("without taking the canvas away", canvas_panel.visible)
	_check("and the table draws its rows", bulk_tree.visible)

	# NO COMMON FIELDS: the refusal is named and the empty grid is NOT drawn.
	shell.set_subject_selection(
		[_placement(0), SubjectScript.for_item("chapter_01", "player_start_tiles", 0)]
	)
	screen.rebuild()
	await process_frame
	_check(
		"a selection of two kinds names its refusal", refused.text.contains("no fields in common")
	)
	_check("and draws no empty grid", not bulk_tree.visible)
	_check("while the canvas is still there", canvas_panel.visible)

	screen.queue_free()
	await process_frame
