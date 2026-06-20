extends Control
# Persistent HUD overlay: phase label, turn counter, unit info panel, terrain info panel.
# Connects to EventBus signals; reads GridManager for terrain data.
#
# Phase 1 More Info terminal host (see
# AGENT/Docs/more_info_mode_plan_2026-05-24.md): when no higher-priority
# More Info panel is open, pressing `more_info` (F) toggles the terrain
# panel into an expanded mode that adds the terrain description, common
# movement-group costs, and the tile actions the currently-selected unit
# could perform on this tile. Priority chain (last winner): combat preview
# → character sheet → terrain HUD.

const MoreInfoContent = preload("res://scripts/shared/MoreInfoContent.gd")
const TileActions     = preload("res://scripts/shared/TileActions.gd")

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
@onready var _terrain_desc: RichTextLabel = $TerrainCorner/TerrainMoreInfoPanel/Scroll/VBox/TerrainDescription
@onready var _terrain_moves: RichTextLabel = $TerrainCorner/TerrainMoreInfoPanel/Scroll/VBox/TerrainMoveCosts
@onready var _terrain_actions: RichTextLabel = $TerrainCorner/TerrainMoreInfoPanel/Scroll/VBox/TerrainActions
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
var _terrain_more_page: int = TERRAIN_PAGE_HIDDEN

# Dynamically-created mastery label — lives in UnitInfoPanel/VBox, separate from equipped skills.
# Populated by _show_unit(); nil until a unit with mastery is first displayed.
var _mastery_label: Label = null

# Dynamically-created Pair Up bonus label (same no-scene-edit pattern as mastery).
# Shows the support's contribution when a paired LEAD is displayed.
var _pairup_label: Label = null

# ── Per-panel HUD layout (Display & Accessibility item 4) ─────────────────────
# Stable panel ids the player can reposition/scale. Order is the editor cycle order.
const LAYOUT_PANEL_IDS: Array[String] = [
	"phase_label", "turn_label", "unit_info", "objective", "terrain_corner",
]
# Per-panel scale clamp — small enough to declutter, large enough to read, without
# letting a panel balloon off-screen.
const MIN_PANEL_SCALE: float = 0.5
const MAX_PANEL_SCALE: float = 2.0
# Minimum on-screen pixels kept visible on each axis so a panel can't be dragged
# (or saved) fully off the viewport.
const _MIN_VISIBLE_PX: float = 24.0
# panel_id → authored base position, captured once before any offset is applied so
# Reset restores the exact .tscn layout regardless of the live offset.
var _layout_base_positions: Dictionary = {}


func _ready() -> void:
	# Discoverable by the in-map "Edit HUD Layout" launcher without a hard node path.
	add_to_group("hud")
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


func setup(grid: Node, turn_node: Node, attack_preview: Node = null,
		unit_details_screen: Node = null) -> void:
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
		"phase_label":    return _phase_label
		"turn_label":     return _turn_label
		"unit_info":      return _unit_panel
		"objective":      return _objective_panel
		"terrain_corner": return get_node_or_null("TerrainCorner")
	return null


# Captures each panel's authored base position exactly once, before any saved offset
# is applied, so Reset can restore the .tscn layout no matter the current offset.
func _capture_base_positions() -> void:
	if not _layout_base_positions.is_empty():
		return
	for id in LAYOUT_PANEL_IDS:
		var panel := get_layout_panel(id)
		if panel != null:
			_layout_base_positions[id] = panel.position


# Applies a full layout dict (panel_id -> { offset: Vector2, scale: float }) to the
# panels. Missing/malformed entries leave that panel at its authored base. Positions
# are clamped so a panel always keeps _MIN_VISIBLE_PX on screen.
func apply_layout(layout: Dictionary) -> void:
	_capture_base_positions()
	for id in LAYOUT_PANEL_IDS:
		var panel := get_layout_panel(id)
		if panel == null:
			continue
		var base: Vector2 = _layout_base_positions.get(id, panel.position)
		var entry: Variant = layout.get(id, {})
		var offset := Vector2.ZERO
		var scale_f := 1.0
		if entry is Dictionary:
			# Type-guard each field: a corrupt/hand-edited cfg could carry a wrong-typed
			# value, and assigning a non-Vector2 into the typed `offset` would crash.
			var off_v: Variant = entry.get("offset", Vector2.ZERO)
			if off_v is Vector2:
				offset = off_v
			var scale_v: Variant = entry.get("scale", 1.0)
			if scale_v is float or scale_v is int:
				scale_f = float(scale_v)
		panel.scale = Vector2.ONE * clampf(scale_f, MIN_PANEL_SCALE, MAX_PANEL_SCALE)
		var layout_pos: Vector2 = base + offset
		panel.position = _clamp_panel_on_screen(
			panel, _panel_position_from_layout_position(id, layout_pos, panel))


# Loads the saved layout from SettingsManager and applies it. Called deferred from
# _ready (post-layout) and re-runnable by the editor.
func _apply_saved_layout() -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	apply_layout(sm.hud_layout if sm != null else {})


# Keeps a panel from being placed (or saved) fully off-screen: clamps the top-left so
# at least _MIN_VISIBLE_PX of the scaled panel stays inside the viewport on each axis.
func _clamp_panel_on_screen(panel: Control, pos: Vector2) -> Vector2:
	var view: Vector2 = get_viewport_rect().size
	var sz: Vector2 = panel.size * panel.scale
	pos.x = clampf(pos.x, _MIN_VISIBLE_PX - sz.x, view.x - _MIN_VISIBLE_PX)
	pos.y = clampf(pos.y, _MIN_VISIBLE_PX - sz.y, view.y - _MIN_VISIBLE_PX)
	return pos


# Live single-panel edit used by the layout editor: sets one panel's offset (from its
# base) + scale without disturbing the others. Returns the clamped on-screen position.
func set_panel_layout(panel_id: String, offset: Vector2, scale_f: float) -> Vector2:
	_capture_base_positions()
	var panel := get_layout_panel(panel_id)
	if panel == null:
		return Vector2.ZERO
	var base: Vector2 = _layout_base_positions.get(panel_id, panel.position)
	panel.scale = Vector2.ONE * clampf(scale_f, MIN_PANEL_SCALE, MAX_PANEL_SCALE)
	var layout_pos: Vector2 = base + offset
	panel.position = _clamp_panel_on_screen(
		panel, _panel_position_from_layout_position(panel_id, layout_pos, panel))
	return panel.position


# Builds the current layout dict (offset from base + scale) for panels that differ
# from their authored layout — the shape persisted to SettingsManager.hud_layout.
func current_layout() -> Dictionary:
	_capture_base_positions()
	var out: Dictionary = {}
	for id in LAYOUT_PANEL_IDS:
		var panel := get_layout_panel(id)
		if panel == null:
			continue
		var base: Vector2 = _layout_base_positions.get(id, panel.position)
		var layout_pos: Vector2 = _layout_position_from_panel_position(id, panel)
		var offset: Vector2 = layout_pos - base
		var scale_f: float = panel.scale.x
		if offset != Vector2.ZERO or not is_equal_approx(scale_f, 1.0):
			out[id] = { "offset": offset, "scale": scale_f }
	return out


# Restores every panel to its authored base layout (offset 0, scale 1).
func reset_layout() -> void:
	apply_layout({})


# Terrain More Info lives above the compact terrain panel inside the same movable
# VBox. Layout offsets are defined by the compact panel's top-left, so reset/editing
# keeps the familiar HUD anchor even while the expanded box is visible.
func _panel_position_from_layout_position(panel_id: String, layout_pos: Vector2,
		panel: Control) -> Vector2:
	if panel_id == "terrain_corner":
		return layout_pos - _terrain_expanded_offset(panel.scale)
	return layout_pos


func _layout_position_from_panel_position(panel_id: String, panel: Control) -> Vector2:
	if panel_id == "terrain_corner":
		return panel.position + _terrain_expanded_offset(panel.scale)
	return panel.position


func _terrain_expanded_offset(scale_v: Vector2) -> Vector2:
	if _terrain_more_page < 0 or _terrain_more_panel == null or not _terrain_more_panel.visible:
		return Vector2.ZERO
	var corner := get_layout_panel("terrain_corner")
	var separation: float = 0.0
	if corner is BoxContainer:
		separation = float((corner as BoxContainer).get_theme_constant("separation"))
	# Derive the offset from the *active page's* current height (V021-02/V021-05): only
	# the visible page's rows contribute, so the panel min-size — and thus the reflow —
	# tracks the page in view instead of a cached expanded height that drifts on reset.
	var more_h: float = _terrain_more_panel.get_combined_minimum_size().y
	if more_h <= 0.0:
		more_h = _terrain_more_panel.size.y
	return Vector2(0.0, (more_h + separation) * scale_v.y)


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
func _build_objective_lines(map_data: MapData) -> Array[String]:
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
	var md: MapData = gs.map_data if gs != null else null
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
	var wpn: WeaponData = unit.get_equipped_weapon() if unit.has_method("get_equipped_weapon") else null
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
	_terrain_name.text = terrain.capitalize()
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


# Cycles the terrain More Info surface Hidden → Description → Movement → Hidden
# (V021-05). Public so the mouse/touch mode (V021-17) can drive paging by click.
func cycle_terrain_more_page() -> void:
	_terrain_more_page += 1
	if _terrain_more_page >= TERRAIN_PAGE_COUNT:
		_terrain_more_page = TERRAIN_PAGE_HIDDEN
	if _cursor_tile.x >= 0:
		_update_terrain(_cursor_tile)


# Renders the active More Info page. Each page shows a subset of the expanded rows
# so the panel sizes to the page in view (Description = blurb + tile actions;
# Movement = the move-cost table). Def/Dodge stay on the always-visible compact
# panel, so the movement page doesn't restate them.
func _render_terrain_page(tile: Vector2i, terrain: String) -> void:
	_terrain_more_panel.show()
	_terrain_hint.visible = false
	var on_description: bool = _terrain_more_page == TERRAIN_PAGE_DESCRIPTION
	var on_movement: bool = _terrain_more_page == TERRAIN_PAGE_MOVEMENT
	_terrain_desc.text = MoreInfoContent.describe("terrain", terrain)
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
		["foot",     "Foot"],
		["mounted",  "Mounted"],
		["armoured", "Armoured"],
		["light",    "Light"],
		["flying",   "Flying"],
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
	var ids: Array[String] = TileActions.available_for(
		_selected_unit, tile, _turn_manager)
	if ids.is_empty():
		return ""
	var lines: Array[String] = ["Actions:"]
	for id in ids:
		lines.append("  %s" % TileActions.display_label(id))
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
	if _attack_preview != null and is_instance_valid(_attack_preview) \
			and _attack_preview.visible:
		return true
	if _unit_details_screen != null and is_instance_valid(_unit_details_screen) \
			and _unit_details_screen.visible:
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
