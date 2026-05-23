extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_pair_up_registry.gd
# Covers PairUpRegistry: pair/separate/swap mutations, query helpers, serialize/
# restore round-trips, and the GameState snapshot/restore integration.

const PairUpRegistryS = preload("res://scripts/autoloads/PairUpRegistry.gd")


func _init() -> void:
	print("=== PairUpRegistry Test ===")
	var passed := 0
	var failed := 0

	# ---- Direct instance unit tests ----
	# Instantiated without add_child so no autoload entanglement; the registry
	# has no _ready dependencies so this is sufficient.
	var reg: Node = PairUpRegistryS.new()

	# pair: establishes both sides with correct roles
	var ok_pair: bool = reg.pair("chrom", "lissa")
	if ok_pair and reg.is_paired("chrom") and reg.is_paired("lissa") \
			and reg.get_partner_id("chrom") == "lissa" \
			and reg.get_partner_id("lissa") == "chrom" \
			and reg.is_lead("chrom") and reg.is_support("lissa"):
		print("OK  pair establishes both sides with lead/support roles"); passed += 1
	else:
		print("FAIL pair: ok=%s chrom_paired=%s lissa_paired=%s chrom_role=%s lissa_role=%s" \
			% [ok_pair, reg.is_paired("chrom"), reg.is_paired("lissa"),
			reg.get_role("chrom"), reg.get_role("lissa")])
		failed += 1

	# pair: refuses if either side is already paired
	var refused_already: bool = not reg.pair("chrom", "robin") and not reg.pair("robin", "lissa")
	if refused_already and not reg.is_paired("robin"):
		print("OK  pair refuses when either id is already paired"); passed += 1
	else:
		print("FAIL pair did not refuse repartner"); failed += 1

	# pair: refuses empty ids and self-pair
	if not reg.pair("", "robin") and not reg.pair("robin", "") \
			and not reg.pair("robin", "robin"):
		print("OK  pair refuses empty ids and self-pair"); passed += 1
	else:
		print("FAIL pair accepted invalid arguments"); failed += 1

	# swap_roles: flips lead and support
	var ok_swap: bool = reg.swap_roles("chrom")
	if ok_swap and reg.is_support("chrom") and reg.is_lead("lissa"):
		print("OK  swap_roles flips lead/support"); passed += 1
	else:
		print("FAIL swap_roles: ok=%s chrom_role=%s lissa_role=%s" \
			% [ok_swap, reg.get_role("chrom"), reg.get_role("lissa")])
		failed += 1

	# swap_roles: refused for unpaired
	if not reg.swap_roles("robin") and not reg.swap_roles(""):
		print("OK  swap_roles refuses unpaired/empty ids"); passed += 1
	else:
		print("FAIL swap_roles accepted unpaired/empty"); failed += 1

	# separate: clears both sides
	var ok_sep: bool = reg.separate("lissa")
	if ok_sep and not reg.is_paired("chrom") and not reg.is_paired("lissa") \
			and reg.get_partner_id("chrom") == "" and reg.get_role("chrom") == "":
		print("OK  separate clears both sides of the pair"); passed += 1
	else:
		print("FAIL separate left residue: chrom_paired=%s lissa_paired=%s" \
			% [reg.is_paired("chrom"), reg.is_paired("lissa")])
		failed += 1

	# separate: idempotent no-op on unpaired
	if not reg.separate("chrom") and not reg.separate(""):
		print("OK  separate is a safe no-op on unpaired/empty"); passed += 1
	else:
		print("FAIL separate returned true for unpaired/empty"); failed += 1

	# ---- serialize / restore round-trip ----
	reg.clear()
	reg.pair("chrom", "lissa")
	reg.pair("robin", "lucina")
	var snap: Dictionary = reg.serialize()

	# Mutating the snapshot must NOT bleed back into the registry (deep-copy guarantee).
	snap["chrom"]["partner_id"] = "tampered"
	if reg.get_partner_id("chrom") == "lissa":
		print("OK  serialize returns a deep copy (snapshot mutation isolated)"); passed += 1
	else:
		print("FAIL snapshot mutation leaked into registry: chrom partner=%s" \
			% reg.get_partner_id("chrom"))
		failed += 1

	# Same the other way: mutating the registry after snapshot must not change snap.
	# Re-take a clean snapshot first so the previous tamper does not pollute this case.
	snap = reg.serialize()
	reg.separate("chrom")
	if snap.has("chrom") and snap["chrom"].get("partner_id", "") == "lissa":
		print("OK  registry mutations after serialize do not alter the snapshot"); passed += 1
	else:
		print("FAIL snapshot was mutated by post-serialize separate"); failed += 1

	# restore: replaces registry contents wholesale
	reg.clear()
	reg.pair("severa", "owain")  # noise that should be gone after restore
	reg.restore(snap)
	if reg.get_partner_id("chrom") == "lissa" and reg.is_lead("chrom") \
			and reg.get_partner_id("robin") == "lucina" \
			and not reg.is_paired("severa") and not reg.is_paired("owain"):
		print("OK  restore replaces registry contents wholesale"); passed += 1
	else:
		print("FAIL restore left wrong state: severa_paired=%s chrom_partner=%s" \
			% [reg.is_paired("severa"), reg.get_partner_id("chrom")])
		failed += 1

	# restore with empty dict clears the registry
	reg.restore({})
	if not reg.is_paired("chrom") and not reg.is_paired("robin"):
		print("OK  restore({}) clears the registry"); passed += 1
	else:
		print("FAIL restore({}) left pairings behind"); failed += 1

	# ---- GameState integration ----
	# GameState's take_map_snapshot / restore_map_snapshot must capture and
	# restore Pair Up state alongside unit data. Use the autoload via relay-node
	# pattern so /root paths resolve from --script context.
	var relay := Node.new()
	root.add_child(relay)
	await process_frame
	var gs := relay.get_node_or_null("/root/GameState")
	var live_reg := relay.get_node_or_null("/root/PairUpRegistry")
	relay.queue_free()
	if gs == null or live_reg == null:
		print("BAIL: GameState or PairUpRegistry autoload missing — skipping integration tests")
	else:
		live_reg.call("clear")
		live_reg.pair("chrom", "lissa")
		# Snapshot captures the current pairing.
		gs.take_map_snapshot()
		# Mutate post-snapshot, then verify restore rewinds to the snapshotted state.
		live_reg.separate("chrom")
		live_reg.pair("robin", "lucina")
		gs.restore_map_snapshot()
		if live_reg.get_partner_id("chrom") == "lissa" and live_reg.is_lead("chrom") \
				and not live_reg.is_paired("robin"):
			print("OK  GameState snapshot round-trips Pair Up state"); passed += 1
		else:
			print("FAIL GameState restore did not rewind pairings: chrom=%s robin_paired=%s" \
				% [live_reg.get_partner_id("chrom"), live_reg.is_paired("robin")])
			failed += 1
		# reset_map_state must clear the live registry.
		live_reg.pair("severa", "owain")
		gs.reset_map_state()
		if not live_reg.is_paired("severa") and not live_reg.is_paired("owain"):
			print("OK  GameState.reset_map_state clears the registry"); passed += 1
		else:
			print("FAIL reset_map_state left pairings live"); failed += 1
		# Campaign gate: when GameState.pair_up_enabled is false, pair() refuses
		# new pairings but separate/restore/queries still work on existing ones.
		live_reg.call("clear")
		live_reg.pair("chrom", "lissa")  # established while gate is open
		var prior_enabled: bool = bool(gs.get("pair_up_enabled"))
		gs.set("pair_up_enabled", false)
		var refused_disabled: bool = not live_reg.pair("robin", "lucina")
		var sep_still_works: bool = live_reg.separate("chrom")
		gs.set("pair_up_enabled", prior_enabled)  # restore default for other tests
		if refused_disabled and sep_still_works \
				and not live_reg.is_paired("chrom") and not live_reg.is_paired("robin"):
			print("OK  campaign gate: pair refused while disabled, separate still works"); passed += 1
		else:
			print("FAIL campaign gate: refused=%s sep=%s chrom_paired=%s robin_paired=%s" \
				% [refused_disabled, sep_still_works,
				live_reg.is_paired("chrom"), live_reg.is_paired("robin")])
			failed += 1
		# Re-enabling restores pair formation.
		if live_reg.pair("severa", "owain") and live_reg.is_paired("severa"):
			print("OK  campaign gate: pair allowed again once re-enabled"); passed += 1
		else:
			print("FAIL campaign gate did not re-open"); failed += 1
		# Lead death: drop the support onto the lead tile and expend it only when
		# the lead died during the player phase.
		var tm_stub_script := GDScript.new()
		tm_stub_script.source_code = "extends Node\nenum UnitState { READY, MOVED, DONE }\nvar last_unit = null\nvar last_state = -1\nfunc set_unit_state(unit, state) -> void:\n\tlast_unit = unit\n\tlast_state = state\n"
		tm_stub_script.reload()
		var gm: Node = Node.new(); gm.name = "GameMap"
		var tm: Node = tm_stub_script.new(); tm.name = "TurnManager"
		gm.add_child(tm); root.add_child(gm)
		var unit_stub_script := GDScript.new()
		unit_stub_script.source_code = "extends Node\nvar data = null\nvar tile_position: Vector2i = Vector2i.ZERO\nvar visible: bool = true\nvar team: String = \"blue\"\n"
		unit_stub_script.reload()
		var lead: Node = unit_stub_script.new()
		lead.data = UnitData.new()
		lead.data.unit_id = "chrom"
		lead.data.hp = 0
		lead.tile_position = Vector2i(4, 5)
		var support: Node = unit_stub_script.new()
		support.data = UnitData.new()
		support.data.unit_id = "lissa"
		support.data.hp = 10
		support.tile_position = live_reg.OFF_MAP_TILE
		support.visible = false
		root.add_child(lead)
		root.add_child(support)
		gs.register_unit(lead)
		gs.register_unit(support)
		live_reg.call("clear")
		live_reg.pair("chrom", "lissa")
		gs.current_phase = gs.Phase.PLAYER
		var dropped_player: Node = live_reg.release_support_from_fallen_lead(lead)
		var player_drop_ok: bool = (
			dropped_player == support
			and support.tile_position == Vector2i(4, 5)
			and support.visible
			and tm.last_unit == support
			and tm.last_state == tm.UnitState.DONE
			and not live_reg.is_paired("chrom")
		)
		live_reg.pair("chrom", "lissa")
		support.tile_position = live_reg.OFF_MAP_TILE
		support.visible = false
		tm.last_unit = null
		tm.last_state = -1
		gs.current_phase = gs.Phase.ENEMY
		var dropped_enemy: Node = live_reg.release_support_from_fallen_lead(lead)
		var enemy_drop_ok: bool = (
			dropped_enemy == support
			and support.tile_position == Vector2i(4, 5)
			and support.visible
			and tm.last_unit == null
			and not live_reg.is_paired("chrom")
		)
		gs.unregister_unit(lead)
		gs.unregister_unit(support)
		lead.queue_free()
		support.queue_free()
		gm.queue_free()
		if player_drop_ok and enemy_drop_ok:
			print("OK  lead death drops support onto the lead tile with phase-aware turn state"); passed += 1
		else:
			print("FAIL lead-death drop: player_ok=%s enemy_ok=%s tile=%s visible=%s state=%s" % [
				player_drop_ok, enemy_drop_ok, support.tile_position, support.visible, tm.last_state])
			failed += 1
		# Clean up so a later test in the same harness does not see stale state.
		live_reg.call("clear")

	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
