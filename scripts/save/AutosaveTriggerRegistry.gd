extends RefCounted
# Open string-id dispatcher. Built-ins and authored custom events use the same API.

var _handlers: Dictionary = {}


func register(trigger_id: String, handler: Callable) -> bool:
	if trigger_id.is_empty() or not handler.is_valid():
		return false
	var handlers: Array = _handlers.get(trigger_id, [])
	if not handlers.has(handler):
		handlers.append(handler)
	_handlers[trigger_id] = handlers
	return true


func unregister(trigger_id: String, handler: Callable) -> void:
	var handlers: Array = _handlers.get(trigger_id, [])
	handlers.erase(handler)
	if handlers.is_empty():
		_handlers.erase(trigger_id)
	else:
		_handlers[trigger_id] = handlers


func dispatch(trigger_id: String, context: Dictionary = {}) -> Array:
	var results: Array = []
	for handler: Callable in _handlers.get(trigger_id, []):
		results.append(handler.call(trigger_id, context.duplicate(true)))
	return results


func has_trigger(trigger_id: String) -> bool:
	return not (_handlers.get(trigger_id, []) as Array).is_empty()
