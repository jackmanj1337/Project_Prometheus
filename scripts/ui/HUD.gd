extends Control
# Persistent HUD overlay: phase label, turn counter, unit info panel, terrain info panel.
# Connects to EventBus signals; reads GridManager for terrain data.

@onready var _phase_label: Label = $PhaseLabel
@onready var _turn_label: Label = $TurnLabel
@onready var _unit_panel: PanelContainer = $UnitInfoPanel
@onready var _unit_name: Label = $UnitInfoPanel/VBox/UnitName
@onready var _unit_class: Label = $UnitInfoPanel/VBox/UnitClass
@onready var _unit_hp: Label = $UnitInfoPanel/VBox/UnitHP
@onready var _unit_weapon: Label = $UnitInfoPanel/VBox/UnitWeapon
@onready var _terrain_panel: PanelContainer = $TerrainInfoPanel
@onready var _terrain_name: Label = $TerrainInfoPanel/VBox/TerrainName
@onready var _terrain_def: Label = $TerrainInfoPanel/VBox/TerrainDef
@onready var _terrain_dodge: Label = $TerrainInfoPanel/VBox/TerrainDodge
# Red "DEBUG MODE" banner — shown only in debug builds (see _setup_debug_banner).
@onready var _debug_label: Label = $DebugLabel

var _turn: int = 1
var _grid: Node = null  # GridManager reference, set by GameMap
var _unit_is_selected: bool = false  # true while a player unit is actively selected
var _cursor_tile: Vector2i = Vector2i(-1, -1)  # last tile reported by cursor_moved
var _displayed_unit: Node = null  # unit currently shown in the info panel (null when hidden)

# Dynamically-created mastery label — lives in UnitInfoPanel/VBox, separate from equipped skills.
# Populated by _show_unit(); nil until a unit with mastery is first displayed.
var _mastery_label: Label = null


func _ready() -> void:
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
	_on_phase_changed(GameState.Phase.PLAYER)
	_setup_debug_banner()


func setup(grid: Node, turn_node: Node) -> void:
	_grid = grid
	if turn_node:
		turn_node.turn_changed.connect(_on_turn_changed)


func _on_phase_changed(new_phase: int) -> void:
	_phase_label.text = "PLAYER PHASE" if new_phase == GameState.Phase.PLAYER else "ENEMY PHASE"


func _on_turn_changed(turn_number: int) -> void:
	_turn = turn_number
	_update_turn_label()


func _on_unit_selected(unit: Node) -> void:
	_unit_is_selected = true
	_show_unit(unit)


func _on_unit_deselected() -> void:
	_unit_is_selected = false
	# After deselection, show whatever unit the cursor is currently over (if any)
	_show_unit(_grid.get_unit_at(_cursor_tile) if _grid != null and _cursor_tile.x >= 0 else null)


func _on_cursor_moved(tile: Vector2i) -> void:
	_cursor_tile = tile
	_update_terrain(tile)
	# When no unit is actively selected, show info for whatever unit the cursor is over
	if not _unit_is_selected:
		_show_unit(_grid.get_unit_at(tile) if _grid != null else null)


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
	_unit_class.text = unit.data.class_id
	_unit_hp.text = "HP %d / %d" % [unit.data.hp, unit.data.max_hp]
	var wpn: WeaponData = unit.get_equipped_weapon() if unit.has_method("get_equipped_weapon") else null
	_unit_weapon.text = wpn.display_name if wpn != null else "--"
	_update_mastery_display(unit)
	_unit_panel.show()


# Shows which weapon types the unit has at S-rank in a dedicated mastery line.
# Uses a dynamically-created Label so no scene edits are required.
func _update_mastery_display(unit: Node) -> void:
	if unit.data == null or unit.data.mastery_skills.is_empty():
		if _mastery_label != null:
			_mastery_label.hide()
		return
	# Collect all weapon types currently at S-rank.
	var s_rank_types: Array[String] = []
	for wtype in unit.data.proficiencies:
		if unit.data.proficiencies[wtype].get("rank", "") == "S":
			s_rank_types.append(wtype.capitalize())
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


func _update_terrain(tile: Vector2i) -> void:
	if _grid == null:
		return
	var terrain: String = _grid.get_terrain_at(tile)
	_terrain_name.text = terrain.capitalize()
	var def_bonus: int = _grid.TERRAIN_DEF_BONUS.get(terrain, 0)
	var dodge_bonus: int = _grid.TERRAIN_DODGE_BONUS.get(terrain, 0)
	_terrain_def.text = "DEF  +%d" % def_bonus
	_terrain_dodge.text = "DODGE +%d" % dodge_bonus



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
		aids.append("growth-boost")
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
