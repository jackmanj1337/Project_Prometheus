class_name EditorPackWriter extends RefCounted
# The write half of `[CEUI-S6]`: `EditorDocument.save()` collapses its overlay and RETURNS
# the record set, and `CampaignEditorShell.document_saved` publishes it. Something has to
# own the path and the bytes, and it is deliberately not either of them --
# `[CEUI-S6]` call 1 removed file operations from the transaction model, so a document
# that could write its own file would have a side effect its own Undo could not reach.
#
# EVERY WRITE IS CHECKED AGAINST THE WORKING COPY, NOT ASSUMED TO BE INSIDE IT. That check
# is what makes `[CEUI-S9]`'s separation structural: the editor has no path that writes
# into the installed root, and the way that claim usually decays is a helper that composes
# a path correctly today and is called with a different root tomorrow. So `_destination`
# refuses a path the working copy does not contain AND names the installed root
# separately, so a refusal says which rule it broke.
#
# THE CATALOGUE IS PART OF THE WRITE. A pack's documents are reachable only through
# `data/catalogue.json`; a record written to a file no entry names is invisible to every
# reader, including the editor's own next `load_catalogue()`. So a record the catalogue
# does not know about gets an entry, and the catalogue is rewritten in the same call.
# Existing records keep the path the catalogue already gives them -- moving a document
# because its id changed is `[CEUI-S8]`'s id rename, which is its own row.
#
# WHAT THIS DOES NOT DO. It never deletes. A document holds every record of its kind, so
# "a record is missing from the set" reads identically to "the author has not opened that
# part yet", and guessing wrong destroys authored content. Deletion is an explicit act
# with `[CEUI-S8]`'s confirmation and usage preview behind it.


class Result:
	extends RefCounted
	var written := false
	var errors: Array[String] = []
	## Pack-relative paths this call wrote, in the order they were written.
	var paths: Array[String] = []
	## True when `data/catalogue.json` gained entries and was rewritten.
	var catalogue_updated := false


var _working_copy: EditorWorkingCopy


func _init(working_copy: EditorWorkingCopy) -> void:
	_working_copy = working_copy


## Writes one document's records into the working copy. `kind` is the catalogue kind the
## document was opened for; `records` is `EditorDocument.save()`'s return value, which is
## `id -> {field: value}` -- for a schema-bearing kind, the whole document.
func write(kind: String, records: Dictionary) -> Result:
	var result := Result.new()
	if _working_copy == null or not _working_copy.is_open():
		result.errors.append("There is no campaign working copy to save into")
		return result
	if kind.is_empty():
		result.errors.append("A saved document must name the content kind it belongs to")
		return result
	var root := _working_copy.path()
	var catalogue := _working_copy.load_catalogue()
	if catalogue == null:
		result.errors.append("The campaign working copy's catalogue could not be read")
		return result

	var paths_by_id: Dictionary = {}
	var taken_paths: Dictionary = {}
	for entry in catalogue.entries:
		taken_paths[String(entry["path"])] = true
		if String(entry["kind"]) == kind:
			paths_by_id[String(entry["id"])] = String(entry["path"])

	var added: Array[Dictionary] = []
	for record_id in records.keys():
		var id := String(record_id)
		if not PackManifest._valid_id(id):
			result.errors.append(
				"'%s' cannot be saved: an id uses lowercase letters, digits, '_' or '-'" % id
			)
			continue
		var document: Variant = records[record_id]
		if not document is Dictionary:
			result.errors.append("'%s' cannot be saved: a record must be an object" % id)
			continue
		var relative := String(paths_by_id.get(id, ""))
		if relative.is_empty():
			relative = _new_document_path(kind, id, taken_paths)
			if relative.is_empty():
				result.errors.append("'%s' cannot be given a document path" % id)
				continue
			taken_paths[relative] = true
			added.append({"kind": kind, "id": id, "path": relative})
		var destination := _destination(root, relative, result.errors)
		if destination.is_empty():
			continue
		if not _write_json(destination, document, result.errors):
			continue
		result.paths.append(relative)

	if not added.is_empty() and result.errors.is_empty():
		result.catalogue_updated = _rewrite_catalogue(root, catalogue, added, result.errors)
	result.written = result.errors.is_empty() and not result.paths.is_empty()
	return result


## The absolute path a pack-relative DOCUMENT is written to, or "" with a reason.
## `_safe_json_path` is asked rather than reimplemented: it is what the catalogue parser
## admits, and a writer with its own idea of a legal path would produce packs the parser
## then refuses to read back.
func _destination(root: String, relative: String, errors: Array[String]) -> String:
	if not Tier2Catalogue._safe_json_path(relative):
		errors.append("'%s' is not a pack-relative .json path under data/" % relative)
		return ""
	var absolute := root.path_join(relative)
	return absolute if _contained(absolute, relative, errors) else ""


## The containment gate, asked of the catalogue index as well as of documents. Both
## refusals are stated separately because they are different failures: one is a path that
## landed in the library, the other is a path that escaped the draft entirely.
func _contained(absolute: String, subject: String, errors: Array[String]) -> bool:
	if _working_copy.is_installed_path(absolute):
		errors.append(
			(
				"Refusing to write '%s': installed campaign packages are never edited in place"
				% subject
			)
		)
		return false
	if not _working_copy.contains(absolute):
		errors.append("Refusing to write '%s': it is outside the working copy" % subject)
		return false
	return true


## A path for a record the catalogue has never seen. Grouped under the kind so it cannot
## collide with the flat `data/<id>.json` layout an exported pack usually has, and
## disambiguated if it somehow does -- a duplicate path makes the whole catalogue
## unparseable, which would cost the author the pack rather than the record.
static func _new_document_path(kind: String, id: String, taken: Dictionary) -> String:
	var base := "data/%s/%s" % [kind, id]
	var candidate := "%s.json" % base
	var attempt := 1
	while taken.has(candidate):
		candidate = "%s_%d.json" % [base, attempt]
		attempt += 1
		if attempt > 99:
			return ""
	return candidate


func _rewrite_catalogue(
	root: String, catalogue: Tier2Catalogue, added: Array[Dictionary], errors: Array[String]
) -> bool:
	var entries: Array[Dictionary] = []
	for entry in catalogue.entries:
		entries.append(
			{
				"kind": String(entry["kind"]),
				"id": String(entry["id"]),
				"path": String(entry["path"])
			}
		)
	entries.append_array(added)
	# The index is composed directly rather than through `_destination`: `_safe_json_path`
	# refuses `data/catalogue.json` by design, so that no DOCUMENT can overwrite the index.
	# Writing the index is this function's job, and it takes the same containment gate.
	var destination := root.path_join(Tier2Catalogue.CATALOGUE_PATH)
	if not _contained(destination, Tier2Catalogue.CATALOGUE_PATH, errors):
		return false
	return _write_json(
		destination, {"format_version": catalogue.format_version, "entries": entries}, errors
	)


static func _write_json(destination: String, value: Variant, errors: Array[String]) -> bool:
	var parent := destination.get_base_dir()
	if not parent.is_empty() and DirAccess.make_dir_recursive_absolute(parent) != OK:
		errors.append("Cannot create '%s'" % parent)
		return false
	var handle := FileAccess.open(destination, FileAccess.WRITE)
	if handle == null:
		errors.append("Cannot write '%s'" % destination)
		return false
	handle.store_string(JSON.stringify(value, "\t", true))
	handle.close()
	return true
