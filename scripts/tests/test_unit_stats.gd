extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_unit_stats.gd
# Verifies Unit.gd combat stat formulas against GDD_02 math.

const GameConstants = preload("res://scripts/shared/GameConstants.gd")

func _init() -> void:
	print("=== Unit Combat Stats Test ===")
	var passed := 0
	var failed := 0

	# Build a Soldier with an Iron Lance
	var soldier_data: UnitData = load("res://data/roster/default/unit_01_soldier.tres").duplicate(true)
	var iron_lance: WeaponData = load("res://data/weapons/iron_lance.tres")

	# Soldier base: STR 7, SKL 6, SPD 6, LUK 6, DEF 6, MAG 0
	# Iron Lance:  Mt 7, Hit 80, Crit 0, Wt 8
	# Battle Speed = SPD - max(0, Wt - STR) = 6 - max(0, 8-7) = 6 - 1 = 5
	# Accuracy     = SKL*2 + LUK + weapon.Hit = 12 + 6 + 80 = 98
	# Dodge        = battle_speed*2 + LUK = 10 + 6 = 16
	# Damage       = STR + Mt = 7 + 7 = 14
	# Crit         = floor(SKL/2) + weapon.Crit = 3 + 0 = 3
	# Crit Avoid   = LUK = 6

	# Construct a Unit node without going through scene instantiation
	var unit := Unit.new()
	unit.data = soldier_data
	# Manually populate equipped weapon by injecting into inventory
	soldier_data.inventory = [
		{"type": "weapon", "weapon_id": "iron_lance", "uses_remaining": 45, "forged_mods": {}}
	]
	soldier_data.proficiencies = {"lance": {"rank": "D", "wexp": 0}}

	var checks := [
		["battle_speed", unit.battle_speed(iron_lance), 5],
		["accuracy",     unit.accuracy(iron_lance),     98],
		["dodge",        unit.dodge(iron_lance),          16],
		["damage",       unit.damage(iron_lance),        14],
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

	# --- S-rank bonus ---
	# At S-rank: +10 Hit, +5 Crit, +1 Damage
	soldier_data.proficiencies = {"lance": {"rank": "S", "wexp": 0}}
	var srank_checks := [
		["S-rank accuracy",  unit.accuracy(iron_lance),  108],  # 98 + 10
		["S-rank damage",    unit.damage(iron_lance),    15],   # 14 + 1
		["S-rank crit_rate", unit.crit_rate(iron_lance), 8],    # 3 + 5
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

	# --- Magic weapon uses MAG, not STR ---
	# Build a Mage with Fire tome: STR 1, MAG 7; Fire: Mt 4 (uses_mag=true)
	# Damage = MAG + Mt = 7 + 4 = 11
	var mage_data: UnitData = load("res://data/roster/default/unit_04_mage.tres").duplicate(true)
	var fire: WeaponData = load("res://data/weapons/fire.tres")
	var mage := Unit.new()
	mage.data = mage_data
	mage_data.proficiencies = {"fire": {"rank": "D", "wexp": 0}}
	if mage.damage(fire) == 11:
		print("OK  mage damage with Fire = 11 (uses MAG, not STR)")
		passed += 1
	else:
		print("FAIL mage damage: got %d, want 11" % mage.damage(fire))
		failed += 1

	# --- No weapon = 0 damage ---
	mage_data.inventory = []
	if mage.damage() == 0:
		print("OK  no weapon = 0 damage")
		passed += 1
	else:
		print("FAIL unarmed damage")
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
	soldier_data.inventory = [
		{"type": "weapon", "weapon_id": "iron_lance", "uses_remaining": 2, "forged_mods": {}}
	]
	unit.use_weapon_durability()
	if soldier_data.inventory[0]["uses_remaining"] == 1:
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
	soldier_data.inventory = [
		{"type": "weapon", "weapon_id": "iron_lance", "uses_remaining": 2, "forged_mods": {}}
	]
	var did_break_no: bool = unit.use_weapon_durability("iron_lance")
	if not did_break_no and soldier_data.inventory[0]["uses_remaining"] == 1:
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
		{"type": "weapon", "weapon_id": "javelin",    "uses_remaining": 1,  "forged_mods": {}},
		{"type": "weapon", "weapon_id": "iron_lance", "uses_remaining": 40, "forged_mods": {}},
	]
	unit.use_weapon_durability("javelin")  # breaks javelin
	var lance_intact: bool = soldier_data.inventory.size() == 1 \
		and soldier_data.inventory[0].get("weapon_id") == "iron_lance" \
		and soldier_data.inventory[0].get("uses_remaining") == 40
	if lance_intact:
		print("OK  use_weapon_durability(weapon_id) targets correct entry; iron_lance untouched")
		passed += 1
	else:
		print("FAIL weapon_id targeting: inv=%s" % soldier_data.inventory)
		failed += 1

	# Calling again with the now-removed weapon_id is a no-op — doesn't touch iron_lance.
	unit.use_weapon_durability("javelin")
	var still_intact: bool = soldier_data.inventory.size() == 1 \
		and soldier_data.inventory[0].get("uses_remaining") == 40
	if still_intact:
		print("OK  use_weapon_durability on already-broken weapon_id is a no-op")
		passed += 1
	else:
		print("FAIL no-op check: inv=%s" % soldier_data.inventory)
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
	# Call _level_up_fixed directly via a fresh unit with controlled rates.
	var fixed_unit := Unit.new()
	var fixed_data := UnitData.new()
	fixed_data.level = 1
	fixed_data.hp = 20; fixed_data.max_hp = 20
	fixed_data.strength = 5; fixed_data.magic = 0; fixed_data.defense = 0
	fixed_data.resistance = 0; fixed_data.skill = 0; fixed_data.speed = 0; fixed_data.luck = 0
	fixed_unit.data = fixed_data
	var rates50 := {"hp": 0, "strength": 50, "magic": 0, "defense": 0, "resistance": 0,
		"skill": 0, "speed": 0, "luck": 0}
	var ch1 := fixed_unit._level_up_fixed(rates50)  # acc=50 → 0 gain, carry=50
	var ch2 := fixed_unit._level_up_fixed(rates50)  # acc=100 → +1, carry=0
	var ch3 := fixed_unit._level_up_fixed(rates50)  # acc=50 → 0 gain, carry=50
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
	var r1 := fixed_unit._level_up_fixed(rates150)  # acc=150 → +1, carry=50
	var r2 := fixed_unit._level_up_fixed(rates150)  # acc=200 → +2, carry=0
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
	var rand_unit := Unit.new()
	rand_unit.data = fixed_data.duplicate(true)
	rand_unit.data.growth_accumulators = {}
	rand_unit.data.strength = 0
	var min_gain := 9999
	for _i in 100:
		rand_unit.data.strength = 0
		var res := rand_unit._level_up_random(rates250)
		var gain: int = res.get("strength", 0)
		if gain < min_gain:
			min_gain = gain
	if min_gain >= 2:
		print("OK  growth_random rate-250: minimum gain ≥ 2 over 100 trials")
		passed += 1
	else:
		print("FAIL growth_random rate-250: got min_gain=%d (expected ≥ 2)" % min_gain)
		failed += 1

	# --- use_weapon_durability: last-use removal doesn't lose wexp if weapon captured first ---
	# Regression for MapCursor._execute_staff_heal ordering bug: fetching get_equipped_weapon()
	# after use_weapon_durability() on a 1-use weapon returns null/wrong weapon.
	var dur_unit := Unit.new()
	var dur_data := UnitData.new()
	dur_data.inventory = [
		{"type": "weapon", "weapon_id": "iron_lance", "uses_remaining": 1, "forged_mods": {}}
	]
	dur_data.proficiencies = {"lance": {"rank": "D", "wexp": 0}}
	dur_unit.data = dur_data
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
	dur_unit.queue_free()

	# Cleanup
	unit.queue_free()
	mage.queue_free()
	fixed_unit.queue_free()
	rand_unit.queue_free()

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
