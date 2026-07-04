extends Control
# Shows attacker vs defender combat stats before the player confirms an attack.
# Populated by MapCursor when entering 'previewing' state.
#
# Phase 1 More Info host (see AGENT/Docs/more_info_mode_plan_2026-05-24.md):
# every preview field is a clickable [url=combat_field:...] link that opens
# a description in the InfoBox side panel; the more_info action cycles
# through them in declaration order. Combat preview wins priority 1 in the
# F chain so its handler consumes the event when the panel is visible.
#
# Positioning: instead of a fixed bottom-of-screen slot the preview anchors
# beside the defender on screen. If neither side has room the camera pans
# horizontally via CameraController.pan_by_pixels(). The math reads the
# panel's current size after content updates so the InfoBox column can grow
# without breaking the screen-edge clamp.

const GameConstants    = preload("res://scripts/shared/GameConstants.gd")
const MoreInfoContent  = preload("res://scripts/shared/MoreInfoContent.gd")

@onready var _panel: PanelContainer = $Panel
@onready var _attacker_box: VBoxContainer = $Panel/HBox/AttackerBox
@onready var _defender_box: VBoxContainer = $Panel/HBox/DefenderBox
@onready var _info_box: VBoxContainer = $Panel/HBox/InfoBox
@onready var _atk_name: RichTextLabel      = $Panel/HBox/AttackerBox/AtkName
@onready var _atk_weapon: RichTextLabel    = $Panel/HBox/AttackerBox/AtkWeapon
@onready var _atk_hp: RichTextLabel        = $Panel/HBox/AttackerBox/AtkHP
@onready var _atk_dmg: RichTextLabel       = $Panel/HBox/AttackerBox/AtkDmg
@onready var _atk_hit: RichTextLabel       = $Panel/HBox/AttackerBox/AtkHit
@onready var _atk_crit: RichTextLabel      = $Panel/HBox/AttackerBox/AtkCrit
@onready var _atk_triangle: RichTextLabel  = $Panel/HBox/AttackerBox/AtkTriangle
@onready var _atk_effective: RichTextLabel = $Panel/HBox/AttackerBox/AtkEffective
@onready var _def_name: RichTextLabel      = $Panel/HBox/DefenderBox/DefName
@onready var _def_weapon: RichTextLabel    = $Panel/HBox/DefenderBox/DefWeapon
@onready var _def_hp: RichTextLabel        = $Panel/HBox/DefenderBox/DefHP
@onready var _def_dmg: RichTextLabel       = $Panel/HBox/DefenderBox/DefDmg
@onready var _def_hit: RichTextLabel       = $Panel/HBox/DefenderBox/DefHit
@onready var _def_crit: RichTextLabel      = $Panel/HBox/DefenderBox/DefCrit
@onready var _def_triangle: RichTextLabel  = $Panel/HBox/DefenderBox/DefTriangle
@onready var _def_effective: RichTextLabel = $Panel/HBox/DefenderBox/DefEffective
@onready var _info_title: Label            = $Panel/HBox/InfoBox/InfoTitle
@onready var _info_hint: Label             = $Panel/HBox/InfoBox/InfoHint
@onready var _info_desc: RichTextLabel     = $Panel/HBox/InfoBox/InfoDescription

# BBCode colour strings (Hex without alpha — RichTextLabel matches the
# previous modulate colours). Inline [color] wraps the link text so the
# triangle/effective markers stay readable while still being clickable.
const COLOR_ADVANTAGE    := "#61c454"
const COLOR_DISADVANTAGE := "#d85b5b"
const COLOR_EFFECTIVE    := "#eec84c"
const COLOR_NEUTRAL      := "#9a9aa6"

# Pixel gap between the defender's tile edge and the preview panel, and
# between the panel and the viewport edge.
const PANEL_MARGIN_PX: int = 16
const FORECAST_COLUMN_MIN_WIDTH: float = 150.0
const INFO_COLUMN_MIN_WIDTH: float = 300.0
const PANEL_DEFAULT_HEIGHT: float = 230.0
const FORECAST_ROW_PADDING_Y: float = 4.0
# Horizontal slack subtracted from the forecast column when deciding whether a
# name fits on one line, so the ellipsis never butts right against the edge.
const NAME_FIT_PADDING_X: float = 6.0
const NAME_ELLIPSIS: String = "…"

# Injected by MapCursor.setup() so the panel can read the defender's screen
# position and ask the camera controller to pan when there is no room. All
# three may be null in headless tests — show_preview() then keeps the panel
# at its scene-file position rather than crashing.
var _camera: Camera2D = null
var _grid: Node = null
var _camera_ctrl: RefCounted = null

# Ordered list of selectable entries built during show_preview(). Each is
# {"side": "atk"|"def", "key": "hit"|..., "title": String} — `more_info`
# cycles through this list in left-to-right, top-to-bottom order.
var _entries: Array = []

# Index into _entries for the currently displayed side-panel entry. -1 means
# nothing is selected yet — InfoHint is visible and InfoDescription is empty.
var _current_index: int = -1

# Full, untruncated combatant names captured each show_preview(). The name rows
# may be shortened with an ellipsis to fit their column, so More Info reads from
# these to always show the complete name.
var _atk_full_name: String = ""
var _def_full_name: String = ""

# Battle Speed of each side and the follow-up threshold, captured each
# show_preview(). Surfaced in the Damage field's More Info so the player can
# verify the follow-up (doubling) math (handbook 8.3).
var _atk_battle_speed: int = 0
var _def_battle_speed: int = 0
var _follow_up_threshold: int = 5
var _can_counter: bool = false

# The defender the visible preview is anchored to, captured in show_preview() so a
# zoom change can re-anchor the panel beside it — the same reposition-on-zoom the
# context menus get (V025-04c). Cleared on hide so a stale defender is never used.
var _anchor_defender: Node = null


func setup(camera: Camera2D, grid: Node, camera_ctrl: RefCounted) -> void:
	_camera = camera
	_grid = grid
	_camera_ctrl = camera_ctrl


func _ready() -> void:
	_attacker_box.custom_minimum_size.x = FORECAST_COLUMN_MIN_WIDTH
	_defender_box.custom_minimum_size.x = FORECAST_COLUMN_MIN_WIDTH
	_info_box.custom_minimum_size.x = INFO_COLUMN_MIN_WIDTH
	# Wire every selectable field's meta_clicked to the same handler. The
	# [url=combat_field:KEY] meta string is parsed in _on_entry_clicked.
	for label in _all_selectable_labels():
		label.meta_clicked.connect(_on_entry_clicked)
	hide()


func show_preview(attacker: Node, defender: Node) -> void:
	var cr := get_node_or_null("/root/CombatResolver")
	if cr == null:
		return
	var p: Dictionary = cr.preview_combat(attacker, defender)

	_entries.clear()
	_current_index = -1

	# Battle Speed + follow-up threshold for the Damage field's More Info (8.3).
	_atk_battle_speed = int(p.get("attacker_battle_speed", 0))
	_def_battle_speed = int(p.get("defender_battle_speed", 0))
	_follow_up_threshold = int(p.get("follow_up_threshold", 5))
	_can_counter = bool(p.get("can_counter", false))

	# ---- Attacker rows -----------------------------------------------
	var atk_name: String = attacker.data.unit_name if attacker.data else "???"
	_atk_full_name = atk_name
	# Name rows are one line; truncate with an ellipsis so a long name can't
	# wrap and clip. The full name stays available through More Info.
	_atk_name.text = _link("atk", "name", "Attacker",
		_fit_name_to_column(atk_name, "", _atk_name))
	# V021-14: name the equipped weapon under each combatant (the sheet already shows
	# full weapon stats; the forecast just needs the name for at-a-glance matchups).
	_atk_weapon.text = _weapon_name(attacker)
	var atk_hp_val: int = attacker.data.hp if attacker.data else 0
	var atk_hp_max: int = attacker.data.max_hp if attacker.data else 0
	_atk_hp.text  = _link("atk", "hp", "HP",
		"HP %d / %d" % [atk_hp_val, atk_hp_max])
	_atk_dmg.text = _link("atk", "damage", "Damage",
		"Dmg  %d×%d" % [p["attacker_damage"], p["attacker_attacks"]])
	_atk_hit.text = _link("atk", "hit", "Hit Rate",
		"Hit  %d%%" % p["attacker_hit"])
	_atk_crit.text = _link("atk", "crit", "Crit Rate",
		"Crit %d%%" % p["attacker_crit"])
	_atk_triangle.text = _triangle_link("atk",
		String(p.get("attacker_triangle", "neutral")))
	_atk_effective.text = _effective_link("atk",
		bool(p.get("attacker_effective", false)),
		float(p.get("attacker_effectiveness_mult", 1.0)))

	# ---- Defender rows -----------------------------------------------
	var def_name_str: String = defender.data.unit_name if defender.data else "???"
	_def_full_name = def_name_str
	if p.get("defender_vantage", false):
		# Vantage is annotated on the name so the player sees the strike-order
		# change. The [Vantage] tag stays outside the [url] to keep the link
		# meta clean, and its width is reserved so it survives name truncation.
		var vantage_suffix: String = "  [Vantage]"
		_def_name.text = _link("def", "name", "Defender",
			_fit_name_to_column(def_name_str, vantage_suffix, _def_name)) + vantage_suffix
	else:
		_def_name.text = _link("def", "name", "Defender",
			_fit_name_to_column(def_name_str, "", _def_name))
	_def_weapon.text = _weapon_name(defender)
	var def_hp_val: int = defender.data.hp if defender.data else 0
	var def_hp_max: int = defender.data.max_hp if defender.data else 0
	_def_hp.text = _link("def", "hp", "HP",
		"HP %d / %d" % [def_hp_val, def_hp_max])
	if p["can_counter"]:
		_def_dmg.text = _link("def", "damage", "Damage",
			"Dmg  %d×%d" % [p["defender_damage"], p["defender_attacks"]])
		_def_hit.text = _link("def", "hit", "Hit Rate",
			"Hit  %d%%" % p["defender_hit"])
		_def_crit.text = _link("def", "crit", "Crit Rate",
			"Crit %d%%" % p["defender_crit"])
		_def_triangle.text = _triangle_link("def",
			String(p.get("defender_triangle", "neutral")))
		_def_effective.text = _effective_link("def",
			bool(p.get("defender_effective", false)),
			float(p.get("defender_effectiveness_mult", 1.0)))
	else:
		# No counter — the defender row collapses to a single "No counter"
		# line. We still register it as an entry so more_info cycle visits
		# the defender side, but the description is a plain note.
		_def_dmg.text = _link("def", "damage", "Damage", "No counter")
		# Dashes, not blanks (V026-04b): keep the row heights so the triangle /
		# effectiveness icons below stay aligned with the attacker column. Plain
		# text (no _link) so More Info never describes a rate that doesn't exist.
		_def_hit.text = "Hit  —"
		_def_crit.text = "Crit —"
		_def_triangle.text = _triangle_link("def", "neutral")
		_def_effective.text = _effective_link("def", false, 1.0)

	_refresh_forecast_row_heights()
	_reset_info_panel()
	_size_panel_to_content()
	_anchor_defender = defender
	_reposition_for(defender)
	show()


func hide_preview() -> void:
	_anchor_defender = null
	hide()


# Re-anchors the visible preview beside its current defender. Called by MapCursor
# when the map zoom changes so the panel tracks the unit the same way the context
# menus do (V025-04c). No-op when hidden or without a live anchor defender.
func reposition() -> void:
	if not visible or _anchor_defender == null or not is_instance_valid(_anchor_defender):
		return
	_reposition_for(_anchor_defender)


# Returns the labels that participate in selection. Hand-listed instead of
# walking the tree so a future "add a stat below crit" doesn't accidentally
# break selection ordering — the cycle order is exactly this declaration
# order, which matches how the player reads the preview.
# V021-14: the equipped weapon's display name for the forecast row, or "Unarmed".
func _weapon_name(unit: Node) -> String:
	if unit == null or not unit.has_method("get_equipped_weapon"):
		return "Unarmed"
	var w: WeaponData = unit.get_equipped_weapon()
	return w.display_name if w != null and String(w.display_name) != "" else "Unarmed"


func _all_selectable_labels() -> Array[RichTextLabel]:
	return [
		_atk_name, _atk_hp, _atk_dmg, _atk_hit, _atk_crit, _atk_triangle, _atk_effective,
		_def_name, _def_hp, _def_dmg, _def_hit, _def_crit, _def_triangle, _def_effective,
	]


func _all_forecast_rows() -> Array[RichTextLabel]:
	return [
		_atk_name, _atk_weapon, _atk_hp, _atk_dmg, _atk_hit, _atk_crit, _atk_triangle,
		_atk_effective, _def_name, _def_weapon, _def_hp, _def_dmg, _def_hit, _def_crit,
		_def_triangle, _def_effective,
	]


# Builds one selectable field. `title` is the side-panel title used when this
# field is selected; `text` is the visible row text. Registering the entry
# here keeps the _entries list in sync with the visible link order.
func _link(side: String, key: String, title: String, text: String) -> String:
	_entries.append({"side": side, "key": key, "title": title})
	return "[url=combat_field:%s:%s]%s[/url]" % [side, key, text]


# Triangle marker. Neutral is visible so the row does not disappear when no
# side has advantage; all states stay clickable and reachable by F-cycling.
func _triangle_link(side: String, result: String) -> String:
	match result:
		"advantage":
			return _link(side, "triangle", "Weapon Triangle",
				"[color=%s]▲ Advantage[/color]" % COLOR_ADVANTAGE)
		"disadvantage":
			return _link(side, "triangle", "Weapon Triangle",
				"[color=%s]▼ Disadvantage[/color]" % COLOR_DISADVANTAGE)
		_:
			return _link(side, "triangle", "Weapon Triangle",
				"[color=%s]■ Neutral[/color]" % COLOR_NEUTRAL)


# Effectiveness marker. Mult is included so the player can tell Giantkiller's
# 4× apart from the standard 3× effective bonus.
func _effective_link(side: String, is_effective: bool, mult: float) -> String:
	if is_effective:
		return _link(side, "effectiveness", "Effectiveness",
			"[color=%s]Effective ×%d[/color]" % [COLOR_EFFECTIVE, int(round(mult))])
	return _link(side, "effectiveness", "Effectiveness",
		"[color=%s]■ Neutral[/color]" % COLOR_NEUTRAL)


# Resets the side panel to its "nothing selected yet" hint state.
func _reset_info_panel() -> void:
	_info_title.text = "More Info"
	_info_hint.visible = true
	_info_desc.text = ""


func _refresh_forecast_row_heights() -> void:
	for label in _all_forecast_rows():
		if label.text == "":
			label.custom_minimum_size.y = 0.0
			continue
		# Forecast rows are authored as single-line values. Keep a stable
		# one-line minimum height instead of letting fit_content drive the
		# whole panel size from RichTextLabel internals.
		label.custom_minimum_size.y = _measure_forecast_row_height(label)


func _measure_forecast_row_height(label: RichTextLabel) -> float:
	var font: Font = label.get_theme_default_font()
	if font == null:
		return 20.0
	return ceilf(font.get_height(label.get_theme_default_font_size()) + FORECAST_ROW_PADDING_Y)


# Shortens `name` with a trailing ellipsis so it plus `suffix` fits on one line
# in a forecast column. RichTextLabel has no built-in overrun ellipsis, so we
# measure against the column width and trim by hand. Returns the (possibly
# truncated) name only — the caller re-wraps it in the [url] link and appends
# any suffix. If the font can't be measured the full name is returned and the
# label's clip falls back to a hard cut.
func _fit_name_to_column(p_name: String, suffix: String, label: RichTextLabel) -> String:
	var font: Font = label.get_theme_default_font()
	if font == null:
		return p_name
	var font_size: int = label.get_theme_default_font_size()
	var budget: float = FORECAST_COLUMN_MIN_WIDTH - NAME_FIT_PADDING_X
	budget -= font.get_string_size(suffix, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if font.get_string_size(p_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= budget:
		return p_name
	var ellipsis_w: float = font.get_string_size(NAME_ELLIPSIS, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var fitted: String = ""
	for i in p_name.length():
		var candidate: String = p_name.substr(0, i + 1)
		if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + ellipsis_w > budget:
			break
		fitted = candidate
	# Drop a trailing space so the ellipsis reads as "Name…" not "Name …".
	return fitted.strip_edges(false, true) + NAME_ELLIPSIS


func _size_panel_to_content() -> void:
	_panel.reset_size()
	var min_size: Vector2 = _panel.get_combined_minimum_size()
	min_size.x = maxf(min_size.x, FORECAST_COLUMN_MIN_WIDTH * 2.0 + INFO_COLUMN_MIN_WIDTH)
	# Height is deliberately NOT taken from get_combined_minimum_size(): on the
	# first show that height is still settling and reads inflated, and pinning it
	# into offset_bottom freezes the over-tall panel. Seed a stable default and
	# let PanelContainer's own minimum-size pass grow the panel to fit the rows
	# (it already enforces its content minimum, so tall previews never clip).
	min_size.y = PANEL_DEFAULT_HEIGHT
	_panel.offset_right = _panel.offset_left + min_size.x
	_panel.offset_bottom = _panel.offset_top + min_size.y


# Parses the [url=...] meta. Expected shape: "combat_field:atk:hit" — a
# three-segment colon-delimited key carrying category, side, and field.
func _on_entry_clicked(meta: Variant) -> void:
	var s: String = String(meta)
	var parts: PackedStringArray = s.split(":")
	if parts.size() != 3:
		return
	var side: String = parts[1]
	var key: String = parts[2]
	for i in _entries.size():
		var e: Dictionary = _entries[i]
		if e["side"] == side and e["key"] == key:
			_current_index = i
			_show_entry(e)
			return


func _show_entry(entry: Dictionary) -> void:
	_info_title.text = String(entry["title"])
	_info_hint.visible = false
	var desc: String = MoreInfoContent.describe("combat_field", String(entry["key"]))
	# Name rows can be ellipsised in the column, so lead the description with the
	# full name — this is where the player reads a name that didn't fit.
	if String(entry["key"]) == "name":
		var full_name: String = _atk_full_name if String(entry["side"]) == "atk" else _def_full_name
		desc = "%s\n\n%s" % [full_name, desc]
	# The Damage field carries the follow-up (×N attacks) outcome, so append the
	# Battle Speed comparison and threshold there — the values the tester needed to
	# verify doubling (handbook 8.3).
	if String(entry["key"]) == "damage":
		desc = "%s\n\n%s" % [desc, _battle_speed_note()]
	_info_desc.text = desc


# Builds the Battle Speed / follow-up line shown under the Damage field's More
# Info. Shows BOTH sides' Battle Speed and the threshold; notes who (if anyone)
# earns a follow-up. Defender speed is shown even when it cannot counter
# (playtest v0.1.5.0 #8.3): the value is still informative, and the attacker can
# still double a non-countering defender, so the comparison is meaningful. When
# the defender can't counter it simply never attacks, so it can't follow up
# regardless of its speed — that is called out in the note rather than hidden.
func _battle_speed_note() -> String:
	var diff: int = _atk_battle_speed - _def_battle_speed
	var who: String = ""
	if not _can_counter:
		# Only the attacker can follow up here; the defender deals no strikes.
		who = "Attacker follows up." if diff >= _follow_up_threshold else "No follow-up."
		return "Battle Speed — Attacker %d vs Defender %d.\nNeeds +%d to follow up. %s (defender cannot counter)" % [
			_atk_battle_speed, _def_battle_speed, _follow_up_threshold, who]
	if diff >= _follow_up_threshold:
		who = "Attacker follows up."
	elif -diff >= _follow_up_threshold:
		who = "Defender follows up."
	else:
		who = "No follow-up."
	return "Battle Speed — Attacker %d vs Defender %d.\nNeeds +%d to follow up. %s" % [
		_atk_battle_speed, _def_battle_speed, _follow_up_threshold, who]


# Advances through _entries. First press shows the first entry; subsequent
# presses move forward one and wrap. Same semantics as UnitDetailsScreen so
# the player only has to learn one F behaviour across both surfaces.
func _cycle_more_info() -> void:
	if _entries.is_empty():
		return
	_current_index = (_current_index + 1) % _entries.size()
	_show_entry(_entries[_current_index])


func _unhandled_input(event: InputEvent) -> void:
	# Priority 1 in the More Info chain: when the preview is visible the F
	# action belongs to the preview, not the character sheet or terrain HUD.
	# Consuming the event here keeps both implicit (the other handlers also
	# guard on `visible`) and explicit (they receive set_input_as_handled).
	if not visible:
		return
	if event.is_action_pressed("more_info"):
		get_viewport().set_input_as_handled()
		_cycle_more_info()


# ── Positioning helpers (unchanged from 2026-05-24d) ──────────────────────


func _reposition_for(defender: Node) -> void:
	if defender == null or not is_instance_valid(defender) or _camera == null:
		return
	if not (defender is Node2D):
		return
	# PanelContainer doesn't always report its minimum size until after a
	# layout pass; reset_size() forces it to recompute from current content.
	var panel_size: Vector2 = _panel.size
	if panel_size == Vector2.ZERO:
		panel_size = _panel.get_combined_minimum_size()
	var view: Vector2 = get_viewport_rect().size
	# On-screen size of one tile = world TILE_SIZE × camera zoom. defender_screen below
	# is already in canvas/screen space (the canvas transform bakes in camera zoom), so
	# the offset beside it must be the *screen* tile size, not the raw world constant —
	# otherwise the panel sits too far/near the defender at any zoom != 1 (Display &
	# Accessibility item 1d).
	var zoom_x: float = _camera.zoom.x if _camera != null and _camera.zoom.x > 0.0 else 1.0
	var tile_px: float = float(GameConstants.TILE_SIZE) * zoom_x
	var defender_screen: Vector2 = (defender as Node2D).get_global_transform_with_canvas().origin

	var right_left: float = defender_screen.x + tile_px + PANEL_MARGIN_PX
	var left_left: float  = defender_screen.x - PANEL_MARGIN_PX - panel_size.x
	var panel_left: float = right_left
	if right_left + panel_size.x > view.x - PANEL_MARGIN_PX:
		if left_left >= PANEL_MARGIN_PX:
			panel_left = left_left
		else:
			var max_right_left: float = view.x - PANEL_MARGIN_PX - panel_size.x
			var pan_x: float = right_left - max_right_left
			if pan_x > 0 and _camera_ctrl != null and _camera_ctrl.has_method("pan_by_pixels"):
				_camera_ctrl.pan_by_pixels(Vector2(pan_x, 0))
				defender_screen = (defender as Node2D).get_global_transform_with_canvas().origin
				panel_left = defender_screen.x + tile_px + PANEL_MARGIN_PX
			panel_left = min(panel_left, view.x - PANEL_MARGIN_PX - panel_size.x)
			panel_left = max(panel_left, PANEL_MARGIN_PX)

	var panel_top: float = defender_screen.y + tile_px * 0.5 - panel_size.y * 0.5
	panel_top = clampf(panel_top, PANEL_MARGIN_PX, view.y - panel_size.y - PANEL_MARGIN_PX)

	# Nudge the panel clear of the HUD panels and the defender tile before committing
	# the position. Degrades to the plain viewport clamp when the HUD isn't reachable.
	var avoid: Array[Rect2] = _hud_avoid_rects()
	avoid.append(_defender_avoid_rect(defender_screen, tile_px))
	var placed: Vector2 = _place_clear_of(Vector2(panel_left, panel_top), panel_size,
		view, avoid, float(PANEL_MARGIN_PX))

	_panel.position = placed
	_panel.offset_right = _panel.offset_left + panel_size.x
	_panel.offset_bottom = _panel.offset_top + panel_size.y


# Screen-space rects of the visible HUD panels the combat preview should not cover.
# Read live from the HUD (a sibling CanvasLayer, so its Control rects are already in
# the same screen space as the preview). Returns [] — i.e. no avoidance, plain
# viewport clamp — when the HUD or a panel is absent/hidden, so this never hard-fails.
func _hud_avoid_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var hud := get_node_or_null("../../HUDMainLayer/HUD")
	if hud == null:
		return out
	for panel_name in ["ObjectivePanel", "UnitInfoPanel", "TerrainCorner"]:
		var p := hud.get_node_or_null(panel_name)
		if p != null and p is Control and (p as Control).visible:
			var r: Rect2 = (p as Control).get_global_rect()
			if r.size.x > 0.0 and r.size.y > 0.0:
				out.append(r)
	return out


static func _defender_avoid_rect(defender_screen: Vector2, tile_px: float) -> Rect2:
	return Rect2(defender_screen, Vector2(tile_px, tile_px))


# Pure placement helper (no node access, so it is unit-testable): start from `pos`
# and, for each `avoid` rect the panel overlaps, slide it vertically clear — above
# the rect when there is room, otherwise below, preferring the smaller move. The
# result is always re-clamped inside `view`. A panel too tall to clear a rect is
# left where it is (clamped); avoidance is best-effort, never off-screen.
static func _place_clear_of(pos: Vector2, panel_size: Vector2, view: Vector2,
		avoid: Array[Rect2], margin: float) -> Vector2:
	var rect := Rect2(pos, panel_size)
	for a in avoid:
		if not rect.intersects(a):
			continue
		var above_y: float = a.position.y - panel_size.y - margin
		var below_y: float = a.position.y + a.size.y + margin
		var above_ok: bool = above_y >= margin
		var below_ok: bool = below_y + panel_size.y <= view.y - margin
		if above_ok and (not below_ok \
				or absf(above_y - rect.position.y) <= absf(below_y - rect.position.y)):
			rect.position.y = above_y
		elif below_ok:
			rect.position.y = below_y
	rect.position.x = clampf(rect.position.x, margin, maxf(margin, view.x - panel_size.x - margin))
	rect.position.y = clampf(rect.position.y, margin, maxf(margin, view.y - panel_size.y - margin))
	return rect.position
