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
# Deliberately NOT folded into `layout_changed`: that signal makes the shell rebuild
# every button, which drops anything held. A window resize (the URL bar collapsing,
# say) must move the canvas without cancelling the press the player is mid-way through.
signal canvas_rect_changed(rect: Rect2)

const ControllerLayoutS = preload("res://scripts/resources/ControllerLayout.gd")
const ControllerActionRegistryS = preload("res://scripts/resources/ControllerActionRegistry.gd")
const ControllerPressLedgerS = preload("res://scripts/resources/ControllerPressLedger.gd")
const InputDisplay = preload("res://scripts/shared/InputDisplay.gd")
const SettingsManagerS = preload("res://scripts/autoloads/SettingsManager.gd")

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
# The slot the player explicitly chose, or "" for "follow the device orientation".
var _active_id: String = ""
var _orientation: String = "landscape"
var _available_pixels: Vector2 = Vector2.ZERO
var _editing: bool = false
var _hex_regex: RegEx = null
# What was in settings the last time this service loaded or saved. Compared against
# the live settings on `settings_changed` so the service reloads on a genuine
# external edit (a Controls reset, say) but ignores the echo of its own save —
# reloading would emit `layout_changed`, and that makes the shell rebuild every
# button, dropping whatever the player is holding.
var _persisted_snapshot: String = ""

# Held for the session's lifetime: the bridge owns the JavaScriptBridge callback
# the shell calls back through, and a RefCounted that nothing references is freed
# — which silently turns every control into a dead rectangle.
var _web_bridge: ControllerWebBridge = null


func _ready() -> void:
	# ALWAYS so a paused tree still releases held actions; a stuck action that
	# survives the pause menu is exactly the bug this service exists to prevent.
	process_mode = Node.PROCESS_MODE_ALWAYS
	registry = ControllerActionRegistryS.new()
	_ledger = ControllerPressLedgerS.new()
	_hex_regex = RegEx.new()
	_hex_regex.compile(HEX_COLOR_PATTERN)
	load_persisted_layout()
	_watch_settings()
	_install_web_bridge()


# The model above is platform-neutral and fully testable headless; this is the one
# place the running service is joined to the browser renderer. `install()` no-ops
# off the web platform, so desktop and the headless suites take no new dependency.
#
# Gated on a TOUCH web platform, not just "web": a desktop browser is `web_windows`
# / `web_macos` / `web_linux` and has a keyboard and mouse, so rendering on-screen
# buttons there would cover the game for players who cannot use them. This reuses
# the same web_ios/web_android probe the input-mode resolver already trusts rather
# than introducing a second, differently-wrong notion of "is this a touch device".
# Slice 4's Touch Controls submenu owns the player-facing override; this is only
# the default so the controls exist at all on a phone.
func _install_web_bridge() -> void:
	if not ControllerWebBridge.is_web() or not SettingsManagerS.has_web_touch_platform():
		return
	_web_bridge = ControllerWebBridge.new()
	if not _web_bridge.install(self):
		# Fail visibly rather than leaving the player wondering why the on-screen
		# controller never appeared: without the shell there is no renderer at all.
		push_warning("ControllerService: browser controller shell failed to install")
		_web_bridge = null


# ── Persistence ──────────────────────────────────────────────────────────────
#
# `save_layout()` is the ONLY method here that touches disk. Everything else
# mutates the in-memory model, which is what makes an editor preview cheap: a
# drag can re-apply a combination every frame without a ConfigFile write per
# tick. Callers persist deliberately, the same shape SettingsScreen already uses
# for Game View — set the fields, then commit.


# Restores the saved collection and the chosen slot. An empty collection is the
# never-saved state and falls back to the built-in six, so a first launch and a
# cleared cfg take the same path.
func restore_layout(combinations: Array, active_id: String) -> void:
	_active_id = active_id.strip_edges()
	set_combinations(combinations)


# The pair `SettingsManager` persists, normalized. Separated from `save_layout()`
# so the round-trip is testable without writing the shared user:// cfg.
func layout_settings_payload() -> Dictionary:
	return {"combinations": combinations(), "active_id": _active_id}


# One lookup for every persistence path, and the seam the tests replace so the
# save/load round-trip can be exercised without writing the shared user:// cfg
# that other suites read back in the same parallel run.
func _settings_node() -> Node:
	return get_node_or_null("/root/SettingsManager")


func load_persisted_layout() -> void:
	var settings := _settings_node()
	if settings == null:
		# No settings autoload (headless model tests): built-in defaults, and the
		# snapshot stays empty so a later settings_changed still reloads.
		restore_layout([], "")
		return
	var stored: Variant = settings.get("controller_combinations")
	restore_layout(stored if stored is Array else [], String(settings.get("controller_active_id")))
	_persisted_snapshot = _settings_snapshot(settings)


func save_layout() -> void:
	var settings := _settings_node()
	if settings == null:
		return
	var payload := layout_settings_payload()
	settings.set("controller_combinations", payload.combinations)
	settings.set("controller_active_id", payload.active_id)
	_persisted_snapshot = _settings_snapshot(settings)
	settings.call("save")


func _watch_settings() -> void:
	var settings := _settings_node()
	if (
		settings == null
		or not settings.has_signal("settings_changed")
		or settings.is_connected("settings_changed", _on_settings_changed)
	):
		return
	settings.connect("settings_changed", _on_settings_changed)


func _on_settings_changed() -> void:
	var settings := _settings_node()
	if settings == null:
		return
	var current := _settings_snapshot(settings)
	if current == _persisted_snapshot:
		return
	load_persisted_layout()


# Serialized rather than compared as a Dictionary: Array/Dictionary equality
# semantics differ between Godot versions, and a snapshot that silently compared
# by reference would make the reload fire on every settings save.
func _settings_snapshot(settings: Node) -> String:
	var stored: Variant = settings.get("controller_combinations")
	return (
		JSON
		. stringify(
			{
				"combinations": stored if stored is Array else [],
				"active_id": String(settings.get("controller_active_id")),
			}
		)
	)


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


func active_combination_id() -> String:
	return _active_id


# Picks one saved slot as the player's choice. Returns false when no slot carries
# that id, leaving the current selection alone — a stale id from a hand-edited cfg
# or a deleted slot must not blank the controls. Does NOT persist; the caller
# commits with `save_layout()`.
func select_combination(combination_id: String) -> bool:
	var wanted := combination_id.strip_edges()
	if wanted.is_empty():
		# The explicit "let the orientation decide" choice, which is a real option
		# in the selector and not the same as "no such slot".
		_active_id = ""
		_select_active()
		return true
	for raw: Variant in _combinations:
		if String(ControllerLayoutS.normalize(raw).id) != wanted:
			continue
		_active_id = wanted
		_select_active()
		return true
	return false


# Writes the live active combination back into the collection, so an edit made
# through `apply_combination()` becomes part of what `save_layout()` persists.
# Kept separate from `apply_combination()` because that is also the preview path:
# a drag applies continuously and must not rewrite the saved slot until released.
func commit_active_combination() -> void:
	if _active.is_empty():
		return
	var stored := ControllerLayoutS.normalize(_active)
	var target_id := String(stored.id)
	for index in _combinations.size():
		if String(_combinations[index].get("id", "")) != target_id:
			continue
		# Deliberately does NOT set `_active_id`. Editing the combination the
		# orientation picked is not the same as pinning it: a player who changes
		# control style while the arrangement is on Automatic would otherwise find
		# it silently pinned, and rotating would stop swapping layouts.
		_combinations[index] = stored
		return
	# A combination the collection has never seen is a new slot rather than an
	# error: "save as" is how the Touch Controls submenu adds one. This one DOES
	# become the choice, because a fresh slot is reachable no other way.
	_combinations.append(stored)
	_active_id = target_id


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


# Which placement set the default elements should come from. A combination pinned
# to one orientation uses that; a "both" preset follows the device, because it is
# the screen shape — not the preset's name — that decides whether the landscape
# fractions fit.
func _placement_orientation() -> String:
	var pinned := String(_active.get("orientation", "both"))
	return pinned if pinned in ["portrait", "landscape"] else _orientation


# ── Canvas rectangle ─────────────────────────────────────────────────────────


# The player's Game View choice as a viewport rect, or {} when they have not
# overridden the layout. Computed on demand and never written back into `_active`:
# mutating the combination in place meant switching back to Automatic left the
# last custom rect stranded, because the original was already gone.
func _game_view_override() -> Dictionary:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null or String(settings.game_view_preset) == "auto":
		return {}
	return SettingsManagerS.game_view_viewport(
		_placement_orientation(),
		float(settings.game_view_size),
		float(settings.game_view_offset),
		bool(settings.game_view_aspect_locked)
	)


# Called by the Settings screen on every slider tick, which is what makes the
# preview live: the canvas moves under the player's finger as they drag.
func refresh_game_view() -> void:
	canvas_rect_changed.emit(canvas_rect())


# The browser's window size in CSS pixels. Godot cannot read this itself under
# canvas_resize_policy=0: DisplayServer reports the CANVAS, and the canvas is the
# thing being sized, so asking the engine would be circular.
func set_available_pixels(pixels: Vector2) -> bool:
	var wanted := Vector2(maxf(pixels.x, 0.0), maxf(pixels.y, 0.0))
	if wanted.is_equal_approx(_available_pixels):
		return false
	_available_pixels = wanted
	canvas_rect_changed.emit(canvas_rect())
	return true


func available_pixels() -> Vector2:
	return _available_pixels


# The active combination's viewport resolved against the real window. Returns an
# empty rect until the window is known, which callers treat as "do not touch the
# canvas" rather than "make it zero-sized".
func canvas_rect() -> Rect2:
	if _available_pixels.x <= 0.0 or _available_pixels.y <= 0.0:
		return Rect2()
	var combination := _active
	var override := _game_view_override()
	if not override.is_empty():
		combination = _active.duplicate(true)
		combination.viewport = override
	var rect := ControllerLayoutS.effective_viewport(combination, _available_pixels)
	if bool(combination.get("viewport", {}).get("aspect_locked", false)):
		rect = _lock_aspect(rect)
	return rect


# Shrinks a rect to the 16:9 design aspect and re-centres it inside its old
# bounds. Shrinks rather than grows so the result always still fits the space the
# player allocated — growing would silently reclaim screen from the controller.
func _lock_aspect(rect: Rect2, ratio: float = 16.0 / 9.0) -> Rect2:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return rect
	var target := Vector2(rect.size.x, rect.size.x / ratio)
	if target.y > rect.size.y:
		target = Vector2(rect.size.y * ratio, rect.size.y)
	return Rect2(rect.position + (rect.size - target) * 0.5, target)


func canvas_rect_json() -> String:
	var rect := canvas_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return ""
	return (
		JSON
		. stringify(
			{
				"x": rect.position.x,
				"y": rect.position.y,
				"width": rect.size.x,
				"height": rect.size.y,
			}
		)
	)


# Applies one combination directly (Slice 4's editor and preview path).
func apply_combination(combination: Dictionary) -> void:
	release_all_actions()
	# Registry defaults are deliberately NOT baked in here. `build_payload_for()`
	# already resolves an empty element list against the registry, so an empty list
	# keeps its meaning of "follow the built-in placement" all the way into the
	# saved cfg — a player who never moved a control keeps getting the current
	# defaults after an update instead of a frozen copy of an older build's.
	_active = ControllerLayoutS.normalize(combination)
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
	# Cleared rather than replaced with the new profile's defaults: empty already
	# means "use the registry placement", and writing them out would freeze them.
	next.elements = []
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
	return build_payload_for(
		_active, registry, brand, _editing, _theme_colors(), _placement_orientation()
	)


static func build_payload_for(
	combination: Dictionary,
	action_registry: ControllerActionRegistry,
	brand: int,
	editing: bool,
	theme_colors: Dictionary,
	placement_orientation: String = "landscape"
) -> Dictionary:
	var normalized := ControllerLayoutS.normalize(combination)
	var active_profile := String(normalized.profile)
	var elements: Array[Dictionary] = []
	var source: Array = normalized.elements
	if source.is_empty() and action_registry != null and active_profile != PROFILE_OFF:
		source = action_registry.default_elements(active_profile, placement_orientation)

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
	_active = _chosen_for_orientation()
	layout_changed.emit(build_payload())


# The player's saved choice wins whenever the current orientation can display it;
# otherwise the orientation decides. A combination pinned to landscape genuinely
# cannot serve a portrait screen — its viewport and element fractions were authored
# for the other shape — so honouring the choice there would hand the player a
# layout that does not fit. The choice is remembered, not discarded: rotating back
# restores it.
func _chosen_for_orientation() -> Dictionary:
	if not _active_id.is_empty():
		for raw: Variant in _combinations:
			var candidate := ControllerLayoutS.normalize(raw)
			if String(candidate.id) != _active_id:
				continue
			if String(candidate.orientation) in ["both", _orientation]:
				return candidate
			break
	return ControllerLayoutS.select_for_orientation(_combinations, _orientation)


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
	_drive_gui(action, pressed)


# `Input.action_press()` sets the polled action state and NOTHING ELSE — it
# synthesizes no InputEvent, so it reaches gameplay code that polls
# `is_action_pressed()` and never reaches Godot's GUI, which moves focus and
# activates buttons from events. Measured on 2026-08-05: with a Button focused,
# `Input.action_press("cursor_down")` left focus where it was, an injected
# `InputEventAction("cursor_down")` also left it (an InputEventAction matches only
# its own action name, and the GUI asks for `ui_down`), and an injected
# `InputEventAction("ui_down")` moved it. So every on-screen control could drive
# the map and none of them could work a menu — the d-pad added for
# `labeled_actions` would have rendered and done nothing.
#
# This is not a new dual path. `_mirror_game_keys_to_ui()` already stamps every
# game key onto its `ui_*` counterpart, so a hardware Z fires `confirm` AND
# `ui_accept`; the on-screen controller was simply the one input that bypassed the
# mirror by pressing an action instead of delivering an event. Injecting the
# mirrored action makes touch behave exactly like the key it stands for.
func _drive_gui(action: String, pressed: bool) -> void:
	var ui_action := SettingsManagerS.ui_action_for(action)
	if ui_action.is_empty() or not InputMap.has_action(ui_action):
		return
	var event := InputEventAction.new()
	event.action = ui_action
	event.pressed = pressed
	Input.parse_input_event(event)


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
