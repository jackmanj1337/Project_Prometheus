extends SceneTree
# Live rewind spends charges, branches the ledger, and restores the RNG boundary
# used to make identical replays identical while allowing deliberate divergence.

const TurnManagerScript = preload("res://scripts/core/TurnManager.gd")
const UnitDataScript = preload("res://scripts/resources/UnitData.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Rewind Test ===")
	var passed := 0
	var failed := 0
	var gs: Node = root.get_node("GameState")
	var rng: Node = root.get_node("RngService")
	var settings: Node = root.get_node("SettingsManager")
	var old_auto_end: bool = settings.get("auto_end_turn")
	settings.set("auto_end_turn", false)
	gs.call("reset_map_state")
	gs.get("campaign_rules").rewind_charges_per_map = 2
	gs.get("campaign_rules").undo_activations = 0
	gs.call("configure_next_map", "res://data/maps/map_001_rout/map_001_data.tres")

	var data: UnitData = UnitDataScript.new()
	data.unit_id = "rewind_hero"
	data.unit_name = "Hero"
	data.class_id = "lord"
	data.max_hp = 20
	data.hp = 20
	data.movement = 5
	var roster: Array[UnitData] = [data]
	gs.set("player_roster", roster)
	gs.set("roster_initialized", true)
	gs.set("party_gold", 500)
	gs.set("party_items", ["vulnerary"] as Array[String])
	var actor_script := GDScript.new()
	actor_script.source_code = 'extends Node\nvar data: UnitData\nvar team := "blue"\nvar tile_position := Vector2i.ZERO\nfunc set_done_appearance(): pass\nfunc reset_appearance(): pass\n'
	actor_script.reload()
	var actor: Node = actor_script.new()
	actor.data = data
	root.add_child(actor)
	gs.call("register_unit", actor)

	var tm: Node = TurnManagerScript.new()
	root.add_child(tm)
	var map := MapData.new()
	map.id = "rewind_map"
	map.player_start_tiles = [Vector2i.ZERO]
	rng.call("start_map", 12345)
	gs.call("begin_map_rewind_budget")
	gs.call("take_map_snapshot")
	var boundary_rng: Dictionary = rng.call("to_save_dict")
	gs.set("party_gold", 900)
	gs.set("party_items", ["elixir"] as Array[String])
	tm.call("start_map", map, null)
	var record: Array[String] = ["rewind_hero", "0,0", "0,0"]
	tm.call("commit_action_event", "wait", record)
	tm.call("set_unit_state", actor, TurnManagerScript.UnitState.DONE)
	await process_frame

	gs.set("_rewind_configure_override", func(_payload: Dictionary) -> bool: return false)
	var rejected_without_mutation: bool = (
		not bool(gs.call("rewind_last_action", tm, null))
		and gs.call("history_size") == 2
		and gs.get("rewind_charges_left") == 2
	)
	gs.set("_rewind_configure_override", Callable())
	if rejected_without_mutation:
		print("OK  rejected staged rewind leaves live history and charges untouched")
		passed += 1
	else:
		print("FAIL rejected rewind mutated live state")
		failed += 1

	if (
		gs.call("history_size") == 2
		and gs.call("can_rewind")
		and gs.get("rewind_charges_left") == 2
	):
		print("OK  committed activation pushes and retains a rewind boundary")
		passed += 1
	else:
		print(
			(
				"FAIL activation history: size=%s charges=%s"
				% [gs.call("history_size"), gs.get("rewind_charges_left")]
			)
		)
		failed += 1
	var first_options: Array = gs.call("rewind_options")
	if (
		first_options.size() == 1
		and first_options[0]["target_index"] == 0
		and first_options[0]["cost"] == 1
		and String(first_options[0]["label"]).contains("Hero")
		and String(first_options[0]["label"]).contains("(0,0) → (0,0)")
	):
		print("OK  selector labels the activated unit and its start/end coordinates")
		passed += 1
	else:
		print("FAIL rewind selector metadata: %s" % [first_options])
		failed += 1

	if (
		gs.call("rewind_last_action", tm, null)
		and gs.call("history_size") == 1
		and gs.get("rewind_charges_left") == 1
		and gs.get("party_gold") == 500
		and gs.get("party_items") == ["vulnerary"]
		and gs.get("next_map_suspend_payload").get("ledger", []).size() == 1
		and (
			int(
				gs.get("next_map_suspend_payload")["ledger"][0]["entry"]["map_runtime"].get(
					"rewind_charges_left", -99
				)
			)
			== 1
		)
		and int(gs.call("peek_history", 0)["map_runtime"].get("rewind_charges_left", -99)) == 1
	):
		print("OK  rewind spends one charge and truncates both staged and live history")
		passed += 1
	else:
		print("FAIL rewind spend/branch")
		failed += 1

	gs.set("rewind_charges_left", 3)
	gs.call(
		"push_history",
		tm,
		null,
		"activation",
		{"unit_name": "Red A", "start": [4, 2], "end": [3, 2]}
	)
	gs.call(
		"push_history",
		tm,
		null,
		"activation",
		{"unit_name": "Red B", "start": [7, 5], "end": [7, 4]}
	)
	var priced: Array = gs.call("rewind_options")
	gs.get("campaign_rules").rewind_cost_mode = "full_history"
	var full_history: Array = gs.call("rewind_options")
	if (
		priced.size() == 2
		and priced[0]["cost"] == 1
		and priced[1]["cost"] == 2
		and full_history.size() == 2
		and full_history[0]["cost"] == 1
		and full_history[1]["cost"] == 1
	):
		print("OK  cost mode supports per-activation pricing or one-charge full history")
		passed += 1
	else:
		print("FAIL rewind cost modes: priced=%s full=%s" % [priced, full_history])
		failed += 1

	tm._turn_order = ["blue", "red"] as Array[String]
	tm._active_faction_idx = 1
	tm._push_history("activation", {"unit_name": "Red Boundary"})
	var ai_boundary: Dictionary = gs.peek_history(gs.history_size() - 1)
	if (
		String(ai_boundary.get("map_runtime", {}).get("turn", {}).get("controller_boundary", ""))
		== "between_ai_activations"
	):
		print("OK  AI activation history records a resumable controller boundary")
		passed += 1
	else:
		print("FAIL AI history boundary: %s" % [ai_boundary])
		failed += 1
	tm._active_faction_idx = 0
	gs.call("restore_history", 0)
	gs.get("campaign_rules").rewind_cost_mode = "per_activation"

	var payload: Dictionary = gs.get("next_map_suspend_payload")
	var restored_rng: Dictionary = payload.get("map_runtime", {}).get("rng", {})
	rng.call("from_save_dict", restored_rng)
	rng.call("commit_event", "wait", record)
	var replay_hash: int = int(rng.get("history_hash"))
	rng.call("from_save_dict", boundary_rng)
	rng.call("commit_event", "wait", record)
	var identical_hash: int = int(rng.get("history_hash"))
	rng.call("from_save_dict", boundary_rng)
	var changed_record: Array[String] = ["rewind_hero", "0,0", "1,0"]
	rng.call("commit_event", "wait", changed_record)
	var diverged_hash: int = int(rng.get("history_hash"))
	if replay_hash == identical_hash and diverged_hash != identical_hash:
		print("OK  identical replay reproduces RNG while a changed decision diverges")
		passed += 1
	else:
		print(
			(
				"FAIL rewind RNG: replay=%s same=%s diverged=%s"
				% [replay_hash, identical_hash, diverged_hash]
			)
		)
		failed += 1

	gs.get("campaign_rules").rewind_charges_per_map = -1
	gs.call("begin_map_rewind_budget")
	gs.call("push_history", tm, null, "activation")
	gs.call("push_history", tm, null, "activation")
	if gs.call("rewind_last_action", tm, null) and gs.get("rewind_charges_left") == -1:
		print("OK  infinite campaign rewind remains spendable without decrement")
		passed += 1
	else:
		print("FAIL infinite rewind budget")
		failed += 1

	gs.set("rewind_charges_left", 0)
	if not gs.call("can_rewind") and not gs.call("rewind_last_action", tm, null):
		print("OK  exhausted budget blocks further rewind")
		passed += 1
	else:
		print("FAIL exhausted rewind budget")
		failed += 1

	settings.set("auto_end_turn", old_auto_end)
	gs.call("reset_map_state")
	actor.queue_free()
	tm.queue_free()
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)
