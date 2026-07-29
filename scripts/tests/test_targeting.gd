extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_targeting.gd
# Exercises MapCursorTargeting (D-1 slice 1) against a live GameMap: attack target
# discovery, the confirm/cancel flow, the CHOOSING -> PREVIEWING sub-state, and
# staff healing. GridManager's unit queries read GameState.all_units, so a real
# scene is loaded rather than constructing the object in isolation.


# Minimal stand-in for the AttackPreview UI node — records show/hide calls so the
# CHOOSING -> PREVIEWING -> resolve path can be driven without the real scene.
class StubPreview:
	extends Node
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

	var bus := root.get_node_or_null("EventBus")
	if bus == null:
		bus = load("res://scripts/autoloads/EventBus.gd").new()
		bus.name = "EventBus"
		root.add_child(bus)
	var dm := root.get_node_or_null("DataManager")
	if dm == null:
		dm = load("res://scripts/autoloads/DataManager.gd").new()
		dm.name = "DataManager"
		root.add_child(dm)
	var gs := root.get_node_or_null("GameState")
	if gs == null:
		gs = load("res://scripts/autoloads/GameState.gd").new()
		gs.name = "GameState"
		root.add_child(gs)
	var cr := root.get_node_or_null("CombatResolver")
	if cr == null:
		cr = load("res://scripts/core/CombatResolver.gd").new()
		cr.name = "CombatResolver"
		root.add_child(cr)
	await process_frame
	gs.reset_map_state()
	gs.load_default_roster()
	gs.configure_next_map("res://data/maps/map_001_rout/map_001_data.tres", "default_roster", "")

	var instance: Node = load("res://scenes/core/GameMap.tscn").instantiate()
	root.add_child(instance)
	await process_frame  # let _ready and unit spawns complete

	var grid: GridManager = instance.get_node("GridManager")

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
	_check(
		stub.shown and not t3.can_change_target(),
		"confirm with a preview node shows the preview and freezes the cursor"
	)
	t3.handle_cancel()  # PREVIEWING -> CHOOSING
	_check(
		not stub.shown and t3.can_change_target() and f3.cancel == 0,
		"cancel from PREVIEWING dismisses preview and returns to CHOOSING"
	)
	t3.handle_confirm(enemy.tile_position)  # CHOOSING -> PREVIEWING
	t3.handle_confirm(enemy.tile_position)  # PREVIEWING -> resolve
	_check(
		f3.done == 1 and not t3.is_active() and not stub.shown,
		"second confirm resolves the attack and emits `completed`"
	)
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
	_check(
		ally.data.hp > hp_before and f4.done == 1,
		"handle_confirm heals the ally and emits `completed`"
	)

	# ── Pair Up: strict same-faction gate ──────────────────────────────────────
	# Code review 2026-06-10: the menu visibility check and the target-collection
	# slice must agree. Pair Up is intra-army: two non-hostile factions in the
	# same alliance group (blue/green) cooperate but cannot pair. Reuse `player`
	# and `ally` (both blue, both unit_id-bearing roster units) so the positive
	# case shares fixtures with the negative one.
	var pair_reg := root.get_node_or_null("PairUpRegistry")
	if pair_reg == null:
		pair_reg = load("res://scripts/autoloads/PairUpRegistry.gd").new()
		pair_reg.name = "PairUpRegistry"
		root.add_child(pair_reg)
	pair_reg.call("clear")
	for u in gs.all_units:
		u.tile_position = Vector2i(0, 0)
	player.tile_position = Vector2i(5, 5)
	ally.tile_position = Vector2i(5, 6)  # cardinal-adjacent
	var t_pair := MapCursorTargeting.new()
	t_pair.setup(grid, null, cr)
	var pair_tiles_same: Array[Vector2i] = t_pair.begin(MapCursorTargeting.Mode.PAIR_UP, player)
	_check(
		ally.tile_position in pair_tiles_same, "begin(PAIR_UP) lists an adjacent same-faction ally"
	)

	# Cross-faction-same-alliance: flip the ally's team to "green". GameState's
	# default alliance map puts blue+green in the same group ("allies"), so they
	# are NOT hostile — but Pair Up must still refuse because the gate is strict
	# same-faction (issue 2.1 / decision: strict).
	var saved_team: String = ally.team
	ally.team = "green"
	var pair_tiles_cross: Array[Vector2i] = t_pair.begin(MapCursorTargeting.Mode.PAIR_UP, player)
	_check(
		not (ally.tile_position in pair_tiles_cross),
		"begin(PAIR_UP) refuses a same-alliance cross-faction neighbor"
	)
	ally.team = saved_team

	# ── Map 900 hotseat regression: green attack opens the real combat preview ──
	gs.reset_map_state()
	gs.load_roster_from_directory("res://data/roster/test/map_900_hotseat_validation/")
	gs.configure_next_map(
		"res://data/maps/map_900_hotseat_validation/map_900_hotseat_validation_data.tres",
		"fixed_test_roster",
		"res://data/roster/test/map_900_hotseat_validation/"
	)
	var hotseat_instance: Node = load("res://scenes/core/GameMap.tscn").instantiate()
	root.add_child(hotseat_instance)
	await process_frame
	var hotseat_cursor: MapCursor = hotseat_instance.get_node("MapCursor")
	var hotseat_preview: Control = hotseat_instance.get_node("HUDLayer/AttackPreview")
	var hotseat_green: Unit = null
	var hotseat_red: Unit = null
	for u in gs.all_units:
		if u.team == "green" and hotseat_green == null:
			hotseat_green = u
		elif u.team == "red" and hotseat_red == null:
			hotseat_red = u
	if hotseat_green == null or hotseat_red == null:
		_check(false, "Map 900 hotseat map spawned green and red units")
	else:
		hotseat_cursor.set_controlling_faction("green")
		hotseat_cursor.unlock()
		hotseat_cursor.current_tile = hotseat_green.tile_position
		hotseat_cursor._on_confirm()
		hotseat_cursor.current_tile = Vector2i(5, 4)  # adjacent to the red soldier at (6,4)
		hotseat_cursor._on_confirm()
		await create_timer(0.5).timeout
		hotseat_cursor._on_action_chosen("attack")
		var targeting_ready: bool = (
			hotseat_cursor._state == MapCursor.State.TARGETING
			and hotseat_cursor.current_tile == hotseat_red.tile_position
		)
		_check(targeting_ready, "Map 900 green move-then-attack enters targeting on the red unit")
		hotseat_cursor._on_confirm()
		await process_frame
		var preview_populated: bool = (
			hotseat_preview.visible
			and "Dmg" in hotseat_preview._atk_dmg.text
			and "HP " in hotseat_preview._def_hp.text
		)
		_check(
			preview_populated,
			"Map 900 green attack opens a populated combat preview instead of info-only UI"
		)
	hotseat_instance.queue_free()

	_finish()


func _finish() -> void:
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
