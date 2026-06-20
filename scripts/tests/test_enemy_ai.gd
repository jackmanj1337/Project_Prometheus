extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_enemy_ai.gd
# Tests EnemyAI._find_nearest and _choose_move_tile using real GridManager + stub units.

func _init() -> void:
	print("=== EnemyAI Test ===")
	var passed := 0
	var failed := 0

	var ai: Node = load("res://scripts/core/EnemyAI.gd").new()
	root.add_child(ai)
	await process_frame

	# Stub script: a Node subclass with the members EnemyAI reads. _weapon defaults to
	# null → GridManager._get_weapon_range → (1,1). perform_staff_heal records that it
	# was called so the staff-heal tests can assert on it.
	var stub_script := GDScript.new()
	stub_script.source_code = "extends Node\nvar tile_position: Vector2i = Vector2i.ZERO\nvar team: String = \"enemy\"\nvar data = null\nvar _weapon = null\nvar staff_heal_called: bool = false\nfunc get_equipped_weapon(): return _weapon\nfunc perform_staff_heal(_t, _w): staff_heal_called = true\n"
	stub_script.reload()

	# ---- F9 debug hotseat override: AI phase aborts before acting ----
	var created_gs := false
	var gs_debug := root.get_node_or_null("GameState")
	if gs_debug == null:
		var gs_debug_script := GDScript.new()
		gs_debug_script.source_code = "extends Node\nvar debug_hotseat_override: bool = true\nvar actors: Array[Node] = []\nfunc get_living_units_of(_faction: String) -> Array[Node]: return actors\n"
		gs_debug_script.reload()
		gs_debug = gs_debug_script.new()
		gs_debug.name = "GameState"
		root.add_child(gs_debug)
		created_gs = true
	var old_debug_override: bool = false if created_gs else bool(gs_debug.get("debug_hotseat_override"))
	gs_debug.set("debug_hotseat_override", true)
	if gs_debug.has_method("reset_map_state"):
		gs_debug.call("reset_map_state")
	var debug_actor: Node = stub_script.new()
	debug_actor.set("team", "red")
	var debug_data := UnitData.new()
	debug_data.hp = 20
	debug_data.max_hp = 20
	debug_actor.set("data", debug_data)
	root.add_child(debug_actor)
	if gs_debug.has_method("register_unit"):
		gs_debug.call("register_unit", debug_actor)
	else:
		gs_debug.set("actors", [debug_actor] as Array[Node])
	var debug_turn := TurnManager.new()
	root.add_child(debug_turn)
	var debug_grid := GridManager.new()
	root.add_child(debug_grid)
	await ai.run_phase(debug_grid, debug_turn, "red")
	if debug_turn._unit_states.is_empty():
		print("OK  F9 debug override makes EnemyAI.run_phase abort before acting")
		passed += 1
	else:
		print("FAIL F9 EnemyAI abort: unit_states=%s" % str(debug_turn._unit_states))
		failed += 1
	if gs_debug.has_method("reset_map_state"):
		gs_debug.call("reset_map_state")
	gs_debug.set("debug_hotseat_override", old_debug_override)
	if created_gs:
		root.remove_child(gs_debug)
		gs_debug.free()

	# ---- _find_nearest: returns closer of two units ----
	var from_unit: Node = stub_script.new()
	from_unit.set("tile_position", Vector2i(0, 0))
	var far: Node = stub_script.new()
	far.set("tile_position", Vector2i(5, 0))   # dist 5
	var near: Node = stub_script.new()
	near.set("tile_position", Vector2i(2, 0))  # dist 2
	root.add_child(from_unit); root.add_child(far); root.add_child(near)

	var targets: Array[Node] = [far, near]
	var nearest: Node = ai._find_nearest(from_unit, targets)
	if nearest == near:
		print("OK  _find_nearest returns closer unit (dist 2 vs 5)")
		passed += 1
	else:
		print("FAIL _find_nearest: got wrong unit")
		failed += 1

	# ---- _find_nearest: equal distance → first wins ----
	var eq1: Node = stub_script.new(); eq1.set("tile_position", Vector2i(3, 0))
	var eq2: Node = stub_script.new(); eq2.set("tile_position", Vector2i(0, 3))
	root.add_child(eq1); root.add_child(eq2)
	var eq_targets: Array[Node] = [eq1, eq2]
	var eq_result: Node = ai._find_nearest(from_unit, eq_targets)
	if eq_result == eq1:
		print("OK  _find_nearest tie: first wins")
		passed += 1
	else:
		print("FAIL _find_nearest tie case")
		failed += 1

	# ---- _choose_move_tile: plain 5x5 grid, player at (4,0) ----
	# Enemy at (0,0), move_tiles [0..3 on x]. Default weapon range = 1..1
	# so tile (3,0) is the only moveable tile adjacent to player at (4,0).
	var grid := GridManager.new()
	grid.map_width = 5
	grid.map_height = 5
	for y in 5:
		for x in 5:
			grid.set_terrain_fallback(Vector2i(x, y), "plain")
	root.add_child(grid)

	var enemy: Node = stub_script.new(); enemy.set("tile_position", Vector2i(0, 0))
	var player: Node = stub_script.new()
	player.set("tile_position", Vector2i(4, 0))
	player.set("team", "blue")
	root.add_child(enemy); root.add_child(player)

	var move_tiles: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)
	]
	var all_players: Array[Node] = [player]
	var chosen: Vector2i = ai._choose_move_tile(enemy, player, all_players, move_tiles, grid)
	if chosen == Vector2i(3, 0):
		print("OK  _choose_move_tile picks attack tile (3,0) adjacent to player at (4,0)")
		passed += 1
	else:
		print("FAIL _choose_move_tile: expected (3,0), got %s" % str(chosen))
		failed += 1

	# ---- _choose_move_tile: player out of attack reach → just close distance ----
	var far_player: Node = stub_script.new()
	far_player.set("tile_position", Vector2i(10, 0))
	far_player.set("team", "blue")
	root.add_child(far_player)
	var all_far: Array[Node] = [far_player]
	var chosen2: Vector2i = ai._choose_move_tile(enemy, far_player, all_far, move_tiles, grid)
	if chosen2 == Vector2i(3, 0):
		print("OK  _choose_move_tile moves toward unreachable player")
		passed += 1
	else:
		print("FAIL _choose_move_tile (no attack): expected (3,0), got %s" % str(chosen2))
		failed += 1

	# ---- _choose_move_tile: already at best tile → stays ----
	var enemy2: Node = stub_script.new(); enemy2.set("tile_position", Vector2i(3, 0))
	root.add_child(enemy2)
	var single_tile: Array[Vector2i] = [Vector2i(3, 0)]
	var chosen3: Vector2i = ai._choose_move_tile(enemy2, player, all_players, single_tile, grid)
	if chosen3 == Vector2i(3, 0):
		print("OK  _choose_move_tile stays when already adjacent")
		passed += 1
	else:
		print("FAIL _choose_move_tile stay: expected (3,0), got %s" % str(chosen3))
		failed += 1

	# ---- dijkstra_costs: terrain cost accumulates; walled tiles are unreachable ----
	# Row-0 corridor: plain, plain, forest (cost 2), plain. Every other tile is unset
	# and so reads as "wall" in headless mode, keeping the flood on row 0.
	var cost_grid := GridManager.new()
	cost_grid.map_width = 5
	cost_grid.map_height = 5
	cost_grid.set_terrain_fallback(Vector2i(0, 0), "plain")
	cost_grid.set_terrain_fallback(Vector2i(1, 0), "plain")
	cost_grid.set_terrain_fallback(Vector2i(2, 0), "forest")
	cost_grid.set_terrain_fallback(Vector2i(3, 0), "plain")
	root.add_child(cost_grid)
	var flood := cost_grid.dijkstra_costs(Vector2i(0, 0), 1_000_000, true, null)
	# (3,0): enter(1,0)=1 + enter(2,0)=2 (forest) + enter(3,0)=1 = 4.
	if flood.get(Vector2i(0, 0), -1) == 0 and flood.get(Vector2i(3, 0), -1) == 4:
		print("OK  dijkstra_costs: forest tile adds +2 to accumulated path cost")
		passed += 1
	else:
		print("FAIL dijkstra_costs: (0,0)=%s (3,0)=%s, want 0 / 4" \
			% [flood.get(Vector2i(0,0), -1), flood.get(Vector2i(3,0), -1)])
		failed += 1
	if not flood.has(Vector2i(0, 1)):
		print("OK  dijkstra_costs: walled (unset) tile is unreachable")
		passed += 1
	else:
		print("FAIL dijkstra_costs: walled tile (0,1) was reached")
		failed += 1

	# ---- _find_nearest (grid branch): lowest path cost wins, not Manhattan distance ----
	# A wall at (1,0) forces a 4-step detour to target A at (2,0); target B at (0,3) is
	# a straight 3-step corridor. Manhattan would pick A (dist 2 < 3); the terrain-aware
	# Dijkstra flood must pick B.
	var fn_grid := GridManager.new()
	fn_grid.map_width = 6
	fn_grid.map_height = 6
	for t in [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3),
			Vector2i(1,1), Vector2i(2,1), Vector2i(2,0)]:
		fn_grid.set_terrain_fallback(t, "plain")
	root.add_child(fn_grid)
	var fn_from: Node = stub_script.new(); fn_from.set("tile_position", Vector2i(0, 0))
	var fn_a: Node = stub_script.new(); fn_a.set("tile_position", Vector2i(2, 0))
	var fn_b: Node = stub_script.new(); fn_b.set("tile_position", Vector2i(0, 3))
	root.add_child(fn_from); root.add_child(fn_a); root.add_child(fn_b)
	var fn_targets: Array[Node] = [fn_a, fn_b]
	if ai._find_nearest(fn_from, fn_targets, fn_grid) == fn_b:
		print("OK  _find_nearest (grid): terrain-cheaper target beats Manhattan-nearer one")
		passed += 1
	else:
		print("FAIL _find_nearest (grid): expected the detoured-around target B")
		failed += 1

	# ---- _choose_heal_move_tile: routes to a tile that puts an injured ally in range ----
	var heal_grid := GridManager.new()
	heal_grid.map_width = 6
	heal_grid.map_height = 6
	for x in 6:
		heal_grid.set_terrain_fallback(Vector2i(x, 0), "plain")
	root.add_child(heal_grid)
	var healer: Node = stub_script.new(); healer.set("tile_position", Vector2i(0, 0))
	var injured: Node = stub_script.new(); injured.set("tile_position", Vector2i(4, 0))
	var injured_data := UnitData.new()
	injured_data.hp = 5
	injured_data.max_hp = 20
	injured.set("data", injured_data)
	root.add_child(healer); root.add_child(injured)
	var gs_stub_script := GDScript.new()
	gs_stub_script.source_code = "extends Node\nvar units: Array[Node] = []\nfunc get_living_units_of(_faction: String) -> Array[Node]: return units\n"
	gs_stub_script.reload()
	var gs_stub: Node = gs_stub_script.new()
	var heal_allies: Array[Node] = [healer, injured]
	gs_stub.set("units", heal_allies)
	root.add_child(gs_stub)
	var heal_tiles: Array[Vector2i] = [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)]
	var heal_choice: Vector2i = ai._choose_heal_move_tile(healer, heal_tiles, heal_grid, gs_stub)
	# Range 1 (no weapon) → only (3,0) is adjacent to the injured ally at (4,0).
	if heal_choice == Vector2i(3, 0):
		print("OK  _choose_heal_move_tile: routes to a tile adjacent to the injured ally")
		passed += 1
	else:
		print("FAIL _choose_heal_move_tile: expected (3,0), got %s" % str(heal_choice))
		failed += 1

	# ---- _try_staff_heal: a non-staff weapon heals nobody ----
	var staff_grid := GridManager.new()
	root.add_child(staff_grid)
	var sword_enemy: Node = stub_script.new()
	sword_enemy.set("_weapon", load("res://data/weapons/iron_sword.tres"))
	root.add_child(sword_enemy)
	ai._try_staff_heal(sword_enemy, staff_grid)
	if not sword_enemy.get("staff_heal_called"):
		print("OK  _try_staff_heal: a non-staff weapon performs no heal")
		passed += 1
	else:
		print("FAIL _try_staff_heal: healed while wielding a non-staff weapon")
		failed += 1

	# ---- _try_staff_heal: a staff with no healable allies in range heals nobody ----
	var staff_enemy: Node = stub_script.new()
	staff_enemy.set("_weapon", load("res://data/weapons/heal_staff.tres"))
	root.add_child(staff_enemy)
	ai._try_staff_heal(staff_enemy, staff_grid)
	if not staff_enemy.get("staff_heal_called"):
		print("OK  _try_staff_heal: a staff with no healable target performs no heal")
		passed += 1
	else:
		print("FAIL _try_staff_heal: healed with no valid target")
		failed += 1

	# ---- _living_hostiles_for_faction: green targets red+yellow, not blue ----
	var hs_script := GDScript.new()
	hs_script.source_code = "extends Node\nvar by_faction := {}\nvar groups := {\"blue\":\"allies\",\"green\":\"allies\",\"red\":\"foes\",\"yellow\":\"rogues\"}\nfunc get_registered_faction_ids() -> Array[String]: return [\"blue\",\"green\",\"red\",\"yellow\"]\nfunc are_hostile(a: String, b: String) -> bool: return groups.get(a, a) != groups.get(b, b)\nfunc get_living_units_of(fid: String) -> Array[Node]: return by_faction.get(fid, [] as Array[Node])\n"
	hs_script.reload()
	var hs_gs: Node = hs_script.new()
	var hb: Node = stub_script.new(); hb.set("team", "blue")
	var hg: Node = stub_script.new(); hg.set("team", "green")
	var hr: Node = stub_script.new(); hr.set("team", "red")
	var hy: Node = stub_script.new(); hy.set("team", "yellow")
	hs_gs.set("by_faction", {
		"blue": [hb] as Array[Node],
		"green": [hg] as Array[Node],
		"red": [hr] as Array[Node],
		"yellow": [hy] as Array[Node],
	})
	var green_hostiles: Array[Node] = ai._living_hostiles_for_faction(hs_gs, "green")
	var yellow_hostiles: Array[Node] = ai._living_hostiles_for_faction(hs_gs, "yellow")
	if green_hostiles.has(hr) and green_hostiles.has(hy) and not green_hostiles.has(hb) \
			and not green_hostiles.has(hg):
		print("OK  hostility model: green sees red+yellow as hostiles, not blue")
		passed += 1
	else:
		print("FAIL hostility model green: %s" % str(green_hostiles))
		failed += 1
	if yellow_hostiles.has(hb) and yellow_hostiles.has(hg) and yellow_hostiles.has(hr) \
			and not yellow_hostiles.has(hy):
		print("OK  hostility model: yellow sees blue+green+red as hostiles")
		passed += 1
	else:
		print("FAIL hostility model yellow: %s" % str(yellow_hostiles))
		failed += 1

	# ---- off-map guard: a unit at OFF_MAP_TILE is never a hostile target ----
	# playtest v0.1.4 #4 backstop: a paired support (or any role-desynced off-map
	# unit) must not be targeted or pathed toward, or enemies beeline to the
	# (-1,-1) sentinel — which clamps to the top-left and looks like a rush to (1,1).
	var OFF_MAP_TILE: Vector2i = load("res://scripts/autoloads/PairUpRegistry.gd").OFF_MAP_TILE
	var hr_off: Node = stub_script.new(); hr_off.set("team", "red")
	hr_off.set("tile_position", OFF_MAP_TILE)
	hs_gs.set("by_faction", {
		"blue": [hb] as Array[Node],
		"green": [hg] as Array[Node],
		"red": [hr, hr_off] as Array[Node],
		"yellow": [hy] as Array[Node],
	})
	var guarded: Array[Node] = ai._living_hostiles_for_faction(hs_gs, "green")
	if guarded.has(hr) and not guarded.has(hr_off):
		print("OK  off-map guard: OFF_MAP_TILE unit excluded from hostile targets")
		passed += 1
	else:
		print("FAIL off-map guard: on-map kept=%s off-map excluded=%s" % [
			guarded.has(hr), not guarded.has(hr_off)])
		failed += 1

	# ════════════════════════════════════════════════════════════════════════
	# _act profile dispatch — full passive / basic / healer turns. These need
	# /root/GameState + /root/CombatResolver and a stub unit with an awaitable
	# move_along_path.
	# ════════════════════════════════════════════════════════════════════════

	# These tests need exact /root/GameState and /root/CombatResolver stubs. Move
	# project autoloads out of the tree temporarily so get_node_or_null resolves
	# the scoped fixtures below instead of live map state.
	var real_game_state := root.get_node_or_null("GameState")
	var real_combat_resolver := root.get_node_or_null("CombatResolver")
	if real_game_state != null:
		root.remove_child(real_game_state)
	if real_combat_resolver != null:
		root.remove_child(real_combat_resolver)

	# Stub unit for the _act tests: the _find_nearest stub plus an awaitable
	# move_along_path (a one-frame coroutine, like the real Unit.move_along_path).
	var act_stub := GDScript.new()
	act_stub.source_code = "extends Node\nvar tile_position: Vector2i = Vector2i.ZERO\nvar team: String = \"enemy\"\nvar data = null\nvar _weapon = null\nvar staff_heal_called: bool = false\nfunc get_equipped_weapon(): return _weapon\nfunc perform_staff_heal(_t, _w): staff_heal_called = true\nfunc move_along_path(p):\n\ttile_position = p[p.size() - 1]\n\tawait get_tree().process_frame\n"
	act_stub.reload()

	# Stub GameState: EnemyAI reads per-faction unit buckets + hostility checks;
	# GridManager reads all_units. Arrays are repopulated per test.
	var act_gs_script := GDScript.new()
	act_gs_script.source_code = "extends Node\nvar all_units: Array[Node] = []\nvar players: Array[Node] = []\nvar enemies: Array[Node] = []\nvar debug_hotseat_override: bool = false\nfunc get_living_player_units() -> Array[Node]: return players\nfunc get_living_enemy_units() -> Array[Node]: return enemies\nfunc get_registered_faction_ids() -> Array[String]: return [\"blue\", \"red\"]\nfunc are_hostile(a: String, b: String) -> bool: return a != b\nfunc get_living_units_of(faction: String) -> Array[Node]: return players if faction == \"blue\" else enemies\nfunc is_player_turn() -> bool: return false\n"
	act_gs_script.reload()
	var act_gs: Node = act_gs_script.new()
	act_gs.name = "GameState"
	root.add_child(act_gs)

	# Stub CombatResolver: records resolve_combat so the attack tests can assert it.
	var act_cr_script := GDScript.new()
	act_cr_script.source_code = "extends Node\nvar resolve_called: bool = false\nvar last_target = null\nfunc resolve_combat(_a, b):\n\tresolve_called = true\n\tlast_target = b\n\treturn {}\nfunc apply_combat_result(_r, _a, _b): pass\n"
	act_cr_script.reload()
	var act_cr: Node = act_cr_script.new()
	act_cr.name = "CombatResolver"
	root.add_child(act_cr)

	# Shared 8x3 plain grid + a TurnManager for the _act tests.
	var act_grid := GridManager.new()
	act_grid.map_width = 8
	act_grid.map_height = 3
	for ay in 3:
		for ax in 8:
			act_grid.set_terrain_fallback(Vector2i(ax, ay), "plain")
	root.add_child(act_grid)
	var act_turn := TurnManager.new()
	root.add_child(act_turn)

	# Let the tree go active so nodes report is_inside_tree() and EnemyAI's
	# get_node_or_null("/root/GameState" / "/root/CombatResolver") resolves.
	await process_frame

	# ---- _act passive: holds position, no combat when no player is in range ----
	var pas_enemy := _mk_act_unit(act_stub, Vector2i(0, 0), "red", "passive", 20,
		"res://data/weapons/iron_sword.tres")
	var pas_player := _mk_act_unit(act_stub, Vector2i(6, 0), "blue", "basic", 20, "")
	var pas_units: Array[Node] = [pas_enemy, pas_player]
	var pas_players: Array[Node] = [pas_player]
	var pas_enemies: Array[Node] = [pas_enemy]
	act_gs.set("all_units", pas_units)
	act_gs.set("players", pas_players)
	act_gs.set("enemies", pas_enemies)
	act_cr.set("resolve_called", false)
	await ai._act(pas_enemy, act_grid, act_turn)
	if pas_enemy.tile_position == Vector2i(0, 0) \
			and act_turn.get_unit_state(pas_enemy) == TurnManager.UnitState.DONE \
			and not act_cr.get("resolve_called"):
		print("OK  _act passive: holds position, no combat with no target in range")
		passed += 1
	else:
		print("FAIL _act passive hold: tile=%s state=%d resolve=%s" % [
			str(pas_enemy.tile_position), act_turn.get_unit_state(pas_enemy),
			act_cr.get("resolve_called")])
		failed += 1

	# ---- _act passive: attacks a player already in range, still does not move ----
	var pa_enemy := _mk_act_unit(act_stub, Vector2i(2, 1), "red", "passive", 20,
		"res://data/weapons/iron_sword.tres")
	var pa_player := _mk_act_unit(act_stub, Vector2i(3, 1), "blue", "basic", 20, "")
	var pa_units: Array[Node] = [pa_enemy, pa_player]
	var pa_players: Array[Node] = [pa_player]
	var pa_enemies: Array[Node] = [pa_enemy]
	act_gs.set("all_units", pa_units)
	act_gs.set("players", pa_players)
	act_gs.set("enemies", pa_enemies)
	act_cr.set("resolve_called", false)
	act_cr.set("last_target", null)
	await ai._act(pa_enemy, act_grid, act_turn)
	if pa_enemy.tile_position == Vector2i(2, 1) and act_cr.get("resolve_called") \
			and act_cr.get("last_target") == pa_player \
			and act_turn.get_unit_state(pa_enemy) == TurnManager.UnitState.DONE:
		print("OK  _act passive: attacks an adjacent player without moving")
		passed += 1
	else:
		print("FAIL _act passive attack: tile=%s resolve=%s state=%d" % [
			str(pa_enemy.tile_position), act_cr.get("resolve_called"),
			act_turn.get_unit_state(pa_enemy)])
		failed += 1

	# ---- _act basic: no living players → marks DONE immediately, no move ----
	var nb_enemy := _mk_act_unit(act_stub, Vector2i(1, 1), "red", "basic", 20,
		"res://data/weapons/iron_sword.tres")
	var nb_units: Array[Node] = [nb_enemy]
	var nb_empty: Array[Node] = []
	act_gs.set("all_units", nb_units)
	act_gs.set("players", nb_empty)
	act_gs.set("enemies", nb_units)
	await ai._act(nb_enemy, act_grid, act_turn)
	if nb_enemy.tile_position == Vector2i(1, 1) \
			and act_turn.get_unit_state(nb_enemy) == TurnManager.UnitState.DONE:
		print("OK  _act basic: no players → DONE without moving")
		passed += 1
	else:
		print("FAIL _act basic no-players: tile=%s state=%d" % [
			str(nb_enemy.tile_position), act_turn.get_unit_state(nb_enemy)])
		failed += 1

	# ---- _act basic: closes on a distant player and attacks from in range ----
	var bm_enemy := _mk_act_unit(act_stub, Vector2i(0, 0), "red", "basic", 20,
		"res://data/weapons/iron_sword.tres")
	var bm_player := _mk_act_unit(act_stub, Vector2i(4, 0), "blue", "basic", 20, "")
	var bm_units: Array[Node] = [bm_enemy, bm_player]
	var bm_players: Array[Node] = [bm_player]
	var bm_enemies: Array[Node] = [bm_enemy]
	act_gs.set("all_units", bm_units)
	act_gs.set("players", bm_players)
	act_gs.set("enemies", bm_enemies)
	act_cr.set("resolve_called", false)
	act_cr.set("last_target", null)
	# Watch for the post-move camera re-pan (#7): _act emits ai_unit_acting once
	# the enemy has moved, so combat resolves on-screen.
	var bm_panned := [false]
	var ev_bus := root.get_node_or_null("EventBus")
	if ev_bus != null:
		ev_bus.ai_unit_acting.connect(func(u): if u == bm_enemy: bm_panned[0] = true)
	await ai._act(bm_enemy, act_grid, act_turn)
	var bm_moved: bool = bm_enemy.tile_position != Vector2i(0, 0)
	var bm_adj: int = absi(bm_enemy.tile_position.x - 4) + absi(bm_enemy.tile_position.y)
	if bm_moved and bm_adj == 1 and act_cr.get("resolve_called") \
			and act_cr.get("last_target") == bm_player \
			and act_turn.get_unit_state(bm_enemy) == TurnManager.UnitState.DONE:
		print("OK  _act basic: closes on a distant player and attacks (moved to %s)" \
			% str(bm_enemy.tile_position))
		passed += 1
	else:
		print("FAIL _act basic move+attack: tile=%s resolve=%s state=%d" % [
			str(bm_enemy.tile_position), act_cr.get("resolve_called"),
			act_turn.get_unit_state(bm_enemy)])
		failed += 1

	# Re-pan: the enemy moved, so _act should have re-announced it (#7).
	if ev_bus == null:
		print("SKIP _act re-pan check (EventBus autoload absent)")
	elif bm_panned[0]:
		print("OK  _act re-pans the camera onto the moved enemy (#7)"); passed += 1
	else:
		print("FAIL _act did not emit ai_unit_acting after moving"); failed += 1

	# ---- _act healer: routes into staff range of an injured ally and heals it.
	#      Regression guard for the can_attack_from_tile-vs-staff bug — a healer
	#      carrying a real staff must still route via in_weapon_range_from_tile.
	var hl_healer := _mk_act_unit(act_stub, Vector2i(0, 0), "red", "healer", 20,
		"res://data/weapons/heal_staff.tres")
	var hl_injured := _mk_act_unit(act_stub, Vector2i(4, 0), "red", "basic", 5, "")
	var hl_units: Array[Node] = [hl_healer, hl_injured]
	var hl_empty: Array[Node] = []
	act_gs.set("all_units", hl_units)
	act_gs.set("players", hl_empty)
	act_gs.set("enemies", hl_units)
	await ai._act(hl_healer, act_grid, act_turn)
	var hl_moved: bool = hl_healer.tile_position != Vector2i(0, 0)
	if hl_moved and hl_healer.get("staff_heal_called") \
			and act_turn.get_unit_state(hl_healer) == TurnManager.UnitState.DONE:
		print("OK  _act healer: routes to an injured ally and heals (moved to %s)" \
			% str(hl_healer.tile_position))
		passed += 1
	else:
		print("FAIL _act healer route+heal: tile=%s healed=%s state=%d" % [
			str(hl_healer.tile_position), hl_healer.get("staff_heal_called"),
			act_turn.get_unit_state(hl_healer)])
		failed += 1

	# ---- _act healer: all allies at full HP → no reposition, no heal, DONE ----
	var hn_healer := _mk_act_unit(act_stub, Vector2i(2, 1), "red", "healer", 20,
		"res://data/weapons/heal_staff.tres")
	var hn_ally := _mk_act_unit(act_stub, Vector2i(4, 1), "red", "basic", 20, "")
	var hn_units: Array[Node] = [hn_healer, hn_ally]
	var hn_empty: Array[Node] = []
	act_gs.set("all_units", hn_units)
	act_gs.set("players", hn_empty)
	act_gs.set("enemies", hn_units)
	await ai._act(hn_healer, act_grid, act_turn)
	if hn_healer.tile_position == Vector2i(2, 1) \
			and not hn_healer.get("staff_heal_called") \
			and act_turn.get_unit_state(hn_healer) == TurnManager.UnitState.DONE:
		print("OK  _act healer: no injured ally → holds position, no heal")
		passed += 1
	else:
		print("FAIL _act healer idle: tile=%s healed=%s state=%d" % [
			str(hn_healer.tile_position), hn_healer.get("staff_heal_called"),
			act_turn.get_unit_state(hn_healer)])
		failed += 1

	# ════════════════════════════════════════════════════════════════════════
	# V021-01 — hotseat activation boundary: run_phase must not re-move spent
	# units on an F9 re-run, and a mid-activation F9 handoff must roll the
	# acting unit back to its activation-start tile (no "moved without spending
	# its turn" teleport).
	# ════════════════════════════════════════════════════════════════════════

	# ---- run_phase skips a unit that already finished (no re-move on re-run) ----
	var rm_enemy := _mk_act_unit(act_stub, Vector2i(0, 0), "red", "basic", 20,
		"res://data/weapons/iron_sword.tres")
	var rm_player := _mk_act_unit(act_stub, Vector2i(4, 0), "blue", "basic", 20, "")
	var rm_units: Array[Node] = [rm_enemy, rm_player]
	act_gs.set("all_units", rm_units)
	act_gs.set("players", [rm_player] as Array[Node])
	act_gs.set("enemies", [rm_enemy] as Array[Node])
	act_turn.set_unit_state(rm_enemy, TurnManager.UnitState.DONE)  # already acted
	act_cr.set("resolve_called", false)
	await ai.run_phase(act_grid, act_turn, "red")
	if rm_enemy.tile_position == Vector2i(0, 0) and not act_cr.get("resolve_called") \
			and act_turn.get_unit_state(rm_enemy) == TurnManager.UnitState.DONE:
		print("OK  V021-01 run_phase: a DONE unit is not re-moved on re-run")
		passed += 1
	else:
		print("FAIL V021-01 re-move guard: tile=%s resolve=%s state=%d" % [
			str(rm_enemy.tile_position), act_cr.get("resolve_called"),
			act_turn.get_unit_state(rm_enemy)])
		failed += 1

	# ---- mid-activation F9 flip rolls the unit back to its start tile + READY ----
	# This stub flips the debug-hotseat override the instant it moves, simulating
	# the player pressing F9 while an AI unit's move is in flight.
	var rb_stub := GDScript.new()
	rb_stub.source_code = "extends Node\nvar tile_position: Vector2i = Vector2i.ZERO\nvar team: String = \"red\"\nvar data = null\nvar _weapon = null\nvar staff_heal_called: bool = false\nvar gs_ref = null\nfunc get_equipped_weapon(): return _weapon\nfunc perform_staff_heal(_t, _w): staff_heal_called = true\nfunc snap_to_tile(t): tile_position = t\nfunc move_along_path(p):\n\ttile_position = p[p.size() - 1]\n\tif gs_ref != null: gs_ref.debug_hotseat_override = true\n\tawait get_tree().process_frame\n"
	rb_stub.reload()
	var rb_enemy := _mk_act_unit(rb_stub, Vector2i(0, 0), "red", "basic", 20,
		"res://data/weapons/iron_sword.tres")
	rb_enemy.set("gs_ref", act_gs)
	var rb_player := _mk_act_unit(act_stub, Vector2i(4, 0), "blue", "basic", 20, "")
	act_gs.set("all_units", [rb_enemy, rb_player] as Array[Node])
	act_gs.set("players", [rb_player] as Array[Node])
	act_gs.set("enemies", [rb_enemy] as Array[Node])
	act_gs.set("debug_hotseat_override", false)
	act_cr.set("resolve_called", false)
	await ai.run_phase(act_grid, act_turn, "red")
	if rb_enemy.tile_position == Vector2i(0, 0) \
			and act_turn.get_unit_state(rb_enemy) == TurnManager.UnitState.READY \
			and not act_cr.get("resolve_called"):
		print("OK  V021-01 run_phase: mid-activation F9 rolls the unit back to start + READY")
		passed += 1
	else:
		print("FAIL V021-01 mid-move rollback: tile=%s state=%d resolve=%s" % [
			str(rb_enemy.tile_position), act_turn.get_unit_state(rb_enemy),
			act_cr.get("resolve_called")])
		failed += 1
	act_gs.set("debug_hotseat_override", false)

	root.remove_child(act_gs)
	act_gs.free()
	root.remove_child(act_cr)
	act_cr.free()
	if real_game_state != null:
		root.add_child(real_game_state)
	if real_combat_resolver != null:
		root.add_child(real_combat_resolver)

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


# Builds an _act-test stub unit with a fresh UnitData. weapon_path "" → no weapon.
func _mk_act_unit(stub: GDScript, tile: Vector2i, team_name: String,
		profile: String, hp: int, weapon_path: String) -> Node:
	var d := UnitData.new()
	d.ai_profile = profile
	d.hp = hp
	d.max_hp = 20
	d.movement = 5
	var u: Node = stub.new()
	u.set("tile_position", tile)
	u.set("team", team_name)
	u.set("data", d)
	if weapon_path != "":
		u.set("_weapon", load(weapon_path))
	root.add_child(u)
	return u
