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
# files. Package/campaign groups retain first-seen order, and rows within each
# group retain the index's newest-first write_seq order.
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

signal back_pressed
signal slot_load_requested(slot_id: String)
# Emitted after a delete so MainMenu can re-evaluate Continue/Load, which may have
# pointed at the slot that just went away.
signal slots_changed
# A disabled save's only fix is installing its campaign package, so the row's
# Manage Campaigns action asks MainMenu to open the library — this screen does
# not own campaign installation and must not grow a second entry point to it.
signal manage_campaigns_requested

const Transfer = preload("res://scripts/resources/TransferFileService.gd")
const ImportBudgets = preload("res://scripts/resources/ImportBudgets.gd")
const CampaignPackRegistry = preload("res://scripts/resources/CampaignPackRegistry.gd")
const SaveRecovery = preload("res://scripts/save/SaveRecovery.gd")

@onready var _rows: VBoxContainer = $Panel/VBox/Scroll/Rows
@onready var _scroll: ScrollContainer = $Panel/VBox/Scroll
@onready var _empty_label: Label = $Panel/VBox/EmptyLabel
@onready var _btn_back: Button = $Panel/VBox/BtnBack
@onready var _btn_import: Button = $Panel/VBox/BtnImport
@onready var _import_dialog: FileDialog = $ImportDialog
@onready var _export_dialog: FileDialog = $ExportDialog
@onready var _transfer_result: AcceptDialog = $TransferResult
@onready var _tamper_warning: ConfirmationDialog = $TamperWarning
@onready var _migration_preview: ConfirmationDialog = $MigrationPreview

# Slot ids in display order — the picker's model, kept so callers (and tests) can
# read the order without walking the row nodes.
var _slot_ids: Array[String] = []
var _export_slot_id := ""
var _pending_import_path := ""
var _pending_import_slot := ""
var _pending_migration: Dictionary = {}


func _ready() -> void:
	_btn_back.pressed.connect(_on_back)
	_btn_import.pressed.connect(_on_import_pressed)
	_import_dialog.file_selected.connect(_on_import_file_selected)
	_export_dialog.file_selected.connect(_on_export_file_selected)
	_tamper_warning.confirmed.connect(_on_tamper_acknowledged)
	_migration_preview.confirmed.connect(_on_migration_confirmed)
	super._ready()


func open() -> void:
	_rebuild_rows()
	show()
	_grab_default_focus()


func suspend_for_child_modal() -> Dictionary:
	var state := {"slot_id": "", "action": "", "scroll": _scroll.scroll_vertical}
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and is_ancestor_of(focused):
		state["action"] = focused.name
		var row := focused.get_parent()
		if row != null and String(row.name).begins_with("Row_"):
			state["slot_id"] = String(row.name).trim_prefix("Row_")
	hide()
	return state


func resume_from_child_modal(state: Dictionary) -> void:
	_rebuild_rows()
	show()
	_scroll.set_deferred("scroll_vertical", int(state.get("scroll", 0)))
	var row_name := "Row_%s" % String(state.get("slot_id", ""))
	for row in _rows.get_children():
		if String(row.name) != row_name:
			continue
		var action := row.get_node_or_null(String(state.get("action", ""))) as Control
		if (
			action != null
			and action.is_visible_in_tree()
			and action.focus_mode != Control.FOCUS_NONE
		):
			action.grab_focus()
			return
	_grab_default_focus()


# The rows list is the whole state of this screen, so it is rebuilt from disk on
# every open and after every delete rather than patched in place.
func _rebuild_rows() -> void:
	for child in _rows.get_children():
		child.queue_free()
		_rows.remove_child(child)
	_slot_ids.clear()
	for group in group_rows_by_source(_list_slots()):
		var heading := Label.new()
		heading.name = "SaveGroupLabel"
		heading.text = String(group.get("label", ""))
		heading.add_theme_font_size_override("font_size", 18)
		_rows.add_child(heading)
		for row in group.get("rows", []):
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
	var header: Dictionary = row.get("header", {}) if row.get("header") is Dictionary else {}
	var recovery := recovery_diagnostic(row)
	var completed := String(header.get("campaign_state", "in_progress")) == "completed"
	load_btn.disabled = completed or not recovery.is_empty()
	if not recovery.is_empty():
		load_btn.tooltip_text = SaveRecovery.summary(recovery)
	elif completed:
		load_btn.tooltip_text = "Campaign completed — retained as a completion record."
	else:
		load_btn.tooltip_text = ""
	load_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	load_btn.pressed.connect(_on_slot_activated.bind(slot_id))
	box.add_child(load_btn)

	# Recovery actions come before the destructive ones: the row's Load button
	# cannot hold focus while it is disabled, so whatever sits next is what the
	# player lands on — and that must be the fix, never Delete.
	if not recovery.is_empty():
		for action in recovery.get("actions", []):
			var action_id := String(action)
			if action_id == SaveRecovery.ACTION_BACK:
				continue
			var action_btn := Button.new()
			action_btn.name = _action_button_name(action_id)
			action_btn.text = String(SaveRecovery.ACTION_LABELS.get(action_id, action_id))
			if action_id == SaveRecovery.ACTION_RETRY:
				action_btn.tooltip_text = "Check again for this save's campaign package."
				action_btn.pressed.connect(_on_retry_pressed.bind(slot_id))
			else:
				action_btn.tooltip_text = "Install or update campaign packages."
				action_btn.pressed.connect(_on_manage_campaigns_pressed)
			box.add_child(action_btn)

	var delete_btn := Button.new()
	delete_btn.name = "DeleteButton"
	delete_btn.text = "Delete"
	delete_btn.pressed.connect(_on_delete_pressed.bind(slot_id))
	box.add_child(delete_btn)

	var export_btn := Button.new()
	export_btn.name = "ExportButton"
	export_btn.text = "Export"
	export_btn.pressed.connect(_on_export_pressed.bind(slot_id))
	box.add_child(export_btn)

	var migration := _migration_for_header(header)
	if not migration.is_empty():
		var migrate_btn := Button.new()
		migrate_btn.name = "MigrateButton"
		migrate_btn.text = "Import into %s" % migration["summary"]["package_version"]
		migrate_btn.pressed.connect(_on_migrate_pressed.bind(slot_id, migration))
		box.add_child(migrate_btn)
	return box


# Save namespaces are package + campaign, not campaign alone: self-contained
# packs may intentionally reuse the same campaign id. Group ordering follows the
# newest row in each namespace and never opens the underlying save documents.
static func group_rows_by_source(rows: Array[Dictionary]) -> Array[Dictionary]:
	var groups: Array[Dictionary] = []
	var group_indexes: Dictionary = {}
	for row in rows:
		var header: Dictionary = row.get("header", {}) if row.get("header") is Dictionary else {}
		var package_id := String(header.get("package_id", ""))
		var campaign_id := String(header.get("campaign_id", ""))
		var key := JSON.stringify([package_id, campaign_id])
		if not group_indexes.has(key):
			group_indexes[key] = groups.size()
			(
				groups
				. append(
					{
						"package_id": package_id,
						"campaign_id": campaign_id,
						"label": _source_group_label(header),
						"rows": [] as Array[Dictionary],
					}
				)
			)
		groups[int(group_indexes[key])]["rows"].append(row)
	return groups


static func _source_group_label(header: Dictionary) -> String:
	var package_id := String(header.get("package_id", ""))
	var package_version := String(header.get("package_version", ""))
	var campaign_id := String(header.get("campaign_id", ""))
	var package_label := "Legacy / local" if package_id.is_empty() else package_id
	if not package_version.is_empty():
		package_label += " v%s" % package_version
	var campaign_label := "Single map" if campaign_id.is_empty() else campaign_id
	return "%s — %s" % [package_label, campaign_label]


# A row is disabled when its index entry says so, and the recorded diagnostic is
# what the row renders. Rows written before the content state existed carry no
# entry and are ready by omission.
static func recovery_diagnostic(row: Dictionary) -> Dictionary:
	if String(row.get("content_state", SaveRecovery.STATE_READY)) != SaveRecovery.STATE_DISABLED:
		return {}
	var recovery: Variant = row.get("recovery", {})
	if recovery is Dictionary and not recovery.is_empty():
		return recovery
	# The state is authoritative even if the recorded wording was lost; describe
	# the least specific recoverable reason rather than showing a runnable row.
	return SaveRecovery.describe(SaveRecovery.REASON_MISSING, row.get("header", {}))


# Button order within a row, exposed so the focus contract is asserted against a
# list rather than by walking a live scene.
static func row_button_names(row: Dictionary) -> Array[String]:
	var names: Array[String] = ["LoadButton"]
	var recovery := recovery_diagnostic(row)
	for action in recovery.get("actions", []):
		if String(action) == SaveRecovery.ACTION_BACK:
			continue
		names.append(_action_button_name(String(action)))
	names.append("DeleteButton")
	names.append("ExportButton")
	return names


static func _action_button_name(action_id: String) -> String:
	return "%sButton" % action_id.to_pascal_case()


func _on_retry_pressed(slot_id: String) -> void:
	var manager := get_node_or_null("/root/SaveManager")
	if manager == null or not manager.has_method("revalidate_slot"):
		_show_transfer_result("Save recovery is unavailable.")
		return
	var outcome: Dictionary = manager.call("revalidate_slot", slot_id)
	_rebuild_rows()
	slots_changed.emit()
	if bool(outcome.get("ok", false)):
		_show_transfer_result(
			"The campaign package for '%s' is installed. This save can be loaded." % slot_id
		)
		return
	_show_transfer_result(SaveRecovery.message(outcome.get("diagnostic", {})))


func _on_manage_campaigns_pressed() -> void:
	manage_campaigns_requested.emit()


func _migration_for_header(header: Dictionary) -> Dictionary:
	var source_id := String(header.get("package_id", ""))
	var source_version := String(header.get("package_version", ""))
	if source_id.is_empty() or source_version.is_empty():
		return {}
	var registry := CampaignPackRegistry.new(CampaignPackRegistry.DEFAULT_STORAGE_ROOT)
	for summary in registry.refresh():
		if summary["package_id"] != source_id:
			continue
		for declaration in summary.get("save_migrations", []):
			if String(declaration.get("source_package_version", "")) == source_version:
				return {"summary": summary, "declaration": declaration}
	return {}


func _on_migrate_pressed(source_slot_id: String, migration: Dictionary) -> void:
	var manager := get_node_or_null("/root/SaveManager")
	if manager == null:
		return
	var summary: Dictionary = migration["summary"]
	var ids: Dictionary = summary.get("content_ids", {})
	var exists := func(family: String, id: String) -> bool:
		return ids.has(family) and ids[family].has(id)
	var destination_slot := _next_migration_slot_id(manager, source_slot_id)
	var preview: Dictionary = manager.preview_save_migration(
		source_slot_id, String(summary["package_id"]), migration["declaration"], exists
	)
	if not preview.get("ok", false):
		_show_transfer_result(SaveRecovery.migration_message(preview.get("errors", [])))
		return
	_pending_migration = {
		"source_slot_id": source_slot_id,
		"destination_slot_id": destination_slot,
		"destination_package_id": String(summary["package_id"]),
		"declaration": migration["declaration"],
		"destination_exists": exists,
	}
	_migration_preview.dialog_text = _migration_preview_text(
		String(summary["package_version"]), destination_slot, preview
	)
	_migration_preview.popup_centered()


func _migration_preview_text(
	destination_version: String, destination_slot: String, preview: Dictionary
) -> String:
	var mapped: Array = preview.get("mappings", [])
	var unchanged: Array = preview.get("pass_through", [])
	var lines: Array[String] = [
		"Create a migrated copy for version %s?" % destination_version,
		"New slot: %s" % destination_slot,
		"",
		"References renamed: %d" % mapped.size(),
		"References kept unchanged: %d" % unchanged.size(),
	]
	for record in mapped.slice(0, 6):
		lines.append(
			(
				"  %s: %s -> %s"
				% [
					record.get("family", "content"),
					record.get("source", ""),
					record.get("destination", "")
				]
			)
		)
	if mapped.size() > 6:
		lines.append("  ...and %d more" % (mapped.size() - 6))
	lines.append("")
	lines.append("The original save will be preserved.")
	return "\n".join(lines)


func _on_migration_confirmed() -> void:
	if _pending_migration.is_empty():
		return
	var pending := _pending_migration
	_pending_migration = {}
	var manager := get_node_or_null("/root/SaveManager")
	if manager == null:
		return
	var result: Dictionary = manager.migrate_save_into_slot(
		pending["source_slot_id"],
		pending["destination_slot_id"],
		pending["destination_package_id"],
		pending["declaration"],
		pending["destination_exists"]
	)
	if not result.get("ok", false):
		_show_transfer_result(SaveRecovery.migration_message(result.get("errors", [])))
		return
	_rebuild_rows()
	slots_changed.emit()
	_show_transfer_result(
		"Migrated a copy as '%s'. The original was preserved." % pending["destination_slot_id"]
	)


func _next_migration_slot_id(manager: Node, source_slot_id: String) -> String:
	var stem := (source_slot_id + "_migrated").left(60)
	var candidate := stem
	var suffix := 2
	while bool(manager.call("has_slot", candidate)):
		candidate = "%s_%d" % [stem.left(60), suffix]
		suffix += 1
	return candidate


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
	if String(row.get("origin", "manual")) == "auto":
		title = "[Autosave] %s" % title
	if String(header.get("campaign_state", "in_progress")) == "completed":
		title = "[Completed] %s" % title
	var recovery := recovery_diagnostic(row)
	if not recovery.is_empty():
		title = "[Needs campaign] %s" % title
	var campaign_id := String(header.get("campaign_id", ""))
	var node_id := String(header.get("node_id", ""))
	var position: String
	if String(header.get("save_kind", "between_map")) == "mid_map":
		position = "Resume battle — Turn %d" % int(header.get("turn_number", 1))
	elif String(header.get("campaign_state", "in_progress")) == "completed":
		position = "%s — Campaign complete" % campaign_id
	else:
		position = "Continue — %s" % (node_id if node_id != "" else campaign_id)
	if not recovery.is_empty():
		position = String(recovery.get("title", ""))
	var detail := (
		"%d units · %dG · %s"
		% [
			int(party.get("count", 0)),
			int(party.get("gold", 0)),
			_format_timestamp(int(row.get("saved_at_unix", 0))),
		]
	)
	return "%s\n%s\n%s" % [title, position, detail]


# saved_at_unix is a UTC epoch; shift by the system's timezone bias so the player
# sees the wall-clock time they actually saved at.
func _format_timestamp(saved_at_unix: int) -> String:
	if saved_at_unix <= 0:
		return "unknown"
	var bias := int(Time.get_time_zone_from_system().get("bias", 0))
	var dt := Time.get_datetime_dict_from_unix_time(saved_at_unix + bias * 60)
	return (
		"%04d-%02d-%02d %02d:%02d" % [dt["year"], dt["month"], dt["day"], dt["hour"], dt["minute"]]
	)


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
	dlg.visibility_changed.connect(
		func():
			if not dlg.visible:
				dlg.queue_free()
				_grab_default_focus()
	)
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


func _on_export_pressed(slot_id: String) -> void:
	_export_slot_id = slot_id
	Transfer.request_save(_export_dialog, "%s.json" % slot_id, _on_export_file_selected)


func _on_import_pressed() -> void:
	Transfer.request_open(
		_import_dialog,
		".json,application/json",
		ImportBudgets.portable_save_maximum_bytes(),
		_on_import_file_selected,
		_on_import_file_failed
	)


func _on_import_file_failed(message: String, cancelled: bool) -> void:
	if cancelled:
		_btn_import.grab_focus()
		return
	_show_transfer_result(message)


func _on_export_file_selected(path: String) -> void:
	var manager := get_node_or_null("/root/SaveManager")
	if manager == null or not manager.has_method("export_slot"):
		_show_transfer_result("Save export is unavailable.")
		return
	var result: Dictionary = manager.call("export_slot", _export_slot_id, path)
	if not result.get("ok", false):
		_show_transfer_result(_transfer_failure("Export failed", result.get("errors", [])))
		return
	# On web the record was written to a staging path the player cannot reach;
	# deliver() hands it to the browser. No-op on desktop.
	var delivery := Transfer.deliver(path)
	if not delivery["ok"]:
		_show_transfer_result(_transfer_failure("Export failed", delivery["errors"]))
		return
	_show_transfer_result("Exported save '%s'." % _export_slot_id)


func _on_import_file_selected(path: String) -> void:
	var manager := get_node_or_null("/root/SaveManager")
	if manager == null or not manager.has_method("import_portable_save"):
		_show_transfer_result("Save import is unavailable.")
		return
	var slot_id := _next_import_slot_id(manager)
	var result: Dictionary = manager.call("import_portable_save", path, slot_id, false)
	if result.get("requires_acknowledgement", false):
		_pending_import_path = path
		_pending_import_slot = slot_id
		_tamper_warning.dialog_text = "%s\n\nImport anyway?" % "\n\n".join(result["warnings"])
		_tamper_warning.popup_centered()
		_tamper_warning.get_ok_button().grab_focus()
		return
	_finish_import(result, slot_id)


func _on_tamper_acknowledged() -> void:
	var manager := get_node_or_null("/root/SaveManager")
	if manager == null:
		return
	var result: Dictionary = manager.call(
		"import_portable_save", _pending_import_path, _pending_import_slot, true
	)
	_finish_import(result, _pending_import_slot)


func _finish_import(result: Dictionary, slot_id: String) -> void:
	if not result.get("ok", false):
		var diagnostic: Dictionary = result.get("diagnostic", {})
		if not diagnostic.is_empty():
			_show_transfer_result(SaveRecovery.message(diagnostic))
			return
		_show_transfer_result(_transfer_failure("Import failed", result.get("errors", [])))
		return
	_rebuild_rows()
	slots_changed.emit()
	# The save was stored, so this is not an import failure — it is an imported
	# save waiting on a package. Say what was kept before saying what is missing.
	if String(result.get("content_state", SaveRecovery.STATE_READY)) == SaveRecovery.STATE_DISABLED:
		_show_transfer_result(
			(
				"Imported campaign save as '%s'. It cannot be loaded yet.\n\n%s"
				% [slot_id, SaveRecovery.message(result.get("diagnostic", {}))]
			)
		)
		return
	_show_transfer_result("Imported campaign save as '%s'." % slot_id)


func _next_import_slot_id(manager: Node) -> String:
	var suffix := 1
	while manager.call("has_slot", "imported_%02d" % suffix):
		suffix += 1
	return "imported_%02d" % suffix


func _show_transfer_result(message: String) -> void:
	_transfer_result.dialog_text = message
	_transfer_result.popup_centered()
	_transfer_result.get_ok_button().grab_focus()


static func _transfer_failure(prefix: String, errors: Array) -> String:
	return prefix + "." if errors.is_empty() else "%s:\n%s" % [prefix, "\n".join(errors)]


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
# wants. With no rows the answer is Import, not Back: an empty profile reaches this
# screen precisely because importing is the only thing left to do here, and landing
# on Back would step over it.
func _focus_default() -> Control:
	if _slot_ids.is_empty() and _btn_import != null and not _btn_import.disabled:
		return _btn_import
	if _rows != null:
		for child in _rows.get_children():
			var load_button := child.get_node_or_null("LoadButton") as Button
			if load_button == null:
				continue
			if not load_button.disabled:
				return load_button
			# A disabled Load button cannot take focus. A disabled save hands
			# focus to its own first recovery action — never to Delete, and never
			# by silently skipping past the row the player is looking at.
			for action in [SaveRecovery.ACTION_MANAGE_CAMPAIGNS, SaveRecovery.ACTION_RETRY]:
				var action_button := child.get_node_or_null(_action_button_name(action)) as Button
				if action_button != null and not action_button.disabled:
					return action_button
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
