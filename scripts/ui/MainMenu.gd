extends Control
# Main menu: Continue resumes the most recent save (a mid-map suspend or a
# between-map campaign slot), Load Game opens the campaign-slot picker, New Game
# opens the NewGameScreen overlay, Settings opens the SettingsScreen overlay, and
# Quit exits.

@onready var _continue_btn: Button = $Panel/VBox/ContinueButton
@onready var _load_game_btn: Button = $Panel/VBox/LoadGameButton
@onready var _new_game_btn: Button = $Panel/VBox/NewGameButton
@onready var _settings_btn: Button = $Panel/VBox/SettingsButton
@onready var _quit_btn: Button = $Panel/VBox/QuitButton
@onready var _load_game_screen: Control = $LoadGameScreen
@onready var _new_game_screen: Control = $NewGameScreen
@onready var _settings_screen: Control = $SettingsScreen

const MenuScale = preload("res://scripts/ui/MenuScale.gd")


func _ready() -> void:
	add_to_group(MenuScale.GROUP)
	_continue_btn.pressed.connect(_on_continue)
	_load_game_btn.pressed.connect(_on_load_game)
	_new_game_btn.pressed.connect(_on_new_game)
	_settings_btn.pressed.connect(_on_settings)
	_quit_btn.pressed.connect(_on_quit)
	# The picker names a slot; the restore itself stays here (_load_slot),
	# so Continue and Load Game cannot drift apart.
	_load_game_screen.slot_load_requested.connect(_on_slot_load_requested)
	_load_game_screen.slots_changed.connect(_refresh_menu_state)
	_load_game_screen.back_pressed.connect(_on_load_game_back)
	_new_game_screen.back_pressed.connect(_on_new_game_back)
	_settings_screen.back_pressed.connect(_on_settings_back)
	_apply_menu_scale_from_settings()
	_refresh_menu_state()
	if not _continue_btn.disabled:
		_continue_btn.grab_focus()
	else:
		_new_game_btn.grab_focus()


func apply_menu_scale(factor: float) -> void:
	MenuScale.apply_to($Panel, factor, true)


func _apply_menu_scale_from_settings() -> void:
	apply_menu_scale(MenuScale.factor_from_settings(self))


func _refresh_menu_state() -> void:
	_refresh_continue_state()
	_refresh_load_state()


func _refresh_continue_state() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	_continue_btn.disabled = save_manager == null \
		or not save_manager.has_method("has_continue_save") \
		or not bool(save_manager.call("has_continue_save"))


# Load Game is only offered when there is something to load, mirroring Continue.
# A player with no campaign save sees exactly the old menu, with Load greyed out.
func _refresh_load_state() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null or not save_manager.has_method("list_slots"):
		_load_game_btn.disabled = true
		return
	var slots: Array = save_manager.call("list_slots")
	_load_game_btn.disabled = slots.is_empty()


# Continue resumes the most recently written save, which is one of two different
# documents: a mid-map suspend (resumes into the live board) or a campaign slot
# (resumes parked between maps, and launches the node the party is sitting on).
# SaveManager owns which is newest; the loaded document's map discriminator routes it.
func _on_continue() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null or not save_manager.has_method("get_continue_target"):
		_show_continue_error("Continue is unavailable.\nNo save service was found.")
		_refresh_continue_state()
		return
	var target: Dictionary = save_manager.call("get_continue_target")
	if String(target.get("kind", "")) == "slot":
		_load_slot(save_manager, String(target.get("slot_id", "")))
	else:
		_show_continue_error("There is no save to continue.")
		_refresh_continue_state()


# A campaign slot restores the position and party, then launches the parked node.
# CampaignManager owns the launch (it resolves the node's map binding), so this
# does not change scene itself.
func _load_slot(save_manager: Node, slot_id: String, change_scene: bool = true) -> bool:
	if not save_manager.has_method("load_slot"):
		_show_continue_error("Continue is unavailable.\nNo save service was found.")
		_refresh_continue_state()
		return false
	var save: Variant = save_manager.call("load_slot", slot_id)
	if save == null:
		_show_continue_error("Could not load the campaign save.\nProgress was not resumed.")
		_refresh_continue_state()
		return false
	var payload: Dictionary = save.to_dict()
	var gs := get_node_or_null("/root/GameState")
	if String(payload.get("map_runtime", {}).get("map_path", "")) != "":
		if gs == null or not gs.has_method("configure_suspend_resume") \
				or not bool(gs.call("configure_suspend_resume", save)):
			_show_continue_error("Could not resume the battle save.\nMap progress was not resumed.")
			_refresh_continue_state()
			return false
		if change_scene:
			if get_tree().change_scene_to_file("res://scenes/core/GameMap.tscn") != OK:
				_show_continue_error("Could not open the restored battle scene.")
				return false
			_consume_loaded_slot_if_required(save_manager, slot_id, gs)
		return true
	var cm := get_node_or_null("/root/CampaignManager")
	if gs == null or cm == null or not gs.has_method("configure_campaign_resume"):
		_show_continue_error("Continue is unavailable.\nGame state could not be prepared.")
		_refresh_continue_state()
		return false
	if not bool(gs.call("configure_campaign_resume", save)):
		_show_continue_error("Could not resume the campaign save.\nProgress was not resumed.")
		_refresh_continue_state()
		return false
	# A finished campaign has no node left to launch — say so rather than failing
	# into an error on an empty position.
	if bool(cm.call("is_campaign_complete")):
		_show_continue_error("This campaign is already complete.")
		return false
	if not bool(cm.call("launch_current_node")):
		_show_continue_error("Could not launch the next battle.\nThe campaign node may be misconfigured.")
		return false
	_consume_loaded_slot_if_required(save_manager, slot_id, gs)
	return true


func _consume_loaded_slot_if_required(save_manager: Node, slot_id: String, gs: Node) -> void:
	if not save_manager.has_method("should_consume_on_load") or gs == null:
		return
	if not gs.has_method("get_save_slot_classes"):
		return
	if bool(save_manager.call("should_consume_on_load", slot_id,
			gs.call("get_save_slot_classes"))):
		if not bool(save_manager.call("delete_slot", slot_id)):
			push_error("MainMenu: failed to consume loaded slot '%s'" % slot_id)


# Compatibility seam for existing callers while all slots now route through one
# discriminator-driven loader.
func _load_campaign_slot(save_manager: Node, slot_id: String) -> bool:
	return _load_slot(save_manager, slot_id)


func _show_continue_error(message: String) -> void:
	var dlg := AcceptDialog.new()
	dlg.dialog_text = message
	dlg.confirmed.connect(func(): dlg.queue_free())
	add_child(dlg)
	dlg.popup_centered()
	dlg.get_ok_button().grab_focus()


func _on_load_game() -> void:
	_load_game_screen.open()


# The picker chose a slot. On success _load_slot changes scene, so the
# overlay only needs closing on failure — where its error dialog is already up and
# the player stays on the picker with the list intact.
func _on_slot_load_requested(slot_id: String) -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		_show_continue_error("Loading is unavailable.\nNo save service was found.")
		return
	_load_slot(save_manager, slot_id)


func _on_load_game_back() -> void:
	_refresh_menu_state()
	# Deleting the last slot disables the button we came from, and a disabled button
	# cannot hold focus — fall back rather than leaving the menu with no focus at all.
	if _load_game_btn.disabled:
		_new_game_btn.grab_focus()
	else:
		_load_game_btn.grab_focus()


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
			and not _settings_screen.visible and not _new_game_screen.visible \
			and not _load_game_screen.visible:
		_on_settings()
		get_viewport().set_input_as_handled()


func _on_quit() -> void:
	get_tree().quit()
