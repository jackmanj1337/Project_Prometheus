extends Control
# Victory-only battle results. Campaign position remains unchanged until the
# player confirms Continue (and, for a branch, explicitly chooses a successor).

const MenuScale = preload("res://scripts/ui/MenuScale.gd")
const Standings = preload("res://scripts/ui/StandingsFormatter.gd")

@onready var _standings_label: Label = $Panel/VBox/Standings
@onready var _rewards_label: Label = $Panel/VBox/Rewards
@onready var _casualties_label: Label = $Panel/VBox/Casualties
@onready var _progression_label: Label = $Panel/VBox/Progression
@onready var _save_status_label: Label = $Panel/VBox/SaveStatus
@onready var _successor_label: Label = $Panel/VBox/SuccessorLabel
@onready var _successor_picker: OptionButton = $Panel/VBox/SuccessorPicker
@onready var _continue_button: Button = $Panel/VBox/ContinueButton

var _result_pending := false
var _level_up_active := false
var _promotion_active := false
var _suspend_deleted_for_result := false


func _ready() -> void:
	add_to_group(MenuScale.GROUP)
	hide()
	_continue_button.pressed.connect(_on_continue)
	_successor_picker.item_selected.connect(_on_successor_selected)
	var bus := get_node_or_null("/root/EventBus")
	if bus != null:
		bus.map_victory.connect(_on_victory)
		bus.map_resolved.connect(_on_map_resolved)
		bus.level_up_started.connect(func(): _level_up_active = true)
		bus.level_up_finished.connect(_on_level_up_finished)
		bus.promotion_started.connect(func(): _promotion_active = true)
		bus.promotion_finished.connect(_on_promotion_finished)
	apply_menu_scale(MenuScale.factor_from_settings(self))


func apply_menu_scale(factor: float) -> void:
	MenuScale.apply_to($Panel, factor, true)


func _on_victory() -> void:
	_request_present()


func _on_map_resolved(winner_group: String, standings: Array) -> void:
	# This surface listens only after a victory request. Defeat standings belong
	# to GameOverScreen even though both receive the shared map_resolved signal.
	if not _result_pending and not visible:
		return
	_standings_label.text = Standings.format(winner_group, standings)
	_request_present()


func _request_present() -> void:
	_delete_mid_map_slot_after_resolution()
	_result_pending = true
	_try_present()


func _try_present() -> void:
	if not _result_pending or _level_up_active or _promotion_active:
		return
	_result_pending = false
	_refresh_result()
	show()
	if _continue_button.disabled and _successor_picker.visible:
		_successor_picker.grab_focus()
	else:
		_continue_button.grab_focus()


func _on_level_up_finished() -> void:
	_level_up_active = false
	if _result_pending:
		call_deferred("_try_present")


func _on_promotion_finished() -> void:
	_promotion_active = false
	if _result_pending:
		call_deferred("_try_present")


func _refresh_result() -> void:
	var cm := _campaign_manager()
	var result: Dictionary = cm.call("get_pending_result") if cm != null else {}
	_rewards_label.text = _summary_line("Rewards", result.get("rewards", []), "None reported")
	_casualties_label.text = _summary_line("Casualties", result.get("casualties", []), "None reported")
	_progression_label.text = _summary_line("Progression", result.get("progression", []), "Resolved")
	_save_status_label.text = "Save: writes after Continue" if cm != null else "Save: not a campaign battle"
	_successor_picker.clear()
	_successor_label.hide()
	_successor_picker.hide()
	_continue_button.disabled = false
	_continue_button.text = "Return to Menu"
	if cm == null:
		return
	var options: Array = cm.call("get_pending_successor_options")
	if options.is_empty():
		_continue_button.text = "Finish Campaign"
		return
	if options.size() == 1:
		_continue_button.text = "Continue: %s" % String(options[0].get("label", "Next Battle"))
		return
	_successor_label.show()
	_successor_picker.show()
	_successor_picker.add_item("Choose the next chapter…")
	_successor_picker.set_item_metadata(0, "")
	for option in options:
		_successor_picker.add_item(String(option.get("label", option.get("node_id", ""))))
		_successor_picker.set_item_metadata(_successor_picker.item_count - 1,
			String(option.get("node_id", "")))
	_continue_button.text = "Continue"
	_continue_button.disabled = true


func _summary_line(label: String, value: Variant, fallback: String) -> String:
	if value is Array and not value.is_empty():
		return "%s: %s" % [label, ", ".join(value.map(func(entry): return str(entry)))]
	if value is String and not value.is_empty():
		return "%s: %s" % [label, value]
	return "%s: %s" % [label, fallback]


func _on_successor_selected(index: int) -> void:
	var node_id: String = String(_successor_picker.get_item_metadata(index))
	var cm := _campaign_manager()
	_continue_button.disabled = cm == null or node_id == "" \
		or not bool(cm.call("choose_pending_successor", node_id))


func _on_continue() -> void:
	var cm := _campaign_manager()
	if cm == null:
		_quit_to_menu()
		return
	var result: Dictionary = cm.call("get_pending_result")
	if not bool(result.get("campaign_complete", false)) \
			and not bool(cm.call("prepare_pending_advance")):
		_save_status_label.text = "Save: could not validate the next battle"
		return
	if not bool(cm.call("commit_pending_result")):
		_save_status_label.text = "Save: campaign advance failed"
		return
	_save_status_label.text = "Save: autosaved"
	if bool(cm.call("is_campaign_complete")):
		cm.call("end_campaign")
		_quit_to_menu()
		return
	cm.call("launch_prepared_node")


func _campaign_manager() -> Node:
	var cm := get_node_or_null("/root/CampaignManager")
	if cm == null or not bool(cm.call("is_campaign_active")):
		return null
	return cm


func _delete_mid_map_slot_after_resolution() -> void:
	if _suspend_deleted_for_result:
		return
	_suspend_deleted_for_result = true
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null and save_manager.has_method("delete_slot"):
		save_manager.call("delete_slot", "resume_battle")


func _unhandled_input(_event: InputEvent) -> void:
	if visible:
		get_viewport().set_input_as_handled()


func _quit_to_menu() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("reset_map_state"):
		gs.call("reset_map_state")
	get_tree().change_scene_to_file("res://scenes/core/Boot.tscn")
