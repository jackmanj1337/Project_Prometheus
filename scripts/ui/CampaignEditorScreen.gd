extends Control
# `[CEUI-1]`'s editor shell: the generated content tree and map layer list (slice 1), and
# the tabbed documents, workspace bar, header, issues panel and status bar (slice 2). The
# renderer for `CampaignEditorShell`, which owns every decision this file draws.
#
# WHAT IS STILL EMPTY, AND WHY IT IS DELIBERATE. The centre column draws a document's
# identity and the Inspector is a frame. `[CEUI-S14]`'s schema-generated forms and
# `[CEUI-S23]`'s bulk table are the record-editing surface, and they are a separate build:
# the shell has to be able to hold a document before it is worth generating a form into
# one. Everything the shell OWNS -- what is open, what is dirty, what committed, what is
# wrong with it -- is drawn here and asserted headlessly.
#
# BOTH RULED ENTRY POINTS NOW REACH HERE, AND THEY REACH IT DIFFERENTLY. `[CEUI-S13]`'s
# main-menu entry calls `open()` -- the editor as a MODE, with no working copy, Test and
# Export gated on `has_working_copy()` with the reason the shell already carried.
# `[CEUI-S22]`'s *Edit a copy* calls `open_working_copy()` with an `EditorWorkingCopy` the
# library entry imported (`[CEUI-S9]`). Which of those the main-menu entry should be was
# the one thing neither ruling settles; opening empty is the reading the shell was built
# for, since `NO_WORKING_COPY_REASON` is authored text that only means anything if the
# editor can be open without one.
#
# THE EDITOR NEVER TOUCHES THE INSTALLED LIBRARY. Everything it writes goes through
# `EditorPackWriter`, which refuses a path the working copy does not contain. That refusal,
# not this comment, is what makes `[CEUI-S9]`'s separation structural.
#
# THIS FILE CONTAINS NO CONTENT FAMILY AND NO LAYER NAME. Every label it draws came from
# the descriptor, through the shell. If a future edit needs to branch on which category is
# focused, the branch belongs in declared metadata, not in a `match` here. The workspace
# ids ARE spelled here, and that is not the same thing: `[CEUI-S12]` ruled the seven, no
# pack contributes one, and `EditorWorkspaces` is where they are declared.
#
# `[CEUI-S2]`/`CEUI-5`: BELOW THE FLOOR, A MINIMUM-SIZE STATE, NEVER A COMPACT EDITOR. The
# floor is `1920 x 880` EFFECTIVE -- window size divided by editor scale -- and the ruling
# is that shrinking below it produces a message, not a rearrangement. The arithmetic now
# lives in `EditorShellMetrics`, because the panel default (`EW-4`) measures against the
# same floor and two copies of it is one copy too many.

const ShellScript = preload("res://scripts/editor/CampaignEditorShell.gd")
const MetricsScript = preload("res://scripts/editor/EditorShellMetrics.gd")
const WorkspacesScript = preload("res://scripts/editor/EditorWorkspaces.gd")
const DocumentSetScript = preload("res://scripts/editor/EditorDocumentSet.gd")
const RulesScript = preload("res://scripts/validation/ValidationRules.gd")
const FormScript = preload("res://scripts/editor/EditorFormModel.gd")
const BulkTableScript = preload("res://scripts/editor/EditorBulkTable.gd")
const WorkingCopyScript = preload("res://scripts/editor/EditorWorkingCopy.gd")
const PackWriterScript = preload("res://scripts/editor/EditorPackWriter.gd")
const SettingsScript = preload("res://scripts/editor/EditorLocalSettings.gd")
const ConfirmDialogScript = preload("res://scripts/ui/DisplayConfirmDialog.gd")

## Tree columns for the layer list. Visibility and lock are `CEUI-23` option A's two
## per-layer controls; they are columns rather than an inspector because the author toggles
## them while looking at the canvas, not while looking at a form.
const LAYER_COLUMN_NAME := 0
const LAYER_COLUMN_VISIBLE := 1
const LAYER_COLUMN_LOCKED := 2

## `[CEUI-S26]`: grouped by severity and by content, each entry navigable to the object AND
## field, and the pass it came from shown so a stale result cannot pass for a fresh one.
## `[CEUI-S17]`: severity is a COLUMN, never a tint -- the panel must not depend on colour.
const ISSUE_COLUMN_SEVERITY := 0
const ISSUE_COLUMN_MESSAGE := 1
const ISSUE_COLUMN_LOCATION := 2
const ISSUE_COLUMN_SOURCE := 3

## The bulk table draws one row per COMMON FIELD, not one per record. Editing a field there
## is `[CEUI-S23]`'s "one atomic edit" across the whole selection; a row per record would be
## forty single-record edits wearing a table's clothes.
const BULK_COLUMN_FIELD := 0
const BULK_COLUMN_VALUE := 1

## `[CEUI-S23]`: a column whose selected records disagree. Shown as text rather than as an
## empty cell, because empty is also a value an author can set.
const MIXED_LABEL := "(mixed)"

## `[CEUI-S16]` shows an unset value DISTINCTLY, and it has to be distinct from `(mixed)`
## too -- they are different facts. `str(null)` renders "<null>", which is a debug string,
## not something to put in front of an author.
const UNSET_LABEL := "(unset)"

## `EW-4` measured the floor case: with the panel open the document area is 552 px of the
## ~752 px the centre column has at `1920 x 880` after the header, workspace bar, tab strip
## and status bar. The panel is therefore ~200 px, not the 120 the first draft used -- at
## 120 the issues tree's column titles and `[CEUI-S26]`'s two grouping levels consumed the
## whole panel and no issue row was visible, which is a panel that reports its own headings.
const BOTTOM_PANEL_HEIGHT := 200.0

signal category_focused(category_id: String)
signal layer_focused(layer_id: String)
## Emitted when a locked layer refuses activation, carrying the reason. `[EPUX-07]`: the
## refusal has to be reachable by someone standing on the entry, so it leaves this screen
## rather than being swallowed. `EW-6`'s status bar shows it.
signal layer_activation_refused(layer_id: String, reason: String)
signal workspace_changed(workspace_id: String)
signal document_activated(document_id: String)
## `[CEUI-S6]` allows close-without-saving but not silently. The refusal leaves the screen
## so whatever owns dialogs can turn it into the confirmation; this screen shows no
## dialogs of its own.
signal document_close_refused(document_id: String, reason: String)
signal document_closed(document_id: String)
## `[CEUI-S26]`'s navigation target, object AND field.
signal issue_navigated(document_id: String, record_id: String, field: String)
signal issue_activation_refused(entry_id: String, reason: String)
## Header actions this screen does not itself perform. Undo and Redo are handled here
## because they are pure shell state; Validate, Test and Export need the working copy and
## the pack lifecycle, so they leave.
signal header_action_invoked(action_id: String)
## Re-emitted from the shell AFTER the working copy's files have been written, so a host
## that wants to react to a save (a bundle gate, a test) sees a save that happened rather
## than one that was about to.
signal document_saved(document_id: String, records: Dictionary)
## A save the writer refused, with its reasons. Separate from `document_saved` because a
## host that treated "saved" as "written" would show a clean document over unwritten bytes.
signal document_save_failed(document_id: String, errors: Array)
## `[CEUI-S13]`/`[CEUI-S22]`: the editor is a mode the shell opened, so it hands control
## back the same way every other pre-campaign screen does. There is no seventh header
## action -- `[CEUI-S11]` names six -- so this is reached by the cancel action.
signal back_pressed
## The working copy this screen was opened on, once it is adopted.
signal working_copy_opened(identity: Dictionary)
## `[CEUI-S1]`'s settings changed. Emitted rather than pushed so a consumer re-reads
## `editor_settings()`; `reduced_motion` and the editor-local `info_density` have no shell
## consumer yet and this is how the first one will find them.
signal editor_settings_changed

@onready var _shell_root: Control = $Shell
@onready var _minimum_size_state: Control = $MinimumSizeState
@onready var _minimum_size_label: Label = $MinimumSizeState/Message
@onready var _content_tree: Tree = $Shell/Body/TreePane/ContentTree
@onready var _layer_tree: Tree = $Shell/Body/TreePane/LayerList
@onready var _tree_pane: Control = $Shell/Body/TreePane
@onready var _inspector: Control = $Shell/Body/Workspace/Inspector
@onready var _status_bar: Control = $Shell/StatusBar
@onready var _status_working_copy: Label = $Shell/StatusBar/WorkingCopy
@onready var _status_keyboard: Label = $Shell/StatusBar/KeyboardOwner
@onready var _status_validation: Label = $Shell/StatusBar/Validation
@onready var _status_selection: Label = $Shell/StatusBar/Selection
@onready var _status_message: Label = $Shell/StatusBar/Message
@onready var _header: Control = $Shell/Header
@onready var _draft_identity: Label = $Shell/Header/DraftIdentity
@onready var _action_bar: HBoxContainer = $Shell/Header/ActionScroll/Actions
@onready var _workspace_bar: Control = $Shell/WorkspaceBar
@onready var _workspace_buttons: HBoxContainer = $Shell/WorkspaceBar/Workspaces
@onready var _tabs: TabBar = $Shell/Body/Workspace/Centre/Tabs
@onready
var _document_placeholder: Label = $Shell/Body/Workspace/Centre/DocumentColumns/Document/Placeholder
@onready var _second_column: Control = $Shell/Body/Workspace/Centre/DocumentColumns/SecondColumn
@onready var _bottom_panel: Control = $Shell/Body/Workspace/Centre/BottomPanel
@onready var _issue_tree: Tree = $Shell/Body/Workspace/Centre/BottomPanel/Issues
@onready var _record_tree: Tree = $Shell/Body/Workspace/Centre/DocumentColumns/Document/Records
@onready var _bulk_panel: Control = $Shell/Body/Workspace/Centre/DocumentColumns/Document/BulkTable
@onready
var _bulk_heading: Label = $Shell/Body/Workspace/Centre/DocumentColumns/Document/BulkTable/BulkHeading
@onready
var _bulk_tree: Tree = $Shell/Body/Workspace/Centre/DocumentColumns/Document/BulkTable/Columns
@onready
var _bulk_refused: Label = $Shell/Body/Workspace/Centre/DocumentColumns/Document/BulkTable/Refused
@onready var _inspector_heading: Label = $Shell/Body/Workspace/Inspector/Heading
@onready var _form_box: VBoxContainer = $Shell/Body/Workspace/Inspector/FormScroll/Form
@onready var _input_warning: Control = $Shell/InputWarning
@onready var _input_warning_label: Label = $Shell/InputWarning/Message

var _shell := ShellScript.new()
## `[CEUI-S1]`'s four editor-local settings. The scale that used to be a bare field with
## nothing behind it now comes from here; the floor check was always written against the
## effective size the ruling names, so wiring the setting in was a change to ONE place.
##
## The object is editor-local in both senses `EditorLocalSettings` documents: it is not the
## player's `SettingsManager`, and it is not the `ResponsiveLayout` autoload's globals. This
## screen still reads its density column statically with `tokens_for_mode()` and writes
## `menu_mode`/`info_density` on the autoload nowhere.
var _settings := SettingsScript.new()
## The editor's own `Theme`, carrying `[CEUI-S1]`'s font size as `default_font_size` so it
## reaches every label in the shell without each one being touched. Built here rather than
## authored in the scene because the size is an author preference, not a scene constant.
##
## `EW-8`: the editor's chrome theme and a pack's theme render in the same window at the
## same time, so the chrome's metrics must come from a theme the pack cannot reach. A theme
## owned by this screen and assigned to its own subtree is that, structurally.
var _editor_theme: Theme = null
## `[CEUI-S3]` point 4 and `EW-6`: which context owns the keyboard. Set by whatever takes
## keyboard ownership; the status bar's job is only to say so.
var _keyboard_owner: String = "Tree"
# category id -> TreeItem, so a focus change repaints without rebuilding the tree. A
# rebuild would drop the author's expanded groups, which is the state-loss shape
# `RecordSelector` was careful about one level down.
var _category_items: Dictionary = {}
var _layer_items: Dictionary = {}
var _issue_items: Dictionary = {}
var _record_items: Dictionary = {}
var _bulk_items: Dictionary = {}
# Tab strip index -> document id. `TabBar` is index-addressed and the document model is
# id-addressed; keeping the map explicit is what stops an index leaking into the model.
var _tab_ids: Array[String] = []
# Set while a rebuild writes check states or tab selections, so `item_edited` and
# `tab_changed` do not read their own writes back into the shell.
var _applying := false
# `[CEUI-S9]`'s working copy and the writer over it. Null until an entry point supplies
# one: `[CEUI-S13]`'s main-menu entry opens the editor with no working copy and the shell
# gates Test and Export on that, which is why the screen has always been able to draw
# itself without one.
var _working_copy: EditorWorkingCopy = null
var _writer: EditorPackWriter = null


func _ready() -> void:
	_content_tree.item_selected.connect(_on_category_selected)
	_layer_tree.item_selected.connect(_on_layer_selected)
	_layer_tree.item_activated.connect(_on_layer_activated)
	_layer_tree.item_edited.connect(_on_layer_edited)
	_tabs.tab_changed.connect(_on_tab_changed)
	_tabs.tab_close_pressed.connect(_on_tab_close_pressed)
	_issue_tree.item_activated.connect(_on_issue_activated)
	_record_tree.multi_selected.connect(_on_records_multi_selected)
	_bulk_tree.item_edited.connect(_on_bulk_edited)
	_shell.documents().opened.connect(func(_id: String) -> void: _refresh_documents())
	_shell.documents().document_dirty_changed.connect(
		func(_id: String, _dirty: bool) -> void: _refresh_documents()
	)
	_shell.issues().entries_changed.connect(_refresh_issues)
	_shell.document_saved.connect(_on_shell_document_saved)
	# Activating a category OPENS it. Until this row there was no way to open a document
	# from the surface at all, so the tab strip, the Inspector and the bulk table could
	# only be reached by a caller with a records dictionary in hand -- i.e. by a test.
	_content_tree.item_activated.connect(_on_category_activated)
	_shell.workspaces().workspace_changed.connect(
		func(new_id: String, _previous: String) -> void:
			_refresh_workspaces()
			workspace_changed.emit(new_id)
	)
	_shell.workspaces().panel_visibility_changed.connect(
		func(_workspace_id: String, _is_open: bool) -> void: _refresh_workspaces()
	)
	get_viewport().size_changed.connect(_on_viewport_resized)
	# READ from `InputModeManager`, never written to: `MOBILE-WEB-UX-GAPS-2026-08-03` owns
	# that autoload, and `[CEUI-S3]`'s per-viewport input context is its row, not this one.
	var input_mode := get_node_or_null("/root/InputModeManager")
	if input_mode != null:
		_shell.set_input_mode(String(input_mode.active_input_mode))
		input_mode.input_mode_changed.connect(set_input_mode)
	# A missing file is the normal first run, not a failure: the defaults ARE the ratified
	# column, so an author who has never touched a knob gets exactly the wireframed editor.
	_settings.load_from()
	_settings.changed.connect(_on_editor_settings_changed)
	_apply_editor_settings()
	rebuild()


## The shell state this screen renders. Exposed because later slices drive the same shell
## -- a second shell per screen is how two surfaces start disagreeing about what is focused.
func shell() -> CampaignEditorShell:
	return _shell


# ---- `[CEUI-S13]`/`[CEUI-S22]` the entry points, `[CEUI-S9]` the working copy ----


## Opens the editor with no working copy. `[CEUI-S13]`'s main-menu entry: the editor is a
## mode, and the mode is reachable before anything has been imported into it. Test and
## Export stay gated with `CampaignEditorShell.NO_WORKING_COPY_REASON`, which is the
## affordance the shell was built with and the reason it was built that way.
func open() -> void:
	show()
	rebuild()
	_content_tree.grab_focus()


## `[CEUI-S22]`'s *Edit a copy*: opens the editor ON an imported working copy.
##
## The shell gets three things it has been waiting for since slice 1 -- the identity Test
## and Export are gated on, the WORKING COPY's registry catalogue (`refresh()` has taken
## one and been passed null all along, because `[CEUI-S13]` puts the editor where the live
## catalogue holds only the engine baseline), and a writer for `document_saved`.
func open_working_copy(working_copy: EditorWorkingCopy) -> void:
	adopt_working_copy(working_copy)
	open()
	working_copy_opened.emit(_shell.working_copy())


## Adopting without showing, so a headless caller and the entry point run the same code.
func adopt_working_copy(working_copy: EditorWorkingCopy) -> void:
	_working_copy = working_copy
	_writer = PackWriterScript.new(working_copy) if working_copy != null else null
	if working_copy == null or not working_copy.is_open():
		_shell.set_working_copy({})
		reload(null, null)
		return
	_shell.set_working_copy(working_copy.identity())
	# Schemas are left as whatever `set_schemas` was given: `refresh()` passes them to the
	# descriptor and does not store them, so re-deriving one here would be a second
	# registry per session for no gain.
	reload(null, working_copy.registry_catalogue())


## The working copy this screen is editing, or null. Read by whatever drives Test and
## Export, which are this screen's to render and not to perform.
func working_copy() -> EditorWorkingCopy:
	return _working_copy


## Opens one content kind as a document, with the WORKING COPY's records in it. The tree's
## categories are content kinds, so this is what activating a category means.
##
## Returns null when there is no working copy or the kind holds nothing: a tab with no
## records is a surface that cannot say why it is empty, and the status bar can.
func open_kind(kind: String, label: String = "") -> EditorDocument:
	if _working_copy == null or not _working_copy.is_open():
		_status_message.text = ShellScript.NO_WORKING_COPY_REASON
		return null
	var records := _working_copy.records(kind)
	if records.is_empty():
		_status_message.text = (
			"This campaign has no %s to edit yet." % (label if not label.is_empty() else kind)
		)
		return null
	var document := _shell.open_document(
		kind,
		kind,
		records,
		label if not label.is_empty() else kind,
		WorkingCopyScript.document_validator(kind)
	)
	_refresh_documents()
	_refresh_records()
	return document


func _on_category_activated() -> void:
	var item := _content_tree.get_selected()
	if item == null:
		return
	var meta: Variant = item.get_metadata(0)
	if not (meta is Dictionary) or String((meta as Dictionary).get("kind", "")) != "category":
		return
	var category: Dictionary = meta
	open_kind(String(category["id"]), String(category.get("label", "")))
	_update_status_bar()


## The write `[CEUI-S6]` call 1 kept out of the document. It happens BEFORE the signal so
## a listener never sees a save the disk has not taken; a refusal reports itself instead of
## being lost, because a document that says it saved over bytes that were refused is the
## one failure an author cannot detect.
func _on_shell_document_saved(document_id: String, records: Dictionary) -> void:
	if _writer == null:
		document_saved.emit(document_id, records)
		return
	var document := _shell.documents().get_document(document_id)
	var kind := document.kind if document != null else ""
	var result := _writer.write(kind, records)
	if not result.errors.is_empty():
		_status_message.text = String(result.errors[0])
		document_save_failed.emit(document_id, result.errors.duplicate())
		return
	document_saved.emit(document_id, records)


## Re-derives the shell from the registries and repaints. `[TSV-24]`: the author's focus,
## selection and per-layer toggles are captured across the re-derivation and restored, so a
## pack that registers a new family mid-session does not cost them their place.
func reload(schemas: EntitySchemaRegistry = null, catalogue: RegistryCatalog = null) -> void:
	var state := _shell.capture_state()
	_shell.refresh(schemas, catalogue)
	_shell.restore_state(state)
	rebuild()


## Repaints everything from the shell. Does not re-derive: the shell is the authority on
## what exists, and a screen that re-derived on every repaint would fight whatever set the
## shell up.
func rebuild() -> void:
	_build_content_tree()
	_build_layer_tree()
	_sync_content_focus()
	_sync_layer_focus()
	_apply_density_tokens()
	_apply_viewport_floor()
	_refresh_input_warning()
	_refresh_documents()
	_refresh_records()
	_refresh_workspaces()
	_refresh_issues()
	_refresh_header()
	_apply_region_collapse()
	_update_status_bar()


func _build_content_tree() -> void:
	_applying = true
	_content_tree.clear()
	_category_items.clear()
	var root := _content_tree.create_item()
	_content_tree.hide_root = true
	for group in _shell.groups():
		var group_item := _content_tree.create_item(root)
		group_item.set_text(0, String(group["label"]))
		group_item.set_selectable(0, false)
		group_item.set_metadata(0, {"kind": "group", "id": String(group["id"])})
		for category_id in group["category_ids"]:
			var row := _shell.content_selector().row(String(category_id))
			if row.is_empty():
				continue
			var category: Dictionary = row["payload"]
			var item := _content_tree.create_item(group_item)
			item.set_text(0, String(category["label"]))
			item.set_metadata(0, {"kind": "category", "id": String(category_id)})
			# `[CEUI-S21]`: a family nothing declared still gets a category, and the surface
			# says so rather than presenting it as authored structure.
			if not bool(category["declared"]):
				item.set_tooltip_text(0, "Registered at runtime; no declared presentation.")
			_category_items[String(category_id)] = item
	_applying = false


func _build_layer_tree() -> void:
	_applying = true
	_layer_tree.clear()
	_layer_items.clear()
	var root := _layer_tree.create_item()
	_layer_tree.hide_root = true
	_apply_layer_columns()
	for layer in _shell.layer_rows():
		var id := String(layer["id"])
		var item := _layer_tree.create_item(root)
		item.set_text(LAYER_COLUMN_NAME, String(layer["label"]))
		item.set_metadata(LAYER_COLUMN_NAME, {"kind": "layer", "id": id})
		item.set_cell_mode(LAYER_COLUMN_VISIBLE, TreeItem.CELL_MODE_CHECK)
		item.set_editable(LAYER_COLUMN_VISIBLE, true)
		item.set_checked(LAYER_COLUMN_VISIBLE, bool(layer["visible"]))
		item.set_cell_mode(LAYER_COLUMN_LOCKED, TreeItem.CELL_MODE_CHECK)
		item.set_editable(LAYER_COLUMN_LOCKED, true)
		item.set_checked(LAYER_COLUMN_LOCKED, bool(layer["locked"]))
		# `[EPUX-07]`/`[CEUI-S17]`: a locked layer stays selectable so its reason is
		# reachable, and says why in a channel that is not colour.
		if bool(layer["locked"]):
			item.set_tooltip_text(LAYER_COLUMN_NAME, ShellScript.LOCKED_LAYER_REASON)
		_layer_items[id] = item
	_applying = false


## Two unlabelled checkbox columns are not readable, and `[CEUI-S17]` binds the editor to
## channels that are not colour or position. Titles say which column is which, and the name
## column expands so a layer's label is not truncated to make room for two 24 px checks.
func _apply_layer_columns() -> void:
	_layer_tree.column_titles_visible = true
	_layer_tree.set_column_title(LAYER_COLUMN_NAME, "Layer")
	_layer_tree.set_column_title(LAYER_COLUMN_VISIBLE, "Shown")
	_layer_tree.set_column_title(LAYER_COLUMN_LOCKED, "Locked")
	_layer_tree.set_column_expand(LAYER_COLUMN_NAME, true)
	for column in [LAYER_COLUMN_VISIBLE, LAYER_COLUMN_LOCKED]:
		_layer_tree.set_column_expand(column, false)
		_layer_tree.set_column_custom_minimum_width(column, 64)


func _sync_content_focus() -> void:
	var focused := _shell.content_selector().focused_id()
	if focused == "" or not _category_items.has(focused):
		return
	_applying = true
	(_category_items[focused] as TreeItem).select(0)
	_applying = false


func _sync_layer_focus() -> void:
	var focused := _shell.layer_selector().focused_id()
	if focused == "" or not _layer_items.has(focused):
		return
	_applying = true
	(_layer_items[focused] as TreeItem).select(LAYER_COLUMN_NAME)
	_applying = false


func _on_category_selected() -> void:
	if _applying:
		return
	var item := _content_tree.get_selected()
	if item == null:
		return
	var meta: Variant = item.get_metadata(0)
	if not (meta is Dictionary) or String((meta as Dictionary).get("kind", "")) != "category":
		return
	var id := String((meta as Dictionary)["id"])
	_shell.content_selector().focus(id)
	_keyboard_owner = "Content tree"
	_update_status_bar()
	category_focused.emit(id)


func _on_layer_selected() -> void:
	if _applying:
		return
	var item := _layer_tree.get_selected()
	if item == null:
		return
	var meta: Variant = item.get_metadata(LAYER_COLUMN_NAME)
	if not (meta is Dictionary):
		return
	var id := String((meta as Dictionary)["id"])
	_shell.layer_selector().focus(id)
	_keyboard_owner = "Map layers"
	_update_status_bar()
	layer_focused.emit(id)


func _on_layer_activated() -> void:
	var item := _layer_tree.get_selected()
	if item == null:
		return
	var meta: Variant = item.get_metadata(LAYER_COLUMN_NAME)
	if not (meta is Dictionary):
		return
	activate_layer(String((meta as Dictionary)["id"]))


## Activation goes through the selector, so the refusal and its reason are the selector's
## rather than a second rule written here. Returns the selector's outcome dictionary.
func activate_layer(id: String) -> Dictionary:
	var outcome := _shell.layer_selector().activate(id)
	if String(outcome["outcome"]) == RecordSelector.REFUSED_UNAVAILABLE:
		_status_message.text = String(outcome["reason"])
		layer_activation_refused.emit(id, String(outcome["reason"]))
	return outcome


func _on_layer_edited() -> void:
	if _applying:
		return
	var item := _layer_tree.get_edited()
	if item == null:
		return
	var meta: Variant = item.get_metadata(LAYER_COLUMN_NAME)
	if not (meta is Dictionary):
		return
	var id := String((meta as Dictionary)["id"])
	match _layer_tree.get_edited_column():
		LAYER_COLUMN_VISIBLE:
			_shell.set_layer_visible(id, item.is_checked(LAYER_COLUMN_VISIBLE))
		LAYER_COLUMN_LOCKED:
			_shell.set_layer_locked(id, item.is_checked(LAYER_COLUMN_LOCKED))
			item.set_tooltip_text(
				LAYER_COLUMN_NAME,
				ShellScript.LOCKED_LAYER_REASON if _shell.is_layer_locked(id) else ""
			)
	_update_status_bar()


# ---- `[CEUI-3]` the tab strip ----


## Rebuilt whole rather than diffed, because `TabBar` addresses tabs by index and a diff
## would have to maintain the index mapping in two directions. The strip is a handful of
## tabs; the rebuild is cheaper than the bug.
func _refresh_documents() -> void:
	_applying = true
	_tabs.clear_tabs()
	_tab_ids.clear()
	var active_index := -1
	for tab in _shell.documents().tabs():
		var id := String(tab["id"])
		# `[CEUI-S17]` binds the editor to non-colour channels for the dirty state, so the
		# marker is a character in the label rather than a tint on the tab.
		var label := String(tab["title"])
		if bool(tab["dirty"]):
			label = "%s *" % label
		_tabs.add_tab(label)
		var index := _tab_ids.size()
		_tabs.set_tab_tooltip(index, id)
		_tab_ids.append(id)
		if bool(tab["active"]):
			active_index = index
	if active_index >= 0:
		_tabs.current_tab = active_index
	_applying = false
	# The document summary belongs to `_refresh_records()`, which runs next and knows the
	# record list too -- writing it in both places is how the two drift.
	_refresh_header()
	_refresh_records()
	_update_status_bar()


func _on_tab_changed(index: int) -> void:
	if _applying or index < 0 or index >= _tab_ids.size():
		return
	var id := _tab_ids[index]
	_shell.documents().activate(id)
	_keyboard_owner = "Document"
	_refresh_documents()
	document_activated.emit(id)


func _on_tab_close_pressed(index: int) -> void:
	if index < 0 or index >= _tab_ids.size():
		return
	close_document(_tab_ids[index])


## `[CEUI-S6]`: closing a dirty document discards its overlay, so the caller has to ask for
## it. Without `discard_changes` this refuses and emits the reason for whatever owns the
## confirmation; the strip is left exactly as it was.
func close_document(document_id: String, discard_changes: bool = false) -> Dictionary:
	var outcome := _shell.documents().close(document_id, discard_changes)
	match String(outcome["outcome"]):
		DocumentSetScript.REFUSED_DIRTY:
			_status_message.text = String(outcome["reason"])
			document_close_refused.emit(document_id, String(outcome["reason"]))
		DocumentSetScript.CLOSED:
			_refresh_documents()
			document_closed.emit(document_id)
	return outcome


# ---- `[CEUI-S14]` the Inspector form, `[CEUI-S23]` the bulk table ----


## Draws the active document's records, then routes the selection: one record to the
## Inspector's form, two or more to the bulk table. That routing is `[CEUI-S23]` itself,
## and it lives here rather than in two independent surfaces so the two can never both
## think they own the edit.
func _refresh_records() -> void:
	_applying = true
	_record_tree.clear()
	_record_items.clear()
	var root := _record_tree.create_item()
	_record_tree.hide_root = true
	for row in _shell.record_selector().rows():
		var item := _record_tree.create_item(root)
		var record_id := String(row["id"])
		item.set_text(0, record_id)
		item.set_metadata(0, {"kind": "record", "id": record_id})
		_record_items[record_id] = item
		if bool(row["selected"]):
			item.select(0)
	_applying = false
	var document := _shell.documents().active()
	_document_placeholder.text = (
		"No document open."
		if document == null
		else (
			"%s  -  %d record(s)%s"
			% [
				document.title,
				document.record_ids().size(),
				"  -  unsaved changes" if document.is_dirty() else "",
			]
		)
	)
	_refresh_bulk_table()
	_refresh_inspector()


func _on_records_multi_selected(_item: TreeItem, _column: int, _selected: bool) -> void:
	if _applying:
		return
	var selector := _shell.record_selector()
	selector.clear_selection()
	var focused := ""
	for record_id in _record_items:
		var item: TreeItem = _record_items[record_id]
		if item.is_selected(0):
			selector.select(String(record_id))
			if focused == "":
				focused = String(record_id)
	if focused != "":
		selector.focus(focused)
	_keyboard_owner = "Records"
	_refresh_bulk_table()
	_refresh_inspector()
	_update_status_bar()


func _refresh_bulk_table() -> void:
	var table := _shell.bulk_table()
	_bulk_panel.visible = table != null
	_record_tree.visible = table == null
	if table == null:
		return
	_applying = true
	_bulk_tree.clear()
	_bulk_items.clear()
	_bulk_tree.column_titles_visible = true
	_bulk_tree.set_column_title(BULK_COLUMN_FIELD, "Field")
	_bulk_tree.set_column_title(BULK_COLUMN_VALUE, "Value for all %d" % table.size())
	var root := _bulk_tree.create_item()
	_bulk_tree.hide_root = true
	_bulk_heading.text = "Editing %d records together" % table.size()
	for column in table.columns():
		var item := _bulk_tree.create_item(root)
		item.set_text(BULK_COLUMN_FIELD, String(column["label"]))
		item.set_metadata(BULK_COLUMN_FIELD, {"kind": "bulk", "name": String(column["name"])})
		_draw_bulk_value(item, column)
		_bulk_items[String(column["name"])] = item
	# `[CEUI-S23]` inherits `[CEUI-S14]`'s restriction, and a refused field is named rather
	# than dropped: an absent column and an unavailable one look identical to an author.
	var refused: Array[String] = []
	for entry in table.refused_columns():
		refused.append(String(entry["label"]))
	_bulk_refused.text = (
		""
		if refused.is_empty()
		else "Edited one at a time in the Inspector: %s" % ", ".join(refused)
	)
	_applying = false


func _draw_bulk_value(item: TreeItem, column: Dictionary) -> void:
	if String(column["kind"]) == FormScript.FIELD_ENUM:
		item.set_cell_mode(BULK_COLUMN_VALUE, TreeItem.CELL_MODE_RANGE)
		var values: Array = column["enum_values"]
		item.set_text(BULK_COLUMN_VALUE, ",".join(values))
		# `enum_values` are stringified (an enum of integers is legal), so match on the
		# stringified value or an integer enum never finds its own current selection.
		item.set_range(BULK_COLUMN_VALUE, max(values.find(str(column["value"])), 0))
	else:
		item.set_cell_mode(BULK_COLUMN_VALUE, TreeItem.CELL_MODE_STRING)
		item.set_text(
			BULK_COLUMN_VALUE, MIXED_LABEL if bool(column["mixed"]) else _cell_text(column["value"])
		)
	item.set_editable(BULK_COLUMN_VALUE, true)


func _on_bulk_edited() -> void:
	if _applying:
		return
	var item := _bulk_tree.get_edited()
	if item == null:
		return
	var meta: Variant = item.get_metadata(BULK_COLUMN_FIELD)
	if not (meta is Dictionary):
		return
	var table := _shell.bulk_table()
	if table == null:
		return
	var field_name := String((meta as Dictionary)["name"])
	var value: Variant = null
	for column in table.columns():
		if String(column["name"]) != field_name:
			continue
		if String(column["kind"]) == FormScript.FIELD_ENUM:
			var values: Array = column["enum_values"]
			var index := int(item.get_range(BULK_COLUMN_VALUE))
			value = values[index] if index >= 0 and index < values.size() else ""
		else:
			value = _coerce(item.get_text(BULK_COLUMN_VALUE), String(column["kind"]), column)
		break
	var outcome := table.set_value(field_name, value)
	if not bool(outcome["accepted"]):
		_status_message.text = String(outcome["reason"])
		_refresh_bulk_table()
		return
	# ONE commit for the whole selection: `[CEUI-S23]`'s atomic edit, and therefore one
	# `[CEUI-13]` Undo step and one `[CEUI-S25]` validation pass rather than N of each.
	_shell.commit_active_edit()
	_refresh_records()


## The Inspector, which always edits exactly one record (`[CEUI-S23]`). Rebuilt rather than
## diffed: the field set changes with the record, and a diff would have to track controls
## per field name for no gain at this size.
func _refresh_inspector() -> void:
	for child in _form_box.get_children():
		_form_box.remove_child(child)
		child.queue_free()
	var form := _shell.inspector_form()
	if form == null:
		var table := _shell.bulk_table()
		_inspector_heading.text = (
			"Select a record" if table == null else "Editing %d records in the table" % table.size()
		)
		return
	if not form.has_schema():
		_inspector_heading.text = "%s  -  no schema registered" % form.record_id()
		return
	_inspector_heading.text = form.record_id()
	for field in form.fields():
		_form_box.add_child(_build_field_row(form, field))


func _build_field_row(form: EditorFormModel, field: Dictionary) -> Control:
	var row := VBoxContainer.new()
	var label := Label.new()
	# `[CEUI-S16]`: a value the author has not set is shown DISTINCTLY. In text, not by
	# tint -- `[CEUI-S17]` binds the editor to channels that are not colour.
	var origin := String(field["origin"])
	var suffix := ""
	if bool(field["required"]):
		suffix += "  (required)"
	if origin != FormScript.ORIGIN_AUTHORED:
		suffix += "  [%s]" % origin.replace("_", " ")
	label.text = "%s%s" % [String(field["label"]), suffix]
	row.add_child(label)
	row.add_child(_build_field_editor(form, field))
	return row


func _build_field_editor(form: EditorFormModel, field: Dictionary) -> Control:
	var field_name := String(field["name"])
	match String(field["kind"]):
		FormScript.FIELD_REFERENCE, FormScript.FIELD_ENUM:
			# `[CEUI-S15]`: references are chosen by browsing, never typed as a raw id. The
			# option list for a reference comes from the field's `RecordSelector`, which IS
			# the shared selector rather than a private picker.
			var options := OptionButton.new()
			var values: Array = []
			if String(field["kind"]) == FormScript.FIELD_REFERENCE:
				var selector := form.reference_selector(field_name)
				if selector != null:
					values = selector.ids()
			else:
				values = field["enum_values"]
			# `str()` throughout: an enum of integers (the schema-version header) would
			# crash `String()`, which takes only string-like types.
			var current := "" if field["value"] == null else str(field["value"])
			for index in values.size():
				options.add_item(str(values[index]), index)
				if str(values[index]) == current:
					options.select(index)
			options.item_selected.connect(
				func(index: int) -> void: _apply_field(form, field_name, values[index])
			)
			return options
		FormScript.FIELD_SCALAR:
			if String(field["type"]) == "boolean":
				var check := CheckBox.new()
				check.button_pressed = bool(field["value"]) if field["value"] != null else false
				check.toggled.connect(
					func(pressed: bool) -> void: _apply_field(form, field_name, pressed)
				)
				return check
			var line := LineEdit.new()
			line.text = "" if field["value"] == null else str(field["value"])
			line.text_submitted.connect(
				func(text: String) -> void:
					_apply_field(form, field_name, _coerce(text, String(field["kind"]), field))
			)
			return line
		_:
			# Structured values are form-only per `[CEUI-S14]`, and their editors are not
			# this row's. Shown read-only so the author can see the value exists rather
			# than concluding the field is missing.
			var readonly := Label.new()
			readonly.text = _cell_text(field["value"])
			return readonly


func _apply_field(form: EditorFormModel, field_name: String, value: Variant) -> void:
	var outcome := form.set_value(field_name, value)
	if not bool(outcome["accepted"]):
		_status_message.text = String(outcome["reason"])
		_refresh_inspector()
		return
	_shell.commit_active_edit()
	_refresh_records()


## An author-facing rendering of a value that may be absent. `str(null)` gives "<null>",
## which is a debug string; `[CEUI-S16]` wants unset shown distinctly, and an empty cell is
## not distinct because empty is also a value an author can set.
func _cell_text(value: Variant) -> String:
	return UNSET_LABEL if value == null else str(value)


## Text back to the field's type. The schema says what the field is, so a numeric field
## does not silently become a string the validator then rejects one commit later.
func _coerce(text: String, _kind: String, field: Dictionary) -> Variant:
	match String(field.get("type", "")):
		"integer":
			return int(text)
		"number":
			return float(text)
		"boolean":
			return text.to_lower() in ["true", "1", "yes"]
		_:
			return text


# ---- `[CEUI-S12]` the workspace bar, `EW-5`/`EW-7` the panel and the second column ----


func _refresh_workspaces() -> void:
	var rows := _shell.workspaces().rows()
	if _workspace_buttons.get_child_count() != rows.size():
		for child in _workspace_buttons.get_children():
			child.queue_free()
			_workspace_buttons.remove_child(child)
		for row in rows:
			var button := Button.new()
			button.toggle_mode = true
			button.name = String(row["id"])
			var workspace_id := String(row["id"])
			button.pressed.connect(
				func() -> void:
					_shell.workspaces().activate(workspace_id)
					_keyboard_owner = "Workspace bar"
			)
			_workspace_buttons.add_child(button)
	var index := 0
	for row in rows:
		var button: Button = _workspace_buttons.get_child(index) as Button
		# `[CEUI-S11]`'s answer to overflow, applied to the bar as well as the header:
		# labels are always shown and the container scrolls. Never icons, never truncation.
		button.text = String(row["label"])
		button.button_pressed = bool(row["active"])
		index += 1
	_bottom_panel.visible = _shell.workspaces().is_panel_open()
	_second_column.visible = _shell.workspaces().is_split_enabled()


## `EW-7`: the second document column is offered above the split threshold and remembered
## per workspace, never turned on by a resize. Refuses while the offer is not standing.
func set_split_enabled(enabled: bool) -> bool:
	var changed := _shell.workspaces().set_split_enabled(enabled)
	_refresh_workspaces()
	return changed


## `EW-5`: the author's own panel choice, which outranks the ruled per-workspace default
## from here on.
func set_bottom_panel_open(is_open: bool) -> void:
	_shell.workspaces().set_panel_open(is_open)
	_refresh_workspaces()


# ---- `[CEUI-S26]` the issues panel ----


func _refresh_issues() -> void:
	_applying = true
	_issue_tree.clear()
	_issue_items.clear()
	var root := _issue_tree.create_item()
	_issue_tree.hide_root = true
	_issue_tree.column_titles_visible = true
	_issue_tree.set_column_title(ISSUE_COLUMN_SEVERITY, "Severity")
	_issue_tree.set_column_title(ISSUE_COLUMN_MESSAGE, "Issue")
	_issue_tree.set_column_title(ISSUE_COLUMN_LOCATION, "Object and field")
	_issue_tree.set_column_title(ISSUE_COLUMN_SOURCE, "From")
	_issue_tree.set_column_expand(ISSUE_COLUMN_MESSAGE, true)
	for column in [ISSUE_COLUMN_SEVERITY, ISSUE_COLUMN_LOCATION, ISSUE_COLUMN_SOURCE]:
		_issue_tree.set_column_expand(column, false)
		_issue_tree.set_column_custom_minimum_width(column, 180)
	for group in _shell.issues().grouped():
		var severity_item := _issue_tree.create_item(root)
		severity_item.set_text(
			ISSUE_COLUMN_SEVERITY,
			"%s (%d)" % [String(group["severity"]).capitalize(), int(group["count"])]
		)
		severity_item.set_selectable(ISSUE_COLUMN_SEVERITY, false)
		for content_group in group["groups"]:
			var group_item := _issue_tree.create_item(severity_item)
			group_item.set_text(
				ISSUE_COLUMN_SEVERITY,
				"%s (%d)" % [String(content_group["group"]), int(content_group["count"])]
			)
			group_item.set_selectable(ISSUE_COLUMN_SEVERITY, false)
			for entry_id in content_group["entry_ids"]:
				_draw_issue(group_item, String(entry_id))
	_applying = false
	# The standing validation count and its freshness live in the status bar (`EW-6`), so
	# a panel refresh that did not touch it would leave the bar reporting the previous
	# pass -- which is the one thing `[CEUI-S26]`'s staleness rule exists to prevent.
	_update_status_bar()


func _draw_issue(parent: TreeItem, entry_id: String) -> void:
	var row := _shell.issues().selector().row(entry_id)
	if row.is_empty():
		return
	var entry: Dictionary = row["payload"]
	var item := _issue_tree.create_item(parent)
	item.set_text(ISSUE_COLUMN_SEVERITY, String(entry["severity"]).capitalize())
	item.set_text(ISSUE_COLUMN_MESSAGE, String(entry["message"]))
	# Object and field, because `[CEUI-S26]` navigates to both and an author cannot act on
	# a record id alone when the record has forty fields.
	var location := String(entry["record"])
	if String(entry["field"]) != "":
		location = "%s.%s" % [location, String(entry["field"])]
	item.set_text(ISSUE_COLUMN_LOCATION, location)
	# Staleness is SHOWN, not avoided: a pack-wide entry says which pass produced it, so
	# the panel never presents an unrechecked result as current.
	var source := String(entry["pass_label"]) if String(entry["pass_label"]) != "" else "live"
	if bool(entry["stale"]):
		source = "%s (stale)" % source
	item.set_text(ISSUE_COLUMN_SOURCE, source)
	item.set_metadata(ISSUE_COLUMN_SEVERITY, {"kind": "issue", "id": entry_id})
	if not bool(row["available"]):
		# `[EPUX-07]`: still in the list, still focusable, and its reason reachable from it.
		item.set_tooltip_text(ISSUE_COLUMN_SEVERITY, String(row["reason"]))
	_issue_items[entry_id] = item


func _on_issue_activated() -> void:
	var item := _issue_tree.get_selected()
	if item == null:
		return
	var meta: Variant = item.get_metadata(ISSUE_COLUMN_SEVERITY)
	if not (meta is Dictionary):
		return
	activate_issue(String((meta as Dictionary)["id"]))


## Goes through the panel's selector, so an entry whose document cannot be opened refuses
## and returns its reason rather than silently doing nothing.
func activate_issue(entry_id: String) -> Dictionary:
	var outcome := _shell.issues().activate(entry_id)
	if String(outcome["outcome"]) == RecordSelector.REFUSED_UNAVAILABLE:
		_status_message.text = String(outcome["reason"])
		issue_activation_refused.emit(entry_id, String(outcome["reason"]))
		return outcome
	if outcome.has("target"):
		var target: Dictionary = outcome["target"]
		var document_id := String(target["document"])
		if document_id != "" and _shell.documents().has(document_id):
			_shell.documents().activate(document_id)
			_refresh_documents()
		issue_navigated.emit(document_id, String(target["record"]), String(target["field"]))
	return outcome


# ---- `[CEUI-S11]` the header ----


func _refresh_header() -> void:
	var actions := _shell.header_actions()
	if _action_bar.get_child_count() != actions.size():
		for child in _action_bar.get_children():
			child.queue_free()
			_action_bar.remove_child(child)
		for action in actions:
			var button := Button.new()
			button.name = String(action["id"])
			var action_id := String(action["id"])
			button.pressed.connect(func() -> void: invoke_header_action(action_id))
			_action_bar.add_child(button)
	var index := 0
	for action in actions:
		var button: Button = _action_bar.get_child(index) as Button
		# Labels ALWAYS, never icons and never truncated (`[CEUI-S11]`). The overflow this
		# creates in a translated build is answered by the header's ScrollContainer, which
		# is the same answer `UBS-4` gave the same pressure.
		button.text = String(action["label"])
		button.disabled = not bool(action["available"])
		button.tooltip_text = String(action["reason"])
		index += 1
	var draft := _shell.draft_status()
	_draft_identity.text = (
		"No working copy"
		if not bool(draft["has_working_copy"])
		else "%s%s" % [String(draft["identity"]), " *" if bool(draft["dirty"]) else ""]
	)


## Undo and Redo are performed here because they are pure shell state and routing them out
## would make every host re-implement two lines. Everything else leaves: Validate, Test and
## Export need the working copy and the pack lifecycle, which are not this screen's.
func invoke_header_action(action_id: String) -> bool:
	for action in _shell.header_actions():
		if String(action["id"]) != action_id:
			continue
		if not bool(action["available"]):
			_status_message.text = String(action["reason"])
			return false
		break
	match action_id:
		ShellScript.HEADER_ACTION_UNDO:
			_shell.undo()
			_refresh_documents()
		ShellScript.HEADER_ACTION_REDO:
			_shell.redo()
			_refresh_documents()
	header_action_invoked.emit(action_id)
	return true


## Leaving the editor. `[CEUI-S11]` names the six header actions and none of them is Back,
## so the way out is the cancel action -- the same one every other pre-campaign screen
## closes on, which is why no new vocabulary is invented here. `[CEUI-40]` wants every
## essential action keyboard-reachable, and this is one.
func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("cancel"):
		return
	get_viewport().set_input_as_handled()
	close()


## Hides the editor and hands control back. Does NOT deactivate anything: `[CEUI-S13]`
## removed the editor's entry transition, and an exit transition would reintroduce it from
## the other side. Whatever ran a Test session owns ending it.
func close() -> void:
	hide()
	back_pressed.emit()


## Ctrl+S. Save is deliberately NOT one of `[CEUI-S11]`'s six header actions -- the ruling
## names what is persistently in the header and saving is a document operation under
## `[CEUI-S6]` -- so the author reaches it by keyboard instead of by amending a ruled list.
## `[CEUI-40]` requires every essential action to be keyboard-reachable anyway.
func _shortcut_input(event: InputEvent) -> void:
	if not _shell_root.visible:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_S and key.ctrl_pressed and not key.shift_pressed:
		save_active_document()
		get_viewport().set_input_as_handled()


## Returns the records written, or `{}` when nothing is open. The screen does not write
## them either; `document_saved` carries them out to whatever owns the working copy.
func save_active_document() -> Dictionary:
	var written := _shell.save_active_document()
	if written.is_empty():
		_status_message.text = ShellScript.NO_DOCUMENT_REASON
	else:
		_refresh_documents()
	return written


# ---- `CEUI-1` region collapse, `EW-9` the input warning ----


## Collapsing hides a region; it never moves one. `CEUI-4` fixed the composition for v1,
## so a collapsed tree comes back exactly where it was rather than somewhere convenient.
func set_region_collapsed(region: String, collapsed: bool) -> bool:
	if not _shell.set_region_collapsed(region, collapsed):
		return false
	_apply_region_collapse()
	return true


func _apply_region_collapse() -> void:
	_tree_pane.visible = not _shell.is_region_collapsed(ShellScript.REGION_TREE)
	_inspector.visible = not _shell.is_region_collapsed(ShellScript.REGION_INSPECTOR)


## `EW-9` option A: warn on non-kbm input and change NOTHING else. The strip appears and
## disappears; the token column, the minimum target and the four regions are identical
## either way, because a warning that grew targets or reflowed would be the second
## responsive state `[CEUI-5]` removed, reintroduced under another name.
func set_input_mode(mode: String) -> void:
	_shell.set_input_mode(mode)
	_refresh_input_warning()


func _refresh_input_warning() -> void:
	var warning := _shell.input_mode_warning()
	_input_warning.visible = bool(warning["active"])
	_input_warning_label.text = String(warning["message"])


# ---- chrome ----


## `[CEUI-S50]`'s editor-only token column with `[CEUI-S1]`'s font size applied, from
## `EditorLocalSettings.tokens()`.
##
## That object reads the column STATICALLY rather than from the `ResponsiveLayout`
## autoload's current mode, and the reason is recorded there: the autoload's `menu_mode` is
## one global value, so a shell that called `set_menu_mode(MENU_MODE_EDITOR)` in `_ready()`
## would flip the density of every game screen with it and leave it flipped when the editor
## closed.
func _apply_density_tokens() -> void:
	var tokens := _settings.tokens()
	_tree_pane.custom_minimum_size.x = float(tokens.get("tree_width", 280.0))
	_inspector.custom_minimum_size.x = float(tokens.get("inspector_width", 380.0))
	_status_bar.custom_minimum_size.y = float(tokens.get("footer", 22.0))
	_header.custom_minimum_size.y = float(tokens.get("header", 44.0))
	_workspace_bar.custom_minimum_size.y = float(tokens.get("workspace_bar", 34.0))
	_tabs.custom_minimum_size.y = float(tokens.get("tab_height", 28.0))
	_bottom_panel.custom_minimum_size.y = BOTTOM_PANEL_HEIGHT


## `[CEUI-S2]`: below the floor the shell is replaced, not reflowed. The same measurement
## feeds `EW-4`'s panel default, so both are published from here rather than measured twice.
func _apply_viewport_floor() -> void:
	var effective := effective_viewport_size()
	var below := MetricsScript.is_below_floor(effective)
	_shell_root.visible = not below
	_minimum_size_state.visible = below
	if below:
		_minimum_size_label.text = MetricsScript.minimum_size_message(effective)
	_publish_metrics(effective)


## The centre column's effective width, which is what `EW-7`'s split threshold measures --
## not the window's. The two docks are fixed-width by `[CEUI-S50]`'s token column, so the
## centre is what is left after them, and an author on a wide window with a wide tree does
## not get offered a split the centre cannot hold.
func _publish_metrics(effective: Vector2) -> void:
	var tokens := _settings.tokens()
	var centre := (
		effective.x
		- float(tokens.get("tree_width", 280.0))
		- float(tokens.get("inspector_width", 380.0))
	)
	_shell.workspaces().set_metrics(max(centre, 0.0), effective.y)


## Window size divided by editor scale, which is what `[CEUI-S2]` measures.
func effective_viewport_size() -> Vector2:
	var viewport := get_viewport()
	if viewport == null:
		return Vector2.ZERO
	return MetricsScript.effective_size(viewport.get_visible_rect().size, _settings.editor_scale)


## Sets the scale WITHOUT `EW-1`'s warning. Kept because a caller that already knows the
## value is safe -- a test, or a restore of a value the author confirmed once -- should not
## have to stand up a dialog. `request_editor_scale()` is the author-facing path.
func set_editor_scale(scale: float) -> void:
	if not _settings.set_editor_scale(scale):
		return


## `[CEUI-S1]`'s settings object. Exposed rather than mirrored: a screen that copied the
## four values would be a second place they can disagree, and the settings have no owner
## other than this one.
func editor_settings() -> EditorLocalSettings:
	return _settings


## The author-facing scale path, carrying `EW-1`'s ruling: nothing bounds how far DOWN the
## knob may go, so the value is APPLIED, and below `DPR x scale = 1.0` it is put behind the
## confirm-or-revert `[CEUI-S1]` inherits from `[UUI-18]`. Keeping it persists; reverting
## restores the previous value and never wrote anything.
##
## Returns the `begin_scale_change` report so a caller can see whether a dialog was raised
## without reaching into the settings object for it.
func request_editor_scale(scale: float, device_pixel_ratio: float = -1.0) -> Dictionary:
	var dpr := device_pixel_ratio if device_pixel_ratio > 0.0 else _device_pixel_ratio()
	var report := _settings.begin_scale_change(scale, dpr)
	if not bool(report.get("applied", false)):
		return report
	if not bool(report.get("needs_confirmation", false)):
		_settings.save_to()
		return report
	var dialog: CanvasLayer = ConfirmDialogScript.new()
	add_child(dialog)
	dialog.kept.connect(func() -> void: _settings.confirm_scale_change())
	dialog.reverted.connect(func() -> void: _settings.revert_scale_change())
	dialog.start()
	return report


## `EW-1` states its threshold as `DPR x scale`, and the project's device pixel ratio is
## `SettingsManager.content_scale_factor` -- the same number `ResponsiveLayout` divides the
## backing size by. READ, never written: the editor does not touch the player's settings
## (`[CEUI-S1]`), and reading one to evaluate a threshold is not touching it.
func _device_pixel_ratio() -> float:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null:
		return 1.0
	var factor := float(settings.get("content_scale_factor"))
	return factor if factor > 0.0 else 1.0


func _on_editor_settings_changed() -> void:
	_apply_editor_settings()
	editor_settings_changed.emit()


## The one place the four settings reach the shell. Scale and font size have surfaces here;
## `info_density` and `reduced_motion` are carried and published but change nothing yet, and
## that is deliberate rather than unfinished -- no editor surface animates, and `EW-6` fixes
## what the status bar carries, so neither has a ruled surface to vary. Inventing one here
## would be this build asserting UI the `CEUI` walk did not rule.
func _apply_editor_settings() -> void:
	_apply_font_size()
	_apply_density_tokens()
	_apply_viewport_floor()
	_refresh_workspaces()


func _apply_font_size() -> void:
	if _editor_theme == null:
		_editor_theme = Theme.new()
	_editor_theme.default_font_size = int(round(_settings.font_size))
	_shell_root.theme = _editor_theme
	_minimum_size_state.theme = _editor_theme


## `[CEUI-S3]` point 4: which context owns the keyboard has to be STATED, because the
## arbitration question exists precisely when focus is somewhere unexpected.
func set_keyboard_owner(owner_label: String) -> void:
	_keyboard_owner = owner_label
	_update_status_bar()


func _on_viewport_resized() -> void:
	_apply_viewport_floor()
	_refresh_workspaces()


## `EW-6`'s status bar, carrying the four pieces of state that belong in none of
## `[CEUI-S11]`'s header slots: the active working copy, the keyboard owner, the standing
## validation freshness, and the selection count. Each is its own label so a translation
## that lengthens one does not push the others out of a single formatted line.
func _update_status_bar() -> void:
	var state := _shell.status_bar_state(_keyboard_owner)
	_status_working_copy.text = (
		"No working copy" if String(state["working_copy"]) == "" else String(state["working_copy"])
	)
	_status_keyboard.text = "Keyboard: %s" % String(state["keyboard_owner"])
	_status_validation.text = String(state["validation"])
	_status_selection.text = "%d selected" % int(state["selection_count"])
