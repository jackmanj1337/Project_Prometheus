extends Node2D
# V031-MRD-01 dual-outline overlay (owner-specified look, v0.3.1 return
# 2026-07-12): two strong perimeter outlines drawn ABOVE unit sprites —
# a bright red line around the union of ALL threatened tiles and a dark red
# line around the union of the WATCHED threat tiles, with the dark watch line
# drawn over the bright one where the two areas share an edge.
#
# This is a draw surface, not a policy owner: GridManager computes the
# world-space segment lists (perimeter_edge_segments, pure + tested headless)
# and hands them over; this node only strokes them. Kept separate from the
# tile-variant stacked_perimeter approach because TileMapLayer overlays render
# BELOW units and can't express two independent unions/colours.
#
# No `class_name`: GridManager preloads this script (same headless --script
# test convention as MenuRepeatPolicy / InputDisplay).

# Placeholder colours/widths pending live F8 comparison; exported so the next
# tuning pass needs no code edit.
@export var danger_color: Color = Color(1.0, 0.25, 0.2, 0.95)   # bright red — whole danger area
@export var watch_color: Color = Color(0.55, 0.02, 0.02, 0.95)  # dark red — watched subset
@export var danger_width: float = 4.0
@export var watch_width: float = 4.0

# Flat [from, to, from, to, …] world-space point pairs.
var _danger_segments: PackedVector2Array = PackedVector2Array()
var _watch_segments: PackedVector2Array = PackedVector2Array()


func set_perimeters(danger_segments: PackedVector2Array,
		watch_segments: PackedVector2Array) -> void:
	_danger_segments = danger_segments
	_watch_segments = watch_segments
	queue_redraw()


func clear() -> void:
	set_perimeters(PackedVector2Array(), PackedVector2Array())


func _draw() -> void:
	# Bright general-danger outline first, dark watch outline second, so the
	# dark line wins shared edges (owner spec: dark over bright).
	_draw_segments(_danger_segments, danger_color, danger_width)
	_draw_segments(_watch_segments, watch_color, watch_width)


func _draw_segments(segments: PackedVector2Array, color: Color, width: float) -> void:
	var i := 0
	while i + 1 < segments.size():
		draw_line(segments[i], segments[i + 1], color, width)
		i += 2
