extends SceneTree
# Pack-save Slice 3. Stage 3A covers the backup envelope as pure data: identity
# rules, digests, deterministic ordering, and the artifact discriminator that keeps
# a pack, a portable save and a backup from being mistaken for one another.
#
# Everything here is a static call. There is no filesystem in this stage, so a
# failure names a contract defect rather than a disk condition.

const Envelope = preload("res://scripts/save/BackupEnvelope.gd")
const Service = preload("res://scripts/resources/CampaignBackupService.gd")
const Registry = preload("res://scripts/resources/CampaignPackRegistry.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const StatusRecord = preload("res://scripts/resources/CampaignStatusRecord.gd")
const Exporter = preload("res://scripts/resources/CampaignPackExporter.gd")

const PACK_ID := "backup-fixture-pack"
const PACK_VERSION := "1.0"
# The engine resolves a save's package against the real library root, so restore has
# to install there for the restored save to be runnable. Isolation comes from the
# test runner giving each worker its own user:// directory, as the Slice 2 suite does.
const TEST_STORAGE_ROOT := Registry.DEFAULT_STORAGE_ROOT
const TEST_SAVE_DIR := "user://test_pack_save_exports_saves"
const TEST_STATUS_ROOT := "user://test_pack_save_exports_status"
const TEST_BACKUP_PATH := "user://test_pack_save_exports_backup.zip"
const TEST_INNER_PACK_PATH := "user://test_pack_save_exports_inner.zip"

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
	print("=== Pack Save Exports (stage 3A) Test ===")
	_test_digests()
	_test_identity_rules()
	_test_manifest_round_trip()
	_test_manifest_rejections()
	_test_user_state_round_trip()
	_test_user_state_rejections()
	_test_artifact_classification()
	_test_accounted_paths()
	_test_backup_write()
	_test_backup_selection()
	_test_backup_inspection()
	_test_backup_restore()
	_test_clean_pack_and_masquerade()
	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


# --- Helpers ------------------------------------------------------------------


func _bytes(text: String) -> PackedByteArray:
	return text.to_utf8_buffer()


func _pack_component(id: String = "base_game", version: String = "1.0.0") -> Dictionary:
	return Envelope.build_pack_component(id, version, _bytes("pack:%s:%s" % [id, version]))


func _user_state_component() -> Dictionary:
	return Envelope.build_user_state_component(_bytes("{}"))


func _manifest(components: Array[Dictionary]) -> Dictionary:
	return Envelope.build_manifest(components, "2026-08-27T00:00:00")


func _parse(manifest: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	return Envelope.parse_manifest(manifest, errors)


func _rejects(manifest: Variant, label: String) -> void:
	var errors: Array[String] = []
	var parsed := Envelope.parse_manifest(manifest, errors)
	_check(parsed.is_empty() and not errors.is_empty(), label, "accepted: %s" % str(manifest))


# --- 3A: digests --------------------------------------------------------------


func _test_digests() -> void:
	var value := Envelope.digest(_bytes("abc"))
	_check(
		value == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
		"digest is sha256",
		value
	)
	_check(Envelope.is_valid_digest(value), "a real digest validates")
	_check(not Envelope.is_valid_digest(value.substr(0, 40)), "a 40-hex digest is refused")
	_check(not Envelope.is_valid_digest(value.to_upper()), "an upper-case digest is refused")
	_check(not Envelope.is_valid_digest(1234), "a non-string digest is refused")
	_check(
		Envelope.digest(_bytes("abc")) != Envelope.digest(_bytes("abd")),
		"digests are content sensitive"
	)


# --- 3A: identity and derived paths -------------------------------------------


func _test_identity_rules() -> void:
	_check(Envelope.is_safe_identity("base_game"), "an ordinary id is safe")
	_check(Envelope.is_safe_identity("1.0.0"), "a dotted version is safe")
	_check(not Envelope.is_safe_identity(""), "an empty id is refused")
	_check(not Envelope.is_safe_identity(".."), "a parent-directory id is refused")
	_check(not Envelope.is_safe_identity(".hidden"), "a dot-prefixed id is refused")
	_check(not Envelope.is_safe_identity("packs/evil"), "a separator in an id is refused")
	_check(not Envelope.is_safe_identity("a".repeat(65)), "an over-long id is refused")
	_check(
		Envelope.pack_component_path("base_game", "1.0.0") == "packs/base_game-1.0.0.zip",
		"pack component paths are derived"
	)
	_check(
		Envelope.save_component_path("autosave") == "user_state/saves/autosave.json",
		"save component paths are derived"
	)


# --- 3A: envelope round trip --------------------------------------------------


func _test_manifest_round_trip() -> void:
	var built := _manifest(
		[_user_state_component(), _pack_component("zeta_pack"), _pack_component()]
	)
	var paths: Array[String] = []
	for component in built["components"]:
		paths.append(String(component["path"]))
	var sorted := paths.duplicate()
	sorted.sort()
	_check(paths == sorted, "built components are ordered by path", str(paths))
	var parsed := _parse(built)
	_check(not parsed.is_empty(), "a built envelope parses")
	_check(parsed["components"].size() == 3, "every component survives the round trip")
	_check(Envelope.pack_components(parsed).size() == 2, "pack components are queryable")
	_check(
		(
			String(Envelope.user_state_component(parsed).get("path", ""))
			== (Envelope.USER_STATE_MANIFEST_PATH)
		),
		"the user-state component is queryable"
	)
	# Two builds of the same content must agree everywhere except the stamp, which
	# is the only field a caller supplies.
	var again := Envelope.build_manifest(
		[_pack_component(), _pack_component("zeta_pack"), _user_state_component()],
		"2026-08-27T00:00:00"
	)
	_check(again == built, "building the same content twice is deterministic")


func _test_manifest_rejections() -> void:
	_rejects("not a dictionary", "a non-object envelope is refused")
	var missing_version := _manifest([_pack_component()])
	missing_version.erase("backup_format_version")
	_rejects(missing_version, "an envelope without a format version is refused")
	var future := _manifest([_pack_component()])
	future["backup_format_version"] = Envelope.FORMAT_VERSION + 1
	_rejects(future, "a future format version is refused")
	var wrong_kind := _manifest([_pack_component()])
	wrong_kind["artifact_kind"] = "campaign_pack"
	_rejects(wrong_kind, "an envelope that is not a backup is refused")
	var weak_digest := _manifest([_pack_component()])
	weak_digest["digest_algorithm"] = "sha1"
	_rejects(weak_digest, "a weaker digest algorithm is refused")
	var empty := _manifest([])
	_rejects(empty, "an envelope with no components is refused")
	var duplicated := _manifest([_pack_component(), _pack_component()])
	_rejects(duplicated, "a duplicated component is refused")
	var two_states := _manifest([_user_state_component(), _user_state_component()])
	_rejects(two_states, "two user-state components are refused")

	var relocated := _manifest([_pack_component()])
	relocated["components"][0]["path"] = "packs/../../escape.zip"
	_rejects(relocated, "a component that names its own path is refused")
	var unsafe_identity := _manifest([_pack_component()])
	unsafe_identity["components"][0]["package_id"] = "../escape"
	_rejects(unsafe_identity, "an unsafe package identity is refused")
	var bad_size := _manifest([_pack_component()])
	bad_size["components"][0]["bytes"] = -1
	_rejects(bad_size, "a negative component size is refused")
	var no_digest := _manifest([_pack_component()])
	no_digest["components"][0].erase("sha256")
	_rejects(no_digest, "a component without a digest is refused")
	var unknown_kind := _manifest([_pack_component()])
	unknown_kind["components"][0]["kind"] = "settings"
	_rejects(unknown_kind, "an unknown component kind is refused")
	var misplaced_state := _manifest([_user_state_component()])
	misplaced_state["components"][0]["path"] = "user_state/elsewhere.json"
	_rejects(misplaced_state, "a relocated user-state component is refused")

	# Case-folding collisions matter because restore writes to case-insensitive
	# filesystems, where two components would silently become one file.
	var folded := _manifest([_pack_component("base_game"), _pack_component("BASE_GAME")])
	_rejects(folded, "a case-fold path collision is refused")


# --- 3A: user-state index -----------------------------------------------------


func _user_state(saves: Array[Dictionary], status: Array[Dictionary]) -> Dictionary:
	return Envelope.build_user_state_manifest(saves, status)


func _save_row(slot_id: String) -> Dictionary:
	return Envelope.build_save_row(slot_id, _bytes("save:%s" % slot_id), "manual", "")


func _status_row(record_id: String) -> Dictionary:
	return Envelope.build_status_row(record_id, _bytes("status:%s" % record_id))


func _rejects_user_state(document: Variant, label: String) -> void:
	var errors: Array[String] = []
	var parsed := Envelope.parse_user_state_manifest(document, errors)
	_check(parsed.is_empty() and not errors.is_empty(), label, "accepted: %s" % str(document))


func _test_user_state_round_trip() -> void:
	var built := _user_state(
		[_save_row("zeta"), _save_row("autosave")],
		[_status_row("record_b"), _status_row("record_a")]
	)
	_check(
		(
			String(built["saves"][0]["slot_id"]) == "autosave"
			and String(built["status_records"][0]["record_id"]) == "record_a"
		),
		"user-state rows are ordered by id"
	)
	var errors: Array[String] = []
	var parsed := Envelope.parse_user_state_manifest(built, errors)
	_check(
		not parsed.is_empty() and errors.is_empty(), "a built user-state index parses", str(errors)
	)
	_check(parsed["saves"].size() == 2 and parsed["status_records"].size() == 2, "all rows survive")
	_check(
		String(parsed["saves"][0]["origin"]) == "manual",
		"a save row keeps the fields restore needs"
	)
	var empty := _user_state([], [])
	var empty_errors: Array[String] = []
	var empty_parsed := Envelope.parse_user_state_manifest(empty, empty_errors)
	_check(
		not empty_parsed.is_empty() and empty_parsed["saves"].is_empty(),
		"a backup may carry packs and no user state"
	)


func _test_user_state_rejections() -> void:
	_rejects_user_state([], "a non-object user-state index is refused")
	var future := _user_state([_save_row("autosave")], [])
	future["user_state_format_version"] = Envelope.USER_STATE_FORMAT_VERSION + 1
	_rejects_user_state(future, "a future user-state version is refused")
	var weak := _user_state([_save_row("autosave")], [])
	weak["digest_algorithm"] = "md5"
	_rejects_user_state(weak, "a weaker user-state digest algorithm is refused")
	var traversal := _user_state([_save_row("autosave")], [])
	traversal["saves"][0]["slot_id"] = "../../escape"
	_rejects_user_state(traversal, "a traversal slot id is refused")
	var relocated := _user_state([_save_row("autosave")], [])
	relocated["saves"][0]["path"] = "user_state/saves/other.json"
	_rejects_user_state(relocated, "a save row that names its own path is refused")
	var duplicated := _user_state([_save_row("autosave"), _save_row("autosave")], [])
	_rejects_user_state(duplicated, "a duplicated save row is refused")
	var folded := _user_state([_save_row("autosave"), _save_row("AutoSave")], [])
	_rejects_user_state(folded, "a case-fold slot collision is refused")
	var bad_status := _user_state([], [_status_row("record_a")])
	bad_status["status_records"][0]["sha256"] = "nope"
	_rejects_user_state(bad_status, "a status row without a valid digest is refused")


# --- 3A: artifact discrimination ----------------------------------------------


func _test_artifact_classification() -> void:
	_check(
		(
			Envelope.classify_document(_manifest([_pack_component()]))
			== (Envelope.ARTIFACT_CAMPAIGN_BACKUP)
		),
		"a backup envelope classifies as a backup"
	)
	_check(
		(
			Envelope.classify_document({"format_version": 2, "header": {}})
			== Envelope.ARTIFACT_PORTABLE_SAVE
		),
		"a save document classifies as a portable save"
	)
	_check(
		Envelope.classify_document({"kind": "campaign"}) == Envelope.ARTIFACT_UNKNOWN,
		"an unrelated document classifies as unknown"
	)
	_check(
		(
			Envelope.classify_archive_entries(["backup.json", "packs/base_game-1.0.0.zip"])
			== Envelope.ARTIFACT_CAMPAIGN_BACKUP
		),
		"an archive holding the envelope classifies as a backup"
	)
	_check(
		(
			Envelope.classify_archive_entries(["base_game/manifest.json"])
			== Envelope.ARTIFACT_CAMPAIGN_PACK
		),
		"an archive without the envelope classifies as a pack"
	)
	var zip_bytes := PackedByteArray([0x50, 0x4b, 0x03, 0x04, 0x00])
	_check(Envelope.looks_like_zip(zip_bytes), "the ZIP signature is recognised")
	_check(not Envelope.looks_like_zip(_bytes("{")), "JSON is not mistaken for a ZIP")


func _test_accounted_paths() -> void:
	var manifest := _parse(_manifest([_pack_component(), _user_state_component()]))
	var errors: Array[String] = []
	var user_state := Envelope.parse_user_state_manifest(
		_user_state([_save_row("autosave")], [_status_row("record_a")]), errors
	)
	var paths := Envelope.accounted_paths(manifest, user_state)
	paths.sort()
	var expected := [
		"backup.json",
		"packs/base_game-1.0.0.zip",
		"user_state/manifest.json",
		"user_state/saves/autosave.json",
		"user_state/status/record_a.json",
	]
	_check(paths == expected, "every stored path is accounted for", str(paths))


# --- 3B: writing a backup -----------------------------------------------------
#
# The service is driven against its own directories and a save-manager stub. The
# real SaveManager is exercised by restore in the later stages; what stage 3B has to
# prove is that the archive is assembled from clean pack bytes and verbatim user
# state, that digests describe what was actually stored, and that a refused export
# leaves nothing behind.


class SaveManagerStub:
	extends RefCounted
	var save_dir: String
	var rows: Array[Dictionary] = []

	func _init(directory: String) -> void:
		save_dir = directory

	func list_slots() -> Array[Dictionary]:
		return rows.duplicate(true)

	func get_slot_path(slot_id: String) -> String:
		if not Envelope.is_safe_identity(slot_id):
			return ""
		return save_dir.path_join("%s.json" % slot_id)


func _write_json(path: String, value: Variant) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()


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
		_write_json(pack_root.path_join(relative), files[relative])


func _reset_fixture() -> void:
	Installer._remove_tree(TEST_STORAGE_ROOT)
	Installer._remove_tree(TEST_SAVE_DIR)
	Installer._remove_tree(TEST_STATUS_ROOT)
	Installer._remove_tree(Service.STAGING_DIR)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_BACKUP_PATH))


func _build_fixture() -> SaveManagerStub:
	_reset_fixture()
	_write_pack(Registry.installed_path(TEST_STORAGE_ROOT, PACK_ID, PACK_VERSION))
	var stub := SaveManagerStub.new(TEST_SAVE_DIR)
	for slot_id in ["autosave", "manual_a"]:
		_write_json(
			TEST_SAVE_DIR.path_join("%s.json" % slot_id),
			{"format_version": 2, "save_label": slot_id, "header": {"save_kind": "between_map"}}
		)
		(
			stub
			. rows
			. append(
				{
					"slot_id": slot_id,
					"origin": "auto" if slot_id == "autosave" else "manual",
					"rule_id": "chapter" if slot_id == "autosave" else "",
				}
			)
		)
	_write_json(TEST_STATUS_ROOT.path_join("record_a.json"), _status_document("record_a"))
	return stub


# A real record, checksum included: stage 3D validates status records through their
# own parser, so a hand-shaped stand-in would pass export and fail restore.
func _status_document(record_id: String) -> Dictionary:
	var record := StatusRecord.new()
	record.record_id = record_id
	record.author_id = "fixture_author"
	record.campaign_id = "fixture"
	record.campaign_version = "1.0.0"
	record.created_at_utc = "2026-08-27T00:00:00"
	return record.to_dict()


func _service(stub: Object) -> RefCounted:
	return Service.new(TEST_STORAGE_ROOT, stub, TEST_STATUS_ROOT)


func _archive_entries(path: String) -> Dictionary:
	var reader := ZIPReader.new()
	if reader.open(path) != OK:
		return {}
	var payloads := {}
	for entry in reader.get_files():
		payloads[entry] = reader.read_file(entry)
	reader.close()
	return payloads


func _test_backup_write() -> void:
	var stub := _build_fixture()
	var service := _service(stub)
	var available: Dictionary = service.available_components()
	_check(
		(
			available["packages"].size() == 1
			and available["saves"].size() == 2
			and available["record_ids"].size() == 1
		),
		"the service offers every installed package, save and status record",
		str(available)
	)

	var result = service.export_backup(TEST_BACKUP_PATH)
	_check(result.exported, "a full backup is written", str(result.errors))
	var payloads := _archive_entries(TEST_BACKUP_PATH)
	var names := payloads.keys()
	names.sort()
	var expected := [
		"backup.json",
		"packs/%s-%s.zip" % [PACK_ID, PACK_VERSION],
		"user_state/manifest.json",
		"user_state/saves/autosave.json",
		"user_state/saves/manual_a.json",
		"user_state/status/record_a.json",
	]
	_check(names == expected, "the archive holds exactly the accounted entries", str(names))

	var errors: Array[String] = []
	var manifest := Envelope.parse_manifest(
		JSON.parse_string(payloads["backup.json"].get_string_from_utf8()), errors
	)
	_check(not manifest.is_empty() and errors.is_empty(), "the stored envelope parses", str(errors))
	var digests_match := true
	for component in manifest["components"]:
		var stored: PackedByteArray = payloads.get(component["path"], PackedByteArray())
		if (
			Envelope.digest(stored) != String(component["sha256"])
			or stored.size() != int(component["bytes"])
		):
			digests_match = false
	_check(digests_match, "every component digest and size describes the stored bytes")

	var state_errors: Array[String] = []
	var user_state := Envelope.parse_user_state_manifest(
		JSON.parse_string(payloads["user_state/manifest.json"].get_string_from_utf8()), state_errors
	)
	_check(
		not user_state.is_empty() and user_state["saves"].size() == 2,
		"the user-state index lists both saves",
		str(state_errors)
	)
	var autosave: Dictionary = user_state["saves"][0]
	_check(
		String(autosave["origin"]) == "auto" and String(autosave["rule_id"]) == "chapter",
		"an autosave keeps the pool it belonged to"
	)
	# Verbatim matters: the save the resolver validates on restore must be the
	# bytes that were stored, not a re-serialization of them.
	var source_bytes := FileAccess.get_file_as_bytes(TEST_SAVE_DIR.path_join("autosave.json"))
	_check(
		payloads["user_state/saves/autosave.json"] == source_bytes, "a save is stored byte for byte"
	)

	# The embedded pack is an ordinary clean pack: one package root, no user state.
	var pack_path := ProjectSettings.globalize_path(TEST_BACKUP_PATH)
	var inner := _extract_inner_pack(payloads["packs/%s-%s.zip" % [PACK_ID, PACK_VERSION]])
	var clean := not inner.is_empty()
	for entry in inner:
		if not String(entry).begins_with("%s/" % PACK_ID):
			clean = false
	_check(clean, "the embedded package is a clean single-root pack", str(inner))
	_check(
		not ("user_state" in str(inner)) and not ("saves" in str(inner)),
		"no user state is stored inside the installable pack"
	)
	_check(pack_path != "", "the backup was written to a real path")


func _extract_inner_pack(bytes: PackedByteArray) -> Array:
	var path := TEST_INNER_PACK_PATH
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return []
	file.store_buffer(bytes)
	file.close()
	var reader := ZIPReader.new()
	if reader.open(path) != OK:
		return []
	var names := reader.get_files()
	reader.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return names


func _test_backup_selection() -> void:
	var stub := _build_fixture()
	var service := _service(stub)
	var result = service.export_backup(TEST_BACKUP_PATH, {"slot_ids": ["manual_a"]})
	_check(result.exported, "a partial backup is written", str(result.errors))
	var names := _archive_entries(TEST_BACKUP_PATH).keys()
	names.sort()
	_check(
		names == ["backup.json", "user_state/manifest.json", "user_state/saves/manual_a.json"],
		"a save-only selection stores only that save",
		str(names)
	)

	# A selection that names something absent is refused rather than quietly
	# reduced: silently writing a backup without the save the player chose is the
	# failure this rejects.
	var missing = service.export_backup(TEST_BACKUP_PATH, {"slot_ids": ["not_a_slot"]})
	_check(not missing.exported and not missing.errors.is_empty(), "a missing selection is refused")
	_check(
		(
			not DirAccess.dir_exists_absolute(Service.STAGING_DIR)
			or DirAccess.open(Service.STAGING_DIR).get_directories().is_empty()
		),
		"a refused export leaves no workspace behind"
	)

	_reset_fixture()
	var empty := Service.new(
		TEST_STORAGE_ROOT, SaveManagerStub.new(TEST_SAVE_DIR), TEST_STATUS_ROOT
	)
	var nothing = empty.export_backup(TEST_BACKUP_PATH)
	_check(
		not nothing.exported and not nothing.errors.is_empty(),
		"an empty library and empty state produce no backup file"
	)
	_check(
		not FileAccess.file_exists(TEST_BACKUP_PATH),
		"no backup file is left when there was nothing to store"
	)
	_reset_fixture()


# --- 3C: inspecting a backup --------------------------------------------------
#
# Inspection answers "what is this file, and is it intact" without committing
# anything. Each rejection below is driven by rebuilding a real archive from mutated
# payloads, so the check under test is the one a tampered or truncated file would
# actually hit.


func _repack(payloads: Dictionary, path: String) -> void:
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


func _inspect(path: String) -> RefCounted:
	return _service(SaveManagerStub.new(TEST_SAVE_DIR)).inspect_backup(path)


func _rejects_backup(payloads: Dictionary, label: String) -> void:
	_repack(payloads, TEST_INNER_PACK_PATH)
	var result = _inspect(TEST_INNER_PACK_PATH)
	_check(not result.valid and not result.errors.is_empty(), label, str(result.errors))


func _test_backup_inspection() -> void:
	var stub := _build_fixture()
	var service := _service(stub)
	var written = service.export_backup(TEST_BACKUP_PATH)
	_check(written.exported, "a backup is available to inspect", str(written.errors))

	var result = service.inspect_backup(TEST_BACKUP_PATH)
	_check(
		result.valid and result.errors.is_empty(),
		"a written backup inspects clean",
		str(result.errors)
	)
	_check(
		result.artifact_kind == Envelope.ARTIFACT_CAMPAIGN_BACKUP,
		"the archive is classified as a backup"
	)
	_check(
		(
			Envelope.pack_components(result.manifest).size() == 1
			and result.user_state["saves"].size() == 2
			and result.user_state["status_records"].size() == 1
		),
		"inspection reports every component it found"
	)

	# Nothing is committed by inspection: the library and the save directory are
	# untouched surfaces here, so a clean read must leave both exactly as they were.
	var slots_before := DirAccess.open(TEST_SAVE_DIR).get_files()
	service.inspect_backup(TEST_BACKUP_PATH)
	_check(DirAccess.open(TEST_SAVE_DIR).get_files() == slots_before, "inspecting writes nothing")

	var payloads := _archive_entries(TEST_BACKUP_PATH)

	var tampered := payloads.duplicate(true)
	tampered["user_state/saves/autosave.json"] = '{"format_version": 2}'.to_utf8_buffer()
	_rejects_backup(tampered, "a save whose bytes changed is refused")

	var extra := payloads.duplicate(true)
	extra["user_state/saves/uninvited.json"] = "{}".to_utf8_buffer()
	_rejects_backup(extra, "an unaccounted file is refused")

	var incomplete := payloads.duplicate(true)
	incomplete.erase("user_state/status/record_a.json")
	_rejects_backup(incomplete, "a missing component is refused")

	var headless := payloads.duplicate(true)
	headless.erase("backup.json")
	_rejects_backup(headless, "an archive with no envelope is not treated as a backup")

	# The three artifacts share a folder and a file dialog. Each must be named for
	# what it is rather than rejected as a malformed backup.
	var pack_only := {}
	pack_only["%s/manifest.json" % PACK_ID] = "{}".to_utf8_buffer()
	_repack(pack_only, TEST_INNER_PACK_PATH)
	var as_pack = _inspect(TEST_INNER_PACK_PATH)
	_check(
		(
			not as_pack.valid
			and as_pack.artifact_kind == Envelope.ARTIFACT_CAMPAIGN_PACK
			and "campaign package" in str(as_pack.errors)
		),
		"a campaign package is named as one, not read as a backup",
		str(as_pack.errors)
	)

	var save_file := FileAccess.open(TEST_INNER_PACK_PATH, FileAccess.WRITE)
	save_file.store_string(JSON.stringify({"format_version": 2, "save_label": "x"}))
	save_file.close()
	var as_save = _inspect(TEST_INNER_PACK_PATH)
	_check(
		(
			not as_save.valid
			and as_save.artifact_kind == Envelope.ARTIFACT_PORTABLE_SAVE
			and "single save" in str(as_save.errors)
		),
		"a portable save is named as one, not read as a backup",
		str(as_save.errors)
	)

	var junk := FileAccess.open(TEST_INNER_PACK_PATH, FileAccess.WRITE)
	junk.store_string("not an archive and not JSON")
	junk.close()
	var as_junk = _inspect(TEST_INNER_PACK_PATH)
	_check(
		not as_junk.valid and as_junk.artifact_kind == Envelope.ARTIFACT_UNKNOWN,
		"an unrelated file is refused as unknown"
	)

	var absent = _inspect("user://test_pack_save_exports_absent.zip")
	_check(not absent.valid and not absent.errors.is_empty(), "a missing file is refused")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_INNER_PACK_PATH))
	_reset_fixture()


# --- 3D: restoring a backup ---------------------------------------------------
#
# This stage runs against the real autoloads. The save that goes into the backup is
# captured from a started campaign, so what restore has to accept is a document the
# engine actually produces, not a hand-written stand-in.

var _restore_pack_root := ""


func _autoloads() -> Dictionary:
	return {
		"data": root.get_node_or_null("DataManager"),
		"state": root.get_node_or_null("GameState"),
		"campaign": root.get_node_or_null("CampaignManager"),
		"save": root.get_node_or_null("SaveManager"),
	}


func _seed_live_save(nodes: Dictionary, slot_id: String) -> bool:
	_restore_pack_root = Registry.installed_path(TEST_STORAGE_ROOT, PACK_ID, PACK_VERSION)
	nodes["save"].call("configure_save_dir_for_tests", TEST_SAVE_DIR)
	nodes["data"].call("select_tier2_campaign_source", _restore_pack_root, PACK_ID, PACK_VERSION)
	var roster: Array = nodes["data"].call("get_campaign_pack_roster", "heroes")
	nodes["state"].call("load_roster_resources", roster, "campaign_pack_roster", "heroes")
	nodes["campaign"].call("start_campaign", "fixture")
	var save: RefCounted = nodes["state"].call("capture_campaign_save", "Backup fixture")
	return bool(nodes["save"].call("save_slot", slot_id, save, "manual"))


func _detach_content(nodes: Dictionary) -> void:
	nodes["campaign"].call("end_campaign")
	nodes["data"].call("select_campaign_source", "res://data")


func _test_backup_restore() -> void:
	var nodes := _autoloads()
	if nodes.values().has(null):
		_check(false, "required autoloads unavailable")
		return
	_reset_fixture()
	_write_pack(Registry.installed_path(TEST_STORAGE_ROOT, PACK_ID, PACK_VERSION))
	_write_json(TEST_STATUS_ROOT.path_join("record_a.json"), _status_document("record_a"))
	if not _seed_live_save(nodes, "restored_a"):
		_check(false, "the fixture save could not be written")
		return

	var service := _service(nodes["save"])
	var written = service.export_backup(TEST_BACKUP_PATH)
	_check(written.exported, "a backup of live state is written", str(written.errors))

	# Everything the backup covers is removed: this is the machine-loss case the
	# whole slice exists for.
	_detach_content(nodes)
	Installer._remove_tree(TEST_STORAGE_ROOT)
	nodes["save"].call("delete_slot", "restored_a")
	Installer._remove_tree(TEST_STATUS_ROOT)

	var restored = service.restore_backup(TEST_BACKUP_PATH)
	_check(restored.restored, "a full backup restores", str(restored.errors))
	_check(
		(
			restored.installed_packages.size() == 1
			and restored.restored_slots == ["restored_a"]
			and restored.restored_records == ["record_a"]
		),
		"restore reports each component it committed",
		str(restored.errors)
	)
	_check(
		(
			DirAccess.dir_exists_absolute(
				Registry.installed_path(TEST_STORAGE_ROOT, PACK_ID, PACK_VERSION)
			)
			and bool(nodes["save"].call("has_slot", "restored_a"))
			and FileAccess.file_exists(TEST_STATUS_ROOT.path_join("record_a.json"))
		),
		"every restored component is back on disk"
	)
	# The restored save must be runnable, not merely present: the package it names
	# was installed by the same restore, so it resolves rather than sitting disabled.
	var revalidated: Dictionary = nodes["save"].call("revalidate_slot", "restored_a")
	_check(
		bool(revalidated.get("ok", false)),
		"the restored save resolves against the restored package",
		str(revalidated.get("errors", []))
	)

	# Restoring again is not an error for packages — the same id and version is the
	# same release — but it will not silently overwrite a save that exists now.
	var again = service.restore_backup(TEST_BACKUP_PATH)
	_check(
		not again.restored and not again.errors.is_empty(),
		"a restore that would overwrite an existing save is refused"
	)
	_check(
		"Replace" in str(again.errors),
		"the refusal names the action that would allow it",
		str(again.errors)
	)
	var replaced = service.restore_backup(TEST_BACKUP_PATH, {}, true)
	_check(
		replaced.restored,
		"an explicit replace restores over the existing save",
		str(replaced.errors)
	)
	_check(
		replaced.skipped_packages.size() == 1 and replaced.installed_packages.is_empty(),
		"an already-installed package is skipped rather than reinstalled"
	)

	_test_restore_rollback(nodes, service)
	_detach_content(nodes)
	_reset_fixture()


func _test_restore_rollback(nodes: Dictionary, service: RefCounted) -> void:
	# Remove the package and the save again, then fail the commit part way through.
	_detach_content(nodes)
	Installer._remove_tree(TEST_STORAGE_ROOT)
	nodes["save"].call("delete_slot", "restored_a")
	var index_before := FileAccess.get_file_as_bytes(nodes["save"].call("get_index_path"))
	var status_before := FileAccess.get_file_as_bytes(TEST_STATUS_ROOT.path_join("record_a.json"))
	var backup_before := FileAccess.get_file_as_bytes(TEST_BACKUP_PATH)

	service.fault_injector = func(stage: String) -> bool: return stage == "slot_restored"
	var failed = service.restore_backup(TEST_BACKUP_PATH)
	service.fault_injector = Callable()
	_check(not failed.restored and not failed.errors.is_empty(), "an interrupted restore fails")
	_check(
		not DirAccess.dir_exists_absolute(
			Registry.installed_path(TEST_STORAGE_ROOT, PACK_ID, PACK_VERSION)
		),
		"a package installed before the failure is rolled back"
	)
	_check(
		not bool(nodes["save"].call("has_slot", "restored_a")),
		"no save survives an interrupted restore"
	)
	_check(
		FileAccess.get_file_as_bytes(nodes["save"].call("get_index_path")) == index_before,
		"the save index is unchanged"
	)
	_check(
		FileAccess.get_file_as_bytes(TEST_STATUS_ROOT.path_join("record_a.json")) == status_before,
		"the status store is unchanged"
	)
	_check(
		FileAccess.get_file_as_bytes(TEST_BACKUP_PATH) == backup_before,
		"the backup file itself is never modified"
	)


# --- 3E: clean packs, and no artifact masquerading as another ------------------
#
# The three artifacts share a file dialog and a folder. Each import boundary must
# name what it was given, and the clean-pack surface the plan says to PRESERVE must
# still behave as it did.


func _test_clean_pack_and_masquerade() -> void:
	var stub := _build_fixture()
	var service := _service(stub)
	var written = service.export_backup(TEST_BACKUP_PATH)
	_check(written.exported, "a backup exists for the boundary checks", str(written.errors))

	# The save import boundary. Before this stage it called every ZIP a campaign
	# package, which sent a player holding a backup to a screen that also refuses it.
	var manager: Node = root.get_node_or_null("SaveManager")
	if manager == null:
		_check(false, "SaveManager autoload unavailable")
		return
	var as_save: Dictionary = manager.call("inspect_portable_save", TEST_BACKUP_PATH)
	_check(
		(
			not bool(as_save.get("ok", false))
			and String(as_save.get("artifact_kind", "")) == Envelope.ARTIFACT_CAMPAIGN_BACKUP
			and "full backup" in str(as_save.get("errors", []))
		),
		"importing a backup as a save names it a backup",
		str(as_save.get("errors", []))
	)

	# The pack import boundary, through the same helper the library screen calls.
	_check(
		Service.classify_archive_file(TEST_BACKUP_PATH) == Envelope.ARTIFACT_CAMPAIGN_BACKUP,
		"the library import boundary classifies a backup as a backup"
	)
	var pack_archive := TEST_INNER_PACK_PATH
	var exported = Exporter.new().export_zip(
		Registry.installed_path(TEST_STORAGE_ROOT, PACK_ID, PACK_VERSION),
		pack_archive,
		Service._pack_limits()
	)
	_check(exported.exported, "the clean-pack export surface still works", str(exported.errors))
	_check(
		Service.classify_archive_file(pack_archive) == Envelope.ARTIFACT_CAMPAIGN_PACK,
		"a clean pack still classifies as a package"
	)

	# Determinism is over entry names and payloads. Raw bytes cannot match: Godot's
	# ZIPPacker stamps every entry with the current time and offers no way to set it.
	var first := _archive_entries(pack_archive)
	var second_path := "user://test_pack_save_exports_inner_second.zip"
	Exporter.new().export_zip(
		Registry.installed_path(TEST_STORAGE_ROOT, PACK_ID, PACK_VERSION),
		second_path,
		Service._pack_limits()
	)
	var second := _archive_entries(second_path)
	var first_names := first.keys()
	first_names.sort()
	var second_names := second.keys()
	second_names.sort()
	var same_payloads := first_names == second_names
	for name in first_names:
		if first[name] != second.get(name, PackedByteArray()):
			same_payloads = false
	_check(same_payloads, "two clean-pack exports carry identical entries and bytes")
	_check(
		not ("user_state" in str(first_names)) and not ("saves_index" in str(first_names)),
		"a clean pack carries no user state",
		str(first_names)
	)

	# The portable-save surface the plan says to preserve.
	manager.call("configure_save_dir_for_tests", TEST_SAVE_DIR)
	var portable := "user://test_pack_save_exports_portable.json"
	var portable_result: Dictionary = manager.call("export_slot", "autosave", portable)
	_check(
		bool(portable_result.get("ok", false)) and FileAccess.file_exists(portable),
		"export_slot still writes a portable save",
		str(portable_result.get("errors", []))
	)
	_check(
		Service.classify_archive_file(portable) == Envelope.ARTIFACT_PORTABLE_SAVE,
		"a portable save still classifies as a save"
	)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(portable))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(second_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(pack_archive))
	_reset_fixture()
