class_name ControllerLayout
extends RefCounted

# Pure, platform-neutral saved-layout contract. The web shell renders this data,
# while Godot remains authoritative for validation, migration, and persistence.

const SCHEMA_VERSION := 1
const VALID_ORIENTATIONS: Array[String] = ["portrait", "landscape", "both"]
const VALID_PROFILES: Array[String] = ["off", "virtual_gamepad", "labeled_actions"]
const DEFAULT_THEME := "prometheus:minimal_black"
const MIN_VIEWPORT_PIXELS := Vector2(640.0, 360.0)
const DEFAULT_SLOT_COUNT := 6

# Per-element edit bounds, named rather than inlined in the clamp below because
# the Settings sliders have to offer exactly this range. A slider authored to a
# wider range in the scene would let a player drag to a value the model silently
# clamps, so the control would stop responding partway along its travel.
const MIN_ELEMENT_SCALE := 0.5
const MAX_ELEMENT_SCALE := 3.0
# Not zero: a fully transparent control still takes touches, so it becomes an
# invisible dead zone the player cannot find again to undo.
const MIN_ELEMENT_OPACITY := 0.15
const MAX_ELEMENT_OPACITY := 1.0


static func default_combination(
	name: String = "Default", orientation: String = "both", slot: int = 0
) -> Dictionary:
	var safe_orientation := orientation if orientation in VALID_ORIENTATIONS else "both"
	return {
		"schema_version": SCHEMA_VERSION,
		"id": "default-%d" % maxi(slot, 0),
		"name": name.strip_edges() if not name.strip_edges().is_empty() else "Default",
		"orientation": safe_orientation,
		"viewport": default_viewport(safe_orientation),
		"profile": "labeled_actions",
		"theme": DEFAULT_THEME,
		"global_opacity": 0.72,
		"elements": [],
	}


static func default_collection() -> Array[Dictionary]:
	var presets: Array[Dictionary] = []
	var names := [
		"Fullscreen Overlay",
		"Landscape Side Grips",
		"Landscape Bottom Dock",
		"Portrait Controls Below",
		"Portrait Centered",
		"Compact One-Handed",
	]
	var orientations := ["both", "landscape", "landscape", "portrait", "portrait", "both"]
	for index in DEFAULT_SLOT_COUNT:
		presets.append(default_combination(names[index], orientations[index], index))
	return presets


static func normalize(raw: Variant) -> Dictionary:
	if not raw is Dictionary:
		return default_combination()
	var source: Dictionary = raw
	if int(source.get("schema_version", -1)) != SCHEMA_VERSION:
		return default_combination()

	var result := default_combination()
	result.id = _safe_text(source.get("id", result.id), result.id)
	result.name = _safe_text(source.get("name", result.name), result.name)
	result.orientation = _choice(source.get("orientation", "both"), VALID_ORIENTATIONS, "both")
	result.viewport = _normalize_viewport(source.get("viewport", {}), result.orientation)
	result.profile = _choice(source.get("profile", result.profile), VALID_PROFILES, result.profile)
	result.theme = _safe_text(source.get("theme", DEFAULT_THEME), DEFAULT_THEME)
	result.global_opacity = clampf(_safe_float(source.get("global_opacity", 0.72), 0.72), 0.0, 1.0)
	result.elements = _normalize_elements(source.get("elements", []))
	return result


# Computes the current device-specific rectangle without mutating the authored
# normalized geometry. That prevents clamp drift when rotating or changing devices.
static func effective_viewport(
	combination: Dictionary,
	available_pixels: Vector2,
	minimum_pixels: Vector2 = MIN_VIEWPORT_PIXELS
) -> Rect2:
	if available_pixels.x <= 0.0 or available_pixels.y <= 0.0:
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	var normalized := normalize(combination)
	var authored: Dictionary = normalized.viewport
	var min_size := Vector2(
		minf(minimum_pixels.x, available_pixels.x), minf(minimum_pixels.y, available_pixels.y)
	)
	var size := Vector2(
		clampf(float(authored.width) * available_pixels.x, min_size.x, available_pixels.x),
		clampf(float(authored.height) * available_pixels.y, min_size.y, available_pixels.y)
	)
	var position := Vector2(
		clampf(float(authored.x) * available_pixels.x, 0.0, available_pixels.x - size.x),
		clampf(float(authored.y) * available_pixels.y, 0.0, available_pixels.y - size.y)
	)
	return Rect2(position, size)


static func select_for_orientation(combinations: Array, orientation: String) -> Dictionary:
	var wanted := orientation if orientation in ["portrait", "landscape"] else "landscape"
	var shared: Dictionary = {}
	for raw: Variant in combinations:
		var candidate := normalize(raw)
		if candidate.orientation == wanted:
			return candidate
		if candidate.orientation == "both" and shared.is_empty():
			shared = candidate
	return shared if not shared.is_empty() else default_combination("Default", wanted)


# Public because the Game View editor's Reset has to write it: unlike the element
# list, a viewport has no "empty means follow the built-in placement" state — it is
# one rect and every key is always present — so resetting means writing today's
# default rather than clearing an override.
static func default_viewport(orientation: String) -> Dictionary:
	if orientation == "portrait":
		return {"x": 0.05, "y": 0.03, "width": 0.90, "height": 0.55, "aspect_locked": true}
	return {"x": 0.0, "y": 0.0, "width": 1.0, "height": 1.0, "aspect_locked": false}


static func _normalize_viewport(raw: Variant, orientation: String) -> Dictionary:
	var fallback := default_viewport(orientation)
	if not raw is Dictionary:
		return fallback
	var source: Dictionary = raw
	return {
		"x": clampf(_safe_float(source.get("x", fallback.x), fallback.x), 0.0, 1.0),
		"y": clampf(_safe_float(source.get("y", fallback.y), fallback.y), 0.0, 1.0),
		"width":
		clampf(_safe_float(source.get("width", fallback.width), fallback.width), 0.01, 1.0),
		"height":
		clampf(_safe_float(source.get("height", fallback.height), fallback.height), 0.01, 1.0),
		"aspect_locked":
		(
			source.get("aspect_locked", fallback.aspect_locked) is bool
			and source.get("aspect_locked", fallback.aspect_locked)
		),
	}


static func _normalize_elements(raw: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not raw is Array:
		return result
	var seen_ids := {}
	for value: Variant in raw:
		if not value is Dictionary:
			continue
		var source: Dictionary = value
		var element_id := _safe_text(source.get("id", ""), "")
		var action := _safe_text(source.get("action", ""), "")
		if element_id.is_empty() or action.is_empty() or seen_ids.has(element_id):
			continue
		seen_ids[element_id] = true
		(
			result
			. append(
				{
					"id": element_id,
					"action": action,
					"x": clampf(_safe_float(source.get("x", 0.5), 0.5), 0.0, 1.0),
					"y": clampf(_safe_float(source.get("y", 0.5), 0.5), 0.0, 1.0),
					"scale":
					clampf(
						_safe_float(source.get("scale", 1.0), 1.0),
						MIN_ELEMENT_SCALE,
						MAX_ELEMENT_SCALE
					),
					"opacity":
					clampf(
						_safe_float(source.get("opacity", 1.0), 1.0),
						MIN_ELEMENT_OPACITY,
						MAX_ELEMENT_OPACITY
					),
					# Whether the control is drawn at all. Defaults to true so an
					# element written by an older build — every saved layout before
					# this field existed — keeps every control it had rather than
					# silently losing the ones it never mentioned.
					#
					# The model does NOT decide whether a false here is honoured:
					# it has no registry and so cannot know which controls a player
					# must keep. `ControllerService.build_payload_for()` makes that
					# call, which is what stops a hand-edited cfg hiding the Back
					# control that would undo it.
					"enabled": _safe_bool(source.get("enabled", true), true),
				}
			)
		)
	return result


static func _safe_text(value: Variant, fallback: String) -> String:
	if not value is String:
		return fallback
	var text: String = value.strip_edges()
	return text if not text.is_empty() else fallback


# Strict: only a real bool counts. Godot would happily read 0/""/[] as false, and
# a saved layout that carried a stray 0 in this field would drop the control
# rather than fall back to showing it.
static func _safe_bool(value: Variant, fallback: bool) -> bool:
	return value if value is bool else fallback


static func _safe_float(value: Variant, fallback: float) -> float:
	if value is float or value is int:
		var number := float(value)
		return number if is_finite(number) else fallback
	return fallback


static func _choice(value: Variant, choices: Array[String], fallback: String) -> String:
	return value if value is String and value in choices else fallback
