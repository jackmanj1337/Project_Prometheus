extends SceneTree
# TerrainRegistry consolidated six engine tables (GridManager's three cost/bonus
# dicts, GameMap's char->source table, DataManager's char set, and TurnManager's
# literal "fort") into one authority. The first block below is therefore a
# REGRESSION PIN, not a restatement of the implementation: it asserts the exact
# numbers those tables carried before the move, so a consolidation that quietly
# retuned the game would fail here rather than in playtest.

const TerrainRegistryScript = preload("res://scripts/core/TerrainRegistry.gd")
const GameConstantsScript = preload("res://scripts/shared/GameConstants.gd")


func _init() -> void:
	print("=== Terrain Registry Test ===")
	var passed := 0
	var failed := 0
	var terrain: TerrainRegistry = TerrainRegistryScript.engine_defaults()

	# --- Move costs, exactly as _DEFAULT_MOVE_COSTS plus the two desert exceptions ---
	# Ground types paid the base cost everywhere except desert, where armoured and
	# mounted paid 3 and light_footed paid 1.
	var base_costs := {"plain": 1, "forest": 2, "mountain": 3, "fort": 1, "sea": 2, "desert": 2}
	var ground_ok := true
	for terrain_id: String in base_costs:
		if terrain.move_cost(terrain_id, "infantry") != int(base_costs[terrain_id]):
			ground_ok = false
		var expected_heavy: int = 3 if terrain_id == "desert" else int(base_costs[terrain_id])
		var expected_light: int = 1 if terrain_id == "desert" else int(base_costs[terrain_id])
		if (
			terrain.move_cost(terrain_id, "armoured") != expected_heavy
			or terrain.move_cost(terrain_id, "mounted") != expected_heavy
			or terrain.move_cost(terrain_id, "light_footed") != expected_light
		):
			ground_ok = false
	if ground_ok:
		print("OK  ground move costs match the pre-consolidation table (desert rule included)")
		passed += 1
	else:
		print("FAIL ground move costs changed during consolidation")
		failed += 1

	# Fliers ignored all ground penalties (flat 1), but walls blocked everyone
	# including them (V021-11). Both were code branches; both are now cells.
	var flying_ok := true
	for terrain_id: String in base_costs:
		if terrain.move_cost(terrain_id, "flying") != 1:
			flying_ok = false
	if (
		flying_ok
		and terrain.move_cost("wall", "flying") == TerrainRegistryScript.IMPASSABLE_MOVE_COST
		and terrain.move_cost("wall", "infantry") == TerrainRegistryScript.IMPASSABLE_MOVE_COST
	):
		print("OK  fliers cross ground terrain at 1 and walls still block them (V021-11)")
		passed += 1
	else:
		print("FAIL flying/wall costs changed during consolidation")
		failed += 1

	# --- Defender bonuses, exactly as TERRAIN_DEF_BONUS / TERRAIN_DODGE_BONUS ---
	var expected_def := {
		"plain": 0, "forest": 1, "mountain": 2, "fort": 2, "sea": 0, "desert": 0, "wall": 0
	}
	var expected_avoid := {
		"plain": 0, "forest": 15, "mountain": 20, "fort": 30, "sea": 10, "desert": 5, "wall": 0
	}
	var bonuses_ok := true
	for terrain_id: String in expected_def:
		if (
			terrain.def_bonus(terrain_id) != int(expected_def[terrain_id])
			or terrain.avoid_bonus(terrain_id) != int(expected_avoid[terrain_id])
		):
			bonuses_ok = false
	if bonuses_ok:
		print("OK  DEF/avoid bonuses match the pre-consolidation tables")
		passed += 1
	else:
		print("FAIL DEF/avoid bonuses changed during consolidation")
		failed += 1

	# --- Healing: fort was a literal `== "fort"` test in TurnManager ---
	if (
		is_equal_approx(terrain.heal_fraction("fort"), GameConstantsScript.PERCENT_HP_HEAL_FRACTION)
		and is_equal_approx(terrain.heal_fraction("plain"), 0.0)
		and is_equal_approx(terrain.heal_fraction("mountain"), 0.0)
	):
		print("OK  fort is the only healing terrain and heals the shared HP fraction")
		passed += 1
	else:
		print(
			(
				"FAIL healing terrain: fort=%f plain=%f"
				% [terrain.heal_fraction("fort"), terrain.heal_fraction("plain")]
			)
		)
		failed += 1

	# --- Grid chars: GameMap and DataManager each kept a copy of this set ---
	var expected_chars := {
		".": "plain",
		"F": "forest",
		"M": "mountain",
		"T": "fort",
		"S": "sea",
		"D": "desert",
		"W": "wall",
	}
	var chars_ok := true
	for grid_char: String in expected_chars:
		if terrain.id_for_grid_char(grid_char) != String(expected_chars[grid_char]):
			chars_ok = false
	# An unregistered char resolves to "" so callers can refuse it with a diagnostic
	# instead of painting it as wall by default.
	if chars_ok and terrain.id_for_grid_char("X").is_empty():
		print("OK  grid chars resolve to terrain ids and an unknown char resolves to nothing")
		passed += 1
	else:
		print("FAIL grid char vocabulary changed during consolidation")
		failed += 1

	# Tile source ids must keep matching generate_tilesets.gd's ordering, or every
	# painted map would silently shift terrain.
	if (
		terrain.tile_source_id("plain") == 0
		and terrain.tile_source_id("forest") == 1
		and terrain.tile_source_id("mountain") == 2
		and terrain.tile_source_id("fort") == 3
		and terrain.tile_source_id("sea") == 4
		and terrain.tile_source_id("desert") == 5
		and terrain.tile_source_id("wall") == 6
	):
		print("OK  tile source ids still match the generated tileset ordering")
		passed += 1
	else:
		print("FAIL tile source ids no longer match generate_tilesets.gd")
		failed += 1

	# --- Impassability is derived from the costs, not stored as its own flag ---
	if (
		terrain.is_impassable("wall")
		and not terrain.is_impassable("mountain")
		and terrain.is_impassable_for("wall", "flying")
		and not terrain.is_impassable_for("mountain", "infantry")
	):
		print("OK  impassability derives from the cost column")
		passed += 1
	else:
		print("FAIL impassability derivation")
		failed += 1

	# An unknown terrain costs 1 rather than becoming an invisible wall mid-battle,
	# preserving `_DEFAULT_MOVE_COSTS.get(terrain, 1)`.
	if terrain.move_cost("swamp", "infantry") == 1 and not terrain.is_impassable("swamp"):
		print("OK  unregistered terrain stays passable at cost 1")
		passed += 1
	else:
		print("FAIL unregistered terrain default")
		failed += 1

	# --- Pack retunes ---------------------------------------------------------
	# A partial cost map retunes only the movement types it names; the rest of the
	# column survives, so an author need not restate five numbers to change one.
	var retuned: TerrainRegistry = TerrainRegistryScript.engine_defaults()
	var apply_errors := retuned.apply_document(
		{
			"id": "forest",
			"display_name": "Deep Wood",
			"avoid_bonus": 25,
			"move_costs": {"mounted": 4}
		}
	)
	if (
		apply_errors.is_empty()
		and retuned.avoid_bonus("forest") == 25
		and retuned.move_cost("forest", "mounted") == 4
		and retuned.move_cost("forest", "infantry") == 2
		and String(retuned.entry("forest").get("display_name", "")) == "Deep Wood"
		# The engine defaults must not be mutated by a pack's retune.
		and terrain.avoid_bonus("forest") == 15
	):
		print("OK  a terrain document retunes named fields and leaves the engine set intact")
		passed += 1
	else:
		print("FAIL terrain retune: errors=%s" % [apply_errors])
		failed += 1

	# A pack cannot introduce terrain: the tile comes from the engine's generated
	# tileset, which a pack may never ship.
	var invented := TerrainRegistryScript.engine_defaults()
	var invented_errors := invented.apply_document({"id": "swamp", "grid_char": "P"})
	if invented_errors.size() == 1 and not invented.has_terrain("swamp"):
		print("OK  a terrain the engine cannot paint is refused with a diagnostic")
		passed += 1
	else:
		print("FAIL invented terrain: %s" % [invented_errors])
		failed += 1

	# Two terrains claiming one char makes an authored map row ambiguous. Each
	# document is individually valid, so only a whole-registry pass can catch it.
	var collided := TerrainRegistryScript.engine_defaults()
	collided.apply_document({"id": "sea", "grid_char": "F"})
	if (
		collided.apply_document({"id": "sea", "grid_char": "F"}).is_empty()
		and collided.collect_coherence_errors().size() == 1
	):
		print("OK  duplicate grid chars fail the whole-registry coherence pass")
		passed += 1
	else:
		print("FAIL grid char collision: %s" % [collided.collect_coherence_errors()])
		failed += 1

	# Every movement type the engine resolves must have a cost on every terrain, or
	# a unit type would silently fall back to the permissive default of 1.
	var coverage_ok := true
	for terrain_id: String in terrain.ids():
		var costs: Dictionary = terrain.move_costs(terrain_id)
		for movement_type in GameConstantsScript.VALID_MOVEMENT_TYPES:
			if not costs.has(movement_type):
				coverage_ok = false
	if coverage_ok:
		print("OK  every terrain prices every VALID_MOVEMENT_TYPES entry")
		passed += 1
	else:
		print("FAIL terrain cost columns do not cover every movement type")
		failed += 1

	# [TER-10]. display_name was authorable from the day the family shipped and no
	# accessor existed, so the HUD titled its panel with the raw id and a pack's
	# retune never reached the player. Pin both halves: the authored name wins, and
	# an entry without one still renders the capitalised id the HUD used to show.
	# The fallback is exercised through an UNREGISTERED id rather than by erasing the
	# field, because that is the case the HUD actually hits (an unpainted tile) and it
	# does not depend on `entry()` handing back a live reference.
	var named: TerrainRegistry = TerrainRegistryScript.engine_defaults()
	var name_errors := named.apply_document({"id": "forest", "display_name": "Deep Wood"})
	if (
		name_errors.is_empty()
		and named.display_name("forest") == "Deep Wood"
		and terrain.display_name("forest") == "Forest"
		and terrain.display_name("not_a_terrain") == "Not A Terrain"
	):
		print("OK  display_name returns the authored name and falls back to the id")
		passed += 1
	else:
		print(
			(
				"FAIL display_name: retuned=%s engine=%s fallback=%s"
				% [
					named.display_name("forest"),
					terrain.display_name("forest"),
					terrain.display_name("not_a_terrain")
				]
			)
		)
		failed += 1

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)
