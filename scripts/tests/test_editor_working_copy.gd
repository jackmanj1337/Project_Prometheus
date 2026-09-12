extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_editor_working_copy.gd
#
# `EDITOR-WORKING-COPY-ENTRY-POINT-2026-09-07`: `[CEUI-S9]`'s working copy, its writer,
# `EW-10`'s entry precondition, and the two ruled entry points (`[CEUI-S13]` main menu,
# `[CEUI-S22]` the library's *Edit a copy*).
#
# THE ASSERTIONS THAT CARRY THE RULINGS, and that nothing else can catch:
#
#   * THE INSTALLED PACK IS UNTOUCHED AFTER AN IMPORT AND AFTER A SAVE (`[CEUI-S9]`,
#     `CL-ADV-01`). Asserted by reading the installed manifest and a document back after
#     both, because "the editor never writes there" is a claim about paths not taken, and
#     the only way to see it is to look at the bytes that were supposed to stay still.
#   * THE WORKING COPY HAS ITS OWN IDENTITY, AND IT IS THE ONE THAT ACTIVATES (call 1).
#     A Test launch that came up as the installed `<id>/<version>` would pass every
#     "did it activate" assertion; what fails is comparing `active_package_identity()` to
#     the draft's, which is exactly the comparison a save's provenance depends on.
#   * THE FINGERPRINT IS COMPUTED FROM THE COPY, NOT CARRIED. It is EQUAL at import --
#     the copy has identical content -- and DIVERGES on the first save. Asserting only
#     the first would pass for an implementation that copied the source's and never
#     recomputed it, which is the same masquerade one field over.
#   * A WRITE OUTSIDE THE WORKING COPY IS REFUSED, AND SAYS WHICH RULE IT BROKE. Proven by
#     pointing a writer at a working copy whose root IS the installed library: every write
#     is refused with the installed-pack reason rather than succeeding quietly.
#   * THE WRITER NEVER DELETES. A record set that omits an id leaves that document alone,
#     because "not in this set" and "the author deleted it" are indistinguishable to a
#     writer and only one of them is recoverable.
#   * ENTRY REFUSES ON A LIVE PACKAGE AND DOES NOT DEACTIVATE IT (`EW-10`, `[CEUI-S13]`).
#     Deactivating would be the entry transition `[CEUI-S13]` removed, so the package must
#     still be active after the refusal -- an assertion that a "helpful" fix would break.
#   * THE AUTOSAVE SANDBOX IS A DIFFERENT ROOT (`[CEUI-S3]`, `[CEUI-S9]` call 3). The
#     hazard runs from the editor INTO player slots, so the assertion is that the player
#     root gains nothing while the editor session writes.
#   * *EDIT A COPY* IS ABSENT FROM THE EMBEDDED LIBRARY AND PRESENT ON THE MAIN MENU'S
#     (`[CEUI-S22]`). Both instances are built and compared, because a default-on flag
#     satisfies the "present" half and silently breaks the half the ruling recommended.
#   * NO SURFACE BUT THE MAIN MENU REFERENCES THE EDITOR SCENE. `[CEUI-S22]` says no
#     pause-menu or in-run entry exists "and none may be added"; a scan is the only thing
#     that can notice one being added later.
#   * THE PRODUCTION VALIDATOR IS THE ONE THAT RUNS (`DLUX-15`, `CL-ADV-02` via
#     `[CEUI-S25]`). Asserted by committing a record the pack loader rejects and seeing
#     the same rule id the loader would raise, and by an unregistered kind reporting
#     "no validator" rather than clean.

const WorkingCopyScript = preload("res://scripts/editor/EditorWorkingCopy.gd")
const PackWriterScript = preload("res://scripts/editor/EditorPackWriter.gd")
const EntryScript = preload("res://scripts/editor/EditorEntry.gd")
const RegistryScript = preload("res://scripts/resources/CampaignPackRegistry.gd")
const RulesScript = preload("res://scripts/validation/ValidationRules.gd")
const EditorScene = preload("res://scenes/ui/CampaignEditorScreen.tscn")
const LibraryScene = preload("res://scenes/ui/CampaignLibraryScreen.tscn")

const FIXTURE := "res://test_fixtures/campaign_packs/two_map_skirmish"
const SOURCE_ID := "two_map_skirmish"
const SOURCE_VERSION := "1.0"

## Everything this suite writes lives here, so a run can be told apart from the profile's
## real library and saves -- which is the same separation the code under test exists for.
const WORK := "user://test_editor_working_copy"

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Editor Working Copy and Entry Points Test ===")

	_the_import_copies_and_leaves_the_installed_pack_alone()
	_the_working_copy_has_its_own_identity()
	_the_fingerprint_is_the_copys_own()
	_a_save_lands_in_the_draft_and_reads_back()
	_a_new_record_gains_a_catalogue_entry()
	_the_writer_never_deletes()
	_a_draft_cannot_claim_a_sibling_draft()
	_a_write_outside_the_working_copy_is_refused()
	_the_validator_is_the_production_one()
	# Autoloads are children of `root` only after the first frame, so everything below
	# this line awaits one. A suite that reads them in `_init()` finds nulls and reports
	# "the autoload is present" as a failure of the autoload rather than of its own timing.
	await process_frame
	_entry_refuses_a_live_package_without_deactivating_it()
	_a_test_launch_activates_the_working_copy_identity()
	_the_editor_session_writes_to_its_own_save_root()
	await _edit_a_copy_is_absent_from_the_embedded_library()
	await _the_main_menu_entry_opens_the_editor_without_a_working_copy()
	await _the_library_entry_opens_the_editor_on_the_copy()
	_no_surface_but_the_main_menu_reaches_the_editor()

	_cleanup()
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % label)
	else:
		_failed += 1
		print("  FAIL: %s%s" % [label, ("  [%s]" % detail) if detail != "" else ""])


# ---- fixtures ----


## An installed library holding one build of the shipped two-map fixture, at the
## fingerprint-bearing layout a current install produces.
func _install_fixture() -> String:
	var storage := WORK.path_join("packs")
	_remove_tree(storage)
	var errors: Array[String] = []
	var catalogue := Tier2Catalogue.load_campaign_pack(FIXTURE, errors)
	if catalogue == null:
		return ""
	var destination := RegistryScript.build_path(
		storage, SOURCE_ID, SOURCE_VERSION, catalogue.content_fingerprint()
	)
	_copy_tree(FIXTURE, destination)
	return storage


func _fresh_working_copy() -> EditorWorkingCopy:
	var storage := _install_fixture()
	_remove_tree(WORK.path_join("drafts"))
	var working_copy := WorkingCopyScript.new(WORK.path_join("drafts"), storage)
	working_copy.import_from_installed(SOURCE_ID, SOURCE_VERSION)
	return working_copy


func _cleanup() -> void:
	_remove_tree(WORK)


# ---- `[CEUI-S9]` the working copy ----


func _the_import_copies_and_leaves_the_installed_pack_alone() -> void:
	print("\n-- [CEUI-S9] the editor imports a COPY and never edits the installed pack --")
	var storage := _install_fixture()
	_check("the fixture installs", not storage.is_empty())
	if storage.is_empty():
		return
	_remove_tree(WORK.path_join("drafts"))
	var working_copy := WorkingCopyScript.new(WORK.path_join("drafts"), storage)
	var result = working_copy.import_from_installed(SOURCE_ID, SOURCE_VERSION)
	_check(
		"the import succeeds",
		result.imported,
		"" if result.errors.is_empty() else String(result.errors[0])
	)
	if not result.imported:
		return
	_check(
		"the copy lives under the drafts root, not the library",
		(
			working_copy.contains(working_copy.path())
			and not working_copy.is_installed_path(working_copy.path())
		)
	)
	_check(
		"the drafts root is not inside the installed library",
		not working_copy.is_installed_path(working_copy.drafts_root())
	)
	var installed_path := RegistryScript.resolve_installed_path(storage, SOURCE_ID, SOURCE_VERSION)
	var installed_manifest := _read_json(installed_path.path_join("manifest.json"))
	_check(
		"the installed manifest still carries the original id",
		String(installed_manifest.get("id", "")) == SOURCE_ID
	)
	_check(
		"the installed pack still reads as itself",
		not RegistryScript.new(storage).refresh().is_empty()
	)


func _the_working_copy_has_its_own_identity() -> void:
	print("\n-- [CEUI-S9] call 1: the copy is a distinct identity, never a masquerade --")
	var working_copy := _fresh_working_copy()
	var identity := working_copy.identity()
	_check("the working copy is open", working_copy.is_open())
	_check(
		"the draft id is not the installed id",
		(
			String(identity.get("package_id", "")) != SOURCE_ID
			and String(identity.get("package_id", "")).begins_with(SOURCE_ID)
		)
	)
	_check(
		"the version is carried unchanged",
		String(identity.get("package_version", "")) == SOURCE_VERSION
	)
	_check(
		"the identity remembers the build it was copied from",
		String(identity.get("source", {}).get("package_id", "")) == SOURCE_ID
	)
	var manifest := _read_json(working_copy.path().path_join("manifest.json"))
	_check(
		"the copy's manifest carries the forked id",
		manifest.get("id", "") == identity["package_id"]
	)
	_check("forked_from names the original", String(manifest.get("forked_from", "")) == SOURCE_ID)
	_check("a working copy is a draft", String(manifest.get("authoring_status", "")) == "draft")
	# The catalogue must still parse under the new id, or the draft cannot be tested or
	# exported and the fork has produced an unreadable pack.
	_check("the copy reads back as a pack", working_copy.load_catalogue() != null)


func _the_fingerprint_is_the_copys_own() -> void:
	print("\n-- the fingerprint is COMPUTED from the copy, so an edit moves it --")
	var storage := _install_fixture()
	var errors: Array[String] = []
	var source_catalogue := Tier2Catalogue.load_campaign_pack(FIXTURE, errors)
	_remove_tree(WORK.path_join("drafts"))
	var working_copy := WorkingCopyScript.new(WORK.path_join("drafts"), storage)
	working_copy.import_from_installed(SOURCE_ID, SOURCE_VERSION)
	var imported := String(working_copy.identity().get("content_fingerprint", ""))
	_check(
		"a fresh copy has the source's fingerprint, because it has the source's content",
		imported == source_catalogue.content_fingerprint()
	)
	var records := working_copy.records("class")
	var first := String(records.keys()[0])
	var edited: Dictionary = records[first]
	edited["display_name"] = "Edited Skirmisher"
	PackWriterScript.new(working_copy).write("class", {first: edited})
	var reopened := WorkingCopyScript.new(WORK.path_join("drafts"), storage)
	reopened.adopt(working_copy.path())
	_check(
		"after a save the copy's fingerprint has moved",
		String(reopened.identity().get("content_fingerprint", "")) != imported
	)
	_check(
		"and the installed build's fingerprint has not",
		Tier2Catalogue.load_campaign_pack(FIXTURE, errors).content_fingerprint() == imported
	)


# ---- the save writer ----


func _a_save_lands_in_the_draft_and_reads_back() -> void:
	print("\n-- [CEUI-S6]: the shell publishes records and the writer owns the bytes --")
	var working_copy := _fresh_working_copy()
	var records := working_copy.records("class")
	_check("the working copy yields the pack's records", not records.is_empty())
	var first := String(records.keys()[0])
	var edited: Dictionary = records[first]
	edited["display_name"] = "Edited Skirmisher"
	var result = PackWriterScript.new(working_copy).write("class", {first: edited})
	_check(
		"the write succeeds",
		result.written,
		"" if result.errors.is_empty() else String(result.errors[0])
	)
	_check("it wrote one document", result.paths.size() == 1)
	_check("and left the catalogue alone", not result.catalogue_updated)
	var reread := working_copy.records("class")
	_check(
		"the edit is readable back through the catalogue",
		String(reread.get(first, {}).get("display_name", "")) == "Edited Skirmisher"
	)


func _a_new_record_gains_a_catalogue_entry() -> void:
	print("\n-- a record the catalogue has never seen becomes reachable, not orphaned --")
	var working_copy := _fresh_working_copy()
	var records := working_copy.records("class")
	var first := String(records.keys()[0])
	var minted: Dictionary = (records[first] as Dictionary).duplicate(true)
	minted["id"] = "editor_minted_class"
	var result = PackWriterScript.new(working_copy).write("class", {"editor_minted_class": minted})
	_check(
		"the write succeeds",
		result.written,
		"" if result.errors.is_empty() else String(result.errors[0])
	)
	_check("the catalogue was rewritten", result.catalogue_updated)
	_check(
		"the new record is discoverable", working_copy.records("class").has("editor_minted_class")
	)
	_check("and the pack still parses", working_copy.load_catalogue() != null)


func _the_writer_never_deletes() -> void:
	print("\n-- a record missing from a save is not a deletion --")
	var working_copy := _fresh_working_copy()
	var records := working_copy.records("class")
	_check("the fixture has more than one class", records.size() > 1)
	var kept := String(records.keys()[0])
	var omitted := String(records.keys()[1])
	PackWriterScript.new(working_copy).write("class", {kept: records[kept]})
	_check("the omitted record is still there", working_copy.records("class").has(omitted))


func _a_write_outside_the_working_copy_is_refused() -> void:
	print("\n-- [CEUI-S9]: the editor has NO path that writes into the installed root --")
	var storage := _install_fixture()
	# A working copy whose drafts root IS the library: every path it composes is inside
	# the installed root, so every write must be refused. This is the arrangement a
	# careless caller would produce, and the containment check is what catches it.
	var trap := WorkingCopyScript.new(storage, storage)
	trap.adopt(RegistryScript.resolve_installed_path(storage, SOURCE_ID, SOURCE_VERSION))
	_check("the trap working copy adopted the installed build", trap.is_open())
	var records := trap.records("class")
	var first := String(records.keys()[0]) if not records.is_empty() else ""
	var result = PackWriterScript.new(trap).write("class", {first: records.get(first, {})})
	_check("the write is refused", not result.written)
	_check(
		"and the refusal names the installed pack",
		(
			not result.errors.is_empty()
			and String(result.errors[0]).contains("installed campaign packages")
		),
		"" if result.errors.is_empty() else String(result.errors[0])
	)
	var installed := RegistryScript.resolve_installed_path(storage, SOURCE_ID, SOURCE_VERSION)
	_check(
		"the installed document is untouched",
		(
			String(_read_json(installed.path_join("data/skirmisher.json")).get("id", ""))
			== "skirmisher"
		)
	)


func _a_draft_cannot_claim_a_sibling_draft() -> void:
	print("\n-- [CEUI-S9]: one working copy cannot write through another --")
	var storage := _install_fixture()
	_remove_tree(WORK.path_join("drafts"))
	var first := WorkingCopyScript.new(WORK.path_join("drafts"), storage)
	var first_result = first.import_from_installed(SOURCE_ID, SOURCE_VERSION)
	var second := WorkingCopyScript.new(WORK.path_join("drafts"), storage)
	var second_result = second.import_from_installed(SOURCE_ID, SOURCE_VERSION)
	_check("the first working copy imports", first_result.imported)
	_check("the sibling working copy imports", second_result.imported)
	if not first_result.imported or not second_result.imported:
		return
	_check("the first copy contains its own root", first.contains(first.path()))
	_check("the first copy does not contain its sibling root", not first.contains(second.path()))


func _the_validator_is_the_production_one() -> void:
	print("\n-- [CEUI-S25]/DLUX-15: the editor SCHEDULES the pack loader's own validators --")
	var working_copy := _fresh_working_copy()
	var records := working_copy.records("class")
	var first := String(records.keys()[0])
	var document := EditorDocument.open("class", "class", records, "Classes")
	var report: ValidationReport = WorkingCopyScript.document_validator("class").call(document)
	_check("a clean document reports nothing", report.is_empty(), str(report.size()))
	# An id the pack loader rejects, chosen as an EMPTY STRING rather than a non-string:
	# `_validate_registered_entity` compares with `String(document["id"])`, and Godot's
	# `String()` constructor is a runtime error on an int, so a wrong-typed id would test
	# the engine's error handling instead of the validator's.
	document.stage(first, "id", "")
	document.commit_edit(WorkingCopyScript.document_validator("class"))
	var after: ValidationReport = WorkingCopyScript.document_validator("class").call(document)
	_check("an edit the pack loader would reject is reported", not after.is_empty())
	_check(
		"under the loader's own rule id",
		not after.messages(ValidationGate.ACTIVATION, RulesScript.SEVERITY_ERROR).is_empty()
	)
	var unknown: ValidationReport = WorkingCopyScript.document_validator("not_a_content_kind").call(
		document
	)
	_check("an unregistered kind reports 'no validator', never clean", not unknown.is_empty())


# ---- `EW-10` / `[CSA-28]` (f) the entry precondition ----


func _entry_refuses_a_live_package_without_deactivating_it() -> void:
	print("\n-- EW-10: entry ASSERTS that nothing is active, and refuses rather than ending it --")
	var data_manager := root.get_node_or_null("DataManager")
	_check("the DataManager autoload is present", data_manager != null)
	if data_manager == null:
		return
	var previous: RefCounted = data_manager.capture_content_session()
	var storage := _install_fixture()
	var installed := RegistryScript.resolve_installed_path(storage, SOURCE_ID, SOURCE_VERSION)
	_check(
		"nothing is active to begin with", bool(EntryScript.precondition(data_manager)["allowed"])
	)
	var activated: bool = data_manager.activate_campaign_package(
		installed, SOURCE_ID, SOURCE_VERSION
	)
	_check("the fixture activates", activated)
	if activated:
		var gate := EntryScript.precondition(data_manager)
		_check("entry is refused while a package is active", not bool(gate["allowed"]))
		_check("with a reason an author can act on", not String(gate["reason"]).is_empty())
		_check(
			"and the refusal did NOT end the session",
			String(data_manager.active_package_identity()["package_id"]) == SOURCE_ID
		)
	data_manager.deactivate_campaign_package()
	_check(
		"entry is allowed once content is deactivated",
		bool(EntryScript.precondition(data_manager)["allowed"])
	)
	data_manager.restore_content_session(previous)


func _a_test_launch_activates_the_working_copy_identity() -> void:
	print("\n-- [CEUI-S9] call 1: a Test launch activates the COPY, under the copy's identity --")
	var data_manager := root.get_node_or_null("DataManager")
	if data_manager == null:
		return
	var previous: RefCounted = data_manager.capture_content_session()
	data_manager.deactivate_campaign_package()
	var working_copy := _fresh_working_copy()
	var outcome := EntryScript.activate_for_test(data_manager, working_copy)
	_check(
		"the working copy activates", bool(outcome["activated"]), String(outcome.get("reason", ""))
	)
	if bool(outcome["activated"]):
		var live: Dictionary = data_manager.active_package_identity()
		_check(
			"and the live identity IS the working copy",
			String(live["package_id"]) == String(working_copy.identity()["package_id"])
		)
		_check(
			"never the installed pack it was copied from", String(live["package_id"]) != SOURCE_ID
		)
	EntryScript.deactivate_after_test(data_manager)
	_check(
		"ending the test leaves nothing active",
		String(data_manager.active_package_identity()["package_id"]).is_empty()
	)
	data_manager.restore_content_session(previous)


func _the_editor_session_writes_to_its_own_save_root() -> void:
	print("\n-- [CEUI-S3]/[CEUI-S9] call 3: the editor session cannot reach player slots --")
	var save_manager := root.get_node_or_null("SaveManager")
	_check("the SaveManager autoload is present", save_manager != null)
	if save_manager == null:
		return
	var player_root := WORK.path_join("player_saves")
	_remove_tree(player_root)
	DirAccess.make_dir_recursive_absolute(player_root)
	var original := String(save_manager.save_dir)
	save_manager.configure_save_dir_for_tests(player_root)
	var working_copy := _fresh_working_copy()
	var restored := EntryScript.sandbox_saves(save_manager, working_copy)
	_check("the sandbox is inside the working copy", working_copy.contains(save_manager.save_dir))
	_check(
		"and is not the player's save root",
		String(save_manager.save_dir).simplify_path() != player_root.simplify_path()
	)
	var handle := FileAccess.open(save_manager.get_index_path(), FileAccess.WRITE)
	if handle != null:
		handle.store_string("{}")
		handle.close()
	_check(
		"an editor session write lands in the sandbox",
		FileAccess.file_exists(
			working_copy.session_save_dir().path_join(save_manager.INDEX_FILENAME)
		)
	)
	_check(
		"and the player's root gained nothing",
		not FileAccess.file_exists(player_root.path_join(save_manager.INDEX_FILENAME))
	)
	EntryScript.restore_saves(save_manager, restored)
	_check(
		"restoring puts the player's root back",
		String(save_manager.save_dir).simplify_path() == player_root.simplify_path()
	)
	save_manager.configure_save_dir_for_tests(original)


# ---- `[CEUI-S13]` / `[CEUI-S22]` the two entry points ----


func _edit_a_copy_is_absent_from_the_embedded_library() -> void:
	print("\n-- [CEUI-S22]: the action is on the MAIN-MENU library and on no other --")
	var embedded: Control = LibraryScene.instantiate()
	var main_menu_instance: Control = LibraryScene.instantiate()
	root.add_child(embedded)
	root.add_child(main_menu_instance)
	await process_frame
	main_menu_instance.editor_entry_enabled = true
	main_menu_instance.open()
	embedded.open()
	var embedded_button: Button = embedded.get_node("Panel/VBox/BtnEditCopy")
	var menu_button: Button = main_menu_instance.get_node("Panel/VBox/BtnEditCopy")
	_check("the embedded library does not offer Edit a copy", not embedded_button.visible)
	_check("the main-menu library does", menu_button.visible)
	_check("and it defaults to off", not embedded.editor_entry_enabled)
	embedded.queue_free()
	main_menu_instance.queue_free()


func _the_main_menu_entry_opens_the_editor_without_a_working_copy() -> void:
	print("\n-- [CEUI-S13]: the main-menu entry opens the MODE; Test and Export stay gated --")
	var screen: Control = EditorScene.instantiate()
	root.add_child(screen)
	await process_frame
	screen.open()
	_check("the editor is showing", screen.visible)
	_check("with no working copy", not screen.shell().has_working_copy())
	var gated := 0
	for action in screen.shell().header_actions():
		if String(action["id"]) in ["test", "export"]:
			gated += 1 if not bool(action["available"]) else 0
			_check(
				"'%s' explains why it is unavailable" % action["id"],
				not String(action["reason"]).is_empty()
			)
	_check("Test and Export are both gated", gated == 2)
	screen.queue_free()


func _the_library_entry_opens_the_editor_on_the_copy() -> void:
	print("\n-- [CEUI-S22]: Edit a copy opens the editor ON the imported working copy --")
	var working_copy := _fresh_working_copy()
	var screen: Control = EditorScene.instantiate()
	root.add_child(screen)
	await process_frame
	screen.open_working_copy(working_copy)
	_check("the shell now holds a working copy", screen.shell().has_working_copy())
	_check(
		"the status bar names the draft",
		(
			String(screen.shell().status_bar_state()["working_copy"])
			== String(working_copy.identity()["package_id"])
		)
	)
	var available := 0
	for action in screen.shell().header_actions():
		if String(action["id"]) in ["test", "export"] and bool(action["available"]):
			available += 1
	_check("Test and Export are available", available == 2)
	# The end-to-end path this row exists to close: a document opened from the working
	# copy, edited, saved, and read back off disk.
	var document: EditorDocument = screen.open_kind("class")
	_check("a category opens as a document", document != null)
	if document != null:
		var first := String(document.record_ids()[0])
		document.stage(first, "display_name", "Saved From The Editor")
		document.commit_edit(WorkingCopyScript.document_validator("class"))
		screen.save_active_document()
		_check(
			"Ctrl+S wrote it into the working copy",
			(
				String(working_copy.records("class").get(first, {}).get("display_name", ""))
				== "Saved From The Editor"
			)
		)
	screen.queue_free()


func _no_surface_but_the_main_menu_reaches_the_editor() -> void:
	print("\n-- [CEUI-S22]: no pause-menu or in-run entry exists, and none may be added --")
	var referencing: Array[String] = []
	for path in _scene_paths("res://scenes"):
		var handle := FileAccess.open(path, FileAccess.READ)
		if handle == null:
			continue
		var text := handle.get_as_text()
		handle.close()
		if text.contains("CampaignEditorScreen.tscn"):
			referencing.append(path.get_file())
	_check(
		"exactly one scene instances the editor, and it is the main menu",
		referencing == ["MainMenu.tscn"],
		", ".join(referencing)
	)


# ---- helpers ----


func _scene_paths(root_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(root_path)
	if dir == null:
		return out
	for file_name in dir.get_files():
		if file_name.ends_with(".tscn"):
			out.append(root_path.path_join(file_name))
	for sub_name in dir.get_directories():
		out.append_array(_scene_paths(root_path.path_join(sub_name)))
	out.sort()
	return out


func _read_json(path: String) -> Dictionary:
	var handle := FileAccess.open(path, FileAccess.READ)
	if handle == null:
		return {}
	var parsed: Variant = JSON.parse_string(handle.get_as_text())
	handle.close()
	return parsed if parsed is Dictionary else {}


func _copy_tree(source: String, destination: String) -> void:
	DirAccess.make_dir_recursive_absolute(destination)
	var dir := DirAccess.open(source)
	if dir == null:
		return
	for file_name in dir.get_files():
		DirAccess.copy_absolute(source.path_join(file_name), destination.path_join(file_name))
	for sub_name in dir.get_directories():
		_copy_tree(source.path_join(sub_name), destination.path_join(sub_name))


func _remove_tree(target: String) -> void:
	var dir := DirAccess.open(target)
	if dir == null:
		return
	for file_name in dir.get_files():
		DirAccess.remove_absolute(target.path_join(file_name))
	for sub_name in dir.get_directories():
		_remove_tree(target.path_join(sub_name))
	DirAccess.remove_absolute(target)
