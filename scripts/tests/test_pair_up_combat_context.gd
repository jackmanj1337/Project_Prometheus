extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_pair_up_combat_context.gd
# Covers step 3 of the Pair Up refactor: combat context now carries
# attacker_support / defender_support keys, resolved via PairUpRegistry plus
# GameState.find_unit_by_id. Also exercises the new GameState.find_unit_by_id
# helper directly.


# A minimal Unit-shaped stub. CombatResolver._build_combat_context reads
# `attacker.team`, `attacker.tile_position`, `attacker.data`, and calls
# attacker.get_equipped_weapon()/can_counterattack — the stub satisfies just
# those reads so the context build path runs without a real Unit scene.
func _mk_unit_stub() -> GDScript:
	var src := """
extends Node
var team: String = \"blue\"
var data = null
var tile_position: Vector2i = Vector2i.ZERO
func get_equipped_weapon():
	return null
"""
	var script := GDScript.new()
	script.source_code = src
	script.reload()
	return script


func _mk_unit(stub: GDScript, unit_id: String, team_name: String) -> Node:
	var d := UnitData.new()
	d.unit_id = unit_id
	d.max_hp = 20
	d.hp = 20
	var u: Node = stub.new()
	u.set("team", team_name)
	u.set("data", d)
	root.add_child(u)
	return u


func _init() -> void:
	print("=== Pair Up Combat Context Test ===")
	var passed := 0
	var failed := 0

	# Bring the live autoloads into the test context via the relay-node pattern.
	var relay := Node.new()
	root.add_child(relay)
	await process_frame
	var gs := relay.get_node_or_null("/root/GameState")
	var reg := relay.get_node_or_null("/root/PairUpRegistry")
	var cr := relay.get_node_or_null("/root/CombatResolver")
	relay.queue_free()
	if gs == null or reg == null or cr == null:
		print(
			(
				"BAIL: missing autoload (GameState=%s PairUpRegistry=%s CombatResolver=%s)"
				% [gs != null, reg != null, cr != null]
			)
		)
		quit(1)
		return

	# Start from a clean state so previous-test residue does not leak in.
	reg.call("clear")
	gs.reset_map_state()

	var stub := _mk_unit_stub()
	var chrom := _mk_unit(stub, "chrom", "blue")
	var lissa := _mk_unit(stub, "lissa", "blue")
	var marth := _mk_unit(stub, "marth", "red")
	gs.register_unit(chrom)
	gs.register_unit(lissa)
	gs.register_unit(marth)

	# ---- find_unit_by_id ----
	if gs.find_unit_by_id("chrom") == chrom and gs.find_unit_by_id("lissa") == lissa:
		print("OK  find_unit_by_id returns the matching registered unit")
		passed += 1
	else:
		print("FAIL find_unit_by_id wrong unit")
		failed += 1

	if gs.find_unit_by_id("ghost") == null and gs.find_unit_by_id("") == null:
		print("OK  find_unit_by_id returns null for unknown / empty ids")
		passed += 1
	else:
		print("FAIL find_unit_by_id should return null for unknown/empty")
		failed += 1

	# ---- Combat context: unpaired ----
	var ctx_unpaired: Dictionary = cr.call("_build_combat_context", chrom, marth)
	if (
		ctx_unpaired.has("attacker_support")
		and ctx_unpaired.has("defender_support")
		and ctx_unpaired["attacker_support"] == null
		and ctx_unpaired["defender_support"] == null
	):
		print("OK  context exposes attacker_support / defender_support as null when unpaired")
		passed += 1
	else:
		print(
			(
				"FAIL unpaired context missing keys or non-null: atk=%s def=%s keys=%s"
				% [
					ctx_unpaired.get("attacker_support"),
					ctx_unpaired.get("defender_support"),
					ctx_unpaired.has("attacker_support")
				]
			)
		)
		failed += 1

	# ---- Combat context: attacker paired ----
	reg.pair("chrom", "lissa")
	var ctx_atk_paired: Dictionary = cr.call("_build_combat_context", chrom, marth)
	if ctx_atk_paired["attacker_support"] == lissa and ctx_atk_paired["defender_support"] == null:
		print("OK  attacker_support resolves to the paired partner Node")
		passed += 1
	else:
		print(
			(
				"FAIL attacker_support wrong: got %s expected %s"
				% [ctx_atk_paired["attacker_support"], lissa]
			)
		)
		failed += 1

	# ---- Combat context: defender paired ----
	reg.call("clear")
	reg.pair("marth", "chrom")  # marth becomes the defender's lead, chrom is support
	# Need a different attacker since chrom is now in marth's pair. Use lissa.
	var ctx_def_paired: Dictionary = cr.call("_build_combat_context", lissa, marth)
	if ctx_def_paired["defender_support"] == chrom and ctx_def_paired["attacker_support"] == null:
		print("OK  defender_support resolves to the paired partner Node")
		passed += 1
	else:
		print(
			(
				"FAIL defender_support wrong: got %s expected %s"
				% [ctx_def_paired["defender_support"], chrom]
			)
		)
		failed += 1

	# ---- Partner registered but not in all_units → null (defensive) ----
	reg.call("clear")
	reg.pair("chrom", "phantom")  # phantom has no registered Unit node
	var ctx_orphan: Dictionary = cr.call("_build_combat_context", chrom, marth)
	if ctx_orphan["attacker_support"] == null:
		print("OK  partner_id with no registered Unit yields null support")
		passed += 1
	else:
		print(
			(
				"FAIL orphan partner should produce null support, got %s"
				% ctx_orphan["attacker_support"]
			)
		)
		failed += 1

	# Clean up so following tests in the same run-tests pass start fresh.
	reg.call("clear")
	gs.reset_map_state()

	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
