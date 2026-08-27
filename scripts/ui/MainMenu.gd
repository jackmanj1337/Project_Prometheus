extends Control
# Main menu: Continue resumes the most recent save (a mid-map suspend or a
# between-map campaign slot), Load Game opens the campaign-slot picker, New Game
# opens the NewGameScreen overlay, Settings opens the SettingsScreen overlay, and
# Quit exits.

@onready var _menu_frame: CenterContainer = $MenuFrame
@onready var _panel: PanelContainer = $MenuFrame/Panel
@onready var _button_list: VBoxContainer = $MenuFrame/Panel/Scroll/VBox
@onready var _continue_btn: Button = $MenuFrame/Panel/Scroll/VBox/ContinueButton
@onready var _load_game_btn: Button = $MenuFrame/Panel/Scroll/VBox/LoadGameButton
@onready var _new_game_btn: Button = $MenuFrame/Panel/Scroll/VBox/NewGameButton
@onready var _campaign_library_btn: Button = $MenuFrame/Panel/Scroll/VBox/CampaignLibraryButton
@onready var _settings_btn: Button = $MenuFrame/Panel/Scroll/VBox/SettingsButton
@onready var _quit_btn: Button = $MenuFrame/Panel/Scroll/VBox/QuitButton
@onready var _load_game_screen: Control = $LoadGameScreen
@onready var _new_game_screen: Control = $NewGameScreen
@onready var _campaign_library_screen: Control = $CampaignLibraryScreen

# Set while the campaign library was opened from the load picker's recovery action.
var _return_to_load_game := false
@onready var _settings_screen: Control = $SettingsScreen
@onready var _title_label: Label = $TitleLabel
@onready var _version_label: Label = $VersionLabel

const MenuScale = preload("res://scripts/ui/MenuScale.gd")
const CampaignPackRegistry = preload("res://scripts/resources/CampaignPackRegistry.gd")
const _SAFE_VIEWPORT_RATIO := 0.9

# Main Menu is intentionally one stable tree at every size. Class changes only alter
# constraints, so the focused button and ScrollContainer position cannot be discarded by
# a rebuild during a live window resize.
const _PANEL_WIDTH_RATIOS := {
	"compact": 1.0,
	"medium": 0.72,
	"expanded": 0.42,
}
const _TITLE_FONT_MULTIPLIERS := {
	"compact": 2.0,
	"medium": 3.0,
	"expanded": 4.0,
}


func _ready() -> void:
	add_to_group(MenuScale.GROUP)
	_continue_btn.pressed.connect(_on_continue)
	_load_game_btn.pressed.connect(_on_load_game)
	_new_game_btn.pressed.connect(_on_new_game)
	_campaign_library_btn.pressed.connect(_on_campaign_library)
	_settings_btn.pressed.connect(_on_settings)
	_quit_btn.pressed.connect(_on_quit)
	# The picker names a slot; the restore itself stays here (_load_slot),
	# so Continue and Load Game cannot drift apart.
	_load_game_screen.slot_load_requested.connect(_on_slot_load_requested)
	_load_game_screen.slots_changed.connect(_refresh_menu_state)
	_load_game_screen.back_pressed.connect(_on_load_game_back)
	_load_game_screen.manage_campaigns_requested.connect(_on_manage_campaigns_requested)
	_new_game_screen.back_pressed.connect(_on_new_game_back)
	_campaign_library_screen.back_pressed.connect(_on_campaign_library_back)
	_campaign_library_screen.campaigns_changed.connect(_refresh_menu_state)
	_settings_screen.back_pressed.connect(_on_settings_back)
	var responsive := _responsive_layout()
	if responsive != null:
		responsive.size_class_changed.connect(_on_responsive_layout_changed)
		responsive.density_changed.connect(_on_density_changed)
	apply_menu_scale(1.0)
	_refresh_menu_state()
	if not _continue_btn.disabled:
		_continue_btn.grab_focus()
	elif not _new_game_btn.disabled:
		_new_game_btn.grab_focus()
	else:
		_campaign_library_btn.grab_focus()


# Main Menu is a pinned-large home screen: it uses all safe space between its
# title and version instead of following the in-game Menu Scale preference.
func apply_menu_scale(_factor: float) -> void:
	_apply_responsive_tokens()
	var available := _available_rect()
	var responsive := _responsive_layout()
	var size_class := _size_class(responsive)
	var width_ratio: float = _PANEL_WIDTH_RATIOS.get(size_class, 0.42)
	var capped := Vector2(available.size.x * width_ratio, available.size.y * _SAFE_VIEWPORT_RATIO)
	_panel.custom_minimum_size = Vector2(maxf(capped.x, 0.0), maxf(capped.y, 0.0))
	_menu_frame.offset_left = available.position.x
	_menu_frame.offset_top = available.position.y
	_menu_frame.offset_right = -(get_viewport_rect().size.x - available.end.x)
	_menu_frame.offset_bottom = -(get_viewport_rect().size.y - available.end.y)
	# Responsive tokens are already expressed in logical pixels. The viewport content
	# scale turns those into the intended physical size; applying MenuScale here as well
	# would multiply the two density authorities.
	_panel.scale = Vector2.ONE


func _responsive_layout() -> Node:
	return get_node_or_null("/root/ResponsiveLayout")


func _size_class(responsive: Node) -> String:
	return String(responsive.get("size_class")) if responsive != null else "expanded"


func _responsive_token(responsive: Node, token_name: String, fallback: float) -> float:
	if responsive != null and responsive.has_method("token"):
		return float(responsive.call("token", token_name, fallback))
	return fallback


func _apply_responsive_tokens() -> void:
	var responsive := _responsive_layout()
	var size_class := _size_class(responsive)
	var row_height := _responsive_token(responsive, "row_height", 48.0)
	var row_gap := _responsive_token(responsive, "row_gap", 8.0)
	var body_font := _responsive_token(responsive, "body_font", 16.0)
	var gutter := _responsive_token(responsive, "gutter", 16.0)
	var header := _responsive_token(responsive, "header", 72.0)
	var footer := _responsive_token(responsive, "footer", 64.0)

	_button_list.add_theme_constant_override("separation", roundi(row_gap))
	for button in [_continue_btn, _load_game_btn, _new_game_btn, _settings_btn, _quit_btn]:
		var menu_button: Button = button
		menu_button.custom_minimum_size.y = row_height
		menu_button.add_theme_font_size_override("font_size", roundi(body_font))

	_title_label.offset_top = gutter
	_title_label.offset_bottom = gutter + header
	_title_label.add_theme_font_size_override(
		"font_size", roundi(body_font * float(_TITLE_FONT_MULTIPLIERS.get(size_class, 4.0)))
	)
	_version_label.offset_left = -(body_font * 10.0)
	_version_label.offset_top = -(footer + gutter)
	_version_label.offset_right = -gutter
	_version_label.offset_bottom = -gutter
	_version_label.add_theme_font_size_override("font_size", roundi(body_font))


func _on_responsive_layout_changed(_new_class: String, _previous_class: String) -> void:
	apply_menu_scale(1.0)


func _on_density_changed() -> void:
	apply_menu_scale(1.0)


func _available_rect() -> Rect2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var gutter := _responsive_token(_responsive_layout(), "gutter", 16.0)
	var settings := get_node_or_null("/root/SettingsManager")
	var safe := Vector4i.ZERO
	if settings != null and settings.has_method("get_safe_area_insets"):
		safe = settings.call("get_safe_area_insets")
	var top: float = maxf(_title_label.get_rect().end.y + gutter, safe.y)
	var bottom: float = minf(
		_version_label.get_rect().position.y - gutter, viewport_size.y - safe.w
	)
	return Rect2(
		Vector2(maxf(gutter, safe.x), top),
		Vector2(
			maxf(viewport_size.x - maxf(gutter, safe.x) - maxf(gutter, safe.z), 0.0),
			maxf(bottom - top, 0.0)
		)
	)


func _refresh_menu_state() -> void:
	_refresh_continue_state()
	_refresh_load_state()
	_refresh_new_game_state()


func _refresh_new_game_state() -> void:
	var data_manager := get_node_or_null("/root/DataManager")
	# Availability is a property of the installed library, not the currently
	# active runtime package. Import must enable New Game without loading content.
	var registry := CampaignPackRegistry.new(CampaignPackRegistry.DEFAULT_STORAGE_ROOT)
	registry.refresh()
	var playable := registry.playable_campaign_count() > 0
	_new_game_btn.disabled = not playable
	_new_game_btn.text = "New Game" if playable else "New Game (No Data Packs Installed)"
	_new_game_btn.tooltip_text = "" if playable else _no_pack_message(data_manager)


func _no_pack_message(data_manager: Node) -> String:
	if data_manager != null and data_manager.has_method("content_status"):
		var status: Dictionary = data_manager.call("content_status")
		var errors: Array = status.get("errors", [])
		if not errors.is_empty():
			return "No playable campaign is active. Pack validation failed: %s" % String(errors[0])
	return "No playable campaign is active. Install or select a campaign pack."


func _refresh_continue_state() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	_continue_btn.disabled = (
		save_manager == null
		or not save_manager.has_method("has_continue_save")
		or not bool(save_manager.call("has_continue_save"))
	)
	_continue_btn.tooltip_text = (
		"" if not _continue_btn.disabled else _menu_text("menu.continue.no_saves")
	)


# Reads the shared table the same way RequirementSystem.render_reason does, so the
# menu's gate reasons and the predicate vocabulary come from one place rather than
# each surface phrasing its own ([EPUX-04]).
func _menu_text(key: String) -> String:
	var text_db := get_node_or_null("/root/TextDB")
	if text_db != null and text_db.has_method("tr_key"):
		return text_db.call("tr_key", key)
	return key


# Load Game is only offered when there is something to load, mirroring Continue.
# A player with no campaign save sees exactly the old menu, with Load greyed out.
func _refresh_load_state() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null or not save_manager.has_method("list_slots"):
		_load_game_btn.disabled = true
		return
	var slots: Array = save_manager.call("list_slots")
	_load_game_btn.disabled = slots.is_empty()
	# [EPUX-07]/[RPD-15]: a gated entry stays reachable AND carries a reason. Load Game
	# was gated with no reason at all, so a keyboard or screen-reader user reached a
	# dimmed button that explained nothing — the "inaccessible and opaque" outcome the
	# ruling rejects by name. New Game already carried one; these two did not.
	_load_game_btn.tooltip_text = (
		"" if not _load_game_btn.disabled else _menu_text("menu.load_game.no_saves")
	)


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
		if (
			gs == null
			or not gs.has_method("configure_suspend_resume")
			or not bool(gs.call("configure_suspend_resume", save))
		):
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
		_show_continue_error(
			"Could not launch the next battle.\nThe campaign node may be misconfigured."
		)
		return false
	_consume_loaded_slot_if_required(save_manager, slot_id, gs)
	return true


func _consume_loaded_slot_if_required(save_manager: Node, slot_id: String, gs: Node) -> void:
	if not save_manager.has_method("should_consume_on_load") or gs == null:
		return
	if not gs.has_method("get_save_slot_classes"):
		return
	if bool(save_manager.call("should_consume_on_load", slot_id, gs.call("get_save_slot_classes"))):
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
	if _new_game_btn.disabled:
		return
	_new_game_screen.open()


func _on_new_game_back() -> void:
	_refresh_continue_state()
	_new_game_btn.grab_focus()


func _on_campaign_library() -> void:
	_campaign_library_screen.open()


# The load picker sent the player here to install a disabled save's package, so
# Back belongs to that picker, not to the main menu: returning them to the menu
# would strand the save they came to fix one screen away.
func _on_manage_campaigns_requested() -> void:
	_return_to_load_game = true
	_campaign_library_screen.open()


func _on_campaign_library_back() -> void:
	_refresh_menu_state()
	if _return_to_load_game:
		_return_to_load_game = false
		_load_game_screen.open()
		return
	_campaign_library_btn.grab_focus()


func _on_settings() -> void:
	_settings_screen.open()


func _on_settings_back() -> void:
	_refresh_continue_state()
	_settings_btn.grab_focus()


# The open_settings keybinding opens the settings screen from the main menu.
# Ignored while either overlay is already showing — those handle their own input.
func _unhandled_input(event: InputEvent) -> void:
	if (
		event.is_action_pressed("open_settings")
		and not _settings_screen.visible
		and not _new_game_screen.visible
		and not _campaign_library_screen.visible
		and not _load_game_screen.visible
	):
		_on_settings()
		get_viewport().set_input_as_handled()


func _on_quit() -> void:
	get_tree().quit()
