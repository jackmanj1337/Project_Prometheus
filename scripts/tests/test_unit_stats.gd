extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_unit_stats.gd
# Verifies Unit.gd combat stat formulas against GDD_02 math.

const GameConstants = preload("res://scripts/shared/GameConstants.gd")

func _init() -> void:
	print("=== Unit Combat Stats Test ===")

	# ── Load resources ──
	var soldier_data: UnitData = load("res://data/roster/default/unit_01_soldier.tres").duplicate(true)
	var iron_lance: WeaponData = load("res://data/weapons/iron_lance.tres")
	soldier_data.inventory = [InventoryEntry.make_weapon("iron_lance", 45)]
	soldier_data.proficiencies = {"lance": {"rank": "D", "wexp": 0}}

	var fixed_data := UnitData.new()
	fixed_data.level = 1
	fixed_data.hp = 20; fixed_data.max_hp = 20
	fixed_data.strength = 5; fixed_data.magic = 0; fixed_data.defense = 0
	fixed_data.resistance = 0; fixed_data.skill = 0; fixed_data.speed = 0; fixed_data.luck = 0

	var dur_data := UnitData.new()
	dur_data.inventory = [InventoryEntry.make_weapon("iron_lance", 1)]
	dur_data.proficiencies = {"lance": {"rank": "D", "wexp": 0}}

	# ── Instantiate from Unit.tscn so @onready vars are populated via _ready().
	# Set data before add_child so _ready fires with it already assigned.
	var unit_scene: PackedScene = preload("res://scenes/units/Unit.tscn")

	var unit: Unit = unit_scene.instantiate()
	unit.data = soldier_data
	root.add_child(unit)

	var fixed_unit: Unit = unit_scene.instantiate()
	fixed_unit.data = fixed_data
	root.add_child(fixed_unit)

	var rand_unit: Unit = unit_scene.instantiate()
	rand_unit.data = fixed_data.duplicate(true)
	rand_unit.data.growth_accumulators = {}
	rand_unit.data.strength = 0
	root.add_child(rand_unit)

	var dur_unit: Unit = unit_scene.instantiate()
	dur_unit.data = dur_data
	root.add_child(dur_unit)

	await process_frame  # _ready fires for all five units

	var passed := 0
	var failed := 0

	# --- C3: unit tint reads FactionData.color when authored ---
	var md_c3 := MapData.new()
	var fd_green := FactionData.new()
	fd_green.id = "green"
	fd_green.color = Color(0.12, 0.88, 0.31, 1.0)
	md_c3.factions = [fd_green] as Array[FactionData]
	unit.team = "green"
	unit.apply_faction_visual(md_c3)
	if unit.get_node("Sprite2D").modulate == fd_green.color:
		print("OK  C3: Unit tint uses authored FactionData.color")
		passed += 1
	else:
		print("FAIL C3 unit tint: got %s want %s" % [
			str(unit.get_node("Sprite2D").modulate), str(fd_green.color)
		]); failed += 1
	# Restore default team for the remaining baseline checks.
	unit.team = "blue"
	unit.apply_faction_visual(null)

	# Soldier base: STR 7, SKL 6, SPD 6, LUK 6, DEF 6, MAG 0
	# Iron Lance:  Mt 7, Hit 80, Crit 0, Wt 8
	# Battle Speed = SPD - max(0, Wt - STR) = 6 - max(0, 8-7) = 6 - 1 = 5
	# Accuracy     = SKL*2 + LUK + weapon.Hit = 12 + 6 + 80 = 98
	# Dodge        = battle_speed*2 + LUK = 10 + 6 = 16
	# Crit         = floor(SKL/2) + weapon.Crit = 3 + 0 = 3
	# Crit Avoid   = LUK = 6

	var checks := [
		["battle_speed", unit.battle_speed(iron_lance), 5],
		["accuracy",     unit.accuracy(iron_lance),     98],
		["dodge",        unit.dodge(iron_lance),         16],
		["crit_rate",    unit.crit_rate(iron_lance),     3],
		["crit_avoid",   unit.crit_avoid(),              6],
	]
	for c in checks:
		var label: String = c[0]
		var got: int = c[1]
		var want: int = c[2]
		if got == want:
			print("OK  %s = %d" % [label, got])
			passed += 1
		else:
			print("FAIL %s: got %d, want %d" % [label, got, want])
			failed += 1

	# --- S-rank: stat methods return BASE values; bonus applied via s_rank_mastery skill at combat time ---
	# accuracy/crit_rate no longer include S-rank; the skill fires on_combat_start and
	# injects into atk_mod, which CombatResolver picks up. Test that base values are unchanged.
	soldier_data.proficiencies = {"lance": {"rank": "S", "wexp": 0}}
	var srank_checks := [
		["S-rank accuracy base (no bonus in stat method)",  unit.accuracy(iron_lance),  98],
		["S-rank crit_rate base (no bonus in stat method)", unit.crit_rate(iron_lance), 3],
	]
	for c in srank_checks:
		var label: String = c[0]
		var got: int = c[1]
		var want: int = c[2]
		if got == want:
			print("OK  %s = %d" % [label, got])
			passed += 1
		else:
			print("FAIL %s: got %d, want %d" % [label, got, want])
			failed += 1

	# --- HP changes ---
	# Restore soldier's setup and run HP tests on it
	soldier_data.hp = soldier_data.max_hp  # full HP
	unit.take_damage(5)
	if soldier_data.hp == soldier_data.max_hp - 5:
		print("OK  take_damage(5) reduces HP correctly")
		passed += 1
	else:
		print("FAIL take_damage: hp=%d" % soldier_data.hp)
		failed += 1

	unit.take_damage(9999)
	if soldier_data.hp == 0:
		print("OK  take_damage clamps to 0")
		passed += 1
	else:
		print("FAIL clamp: hp=%d" % soldier_data.hp)
		failed += 1

	unit.heal(10)
	if soldier_data.hp == 10:
		print("OK  heal(10) increases HP")
		passed += 1
	else:
		print("FAIL heal: hp=%d" % soldier_data.hp)
		failed += 1

	unit.heal(9999)
	if soldier_data.hp == soldier_data.max_hp:
		print("OK  heal clamps to max_hp")
		passed += 1
	else:
		print("FAIL heal clamp: hp=%d (max=%d)" % [soldier_data.hp, soldier_data.max_hp])
		failed += 1

	# --- Weapon durability ---
	soldier_data.inventory = [InventoryEntry.make_weapon("iron_lance", 2)]
	unit.use_weapon_durability()
	if soldier_data.inventory[0].uses_remaining == 1:
		print("OK  use_weapon_durability decrements")
		passed += 1
	else:
		print("FAIL durability: %s" % soldier_data.inventory)
		failed += 1

	unit.use_weapon_durability()
	if soldier_data.inventory.size() == 0:
		print("OK  weapon removed at 0 uses")
		passed += 1
	else:
		print("FAIL weapon not removed: %s" % soldier_data.inventory)
		failed += 1

	# --- use_weapon_durability(weapon_id): return value and targeted decrement ---
	# Returns false when weapon decremented but not broken.
	soldier_data.inventory = [InventoryEntry.make_weapon("iron_lance", 2)]
	var did_break_no: bool = unit.use_weapon_durability("iron_lance")
	if not did_break_no and soldier_data.inventory[0].uses_remaining == 1:
		print("OK  use_weapon_durability returns false when not broken")
		passed += 1
	else:
		print("FAIL durability return false: broke=%s inv=%s" % [did_break_no, soldier_data.inventory])
		failed += 1

	# Returns true when weapon breaks.
	var did_break_yes: bool = unit.use_weapon_durability("iron_lance")
	if did_break_yes and soldier_data.inventory.is_empty():
		print("OK  use_weapon_durability returns true when broken")
		passed += 1
	else:
		print("FAIL durability return true: broke=%s inv=%s" % [did_break_yes, soldier_data.inventory])
		failed += 1

	# With two weapons, targeting a specific weapon_id never bleeds into the next one.
	soldier_data.inventory = [
		InventoryEntry.make_weapon("javelin", 1),
		InventoryEntry.make_weapon("iron_lance", 40),
	]
	unit.use_weapon_durability("javelin")  # breaks javelin
	var lance_intact: bool = soldier_data.inventory.size() == 1 \
		and soldier_data.inventory[0].weapon_id == "iron_lance" \
		and soldier_data.inventory[0].uses_remaining == 40
	if lance_intact:
		print("OK  use_weapon_durability(weapon_id) targets correct entry; iron_lance untouched")
		passed += 1
	else:
		print("FAIL weapon_id targeting: inv=%s" % soldier_data.inventory)
		failed += 1

	# Calling again with the now-removed weapon_id is a no-op — doesn't touch iron_lance.
	unit.use_weapon_durability("javelin")
	var still_intact: bool = soldier_data.inventory.size() == 1 \
		and soldier_data.inventory[0].uses_remaining == 40
	if still_intact:
		print("OK  use_weapon_durability on already-broken weapon_id is a no-op")
		passed += 1
	else:
		print("FAIL no-op check: inv=%s" % soldier_data.inventory)
		failed += 1

	# --- B1: -1 = infinite-use sentinel — weapon never decrements, never breaks ---
	soldier_data.inventory = [InventoryEntry.make_weapon("iron_lance", -1)]
	var inf_broke: bool = unit.use_weapon_durability()
	if not inf_broke and soldier_data.inventory.size() == 1 \
			and soldier_data.inventory[0].uses_remaining == -1:
		print("OK  B1: -1 weapon does not decrement or break")
		passed += 1
	else:
		print("FAIL B1 weapon: broke=%s inv=%s" % [inf_broke, soldier_data.inventory])
		failed += 1

	# --- snap_to_tile ---
	unit.snap_to_tile(Vector2i(5, 7))
	if unit.tile_position == Vector2i(5, 7) and unit.position == Vector2(5 * GameConstants.TILE_SIZE, 7 * GameConstants.TILE_SIZE):
		print("OK  snap_to_tile sets tile and world position")
		passed += 1
	else:
		print("FAIL snap_to_tile: tile=%s pos=%s" % [unit.tile_position, unit.position])
		failed += 1

	# --- EXP and leveling ---
	soldier_data.level = 1
	soldier_data.exp = 0
	unit.add_exp(30)
	if soldier_data.exp == 30 and soldier_data.level == 1:
		print("OK  add_exp(30) without level up")
		passed += 1
	else:
		print("FAIL exp: lvl=%d exp=%d" % [soldier_data.level, soldier_data.exp])
		failed += 1

	unit.add_exp(75)  # 30+75 = 105 → level up, 5 overflow
	if soldier_data.level == 2 and soldier_data.exp == 5:
		print("OK  add_exp carries overflow correctly")
		passed += 1
	else:
		print("FAIL overflow: lvl=%d exp=%d" % [soldier_data.level, soldier_data.exp])
		failed += 1

	# Multiple level-ups in one call (250 EXP → 2 level-ups)
	soldier_data.level = 1
	soldier_data.exp = 0
	unit.add_exp(250)
	if soldier_data.level == 3 and soldier_data.exp == 50:
		print("OK  add_exp(250) triggers 2 level-ups")
		passed += 1
	else:
		print("FAIL multi level-up: lvl=%d exp=%d" % [soldier_data.level, soldier_data.exp])
		failed += 1

	# --- Weapon EXP and rank-up ---
	soldier_data.proficiencies = {"lance": {"rank": "D", "wexp": 50}}
	unit.add_wexp("lance", 30)
	if soldier_data.proficiencies["lance"]["wexp"] == 80 and soldier_data.proficiencies["lance"]["rank"] == "D":
		print("OK  add_wexp accumulates without rank-up")
		passed += 1
	else:
		print("FAIL wexp accumulate: %s" % soldier_data.proficiencies)
		failed += 1

	var ranked := unit.add_wexp("lance", 30)  # 80+30 = 110 → rank up to C, 10 carry
	if ranked and soldier_data.proficiencies["lance"]["rank"] == "C" and soldier_data.proficiencies["lance"]["wexp"] == 10:
		print("OK  add_wexp triggers rank-up D→C")
		passed += 1
	else:
		print("FAIL rank up: %s ranked=%s" % [soldier_data.proficiencies, ranked])
		failed += 1

	# S rank cap
	soldier_data.proficiencies = {"lance": {"rank": "S", "wexp": 95}}
	unit.add_wexp("lance", 100)
	if soldier_data.proficiencies["lance"]["rank"] == "S" and soldier_data.proficiencies["lance"]["wexp"] == 100:
		print("OK  wexp caps at 100 when already S-rank")
		passed += 1
	else:
		print("FAIL S-cap: %s" % soldier_data.proficiencies)
		failed += 1

	# --- growth_fixed: carry persists across calls ---
	# Rate 50: should gain +1 on even levels only.
	var rates50 := {"hp": 0, "strength": 50, "magic": 0, "defense": 0, "resistance": 0,
		"skill": 0, "speed": 0, "luck": 0}
	var ch1 := fixed_unit._level_up_fixed(rates50, {})  # acc=50 → 0 gain, carry=50
	var ch2 := fixed_unit._level_up_fixed(rates50, {})  # acc=100 → +1, carry=0
	var ch3 := fixed_unit._level_up_fixed(rates50, {})  # acc=50 → 0 gain, carry=50
	if not ch1.has("strength") and ch2.get("strength", 0) == 1 and not ch3.has("strength"):
		print("OK  growth_fixed rate-50: gain only on every 2nd level")
		passed += 1
	else:
		print("FAIL growth_fixed rate-50: ch1=%s ch2=%s ch3=%s" % [ch1, ch2, ch3])
		failed += 1

	# Rate 150: +1 guaranteed each level, +1 extra every other level.
	var rates150 := {"hp": 0, "strength": 150, "magic": 0, "defense": 0, "resistance": 0,
		"skill": 0, "speed": 0, "luck": 0}
	fixed_data.growth_accumulators = {}
	fixed_data.strength = 0
	var r1 := fixed_unit._level_up_fixed(rates150, {})  # acc=150 → +1, carry=50
	var r2 := fixed_unit._level_up_fixed(rates150, {})  # acc=200 → +2, carry=0
	if r1.get("strength", 0) == 1 and r2.get("strength", 0) == 2:
		print("OK  growth_fixed rate-150: +1 then +2 pattern")
		passed += 1
	else:
		print("FAIL growth_fixed rate-150: r1=%s r2=%s" % [r1, r2])
		failed += 1

	# --- growth_random: rate > 100 gives guaranteed gains ---
	# Rate 250 → guaranteed +2, 50% chance of +3. Test the guaranteed part by
	# running 100 trials and checking the minimum gain is always ≥ 2.
	var rates250 := {"hp": 0, "strength": 250, "magic": 0, "defense": 0, "resistance": 0,
		"skill": 0, "speed": 0, "luck": 0}
	var min_gain := 9999
	for _i in 100:
		rand_unit.data.strength = 0
		var res := rand_unit._level_up_random(rates250, {})
		var gain: int = res.get("strength", 0)
		if gain < min_gain:
			min_gain = gain
	if min_gain >= 2:
		print("OK  growth_random rate-250: minimum gain ≥ 2 over 100 trials")
		passed += 1
	else:
		print("FAIL growth_random rate-250: got min_gain=%d (expected ≥ 2)" % min_gain)
		failed += 1

	# --- DEBUG AID #11: debug_growth_boost inflates growth rates by +50 ---
	# Effective only in debug builds (the headless test binary is one). A rate-0
	# stat becomes 50 → _debug_boosted_rate returns 50; restored to false after.
	var gs_dbg := rand_unit.get_node_or_null("/root/GameState")
	if gs_dbg != null:
		gs_dbg.debug_growth_boost = true
		var boosted: bool = rand_unit._debug_boosted_rate(0) == 50
		gs_dbg.debug_growth_boost = false
		var unboosted: bool = rand_unit._debug_boosted_rate(0) == 0
		if boosted and unboosted:
			print("OK  debug_growth_boost adds +50 to growth rates, off restores (#11)")
			passed += 1
		else:
			print("FAIL debug_growth_boost: boosted=%s unboosted=%s" % [boosted, unboosted])
			failed += 1
	else:
		print("SKIP debug_growth_boost (GameState autoload absent)")

	# --- M2: stat gains clamp to the class stat cap ---
	# A stat already at cap gains nothing; a stat one below cap gains only 1 of 2.
	var cap_unit: Unit = unit_scene.instantiate()
	var cap_data := UnitData.new()
	cap_unit.data = cap_data
	root.add_child(cap_unit)
	await process_frame
	cap_data.strength = 30
	var at_cap: int = cap_unit._apply_stat_gain("strength", 2, {"strength": 30})
	cap_data.strength = 29
	var partial: int = cap_unit._apply_stat_gain("strength", 2, {"strength": 30})
	if at_cap == 0 and partial == 1 and cap_data.strength == 30:
		print("OK  M2: stat gain clamps to class cap")
		passed += 1
	else:
		print("FAIL M2 cap clamp: at_cap=%d partial=%d str=%d" % [at_cap, partial, cap_data.strength])
		failed += 1

	# --- M2: growth-table resolution (player vs enemy) ---
	# Blue units add personal growth_rates to the class player table; other teams
	# use the class enemy table alone.
	var gc := ClassData.new()
	gc.player_growth_rates = {"hp": 40, "strength": 20, "magic": 0, "defense": 10,
		"resistance": 5, "skill": 30, "speed": 15, "luck": 0}
	gc.enemy_growth_rates = {"hp": 80, "strength": 40, "magic": 0, "defense": 20,
		"resistance": 10, "skill": 60, "speed": 30, "luck": 0}
	fixed_unit.data.growth_rates = {"strength": 10}
	fixed_unit.team = "blue"
	var blue_rates: Dictionary = fixed_unit._resolve_growth_rates(gc)
	fixed_unit.team = "red"
	var red_rates: Dictionary = fixed_unit._resolve_growth_rates(gc)
	fixed_unit.team = "blue"
	if blue_rates.get("strength", 0) == 30 and red_rates.get("strength", 0) == 40:
		print("OK  M2: player growths add personal rates; enemy uses enemy table")
		passed += 1
	else:
		print("FAIL M2 growth resolution: blue=%s red=%s" % [blue_rates, red_rates])
		failed += 1

	# --- M2: class skills auto-granted at their unlock level ---
	var skill_unit: Unit = unit_scene.instantiate()
	var skill_data := UnitData.new()
	skill_unit.data = skill_data
	root.add_child(skill_unit)
	await process_frame
	var sc := ClassData.new()
	sc.skill_unlocks = {1: "vantage", 10: "wrath"}
	skill_data.level = 10
	var learned1: Array = skill_unit._grant_level_skills(sc)  # → wrath
	skill_data.level = 1
	var learned2: Array = skill_unit._grant_level_skills(sc)  # → vantage
	var learned3: Array = skill_unit._grant_level_skills(sc)  # vantage already known → none
	if learned1.size() == 1 and learned1[0] == "wrath" \
			and learned2.size() == 1 and learned2[0] == "vantage" \
			and learned3.is_empty():
		print("OK  M2: class skills auto-granted at unlock level, no duplicates")
		passed += 1
	else:
		print("FAIL M2 skill grant: l1=%s l2=%s l3=%s" % [learned1, learned2, learned3])
		failed += 1

	# --- use_weapon_durability: last-use removal doesn't lose wexp if weapon captured first ---
	# Regression for MapCursorTargeting._apply_staff_heal ordering bug: fetching get_equipped_weapon()
	# after use_weapon_durability() on a 1-use weapon returns null/wrong weapon.
	var pre_weapon: WeaponData = iron_lance  # captured BEFORE use (the correct ordering)
	dur_unit.use_weapon_durability()
	var entry_removed: bool = dur_data.inventory.is_empty()
	dur_unit.add_wexp(pre_weapon.weapon_type, pre_weapon.wexp)
	var wexp_ok: bool = dur_data.proficiencies["lance"]["wexp"] == pre_weapon.wexp
	if entry_removed and wexp_ok:
		print("OK  last-use weapon removed; pre-captured wexp reference awards correctly")
		passed += 1
	else:
		print("FAIL last-use wexp: entry_removed=%s wexp_ok=%s" % [entry_removed, wexp_ok])
		failed += 1

	# --- Fort healing rounds down (GDD_02:76) ---
	# A unit on a fort heals floor(max_hp * 10%). For a 25-HP unit that is 2, not 3 —
	# the old ceili() gave 3. Regression for code review 2026-05-16d.
	var fort_unit: Unit = unit_scene.instantiate()
	var fort_data := UnitData.new()
	fort_data.hp = 12
	fort_data.max_hp = 25
	fort_unit.data = fort_data
	root.add_child(fort_unit)
	await process_frame
	fort_unit.tile_position = Vector2i(0, 0)
	var fort_grid := GridManager.new()
	fort_grid.set_terrain_fallback(Vector2i(0, 0), "fort")
	var fort_tm := TurnManager.new()
	fort_tm._grid = fort_grid
	var fort_units: Array[Node] = [fort_unit]
	fort_tm._apply_fort_healing(fort_units)
	# floor(25 * 0.10) = 2 → 12 + 2 = 14 (the old ceili would have given 15)
	if fort_unit.data.hp == 14:
		print("OK  fort healing rounds down: 25-HP unit heals 2 (hp 12→14)")
		passed += 1
	else:
		print("FAIL fort healing: hp = %d, want 14 (floor heal of 2)" % fort_unit.data.hp)
		failed += 1
	fort_grid.free()
	fort_tm.free()

	# Cleanup
	unit.queue_free()
	fixed_unit.queue_free()
	rand_unit.queue_free()
	dur_unit.queue_free()
	fort_unit.queue_free()

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
