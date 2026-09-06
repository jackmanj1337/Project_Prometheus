extends SceneTree
# V0717-01 and V0717-08: restoring a backup whose pack is already installed at the
# same id and version, but with DIFFERENT CONTENT.
#
# What the v0.7.17 tester hit. `_validate_restore_candidates` skipped a backup's
# package whenever a directory existed at that id/version, on the strength of a
# comment asserting that "same id AND version is the same release by definition of
# the library's identity rules". Nothing enforced that. The saves were then restored
# against whatever content happened to be installed, every one failed revalidation,
# and the dialog told the player to reinstall a version that was already installed —
# an instruction they could not follow, and the round's only failed row.
#
# The identity the library keys on (`id|version`) is coarser than the identity saves
# are validated against (`id|version|content_fingerprint`), and the fingerprint that
# detects the violation is available on both sides at the moment of the skip.
#
# Why the existing suites missed it: `test_pack_save_exports.gd` covers "pack absent"
# (installs) and "pack present at the same version" (skips), and both behave as
# written. Neither installs DIFFERENT CONTENT under the same version, because the
# coarse-identity comment was treated as an axiom rather than as a condition to test.
# That case is the whole of this file.
#
# Everything here drives the real CampaignBackupService against a real library root
# and the real SaveManager, because the defect lives in the disagreement between two
# real surfaces. The one exception is the final case, which drives the CORRECTED
# campaign_backup_v2.zip from V0717-BACKUP-FIXTURE-REBUILD-2026-09-06 when it is on
# this machine — the return's own artifact, per the standing rule that a row opened
# by a playtest return is closed by its own evidence.

const Service = preload("res://scripts/resources/CampaignBackupService.gd")
const Registry = preload("res://scripts/resources/CampaignPackRegistry.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const Recovery = preload("res://scripts/save/SaveRecovery.gd")
const Tier2 = preload("res://scripts/resources/Tier2Catalogue.gd")
const Preflight = preload("res://scripts/resources/CampaignArchivePreflight.gd")
const Budgets = preload("res://scripts/resources/ImportBudgets.gd")

const PACK_ID := "restore-guard-pack"
const PACK_VERSION := "1.0"
const SLOT_ID := "guard_slot"

# The engine resolves a save's package against the real library root, so restore has
# to install there for the restored save to be runnable. Isolation comes from the
# runner giving each worker its own user:// directory.
const TEST_STORAGE_ROOT := Registry.DEFAULT_STORAGE_ROOT
const TEST_SAVE_DIR := "user://test_campaign_backup_restore_saves"
const TEST_STATUS_ROOT := "user://test_campaign_backup_restore_status"
const TEST_BACKUP_PATH := "user://test_campaign_backup_restore_backup.zip"

# The corrected fixture, if this machine has one. Absolute because it is produced by
# the container repo's scripts/rebuild-backup-fixture.sh, which lives outside res://.
const RETURN_FIXTURE_ENV := "PROMETHEUS_TEST_BACKUP_FIXTURE"
const RETURN_FIXTURE_DEFAULT := "/workspace/godot-prometheus-env/builds/v0.7.18-fixtures/campaign_backup_v2.zip"
# The genuine v2 pack the bundle ships beside it. Both halves are needed: the
# collision only exists once this is installed.
const RETURN_FIXTURE_PACK_ENV := "PROMETHEUS_TEST_BACKUP_FIXTURE_PACK"
const RETURN_FIXTURE_PACK_DEFAULT := "/workspace/godot-prometheus-env/builds/packs/v0.7.18/v076-migration-2.0.0.zip"

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
	print("=== Campaign Backup Restore (V0717-01 / V0717-08) Test ===")
	_test_same_version_different_content_is_refused()
	_test_same_version_same_content_still_skips()
	_test_absent_package_still_installs()
	_test_refusal_texts_distinguish_missing_from_mismatched()
	_test_return_fixture_restores()
	_reset_fixture()
	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


# --- Fixture ------------------------------------------------------------------


func _autoloads() -> Dictionary:
	return {
		"data": root.get_node_or_null("DataManager"),
		"state": root.get_node_or_null("GameState"),
		"campaign": root.get_node_or_null("CampaignManager"),
		"save": root.get_node_or_null("SaveManager"),
		"diagnostics": root.get_node_or_null("DiagnosticsLog"),
	}


func _write_json(path: String, value: Variant) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()


# `variant` changes one indexed document, so two packs share an id and a version and
# differ in content — the exact collision the library's coarse identity cannot see.
func _write_pack(pack_root: String, variant: String) -> void:
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
			"display_name": "Fixture %s" % variant,
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
		_write_json(pack_root.path_join(relative), files[relative])


func _installed_root() -> String:
	return Registry.installed_path(TEST_STORAGE_ROOT, PACK_ID, PACK_VERSION)


func _fingerprint_of(pack_root: String) -> String:
	var errors: Array[String] = []
	var catalogue := Tier2.load_campaign_pack(pack_root, errors)
	return "" if catalogue == null else catalogue.content_fingerprint()


func _reset_fixture() -> void:
	Installer._remove_tree(TEST_STORAGE_ROOT)
	Installer._remove_tree(TEST_SAVE_DIR)
	Installer._remove_tree(TEST_STATUS_ROOT)
	Installer._remove_tree(Service.STAGING_DIR)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_BACKUP_PATH))


func _detach_content(nodes: Dictionary) -> void:
	nodes["campaign"].call("end_campaign")
	nodes["data"].call("select_campaign_source", "res://data")


func _seed_live_save(nodes: Dictionary) -> bool:
	nodes["save"].call("configure_save_dir_for_tests", TEST_SAVE_DIR)
	nodes["data"].call("select_tier2_campaign_source", _installed_root(), PACK_ID, PACK_VERSION)
	var roster: Array = nodes["data"].call("get_campaign_pack_roster", "heroes")
	nodes["state"].call("load_roster_resources", roster, "campaign_pack_roster", "heroes")
	nodes["campaign"].call("start_campaign", "fixture")
	var save: RefCounted = nodes["state"].call("capture_campaign_save", "Restore guard fixture")
	return bool(nodes["save"].call("save_slot", SLOT_ID, save, "manual"))


# Export a backup of a library holding `variant`, then leave the library empty. The
# backup's pack component and its save both carry `variant`'s fingerprint, because
# both were produced by the real surfaces from the same content.
func _export_backup_of(nodes: Dictionary, variant: String) -> String:
	_reset_fixture()
	_write_pack(_installed_root(), variant)
	if not _seed_live_save(nodes):
		return ""
	var fingerprint := _fingerprint_of(_installed_root())
	var service := Service.new(TEST_STORAGE_ROOT, nodes["save"], TEST_STATUS_ROOT)
	var written = service.export_backup(TEST_BACKUP_PATH)
	if not written.exported:
		return ""
	_detach_content(nodes)
	Installer._remove_tree(TEST_STORAGE_ROOT)
	nodes["save"].call("delete_slot", SLOT_ID)
	return fingerprint


func _restore_records(nodes: Dictionary, event: StringName) -> Array:
	var diagnostics: Object = nodes["diagnostics"]
	if diagnostics == null or not diagnostics.has_method("snapshot"):
		return []
	var found: Array = []
	for entry in diagnostics.call("snapshot"):
		if StringName(entry.get("event", "")) == event:
			found.append(entry)
	return found


# --- Cases --------------------------------------------------------------------


# THE PROBE. Written before the fix; it fails on the shipped behaviour, where the
# restore reports success and every restored save is unopenable.
func _test_same_version_different_content_is_refused() -> void:
	var nodes := _autoloads()
	if nodes.values().has(null):
		_check(false, "required autoloads unavailable")
		return
	if nodes["diagnostics"].has_method("reset"):
		nodes["diagnostics"].call("reset")

	var backed_up := _export_backup_of(nodes, "B")
	if backed_up.is_empty():
		_check(false, "the fixture backup could not be exported")
		return

	# The collision: the same id and version is installed, holding different content.
	_write_pack(_installed_root(), "A")
	var installed := _fingerprint_of(_installed_root())
	_check(
		not installed.is_empty() and installed != backed_up,
		"the fixture puts two different contents under one id and version",
		"%s vs %s" % [installed, backed_up]
	)

	var service := Service.new(TEST_STORAGE_ROOT, nodes["save"], TEST_STATUS_ROOT)
	var restored = service.restore_backup(TEST_BACKUP_PATH)

	_check(
		not restored.restored,
		"a restore whose package is installed at different content is refused",
		str(restored.errors)
	)
	_check(
		restored.skipped_packages.is_empty(),
		"the conflicting package is not silently skipped",
		str(restored.skipped_packages)
	)
	# The message is the half the tester actually met: it has to name the conflict,
	# not repeat an instruction they have already followed.
	var message := str(restored.errors)
	_check(
		(
			Recovery.short_fingerprint(installed) in message
			and Recovery.short_fingerprint(backed_up) in message
		),
		"the refusal quotes both content fingerprints",
		message
	)
	_check(
		not bool(nodes["save"].call("has_slot", SLOT_ID)),
		"no save is left behind by the refused restore"
	)
	# The installed pack is untouched: a refusal that half-installed would be worse
	# than the silent skip it replaces.
	_check(
		_fingerprint_of(_installed_root()) == installed,
		"the installed package is left exactly as it was"
	)

	# V0717-08. The absence of records is why V0717-01 had to be argued from the
	# ABSENCE of a pack|install line between two unrelated records.
	var package_records := _restore_records(nodes, &"restore_package")
	_check(not package_records.is_empty(), "restore records what it did with each package")
	var quoted := false
	for entry in package_records:
		# `fields` is already the rendered key=value text; DiagnosticsLog stores the
		# line, not the dictionary that produced it.
		var text := String(entry.get("fields", ""))
		if installed in text and backed_up in text:
			quoted = true
	_check(quoted, "the package record carries both fingerprints", str(package_records))

	_detach_content(nodes)
	_reset_fixture()


func _test_same_version_same_content_still_skips() -> void:
	var nodes := _autoloads()
	if nodes.values().has(null):
		return
	var backed_up := _export_backup_of(nodes, "B")
	if backed_up.is_empty():
		_check(false, "the fixture backup could not be exported")
		return

	# Identical content, reinstalled. This is the ordinary case the skip exists for,
	# and the guard must not turn it into a refusal.
	_write_pack(_installed_root(), "B")
	var service := Service.new(TEST_STORAGE_ROOT, nodes["save"], TEST_STATUS_ROOT)
	var restored = service.restore_backup(TEST_BACKUP_PATH)
	_check(restored.restored, "an identical installed package still restores", str(restored.errors))
	_check(
		restored.skipped_packages.size() == 1 and restored.installed_packages.is_empty(),
		"an identical installed package is skipped rather than reinstalled",
		str(restored.errors)
	)
	var revalidated: Dictionary = nodes["save"].call("revalidate_slot", SLOT_ID)
	_check(
		bool(revalidated.get("ok", false)),
		"the restored save resolves against the installed package",
		str(revalidated.get("errors", []))
	)
	_detach_content(nodes)
	_reset_fixture()


func _test_absent_package_still_installs() -> void:
	var nodes := _autoloads()
	if nodes.values().has(null):
		return
	var backed_up := _export_backup_of(nodes, "B")
	if backed_up.is_empty():
		_check(false, "the fixture backup could not be exported")
		return

	var service := Service.new(TEST_STORAGE_ROOT, nodes["save"], TEST_STATUS_ROOT)
	var restored = service.restore_backup(TEST_BACKUP_PATH)
	_check(
		restored.restored and restored.installed_packages.size() == 1,
		"an absent package is installed from the backup",
		str(restored.errors)
	)
	_check(
		_fingerprint_of(_installed_root()) == backed_up,
		"the installed content is the backup's content"
	)
	var revalidated: Dictionary = nodes["save"].call("revalidate_slot", SLOT_ID)
	_check(
		bool(revalidated.get("ok", false)),
		"the restored save resolves against the package restore installed",
		str(revalidated.get("errors", []))
	)
	_detach_content(nodes)
	_reset_fixture()


# V0717-01's secondary half. Both cases rendered as "Reinstall the exact package
# version this save was made with." — which is unfollowable when that version is
# already installed.
func _test_refusal_texts_distinguish_missing_from_mismatched() -> void:
	var saved := {
		"package_id": PACK_ID,
		"package_version": PACK_VERSION,
		"campaign_id": "fixture",
		"content_schema_version": 1,
		"content_fingerprint": "sha256:%s" % "a".repeat(64),
	}
	var installed_elsewhere: Array = [
		{
			"package_id": PACK_ID,
			"package_version": "2.0",
			"content_schema_version": 1,
			"content_fingerprint": "sha256:%s" % "b".repeat(64),
		}
	]
	var installed_same_version: Array = [
		{
			"package_id": PACK_ID,
			"package_version": PACK_VERSION,
			"content_schema_version": 1,
			"content_fingerprint": "sha256:%s" % "c".repeat(64),
		}
	]
	var absent := Recovery.describe(
		Recovery.REASON_FINGERPRINT_MISMATCH, saved, installed_elsewhere
	)
	var present := Recovery.describe(
		Recovery.REASON_FINGERPRINT_MISMATCH, saved, installed_same_version
	)
	_check(
		Recovery.message(absent) != Recovery.message(present),
		"the two fingerprint-mismatch causes read differently"
	)
	_check(
		Recovery.short_fingerprint("sha256:%s" % "c".repeat(64)) in Recovery.message(present),
		"the installed-but-different message names the installed fingerprint",
		Recovery.message(present)
	)
	_check(
		PACK_VERSION in Recovery.message(present),
		"the installed-but-different message names the version that is installed",
		Recovery.message(present)
	)


# The return's own artifact, in the tester's own sequence. Skipped where it is
# absent, because builds/ is gitignored and this suite must stay runnable on a bare
# checkout.
#
# THE SEQUENCE MATTERS. Restoring either fixture into an EMPTY library succeeds and
# every save resolves, because restore installs the backup's own pack and the saves
# agree with it — the broken v0.7.17 fixture included, since it was self-consistent.
# What failed on the tester's machine is Section 4 row 3: install the genuine v2 pack
# from the bundle FIRST, then restore. Only then do the two identities meet.
func _test_return_fixture_restores() -> void:
	var path := OS.get_environment(RETURN_FIXTURE_ENV)
	if path.is_empty():
		path = RETURN_FIXTURE_DEFAULT
	var pack_path := OS.get_environment(RETURN_FIXTURE_PACK_ENV)
	if pack_path.is_empty():
		pack_path = RETURN_FIXTURE_PACK_DEFAULT
	if not FileAccess.file_exists(path) or not FileAccess.file_exists(pack_path):
		print("SKIP the v0.7.18 backup fixture is not on this machine (%s)" % path)
		return
	var nodes := _autoloads()
	if nodes.values().has(null):
		return
	_reset_fixture()
	nodes["save"].call("configure_save_dir_for_tests", TEST_SAVE_DIR)

	# Section 4, rows 1-2: the tester installs the shipped campaign packs.
	var limits := Preflight.Limits.new(
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRIES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRY_COMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRY_UNCOMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_TOTAL_COMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_TOTAL_UNCOMPRESSED_BYTES
	)
	var preflight = Preflight.inspect_zip(pack_path, limits)
	_check(preflight.valid, "the shipped v2 pack passes preflight", str(preflight.errors))
	if not preflight.valid:
		return
	var installed = Installer.new(TEST_STORAGE_ROOT).install_zip(pack_path, preflight)
	_check(installed.installed, "the shipped v2 pack installs", str(installed.errors))
	if not installed.installed:
		return
	var installed_fingerprint := _fingerprint_of(installed.installed_path)

	# Section 4, row 3: restore the backup on top of it.
	var service := Service.new(TEST_STORAGE_ROOT, nodes["save"], TEST_STATUS_ROOT)
	var inspected = service.inspect_backup(path)
	_check(inspected.valid, "the corrected fixture inspects as a backup", str(inspected.errors))
	if not inspected.valid:
		return
	var restored = service.restore_backup(path)
	_check(
		restored.restored,
		"the corrected campaign_backup_v2.zip restores over the installed v2 pack",
		str(restored.errors)
	)
	# Its bundled pack IS the installed pack, so the guard agrees and skips. A fixture
	# that had to be installed here would be a fixture whose bytes disagree with the
	# bundle — which is what shipped.
	_check(
		restored.skipped_packages.size() == 1 and restored.installed_packages.is_empty(),
		"the fixture's bundled pack matches the installed one and is skipped",
		str(restored.errors)
	)
	for slot_id in restored.restored_slots:
		var revalidated: Dictionary = nodes["save"].call("revalidate_slot", String(slot_id))
		_check(
			bool(revalidated.get("ok", false)),
			"restored slot '%s' resolves against the installed package" % slot_id,
			str(revalidated.get("errors", []))
		)
	_check(
		_fingerprint_of(installed.installed_path) == installed_fingerprint,
		"the installed package is unchanged by the restore"
	)
	_reset_fixture()
