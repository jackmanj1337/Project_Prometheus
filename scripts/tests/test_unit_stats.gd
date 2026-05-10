extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_unit_stats.gd
# Verifies Unit.gd combat stat formulas against GDD_02 math.

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
		["dodge",        unit.dodge(),                   16],
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

	# --- snap_to_tile ---
	unit.snap_to_tile(Vector2i(5, 7))
	if unit.tile_position == Vector2i(5, 7) and unit.position == Vector2(5*64, 7*64):
		print("OK  snap_to_tile sets tile and world position")
		passed += 1
	else:
		print("FAIL snap_to_tile: tile=%s pos=%s" % [unit.tile_position, unit.position])
		failed += 1

	# Cleanup
	unit.queue_free()
	mage.queue_free()

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
