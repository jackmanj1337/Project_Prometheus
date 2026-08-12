extends Node

# Persistent on-screen controller service.
#
# Slice 2 of the mobile-web viewport/controller plan. It replaces the map-local
# touch overlay with one service that lives for the whole session, so a control
# held while a scene changes cannot leave an action stuck down — the previous
# overlay was freed mid-press and the action stayed pressed forever.
#
# Division of labour (see the implementation plan §3):
#   - Godot owns the model, validation, persistence, the action allow-list, and
#     every press/release transition.
#   - The browser shell owns the DOM, pointer capture, and hit testing, because
#     only it can put controls OUTSIDE the game canvas.
# The shell is told what to draw and reports element ids back; it never names an
# InputMap action, so it cannot invent one.

signal layout_changed(payload: Dictionary)
signal editing_changed(editing: bool)
signal action_pressed(action: String)
signal action_released(action: String)

const ControllerLayoutS = preload("res://scripts/resources/ControllerLayout.gd")
const ControllerActionRegistryS = preload("res://scripts/resources/ControllerActionRegistry.gd")
const ControllerPressLedgerS = preload("res://scripts/resources/ControllerPressLedger.gd")
const InputDisplay = preload("res://scripts/shared/InputDisplay.gd")

const PAYLOAD_VERSION := 1
const PROFILE_OFF := "off"

# Minimal-black default presentation. Slice 5 replaces this with the validated
# `controller_theme` registry; the colours cross the bridge as plain strings so
# a campaign can never hand the shell CSS or script.
const DEFAULT_THEME_COLORS := {
	"surface": "#000000",
	"button": "#141414",
	"button_pressed": "#3c3c3c",
	"label": "#f0f0f0",
	"outline": "#787878",
}
const HEX_COLOR_PATTERN := "^#[0-9a-fA-F]{6}$"

var registry: ControllerActionRegistry = null

var _ledger: ControllerPressLedger = null
var _combinations: Array[Dictionary] = []
var _active: Dictionary = {}
var _orientation: String = "landscape"
var _editing: bool = false
var _hex_regex: RegEx = null


func _ready() -> void:
	# ALWAYS so a paused tree still releases held actions; a stuck action that
	# survives the pause menu is exactly the bug this service exists to prevent.
	process_mode = Node.PROCESS_MODE_ALWAYS
	registry = ControllerActionRegistryS.new()
	_ledger = ControllerPressLedgerS.new()
	_hex_regex = RegEx.new()
	_hex_regex.compile(HEX_COLOR_PATTERN)
	_combinations = ControllerLayoutS.default_collection()
	_select_active()


# ── Layout state ─────────────────────────────────────────────────────────────


func set_combinations(combinations: Array) -> void:
	var normalized: Array[Dictionary] = []
	for raw: Variant in combinations:
		normalized.append(ControllerLayoutS.normalize(raw))
	_combinations = (
		normalized if not normalized.is_empty() else ControllerLayoutS.default_collection()
	)
	_select_active()


func combinations() -> Array[Dictionary]:
	return _combinations.duplicate(true)


func active_combination() -> Dictionary:
	return _active.duplicate(true)


func set_orientation(orientation: String) -> void:
	var wanted := orientation if orientation in ["portrait", "landscape"] else "landscape"
	if wanted == _orientation:
		return
	_orientation = wanted
	# Rotating swaps the whole layout under the player's fingers, so anything
	# still held belongs to a layout that no longer exists.
	_select_active()


func orientation() -> String:
	return _orientation


# Applies one combination directly (Slice 4's editor and preview path).
func apply_combination(combination: Dictionary) -> void:
	release_all_actions()
	_active = ControllerLayoutS.normalize(combination)
	if _active.elements.is_empty():
		_active.elements = registry.default_elements(_active.profile)
	layout_changed.emit(build_payload())


func set_profile(profile: String) -> void:
	var wanted: String = (
		profile
		if profile in ControllerLayoutS.VALID_PROFILES
		else String(_active.get("profile", PROFILE_OFF))
	)
	if wanted == _active.get("profile", ""):
		return
	var next: Dictionary = _active.duplicate(true)
	next.profile = wanted
	# Element ids are profile-specific, so the previous layout cannot carry over.
	next.elements = registry.default_elements(wanted)
	apply_combination(next)


func profile() -> String:
	return String(_active.get("profile", PROFILE_OFF))


# ── Editing mode ─────────────────────────────────────────────────────────────


# Entering the editor pauses gameplay and hands every pointer to the editor, so
# dragging a control must not also play the game.
func set_editing(editing: bool) -> void:
	if _editing == editing:
		return
	_editing = editing
	release_all_actions()
	editing_changed.emit(_editing)
	layout_changed.emit(build_payload())


func is_editing() -> bool:
	return _editing


# ── Press / release ──────────────────────────────────────────────────────────


# Reports a pointer going down on `element_id`. Returns true when the event was
# accepted (registered element, present in the active profile, not editing).
func press(pointer_id: String, element_id: String) -> bool:
	if _ledger == null or _editing or profile() == PROFILE_OFF:
		return false
	var action := _allowed_action(element_id)
	if action.is_empty():
		return false
	_apply_transitions(_ledger.press(pointer_id, action))
	return true


func release(pointer_id: String) -> bool:
	# Held-ness is checked first: a release is still "accepted" when a second
	# pointer keeps the action down and no transition is reported.
	if _ledger == null or not _ledger.is_pointer_held(pointer_id):
		return false
	var released := _ledger.release(pointer_id)
	if not released.is_empty():
		_emit_action(released, false)
	return true


# The single cleanup path for every lifecycle transition: pointer cancel, blur,
# visibility loss, layout/profile change, orientation change, and editor entry.
func release_all_actions() -> Array[String]:
	if _ledger == null:
		return []
	var released := _ledger.release_all()
	for action in released:
		_emit_action(action, false)
	return released


func held_actions() -> Array[String]:
	return _ledger.held_actions() if _ledger != null else []


# ── Bridge payload ───────────────────────────────────────────────────────────


# Everything the shell needs to draw the controller, and nothing else. Element
# actions are resolved from the registry rather than copied from the saved
# layout, so a tampered save cannot rebind a control to another action.
func build_payload() -> Dictionary:
	var brand := InputDisplay.active_pad_brand_for_tree(self)
	return build_payload_for(_active, registry, brand, _editing, _theme_colors())


static func build_payload_for(
	combination: Dictionary,
	action_registry: ControllerActionRegistry,
	brand: int,
	editing: bool,
	theme_colors: Dictionary
) -> Dictionary:
	var normalized := ControllerLayoutS.normalize(combination)
	var active_profile := String(normalized.profile)
	var elements: Array[Dictionary] = []
	var source: Array = normalized.elements
	if source.is_empty() and action_registry != null and active_profile != PROFILE_OFF:
		source = action_registry.default_elements(active_profile)

	var seen: Dictionary = {}
	for raw: Variant in source:
		if not raw is Dictionary or action_registry == null:
			continue
		var element: Dictionary = raw
		var id := String(element.get("id", ""))
		if seen.has(id) or not action_registry.has(id):
			continue
		var descriptor := action_registry.descriptor(id)
		if not active_profile in descriptor.profiles:
			continue
		seen[id] = true
		(
			elements
			. append(
				{
					"id": id,
					# Registry-owned, never the saved value.
					"action": String(descriptor.action),
					"label": String(descriptor.label),
					"group": String(descriptor.group),
					# Labeled actions keep engine wording whatever the pad is bound
					# to; the virtual pad follows the live binding instead.
					"glyph":
					(
						InputDisplay.first_pad_label_for_action(String(descriptor.action), brand)
						if active_profile == ControllerActionRegistryS.PROFILE_VIRTUAL_GAMEPAD
						else ""
					),
					"x": float(element.get("x", descriptor.x)),
					"y": float(element.get("y", descriptor.y)),
					"scale": float(element.get("scale", descriptor.scale)),
					"opacity": float(element.get("opacity", 1.0)),
				}
			)
		)

	return {
		"payload_version": PAYLOAD_VERSION,
		"schema_version": int(normalized.schema_version),
		"combination_id": String(normalized.id),
		"profile": active_profile,
		"theme": String(normalized.theme),
		"colors": theme_colors,
		"global_opacity": float(normalized.global_opacity),
		"viewport": normalized.viewport,
		"editing": editing,
		"elements": elements,
	}


func payload_json() -> String:
	return JSON.stringify(build_payload())


# ── Internals ────────────────────────────────────────────────────────────────


func _select_active() -> void:
	release_all_actions()
	_active = ControllerLayoutS.select_for_orientation(_combinations, _orientation)
	if _active.elements.is_empty():
		_active.elements = registry.default_elements(_active.profile)
	layout_changed.emit(build_payload())


func _allowed_action(element_id: String) -> String:
	if registry == null or not registry.has(element_id):
		return ""
	var descriptor := registry.descriptor(element_id)
	if not profile() in descriptor.profiles:
		return ""
	return String(descriptor.action)


func _apply_transitions(transitions: Dictionary) -> void:
	var released := String(transitions.get("released", ""))
	if not released.is_empty():
		_emit_action(released, false)
	var pressed := String(transitions.get("pressed", ""))
	if not pressed.is_empty():
		_emit_action(pressed, true)


func _emit_action(action: String, pressed: bool) -> void:
	if not InputMap.has_action(action):
		# A descriptor can name an action a campaign build does not define; drop
		# it rather than crashing the input path.
		return
	if pressed:
		Input.action_press(action)
		action_pressed.emit(action)
	else:
		Input.action_release(action)
		action_released.emit(action)


# Rejects anything that is not a plain #rrggbb string, so no campaign-supplied
# value can reach the shell as a CSS expression.
func _theme_colors() -> Dictionary:
	var colors: Dictionary = {}
	for key: String in DEFAULT_THEME_COLORS:
		colors[key] = validated_color(DEFAULT_THEME_COLORS[key], "#000000", _hex_regex)
	return colors


static func validated_color(value: Variant, fallback: String, regex: RegEx) -> String:
	if not value is String or regex == null:
		return fallback
	return value if regex.search(value) != null else fallback


# Losing focus, backgrounding, or closing stops pointer-up delivery, so anything
# held at that moment would otherwise stay down until the player taps it again.
const RELEASE_NOTIFICATIONS: Array[int] = [
	NOTIFICATION_APPLICATION_FOCUS_OUT,
	NOTIFICATION_WM_WINDOW_FOCUS_OUT,
	NOTIFICATION_APPLICATION_PAUSED,
	NOTIFICATION_WM_CLOSE_REQUEST,
]


func _notification(what: int) -> void:
	if what in RELEASE_NOTIFICATIONS:
		release_all_actions()
