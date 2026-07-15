extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_save_manager.gd
# Unified slot I/O for mid-map and between-map documents.

const SaveDataScript = preload("res://scripts/save/SaveData.gd")
const SaveManagerScript = preload("res://scripts/autoloads/SaveManager.gd")
const ImportBudgetConfig = preload("res://scripts/resources/ImportBudgets.gd")

const TEST_SAVE_DIR := "user://test_save_manager"

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== SaveManager Test ===")
	_clean_test_dir()

	var manager: Node = SaveManagerScript.new()
	manager.configure_save_dir_for_tests(TEST_SAVE_DIR)

	_test_mid_map_slot_write_and_load(manager)
	_test_mid_map_slot_rejects_bad_documents(manager)
	_test_slot_write_and_load(manager)
	_test_slot_ids_are_allow_listed(manager)
	_test_continue_routes_to_the_newest_document(manager)
	_test_completed_slots_are_records_not_continue_targets(manager)
	_test_slot_listing(manager)
	_test_slot_transaction_rolls_back_on_index_failure(manager)
	_test_portable_save_transfer_and_integrity(manager)
	_test_campaign_preference_order(manager)
	_test_slot_delete(manager)

	manager.free()
	_clean_test_dir()
	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _check(ok: bool, label: String, detail: String = "") -> void:
	if ok:
		print("OK  %s" % label)
		_passed += 1
	else:
		print("FAIL %s%s" % [label, ("" if detail == "" else " — %s" % detail)])
		_failed += 1


# --- Suspend save (mid-map) ---------------------------------------------------

func _test_mid_map_slot_write_and_load(manager: Node) -> void:
	var slot_id: String = SaveManagerScript.MID_MAP_SLOT
	var write_ok: bool = manager.save_slot(slot_id, _make_suspend_save())
	var last_played: Dictionary = manager.get_last_played()
	_check(write_ok
			and FileAccess.file_exists(manager.get_slot_path(slot_id))
			and String(last_played.get("kind", "")) == "slot"
			and String(last_played.get("slot_id", "")) == slot_id
			and manager.load_index().has("last_played"),
		"mid-map save uses the unified slot and continue pointer", str(last_played))

	var loaded: RefCounted = manager.load_slot(slot_id)
	_check(loaded != null
			and loaded.map_runtime["map_id"] == "map_001"
			and loaded.map_runtime["map_path"] == "res://data/maps/map_001_rout/map_001_data.tres"
			and loaded.map_runtime["rng"] == {"map_seed": "123", "history_hash": "456"}
			and loaded.suspend["kind"] == "map"
			and loaded.ledger.size() == 1
			and loaded.ledger[0]["entry"]["map_runtime"]["rng"] \
				== {"map_seed": "123", "history_hash": "456"},
		"mid-map slot round-trips the board and whole ledger",
		str(loaded.to_dict() if loaded != null else null))

	_check(manager.has_continue_save(), "has_continue_save tracks the mid-map slot")

	_check(manager.delete_slot(slot_id)
			and not FileAccess.file_exists(manager.get_slot_path(slot_id))
			and manager.get_last_played().is_empty(),
		"delete_slot removes the mid-map file and continue pointer")


func _test_mid_map_slot_rejects_bad_documents(manager: Node) -> void:
	var path: String = manager.get_slot_path(SaveManagerScript.MID_MAP_SLOT)
	_write_text(path, "{ not json")
	_check(manager.load_slot(SaveManagerScript.MID_MAP_SLOT) == null,
		"mid-map slot rejects invalid JSON")

	_write_text(path, JSON.stringify({"format_version": 99}, "\t", true))
	_check(manager.load_slot(SaveManagerScript.MID_MAP_SLOT) == null,
		"mid-map slot rejects an unsupported format_version")
	manager.delete_slot(SaveManagerScript.MID_MAP_SLOT)


# --- Campaign slots (between-map) ---------------------------------------------

func _test_slot_write_and_load(manager: Node) -> void:
	var write_ok: bool = manager.save_slot("autosave", _make_campaign_save(),
		"auto", "campaign_progress")
	var last_played: Dictionary = manager.get_last_played()
	_check(write_ok
			and manager.has_slot("autosave")
			and FileAccess.file_exists(manager.get_slot_path("autosave"))
			and String(last_played.get("kind", "")) == "slot"
			and String(last_played.get("slot_id", "")) == "autosave"
			and manager.load_slot("autosave").origin == "auto"
			and manager.load_slot("autosave").rule_id == "campaign_progress",
		"save_slot writes the slot file and points continue at it", str(last_played))

	var loaded: RefCounted = manager.load_slot("autosave")
	_check(loaded != null
			and loaded.campaign["campaign_id"] == "proving_grounds"
			and loaded.campaign["node_id"] == "node_02_seize"
			and loaded.campaign["cleared_nodes"] == ["node_01_rout"]
			and loaded.party["resources"]["party_gold"] == 250,
		"load_slot round-trips the campaign envelope and party",
		str(loaded.to_dict()["campaign"] if loaded != null else null))

	# The between-map save carries no live board: that absence is what routes a
	# slot load through the campaign launch path instead of a map resume.
	_check(loaded != null
			and String(loaded.map_runtime.get("map_path", "")) == ""
			and loaded.suspend.get("kind", null) == null,
		"a campaign slot carries no map_runtime or suspend block")

	_check(manager.load_slot("never_written") == null,
		"load_slot returns null for a slot that was never written")


# Slot ids become filenames, so an id outside the allow-list must be refused
# rather than sanitized — it must never resolve to a path outside the save dir.
func _test_slot_ids_are_allow_listed(manager: Node) -> void:
	_check(SaveManagerScript.is_valid_slot_id("autosave")
			and SaveManagerScript.is_valid_slot_id("slot_01")
			and SaveManagerScript.is_valid_slot_id("manual-3"),
		"plain slot ids are valid")

	_check(not SaveManagerScript.is_valid_slot_id("")
			and not SaveManagerScript.is_valid_slot_id("../../evil")
			and not SaveManagerScript.is_valid_slot_id("a/b")
			and not SaveManagerScript.is_valid_slot_id("save.json"),
		"path-escaping slot ids are refused")

	_check(not manager.save_slot("../evil", _make_campaign_save())
			and manager.get_slot_path("../evil") == ""
			and not FileAccess.file_exists("%s/../evil.json" % TEST_SAVE_DIR),
		"save_slot refuses to write through an escaping slot id")


# Continue resumes whichever unified slot was written last.
func _test_continue_routes_to_the_newest_document(manager: Node) -> void:
	# Slot was written most recently (previous test).
	var target: Dictionary = manager.get_continue_target()
	_check(String(target.get("kind", "")) == "slot"
			and String(target.get("slot_id", "")) == "autosave",
		"continue routes to the campaign slot when it is newest", str(target))

	manager.save_slot(SaveManagerScript.MID_MAP_SLOT, _make_suspend_save())
	target = manager.get_continue_target()
	_check(String(target.get("kind", "")) == "slot"
			and String(target.get("slot_id", "")) == SaveManagerScript.MID_MAP_SLOT,
		"continue routes to the mid-map slot when it is newest", str(target))

	# The pointed-at document going missing must not strand Continue on it: the
	# slot is still on disk and is still continuable.
	manager.delete_slot(SaveManagerScript.MID_MAP_SLOT)
	target = manager.get_continue_target()
	_check(String(target.get("kind", "")) == "slot"
			and String(target.get("slot_id", "")) == "autosave"
			and manager.has_continue_save(),
		"continue falls back to the surviving save when the newest is gone", str(target))


func _test_completed_slots_are_records_not_continue_targets(manager: Node) -> void:
	manager.save_slot("completed", _make_completed_save())
	var target: Dictionary = manager.get_continue_target()
	_check(String(target.get("slot_id", "")) == "autosave",
		"Continue skips a newer completed record", str(target))
	manager.delete_slot("autosave")
	_check(manager.get_continue_target().is_empty() and not manager.has_continue_save()
			and manager.list_slots().size() == 1,
		"with only completion records Continue is disabled but Load Game can list them")
	manager.save_slot("autosave", _make_campaign_save())


func _test_slot_listing(manager: Node) -> void:
	manager.save_slot("manual_01", _make_campaign_save("Manual save"))
	var rows: Array[Dictionary] = manager.list_slots()
	var ids: Array = []
	for row in rows:
		ids.append(String(row.get("slot_id", "")))
	_check(rows.size() == 3 and ids.has("autosave") and ids.has("manual_01") and ids.has("completed"),
		"list_slots returns a row per written slot", str(ids))
	_check(String(rows[0].get("slot_id", "")) == "manual_01"
			and String(rows[0].get("label", "")) == "Manual save"
			and String(rows[0].get("header", {}).get("node_id", "")) == "node_02_seize",
		"slot rows are newest first and carry the picker's label and header",
		str(rows[0]))

	# A row whose file was removed behind our back must not be offered: the picker
	# must never list a save that cannot be loaded.
	DirAccess.open(TEST_SAVE_DIR).remove("manual_01.json")
	var survivors: Array[Dictionary] = manager.list_slots()
	_check(survivors.size() == 2,
		"a slot whose file has vanished is not listed", str(survivors))
	manager.delete_slot("completed")


func _test_slot_transaction_rolls_back_on_index_failure(manager: Node) -> void:
	var old_slot: String = FileAccess.get_file_as_string(manager.get_slot_path("autosave"))
	var old_index: String = FileAccess.get_file_as_string(manager.get_index_path())
	manager._test_fail_before_index_replace = true
	var ok: bool = manager.save_slot("autosave", _make_campaign_save("Replacement"))
	manager._test_fail_before_index_replace = false
	var leftovers: Array[String] = []
	for file_name in DirAccess.open(TEST_SAVE_DIR).get_files():
		if file_name.ends_with(".tmp") or file_name.ends_with(".bak"):
			leftovers.append(file_name)
	_check(not ok
			and FileAccess.get_file_as_string(manager.get_slot_path("autosave")) == old_slot
			and FileAccess.get_file_as_string(manager.get_index_path()) == old_index
			and leftovers.is_empty(),
		"an index-stage failure preserves the prior slot/index pair and cleans staging files")


func _test_portable_save_transfer_and_integrity(manager: Node) -> void:
	var portable := TEST_SAVE_DIR.path_join("portable.json")
	var exported: Dictionary = manager.export_slot("autosave", portable)
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(portable))
	_check(exported["ok"] and String(parsed.get("integrity", {}).get("payload_hash", "")) != "" \
			and String(parsed.get("integrity", {}).get("schema_hash", "")) != "",
		"portable export writes one JSON document with both integrity hashes")
	var first_export := FileAccess.get_file_as_string(portable)
	var replacement: Dictionary = manager.export_slot("autosave", portable)
	_check(replacement["ok"] and FileAccess.get_file_as_string(portable) == first_export \
			and not FileAccess.file_exists(portable + ".bak"),
		"portable export replaces an existing artifact through staged promotion")

	var clean: Dictionary = manager.inspect_portable_save(portable)
	_check(clean["ok"] and clean["warnings"].is_empty(),
		"an untouched portable save verifies without warnings", str(clean))
	var large_warning: Dictionary = manager.inspect_portable_save(
		portable, 1, ImportBudgetConfig.portable_save_maximum_bytes())
	_check(large_warning["ok"] and large_warning["warnings"].size() == 1 \
			and "unusually large" in String(large_warning["warnings"][0]),
		"warning budget reports an unusually large valid save without rejecting it",
		str(large_warning))
	var warned_for_size: Dictionary = manager.import_portable_save(
		portable, "large_import", false, 1, ImportBudgetConfig.portable_save_maximum_bytes())
	_check(not warned_for_size["ok"] \
			and warned_for_size.get("requires_acknowledgement", false) \
			and not manager.has_slot("large_import"),
		"large-save warning uses the normal acknowledgement boundary")
	var accepted_large: Dictionary = manager.import_portable_save(
		portable, "large_import", true, 1, ImportBudgetConfig.portable_save_maximum_bytes())
	_check(accepted_large["ok"] and manager.has_slot("large_import"),
		"acknowledging a size warning imports the schema-validated save")
	manager.delete_slot("large_import")
	var malformed_large := TEST_SAVE_DIR.path_join("malformed_large.json")
	_write_text(malformed_large, "{ malformed payload padded above warning }")
	var malformed_result: Dictionary = manager.import_portable_save(
		malformed_large, "malformed_import", false, 1, 1024)
	_check(not malformed_result["ok"] \
			and not malformed_result.get("requires_acknowledgement", false) \
			and not malformed_result["errors"].is_empty() \
			and not manager.has_slot("malformed_import"),
		"large-file warning never bypasses JSON/schema rejection")

	parsed["campaign"]["node_id"] = "tampered_node"
	_write_text(portable, JSON.stringify(parsed, "\t", true))
	var warned: Dictionary = manager.import_portable_save(portable, "imported_01")
	_check(not warned["ok"] and warned.get("requires_acknowledgement", false) \
			and warned["warnings"].size() == 2 and not manager.has_slot("imported_01"),
		"tampered protected data requires acknowledgement before import", str(warned))
	var accepted: Dictionary = manager.import_portable_save(portable, "imported_01", true)
	_check(accepted["ok"] and manager.has_slot("imported_01") \
			and manager.load_slot("imported_01").campaign["node_id"] == "tampered_node",
		"acknowledged tampering warns-and-continues into a normal slot", str(accepted))

	var zip_path := TEST_SAVE_DIR.path_join("pack.zip")
	var zip_file := FileAccess.open(zip_path, FileAccess.WRITE)
	zip_file.store_buffer(PackedByteArray([0x50, 0x4b, 0x03, 0x04]))
	zip_file.close()
	var sniffed: Dictionary = manager.inspect_portable_save(zip_path)
	_check(not sniffed["ok"] and sniffed["artifact_kind"] == "campaign_pack",
		"portable importer sniffs ZIP and routes campaign packages to Manage Campaigns")

	var oversized := TEST_SAVE_DIR.path_join("oversized.json")
	var oversized_file := FileAccess.open(oversized, FileAccess.WRITE)
	oversized_file.seek(ImportBudgetConfig.portable_save_maximum_bytes())
	oversized_file.store_8(0)
	oversized_file.close()
	var oversized_result: Dictionary = manager.inspect_portable_save(oversized)
	_check(not oversized_result["ok"] and oversized_result["errors"].any(
		func(error): return "size limit" in String(error)),
		"portable importer rejects oversized artifacts before buffering")
	manager.delete_slot("imported_01")


func _test_campaign_preference_order(manager: Node) -> void:
	manager.record_campaign_imported({"campaign_id": "imported_campaign",
		"package_id": "pack", "package_version": "1.0"})
	var imported_only: Array[Dictionary] = manager.campaign_preference_candidates()
	manager.record_campaign_started({"campaign_id": "played_campaign"})
	var with_started: Array[Dictionary] = manager.campaign_preference_candidates()
	_check(imported_only.size() == 1 \
			and imported_only[0]["campaign_id"] == "imported_campaign" \
			and with_started.size() == 2 \
			and with_started[0]["campaign_id"] == "played_campaign" \
			and with_started[1]["campaign_id"] == "imported_campaign",
		"campaign preference orders last-started before most-recently-imported")


func _test_slot_delete(manager: Node) -> void:
	_check(manager.delete_slot("autosave")
			and not manager.has_slot("autosave")
			and manager.list_slots().is_empty(),
		"delete_slot removes the file and its index row")
	_check(not manager.has_continue_save() and manager.get_continue_target().is_empty(),
		"deleting the continue target leaves nothing to continue")


# --- Fixtures -----------------------------------------------------------------

func _make_suspend_save() -> RefCounted:
	var save: RefCounted = SaveDataScript.new()
	save.save_label = "Suspend test"
	save.campaign["campaign_id"] = "demo"
	save.campaign["node_id"] = "map_001"
	save.party["resources"]["party_gold"] = 50
	save.map_runtime["map_id"] = "map_001"
	save.map_runtime["map_path"] = "res://data/maps/map_001_rout/map_001_data.tres"
	save.map_runtime["rng"] = {"map_seed": 123, "history_hash": 456}
	save.suspend["kind"] = "map"
	save.ledger.append({
		"reason": "round_start",
		"entry": {
			"map_runtime": save.map_runtime.duplicate(true),
			"suspend": save.suspend.duplicate(true),
			"party": {"gold": 50, "items": [], "roster": []},
		},
	})
	return SaveDataScript.from_dict(save.to_dict())


# A between-map campaign save: a position + a party, and no live map.
func _make_campaign_save(label: String = "Autosave") -> RefCounted:
	var save: RefCounted = SaveDataScript.new()
	save.save_label = label
	save.campaign["campaign_id"] = "proving_grounds"
	save.campaign["node_id"] = "node_02_seize"
	save.campaign["cleared_nodes"] = ["node_01_rout"]
	save.party["resources"]["party_gold"] = 250
	save.roster["units"] = [{"unit_id": "lyn", "unit_name": "Lyn"}]
	return SaveDataScript.from_dict(save.to_dict())


func _make_completed_save() -> RefCounted:
	var save: RefCounted = _make_campaign_save("Proving Grounds - Complete")
	save.campaign["node_id"] = ""
	return SaveDataScript.from_dict(save.to_dict())


func _clean_test_dir() -> void:
	var err := DirAccess.make_dir_recursive_absolute(TEST_SAVE_DIR)
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_error("test_save_manager: failed to create test dir: %s" % error_string(err))
		return
	var dir := DirAccess.open(TEST_SAVE_DIR)
	if dir == null:
		return
	for file_name in dir.get_files():
		dir.remove(file_name)


func _write_text(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_SAVE_DIR)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("test_save_manager: failed to write test file: %s" \
			% error_string(FileAccess.get_open_error()))
		return
	file.store_string(text)
	file.close()
