class_name Tier2Catalogue extends RefCounted
# Canonical index and validation boundary for structured campaign-pack JSON.
# It never installs a pack or selects runtime content. Content-family validators
# are registered Callables so the author-facing `kind` vocabulary stays open.

const FORMAT_VERSION := 1
const CATALOGUE_PATH := "data/catalogue.json"

var format_version: int = FORMAT_VERSION
var entries: Array[Dictionary] = []
var documents: Dictionary = {}
# Pack root on disk, set only when the catalogue was loaded from a directory. The
# archive path validates already-decoded documents with no directory to read, so it
# leaves this empty and the asset-integrity pass is skipped there — archive bytes are
# checked by `CampaignArchivePreflight` instead.
var pack_root: String = ""


static func parse(raw: Variant, source_path: String, errors: Array[String]) -> Tier2Catalogue:
	var prefix := "Tier2Catalogue(%s)" % source_path
	if not raw is Dictionary:
		errors.append("%s: root must be an object" % prefix)
		return null
	var data: Dictionary = raw
	var catalogue := Tier2Catalogue.new()
	if (
		not data.has("format_version")
		or not typeof(data["format_version"]) in [TYPE_INT, TYPE_FLOAT]
		or float(data["format_version"]) != floor(float(data["format_version"]))
	):
		errors.append("%s: format_version must be an integer" % prefix)
	else:
		catalogue.format_version = int(data["format_version"])
		if catalogue.format_version != FORMAT_VERSION:
			errors.append(
				(
					"%s: unsupported format_version %d (expected %d)"
					% [prefix, catalogue.format_version, FORMAT_VERSION]
				)
			)
	if not data.has("entries") or not data["entries"] is Array:
		errors.append("%s: entries must be an array" % prefix)
		return null
	if data["entries"].is_empty():
		errors.append("%s: entries cannot be empty" % prefix)

	var identities := {}
	var paths := {}
	for index in data["entries"].size():
		var entry_prefix := "%s: entries[%d]" % [prefix, index]
		var raw_entry: Variant = data["entries"][index]
		if not raw_entry is Dictionary:
			errors.append("%s must be an object" % entry_prefix)
			continue
		var entry := _parse_entry(raw_entry, entry_prefix, errors)
		if entry.is_empty():
			continue
		var identity := "%s\n%s" % [entry["kind"], entry["id"]]
		if identities.has(identity):
			errors.append(
				"%s duplicates kind/id '%s/%s'" % [entry_prefix, entry["kind"], entry["id"]]
			)
		elif paths.has(entry["path"]):
			errors.append("%s duplicates path '%s'" % [entry_prefix, entry["path"]])
		else:
			identities[identity] = true
			paths[entry["path"]] = true
			catalogue.entries.append(entry)

	if errors.any(func(error): return error.begins_with(prefix)):
		return null
	return catalogue


# Reads the canonical index and every indexed JSON document. Validators receive
# (document, entry, errors) and must only inspect/normalize data, never mutate
# runtime catalogues. Unknown kinds fail loud rather than loading unchecked data.
static func load_and_validate(
	pack_root: String,
	validators: Dictionary,
	errors: Array[String],
	report: ValidationReport = null
) -> Tier2Catalogue:
	var initial_error_count := errors.size()
	var root := pack_root.trim_suffix("/")
	var catalogue_path := root.path_join(CATALOGUE_PATH)
	var raw_catalogue: Variant = _read_json(catalogue_path, errors)
	if raw_catalogue == null:
		_adopt_since(report, errors, initial_error_count, ValidationRules.RULE_TIER2_DOCUMENT)
		return null
	var parsed_at := errors.size()
	var catalogue := parse(raw_catalogue, CATALOGUE_PATH, errors)
	if catalogue == null:
		_adopt_since(report, errors, parsed_at, ValidationRules.RULE_TIER2_DOCUMENT)
		return null
	_adopt_since(report, errors, parsed_at, ValidationRules.RULE_TIER2_DOCUMENT)
	catalogue.pack_root = root

	for entry in catalogue.entries:
		var kind: String = entry["kind"]
		var identity := "%s\n%s" % [kind, entry["id"]]
		if (
			not validators.has(kind)
			or typeof(validators[kind]) != TYPE_CALLABLE
			or not (validators[kind] as Callable).is_valid()
		):
			var missing := (
				"Tier2Catalogue: '%s/%s' has no registered validator" % [kind, entry["id"]]
			)
			errors.append(missing)
			if report != null:
				report.add(
					ValidationRules.RULE_TIER2_MISSING_VALIDATOR,
					missing,
					{"kind": kind, "id": entry["id"]}
				)
			continue
		var read_at := errors.size()
		var document: Variant = _read_json(root.path_join(entry["path"]), errors)
		if document == null:
			_adopt_since(report, errors, read_at, ValidationRules.RULE_TIER2_DOCUMENT, entry)
			continue
		var before := errors.size()
		validators[kind].call(document.duplicate(true), entry.duplicate(true), errors)
		_adopt_since(report, errors, before, ValidationRules.RULE_TIER2_DOCUMENT, entry)
		if errors.size() == before:
			catalogue.documents[identity] = document
	return catalogue if errors.size() == initial_error_count else null


# Puts the errors a flat-array pass just appended behind a rule id, without changing what
# that pass appends. The index is taken BEFORE the call, so this cannot pick up an error
# an earlier pass left in the same array -- the shared `errors` accumulator is reused
# across passes and across whole packs, and adopting by "everything in the array" would
# re-report the previous pass's findings under this pass's rule.
static func _adopt_since(
	report: ValidationReport,
	errors: Array[String],
	from_index: int,
	rule_id: String,
	entry: Variant = null
) -> void:
	if report == null or errors.size() <= from_index:
		return
	var subject: Dictionary = {}
	if entry is Dictionary:
		subject = {"kind": entry["kind"], "id": entry["id"]}
	for index in range(from_index, errors.size()):
		report.add(rule_id, errors[index], subject)


# Convenience composition for the shipped campaign validator set. Keeping the
# generic loader above public preserves the open registry extension point.
static func load_campaign_pack(
	pack_root: String, errors: Array[String], report: ValidationReport = null
) -> Tier2Catalogue:
	var validator_set = preload("res://scripts/resources/CampaignTier2Validators.gd")
	var catalogue := load_and_validate(pack_root, validator_set.registry(), errors, report)
	if catalogue == null:
		return null
	var schema_errors := validator_set.collect_entity_schema_errors(catalogue)
	errors.append_array(schema_errors)
	var asset_errors := validator_set.collect_asset_integrity_errors(catalogue)
	errors.append_array(asset_errors)
	var reference_errors := validator_set.collect_cross_reference_errors(catalogue)
	errors.append_array(reference_errors)
	if report != null:
		report.adopt_errors(ValidationRules.RULE_TIER2_ENTITY_SCHEMA, schema_errors)
		report.adopt_errors(ValidationRules.RULE_TIER2_ASSET_INTEGRITY, asset_errors)
		report.adopt_errors(ValidationRules.RULE_TIER2_CROSS_REFERENCE, reference_errors)
	return catalogue if errors.is_empty() else null


# The `[CEUI-S27]` form of the call above: the same three passes, reported as ISSUES with
# rule ids and gate-resolved severities instead of a flat array.
#
# It returns the catalogue AND the report because a caller needs both and the gate is the
# caller's decision, not this function's: the campaign editor asks `report.blocks()` at
# `ValidationGate.ACTIVATION` before a Test launch and at an export gate before writing an
# artifact, and a null catalogue with an empty report is not a thing this can produce --
# a null catalogue always carries at least one error issue.
static func load_campaign_pack_report(pack_root: String) -> Dictionary:
	var errors: Array[String] = []
	var report := ValidationReport.create()
	var catalogue := load_campaign_pack(pack_root, errors, report)
	return {"catalogue": catalogue, "report": report, "errors": errors}


# Validates already-decoded archive documents without extracting them. Keys in
# raw_documents are the normalized pack-relative paths from the catalogue.
static func validate_campaign_documents(
	catalogue: Tier2Catalogue,
	raw_documents: Dictionary,
	errors: Array[String],
	report: ValidationReport = null
) -> bool:
	var validator_set = preload("res://scripts/resources/CampaignTier2Validators.gd")
	var validators: Dictionary = validator_set.registry()
	for entry in catalogue.entries:
		var kind: String = entry["kind"]
		var identity := "%s\n%s" % [kind, entry["id"]]
		if (
			not validators.has(kind)
			or typeof(validators[kind]) != TYPE_CALLABLE
			or not (validators[kind] as Callable).is_valid()
		):
			var missing := (
				"Tier2Catalogue: '%s/%s' has no registered validator" % [kind, entry["id"]]
			)
			errors.append(missing)
			if report != null:
				report.add(
					ValidationRules.RULE_TIER2_MISSING_VALIDATOR,
					missing,
					{"kind": kind, "id": entry["id"]}
				)
			continue
		if not raw_documents.has(entry["path"]):
			var absent := "Tier2Catalogue: missing required JSON '%s'" % entry["path"]
			errors.append(absent)
			if report != null:
				report.add(
					ValidationRules.RULE_TIER2_DOCUMENT, absent, {"kind": kind, "id": entry["id"]}
				)
			continue
		var before := errors.size()
		validators[kind].call(
			raw_documents[entry["path"]].duplicate(true), entry.duplicate(true), errors
		)
		_adopt_since(report, errors, before, ValidationRules.RULE_TIER2_DOCUMENT, entry)
		if errors.size() == before:
			catalogue.documents[identity] = raw_documents[entry["path"]]
	if not errors.is_empty():
		return false
	var schema_errors := validator_set.collect_entity_schema_errors(catalogue)
	errors.append_array(schema_errors)
	var reference_errors := validator_set.collect_cross_reference_errors(catalogue)
	errors.append_array(reference_errors)
	if report != null:
		report.adopt_errors(ValidationRules.RULE_TIER2_ENTITY_SCHEMA, schema_errors)
		report.adopt_errors(ValidationRules.RULE_TIER2_CROSS_REFERENCE, reference_errors)
	return errors.is_empty()


func get_document(kind: String, id: String) -> Variant:
	return documents.get("%s\n%s" % [kind, id])


# Hash the validated logical catalogue, not installation paths or ZIP metadata.
# Sorting both identities and JSON keys makes the identity stable across exports.
func content_fingerprint() -> String:
	var rows: Array[String] = []
	for entry in entries:
		var identity := "%s\n%s" % [entry["kind"], entry["id"]]
		(
			rows
			. append(
				(
					JSON
					. stringify(
						{
							"kind": entry["kind"],
							"id": entry["id"],
							"document": documents.get(identity, null),
						},
						"",
						true
					)
				)
			)
		)
	rows.sort()
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update("\n".join(rows).to_utf8_buffer())
	return "sha256:%s" % context.finish().hex_encode()


static func _parse_entry(raw: Dictionary, prefix: String, errors: Array[String]) -> Dictionary:
	var entry := {}
	for field in ["kind", "id", "path"]:
		if (
			not raw.has(field)
			or typeof(raw[field]) != TYPE_STRING
			or String(raw[field]).strip_edges().is_empty()
		):
			errors.append("%s.%s must be a non-empty string" % [prefix, field])
		else:
			entry[field] = String(raw[field]).strip_edges()
	if entry.size() != 3:
		return {}
	if not PackManifest._valid_id(entry["kind"]):
		errors.append("%s.kind is not a valid id" % prefix)
	if not PackManifest._valid_id(entry["id"]):
		errors.append("%s.id is not a valid id" % prefix)
	if not _safe_json_path(entry["path"]):
		errors.append("%s.path must be a pack-relative .json path under data/" % prefix)
	return entry


static func _safe_json_path(path: String) -> bool:
	var normalized := path.replace("\\", "/")
	if (
		not normalized.begins_with("data/")
		or not normalized.ends_with(".json")
		or normalized.is_absolute_path()
		or normalized.begins_with("user://")
		or normalized.begins_with("res://")
	):
		return false
	for part in normalized.split("/"):
		if part == ".." or part.is_empty():
			return false
	return normalized != CATALOGUE_PATH


static func _read_json(path: String, errors: Array[String]) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("Tier2Catalogue: cannot open required JSON '%s'" % path)
		return null
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		errors.append(
			(
				"Tier2Catalogue: invalid JSON '%s' at line %d: %s"
				% [path, json.get_error_line(), json.get_error_message()]
			)
		)
		return null
	return json.data
