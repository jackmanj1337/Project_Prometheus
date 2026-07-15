class_name SaveBudgetMeasurement extends RefCounted
# Deterministic representative save fixtures for import-budget evidence. Timing
# and memory are reported for observation only; byte-size invariants are stable.

const ImportBudgetConfig = preload("res://scripts/resources/ImportBudgets.gd")


static func measure_all() -> Array[Dictionary]:
	var scenarios := [
		{"id": "between_map", "document": _between_map(24, 120)},
		{"id": "normal_mid_map", "document": _mid_map(30, 6)},
		{"id": "large_roster_convoy", "document": _between_map(300, 3000)},
		# Shipped campaign data leaves undo_activations/undo_rounds at 0/0, so the
		# largest shipped retention is its retry boundary: one full board entry.
		{"id": "largest_shipped_rewind_ledger", "document": _mid_map(60, 1)},
	]
	var rows: Array[Dictionary] = []
	for scenario in scenarios:
		rows.append(_measure(String(scenario["id"]), scenario["document"]))
	return rows


static func _measure(id: String, document: Dictionary) -> Dictionary:
	var json := JSON.stringify(document)
	var bytes := json.to_utf8_buffer().size()
	var memory_before := OS.get_static_memory_usage()
	var started := Time.get_ticks_usec()
	var parsed: Variant = JSON.parse_string(json)
	var parse_usec := Time.get_ticks_usec() - started
	var memory_after := OS.get_static_memory_usage()
	return {
		"id": id,
		"json_bytes": bytes,
		"parse_usec": parse_usec,
		"observed_memory_delta_bytes": maxi(0, memory_after - memory_before),
		"parsed": parsed is Dictionary,
		"warning_headroom_bytes": ImportBudgetConfig.portable_save_warning_bytes() - bytes,
	}


static func _between_map(roster_count: int, convoy_count: int) -> Dictionary:
	var roster: Array[Dictionary] = []
	for index in roster_count:
		roster.append(_unit(index))
	var convoy: Array[Dictionary] = []
	for index in convoy_count:
		convoy.append(_item(index))
	return {
		"format_version": 1,
		"_warning": "Representative portable campaign save",
		"save_label": "Measured between-map save",
		"origin": "manual",
		"rule_id": "",
		"integrity": {"payload_hash": "0".repeat(64), "schema_hash": "0".repeat(64)},
		"header": {"save_kind": "between_map", "campaign_id": "proving_grounds"},
		"campaign": {"campaign_id": "proving_grounds", "node_id": "map_03",
			"cleared_nodes": ["map_01", "map_02"], "flags": ["village_saved"],
			"vars": {"reputation": 12}, "rules": _rules()},
		"party": {"resources": {"party_gold": 999999}, "convoy": {"entries": convoy}},
		"roster": {"units": roster},
		"map_runtime": {}, "suspend": {}, "ledger": [],
	}


static func _mid_map(unit_count: int, ledger_entries: int) -> Dictionary:
	var document := _between_map(unit_count, unit_count * 4)
	document["save_label"] = "Measured mid-map save"
	var units: Array[Dictionary] = []
	for index in unit_count:
		units.append(_runtime_unit(index))
	var runtime := {
		"map_id": "map_03", "map_path": "res://scenes/maps/Map03.tscn",
		"vars": {"reinforcement_wave": 3}, "flags": ["gate_open"],
		"events_fired": ["intro", "turn_2"], "units": units,
		"turn": {"turn_number": 9, "phase": "player", "active_faction": "blue",
			"turn_order": ["blue", "red", "green"], "unit_states": {}},
		"rng": {"map_seed": "922337203685477000", "history_hash": "123456789"},
	}
	document["map_runtime"] = runtime
	document["header"]["save_kind"] = "mid_map"
	document["ledger"] = []
	for index in ledger_entries:
		document["ledger"].append({"reason": "round_start" if index == 0 else "activation",
			"entry": {"map_runtime": runtime.duplicate(true), "suspend": {},
				"party": document["party"].duplicate(true),
				"roster": document["roster"].duplicate(true)}})
	return document


static func _rules() -> Dictionary:
	return {"death_mode": "casual", "hit_formula": "two_roll",
		"rewind_charges_per_map": 4, "undo_activations": 0, "undo_rounds": 0,
		"save_slot_classes": [{"count": 3, "accepts": "between_map",
			"consumed_on_load": false, "label": "Campaign Save"}],
		"autosave_rules": []}


static func _unit(index: int) -> Dictionary:
	var inventory: Array[Dictionary] = []
	for item_index in 8:
		inventory.append(_item(index * 8 + item_index))
	return {"unit_id": "unit_%04d" % index, "class_id": "hero_class",
		"level": 20, "experience": 99,
		"stats": {"hp": 60, "strength": 30, "magic": 30, "skill": 30,
			"speed": 30, "luck": 30, "defense": 30, "resistance": 30},
		"skills": ["skill_a", "skill_b", "skill_c", "skill_d", "skill_e"],
		"inventory": {"entries": inventory}}


static func _runtime_unit(index: int) -> Dictionary:
	var unit := _unit(index)
	unit.merge({"faction": "blue" if index < 20 else "red", "hp": 60,
		"position": {"x": index % 20, "y": index / 20}, "dead": false,
		"statuses": [{"id": "measured_status", "turns": 3}]}, true)
	return unit


static func _item(index: int) -> Dictionary:
	return {"instance_id": "item_%06d" % index, "item_id": "silver_sword",
		"uses": 30, "max_uses": 30, "state": {"forged_might": 5}}
