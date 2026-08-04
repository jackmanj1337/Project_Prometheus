extends SceneTree
# Extracts the engine's baked `res://data` content into ONE self-contained Tier-2
# campaign pack — the zero-content plan's Slice 4 / `IMPL-ZERO-CONTENT-BASE-PACK`
# machinery, run against the internal FE target first.
#
# Run with:
#   godot --headless --path . --script res://scripts/tools/extract_proving_grounds_pack.gd \
#     -- --out /abs/path/to/pack_root [--package-id UUID] [--rights-status unchecked]
#
# WHY THIS IS A TOOL AND NOT A COPY. A pack is not `data/` renamed. The engine
# stores content as Godot `.tres` resources with typed arrays and resource
# references; a pack carries indexed JSON documents in the registered
# `EntitySchemaRegistry` shapes, each one naming its provenance through
# `source_refs` that resolve in a `source_registry`. Provenance is the whole point:
# `fe_numeric_provenance_audit_2026-07-30.md` found 10 of 12 weapons and every
# non-placeholder class reproduce an older TTRPG table, and the only way that fact
# can travel WITH the numbers is if extraction writes it down per document.
#
# So every emitted document is stamped with a source id, and every source carries a
# `rights_status`. The default is deliberately `unchecked` — extraction is a
# mechanical move, and claiming `verified` here would launder exactly the finding
# the audit raised. Clearing rights is a separate, human pass over the emitted
# registry.
#
# Families with no registered Tier-2 kind (skills, pair-up, the engine's action /
# item-effect / objective / occupancy / resource registries) are NOT emitted and are
# reported as gaps, rather than being silently dropped or invented into a shape the
# validator has never seen.

const EntitySchemas = preload("res://scripts/data/EntitySchemaRegistry.gd")
const TerrainRegistryScript = preload("res://scripts/core/TerrainRegistry.gd")
const WeaponDataScript = preload("res://scripts/resources/WeaponData.gd")

const SOURCE_REGISTRY_ID := "proving_grounds_sources"
const ASSET_REGISTRY_ID := "proving_grounds_assets"
const OCCURRENCE_AUDIT_ID := "proving_grounds_occurrences"
# One source per provenance class, so the copyright pass can retune or replace a
# whole group by editing one record instead of hunting every document.
const SOURCE_PROJECT := "project_original"
const SOURCE_TRANSCRIBED := "inherited_ttrpg_tables"

# The audit's exact findings, by resource id. Anything named here is stamped with
# the transcribed source so the public-pack retune has a machine-readable worklist;
# everything else gets the project source. Held as data because the audit is the
# authority, not this script.
const AUDIT_TRANSCRIBED_WEAPONS := [
	"iron_sword",
	"steel_sword",
	"iron_lance",
	"javelin",
	"iron_axe",
	"iron_bow",
	"fire",
	"elfire",
	"thunder",
	"wind",
	# The audit lists this row as "Heal"; the resource id is heal_staff.
	"heal_staff",
]

var _out_root := ""
var _package_id := ""
var _rights_status := "unchecked"
var _catalogue: Array[Dictionary] = []
var _asset_records: Dictionary = {}
var _derived_occurrences: Dictionary = {}
var _emitted_map_ids: Dictionary = {}
var _emitted_roster_ids: Dictionary = {}
var _map_ids_by_encounter: Dictionary = {}
var _gaps: Array[String] = []
var _errors: Array[String] = []


func _init() -> void:
	if not _parse_args():
		quit(2)
		return
	print("=== Proving Grounds pack extraction ===")
	print("out: %s" % _out_root)

	_reset_output()
	_emit_classes()
	_emit_weapons()
	_emit_items()
	_emit_rosters()
	_emit_terrain()
	_emit_maps()
	_map_ids_by_encounter = _emit_map_registry()
	_emit_campaigns()
	# After every emitter, so derived occurrences are in the registry it writes.
	_emit_sources()
	# Assets last: every emitter registers the media it referenced, so the registry
	# is the union of what the pack actually names rather than a directory listing.
	_emit_assets()
	_write_catalogue()
	_write_manifest()

	_record_gaps()

	print("")
	for gap in _gaps:
		print("GAP  %s" % gap)
	for error in _errors:
		print("ERROR %s" % error)
	print("")
	print(
		(
			"entries: %d, assets: %d, gaps: %d, errors: %d"
			% [_catalogue.size(), _asset_records.size(), _gaps.size(), _errors.size()]
		)
	)
	quit(1 if not _errors.is_empty() else 0)


func _parse_args() -> bool:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--out":
				i += 1
				if i < args.size():
					_out_root = args[i].trim_suffix("/")
			"--package-id":
				i += 1
				if i < args.size():
					_package_id = args[i]
			"--rights-status":
				i += 1
				if i < args.size():
					_rights_status = args[i]
			_:
				printerr("unknown argument: %s" % args[i])
				return false
		i += 1
	if _out_root.is_empty():
		printerr("--out is required")
		return false
	if _package_id.is_empty():
		# Stable rather than random: re-running extraction must not mint a new package
		# identity, or every run would look like a different pack to the installer.
		_package_id = "prometheus-proving-grounds-internal-fe"
	return true


func _reset_output() -> void:
	# The emitted set is derived from the catalogue, so a stale document left by an
	# earlier run would be unreferenced but still shipped. Clear the data dir.
	var data_dir := _out_root.path_join("data")
	if DirAccess.dir_exists_absolute(data_dir):
		for file in DirAccess.get_files_at(data_dir):
			DirAccess.remove_absolute(data_dir.path_join(file))
	DirAccess.make_dir_recursive_absolute(data_dir)
	DirAccess.make_dir_recursive_absolute(_out_root.path_join("assets"))


# --- documents ---------------------------------------------------------------


# The provenance spine. Two sources, both `unchecked` by default: extraction moved
# these numbers, it did not clear them.
func _emit_sources() -> void:
	var document := {
		"schema_version": 1,
		"kind": "source_registry",
		"id": SOURCE_REGISTRY_ID,
		"sources":
		{
			SOURCE_PROJECT:
			{
				"locator": "internal://project-prometheus/data",
				"title": "Project Prometheus engine data",
				"attribution": "Project Prometheus",
				"rights_status": _rights_status,
				"license_id": "LicenseRef-Project-Prometheus-Internal",
				"distribution_scope": "private_only",
				"attribution_required": false,
				"author_notes":
				(
					"Content extracted mechanically from res://data. Rights are NOT asserted "
					+ "by extraction; this record starts unchecked on purpose."
				),
			},
			SOURCE_TRANSCRIBED:
			{
				"locator": "internal://old-deferred/items_and_weapons",
				"title": "Inherited TTRPG weapon and class tables",
				"attribution": "Unresolved — see fe_numeric_provenance_audit_2026-07-30.md",
				"rights_status": "disputed",
				"license_id": "LicenseRef-Unresolved",
				"distribution_scope": "private_only",
				"attribution_required": true,
				"author_notes":
				(
					"The 2026-07-30 provenance audit found these rows reproduce complete stat "
					+ "lines from an older combined TTRPG reference. Every document naming this "
					+ "source must be retuned or licensed before it can leave a private pack."
				),
			},
		},
		"occurrences": {},
	}
	_write_document("source_registry", SOURCE_REGISTRY_ID, document)
	# Occurrences live in their own `occurrence_audit` document — that is the kind
	# collect_entity_schema_errors reads them from, NOT the source registry's own
	# `occurrences` key, which the zero-content fixtures use and nothing resolves.
	if not _derived_occurrences.is_empty():
		_write_document(
			"occurrence_audit",
			OCCURRENCE_AUDIT_ID,
			{
				"schema_version": 1,
				"kind": "occurrence_audit",
				"id": OCCURRENCE_AUDIT_ID,
				"occurrences": _derived_occurrences,
			}
		)


# Base stat fields, paired with the promotion-bonus key that feeds them. Promoted
# classes ship zeroed bases in the engine because they are only ever REACHED by
# promotion — the unit keeps its own stats and gains these bonuses. A pack class has
# no such history: it must stand alone, and the Tier-2 runtime refuses base_hp or
# base_movement of zero. So a promoted class's bases are DERIVED here as
# base-class bases + promotion bonuses, and every derivation is recorded as an
# occurrence so the number is reviewable rather than silently authored.
const PROMOTION_BONUS_KEYS := {
	"base_hp": "hp",
	"base_strength": "strength",
	"base_magic": "magic",
	"base_defense": "defense",
	"base_resistance": "resistance",
	"base_skill": "skill",
	"base_speed": "speed",
	"base_luck": "luck",
	"base_constitution": "constitution",
}


func _emit_classes() -> void:
	# Two passes: a promoted class's bases are resolved against the class it promotes
	# from, so every class has to be loaded before any is written.
	var by_id := {}
	for path in _resource_paths("res://data/classes"):
		var loaded: Resource = load(path)
		if loaded == null:
			_errors.append("could not load class %s" % path)
			continue
		var loaded_id := str(loaded.get("id"))
		if loaded_id.is_empty():
			_errors.append("class %s has no id" % path)
			continue
		by_id[loaded_id] = loaded

	for key in by_id:
		# Coerced: a Dictionary key is an untyped Variant, and every use below needs a
		# String (the schema id, the occurrence path, begins_with).
		var id := str(key)
		var resource: Resource = by_id[key]
		var derived := _derive_class_bases(id, resource, by_id)
		# Every non-placeholder class reproduces the older corpus's bases/growths/caps
		# per the audit, so the transcribed source is the default for this family and
		# the exceptions are the placeholders.
		var transcribed := not id.begins_with("placeholder")
		var document := {
			"schema_version": 1,
			"kind": "class",
			"id": id,
			"display_name": _display_name(resource, id),
			"source_refs": [SOURCE_TRANSCRIBED if transcribed else SOURCE_PROJECT],
			"tier": int(resource.get("tier")),
			"max_level": int(resource.get("max_level")),
			"base_movement": int(derived.get("base_movement", resource.get("base_movement"))),
			"internal_level_rule": _internal_level_rule(resource),
			"weapon_wexp_bases": _int_map(resource.get("weapon_wexp_bases")),
			"weapon_wexp_caps": _int_map(resource.get("weapon_wexp_caps")),
			"player_growth_rates": _int_map(resource.get("player_growth_rates")),
			"enemy_growth_rates": _int_map(resource.get("enemy_growth_rates")),
			"stat_caps": _int_map(resource.get("stat_caps")),
			# Advancement edges are their own family and the promotion graph needs the
			# edge documents this extraction does not yet emit, so the list is empty
			# and the gap is reported rather than faked with dangling refs.
			"advancement_edge_refs": [],
			"field_completeness": _completeness(transcribed),
		}
		for field in [
			"base_hp",
			"base_strength",
			"base_magic",
			"base_defense",
			"base_resistance",
			"base_skill",
			"base_speed",
			"base_luck",
			"base_constitution",
			"base_line_of_sight",
		]:
			document[field] = int(derived.get(field, resource.get(field)))
		if not derived.is_empty():
			document["occurrence_audit_refs"] = ["derived_promoted_bases_%s" % id]
		var description := str(resource.get("description"))
		if not description.is_empty():
			document["description"] = description
		for field in [
			"allowed_weapon_families", "class_groups", "special_qualities", "vulnerability_groups"
		]:
			var list := _string_list(resource.get(field))
			if not list.is_empty():
				document[field] = list
		var sprite_id := str(resource.get("sprite_id"))
		if not sprite_id.is_empty():
			document["sprite_id"] = sprite_id
			_register_asset(sprite_id, "res://assets/sprites/units/%s.png" % sprite_id)
		if not _string_list(resource.get("promotes_to")).is_empty():
			(
				_gaps
				. append(
					(
						(
							"class '%s' promotes_to %s — advancement_edge documents are not emitted, so the "
							+ "promotion graph is dropped"
						)
						% [id, _string_list(resource.get("promotes_to"))]
					)
				)
			)
		if not _int_map(resource.get("skill_unlocks")).is_empty():
			_gaps.append("class '%s' has skill_unlocks but skills have no Tier-2 kind" % id)
		_write_document("class", id, document)


func _emit_weapons() -> void:
	for path in _resource_paths("res://data/weapons"):
		var resource: Resource = load(path)
		if resource == null:
			_errors.append("could not load weapon %s" % path)
			continue
		var id := str(resource.get("id"))
		if id.is_empty():
			continue
		var transcribed := AUDIT_TRANSCRIBED_WEAPONS.has(id)
		var document := {
			"schema_version": 1,
			"kind": "weapon",
			"id": id,
			"display_name": _display_name(resource, id),
			"source_refs": [SOURCE_TRANSCRIBED if transcribed else SOURCE_PROJECT],
			"combat_family": str(resource.get("combat_family")),
			"wexp_track": str(resource.get("wexp_track")),
			"required_rank": str(resource.get("required_rank")),
			"mt": int(resource.get("mt")),
			"hit": int(resource.get("hit")),
			"crit": int(resource.get("crit")),
			"wt": int(resource.get("wt")),
			"uses": int(resource.get("uses")),
			"cost": int(resource.get("cost")),
			"wexp": int(resource.get("wexp")),
			# Range resolves through the formula registry, so the ids and their
			# parameters are required. Most shipped resources still carry only the
			# legacy literal string, so extraction NORMALIZES through WeaponData's own
			# compatibility adapter rather than inventing a second grammar — a pack is
			# the registered form, and the legacy boundary does not travel with it.
			"range_min_formula_id": _range(resource, "min")["id"],
			"range_min_parameters": _range(resource, "min")["parameters"],
			"range_max_formula_id": _range(resource, "max")["id"],
			"range_max_parameters": _range(resource, "max")["parameters"],
			"field_completeness": _completeness(transcribed),
		}
		for field in ["effect_tags"]:
			var tags := _string_list(resource.get(field))
			if not tags.is_empty():
				document[field] = tags
		var icon := str(resource.get("icon"))
		if not icon.is_empty():
			document["icon"] = icon
			_register_asset(icon, "res://assets/sprites/items/%s.png" % icon)
		_write_document("weapon", id, document)


func _emit_items() -> void:
	for path in _resource_paths("res://data/items"):
		var resource: Resource = load(path)
		if resource == null:
			continue
		var id := str(resource.get("id"))
		if id.is_empty():
			continue
		var document := {
			"schema_version": 1,
			"kind": "item",
			"id": id,
			"display_name": _display_name(resource, id),
			"source_refs": [SOURCE_PROJECT],
			"cost": int(resource.get("cost")),
			"uses": int(resource.get("uses")),
			"field_completeness": _completeness(false),
		}
		_write_document("item", id, document)


# The engine keeps ONE default roster plus a per-map directory of fixed test rosters
# under data/roster/test/<map_id>/. A pack names rosters by id, so each of those
# directories becomes its own `roster_<map_id>` document and the registry rows point
# at them by name instead of at a `roster_source` path.
func _emit_rosters() -> void:
	var directories: Array[String] = ["default"]
	for nested in DirAccess.get_directories_at("res://data/roster/test"):
		directories.append("test/%s" % nested)
	for directory in directories:
		var units: Array = []
		for path in _resource_paths("res://data/roster/%s" % directory):
			var resource: Resource = load(path)
			if resource == null:
				continue
			# UnitData's identity field is `unit_id`, and its label is `unit_name` —
			# NOT the `id`/`display_name` every other family uses. Reading the wrong one
			# gives every unit an empty id, which the roster's unique_key then reports
			# as a duplicate rather than as the missing field it actually is.
			var unit := {
				"unit_id": str(resource.get("unit_id")),
				"class_id": str(resource.get("class_id")),
				"level": int(resource.get("level")),
			}
			var unit_name := str(resource.get("unit_name"))
			if not unit_name.is_empty():
				unit["unit_name"] = unit_name
			for stat in [
				"exp",
				"internal_level",
				"max_hp",
				"hp",
				"strength",
				"magic",
				"defense",
				"resistance",
				"skill",
				"speed",
				"luck",
				"movement",
			]:
				unit[stat] = int(resource.get(stat))
			unit["is_promoted"] = bool(resource.get("is_promoted"))
			units.append(unit)
		if units.is_empty():
			continue
		var roster_id := "roster_%s" % directory.get_file()
		_emitted_roster_ids[roster_id] = true
		_write_document(
			"roster",
			roster_id,
			{
				"schema_version": 1,
				"kind": "roster",
				"id": roster_id,
				"display_name": "%s roster" % directory.get_file().capitalize(),
				"source_refs": [SOURCE_PROJECT],
				"units": units,
				"field_completeness": _completeness(false),
			}
		)


# The engine's seven terrains, written out so the pack is self-contained rather than
# leaning on engine defaults it happens to share today.
func _emit_terrain() -> void:
	var registry: TerrainRegistry = TerrainRegistryScript.engine_defaults()
	for terrain_id in registry.ids():
		var entry := registry.entry(terrain_id)
		_write_document(
			"terrain",
			terrain_id,
			{
				"schema_version": 1,
				"kind": "terrain",
				"id": terrain_id,
				"display_name": registry.display_name(terrain_id),
				"source_refs": [SOURCE_PROJECT],
				"grid_char": str(entry.get("grid_char", "")),
				"move_costs": _int_map(entry.get("move_costs")),
				"def_bonus": int(entry.get("def_bonus", 0)),
				"avoid_bonus": int(entry.get("avoid_bonus", 0)),
				"heal_fraction": float(entry.get("heal_fraction", 0.0)),
				"field_completeness": _completeness(false),
			}
		)


func _emit_maps() -> void:
	for path in _resource_paths("res://data/maps/battle_maps"):
		var resource: Resource = load(path)
		if resource == null:
			continue
		var id := str(resource.get("id"))
		if id.is_empty():
			id = path.get_file().get_basename()
		var grid := _string_list(resource.get("grid"))
		if grid.is_empty():
			_gaps.append("battle map '%s' has no grid and was skipped" % id)
			continue
		var document := {
			"schema_version": 1,
			"kind": "map_data",
			"id": id,
			"display_name": _display_name(resource, id),
			"source_refs": [SOURCE_PROJECT],
			"grid": grid,
			"player_start_tiles": _tile_list(resource.get("player_start_tiles")),
			"field_completeness": _completeness(false),
		}
		_emitted_map_ids[id] = true
		_write_document("map_data", id, document)
	_gaps.append(
		(
			"battle ENCOUNTERS (placements, factions, turn order, objectives, rewards) are not "
			+ "emitted: map_data admits them, but they live on BattleEncounterDef resources whose "
			+ "projection is its own slice"
		)
	)


# The registry is where the pack stops referring to the engine. Engine rows point at
# `res://` resource paths; a pack row names pack-local document ids, because a pack
# that still named engine paths would not be self-contained. Returns encounter_id ->
# map row id so the campaign can be rewired onto it.
func _emit_map_registry() -> Dictionary:
	var by_encounter := {}
	var raw: Variant = _read_json("res://data/maps/map_registry.json")
	if not raw is Array:
		_gaps.append("map_registry.json missing or not an array — registry not emitted")
		return by_encounter
	var rows: Array = []
	for item in raw:
		if not item is Dictionary:
			continue
		var source: Dictionary = item
		var id := str(source.get("id", ""))
		if id.is_empty():
			continue
		# The map document this pack emitted came from the BATTLE map resource, so the
		# row points at that basename rather than at the separate map_data_path.
		var map_data_id := str(source.get("battle_map_path", "")).get_file().get_basename()
		if not _emitted_map_ids.has(map_data_id):
			_gaps.append(
				"map registry row '%s' names map '%s', which was not emitted" % [id, map_data_id]
			)
			continue
		# A fixed test roster lives in its own per-map directory, so the row points at
		# `roster_<map id>` rather than at one shared "test" roster that does not exist.
		var roster_policy := str(source.get("roster_policy", "default_roster"))
		var roster_id := "roster_default"
		if roster_policy == "fixed_test_roster":
			var candidate := (
				"roster_%s" % str(source.get("roster_source", "")).trim_suffix("/").get_file()
			)
			if _emitted_roster_ids.has(candidate):
				roster_id = candidate
			else:
				_gaps.append(
					(
						"map registry row '%s' wants fixed roster '%s', which was not emitted"
						% [id, candidate]
					)
				)
		(
			rows
			. append(
				{
					"id": id,
					"label": str(source.get("label", id)),
					"map_data_id": map_data_id,
					"roster_id": roster_id,
				}
			)
		)
		by_encounter[str(source.get("encounter_id", ""))] = id
	if rows.is_empty():
		return by_encounter
	_write_document("map_registry", "proving_grounds_maps", rows)
	return by_encounter


func _emit_campaigns() -> void:
	for path in _json_paths("res://data/campaigns"):
		if path.ends_with("resource_manifest.json"):
			continue
		var raw: Variant = _read_json(path)
		if not raw is Dictionary:
			continue
		var source: Dictionary = raw
		var id := str(source.get("campaign_id", ""))
		if id.is_empty():
			continue
		var document := source.duplicate(true)
		document["schema_version"] = 1
		document["kind"] = "campaign"
		document["id"] = id
		document["display_name"] = str(source.get("label", id))
		document["source_refs"] = [SOURCE_PROJECT]
		# Engine campaign nodes bind by `encounter_id`; a Tier-2 node binds by `map_id`
		# resolving in the pack's own map_registry. Translate rather than emit both, or
		# the pack would carry two bindings that can drift.
		if document.get("nodes", null) is Array:
			for node in document["nodes"]:
				if not node is Dictionary:
					continue
				var encounter := str((node as Dictionary).get("encounter_id", ""))
				if _map_ids_by_encounter.has(encounter):
					(node as Dictionary)["map_id"] = str(_map_ids_by_encounter[encounter])
					(node as Dictionary).erase("encounter_id")
				else:
					_gaps.append(
						(
							"campaign '%s' node '%s' names encounter '%s' with no registry row"
							% [id, (node as Dictionary).get("node_id", ""), encounter]
						)
					)
		_write_document("campaign", id, document)


# Only the media the emitted documents actually named. Each record carries the real
# byte size and digest, because `collect_asset_integrity_errors` verifies them
# against the file rather than trusting the record.
func _emit_assets() -> void:
	var assets := {}
	for logical_id in _asset_records:
		var source_path := str(_asset_records[logical_id])
		var bytes := FileAccess.get_file_as_bytes(source_path)
		if bytes.is_empty():
			_gaps.append(
				(
					"asset '%s' not found at %s — reference emitted without media"
					% [logical_id, source_path]
				)
			)
			continue
		var relative := "assets/%s.png" % logical_id
		var destination := _out_root.path_join(relative)
		DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
		var out := FileAccess.open(destination, FileAccess.WRITE)
		if out == null:
			_errors.append("cannot write asset %s" % destination)
			continue
		out.store_buffer(bytes)
		out.close()
		assets[logical_id] = {
			"path": relative,
			"decoded_type": "image/png",
			"byte_size": bytes.size(),
			"sha256": _sha256(bytes),
			"original_filename": source_path.get_file(),
		}
	if assets.is_empty():
		return
	_write_document(
		"asset_registry",
		ASSET_REGISTRY_ID,
		{
			"schema_version": 1,
			"kind": "asset_registry",
			"id": ASSET_REGISTRY_ID,
			"assets": assets,
		}
	)


# --- gaps --------------------------------------------------------------------


# Stated once, loudly. A pack that silently omits a family looks complete and is not.
func _record_gaps() -> void:
	_gaps.append(
		"skills (data/skills, 55 resources) have NO registered Tier-2 kind and are not emitted"
	)
	_gaps.append("pair_up bonus table has no registered Tier-2 kind and is not emitted")
	_gaps.append(
		(
			"engine registries (action_primitives, item_effects, objective_conditions, "
			+ "occupancy_policies, resource_types) are engine primitives, not pack content — "
			+ "confirm that boundary before the public pack ships"
		)
	)


# --- output ------------------------------------------------------------------


# `document` is Variant, not Dictionary: a map_registry document is an ARRAY of map
# rows, which is the shape _validate_map_registry requires.
func _write_document(kind: String, id: String, document: Variant) -> void:
	var relative := "data/%s__%s.json" % [kind, id]
	var absolute := _out_root.path_join(relative)
	var file := FileAccess.open(absolute, FileAccess.WRITE)
	if file == null:
		_errors.append("cannot write %s" % absolute)
		return
	file.store_string(JSON.stringify(document, "  ", true) + "\n")
	file.close()
	_catalogue.append({"kind": kind, "id": id, "path": relative, "schema_version": 1})


func _write_catalogue() -> void:
	# Sorted so a re-run of the same content produces byte-identical output; the pack
	# fingerprint depends on it.
	_catalogue.sort_custom(func(a, b): return str(a["path"]) < str(b["path"]))
	var entries: Array = []
	for entry in _catalogue:
		entries.append(entry)
	# `format_version`, like the manifest's — the zero-content fixtures' "schema_version"
	# spelling predates Tier2Catalogue.parse and is rejected by it.
	var file := FileAccess.open(_out_root.path_join("data/catalogue.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"format_version": 1, "entries": entries}, "  ", true) + "\n")
	file.close()


func _write_manifest() -> void:
	# Field names come from PackManifest.parse, NOT from the zero-content test
	# fixtures — those use an older package_id/package_version spelling that the
	# runtime manifest parser rejects.
	var manifest := {
		"id": _package_id,
		"version": "0.1.0",
		"builder_content_version": "0.1.0",
		"format_version": 1,
		"display_name": "The Proving Grounds (internal extraction)",
		# private_only until the provenance pass clears the transcribed source. The
		# manifest is the enforcement point a distribution check reads.
		"distribution_policy": "private_only",
		"authoring_status": "draft",
		"default_enabled": false,
		"catalogue_path": "data/catalogue.json",
	}
	var file := FileAccess.open(_out_root.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "  ", true) + "\n")
	file.close()


# --- helpers -----------------------------------------------------------------


func _resource_paths(directory: String) -> Array[String]:
	var out: Array[String] = []
	if not DirAccess.dir_exists_absolute(directory):
		return out
	for file in DirAccess.get_files_at(directory):
		# Exported builds rename .tres to .remap; the editor-side extraction only ever
		# sees .tres, but strip both so a packed run does not silently emit nothing.
		if file.ends_with(".tres") or file.ends_with(".tres.remap"):
			out.append(directory.path_join(file.trim_suffix(".remap")))
	out.sort()
	return out


func _json_paths(directory: String) -> Array[String]:
	var out: Array[String] = []
	if not DirAccess.dir_exists_absolute(directory):
		return out
	for file in DirAccess.get_files_at(directory):
		if file.ends_with(".json"):
			out.append(directory.path_join(file))
	out.sort()
	return out


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _display_name(resource: Resource, fallback: String) -> String:
	var name := str(resource.get("display_name"))
	return name if not name.is_empty() else fallback.capitalize()


# The schema admits only "base" or "promoted"; a resource that left it blank gets the
# tier's answer rather than an invalid document.
func _internal_level_rule(resource: Resource) -> String:
	var rule := str(resource.get("internal_level_rule"))
	if rule == "base" or rule == "promoted":
		return rule
	return "promoted" if int(resource.get("tier")) > 1 else "base"


func _int_map(value: Variant) -> Dictionary:
	var out := {}
	if value is Dictionary:
		for key in value:
			out[str(key)] = int((value as Dictionary)[key])
	return out


func _string_list(value: Variant) -> Array:
	var out: Array = []
	if value is Array:
		for item in value:
			out.append(str(item))
	return out


# The map schema admits a tile as a two-integer array, not an {x, y} object.
func _tile_list(value: Variant) -> Array:
	var out: Array = []
	if value is Array:
		for item in value:
			if item is Vector2i:
				out.append([(item as Vector2i).x, (item as Vector2i).y])
	return out


# The admitted vocabulary is verified | unverified | not_applicable — there is no
# "unchecked", so a transcribed row is `unverified` (known-good for play,
# known-unresolved for rights) and project-original content is `not_applicable`.
# Neither is ever `verified` here: extraction moves numbers, it does not clear them.
func _completeness(transcribed: bool) -> Dictionary:
	return {"provenance": "unverified" if transcribed else "not_applicable"}


# Records that an emitted document named this media. The registry is built from the
# union of these calls, so a pack never ships art nothing references.
func _register_asset(logical_id: String, source_path: String) -> void:
	if logical_id.is_empty():
		return
	_asset_records[logical_id] = source_path


# Resolves one end of a weapon's range to its REGISTERED form. Prefers an authored
# formula id; falls back to WeaponData's legacy adapter so a resource that only ever
# had "1" or "MAG/2" still emits a valid registered descriptor.
func _range(resource: Resource, end: String) -> Dictionary:
	var authored_id := str(resource.get("range_%s_formula_id" % end))
	if not authored_id.is_empty():
		return {
			"id": authored_id,
			"parameters": _int_map(resource.get("range_%s_parameters" % end)),
		}
	var legacy := str(resource.get("range_%s_formula" % end))
	var adapted: Dictionary = WeaponDataScript._adapt_legacy_range(legacy)
	if adapted.is_empty():
		_errors.append(
			(
				"weapon %s has an unrecognised legacy range formula '%s'"
				% [str(resource.get("id")), legacy]
			)
		)
		return {"id": "literal", "parameters": {"value": 1}}
	return {"id": str(adapted["id"]), "parameters": _int_map(adapted["parameters"])}


# Returns the derived base fields for a promoted class, or {} when the class already
# carries its own. A class that promotes from several parents uses the first, which is
# the only deterministic choice available and is recorded in the occurrence note.
func _derive_class_bases(id: String, resource: Resource, by_id: Dictionary) -> Dictionary:
	if int(resource.get("base_hp")) > 0 and int(resource.get("base_movement")) > 0:
		return {}
	var parents := _string_list(resource.get("promotes_from"))
	if parents.is_empty():
		_gaps.append(
			"class '%s' has zero bases and no promotes_from, so it cannot be made standalone" % id
		)
		return {}
	var parent_id := str(parents[0])
	if not by_id.has(parent_id):
		_gaps.append("class '%s' promotes_from unknown class '%s'" % [id, parent_id])
		return {}
	var parent: Resource = by_id[parent_id]
	var bonuses := _int_map(resource.get("promotion_stat_bonuses"))
	var derived := {}
	for field in PROMOTION_BONUS_KEYS:
		var bonus: int = int(bonuses.get(PROMOTION_BONUS_KEYS[field], 0))
		derived[field] = int(parent.get(field)) + bonus
	# Movement and line of sight are not promotion bonuses; they carry over unchanged.
	derived["base_movement"] = int(parent.get("base_movement"))
	derived["base_line_of_sight"] = int(parent.get("base_line_of_sight"))
	# The occurrence must name the document by "kind:id", carry a `source_ref` that
	# also appears in that document's own source_refs, and a `field_path` that is a
	# real JSON pointer INTO the document — the validator resolves all three.
	_derived_occurrences["derived_promoted_bases_%s" % id] = {
		"document_ref": "class:%s" % id,
		"source_ref": SOURCE_TRANSCRIBED,
		"field_path": "/base_hp",
		"state": "transformed",
		"source_value": "zeroed bases; promotes_from %s" % [parents],
		"canonical_value": derived.duplicate(),
		"author_notes":
		(
			(
				"Engine promoted classes ship zeroed bases because promotion applies bonuses to "
				+ "the unit's own stats. A pack class must stand alone, so these are "
				+ "'%s' bases plus promotion_stat_bonuses. Balance-affecting: review before "
				+ "this pack is used for tuning."
			)
			% parent_id
		),
	}
	return derived


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
