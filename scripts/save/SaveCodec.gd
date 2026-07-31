extends RefCounted

const InventoryEntryScript = preload("res://scripts/resources/InventoryEntry.gd")

const UNIT_SNAPSHOT_KEYS: Array[String] = [
	"tile_position",
	"class_id",
	"class_variant_id",
	"advancement_edge_id",
	"advancement_edge_variant_id",
	"hp",
	"max_hp",
	"strength",
	"magic",
	"defense",
	"resistance",
	"skill",
	"speed",
	"luck",
	"exp",
	"level",
	"internal_level",
	"is_promoted",
	"class_line_id",
	"weapon_wexp",
	"inventory",
	"conditions",
	"skills",
	"earned_skills",
	"mastery_skills",
	"is_incapacitated",
	"active_modifiers",
	"skill_use_counters",
	"damage_taken_this_map",
	"growth_accumulators",
	"shift_gauge",
	"is_shifted",
]

const _REQUIRED_ARRAY_KEYS: Array[String] = [
	"inventory",
	"conditions",
	"skills",
	"earned_skills",
	"mastery_skills",
	"active_modifiers",
]
const _REQUIRED_DICT_KEYS: Array[String] = [
	"tile_position",
	"weapon_wexp",
	"skill_use_counters",
	"growth_accumulators",
]
const _ENTRY_TYPES: Array[String] = ["weapon", "item", "equip"]
const _EQUIP_MOD_KEYS: Array[String] = ["accuracy", "damage", "crit", "dodge"]


static func vector2i_to_dict(value: Vector2i) -> Dictionary:
	return {"x": value.x, "y": value.y}


static func vector2i_from_dict(value: Variant, default_value: Vector2i = Vector2i.ZERO) -> Vector2i:
	if value is Dictionary:
		return Vector2i(
			as_int(value.get("x", default_value.x), default_value.x),
			as_int(value.get("y", default_value.y), default_value.y)
		)
	if value is Array and value.size() >= 2:
		return Vector2i(as_int(value[0], default_value.x), as_int(value[1], default_value.y))
	return default_value


static func inventory_entry_to_dict(entry: InventoryEntry) -> Dictionary:
	return {
		"entry_type": entry.entry_type,
		"weapon_id": entry.weapon_id,
		"item_id": entry.item_id,
		"uses_remaining": entry.uses_remaining,
		"forged_mods": entry.forged_mods.duplicate(true),
		"accuracy": entry.accuracy,
		"damage": entry.damage,
		"crit": entry.crit,
		"dodge": entry.dodge,
	}


static func inventory_entry_from_dict(data: Variant) -> InventoryEntry:
	if not (data is Dictionary):
		return null
	var entry: InventoryEntry = InventoryEntryScript.new()
	entry.entry_type = String(data.get("entry_type", ""))
	entry.weapon_id = String(data.get("weapon_id", ""))
	entry.item_id = String(data.get("item_id", ""))
	entry.uses_remaining = as_int(data.get("uses_remaining", 0), 0)
	entry.forged_mods = (
		data.get("forged_mods", {}).duplicate(true)
		if data.get("forged_mods", {}) is Dictionary
		else {}
	)
	entry.accuracy = as_int(data.get("accuracy", 0), 0)
	entry.damage = as_int(data.get("damage", 0), 0)
	entry.crit = as_int(data.get("crit", 0), 0)
	entry.dodge = as_int(data.get("dodge", 0), 0)
	return entry


static func inventory_entries_to_array(entries: Array[InventoryEntry]) -> Array:
	var out: Array = []
	for entry in entries:
		out.append(inventory_entry_to_dict(entry) if entry != null else null)
	return out


static func inventory_entries_from_array(entries: Variant) -> Array[InventoryEntry]:
	var out: Array[InventoryEntry] = []
	if not (entries is Array):
		return out
	for entry_data in entries:
		out.append(inventory_entry_from_dict(entry_data))
	return out


static func unit_data_to_dict(data: UnitData) -> Dictionary:
	return {
		"tile_position": vector2i_to_dict(data.tile_position),
		"class_id": data.class_id,
		"class_variant_id": data.class_variant_id,
		"advancement_edge_id": data.advancement_edge_id,
		"advancement_edge_variant_id": data.advancement_edge_variant_id,
		"hp": data.hp,
		"max_hp": data.max_hp,
		"strength": data.strength,
		"magic": data.magic,
		"defense": data.defense,
		"resistance": data.resistance,
		"skill": data.skill,
		"speed": data.speed,
		"luck": data.luck,
		"exp": data.exp,
		"level": data.level,
		"internal_level": data.internal_level,
		"is_promoted": data.is_promoted,
		"class_line_id": data.class_line_id,
		"weapon_wexp": data.weapon_wexp.duplicate(true),
		"inventory": inventory_entries_to_array(data.inventory),
		"conditions": data.conditions.duplicate(true),
		"skills": data.skills.duplicate(true),
		"earned_skills": data.earned_skills.duplicate(true),
		"mastery_skills": data.mastery_skills.duplicate(true),
		"is_incapacitated": data.is_incapacitated,
		"active_modifiers": data.active_modifiers.duplicate(true),
		"skill_use_counters": data.skill_use_counters.duplicate(true),
		"damage_taken_this_map": data.damage_taken_this_map,
		"growth_accumulators": data.growth_accumulators.duplicate(true),
		"shift_gauge": data.shift_gauge,
		"is_shifted": data.is_shifted,
	}


static func apply_unit_dict(data: UnitData, snap: Dictionary) -> void:
	data.tile_position = vector2i_from_dict(snap.get("tile_position", {}), Vector2i.ZERO)
	data.class_id = String(snap.get("class_id", data.class_id))
	data.class_variant_id = String(snap.get("class_variant_id", ""))
	data.advancement_edge_id = String(snap.get("advancement_edge_id", ""))
	data.advancement_edge_variant_id = String(snap.get("advancement_edge_variant_id", ""))
	data.hp = as_int(snap.get("hp", data.max_hp), data.max_hp)
	data.max_hp = as_int(snap.get("max_hp", data.max_hp), data.max_hp)
	data.strength = as_int(snap.get("strength", data.strength), data.strength)
	data.magic = as_int(snap.get("magic", data.magic), data.magic)
	data.defense = as_int(snap.get("defense", data.defense), data.defense)
	data.resistance = as_int(snap.get("resistance", data.resistance), data.resistance)
	data.skill = as_int(snap.get("skill", data.skill), data.skill)
	data.speed = as_int(snap.get("speed", data.speed), data.speed)
	data.luck = as_int(snap.get("luck", data.luck), data.luck)
	data.exp = as_int(snap.get("exp", 0), 0)
	data.level = as_int(snap.get("level", data.level), data.level)
	data.internal_level = as_int(
		snap.get("internal_level", data.internal_level), data.internal_level
	)
	data.is_promoted = bool(snap.get("is_promoted", data.is_promoted))
	data.class_line_id = String(snap.get("class_line_id", data.class_line_id))
	data.weapon_wexp = int_dict_from_variant(snap.get("weapon_wexp", {}))
	data.inventory = inventory_entries_from_array(snap.get("inventory", []))
	data.conditions = _dict_array_from_variant(snap.get("conditions", []))
	data.skills = string_array_from_variant(snap.get("skills", []))
	data.earned_skills = string_array_from_variant(snap.get("earned_skills", []))
	data.mastery_skills = string_array_from_variant(snap.get("mastery_skills", []))
	data.is_incapacitated = bool(snap.get("is_incapacitated", false))
	data.active_modifiers = _dict_array_from_variant(snap.get("active_modifiers", []))
	data.skill_use_counters = int_dict_from_variant(snap.get("skill_use_counters", {}))
	data.damage_taken_this_map = as_int(snap.get("damage_taken_this_map", 0), 0)
	data.growth_accumulators = int_dict_from_variant(snap.get("growth_accumulators", {}))
	data.shift_gauge = as_int(snap.get("shift_gauge", 0), 0)
	data.is_shifted = bool(snap.get("is_shifted", false))


static func validate_unit_snapshot_dict(
	snap: Dictionary, index: int, data_manager: Object = null
) -> Array[String]:
	var errors: Array[String] = []
	var prefix := "GameState: snapshot entry %d" % index
	if not snap.has("hp") or not snap.has("max_hp"):
		errors.append("%s is missing hp/max_hp" % prefix)
	else:
		if not _is_json_int(snap.get("hp")) or not _is_json_int(snap.get("max_hp")):
			errors.append("%s hp/max_hp must be whole numbers" % prefix)
		else:
			var hp := as_int(snap.get("hp"), -1)
			var max_hp := as_int(snap.get("max_hp"), -1)
			if max_hp < 1:
				errors.append("%s max_hp must be >= 1" % prefix)
			if hp < 0:
				errors.append("%s hp cannot be negative" % prefix)
			elif max_hp >= 1 and hp > max_hp:
				errors.append("%s hp %d exceeds max_hp %d" % [prefix, hp, max_hp])

	for key in _REQUIRED_ARRAY_KEYS:
		if not snap.has(key):
			errors.append("%s is missing '%s'" % [prefix, key])
		elif not (snap[key] is Array):
			errors.append("%s '%s' is not an Array" % [prefix, key])
	for key in _REQUIRED_DICT_KEYS:
		if not snap.has(key):
			errors.append("%s is missing '%s'" % [prefix, key])
		elif not (snap[key] is Dictionary):
			errors.append("%s '%s' is not a Dictionary" % [prefix, key])
	if snap.has("tile_position") and snap["tile_position"] is Dictionary:
		var pos: Dictionary = snap["tile_position"]
		if (
			not pos.has("x")
			or not pos.has("y")
			or not _is_json_int(pos["x"])
			or not _is_json_int(pos["y"])
		):
			errors.append("%s tile_position must carry whole-number x/y fields" % prefix)

	if snap.get("inventory", null) is Array:
		var inventory: Array = snap["inventory"]
		for i in inventory.size():
			errors.append_array(
				validate_inventory_entry_dict(
					inventory[i], "%s inventory[%d]" % [prefix, i], data_manager
				)
			)
	return errors


static func validate_inventory_entry_dict(
	entry_data: Variant, path: String, data_manager: Object = null
) -> Array[String]:
	var errors: Array[String] = []
	if entry_data == null:
		return errors
	if not (entry_data is Dictionary):
		errors.append("%s is not a Dictionary" % path)
		return errors
	var entry_type := String(entry_data.get("entry_type", ""))
	if not (entry_type in _ENTRY_TYPES):
		errors.append("%s entry_type '%s' is not valid" % [path, entry_type])
	if not _is_json_int(entry_data.get("uses_remaining", 0)):
		errors.append("%s uses_remaining must be a whole number" % path)
	for key in _EQUIP_MOD_KEYS:
		if not _is_json_int(entry_data.get(key, 0)):
			errors.append("%s %s must be a whole number" % [path, key])
	if entry_data.has("forged_mods") and not (entry_data["forged_mods"] is Dictionary):
		errors.append("%s forged_mods is not a Dictionary" % path)

	if entry_type == "weapon":
		var weapon_id := String(entry_data.get("weapon_id", ""))
		if weapon_id == "":
			errors.append("%s weapon_id is empty" % path)
		elif (
			data_manager != null
			and data_manager.has_method("has_weapon")
			and not bool(data_manager.call("has_weapon", weapon_id))
		):
			errors.append("%s weapon '%s' not found" % [path, weapon_id])
	elif entry_type == "item":
		var item_id := String(entry_data.get("item_id", ""))
		if item_id == "":
			errors.append("%s item_id is empty" % path)
		elif (
			data_manager != null
			and data_manager.has_method("has_item")
			and not bool(data_manager.call("has_item", item_id))
		):
			errors.append("%s item '%s' not found" % [path, item_id])
	return errors


static func string_array_from_variant(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if not (value is Array):
		return out
	for item in value:
		out.append(String(item))
	return out


static func _dict_array_from_variant(value: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not (value is Array):
		if value != null:
			push_warning("SaveCodec: dropped malformed dictionary array; expected Array")
		return out
	for i in value.size():
		var item: Variant = value[i]
		if item is Dictionary:
			out.append(item.duplicate(true))
		else:
			push_warning("SaveCodec: dropped non-Dictionary array entry at index %d" % i)
	return out


static func int_dict_from_variant(value: Variant) -> Dictionary:
	var out: Dictionary = {}
	if not (value is Dictionary):
		return out
	for key in value.keys():
		out[key] = as_int(value[key], 0)
	return out


static func _is_json_int(value: Variant) -> bool:
	if value is int:
		return true
	if value is float:
		return absf(float(value) - float(int(value))) < 0.00001
	return false


static func as_int(value: Variant, default_value: int) -> int:
	return int(value) if _is_json_int(value) else default_value
