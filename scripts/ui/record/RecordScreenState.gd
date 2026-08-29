class_name RecordScreenState
extends RefCounted

# Pure restoration state shared by record-oriented screens. ModalScreen remains
# the lifecycle/focus-trap shell; this object subsumes the scattered selection
# memory that would otherwise accumulate in screen-specific focus helpers.

var active_region: StringName = &"list"
var filter_text := ""
var sort_id: StringName = &"default"
var presenter_mode: StringName = &"auto"

var _selected_by_region: Dictionary = {}


func select(region: StringName, stable_id: String) -> void:
	if stable_id.is_empty():
		_selected_by_region.erase(region)
	else:
		_selected_by_region[region] = stable_id


func selected_id(region: StringName = active_region) -> String:
	return String(_selected_by_region.get(region, ""))


# Restores by stable id, never by row index. Reordering therefore preserves the
# same record, while removal chooses the caller's preferred id or the first row.
func restore(region: StringName, available_ids: Array[String], preferred_id := "") -> String:
	active_region = region
	var previous := selected_id(region)
	if previous in available_ids:
		return previous
	if not preferred_id.is_empty() and preferred_id in available_ids:
		select(region, preferred_id)
		return preferred_id
	if available_ids.is_empty():
		select(region, "")
		return ""
	select(region, available_ids[0])
	return available_ids[0]


func snapshot() -> Dictionary:
	return {
		"active_region": String(active_region),
		"filter_text": filter_text,
		"sort_id": String(sort_id),
		"presenter_mode": String(presenter_mode),
		"selected_by_region": _selected_by_region.duplicate(true),
	}


func restore_snapshot(value: Dictionary) -> void:
	active_region = StringName(str(value.get("active_region", "list")))
	filter_text = str(value.get("filter_text", ""))
	sort_id = StringName(str(value.get("sort_id", "default")))
	presenter_mode = StringName(str(value.get("presenter_mode", "auto")))
	_selected_by_region.clear()
	var selections: Variant = value.get("selected_by_region", {})
	if selections is Dictionary:
		for region in selections:
			var stable_id := str(selections[region])
			if not stable_id.is_empty():
				_selected_by_region[StringName(str(region))] = stable_id
