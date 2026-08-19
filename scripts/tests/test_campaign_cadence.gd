extends SceneTree

const Cadence = preload("res://scripts/campaign/CadenceEngine.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	var engine := Cadence.new()
	var definitions := {
		"shop_refresh":
		{"family": "counter", "counter_id": "deployments_total", "mode": "every", "threshold": 2},
		"late_activity":
		{"family": "counter", "counter_id": "chapters_elapsed", "mode": "after", "threshold": 3},
	}
	_check(engine.validate(definitions).is_empty(), "valid trigger descriptors pass validation")
	var malformed := definitions.duplicate(true)
	malformed["bad"] = {"family": "calendar", "threshold": 0}
	_check(not engine.validate(malformed).is_empty(), "unknown trigger families fail loud")

	var state := engine.normalize_state({})
	engine.increment_counter(state, "deployments_total")
	var first: Dictionary = engine.evaluate(definitions, state)
	_check(first.fired.is_empty(), "every trigger waits for its interval")
	engine.increment_counter(state, "deployments_total")
	var second: Dictionary = engine.evaluate(definitions, state)
	_check(second.fired == ["shop_refresh"], "every trigger fires on its interval")
	var revisit: Dictionary = engine.evaluate(definitions, second.state)
	_check(revisit.fired.is_empty(), "revisit evaluation does not repeat a consumed interval")
	engine.increment_counter(state, "chapters_elapsed", 3)
	var after: Dictionary = engine.evaluate(definitions, state)
	_check(
		(
			"late_activity" in after.fired
			and bool(after.state.get("latched", {}).get("late_activity", false))
		),
		"after trigger fires and persists its latch"
	)
	var restored := engine.normalize_state(after.state)
	_check(
		(
			restored == after.state
			and restored.get("counters") is Dictionary
			and restored.get("latched") is Dictionary
			and restored.get("last_fired") is Dictionary
		),
		"cadence state round-trips as plain save data"
	)

	var custom := func(
		_trigger: Dictionary, _state: Dictionary, _context: Dictionary
	) -> Dictionary:
		return {"fired": true}
	_check(engine.register_family("fixture", custom), "trigger families are openly registered")
	var custom_result: Dictionary = engine.evaluate(
		{"custom": {"family": "fixture"}}, engine.normalize_state({})
	)
	_check(custom_result.fired == ["custom"], "registered family evaluates")

	print("=== Campaign Cadence: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _check(ok: bool, label: String) -> void:
	if ok:
		print("OK  %s" % label)
		_passed += 1
	else:
		print("FAIL %s" % label)
		_failed += 1
