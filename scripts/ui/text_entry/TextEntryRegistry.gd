class_name TextEntryRegistry
extends RefCounted

const VALID_MODES := [&"auto", &"grid", &"hardware", &"system"]

var _presenters: Dictionary = {}


func register(mode: StringName, factory: Callable) -> bool:
	if mode not in VALID_MODES or not factory.is_valid():
		return false
	_presenters[mode] = factory
	return true


func has_backend(mode: StringName) -> bool:
	return _presenters.has(mode)


func create(mode: StringName) -> Node:
	if not _presenters.has(mode):
		return null
	var result: Variant = (_presenters[mode] as Callable).call()
	return result as Node


func resolve(requested: StringName, last_device: StringName) -> StringName:
	if requested != &"auto":
		return requested if has_backend(requested) else &"hardware"
	if last_device in [&"gamepad", &"touch"] and has_backend(&"grid"):
		return &"grid"
	return &"hardware"
