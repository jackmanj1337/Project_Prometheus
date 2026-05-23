extends Node
# Central runtime registry for Pair Up relationships.
#
# Single source of truth: unit_id -> { partner_id, role }. Both sides of a
# pair are stored so any query is O(1) regardless of which unit is asked.
# Snapshotted by GameState alongside _map_start_snapshot so a Retry rewinds
# pairings to the map's start state. See AGENT/Docs/pair_up_combat_refactor
# _answers_2026-05-23.md (Q1, Q8) for the design rationale.
#
# Class-name is intentionally omitted: Godot 4 refuses class_name on autoload
# scripts (same constraint GameState documents).

const ROLE_LEAD := "lead"
const ROLE_SUPPORT := "support"

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
# is empty, the two ids are equal, or either unit is already paired. Callers
# must separate first to repartner.
func pair(lead_id: String, support_id: String) -> bool:
	if lead_id == "" or support_id == "" or lead_id == support_id:
		return false
	if is_paired(lead_id) or is_paired(support_id):
		return false
	_pairs[lead_id] = {"partner_id": support_id, "role": ROLE_LEAD}
	_pairs[support_id] = {"partner_id": lead_id, "role": ROLE_SUPPORT}
	return true


# Removes both sides of the pair this unit belongs to. Returns false if the
# unit was not paired. Idempotent on its no-op result.
func separate(unit_id: String) -> bool:
	if not is_paired(unit_id):
		return false
	var partner_id := get_partner_id(unit_id)
	_pairs.erase(unit_id)
	if partner_id != "":
		_pairs.erase(partner_id)
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
	return true


# Drops all pairings. Called by GameState.reset_map_state() between maps.
func clear() -> void:
	_pairs.clear()


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
