extends SceneTree

# Headless acceptance pass for the authored Proving Grounds campaign.
#
# This is deliberately a playability harness, not a balance test. It launches
# every authored node through CampaignManager/GameMap, resolves the real
# objective evaluator for each map, commits campaign progression, and loads a
# between-map save after every result. The objective actions are deterministic
# probes so this suite tests the campaign/runtime seam without pretending that
# headless numbers are balance evidence.

const CAMPAIGN_ID := "proving_grounds"
const GAME_MAP_SCENE := "res://scenes/core/GameMap.tscn"
const PREP_SCENE := "res://scenes/ui/PrepScreen.tscn"

const NODES := [
	{
		"node_id": "node_00_drill",
		"map_id": "map_000_drill",
		"path": "res://data/maps/map_000_drill/map_000_drill_data.tres",
		"objective": "rout",
	},
	{
		"node_id": "node_01_rout",
		"map_id": "map_001",
		"path": "res://data/maps/map_001_rout/map_001_data.tres",
		"objective": "rout",
	},
	{
		"node_id": "node_02_seize",
		"map_id": "map_002_seize",
		"path": "res://data/maps/map_002_seize/map_002_seize_data.tres",
		"objective": "seize",
	},
	{
		"node_id": "node_03_boss",
		"map_id": "map_003_defeat_boss",
		"path": "res://data/maps/map_003_defeat_boss/map_003_defeat_boss_data.tres",
		"objective": "defeat_boss",
	},
	{
		"node_id": "node_04_escape",
		"map_id": "map_004_escape",
		"path": "res://data/maps/map_004_escape/map_004_escape_data.tres",
		"objective": "escape",
	},
	{
		"node_id": "node_05_defend",
		"map_id": "map_005_defend",
		"path": "res://data/maps/map_005_defend/map_005_defend_data.tres",
		"objective": "survive",
	},
]

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== V0717 Proving Grounds Playability ===")
	await process_frame
	var cm := root.get_node_or_null("CampaignManager")
	var gs := root.get_node_or_null("GameState")
	if cm == null or gs == null:
		_fail("autoloads are available")
		_finish()
		return

	if not bool(cm.call("start_campaign", CAMPAIGN_ID)):
		_fail("campaign starts: %s" % CAMPAIGN_ID)
		_finish()
		return
	_pass("campaign starts: %s" % CAMPAIGN_ID)

	for node_info in NODES:
		await _run_node(cm, gs, node_info)

	var cleared: Array = cm.get("cleared_node_ids")
	_check(
		String(cm.get("current_node_id")) == "" and cleared.size() == NODES.size(),
		(
			"campaign reaches terminal completion (%d/%d nodes cleared)"
			% [cleared.size(), NODES.size()]
		)
	)
	_finish()


func _run_node(cm: Node, gs: Node, node_info: Dictionary) -> void:
	var node_id := String(node_info["node_id"])
	var map_id := String(node_info["map_id"])
	var objective := String(node_info["objective"])
	print("\n--- %s (%s) ---" % [node_id, objective])

	_check(
		String(cm.get("current_node_id")) == node_id, "%s is the current campaign node" % node_id
	)
	if String(cm.get("current_node_id")) != node_id:
		return

	if not bool(cm.call("launch_current_node")):
		_fail("%s launch_current_node" % map_id)
		return
	await _settle_scene()
	var prep_scene: Node = current_scene
	_check(prep_scene != null, "%s reaches Prep" % map_id)
	_check(
		prep_scene != null and prep_scene.scene_file_path == PREP_SCENE, "%s enters Prep" % map_id
	)

	var map_data: MapData = load(String(node_info["path"]))
	if map_data == null:
		_fail("%s authored MapData loads" % map_id)
		return
	var plan: Dictionary = _deployment_plan(gs, map_data)
	_check(not plan.is_empty(), "%s has a legal deployment plan" % map_id)
	gs.call("set_next_map_deployment", plan)
	if not bool(cm.call("begin_prepared_battle")):
		_fail("%s begins from Prep" % map_id)
		return
	await _settle_scene()

	var battle: Node = current_scene
	_check(battle != null, "%s reaches GameMap" % map_id)
	if battle == null:
		return
	_check(battle.scene_file_path == GAME_MAP_SCENE, "%s enters GameMap" % map_id)
	var turn_manager: Node = battle.get_node_or_null("TurnManager")
	_check(turn_manager != null, "%s has TurnManager" % map_id)
	if turn_manager == null:
		return
	var loaded_map: Resource = battle.get("map_data") as Resource
	_check(
		loaded_map != null and String(loaded_map.get("id")) == map_id,
		"%s loads the authored battle" % map_id
	)

	var gold_before := int(gs.get("party_gold"))
	if not _resolve_objective(turn_manager, gs, objective):
		_fail("%s objective probe is accepted by the runtime" % map_id)
		return
	await process_frame

	var pending: Dictionary = cm.call("get_pending_result")
	_check(bool(pending.get("victory", false)), "%s objective resolves as victory" % map_id)
	_check(int(gs.get("party_gold")) > gold_before, "%s commits its authored reward" % map_id)
	if not bool(pending.get("victory", false)):
		return

	var next_id: String = String(pending.get("next_node_id", ""))
	if not bool(cm.call("commit_pending_result")):
		_fail("%s commits campaign progression" % map_id)
		return
	_check(
		String(cm.get("current_node_id")) == next_id,
		"%s advances to %s" % [map_id, next_id if next_id != "" else "terminal"]
	)

	# Exercise the actual between-map save/resume seam after every completed node,
	# including the terminal node where current_node_id is intentionally empty.
	var save: RefCounted = gs.call("capture_campaign_save", "playability-%s" % map_id)
	_check(save != null, "%s creates a between-map save" % map_id)
	if save == null:
		return
	var saved_payload: Dictionary = save.to_dict()
	_check(
		String(saved_payload.get("campaign", {}).get("node_id", "")) == next_id,
		"%s save records the post-victory node" % map_id
	)
	cm.call("end_campaign")
	_check(
		bool(gs.call("configure_campaign_resume", save)), "%s resumes its campaign save" % map_id
	)
	_check(
		String(cm.get("current_node_id")) == next_id and int(gs.get("party_gold")) > gold_before,
		"%s resume restores position and reward" % map_id
	)


func _deployment_plan(gs: Node, map_data: MapData) -> Dictionary:
	var roster: Array = gs.get("player_roster")
	var plan: Dictionary = {}
	var count: int = mini(roster.size(), map_data.player_start_tiles.size())
	for i in range(count):
		var unit_data: UnitData = roster[i]
		if unit_data != null and unit_data.unit_id != "":
			plan[unit_data.unit_id] = map_data.player_start_tiles[i]
	return plan


func _resolve_objective(turn_manager: Node, gs: Node, objective: String) -> bool:
	var units: Array = gs.get("all_units")
	match objective:
		"rout":
			for unit in units:
				if unit != null and String(unit.get("team")) != "blue" and unit.get("data") != null:
					unit.data.hp = 0
			turn_manager.call("check_victory_conditions")
			return true
		"seize":
			var lord: Node = gs.call("find_unit_by_id", "unit_01_cavalier") as Node
			if lord == null:
				return false
			lord.tile_position = Vector2i(15, 2)
			turn_manager.call("record_seize", lord)
			return true
		"defeat_boss":
			var boss: Node = gs.call("find_unit_by_id", "m003_boss") as Node
			if boss == null or boss.get("data") == null:
				return false
			boss.data.hp = 0
			turn_manager.call("check_victory_conditions")
			return true
		"escape":
			var lord: Node = gs.call("find_unit_by_id", "unit_01_cavalier") as Node
			var merc: Node = gs.call("find_unit_by_id", "unit_02_mercenary") as Node
			if lord == null or merc == null:
				return false
			lord.tile_position = Vector2i(16, 2)
			merc.tile_position = Vector2i(16, 3)
			turn_manager.call("record_escape", lord)
			turn_manager.call("record_escape", merc)
			return true
		"survive":
			gs.set("turn_number", 7)
			turn_manager.call("start_player_phase")
			return true
	return false


func _settle_scene() -> void:
	await process_frame
	await process_frame


func _pass(message: String) -> void:
	_passed += 1
	print("OK  " + message)


func _fail(message: String) -> void:
	_failed += 1
	print("FAIL " + message)


func _check(condition: bool, message: String) -> void:
	if condition:
		_pass(message)
	else:
		_fail(message)


func _finish() -> void:
	print("\n=== Playability Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
