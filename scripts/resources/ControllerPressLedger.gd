class_name ControllerPressLedger
extends RefCounted

# Reference-counted bookkeeping for on-screen controller presses.
#
# Why counting rather than a bool: two fingers can hold the same action (a thumb
# on the D-pad and a second thumb on a duplicated control), and multi-touch
# release order is arbitrary. Releasing the first pointer must NOT release the
# action while the second still holds it, or the player gets a control that
# stops responding until they let go of everything.
#
# Pure bookkeeping — it never touches Input or the tree, so the whole
# stuck-input surface is unit-testable headlessly. The caller turns the reported
# transitions into Input.action_press / Input.action_release calls exactly once.

var _pointer_actions: Dictionary = {}  # pointer id -> action id it is holding
var _counts: Dictionary = {}  # action id -> number of pointers holding it


# Records `pointer_id` holding `action_id`.
# Returns {"pressed": <action that went down, or "">, "released": <action that
# went up, or "">}. A pointer that slides from one control to another releases
# the first in the same call, so no pointer can ever hold two actions at once.
func press(pointer_id: String, action_id: String) -> Dictionary:
	var result := {"pressed": "", "released": ""}
	if pointer_id.is_empty() or action_id.is_empty():
		return result

	var previous := String(_pointer_actions.get(pointer_id, ""))
	if previous == action_id:
		# Duplicate press from the same pointer (a repeated pointerdown, or a
		# re-entry after a capture hiccup). Idempotent: no second reference.
		return result
	if not previous.is_empty():
		result.released = _decrement(previous)

	_pointer_actions[pointer_id] = action_id
	var count := int(_counts.get(action_id, 0))
	_counts[action_id] = count + 1
	if count == 0:
		result.pressed = action_id
	return result


# Releases whatever `pointer_id` was holding. Returns the action that went up,
# or "" when the pointer held nothing or another pointer still holds the action.
func release(pointer_id: String) -> String:
	if not _pointer_actions.has(pointer_id):
		return ""
	var action := String(_pointer_actions[pointer_id])
	_pointer_actions.erase(pointer_id)
	return _decrement(action)


# Drops every held pointer. Returns the actions that went up, in a stable sorted
# order so lifecycle-cleanup tests are deterministic.
func release_all() -> Array[String]:
	var released := held_actions()
	_pointer_actions.clear()
	_counts.clear()
	return released


func held_actions() -> Array[String]:
	var actions: Array[String] = []
	actions.assign(_counts.keys())
	actions.sort()
	return actions


func holders(action_id: String) -> int:
	return int(_counts.get(action_id, 0))


func is_pointer_held(pointer_id: String) -> bool:
	return _pointer_actions.has(pointer_id)


func pointer_count() -> int:
	return _pointer_actions.size()


func _decrement(action_id: String) -> String:
	var count := int(_counts.get(action_id, 0)) - 1
	if count > 0:
		_counts[action_id] = count
		return ""
	_counts.erase(action_id)
	return action_id
