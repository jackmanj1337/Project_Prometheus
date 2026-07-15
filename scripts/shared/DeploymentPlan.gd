extends RefCounted
# B4-PREP-DEPLOYMENT Slice 1 — the explicit deployment plan and its validator.
#
# A plan is a Dictionary: unit_id (String) -> player start tile (Vector2i). The
# dictionary shape structurally forbids deploying the same unit twice; every
# other rule is checked by validate() below.
#
# Prep replaces an INFERENCE with a CHOICE. Before this, GameMap derived the
# player's deployment from roster order truncated by the start-tile count — a
# fallback that merely looked like a decision. The plan is that decision made
# explicit, and it has exactly two consumers: prep (to gate Begin Battle) and
# GameMap (to spawn from, and to refuse an illegal plan rather than spawn a
# half-legal board).
#
# The plan is chosen at prep and consumed at launch, and is deliberately NOT
# persisted — a campaign save is parked BETWEEN maps, so a reload lands back on
# prep and the player deploys again.
#
# No class_name: preload this script (as GameState does with its helpers) so
# adding it does not depend on the global class registry being reimported.
#
# Authority: GDD_07 §Prep Screen; the node constraints it reads are GDD_01
# §CampaignData Contract.


# Every reason `plan` is not launchable, as player/author-facing strings. Empty
# means the plan is legal. `node` may be null — a bare single-map launch has no
# campaign node, so the node constraints simply do not apply.
static func validate(plan: Dictionary, roster: Array[UnitData], node: CampaignNode,
		start_tiles: Array[Vector2i]) -> Array[String]:
	var errors: Array[String] = []

	if plan.is_empty():
		errors.append("DeploymentPlan: plan deploys no units")
	if plan.size() > start_tiles.size():
		errors.append("DeploymentPlan: plan deploys %d units but the map has only %d start tiles" % [
			plan.size(), start_tiles.size()])

	# Party index by unit_id. Under permadeath a fallen unit STAYS in the roster
	# (spawn skips it), so presence here means "in the party", never "deployable".
	var party: Dictionary = {}
	for unit_data in roster:
		if unit_data != null and unit_data.unit_id != "":
			party[unit_data.unit_id] = unit_data

	var tile_owner: Dictionary = {}  # tile -> unit_id, so two units cannot share one tile
	for key in plan:
		var unit_id: String = String(key)
		if not (plan[key] is Vector2i):
			errors.append("DeploymentPlan: unit '%s' is not placed on a tile" % unit_id)
			continue
		var tile: Vector2i = plan[key]
		if not party.has(unit_id):
			errors.append("DeploymentPlan: unit '%s' is not in the party" % unit_id)
			continue
		if (party[unit_id] as UnitData).is_incapacitated:
			errors.append("DeploymentPlan: unit '%s' has fallen and cannot deploy" % unit_id)
		if not start_tiles.has(tile):
			errors.append("DeploymentPlan: unit '%s' is placed on %s, which is not a player start tile" % [
				unit_id, tile])
		if tile_owner.has(tile):
			errors.append("DeploymentPlan: units '%s' and '%s' are both placed on %s" % [
				tile_owner[tile], unit_id, tile])
		else:
			tile_owner[tile] = unit_id

	if node != null:
		errors.append_array(_node_constraint_errors(plan, party, node))
	return errors


# The [CST-5] node constraints: deployment_cap, excluded_units, required_units.
# Authored on CampaignNode since Slice 1 of B1-CST with no consumer — this is
# their first one, which is why no schema change is owed here.
static func _node_constraint_errors(plan: Dictionary, party: Dictionary,
		node: CampaignNode) -> Array[String]:
	var errors: Array[String] = []

	# -1 is uncapped and CampaignData rejects 0, so any other value is a real cap.
	if node.deployment_cap != -1 and plan.size() > node.deployment_cap:
		errors.append("DeploymentPlan: node '%s' caps deployment at %d, plan deploys %d" % [
			node.node_id, node.deployment_cap, plan.size()])

	for unit_id in node.excluded_units:
		if plan.has(unit_id):
			errors.append("DeploymentPlan: node '%s' excludes unit '%s'" % [node.node_id, unit_id])

	for unit_id in node.required_units:
		if plan.has(unit_id):
			continue
		if not party.has(unit_id):
			# An authoring error, not a play state: a fallen unit stays in the
			# roster, so an id missing from the party means the node requires a
			# unit the campaign never grants.
			errors.append("DeploymentPlan: node '%s' requires unit '%s', which is not in the party" % [
				node.node_id, unit_id])
			continue
		if (party[unit_id] as UnitData).is_incapacitated:
			# EXCUSED. A required unit that has FALLEN is dropped from the
			# requirement rather than blocking the plan: blocking would strand the
			# campaign, since no legal plan for this node could ever exist again and
			# the player's only recovery would be an older save. Whether a key death
			# should END the run is a campaign-rules question (permadeath game-over),
			# not a prep-validation one.
			continue
		errors.append("DeploymentPlan: node '%s' requires unit '%s' to deploy" % [
			node.node_id, unit_id])

	return errors
