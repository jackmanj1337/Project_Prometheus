class_name EditorDocumentSet extends RefCounted
# `[CEUI-3]` option B: documents open as tabs, and **each tab is an independent
# `[CEUI-S6]` transaction with its own dirty state**. This owns the strip -- which
# documents are open, in what order, which one is active -- and owns none of what is
# inside them.
#
# THE INDEPENDENCE IS THE RULING, NOT AN IMPLEMENTATION DETAIL. There is deliberately no
# "save all", no shared Undo stack and no set-wide staged edit anywhere in this file.
# `[CEUI-14]` resolved to document-local history precisely so that two open documents can
# never entangle; a convenience that committed or reverted across tabs would rebuild the
# project-wide history `[CEUI-S6]` declined to adopt, one helper at a time.
#
# CLOSING A DIRTY TAB REFUSES AND SAYS WHY. `[CEUI-S6]` allows close-without-saving --
# it is one of the three ways an overlay is discarded -- but not silently: the caller has
# to ask for it. So `close()` returns a refusal carrying an author-facing reason, and the
# surface turns that into its confirmation. This is `[EPUX-07]`'s focusable-but-not-
# activatable shape applied to an action rather than a row, and it is the same reason
# `RecordSelector.activate()` returns its reason instead of no-opping.
#
# WHY THE TAB STRIP IS NOT A `RecordSelector`. The selector exists for list/detail
# surfaces with availability gating (`[TSV-10]`, `[EPUX-04]`); a tab strip has no
# eligibility, no quantity, no filters and no detail payload, and forcing it through that
# vocabulary would mean a second meaning for `selected` beside the tree's. `[CEUI-S15]`
# requires ONE reference picker, not one list primitive for everything that is a row.

const DocumentScript = preload("res://scripts/editor/EditorDocument.gd")

const CLOSED := "closed"
const REFUSED_DIRTY := "refused_dirty"
const REFUSED_UNKNOWN := "refused_unknown"

## Author-facing; the surface shows it on the confirmation.
const DIRTY_CLOSE_REASON := "This document has unsaved changes. Save it, or close without saving."

signal active_changed(new_id: String, previous_id: String)
signal opened(document_id: String)
signal closed(document_id: String)
## Re-emitted from whichever document changed, so a tab strip can repaint its markers
## without connecting to every document itself.
signal document_dirty_changed(document_id: String, is_dirty: bool)

var _order: Array[String] = []
var _documents: Dictionary = {}
var _active: String = ""


## Opening an id that is already open ACTIVATES its tab instead of opening a second one.
## Two tabs over one document would be two overlays over one file, which is the only way
## this model can lose an edit.
func open(document: EditorDocument) -> EditorDocument:
	var document_id := document.id
	if _documents.has(document_id):
		activate(document_id)
		return _documents[document_id]
	_documents[document_id] = document
	_order.append(document_id)
	document.dirty_changed.connect(
		func(is_dirty: bool) -> void: document_dirty_changed.emit(document_id, is_dirty)
	)
	opened.emit(document_id)
	activate(document_id)
	return document


## `{outcome, id, reason}`. `discard_changes` is the author having answered the
## confirmation; without it a dirty document refuses and returns the reason.
func close(document_id: String, discard_changes: bool = false) -> Dictionary:
	if not _documents.has(document_id):
		return {"outcome": REFUSED_UNKNOWN, "id": document_id, "reason": ""}
	var document: EditorDocument = _documents[document_id]
	if document.is_dirty() and not discard_changes:
		return {"outcome": REFUSED_DIRTY, "id": document_id, "reason": DIRTY_CLOSE_REASON}
	document.discard()
	_documents.erase(document_id)
	var index := _order.find(document_id)
	_order.remove_at(index)
	if _active == document_id:
		# Activate the neighbour rather than the first tab: the author closed the thing in
		# front of them and expects to be left where they were, not sent to the start.
		var next_index: int = min(index, _order.size() - 1)
		_set_active("" if _order.is_empty() else _order[next_index])
	closed.emit(document_id)
	return {"outcome": CLOSED, "id": document_id, "reason": ""}


func has(document_id: String) -> bool:
	return _documents.has(document_id)


func get_document(document_id: String) -> EditorDocument:
	return _documents.get(document_id, null)


func ids() -> Array[String]:
	return _order.duplicate()


func size() -> int:
	return _order.size()


func active_id() -> String:
	return _active


func active() -> EditorDocument:
	return _documents.get(_active, null)


func activate(document_id: String) -> bool:
	if not _documents.has(document_id):
		return false
	_set_active(document_id)
	return true


## Wraps, because the strip is a ring the author cycles with a shortcut and a wall at the
## end is a dead keypress rather than a boundary that means anything.
func activate_next() -> String:
	return _step(1)


func activate_previous() -> String:
	return _step(-1)


## `{id, title, kind, dirty, active}` per tab, in strip order. `dirty` is `[CEUI-S11]`'s
## per-tab dirty state; `[CEUI-S17]` requires the surface to carry it in a channel that is
## not colour, which is why it is a value here rather than a hint to tint something.
func tabs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for document_id in _order:
		var document: EditorDocument = _documents[document_id]
		(
			out
			. append(
				{
					"id": document_id,
					"title": document.title,
					"kind": document.kind,
					"dirty": document.is_dirty(),
					"active": document_id == _active,
				}
			)
		)
	return out


func dirty_ids() -> Array[String]:
	var out: Array[String] = []
	for document_id in _order:
		if (_documents[document_id] as EditorDocument).is_dirty():
			out.append(document_id)
	return out


func any_dirty() -> bool:
	return not dirty_ids().is_empty()


## `[TSV-24]`, one level up from the selector's: which documents are open and which is
## active survive a recomposition. The documents themselves are held, not serialized --
## an overlay is session state and has no representation outside this process.
func capture_state() -> Dictionary:
	return {"order": _order.duplicate(), "active": _active}


func restore_state(state: Dictionary) -> void:
	var wanted: Array = state.get("order", [])
	var restored: Array[String] = []
	for document_id in wanted:
		if _documents.has(String(document_id)):
			restored.append(String(document_id))
	# Anything opened since the capture keeps its place at the end rather than being
	# dropped: a restore that closed tabs would be a state-loss bug wearing a restore's
	# name.
	for document_id in _order:
		if not restored.has(document_id):
			restored.append(document_id)
	_order = restored
	var active := String(state.get("active", ""))
	_set_active(active if _documents.has(active) else (_order[0] if not _order.is_empty() else ""))


func _step(direction: int) -> String:
	if _order.is_empty():
		return ""
	var index := _order.find(_active)
	if index < 0:
		index = 0
	else:
		index = wrapi(index + direction, 0, _order.size())
	_set_active(_order[index])
	return _active


func _set_active(document_id: String) -> void:
	if document_id == _active:
		return
	var previous := _active
	_active = document_id
	active_changed.emit(_active, previous)
