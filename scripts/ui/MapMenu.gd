extends Control
# Pause-style map menu: End Turn, Settings, Close.
# Opens on open_menu action; closes on cancel or after a selection.

signal end_turn_requested()
signal settings_requested()
signal suspend_and_quit_requested()
signal quit_to_menu_requested()
signal menu_closed()

const MenuScale = preload("res://scripts/ui/MenuScale.gd")

@onready var _panel: PanelContainer = $Panel
@onready var _end_turn_btn: Button = $Panel/VBox/EndTurnButton
@onready var _settings_btn: Button = $Panel/VBox/SettingsButton
@onready var _suspend_and_quit_btn: Button = $Panel/VBox/SuspendAndQuitButton
@onready var _quit_to_menu_btn: Button = $Panel/VBox/QuitToMenuButton
@onready var _close_btn: Button = $Panel/VBox/CloseButton
@onready var _gold_label: Label = $Panel/VBox/GoldLabel

var _suspend_available: bool = true


func _ready() -> void:
	add_to_group(MenuScale.GROUP)
	hide()
	_end_turn_btn.pressed.connect(_on_end_turn)
	_settings_btn.pressed.connect(_on_settings)
	_suspend_and_quit_btn.pressed.connect(_on_suspend_and_quit)
	_quit_to_menu_btn.pressed.connect(_on_quit_to_menu)
	_close_btn.pressed.connect(_on_close)
	# V021-13: a click on the backdrop (this full-rect Control, outside the centered
	# Panel) dismisses the menu — common modal behaviour. The Panel + its buttons are
	# STOP children on top, so they consume their own clicks; only outside clicks
	# reach this gui_input.
	gui_input.connect(_on_backdrop_input)
	_apply_menu_scale_from_settings()


func _on_backdrop_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_on_close()
		accept_event()


func open() -> void:
	_apply_menu_scale_from_settings()
	_refresh_resource_summary()
	_suspend_and_quit_btn.disabled = not _suspend_available
	show()
	_end_turn_btn.grab_focus()


func _refresh_resource_summary() -> void:
	var gs := get_node_or_null("/root/GameState")
	_gold_label.text = format_party_gold(int(gs.party_gold) if gs != null else 0)


static func format_party_gold(value: int) -> String:
	return "Total gold: %d" % value


func set_suspend_available(available: bool) -> void:
	_suspend_available = available
	if is_node_ready():
		_suspend_and_quit_btn.disabled = not available


func apply_menu_scale(factor: float) -> void:
	MenuScale.apply_to(_panel, factor, true)


func _apply_menu_scale_from_settings() -> void:
	apply_menu_scale(MenuScale.factor_from_settings(self))


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("cancel") or event.is_action_pressed("open_menu"):
		_on_close()
		get_viewport().set_input_as_handled()


func _on_end_turn() -> void:
	hide()
	end_turn_requested.emit()
	menu_closed.emit()


# Hides the menu and asks for the settings overlay. Deliberately does NOT emit
# menu_closed — that would unlock the cursor while Settings is still open.
func _on_settings() -> void:
	hide()
	settings_requested.emit()


func _on_suspend_and_quit() -> void:
	if _suspend_and_quit_btn.disabled:
		return
	hide()
	suspend_and_quit_requested.emit()


func _on_quit_to_menu() -> void:
	hide()
	quit_to_menu_requested.emit()


func _on_close() -> void:
	hide()
	menu_closed.emit()
