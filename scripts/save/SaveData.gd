class_name SaveData
extends RefCounted

const SaveCodec = preload("res://scripts/save/SaveCodec.gd")

const FORMAT_VERSION := 1
const TOP_LEVEL_KEYS: Array[String] = [
	"format_version",
	"save_label",
	"integrity",
	"header",
	"campaign",
	"party",
	"roster",
	"map_runtime",
	"suspend",
]

var format_version: int = FORMAT_VERSION
var save_label: String = ""
var integrity: Dictionary = {}
var header: Dictionary = {}
var campaign: Dictionary = {}
var party: Dictionary = {}
var roster: Dictionary = {}
var map_runtime: Dictionary = {}
var suspend: Dictionary = {}


func _init() -> void:
	_apply_defaults()


static func from_dict(source: Variant) -> RefCounted:
	var save: RefCounted = load("res://scripts/save/SaveData.gd").new()
	save.apply_dict(source)
	return save


func apply_dict(source: Variant) -> void:
	_apply_defaults()
	if not (source is Dictionary):
		return
	var data: Dictionary = source
	format_version = _as_int(data.get("format_version", FORMAT_VERSION), FORMAT_VERSION)
	save_label = _as_string(data.get("save_label", ""), "")
	integrity = _normalize_integrity(data.get("integrity", {}))
	campaign = _normalize_campaign(data.get("campaign", {}), data)
	party = _normalize_party(data.get("party", {}), data)
	roster = _normalize_roster(data.get("roster", {}), data)
	map_runtime = _normalize_map_runtime(data.get("map_runtime", {}))
	suspend = _normalize_suspend(data.get("suspend", {}))
	header = _normalize_header(data.get("header", {}), campaign, party, roster)


func to_dict() -> Dictionary:
	var header_dict := _normalize_header(header, campaign, party, roster)
	return {
		"format_version": format_version,
		"save_label": save_label,
		"integrity": integrity.duplicate(true),
		"header": header_dict,
		"campaign": campaign.duplicate(true),
		"party": party.duplicate(true),
		"roster": roster.duplicate(true),
		"map_runtime": map_runtime.duplicate(true),
		"suspend": suspend.duplicate(true),
	}


func validate(data_manager: Object = null) -> Array[String]:
	var errors: Array[String] = []
	if format_version != FORMAT_VERSION:
		errors.append("SaveData: unsupported format_version %d" % format_version)
	if not (integrity.get("payload_hash", "") is String):
		errors.append("SaveData: integrity.payload_hash must be a String")
	if not (integrity.get("schema_hash", "") is String):
		errors.append("SaveData: integrity.schema_hash must be a String")
	errors.append_array(_validate_rng(map_runtime.get("rng", {})))
	errors.append_array(_validate_inventory_refs(data_manager))
	return errors


func _apply_defaults() -> void:
	format_version = FORMAT_VERSION
	save_label = ""
	integrity = _default_integrity()
	header = _default_header()
	campaign = _default_campaign()
	party = _default_party()
	roster = _default_roster()
	map_runtime = _default_map_runtime()
	suspend = _default_suspend()


static func _normalize_integrity(source: Variant) -> Dictionary:
	var out := _with_defaults(source, _default_integrity())
	# Older planning docs used whole/protected names. Keep loading tolerant while
	# writing the locked manifest names.
	if _as_string(out.get("payload_hash", ""), "") == "" and out.has("whole"):
		out["payload_hash"] = _as_string(out["whole"], "")
	else:
		out["payload_hash"] = _as_string(out.get("payload_hash", ""), "")
	if _as_string(out.get("schema_hash", ""), "") == "" and out.has("protected"):
		out["schema_hash"] = _as_string(out["protected"], "")
	else:
		out["schema_hash"] = _as_string(out.get("schema_hash", ""), "")
	out.erase("whole")
	out.erase("protected")
	return out


static func _normalize_campaign(source: Variant, root: Dictionary) -> Dictionary:
	var raw_campaign: Dictionary = source if source is Dictionary else {}
	var out := _with_defaults(source, _default_campaign())
	out["campaign_id"] = _as_string(out.get("campaign_id", ""), "")
	out["node_id"] = _as_string(out.get("node_id", ""), "")
	out["cleared_nodes"] = _string_array_from_variant(out.get("cleared_nodes", []))
	out["vars"] = _dict_from_variant(out.get("vars", {}))
	out["flags"] = _string_array_from_variant(out.get("flags", []))
	out["rules"] = _normalize_rules(raw_campaign.get("rules", {}), root)
	out["recruited_flags"] = _string_array_from_variant(out.get("recruited_flags", []))
	return out


static func _normalize_rules(source: Variant, root: Dictionary) -> Dictionary:
	var out := _with_defaults(root.get("rules", {}), _default_campaign()["rules"])
	if source is Dictionary:
		_merge_missing(out, source)
		for key in source.keys():
			out[key] = source[key]
	out["hit_formula"] = _as_string(out.get("hit_formula", "two_roll"), "two_roll")
	out["leveling_method"] = _as_string(out.get("leveling_method", "growth_random"), "growth_random")
	out["auto_promote_at_max_level"] = bool(out.get("auto_promote_at_max_level", false))
	out["pair_up_enabled"] = bool(out.get("pair_up_enabled", true))
	out["max_skills"] = _as_int(out.get("max_skills", 5), 5)
	out["max_inventory"] = _as_int(out.get("max_inventory", 8), 8)
	out["exp_gaining_factions"] = _string_array_from_variant(
		out.get("exp_gaining_factions", ["blue", "green"]))
	out["rewind_charges_per_map"] = _as_int(out.get("rewind_charges_per_map", 4), 4)
	if out.has("permadeath_enabled") and not out.has("death_mode"):
		out["death_mode"] = "classic" if bool(out["permadeath_enabled"]) else "casual"
	out["death_mode"] = _as_string(out.get("death_mode", "casual"), "casual")
	out.erase("permadeath_enabled")
	return out


static func _normalize_party(source: Variant, root: Dictionary) -> Dictionary:
	var out := _with_defaults(source, _default_party())
	out["resources"] = _dict_from_variant(out.get("resources", {}))
	var legacy_gold: Variant = null
	if out.has("party_gold"):
		legacy_gold = out["party_gold"]
	elif out.has("gold"):
		legacy_gold = out["gold"]
	elif root.has("party_gold"):
		legacy_gold = root["party_gold"]
	if legacy_gold != null and not out["resources"].has("party_gold"):
		out["resources"]["party_gold"] = _as_int(legacy_gold, 0)
	out.erase("party_gold")
	out.erase("gold")

	out["convoy"] = _with_defaults(out.get("convoy", {}), {"entries": []})
	if out.has("items") and out["convoy"].get("entries", []).is_empty():
		out["convoy"]["entries"] = _array_from_variant(out["items"])
	out.erase("items")
	out["bonus_exp"] = _as_int(out.get("bonus_exp", 0), 0)
	out["training_purchase_counts"] = _dict_from_variant(out.get("training_purchase_counts", {}))
	return out


static func _normalize_roster(source: Variant, root: Dictionary) -> Dictionary:
	var out := _with_defaults(source, _default_roster())
	if source is Array:
		out["units"] = _array_from_variant(source)
	elif out.get("units", []) is Array:
		out["units"] = _array_from_variant(out["units"])
	var party_source: Variant = root.get("party", {})
	if out["units"].is_empty() and party_source is Dictionary and party_source.get("roster", []) is Array:
		out["units"] = _array_from_variant(party_source.get("roster", []))
	return out


static func _normalize_map_runtime(source: Variant) -> Dictionary:
	var out := _with_defaults(source, _default_map_runtime())
	out["vars"] = _dict_from_variant(out.get("vars", {}))
	out["flags"] = _string_array_from_variant(out.get("flags", []))
	out["events_fired"] = _string_array_from_variant(out.get("events_fired", []))
	out["discovered_units"] = _string_array_from_variant(out.get("discovered_units", []))
	out["units"] = _array_from_variant(out.get("units", []))
	out["rng"] = _dict_from_variant(out.get("rng", {}))
	if not out["rng"].is_empty():
		out["rng"]["map_seed"] = _as_int(out["rng"].get("map_seed", 0), 0)
		out["rng"]["history_hash"] = _as_int(out["rng"].get("history_hash", 0), 0)
	return out


static func _normalize_suspend(source: Variant) -> Dictionary:
	var out := _with_defaults(source, _default_suspend())
	out["pending_action"] = _with_defaults(out.get("pending_action", {}), _default_suspend()["pending_action"])
	out["cursor_tile"] = _vector_dict_or_null(out.get("cursor_tile", null))
	out["watch_set"] = _vector_array_from_variant(out.get("watch_set", []))
	out["danger_mode"] = _as_string(out.get("danger_mode", "none"), "none")
	return out


static func _normalize_header(source: Variant, campaign_data: Dictionary,
		party_data: Dictionary, roster_data: Dictionary) -> Dictionary:
	var derived := _default_header()
	derived["campaign_id"] = _as_string(campaign_data.get("campaign_id", ""), "")
	derived["node_id"] = _as_string(campaign_data.get("node_id", ""), "")
	derived["party"]["count"] = _array_from_variant(roster_data.get("units", [])).size()
	derived["party"]["gold"] = _as_int(
		_dict_from_variant(party_data.get("resources", {})).get("party_gold", 0), 0)
	var out := _with_defaults(source, derived)
	out["badges"] = _string_array_from_variant(out.get("badges", []))
	out["party"] = _with_defaults(out.get("party", {}), derived["party"])
	out["party"]["count"] = _as_int(out["party"].get("count", derived["party"]["count"]),
		derived["party"]["count"])
	out["party"]["gold"] = _as_int(out["party"].get("gold", derived["party"]["gold"]),
		derived["party"]["gold"])
	out["party"]["lord"] = _as_string(out["party"].get("lord", ""), "")
	if _as_string(out.get("campaign_id", ""), "") == "":
		out["campaign_id"] = derived["campaign_id"]
	if _as_string(out.get("node_id", ""), "") == "":
		out["node_id"] = derived["node_id"]
	if out["party"]["count"] == 0 and derived["party"]["count"] > 0:
		out["party"]["count"] = derived["party"]["count"]
	if out["party"]["gold"] == 0 and derived["party"]["gold"] != 0:
		out["party"]["gold"] = derived["party"]["gold"]
	return out


func _validate_rng(rng_data: Variant) -> Array[String]:
	var errors: Array[String] = []
	if not (rng_data is Dictionary) or rng_data.is_empty():
		return errors
	if not (rng_data.get("map_seed") is int) or not (rng_data.get("history_hash") is int):
		errors.append("SaveData: map_runtime.rng must carry int map_seed and history_hash")
	return errors


func _validate_inventory_refs(data_manager: Object) -> Array[String]:
	var errors: Array[String] = []
	errors.append_array(_validate_entry_array(
		party.get("convoy", {}).get("entries", []),
		"SaveData party.convoy.entries",
		data_manager))

	var units: Array = _array_from_variant(roster.get("units", []))
	for i in units.size():
		errors.append_array(_validate_entry_array(
			_inventory_entries_from_unit_dict(units[i]),
			"SaveData roster.units[%d].inventory.entries" % i,
			data_manager))

	var runtime_units: Array = _array_from_variant(map_runtime.get("units", []))
	for i in runtime_units.size():
		errors.append_array(_validate_entry_array(
			_inventory_entries_from_unit_dict(runtime_units[i]),
			"SaveData map_runtime.units[%d].inventory.entries" % i,
			data_manager))
	return errors


func _validate_entry_array(entries: Variant, path: String, data_manager: Object) -> Array[String]:
	var errors: Array[String] = []
	if not (entries is Array):
		errors.append("%s is not an Array" % path)
		return errors
	for i in entries.size():
		errors.append_array(SaveCodec.validate_inventory_entry_dict(
			entries[i], "%s[%d]" % [path, i], data_manager))
	return errors


static func _inventory_entries_from_unit_dict(unit_data: Variant) -> Array:
	if not (unit_data is Dictionary):
		return []
	var inventory: Variant = unit_data.get("inventory", [])
	if inventory is Dictionary:
		return _array_from_variant(inventory.get("entries", []))
	return _array_from_variant(inventory)


static func _default_integrity() -> Dictionary:
	return {"payload_hash": "", "schema_hash": ""}


static func _default_header() -> Dictionary:
	return {
		"campaign_id": "",
		"node_id": "",
		"chapter_name": "",
		"map_name": "",
		"progress": "",
		"playtime_seconds": 0,
		"last_saved": "",
		"party": {"count": 0, "gold": 0, "lord": ""},
		"badges": [],
	}


static func _default_campaign() -> Dictionary:
	return {
		"campaign_id": "",
		"node_id": "",
		"cleared_nodes": [],
		"rules": {
			"death_mode": "casual",
			"leveling_method": "growth_random",
			"auto_promote_at_max_level": false,
			"pair_up_enabled": true,
			"max_skills": 5,
			"max_inventory": 8,
			"exp_gaining_factions": ["blue", "green"],
			"hit_formula": "two_roll",
			"rewind_charges_per_map": 4,
			"profile_selections": {},
			"exposed_tunables": {},
			"pxp_profiles": {},
		},
		"vars": {},
		"flags": [],
		"relationship_graph": {},
		"recruited_flags": [],
		"key_item_custody": {},
		"pvp": null,
	}


static func _default_party() -> Dictionary:
	return {
		"resources": {},
		"convoy": {"entries": []},
		"bonus_exp": 0,
		"training_purchase_counts": {},
	}


static func _default_roster() -> Dictionary:
	return {"units": []}


static func _default_map_runtime() -> Dictionary:
	return {
		"vars": {},
		"flags": [],
		"objective_latches": {},
		"events_fired": [],
		"objects": {},
		"discovered_units": [],
		"units": [],
		"pair_carry": {},
		"relationship_overrides": {},
		"relationship_gain_counters": {},
		"key_item_custody": {},
		"dropped_items": [],
		"battalion_charges": {},
		"rng": {},
	}


static func _default_suspend() -> Dictionary:
	return {
		"kind": null,
		"pending_action": {"source_id": null, "style_id": null},
		"conversation_resume": null,
		"cursor_tile": null,
		"mode": null,
		"watch_set": [],
		"danger_mode": "none",
	}


static func _with_defaults(source: Variant, defaults: Dictionary) -> Dictionary:
	var out: Dictionary = source.duplicate(true) if source is Dictionary else {}
	_merge_missing(out, defaults)
	return out


static func _merge_missing(out: Dictionary, defaults: Dictionary) -> void:
	for key in defaults.keys():
		if not out.has(key):
			out[key] = _deep_copy(defaults[key])
		elif out[key] is Dictionary and defaults[key] is Dictionary:
			_merge_missing(out[key], defaults[key])


static func _deep_copy(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value


static func _dict_from_variant(value: Variant) -> Dictionary:
	return value.duplicate(true) if value is Dictionary else {}


static func _array_from_variant(value: Variant) -> Array:
	return value.duplicate(true) if value is Array else []


static func _string_array_from_variant(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if not (value is Array):
		return out
	for item in value:
		out.append(String(item))
	return out


static func _vector_array_from_variant(value: Variant) -> Array:
	var out: Array = []
	if not (value is Array):
		return out
	for item in value:
		var tile: Variant = _vector_dict_or_null(item)
		if tile != null:
			out.append(tile)
	return out


static func _vector_dict_or_null(value: Variant) -> Variant:
	if value == null:
		return null
	if value is Vector2i:
		return SaveCodec.vector2i_to_dict(value)
	if value is Dictionary or value is Array:
		return SaveCodec.vector2i_to_dict(SaveCodec.vector2i_from_dict(value))
	return null


static func _as_int(value: Variant, default_value: int) -> int:
	if value is int:
		return value
	if value is float and absf(float(value) - float(int(value))) < 0.00001:
		return int(value)
	return default_value


static func _as_string(value: Variant, default_value: String) -> String:
	if value == null:
		return default_value
	return String(value)
