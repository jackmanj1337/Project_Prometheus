extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_save_codec.gd
# B1-SAVECODEC Slice 4: pure JSON-safe codec coverage for Retry-facing unit and
# inventory snapshots.

const SaveCodec = preload("res://scripts/save/SaveCodec.gd")


class RefValidator:
	extends RefCounted

	func has_weapon(id: String) -> bool:
		return id == "iron_lance"

	func has_item(id: String) -> bool:
		return id == "vulnerary"


func _init() -> void:
	print("=== SaveCodec Test ===")
	var passed := 0
	var failed := 0

	var weapon := InventoryEntry.make_weapon("iron_lance", 20)
	# The variant choice is durable: a save must restore the exact variant the slot
	# held, never re-decide it from eligibility at load time.
	weapon.weapon_variant_id = "reforged"
	weapon.forged_mods = {"might": 1, "name": "Test Forge"}
	weapon.accuracy = 5
	weapon.damage = 2
	weapon.crit = 1
	weapon.dodge = 3
	var weapon_dict := SaveCodec.inventory_entry_to_dict(weapon)
	var weapon_json: Variant = JSON.parse_string(JSON.stringify(weapon_dict))
	var weapon_after: InventoryEntry = SaveCodec.inventory_entry_from_dict(weapon_json)
	if (
		weapon_after != null
		and weapon_after.entry_type == "weapon"
		and weapon_after.weapon_id == "iron_lance"
		and weapon_after.weapon_variant_id == "reforged"
		and weapon_after.uses_remaining == 20
		and int(weapon_after.forged_mods.get("might", -1)) == 1
		and weapon_after.forged_mods.get("name", "") == "Test Forge"
		and weapon_after.accuracy == 5
		and weapon_after.damage == 2
		and weapon_after.crit == 1
		and weapon_after.dodge == 3
	):
		print("OK  inventory_entry_roundtrip: weapon entry survives JSON")
		passed += 1
	else:
		print("FAIL inventory weapon roundtrip: %s" % [weapon_after])
		failed += 1

	var item := InventoryEntry.make_item("vulnerary", 3)
	var item_after: InventoryEntry = SaveCodec.inventory_entry_from_dict(
		JSON.parse_string(JSON.stringify(SaveCodec.inventory_entry_to_dict(item)))
	)
	if (
		item_after != null
		and item_after.is_item()
		and item_after.item_id == "vulnerary"
		and item_after.uses_remaining == 3
	):
		print("OK  inventory_entry_roundtrip: item entry survives JSON")
		passed += 1
	else:
		print("FAIL inventory item roundtrip: %s" % [item_after])
		failed += 1

	# Saves written before the durable variant selection existed carry no key at all;
	# they mean "the base weapon", which is what the empty default says.
	var legacy_entry: InventoryEntry = SaveCodec.inventory_entry_from_dict(
		{"entry_type": "weapon", "weapon_id": "iron_lance", "uses_remaining": 20}
	)
	if legacy_entry != null and legacy_entry.weapon_variant_id == "":
		print("OK  inventory_entry_roundtrip: pre-variant saves load as the base weapon")
		passed += 1
	else:
		print("FAIL legacy inventory entry: %s" % [legacy_entry])
		failed += 1

	var unit := UnitData.new()
	unit.tile_position = Vector2i(7, 9)
	unit.class_id = "cavalier"
	unit.class_variant_id = "female"
	unit.advancement_edge_id = "cavalier_promotion"
	unit.advancement_edge_variant_id = "paladin_only"
	unit.hp = 18
	unit.max_hp = 24
	unit.strength = 9
	unit.magic = 2
	unit.defense = 7
	unit.resistance = 4
	unit.skill = 8
	unit.speed = 10
	unit.luck = 6
	unit.exp = 55
	unit.level = 5
	unit.internal_level = 8
	unit.is_promoted = false
	unit.class_line_id = "cavalier"
	unit.weapon_wexp = {"lance": 130}
	unit.inventory = [weapon, item]
	unit.conditions = [{"type": "poison", "turns_remaining": 2}]
	unit.skills = ["discipline"]
	unit.earned_skills = ["discipline", "outdoor_fighter"]
	unit.mastery_skills = ["lance_mastery"]
	unit.is_incapacitated = true
	unit.active_modifiers = [
		{"stat": "strength", "delta": 2, "source": "test", "duration": 1, "duration_type": "turn"}
	]
	unit.skill_use_counters = {"dance": 1}
	unit.damage_taken_this_map = 6
	unit.growth_accumulators = {"strength": 40}
	unit.shift_gauge = 12
	unit.is_shifted = true

	var unit_dict := SaveCodec.unit_data_to_dict(unit)
	var json_safe := (
		unit_dict["tile_position"] is Dictionary
		and unit_dict["inventory"] is Array
		and unit_dict["inventory"][0] is Dictionary
		and not (unit_dict["inventory"][0] is Resource)
	)
	if json_safe:
		print("OK  unit_snapshot_json_shape: vectors/resources become dictionaries")
		passed += 1
	else:
		print(
			(
				"FAIL unit snapshot shape: tile=%s inv0=%s"
				% [typeof(unit_dict["tile_position"]), typeof(unit_dict["inventory"][0])]
			)
		)
		failed += 1

	var parsed_unit: Variant = JSON.parse_string(JSON.stringify(unit_dict))
	var restored := UnitData.new()
	SaveCodec.apply_unit_dict(restored, parsed_unit)
	if (
		restored.tile_position == Vector2i(7, 9)
		and restored.class_id == "cavalier"
		and restored.class_variant_id == "female"
		and restored.advancement_edge_id == "cavalier_promotion"
		and restored.advancement_edge_variant_id == "paladin_only"
		and restored.hp == 18
		and restored.max_hp == 24
		and restored.strength == 9
		and restored.magic == 2
		and restored.defense == 7
		and restored.resistance == 4
		and restored.skill == 8
		and restored.speed == 10
		and restored.luck == 6
		and restored.exp == 55
		and restored.level == 5
		and restored.internal_level == 8
		and restored.weapon_wexp == {"lance": 130}
		and restored.inventory.size() == 2
		and restored.inventory[0].weapon_id == "iron_lance"
		and restored.inventory[1].item_id == "vulnerary"
		and restored.conditions.size() == 1
		and restored.skills == ["discipline"]
		and restored.earned_skills == ["discipline", "outdoor_fighter"]
		and restored.mastery_skills == ["lance_mastery"]
		and restored.is_incapacitated
		and restored.active_modifiers.size() == 1
		and restored.skill_use_counters == {"dance": 1}
		and restored.damage_taken_this_map == 6
		and restored.growth_accumulators == {"strength": 40}
		and restored.shift_gauge == 12
		and restored.is_shifted
	):
		print("OK  save_codec_unit_roundtrip: unit snapshot survives JSON")
		passed += 1
	else:
		print(
			(
				"FAIL unit roundtrip: tile=%s class=%s hp=%d inv=%s skills=%s mods=%s"
				% [
					restored.tile_position,
					restored.class_id,
					restored.hp,
					restored.inventory,
					restored.skills,
					restored.active_modifiers
				]
			)
		)
		failed += 1

	restored.inventory[0].uses_remaining = 1
	var restored_again := UnitData.new()
	SaveCodec.apply_unit_dict(restored_again, parsed_unit)
	if restored_again.inventory[0].uses_remaining == 20:
		print("OK  save_codec_unit_roundtrip: repeated restores do not alias inventory")
		passed += 1
	else:
		print("FAIL repeated restore alias: uses=%d" % restored_again.inventory[0].uses_remaining)
		failed += 1

	var malformed_arrays: Dictionary = parsed_unit.duplicate(true)
	malformed_arrays["conditions"] = [{"type": "poison"}, "bad"]
	malformed_arrays["active_modifiers"] = ["bad", {"stat": "strength", "delta": 1}]
	var restored_malformed := UnitData.new()
	SaveCodec.apply_unit_dict(restored_malformed, malformed_arrays)
	var drop_ok: bool = (
		restored_malformed.conditions.size() == 1
		and restored_malformed.active_modifiers.size() == 1
	)
	if drop_ok:
		print("OK  malformed condition/modifier entries drop with warning")
		passed += 1
	else:
		print(
			(
				"FAIL malformed array drop: conditions=%s modifiers=%s"
				% [restored_malformed.conditions, restored_malformed.active_modifiers]
			)
		)
		failed += 1

	var bad := unit_dict.duplicate(true)
	bad["inventory"] = [
		{
			"entry_type": "weapon",
			"weapon_id": "missing_sword",
			"uses_remaining": 1,
			"forged_mods": {},
			"accuracy": 0,
			"damage": 0,
			"crit": 0,
			"dodge": 0
		},
		{
			"entry_type": "item",
			"item_id": "missing_vulnerary",
			"uses_remaining": 1,
			"forged_mods": {},
			"accuracy": 0,
			"damage": 0,
			"crit": 0,
			"dodge": 0
		},
	]
	var errors := SaveCodec.validate_unit_snapshot_dict(bad, 0, RefValidator.new())
	var saw_weapon := false
	var saw_item := false
	for err in errors:
		if err.contains("weapon 'missing_sword' not found"):
			saw_weapon = true
		if err.contains("item 'missing_vulnerary' not found"):
			saw_item = true
	if saw_weapon and saw_item:
		print("OK  reference_validation_unknown_ids: inventory refs fail structured validation")
		passed += 1
	else:
		print("FAIL reference validation errors: %s" % [errors])
		failed += 1

	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
