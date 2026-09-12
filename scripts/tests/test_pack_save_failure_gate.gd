extends SceneTree
# Pack-save Slice 2, stage 2G: the failure gate.
#
# Stages 2A-2F each proved their own seam, mostly as pure functions over
# synthetic identities. This suite drives the same set through the real
# registry, DataManager, GameState and SaveManager, because the contract the
# player depends on is not "resolve_source returns a status" but "a load that
# cannot succeed changes nothing": not the installed catalogue, not the active
# runtime content, not the save bytes, and not the slot index.
#
# Every failure case therefore asserts an outcome AND the four things that must
# be unchanged after it.

const Registry = preload("res://scripts/resources/CampaignPackRegistry.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const Recovery = preload("res://scripts/save/SaveRecovery.gd")
const Migration = preload("res://scripts/save/SaveMigrationService.gd")
const SaveManagerScript = preload("res://scripts/autoloads/SaveManager.gd")

const PACK_ID := "gate-pack"
const V1 := "1.0"
const V2 := "2.0"
const V3 := "3.0"
const TEST_SAVE_DIR := "user://test_pack_save_failure_gate"

var _passed := 0
var _failed := 0
var _dm: Node
var _gs: Node
var _cm: Node
var _sm: Node


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
	print("=== Pack Save Failure Gate (stage 2G) Test ===")
	_dm = root.get_node_or_null("DataManager")
	_gs = root.get_node_or_null("GameState")
	_cm = root.get_node_or_null("CampaignManager")
	_sm = root.get_node_or_null("SaveManager")
	if _dm == null or _gs == null or _cm == null or _sm == null:
		_check(false, "required autoloads unavailable")
		print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
		quit(1)
		return
	_sm.call("configure_save_dir_for_tests", TEST_SAVE_DIR)
	_test_chain_endpoints_install()
	_test_end_to_end_gate()
	_test_diagnostic_severity()
	_teardown()
	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _teardown() -> void:
	_dm.call("select_campaign_source", "res://data")
	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
	Installer._remove_tree(TEST_SAVE_DIR)


# --- Multistep chain ----------------------------------------------------------


# A pack that supersedes two of its own earlier releases must ship both edges.
# The intermediate edge's destination is the version in the middle, which by
# construction is NOT this pack's own catalogue.
func _test_chain_endpoints_install() -> void:
	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
	var identities := _identities_for([V1, V2, V3])
	var edge_a := _edge(identities[V1], identities[V2], {})
	var edge_b := _edge(identities[V2], identities[V3], {"class": {"gate_class_1": "gate_class_3"}})
	_write_pack(V3, [edge_a, edge_b])
	var registry := Registry.new(Registry.DEFAULT_STORAGE_ROOT)
	var summaries: Array[Dictionary] = registry.refresh()
	_check(
		summaries.size() == 1,
		"a pack shipping a two-edge migration chain is still installable",
		"%d summaries, errors: %s" % [summaries.size(), registry.errors()]
	)
	if summaries.size() != 1:
		return
	var chain := Migration.plan_chain(
		identities[V1], identities[V3], summaries[0]["save_migrations"]
	)
	_check(
		chain["ok"] and chain["chain"].size() == 2,
		"the installed pack's declarations plan the complete two-step chain",
		str(chain)
	)


# --- End-to-end load gate -----------------------------------------------------


# One real save, produced by the real capture path, driven against every
# disposition. Each failing case asserts the four invariants: the active
# catalogue, the installed library, the save bytes, and the index row are all
# exactly what they were before the attempt.
func _test_end_to_end_gate() -> void:
	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
	Installer._remove_tree(TEST_SAVE_DIR)
	var identities := _identities_for([V1, V2, V3])
	if identities.size() != 3:
		return
	_write_pack(V1, [])
	var pack_v1: String = Registry.installed_path(Registry.DEFAULT_STORAGE_ROOT, PACK_ID, V1)
	_dm.call("select_tier2_campaign_source", pack_v1, PACK_ID, V1)
	var roster: Array = _dm.call("get_campaign_pack_roster", "heroes")
	_gs.call("load_roster_resources", roster, "campaign_pack_roster", "heroes")
	_cm.call("start_campaign", "fixture")
	var save: RefCounted = _gs.call("capture_campaign_save", "Gate run")
	if not bool(_sm.call("save_slot", "run", save)):
		_check(false, "the fixture run is saved to a slot")
		return
	_check(
		(
			String(save.source.get("package_version", "")) == V1
			and String(save.roster["units"][0].get("class_id", "")) == _class_id(V1)
		),
		"the captured save names the installed release and its class id",
		str(save.source)
	)

	var exact: RefCounted = _sm.call("load_slot", "run")
	_check(
		exact != null and String(exact.source.get("package_version", "")) == V1,
		"exact load succeeds against the release the save was written on"
	)

	# Successor: only a later release is installed, and it supersedes the save's
	# version through two declared steps.
	var edge_a := _edge(identities[V1], identities[V2], {})
	var edge_b := _edge(identities[V2], identities[V3], {"class": {_class_id(V1): _class_id(V3)}})
	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
	_write_pack(V3, [edge_a, edge_b])
	var before := _snapshot()
	var migrated: RefCounted = _sm.call("load_slot", "run")
	_check(
		(
			migrated != null
			and String(migrated.source.get("package_version", "")) == V3
			and (
				String(migrated.source.get("content_fingerprint", ""))
				== String(identities[V3]["content_fingerprint"])
			)
			and String(migrated.roster["units"][0].get("class_id", "")) == _class_id(V3)
		),
		"a two-step chain migrates the save in memory onto the installed release",
		str(migrated.source) if migrated != null else "load refused"
	)
	_check(
		_snapshot()["save_bytes"] == before["save_bytes"],
		"a successful migration rewrites no save bytes"
	)

	# Every remaining case must fail closed. The chain is deliberately broken a
	# different way each time.
	var unreachable := {
		"package_id": PACK_ID,
		"package_version": "9.0",
		"content_schema_version": int(identities[V3]["content_schema_version"]),
		"content_fingerprint": "sha256:%s" % "e".repeat(64),
		"campaign_id": "fixture",
	}
	var cases := [
		{
			"label": "the saved package is not installed at all",
			"install": [],
			"reason": Recovery.REASON_MISSING,
		},
		{
			"label": "the chain has a gap the installed pack does not bridge",
			"install": [edge_b],
			"reason": Recovery.REASON_INCOMPATIBLE,
		},
		{
			"label": "the chain would cycle back through a version it already left",
			"install":
			[
				edge_a,
				_edge(identities[V2], identities[V1], {}),
				_edge(unreachable, identities[V3], {})
			],
			"reason": Recovery.REASON_INCOMPATIBLE,
		},
		{
			"label": "two edges leave the saved version ambiguously",
			"install": [edge_a, _edge(identities[V1], identities[V3], {}), edge_b],
			"reason": Recovery.REASON_INCOMPATIBLE,
		},
		{
			"label": "the final edge renames content the destination does not contain",
			"install":
			[
				edge_a,
				_edge(identities[V2], identities[V3], {"class": {_class_id(V1): "absent_class"}})
			],
			"reason": Recovery.REASON_INCOMPATIBLE,
		},
	]
	for case in cases:
		_run_failure_case(String(case["label"]), case["install"], String(case["reason"]))

	# Same version, different bytes: the pack was edited under the save.
	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
	_write_pack(V1, [])
	_edit_installed_content(V1)
	_run_prepared_failure_case(
		"the installed release keeps the saved version but no longer matches its content",
		Recovery.REASON_FINGERPRINT_MISMATCH
	)

	# A pack whose declaration is malformed is refused at discovery, but it must
	# not take the rest of the library with it.
	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
	var malformed := _edge(identities[V1], identities[V3], {})
	malformed["operations"] = [{"op": "delete_field", "path": "integrity"}]
	_write_pack(V3, [malformed])
	_write_pack(V1, [])
	var registry := Registry.new(Registry.DEFAULT_STORAGE_ROOT)
	var summaries: Array[Dictionary] = registry.refresh()
	_check(
		(
			summaries.size() == 1
			and String(summaries[0]["package_version"]) == V1
			and registry.errors().any(func(e): return "path_not_allowed" in e)
		),
		"a malformed migration operation disqualifies only its own release",
		"%s / %s" % [summaries.size(), registry.errors()]
	)

	# Old saves stay readable. A format-1 document predates fingerprints
	# entirely; refusing it would strand every run made before this slice.
	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
	_write_pack(V1, [])
	var legacy_document: Dictionary = save.to_dict()
	legacy_document["format_version"] = 1
	legacy_document.erase("source")
	var legacy: RefCounted = SaveData.from_dict(legacy_document)
	_check(bool(_sm.call("save_slot", "legacy", legacy)), "the format-1 fixture is stored")
	var legacy_loaded: RefCounted = _sm.call("load_slot", "legacy")
	_check(
		(
			legacy_loaded != null
			and String(legacy_loaded.source.get("package_id", "")) == PACK_ID
			and (
				String(legacy_loaded.source.get("content_fingerprint", ""))
				== String(identities[V1]["content_fingerprint"])
			)
		),
		"a format-1 save of an installed pack loads and adopts the installed identity",
		str(legacy_loaded.source) if legacy_loaded != null else "load refused"
	)


# V0715-05. A disabled save is an expected state with a recovery UI, so it must not
# be reported as an engine fault, and the same unchanged state must not be re-reported
# on every load attempt. The returned v0.7.15 log carried eight red lines for one
# intentionally retained save. Severity and the migration wording are both functions
# here precisely so this can be asserted rather than eyeballed in a log.
func _test_diagnostic_severity() -> void:
	var expected := {
		Recovery.REASON_INVALID: SaveManagerScript.SEVERITY_ERROR,
		Recovery.REASON_MISSING: SaveManagerScript.SEVERITY_WARNING,
		Recovery.REASON_INCOMPATIBLE: SaveManagerScript.SEVERITY_WARNING,
		Recovery.REASON_FINGERPRINT_MISMATCH: SaveManagerScript.SEVERITY_WARNING,
		Recovery.REASON_MISSING_CONTENT: SaveManagerScript.SEVERITY_WARNING,
	}
	var severities_ok := (
		SaveManagerScript.diagnostic_severity("") == SaveManagerScript.SEVERITY_ERROR
	)
	for reason in expected:
		if SaveManagerScript.diagnostic_severity(String(reason)) != String(expected[reason]):
			severities_ok = false
	_check(
		severities_ok,
		"only an unreadable document is reported as an engine error",
		"unexpected severity mapping"
	)

	var disabled := {
		"reason": Recovery.REASON_MISSING, "errors": ["save_source_missing"] as Array[String]
	}
	var first: String = _sm.call("report_content_diagnostic", "slot 'severity'", disabled)
	var repeat: String = _sm.call("report_content_diagnostic", "slot 'severity'", disabled)
	var changed := {
		"reason": Recovery.REASON_MISSING_CONTENT,
		"errors": ["SaveData: saved campaign content could not be activated"] as Array[String],
	}
	var after_change: String = _sm.call("report_content_diagnostic", "slot 'severity'", changed)
	_check(
		(
			first == SaveManagerScript.SEVERITY_WARNING
			and repeat == SaveManagerScript.SEVERITY_SUPPRESSED
			and after_change == SaveManagerScript.SEVERITY_WARNING
		),
		"an unchanged disabled state is recorded once, and a changed one is recorded again",
		"%s / %s / %s" % [first, repeat, after_change]
	)

	# The four migration causes the return conflated must stay four outcomes, and a
	# successful preview must not be worded as a failure at all.
	var kinds := [
		Recovery.migration_kind(["migration_source_invalid"]),
		Recovery.migration_kind(["migration_source_identity_mismatch"]),
		Recovery.migration_kind(["migration_destination_missing:map:campaign-pack://p/1.0.0/m"]),
		Recovery.migration_kind([]),
	]
	var messages := {}
	for error_set in [
		["migration_source_invalid"],
		["migration_source_identity_mismatch"],
		["migration_destination_missing:map:campaign-pack://p/1.0.0/m"],
		["migration_candidate_reference_unscoped:map:campaign-pack://p/1.0.0/m:map_runtime.map_id"],
		["migration_commit_failed"],
	]:
		messages[Recovery.migration_message(error_set)] = true
	var leaks_engine_text := false
	for message in messages:
		if "migration_" in String(message) or "campaign-pack://" in String(message):
			leaks_engine_text = true
	_check(
		(
			(
				kinds
				== [
					Recovery.MIGRATION_SOURCE_INVALID,
					Recovery.MIGRATION_IDENTITY_MISMATCH,
					Recovery.MIGRATION_CONTENT_MISSING,
					Recovery.MIGRATION_OK,
				]
			)
			and messages.size() == 5
			and not leaks_engine_text
			and Recovery.migration_message([]).is_empty()
		),
		"each migration cause gets its own player-facing message and no engine text",
		"%s / %d distinct message(s) / leaks=%s" % [kinds, messages.size(), leaks_engine_text]
	)


func _run_failure_case(label: String, migrations: Array, reason: String) -> void:
	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
	if not migrations.is_empty():
		_write_pack(V3, migrations)
	_run_prepared_failure_case(label, reason)


# The library is already in the state under test; drive the load and prove
# nothing moved.
func _run_prepared_failure_case(label: String, reason: String) -> void:
	var before := _snapshot()
	var loaded: RefCounted = _sm.call("load_slot", "run")
	var after := _snapshot()
	var diagnostic: Dictionary = _sm.call("revalidate_slot", "run").get("diagnostic", {})
	_check(loaded == null, "load is refused when %s" % label)
	_check(
		String(diagnostic.get("reason", "")) == reason,
		"the refusal is described to the player as %s when %s" % [reason, label],
		str(diagnostic)
	)
	_check(
		(
			after["active"] == before["active"]
			and after["save_bytes"] == before["save_bytes"]
			and after["installed"] == before["installed"]
		),
		"nothing changes when %s" % label,
		"%s -> %s" % [before, after]
	)


func _snapshot() -> Dictionary:
	var registry := Registry.new(Registry.DEFAULT_STORAGE_ROOT)
	var installed: Array[String] = []
	for summary in registry.refresh():
		installed.append(
			(
				"%s@%s:%s"
				% [
					summary["package_id"],
					summary["package_version"],
					summary["content_fingerprint"]
				]
			)
		)
	var file := FileAccess.open(_sm.call("get_slot_path", "run"), FileAccess.READ)
	var bytes := ""
	if file != null:
		bytes = file.get_as_text()
		file.close()
	return {
		"active": _dm.call("active_package_identity").duplicate(true),
		"installed": installed,
		"save_bytes": bytes,
	}


# Rewrite one installed document so the catalogue hashes differently while the
# version on the box stays the same.
func _edit_installed_content(version: String) -> void:
	var path: String = (
		Registry
		. installed_path(Registry.DEFAULT_STORAGE_ROOT, PACK_ID, version)
		. path_join("data/class.json")
	)
	var file := FileAccess.open(path, FileAccess.READ)
	var document: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	document["base_hp"] = int(document["base_hp"]) + 5
	var out := FileAccess.open(path, FileAccess.WRITE)
	out.store_string(JSON.stringify(document))
	out.close()


# --- Fixtures -----------------------------------------------------------------


# Build each version once, read the fingerprint the catalogue actually computes,
# and keep only the identity. Declarations that name a version's fingerprint
# cannot be written by hand: they are whatever the content hashes to.
func _identities_for(versions: Array) -> Dictionary:
	var identities := {}
	for version in versions:
		Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
		_write_pack(String(version), [])
		var registry := Registry.new(Registry.DEFAULT_STORAGE_ROOT)
		var summaries: Array[Dictionary] = registry.refresh()
		if summaries.is_empty():
			_check(false, "fixture pack %s is discoverable" % version, str(registry.errors()))
			continue
		identities[version] = {
			"package_id": PACK_ID,
			"package_version": String(version),
			"content_schema_version": int(summaries[0]["content_schema_version"]),
			"content_fingerprint": String(summaries[0]["content_fingerprint"]),
			"campaign_id": "fixture",
		}
	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
	return identities


func _edge(source: Dictionary, destination: Dictionary, aliases: Dictionary) -> Dictionary:
	var declaration := {
		"source_package_id": source["package_id"],
		"source_package_version": source["package_version"],
		"source_content_schema_version": source["content_schema_version"],
		"source_content_fingerprint": source["content_fingerprint"],
		"destination_package_id": destination["package_id"],
		"destination_package_version": destination["package_version"],
		"destination_content_schema_version": destination["content_schema_version"],
		"destination_content_fingerprint": destination["content_fingerprint"],
		"aliases": {},
		"operations": [],
	}
	for family in Migration.FAMILIES:
		declaration["aliases"][family] = aliases.get(family, {})
	return declaration


# The class id carries the version so each release hashes differently and so the
# chain has something real to rename.
func _class_id(version: String) -> String:
	return "gate_class_%s" % version.split(".")[0]


func _write_pack(version: String, migrations: Array) -> void:
	var pack_root: String = Registry.installed_path(Registry.DEFAULT_STORAGE_ROOT, PACK_ID, version)
	var class_id := _class_id(version)
	var files := {
		"manifest.json":
		{
			"id": PACK_ID,
			"version": version,
			"forked_from": "",
			"builder_content_version": "0.4",
			"format_version": 1,
			"save_migrations": migrations,
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
				{"kind": "class", "id": class_id, "path": "data/class.json"},
				{"kind": "weapon", "id": "gate_blade", "path": "data/weapon.json"}
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
					"class_id": class_id,
					"inventory": [{"weapon_id": "gate_blade", "uses": -1}]
				}
			]
		},
		"data/class.json":
		{
			"id": class_id,
			"display_name": "Gate",
			"base_hp": 20,
			"base_movement": 5,
			"allowed_weapon_families": ["sword"],
			"weapon_wexp_bases": {"sword": 1},
			"weapon_wexp_caps": {"sword": 400}
		},
		"data/weapon.json":
		{
			"id": "gate_blade",
			"display_name": "Gate Blade",
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
		var path: String = pack_root.path_join(relative)
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(files[relative]))
		file.close()
