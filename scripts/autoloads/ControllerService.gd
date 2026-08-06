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
# Split from `layout_changed` for the same reason as the canvas rect, and found
# the same way — in a real export. Selection is presentation only, but publishing
# it as a layout made the shell rebuild every button, which DESTROYS the node the
# finger is holding: the drag died on its own first frame, every time, while the
# stub-canvas tests passed because nothing was there to republish.
signal selection_changed(element_id: String)
# Split from `layout_changed` for the third time, and for the third time because a
# rebuild drops held controls. This one carries only the auto-hide delay.
signal auto_hide_changed(seconds: float)

const ControllerLayoutS = preload("res://scripts/resources/ControllerLayout.gd")
const ControllerActionRegistryS = preload("res://scripts/resources/ControllerActionRegistry.gd")
const ControllerPressLedgerS = preload("res://scripts/resources/ControllerPressLedger.gd")
const InputDisplay = preload("res://scripts/shared/InputDisplay.gd")
const SettingsManagerS = preload("res://scripts/autoloads/SettingsManager.gd")

const PAYLOAD_VERSION := 1
const PROFILE_OFF := "off"

# The three states of the on-screen editor. `EDIT_CONTROLS` is Slice 4's control
# arrangement editor; `EDIT_VIEWPORT` is Slice 3's Game View editor, which drags
# the canvas rectangle itself.
const EDIT_NONE := "none"
const EDIT_CONTROLS := "controls"
const EDIT_VIEWPORT := "viewport"
const VALID_EDIT_MODES: Array[String] = [EDIT_NONE, EDIT_CONTROLS, EDIT_VIEWPORT]

# Deep enough that a player can explore a few arrangements and still walk back,
# shallow enough that the stack is not a second copy of the layout history. Each
# entry is one small rect, so the cap is about intelligibility rather than memory.
const VIEWPORT_UNDO_DEPTH := 16

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
# Which editor has the screen: nothing, the controls, or the game view. One value
# rather than two booleans because the two editors cannot coexist — both need the
# shell overlay to swallow every pointer, so a screen showing both would have the
# same touch mean "drag a control" and "drag the canvas edge" at once.
var _edit_mode: String = EDIT_NONE
# Authored viewport rects the Game View editor can step back through, oldest
# first. Each entry also carries the Game View preset that was live when it was
# pushed, so undoing the very first drag restores the preset the adoption below
# cleared — otherwise Undo would return the rect but leave the player on Custom.
var _viewport_undo: Array[Dictionary] = []
# Which element the Settings sliders act on. Cleared whenever the drawn set can
# change (profile switch, orientation swap, slot change), because element ids are
# profile-specific and a stale selection would edit something invisible.
var _selected_element_id: String = ""
var _hex_regex: RegEx = null
# What was in settings the last time this service loaded or saved. Compared against
# the live settings on `settings_changed` so the service reloads on a genuine
# external edit (a Controls reset, say) but ignores the echo of its own save —
# reloading would emit `layout_changed`, and that makes the shell rebuild every
# button, dropping whatever the player is holding.
var _persisted_snapshot: String = ""

# The process frame each held action's press was applied on, and the releases
# being held back because that frame has not ended yet. See `_emit_action()`.
var _press_frames: Dictionary = {}
var _deferred_releases: Dictionary = {}

# Held for the session's lifetime: the bridge owns the JavaScriptBridge callback
# the shell calls back through, and a RefCounted that nothing references is freed
# — which silently turns every control into a dead rectangle.
var _web_bridge: ControllerWebBridge = null


func _ready() -> void:
	# ALWAYS so a paused tree still releases held actions; a stuck action that
	# survives the pause menu is exactly the bug this service exists to prevent.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# `_process` exists only to flush a held-back release, so it stays off until
	# there is one; a per-frame callback that does nothing is still a per-frame
	# callback on a phone.
	set_process(false)
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
	# Through `_settings_node()` like every other settings read here, rather than
	# resolving the autoload path directly: the direct path made the whole override
	# branch unreachable under test, which is precisely where the adoption rule that
	# depends on it lives.
	var settings := _settings_node()
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
	_selected_element_id = ""
	# Element ids are profile-specific, so the previous layout cannot carry over.
	# Cleared rather than replaced with the new profile's defaults: empty already
	# means "use the registry placement", and writing them out would freeze them.
	next.elements = []
	apply_combination(next)


func profile() -> String:
	return String(_active.get("profile", PROFILE_OFF))


# ── Editing mode ─────────────────────────────────────────────────────────────


# Entering an editor pauses gameplay and hands every pointer to it, so dragging a
# control (or a canvas edge) must not also play the game.
func set_edit_mode(mode: String) -> void:
	var wanted := mode if mode in VALID_EDIT_MODES else EDIT_NONE
	if wanted == _edit_mode:
		return
	_edit_mode = wanted
	release_all_actions()
	# Opening the Game View editor is the moment the rect on screen has to become
	# the rect being edited — see `adopt_game_view_override()`. Done here rather
	# than in the Settings screen so entering the editor by any route starts from
	# what the player can actually see.
	if wanted == EDIT_VIEWPORT:
		adopt_game_view_override()
	editing_changed.emit(is_editing())
	layout_changed.emit(build_payload())


func set_editing(editing: bool) -> void:
	set_edit_mode(EDIT_CONTROLS if editing else EDIT_NONE)


func set_viewport_editing(editing: bool) -> void:
	set_edit_mode(EDIT_VIEWPORT if editing else EDIT_NONE)


func edit_mode() -> String:
	return _edit_mode


func is_editing() -> bool:
	return _edit_mode != EDIT_NONE


# ── Game View editing ────────────────────────────────────────────────────────
#
# Slice 3. The canvas rectangle is dragged the same way a control is: the shell
# owns the gesture, because the handles are DOM outside the canvas and the engine
# never sees those touches, and it reports ONE rect when the finger lifts. Nothing
# here is applied per pointer move — under `canvas_resize_policy=0` a canvas
# resize reallocates the backing store, so a per-move apply would reallocate it
# every frame of the drag.
#
# What is stored is the ACTIVE COMBINATION's own viewport, not a separate setting.
# A saved arrangement is "where the canvas sits and where the controls sit"; the
# Game View preset rows are a coarse shortcut layered over that, and layering the
# free editor over it as well would give one rectangle two owners.


# The rect being edited, as authored fractions of the window. Not `canvas_rect()`:
# that answers in pixels and has already had the minimum-size clamp and the aspect
# lock applied, and feeding a clamped answer back in as the authored value is
# exactly the drift `effective_viewport` was written to avoid.
func viewport_fractions() -> Dictionary:
	var authored: Variant = _active.get("viewport", {})
	if authored is Dictionary:
		return (authored as Dictionary).duplicate(true)
	return ControllerLayoutS.default_viewport(String(_active.get("orientation", "both")))


# Entering the editor has to start from the rect the player can SEE. While a Game
# View preset is active that rect comes from the settings override rather than
# from the combination, so a drag would be measured against one rectangle and
# stored in another — the canvas would jump on the first pointer-down and every
# later drag would be silently overruled by the preset.
#
# This is the control editor's materialization rule wearing a second hat: the
# first edit must freeze what is on screen before it changes it. Returns true when
# an override was actually folded in, so a caller can tell an adoption from a
# no-op. Does NOT persist; the drag that follows commits.
func adopt_game_view_override() -> bool:
	var override := _game_view_override()
	if override.is_empty():
		return false
	# Pushed BEFORE the preset is cleared, so the entry records the preset the
	# player was on. Adoption changes both the rect and the preset, so it is an
	# undoable step like any other — and it is the one a player is most likely to
	# want back, having only meant to look at the editor.
	_push_viewport_undo()
	var next: Dictionary = _active.duplicate(true)
	next.viewport = override
	_active = ControllerLayoutS.normalize(next)
	_clear_game_view_override()
	canvas_rect_changed.emit(canvas_rect())
	return true


# Returns the preset row to Automatic so the combination's own viewport is what
# reaches the canvas again. Writes the setting but does not save it: `save_layout()`
# persists the whole cfg, so the commit at the end of the drag carries this too.
func _clear_game_view_override() -> void:
	var settings := _settings_node()
	if settings == null or String(settings.game_view_preset) == "auto":
		return
	settings.set("game_view_preset", "auto")


# The dragged rectangle, in fractions of the window. Applied to the canvas but
# deliberately NOT published as a layout: `layout_changed` rebuilds every control,
# and the finger that just resized the canvas is often still holding a handle.
func set_viewport_rect(x: float, y: float, width: float, height: float) -> bool:
	if not (is_finite(x) and is_finite(y) and is_finite(width) and is_finite(height)):
		return false
	# A zero or negative extent is not a small canvas, it is a lost one — and
	# normalization would clamp it up to 0.01 of the window, which is a canvas the
	# player can neither see nor find the handles of.
	if width <= 0.0 or height <= 0.0:
		return false
	_push_viewport_undo()
	_apply_viewport_fractions({"x": x, "y": y, "width": width, "height": height})
	return true


func set_viewport_aspect_locked(locked: bool) -> void:
	_push_viewport_undo()
	_apply_viewport_fractions({"aspect_locked": locked})


# Restores the built-in rect for this combination's orientation. Unlike
# `reset_elements()` this WRITES today's default rather than clearing an override:
# a viewport is a single rect whose keys are always present, so there is no empty
# state that could mean "follow the built-in placement".
func reset_viewport() -> void:
	_push_viewport_undo()
	_apply_viewport_fractions(
		ControllerLayoutS.default_viewport(String(_active.get("orientation", "both")))
	)


func can_undo_viewport() -> bool:
	return not _viewport_undo.is_empty()


func undo_viewport_edit() -> bool:
	if _viewport_undo.is_empty():
		return false
	var previous: Dictionary = _viewport_undo.pop_back()
	var next: Dictionary = _active.duplicate(true)
	next.viewport = previous.get("viewport", {})
	_active = ControllerLayoutS.normalize(next)
	# The preset travels with the rect. Undoing the drag that adopted an override
	# without also restoring the preset would leave the player on Automatic looking
	# at the rect Custom used to produce, which is neither state they were in.
	var settings := _settings_node()
	var preset := String(previous.get("preset", "auto"))
	if settings != null and String(settings.game_view_preset) != preset:
		settings.set("game_view_preset", preset)
	canvas_rect_changed.emit(canvas_rect())
	return true


# One commit path for a FINISHED viewport edit — a finger lifting off a handle, or
# Reset. Everything before that is preview, exactly as with an element drag.
func commit_viewport_edit() -> void:
	commit_active_combination()
	save_layout()


func _push_viewport_undo() -> void:
	var settings := _settings_node()
	(
		_viewport_undo
		. append(
			{
				"viewport": viewport_fractions(),
				"preset": String(settings.game_view_preset) if settings != null else "auto",
			}
		)
	)
	if _viewport_undo.size() > VIEWPORT_UNDO_DEPTH:
		_viewport_undo.remove_at(0)


func _apply_viewport_fractions(changes: Dictionary) -> void:
	var authored := viewport_fractions()
	for key: String in changes:
		authored[key] = changes[key]
	var next: Dictionary = _active.duplicate(true)
	next.viewport = authored
	_active = ControllerLayoutS.normalize(next)
	# A live preset would win over the rect just authored, so the drag would appear
	# to do nothing. Adoption on entering the editor normally clears it already;
	# this makes the outcome independent of how the editor was reached.
	_clear_game_view_override()
	canvas_rect_changed.emit(canvas_rect())


# ── Auto-hide ────────────────────────────────────────────────────────────────
#
# The DELAY is a setting; the TIMER lives in the shell, because only the browser
# sees the touches that keep the controls awake — a tap that lands on a control
# never reaches Godot as an input event, and a tap that misses one is a canvas
# event the shell observes first. The engine's whole part is telling the shell how
# long to wait.


func auto_hide_seconds() -> float:
	var settings := _settings_node()
	if settings == null:
		return 0.0
	return SettingsManagerS.normalize_controller_auto_hide(
		settings.get("controller_auto_hide_seconds")
	)


# Called by the Settings screen when the delay changes. Its own signal rather than
# a republished layout for the same reason the canvas rect and the selection have
# theirs: a layout rebuilds every control, and rebuilding them to change a timeout
# would drop whatever a second finger is holding.
func refresh_auto_hide() -> void:
	auto_hide_changed.emit(auto_hide_seconds())


# ── Element editing ──────────────────────────────────────────────────────────
#
# Slice 4 step 3. The two halves of an edit arrive from opposite directions:
# POSITION comes from the shell, because a finger drags the control itself and
# only the browser owns those pointers; SIZE and OPACITY come from Settings
# sliders, which are Godot Controls and therefore need to be told which element
# they act on. That is what the selection is for — the same tap that begins a
# drag also names the element the sliders edit.
#
# None of these write to disk. `commit_element_edit()` does, once, when an edit
# finishes; a drag can otherwise re-apply the layout as often as it likes.


func selected_element_id() -> String:
	return _selected_element_id


# "" clears the selection. An id the active profile does not draw is REFUSED
# rather than remembered: the sliders would otherwise edit a control that is not
# on screen, and the player would see nothing move.
func select_element(element_id: String) -> bool:
	var wanted := element_id.strip_edges()
	if not wanted.is_empty() and _allowed_action(wanted).is_empty():
		return false
	if wanted == _selected_element_id:
		return true
	_selected_element_id = wanted
	selection_changed.emit(_selected_element_id)
	return true


# The element list as the shell is actually drawing it, which is not the same as
# the saved list: an empty saved list means "follow the registry placement".
#
# So the first edit has to FREEZE that placement into the combination. Writing
# only the edited element instead would leave a layout carrying exactly one
# control — the whole controller gone in a single drag, with no way back to it
# except the Reset button the player can no longer reach.
func _materialized_elements() -> Array:
	var stored: Array = _active.get("elements", [])
	if not stored.is_empty():
		return stored.duplicate(true)
	if registry == null or profile() == PROFILE_OFF:
		return []
	return registry.default_elements(profile(), _placement_orientation())


func element_layout(element_id: String) -> Dictionary:
	for raw: Variant in _materialized_elements():
		if raw is Dictionary and String((raw as Dictionary).get("id", "")) == element_id:
			return (raw as Dictionary).duplicate(true)
	return {}


func move_element(element_id: String, x: float, y: float) -> bool:
	# Rejected rather than clamped: a non-finite coordinate is a broken message,
	# and `_safe_float` would quietly rewrite it to the middle of the screen —
	# so a malformed drag would teleport the control instead of doing nothing.
	if not is_finite(x) or not is_finite(y):
		return false
	return _update_element(element_id, {"x": x, "y": y})


func set_element_scale(element_id: String, scale: float) -> bool:
	if not is_finite(scale):
		return false
	return _update_element(element_id, {"scale": scale})


func set_element_opacity(element_id: String, opacity: float) -> bool:
	if not is_finite(opacity):
		return false
	return _update_element(element_id, {"opacity": opacity})


# Adds or removes an optional control. Turning one OFF is refused for a required
# descriptor — the directional cross, Confirm and Back — because those are what
# reach and work the Settings screen this row lives on, so hiding them would hide
# the way back. Turning one ON is never refused: re-showing a control cannot
# strand anybody.
#
# Note what this deliberately does NOT do: `press()` is not gated on it. Hiding a
# control is a presentation choice, and every hideable control fires an action the
# active profile already exposes, so refusing the press would buy no authorisation
# the registry allow-list does not already give — while adding a second rule that
# could drift from the one the payload filter applies, and a rule that disagreed
# would turn a visible control into a dead one.
func set_element_enabled(element_id: String, enabled: bool) -> bool:
	if not enabled and registry != null and registry.is_required(element_id):
		return false
	return _update_element(element_id, {"enabled": enabled})


# Every control the active profile can draw, in registry order, with the state the
# Settings rows need. Includes the ones currently turned OFF — that is the whole
# point: a hidden control cannot be tapped, so the only way back to it is a list
# that still names it.
func profile_elements() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if registry == null or profile() == PROFILE_OFF:
		return result
	var enabled_by_id: Dictionary = {}
	for raw: Variant in _materialized_elements():
		if raw is Dictionary:
			var element: Dictionary = raw
			enabled_by_id[String(element.get("id", ""))] = bool(element.get("enabled", true))
	for id in registry.ids_for_profile(profile()):
		var descriptor := registry.descriptor(id)
		(
			result
			. append(
				{
					"id": id,
					"label": String(descriptor.get("label", id)),
					"required": bool(descriptor.get("required", false)),
					"enabled": bool(enabled_by_id.get(id, true)),
				}
			)
		)
	return result


# Drops every element override so the combination follows the registry placement
# again. Deliberately CLEARS rather than rewriting today's defaults into the
# slot: empty is what lets a later build move a control the player never touched.
func reset_elements() -> void:
	_selected_element_id = ""
	var next: Dictionary = _active.duplicate(true)
	next.elements = []
	_active = ControllerLayoutS.normalize(next)
	selection_changed.emit(_selected_element_id)
	layout_changed.emit(build_payload())


# One commit path for an edit that is FINISHED — a finger lifting off a dragged
# control, or a slider settling. Everything before that is preview.
func commit_element_edit() -> void:
	commit_active_combination()
	save_layout()


func _update_element(element_id: String, changes: Dictionary) -> bool:
	if _allowed_action(element_id).is_empty():
		return false
	var elements := _materialized_elements()
	var edited := false
	for index in elements.size():
		var element: Dictionary = elements[index]
		if String(element.get("id", "")) != element_id:
			continue
		for key: String in changes:
			element[key] = changes[key]
		elements[index] = element
		edited = true
		break
	if not edited:
		return false
	var next: Dictionary = _active.duplicate(true)
	next.elements = elements
	# Deliberately NOT `apply_combination()`: that releases every held action,
	# and an edit is not a lifecycle event. Normalization does the clamping, so
	# an out-of-range slider or a hostile drag lands in bounds either way.
	_active = ControllerLayoutS.normalize(next)
	layout_changed.emit(build_payload())
	return true


# ── Press / release ──────────────────────────────────────────────────────────


# Reports a pointer going down on `element_id`. Returns true when the event was
# accepted (registered element, present in the active profile, not editing).
func press(pointer_id: String, element_id: String) -> bool:
	if _ledger == null or is_editing() or profile() == PROFILE_OFF:
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
#
# Unlike a finger lifting, none of these may be held back a frame: a release that
# is still pending when the tab blurs or the scene changes is exactly the stuck
# action this service exists to prevent. Anything already deferred is flushed
# here for the same reason — the ledger no longer knows about it, so this is the
# last chance to let it go.
func release_all_actions() -> Array[String]:
	if _ledger == null:
		return []
	var released := _flush_deferred_releases(true)
	for action in _ledger.release_all():
		released.append(action)
		_apply_action(action, false)
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
		_active,
		registry,
		brand,
		is_editing(),
		_theme_colors(),
		_placement_orientation(),
		_selected_element_id,
		auto_hide_seconds(),
		_edit_mode
	)


static func build_payload_for(
	combination: Dictionary,
	action_registry: ControllerActionRegistry,
	brand: int,
	editing: bool,
	theme_colors: Dictionary,
	placement_orientation: String = "landscape",
	selected: String = "",
	auto_hide: float = 0.0,
	edit_mode: String = EDIT_NONE
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
		# A control the player turned off is simply not drawn — REQUIRED ones
		# excepted. The registry, not the saved layout, has the last word here:
		# `set_element_enabled()` already refuses to turn a required control off,
		# but a hand-edited or corrupted cfg answers to no UI, and a save that hid
		# Back or the d-pad would leave a phone that cannot open the menu holding
		# the row that would undo it.
		if not bool(element.get("enabled", true)) and not bool(descriptor.get("required", false)):
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
		# The smallest canvas the editor may drag to, in WINDOW pixels — the same
		# space the shell's `metrics` message reports, so it can clamp the gesture
		# in its own units. Published rather than duplicated in the shell because
		# the engine clamps to it too (`effective_viewport`), and a shell that
		# disagreed would let a player drag to a size that visibly snapped back.
		"min_viewport":
		{
			"width": ControllerLayoutS.MIN_VIEWPORT_PIXELS.x,
			"height": ControllerLayoutS.MIN_VIEWPORT_PIXELS.y,
		},
		"editing": editing,
		# Which editor is open, so the shell knows whether a pointer drags a
		# control or a canvas handle. `editing` stays a plain bool beside it: it
		# answers "are pointers mine?", which is the question the renderer asks on
		# every touch, and every existing consumer already reads it.
		"edit_mode": edit_mode if edit_mode in VALID_EDIT_MODES else EDIT_NONE,
		# Seconds of no touching before the shell fades the controls out; 0 never
		# hides. Service state rather than a combination field, like `editing` and
		# `colors` above it — see SettingsManager.controller_auto_hide_seconds.
		"auto_hide_seconds": maxf(auto_hide, 0.0) if is_finite(auto_hide) else 0.0,
		# Only ever an element the shell is actually drawing. Publishing a
		# selection the payload does not contain would leave the highlight on a
		# control that is no longer there.
		"selected": selected if seen.has(selected) else "",
		"elements": elements,
	}


func payload_json() -> String:
	return JSON.stringify(build_payload())


# ── Internals ────────────────────────────────────────────────────────────────


func _select_active() -> void:
	release_all_actions()
	_selected_element_id = ""
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


# A press is applied at once; a release may be held back one frame. See
# `_apply_action()` for what "applied" means and `_process()` for the hold.
func _emit_action(action: String, pressed: bool) -> void:
	if not InputMap.has_action(action):
		# A descriptor can name an action a campaign build does not define; drop
		# it rather than crashing the input path.
		return
	if pressed:
		# A new press cancels any release still waiting on the previous one,
		# otherwise the flush below would let go of an action that is held again.
		_deferred_releases.erase(action)
		_press_frames[action] = Engine.get_process_frames()
		_apply_action(action, true)
		return
	# A press and its release inside ONE frame are invisible to every consumer
	# that polls `is_action_pressed()` rather than handling events — the map
	# cursor, and the directional repeat policy every modal menu navigates by.
	# The state goes up and back down between two polls, so the tap does nothing
	# at all. A finger cannot do that, but a browser can: the shell's pointerdown
	# and pointerup arrive as JavaScript callbacks, and a synthesized tap (or a
	# real one across a dropped frame) delivers both before the engine next runs.
	# Holding the release to the next frame guarantees exactly one poll sees it,
	# which is the shortest press a finger could have produced anyway.
	if int(_press_frames.get(action, -1)) >= Engine.get_process_frames():
		_deferred_releases[action] = true
		set_process(true)
		return
	_apply_action(action, false)


func _process(_delta: float) -> void:
	_flush_deferred_releases(false)


# Lets go of every release whose press has now been visible for a whole frame.
# `force` skips that wait for the lifecycle paths, which must never leave one
# pending. Returns the actions actually released.
func _flush_deferred_releases(force: bool) -> Array[String]:
	var released: Array[String] = []
	var frame := Engine.get_process_frames()
	for action: String in _deferred_releases.keys():
		if not force and int(_press_frames.get(action, -1)) >= frame:
			continue
		_deferred_releases.erase(action)
		released.append(action)
		_apply_action(action, false)
	if _deferred_releases.is_empty():
		set_process(false)
	return released


# One press or release, delivered every way an input can be observed: the polled
# action state, this service's own signals, and real InputEvents.
func _apply_action(action: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
		action_pressed.emit(action)
	else:
		# Erased here rather than at each call site so the lifecycle paths, which
		# release straight through this method, cannot leave a stale frame number
		# behind for an action that is no longer down.
		_press_frames.erase(action)
		Input.action_release(action)
		action_released.emit(action)
	_deliver_events(action, pressed)


# `Input.action_press()` sets the polled action state and NOTHING ELSE — it
# synthesizes no InputEvent, so it reaches code that polls `is_action_pressed()`
# and no handler that reads events. Both halves of the game are event handlers:
# Godot's GUI moves focus and activates buttons from events, and every screen in
# `scripts/ui/` reads its own vocabulary (`cancel`, `confirm`, `open_menu`,
# `inspect_unit`, …) out of `_input` / `_unhandled_input`. So the controller drove
# the map and reached neither.
#
# Two events go out, because no single one can stand in for a key press. An
# `InputEventAction` matches ONLY its own action name (measured 2026-08-05: with a
# Button focused, an injected `InputEventAction("cursor_down")` did not move focus
# and an injected `InputEventAction("ui_down")` did), while a hardware key matches
# every action it is bound to at once — `_mirror_game_keys_to_ui()` stamps each
# game key onto its `ui_*` counterpart, so one press of Z is `confirm` AND
# `ui_accept`. Reproducing that takes one event per action name.
#
# The `ui_*` event goes FIRST so the GUI still gets first refusal, exactly as it
# would with a key: a focused button acts on `ui_accept`, and the screen-level
# `confirm` handler that follows finds itself already closed and does nothing.
# Reversing the order would let the screen act before the button it was showing.
func _deliver_events(action: String, pressed: bool) -> void:
	var ui_action := SettingsManagerS.ui_action_for(action)
	if not ui_action.is_empty() and InputMap.has_action(ui_action):
		_inject_action_event(ui_action, pressed)
	_inject_action_event(action, pressed)


func _inject_action_event(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
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
