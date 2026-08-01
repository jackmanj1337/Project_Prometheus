class_name TerrainRegistry extends RefCounted
# Open registry of terrain definitions: the movement, defence, avoid, healing and
# tile-source facts that decide what standing on a tile means.
#
# Every other content family in the zero-content work projected an existing
# `*Data` resource. Terrain had none — its numbers were baked into SIX engine
# tables that each owned part of the same vocabulary and could drift apart:
#
#   1. `GridManager._DEFAULT_MOVE_COSTS`               move cost per terrain
#   2. `GridManager.TERRAIN_DEF_BONUS` / `_DODGE_BONUS` defender bonuses
#   3. `GridManager.get_move_costs_for_groups`          a SECOND cost table, keyed
#      by HUD labels ("foot"/"light") rather than by `VALID_MOVEMENT_TYPES`, with
#      the desert exception written out twice and a comment asking future editors
#      to keep the copies in sync by hand
#   4. `GameMap._CHAR_TO_SOURCE`                        grid char -> tile source
#   5. `DataManager`'s inline `valid_terrain` char set  a second copy of #4's keys
#   6. `TurnManager._apply_fort_healing`'s `== "fort"`  healing, as a literal
#
# That is the closed-switch smell `AGENTS.md` names: adding a terrain meant editing
# six engine sites. This registry is the single authority all six now read, and the
# seam the Tier-2 `terrain` family authors against.
#
# A preloaded script rather than an autoload, matching `AIProfileRegistry`: the
# validator (`EntitySchemaRegistry`), boot validation (`DataManager`) and runtime
# (`GridManager`, `GameMap`, `TurnManager`) all need it, and headless `--script`
# tests that load no autoloads must still resolve terrain.

const GameConstants = preload("res://scripts/shared/GameConstants.gd")

# Cost that marks a tile unreachable. Kept here rather than on `GridManager` so the
# "999 means impassable" rule and the costs it applies to share one owner; the
# `GridManager` const is now an alias for compatibility with existing callers.
const IMPASSABLE_MOVE_COST: int = 999

# The terrain reported for an unpainted or out-of-bounds tile. `GridManager` returns
# it so callers never need explicit bounds checks, so it must always be registered.
const OUT_OF_BOUNDS_TERRAIN := "wall"

# Fields a pack's `terrain` document may retune. Held as data so admitting one more
# is a row here plus a schema property, not another branch in a merge function.
# `tile_source_id` is absent on purpose: it indexes the engine's own generated
# tileset, so it is engine identity, not authored content.
const AUTHORABLE_FIELDS: Array[String] = [
	"display_name",
	"grid_char",
	"move_costs",
	"def_bonus",
	"avoid_bonus",
	"heal_fraction",
	"tile_asset_id",
]

# The terrains the engine can paint, seeded with exactly the numbers the six tables
# above carried — this is a consolidation, not a retune. `tile_source_id` matches
# the source ordering `scripts/tools/generate_tilesets.gd` writes.
#
# `move_costs` is keyed by `GameConstants.VALID_MOVEMENT_TYPES`, which resolves the
# old duplicate-table problem: `get_move_cost` keyed off real movement types while
# `get_move_costs_for_groups` keyed off HUD labels, so the desert exception existed
# twice in two vocabularies. There is now one cost per terrain per movement type and
# no special cases in code: the flier's "ignores ground terrain" is a column of 1s,
# and the wall's "blocks everyone, fliers included" (V021-11) is a column of 999s.
const ENGINE_TERRAINS := {
	"plain":
	{
		"grid_char": ".",
		"display_name": "Plain",
		"tile_source_id": 0,
		"def_bonus": 0,
		"avoid_bonus": 0,
		"heal_fraction": 0.0,
		"move_costs": {"infantry": 1, "light_footed": 1, "armoured": 1, "mounted": 1, "flying": 1},
	},
	"forest":
	{
		"grid_char": "F",
		"display_name": "Forest",
		"tile_source_id": 1,
		"def_bonus": 1,
		"avoid_bonus": 15,
		"heal_fraction": 0.0,
		"move_costs": {"infantry": 2, "light_footed": 2, "armoured": 2, "mounted": 2, "flying": 1},
	},
	"mountain":
	{
		"grid_char": "M",
		"display_name": "Mountain",
		"tile_source_id": 2,
		"def_bonus": 2,
		"avoid_bonus": 20,
		"heal_fraction": 0.0,
		"move_costs": {"infantry": 3, "light_footed": 3, "armoured": 3, "mounted": 3, "flying": 1},
	},
	"fort":
	{
		"grid_char": "T",
		"display_name": "Fort",
		"tile_source_id": 3,
		"def_bonus": 2,
		"avoid_bonus": 30,
		# The one healing terrain today (GDD_02 fort/throne heal). Seeded from the
		# shared constant so terrain healing and the Renewal skill keep one source.
		"heal_fraction": GameConstants.PERCENT_HP_HEAL_FRACTION,
		"move_costs": {"infantry": 1, "light_footed": 1, "armoured": 1, "mounted": 1, "flying": 1},
	},
	"sea":
	{
		"grid_char": "S",
		"display_name": "Sea",
		"tile_source_id": 4,
		"def_bonus": 0,
		"avoid_bonus": 10,
		"heal_fraction": 0.0,
		"move_costs": {"infantry": 2, "light_footed": 2, "armoured": 2, "mounted": 2, "flying": 1},
	},
	"desert":
	{
		"grid_char": "D",
		"display_name": "Desert",
		"tile_source_id": 5,
		"def_bonus": 0,
		"avoid_bonus": 5,
		"heal_fraction": 0.0,
		# The GDD_02 desert rule, now data: mounts and armour bog down, the
		# light-footed slip through, infantry pays the base cost.
		"move_costs": {"infantry": 2, "light_footed": 1, "armoured": 3, "mounted": 3, "flying": 1},
	},
	"wall":
	{
		"grid_char": "W",
		"display_name": "Wall",
		"tile_source_id": 6,
		"def_bonus": 0,
		"avoid_bonus": 0,
		"heal_fraction": 0.0,
		"move_costs":
		{
			"infantry": IMPASSABLE_MOVE_COST,
			"light_footed": IMPASSABLE_MOVE_COST,
			"armoured": IMPASSABLE_MOVE_COST,
			"mounted": IMPASSABLE_MOVE_COST,
			"flying": IMPASSABLE_MOVE_COST,
		},
	},
}

var _entries: Dictionary = {}


func _init() -> void:
	for terrain_id in ENGINE_TERRAINS:
		_entries[terrain_id] = (ENGINE_TERRAINS[terrain_id] as Dictionary).duplicate(true)


# Named constructor for the readable "no pack is active" case. `_init` already seeds
# the engine set, so this exists to make the intent explicit at call sites.
static func engine_defaults() -> TerrainRegistry:
	return TerrainRegistry.new()


# The registry the selected content is actually playing with: the one the active
# pack committed, or the engine defaults when no pack is active. Resolved through
# the main loop rather than a `/root` node path so static and headless callers —
# `--script` tests load no autoloads — get the same answer as scene code.
#
# One seam, deliberately: every consumer that cannot be handed a registry at setup
# calls this, so "which terrain numbers are live" has a single answer.
static func active() -> TerrainRegistry:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var data_manager := (loop as SceneTree).root.get_node_or_null("DataManager")
		if data_manager != null and data_manager.has_method("terrain_registry"):
			var resolved: Variant = data_manager.call("terrain_registry")
			if resolved is TerrainRegistry:
				return resolved
	return engine_defaults()


func ids() -> Array[String]:
	var out: Array[String] = []
	for terrain_id in _entries:
		out.append(String(terrain_id))
	return out


func has_terrain(terrain_id: String) -> bool:
	return _entries.has(terrain_id)


func entry(terrain_id: String) -> Dictionary:
	return _entries.get(terrain_id, {})


# Grid char -> terrain id, or "" when the char is not registered. `GameMap` and
# `DataManager` both validate authored grids against this instead of keeping their
# own copies of the char set.
func id_for_grid_char(grid_char: String) -> String:
	for terrain_id in _entries:
		if String(_entries[terrain_id].get("grid_char", "")) == grid_char:
			return String(terrain_id)
	return ""


func grid_chars() -> Array[String]:
	var out: Array[String] = []
	for terrain_id in _entries:
		out.append(String(_entries[terrain_id].get("grid_char", "")))
	return out


func tile_source_id(terrain_id: String) -> int:
	# Unknown terrain paints as wall, preserving the previous `_CHAR_TO_SOURCE` default.
	var fallback: int = int(ENGINE_TERRAINS[OUT_OF_BOUNDS_TERRAIN]["tile_source_id"])
	return int(entry(terrain_id).get("tile_source_id", fallback))


# Cost for one movement type. An unregistered terrain costs 1 — the same permissive
# default `_DEFAULT_MOVE_COSTS.get(terrain, 1)` had, so a tile painted with terrain
# the registry does not know never silently becomes an invisible wall mid-battle.
func move_cost(terrain_id: String, movement_type: String) -> int:
	var costs: Variant = entry(terrain_id).get("move_costs", null)
	if not costs is Dictionary:
		return 1
	return int((costs as Dictionary).get(movement_type, 1))


# The whole cost column, for UI that shows every movement group at once.
func move_costs(terrain_id: String) -> Dictionary:
	var costs: Variant = entry(terrain_id).get("move_costs", null)
	if not costs is Dictionary:
		return {}
	return (costs as Dictionary).duplicate()


# The player-facing name for a terrain. `display_name` was authorable from the day
# the family shipped, but nothing read it — the HUD titled its panel with the raw id
# instead, so a pack retuning "forest" to "Deep Wood" still saw "Forest" in game.
# Falls back to the capitalised id so an entry that somehow lacks the field still
# renders the way it always did rather than blanking the panel ([TER-10]).
func display_name(terrain_id: String) -> String:
	var authored := String(entry(terrain_id).get("display_name", ""))
	return authored if authored != "" else terrain_id.capitalize()


func def_bonus(terrain_id: String) -> int:
	return int(entry(terrain_id).get("def_bonus", 0))


func avoid_bonus(terrain_id: String) -> int:
	return int(entry(terrain_id).get("avoid_bonus", 0))


# Fraction of max HP restored at the start of a phase, 0.0 for terrain that does not
# heal. `TurnManager` reads this instead of testing for the literal id "fort".
func heal_fraction(terrain_id: String) -> float:
	return float(entry(terrain_id).get("heal_fraction", 0.0))


# Impassable is DERIVED from the costs rather than stored as its own flag, so a
# terrain cannot declare itself passable while costing 999 (or the reverse).
func is_impassable(terrain_id: String) -> bool:
	var costs: Dictionary = move_costs(terrain_id)
	if costs.is_empty():
		return false
	for movement_type in costs:
		if int(costs[movement_type]) < IMPASSABLE_MOVE_COST:
			return false
	return true


func is_impassable_for(terrain_id: String, movement_type: String) -> bool:
	return move_cost(terrain_id, movement_type) >= IMPASSABLE_MOVE_COST


# Applies one validated pack `terrain` document over the engine definition, returning
# diagnostics rather than raising. A pack RETUNES a terrain the engine can paint; it
# does not introduce one, because `tile_source_id` indexes the engine's generated
# tileset and a pack may only carry indexed JSON plus approved Tier-1 media — it can
# never ship the `TileSet` a new terrain would need. Admitting an unpaintable terrain
# would paint it as wall with no diagnostic, so it is refused here with one.
func apply_document(document: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var terrain_id := String(document.get("id", ""))
	if not ENGINE_TERRAINS.has(terrain_id):
		errors.append(
			(
				(
					"TerrainRegistry: terrain '%s' is not one the engine can paint (%s); "
					+ "v1 packs retune existing terrain and cannot introduce new terrain"
				)
				% [terrain_id, ", ".join(PackedStringArray(ENGINE_TERRAINS.keys()))]
			)
		)
		return errors
	var target: Dictionary = _entries[terrain_id]
	for field in AUTHORABLE_FIELDS:
		if not document.has(field):
			continue
		if field == "move_costs":
			# Whole-column replacement is not required: an author may retune the
			# mounted cost of one terrain without restating the other four.
			var authored: Dictionary = document["move_costs"]
			var merged: Dictionary = (target["move_costs"] as Dictionary).duplicate()
			for movement_type in authored:
				merged[String(movement_type)] = int(authored[movement_type])
			target["move_costs"] = merged
		else:
			target[field] = document[field]
	return errors


# Whole-registry coherence, run once after every pack terrain document is applied.
# Grid chars must stay distinct or an authored map row becomes ambiguous, and the
# out-of-bounds terrain must survive because `GridManager` returns it for any tile
# outside the grid.
func collect_coherence_errors() -> Array[String]:
	var errors: Array[String] = []
	var seen_chars := {}
	for terrain_id in _entries:
		var grid_char := String(_entries[terrain_id].get("grid_char", ""))
		if seen_chars.has(grid_char):
			errors.append(
				(
					"TerrainRegistry: terrain '%s' and '%s' both use grid char '%s'"
					% [seen_chars[grid_char], terrain_id, grid_char]
				)
			)
		else:
			seen_chars[grid_char] = String(terrain_id)
	if not _entries.has(OUT_OF_BOUNDS_TERRAIN):
		errors.append(
			(
				"TerrainRegistry: the out-of-bounds terrain '%s' is not registered"
				% OUT_OF_BOUNDS_TERRAIN
			)
		)
	return errors
