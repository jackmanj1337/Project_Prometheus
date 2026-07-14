extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_save_data.gd
# B1-SAVECODEC Slice 5: I/O-free SaveData envelope coverage.

const SaveCodec = preload("res://scripts/save/SaveCodec.gd")
const SaveDataScript = preload("res://scripts/save/SaveData.gd")


class RefValidator extends RefCounted:
	func has_weapon(id: String) -> bool:
		return id == "iron_lance"

	func has_item(id: String) -> bool:
		return id == "vulnerary"


func _init() -> void:
	print("=== SaveData Test ===")
	var passed := 0
	var failed := 0

	var weapon := InventoryEntry.make_weapon("iron_lance", 20)
	var item := InventoryEntry.make_item("vulnerary", 3)
	var weapon_dict := SaveCodec.inventory_entry_to_dict(weapon)
	var item_dict := SaveCodec.inventory_entry_to_dict(item)

	var save: RefCounted = SaveDataScript.new()
	save.save_label = "Chapter 1 start"
	save.integrity = {"payload_hash": "payload-a", "schema_hash": "schema-a"}
	save.campaign["campaign_id"] = "demo_campaign"
	save.campaign["node_id"] = "prologue"
	save.campaign["cleared_nodes"] = ["intro"]
	save.campaign["rules"]["hit_formula"] = "single_roll"
	save.party["resources"]["party_gold"] = 500
	save.party["convoy"]["entries"] = [item_dict]
	save.roster["units"] = [{
		"identity": {"unit_id": "alice"},
		"inventory": {"entries": [weapon_dict]},
	}]
	save.map_runtime["rng"] = {"map_seed": 12345, "history_hash": 67890}
	save.suspend["kind"] = "map"
	save.suspend["cursor_tile"] = SaveCodec.vector2i_to_dict(Vector2i(4, 6))
	save.suspend["threat_views_version"] = 1
	save.suspend["threat_views_by_faction"] = {
		"blue": {"watch_set": ["enemy_a"], "danger_mode": "combined"},
		"red": {"watch_set": ["ally_a"], "danger_mode": "selected"},
	}

	var parsed: Variant = JSON.parse_string(JSON.stringify(save.to_dict()))
	var restored: RefCounted = SaveDataScript.from_dict(parsed)
	var restored_dict: Dictionary = restored.to_dict()
	var top_level_ok := true
	for key in SaveDataScript.TOP_LEVEL_KEYS:
		top_level_ok = top_level_ok and restored_dict.has(key)
	var roundtrip_ok: bool = top_level_ok \
		and restored.format_version == SaveDataScript.FORMAT_VERSION \
		and restored.save_label == "Chapter 1 start" \
		and restored.integrity == {"payload_hash": "payload-a", "schema_hash": "schema-a"} \
		and restored.campaign["campaign_id"] == "demo_campaign" \
		and restored.campaign["node_id"] == "prologue" \
		and restored.campaign["rules"]["hit_formula"] == "single_roll" \
		and restored.party["resources"]["party_gold"] == 500 \
		and restored.party["convoy"]["entries"][0]["item_id"] == "vulnerary" \
		and restored.roster["units"][0]["inventory"]["entries"][0]["weapon_id"] == "iron_lance" \
		and restored.map_runtime["rng"] == {"map_seed": "12345", "history_hash": "67890"} \
		and restored.suspend["cursor_tile"] == {"x": 4, "y": 6} \
		and restored.suspend["threat_views_version"] == 1 \
		and restored.suspend["threat_views_by_faction"]["blue"]["watch_set"] == ["enemy_a"] \
		and restored.suspend["threat_views_by_faction"]["red"]["danger_mode"] == "selected" \
		and restored.validate(RefValidator.new()).is_empty()
	if roundtrip_ok:
		print("OK  test_save_data_campaign_roundtrip: envelope survives JSON")
		passed += 1
	else:
		print("FAIL campaign roundtrip: %s" % [restored_dict])
		failed += 1

	var legacy := {
		"integrity": {"whole": "old-payload", "protected": "old-schema"},
		"rules": {"hit_formula": "single_roll"},
		"campaign": {
			"campaign_id": "legacy_campaign",
			"node_id": "legacy_node",
			"rules": {"permadeath_enabled": false},
		},
		"party": {
			"gold": 777,
			"roster": [{"identity": {"unit_id": "legacy_lord"}}],
		},
	}
	var defaulted: RefCounted = SaveDataScript.from_dict(legacy)
	var defaults_ok: bool = defaulted.format_version == SaveDataScript.FORMAT_VERSION \
		and defaulted.save_label == "" \
		and defaulted.integrity == {"payload_hash": "old-payload", "schema_hash": "old-schema"} \
		and defaulted.campaign["rules"]["hit_formula"] == "single_roll" \
		and defaulted.campaign["rules"]["death_mode"] == "casual" \
		and defaulted.campaign["rules"]["leveling_method"] == "growth_random" \
		and defaulted.campaign["rules"]["pair_up_enabled"] == true \
		and defaulted.campaign["rules"]["max_skills"] == 5 \
		and defaulted.campaign["rules"]["max_inventory"] == 8 \
		and defaulted.campaign["rules"]["exp_gaining_factions"] == ["blue", "green"] \
		and defaulted.campaign["rules"]["rewind_charges_per_map"] == 4 \
		and defaulted.party["resources"]["party_gold"] == 777 \
		and defaulted.roster["units"].size() == 1 \
		and defaulted.header["campaign_id"] == "legacy_campaign" \
		and defaulted.header["node_id"] == "legacy_node" \
		and defaulted.header["party"]["count"] == 1 \
		and defaulted.header["party"]["gold"] == 777 \
		and defaulted.map_runtime["rng"].is_empty() \
		and defaulted.suspend["kind"] == null
	if defaults_ok:
		print("OK  test_save_data_old_save_defaults: absent sections get one default path")
		passed += 1
	else:
		print("FAIL old-save defaults: %s" % [defaulted.to_dict()])
		failed += 1

	var malformed_convoy: RefCounted = SaveDataScript.from_dict({
		"party": {"convoy": {"entries": "bad"}, "items": [item_dict]},
	})
	var convoy_fallback_ok: bool = malformed_convoy.party["convoy"]["entries"].size() == 1 \
		and malformed_convoy.party["convoy"]["entries"][0]["item_id"] == "vulnerary"
	if convoy_fallback_ok:
		print("OK  malformed convoy entries fall back to legacy items with warning")
		passed += 1
	else:
		print("FAIL malformed convoy fallback: %s" % [malformed_convoy.party])
		failed += 1

	var bad_refs: RefCounted = SaveDataScript.from_dict({
		"party": {"convoy": {"entries": [
			{"entry_type": "item", "item_id": "missing_vulnerary",
				"uses_remaining": 1, "forged_mods": {},
				"accuracy": 0, "damage": 0, "crit": 0, "dodge": 0},
		]}},
		"roster": {"units": [{
			"inventory": {"entries": [
				{"entry_type": "weapon", "weapon_id": "missing_sword",
					"uses_remaining": 1, "forged_mods": {},
					"accuracy": 0, "damage": 0, "crit": 0, "dodge": 0},
			]},
		}]},
	})
	var ref_errors: Array[String] = bad_refs.validate(RefValidator.new())
	var saw_weapon := false
	var saw_item := false
	for err in ref_errors:
		if err.contains("weapon 'missing_sword' not found"):
			saw_weapon = true
		if err.contains("item 'missing_vulnerary' not found"):
			saw_item = true
	if saw_weapon and saw_item:
		print("OK  test_reference_validation_unknown_ids: SaveData forwards inventory refs")
		passed += 1
	else:
		print("FAIL reference validation errors: %s" % [ref_errors])
		failed += 1

	var unsupported: RefCounted = SaveDataScript.from_dict({"format_version": 99})
	var version_errors: Array[String] = unsupported.validate()
	var saw_version := false
	for err in version_errors:
		if err.contains("unsupported format_version"):
			saw_version = true
	if saw_version:
		print("OK  save_data_version_guard: unknown versions fail validation")
		passed += 1
	else:
		print("FAIL version guard: %s" % [version_errors])
		failed += 1

	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
