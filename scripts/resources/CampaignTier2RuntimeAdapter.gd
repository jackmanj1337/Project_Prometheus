class_name CampaignTier2RuntimeAdapter extends RefCounted
# Converts a fully validated Tier-2 pack into the engine's existing runtime
# Resource objects. This is an adapter, not a second validator or disk cache.

const MAP_SCHEME := "campaign-pack://"


class Result:
	extends RefCounted
	var valid := false
	var errors: Array[String] = []
	var package_id := ""
	var package_version := ""
	var campaigns: Dictionary = {}
	var map_registry: Dictionary = {}
	var maps: Dictionary = {}
	var rosters: Dictionary = {}
	var classes: Dictionary = {}


static func load(
	pack_root: String, expected_id: String = "", expected_version: String = ""
) -> Result:
	var result := Result.new()
	var root := pack_root.trim_suffix("/")
	var manifest_raw: Variant = _read_json(root.path_join("manifest.json"), result.errors)
	if manifest_raw == null:
		return result
	var manifest_errors: Array[String] = []
	var manifest: PackManifest = PackManifest.parse(manifest_raw, "manifest.json", manifest_errors)
	result.errors.append_array(manifest_errors)
	if manifest == null:
		return result
	result.package_id = manifest.id
	result.package_version = manifest.version
	if not expected_id.is_empty() and manifest.id != expected_id:
		result.errors.append(
			(
				"Tier-2 runtime source id '%s' does not match requested '%s'"
				% [manifest.id, expected_id]
			)
		)
	if not expected_version.is_empty() and manifest.version != expected_version:
		result.errors.append(
			(
				"Tier-2 runtime source version '%s' does not match requested '%s'"
				% [manifest.version, expected_version]
			)
		)

	var catalogue_errors: Array[String] = []
	var catalogue := Tier2Catalogue.load_campaign_pack(root, catalogue_errors)
	result.errors.append_array(catalogue_errors)
	if catalogue == null or not result.errors.is_empty():
		return result
	_build_classes(catalogue, result)
	_build_rosters(catalogue, result)
	_build_maps(catalogue, result)
	_build_map_registry(catalogue, result)
	_build_campaigns(catalogue, result)
	result.valid = result.errors.is_empty()
	return result


static func map_uri(package_id: String, package_version: String, map_id: String) -> String:
	return "%s%s/%s/%s" % [MAP_SCHEME, package_id, package_version, map_id]


static func _build_classes(catalogue: Tier2Catalogue, result: Result) -> void:
	for entry in catalogue.entries:
		if entry["kind"] != "class":
			continue
		var raw: Dictionary = catalogue.get_document("class", entry["id"])
		var value := ClassData.new()
		_apply_properties(value, raw)
		value.id = String(entry["id"])
		if value.base_hp <= 0:
			result.errors.append(
				(
					"Tier-2 class '%s' base_hp must be greater than zero for runtime activation"
					% value.id
				)
			)
		if value.base_movement <= 0:
			(
				result
				. errors
				. append(
					(
						"Tier-2 class '%s' base_movement must be greater than zero for runtime activation"
						% value.id
					)
				)
			)
		result.classes[value.id] = value


static func _build_rosters(catalogue: Tier2Catalogue, result: Result) -> void:
	for entry in catalogue.entries:
		if entry["kind"] != "roster":
			continue
		var raw: Dictionary = catalogue.get_document("roster", entry["id"])
		var roster: Array[UnitData] = []
		for unit_raw in raw.get("units", []):
			var class_id := String(unit_raw.get("class_id", ""))
			var class_data: ClassData = result.classes.get(class_id)
			if class_data == null:
				continue  # Whole-pack validation already reports this reference.
			var unit := UnitData.new()
			_apply_class_bases(unit, class_data)
			_apply_properties(unit, unit_raw)
			unit.unit_id = String(unit_raw.get("unit_id", ""))
			unit.unit_name = String(unit_raw.get("unit_name", unit.unit_id))
			unit.class_id = class_id
			if unit.max_hp <= 0 or unit.hp <= 0:
				result.errors.append(
					(
						"Tier-2 roster '%s' unit '%s' must have positive hp"
						% [entry["id"], unit.unit_id]
					)
				)
			roster.append(unit)
		result.rosters[String(entry["id"])] = roster


static func _build_maps(catalogue: Tier2Catalogue, result: Result) -> void:
	for entry in catalogue.entries:
		if entry["kind"] != "map_data":
			continue
		var raw: Dictionary = catalogue.get_document("map_data", entry["id"])
		var map := MapData.new()
		_apply_properties(
			map,
			raw,
			[
				"grid",
				"player_start_tiles",
				"camera_start_tile",
				"enemy_placements",
				"reward_items",
				"turn_order"
			]
		)
		map.id = String(entry["id"])
		map.grid = _strings(raw.get("grid", []))
		map.reward_items = _strings(raw.get("reward_items", []))
		map.turn_order = _strings(raw.get("turn_order", []))
		map.player_start_tiles = _tiles(
			raw.get("player_start_tiles", []), "map '%s' player_start_tiles" % map.id, result.errors
		)
		if raw.has("camera_start_tile"):
			map.camera_start_tile = _tile(
				raw["camera_start_tile"], "map '%s' camera_start_tile" % map.id, result.errors
			)
		map.enemy_placements = _enemy_placements(raw.get("enemy_placements", []), result)
		result.maps[map.id] = map


static func _build_map_registry(catalogue: Tier2Catalogue, result: Result) -> void:
	for entry in catalogue.entries:
		if entry["kind"] != "map_registry":
			continue
		for raw in catalogue.get_document("map_registry", entry["id"]):
			var map_id := String(raw.get("id", ""))
			var roster_id := String(raw.get("roster_id", ""))
			result.map_registry[map_id] = {
				"id": map_id,
				"label": String(raw.get("label", map_id)),
				"map_data_path":
				map_uri(
					result.package_id, result.package_version, String(raw.get("map_data_id", ""))
				),
				"roster_policy": "campaign_pack_roster",
				"roster_source": roster_id,
				"description": String(raw.get("description", "Single-map campaign.")),
				"is_dev_only": bool(raw.get("is_dev_only", false)),
			}


static func _build_campaigns(catalogue: Tier2Catalogue, result: Result) -> void:
	for entry in catalogue.entries:
		if entry["kind"] != "campaign":
			continue
		var parse_errors: Array[String] = []
		var campaign := CampaignData.parse(
			catalogue.get_document("campaign", entry["id"]), entry["path"], parse_errors
		)
		result.errors.append_array(parse_errors)
		if campaign != null:
			result.campaigns[campaign.campaign_id] = campaign


static func _enemy_placements(source: Variant, result: Result) -> Array[Dictionary]:
	var placements: Array[Dictionary] = []
	if not source is Array:
		return placements
	for raw in source:
		if not raw is Dictionary:
			continue
		var unit_raw: Variant = raw.get("unit", null)
		if not unit_raw is Dictionary:
			result.errors.append("Tier-2 enemy placement requires an inline unit object")
			continue
		var class_id := String(unit_raw.get("class_id", ""))
		var class_data: ClassData = result.classes.get(class_id)
		if class_data == null:
			result.errors.append("Tier-2 enemy placement references missing class '%s'" % class_id)
			continue
		var unit := UnitData.new()
		_apply_class_bases(unit, class_data)
		_apply_properties(unit, unit_raw)
		unit.unit_id = String(unit_raw.get("unit_id", ""))
		unit.unit_name = String(unit_raw.get("unit_name", unit.unit_id))
		unit.class_id = class_id
		(
			placements
			. append(
				{
					"unit_data": unit,
					"tile": _tile(raw.get("tile", []), "enemy placement tile", result.errors),
					"ai_profile": String(raw.get("ai_profile", unit.ai_profile)),
					"is_boss": bool(raw.get("is_boss", false)),
					"faction": String(raw.get("faction", "red")),
				}
			)
		)
	return placements


static func _apply_class_bases(unit: UnitData, value: ClassData) -> void:
	unit.max_hp = value.base_hp
	unit.hp = value.base_hp
	unit.strength = value.base_strength
	unit.magic = value.base_magic
	unit.defense = value.base_defense
	unit.resistance = value.base_resistance
	unit.skill = value.base_skill
	unit.speed = value.base_speed
	unit.luck = value.base_luck
	unit.movement = value.base_movement
	unit.constitution = value.base_constitution
	unit.line_of_sight = value.base_line_of_sight
	unit.weapon_wexp = value.weapon_wexp_bases.duplicate(true)


static func _apply_properties(
	target: Object, raw: Dictionary, excluded: Array[String] = []
) -> void:
	var properties := {}
	for property in target.get_property_list():
		properties[String(property["name"])] = true
	for key in raw:
		var name := String(key)
		if properties.has(name) and not name in excluded:
			target.set(name, raw[key])


static func _tiles(source: Variant, owner: String, errors: Array[String]) -> Array[Vector2i]:
	var output: Array[Vector2i] = []
	if not source is Array:
		errors.append("Tier-2 %s must be an array" % owner)
		return output
	for raw in source:
		output.append(_tile(raw, owner, errors))
	return output


static func _strings(source: Variant) -> Array[String]:
	var output: Array[String] = []
	if source is Array:
		for value in source:
			output.append(String(value))
	return output


static func _tile(source: Variant, owner: String, errors: Array[String]) -> Vector2i:
	if not source is Array or source.size() != 2:
		errors.append("Tier-2 %s must be [x, y]" % owner)
		return Vector2i.ZERO
	return Vector2i(int(source[0]), int(source[1]))


static func _read_json(path: String, errors: Array[String]) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("Tier-2 runtime adapter cannot open '%s'" % path)
		return null
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		errors.append(
			"Tier-2 runtime adapter cannot parse '%s': %s" % [path, json.get_error_message()]
		)
		return null
	return json.data
