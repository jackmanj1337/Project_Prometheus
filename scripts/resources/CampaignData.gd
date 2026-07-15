class_name CampaignData extends Resource
# A campaign: an ordered progression graph of CampaignNodes plus the identity a
# save binds to. Authored as JSON under data/campaigns/ and parsed here; see
# CampaignNode for why JSON and not .tres ([CST-3]).
#
# Authority: GDD_01 §CampaignData Contract
# Scope: this is the GRAPH only. Campaign-owned rule mandates/defaults ([CST-4]/
# [CST-6]) and the campaign envelope in saves land with the later save-spine
# slices; CampaignRules remains the live rule source in the meantime.
#
# Failure policy matches the map registry and the registry catalogue: a missing
# or malformed campaign is a LOUD error (collected here, push_error'd by
# DataManager), never a silent skip that would strand a player mid-campaign.

const SavePolicy = preload("res://scripts/save/SavePolicy.gd")
const SINGLE_MAP_PREFIX := "single_map__"

# Durable campaign identity. Saves store this in campaign.campaign_id.
@export var campaign_id: String = ""

# Player-facing campaign name and blurb for the future campaign selector.
@export var label: String = ""
@export var description: String = ""

# Dev/test campaigns are filtered out of the player-facing list ([CST-6]).
@export var is_dev_only: bool = false

# Where a new campaign begins. Defaults to the first authored node when the
# author omits it.
@export var start_node_id: String = ""

# Authored order IS the ordering contract: node_ids() returns nodes in the order
# the JSON declares them, so a campaign listing is stable across runs and
# platforms (no dictionary iteration order, no path sort).
@export var nodes: Array[CampaignNode] = []
@export var rule_overrides: Dictionary = {}
@export var mandated_rule_ids: Array[String] = []


static func single_map_campaign_id(map_id: String) -> String:
	return SINGLE_MAP_PREFIX + map_id


static func make_single_map(entry: Dictionary) -> CampaignData:
	var map_id := String(entry.get("id", ""))
	if map_id.is_empty():
		return null
	var campaign := CampaignData.new()
	campaign.campaign_id = single_map_campaign_id(map_id)
	campaign.label = String(entry.get("label", map_id))
	campaign.description = String(entry.get("description", "Single-map campaign."))
	campaign.is_dev_only = bool(entry.get("is_dev_only", false))
	campaign.start_node_id = "map"
	var node := CampaignNode.new()
	node.node_id = "map"
	node.label = campaign.label
	node.map_id = map_id
	campaign.nodes.append(node)
	return campaign


# Parses one authored campaign document. Appends every structural problem to
# `errors` and returns null when the document is too broken to represent (a
# partial CampaignData would let a caller launch a campaign that cannot finish).
# Cross-reference checks against the map registry belong to DataManager, which
# owns the map-id vocabulary.
static func parse(raw: Variant, source_path: String, errors: Array[String]) -> CampaignData:
	if not (raw is Dictionary):
		errors.append("CampaignData: '%s' did not parse as a JSON object" % source_path)
		return null

	var doc: Dictionary = raw
	var campaign := CampaignData.new()
	campaign.campaign_id = String(doc.get("campaign_id", ""))
	campaign.label = String(doc.get("label", ""))
	campaign.description = String(doc.get("description", ""))
	campaign.is_dev_only = bool(doc.get("is_dev_only", false))
	var raw_rules: Variant = doc.get("rules", {})
	if not (raw_rules is Dictionary):
		errors.append("CampaignData: campaign '%s' rules must be an object" % campaign.campaign_id)
	else:
		for rule_id in raw_rules:
			var authored: Variant = raw_rules[rule_id]
			if authored is Dictionary and authored.has("authority") and authored.has("value"):
				var authority := String(authored.get("authority", ""))
				if authority not in ["default", "mandate"]:
					errors.append("CampaignData: rule '%s' authority must be 'default' or 'mandate'" % rule_id)
					continue
				campaign.rule_overrides[rule_id] = authored["value"]
				if authority == "mandate":
					campaign.mandated_rule_ids.append(String(rule_id))
			else:
				# Legacy direct values are editable campaign defaults.
				campaign.rule_overrides[rule_id] = authored
		if campaign.rule_overrides.has("save_slot_classes") \
				or campaign.rule_overrides.has("autosave_rules"):
			var slot_classes: Variant = campaign.rule_overrides.get(
				"save_slot_classes", SavePolicy.classic_gba())
			var autosave_rules: Variant = campaign.rule_overrides.get(
				"autosave_rules", SavePolicy.default_autosave_rules())
			errors.append_array(SavePolicy.validate(slot_classes, autosave_rules,
				int(campaign.rule_overrides.get("rewind_charges_per_map", 4))))
			for warning in SavePolicy.builder_warnings(slot_classes,
					int(campaign.rule_overrides.get("rewind_charges_per_map", 4))):
				push_warning("CampaignData '%s': %s" % [campaign.campaign_id, warning])

	if campaign.campaign_id == "":
		errors.append("CampaignData: '%s' is missing 'campaign_id'" % source_path)
	if campaign.label == "":
		errors.append("CampaignData: campaign '%s' is missing 'label'" % campaign.campaign_id)

	var raw_nodes: Variant = doc.get("nodes", null)
	if not (raw_nodes is Array) or (raw_nodes as Array).is_empty():
		errors.append("CampaignData: campaign '%s' must author a non-empty 'nodes' array" % campaign.campaign_id)
		return null

	var seen_ids := {}
	for i in (raw_nodes as Array).size():
		var node := _parse_node((raw_nodes as Array)[i], i, campaign.campaign_id, seen_ids, errors)
		if node != null:
			campaign.nodes.append(node)
	if campaign.nodes.is_empty():
		return null

	# Start node defaults to the first authored node; an explicit one must exist.
	campaign.start_node_id = String(doc.get("start_node_id", ""))
	if campaign.start_node_id == "":
		campaign.start_node_id = campaign.nodes[0].node_id
	elif not seen_ids.has(campaign.start_node_id):
		errors.append("CampaignData: campaign '%s' start_node_id '%s' is not a node in the graph" % [
			campaign.campaign_id, campaign.start_node_id])

	campaign._collect_graph_errors(seen_ids, errors)
	return campaign


static func _parse_node(raw: Variant, index: int, campaign_id: String, seen_ids: Dictionary,
		errors: Array[String]) -> CampaignNode:
	if not (raw is Dictionary):
		errors.append("CampaignData: campaign '%s' node %d is not a JSON object" % [campaign_id, index])
		return null

	var doc: Dictionary = raw
	var node := CampaignNode.new()
	node.node_id = String(doc.get("node_id", ""))
	node.label = String(doc.get("label", ""))
	node.map_id = String(doc.get("map_id", ""))
	node.deployment_cap = int(doc.get("deployment_cap", -1))
	node.next_node_ids = _string_array(doc.get("next", []))
	node.required_units = _string_array(doc.get("required_units", []))
	node.excluded_units = _string_array(doc.get("excluded_units", []))
	node.rule_overrides = doc.get("rule_overrides", {}).duplicate(true) \
		if doc.get("rule_overrides", {}) is Dictionary else {}

	if node.node_id == "":
		errors.append("CampaignData: campaign '%s' node %d is missing 'node_id'" % [campaign_id, index])
		return null
	if seen_ids.has(node.node_id):
		errors.append("CampaignData: campaign '%s' has duplicate node_id '%s'" % [campaign_id, node.node_id])
		return null
	seen_ids[node.node_id] = true

	if node.map_id == "":
		errors.append("CampaignData: campaign '%s' node '%s' is missing 'map_id'" % [
			campaign_id, node.node_id])
	if node.deployment_cap < -1 or node.deployment_cap == 0:
		errors.append("CampaignData: campaign '%s' node '%s' deployment_cap %d must be -1 (uncapped) or >= 1" % [
			campaign_id, node.node_id, node.deployment_cap])
	# A unit that is both forced in and banned is an unsatisfiable prep screen.
	for unit_id in node.required_units:
		if unit_id in node.excluded_units:
			errors.append("CampaignData: campaign '%s' node '%s' lists unit '%s' as both required and excluded" % [
				campaign_id, node.node_id, unit_id])
	return node


static func _string_array(raw: Variant) -> Array[String]:
	var out: Array[String] = []
	if not (raw is Array):
		return out
	for entry in (raw as Array):
		out.append(String(entry))
	return out


# Graph-level checks that need every node parsed first.
func _collect_graph_errors(seen_ids: Dictionary, errors: Array[String]) -> void:
	for node in nodes:
		for next_id in node.next_node_ids:
			if next_id == node.node_id:
				errors.append("CampaignData: campaign '%s' node '%s' lists itself as its own successor" % [
					campaign_id, node.node_id])
			elif not seen_ids.has(next_id):
				errors.append("CampaignData: campaign '%s' node '%s' points at unknown next node '%s'" % [
					campaign_id, node.node_id, next_id])
	# An unreachable node can never be played, so it is an authoring bug rather
	# than dead data — fail loud instead of shipping a node the player can't see.
	var reachable := _reachable_node_ids()
	for node in nodes:
		if not reachable.has(node.node_id):
			errors.append("CampaignData: campaign '%s' node '%s' is unreachable from start node '%s'" % [
				campaign_id, node.node_id, start_node_id])


# Ids reachable from start_node_id, following next_node_ids. Cycles terminate
# because a visited node is never expanded twice.
func _reachable_node_ids() -> Dictionary:
	var reachable := {}
	var frontier: Array[String] = [start_node_id]
	while not frontier.is_empty():
		var node_id: String = frontier.pop_front()
		if reachable.has(node_id):
			continue
		var node := get_node_by_id(node_id)
		if node == null:
			continue
		reachable[node_id] = true
		for next_id in node.next_node_ids:
			frontier.append(next_id)
	return reachable


# --- Read API ---------------------------------------------------------------

# Node ids in authored order — the deterministic ordering contract.
func node_ids() -> Array[String]:
	var out: Array[String] = []
	for node in nodes:
		out.append(node.node_id)
	return out


# Null for an unknown id. Callers that require the node (save load, node advance)
# must treat null as a hard failure, not a fallback to node 1.
func get_node_by_id(node_id: String) -> CampaignNode:
	for node in nodes:
		if node.node_id == node_id:
			return node
	return null


func has_node(node_id: String) -> bool:
	return get_node_by_id(node_id) != null


# Successor ids for a node; empty for a terminal node OR an unknown id, so
# callers should check has_node first when the distinction matters.
func next_node_ids_of(node_id: String) -> Array[String]:
	var node := get_node_by_id(node_id)
	if node == null:
		return []
	return node.next_node_ids.duplicate()
