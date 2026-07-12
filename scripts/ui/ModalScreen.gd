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

# Generic close signal — emitted by the default _close(). Subclasses that
# already publish their own signal (back_pressed, etc.) keep emitting it in
# addition; nothing's listening to this generic one yet, but it's the contract
# for any new modal that doesn't need a custom signal name.
signal closed()

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
	if imm != null and imm.has_signal("input_mode_changed") \
			and not imm.is_connected("input_mode_changed", _on_input_mode_changed):
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


# Depth-first search for the first visible, focusable Control under root_node.
func _first_focusable(root_node: Node) -> Control:
	if root_node == null:
		return null
	for child in root_node.get_children():
		if child is Control:
			var c := child as Control
			if c.visible and c.focus_mode != Control.FOCUS_NONE and not _is_focus_disabled(c):
				return c
		var nested := _first_focusable(child)
		if nested != null:
			return nested
	return null


func _input(event: InputEvent) -> void:
	if not visible or not _modal_focus_repeat_enabled() or _capture_ui_active():
		return
	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
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


func _focusable_controls(root_node: Node) -> Array[Control]:
	var out: Array[Control] = []
	_collect_focusable_controls(root_node, out)
	return out


func _collect_focusable_controls(root_node: Node, out: Array[Control]) -> void:
	if root_node == null:
		return
	for child in root_node.get_children():
		if child is Control:
			var c := child as Control
			if c.is_visible_in_tree() and c.focus_mode != Control.FOCUS_NONE \
					and not _is_focus_disabled(c):
				out.append(c)
		_collect_focusable_controls(child, out)


func _is_focus_disabled(control: Control) -> bool:
	return control is BaseButton and (control as BaseButton).disabled


func apply_menu_scale(factor: float) -> void:
	MenuScale.apply_to(_menu_scale_target(), factor, true)


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
