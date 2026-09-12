class_name CampaignEditorShell extends RefCounted
# The campaign editor shell's state, and the ADOPTER for `ContentTreeDescriptor` and
# `RecordSelector` (`EDITOR-SHELL-TREE-V1-2026-09-07`). `[CEUI-1]`'s left tree and
# `[CEUI-S30]`'s map layer list, both as state a headless test can assert.
#
# WHY A MODEL AND NOT THE SCREEN. The same argument `RecordSelector` and `ResponsiveLayout`
# both made: every rule these two rulings state is about STATE -- what categories exist,
# what order they are in, which layer is focused, what a locked layer does when activated.
# A Control cannot be asserted headlessly, and `CampaignEditorScreen` is then a renderer
# with no decisions of its own to get wrong.
#
# THIS FILE NAMES NO CONTENT FAMILY, AND NEITHER MAY ITS CALLERS. `[CEUI-S21]` rejected
# hand-coded categories because adding a content family would then mean editing the
# editor. `ContentTreeDescriptor` is deliberately the only thing that knows what families
# exist; a category list here -- or a `match` on a category id in the screen -- would undo
# the ruling the descriptor implements. The groups the tree draws are DERIVED from the
# categories the descriptor returned, which is why `groups()` builds them by walking the
# descriptor's output rather than declaring a group table.
#
# WHY NO LIVE CATALOGUE IS PASSED BY DEFAULT. `build()` takes an optional `RegistryCatalog`
# and the shell leaves it null unless a caller supplies one. `[CEUI-S13]` makes the editor
# reachable only where no campaign is active, so `RegistryManager`'s live catalogue would
# hold the engine baseline rather than pack content; the catalogue worth showing is the
# WORKING COPY's, and the working copy arrives with the document model in a later slice.
# The argument is kept open so that slice supplies one without touching this file.
#
# SLICE 2 ADDED THE DOCUMENT SIDE, AND IT IS THREE COLLABORATORS, NOT THREE FIELDS ON
# THIS CLASS. `EditorDocumentSet` owns `[CEUI-3]`'s tabs, `EditorWorkspaces` owns
# `[CEUI-S12]`'s seven workspaces with `EW-4`/`EW-5`/`EW-7`'s chrome rules, and
# `EditorIssues` owns `[CEUI-S26]`'s panel. Each is separately assertable, and this class
# is what wires them to one another: an edit committed in a document becomes that
# document's live entry in the issues panel, and a document closing takes its live entries
# with it. Those two connections are the whole of what the shell adds, and they are here
# rather than in the screen because a second surface driving a second shell is how two
# views start disagreeing about what is dirty.
#
# LAYER VISIBILITY IS NOT A `RecordSelector` GATE, AND LOCK IS. Both come from `CEUI-23`
# option A -- "named layers with per-layer visibility and lock" -- and they are different
# kinds of thing. Hiding a layer is the author changing what the CANVAS draws; the layer
# stays in the list, because a layer that vanished from the list when hidden could not be
# shown again. Locking a layer is a refusal to edit it, which is exactly the
# focusable-but-not-activatable shape `[EPUX-07]` ruled, so lock goes through the
# selector's availability provider and `activate()` returns the reason.

const DescriptorScript = preload("res://scripts/editor/ContentTreeDescriptor.gd")
const DocumentSetScript = preload("res://scripts/editor/EditorDocumentSet.gd")
const WorkspacesScript = preload("res://scripts/editor/EditorWorkspaces.gd")
const IssuesScript = preload("res://scripts/editor/EditorIssues.gd")
const FormScript = preload("res://scripts/editor/EditorFormModel.gd")
const BulkTableScript = preload("res://scripts/editor/EditorBulkTable.gd")
const SubjectScript = preload("res://scripts/editor/EditorSubject.gd")

## Why `activate()` refuses on a locked layer. Author-facing, because `RecordSelector`
## hands whatever it is given straight to the surface that displays it.
const LOCKED_LAYER_REASON := "This layer is locked. Unlock it to edit."

## `[CEUI-S11]`'s header, exactly as ruled: draft identity and dirty state, Undo/Redo,
## Validate, Test, Export, Help. Nothing is added to this list here -- the ruling names
## what is persistently in the header, and Save is deliberately absent from it because
## `[CEUI-S6]` made saving a document operation rather than a shell-wide one.
##
## Labels are ALWAYS shown and the bar scrolls when they overflow (`[CEUI-S11]`): never
## collapsed to icons, never truncated, never clipped. `[L10N-7]`'s 1.4x text extent makes
## seven labelled actions overflow at the only viewport the editor has, and `UBS-4`
## already answered that pressure with scrolling rather than clipping.
const HEADER_ACTION_UNDO := "undo"
const HEADER_ACTION_REDO := "redo"
const HEADER_ACTION_VALIDATE := "validate"
const HEADER_ACTION_TEST := "test"
const HEADER_ACTION_EXPORT := "export"
const HEADER_ACTION_HELP := "help"
const HEADER_ACTIONS: Array[String] = [
	HEADER_ACTION_UNDO,
	HEADER_ACTION_REDO,
	HEADER_ACTION_VALIDATE,
	HEADER_ACTION_TEST,
	HEADER_ACTION_EXPORT,
	HEADER_ACTION_HELP,
]
const HEADER_ACTION_LABELS: Dictionary = {
	HEADER_ACTION_UNDO: "Undo",
	HEADER_ACTION_REDO: "Redo",
	HEADER_ACTION_VALIDATE: "Validate",
	HEADER_ACTION_TEST: "Test",
	HEADER_ACTION_EXPORT: "Export",
	HEADER_ACTION_HELP: "Help",
}

## The reasons a header action refuses, author-facing per `EPUX-02`'s
## gated-shows-disabled-with-reason. None of these is an "unimplemented" placeholder: each
## states a precondition that stays true once the rest of the editor exists.
const NO_UNDO_REASON := "There is nothing to undo in this document."
const NO_REDO_REASON := "There is nothing to redo in this document."
const NO_DOCUMENT_REASON := "Open a document first."
## `[CEUI-S9]`: Test activates the WORKING COPY and Export writes it out, so both need one.
const NO_WORKING_COPY_REASON := "Open a campaign working copy first."

## `CEUI-1`: "regions resize and collapse but are not rearrangeable in v1". Collapsing is
## not rearranging -- a collapsed region keeps its place in the composition and comes back
## to it -- which is why it is allowed while `CEUI-4` forbids the other.
##
## The bottom panel is deliberately NOT one of these: `EW-5` gave it a per-workspace
## default and `EW-4` a height rule, so it is `EditorWorkspaces`' to own. Two owners for
## one region's visibility is how the ruled default stops being applied.
const REGION_TREE := "tree"
const REGION_INSPECTOR := "inspector"
const REGIONS: Array[String] = [REGION_TREE, REGION_INSPECTOR]

## `EW-9`, ruled option A: the editor keeps a 24 px minimum target and WARNS on non-kbm
## input; it never grows targets or reflows, because that is a second responsive state and
## `[CEUI-5]` spent real cost removing those. `[NMTE-S2]` states the hardware assumption,
## and Branch K kept the warning alive precisely because an author can arrive without a
## keyboard -- the iPad case.
const INPUT_MODE_MOUSE_KEYBOARD := "mouse_keyboard"
const NON_KBM_INPUT_WARNING := (
	"The campaign editor is built for a mouse and a physical keyboard. "
	+ "Some actions may be hard to reach without them."
)

## Emitted when a document saves, carrying the records for whoever owns the file. The shell
## has no path, and `[CEUI-S6]` call 1 kept file operations out of the transaction, so this
## is the boundary: the model produces the bytes and something else writes them.
signal document_saved(document_id: String, records: Dictionary)

var _content := RecordSelector.new()
var _layers := RecordSelector.new()
# layer id -> bool. Absent means the default: visible, unlocked.
var _layer_visible: Dictionary = {}
var _layer_locked: Dictionary = {}
var _documents := DocumentSetScript.new()
var _workspaces := WorkspacesScript.new()
var _issues := IssuesScript.new()
## `[CEUI-S9]`: the imported working copy the session is editing, never the installed pack.
## Empty until a working copy is opened, which is what gates Test and Export.
var _working_copy: Dictionary = {}
# document id -> `func(doc) -> ValidationReport`. Held here rather than on the document so
# `EditorDocument` stays a pure transaction with no opinion about who validates it.
var _document_validators: Dictionary = {}
# region id -> true when collapsed. Absent means shown; view state, and `[CEUI-S6]` lists
# view state among the things explicitly outside Undo.
var _collapsed_regions: Dictionary = {}
## Supplied by the surface from `InputModeManager`, rather than read from the autoload, so
## this stays a headless model and so the editor never writes to an input mode another row
## owns.
var _input_mode: String = INPUT_MODE_MOUSE_KEYBOARD
## The active document's records. `[CEUI-S23]` needs a selection to open the bulk table
## over and `[CEUI-S14]` needs exactly one record for the Inspector, so both read this --
## one selection, two surfaces, rather than a selection per surface that could disagree
## about what the author is pointing at.
var _records := RecordSelector.new()
## `[CEUI-S23]`'s OTHER selection: the marks a canvas selection published, as
## `EditorSubject`s. It is not a second selector because it is not a list -- a canvas
## selection is of objects inside one record, which a `RecordSelector` cannot address --
## and it is deliberately EXCLUSIVE with the record selection: whichever was made last owns
## the Inspector and the table, so the two surfaces can never both think they own the edit.
var _subject_selection: Array[Dictionary] = []
## Property lengths captured when `_subject_selection` was set, so a commit that inserted
## or removed an item can be told from one that only changed values. See `EditorSubject`.
var _subject_lengths: Dictionary = {}
## Supplied by the caller; the schema side of the editor, kept so a form does not build its
## own registry per record.
var _schemas: EntitySchemaRegistry = null


func _init() -> void:
	_layers.availability_provider = _layer_availability
	# The panel only offers to navigate to a document the tab set can actually open, which
	# is `[CEUI-S26]`'s closing paragraph: gated entries stay focusable and say why.
	_issues.openable_provider = func(document_id: String) -> bool:
		return _documents.has(document_id)
	_documents.closed.connect(_issues.forget_document)
	_records.allow_multi_select = true
	_documents.active_changed.connect(
		# The subject selection goes with the document, not with the session: a canvas
		# selection addresses items inside ONE document's record, so carrying it across a
		# tab change would point it into a document that has no such property.
		func(_new_id: String, _previous: String) -> void: _on_active_document_changed()
	)
	# The descriptor has already sorted both lists into display order, and neither
	# selector may re-sort them: the order IS the ruling's authored output.
	refresh()


## Rebuilds both lists from the descriptor. Both arguments are the descriptor's own, passed
## through unread -- see the header on why the catalogue is usually absent.
func refresh(schemas: EntitySchemaRegistry = null, catalogue: RegistryCatalog = null) -> void:
	var categories := DescriptorScript.build(schemas, catalogue)
	var content_records: Array = []
	for category in categories:
		content_records.append({"id": String(category["id"]), "payload": category})
	_content.set_records(content_records)

	var layer_records: Array = []
	for layer in DescriptorScript.map_layers(schemas):
		layer_records.append({"id": String(layer["id"]), "payload": layer})
	_layers.set_records(layer_records)
	for id in _layer_visible.keys().duplicate():
		if not _layers.has(String(id)):
			_layer_visible.erase(id)
	for id in _layer_locked.keys().duplicate():
		if not _layers.has(String(id)):
			_layer_locked.erase(id)
	_layers.refresh()


# ---- the `[CEUI-1]` left tree ----


## `[CEUI-S15]`'s selector, over the tree's categories. Exposed rather than wrapped: the
## screen needs focus, selection and activation, and a wrapper would be a second selector
## vocabulary for the surface the ruling exists to keep singular.
func content_selector() -> RecordSelector:
	return _content


## The tree's top level, DERIVED from the categories rather than declared. A group exists
## because a category claimed it, it is labelled from its own id, and it sorts by the
## `group_order` its members carry -- so a content family that introduces a new group gets
## one with no edit here, which is the whole of `[CEUI-S21]` applied to the level above
## categories.
##
## `{id, label, order, category_ids}`, in display order.
func groups() -> Array[Dictionary]:
	var by_id: Dictionary = {}
	var order: Array[String] = []
	for row in _content.rows():
		var category: Dictionary = row["payload"]
		var group_id := String(category["group"])
		if not by_id.has(group_id):
			by_id[group_id] = {
				"id": group_id,
				"label": DescriptorScript.fallback_label(group_id),
				"order": int(category["group_order"]),
				"category_ids": [] as Array[String],
			}
			order.append(group_id)
		(by_id[group_id]["category_ids"] as Array[String]).append(String(row["id"]))
	var out: Array[Dictionary] = []
	for group_id in order:
		out.append(by_id[group_id])
	return out


## The focused category's descriptor entry, or `{}` when the tree is empty.
func focused_category() -> Dictionary:
	var row := _content.row(_content.focused_id())
	if row.is_empty():
		return {}
	return row["payload"]


# ---- the `[CEUI-S30]` map layer list ----


func layer_selector() -> RecordSelector:
	return _layers


## `{id, label, order, properties, visible, locked}` per layer, in the schema's order. The
## first four are the descriptor's; the last two are this shell's, because visibility and
## lock are editor session state and not part of the map document.
func layer_rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row in _layers.rows():
		var layer: Dictionary = (row["payload"] as Dictionary).duplicate(true)
		layer["visible"] = is_layer_visible(String(row["id"]))
		layer["locked"] = is_layer_locked(String(row["id"]))
		out.append(layer)
	return out


func is_layer_visible(id: String) -> bool:
	return bool(_layer_visible.get(id, true))


func is_layer_locked(id: String) -> bool:
	return bool(_layer_locked.get(id, false))


## Returns false for a layer the schema does not declare. Hiding a layer never removes it
## from the list -- see the header.
func set_layer_visible(id: String, visible: bool) -> bool:
	if not _layers.has(id):
		return false
	_layer_visible[id] = visible
	return true


## Locking re-runs availability, so the selector drops the layer from its selection if it
## was selected. Focus is deliberately untouched: `[EPUX-07]` keeps a gated entry
## focusable, and locking the layer someone is standing on must not move them.
func set_layer_locked(id: String, locked: bool) -> bool:
	if not _layers.has(id):
		return false
	_layer_locked[id] = locked
	_layers.refresh()
	return true


# ---- `[CEUI-3]` documents, `[CEUI-S12]` workspaces, `[CEUI-S26]` issues ----


func documents() -> EditorDocumentSet:
	return _documents


func workspaces() -> EditorWorkspaces:
	return _workspaces


func issues() -> EditorIssues:
	return _issues


## `[CEUI-S9]`: what the editor is editing is an imported WORKING COPY with its own
## identity, never the installed pack. This holds that identity so Test and Export can be
## gated on its presence and so the status bar can name it; importing it is the pack
## lifecycle's job, not the shell's.
func set_working_copy(identity: Dictionary) -> void:
	_working_copy = identity.duplicate(true)


func working_copy() -> Dictionary:
	return _working_copy.duplicate(true)


func has_working_copy() -> bool:
	return not _working_copy.is_empty()


## Opens a document as a tab and returns it. `validator` is remembered per document and
## re-run on every commit, so `[CEUI-S25]`'s incremental pass is scheduled once here
## rather than at each call site that happens to commit an edit.
func open_document(
	document_id: String,
	kind: String,
	records: Dictionary,
	label: String = "",
	validator: Callable = Callable()
) -> EditorDocument:
	if _documents.has(document_id):
		_documents.activate(document_id)
		return _documents.get_document(document_id)
	var document := EditorDocument.open(document_id, kind, records, label)
	document.edit_committed.connect(
		func(report: ValidationReport) -> void: _issues.set_document_report(document_id, report)
	)
	if validator.is_valid():
		_document_validators[document_id] = validator
	_documents.open(document)
	_rebuild_record_list()
	return document


## Commits the active document's staged edit through its remembered validator. The one
## place an edit commits, so a caller cannot accidentally commit without validating and
## leave the panel showing a document's previous results as current.
func commit_active_edit() -> ValidationReport:
	var document := _documents.active()
	if document == null:
		return null
	var report := document.commit_edit(_document_validators.get(document.id, Callable()))
	# Index addressing is only honest while the array's shape is: see
	# `re_derive_subject_selection()`. Doing it here rather than in the surface means a
	# selection cannot outlive the edit that invalidated it no matter who committed.
	re_derive_subject_selection()
	return report


## Saves the active document and publishes its records. NOT a header action: `[CEUI-S11]`
## names the six that are persistently in the header and saving is not among them, because
## `[CEUI-S6]` made it a document operation. It reaches the author as a keyboard shortcut
## on the surface instead, which is the same affordance without amending a ruled list.
##
## Returns the records written, or `{}` when nothing is open.
func save_active_document() -> Dictionary:
	var document := _documents.active()
	if document == null:
		return {}
	var written := document.save()
	document_saved.emit(document.id, written)
	return written


## `[CEUI-S6]`: Undo is document-local and session-scoped, so it routes to the ACTIVE
## document and to nothing else. There is deliberately no shell-wide history.
func undo() -> bool:
	var document := _documents.active()
	return document != null and document.undo()


func redo() -> bool:
	var document := _documents.active()
	return document != null and document.redo()


## `[CEUI-S25]`'s explicit full-pack Validate, and the automatic passes at Test and Export.
## The report is produced by the caller's validators -- `CL-ADV-02` and the reuse-the-
## production-validators obligation (DLUX-15) require the editor to schedule them rather
## than keep a second interpretation.
func record_pack_validation(report: ValidationReport, pass_label: String = "") -> void:
	_issues.set_pack_pass(report, pass_label)


## `[CEUI-S11]`'s header, resolved against current state:
## `{id, label, available, reason}` in the ruled order. Availability is `EPUX-02`'s
## gated-shows-disabled-with-reason throughout, so a refused action is still in the bar,
## still focusable, and still says why.
func header_actions() -> Array[Dictionary]:
	var document := _documents.active()
	var out: Array[Dictionary] = []
	for action_id in HEADER_ACTIONS:
		var available := true
		var reason := ""
		match action_id:
			HEADER_ACTION_UNDO:
				available = document != null and document.can_undo()
				reason = (
					""
					if available
					else (NO_DOCUMENT_REASON if document == null else NO_UNDO_REASON)
				)
			HEADER_ACTION_REDO:
				available = document != null and document.can_redo()
				reason = (
					""
					if available
					else (NO_DOCUMENT_REASON if document == null else NO_REDO_REASON)
				)
			HEADER_ACTION_VALIDATE, HEADER_ACTION_TEST, HEADER_ACTION_EXPORT:
				available = has_working_copy()
				reason = "" if available else NO_WORKING_COPY_REASON
		(
			out
			. append(
				{
					"id": action_id,
					"label": String(HEADER_ACTION_LABELS[action_id]),
					"available": available,
					"reason": reason,
				}
			)
		)
	return out


## `[CEUI-S11]`'s draft identity and dirty state, which sit in the header beside the
## actions. `dirty` is ANY open document being dirty, because the header speaks for the
## draft and the per-tab marker speaks for the tab.
func draft_status() -> Dictionary:
	return {
		"identity": String(_working_copy.get("label", _working_copy.get("id", ""))),
		"has_working_copy": has_working_copy(),
		"dirty": _documents.any_dirty(),
		"dirty_document_ids": _documents.dirty_ids(),
	}


## `EW-6`'s status bar, which exists because four pieces of state belong in none of
## `[CEUI-S11]`'s header slots: which working copy is active, what owns the keyboard
## (`[CEUI-S3]` point 4), the standing validation freshness, and the selection count.
## Returned as values rather than a formatted line so the surface, not the model, decides
## how they are laid out.
func status_bar_state(keyboard_owner: String = "") -> Dictionary:
	var category := focused_category()
	return {
		"working_copy": String(_working_copy.get("label", _working_copy.get("id", ""))),
		"keyboard_owner": keyboard_owner,
		"validation": _issues.freshness_summary(),
		# The RECORD selection, not the tree's. `EW-6` puts a selection count in the status
		# bar so an author knows how many things an edit will touch, and after `[CEUI-S23]`
		# that is the bulk table's subject -- the tree selects a category, which is a place
		# to look rather than a thing to edit.
		"selection_count":
		(
			_subject_selection.size()
			if not _subject_selection.is_empty()
			else _records.selected_ids().size()
		),
		"category_selection_count": _content.selected_ids().size(),
		"focused_category": String(category.get("label", "")),
		"focused_layer": _layers.focused_id(),
	}


# ---- `[CEUI-S14]` the Inspector, `[CEUI-S23]` the bulk table ----


## The active document's records, multi-select. The Inspector reads its single subject from
## here and the bulk table reads its selection from here.
func record_selector() -> RecordSelector:
	return _records


## Publishes a canvas selection. `subjects` are `EditorSubject`s -- `EditorMapCanvas`
## already produces the address (`{property, index, group, tile, layer}` per mark), so the
## surface converts and hands them over rather than the shell reaching into the canvas.
##
## Setting a non-empty subject selection CLEARS the record selection, for the reason on
## `_subject_selection`: `[CEUI-S23]` routes one selection to one surface, and two live
## selections would make "how many things will this edit touch" unanswerable.
func set_subject_selection(subjects: Array) -> void:
	_subject_selection.clear()
	for entry in subjects:
		_subject_selection.append((entry as Dictionary).duplicate(true))
	var document := _documents.active()
	_subject_lengths = SubjectScript.capture_lengths(document, _subject_selection)
	if not _subject_selection.is_empty():
		_records.clear_selection()


func clear_subject_selection() -> void:
	_subject_selection.clear()
	_subject_lengths.clear()


func subject_selection() -> Array[Dictionary]:
	return _subject_selection.duplicate(true)


## Drops the parts of a canvas selection an edit has invalidated: a property that is gone,
## and -- the case that matters -- a property whose LENGTH changed, because an insertion or
## a deletion moves every index after it and the surviving addresses would silently name
## different objects than the ones the author clicked. Called after every commit.
func re_derive_subject_selection() -> void:
	if _subject_selection.is_empty():
		return
	var document := _documents.active()
	var kept := SubjectScript.re_derive(document, _subject_selection, _subject_lengths)
	_subject_selection.clear()
	for entry in kept:
		_subject_selection.append((entry as Dictionary).duplicate(true))
	_subject_lengths = SubjectScript.capture_lengths(document, _subject_selection)


## The schema registry the forms generate from. Held rather than built per form: a registry
## per record would be `[CEUI-S21]`'s cost paid once per row instead of once per session.
func set_schemas(schemas: EntitySchemaRegistry) -> void:
	_schemas = schemas
	_rebuild_record_list()


## The same registry, for a surface that derives from the schema rather than from a form --
## `[CEUI-S31]`'s map tools are derived from `map_data`'s own properties, and a second
## registry built for that would be `[CEUI-S21]`'s cost paid twice per session.
func schemas() -> EntitySchemaRegistry:
	return _schemas


## `[CEUI-S14]`/`[CEUI-S23]`: the Inspector edits EXACTLY ONE record. Returns null for an
## empty selection and for a multi-selection -- the second is not a degenerate case to
## paper over, it is the case `[CEUI-S23]` routes to the bulk table, and a form that
## quietly showed the first of forty records would be the mixed-value state the ruling
## refused to build twice.
func inspector_form() -> EditorFormModel:
	var document := _documents.active()
	if document == null:
		return null
	# A canvas selection outranks the record list when there is one, because it is the
	# more specific statement about what the author is pointing at: on a map document the
	# record selection can only ever name the whole map.
	if not _subject_selection.is_empty():
		if _subject_selection.size() > 1:
			return null
		return FormScript.over_subject(document, _subject_selection[0], _schemas)
	var selected := _records.selected_ids()
	var subject := ""
	if selected.size() == 1:
		subject = selected[0]
	elif selected.is_empty():
		subject = _records.focused_id()
	if subject == "" or not document.has_record(subject):
		return null
	return FormScript.over(document, subject, _schemas)


## `[CEUI-S23]`: any multi-selection opens the bulk table. Returns null below two, because
## a table over one record is the Inspector's job and offering both would be the two-routes-
## for-one-edit shape the ruling closed.
func bulk_table() -> EditorBulkTable:
	var document := _documents.active()
	if document == null:
		return null
	if not _subject_selection.is_empty():
		if _subject_selection.size() < 2:
			return null
		return BulkTableScript.over_subjects(document, _subject_selection, _schemas)
	var selected := _records.selected_ids()
	if selected.size() < 2:
		return null
	return BulkTableScript.over(document, selected, _schemas)


## Rebuilds the record list from the active document, preserving focus and selection by id.
## Called when the active tab changes and after an edit adds or removes a record.
func _on_active_document_changed() -> void:
	clear_subject_selection()
	_rebuild_record_list()


func _rebuild_record_list() -> void:
	var state := _records.capture_state()
	var document := _documents.active()
	var records: Array = []
	if document != null:
		for record_id in document.record_ids():
			records.append({"id": record_id, "payload": {"id": record_id}})
	_records.set_records(records)
	_records.restore_state(state)


# ---- `CEUI-1` region collapse, `EW-9` the input warning ----


func is_region_collapsed(region: String) -> bool:
	return bool(_collapsed_regions.get(region, false))


## Returns false for a region that is not one of the composition's. A silent accept would
## let a typo record a collapse nothing ever reads.
func set_region_collapsed(region: String, collapsed: bool) -> bool:
	if not REGIONS.has(region):
		return false
	_collapsed_regions[region] = collapsed
	return true


func set_input_mode(mode: String) -> void:
	_input_mode = mode


## `{active, message}`. Active for any input mode that is not mouse-and-keyboard. The
## surface shows the message; what it must NOT do is change a token, a target size or the
## composition, because `[CEUI-5]` removed the editor's second layout outright and a
## warning that reflowed would put one back under another name.
func input_mode_warning() -> Dictionary:
	var active := _input_mode != INPUT_MODE_MOUSE_KEYBOARD
	return {"active": active, "message": NON_KBM_INPUT_WARNING if active else ""}


# ---- `[TSV-24]` state across recomposition ----


## Everything that must survive a resize, a density change or an input-mode change: both
## selectors' state, plus the per-layer visibility and lock the author set. Keyed by id
## throughout, because the descriptor's output is re-derived on every rebuild.
func capture_state() -> Dictionary:
	return {
		"content": _content.capture_state(),
		"layers": _layers.capture_state(),
		"layer_visible": _layer_visible.duplicate(true),
		"layer_locked": _layer_locked.duplicate(true),
		"documents": _documents.capture_state(),
		"workspaces": _workspaces.capture_state(),
		# The issues panel's own state is its selector's focus. The ENTRIES are not
		# captured: they are derived from the two reports, and a restore that put back a
		# stale copy of them would be the panel claiming results it no longer holds.
		"issues": _issues.selector().capture_state(),
		"collapsed_regions": _collapsed_regions.duplicate(true),
		"records": _records.capture_state(),
	}


func restore_state(state: Dictionary) -> void:
	_layer_visible.clear()
	for id in (state.get("layer_visible", {}) as Dictionary).keys():
		if _layers.has(String(id)):
			_layer_visible[String(id)] = bool((state["layer_visible"] as Dictionary)[id])
	_layer_locked.clear()
	for id in (state.get("layer_locked", {}) as Dictionary).keys():
		if _layers.has(String(id)):
			_layer_locked[String(id)] = bool((state["layer_locked"] as Dictionary)[id])
	_layers.refresh()
	_content.restore_state(state.get("content", {}))
	_layers.restore_state(state.get("layers", {}))
	_documents.restore_state(state.get("documents", {}))
	_workspaces.restore_state(state.get("workspaces", {}))
	_issues.selector().restore_state(state.get("issues", {}))
	_collapsed_regions.clear()
	for region in state.get("collapsed_regions", {}) as Dictionary:
		if REGIONS.has(String(region)):
			_collapsed_regions[String(region)] = bool(
				(state["collapsed_regions"] as Dictionary)[region]
			)


func _layer_availability(id: String, _payload: Variant) -> Dictionary:
	if not is_layer_locked(id):
		return {"available": true, "reason": ""}
	# `GATE_VISIBLE_DISABLED` rather than hidden, explicitly: a locked layer the author
	# cannot see is a layer they cannot unlock.
	return {
		"available": false,
		"reason": LOCKED_LAYER_REASON,
		"gate": RecordSelector.GATE_VISIBLE_DISABLED,
	}
