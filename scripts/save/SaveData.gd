class_name SaveData
extends RefCounted

const SaveCodec = preload("res://scripts/save/SaveCodec.gd")
const SavePolicy = preload("res://scripts/save/SavePolicy.gd")

const FORMAT_VERSION := 1
const TOP_LEVEL_KEYS: Array[String] = [
	"format_version",
	"_warning",
	"save_label",
	"origin",
	"rule_id",
	"integrity",
	"header",
	"campaign",
	"party",
	"roster",
	"map_runtime",
	"suspend",
	"ledger",
]

var format_version: int = FORMAT_VERSION
var warning: String = "This is a human-readable campaign save. Editing may cause invalid or unintended game state."
var save_label: String = ""
var origin: String = "manual"
var rule_id: String = ""
var integrity: Dictionary = {}
var header: Dictionary = {}
var campaign: Dictionary = {}
var party: Dictionary = {}
var roster: Dictionary = {}
var map_runtime: Dictionary = {}
var suspend: Dictionary = {}
var ledger: Array[Dictionary] = []


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
	format_version = SaveCodec.as_int(data.get("format_version", FORMAT_VERSION), FORMAT_VERSION)
	warning = _as_string(data.get("_warning", warning), warning)
	save_label = _as_string(data.get("save_label", ""), "")
	origin = _as_string(data.get("origin", "manual"), "manual")
	rule_id = _as_string(data.get("rule_id", ""), "")
	integrity = _normalize_integrity(data.get("integrity", {}))
	campaign = _normalize_campaign(data.get("campaign", {}), data)
	party = _normalize_party(data.get("party", {}), data)
	roster = _normalize_roster(data.get("roster", {}), data)
	map_runtime = _normalize_map_runtime(data.get("map_runtime", {}))
	suspend = _normalize_suspend(data.get("suspend", {}))
	ledger = _normalize_ledger(data.get("ledger", []))
	header = _normalize_header(data.get("header", {}), campaign, party, roster, map_runtime)


func to_dict() -> Dictionary:
	var header_dict := _normalize_header(header, campaign, party, roster, map_runtime)
	return {
		"format_version": format_version,
		"_warning": warning,
		"save_label": save_label,
		"origin": origin,
		"rule_id": rule_id,
		"integrity": integrity.duplicate(true),
		"header": header_dict,
		"campaign": campaign.duplicate(true),
		"party": party.duplicate(true),
		"roster": roster.duplicate(true),
		"map_runtime": map_runtime.duplicate(true),
		"suspend": suspend.duplicate(true),
		"ledger": ledger.duplicate(true),
	}


func validate(data_manager: Object = null) -> Array[String]:
	var errors: Array[String] = []
	if format_version != FORMAT_VERSION:
		errors.append("SaveData: unsupported format_version %d" % format_version)
	if origin not in ["manual", "auto"]:
		errors.append("SaveData: origin must be 'manual' or 'auto'")
	if origin == "auto" and rule_id.is_empty():
		errors.append("SaveData: automatic saves require rule_id")
	if not (integrity.get("payload_hash", "") is String):
		errors.append("SaveData: integrity.payload_hash must be a String")
	if not (integrity.get("schema_hash", "") is String):
		errors.append("SaveData: integrity.schema_hash must be a String")
	errors.append_array(_validate_rng(map_runtime.get("rng", {})))
	errors.append_array(_validate_ledger())
	errors.append_array(SavePolicy.validate(campaign.get("rules", {}).get("save_slot_classes", []),
		campaign.get("rules", {}).get("autosave_rules", []),
		SaveCodec.as_int(campaign.get("rules", {}).get("rewind_charges_per_map", 4), 4)))
	errors.append_array(_validate_inventory_refs(data_manager))
	return errors


func _validate_ledger() -> Array[String]:
	var errors: Array[String] = []
	var is_mid_map := String(map_runtime.get("map_path", "")) != ""
	if is_mid_map and ledger.is_empty():
		errors.append("SaveData: mid_map document must persist its rewind ledger")
	if not is_mid_map and not ledger.is_empty():
		errors.append("SaveData: between_map document cannot carry a rewind ledger")
	for i in ledger.size():
		var item: Dictionary = ledger[i]
		if String(item.get("reason", "")) not in ["round_start", "activation"] \
				or not (item.get("entry", null) is Dictionary):
			errors.append("SaveData: ledger[%d] is malformed" % i)
	return errors


func _apply_defaults() -> void:
	format_version = FORMAT_VERSION
	warning = "This is a human-readable campaign save. Editing may cause invalid or unintended game state."
	save_label = ""
	origin = "manual"
	rule_id = ""
	integrity = _default_integrity()
	header = _default_header()
	campaign = _default_campaign()
	party = _default_party()
	roster = _default_roster()
	map_runtime = _default_map_runtime()
	suspend = _default_suspend()
	ledger = []


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
	out["package_id"] = _as_string(out.get("package_id", ""), "")
	out["package_version"] = _as_string(out.get("package_version", ""), "")
	out["node_id"] = _as_string(out.get("node_id", ""), "")
	out["cleared_nodes"] = SaveCodec.string_array_from_variant(out.get("cleared_nodes", []))
	out["vars"] = _dict_from_variant(out.get("vars", {}))
	out["flags"] = SaveCodec.string_array_from_variant(out.get("flags", []))
	out["rules"] = _normalize_rules(raw_campaign.get("rules", {}), root)
	out["recruited_flags"] = SaveCodec.string_array_from_variant(out.get("recruited_flags", []))
	return out


static func _normalize_rules(source: Variant, root: Dictionary) -> Dictionary:
	var out := _with_defaults(root.get("rules", {}), _default_campaign()["rules"])
	if source is Dictionary:
		for key in source.keys():
			out[key] = source[key]
	out["hit_formula"] = _as_string(out.get("hit_formula", "two_roll"), "two_roll")
	out["leveling_method"] = _as_string(out.get("leveling_method", "growth_random"), "growth_random")
	out["auto_promote_at_max_level"] = bool(out.get("auto_promote_at_max_level", false))
	out["pair_up_enabled"] = bool(out.get("pair_up_enabled", true))
	out["max_skills"] = SaveCodec.as_int(out.get("max_skills", 5), 5)
	out["max_inventory"] = SaveCodec.as_int(out.get("max_inventory", 8), 8)
	out["exp_gaining_factions"] = SaveCodec.string_array_from_variant(
		out.get("exp_gaining_factions", ["blue", "green"]))
	out["rewind_charges_per_map"] = SaveCodec.as_int(out.get("rewind_charges_per_map", 4), 4)
	# B1-LEDGER Phase 2: within-map ledger retention budgets (-1 = infinite tier).
	out["undo_activations"] = SaveCodec.as_int(out.get("undo_activations", 0), 0)
	out["undo_rounds"] = SaveCodec.as_int(out.get("undo_rounds", 0), 0)
	out["save_slot_classes"] = SavePolicy.normalize_slot_classes(
		out.get("save_slot_classes", SavePolicy.classic_gba()))
	out["autosave_rules"] = SavePolicy.normalize_autosave_rules(
		out.get("autosave_rules", SavePolicy.default_autosave_rules()))
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
		out["resources"]["party_gold"] = SaveCodec.as_int(legacy_gold, 0)
	out.erase("party_gold")
	out.erase("gold")

	out["convoy"] = _with_defaults(out.get("convoy", {}), {"entries": []})
	var convoy_entries: Variant = out["convoy"].get("entries", [])
	if convoy_entries is Array:
		out["convoy"]["entries"] = _array_from_variant(convoy_entries)
	else:
		push_warning("SaveData: dropped malformed party.convoy.entries; expected Array")
		out["convoy"]["entries"] = []
	if out.has("items") and out["convoy"].get("entries", []).is_empty():
		out["convoy"]["entries"] = _array_from_variant(out["items"])
	out.erase("items")
	out["bonus_exp"] = SaveCodec.as_int(out.get("bonus_exp", 0), 0)
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
	out["map_id"] = _as_string(out.get("map_id", ""), "")
	out["map_path"] = _as_string(out.get("map_path", ""), "")
	out["vars"] = _dict_from_variant(out.get("vars", {}))
	out["flags"] = SaveCodec.string_array_from_variant(out.get("flags", []))
	out["events_fired"] = SaveCodec.string_array_from_variant(out.get("events_fired", []))
	out["discovered_units"] = SaveCodec.string_array_from_variant(out.get("discovered_units", []))
	out["units"] = _array_from_variant(out.get("units", []))
	out["turn"] = _normalize_turn(out.get("turn", {}))
	out["rng"] = _dict_from_variant(out.get("rng", {}))
	if not out["rng"].is_empty():
		# Godot JSON parses large integers through a lossy numeric path. Store
		# RNG timeline fields as decimal strings in SaveData while RngService keeps
		# using ints in memory.
		out["rng"]["map_seed"] = _rng_int_string(out["rng"].get("map_seed", 0))
		out["rng"]["history_hash"] = _rng_int_string(out["rng"].get("history_hash", 0))
	return out


static func _normalize_suspend(source: Variant) -> Dictionary:
	var out := _with_defaults(source, _default_suspend())
	out["pending_action"] = _with_defaults(out.get("pending_action", {}), _default_suspend()["pending_action"])
	out["cursor_tile"] = _vector_dict_or_null(out.get("cursor_tile", null))
	out["watch_set"] = SaveCodec.string_array_from_variant(out.get("watch_set", []))
	out["danger_mode"] = _as_string(out.get("danger_mode", "none"), "none")
	out["threat_views_version"] = SaveCodec.as_int(out.get("threat_views_version", 0), 0)
	var views := _dict_from_variant(out.get("threat_views_by_faction", {}))
	for faction_id in views:
		var view := _dict_from_variant(views[faction_id])
		view["watch_set"] = SaveCodec.string_array_from_variant(view.get("watch_set", []))
		view["danger_mode"] = _as_string(view.get("danger_mode", "none"), "none")
		views[faction_id] = view
	out["threat_views_by_faction"] = views
	return out


static func _normalize_ledger(source: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not (source is Array):
		return out
	for item in source:
		if item is Dictionary:
			var normalized: Dictionary = item.duplicate(true)
			var entry: Variant = normalized.get("entry", null)
			if entry is Dictionary:
				var normalized_entry: Dictionary = entry.duplicate(true)
				normalized_entry["map_runtime"] = _normalize_map_runtime(
					normalized_entry.get("map_runtime", {}))
				normalized_entry["suspend"] = _normalize_suspend(
					normalized_entry.get("suspend", {}))
				normalized["entry"] = normalized_entry
			out.append(normalized)
	return out


static func _normalize_turn(source: Variant) -> Dictionary:
	var out := _with_defaults(source, _default_map_runtime()["turn"])
	out["turn_number"] = SaveCodec.as_int(out.get("turn_number", 1), 1)
	out["phase"] = _as_string(out.get("phase", "player"), "player")
	out["active_faction"] = _as_string(out.get("active_faction", ""), "")
	out["active_faction_idx"] = SaveCodec.as_int(out.get("active_faction_idx", 0), 0)
	out["turn_order"] = SaveCodec.string_array_from_variant(out.get("turn_order", []))
	out["activation_mode"] = _as_string(out.get("activation_mode", "WHOLE_PHASE"), "WHOLE_PHASE")
	out["unit_states"] = SaveCodec.int_dict_from_variant(out.get("unit_states", {}))
	out["seize_records"] = _array_from_variant(out.get("seize_records", []))
	out["escape_records"] = _array_from_variant(out.get("escape_records", []))
	out["group_eliminated_round"] = SaveCodec.int_dict_from_variant(out.get("group_eliminated_round", {}))
	return out


static func _normalize_header(source: Variant, campaign_data: Dictionary,
		party_data: Dictionary, roster_data: Dictionary, map_data: Dictionary) -> Dictionary:
	var derived := _default_header()
	derived["campaign_id"] = _as_string(campaign_data.get("campaign_id", ""), "")
	derived["node_id"] = _as_string(campaign_data.get("node_id", ""), "")
	derived["campaign_state"] = "completed" if derived["campaign_id"] != "" \
			and derived["node_id"] == "" else "in_progress"
	derived["save_kind"] = "mid_map" if String(map_data.get("map_path", "")) != "" \
		else "between_map"
	derived["turn_number"] = SaveCodec.as_int(
		_dict_from_variant(map_data.get("turn", {})).get("turn_number", 1), 1)
	derived["map_id"] = _as_string(map_data.get("map_id", ""), "")
	derived["party"]["count"] = _array_from_variant(roster_data.get("units", [])).size()
	derived["party"]["gold"] = SaveCodec.as_int(
		_dict_from_variant(party_data.get("resources", {})).get("party_gold", 0), 0)
	var out := _with_defaults(source, derived)
	out["badges"] = SaveCodec.string_array_from_variant(out.get("badges", []))
	out["party"] = _with_defaults(out.get("party", {}), derived["party"])
	out["party"]["count"] = SaveCodec.as_int(out["party"].get("count", derived["party"]["count"]),
		derived["party"]["count"])
	out["party"]["gold"] = SaveCodec.as_int(out["party"].get("gold", derived["party"]["gold"]),
		derived["party"]["gold"])
	out["party"]["lord"] = _as_string(out["party"].get("lord", ""), "")
	if _as_string(out.get("campaign_id", ""), "") == "":
		out["campaign_id"] = derived["campaign_id"]
	if _as_string(out.get("node_id", ""), "") == "":
		out["node_id"] = derived["node_id"]
	# Lifecycle is authoritative campaign state, not a presentation label. Derive
	# it on every normalization so a reused header cannot retain a stale marker.
	out["campaign_state"] = derived["campaign_state"]
	out["save_kind"] = derived["save_kind"]
	out["turn_number"] = derived["turn_number"]
	out["map_id"] = derived["map_id"]
	if out["party"]["count"] == 0 and derived["party"]["count"] > 0:
		out["party"]["count"] = derived["party"]["count"]
	if out["party"]["gold"] == 0 and derived["party"]["gold"] != 0:
		out["party"]["gold"] = derived["party"]["gold"]
	return out


func _validate_rng(rng_data: Variant) -> Array[String]:
	var errors: Array[String] = []
	if not (rng_data is Dictionary) or rng_data.is_empty():
		return errors
	if not _is_rng_value(rng_data.get("map_seed")) \
			or not _is_rng_value(rng_data.get("history_hash")):
		errors.append("SaveData: map_runtime.rng must carry int or decimal-string map_seed and history_hash")
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
		"package_id": "",
		"package_version": "",
		"node_id": "",
		"campaign_state": "in_progress",
		"save_kind": "between_map",
		"turn_number": 1,
		"map_id": "",
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
			"undo_activations": 0,
			"undo_rounds": 0,
			"save_slot_classes": SavePolicy.classic_gba(),
			"autosave_rules": SavePolicy.default_autosave_rules(),
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
		"map_id": "",
		"map_path": "",
		"vars": {},
		"flags": [],
		"objective_latches": {},
		"events_fired": [],
		"objects": {},
		"discovered_units": [],
		"units": [],
		"turn": {
			"turn_number": 1,
			"phase": "player",
			"active_faction": "",
			"active_faction_idx": 0,
			"turn_order": [],
			"activation_mode": "WHOLE_PHASE",
			"unit_states": {},
			"seize_records": [],
			"escape_records": [],
			"group_eliminated_round": {},
		},
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
		"threat_views_version": 0,
		"threat_views_by_faction": {},
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


static func _rng_int_string(value: Variant) -> String:
	if value is String and String(value).is_valid_int():
		return String(value)
	if value is int:
		return str(value)
	if value is float and absf(float(value) - float(int(value))) < 0.00001:
		return str(int(value))
	return "0"


static func _is_rng_int_string(value: Variant) -> bool:
	return value is String and String(value).is_valid_int()


static func _is_rng_value(value: Variant) -> bool:
	return value is int or _is_rng_int_string(value)


static func _as_string(value: Variant, default_value: String) -> String:
	if value == null:
		return default_value
	return String(value)
