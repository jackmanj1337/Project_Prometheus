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

# Generic close signal — emitted by the default _close(). Subclasses that
# already publish their own signal (back_pressed, etc.) keep emitting it in
# addition; nothing's listening to this generic one yet, but it's the contract
# for any new modal that doesn't need a custom signal name.
signal closed()


func _ready() -> void:
	add_to_group(MenuScale.GROUP)
	_apply_menu_scale_from_settings()
	hide()


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
	closed.emit()
	hide()
