extends SceneTree

const TelemetryScript = preload("res://scripts/autoloads/TransitionTelemetry.gd")

var passed := 0
var failed := 0


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, label: String) -> void:
	if condition:
		print("OK  %s" % label)
		passed += 1
	else:
		print("FAIL %s" % label)
		failed += 1


func _run() -> void:
	var telemetry := TelemetryScript.new()
	telemetry.name = "TransitionTelemetryTest"
	root.add_child(telemetry)
	telemetry.set_process(false)
	var owner := Node.new()
	root.add_child(owner)

	var correlation := telemetry.begin(&"attack", {"actor_id": 1})
	telemetry.record(correlation, &"combat_started")
	telemetry.finish(correlation)
	_check(
		telemetry.records.slice(0, 3).all(
			func(item: Dictionary) -> bool: return item["correlation"] == correlation
		),
		"one correlation id spans a transition"
	)

	telemetry.acquire_suppression(owner, &"test")
	telemetry.release_suppression(owner, &"test")
	_check(telemetry._suppression_owners.is_empty(), "suppression acquire and release balance")

	telemetry.watchdog_timeout_msec = 10
	telemetry.acquire_suppression(owner, &"test")
	var start := telemetry._suppressed_since_msec
	telemetry.set_transition_state(&"combat", true)
	_check(
		telemetry.check_watchdog(start + 20).is_empty(),
		"legitimate long transition does not trigger watchdog"
	)
	telemetry.set_transition_state(&"combat", false)
	var before_owners: Dictionary = telemetry._suppression_owners.duplicate(true)
	var snapshot := telemetry.check_watchdog(start + 20)
	_check(not snapshot.is_empty(), "ownerless transition state emits watchdog snapshot")
	_check(
		telemetry.check_watchdog(start + 30).is_empty(),
		"watchdog snapshot is emitted only once per suppression interval"
	)
	_check(
		telemetry._suppression_owners == before_owners,
		"diagnostic watchdog never mutates suppression ownership"
	)
	_check(
		(
			snapshot.has("modal_locked")
			and snapshot.has("focus_owner_id")
			and snapshot.has("modal_stack")
			and snapshot.has("input_mode")
			and snapshot.has("combat")
			and snapshot.has("turn_state")
			and snapshot.has("level_up")
		),
		"snapshot includes modal, focus, input, combat, turn, and level-up state"
	)
	telemetry.release_suppression(owner, &"test")

	telemetry.acquire_suppression(owner, &"visible_details", "", true)
	var legitimate_start := telemetry._suppressed_since_msec
	_check(
		telemetry.check_watchdog(legitimate_start + 20).is_empty(),
		"explicit legitimate visible owner stands down watchdog"
	)
	telemetry.release_suppression(owner, &"visible_details")

	for index in range(TelemetryScript.MAX_RECORDS + 20):
		telemetry.record("", &"bounded", {"index": index})
	_check(telemetry.records.size() == TelemetryScript.MAX_RECORDS, "telemetry buffer is bounded")

	telemetry.queue_free()
	owner.queue_free()
	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
