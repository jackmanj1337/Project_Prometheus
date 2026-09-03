extends Node
# Central runtime registry for Pair Up relationships.
#
# Single source of truth: unit_id -> { partner_id, role }. Both sides of a
# pair are stored so any query is O(1) regardless of which unit is asked.
# Serialized into each within-map ledger entry (GameState's map_runtime.pair_carry)
# so a Retry — restore_history(0) — rewinds pairings to the map's start state. See
# [GDD-05-SKILLS] (Q1, Q8) for the rationale.
#
# Class-name is intentionally omitted: Godot 4 refuses class_name on autoload
# scripts (same constraint GameState documents).

const ROLE_LEAD := "lead"
const ROLE_SUPPORT := "support"
# Sentinel tile_position used to mark a paired support unit as off-map (Q2:
# "Lead-only on map; support's tile becomes null while paired"). Vector2i
# cannot be null, so we use a negative-coord sentinel no real map tile occupies.
# GridManager.get_unit_at compares tile_position by equality, so units at this
# coord cannot be returned by any tile query for a real map cell. Step 6c
# (Separate) and the Charm aura helper (step 11) compare against this value.
const OFF_MAP_TILE := Vector2i(-1, -1)

# Storage: unit_id -> { "partner_id": String, "role": String }
var _pairs: Dictionary = {}

# ---- Queries ----


func is_paired(unit_id: String) -> bool:
	return unit_id != "" and _pairs.has(unit_id)


func get_partner_id(unit_id: String) -> String:
	if not is_paired(unit_id):
		return ""
	return String(_pairs[unit_id].get("partner_id", ""))


func get_role(unit_id: String) -> String:
	if not is_paired(unit_id):
		return ""
	return String(_pairs[unit_id].get("role", ""))


func is_lead(unit_id: String) -> bool:
	return get_role(unit_id) == ROLE_LEAD


func is_support(unit_id: String) -> bool:
	return get_role(unit_id) == ROLE_SUPPORT


# ---- Mutations ----


# Pairs lead_id and support_id. Returns false (and does nothing) if either id
# is empty, the two ids are equal, either unit is already paired, or the
# campaign has Pair Up disabled. Callers must separate first to repartner.
func pair(lead_id: String, support_id: String) -> bool:
	if not _campaign_allows_pair_up():
		return false
	if lead_id == "" or support_id == "" or lead_id == support_id:
		return false
	if is_paired(lead_id) or is_paired(support_id):
		return false
	_pairs[lead_id] = {"partner_id": support_id, "role": ROLE_LEAD}
	_pairs[support_id] = {"partner_id": lead_id, "role": ROLE_SUPPORT}
	_emit_pair_up_changed()
	return true


# Gates pair() on the campaign-level GameState.campaign_rules flag. Returns
# true when the autoload is absent (headless tests that omit GameState) or
# when the registry instance is not in the scene tree (direct-instance unit
# tests). The is_inside_tree() check matches the cross-autoload idiom used
# elsewhere — get_node_or_null with an absolute path errors when called from
# a Node outside the active scene tree. Existing pairings, separate(),
# swap_roles(), and restore() are intentionally NOT gated; disabling Pair Up
# only blocks new pair formation.
func _campaign_allows_pair_up() -> bool:
	if not is_inside_tree():
		return true
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return true
	var rules: CampaignRules = gs.get("campaign_rules") as CampaignRules
	return true if rules == null else rules.pair_up_enabled


# Removes both sides of the pair this unit belongs to. Returns false if the
# unit was not paired. Idempotent on its no-op result.
func separate(unit_id: String) -> bool:
	if not is_paired(unit_id):
		return false
	var partner_id := get_partner_id(unit_id)
	_pairs.erase(unit_id)
	if partner_id != "":
		_pairs.erase(partner_id)
	_emit_pair_up_changed()
	return true


# Swaps lead and support roles within an existing pair. Returns false if the
# unit was not paired. Either side of the pair can call this; the result is
# identical.
func swap_roles(unit_id: String) -> bool:
	if not is_paired(unit_id):
		return false
	var partner_id := get_partner_id(unit_id)
	if partner_id == "" or not is_paired(partner_id):
		return false
	var unit_role := get_role(unit_id)
	var partner_role := get_role(partner_id)
	_pairs[unit_id]["role"] = partner_role
	_pairs[partner_id]["role"] = unit_role
	_emit_pair_up_changed()
	return true


# Drops all pairings. Called by GameState.reset_map_state() between maps.
func clear() -> void:
	_pairs.clear()
	_emit_pair_up_changed()


# Lead-death handler: if a paired lead dies, the support drops onto the lead's
# tile and the pairing is cleared. Player-phase deaths expend the dropped
# support immediately; enemy-phase deaths leave the support to refresh at the
# next round start with the normal blue-phase READY reset.
func release_support_from_fallen_lead(unit: Node) -> Node:
	if unit == null or unit.data == null or unit.data.unit_id == "":
		return null
	if not is_lead(unit.data.unit_id):
		return null
	var support_id: String = get_partner_id(unit.data.unit_id)
	var drop_tile: Vector2i = unit.tile_position
	var support: Node = _find_live_unit(support_id)
	separate(unit.data.unit_id)
	if support == null or support.data == null or support.data.hp <= 0:
		return null
	_restore_support_to_tile(support, drop_tile)
	_apply_support_turn_state_after_lead_death(support)
	return support


func _restore_support_to_tile(support: Node, tile: Vector2i) -> void:
	if support == null:
		return
	if support.has_method("snap_to_tile"):
		support.snap_to_tile(tile)
	else:
		support.tile_position = tile
	support.visible = true


func _find_live_unit(unit_id: String) -> Node:
	if unit_id == "" or not is_inside_tree():
		return null
	var gs := get_node_or_null("/root/GameState")
	if gs == null or not gs.has_method("find_unit_by_id"):
		return null
	return gs.find_unit_by_id(unit_id)


func _apply_support_turn_state_after_lead_death(support: Node) -> void:
	if support == null or not is_inside_tree():
		return
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return
	# A player-phase lead death expends the dropped support immediately. Announce it
	# on EventBus rather than reaching into "/root/GameMap/TurnManager" by literal
	# path — that autoload→scene coupling silently no-op'd on a tree reorg, so a
	# dropped support could fail to be marked DONE (audit 2026-06-14 P1). TurnManager
	# owns unit-state and listens for support_orphaned.
	if gs.current_phase == gs.Phase.PLAYER:
		var bus := get_node_or_null("/root/EventBus")
		if bus != null:
			bus.support_orphaned.emit(support)


# ---- Snapshot ----


# Returns a deep copy of the registry suitable for storage in a map snapshot.
# Deep copy prevents post-snapshot pair/separate calls from mutating the
# snapshot, matching the deep-copy discipline GameState already uses for
# inventory entries.
func serialize() -> Dictionary:
	return _pairs.duplicate(true)


# Replaces the registry contents with a deep copy of the supplied snapshot.
# A missing or empty snapshot leaves the registry empty.
func restore(snap: Dictionary) -> void:
	_pairs = snap.duplicate(true) if snap != null else {}
	_emit_pair_up_changed()


func _emit_pair_up_changed() -> void:
	if not is_inside_tree():
		return
	var bus := get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("pair_up_changed"):
		bus.pair_up_changed.emit()
