class_name ItemEffectRegistry extends RefCounted
# Open item-effect registry. Effect ids map to independently registered
# validation/preview/commit handlers; dispatch never switches on authored ids.

var _entries: Dictionary = {}
var _validators: Dictionary = {}
var _can_apply_handlers: Dictionary = {}
var _preview_handlers: Dictionary = {}
var _commit_handlers: Dictionary = {}

const RegistryEntryScript = preload("res://scripts/resources/RegistryEntry.gd")
const ResourceManifest = preload("res://scripts/shared/ResourceManifest.gd")
const DEFAULT_ENTRY_ROOT := "res://data/registries/item_effects"


func _init(register_builtins: bool = true) -> void:
	_validators = {
		"none": Callable(self, "_validate_none"),
		"amount": Callable(self, "_validate_amount"),
		"promotion": Callable(self, "_validate_promotion"),
		"stat_buff": Callable(self, "_validate_stat_buff"),
	}
	if register_builtins:
		load_entries(DEFAULT_ENTRY_ROOT)


func load_entries(root: String) -> Array[String]:
	var errors: Array[String] = []
	for path in ResourceManifest.load_paths(root):
		var resource := ResourceLoader.load(path)
		if resource == null or resource.get_script() != RegistryEntryScript:
			errors.append("ItemEffectRegistry: '%s' is not a RegistryEntry" % path)
			continue
		if resource.family != "item_effects":
			errors.append("ItemEffectRegistry: '%s' has family '%s'" % [path, resource.family])
			continue
		errors.append_array(
			register_effect(
				resource.id,
				String(resource.test_fixture.get("validation_handler", "")),
				resource.primitive_handler,
				String(resource.test_fixture.get("preview_mode", "direct"))
			)
		)
	return errors


func register_effect(
	effect_id: String,
	validation_handler: String,
	runtime_handler: String,
	preview_mode: String = "direct"
) -> Array[String]:
	var errors: Array[String] = []
	if effect_id.strip_edges().is_empty():
		errors.append("ItemEffectRegistry: effect id is empty")
	if not _validators.has(validation_handler):
		errors.append(
			(
				"ItemEffectRegistry: effect '%s' has unknown validation handler '%s'"
				% [effect_id, validation_handler]
			)
		)
	if runtime_handler.strip_edges().is_empty():
		errors.append("ItemEffectRegistry: effect '%s' has an empty runtime handler" % effect_id)
	if preview_mode.strip_edges().is_empty():
		errors.append("ItemEffectRegistry: effect '%s' has an empty preview mode" % effect_id)
	if _entries.has(effect_id):
		errors.append("ItemEffectRegistry: duplicate effect id '%s'" % effect_id)
	if errors.is_empty():
		_entries[effect_id] = {
			"validation_handler": validation_handler,
			"runtime_handler": runtime_handler,
			"preview_mode": preview_mode
		}
	return errors


func register_validation_handler(handler_id: String, handler: Callable) -> Array[String]:
	if handler_id.strip_edges().is_empty() or not handler.is_valid():
		return ["ItemEffectRegistry: validation handler '%s' is incomplete" % handler_id]
	if _validators.has(handler_id):
		return ["ItemEffectRegistry: duplicate validation handler '%s'" % handler_id]
	_validators[handler_id] = handler
	return []


func register_runtime_handler(
	handler_id: String, can_apply: Callable, preview: Callable, commit: Callable
) -> Array[String]:
	if (
		handler_id.strip_edges().is_empty()
		or not can_apply.is_valid()
		or not preview.is_valid()
		or not commit.is_valid()
	):
		return ["ItemEffectRegistry: runtime handler '%s' is incomplete" % handler_id]
	if _can_apply_handlers.has(handler_id):
		return ["ItemEffectRegistry: duplicate runtime handler '%s'" % handler_id]
	_can_apply_handlers[handler_id] = can_apply
	_preview_handlers[handler_id] = preview
	_commit_handlers[handler_id] = commit
	return []


func ids() -> Array[String]:
	var result: Array[String] = []
	result.assign(_entries.keys())
	result.sort()
	return result


func has_effect(effect_id: String) -> bool:
	return _entries.has(effect_id)


func validate_item(item: ItemData, classes: Dictionary) -> Array[String]:
	if item == null:
		return ["ItemEffectRegistry: item is null"]
	var errors := _validate_class_refs(item, classes)
	if not _entries.has(item.effect_id):
		errors.append(
			"DataManager: item '%s' effect_id '%s' is not registered" % [item.id, item.effect_id]
		)
		return errors
	var entry: Dictionary = _entries[item.effect_id]
	errors.append_array((_validators[entry["validation_handler"]] as Callable).call(item, classes))
	return errors


func can_apply(effect_id: String, unit: Node, item: ItemData) -> bool:
	var handler := _runtime_handler_for(effect_id, _can_apply_handlers)
	return handler.is_valid() and bool(handler.call(unit, item))


func preview(effect_id: String, unit: Node, item: ItemData) -> Dictionary:
	var handler := _runtime_handler_for(effect_id, _preview_handlers)
	if not handler.is_valid():
		return {"ok": false, "mode": "", "error": "unknown_effect"}
	var result: Dictionary = handler.call(unit, item)
	if not result.has("mode"):
		result["mode"] = String((_entries[effect_id] as Dictionary)["preview_mode"])
	return result


func commit(effect_id: String, unit: Node, item: ItemData) -> Dictionary:
	var handler := _runtime_handler_for(effect_id, _commit_handlers)
	if not handler.is_valid():
		return {"ok": false, "consume": false, "error": "unknown_effect"}
	return handler.call(unit, item)


func _runtime_handler_for(effect_id: String, handlers: Dictionary) -> Callable:
	if not _entries.has(effect_id):
		return Callable()
	var handler_id := String((_entries[effect_id] as Dictionary)["runtime_handler"])
	return handlers.get(handler_id, Callable())


func _validate_none(_item: ItemData, _classes: Dictionary) -> Array[String]:
	return []


func _validate_amount(item: ItemData, _classes: Dictionary) -> Array[String]:
	if (
		not (item.effect_params.get("amount", null) is int)
		or int(item.effect_params.get("amount", 0)) <= 0
	):
		return ["DataManager: item '%s' effect_params.amount must be an int > 0" % item.id]
	return []


func _validate_promotion(_item: ItemData, _classes: Dictionary) -> Array[String]:
	return []


func _validate_class_refs(item: ItemData, classes: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for class_id in item.effect_params.get("allowed_classes", []):
		if not classes.has(String(class_id)):
			errors.append(
				(
					"DataManager: item '%s' allowed_classes '%s' not found"
					% [item.id, String(class_id)]
				)
			)
	var groups := {}
	for class_data in classes.values():
		for group_id in class_data.class_groups:
			groups[String(group_id)] = true
	for group_id in item.effect_params.get("allowed_class_groups", []):
		if not groups.has(String(group_id)):
			errors.append(
				(
					"DataManager: item '%s' allowed_class_groups '%s' not found"
					% [item.id, String(group_id)]
				)
			)
	return errors


func _validate_stat_buff(item: ItemData, _classes: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if String(item.effect_params.get("stat", "")).is_empty():
		errors.append("DataManager: item '%s' stat_buff requires a stat" % item.id)
	if (
		not (item.effect_params.get("delta", null) is int)
		or int(item.effect_params.get("delta", 0)) == 0
	):
		errors.append("DataManager: item '%s' stat_buff delta must be a non-zero int" % item.id)
	return errors
