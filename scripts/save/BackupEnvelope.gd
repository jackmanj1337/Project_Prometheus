class_name BackupEnvelope extends RefCounted
# adopter-todo: IMPL-PACK-SAVE-EXPORTS
# Pack-save Slice 3, stage 3A: the full-backup envelope format, as pure data.
# The consumer is stage 3B's CampaignBackupService, which writes and reads the
# archive this file describes.
#
# A backup is one ZIP holding two INDEPENDENT halves:
#
#   backup.json                        the envelope below
#   packs/<id>-<version>.zip           clean pack archives, each exactly the bytes
#                                      the ordinary pack exporter produces
#   user_state/manifest.json           the user-state index
#   user_state/saves/<slot_id>.json    save documents, byte-for-byte as stored
#   user_state/status/<record_id>.json campaign status records
#
# The halves are separate on purpose. A pack archive is validated by the pack
# preflight/installer; user state is validated by the save resolution path. Neither
# validator is allowed to vouch for the other's bytes, so the envelope never mixes
# them into one blob and never stores user state inside an installable pack.
#
# Nothing here touches the filesystem. This file owns the SHAPE and the identity
# rules; CampaignBackupService owns bytes, budgets and transactions.

const SaveManagerScript = preload("res://scripts/autoloads/SaveManager.gd")

const FORMAT_VERSION := 1
const USER_STATE_FORMAT_VERSION := 1

const MANIFEST_PATH := "backup.json"
const USER_STATE_MANIFEST_PATH := "user_state/manifest.json"
const PACKS_DIR := "packs"
const SAVES_DIR := "user_state/saves"
const STATUS_DIR := "user_state/status"

const DIGEST_ALGORITHM := "sha256"
const DIGEST_HEX_LENGTH := 64

const COMPONENT_PACK := "campaign_pack"
const COMPONENT_USER_STATE := "user_state"
const COMPONENT_KINDS := [COMPONENT_PACK, COMPONENT_USER_STATE]

# What a chosen file actually is. The player picks one file from a file dialog and
# all three of ours are plausible neighbours in the same folder, so every entry
# point classifies before it validates — a pack must never be read as a save, and a
# backup must never be installed as a pack.
const ARTIFACT_UNKNOWN := "unknown"
const ARTIFACT_PORTABLE_SAVE := "portable_save"
const ARTIFACT_CAMPAIGN_PACK := "campaign_pack"
const ARTIFACT_CAMPAIGN_BACKUP := "campaign_backup"

const _IDENTITY_CHARS := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-."
const _MAX_IDENTITY_LENGTH := 64

# --- Digests ------------------------------------------------------------------


static func digest(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


# The algorithm and the length are both part of the contract: a 40-hex digest is a
# different algorithm wearing the same field name, and accepting it would let a
# weaker hash decide whether restored bytes are intact.
static func is_valid_digest(value: Variant) -> bool:
	if not value is String:
		return false
	var text := String(value)
	if text.length() != DIGEST_HEX_LENGTH:
		return false
	for index in text.length():
		if not text[index] in "0123456789abcdef":
			return false
	return true


# --- Identity -----------------------------------------------------------------


static func is_safe_identity(value: String) -> bool:
	if value.is_empty() or value.length() > _MAX_IDENTITY_LENGTH:
		return false
	if value == "." or value == ".." or value.begins_with("."):
		return false
	for index in value.length():
		if not _IDENTITY_CHARS.contains(value[index]):
			return false
	return true


static func pack_component_path(package_id: String, package_version: String) -> String:
	return "%s/%s-%s.zip" % [PACKS_DIR, package_id, package_version]


static func save_component_path(slot_id: String) -> String:
	return "%s/%s.json" % [SAVES_DIR, slot_id]


static func status_component_path(record_id: String) -> String:
	return "%s/%s.json" % [STATUS_DIR, record_id]


# --- Artifact classification --------------------------------------------------


# The ZIP local-file-header signature. Cheap, and the only thing that separates our
# two archive artifacts from our one JSON artifact before any parsing happens.
static func looks_like_zip(bytes: PackedByteArray) -> bool:
	return bytes.size() >= 4 and bytes.decode_u32(0) == 0x04034b50


# Archive kind from entry names alone: a backup carries the envelope at its root, a
# pack does not. Pure so the discriminator can be tested without writing archives.
static func classify_archive_entries(paths: Array) -> String:
	for path in paths:
		if String(path).replace("\\", "/") == MANIFEST_PATH:
			return ARTIFACT_CAMPAIGN_BACKUP
	return ARTIFACT_CAMPAIGN_PACK


# Document kind for a parsed JSON value. A backup envelope is a JSON object too, so
# a player who renames backup.json and imports it as a save gets told what it is
# rather than "not a save".
static func classify_document(value: Variant) -> String:
	if not value is Dictionary:
		return ARTIFACT_UNKNOWN
	var document: Dictionary = value
	if (
		document.has("backup_format_version")
		or document.get("artifact_kind", "") == (ARTIFACT_CAMPAIGN_BACKUP)
	):
		return ARTIFACT_CAMPAIGN_BACKUP
	if document.has("format_version") or document.has("header") or document.has("save_label"):
		return ARTIFACT_PORTABLE_SAVE
	return ARTIFACT_UNKNOWN


# --- Envelope construction ----------------------------------------------------


# Components are sorted by path so two backups of the same state produce the same
# envelope. (The archive BYTES cannot be identical run to run: Godot's ZIPPacker
# stamps each entry with the current time and exposes no way to set it. Determinism
# here is over entry names and payloads, which is what a round trip compares.)
static func build_manifest(components: Array[Dictionary], created_at_utc: String) -> Dictionary:
	var rows: Array[Dictionary] = []
	for component in components:
		rows.append(component.duplicate(true))
	rows.sort_custom(func(a, b): return String(a.get("path", "")) < String(b.get("path", "")))
	return {
		"backup_format_version": FORMAT_VERSION,
		"artifact_kind": ARTIFACT_CAMPAIGN_BACKUP,
		"created_at_utc": created_at_utc,
		"digest_algorithm": DIGEST_ALGORITHM,
		"components": rows,
	}


static func build_pack_component(
	package_id: String, package_version: String, bytes: PackedByteArray
) -> Dictionary:
	return {
		"kind": COMPONENT_PACK,
		"package_id": package_id,
		"package_version": package_version,
		"path": pack_component_path(package_id, package_version),
		"sha256": digest(bytes),
		"bytes": bytes.size(),
	}


static func build_user_state_component(bytes: PackedByteArray) -> Dictionary:
	return {
		"kind": COMPONENT_USER_STATE,
		"path": USER_STATE_MANIFEST_PATH,
		"sha256": digest(bytes),
		"bytes": bytes.size(),
	}


static func build_user_state_manifest(
	saves: Array[Dictionary], status_records: Array[Dictionary]
) -> Dictionary:
	var save_rows: Array[Dictionary] = []
	for row in saves:
		save_rows.append(row.duplicate(true))
	save_rows.sort_custom(
		func(a, b): return String(a.get("slot_id", "")) < String(b.get("slot_id", ""))
	)
	var status_rows: Array[Dictionary] = []
	for row in status_records:
		status_rows.append(row.duplicate(true))
	status_rows.sort_custom(
		func(a, b): return String(a.get("record_id", "")) < String(b.get("record_id", ""))
	)
	return {
		"user_state_format_version": USER_STATE_FORMAT_VERSION,
		"digest_algorithm": DIGEST_ALGORITHM,
		"saves": save_rows,
		"status_records": status_rows,
	}


static func build_save_row(
	slot_id: String, bytes: PackedByteArray, origin: String, rule_id: String
) -> Dictionary:
	return {
		"slot_id": slot_id,
		"path": save_component_path(slot_id),
		"sha256": digest(bytes),
		"bytes": bytes.size(),
		"origin": origin,
		"rule_id": rule_id,
	}


static func build_status_row(record_id: String, bytes: PackedByteArray) -> Dictionary:
	return {
		"record_id": record_id,
		"path": status_component_path(record_id),
		"sha256": digest(bytes),
		"bytes": bytes.size(),
	}


# --- Envelope parsing ---------------------------------------------------------


# Returns the normalized manifest, or {} with errors. Ordering is normalized rather
# than rejected: a backup that is otherwise sound should not be refused because some
# tool rewrote its component order.
static func parse_manifest(value: Variant, errors: Array[String]) -> Dictionary:
	if not value is Dictionary:
		errors.append("The backup envelope is not a JSON object.")
		return {}
	var document: Dictionary = value
	var version: Variant = document.get("backup_format_version", null)
	if not _is_integer(version):
		errors.append("The backup envelope does not declare a format version.")
		return {}
	if int(version) != FORMAT_VERSION:
		errors.append(
			(
				"This backup uses format version %d; this build reads version %d."
				% [int(version), FORMAT_VERSION]
			)
		)
		return {}
	if String(document.get("artifact_kind", "")) != ARTIFACT_CAMPAIGN_BACKUP:
		errors.append("The backup envelope does not identify itself as a campaign backup.")
		return {}
	if String(document.get("digest_algorithm", "")) != DIGEST_ALGORITHM:
		errors.append("The backup declares an unsupported digest algorithm.")
		return {}
	var raw_components: Variant = document.get("components", null)
	if not raw_components is Array:
		errors.append("The backup envelope has no component list.")
		return {}
	var components: Array[Dictionary] = []
	var seen_paths := {}
	var folded_paths := {}
	var seen_packs := {}
	var user_state_seen := false
	for entry in raw_components:
		var component := _parse_component(entry, errors)
		if component.is_empty():
			continue
		var path := String(component["path"])
		if seen_paths.has(path):
			errors.append("The backup lists the same component twice.")
			continue
		seen_paths[path] = true
		var folded := path.to_lower()
		if folded_paths.has(folded):
			errors.append("The backup lists two components whose paths differ only in case.")
			continue
		folded_paths[folded] = true
		if component["kind"] == COMPONENT_PACK:
			var key := "%s|%s" % [component["package_id"], component["package_version"]]
			if seen_packs.has(key):
				errors.append("The backup lists the same campaign package twice.")
				continue
			seen_packs[key] = true
		elif component["kind"] == COMPONENT_USER_STATE:
			if user_state_seen:
				errors.append("The backup lists more than one user-state component.")
				continue
			user_state_seen = true
		components.append(component)
	if not errors.is_empty():
		return {}
	if components.is_empty():
		errors.append("The backup contains no components to restore.")
		return {}
	components.sort_custom(func(a, b): return String(a["path"]) < String(b["path"]))
	return {
		"backup_format_version": FORMAT_VERSION,
		"artifact_kind": ARTIFACT_CAMPAIGN_BACKUP,
		"created_at_utc": String(document.get("created_at_utc", "")),
		"digest_algorithm": DIGEST_ALGORITHM,
		"components": components,
	}


static func _parse_component(value: Variant, errors: Array[String]) -> Dictionary:
	if not value is Dictionary:
		errors.append("A backup component is not a JSON object.")
		return {}
	var entry: Dictionary = value
	var kind := String(entry.get("kind", ""))
	if not kind in COMPONENT_KINDS:
		errors.append("The backup contains a component of an unknown kind.")
		return {}
	if not is_valid_digest(entry.get("sha256", null)):
		errors.append("A backup component has no valid sha256 digest.")
		return {}
	var size: Variant = entry.get("bytes", null)
	if not _is_integer(size) or int(size) < 0:
		errors.append("A backup component declares an invalid size.")
		return {}
	var path := String(entry.get("path", ""))
	var component := {
		"kind": kind,
		"path": path,
		"sha256": String(entry["sha256"]),
		"bytes": int(size),
	}
	if kind == COMPONENT_USER_STATE:
		if path != USER_STATE_MANIFEST_PATH:
			errors.append("The user-state component is not stored at its required path.")
			return {}
		return component
	var package_id := String(entry.get("package_id", ""))
	var package_version := String(entry.get("package_version", ""))
	if not is_safe_identity(package_id) or not is_safe_identity(package_version):
		errors.append("A backup package component has an unusable identity.")
		return {}
	# The path is DERIVED, never trusted: a component that names its own location
	# could point at another component's bytes or outside the archive entirely.
	if path != pack_component_path(package_id, package_version):
		errors.append("A backup package component is not stored at its required path.")
		return {}
	component["package_id"] = package_id
	component["package_version"] = package_version
	return component


static func parse_user_state_manifest(value: Variant, errors: Array[String]) -> Dictionary:
	if not value is Dictionary:
		errors.append("The backup's user-state index is not a JSON object.")
		return {}
	var document: Dictionary = value
	var version: Variant = document.get("user_state_format_version", null)
	if not _is_integer(version) or int(version) != USER_STATE_FORMAT_VERSION:
		errors.append("The backup's user-state index uses an unsupported format version.")
		return {}
	if String(document.get("digest_algorithm", "")) != DIGEST_ALGORITHM:
		errors.append("The backup's user-state index declares an unsupported digest algorithm.")
		return {}
	var saves := _parse_rows(
		document.get("saves", null),
		"slot_id",
		"save",
		errors,
		func(id): return SaveManagerScript.is_valid_slot_id(id)
	)
	var status_records := _parse_rows(
		document.get("status_records", null),
		"record_id",
		"status record",
		errors,
		func(id): return is_safe_identity(id)
	)
	if not errors.is_empty():
		return {}
	return {
		"user_state_format_version": USER_STATE_FORMAT_VERSION,
		"digest_algorithm": DIGEST_ALGORITHM,
		"saves": saves,
		"status_records": status_records,
	}


static func _parse_rows(
	value: Variant, id_field: String, label: String, errors: Array[String], id_is_valid: Callable
) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if value == null:
		return rows
	if not value is Array:
		errors.append("The backup's %s list is not an array." % label)
		return rows
	var seen := {}
	var folded := {}
	for entry in value:
		if not entry is Dictionary:
			errors.append("A backup %s entry is not a JSON object." % label)
			continue
		var row: Dictionary = entry
		var id := String(row.get(id_field, ""))
		if not id_is_valid.call(id):
			errors.append("A backup %s entry has an unusable identifier." % label)
			continue
		if seen.has(id):
			errors.append("The backup lists the same %s twice." % label)
			continue
		seen[id] = true
		var folded_id := id.to_lower()
		if folded.has(folded_id):
			errors.append("The backup lists two %s entries whose ids differ only in case." % label)
			continue
		folded[folded_id] = true
		if not is_valid_digest(row.get("sha256", null)):
			errors.append("A backup %s entry has no valid sha256 digest." % label)
			continue
		var size: Variant = row.get("bytes", null)
		if not _is_integer(size) or int(size) < 0:
			errors.append("A backup %s entry declares an invalid size." % label)
			continue
		var expected := (
			save_component_path(id) if id_field == "slot_id" else status_component_path(id)
		)
		if String(row.get("path", "")) != expected:
			errors.append("A backup %s entry is not stored at its required path." % label)
			continue
		var parsed := {
			id_field: id,
			"path": expected,
			"sha256": String(row["sha256"]),
			"bytes": int(size),
		}
		if id_field == "slot_id":
			parsed["origin"] = String(row.get("origin", "manual"))
			parsed["rule_id"] = String(row.get("rule_id", ""))
		rows.append(parsed)
	rows.sort_custom(func(a, b): return String(a[id_field]) < String(b[id_field]))
	return rows


# --- Queries ------------------------------------------------------------------


static func pack_components(manifest: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for component in manifest.get("components", []):
		if String(component.get("kind", "")) == COMPONENT_PACK:
			rows.append(component)
	return rows


static func user_state_component(manifest: Dictionary) -> Dictionary:
	for component in manifest.get("components", []):
		if String(component.get("kind", "")) == COMPONENT_USER_STATE:
			return component
	return {}


# Every archive path the envelope and its user-state index account for. Anything in
# the archive that is not here is unaccounted content, which the inspector rejects.
static func accounted_paths(manifest: Dictionary, user_state: Dictionary) -> Array[String]:
	var paths: Array[String] = [MANIFEST_PATH]
	for component in manifest.get("components", []):
		paths.append(String(component.get("path", "")))
	for row in user_state.get("saves", []):
		paths.append(String(row.get("path", "")))
	for row in user_state.get("status_records", []):
		paths.append(String(row.get("path", "")))
	return paths


static func _is_integer(value: Variant) -> bool:
	if value is int:
		return true
	# JSON numbers arrive as floats; a fractional count is not an integer.
	return value is float and float(value) == floor(float(value))
