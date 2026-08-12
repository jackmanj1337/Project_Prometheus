class_name GameMap extends Node2D
# The root scene for any battle. Loads MapData, paints the terrain from its string grid,
# and spawns units. Adding a new map = adding a new MapData resource; no code changes.

# Grid char -> terrain id -> tile source now resolves through TerrainRegistry, which
# owns the char vocabulary and the source ordering generate_tilesets.gd writes. This
# used to be a local table, and DataManager kept a second copy of the same char set
# for validation; the two could disagree, admitting a char that painted as wall.
var _terrain_registry: TerrainRegistry = TerrainRegistry.engine_defaults()

# Variant id -> tile source id for the tileset built at load. Held rather than asked
# per cell because pack-introduced sources are appended at activation and so have no
# stable id the registry could carry ([TER-2]).
var _variant_source_ids: Dictionary = {}

# Path to the active map's MapData resource. Defaults to map_001 for MVP.
# Will be set externally (e.g. by MainMenu) once campaign/chapter select lands.
@export var map_data_path: String = "res://data/maps/map_001_rout/map_001_data.tres"

# Packed scene used to instance unit nodes
@export var unit_scene: PackedScene = preload("res://scenes/units/Unit.tscn")

@onready var _terrain_layer: TileMapLayer = $TileMapLayer_Terrain
@onready var _overlay_layer: TileMapLayer = $TileMapLayer_Overlay
@onready var _overlay_top_layer: TileMapLayer = $TileMapLayer_OverlayTop
@onready var _units_container: Node2D = $UnitsContainer
@onready var _grid: GridManager = $GridManager
@onready var _cursor: MapCursor = $MapCursor
@onready var _camera: Camera2D = $Camera2D
@onready var _turn_manager: TurnManager = $TurnManager
@onready var _hud: Control = $HUDMainLayer/HUD
@onready var _attack_preview: Control = $HUDLayer/AttackPreview
@onready var _unit_details_screen: Control = $UnitDetailsLayer/UnitDetailsScreen

# Sole writer of Camera2D.position in production (B4). Built in _ready, shared
# with MapCursor via its setup() so both layers' camera operations flow through
# the same instance — keeps save/restore state consistent across phase changes.
const CameraControllerS = preload("res://scripts/core/CameraController.gd")
const HotseatControllerS = preload("res://scripts/core/HotseatController.gd")
# Autoload scripts carry no class_name, so preload the script to read its
# OFF_MAP_TILE sentinel (same pattern MapCursor uses).
const PairUpRegistryScript = preload("res://scripts/autoloads/PairUpRegistry.gd")
const OccupancyContextScript = preload("res://scripts/placement/OccupancyContext.gd")
# B4-PREP-DEPLOYMENT: validates the explicit deployment plan before it is spawned.
const DeploymentPlanS = preload("res://scripts/shared/DeploymentPlan.gd")
var _camera_ctrl: RefCounted = null
var _hotseat_controller: Node = null
# Band 6 fog. Built only when the encounter authored fog_enabled ([FOW-2]), so a
# non-fog map allocates nothing and registers no crossing consumer.
var _fog: FogRuntime = null

var battle_data: ResolvedBattleData = null
var map_data: Resource = null
var encounter_data: BattleEncounterDef = null


func _ready() -> void:
	var occupancy := get_node_or_null("/root/OccupancyService")
	if occupancy != null:
		occupancy.call("clear_delayed")
	var gs := get_node_or_null("/root/GameState")
	var resume_payload: Dictionary = {}
	if gs:
		var raw_payload: Variant = gs.get("next_map_suspend_payload")
		if raw_payload is Dictionary:
			resume_payload = raw_payload.duplicate(true)
		# Fresh map boot must not inherit stale scene-scoped unit state from a
		# prior battle. This is especially important after returning to the main
		# menu from an in-progress map in an exported build.
		gs.call("reset_map_state")
		# reset_map_state must clear stale scene units, but it also clears the
		# map-scoped ledger and rewind budget. Re-install the already-validated
		# resume transaction so a rewind/suspend scene reload retains both.
		if (
			not resume_payload.is_empty()
			# "campaign_restaged": this re-installs an already-restored envelope after
			# reset_map_state, so it must not emit a second "campaign_restored" (V053-08).
			and not bool(gs.call("configure_suspend_resume", resume_payload, "campaign_restaged"))
		):
			push_error("GameMap: could not re-stage suspend state after board cleanup")
			return
	# Load data first — terrain painting and grid setup both depend on map_data.grid.
	_load_map_data()
	# Resolve the active pack's terrain once, before the grid is validated or
	# painted, so char validation and painting agree with the movement costs
	# GridManager.setup() will resolve from the same registry a few lines below.
	_terrain_registry = TerrainRegistry.active()
	if map_data == null or map_data.grid.is_empty():
		push_error("GameMap: no grid in MapData; cannot paint terrain")
		return
	var map_width: int = map_data.grid[0].length()
	var map_height: int = map_data.grid.size()
	if not _validate_map(map_data.grid, map_width, map_height):
		return
	# The tileset is built before painting because a pack's terrain art is resolved at
	# activation, not baked into the engine's generated tileset.
	if not _build_terrain_tile_set():
		return
	_paint_terrain(map_data.grid, map_width, map_height)
	_grid.setup(_terrain_layer, _overlay_layer, map_width, map_height, _overlay_top_layer)
	# Grid-dim accessibility knob ([MRD-5]): the terrain layer joins the dim group
	# so the Settings slider can fade it live; units + overlays stay full opacity.
	_terrain_layer.add_to_group("grid_dim_target")
	# Build the camera controller and share it with the cursor (B4) so save/restore
	# state lives in exactly one place.
	_camera_ctrl = CameraControllerS.new()
	_camera_ctrl.setup(_camera, _grid)
	_cursor.setup(_grid, _camera, _turn_manager, _camera_ctrl)
	_hotseat_controller = HotseatControllerS.new()
	_hotseat_controller.set_cursor(_cursor)
	add_child(_hotseat_controller)
	_turn_manager.set_hotseat_controller(_hotseat_controller)
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = map_width * GameConstants.TILE_SIZE
	_camera.limit_bottom = map_height * GameConstants.TILE_SIZE
	# Apply the persisted map-zoom level (Display & Accessibility item 1) before the
	# initial center so the centre uses the right visible span. _silent variant just
	# sets Camera2D.zoom + level without repositioning — center_at follows.
	var sm := get_node_or_null("/root/SettingsManager")
	if sm != null:
		_camera_ctrl.set_zoom_index_silent(sm.get("map_zoom_index"))
		# Apply the persisted terrain dim now that the layer is in the group.
		_terrain_layer.modulate.a = 1.0 - clampf(float(sm.get("grid_dim")), 0.0, 0.5)
	_camera_ctrl.set_smoothing(false)
	_camera_ctrl.center_at(_get_camera_start())

	# Camera follows the enemy phase (#7): EnemyAI announces each acting unit and
	# phase_changed flips smoothing on so the camera glides during the AI turn.
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.ai_unit_acting.connect(_on_ai_unit_acting)
		bus.phase_changed.connect(_on_phase_changed)

	if not _spawn_units():
		return
	var is_resuming := not resume_payload.is_empty()
	# Snapshot for the Retry button — done after units land so HP/inventory reflect map start.
	# A suspend resume keeps the serialized mid-map runtime state intact instead
	# of running map-start resets over it.
	if gs:
		if not is_resuming:
			# .get()/.set()/.call() avoid typed-Node property errors (autoloads lack class_name).
			for u in gs.get("all_units") as Array:
				if u.has_method("reset_map_state"):
					u.reset_map_state()
			# Seed before the Retry snapshot so a replay restores this map's
			# timeline instead of the previous map's RNG state.
			var rng_svc := get_node_or_null("/root/RngService")
			if rng_svc != null:
				rng_svc.call("start_map")
		gs.set("battle_data", battle_data)
		gs.set("map_data", encounter_data)
		if not is_resuming:
			gs.call("begin_map_rewind_budget")
			gs.call("take_map_snapshot")
	# Fog comes up after spawning (it needs the roster) and before the first phase
	# starts, so the opening visible set is banked before anyone can move.
	_setup_fog(gs, bus)
	_turn_manager.set_history_cursor(_cursor)
	# Wire persistent HUD
	if _hud and _hud.has_method("setup"):
		_hud.setup(_grid, _turn_manager, _attack_preview, _unit_details_screen)
	if is_resuming:
		_apply_suspend_resume(resume_payload)
	else:
		# Start the cursor on the first player unit, not the map's (0,0) corner (#9).
		# After _hud.setup() so the cursor_moved emit reaches a HUD that can populate
		# its unit/terrain panels from the start tile.
		_place_cursor_at_start()
		# Kick off the first player phase.
		_turn_manager.start_map(encounter_data, _grid)


# Builds the fog runtime and registers its ambush trigger with the shared
# crossing resolver ([PCM-1]). A map without fog_enabled gets no runtime and no
# registered consumer, so the resolver stays empty and every move passes straight
# through — which is why this can land before the fog render slice.
func _setup_fog(gs: Node, bus: Node) -> void:
	if not FogService.is_fog_enabled(encounter_data):
		return
	_fog = FogRuntime.new()
	_fog.setup(encounter_data, gs, _grid, "blue", bus)
	var crossing := get_node_or_null("/root/CrossingService")
	for error in _fog.register(crossing):
		push_error(error)


# CrossingService is an autoload and outlives the map scene, so a consumer
# registered here MUST be dropped when the map goes away. Otherwise the next map
# — very likely a non-fog one — inherits a probe bound to a freed runtime.
func _exit_tree() -> void:
	if _fog != null:
		_fog.unregister(get_node_or_null("/root/CrossingService"))
		_fog = null


# Smooth camera glide during the enemy phase so AI moves are easy to follow;
# snappy (smoothing off) for the player phase so the cursor scroll stays tight.
func _on_phase_changed(new_phase: int, _faction_id: String = "") -> void:
	if _camera_ctrl != null:
		_camera_ctrl.set_smoothing(new_phase == GameState.Phase.ENEMY)
	# Recompute vision at phase start ([FOW-4] plan slice 2 step 3): units moved
	# and died during the other faction's phase, so the banked set is stale.
	if _fog != null:
		_fog.refresh()


# Pans the camera to centre on an acting enemy (#7). Half-tile offset is owned
# by CameraController.center_on_tile now (B4).
func _on_ai_unit_acting(unit: Node) -> void:
	if _camera_ctrl == null or not is_instance_valid(unit):
		return
	_camera_ctrl.center_on_tile(unit.tile_position)


# Returns the world-space camera start position. Uses map_data.camera_start_tile when
# explicitly set; otherwise computes the centroid of player_start_tiles.
func _get_camera_start() -> Vector2:
	if map_data.camera_start_tile != Vector2i(-1, -1):
		return _grid.tile_to_world(map_data.camera_start_tile)
	if map_data.player_start_tiles.is_empty():
		return Vector2.ZERO
	var sum := Vector2i.ZERO
	for t in map_data.player_start_tiles:
		sum += t
	var centroid := Vector2i(
		sum.x / map_data.player_start_tiles.size(), sum.y / map_data.player_start_tiles.size()
	)
	return _grid.tile_to_world(centroid)


# Places the map cursor on the first spawned player unit (#9). Falls back to
# leaving the cursor at its default tile if no player unit was spawned.
func _place_cursor_at_start() -> void:
	for u in _units_container.get_children():
		if "team" in u and u.team == "blue":
			_cursor.center_on_tile(u.tile_position)
			return


func _load_map_data() -> void:
	var selected_path: String = map_data_path
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		var override_path: String = gs.get("next_map_data_path")
		if override_path != "":
			selected_path = override_path
	var dm := get_node_or_null("/root/DataManager")
	if dm != null and dm.has_method("resolve_battle_source"):
		battle_data = dm.call("resolve_battle_source", selected_path)
	elif ResourceLoader.exists(selected_path):
		battle_data = ResolvedBattleData.from_legacy(load(selected_path) as MapData, selected_path)
	if battle_data != null:
		map_data = battle_data.battle_map
		encounter_data = battle_data.encounter
	if map_data == null or encounter_data == null:
		push_error("GameMap: missing resolved battle data for " + selected_path)


# Spawns player units from GameState.player_roster onto player_start_tiles,
# then enemy units from MapData.enemy_placements. All units get registered
# with GameState so GridManager can find them via _get_units().
func _spawn_units() -> bool:
	if map_data == null:
		return false
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		push_error("GameMap: GameState autoload missing")
		return false
	var resume_payload: Variant = gs.get("next_map_suspend_payload")
	if resume_payload is Dictionary and not resume_payload.is_empty():
		return _spawn_units_from_suspend(resume_payload)
	if not bool(gs.call("is_roster_ready_for_launch")):
		push_error(
			(
				"GameMap: launch roster not explicitly prepared for policy '%s' (source '%s')"
				% [
					String(gs.get("next_map_roster_policy")),
					String(gs.get("next_map_roster_source")),
				]
			)
		)
		return false
	var roster: Array = gs.get("player_roster")
	if roster == null or roster.is_empty():
		push_error("GameMap: prepared launch roster is empty")
		return false

	# Player units. An explicit deployment plan (chosen at prep) wins when present.
	# Without one, keep the historical inference — roster slot N →
	# player_start_tiles[N] — so a launch path with no prep screen (the bare
	# single-map launch) behaves exactly as it did before B4-PREP-DEPLOYMENT.
	var plan: Variant = gs.get("next_map_deployment")
	if plan is Dictionary and not (plan as Dictionary).is_empty():
		return _spawn_units_from_plan(plan as Dictionary, roster) and _spawn_enemy_units()

	for i in roster.size():
		if i >= map_data.player_start_tiles.size():
			break
		var u_data: UnitData = roster[i] as UnitData
		if u_data == null or u_data.is_incapacitated:
			continue  # permadeath: skip dead units in future deployments
		_place_and_spawn(u_data, map_data.player_start_tiles[i], "blue")

	return _spawn_enemy_units()


# Spawns the player side from an explicit deployment plan: unit_id -> start tile.
#
# Revalidates before spawning. Prep already gates Begin Battle on a legal plan, so
# an illegal plan arriving here means the party or the map changed underneath it —
# and spawning a half-legal board (a fallen unit, two units stacked on one tile)
# is worse than refusing to launch, which is how this function already treats an
# unprepared roster.
func _spawn_units_from_plan(plan: Dictionary, roster: Array) -> bool:
	var party: Array[UnitData] = []
	for entry in roster:
		if entry is UnitData:
			party.append(entry)

	# The node carries the deployment constraints ([CST-5]); a bare single-map
	# launch has no campaign position, and a null node simply skips them.
	var node: CampaignNode = null
	var cm := get_node_or_null("/root/CampaignManager")
	if cm != null and cm.has_method("get_current_node"):
		node = cm.call("get_current_node")

	var errors: Array[String] = DeploymentPlanS.validate(
		plan, party, node, map_data.player_start_tiles
	)
	if not errors.is_empty():
		for err in errors:
			push_error(err)
		return false

	for key in plan:
		var unit_id: String = String(key)
		for unit_data in party:
			if unit_data.unit_id == unit_id:
				_place_and_spawn(unit_data, plan[key], "blue")
				break
	return true


# Enemy/AI-controlled units. Each placement resolves to a UnitData via exactly
# one source, either an in-memory instance or a resource path.
# Optional placement keys: "faction" (defaults to "red"), "ai_profile"
# (explicit override; omission preserves the UnitData profile).
func _spawn_enemy_units() -> bool:
	var payload: Resource = encounter_data if encounter_data != null else map_data
	for placement in payload.enemy_placements:
		var tile: Vector2i = placement.get("tile", Vector2i.ZERO)
		var faction_id: String = placement.get("faction", "red")
		var u_data: UnitData = _resolve_placement_unit_data(placement)
		if u_data == null:
			continue  # _resolve_placement_unit_data already logged why
		_apply_enemy_placement_overrides(u_data, placement)
		# push_error + continue (not assert) so bad data is skipped in release
		# builds, where assert() is stripped.
		if u_data.unit_id == "":
			push_error(
				(
					"GameMap: enemy placement has empty unit_id — set it on the UnitData: %s"
					% str(placement)
				)
			)
			continue
		_place_and_spawn(u_data, tile, faction_id)
	return true


func _spawn_units_from_suspend(payload: Dictionary) -> bool:
	var gs := get_node_or_null("/root/GameState")
	var units: Array = payload.get("map_runtime", {}).get("units", [])
	if units.is_empty():
		push_error("GameMap: suspend payload has no map_runtime.units")
		return false
	for unit_entry in units:
		if not (unit_entry is Dictionary):
			push_error(
				"GameMap: suspend payload unit entry is not a Dictionary: %s" % str(unit_entry)
			)
			continue
		var u_data: UnitData = gs.call("unit_data_from_runtime_dict", unit_entry)
		if u_data == null or u_data.unit_id == "":
			push_error("GameMap: suspend payload unit has no unit_id: %s" % str(unit_entry))
			continue
		var faction_id: String = String(unit_entry.get("faction", "red"))
		var spawned: Node = _spawn_unit(u_data, u_data.tile_position, faction_id)
		# V030-SUS-01 (b): a paired support was parked at the off-map sentinel and
		# hidden when the pair formed (MapCursor.gd:1203-1204), and that sentinel
		# is what the payload serialized. _spawn_unit renders every unit visible,
		# so re-hide any unit restored onto the sentinel — otherwise the support
		# draws at (-1,-1). PairUpRegistry.restore (dict-only) can't do this.
		if spawned != null and u_data.tile_position == PairUpRegistryScript.OFF_MAP_TILE:
			spawned.visible = false
	return true


func _apply_suspend_resume(payload: Dictionary) -> void:
	var gs := get_node_or_null("/root/GameState")
	var map_runtime: Dictionary = payload.get("map_runtime", {})
	var reg := get_node_or_null("/root/PairUpRegistry")
	if reg:
		reg.call("restore", map_runtime.get("pair_carry", {}).get("pair_up", {}))
	var rng_svc := get_node_or_null("/root/RngService")
	if (
		rng_svc != null
		and map_runtime.get("rng", {}) is Dictionary
		and not map_runtime.get("rng", {}).is_empty()
	):
		rng_svc.call("from_save_dict", map_runtime["rng"])
	_turn_manager.start_map_from_suspend(encounter_data, _grid, map_runtime.get("turn", {}))
	_cursor.apply_suspend_ui_state(payload.get("suspend", {}))
	if gs:
		gs.call("clear_suspend_resume")


# [PUG-3] The spawn seam. An enemy placement carries exactly one UnitData source:
# in-memory `unit_data` (generated skirmish forces, editor-baked units, mid-map
# reinforcements) OR `unit_data_path` resource path (authored maps). Returns a
# fresh duplicate so the map owns its own copy; returns null on bad data so the
# caller can skip, not crash.
func _resolve_placement_unit_data(placement: Dictionary) -> UnitData:
	var raw_instance: Variant = placement.get("unit_data", null)
	var path: String = String(placement.get("unit_data_path", ""))
	var has_instance := raw_instance != null
	var has_path := path != ""
	if has_instance == has_path:
		push_error(
			(
				"GameMap: enemy placement must provide exactly one of unit_data_path or unit_data: "
				+ str(placement)
			)
		)
		return null
	if has_instance:
		var instance: UnitData = raw_instance as UnitData
		if instance == null:
			push_error("GameMap: enemy placement unit_data is not UnitData: " + str(placement))
			return null
		return instance.duplicate(true)  # fresh copy per map
	if not ResourceLoader.exists(path):
		push_error(
			"GameMap: enemy placement points at missing UnitData '%s': %s" % [path, str(placement)]
		)
		return null
	# ResourceLoader.exists() passed, but load() can still return null on a
	# corrupt .tres — null-check before .duplicate() so we skip, not crash.
	var loaded := load(path)
	if loaded == null:
		push_error("GameMap: failed to load enemy unit data at '%s' — skipping" % path)
		return null
	return loaded.duplicate(true)  # fresh copy per map


# Placement keys are overrides, not defaults. A generated inline unit can carry
# its own profile; authored maps may still override per placement when needed.
func _apply_enemy_placement_overrides(u_data: UnitData, placement: Dictionary) -> void:
	if placement.has("ai_profile"):
		u_data.ai_profile = String(placement.get("ai_profile", u_data.ai_profile))


func _spawn_unit(u_data: UnitData, tile: Vector2i, team: String) -> Unit:
	# Surface malformed inventory data (bad/empty entry_type, missing weapon_id/item_id)
	# at spawn — fails loud here rather than as a confusing null mid-combat.
	for entry in u_data.inventory:
		if entry != null:
			entry.validate()
	var unit: Unit = unit_scene.instantiate()
	unit.initialize(u_data, tile, team)
	_units_container.add_child(unit)
	unit.apply_faction_visual(encounter_data if encounter_data != null else map_data)
	unit.set_grid_manager(_grid)
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.call("register_unit", unit)
	return unit


# Public/non-standard placement resolves policy before this method reaches the
# private instancing seam. Normal movement remains owned by Unit/GridManager.
func _place_and_spawn(
	u_data: UnitData, desired_tile: Vector2i, team: String, policy: String = "nearest_free"
) -> Unit:
	var occupancy := get_node_or_null("/root/OccupancyService")
	if occupancy == null:
		push_error("GameMap: OccupancyService autoload missing")
		return null
	var context: RefCounted = OccupancyContextScript.create(
		u_data, desired_tile, policy, u_data.unit_id
	)
	context.source = self
	context.reason = "map_start_spawn"
	var result: RefCounted = occupancy.call("place", context, _grid)
	if not result.ok:
		push_error(
			(
				"GameMap: could not place unit '%s' at %s (%s)"
				% [u_data.unit_id, str(desired_tile), result.failure_reason]
			)
		)
		return null
	if result.fallback_used:
		push_warning(
			(
				"GameMap: unit '%s' moved from authored tile %s to nearest free tile %s"
				% [u_data.unit_id, str(desired_tile), str(result.to_tile)]
			)
		)
	return _spawn_unit(u_data, result.to_tile, team)


# Asserts all rows are the expected length and contain only known terrain chars.
func _validate_map(grid: Array[String], width: int, height: int) -> bool:
	if grid.size() != height:
		push_error("GameMap: grid has %d rows, expected %d" % [grid.size(), height])
		return false
	for y in grid.size():
		var row: String = grid[y]
		if row.length() != width:
			push_error("GameMap: row %d length %d, expected %d" % [y, row.length(), width])
			return false
		for x in row.length():
			var ch: String = row[x]
			if _terrain_registry.id_for_grid_char(ch).is_empty():
				push_error("GameMap: row %d col %d: unknown terrain char '%s'" % [y, x, ch])
				return false
	return true


# Builds the TileSet this map paints with: the engine's pre-generated sources plus one
# appended source per pack-introduced terrain or decorative variant ([TER-1], [TER-2]).
# Returns false when the pack named art that will not resolve, so the map refuses to
# load rather than painting the author's terrain as wall with no diagnostic.
func _build_terrain_tile_set() -> bool:
	var assets: Dictionary = {}
	var data_manager := get_node_or_null("/root/DataManager")
	if data_manager != null and data_manager.has_method("pack_assets"):
		assets = data_manager.call("pack_assets")
	var built := TerrainTileSetBuilder.build(_terrain_registry, _terrain_layer.tile_set, assets)
	if not built.valid():
		for error in built.errors:
			push_error("GameMap: %s" % error)
		return false
	_terrain_layer.tile_set = built.tile_set
	_variant_source_ids = built.source_ids
	return true


func _paint_terrain(grid: Array[String], width: int, height: int) -> void:
	for y in height:
		var row: String = grid[y]
		for x in width:
			# Art is chosen by VARIANT, while the terrain the tile reports (through the
			# source's terrain_type custom data) stays the shared terrain id — which is
			# why get_terrain_at and every id-matching consumer needed no change.
			var variant_id := _terrain_registry.variant_for_grid_char(row[x])
			# An unregistered char paints as the out-of-bounds terrain, preserving the
			# previous table's wall default; _validate_map has already refused it.
			var source_id: int = _terrain_registry.tile_source_id(
				TerrainRegistry.OUT_OF_BOUNDS_TERRAIN
			)
			if not variant_id.is_empty() and _variant_source_ids.has(variant_id):
				source_id = int(_variant_source_ids[variant_id])
			_terrain_layer.set_cell(Vector2i(x, y), source_id, Vector2i.ZERO)
