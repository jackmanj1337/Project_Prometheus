extends Node

const MAX_RECORDS := 256
const DEFAULT_WATCHDOG_MSEC := 5000

var records: Array[Dictionary] = []
var watchdog_timeout_msec := DEFAULT_WATCHDOG_MSEC

var _next_correlation := 1
var _active: Dictionary = {}
var _suppression_owners: Dictionary = {}
var _suppressed_since_msec := -1
var _watchdog_reported := false
var _state: Dictionary = {
	"combat": false,
	"level_up": false,
	"scene_transition": false,
}


func _ready() -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus != null:
		bus.combat_started.connect(_on_combat_started)
		bus.combat_resolved.connect(_on_combat_resolved)
		bus.unit_leveled_up.connect(_on_unit_leveled_up)
		bus.level_up_started.connect(_on_level_up_started)
		bus.level_up_finished.connect(_on_level_up_finished)
		bus.phase_changed.connect(_on_phase_changed)
		bus.gameplay_modal_lock_changed.connect(_on_modal_lock_changed)
	var input_modes := get_node_or_null("/root/InputModeManager")
	if input_modes != null:
		input_modes.input_mode_changed.connect(_on_input_mode_changed)
	var viewport := get_viewport()
	if viewport != null and not viewport.gui_focus_changed.is_connected(_on_focus_changed):
		viewport.gui_focus_changed.connect(_on_focus_changed)
	set_process(true)


func _process(_delta: float) -> void:
	check_watchdog(Time.get_ticks_msec())


func begin(kind: StringName, fields: Dictionary = {}) -> String:
	var correlation := "tr-%06d" % _next_correlation
	_next_correlation += 1
	_active[correlation] = String(kind)
	record(correlation, &"begin", fields)
	return correlation


func record(correlation: String, stage: StringName, fields: Dictionary = {}) -> void:
	var entry := {
		"at_msec": Time.get_ticks_msec(),
		"correlation": correlation,
		"kind": String(_active.get(correlation, fields.get("kind", "system"))),
		"stage": String(stage),
		"fields": fields.duplicate(true),
	}
	records.append(entry)
	while records.size() > MAX_RECORDS:
		records.pop_front()
	print("TRANSITION %s" % JSON.stringify(entry))


func finish(correlation: String, fields: Dictionary = {}) -> void:
	if correlation.is_empty():
		return
	record(correlation, &"finish", fields)
	_active.erase(correlation)


func begin_attack(attacker: Node, defender: Node) -> String:
	var correlation := begin(&"attack", _node_pair(attacker, defender))
	_state["pending_attack_correlation"] = correlation
	record(correlation, &"attack_confirmed")
	return correlation


func record_exp_award(unit: Node, amount: int) -> void:
	var correlation := String(_state.get("combat_correlation", ""))
	record(correlation, &"exp_awarded", {"unit_id": _node_id(unit), "amount": amount})


func acquire_suppression(owner: Object, reason: StringName, correlation: String = "") -> void:
	if owner == null:
		return
	var id := owner.get_instance_id()
	var item: Dictionary = (
		_suppression_owners
		. get(
			id,
			{
				"count": 0,
				"type": owner.get_class(),
				"reason": String(reason),
				"correlation": correlation,
			}
		)
	)
	item["count"] = int(item["count"]) + 1
	item["reason"] = String(reason)
	if not correlation.is_empty():
		item["correlation"] = correlation
	_suppression_owners[id] = item
	if _suppressed_since_msec < 0:
		_suppressed_since_msec = Time.get_ticks_msec()
		_watchdog_reported = false
	record(correlation, &"suppression_acquire", {"owner_id": id, "reason": String(reason)})


func release_suppression(owner: Object, reason: StringName) -> void:
	if owner == null:
		return
	var id := owner.get_instance_id()
	if not _suppression_owners.has(id):
		return
	var item: Dictionary = _suppression_owners[id]
	var correlation := String(item.get("correlation", ""))
	var remaining := int(item.get("count", 1)) - 1
	if remaining > 0:
		item["count"] = remaining
		_suppression_owners[id] = item
	else:
		_suppression_owners.erase(id)
	record(correlation, &"suppression_release", {"owner_id": id, "reason": String(reason)})
	if _suppression_owners.is_empty():
		_suppressed_since_msec = -1
		_watchdog_reported = false


func clear_suppression(owner: Object, reason: StringName) -> void:
	if owner == null or not _suppression_owners.has(owner.get_instance_id()):
		return
	var id := owner.get_instance_id()
	var correlation := String(_suppression_owners[id].get("correlation", ""))
	_suppression_owners.erase(id)
	record(correlation, &"suppression_clear", {"owner_id": id, "reason": String(reason)})
	if _suppression_owners.is_empty():
		_suppressed_since_msec = -1
		_watchdog_reported = false


func set_transition_state(key: StringName, active: bool, correlation: String = "") -> void:
	_state[String(key)] = active
	record(correlation, &"state", {"name": String(key), "active": active})


func check_watchdog(now_msec: int) -> Dictionary:
	if _suppression_owners.is_empty() or _suppressed_since_msec < 0 or _watchdog_reported:
		return {}
	var elapsed := now_msec - _suppressed_since_msec
	if elapsed < watchdog_timeout_msec or _has_legitimate_transition():
		return {}
	_watchdog_reported = true
	var snapshot := diagnostic_snapshot(elapsed)
	record("", &"watchdog", snapshot)
	return snapshot


func diagnostic_snapshot(elapsed_msec: int) -> Dictionary:
	var bus := get_node_or_null("/root/EventBus")
	var input_modes := get_node_or_null("/root/InputModeManager")
	var viewport := get_viewport()
	var focus := viewport.gui_get_focus_owner() if viewport != null else null
	return {
		"elapsed_msec": elapsed_msec,
		"suppression_owners": _suppression_owners.duplicate(true),
		"modal_locked": bus != null and bus.is_gameplay_modal_locked(),
		"modal_stack": bus.gameplay_modal_lock_snapshot() if bus != null else {},
		"focus_owner_id": focus.get_instance_id() if focus != null else 0,
		"focus_owner_type": focus.get_class() if focus != null else "",
		"input_mode": String(input_modes.active_input_mode) if input_modes != null else "",
		"input_device": int(input_modes.active_joypad_device()) if input_modes != null else -1,
		"combat": bool(_state.get("combat", false)),
		"turn_state": _state.get("turn_state", -1),
		"level_up": bool(_state.get("level_up", false)),
		"scene_transition": bool(_state.get("scene_transition", false)),
	}


func _has_legitimate_transition() -> bool:
	if bool(_state.get("combat", false)) or bool(_state.get("level_up", false)):
		return true
	if bool(_state.get("scene_transition", false)):
		return true
	var bus := get_node_or_null("/root/EventBus")
	return bus != null and bus.is_gameplay_modal_locked()


func _on_combat_started(attacker: Node, defender: Node) -> void:
	var correlation := String(_state.get("pending_attack_correlation", ""))
	if correlation.is_empty():
		correlation = begin(&"combat", _node_pair(attacker, defender))
	else:
		record(correlation, &"combat_started", _node_pair(attacker, defender))
	_state["combat"] = true
	_state["combat_correlation"] = correlation


func _on_combat_resolved(attacker: Node, defender: Node, _result: Dictionary) -> void:
	_state["combat"] = false
	var correlation := String(_state.get("combat_correlation", ""))
	record(correlation, &"combat_resolved", _node_pair(attacker, defender))
	finish(correlation)
	_state.erase("combat_correlation")
	_state.erase("pending_attack_correlation")


func _on_unit_leveled_up(unit: Node, _stats: Dictionary, learned: Array) -> void:
	var correlation := begin(&"level_up", {"unit_id": _node_id(unit)})
	record(correlation, &"level_up_enqueued", {"learned_count": learned.size()})
	_state["level_up_correlation"] = correlation


func _on_level_up_started() -> void:
	_state["level_up"] = true
	record(String(_state.get("level_up_correlation", "")), &"level_up_shown")


func _on_level_up_finished() -> void:
	_state["level_up"] = false
	var correlation := String(_state.get("level_up_correlation", ""))
	record(correlation, &"level_up_dismissed")
	finish(correlation)
	_state.erase("level_up_correlation")


func _on_phase_changed(phase: int, faction_id: String) -> void:
	_state["turn_state"] = phase
	record("", &"turn_state", {"phase": phase, "faction": faction_id})


func _on_modal_lock_changed(locked: bool) -> void:
	record("", &"modal_stack", {"locked": locked})


func _on_input_mode_changed(mode: String) -> void:
	record("", &"input_mode", {"mode": mode})


func _on_focus_changed(control: Control) -> void:
	record(
		"",
		&"focus_changed",
		{
			"owner_id": _node_id(control),
			"owner_type": control.get_class() if control != null else "",
		}
	)


func _node_pair(first: Node, second: Node) -> Dictionary:
	return {"actor_id": _node_id(first), "target_id": _node_id(second)}


func _node_id(node: Node) -> int:
	return node.get_instance_id() if node != null else 0
