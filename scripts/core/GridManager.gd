class_name GridManager extends Node
# Authority on map geometry: terrain queries, tile/world conversions, movement
# range, pathfinding, and attack range. Reads terrain from an assigned TileMapLayer
# so that terrain is data-driven (painted in the editor, not hardcoded).

var map_width: int = 0
var map_height: int = 0

# Assigned by GameMap when the map loads
var _tilemap: TileMapLayer = null

# Base overlay layer for movement/attack/heal/danger highlights.
var _overlay: TileMapLayer = null
# Optional prototype overlay lane for MRD-7 shared-cell visual comparisons.
var _overlay_top: TileMapLayer = null

# Lazily-created dual-outline draw surface (V031-MRD-01) — a Node2D that
# strokes the threat perimeters above unit sprites; see _ensure_perimeter_overlay.
var _perimeter_overlay: Node2D = null

# Optional fallback when no TileMapLayer is assigned (tests, headless).
# Maps Vector2i tile -> String terrain type.
var _terrain_fallback: Dictionary = {}

# Terrain move costs, DEF/avoid bonuses and healing (GDD_02) now live in one place
# instead of three tables here plus three more across GameMap, DataManager and
# TurnManager. Resolved once at setup() so a pack activated mid-battle cannot change
# the terrain under a running map; tests that build a GridManager directly get the
# engine defaults without needing an autoload.
var _terrain: TerrainRegistry = TerrainRegistry.engine_defaults()


# M14 stage 2: hostility check, routed through GameState.are_hostile when the
# autoload is live. Without the autoload (headless --script tests that don't
# load every autoload) we fall back to "different team-string = hostile" —
# which is exactly the stage-1 binary behaviour the test suite already pins.
# Identity-equal (both null / same instance) is never hostile; missing `team`
# on either side is never hostile either (matches the prior `"team" in`
# guards).
func _hostile(a: Node, b: Node) -> bool:
	if a == null or b == null or a == b:
		return false
	if not ("team" in a) or not ("team" in b):
		return false
	var gs := get_node_or_null("/root/GameState") if is_inside_tree() else null
	if gs != null and gs.has_method("are_hostile"):
		return gs.are_hostile(a.team, b.team)
	return a.team != b.team


# Called by GameMap during _ready() to wire the layers.
func setup(
	terrain_layer: TileMapLayer,
	overlay_layer: TileMapLayer,
	width: int,
	height: int,
	overlay_top_layer: TileMapLayer = null
) -> void:
	_tilemap = terrain_layer
	_overlay = overlay_layer
	_overlay_top = overlay_top_layer
	map_width = width
	map_height = height
	_terrain = TerrainRegistry.active()


# The terrain definitions this grid resolves against. Exposed so UI and AI read the
# same numbers the movement code does rather than re-resolving the active registry.
func terrain_registry() -> TerrainRegistry:
	return _terrain


# Out-of-bounds tiles count as walls so callers don't need explicit bounds checks.
func get_terrain_at(tile: Vector2i) -> String:
	if _tilemap != null:
		var tile_data := _tilemap.get_cell_tile_data(tile)
		if tile_data == null:
			return TerrainRegistry.OUT_OF_BOUNDS_TERRAIN
		var terrain: Variant = tile_data.get_custom_data("terrain_type")
		if terrain == null or terrain == "":
			return TerrainRegistry.OUT_OF_BOUNDS_TERRAIN
		return terrain
	# Fallback for headless tests
	if _terrain_fallback.has(tile):
		return _terrain_fallback[tile]
	return TerrainRegistry.OUT_OF_BOUNDS_TERRAIN


# Test helper: assigns terrain to a tile when no TileMapLayer is in use
func set_terrain_fallback(tile: Vector2i, terrain: String) -> void:
	_terrain_fallback[tile] = terrain


# Returns the defender's DEF / Dodge bonuses for the terrain at `tile` as a
# dictionary {"def": int, "dodge": int}. Every caller — HUD,
# Unit.get_terrain_def_bonus / _dodge_bonus, CombatResolver, and EnemyAI's
# hypothetical-attack scoring — queries through this accessor or its by-id sibling,
# so GridManager owns the lookup contract and no caller reads a bonus table directly.
# Out-of-bounds / wall terrain returns zeros — never a counterattack hazard.
func get_terrain_bonuses(tile: Vector2i) -> Dictionary:
	return terrain_bonuses_for(get_terrain_at(tile))


# The same bonuses keyed by terrain id, for callers that already resolved the
# terrain (EnemyAI scores a hypothetical stand tile before committing to it).
func terrain_bonuses_for(terrain: String) -> Dictionary:
	return {
		"def": _terrain.def_bonus(terrain),
		"dodge": _terrain.avoid_bonus(terrain),
	}


# Alias kept so existing callers (HUD's "—" rendering, tests) keep one spelling of
# the impassable sentinel; the rule and the costs it applies to live together on
# TerrainRegistry.
const IMPASSABLE_MOVE_COST: int = TerrainRegistry.IMPASSABLE_MOVE_COST

# The HUD's More Info panel labels movement groups for players ("Foot", "Light"),
# while costs are keyed by GameConstants.VALID_MOVEMENT_TYPES. This table is the
# whole difference between the two vocabularies — it used to be a second cost table
# that restated the desert rule and carried a comment asking editors to keep the
# copies in sync by hand.
const DISPLAY_GROUP_MOVEMENT_TYPES := {
	"foot": "infantry",
	"mounted": "mounted",
	"armoured": "armoured",
	"light": "light_footed",
	"flying": "flying",
}


# Returns a `terrain`-specific move-cost reading for the common authored movement
# groups, so the HUD's terrain More Info panel can show the same numbers without
# having to invent a synthetic unit for each group. Static because the HUD reads it
# without a grid; `registry` defaults to the active terrain set, so a pack retune
# shows up in the panel and in movement together.
static func get_move_costs_for_groups(
	terrain: String, registry: TerrainRegistry = null
) -> Dictionary:
	var terrain_registry_ref: TerrainRegistry = (
		registry if registry != null else TerrainRegistry.active()
	)
	var costs := {}
	for group in DISPLAY_GROUP_MOVEMENT_TYPES:
		costs[group] = terrain_registry_ref.move_cost(
			terrain, String(DISPLAY_GROUP_MOVEMENT_TYPES[group])
		)
	return costs


func world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(world_pos.x) / GameConstants.TILE_SIZE, int(world_pos.y) / GameConstants.TILE_SIZE
	)


# Returns the top-left corner of the tile in world space.
func tile_to_world(tile: Vector2i) -> Vector2:
	return Vector2(tile.x * GameConstants.TILE_SIZE, tile.y * GameConstants.TILE_SIZE)


# Move cost factors in unit special qualities per GDD_02 desert rule.
# Checks SkillHandler for movement overrides (Acrobat, Pass, Nimble) first.
func get_move_cost(tile: Vector2i, unit: Node) -> int:
	var terrain := get_terrain_at(tile)

	# Skill override check (stubs return -1 until M9 skills are implemented)
	if unit != null and is_inside_tree():
		var sh := get_node_or_null("/root/SkillHandler")
		if sh:
			var override: int = sh.get_move_cost_override(unit, terrain)
			if override != -1:
				return override

	# Resolve the unit's single movement type (V021-11) and key the cost off it,
	# preserving the skill-override-first ordering above. Everything that used to be
	# a special case here — the flier's flat 1, the wall that blocks fliers too, the
	# desert's armoured/mounted/light_footed exception — is now a cell in the
	# terrain's cost column, so this reads one number instead of branching.
	return _terrain.move_cost(terrain, _movement_type_of_unit(unit))


# Resolves `unit`'s movement type. A real Unit exposes movement_type() (the single
# source of truth, GameConstants.movement_type_of over its class qualities), so we
# defer to it. Test stubs that only implement has_quality fall back to probing
# VALID_MOVEMENT_TYPES in the same precedence order. Defaults to infantry for a null
# unit or a stub with neither method.
func _movement_type_of_unit(unit: Node) -> String:
	if unit == null:
		return "infantry"
	if unit.has_method("movement_type"):
		return String(unit.call("movement_type"))
	if unit.has_method("has_quality"):
		for mt in GameConstants.VALID_MOVEMENT_TYPES:
			if unit.has_quality(mt):
				return mt
	return "infantry"


# Terrain that costs the impassable sentinel blocks the unit unless the Phasing
# skill is active. Asking the registry per movement type rather than testing for the
# literal id "wall" is what lets a pack author terrain that stops ground units but
# not fliers; with the engine defaults, wall is impassable to everyone (V021-11) and
# nothing else is, so shipped behaviour is unchanged.
# Enemy-occupied tiles block movement unless the Pass skill is active.
func is_passable(tile: Vector2i, unit: Node) -> bool:
	var terrain := get_terrain_at(tile)
	if _terrain.is_impassable_for(terrain, _movement_type_of_unit(unit)):
		# Phasing skill (Sage promotion) can pass through walls — stub returns false
		if unit != null and is_inside_tree():
			var sh := get_node_or_null("/root/SkillHandler")
			if sh and sh.can_phase_through(unit, terrain):
				return true
		return false
	var occupant := get_unit_at(tile)
	if occupant != null and occupant != unit:
		# Hostile units block; allies (same alliance group) can be passed through
		# during movement. M14 stage 2: routes through _hostile so blue/green allies
		# don't block each other when stage-3 content adds the green faction.
		if _hostile(unit, occupant):
			# Pass skill (Trickster) allows moving through enemies — stub returns false
			if is_inside_tree():
				var sh := get_node_or_null("/root/SkillHandler")
				if sh and sh.can_pass_through_enemies(unit):
					return true
			return false
	return true


# Separate from is_passable: can the unit END their move on this tile?
# A unit with Pass can move through enemy tiles but cannot stop on one.
func can_end_on_tile(tile: Vector2i, unit: Node) -> bool:
	var occupant := get_unit_at(tile)
	if occupant == null or occupant == unit:
		return true
	# Cannot stack on allies OR end on enemies (even with Pass)
	return false


# Resolves to GameState.all_units when this node is in the scene tree.
# Returns [] in --script test mode where the autoload isn't registered.
# Decoupling like this lets us test GridManager without spinning up GameState.
func _get_units() -> Array:
	if is_inside_tree():
		var gs := get_node_or_null("/root/GameState")
		if gs != null:
			# .get() avoids a type error: get_node_or_null returns Node, not GameState
			var units: Variant = gs.get("all_units")
			if units is Array:
				return units
	return []


# Linear scan of all units for the given tile. Returns null if empty.
func get_unit_at(tile: Vector2i) -> Node:
	for u in _get_units():
		if u.tile_position == tile:
			return u
	return null


# 4-direction adjacency (no diagonals per GDD_02). This is the single geometry
# seam: dijkstra_costs() iterates DIRS, so neighbour topology is defined here once.
# Direction-based features (displacement/shove/swap/pivot, etc.) must read neighbours
# via this seam rather than copying a 4-way literal — that keeps the parked hex-grid
# option open ([HEX-9]).
const DIRS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]


# Dijkstra cost map from `start` over terrain move costs. The single shared flood
# behind get_movement_range, get_movement_path, and EnemyAI's distance estimation.
#   max_cost          — caps expansion; pass GameConstants.INT_MAX for "whole map".
#   ignore_occupants  — when false, enemy-occupied tiles block traversal.
#   blocker_unit      — the moving unit: defines "enemy" for occupant checks and is
#                       passed to get_move_cost for unit-specific terrain costs. May
#                       be null (e.g. EnemyAI's occupant-agnostic distance flood).
#   came_from         — when a Dictionary is passed it is filled with tile->predecessor
#                       so callers can reconstruct a path.
# Returns { tile: cost } for every tile reachable within max_cost (start included).
# Heap is an insertion-sorted Array of [cost, tile]; pop_front yields the cheapest
# unvisited tile, and stale entries (a shorter path settled later) are skipped.
func dijkstra_costs(
	start: Vector2i,
	max_cost: int,
	ignore_occupants: bool,
	blocker_unit: Node,
	came_from: Dictionary = {}
) -> Dictionary:
	var costs: Dictionary = {start: 0}
	var heap: Array = [[0, start]]
	while not heap.is_empty():
		var entry: Array = heap.pop_front()
		var current_cost: int = entry[0]
		var current: Vector2i = entry[1]
		if current_cost > costs.get(current, GameConstants.INT_MAX):
			continue  # stale entry — a shorter path was already settled
		for d in DIRS:
			var next: Vector2i = current + d
			if get_terrain_at(next) == "wall":
				continue
			# Hostile units block traversal unless the caller opts out. Allies (same
			# alliance group) never block — M14 stage 2 routes through _hostile.
			if not ignore_occupants and blocker_unit != null:
				var occupant := get_unit_at(next)
				if _hostile(blocker_unit, occupant):
					continue
			var total: int = current_cost + get_move_cost(next, blocker_unit)
			if total > max_cost:
				continue
			if total < costs.get(next, GameConstants.INT_MAX):
				costs[next] = total
				came_from[next] = current
				var insert_idx := heap.size()
				for i in heap.size():
					if total <= heap[i][0]:
						insert_idx = i
						break
				heap.insert(insert_idx, [total, next])
	return costs


# Dijkstra over move costs from the unit's tile, capped at unit.data.movement.
# Tiles with enemy units occupying are NOT included even if reachable
# (you can't end your move on an enemy). Allies don't block traversal.
func get_movement_range(unit: Node) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if unit == null:
		return result
	var costs := dijkstra_costs(unit.tile_position, unit.data.movement, false, unit)
	# Only include tiles the unit can legally stop on (not occupied by anyone else).
	for tile in costs.keys():
		if can_end_on_tile(tile, unit):
			result.append(tile)
	return result


# Traceback over move costs. Returns the ordered tile list from the unit's current
# tile to target_tile inclusive. Empty if the target is unreachable within movement.
func get_movement_path(unit: Node, target_tile: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if unit == null:
		return path
	var start: Vector2i = unit.tile_position
	if start == target_tile:
		path.append(start)
		return path
	var came_from: Dictionary = {}
	var costs := dijkstra_costs(start, unit.data.movement, false, unit, came_from)
	if not costs.has(target_tile):
		return path
	# Reconstruct path from target back to start (start has no came_from entry).
	var node: Vector2i = target_tile
	path.append(node)
	while came_from.has(node):
		node = came_from[node]
		path.push_front(node)
	return path


# Reads the unit's currently equipped weapon's range. Returns (1, 1) when the
# unit has no usable weapon — get_attackable_enemies_from_tile then returns []
# but the caller can still query "what tiles would I threaten if armed".
func _get_weapon_range(unit: Node) -> Vector2i:
	if unit == null or not unit.has_method("get_equipped_weapon"):
		return Vector2i(1, 1)
	var weapon = unit.get_equipped_weapon()
	if weapon == null:
		return Vector2i(1, 1)
	return Vector2i(weapon.get_range_min(unit), weapon.get_range_max(unit))


# True when the unit's equipped weapon can be used to attack. Healing staves
# cannot — they are restricted to the Staff action. Keys off is_healing_staff()
# rather than weapon_type so future offensive/debuff staves remain attack-capable.
func _equipped_can_attack(unit: Node) -> bool:
	if unit == null or not unit.has_method("get_equipped_weapon"):
		return true
	var w: WeaponData = unit.get_equipped_weapon()
	return w == null or not w.is_healing_staff()


# Manhattan-distance ring at distances [range_min, range_max] from a tile.
func _tiles_in_range(center: Vector2i, range_min: int, range_max: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dx in range(-range_max, range_max + 1):
		for dy in range(-range_max, range_max + 1):
			var dist := absi(dx) + absi(dy)
			if dist >= range_min and dist <= range_max:
				out.append(center + Vector2i(dx, dy))
	return out


# All tiles attackable from any tile in from_tiles, excluding from_tiles themselves.
# Used to draw the red attack overlay around the blue movement overlay.
func get_attack_range_from_tiles(unit: Node, from_tiles: Array[Vector2i]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	# Healing-staff users have no attack range — skip the red overlay entirely.
	if not _equipped_can_attack(unit):
		return out
	var wrange := _get_weapon_range(unit)
	var seen: Dictionary = {}
	var from_set: Dictionary = {}
	for t in from_tiles:
		from_set[t] = true
	for src in from_tiles:
		for tile in _tiles_in_range(src, wrange.x, wrange.y):
			if not from_set.has(tile) and not seen.has(tile):
				seen[tile] = true
	for k in seen.keys():
		out.append(k)
	return out


# Heal reach around the movement range — selection-time analogue of
# get_attack_range_from_tiles for healing-staff users. Returns empty for any
# unit not currently equipped with a healing staff, so the caller can pick the
# right overlay (red attack vs orange heal) by looking at which list is empty.
# Playtest 3 #3 — without this a selected healer showed only movement range.
func get_staff_range_from_tiles(unit: Node, from_tiles: Array[Vector2i]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if unit == null or not unit.has_method("get_equipped_weapon"):
		return out
	var w: WeaponData = unit.get_equipped_weapon()
	if w == null or not w.is_healing_staff():
		return out
	var wrange := _get_weapon_range(unit)
	var from_set: Dictionary = {}
	for t in from_tiles:
		from_set[t] = true
	var seen: Dictionary = {}
	for src in from_tiles:
		for tile in _tiles_in_range(src, wrange.x, wrange.y):
			if not from_set.has(tile):
				seen[tile] = true
	for k in seen.keys():
		out.append(k)
	return out


# Union of from_tiles and all attackable tiles. Used by AI scoring.
func get_all_attack_tiles(unit: Node, from_tiles: Array[Vector2i]) -> Array[Vector2i]:
	var wrange := _get_weapon_range(unit)
	var seen: Dictionary = {}
	for src in from_tiles:
		seen[src] = true
		for tile in _tiles_in_range(src, wrange.x, wrange.y):
			seen[tile] = true
	var out: Array[Vector2i] = []
	for k in seen.keys():
		out.append(k)
	return out


# Enemies the unit could hit from `tile`, given its equipped weapon's range.
func get_attackable_enemies_from_tile(unit: Node, tile: Vector2i) -> Array[Node]:
	var out: Array[Node] = []
	if unit == null:
		return out
	# Healing staves can't attack — no targets regardless of range.
	if not _equipped_can_attack(unit):
		return out
	var wrange := _get_weapon_range(unit)
	for target in _get_units():
		# Only hostile units are attackable. M14 stage 2: routes through _hostile
		# so blue can't accidentally attack a green ally once stage-3 content lands.
		if not _hostile(unit, target):
			continue
		if target.data == null or target.data.hp <= 0:
			continue
		var dist: int = (
			absi(target.tile_position.x - tile.x) + absi(target.tile_position.y - tile.y)
		)
		if dist >= wrange.x and dist <= wrange.y:
			out.append(target)
	return out


func can_attack_from_tile(attacker: Node, at_tile: Vector2i, target: Node) -> bool:
	# Healing staves can't attack — consistent with get_attackable_enemies_from_tile.
	if attacker == null or not _equipped_can_attack(attacker):
		return false
	return in_weapon_range_from_tile(attacker, at_tile, target)


# True when `target` is within `unit`'s weapon range from `at_tile`, regardless of
# whether the weapon can attack. Staff-heal positioning uses this — can_attack_from_tile
# rejects healing staves, which is wrong for deciding where a healer should stand.
func in_weapon_range_from_tile(unit: Node, at_tile: Vector2i, target: Node) -> bool:
	if unit == null or target == null:
		return false
	var wrange := _get_weapon_range(unit)
	var dist: int = (
		absi(target.tile_position.x - at_tile.x) + absi(target.tile_position.y - at_tile.y)
	)
	return dist >= wrange.x and dist <= wrange.y


# Allies within staff range whose HP is below max. Used for staff target selection.
# Reads the unit's equipped weapon range — if it's a staff, that's the heal range.
func get_healable_allies(unit: Node) -> Array[Node]:
	var out: Array[Node] = []
	if unit == null:
		return out
	var wrange := _get_weapon_range(unit)
	for ally in _get_units():
		# Only same-alliance-group units are healable. M14 stage 2: routes through
		# _hostile so blue can heal green (and vice versa) once green units exist.
		# (`_hostile(u, u)` returns false — the ally==unit guard below still keeps
		# self-heal out of staff targeting.)
		if ally == unit:
			continue
		if _hostile(unit, ally):
			continue
		if not ("team" in ally):
			continue
		if ally.data == null or ally.data.hp >= ally.data.max_hp:
			continue
		var dist: int = (
			absi(ally.tile_position.x - unit.tile_position.x)
			+ absi(ally.tile_position.y - unit.tile_position.y)
		)
		if dist >= wrange.x and dist <= wrange.y:
			out.append(ally)
	return out


# Overlay tile source IDs (assigned to overlay TileMapLayer in editor):
#   0: Blue (movement), 1: Red (attack), 2: Heal, 3: Dark red (danger)
# Source 2's sprite is orange (#6) — the constant is named for its role, not its
# colour, so a future recolour needs no code change here.
const OVERLAY_BLUE := 0
const OVERLAY_RED := 1
const OVERLAY_HEAL := 2
const OVERLAY_DARK_RED := 3
# [TUR-2] The watch-set threat layer — a distinct DARKER red so a hand-picked
# enemy's threat reads inside the broader faction cloud. Source 4 is authored in
# assets/overlay_tileset.tres (generate_tilesets.gd OVERLAY_SOURCES[4] =
# "darker_red"; placeholder colour from generate_placeholder_assets.gd).
const OVERLAY_DARKER_RED := 4
const OVERLAY_BLUE_ON_DARK_RED := 5
const OVERLAY_RED_ON_DARK_RED := 6
const OVERLAY_HEAL_ON_DARK_RED := 7
const OVERLAY_BLUE_ON_DARKER_RED := 8
const OVERLAY_RED_ON_DARKER_RED := 9
const OVERLAY_HEAL_ON_DARKER_RED := 10
const OVERLAY_DARK_RED_PERIMETER_START := 11
const OVERLAY_DARKER_RED_PERIMETER_START := 26
const OVERLAY_PERIMETER_MASK_COUNT := 15

# ── [MRD-1] Overlay precedence registry ──────────────────────────────────────
# Every overlay shares ONE overlay TileMapLayer, so paint ORDER decides the
# winner of a shared cell (the last set_cell wins). Instead of hardcoding that
# order in each repaint — a z-order match every new overlay would have to edit —
# layers register precedence here and painters iterate in ASCENDING
# precedence (lower first, higher on top so it wins shared cells).
# Adding an overlay (healing zones, objective markers, …) is a registration, not
# a repaint edit ([EXT], Q10 watchout).
const OVERLAY_LAYER_MOVE := "move_range"
const OVERLAY_LAYER_ATTACK := "attack_range"
const OVERLAY_LAYER_HEAL := "heal_range"
const OVERLAY_LAYER_FACTION_THREAT := "faction_threat"
const OVERLAY_LAYER_WATCH_THREAT := "watch_threat"
const OVERLAY_LAYER_HOVER_PEEK := "hover_peek"  # peek move range (blue)
const OVERLAY_LAYER_HOVER_PEEK_ATTACK := "hover_peek_attack"  # peek attack reach (red)
const OVERLAY_LAYER_PATH_ARROWS := "path_arrows"

static var _overlay_registry: Dictionary = {}

const OVERLAY_ROLE_RANGE := "range"
const OVERLAY_ROLE_THREAT := "threat"
const OVERLAY_ROLE_EXCLUSIVE := "exclusive"

const SHARED_CELL_SINGLE := "single_layer"
const SHARED_CELL_BORDER_THROUGH := "border_through"
const SHARED_CELL_STACKED := "stacked"
const SHARED_CELL_STACKED_PERIMETER := "stacked_perimeter"
const SHARED_CELL_DUAL_OUTLINE := "dual_outline"

const SHARED_CELL_MODES := {
	SHARED_CELL_SINGLE: {"label": "Single layer"},
	SHARED_CELL_BORDER_THROUGH: {"label": "Threat center + range border"},
	SHARED_CELL_STACKED: {"label": "Second overlay layer"},
	SHARED_CELL_STACKED_PERIMETER: {"label": "Second overlay layer + threat perimeter"},
	SHARED_CELL_DUAL_OUTLINE: {"label": "Stacked fill + dual outline above units"},
}

const ThreatPerimeterOverlayScript = preload("res://scripts/core/ThreatPerimeterOverlay.gd")

const PERIMETER_EDGE_TOP := 1
const PERIMETER_EDGE_RIGHT := 2
const PERIMETER_EDGE_BOTTOM := 4
const PERIMETER_EDGE_LEFT := 8

const _RANGE_ON_THREAT_SOURCES := {
	OVERLAY_BLUE:
	{
		OVERLAY_DARK_RED: OVERLAY_BLUE_ON_DARK_RED,
		OVERLAY_DARKER_RED: OVERLAY_BLUE_ON_DARKER_RED,
	},
	OVERLAY_RED:
	{
		OVERLAY_DARK_RED: OVERLAY_RED_ON_DARK_RED,
		OVERLAY_DARKER_RED: OVERLAY_RED_ON_DARKER_RED,
	},
	OVERLAY_HEAL:
	{
		OVERLAY_DARK_RED: OVERLAY_HEAL_ON_DARK_RED,
		OVERLAY_DARKER_RED: OVERLAY_HEAL_ON_DARKER_RED,
	},
}

var shared_cell_mode: String = SHARED_CELL_DUAL_OUTLINE


# Seed the built-in layers once. Precedence gaps of 10 leave room to slot future
# overlays between the existing ones without renumbering.
static func _ensure_overlay_registry() -> void:
	if not _overlay_registry.is_empty():
		return
	register_overlay_layer(OVERLAY_LAYER_MOVE, 10, OVERLAY_ROLE_RANGE)
	register_overlay_layer(OVERLAY_LAYER_ATTACK, 10, OVERLAY_ROLE_RANGE)
	register_overlay_layer(OVERLAY_LAYER_HEAL, 10, OVERLAY_ROLE_RANGE)
	register_overlay_layer(OVERLAY_LAYER_FACTION_THREAT, 20, OVERLAY_ROLE_THREAT)
	register_overlay_layer(OVERLAY_LAYER_WATCH_THREAT, 30, OVERLAY_ROLE_THREAT)
	register_overlay_layer(OVERLAY_LAYER_HOVER_PEEK, 100, OVERLAY_ROLE_EXCLUSIVE)
	register_overlay_layer(OVERLAY_LAYER_HOVER_PEEK_ATTACK, 101, OVERLAY_ROLE_EXCLUSIVE)
	register_overlay_layer(OVERLAY_LAYER_PATH_ARROWS, 110, OVERLAY_ROLE_EXCLUSIVE)


static func register_overlay_layer(
	layer_id: String, precedence: int, role: String = OVERLAY_ROLE_RANGE
) -> void:
	_overlay_registry[layer_id] = {"precedence": precedence, "role": role}


static func overlay_layer_precedence(layer_id: String) -> int:
	_ensure_overlay_registry()
	if _overlay_registry.has(layer_id):
		return int(_overlay_registry[layer_id]["precedence"])
	push_warning("GridManager: unregistered overlay layer '%s' — painting it last" % layer_id)
	return 1 << 30  # unregistered layers paint last


static func overlay_layer_role(layer_id: String) -> String:
	_ensure_overlay_registry()
	if _overlay_registry.has(layer_id):
		return String(_overlay_registry[layer_id].get("role", OVERLAY_ROLE_RANGE))
	return OVERLAY_ROLE_RANGE


func set_shared_cell_mode(mode: String) -> void:
	if not SHARED_CELL_MODES.has(mode):
		push_warning("GridManager: unknown shared-cell overlay mode '%s'" % mode)
		return
	shared_cell_mode = mode
	if not _shared_cell_mode_uses_top_overlay(shared_cell_mode):
		_clear_top_overlay()
	if shared_cell_mode != SHARED_CELL_DUAL_OUTLINE:
		_clear_perimeter_overlay()


func _shared_cell_mode_uses_top_overlay(mode: String) -> bool:
	return (
		mode == SHARED_CELL_STACKED
		or mode == SHARED_CELL_STACKED_PERIMETER
		or mode == SHARED_CELL_DUAL_OUTLINE
	)


func _clear_top_overlay() -> void:
	if _overlay_top != null:
		_overlay_top.clear()


func _paint_overlay(tiles: Array[Vector2i], source_id: int, target: TileMapLayer = null) -> void:
	var layer := target if target != null else _overlay
	if layer == null:
		return
	for t in tiles:
		layer.set_cell(t, source_id, Vector2i.ZERO)


func _sorted_overlay_ids(layer_specs: Dictionary) -> Array:
	var ids: Array = layer_specs.keys()
	ids.sort_custom(func(a, b): return overlay_layer_precedence(a) < overlay_layer_precedence(b))
	return ids


func _spec_tiles(spec: Dictionary) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	if spec.has("tiles"):
		tiles.assign(spec["tiles"])
	return tiles


func _paint_single_layer(layer_specs: Dictionary) -> void:
	for id in _sorted_overlay_ids(layer_specs):
		var spec: Dictionary = layer_specs[id]
		_paint_overlay(_spec_tiles(spec), int(spec.get("source", OVERLAY_DARK_RED)))


func _paint_stacked_layers(layer_specs: Dictionary) -> void:
	for id in _sorted_overlay_ids(layer_specs):
		var spec: Dictionary = layer_specs[id]
		var source := int(spec.get("source", OVERLAY_DARK_RED))
		var role := overlay_layer_role(id)
		var target := _overlay if role == OVERLAY_ROLE_THREAT else _overlay_top
		_paint_overlay(_spec_tiles(spec), source, target)


static func threat_perimeter_mask(tile: Vector2i, threat_tiles: Dictionary) -> int:
	var mask := 0
	if not threat_tiles.has(tile + Vector2i(0, -1)):
		mask |= PERIMETER_EDGE_TOP
	if not threat_tiles.has(tile + Vector2i(1, 0)):
		mask |= PERIMETER_EDGE_RIGHT
	if not threat_tiles.has(tile + Vector2i(0, 1)):
		mask |= PERIMETER_EDGE_BOTTOM
	if not threat_tiles.has(tile + Vector2i(-1, 0)):
		mask |= PERIMETER_EDGE_LEFT
	return mask


static func threat_perimeter_source(threat_source: int, mask: int) -> int:
	var clamped_mask: int = clampi(mask, 0, OVERLAY_PERIMETER_MASK_COUNT)
	if clamped_mask == 0:
		return threat_source
	match threat_source:
		OVERLAY_DARK_RED:
			return OVERLAY_DARK_RED_PERIMETER_START + clamped_mask - 1
		OVERLAY_DARKER_RED:
			return OVERLAY_DARKER_RED_PERIMETER_START + clamped_mask - 1
		_:
			return threat_source


func _threat_union(layer_specs: Dictionary) -> Dictionary:
	var threat_tiles: Dictionary = {}
	for id in _sorted_overlay_ids(layer_specs):
		if overlay_layer_role(id) != OVERLAY_ROLE_THREAT:
			continue
		var spec: Dictionary = layer_specs[id]
		for tile in _spec_tiles(spec):
			threat_tiles[tile] = true
	return threat_tiles


# Pure world-space outline geometry for the perimeter of `tiles` (a tile->bool
# set): a flat [from, to, from, to, ...] point-pair list built from the same
# edge-mask logic the stacked_perimeter tile variants use. Pure + static so
# the dual-outline geometry is testable headless without a canvas.
static func perimeter_edge_segments(tiles: Dictionary, tile_size: int) -> PackedVector2Array:
	var segments := PackedVector2Array()
	for tile_any in tiles:
		var tile: Vector2i = tile_any
		var mask := threat_perimeter_mask(tile, tiles)
		if mask == 0:
			continue
		var origin := Vector2(tile.x * tile_size, tile.y * tile_size)
		var size := float(tile_size)
		if mask & PERIMETER_EDGE_TOP:
			segments.append(origin)
			segments.append(origin + Vector2(size, 0))
		if mask & PERIMETER_EDGE_RIGHT:
			segments.append(origin + Vector2(size, 0))
			segments.append(origin + Vector2(size, size))
		if mask & PERIMETER_EDGE_BOTTOM:
			segments.append(origin + Vector2(0, size))
			segments.append(origin + Vector2(size, size))
		if mask & PERIMETER_EDGE_LEFT:
			segments.append(origin)
			segments.append(origin + Vector2(0, size))
	return segments


func _paint_stacked_perimeter(layer_specs: Dictionary) -> void:
	var threat_tiles := _threat_union(layer_specs)
	for id in _sorted_overlay_ids(layer_specs):
		var spec: Dictionary = layer_specs[id]
		var source := int(spec.get("source", OVERLAY_DARK_RED))
		var role := overlay_layer_role(id)
		if role == OVERLAY_ROLE_THREAT:
			for tile in _spec_tiles(spec):
				var mask := threat_perimeter_mask(tile, threat_tiles)
				var paint_source := threat_perimeter_source(source, mask)
				_overlay.set_cell(tile, paint_source, Vector2i.ZERO)
		else:
			_paint_overlay(_spec_tiles(spec), source, _overlay_top)


# V031-MRD-01 `dual_outline`: the stacked fill underneath, plus two world-space
# outlines drawn above unit sprites — bright red around every threatened tile,
# dark red around the watched subset, dark over bright (owner spec 2026-07-12).
func _paint_dual_outline(layer_specs: Dictionary) -> void:
	_paint_stacked_layers(layer_specs)
	var overlay := _ensure_perimeter_overlay()
	if overlay == null:
		return
	var watch_tiles: Dictionary = {}
	if layer_specs.has(OVERLAY_LAYER_WATCH_THREAT):
		for tile in _spec_tiles(layer_specs[OVERLAY_LAYER_WATCH_THREAT]):
			watch_tiles[tile] = true
	overlay.set_perimeters(
		perimeter_edge_segments(_threat_union(layer_specs), GameConstants.TILE_SIZE),
		perimeter_edge_segments(watch_tiles, GameConstants.TILE_SIZE)
	)


# Lazily creates the outline draw surface (same pattern as MapCursor's
# PathArrows layer). Null on headless grids with no real overlay layer (the
# pure-logic fallback grid). Created even before this grid enters the tree —
# the child simply starts rendering when the grid does.
func _ensure_perimeter_overlay() -> Node2D:
	if _perimeter_overlay != null:
		return _perimeter_overlay
	if _overlay == null:
		return null
	_perimeter_overlay = ThreatPerimeterOverlayScript.new()
	_perimeter_overlay.name = "ThreatPerimeterOverlay"
	# Above unit sprites (z 0) so the outlines read over units per the owner
	# spec; below the transient movement path arrows (z 100).
	_perimeter_overlay.z_index = 90
	add_child(_perimeter_overlay)
	return _perimeter_overlay


func _clear_perimeter_overlay() -> void:
	if _perimeter_overlay != null:
		_perimeter_overlay.clear()


func _range_source_on_threat(range_source: int, threat_source: int) -> int:
	var by_threat: Dictionary = _RANGE_ON_THREAT_SOURCES.get(range_source, {})
	return int(by_threat.get(threat_source, range_source))


func _paint_border_through(layer_specs: Dictionary) -> void:
	var threat_sources: Dictionary = {}
	var ids := _sorted_overlay_ids(layer_specs)
	for id in ids:
		if overlay_layer_role(id) != OVERLAY_ROLE_THREAT:
			continue
		var spec: Dictionary = layer_specs[id]
		var source := int(spec.get("source", OVERLAY_DARK_RED))
		for tile in _spec_tiles(spec):
			threat_sources[tile] = source
			_overlay.set_cell(tile, source, Vector2i.ZERO)
	for id in ids:
		var role := overlay_layer_role(id)
		if role == OVERLAY_ROLE_THREAT:
			continue
		var spec: Dictionary = layer_specs[id]
		var source := int(spec.get("source", OVERLAY_DARK_RED))
		for tile in _spec_tiles(spec):
			var paint_source := source
			if role == OVERLAY_ROLE_RANGE and threat_sources.has(tile):
				paint_source = _range_source_on_threat(source, int(threat_sources[tile]))
			_overlay.set_cell(tile, paint_source, Vector2i.ZERO)


# [MRD-1] Repaint the shared overlay from a set of layers, in registered
# precedence order (ascending) so higher-precedence layers win shared cells.
# `layer_specs` maps a registered layer_id -> { "tiles": Array[Vector2i],
# "source": int }. Clears first, so passing {} turns the overlay off.
func repaint_overlays(layer_specs: Dictionary) -> void:
	if _overlay == null:
		return
	_overlay.clear()
	_clear_top_overlay()
	_clear_perimeter_overlay()
	if shared_cell_mode == SHARED_CELL_DUAL_OUTLINE and _overlay_top != null:
		_paint_dual_outline(layer_specs)
	elif shared_cell_mode == SHARED_CELL_STACKED_PERIMETER and _overlay_top != null:
		_paint_stacked_perimeter(layer_specs)
	elif shared_cell_mode == SHARED_CELL_STACKED and _overlay_top != null:
		_paint_stacked_layers(layer_specs)
	elif shared_cell_mode == SHARED_CELL_BORDER_THROUGH:
		_paint_border_through(layer_specs)
	else:
		_paint_single_layer(layer_specs)


func show_movement_overlay(tiles: Array[Vector2i]) -> void:
	_clear_top_overlay()
	_paint_overlay(tiles, OVERLAY_BLUE)


func show_attack_overlay(tiles: Array[Vector2i]) -> void:
	_clear_top_overlay()
	_paint_overlay(tiles, OVERLAY_RED)


func show_heal_overlay(tiles: Array[Vector2i]) -> void:
	_clear_top_overlay()
	_paint_overlay(tiles, OVERLAY_HEAL)


# The full threat area of every living, attack-capable enemy: each tile an enemy
# could move to (plus staying put) AND the attack range from each of those tiles
# (#11) — not just the attack range from where the enemy currently stands.
#
# `viewer_faction` is the faction from whose perspective "danger" is measured.
# Defaults to "blue" so existing single-player callers stay valid; the cursor
# passes its _controlling_faction so a hotseat green player sees green's
# threats, not blue's (code review 2026-06-10 issue 2.4).
func get_enemy_danger_tiles(viewer_faction: String = "blue") -> Array[Vector2i]:
	var seen: Dictionary = {}
	var gs := get_node_or_null("/root/GameState") if is_inside_tree() else null
	for u in _get_units():
		if not ("team" in u):
			continue
		var hostile: bool
		if gs != null and gs.has_method("are_hostile"):
			hostile = gs.are_hostile(viewer_faction, u.team)
		else:
			# Headless fallback — different team string = hostile (stage-1 binary).
			hostile = u.team != viewer_faction
		if not hostile:
			continue
		# get_unit_threat_tiles applies the dead/healer guards and dedups per unit;
		# the outer dict dedups across the whole hostile set. [TUR-1] extraction.
		for t in get_unit_threat_tiles(u):
			seen[t] = true
	var out: Array[Vector2i] = []
	for tile in seen.keys():
		out.append(tile)
	return out


# [TUR-1] The threat area of a SINGLE unit: every tile it could move to (plus
# staying put) AND the attack reach from each of those tiles (#11). Returns []
# for a null/teamless/dead unit or one whose equipped weapon can't attack (a
# healer threatens nothing). This is the reusable per-unit primitive:
# get_enemy_danger_tiles unions it over the hostile set, and the contextual
# watch-set threat view (`B6-MRD` slice 2) / gamepad R3 arm consume it directly.
func get_unit_threat_tiles(unit: Node) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if unit == null or not ("team" in unit):
		return out
	if unit.data == null or unit.data.hp <= 0:
		return out
	# A healing-staff unit threatens no tiles — keep it out of the threat area.
	if not _equipped_can_attack(unit):
		return out
	# Reachable tiles (plus staying put), then the union of attack reach from all
	# of them. get_all_attack_tiles dedups, so the extra current tile is safe.
	var move_tiles := get_movement_range(unit)
	if not move_tiles.has(unit.tile_position):
		move_tiles.append(unit.tile_position)
	return get_all_attack_tiles(unit, move_tiles)


# Paints the danger zone for `viewer_faction` (see get_enemy_danger_tiles) onto
# the overlay. Triggered via MapCursor's show_danger_zone toggle / middle mouse.
func show_enemy_danger_zone(viewer_faction: String = "blue") -> void:
	if _overlay == null:
		return
	_clear_top_overlay()
	_paint_overlay(get_enemy_danger_tiles(viewer_faction), OVERLAY_DARK_RED)


# Clears every painted overlay tile. Called between selection states and at phase change.
func clear_overlays() -> void:
	if _overlay == null:
		return
	_overlay.clear()
	_clear_top_overlay()
