extends SceneTree
# Keeps the player-facing import artifact aligned with the Tier-2 runtime schema.

const Adapter = preload("res://scripts/resources/CampaignTier2RuntimeAdapter.gd")
const Preflight = preload("res://scripts/resources/CampaignArchivePreflight.gd")
const DataManagerScript = preload("res://scripts/autoloads/DataManager.gd")
const CampaignManagerScript = preload("res://scripts/autoloads/CampaignManager.gd")
const GameStateScript = preload("res://scripts/autoloads/GameState.gd")
const ROOT := "res://test_fixtures/campaign_packs/two_map_skirmish"
const BRANCH_ROOT := "res://test_fixtures/campaign_packs/branching_skirmish"
const ARCHIVE := "res://test_fixtures/campaign_packs/two-map-skirmish-1.0.zip"


func _init() -> void:
	print("=== Two-map Campaign Fixture Test ===")
	var passed := 0
	var failed := 0

	var adapted = Adapter.load(ROOT, "two_map_skirmish", "1.0")
	var campaign = adapted.campaigns.get("two_map_skirmish") if adapted.valid else null
	if (
		adapted.valid
		and campaign != null
		and campaign.nodes.size() == 2
		and adapted.rosters["skirmish_team"].size() == 2
		and adapted.maps["skirmish_01"].enemy_placements.size() == 3
		and adapted.maps["skirmish_02"].enemy_placements.size() == 3
		and adapted.weapons.has("training_sword")
		and adapted.rosters["skirmish_team"][0].inventory.size() == 1
		and adapted.maps["skirmish_01"].victory_conditions.has("allies")
		and campaign.rule_overrides.get("undo_activations", 0) == -1
	):
		print("OK  source fixture adapts with two maps, two blue units, and three reds per map")
		passed += 1
	else:
		print("FAIL source fixture: %s" % [adapted.errors])
		failed += 1

	var branch_adapted = Adapter.load(BRANCH_ROOT, "branching_skirmish", "1.0")
	var branch_campaign = (
		branch_adapted.campaigns.get("branching_skirmish") if branch_adapted.valid else null
	)
	var branch_start = (
		branch_campaign.get_node_by_id("crossroads") if branch_campaign != null else null
	)
	var river = branch_campaign.get_node_by_id("river_pass") if branch_campaign != null else null
	var ridge = branch_campaign.get_node_by_id("ridge_pass") if branch_campaign != null else null
	if (
		branch_adapted.valid
		and branch_campaign != null
		and branch_campaign.nodes.size() == 3
		and branch_start != null
		and branch_start.next_node_ids == ["river_pass", "ridge_pass"]
		and river != null
		and ridge != null
		and river.map_id == "skirmish_02"
		and ridge.map_id == "skirmish_03"
		and branch_adapted.maps["skirmish_02"].grid != branch_adapted.maps["skirmish_03"].grid
		and branch_adapted.maps["skirmish_03"].enemy_placements.size() == 4
	):
		print("OK  branching fixture exposes ordered, visibly distinct River/Ridge maps")
		passed += 1
	else:
		print("FAIL branching fixture: %s" % [branch_adapted.errors])
		failed += 1

	var limits := Preflight.Limits.new(32, 200000, 200000, 500000, 500000)
	var preflight = Preflight.inspect_zip(ARCHIVE, limits)
	if preflight.valid and preflight.package_id == "two_map_skirmish":
		print("OK  persistent ZIP passes the player-facing archive preflight")
		passed += 1
	else:
		print("FAIL archive preflight: %s" % [preflight.errors])
		failed += 1

	var bus: Node = load("res://scripts/autoloads/EventBus.gd").new()
	bus.name = "EventBus"
	get_root().add_child(bus)
	var registry_manager: Node = load("res://scripts/autoloads/RegistryManager.gd").new()
	registry_manager.name = "RegistryManager"
	get_root().add_child(registry_manager)
	var dm := DataManagerScript.new()
	dm.name = "DataManager"
	get_root().add_child(dm)
	var gs := GameStateScript.new()
	gs.name = "GameState"
	get_root().add_child(gs)
	var cm := CampaignManagerScript.new()
	cm.name = "CampaignManager"
	get_root().add_child(cm)
	await process_frame
	var selected: bool = dm.select_tier2_campaign_source(ROOT, "two_map_skirmish", "1.0")
	var started: bool = selected and cm.start_campaign("two_map_skirmish")
	var staged: bool = (
		started
		and (
			cm
			. stage_status_import_benefits(
				{
					"author_id": "project_prometheus",
					"campaign_id": "proving_grounds",
					"campaign_version": "1.0.0",
					"counters": {"party_gold": 4321},
				}
			)
		)
	)
	var roster_applied: bool = (
		staged and cm._apply_roster_policy(gs, "campaign_pack_roster", "skirmish_team")
	)
	var benefit_ok: bool = roster_applied
	var mira: UnitData = null
	for unit: UnitData in gs.player_roster:
		if unit.unit_id == "mira":
			mira = unit
			break
	benefit_ok = (
		benefit_ok
		and gs.party_gold == 4321
		and mira != null
		and mira.inventory.size() == 2
		and mira.inventory.any(
			func(entry: InventoryEntry) -> bool: return entry.item_id == "proving_medal"
		)
		and mira.inventory.any(
			func(entry: InventoryEntry) -> bool: return entry.weapon_id == "training_sword"
		)
	)
	if benefit_ok:
		print("OK  Proving Grounds record carries gold and grants Mira its special medal")
		passed += 1
	else:
		print(
			(
				"FAIL Proving Grounds import benefit: selected=%s started=%s staged=%s roster=%s gold=%s mira=%s inventory=%s"
				% [
					selected,
					started,
					staged,
					roster_applied,
					gs.party_gold,
					mira != null,
					mira.inventory.size() if mira != null else -1
				]
			)
		)
		failed += 1
	cm.free()
	gs.free()
	dm.free()
	registry_manager.free()
	bus.free()

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)
