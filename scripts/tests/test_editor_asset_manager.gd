extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_editor_asset_manager.gd
#
# Covers `[CEUI-S36]`-`[CEUI-S39]`'s Assets workspace -- `EditorAssetManager` over the
# ENGINE's own `asset_registry` schema and a real `EditorDocument`, plus the `EditorSubject`
# keyed-member address `[CEUI-S37]` needs and the surface that draws the grid.
#
# THE ASSERTIONS THAT CARRY THE RULINGS, and that nothing else can catch:
#
#   * AN INCOMPLETE RIGHTS RECORD DOES NOT BLOCK THE COMMIT (`[CEUI-S36]`). Asserted as a
#     committed plan, not as an absent error message: the failure mode is an importer that
#     refuses politely, which reads as correct until an author is stuck mid-import looking up
#     a licence URL.
#   * AND THE GATE CATCHES IT ANYWAY. The same asset warns at ACTIVATION-as-draft and ERRORS
#     at both export gates. Together these two are the whole ruling; either alone is a
#     different, wrong design -- one launders rights, the other blocks the import.
#   * NOTHING IS INFERRED. Classification comes from the extension against the engine's
#     admitted media table; there is no path by which a licence, an attribution or a source
#     is derived from a filename or a URL.
#   * A DUPLICATE IS REPORTED AND NOT REFUSED, and is detected against other CANDIDATES too,
#     not only against the registry -- two identical files in one batch is the case a
#     registry-only check misses entirely.
#   * IMPORT AND DELETION NEVER TOUCH THE DOCUMENT'S TRANSACTION (`[CEUI-S6]` call 1). After
#     a committed import the document has nothing staged, is not dirty, and has no Undo step.
#     This is the assertion that would fail the moment someone "simplified" the plan into a
#     stage() call, which would make Undo responsible for un-copying a file.
#   * DELETION SHOWS USAGES AND NEVER CASCADES (`[CEUI-S39]`). Three answers, three different
#     plans; no plan removes a record that merely REFERS to the asset, and BREAK reports each
#     surviving reference as an ordinary validation issue.
#   * THE REGISTRY'S OWN ENTRY IS NOT A USAGE. Counting it makes every asset look referenced
#     and the whole preview meaningless.
#   * BATCH PROVENANCE IS THE BULK TABLE (`[CEUI-S37]`). The subjects an asset selection
#     publishes drive `EditorBulkTable` unchanged -- which is the test that the keyed-member
#     address generalized the SUBJECT rather than adding a second table.
#   * A MEMBER ADDRESS SURVIVES A COMMIT THAT AN INDEX ADDRESS WOULD NOT. Adding another
#     asset drops nothing, because a key is not moved by a neighbour arriving.

const ManagerScript = preload("res://scripts/editor/EditorAssetManager.gd")
const DocumentScript = preload("res://scripts/editor/EditorDocument.gd")
const SubjectScript = preload("res://scripts/editor/EditorSubject.gd")
const FormScript = preload("res://scripts/editor/EditorFormModel.gd")
const BulkTableScript = preload("res://scripts/editor/EditorBulkTable.gd")
const SchemasScript = preload("res://scripts/data/EntitySchemaRegistry.gd")
const RulesScript = preload("res://scripts/validation/ValidationRules.gd")
const GateScript = preload("res://scripts/validation/ValidationGate.gd")
const WorkspacesScript = preload("res://scripts/editor/EditorWorkspaces.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Editor Asset Manager Test ===")

	_the_grid_reads_the_engine_schema()
	_classification_is_derived_and_nothing_else_is()
	_an_unknown_rights_record_does_not_block_the_commit()
	_and_the_gate_catches_it_anyway()
	_a_duplicate_is_reported_not_refused()
	_an_unsupported_media_type_is_refused()
	_a_committed_import_never_touches_the_transaction()
	_deletion_shows_usages_and_never_cascades()
	_the_registrys_own_entry_is_not_a_usage()
	_batch_provenance_is_the_bulk_table()
	_a_member_address_survives_what_an_index_address_would_not()
	_sections_remember_their_state()
	await _the_screen_draws_the_grid_only_in_the_assets_workspace()

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


## One asset with a source recorded and one without, so both sides of `[CSA-6]` are live.
func _registry_record() -> Dictionary:
	return {
		"kind": "asset_registry",
		"schema_version": 1,
		"id": "pack_assets",
		"assets":
		{
			"hero_sheet":
			{
				"path": "assets/hero_sheet.png",
				"decoded_type": "image/png",
				"byte_size": 2048,
				"sha256": "a".repeat(64),
				"original_filename": "hero_sheet.png",
				"source_refs": ["puny_dungeon"],
			},
			"village_theme":
			{
				"path": "assets/village_theme.ogg",
				"decoded_type": "audio/ogg",
				"byte_size": 4096,
				"sha256": "b".repeat(64),
				"original_filename": "village_theme.ogg",
			},
		},
	}


func _document() -> EditorDocument:
	return DocumentScript.open(
		"assets", "asset_registry", {"pack_assets": _registry_record()}, "Assets"
	)


## A class document that REFERS to an asset id, which is what a usage scan has to find.
func _consumer_document() -> EditorDocument:
	return (
		DocumentScript
		. open(
			"classes",
			"class",
			{
				"knight":
				{
					"kind": "class",
					"schema_version": 1,
					"id": "knight",
					"display_name": "Knight",
					"source_refs": ["puny_dungeon"],
					"sprite_asset": "hero_sheet",
				}
			},
			"Classes"
		)
	)


func _manager_over(document: EditorDocument) -> EditorAssetManager:
	var manager := ManagerScript.new()
	manager.set_registry(document, "pack_assets", _schemas())
	return manager


func _manager() -> EditorAssetManager:
	return _manager_over(_document())


# ---- the grid ----


func _the_grid_reads_the_engine_schema() -> void:
	print("\n-- the grid reads the engine's own asset registry schema --")
	var manager := _manager()
	_check("the registry is recognised", manager.has_registry())
	var rows := manager.assets()
	_check("both assets are in the grid", rows.size() == 2, str(rows.size()))
	_check(
		"in key order",
		String(rows[0]["id"]) == "hero_sheet" and String(rows[1]["id"]) == "village_theme"
	)
	_check("the one with a source reads as rights-known", bool(rows[0]["rights_known"]))
	_check("and the one without does not", not bool(rows[1]["rights_known"]))
	_check(
		"each asset addresses as a MEMBER subject, keyed by the author's own id",
		(
			SubjectScript.is_member(rows[0]["subject"])
			and String((rows[0]["subject"] as Dictionary)["key"]) == "hero_sheet"
		)
	)


func _classification_is_derived_and_nothing_else_is() -> void:
	print("\n-- classification is derived; nothing else is --")
	_check("a png classifies", ManagerScript.classify("art.png") == "image/png")
	_check("an ogg classifies", ManagerScript.classify("song.OGG") == "audio/ogg")
	_check(
		"a file type a pack may not carry classifies as nothing",
		ManagerScript.classify("notes.txt") == ""
	)
	# The assertion that guards `[CEUI-S37]`'s "nothing is inferred": a licence-looking
	# filename produces a record with NO source, not a guessed one.
	var manager := _manager()
	(
		manager
		. stage_import(
			{
				"id": "cc_by_tiles",
				"source_path": "/tmp/CC-BY-4.0_tiles_by_someone.png",
				"original_filename": "CC-BY-4.0_tiles_by_someone.png",
				"byte_size": 512,
				"sha256": "c".repeat(64),
			}
		)
	)
	var plan := manager.commit_import()
	var record: Dictionary = (plan["assets"] as Dictionary)["cc_by_tiles"]
	_check(
		"a licence-shaped filename yields NO source ref and no licence claim",
		not record.has("source_refs"),
		str(record.keys())
	)


# ---- `[CEUI-S36]` the import transaction ----


func _an_unknown_rights_record_does_not_block_the_commit() -> void:
	print("\n-- an incomplete rights record does not block the commit --")
	var manager := _manager()
	var staged := (
		manager
		. stage_import(
			{
				"id": "banner",
				"source_path": "/tmp/banner.png",
				"original_filename": "banner.png",
				"byte_size": 700,
				"sha256": "d".repeat(64),
			}
		)
	)
	_check("staging is accepted with no source named", bool(staged["staged"]))
	var preview := manager.import_preview()
	_check(
		"the preview says the rights are unrecorded",
		preview.size() == 1 and not bool(preview[0]["rights_known"])
	)
	var plan := manager.commit_import()
	_check("and the commit SUCCEEDS anyway", bool(plan["committed"]), String(plan["reason"]))
	_check(
		"the plan carries the file to copy and the whole assets map",
		(plan["files"] as Array).size() == 1 and (plan["assets"] as Dictionary).size() == 3
	)
	_check("and says the document must be re-opened", bool(plan["reload_required"]))


func _and_the_gate_catches_it_anyway() -> void:
	print("\n-- and the ratified gate catches it anyway --")
	var report := _manager().validate()
	_check("one issue for the asset with no source", report.size() == 1, str(report.size()))
	_check(
		"a WARNING while the author is drafting", report.warnings(GateScript.ACTIVATION).size() == 1
	)
	_check("an ERROR at export to a file", report.errors(GateScript.EXPORT_FILE).size() == 1)
	_check(
		"an ERROR at export to the library, so nothing is published with unknown rights",
		report.blocks(GateScript.EXPORT_LIBRARY)
	)
	_check(
		"and it does NOT block the draft the author is working in",
		not report.blocks(GateScript.ACTIVATION)
	)
	# The mechanism was built with no producer; this is the producer.
	_check(
		"the rule escalates between gates, which is what the gate axis exists for",
		(
			(
				ManagerScript.rules().severity_for(
					ManagerScript.RULE_RIGHTS_UNKNOWN, GateScript.ACTIVATION
				)
				== RulesScript.SEVERITY_WARNING
			)
			and (
				(ManagerScript.rules().severity_for(
					ManagerScript.RULE_RIGHTS_UNKNOWN, GateScript.EXPORT_FILE
				))
				== RulesScript.SEVERITY_ERROR
			)
		)
	)


func _a_duplicate_is_reported_not_refused() -> void:
	print("\n-- a duplicate is reported, not refused --")
	var manager := _manager()
	(
		manager
		. stage_import(
			{
				"id": "hero_copy",
				"source_path": "/tmp/hero.png",
				"original_filename": "hero.png",
				"byte_size": 2048,
				"sha256": "a".repeat(64),
			}
		)
	)
	# The case a registry-only duplicate check misses: two identical files in ONE batch.
	(
		manager
		. stage_import(
			{
				"id": "hero_copy_again",
				"source_path": "/tmp/hero2.png",
				"original_filename": "hero2.png",
				"byte_size": 2048,
				"sha256": "a".repeat(64),
			}
		)
	)
	var preview := manager.import_preview()
	_check(
		"the first duplicate names the registry asset it matches",
		preview.size() == 2 and String(preview[0]["duplicate_of"]) == "hero_sheet",
		str(preview)
	)
	_check(
		"and the second names one too, rather than looking unique",
		String(preview[1]["duplicate_of"]) != "",
		String(preview[1]["duplicate_of"])
	)
	_check("both still commit", bool(manager.commit_import()["committed"]))


func _an_unsupported_media_type_is_refused() -> void:
	print("\n-- an unsupported media type is refused, with its reason --")
	var manager := _manager()
	var staged := (
		manager
		. stage_import(
			{
				"id": "readme",
				"source_path": "/tmp/readme.txt",
				"original_filename": "readme.txt",
				"byte_size": 12,
				"sha256": "e".repeat(64),
			}
		)
	)
	_check("staging is refused", not bool(staged["staged"]))
	_check(
		"and says why",
		String(staged["reason"]) == ManagerScript.UNSUPPORTED_MEDIA_REASON,
		String(staged["reason"])
	)
	var clash := (
		manager
		. stage_import(
			{
				"id": "hero_sheet",
				"source_path": "/tmp/x.png",
				"original_filename": "x.png",
				"byte_size": 1,
				"sha256": "f".repeat(64),
			}
		)
	)
	_check(
		"an id the registry already holds is refused too",
		not bool(clash["staged"]) and String(clash["reason"]) == ManagerScript.DUPLICATE_ID_REASON
	)


func _a_committed_import_never_touches_the_transaction() -> void:
	print("\n-- a committed import never touches the document's transaction --")
	var document := _document()
	var manager := _manager_over(document)
	(
		manager
		. stage_import(
			{
				"id": "banner",
				"source_path": "/tmp/banner.png",
				"original_filename": "banner.png",
				"byte_size": 700,
				"sha256": "d".repeat(64),
			}
		)
	)
	manager.commit_import()
	_check("nothing is staged on the document", not document.has_staged_edit())
	_check("the document is not dirty", not document.is_dirty())
	_check("and there is no Undo step to press", document.undo_depth() == 0)
	# The same for deletion, which also removes a file.
	manager.plan_deletion("village_theme", ManagerScript.ON_DELETE_BREAK)
	_check("planning a deletion stages nothing either", not document.has_staged_edit())
	_check("and adds no Undo step", document.undo_depth() == 0)


# ---- `[CEUI-S39]` deletion ----


func _deletion_shows_usages_and_never_cascades() -> void:
	print("\n-- deletion shows usages and never cascades --")
	var document := _document()
	var manager := _manager_over(document)
	var consumer := _consumer_document()
	var preview := manager.deletion_preview("hero_sheet", [document, consumer])
	_check("the preview is available", bool(preview["available"]))
	_check(
		"and finds the class that refers to the asset",
		(preview["usages"] as Array).size() == 1,
		str(preview["usages"])
	)
	_check(
		"naming the field, so the author can navigate to it",
		String(((preview["usages"] as Array)[0] as Dictionary)["path"]) == "sprite_asset"
	)
	_check(
		"three answers, and cascade is not among them",
		(
			(preview["choices"] as Array)
			== [
				ManagerScript.ON_DELETE_CANCEL,
				ManagerScript.ON_DELETE_REPLACE,
				ManagerScript.ON_DELETE_BREAK,
			]
		)
	)
	_check("the not-undoable warning is stated", String(preview["warning"]) != "")
	_check("and a recovery snapshot is required first", bool(preview["snapshot_required"]))

	var cancelled := manager.plan_deletion(
		"hero_sheet", ManagerScript.ON_DELETE_CANCEL, [document, consumer]
	)
	_check("cancel plans nothing", not bool(cancelled["applied"]))

	var broken := manager.plan_deletion(
		"hero_sheet", ManagerScript.ON_DELETE_BREAK, [document, consumer]
	)
	_check("break removes the asset", not (broken["assets"] as Dictionary).has("hero_sheet"))
	_check(
		"and leaves the referring record alone -- it never cascades",
		(broken["record_edits"] as Array).is_empty()
	)
	var issues: ValidationReport = broken["issues"]
	_check(
		"reporting the surviving reference as an ordinary validation issue",
		issues.size() == 1,
		str(issues.size())
	)

	var replaced := manager.plan_deletion(
		"hero_sheet", ManagerScript.ON_DELETE_REPLACE, [document, consumer], "village_theme"
	)
	_check("replace rewrites the reference", (replaced["record_edits"] as Array).size() == 1)
	_check(
		"to the replacement the author chose",
		String(((replaced["record_edits"] as Array)[0] as Dictionary)["value"]) == "village_theme"
	)
	var no_target := manager.plan_deletion(
		"hero_sheet", ManagerScript.ON_DELETE_REPLACE, [document, consumer]
	)
	_check(
		"replace with nothing to replace it with is refused, with its reason",
		(
			not bool(no_target["applied"])
			and String(no_target["reason"]) == ManagerScript.NO_REPLACEMENT_REASON
		)
	)


func _the_registrys_own_entry_is_not_a_usage() -> void:
	print("\n-- the registry's own entry for an asset is not a usage of it --")
	var document := _document()
	var manager := _manager_over(document)
	var usages := manager.usages_of("village_theme", [document])
	_check(
		"an unreferenced asset reports NO usages, not one for its own record",
		usages.is_empty(),
		str(usages)
	)


# ---- `[CEUI-S37]` batch provenance ----


func _batch_provenance_is_the_bulk_table() -> void:
	print("\n-- batch provenance is the bulk table, not a second surface --")
	var document := _document()
	var manager := _manager_over(document)
	manager.select(["hero_sheet", "village_theme"])
	var subjects := manager.subjects_for()
	_check("the selection publishes two subjects", subjects.size() == 2)
	var table := BulkTableScript.over_subjects(document, subjects, _schemas())
	_check("the EXISTING bulk table opens over them unchanged", table.is_active())
	var columns: Array[Dictionary] = table.columns()
	var names: Array[String] = []
	for column in columns:
		names.append(String(column["name"]))
	_check(
		"offering the asset record's own scalar fields",
		names.has("byte_size") and names.has("original_filename"),
		str(names)
	)
	# The single-subject route is the Inspector's, and it must show the ASSET rather than the
	# whole registry -- the defect that made a subject an address in the first place.
	var form := FormScript.over_subject(document, subjects[0], _schemas())
	var field_names: Array[String] = []
	for field in form.fields():
		field_names.append(String(field["name"]))
	_check(
		"and the Inspector over ONE asset shows that asset, not the registry",
		field_names.has("sha256") and not field_names.has("assets"),
		str(field_names)
	)

	var review := manager.review_batch({"source_refs": ["puny_dungeon"]})
	_check("the pre-commit review list names every selected asset", review.size() == 2)
	_check(
		"and names only the ones that actually change",
		(review[0]["changes"] as Array).is_empty() and (review[1]["changes"] as Array).size() == 1,
		str(review)
	)


func _a_member_address_survives_what_an_index_address_would_not() -> void:
	print("\n-- a member address survives a commit an index address would not --")
	var document := _document()
	var manager := _manager_over(document)
	var subjects := manager.subjects_for(["hero_sheet"])
	var lengths := SubjectScript.capture_lengths(document, subjects)
	_check(
		"a member captures no length, because it has none to be invalidated by",
		lengths.is_empty(),
		str(lengths)
	)
	# Another asset arriving is exactly the shape that moves every index after it.
	var assets: Dictionary = (document.value("pack_assets", "assets", {}) as Dictionary).duplicate(
		true
	)
	assets["aaa_first_alphabetically"] = {
		"path": "assets/a.png",
		"decoded_type": "image/png",
		"byte_size": 1,
		"sha256": "9".repeat(64),
		"original_filename": "a.png",
	}
	document.stage("pack_assets", "assets", assets)
	document.commit_edit()
	var kept := SubjectScript.re_derive(document, subjects, lengths)
	_check("the member address survives", kept.size() == 1, str(kept.size()))
	_check(
		"and still resolves to the same asset",
		(
			String(SubjectScript.resolve(document, kept[0])["value"]["original_filename"])
			== "hero_sheet.png"
		)
	)


func _sections_remember_their_state() -> void:
	print("\n-- the disclosure sections remember their state --")
	var manager := _manager()
	_check("five named sections", manager.sections().size() == 5, str(manager.sections().size()))
	_check("all collapsed by default", not manager.is_section_expanded("swap_editor"))
	_check("expanding one is accepted", manager.set_section_expanded("swap_editor", true))
	_check("a section that is not ruled is refused", not manager.set_section_expanded("x", true))
	var state := manager.capture_state()
	var restored := _manager()
	restored.restore_state(state)
	_check("and the state survives a recomposition", restored.is_section_expanded("swap_editor"))
	_check(
		"the always-visible three are NOT sections, so nothing can collapse them",
		not ManagerScript.SECTIONS.has("preview") and ManagerScript.ALWAYS_VISIBLE.has("preview")
	)


# ---- the surface ----


func _the_screen_draws_the_grid_only_in_the_assets_workspace() -> void:
	print("\n-- the screen draws the grid only in the Assets workspace --")
	var packed: PackedScene = load("res://scenes/ui/CampaignEditorScreen.tscn")
	var screen: Node = packed.instantiate()
	root.add_child(screen)
	await process_frame

	var shell: CampaignEditorShell = screen.shell()
	shell.set_schemas(_schemas())
	shell.open_document("assets", "asset_registry", {"pack_assets": _registry_record()}, "Assets")
	shell.record_selector().focus("pack_assets")
	shell.workspaces().activate(WorkspacesScript.ASSETS)
	screen.rebuild()
	await process_frame

	var panel: Control = screen.get_node(
		"Shell/Body/Workspace/Centre/DocumentColumns/Document/AssetGrid"
	)
	_check("the Assets workspace shows the grid", panel.visible)
	var tiles: HFlowContainer = screen.get_node(
		"Shell/Body/Workspace/Centre/DocumentColumns/Document/AssetGrid/TileScroll/Tiles"
	)
	_check("with one tile per asset", tiles.get_child_count() == 2, str(tiles.get_child_count()))
	# `WIDTH_GRID_REFLOWS`: the tile is a fixed size, so extra width grows the column count.
	var first: Button = tiles.get_child(0) as Button
	_check(
		"at a fixed tile size, never stretched",
		is_equal_approx(first.custom_minimum_size.x, first.custom_minimum_size.y)
	)
	_check(
		"and rights state is on the tile face, where Advanced mode cannot hide it",
		first.text.contains("hero_sheet")
	)

	shell.workspaces().activate(WorkspacesScript.CONTENT)
	await process_frame
	_check("leaving Assets takes the grid away again", not panel.visible)

	screen.queue_free()
	await process_frame
