extends Control
# Responsive campaign-graph surface. CampaignManager remains the sole authority
# for availability, cadence evaluation, and entry into prep.

@onready var _margin: MarginContainer = $Margin
@onready var _nodes: VBoxContainer = $Margin/VBox/Canvas/Nodes
@onready var _status: Label = $Margin/VBox/Status
@onready var _zoom_label: Label = $Margin/VBox/Toolbar/ZoomLabel
@onready var _save_button: Button = $Margin/VBox/Toolbar/SaveButton
@onready var _settings_button: Button = $Margin/VBox/Toolbar/SettingsButton
@onready var _overwrite_confirm: ConfirmationDialog = $OverwriteConfirm

var _zoom := 1.0
var _settings_screen: Control = null
var _pending_overwrite_slot_id := ""
const ManualSaveReplacementPicker = preload("res://scripts/ui/ManualSaveReplacementPicker.gd")


func _ready() -> void:
	_save_button.pressed.connect(_on_save)
	_settings_button.pressed.connect(_on_settings)
	$Margin/VBox/Toolbar/ZoomOut.pressed.connect(_change_zoom.bind(-0.1))
	$Margin/VBox/Toolbar/ZoomIn.pressed.connect(_change_zoom.bind(0.1))
	_overwrite_confirm.confirmed.connect(_on_overwrite_confirmed)
	_zoom_label.text = "%d%%" % roundi(_zoom * 100.0)
	var responsive := get_node_or_null("/root/ResponsiveLayout")
	if responsive != null and responsive.has_signal("size_class_changed"):
		responsive.size_class_changed.connect(_on_size_class_changed)
		_apply_size_class(String(responsive.get("size_class")))
	else:
		_apply_size_class("expanded")
	_rebuild()


func _unhandled_input(event: InputEvent) -> void:
	# Settings owns cancel while open. On the map itself, cancel deliberately does
	# nothing: leaving a live campaign must be an explicit main-menu action.
	if event.is_action_pressed("open_settings") and not _settings_is_open():
		_on_settings()
		get_viewport().set_input_as_handled()


func _rebuild() -> void:
	for child in _nodes.get_children():
		child.queue_free()
		_nodes.remove_child(child)
	var cm := get_node_or_null("/root/CampaignManager")
	if cm == null or not bool(cm.call("uses_overworld")):
		_status.text = "No overworld campaign is active."
		return
	var first_available: Button = null
	var first_entry: Button = null
	for row in cm.call("get_overworld_nodes"):
		var button := Button.new()
		button.name = "Node_%s" % String(row.get("node_id", ""))
		button.text = _node_label(row)
		button.disabled = not bool(row.get("available", false))
		button.custom_minimum_size = Vector2(280.0 * _zoom, 48.0 * _zoom)
		# [EPUX-07] / [RPD-15]: a gated entry stays in the focus order so its reason
		# is reachable without a pointer. Godot 4.6.3 already focuses a disabled
		# BaseButton and refuses to activate it, and this screen is a plain
		# VBoxContainer, so native traversal covers it -- what the entry still needs
		# is somewhere for the reason to GO. tooltip_text is the carrier the rest of
		# the shell uses (MainMenu's no-pack state), and _announce_focused mirrors it
		# into the status line so keyboard and controller reach it too. The screen
		# reader channel is SHELL-UNMET-REASON-ANNOUNCEMENT-CHANNEL-2026-08-19.
		button.tooltip_text = String(row.get("unavailable_reason", ""))
		button.focus_entered.connect(_announce_focused.bind(button))
		button.pressed.connect(_on_node_pressed.bind(String(row.get("node_id", ""))))
		_nodes.add_child(button)
		if first_entry == null:
			first_entry = button
		if first_available == null and not button.disabled:
			first_available = button
	# Entry focus prefers an available entry and falls back to a gated one only when
	# every entry is gated, so a fully gated surface is never unreachable. Same split
	# the shell uses; traversal order (above) and entry focus are different rules.
	var entry_focus: Button = first_available if first_available != null else first_entry
	if entry_focus != null:
		entry_focus.call_deferred("grab_focus")
	_status.text = _default_status()


func _default_status() -> String:
	return "Choose the next destination or revisit a cleared hub."


# The focused entry's reason, or the standing instruction when it is available.
func _announce_focused(button: Button) -> void:
	_status.text = button.tooltip_text if button.disabled else _default_status()


func _node_label(row: Dictionary) -> String:
	var suffix := ""
	if bool(row.get("current", false)):
		suffix = "  • Next"
	elif bool(row.get("cleared", false)):
		suffix = "  ✓ Cleared"
	return String(row.get("label", row.get("node_id", ""))) + suffix


func _on_node_pressed(node_id: String) -> void:
	var cm := get_node_or_null("/root/CampaignManager")
	if cm == null or not bool(cm.call("enter_overworld_node", node_id)):
		_status.text = "That destination is unavailable."


func _on_save() -> void:
	var label := _manual_save_label()
	var existing_id := _same_label_slot_id(label)
	if existing_id != "":
		_pending_overwrite_slot_id = existing_id
		_overwrite_confirm.popup_centered()
		return
	_write_manual_save("")


func _on_overwrite_confirmed() -> void:
	var old_slot_id := _pending_overwrite_slot_id
	if old_slot_id == "__picker__":
		old_slot_id = ManualSaveReplacementPicker.selected_slot(_overwrite_confirm)
	_pending_overwrite_slot_id = ""
	_write_manual_save(old_slot_id)


func _write_manual_save(old_slot_id: String) -> void:
	var cm := get_node_or_null("/root/CampaignManager")
	var sm := get_node_or_null("/root/SaveManager")
	if cm == null or sm == null:
		_status.text = "Save failed."
		return
	if old_slot_id == "" and sm.has_method("manual_slot_budget"):
		var budget: Dictionary = sm.call("manual_slot_budget", "between_map")
		if bool(budget.get("full", false)):
			var rows := ManualSaveReplacementPicker.eligible_rows(
				sm.call("list_slots"), budget.get("scope", {})
			)
			ManualSaveReplacementPicker.configure(_overwrite_confirm, rows)
			_pending_overwrite_slot_id = "__picker__"
			_overwrite_confirm.popup_centered()
			return
	var slot_id := old_slot_id if old_slot_id != "" else _next_manual_slot_id()
	_status.text = (
		"Saved."
		if bool(cm.call("write_campaign_slot", slot_id, _manual_save_label()))
		else "Save failed."
	)


func _manual_save_label() -> String:
	var cm := get_node_or_null("/root/CampaignManager")
	var node: CampaignNode = cm.call("get_current_node") if cm != null else null
	var position := node.label if node != null and node.label != "" else "Campaign Map"
	return "%s — Campaign Map" % position


func _same_label_slot_id(label: String) -> String:
	var sm := get_node_or_null("/root/SaveManager")
	if sm == null or not sm.has_method("list_slots"):
		return ""
	var budget: Dictionary = sm.call("manual_slot_budget", "between_map")
	for row in ManualSaveReplacementPicker.eligible_rows(
		sm.call("list_slots"), budget.get("scope", {})
	):
		if String(row.get("label", "")) == label:
			return String(row.get("slot_id", ""))
	return ""


func _next_manual_slot_id(timestamp: int = -1) -> String:
	var value := timestamp if timestamp >= 0 else int(Time.get_unix_time_from_system() * 1000.0)
	var base := "campaign-map-%d" % value
	var sm := get_node_or_null("/root/SaveManager")
	var candidate := base
	var suffix := 2
	while sm != null and bool(sm.call("has_slot", candidate)):
		candidate = "%s-%d" % [base, suffix]
		suffix += 1
	return candidate


func _on_settings() -> void:
	if _settings_screen == null:
		_settings_screen = load("res://scenes/ui/SettingsScreen.tscn").instantiate()
		_settings_screen.name = "SettingsScreen"
		add_child(_settings_screen)
		_settings_screen.back_pressed.connect(_on_settings_back)
	_settings_screen.open()


func _on_settings_back() -> void:
	_settings_button.grab_focus()


func _settings_is_open() -> bool:
	return _settings_screen != null and _settings_screen.visible


func _change_zoom(delta: float) -> void:
	_zoom = clampf(_zoom + delta, 0.7, 1.5)
	_zoom_label.text = "%d%%" % roundi(_zoom * 100.0)
	_rebuild()


func _on_size_class_changed(new_class: String, _previous_class: String) -> void:
	_apply_size_class(new_class)


func _apply_size_class(size_class: String) -> void:
	var gutter := 12 if size_class == "compact" else 32 if size_class == "medium" else 72
	_margin.add_theme_constant_override("margin_left", gutter)
	_margin.add_theme_constant_override("margin_right", gutter)
	_margin.add_theme_constant_override("margin_top", 16)
	_margin.add_theme_constant_override("margin_bottom", 16)
