extends Node
# [NOTE — M-1] class_name cannot be used on autoload scripts in Godot 4, even with a
# name that differs from the autoload name — Godot refuses to register the class_name.
# Retry snapshots are in-memory map-start checkpoints. Active-map suspend now uses
# SaveData and captures live units for every faction; future terrain/object mutation
# fields should join the same map_runtime section when those systems land.

const ResourceManifest = preload("res://scripts/shared/ResourceManifest.gd")
const SaveCodec = preload("res://scripts/save/SaveCodec.gd")
const SaveDataScript = preload("res://scripts/save/SaveData.gd")
const CampaignRuleSchema = preload("res://scripts/save/CampaignRuleSchema.gd")
const CampaignRulesScript = preload("res://scripts/resources/CampaignRules.gd")
const MutableCampaignStateScript = preload("res://scripts/resources/MutableCampaignState.gd")
const MapLedgerScript = preload("res://scripts/save/MapLedger.gd")

enum Phase { PLAYER, ENEMY }

# ── M14 stage 2: alliance-group hostility model ──────────────────────────────
# A faction's id maps to an alliance group; two units are hostile iff they
# belong to different groups. Captures the GDD relationships exactly with one
# table instead of a 4x4 pairwise matrix (and trivially extends to a 5th+
# faction — add it to the dict).
#
# Default groups (per [GDD-02-CORE-MECHANICS], Faction Hostility):
#   {blue, green} — the player's alliance
#   {red}         — the standing enemy
#   {yellow}      — the rogue that fights everyone
#
# Stage 3 will replace this constant with data read from each map's
# FactionData[] so a map can override groupings; the constant stays as the
# fallback for tests / headless code paths that don't set a MapData.
const _DEFAULT_ALLIANCE_GROUPS: Dictionary = {
	"blue": "allies",
	"green": "allies",
	"red": "foes",
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

# Per-save gameplay rules. Defaults cover direct-boot development maps until the
# campaign selector seeds this from authored CampaignData.
var campaign_rules: CampaignRules = CampaignRulesScript.make_default()
var mandated_campaign_rules: Array[String] = []
var mutable_campaign_state: MutableCampaignState = MutableCampaignStateScript.new()
var per_map_rule_overrides: Dictionary = {}
var active_mid_map_rule_overrides: Dictionary = {}
var _authored_campaign_rule_values: Dictionary = {}

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
var _debug_hotseat_override_v: bool = false

var debug_force_levelup: bool:  # #10: any landed hit awards a full level
	get:
		return _debug_force_levelup_v
	set(v):
		if _debug_force_levelup_v == v:
			return
		_debug_force_levelup_v = v
		_emit_debug_flags_changed()
var debug_growth_boost: bool:  # #11: +300 to every growth rate on level-up
	get:
		return _debug_growth_boost_v
	set(v):
		if _debug_growth_boost_v == v:
			return
		_debug_growth_boost_v = v
		_emit_debug_flags_changed()
var debug_hotseat_override: bool:  # F9: temporarily drive all factions by hotseat
	get:
		return _debug_hotseat_override_v
	set(v):
		if _debug_hotseat_override_v == v:
			return
		_debug_hotseat_override_v = v
		_emit_debug_flags_changed()


# Routes the setter notification through EventBus when it is available. Null-
# guarded because GameState's _init can run before EventBus is wired in headless
# --script tests that don't load every autoload.
func _emit_debug_flags_changed() -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("debug_flags_changed"):
		bus.debug_flags_changed.emit()


# Debug hotkey handler. F10 toggles debug_force_levelup, F11 toggles
# debug_growth_boost, and F9 toggles all-faction hotseat override. Gated on
# OS.is_debug_build() so the action firing in a release build is a no-op even
# if the input binding remains registered — matches the existing gate on the
# flags themselves (callers check the same).
# Actions are absent from the SettingsScreen keybinding list in release per
# the OS.is_debug_build() filter in _populate_keybindings.
func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event.is_action_pressed("debug_toggle_force_levelup"):
		debug_force_levelup = not debug_force_levelup
	elif event.is_action_pressed("debug_toggle_growth_boost"):
		debug_growth_boost = not debug_growth_boost
	elif event.is_action_pressed("debug_toggle_hotseat_override"):
		debug_hotseat_override = not debug_hotseat_override


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
var battle_data: ResolvedBattleData = null
# Encounter payload retained under the historical name for UI/TurnManager consumers.
var map_data: Resource = null

# Persists between maps — the live roster and shared economy
var player_roster: Array[UnitData] = []
var party_gold: int = 0
var party_items: Array[String] = []  # item IDs awarded by completed maps
# Explicit roster-launch state. This separates "roster was never prepared",
# "roster prep failed", and "roster is ready for the selected launch policy".
var roster_initialized: bool = false
var roster_load_failed: bool = false
var active_roster_policy: String = ""
var active_roster_source: String = ""
# New Game / map-select launch state. The selected map path persists so retries
# and direct scene reloads stay on the same map until another selection is made.
var next_map_data_path: String = ""
var next_map_roster_policy: String = ""
var next_map_roster_source: String = ""
# I/O-free suspend resume payload. SaveManager will eventually populate this
# from disk; GameMap consumes it to spawn from live unit state instead of
# authored placements.
var next_map_suspend_payload: Dictionary = {}
# B4-PREP-DEPLOYMENT: the explicit deployment chosen at prep — unit_id -> player
# start tile. EMPTY means no prep screen ran, and GameMap keeps its historical
# roster-order inference, so the bare single-map launch behaves exactly as it did
# before prep existed.
#
# Deliberately NOT persisted: a campaign save is parked BETWEEN maps, so a reload
# lands back on prep and the player deploys again (the same reasoning that keeps
# the pending map result out of the save). It DOES survive a Retry, which reloads
# the map scene without reconfiguring the launch — so a replay redeploys the units
# the player actually chose, rather than silently falling back to roster order.
var next_map_deployment: Dictionary = {}

# B1-LEDGER Phase 2: the within-map decaying ledger — an ordered list of
# SUSPEND-COMPLETE entries (all factions' units + party economy + turn state +
# cursor + RNG timeline + Pair Up), the same board format a suspend save carries.
# Index 0 is the round-0 boundary a Retry rewinds to (restore_history(0)); the
# two-tier prune keeps a union of the last N activations and round-starts. Map-
# scoped: cleared in reset_map_state and re-seeded by the round-0 push in
# take_map_snapshot. See scripts/save/MapLedger.gd.
var _map_ledger: RefCounted = MapLedgerScript.new()
var _rewind_configure_override: Callable
var rewind_charges_left: int = 0


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


# Returns the registered Unit Node whose data.unit_id matches the given id,
# or null if no live unit carries that id. Empty / unknown ids return null.
# Walks all_units rather than the per-faction buckets because Pair Up callers
# need the lookup to work even when the support is off-map; faction filtering
# is incidental, identity is not.
func find_unit_by_id(unit_id: String) -> Node:
	if unit_id == "":
		return null
	for u in all_units:
		if is_instance_valid(u) and u.data != null and u.data.unit_id == unit_id:
			return u
	return null


# M14 stage 3: living units of an arbitrary faction. filter() returns a generic
# Array, so build Array[Node] explicitly. A missing faction returns [].
#
# Paired supports are excluded: while a unit is the support side of a Pair Up
# its tile_position is the OFF_MAP_TILE sentinel, the player cannot select it,
# and its lead has already consumed the joint action. Counting it as "living"
# here inflated are_all_units_done so auto-end-turn never fired, and made
# MapCursor._cycle_to_next_unit Tab onto the (-1, -1) sentinel. Liveness
# queries that need every unit alive regardless of pair role (objective
# evaluators) already use find_unit_by_id / escape records, not this method.
func get_living_units_of(faction_id: String) -> Array[Node]:
	var result: Array[Node] = []
	var bucket: Array[Node] = _units_by_faction.get(faction_id, [] as Array[Node])
	var reg := get_node_or_null("/root/PairUpRegistry")
	for u in bucket:
		if not is_instance_valid(u) or u.data == null or u.data.hp <= 0:
			continue
		if reg != null and u.data.unit_id != "" and reg.call("is_support", u.data.unit_id):
			continue
		result.append(u)
	return result


# True liveness of a faction, INCLUDING paired supports. Objective evaluators
# (rout victory/defeat) must count a hidden support as a living member — a pair's
# support is still an undefeated unit even though it sits off-map. This differs
# from get_living_units_of, which deliberately drops supports for unit selection,
# Tab cycling, and are_all_units_done accounting. Mixing the two let an
# allied/enemy Rout resolve while a support was still alive (playtest v0.1.4 #4).
func get_all_living_units_of(faction_id: String) -> Array[Node]:
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
		for u in _units_by_faction[fid] as Array[Node]:
			if is_instance_valid(u) and u.data != null and u.data.hp > 0:
				result.append(u)
	return result


func is_player_turn() -> bool:
	return current_phase == Phase.PLAYER


func reset_map_state() -> void:
	var campaign_var_store := get_node_or_null("/root/CampaignVars")
	if campaign_var_store != null:
		campaign_var_store.call("reset_map_scope")
	all_units.clear()
	_units_by_faction.clear()
	map_data = null
	battle_data = null
	turn_number = 1
	current_phase = Phase.PLAYER
	# B1-LEDGER: the within-map ledger is map-scoped — drop it between maps so a
	# new map starts with a fresh ledger (take_map_snapshot re-seeds the round-0 entry).
	_map_ledger.clear()
	rewind_charges_left = 0
	# Pair Up state is map-scoped; drop pairings between maps so a new map
	# starts unpaired regardless of how the previous one ended.
	var reg := get_node_or_null("/root/PairUpRegistry")
	if reg:
		reg.call("clear")


func configure_next_map(
	map_path: String, roster_policy: String = "default_roster", roster_source: String = ""
) -> void:
	next_map_data_path = map_path
	next_map_roster_policy = roster_policy
	next_map_roster_source = roster_source
	next_map_suspend_payload.clear()
	# Selecting a map invalidates any plan authored against the previous one — its
	# tiles belonged to a different board. Prep stages its plan AFTER this call.
	next_map_deployment.clear()


# Stages the prep screen's deployment for the next launch. Copied, so prep can
# keep editing its working plan without mutating what GameMap will spawn.
func set_next_map_deployment(plan: Dictionary) -> void:
	next_map_deployment = plan.duplicate(true)


func clear_next_map_deployment() -> void:
	next_map_deployment.clear()


func configure_suspend_resume(source: Variant, restore_event: String = "campaign_restored") -> bool:
	var save: RefCounted = source if source is SaveData else SaveDataScript.from_dict(source)
	if save == null:
		return false
	var payload: Dictionary = save.to_dict()
	var map_runtime: Dictionary = payload.get("map_runtime", {})
	var map_path: String = String(map_runtime.get("map_path", ""))
	if map_path == "":
		push_error("GameState: suspend payload is missing map_runtime.map_path")
		return false
	if not _activate_saved_campaign_source(payload.get("campaign", {})):
		return false
	var staged_ledger := MapLedgerScript.new()
	if not staged_ledger.restore_from_save(payload.get("ledger", [])):
		push_error("GameState: suspend payload carries a malformed rewind ledger")
		return false
	var restored_items: Array[String] = _party_items_from_convoy_entries(
		payload.get("party", {}).get("convoy", {}).get("entries", [])
	)
	if (
		restored_items.is_empty()
		and not payload.get("party", {}).get("convoy", {}).get("entries", []).is_empty()
	):
		return false
	var campaign_dict: Dictionary = payload.get("campaign", {})
	if String(campaign_dict.get("campaign_id", "")) != "":
		var cm := get_node_or_null("/root/CampaignManager")
		if (
			cm == null
			or not cm.has_method("restore_campaign_state")
			or not bool(cm.call("restore_campaign_state", campaign_dict, restore_event))
		):
			push_error("GameState: suspend campaign envelope could not be restored")
			return false
		# A between-map restore clears the launched node and re-launches; a suspend
		# resume boots straight into the live map, so re-mark the node as launched
		# here or the eventual map result is orphaned and lost (V053-01).
		if cm.has_method("resume_launched_node"):
			cm.call("resume_launched_node")
	_apply_campaign_rules_dict(payload.get("campaign", {}).get("rules", {}))
	if not restore_mutable_campaign_state(campaign_dict):
		push_error("GameState: suspend mutable campaign state is malformed")
		return false
	party_gold = int(payload.get("party", {}).get("resources", {}).get("party_gold", party_gold))
	party_items = restored_items
	player_roster = _player_roster_from_runtime_units(map_runtime.get("units", []))
	roster_initialized = not player_roster.is_empty()
	roster_load_failed = player_roster.is_empty()
	active_roster_policy = "suspend_resume"
	active_roster_source = map_path
	next_map_data_path = map_path
	next_map_roster_policy = "suspend_resume"
	next_map_roster_source = map_path
	next_map_suspend_payload = payload.duplicate(true)
	_map_ledger = staged_ledger
	var saved_charges := int(
		map_runtime.get("rewind_charges_left", campaign_rules.rewind_charges_per_map)
	)
	rewind_charges_left = -1 if saved_charges < 0 else maxi(0, saved_charges)
	# A suspend resume rebuilds the board from the serialized live units, so any
	# staged plan is stale — it described a fresh deployment, not a map in progress.
	next_map_deployment.clear()
	return true


func clear_suspend_resume() -> void:
	next_map_suspend_payload.clear()
	# The roster was rebuilt from the payload (player_roster above), so once the
	# payload is consumed the "suspend_resume" launch policy is stale: a later
	# reload (e.g. defeat -> Retry) finds an empty payload and is_roster_ready_
	# for_launch() fails, aborting the spawn and leaving an empty board (V053-02).
	# Normalize to keep_current_roster so the live roster stays launch-ready.
	if next_map_roster_policy == "suspend_resume":
		next_map_roster_policy = "keep_current_roster"


# Loads the 6 default roster UnitData .tres files into player_roster.
# Called by MainMenu on "New Game" for MVP.
func load_default_roster() -> bool:
	return load_roster_from_directory("res://data/roster/default/", "default_roster")


func load_roster_from_directory(
	roster_path: String, roster_policy: String = "fixed_test_roster"
) -> bool:
	_clear_roster_launch_state()
	var resource_paths: Array[String] = ResourceManifest.load_paths(roster_path)
	if resource_paths.is_empty():
		push_error("GameState: cannot open roster directory: " + roster_path)
		roster_load_failed = true
		return false
	var loaded_roster: Array[UnitData] = []
	var had_errors: bool = false
	for res_path in resource_paths:
		# load() can return null for a corrupt .tres even though the file exists;
		# null-check before .duplicate() so a bad file is skipped, not a crash.
		var loaded := load(res_path)
		if loaded == null:
			push_error("GameState: failed to load roster file '%s' — skipping" % res_path)
			had_errors = true
			continue
		# Explicit type check before the typed-variable assignment below: a stray
		# non-UnitData resource (e.g. ClassData accidentally saved here) would
		# otherwise trigger a typed-assignment crash rather than the friendly
		# skip path. Code review 2026-06-09 issue #4.
		if not (loaded is UnitData):
			push_error("GameState: roster file '%s' is not UnitData — skipping" % res_path)
			had_errors = true
			continue
		var res: UnitData = loaded.duplicate(true)
		if res:
			# push_error + continue (not assert) so a bad .tres is skipped in
			# release builds, where assert() is stripped.
			if res.unit_id == "":
				push_error(
					"GameState: roster file '%s' has empty unit_id — set it in the .tres" % res_path
				)
				had_errors = true
				continue
			var dm := get_node_or_null("/root/DataManager")
			if dm != null and not dm.get_all_classes().is_empty():
				var unit_errors: Array[String] = dm.validate_unit_data(res)
				if not unit_errors.is_empty():
					for err in unit_errors:
						push_error(err)
					had_errors = true
					continue
			loaded_roster.append(res)
	if had_errors or loaded_roster.is_empty():
		if loaded_roster.is_empty():
			push_error("GameState: roster load produced no valid units from '%s'" % roster_path)
		player_roster.clear()
		roster_load_failed = true
		return false
	player_roster = loaded_roster
	roster_initialized = true
	active_roster_policy = roster_policy
	active_roster_source = roster_path
	return true


# Runtime-source counterpart to directory loading. Tier-2 packs are parsed into
# UnitData in memory and never materialized as generated .tres files.
func load_roster_resources(source: Array, roster_policy: String, roster_source: String) -> bool:
	_clear_roster_launch_state()
	var loaded_roster: Array[UnitData] = []
	for value in source:
		if not value is UnitData or String(value.unit_id).is_empty():
			push_error("GameState: runtime roster contains an invalid UnitData")
			roster_load_failed = true
			return false
		loaded_roster.append((value as UnitData).duplicate(true))
	if loaded_roster.is_empty():
		push_error("GameState: runtime roster '%s' is empty" % roster_source)
		roster_load_failed = true
		return false
	player_roster = loaded_roster
	roster_initialized = true
	active_roster_policy = roster_policy
	active_roster_source = roster_source
	return true


func is_roster_ready_for_launch() -> bool:
	if roster_load_failed or not roster_initialized:
		return false
	match next_map_roster_policy:
		"default_roster":
			return (
				active_roster_policy == "default_roster"
				and active_roster_source == "res://data/roster/default/"
				and not player_roster.is_empty()
			)
		"fixed_test_roster":
			return (
				next_map_roster_source != ""
				and active_roster_policy == "fixed_test_roster"
				and active_roster_source == next_map_roster_source
				and not player_roster.is_empty()
			)
		"campaign_pack_roster":
			return (
				next_map_roster_source != ""
				and active_roster_policy == "campaign_pack_roster"
				and active_roster_source == next_map_roster_source
				and not player_roster.is_empty()
			)
		"keep_current_roster":
			return not player_roster.is_empty()
		"suspend_resume":
			return not next_map_suspend_payload.is_empty()
		_:
			return false


func _clear_roster_launch_state() -> void:
	player_roster.clear()
	roster_initialized = false
	roster_load_failed = false
	active_roster_policy = ""
	active_roster_source = ""


func capture_save(
	save_label: String = "", turn_manager: Node = null, cursor: Node = null
) -> RefCounted:
	if turn_manager != null:
		var mid_map := capture_suspend_save(turn_manager, cursor)
		if mid_map != null:
			mid_map.save_label = save_label
		return mid_map
	return capture_campaign_save(save_label)


func get_save_slot_classes() -> Array[Dictionary]:
	return campaign_rules.save_slot_classes.duplicate(true)


func apply_campaign_rule_overrides(overrides: Variant, mandated_rules: Variant = []) -> void:
	mutable_campaign_state = MutableCampaignStateScript.new()
	per_map_rule_overrides.clear()
	active_mid_map_rule_overrides.clear()
	mandated_campaign_rules = SaveCodec.string_array_from_variant(mandated_rules)
	if overrides is Dictionary and not overrides.is_empty():
		var merged := _campaign_rules_to_dict()
		for key in overrides:
			merged[key] = overrides[key]
		_apply_campaign_rules_dict(merged)


func is_campaign_rule_mandated(rule_id: String) -> bool:
	return rule_id in mandated_campaign_rules


# New Game calls this after applying editable player choices. From then on,
# temporary/effective mirroring must not rewrite the persisted bottom layer.
func commit_current_campaign_rules_as_defaults() -> void:
	_authored_campaign_rule_values = _campaign_rules_to_dict()


# Three-layer open resolver: triggered mid-map > node/map > effective campaign
# default. A mandate freezes the authored campaign value above both overlays.
func get_effective_campaign_rule(rule_id: String, fallback: Variant = null) -> Variant:
	var defaults := (
		_authored_campaign_rule_values
		if not _authored_campaign_rule_values.is_empty()
		else _campaign_rules_to_dict()
	)
	var value: Variant = defaults.get(rule_id, fallback)
	if not is_campaign_rule_mandated(rule_id) and mutable_campaign_state.has_patch(rule_id):
		value = mutable_campaign_state.patched_value(rule_id, value)
	if is_campaign_rule_mandated(rule_id):
		return value
	if per_map_rule_overrides.has(rule_id):
		value = per_map_rule_overrides[rule_id]
	if active_mid_map_rule_overrides.has(rule_id):
		value = active_mid_map_rule_overrides[rule_id]
	return value


func get_campaign_rule_summary() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	# Show the entire effective ruleset, including engine defaults the campaign
	# author did not override. Authored values influence authority/effective value,
	# not whether a live rule disappears from the player's read-only view.
	var ids: Array = _campaign_rules_to_dict().keys()
	for rule_id in _authored_campaign_rule_values:
		if rule_id not in ids:
			ids.append(rule_id)
	ids.sort()
	for rule_id in ids:
		if String(rule_id) == "mandated_rules":
			continue
		(
			rows
			. append(
				{
					"rule_id": String(rule_id),
					"value": get_effective_campaign_rule(String(rule_id)),
					"mandated": is_campaign_rule_mandated(String(rule_id)),
				}
			)
		)
	return rows


func begin_campaign_map_rules(overrides: Variant) -> bool:
	if not (overrides is Dictionary):
		return false
	per_map_rule_overrides.clear()
	active_mid_map_rule_overrides.clear()
	for rule_id in overrides:
		if (
			not (rule_id is String)
			or String(rule_id) == ""
			or is_campaign_rule_mandated(String(rule_id))
		):
			continue
		per_map_rule_overrides[rule_id] = overrides[rule_id]
	_sync_all_effective_rules()
	return true


func end_campaign_map_rules() -> void:
	var affected: Array = per_map_rule_overrides.keys()
	for rule_id in active_mid_map_rule_overrides:
		if not rule_id in affected:
			affected.append(rule_id)
	per_map_rule_overrides.clear()
	active_mid_map_rule_overrides.clear()
	for rule_id in affected:
		_apply_effective_rule_to_live(String(rule_id))


func apply_rule_flip(
	rule_id: String, value: Variant, reason: String, revert_scope: String = "end_of_map"
) -> bool:
	if (
		rule_id == ""
		or revert_scope not in ["end_of_map", "permanent"]
		or is_campaign_rule_mandated(rule_id)
	):
		return false
	if revert_scope == "permanent":
		if not mutable_campaign_state.append_rule_patch(rule_id, value, reason):
			return false
	else:
		active_mid_map_rule_overrides[rule_id] = value
	_apply_effective_rule_to_live(rule_id)
	var bus := get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("campaign_rule_flipped"):
		bus.emit_signal("campaign_rule_flipped", rule_id, value, reason, revert_scope)
	return true


func capture_mutable_campaign_state() -> Dictionary:
	return {
		"mutable_state": mutable_campaign_state.to_dict(),
		"per_map_overrides": per_map_rule_overrides.duplicate(true),
		"active_mid_map_overrides": active_mid_map_rule_overrides.duplicate(true),
	}


func restore_mutable_campaign_state(campaign: Dictionary) -> bool:
	var staged := MutableCampaignStateScript.new()
	if not staged.apply_dict(campaign.get("mutable_state", {})):
		return false
	var per_map: Variant = campaign.get("per_map_overrides", {})
	var mid_map: Variant = campaign.get("active_mid_map_overrides", {})
	if not (per_map is Dictionary) or not (mid_map is Dictionary):
		return false
	mutable_campaign_state = staged
	per_map_rule_overrides = per_map.duplicate(true)
	active_mid_map_rule_overrides = mid_map.duplicate(true)
	_sync_all_effective_rules()
	return true


func _sync_all_effective_rules() -> void:
	var rule_ids: Dictionary = {}
	for patch in mutable_campaign_state.rule_patches:
		rule_ids[String(patch.get("rule_id", ""))] = true
	for rule_id in per_map_rule_overrides:
		rule_ids[rule_id] = true
	for rule_id in active_mid_map_rule_overrides:
		rule_ids[rule_id] = true
	for rule_id in rule_ids:
		_apply_effective_rule_to_live(String(rule_id))


# Existing systems read typed CampaignRules properties directly. Mirror an
# effective data-layer value into a matching property so the resolver governs
# those call sites without a closed rule-id switch. death_mode is the one legacy
# serialized alias and is normalized at the save boundary.
func _apply_effective_rule_to_live(rule_id: String) -> void:
	var value: Variant = get_effective_campaign_rule(rule_id)
	if rule_id == "death_mode":
		campaign_rules.permadeath_enabled = String(value) == "classic"
		return
	for property in campaign_rules.get_property_list():
		if String(property.get("name", "")) == rule_id:
			campaign_rules.set(rule_id, value)
			return


func capture_suspend_save(turn_manager: Node, cursor: Node = null) -> RefCounted:
	var save: RefCounted = SaveDataScript.new()
	_capture_campaign_package_identity(save.campaign)
	var cm := get_node_or_null("/root/CampaignManager")
	if cm != null and cm.has_method("capture_campaign_state"):
		var envelope: Dictionary = cm.call("capture_campaign_state")
		if String(envelope.get("campaign_id", "")) != "":
			save.campaign["campaign_id"] = String(envelope.get("campaign_id", ""))
			save.campaign["node_id"] = String(envelope.get("node_id", ""))
			save.campaign["cleared_nodes"] = SaveCodec.string_array_from_variant(
				envelope.get("cleared_nodes", [])
			)
			save.campaign["flags"] = SaveCodec.string_array_from_variant(envelope.get("flags", []))
			save.campaign["vars"] = envelope.get("vars", {}).duplicate(true)
	save.campaign["rules"] = _campaign_rule_defaults_to_dict()
	_write_mutable_campaign_state(save.campaign)
	save.party["resources"]["party_gold"] = party_gold
	save.party["convoy"]["entries"] = _party_items_to_convoy_entries()
	save.roster["units"] = []
	for unit_data in player_roster:
		if unit_data != null:
			save.roster["units"].append(unit_data_to_runtime_dict(unit_data, "blue"))

	# The map board itself comes from the shared ledger codec, so a suspend save
	# and a history entry serialize the live board identically. Merge its keys onto
	# the SaveData section defaults (rather than replacing the dicts) so every
	# default key SaveData seeds — vars/flags/objects/... — survives; the codec sets
	# exactly the keys the old inline block set, so the document is byte-identical.
	var entry: Dictionary = _capture_map_runtime_entry(turn_manager, cursor)
	for key in entry["map_runtime"]:
		save.map_runtime[key] = entry["map_runtime"][key]
	for key in entry["suspend"]:
		save.suspend[key] = entry["suspend"][key]
	save.ledger = _map_ledger.to_save_array()
	return SaveDataScript.from_dict(save.to_dict())


# B1-LEDGER Phase 1: the reusable SUSPEND-COMPLETE board serializer. Returns the
# two save-document sub-blocks that describe a live map at one instant — the map
# runtime (all factions' units, turn state, Pair Up carry, RNG timeline) and the
# suspend UI block (cursor + threat views). capture_suspend_save composes this with
# the campaign/party/roster layers; the ledger stores it verbatim as one history
# entry, so a mid-map rewind and a suspend save read the SAME board format.
# turn_manager/cursor are optional: at the round-0 push they are not yet
# started/placed, so their fields fall back to defaults (a scene reload
# regenerates turn state and cursor for Retry anyway).
func _capture_map_runtime_entry(turn_manager: Node, cursor: Node) -> Dictionary:
	var reg := get_node_or_null("/root/PairUpRegistry")
	var rng_svc := get_node_or_null("/root/RngService")
	var map_runtime: Dictionary = {
		"map_id":
		battle_data.source_id if battle_data != null else (map_data.id if map_data != null else ""),
		"map_path": _current_map_path(),
		"units": _runtime_units_to_array(),
		"turn":
		(
			turn_manager.call("capture_suspend_turn_state")
			if turn_manager != null and turn_manager.has_method("capture_suspend_turn_state")
			else {}
		),
		"pair_carry": {"pair_up": reg.call("serialize") if reg else {}},
		"rng": rng_svc.call("to_save_dict") if rng_svc else {},
		"rewind_charges_left": rewind_charges_left,
	}
	var suspend_ui: Dictionary = (
		cursor.call("capture_suspend_ui_state")
		if cursor != null and cursor.has_method("capture_suspend_ui_state")
		else {}
	)
	var suspend: Dictionary = {
		"kind": "map",
		"cursor_tile": suspend_ui.get("cursor_tile", null),
		"mode": suspend_ui.get("mode", "free"),
		"threat_views_version": suspend_ui.get("threat_views_version", 1),
		"threat_views_by_faction": suspend_ui.get("threat_views_by_faction", {}),
	}
	# B1-LEDGER Phase 2 (DECIDED 2026-07-15): party economy lives PER LEDGER ENTRY.
	# Folding gold/items/roster into the entry makes it self-sufficient — a Retry
	# (restore_history(0)) rolls the party back exactly as the old snapshot path did,
	# and a mid-map rewind (Phase 3) correctly undoes a village/chest reward earned
	# earlier in the map. The roster snapshot mirrors the old _map_start_snapshot
	# array (one _snapshot_unit_data dict per player unit, in roster order) so the
	# restore is byte-for-byte the same operation, just sourced from the ledger.
	var party: Dictionary = {
		"gold": party_gold,
		"items": party_items.duplicate(),
		"roster": _player_roster_snapshot_array(),
	}
	return {
		"map_runtime": map_runtime,
		"suspend": suspend,
		"party": party,
		"campaign_rules_state": capture_mutable_campaign_state(),
	}


# The player roster serialized as _snapshot_unit_data dicts in roster order — the
# Retry-restore source folded into every ledger entry (see _capture_map_runtime_entry).
func _player_roster_snapshot_array() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for unit_data in player_roster:
		out.append(_snapshot_unit_data(unit_data))
	return out


# B1-LEDGER Phase 2: append one SUSPEND-COMPLETE entry to the within-map ledger
# under `reason` (round-start by default — the round-0 seed and every round
# boundary; per-activation pushes pass MapLedger.REASON_ACTIVATION). turn_manager/
# cursor are optional (absent at the round-0 push). Live per-activation pushing and
# the prune call sites arrive with Rewind in Phase 3; the ledger machinery and its
# prune are built and unit-tested here.
func push_history(
	turn_manager: Node = null,
	cursor: Node = null,
	reason: String = MapLedgerScript.REASON_ROUND_START,
	metadata: Dictionary = {}
) -> void:
	_map_ledger.push(_capture_map_runtime_entry(turn_manager, cursor), reason, metadata)


func history_size() -> int:
	return _map_ledger.size()


# Returns a deep copy of the ledger entry at index (0 = the round-0 boundary), or
# {} if out of range, so a caller — a test, the Phase 1 measurement, or Retry's
# restore_history — reads an entry without mutating the stored ledger.
func peek_history(index: int) -> Dictionary:
	return _map_ledger.peek(index)


# Decay the ledger to the campaign's undo budgets (see MapLedger.prune). The round-0
# boundary is always retained. Called after each live push once Phase 3 wires them.
func prune_history() -> void:
	var fine_keep := campaign_rules.undo_activations
	if campaign_rules.rewind_cost_mode == "full_history":
		fine_keep = MapLedgerScript.BUDGET_INFINITE
	elif campaign_rules.rewind_charges_per_map < 0:
		fine_keep = MapLedgerScript.BUDGET_INFINITE
	elif campaign_rules.rewind_charges_per_map > 0:
		fine_keep = maxi(fine_keep, campaign_rules.rewind_charges_per_map + 1)
	_map_ledger.prune(fine_keep, campaign_rules.undo_rounds)


func begin_map_rewind_budget() -> void:
	rewind_charges_left = (
		campaign_rules.rewind_charges_per_map
		if campaign_rules.rewind_charges_per_map < 0
		else maxi(0, campaign_rules.rewind_charges_per_map)
	)


func can_rewind() -> bool:
	return not rewind_options().is_empty()


func rewind_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	if rewind_charges_left == 0:
		return options
	var crossed := 0
	for index in range(_map_ledger.size() - 1, 0, -1):
		if _map_ledger.reason_at(index) != MapLedgerScript.REASON_ACTIVATION:
			continue
		crossed += 1
		var cost := 1 if campaign_rules.rewind_cost_mode == "full_history" else crossed
		if rewind_charges_left >= 0 and cost > rewind_charges_left:
			continue
		var metadata: Dictionary = _map_ledger.metadata_at(index)
		var unit_name := String(metadata.get("unit_name", metadata.get("unit_id", "Unit")))
		var start: Array = metadata.get("start", ["?", "?"])
		var finish: Array = metadata.get("end", ["?", "?"])
		(
			options
			. append(
				{
					"target_index": index - 1,
					"cost": cost,
					"label":
					(
						"%s  (%s,%s) → (%s,%s)  [%d charge%s]"
						% [
							unit_name,
							start[0],
							start[1],
							finish[0],
							finish[1],
							cost,
							"" if cost == 1 else "s"
						]
					),
				}
			)
		)
	return options


func rewind_last_action(turn_manager: Node, cursor: Node = null) -> bool:
	var options := rewind_options()
	if options.is_empty():
		return false
	return rewind_to_history(
		int(options[0]["target_index"]), int(options[0]["cost"]), turn_manager, cursor
	)


func rewind_to_history(
	target_index: int, cost: int, turn_manager: Node, cursor: Node = null
) -> bool:
	if cost <= 0 or target_index < 0 or target_index >= _map_ledger.size():
		return false
	if rewind_charges_left >= 0 and cost > rewind_charges_left:
		return false
	var entry: Dictionary = _map_ledger.peek(target_index)
	var errors: Array[String] = _validate_restore_entry(entry)
	if not errors.is_empty():
		for error in errors:
			push_error(error)
		return false
	var save: RefCounted = capture_suspend_save(turn_manager, cursor)
	if save == null:
		return false
	var payload: Dictionary = save.to_dict()
	payload["map_runtime"] = entry["map_runtime"].duplicate(true)
	payload["suspend"] = entry["suspend"].duplicate(true)
	var entry_party: Dictionary = entry["party"]
	payload["party"]["resources"]["party_gold"] = int(entry_party.get("gold", 0))
	payload["party"]["convoy"]["entries"] = _party_item_ids_to_convoy_entries(
		entry_party.get("items", [])
	)
	var restored_charges := -1 if rewind_charges_left < 0 else maxi(0, rewind_charges_left - cost)
	payload["map_runtime"]["rewind_charges_left"] = restored_charges
	var staged_ledger: Array[Dictionary] = _map_ledger.to_save_array_through(target_index)
	staged_ledger[target_index]["entry"]["map_runtime"]["rewind_charges_left"] = restored_charges
	payload["ledger"] = staged_ledger
	var accepted := (
		bool(_rewind_configure_override.call(payload))
		if _rewind_configure_override.is_valid()
		else configure_suspend_resume(payload)
	)
	if not accepted:
		return false
	# Commit the branch only after the staged durable payload has been accepted.
	# A malformed target therefore cannot destroy the still-playable future.
	_map_ledger.truncate_after(target_index)
	_map_ledger.set_map_runtime_value(target_index, "rewind_charges_left", restored_charges)
	rewind_charges_left = restored_charges
	return true


# The BETWEEN-map campaign save (B1-CST Slice 3): the party parked on a campaign
# node, with no live map. The counterpart to capture_suspend_save, which
# serializes a map in progress.
#
# map_runtime and suspend are deliberately left at their empty defaults. That is
# what distinguishes the two documents on load: a save with no map_runtime.map_path
# cannot be resumed into a board, and must route through the campaign launch path
# (CampaignManager.launch_current_node) instead.
func capture_campaign_save(save_label: String = "") -> RefCounted:
	var save: RefCounted = SaveDataScript.new()
	save.save_label = save_label
	var cm := get_node_or_null("/root/CampaignManager")
	if cm == null or not cm.has_method("capture_campaign_state"):
		push_error("GameState: CampaignManager cannot capture the campaign envelope")
		return null
	var envelope: Dictionary = cm.call("capture_campaign_state")
	_capture_campaign_package_identity(save.campaign)
	save.campaign["campaign_id"] = String(envelope.get("campaign_id", ""))
	save.campaign["node_id"] = String(envelope.get("node_id", ""))
	save.campaign["cleared_nodes"] = SaveCodec.string_array_from_variant(
		envelope.get("cleared_nodes", [])
	)
	save.campaign["flags"] = SaveCodec.string_array_from_variant(envelope.get("flags", []))
	save.campaign["vars"] = envelope.get("vars", {}).duplicate(true)
	save.campaign["rules"] = _campaign_rule_defaults_to_dict()
	_write_mutable_campaign_state(save.campaign)

	save.party["resources"]["party_gold"] = party_gold
	save.party["convoy"]["entries"] = _party_items_to_convoy_entries()
	save.roster["units"] = []
	for unit_data in player_roster:
		if unit_data != null:
			save.roster["units"].append(unit_data_to_runtime_dict(unit_data, "blue"))
	return SaveDataScript.from_dict(save.to_dict())


# Restores a between-map campaign save: the campaign position, the rules, and the
# party the player earned. Does NOT change scene — launching the parked node is
# CampaignManager's seam, so the caller (Continue / Load) decides when to leave
# the menu.
func configure_campaign_resume(source: Variant) -> bool:
	var save: RefCounted = source if source is SaveData else SaveDataScript.from_dict(source)
	if save == null:
		return false
	var payload: Dictionary = save.to_dict()
	var campaign_dict: Dictionary = payload.get("campaign", {})

	# Stage every value that can be checked against the current catalogues before
	# opening the content transaction. Campaign ids belong to the saved package,
	# so their final validation necessarily happens after that candidate activates.
	var roster: Array[UnitData] = _roster_from_save_units(
		payload.get("roster", {}).get("units", [])
	)
	if roster.is_empty():
		push_error("GameState: campaign save carries no player roster")
		return false
	var cm := get_node_or_null("/root/CampaignManager")
	if cm == null or not cm.has_method("restore_campaign_state"):
		push_error("GameState: CampaignManager is unavailable")
		return false
	var restored_items: Array[String] = _party_items_from_convoy_entries(
		payload.get("party", {}).get("convoy", {}).get("entries", [])
	)
	if (
		restored_items.is_empty()
		and not payload.get("party", {}).get("convoy", {}).get("entries", []).is_empty()
	):
		return false
	# Validate the final mutable-rule layer before package activation or campaign
	# position writes. This is the last independently fallible resume component.
	var staged_mutable := MutableCampaignStateScript.new()
	if (
		not staged_mutable.apply_dict(campaign_dict.get("mutable_state", {}))
		or not (campaign_dict.get("per_map_overrides", {}) is Dictionary)
		or not (campaign_dict.get("active_mid_map_overrides", {}) is Dictionary)
	):
		push_error("GameState: campaign save mutable state is malformed")
		return false

	# Package activation must precede campaign-id resolution, but it is itself a
	# live commit. Snapshot every owner in the outer transaction so any rejection
	# after this point restores one coherent prior campaign/content session.
	var dm := get_node_or_null("/root/DataManager")
	if dm == null or not dm.has_method("capture_content_session"):
		push_error("GameState: DataManager cannot snapshot campaign content")
		return false
	var prior_content: ContentSession = dm.call("capture_content_session")
	var prior_campaign: Dictionary = cm.call("capture_campaign_state")
	var prior_mutable: Dictionary = capture_mutable_campaign_state()
	var prior_rules: Dictionary = _campaign_rule_defaults_to_dict()
	if not _activate_saved_campaign_source(campaign_dict):
		return false
	if not bool(cm.call("restore_campaign_state", campaign_dict)):
		_rollback_campaign_resume(dm, cm, prior_content, prior_campaign, prior_mutable, prior_rules)
		return false  # CampaignManager already reported which id failed to resolve

	_apply_campaign_rules_dict(campaign_dict.get("rules", {}))
	if not restore_mutable_campaign_state(campaign_dict):
		push_error("GameState: campaign save mutable state is malformed")
		_rollback_campaign_resume(dm, cm, prior_content, prior_campaign, prior_mutable, prior_rules)
		return false
	party_gold = int(payload.get("party", {}).get("resources", {}).get("party_gold", 0))
	party_items = restored_items
	player_roster = roster
	roster_initialized = true
	roster_load_failed = false
	active_roster_policy = "campaign_resume"
	active_roster_source = ""
	# A slot load is not a suspend resume; drop any stale mid-map payload so the
	# next launch builds a fresh board, and any deployment staged for the run that
	# was in progress before the load.
	clear_suspend_resume()
	next_map_deployment.clear()
	return true


func _rollback_campaign_resume(
	dm: Node,
	cm: Node,
	prior_content: ContentSession,
	prior_campaign: Dictionary,
	prior_mutable: Dictionary,
	prior_rules: Dictionary
) -> void:
	dm.call("restore_content_session", prior_content)
	if not bool(cm.call("restore_campaign_state", prior_campaign, "campaign_resume_rollback")):
		push_error("GameState: failed to restore prior campaign after rejected resume")
	_apply_campaign_rules_dict(prior_rules)
	if not restore_mutable_campaign_state(prior_mutable):
		push_error("GameState: failed to restore prior mutable campaign state")


func _capture_campaign_package_identity(campaign: Dictionary) -> void:
	var dm := get_node_or_null("/root/DataManager")
	if dm == null or not dm.has_method("active_package_identity"):
		return
	var identity: Dictionary = dm.call("active_package_identity")
	campaign["package_id"] = String(identity.get("package_id", ""))
	campaign["package_version"] = String(identity.get("package_version", ""))
	var cm := get_node_or_null("/root/CampaignManager")
	var active: CampaignData = (
		cm.call("get_active_campaign")
		if cm != null and cm.has_method("get_active_campaign")
		else null
	)
	if active != null:
		campaign["protected_fields"] = active.protected_fields.duplicate()


func _write_mutable_campaign_state(campaign: Dictionary) -> void:
	var state := capture_mutable_campaign_state()
	campaign["mutable_state"] = state["mutable_state"]
	campaign["per_map_overrides"] = state["per_map_overrides"]
	campaign["active_mid_map_overrides"] = state["active_mid_map_overrides"]


# Content must be active before campaign/map/unit ids are resolved. Empty
# identity selects shipped content; a package identity resolves only through the
# service-owned installed root, never a caller-provided save path.
func _activate_saved_campaign_source(campaign: Dictionary) -> bool:
	var dm := get_node_or_null("/root/DataManager")
	if dm == null:
		push_error("GameState: DataManager is unavailable for campaign source restore")
		return false
	if not dm.has_method("select_saved_campaign_source"):
		push_error("GameState: DataManager cannot select saved campaign content")
		return false
	return bool(
		dm.call(
			"select_saved_campaign_source",
			String(campaign.get("package_id", "")),
			String(campaign.get("package_version", ""))
		)
	)


# Temporary flat party item ids use the durable convoy schema until the full
# convoy system owns richer InventoryEntry state. Duplicates are intentional.
func _party_items_to_convoy_entries() -> Array[Dictionary]:
	return _party_item_ids_to_convoy_entries(party_items)


func _party_item_ids_to_convoy_entries(item_ids: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not (item_ids is Array):
		return out
	for item_id_var in item_ids:
		(
			out
			. append(
				{
					"entry_type": "item",
					"item_id": String(item_id_var),
					"uses_remaining": 1,
				}
			)
		)
	return out


func _party_items_from_convoy_entries(entries: Variant) -> Array[String]:
	var out: Array[String] = []
	if not (entries is Array):
		push_error("GameState: campaign save party.convoy.entries is not an Array")
		return out
	var dm := get_node_or_null("/root/DataManager")
	for value in entries:
		if not (value is Dictionary) or String(value.get("entry_type", "")) != "item":
			push_error("GameState: campaign save convoy contains a non-item entry")
			return []
		var item_id: String = String(value.get("item_id", ""))
		if (
			item_id.is_empty()
			or (dm != null and dm.has_method("has_item") and not bool(dm.call("has_item", item_id)))
		):
			push_error("GameState: campaign save convoy names unknown item '%s'" % item_id)
			return []
		out.append(item_id)
	return out


# roster.units is the player's party by definition, so every entry converts —
# unlike map_runtime.units, which is the mixed live board and must be filtered by
# faction (_player_roster_from_runtime_units).
func _roster_from_save_units(units: Variant) -> Array[UnitData]:
	var out: Array[UnitData] = []
	if not (units is Array):
		return out
	for unit_entry in units:
		if unit_entry is Dictionary:
			out.append(unit_data_from_runtime_dict(unit_entry))
	return out


func unit_data_to_runtime_dict(data: UnitData, faction_id: String = "") -> Dictionary:
	var out: Dictionary = _snapshot_unit_data(data)
	# Suspend must rebuild live enemies that have no roster resource on load, so
	# it carries static identity/config beside the mutable snapshot fields.
	out["unit_id"] = data.unit_id
	out["unit_name"] = data.unit_name
	out["faction"] = faction_id
	out["movement"] = data.movement
	out["constitution"] = data.constitution
	out["line_of_sight"] = data.line_of_sight
	out["growth_rates"] = data.growth_rates.duplicate(true)
	out["reclass_options"] = data.reclass_options.duplicate()
	out["can_seize"] = data.can_seize
	out["gold"] = data.gold
	out["ai_profile"] = data.ai_profile
	out["is_default_roster"] = data.is_default_roster
	out["shift_profile_id"] = data.shift_profile_id
	return out


func unit_data_from_runtime_dict(unit_dict: Dictionary) -> UnitData:
	var data := UnitData.new()
	data.unit_id = String(unit_dict.get("unit_id", ""))
	data.unit_name = String(unit_dict.get("unit_name", ""))
	data.movement = _variant_int(unit_dict.get("movement", 0), 0)
	data.constitution = _variant_int(unit_dict.get("constitution", 0), 0)
	data.line_of_sight = _variant_int(unit_dict.get("line_of_sight", 4), 4)
	data.growth_rates = (
		unit_dict.get("growth_rates", {}).duplicate(true)
		if unit_dict.get("growth_rates", {}) is Dictionary
		else {}
	)
	data.reclass_options = SaveCodec.string_array_from_variant(unit_dict.get("reclass_options", []))
	data.can_seize = bool(unit_dict.get("can_seize", false))
	data.gold = _variant_int(unit_dict.get("gold", 1000), 1000)
	data.ai_profile = String(unit_dict.get("ai_profile", "basic"))
	data.is_default_roster = bool(unit_dict.get("is_default_roster", false))
	data.shift_profile_id = String(unit_dict.get("shift_profile_id", ""))
	_restore_unit_data(data, unit_dict)
	return data


func _runtime_units_to_array() -> Array:
	var out: Array = []
	for unit in all_units:
		if not is_instance_valid(unit) or unit.get("data") == null:
			continue
		var faction_id: String = String(unit.get("team")) if "team" in unit else ""
		out.append(unit_data_to_runtime_dict(unit.data, faction_id))
	return out


func _player_roster_from_runtime_units(units: Variant) -> Array[UnitData]:
	var out: Array[UnitData] = []
	if not (units is Array):
		return out
	for unit_entry in units:
		if not (unit_entry is Dictionary):
			continue
		if String(unit_entry.get("faction", "")) != "blue":
			continue
		out.append(unit_data_from_runtime_dict(unit_entry))
	return out


func _campaign_rules_to_dict() -> Dictionary:
	return CampaignRuleSchema.from_resource(campaign_rules, mandated_campaign_rules)


func _campaign_rule_defaults_to_dict() -> Dictionary:
	if _authored_campaign_rule_values.is_empty():
		return _campaign_rules_to_dict()
	var out := _authored_campaign_rule_values.duplicate(true)
	out["mandated_rules"] = mandated_campaign_rules.duplicate()
	return out


func _apply_campaign_rules_dict(rules_dict: Variant) -> void:
	if not (rules_dict is Dictionary):
		return
	var normalized := CampaignRuleSchema.apply_to_resource(campaign_rules, rules_dict)
	mandated_campaign_rules = SaveCodec.string_array_from_variant(
		normalized.get("mandated_rules", [])
	)
	_authored_campaign_rule_values = normalized.duplicate(true)


func _current_map_path() -> String:
	if next_map_data_path != "":
		return next_map_data_path
	if map_data != null and map_data.resource_path != "":
		return map_data.resource_path
	return ""


func _variant_int(value: Variant, default_value: int) -> int:
	if value is int:
		return int(value)
	if value is float and absf(float(value) - float(int(value))) < 0.00001:
		return int(value)
	return default_value


# Validates a ledger entry's party block against the live roster before any of it
# is applied, so a bad entry leaves the running game untouched instead of half-
# restored. Mirrors the checks the old party-only snapshot validator ran, now
# reading the entry's party.roster / party.items and the entry's Pair Up + RNG.
func _validate_restore_entry(entry: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var party: Dictionary = entry.get("party", {})
	var roster_snap: Variant = party.get("roster", [])
	var roster_size: int = roster_snap.size() if roster_snap is Array else -1
	if roster_size != player_roster.size():
		errors.append(
			(
				"GameState: ledger entry roster count %d does not match player_roster size %d"
				% [roster_size, player_roster.size()]
			)
		)
	if roster_snap is Array:
		for i in roster_snap.size():
			var snap: Variant = roster_snap[i]
			if not (snap is Dictionary):
				errors.append("GameState: ledger roster entry %d is not a Dictionary" % i)
				continue
			_validate_snapshot_unit_dict(snap, i, errors)
	var items: Variant = party.get("items", [])
	if not (items is Array):
		errors.append("GameState: ledger entry party items is not an Array")
	else:
		var dm := get_node_or_null("/root/DataManager")
		for item_id_var in items:
			var item_id: String = String(item_id_var)
			if item_id == "":
				errors.append("GameState: ledger entry party items contains an empty item id")
			elif (
				dm != null and dm.has_method("has_item") and not bool(dm.call("has_item", item_id))
			):
				errors.append("GameState: ledger entry party item '%s' not found" % item_id)
	var map_runtime: Dictionary = entry.get("map_runtime", {})
	if not (map_runtime.get("pair_carry", {}).get("pair_up", {}) is Dictionary):
		errors.append("GameState: ledger entry Pair Up registry is not a Dictionary")
	# RNG (RNG-2): empty = legitimately captured without the autoload; non-empty must
	# carry both timeline ints or the restore would silently desync the dice chain.
	var rng_dict: Variant = map_runtime.get("rng", {})
	if rng_dict is Dictionary and not rng_dict.is_empty():
		if (
			not _is_ledger_rng_value(rng_dict.get("map_seed"))
			or not _is_ledger_rng_value(rng_dict.get("history_hash"))
		):
			errors.append(
				"GameState: ledger entry rng must carry int or decimal-string timeline values"
			)
	var rules_state: Variant = entry.get("campaign_rules_state", {})
	if not (rules_state is Dictionary):
		errors.append("GameState: ledger campaign rule state is not a Dictionary")
	else:
		var staged := MutableCampaignStateScript.new()
		if (
			not staged.apply_dict(rules_state.get("mutable_state", {}))
			or not (rules_state.get("per_map_overrides", {}) is Dictionary)
			or not (rules_state.get("active_mid_map_overrides", {}) is Dictionary)
		):
			errors.append("GameState: ledger campaign rule state is malformed")
	return errors


func _is_ledger_rng_value(value: Variant) -> bool:
	if value is int:
		return true
	if not (value is String) or String(value).is_empty():
		return false
	var text := String(value)
	var digits := text.substr(1) if text.begins_with("-") else text
	return not digits.is_empty() and digits.is_valid_int()


func _validate_snapshot_unit_dict(snap: Dictionary, index: int, errors: Array[String]) -> void:
	var dm := get_node_or_null("/root/DataManager")
	errors.append_array(SaveCodec.validate_unit_snapshot_dict(snap, index, dm))


# Seeds the within-map ledger with the round-0 boundary entry — the SUSPEND-COMPLETE
# board plus the folded party block (gold/items/roster), which is everything a Retry
# (restore_history(0)) rolls back. Call once immediately after units are spawned on
# the map. No turn_manager/cursor here: at map start turn state is not yet started
# and the cursor not yet placed, and a Retry scene reload regenerates both.
func take_map_snapshot() -> void:
	_map_ledger.clear()
	push_history()  # round-0, round-start reason; the entry carries the party block


# Restores the party (roster UnitData in place + gold + items), Pair Up, and the RNG
# timeline from ledger entry `index` — 0 is the round-0 boundary a Retry rewinds to.
# Returns false without mutating anything if the entry is missing or malformed. The
# board's non-player factions are NOT restored here: Retry reloads the scene, which
# rebuilds enemies from map_data. (A mid-map Rewind that stays in the scene — Phase 3
# — will additionally restore the board from the entry's map_runtime.units.)
func restore_history(index: int) -> bool:
	var entry: Dictionary = _map_ledger.peek(index)  # deep copy; safe across reset below
	if entry.is_empty():
		push_error("GameState: restore_history has no entry at index %d" % index)
		return false
	var restore_errors: Array[String] = _validate_restore_entry(entry)
	if not restore_errors.is_empty():
		for err in restore_errors:
			push_error(err)
		return false
	var party: Dictionary = entry.get("party", {})
	var roster_snap: Array = party.get("roster", [])
	for i in player_roster.size():
		if i < roster_snap.size():
			_restore_unit_data(player_roster[i], roster_snap[i])
	# Roll the party economy back too, so a replayed map can't re-grant its rewards.
	party_gold = int(party.get("gold", party_gold))
	party_items = SaveCodec.string_array_from_variant(party.get("items", []))
	reset_map_state()
	# Rule flips and their permanence are part of the same decision boundary as
	# board/economy state; Retry/Rewind must abandon mutations from the old future.
	restore_mutable_campaign_state(entry.get("campaign_rules_state", {}))
	# reset_map_state cleared the registry + ledger; reapply the entry's pairings so
	# the restore lands on the same paired layout. Done AFTER reset so the
	# clear-then-restore order is deterministic.
	var reg := get_node_or_null("/root/PairUpRegistry")
	if reg:
		reg.call("restore", entry.get("map_runtime", {}).get("pair_carry", {}).get("pair_up", {}))
	# Restore the dice timeline (RNG-2) so replaying the identical committed-action
	# sequence reproduces identical outcomes. Skipped when no RNG state was captured.
	var rng_svc := get_node_or_null("/root/RngService")
	var rng_dict: Dictionary = entry.get("map_runtime", {}).get("rng", {})
	if rng_svc != null and not rng_dict.is_empty():
		rng_svc.call("from_save_dict", rng_dict)
	# Caller is responsible for reloading the scene after this returns.
	return true


func _snapshot_unit_data(data: UnitData) -> Dictionary:
	return SaveCodec.unit_data_to_dict(data)


func _restore_unit_data(data: UnitData, snap: Dictionary) -> void:
	SaveCodec.apply_unit_dict(data, snap)
