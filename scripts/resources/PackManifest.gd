class_name PackManifest extends RefCounted
# Parsed identity and compatibility metadata for a campaign pack. This type is
# deliberately disk- and installer-agnostic: callers supply decoded JSON.

const FORMAT_VERSION := 1
const VALID_AUTHORING_STATUSES: Array[String] = ["draft", "complete"]

var id: String = ""
var version: String = ""
var forked_from: String = ""
var builder_content_version: String = ""
var authoring_status: String = "draft"
var format_version: int = FORMAT_VERSION
var save_migrations: Array[Dictionary] = []


static func parse(raw: Variant, source_path: String, errors: Array[String]) -> PackManifest:
	var prefix := "PackManifest(%s)" % source_path
	if not raw is Dictionary:
		errors.append("%s: root must be an object" % prefix)
		return null

	var data: Dictionary = raw
	var manifest := PackManifest.new()
	manifest.id = _string_field(data, "id", prefix, errors, true)
	manifest.version = _string_field(data, "version", prefix, errors, true)
	manifest.forked_from = _string_field(data, "forked_from", prefix, errors, false)
	manifest.builder_content_version = _string_field(
		data, "builder_content_version", prefix, errors, true
	)
	manifest.authoring_status = _string_field(data, "authoring_status", prefix, errors, false)
	if manifest.authoring_status.is_empty():
		manifest.authoring_status = "draft"
	elif not manifest.authoring_status in VALID_AUTHORING_STATUSES:
		errors.append(
			"%s: authoring_status must be one of %s" % [prefix, ", ".join(VALID_AUTHORING_STATUSES)]
		)
	var migration_rows: Variant = data.get("save_migrations", [])
	if not migration_rows is Array:
		errors.append("%s: save_migrations must be an array" % prefix)
	else:
		for index in migration_rows.size():
			if not migration_rows[index] is Dictionary:
				errors.append("%s: save_migrations[%d] must be an object" % [prefix, index])
				continue
			var row: Dictionary = migration_rows[index].duplicate(true)
			var migration_errors := SaveMigrationService.validate_declaration(row, manifest.id)
			for migration_error in migration_errors:
				errors.append("%s: save_migrations[%d] %s" % [prefix, index, migration_error])
			if migration_errors.is_empty():
				if (
					String(row["destination_package_id"]) != manifest.id
					or String(row["destination_package_version"]) != manifest.version
				):
					errors.append(
						(
							"%s: save_migrations[%d] destination version must match manifest"
							% [prefix, index]
						)
					)
				else:
					manifest.save_migrations.append(row)
	if (
		not data.has("format_version")
		or not typeof(data["format_version"]) in [TYPE_INT, TYPE_FLOAT]
	):
		errors.append("%s: format_version must be an integer" % prefix)
	else:
		var raw_version: float = float(data["format_version"])
		if raw_version != floor(raw_version):
			errors.append("%s: format_version must be an integer" % prefix)
		else:
			manifest.format_version = int(raw_version)
			if manifest.format_version != FORMAT_VERSION:
				errors.append(
					(
						"%s: unsupported format_version %d (expected %d)"
						% [prefix, manifest.format_version, FORMAT_VERSION]
					)
				)

	if not _valid_id(manifest.id):
		errors.append("%s: id must use lowercase letters, digits, '_' or '-'" % prefix)
	if not manifest.forked_from.is_empty() and not _valid_id(manifest.forked_from):
		errors.append("%s: forked_from must be empty or a valid pack id" % prefix)
	if errors.any(func(error): return error.begins_with(prefix + ":")):
		return null
	return manifest


static func _string_field(
	data: Dictionary, field: String, prefix: String, errors: Array[String], required: bool
) -> String:
	if not data.has(field):
		if required:
			errors.append("%s: missing %s" % [prefix, field])
		return ""
	if typeof(data[field]) != TYPE_STRING:
		errors.append("%s: %s must be a string" % [prefix, field])
		return ""
	var value := String(data[field]).strip_edges()
	if required and value.is_empty():
		errors.append("%s: %s cannot be empty" % [prefix, field])
	return value


static func _valid_id(value: String) -> bool:
	if value.is_empty():
		return false
	for character in value:
		if not character in "abcdefghijklmnopqrstuvwxyz0123456789_-":
			return false
	return true
