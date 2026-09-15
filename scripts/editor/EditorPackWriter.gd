class_name EditorPackWriter extends RefCounted
# The write half of `[CEUI-S6]`: `CampaignEditorShell` reads `EditorDocument.records()`,
# hands them here, and collapses the document only once this has answered. Something has
# to own the path and the bytes, and it is deliberately not the document --
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
# A WRITE IS ALL OR NOTHING. Every record is checked and serialized before the first byte
# lands, so a refused record writes nothing at all. The bytes each destination held are
# captured before it is written, and a failure part-way -- a document, or the catalogue
# after every document -- puts them back. Without that, a late failure left the earlier
# documents on disk under a catalogue that did not name them, and the editor's own
# document still read dirty over a pack that had half-changed
# (`AUDIT-EDITOR-SAVE-ATOMICITY-2026-09-14`).
#
# WHAT THIS DOES NOT DO. It never deletes authored content. A document holds every record
# of its kind, so "a record is missing from the set" reads identically to "the author has
# not opened that part yet", and guessing wrong destroys authored content. Deletion is an
# explicit act with `[CEUI-S8]`'s confirmation and usage preview behind it. The one thing
# a rollback removes is a file or folder THIS call created, which held nothing before it.


class Result:
	extends RefCounted
	var written := false
	var errors: Array[String] = []
	## Pack-relative paths this call wrote, in the order they were written. Empty unless
	## the whole write landed.
	var paths: Array[String] = []
	## True when `data/catalogue.json` gained entries and was rewritten.
	var catalogue_updated := false


var _working_copy: EditorWorkingCopy


func _init(working_copy: EditorWorkingCopy) -> void:
	_working_copy = working_copy


## Writes one document's records into the working copy. `kind` is the catalogue kind the
## document was opened for; `records` is `EditorDocument.records()` -- `id -> {field: value}`,
## which for a schema-bearing kind is the whole document.
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

	# ---- plan: every refusal a record can earn, before anything is written ----
	# Each planned write is {relative, destination, bytes}. The catalogue, when it changes,
	# is planned LAST so it is written last: a catalogue naming a file that is not there yet
	# would make the whole pack unreadable, where a stray file only makes itself invisible.
	var planned: Array[Dictionary] = []
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
		planned.append(
			{"relative": relative, "destination": destination, "bytes": _json_bytes(document)}
		)
	if not added.is_empty():
		var index := _planned_catalogue(root, catalogue, added, result.errors)
		if not index.is_empty():
			planned.append(index)
	if not result.errors.is_empty():
		return result

	# ---- apply: all of it, or put back what was there ----
	if not _apply(planned, result.errors):
		return result
	for write_plan in planned:
		if String(write_plan["relative"]) != Tier2Catalogue.CATALOGUE_PATH:
			result.paths.append(String(write_plan["relative"]))
	result.catalogue_updated = not added.is_empty()
	result.written = not result.paths.is_empty()
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


## The catalogue rewrite as a planned write, or `{}` with a reason.
func _planned_catalogue(
	root: String, catalogue: Tier2Catalogue, added: Array[Dictionary], errors: Array[String]
) -> Dictionary:
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
		return {}
	return {
		"relative": Tier2Catalogue.CATALOGUE_PATH,
		"destination": destination,
		"bytes": _json_bytes({"format_version": catalogue.format_version, "entries": entries}),
	}


## Writes every planned file in order. On the first failure, every file already written
## -- and the one that failed, which an opened-for-write handle may have truncated -- is
## put back to the bytes it held, and folders this call created are removed. Returns
## false with reasons, including any file that could not be put back, because a rollback
## that fails silently is the same lie one level down.
func _apply(planned: Array[Dictionary], errors: Array[String]) -> bool:
	# destination -> PackedByteArray it held, or null when it did not exist.
	var before: Dictionary = {}
	for write_plan in planned:
		var destination := String(write_plan["destination"])
		if not FileAccess.file_exists(destination):
			before[destination] = null
			continue
		var handle := FileAccess.open(destination, FileAccess.READ)
		if handle == null:
			errors.append("Cannot read '%s' to protect it during the save" % destination)
			return false
		before[destination] = handle.get_buffer(handle.get_length())
		handle.close()

	var created_dirs: Array[String] = []
	var touched: Array[String] = []
	for write_plan in planned:
		var destination := String(write_plan["destination"])
		var parent := destination.get_base_dir()
		var missing := _missing_dirs(parent)
		# Recorded before the attempt: a recursive create can fail part-way down the chain.
		created_dirs.append_array(missing)
		if not missing.is_empty() and DirAccess.make_dir_recursive_absolute(parent) != OK:
			errors.append("Cannot create '%s'" % parent)
			_roll_back(touched, created_dirs, before, errors)
			return false
		touched.append(destination)
		if not _store(destination, write_plan["bytes"]):
			errors.append("Cannot write '%s'" % destination)
			_roll_back(touched, created_dirs, before, errors)
			return false
	return true


func _roll_back(
	touched: Array[String], created_dirs: Array[String], before: Dictionary, errors: Array[String]
) -> void:
	for index in range(touched.size() - 1, -1, -1):
		var destination := touched[index]
		var previous: Variant = before.get(destination, null)
		if previous == null:
			if FileAccess.file_exists(destination) and DirAccess.remove_absolute(destination) != OK:
				errors.append("'%s' was left behind and could not be removed" % destination)
		elif not _store(destination, previous):
			errors.append("'%s' could not be restored to its saved content" % destination)
	# Deepest first, so a parent is empty by the time it is asked. `_missing_dirs` lists
	# each chain deepest first and chains are appended in write order, so sorting by length
	# is enough.
	var dirs := created_dirs.duplicate()
	dirs.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	for dir_path in dirs:
		if DirAccess.dir_exists_absolute(dir_path):
			DirAccess.remove_absolute(dir_path)


## The folders `make_dir_recursive_absolute(path)` would create, deepest first.
static func _missing_dirs(path: String) -> Array[String]:
	var out: Array[String] = []
	var current := path
	while not current.is_empty() and not DirAccess.dir_exists_absolute(current):
		out.append(current)
		var parent := current.get_base_dir()
		if parent == current:
			break
		current = parent
	return out


static func _json_bytes(value: Variant) -> PackedByteArray:
	return JSON.stringify(value, "\t", true).to_utf8_buffer()


## The one place bytes reach the disk. An instance method, not static, so a test can put a
## refusing writer in front of the real screen and watch the whole save transaction answer
## a failure it cannot otherwise provoke on demand.
func _store(destination: String, bytes: PackedByteArray) -> bool:
	var handle := FileAccess.open(destination, FileAccess.WRITE)
	if handle == null:
		return false
	var stored := handle.store_buffer(bytes)
	handle.close()
	return stored
