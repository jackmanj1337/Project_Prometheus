extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_targeting.gd
# Exercises MapCursorTargeting (D-1 slice 1) against a live GameMap: attack target
# discovery, the confirm/cancel flow, the CHOOSING -> PREVIEWING sub-state, and
# staff healing. GridManager's unit queries read GameState.all_units, so a real
# scene is loaded rather than constructing the object in isolation.

# Minimal stand-in for the AttackPreview UI node — records show/hide calls so the
# CHOOSING -> PREVIEWING -> resolve path can be driven without the real scene.
class StubPreview extends Node:
	var shown: bool = false
	func show_preview(_attacker: Node, _target: Node) -> void:
		shown = true
	func hide_preview() -> void:
		shown = false

var _passed: int = 0
var _failed: int = 0


func _check(ok: bool, msg: String) -> void:
	if ok:
		print("OK  " + msg)
		_passed += 1
	else:
		print("FAIL " + msg)
		_failed += 1


func _init() -> void:
	print("=== MapCursorTargeting Test ===")

	var instance: Node = load("res://scenes/core/GameMap.tscn").instantiate()
	root.add_child(instance)
	await process_frame  # let _ready and unit spawns complete

	var grid: GridManager = instance.get_node("GridManager")
	var cr: Node = root.get_node_or_null("CombatResolver")
	var gs: Node = root.get_node_or_null("GameState")

	# Pick test units: a player attacker with a weapon, a second player unit to
	# heal, the cleric (staff user), and an enemy.
	var player: Unit = null
	var ally: Unit = null
	var enemy: Unit = null
	var cleric: Unit = null
	for u in gs.all_units:
		if u.team == "red":
			if enemy == null:
				enemy = u
		elif u.data != null and u.data.class_id == "cleric":
			if cleric == null:
				cleric = u
		elif u.get_equipped_weapon() != null and player == null:
			player = u
		elif ally == null:
			ally = u
	if player == null or ally == null or enemy == null or cleric == null:
		_check(false, "found player/ally/enemy/cleric units in roster")
		_finish()
		return

	# Park every unit far from the test area so only positions we set matter.
	for u in gs.all_units:
		u.tile_position = Vector2i(0, 0)

	# ── Attack: no targets in range ─────────────────────────────────────────
	player.tile_position = Vector2i(20, 20)  # all enemies parked at (0,0)
	var wrange: Vector2i = grid._get_weapon_range(player)
	var t1 := MapCursorTargeting.new()
	t1.setup(grid, null, cr)
	var no_tiles := t1.begin(MapCursorTargeting.Mode.ATTACK, player)
	_check(no_tiles.is_empty(), "begin(ATTACK) with no enemy in range returns no tiles")
	_check(not t1.is_active(), "targeting stays inactive when there are no targets")

	# ── Attack: enemy in range ──────────────────────────────────────────────
	# Place the enemy exactly at the weapon's minimum range so any weapon works.
	enemy.tile_position = player.tile_position + Vector2i(wrange.x, 0)
	enemy.data.hp = enemy.data.max_hp
	player.data.hp = player.data.max_hp
	var tiles := t1.begin(MapCursorTargeting.Mode.ATTACK, player)
	_check(enemy.tile_position in tiles, "begin(ATTACK) lists the in-range enemy's tile")
	_check(t1.is_active() and t1.can_change_target(), "targeting active and CHOOSING after begin")

	# ── Attack: confirm with no preview node resolves immediately ───────────
	var f1 := {"done": 0, "cancel": 0}
	t1.completed.connect(func() -> void: f1.done += 1)
	t1.cancelled.connect(func() -> void: f1.cancel += 1)
	t1.handle_confirm(enemy.tile_position)
	_check(f1.done == 1, "handle_confirm with null preview emits `completed`")
	_check(not t1.is_active(), "targeting inactive after the action resolves")

	# ── Attack: cancel from CHOOSING backs out ──────────────────────────────
	enemy.data.hp = enemy.data.max_hp
	player.data.hp = player.data.max_hp
	var t2 := MapCursorTargeting.new()
	t2.setup(grid, null, cr)
	var f2 := {"done": 0, "cancel": 0}
	t2.completed.connect(func() -> void: f2.done += 1)
	t2.cancelled.connect(func() -> void: f2.cancel += 1)
	t2.begin(MapCursorTargeting.Mode.ATTACK, player)
	t2.handle_cancel()
	_check(f2.cancel == 1 and f2.done == 0, "handle_cancel from CHOOSING emits `cancelled`")
	_check(not t2.is_active(), "targeting inactive after cancel")

	# ── Attack: preview sub-state (CHOOSING -> PREVIEWING -> resolve) ────────
	enemy.data.hp = enemy.data.max_hp
	player.data.hp = player.data.max_hp
	var stub := StubPreview.new()
	var t3 := MapCursorTargeting.new()
	t3.setup(grid, stub, cr)
	var f3 := {"done": 0, "cancel": 0}
	t3.completed.connect(func() -> void: f3.done += 1)
	t3.cancelled.connect(func() -> void: f3.cancel += 1)
	t3.begin(MapCursorTargeting.Mode.ATTACK, player)
	t3.handle_confirm(enemy.tile_position)  # CHOOSING -> PREVIEWING
	_check(stub.shown and not t3.can_change_target(),
		"confirm with a preview node shows the preview and freezes the cursor")
	t3.handle_cancel()  # PREVIEWING -> CHOOSING
	_check(not stub.shown and t3.can_change_target() and f3.cancel == 0,
		"cancel from PREVIEWING dismisses preview and returns to CHOOSING")
	t3.handle_confirm(enemy.tile_position)  # CHOOSING -> PREVIEWING
	t3.handle_confirm(enemy.tile_position)  # PREVIEWING -> resolve
	_check(f3.done == 1 and not t3.is_active() and not stub.shown,
		"second confirm resolves the attack and emits `completed`")
	stub.free()

	# ── Staff: heal an injured ally ─────────────────────────────────────────
	cleric.tile_position = Vector2i(20, 20)
	var staff_range: Vector2i = grid._get_weapon_range(cleric)
	ally.tile_position = cleric.tile_position + Vector2i(staff_range.x, 0)
	ally.data.hp = maxi(1, ally.data.max_hp - 8)  # injure so it is healable
	var t4 := MapCursorTargeting.new()
	t4.setup(grid, null, cr)
	var f4 := {"done": 0, "cancel": 0}
	t4.completed.connect(func() -> void: f4.done += 1)
	t4.cancelled.connect(func() -> void: f4.cancel += 1)
	var heal_tiles := t4.begin(MapCursorTargeting.Mode.STAFF, cleric)
	_check(ally.tile_position in heal_tiles, "begin(STAFF) lists the injured ally's tile")
	var hp_before: int = ally.data.hp
	t4.handle_confirm(ally.tile_position)
	_check(ally.data.hp > hp_before and f4.done == 1,
		"handle_confirm heals the ally and emits `completed`")

	_finish()


func _finish() -> void:
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
