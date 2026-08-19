extends Control
# Responsive campaign-graph surface. CampaignManager remains the sole authority
# for availability, cadence evaluation, and entry into prep.

@onready var _margin: MarginContainer = $Margin
@onready var _nodes: VBoxContainer = $Margin/VBox/Canvas/Nodes
@onready var _status: Label = $Margin/VBox/Status
@onready var _zoom_label: Label = $Margin/VBox/Toolbar/ZoomLabel

var _zoom := 1.0


func _ready() -> void:
	$Margin/VBox/Toolbar/ZoomOut.pressed.connect(_change_zoom.bind(-0.1))
	$Margin/VBox/Toolbar/ZoomIn.pressed.connect(_change_zoom.bind(0.1))
	var responsive := get_node_or_null("/root/ResponsiveLayout")
	if responsive != null and responsive.has_signal("size_class_changed"):
		responsive.size_class_changed.connect(_on_size_class_changed)
		_apply_size_class(String(responsive.get("size_class")))
	else:
		_apply_size_class("expanded")
	_rebuild()


func _rebuild() -> void:
	for child in _nodes.get_children():
		child.queue_free()
		_nodes.remove_child(child)
	var cm := get_node_or_null("/root/CampaignManager")
	if cm == null or not bool(cm.call("uses_overworld")):
		_status.text = "No overworld campaign is active."
		return
	var first_available: Button = null
	for row in cm.call("get_overworld_nodes"):
		var button := Button.new()
		button.name = "Node_%s" % String(row.get("node_id", ""))
		button.text = _node_label(row)
		button.disabled = not bool(row.get("available", false))
		button.custom_minimum_size = Vector2(280.0 * _zoom, 48.0 * _zoom)
		button.pressed.connect(_on_node_pressed.bind(String(row.get("node_id", ""))))
		_nodes.add_child(button)
		if first_available == null and not button.disabled:
			first_available = button
	if first_available != null:
		first_available.call_deferred("grab_focus")
	_status.text = "Choose the next destination or revisit a cleared hub."


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
