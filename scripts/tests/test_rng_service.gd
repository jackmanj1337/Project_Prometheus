extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_rng_service.gd
# Tests RngService (Package A Step 1, Slice 1a): fixed-seed stability, event
# identity, history-chain butterfly behavior, preview neutrality of
# begin_event, and the save-dict round trip. Contract under test:
# AGENT/Docs/design/rng_determinism_design_2026-06-11.md §2-§4.

const FIXED_SEED := 123456789


# Draw n ints in [0,100) from a fresh event RNG — the shape gameplay uses.
func _draws(rng: RandomNumberGenerator, n: int) -> Array[int]:
	var out: Array[int] = []
	for i in n:
		out.append(rng.randi_range(0, 99))
	return out


func _init() -> void:
	print("=== RngService Test ===")
	var passed := 0
	var failed := 0

	var svc: Node = load("res://scripts/autoloads/RngService.gd").new()
	svc.name = "RngService"
	root.add_child(svc)

	var attack_rec: Array[String] = ["unit_02", "7,11", "8,11", "e3"]
	var other_rec: Array[String] = ["unit_05", "1,1", "2,1", "e1"]

	# ---- fixed seed produces stable event numbers across start_map calls ----
	svc.start_map(FIXED_SEED)
	var first: Array[int] = _draws(svc.begin_event("attack", attack_rec), 5)
	svc.start_map(FIXED_SEED)
	var second: Array[int] = _draws(svc.begin_event("attack", attack_rec), 5)
	if first == second and first.size() == 5:
		print("OK  fixed seed reproduces identical event draws: %s" % str(first)); passed += 1
	else:
		print("FAIL fixed-seed stability: %s vs %s" % [str(first), str(second)]); failed += 1

	# ---- begin_event is preview-safe: it must not advance the chain ----
	svc.start_map(FIXED_SEED)
	svc.begin_event("attack", attack_rec)
	svc.begin_event("attack", other_rec)
	var after_begins: Array[int] = _draws(svc.begin_event("attack", attack_rec), 5)
	if after_begins == first:
		print("OK  begin_event alone never advances history_hash"); passed += 1
	else:
		print("FAIL begin_event advanced the chain"); failed += 1

	# ---- identical committed history + identical record repeats (probing, RNG-3a) ----
	svc.start_map(FIXED_SEED)
	svc.commit_event("wait", ["unit_01", "3,3", "3,4"] as Array[String])
	var branch_a: Array[int] = _draws(svc.begin_event("attack", attack_rec), 5)
	svc.start_map(FIXED_SEED)
	svc.commit_event("wait", ["unit_01", "3,3", "3,4"] as Array[String])
	var branch_a2: Array[int] = _draws(svc.begin_event("attack", attack_rec), 5)
	if branch_a == branch_a2:
		print("OK  identical history + identical event repeats exactly"); passed += 1
	else:
		print("FAIL probing repeat differs"); failed += 1

	# ---- different committed history changes later events (butterfly) ----
	svc.start_map(FIXED_SEED)
	svc.commit_event("wait", ["unit_01", "3,3", "4,4"] as Array[String])  # different tile
	var branch_b: Array[int] = _draws(svc.begin_event("attack", attack_rec), 5)
	if branch_b != branch_a:
		print("OK  different committed history changes later event draws"); passed += 1
	else:
		print("FAIL butterfly: draws identical despite different history"); failed += 1

	# ---- different event identity gets different numbers (no roll transfer) ----
	svc.start_map(FIXED_SEED)
	var rec_draws: Array[int] = _draws(svc.begin_event("attack", attack_rec), 5)
	var other_draws: Array[int] = _draws(svc.begin_event("attack", other_rec), 5)
	var kind_draws: Array[int] = _draws(svc.begin_event("levelup", attack_rec), 5)
	if rec_draws != other_draws and rec_draws != kind_draws:
		print("OK  event identity (kind + record) isolates draws"); passed += 1
	else:
		print("FAIL roll transfer across event identities"); failed += 1

	# ---- record field ORDER is part of the identity (§3) ----
	svc.start_map(FIXED_SEED)
	var ordered: Array[int] = _draws(
		svc.begin_event("attack", ["a", "b"] as Array[String]), 3)
	var swapped: Array[int] = _draws(
		svc.begin_event("attack", ["b", "a"] as Array[String]), 3)
	if ordered != swapped:
		print("OK  record field order is part of the event identity"); passed += 1
	else:
		print("FAIL field order ignored by the seed mix"); failed += 1

	# ---- to_save_dict / from_save_dict preserves the timeline (RNG-2) ----
	svc.start_map(FIXED_SEED)
	svc.commit_event("attack", attack_rec)
	var saved: Dictionary = svc.to_save_dict()
	var expected_next: Array[int] = _draws(svc.begin_event("attack", other_rec), 5)
	svc.commit_event("attack", other_rec)  # mutate past the save point
	svc.commit_event("wait", ["unit_09", "0,0", "0,1"] as Array[String])
	svc.from_save_dict(saved)
	var restored: Dictionary = svc.to_save_dict()
	var replayed: Array[int] = _draws(svc.begin_event("attack", other_rec), 5)
	if saved == restored and replayed == expected_next:
		print("OK  save-dict round trip restores the dice timeline"); passed += 1
	else:
		print("FAIL save-dict round trip: %s vs %s" % [str(saved), str(restored)]); failed += 1

	# ---- from_save_dict tolerates missing fields with 0 defaults ----
	svc.from_save_dict({})
	if svc.map_seed == 0 and svc.history_hash == 0:
		print("OK  from_save_dict defaults missing fields to 0"); passed += 1
	else:
		print("FAIL from_save_dict defaults"); failed += 1

	# ---- start_map with no override rolls a fresh nonzero entropy seed ----
	svc.start_map()
	var entropy_seed: int = svc.map_seed
	if entropy_seed != 0 and svc.history_hash == 0:
		print("OK  start_map() rolls an entropy seed and resets the chain"); passed += 1
	else:
		print("FAIL entropy start_map: seed=%d hash=%d" % [svc.map_seed, svc.history_hash]); failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
