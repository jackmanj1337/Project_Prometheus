class_name ControllerPlacement
extends RefCounted

# Where the registry's controls go by default, given the window and the game view
# ([UUI-2], [UUI-20] point 8). Controls never cover the game: in landscape they go
# in the two side columns the game view leaves, and in portrait in the band below
# it, split into a left and a right half.
#
# Descriptors say WHICH column and in what order; this decides WHERE, because the
# columns move with every Game View preset and window size and a fixed fraction of
# the window cannot follow them. A descriptor may name:
#   column  "left" | "right"   (default: the side its own x is on)
#   cell    [col, row] in -1..1, which makes it part of the column's 3x3 cluster —
#           the D-pad, or the face-button diamond — drawn at the column's foot
#   order   stacking order among the column's other controls, packed into rows
#           above the cluster, as many per row as fit
# Shoulders (group `shoulder`) pin to the top of their column instead.
#
# A layout the player has dragged is not touched: an empty element list means
# "follow the registry placement", and only that list is placed here.

# Mirror tools/web/controller_shell.js (BASE_SIZE_FRACTION, MIN_BUTTON_PX,
# MAX_BUTTON_PX, EDGE_MARGIN, and the 1.9x pill): the shell sizes controls from the
# window's short edge, so placement has to know the same sizes. Change them together.
const BUTTON_SHORT_EDGE_FRACTION: float = 0.115
const BUTTON_MIN_PX: float = 38.0
const BUTTON_MAX_PX: float = 96.0
const EDGE_MARGIN_PX: float = 4.0
const PILL_WIDTH_FACTOR: float = 1.9
# Space between packed rows and between controls in a row. The cluster packs tighter,
# so its arms read as one cross rather than four buttons.
const GAP_PX: float = 6.0
const CLUSTER_GAP_PX: float = 2.0


static func button_px(available: Vector2) -> float:
	return clampf(
		roundf(minf(available.x, available.y) * BUTTON_SHORT_EDGE_FRACTION),
		BUTTON_MIN_PX,
		BUTTON_MAX_PX
	)


# The width one side column needs to hold a 3x3 cluster. [UUI-1]'s widest-that-fits
# default is defined against this.
static func side_column_px(available: Vector2) -> float:
	return button_px(available) * 3.0 + EDGE_MARGIN_PX * 2.0


# id -> Vector2 centre, in fractions of the window. Empty when the window or the
# game view is unknown, which callers read as "use the descriptors' own x/y".
static func place(
	descriptors: Array[Dictionary], available: Vector2, canvas: Rect2, orientation: String
) -> Dictionary:
	if available.x <= 0.0 or available.y <= 0.0 or canvas.size.x <= 0.0:
		return {}
	var b := button_px(available)
	var regions := _regions(available, canvas, orientation, b)
	var by_column := {"left": [], "right": []}
	for d: Dictionary in descriptors:
		by_column[_column_of(d)].append(d)
	var placed := {}
	for column: String in by_column:
		_place_column(by_column[column], regions[column], b, placed)
	for id: String in placed:
		placed[id] = (placed[id] as Vector2) / available
	return placed


static func _column_of(d: Dictionary) -> String:
	var column := String(d.get("column", ""))
	if column in ["left", "right"]:
		return column
	return "left" if float(d.get("x", 0.5)) < 0.5 else "right"


# The two regions controls may use. Where the game view leaves less than a cluster's
# width (a 16:9 preset on a phone, say) the region is widened to that width at the
# window edge: overlapping the game is then the only way to keep the controls
# usable, and the player chose the preset that caused it.
static func _regions(
	available: Vector2, canvas: Rect2, orientation: String, b: float
) -> Dictionary:
	var need := b * 3.0 + EDGE_MARGIN_PX * 2.0
	if orientation == "portrait":
		var top := minf(canvas.end.y, available.y - need)
		var half := available.x * 0.5
		return {
			"left": Rect2(0.0, top, half, available.y - top),
			"right": Rect2(half, top, available.x - half, available.y - top),
		}
	var left_w := maxf(canvas.position.x, need)
	var right_x := minf(canvas.end.x, available.x - need)
	return {
		"left": Rect2(0.0, 0.0, left_w, available.y),
		"right": Rect2(right_x, 0.0, available.x - right_x, available.y),
	}


static func _place_column(members: Array, region: Rect2, b: float, placed: Dictionary) -> void:
	var cluster: Array[Dictionary] = []
	var shoulders: Array[Dictionary] = []
	var stacked: Array[Dictionary] = []
	for d: Dictionary in members:
		if _cell_of(d) != null:
			cluster.append(d)
		elif String(d.get("group", "")) == "shoulder":
			shoulders.append(d)
		else:
			stacked.append(d)
	stacked.sort_custom(
		func(a: Dictionary, c: Dictionary) -> bool: return _order_of(a) < _order_of(c)
	)

	var centre_x := region.position.x + region.size.x * 0.5
	var cursor := region.end.y - EDGE_MARGIN_PX
	if not cluster.is_empty():
		var pitch := b + CLUSTER_GAP_PX
		var middle := Vector2(centre_x, cursor - pitch * 1.5)
		for d: Dictionary in cluster:
			var cell: Vector2 = _cell_of(d)
			placed[String(d.id)] = middle + cell * pitch
		cursor -= pitch * 3.0 + GAP_PX
	for row: Array in _rows(stacked, region.size.x - EDGE_MARGIN_PX * 2.0, b):
		_place_row(row, centre_x, cursor - b * 0.5, b, placed)
		cursor -= b + GAP_PX
	var top := region.position.y + EDGE_MARGIN_PX + b * 0.5
	for row: Array in _rows(shoulders, region.size.x - EDGE_MARGIN_PX * 2.0, b):
		_place_row(row, centre_x, top, b, placed)
		top += b + GAP_PX


# Greedy row packing: as many controls side by side as the column's width allows,
# and never fewer than one, so a control too wide for its column still gets a row.
static func _rows(items: Array[Dictionary], width: float, b: float) -> Array:
	var rows: Array = []
	var current: Array[Dictionary] = []
	var used := 0.0
	for d: Dictionary in items:
		var w := _width_of(d, b)
		var extra := w if current.is_empty() else w + GAP_PX
		if not current.is_empty() and used + extra > width:
			rows.append(current)
			current = []
			used = 0.0
			extra = w
		current.append(d)
		used += extra
	if not current.is_empty():
		rows.append(current)
	return rows


static func _place_row(row: Array, centre_x: float, y: float, b: float, placed: Dictionary) -> void:
	var total := -GAP_PX
	for d: Dictionary in row:
		total += _width_of(d, b) + GAP_PX
	var x := centre_x - total * 0.5
	for d: Dictionary in row:
		var w := _width_of(d, b)
		placed[String(d.id)] = Vector2(x + w * 0.5, y)
		x += w + GAP_PX


static func _width_of(d: Dictionary, b: float) -> float:
	return b * (PILL_WIDTH_FACTOR if String(d.get("group", "")) == "action" else 1.0)


static func _order_of(d: Dictionary) -> int:
	return int(d.get("order", 1000))


static func _cell_of(d: Dictionary) -> Variant:
	var cell: Variant = d.get("cell", null)
	if cell is Vector2:
		return cell
	return null
