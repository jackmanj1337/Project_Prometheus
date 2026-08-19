extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_campaign_data.gd
# Tests the B1-CST Slice 1 campaign progression graph: CampaignData/CampaignNode
# parsing, the deterministic authored node ordering, the shipped campaign loading
# through DataManager, and the loud failures for a malformed graph or an
# unresolved map binding.

const DataManagerScript = preload("res://scripts/autoloads/DataManager.gd")


func _init() -> void:
	print("=== CampaignData Test ===")
	var passed := 0
	var failed := 0

	# ---- the shipped campaign loads through DataManager and validates clean ----
	var registry_manager: Node = load("res://scripts/autoloads/RegistryManager.gd").new()
	registry_manager.name = "RegistryManager"
	root.add_child(registry_manager)
	var dm: Node = DataManagerScript.new()
	dm.name = "DataManager"
	root.add_child(dm)  # _ready loads every catalogue, campaigns included
	await process_frame

	var shipped: CampaignData = dm.get_campaign("proving_grounds")
	if (
		shipped != null
		and shipped.campaign_id == "proving_grounds"
		and shipped.label != ""
		and shipped.nodes.size() == 5
		and not shipped.is_dev_only
	):
		print("OK  DataManager loads the shipped campaign through the catalogue path")
		passed += 1
	else:
		print("FAIL shipped campaign did not load: %s" % [shipped])
		failed += 1
	var single_map_id := CampaignData.single_map_campaign_id("map_900_hotseat_validation")
	var single_map: CampaignData = dm.get_campaign(single_map_id)
	if (
		single_map != null
		and single_map.is_dev_only
		and single_map.nodes.size() == 1
		and single_map.nodes[0].map_id == "map_900_hotseat_validation"
		and single_map.nodes[0].is_terminal()
	):
		print("OK  map registry entries auto-wrap as deterministic one-node campaigns")
		passed += 1
	else:
		print("FAIL generated single-map campaign: %s" % [single_map])
		failed += 1

	var live_errors: Array[String] = DataManagerScript.collect_campaign_validation_errors(
		dm.get_all_campaigns(),
		DataManagerScript.collect_map_registry_ids("res://data/maps/map_registry.json")
	)
	if live_errors.is_empty():
		print("OK  shipped campaign map bindings resolve against the map registry")
		passed += 1
	else:
		print("FAIL live campaign validation: %s" % [live_errors])
		failed += 1

	# ---- deterministic node ordering: authored order, stable across calls ----
	var expected_order: Array[String] = [
		"node_01_rout", "node_02_seize", "node_03_boss", "node_04_escape", "node_05_defend"
	]
	if (
		shipped != null
		and shipped.node_ids() == expected_order
		and shipped.node_ids() == shipped.node_ids()
		and shipped.start_node_id == "node_01_rout"
	):
		print("OK  node_ids() returns the authored order deterministically")
		passed += 1
	else:
		print("FAIL node ordering: %s" % [shipped.node_ids() if shipped != null else "null"])
		failed += 1

	# ---- graph traversal reaches the terminal node in authored order ----
	var walked: Array[String] = []
	if shipped != null:
		var cursor: String = shipped.start_node_id
		while cursor != "":
			walked.append(cursor)
			var successors: Array[String] = shipped.next_node_ids_of(cursor)
			cursor = successors[0] if successors.size() > 0 else ""
	var terminal: CampaignNode = (
		shipped.get_node_by_id("node_05_defend") if shipped != null else null
	)
	if walked == expected_order and terminal != null and terminal.is_terminal():
		print("OK  linear traversal from start reaches the terminal node")
		passed += 1
	else:
		print("FAIL traversal: walked=%s" % [walked])
		failed += 1

	# ---- unknown node id resolves to null, not a silent fallback to node 1 ----
	if (
		shipped != null
		and shipped.get_node_by_id("no_such_node") == null
		and not shipped.has_node("no_such_node")
		and shipped.next_node_ids_of("no_such_node").is_empty()
	):
		print("OK  unknown node id returns null / empty rather than a fallback")
		passed += 1
	else:
		print("FAIL unknown node id did not fail closed")
		failed += 1

	# ---- unresolved map binding is a cross-reference error ----
	var dangling := _parse_ok(
		{
			"campaign_id": "dangling",
			"label": "Dangling",
			"nodes": [{"node_id": "n1", "map_id": "map_does_not_exist", "next": []}],
		}
	)
	var map_errors: Array[String] = DataManagerScript.collect_campaign_validation_errors(
		{"dangling": dangling},
		DataManagerScript.collect_map_registry_ids("res://data/maps/map_registry.json")
	)
	if (
		dangling != null
		and map_errors.size() == 1
		and map_errors[0].contains("unknown map id 'map_does_not_exist'")
	):
		print("OK  a node bound to an unknown map id fails reference validation")
		passed += 1
	else:
		print("FAIL unresolved map reference: %s" % [map_errors])
		failed += 1

	var governed := _parse_ok(
		{
			"campaign_id": "governed",
			"label": "Governed",
			"rules":
			{
				"death_mode": {"authority": "mandate", "value": "classic"},
				"pair_up_enabled": {"authority": "default", "value": false},
				"undo_rounds": 2,
			},
			"nodes": [{"node_id": "n1", "map_id": "map_001", "next": []}],
		}
	)
	if (
		governed != null
		and governed.rule_overrides["death_mode"] == "classic"
		and governed.rule_overrides["pair_up_enabled"] == false
		and governed.rule_overrides["undo_rounds"] == 2
		and governed.mandated_rule_ids == ["death_mode"]
	):
		print("OK  campaign rules distinguish locked mandates from editable defaults")
		passed += 1
	else:
		print("FAIL campaign rule authority: %s" % [governed])
		failed += 1

	# ---- malformed graphs each fail loud, one case per defect ----
	# [case name, authored document, the error substring it must report]
	var malformed_cases := [
		[
			"next points at an unknown node",
			{
				"campaign_id": "bad",
				"label": "Bad",
				"nodes": [{"node_id": "n1", "map_id": "map_001", "next": ["ghost"]}],
			},
			"unknown next node 'ghost'"
		],
		[
			"duplicate node_id",
			{
				"campaign_id": "bad",
				"label": "Bad",
				"nodes":
				[
					{"node_id": "n1", "map_id": "map_001", "next": []},
					{"node_id": "n1", "map_id": "map_002_seize", "next": []},
				],
			},
			"duplicate node_id 'n1'"
		],
		[
			"unreachable node",
			{
				"campaign_id": "bad",
				"label": "Bad",
				"nodes":
				[
					{"node_id": "n1", "map_id": "map_001", "next": []},
					{"node_id": "orphan", "map_id": "map_002_seize", "next": []},
				],
			},
			"node 'orphan' is unreachable"
		],
		[
			"self-referencing node",
			{
				"campaign_id": "bad",
				"label": "Bad",
				"nodes": [{"node_id": "n1", "map_id": "map_001", "next": ["n1"]}],
			},
			"its own successor"
		],
		[
			"unknown start_node_id",
			{
				"campaign_id": "bad",
				"label": "Bad",
				"start_node_id": "ghost",
				"nodes": [{"node_id": "n1", "map_id": "map_001", "next": []}],
			},
			"start_node_id 'ghost' is not a node"
		],
		[
			"missing map_id",
			{
				"campaign_id": "bad",
				"label": "Bad",
				"nodes": [{"node_id": "n1", "next": []}],
			},
			"is missing 'map_id'"
		],
		[
			"missing campaign_id",
			{
				"label": "Bad",
				"nodes": [{"node_id": "n1", "map_id": "map_001", "next": []}],
			},
			"is missing 'campaign_id'"
		],
		[
			"required and excluded overlap",
			{
				"campaign_id": "bad",
				"label": "Bad",
				"nodes":
				[
					{
						"node_id": "n1",
						"map_id": "map_001",
						"next": [],
						"required_units": ["lyn"],
						"excluded_units": ["lyn"],
					}
				],
			},
			"both required and excluded"
		],
		[
			"zero deployment_cap",
			{
				"campaign_id": "bad",
				"label": "Bad",
				"nodes": [{"node_id": "n1", "map_id": "map_001", "next": [], "deployment_cap": 0}],
			},
			"deployment_cap 0 must be"
		],
	]
	for case in malformed_cases:
		if _reports_error(String(case[0]), case[1], String(case[2])):
			passed += 1
		else:
			failed += 1

	# ---- documents too broken to represent return null ----
	var null_cases := {
		"non-object document": "not a campaign",
		"empty nodes array": {"campaign_id": "bad", "label": "Bad", "nodes": []},
		"missing nodes key": {"campaign_id": "bad", "label": "Bad"},
	}
	var null_ok := true
	for case_name in null_cases:
		var errors: Array[String] = []
		if (
			CampaignData.parse(null_cases[case_name], "fixture", errors) != null
			or errors.is_empty()
		):
			print("FAIL %s should parse to null with an error" % case_name)
			null_ok = false
	if null_ok:
		print("OK  unrepresentable campaign documents parse to null with errors")
		passed += 1
	else:
		failed += 1

	# ---- a branching graph is representable with no reshape ----
	var branching := _parse_ok(
		{
			"campaign_id": "branching",
			"label": "Branching",
			"nodes":
			[
				{"node_id": "n1", "map_id": "map_001", "next": ["left", "right"]},
				{"node_id": "left", "map_id": "map_002_seize", "next": []},
				{"node_id": "right", "map_id": "map_003_defeat_boss", "next": []},
			],
		}
	)
	if branching != null and branching.next_node_ids_of("n1") == ["left", "right"]:
		print("OK  a branching graph parses without a schema reshape")
		passed += 1
	else:
		print("FAIL branching graph did not parse")
		failed += 1

	# ---- cadence subscriptions bind to declared triggers and carry payloads ----
	var subscribed := _parse_ok(
		{
			"campaign_id": "cadence",
			"label": "Cadence",
			"cadence_triggers":
			{
				"late":
				{
					"family": "counter",
					"counter_id": "chapters_elapsed",
					"mode": "after",
					"threshold": 2
				}
			},
			"nodes":
			[
				{
					"node_id": "n1",
					"map_id": "map_001",
					"next": [],
					"cadence_subscriptions":
					{
						"battle_target":
						[{"trigger": "late", "value": {"map_id": "map_002_seize"}}],
						"activity_set": ["late"],
					},
				},
			],
		}
	)
	if (
		subscribed != null
		and subscribed.nodes[0].cadence_subscriptions.get("activity_set", []) == ["late"]
	):
		print("OK  a node subscribes to a declared trigger with a bare id and a payload")
		passed += 1
	else:
		print("FAIL cadence subscriptions did not parse")
		failed += 1

	# The two failures worth failing loud on: a binding that names no declared
	# trigger would silently never select, and a battle_target payload with no
	# target would silently fall back to the authored battle.
	var subscription_cases := {
		"unknown trigger":
		[
			{"battle_target": [{"trigger": "missing", "value": {"map_id": "map_002_seize"}}]},
			"names unknown trigger",
		],
		"battle target without a target": [{"battle_target": ["late"]}, "non-empty encounter_id"],
		"binding that is neither an id nor an object":
		[{"activity_set": [7]}, "neither a trigger id"],
		"subscriber that is not an array":
		[{"activity_set": "late"}, "must be an array of bindings"],
	}
	var subscription_ok := true
	for case_name in subscription_cases:
		var case: Array = subscription_cases[case_name]
		if not _reports_error(
			case_name,
			{
				"campaign_id": "cadence_bad",
				"label": "Cadence",
				"cadence_triggers":
				{
					"late":
					{
						"family": "counter",
						"counter_id": "chapters_elapsed",
						"mode": "after",
						"threshold": 2
					}
				},
				"nodes":
				[
					{
						"node_id": "n1",
						"map_id": "map_001",
						"next": [],
						"cadence_subscriptions": case[0]
					}
				],
			},
			String(case[1])
		):
			subscription_ok = false
	if subscription_ok:
		passed += 1
	else:
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


# Parses a fixture that is expected to be clean; returns null (and prints) if not.
func _parse_ok(doc: Dictionary) -> CampaignData:
	var errors: Array[String] = []
	var campaign := CampaignData.parse(doc, "fixture", errors)
	if not errors.is_empty():
		print("FAIL fixture expected to parse clean but reported: %s" % [errors])
		return null
	return campaign


# True when a malformed document reports an error containing `needle`.
static func _reports_error(case_name: String, doc: Variant, needle: String) -> bool:
	var errors: Array[String] = []
	CampaignData.parse(doc, "fixture", errors)
	for err in errors:
		if err.contains(needle):
			print("OK  malformed graph rejected: %s" % case_name)
			return true
	print("FAIL %s did not report '%s' (got %s)" % [case_name, needle, errors])
	return false
