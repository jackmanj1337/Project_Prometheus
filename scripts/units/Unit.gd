class_name Unit extends Node2D
# A single unit on the battlefield. Wraps a UnitData resource and provides
# combat math, movement, progression, and visual state. (Identity, position,
# HP/state, movement animation, the modifier-aware combat stats, and the
# reclass/second-seal state machine all live here.)

const GameConstants = preload("res://scripts/shared/GameConstants.gd")
const StatRegistry = preload("res://scripts/core/StatRegistry.gd")
const DeathContextScript = preload("res://scripts/death/DeathContext.gd")
const DeathResultScript = preload("res://scripts/death/DeathResult.gd")
const UnitSpriteResolver = preload("res://scripts/core/UnitSpriteFramesResolver.gd")

# Set by initialize()
var data: UnitData
# Pass-through to data.tile_position so callers use unit.tile_position unchanged.
var tile_position: Vector2i:
	get:
		return data.tile_position if data else Vector2i.ZERO
	set(val):
		if data:
			data.tile_position = val
var team: String = "blue"  # faction id (M14 stage 1) — "blue" (player), "red" (enemy); "green"/"yellow" land with stage-4/5 content

@onready var _sprite: AnimatedSprite2D = $Sprite2D
@onready var _hp_bar: ProgressBar = $HPBar
@onready var _pair_up_badge: Label = $PairUpBadge
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
		_ensure_class_line_id()
		_ensure_internal_level()
		_seed_earned_skills()
		_grant_current_level_class_skills()
		_apply_initial_state()
		_apply_active_pack_sprite()
	var bus := _bus()
	if (
		bus != null
		and bus.has_signal("pair_up_changed")
		and not bus.pair_up_changed.is_connected(_refresh_pair_up_badge)
	):
		bus.pair_up_changed.connect(_refresh_pair_up_badge)


# Sets sprite tint, HP bar, and world position. Idempotent.
func _apply_initial_state() -> void:
	if _sprite == null or _hp_bar == null:
		return
	# C3: use authored faction colours when map data provides them.
	_apply_faction_visual()
	_hp_bar.max_value = data.max_hp
	_hp_bar.value = data.hp
	# Snap world position to tile (TILE_SIZE px per tile)
	position = Vector2(
		tile_position.x * GameConstants.TILE_SIZE, tile_position.y * GameConstants.TILE_SIZE
	)
	_refresh_pair_up_badge()


# Installs a resolved class sprite while preserving the built-in placeholder when
# resolution fails. Asset loading remains the pack resolver's responsibility.
func set_sprite_frames(frames: SpriteFrames, preferred_animation: StringName = &"idle") -> void:
	if _sprite == null or frames == null:
		return
	_sprite.sprite_frames = frames
	if frames.has_animation(preferred_animation):
		_sprite.play(preferred_animation)
	elif frames.has_animation(&"default"):
		_sprite.play(&"default")
	else:
		var names := frames.get_animation_names()
		if not names.is_empty():
			_sprite.play(names[0])


# ClassData owns the normal sprite key. The empty value deliberately keeps the
# placeholder path first-class for incomplete or corrupted campaign packs.
func class_sprite_id() -> String:
	var class_data := _get_class_data()
	return class_data.sprite_id if class_data != null else ""


# Resolves against the one active pack after class identity is available. Missing or
# malformed optional art leaves the scene's built-in placeholder untouched.
func _apply_active_pack_sprite() -> void:
	var dm := get_node_or_null("/root/DataManager")
	if dm == null or not dm.has_method("pack_assets"):
		return
	apply_pack_sprite_asset(dm.call("pack_assets"))


# Public for the campaign-loader seam and headless tests; returns structured repair
# evidence so a future campaign repair UI can present failures without parsing logs.
func apply_pack_sprite_asset(assets: Dictionary) -> Dictionary:
	var result: Dictionary = UnitSpriteResolver.resolve(
		class_sprite_id(), assets, Vector2i(GameConstants.TILE_SIZE, GameConstants.TILE_SIZE)
	)
	var frames: SpriteFrames = result["sprite_frames"]
	if frames != null:
		set_sprite_frames(frames)
	for warning in result["warnings"]:
		push_warning(String(warning))
	for error in result["errors"]:
		push_warning(String(error))
	return result


# Applies the unit tint from MapData.factions when available; otherwise falls
# back to the legacy blue/red defaults.
func _apply_faction_visual(map_data: Resource = null) -> void:
	var color: Color = Color(0.95, 0.35, 0.35, 1.0)
	if team == "blue":
		color = Color(0.30, 0.55, 0.95, 1.0)
	var md: Resource = map_data
	if md == null:
		var gs := get_node_or_null("/root/GameState")
		if gs != null:
			md = gs.map_data
	if md != null:
		var faction: FactionData = md.get_faction(team)
		if faction != null:
			color = faction.color
	_base_modulate = color
	if _sprite != null:
		_sprite.modulate = _base_modulate


# Called by GameMap once map_data is known so faction colour can be applied
# even though Unit._ready runs before GameState.map_data is assigned.
func apply_faction_visual(map_data: Resource) -> void:
	_apply_faction_visual(map_data)


# Small on-map marker for a visible paired lead. Pair Up support units are hidden
# off-map, so the badge belongs to the lead and refreshes whenever the registry changes.
func _refresh_pair_up_badge() -> void:
	if _pair_up_badge == null:
		return
	var show_badge := false
	if data != null and data.unit_id != "" and is_inside_tree():
		var registry := get_node_or_null("/root/PairUpRegistry")
		show_badge = registry != null and bool(registry.call("is_lead", data.unit_id))
	if show_badge:
		# Anchor to the sprite's upper-right corner derived from TILE_SIZE rather
		# than hardcoded offsets, so the badge tracks the tile if TILE_SIZE changes.
		var badge_w := 22.0
		var badge_h := 16.0
		var top_margin := 13.0
		_pair_up_badge.offset_left = GameConstants.TILE_SIZE - badge_w
		_pair_up_badge.offset_right = GameConstants.TILE_SIZE
		_pair_up_badge.offset_top = top_margin
		_pair_up_badge.offset_bottom = top_margin + badge_h
	_pair_up_badge.visible = show_badge


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


# The unit's resolved movement type (V021-11): the single highest-precedence
# movement tag in its class's special_qualities, or "infantry" by default. Used for
# terrain-cost resolution (GridManager) and the class More Info display.
func movement_type() -> String:
	var class_data := _get_class_data()
	if class_data == null:
		return "infantry"
	return GameConstants.movement_type_of(class_data.special_qualities)


func has_vulnerability(group: String) -> bool:
	if data == null:
		return false
	var class_data := _get_class_data()
	if class_data == null:
		return false
	return group in class_data.vulnerability_groups


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


# Every inventory weapon the unit can currently use (rank allows it, uses left).
# The weapon-swap menu (#8) lists these; the first entry is the equipped weapon.
func get_equippable_weapons() -> Array[InventoryEntry]:
	var out: Array[InventoryEntry] = []
	if data == null:
		return out
	for entry in data.inventory:
		if not entry.is_weapon() or not entry.has_uses():
			continue
		var weapon := _load_weapon(entry.weapon_id)
		if weapon != null and _can_equip_rank(weapon):
			out.append(entry)
	return out


# Makes `entry` the equipped weapon by moving it to the front of the inventory.
# get_equipped_weapon() returns the first usable weapon, so inventory order *is*
# the equip state (#8). No-op if the entry is missing or already at the front.
func set_equipped_weapon(entry: InventoryEntry) -> void:
	if data == null or entry == null:
		return
	var idx: int = data.inventory.find(entry)
	if idx <= 0:
		return
	data.inventory.remove_at(idx)
	data.inventory.insert(0, entry)


func _load_weapon(id: String) -> WeaponData:
	if is_inside_tree():
		var dm := get_node_or_null("/root/DataManager")
		if dm:
			return dm.get_weapon(id)
	return null


func _can_equip_rank(weapon: WeaponData) -> bool:
	if data == null or weapon == null:
		return false
	var class_data := _get_class_data()
	if class_data == null:
		return false
	if not (weapon.combat_family in class_data.get_allowed_weapon_families()):
		return false
	return (
		get_active_wexp(weapon.wexp_track)
		>= GameConstants.minimum_wexp_for_rank(weapon.required_rank)
	)


func get_weapon_wexp(track: String) -> int:
	if data == null:
		return 0
	return int(data.weapon_wexp.get(track, 0))


func get_active_wexp(track: String) -> int:
	var stored := get_weapon_wexp(track)
	var class_data := _get_class_data()
	if class_data == null:
		return stored
	var cap := class_data.get_weapon_wexp_cap(track)
	if cap <= 0:
		return 0
	return mini(stored, cap)


func get_weapon_rank(track: String) -> String:
	return GameConstants.weapon_rank_for_wexp(get_active_wexp(track))


func get_stored_weapon_rank(track: String) -> String:
	return GameConstants.weapon_rank_for_wexp(get_weapon_wexp(track))


func is_weapon_track_available(track: String) -> bool:
	var class_data := _get_class_data()
	return class_data != null and class_data.get_weapon_wexp_cap(track) > 0


# Reads terrain bonuses from GridManager via its accessor (B1) rather than
# reaching into TERRAIN_*_BONUS directly. Only applies when this unit is the
# defender in combat (per GDD_02).
func get_terrain_def_bonus() -> int:
	var grid := _get_grid_manager()
	if grid == null:
		return 0
	return int(grid.get_terrain_bonuses(tile_position)["def"])


func get_terrain_dodge_bonus() -> int:
	var grid := _get_grid_manager()
	if grid == null:
		return 0
	return int(grid.get_terrain_bonuses(tile_position)["dodge"])


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


# Returns true if the unit has the given skill — checks both equipped skills and
# earned mastery skills (e.g. s_rank_mastery), so a mastery skill is never invisible
# to a has_skill() lookup.
func has_skill(skill_id: String) -> bool:
	if data == null:
		return false
	return skill_id in data.skills or skill_id in data.mastery_skills


# Returns how many uses of this skill remain this map. -1 = unlimited.
# Keyed by skill.id (not effect_id) so two skills sharing an effect_id keep
# isolated counters — matches SkillHandler.apply_trigger after issue 2.6.
func get_skill_uses_remaining(skill_id: String, max_per_map: int) -> int:
	if max_per_map == -1:
		return -1
	var used: int = data.skill_use_counters.get(skill_id, 0)
	return max(0, max_per_map - used)


func consume_skill_use(skill_id: String) -> void:
	data.skill_use_counters[skill_id] = data.skill_use_counters.get(skill_id, 0) + 1


# ---- Modifier Lifecycle ----


# Adds a temporary stat modifier. Replaces any existing modifier from the same source
# so re-applying the same skill refreshes duration rather than stacking.
# duration_type: "turn" decrements at this unit's turn start; "map_turn" at top of
# player phase; "combat" cleared after each combat; "permanent" never auto-removed.
# duration = -1 also means never auto-removed.
func add_modifier(
	stat: String, delta: int, source: String, duration: int, duration_type: String
) -> void:
	remove_modifier(source)
	data.active_modifiers.append(
		{
			"stat": stat,
			"delta": delta,
			"source": source,
			"duration": duration,
			"duration_type": duration_type
		}
	)


# Removes all modifiers whose source matches (e.g. on condition cure, on unshift).
func remove_modifier(source: String) -> void:
	data.active_modifiers = data.active_modifiers.filter(func(m): return m["source"] != source)


# Decrements modifiers of the given duration_type and removes those that hit 0.
# Called by TurnManager: "turn" at unit's own turn start; "map_turn" once per round.
func tick_modifiers(duration_type: String) -> void:
	for mod in data.active_modifiers:
		if mod["duration_type"] == duration_type and mod["duration"] > 0:
			mod["duration"] -= 1
	data.active_modifiers = data.active_modifiers.filter(func(m): return m["duration"] != 0)


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
		var bus := get_node_or_null("/root/EventBus")
		if bus != null:
			return bus
		var tree := get_tree()
		if tree != null and tree.root != null:
			return tree.root.get_node_or_null("EventBus")
	return null


# Decrements HP (clamped to 0), updates the bar, and emits unit_damaged.
# Does NOT trigger handle_death; CombatResolver decides when death checks happen.
func take_damage(amount: int) -> void:
	if data == null or amount <= 0:
		return
	data.hp = max(0, data.hp - amount)
	refresh_hp_display()
	var bus := _bus()
	if bus:
		bus.unit_damaged.emit(self, amount)


# Repaints the HP bar from current data. Callers that write hp through a
# transaction commit rather than through take_damage/heal need this, and it
# replaces the `if _hp_bar: _hp_bar.value = data.hp` pair that was copied into
# every method that moved HP.
func refresh_hp_display() -> void:
	if _hp_bar == null or data == null:
		return
	_hp_bar.max_value = data.max_hp
	_hp_bar.value = data.hp


# Increments HP (clamped to max_hp), updates the bar, and emits unit_healed.
func heal(amount: int) -> void:
	if data == null or amount <= 0:
		return
	data.hp = min(data.max_hp, data.hp + amount)
	refresh_hp_display()
	var bus := _bus()
	if bus:
		bus.unit_healed.emit(self, amount)


# Shared staff-heal logic used by both MapCursor (player) and EnemyAI.
# `weapon` must be captured by the caller BEFORE calling this — use_weapon_durability
# may remove the last-use entry, making get_equipped_weapon() return null afterward.
func perform_staff_heal(target: Node, weapon: WeaponData) -> void:
	# Use the modifier-aware stat so temporary MAG buffs affect healing, matching
	# how combat damage reads stats.
	var heal_amount: int = GameConstants.STAFF_HEAL_BASE + get_effective_stat("magic")
	var sh := get_node_or_null("/root/SkillHandler") if is_inside_tree() else null
	if sh != null and sh.has_method("get_staff_heal_bonus"):
		heal_amount += int(sh.get_staff_heal_bonus(self))
	target.heal(heal_amount)
	use_weapon_durability(weapon.id)
	add_wexp(weapon.wexp_track, weapon.wexp)
	add_exp(GameConstants.STAFF_HEAL_EXP)


# Called when HP reaches 0. If permadeath is on (per CampaignRules), flags the
# UnitData as incapacitated so the unit cannot be redeployed; otherwise the
# data is preserved for the next map. Either way the scene node is freed.
func handle_death() -> RefCounted:
	if data == null:
		return DeathResultScript.failure("death subject has no unit data")
	var lifecycle := get_node_or_null("/root/DeathLifecycle") if is_inside_tree() else null
	if lifecycle == null:
		return DeathResultScript.failure("DeathLifecycle is unavailable")
	return lifecycle.handle_death(
		DeathContextScript.from_subject(self, "compatibility", "unit.handle_death")
	)


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
#
# Crossings resolve FIRST, over the path as data ([PCM-3]) — the returned
# CrossingOutcome carries the effective (possibly truncated) path, and the tween
# below only presents it. Resolving here rather than at the three call sites is
# deliberate: it is the one place both the Instant-speed branch and the tween
# branch pass through, so a halt cannot fire for animated players and silently
# not fire at Instant speed, and an AI move resolves identically to a player's.
# Callers read `ends_activation` / `movement_permanent` off the outcome.
func move_along_path(path: Array[Vector2i]) -> CrossingOutcome:
	if path.size() <= 1:
		return CrossingOutcome.pass_through(path)
	var outcome := _resolve_crossings(path)
	var effective: Array[Vector2i] = outcome.path
	if effective.size() <= 1:
		return outcome
	var origin: Vector2i = tile_position
	var seconds_per_tile := _get_per_tile_seconds()
	# "Instant" speed: no tween, just snap to the destination
	if seconds_per_tile <= 0.0:
		snap_to_tile(effective[-1])
		_emit_moved(origin, effective[-1])
		return outcome
	# Update logical position before animation so grid queries are never stale mid-tween.
	tile_position = effective[-1]
	var tween := create_tween()
	# Each tile is one tween segment; chain them sequentially
	for i in range(1, effective.size()):
		var dest_world := Vector2(
			effective[i].x * GameConstants.TILE_SIZE, effective[i].y * GameConstants.TILE_SIZE
		)
		tween.tween_property(self, "position", dest_world, seconds_per_tile)
	await tween.finished
	_emit_moved(origin, tile_position)
	return outcome


# Asks the crossing service what happens along this path. Missing service (bare
# test trees, tools) means nothing observes movement, so the path stands.
func _resolve_crossings(path: Array[Vector2i]) -> CrossingOutcome:
	var service := get_node_or_null("/root/CrossingService")
	if service == null:
		return CrossingOutcome.pass_through(path)
	return service.resolve(self, path)


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
	position = Vector2(tile.x * GameConstants.TILE_SIZE, tile.y * GameConstants.TILE_SIZE)


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
	amount = _debug_force_levelup_exp(amount)
	var telemetry := get_node_or_null("/root/TransitionTelemetry") if is_inside_tree() else null
	if telemetry != null:
		telemetry.record_exp_award(self, amount)
	var max_level: int = _current_max_level()
	if data.level >= max_level:
		# EXP is discarded at the level cap, but still surface promotion availability:
		# a unit authored to spawn ALREADY at max level never crossed the cap via
		# level_up() (which is the other emit site), so without this it could never
		# auto-promote. Idempotent — _maybe_emit_promotion_available() is gated on
		# auto_promote_at_max_level + can_promote() (false once promoted), and
		# PromotionScreen ignores re-emits while it is already open.
		_maybe_emit_promotion_available()
		return  # M6 promotion will hook here for further levelling

	data.exp += amount
	while data.exp >= 100:
		data.exp -= 100
		level_up()
		if data.level >= max_level:
			_maybe_emit_promotion_available()
			data.exp = 0  # no overflow past the cap
			break


# Shared debug-aid seam: when force-level-up is on, every EXP-awarding path
# should grant at least one full level. Combat already routes through a
# dedicated override in CombatResolver; add_exp() mirrors that so staff use and
# future non-combat EXP sources behave the same way.
func _debug_force_levelup_exp(amount: int) -> int:
	if amount <= 0 or not OS.is_debug_build() or not is_inside_tree():
		return amount
	var gs := get_node_or_null("/root/GameState")
	if gs != null and gs.get("debug_force_levelup"):
		return maxi(amount, 100)
	return amount


func _current_max_level() -> int:
	var class_data := _get_class_data()
	return class_data.max_level if class_data != null else 20


func can_promote() -> bool:
	var class_data := _get_class_data()
	return (
		class_data != null
		and not data.is_promoted
		and data.level >= class_data.max_level
		and not class_data.promotes_to.is_empty()
	)


func promote(target_class_id: String) -> bool:
	var source_class := _get_class_data()
	if source_class == null or not can_promote():
		return false
	if not (target_class_id in source_class.promotes_to):
		return false
	var target_class := _class_data_for(target_class_id)
	if target_class == null:
		return false
	var old_class_id: String = data.class_id
	var line_id: String = _current_class_line_id()
	_apply_promotion_stat_bonuses(target_class)
	data.class_id = target_class_id
	data.class_line_id = line_id if line_id != "" else old_class_id
	data.is_promoted = true
	_reset_class_level_state(false)
	_apply_class_weapon_bases(target_class)
	var bus := _bus()
	if bus:
		bus.unit_promoted.emit(self, old_class_id, target_class_id)
	return true


func can_use_second_seal() -> bool:
	return not get_second_seal_options().is_empty()


func get_second_seal_options() -> Array[Dictionary]:
	var class_data := _get_class_data()
	if class_data == null:
		return []
	var dm := get_node_or_null("/root/DataManager") if is_inside_tree() else null
	if dm == null:
		return []
	var options: Array[Dictionary] = []
	var current_line_id: String = _current_class_line_id()
	var at_max_level: bool = data.level >= class_data.max_level
	match _effective_second_seal_tier():
		1:
			if data.level < 10:
				return _self_reset_only(options, class_data, current_line_id, at_max_level)
			for class_id in data.reclass_options:
				var target_class: ClassData = _class_data_for(String(class_id))
				if target_class == null or target_class.tier != 1:
					continue
				if target_class.id == data.class_id:
					continue
				_append_second_seal_option(options, target_class, target_class.id, "Reclass", false)
			return _self_reset_only(options, class_data, current_line_id, at_max_level)
		2:
			var class_ids: Array = dm.get_all_classes().keys()
			class_ids.sort()
			for class_id in class_ids:
				var target_class: ClassData = _class_data_for(String(class_id))
				if target_class == null:
					continue
				if target_class.tier == 1:
					_append_second_seal_option(
						options, target_class, target_class.id, "Demote", false
					)
					continue
				if data.level < 10 or target_class.tier != 2:
					continue
				for line_id in _target_line_ids_for_promoted_class(target_class):
					if line_id == current_line_id:
						continue
					_append_second_seal_option(options, target_class, line_id, "Reclass", false)
			return _self_reset_only(options, class_data, current_line_id, at_max_level)
	return []


func reclass(target_class_id: String, target_line_id: String = "") -> bool:
	var source_class := _get_class_data()
	if source_class == null:
		return false
	var resolved_line_id: String = _normalize_line_id(target_class_id, target_line_id)
	var chosen := {}
	for option in get_second_seal_options():
		if option["class_id"] == target_class_id and option["class_line_id"] == resolved_line_id:
			chosen = option
			break
	if chosen.is_empty():
		return false
	var target_class := _class_data_for(target_class_id)
	if target_class == null:
		return false
	var old_class_id: String = data.class_id
	var self_reset: bool = bool(chosen.get("is_self_reset", false))
	if not self_reset and source_class.tier == 2:
		_remove_promotion_stat_bonuses(source_class)
	if not self_reset:
		_replace_class_base_stats(
			source_class, _current_class_line_id(), target_class, resolved_line_id
		)
		_clamp_stats_to_caps(target_class)
		data.class_id = target_class_id
		data.class_line_id = resolved_line_id
		data.is_promoted = target_class.tier == 2
		_apply_class_weapon_bases(target_class)
	else:
		data.class_id = target_class_id
		data.class_line_id = resolved_line_id
		data.is_promoted = target_class.tier == 2
	_reset_class_level_state(true)
	_grant_current_level_class_skills()
	var bus := _bus()
	if bus:
		bus.unit_reclassed.emit(self, old_class_id, target_class_id)
	return true


func _class_data_for(class_id: String) -> ClassData:
	if not is_inside_tree():
		return null
	var dm := get_node_or_null("/root/DataManager")
	return dm.get_class_data(class_id) if dm != null else null


func _maybe_emit_promotion_available() -> void:
	var gs := get_node_or_null("/root/GameState") if is_inside_tree() else null
	var rules: CampaignRules = (gs.get("campaign_rules") as CampaignRules) if gs else null
	if rules == null or not rules.auto_promote_at_max_level or not can_promote():
		return
	var bus := _bus()
	if bus:
		bus.promotion_available.emit(self)


func _apply_promotion_stat_bonuses(target_class: ClassData) -> void:
	for stat in _GROWTH_STATS:
		var bonus: int = int(target_class.promotion_stat_bonuses.get(stat, 0))
		if stat == "hp":
			data.max_hp = _clamp_to_cap(
				data.max_hp + bonus, int(target_class.stat_caps.get("hp", -1))
			)
			data.hp = mini(data.hp + bonus, data.max_hp)
			if _hp_bar:
				_hp_bar.max_value = data.max_hp
				_hp_bar.value = data.hp
			continue
		var current: int = int(data.get(stat))
		data.set(stat, _clamp_to_cap(current + bonus, int(target_class.stat_caps.get(stat, -1))))


func _apply_class_weapon_bases(target_class: ClassData) -> void:
	for key in target_class.weapon_wexp_bases.keys():
		var track: String = String(key)
		var base_wexp: int = target_class.get_weapon_wexp_base(track)
		data.weapon_wexp[track] = maxi(get_weapon_wexp(track), base_wexp)


func _reset_class_level_state(preserve_internal_level: bool) -> void:
	var previous_internal_level: int = data.internal_level
	data.level = 1
	data.exp = 0
	data.growth_accumulators = {}
	_recalculate_internal_level()
	if preserve_internal_level:
		data.internal_level = maxi(previous_internal_level, data.internal_level)


func _clamp_to_cap(value: int, cap: int) -> int:
	return mini(value, cap) if cap >= 0 else value


# Rolls stat increases per the unit's class growth rates and applies them.
# Two methods: growth_random (RNG-based, rate > 100 gives guaranteed gains)
# and growth_fixed (deterministic accumulator, always predictable progression).
# Emits unit_leveled_up with the dictionary of changes for the level-up screen.
# Growth-roll set + order sourced from the single StatRegistry vocabulary; the
# RNG draws one roll per stat in this order (order is part of the §5 contract).
const _GROWTH_STATS := StatRegistry.GROWTH_STAT_IDS


func level_up() -> void:
	if data == null:
		return
	data.level += 1
	data.internal_level += 1
	var gs := get_node_or_null("/root/GameState") if is_inside_tree() else null
	var rules: CampaignRules = (gs.get("campaign_rules") as CampaignRules) if gs else null
	var method: String = rules.leveling_method if rules != null else "growth_random"
	var class_data := _get_class_data()
	if class_data == null:
		return
	var rates: Dictionary = _resolve_growth_rates(class_data)
	var caps: Dictionary = class_data.stat_caps
	# One chained "levelup" RNG event per level (RNG-1): begin before the growth
	# draws, commit after them. growth_fixed draws nothing but still commits, so
	# the dice chain is identical across leveling methods for the same actions.
	var svc := get_node_or_null("/root/RngService") if is_inside_tree() else null
	var event_record: Array[String] = [data.unit_id, str(data.level)]
	var changes: Dictionary = {}
	match method:
		"growth_fixed":
			changes = _level_up_fixed(rates, caps)
		_:  # "growth_random" and any unknown value
			changes = _level_up_random(
				rates, caps, svc.begin_event("levelup", event_record) if svc else null
			)
	if svc:
		svc.commit_event("levelup", event_record)
	# Auto-learn any class skill whose unlock level matches the new level.
	var learned: Array[Dictionary] = _grant_level_skills(class_data)
	var bus := _bus()
	if bus:
		bus.unit_leveled_up.emit(self, changes, learned)


# Picks the growth table for this level-up. Enemy/generic units auto-level on
# the class enemy table alone; player units add the class player table to the
# unit's personal growth_rates (per the GDD growth-rate split).
func _resolve_growth_rates(class_data: ClassData) -> Dictionary:
	if team != "blue":
		return class_data.enemy_growth_rates
	var merged: Dictionary = {}
	for stat in ClassData.STAT_KEYS:
		merged[stat] = (
			int(class_data.player_growth_rates.get(stat, 0)) + int(data.growth_rates.get(stat, 0))
		)
	return merged


# Grants every skill listed in the class's skill_unlocks for the unit's current
# level, skipping any the unit already knows. Returns dictionaries describing
# what was learned and whether it fit into an equipped skill slot.
func _grant_level_skills(class_data: ClassData) -> Array[Dictionary]:
	_seed_earned_skills()
	var learned: Array[Dictionary] = []
	for unlock_level in class_data.skill_unlocks:
		if int(unlock_level) != data.level:
			continue
		var learned_skill := _learn_skill(String(class_data.skill_unlocks[unlock_level]))
		if not learned_skill.is_empty():
			learned.append(learned_skill)
	return learned


func _seed_earned_skills() -> void:
	for skill_id in data.skills:
		if not (skill_id in data.earned_skills):
			data.earned_skills.append(skill_id)


func _has_earned_skill(skill_id: String) -> bool:
	return (
		skill_id in data.earned_skills or skill_id in data.skills or skill_id in data.mastery_skills
	)


func _grant_current_level_class_skills() -> void:
	if data == null or data.class_id.is_empty():
		return
	var class_data := _get_class_data()
	if class_data == null:
		return
	# Spawn/reclass should grant every class skill earned at or below the unit's
	# current level — a directly-spawned level-20 General must already know its
	# level 5 and level 15 unlocks, not only an exact-level match.
	var unlock_levels: Array = class_data.skill_unlocks.keys()
	unlock_levels.sort()
	for unlock_level in unlock_levels:
		if int(unlock_level) > data.level:
			continue
		_learn_skill(String(class_data.skill_unlocks[unlock_level]))


func _learn_skill(skill_id: String) -> Dictionary:
	if skill_id.is_empty() or _has_earned_skill(skill_id):
		return {}
	data.earned_skills.append(skill_id)
	var equipped: bool = false
	if data.skills.size() < _max_equipped_skills():
		data.skills.append(skill_id)
		equipped = true
	return {"id": skill_id, "equipped": equipped}


func _ensure_class_line_id() -> void:
	if data == null or data.class_id.is_empty() or not data.class_line_id.is_empty():
		return
	var class_data := _get_class_data()
	if class_data == null:
		return
	if class_data.tier == 1:
		data.class_line_id = data.class_id
		return
	var lines := _target_line_ids_for_promoted_class(class_data)
	if not lines.is_empty():
		data.class_line_id = lines[0]


func _ensure_internal_level() -> void:
	if data == null or data.internal_level > 0:
		return
	_recalculate_internal_level()


func _current_class_line_id() -> String:
	_ensure_class_line_id()
	return data.class_line_id


func _effective_second_seal_tier() -> int:
	var class_data := _get_class_data()
	if class_data == null:
		return 0
	if class_data.resolved_internal_level_rule() == "special":
		return 2 if data.level >= 30 else 1
	return class_data.tier


func _recalculate_internal_level() -> void:
	if data == null:
		return
	var class_data := _get_class_data()
	if class_data == null:
		data.internal_level = maxi(1, data.level)
		return
	match class_data.resolved_internal_level_rule():
		"promoted":
			data.internal_level = 20 + data.level
		"special":
			data.internal_level = data.level
		_:
			data.internal_level = data.level


func _self_reset_only(
	options: Array[Dictionary], class_data: ClassData, current_line_id: String, at_max_level: bool
) -> Array[Dictionary]:
	if at_max_level:
		_append_second_seal_option(options, class_data, current_line_id, "Reset", true)
	return options


func _append_second_seal_option(
	options: Array[Dictionary],
	target_class: ClassData,
	line_id: String,
	note: String,
	is_self_reset: bool
) -> void:
	for option in options:
		if option["class_id"] == target_class.id and option["class_line_id"] == line_id:
			return
	var label := target_class.display_name
	var target_lines := _target_line_ids_for_promoted_class(target_class)
	if target_class.tier == 2 and target_lines.size() > 1:
		var line_class := _class_data_for(line_id)
		var line_name := line_class.display_name if line_class != null else line_id.capitalize()
		label = "%s (%s line)" % [target_class.display_name, line_name]
	(
		options
		. append(
			{
				"class_id": target_class.id,
				"class_line_id": line_id,
				"label": label,
				"target_tier": target_class.tier,
				"is_self_reset": is_self_reset,
				"note": note,
			}
		)
	)


func _target_line_ids_for_promoted_class(target_class: ClassData) -> Array[String]:
	if target_class == null:
		return []
	if target_class.tier != 2:
		return [target_class.id]
	var line_ids: Array[String] = []
	for line_id in target_class.promotes_from:
		var line_text := String(line_id)
		if line_text.is_empty() or line_text in line_ids:
			continue
		line_ids.append(line_text)
	if line_ids.is_empty():
		line_ids.append(target_class.id)
	line_ids.sort()
	return line_ids


func _normalize_line_id(target_class_id: String, target_line_id: String) -> String:
	if not target_line_id.is_empty():
		return target_line_id
	var target_class := _class_data_for(target_class_id)
	if target_class == null:
		return ""
	if target_class.tier == 1:
		return target_class.id
	var line_ids := _target_line_ids_for_promoted_class(target_class)
	return line_ids[0] if not line_ids.is_empty() else target_class.id


func _remove_promotion_stat_bonuses(source_class: ClassData) -> void:
	for stat in _GROWTH_STATS:
		var bonus: int = int(source_class.promotion_stat_bonuses.get(stat, 0))
		if bonus == 0:
			continue
		if stat == "hp":
			data.max_hp = max(1, data.max_hp - bonus)
			data.hp = mini(data.hp, data.max_hp)
			if _hp_bar:
				_hp_bar.max_value = data.max_hp
				_hp_bar.value = data.hp
			continue
		var current: int = int(data.get(stat))
		data.set(stat, max(0, current - bonus))


func _replace_class_base_stats(
	source_class: ClassData, source_line_id: String, target_class: ClassData, target_line_id: String
) -> void:
	var source_base_class: ClassData = _class_base_contributor(source_class, source_line_id)
	var target_base_class: ClassData = _class_base_contributor(target_class, target_line_id)
	if source_base_class == null or target_base_class == null:
		return
	var hp_delta: int = target_base_class.base_hp - source_base_class.base_hp
	data.max_hp = max(1, data.max_hp + hp_delta)
	data.hp = clampi(data.hp + hp_delta, 0, data.max_hp)
	if _hp_bar:
		_hp_bar.max_value = data.max_hp
		_hp_bar.value = data.hp
	var stat_keys := {
		"strength": ["base_strength", "strength"],
		"magic": ["base_magic", "magic"],
		"defense": ["base_defense", "defense"],
		"resistance": ["base_resistance", "resistance"],
		"skill": ["base_skill", "skill"],
		"speed": ["base_speed", "speed"],
		"luck": ["base_luck", "luck"],
		"movement": ["base_movement", "movement"],
		"constitution": ["base_constitution", "constitution"],
		"line_of_sight": ["base_line_of_sight", "line_of_sight"],
	}
	for stat_name in stat_keys.keys():
		var fields: Array = stat_keys[stat_name]
		var source_base: int = int(source_base_class.get(String(fields[0])))
		var target_base: int = int(target_base_class.get(String(fields[0])))
		var current: int = int(data.get(String(fields[1])))
		data.set(String(fields[1]), max(0, current + target_base - source_base))


func _class_base_contributor(class_data: ClassData, line_id: String) -> ClassData:
	if class_data == null:
		return null
	if class_data.tier == 1:
		return class_data
	return _class_data_for(line_id)


func _clamp_stats_to_caps(target_class: ClassData) -> void:
	data.max_hp = _clamp_to_cap(data.max_hp, int(target_class.stat_caps.get("hp", -1)))
	data.hp = mini(data.hp, data.max_hp)
	if _hp_bar:
		_hp_bar.max_value = data.max_hp
		_hp_bar.value = data.hp
	for stat in _GROWTH_STATS:
		if stat == "hp":
			continue
		data.set(
			stat, _clamp_to_cap(int(data.get(stat)), int(target_class.stat_caps.get(stat, -1)))
		)


func _max_equipped_skills() -> int:
	var gs := get_node_or_null("/root/GameState") if is_inside_tree() else null
	var rules: CampaignRules = (gs.get("campaign_rules") as CampaignRules) if gs else null
	return rules.max_skills if rules != null else 5


# DEBUG TESTING AID (#11) — debug builds only; remove before release, see
# GDD_10_Roadmap.md § Pre-Release Cleanup. When GameState.debug_growth_boost is
# on, inflates a growth rate by +300 so level-up stat gains are easy to observe.
func _debug_boosted_rate(rate: int) -> int:
	if not OS.is_debug_build():
		return rate
	var gs := get_node_or_null("/root/GameState") if is_inside_tree() else null
	if gs != null and gs.debug_growth_boost:
		return rate + 300
	return rate


# Probabilistic: rate 75 = 75% chance of +1. Rate 150 = +1 guaranteed, 50% chance of +2.
# Draws one roll per stat in _GROWTH_STATS order from the levelup event RNG
# (RNG-1; the order is part of the §5 canonical-roll-order contract). rng = null
# is the no-RngService fallback for suites that exercise growth statistically —
# production always passes the event RNG from level_up().
func _level_up_random(
	rates: Dictionary, caps: Dictionary, rng: RandomNumberGenerator = null
) -> Dictionary:
	if rng == null:
		rng = RandomNumberGenerator.new()  # rng-allow: headless fallback when RngService is absent
		rng.randomize()  # rng-allow: headless fallback when RngService is absent
	var changes: Dictionary = {}
	for stat in _GROWTH_STATS:
		var rate: int = _debug_boosted_rate(int(rates.get(stat, 0)))
		var guaranteed: int = rate / 100
		var remainder: int = rate % 100
		var gain: int = guaranteed + (1 if rng.randi_range(0, 99) < remainder else 0)  # rng-allow: draw from the RngService event RNG (RNG-1)
		var applied: int = _apply_stat_gain(stat, gain, caps)
		if applied > 0:
			changes[stat] = applied
	return changes


# Deterministic: accumulates rate each level; +1 per full 100 accumulated.
# Carry persists in data.growth_accumulators so gains are perfectly predictable.
# Rate 50 → +1 every 2 levels exactly. Rate 150 → +1 every level, +1 extra every other.
func _level_up_fixed(rates: Dictionary, caps: Dictionary) -> Dictionary:
	var changes: Dictionary = {}
	for stat in _GROWTH_STATS:
		var rate: int = _debug_boosted_rate(int(rates.get(stat, 0)))
		var acc: int = int(data.growth_accumulators.get(stat, 0)) + rate
		var gain: int = acc / 100
		data.growth_accumulators[stat] = acc % 100
		var applied: int = _apply_stat_gain(stat, gain, caps)
		if applied > 0:
			changes[stat] = applied
	return changes


# Applies up to `gain` points to a stat, stopping at the class cap. Returns the
# number actually applied — a stat already at cap reports 0 so the level-up
# screen shows no gain for it.
func _apply_stat_gain(stat: String, gain: int, caps: Dictionary) -> int:
	var cap: int = int(caps.get(stat, -1))  # -1 = uncapped (missing key / empty caps)
	var applied: int = 0
	for _i in gain:
		if not _increment_stat(stat, cap):
			break  # at cap — further points in this level-up are wasted
		applied += 1
	return applied


# Raises one stat by 1, unless it has reached `cap` (cap < 0 means uncapped).
# Returns true if the point was applied. The "hp" stat raises max_hp (the cap
# target) and current hp together.
func _increment_stat(stat: String, cap: int) -> bool:
	if stat == "hp":
		if cap >= 0 and data.max_hp >= cap:
			return false
		data.max_hp += 1
		data.hp += 1  # current HP also increases on level up
		# Refresh the HP bar: max_value is set once at init, so a mid-map
		# level-up would otherwise leave the bar's range stale until the next
		# reset_appearance() (never, for enemies).
		if _hp_bar:
			_hp_bar.max_value = data.max_hp
			_hp_bar.value = data.hp
		return true
	# Every other growth stat shares its name with a UnitData property.
	var current: int = int(data.get(stat))
	if cap >= 0 and current >= cap:
		return false
	data.set(stat, current + 1)
	return true


# Adds weapon EXP to the given track and reports whether the derived displayed
# rank increased. Numeric WEXP is the authoritative stored value.
func add_wexp(track: String, amount: int) -> bool:
	var plan := plan_wexp_gain(track, amount)
	if not plan.ok:
		return false
	data.weapon_wexp[track] = plan.next_total
	if plan.grants_mastery:
		data.mastery_skills.append("s_rank_mastery")
	return plan.rank_up


# Pure rule half of add_wexp(): weapon-rank caps, the Discipline multiplier and
# the S-rank mastery grant, decided without writing anything. A caller that
# commits through a transaction prepares from this and journals the two fields;
# add_wexp() above is the same rules applied immediately. Split 2026-08-31 for
# the Session 7 combat migration — a fight must be able to decide its whole
# outcome before any of it lands.
func plan_wexp_gain(track: String, amount: int) -> Dictionary:
	var declined := {"ok": false, "next_total": 0, "rank_up": false, "grants_mastery": false}
	if data == null or amount <= 0:
		return declined
	if not data.weapon_wexp.has(track):
		return declined
	var class_data := _get_class_data()
	if class_data == null:
		return declined
	var class_cap := class_data.get_weapon_wexp_cap(track)
	var current_total := get_weapon_wexp(track)
	if class_cap <= 0 or current_total >= class_cap:
		return declined
	var gained := amount
	var sh := get_node_or_null("/root/SkillHandler") if is_inside_tree() else null
	if sh != null and sh.has_method("get_wexp_multiplier"):
		gained *= int(sh.get_wexp_multiplier(self, track))
	var previous_rank: String = GameConstants.weapon_rank_for_wexp(current_total)
	var next_total := mini(current_total + gained, class_cap)
	var next_rank: String = GameConstants.weapon_rank_for_wexp(next_total)
	return {
		"ok": true,
		"next_total": next_total,
		"rank_up": previous_rank != next_rank,
		"grants_mastery":
		next_rank == "S" and previous_rank != "S" and not ("s_rank_mastery" in data.mastery_skills),
	}
