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
# THERE IS STILL NO ENTRY POINT, AND STILL FOR `[CEUI-S13]`/`[CEUI-S22]`'s REASON. The two
# ruled entries -- the main menu and the library's *Edit a copy* -- both open the editor on
# an imported WORKING COPY (`[CEUI-S9]`), and importing one is the pack lifecycle's job,
# not the shell's. Wiring an entry that opened an editor with no working copy would put a
# mode in front of the player that cannot do the thing it is for. `has_working_copy()` is
# what Test and Export are gated on, and it is false until that import exists.
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
const ResponsiveLayoutScript = preload("res://scripts/autoloads/ResponsiveLayout.gd")

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
@onready var _input_warning: Control = $Shell/InputWarning
@onready var _input_warning_label: Label = $Shell/InputWarning/Message

var _shell := ShellScript.new()
## Editor scale is an editor-local setting (`[CEUI-S1]`) that does not exist yet. Held as a
## field rather than read from a settings key so the floor check is already written against
## the effective size the ruling names, and the setting wires into one place when it lands.
var _editor_scale: float = 1.0
## `[CEUI-S3]` point 4 and `EW-6`: which context owns the keyboard. Set by whatever takes
## keyboard ownership; the status bar's job is only to say so.
var _keyboard_owner: String = "Tree"
# category id -> TreeItem, so a focus change repaints without rebuilding the tree. A
# rebuild would drop the author's expanded groups, which is the state-loss shape
# `RecordSelector` was careful about one level down.
var _category_items: Dictionary = {}
var _layer_items: Dictionary = {}
var _issue_items: Dictionary = {}
# Tab strip index -> document id. `TabBar` is index-addressed and the document model is
# id-addressed; keeping the map explicit is what stops an index leaking into the model.
var _tab_ids: Array[String] = []
# Set while a rebuild writes check states or tab selections, so `item_edited` and
# `tab_changed` do not read their own writes back into the shell.
var _applying := false


func _ready() -> void:
	_content_tree.item_selected.connect(_on_category_selected)
	_layer_tree.item_selected.connect(_on_layer_selected)
	_layer_tree.item_activated.connect(_on_layer_activated)
	_layer_tree.item_edited.connect(_on_layer_edited)
	_tabs.tab_changed.connect(_on_tab_changed)
	_tabs.tab_close_pressed.connect(_on_tab_close_pressed)
	_issue_tree.item_activated.connect(_on_issue_activated)
	_shell.documents().opened.connect(func(_id: String) -> void: _refresh_documents())
	_shell.documents().document_dirty_changed.connect(
		func(_id: String, _dirty: bool) -> void: _refresh_documents()
	)
	_shell.issues().entries_changed.connect(_refresh_issues)
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
	rebuild()


## The shell state this screen renders. Exposed because later slices drive the same shell
## -- a second shell per screen is how two surfaces start disagreeing about what is focused.
func shell() -> CampaignEditorShell:
	return _shell


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
	var document := _shell.documents().active()
	_document_placeholder.text = (
		"No document open."
		if document == null
		else (
			"%s\n%d record(s)%s"
			% [
				document.title,
				document.record_ids().size(),
				"  -  unsaved changes" if document.is_dirty() else "",
			]
		)
	)
	_refresh_header()
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


## `[CEUI-S50]`'s editor-only token column, read STATICALLY rather than from the
## `ResponsiveLayout` autoload's current mode.
##
## The autoload's `menu_mode` is one global value, so a shell that called
## `set_menu_mode(MENU_MODE_EDITOR)` in `_ready()` would flip the density of every game
## screen with it, and leave it flipped when the editor closed. The editor's own furniture
## is `MENU_MODE_EDITOR` by construction -- `tree_width` and the other five have no game
## analogue at all -- so asking the table for that column is both correct and free of the
## side effect. `[CEUI-S3]`'s per-viewport context is the mechanism that eventually carries
## an editor mode without a global flip, and it is not this row's to build.
func _apply_density_tokens() -> void:
	var tokens := ResponsiveLayoutScript.tokens_for_mode(ResponsiveLayoutScript.MENU_MODE_EDITOR)
	_tree_pane.custom_minimum_size.x = float(tokens.get("tree_width", 280.0))
	_inspector.custom_minimum_size.x = float(tokens.get("inspector_width", 380.0))
	_status_bar.custom_minimum_size.y = float(tokens.get("footer", 22.0))
	_header.custom_minimum_size.y = float(tokens.get("header", 44.0))
	_workspace_bar.custom_minimum_size.y = float(tokens.get("workspace_bar", 34.0))
	_tabs.custom_minimum_size.y = float(tokens.get("tab_height", 28.0))


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
	var tokens := ResponsiveLayoutScript.tokens_for_mode(ResponsiveLayoutScript.MENU_MODE_EDITOR)
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
	return MetricsScript.effective_size(viewport.get_visible_rect().size, _editor_scale)


func set_editor_scale(scale: float) -> void:
	if scale <= 0.0:
		return
	_editor_scale = scale
	_apply_viewport_floor()
	_refresh_workspaces()


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
