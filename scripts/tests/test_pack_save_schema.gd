extends SceneTree

const CampaignRuleSchema = preload("res://scripts/save/CampaignRuleSchema.gd")
const SaveDataScript = preload("res://scripts/save/SaveData.gd")
const CampaignRulesScript = preload("res://scripts/resources/CampaignRules.gd")
const Tier2CatalogueScript = preload("res://scripts/resources/Tier2Catalogue.gd")


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

	var legacy: RefCounted = (
		SaveDataScript
		. from_dict(
			{
				"format_version": 1,
				"campaign":
				{
					"package_id": "example_pack",
					"package_version": "1.2.3",
					"campaign_id": "opening",
				}
			}
		)
	)
	if (
		legacy.format_version == 2
		and legacy.source["package_id"] == "example_pack"
		and legacy.source["package_version"] == "1.2.3"
		and legacy.source["campaign_id"] == "opening"
		and legacy.to_dict().has("source")
	):
		print("OK  format-1 package identity migrates into canonical source envelope")
		passed += 1
	else:
		print("FAIL legacy source migration: %s" % [legacy.to_dict()])
		failed += 1

	var invalid_fingerprint: RefCounted = SaveDataScript.from_dict(
		{"source": {"content_fingerprint": "sha256:not-a-digest"}}
	)
	if invalid_fingerprint.validate().has(
		"SaveData: source.content_fingerprint must be a sha256 digest"
	):
		print("OK  malformed content fingerprints fail validation")
		passed += 1
	else:
		print("FAIL malformed fingerprint was accepted")
		failed += 1

	var catalogue: RefCounted = Tier2CatalogueScript.new()
	catalogue.entries.append({"kind": "unit", "id": "b", "path": "data/b.json"})
	catalogue.entries.append({"kind": "unit", "id": "a", "path": "data/a.json"})
	catalogue.documents = {"unit\nb": {"hp": 20}, "unit\na": {"hp": 18}}
	var first_fingerprint: String = catalogue.content_fingerprint()
	catalogue.entries.reverse()
	var reordered_fingerprint: String = catalogue.content_fingerprint()
	catalogue.documents["unit\na"]["hp"] = 19
	var changed_fingerprint: String = catalogue.content_fingerprint()
	if (
		first_fingerprint == reordered_fingerprint
		and first_fingerprint != changed_fingerprint
		and first_fingerprint.begins_with("sha256:")
		and first_fingerprint.length() == 71
	):
		print("OK  catalogue fingerprint is deterministic and content-sensitive")
		passed += 1
	else:
		print("FAIL catalogue fingerprint contract")
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
