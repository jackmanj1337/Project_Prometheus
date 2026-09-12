extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_editor_inspector_forms.gd
#
# Covers `[CEUI-S14]`'s schema-generated Inspector form, `[CEUI-S15]`'s reference picker,
# `[CEUI-S16]`'s value origins and `[CEUI-S23]`'s bulk table -- `EditorFormModel`,
# `EditorBulkTable`, and the routing between them in `CampaignEditorShell`.
#
# THE ASSERTIONS THAT CARRY THE RULINGS, and that nothing else can catch:
#
#   * THE FORM IS THE SCHEMA AND NOTHING ELSE. `[CEUI-S14]` chose schema-generated forms so
#     that a new content kind needs no engine edit; the way that decays is a field list
#     that starts as a convenience. Asserted by comparing the form's field names against a
#     fresh `schema_for()` call, so a hand-added or hand-dropped field fails here.
#   * A REFERENCE IS NEVER BULK-EDITABLE, AND THE KIND IS DERIVED. `[CEUI-S14]` restricted
#     the table so references have exactly ONE authoring path, because a reference is the
#     one field type that can dangle. The kind comes from the property carrying a
#     `vocabulary` -- not from a list here -- so a schema that adds one moves the field out
#     of the table with no edit. Asserted on a real engine schema, not a fixture.
#   * A REFUSED COLUMN IS NAMED, NOT DROPPED. An absent column and an unavailable one look
#     identical to an author, which is the whole reason `EPUX-02` says gated-shows-disabled-
#     WITH-REASON rather than hidden.
#   * ONE BULK EDIT IS ONE UNDO STEP ACROSS EVERY SELECTED RECORD (`[CEUI-S23]` +
#     `[CEUI-13]`). The failure mode is a table that commits per record: every value is
#     correct, and Undo is then forty presses and validation forty runs of one check.
#   * MIXED IS A STATE, NOT A VALUE. A column whose records disagree reports `mixed` and a
#     null value; a placeholder equal to one record's value would silently flatten the
#     others on the next commit, and every value assertion would still pass.
#   * THE INSPECTOR RETURNS NULL FOR A MULTI-SELECTION. Not a degenerate case to paper
#     over: `[CEUI-S23]` routes it to the table, and a form that quietly showed the first
#     of forty records is the second mixed-value state the ruling refused to build.
#   * SETTING A REFERENCE TO SOMETHING THE VOCABULARY DOES NOT ADMIT IS REFUSED AT THE
#     MOMENT OF CHOOSING, with the reason -- not one commit later by the validator.

const ShellScript = preload("res://scripts/editor/CampaignEditorShell.gd")
const DocumentScript = preload("res://scripts/editor/EditorDocument.gd")
const FormScript = preload("res://scripts/editor/EditorFormModel.gd")
const BulkTableScript = preload("res://scripts/editor/EditorBulkTable.gd")
const SchemasScript = preload("res://scripts/data/EntitySchemaRegistry.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Editor Inspector Forms and Bulk Table Test ===")

	_the_form_is_the_schema_and_nothing_else()
	_field_kinds_are_derived_from_the_schema()
	_a_reference_is_chosen_from_its_vocabulary_and_refuses_anything_else()
	_an_unset_value_shows_its_origin_and_resets_to_it()
	_editing_stages_rather_than_writes()
	_the_bulk_table_offers_common_scalars_and_enums_only()
	_a_refused_column_is_named_with_its_reason()
	_one_bulk_edit_is_one_undo_step()
	_mixed_is_a_state_not_a_value()
	_the_shell_routes_one_record_to_the_form_and_many_to_the_table()
	await _the_screen_draws_the_form_and_the_table()

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


## A real `item` document, so the assertions run against the engine's own schema rather
## than a fixture that could drift from it.
func _item_document() -> EditorDocument:
	return (
		DocumentScript
		. open(
			"items",
			"item",
			{
				"potion":
				{
					"kind": "item",
					"schema_version": 1,
					"id": "potion",
					"display_name": "Potion",
					"effect_id": "heal_flat",
				},
				"elixir":
				{
					"kind": "item",
					"schema_version": 1,
					"id": "elixir",
					"display_name": "Elixir",
					"effect_id": "heal_flat",
				},
			},
			"Items"
		)
	)


func _the_form_is_the_schema_and_nothing_else() -> void:
	print("\n-- [CEUI-S14] the form is generated, never a field list --")
	var schemas := _schemas()
	var document := _item_document()
	var form := FormScript.over(document, "potion", schemas)
	_check("the form has a schema", form.has_schema())

	var drawn: Array[String] = []
	for field in form.fields():
		drawn.append(String(field["name"]))
	drawn.sort()
	var expected: Array[String] = []
	for name in schemas.schema_for("item", 1).get("properties", {}) as Dictionary:
		expected.append(String(name))
	expected.sort()
	# A hand-added or hand-dropped field fails here rather than at review.
	_check(
		"the fields are exactly the schema's properties",
		drawn == expected,
		"drawn=%d expected=%d" % [drawn.size(), expected.size()]
	)

	var required_seen := false
	for field in form.fields():
		if String(field["name"]) == "id" and bool(field["required"]):
			required_seen = true
	_check("required is read from the schema, not guessed", required_seen)

	var unschema_d := DocumentScript.open("x", "not_a_kind", {"a": {}}, "X")
	var empty := FormScript.over(unschema_d, "a", schemas)
	# An unschema'd kind gets an EMPTY form that says so, rather than invented fields.
	_check(
		"a kind with no schema reports it instead of inventing fields",
		not empty.has_schema() and empty.fields().is_empty()
	)


func _field_kinds_are_derived_from_the_schema() -> void:
	print("\n-- the four kinds come from vocabulary/enum/type, not from a list --")
	var schemas := _schemas()
	var form := FormScript.over(_item_document(), "potion", schemas)
	# `effect_id` carries `vocabulary: item_effect` in the engine schema, so it is the
	# reference case on real data rather than a fixture.
	_check(
		"a vocabulary-bearing string is a REFERENCE",
		form.kind_of("effect_id") == FormScript.FIELD_REFERENCE,
		form.kind_of("effect_id")
	)
	_check(
		"an inline enum is an ENUM",
		form.kind_of("kind") == FormScript.FIELD_ENUM,
		form.kind_of("kind")
	)
	_check(
		"a plain string is a SCALAR",
		form.kind_of("display_name") == FormScript.FIELD_SCALAR,
		form.kind_of("display_name")
	)
	# The document header declares which schema versions it admits as an inline enum, so
	# `schema_version` is an ENUM here even though its type is integer -- which is the point
	# of deriving the kind rather than branching on the type.
	_check(
		"an integer with an inline enum is an ENUM, not a scalar",
		form.kind_of("schema_version") == FormScript.FIELD_ENUM,
		form.kind_of("schema_version")
	)
	_check(
		"an array is STRUCTURED",
		form.kind_of("source_refs") == FormScript.FIELD_STRUCTURED,
		form.kind_of("source_refs")
	)

	var by_name: Dictionary = {}
	for field in form.fields():
		by_name[String(field["name"])] = field
	# The restriction is `[CEUI-S14]`'s, and it exists so a reference has exactly one
	# authoring path -- the picker -- because it is the one field type that can dangle.
	_check(
		"a reference is NOT bulk-editable",
		not bool((by_name["effect_id"] as Dictionary)["bulk_editable"])
	)
	_check(
		"and says why",
		(
			String((by_name["effect_id"] as Dictionary)["bulk_reason"])
			== FormScript.REFERENCE_NOT_BULK_REASON
		)
	)
	_check(
		"a structured field is NOT bulk-editable",
		not bool((by_name["source_refs"] as Dictionary)["bulk_editable"])
	)
	_check("an enum IS bulk-editable", bool((by_name["kind"] as Dictionary)["bulk_editable"]))
	_check(
		"a scalar IS bulk-editable", bool((by_name["display_name"] as Dictionary)["bulk_editable"])
	)
	_check("the identity field is flagged", bool((by_name["id"] as Dictionary)["identity"]))
	_check(
		"and is not bulk-editable despite being a scalar",
		not bool((by_name["id"] as Dictionary)["bulk_editable"])
	)
	_check(
		"while an ordinary scalar is not flagged",
		not bool((by_name["display_name"] as Dictionary)["identity"])
	)


func _a_reference_is_chosen_from_its_vocabulary_and_refuses_anything_else() -> void:
	print("\n-- [CEUI-S15] the picker IS the shared selector, and raw ids are not a path --")
	var schemas := _schemas()
	var document := _item_document()
	var form := FormScript.over(document, "potion", schemas)
	var selector := form.reference_selector("effect_id")
	_check("a reference field has a selector", selector != null)
	_check("it is the shared RecordSelector, not a private picker", selector is RecordSelector)
	_check(
		"its rows are the vocabulary's values",
		selector.ids() == schemas.vocabulary_values("item_effect"),
		str(selector.ids())
	)
	_check(
		"and it starts focused on the current value",
		selector.focused_id() == "heal_flat",
		selector.focused_id()
	)
	# Held, not rebuilt: `[TSV-24]` is the selector's own contract and a new instance per
	# call would drop focus on every repaint.
	_check(
		"asking twice returns the same selector", form.reference_selector("effect_id") == selector
	)
	_check("a scalar has none", form.reference_selector("display_name") == null)

	var admitted: Array[String] = schemas.vocabulary_values("item_effect")
	var accepted := form.set_value("effect_id", admitted[0])
	_check("an admitted value is accepted", bool(accepted["accepted"]))
	var refused := form.set_value("effect_id", "not_a_real_effect")
	# Refused at the moment of choosing, not one commit later by the validator.
	_check("a value the vocabulary does not admit is refused", not bool(refused["accepted"]))
	_check(
		"with a reason naming the vocabulary",
		String(refused["reason"]).contains("item_effect"),
		String(refused["reason"])
	)
	_check(
		"and the refusal staged nothing",
		String(document.value("potion", "effect_id")) == admitted[0],
		String(document.value("potion", "effect_id"))
	)


func _an_unset_value_shows_its_origin_and_resets_to_it() -> void:
	print("\n-- [CEUI-S16] two origins, never another pack --")
	var schemas := _schemas()
	var document := _item_document()
	var form := FormScript.over(document, "potion", schemas)
	var by_name: Dictionary = {}
	for field in form.fields():
		by_name[String(field["name"])] = field
	_check(
		"a value the record sets is AUTHORED",
		String((by_name["display_name"] as Dictionary)["origin"]) == FormScript.ORIGIN_AUTHORED
	)
	# No engine schema declares a `default` today, so an unset field with no template has
	# nothing to reset TO -- and offering a reset that wrote null would be worse than none.
	_check(
		"an unset field with no default and no template is UNSET",
		String((by_name["source_refs"] as Dictionary)["origin"]) == FormScript.ORIGIN_UNSET,
		String((by_name["source_refs"] as Dictionary)["origin"])
	)
	_check("and cannot be reset", not form.can_reset("source_refs"))
	var refused := form.reset("source_refs")
	_check(
		"resetting it refuses with a reason",
		not bool(refused["accepted"]) and String(refused["reason"]) != ""
	)

	# `[CEUI-S35]` ruled templates COPY-ON-CREATE, so this takes a plain copy and holds no
	# pointer back to whatever produced it -- an origin link to another pack would revive
	# exactly the overlay model `ICO` removed.
	form.set_template({"source_refs": ["template://ref"]})
	var templated := form.field("source_refs")
	_check(
		"a template supplies the origin", String(templated["origin"]) == FormScript.ORIGIN_TEMPLATE
	)
	_check(
		"and reset now works",
		form.can_reset("source_refs") and bool(form.reset("source_refs")["accepted"])
	)
	_check(
		"writing the template's value, not a null",
		document.value("potion", "source_refs") == ["template://ref"],
		str(document.value("potion", "source_refs"))
	)


func _editing_stages_rather_than_writes() -> void:
	print("\n-- every edit is a staged transaction, never a direct write --")
	var document := _item_document()
	var form := FormScript.over(document, "potion", _schemas())
	form.set_value("display_name", "Big Potion")
	# The form stages; committing is the shell's, so `[CEUI-S25]`'s validation runs once
	# per author action rather than once per keystroke.
	_check("the value is staged", document.has_staged_edit())
	_check("and readable", String(document.value("potion", "display_name")) == "Big Potion")
	_check("but the document is not dirty until it commits", not document.is_dirty())
	document.commit_edit()
	_check("committing makes it dirty", document.is_dirty())
	_check("as one undo step", document.undo_depth() == 1)


# ---- `[CEUI-S23]` the bulk table ----


func _the_bulk_table_offers_common_scalars_and_enums_only() -> void:
	print("\n-- [CEUI-S23] common fields, scalars and enums, nothing else --")
	var document := _item_document()
	var table := BulkTableScript.over(document, ["potion", "elixir"], _schemas())
	_check("the table is active over two records", table.is_active() and table.size() == 2)
	var names: Array[String] = []
	var kinds: Dictionary = {}
	for column in table.columns():
		names.append(String(column["name"]))
		kinds[String(column["name"])] = String(column["kind"])
	_check("display_name is a column", names.has("display_name"), str(names))
	_check("id -- the identity field -- is NOT", not names.has("id"), str(names))
	# The restriction is inherited from `[CEUI-S14]`, not re-decided here.
	_check("effect_id -- a reference -- is NOT", not names.has("effect_id"))
	_check("source_refs -- structured -- is NOT", not names.has("source_refs"))
	var only_scalar_and_enum := true
	for name in kinds:
		if not (kinds[name] in [FormScript.FIELD_SCALAR, FormScript.FIELD_ENUM]):
			only_scalar_and_enum = false
	_check("every column is a scalar or an enum", only_scalar_and_enum, str(kinds))

	var single := BulkTableScript.over(document, ["potion"], _schemas())
	# A table over one record is the Inspector's job; offering both would be the two-routes-
	# for-one-edit shape the ruling closed.
	_check("a selection of one is not a table", not single.is_active())
	var refused := single.set_value("display_name", "x")
	_check(
		"and editing it refuses with the reason",
		(
			not bool(refused["accepted"])
			and String(refused["reason"]) == BulkTableScript.SINGLE_SELECTION_REASON
		)
	)


func _a_refused_column_is_named_with_its_reason() -> void:
	print("\n-- a refused column is NAMED, not silently dropped --")
	var document := _item_document()
	var table := BulkTableScript.over(document, ["potion", "elixir"], _schemas())
	var refused: Dictionary = {}
	for entry in table.refused_columns():
		refused[String(entry["name"])] = entry
	_check("the reference field is listed as refused", refused.has("effect_id"))
	# An absent column and an unavailable one look identical to an author, which is why
	# `EPUX-02` says disabled-WITH-REASON rather than hidden.
	_check(
		"with the reason the form gave it",
		(
			String((refused["effect_id"] as Dictionary)["reason"])
			== FormScript.REFERENCE_NOT_BULK_REASON
		)
	)
	# `[CEUI-S8]`: an id rename offers a usage preview and a per-rename confirmation with a
	# recovery snapshot. A table cell can do none of that, and setting one id across three
	# records is the one edit the document model cannot represent -- three records answering
	# to one key. The identity field is DERIVED (the field mirroring the record's key), so
	# no content family is named to find it.
	_check("the identity field is refused too", refused.has("id"), str(refused.keys()))
	_check(
		"with the rename reason, not the reference one",
		String((refused["id"] as Dictionary)["reason"]) == FormScript.IDENTITY_NOT_BULK_REASON
	)
	_check("the structured field too", refused.has("source_refs"))
	_check(
		"with its own reason",
		(
			String((refused["source_refs"] as Dictionary)["reason"])
			== FormScript.STRUCTURED_NOT_BULK_REASON
		)
	)

	var outcome := table.set_value("effect_id", "heal_flat")
	_check("setting a refused field through the table refuses", not bool(outcome["accepted"]))
	_check(
		"with the same wording -- one refusal, one sentence",
		String(outcome["reason"]) == FormScript.REFERENCE_NOT_BULK_REASON
	)
	_check("and stages nothing", int(outcome["staged"]) == 0)


func _one_bulk_edit_is_one_undo_step() -> void:
	print("\n-- [CEUI-S23] one atomic edit over the whole selection --")
	var document := _item_document()
	var table := BulkTableScript.over(document, ["potion", "elixir"], _schemas())
	var outcome := table.set_value("display_name", "Restorative")
	_check("both records stage", bool(outcome["accepted"]) and int(outcome["staged"]) == 2)
	document.commit_edit()
	_check(
		"both took the value",
		(
			String(document.value("potion", "display_name")) == "Restorative"
			and String(document.value("elixir", "display_name")) == "Restorative"
		)
	)
	# The failure mode this catches: committing per record. Every value would be correct
	# and Undo would be N presses, with N validation runs of the same check.
	_check("as ONE undo step, not two", document.undo_depth() == 1, str(document.undo_depth()))
	document.undo()
	_check(
		"and one undo reverts both",
		(
			String(document.value("potion", "display_name")) == "Potion"
			and String(document.value("elixir", "display_name")) == "Elixir"
		)
	)


func _mixed_is_a_state_not_a_value() -> void:
	print("\n-- a column whose records disagree is MIXED, with no value --")
	var document := _item_document()
	var table := BulkTableScript.over(document, ["potion", "elixir"], _schemas())
	var by_name: Dictionary = {}
	for column in table.columns():
		by_name[String(column["name"])] = column
	_check(
		"display_name is mixed -- the two records differ",
		bool((by_name["display_name"] as Dictionary)["mixed"])
	)
	_check(
		"and the identity field is not offered at all", not by_name.has("id"), str(by_name.keys())
	)
	# A placeholder equal to one record's value would silently flatten the other on the
	# next commit, and every value assertion would still pass.
	_check("and carries NO value", (by_name["display_name"] as Dictionary)["value"] == null)
	_check(
		"but does carry the per-record values",
		((by_name["display_name"] as Dictionary)["values"] as Array).size() == 2
	)
	_check(
		"a column they agree on is not mixed", not bool((by_name["kind"] as Dictionary)["mixed"])
	)
	_check(
		"and carries the shared value", String((by_name["kind"] as Dictionary)["value"]) == "item"
	)


func _the_shell_routes_one_record_to_the_form_and_many_to_the_table() -> void:
	print("\n-- [CEUI-S23] the Inspector edits exactly one record --")
	var shell := ShellScript.new()
	shell.set_schemas(_schemas())
	(
		shell
		. open_document(
			"items",
			"item",
			{
				"potion":
				{"kind": "item", "schema_version": 1, "id": "potion", "display_name": "Potion"},
				"elixir":
				{"kind": "item", "schema_version": 1, "id": "elixir", "display_name": "Elixir"},
			},
			"Items"
		)
	)
	var records := shell.record_selector()
	_check(
		"the record list is the document's records",
		records.ids() == ["elixir", "potion"],
		str(records.ids())
	)
	_check("with no selection there is no table", shell.bulk_table() == null)

	records.select("potion")
	_check("one selected record gives a form", shell.inspector_form() != null)
	_check("and its subject is that record", shell.inspector_form().record_id() == "potion")
	_check("and still no table", shell.bulk_table() == null)

	records.select("elixir")
	# Not a degenerate case to paper over: a form that showed the first of forty records
	# would be the second mixed-value state `[CEUI-S23]` refused to build.
	_check("two selected records give NO form", shell.inspector_form() == null)
	_check("and a table instead", shell.bulk_table() != null)
	_check("over both", shell.bulk_table().size() == 2)
	# `EW-6`'s count tells an author how many things an edit will touch, which after
	# `[CEUI-S23]` is the record selection -- the tree selects a category, a place to look.
	_check(
		"the status bar counts the RECORD selection",
		int(shell.status_bar_state()["selection_count"]) == 2,
		str(shell.status_bar_state()["selection_count"])
	)


func _the_screen_draws_the_form_and_the_table() -> void:
	print("\n-- the screen draws the record list, the form and the table --")
	var screen: Control = preload("res://scenes/ui/CampaignEditorScreen.tscn").instantiate()
	root.add_child(screen)
	await process_frame

	var shell: CampaignEditorShell = screen.shell()
	shell.set_schemas(_schemas())
	shell.set_working_copy({"id": "draft", "label": "Draft"})
	(
		shell
		. open_document(
			"items",
			"item",
			{
				"potion":
				{
					"kind": "item",
					"schema_version": 1,
					"id": "potion",
					"display_name": "Potion",
					"effect_id": "heal"
				},
				"elixir":
				{
					"kind": "item",
					"schema_version": 1,
					"id": "elixir",
					"display_name": "Elixir",
					"effect_id": "heal"
				},
			},
			"Items"
		)
	)
	screen.rebuild()
	await process_frame

	var record_tree: Tree = screen.get_node(
		"Shell/Body/Workspace/Centre/DocumentColumns/Document/Records"
	)
	var drawn := 0
	var item := record_tree.get_root().get_first_child()
	while item != null:
		drawn += 1
		item = item.get_next()
	_check("the centre lists the document's records", drawn == 2, str(drawn))

	var form_box: Control = screen.get_node("Shell/Body/Workspace/Inspector/FormScroll/Form")
	shell.record_selector().select("potion")
	screen.rebuild()
	await process_frame
	_check(
		"selecting one record draws a form row per schema field",
		form_box.get_child_count() == shell.inspector_form().fields().size(),
		"%d vs %d" % [form_box.get_child_count(), shell.inspector_form().fields().size()]
	)

	var bulk_panel: Control = screen.get_node(
		"Shell/Body/Workspace/Centre/DocumentColumns/Document/BulkTable"
	)
	_check("and no bulk table", not bulk_panel.visible)
	shell.record_selector().select("elixir")
	screen.rebuild()
	await process_frame
	_check("selecting a second record opens the bulk table", bulk_panel.visible)
	_check("and empties the form", form_box.get_child_count() == 0)
	var refused_label: Label = screen.get_node(
		"Shell/Body/Workspace/Centre/DocumentColumns/Document/BulkTable/Refused"
	)
	# Named, not dropped.
	_check(
		"the refused fields are named on the surface", refused_label.text != "", refused_label.text
	)

	screen.queue_free()
	await process_frame
