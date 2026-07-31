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
			"units":
			[
				{
					"unit_id": "hero",
					"unit_name": "Hero",
					"class_id": "fixture_class",
				}
			]
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
			"variants": [],
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
