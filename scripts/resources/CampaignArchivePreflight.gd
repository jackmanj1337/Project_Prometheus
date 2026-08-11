class_name CampaignArchivePreflight extends RefCounted
# Pure ZIP inspection boundary. It reads archive bytes and validates content in
# memory; extraction and installed-pack writes belong to the later installer.

const MANIFEST_PATH := "manifest.json"
const CATALOGUE_PATH := "data/catalogue.json"
const APPROVED_MEDIA_EXTENSIONS := ["png", "ogg", "wav", "ttf", "otf"]


class Limits:
	extends RefCounted
	var max_entries: int
	var max_entry_compressed: int
	var max_entry_uncompressed: int
	var max_total_compressed: int
	var max_total_uncompressed: int

	func _init(
		entries: int,
		entry_compressed: int,
		entry_uncompressed: int,
		total_compressed: int,
		total_uncompressed: int
	) -> void:
		max_entries = entries
		max_entry_compressed = entry_compressed
		max_entry_uncompressed = entry_uncompressed
		max_total_compressed = total_compressed
		max_total_uncompressed = total_uncompressed


class Result:
	extends RefCounted
	var valid := false
	var errors: Array[String] = []
	var package_id := ""
	var package_root := ""
	var entries: Array[Dictionary] = []


# Player-facing defaults come from ImportBudgets through CampaignLibraryScreen;
# explicit limits keep hostile-fixture and build-tool overrides small and testable.
static func inspect_zip(archive_path: String, limits: Limits) -> Result:
	var result := Result.new()
	if limits == null:
		result.errors.append("Archive preflight requires explicit security limits")
		return result
	var file := FileAccess.open(archive_path, FileAccess.READ)
	if file == null:
		result.errors.append("Cannot open archive '%s'" % archive_path)
		return result
	var archive_size := file.get_length()
	# Enforce the outer artifact budget before buffering any attacker-controlled
	# bytes. Entry limits cannot protect memory if the whole ZIP is allocated first.
	if archive_size > limits.max_total_compressed:
		result.errors.append("Archive file exceeds compressed size limit")
		return result
	var bytes := file.get_buffer(archive_size)
	if bytes.size() < 4 or bytes.decode_u32(0) != 0x04034b50:
		result.errors.append("Artifact is not a ZIP archive (local header signature missing)")
		return result
	var entries := _read_central_directory(bytes, result.errors)
	if not result.errors.is_empty():
		return result
	var reader := ZIPReader.new()
	var open_error := reader.open(archive_path)
	if open_error != OK:
		result.errors.append("ZIP reader rejected archive: %s" % error_string(open_error))
		return result
	var payloads := {}
	for entry in entries:
		if not entry["is_directory"]:
			var payload: PackedByteArray = reader.read_file(entry["path"])
			if payload.size() != entry["uncompressed_size"]:
				result.errors.append("Cannot read complete archive entry '%s'" % entry["path"])
			else:
				payloads[entry["path"]] = payload
	reader.close()
	if not result.errors.is_empty():
		return result
	return inspect_entries(entries, payloads, limits)


# Public for deterministic hostile-metadata tests that ZIPWriter cannot author
# (notably Unix symlink and special-file central-directory modes).
static func inspect_entries(
	entries: Array[Dictionary], payloads: Dictionary, limits: Limits
) -> Result:
	var result := Result.new()
	result.entries = entries.duplicate(true)
	if limits == null:
		result.errors.append("Archive preflight requires explicit security limits")
		return result
	if entries.size() > limits.max_entries:
		result.errors.append(
			"Archive has %d entries; limit is %d" % [entries.size(), limits.max_entries]
		)
	var exact := {}
	var folded := {}
	var roots := {}
	var total_compressed := 0
	var total_uncompressed := 0
	for entry in entries:
		_validate_entry(entry, exact, folded, roots, limits, result.errors)
		total_compressed += int(entry.get("compressed_size", 0))
		total_uncompressed += int(entry.get("uncompressed_size", 0))
	if total_compressed > limits.max_total_compressed:
		result.errors.append("Archive compressed total exceeds limit")
	if total_uncompressed > limits.max_total_uncompressed:
		result.errors.append("Archive uncompressed total exceeds limit")
	if roots.size() != 1:
		result.errors.append("Archive must contain exactly one package root")
		return result
	result.package_root = String(roots.keys()[0])
	var prefix := result.package_root + "/"
	var relative_payloads := {}
	for path in payloads:
		if String(path).begins_with(prefix):
			relative_payloads[String(path).trim_prefix(prefix)] = payloads[path]
	_validate_content(relative_payloads, result)
	result.valid = result.errors.is_empty()
	return result


static func _validate_entry(
	entry: Dictionary,
	exact: Dictionary,
	folded: Dictionary,
	roots: Dictionary,
	limits: Limits,
	errors: Array[String]
) -> void:
	var path := String(entry.get("path", ""))
	if not _safe_archive_path(path):
		errors.append("Unsafe archive path '%s'" % path)
		return
	var normalized := path.trim_suffix("/")
	var root := normalized.get_slice("/", 0)
	if normalized.find("/") == -1:
		# ZIP tools commonly emit the package root as an explicit directory entry.
		# It establishes the same root as its child files; only root-level files escape it.
		if bool(entry.get("is_directory", false)):
			roots[root] = true
		else:
			errors.append("Entry '%s' is outside a package root" % path)
	else:
		roots[root] = true
	if exact.has(normalized):
		errors.append("Duplicate normalized path '%s'" % normalized)
	else:
		exact[normalized] = true
	var case_key := normalized.to_lower()
	if folded.has(case_key) and folded[case_key] != normalized:
		errors.append("Case-fold path collision '%s' and '%s'" % [folded[case_key], normalized])
	else:
		folded[case_key] = normalized
	var file_type := String(entry.get("file_type", "file"))
	if not file_type in ["file", "directory"]:
		errors.append("Archive entry '%s' is a forbidden %s" % [path, file_type])
	var compressed := int(entry.get("compressed_size", 0))
	var uncompressed := int(entry.get("uncompressed_size", 0))
	if (
		compressed < 0
		or uncompressed < 0
		or compressed > limits.max_entry_compressed
		or uncompressed > limits.max_entry_uncompressed
	):
		errors.append("Archive entry '%s' exceeds size limits" % path)


static func _validate_content(payloads: Dictionary, result: Result) -> void:
	for required in [MANIFEST_PATH, CATALOGUE_PATH]:
		if not payloads.has(required):
			result.errors.append("Package root is missing required '%s'" % required)
	if not result.errors.is_empty():
		return
	var manifest_raw: Variant = _parse_json(payloads[MANIFEST_PATH], MANIFEST_PATH, result.errors)
	var catalogue_raw: Variant = _parse_json(
		payloads[CATALOGUE_PATH], CATALOGUE_PATH, result.errors
	)
	if manifest_raw == null or catalogue_raw == null:
		return
	var manifest_errors: Array[String] = []
	var manifest = PackManifest.parse(manifest_raw, MANIFEST_PATH, manifest_errors)
	result.errors.append_array(manifest_errors)
	var catalogue_errors: Array[String] = []
	var catalogue = Tier2Catalogue.parse(catalogue_raw, CATALOGUE_PATH, catalogue_errors)
	result.errors.append_array(catalogue_errors)
	if catalogue == null:
		return
	if manifest != null:
		result.package_id = manifest.id
	if manifest != null and manifest.id != result.package_root:
		result.errors.append(
			"Manifest id '%s' does not match package root '%s'" % [manifest.id, result.package_root]
		)
	var documents := {}
	var admitted := {MANIFEST_PATH: true, CATALOGUE_PATH: true}
	for entry in catalogue.entries:
		var path: String = entry["path"]
		admitted[path] = true
		if not payloads.has(path):
			continue
		var document: Variant = _parse_json(payloads[path], path, result.errors)
		if document != null:
			if _is_save_shaped(document):
				result.errors.append("Save-shaped JSON is forbidden as pack content: '%s'" % path)
			else:
				documents[path] = document
	# JSON is otherwise catalogue-indexed content. Sprite frame sidecars are the
	# narrow exception: an asset registry explicitly references them, so preflight
	# admits exactly those paths and still parses them before extraction.
	for document in documents.values():
		if not document is Dictionary or document.get("kind", "") != "asset_registry":
			continue
		var assets: Variant = document.get("assets", {})
		if not assets is Dictionary:
			continue
		for record in assets.values():
			if not record is Dictionary:
				continue
			var sidecar_path := String(record.get("sidecar_path", ""))
			if sidecar_path.is_empty():
				continue
			if (
				not _safe_archive_path(sidecar_path)
				or not sidecar_path.begins_with("assets/")
				or sidecar_path.get_extension().to_lower() != "json"
			):
				continue  # The asset schema reports the precise contract error.
			admitted[sidecar_path] = true
			if not payloads.has(sidecar_path):
				result.errors.append("Referenced asset sidecar is missing: '%s'" % sidecar_path)
				continue
			var sidecar: Variant = _parse_json(payloads[sidecar_path], sidecar_path, result.errors)
			if sidecar != null and _is_save_shaped(sidecar):
				result.errors.append(
					"Save-shaped JSON is forbidden as asset sidecar: '%s'" % sidecar_path
				)
	for path in payloads:
		if admitted.has(path):
			continue
		var extension := String(path).get_extension().to_lower()
		if not String(path).begins_with("assets/") or not extension in APPROVED_MEDIA_EXTENSIONS:
			result.errors.append("Unindexed file is not approved Tier-1 media: '%s'" % path)
	if result.errors.is_empty():
		Tier2Catalogue.validate_campaign_documents(catalogue, documents, result.errors)
	if result.errors.is_empty() and not has_playable_campaign(catalogue, documents):
		result.errors.append("no_playable_campaign")


# Keep the player-library admission rule beside Tier-2 validation so archive
# preflight, staged promotion, and installed discovery cannot drift apart.
static func has_playable_campaign(catalogue: Tier2Catalogue, documents: Dictionary) -> bool:
	if catalogue == null:
		return false
	for entry in catalogue.entries:
		var kind := String(entry.get("kind", ""))
		var document: Variant = documents.get(String(entry.get("path", "")))
		if kind == "campaign" and document is Dictionary:
			if not bool(document.get("is_dev_only", false)):
				return true
		if kind != "map_registry" or document == null:
			continue
		var rows: Variant = document.get("entries", []) if document is Dictionary else document
		if not rows is Array:
			continue
		for row in rows:
			if row is Dictionary and not bool(row.get("is_dev_only", false)):
				return true
	return false


static func _safe_archive_path(path: String) -> bool:
	if (
		path.is_empty()
		or path.to_utf8_buffer().has(0)
		or "\\" in path
		or path.begins_with("/")
		or path.begins_with("user://")
		or path.begins_with("res://")
	):
		return false
	if path.length() >= 2 and path[1] == ":":
		return false
	var trimmed := path.trim_suffix("/")
	for part in trimmed.split("/"):
		if part.is_empty() or part == "." or part == "..":
			return false
	return true


static func _is_save_shaped(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var hits := 0
	for key in ["save_label", "integrity", "header", "party", "map_runtime", "suspend"]:
		if value.has(key):
			hits += 1
	return hits >= 3 or value.has("save_label") or value.has("map_runtime") or value.has("suspend")


static func _parse_json(bytes: PackedByteArray, path: String, errors: Array[String]) -> Variant:
	var json := JSON.new()
	var parse_error := json.parse(bytes.get_string_from_utf8())
	if parse_error != OK:
		errors.append(
			(
				"Invalid JSON '%s' at line %d: %s"
				% [path, json.get_error_line(), json.get_error_message()]
			)
		)
		return null
	return json.data


static func _read_central_directory(
	bytes: PackedByteArray, errors: Array[String]
) -> Array[Dictionary]:
	var eocd := -1
	var minimum := maxi(0, bytes.size() - 65557)
	for offset in range(bytes.size() - 22, minimum - 1, -1):
		if bytes.decode_u32(offset) == 0x06054b50:
			eocd = offset
			break
	if eocd < 0:
		errors.append("ZIP end-of-central-directory record is missing")
		return []
	if bytes.decode_u16(eocd + 4) != 0 or bytes.decode_u16(eocd + 6) != 0:
		errors.append("Multi-disk ZIP archives are not supported")
		return []
	var count := int(bytes.decode_u16(eocd + 10))
	if int(bytes.decode_u16(eocd + 8)) != count:
		errors.append("ZIP central-directory entry counts disagree")
		return []
	var cursor := int(bytes.decode_u32(eocd + 16))
	var central_size := int(bytes.decode_u32(eocd + 12))
	if cursor + central_size != eocd:
		errors.append("ZIP central-directory bounds are inconsistent")
		return []
	var entries: Array[Dictionary] = []
	for _index in count:
		if cursor + 46 > bytes.size() or bytes.decode_u32(cursor) != 0x02014b50:
			errors.append("ZIP central directory is malformed")
			return []
		var name_length := int(bytes.decode_u16(cursor + 28))
		var extra_length := int(bytes.decode_u16(cursor + 30))
		var comment_length := int(bytes.decode_u16(cursor + 32))
		if cursor + 46 + name_length + extra_length + comment_length > bytes.size():
			errors.append("ZIP central-directory entry is truncated")
			return []
		var name := bytes.slice(cursor + 46, cursor + 46 + name_length).get_string_from_utf8()
		if String.chr(0xfffd) in name:
			errors.append("ZIP entry name is not valid UTF-8")
			return []
		var flags := int(bytes.decode_u16(cursor + 8))
		if flags & 1:
			errors.append("Encrypted ZIP entries are not supported: '%s'" % name)
			return []
		var compression := int(bytes.decode_u16(cursor + 10))
		if compression not in [0, 8]:
			errors.append("Unsupported ZIP compression method %d for '%s'" % [compression, name])
			return []
		var made_by := int(bytes.decode_u16(cursor + 4)) >> 8
		var external := int(bytes.decode_u32(cursor + 38))
		var unix_mode := (external >> 16) & 0xffff if made_by == 3 else 0
		var type_bits := unix_mode & 0xf000
		var file_type := "directory" if name.ends_with("/") else "file"
		if type_bits == 0xa000:
			file_type = "symlink"
		elif type_bits != 0 and type_bits not in [0x8000, 0x4000]:
			file_type = "special file"
		(
			entries
			. append(
				{
					"path": name,
					"compressed_size": int(bytes.decode_u32(cursor + 20)),
					"uncompressed_size": int(bytes.decode_u32(cursor + 24)),
					"file_type": file_type,
					"is_directory": file_type == "directory",
				}
			)
		)
		cursor += 46 + name_length + extra_length + comment_length
	return entries
