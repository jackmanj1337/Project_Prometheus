extends "res://scripts/ui/ModalScreen.gd"
# Load Game: lists the written campaign slots and loads or deletes one. An overlay
# child of MainMenu (open()/hide(), no scene change) like NewGameScreen and
# SettingsScreen; extends ModalScreen (B3) for hide-on-ready and cancel-to-close.
#
# This screen does NOT restore a save itself. It emits slot_load_requested and
# MainMenu runs its existing _load_campaign_slot path, so the restore (GameState
# staging -> CampaignManager launch, plus the failure dialog) lives in one place.
#
# Rows come from SaveManager.list_slots(), which mirrors each save's header into
# the index at write time — so drawing the list never opens or validates N save
# files. The rows arrive newest-first already; do not re-sort them (they order by
# a monotonic write_seq, because saved_at_unix ties at whole-second resolution).
#
# Manual save is NOT here: writing a slot is a between-map action and belongs to
# the prep screen (B4-PREP-DEPLOYMENT). This screen only reads.
#
# Expected scene structure (see LoadGameScreen.tscn):
#   LoadGameScreen (Control, full-rect anchor, visible = false)
#     Dimmer
#     Panel
#       VBox
#         TitleLabel "Load Game"
#         EmptyLabel     # shown only when there are no slots
#         Scroll (ScrollContainer)
#           Rows (VBoxContainer)   # one Row_<slot_id> HBox per slot, built at open()
#         HSep
#         BtnBack

signal back_pressed()
signal slot_load_requested(slot_id: String)
# Emitted after a delete so MainMenu can re-evaluate Continue/Load, which may have
# pointed at the slot that just went away.
signal slots_changed()

const SaveManagerScript = preload("res://scripts/autoloads/SaveManager.gd")

@onready var _rows: VBoxContainer = $Panel/VBox/Scroll/Rows
@onready var _scroll: ScrollContainer = $Panel/VBox/Scroll
@onready var _empty_label: Label = $Panel/VBox/EmptyLabel
@onready var _btn_back: Button = $Panel/VBox/BtnBack

# Slot ids in display order — the picker's model, kept so callers (and tests) can
# read the order without walking the row nodes.
var _slot_ids: Array[String] = []


func _ready() -> void:
	_btn_back.pressed.connect(_on_back)
	super._ready()


func open() -> void:
	_rebuild_rows()
	show()
	_grab_default_focus()


# The rows list is the whole state of this screen, so it is rebuilt from disk on
# every open and after every delete rather than patched in place.
func _rebuild_rows() -> void:
	for child in _rows.get_children():
		child.queue_free()
		_rows.remove_child(child)
	_slot_ids.clear()
	for row in _list_slots():
		var slot_id := String(row.get("slot_id", ""))
		if slot_id == "":
			continue
		_slot_ids.append(slot_id)
		_rows.add_child(_make_row(slot_id, row))
	_empty_label.visible = _slot_ids.is_empty()
	_scroll.visible = not _slot_ids.is_empty()


func _make_row(slot_id: String, row: Dictionary) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.name = "Row_%s" % slot_id

	var load_btn := Button.new()
	load_btn.name = "LoadButton"
	load_btn.text = _row_text(slot_id, row)
	load_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	load_btn.pressed.connect(_on_slot_activated.bind(slot_id))
	box.add_child(load_btn)

	var delete_btn := Button.new()
	delete_btn.name = "DeleteButton"
	delete_btn.text = "Delete"
	delete_btn.pressed.connect(_on_delete_pressed.bind(slot_id))
	box.add_child(delete_btn)
	return box


# One row: what the save is, then how far along and when it was written. Every
# field comes from the index row's mirrored header — no save file is opened here.
func _row_text(slot_id: String, row: Dictionary) -> String:
	var header: Dictionary = row.get("header", {}) if row.get("header") is Dictionary else {}
	var party: Dictionary = header.get("party", {}) if header.get("party") is Dictionary else {}
	var title := String(row.get("label", ""))
	if title == "":
		title = slot_id
	# The autosave is a normal row, but the player must be able to tell it apart from
	# a slot they wrote themselves — it is the one that gets overwritten under them.
	if slot_id == SaveManagerScript.AUTOSAVE_SLOT:
		title = "[Autosave] %s" % title
	var campaign_id := String(header.get("campaign_id", ""))
	var node_id := String(header.get("node_id", ""))
	var position := "%s — %s" % [campaign_id, node_id] if campaign_id != "" else "Single map"
	var detail := "%d units · %dG · %s" % [
		int(party.get("count", 0)),
		int(party.get("gold", 0)),
		_format_timestamp(int(row.get("saved_at_unix", 0))),
	]
	return "%s\n%s\n%s" % [title, position, detail]


# saved_at_unix is a UTC epoch; shift by the system's timezone bias so the player
# sees the wall-clock time they actually saved at.
func _format_timestamp(saved_at_unix: int) -> String:
	if saved_at_unix <= 0:
		return "unknown"
	var bias := int(Time.get_time_zone_from_system().get("bias", 0))
	var dt := Time.get_datetime_dict_from_unix_time(saved_at_unix + bias * 60)
	return "%04d-%02d-%02d %02d:%02d" % [dt["year"], dt["month"], dt["day"],
		dt["hour"], dt["minute"]]


func _on_slot_activated(slot_id: String) -> void:
	# MainMenu owns the restore path (and its failure dialog); this only names the
	# slot. On success it changes scene, so nothing below matters.
	slot_load_requested.emit(slot_id)


# Delete is destructive and sits next to Load on every row, so it confirms first.
func _on_delete_pressed(slot_id: String) -> void:
	var dlg := ConfirmationDialog.new()
	dlg.dialog_text = "Delete this save?\nThis cannot be undone."
	dlg.confirmed.connect(_delete_slot.bind(slot_id))
	# Focus would otherwise be left on a button that no longer exists after a delete.
	dlg.visibility_changed.connect(func():
		if not dlg.visible:
			dlg.queue_free()
			_grab_default_focus())
	add_child(dlg)
	dlg.popup_centered()
	dlg.get_ok_button().grab_focus()


func _delete_slot(slot_id: String) -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null or not save_manager.has_method("delete_slot"):
		return
	if not bool(save_manager.call("delete_slot", slot_id)):
		push_error("LoadGameScreen: failed to delete slot '%s'" % slot_id)
		return
	_rebuild_rows()
	# delete_slot already clears the Continue pointer when it named this slot;
	# MainMenu still has to redraw the buttons that read it.
	slots_changed.emit()


func _list_slots() -> Array[Dictionary]:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null or not save_manager.has_method("list_slots"):
		return []
	return save_manager.call("list_slots")


# Slot ids in display order (newest first). The picker's model, exposed for MainMenu
# and the tests rather than making them walk row nodes.
func get_slot_ids() -> Array[String]:
	return _slot_ids.duplicate()


# Focus lands on the newest save — the one a player reaching for Load almost always
# wants. With no rows there is only Back.
func _focus_default() -> Control:
	if _rows != null and _rows.get_child_count() > 0:
		var first := _rows.get_child(0).get_node_or_null("LoadButton") as Control
		if first != null:
			return first
	return _btn_back


func _focus_scroll_container() -> ScrollContainer:
	return _scroll


func _on_back() -> void:
	_close()


func _close() -> void:
	# Subclass override: emit back_pressed (consumed by MainMenu) in addition to
	# ModalScreen.closed.
	back_pressed.emit()
	super._close()
