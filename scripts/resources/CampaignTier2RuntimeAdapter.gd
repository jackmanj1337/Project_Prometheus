class_name CampaignTier2RuntimeAdapter extends RefCounted
# Converts a fully validated Tier-2 pack into the engine's existing runtime
# Resource objects. This is an adapter, not a second validator or disk cache.

const EntitySchemas = preload("res://scripts/data/EntitySchemaRegistry.gd")
const PairUpBonusTableScript = preload("res://scripts/resources/PairUpBonusTable.gd")
const RegistryEntryScript = preload("res://scripts/resources/RegistryEntry.gd")
const CampaignVarDefScript = preload("res://scripts/resources/CampaignVarDef.gd")

const MAP_SCHEME := "campaign-pack://"


class Result:
	extends RefCounted
	var valid := false
	var errors: Array[String] = []
	var package_id := ""
	var package_version := ""
	var content_schema_version := 0
	var content_fingerprint := ""
	var campaigns: Dictionary = {}
	var map_registry: Dictionary = {}
	var maps: Dictionary = {}
	var rosters: Dictionary = {}
	var classes: Dictionary = {}
	var items: Dictionary = {}
	var weapons: Dictionary = {}
	var skills: Dictionary = {}
	var pair_up_bonus_table: Resource = null
	var registry_entries: Array[Resource] = []
	var advancement_edges: Dictionary = {}
	var advancement_routes: Dictionary = {}
	# Validated terrain documents, kept as documents rather than adapted here: the
	# runtime object is a TerrainRegistry built by merging them over the engine set,
	# and that merge belongs to the registry that owns the rules, not to this adapter.
	var terrain: Dictionary = {}
	# Validated `terrain_variant` documents ([TER-1]), kept as documents for the same
	# reason terrain is: `TerrainRegistry` owns the merge, so validation and activation
	# cannot disagree about it.
	var terrain_variants: Dictionary = {}
	# logical asset id -> pack-absolute path of the validated file. Documents carry
	# logical ids, never paths, so this is the one place a media reference becomes
	# something loadable.
	var assets: Dictionary = {}


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
	result.content_schema_version = catalogue.format_version
	result.content_fingerprint = catalogue.content_fingerprint()
	_build_assets(root, catalogue, result)
	_build_terrain(catalogue, result)
	_build_terrain_variants(catalogue, result)
	_build_classes(catalogue, result)
	_build_advancement_documents(catalogue, result)
	_build_items(catalogue, result)
	_build_weapons(catalogue, result)
	_build_skills(catalogue, result)
	_build_pair_up_bonus_table(catalogue, result)
	_build_registry_entries(catalogue, result)
	_build_rosters(catalogue, result)
	_build_maps(catalogue, result)
	_build_map_registry(catalogue, result)
	_build_campaigns(catalogue, result)
	result.valid = result.errors.is_empty()
	return result


static func _build_advancement_documents(catalogue: Tier2Catalogue, result: Result) -> void:
	for entry in catalogue.entries:
		var kind: String = entry["kind"]
		if kind == "advancement_edge":
			result.advancement_edges[entry["id"]] = (
				catalogue.get_document(kind, entry["id"]).duplicate(true)
			)
		elif kind == "advancement_route":
			result.advancement_routes[entry["id"]] = (
				catalogue.get_document(kind, entry["id"]).duplicate(true)
			)


# Resolves each validated media record to a loadable path. Whole-pack validation has
# already proved the file exists and matches its digest, so this only joins the pack
# root; nothing here re-checks integrity.
static func _build_assets(root: String, catalogue: Tier2Catalogue, result: Result) -> void:
	for entry in catalogue.entries:
		if entry["kind"] != "asset_registry":
			continue
		var raw: Variant = catalogue.get_document("asset_registry", entry["id"])
		if not raw is Dictionary or not raw.get("assets", null) is Dictionary:
			continue
		for logical_id in raw["assets"]:
			var record: Variant = raw["assets"][logical_id]
			if record is Dictionary:
				var adapted := {
					"path": root.trim_suffix("/").path_join(String(record.get("path", ""))),
					"decoded_type": String(record.get("decoded_type", "")),
				}
				var sidecar_relative := String(record.get("sidecar_path", ""))
				if not sidecar_relative.is_empty():
					adapted["sidecar_path"] = root.trim_suffix("/").path_join(sidecar_relative)
				result.assets[String(logical_id)] = adapted


# Terrain retunes reach the runtime as documents. JSON decodes every number as a
# float, so the integer fields are narrowed here — a move cost of 2.0 handed to
# pathfinding compares unequal to the integers the cost tables use, the same trap
# proven on weapon formula parameters and roster stat maps. `heal_fraction` is
# genuinely fractional and stays a float.
static func _build_terrain(catalogue: Tier2Catalogue, result: Result) -> void:
	for entry in catalogue.entries:
		if entry["kind"] != "terrain":
			continue
		var raw: Variant = catalogue.get_document("terrain", entry["id"])
		if not raw is Dictionary:
			continue
		var document: Dictionary = (raw as Dictionary).duplicate(true)
		for field in ["def_bonus", "avoid_bonus"]:
			if document.has(field):
				document[field] = int(document[field])
		if document.get("move_costs", null) is Dictionary:
			var costs: Dictionary = document["move_costs"]
			for movement_type in costs:
				costs[movement_type] = int(costs[movement_type])
		result.terrain[String(entry["id"])] = document


# Variants carry no numbers at all — only a terrain id, a grid char, a label and an
# asset id — so unlike terrain there is nothing to narrow from JSON's floats here.
static func _build_terrain_variants(catalogue: Tier2Catalogue, result: Result) -> void:
	for entry in catalogue.entries:
		if entry["kind"] != "terrain_variant":
			continue
		var raw: Variant = catalogue.get_document("terrain_variant", entry["id"])
		if not raw is Dictionary:
			continue
		result.terrain_variants[String(entry["id"])] = (raw as Dictionary).duplicate(true)


static func _build_items(catalogue: Tier2Catalogue, result: Result) -> void:
	for entry in catalogue.entries:
		if entry["kind"] != "item":
			continue
		var raw: Dictionary = catalogue.get_document("item", entry["id"])
		var value := ItemData.new()
		_apply_properties(value, raw, ["effect_params"])
		value.id = String(entry["id"])
		# JSON decodes every number as a float, so an authored `{"amount": 10}` would
		# reach the effect handlers as 10.0 and compare unequal to an integer.
		value.effect_params = EntitySchemas.normalize_json_integers(raw.get("effect_params", {}))
		result.items[value.id] = value


static func _build_weapons(catalogue: Tier2Catalogue, result: Result) -> void:
	for entry in catalogue.entries:
		if entry["kind"] != "weapon":
			continue
		var raw: Dictionary = catalogue.get_document("weapon", entry["id"])
		var value := WeaponData.new()
		# `effect_tags` is an Array[String] export: assigning a raw JSON Array through
		# Object.set() silently leaves it empty, so it is converted explicitly.
		_apply_properties(
			value,
			raw,
			["effect_tags", "range_min_parameters", "range_max_parameters"],
		)
		value.id = String(entry["id"])
		value.effect_tags = _strings(raw.get("effect_tags", []))
		# JSON numbers decode as floats; RangeFormulaRegistry requires true integers,
		# so the validated selection is narrowed once here rather than on every
		# get_range_min/get_range_max call.
		value.range_min_parameters = EntitySchemas.normalize_json_integers(
			raw.get("range_min_parameters", {})
		)
		value.range_max_parameters = EntitySchemas.normalize_json_integers(
			raw.get("range_max_parameters", {})
		)
		result.weapons[value.id] = value


static func _build_skills(catalogue: Tier2Catalogue, result: Result) -> void:
	for entry in catalogue.entries:
		if entry["kind"] != "skill":
			continue
		var raw: Dictionary = catalogue.get_document("skill", entry["id"])
		var value := SkillData.new()
		_apply_properties(value, raw)
		value.id = String(entry["id"])
		value.effect_params = EntitySchemas.normalize_json_integers(raw.get("effect_params", {}))
		result.skills[value.id] = value


static func _build_pair_up_bonus_table(catalogue: Tier2Catalogue, result: Result) -> void:
	for entry in catalogue.entries:
		if entry["kind"] != "pair_up_bonus_table":
			continue
		if result.pair_up_bonus_table != null:
			result.errors.append("Tier-2 pack contains more than one pair-up bonus table")
			return
		var raw: Dictionary = catalogue.get_document("pair_up_bonus_table", entry["id"])
		var value := PairUpBonusTableScript.new()
		value.scaling_divisor = int(raw["scaling_divisor"])
		value.scaling_stats = _strings(raw["scaling_stats"])
		value.class_bonuses = EntitySchemas.normalize_json_integers(raw["class_bonuses"])
		result.pair_up_bonus_table = value


static func _build_registry_entries(catalogue: Tier2Catalogue, result: Result) -> void:
	for entry in catalogue.entries:
		if entry["kind"] != "registry_entry":
			continue
		var raw: Dictionary = catalogue.get_document("registry_entry", entry["id"])
		var value: Resource = (
			CampaignVarDefScript.new()
			if String(raw.get("family", "")) == "campaign_vars"
			else RegistryEntryScript.new()
		)
		_apply_properties(
			value, raw, ["kind", "entry_kind", "subjects", "save_fields", "composition"]
		)
		value.id = String(raw["entry_id"])
		value.kind = String(raw["entry_kind"])
		value.subjects = _strings(raw.get("subjects", []))
		value.save_fields = _strings(raw.get("save_fields", []))
		var composition: Array[Dictionary] = []
		for step in raw.get("composition", []):
			composition.append((step as Dictionary).duplicate(true))
		value.composition = composition
		result.registry_entries.append(value)


static func map_uri(package_id: String, package_version: String, map_id: String) -> String:
	return "%s%s/%s/%s" % [MAP_SCHEME, package_id, package_version, map_id]


static func _build_classes(catalogue: Tier2Catalogue, result: Result) -> void:
	for entry in catalogue.entries:
		if entry["kind"] != "class":
			continue
		var raw: Dictionary = catalogue.get_document("class", entry["id"])
		var value := ClassData.new()
		# Same `Array[String]` export trap as `WeaponData.effect_tags`: a raw JSON array
		# assigned through `Object.set()` leaves the export EMPTY. Left unconverted,
		# `allowed_weapon_families` would silently make every class unable to equip
		# anything; the other three admitted lists fail just as quietly.
		const CLASS_STRING_LISTS: Array[String] = [
			"allowed_weapon_families", "class_groups", "special_qualities", "vulnerability_groups"
		]
		_apply_properties(value, raw, CLASS_STRING_LISTS)
		for field in CLASS_STRING_LISTS:
			if raw.has(field):
				value.set(field, _strings(raw[field]))
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
			_apply_unit_properties(unit, unit_raw)
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
				"turn_order",
				"victory_conditions",
				"defeat_conditions",
				# `factions` is an `Array[FactionData]` export, so a raw JSON array
				# assigned through `Object.set()` would silently leave it EMPTY — the
				# same trap proven on effect tags, class string lists, and unit arrays.
				# It was excluded from neither the copy nor a conversion before, so an
				# authored faction list never reached the map at all.
				"factions",
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
		map.factions = _factions(raw.get("factions", []))
		map.enemy_placements = _enemy_placements(raw.get("enemy_placements", []), result)
		map.victory_conditions = _objective_groups(raw.get("victory_conditions", {}), result)
		map.defeat_conditions = _objective_groups(raw.get("defeat_conditions", {}), result)
		result.maps[map.id] = map


static func _build_map_registry(catalogue: Tier2Catalogue, result: Result) -> void:
	for entry in catalogue.entries:
		if entry["kind"] != "map_registry":
			continue
		var document: Variant = catalogue.get_document("map_registry", entry["id"])
		var rows: Array = document.get("entries", []) if document is Dictionary else document
		for raw in rows:
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
		_apply_unit_properties(unit, unit_raw)
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


# Builds the typed faction list. An empty authored list is legal and meaningful:
# `TurnManager`/`GameState` construct the blue+red default at start_map time, so a
# map that does not care about factions stays authorable as it is today.
static func _factions(source: Variant) -> Array[FactionData]:
	var output: Array[FactionData] = []
	if not source is Array:
		return output
	for raw in source:
		if not raw is Dictionary:
			continue
		var faction := FactionData.new()
		# `color` is a JSON array, not a Color, so it is converted rather than copied.
		_apply_properties(faction, raw, ["color"])
		faction.id = String(raw.get("id", ""))
		if raw.get("color", null) is Array and raw["color"].size() >= 3:
			var channels: Array = raw["color"]
			faction.color = Color(
				float(channels[0]),
				float(channels[1]),
				float(channels[2]),
				float(channels[3]) if channels.size() > 3 else 1.0
			)
		output.append(faction)
	return output


static func _inventory(source: Variant) -> Array[InventoryEntry]:
	var output: Array[InventoryEntry] = []
	if source is Array:
		for raw in source:
			if not raw is Dictionary:
				continue
			# `InventoryEntry` dispatches on entry_type, so the slot's kind is decided
			# here once. Whole-pack validation has already proved exactly one id is set.
			var item_id := String(raw.get("item_id", ""))
			if not item_id.is_empty():
				output.append(InventoryEntry.make_item(item_id, int(raw.get("uses", 1))))
				continue
			var entry := InventoryEntry.make_weapon(
				String(raw.get("weapon_id", "")), int(raw.get("uses", 1))
			)
			# The authored variant choice rides on the slot, so `SaveCodec` restores
			# it with the rest of the entry instead of re-deciding eligibility.
			entry.weapon_variant_id = String(raw.get("weapon_variant_id", ""))
			output.append(entry)
	return output


# Units are the widest resource the adapter writes, and two Godot behaviours make a
# plain property copy lossy here:
#   - `Object.set()` on an `Array[String]` export with a raw JSON array silently
#     leaves the export EMPTY, so every typed string array is converted explicitly;
#   - JSON decodes every number as a float, so the stat/WEXP dictionaries would
#     otherwise carry floats into WEXP-rank and growth comparisons.
static func _apply_unit_properties(unit: UnitData, raw: Dictionary) -> void:
	const TYPED_ARRAYS: Array[String] = ["skills", "earned_skills", "reclass_options"]
	const INT_MAPS: Array[String] = ["growth_rates", "growth_accumulators", "weapon_wexp"]
	var excluded: Array[String] = ["inventory"]
	excluded.append_array(TYPED_ARRAYS)
	excluded.append_array(INT_MAPS)
	_apply_properties(unit, raw, excluded)
	unit.inventory = _inventory(raw.get("inventory", []))
	for field in TYPED_ARRAYS:
		if raw.has(field):
			unit.set(field, _strings(raw[field]))
	for field in INT_MAPS:
		if raw.has(field):
			unit.set(field, EntitySchemas.normalize_json_integers(raw[field]))


static func _objective_groups(source: Variant, result: Result) -> Dictionary:
	var output: Dictionary = {}
	if not source is Dictionary:
		return output
	for group_id in source:
		var conditions: Array[ObjectiveCondition] = []
		var rows: Variant = source[group_id]
		if not rows is Array:
			result.errors.append("Tier-2 objective group '%s' must be an array" % group_id)
			continue
		for raw in rows:
			if not raw is Dictionary:
				continue
			var condition := ObjectiveCondition.new()
			_apply_properties(condition, raw, ["tile", "tiles", "unit_ids"])
			condition.unit_ids = _strings(raw.get("unit_ids", []))
			condition.tiles = _tiles(raw.get("tiles", []), "objective tiles", result.errors)
			if raw.has("tile"):
				condition.tile = _tile(raw["tile"], "objective tile", result.errors)
			conditions.append(condition)
		output[String(group_id)] = conditions
	return output


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
