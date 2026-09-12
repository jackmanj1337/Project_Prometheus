class_name ZeroContentFixtureValidator extends RefCounted
# adopter-todo: ZERO-CONTENT-PREDICATE-FIXTURE-PLAN-2026-07-29
# The engine half of the Z0/Z1 fixture contract. Its consumer is the Pack_FE
# acceptance corpus that row is building, so the adopter lands in another repo
# -- which is why this is deferred debt rather than a permanent waiver.
# Canonical engine-side validator for the synthetic Z0/Z1 package contract corpus.
# It intentionally covers only the package shell and provenance tranche represented
# by those fixtures; later family schemas remain owned by EntitySchemaRegistry.

const SUPPORTED_SCHEMA_VERSION := 1


static func validate(root: String) -> Array[Dictionary]:
	var errors: Array[Dictionary] = []
	var manifest: Variant = _read_json(root.path_join("manifest.json"), errors)
	if not manifest is Dictionary:
		return _sorted(errors)
	if manifest.get("content_schema_version") != SUPPORTED_SCHEMA_VERSION:
		errors.append(
			_error("unsupported_content_schema_version", "manifest.json#/content_schema_version")
		)
	var catalogue_path: Variant = manifest.get("catalogue_path")
	if not _safe_relative(catalogue_path):
		errors.append(_error("unsafe_relative_path", "manifest.json#/catalogue_path"))
		return _sorted(errors)
	var catalogue: Variant = _read_json(root.path_join(String(catalogue_path)), errors)
	if not catalogue is Dictionary:
		return _sorted(errors)

	var seen_ids := {}
	var documents := {}
	var paths_by_kind := {}
	var indexed_files := {"manifest.json": true, String(catalogue_path): true}
	var entries: Variant = catalogue.get("entries", [])
	if not entries is Array:
		return _sorted(errors)
	for index in entries.size():
		var entry: Variant = entries[index]
		if not entry is Dictionary:
			continue
		var folded := String(entry.get("id", "")).to_lower()
		if seen_ids.has(folded):
			errors.append(
				_error(
					"casefolded_catalogue_id_collision",
					"%s#/entries/%d/id" % [catalogue_path, index]
				)
			)
		else:
			seen_ids[folded] = true
		var document_path: Variant = entry.get("path")
		if not _safe_relative(document_path):
			errors.append(
				_error("unsafe_relative_path", "%s#/entries/%d/path" % [catalogue_path, index])
			)
			continue
		indexed_files[String(document_path)] = true
		var document: Variant = _read_json(root.path_join(String(document_path)), errors)
		if document != null:
			documents[String(document_path)] = document
			paths_by_kind.get_or_add(String(entry.get("kind", "")), []).append(
				String(document_path)
			)

	if root.get_file().begins_with("z1_"):
		_validate_provenance(root, documents, paths_by_kind, indexed_files, errors)
	return _sorted(errors)


static func _validate_provenance(
	root: String,
	documents: Dictionary,
	paths_by_kind: Dictionary,
	indexed_files: Dictionary,
	errors: Array[Dictionary]
) -> void:
	var sources := {}
	var occurrences := {}
	for path in paths_by_kind.get("source_registry", []):
		var document: Dictionary = documents.get(path, {})
		sources.merge(document.get("sources", {}), true)
		occurrences.merge(document.get("occurrences", {}), true)
	for path in paths_by_kind.get("fixture_identity", []):
		var document: Dictionary = documents.get(path, {})
		var source_refs: Variant = document.get("source_refs")
		if not source_refs is Array or source_refs.is_empty():
			errors.append(_error("missing_document_source_refs", "%s#/source_refs" % path))
		else:
			for index in source_refs.size():
				if not sources.has(source_refs[index]):
					errors.append(
						_error("dangling_document_source_ref", "%s#/source_refs/%d" % [path, index])
					)
		for field_name in document.get("field_audits", {}):
			if not occurrences.has(document["field_audits"][field_name]):
				errors.append(
					_error(
						"missing_occurrence_coverage", "%s#/field_audits/%s" % [path, field_name]
					)
				)
	for path in paths_by_kind.get("asset_registry", []):
		for asset in documents.get(path, {}).get("assets", {}).values():
			if _safe_relative(asset.get("path")):
				indexed_files[String(asset["path"])] = true
	for relative in _files_below(root):
		if relative.ends_with(".import"):
			continue
		if not indexed_files.has(relative):
			errors.append(_error("unindexed_pack_file", relative))


static func _files_below(root: String, relative: String = "") -> Array[String]:
	var files: Array[String] = []
	var directory := DirAccess.open(root.path_join(relative))
	if directory == null:
		return files
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		var child := relative.path_join(name) if not relative.is_empty() else name
		if directory.current_is_dir():
			files.append_array(_files_below(root, child))
		else:
			files.append(child)
		name = directory.get_next()
	directory.list_dir_end()
	files.sort()
	return files


static func _safe_relative(value: Variant) -> bool:
	if typeof(value) != TYPE_STRING or String(value).is_empty() or "\\" in String(value):
		return false
	var path := String(value)
	if path.is_absolute_path() or path.begins_with("res://") or path.begins_with("user://"):
		return false
	for part in path.split("/"):
		if part in ["", ".", ".."]:
			return false
	return true


static func _read_json(path: String, errors: Array[Dictionary]) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append(_error("missing_file", path))
		return null
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		errors.append(_error("invalid_json", path))
		return null
	return json.data


static func _error(code: String, path: String) -> Dictionary:
	return {"code": code, "path": path}


static func _sorted(errors: Array[Dictionary]) -> Array[Dictionary]:
	errors.sort_custom(func(a, b): return [a["path"], a["code"]] < [b["path"], b["code"]])
	return errors
