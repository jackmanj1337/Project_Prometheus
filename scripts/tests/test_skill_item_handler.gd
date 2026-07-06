extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_skill_item_handler.gd
# Tests SkillHandler._execute_skill dispatch and ItemHandler.apply_item effects.

const SkillHandlerS = preload("res://scripts/skills/SkillHandler.gd")
const ItemHandlerS  = preload("res://scripts/items/ItemHandler.gd")
const DataManagerS  = preload("res://scripts/autoloads/DataManager.gd")

# ---- Minimal mock unit ----
class MockUnit extends Node:
	var data: UnitData
	var team: String = "blue"
	var tile_position: Vector2i = Vector2i.ZERO
	var second_seal_usable: bool = false

	func setup(unit_data: UnitData) -> void:
		data = unit_data

	func heal(amount: int) -> void:
		data.hp = mini(data.hp + amount, data.max_hp)

	# Faithful mirror of Unit.add_modifier — replaces all modifiers sharing a source
	# and stores duration + duration_type so callers can verify the modifier shape.
	func add_modifier(stat: String, delta: int, source: String, duration: int, duration_type: String) -> void:
		remove_modifier(source)
		data.active_modifiers.append({"stat": stat, "delta": delta, "source": source,
			"duration": duration, "duration_type": duration_type})

	func remove_modifier(source: String) -> void:
		data.active_modifiers = data.active_modifiers.filter(
			func(m): return m.get("source", "") != source)

	func get_effective_stat(stat_name: String) -> int:
		var base = data.get(stat_name)
		var total: int = int(base) if base != null else 0
		for mod in data.active_modifiers:
			if mod.get("stat", "") == stat_name:
				total += mod.get("delta", 0)
		return max(0, total)

	func can_promote() -> bool:
		var dm := get_node_or_null("/root/DataManager")
		if dm == null or data == null:
			return false
		var class_data: ClassData = dm.get_class_data(data.class_id)
		return class_data != null and not data.is_promoted \
			and data.level >= class_data.max_level and not class_data.promotes_to.is_empty()

	func can_use_second_seal() -> bool:
		return second_seal_usable


class MockGameState extends Node:
	var all_units: Array[Node] = []

	func are_hostile(a_id: String, b_id: String) -> bool:
		return a_id != b_id


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

	var gs := MockGameState.new()
	gs.name = "GameState"
	root.add_child(gs)

	var ih: Node = ItemHandlerS.new()
	ih.name = "ItemHandler"
	root.add_child(ih)

	# Wait one frame so all nodes are in the active scene tree;
	# required for get_node_or_null("/root/...") to work from child nodes.
	await process_frame

	var passed := 0
	var failed := 0

	var soldier_data: UnitData = load("res://data/roster/default/unit_01_cavalier.tres").duplicate(true)
	var unit := MockUnit.new()
	unit.setup(soldier_data)
	root.add_child(unit)

	var def_unit := MockUnit.new()
	def_unit.setup(soldier_data.duplicate(true))
	root.add_child(def_unit)
	gs.all_units = [unit, def_unit]

	var iron_lance: WeaponData = load("res://data/weapons/iron_lance.tres")
	var iron_sword: WeaponData = load("res://data/weapons/iron_sword.tres")

	# ── Vantage: only sets flag when unit == defender ─────────────────────────
	var vantage_skill: SkillData = load("res://data/skills/vantage.tres")
	var ctx: Dictionary = _make_ctx(def_unit, unit, iron_lance, iron_lance)
	# _execute_skill now returns whether the effect fired (context mutates by reference).
	var vantage_fired: bool = sh._execute_skill(vantage_skill, unit, ctx)
	if ctx["flags"].get("vantage", false) and vantage_fired:
		print("OK  vantage sets flag and reports fired when unit is defender"); passed += 1
	else:
		print("FAIL vantage: flag not set / not reported fired when unit is defender"); failed += 1

	var ctx2: Dictionary = _make_ctx(unit, def_unit, iron_lance, iron_lance)
	var vantage_fired2: bool = sh._execute_skill(vantage_skill, unit, ctx2)
	if not ctx2["flags"].has("vantage") and not vantage_fired2:
		print("OK  vantage no flag and reports not-fired when unit is attacker"); passed += 1
	else:
		print("FAIL vantage: flag set / reported fired when unit is attacker"); failed += 1

	# ── Wrath: +50 crit when HP ≤ 50% ────────────────────────────────────────
	var wrath_skill: SkillData = load("res://data/skills/wrath.tres")
	var wrath_data: UnitData = soldier_data.duplicate(true)
	wrath_data.hp = 8  # 47% — triggers
	var wrath_unit := MockUnit.new()
	wrath_unit.setup(wrath_data)
	root.add_child(wrath_unit)
	var ctx3: Dictionary = _make_ctx(wrath_unit, def_unit, iron_lance, iron_lance)
	ctx3["attacker"] = wrath_unit
	sh._execute_skill(wrath_skill, wrath_unit, ctx3)
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
	var wrath_fired_full: bool = sh._execute_skill(wrath_skill, full_unit, ctx4)
	if ctx4["atk_mod"]["crit"] == 0 and not wrath_fired_full:
		print("OK  wrath no bonus / not fired when HP > 50%"); passed += 1
	else:
		print("FAIL wrath: bonus applied / reported fired at full HP"); failed += 1

	# ── Miracle: caps fatal damage at sim_hp - 1; reports fired only when lethal ──
	var miracle_skill: SkillData = load("res://data/skills/miracle.tres")
	var ctx5: Dictionary = _make_ctx(def_unit, unit, iron_lance, iron_lance, 10, 10)
	var miracle_fired: bool = sh._execute_skill(miracle_skill, unit, ctx5)
	if ctx5["damage"] == 9 and miracle_fired:
		print("OK  miracle caps fatal damage to sim_hp-1 and reports fired"); passed += 1
	else:
		print("FAIL miracle: expected damage 9 + fired, got %d / %s" % [ctx5["damage"], miracle_fired]); failed += 1

	var ctx6: Dictionary = _make_ctx(def_unit, unit, iron_lance, iron_lance, 5, 10)
	var miracle_fired_nonfatal: bool = sh._execute_skill(miracle_skill, unit, ctx6)
	# #6: a non-lethal hit must report not-fired so a use-limited Miracle isn't burned.
	if ctx6["damage"] == 5 and not miracle_fired_nonfatal:
		print("OK  miracle no-op on non-fatal damage and reports not-fired"); passed += 1
	else:
		print("FAIL miracle: modified non-fatal damage / reported fired"); failed += 1

	# ── Resolve: adds modifiers when HP ≤ 50% ────────────────────────────────
	var resolve_skill: SkillData = load("res://data/skills/resolve.tres")
	var res_data: UnitData = soldier_data.duplicate(true)
	res_data.hp = 8
	var res_unit := MockUnit.new()
	res_unit.setup(res_data)
	root.add_child(res_unit)
	var ctx7: Dictionary = _make_ctx(res_unit, def_unit, iron_lance, iron_lance)
	sh._execute_skill(resolve_skill, res_unit, ctx7)
	# All four stats must survive — Resolve uses a distinct source per stat, since a
	# single shared source would make add_modifier() wipe three of the four.
	var resolve_stats := {}
	for mod in res_data.active_modifiers:
		if str(mod.get("source", "")).begins_with("resolve"):
			resolve_stats[mod.get("stat")] = true
	if resolve_stats.has("strength") and resolve_stats.has("magic") \
			and resolve_stats.has("skill") and resolve_stats.has("speed"):
		print("OK  resolve adds STR/MAG/SKL/SPD modifiers when HP ≤ 50%"); passed += 1
	else:
		print("FAIL resolve: expected 4 stat modifiers, got %s" % str(resolve_stats.keys())); failed += 1

	# ── Faire: +damage for matching weapon type ───────────────────────────────
	var faire_skill: SkillData = load("res://data/skills/lancefaire.tres")
	var ctx8: Dictionary = _make_ctx(unit, def_unit, iron_lance, iron_lance)
	ctx8["attacker"] = unit
	sh._execute_skill(faire_skill, unit, ctx8)
	if ctx8["atk_mod"]["damage"] > 0:
		print("OK  lancefaire adds damage bonus with lance"); passed += 1
	else:
		print("FAIL lancefaire: no bonus with lance"); failed += 1

	var ctx9: Dictionary = _make_ctx(unit, def_unit, iron_sword, iron_lance)
	ctx9["attacker"] = unit
	var faire_fired_wrong: bool = sh._execute_skill(faire_skill, unit, ctx9)
	if ctx9["atk_mod"]["damage"] == 0 and not faire_fired_wrong:
		print("OK  lancefaire no bonus / not fired with sword"); passed += 1
	else:
		print("FAIL lancefaire: bonus applied / reported fired with wrong weapon type"); failed += 1

	# ── Breaker: +hit vs matching opponent weapon type ────────────────────────
	var breaker_skill: SkillData = load("res://data/skills/lancebreaker.tres")
	var ctx10: Dictionary = _make_ctx(unit, def_unit, iron_sword, iron_lance)
	ctx10["attacker"] = unit
	sh._execute_skill(breaker_skill, unit, ctx10)
	if ctx10["atk_mod"]["accuracy"] > 0:
		print("OK  lancebreaker +hit vs lance opponent"); passed += 1
	else:
		print("FAIL lancebreaker: no hit bonus vs lance"); failed += 1

	var ctx11: Dictionary = _make_ctx(unit, def_unit, iron_sword, iron_sword)
	ctx11["attacker"] = unit
	sh._execute_skill(breaker_skill, unit, ctx11)
	if ctx11["atk_mod"]["accuracy"] == 0:
		print("OK  lancebreaker no bonus vs non-lance opponent"); passed += 1
	else:
		print("FAIL lancebreaker: bonus applied vs non-lance"); failed += 1

	# ── M9a: stat_bonus applies a combat-duration modifier through unit stats ──
	var skill_plus_2: SkillData = load("res://data/skills/skill_plus_2.tres")
	var sb_data: UnitData = soldier_data.duplicate(true)
	var sb_unit := MockUnit.new()
	sb_unit.setup(sb_data)
	root.add_child(sb_unit)
	var sb_ctx: Dictionary = _make_ctx(sb_unit, def_unit, iron_lance, iron_lance)
	var sb_fired: bool = sh._execute_skill(skill_plus_2, sb_unit, sb_ctx)
	if sb_fired and sb_unit.get_effective_stat("skill") == sb_data.skill + 2:
		print("OK  M9a stat_bonus adds a combat stat modifier"); passed += 1
	else:
		print("FAIL M9a stat_bonus: fired=%s skill=%d base=%d" \
			% [sb_fired, sb_unit.get_effective_stat("skill"), sb_data.skill]); failed += 1

	# ── M9a: prescience gives +15 hit/dodge only on initiation ───────────────
	var prescience: SkillData = load("res://data/skills/prescience.tres")
	var pre_ctx: Dictionary = _make_ctx(unit, def_unit, iron_lance, iron_lance)
	var pre_fired: bool = sh._execute_skill(prescience, unit, pre_ctx)
	if pre_fired and pre_ctx["atk_mod"]["accuracy"] == 15 and pre_ctx["atk_mod"]["dodge"] == 15:
		print("OK  M9a prescience buffs the initiator"); passed += 1
	else:
		print("FAIL M9a prescience atk_mod=%s fired=%s" % [str(pre_ctx["atk_mod"]), pre_fired]); failed += 1
	var pre_ctx2: Dictionary = _make_ctx(def_unit, unit, iron_lance, iron_lance)
	var pre_fired2: bool = sh._execute_skill(prescience, unit, pre_ctx2)
	if not pre_fired2 and pre_ctx2["def_mod"]["accuracy"] == 0 and pre_ctx2["def_mod"]["dodge"] == 0:
		print("OK  M9a prescience stays inactive on defense"); passed += 1
	else:
		print("FAIL M9a prescience defended: def_mod=%s fired=%s" % [str(pre_ctx2["def_mod"]), pre_fired2]); failed += 1

	# ── M9a: patience gives +10 hit/dodge only while defending ───────────────
	var patience: SkillData = load("res://data/skills/patience.tres")
	var pat_ctx: Dictionary = _make_ctx(unit, def_unit, iron_lance, iron_lance)
	var pat_fired: bool = sh._execute_skill(patience, def_unit, pat_ctx)
	if pat_fired and pat_ctx["def_mod"]["accuracy"] == 10 and pat_ctx["def_mod"]["dodge"] == 10:
		print("OK  M9a patience buffs the defender"); passed += 1
	else:
		print("FAIL M9a patience def_mod=%s fired=%s" % [str(pat_ctx["def_mod"]), pat_fired]); failed += 1

	# ── M9a: focus grants crit only when no ally is nearby ────────────────────
	var focus_skill: SkillData = load("res://data/skills/focus.tres")
	var focus_data: UnitData = soldier_data.duplicate(true)
	var focus_unit := MockUnit.new()
	focus_unit.setup(focus_data)
	focus_unit.tile_position = Vector2i(5, 5)
	root.add_child(focus_unit)
	gs.all_units = [focus_unit]
	var focus_ctx: Dictionary = _make_ctx(focus_unit, def_unit, iron_lance, iron_lance)
	var focus_fired: bool = sh._execute_skill(focus_skill, focus_unit, focus_ctx)
	if focus_fired and focus_ctx["atk_mod"]["crit"] == 10:
		print("OK  M9a focus grants crit when no ally is within range"); passed += 1
	else:
		print("FAIL M9a focus solo atk_mod=%s fired=%s" % [str(focus_ctx["atk_mod"]), focus_fired]); failed += 1
	var ally_unit := MockUnit.new()
	ally_unit.setup(soldier_data.duplicate(true))
	ally_unit.tile_position = Vector2i(6, 5)
	root.add_child(ally_unit)
	gs.all_units = [focus_unit, ally_unit]
	var focus_ctx2: Dictionary = _make_ctx(focus_unit, def_unit, iron_lance, iron_lance)
	var focus_fired2: bool = sh._execute_skill(focus_skill, focus_unit, focus_ctx2)
	if not focus_fired2 and focus_ctx2["atk_mod"]["crit"] == 0:
		print("OK  M9a focus stays off when an ally is nearby"); passed += 1
	else:
		print("FAIL M9a focus ally atk_mod=%s fired=%s" % [str(focus_ctx2["atk_mod"]), focus_fired2]); failed += 1

	# ── M9a helpers: discipline and healtouch expose runtime bonuses ─────────
	var helper_data: UnitData = soldier_data.duplicate(true)
	helper_data.skills = ["discipline", "healtouch"]
	var helper_unit := MockUnit.new()
	helper_unit.setup(helper_data)
	root.add_child(helper_unit)
	var wexp_mult: int = sh.get_wexp_multiplier(helper_unit, "lance")
	var heal_bonus: int = sh.get_staff_heal_bonus(helper_unit)
	if wexp_mult == 2 and heal_bonus == 5:
		print("OK  M9a helpers expose discipline/healtouch bonuses"); passed += 1
	else:
		print("FAIL M9a helpers: wexp=%d heal=%d" % [wexp_mult, heal_bonus]); failed += 1

	# ── #4: max_uses_per_combat caps how often a skill fires within one combat ──
	# Give lancefaire a 1-use-per-combat limit, then fire on_combat_start twice with
	# reset_combat_uses() simulating a single combat: the second call must be skipped.
	var faire_data: SkillData = dm.get_skill("lancefaire")
	var saved_limit: int = faire_data.max_uses_per_combat
	faire_data.max_uses_per_combat = 1
	var combo_unit := MockUnit.new()
	combo_unit.setup(soldier_data.duplicate(true))
	combo_unit.data.skills.assign(["lancefaire"])
	root.add_child(combo_unit)
	sh.reset_combat_uses()
	var combo_ctx: Dictionary = _make_ctx(combo_unit, def_unit, iron_lance, iron_lance)
	combo_ctx["attacker"] = combo_unit
	sh.apply_trigger(combo_unit, "on_combat_start", combo_ctx)
	var dmg_after_one: int = combo_ctx["atk_mod"]["damage"]
	sh.apply_trigger(combo_unit, "on_combat_start", combo_ctx)
	var dmg_after_two: int = combo_ctx["atk_mod"]["damage"]
	if dmg_after_one > 0 and dmg_after_two == dmg_after_one:
		print("OK  #4: max_uses_per_combat blocks the second activation"); passed += 1
	else:
		print("FAIL #4: faire fired twice (%d → %d)" % [dmg_after_one, dmg_after_two]); failed += 1
	# reset_combat_uses() scopes the limit to one combat — a fresh combat fires again.
	sh.reset_combat_uses()
	sh.apply_trigger(combo_unit, "on_combat_start", combo_ctx)
	if combo_ctx["atk_mod"]["damage"] > dmg_after_two:
		print("OK  #4: reset_combat_uses re-arms the skill for the next combat"); passed += 1
	else:
		print("FAIL #4: skill did not re-arm after reset_combat_uses"); failed += 1
	faire_data.max_uses_per_combat = saved_limit  # restore shared resource

	# ── 2.6: counters key by skill.id, not effect_id ──────────────────────────
	# Two stat_bonus skills (skill_plus_2 and defense_plus_2) share an
	# effect_id but have distinct skill ids. Pre-2026-06-10 they shared a
	# single max_uses_per_combat counter, so capping at 1 silently silenced
	# the second one. Keying by skill.id keeps them isolated.
	var skl_plus: SkillData = dm.get_skill("skill_plus_2")
	var def_plus: SkillData = dm.get_skill("defense_plus_2")
	var saved_skl_limit: int = skl_plus.max_uses_per_combat
	var saved_def_limit: int = def_plus.max_uses_per_combat
	skl_plus.max_uses_per_combat = 1
	def_plus.max_uses_per_combat = 1
	var iso_unit := MockUnit.new()
	iso_unit.setup(soldier_data.duplicate(true))
	iso_unit.data.skills.assign(["skill_plus_2", "defense_plus_2"])
	root.add_child(iso_unit)
	sh.reset_combat_uses()
	var iso_ctx: Dictionary = _make_ctx(iso_unit, def_unit, iron_lance, iron_lance)
	iso_ctx["attacker"] = iso_unit
	sh.apply_trigger(iso_unit, "on_combat_start", iso_ctx)
	# Both stat_bonus skills are duration_type="combat" modifiers on the unit's
	# active_modifiers — count distinct sources.
	var distinct_sources: Dictionary = {}
	for m in iso_unit.data.active_modifiers:
		if String(m.get("source", "")).begins_with("skill:"):
			distinct_sources[String(m["source"])] = true
	if distinct_sources.size() == 2:
		print("OK  2.6: skills sharing effect_id keep isolated use counters"); passed += 1
	else:
		print("FAIL 2.6: shared-effect-id skill counter collision (%d sources)" % \
			distinct_sources.size()); failed += 1
	skl_plus.max_uses_per_combat = saved_skl_limit
	def_plus.max_uses_per_combat = saved_def_limit

	# ── ItemHandler: heal_flat heals and decrements uses ──────────────────────
	# max_hp leaves headroom so the full heal is observable (no cap clamp here):
	# the Vulnerary restores exactly 10 HP (#14), down from the old 20.
	var vuln_data: UnitData = soldier_data.duplicate(true)
	vuln_data.hp = 10
	vuln_data.max_hp = 30
	var vuln_unit := MockUnit.new()
	vuln_unit.setup(vuln_data)
	root.add_child(vuln_unit)
	var vuln_entry := InventoryEntry.make_item("vulnerary", 3)
	vuln_data.inventory = [vuln_entry]
	ih.apply_item(vuln_unit, vuln_entry)
	if vuln_data.hp == 20:
		print("OK  vulnerary heals exactly 10 HP (#14)"); passed += 1
	else:
		print("FAIL vulnerary: expected 20 HP, got %d" % vuln_data.hp); failed += 1
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

	# ── M6.4: promotion-item restrictions by exact class and class group ─────
	var archer_data: UnitData = load("res://data/roster/default/unit_03_archer.tres").duplicate(true)
	archer_data.level = 20
	var archer_unit := MockUnit.new()
	archer_unit.setup(archer_data)
	archer_unit.second_seal_usable = true
	root.add_child(archer_unit)
	var mage_data: UnitData = load("res://data/roster/default/unit_04_mage.tres").duplicate(true)
	mage_data.level = 20
	var mage_unit := MockUnit.new()
	mage_unit.setup(mage_data)
	mage_unit.second_seal_usable = true
	root.add_child(mage_unit)
	var merc_data: UnitData = load("res://data/roster/default/unit_02_mercenary.tres").duplicate(true)
	merc_data.level = 20
	var merc_unit := MockUnit.new()
	merc_unit.setup(merc_data)
	merc_unit.second_seal_usable = false
	root.add_child(merc_unit)
	var orion_entry := InventoryEntry.make_item("orion_bolt", 1)
	var ring_entry := InventoryEntry.make_item("guiding_ring", 1)
	if ih.can_apply_item(archer_unit, orion_entry) and not ih.can_apply_item(merc_unit, orion_entry):
		print("OK  M6.4: allowed_classes restrict a promotion item to exact classes"); passed += 1
	else:
		print("FAIL M6.4 allowed_classes: archer=%s merc=%s" % [
			ih.can_apply_item(archer_unit, orion_entry), ih.can_apply_item(merc_unit, orion_entry)]); failed += 1
	if ih.can_apply_item(mage_unit, ring_entry) and not ih.can_apply_item(merc_unit, ring_entry):
		print("OK  M6.4: allowed_class_groups restrict a promotion item by class group"); passed += 1
	else:
		print("FAIL M6.4 allowed_class_groups: mage=%s merc=%s" % [
			ih.can_apply_item(mage_unit, ring_entry), ih.can_apply_item(merc_unit, ring_entry)]); failed += 1
	var second_entry := InventoryEntry.make_item("second_seal", 1)
	if ih.can_apply_item(archer_unit, second_entry) and not ih.can_apply_item(merc_unit, second_entry):
		print("OK  M7.4: Second Seal usability follows unit.can_use_second_seal()"); passed += 1
	else:
		print("FAIL M7.4 second_seal: archer=%s merc=%s" % [
			ih.can_apply_item(archer_unit, second_entry), ih.can_apply_item(merc_unit, second_entry)]); failed += 1

	# W5c regression — strength_tonic is a fixture item with effect_id "stat_buff"
	# that lets playtesters verify the unit-details modifier block and combat
	# preview against a reliable positive modifier. apply_item must stamp an
	# active_modifier from ItemData.effect_params and consume the entry.
	var tonic_entry := InventoryEntry.make_item("strength_tonic", 1)
	var tonic_data: UnitData = load("res://data/roster/default/unit_02_mercenary.tres").duplicate(true)
	tonic_data.inventory = [tonic_entry]
	tonic_data.active_modifiers = []
	var tonic_unit := MockUnit.new()
	tonic_unit.setup(tonic_data)
	root.add_child(tonic_unit)
	var tonic_usable: bool = ih.can_apply_item(tonic_unit, tonic_entry)
	ih.apply_item(tonic_unit, tonic_entry)
	var matched: int = 0
	for mod in tonic_data.active_modifiers:
		if mod.get("stat", "") == "strength" and int(mod.get("delta", 0)) == 4 \
				and String(mod.get("source", "")).begins_with("item:") \
				and String(mod.get("duration_type", "")) == "turn":
			matched += 1
	if tonic_usable and matched == 1 and tonic_data.inventory.is_empty():
		print("OK  W5c: strength_tonic applies a +4 strength turn modifier and is consumed"); passed += 1
	else:
		print("FAIL W5c: usable=%s matched=%d inv=%d mods=%s" % [
			tonic_usable, matched, tonic_data.inventory.size(), tonic_data.active_modifiers]); failed += 1

	# V020-14 — debuff_tonic is a Map 950 validation item: a stat_buff with a
	# NEGATIVE delta so testers can confirm lowered stats render in red. Verify it
	# stamps a -4 strength modifier and is consumed, same path as strength_tonic.
	var debuff_entry := InventoryEntry.make_item("debuff_tonic", 1)
	var debuff_data: UnitData = load("res://data/roster/default/unit_02_mercenary.tres").duplicate(true)
	debuff_data.inventory = [debuff_entry]
	debuff_data.active_modifiers = []
	var debuff_unit := MockUnit.new()
	debuff_unit.setup(debuff_data)
	root.add_child(debuff_unit)
	var debuff_usable: bool = ih.can_apply_item(debuff_unit, debuff_entry)
	ih.apply_item(debuff_unit, debuff_entry)
	var debuff_matched: int = 0
	for mod in debuff_data.active_modifiers:
		if mod.get("stat", "") == "strength" and int(mod.get("delta", 0)) == -4 \
				and String(mod.get("source", "")).begins_with("item:") \
				and String(mod.get("duration_type", "")) == "turn":
			debuff_matched += 1
	if debuff_usable and debuff_matched == 1 and debuff_data.inventory.is_empty():
		print("OK  V020-14: debuff_tonic applies a -4 strength turn modifier and is consumed"); passed += 1
	else:
		print("FAIL V020-14: usable=%s matched=%d inv=%d mods=%s" % [
			debuff_usable, debuff_matched, debuff_data.inventory.size(), debuff_data.active_modifiers]); failed += 1

	# W3b regression — playtest #214: a unit that started below max level with a
	# promotion item in inventory should become eligible as soon as it hits the
	# class max. can_apply_item must reflect the live data.level so the next
	# action-menu open reveals the seal.
	var refresh_data: UnitData = load("res://data/roster/default/unit_06_knight.tres").duplicate(true)
	refresh_data.level = 18
	refresh_data.is_promoted = false
	var refresh_unit := MockUnit.new()
	refresh_unit.setup(refresh_data)
	refresh_unit.second_seal_usable = false
	root.add_child(refresh_unit)
	var seal_entry := InventoryEntry.make_item("master_seal", 1)
	var hidden_at_18: bool = not ih.can_apply_item(refresh_unit, seal_entry)
	refresh_data.level = 19
	var hidden_at_19: bool = not ih.can_apply_item(refresh_unit, seal_entry)
	refresh_data.level = 20
	var usable_at_20: bool = ih.can_apply_item(refresh_unit, seal_entry)
	if hidden_at_18 and hidden_at_19 and usable_at_20:
		print("OK  W3b: promotion-item usability refreshes the instant a unit hits max level"); passed += 1
	else:
		print("FAIL W3b promotion refresh: 18=%s 19=%s 20=%s" % [
			hidden_at_18, hidden_at_19, usable_at_20]); failed += 1

	# ---- stub appliers warn once per skill id, not every combat (log-noise fix) ----
	# Guards against the v0.1.4 godot.log flood (armsthrift ×80 etc.). _warn_stub_once
	# records each skill id once; repeats are suppressed.
	sh._stub_warned.clear()
	sh._warn_stub_once("Test._stub", "armsthrift")
	sh._warn_stub_once("Test._stub", "armsthrift")   # repeat — must not re-record
	sh._warn_stub_once("Test._stub", "dash")
	if sh._stub_warned.size() == 2 and sh._stub_warned.has("armsthrift") and sh._stub_warned.has("dash"):
		print("OK  stub appliers warn once per skill id (repeats suppressed)"); passed += 1
	else:
		print("FAIL stub warn dedupe: %s" % sh._stub_warned); failed += 1

	# ── B1-PKGA Slice 1c: activation rolls draw from the event RNG (RNG-1) ────
	# Miracle (LUK% proc on on_damaged) is the only activation_chance_stat skill
	# today; apply_trigger must roll it from context["rng"] and refuse to roll at
	# all when a non-preview path forgot to begin an RNG event.
	var svc: Node = load("res://scripts/autoloads/RngService.gd").new()
	svc.name = "RngService"
	root.add_child(svc)
	var mir_data: UnitData = soldier_data.duplicate(true)
	mir_data.skills.assign(["miracle"])
	mir_data.luck = 50
	var mir_unit := MockUnit.new()
	mir_unit.setup(mir_data)
	root.add_child(mir_unit)
	svc.start_map(9001)
	var mir_rec: Array[String] = ["mir", "1,1", "1,1", "e9"]

	# Identical event seed → identical activation outcome (fixed-seed determinism).
	var mir_ctx_a := {"damage": 20, "current_sim_hp": 10, "unit": mir_unit,
		"rng": svc.begin_event("attack", mir_rec)}
	sh.apply_trigger(mir_unit, "on_damaged", mir_ctx_a)
	var mir_ctx_b := {"damage": 20, "current_sim_hp": 10, "unit": mir_unit,
		"rng": svc.begin_event("attack", mir_rec)}
	sh.apply_trigger(mir_unit, "on_damaged", mir_ctx_b)
	var mir_valid: bool = mir_ctx_a["damage"] == 9 or mir_ctx_a["damage"] == 20
	if mir_ctx_a["damage"] == mir_ctx_b["damage"] and mir_valid:
		print("OK  1c: activation roll is deterministic under a fixed event seed"); passed += 1
	else:
		print("FAIL 1c determinism: %s vs %s" % [mir_ctx_a["damage"], mir_ctx_b["damage"]]); failed += 1

	# Missing context["rng"] on a live path: loud fail, NO activation — even at
	# chance 100, where a silent raw-RNG fallback would always have fired.
	mir_unit.data.luck = 100
	var mir_ctx_c := {"damage": 20, "current_sim_hp": 10, "unit": mir_unit}
	sh.apply_trigger(mir_unit, "on_damaged", mir_ctx_c)  # pushes an error by design
	if mir_ctx_c["damage"] == 20:
		print("OK  1c: missing event RNG fails loudly and never falls back to raw RNG"); passed += 1
	else:
		print("FAIL 1c loud-fail: skill activated without an event RNG"); failed += 1

	# Same chance-100 proc WITH the event RNG present always fires.
	var mir_ctx_d := {"damage": 20, "current_sim_hp": 10, "unit": mir_unit,
		"rng": svc.begin_event("attack", mir_rec)}
	sh.apply_trigger(mir_unit, "on_damaged", mir_ctx_d)
	if mir_ctx_d["damage"] == 9:
		print("OK  1c: chance-100 activation fires from the event RNG"); passed += 1
	else:
		print("FAIL 1c chance-100: damage=%s (want 9)" % mir_ctx_d["damage"]); failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
