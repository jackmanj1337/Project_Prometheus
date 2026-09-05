extends SceneTree
# Durable end-to-end probes for the v0.7.16 return. Optional --returned <json>
# drives the same checks with the original packet, without committing player data.
const Registry = preload("res://scripts/resources/CampaignPackRegistry.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const Integrity = preload("res://scripts/save/SaveIntegrity.gd")
const Migration = preload("res://scripts/save/SaveMigrationService.gd")
const PACK_ID := "v076_migration_fixture"
const WORK := "user://test_v0716_return"
var failed := 0
var passed := 0


func _init() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String, detail: Variant = "") -> void:
	if ok:
		passed += 1
		print("OK  ", message)
	else:
		failed += 1
		print("FAIL ", message, " ", detail)


func _run() -> void:
	var output: Array = []
	var built := OS.execute(
		OS.get_executable_path(),
		PackedStringArray(
			[
				"--headless",
				"--path",
				ProjectSettings.globalize_path("res://"),
				"--script",
				"res://scripts/tools/build_migration_fixtures.gd",
				"--",
				"--out",
				ProjectSettings.globalize_path(WORK.path_join("fixtures"))
			]
		),
		output,
		true
	)
	_check(built == 0, "the shipped migration fixtures rebuild", output)
	if built != 0:
		quit(1)
		return
	var dm: Node = root.get_node("DataManager")
	var sm: Node = root.get_node("SaveManager")
	var gs: Node = root.get_node("GameState")
	var cm: Node = root.get_node("CampaignManager")
	Installer._remove_tree(WORK.path_join("saves"))
	var original: RefCounted = dm.capture_content_session()
	sm.configure_save_dir_for_tests(WORK.path_join("saves"))
	var pack1 := Registry.installed_path(Registry.DEFAULT_STORAGE_ROOT, PACK_ID, "1.0.0")
	var pack2 := Registry.installed_path(Registry.DEFAULT_STORAGE_ROOT, PACK_ID, "2.0.0")
	_copy_tree(WORK.path_join("fixtures/src-v1").path_join(PACK_ID), pack1)
	_copy_tree(WORK.path_join("fixtures/src-v2").path_join(PACK_ID), pack2)
	_check(dm.select_tier2_campaign_source(pack1, PACK_ID, "1.0.0"), "v1 activates")
	gs.load_roster_resources(
		dm.get_campaign_pack_roster("skirmish_team"), "campaign_pack_roster", "skirmish_team"
	)
	cm.start_campaign("two_map_skirmish")
	for slot_class in gs.campaign_rules.save_slot_classes:
		slot_class["count"] = 1
	var save: RefCounted = gs.capture_campaign_save("Returned campaign")
	var document: Dictionary = Integrity.stamp(save.to_dict())
	var args := OS.get_cmdline_user_args()
	var returned := args.find("--returned")
	if returned >= 0 and returned + 1 < args.size():
		document = JSON.parse_string(FileAccess.get_file_as_string(args[returned + 1]))
	var portable := WORK.path_join("portable.json")
	_write(portable, document)
	cm.end_campaign()
	dm.deactivate_campaign_package()
	var inspected: Dictionary = sm.inspect_portable_save(portable)
	_check(
		inspected.ok and inspected.content_state == "ready",
		"installed inactive pack inspects ready",
		inspected.errors
	)
	var imported: Dictionary = sm.import_portable_save(portable, "returned", true)
	_check(imported.ok, "installed inactive pack imports successfully", imported.errors)
	_check(not dm.has_weapon("training_sword"), "import restores the inactive content session")
	_check(
		not sm.save_slot("same_version_overflow", SaveData.from_dict(document)),
		"the same package version still enforces its slot cap"
	)
	var source_bytes := FileAccess.get_file_as_string(sm.get_slot_path("returned"))
	var summaries: Array[Dictionary] = Registry.new(Registry.DEFAULT_STORAGE_ROOT).refresh()
	var summary: Dictionary = {}
	for row in summaries:
		if row.package_id == PACK_ID and row.package_version == "2.0.0":
			summary = row
	if summary.is_empty():
		_check(false, "v2 is registered")
		quit(1)
		return
	var ids: Dictionary = summary.content_ids
	var exists := func(family: String, id: String) -> bool:
		return ids.has(family) and ids[family].has(id)
	var declaration: Dictionary = summary.save_migrations[0]
	var before_index := FileAccess.get_file_as_string(sm.get_index_path())
	sm._test_fail_before_index_replace = true
	var rejected: Dictionary = sm.migrate_save_into_slot(
		"returned", "failed_migration", PACK_ID, declaration, exists
	)
	sm._test_fail_before_index_replace = false
	_check(
		not rejected.ok and not sm.has_slot("failed_migration"),
		"failed migration transaction removes the destination"
	)
	_check(
		(
			FileAccess.get_file_as_string(sm.get_index_path()) == before_index
			and FileAccess.get_file_as_string(sm.get_slot_path("returned")) == source_bytes
		),
		"failed migration preserves source, index and Continue"
	)
	var migrated: Dictionary = sm.migrate_save_into_slot(
		"returned", "migrated", PACK_ID, declaration, exists
	)
	_check(migrated.ok, "migration commits with no active pack", migrated.errors)
	_check(not dm.has_weapon("training_sword"), "migration restores the inactive content session")
	if migrated.ok:
		var loaded: RefCounted = sm.load_slot("migrated")
		_check(loaded != null, "the migrated slot reads back")
		if loaded != null:
			for field in [
				"package_id", "package_version", "content_schema_version", "content_fingerprint"
			]:
				_check(loaded.source[field] == loaded.campaign[field], "migration mirrors " + field)
			var resumed: bool = (
				gs.configure_campaign_resume(loaded)
				if loaded.map_runtime.get("map_path", "") == ""
				else gs.configure_suspend_resume(loaded)
			)
			_check(resumed, "the migrated save resumes through GameState")
	var preview: Dictionary = Migration.preview(
		SaveData.from_dict(document), PACK_ID, declaration, exists
	)
	if preview.ok:
		var bad_identity: Dictionary = preview.save.to_dict()
		bad_identity.campaign.content_fingerprint = document.source.content_fingerprint
		_check(
			not Migration._validate_candidate_payload(bad_identity, declaration, exists).is_empty(),
			"candidate validation rejects a mismatched campaign mirror"
		)
	# A different, real content session must survive both success and rejection.
	dm.select_campaign_source("res://data")
	var previous: RefCounted = dm.capture_content_session()
	var again: Dictionary = sm.import_portable_save(portable, "returned", true)
	_check(again.ok, "import also works with unrelated content active", again.errors)
	_check(
		(
			dm.capture_content_session().weapons == previous.weapons
			and dm.capture_content_session().package_id == previous.package_id
		),
		"successful import restores unrelated content"
	)
	var invalid: RefCounted = SaveData.from_dict(document)
	var inventory: Variant = invalid.roster.units[0].inventory
	var entries: Array = inventory.entries if inventory is Dictionary else inventory
	entries[0].weapon_id = "missing_weapon_v0716"
	_check(
		not sm.save_slot("invalid", invalid), "catalogue validation rejects a truly missing weapon"
	)
	_check(
		not sm.has_slot("invalid") and dm.capture_content_session().weapons == previous.weapons,
		"rejection writes no slot and restores unrelated content"
	)
	invalid.source.content_fingerprint = "sha256:" + "0".repeat(64)
	_check(not sm.save_slot("bad_identity", invalid), "activation rejects an incorrect fingerprint")
	_check(
		dm.capture_content_session().weapons == previous.weapons,
		"activation failure also restores unrelated content"
	)
	_check(
		FileAccess.get_file_as_string(sm.get_slot_path("returned")) == source_bytes,
		"migration and load leave the source slot unchanged"
	)
	sm.delete_slot("returned")
	sm.delete_slot("migrated")
	# Save-first order: retain exactly the original document, then promote on Retry.
	Installer._remove_tree(pack1)
	Installer._remove_tree(pack2)
	var disabled: Dictionary = sm.import_portable_save(portable, "disabled", true)
	_check(
		disabled.ok and disabled.content_state == "disabled",
		"save-first import is retained disabled"
	)
	var before := FileAccess.get_file_as_string(sm.get_slot_path("disabled"))
	_copy_tree(WORK.path_join("fixtures/src-v1").path_join(PACK_ID), pack1)
	var retry: Dictionary = sm.revalidate_slot("disabled")
	_check(retry.ok and retry.content_state == "ready", "install then Retry promotes the save")
	_check(
		FileAccess.get_file_as_string(sm.get_slot_path("disabled")) == before,
		"Retry never rewrites the source document"
	)
	dm.restore_content_session(original)
	Installer._remove_tree(pack1)
	Installer._remove_tree(WORK)
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)


func _write(path: String, document: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(document))
	file.close()


func _copy_tree(source: String, destination: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination))
	var dir := DirAccess.open(source)
	for name in dir.get_files():
		DirAccess.copy_absolute(source.path_join(name), destination.path_join(name))
	for name in dir.get_directories():
		_copy_tree(source.path_join(name), destination.path_join(name))
