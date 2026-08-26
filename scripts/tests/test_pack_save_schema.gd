extends SceneTree

const CampaignRuleSchema = preload("res://scripts/save/CampaignRuleSchema.gd")
const SaveDataScript = preload("res://scripts/save/SaveData.gd")
const CampaignRulesScript = preload("res://scripts/resources/CampaignRules.gd")


func _init() -> void:
	var passed := 0
	var failed := 0
	var rules: Resource = CampaignRulesScript.make_default()
	rules.requirement_node_budget = 73
	rules.value_term_node_budget = 74
	rules.requirement_depth_budget = 11
	rules.value_term_depth_budget = 12
	var encoded := CampaignRuleSchema.from_resource(rules, ["death_mode"])
	var restored: Resource = CampaignRulesScript.make_default()
	var normalized := CampaignRuleSchema.apply_to_resource(restored, encoded)
	if (
		restored.requirement_node_budget == 73
		and restored.value_term_node_budget == 74
		and restored.requirement_depth_budget == 11
		and restored.value_term_depth_budget == 12
		and normalized["mandated_rules"] == ["death_mode"]
	):
		print("OK  shared rule schema round-trips every complexity budget")
		passed += 1
	else:
		print("FAIL shared rule schema lost a complexity budget: %s" % [normalized])
		failed += 1

	var malformed: RefCounted = (
		SaveDataScript
		. from_dict(
			{
				"campaign":
				{
					"rules":
					{
						"requirement_node_budget": "clicked into nonsense",
						"rewind_cost_mode": "typo",
					}
				}
			}
		)
	)
	if (
		malformed.campaign["rules"]["requirement_node_budget"] == 128
		and malformed.campaign["rules"]["rewind_cost_mode"] == "per_activation"
	):
		print("OK  malformed rule values fall back without partial state")
		passed += 1
	else:
		print("FAIL malformed rule fallback: %s" % [malformed.campaign["rules"]])
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
