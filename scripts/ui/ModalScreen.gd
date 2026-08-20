extends Control
# Shared base for full-screen modal overlays (B3 / 05-19 review §4). The three
# Dimmer-having screens — SettingsScreen, NewGameScreen, UnitDetailsScreen —
# each hand-rolled the "hide on ready + cancel-to-close + emit-and-hide" wiring;
# this base owns those bits so a future modal can't ship them inconsistently.
#
# Subclasses extend via `extends "res://scripts/ui/ModalScreen.gd"` (no
# class_name — keeps headless --script tests free of any class-cache entry; the
# project's MEMORY note flags class_name as a regular gotcha there).
#
# The Dimmer + Panel scene structure is owned by each .tscn — the base doesn't
# enforce a specific shape, just the shared behaviour. Subclasses override
# _close() to emit their per-screen signal and do any teardown before the hide.
# Cursor lock / input-suppression is handled by callers via EventBus signals
# (e.g. MapCursor's _input_suppressed flag listens for unit_details.closed) —
# the base intentionally stays out of that mechanism.

const MenuScale = preload("res://scripts/ui/MenuScale.gd")
const ModalMenuRepeatPolicy = preload("res://scripts/shared/MenuRepeatPolicy.gd")
const _SAFE_VIEWPORT_RATIO := 0.9
const _PREFERRED_SIZE_META := "_responsive_preferred_size"

# Generic close signal — emitted by the default _close(). Subclasses that
# already publish their own signal (back_pressed, etc.) keep emitting it in
# addition; nothing's listening to this generic one yet, but it's the contract
# for any new modal that doesn't need a custom signal name.
signal closed

var _modal_repeat := ModalMenuRepeatPolicy.new("", "", "ui_up", "ui_down")

# V031-GP-02: true while a capture-mode UI (an OptionButton dropdown or any other
# embedded popup Window) was active on the previous poll frame. Tracked so the
# frame the popup closes can re-latch the repeat policy to neutral instead of
# instantly stepping from a direction still held from inside the popup.
var _capture_ui_was_active: bool = false


func _ready() -> void:
	add_to_group(MenuScale.GROUP)
	_apply_menu_scale_from_settings()
	_connect_input_mode_changed()
	hide()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		_modal_repeat.clear()


# B6-INPUT focus seam: every modal subscribes to InputModeManager.input_mode_changed
# so a live input-scheme switch keeps focus coherent. Switching TO gamepad while the
# modal is open grabs a sensible default focus (the d-pad needs a focus anchor to move
# from). Switching TO touch drops the stale focus highlight (a lingering ring with no
# pointer/stick looks broken). Switching TO mouse_keyboard is deliberately left alone:
# that mode lumps mouse AND keyboard together, and a keyboard user still wants the
# highlight — yanking it would regress keyboard nav. Guarded so the base stays inert
# when the autoload is absent (headless scenes without it).
func _connect_input_mode_changed() -> void:
	var imm := get_node_or_null("/root/InputModeManager")
	if (
		imm != null
		and imm.has_signal("input_mode_changed")
		and not imm.is_connected("input_mode_changed", _on_input_mode_changed)
	):
		imm.connect("input_mode_changed", _on_input_mode_changed)


func _on_input_mode_changed(mode: String) -> void:
	# Only the visible modal reacts; hidden ones ignore the switch (many share this base).
	if not visible:
		return
	match mode:
		"gamepad":
			_grab_default_focus()
		"touch":
			_release_stale_focus()
	# Prompt/glyph swapping (B6-INPUT): runs for EVERY mode so a modal showing a
	# "press F / press X" hint re-renders it for the new scheme. Default is a no-op.
	_refresh_input_prompts(mode)


# Virtual: re-render any on-screen input prompts (key labels / pad glyphs) for `mode`.
# Overridden by modals that print a control hint; the base has none.
func _refresh_input_prompts(_mode: String) -> void:
	pass


# Virtual: the control that should receive focus when a gamepad becomes active while
# this modal is open. Default is the first focusable control under Panel; subclasses
# with a preferred entry point (e.g. a Back button) override this.
func _focus_default() -> Control:
	return _first_focusable(_menu_scale_target())


func _grab_default_focus() -> void:
	var target := _focus_default()
	if target != null and target.is_visible_in_tree():
		target.grab_focus()


# Drops focus only when the focused control belongs to THIS modal, so a mode switch
# never yanks focus away from an unrelated surface.
func _release_stale_focus() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var focused := vp.gui_get_focus_owner()
	if focused != null and is_ancestor_of(focused):
		focused.release_focus()


# Depth-first search for the ENTRY focus under root_node. Distinct from focus
# TRAVERSAL (_collect_focusable_controls): a disabled entry belongs in the focus order
# per [EPUX-07]/[RPD-15], but it is a poor place to *land* when the modal opens or a
# gamepad is plugged in — the player's first control would do nothing. So an available
# entry is preferred, and a disabled one is taken only when nothing else can be focused
# (a fully-gated panel must still be reachable, or its reasons are unreadable).
# MainMenu and MapMenu already encode this same preference by hand.
func _first_focusable(root_node: Node) -> Control:
	var candidates := _entry_focus_candidates(root_node)
	for c in candidates:
		if not _is_focus_disabled(c):
			return c
	return candidates[0] if not candidates.is_empty() else null


# Depth-first list of visible, focusable Controls under root_node, disabled included.
func _entry_focus_candidates(root_node: Node) -> Array[Control]:
	var out: Array[Control] = []
	if root_node == null:
		return out
	for child in root_node.get_children():
		if child is Control:
			var c := child as Control
			if c.visible and c.focus_mode != Control.FOCUS_NONE:
				out.append(c)
				continue
		out.append_array(_entry_focus_candidates(child))
	return out


func _input(event: InputEvent) -> void:
	if _text_entry_owner_active():
		return
	if not visible or not _modal_focus_repeat_enabled() or _capture_ui_active():
		return
	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _text_entry_owner_active():
		_modal_repeat.clear()
		return
	if not visible or not _modal_focus_repeat_enabled():
		return
	# V031-GP-02 standdown: the repeat policy polls the process-global Input
	# singleton, which cannot see that an open popup is capturing the event
	# stream — without this gate every press inside a dropdown also stepped the
	# panel's focus behind it (v0.3.1 live return). Containment is skipped too,
	# so it never fights the popup for focus.
	if _capture_ui_active():
		_capture_ui_was_active = true
		return
	if _capture_ui_was_active:
		_capture_ui_was_active = false
		# clear()'s wait-for-neutral latch swallows a direction still held from
		# inside the popup, so closing it never causes a surprise focus step.
		_modal_repeat.clear()
		return
	_enforce_focus_containment()
	var step := _modal_repeat.poll(delta)
	if step.y < 0:
		_move_modal_focus(-1)
	elif step.y > 0:
		_move_modal_focus(1)


func _text_entry_owner_active() -> bool:
	var service := get_node_or_null("/root/TextEntryService")
	return service != null and service.get("session") != null and service.session.active


# True while any embedded popup Window (OptionButton dropdown, context menu, …)
# is visible in this modal's viewport. The game runs single-window with embedded
# subwindows, so an open popup always registers here.
func _capture_ui_active() -> bool:
	var vp := get_viewport()
	if vp == null:
		return false
	for w in vp.get_embedded_subwindows():
		if w.visible:
			return true
	return false


# Virtual: custom-selector modals can opt out if they own directional polling.
func _modal_focus_repeat_enabled() -> bool:
	return true


func _enforce_focus_containment() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var focused := vp.gui_get_focus_owner()
	if focused != null and not is_ancestor_of(focused):
		_grab_default_focus()


func _move_modal_focus(delta: int) -> void:
	var focusables := _focusable_controls(_menu_scale_target())
	if focusables.is_empty():
		return
	var focused := get_viewport().gui_get_focus_owner()
	var idx := focusables.find(focused)
	if idx == -1:
		var default_focus := _focus_default()
		idx = focusables.find(default_focus)
		if idx == -1:
			idx = 0
	else:
		idx = wrapi(idx + delta, 0, focusables.size())
	focusables[idx].grab_focus()
	_apply_focus_lookahead(focusables[idx], delta)


# Virtual: the ScrollContainer that should keep lookahead context around the
# focused row (V031-GP-01), or null when the modal doesn't scroll. Subclasses
# with a scrolling focus list (SettingsScreen) override this.
func _focus_scroll_container() -> ScrollContainer:
	return null


# Deferred lookahead requests are coalesced: held input may move focus again before
# the layout frame settles, and only the newest focus owner may adjust the scroll.
var _focus_lookahead_generation: int = 0


# V031-GP-01: `ScrollContainer.follow_focus` scrolls a focused row just barely
# into view, so the tester couldn't see what the next step moves toward. After
# a focus step, keep up to three row heights of context visible. The margin is
# capped below half the viewport so small/high-scale layouts cannot overflow.
func _apply_focus_lookahead(ctrl: Control, direction: int = 0) -> void:
	var scroll := _focus_scroll_container()
	if (
		scroll == null
		or ctrl == null
		or not ctrl.is_inside_tree()
		or not scroll.is_ancestor_of(ctrl)
	):
		return
	_focus_lookahead_generation += 1
	var generation := _focus_lookahead_generation
	# Container geometry settles after focus changes. Reading global rectangles in
	# the same frame caused corrections based on the previous scroll position.
	await get_tree().process_frame
	if not is_instance_valid(scroll) or not is_instance_valid(ctrl):
		return
	if generation != _focus_lookahead_generation or get_viewport().gui_get_focus_owner() != ctrl:
		return
	var row := _visual_scroll_row(scroll, ctrl)
	var view := scroll.get_global_rect()
	var rect := row.get_global_rect()
	var desired := _visual_rows_height(row, 3, direction if direction != 0 else 1)
	var viewport_cap: float = maxf(0.0, (view.size.y - rect.size.y) * 0.5)
	var lookahead: float = minf(desired, viewport_cap)
	# Convert the row to content coordinates and assign one absolute target. This
	# avoids accumulated corrections and makes the margin follow travel direction.
	var content_top: float = float(scroll.scroll_vertical) + rect.position.y - view.position.y
	var current := float(scroll.scroll_vertical)
	var target := current
	# Preserve the current scroll while the requested context is already visible.
	# This makes lookahead a bounded reveal, not a recenter on every focus step.
	if direction < 0 and content_top - lookahead < current:
		target = content_top - lookahead
	elif direction > 0 and content_top + rect.size.y + lookahead > current + view.size.y:
		target = content_top + rect.size.y + lookahead - view.size.y
	elif rect.position.y < view.position.y:
		target = content_top
	elif rect.end.y > view.end.y:
		target = content_top + rect.size.y - view.size.y
	var bar := scroll.get_v_scroll_bar()
	var maximum := maxf(0.0, bar.max_value - bar.page) if bar != null else target
	scroll.scroll_vertical = roundi(clampf(target, 0.0, maximum))


# Resolve a leaf focus target (for example an HSlider) to the row directly
# owned by the scrolling content container.
func _visual_scroll_row(scroll: ScrollContainer, ctrl: Control) -> Control:
	var row := ctrl
	while row.get_parent() is Control:
		# Settings has ScrollContainer -> MarginContainer -> VBoxContainer -> rows.
		# Stopping only at a direct child of ScrollContainer returned the entire VBox,
		# so its document-height rectangle sent every correction to an endpoint.
		if row.get_parent() is VBoxContainer:
			break
		row = row.get_parent() as Control
	return row


func _visual_rows_height(row: Control, count: int, direction: int) -> float:
	var parent := row.get_parent()
	if parent == null:
		return 0.0
	var siblings := parent.get_children()
	var index := siblings.find(row)
	var height := 0.0
	var found := 0
	var stop := siblings.size() if direction > 0 else -1
	for i in range(index + direction, stop, direction):
		var sibling := siblings[i]
		if sibling is Control and sibling.is_visible_in_tree():
			height += (sibling as Control).get_global_rect().size.y
			found += 1
			if found == count:
				break
	return height


func _focusable_controls(root_node: Node) -> Array[Control]:
	var out: Array[Control] = []
	_collect_focusable_controls(root_node, out)
	return out


# Focus TRAVERSAL order. Disabled entries are INCLUDED: [EPUX-07] (2026-07-26, restated
# as [RPD-15] and promoted to all five availability surfaces) ruled that a disabled entry
# remains in the focus order so its unmet reason is reachable by keyboard and controller
# rather than by pointer hover only — the "inaccessible and opaque" failure the ruling
# rejects by name. This shipped implemented backwards: the filter here excluded exactly
# the entries the ruling requires, shell-wide.
#
# No inert treatment is needed alongside it. Measured on Godot 4.6.3: a disabled
# BaseButton still accepts grab_focus(), keeps its focus when `disabled` flips true, and
# emits no `pressed` for ui_accept — i.e. focusable-but-not-activatable is already the
# engine's native behaviour, and find_next_valid_focus() likewise steps *through*
# disabled buttons. Only this project's own traversal disagreed with it.
func _collect_focusable_controls(root_node: Node, out: Array[Control]) -> void:
	if root_node == null:
		return
	for child in root_node.get_children():
		if child is Control:
			var c := child as Control
			if c.is_visible_in_tree() and c.focus_mode != Control.FOCUS_NONE:
				out.append(c)
		_collect_focusable_controls(child, out)


# Kept as the shared availability predicate — no longer a focus filter, only the
# entry-focus preference in _first_focusable reads it.
func _is_focus_disabled(control: Control) -> bool:
	return control is BaseButton and (control as BaseButton).disabled


func apply_menu_scale(factor: float) -> void:
	var target := _menu_scale_target()
	_apply_responsive_frame(target)
	MenuScale.apply_to(target, factor)


# Centered modal frames occupy at most 90% of the safe viewport, and no more than they
# need. Their authored size remains the preference on roomy displays; existing
# ScrollContainers take overflow before MenuScale is allowed to reduce type below the
# selected setting.
func _apply_responsive_frame(target: Control) -> void:
	if target == null:
		return
	# Capture the authored preference exactly once, BEFORE this method rewrites the
	# anchors and offsets it is derived from. A scene can express its intended size
	# two ways: a custom_minimum_size, or an anchor span plus offsets (how
	# LoadGameScreen's 480x360 and CampaignLibraryScreen's 500x340 are authored).
	# Reading only the former treated both as "no preference".
	if not target.has_meta(_PREFERRED_SIZE_META):
		var authored := target.custom_minimum_size
		if authored.x <= 0.0:
			authored.x = _authored_extent(
				target.anchor_right - target.anchor_left,
				target.offset_right - target.offset_left,
				get_viewport_rect().size.x
			)
		if authored.y <= 0.0:
			authored.y = _authored_extent(
				target.anchor_bottom - target.anchor_top,
				target.offset_bottom - target.offset_top,
				get_viewport_rect().size.y
			)
		target.set_meta(_PREFERRED_SIZE_META, authored)
	var viewport_size := get_viewport_rect().size
	var safe := Vector4i.ZERO
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null and settings.has_method("get_safe_area_insets"):
		safe = settings.call("get_safe_area_insets")
	var safe_size := Vector2(
		maxf(viewport_size.x - safe.x - safe.z, 0.0), maxf(viewport_size.y - safe.y - safe.w, 0.0)
	)
	var cap := safe_size * _SAFE_VIEWPORT_RATIO
	var preferred: Vector2 = target.get_meta(_PREFERRED_SIZE_META)
	# A panel authored WITHOUT a custom_minimum_size is grow-to-content, not
	# fill-the-screen: its content minimum is the preference, capped. Using the cap
	# itself as the fallback pinned every such panel to exactly 90% x 90% of the safe
	# viewport, because the offsets below fix the rect to `desired` — a 480x360 Load
	# Game dialog rendered at 1152x648 on a 720p display. The album's containment rule
	# could not see it: an over-large frame is still inside the viewport.
	# A panel with no authored size at all falls back to its content — unless it is
	# built around a ScrollContainer, which has no intrinsic size and collapses to
	# nothing. NewGameScreen (an outer scroll region, no authored size) measured 458x32
	# under a content fallback. A scroll frame is meant to be given room, so it takes
	# the cap; MenuScale._panel_size draws the same distinction for the same reason.
	var content := target.get_combined_minimum_size()
	var fallback := cap if _contains_scroll_container(target) else content
	var desired := Vector2(
		minf(preferred.x if preferred.x > 0.0 else fallback.x, cap.x),
		minf(preferred.y if preferred.y > 0.0 else fallback.y, cap.y)
	)
	# Only an authored preference is re-asserted as a minimum. Leaving a grow-to-content
	# panel's minimum at zero lets its container keep sizing it as content changes,
	# instead of freezing whatever the first measurement happened to be.
	target.custom_minimum_size = Vector2(
		desired.x if preferred.x > 0.0 else 0.0, desired.y if preferred.y > 0.0 else 0.0
	)
	# Normalize legacy top-left-authored panels (CampaignLibraryScreen) onto the
	# same declarative center anchor used by newer modal scenes.
	target.set_anchors_preset(Control.PRESET_CENTER)
	var safe_center := Vector2(safe.x, safe.y) + safe_size * 0.5
	var delta := safe_center - viewport_size * 0.5
	target.offset_left = -desired.x * 0.5 + delta.x
	target.offset_top = -desired.y * 0.5 + delta.y
	target.offset_right = desired.x * 0.5 + delta.x
	target.offset_bottom = desired.y * 0.5 + delta.y


# One axis of a scene-authored size: the anchor span across the viewport plus the
# offset span. Computed from the anchors rather than read off target.size so it is
# correct on the first call, before any layout pass has run.
static func _authored_extent(
	anchor_span: float, offset_span: float, viewport_extent: float
) -> float:
	return maxf(anchor_span * viewport_extent + offset_span, 0.0)


# True when the frame is built around a ScrollContainer, i.e. it scrolls rather than
# growing, so its content minimum says nothing about how big it should be.
static func _contains_scroll_container(node: Node) -> bool:
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is ScrollContainer:
			return true
		for child in current.get_children():
			stack.push_back(child)
	return false


func _apply_menu_scale_from_settings() -> void:
	apply_menu_scale(MenuScale.factor_from_settings(self))


func _menu_scale_target() -> Control:
	return get_node_or_null("Panel") as Control


# Closes on the "cancel" input action. Subclasses can override entirely if they
# need more than cancel-to-close (e.g. SettingsScreen does no extra work; the
# default fits). visible-guard prevents handling input while the modal is hidden.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		_close()


# Default close: emit the generic signal and hide. Subclasses override to also
# emit their per-screen signal (back_pressed / closed-with-args / etc.) and do
# any teardown before calling super() or hide() themselves.
func _close() -> void:
	_modal_repeat.clear()
	closed.emit()
	hide()
