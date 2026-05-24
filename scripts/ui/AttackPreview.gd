extends Control
# Shows attacker vs defender combat stats before the player confirms an attack.
# Populated by MapCursor when entering 'previewing' state.
#
# Phase 1 More Info content (see AGENT/Docs/more_info_mode_plan_2026-05-24.md):
# the preview shows weapon-triangle and effectiveness markers because both are
# pre-requisites for the upcoming combat-preview More Info selector. Both
# fields read straight from CombatResolver.preview_combat() — the resolver is
# the math authority; this script only formats the result.
#
# Positioning (2026-05-24d follow-up): instead of a fixed bottom-of-screen
# panel, the preview anchors adjacent to the defender's screen tile. If
# neither side of the defender has room for the panel on the current viewport
# the camera pans horizontally just far enough to make room — this is the
# only place outside CameraController that triggers a camera write, and it
# goes through pan_by_pixels() so map-bounds clamping is honoured.

const GameConstants = preload("res://scripts/shared/GameConstants.gd")

@onready var _panel: PanelContainer = $Panel
@onready var _atk_name: Label      = $Panel/HBox/AttackerBox/AtkName
@onready var _atk_hp: Label        = $Panel/HBox/AttackerBox/AtkHP
@onready var _atk_dmg: Label       = $Panel/HBox/AttackerBox/AtkDmg
@onready var _atk_hit: Label       = $Panel/HBox/AttackerBox/AtkHit
@onready var _atk_crit: Label      = $Panel/HBox/AttackerBox/AtkCrit
@onready var _atk_triangle: Label  = $Panel/HBox/AttackerBox/AtkTriangle
@onready var _atk_effective: Label = $Panel/HBox/AttackerBox/AtkEffective
@onready var _def_name: Label      = $Panel/HBox/DefenderBox/DefName
@onready var _def_hp: Label        = $Panel/HBox/DefenderBox/DefHP
@onready var _def_dmg: Label       = $Panel/HBox/DefenderBox/DefDmg
@onready var _def_hit: Label       = $Panel/HBox/DefenderBox/DefHit
@onready var _def_crit: Label      = $Panel/HBox/DefenderBox/DefCrit
@onready var _def_triangle: Label  = $Panel/HBox/DefenderBox/DefTriangle
@onready var _def_effective: Label = $Panel/HBox/DefenderBox/DefEffective

# Colors tuned to read against the dark panel: green = advantage / boost,
# red = disadvantage, amber = effective. Modulate is used instead of BBCode
# because these are plain Labels and modulate avoids upgrading the whole row
# to a RichTextLabel for one short tag.
const COLOR_ADVANTAGE    := Color(0.38, 0.77, 0.33)
const COLOR_DISADVANTAGE := Color(0.85, 0.36, 0.36)
const COLOR_EFFECTIVE    := Color(0.94, 0.78, 0.30)
const COLOR_NEUTRAL      := Color(1, 1, 1, 0.6)

# Pixel gap between the defender's tile edge and the preview panel, and
# between the panel and the viewport edge. Small enough that the panel reads
# as "attached" to the defender without crowding the sprite.
const PANEL_MARGIN_PX: int = 16

# Injected by MapCursor.setup() so the panel can read the defender's screen
# position and ask the camera controller to pan when there is no room. All
# three may be null in headless tests — show_preview() falls back to the
# original fixed position so existing tests keep working.
var _camera: Camera2D = null
var _grid: Node = null
var _camera_ctrl: RefCounted = null


# Inject scene-tree dependencies that the dynamic positioning needs. Safe to
# omit (headless tests) — the panel then keeps whatever position it had from
# the scene file, matching the pre-2026-05-24 behaviour.
func setup(camera: Camera2D, grid: Node, camera_ctrl: RefCounted) -> void:
	_camera = camera
	_grid = grid
	_camera_ctrl = camera_ctrl


func _ready() -> void:
	hide()


func show_preview(attacker: Node, defender: Node) -> void:
	var cr := get_node_or_null("/root/CombatResolver")
	if cr == null:
		return
	var p: Dictionary = cr.preview_combat(attacker, defender)

	_atk_name.text = attacker.data.unit_name if attacker.data else "???"
	_atk_hp.text = "HP %d" % (attacker.data.hp if attacker.data else 0)
	_atk_dmg.text = "Dmg  %d×%d" % [p["attacker_damage"], p["attacker_attacks"]]
	_atk_hit.text = "Hit  %d%%" % p["attacker_hit"]
	_atk_crit.text = "Crit %d%%" % p["attacker_crit"]
	_apply_triangle(_atk_triangle, String(p.get("attacker_triangle", "neutral")))
	_apply_effective(_atk_effective,
		bool(p.get("attacker_effective", false)),
		float(p.get("attacker_effectiveness_mult", 1.0)))

	# Flag Vantage on the defender's name — the defender will strike first.
	var def_name: String = defender.data.unit_name if defender.data else "???"
	if p.get("defender_vantage", false):
		def_name += "  [Vantage]"
	_def_name.text = def_name
	_def_hp.text = "HP %d" % (defender.data.hp if defender.data else 0)
	if p["can_counter"]:
		_def_dmg.text = "Dmg  %d×%d" % [p["defender_damage"], p["defender_attacks"]]
		_def_hit.text = "Hit  %d%%" % p["defender_hit"]
		_def_crit.text = "Crit %d%%" % p["defender_crit"]
		_apply_triangle(_def_triangle, String(p.get("defender_triangle", "neutral")))
		_apply_effective(_def_effective,
			bool(p.get("defender_effective", false)),
			float(p.get("defender_effectiveness_mult", 1.0)))
	else:
		# No counter -> defender row is mostly blank; clear the markers too so
		# stale text from a previous preview never leaks through.
		_def_dmg.text = "No counter"
		_def_hit.text = ""
		_def_crit.text = ""
		_apply_triangle(_def_triangle, "neutral")
		_apply_effective(_def_effective, false, 1.0)

	# Reposition after content updates so PanelContainer's minimum size
	# reflects the labels we just set. Then make visible.
	_reposition_for(defender)
	show()


func hide_preview() -> void:
	hide()


# Anchors the panel beside `defender` on the current viewport. Right of the
# defender by default; left if there is no room on the right; pan the camera
# and use the right side if neither side fits. No-op in headless tests where
# camera/grid were never injected.
func _reposition_for(defender: Node) -> void:
	if defender == null or not is_instance_valid(defender) or _camera == null:
		return
	if not (defender is Node2D):
		return
	# PanelContainer doesn't always report its minimum size until after a
	# layout pass; reset_size() forces it to recompute from current content.
	_panel.reset_size()
	var panel_size: Vector2 = _panel.size
	if panel_size == Vector2.ZERO:
		panel_size = _panel.get_combined_minimum_size()
	var view: Vector2 = get_viewport_rect().size
	var tile_px: float = float(GameConstants.TILE_SIZE)
	var defender_screen: Vector2 = (defender as Node2D).get_global_transform_with_canvas().origin

	# Try the right side first. If it overflows the viewport, try the left.
	# If the left also overflows, pan the camera so the right side fits.
	var right_left: float = defender_screen.x + tile_px + PANEL_MARGIN_PX
	var left_left: float  = defender_screen.x - PANEL_MARGIN_PX - panel_size.x
	var panel_left: float = right_left
	if right_left + panel_size.x > view.x - PANEL_MARGIN_PX:
		if left_left >= PANEL_MARGIN_PX:
			panel_left = left_left
		else:
			# Neither side fits — shift the camera right by enough to make
			# the right-side placement land inside the viewport. After the
			# pan the defender's screen position has moved left by the same
			# amount, so we recompute and re-anchor.
			var max_right_left: float = view.x - PANEL_MARGIN_PX - panel_size.x
			var pan_x: float = right_left - max_right_left
			if pan_x > 0 and _camera_ctrl != null and _camera_ctrl.has_method("pan_by_pixels"):
				_camera_ctrl.pan_by_pixels(Vector2(pan_x, 0))
				defender_screen = (defender as Node2D).get_global_transform_with_canvas().origin
				panel_left = defender_screen.x + tile_px + PANEL_MARGIN_PX
			# If the camera couldn't move (e.g. already at the map edge),
			# clamp to the right-most legal position so the panel stays on
			# screen even if it visually overlaps the defender.
			panel_left = min(panel_left, view.x - PANEL_MARGIN_PX - panel_size.x)
			panel_left = max(panel_left, PANEL_MARGIN_PX)

	# Vertical: centre the panel on the defender; clamp to viewport so the
	# top/bottom never clip when the defender is at a screen edge.
	var panel_top: float = defender_screen.y + tile_px * 0.5 - panel_size.y * 0.5
	panel_top = clampf(panel_top, PANEL_MARGIN_PX, view.y - panel_size.y - PANEL_MARGIN_PX)

	_panel.position = Vector2(panel_left, panel_top)


# Writes the triangle marker into `label`. Neutral collapses to an empty
# string so the row doesn't reserve vertical space for a marker that has no
# meaning right now.
func _apply_triangle(label: Label, result: String) -> void:
	match result:
		"advantage":
			label.text = "▲ Advantage"
			label.modulate = COLOR_ADVANTAGE
		"disadvantage":
			label.text = "▼ Disadvantage"
			label.modulate = COLOR_DISADVANTAGE
		_:
			label.text = ""
			label.modulate = COLOR_NEUTRAL


# Writes the effectiveness marker. Mult is shown when > 1 so the player can
# see Giantkiller's 4× distinct from the normal 3× effective bonus.
func _apply_effective(label: Label, is_effective: bool, mult: float) -> void:
	if is_effective:
		label.text = "Effective ×%d" % int(round(mult))
		label.modulate = COLOR_EFFECTIVE
	else:
		label.text = ""
		label.modulate = COLOR_NEUTRAL
