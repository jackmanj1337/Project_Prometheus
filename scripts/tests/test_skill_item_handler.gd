extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_skill_item_handler.gd
# Tests SkillHandler._execute_skill dispatch and ItemHandler.apply_item effects.

const SkillHandlerS = preload("res://scripts/skills/SkillHandler.gd")
const ItemHandlerS  = preload("res://scripts/items/ItemHandler.gd")
const DataManagerS  = preload("res://scripts/autoloads/DataManager.gd")

# ---- Minimal mock unit ----
class MockUnit extends Node:
	var data: UnitData
	var team: String = "player"

	func setup(unit_data: UnitData) -> void:
		data = unit_data

	func heal(amount: int) -> void:
		data.hp = mini(data.hp + amount, data.max_hp)

	func add_modifier(stat: String, delta: int, source: String, _dur: int, _dtype: String) -> void:
		data.active_modifiers.append({"stat": stat, "delta": delta, "source": source})

	func get_effective_stat(stat_name: String) -> int:
		var base = data.get(stat_name)
		var total: int = int(base) if base != null else 0
		for mod in data.active_modifiers:
			if mod.get("stat", "") == stat_name:
				total += mod.get("delta", 0)
		return max(0, total)


func _make_ctx(atk: Node, def: Node, w_atk: WeaponData, w_def: WeaponData,
		damage: int = 0, sim_hp: int = 17) -> Dictionary:
	return {
		"attacker": atk, "defender": def,
		"attacker_weapon": w_atk, "defender_weapon": w_def,
		"current_sim_hp": sim_hp,
		"damage": damage,
		"flags": {},
		"atk_mod": {"accuracy": 0, "dodge": 0, "crit": 0, "damage": 0, "damage_multiplier": 1.0},
		"def_mod": {"accuracy": 0, "dodge": 0, "crit": 0, "damage": 0, "damage_multiplier": 1.0},
	}


func _init() -> void:
	print("=== SkillHandler + ItemHandler Test ===")

	# Register DataManager under /root so ItemHandler's get_node_or_null finds it.
	var dm: Node = DataManagerS.new()
	dm.name = "DataManager"
	root.add_child(dm)
	dm._ready()

	var sh: Node = SkillHandlerS.new()
	sh.name = "SkillHandler"
	root.add_child(sh)

	var ih: Node = ItemHandlerS.new()
	ih.name = "ItemHandler"
	root.add_child(ih)

	# Wait one frame so all nodes are in the active scene tree;
	# required for get_node_or_null("/root/...") to work from child nodes.
	await process_frame

	var passed := 0
	var failed := 0

	var soldier_data: UnitData = load("res://data/roster/default/unit_01_soldier.tres").duplicate(true)
	var unit := MockUnit.new()
	unit.setup(soldier_data)
	root.add_child(unit)

	var def_unit := MockUnit.new()
	def_unit.setup(soldier_data.duplicate(true))
	root.add_child(def_unit)

	var iron_lance: WeaponData = load("res://data/weapons/iron_lance.tres")
	var iron_sword: WeaponData = load("res://data/weapons/iron_sword.tres")

	# ── Vantage: only sets flag when unit == defender ─────────────────────────
	var vantage_skill: SkillData = load("res://data/skills/vantage.tres")
	var ctx: Dictionary = _make_ctx(def_unit, unit, iron_lance, iron_lance)
	ctx = sh._execute_skill(vantage_skill, unit, ctx)
	if ctx["flags"].get("vantage", false):
		print("OK  vantage sets flag when unit is defender"); passed += 1
	else:
		print("FAIL vantage: flag not set when unit is defender"); failed += 1

	var ctx2: Dictionary = _make_ctx(unit, def_unit, iron_lance, iron_lance)
	ctx2 = sh._execute_skill(vantage_skill, unit, ctx2)
	if not ctx2["flags"].has("vantage"):
		print("OK  vantage no flag when unit is attacker"); passed += 1
	else:
		print("FAIL vantage: flag set when unit is attacker"); failed += 1

	# ── Wrath: +50 crit when HP ≤ 50% ────────────────────────────────────────
	var wrath_skill: SkillData = load("res://data/skills/wrath.tres")
	var wrath_data: UnitData = soldier_data.duplicate(true)
	wrath_data.hp = 8  # 47% — triggers
	var wrath_unit := MockUnit.new()
	wrath_unit.setup(wrath_data)
	root.add_child(wrath_unit)
	var ctx3: Dictionary = _make_ctx(wrath_unit, def_unit, iron_lance, iron_lance)
	ctx3["attacker"] = wrath_unit
	ctx3 = sh._execute_skill(wrath_skill, wrath_unit, ctx3)
	if ctx3["atk_mod"]["crit"] == 50:
		print("OK  wrath +50 crit when HP ≤ 50%"); passed += 1
	else:
		print("FAIL wrath: expected crit 50, got %d" % ctx3["atk_mod"]["crit"]); failed += 1

	var full_data: UnitData = soldier_data.duplicate(true)
	full_data.hp = 17  # full — no trigger
	var full_unit := MockUnit.new()
	full_unit.setup(full_data)
	root.add_child(full_unit)
	var ctx4: Dictionary = _make_ctx(full_unit, def_unit, iron_lance, iron_lance)
	ctx4["attacker"] = full_unit
	ctx4 = sh._execute_skill(wrath_skill, full_unit, ctx4)
	if ctx4["atk_mod"]["crit"] == 0:
		print("OK  wrath no bonus when HP > 50%"); passed += 1
	else:
		print("FAIL wrath: bonus applied at full HP"); failed += 1

	# ── Miracle: caps fatal damage at sim_hp - 1 ─────────────────────────────
	var miracle_skill: SkillData = load("res://data/skills/miracle.tres")
	var ctx5: Dictionary = _make_ctx(def_unit, unit, iron_lance, iron_lance, 10, 10)
	ctx5 = sh._execute_skill(miracle_skill, unit, ctx5)
	if ctx5["damage"] == 9:
		print("OK  miracle caps fatal damage to sim_hp-1"); passed += 1
	else:
		print("FAIL miracle: expected damage 9, got %d" % ctx5["damage"]); failed += 1

	var ctx6: Dictionary = _make_ctx(def_unit, unit, iron_lance, iron_lance, 5, 10)
	ctx6 = sh._execute_skill(miracle_skill, unit, ctx6)
	if ctx6["damage"] == 5:
		print("OK  miracle no-op on non-fatal damage"); passed += 1
	else:
		print("FAIL miracle: modified non-fatal damage"); failed += 1

	# ── Resolve: adds modifiers when HP ≤ 50% ────────────────────────────────
	var resolve_skill: SkillData = load("res://data/skills/resolve.tres")
	var res_data: UnitData = soldier_data.duplicate(true)
	res_data.hp = 8
	var res_unit := MockUnit.new()
	res_unit.setup(res_data)
	root.add_child(res_unit)
	var ctx7: Dictionary = _make_ctx(res_unit, def_unit, iron_lance, iron_lance)
	sh._execute_skill(resolve_skill, res_unit, ctx7)
	var str_bonus := 0
	for mod in res_data.active_modifiers:
		if mod.get("stat") == "strength":
			str_bonus += mod.get("delta", 0)
	if str_bonus > 0:
		print("OK  resolve adds STR modifier when HP ≤ 50%"); passed += 1
	else:
		print("FAIL resolve: no STR modifier added"); failed += 1

	# ── Faire: +damage for matching weapon type ───────────────────────────────
	var faire_skill: SkillData = load("res://data/skills/lancefaire.tres")
	var ctx8: Dictionary = _make_ctx(unit, def_unit, iron_lance, iron_lance)
	ctx8["attacker"] = unit
	ctx8 = sh._execute_skill(faire_skill, unit, ctx8)
	if ctx8["atk_mod"]["damage"] > 0:
		print("OK  lancefaire adds damage bonus with lance"); passed += 1
	else:
		print("FAIL lancefaire: no bonus with lance"); failed += 1

	var ctx9: Dictionary = _make_ctx(unit, def_unit, iron_sword, iron_lance)
	ctx9["attacker"] = unit
	ctx9 = sh._execute_skill(faire_skill, unit, ctx9)
	if ctx9["atk_mod"]["damage"] == 0:
		print("OK  lancefaire no bonus with sword"); passed += 1
	else:
		print("FAIL lancefaire: bonus applied with wrong weapon type"); failed += 1

	# ── Breaker: +hit vs matching opponent weapon type ────────────────────────
	var breaker_skill: SkillData = load("res://data/skills/lancebreaker.tres")
	var ctx10: Dictionary = _make_ctx(unit, def_unit, iron_sword, iron_lance)
	ctx10["attacker"] = unit
	ctx10 = sh._execute_skill(breaker_skill, unit, ctx10)
	if ctx10["atk_mod"]["accuracy"] > 0:
		print("OK  lancebreaker +hit vs lance opponent"); passed += 1
	else:
		print("FAIL lancebreaker: no hit bonus vs lance"); failed += 1

	var ctx11: Dictionary = _make_ctx(unit, def_unit, iron_sword, iron_sword)
	ctx11["attacker"] = unit
	ctx11 = sh._execute_skill(breaker_skill, unit, ctx11)
	if ctx11["atk_mod"]["accuracy"] == 0:
		print("OK  lancebreaker no bonus vs non-lance opponent"); passed += 1
	else:
		print("FAIL lancebreaker: bonus applied vs non-lance"); failed += 1

	# ── ItemHandler: heal_flat heals and decrements uses ──────────────────────
	var vuln_data: UnitData = soldier_data.duplicate(true)
	vuln_data.hp = 10
	vuln_data.max_hp = 17
	var vuln_unit := MockUnit.new()
	vuln_unit.setup(vuln_data)
	root.add_child(vuln_unit)
	var vuln_entry := InventoryEntry.make_item("vulnerary", 3)
	vuln_data.inventory = [vuln_entry]
	ih.apply_item(vuln_unit, vuln_entry)
	if vuln_data.hp > 10:
		print("OK  vulnerary heals HP"); passed += 1
	else:
		print("FAIL vulnerary: HP unchanged after use"); failed += 1
	if vuln_entry.uses_remaining == 2:
		print("OK  vulnerary decrements uses"); passed += 1
	else:
		print("FAIL vulnerary: uses not decremented"); failed += 1

	# ── ItemHandler: does not overheal ───────────────────────────────────────
	var full_data2: UnitData = soldier_data.duplicate(true)
	full_data2.hp = 17
	full_data2.max_hp = 17
	var full_unit2 := MockUnit.new()
	full_unit2.setup(full_data2)
	root.add_child(full_unit2)
	var vuln_entry2 := InventoryEntry.make_item("vulnerary", 3)
	full_data2.inventory = [vuln_entry2]
	ih.apply_item(full_unit2, vuln_entry2)
	if full_data2.hp == 17:
		print("OK  vulnerary does not overheal"); passed += 1
	else:
		print("FAIL vulnerary: overhealed"); failed += 1
	if vuln_entry2.uses_remaining == 2:
		print("OK  vulnerary still consumed when already full"); passed += 1
	else:
		print("FAIL vulnerary: uses not consumed at full HP"); failed += 1

	# ── ItemHandler: last use removes item from inventory ─────────────────────
	var last_data: UnitData = soldier_data.duplicate(true)
	last_data.hp = 10
	last_data.max_hp = 17
	var last_unit := MockUnit.new()
	last_unit.setup(last_data)
	root.add_child(last_unit)
	var last_entry := InventoryEntry.make_item("vulnerary", 1)
	last_data.inventory = [last_entry]
	ih.apply_item(last_unit, last_entry)
	if last_data.inventory.is_empty():
		print("OK  item removed from inventory when uses reach 0"); passed += 1
	else:
		print("FAIL item: not removed when uses reach 0"); failed += 1

	# ── ItemHandler: empty item_id is a no-op ────────────────────────────────
	var skip_data: UnitData = soldier_data.duplicate(true)
	var skip_unit := MockUnit.new()
	skip_unit.setup(skip_data)
	root.add_child(skip_unit)
	var skip_entry := InventoryEntry.make_item("", 3)
	skip_data.inventory = [skip_entry]
	ih.apply_item(skip_unit, skip_entry)
	if skip_entry.uses_remaining == 3:
		print("OK  empty item_id is a no-op (uses not consumed)"); passed += 1
	else:
		print("FAIL empty item_id: uses were consumed"); failed += 1

	# ── B1: -1 = infinite-use sentinel — item heals but is never consumed ─────
	var inf_data: UnitData = soldier_data.duplicate(true)
	inf_data.hp = 10
	inf_data.max_hp = 17
	var inf_unit := MockUnit.new()
	inf_unit.setup(inf_data)
	root.add_child(inf_unit)
	var inf_entry := InventoryEntry.make_item("vulnerary", -1)
	inf_data.inventory = [inf_entry]
	ih.apply_item(inf_unit, inf_entry)
	if inf_data.hp > 10 and inf_entry.uses_remaining == -1 and inf_data.inventory.size() == 1:
		print("OK  B1: -1 item heals but is never consumed or removed"); passed += 1
	else:
		print("FAIL B1 item: hp=%d uses=%d inv=%d" \
			% [inf_data.hp, inf_entry.uses_remaining, inf_data.inventory.size()]); failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
