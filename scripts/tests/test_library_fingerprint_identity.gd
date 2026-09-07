extends SceneTree
# LIBRARY-FINGERPRINT-IDENTITY-2026-09-07 — the closeout of
# SAVE-IDENTITY-BLOCK-UNIFICATION-2026-09-05 and the destination V0717-01's interim
# refusal points at.
#
# THE DEFECT THIS FILE IS ABOUT. The installed library keys a release on
# `package_id|package_version`. A save is validated against
# `package_id|package_version|content_fingerprint`. The library's identity is the
# coarser of the two, so two builds that share an id and a version cannot coexist —
# and two consecutive playtest rounds failed on exactly that disagreement (V0716-03,
# then V0717-01, the v0.7.17 round's only failed row).
#
# v0.7.18 ships an interim answer: restore compares fingerprints at the skip and
# REFUSES, naming both. Refusing is honest but it is not a way through — the tester
# holding the v0.7.18 build still cannot restore that backup. The owner settled at the
# 2026-09-06 walkthrough (decision 2) that the destination is to install the backup's
# package SIDE BY SIDE under a distinguishing identity, which needs a library identity
# that carries the content fingerprint. That is what this suite proves.
#
# WRITTEN BEFORE THE FIX. Against the shipped code every case here is red, and each is
# red for the right reason: the second install is rejected as "already installed", the
# registry can only describe one release per id/version, and restore refuses.
#
# THE SEQUENCE MATTERS, and it is why the last case exists. Restoring either v0.7.17
# fixture into an EMPTY library succeeds and every save resolves, because restore
# installs the backup's own pack and the saves agree with it. What failed on the
# tester's machine is Section 4 row 3: install the genuine v2 pack from the bundle
# FIRST, then restore. Only then do the two identities meet. A probe that skips that
# install measures nothing.

const Registry = preload("res://scripts/resources/CampaignPackRegistry.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const Preflight = preload("res://scripts/resources/CampaignArchivePreflight.gd")
const Service = preload("res://scripts/resources/CampaignBackupService.gd")
const Tier2 = preload("res://scripts/resources/Tier2Catalogue.gd")
const Budgets = preload("res://scripts/resources/ImportBudgets.gd")

const PACK_ID := "library-identity-pack"
const PACK_VERSION := "1.0"
const SLOT_ID := "library_identity_slot"

# The engine resolves a save's package against the real library root, so anything
# proving activation has to install there. Isolation comes from the runner giving each
# worker its own user:// directory.
const TEST_STORAGE_ROOT := Registry.DEFAULT_STORAGE_ROOT
const TEST_SAVE_DIR := "user://test_library_fingerprint_identity_saves"
const TEST_STATUS_ROOT := "user://test_library_fingerprint_identity_status"
const TEST_SCRATCH := "user://test_library_fingerprint_identity_scratch"
const TEST_BACKUP_PATH := "user://test_library_fingerprint_identity_backup.zip"

# The v0.7.17 return's own artifacts. The BROKEN backup the tester actually restored
# ships inside the bundle's tester-fixtures archive; the genuine v2 pack it collides
# with ships beside it. Absolute because both are produced outside res:// and live in
# the gitignored builds/ tree, so the case skips on a bare checkout.
const RETURN_BUNDLE_ENV := "PROMETHEUS_TEST_V0717_FIXTURE_BUNDLE"
const RETURN_BUNDLE_DEFAULT := "/workspace/godot-prometheus-env/builds/tester/Project_Prometheus_v0.7.17/tester-fixtures-v0.7.17.zip"
const RETURN_BUNDLE_ENTRY := "campaign_backup_v2.zip"
const RETURN_PACK_ENV := "PROMETHEUS_TEST_BACKUP_FIXTURE_PACK"
const RETURN_PACK_DEFAULT := "/workspace/godot-prometheus-env/builds/packs/v0.7.18/v076-migration-2.0.0.zip"
const RETURN_PACK_ID := "v076_migration_fixture"
const RETURN_PACK_VERSION := "2.0.0"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String, detail: String = "") -> void:
	if ok:
		print("OK  %s" % label)
		_passed += 1
	else:
		print("FAIL %s%s" % [label, "" if detail.is_empty() else ": %s" % detail])
		_failed += 1


func _run() -> void:
	print("=== Library Fingerprint Identity (LIBRARY-FINGERPRINT-IDENTITY) Test ===")
	_test_two_builds_of_one_version_coexist()
	_test_each_build_activates_against_its_own_save()
	_test_legacy_install_is_discovered_and_relocated()
	_test_restore_installs_beside_a_conflicting_build()
	_test_v0717_shipped_backup_restores_over_the_genuine_pack()
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
	}


func _limits():
	return Preflight.Limits.new(
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRIES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRY_COMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRY_UNCOMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_TOTAL_COMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_TOTAL_UNCOMPRESSED_BYTES
	)


func _reset_fixture() -> void:
	Installer._remove_tree(TEST_STORAGE_ROOT)
	Installer._remove_tree(TEST_SAVE_DIR)
	Installer._remove_tree(TEST_STATUS_ROOT)
	Installer._remove_tree(TEST_SCRATCH)
	Installer._remove_tree(Service.STAGING_DIR)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_BACKUP_PATH))


# `variant` changes one indexed document, so two packs share an id and a version and
# differ in content — the exact collision the coarse identity cannot see.
func _pack_documents(variant: String) -> Dictionary:
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


func _write_tree(pack_root: String, variant: String) -> void:
	var documents := _pack_documents(variant)
	for relative in documents:
		var path: String = pack_root.path_join(relative)
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(documents[relative]))
		file.close()


# A real archive, because installation is the surface under test and it only accepts
# a preflighted ZIP.
func _write_pack_zip(archive_path: String, variant: String) -> void:
	DirAccess.make_dir_recursive_absolute(archive_path.get_base_dir())
	if FileAccess.file_exists(archive_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(archive_path))
	var documents := _pack_documents(variant)
	var relatives: Array = documents.keys()
	relatives.sort()
	var packer := ZIPPacker.new()
	packer.open(archive_path)
	for relative in relatives:
		packer.start_file("%s/%s" % [PACK_ID, relative])
		packer.write_file(JSON.stringify(documents[relative]).to_utf8_buffer())
		packer.close_file()
	packer.close()


func _install(archive_path: String):
	var preflight = Preflight.inspect_zip(archive_path, _limits())
	if not preflight.valid:
		return null
	return Installer.new(TEST_STORAGE_ROOT).install_zip(archive_path, preflight)


func _fingerprint_of(pack_root: String) -> String:
	var errors: Array[String] = []
	var catalogue := Tier2.load_campaign_pack(pack_root, errors)
	return "" if catalogue == null else catalogue.content_fingerprint()


func _file_count(path: String) -> int:
	var total := 0
	var directory := DirAccess.open(path)
	if directory == null:
		return 0
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		if directory.current_is_dir():
			total += _file_count(path.path_join(name))
		else:
			total += 1
		name = directory.get_next()
	directory.list_dir_end()
	return total


# Deliberately scans `summaries()` rather than calling the registry's own
# fingerprint-aware lookup. A suite that references API the fix introduces cannot be
# run against the code it is supposed to fail on — it dies at parse — and then the
# "written before the fix" claim rests on a throwaway probe nobody keeps. This suite
# runs on both sides.
func _identity(
	registry, package_id: String, package_version: String, fingerprint: String
) -> Dictionary:
	for summary in registry.summaries():
		if (
			String(summary.get("package_id", "")) == package_id
			and String(summary.get("package_version", "")) == package_version
			and String(summary.get("content_fingerprint", "")) == fingerprint
		):
			return summary
	return {}


func _identity_count(registry, package_id: String, package_version: String) -> int:
	var total := 0
	for summary in registry.summaries():
		if (
			String(summary.get("package_id", "")) == package_id
			and String(summary.get("package_version", "")) == package_version
		):
			total += 1
	return total


func _records(event: StringName) -> Array:
	var diagnostics := root.get_node_or_null("DiagnosticsLog")
	if diagnostics == null or not diagnostics.has_method("snapshot"):
		return []
	var found: Array = []
	for entry in diagnostics.call("snapshot"):
		if StringName(entry.get("event", "")) == event:
			found.append(entry)
	return found


func _detach_content(nodes: Dictionary) -> void:
	nodes["campaign"].call("end_campaign")
	nodes["data"].call("select_campaign_source", "res://data")


# --- Cases --------------------------------------------------------------------


# The identity change itself. Two builds, one id, one version: today the second is
# rejected as "already installed", which is the whole defect stated as an install
# refusal instead of as a restore refusal.
func _test_two_builds_of_one_version_coexist() -> void:
	_reset_fixture()
	var diagnostics := root.get_node_or_null("DiagnosticsLog")
	if diagnostics != null and diagnostics.has_method("reset"):
		diagnostics.call("reset")
	var archive_a := TEST_SCRATCH.path_join("pack-a.zip")
	var archive_b := TEST_SCRATCH.path_join("pack-b.zip")
	_write_pack_zip(archive_a, "A")
	_write_pack_zip(archive_b, "B")

	var installed_a = _install(archive_a)
	_check(installed_a != null and installed_a.installed, "the first build installs")
	if installed_a == null or not installed_a.installed:
		return
	var installed_b = _install(archive_b)
	_check(
		installed_b != null and installed_b.installed,
		"a second build of the same id and version installs beside the first",
		"" if installed_b == null else str(installed_b.errors)
	)
	if installed_b == null or not installed_b.installed:
		return
	_check(
		installed_a.installed_path != installed_b.installed_path,
		"the two builds occupy distinguishable installed identities",
		installed_a.installed_path
	)
	var fingerprint_a := _fingerprint_of(installed_a.installed_path)
	var fingerprint_b := _fingerprint_of(installed_b.installed_path)
	_check(
		not fingerprint_a.is_empty() and fingerprint_a != fingerprint_b,
		"the fixture really is two different contents",
		fingerprint_a
	)

	var registry := Registry.new(TEST_STORAGE_ROOT)
	var summaries := registry.refresh()
	_check(
		summaries.size() == 2 and registry.errors().is_empty(),
		"discovery describes both builds and reports no error",
		"%d summaries, errors %s" % [summaries.size(), registry.errors()]
	)
	var found_a := _identity(registry, PACK_ID, PACK_VERSION, fingerprint_a)
	var found_b := _identity(registry, PACK_ID, PACK_VERSION, fingerprint_b)
	_check(
		(
			String(found_a.get("path", "")) == installed_a.installed_path
			and String(found_b.get("path", "")) == installed_b.installed_path
		),
		"the registry can be asked for one build by its content fingerprint"
	)
	# Two consecutive installs, and a return has to be able to tell them apart.
	# DiagnosticsLog collapses consecutive records sharing a dedupe key into one line
	# with a repeat count, so keying `pack | install` on id and version alone would
	# write these two as ONE record carrying only the first build's fingerprint —
	# re-creating, in the log, the coarse identity the library just stopped using.
	var install_records := _records(&"install")
	_check(
		install_records.size() == 2,
		"each build is installed under its own diagnostics record",
		str(install_records.size())
	)
	var recorded_both := false
	for entry in install_records:
		if fingerprint_b in String(entry.get("fields", "")):
			recorded_both = true
	_check(recorded_both, "the second build's record names its own content", str(install_records))

	# Installing the SAME bytes twice is still a duplicate — side-by-side is about
	# different content, not about permitting churn.
	var duplicate = _install(archive_a)
	_check(
		duplicate != null and not duplicate.installed,
		"re-installing identical content is still refused as already installed",
		"" if duplicate == null else str(duplicate.errors)
	)
	_reset_fixture()


# The point of the identity, rather than a property of the directory layout: a save
# made on one build has to reach THAT build while the other is installed.
func _test_each_build_activates_against_its_own_save() -> void:
	var nodes := _autoloads()
	if nodes.values().has(null):
		_check(false, "required autoloads unavailable")
		return
	_reset_fixture()
	var archive_a := TEST_SCRATCH.path_join("pack-a.zip")
	var archive_b := TEST_SCRATCH.path_join("pack-b.zip")
	_write_pack_zip(archive_a, "A")
	_write_pack_zip(archive_b, "B")
	var installed_a = _install(archive_a)
	var installed_b = _install(archive_b)
	if installed_a == null or not installed_a.installed:
		_check(false, "the first build installs")
		return
	if installed_b == null or not installed_b.installed:
		_check(false, "the second build installs")
		return
	var fingerprint_a := _fingerprint_of(installed_a.installed_path)
	var fingerprint_b := _fingerprint_of(installed_b.installed_path)

	var expectations := {fingerprint_a: installed_a.installed_path}
	expectations[fingerprint_b] = installed_b.installed_path
	for fingerprint in expectations:
		var selected: bool = nodes["data"].call(
			"select_saved_campaign_source", PACK_ID, PACK_VERSION, 1, fingerprint
		)
		_check(
			selected,
			(
				"a save naming content %s activates while the other build is installed"
				% fingerprint.right(8)
			),
		)
		if not selected:
			continue
		var identity: Dictionary = nodes["data"].call("active_package_identity")
		_check(
			(
				String(identity.get("content_fingerprint", "")) == fingerprint
				and String(identity.get("path", "")) == String(expectations[fingerprint])
			),
			"activation selected the build the save names, not its namesake",
			str(identity)
		)
	_detach_content(nodes)
	_reset_fixture()


# A library installed before this change keeps its release directly at
# installed/<id>/<version>. Discovery must keep reading it, and installing a second
# build there must relocate it rather than nest inside it or overwrite it.
func _test_legacy_install_is_discovered_and_relocated() -> void:
	_reset_fixture()
	var legacy_root := Registry.installed_path(TEST_STORAGE_ROOT, PACK_ID, PACK_VERSION)
	_write_tree(legacy_root, "A")
	var legacy_fingerprint := _fingerprint_of(legacy_root)
	var legacy_files := _file_count(legacy_root)

	var registry := Registry.new(TEST_STORAGE_ROOT)
	var summaries := registry.refresh()
	_check(
		summaries.size() == 1 and registry.errors().is_empty(),
		"a pre-fingerprint install is still discovered where it sits",
		"%d summaries, errors %s" % [summaries.size(), registry.errors()]
	)

	var archive_b := TEST_SCRATCH.path_join("pack-b.zip")
	_write_pack_zip(archive_b, "B")
	var installed_b = _install(archive_b)
	_check(
		installed_b != null and installed_b.installed,
		"a different build installs alongside a pre-fingerprint one",
		"" if installed_b == null else str(installed_b.errors)
	)
	if installed_b == null or not installed_b.installed:
		return
	registry = Registry.new(TEST_STORAGE_ROOT)
	summaries = registry.refresh()
	_check(
		summaries.size() == 2 and registry.errors().is_empty(),
		"both builds are discoverable after the relocation",
		"%d summaries, errors %s" % [summaries.size(), registry.errors()]
	)
	var relocated := _identity(registry, PACK_ID, PACK_VERSION, legacy_fingerprint)
	_check(
		(
			not relocated.is_empty()
			and String(relocated.get("path", "")) != legacy_root
			and _file_count(String(relocated.get("path", ""))) == legacy_files
		),
		"the pre-fingerprint install moved to its own identity with every byte intact",
		str(relocated.get("path", ""))
	)
	_reset_fixture()


# The tester's shape, with content this suite controls: a build is installed, and a
# backup carrying a DIFFERENT build of the same id and version is restored over it.
# v0.7.18 refuses here. The destination installs beside it and leaves both usable.
func _test_restore_installs_beside_a_conflicting_build() -> void:
	var nodes := _autoloads()
	if nodes.values().has(null):
		_check(false, "required autoloads unavailable")
		return
	_reset_fixture()
	nodes["save"].call("configure_save_dir_for_tests", TEST_SAVE_DIR)

	# A backup of a library holding build B, exported by the real surfaces so its pack
	# component and its save carry the same fingerprint.
	var archive_b := TEST_SCRATCH.path_join("pack-b.zip")
	_write_pack_zip(archive_b, "B")
	var seeded = _install(archive_b)
	if seeded == null or not seeded.installed:
		_check(false, "build B installs for the backup export")
		return
	var fingerprint_b := _fingerprint_of(seeded.installed_path)
	nodes["data"].call("select_tier2_campaign_source", seeded.installed_path, PACK_ID, PACK_VERSION)
	var roster: Array = nodes["data"].call("get_campaign_pack_roster", "heroes")
	nodes["state"].call("load_roster_resources", roster, "campaign_pack_roster", "heroes")
	nodes["campaign"].call("start_campaign", "fixture")
	var save: RefCounted = nodes["state"].call("capture_campaign_save", "Library identity fixture")
	if not bool(nodes["save"].call("save_slot", SLOT_ID, save, "manual")):
		_check(false, "the fixture save is written")
		return
	var service := Service.new(TEST_STORAGE_ROOT, nodes["save"], TEST_STATUS_ROOT)
	var exported = service.export_backup(TEST_BACKUP_PATH)
	if not exported.exported:
		_check(false, "the backup exports", str(exported.errors))
		return
	_detach_content(nodes)
	nodes["save"].call("delete_slot", SLOT_ID)
	Installer._remove_tree(TEST_STORAGE_ROOT)

	# Now the collision: a DIFFERENT build at the same id and version is what is
	# installed when the backup arrives.
	var archive_a := TEST_SCRATCH.path_join("pack-a.zip")
	_write_pack_zip(archive_a, "A")
	var installed_a = _install(archive_a)
	if installed_a == null or not installed_a.installed:
		_check(false, "build A installs before the restore")
		return
	var fingerprint_a := _fingerprint_of(installed_a.installed_path)
	var files_a := _file_count(installed_a.installed_path)

	var restore_service := Service.new(TEST_STORAGE_ROOT, nodes["save"], TEST_STATUS_ROOT)
	var restored = restore_service.restore_backup(TEST_BACKUP_PATH)
	_check(
		restored.restored,
		"a backup whose build differs from the installed one restores instead of refusing",
		str(restored.errors)
	)
	if not restored.restored:
		_reset_fixture()
		return
	_check(
		restored.installed_packages.size() == 1 and restored.skipped_packages.is_empty(),
		"the backup's build is installed rather than skipped",
		"installed %s skipped %s" % [restored.installed_packages, restored.skipped_packages]
	)
	_check(
		(
			_file_count(installed_a.installed_path) == files_a
			and _fingerprint_of(installed_a.installed_path) == fingerprint_a
		),
		"the build that was already installed is untouched"
	)
	var registry := Registry.new(TEST_STORAGE_ROOT)
	registry.refresh()
	_check(
		(
			not _identity(registry, PACK_ID, PACK_VERSION, fingerprint_a).is_empty()
			and not _identity(registry, PACK_ID, PACK_VERSION, fingerprint_b).is_empty()
		),
		"both builds are installed and told apart afterwards"
	)
	for slot_id in restored.restored_slots:
		var revalidated: Dictionary = nodes["save"].call("revalidate_slot", String(slot_id))
		_check(
			bool(revalidated.get("ok", false)),
			"restored slot '%s' resolves against its own build" % slot_id,
			str(revalidated.get("errors", []))
		)
	_detach_content(nodes)
	_reset_fixture()


# The return's own artifacts, in the tester's own sequence. Skipped where the
# gitignored builds/ tree is absent, so the suite stays runnable on a bare checkout.
#
# The backup here is the BROKEN one the v0.7.17 bundle actually shipped — its pack
# component and its saves carry sha256:74e9e91e…, while the genuine v2 pack the same
# bundle ships carries sha256:45391892…. That disagreement is the tester's failed row.
func _test_v0717_shipped_backup_restores_over_the_genuine_pack() -> void:
	var bundle := OS.get_environment(RETURN_BUNDLE_ENV)
	if bundle.is_empty():
		bundle = RETURN_BUNDLE_DEFAULT
	var pack_path := OS.get_environment(RETURN_PACK_ENV)
	if pack_path.is_empty():
		pack_path = RETURN_PACK_DEFAULT
	if not FileAccess.file_exists(bundle) or not FileAccess.file_exists(pack_path):
		print("SKIP the v0.7.17 return artifacts are not on this machine (%s)" % bundle)
		return
	var nodes := _autoloads()
	if nodes.values().has(null):
		_check(false, "required autoloads unavailable")
		return
	_reset_fixture()
	nodes["save"].call("configure_save_dir_for_tests", TEST_SAVE_DIR)

	var backup_path := TEST_SCRATCH.path_join("shipped-campaign-backup.zip")
	if not _extract_from_zip(bundle, RETURN_BUNDLE_ENTRY, backup_path):
		_check(false, "the shipped backup is readable out of the tester-fixtures archive")
		return

	# Section 4 rows 1-2: the tester installs the shipped campaign packs.
	var installed = _install(pack_path)
	_check(
		installed != null and installed.installed,
		"the genuine v2 pack installs",
		"" if installed == null else str(installed.errors)
	)
	if installed == null or not installed.installed:
		return
	var genuine_fingerprint := _fingerprint_of(installed.installed_path)
	var genuine_files := _file_count(installed.installed_path)

	# Section 4 row 3: restore the backup on top of it. This is the row that failed.
	var service := Service.new(TEST_STORAGE_ROOT, nodes["save"], TEST_STATUS_ROOT)
	var inspected = service.inspect_backup(backup_path)
	_check(inspected.valid, "the shipped backup inspects as a backup", str(inspected.errors))
	if not inspected.valid:
		return
	var restored = service.restore_backup(backup_path)
	_check(
		restored.restored,
		"the shipped v0.7.17 backup restores over the genuine v2 pack",
		str(restored.errors)
	)
	if not restored.restored:
		_reset_fixture()
		return
	_check(
		restored.installed_packages.size() == 1 and restored.skipped_packages.is_empty(),
		"the backup's own build of v2.0.0 is installed beside the genuine one",
		"installed %s skipped %s" % [restored.installed_packages, restored.skipped_packages]
	)
	_check(
		(
			_file_count(installed.installed_path) == genuine_files
			and _fingerprint_of(installed.installed_path) == genuine_fingerprint
		),
		"the genuine v2 pack is unchanged by the restore"
	)
	_check(
		restored.restored_slots.size() == 2,
		"both saves in the backup are restored",
		str(restored.restored_slots)
	)
	for slot_id in restored.restored_slots:
		var revalidated: Dictionary = nodes["save"].call("revalidate_slot", String(slot_id))
		_check(
			bool(revalidated.get("ok", false)),
			"restored slot '%s' resolves — the tester's failed row, now passing" % slot_id,
			str(revalidated.get("errors", []))
		)
	var registry := Registry.new(TEST_STORAGE_ROOT)
	registry.refresh()
	_check(
		_identity_count(registry, RETURN_PACK_ID, RETURN_PACK_VERSION) == 2,
		"the library holds both builds of v076_migration_fixture 2.0.0"
	)
	_detach_content(nodes)
	_reset_fixture()


func _extract_from_zip(archive_path: String, entry: String, destination: String) -> bool:
	var reader := ZIPReader.new()
	if reader.open(archive_path) != OK:
		return false
	var payload := reader.read_file(entry)
	reader.close()
	if payload.is_empty():
		return false
	DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
	var file := FileAccess.open(destination, FileAccess.WRITE)
	if file == null:
		return false
	file.store_buffer(payload)
	file.close()
	return true
