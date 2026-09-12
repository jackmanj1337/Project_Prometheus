class_name EffectMutationJournal extends RefCounted

## Ordered, prepared writes. Entries are evidence until commit applies them.

var entries: Array[Dictionary] = []


func append(
	step_id: String,
	authority_id: String,
	save_field: String,
	ref: Variant,
	before: Variant,
	after: Variant
) -> Dictionary:
	var entry := {
		"step_id": step_id,
		"authority_id": authority_id,
		"save_field": save_field,
		"ref": ref,
		"before": _copy(before),
		"after": _copy(after),
	}
	entries.append(entry)
	return entry


func save_fields() -> Array[String]:
	var result: Array[String] = []
	for entry in entries:
		var field := String(entry.save_field)
		if not result.has(field):
			result.append(field)
	return result


func duplicate_entries() -> Array[Dictionary]:
	return entries.duplicate(true)


static func _copy(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value
