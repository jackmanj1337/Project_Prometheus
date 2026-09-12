extends RefCounted
# Shared model/view adapter for choosing an existing manual campaign slot when
# the active between-map pool is full. Automatic slots are never candidates.

const PICKER_NAME := "ManualSaveReplacementContent/ManualSaveReplacementOptions"


static func eligible_rows(rows: Array, scope: Dictionary) -> Array[Dictionary]:
	var eligible: Array[Dictionary] = []
	for raw in rows:
		if not raw is Dictionary or String(raw.get("origin", "manual")) != "manual":
			continue
		var header: Dictionary = raw.get("header", {}) if raw.get("header") is Dictionary else {}
		if String(header.get("save_kind", "between_map")) != "between_map":
			continue
		if (
			String(header.get("package_id", "")) != String(scope.get("package_id", ""))
			or String(header.get("package_version", "")) != String(scope.get("package_version", ""))
			or String(header.get("campaign_id", "")) != String(scope.get("campaign_id", ""))
		):
			continue
		eligible.append(raw.duplicate(true))
	eligible.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("saved_at_unix", 0)) < int(b.get("saved_at_unix", 0))
	)
	return eligible


static func configure(dialog: ConfirmationDialog, rows: Array[Dictionary]) -> void:
	var picker := dialog.get_node_or_null(PICKER_NAME) as OptionButton
	if picker == null:
		var content := VBoxContainer.new()
		content.name = "ManualSaveReplacementContent"
		content.custom_minimum_size.x = (
			mini(552, int(dialog.get_parent().get_viewport().get_visible_rect().size.x) - 32) - 32
		)
		content.size.x = content.custom_minimum_size.x
		content.add_theme_constant_override("separation", 12)
		dialog.add_child(content)
		dialog.size_changed.connect(_centre.bind(dialog), CONNECT_DEFERRED)
		var prompt := Label.new()
		prompt.text = "Choose a manual campaign save to replace. The oldest is selected by default."
		prompt.size.x = content.size.x
		prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(prompt)
		picker = OptionButton.new()
		picker.name = "ManualSaveReplacementOptions"
		picker.custom_minimum_size.y = 44
		picker.fit_to_longest_item = false
		picker.clip_text = true
		content.add_child(picker)
		var detail := Label.new()
		detail.name = "SelectedSave"
		detail.size.x = content.size.x
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(detail)
		picker.item_selected.connect(
			func(index: int) -> void: detail.text = picker.get_popup().get_item_tooltip(index)
		)
	picker.clear()
	for row in rows:
		var description := describe(row)
		var text := description
		var available := (
			mini(552, int(dialog.get_parent().get_viewport().get_visible_rect().size.x) - 32) - 64
		)
		var font := picker.get_theme_font("font")
		var font_size := picker.get_theme_font_size("font_size")
		while (
			text.length() > 1
			and (
				font.get_string_size(text + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
				> available
			)
		):
			text = text.left(text.length() - 1)
		picker.add_item(text + "…" if text != description else text)
		picker.get_popup().set_item_tooltip(picker.item_count - 1, description)
		picker.set_item_metadata(picker.item_count - 1, String(row.get("slot_id", "")))
	if not rows.is_empty():
		picker.select(0)
	picker.visible = not rows.is_empty()
	var detail := picker.get_parent().get_node("SelectedSave") as Label
	detail.text = (
		picker.get_popup().get_item_tooltip(0) if not rows.is_empty() else "No saves available."
	)
	var confirm := dialog.get_ok_button()
	confirm.disabled = rows.is_empty()
	confirm.focus_mode = Control.FOCUS_ALL
	confirm.tooltip_text = detail.text if rows.is_empty() else ""
	dialog.dialog_text = ""


# Bound text before opening, then size and centre after the content containers
# have measured. The first open uses the same geometry as every later open.
static func popup(dialog: ConfirmationDialog) -> void:
	var viewport := dialog.get_parent().get_viewport()
	var width := mini(552, int(viewport.get_visible_rect().size.x) - 32)
	dialog.min_size = Vector2i(width, 0)
	var content := dialog.get_node("ManualSaveReplacementContent") as VBoxContainer
	content.custom_minimum_size.x = width - 32
	content.size.x = width - 32
	for child in content.get_children():
		if child is Control:
			child.size.x = width - 32
	content.queue_sort()
	await dialog.get_tree().process_frame
	if (
		not is_instance_valid(dialog)
		or not dialog.is_inside_tree()
		or dialog.is_queued_for_deletion()
	):
		return
	dialog.reset_size()
	dialog.popup_centered()


# Text wrapping may refine height after the first container sort. Follow that
# measurement without reopening the dialog or taking focus a second time.
static func _centre(dialog: ConfirmationDialog) -> void:
	if not dialog.visible:
		return
	var parent_window := dialog.get_parent().get_window()
	if dialog.is_embedded():
		dialog.position = Vector2i(
			(parent_window.get_visible_rect().size - Vector2(dialog.size)) / 2
		)
	else:
		dialog.position = parent_window.position + (parent_window.size - dialog.size) / 2


static func selected_slot(dialog: ConfirmationDialog) -> String:
	var picker := dialog.get_node_or_null(PICKER_NAME) as OptionButton
	if picker == null or picker.item_count == 0 or picker.selected < 0:
		return ""
	return String(picker.get_item_metadata(picker.selected))


static func describe(row: Dictionary) -> String:
	var header: Dictionary = row.get("header", {}) if row.get("header") is Dictionary else {}
	var location := String(header.get("node_id", header.get("map_id", "Campaign Map")))
	return (
		"%s | %s | %s"
		% [
			String(row.get("label", row.get("slot_id", "Save"))),
			location,
			Time.get_datetime_string_from_unix_time(int(row.get("saved_at_unix", 0)), true),
		]
	)
