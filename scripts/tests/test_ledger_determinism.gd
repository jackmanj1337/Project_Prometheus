extends SceneTree

# The ledger and suspend document consume the same board blocks. Compare exact
# JSON bytes so future serializer drift cannot make Retry and Resume disagree.
const MapLedgerScript = preload("res://scripts/save/MapLedger.gd")
const SaveDataScript = preload("res://scripts/save/SaveData.gd")


func _init() -> void:
	print("=== Ledger And Suspend Determinism Test ===")
	var entry := _board_entry()
	var ledger: RefCounted = MapLedgerScript.new()
	ledger.push(entry, MapLedgerScript.REASON_ROUND_START)

	var save: RefCounted = SaveDataScript.new()
	for key in entry["map_runtime"]:
		save.map_runtime[key] = entry["map_runtime"][key]
	for key in entry["suspend"]:
		save.suspend[key] = entry["suspend"][key]
	save.ledger = ledger.to_save_array()
	var document: Dictionary = SaveDataScript.from_dict(save.to_dict()).to_dict()

	var ledger_entry: Dictionary = document["ledger"][0]["entry"]
	var shared_bytes_match := (
		JSON.stringify(ledger_entry["map_runtime"]) == JSON.stringify(document["map_runtime"])
		and JSON.stringify(ledger_entry["suspend"]) == JSON.stringify(document["suspend"])
	)
	var first_bytes := JSON.stringify(document, "\t", true).to_utf8_buffer()
	var second_bytes := (
		JSON.stringify(SaveDataScript.from_dict(document).to_dict(), "\t", true).to_utf8_buffer()
	)
	var deterministic := first_bytes == second_bytes

	if shared_bytes_match:
		print("OK  ledger and suspend carry byte-identical shared board blocks")
	else:
		print("FAIL ledger/suspend shared serializer drift")
	if deterministic:
		print("OK  repeated save normalization produces deterministic document bytes")
	else:
		print("FAIL repeated normalization changed document bytes")

	var passed := int(shared_bytes_match) + int(deterministic)
	print("=== Results: %d passed, %d failed ===" % [passed, 2 - passed])
	quit(0 if passed == 2 else 1)


func _board_entry() -> Dictionary:
	return {
		"map_runtime":
		{
			"map_id": "fixture_map",
			"map_path": "res://data/maps/map_001_rout/map_001_data.tres",
			"units": [],
			"turn": {"active_faction": "blue"},
			"pair_carry": {"pair_up": {}},
			"rng": {"map_seed": 123, "history_hash": 456},
			"rewind_charges_left": 4,
		},
		"suspend":
		{
			"kind": "map",
			"cursor_tile": {"x": 2, "y": 3},
			"mode": "free",
			"threat_views_version": 1,
			"threat_views_by_faction": {},
		},
		"party": {"gold": 10, "items": [], "roster": []},
		"campaign_rules_state": {},
	}
