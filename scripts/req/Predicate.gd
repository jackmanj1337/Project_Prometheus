class_name Predicate
extends RefCounted

var definition: Dictionary


func _init(value: Dictionary = {}) -> void:
	definition = value.duplicate(true)


func to_dict() -> Dictionary:
	return definition.duplicate(true)
