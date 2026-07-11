extends Control
# Main menu: Continue resumes a suspend save, New Game opens the NewGameScreen
# overlay, Settings opens the SettingsScreen overlay, and Quit exits.

@onready var _continue_btn: Button = $Panel/VBox/ContinueButton
@onready var _new_game_btn: Button = $Panel/VBox/NewGameButton
@onready var _settings_btn: Button = $Panel/VBox/SettingsButton
@onready var _quit_btn: Button = $Panel/VBox/QuitButton
@onready var _new_game_screen: Control = $NewGameScreen
@onready var _settings_screen: Control = $SettingsScreen
@onready var _title_label: Label = $TitleLabel
@onready var _version_label: Label = $VersionLabel

const MenuScale = preload("res://scripts/ui/MenuScale.gd")

# V027-05a: MainMenu is a "pinned-large home screen" — exempt from the user's
# Menu Scale setting, always shown as big as the screen comfortably allows.
# This is the padding kept clear around the grown panel and between it and the
# fixed TitleLabel/VersionLabel siblings it must never overlap (that overlap,
# at 2.0x Menu Scale under the old shared-scale behavior, was V030-REG-01).
const _AVAILABLE_MARGIN := 24.0


func _ready() -> void:
	add_to_group(MenuScale.GROUP)
	_continue_btn.pressed.connect(_on_continue)
	_new_game_btn.pressed.connect(_on_new_game)
	_settings_btn.pressed.connect(_on_settings)
	_quit_btn.pressed.connect(_on_quit)
	_new_game_screen.back_pressed.connect(_on_new_game_back)
	_settings_screen.back_pressed.connect(_on_settings_back)
	apply_menu_scale(1.0)
	_refresh_continue_state()
	if not _continue_btn.disabled:
		_continue_btn.grab_focus()
	else:
		_new_game_btn.grab_focus()


# `factor` is intentionally ignored (V027-05a) — MainMenu stays a
# `menu_scale_targets` member purely to piggyback on SettingsManager's existing
# window/viewport resize-refresh plumbing (it calls apply_menu_scale on every
# group member on both a Menu Scale change AND a debounced resize), not because
# it follows the shared user setting. The panel always grows/shrinks to the
# largest size that fits between the title and version label.
func apply_menu_scale(_factor: float) -> void:
	MenuScale.apply_to_fit_rect($Panel, _available_rect())


# The rect the Panel is allowed to fill: full viewport width (inset by the
# margin) and the vertical band between the title's bottom edge and the version
# label's top edge (also inset), so growing the panel can never cover either.
# get_rect() (not get_global_rect()) deliberately: it's LOCAL to MainMenu, the
# same space $Panel.position lives in, since Title/Version/Panel are siblings.
func _available_rect() -> Rect2:
	var vp: Vector2 = get_viewport_rect().size
	var top: float = _title_label.get_rect().end.y + _AVAILABLE_MARGIN
	var bottom: float = _version_label.get_rect().position.y - _AVAILABLE_MARGIN
	return Rect2(
		Vector2(_AVAILABLE_MARGIN, top),
		Vector2(maxf(vp.x - _AVAILABLE_MARGIN * 2.0, 0.0), maxf(bottom - top, 0.0)))


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
