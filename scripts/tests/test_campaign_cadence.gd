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

	_check_subscriber_resolution(engine, definitions)
	_check_ticks(engine, definitions)

	print("=== Campaign Cadence: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


# The state/event split is the whole point of separating active from fired: a
# standing selection (battle target, activity set, activity variant) may only
# subscribe to a state trigger, while an interval is an event a stock entity
# reads through the tick counter.
func _check_subscriber_resolution(engine: RefCounted, definitions: Dictionary) -> void:
	var state: Dictionary = engine.normalize_state({})
	engine.increment_counter(state, "chapters_elapsed", 3)
	engine.increment_counter(state, "deployments_total", 2)
	var result: Dictionary = engine.evaluate(definitions, state)
	_check(
		result.active == ["late_activity"] and "shop_refresh" in result.fired,
		"an interval fires as an event but is never a standing selection"
	)

	var subscriptions := {
		"battle_target":
		[
			{"trigger": "late_activity", "value": {"encounter_id": "hard_variant"}},
			{"trigger": "unfired", "value": {"encounter_id": "never_selected"}},
		],
		"activity_set": ["late_activity"],
		"stock": ["shop_refresh"],
	}
	var resolved: Dictionary = engine.resolve_subscriptions(subscriptions, result.active)
	_check(
		resolved.get("battle_target", {}).get("encounter_id", "") == "hard_variant",
		"a satisfied binding selects its authored payload"
	)
	_check(resolved.get("activity_set", null) == true, "a bare trigger id binds to a true value")
	_check(
		not resolved.has("stock"),
		"an event-only subscriber resolves to nothing in the state selection"
	)

	var ordered := {
		"battle_target":
		[
			{"trigger": "late_activity", "value": {"map_id": "first"}},
			{"trigger": "late_activity", "value": {"map_id": "last"}},
		]
	}
	_check(
		(
			engine.resolve_subscriptions(ordered, result.active).get("battle_target", {}).get(
				"map_id", ""
			)
			== "last"
		),
		"authored order decides precedence and the last satisfied binding wins"
	)

	_check(
		engine.normalize_binding("trigger_id") == {"trigger": "trigger_id", "value": true},
		"a bare trigger id normalizes to a true-valued binding"
	)
	_check(
		(
			engine.normalize_binding({"value": 1}).is_empty()
			and engine.normalize_binding("").is_empty()
			and engine.normalize_binding(7).is_empty()
		),
		"a binding that names no trigger is rejected rather than silently ignored"
	)


# Ticks are the seam a stock entity compares against ([CVS-S6]), so they must
# count edges: repeated evaluation of a standing trigger is not a new tick.
func _check_ticks(engine: RefCounted, definitions: Dictionary) -> void:
	var state: Dictionary = engine.normalize_state({})
	engine.increment_counter(state, "chapters_elapsed", 3)
	var first: Dictionary = engine.evaluate(definitions, state)
	_check(int(first.state.ticks.get("late_activity", 0)) == 1, "becoming satisfied ticks once")
	var second: Dictionary = engine.evaluate(definitions, first.state)
	_check(
		int(second.state.ticks.get("late_activity", 0)) == 1,
		"re-evaluating a standing trigger does not tick again"
	)
	engine.increment_counter(second.state, "deployments_total", 2)
	var third: Dictionary = engine.evaluate(definitions, second.state)
	engine.increment_counter(third.state, "deployments_total", 2)
	var fourth: Dictionary = engine.evaluate(definitions, third.state)
	_check(
		(
			int(third.state.ticks.get("shop_refresh", 0)) == 1
			and int(fourth.state.ticks.get("shop_refresh", 0)) == 2
		),
		"each interval boundary is a separate tick a consumer can compare against"
	)


func _check(ok: bool, label: String) -> void:
	if ok:
		print("OK  %s" % label)
		_passed += 1
	else:
		print("FAIL %s" % label)
		_failed += 1
