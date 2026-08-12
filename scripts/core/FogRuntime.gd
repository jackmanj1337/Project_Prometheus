class_name FogRuntime extends RefCounted
# Band 6 fog of war, Slice 3: reveal-on-move + the ambush interrupt ([FOW-4] A-full).
# Plan: AGENT/Docs/plans/band6_fog_of_war_implementation_plan_2026-07-03.md
#
# This is the FIRST consumer of the shared crossing resolver ([PCM-1]). It
# registers a probe and returns an ambush trigger; it does not touch
# Unit.move_along_path, does not hook the tween, and owns no movement code. The
# plan's original step ("in the move_along_path per-step loop") is superseded by
# `[PCM-3]` — see the correction in the plan's Existing Code Touchpoints.
#
# Ambush shape, per the model: {interrupt: halt, ends_activation: false}. The move
# stops on the tile that spotted the enemy, and the unit still gets to act — being
# ambushed does not cost you your turn ([PCM-5]/[PCM-6]).

const CONSUMER_ID := "fog_ambush"
const TRIGGER_ID := "fog_ambush"

# The faction whose eyes we are computing through — the one whose units move and
# whose view the fog mask is painted for.
var viewer_faction: String = "blue"
var map_data: Resource = null
var game_state: Node = null
var grid: Node = null
# Optional. A RefCounted cannot walk the tree, so the owner passes the bus in
# rather than this reaching for an autoload it may not have.
var event_bus: Node = null

# Units this viewer has already spotted, keyed by unit node. Runtime-only in this
# slice; slice 5 persists it as `discovered_units` (F1). A spotted unit stays
# spotted for the rest of the map — fog hides the unknown, it does not re-hide
# what you have already seen walking around.
var discovered_units: Dictionary = {}

# The viewer's visible tile set as of the last refresh. Recomputed at phase start
# and after each move; the render mask (slice 2) paints its complement.
var visible_tiles: Dictionary = {}


func setup(
	p_map_data: Resource,
	p_game_state: Node,
	p_grid: Node,
	p_faction: String = "blue",
	p_event_bus: Node = null
) -> void:
	map_data = p_map_data
	game_state = p_game_state
	grid = p_grid
	viewer_faction = p_faction
	event_bus = p_event_bus
	refresh()


func is_active() -> bool:
	return FogService.is_fog_enabled(map_data)


# Recomputes the visible set and banks everything currently in view as
# discovered. Call at phase start and after any move settles.
func refresh() -> void:
	if not is_active():
		visible_tiles = {}
		return
	visible_tiles = FogService.compute_visible_tiles(viewer_faction, game_state, grid)
	for unit in _hostiles():
		if visible_tiles.has(unit.tile_position):
			discovered_units[unit] = true


func is_discovered(unit: Node) -> bool:
	return discovered_units.has(unit)


# ── Crossing consumer ────────────────────────────────────────────────────────


func register(crossing_service: Node) -> Array[String]:
	if crossing_service == null:
		return ["FogRuntime: no crossing service to register with"]
	return crossing_service.register_consumer(CONSUMER_ID, probe)


func unregister(crossing_service: Node) -> void:
	if crossing_service != null:
		crossing_service.unregister_consumer(CONSUMER_ID)


# Called once per crossed tile by the resolver, over the path as data.
#
# The check is deliberately narrow: only the MOVER's own disc changes during a
# move — every other unit stands still, so anything they can see was already
# banked by refresh(). So "does this step reveal someone" reduces to "is there an
# undiscovered hostile within the mover's vision radius of this tile".
func probe(context: Dictionary) -> Variant:
	if not is_active():
		return null
	var mover: Node = context.get("unit", null)
	if mover == null or not is_instance_valid(mover) or _team_of(mover) != viewer_faction:
		return null
	var tile: Vector2i = context.get("tile", Vector2i.ZERO)
	var radius: int = FogService.vision_radius(mover)
	var spotted: Array[Node] = []
	for hostile in _hostiles():
		if discovered_units.has(hostile):
			continue
		if FogService.distance(hostile.tile_position, tile) <= radius:
			spotted.append(hostile)
	if spotted.is_empty():
		return null
	return {
		"id": TRIGGER_ID,
		# [FOW-4] requires halt — the whole point of an ambush is that you do not
		# walk your unit into the rest of the ambushing squad.
		"interrupt": "halt",
		# Being ambushed does not spend the unit's action ([PCM-6]).
		"ends_activation": false,
		"effect": func(_ctx: Dictionary) -> void: _reveal(spotted, mover),
	}


# Banks the newly spotted units and announces them. Runs at resolution time, so
# discovery is committed before any animation plays — a halted move and its
# reveal can never disagree, and an Instant-speed move behaves identically.
func _reveal(spotted: Array[Node], mover: Node) -> void:
	for unit in spotted:
		discovered_units[unit] = true
	refresh()
	if event_bus != null and event_bus.has_signal("fog_units_spotted"):
		event_bus.fog_units_spotted.emit(spotted, mover)


# ── Helpers ──────────────────────────────────────────────────────────────────


# Every living unit not on the viewer's side. Fog is per-faction, so "hostile"
# here means "not mine" rather than "red" — a green third army hides too.
func _hostiles() -> Array[Node]:
	var out: Array[Node] = []
	if game_state == null:
		return out
	var all_units: Variant = game_state.get("all_units")
	if not (all_units is Array):
		return out
	for unit in all_units:
		if unit == null or not is_instance_valid(unit):
			continue
		if _team_of(unit) == viewer_faction:
			continue
		if unit.get("data") == null or int(unit.data.hp) <= 0:
			continue
		out.append(unit)
	return out


func _team_of(unit: Node) -> String:
	return String(unit.get("team")) if unit != null else ""
