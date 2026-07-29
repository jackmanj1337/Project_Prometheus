class_name MapCursorTargeting extends RefCounted
# Owns the attack / staff-heal targeting flow extracted from MapCursor (D-1 slice 1).
#
# A plain RefCounted, not a Node: every scene-tree dependency (grid, attack-preview
# node, CombatResolver) is injected via setup(), so the whole flow is unit-testable
# without a SceneTree. The cursor FSM stays on MapCursor — this object only tracks
# its own ATTACK-vs-STAFF mode and CHOOSING-vs-PREVIEWING sub-state, and reports
# back through the `completed` / `cancelled` signals.

enum Mode { ATTACK, STAFF, PAIR_UP, SEPARATE }

# Internal sub-state. Collapses the old MapCursor TARGETING / PREVIEWING /
# STAFF_TARGETING states — MapCursor now sees a single State.TARGETING.
enum _Sub { IDLE, CHOOSING, PREVIEWING }

signal completed  # action resolved — MapCursor should call _finish_action()
signal cancelled  # player backed out of target choice — MapCursor reopens the ActionMenu
# Pair Up confirmation. Emitted by handle_confirm() while in PAIR_UP mode when
# the cursor sits on a valid adjacent unpaired ally; MapCursor receives lead
# (the initiating unit) and support (the chosen partner), performs the actual
# pair / support-tile / DONE bookkeeping, then arranges _finish_action. This
# stays separate from `completed` so existing ATTACK/STAFF flows are untouched.
signal pair_up_resolved(lead: Node, support: Node)
signal separate_resolved(lead: Node, support: Node, target_tile: Vector2i)

# Injected via setup(). attack_preview / combat_resolver may be null (see setup()).
var _grid: GridManager = null
var _attack_preview: Node = null
var _combat_resolver: Node = null
# TurnManager, for the RNG event record's pre-move from_tile (may be null in
# headless tests — the record then falls back to the unit's live tile).
var _turn: Node = null
# Faction id the cursor currently controls. Used by the attack/heal-target gates
# (M14 stage 1) — "valid enemy" = `target.team != _controlling_faction`, "valid
# ally" = same. Defaults to "blue" so 3-arg test callers stay valid. Stage 2
# generalises both gates to the alliance-group hostility helper.
var _controlling_faction: String = "blue"

var _sub: int = _Sub.IDLE
var _mode: int = Mode.ATTACK
var _unit: Unit = null
var _tiles: Array[Vector2i] = []  # valid target tiles for this session
var _preview_target: Node = null


# Inject scene-tree dependencies once, when MapCursor.setup() runs and _grid is known.
# attack_preview may be null (headless tests) — confirm then resolves immediately.
# combat_resolver may be null — combat resolution is skipped (matches the old `if cr:`).
# controlling_faction defaults to "blue" so 3-arg test callers stay valid.
func setup(
	grid: GridManager,
	attack_preview: Node,
	combat_resolver: Node,
	controlling_faction: String = "blue",
	turn: Node = null
) -> void:
	_grid = grid
	_attack_preview = attack_preview
	_combat_resolver = combat_resolver
	_controlling_faction = controlling_faction
	_turn = turn


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
	elif mode == Mode.PAIR_UP:
		# Adjacent unpaired allies. Visually reuses the heal overlay — Pair Up
		# is the "friendly target" pattern, same as a staff heal in terms of
		# what the player is picking among.
		for ally in _get_adjacent_unpaired_allies(unit):
			_tiles.append(ally.tile_position)
	elif mode == Mode.SEPARATE:
		for tile in _get_adjacent_separate_tiles(unit):
			_tiles.append(tile)
	else:
		for ally in _grid.get_healable_allies(unit):
			_tiles.append(ally.tile_position)
	_sub = _Sub.IDLE if _tiles.is_empty() else _Sub.CHOOSING
	if not _tiles.is_empty():
		_grid.repaint_overlays(overlay_specs())
	return _tiles


# Targeting overlay specs for the registry compose path. MapCursor merges these
# with retained threat/watch specs so target selection can coexist with danger
# overlays ([MRD-7]); direct unit tests still get the standalone target paint.
func overlay_specs() -> Dictionary:
	var specs: Dictionary = {}
	if _tiles.is_empty():
		return specs
	if _mode == Mode.ATTACK:
		specs[GridManager.OVERLAY_LAYER_ATTACK] = {
			"tiles": _tiles,
			"source": GridManager.OVERLAY_RED,
		}
	else:
		specs[GridManager.OVERLAY_LAYER_HEAL] = {
			"tiles": _tiles,
			"source": GridManager.OVERLAY_HEAL,
		}
	return specs


# Called by MapCursor._on_confirm while in State.TARGETING. cursor_tile is the
# cursor's current tile. CHOOSING: shows the attack preview (ATTACK), applies
# the heal (STAFF), or resolves the pair choice (PAIR_UP). PREVIEWING: resolves
# the previewed attack.
func handle_confirm(cursor_tile: Vector2i) -> void:
	match _sub:
		_Sub.CHOOSING:
			if _mode == Mode.ATTACK:
				_confirm_attack_target(cursor_tile)
			elif _mode == Mode.PAIR_UP:
				_confirm_pair_up_target(cursor_tile)
			elif _mode == Mode.SEPARATE:
				_confirm_separate_target(cursor_tile)
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


# Controller handoff / debug override cancellation: hide any preview, clear
# overlays, and forget the transient target without emitting action-complete.
func abort() -> void:
	if _attack_preview and _attack_preview.has_method("hide_preview"):
		_attack_preview.hide_preview()
	_preview_target = null
	_unit = null
	_clear_overlays()
	_sub = _Sub.IDLE


# ── Internals ────────────────────────────────────────────────────────────────


# True iff `target.team` is hostile to `_controlling_faction` per the alliance
# model. Routes through GameState.are_hostile when the autoload is live; falls
# back to the strict same-faction comparison so headless --script tests that
# don't load GameState still get the stage-1 binary behaviour.
func _is_target_hostile(target: Node) -> bool:
	if target == null or not ("team" in target):
		return false
	var gs: Node = null
	# RefCounted has no scene-tree handle; resolve the autoload via the grid Node
	# (which is in the tree during gameplay) when we need to read GameState.
	if _grid != null and _grid.is_inside_tree():
		gs = _grid.get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("are_hostile"):
		return gs.are_hostile(_controlling_faction, target.team)
	return target.team != _controlling_faction


func _confirm_attack_target(cursor_tile: Vector2i) -> void:
	var target := _grid.get_unit_at(cursor_tile)
	# M14 stage 2: "valid enemy" = "hostile to the controlling faction", routed
	# through GameState.are_hostile so blue can't confirm an attack on a green ally.
	if target == null or not _is_target_hostile(target):
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
		# Canonical "attack" event record (RNG-1): from_tile is the pre-move
		# tile so the chosen destination is part of the action's dice identity.
		var from_tile: Vector2i = _unit.tile_position
		if _turn != null and _turn.has_method("get_action_start_tile"):
			from_tile = _turn.get_action_start_tile(_unit)
		var record: Array[String] = _combat_resolver.make_attack_event_record(
			_unit, target, from_tile
		)
		var result: Dictionary = _combat_resolver.resolve_combat(_unit, target, record)
		_combat_resolver.apply_combat_result(result, _unit, target)
	_clear_overlays()
	_sub = _Sub.IDLE
	completed.emit()


func _apply_staff_heal(cursor_tile: Vector2i) -> void:
	var target := _grid.get_unit_at(cursor_tile)
	# M14 stage 2: "valid ally" = "same alliance group as the controlling faction"
	# = "not hostile to the controlling faction". Routes through GameState.are_hostile
	# so blue can heal green when stage-3 content adds the green faction.
	if target == null or _is_target_hostile(target):
		return  # cursor isn't on a valid ally — ignore the confirm, stay CHOOSING
	# Capture the weapon before perform_staff_heal — a last-use removal would clear
	# the entry, and a later get_equipped_weapon() could return null / the wrong type.
	var weapon: WeaponData = _unit.get_equipped_weapon()
	if weapon != null:
		# Commit the staff RNG event BEFORE the heal (§3: [healer_id, from_tile,
		# to_tile, target_id]): heal EXP can level the healer, and those chained
		# levelup events must sit on the post-staff hash (§4 ordering).
		if _turn != null and _turn.has_method("commit_action_event"):
			(
				_turn
				. commit_action_event(
					"staff",
					(
						[
							_unit.data.unit_id if _unit.data != null else "-",
							TurnManager.tile_field(_turn.get_action_start_tile(_unit)),
							TurnManager.tile_field(_unit.tile_position),
							target.data.unit_id if target.data != null else "-",
						]
						as Array[String]
					)
				)
			)
		_unit.perform_staff_heal(target, weapon)
	_clear_overlays()
	_sub = _Sub.IDLE
	completed.emit()


func _clear_overlays() -> void:
	_tiles = []
	if _grid != null:
		_grid.clear_overlays()


# Returns the four cardinal-neighbor allies of `unit` who are unpaired and have
# a unit_id. Pair Up needs an unpaired partner, so filter via PairUpRegistry.
# Resolves the registry through the grid Node (RefCounted has no scene-tree
# handle of its own — same trick used by _is_target_hostile for GameState).
func _get_adjacent_unpaired_allies(unit: Node) -> Array[Node]:
	var out: Array[Node] = []
	if _grid == null or unit == null:
		return out
	var registry: Node = null
	if _grid.is_inside_tree():
		registry = _grid.get_node_or_null("/root/PairUpRegistry")
	const _CARDINALS: Array[Vector2i] = [
		Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)
	]
	for delta in _CARDINALS:
		var neighbor: Node = _grid.get_unit_at(unit.tile_position + delta)
		if neighbor == null or neighbor == unit:
			continue
		# Pair Up is intra-army (strict same-faction). Two non-hostile factions
		# in the same alliance group can cooperate (no friendly fire) but cannot
		# pair — matches ActionMenu's visibility gate. Code review 2026-06-10.
		if not ("team" in neighbor) or neighbor.team != unit.team:
			continue
		if neighbor.data == null or neighbor.data.unit_id == "":
			continue
		# Self-pair check — unit must also be unpaired. Cheap to short-circuit
		# the whole list when the lead is already paired.
		if registry != null:
			if registry.call("is_paired", unit.data.unit_id):
				return out
			if registry.call("is_paired", neighbor.data.unit_id):
				continue
		out.append(neighbor)
	return out


# CHOOSING + PAIR_UP confirm. Validates the cursor sits on one of the _tiles
# returned by begin(), looks up the unit there, and emits pair_up_resolved so
# MapCursor can perform the registry mutation / support-tile hide / dual-DONE
# bookkeeping. Bails silently if the cursor moved off a valid target.
func _confirm_pair_up_target(cursor_tile: Vector2i) -> void:
	if not (cursor_tile in _tiles):
		return
	var target: Node = _grid.get_unit_at(cursor_tile)
	if target == null:
		return
	_clear_overlays()
	_sub = _Sub.IDLE
	pair_up_resolved.emit(_unit, target)


# Returns every adjacent cardinal tile the paired lead may drop its support onto.
# Requires the current unit to be the lead of a live pair; passability + end-tile
# legality are both checked so Separate can't target walls or occupied tiles.
func _get_adjacent_separate_tiles(unit: Node) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if _grid == null or unit == null or unit.data == null or unit.data.unit_id == "":
		return out
	var registry: Node = null
	var gs: Node = null
	if _grid.is_inside_tree():
		registry = _grid.get_node_or_null("/root/PairUpRegistry")
		gs = _grid.get_node_or_null("/root/GameState")
	if registry == null or gs == null:
		return out
	if not registry.call("is_lead", unit.data.unit_id):
		return out
	var support_id: String = registry.call("get_partner_id", unit.data.unit_id)
	if support_id == "":
		return out
	var support: Node = gs.call("find_unit_by_id", support_id)
	if support == null or support.data == null or support.data.hp <= 0:
		return out
	const _CARDINALS: Array[Vector2i] = [
		Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)
	]
	for delta in _CARDINALS:
		var tile: Vector2i = unit.tile_position + delta
		if _grid.is_passable(tile, support) and _grid.can_end_on_tile(tile, support):
			out.append(tile)
	return out


# CHOOSING + SEPARATE confirm. The cursor picks which adjacent legal tile the
# support should reappear on; MapCursor performs the actual registry mutation.
func _confirm_separate_target(cursor_tile: Vector2i) -> void:
	if not (cursor_tile in _tiles):
		return
	if _unit == null or _unit.data == null:
		return
	var gs: Node = null
	var registry: Node = null
	if _grid != null and _grid.is_inside_tree():
		gs = _grid.get_node_or_null("/root/GameState")
		registry = _grid.get_node_or_null("/root/PairUpRegistry")
	if gs == null or registry == null:
		return
	var support_id: String = registry.call("get_partner_id", _unit.data.unit_id)
	var support: Node = gs.call("find_unit_by_id", support_id)
	if support == null:
		return
	_clear_overlays()
	_sub = _Sub.IDLE
	separate_resolved.emit(_unit, support, cursor_tile)
