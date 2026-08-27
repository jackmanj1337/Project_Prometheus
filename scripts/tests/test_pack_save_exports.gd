extends SceneTree
# Pack-save Slice 3. Stage 3A covers the backup envelope as pure data: identity
# rules, digests, deterministic ordering, and the artifact discriminator that keeps
# a pack, a portable save and a backup from being mistaken for one another.
#
# Everything here is a static call. There is no filesystem in this stage, so a
# failure names a contract defect rather than a disk condition.

const Envelope = preload("res://scripts/save/BackupEnvelope.gd")

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
