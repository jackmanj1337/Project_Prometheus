extends SceneTree
# Build a browser fixture for ONE attack-forecast matchup, for the tester bundle's
# labelled comparison screenshots.
#
#   godot --headless --script res://scripts/tools/build_forecast_scenario_fixture.gd -- \
#       --pack <pack directory> --pack-id <id> --node <node_id> \
#       --attacker <unit_id> --target <unit_id> --name <scenario> --out <directory>
#
# WHY IT EXISTS SEPARATELY FROM `build_interaction_readout_fixture.gd`. That one builds
# the acceptance evidence: a specific authored relationship, on a specific chapter, with
# the dice pinned to the same seed the headless proof pins. This builds a PICTURE — one
# matchup a tester is asked to compare their own screen against — and it has to do it for
# several matchups across two packs, so the matchup is an argument rather than a constant.
# Its output is the same sidecar shape, so `stateful-journeys.mjs --journey
# interaction-readout` consumes it unchanged.
#
# IT STAGES THE ATTACKER, AND SAYS SO. The acceptance fixture deliberately does NOT
# pre-position its bearer: the journey's move is the decision the run exists to make. Here
# the move is scenery, and the maps that hold the interesting matchups put the target
# twenty tiles from the player's start tiles. So the attacker is placed two steps from the
# target on the target's own row, after deployment, and the sidecar records `staged: true`
# so a reader never mistakes this for evidence about reachability.
#
# THE CAMPAIGN IS ALWAYS THE FULL ONE, NEVER A `single_map__` entry. A map launched from a
# pack's own registry row carries no ruleset, so the pack's authored interaction profiles
# are not in scope and every forecast would photograph an empty relationship list. That is
# a known gap with its own row, `STANDALONE-MAP-RULESET-2026-09-20`; until it closes, a
# fixture that wants authored relationships has to go through a campaign run.

const Exporter = preload("res://scripts/resources/CampaignPackExporter.gd")
const Preflight = preload("res://scripts/resources/CampaignArchivePreflight.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const Registry = preload("res://scripts/resources/CampaignPackRegistry.gd")
const Backup = preload("res://scripts/resources/CampaignBackupService.gd")
const Budgets = preload("res://scripts/resources/ImportBudgets.gd")

const CAMPAIGN_ID := "proving_grounds"
const GAME_MAP_SCENE := "res://scenes/core/GameMap.tscn"
const PREP_SCENE := "res://scenes/ui/PrepScreen.tscn"
const SUSPEND_SLOT := "resume_battle"
const STAGING_SEED := 20260921

var _dm: Node
var _gs: Node
var _cm: Node
var _rng: Node
var _pack_id := ""
var _pack_version := "0.1.0"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := _parse_args()
	for required in ["pack", "pack-id", "node", "attacker", "target", "name", "out"]:
		if String(args.get(required, "")).is_empty():
			printerr("missing --%s" % required)
			quit(2)
			return
	var out_dir: String = args["out"]
	_pack_id = args["pack-id"]
	await process_frame

	if DirAccess.make_dir_recursive_absolute(out_dir) != OK:
		printerr("output directory could not be created: %s" % out_dir)
		quit(1)
		return
	_dm = root.get_node_or_null("DataManager")
	_gs = root.get_node_or_null("GameState")
	_cm = root.get_node_or_null("CampaignManager")
	_rng = root.get_node_or_null("RngService")
	if _dm == null or _gs == null or _cm == null:
		printerr("DataManager, GameState and CampaignManager must all be present")
		quit(1)
		return

	if not _install_pack(args["pack"], out_dir):
		quit(1)
		return
	var target_node: String = args["node"]
	if not await _play_until(target_node):
		quit(1)
		return
	var board := await _stage_board(args["attacker"], args["target"])
	if board.is_empty():
		quit(1)
		return
	if not bool(board["cursor"].call("_write_suspend_save")):
		printerr("the suspend save was refused; no mid-map slot exists to back up")
		quit(1)
		return
	if not _export_backup(out_dir, args["name"], target_node, board):
		quit(1)
		return
	print("fixture %s ready in %s" % [args["name"], out_dir])
	quit(0)


func _parse_args() -> Dictionary:
	var out := {}
	var argv := OS.get_cmdline_user_args()
	for index in argv.size():
		if argv[index].begins_with("--") and index + 1 < argv.size():
			out[argv[index].substr(2)] = argv[index + 1]
	return out


# --- install ----------------------------------------------------------------------------


func _install_pack(pack_root: String, out_dir: String) -> bool:
	var limits: Preflight.Limits = Preflight.Limits.new(
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRIES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRY_COMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRY_UNCOMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_TOTAL_COMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_TOTAL_UNCOMPRESSED_BYTES
	)
	var archive := out_dir.path_join("%s-%s.zip" % [_pack_id, _pack_version])
	var exported = Exporter.new().export_zip(pack_root, archive, limits)
	if not exported.exported:
		printerr("pack export failed: %s" % str(exported.errors))
		return false
	var preflight = Preflight.inspect_zip(archive, limits)
	if not preflight.valid:
		printerr("pack preflight refused the archive: %s" % str(preflight.errors))
		return false
	var installed = Installer.new(Registry.DEFAULT_STORAGE_ROOT).install_zip(archive, preflight)
	if not installed.errors.is_empty():
		printerr("pack install failed: %s" % str(installed.errors))
		return false
	var path := String(installed.installed_path)
	if path.is_empty():
		path = Registry.resolve_installed_path(
			Registry.DEFAULT_STORAGE_ROOT, _pack_id, _pack_version, installed.content_fingerprint
		)
	if path.is_empty():
		printerr("the pack installed but the library cannot resolve where")
		return false
	if not bool(_dm.call("select_tier2_campaign_source", path, _pack_id, _pack_version)):
		printerr("installed pack did not activate: %s" % str(_dm.get("_activation_errors")))
		return false
	print("installed and activated %s %s" % [_pack_id, _pack_version])
	return true


# --- reach the node ---------------------------------------------------------------------


# Chapters before the wanted one are cleared with the rout probe, which is a playability
# device and never balance evidence: it zeroes every non-player unit and asks the turn
# manager to evaluate. The campaign keeps its party between nodes, so the only way to a
# later node is through the earlier ones.
func _play_until(target_node: String) -> bool:
	if not bool(_cm.call("start_campaign", CAMPAIGN_ID)):
		printerr("campaign %s did not start" % CAMPAIGN_ID)
		return false
	var guard := 0
	while String(_cm.get("current_node_id")) != target_node:
		guard += 1
		if guard > 12:
			printerr("node %s was never reached" % target_node)
			return false
		var node_id := String(_cm.get("current_node_id"))
		var battle := await _begin_battle()
		if battle == null:
			return false
		var turn_manager: Node = battle.get_node_or_null("TurnManager")
		if turn_manager == null:
			printerr("%s has no TurnManager" % node_id)
			return false
		if not _resolve_objective(turn_manager, _objective_for(node_id)):
			printerr("%s objective probe was refused" % node_id)
			return false
		await process_frame
		if not bool(_cm.call("get_pending_result").get("victory", false)):
			printerr("%s did not resolve as a victory" % node_id)
			return false
		if not bool(_cm.call("commit_pending_result")):
			printerr("%s did not commit" % node_id)
			return false
		print("  cleared %s" % node_id)
	return true


func _begin_battle() -> Node:
	if not bool(_cm.call("launch_current_node")):
		printerr("node did not launch")
		return null
	await _settle()
	if current_scene == null or current_scene.scene_file_path != PREP_SCENE:
		printerr("did not reach Prep")
		return null
	_gs.call("set_next_map_deployment", _deployment_plan(_cm.call("get_current_node")))
	if not bool(_cm.call("begin_prepared_battle")):
		printerr("did not begin from Prep")
		return null
	await _settle()
	if current_scene == null or current_scene.scene_file_path != GAME_MAP_SCENE:
		printerr("did not reach GameMap")
		return null
	if _rng != null and _rng.has_method("start_map"):
		_rng.call("start_map", STAGING_SEED)
	return current_scene


# --- stage the matchup ------------------------------------------------------------------


func _stage_board(attacker_id: String, target_id: String) -> Dictionary:
	var battle := await _begin_battle()
	if battle == null:
		return {}
	var cursor: Node = battle.get_node_or_null("MapCursor")
	if cursor == null:
		printerr("the live map has no MapCursor, so no suspend save can be written")
		return {}
	var attacker := _find_unit(attacker_id)
	var target := _find_unit(target_id)
	if attacker == null or target == null:
		printerr("the map did not field both %s and %s" % [attacker_id, target_id])
		return {}
	var target_tile: Vector2i = target.tile_position
	# Two steps out on the target's own row: the journey moves to `target.x - 1`, so the
	# staging tile and the approach tile both have to be free and walkable, and both have
	# to be on that row or the single click the journey makes cannot reach the target.
	var staged := _free_tile(battle, Vector2i(target_tile.x - 2, target_tile.y), attacker)
	var approach := _free_tile(battle, Vector2i(target_tile.x - 1, target_tile.y), attacker)
	if staged == Vector2i(-1, -1) or approach == Vector2i(-1, -1):
		printerr("no free staging/approach pair beside %s at %s" % [target_id, str(target_tile)])
		return {}
	# `snap_to_tile` sets both the logical tile and the node's position; setting
	# `tile_position` alone leaves the sprite where it was, and the suspend save would
	# then disagree with what the browser draws.
	# EXPECTED ROWS ARE READ FROM THE APPROACH TILE, NOT THE STAGING TILE, and that is not
	# a detail. `_build_context` resolves `defender_weapon` only when the defender can
	# COUNTER from where the attacker is standing, so a rule whose `when` names
	# `equipped_target` -- which is every arm of a weapon triangle -- cannot match while the
	# attacker is still two tiles out. Recording the rows from the staging tile therefore
	# wrote `expected_rows: []` for a matchup that shows a row the moment the unit steps in,
	# and the journey would then fail the run for showing the row it exists to photograph.
	attacker.call("snap_to_tile", approach)
	await process_frame
	var expected := _expected_rows(attacker, target)
	attacker.call("snap_to_tile", staged)
	await process_frame
	print(
		(
			"staged %s at %s against %s at %s (approach %s)"
			% [attacker_id, str(staged), target_id, str(target_tile), str(approach)]
		)
	)
	return {
		"cursor": cursor,
		"attacker_id": attacker_id,
		"target_id": target_id,
		"attacker_tile": [staged.x, staged.y],
		"target_tile": [target_tile.x, target_tile.y],
		"expected_rows": expected,
	}


# A tile is usable when the map calls it walkable and nothing else is standing on it. The
# attacker itself does not count as an occupant: it is about to be moved off wherever it is.
func _free_tile(battle: Node, tile: Vector2i, attacker: Node) -> Vector2i:
	if battle.has_method("is_tile_walkable") and not bool(battle.call("is_tile_walkable", tile)):
		return Vector2i(-1, -1)
	for unit in _gs.get("all_units"):
		if unit == null or unit == attacker:
			continue
		if unit.get("tile_position") == tile:
			return Vector2i(-1, -1)
	return tile


# The same `preview_combat` call the forecast panel makes, recorded so the browser run
# asserts the panel against what the engine resolved rather than against "a row appeared".
func _expected_rows(attacker: Node, defender: Node) -> Array:
	var cr := root.get_node_or_null("CombatResolver")
	if cr == null or not cr.has_method("preview_combat"):
		return []
	var preview: Dictionary = cr.call("preview_combat", attacker, defender)
	var expected: Array = []
	for side in ["attacker", "defender"]:
		for row: Variant in preview.get("%s_interactions" % side, []):
			var entry := row as Dictionary
			(
				expected
				. append(
					{
						"side": side,
						"profile_id": String(entry.get("profile_id", "")),
						"label": String(entry.get("label", "")),
						"direction": String(entry.get("direction", "")),
						"summary": String(entry.get("summary", "")),
					}
				)
			)
	return expected


# --- artifacts --------------------------------------------------------------------------


func _export_backup(out_dir: String, name: String, node_id: String, board: Dictionary) -> bool:
	var destination := out_dir.path_join("%s-backup.zip" % name)
	var service = Backup.new(Registry.DEFAULT_STORAGE_ROOT, root.get_node_or_null("SaveManager"))
	var result = service.export_backup(destination)
	if not result.exported:
		printerr("backup export failed: %s" % str(result.errors))
		return false
	var node: Variant = _cm.call("get_current_node")
	var sidecar := {
		"schema_version": 1,
		"staged": true,
		"backup": destination,
		"campaign_id": CAMPAIGN_ID,
		"campaign_slot": SUSPEND_SLOT,
		"map_id": String(node.get("map_id")) if node != null else "",
		"node_id": node_id,
		"package_id": _pack_id,
		"package_version": _pack_version,
		"seed": STAGING_SEED,
		"bearer": {"unit_id": String(board["attacker_id"]), "tile": board["attacker_tile"]},
		"target": {"unit_id": String(board["target_id"]), "tile": board["target_tile"]},
		"expected_rows": board["expected_rows"],
	}
	var sidecar_path := out_dir.path_join("%s-fixture.json" % name)
	var handle := FileAccess.open(sidecar_path, FileAccess.WRITE)
	if handle == null:
		printerr("could not write %s" % sidecar_path)
		return false
	handle.store_string("%s\n" % JSON.stringify(sidecar, "  "))
	handle.close()
	print("wrote %s (%d bytes) and %s" % [destination, result.total_bytes, sidecar_path])
	return true


# --- shared helpers ---------------------------------------------------------------------


func _deployment_plan(node: Variant = null) -> Dictionary:
	var path := String(_gs.get("next_map_data_path"))
	var resolved: Variant = _dm.call("resolve_battle_source", path)
	if resolved == null:
		return {}
	var map_data: Variant = resolved.get("battle_map")
	if map_data == null:
		return {}
	var tiles: Array = map_data.get("player_start_tiles")
	var ordered: Array[String] = []
	if node != null:
		for required_id in node.get("required_units"):
			if String(required_id) != "" and not String(required_id) in ordered:
				ordered.append(String(required_id))
	for unit_data in _gs.get("player_roster"):
		if unit_data == null:
			continue
		var unit_id := String(unit_data.get("unit_id"))
		if unit_id != "" and not unit_id in ordered:
			ordered.append(unit_id)
	var plan := {}
	for i in range(mini(ordered.size(), tiles.size())):
		plan[ordered[i]] = tiles[i]
	return plan


# The deterministic probe that clears each chapter on the way to the wanted one. Lifted
# from `build_interaction_readout_fixture.gd`, which lifted it from the playthrough proof:
# they are PLAYABILITY devices and never balance evidence. A generic "zero every enemy"
# probe is not enough, because `seize`, `escape` and `survive` are not rout conditions and
# a map whose objective is one of those stays unresolved with every enemy dead.
const OBJECTIVES := {
	"node_00_drill": "rout",
	"node_01_rout": "rout",
	"node_02_seize": "seize",
	"node_03_boss": "defeat_boss",
	"node_04_escape": "escape",
	"node_05_defend": "survive",
}


func _objective_for(node_id: String) -> String:
	return String(OBJECTIVES.get(node_id, "rout"))


func _resolve_objective(turn_manager: Node, objective: String) -> bool:
	var units: Array = _gs.get("all_units")
	match objective:
		"rout":
			for unit in units:
				if unit != null and String(unit.get("team")) != "blue" and unit.get("data") != null:
					unit.data.hp = 0
			turn_manager.call("check_victory_conditions")
			return true
		"seize":
			var lord := _find_unit("unit_01_cavalier")
			if lord == null:
				return false
			lord.tile_position = Vector2i(15, 2)
			turn_manager.call("record_seize", lord)
			return true
		"defeat_boss":
			var boss := _find_unit("m003_boss")
			if boss == null or boss.get("data") == null:
				return false
			boss.data.hp = 0
			turn_manager.call("check_victory_conditions")
			return true
		"escape":
			var lord := _find_unit("unit_01_cavalier")
			var merc := _find_unit("unit_02_mercenary")
			if lord == null or merc == null:
				return false
			lord.tile_position = Vector2i(16, 2)
			merc.tile_position = Vector2i(16, 3)
			turn_manager.call("record_escape", lord)
			turn_manager.call("record_escape", merc)
			return true
		"survive":
			_gs.set("turn_number", 7)
			turn_manager.call("start_player_phase")
			return true
	return false


func _find_unit(unit_id: String) -> Node:
	for unit in _gs.get("all_units"):
		if unit != null and unit.get("data") != null:
			if String(unit.data.get("unit_id")) == unit_id:
				return unit
	return null


func _settle() -> void:
	for _i in range(8):
		await process_frame
