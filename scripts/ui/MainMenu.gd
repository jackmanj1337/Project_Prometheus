extends Control
# Main menu: Continue resumes a suspend save, New Game opens the NewGameScreen
# overlay, Settings opens the SettingsScreen overlay, and Quit exits.

@onready var _continue_btn: Button = $Panel/VBox/ContinueButton
@onready var _new_game_btn: Button = $Panel/VBox/NewGameButton
@onready var _settings_btn: Button = $Panel/VBox/SettingsButton
@onready var _quit_btn: Button = $Panel/VBox/QuitButton
@onready var _new_game_screen: Control = $NewGameScreen
@onready var _settings_screen: Control = $SettingsScreen

const MenuScale = preload("res://scripts/ui/MenuScale.gd")


func _ready() -> void:
	add_to_group(MenuScale.GROUP)
	_continue_btn.pressed.connect(_on_continue)
	_new_game_btn.pressed.connect(_on_new_game)
	_settings_btn.pressed.connect(_on_settings)
	_quit_btn.pressed.connect(_on_quit)
	_new_game_screen.back_pressed.connect(_on_new_game_back)
	_settings_screen.back_pressed.connect(_on_settings_back)
	_apply_menu_scale_from_settings()
	_refresh_continue_state()
	if not _continue_btn.disabled:
		_continue_btn.grab_focus()
	else:
		_new_game_btn.grab_focus()


func apply_menu_scale(factor: float) -> void:
	MenuScale.apply_to($Panel, factor, true)


func _apply_menu_scale_from_settings() -> void:
	apply_menu_scale(MenuScale.factor_from_settings(self))


func _refresh_continue_state() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	_continue_btn.disabled = save_manager == null \
		or not save_manager.has_method("has_continue_save") \
		or not bool(save_manager.call("has_continue_save"))


func _on_continue() -> void:
	if _load_continue_save():
		get_tree().change_scene_to_file("res://scenes/core/GameMap.tscn")


func _load_continue_save() -> bool:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null or not save_manager.has_method("load_suspend"):
		_show_continue_error("Continue is unavailable.\nNo save service was found.")
		_refresh_continue_state()
		return false
	var save: Variant = save_manager.call("load_suspend")
	if save == null:
		_show_continue_error("Could not load the suspend save.\nMap progress was not resumed.")
		_refresh_continue_state()
		return false
	var gs := get_node_or_null("/root/GameState")
	if gs == null or not gs.has_method("configure_suspend_resume"):
		_show_continue_error("Continue is unavailable.\nGame state could not be prepared.")
		_refresh_continue_state()
		return false
	if not bool(gs.call("configure_suspend_resume", save)):
		_show_continue_error("Could not resume the suspend save.\nMap progress was not resumed.")
		_refresh_continue_state()
		return false
	return true


func _show_continue_error(message: String) -> void:
	var dlg := AcceptDialog.new()
	dlg.dialog_text = message
	dlg.confirmed.connect(func(): dlg.queue_free())
	add_child(dlg)
	dlg.popup_centered()
	dlg.get_ok_button().grab_focus()


func _on_new_game() -> void:
	# NewGameScreen handles roster load + scene change once the player hits Start.
	_new_game_screen.open()


func _on_new_game_back() -> void:
	_refresh_continue_state()
	_new_game_btn.grab_focus()


func _on_settings() -> void:
	_settings_screen.open()


func _on_settings_back() -> void:
	_refresh_continue_state()
	_settings_btn.grab_focus()


# The open_settings keybinding opens the settings screen from the main menu.
# Ignored while either overlay is already showing — those handle their own input.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_settings") \
			and not _settings_screen.visible and not _new_game_screen.visible:
		_on_settings()
		get_viewport().set_input_as_handled()


func _on_quit() -> void:
	get_tree().quit()
