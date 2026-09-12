extends SceneTree
# Pack-save Slice 2, stage 2F: a save whose campaign package is absent is stored
# DISABLED rather than refused, described in identity terms the player can act on,
# and promoted only when the package is actually installed.
#
# The wording and row model are asserted as pure functions (SaveRecovery and the
# picker's static row helpers), and the storage behaviour against the real
# autoloads, because that is where "the import was rejected and the file is gone"
# would actually happen.

const Registry = preload("res://scripts/resources/CampaignPackRegistry.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const Recovery = preload("res://scripts/save/SaveRecovery.gd")
const LoadGameScreenScript = preload("res://scripts/ui/LoadGameScreen.gd")
const SaveIntegrityScript = preload("res://scripts/save/SaveIntegrity.gd")
const Migration = preload("res://scripts/save/SaveMigrationService.gd")

const PACK_ID := "save-recovery-pack"
const PACK_VERSION := "1.0"
const TEST_SAVE_DIR := "user://test_pack_save_load_migration"
const PORTABLE_PATH := "user://test_pack_save_load_migration_portable.json"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String, detail: String = "") -> void:
	if ok:
		print("OK  %s" % label)
		_passed += 1
	else:
		print("FAIL %s%s" % [label, "" if detail == "" else " — %s" % detail])
		_failed += 1


func _run() -> void:
	print("=== Pack Save Load Migration (stage 2F) Test ===")
	_test_reason_mapping()
	_test_diagnostic_wording()
	_test_bounded_installed_list()
	_test_row_model()
	_test_disabled_import_and_recovery()
	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


# --- Wording and reason model -------------------------------------------------


func _test_reason_mapping() -> void:
	_check(
		(
			Recovery.reason_for_status(Migration.STATUS_MISSING) == Recovery.REASON_MISSING
			and (
				Recovery.reason_for_status(Migration.STATUS_INCOMPATIBLE)
				== Recovery.REASON_INCOMPATIBLE
			)
			and (
				Recovery.reason_for_status(Migration.STATUS_FINGERPRINT_MISMATCH)
				== Recovery.REASON_FINGERPRINT_MISMATCH
			)
			and Recovery.reason_for_status(Migration.STATUS_INVALID) == Recovery.REASON_INVALID
			and Recovery.reason_for_status(Migration.STATUS_EXACT) == ""
			and Recovery.reason_for_status(Migration.STATUS_SUCCESSOR) == ""
		),
		"every unresolvable status maps to one recovery reason and continuable ones map to none"
	)


func _test_diagnostic_wording() -> void:
	var saved := {
		"package_id": PACK_ID,
		"package_version": "2.0",
		"content_schema_version": 3,
		"content_fingerprint": "sha256:%s" % "ab12cd34".repeat(8),
		"campaign_id": "fixture",
	}
	var installed: Array = [{"package_id": PACK_ID, "package_version": PACK_VERSION}]
	var distinct: Dictionary = {}
	var all_actionable := true
	var all_unchanged := true
	var no_paths := true
	for reason in Recovery.REASONS:
		var diagnostic := Recovery.describe(reason, saved, installed)
		var text := Recovery.message(diagnostic)
		distinct[diagnostic["title"]] = true
		if reason == Recovery.REASON_INVALID:
			all_actionable = all_actionable and diagnostic["actions"] == [Recovery.ACTION_BACK]
		else:
			all_actionable = (
				all_actionable
				and (
					diagnostic["actions"]
					== [
						Recovery.ACTION_MANAGE_CAMPAIGNS,
						Recovery.ACTION_RETRY,
						Recovery.ACTION_BACK
					]
				)
				and text.contains("%s v2.0" % PACK_ID)
			)
		all_unchanged = all_unchanged and text.contains(Recovery.UNCHANGED_NOTICE)
		no_paths = (
			no_paths
			and not text.contains("user://")
			and not text.contains("res://")
			and not text.contains("/")
		)
	_check(
		distinct.size() == Recovery.REASONS.size(),
		"every reason has its own title so the five failures are distinguishable",
		str(distinct.keys())
	)
	_check(all_actionable, "recoverable reasons offer Manage Campaigns, Retry and Back in order")
	_check(all_unchanged, "every diagnostic states that no save data or progress was changed")
	_check(no_paths, "no diagnostic exposes a filesystem path")
	_check(
		(
			Recovery.short_fingerprint(String(saved["content_fingerprint"])) == "ab12cd34…"
			and Recovery.short_fingerprint("not-a-digest") == "unknown"
			and (
				Recovery
				. message(Recovery.describe(Recovery.REASON_FINGERPRINT_MISMATCH, saved, installed))
				. contains("ab12cd34…")
			)
		),
		"fingerprints are shown shortened, never in full and never as raw bytes"
	)


func _test_bounded_installed_list() -> void:
	var installed: Array = []
	for index in 7:
		installed.append({"package_id": PACK_ID, "package_version": "1.%d" % index})
	var saved := {
		"package_id": PACK_ID,
		"package_version": "9.0",
		"content_schema_version": 1,
		"content_fingerprint": "sha256:%s" % "c".repeat(64),
		"campaign_id": "fixture",
	}
	var text := Recovery.message(Recovery.describe(Recovery.REASON_INCOMPATIBLE, saved, installed))
	_check(
		text.contains("and 3 more") and not text.contains("1.6"),
		"an installed-version list is bounded rather than printing the whole library",
		text
	)


# --- Picker row model ---------------------------------------------------------


func _test_row_model() -> void:
	var ready_row := {"slot_id": "ready", "header": {}, "content_state": Recovery.STATE_READY}
	var legacy_row := {"slot_id": "legacy", "header": {}}
	var disabled_row := {
		"slot_id": "disabled",
		"header": {"package_id": PACK_ID, "package_version": PACK_VERSION},
		"content_state": Recovery.STATE_DISABLED,
		"recovery": Recovery.describe(Recovery.REASON_MISSING, {"package_id": PACK_ID}),
	}
	var stateless_row := {
		"slot_id": "stateless",
		"header": {"package_id": PACK_ID},
		"content_state": Recovery.STATE_DISABLED,
	}
	_check(
		(
			LoadGameScreenScript.recovery_diagnostic(ready_row).is_empty()
			and LoadGameScreenScript.recovery_diagnostic(legacy_row).is_empty()
			and not LoadGameScreenScript.recovery_diagnostic(disabled_row).is_empty()
			and not LoadGameScreenScript.recovery_diagnostic(stateless_row).is_empty()
		),
		"rows are ready by omission and disabled only when the index says so"
	)
	_check(
		(
			LoadGameScreenScript.row_button_names(ready_row)
			== ["LoadButton", "DeleteButton", "ExportButton"]
		),
		"a loadable row keeps its existing buttons",
		str(LoadGameScreenScript.row_button_names(ready_row))
	)
	_check(
		(
			LoadGameScreenScript.row_button_names(disabled_row)
			== [
				"LoadButton", "ManageCampaignsButton", "RetryButton", "DeleteButton", "ExportButton"
			]
		),
		"a disabled row puts both recovery actions ahead of Delete, which focus lands on first",
		str(LoadGameScreenScript.row_button_names(disabled_row))
	)


# --- Storage, promotion and preservation --------------------------------------


func _test_disabled_import_and_recovery() -> void:
	var pack := Registry.installed_path(Registry.DEFAULT_STORAGE_ROOT, PACK_ID, PACK_VERSION)
	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
	Installer._remove_tree(TEST_SAVE_DIR)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PORTABLE_PATH))
	_write_pack(pack)

	var dm: Node = root.get_node_or_null("DataManager")
	var gs: Node = root.get_node_or_null("GameState")
	var cm: Node = root.get_node_or_null("CampaignManager")
	var sm: Node = root.get_node_or_null("SaveManager")
	if dm == null or gs == null or cm == null or sm == null:
		_check(false, "required autoloads unavailable")
		return
	sm.call("configure_save_dir_for_tests", TEST_SAVE_DIR)
	dm.call("select_tier2_campaign_source", pack, PACK_ID, PACK_VERSION)
	var roster: Array = dm.call("get_campaign_pack_roster", "heroes")
	gs.call("load_roster_resources", roster, "campaign_pack_roster", "heroes")
	cm.call("start_campaign", "fixture")
	var save: RefCounted = gs.call("capture_campaign_save", "Recovery fixture")
	var portable: Dictionary = SaveIntegrityScript.stamp(save.to_dict())
	var portable_file := FileAccess.open(PORTABLE_PATH, FileAccess.WRITE)
	portable_file.store_string(JSON.stringify(portable, "\t"))
	portable_file.close()

	# The package the save names is gone. This is the case that used to lose the
	# player's only copy of the run.
	dm.call("select_campaign_source", "res://data")
	cm.call("end_campaign")
	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)

	var imported: Dictionary = sm.call("import_portable_save", PORTABLE_PATH, "recovered")
	var diagnostic: Dictionary = imported.get("diagnostic", {})
	_check(
		(
			bool(imported.get("ok", false))
			and String(imported.get("content_state", "")) == Recovery.STATE_DISABLED
			and String(diagnostic.get("reason", "")) == Recovery.REASON_MISSING
			and bool(sm.call("has_slot", "recovered"))
		),
		"a portable save whose package is absent imports disabled instead of being refused",
		str(imported.get("errors", []))
	)

	var stored_text := _read_text(sm.call("get_slot_path", "recovered"))
	var stored: Dictionary = JSON.parse_string(stored_text)
	# Compare both sides after a JSON round trip: the source file is the contract,
	# not the in-memory dictionary it was written from.
	var source_document: Dictionary = JSON.parse_string(_read_text(PORTABLE_PATH))
	var differing: Array[String] = []
	for section in source_document.keys():
		if stored.get(section) != source_document[section]:
			differing.append(String(section))
	_check(
		differing.is_empty() and stored.size() == source_document.size(),
		"the disabled import stores the source document verbatim",
		str(differing)
	)

	var row := _row_for(sm, "recovered")
	_check(
		(
			String(row.get("content_state", "")) == Recovery.STATE_DISABLED
			and row.get("recovery", {}) is Dictionary
			and String(row["recovery"].get("reason", "")) == Recovery.REASON_MISSING
			and not LoadGameScreenScript.recovery_diagnostic(row).is_empty()
		),
		"the index row records the disabled state and the diagnostic the picker renders",
		str(row)
	)
	_check(
		sm.call("load_slot", "recovered") == null and not bool(sm.call("has_continue_save")),
		"a disabled save neither loads nor becomes the Continue target"
	)

	var retry_missing: Dictionary = sm.call("revalidate_slot", "recovered")
	_check(
		(
			not bool(retry_missing.get("ok", false))
			and String(retry_missing.get("content_state", "")) == Recovery.STATE_DISABLED
			and (
				String(retry_missing.get("diagnostic", {}).get("reason", ""))
				== Recovery.REASON_MISSING
			)
			and _read_text(sm.call("get_slot_path", "recovered")) == stored_text
		),
		"Retry without the package refreshes the diagnostic and rewrites no save bytes"
	)

	_write_pack(pack)
	var retry_installed: Dictionary = sm.call("revalidate_slot", "recovered")
	var promoted := _row_for(sm, "recovered")
	_check(
		(
			bool(retry_installed.get("ok", false))
			and String(retry_installed.get("content_state", "")) == Recovery.STATE_READY
			and String(promoted.get("content_state", "")) == Recovery.STATE_READY
			and not promoted.has("recovery")
			and LoadGameScreenScript.recovery_diagnostic(promoted).is_empty()
			and _read_text(sm.call("get_slot_path", "recovered")) == stored_text
		),
		"installing the package promotes the same stored bytes to a loadable save",
		str(retry_installed.get("errors", []))
	)
	var loaded: RefCounted = sm.call("load_slot", "recovered")
	_check(
		loaded != null and bool(sm.call("has_continue_save")),
		"the promoted save loads and is offered as Continue again"
	)
	dm.call("select_campaign_source", "res://data")

	# A document that is not a readable save is still refused outright: there is
	# nothing to recover and storing it would invent a slot the player cannot fix.
	var damaged: Dictionary = portable.duplicate(true)
	damaged["source"]["content_fingerprint"] = "not-a-digest"
	var damaged_path := "user://test_pack_save_load_migration_damaged.json"
	var damaged_file := FileAccess.open(damaged_path, FileAccess.WRITE)
	damaged_file.store_string(JSON.stringify(damaged))
	damaged_file.close()
	var damaged_result: Dictionary = sm.call("import_portable_save", damaged_path, "damaged")
	var not_json_path := "user://test_pack_save_load_migration_not_json.json"
	var not_json := FileAccess.open(not_json_path, FileAccess.WRITE)
	not_json.store_string("[1, 2, 3]")
	not_json.close()
	var not_json_result: Dictionary = sm.call("import_portable_save", not_json_path, "notjson")
	_check(
		(
			not bool(damaged_result.get("ok", false))
			and not bool(sm.call("has_slot", "damaged"))
			and (
				String(damaged_result.get("diagnostic", {}).get("reason", ""))
				== Recovery.REASON_INVALID
			)
			and not bool(not_json_result.get("ok", false))
			and not bool(sm.call("has_slot", "notjson"))
			and (
				String(not_json_result.get("diagnostic", {}).get("reason", ""))
				== Recovery.REASON_INVALID
			)
		),
		"an unreadable or damaged document is refused, not stored disabled",
		"%s / %s" % [damaged_result, not_json_result]
	)

	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
	Installer._remove_tree(TEST_SAVE_DIR)


func _row_for(sm: Node, slot_id: String) -> Dictionary:
	for row in sm.call("list_slots"):
		if String(row.get("slot_id", "")) == slot_id:
			return row
	return {}


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _write_pack(pack_root: String) -> void:
	var files := {
		"manifest.json":
		{
			"id": PACK_ID,
			"version": PACK_VERSION,
			"forked_from": "",
			"builder_content_version": "0.4",
			"format_version": 1
		},
		"data/catalogue.json":
		{
			"format_version": 1,
			"entries":
			[
				{"kind": "campaign", "id": "fixture", "path": "data/campaign.json"},
				{"kind": "map_registry", "id": "maps", "path": "data/map_registry.json"},
				{"kind": "map_data", "id": "map_01", "path": "data/map_01.json"},
				{"kind": "roster", "id": "heroes", "path": "data/roster.json"},
				{"kind": "class", "id": "fixture_class", "path": "data/class.json"},
				{"kind": "weapon", "id": "fixture_blade", "path": "data/weapon.json"}
			]
		},
		"data/campaign.json":
		{
			"campaign_id": "fixture",
			"label": "Fixture",
			"start_node_id": "start",
			"nodes": [{"node_id": "start", "label": "Start", "map_id": "map_01", "next": []}]
		},
		"data/map_registry.json":
		[{"id": "map_01", "label": "Map", "map_data_id": "map_01", "roster_id": "heroes"}],
		"data/map_01.json":
		{"id": "map_01", "display_name": "Map", "grid": ["..."], "player_start_tiles": [[0, 0]]},
		"data/roster.json":
		{
			"units":
			[
				{
					"unit_id": "hero",
					"unit_name": "Hero",
					"class_id": "fixture_class",
					"inventory": [{"weapon_id": "fixture_blade", "uses": -1}]
				}
			]
		},
		"data/class.json":
		{
			"id": "fixture_class",
			"display_name": "Fixture",
			"base_hp": 20,
			"base_movement": 5,
			"allowed_weapon_families": ["sword"],
			"weapon_wexp_bases": {"sword": 1},
			"weapon_wexp_caps": {"sword": 400}
		},
		"data/weapon.json":
		{
			"id": "fixture_blade",
			"display_name": "Fixture Blade",
			"combat_family": "sword",
			"wexp_track": "sword",
			"required_rank": "E",
			"mt": 1,
			"hit": 100,
			"crit": 0,
			"wt": 0,
			"range_min_formula": "1",
			"range_max_formula": "1",
			"uses": -1,
			"cost": 0,
			"wexp": 1
		},
	}
	for relative in files:
		var path := pack_root.path_join(relative)
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(files[relative]))
		file.close()
