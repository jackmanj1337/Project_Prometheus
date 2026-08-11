class_name ObjectiveConditionRegistry extends RefCounted
# Open objective-condition registry. Authored ids select registered validation,
# evaluation, and display handlers; existing ObjectiveCondition resources remain
# byte-compatible and no caller dispatches through a closed type match.

var _entries: Dictionary = {}
var _validators: Dictionary = {}
var _displays: Dictionary = {}
var _evaluators: Dictionary = {}

const RegistryEntryScript = preload("res://scripts/resources/RegistryEntry.gd")
const ResourceManifest = preload("res://scripts/shared/ResourceManifest.gd")
const DEFAULT_ENTRY_ROOT := "res://engine_data/registries/objective_conditions"


func _init(register_builtins: bool = true) -> void:
	_register_builtin_handlers()
	if register_builtins:
		load_entries(DEFAULT_ENTRY_ROOT)


func load_entries(root: String) -> Array[String]:
	var errors: Array[String] = []
	for path in ResourceManifest.load_paths(root):
		var resource := ResourceLoader.load(path)
		if resource == null or resource.get_script() != RegistryEntryScript:
			errors.append("ObjectiveConditionRegistry: '%s' is not a RegistryEntry" % path)
			continue
		if resource.family != "objective_conditions":
			errors.append(
				"ObjectiveConditionRegistry: '%s' has family '%s'" % [path, resource.family]
			)
			continue
		errors.append_array(
			register_condition(
				resource.id,
				String(resource.test_fixture.get("validation_handler", "")),
				resource.primitive_handler,
				String(resource.test_fixture.get("display_handler", ""))
			)
		)
	return errors


func register_condition(
	condition_id: String,
	validation_handler: String,
	evaluation_handler: String,
	display_handler: String
) -> Array[String]:
	var errors: Array[String] = []
	if condition_id.strip_edges().is_empty():
		errors.append("ObjectiveConditionRegistry: condition id is empty")
	if not _validators.has(validation_handler):
		errors.append(
			(
				"ObjectiveConditionRegistry: condition '%s' has unknown validation handler '%s'"
				% [condition_id, validation_handler]
			)
		)
	if evaluation_handler.strip_edges().is_empty():
		errors.append(
			(
				"ObjectiveConditionRegistry: condition '%s' has an empty evaluation handler"
				% condition_id
			)
		)
	if not _displays.has(display_handler):
		errors.append(
			(
				"ObjectiveConditionRegistry: condition '%s' has unknown display handler '%s'"
				% [condition_id, display_handler]
			)
		)
	if _entries.has(condition_id):
		errors.append("ObjectiveConditionRegistry: duplicate condition id '%s'" % condition_id)
	if errors.is_empty():
		_entries[condition_id] = {
			"validation_handler": validation_handler,
			"evaluation_handler": evaluation_handler,
			"display_handler": display_handler
		}
	return errors


func register_validation_handler(handler_id: String, handler: Callable) -> Array[String]:
	if handler_id.strip_edges().is_empty() or not handler.is_valid():
		return ["ObjectiveConditionRegistry: validation handler '%s' is incomplete" % handler_id]
	if _validators.has(handler_id):
		return ["ObjectiveConditionRegistry: duplicate validation handler '%s'" % handler_id]
	_validators[handler_id] = handler
	return []


func register_display_handler(handler_id: String, handler: Callable) -> Array[String]:
	if handler_id.strip_edges().is_empty() or not handler.is_valid():
		return ["ObjectiveConditionRegistry: display handler '%s' is incomplete" % handler_id]
	if _displays.has(handler_id):
		return ["ObjectiveConditionRegistry: duplicate display handler '%s'" % handler_id]
	_displays[handler_id] = handler
	return []


func register_evaluation_handler(handler_id: String, handler: Callable) -> Array[String]:
	if handler_id.strip_edges().is_empty() or not handler.is_valid():
		return ["ObjectiveConditionRegistry: evaluation handler '%s' is incomplete" % handler_id]
	if _evaluators.has(handler_id):
		return ["ObjectiveConditionRegistry: duplicate evaluation handler '%s'" % handler_id]
	_evaluators[handler_id] = handler
	return []


func ids() -> Array[String]:
	var result: Array[String] = []
	result.assign(_entries.keys())
	result.sort()
	return result


func has_condition(condition_id: String) -> bool:
	return _entries.has(condition_id)


func validate(cond: ObjectiveCondition, context: Dictionary) -> Array[String]:
	if cond == null:
		return ["ObjectiveConditionRegistry: condition is null"]
	if not _entries.has(cond.type):
		return [
			(
				"DataManager: map '%s' %s['%s'] has unregistered ObjectiveCondition.type '%s'"
				% [
					context.get("map_path", ""),
					context.get("field_name", ""),
					context.get("group_name", ""),
					cond.type
				]
			)
		]
	var entry: Dictionary = _entries[cond.type]
	return (_validators[entry["validation_handler"]] as Callable).call(cond, context)


func evaluate(cond: ObjectiveCondition, for_group: String, game_state: Node) -> bool:
	if cond == null or not _entries.has(cond.type):
		return false
	var handler_id := String((_entries[cond.type] as Dictionary)["evaluation_handler"])
	var handler: Callable = _evaluators.get(handler_id, Callable())
	if not handler.is_valid():
		push_warning(
			"ObjectiveCondition: no evaluation handler for registered type '%s'" % cond.type
		)
		return false
	return bool(handler.call(cond, for_group, game_state))


func display_text(cond: ObjectiveCondition) -> String:
	if cond == null or not _entries.has(cond.type):
		return ""
	var handler_id := String((_entries[cond.type] as Dictionary)["display_handler"])
	return String((_displays[handler_id] as Callable).call(cond))


func _register_builtin_handlers() -> void:
	_validators = {
		"none": Callable(self, "_validate_none"),
		"rout": Callable(self, "_validate_rout"),
		"named_units": Callable(self, "_validate_named_units"),
		"seize": Callable(self, "_validate_seize"),
		"escape": Callable(self, "_validate_escape"),
		"survive": Callable(self, "_validate_survive")
	}
	_displays = {
		"rout": Callable(self, "_display_rout"),
		"defeat_boss": Callable(self, "_display_defeat_boss"),
		"seize": Callable(self, "_display_seize"),
		"escape": Callable(self, "_display_escape"),
		"survive": Callable(self, "_display_survive"),
		"protect": Callable(self, "_display_protect"),
		"turn_limit": Callable(self, "_display_turn_limit")
	}


func _validate_none(_cond: ObjectiveCondition, _context: Dictionary) -> Array[String]:
	return []


func _validate_rout(cond: ObjectiveCondition, context: Dictionary) -> Array[String]:
	if (
		cond.faction_id != ""
		and not context.get("faction_ids", {}).has(cond.faction_id)
		and not context.get("alliance_groups", {}).has(cond.faction_id)
	):
		return [
			(
				"DataManager: map '%s' rout condition references unknown faction/group '%s'"
				% [context.get("map_path", ""), cond.faction_id]
			)
		]
	return []


func _validate_named_units(cond: ObjectiveCondition, context: Dictionary) -> Array[String]:
	if cond.unit_ids.is_empty():
		return [
			(
				"DataManager: map '%s' %s condition in group '%s' requires unit_ids"
				% [context.get("map_path", ""), cond.type, context.get("group_name", "")]
			)
		]
	return []


func _validate_seize(cond: ObjectiveCondition, context: Dictionary) -> Array[String]:
	if cond.tile == Vector2i(-1, -1):
		return [
			(
				"DataManager: map '%s' seize condition in group '%s' is missing tile"
				% [context.get("map_path", ""), context.get("group_name", "")]
			)
		]
	if not _inside(cond.tile, context):
		return [
			(
				"DataManager: map '%s' seize condition in group '%s' tile %s is outside the grid"
				% [context.get("map_path", ""), context.get("group_name", ""), str(cond.tile)]
			)
		]
	return []


func _validate_escape(cond: ObjectiveCondition, context: Dictionary) -> Array[String]:
	var errors := _validate_named_units(cond, context)
	if cond.tiles.is_empty():
		errors.append(
			(
				"DataManager: map '%s' escape condition in group '%s' requires tiles"
				% [context.get("map_path", ""), context.get("group_name", "")]
			)
		)
	errors.append_array(_validate_tiles(cond, context))
	return errors


func _validate_survive(cond: ObjectiveCondition, context: Dictionary) -> Array[String]:
	var errors := _validate_tiles(cond, context)
	if cond.turns <= 0:
		errors.append(
			(
				"DataManager: map '%s' survive condition in group '%s' requires turns > 0"
				% [context.get("map_path", ""), context.get("group_name", "")]
			)
		)
	return errors


func _validate_tiles(cond: ObjectiveCondition, context: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for tile in cond.tiles:
		if not _inside(tile, context):
			errors.append(
				(
					"DataManager: map '%s' %s condition in group '%s' tile %s is outside the grid"
					% [
						context.get("map_path", ""),
						cond.type,
						context.get("group_name", ""),
						str(tile)
					]
				)
			)
	return errors


func _inside(tile: Vector2i, context: Dictionary) -> bool:
	var width := int(context.get("width", 0))
	var height := int(context.get("height", 0))
	return (
		width <= 0
		or height <= 0
		or (tile.x >= 0 and tile.y >= 0 and tile.x < width and tile.y < height)
	)


func _display_rout(cond: ObjectiveCondition) -> String:
	return "Rout all hostiles" if cond.faction_id == "" else "Rout %s" % cond.faction_id


func _display_defeat_boss(cond: ObjectiveCondition) -> String:
	return "Defeat boss" if cond.unit_ids.is_empty() else "Defeat %s" % ", ".join(cond.unit_ids)


func _display_seize(cond: ObjectiveCondition) -> String:
	return (
		"Seize"
		if cond.tile == Vector2i(-1, -1)
		else "Seize (%d, %d)" % [cond.tile.x + 1, cond.tile.y + 1]
	)


func _display_escape(cond: ObjectiveCondition) -> String:
	return "Escape" if cond.unit_ids.is_empty() else "Escape: %s" % ", ".join(cond.unit_ids)


func _display_survive(cond: ObjectiveCondition) -> String:
	if cond.tiles.is_empty():
		return "Survive %d turn(s)" % cond.turns
	var tile_labels: Array[String] = []
	for tile in cond.tiles:
		tile_labels.append("(%d, %d)" % [tile.x + 1, tile.y + 1])
	return "Hold %s for %d turn(s)" % [", ".join(tile_labels), cond.turns]


func _display_protect(cond: ObjectiveCondition) -> String:
	return "Protect" if cond.unit_ids.is_empty() else "Protect: %s" % ", ".join(cond.unit_ids)


func _display_turn_limit(cond: ObjectiveCondition) -> String:
	return "Win before turn %d" % cond.turns
