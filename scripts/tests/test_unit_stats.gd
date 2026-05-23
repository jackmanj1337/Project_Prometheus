extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_unit_stats.gd
# Verifies Unit.gd combat stat formulas against GDD_02 math.

const GameConstants = preload("res://scripts/shared/GameConstants.gd")

class SignalWatcher extends RefCounted:
	var promoted_count: int = 0
	var promoted_from: String = ""
	var promoted_to: String = ""
	var prompt_count: int = 0
	var promoted_target: Node = null
	var prompt_target: Node = null
	var reclass_count: int = 0
	var reclass_from: String = ""
	var reclass_to: String = ""
	var reclass_target: Node = null

	func on_promoted(promoted_unit: Node, old_id: String, new_id: String) -> void:
		if promoted_unit != promoted_target:
			return
		promoted_count += 1
		promoted_from = old_id
		promoted_to = new_id

	func on_prompt(prompt_unit: Node) -> void:
		if prompt_unit != prompt_target:
			return
		prompt_count += 1

	func on_reclassed(reclassed_unit: Node, old_id: String, new_id: String) -> void:
		if reclassed_unit != reclass_target:
			return
		reclass_count += 1
		reclass_from = old_id
		reclass_to = new_id


func _wexp(rank: String, carry: int = 0) -> int:
	return mini(GameConstants.minimum_wexp_for_rank(rank) + carry, GameConstants.maximum_wexp_total())

func _init() -> void:
	print("=== Unit Combat Stats Test ===")

	# ── Load resources ──
	var soldier_data: UnitData = load("res://data/roster/default/unit_01_cavalier.tres").duplicate(true)
	var iron_lance: WeaponData = load("res://data/weapons/iron_lance.tres")
	soldier_data.inventory = [InventoryEntry.make_weapon("iron_lance", 45)]
	soldier_data.weapon_wexp = {"lance": _wexp("D")}

	var fixed_data := UnitData.new()
	fixed_data.level = 1
	fixed_data.hp = 20; fixed_data.max_hp = 20
	fixed_data.strength = 5; fixed_data.magic = 0; fixed_data.defense = 0
	fixed_data.resistance = 0; fixed_data.skill = 0; fixed_data.speed = 0; fixed_data.luck = 0

	var dur_data := UnitData.new()
	dur_data.inventory = [InventoryEntry.make_weapon("iron_lance", 1)]
	dur_data.weapon_wexp = {"lance": _wexp("D")}

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

	var relay := Node.new()
	root.add_child(relay)
	await process_frame
	var dm: Node = relay.get_node_or_null("/root/DataManager")
	var gs: Node = relay.get_node_or_null("/root/GameState")
	var bus: Node = relay.get_node_or_null("/root/EventBus")
	relay.queue_free()
	if dm == null or gs == null or bus == null:
		print("BAIL: required autoload missing — DataManager=%s GameState=%s EventBus=%s" % [
			dm, gs, bus])
		quit(1)
		return

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
	soldier_data.weapon_wexp = {"lance": _wexp("S")}
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

	# Per-class max level: Unit.add_exp reads ClassData.max_level, not a global constant.
	var saved_max_level: int = load("res://data/classes/cavalier.tres").max_level
	var class_res: ClassData = load("res://data/classes/cavalier.tres")
	class_res.max_level = 3
	soldier_data.level = 3
	soldier_data.exp = 20
	unit.add_exp(80)
	if soldier_data.level == 3 and soldier_data.exp == 20:
		print("OK  add_exp respects ClassData.max_level")
		passed += 1
	else:
		print("FAIL class max level: lvl=%d exp=%d" % [soldier_data.level, soldier_data.exp])
		failed += 1
	class_res.max_level = saved_max_level

	# --- M6.2: promotion eligibility / flow / auto-prompt ---
	var promo_base: ClassData = dm.get_class_data("cavalier")
	var saved_base_max_level: int = promo_base.max_level
	var saved_base_promotes_to: Array[String] = promo_base.promotes_to.duplicate(true)
	promo_base.max_level = 2
	promo_base.promotes_to = ["archer"]
	var promo_target: ClassData = dm.get_class_data("archer")
	var saved_target_tier: int = promo_target.tier
	var saved_target_caps: Dictionary = promo_target.stat_caps.duplicate(true)
	var saved_target_bonuses: Dictionary = promo_target.promotion_stat_bonuses.duplicate(true)
	var saved_target_weapon_wexp_bases: Dictionary = promo_target.weapon_wexp_bases.duplicate(true)
	var saved_target_weapon_wexp_caps: Dictionary = promo_target.weapon_wexp_caps.duplicate(true)
	var saved_target_internal_level_rule: String = promo_target.internal_level_rule
	promo_target.tier = 2
	promo_target.internal_level_rule = "promoted"
	promo_target.stat_caps = {"hp": 20, "strength": 12, "magic": 20, "defense": 20,
		"resistance": 20, "skill": 20, "speed": 20, "luck": 20}
	promo_target.promotion_stat_bonuses = {"hp": 5, "strength": 3, "defense": 2}
	promo_target.weapon_wexp_bases = {"sword": _wexp("D"), "bow": _wexp("E")}
	promo_target.weapon_wexp_caps = {"sword": _wexp("S"), "bow": _wexp("S")}

	var promo_data := UnitData.new()
	promo_data.class_id = "cavalier"
	promo_data.level = 2
	promo_data.exp = 80
	promo_data.internal_level = 7
	promo_data.hp = 18
	promo_data.max_hp = 18
	promo_data.strength = 10
	promo_data.defense = 6
	promo_data.weapon_wexp = {"sword": _wexp("D", 25)}
	promo_data.growth_accumulators = {"strength": 55}
	var promo_unit: Unit = unit_scene.instantiate()
	promo_unit.data = promo_data
	root.add_child(promo_unit)
	await process_frame
	if promo_unit.can_promote():
		print("OK  can_promote true at max level with promotion options")
		passed += 1
	else:
		print("FAIL can_promote should be true for eligible base class unit")
		failed += 1
	promo_data.level = 1
	if not promo_unit.can_promote():
		print("OK  can_promote false below class max level")
		passed += 1
	else:
		print("FAIL can_promote true below class max level")
		failed += 1
	promo_data.level = 2
	promo_base.promotes_to = []
	if not promo_unit.can_promote():
		print("OK  can_promote false with no promotion targets")
		passed += 1
	else:
		print("FAIL can_promote true with no promotion targets")
		failed += 1
	promo_base.promotes_to = ["archer"]
	promo_data.is_promoted = true
	if not promo_unit.can_promote():
		print("OK  can_promote false once already promoted")
		passed += 1
	else:
		print("FAIL can_promote true for promoted unit")
		failed += 1
	promo_data.is_promoted = false

	var watcher := SignalWatcher.new()
	watcher.promoted_target = promo_unit
	bus.unit_promoted.connect(Callable(watcher, "on_promoted"))
	await process_frame
	var promote_ok: bool = promo_unit.promote("archer")
	if promote_ok and promo_data.class_id == "archer" and promo_data.is_promoted \
			and promo_data.level == 1 and promo_data.exp == 0 \
			and promo_data.internal_level == 21 \
			and promo_data.growth_accumulators.is_empty() \
			and promo_data.max_hp == 20 and promo_data.hp == 20 \
			and promo_data.strength == 12 and promo_data.defense == 8 \
			and promo_data.weapon_wexp.get("bow", -1) == _wexp("E") \
			and promo_data.weapon_wexp.get("sword", -1) == _wexp("D", 25) \
			and watcher.promoted_count == 1 \
			and watcher.promoted_from == "cavalier" \
			and watcher.promoted_to == "archer":
		print("OK  promote applies bonuses, caps, weapon baselines, reset state, and emits unit_promoted")
		passed += 1
	else:
		print("FAIL promote: ok=%s class=%s lvl=%d exp=%d internal=%d hp=%d/%d str=%d def=%d weapon_wexp=%s promoted=%d from=%s to=%s" % [
			promote_ok, promo_data.class_id, promo_data.level, promo_data.exp,
			promo_data.internal_level, promo_data.hp, promo_data.max_hp,
			promo_data.strength, promo_data.defense, promo_data.weapon_wexp,
			watcher.promoted_count, watcher.promoted_from, watcher.promoted_to])
		failed += 1

	var auto_data := UnitData.new()
	auto_data.class_id = "cavalier"
	auto_data.level = 1
	auto_data.exp = 95
	auto_data.hp = 10
	auto_data.max_hp = 10
	auto_data.weapon_wexp = {"sword": _wexp("D")}
	var auto_unit: Unit = unit_scene.instantiate()
	auto_unit.data = auto_data
	root.add_child(auto_unit)
	await process_frame
	watcher.prompt_target = auto_unit
	bus.promotion_available.connect(Callable(watcher, "on_prompt"))
	await process_frame
	gs.auto_promote_at_max_level = true
	auto_unit.add_exp(5)
	if auto_data.level == 2 and auto_data.exp == 0 and watcher.prompt_count == 1:
		print("OK  auto-promote emits promotion_available at class cap when enabled")
		passed += 1
	else:
		print("FAIL auto-promote on: lvl=%d exp=%d prompts=%d" % [
			auto_data.level, auto_data.exp, watcher.prompt_count])
		failed += 1
	var no_prompt_data := UnitData.new()
	no_prompt_data.class_id = "cavalier"
	no_prompt_data.level = 1
	no_prompt_data.exp = 95
	no_prompt_data.hp = 10
	no_prompt_data.max_hp = 10
	no_prompt_data.weapon_wexp = {"sword": _wexp("D")}
	var no_prompt_unit: Unit = unit_scene.instantiate()
	no_prompt_unit.data = no_prompt_data
	root.add_child(no_prompt_unit)
	await process_frame
	var prompt_before: int = watcher.prompt_count
	gs.auto_promote_at_max_level = false
	no_prompt_unit.add_exp(5)
	if no_prompt_data.level == 2 and no_prompt_data.exp == 0 \
			and watcher.prompt_count == prompt_before:
		print("OK  auto-promote stays silent when the campaign rule is off")
		passed += 1
	else:
		print("FAIL auto-promote off: lvl=%d exp=%d prompts=%d before=%d" % [
			no_prompt_data.level, no_prompt_data.exp, watcher.prompt_count, prompt_before])
		failed += 1
	promo_base.max_level = saved_base_max_level
	promo_base.promotes_to = saved_base_promotes_to
	promo_target.tier = saved_target_tier
	promo_target.internal_level_rule = saved_target_internal_level_rule
	promo_target.stat_caps = saved_target_caps
	promo_target.promotion_stat_bonuses = saved_target_bonuses
	promo_target.weapon_wexp_bases = saved_target_weapon_wexp_bases
	promo_target.weapon_wexp_caps = saved_target_weapon_wexp_caps

	# --- Weapon EXP and rank-up ---
	soldier_data.weapon_wexp = {"lance": _wexp("D", 50)}
	unit.add_wexp("lance", 30)
	if soldier_data.weapon_wexp["lance"] == _wexp("D", 80) and unit.get_weapon_rank("lance") == "D":
		print("OK  add_wexp accumulates without rank-up")
		passed += 1
	else:
		print("FAIL wexp accumulate: %s" % soldier_data.weapon_wexp)
		failed += 1

	var ranked := unit.add_wexp("lance", 30)  # 180+30 = 210 → rank up to C, 10 carry
	if ranked and unit.get_weapon_rank("lance") == "C" and soldier_data.weapon_wexp["lance"] == _wexp("C", 10):
		print("OK  add_wexp triggers rank-up D→C")
		passed += 1
	else:
		print("FAIL rank up: %s ranked=%s" % [soldier_data.weapon_wexp, ranked])
		failed += 1

	# S rank cap
	soldier_data.weapon_wexp = {"lance": _wexp("S", 95)}
	unit.add_wexp("lance", 100)
	if unit.get_weapon_rank("lance") == "S" and soldier_data.weapon_wexp["lance"] == _wexp("S"):
		print("OK  wexp caps at 100 when already S-rank")
		passed += 1
	else:
		print("FAIL S-cap: %s" % soldier_data.weapon_wexp)
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

	# --- M2/M6.3: class skills auto-granted; earned_skills tracks stored skills ---
	var skill_unit: Unit = unit_scene.instantiate()
	var skill_data := UnitData.new()
	skill_unit.data = skill_data
	root.add_child(skill_unit)
	await process_frame
	var sc := ClassData.new()
	sc.skill_unlocks = {1: "vantage", 10: "wrath"}
	gs.max_skills = 1
	skill_data.level = 10
	var learned1: Array = skill_unit._grant_level_skills(sc)  # → wrath
	skill_data.level = 1
	var learned2: Array = skill_unit._grant_level_skills(sc)  # → stored, slots full
	var learned3: Array = skill_unit._grant_level_skills(sc)  # vantage already known → none
	if learned1.size() == 1 and learned1[0]["id"] == "wrath" and learned1[0]["equipped"] \
			and learned2.size() == 1 and learned2[0]["id"] == "vantage" \
			and not learned2[0]["equipped"] and learned3.is_empty() \
			and skill_data.skills == ["wrath"] \
			and skill_data.earned_skills == ["wrath", "vantage"]:
		print("OK  M2/M6.3: class skills auto-grant, respect max_skills, and track earned_skills")
		passed += 1
	else:
		print("FAIL M2/M6.3 skill grant: skills=%s earned=%s l1=%s l2=%s l3=%s" % [
			skill_data.skills, skill_data.earned_skills, learned1, learned2, learned3])
		failed += 1
	gs.max_skills = 4

	# --- N6/F1: a newly created level-1 unit receives its class level-1 skill once ---
	var init_skill_unit: Unit = unit_scene.instantiate()
	var init_skill_data := UnitData.new()
	init_skill_data.class_id = "cavalier"
	init_skill_data.level = 1
	init_skill_data.hp = 10
	init_skill_data.max_hp = 10
	init_skill_unit.data = init_skill_data
	root.add_child(init_skill_unit)
	await process_frame
	init_skill_unit._grant_current_level_class_skills()
	if init_skill_data.skills == ["discipline"] and init_skill_data.earned_skills == ["discipline"]:
		print("OK  N6/F1: unit creation grants the class level-1 skill without duplicates")
		passed += 1
	else:
		print("FAIL N6/F1 init skill grant: skills=%s earned=%s" % [
			init_skill_data.skills, init_skill_data.earned_skills])
		failed += 1

	# --- C3 helper lookups: MapData.get_faction + FactionData.display_label ---
	var md_helpers := MapData.new()
	var fd_helpers := FactionData.new()
	fd_helpers.id = "green"
	fd_helpers.display_name = "Verdant"
	md_helpers.factions = [fd_helpers]
	var helper_found: bool = md_helpers.get_faction("green") == fd_helpers
	var helper_missing: bool = md_helpers.get_faction("purple") == null
	var helper_label: bool = FactionData.display_label("yellow") == "Yellow"
	if helper_found and helper_missing and helper_label:
		print("OK  C3 helpers: get_faction resolves known ids and display_label title-cases ids")
		passed += 1
	else:
		print("FAIL C3 helpers: found=%s missing=%s label=%s" % [helper_found, helper_missing, helper_label])
		failed += 1

	# --- M7: Second Seal eligibility, options, and reclass rules ---
	var watcher_reclass := SignalWatcher.new()
	var seal_base: Unit = unit_scene.instantiate()
	var seal_base_data := UnitData.new()
	seal_base_data.class_id = "cavalier"
	seal_base_data.class_line_id = "cavalier"
	seal_base_data.reclass_options = ["cavalier", "knight", "mercenary"]
	seal_base_data.level = 9
	seal_base_data.internal_level = 9
	seal_base_data.hp = 18
	seal_base_data.max_hp = 18
	seal_base_data.strength = 8
	seal_base_data.magic = 0
	seal_base_data.defense = 6
	seal_base_data.resistance = 3
	seal_base_data.skill = 7
	seal_base_data.speed = 7
	seal_base_data.luck = 5
	seal_base_data.weapon_wexp = {"lance": _wexp("D")}
	seal_base.data = seal_base_data
	root.add_child(seal_base)
	await process_frame
	if not seal_base.can_use_second_seal():
		print("OK  M7: a tier-1 unit below level 10 cannot use Second Seal")
		passed += 1
	else:
		print("FAIL M7 tier-1 gate: unit below level 10 should not use Second Seal")
		failed += 1
	seal_base_data.level = 10
	var base_options: Array[Dictionary] = seal_base.get_second_seal_options()
	var base_ids: Array = base_options.map(func(opt): return opt["class_id"])
	var base_has_tier2: bool = base_options.any(func(opt): return int(opt["target_tier"]) == 2)
	if seal_base.can_use_second_seal() and "knight" in base_ids and "mercenary" in base_ids \
			and not ("paladin" in base_ids) and not base_has_tier2:
		print("OK  M7: a tier-1 level-10 unit gets only tier-1 reclass options")
		passed += 1
	else:
		print("FAIL M7 tier-1 options: ids=%s has_tier2=%s" % [base_ids, base_has_tier2])
		failed += 1
	watcher_reclass.reclass_target = seal_base
	bus.unit_reclassed.connect(Callable(watcher_reclass, "on_reclassed"))
	var base_reclass_ok: bool = seal_base.reclass("knight")
	if base_reclass_ok and seal_base_data.class_id == "knight" \
			and seal_base_data.class_line_id == "knight" and seal_base_data.level == 1 \
			and seal_base_data.exp == 0 and not seal_base_data.is_promoted \
			and seal_base_data.skills.has("defense_plus_2") \
			and seal_base_data.earned_skills.has("defense_plus_2") \
			and watcher_reclass.reclass_count == 1 \
			and watcher_reclass.reclass_from == "cavalier" \
			and watcher_reclass.reclass_to == "knight":
		print("OK  M7: tier-1 reclass changes class, resets level, grants the new level-1 skill, and emits unit_reclassed")
		passed += 1
	else:
		print("FAIL M7 tier-1 reclass: ok=%s class=%s line=%s lvl=%d exp=%d promoted=%s skills=%s earned=%s signals=%d from=%s to=%s" % [
			base_reclass_ok, seal_base_data.class_id, seal_base_data.class_line_id,
			seal_base_data.level, seal_base_data.exp, seal_base_data.is_promoted,
			seal_base_data.skills, seal_base_data.earned_skills,
			watcher_reclass.reclass_count, watcher_reclass.reclass_from,
			watcher_reclass.reclass_to])
		failed += 1

	var seal_promoted: Unit = unit_scene.instantiate()
	var seal_promoted_data := UnitData.new()
	seal_promoted_data.class_id = "paladin"
	seal_promoted_data.class_line_id = "cavalier"
	seal_promoted_data.level = 9
	seal_promoted_data.exp = 40
	seal_promoted_data.is_promoted = true
	seal_promoted_data.internal_level = 17
	seal_promoted_data.hp = 28
	seal_promoted_data.max_hp = 30
	seal_promoted_data.strength = 14
	seal_promoted_data.magic = 1
	seal_promoted_data.defense = 10
	seal_promoted_data.resistance = 8
	seal_promoted_data.skill = 10
	seal_promoted_data.speed = 10
	seal_promoted_data.luck = 7
	seal_promoted_data.weapon_wexp = {"lance": _wexp("B"), "sword": _wexp("C")}
	seal_promoted.data = seal_promoted_data
	root.add_child(seal_promoted)
	await process_frame
	var promoted_low_options: Array[Dictionary] = seal_promoted.get_second_seal_options()
	var promoted_low_has_tier2: bool = promoted_low_options.any(func(opt): return int(opt["target_tier"]) == 2)
	if seal_promoted.can_use_second_seal() and not promoted_low_has_tier2:
		print("OK  M7: a promoted unit below level 10 can demote but cannot laterally reclass")
		passed += 1
	else:
		print("FAIL M7 promoted low options: can_use=%s opts=%s" % [
			seal_promoted.can_use_second_seal(), promoted_low_options])
		failed += 1
	var demote_ok: bool = seal_promoted.reclass("knight")
	if demote_ok and seal_promoted_data.class_id == "knight" and seal_promoted_data.class_line_id == "knight" \
			and not seal_promoted_data.is_promoted and seal_promoted_data.level == 1 \
			and seal_promoted_data.internal_level == 17 and seal_promoted_data.max_hp == 23 \
			and seal_promoted_data.hp == 23 and seal_promoted_data.strength == 11 \
			and seal_promoted_data.magic == 0 and seal_promoted_data.defense == 7 \
			and seal_promoted_data.resistance == 2:
		print("OK  M7: demotion removes source promotion bonuses and preserves internal_level")
		passed += 1
	else:
		print("FAIL M7 demotion: ok=%s class=%s line=%s promoted=%s lvl=%d eff=%d hp=%d/%d str=%d mag=%d def=%d res=%d" % [
			demote_ok, seal_promoted_data.class_id, seal_promoted_data.class_line_id,
			seal_promoted_data.is_promoted, seal_promoted_data.level,
			seal_promoted_data.internal_level, seal_promoted_data.hp,
			seal_promoted_data.max_hp, seal_promoted_data.strength,
			seal_promoted_data.magic, seal_promoted_data.defense,
			seal_promoted_data.resistance])
		failed += 1

	var seal_lateral: Unit = unit_scene.instantiate()
	var seal_lateral_data := UnitData.new()
	seal_lateral_data.class_id = "paladin"
	seal_lateral_data.class_line_id = "cavalier"
	seal_lateral_data.level = 10
	seal_lateral_data.is_promoted = true
	seal_lateral_data.internal_level = 18
	seal_lateral_data.hp = 28
	seal_lateral_data.max_hp = 30
	seal_lateral_data.strength = 14
	seal_lateral_data.magic = 1
	seal_lateral_data.defense = 10
	seal_lateral_data.resistance = 8
	seal_lateral_data.skill = 10
	seal_lateral_data.speed = 10
	seal_lateral_data.luck = 7
	seal_lateral_data.weapon_wexp = {"lance": _wexp("B"), "sword": _wexp("C")}
	seal_lateral.data = seal_lateral_data
	root.add_child(seal_lateral)
	await process_frame
	var lateral_options: Array[Dictionary] = seal_lateral.get_second_seal_options()
	var bow_knight_lines: Array = lateral_options.filter(func(opt): return opt["class_id"] == "bow_knight") \
		.map(func(opt): return opt["class_line_id"])
	var lateral_has_hero: bool = lateral_options.any(func(opt): return opt["class_id"] == "hero")
	if lateral_has_hero and bow_knight_lines.size() == 2 \
			and "archer" in bow_knight_lines and "mercenary" in bow_knight_lines:
		print("OK  M7: a promoted level-10 unit sees lateral tier-2 options, including shared-class lines")
		passed += 1
	else:
		print("FAIL M7 lateral options: hero=%s bow_knight_lines=%s opts=%s" % [
			lateral_has_hero, bow_knight_lines, lateral_options])
		failed += 1
	var lateral_ok: bool = seal_lateral.reclass("hero", "mercenary")
	if lateral_ok and seal_lateral_data.class_id == "hero" and seal_lateral_data.class_line_id == "mercenary" \
			and seal_lateral_data.is_promoted and seal_lateral_data.level == 1 \
			and seal_lateral_data.max_hp == 23 and seal_lateral_data.hp == 23 \
			and seal_lateral_data.strength == 11 and seal_lateral_data.magic == 0 \
			and seal_lateral_data.defense == 7 and seal_lateral_data.resistance == 2 \
			and seal_lateral_data.weapon_wexp.get("axe", -1) == _wexp("E"):
		print("OK  M7: lateral tier-2 reclass removes source bonuses, keeps no target bonuses, and adds new weapon baselines at E")
		passed += 1
	else:
		print("FAIL M7 lateral reclass: ok=%s class=%s line=%s promoted=%s lvl=%d hp=%d/%d str=%d mag=%d def=%d res=%d weapon_wexp=%s" % [
			lateral_ok, seal_lateral_data.class_id, seal_lateral_data.class_line_id,
			seal_lateral_data.is_promoted, seal_lateral_data.level,
			seal_lateral_data.hp, seal_lateral_data.max_hp, seal_lateral_data.strength,
			seal_lateral_data.magic, seal_lateral_data.defense,
			seal_lateral_data.resistance, seal_lateral_data.weapon_wexp])
		failed += 1
	seal_lateral_data.level = 20
	seal_lateral_data.exp = 55
	var hp_before_reset: int = seal_lateral_data.hp
	var max_hp_before_reset: int = seal_lateral_data.max_hp
	var reset_ok: bool = seal_lateral.reclass("hero", "mercenary")
	if reset_ok and seal_lateral_data.level == 1 and seal_lateral_data.exp == 0 \
			and seal_lateral_data.hp == hp_before_reset \
			and seal_lateral_data.max_hp == max_hp_before_reset:
		print("OK  M7: self-reset keeps stats unchanged while resetting the displayed level")
		passed += 1
	else:
		print("FAIL M7 self-reset: ok=%s lvl=%d exp=%d hp=%d/%d want=%d/%d" % [
			reset_ok, seal_lateral_data.level, seal_lateral_data.exp,
			seal_lateral_data.hp, seal_lateral_data.max_hp,
			hp_before_reset, max_hp_before_reset])
		failed += 1

	# --- use_weapon_durability: last-use removal doesn't lose wexp if weapon captured first ---
	# Regression for MapCursorTargeting._apply_staff_heal ordering bug: fetching get_equipped_weapon()
	# after use_weapon_durability() on a 1-use weapon returns null/wrong weapon.
	var pre_weapon: WeaponData = iron_lance  # captured BEFORE use (the correct ordering)
	dur_unit.use_weapon_durability()
	var entry_removed: bool = dur_data.inventory.is_empty()
	dur_unit.add_wexp(pre_weapon.wexp_track, pre_weapon.wexp)
	var wexp_ok: bool = dur_data.weapon_wexp["lance"] == _wexp("D", pre_weapon.wexp)
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
