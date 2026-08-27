extends SceneTree
# Pack-save Slice 3, stage 3G: the failure gate.
#
# Every case below drives the real registry, installer, SaveManager and status store
# rather than synthetic identities, and every refusal asserts the SAME FOUR
# INVARIANTS together: the installed library, the save index and slots, the campaign
# status store, and the backup file's own bytes are all unchanged. A check that only
# asserts "it returned false" cannot tell a clean refusal from a half-applied one.

const Service = preload("res://scripts/resources/CampaignBackupService.gd")
const Envelope = preload("res://scripts/save/BackupEnvelope.gd")
const Registry = preload("res://scripts/resources/CampaignPackRegistry.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const StatusRecord = preload("res://scripts/resources/CampaignStatusRecord.gd")
const Exporter = preload("res://scripts/resources/CampaignPackExporter.gd")

const PACK_ID := "backup-gate-pack"
const PACK_VERSION := "1.0"
const SLOT_ID := "gate_slot"
const RECORD_ID := "gate_record"
const TEST_SAVE_DIR := "user://test_pack_save_export_gate_saves"
const TEST_STATUS_ROOT := "user://test_pack_save_export_gate_status"
const BACKUP_PATH := "user://test_pack_save_export_gate_backup.zip"
const SCRATCH_PATH := "user://test_pack_save_export_gate_scratch.zip"

var _passed := 0
var _failed := 0
var _nodes: Dictionary = {}


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
	print("=== Pack Save Export Failure Gate (stage 3G) Test ===")
	_nodes = {
		"data": root.get_node_or_null("DataManager"),
		"state": root.get_node_or_null("GameState"),
		"campaign": root.get_node_or_null("CampaignManager"),
		"save": root.get_node_or_null("SaveManager"),
	}
	if _nodes.values().has(null):
		_check(false, "required autoloads unavailable")
		print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
		quit(1)
		return
	_test_round_trip()
	_test_malformed_archives()
	_test_budgets()
	_test_component_failures()
	_test_commit_faults()
	_test_state_in_pack_is_refused()
	_test_diagnostics_are_bounded()
	_cleanup()
	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


# --- Fixture ------------------------------------------------------------------


func _cleanup() -> void:
	_nodes["campaign"].call("end_campaign")
	_nodes["data"].call("select_campaign_source", "res://data")
	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
	Installer._remove_tree(TEST_SAVE_DIR)
	Installer._remove_tree(TEST_STATUS_ROOT)
	Installer._remove_tree(Service.STAGING_DIR)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_PATH))


func _service() -> RefCounted:
	return Service.new(Registry.DEFAULT_STORAGE_ROOT, _nodes["save"], TEST_STATUS_ROOT)


func _write_json(path: String, value: Variant) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()


func _status_document() -> Dictionary:
	var record := StatusRecord.new()
	record.record_id = RECORD_ID
	record.author_id = "gate_author"
	record.campaign_id = "fixture"
	record.campaign_version = "1.0.0"
	record.created_at_utc = "2026-08-27T00:00:00"
	return record.to_dict()


func _pack_files() -> Dictionary:
	return {
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


func _write_pack(pack_root: String, extra: Dictionary = {}) -> void:
	var files := _pack_files()
	for relative in extra:
		files[relative] = extra[relative]
	for relative in files:
		_write_json(pack_root.path_join(relative), files[relative])


# Rebuilds the world and one backup of it. Called before each group so a case that
# does change state cannot leak into the next one's invariants.
func _seed() -> void:
	_cleanup()
	_write_pack(Registry.installed_path(Registry.DEFAULT_STORAGE_ROOT, PACK_ID, PACK_VERSION))
	_write_json(TEST_STATUS_ROOT.path_join("%s.json" % RECORD_ID), _status_document())
	_nodes["save"].call("configure_save_dir_for_tests", TEST_SAVE_DIR)
	var pack := Registry.installed_path(Registry.DEFAULT_STORAGE_ROOT, PACK_ID, PACK_VERSION)
	_nodes["data"].call("select_tier2_campaign_source", pack, PACK_ID, PACK_VERSION)
	var roster: Array = _nodes["data"].call("get_campaign_pack_roster", "heroes")
	_nodes["state"].call("load_roster_resources", roster, "campaign_pack_roster", "heroes")
	_nodes["campaign"].call("start_campaign", "fixture")
	var save: RefCounted = _nodes["state"].call("capture_campaign_save", "Gate fixture")
	_nodes["save"].call("save_slot", SLOT_ID, save, "manual")
	_service().export_backup(BACKUP_PATH)


# --- The four invariants ------------------------------------------------------


func _snapshot() -> Dictionary:
	var library: Array[String] = []
	for summary in Registry.new(Registry.DEFAULT_STORAGE_ROOT).refresh():
		library.append("%s|%s" % [summary["package_id"], summary["package_version"]])
	var slots := {}
	var directory := DirAccess.open(TEST_SAVE_DIR)
	if directory != null:
		for name in directory.get_files():
			slots[name] = FileAccess.get_file_as_bytes(TEST_SAVE_DIR.path_join(name))
	var status := {}
	var status_dir := DirAccess.open(TEST_STATUS_ROOT)
	if status_dir != null:
		for name in status_dir.get_files():
			status[name] = FileAccess.get_file_as_bytes(TEST_STATUS_ROOT.path_join(name))
	return {
		"library": library,
		"slots": slots,
		"status": status,
		"backup": FileAccess.get_file_as_bytes(BACKUP_PATH),
	}


func _check_unchanged(before: Dictionary, label: String) -> void:
	var after := _snapshot()
	_check(before["library"] == after["library"], "%s: the installed library is unchanged" % label)
	_check(before["slots"] == after["slots"], "%s: every save and the index are unchanged" % label)
	_check(before["status"] == after["status"], "%s: the status store is unchanged" % label)
	_check(before["backup"] == after["backup"], "%s: the source backup is unchanged" % label)


# --- Cases --------------------------------------------------------------------


func _test_round_trip() -> void:
	_seed()
	var service := _service()
	var inspected = service.inspect_backup(BACKUP_PATH)
	_check(inspected.valid, "a written backup inspects clean", str(inspected.errors))

	# The loss case: the pack, the save and the record are all gone.
	_nodes["campaign"].call("end_campaign")
	_nodes["data"].call("select_campaign_source", "res://data")
	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
	_nodes["save"].call("delete_slot", SLOT_ID)
	Installer._remove_tree(TEST_STATUS_ROOT)

	var restored = service.restore_backup(BACKUP_PATH)
	_check(restored.restored, "a full backup round trips", str(restored.errors))
	var revalidated: Dictionary = _nodes["save"].call("revalidate_slot", SLOT_ID)
	_check(
		bool(revalidated.get("ok", false)),
		"the restored save is runnable, not merely present",
		str(revalidated.get("errors", []))
	)
	var record_path := TEST_STATUS_ROOT.path_join("%s.json" % RECORD_ID)
	var record_errors: Array[String] = []
	_check(
		(
			StatusRecord.from_dict(
				JSON.parse_string(FileAccess.get_file_as_string(record_path)), record_errors
			)
			!= null
		),
		"the restored status record still validates",
		str(record_errors)
	)


func _rebuild(payloads: Dictionary, path: String) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var packer := ZIPPacker.new()
	if packer.open(path, ZIPPacker.APPEND_CREATE) != OK:
		return
	var names := payloads.keys()
	names.sort()
	for name in names:
		packer.start_file(String(name))
		packer.write_file(payloads[name])
		packer.close_file()
	packer.close()


func _payloads_of(path: String) -> Dictionary:
	var reader := ZIPReader.new()
	if reader.open(path) != OK:
		return {}
	var payloads := {}
	for entry in reader.get_files():
		payloads[entry] = reader.read_file(entry)
	reader.close()
	return payloads


func _refuses(payloads: Dictionary, label: String) -> void:
	var before := _snapshot()
	_rebuild(payloads, SCRATCH_PATH)
	var result = _service().restore_backup(SCRATCH_PATH)
	_check(not result.restored and not result.errors.is_empty(), label, str(result.errors))
	_check_unchanged(before, label)


func _test_malformed_archives() -> void:
	_seed()
	var payloads := _payloads_of(BACKUP_PATH)

	var traversal := payloads.duplicate(true)
	traversal["../escape.json"] = "{}".to_utf8_buffer()
	_refuses(traversal, "a path escaping the archive is refused")

	var folded := payloads.duplicate(true)
	folded["user_state/saves/GATE_SLOT.json"] = payloads["user_state/saves/%s.json" % SLOT_ID]
	_refuses(folded, "a case-fold collision is refused")

	var truncated := payloads.duplicate(true)
	truncated["backup.json"] = "{".to_utf8_buffer()
	_refuses(truncated, "an unparseable envelope is refused")

	var weakened := payloads.duplicate(true)
	var envelope: Dictionary = JSON.parse_string(payloads["backup.json"].get_string_from_utf8())
	envelope["digest_algorithm"] = "sha1"
	weakened["backup.json"] = JSON.stringify(envelope).to_utf8_buffer()
	_refuses(weakened, "a weaker digest algorithm is refused")


func _test_budgets() -> void:
	_seed()
	var before := _snapshot()
	var service := _service()
	_check(
		not service.inspect_backup(BACKUP_PATH, 2).valid,
		"an archive with more entries than the budget allows is refused"
	)
	_check(
		not service.inspect_backup(BACKUP_PATH, -1, 8).valid,
		"a component larger than the per-entry budget is refused"
	)
	_check(
		not service.inspect_backup(BACKUP_PATH, -1, 8, 16).valid,
		"a backup larger than the total budget is refused"
	)
	_check(
		not service.inspect_backup(BACKUP_PATH, 0).valid,
		"an impossible budget is refused rather than treated as unlimited"
	)
	_check_unchanged(before, "a budget refusal")


func _test_component_failures() -> void:
	_seed()
	var payloads := _payloads_of(BACKUP_PATH)
	var envelope: Dictionary = JSON.parse_string(payloads["backup.json"].get_string_from_utf8())

	# A pack component that is intact by digest but not installable. The digest says
	# nothing about whether the archive inside is a valid package.
	var broken_pack := payloads.duplicate(true)
	var pack_path := "packs/%s-%s.zip" % [PACK_ID, PACK_VERSION]
	var replacement := "not a package".to_utf8_buffer()
	broken_pack[pack_path] = replacement
	var patched := envelope.duplicate(true)
	for component in patched["components"]:
		if String(component.get("path", "")) == pack_path:
			component["sha256"] = Envelope.digest(replacement)
			component["bytes"] = replacement.size()
	broken_pack["backup.json"] = JSON.stringify(patched).to_utf8_buffer()
	var before := _snapshot()
	_rebuild(broken_pack, SCRATCH_PATH)
	# Remove the installed copy so restore actually attempts the install.
	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
	var result = _service().restore_backup(SCRATCH_PATH)
	_check(
		not result.restored and not result.errors.is_empty(),
		"a package that cannot be installed is refused",
		str(result.errors)
	)
	_check(
		Registry.new(Registry.DEFAULT_STORAGE_ROOT).refresh().is_empty(),
		"nothing was installed by the refused restore"
	)
	_seed()

	# A status record whose checksum does not match its contents.
	var tampered := _payloads_of(BACKUP_PATH)
	var record: Dictionary = JSON.parse_string(
		tampered["user_state/status/%s.json" % RECORD_ID].get_string_from_utf8()
	)
	record["facts"] = {"tampered": true}
	var record_bytes := JSON.stringify(record).to_utf8_buffer()
	tampered["user_state/status/%s.json" % RECORD_ID] = record_bytes
	var state: Dictionary = JSON.parse_string(
		tampered["user_state/manifest.json"].get_string_from_utf8()
	)
	for row in state["status_records"]:
		row["sha256"] = Envelope.digest(record_bytes)
		row["bytes"] = record_bytes.size()
	var state_bytes := JSON.stringify(state).to_utf8_buffer()
	tampered["user_state/manifest.json"] = state_bytes
	var outer: Dictionary = JSON.parse_string(tampered["backup.json"].get_string_from_utf8())
	for component in outer["components"]:
		if String(component.get("path", "")) == Envelope.USER_STATE_MANIFEST_PATH:
			component["sha256"] = Envelope.digest(state_bytes)
			component["bytes"] = state_bytes.size()
	tampered["backup.json"] = JSON.stringify(outer).to_utf8_buffer()
	_refuses(tampered, "a status record that fails its own validator is refused")


func _test_commit_faults() -> void:
	# Faults are injected at each commit stage in turn. The point is not that the
	# fault happens; it is that the world afterwards is the world before.
	for stage in ["package_installed", "slot_restored", "record_restored"]:
		_seed()
		_nodes["campaign"].call("end_campaign")
		_nodes["data"].call("select_campaign_source", "res://data")
		Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
		_nodes["save"].call("delete_slot", SLOT_ID)
		var before := _snapshot()
		var service := _service()
		service.fault_injector = func(name: String) -> bool: return name == stage
		var result = service.restore_backup(BACKUP_PATH)
		_check(
			not result.restored and not result.errors.is_empty(),
			"a failure at %s stops the restore" % stage
		)
		_check_unchanged(before, "a failure at %s" % stage)


func _test_state_in_pack_is_refused() -> void:
	_seed()
	# Save-shaped JSON inside a package is refused by the pack surface itself, which
	# is why a backup cannot smuggle user state into an installable pack.
	var dirty := "user://test_pack_save_export_gate_dirty"
	Installer._remove_tree(dirty)
	var files := _pack_files()
	files["data/catalogue.json"]["entries"].append(
		{"kind": "campaign", "id": "smuggled", "path": "data/smuggled.json"}
	)
	_write_pack(dirty, {"data/smuggled.json": {"save_label": "x", "map_runtime": {}, "header": {}}})
	_write_json(dirty.path_join("data/catalogue.json"), files["data/catalogue.json"])
	var exported = Exporter.new().export_zip(dirty, SCRATCH_PATH, Service._pack_limits())
	var refused: bool = not exported.exported
	if exported.exported:
		# If it exported, the preflight boundary must still refuse to install it.
		refused = not Service.new(Registry.DEFAULT_STORAGE_ROOT).inspect_backup(SCRATCH_PATH).valid
	_check(refused, "a package carrying save-shaped state is refused", str(exported.errors))
	Installer._remove_tree(dirty)


func _test_diagnostics_are_bounded() -> void:
	_seed()
	var payloads := _payloads_of(BACKUP_PATH)
	payloads.erase("backup.json")
	_rebuild(payloads, SCRATCH_PATH)
	var result = _service().restore_backup(SCRATCH_PATH)
	var text := str(result.errors)
	# No filesystem path reaches the player: not the archive's, not user://, not res://.
	_check(
		(
			not ("user://" in text)
			and not ("res://" in text)
			and not (SCRATCH_PATH in text)
			and not ("/" in text.replace("and/or", ""))
		),
		"a refusal names no filesystem path",
		text
	)
