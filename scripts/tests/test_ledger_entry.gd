extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_ledger_entry.gd
# B1-LEDGER Phase 1: the within-map history entry is SUSPEND-COMPLETE — it carries
# ALL factions' units (enemy HP + board position included) and the turn state, not
# just the player party the old Retry snapshot captured. This test proves the entry
# round-trips that enemy/turn state through JSON, that take_map_snapshot seeds the
# round-0 entry, and it LOGS one serialized entry's byte size — the Phase 1 exit
# measurement that gates the deferrable Rewind phase (a heavy board caps the tier
# budgets). Mirrors test_suspend_map_runtime's real-board harness.

const PairUpRegistryScript = preload("res://scripts/autoloads/PairUpRegistry.gd")


func _ensure_autoload(node_name: String, path: String) -> Node:
	var node := root.get_node_or_null(node_name)
	if node != null:
		return node
	node = load(path).new()
	node.name = node_name
	root.add_child(node)
	return node


func _find_unit(units_container: Node, unit_id: String) -> Node:
	for child in units_container.get_children():
		if child.get("data") != null and child.data.unit_id == unit_id:
			return child
	return null


# Pull one serialized unit dict out of an entry's map_runtime.units array by id.
func _entry_unit(entry: Dictionary, unit_id: String) -> Dictionary:
	for unit_dict in entry.get("map_runtime", {}).get("units", []):
		if unit_dict is Dictionary and String(unit_dict.get("unit_id", "")) == unit_id:
			return unit_dict
	return {}


func _init() -> void:
	print("=== Ledger Entry Round-Trip + Measurement Test (B1-LEDGER Phase 1) ===")
	var passed := 0
	var failed := 0

	_ensure_autoload("EventBus", "res://scripts/autoloads/EventBus.gd")
	_ensure_autoload("DataManager", "res://scripts/autoloads/DataManager.gd")
	var pair_reg: Node = _ensure_autoload(
		"PairUpRegistry", "res://scripts/autoloads/PairUpRegistry.gd"
	)
	var rng: Node = _ensure_autoload("RngService", "res://scripts/autoloads/RngService.gd")
	var gs: Node = _ensure_autoload("GameState", "res://scripts/autoloads/GameState.gd")
	await process_frame

	var packed: PackedScene = load("res://scenes/core/GameMap.tscn")
	gs.reset_map_state()
	gs.load_default_roster()
	gs.configure_next_map("res://data/maps/map_001_rout/map_001_data.tres", "default_roster", "")
	rng.start_map(20260715)

	var map_node: Node = packed.instantiate()
	root.add_child(map_node)
	await process_frame

	var units: Node = map_node.get_node("UnitsContainer")
	var cursor: MapCursor = map_node.get_node("MapCursor")
	var turn: TurnManager = map_node.get_node("TurnManager")
	var blue_a: Node = _find_unit(units, "unit_01_cavalier")
	var blue_b: Node = _find_unit(units, "unit_02_mercenary")
	var boss: Node = _find_unit(units, "e8_knight_boss")
	if blue_a == null or blue_b == null or boss == null:
		print("FAIL setup: expected units missing")
		quit(1)
		return
	var boss_id: String = boss.data.unit_id
	var blue_a_id: String = blue_a.data.unit_id
	var blue_b_id: String = blue_b.data.unit_id

	# ---- take_map_snapshot seeds exactly one round-0 history entry ----
	# GameMap already called it on spawn; a fresh call re-seeds a single entry.
	gs.take_map_snapshot()
	var round0: Dictionary = gs.peek_history(0)
	if (
		gs.history_size() == 1
		and round0.get("map_runtime", {}).get("units", []).size() == gs.all_units.size()
	):
		print(
			(
				"OK  take_map_snapshot seeds one round-0 entry carrying all factions (%d units)"
				% gs.all_units.size()
			)
		)
		passed += 1
	else:
		print(
			(
				"FAIL round-0 seed: size=%d units=%s all=%d"
				% [
					gs.history_size(),
					round0.get("map_runtime", {}).get("units", []).size(),
					gs.all_units.size()
				]
			)
		)
		failed += 1

	# ---- mid-map mutations that the party-only snapshot could never capture ----
	boss.data.hp = 4
	boss.snap_to_tile(Vector2i(10, 11))
	pair_reg.call("pair", blue_a_id, blue_b_id)
	turn._activation_mode = "ALTERNATING"
	turn._turn_order = ["blue", "red"] as Array[String]
	turn._active_faction_idx = 1
	turn._unit_states[boss] = TurnManager.UnitState.READY
	gs.turn_number = 3
	gs.set_phase(gs.Phase.ENEMY, "red")

	# Push a full mid-map entry WITH the turn manager + cursor, then JSON round-trip it
	# exactly as a save file would, and confirm the enemy + turn state survive.
	gs.push_history(turn, cursor)
	var live: Dictionary = gs.peek_history(gs.history_size() - 1)
	var roundtripped: Dictionary = JSON.parse_string(JSON.stringify(live))

	var boss_dict: Dictionary = _entry_unit(roundtripped, boss_id)
	var boss_hp_ok: bool = int(boss_dict.get("hp", -1)) == 4
	var boss_pos: Dictionary = boss_dict.get("tile_position", {})
	var boss_pos_ok: bool = int(boss_pos.get("x", -1)) == 10 and int(boss_pos.get("y", -1)) == 11
	var boss_faction_ok: bool = String(boss_dict.get("faction", "")) == "red"
	if boss_hp_ok and boss_pos_ok and boss_faction_ok:
		print("OK  entry round-trips enemy HP (4), board position (10,11), and faction (red)")
		passed += 1
	else:
		print(
			(
				"FAIL enemy round-trip: hp_ok=%s pos_ok=%s faction_ok=%s dict=%s"
				% [boss_hp_ok, boss_pos_ok, boss_faction_ok, boss_dict]
			)
		)
		failed += 1

	var turn_dict: Dictionary = roundtripped.get("map_runtime", {}).get("turn", {})
	var turn_ok: bool = (
		String(turn_dict.get("active_faction", "")) == "red"
		and int(turn_dict.get("unit_states", {}).get(boss_id, -1)) == TurnManager.UnitState.READY
	)
	if turn_ok:
		print("OK  entry round-trips turn state (active_faction=red, boss READY)")
		passed += 1
	else:
		print("FAIL turn round-trip: %s" % turn_dict)
		failed += 1

	# ---- Phase 1 exit measurement: one serialized board entry's byte size ----
	# Reported both as compact binary (var_to_bytes) and JSON text length, so Phase 3
	# can size the two-tier tier budgets against real memory, not a guess.
	var bin_bytes: int = var_to_bytes(live).size()
	var json_bytes: int = JSON.stringify(live).length()
	print(
		(
			"MEASURE one suspend-complete ledger entry: %d units, %d bytes binary, %d bytes JSON"
			% [live.get("map_runtime", {}).get("units", []).size(), bin_bytes, json_bytes]
		)
	)

	# ---- B1-LEDGER Phase 2: party economy is folded PER ENTRY and a Retry
	# (restore_history(0)) rolls it back — the DECIDED-2026-07-15 party-per-entry
	# rule that lets a mid-map rewind undo a village/chest reward. Runs LAST: the
	# restore calls reset_map_state, which tears down the shared board. ----
	gs.party_gold = 500
	gs.party_items = ["vulnerary"] as Array[String]
	gs.take_map_snapshot()  # re-seed round-0 with this economy
	var entry_party: Dictionary = gs.peek_history(0).get("party", {})
	var folded_ok: bool = (
		int(entry_party.get("gold", -1)) == 500
		and entry_party.get("items", []) == ["vulnerary"]
		and entry_party.get("roster", []).size() == gs.player_roster.size()
	)
	# Simulate mid-map rewards, then Retry: the ledger must roll both back.
	gs.party_gold = 999
	gs.party_items = ["elixir", "elixir"] as Array[String]
	var restored: bool = gs.restore_history(0)
	var rollback_ok: bool = restored and gs.party_gold == 500 and gs.party_items == ["vulnerary"]
	if folded_ok and rollback_ok:
		print("OK  entry folds party economy; restore_history(0) rolls gold/items back")
		passed += 1
	else:
		print(
			(
				"FAIL party economy: folded=%s rollback=%s gold=%d items=%s"
				% [folded_ok, rollback_ok, gs.party_gold, gs.party_items]
			)
		)
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
