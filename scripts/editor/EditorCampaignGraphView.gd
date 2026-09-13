class_name EditorCampaignGraphView extends Control
# A read-only Control for the canonical campaign graph. It receives a derived model from
# `EditorCampaignGraph`; it never writes node ids, successors, or positions back to data.

signal node_selected(node_id: String)

const NODE_SIZE := Vector2(220.0, 72.0)
const NODE_FILL := Color("24314a")
const NODE_START_FILL := Color("31563f")
const NODE_ERROR_FILL := Color("5b3232")
const NODE_BORDER := Color("8ba3c7")
const EDGE_COLOR := Color("a9b8d1")
const TEXT_COLOR := Color("f4f6fb")
const MUTED_COLOR := Color("c2cede")

var _graph: Dictionary = {}
var _rects: Dictionary = {}


func set_graph(graph: Dictionary) -> void:
	_graph = graph.duplicate(true)
	_rects.clear()
	var required_size := Vector2(760.0, 520.0)
	for node in _graph.get("nodes", []) as Array[Dictionary]:
		var position: Vector2 = node.get("position", Vector2.ZERO)
		required_size.x = maxf(required_size.x, position.x + NODE_SIZE.x + 32.0)
		required_size.y = maxf(required_size.y, position.y + NODE_SIZE.y + 32.0)
	custom_minimum_size = required_size
	queue_redraw()


func graph() -> Dictionary:
	return _graph.duplicate(true)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
	_rects.clear()
	if _graph.is_empty():
		return
	var nodes: Array[Dictionary] = _graph.get("nodes", []) as Array[Dictionary]
	var edges: Array[Dictionary] = _graph.get("edges", []) as Array[Dictionary]
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[String(node["id"])] = node
	for edge in edges:
		var from_node: Dictionary = by_id.get(String(edge["from"]), {})
		var to_node: Dictionary = by_id.get(String(edge["to"]), {})
		if from_node.is_empty() or to_node.is_empty():
			continue
		var from_rect := _node_rect(from_node)
		var to_rect := _node_rect(to_node)
		draw_line(from_rect.get_center(), to_rect.get_center(), EDGE_COLOR, 2.0, true)
	for node in nodes:
		var rect := _node_rect(node)
		var node_id := String(node["id"])
		_rects[node_id] = rect
		var fill := NODE_START_FILL if bool(node["is_start"]) else NODE_FILL
		if not bool(node["reachable_from_start"]):
			fill = NODE_ERROR_FILL
		draw_style_box(_box(fill), rect)
		var title := String(node["label"])
		if bool(node["is_start"]):
			title = "Start  ·  %s" % title
		draw_string(
			ThemeDB.fallback_font,
			rect.position + Vector2(12, 24),
			title,
			HORIZONTAL_ALIGNMENT_LEFT,
			rect.size.x - 24,
			16,
			TEXT_COLOR
		)
		var map_id := String(node["map_id"])
		if map_id != "":
			draw_string(
				ThemeDB.fallback_font,
				rect.position + Vector2(12, 49),
				"Map: %s" % map_id,
				HORIZONTAL_ALIGNMENT_LEFT,
				rect.size.x - 24,
				13,
				MUTED_COLOR
			)
		else:
			draw_string(
				ThemeDB.fallback_font,
				rect.position + Vector2(12, 49),
				"No map selected",
				HORIZONTAL_ALIGNMENT_LEFT,
				rect.size.x - 24,
				13,
				MUTED_COLOR
			)


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not (event as InputEventMouseButton).pressed:
		return
	if (event as InputEventMouseButton).button_index != MOUSE_BUTTON_LEFT:
		return
	for node_id in _rects:
		if (_rects[node_id] as Rect2).has_point((event as InputEventMouseButton).position):
			node_selected.emit(String(node_id))
			accept_event()
			return


func _node_rect(node: Dictionary) -> Rect2:
	return Rect2(node.get("position", Vector2.ZERO), NODE_SIZE)


func _box(fill: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = NODE_BORDER
	box.set_border_width_all(1)
	box.set_corner_radius_all(6)
	return box
