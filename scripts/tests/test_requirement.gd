extends SceneTree

const RequirementSystemScript = preload("res://scripts/autoloads/RequirementSystem.gd")
const TextDBScript = preload("res://scripts/text/TextDB.gd")


func _init() -> void:
	var failed := 0
	var system = RequirementSystemScript.new()
	system._ready()
	var context := {"campaign_flags": {"joined": true}, "values": {"level": 4}}
	var tree := {
		"op": "all",
		"children":
		[
			{"predicate_id": "flag", "params": {"scope": "campaign", "name": "joined"}},
			{
				"predicate_id": "compare",
				"params":
				{
					"op": "gte",
					"left": {"source_id": "literal_context", "params": {"key": "level"}},
					"right": {"literal": 3}
				}
			}
		]
	}
	failed += _check(system.evaluate(tree, context).met, "map-free composed requirement")
	var absent := {
		"op": "not",
		"children":
		[{"predicate_id": "unit_present", "subject": {"kind": "active_unit"}, "params": {}}]
	}
	failed += _check(system.evaluate(absent, context).met, "not over absent subject")
	var unmet := system.evaluate(
		{"predicate_id": "flag", "params": {"scope": "campaign", "name": "missing"}}, context
	)
	failed += _check(
		not unmet.met and unmet.reasons[0].predicate_path == "$", "structured unmet reason"
	)
	var db = TextDBScript.new()
	db.add_table({"req.flag": "Requires {name}"})
	failed += _check(
		system.render_reason(unmet.reasons[0], db) == "Requires missing",
		"text-key reason rendering"
	)
	system.register_predicate(
		"fixture",
		func(_node: Dictionary, _context: Dictionary) -> bool: return true,
		"fixture",
		"fixture.inverse"
	)
	failed += _check(
		system.evaluate({"predicate_id": "fixture", "params": {}}, {}).met,
		"registered predicate adds without engine edit"
	)

	# --- An empty composition used to validate clean and evaluate met = true, so an
	# --- authoring typo OPENED the gate. Spec: all/any have at least one child.
	for op in ["all", "any"]:
		failed += _check(
			not system.validate({"op": op, "children": []}).is_empty(),
			"an empty '%s' is a validate error" % op
		)
		failed += _check(
			not system.evaluate({"op": op, "children": []}).met,
			"an empty '%s' does not evaluate met" % op
		)
	failed += _check(
		not system.validate({"op": "all"}).is_empty(),
		"a composition with no children key is a validate error"
	)
	failed += _check(
		system.evaluate({"op": "all"}).has("met"),
		"a composition with no children key degrades instead of throwing"
	)
	failed += _check(
		not (
			system.validate({"op": "not", "children": [{"predicate_id": "fixture"}, {}]}).is_empty()
		),
		"'not' still takes exactly one child"
	)

	# --- presentation.gate: [EPUX-02]'s per-entry choice, consumed by [EPUX-04]/[ANN-2].
	# --- It was previously never validated and never surfaced.
	failed += _check(
		(
			(
				system
				. validate({"predicate_id": "fixture", "presentation": {"gate": "NOT_A_GATE"}})
				. size()
			)
			== 1
		),
		"an unknown presentation gate is a validate error"
	)
	for gate in [system.GATE_VISIBLE_DISABLED, system.GATE_HIDDEN_UNTIL_MET]:
		failed += _check(
			system.validate({"predicate_id": "fixture", "presentation": {"gate": gate}}).is_empty(),
			"gate '%s' validates" % gate
		)
	var hidden := system.evaluate(
		{
			"predicate_id": "flag",
			"params": {"scope": "campaign", "name": "missing"},
			"presentation": {"gate": "hidden_until_met"}
		},
		context
	)
	failed += _check(
		hidden.reasons[0].get("gate", "") == system.GATE_HIDDEN_UNTIL_MET,
		"the declared gate reaches the consumer inside the reason"
	)
	failed += _check(
		unmet.reasons[0].get("gate", "") == system.GATE_VISIBLE_DISABLED,
		"an entry with no presentation defaults to visible_disabled"
	)
	# Hidden changes presentation ONLY -- boolean evaluation and diagnostics are identical.
	failed += _check(
		(
			hidden.met == unmet.met
			and hidden.reasons[0].text_key == unmet.reasons[0].text_key
			and hidden.reasons[0].predicate_path == unmet.reasons[0].predicate_path
		),
		"hidden vs visible-disabled changes presentation only"
	)
	# --- The four [REQ-2] v1 predicates that were never registered. Param shapes are the
	# --- ratified ones: class_level {class_id?, op, n}, proficiency {track, op, rank},
	# --- stat {name, op, n}, has_item {item_id, location: held|equipped|convoy}.
	var unit := UnitData.new()
	unit.unit_id = "lord"
	unit.class_id = "myrmidon"
	unit.level = 10
	unit.strength = 12
	unit.weapon_wexp = {"sword": 250}
	var sword := InventoryEntry.new()
	sword.entry_type = "weapon"
	sword.weapon_id = "iron_sword"
	unit.inventory = [sword] as Array[InventoryEntry]
	var unit_context := {"units": {"lord": unit}, "convoy": ["vulnerary"], "active_unit": unit}
	var named := {"kind": "named_unit", "unit_id": "lord"}

	for case in [
		["class_level", {"op": "gte", "n": 10}, true, "class_level meets its threshold"],
		["class_level", {"op": "gte", "n": 11}, false, "class_level below its threshold"],
		[
			"class_level",
			{"class_id": "archer", "op": "gte", "n": 1},
			false,
			"class_level scoped to another class"
		],
		["stat", {"name": "strength", "op": "gte", "n": 12}, true, "stat meets its threshold"],
		["stat", {"name": "strength", "op": "gt", "n": 12}, false, "stat below its threshold"],
		["proficiency", {"track": "sword", "op": "gte", "rank": "C"}, true, "proficiency at rank"],
		[
			"proficiency",
			{"track": "sword", "op": "gte", "rank": "A"},
			false,
			"proficiency below rank"
		],
		[
			"proficiency",
			{"track": "axe", "op": "gte", "rank": "D"},
			false,
			"proficiency on an untrained track"
		],
		["has_item", {"item_id": "iron_sword", "location": "held"}, true, "has_item held"],
		["has_item", {"item_id": "elixir", "location": "held"}, false, "has_item absent"],
		["has_item", {"item_id": "vulnerary", "location": "convoy"}, true, "has_item convoy"],
		["has_item", {"item_id": "iron_sword", "location": "convoy"}, false, "convoy is not held"],
	]:
		var definition := {"predicate_id": case[0], "subject": named, "params": case[1]}
		failed += _check(
			(
				system.validate(definition).is_empty()
				and system.evaluate(definition, unit_context).met == case[2]
			),
			case[3]
		)

	# Absent subjects stay false with a reason rather than throwing (Slice 5 §Context).
	for predicate_id in ["class_level", "proficiency", "stat", "has_item"]:
		var absent_subject := {
			"predicate_id": predicate_id,
			"subject": {"kind": "named_unit", "unit_id": "nobody"},
			"params": {"name": "strength", "track": "sword", "item_id": "x", "op": "gte", "n": 1}
		}
		var outcome := system.evaluate(absent_subject, unit_context)
		failed += _check(
			not outcome.met and outcome.reasons.size() == 1,
			"'%s' over an absent subject is false with a reason" % predicate_id
		)

	# Depth budgets are pack-lowerable, and they were not before: validation applied
	# only the engine ceiling, so a pack could cap how MANY nodes a tree had but not
	# how deeply it nested. `not` is the cheapest way to nest one node per level.
	var rules := CampaignRules.new()
	rules.requirement_depth_budget = 3
	var deep: Dictionary = {
		"predicate_id": "flag", "params": {"scope": "campaign", "name": "joined"}
	}
	for _i in 5:
		deep = {"op": "not", "children": [deep]}
	var deep_errors: Array[String] = system.validate(deep, rules)
	failed += _check(
		not deep_errors.is_empty() and "depth budget" in deep_errors[0],
		"a pack-lowered requirement depth budget rejects a tree the engine ceiling allows"
	)
	failed += _check(
		system.validate(deep).is_empty(),
		"the same tree validates clean under the default budget, so the budget is what rejected it"
	)
	rules.requirement_depth_budget = 32
	rules.value_term_depth_budget = 2
	var deep_term: Dictionary = {"literal": 1}
	for _i in 4:
		deep_term = {"op": "neg", "operands": [deep_term]}
	var term_node := {
		"predicate_id": "compare",
		"params": {"op": "gte", "left": deep_term, "right": {"literal": 0}}
	}
	failed += _check(
		not system.validate(term_node, rules).is_empty() and system.validate(term_node).is_empty(),
		"a pack-lowered value-term depth budget reaches Formula.validate instead of a hardcoded 16"
	)

	print("=== Requirement Results: %d failed ===" % failed)
	quit(1 if failed else 0)


func _check(ok: bool, label: String) -> int:
	print(("OK  " if ok else "FAIL ") + label)
	return 0 if ok else 1
