class_name MapCursorTargeting extends RefCounted
# Owns the attack / staff-heal targeting flow extracted from MapCursor (D-1 slice 1).
#
# A plain RefCounted, not a Node: every scene-tree dependency (grid, attack-preview
# node, CombatResolver) is injected via setup(), so the whole flow is unit-testable
# without a SceneTree. The cursor FSM stays on MapCursor — this object only tracks
# its own ATTACK-vs-STAFF mode and CHOOSING-vs-PREVIEWING sub-state, and reports
# back through the `completed` / `cancelled` signals.

enum Mode { ATTACK, STAFF }

# Internal sub-state. Collapses the old MapCursor TARGETING / PREVIEWING /
# STAFF_TARGETING states — MapCursor now sees a single State.TARGETING.
enum _Sub { IDLE, CHOOSING, PREVIEWING }

signal completed   # action resolved — MapCursor should call _finish_action()
signal cancelled   # player backed out of target choice — MapCursor reopens the ActionMenu

# Injected via setup(). attack_preview / combat_resolver may be null (see setup()).
var _grid: GridManager = null
var _attack_preview: Node = null
var _combat_resolver: Node = null
# Faction id the cursor currently controls. Used by the attack/heal-target gates
# (M14 stage 1) — "valid enemy" = `target.team != _controlling_faction`, "valid
# ally" = same. Defaults to "blue" so 3-arg test callers stay valid. Stage 2
# generalises both gates to the alliance-group hostility helper.
var _controlling_faction: String = "blue"

var _sub: int = _Sub.IDLE
var _mode: int = Mode.ATTACK
var _unit: Unit = null
var _tiles: Array[Vector2i] = []     # valid target tiles for this session
var _preview_target: Node = null


# Inject scene-tree dependencies once, when MapCursor.setup() runs and _grid is known.
# attack_preview may be null (headless tests) — confirm then resolves immediately.
# combat_resolver may be null — combat resolution is skipped (matches the old `if cr:`).
# controlling_faction defaults to "blue" so 3-arg test callers stay valid.
func setup(grid: GridManager, attack_preview: Node, combat_resolver: Node,
		controlling_faction: String = "blue") -> void:
	_grid = grid
	_attack_preview = attack_preview
	_combat_resolver = combat_resolver
	_controlling_faction = controlling_faction


# Called when the active controlling faction changes mid-map (M14 stage 5).
func set_controlling_faction(faction_id: String) -> void:
	_controlling_faction = faction_id


# Start a targeting session. Returns the valid target tiles (caller snaps the cursor
# to tiles[0]); returns an empty array when there are no targets, in which case the
# caller should reopen the ActionMenu instead of entering State.TARGETING.
func begin(mode: int, unit: Unit) -> Array[Vector2i]:
	_mode = mode
	_unit = unit
	_preview_target = null
	_tiles = []
	if _grid == null or unit == null:
		_sub = _Sub.IDLE
		return _tiles
	if mode == Mode.ATTACK:
		for enemy in _grid.get_attackable_enemies_from_tile(unit, unit.tile_position):
			_tiles.append(enemy.tile_position)
		if not _tiles.is_empty():
			_grid.show_attack_overlay(_tiles)
	else:
		for ally in _grid.get_healable_allies(unit):
			_tiles.append(ally.tile_position)
		if not _tiles.is_empty():
			_grid.show_heal_overlay(_tiles)
	_sub = _Sub.IDLE if _tiles.is_empty() else _Sub.CHOOSING
	return _tiles


# Called by MapCursor._on_confirm while in State.TARGETING. cursor_tile is the
# cursor's current tile. CHOOSING: shows the attack preview (ATTACK) or applies the
# heal (STAFF). PREVIEWING: resolves the previewed attack.
func handle_confirm(cursor_tile: Vector2i) -> void:
	match _sub:
		_Sub.CHOOSING:
			if _mode == Mode.ATTACK:
				_confirm_attack_target(cursor_tile)
			else:
				_apply_staff_heal(cursor_tile)
		_Sub.PREVIEWING:
			_resolve_attack(_preview_target)


# Called by MapCursor._on_cancel while in State.TARGETING.
# PREVIEWING -> back to CHOOSING (preview dismissed). CHOOSING -> emits `cancelled`.
func handle_cancel() -> void:
	match _sub:
		_Sub.PREVIEWING:
			if _attack_preview and _attack_preview.has_method("hide_preview"):
				_attack_preview.hide_preview()
			_preview_target = null
			_sub = _Sub.CHOOSING
		_Sub.CHOOSING:
			_clear_overlays()
			_sub = _Sub.IDLE
			cancelled.emit()


# Tiles the cursor may cycle among this session (for the MapCursor input layer).
func target_tiles() -> Array[Vector2i]:
	return _tiles


# True only while CHOOSING. The input layer checks this before moving the cursor —
# during PREVIEWING the cursor and the chosen target are frozen.
func can_change_target() -> bool:
	return _sub == _Sub.CHOOSING


func is_active() -> bool:
	return _sub != _Sub.IDLE


# ── Internals ────────────────────────────────────────────────────────────────

func _confirm_attack_target(cursor_tile: Vector2i) -> void:
	var target := _grid.get_unit_at(cursor_tile)
	if target == null or target.team == _controlling_faction:
		return  # cursor isn't on a valid enemy — ignore the confirm, stay CHOOSING
	_preview_target = target
	if _attack_preview and _attack_preview.has_method("show_preview"):
		_attack_preview.show_preview(_unit, target)
		_sub = _Sub.PREVIEWING
	else:
		# No preview node wired (headless) — resolve straight away.
		_resolve_attack(target)


func _resolve_attack(target: Node) -> void:
	if _attack_preview and _attack_preview.has_method("hide_preview"):
		_attack_preview.hide_preview()
	_preview_target = null
	if target != null and _combat_resolver != null:
		var result: Dictionary = _combat_resolver.resolve_combat(_unit, target)
		_combat_resolver.apply_combat_result(result, _unit, target)
	_clear_overlays()
	_sub = _Sub.IDLE
	completed.emit()


func _apply_staff_heal(cursor_tile: Vector2i) -> void:
	var target := _grid.get_unit_at(cursor_tile)
	if target == null or target.team != _controlling_faction:
		return  # cursor isn't on a valid ally — ignore the confirm, stay CHOOSING
	# Capture the weapon before perform_staff_heal — a last-use removal would clear
	# the entry, and a later get_equipped_weapon() could return null / the wrong type.
	var weapon: WeaponData = _unit.get_equipped_weapon()
	if weapon != null:
		_unit.perform_staff_heal(target, weapon)
	_clear_overlays()
	_sub = _Sub.IDLE
	completed.emit()


func _clear_overlays() -> void:
	_tiles = []
	if _grid != null:
		_grid.clear_overlays()
