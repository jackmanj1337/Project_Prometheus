class_name PrepActivityRegistry extends RefCounted
# adopter-todo: PREP-V1-S01
# The Prep shell is this registry's only intended consumer. Adoption was RULED
# 2026-08-22 -- adopt and extend, keeping register_panel_type/create_panel and
# extending the descriptor with an availability predicate, a visibility mode and
# an explicit order -- so the shape of the adopter is settled, not open.

# Open PHB registry: engine code registers panel factories, while authored data
# selects a panel_type and supplies instance parameters. Concrete services own
# their persistent state; this registry deliberately stores no UI/save state.
var _factories: Dictionary = {}
var _activities: Dictionary = {}


func register_panel_type(panel_type: String, factory: Callable) -> Array[String]:
	var normalized := panel_type.strip_edges()
	if normalized.is_empty() or not factory.is_valid():
		return ["PrepActivityRegistry: panel type '%s' has no valid factory" % panel_type]
	if _factories.has(normalized):
		return ["PrepActivityRegistry: duplicate panel type '%s'" % normalized]
	_factories[normalized] = factory
	return []


func register_activity(activity: Resource) -> Array[String]:
	var errors := validate_activity(activity)
	if not errors.is_empty():
		return errors
	_activities[activity.id] = activity
	return []


func validate_activity(activity: Resource) -> Array[String]:
	var errors: Array[String] = []
	if activity == null:
		return ["PrepActivityRegistry: activity is null"]
	if activity.id.strip_edges().is_empty():
		errors.append("PrepActivityRegistry: activity id is empty")
	elif _activities.has(activity.id):
		errors.append("PrepActivityRegistry: duplicate activity id '%s'" % activity.id)
	if activity.panel_type.strip_edges().is_empty():
		errors.append("PrepActivityRegistry: activity '%s' has no panel type" % activity.id)
	elif not _factories.has(activity.panel_type):
		errors.append(
			(
				"PrepActivityRegistry: activity '%s' has unknown panel type '%s'"
				% [activity.id, activity.panel_type]
			)
		)
	return errors


func activity_ids() -> Array[String]:
	var result: Array[String] = []
	result.assign(_activities.keys())
	result.sort()
	return result


func create_panel(activity_id: String, context: Dictionary = {}) -> Variant:
	var activity: Resource = _activities.get(activity_id)
	if activity == null:
		return null
	var factory: Callable = _factories.get(activity.panel_type, Callable())
	if not factory.is_valid():
		return null
	return factory.call(activity.params.duplicate(true), context.duplicate(true))
