extends Node
# [NOTE — M-1] class_name conflicts with the autoload singleton name in Godot 4.
# Loads all content resources at startup. All game systems query this singleton
# rather than loading resources on demand, so load errors surface immediately.

const ItemEffectRegistryScript = preload("res://scripts/registries/ItemEffectRegistry.gd")
const ObjectiveConditionRegistryScript = preload(
	"res://scripts/registries/ObjectiveConditionRegistry.gd"
)
const ResourceManifest = preload("res://scripts/shared/ResourceManifest.gd")
# Preloaded rather than used as the autoload, because the consts below are resolved
# at parse time and autoloads are not live then (see GameConstants' own header).
const GameConstantsScript = preload("res://scripts/shared/GameConstants.gd")
# AI profiles are validated against the open AIProfileRegistry (the composition
# engine seam) rather than a closed const — adding a profile no longer needs a
# DataManager edit. See AIProfileRegistry.gd.
const AIProfileRegistry = preload("res://scripts/core/AIProfileRegistry.gd")
const StatRegistry = preload("res://scripts/core/StatRegistry.gd")
const CampaignTier2RuntimeAdapter = preload(
	"res://scripts/resources/CampaignTier2RuntimeAdapter.gd"
)
const CampaignPackRegistry = preload("res://scripts/resources/CampaignPackRegistry.gd")
const ContentSessionScript = preload("res://scripts/resources/ContentSession.gd")
const DEFAULT_CONTENT_SOURCE := "res://data"
const COMPATIBILITY_SETTING := "prometheus/content/activate_project_data_compatibility"
enum ContentState { INACTIVE, COMPATIBILITY, PACKAGE }
# Pair Up bonus table lives with PairUpBonusResolver at runtime, but its stat-name
# references ([STM-5]) are validated here at boot alongside the other content so a
# typo'd scaling/bonus stat fails loud instead of contributing a silent 0.
const _VALID_ROSTER_POLICIES := ["default_roster", "fixed_test_roster", "keep_current_roster"]
# Single source lives in GameConstants so the Tier-2 map schema admits exactly the
# list this validator enforces.
const _VALID_ACTIVATION_MODES := GameConstantsScript.VALID_ACTIVATION_MODES
const _DEFAULT_FACTION_IDS := ["blue", "green", "red", "yellow"]
const _DEFAULT_ALLIANCE_GROUP_IDS := ["allies", "foes", "rogues"]

var _classes: Dictionary = {}
var _weapons: Dictionary = {}
var _items: Dictionary = {}
var _skills: Dictionary = {}
var _pair_up_bonus_table: Resource = null
# Campaign progression graphs, keyed by campaign_id. Authored as JSON (not .tres)
# per [CST-3], so they load through their own directory pass rather than
# _load_directory's resource loader.
var _campaigns: Dictionary = {}
# Immutable discovery snapshot of the shipped campaigns. New Game must be able
# to list these while an installed package owns the live runtime catalogue.
var _shipped_campaigns: Dictionary = {}

# Map registry entries keyed by map_registry id. Campaign nodes bind by map id,
# so the campaign runtime resolves a node's launch parameters through this cache.
var _map_registry: Dictionary = {}
var _battle_maps: Dictionary = {}
var _battle_encounters: Dictionary = {}
var _pack_maps: Dictionary = {}
var _pack_rosters: Dictionary = {}
# Terrain definitions the active content plays with. Unlike the other catalogues this
# is never empty: the engine can always paint its own terrain, and a pack's `terrain`
# documents retune that set, and since [TER-2] (2026-08-01) may also introduce terrain
# of their own, whose art is built from pack media at activation. Inactive content
# therefore means "engine defaults", not "no terrain", which is why _clear_content
# resets it rather than clearing it.
var _terrain: TerrainRegistry = TerrainRegistry.engine_defaults()
# Resolved pack media, needed by the renderer to build tile sources for introduced
# terrain and decorative variants. Empty whenever no pack is active.
var _assets: Dictionary = {}
var _active_package_id := ""
var _active_package_version := ""
var _active_package_path := ""
var _content_state: ContentState = ContentState.INACTIVE
# Why the active content could NOT be committed. `_commit_session` clears it, so a
# non-empty list always means "activation failed" — the contract a caller rendering
# a blocking failure list depends on. That is why an unresolved id, which leaves the
# content playable, belongs in `_content_warnings` below instead.
var _activation_errors: Array[String] = []
# Content-authoring facts about the content that IS live: true but not fatal. Filled
# at activation and, for a path no validator walks, on the first lookup that misses.
# Scoped to one activation: `_commit_session` empties it, so the committed session
# never inherits the previous one's gaps.
var _content_warnings: Array[String] = []
# Ids already reported through `_content_warnings`, as "<kind>:<id>". V070-11: one
# authored typo used to cost one push_error per LOOKUP — `get_skill` is called per
# unit, per skill, per trigger, per phase, so a single missing id produced ~3,200
# identical ERROR: lines in one returned session. The fact is worth reporting once;
# its cardinality was the defect.
var _reported_unknown_ids: Dictionary = {}

# Weapon triangle lives in GameConstants.WEAPON_TRIANGLE — single source of truth.


func _ready() -> void:
	_clear_content()
	if bool(ProjectSettings.get_setting(COMPATIBILITY_SETTING, false)):
		activate_project_data_compatibility()


# Content sources are self-contained data roots. Keeping path construction here
# makes the future campaign-pack switch a replace-load instead of a merge.
func _load_all(source: String = DEFAULT_CONTENT_SOURCE) -> void:
	_load_directory(source.path_join("classes"), _classes)
	_load_directory(source.path_join("weapons"), _weapons)
	_load_directory(source.path_join("items"), _items)
	_load_directory(source.path_join("skills"), _skills)
	var pair_up_path := source.path_join("pair_up/pair_up_bonus_table.tres")
	if ResourceLoader.exists(pair_up_path):
		_pair_up_bonus_table = load(pair_up_path)
	_load_campaign_directory(source.path_join("campaigns"))
	# Cached so campaign node -> map launches resolve through the catalogue
	# instead of each caller re-reading map_registry.json from disk.
	_load_map_registry(source.path_join("maps/map_registry.json"))
	_load_battle_catalogues(source.path_join("maps"))
	_register_single_map_campaigns()


func _clear_content() -> void:
	_classes.clear()
	_weapons.clear()
	_items.clear()
	_skills.clear()
	_pair_up_bonus_table = null
	_campaigns.clear()
	_map_registry.clear()
	_battle_maps.clear()
	_battle_encounters.clear()
	_pack_maps.clear()
	_pack_rosters.clear()
	_terrain = TerrainRegistry.engine_defaults()
	_assets.clear()
	_active_package_id = ""
	_active_package_version = ""
	_active_package_path = ""
	_content_state = ContentState.INACTIVE
	_content_warnings.clear()
	_reported_unknown_ids.clear()
	_sync_pair_up_bonus_resolver()


func _commit_session(session: ContentSession) -> void:
	_classes = session.classes
	_weapons = session.weapons
	_items = session.items
	_skills = session.skills
	_pair_up_bonus_table = session.pair_up_bonus_table
	_campaigns = session.campaigns
	_map_registry = session.map_registry
	_battle_maps = session.battle_maps
	_battle_encounters = session.battle_encounters
	_pack_maps = session.pack_maps
	_pack_rosters = session.pack_rosters
	_terrain = session.terrain
	_assets = session.assets
	_active_package_id = session.package_id
	_active_package_version = session.package_version
	_active_package_path = session.package_path
	_content_state = (
		ContentState.COMPATIBILITY if session.compatibility_source else ContentState.PACKAGE
	)
	_activation_errors.clear()
	# Warnings are scoped to one activation: the committed session gets a fresh
	# list, so a previous session's authoring gaps can never be read as this one's.
	_content_warnings.clear()
	_reported_unknown_ids.clear()
	_sync_pair_up_bonus_resolver()


func _sync_pair_up_bonus_resolver() -> void:
	if not is_inside_tree():
		return
	var resolver := get_node_or_null("/root/PairUpBonusResolver")
	if resolver != null and resolver.has_method("load_table"):
		resolver.load_table(_pair_up_bonus_table)


func _session_from_loaded_manager(candidate: Node, source: String) -> ContentSession:
	var session := ContentSessionScript.new()
	session.classes = candidate._classes
	session.weapons = candidate._weapons
	session.items = candidate._items
	session.skills = candidate._skills
	session.pair_up_bonus_table = candidate._pair_up_bonus_table
	session.campaigns = candidate._campaigns
	session.map_registry = candidate._map_registry
	session.battle_maps = candidate._battle_maps
	session.battle_encounters = candidate._battle_encounters
	session.package_path = source.trim_suffix("/")
	session.compatibility_source = true
	return session


# Runs the complete validation composition for one loaded source. SkillData's
# missing-field diagnostics remain warnings; hard cross-reference failures are
# collected and reported through the single error channel below.
func _validate_all(source: String = DEFAULT_CONTENT_SOURCE) -> Array[String]:
	for skill in _skills.values():
		skill.validate()
	var registry_path := source.path_join("maps/map_registry.json")
	var errors := collect_validation_errors(_classes, _weapons, _items, _skills)
	errors.append_array(collect_map_registry_validation_errors(registry_path, _classes, _items))
	errors.append_array(
		collect_battle_catalogue_validation_errors(
			_battle_maps, _battle_encounters, _classes, _items
		)
	)
	errors.append_array(
		collect_pair_up_validation_errors(source.path_join("pair_up/pair_up_bonus_table.tres"))
	)
	# Campaign nodes bind to map_registry ids, so campaigns are cross-checked
	# against the registry's id vocabulary once the registry itself is validated.
	errors.append_array(
		collect_campaign_validation_errors(
			_campaigns, collect_map_registry_ids(registry_path), _battle_encounters
		)
	)
	return errors


func _report(errors: Array[String]) -> void:
	for err in errors:
		push_error(err)


# Records an unresolved id ONCE per activation, wherever it is first noticed — the
# activation pass below, or a lookup on a path no validator walks. Later sightings of
# the same id are dropped, which is the whole of the V070-11 fix: the getters still
# return null and their callers still null-check, so behaviour is unchanged.
#
# It is a WARNING, not an error: the content is live and playable, and an unresolved
# id leaves one skill or item inert. Spending an ERROR: line on a survivable
# authoring gap is what taught the v0.7.0 triage pass to skim past ERROR: lines.
func _report_unknown_id(kind: String, id: String, context: String = "") -> void:
	var key := "%s:%s" % [kind, id]
	if _reported_unknown_ids.has(key):
		return
	_reported_unknown_ids[key] = true
	var message := "DataManager: unknown %s id '%s'" % [kind, id]
	if context != "":
		message += " (%s)" % context
	_content_warnings.append(message)
	push_warning(message)


# The activation-time coverage V070-11 exposed as missing. `_check_class_refs` walks
# `ClassData.skill_unlocks`, but NOTHING walked a unit's own skill arrays — and those
# are exactly what `SkillHandler` resolves per unit, per skill, per trigger, per
# phase. Reporting them here means the fact is on the record before any combat runs,
# instead of arriving as the first of thousands of identical lines mid-battle.
#
# Deliberately NOT fatal, and deliberately not part of `collect_validation_errors`:
# an unresolved skill is inert, not unplayable, and a Tier-2 pack carries no skills
# catalogue at all yet (that family is still unregistered in the zero-content schema
# work), so refusing activation over one would make every pack unlaunchable.
func _report_unresolved_unit_skills(units: Array) -> void:
	for unit in units:
		if not (unit is UnitData):
			continue
		var referenced: Array[String] = []
		referenced.append_array(unit.skills)
		referenced.append_array(unit.earned_skills)
		referenced.append_array(unit.mastery_skills)
		for raw_id in referenced:
			var skill_id := String(raw_id)
			if skill_id == "" or _skills.has(skill_id):
				continue
			_report_unknown_id("skill", skill_id, "referenced by unit '%s'" % unit.unit_id)


# The units the committed pack carries: its rosters plus the enemies standing on its
# maps. Both hold real UnitData by the time the session is committed, so no reload is
# needed. Placements are dictionaries and may carry a path instead of an inline unit
# (`MapData.enemy_placements`), so only inline units are read — a pack's placements
# are always inline, and the map validator has already rejected any that are not.
func _committed_pack_units() -> Array:
	var units: Array = []
	for roster_id in _pack_rosters:
		units.append_array(_pack_rosters[roster_id])
	for map_id in _pack_maps:
		var map_data: MapData = _pack_maps[map_id]
		if map_data == null:
			continue
		for placement in map_data.enemy_placements:
			if placement is Dictionary and placement.get("unit_data", null) is UnitData:
				units.append(placement["unit_data"])
	return units


# Loads one roster directory's UnitData for reporting only. Bad entries are skipped
# silently here: whether they are an error is `collect_unit_validation_errors`'s call,
# and this pass must not become a second, weaker opinion about roster validity.
func _load_roster_units(roster_path: String) -> Array:
	var units: Array = []
	for path in ResourceManifest.load_paths(roster_path):
		if not ResourceLoader.exists(path):
			continue
		var loaded := load(path)
		if loaded is UnitData:
			units.append(loaded)
	return units


# Inert until campaign selection is wired. Callers provide a complete content
# root; old catalogues are cleared before the replacement source is loaded.
func select_campaign_source(source: String) -> bool:
	return activate_project_data_compatibility(source)


# Temporary extraction bridge. It is explicit, setting-gated at boot, and uses
# the same candidate/commit rule as package activation; Slice 4 removes it.
func activate_project_data_compatibility(source: String = DEFAULT_CONTENT_SOURCE) -> bool:
	var candidate: Node = get_script().new()
	candidate._clear_content()
	candidate._load_all(source)
	var errors: Array[String] = candidate._validate_all(source)
	var registry_manager := get_node_or_null("/root/RegistryManager") if is_inside_tree() else null
	if registry_manager == null:
		errors.append("DataManager: RegistryManager is unavailable")
	else:
		var registry_candidate: Dictionary = registry_manager.call("build_candidate", source)
		errors.append_array(registry_candidate.get("errors", []))
		if errors.is_empty():
			registry_manager.call("commit_candidate", registry_candidate)
	if not errors.is_empty():
		_activation_errors = errors
		_report(errors)
		candidate.free()
		return false
	_commit_session(_session_from_loaded_manager(candidate, source))
	_shipped_campaigns = _duplicate_campaigns(_campaigns)
	# Runs after the commit because it reports on the content that is now live, and
	# never changes whether it went live. Project data's units live on disk rather
	# than in a catalogue, so only the roster this source actually deploys is walked;
	# a unit reached by any other route is still reported by its first lookup.
	_report_unresolved_unit_skills(_load_roster_units(source.path_join("roster/default")))
	candidate.free()
	return true


# Activates a validated Tier-2 JSON source atomically. The adapter builds a
# complete replacement set before live registries are cleared, so a malformed
# pack cannot strand the previously selected campaign content.
func select_tier2_campaign_source(
	source: String, package_id: String, package_version: String
) -> bool:
	var adapted = CampaignTier2RuntimeAdapter.load(source, package_id, package_version)
	if not adapted.valid:
		_activation_errors = adapted.errors.duplicate()
		_report(adapted.errors)
		return false
	# Document shape is the entity-schema pass's job; map SEMANTICS — tile bounds,
	# terrain codes, faction/turn-order coherence, duplicate tiles, objective groups —
	# already have exactly one owner in collect_map_data_validation_errors. Running it
	# here means a Tier-2 pack is held to the same rules as project data instead of a
	# second, weaker copy of them. It runs before _commit_session, so activation stays
	# atomic and a bad map cannot strand the previously selected content.
	#
	# Terrain is resolved BEFORE the maps are checked: a pack may retune which char
	# means which terrain, so validating its grids against the engine char set would
	# reject rows the pack itself authored correctly.
	var candidate_terrain: TerrainRegistry = TerrainRegistry.engine_defaults()
	var terrain_errors: Array[String] = []
	for terrain_id in adapted.terrain:
		terrain_errors.append_array(candidate_terrain.apply_document(adapted.terrain[terrain_id]))
	# Variants are applied after every terrain, so a variant may share a terrain the
	# same pack introduced regardless of document order ([TER-1]).
	for variant_id in adapted.terrain_variants:
		terrain_errors.append_array(
			candidate_terrain.apply_variant_document(adapted.terrain_variants[variant_id])
		)
	terrain_errors.append_array(candidate_terrain.collect_coherence_errors())
	if not terrain_errors.is_empty():
		_activation_errors = terrain_errors.duplicate()
		_report(terrain_errors)
		return false
	var map_errors: Array[String] = []
	# Unit-id uniqueness is scoped to ONE PLAYABLE BATTLE — the roster that deploys
	# onto a map plus the enemies standing on it — which is exactly how the
	# project-data path scopes it (per map registry entry, in
	# _collect_map_registry_entry_errors). One table shared across every map in the
	# pack instead forbade two maps re-using an enemy archetype id: legal authoring
	# that the engine's own content does (the rout map and its faction demo share all
	# eight enemies) and that no runtime rule needs, because only one map is ever
	# loaded. It surfaced the moment a pack carried more than one encounter.
	for map_id in adapted.maps:
		var seen_unit_ids := _roster_unit_ids_for_map(adapted, String(map_id))
		map_errors.append_array(
			collect_map_data_validation_errors(
				adapted.maps[map_id],
				"campaign-pack:%s" % map_id,
				adapted.classes,
				adapted.items,
				seen_unit_ids,
				candidate_terrain
			)
		)
	if not map_errors.is_empty():
		_activation_errors = map_errors.duplicate()
		_report(map_errors)
		return false
	var session := ContentSessionScript.new()
	session.terrain = candidate_terrain
	session.assets = adapted.assets
	session.classes = adapted.classes
	session.weapons = adapted.weapons
	session.items = adapted.items
	session.skills = adapted.skills
	session.pair_up_bonus_table = adapted.pair_up_bonus_table
	session.campaigns = adapted.campaigns
	session.map_registry = adapted.map_registry
	session.pack_maps = adapted.maps
	session.pack_rosters = adapted.rosters
	session.package_id = adapted.package_id
	session.package_version = adapted.package_version
	session.package_path = source.trim_suffix("/")
	var validation_errors := collect_validation_errors(
		session.classes, session.weapons, session.items, session.skills
	)
	if not validation_errors.is_empty():
		_activation_errors = validation_errors.duplicate()
		_report(validation_errors)
		return false
	var registry_manager := get_node_or_null("/root/RegistryManager") if is_inside_tree() else null
	if registry_manager != null and not registry_manager.call("activate_engine_baseline"):
		_activation_errors = registry_manager.call("load_errors")
		_report(_activation_errors)
		return false
	_commit_session(session)
	_register_single_map_campaigns()
	# Every unit the pack carries — the rosters it deploys and the enemies standing on
	# its maps — is in memory here, so a pack's unresolved skill ids are all on the
	# record at activation. A pack ships no skills catalogue yet, so today this is
	# where an authored skill id is reported at all.
	_report_unresolved_unit_skills(_committed_pack_units())
	return true


# The terrain definitions the active content plays with. `TerrainRegistry.active()`
# resolves through this, so runtime (GridManager, GameMap, TurnManager) and the HUD
# all read the pack's numbers once it is activated.
func terrain_registry() -> TerrainRegistry:
	return _terrain


func pair_up_bonus_table() -> Resource:
	return _pair_up_bonus_table


# Resolved media for the active pack: logical asset id -> {path, decoded_type}.
# `TerrainTileSetBuilder` reads it to build tile sources for pack-introduced terrain
# and decorative variants; empty means "no pack", and only engine sources are used.
func pack_assets() -> Dictionary:
	return _assets


# Seeds the unit-id table for one map with the units that deploy onto it: every
# roster a map_registry row binds to that map. A roster unit colliding with an enemy
# on the map it deploys onto breaks find_unit_by_id and Pair Up in silently confusing
# ways (code review 2026-06-10 issue 2.10), which is what this seeding catches.
#
# Collisions BETWEEN two rosters are deliberately not reported while building the
# seed: two rosters may share a unit id because only one of them is ever deployed.
static func _roster_unit_ids_for_map(adapted, map_id: String) -> Dictionary:
	var seen := {}
	for entry_id in adapted.map_registry:
		var row: Dictionary = adapted.map_registry[entry_id]
		if String(row.get("map_data_path", "")).get_file() != map_id:
			continue
		var roster_id := String(row.get("roster_source", ""))
		for unit in adapted.rosters.get(roster_id, []):
			if unit != null and String(unit.unit_id) != "":
				seen[String(unit.unit_id)] = "pack roster '%s'" % roster_id
	return seen


func activate_campaign_package(source: String, package_id: String, package_version: String) -> bool:
	return select_tier2_campaign_source(source, package_id, package_version)


func deactivate_campaign_package() -> void:
	_clear_content()
	_shipped_campaigns.clear()
	_activation_errors.clear()
	var registry_manager := get_node_or_null("/root/RegistryManager") if is_inside_tree() else null
	if registry_manager != null:
		registry_manager.call("deactivate")


func content_state() -> ContentState:
	return _content_state


func has_playable_content() -> bool:
	return not _campaigns.is_empty()


# "errors" is why activation FAILED and is empty whenever content is live;
# "warnings" is what is authored-but-unresolved in the content that IS live. The
# two are separate keys because a caller that renders them together would either
# block on a survivable gap or bury a fatal one.
func content_status() -> Dictionary:
	return {
		"state": _content_state,
		"playable": has_playable_content(),
		"package": active_package_identity(),
		"errors": _activation_errors.duplicate(),
		"warnings": _content_warnings.duplicate(),
	}


func get_campaign_ids() -> Array[String]:
	var result: Array[String] = []
	for id in _campaigns.keys():
		result.append(String(id))
	result.sort()
	return result


func active_package_identity() -> Dictionary:
	return {
		"package_id": _active_package_id,
		"package_version": _active_package_version,
		"path": _active_package_path,
	}


# Selects the content catalogue named by durable save identity. Paths never come
# from save data: installed packages resolve through the service-owned root.
func select_saved_campaign_source(package_id: String, package_version: String) -> bool:
	if package_id.is_empty() != package_version.is_empty():
		push_error("DataManager: saved campaign package identity is incomplete")
		return false
	if package_id.is_empty():
		return select_campaign_source(DEFAULT_CONTENT_SOURCE)
	var path := CampaignPackRegistry.installed_path(
		CampaignPackRegistry.DEFAULT_STORAGE_ROOT, package_id, package_version
	)
	return select_tier2_campaign_source(path, package_id, package_version)


func resolve_map_data(source_id: String) -> MapData:
	if source_id.begins_with(CampaignTier2RuntimeAdapter.MAP_SCHEME):
		var map_id := source_id.get_file()
		if _pack_maps.has(map_id):
			return _pack_maps[map_id]
		push_error("DataManager: Tier-2 source names unknown map '%s'" % map_id)
		return null
	if ResourceLoader.exists(source_id):
		var loaded: Variant = load(source_id)
		return loaded as MapData
	return null


# The sole split/legacy composition boundary. Gameplay receives the same typed
# bundle whichever authoring route selected the battle.
func resolve_battle_source(source_id: String) -> ResolvedBattleData:
	if _battle_encounters.has(source_id):
		var encounter: BattleEncounterDef = _battle_encounters[source_id]
		var map_def: BattleMapDef = _battle_maps.get(encounter.battle_map_id)
		if map_def == null:
			push_error(
				(
					"DataManager: encounter '%s' references unknown battle map '%s'"
					% [source_id, encounter.battle_map_id]
				)
			)
			return null
		return ResolvedBattleData.from_split(map_def, encounter, source_id)
	var legacy := resolve_map_data(source_id)
	if legacy != null:
		return ResolvedBattleData.from_legacy(legacy, source_id)
	push_error("DataManager: unknown battle source '%s'" % source_id)
	return null


func has_battle_encounter(encounter_id: String) -> bool:
	return _battle_encounters.has(encounter_id)


func get_battle_encounter_entry(encounter_id: String) -> Dictionary:
	if not _battle_encounters.has(encounter_id):
		push_error("DataManager: unknown battle encounter id '%s'" % encounter_id)
		return {}
	var encounter: BattleEncounterDef = _battle_encounters[encounter_id]
	var map_entry: Dictionary = _map_registry.get(encounter.battle_map_id, {})
	return {
		"id": encounter_id,
		"battle_source": encounter_id,
		"roster_policy": String(map_entry.get("roster_policy", "default_roster")),
		"roster_source": String(map_entry.get("roster_source", "")),
	}


func get_campaign_pack_roster(roster_id: String) -> Array[UnitData]:
	var output: Array[UnitData] = []
	for unit in _pack_rosters.get(roster_id, []):
		if unit is UnitData:
			output.append((unit as UnitData).duplicate(true))
	return output


# Pure validator: returns the list of cross-reference errors as strings.
# Split out from _ready (B6) so tests can drive it with fixture data without
# capturing push_error. _ready loops over the result and emits each via
# push_error so bad data still surfaces in release builds (assert is stripped).
static func collect_validation_errors(
	classes: Dictionary, weapons: Dictionary, items: Dictionary, skills: Dictionary
) -> Array[String]:
	var errors: Array[String] = []
	_check_class_refs(classes, skills, errors)
	_check_skill_refs(skills, errors)
	_check_weapon_refs(weapons, errors)
	_check_weapon_track_coverage(classes, weapons, errors)
	_check_item_refs(items, classes, errors)
	return errors


static func _check_class_refs(
	classes: Dictionary, skills: Dictionary, errors: Array[String]
) -> void:
	for cls in classes.values():
		# Every skill a class auto-grants at level-up must reference a real skill.
		for level in cls.skill_unlocks:
			var skill_id: String = String(cls.skill_unlocks[level])
			if not skills.has(skill_id):
				errors.append(
					(
						"DataManager: class '%s' skill_unlocks[%s] '%s' not found"
						% [cls.id, str(level), skill_id]
					)
				)
		# Growth tables and caps must carry every expected stat key so a missing
		# entry can't silently zero a stat at level-up.
		_check_stat_dict(cls, "player_growth_rates", cls.player_growth_rates, errors)
		_check_stat_dict(cls, "enemy_growth_rates", cls.enemy_growth_rates, errors)
		_check_stat_dict(cls, "stat_caps", cls.stat_caps, errors)
		_check_weapon_wexp_dict(cls.id, "weapon_wexp_bases", cls.weapon_wexp_bases, false, errors)
		_check_weapon_wexp_dict(cls.id, "weapon_wexp_caps", cls.weapon_wexp_caps, true, errors)
		if (
			cls.internal_level_rule != ""
			and not (cls.internal_level_rule in GameConstants.VALID_INTERNAL_LEVEL_RULES)
		):
			errors.append(
				(
					"DataManager: class '%s' internal_level_rule '%s' is not valid"
					% [cls.id, cls.internal_level_rule]
				)
			)
		if not (cls.class_availability in GameConstants.VALID_CLASS_AVAILABILITY):
			errors.append(
				(
					"DataManager: class '%s' class_availability '%s' is not valid"
					% [cls.id, cls.class_availability]
				)
			)
		for group in cls.vulnerability_groups:
			var group_id: String = String(group)
			if not (group_id in GameConstants.VALID_VULNERABILITY_GROUPS):
				errors.append(
					(
						"DataManager: class '%s' vulnerability_groups '%s' is not a known group"
						% [cls.id, group_id]
					)
				)
		for family in cls.allowed_weapon_families:
			var family_id: String = String(family)
			if not (family_id in GameConstants.VALID_COMBAT_FAMILIES):
				(
					errors
					. append(
						(
							"DataManager: class '%s' allowed_weapon_families '%s' is not a known combat family"
							% [cls.id, family_id]
						)
					)
				)
		for target_id in cls.promotes_to:
			if not classes.has(String(target_id)):
				errors.append(
					(
						"DataManager: class '%s' promotes_to '%s' not found"
						% [cls.id, String(target_id)]
					)
				)
		for source_id in cls.promotes_from:
			if not classes.has(String(source_id)):
				errors.append(
					(
						"DataManager: class '%s' promotes_from '%s' not found"
						% [cls.id, String(source_id)]
					)
				)


# Warns if a class stat dictionary is non-empty but missing expected stat keys.
# Empty {} is allowed (e.g. a class with no enemy variant) and skipped.
static func _check_stat_dict(cls, field: String, dict: Dictionary, errors: Array[String]) -> void:
	if dict.is_empty():
		return
	for key in ClassData.STAT_KEYS:
		if not dict.has(key):
			errors.append("DataManager: class '%s' %s missing stat key '%s'" % [cls.id, field, key])
	# [STM-5] Referenced-but-unregistered stat = hard load error (not a silent 0).
	# growth_rates / stat_caps are growth-stat dicts, so any extra key is a typo'd or
	# unknown stat reference — reject it loudly against the StatRegistry vocabulary.
	for key in dict.keys():
		if not StatRegistry.is_growth_stat(String(key)):
			errors.append(
				(
					"DataManager: class '%s' %s references unknown stat '%s'"
					% [cls.id, field, String(key)]
				)
			)


static func _check_weapon_wexp_dict(
	owner_id: String, field: String, dict: Dictionary, require_positive: bool, errors: Array[String]
) -> void:
	for key in dict.keys():
		var track: String = String(key)
		if not (track in GameConstants.VALID_WEXP_TRACKS):
			errors.append(
				(
					"DataManager: class '%s' %s key '%s' is not a known WEXP track"
					% [owner_id, field, track]
				)
			)
			continue
		var value: int = int(dict[key])
		if value < 0:
			errors.append(
				"DataManager: class '%s' %s['%s'] cannot be negative" % [owner_id, field, track]
			)
		elif require_positive and value == 0:
			errors.append(
				(
					"DataManager: class '%s' %s['%s'] must be > 0 when authored"
					% [owner_id, field, track]
				)
			)


static func _check_skill_refs(skills: Dictionary, errors: Array[String]) -> void:
	for skill in skills.values():
		if skill.activation_chance_stat != "":
			# Valid activation-chance stats = the growth stats, read from the single
			# StatRegistry vocabulary (was the local _VALID_STATS copy).
			if not StatRegistry.is_growth_stat(skill.activation_chance_stat):
				errors.append(
					(
						"DataManager: skill '%s' activation_chance_stat '%s' is not a known stat"
						% [skill.id, skill.activation_chance_stat]
					)
				)
		# Skills whose effect_params name a combat family (faires, breakers) must
		# reference a real combat family so a typo like 'sord' fails loud.
		if skill.effect_params.has("weapon_type"):
			var skl_wt: String = String(skill.effect_params["weapon_type"])
			if not (skl_wt in GameConstants.VALID_COMBAT_FAMILIES):
				(
					errors
					. append(
						(
							"DataManager: skill '%s' effect_params.weapon_type '%s' is not a known weapon type"
							% [skill.id, skl_wt]
						)
					)
				)


static func _check_weapon_refs(weapons: Dictionary, errors: Array[String]) -> void:
	# Catches typos like effective_armored vs effective_armoured (the literal-string
	# match in CombatResolver._is_effective would silently never fire on a typo).
	for weapon in weapons.values():
		if not (weapon.combat_family in GameConstants.VALID_COMBAT_FAMILIES):
			errors.append(
				(
					"DataManager: weapon '%s' combat_family '%s' is not a known combat family"
					% [weapon.id, weapon.combat_family]
				)
			)
		if not (weapon.wexp_track in GameConstants.VALID_WEXP_TRACKS):
			errors.append(
				(
					"DataManager: weapon '%s' wexp_track '%s' is not a known WEXP track"
					% [weapon.id, weapon.wexp_track]
				)
			)
		if weapon.required_rank not in GameConstants.WEXP_RANK_THRESHOLDS:
			errors.append(
				(
					"DataManager: weapon '%s' required_rank '%s' is not a known weapon rank"
					% [weapon.id, weapon.required_rank]
				)
			)
		if (
			weapon.triangle_family != ""
			and not (weapon.triangle_family in GameConstants.VALID_COMBAT_FAMILIES)
		):
			errors.append(
				(
					"DataManager: weapon '%s' triangle_family '%s' is not a known combat family"
					% [weapon.id, weapon.triangle_family]
				)
			)
		for tag in weapon.effect_tags:
			if not (tag in GameConstants.VALID_EFFECT_TAGS):
				errors.append(
					"DataManager: weapon '%s' effect_tag '%s' is not a known tag" % [weapon.id, tag]
				)


static func _check_weapon_track_coverage(
	classes: Dictionary, weapons: Dictionary, errors: Array[String]
) -> void:
	var supplied_tracks: Dictionary = {}
	for weapon in weapons.values():
		if weapon.wexp_track != "":
			supplied_tracks[weapon.wexp_track] = true
	for cls in classes.values():
		for track in cls.weapon_wexp_caps:
			if not supplied_tracks.has(track):
				errors.append(
					(
						"DataManager: class '%s' declares weapon track '%s' with no authored weapon"
						% [cls.id, track]
					)
				)


static func _check_item_refs(items: Dictionary, classes: Dictionary, errors: Array[String]) -> void:
	var registry := ItemEffectRegistryScript.new()
	for item in items.values():
		# Key items may be pure durable markers with no use effect. They still flow
		# through inventory/save validation, but have nothing to dispatch.
		if item.item_type == "key" and item.effect_id.is_empty():
			continue
		errors.append_array(registry.validate_item(item, classes))


# --- Campaigns ([CST-3] progression graphs) ---------------------------------


# Parses every authored campaign JSON in `dir_path` into `target` (campaign_id ->
# CampaignData). Structural problems and a missing/unreadable directory are
# collected as errors, matching the loud-failure policy the map registry and the
# registry catalogue already use — a campaign that half-loads would strand a run.
static func load_campaigns(dir_path: String, target: Dictionary, errors: Array[String]) -> void:
	var campaign_paths: Array[String] = ResourceManifest.load_paths(dir_path)
	if campaign_paths.is_empty():
		errors.append("DataManager: no campaigns found at %s" % dir_path)
		return
	for path in campaign_paths:
		if not FileAccess.file_exists(path):
			errors.append("DataManager: campaign file missing at %s" % path)
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		var campaign := CampaignData.parse(parsed, path, errors)
		if campaign == null:
			continue
		if target.has(campaign.campaign_id):
			errors.append(
				"DataManager: duplicate campaign_id '%s' at %s" % [campaign.campaign_id, path]
			)
			continue
		target[campaign.campaign_id] = campaign


# Cross-reference pass: every node's map binding must resolve to a map_registry
# id. Structural graph checks already ran in CampaignData.parse.
static func collect_campaign_validation_errors(
	campaigns: Dictionary, known_map_ids: Dictionary, known_encounters: Dictionary = {}
) -> Array[String]:
	var errors: Array[String] = []
	for campaign in campaigns.values():
		for node in campaign.nodes:
			if node.map_id != "" and node.encounter_id != "":
				errors.append(
					(
						"DataManager: campaign '%s' node '%s' has ambiguous battle references"
						% [campaign.campaign_id, node.node_id]
					)
				)
			if node.map_id != "" and not known_map_ids.has(node.map_id):
				errors.append(
					(
						"DataManager: campaign '%s' node '%s' references unknown map id '%s'"
						% [campaign.campaign_id, node.node_id, node.map_id]
					)
				)
			if (
				node.encounter_id != ""
				and not known_encounters.is_empty()
				and not known_encounters.has(node.encounter_id)
			):
				errors.append(
					(
						"DataManager: campaign '%s' node '%s' references unknown encounter id '%s'"
						% [campaign.campaign_id, node.node_id, node.encounter_id]
					)
				)
	return errors


func _load_battle_catalogues(maps_root: String) -> void:
	_load_typed_manifest(maps_root.path_join("battle_maps"), _battle_maps, BattleMapDef)
	_load_typed_manifest(
		maps_root.path_join("battle_encounters"), _battle_encounters, BattleEncounterDef
	)


func _load_typed_manifest(dir_path: String, target: Dictionary, expected_type: Variant) -> void:
	for path in ResourceManifest.load_paths(dir_path):
		var loaded: Variant = load(path)
		if loaded == null or loaded.get_script() != expected_type:
			push_error("DataManager: '%s' has the wrong battle catalogue resource type" % path)
			continue
		var resource_id: String = String(loaded.get("id"))
		if resource_id == "" or target.has(resource_id):
			push_error("DataManager: missing/duplicate battle catalogue id '%s'" % resource_id)
			continue
		target[resource_id] = loaded


static func collect_battle_catalogue_validation_errors(
	maps: Dictionary, encounters: Dictionary, classes: Dictionary, items: Dictionary = {}
) -> Array[String]:
	var errors: Array[String] = []
	for map_id in maps:
		var map_def: BattleMapDef = maps[map_id]
		if map_def == null or map_def.id == "" or map_def.display_name == "":
			errors.append("DataManager: battle map '%s' is missing id/display_name" % map_id)
			continue
		if map_def.grid.is_empty():
			errors.append("DataManager: battle map '%s' has no grid" % map_id)
		else:
			var width := map_def.grid[0].length()
			for row in map_def.grid:
				if row.length() != width:
					errors.append("DataManager: battle map '%s' grid is not rectangular" % map_id)
					break
		if map_def.player_start_tiles.is_empty():
			errors.append("DataManager: battle map '%s' has no player_start_tiles" % map_id)
		for tile in map_def.player_start_tiles + map_def.enemy_start_tiles:
			if (
				map_def.grid.is_empty()
				or tile.x < 0
				or tile.y < 0
				or tile.y >= map_def.grid.size()
				or tile.x >= map_def.grid[0].length()
			):
				errors.append(
					"DataManager: battle map '%s' has out-of-bounds start tile %s" % [map_id, tile]
				)
	for encounter_id in encounters:
		var encounter: BattleEncounterDef = encounters[encounter_id]
		if encounter == null or encounter.id == "":
			errors.append("DataManager: encounter '%s' is missing id" % encounter_id)
			continue
		if not maps.has(encounter.battle_map_id):
			errors.append(
				(
					"DataManager: encounter '%s' references unknown battle map '%s'"
					% [encounter_id, encounter.battle_map_id]
				)
			)
		if not (encounter.activation_mode in _VALID_ACTIVATION_MODES):
			errors.append("DataManager: encounter '%s' has invalid activation_mode" % encounter_id)
		if not maps.has(encounter.battle_map_id):
			continue
		var owner_map: BattleMapDef = maps[encounter.battle_map_id]
		var projection := MapData.new()
		projection.id = encounter.id
		projection.display_name = owner_map.display_name
		projection.tilemap_scene_path = owner_map.tilemap_scene_path
		projection.player_start_tiles = owner_map.player_start_tiles
		projection.camera_start_tile = owner_map.camera_start_tile
		projection.grid = owner_map.grid
		projection.enemy_placements = encounter.enemy_placements
		projection.factions = encounter.factions
		projection.turn_order = encounter.turn_order
		projection.activation_mode = encounter.activation_mode
		projection.victory_conditions = encounter.victory_conditions
		projection.defeat_conditions = encounter.defeat_conditions
		projection.reward_gold = encounter.reward_gold
		projection.reward_items = encounter.reward_items
		errors.append_array(
			collect_map_data_validation_errors(
				projection, "encounter:%s" % encounter_id, classes, items
			)
		)
	return errors


# The map registry keyed by id. Parse errors are the map registry validator's
# job, so a broken registry simply yields no entries here.
static func load_map_registry_entries(registry_path: String) -> Dictionary:
	var entries := {}
	if not FileAccess.file_exists(registry_path):
		return entries
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(registry_path))
	if not (parsed is Array):
		return entries
	for entry in parsed as Array:
		if entry is Dictionary:
			var entry_id: String = String((entry as Dictionary).get("id", ""))
			if entry_id != "":
				entries[entry_id] = entry
	return entries


# The map-id vocabulary campaigns bind against.
static func collect_map_registry_ids(registry_path: String) -> Dictionary:
	var ids := {}
	for entry_id in load_map_registry_entries(registry_path):
		ids[entry_id] = true
	return ids


func _load_map_registry(registry_path: String) -> void:
	_map_registry = load_map_registry_entries(registry_path)


func _register_single_map_campaigns() -> void:
	for map_id in _map_registry:
		var entry: Dictionary = _map_registry[map_id]
		var campaign := CampaignData.make_single_map(entry)
		if campaign == null:
			continue
		if _campaigns.has(campaign.campaign_id):
			push_error(
				(
					"DataManager: generated single-map campaign id collides with authored campaign '%s'"
					% campaign.campaign_id
				)
			)
			continue
		_campaigns[campaign.campaign_id] = campaign


# The full registry entry (map_data_path, roster_policy, roster_source, …) for a
# map id. Campaign nodes bind by map id ([CNC-3]) and need the entry to launch,
# so the campaign flow resolves through here rather than re-reading the registry
# from disk. Unknown ids fail loud: launching "nothing" would strand a run.
func get_map_registry_entry(map_id: String) -> Dictionary:
	if not _map_registry.has(map_id):
		push_error("DataManager: unknown map registry id '%s'" % map_id)
		return {}
	return _map_registry[map_id]


func has_map_registry_entry(map_id: String) -> bool:
	return _map_registry.has(map_id)


func _load_campaign_directory(dir_path: String) -> void:
	var errors: Array[String] = []
	load_campaigns(dir_path, _campaigns, errors)
	_report(errors)


func get_campaign(id: String) -> CampaignData:
	if not _campaigns.has(id):
		push_error("DataManager: unknown campaign id '%s'" % id)
		return null
	return _campaigns[id]


func has_campaign(id: String) -> bool:
	return _campaigns.has(id)


func get_all_campaigns() -> Dictionary:
	return _campaigns


func get_shipped_campaigns() -> Dictionary:
	return _shipped_campaigns


static func _duplicate_campaigns(source: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for campaign_id in source:
		var campaign: CampaignData = source[campaign_id]
		out[campaign_id] = campaign.duplicate(true) if campaign != null else null
	return out


static func collect_map_registry_validation_errors(
	registry_path: String, classes: Dictionary, items: Dictionary = {}
) -> Array[String]:
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


static func _validate_map_registry_entry(
	entry: Dictionary,
	index: int,
	seen_ids: Dictionary,
	seen_paths: Dictionary,
	classes: Dictionary,
	items: Dictionary,
	errors: Array[String]
) -> void:
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
		errors.append(
			"DataManager: map registry entry %d ('%s') is missing 'label'" % [index, entry_id]
		)
	if map_path == "":
		errors.append(
			(
				"DataManager: map registry entry %d ('%s') is missing 'map_data_path'"
				% [index, entry_id]
			)
		)
	else:
		if seen_paths.has(map_path):
			errors.append("DataManager: map registry duplicate map_data_path '%s'" % map_path)
		else:
			seen_paths[map_path] = true
	if not (roster_policy in _VALID_ROSTER_POLICIES):
		errors.append(
			(
				"DataManager: map registry entry '%s' roster_policy '%s' is not valid"
				% [entry_id, roster_policy]
			)
		)
	# Cross-source unit_id uniqueness (code review 2026-06-10 issue 2.10).
	# Shared dedup table across the roster pass below and the enemy_placements
	# pass in collect_map_data_validation_errors; a duplicate unit_id between a
	# roster file and an enemy placement breaks find_unit_by_id and Pair Up
	# in silently confusing ways.
	var seen_unit_ids: Dictionary = {}
	if roster_policy == "fixed_test_roster":
		if roster_source == "":
			(
				errors
				. append(
					(
						"DataManager: map registry entry '%s' fixed_test_roster is missing roster_source"
						% entry_id
					)
				)
			)
		else:
			var roster_paths: Array[String] = ResourceManifest.load_paths(roster_source)
			if roster_paths.is_empty():
				(
					errors
					. append(
						(
							"DataManager: map registry entry '%s' roster_source '%s' does not load any roster units"
							% [entry_id, roster_source]
						)
					)
				)
			else:
				var roster_units: Array = []
				for roster_path in roster_paths:
					var loaded := load(roster_path)
					if loaded == null:
						errors.append(
							(
								"DataManager: roster file '%s' failed to load for map '%s'"
								% [roster_path, entry_id]
							)
						)
						continue
					roster_units.append(loaded)
					if loaded is UnitData and String(loaded.unit_id) != "":
						var uid: String = String(loaded.unit_id)
						var here: String = "roster file '%s'" % roster_path
						if seen_unit_ids.has(uid):
							errors.append(
								(
									"DataManager: duplicate unit_id '%s' at %s (also at %s)"
									% [uid, here, seen_unit_ids[uid]]
								)
							)
						else:
							seen_unit_ids[uid] = here
				for err in collect_unit_validation_errors(roster_units, classes):
					errors.append(err)
	if roster_policy != "fixed_test_roster" and roster_source != "":
		(
			errors
			. append(
				(
					"DataManager: map registry entry '%s' roster_source should be empty for roster_policy '%s'"
					% [entry_id, roster_policy]
				)
			)
		)
	if map_path == "":
		return
	if not ResourceLoader.exists(map_path):
		errors.append(
			(
				"DataManager: map registry entry '%s' points at missing MapData '%s'"
				% [entry_id, map_path]
			)
		)
		return
	var loaded_map := load(map_path)
	if not (loaded_map is MapData):
		errors.append(
			(
				"DataManager: map registry entry '%s' path '%s' did not load as MapData"
				% [entry_id, map_path]
			)
		)
		return
	var map_data: MapData = loaded_map
	if entry_id != "" and map_data.id != "" and map_data.id != entry_id:
		errors.append(
			(
				"DataManager: map registry entry '%s' points at MapData id '%s'"
				% [entry_id, map_data.id]
			)
		)
	for err in collect_map_data_validation_errors(
		map_data, map_path, classes, items, seen_unit_ids
	):
		errors.append(err)


# [STM-5] Pair Up bonus table stat-reference validation. `scaling_stats` and every
# inner key of `class_bonuses` name a stat; a typo (e.g. "strngth") would otherwise
# scale/bonus a phantom stat as a silent 0. Absent table = no error (Pair Up simply
# contributes nothing), matching the resolver's tolerant load. Loaded from a path
# (mirrors collect_map_registry_validation_errors) so tests can point it elsewhere.
static func collect_pair_up_validation_errors(table_path: String) -> Array[String]:
	var errors: Array[String] = []
	if not ResourceLoader.exists(table_path):
		return errors
	var table: Resource = load(table_path)
	if table == null:
		errors.append("DataManager: pair-up bonus table failed to load at %s" % table_path)
		return errors
	_check_pair_up_stat_refs(table, errors)
	return errors


# Resource-level ref check, split out so tests can drive a constructed table
# without writing a .tres to disk (path loader above wraps it for the boot pass).
static func _check_pair_up_stat_refs(table: Resource, errors: Array[String]) -> void:
	var scaling_stats: PackedStringArray = table.get("scaling_stats")
	for stat in scaling_stats:
		if not StatRegistry.is_registered_stat(String(stat)):
			errors.append(
				(
					"DataManager: pair-up table scaling_stats references unknown stat '%s'"
					% String(stat)
				)
			)
	var class_bonuses: Dictionary = table.get("class_bonuses")
	for class_id in class_bonuses.keys():
		var block: Dictionary = class_bonuses[class_id]
		for stat in block.keys():
			if not StatRegistry.is_registered_stat(String(stat)):
				(
					errors
					. append(
						(
							"DataManager: pair-up table class_bonuses['%s'] references unknown stat '%s'"
							% [String(class_id), String(stat)]
						)
					)
				)


# `seen_unit_ids` is unit_id -> source description (e.g. "roster file '...'"
# or "enemy placement '...'"). Threaded in by collect_map_registry_validation
# _errors so the unit_ids loaded from the roster directory and the enemy_
# placements share a single dedup namespace. Defaults to a fresh dict for
# direct callers that don't have a cross-source view. Code review 2026-06-10
# issue 2.10.
# `terrain` decides which grid chars an authored row may use. It defaults to the
# engine set so direct callers keep working; activation passes the pack's registry so
# a pack that retunes a terrain's char is validated against what it actually authored.
static func collect_map_data_validation_errors(
	map_data: MapData,
	map_path: String,
	classes: Dictionary,
	items: Dictionary = {},
	seen_unit_ids: Dictionary = {},
	terrain: TerrainRegistry = null
) -> Array[String]:
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
			errors.append(
				(
					"DataManager: map '%s' tilemap_scene_path '%s' is missing"
					% [map_path, map_data.tilemap_scene_path]
				)
			)
		else:
			var tilemap_scene := load(map_data.tilemap_scene_path)
			if not (tilemap_scene is PackedScene):
				errors.append(
					(
						"DataManager: map '%s' tilemap_scene_path '%s' did not load as PackedScene"
						% [map_path, map_data.tilemap_scene_path]
					)
				)
	if map_data.player_start_tiles.is_empty():
		errors.append("DataManager: map '%s' has no player_start_tiles" % map_path)
	for reward_item in map_data.reward_items:
		var reward_item_id: String = String(reward_item)
		if reward_item_id == "":
			errors.append("DataManager: map '%s' reward_items contains an empty item id" % map_path)
		elif not items.is_empty() and not items.has(reward_item_id):
			errors.append(
				(
					"DataManager: map '%s' reward_items item '%s' not found"
					% [map_path, reward_item_id]
				)
			)
	var seen_player_tiles := {}
	for tile in map_data.player_start_tiles:
		var tile_key := "%d,%d" % [tile.x, tile.y]
		if seen_player_tiles.has(tile_key):
			errors.append(
				"DataManager: map '%s' has duplicate player_start_tile %s" % [map_path, str(tile)]
			)
		else:
			seen_player_tiles[tile_key] = true
	var width: int = 0
	var height: int = map_data.grid.size()
	if not map_data.grid.is_empty():
		width = map_data.grid[0].length()
		# The grid char vocabulary belongs to the terrain definitions, not to a literal
		# set here that had to be kept identical to GameMap's painting table by hand.
		var terrain_registry: TerrainRegistry = (
			terrain if terrain != null else TerrainRegistry.engine_defaults()
		)
		for y in map_data.grid.size():
			var row: String = map_data.grid[y]
			if row.length() != width:
				errors.append(
					(
						"DataManager: map '%s' grid row %d length %d != %d"
						% [map_path, y, row.length(), width]
					)
				)
			for x in row.length():
				var ch: String = row[x]
				if terrain_registry.id_for_grid_char(ch).is_empty():
					errors.append(
						(
							"DataManager: map '%s' grid row %d col %d has unknown terrain '%s'"
							% [map_path, y, x, ch]
						)
					)
		if map_data.camera_start_tile != Vector2i(-1, -1):
			if not _tile_is_inside_grid(map_data.camera_start_tile, width, height):
				errors.append(
					(
						"DataManager: map '%s' camera_start_tile %s is outside the grid"
						% [map_path, str(map_data.camera_start_tile)]
					)
				)
	for tile in map_data.player_start_tiles:
		if width > 0 and height > 0 and not _tile_is_inside_grid(tile, width, height):
			errors.append(
				(
					"DataManager: map '%s' player_start_tile %s is outside the grid"
					% [map_path, str(tile)]
				)
			)
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
				errors.append(
					"DataManager: map '%s' has duplicate faction id '%s'" % [map_path, faction.id]
				)
		else:
			faction_ids[faction.id] = true
		if faction.alliance_group != "":
			alliance_groups[faction.alliance_group] = true
	if not (map_data.activation_mode in _VALID_ACTIVATION_MODES):
		errors.append(
			(
				"DataManager: map '%s' activation_mode '%s' is not valid"
				% [map_path, map_data.activation_mode]
			)
		)
	var seen_turn_ids := {}
	for faction_id in map_data.turn_order:
		if faction_id == "":
			errors.append(
				"DataManager: map '%s' turn_order contains an empty faction id" % map_path
			)
			continue
		if seen_turn_ids.has(faction_id):
			errors.append(
				"DataManager: map '%s' turn_order repeats faction '%s'" % [map_path, faction_id]
			)
		else:
			seen_turn_ids[faction_id] = true
		if not faction_ids.has(faction_id):
			errors.append(
				(
					"DataManager: map '%s' turn_order references unknown faction '%s'"
					% [map_path, faction_id]
				)
			)
	var seen_enemy_tiles := {}
	for placement in map_data.enemy_placements:
		if not (placement is Dictionary):
			errors.append(
				(
					"DataManager: map '%s' has non-Dictionary enemy placement %s"
					% [map_path, str(placement)]
				)
			)
			continue
		var unit_path: String = String(placement.get("unit_data_path", ""))
		var inline_unit: Variant = placement.get("unit_data", null)
		var has_unit_path := unit_path != ""
		var has_inline_unit := inline_unit != null
		var unit_loaded: UnitData = null
		var unit_source := ""
		if has_unit_path == has_inline_unit:
			(
				errors
				. append(
					(
						"DataManager: map '%s' enemy placement must provide exactly one of unit_data_path or unit_data"
						% map_path
					)
				)
			)
		elif has_unit_path:
			unit_source = "enemy placement '%s'" % unit_path
			if not ResourceLoader.exists(unit_path):
				errors.append(
					(
						"DataManager: map '%s' enemy placement points at missing UnitData '%s'"
						% [map_path, unit_path]
					)
				)
			else:
				var unit_resource := load(unit_path)
				if not (unit_resource is UnitData):
					errors.append(
						(
							"DataManager: map '%s' enemy placement '%s' did not load as UnitData"
							% [map_path, unit_path]
						)
					)
				else:
					unit_loaded = unit_resource
		else:
			if not (inline_unit is UnitData):
				errors.append(
					"DataManager: map '%s' enemy placement unit_data is not UnitData" % map_path
				)
			else:
				unit_loaded = inline_unit
				unit_source = "enemy placement inline unit_data"
		if unit_loaded != null:
			if String(unit_loaded.unit_id) == "":
				errors.append(
					"DataManager: map '%s' %s has empty unit_id" % [map_path, unit_source]
				)
			else:
				var uid: String = String(unit_loaded.unit_id)
				var here: String = unit_source
				if not has_unit_path:
					here = "%s '%s'" % [unit_source, uid]
				if seen_unit_ids.has(uid):
					errors.append(
						(
							"DataManager: duplicate unit_id '%s' at %s (also at %s)"
							% [uid, here, seen_unit_ids[uid]]
						)
					)
				else:
					seen_unit_ids[uid] = here
				for err in collect_unit_validation_errors([unit_loaded], classes):
					errors.append(err)
		if not placement.has("tile"):
			errors.append("DataManager: map '%s' has enemy placement missing tile" % map_path)
		else:
			var enemy_tile: Vector2i = placement.get("tile", Vector2i.ZERO)
			var tile_key := "%d,%d" % [enemy_tile.x, enemy_tile.y]
			if seen_player_tiles.has(tile_key):
				errors.append(
					(
						"DataManager: map '%s' enemy placement tile %s overlaps a player start"
						% [map_path, str(enemy_tile)]
					)
				)
			if seen_enemy_tiles.has(tile_key):
				errors.append(
					(
						"DataManager: map '%s' has duplicate enemy placement tile %s"
						% [map_path, str(enemy_tile)]
					)
				)
			else:
				seen_enemy_tiles[tile_key] = true
		var placement_faction: String = String(placement.get("faction", "red"))
		if placement_faction == "":
			errors.append(
				"DataManager: map '%s' has enemy placement with empty faction id" % map_path
			)
		elif not faction_ids.has(placement_faction):
			errors.append(
				(
					"DataManager: map '%s' enemy placement references unknown faction '%s'"
					% [map_path, placement_faction]
				)
			)
		var ai_profile: String = String(placement.get("ai_profile", "basic"))
		if not AIProfileRegistry.is_valid_profile(ai_profile):
			errors.append(
				(
					"DataManager: map '%s' enemy placement ai_profile '%s' is not valid"
					% [map_path, ai_profile]
				)
			)
		if placement.has("tile"):
			var enemy_tile: Vector2i = placement.get("tile", Vector2i.ZERO)
			if width > 0 and height > 0 and not _tile_is_inside_grid(enemy_tile, width, height):
				errors.append(
					(
						"DataManager: map '%s' enemy placement tile %s is outside the grid"
						% [map_path, str(enemy_tile)]
					)
				)
	_validate_condition_dict(
		map_data.victory_conditions,
		"victory_conditions",
		map_path,
		faction_ids,
		alliance_groups,
		width,
		height,
		errors
	)
	_validate_condition_dict(
		map_data.defeat_conditions,
		"defeat_conditions",
		map_path,
		faction_ids,
		alliance_groups,
		width,
		height,
		errors
	)
	return errors


static func _validate_condition_dict(
	cond_dict: Dictionary,
	field_name: String,
	map_path: String,
	faction_ids: Dictionary,
	alliance_groups: Dictionary,
	width: int,
	height: int,
	errors: Array[String]
) -> void:
	for group_id in cond_dict.keys():
		var group_name: String = String(group_id)
		if group_name == "":
			errors.append("DataManager: map '%s' %s has an empty group id" % [map_path, field_name])
		elif not alliance_groups.has(group_name):
			errors.append(
				(
					"DataManager: map '%s' %s references unknown alliance group '%s'"
					% [map_path, field_name, group_name]
				)
			)
		var conds: Variant = cond_dict[group_id]
		if not (conds is Array):
			errors.append(
				(
					"DataManager: map '%s' %s['%s'] is not an Array"
					% [map_path, field_name, group_name]
				)
			)
			continue
		for i in conds.size():
			var cond: Variant = conds[i]
			if not (cond is ObjectiveCondition):
				errors.append(
					(
						"DataManager: map '%s' %s['%s'][%d] is not an ObjectiveCondition"
						% [map_path, field_name, group_name, i]
					)
				)
				continue
			_validate_objective_condition(
				cond,
				map_path,
				field_name,
				group_name,
				faction_ids,
				alliance_groups,
				width,
				height,
				errors
			)


static func _validate_objective_condition(
	cond: ObjectiveCondition,
	map_path: String,
	field_name: String,
	group_name: String,
	faction_ids: Dictionary,
	alliance_groups: Dictionary,
	width: int,
	height: int,
	errors: Array[String]
) -> void:
	var registry := ObjectiveConditionRegistryScript.new()
	errors.append_array(
		registry.validate(
			cond,
			{
				"map_path": map_path,
				"field_name": field_name,
				"group_name": group_name,
				"faction_ids": faction_ids,
				"alliance_groups": alliance_groups,
				"width": width,
				"height": height
			}
		)
	)


static func _tile_is_inside_grid(tile: Vector2i, width: int, height: int) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < width and tile.y < height


# Result codes returned by register_loaded_resource. Was a free-form String
# error previously, which forced _load_directory to switch severity via a
# substring search on the message — fragile across rewordings (code review
# 2026-06-09). Keeping the message in the return alongside the code so callers
# that want to surface it still can.
enum LoadResult { OK, MISSING_ID, DUPLICATE_ID, LOAD_FAILED }


static func register_loaded_resource(
	target: Dictionary, res: Resource, res_path: String
) -> Dictionary:
	if res == null:
		return {
			"result": LoadResult.LOAD_FAILED,
			"message": "DataManager: resource at %s failed to load" % res_path
		}
	var rid: Variant = res.get("id")
	if rid == null or rid == "":
		return {
			"result": LoadResult.MISSING_ID,
			"message": "DataManager: resource at %s has no 'id' field" % res_path
		}
	var id: String = String(rid)
	if target.has(id):
		return {
			"result": LoadResult.DUPLICATE_ID,
			"message": "DataManager: duplicate resource id '%s' at %s" % [id, res_path]
		}
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
#
# V070-11: this and the three lookups below all report an unresolved id through
# `_report_unknown_id`, which reports each distinct id once per content activation.
# Every one of them sits on a hot path (per unit, per skill, per trigger, per phase;
# per combat exchange; per screen build), so the per-call report made one authored
# typo cost thousands of identical lines. Nothing goes silent: the first miss is
# still reported, and it also lands in `content_status()["warnings"]`.
func get_class_data(id: String) -> ClassData:
	if not _classes.has(id):
		_report_unknown_id("class", id)
		return null
	return _classes[id]


func get_all_classes() -> Dictionary:
	return _classes


func validate_unit_data(unit: UnitData) -> Array[String]:
	return collect_unit_validation_errors([unit], _classes)


func get_weapon(id: String) -> WeaponData:
	if not _weapons.has(id):
		_report_unknown_id("weapon", id)
		return null
	return _weapons[id]


func has_weapon(id: String) -> bool:
	return _weapons.has(id)


func get_item(id: String) -> ItemData:
	if not _items.has(id):
		_report_unknown_id("item", id)
		return null
	return _items[id]


func has_item(id: String) -> bool:
	return _items.has(id)


func get_skill(id: String) -> SkillData:
	if not _skills.has(id):
		_report_unknown_id("skill", id)
		return null
	return _skills[id]


func is_skill_release_available(id: String) -> bool:
	var skill := get_skill(id)
	return skill != null and skill.is_available_for_release()


func release_available_skills() -> Array[SkillData]:
	var out: Array[SkillData] = []
	for skill_any in _skills.values():
		var skill: SkillData = skill_any
		if skill.is_available_for_release():
			out.append(skill)
	return out


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
			errors.append(
				"DataManager: unit '%s' class_id '%s' not found" % [unit.unit_id, unit.class_id]
			)
		if unit.internal_level < 1:
			errors.append("DataManager: unit '%s' internal_level must be >= 1" % [unit.unit_id])
		# HP / max_hp / level invariants (code review 2026-06-10 issue 2.7).
		# Mirrors GameState._validate_snapshot_unit_dict so authoring caught here
		# at boot matches what the snapshot restore would reject at runtime.
		if unit.level < 1:
			errors.append("DataManager: unit '%s' level must be >= 1" % unit.unit_id)
		if unit.max_hp < 1:
			errors.append("DataManager: unit '%s' max_hp must be >= 1" % unit.unit_id)
		if unit.hp < 0:
			errors.append(
				"DataManager: unit '%s' hp cannot be negative (%d)" % [unit.unit_id, unit.hp]
			)
		elif unit.max_hp >= 1 and unit.hp > unit.max_hp:
			errors.append(
				(
					"DataManager: unit '%s' hp %d exceeds max_hp %d"
					% [unit.unit_id, unit.hp, unit.max_hp]
				)
			)
		if unit.class_line_id != "":
			if not classes.has(unit.class_line_id):
				errors.append(
					(
						"DataManager: unit '%s' class_line_id '%s' not found"
						% [unit.unit_id, unit.class_line_id]
					)
				)
			else:
				var line_class: ClassData = classes[unit.class_line_id]
				if line_class.tier != 1:
					errors.append(
						(
							"DataManager: unit '%s' class_line_id '%s' must point to a tier-1 class"
							% [unit.unit_id, unit.class_line_id]
						)
					)
		for option_id in unit.reclass_options:
			if not classes.has(String(option_id)):
				errors.append(
					(
						"DataManager: unit '%s' reclass_options '%s' not found"
						% [unit.unit_id, String(option_id)]
					)
				)
				continue
			var option_class: ClassData = classes[String(option_id)]
			if option_class.tier != 1:
				errors.append(
					(
						"DataManager: unit '%s' reclass_options '%s' must point to a tier-1 class"
						% [unit.unit_id, String(option_id)]
					)
				)
		for track in unit.weapon_wexp.keys():
			var track_id: String = String(track)
			if not (track_id in GameConstants.VALID_WEXP_TRACKS):
				errors.append(
					(
						"DataManager: unit '%s' weapon_wexp key '%s' is not a known WEXP track"
						% [unit.unit_id, track_id]
					)
				)
				continue
			if int(unit.weapon_wexp[track]) < 0:
				errors.append(
					(
						"DataManager: unit '%s' weapon_wexp['%s'] cannot be negative"
						% [unit.unit_id, track_id]
					)
				)
		if not AIProfileRegistry.is_valid_profile(unit.ai_profile):
			errors.append(
				(
					"DataManager: unit '%s' ai_profile '%s' is not valid"
					% [unit.unit_id, unit.ai_profile]
				)
			)
		# [STM-5] personal growth_rates is a PARTIAL override dict (only the stats an
		# author bumps), so unlike the class dicts it needs no presence check — but a
		# key outside the growth-stat vocabulary is a typo that would add a phantom 0
		# growth. Reject it loudly, same policy as the class dicts.
		for stat in unit.growth_rates.keys():
			if not StatRegistry.is_growth_stat(String(stat)):
				errors.append(
					(
						"DataManager: unit '%s' growth_rates references unknown stat '%s'"
						% [unit.unit_id, String(stat)]
					)
				)
	return errors
