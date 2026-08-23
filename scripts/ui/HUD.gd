extends Control
# Persistent HUD overlay: phase label, turn counter, unit info panel, terrain info panel.
# Connects to EventBus signals; reads GridManager for terrain data.
#
# Phase 1 More Info terminal host (see
# [GDD-07-SCREENS-PANELS]): when no higher-priority
# More Info panel is open, pressing `more_info` (F) toggles the terrain
# panel into an expanded mode that adds the terrain description, common
# movement-group costs, and the tile actions the currently-selected unit
# could perform on this tile. Priority chain (last winner): combat preview
# → character sheet → terrain HUD.

const MoreInfoContent = preload("res://scripts/shared/MoreInfoContent.gd")
const TileActions = preload("res://scripts/shared/TileActions.gd")
const SelectionCursor = preload("res://scripts/ui/SelectionCursor.gd")
const InputDisplay = preload("res://scripts/shared/InputDisplay.gd")

@onready var _phase_label: Label = $PhaseLabel
@onready var _turn_label: Label = $TurnLabel
@onready var _unit_panel: PanelContainer = $UnitInfoPanel
@onready var _unit_name: Label = $UnitInfoPanel/VBox/UnitName
@onready var _unit_class: Label = $UnitInfoPanel/VBox/UnitClass
@onready var _unit_hp: Label = $UnitInfoPanel/VBox/UnitHP
@onready var _unit_weapon: Label = $UnitInfoPanel/VBox/UnitWeapon
# Basic stats box (always visible) lives in the bottom of the corner stack.
@onready var _terrain_panel: PanelContainer = $TerrainCorner/TerrainInfoPanel
@onready var _terrain_name: Label = $TerrainCorner/TerrainInfoPanel/VBox/TerrainName
@onready var _terrain_coord: Label = $TerrainCorner/TerrainInfoPanel/VBox/TerrainCoord
@onready var _terrain_def: Label = $TerrainCorner/TerrainInfoPanel/VBox/TerrainDef
@onready var _terrain_dodge: Label = $TerrainCorner/TerrainInfoPanel/VBox/TerrainDodge
@onready var _terrain_hint: Label = $TerrainCorner/TerrainInfoPanel/VBox/TerrainHint
# Separate, scrollable More Info box that appears above the basic box when
# expanded. The rows live inside its bounded ScrollContainer.
@onready var _terrain_more_panel: PanelContainer = $TerrainCorner/TerrainMoreInfoPanel
@onready var _terrain_scroll: ScrollContainer = $TerrainCorner/TerrainMoreInfoPanel/Scroll
@onready
var _terrain_desc: RichTextLabel = $TerrainCorner/TerrainMoreInfoPanel/Scroll/VBox/TerrainDescription
@onready
var _terrain_moves: RichTextLabel = $TerrainCorner/TerrainMoreInfoPanel/Scroll/VBox/TerrainMoveCosts
@onready
var _terrain_actions: RichTextLabel = $TerrainCorner/TerrainMoreInfoPanel/Scroll/VBox/TerrainActions
# Red "DEBUG MODE" banner — shown only in debug builds (see _setup_debug_banner).
@onready var _debug_label: Label = $DebugLabel
# M16 stage 4: objective readout for the current player (blue) — listed
# from MapData.victory_conditions["allies"]. Populated by setup().
@onready var _objective_panel: PanelContainer = $ObjectivePanel
@onready var _objective_list: Label = $ObjectivePanel/VBox/ObjectiveList

var _turn: int = 1
var _grid: Node = null  # GridManager reference, set by GameMap
var _turn_manager: Node = null  # TurnManager — needed for tile-action gates in expanded mode
var _attack_preview: Node = null  # More Info priority 1 host, injected by GameMap
var _unit_details_screen: Node = null  # More Info priority 2 host, injected by GameMap
var _unit_is_selected: bool = false  # true while a player unit is actively selected
var _selected_unit: Node = null  # the actively selected unit (fallback for empty tiles during selection — playtest 3 #6)
var _cursor_tile: Vector2i = Vector2i(-1, -1)  # last tile reported by cursor_moved
var _displayed_unit: Node = null  # unit currently shown in the info panel (null when hidden)
# Terrain More Info paging (V021-05). The `more_info` action (F) cycles the terrain
# More Info surface through Hidden → Description → Movement → Hidden when no
# higher-priority More Info panel is visible. "Hidden" fully hides the box (frees map
# area); the compact terrain readout stays visible throughout. Logical pages: each
# page shows a subset of the existing expanded rows, so the panel auto-sizes to the
# active page and the reflow offset is derived from it (hardens the V021-02 reset bug).
const TERRAIN_PAGE_HIDDEN: int = -1
const TERRAIN_PAGE_DESCRIPTION: int = 0
const TERRAIN_PAGE_MOVEMENT: int = 1
const TERRAIN_PAGE_COUNT: int = 2
# _terrain_more_page mirrors _terrain_pager.index and is what every reader/test uses.
# The pager is the shared SelectionCursor with the inactive (-1 = Hidden) stop enabled,
# so the terrain pager, the sheet grid, and the forecast list all navigate through one
# core — the single point the gamepad d-pad wiring attaches to (B6-INPUT selector
# adoption). configure() runs in _ready; advance() runs in cycle_terrain_more_page().
var _terrain_more_page: int = TERRAIN_PAGE_HIDDEN
var _terrain_pager: RefCounted = SelectionCursor.new()

# Dynamically-created mastery label — lives in UnitInfoPanel/VBox, separate from equipped skills.
# Populated by _show_unit(); nil until a unit with mastery is first displayed.
var _mastery_label: Label = null

# Dynamically-created Pair Up bonus label (same no-scene-edit pattern as mastery).
# Shows the support's contribution when a paired LEAD is displayed.
var _pairup_label: Label = null

# ── Per-panel HUD layout (Display & Accessibility item 4) ─────────────────────
# Stable panel ids the player can reposition/scale. Order is the editor cycle order.
const LAYOUT_PANEL_IDS: Array[String] = [
	"phase_label",
	"turn_label",
	"unit_info",
	"objective",
	"terrain_corner",
]
# Per-panel scale clamp — small enough to declutter, large enough to read, without
# letting a panel balloon off-screen.
const MIN_PANEL_SCALE: float = 0.5
const MAX_PANEL_SCALE: float = 2.0
const HUD_LAYOUT_SCHEMA_VERSION: int = 2
const ATTACHMENT_IDS: Array[String] = [
	"top_left", "top", "top_right", "left", "right", "bottom_left", "bottom", "bottom_right"
]
const DEFAULT_ATTACHMENTS := {
	"phase_label": ["top_left", "top_left", Vector2(8, 8)],
	"turn_label": ["top_right", "top_right", Vector2(-8, 8)],
	"unit_info": ["bottom_left", "bottom_left", Vector2(8, -78)],
	"objective": ["top_left", "top_left", Vector2(8, 48)],
	"terrain_corner": ["bottom_right", "bottom_right", Vector2(-8, -8)],
}
var _active_layout: Dictionary = {}
var _layout_reflow_queued := false


func _ready() -> void:
	# Discoverable by the in-map "Edit HUD Layout" launcher without a hard node path.
	add_to_group("hud")
	# The terrain pager cycles Hidden(-1) → Description(0) → Movement(1) → Hidden.
	# has_inactive=true makes -1 a real stop in the cycle (matching the old int wrap).
	_terrain_pager.configure(TERRAIN_PAGE_COUNT, 1, true, true)
	_terrain_pager.changed.connect(_on_terrain_page_changed)
	# Prompt/glyph swapping (B6-INPUT): re-render the compact terrain "press F / press X"
	# hint when the input scheme changes. Guarded so headless scenes stay inert.
	var imm := get_node_or_null("/root/InputModeManager")
	if imm != null and imm.has_signal("input_mode_changed"):
		imm.connect("input_mode_changed", _on_input_mode_changed)
	_refresh_terrain_hint()
	_unit_panel.hide()
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.cursor_moved.connect(_on_cursor_moved)
		bus.phase_changed.connect(_on_phase_changed)
		bus.unit_selected.connect(_on_unit_selected)
		bus.unit_deselected.connect(_on_unit_deselected)
		# Live-refresh the info panel when the displayed unit's HP changes.
		bus.unit_damaged.connect(_on_unit_hp_changed)
		bus.unit_healed.connect(_on_unit_hp_changed)
		# Drop the panel when the displayed unit dies — its node is about to be freed.
		bus.unit_died.connect(_on_unit_died)
	_update_turn_label()
	_on_phase_changed(GameState.Phase.PLAYER, "blue")
	_setup_debug_banner()
	# Apply the saved per-panel layout after the first layout pass has settled, so
	# the captured base positions reflect the authored offsets (item 4).
	call_deferred("_apply_saved_layout")
	get_viewport().size_changed.connect(_queue_layout_reflow)


func setup(
	grid: Node, turn_node: Node, attack_preview: Node = null, unit_details_screen: Node = null
) -> void:
	_grid = grid
	_turn_manager = turn_node
	_attack_preview = attack_preview
	_unit_details_screen = unit_details_screen
	if turn_node:
		turn_node.turn_changed.connect(_on_turn_changed)
	# M16 stage 4: populate the objective readout from the active map's blue-group
	# conditions, plus any legacy fields (which translate to blue group at the
	# TurnManager evaluator). Render-only — no live re-evaluation needed since
	# conditions are static for the duration of a map.
	_populate_objective_panel()


# ── Per-panel HUD layout (item 4) ─────────────────────────────────────────────


# Resolves a stable panel id to its live Control node.
func get_layout_panel(panel_id: String) -> Control:
	match panel_id:
		"phase_label":
			return _phase_label
		"turn_label":
			return _turn_label
		"unit_info":
			return _unit_panel
		"objective":
			return _objective_panel
		"terrain_corner":
			return get_node_or_null("TerrainCorner")
	return null


# Applies the version-2 attachment layout. Legacy absolute-offset layouts without a
# reference viewport fall back to authored attachments: guessing across resolutions
# would preserve neither intent nor reachability.
func apply_layout(layout: Dictionary) -> void:
	_active_layout = _normalize_layout(layout)
	var entries: Dictionary = _active_layout["panels"]
	for id in LAYOUT_PANEL_IDS:
		var panel := get_layout_panel(id)
		if panel == null:
			continue
		var entry: Dictionary = entries[id]
		var offset: Vector2 = entry["offset"]
		var scale_f: float = entry["scale"]
		panel.scale = Vector2.ONE * clampf(scale_f, MIN_PANEL_SCALE, MAX_PANEL_SCALE)
		panel.position = _position_for_attachments(panel, entry, offset)


# Loads the saved layout from SettingsManager and applies it. Called deferred from
# _ready (post-layout) and re-runnable by the editor.
func _apply_saved_layout() -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	apply_layout(sm.hud_layout if sm != null else {})


# Clamps the full scaled panel inside the safe viewport.
func _clamp_panel_on_screen(panel: Control, pos: Vector2) -> Vector2:
	var safe_rect := _safe_viewport_rect()
	var sz: Vector2 = panel.size * panel.scale
	pos.x = clampf(pos.x, safe_rect.position.x, maxf(safe_rect.end.x - sz.x, safe_rect.position.x))
	pos.y = clampf(pos.y, safe_rect.position.y, maxf(safe_rect.end.y - sz.y, safe_rect.position.y))
	return pos


func _safe_viewport_rect() -> Rect2:
	var view := get_viewport_rect().size
	var insets := _safe_area_insets()
	return Rect2(
		Vector2(insets.x, insets.y),
		Vector2(maxf(view.x - insets.x - insets.z, 0.0), maxf(view.y - insets.y - insets.w, 0.0))
	)


# Reads the single safe-area provider (SettingsManager). Returns ZERO when the
# autoload is absent (headless paths that build the HUD without it) so desktop and
# tests are unaffected.
func _safe_area_insets() -> Vector4i:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm != null and sm.has_method("get_safe_area_insets"):
		return sm.call("get_safe_area_insets")
	return Vector4i.ZERO


# Live single-panel edit used by the layout editor: sets one panel's offset (from its
# base) + scale without disturbing the others. Returns the clamped on-screen position.
func set_panel_layout(panel_id: String, offset: Vector2, scale_f: float) -> Vector2:
	var panel := get_layout_panel(panel_id)
	if panel == null:
		return Vector2.ZERO
	if _active_layout.is_empty():
		_active_layout = _normalize_layout({})
	var entry: Dictionary = _active_layout["panels"][panel_id]
	entry["offset"] = offset
	entry["scale"] = clampf(scale_f, MIN_PANEL_SCALE, MAX_PANEL_SCALE)
	panel.scale = Vector2.ONE * clampf(scale_f, MIN_PANEL_SCALE, MAX_PANEL_SCALE)
	panel.position = _position_for_attachments(panel, entry, offset)
	return panel.position


func set_panel_attachments(
	panel_id: String, panel_attachment: String, viewport_attachment: String
) -> void:
	if panel_id not in LAYOUT_PANEL_IDS:
		return
	if panel_attachment not in ATTACHMENT_IDS or viewport_attachment not in ATTACHMENT_IDS:
		return
	# Same two guards its sibling set_panel_layout carries: a panel id can be valid and
	# still have no node (a HUD built without that panel), and the editor can reach this
	# before the deferred _apply_saved_layout has populated _active_layout. Both
	# unguarded paths were a crash, not a no-op.
	var panel := get_layout_panel(panel_id)
	if panel == null:
		return
	if _active_layout.is_empty():
		_active_layout = _normalize_layout({})
	var current_position := panel.position
	var entry: Dictionary = _active_layout["panels"][panel_id]
	entry["panel_attachment"] = panel_attachment
	entry["viewport_attachment"] = viewport_attachment
	entry["offset"] = _offset_for_position(panel, entry, current_position)
	apply_layout(_active_layout)


# Builds the current layout dict (offset from base + scale) for panels that differ
# from their authored layout — the shape persisted to SettingsManager.hud_layout.
func current_layout() -> Dictionary:
	return (
		_active_layout.duplicate(true) if not _active_layout.is_empty() else _normalize_layout({})
	)


# Restores every panel to its authored base layout (offset 0, scale 1).
func reset_layout() -> void:
	apply_layout({})


func _normalize_layout(layout: Dictionary) -> Dictionary:
	var source: Dictionary = {}
	if int(layout.get("schema_version", 0)) == HUD_LAYOUT_SCHEMA_VERSION:
		var raw: Variant = layout.get("panels", {})
		if raw is Dictionary:
			source = raw
	var panels := {}
	for id in LAYOUT_PANEL_IDS:
		var defaults: Array = DEFAULT_ATTACHMENTS[id]
		var entry := {
			"panel_attachment": defaults[0],
			"viewport_attachment": defaults[1],
			"offset": defaults[2],
			"scale": 1.0,
		}
		var raw_entry: Variant = source.get(id, {})
		if raw_entry is Dictionary:
			var candidate := raw_entry as Dictionary
			var panel_attachment := String(
				candidate.get("panel_attachment", entry.panel_attachment)
			)
			var viewport_attachment := String(
				candidate.get("viewport_attachment", entry.viewport_attachment)
			)
			if panel_attachment in ATTACHMENT_IDS:
				entry.panel_attachment = panel_attachment
			if viewport_attachment in ATTACHMENT_IDS:
				entry.viewport_attachment = viewport_attachment
			if candidate.get("offset") is Vector2:
				entry.offset = candidate.offset
			if candidate.get("scale") is float or candidate.get("scale") is int:
				entry.scale = clampf(float(candidate.scale), MIN_PANEL_SCALE, MAX_PANEL_SCALE)
		panels[id] = entry
	return {
		"schema_version": HUD_LAYOUT_SCHEMA_VERSION,
		"reference_viewport": get_viewport_rect().size,
		"panels": panels,
	}


func _position_for_attachments(panel: Control, entry: Dictionary, offset: Vector2) -> Vector2:
	var safe_rect := _safe_viewport_rect()
	var viewport_point := (
		safe_rect.position + _attachment_point(safe_rect.size, String(entry.viewport_attachment))
	)
	var panel_point := _attachment_point(panel.size * panel.scale, String(entry.panel_attachment))
	return _clamp_panel_on_screen(panel, viewport_point + offset - panel_point)


func _offset_for_position(panel: Control, entry: Dictionary, position: Vector2) -> Vector2:
	var safe_rect := _safe_viewport_rect()
	var viewport_point := (
		safe_rect.position + _attachment_point(safe_rect.size, String(entry.viewport_attachment))
	)
	var panel_point := _attachment_point(panel.size * panel.scale, String(entry.panel_attachment))
	return position + panel_point - viewport_point


static func _attachment_point(size: Vector2, attachment: String) -> Vector2:
	var x := {
		"top_left": 0.0,
		"left": 0.0,
		"bottom_left": 0.0,
		"top": 0.5,
		"bottom": 0.5,
		"top_right": 1.0,
		"right": 1.0,
		"bottom_right": 1.0
	}
	var y := {
		"top_left": 0.0,
		"top": 0.0,
		"top_right": 0.0,
		"left": 0.5,
		"right": 0.5,
		"bottom_left": 1.0,
		"bottom": 1.0,
		"bottom_right": 1.0
	}
	return Vector2(float(x.get(attachment, 0.0)), float(y.get(attachment, 0.0))) * size


func _queue_layout_reflow() -> void:
	if _layout_reflow_queued:
		return
	_layout_reflow_queued = true
	_reflow_layout.call_deferred()


func _reflow_layout() -> void:
	_layout_reflow_queued = false
	if not _active_layout.is_empty():
		apply_layout(_active_layout)


func _populate_objective_panel() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs == null or gs.map_data == null or _objective_panel == null:
		return
	var lines: Array[String] = _build_objective_lines(gs.map_data)
	if lines.is_empty():
		_objective_panel.hide()
		return
	_objective_list.text = "\n".join(lines)
	_objective_panel.show()


# Returns the display lines for the local player (blue's alliance group):
# a "Win:" header followed by every victory-condition summary, then a "Lose:"
# header followed by every defeat-condition summary. Each header is only
# emitted when at least one matching condition exists, so a map with no
# defeats authored doesn't show an empty "Lose:" group.
func _build_objective_lines(map_data: Resource) -> Array[String]:
	var gs := get_node_or_null("/root/GameState")
	var blue_group: String = "allies"
	if gs:
		blue_group = gs.get_alliance_group("blue")
	var win_lines: Array[String] = []
	var lose_lines: Array[String] = []
	for cond in _conditions_for(map_data.victory_conditions, blue_group):
		var s: String = cond.get_display_text()
		if s != "":
			win_lines.append("  " + s)
	for cond in _conditions_for(map_data.defeat_conditions, blue_group):
		var s: String = cond.get_display_text()
		if s != "":
			lose_lines.append("  " + s)
	var out: Array[String] = []
	if not win_lines.is_empty():
		out.append("Win:")
		out.append_array(win_lines)
	if not lose_lines.is_empty():
		out.append("Lose:")
		out.append_array(lose_lines)
	return out


func _conditions_for(dict: Dictionary, group: String) -> Array:
	var raw: Variant = dict.get(group, null)
	if raw is Array:
		return raw
	return []


func _on_phase_changed(new_phase: int, faction_id: String = "") -> void:
	if faction_id == "":
		faction_id = "blue" if new_phase == GameState.Phase.PLAYER else _active_faction_id()
	var label: String = _faction_phase_label(faction_id)
	_phase_label.text = "%s PHASE" % label.to_upper()


func _active_faction_id() -> String:
	var turn := get_node_or_null("/root/GameMap/TurnManager")
	if turn != null and turn.has_method("active_faction"):
		var fid: String = turn.active_faction()
		if fid != "":
			return fid
	return "red"


func _faction_phase_label(faction_id: String) -> String:
	var gs := get_node_or_null("/root/GameState")
	var md: Resource = gs.map_data if gs != null else null
	if md != null:
		var faction: FactionData = md.get_faction(faction_id)
		if faction != null:
			return faction.get_phase_label()
	return "Unknown" if faction_id == "" else FactionData.default_phase_label(faction_id)


func _on_turn_changed(turn_number: int) -> void:
	_turn = turn_number
	_update_turn_label()


func _on_unit_selected(unit: Node) -> void:
	_unit_is_selected = true
	_selected_unit = unit
	_show_unit(unit)


func _on_unit_deselected() -> void:
	_unit_is_selected = false
	_selected_unit = null
	# After deselection, show whatever unit the cursor is currently over (if any)
	_show_unit(_grid.get_unit_at(_cursor_tile) if _grid != null and _cursor_tile.x >= 0 else null)


# Always prefer the unit the cursor is on — including enemies/allies during
# attack and staff targeting (playtest 3 #6). Only when the cursor sits on an
# empty tile mid-selection do we fall back to the actively selected unit, so
# the player doesn't lose sight of who is acting between target candidates.
func _on_cursor_moved(tile: Vector2i) -> void:
	_cursor_tile = tile
	_update_terrain(tile)
	var hovered: Node = _grid.get_unit_at(tile) if _grid != null else null
	if hovered != null:
		_show_unit(hovered)
	elif _unit_is_selected:
		_show_unit(_selected_unit)
	else:
		_show_unit(null)


# Refreshes the info panel if the unit whose HP changed is the one on display.
# amount is unused — _show_unit re-reads HP straight from unit.data.
func _on_unit_hp_changed(unit: Node, _amount: int) -> void:
	if unit != null and unit == _displayed_unit:
		_show_unit(unit)


# Hides the info panel if the unit that just died is the one on display, so the
# panel never holds a stale reference to a freed node.
func _on_unit_died(unit: Node) -> void:
	if unit != null and unit == _displayed_unit:
		_show_unit(null)


func _show_unit(unit: Node) -> void:
	if unit == null or unit.data == null:
		_displayed_unit = null
		_unit_panel.hide()
		return
	_displayed_unit = unit
	_unit_name.text = unit.data.unit_name
	_unit_class.text = "%s  Lv %d" % [unit.data.class_id, int(unit.data.level)]
	_unit_hp.text = "HP %d / %d" % [unit.data.hp, unit.data.max_hp]
	var wpn: WeaponData = (
		unit.get_equipped_weapon() if unit.has_method("get_equipped_weapon") else null
	)
	_unit_weapon.text = wpn.display_name if wpn != null else "--"
	_update_mastery_display(unit)
	_update_pairup_display(unit)
	_unit_panel.show()


# Shows which weapon types the unit has at S-rank in a dedicated mastery line.
# Uses a dynamically-created Label so no scene edits are required.
func _update_mastery_display(unit: Node) -> void:
	if unit.data == null or unit.data.mastery_skills.is_empty():
		if _mastery_label != null:
			_mastery_label.hide()
		return
	var s_rank_types: Array[String] = []
	for track in unit.data.weapon_wexp.keys():
		if unit.get_weapon_rank(String(track)) == "S":
			s_rank_types.append(String(track).capitalize())
	if s_rank_types.is_empty():
		if _mastery_label != null:
			_mastery_label.hide()
		return
	# Create the label once and reuse it.
	if _mastery_label == null:
		_mastery_label = Label.new()
		_mastery_label.name = "MasteryLabel"
		$UnitInfoPanel/VBox.add_child(_mastery_label)
	_mastery_label.text = "Mastery  " + ", ".join(s_rank_types)
	_mastery_label.show()


# Shows the Pair Up support bonus on a paired lead's info panel. The bonus is a
# combat-only modifier — it never lives in active_modifiers outside a fight — so
# the panel otherwise gives no sign the pairing does anything, which is exactly
# what the v0.1.4 tester reported (#8.5). Query PairUpBonusResolver on demand.
func _update_pairup_display(unit: Node) -> void:
	var text: String = _pairup_bonus_text(unit)
	if text == "":
		if _pairup_label != null:
			_pairup_label.hide()
		return
	if _pairup_label == null:
		_pairup_label = Label.new()
		_pairup_label.name = "PairUpLabel"
		$UnitInfoPanel/VBox.add_child(_pairup_label)
	_pairup_label.text = text
	_pairup_label.show()


# "Support: <name>" for a paired LEAD, else "". Only the lead is shown (the support
# sits off-map and is never the displayed unit). V021-07: the per-stat bonus deltas
# were dropped from the *map* HUD — they crowded the panel and pushed the support
# name off the screen edge — so the line names only the support partner. The full
# per-stat breakdown still lives on the `I` character sheet (via StatContributions).
func _pairup_bonus_text(unit: Node) -> String:
	if unit == null or unit.data == null or unit.data.unit_id == "":
		return ""
	var reg := get_node_or_null("/root/PairUpRegistry")
	if reg == null or not bool(reg.call("is_lead", unit.data.unit_id)):
		return ""
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return ""
	var support: Node = gs.call("find_unit_by_id", reg.call("get_partner_id", unit.data.unit_id))
	if support == null or support.data == null or String(support.data.unit_name) == "":
		return ""
	return "Support: %s" % support.data.unit_name


func _update_terrain(tile: Vector2i) -> void:
	if _grid == null:
		return
	var terrain: String = _grid.get_terrain_at(tile)
	# Title the panel from the terrain's authored display_name rather than the raw id,
	# so a pack's retune actually reaches the player ([TER-10]). The registry falls back
	# to the capitalised id, which is what this line used to do unconditionally.
	_terrain_name.text = _grid.terrain_registry().display_name(terrain)
	# Player-facing coords are one-based — upper-left tile reads (1, 1). Internal
	# tile_position storage stays zero-based; this is display-only.
	_terrain_coord.text = "Tile (%d, %d)" % [tile.x + 1, tile.y + 1]
	# Read bonuses through GridManager's accessor rather than reaching into the
	# TERRAIN_*_BONUS dicts directly — GridManager owns the lookup contract (B1).
	var bonuses: Dictionary = _grid.get_terrain_bonuses(tile)
	_terrain_def.text = "DEF  +%d" % int(bonuses["def"])
	_terrain_dodge.text = "DODGE +%d" % int(bonuses["dodge"])
	# Compact view = the three lines above. The More Info box adds the paged content
	# (Description page / Movement page) when not hidden (V021-05).
	if _terrain_more_page >= 0:
		_render_terrain_page(tile, terrain)
	else:
		# Hidden: hide the whole More Info box so the map area behind it is reclaimed.
		# Row visibilities are kept in sync so anything reading them sees the off state.
		_terrain_more_panel.hide()
		_terrain_desc.visible = false
		_terrain_moves.visible = false
		_terrain_actions.visible = false
		_terrain_hint.visible = true
	_queue_layout_reflow()


# Cycles the terrain More Info surface Hidden → Description → Movement → Hidden
# (V021-05). Public so the mouse/touch mode (V021-17) can drive paging by click.
# Delegates to the shared cursor; the `changed` handler mirrors the page and
# re-renders. Sync-then-advance because callers/tests may set _terrain_more_page
# directly — production paging always flows through here, so it never desyncs.
func cycle_terrain_more_page() -> void:
	if _terrain_pager.index != _terrain_more_page:
		_terrain_pager.set_index(_terrain_more_page)
	_terrain_pager.advance(1)


# Cursor callback: mirror the active page and re-render against the current cursor
# tile so the transition is immediate (index -1 hides the box via _update_terrain).
func _on_terrain_page_changed(index: int) -> void:
	_terrain_more_page = index
	if _cursor_tile.x >= 0:
		_update_terrain(_cursor_tile)


# Re-render the compact terrain hint's key/glyph for the active input scheme.
func _on_input_mode_changed(_mode: String) -> void:
	_refresh_terrain_hint()


func _refresh_terrain_hint() -> void:
	if _terrain_hint != null:
		_terrain_hint.text = InputDisplay.more_info_hint(self, "")


func terrain_corner_contains_screen_position(screen_pos: Vector2) -> bool:
	var corner := get_layout_panel("terrain_corner")
	if corner == null or not corner.visible:
		return false
	if (
		_terrain_panel != null
		and _terrain_panel.visible
		and _terrain_panel.get_global_rect().has_point(screen_pos)
	):
		return true
	if (
		_terrain_more_panel != null
		and _terrain_more_panel.visible
		and _terrain_more_panel.get_global_rect().has_point(screen_pos)
	):
		return true
	return corner.get_global_rect().has_point(screen_pos)


# Renders the active More Info page. Each page shows a subset of the expanded rows
# so the panel sizes to the page in view (Description = blurb + tile actions;
# Movement = the move-cost table). Def/Dodge stay on the always-visible compact
# panel, so the movement page doesn't restate them.
func _render_terrain_page(tile: Vector2i, terrain: String) -> void:
	_terrain_more_panel.show()
	_terrain_hint.visible = false
	var on_description: bool = _terrain_more_page == TERRAIN_PAGE_DESCRIPTION
	var on_movement: bool = _terrain_more_page == TERRAIN_PAGE_MOVEMENT
	_terrain_desc.text = BBCode.escape(MoreInfoContent.describe("terrain", terrain))
	_terrain_desc.visible = on_description
	var actions_text: String = _format_tile_actions(tile)
	_terrain_actions.text = actions_text
	# Actions belong to the Description page, and only when there's something to say.
	_terrain_actions.visible = on_description and actions_text != ""
	_terrain_moves.text = _format_move_costs(terrain)
	_terrain_moves.visible = on_movement
	# Start each tile's page at the top so a long previous tile doesn't leave the box
	# scrolled past this tile's content.
	_terrain_scroll.scroll_vertical = 0


# Returns the BBCode block listing common movement-group costs for this
# terrain. Walls render "—" so the player sees they're impassable rather
# than a meaningless "999."
func _format_move_costs(terrain: String) -> String:
	const GridManagerS = preload("res://scripts/core/GridManager.gd")
	var costs: Dictionary = GridManagerS.get_move_costs_for_groups(terrain)
	var lines: Array[String] = ["Move cost:"]
	var group_labels: Array = [
		["foot", "Foot"],
		["mounted", "Mounted"],
		["armoured", "Armoured"],
		["light", "Light"],
		["flying", "Flying"],
	]
	for entry in group_labels:
		var key: String = entry[0]
		var label: String = entry[1]
		var c: int = int(costs.get(key, 1))
		var rendered: String = "—" if c >= GridManagerS.IMPASSABLE_MOVE_COST else str(c)
		lines.append("  %-9s %s" % [label, rendered])
	return "\n".join(lines)


# Returns the BBCode block listing available tile actions for the currently-
# selected unit. Empty when no unit is selected so the row collapses
# entirely. Uses TileActions so the list mirrors what ActionMenu would offer
# at the same tile.
func _format_tile_actions(tile: Vector2i) -> String:
	if _selected_unit == null:
		return ""
	var ids: Array[String] = TileActions.available_for(_selected_unit, tile, _turn_manager)
	if ids.is_empty():
		return ""
	var lines: Array[String] = ["Actions:"]
	for id in ids:
		lines.append("  %s" % BBCode.escape(TileActions.display_label(id)))
	return "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	# Priority 3 in the More Info chain: only act when no higher-priority
	# panel is visible. UnitDetailsScreen and AttackPreview both call
	# set_input_as_handled when they consume the event, which already
	# prevents this handler from firing in most cases; the explicit
	# visibility check below makes the priority safe against future tree-
	# order changes.
	if not event.is_action_pressed("more_info"):
		return
	if _higher_priority_more_info_visible():
		return
	get_viewport().set_input_as_handled()
	# Cycle Hidden → Description → Movement → Hidden (V021-05). The cycle re-renders
	# against the current cursor tile so the transition is immediate.
	cycle_terrain_more_page()


# True when the combat preview or unit-details screen is open — those are
# the priority-1 and priority-2 More Info hosts and own the F key while
# visible.
func _higher_priority_more_info_visible() -> bool:
	if _attack_preview != null and is_instance_valid(_attack_preview) and _attack_preview.visible:
		return true
	if (
		_unit_details_screen != null
		and is_instance_valid(_unit_details_screen)
		and _unit_details_screen.visible
	):
		return true
	return false


func _update_turn_label() -> void:
	_turn_label.text = "Turn %d" % _turn


# ── Debug-mode banner ────────────────────────────────────────────────────────
# A red "DEBUG MODE" label on the HUD whenever this is a debug build. It warns
# playtesters that debug aids (force-levelup, growth boost — see GameState) may
# be active and that on-screen stats may not reflect release behaviour. The
# banner also lists the *active* aids by name, refreshing live when a flag is
# toggled from the remote debugger via EventBus.debug_flags_changed.
# DEBUG AID — remove before release; see GDD_10_Roadmap.md § Pre-Release Cleanup.
func _setup_debug_banner() -> void:
	# Skip wiring entirely in release builds — the banner can never be shown and
	# the debug flags can never be flipped, so the signal connection would be
	# dead weight on the bus. The DebugLabel stays hidden by its tscn default.
	if not OS.is_debug_build():
		return
	# Listen for runtime flag toggles so the aid list stays current without polling.
	var bus := get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("debug_flags_changed"):
		bus.debug_flags_changed.connect(_refresh_debug_banner)
	_refresh_debug_banner()


# Re-reads the live debug-aid flags off GameState and repaints the banner. Used
# at startup and on every debug_flags_changed emit.
func _refresh_debug_banner() -> void:
	_apply_debug_banner(OS.is_debug_build(), _collect_active_debug_aids())


# Returns the short-name list of debug aids currently flipped on. Uses .get() so
# the HUD doesn't hard-fault if GameState is absent (headless test path).
func _collect_active_debug_aids() -> Array[String]:
	var aids: Array[String] = []
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return aids
	if gs.get("debug_force_levelup"):
		aids.append("force-levelup")
	if gs.get("debug_growth_boost"):
		aids.append("growth+300")
	if gs.get("debug_hotseat_override"):
		aids.append("hotseat-all")
	return aids


# Split from _setup_debug_banner so tests can drive the banner directly without
# depending on whether the test run is itself a debug build. `active_aids` is the
# short-name list rendered after the banner; empty = just "● DEBUG MODE".
func _apply_debug_banner(is_debug: bool, active_aids: Array[String] = []) -> void:
	if _debug_label == null:
		return
	_debug_label.visible = is_debug
	if not is_debug:
		# Don't leave a stale aid list on the hidden label — clearing keeps the
		# label state and visible state in sync.
		_debug_label.text = ""
		return
	if active_aids.is_empty():
		_debug_label.text = "● DEBUG MODE"
	else:
		_debug_label.text = "● DEBUG MODE — " + ", ".join(active_aids)
