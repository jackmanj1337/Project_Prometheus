class_name Unit extends Node2D
# A single unit on the battlefield. Wraps a UnitData resource and provides
# combat math, movement, and visual state.
#
# Responsibilities are split:
#   - This file: identity, position, HP/state changes, movement animation
#   - UnitStatBlock.gd (helper): stat math that factors in terrain, S-rank, conditions

# Set by initialize()
var data: UnitData
# Pass-through to data.tile_position so callers use unit.tile_position unchanged.
var tile_position: Vector2i:
	get: return data.tile_position if data else Vector2i.ZERO
	set(val):
		if data:
			data.tile_position = val
var team: String = "player"  # "player" | "enemy"

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _hp_bar: ProgressBar = $HPBar
var _grid_manager: GridManager = null  # cached on first use
var _base_modulate: Color = Color.WHITE  # set in _apply_initial_state; used by set_done_appearance


# Called by GameMap right after scene instancing. Must be invoked before _ready
# can finish using the data, so the spawner uses call_deferred carefully or sets
# the values before adding to the tree.
# Call this before add_child(). _ready() then fires _apply_initial_state() once nodes exist.
func initialize(unit_data: UnitData, start_tile: Vector2i, unit_team: String) -> void:
	data = unit_data
	tile_position = start_tile
	team = unit_team


# Called by GameMap after spawning to avoid per-call tree walks in combat calculations.
func set_grid_manager(grid: GridManager) -> void:
	_grid_manager = grid


func _ready() -> void:
	if data != null:
		_apply_initial_state()


# Sets sprite tint, HP bar, and world position. Idempotent.
func _apply_initial_state() -> void:
	if _sprite == null or _hp_bar == null:
		return
	# Player units render in blue tint, enemies in red tint (placeholder visuals).
	# When real sprites land we use class_id for sprite selection instead.
	if team == "enemy":
		_base_modulate = Color(0.95, 0.35, 0.35, 1.0)
	else:
		_base_modulate = Color(0.30, 0.55, 0.95, 1.0)
	_sprite.modulate = _base_modulate
	_hp_bar.max_value = data.max_hp
	_hp_bar.value = data.hp
	# Snap world position to tile (TILE_SIZE px per tile)
	position = Vector2(tile_position.x * GameConstants.TILE_SIZE,
		tile_position.y * GameConstants.TILE_SIZE)


# True if the unit's class has the given quality (per ClassData.special_qualities)
# OR the unit has been granted it via skill/item. For MVP only class qualities apply.
# [DEFERRED — Laguz] Beast and Laguz qualities are marked "*" (animal form only) in
# the GDD. This method does not check is_shifted, so effectiveness checks against
# "beast" or "dragon" will incorrectly fire in humanoid form. Fix when Laguz shift
# mechanics are fully implemented.
func has_quality(quality: String) -> bool:
	if data == null:
		return false
	var class_data := _get_class_data()
	if class_data == null:
		return false
	return quality in class_data.special_qualities


func _get_class_data() -> ClassData:
	if data == null:
		return null
	if is_inside_tree():
		var dm := get_node_or_null("/root/DataManager")
		if dm:
			return dm.get_class_data(data.class_id)
	return null


# Returns [InventoryEntry, WeaponData] for the first usable equipped weapon, or []
# if none. Single inventory pass, single DataManager lookup — avoids double-lookup.
func _find_equipped_weapon() -> Array:
	if data == null:
		return []
	for entry in data.inventory:
		if not entry.is_weapon() or not entry.has_uses():
			continue
		var weapon := _load_weapon(entry.weapon_id)
		if weapon == null or not _can_equip_rank(weapon):
			continue
		return [entry, weapon]
	return []


func get_equipped_weapon() -> WeaponData:
	var pair := _find_equipped_weapon()
	return pair[1] if pair.size() == 2 else null


# Returns the InventoryEntry for callers that need to decrement uses or read forge mods.
func get_equipped_weapon_entry() -> InventoryEntry:
	var pair := _find_equipped_weapon()
	return pair[0] if pair.size() == 2 else null


func _load_weapon(id: String) -> WeaponData:
	if is_inside_tree():
		var dm := get_node_or_null("/root/DataManager")
		if dm:
			return dm.get_weapon(id)
	return null


# Rank order: E < D < C < B < A < S (small lookup map)
const _RANK_ORDER := {"E": 0, "D": 1, "C": 2, "B": 3, "A": 4, "S": 5}


func _can_equip_rank(weapon: WeaponData) -> bool:
	if not data.proficiencies.has(weapon.weapon_type):
		return false
	var unit_rank: String = data.proficiencies[weapon.weapon_type].get("rank", "E")
	return _RANK_ORDER.get(unit_rank, 0) >= _RANK_ORDER.get(weapon.rank, 0)


# Reads terrain bonuses from GridManager; only applies when this unit is the
# defender in combat (per GDD_02).
func get_terrain_def_bonus() -> int:
	var grid := _get_grid_manager()
	if grid == null:
		return 0
	var terrain := grid.get_terrain_at(tile_position)
	return GridManager.TERRAIN_DEF_BONUS.get(terrain, 0)


func get_terrain_dodge_bonus() -> int:
	var grid := _get_grid_manager()
	if grid == null:
		return 0
	var terrain := grid.get_terrain_at(tile_position)
	return GridManager.TERRAIN_DODGE_BONUS.get(terrain, 0)


func _get_grid_manager() -> GridManager:
	if _grid_manager != null and is_instance_valid(_grid_manager):
		return _grid_manager
	if not is_inside_tree():
		return null
	var n := get_parent()
	while n:
		var g := n.get_node_or_null("GridManager")
		if g and g is GridManager:
			_grid_manager = g
			return _grid_manager
		n = n.get_parent()
	return null


# ---- Stat Access (modifier-aware) ----

# Returns the base stat value plus the sum of all active_modifiers that target
# stat_name. stat_name must match a UnitData property name exactly (e.g. "strength",
# "magic", "speed"). Result is clamped to 0 minimum so negative modifiers can't go below zero.
func get_effective_stat(stat_name: String) -> int:
	if data == null:
		return 0
	var base = data.get(stat_name)
	var total: int = int(base) if base != null else 0
	for mod in data.active_modifiers:
		if mod["stat"] == stat_name:
			total += mod["delta"]
	return max(0, total)


# Returns true if the unit has the given skill effect_id in their skills list.
func has_skill(skill_id: String) -> bool:
	if data == null:
		return false
	return skill_id in data.skills


# Returns how many uses of this skill remain this map. -1 = unlimited.
func get_skill_uses_remaining(effect_id: String, max_per_map: int) -> int:
	if max_per_map == -1:
		return -1
	var used: int = data.skill_use_counters.get(effect_id, 0)
	return max(0, max_per_map - used)


func consume_skill_use(effect_id: String) -> void:
	data.skill_use_counters[effect_id] = data.skill_use_counters.get(effect_id, 0) + 1


# ---- Modifier Lifecycle ----

# Adds a temporary stat modifier. Replaces any existing modifier from the same source
# so re-applying the same skill refreshes duration rather than stacking.
# duration_type: "turn" decrements at this unit's turn start; "map_turn" at top of
# player phase; "combat" cleared after each combat; "permanent" never auto-removed.
# duration = -1 also means never auto-removed.
func add_modifier(stat: String, delta: int, source: String,
		duration: int, duration_type: String) -> void:
	remove_modifier(source)
	data.active_modifiers.append({
		"stat": stat, "delta": delta, "source": source,
		"duration": duration, "duration_type": duration_type
	})


# Removes all modifiers whose source matches (e.g. on condition cure, on unshift).
func remove_modifier(source: String) -> void:
	data.active_modifiers = data.active_modifiers.filter(
		func(m): return m["source"] != source
	)


# Decrements modifiers of the given duration_type and removes those that hit 0.
# Called by TurnManager: "turn" at unit's own turn start; "map_turn" once per round.
func tick_modifiers(duration_type: String) -> void:
	for mod in data.active_modifiers:
		if mod["duration_type"] == duration_type and mod["duration"] > 0:
			mod["duration"] -= 1
	data.active_modifiers = data.active_modifiers.filter(
		func(m): return m["duration"] != 0
	)


# Removes modifiers with duration_type "combat". Called by CombatResolver after each
# combat resolves so one-fight buffs don't carry over.
func clear_combat_modifiers() -> void:
	data.active_modifiers = data.active_modifiers.filter(
		func(m): return m["duration_type"] != "combat"
	)


# Resets all per-map runtime state. Call before GameState.take_map_snapshot() so
# the snapshot captures a clean slate, not carry-over from a previous map.
func reset_map_state() -> void:
	data.active_modifiers.clear()
	data.skill_use_counters.clear()
	data.damage_taken_this_map = 0


# ---- Combat Stats ----
# All formulas from GDD_02. Each accepts an optional weapon override so callers
# can preview "what if I equip X instead." Default = currently equipped weapon.
# All reads go through get_effective_stat() so active modifiers are included.

func _weapon_or_equipped(weapon: WeaponData) -> WeaponData:
	return weapon if weapon != null else get_equipped_weapon()


# Battle Speed = SPD - max(0, Wt - STR)
func battle_speed(weapon: WeaponData = null) -> int:
	var w := _weapon_or_equipped(weapon)
	if w == null:
		return get_effective_stat("speed")
	var penalty: int = max(0, w.wt - get_effective_stat("strength"))
	return get_effective_stat("speed") - penalty


# Accuracy = SKL*2 + LUK + weapon.Hit. S-rank bonus applied via s_rank_mastery skill at combat time.
func accuracy(weapon: WeaponData = null) -> int:
	var w := _weapon_or_equipped(weapon)
	var acc: int = get_effective_stat("skill") * 2 + get_effective_stat("luck")
	if w != null:
		acc += w.hit
	return acc


# Dodge = Battle Speed * 2 + LUK (+ terrain dodge bonus, applied at combat time)
func dodge(weapon: WeaponData = null) -> int:
	return battle_speed(weapon) * 2 + get_effective_stat("luck")


# Critical rate = floor(SKL/2) + weapon.Crit. S-rank bonus applied via s_rank_mastery skill.
func crit_rate(weapon: WeaponData = null) -> int:
	var w := _weapon_or_equipped(weapon)
	var c: int = get_effective_stat("skill") / 2
	if w != null:
		c += w.crit
	return c


# Crit Avoid = LUK
func crit_avoid() -> int:
	return get_effective_stat("luck")


# ---- HP / Death ----

# Safe EventBus accessor; returns null in tests where the autoload isn't live
func _bus() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/EventBus")
	return null


# Decrements HP (clamped to 0), updates the bar, and emits unit_damaged.
# Does NOT trigger handle_death; CombatResolver decides when death checks happen.
func take_damage(amount: int) -> void:
	if data == null or amount <= 0:
		return
	data.hp = max(0, data.hp - amount)
	if _hp_bar:
		_hp_bar.value = data.hp
	var bus := _bus()
	if bus:
		bus.unit_damaged.emit(self, amount)


# Increments HP (clamped to max_hp), updates the bar, and emits unit_healed.
func heal(amount: int) -> void:
	if data == null or amount <= 0:
		return
	data.hp = min(data.max_hp, data.hp + amount)
	if _hp_bar:
		_hp_bar.value = data.hp
	var bus := _bus()
	if bus:
		bus.unit_healed.emit(self, amount)


# Shared staff-heal logic used by both MapCursor (player) and EnemyAI.
# `weapon` must be captured by the caller BEFORE calling this — use_weapon_durability
# may remove the last-use entry, making get_equipped_weapon() return null afterward.
func perform_staff_heal(target: Node, weapon: WeaponData) -> void:
	var heal_amount: int = GameConstants.STAFF_HEAL_BASE + data.magic
	target.heal(heal_amount)
	use_weapon_durability(weapon.id)
	add_wexp(weapon.weapon_type, weapon.wexp)
	add_exp(GameConstants.STAFF_HEAL_EXP)


# Called when HP reaches 0. If permadeath is on (per GameState), flags the
# UnitData as incapacitated so the unit cannot be redeployed; otherwise the
# data is preserved for the next map. Either way the scene node is freed.
func handle_death() -> void:
	if data == null:
		return
	var gs := get_node_or_null("/root/GameState") if is_inside_tree() else null
	if gs:
		if gs.permadeath_enabled:
			data.is_incapacitated = true
		gs.unregister_unit(self)
	var bus := _bus()
	if bus:
		bus.unit_died.emit(self)
	queue_free()


# ---- Inventory / Durability ----

# Decrements uses on the weapon matching weapon_id. Pass the id captured before
# combat starts so a mid-combat break can't bleed into the next weapon in inventory.
# Returns true if the entry was removed (weapon broke), false otherwise.
# Omit weapon_id to fall back to "first usable weapon" for non-combat callers.
func use_weapon_durability(weapon_id: String = "") -> bool:
	if data == null:
		return false
	for i in data.inventory.size():
		var entry: InventoryEntry = data.inventory[i]
		if not entry.is_weapon():
			continue
		if weapon_id != "" and entry.weapon_id != weapon_id:
			continue
		if not entry.has_uses():
			continue
		if entry.uses_remaining == -1:
			return false  # infinite-use weapon: never decrements, never breaks
		entry.uses_remaining -= 1
		if entry.uses_remaining <= 0:
			data.inventory.remove_at(i)
			return true
		return false
	return false


# Whether the unit's proficiency in this weapon's type allows equipping it.
# Same logic as the rank check inside get_equipped_weapon_entry but exposed
# so callers (e.g. trade UI) can preview equip eligibility.
func can_equip(weapon_data: WeaponData) -> bool:
	if data == null or weapon_data == null:
		return false
	return _can_equip_rank(weapon_data)


# ---- Movement / Visuals ----

# Animates this unit along the path (Vector2i tile list) using a Tween. The
# first tile in path should be the starting tile and is skipped. Per-tile
# duration comes from SettingsManager so the player can change movement speed
# without code changes. Emits unit_moved on completion. await this call to
# block until movement finishes.
func move_along_path(path: Array[Vector2i]) -> void:
	if path.size() <= 1:
		return
	var origin: Vector2i = tile_position
	var seconds_per_tile := _get_per_tile_seconds()
	# "Instant" speed: no tween, just snap to the destination
	if seconds_per_tile <= 0.0:
		snap_to_tile(path[-1])
		_emit_moved(origin, path[-1])
		return
	# Update logical position before animation so grid queries are never stale mid-tween.
	tile_position = path[-1]
	var tween := create_tween()
	# Each tile is one tween segment; chain them sequentially
	for i in range(1, path.size()):
		var dest_world := Vector2(path[i].x * GameConstants.TILE_SIZE,
			path[i].y * GameConstants.TILE_SIZE)
		tween.tween_property(self, "position", dest_world, seconds_per_tile)
	await tween.finished
	_emit_moved(origin, tile_position)


func _get_per_tile_seconds() -> float:
	if is_inside_tree():
		var sm := get_node_or_null("/root/SettingsManager")
		if sm:
			return sm.get_movement_speed_seconds()
	return 0.12  # default


func _emit_moved(from_tile: Vector2i, to_tile: Vector2i) -> void:
	var bus := _bus()
	if bus:
		bus.unit_moved.emit(self, from_tile, to_tile)


# Instant position change. Used by AI when animations are off and by undo_move.
func snap_to_tile(tile: Vector2i) -> void:
	tile_position = tile
	position = Vector2(tile.x * GameConstants.TILE_SIZE,
		tile.y * GameConstants.TILE_SIZE)


# Visual state for "this unit has acted this turn" (DONE in TurnManager).
# Uses sprite modulate to darken; restored each new player phase.
func set_done_appearance() -> void:
	if _sprite:
		_sprite.modulate = _base_modulate.darkened(GameConstants.DONE_APPEARANCE_DARKEN)


func reset_appearance() -> void:
	if _sprite == null:
		return
	# Restore the team color (set in _apply_initial_state)
	_apply_initial_state()


# ---- Progression ----

# Adds EXP; triggers level_up() and carries overflow when crossing 100.
# Handles the case where a single combat awards more than 100 EXP (multiple
# level-ups queued in sequence).
func add_exp(amount: int) -> void:
	if data == null or amount <= 0:
		return
	if data.level >= GameConstants.MAX_LEVEL:
		return  # EXP discarded at cap; promotion (Phase 2) will unlock further levelling
	data.exp += amount
	while data.exp >= 100:
		data.exp -= 100
		level_up()
		if data.level >= GameConstants.MAX_LEVEL:
			data.exp = 0  # no overflow past the cap
			break


# Rolls stat increases per the unit's class growth rates and applies them.
# Two methods: growth_random (RNG-based, rate > 100 gives guaranteed gains)
# and growth_fixed (deterministic accumulator, always predictable progression).
# Emits unit_leveled_up with the dictionary of changes for the level-up screen.
const _GROWTH_STATS := ["hp", "strength", "magic", "defense", "resistance", "skill", "speed", "luck"]

func level_up() -> void:
	if data == null:
		return
	data.level += 1
	data.effective_level += 1
	var gs := get_node_or_null("/root/GameState") if is_inside_tree() else null
	var method: String = gs.leveling_method if gs else "growth_random"
	var class_data := _get_class_data()
	if class_data == null:
		return
	var rates: Dictionary = class_data.growth_rates
	var changes: Dictionary = {}
	match method:
		"growth_fixed":
			changes = _level_up_fixed(rates)
		_:  # "growth_random" and any unknown value
			changes = _level_up_random(rates)
	var bus := _bus()
	if bus:
		bus.unit_leveled_up.emit(self, changes)


# Probabilistic: rate 75 = 75% chance of +1. Rate 150 = +1 guaranteed, 50% chance of +2.
func _level_up_random(rates: Dictionary) -> Dictionary:
	var changes: Dictionary = {}
	for stat in _GROWTH_STATS:
		var rate: int = int(rates.get(stat, 0))
		var guaranteed: int = rate / 100
		var remainder: int  = rate % 100
		var gain: int = guaranteed + (1 if (randi() % 100) < remainder else 0)
		if gain > 0:
			for _i in gain:
				_increment_stat(stat)
			changes[stat] = gain
	return changes


# Deterministic: accumulates rate each level; +1 per full 100 accumulated.
# Carry persists in data.growth_accumulators so gains are perfectly predictable.
# Rate 50 → +1 every 2 levels exactly. Rate 150 → +1 every level, +1 extra every other.
func _level_up_fixed(rates: Dictionary) -> Dictionary:
	var changes: Dictionary = {}
	for stat in _GROWTH_STATS:
		var rate: int = int(rates.get(stat, 0))
		var acc: int = int(data.growth_accumulators.get(stat, 0)) + rate
		var gain: int = acc / 100
		data.growth_accumulators[stat] = acc % 100
		if gain > 0:
			for _i in gain:
				_increment_stat(stat)
			changes[stat] = gain
	return changes


func _increment_stat(stat: String) -> void:
	match stat:
		"hp":
			data.max_hp += 1
			data.hp += 1  # current HP also increases on level up
		"strength": data.strength += 1
		"magic": data.magic += 1
		"defense": data.defense += 1
		"resistance": data.resistance += 1
		"skill": data.skill += 1
		"speed": data.speed += 1
		"luck": data.luck += 1


# Adds weapon EXP to the given proficiency, handling rank-up at 100. The unit
# must already have an entry for this weapon type (set at class creation).
# Returns true if a rank-up occurred.
func add_wexp(weapon_type: String, amount: int) -> bool:
	if data == null or amount <= 0:
		return false
	if not data.proficiencies.has(weapon_type):
		return false
	var prof: Dictionary = data.proficiencies[weapon_type]
	prof["wexp"] = prof.get("wexp", 0) + amount
	var ranked_up := false
	while prof["wexp"] >= 100:
		var current_rank: String = prof.get("rank", "E")
		var next_rank := _next_rank(current_rank)
		if next_rank == current_rank:
			# Already at S — cap wexp at 100
			prof["wexp"] = 100
			break
		prof["rank"] = next_rank
		prof["wexp"] -= 100
		ranked_up = true
		# Grant permanent mastery skill on first S-rank in any weapon type.
		if next_rank == "S" and not ("s_rank_mastery" in data.mastery_skills):
			data.mastery_skills.append("s_rank_mastery")
	data.proficiencies[weapon_type] = prof
	return ranked_up


func _next_rank(rank: String) -> String:
	const NEXT := {"E": "D", "D": "C", "C": "B", "B": "A", "A": "S", "S": "S"}
	return NEXT.get(rank, rank)
