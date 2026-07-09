extends Node
# [NOTE — M-1] class_name conflicts with the autoload singleton name in Godot 4.
# Loads all content resources at startup. All game systems query this singleton
# rather than loading resources on demand, so load errors surface immediately.

# Preloaded (not autoload-referenced) so _validate_cross_references can read the
# canonical IMPLEMENTED_EFFECT_IDS list even though ItemHandler is registered as
# an autoload AFTER DataManager in project.godot (so /root/ItemHandler doesn't
# exist yet during DataManager._ready). Const access only — no instance needed.
const ItemHandlerScript = preload("res://scripts/items/ItemHandler.gd")
const ResourceManifest = preload("res://scripts/shared/ResourceManifest.gd")
# AI profiles are validated against the open AIProfileRegistry (the composition
# engine seam) rather than a closed const — adding a profile no longer needs a
# DataManager edit. See AIProfileRegistry.gd.
const AIProfileRegistry = preload("res://scripts/core/AIProfileRegistry.gd")
const StatRegistry = preload("res://scripts/core/StatRegistry.gd")
const _MAP_REGISTRY_PATH := "res://data/maps/map_registry.json"
const _VALID_ROSTER_POLICIES := ["default_roster", "fixed_test_roster", "keep_current_roster"]
const _VALID_ACTIVATION_MODES := ["WHOLE_PHASE", "ALTERNATING"]
const _VALID_OBJECTIVE_TYPES := ["rout", "defeat_boss", "seize", "escape", "survive", "protect", "turn_limit"]
const _DEFAULT_FACTION_IDS := ["blue", "green", "red", "yellow"]
const _DEFAULT_ALLIANCE_GROUP_IDS := ["allies", "foes", "rogues"]

var _classes: Dictionary = {}
var _weapons: Dictionary = {}
var _items: Dictionary = {}
var _skills: Dictionary = {}

# Weapon triangle lives in GameConstants.WEAPON_TRIANGLE — single source of truth.


func _ready() -> void:
	_load_directory("res://data/classes/", _classes)
	_load_directory("res://data/weapons/", _weapons)
	_load_directory("res://data/items/", _items)
	_load_directory("res://data/skills/", _skills)
	for skill in _skills.values():
		skill.validate()
	for err in collect_validation_errors(_classes, _weapons, _items, _skills):
		push_error(err)
	for err in collect_map_registry_validation_errors(_MAP_REGISTRY_PATH, _classes, _items):
		push_error(err)


# Pure validator: returns the list of cross-reference errors as strings.
# Split out from _ready (B6) so tests can drive it with fixture data without
# capturing push_error. _ready loops over the result and emits each via
# push_error so bad data still surfaces in release builds (assert is stripped).
static func collect_validation_errors(classes: Dictionary, weapons: Dictionary,
		items: Dictionary, skills: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	_check_class_refs(classes, skills, errors)
	_check_skill_refs(skills, errors)
	_check_weapon_refs(weapons, errors)
	_check_item_refs(items, classes, errors)
	return errors


static func _check_class_refs(classes: Dictionary, skills: Dictionary, errors: Array[String]) -> void:
	for cls in classes.values():
		# Every skill a class auto-grants at level-up must reference a real skill.
		for level in cls.skill_unlocks:
			var skill_id: String = String(cls.skill_unlocks[level])
			if not skills.has(skill_id):
				errors.append("DataManager: class '%s' skill_unlocks[%s] '%s' not found" \
					% [cls.id, str(level), skill_id])
		# Growth tables and caps must carry every expected stat key so a missing
		# entry can't silently zero a stat at level-up.
		_check_stat_dict(cls, "player_growth_rates", cls.player_growth_rates, errors)
		_check_stat_dict(cls, "enemy_growth_rates", cls.enemy_growth_rates, errors)
		_check_stat_dict(cls, "stat_caps", cls.stat_caps, errors)
		_check_weapon_wexp_dict(cls.id, "weapon_wexp_bases", cls.weapon_wexp_bases, false, errors)
		_check_weapon_wexp_dict(cls.id, "weapon_wexp_caps", cls.weapon_wexp_caps, true, errors)
		if cls.internal_level_rule != "" and not (cls.internal_level_rule in GameConstants.VALID_INTERNAL_LEVEL_RULES):
			errors.append("DataManager: class '%s' internal_level_rule '%s' is not valid" % [
				cls.id, cls.internal_level_rule])
		if not (cls.class_availability in GameConstants.VALID_CLASS_AVAILABILITY):
			errors.append("DataManager: class '%s' class_availability '%s' is not valid" % [
				cls.id, cls.class_availability])
		for group in cls.vulnerability_groups:
			var group_id: String = String(group)
			if not (group_id in GameConstants.VALID_VULNERABILITY_GROUPS):
				errors.append("DataManager: class '%s' vulnerability_groups '%s' is not a known group" % [
					cls.id, group_id])
		for family in cls.allowed_weapon_families:
			var family_id: String = String(family)
			if not (family_id in GameConstants.VALID_COMBAT_FAMILIES):
				errors.append("DataManager: class '%s' allowed_weapon_families '%s' is not a known combat family" % [
					cls.id, family_id])
		for target_id in cls.promotes_to:
			if not classes.has(String(target_id)):
				errors.append("DataManager: class '%s' promotes_to '%s' not found" % [cls.id, String(target_id)])
		for source_id in cls.promotes_from:
			if not classes.has(String(source_id)):
				errors.append("DataManager: class '%s' promotes_from '%s' not found" % [cls.id, String(source_id)])


# Warns if a class stat dictionary is non-empty but missing expected stat keys.
# Empty {} is allowed (e.g. a class with no enemy variant) and skipped.
static func _check_stat_dict(cls, field: String, dict: Dictionary, errors: Array[String]) -> void:
	if dict.is_empty():
		return
	for key in ClassData.STAT_KEYS:
		if not dict.has(key):
			errors.append("DataManager: class '%s' %s missing stat key '%s'" % [cls.id, field, key])


static func _check_weapon_wexp_dict(owner_id: String, field: String, dict: Dictionary,
		require_positive: bool, errors: Array[String]) -> void:
	for key in dict.keys():
		var track: String = String(key)
		if not (track in GameConstants.VALID_WEXP_TRACKS):
			errors.append("DataManager: class '%s' %s key '%s' is not a known WEXP track" % [
				owner_id, field, track])
			continue
		var value: int = int(dict[key])
		if value < 0:
			errors.append("DataManager: class '%s' %s['%s'] cannot be negative" % [
				owner_id, field, track])
		elif require_positive and value == 0:
			errors.append("DataManager: class '%s' %s['%s'] must be > 0 when authored" % [
				owner_id, field, track])


static func _check_skill_refs(skills: Dictionary, errors: Array[String]) -> void:
	for skill in skills.values():
		if skill.activation_chance_stat != "":
			# Valid activation-chance stats = the growth stats, read from the single
			# StatRegistry vocabulary (was the local _VALID_STATS copy).
			if not StatRegistry.is_growth_stat(skill.activation_chance_stat):
				errors.append("DataManager: skill '%s' activation_chance_stat '%s' is not a known stat" \
					% [skill.id, skill.activation_chance_stat])
		# Skills whose effect_params name a combat family (faires, breakers) must
		# reference a real combat family so a typo like 'sord' fails loud.
		if skill.effect_params.has("weapon_type"):
			var skl_wt: String = String(skill.effect_params["weapon_type"])
			if not (skl_wt in GameConstants.VALID_COMBAT_FAMILIES):
				errors.append("DataManager: skill '%s' effect_params.weapon_type '%s' is not a known weapon type" \
					% [skill.id, skl_wt])


static func _check_weapon_refs(weapons: Dictionary, errors: Array[String]) -> void:
	# Catches typos like effective_armored vs effective_armoured (the literal-string
	# match in CombatResolver._is_effective would silently never fire on a typo).
	for weapon in weapons.values():
		if not (weapon.combat_family in GameConstants.VALID_COMBAT_FAMILIES):
			errors.append("DataManager: weapon '%s' combat_family '%s' is not a known combat family" \
				% [weapon.id, weapon.combat_family])
		if not (weapon.wexp_track in GameConstants.VALID_WEXP_TRACKS):
			errors.append("DataManager: weapon '%s' wexp_track '%s' is not a known WEXP track" \
				% [weapon.id, weapon.wexp_track])
		if weapon.required_rank not in GameConstants.WEXP_RANK_THRESHOLDS:
			errors.append("DataManager: weapon '%s' required_rank '%s' is not a known weapon rank" % [
				weapon.id, weapon.required_rank])
		if weapon.triangle_family != "" and not (weapon.triangle_family in GameConstants.VALID_COMBAT_FAMILIES):
			errors.append("DataManager: weapon '%s' triangle_family '%s' is not a known combat family" % [
				weapon.id, weapon.triangle_family])
		for tag in weapon.effect_tags:
			if not (tag in GameConstants.VALID_EFFECT_TAGS):
				errors.append("DataManager: weapon '%s' effect_tag '%s' is not a known tag" \
					% [weapon.id, tag])


static func _check_item_refs(items: Dictionary, classes: Dictionary, errors: Array[String]) -> void:
	# apply_item already push_warns and refuses to consume unknown effects at
	# runtime, but failing loud at boot beats discovering it the first time the
	# player drinks the item.
	var known_class_groups := _collect_class_groups(classes)
	for item in items.values():
		if not (item.effect_id in ItemHandlerScript.IMPLEMENTED_EFFECT_IDS):
			errors.append("DataManager: item '%s' effect_id '%s' is not implemented by ItemHandler" \
				% [item.id, item.effect_id])
		if item.effect_params.has("allowed_classes"):
			for class_id in item.effect_params["allowed_classes"]:
				if not classes.has(String(class_id)):
					errors.append("DataManager: item '%s' allowed_classes '%s' not found" % [
						item.id, String(class_id)])
		if item.effect_params.has("allowed_class_groups"):
			for group_id in item.effect_params["allowed_class_groups"]:
				if not known_class_groups.has(String(group_id)):
					errors.append("DataManager: item '%s' allowed_class_groups '%s' not found" % [
						item.id, String(group_id)])


static func _collect_class_groups(classes: Dictionary) -> Dictionary:
	var groups := {}
	for cls in classes.values():
		for group_id in cls.class_groups:
			groups[String(group_id)] = true
	return groups


static func collect_map_registry_validation_errors(registry_path: String,
		classes: Dictionary, items: Dictionary = {}) -> Array[String]:
	var errors: Array[String] = []
	if not FileAccess.file_exists(registry_path):
		errors.append("DataManager: map registry missing at %s" % registry_path)
		return errors
	var raw_text := FileAccess.get_file_as_string(registry_path)
	var parsed: Variant = JSON.parse_string(raw_text)
	if not (parsed is Array):
		errors.append("DataManager: map registry did not parse as an array at %s" % registry_path)
		return errors
	var seen_ids := {}
	var seen_paths := {}
	for i in parsed.size():
		var entry: Variant = parsed[i]
		if not (entry is Dictionary):
			errors.append("DataManager: map registry entry %d is not a Dictionary" % i)
			continue
		_validate_map_registry_entry(entry, i, seen_ids, seen_paths, classes, items, errors)
	return errors


static func _validate_map_registry_entry(entry: Dictionary, index: int, seen_ids: Dictionary,
		seen_paths: Dictionary, classes: Dictionary, items: Dictionary,
		errors: Array[String]) -> void:
	var entry_id: String = String(entry.get("id", ""))
	var label: String = String(entry.get("label", ""))
	var map_path: String = String(entry.get("map_data_path", ""))
	var roster_policy: String = String(entry.get("roster_policy", ""))
	var roster_source: String = String(entry.get("roster_source", ""))
	if entry_id == "":
		errors.append("DataManager: map registry entry %d is missing 'id'" % index)
	else:
		if seen_ids.has(entry_id):
			errors.append("DataManager: map registry duplicate id '%s'" % entry_id)
		else:
			seen_ids[entry_id] = true
	if label == "":
		errors.append("DataManager: map registry entry %d ('%s') is missing 'label'" % [index, entry_id])
	if map_path == "":
		errors.append("DataManager: map registry entry %d ('%s') is missing 'map_data_path'" % [index, entry_id])
	else:
		if seen_paths.has(map_path):
			errors.append("DataManager: map registry duplicate map_data_path '%s'" % map_path)
		else:
			seen_paths[map_path] = true
	if not (roster_policy in _VALID_ROSTER_POLICIES):
		errors.append("DataManager: map registry entry '%s' roster_policy '%s' is not valid" % [
			entry_id, roster_policy])
	# Cross-source unit_id uniqueness (code review 2026-06-10 issue 2.10).
	# Shared dedup table across the roster pass below and the enemy_placements
	# pass in collect_map_data_validation_errors; a duplicate unit_id between a
	# roster file and an enemy placement breaks find_unit_by_id and Pair Up
	# in silently confusing ways.
	var seen_unit_ids: Dictionary = {}
	if roster_policy == "fixed_test_roster":
		if roster_source == "":
			errors.append("DataManager: map registry entry '%s' fixed_test_roster is missing roster_source" % entry_id)
		else:
			var roster_paths: Array[String] = ResourceManifest.load_paths(roster_source)
			if roster_paths.is_empty():
				errors.append("DataManager: map registry entry '%s' roster_source '%s' does not load any roster units" % [
					entry_id, roster_source])
			else:
				var roster_units: Array = []
				for roster_path in roster_paths:
					var loaded := load(roster_path)
					if loaded == null:
						errors.append("DataManager: roster file '%s' failed to load for map '%s'" % [
							roster_path, entry_id])
						continue
					roster_units.append(loaded)
					if loaded is UnitData and String(loaded.unit_id) != "":
						var uid: String = String(loaded.unit_id)
						var here: String = "roster file '%s'" % roster_path
						if seen_unit_ids.has(uid):
							errors.append("DataManager: duplicate unit_id '%s' at %s (also at %s)" % [
								uid, here, seen_unit_ids[uid]])
						else:
							seen_unit_ids[uid] = here
				for err in collect_unit_validation_errors(roster_units, classes):
					errors.append(err)
	if roster_policy != "fixed_test_roster" and roster_source != "":
		errors.append("DataManager: map registry entry '%s' roster_source should be empty for roster_policy '%s'" % [
			entry_id, roster_policy])
	if map_path == "":
		return
	if not ResourceLoader.exists(map_path):
		errors.append("DataManager: map registry entry '%s' points at missing MapData '%s'" % [
			entry_id, map_path])
		return
	var loaded_map := load(map_path)
	if not (loaded_map is MapData):
		errors.append("DataManager: map registry entry '%s' path '%s' did not load as MapData" % [
			entry_id, map_path])
		return
	var map_data: MapData = loaded_map
	if entry_id != "" and map_data.id != "" and map_data.id != entry_id:
		errors.append("DataManager: map registry entry '%s' points at MapData id '%s'" % [
			entry_id, map_data.id])
	for err in collect_map_data_validation_errors(map_data, map_path, classes, items,
			seen_unit_ids):
		errors.append(err)


# `seen_unit_ids` is unit_id -> source description (e.g. "roster file '...'"
# or "enemy placement '...'"). Threaded in by collect_map_registry_validation
# _errors so the unit_ids loaded from the roster directory and the enemy_
# placements share a single dedup namespace. Defaults to a fresh dict for
# direct callers that don't have a cross-source view. Code review 2026-06-10
# issue 2.10.
static func collect_map_data_validation_errors(map_data: MapData, map_path: String,
		classes: Dictionary, items: Dictionary = {},
		seen_unit_ids: Dictionary = {}) -> Array[String]:
	var errors: Array[String] = []
	if map_data == null:
		errors.append("DataManager: map '%s' did not load" % map_path)
		return errors
	if map_data.id == "":
		errors.append("DataManager: map '%s' is missing MapData.id" % map_path)
	if map_data.display_name == "":
		errors.append("DataManager: map '%s' is missing display_name" % map_path)
	if map_data.tilemap_scene_path != "":
		if not ResourceLoader.exists(map_data.tilemap_scene_path):
			errors.append("DataManager: map '%s' tilemap_scene_path '%s' is missing" % [
				map_path, map_data.tilemap_scene_path])
		else:
			var tilemap_scene := load(map_data.tilemap_scene_path)
			if not (tilemap_scene is PackedScene):
				errors.append("DataManager: map '%s' tilemap_scene_path '%s' did not load as PackedScene" % [
					map_path, map_data.tilemap_scene_path])
	if map_data.player_start_tiles.is_empty():
		errors.append("DataManager: map '%s' has no player_start_tiles" % map_path)
	for reward_item in map_data.reward_items:
		var reward_item_id: String = String(reward_item)
		if reward_item_id == "":
			errors.append("DataManager: map '%s' reward_items contains an empty item id" % map_path)
		elif not items.is_empty() and not items.has(reward_item_id):
			errors.append("DataManager: map '%s' reward_items item '%s' not found" % [
				map_path, reward_item_id])
	var seen_player_tiles := {}
	for tile in map_data.player_start_tiles:
		var tile_key := "%d,%d" % [tile.x, tile.y]
		if seen_player_tiles.has(tile_key):
			errors.append("DataManager: map '%s' has duplicate player_start_tile %s" % [map_path, str(tile)])
		else:
			seen_player_tiles[tile_key] = true
	var width: int = 0
	var height: int = map_data.grid.size()
	if not map_data.grid.is_empty():
		width = map_data.grid[0].length()
		var valid_terrain := {".": true, "F": true, "M": true, "T": true, "S": true, "D": true, "W": true}
		for y in map_data.grid.size():
			var row: String = map_data.grid[y]
			if row.length() != width:
				errors.append("DataManager: map '%s' grid row %d length %d != %d" % [
					map_path, y, row.length(), width])
			for x in row.length():
				var ch: String = row[x]
				if not valid_terrain.has(ch):
					errors.append("DataManager: map '%s' grid row %d col %d has unknown terrain '%s'" % [
						map_path, y, x, ch])
		if map_data.camera_start_tile != Vector2i(-1, -1):
			if not _tile_is_inside_grid(map_data.camera_start_tile, width, height):
				errors.append("DataManager: map '%s' camera_start_tile %s is outside the grid" % [
					map_path, str(map_data.camera_start_tile)])
	for tile in map_data.player_start_tiles:
		if width > 0 and height > 0 and not _tile_is_inside_grid(tile, width, height):
			errors.append("DataManager: map '%s' player_start_tile %s is outside the grid" % [
				map_path, str(tile)])
	var faction_ids := {}
	var alliance_groups := {}
	for default_id in _DEFAULT_FACTION_IDS:
		faction_ids[default_id] = true
	for default_group in _DEFAULT_ALLIANCE_GROUP_IDS:
		alliance_groups[default_group] = true
	for faction in map_data.factions:
		if faction == null:
			errors.append("DataManager: map '%s' has a null faction entry" % map_path)
			continue
		if faction.id == "":
			errors.append("DataManager: map '%s' has a faction with empty id" % map_path)
			continue
		if faction_ids.has(faction.id):
			# allow default ids once, but not duplicates within the authored list
			var authored_dupes := 0
			for other in map_data.factions:
				if other != null and other.id == faction.id:
					authored_dupes += 1
			if authored_dupes > 1:
				errors.append("DataManager: map '%s' has duplicate faction id '%s'" % [map_path, faction.id])
		else:
			faction_ids[faction.id] = true
		if faction.alliance_group != "":
			alliance_groups[faction.alliance_group] = true
	if not (map_data.activation_mode in _VALID_ACTIVATION_MODES):
		errors.append("DataManager: map '%s' activation_mode '%s' is not valid" % [
			map_path, map_data.activation_mode])
	var seen_turn_ids := {}
	for faction_id in map_data.turn_order:
		if faction_id == "":
			errors.append("DataManager: map '%s' turn_order contains an empty faction id" % map_path)
			continue
		if seen_turn_ids.has(faction_id):
			errors.append("DataManager: map '%s' turn_order repeats faction '%s'" % [map_path, faction_id])
		else:
			seen_turn_ids[faction_id] = true
		if not faction_ids.has(faction_id):
			errors.append("DataManager: map '%s' turn_order references unknown faction '%s'" % [
				map_path, faction_id])
	var seen_enemy_tiles := {}
	for placement in map_data.enemy_placements:
		if not (placement is Dictionary):
			errors.append("DataManager: map '%s' has non-Dictionary enemy placement %s" % [
				map_path, str(placement)])
			continue
		var unit_path: String = String(placement.get("unit_data_path", ""))
		var inline_unit: Variant = placement.get("unit_data", null)
		var has_unit_path := unit_path != ""
		var has_inline_unit := inline_unit != null
		var unit_loaded: UnitData = null
		var unit_source := ""
		if has_unit_path == has_inline_unit:
			errors.append(
				"DataManager: map '%s' enemy placement must provide exactly one of unit_data_path or unit_data"
				% map_path)
		elif has_unit_path:
			unit_source = "enemy placement '%s'" % unit_path
			if not ResourceLoader.exists(unit_path):
				errors.append("DataManager: map '%s' enemy placement points at missing UnitData '%s'" % [
					map_path, unit_path])
			else:
				var unit_resource := load(unit_path)
				if not (unit_resource is UnitData):
					errors.append("DataManager: map '%s' enemy placement '%s' did not load as UnitData" % [
						map_path, unit_path])
				else:
					unit_loaded = unit_resource
		else:
			if not (inline_unit is UnitData):
				errors.append("DataManager: map '%s' enemy placement unit_data is not UnitData" % map_path)
			else:
				unit_loaded = inline_unit
				unit_source = "enemy placement inline unit_data"
		if unit_loaded != null:
			if String(unit_loaded.unit_id) == "":
				errors.append("DataManager: map '%s' %s has empty unit_id" % [
					map_path, unit_source])
			else:
				var uid: String = String(unit_loaded.unit_id)
				var here: String = unit_source
				if not has_unit_path:
					here = "%s '%s'" % [unit_source, uid]
				if seen_unit_ids.has(uid):
					errors.append("DataManager: duplicate unit_id '%s' at %s (also at %s)" % [
						uid, here, seen_unit_ids[uid]])
				else:
					seen_unit_ids[uid] = here
				for err in collect_unit_validation_errors([unit_loaded], classes):
					errors.append(err)
		if not placement.has("tile"):
			errors.append("DataManager: map '%s' has enemy placement missing tile" % map_path)
		else:
			var enemy_tile: Vector2i = placement.get("tile", Vector2i.ZERO)
			var tile_key := "%d,%d" % [enemy_tile.x, enemy_tile.y]
			if seen_enemy_tiles.has(tile_key):
				errors.append("DataManager: map '%s' has duplicate enemy placement tile %s" % [
					map_path, str(enemy_tile)])
			else:
				seen_enemy_tiles[tile_key] = true
		var placement_faction: String = String(placement.get("faction", "red"))
		if placement_faction == "":
			errors.append("DataManager: map '%s' has enemy placement with empty faction id" % map_path)
		elif not faction_ids.has(placement_faction):
			errors.append("DataManager: map '%s' enemy placement references unknown faction '%s'" % [
				map_path, placement_faction])
		var ai_profile: String = String(placement.get("ai_profile", "basic"))
		if not AIProfileRegistry.is_valid_profile(ai_profile):
			errors.append("DataManager: map '%s' enemy placement ai_profile '%s' is not valid" % [
				map_path, ai_profile])
		if placement.has("tile"):
			var enemy_tile: Vector2i = placement.get("tile", Vector2i.ZERO)
			if width > 0 and height > 0 and not _tile_is_inside_grid(enemy_tile, width, height):
				errors.append("DataManager: map '%s' enemy placement tile %s is outside the grid" % [
					map_path, str(enemy_tile)])
	_validate_condition_dict(map_data.victory_conditions, "victory_conditions", map_path,
		faction_ids, alliance_groups, width, height, errors)
	_validate_condition_dict(map_data.defeat_conditions, "defeat_conditions", map_path,
		faction_ids, alliance_groups, width, height, errors)
	return errors


static func _validate_condition_dict(cond_dict: Dictionary, field_name: String, map_path: String,
		faction_ids: Dictionary, alliance_groups: Dictionary, width: int, height: int,
		errors: Array[String]) -> void:
	for group_id in cond_dict.keys():
		var group_name: String = String(group_id)
		if group_name == "":
			errors.append("DataManager: map '%s' %s has an empty group id" % [map_path, field_name])
		elif not alliance_groups.has(group_name):
			errors.append("DataManager: map '%s' %s references unknown alliance group '%s'" % [
				map_path, field_name, group_name])
		var conds: Variant = cond_dict[group_id]
		if not (conds is Array):
			errors.append("DataManager: map '%s' %s['%s'] is not an Array" % [
				map_path, field_name, group_name])
			continue
		for i in conds.size():
			var cond: Variant = conds[i]
			if not (cond is ObjectiveCondition):
				errors.append("DataManager: map '%s' %s['%s'][%d] is not an ObjectiveCondition" % [
					map_path, field_name, group_name, i])
				continue
			_validate_objective_condition(
				cond, map_path, field_name, group_name, faction_ids, alliance_groups,
				width, height, errors)


static func _validate_objective_condition(cond: ObjectiveCondition, map_path: String,
		field_name: String, group_name: String, faction_ids: Dictionary,
		alliance_groups: Dictionary, width: int, height: int,
		errors: Array[String]) -> void:
	if not (cond.type in _VALID_OBJECTIVE_TYPES):
		errors.append("DataManager: map '%s' %s['%s'] has invalid ObjectiveCondition.type '%s'" % [
			map_path, field_name, group_name, cond.type])
		return
	if cond.type == "rout" and cond.faction_id != "" \
			and not faction_ids.has(cond.faction_id) and not alliance_groups.has(cond.faction_id):
		errors.append("DataManager: map '%s' rout condition references unknown faction/group '%s'" % [
			map_path, cond.faction_id])
	if cond.type in ["defeat_boss", "protect", "escape"] and cond.unit_ids.is_empty():
		errors.append("DataManager: map '%s' %s condition in group '%s' requires unit_ids" % [
			map_path, cond.type, group_name])
	if cond.type == "seize":
		if cond.tile == Vector2i(-1, -1):
			errors.append("DataManager: map '%s' seize condition in group '%s' is missing tile" % [
				map_path, group_name])
		elif width > 0 and height > 0 and not _tile_is_inside_grid(cond.tile, width, height):
			errors.append("DataManager: map '%s' seize condition in group '%s' tile %s is outside the grid" % [
				map_path, group_name, str(cond.tile)])
	if cond.type == "escape" and cond.tiles.is_empty():
		errors.append("DataManager: map '%s' escape condition in group '%s' requires tiles" % [
			map_path, group_name])
	for tile in cond.tiles:
		if width > 0 and height > 0 and not _tile_is_inside_grid(tile, width, height):
			errors.append("DataManager: map '%s' %s condition in group '%s' tile %s is outside the grid" % [
				map_path, cond.type, group_name, str(tile)])
	if cond.type == "survive" and cond.turns <= 0:
		errors.append("DataManager: map '%s' survive condition in group '%s' requires turns > 0" % [
			map_path, group_name])


static func _tile_is_inside_grid(tile: Vector2i, width: int, height: int) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < width and tile.y < height


# Result codes returned by register_loaded_resource. Was a free-form String
# error previously, which forced _load_directory to switch severity via a
# substring search on the message — fragile across rewordings (code review
# 2026-06-09). Keeping the message in the return alongside the code so callers
# that want to surface it still can.
enum LoadResult { OK, MISSING_ID, DUPLICATE_ID, LOAD_FAILED }


static func register_loaded_resource(target: Dictionary, res: Resource, res_path: String) -> Dictionary:
	if res == null:
		return {"result": LoadResult.LOAD_FAILED,
			"message": "DataManager: resource at %s failed to load" % res_path}
	var rid: Variant = res.get("id")
	if rid == null or rid == "":
		return {"result": LoadResult.MISSING_ID,
			"message": "DataManager: resource at %s has no 'id' field" % res_path}
	var id: String = String(rid)
	if target.has(id):
		return {"result": LoadResult.DUPLICATE_ID,
			"message": "DataManager: duplicate resource id '%s' at %s" % [id, res_path]}
	target[id] = res
	return {"result": LoadResult.OK, "message": ""}


func _load_directory(path: String, target: Dictionary) -> void:
	var resource_paths: Array[String] = ResourceManifest.load_paths(path)
	if resource_paths.is_empty():
		push_error("DataManager: cannot open directory: " + path)
		return
	for res_path in resource_paths:
		var res := load(res_path)
		var r: Dictionary = register_loaded_resource(target, res, res_path)
		# Duplicate ids and load failures must fail loud — they leave a wrong
		# resource resolved (or none at all) at runtime. Missing-id is a soft
		# data-authoring warning: the resource is skipped, not silently aliased.
		match r["result"]:
			LoadResult.OK:
				continue
			LoadResult.DUPLICATE_ID, LoadResult.LOAD_FAILED:
				push_error(r["message"])
			_:
				push_warning(r["message"])


# Named get_class_data (not get_class) to avoid conflict with Object.get_class() -> String
func get_class_data(id: String) -> ClassData:
	if not _classes.has(id):
		push_error("DataManager: unknown class id '%s'" % id)
		return null
	return _classes[id]


func get_all_classes() -> Dictionary:
	return _classes


func validate_unit_data(unit: UnitData) -> Array[String]:
	return collect_unit_validation_errors([unit], _classes)


func get_weapon(id: String) -> WeaponData:
	if not _weapons.has(id):
		push_error("DataManager: unknown weapon id '%s'" % id)
		return null
	return _weapons[id]


func has_weapon(id: String) -> bool:
	return _weapons.has(id)


func get_item(id: String) -> ItemData:
	if not _items.has(id):
		push_error("DataManager: unknown item id '%s'" % id)
		return null
	return _items[id]


func has_item(id: String) -> bool:
	return _items.has(id)


func get_skill(id: String) -> SkillData:
	if not _skills.has(id):
		push_error("DataManager: unknown skill id '%s'" % id)
		return null
	return _skills[id]


# Returns "advantage", "disadvantage", or "neutral"
func get_weapon_triangle_result(attacker_type: String, defender_type: String) -> String:
	if GameConstants.WEAPON_TRIANGLE.has(attacker_type):
		var row: Dictionary = GameConstants.WEAPON_TRIANGLE[attacker_type]
		if row.has(defender_type):
			return row[defender_type]
	return "neutral"


static func collect_unit_validation_errors(units: Array, classes: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for unit in units:
		if unit == null:
			continue
		if unit.class_id != "" and not classes.has(unit.class_id):
			errors.append("DataManager: unit '%s' class_id '%s' not found" % [
				unit.unit_id, unit.class_id])
		if unit.internal_level < 1:
			errors.append("DataManager: unit '%s' internal_level must be >= 1" % [
				unit.unit_id])
		# HP / max_hp / level invariants (code review 2026-06-10 issue 2.7).
		# Mirrors GameState._validate_snapshot_unit_dict so authoring caught here
		# at boot matches what the snapshot restore would reject at runtime.
		if unit.level < 1:
			errors.append("DataManager: unit '%s' level must be >= 1" % unit.unit_id)
		if unit.max_hp < 1:
			errors.append("DataManager: unit '%s' max_hp must be >= 1" % unit.unit_id)
		if unit.hp < 0:
			errors.append("DataManager: unit '%s' hp cannot be negative (%d)" % [
				unit.unit_id, unit.hp])
		elif unit.max_hp >= 1 and unit.hp > unit.max_hp:
			errors.append("DataManager: unit '%s' hp %d exceeds max_hp %d" % [
				unit.unit_id, unit.hp, unit.max_hp])
		if unit.class_line_id != "":
			if not classes.has(unit.class_line_id):
				errors.append("DataManager: unit '%s' class_line_id '%s' not found" % [
					unit.unit_id, unit.class_line_id])
			else:
				var line_class: ClassData = classes[unit.class_line_id]
				if line_class.tier != 1:
					errors.append("DataManager: unit '%s' class_line_id '%s' must point to a tier-1 class" % [
						unit.unit_id, unit.class_line_id])
		for option_id in unit.reclass_options:
			if not classes.has(String(option_id)):
				errors.append("DataManager: unit '%s' reclass_options '%s' not found" % [
					unit.unit_id, String(option_id)])
				continue
			var option_class: ClassData = classes[String(option_id)]
			if option_class.tier != 1:
				errors.append("DataManager: unit '%s' reclass_options '%s' must point to a tier-1 class" % [
					unit.unit_id, String(option_id)])
		for track in unit.weapon_wexp.keys():
			var track_id: String = String(track)
			if not (track_id in GameConstants.VALID_WEXP_TRACKS):
				errors.append("DataManager: unit '%s' weapon_wexp key '%s' is not a known WEXP track" % [
					unit.unit_id, track_id])
				continue
			if int(unit.weapon_wexp[track]) < 0:
				errors.append("DataManager: unit '%s' weapon_wexp['%s'] cannot be negative" % [
					unit.unit_id, track_id])
		if not AIProfileRegistry.is_valid_profile(unit.ai_profile):
			errors.append("DataManager: unit '%s' ai_profile '%s' is not valid" % [
				unit.unit_id, unit.ai_profile])
	return errors
