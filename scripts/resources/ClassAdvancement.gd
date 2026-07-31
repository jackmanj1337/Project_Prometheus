class_name ClassAdvancement extends RefCounted
# Pure resolver for the package-authored advancement edge contract. Both fixed
# and branching edges use this path; callers mutate state only after a valid,
# explicitly confirmed resolution is returned.


static func resolve(
	edge: Dictionary,
	destination_id: String,
	class_variant_id: String = "",
	edge_variant_id: String = ""
) -> Dictionary:
	var effective := edge.duplicate(true)
	var errors: Array[String] = []
	if not edge_variant_id.is_empty():
		var edge_variant := _variant(edge.get("variants", []), edge_variant_id)
		if edge_variant.is_empty():
			errors.append("Unknown advancement edge variant '%s'." % edge_variant_id)
		else:
			for field in edge_variant.get("overrides", {}):
				effective[field] = edge_variant["overrides"][field]
	var destinations: Array = effective.get("destination_class_refs", [])
	if destination_id.is_empty() or not destinations.has(destination_id):
		errors.append("Destination class '%s' is not admitted by this edge." % destination_id)
	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"edge_id": String(edge.get("id", "")),
		"destination_class_id": destination_id,
		"class_variant_id": class_variant_id,
		"edge_variant_id": edge_variant_id,
		"stat_gains": effective.get("stat_gains", {}).duplicate(true),
		"weapon_wexp_grants": effective.get("weapon_wexp_grants", {}).duplicate(true),
		"operations": effective.get("operations", []).duplicate(true),
	}


static func commit_state(state: Variant, resolution: Dictionary, confirmed: bool) -> bool:
	if not confirmed or not bool(resolution.get("valid", false)):
		return false
	state["class_id"] = String(resolution.get("destination_class_id", ""))
	state["class_variant_id"] = _state_id(state, resolution.get("class_variant_id", ""))
	state["advancement_edge_id"] = String(resolution.get("edge_id", ""))
	state["advancement_edge_variant_id"] = _state_id(state, resolution.get("edge_variant_id", ""))
	for stat in resolution.get("stat_gains", {}):
		state[stat] = int(_state_get(state, stat, 0)) + int(resolution["stat_gains"][stat])
	var wexp: Dictionary = _state_get(state, "weapon_wexp", {}).duplicate(true)
	for track in resolution.get("weapon_wexp_grants", {}):
		wexp[track] = max(int(wexp.get(track, 0)), int(resolution["weapon_wexp_grants"][track]))
	state["weapon_wexp"] = wexp
	return true


static func _variant(variants: Variant, variant_id: String) -> Dictionary:
	if variants is Array:
		for value in variants:
			if value is Dictionary and String(value.get("variant_id", "")) == variant_id:
				return value
	return {}


static func _nullable_id(value: Variant) -> Variant:
	var id := String(value)
	return null if id.is_empty() else id


static func _state_id(state: Variant, value: Variant) -> Variant:
	return _nullable_id(value) if state is Dictionary else String(value)


static func _state_get(state: Variant, field: String, fallback: Variant) -> Variant:
	if state is Dictionary:
		return state.get(field, fallback)
	var value: Variant = state.get(field)
	return fallback if value == null else value
