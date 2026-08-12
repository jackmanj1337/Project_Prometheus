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
	if (
		adapted.registry_entries.size() == 5
		and adapted.registry_entries[0] is Resource
		and adapted.registry_entries.any(
			func(entry): return entry.family == "item_effects" and entry.id == "fixture_item"
		)
	):
		print("OK  trusted registry documents adapt without executable handlers")
		passed += 1
	else:
		print("FAIL registry entries: %s" % [adapted.registry_entries])
		failed += 1
	var untrusted_registry := scratch.path_join("untrusted-registry")
	_write_pack(untrusted_registry)
	var registry_path := untrusted_registry.path_join("data/registry_action_primitives.json")
	var registry_document: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(registry_path)
	)
	registry_document["primitive_handler"] = "pack_supplied_code"
	_write_bytes(registry_path, JSON.stringify(registry_document).to_utf8_buffer())
	var untrusted_result = Adapter.load(untrusted_registry, ROOT, "1.0")
	if (
		not untrusted_result.valid
		and "vocabulary_value_unknown" in "\n".join(untrusted_result.errors)
	):
		print("OK  a pack cannot introduce an executable primitive handler")
		passed += 1
	else:
		print("FAIL untrusted handler response: %s" % [untrusted_result.errors])
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
		and roster[0].inventory.size() == 2
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
		and hero.skills == ["fixture_vantage"]
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

	# A registered item must reach `ItemData` with its effect parameters usable. JSON
	# decodes every number as a float, so an unconverted `amount` would arrive as 10.0
	# and compare unequal to the integer the effect handlers expect.
	var vulnerary: ItemData = adapted.items.get("fixture_vulnerary")
	var item_slot: InventoryEntry = (
		roster[0].inventory[1] if not roster.is_empty() and roster[0].inventory.size() > 1 else null
	)
	if (
		vulnerary != null
		and vulnerary.item_type == "healing"
		and vulnerary.uses == 3
		and vulnerary.cost == 300
		and vulnerary.effect_id == "heal_flat"
		and typeof(vulnerary.effect_params.get("amount")) == TYPE_INT
		and vulnerary.effect_params["amount"] == 10
		and item_slot != null
		and item_slot.is_item()
		and item_slot.item_id == "fixture_vulnerary"
		and item_slot.uses_remaining == 3
	):
		print("OK  a registered item adapts and fills an item inventory slot")
		passed += 1
	else:
		print(
			(
				"FAIL item adoption: params=%s slot=%s"
				% [
					vulnerary.effect_params if vulnerary else null,
					item_slot.entry_type if item_slot else null,
				]
			)
		)
		failed += 1

	# A registered map must reach MapData with the encounter intact. `factions` is the
	# field that was never built at all before this family — it is an
	# `Array[FactionData]` export, so the plain property copy left it empty and an
	# authored faction list silently became the blue+red default.
	var placement: Dictionary = (
		map.enemy_placements[0] if map != null and not map.enemy_placements.is_empty() else {}
	)
	if (
		map != null
		and map.factions.size() == 2
		and map.factions[0] is FactionData
		and map.factions[0].id == "blue"
		and map.factions[0].alliance_group == "allies"
		and is_equal_approx(map.factions[0].color.b, 0.9)
		and map.get_faction("red") != null
		and map.turn_order == ["blue", "red"]
		and map.activation_mode == "WHOLE_PHASE"
		and map.camera_start_tile == Vector2i(1, 0)
		and map.reward_gold == 500
		and map.reward_items == ["fixture_vulnerary"]
	):
		print("OK  a registered map adapts its factions, turn order, and rewards")
		passed += 1
	else:
		print(
			(
				"FAIL map adoption: factions=%s turn_order=%s rewards=%s"
				% [
					map.factions.size() if map else null,
					map.turn_order if map else null,
					map.reward_items if map else null,
				]
			)
		)
		failed += 1

	if (
		placement.get("unit_data") is UnitData
		and placement["unit_data"].unit_id == "brigand"
		and placement["tile"] == Vector2i(2, 0)
		and placement["faction"] == "red"
		and placement["is_boss"]
		and placement["ai_profile"] == "hunter"
		and map.victory_conditions.has("allies")
		and map.victory_conditions["allies"][0] is ObjectiveCondition
		and map.victory_conditions["allies"][0].type == "rout"
		and map.defeat_conditions["allies"][0].turns == 20
	):
		print("OK  inline enemy placements and objective groups adapt as engine types")
		passed += 1
	else:
		print("FAIL placement/objective adoption: %s" % [placement])
		failed += 1

	# Media identity closes the icon/sprite deferral the class, weapon, and roster
	# families each carried: a logical id must resolve to a real validated file.
	if (
		adapted.assets.size() == 3
		and adapted.assets["blade_icon"]["path"] == pack.path_join("assets/blade.png")
		and adapted.assets["blade_icon"]["decoded_type"] == "image/png"
		and (
			adapted.assets["hero_sprite"]["sidecar_path"]
			== pack.path_join("assets/hero.frames.json")
		)
		and weapon != null
		and weapon.icon == "blade_icon"
		and adapted.classes["fixture_class"].sprite_id == "hero_sprite"
	):
		print("OK  logical media ids resolve to validated files on the pack root")
		passed += 1
	else:
		print("FAIL media adoption: assets=%s" % [adapted.assets])
		failed += 1

	# An icon naming nothing is the media equivalent of a dangling variant selection:
	# it survives a save and resolves to nothing, so it must reject the pack.
	var missing_media := scratch.path_join("missing-media")
	_write_pack(missing_media)
	var weapon_document: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(missing_media.path_join("data/weapon.json"))
	)
	weapon_document["icon"] = "no_such_asset"
	_write_bytes(
		missing_media.path_join("data/weapon.json"),
		JSON.stringify(weapon_document).to_utf8_buffer()
	)
	var missing_media_result = Adapter.load(missing_media, ROOT, "1.0")
	if (
		not missing_media_result.valid
		and "references missing asset 'no_such_asset'" in "\n".join(missing_media_result.errors)
	):
		print("OK  an icon that names no registered asset rejects the pack")
		passed += 1
	else:
		print("FAIL dangling media response: %s" % [missing_media_result.errors])
		failed += 1

	# The recorded digest must be checked against the bytes on disk, or a mutated
	# asset would activate silently under a record that still looks correct.
	var mutated_media := scratch.path_join("mutated-media")
	_write_pack(mutated_media)
	_write_bytes(
		mutated_media.path_join("assets/blade.png"),
		PackedByteArray([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x2A, 0x2A])
	)
	var mutated_result = Adapter.load(mutated_media, ROOT, "1.0")
	var mutated_text := "\n".join(mutated_result.errors)
	if (
		not mutated_result.valid
		and "asset_byte_size_mismatch" in mutated_text
		and "asset_sha256_mismatch" in mutated_text
	):
		print("OK  a mutated asset fails its recorded integrity")
		passed += 1
	else:
		print("FAIL mutated asset response: %s" % [mutated_result.errors])
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

	# The active pack owns its skill catalogue; project data is never unioned in.
	var active_skill: SkillData = dm.get_skill("fixture_vantage")
	if (
		active_skill != null
		and active_skill.effect_id == "vantage"
		and active_skill.trigger == "on_combat_start"
		and not dm._skills.has("vantage")
		and dm.content_status()["warnings"].is_empty()
	):
		print("OK  pack activation commits its self-contained skill catalogue")
		passed += 1
	else:
		print("FAIL pack skill catalogue: %s" % [dm.content_status()])
		failed += 1
	var active_pair_up: Resource = dm.pair_up_bonus_table()
	if (
		active_pair_up != null
		and active_pair_up.get("scaling_divisor") == 4
		and active_pair_up.call("get_class_bonus", "fixture_class").get("strength") == 2
	):
		print("OK  pack activation commits its self-contained pair-up bonus table")
		passed += 1
	else:
		print("FAIL pack pair-up bonus table: %s" % [active_pair_up])
		failed += 1
	dm.free()

	# Map SEMANTICS have one owner: collect_map_data_validation_errors. A tile outside
	# the grid is shape-valid JSON, so the schema pass admits it — activation must
	# still refuse the pack, proving Tier-2 packs are held to the same rules as project
	# data rather than a second, weaker copy of them.
	var out_of_bounds := scratch.path_join("out-of-bounds")
	_write_pack(out_of_bounds)
	var map_document: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(out_of_bounds.path_join("data/map_01.json"))
	)
	map_document["enemy_placements"][0]["tile"] = [99, 99]
	_write_bytes(
		out_of_bounds.path_join("data/map_01.json"), JSON.stringify(map_document).to_utf8_buffer()
	)
	var bounds_dm := DataManagerScript.new()
	var bounds_adapted = Adapter.load(out_of_bounds, ROOT, "1.0")
	var bounds_accepted := bounds_dm.select_tier2_campaign_source(out_of_bounds, ROOT, "1.0")
	if (
		bounds_adapted.valid
		and not bounds_accepted
		and "is outside the grid" in "\n".join(bounds_dm.content_status()["errors"])
		and bounds_dm.content_state() == DataManagerScript.ContentState.INACTIVE
	):
		print("OK  map semantics reject a pack the document schema alone would admit")
		passed += 1
	else:
		print("FAIL out-of-bounds gate: accepted=%s" % [bounds_accepted])
		failed += 1
	bounds_dm.free()

	# Unit-id uniqueness is scoped to one playable battle, not to the whole pack. Two
	# maps re-using an enemy archetype id is legal authoring the engine's own content
	# does — the rout map and its faction demo share all eight enemies — and only one
	# map is ever loaded, so a pack-wide table rejected a pack that plays perfectly.
	var shared_enemy := scratch.path_join("shared-enemy")
	_write_pack(shared_enemy)
	_add_second_map(shared_enemy, "map_02")
	var shared_dm := DataManagerScript.new()
	var shared_accepted := shared_dm.select_tier2_campaign_source(shared_enemy, ROOT, "1.0")
	if (
		shared_accepted
		and shared_dm.resolve_map_data(Adapter.map_uri(ROOT, "1.0", "map_02")) != null
	):
		print("OK  two maps may re-use an enemy unit id, because only one is ever loaded")
		passed += 1
	else:
		print("FAIL shared enemy id: %s" % [shared_dm.content_status()["errors"]])
		failed += 1
	shared_dm.free()

	# The collision that DOES matter is still caught: a roster unit sharing an id with
	# an enemy on the map that roster deploys onto breaks find_unit_by_id and Pair Up
	# in silently confusing ways (code review 2026-06-10 issue 2.10).
	var roster_collision := scratch.path_join("roster-collision")
	_write_pack(roster_collision)
	var collision_roster: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(roster_collision.path_join("data/roster.json"))
	)
	collision_roster["units"][0]["unit_id"] = "brigand"
	_write_bytes(
		roster_collision.path_join("data/roster.json"),
		JSON.stringify(collision_roster).to_utf8_buffer()
	)
	var collision_dm := DataManagerScript.new()
	var collision_accepted := collision_dm.select_tier2_campaign_source(
		roster_collision, ROOT, "1.0"
	)
	if (
		not collision_accepted
		and "duplicate unit_id 'brigand'" in "\n".join(collision_dm.content_status()["errors"])
	):
		print("OK  a roster unit colliding with an enemy on its own map still rejects")
		passed += 1
	else:
		print("FAIL roster/placement collision: accepted=%s" % [collision_accepted])
		failed += 1
	collision_dm.free()

	# Terrain: a pack retune must reach the live registry through activation, merge
	# over the engine definition rather than replacing it, and arrive as integers —
	# JSON decodes every number as a float, and a move cost of 4.0 handed to
	# pathfinding compares unequal to the integers the cost tables use.
	var terrain_dm := DataManagerScript.new()
	var terrain_accepted := terrain_dm.select_tier2_campaign_source(pack, ROOT, "1.0")
	var live_terrain: TerrainRegistry = terrain_dm.terrain_registry()
	if (
		terrain_accepted
		and live_terrain.avoid_bonus("forest") == 25
		and live_terrain.move_cost("forest", "mounted") == 4
		and typeof(live_terrain.move_cost("forest", "mounted")) == TYPE_INT
		# Untouched by the partial retune, and untouched terrain keeps its own numbers.
		and live_terrain.move_cost("forest", "infantry") == 2
		and live_terrain.avoid_bonus("mountain") == 20
	):
		print("OK  a pack terrain retune activates, merges, and arrives as integers")
		passed += 1
	else:
		print(
			(
				"FAIL terrain activation: accepted=%s avoid=%s"
				% [terrain_accepted, live_terrain.avoid_bonus("forest")]
			)
		)
		failed += 1
	# Deactivation returns terrain to the engine set, like every other catalogue.
	terrain_dm.deactivate_campaign_package()
	if terrain_dm.terrain_registry().avoid_bonus("forest") == 15:
		print("OK  deactivation restores the engine terrain definitions")
		passed += 1
	else:
		print("FAIL terrain deactivation did not restore the engine set")
		failed += 1
	terrain_dm.free()

	# A terrain the engine cannot paint would render as wall with no diagnostic, so
	# activation must refuse the pack rather than admit it.
	var invented_terrain := scratch.path_join("invented-terrain")
	_write_pack(invented_terrain)
	var terrain_document: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(invented_terrain.path_join("data/terrain_forest.json"))
	)
	terrain_document["id"] = "swamp"
	_write_bytes(
		invented_terrain.path_join("data/terrain_forest.json"),
		JSON.stringify(terrain_document).to_utf8_buffer()
	)
	var invented_dm := DataManagerScript.new()
	var invented_accepted := invented_dm.select_tier2_campaign_source(invented_terrain, ROOT, "1.0")
	if not invented_accepted and invented_dm.terrain_registry().avoid_bonus("forest") == 15:
		print("OK  a terrain the engine cannot paint is refused before any state changes")
		passed += 1
	else:
		print("FAIL invented terrain activation: accepted=%s" % [invented_accepted])
		failed += 1
	invented_dm.free()

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


# Copies the fixture map under a second id — same enemy placement, same roster —
# and registers it. The copy keeps the enemy's unit_id deliberately: that shared id
# is the whole point of the case.
func _add_second_map(root: String, map_id: String) -> void:
	var relative := "data/%s.json" % map_id
	var map_document: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(root.path_join("data/map_01.json"))
	)
	map_document["id"] = map_id
	_write_bytes(root.path_join(relative), JSON.stringify(map_document).to_utf8_buffer())

	var catalogue: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(root.path_join("data/catalogue.json"))
	)
	catalogue["entries"].append({"kind": "map_data", "id": map_id, "path": relative})
	_write_bytes(root.path_join("data/catalogue.json"), JSON.stringify(catalogue).to_utf8_buffer())

	var registry: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(root.path_join("data/map_registry.json"))
	)
	registry["entries"].append(
		{"id": map_id, "label": "Second Map", "map_data_id": map_id, "roster_id": "heroes"}
	)
	_write_bytes(
		root.path_join("data/map_registry.json"), JSON.stringify(registry).to_utf8_buffer()
	)


func _write_pack(root: String, base_hp: int = 20) -> void:
	# Media is written before the registry that describes it, because the registry
	# carries the real byte size and digest — an authored-by-hand pair would only prove
	# the fixture agrees with itself.
	var png_bytes := PackedByteArray([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x2A])
	var media := {
		"blade_icon": "assets/blade.png",
		"hero_sprite": "assets/hero.png",
		"vulnerary_icon": "assets/vulnerary.png",
	}
	var assets := {}
	for logical_id: String in media:
		var relative: String = media[logical_id]
		_write_bytes(root.path_join(relative), png_bytes)
		assets[logical_id] = {
			"path": relative,
			"decoded_type": "image/png",
			"byte_size": png_bytes.size(),
			"sha256": FileAccess.get_sha256(root.path_join(relative)),
			"original_filename": relative.get_file(),
		}
	_write_bytes(
		root.path_join("assets/hero.frames.json"),
		JSON.stringify({"schema_version": 1, "animations": {}}).to_utf8_buffer()
	)
	assets["hero_sprite"]["sidecar_path"] = "assets/hero.frames.json"

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
				{"kind": "skill", "id": "fixture_vantage", "path": "data/skill.json"},
				{
					"kind": "pair_up_bonus_table",
					"id": "fixture_pair_up",
					"path": "data/pair_up.json",
				},
				{"kind": "source_registry", "id": "fixture_sources", "path": "data/sources.json"},
				{"kind": "asset_registry", "id": "fixture_assets", "path": "data/assets.json"},
				{"kind": "item", "id": "fixture_vulnerary", "path": "data/item.json"},
				{"kind": "terrain", "id": "forest", "path": "data/terrain_forest.json"},
			],
		},
		"data/terrain_forest.json":
		{
			"kind": "terrain",
			"schema_version": 1,
			"id": "forest",
			"display_name": "Fixture Wood",
			"source_refs": ["fixture_design"],
			"avoid_bonus": 25,
			# Partial: only the mounted cost is retuned, so the merge must preserve
			# the other four movement types from the engine definition.
			"move_costs": {"mounted": 4},
		},
		"data/skill.json":
		{
			"kind": "skill",
			"schema_version": 1,
			"id": "fixture_vantage",
			"display_name": "Fixture Vantage",
			"source_refs": ["fixture_design"],
			"trigger": "on_combat_start",
			"effect_id": "vantage",
			"effect_params": {},
			"release_available": true,
			"field_completeness": {"effect_id": "verified"},
		},
		"data/pair_up.json":
		{
			"kind": "pair_up_bonus_table",
			"schema_version": 1,
			"id": "fixture_pair_up",
			"display_name": "Fixture Pair Up",
			"source_refs": ["fixture_design"],
			"scaling_divisor": 4,
			"scaling_stats": ["strength", "skill"],
			"class_bonuses": {"fixture_class": {"strength": 2}},
			"field_completeness": {},
		},
		"data/item.json":
		{
			"kind": "item",
			"schema_version": 1,
			"id": "fixture_vulnerary",
			"display_name": "Fixture Vulnerary",
			"source_refs": ["fixture_design"],
			"item_type": "healing",
			"icon": "vulnerary_icon",
			"uses": 3,
			"cost": 300,
			"effect_id": "heal_flat",
			"effect_params": {"amount": 10},
		},
		"data/assets.json":
		{
			"kind": "asset_registry",
			"schema_version": 1,
			"id": "fixture_assets",
			"assets": assets,
		},
		"data/campaign.json":
		{
			"kind": "campaign",
			"schema_version": 1,
			"id": "fixture",
			"display_name": "Fixture",
			"source_refs": ["fixture_design"],
			"campaign_id": "fixture",
			"label": "Fixture",
			"start_node_id": "start",
			"nodes": [{"node_id": "start", "label": "Start", "map_id": "map_01", "next": []}],
		},
		"data/map_registry.json":
		{
			"kind": "map_registry",
			"schema_version": 1,
			"id": "maps",
			"display_name": "Fixture Maps",
			"source_refs": ["fixture_design"],
			"entries":
			[
				{
					"id": "map_01",
					"label": "Map",
					"map_data_id": "map_01",
					"roster_id": "heroes",
				}
			],
		},
		"data/map_01.json":
		{
			"kind": "map_data",
			"schema_version": 1,
			"id": "map_01",
			"display_name": "Map",
			"source_refs": ["fixture_design"],
			"grid": ["..."],
			"player_start_tiles": [[0, 0]],
			"camera_start_tile": [1, 0],
			"activation_mode": "WHOLE_PHASE",
			"factions":
			[
				{
					"id": "blue",
					"display_name": "Player",
					"color": [0.2, 0.4, 0.9, 1.0],
					"alliance_group": "allies",
					"controller": "AI",
				},
				{"id": "red", "alliance_group": "foes"},
			],
			"turn_order": ["blue", "red"],
			"enemy_placements":
			[
				{
					"unit": {"unit_id": "brigand", "class_id": "fixture_class", "level": 2},
					"tile": [2, 0],
					"faction": "red",
					"is_boss": true,
					"ai_profile": "hunter",
				}
			],
			"victory_conditions": {"allies": [{"type": "rout", "faction_id": "red"}]},
			"defeat_conditions": {"allies": [{"type": "turn_limit", "turns": 20}]},
			"reward_gold": 500,
			"reward_items": ["fixture_vulnerary"],
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
					"skills": ["fixture_vantage"],
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
						},
						{"item_id": "fixture_vulnerary", "uses": 3},
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
			# A logical media id, not a path: the asset registry owns where it lives.
			"icon": "blade_icon",
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
			"sprite_id": "hero_sprite",
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
	var registry_fixtures := {
		"action_primitives": ["fixture_action", "apply_active_modifier"],
		"resource_types": ["fixture_resource", "party_gold_wallet"],
		"occupancy_policies": ["fixture_occupancy", "require_empty_placement"],
		"objective_conditions": ["fixture_objective", "rout"],
		"item_effects": ["fixture_item", "heal_flat"],
	}
	for family in registry_fixtures:
		var entry_id: String = registry_fixtures[family][0]
		var catalogue_id := "%s__%s" % [family, entry_id]
		var relative := "data/registry_%s.json" % family
		files["data/catalogue.json"]["entries"].append(
			{"kind": "registry_entry", "id": catalogue_id, "path": relative}
		)
		files[relative] = {
			"kind": "registry_entry",
			"schema_version": 1,
			"id": catalogue_id,
			"display_name": entry_id,
			"source_refs": ["fixture_design"],
			"family": family,
			"entry_id": entry_id,
			"label_key": "registry.fixture.%s" % entry_id,
			"owner_feature": "TEST",
			"version": 1,
			"entry_kind": "test",
			"primitive_handler": registry_fixtures[family][1],
			"params_schema": {},
			"docs_text": "Fixture registry entry.",
			"test_fixture": {"fixture": true},
		}
	for relative in files:
		_write_bytes(root.path_join(relative), JSON.stringify(files[relative]).to_utf8_buffer())


func _write_bytes(path: String, bytes: PackedByteArray) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)
