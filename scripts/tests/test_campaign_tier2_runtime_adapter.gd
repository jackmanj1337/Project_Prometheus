extends SceneTree
# Validated Tier-2 JSON activates as existing engine Resource types in memory.

const Adapter = preload("res://scripts/resources/CampaignTier2RuntimeAdapter.gd")
const DataManagerScript = preload("res://scripts/autoloads/DataManager.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const ROOT := "runtime-pack"


func _init() -> void:
	print("=== Campaign Tier-2 Runtime Adapter Test ===")
	var passed := 0
	var failed := 0
	var scratch := "user://test_campaign_tier2_runtime_adapter"
	Installer._remove_tree(scratch)
	var pack := scratch.path_join("installed/%s/1.0" % ROOT)
	_write_pack(pack)

	var adapted = Adapter.load(pack, ROOT, "1.0")
	var map_uri := Adapter.map_uri(ROOT, "1.0", "map_01")
	if (
		adapted.valid
		and adapted.campaigns.has("fixture")
		and adapted.map_registry["map_01"]["map_data_path"] == map_uri
		and adapted.map_registry["map_01"]["roster_policy"] == "campaign_pack_roster"
		and adapted.advancement_edges.has("fixture_promotion")
		and adapted.advancement_routes.has("level_route")
	):
		print("OK  manifest/catalogue becomes a stable package-scoped launch graph")
		passed += 1
	else:
		print("FAIL runtime graph: %s" % [adapted.errors])
		failed += 1

	var map: MapData = adapted.maps.get("map_01")
	var roster: Array = adapted.rosters.get("heroes", [])
	if (
		map != null
		and map.grid == ["..."]
		and map.player_start_tiles == [Vector2i(0, 0)]
		and roster.size() == 1
		and roster[0] is UnitData
		and roster[0].hp == 20
		and roster[0].movement == 5
	):
		print("OK  JSON map, class bases, and roster adapt to engine Resource types")
		passed += 1
	else:
		print(
			(
				"FAIL runtime resources: grid=%s starts=%s hp=%s move=%s"
				% [
					map.grid if map else null,
					map.player_start_tiles if map else null,
					roster[0].hp if not roster.is_empty() else null,
					roster[0].movement if not roster.is_empty() else null
				]
			)
		)
		failed += 1

	# A validated weapon document must produce the same range/equip/combat inputs the
	# JSON authored — including the Array[String] and registered-formula fields that a
	# plain property copy would silently drop or leave unevaluated.
	var weapon: WeaponData = adapted.weapons.get("fixture_blade")
	if (
		weapon != null
		and weapon.mt == 8
		and weapon.hit == 85
		and weapon.crit == 5
		and weapon.wt == 6
		and weapon.uses == 30
		and weapon.wexp == 2
		and weapon.strikes_per_attack == 2
		and weapon.combat_family == "sword"
		and weapon.wexp_track == "sword"
		and weapon.required_rank == "E"
		and weapon.get_triangle_family() == "sword"
		and weapon.effect_tags == ["effective_armoured"]
		and weapon.get_range_min() == 1
		and weapon.get_range_max() == 2
		and not roster.is_empty()
		and roster[0].inventory.size() == 1
		and roster[0].inventory[0].weapon_id == "fixture_blade"
	):
		print("OK  a registered weapon adapts to the same runtime combat inputs")
		passed += 1
	else:
		print(
			(
				"FAIL weapon adoption: tags=%s range=%s..%s strikes=%s"
				% [
					weapon.effect_tags if weapon else null,
					weapon.get_range_min() if weapon else null,
					weapon.get_range_max() if weapon else null,
					weapon.strikes_per_attack if weapon else null,
				]
			)
		)
		failed += 1

	# A registered roster must reach UnitData with nothing silently dropped. The typed
	# `Array[String]` exports and the JSON-float stat maps are the two fields a plain
	# property copy loses without saying so, and the durable selections are what a
	# save round-trip has to restore.
	var hero: UnitData = roster[0] if not roster.is_empty() else null
	if (
		hero != null
		and hero.skills == ["canto"]
		and hero.reclass_options == ["fixture_elite"]
		and typeof(hero.weapon_wexp.get("sword")) == TYPE_INT
		and hero.weapon_wexp["sword"] == 31
		and hero.level == 3
		and hero.class_variant_id == "veteran"
		and hero.advancement_edge_id == "fixture_promotion"
		and hero.advancement_edge_variant_id == "swift_promotion"
		and hero.inventory[0].weapon_variant_id == "reforged"
	):
		print("OK  a registered roster adapts without dropping typed arrays or selections")
		passed += 1
	else:
		print(
			(
				"FAIL roster adoption: skills=%s reclass=%s wexp=%s variant=%s slot=%s"
				% [
					hero.skills if hero else null,
					hero.reclass_options if hero else null,
					hero.weapon_wexp if hero else null,
					hero.class_variant_id if hero else null,
					hero.inventory[0].weapon_variant_id if hero else null,
				]
			)
		)
		failed += 1

	# A durable selection whose target disappeared is the one failure the save layer
	# cannot repair, so whole-pack validation must reject it before activation.
	var dangling := scratch.path_join("dangling")
	_write_pack(dangling)
	_write_bytes(
		dangling.path_join("data/roster.json"),
		(
			JSON
			. stringify(
				{
					"kind": "roster",
					"schema_version": 1,
					"id": "heroes",
					"display_name": "Heroes",
					"source_refs": ["fixture_design"],
					"units":
					[
						{
							"unit_id": "hero",
							"class_id": "fixture_class",
							"class_variant_id": "retired",
							"inventory":
							[
								{
									"weapon_id": "fixture_blade",
									"uses": 30,
									"weapon_variant_id": "unforged",
								}
							],
						}
					],
				}
			)
			. to_utf8_buffer()
		)
	)
	var dangling_result = Adapter.load(dangling, ROOT, "1.0")
	var dangling_text := "\n".join(dangling_result.errors)
	if (
		not dangling_result.valid
		and "references missing class variant 'retired'" in dangling_text
		and "references missing weapon variant 'unforged'" in dangling_text
	):
		print("OK  durable selections that no longer resolve reject the pack")
		passed += 1
	else:
		print("FAIL dangling selection response: %s" % [dangling_result.errors])
		failed += 1

	var dm := DataManagerScript.new()
	if (
		dm.select_tier2_campaign_source(pack, ROOT, "1.0")
		and dm.active_package_identity()["package_id"] == ROOT
		and dm.resolve_map_data(map_uri) is MapData
		and dm.get_campaign_pack_roster("heroes").size() == 1
	):
		print("OK  DataManager atomically selects and resolves the Tier-2 source")
		passed += 1
	else:
		print("FAIL DataManager Tier-2 selection")
		failed += 1
	dm.free()

	var bad_pack := scratch.path_join("bad")
	_write_pack(bad_pack, 0)
	var live_dm := DataManagerScript.new()
	live_dm.select_tier2_campaign_source(pack, ROOT, "1.0")
	var before := live_dm.active_package_identity()
	var rejected := live_dm.select_tier2_campaign_source(bad_pack, ROOT, "1.0")
	if (
		not rejected
		and live_dm.active_package_identity() == before
		and live_dm.has_campaign("fixture")
	):
		print("OK  invalid activation preserves the previously selected registries")
		passed += 1
	else:
		print("FAIL atomic selection preservation")
		failed += 1
	live_dm.deactivate_campaign_package()
	if (
		live_dm.content_state() == DataManagerScript.ContentState.INACTIVE
		and live_dm.active_package_identity()["package_id"] == ""
		and not live_dm.has_campaign("fixture")
	):
		print("OK  package deactivation restores a valid empty catalogue")
		passed += 1
	else:
		print("FAIL package deactivation")
		failed += 1
	live_dm.free()

	Installer._remove_tree(scratch)
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _write_pack(root: String, base_hp: int = 20) -> void:
	var files := {
		"manifest.json":
		{
			"id": ROOT,
			"version": "1.0",
			"forked_from": "",
			"builder_content_version": "0.4",
			"format_version": 1,
		},
		"data/catalogue.json":
		{
			"format_version": 1,
			"entries":
			[
				{"kind": "campaign", "id": "fixture", "path": "data/campaign.json"},
				{"kind": "map_registry", "id": "maps", "path": "data/map_registry.json"},
				{"kind": "map_data", "id": "map_01", "path": "data/map_01.json"},
				{"kind": "roster", "id": "heroes", "path": "data/roster.json"},
				{"kind": "class", "id": "fixture_class", "path": "data/class.json"},
				{"kind": "class", "id": "fixture_elite", "path": "data/elite.json"},
				{"kind": "advancement_edge", "id": "fixture_promotion", "path": "data/edge.json"},
				{"kind": "advancement_route", "id": "level_route", "path": "data/route.json"},
				{"kind": "weapon", "id": "fixture_blade", "path": "data/weapon.json"},
				{"kind": "source_registry", "id": "fixture_sources", "path": "data/sources.json"},
			],
		},
		"data/campaign.json":
		{
			"campaign_id": "fixture",
			"label": "Fixture",
			"start_node_id": "start",
			"nodes": [{"node_id": "start", "label": "Start", "map_id": "map_01", "next": []}],
		},
		"data/map_registry.json":
		[
			{
				"id": "map_01",
				"label": "Map",
				"map_data_id": "map_01",
				"roster_id": "heroes",
			}
		],
		"data/map_01.json":
		{
			"id": "map_01",
			"display_name": "Map",
			"grid": ["..."],
			"player_start_tiles": [[0, 0]],
		},
		"data/roster.json":
		{
			"kind": "roster",
			"schema_version": 1,
			"id": "heroes",
			"display_name": "Heroes",
			"source_refs": ["fixture_design"],
			"units":
			[
				{
					"unit_id": "hero",
					"unit_name": "Hero",
					"class_id": "fixture_class",
					# Durable authored selections; each must resolve against the document
					# that owns the variant, and survive the campaign save round-trip.
					"class_variant_id": "veteran",
					"advancement_edge_id": "fixture_promotion",
					"advancement_edge_variant_id": "swift_promotion",
					"level": 3,
					"skills": ["canto"],
					"reclass_options": ["fixture_elite"],
					"weapon_wexp": {"sword": 31},
					"growth_rates": {"hp": 60},
					"ai_profile": "basic",
					"inventory":
					[
						{
							"weapon_id": "fixture_blade",
							"uses": 30,
							"weapon_variant_id": "reforged",
						}
					],
				}
			],
		},
		"data/weapon.json":
		{
			"kind": "weapon",
			"schema_version": 1,
			"id": "fixture_blade",
			"display_name": "Fixture Blade",
			"source_refs": ["fixture_design"],
			"combat_family": "sword",
			"wexp_track": "sword",
			"required_rank": "E",
			"mt": 8,
			"hit": 85,
			"crit": 5,
			"wt": 6,
			"uses": 30,
			"cost": 480,
			"wexp": 2,
			"effect_tags": ["effective_armoured"],
			"strikes_per_attack": 2,
			"uses_mag": false,
			"range_min_formula_id": "literal",
			"range_min_parameters": {"value": 1},
			"range_max_formula_id": "literal",
			"range_max_parameters": {"value": 2},
			"field_completeness": {"mt": "verified"},
			"variants":
			[
				{
					"variant_id": "reforged",
					"eligibility":
					{
						"handler_id": "fact_contains_v1",
						"schema_version": 1,
						"parameters": {"fact_id": "forge", "value": "reforged"},
					},
					"overrides": {"mt": 10},
				}
			],
		},
		"data/class.json":
		{
			"kind": "class",
			"schema_version": 1,
			"id": "fixture_class",
			"display_name": "Fixture",
			"source_refs": ["fixture_design"],
			"tier": 1,
			"max_level": 20,
			"base_hp": base_hp,
			"base_movement": 5,
			"internal_level_rule": "base",
			"weapon_wexp_bases": {},
			"weapon_wexp_caps": {},
			"player_growth_rates": {},
			"enemy_growth_rates": {},
			"stat_caps": {},
			"field_completeness": {},
			"advancement_edge_refs": ["fixture_promotion"],
			"variants":
			[
				{
					"variant_id": "veteran",
					"eligibility":
					{
						"handler_id": "fact_contains_v1",
						"schema_version": 1,
						"parameters": {"fact_id": "training", "value": "veteran"},
					},
					"overrides": {"base_movement": 6},
				}
			],
		},
		"data/elite.json":
		{
			"kind": "class",
			"schema_version": 1,
			"id": "fixture_elite",
			"display_name": "Fixture Elite",
			"source_refs": ["fixture_design"],
			"tier": 2,
			"max_level": 20,
			"base_hp": 25,
			"base_movement": 6,
			"internal_level_rule": "promoted",
			"weapon_wexp_bases": {},
			"weapon_wexp_caps": {},
			"player_growth_rates": {},
			"enemy_growth_rates": {},
			"stat_caps": {},
			"field_completeness": {},
			"advancement_edge_refs": [],
		},
		"data/edge.json":
		{
			"kind": "advancement_edge",
			"schema_version": 1,
			"id": "fixture_promotion",
			"display_name": "Fixture Promotion",
			"source_refs": ["fixture_design"],
			"source_class_ref": "fixture_class",
			"destination_class_refs": ["fixture_elite"],
			"route_refs": ["level_route"],
			"transition":
			{"handler_id": "class_advancement_v1", "schema_version": 1, "parameters": {}},
			"stat_gains": {"strength": 2},
			"weapon_wexp_grants": {},
			"variants":
			[
				{
					"variant_id": "swift_promotion",
					"eligibility":
					{
						"handler_id": "fact_contains_v1",
						"schema_version": 1,
						"parameters": {"fact_id": "training", "value": "swift"},
					},
					"overrides": {"stat_gains": {"speed": 2}},
				}
			],
		},
		"data/route.json":
		{
			"kind": "advancement_route",
			"schema_version": 1,
			"id": "level_route",
			"display_name": "Level Route",
			"source_refs": ["fixture_design"],
			"trigger":
			{"handler_id": "class_advancement_v1", "schema_version": 1, "parameters": {}},
			"requirements": [],
			"cost": {"handler_id": "class_advancement_v1", "schema_version": 1, "parameters": {}},
			"selection":
			{"handler_id": "class_advancement_v1", "schema_version": 1, "parameters": {}},
			"transition":
			{"handler_id": "class_advancement_v1", "schema_version": 1, "parameters": {}},
			"priority": 0,
		},
		"data/sources.json":
		{
			"kind": "source_registry",
			"schema_version": 1,
			"id": "fixture_sources",
			"sources": {"fixture_design": {"locator": "internal://runtime-test"}},
		},
	}
	for relative in files:
		_write_bytes(root.path_join(relative), JSON.stringify(files[relative]).to_utf8_buffer())


func _write_bytes(path: String, bytes: PackedByteArray) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)
