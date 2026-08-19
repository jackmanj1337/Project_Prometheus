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
	print("=== Requirement results: %d failed ===" % failed)
	quit(1 if failed else 0)


func _check(ok: bool, label: String) -> int:
	print(("OK  " if ok else "FAIL ") + label)
	return 0 if ok else 1
