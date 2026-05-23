extends Node
# [NOTE — M-1] class_name cannot be used on autoload scripts in Godot 4, even with a
# name that differs from the autoload name — Godot refuses to register the class_name.
# TODO save-system: the current snapshot (_map_start_snapshot) is in-memory only and
# covers player UnitData. Suspend saves additionally need: (a) live enemy UnitData state
# (enemies are re-spawned fresh today — see GameMap._spawn_units), and (b) live terrain
# mutations if MapData.grid ever diverges at runtime. Neither is in scope until the
# save-system milestone — see §0b N2 in code_review_2026-05-13c.

enum Phase { PLAYER, ENEMY }

# ── M14 stage 2: alliance-group hostility model ──────────────────────────────
# A faction's id maps to an alliance group; two units are hostile iff they
# belong to different groups. Captures the GDD relationships exactly with one
# table instead of a 4x4 pairwise matrix (and trivially extends to a 5th+
# faction — add it to the dict).
#
# Default groups (per second_player_control_feasibility.md §3.2):
#   {blue, green} — the player's alliance
#   {red}         — the standing enemy
#   {yellow}      — the rogue that fights everyone
#
# Stage 3 will replace this constant with data read from each map's
# FactionData[] so a map can override groupings; the constant stays as the
# fallback for tests / headless code paths that don't set a MapData.
const _DEFAULT_ALLIANCE_GROUPS: Dictionary = {
	"blue":   "allies",
	"green":  "allies",
	"red":    "foes",
	"yellow": "rogues",
}
# Runtime override — populated by Stage 3 from MapData.factions; meanwhile mirrors
# the defaults so are_hostile() works from the moment GameState comes up.
var _alliance_groups: Dictionary = _DEFAULT_ALLIANCE_GROUPS.duplicate()


# True iff faction `a_id` and faction `b_id` are in DIFFERENT alliance groups.
# An empty string OR an unknown id is treated as its own private group (so it
# is hostile to every named faction and to itself — same group of one). Stage 5
# may revisit "hostile to self" but for the current model it can't arise.
func are_hostile(a_id: String, b_id: String) -> bool:
	if a_id == b_id:
		# Exactly-equal ids are the same faction by definition — same group, never hostile.
		# Matches the stage-1 "u.team == other.team" semantics for the binary case.
		return false
	var ga: String = _alliance_groups.get(a_id, a_id)  # unknown id → its own group named after itself
	var gb: String = _alliance_groups.get(b_id, b_id)
	return ga != gb


# Alliance-group name for a faction id; defaults to the id itself if unknown
# (every unmapped faction is its own one-faction group, hostile to all others).
func get_alliance_group(faction_id: String) -> String:
	return _alliance_groups.get(faction_id, faction_id)
# ─────────────────────────────────────────────────────────────────────────────


# Per-save gameplay rules. Set by the New Game screen; the save-system milestone
# will serialize these into the save file. Defaults cover the direct-boot dev path.
var permadeath_enabled: bool = false
var leveling_method: String = "growth_random"
var auto_promote_at_max_level: bool = false
# max_skills now gates auto-equipped learned skills (M6.3), but there is still
# no battle-prep UI for manual swapping. max_inventory remains future-facing.
var max_skills: int = 4
var max_inventory: int = 8

# ── DEBUG TESTING AIDS (#10 / #11) ───────────────────────────────────────────
# Temporary playtest aids — both are honoured ONLY in debug builds (callers gate
# on OS.is_debug_build()), so a release build is unaffected even if left true.
# RELEASE BLOCKER: delete these and their callers before shipping — tracked in
# GDD_10_Roadmap.md § Pre-Release Cleanup. Toggle them from the remote debugger.
# Backing fields for the two debug flags. Setters below emit
# EventBus.debug_flags_changed so the HUD's DEBUG MODE banner can re-render its
# list of active aids the moment a flag is flipped (incl. from the remote
# debugger, which goes through the property setter). Backing-variable pattern is
# required — assigning to the property name inside its own setter recurses.
var _debug_force_levelup_v: bool = false
var _debug_growth_boost_v: bool = false

var debug_force_levelup: bool:   # #10: any landed hit awards a full level
	get:
		return _debug_force_levelup_v
	set(v):
		if _debug_force_levelup_v == v: return
		_debug_force_levelup_v = v
		_emit_debug_flags_changed()
var debug_growth_boost: bool:    # #11: +50 to every growth rate on level-up
	get:
		return _debug_growth_boost_v
	set(v):
		if _debug_growth_boost_v == v: return
		_debug_growth_boost_v = v
		_emit_debug_flags_changed()


# Routes the setter notification through EventBus when it is available. Null-
# guarded because GameState's _init can run before EventBus is wired in headless
# --script tests that don't load every autoload.
func _emit_debug_flags_changed() -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("debug_flags_changed"):
		bus.debug_flags_changed.emit()

# Current map state
var current_phase: Phase = Phase.PLAYER
var turn_number: int = 1
var all_units: Array[Node] = []
# M14 stage 3: per-faction unit buckets keyed by faction id. Replaces the
# previous binary _player_units / _enemy_units pair so a 5th faction is pure
# data. Living-unit filters (get_living_units_of, get_living_player_units,
# get_living_enemy_units) all read from this dict — the legacy two methods
# are thin wrappers that delegate to "blue" and "every non-blue id" so the
# existing TurnManager / EnemyAI / MapCursor call sites work unchanged.
var _units_by_faction: Dictionary = {}
var map_data: MapData = null

# Persists between maps — the live roster and shared economy
var player_roster: Array[UnitData] = []
var party_gold: int = 0
var party_items: Array[String] = []  # item IDs awarded by completed maps
# New Game / map-select launch state. The selected map path persists so retries
# and direct scene reloads stay on the same map until another selection is made.
var next_map_data_path: String = ""
var next_map_roster_policy: String = "default_roster"
var next_map_roster_source: String = ""

# Deep copy taken at map start; used by the Retry button to restore state
var _map_start_snapshot: Array[Dictionary] = []
# Party-level economy snapshot — restored alongside unit data so a Retry (including
# a Retry after a victory) rolls gold and item rewards back to the map's start
# state, instead of letting a replay re-grant them.
var _snapshot_party_gold: int = 0
var _snapshot_party_items: Array[String] = []


func register_unit(unit: Node) -> void:
	if unit in all_units:
		push_error("GameState.register_unit: %s already registered" % unit)
		return
	all_units.append(unit)
	# M14 stage 3: per-faction-id buckets. Builds the entry array lazily so a
	# new faction joining mid-map (e.g. summoned units in a later milestone)
	# doesn't need pre-registration.
	var bucket: Array[Node] = _units_by_faction.get(unit.team, [] as Array[Node])
	if not (unit in bucket):
		bucket.append(unit)
	_units_by_faction[unit.team] = bucket


func unregister_unit(unit: Node) -> void:
	all_units.erase(unit)
	if "team" in unit:
		var bucket: Array[Node] = _units_by_faction.get(unit.team, [] as Array[Node])
		bucket.erase(unit)
		_units_by_faction[unit.team] = bucket
	else:
		# Defensive: a Unit instance whose team somehow vanished — sweep all buckets.
		for fid in _units_by_faction.keys():
			(_units_by_faction[fid] as Array[Node]).erase(unit)


func set_phase(new_phase: Phase, faction_id: String = "") -> void:
	current_phase = new_phase
	# Use emit_signal to avoid a compile-time dependency on EventBus identifier
	# (autoloads must not reference each other by identifier — use get_node_or_null).
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.emit_signal("phase_changed", new_phase, faction_id)


# M14 stage 3: living units of an arbitrary faction. filter() returns a generic
# Array, so build Array[Node] explicitly. A missing faction returns [].
func get_living_units_of(faction_id: String) -> Array[Node]:
	var result: Array[Node] = []
	var bucket: Array[Node] = _units_by_faction.get(faction_id, [] as Array[Node])
	for u in bucket:
		if is_instance_valid(u) and u.data != null and u.data.hp > 0:
			result.append(u)
	return result


# Every faction id that has had at least one unit registered on this map (alive
# or dead). Used by the M16 evaluator to enumerate which factions exist when
# walking per-group conditions. Returns a typed copy so callers can iterate
# safely while register_unit / unregister_unit mutate the underlying dict.
func get_registered_faction_ids() -> Array[String]:
	var out: Array[String] = []
	for fid in _units_by_faction.keys():
		out.append(fid)
	return out


# Legacy alias: the human-controlled "blue" faction. Kept so the existing
# TurnManager / MapCursor / EnemyAI / test call sites work unchanged. Stage 5
# (hotseat) and beyond will broaden this to "the active controlling faction"
# at the call site rather than hardcoding blue here.
func get_living_player_units() -> Array[Node]:
	return get_living_units_of("blue")


# Legacy alias: every living unit NOT in blue's alliance group — i.e. every
# unit hostile to the player. Today's enemy AI loop iterates this; stage 4
# replaces both call sites with run_ai_phase(faction) / per-AI-faction iter.
func get_living_enemy_units() -> Array[Node]:
	var result: Array[Node] = []
	for fid in _units_by_faction.keys():
		# "blue" by definition is in blue's alliance group; skip it. For other
		# ids, use are_hostile so a future "green" ally to blue is also excluded
		# from the "enemy" list. (Stage 4 retires this caller; behaviour-neutral
		# today since only blue + red exist.)
		if fid == "blue" or not are_hostile("blue", fid):
			continue
		for u in (_units_by_faction[fid] as Array[Node]):
			if is_instance_valid(u) and u.data != null and u.data.hp > 0:
				result.append(u)
	return result


func is_player_turn() -> bool:
	return current_phase == Phase.PLAYER


func reset_map_state() -> void:
	all_units.clear()
	_units_by_faction.clear()
	map_data = null
	turn_number = 1
	current_phase = Phase.PLAYER


func configure_next_map(map_path: String, roster_policy: String = "default_roster",
		roster_source: String = "") -> void:
	next_map_data_path = map_path
	next_map_roster_policy = roster_policy
	next_map_roster_source = roster_source


# Loads the 6 default roster UnitData .tres files into player_roster.
# Called by MainMenu on "New Game" for MVP.
func load_default_roster() -> void:
	load_roster_from_directory("res://data/roster/default/")


func load_roster_from_directory(roster_path: String) -> void:
	player_roster.clear()
	var dir := DirAccess.open(roster_path)
	if dir == null:
		push_error("GameState: cannot open roster directory: " + roster_path)
		# Emit defeat so the game doesn't silently start with zero player units
		var bus := get_node_or_null("/root/EventBus")
		if bus:
			bus.map_defeat.emit()
		return
	# Load in filename order so slot numbering stays consistent
	var files: Array[String] = []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".tres"):
			files.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	files.sort()
	for f in files:
		# load() can return null for a corrupt .tres even though the file exists;
		# null-check before .duplicate() so a bad file is skipped, not a crash.
		var loaded := load(roster_path + f)
		if loaded == null:
			push_error("GameState: failed to load roster file '%s' — skipping" % f)
			continue
		var res: UnitData = loaded.duplicate(true)
		if res:
			# push_error + continue (not assert) so a bad .tres is skipped in
			# release builds, where assert() is stripped.
			if res.unit_id == "":
				push_error("GameState: roster file '%s' has empty unit_id — set it in the .tres" % f)
				continue
			var dm := get_node_or_null("/root/DataManager")
			if dm != null and not dm.get_all_classes().is_empty():
				var unit_errors: Array[String] = dm.validate_unit_data(res)
				if not unit_errors.is_empty():
					for err in unit_errors:
						push_error(err)
					continue
			player_roster.append(res)


# Deep-copies all player UnitData fields into _map_start_snapshot.
# Call once immediately after units are spawned on the map.
func take_map_snapshot() -> void:
	_map_start_snapshot.clear()
	for unit_data in player_roster:
		_map_start_snapshot.append(_snapshot_unit_data(unit_data))
	_snapshot_party_gold = party_gold
	_snapshot_party_items = party_items.duplicate()


# Restores player_roster UnitData from snapshot, then reloads the current scene.
# Called by GameOverScreen's Retry button.
func restore_map_snapshot() -> void:
	for i in player_roster.size():
		if i < _map_start_snapshot.size():
			_restore_unit_data(player_roster[i], _map_start_snapshot[i])
	# Roll the party economy back too, so a replayed map can't re-grant its rewards.
	party_gold = _snapshot_party_gold
	party_items = _snapshot_party_items.duplicate()
	reset_map_state()
	# Caller is responsible for reloading the scene after this returns.


func _snapshot_unit_data(data: UnitData) -> Dictionary:
	# Snapshot only the fields that can change during a map.
	# Phase 2 runtime state (modifiers, conditions, counters) is included so a
	# mid-battle suspend save can serialize everything without scene tree traversal.
	# Deep-copy each InventoryEntry individually: Array.duplicate(true) copies the
	# array but shares the Resource references, so combat use/durability would
	# otherwise mutate the snapshot and break a Retry.
	var inventory_copy: Array = []
	for entry in data.inventory:
		inventory_copy.append(entry.duplicate(true) if entry != null else null)
	return {
		"tile_position": data.tile_position,
		"class_id": data.class_id,
		"hp": data.hp,
		"max_hp": data.max_hp,
		"strength": data.strength,
		"magic": data.magic,
		"defense": data.defense,
		"resistance": data.resistance,
		"skill": data.skill,
		"speed": data.speed,
		"luck": data.luck,
		"exp": data.exp,
		"level": data.level,
		"effective_level": data.effective_level,
		"is_promoted": data.is_promoted,
		"class_line_id": data.class_line_id,
		"weapon_wexp": data.weapon_wexp.duplicate(true),
		"inventory": inventory_copy,
		"conditions": data.conditions.duplicate(true),
		"skills": data.skills.duplicate(true),
		"earned_skills": data.earned_skills.duplicate(true),
		"mastery_skills": data.mastery_skills.duplicate(true),
		"is_incapacitated": data.is_incapacitated,
		# Phase 2 runtime state
		"active_modifiers": data.active_modifiers.duplicate(true),
		"skill_use_counters": data.skill_use_counters.duplicate(true),
		"damage_taken_this_map": data.damage_taken_this_map,
		"growth_accumulators": data.growth_accumulators.duplicate(true),
		"shift_gauge": data.shift_gauge,
		"is_shifted": data.is_shifted,
	}


func _restore_unit_data(data: UnitData, snap: Dictionary) -> void:
	# Use .get() with defaults so older snapshots missing newer fields don't crash.
	data.tile_position = snap.get("tile_position", Vector2i.ZERO)
	data.class_id = snap.get("class_id", data.class_id)
	data.hp = snap.get("hp", data.max_hp)
	data.max_hp = snap.get("max_hp", data.max_hp)
	data.strength = snap.get("strength", data.strength)
	data.magic = snap.get("magic", data.magic)
	data.defense = snap.get("defense", data.defense)
	data.resistance = snap.get("resistance", data.resistance)
	data.skill = snap.get("skill", data.skill)
	data.speed = snap.get("speed", data.speed)
	data.luck = snap.get("luck", data.luck)
	data.exp = snap.get("exp", 0)
	data.level = snap.get("level", data.level)
	data.effective_level = snap.get("effective_level", data.effective_level)
	data.is_promoted = snap.get("is_promoted", data.is_promoted)
	data.class_line_id = snap.get("class_line_id", data.class_line_id)
	data.weapon_wexp = snap.get("weapon_wexp", {}).duplicate(true)
	# Deep-copy each InventoryEntry on restore too, so repeated Retries each get a
	# fresh copy rather than aliasing the one stored in the snapshot.
	data.inventory.clear()
	for entry in snap.get("inventory", []):
		data.inventory.append(entry.duplicate(true) if entry != null else null)
	data.conditions = snap.get("conditions", []).duplicate(true)
	data.skills = snap.get("skills", []).duplicate(true)
	data.earned_skills = snap.get("earned_skills", []).duplicate(true)
	data.mastery_skills = snap.get("mastery_skills", []).duplicate(true)
	data.is_incapacitated = snap.get("is_incapacitated", false)
	# Phase 2 runtime state
	# Default is [] — active_modifiers is Array[Dictionary]; an older snapshot missing
	# the key must fall back to an empty Array, not an empty Dictionary.
	data.active_modifiers = snap.get("active_modifiers", []).duplicate(true)
	data.skill_use_counters = snap.get("skill_use_counters", {}).duplicate(true)
	data.damage_taken_this_map = snap.get("damage_taken_this_map", 0)
	data.growth_accumulators = snap.get("growth_accumulators", {}).duplicate(true)
	data.shift_gauge = snap.get("shift_gauge", 0.0)
	data.is_shifted = snap.get("is_shifted", false)
