class_name EditorDocument extends RefCounted
# `[CEUI-S6]`'s document-scoped staged transaction, and the Undo unit `[CEUI-13]`/
# `[CEUI-14]` resolved to. One open document: its records, the edit in progress, the
# edits committed but not yet saved, and the session-scoped Undo history over them.
#
# WHY THERE ARE THREE LAYERS AND NOT TWO. `[CEUI-S6]` describes the ordinary document
# model -- "open a document, make changes, save; an interruption reverts" -- which is a
# saved state and an overlay. But `[CEUI-S25]` rules that a document is validated **when
# its staged edit commits, not continuously while the author types**, and `[CEUI-13]`
# makes that commit the Undo unit. Neither statement means anything with only two layers:
# with saved-plus-overlay, every keystroke is a commit and there is nothing for
# "not continuously" to exclude. So:
#
#   _saved    what the last save wrote. `discard()` returns here; an interruption reverts
#             here; this is the only layer a file write reads.
#   _overlay  edits the author has committed but not saved. `is_dirty()` is this layer
#             being non-empty, and Undo/Redo move within it.
#   _staged   the one edit in progress -- a field being typed, a bulk table's pending
#             cells. Validation has not seen it and Undo cannot reach it.
#
# THE REGISTER SAYS "COMMIT" FOR TWO DIFFERENT ACTS, SO THIS FILE DOES NOT. `commit_edit()`
# is the staged transaction's commit: the Undo unit, and what schedules `[CEUI-S25]`'s
# incremental validation. `save()` is the file operation, which `[CEUI-S6]` call 1
# excludes from Undo outright. Calling one when you meant the other is the mistake this
# naming exists to make visible.
#
# THIS CLASS NEVER TOUCHES THE FILESYSTEM. `save()` collapses the overlay and RETURNS the
# record set for its caller to write. That is not squeamishness about I/O: `[CEUI-S6]`
# removed file-touching operations from the transaction model entirely, so a document that
# could write its own file would have a side effect its own Undo could not reach.
#
# IT ALSO OWNS NO VALIDATION RULES. `commit_edit()` takes a validator callable and runs it;
# `[CEUI-S25]` restated `CL-ADV-02` and the reuse-the-production-validators obligation
# (DLUX-15) -- the editor SCHEDULES those validators and must not maintain a second
# interpretation of them.
#
# NO CONTENT FAMILY IS NAMED HERE, for the same reason `ContentTreeDescriptor` names none.
# A document carries an opaque `kind` string it never inspects, and records are
# `id -> {field: value}` dictionaries this class does not interpret.

const ReportScript = preload("res://scripts/validation/ValidationReport.gd")

## `[CEUI-S24]`: how an external disk edit is answered. Two buttons, no merge UI -- the
## structured diff was the largest unbudgeted piece of Section B and loses nothing that
## cannot be redone by hand.
const EXTERNAL_RELOAD := "reload"
const EXTERNAL_KEEP_MINE := "keep_mine"

## Emitted after `commit_edit()` applies a staged edit, carrying the report `[CEUI-S25]`
## produced for it. The issues panel listens; nothing else may re-run the validator to
## find out what happened.
signal edit_committed(report: ValidationReport)
signal dirty_changed(is_dirty: bool)
## `[CEUI-S24]`: raised once when disk diverges, and not again until it is answered.
signal external_change_detected

var id: String = ""
## Opaque. The category id this document belongs to, carried for the tab strip and the
## issues panel to group by; never matched on here.
var kind: String = ""
## Author-facing, for the tab label.
var title: String = ""

# record id -> {field: value}
var _saved: Dictionary = {}
var _overlay: Dictionary = {}
var _staged: Dictionary = {}
# Each entry is {before: {record: {field: {present, value}}}, after: {...}} holding the
# EFFECTIVE value on either side of the commit, so a step replays correctly whether or not
# a save has emptied the overlay underneath it.
var _undo: Array[Dictionary] = []
var _redo: Array[Dictionary] = []
var _last_report: ValidationReport = null
var _external: Dictionary = {}
var _was_dirty: bool = false


## `records` is `id -> {field: value}` and is copied, not referenced: the caller's
## dictionary is usually the loaded pack's, and an editor that mutated it in place would
## edit the installed content `[CEUI-S9]` exists to keep untouchable.
static func open(
	document_id: String, document_kind: String, records: Dictionary, label: String = ""
) -> EditorDocument:
	var doc := EditorDocument.new()
	doc.id = document_id
	doc.kind = document_kind
	doc.title = label if label != "" else document_id
	doc._saved = records.duplicate(true)
	return doc


# ---- reading ----


## Resolution order is staged, then overlay, then saved -- the author's most recent
## assertion wins, whether or not they have committed it yet.
func value(record_id: String, field: String, fallback: Variant = null) -> Variant:
	for layer in [_staged, _overlay, _saved]:
		var record: Dictionary = (layer as Dictionary).get(record_id, {})
		if record.has(field):
			return record[field]
	return fallback


func record(record_id: String) -> Dictionary:
	var out: Dictionary = (_saved.get(record_id, {}) as Dictionary).duplicate(true)
	for layer in [_overlay, _staged]:
		for field in (layer as Dictionary).get(record_id, {}) as Dictionary:
			out[field] = (layer as Dictionary)[record_id][field]
	return out


## Every record the document holds, with all three layers resolved. This is what a save
## writes and what a full validation pass reads.
func records() -> Dictionary:
	var ids: Dictionary = {}
	for layer in [_saved, _overlay, _staged]:
		for record_id in layer as Dictionary:
			ids[record_id] = true
	var out: Dictionary = {}
	for record_id in ids:
		out[String(record_id)] = record(String(record_id))
	return out


func record_ids() -> Array[String]:
	var out: Array[String] = []
	for record_id in records():
		out.append(String(record_id))
	out.sort()
	return out


func has_record(record_id: String) -> bool:
	return _saved.has(record_id) or _overlay.has(record_id) or _staged.has(record_id)


## Records with unsaved committed edits. The issues panel and the tab's dirty marker both
## want this, and neither should recompute it from the overlay's shape.
func dirty_record_ids() -> Array[String]:
	var out: Array[String] = []
	for record_id in _overlay:
		out.append(String(record_id))
	out.sort()
	return out


func is_dirty() -> bool:
	return not _overlay.is_empty()


func latest_report() -> ValidationReport:
	return _last_report


# ---- the staged edit ----


## Stages one cell. Repeated calls accumulate into ONE edit: the author typing into three
## fields of a form and committing has made a single Undo unit, which is what
## `[CEUI-13]`'s "the open document's staged overlay" says.
func stage(record_id: String, field: String, new_value: Variant) -> void:
	if not _staged.has(record_id):
		_staged[record_id] = {}
	(_staged[record_id] as Dictionary)[field] = new_value


## `[CEUI-S23]`'s bulk table: a multi-selection edit is ONE staged transaction over many
## records, not one per record. Cells are `{record_id, field, value}`.
func stage_many(cells: Array) -> int:
	var applied := 0
	for cell in cells:
		var entry: Dictionary = cell
		stage(String(entry["record_id"]), String(entry["field"]), entry["value"])
		applied += 1
	return applied


func has_staged_edit() -> bool:
	return not _staged.is_empty()


func staged_cells() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for record_id in _staged:
		for field in _staged[record_id] as Dictionary:
			(
				out
				. append(
					{
						"record_id": String(record_id),
						"field": String(field),
						"value": (_staged[record_id] as Dictionary)[field],
					}
				)
			)
	return out


func discard_staged() -> void:
	_staged.clear()


## Applies the staged edit to the overlay, pushes it onto Undo, and runs `[CEUI-S25]`'s
## incremental validation SCOPED TO THIS DOCUMENT. `validator` is
## `func(doc: EditorDocument) -> ValidationReport`; absent, the report is empty and the
## panel shows the document as validated-clean rather than unvalidated, because a document
## whose kind has no validator has genuinely produced no issues.
##
## Returns the report. A no-op commit (nothing staged) returns the previous report
## unchanged and pushes nothing onto Undo -- an empty Undo entry is a step the author
## would have to press Undo twice to get past.
func commit_edit(validator: Callable = Callable()) -> ValidationReport:
	if _staged.is_empty():
		return _last_report if _last_report != null else ReportScript.create()
	var before: Dictionary = {}
	var after: Dictionary = {}
	for record_id in _staged:
		before[record_id] = {}
		after[record_id] = {}
		for field in _staged[record_id] as Dictionary:
			# The EFFECTIVE value is recorded, not the overlay cell, and that is the whole
			# reason undo survives a save. After a save the overlay is empty, so an entry
			# describing overlay cells would undo to nothing observable -- the history
			# would silently stop working at exactly the moment `[CEUI-S6]` call 2 says it
			# is still live ("session-scoped", not save-scoped). `_apply_overlay_cells`
			# turns an effective value back into the right overlay state.
			(before[record_id] as Dictionary)[field] = _effective_cell(record_id, String(field))
			var new_value: Variant = (_staged[record_id] as Dictionary)[field]
			(after[record_id] as Dictionary)[field] = {"present": true, "value": new_value}
	_apply_overlay_cells(after)
	_staged.clear()
	_undo.append({"before": before, "after": after})
	# A new edit invalidates the redo branch. Keeping it would let Redo reapply a value
	# the author has since overwritten, which is the one behaviour every editor's users
	# read as corruption.
	_redo.clear()
	_last_report = validator.call(self) if validator.is_valid() else ReportScript.create()
	edit_committed.emit(_last_report)
	_notify_dirty()
	return _last_report


# ---- Undo, session-scoped and document-local ----


## `[CEUI-14]` option B. There is deliberately no cross-document history: `[CEUI-S6]`
## excluded file operations from the transaction, which removed nearly every action that
## spans documents. The one survivor -- an id rename that rewrites references -- is
## `[CEUI-S8]`'s explicit per-rename confirmation with a recovery snapshot, and is not
## routed through this stack.
func can_undo() -> bool:
	return not _undo.is_empty()


func can_redo() -> bool:
	return not _redo.is_empty()


func undo() -> bool:
	if _undo.is_empty():
		return false
	var entry: Dictionary = _undo.pop_back()
	_apply_overlay_cells(entry["before"])
	_redo.append(entry)
	_notify_dirty()
	return true


func redo() -> bool:
	if _redo.is_empty():
		return false
	var entry: Dictionary = _redo.pop_back()
	_apply_overlay_cells(entry["after"])
	_undo.append(entry)
	_notify_dirty()
	return true


func undo_depth() -> int:
	return _undo.size()


# ---- save and discard: the file boundary ----


## Collapses the overlay into the saved state and RETURNS the records to write.
##
## Not undoable, per `[CEUI-S6]` call 1. The Undo history is deliberately NOT cleared:
## saving does not un-make the edits behind it, and an author who saves and then undoes
## has simply made the document dirty again -- which is true, and which the next save
## fixes. Clearing here would silently discard history the ruling never said to discard.
func save() -> Dictionary:
	var written := records()
	_saved = written.duplicate(true)
	_overlay.clear()
	_staged.clear()
	_notify_dirty()
	return written


## Close-without-saving, cancel, or a crash: `[CEUI-S6]`'s "an interruption reverts".
## Undo goes with it, because `[CEUI-S6]` call 2 scoped the history to the session and
## `CEUI-37`'s recovery snapshot -- not this -- is the durable path back.
func discard() -> void:
	_overlay.clear()
	_staged.clear()
	_undo.clear()
	_redo.clear()
	_notify_dirty()


# ---- `[CEUI-S24]` external disk edits ----


## Desktop only; `[CEUI-S4]` gives the browser no watchable path, so on web nothing calls
## this and the editor says the affordance does not exist. Reports the divergence once and
## holds the disk state until it is answered -- a second detection while an unanswered one
## is pending would stack two prompts over one file.
func note_external_change(disk_records: Dictionary) -> bool:
	if not _external.is_empty():
		return false
	_external = disk_records.duplicate(true)
	external_change_detected.emit()
	return true


func has_external_change() -> bool:
	return not _external.is_empty()


func external_records() -> Dictionary:
	return _external.duplicate(true)


## `EXTERNAL_RELOAD` discards the overlay by the ordinary discard path and takes disk;
## `EXTERNAL_KEEP_MINE` leaves the overlay standing so the next save overwrites disk.
## Both are outside Undo -- `[CEUI-S6]` excludes file-touching operations, and Reload's
## effect on the overlay is `discard()`, which was never undoable either.
func resolve_external_change(choice: String) -> bool:
	if _external.is_empty():
		return false
	match choice:
		EXTERNAL_RELOAD:
			_saved = _external.duplicate(true)
			discard()
		EXTERNAL_KEEP_MINE:
			# Disk is deliberately NOT folded into `_saved`. Keeping mine means the next
			# save writes the author's records over whatever is there; recording disk as
			# saved would make the document look clean while differing from the file.
			pass
		_:
			return false
	_external.clear()
	return true


# ---- internals ----


## The effective value of a cell right now, as `{present, value}`. `present: false` means
## nothing has ever set it -- a distinct state from "set to null", and the one an undo has
## to be able to return to.
func _effective_cell(record_id: String, field: String) -> Dictionary:
	for layer in [_overlay, _saved]:
		var stored: Dictionary = (layer as Dictionary).get(record_id, {})
		if stored.has(field):
			return {"present": true, "value": stored[field]}
	return {"present": false}


## Applies `{record: {field: {present, value}}}` -- EFFECTIVE values -- to the overlay. One
## shape for commit, undo and redo, because three separate appliers is how the three drift.
##
## A cell whose target value already matches the saved state is ERASED from the overlay
## rather than written into it. That is what makes undoing back to the start leave the
## document CLEAN: writing the value would leave a non-empty overlay, `is_dirty()` would
## stay true forever after the first edit, and every dirty marker in the shell would lie.
func _apply_overlay_cells(cells: Dictionary) -> void:
	for record_id in cells:
		for field in cells[record_id] as Dictionary:
			var cell: Dictionary = (cells[record_id] as Dictionary)[field]
			var saved_record: Dictionary = _saved.get(record_id, {})
			var matches_saved: bool = (
				bool(cell["present"])
				and saved_record.has(field)
				and saved_record[field] == cell["value"]
			)
			if bool(cell["present"]) and not matches_saved:
				if not _overlay.has(record_id):
					_overlay[record_id] = {}
				(_overlay[record_id] as Dictionary)[field] = cell["value"]
			elif _overlay.has(record_id):
				(_overlay[record_id] as Dictionary).erase(field)
				if (_overlay[record_id] as Dictionary).is_empty():
					_overlay.erase(record_id)


func _notify_dirty() -> void:
	var now := is_dirty()
	if now == _was_dirty:
		return
	_was_dirty = now
	dirty_changed.emit(now)
