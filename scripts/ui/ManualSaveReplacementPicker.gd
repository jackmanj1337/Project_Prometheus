extends RefCounted
# Shared model/view adapter for choosing an existing manual campaign slot when
# the active between-map pool is full. Automatic slots are never candidates.

const PICKER_NAME := "ManualSaveReplacementOptions"


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
		picker = OptionButton.new()
		picker.name = PICKER_NAME
		picker.custom_minimum_size = Vector2(520, 44)
		picker.position = Vector2(16, 70)
		dialog.add_child(picker)
		dialog.min_size = Vector2i(552, 180)
	picker.clear()
	for row in rows:
		picker.add_item(describe(row))
		picker.set_item_metadata(picker.item_count - 1, String(row.get("slot_id", "")))
	picker.select(0)
	picker.visible = not rows.is_empty()
	dialog.dialog_text = "Choose a manual campaign save to replace. The oldest is selected by default."


static func selected_slot(dialog: ConfirmationDialog) -> String:
	var picker := dialog.get_node_or_null(PICKER_NAME) as OptionButton
	if picker == null or picker.item_count == 0 or picker.selected < 0:
		return ""
	return String(picker.get_item_metadata(picker.selected))


static func describe(row: Dictionary) -> String:
	var header: Dictionary = row.get("header", {}) if row.get("header") is Dictionary else {}
	var location := String(header.get("node_id", header.get("map_id", "Campaign Map")))
	return (
		"%s | %s/%s | %s | %s"
		% [
			String(row.get("label", row.get("slot_id", "Save"))),
			String(header.get("package_id", "built-in")),
			String(header.get("campaign_id", "campaign")),
			location,
			Time.get_datetime_string_from_unix_time(int(row.get("saved_at_unix", 0)), true),
		]
	)
