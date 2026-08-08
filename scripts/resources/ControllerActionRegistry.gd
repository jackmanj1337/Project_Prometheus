class_name ControllerActionRegistry
extends RefCounted

# Open registry of on-screen controller elements. Adding a control is a
# descriptor entry, never a new branch in a `match` — the same author-extensible
# shape the objective/AI/effect registries use.
#
# A descriptor is the ONLY thing that maps an element id to an InputMap action.
# Saved layouts and the browser shell address elements by id and never carry an
# action string of their own, so neither a corrupt save nor a compromised shell
# can fire an action that was not registered here. That is the allow-list the
# implementation plan requires ("no evaluated action strings cross the bridge").

const PROFILE_VIRTUAL_GAMEPAD := "virtual_gamepad"
const PROFILE_LABELED_ACTIONS := "labeled_actions"
const VALID_PROFILES: Array[String] = [PROFILE_VIRTUAL_GAMEPAD, PROFILE_LABELED_ACTIONS]

# Presentation grouping only. Themes use it to pick artwork families; nothing in
# the input path reads it, so a new group needs no engine change.
const VALID_GROUPS: Array[String] = ["dpad", "face", "shoulder", "system", "action"]

# Built-in descriptors. Coordinates are normalized to the controller surface
# (the full browser rectangle), so they survive any device size or pixel ratio.
# Slice 4's editor overwrites them per saved combination; these are only the
# starting placement.
const BUILTIN_DESCRIPTORS: Array[Dictionary] = [
	# ── Virtual gamepad: physical pad shape, logical actions ──────────────────
	# The glyph a player sees is resolved from the live InputMap binding, so
	# rebinding Confirm from A to B relabels this control without moving it.
	{
		"id": "dpad_up",
		"action": "cursor_up",
		"label": "Up",
		"group": "dpad",
		"profiles": [PROFILE_VIRTUAL_GAMEPAD],
		"x": 0.12,
		"y": 0.64,
	},
	{
		"id": "dpad_down",
		"action": "cursor_down",
		"label": "Down",
		"group": "dpad",
		"profiles": [PROFILE_VIRTUAL_GAMEPAD],
		"x": 0.12,
		"y": 0.88,
	},
	{
		"id": "dpad_left",
		"action": "cursor_left",
		"label": "Left",
		"group": "dpad",
		"profiles": [PROFILE_VIRTUAL_GAMEPAD],
		"x": 0.05,
		"y": 0.76,
	},
	{
		"id": "dpad_right",
		"action": "cursor_right",
		"label": "Right",
		"group": "dpad",
		"profiles": [PROFILE_VIRTUAL_GAMEPAD],
		"x": 0.19,
		"y": 0.76,
	},
	{
		"id": "pad_south",
		"action": "confirm",
		"label": "Confirm",
		"group": "face",
		"profiles": [PROFILE_VIRTUAL_GAMEPAD],
		"x": 0.88,
		"y": 0.88,
	},
	{
		"id": "pad_east",
		"action": "cancel",
		"label": "Back",
		"group": "face",
		"profiles": [PROFILE_VIRTUAL_GAMEPAD],
		"x": 0.95,
		"y": 0.76,
	},
	{
		"id": "pad_west",
		"action": "inspect_unit",
		"label": "Info",
		"group": "face",
		"profiles": [PROFILE_VIRTUAL_GAMEPAD],
		"x": 0.81,
		"y": 0.76,
	},
	{
		"id": "pad_north",
		"action": "more_info",
		"label": "More",
		"group": "face",
		"profiles": [PROFILE_VIRTUAL_GAMEPAD],
		"x": 0.88,
		"y": 0.64,
	},
	{
		"id": "shoulder_left",
		"action": "prev_unit",
		"label": "Previous Unit",
		"group": "shoulder",
		"profiles": [PROFILE_VIRTUAL_GAMEPAD],
		"x": 0.05,
		"y": 0.10,
	},
	{
		"id": "shoulder_right",
		"action": "next_unit",
		"label": "Next Unit",
		"group": "shoulder",
		"profiles": [PROFILE_VIRTUAL_GAMEPAD],
		"x": 0.95,
		"y": 0.10,
	},
	{
		"id": "pad_select",
		"action": "show_danger_zone",
		"label": "Danger Zone",
		"group": "system",
		"profiles": [PROFILE_VIRTUAL_GAMEPAD],
		"x": 0.42,
		"y": 0.94,
	},
	{
		"id": "pad_start",
		"action": "open_menu",
		"label": "Menu",
		"group": "system",
		"profiles": [PROFILE_VIRTUAL_GAMEPAD],
		"x": 0.58,
		"y": 0.94,
	},
	# ── Labeled actions: engine-authored words, fixed semantics ───────────────
	# These labels never change with a physical-pad rebinding; that is the whole
	# point of the profile, so no glyph is resolved for them.
	{
		"id": "act_confirm",
		"action": "confirm",
		"label": "Confirm",
		"group": "action",
		"profiles": [PROFILE_LABELED_ACTIONS],
		"x": 0.91,
		"y": 0.88,
	},
	{
		"id": "act_back",
		"action": "cancel",
		"label": "Back",
		"group": "action",
		"profiles": [PROFILE_LABELED_ACTIONS],
		"x": 0.76,
		"y": 0.88,
	},
	{
		"id": "act_menu",
		"action": "open_menu",
		"label": "Menu",
		"group": "action",
		"profiles": [PROFILE_LABELED_ACTIONS],
		"x": 0.91,
		"y": 0.70,
	},
	{
		"id": "act_info",
		"action": "inspect_unit",
		"label": "Info",
		"group": "action",
		"profiles": [PROFILE_LABELED_ACTIONS],
		"x": 0.76,
		"y": 0.70,
	},
	{
		"id": "act_more",
		"action": "more_info",
		"label": "More",
		"group": "action",
		"profiles": [PROFILE_LABELED_ACTIONS],
		"x": 0.61,
		"y": 0.88,
	},
	{
		"id": "act_prev_unit",
		"action": "prev_unit",
		"label": "Prev Unit",
		"group": "action",
		"profiles": [PROFILE_LABELED_ACTIONS],
		"x": 0.09,
		"y": 0.88,
	},
	{
		"id": "act_next_unit",
		"action": "next_unit",
		"label": "Next Unit",
		"group": "action",
		"profiles": [PROFILE_LABELED_ACTIONS],
		"x": 0.24,
		"y": 0.88,
	},
	{
		"id": "act_zoom_in",
		"action": "zoom_in",
		"label": "Zoom In",
		"group": "action",
		"profiles": [PROFILE_LABELED_ACTIONS],
		"x": 0.09,
		"y": 0.70,
	},
	{
		"id": "act_zoom_out",
		"action": "zoom_out",
		"label": "Zoom Out",
		"group": "action",
		"profiles": [PROFILE_LABELED_ACTIONS],
		"x": 0.24,
		"y": 0.70,
	},
]

var _descriptors: Dictionary = {}
var _order: Array[String] = []


func _init(seed_builtins: bool = true) -> void:
	if seed_builtins:
		for descriptor in BUILTIN_DESCRIPTORS:
			var errors := register(descriptor)
			assert(errors.is_empty(), "built-in controller descriptor rejected: " + str(errors))


# Registers one descriptor. Returns the reasons it was rejected, empty on success
# — fail closed, so a malformed entry never becomes a half-working control.
func register(raw: Variant) -> Array[String]:
	var errors: Array[String] = []
	if not raw is Dictionary:
		return ["descriptor is not a Dictionary"]
	var source: Dictionary = raw

	var id := _text(source.get("id", ""))
	var action := _text(source.get("action", ""))
	var label := _text(source.get("label", ""))
	var group := _text(source.get("group", "action"))
	if id.is_empty():
		errors.append("descriptor is missing an id")
	elif _descriptors.has(id):
		errors.append("descriptor id '%s' is already registered" % id)
	if action.is_empty():
		errors.append("descriptor '%s' is missing an InputMap action" % id)
	if label.is_empty():
		errors.append("descriptor '%s' is missing a player-facing label" % id)
	if not group in VALID_GROUPS:
		errors.append("descriptor '%s' has unknown group '%s'" % [id, group])

	var profiles: Array[String] = []
	var raw_profiles: Variant = source.get("profiles", [])
	if raw_profiles is Array:
		for value: Variant in raw_profiles:
			var profile := _text(value)
			if profile in VALID_PROFILES and not profile in profiles:
				profiles.append(profile)
	if profiles.is_empty():
		errors.append("descriptor '%s' names no valid profile" % id)

	if not errors.is_empty():
		return errors

	_descriptors[id] = {
		"id": id,
		"action": action,
		"label": label,
		"group": group,
		"profiles": profiles,
		"x": clampf(_number(source.get("x", 0.5), 0.5), 0.0, 1.0),
		"y": clampf(_number(source.get("y", 0.5), 0.5), 0.0, 1.0),
		"scale": clampf(_number(source.get("scale", 1.0), 1.0), 0.5, 3.0),
	}
	_order.append(id)
	return errors


func has(id: String) -> bool:
	return _descriptors.has(id)


func descriptor(id: String) -> Dictionary:
	var found: Dictionary = _descriptors.get(id, {})
	return found.duplicate(true)


# The allow-list gate. An element id that was never registered resolves to "",
# which every caller treats as "ignore this event".
func action_for(id: String) -> String:
	var found: Dictionary = _descriptors.get(id, {})
	return String(found.get("action", ""))


func ids_for_profile(profile: String) -> Array[String]:
	var result: Array[String] = []
	for id in _order:
		var found: Dictionary = _descriptors[id]
		if profile in found.profiles:
			result.append(id)
	return result


# Starting element list for a profile in the shape ControllerLayout stores, so a
# fresh combination can be saved and edited like any authored one.
func default_elements(profile: String) -> Array[Dictionary]:
	var elements: Array[Dictionary] = []
	for id in ids_for_profile(profile):
		var found: Dictionary = _descriptors[id]
		(
			elements
			. append(
				{
					"id": id,
					"action": found.action,
					"x": found.x,
					"y": found.y,
					"scale": found.scale,
					"opacity": 1.0,
				}
			)
		)
	return elements


static func _text(value: Variant) -> String:
	return (value as String).strip_edges() if value is String else ""


static func _number(value: Variant, fallback: float) -> float:
	if value is float or value is int:
		var number := float(value)
		return number if is_finite(number) else fallback
	return fallback
