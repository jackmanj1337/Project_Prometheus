extends SceneTree
# Validates an on-disk campaign pack through the SAME path activation takes —
# DataManager.select_tier2_campaign_source() — rather than a second, weaker copy of
# the rules. If this passes, the pack activates.
#
# It reports PLAYABILITY separately, because activating is not playing: a map with no
# enemies and no victory condition passes every rule the validators own and still puts
# the player on an empty board with nothing to win. That was the state the first
# extraction shipped in, so the tool now says it out loud.
#
#   godot --headless --path . --script res://scripts/tools/validate_pack.gd -- --pack /abs/path
#     [--require-playable]   exit non-zero when a map cannot be played to a result

const CampaignTier2RuntimeAdapter = preload(
	"res://scripts/resources/CampaignTier2RuntimeAdapter.gd"
)
const DataManagerScript = preload("res://scripts/autoloads/DataManager.gd")
const FeatureCoverage = preload("res://scripts/tools/PackFeatureCoverage.gd")


func _init() -> void:
	var pack := ""
	var require_playable := false
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--pack" and i + 1 < args.size():
			pack = args[i + 1]
		elif args[i] == "--require-playable":
			require_playable = true
	if pack.is_empty():
		printerr("--pack is required")
		quit(2)
		return

	var manifest_raw: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(pack.path_join("manifest.json"))
	)
	if not manifest_raw is Dictionary:
		printerr("no readable manifest.json at %s" % pack)
		quit(2)
		return
	var manifest: Dictionary = manifest_raw
	var package_id := str(manifest.get("id", ""))
	var package_version := str(manifest.get("version", ""))
	var authoring_status := str(manifest.get("authoring_status", "draft"))

	var adapted = CampaignTier2RuntimeAdapter.load(pack, package_id, package_version)
	print("=== pack validation: %s ===" % pack)
	print("adapter valid: %s" % adapted.valid)
	print(
		(
			"classes=%d weapons=%d items=%d maps=%d rosters=%d campaigns=%d terrain=%d variants=%d assets=%d"
			% [
				adapted.classes.size(),
				adapted.weapons.size(),
				adapted.items.size(),
				adapted.maps.size(),
				adapted.rosters.size(),
				adapted.campaigns.size(),
				adapted.terrain.size(),
				adapted.terrain_variants.size(),
				adapted.assets.size(),
			]
		)
	)
	if not adapted.valid:
		_print_errors(adapted.errors)
		quit(1)
		return

	# The adapter proves shape and cross-references. Map SEMANTICS — tile bounds,
	# terrain codes, faction coherence, duplicate unit ids, objective validity — are
	# only checked when DataManager activates, so the tool activates.
	var data_manager := DataManagerScript.new()
	var activated: bool = data_manager.select_tier2_campaign_source(
		pack, package_id, package_version
	)
	print("activates: %s" % activated)
	if not activated:
		_print_errors(data_manager.content_status()["errors"])
		data_manager.free()
		quit(1)
		return

	_print_warnings(FeatureCoverage.warnings(authoring_status, adapted))

	var unplayable := _report_playability(data_manager, adapted)
	data_manager.free()
	if not unplayable.is_empty() and require_playable:
		quit(1)
		return
	quit(0)


# Per map: what a player would find on it. A map is playable when something opposes
# them and some condition ends the battle — the two facts the encounter carries and
# the two a terrain-only extraction silently drops. Returns the unplayable map ids.
func _report_playability(data_manager, adapted) -> Array:
	var unplayable: Array = []
	var map_ids: Array = adapted.maps.keys()
	map_ids.sort()
	print("--- playability ---")
	for map_id in map_ids:
		var battle: ResolvedBattleData = data_manager.resolve_battle_source(
			CampaignTier2RuntimeAdapter.map_uri(
				adapted.package_id, adapted.package_version, str(map_id)
			)
		)
		if battle == null or battle.encounter == null:
			print("  %-32s UNRESOLVED" % map_id)
			unplayable.append(map_id)
			continue
		var encounter: BattleEncounterDef = battle.encounter
		var reasons: Array[String] = []
		if encounter.enemy_placements.is_empty():
			reasons.append("no enemies")
		if encounter.victory_conditions.is_empty():
			reasons.append("no victory condition")
		if battle.battle_map.player_start_tiles.is_empty():
			reasons.append("no player start tiles")
		# A unit with no weapon the pack can resolve cannot attack. Both sides are
		# checked: enemies that cannot fight make a map a walk, and a roster that
		# cannot fight makes it unwinnable — and neither breaks any validation rule,
		# which is exactly how an inventory dropped in extraction stayed invisible.
		var unarmed_enemies := _unarmed(_placement_units(encounter), adapted)
		if not unarmed_enemies.is_empty():
			reasons.append("%d enemy/enemies cannot attack" % unarmed_enemies.size())
		print(
			(
				"  %-32s enemies=%2d factions=%d victory=%d defeat=%d %s"
				% [
					map_id,
					encounter.enemy_placements.size(),
					encounter.factions.size(),
					encounter.victory_conditions.size(),
					encounter.defeat_conditions.size(),
					"OK" if reasons.is_empty() else "NOT PLAYABLE: %s" % ", ".join(reasons),
				]
			)
		)
		if not reasons.is_empty():
			unplayable.append(map_id)
	print("playable maps: %d/%d" % [adapted.maps.size() - unplayable.size(), adapted.maps.size()])
	var roster_ids: Array = adapted.rosters.keys()
	roster_ids.sort()
	for roster_id in roster_ids:
		var unarmed := _unarmed(adapted.rosters[roster_id], adapted)
		print(
			(
				"  roster %-24s units=%2d %s"
				% [
					roster_id,
					adapted.rosters[roster_id].size(),
					"OK" if unarmed.is_empty() else "cannot attack: %s" % ", ".join(unarmed),
				]
			)
		)
	return unplayable


# The units standing on a map, whichever spawn source the placement used.
func _placement_units(encounter: BattleEncounterDef) -> Array:
	var units: Array = []
	for placement in encounter.enemy_placements:
		if placement is Dictionary and placement.get("unit_data") is UnitData:
			units.append(placement["unit_data"])
	return units


# Unit ids carrying no weapon slot that resolves in the pack's own weapon set. A
# staff healer counts as armed: it holds a weapon document and acts with it.
func _unarmed(units: Array, adapted) -> Array:
	var unarmed: Array = []
	for unit in units:
		if not unit is UnitData:
			continue
		var armed := false
		for entry in unit.inventory:
			if entry != null and entry.is_weapon() and adapted.weapons.has(entry.weapon_id):
				armed = true
				break
		if not armed:
			unarmed.append(unit.unit_id)
	return unarmed


func _print_errors(errors: Array) -> void:
	print("--- %d error(s) ---" % errors.size())
	var shown := 0
	for error in errors:
		print("  %s" % error)
		shown += 1
		if shown >= 40:
			print("  … %d more" % (errors.size() - shown))
			return


func _print_warnings(warnings: Array) -> void:
	if warnings.is_empty():
		return
	print("--- %d warning(s) ---" % warnings.size())
	for warning in warnings:
		print("  WARNING: %s" % warning)
