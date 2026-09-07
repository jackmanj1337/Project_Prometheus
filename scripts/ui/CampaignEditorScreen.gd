extends Control
# `[CEUI-1]`'s editor shell, slice 1: the generated content tree and the derived map layer
# list. The renderer for `CampaignEditorShell`, which owns every decision this file draws.
#
# WHAT SLICE 1 IS AND IS NOT. The four regions `CEUI-1` resolved to -- tree, centre
# workspace, Inspector, collapsible bottom panel -- exist here so the tree has somewhere
# ruled to live, and the centre, Inspector and bottom panel are EMPTY. They fill in with
# the document model (`[CEUI-3]`'s tabs, `[CEUI-S14]`'s schema-generated forms) and
# `[CEUI-S26]`'s issues panel, none of which this row owns. The seven workspaces
# (`[CEUI-8]`, `[CEUI-S12]`) are likewise not routed yet, which is why the layer list is
# its own region rather than something the Maps workspace reveals: routing it by the
# focused category would mean naming a content family here, and `[CEUI-S21]` is precisely
# the ruling against that.
#
# THIS FILE CONTAINS NO CONTENT FAMILY AND NO LAYER NAME. Every label it draws came from
# the descriptor, through the shell. If a future edit needs to branch on which category is
# focused, the branch belongs in declared metadata, not in a `match` here.
#
# `[CEUI-S2]`/`CEUI-5`: BELOW THE FLOOR, A MINIMUM-SIZE STATE, NEVER A COMPACT EDITOR. The
# floor is `1920 x 880` EFFECTIVE -- window size divided by editor scale -- and the ruling
# is that shrinking below it produces a message, not a rearrangement. Slice 1 honours it
# because a shell that quietly reflowed at 1280 would have to be un-taught later, and
# because the state is one label today and a design decision forever after.

const ShellScript = preload("res://scripts/editor/CampaignEditorShell.gd")
const ResponsiveLayoutScript = preload("res://scripts/autoloads/ResponsiveLayout.gd")

## `[CEUI-S2]`. Effective, not physical: a 3840-wide window at editor scale 2.0 is 1920.
const VIEWPORT_FLOOR := Vector2(1920, 880)

## Tree columns for the layer list. Visibility and lock are `CEUI-23` option A's two
## per-layer controls; they are columns rather than an inspector because the author toggles
## them while looking at the canvas, not while looking at a form.
const LAYER_COLUMN_NAME := 0
const LAYER_COLUMN_VISIBLE := 1
const LAYER_COLUMN_LOCKED := 2

signal category_focused(category_id: String)
signal layer_focused(layer_id: String)
## Emitted when a locked layer refuses activation, carrying the reason. `[EPUX-07]`: the
## refusal has to be reachable by someone standing on the entry, so it leaves this screen
## rather than being swallowed. `EW-6`'s status bar shows it.
signal layer_activation_refused(layer_id: String, reason: String)

@onready var _shell_root: Control = $Shell
@onready var _minimum_size_state: Control = $MinimumSizeState
@onready var _minimum_size_label: Label = $MinimumSizeState/Message
@onready var _content_tree: Tree = $Shell/Body/TreePane/ContentTree
@onready var _layer_tree: Tree = $Shell/Body/TreePane/LayerList
@onready var _tree_pane: Control = $Shell/Body/TreePane
@onready var _inspector: Control = $Shell/Body/Workspace/Inspector
@onready var _status_bar: Label = $Shell/StatusBar

var _shell := ShellScript.new()
## Editor scale is an editor-local setting (`[CEUI-S1]`) that does not exist yet. Held as a
## field rather than read from a settings key so the floor check is already written against
## the effective size the ruling names, and the setting wires into one place when it lands.
var _editor_scale: float = 1.0
# category id -> TreeItem, so a focus change repaints without rebuilding the tree. A
# rebuild would drop the author's expanded groups, which is the state-loss shape
# `RecordSelector` was careful about one level down.
var _category_items: Dictionary = {}
var _layer_items: Dictionary = {}
# Set while a rebuild writes check states, so `item_edited` does not read its own writes
# back into the shell.
var _applying := false


func _ready() -> void:
	_content_tree.item_selected.connect(_on_category_selected)
	_layer_tree.item_selected.connect(_on_layer_selected)
	_layer_tree.item_activated.connect(_on_layer_activated)
	_layer_tree.item_edited.connect(_on_layer_edited)
	get_viewport().size_changed.connect(_on_viewport_resized)
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


## Repaints both trees from the shell. Does not re-derive: the shell is the authority on
## what exists, and a screen that re-derived on every repaint would fight whatever set the
## shell up.
func rebuild() -> void:
	_build_content_tree()
	_build_layer_tree()
	_sync_content_focus()
	_sync_layer_focus()
	_apply_density_tokens()
	_apply_viewport_floor()
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
		_status_bar.text = String(outcome["reason"])
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


## `[CEUI-S2]`: below the floor the shell is replaced, not reflowed.
func _apply_viewport_floor() -> void:
	var effective := effective_viewport_size()
	var below := effective.x < VIEWPORT_FLOOR.x or effective.y < VIEWPORT_FLOOR.y
	_shell_root.visible = not below
	_minimum_size_state.visible = below
	if below:
		_minimum_size_label.text = (
			"The campaign editor needs at least %d x %d.\nThis window is %d x %d."
			% [
				int(VIEWPORT_FLOOR.x),
				int(VIEWPORT_FLOOR.y),
				int(effective.x),
				int(effective.y),
			]
		)


## Window size divided by editor scale, which is what `[CEUI-S2]` measures.
func effective_viewport_size() -> Vector2:
	var viewport := get_viewport()
	if viewport == null or _editor_scale <= 0.0:
		return Vector2.ZERO
	return viewport.get_visible_rect().size / _editor_scale


func set_editor_scale(scale: float) -> void:
	if scale <= 0.0:
		return
	_editor_scale = scale
	_apply_viewport_floor()


func _on_viewport_resized() -> void:
	_apply_viewport_floor()


## `EW-6`'s status bar, carrying the two states slice 1 actually has: what owns the
## keyboard and how much is selected. Validation freshness and the active tool arrive with
## the rows that own them.
func _update_status_bar() -> void:
	var category := _shell.focused_category()
	var layer_id := _shell.layer_selector().focused_id()
	_status_bar.text = (
		"%s  |  Layer: %s  |  %d selected"
		% [
			String(category.get("label", "No selection")),
			layer_id if layer_id != "" else "none",
			_shell.content_selector().selected_ids().size(),
		]
	)
