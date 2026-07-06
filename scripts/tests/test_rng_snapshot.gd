extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_rng_snapshot.gd
# T2 snapshot round-trip (B1-PKGA Step 2; rng_determinism_design §10): the
# Retry snapshot carries {map_seed, history_hash}, restoring it restores the
# dice timeline byte-for-byte (RNG-2), and a malformed RNG snapshot fails
# validation instead of silently desyncing the chain.
#
# Stub nodes claim the /root names in _init BEFORE the project autoloads
# attach, so GameState/RngService lookups resolve to these instances.

const FIXED_SEED := 20260706


func _draws(rng: RandomNumberGenerator, n: int = 6) -> Array[int]:
	var out: Array[int] = []
	for _i in n:
		out.append(rng.randi_range(0, 99))
	return out


func _init() -> void:
	print("=== RNG Snapshot Round-Trip Test (T2) ===")
	var passed := 0
	var failed := 0

	var svc: Node = load("res://scripts/autoloads/RngService.gd").new()
	svc.name = "RngService"
	root.add_child(svc)
	var gs: Node = load("res://scripts/autoloads/GameState.gd").new()
	gs.name = "GameState"
	root.add_child(gs)
	await process_frame

	# A minimal but VALID roster entry — restore_map_snapshot refuses to run
	# when the unit snapshot fails validation, so this must be a real UnitData.
	var ud := UnitData.new()
	ud.hp = 20
	ud.max_hp = 20
	ud.unit_id = "t2_unit"
	# player_roster is Array[UnitData]; a bare [ud] literal won't assign to it.
	gs.player_roster.append(ud)

	# Advance the dice timeline mid-map, then take the snapshot.
	svc.start_map(FIXED_SEED)
	svc.commit_event("wait", ["t2_unit", "1,1", "2,1"] as Array[String])
	svc.commit_event("attack", ["t2_unit", "2,1", "2,1", "e1"] as Array[String])
	var expected_state: Dictionary = svc.to_save_dict()
	var attack_rec: Array[String] = ["t2_unit", "2,1", "3,1", "e2"]
	var expected_draws: Array[int] = _draws(svc.begin_event("attack", attack_rec))
	gs.take_map_snapshot()

	# ---- the snapshot captured the RNG timeline ----
	if gs._snapshot_rng == expected_state and not gs._snapshot_rng.is_empty():
		print("OK  take_map_snapshot captures {map_seed, history_hash}"); passed += 1
	else:
		print("FAIL snapshot capture: %s vs %s" % [gs._snapshot_rng, expected_state]); failed += 1

	# ---- mutate the timeline arbitrarily, restore, and deep-compare ----
	svc.commit_event("wait", ["t2_unit", "3,1", "3,2"] as Array[String])
	svc.commit_event("item", ["t2_unit", "3,2", "3,2", "vulnerary"] as Array[String])
	svc.start_map(999)  # even the seed diverges
	if not gs.restore_map_snapshot():
		print("FAIL restore_map_snapshot returned false"); failed += 1
	elif svc.to_save_dict() == expected_state:
		print("OK  T2: restore returns the exact {map_seed, history_hash}"); passed += 1
	else:
		print("FAIL T2 round-trip: %s vs %s" % [svc.to_save_dict(), expected_state]); failed += 1

	# ---- the restored timeline replays the same attack identically ----
	var replayed_draws: Array[int] = _draws(svc.begin_event("attack", attack_rec))
	if replayed_draws == expected_draws:
		print("OK  T2: the next attack's dice match the pre-snapshot branch: %s" % str(replayed_draws)); passed += 1
	else:
		print("FAIL T2 replay: %s vs %s" % [replayed_draws, expected_draws]); failed += 1

	# ---- an empty RNG snapshot restores fine and leaves the service alone ----
	# (legitimate when the snapshot was taken without the autoload in the tree)
	gs._snapshot_rng = {}
	svc.start_map(31415)
	var untouched: Dictionary = svc.to_save_dict()
	if gs.restore_map_snapshot() and svc.to_save_dict() == untouched:
		print("OK  empty rng snapshot: restore succeeds, service untouched"); passed += 1
	else:
		print("FAIL empty-rng restore: %s vs %s" % [svc.to_save_dict(), untouched]); failed += 1

	# ---- a malformed RNG snapshot fails validation (no silent desync) ----
	gs._snapshot_rng = {"map_seed": "bogus", "history_hash": 3}
	var errors: Array[String] = gs.validate_restore_snapshot_state()
	var flagged := false
	for e in errors:
		if e.contains("snapshot rng"):
			flagged = true
	if flagged and not gs.restore_map_snapshot():
		print("OK  malformed rng snapshot fails validation and blocks restore"); passed += 1
	else:
		print("FAIL malformed rng: errors=%s" % str(errors)); failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
