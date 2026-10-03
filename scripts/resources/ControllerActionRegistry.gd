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

# A descriptor may declare itself REQUIRED, which means the player cannot turn it
# off. The set is deliberately tiny — the directional cross plus Confirm and Back
# — because it exists for exactly one failure: those are the controls that reach
# and work the Settings screen, so hiding them would hide the row that unhides
# them. It is the same trap the profile-without-a-cross owner call named, arriving
# by a different door, and the remedy is the same. Everything else is the player's
# to remove: Zoom, Danger Zone and the unit-cycling controls are convenience, and
# on a small screen the space they take is worth more than they are.
#
# Enforced in TWO places on purpose. Refusing the toggle stops the player doing it;
# drawing a required control even when a saved layout says otherwise stops a
# hand-edited or corrupt cfg doing it, where there is no UI to refuse.

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
		"required": true,
		"x": 0.12,
		"y": 0.64,
		"portrait_x": 0.22,
		"portrait_y": 0.776,
	},
	{
		"id": "dpad_down",
		"action": "cursor_down",
		"label": "Down",
		"group": "dpad",
		"profiles": [PROFILE_VIRTUAL_GAMEPAD],
		"required": true,
		"x": 0.12,
		"y": 0.88,
		"portrait_x": 0.22,
		"portrait_y": 0.864,
	},
	{
		"id": "dpad_left",
		"action": "cursor_left",
		"label": "Left",
		"group": "dpad",
		"profiles": [PROFILE_VIRTUAL_GAMEPAD],
		"required": true,
		"x": 0.05,
		"y": 0.76,
		"portrait_x": 0.13,
		"portrait_y": 0.82,
	},
	{
		"id": "dpad_right",
		"action": "cursor_right",
		"label": "Right",
		"group": "dpad",
		"profiles": [PROFILE_VIRTUAL_GAMEPAD],
		"required": true,
		"x": 0.19,
		"y": 0.76,
		"portrait_x": 0.31,
		"portrait_y": 0.82,
	},
	{
		"id": "pad_south",
		"action": "confirm",
		"label": "Confirm",
		"group": "face",
		"profiles": [PROFILE_VIRTUAL_GAMEPAD],
		"required": true,
		"x": 0.88,
		"y": 0.88,
		"portrait_x": 0.78,
		"portrait_y": 0.864,
	},
	{
		"id": "pad_east",
		"action": "cancel",
		"label": "Back",
		"group": "face",
		"profiles": [PROFILE_VIRTUAL_GAMEPAD],
		"required": true,
		"x": 0.95,
		"y": 0.76,
		"portrait_x": 0.87,
		"portrait_y": 0.82,
	},
	{
		"id": "pad_west",
		"action": "inspect_unit",
		"label": "Info",
		"group": "face",
		"profiles": [PROFILE_VIRTUAL_GAMEPAD],
		"x": 0.81,
		"y": 0.76,
		"portrait_x": 0.69,
		"portrait_y": 0.82,
	},
	{
		"id": "pad_north",
		"action": "more_info",
		"label": "More",
		"group": "face",
		"profiles": [PROFILE_VIRTUAL_GAMEPAD],
		"x": 0.88,
		"y": 0.64,
		"portrait_x": 0.78,
		"portrait_y": 0.776,
	},
	{
		"id": "shoulder_left",
		"action": "prev_unit",
		"label": "Previous Unit",
		"group": "shoulder",
		"profiles": [PROFILE_VIRTUAL_GAMEPAD],
		"x": 0.05,
		"y": 0.10,
		"portrait_x": 0.12,
		"portrait_y": 0.64,
	},
	{
		"id": "shoulder_right",
		"action": "next_unit",
		"label": "Next Unit",
		"group": "shoulder",
		"profiles": [PROFILE_VIRTUAL_GAMEPAD],
		"x": 0.95,
		"y": 0.10,
		"portrait_x": 0.88,
		"portrait_y": 0.64,
	},
	{
		"id": "pad_select",
		"action": "show_danger_zone",
		"label": "Danger Zone",
		"group": "system",
		"profiles": [PROFILE_VIRTUAL_GAMEPAD],
		"x": 0.42,
		"y": 0.94,
		"portrait_x": 0.38,
		"portrait_y": 0.95,
	},
	{
		"id": "pad_start",
		"action": "open_menu",
		"label": "Menu",
		"group": "system",
		"profiles": [PROFILE_VIRTUAL_GAMEPAD],
		"x": 0.58,
		"y": 0.94,
		"portrait_x": 0.62,
		"portrait_y": 0.95,
	},
	# ── Labeled actions: engine-authored words, fixed semantics ───────────────
	# These labels never change with a physical-pad rebinding; that is the whole
	# point of the profile, so no glyph is resolved for them.
	#
	# The directional cross comes FIRST because without it this profile could not
	# move a menu highlight at all: menu navigation runs on ui_up/ui_down, which
	# only the cursor_* actions mirror, so a phone on the default profile could
	# render nine controls and still not reach the Settings screen that offers the
	# other profile. Owner call 2026-08-05: both profiles carry a d-pad.
	#
	# Separate descriptors rather than adding this profile to the `dpad_*` entries:
	# a descriptor carries ONE placement per orientation, and the virtual pad's
	# cross sits exactly where this profile's word grid already is. The registry
	# already pairs two ids to one action this way (`act_confirm` and `pad_south`
	# both fire `confirm`), so this is the established shape, not a new one.
	#
	# Group `dpad`, not `action`: the shell renders `action` as a 1.9x-wide pill,
	# which cannot form a cross without the arms overlapping, and round directional
	# buttons are also what a player expects to read as a d-pad.
	{
		"id": "act_up",
		"action": "cursor_up",
		"label": "Up",
		"group": "dpad",
		"profiles": [PROFILE_LABELED_ACTIONS],
		"required": true,
		"x": 0.43,
		"y": 0.66,
		"portrait_x": 0.24,
		"portrait_y": 0.491,
	},
	{
		"id": "act_down",
		"action": "cursor_down",
		"label": "Down",
		"group": "dpad",
		"profiles": [PROFILE_LABELED_ACTIONS],
		"required": true,
		"x": 0.43,
		"y": 0.90,
		"portrait_x": 0.24,
		"portrait_y": 0.622,
	},
	{
		"id": "act_left",
		"action": "cursor_left",
		"label": "Left",
		"group": "dpad",
		"profiles": [PROFILE_LABELED_ACTIONS],
		"required": true,
		"x": 0.36,
		"y": 0.78,
		"portrait_x": 0.11,
		"portrait_y": 0.557,
	},
	{
		"id": "act_right",
		"action": "cursor_right",
		"label": "Right",
		"group": "dpad",
		"profiles": [PROFILE_LABELED_ACTIONS],
		"required": true,
		"x": 0.50,
		"y": 0.78,
		"portrait_x": 0.37,
		"portrait_y": 0.557,
	},
	{
		"id": "act_confirm",
		"action": "confirm",
		"label": "Confirm",
		"group": "action",
		"profiles": [PROFILE_LABELED_ACTIONS],
		"required": true,
		"x": 0.91,
		"y": 0.88,
		"portrait_x": 0.82,
		"portrait_y": 0.94,
	},
	{
		"id": "act_back",
		"action": "cancel",
		"label": "Back",
		"group": "action",
		"profiles": [PROFILE_LABELED_ACTIONS],
		"required": true,
		"x": 0.76,
		"y": 0.88,
		"portrait_x": 0.5,
		"portrait_y": 0.94,
	},
	{
		"id": "act_menu",
		"action": "open_menu",
		"label": "Menu",
		"group": "action",
		"profiles": [PROFILE_LABELED_ACTIONS],
		"x": 0.91,
		"y": 0.70,
		"portrait_x": 0.82,
		"portrait_y": 0.7,
	},
	{
		"id": "act_info",
		"action": "inspect_unit",
		"label": "Info",
		"group": "action",
		"profiles": [PROFILE_LABELED_ACTIONS],
		"x": 0.76,
		"y": 0.70,
		"portrait_x": 0.82,
		"portrait_y": 0.82,
	},
	{
		"id": "act_more",
		"action": "more_info",
		"label": "More",
		"group": "action",
		"profiles": [PROFILE_LABELED_ACTIONS],
		"x": 0.61,
		"y": 0.88,
		"portrait_x": 0.18,
		"portrait_y": 0.94,
	},
	{
		"id": "act_prev_unit",
		"action": "prev_unit",
		"label": "Prev Unit",
		"group": "action",
		"profiles": [PROFILE_LABELED_ACTIONS],
		"x": 0.09,
		"y": 0.88,
		"portrait_x": 0.18,
		"portrait_y": 0.82,
	},
	{
		"id": "act_next_unit",
		"action": "next_unit",
		"label": "Next Unit",
		"group": "action",
		"profiles": [PROFILE_LABELED_ACTIONS],
		"x": 0.24,
		"y": 0.88,
		"portrait_x": 0.5,
		"portrait_y": 0.82,
	},
	{
		"id": "act_zoom_in",
		"action": "zoom_in",
		"label": "Zoom In",
		"group": "action",
		"profiles": [PROFILE_LABELED_ACTIONS],
		"x": 0.09,
		"y": 0.70,
		"portrait_x": 0.18,
		"portrait_y": 0.7,
	},
	{
		"id": "act_zoom_out",
		"action": "zoom_out",
		"label": "Zoom Out",
		"group": "action",
		"profiles": [PROFILE_LABELED_ACTIONS],
		"x": 0.24,
		"y": 0.70,
		"portrait_x": 0.5,
		"portrait_y": 0.7,
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
		# Defaults to FALSE, so a descriptor that says nothing is removable. The
		# opposite default would make every third-party control unhideable by
		# omission, which is the wrong way round for a setting whose whole purpose
		# is reclaiming screen space.
		"required": source.get("required", false) is bool and source.get("required", false),
		"x": clampf(_number(source.get("x", 0.5), 0.5), 0.0, 1.0),
		"y": clampf(_number(source.get("y", 0.5), 0.5), 0.0, 1.0),
		# Portrait needs its own placement, not a reflowed landscape one. The same
		# fraction means a very different pixel offset on a 412-wide screen than on
		# an 863-wide one, which is what pushed the landscape defaults off both
		# edges the moment portrait became playable. Falls back to the landscape
		# value so a third-party descriptor need not know about orientations.
		"portrait_x":
		clampf(_number(source.get("portrait_x", source.get("x", 0.5)), 0.5), 0.0, 1.0),
		"portrait_y":
		clampf(_number(source.get("portrait_y", source.get("y", 0.5)), 0.5), 0.0, 1.0),
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


# Whether this control may be turned off. An UNREGISTERED id answers false rather
# than true: it names nothing that can be drawn, so treating it as required would
# have the payload filter keep drawing a control the registry cannot describe.
func is_required(id: String) -> bool:
	var found: Dictionary = _descriptors.get(id, {})
	return bool(found.get("required", false))


func ids_for_profile(profile: String) -> Array[String]:
	var result: Array[String] = []
	for id in _order:
		var found: Dictionary = _descriptors[id]
		if profile in found.profiles:
			result.append(id)
	return result


# Starting element list for a profile in the shape ControllerLayout stores, so a
# fresh combination can be saved and edited like any authored one.
func default_elements(profile: String, orientation: String = "landscape") -> Array[Dictionary]:
	var elements: Array[Dictionary] = []
	var use_portrait := orientation == "portrait"
	for id in ids_for_profile(profile):
		var found: Dictionary = _descriptors[id]
		(
			elements
			. append(
				{
					"id": id,
					"action": found.action,
					"x": found.portrait_x if use_portrait else found.x,
					"y": found.portrait_y if use_portrait else found.y,
					"scale": found.scale,
					"opacity": 1.0,
					# Every registered control starts on. A descriptor cannot ship
					# hidden: the player would have to discover a control they have
					# never seen before they could ask for it.
					"enabled": true,
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
