extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_deployment_plan.gd
# Tests the B4-PREP-DEPLOYMENT Slice 1 deployment plan validator: the map rules
# (party membership, start tiles, tile collisions) and the [CST-5] node
# constraints (deployment_cap, excluded_units, required_units) that CampaignNode
# has carried since B1-CST with no consumer until now.

const DeploymentPlanS = preload("res://scripts/shared/DeploymentPlan.gd")

# Four start tiles; the party is four units unless a case says otherwise.
const TILES: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]


func _init() -> void:
	print("=== DeploymentPlan Test ===")
	var passed := 0
	var failed := 0

	var party: Array[UnitData] = [_unit("lyn"), _unit("kent"), _unit("sain"), _unit("florina")]

	# ---- the map rules, with no campaign node (the bare single-map launch) ----
	if _is_legal("a plan on distinct start tiles is legal",
			{"lyn": TILES[0], "kent": TILES[1]}, party, null): passed += 1
	else: failed += 1

	if _rejects("an empty plan deploys nobody",
			{}, party, null, "deploys no units"): passed += 1
	else: failed += 1

	if _rejects("a unit outside the party cannot deploy",
			{"eliwood": TILES[0]}, party, null, "not in the party"): passed += 1
	else: failed += 1

	if _rejects("a tile that is not a player start tile is rejected",
			{"lyn": Vector2i(9, 9)}, party, null, "not a player start tile"): passed += 1
	else: failed += 1

	if _rejects("two units cannot share one tile",
			{"lyn": TILES[0], "kent": TILES[0]}, party, null, "both placed on"): passed += 1
	else: failed += 1

	# More units than start tiles. Five units, four tiles — the fifth has nowhere
	# legal to stand, so this reports the count as well as the tile violation.
	var big_party: Array[UnitData] = party.duplicate()
	big_party.append(_unit("hector"))
	if _rejects("a plan larger than the start-tile count is rejected",
			{"lyn": TILES[0], "kent": TILES[1], "sain": TILES[2], "florina": TILES[3],
			"hector": Vector2i(4, 0)},
			big_party, null, "only 4 start tiles"): passed += 1
	else: failed += 1

	# Permadeath: a fallen unit stays in the roster (spawn skips it), so the
	# validator — not roster membership — is what keeps it off the board.
	var fallen_party: Array[UnitData] = [_unit("lyn"), _fallen("kent")]
	if _rejects("a fallen unit cannot be deployed",
			{"kent": TILES[0]}, fallen_party, null, "has fallen"): passed += 1
	else: failed += 1

	# ---- [CST-5] node constraints ----
	# deployment_cap: -1 is uncapped, and CampaignData already rejects 0, so any
	# other value is a real cap.
	var capped := _node("n1", [], [], 2)
	if _is_legal("a plan at the deployment cap is legal",
			{"lyn": TILES[0], "kent": TILES[1]}, party, capped): passed += 1
	else: failed += 1

	if _rejects("a plan over the deployment cap is rejected",
			{"lyn": TILES[0], "kent": TILES[1], "sain": TILES[2]}, party, capped,
			"caps deployment at 2"): passed += 1
	else: failed += 1

	if _is_legal("deployment_cap -1 is uncapped, not zero",
			{"lyn": TILES[0], "kent": TILES[1], "sain": TILES[2], "florina": TILES[3]},
			party, _node("n1", [], [], -1)): passed += 1
	else: failed += 1

	# excluded_units / required_units
	if _rejects("an excluded unit cannot be deployed",
			{"lyn": TILES[0], "kent": TILES[1]}, party, _node("n1", [], ["kent"], -1),
			"excludes unit 'kent'"): passed += 1
	else: failed += 1

	if _rejects("a required unit cannot be benched",
			{"kent": TILES[0]}, party, _node("n1", ["lyn"], [], -1),
			"requires unit 'lyn' to deploy"): passed += 1
	else: failed += 1

	if _is_legal("a deployed required unit satisfies the requirement",
			{"lyn": TILES[0]}, party, _node("n1", ["lyn"], [], -1)): passed += 1
	else: failed += 1

	# The permadeath decision (2026-07-14): a required unit that has FALLEN is
	# EXCUSED from the requirement rather than blocking the plan. Blocking would
	# strand the campaign — no legal plan for this node could ever exist again.
	if _is_legal("a fallen required unit is excused, not a launch block",
			{"lyn": TILES[0]}, [_unit("lyn"), _fallen("kent")] as Array[UnitData],
			_node("n1", ["kent"], [], -1)): passed += 1
	else: failed += 1

	# ...but a required unit that was never in the party at all is an AUTHORING
	# error, not a play state, so it still fails loudly.
	if _rejects("a required unit missing from the party is an authoring error",
			{"lyn": TILES[0]}, party, _node("n1", ["eliwood"], [], -1),
			"which is not in the party"): passed += 1
	else: failed += 1

	# A bare single-map launch has no campaign node, so no node constraint applies.
	if _is_legal("a null node skips the node constraints entirely",
			{"lyn": TILES[0], "kent": TILES[1], "sain": TILES[2], "florina": TILES[3]},
			party, null): passed += 1
	else: failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


# ---- fixtures ---------------------------------------------------------------

static func _unit(unit_id: String) -> UnitData:
	var data := UnitData.new()
	data.unit_id = unit_id
	data.unit_name = unit_id.capitalize()
	return data


static func _fallen(unit_id: String) -> UnitData:
	var data := _unit(unit_id)
	data.is_incapacitated = true
	return data


static func _node(node_id: String, required: Array[String], excluded: Array[String],
		cap: int) -> CampaignNode:
	var node := CampaignNode.new()
	node.node_id = node_id
	node.map_id = "map_001_rout"
	node.required_units = required
	node.excluded_units = excluded
	node.deployment_cap = cap
	return node


# ---- assertions -------------------------------------------------------------

static func _is_legal(case_name: String, plan: Dictionary, party: Array[UnitData],
		node: CampaignNode) -> bool:
	var errors: Array[String] = DeploymentPlanS.validate(plan, party, node, TILES)
	if errors.is_empty():
		print("OK  %s" % case_name)
		return true
	print("FAIL %s — expected a legal plan, got %s" % [case_name, errors])
	return false


static func _rejects(case_name: String, plan: Dictionary, party: Array[UnitData],
		node: CampaignNode, needle: String) -> bool:
	var errors: Array[String] = DeploymentPlanS.validate(plan, party, node, TILES)
	for err in errors:
		if err.contains(needle):
			print("OK  rejected: %s" % case_name)
			return true
	print("FAIL %s did not report '%s' (got %s)" % [case_name, needle, errors])
	return false
