extends SceneTree
# Build the browser fixture for the `[ITR-6]` readout journey.
#
#   godot --headless --script res://scripts/tools/build_interaction_readout_fixture.gd -- \
#       --pack <FE pack directory> --out <directory>
#
# WHAT IT PRODUCES. One campaign backup archive holding the acceptance pack AND a
# mid-map suspend save parked at the start of chapter 6's first player phase, plus a
# JSON sidecar naming the slot, the board and the two units the journey drives.
# `tools/playwright/stateful-journeys.mjs --journey interaction-readout` consumes it.
#
# WHY A FIXTURE AND NOT A BROWSER PLAYTHROUGH. The authored relationship is only in
# scope on chapter 6, and chapter 6 is only reachable by playing the five chapters
# before it -- the campaign keeps its party between nodes, which is exactly why the
# bearer has to be seeded into the FIRST node's roster (`ROS-6`). Driving five
# objectives through a canvas to reach the sixth would be a long, flaky journey that
# tests the five chapters rather than the readout. So the play happens here, headless
# and deterministic, and the browser starts where the evidence is.
#
# WHY A SUSPEND SAVE AND NOT A PREP SAVE. Resuming a `mid_map` slot lands straight on
# GameMap with the authored board already spawned and deployment already settled, so
# the journey's first real input is the one it exists to make. A `between_map` slot
# would put the browser in Prep and make the run depend on Prep's deployment defaults,
# which are not what this fixture is evidence about.
#
# THE BEARER IS NOT PRE-POSITIONED, ON PURPOSE. He has movement 5 and starts within
# reach of `m006_revenant_1`, so the journey moves and attacks him like a player. A
# fixture that parked him adjacent would have pre-made the only decision the run makes.
#
# THE DICE ARE PINNED through `RngService.start_map()`, the engine's own test/replay
# hook, for the same reason `test_interaction_acceptance_playthrough.gd` pins them: an
# unpinned forecast is still a forecast, but a screenshot of one is evidence of a roll
# rather than of a relationship.

const AdopterPack = preload("res://scripts/tests/support/adopter_pack.gd")
const Exporter = preload("res://scripts/resources/CampaignPackExporter.gd")
const Preflight = preload("res://scripts/resources/CampaignArchivePreflight.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const Registry = preload("res://scripts/resources/CampaignPackRegistry.gd")
const Backup = preload("res://scripts/resources/CampaignBackupService.gd")
const Budgets = preload("res://scripts/resources/ImportBudgets.gd")

const PACK_ID := "prometheus-proving-grounds-internal-fe"
const PACK_VERSION := "0.1.0"
const CAMPAIGN_ID := "proving_grounds"
const ACCEPTANCE_MAP := "map_006_hallowed"
const GAME_MAP_SCENE := "res://scenes/core/GameMap.tscn"
const PREP_SCENE := "res://scenes/ui/PrepScreen.tscn"
const SUSPEND_SLOT := "resume_battle"
# Same value the playthrough proof pins, so the fixture's fight and the headless
# proof's fight are the same fight.
const MEASUREMENT_SEED := 20260920

# The five chapters that are played only to carry the party to the sixth, and the
# deterministic probe that satisfies each. Lifted from
# `test_interaction_acceptance_playthrough.gd`; they are playability probes, never
# balance evidence.
const CHAPTERS := [
	{"node_id": "node_01_rout", "map_id": "map_001", "objective": "rout"},
	{"node_id": "node_02_seize", "map_id": "map_002_seize", "objective": "seize"},
	{"node_id": "node_03_boss", "map_id": "map_003_defeat_boss", "objective": "defeat_boss"},
	{"node_id": "node_04_escape", "map_id": "map_004_escape", "objective": "escape"},
	{"node_id": "node_05_defend", "map_id": "map_005_defend", "objective": "survive"},
]
const ACCEPTANCE_NODE := "node_06_hallowed"

var _dm: Node
var _gs: Node
var _cm: Node
var _rng: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := _parse_args()
	var pack_arg: String = args.get("pack", "")
	var out_dir: String = args.get("out", "")
	if out_dir.is_empty():
		printerr("usage: --out <directory> [--pack <FE pack directory>]")
		quit(2)
		return
	await process_frame

	var pack_root := pack_arg
	if pack_root.is_empty():
		var located := AdopterPack.locate(
			"Project_Prometheus_Campaign_Pack_FE/packs/proving_grounds"
		)
		if located["state"] != AdopterPack.FOUND:
			printerr("acceptance pack unavailable: %s" % located["detail"])
			quit(1)
			return
		pack_root = located["path"]
	if not DirAccess.dir_exists_absolute(pack_root):
		printerr("pack directory does not exist: %s" % pack_root)
		quit(1)
		return
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

	# INSTALL, NEVER DIRECTORY-ACTIVATE. A pack activated straight from a checkout has
	# no `user://campaign_packs/installed/.../manifest.json`, so every chapter commit's
	# autosave fails while the play still completes -- and, more to the point here, a
	# backup archive can only carry a package the library actually holds.
	if not _install_pack(pack_root, out_dir):
		quit(1)
		return

	if not await _play_to_the_acceptance_chapter():
		quit(1)
		return
	var board := await _open_the_acceptance_board()
	if board.is_empty():
		quit(1)
		return
	if not _write_suspend_slot(board["cursor"]):
		quit(1)
		return
	if not _export_backup(out_dir, board):
		quit(1)
		return
	print("\nfixture ready in %s" % out_dir)
	quit(0)


# --- install --------------------------------------------------------------------------


func _install_pack(pack_root: String, out_dir: String) -> bool:
	# The PLAYER's budgets, for the same reason `export_pack_archive.gd` uses them: an
	# archive that only passes because a build tool was generous is not evidence about
	# the path a player's install takes.
	var limits: Preflight.Limits = Preflight.Limits.new(
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRIES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRY_COMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRY_UNCOMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_TOTAL_COMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_TOTAL_UNCOMPRESSED_BYTES
	)
	var archive := out_dir.path_join("%s-%s.zip" % [PACK_ID, PACK_VERSION])
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
	# THE INSTALLED PATH IS NOT THE VERSION DIRECTORY. The library keys a build by its
	# content fingerprint, so a pack installs one level below `installed_path()` and that
	# string-arithmetic helper names a directory holding no manifest. `installed_path` is
	# what the result carries and `resolve_installed_path` is the one that looks, so use
	# them rather than composing the path by hand.
	var path := String(installed.installed_path)
	if path.is_empty():
		path = Registry.resolve_installed_path(
			Registry.DEFAULT_STORAGE_ROOT, PACK_ID, PACK_VERSION, installed.content_fingerprint
		)
	if path.is_empty():
		printerr("the pack installed but the library cannot resolve where")
		return false
	if not bool(_dm.call("select_tier2_campaign_source", path, PACK_ID, PACK_VERSION)):
		printerr("installed pack did not activate: %s" % str(_dm.get("_activation_errors")))
		return false
	print("installed and activated %s %s" % [PACK_ID, PACK_VERSION])
	return true


# --- the five chapters before the evidence ----------------------------------------------


func _play_to_the_acceptance_chapter() -> bool:
	if not bool(_cm.call("start_campaign", CAMPAIGN_ID)):
		printerr("campaign %s did not start" % CAMPAIGN_ID)
		return false
	for chapter in CHAPTERS:
		if not await _play_chapter(chapter):
			return false
	if String(_cm.get("current_node_id")) != ACCEPTANCE_NODE:
		printerr(
			(
				"the five chapters did not lead to %s (stopped at %s)"
				% [ACCEPTANCE_NODE, _cm.get("current_node_id")]
			)
		)
		return false
	return true


func _play_chapter(chapter: Dictionary) -> bool:
	var node_id := String(chapter["node_id"])
	var map_id := String(chapter["map_id"])
	if String(_cm.get("current_node_id")) != node_id:
		printerr("expected to be at %s, am at %s" % [node_id, _cm.get("current_node_id")])
		return false
	var battle := await _begin_battle(map_id)
	if battle == null:
		return false
	var turn_manager: Node = battle.get_node_or_null("TurnManager")
	if turn_manager == null:
		printerr("%s has no TurnManager" % map_id)
		return false
	if not _resolve_objective(turn_manager, String(chapter["objective"])):
		printerr("%s objective probe was refused" % map_id)
		return false
	await process_frame
	var pending: Dictionary = _cm.call("get_pending_result")
	if not bool(pending.get("victory", false)):
		printerr("%s did not resolve as a victory" % map_id)
		return false
	if not bool(_cm.call("commit_pending_result")):
		printerr("%s did not commit" % map_id)
		return false
	print("  cleared %s" % map_id)
	return true


# --- chapter 6, left live -----------------------------------------------------------------


func _open_the_acceptance_board() -> Dictionary:
	var battle := await _begin_battle(ACCEPTANCE_MAP)
	if battle == null:
		return {}
	var cursor: Node = battle.get_node_or_null("MapCursor")
	if cursor == null:
		printerr("%s has no MapCursor, so no suspend save can be written" % ACCEPTANCE_MAP)
		return {}
	var bearer := _find_unit("m006_hallowed_bearer")
	var revenant := _find_unit("m006_revenant_1")
	if bearer == null or revenant == null:
		printerr("%s did not spawn the bearer and the revenant" % ACCEPTANCE_MAP)
		return {}
	# The whole fixture is worthless if the bearer cannot reach a target on the turn the
	# journey resumes into, so assert reachability here rather than discovering it as a
	# browser timeout. Chebyshev distance understates nothing: movement is orthogonal, so
	# a tile this far away is at least this many steps away.
	var bearer_tile: Vector2i = bearer.tile_position
	var target_tile: Vector2i = revenant.tile_position
	var steps := absi(bearer_tile.x - target_tile.x) + absi(bearer_tile.y - target_tile.y)
	var movement := int(bearer.data.movement) if bearer.get("data") != null else 0
	if steps - 1 > movement:
		printerr(
			(
				"the bearer at %s cannot reach %s in one turn (%d steps, movement %d)"
				% [bearer_tile, target_tile, steps - 1, movement]
			)
		)
		return {}
	print(
		(
			"%s is live: bearer at %s, revenant at %s (%d steps, movement %d)"
			% [ACCEPTANCE_MAP, bearer_tile, target_tile, steps - 1, movement]
		)
	)
	return {
		"cursor": cursor,
		"bearer_tile": [bearer_tile.x, bearer_tile.y],
		"target_tile": [target_tile.x, target_tile.y],
		"expected_rows": _expected_rows(bearer, revenant),
	}


# WHAT THE ENGINE SAYS THIS MATCHUP SHOWS, recorded here so the browser run can assert the
# panel against it instead of against "at least one row appeared". That weaker check passes
# for a panel that has lost the author's label, lost a profile to a suppression bug, or
# gained one; this one fails on all three. It is the same `preview_combat` call the forecast
# panel itself makes, so the two cannot be measuring different fights -- and the numbers are
# left out deliberately, because the fixture and the run pin the same seed but a summary is
# formatting, and asserting formatting would make every future wording change a failure.
func _expected_rows(attacker: Node, defender: Node) -> Array:
	var cr := root.get_node_or_null("CombatResolver")
	if cr == null or not cr.has_method("preview_combat"):
		return []
	var preview: Dictionary = cr.call("preview_combat", attacker, defender)
	var expected: Array = []
	for side in ["attacker", "defender"]:
		for row: Variant in preview.get("%s_interactions" % side, []):
			(
				expected
				. append(
					{
						"side": side,
						"profile_id": String((row as Dictionary).get("profile_id", "")),
						"label": String((row as Dictionary).get("label", "")),
						"direction": String((row as Dictionary).get("direction", "")),
					}
				)
			)
	return expected


func _begin_battle(map_id: String) -> Node:
	if not bool(_cm.call("launch_current_node")):
		printerr("%s did not launch" % map_id)
		return null
	await _settle()
	if current_scene == null or current_scene.scene_file_path != PREP_SCENE:
		printerr("%s did not reach Prep" % map_id)
		return null
	var plan := _deployment_plan(_cm.call("get_current_node"))
	if plan.is_empty():
		printerr("%s has no legal deployment plan" % map_id)
		return null
	_gs.call("set_next_map_deployment", plan)
	if not bool(_cm.call("begin_prepared_battle")):
		printerr("%s did not begin from Prep" % map_id)
		return null
	await _settle()
	if current_scene == null or current_scene.scene_file_path != GAME_MAP_SCENE:
		printerr("%s did not reach GameMap" % map_id)
		return null
	# Pinned AFTER the map is live, because `start_map` seeds the stream the map will
	# draw from; pinning before the scene exists seeds a stream nothing reads.
	if _rng != null and _rng.has_method("start_map"):
		_rng.call("start_map", MEASUREMENT_SEED)
	return current_scene


# --- the artifacts ------------------------------------------------------------------------


func _write_suspend_slot(cursor: Node) -> bool:
	# The real menu path: `_on_suspend_and_quit_requested` only adds a confirmation
	# dialog in front of this call, and a headless tool has nobody to confirm.
	if not bool(cursor.call("_write_suspend_save")):
		printerr("the suspend save was refused; no mid-map slot exists to back up")
		return false
	print("wrote the mid-map suspend slot %s" % SUSPEND_SLOT)
	return true


func _export_backup(out_dir: String, board: Dictionary) -> bool:
	var destination := out_dir.path_join("interaction-readout-backup.zip")
	var service = Backup.new(Registry.DEFAULT_STORAGE_ROOT, root.get_node_or_null("SaveManager"))
	var result = service.export_backup(destination)
	if not result.exported:
		printerr("backup export failed: %s" % str(result.errors))
		return false
	var sidecar := {
		"schema_version": 1,
		"backup": destination,
		"campaign_id": CAMPAIGN_ID,
		"campaign_slot": SUSPEND_SLOT,
		"map_id": ACCEPTANCE_MAP,
		"node_id": ACCEPTANCE_NODE,
		"package_id": PACK_ID,
		"package_version": PACK_VERSION,
		"seed": MEASUREMENT_SEED,
		"bearer": {"unit_id": "m006_hallowed_bearer", "tile": board["bearer_tile"]},
		"target": {"unit_id": "m006_revenant_1", "tile": board["target_tile"]},
		"expected_rows": board["expected_rows"],
	}
	var sidecar_path := out_dir.path_join("interaction-readout-fixture.json")
	var handle := FileAccess.open(sidecar_path, FileAccess.WRITE)
	if handle == null:
		printerr("could not write %s" % sidecar_path)
		return false
	handle.store_string("%s\n" % JSON.stringify(sidecar, "  "))
	handle.close()
	print("wrote %s (%d bytes) and %s" % [destination, result.total_bytes, sidecar_path])
	return true


# --- shared with the playthrough proof ------------------------------------------------------


func _deployment_plan(node: Variant = null) -> Dictionary:
	var path := String(_gs.get("next_map_data_path"))
	var resolved: Variant = _dm.call("resolve_battle_source", path)
	if resolved == null:
		return {}
	var map_data: Variant = resolved.get("battle_map")
	if map_data == null:
		return {}
	var tiles: Array = map_data.get("player_start_tiles")
	var roster: Array = _gs.get("player_roster")
	var party: Array[String] = []
	for unit_data in roster:
		if unit_data != null and String(unit_data.get("unit_id")) != "":
			party.append(String(unit_data.get("unit_id")))
	var ordered: Array[String] = []
	if node != null:
		for required_id in node.get("required_units"):
			var unit_id := String(required_id)
			if unit_id in party and not unit_id in ordered:
				ordered.append(unit_id)
	for unit_id in party:
		if not unit_id in ordered:
			ordered.append(unit_id)
	var plan := {}
	for i in range(mini(ordered.size(), tiles.size())):
		plan[ordered[i]] = tiles[i]
	return plan


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
	for unit in _gs.get("all_units") as Array:
		if unit != null and unit.get("data") != null:
			if String(unit.data.unit_id) == unit_id:
				return unit
	return null


func _settle() -> void:
	await process_frame
	await process_frame
	await process_frame


func _parse_args() -> Dictionary:
	var parsed := {}
	var args := OS.get_cmdline_user_args()
	var index := 0
	while index < args.size():
		var key := String(args[index])
		if key.begins_with("--") and index + 1 < args.size():
			parsed[key.substr(2)] = String(args[index + 1])
			index += 2
		else:
			index += 1
	return parsed
