extends Control
# Victory-only battle results. Campaign position remains unchanged until the
# player confirms Continue (and, for a branch, explicitly chooses a successor).

const MenuScale = preload("res://scripts/ui/MenuScale.gd")
const Standings = preload("res://scripts/ui/StandingsFormatter.gd")
const FocusNavigatorS = preload("res://scripts/shared/FocusNavigator.gd")
const _SAFE_VIEWPORT_RATIO := 0.9
const _PREFERRED_PANEL_SIZE := Vector2(1120, 620)

@onready var _results_layout: BoxContainer = $Panel/VBox
@onready var _standings_label: Label = $Panel/VBox/SummaryScroll/Summary/Standings
@onready var _rewards_label: Label = $Panel/VBox/SummaryScroll/Summary/Rewards
@onready var _casualties_label: Label = $Panel/VBox/SummaryScroll/Summary/Casualties
@onready var _progression_label: Label = $Panel/VBox/SummaryScroll/Summary/Progression
@onready var _save_status_label: Label = $Panel/VBox/Actions/SaveStatus
@onready var _successor_label: Label = $Panel/VBox/Actions/SuccessorLabel
@onready var _successor_picker: OptionButton = $Panel/VBox/Actions/SuccessorPicker
@onready var _continue_button: Button = $Panel/VBox/Actions/ContinueButton
@onready var _retry_button: Button = $Panel/VBox/Actions/RetryButton
@onready var _save_button: Button = $Panel/VBox/Actions/SaveButton
@onready var _quit_button: Button = $Panel/VBox/Actions/QuitButton
@onready var _retry_committed_confirm: ConfirmationDialog = $RetryCommittedConfirm
var _campaign_data_error := false

var _result_pending := false
var _level_up_active := false
var _promotion_active := false
var _suspend_deleted_for_result := false
var _reward_receipt: Dictionary = {}
var _modal_lock_held := false
var _result_committed := false
var _committed_complete := false
var _focus_nav: RefCounted
var _retry_campaign_state: Dictionary = {}
var _retry_node_id := ""


func _ready() -> void:
	_focus_nav = FocusNavigatorS.new(self)
	add_to_group(MenuScale.GROUP)
	hide()
	_continue_button.pressed.connect(_on_continue)
	_retry_button.pressed.connect(_on_retry)
	_save_button.pressed.connect(_on_save)
	_quit_button.pressed.connect(_quit_to_menu)
	_successor_picker.item_selected.connect(_on_successor_selected)
	_retry_committed_confirm.confirmed.connect(_retry_committed_branch)
	get_viewport().size_changed.connect(_update_responsive_layout)
	var bus := get_node_or_null("/root/EventBus")
	if bus != null:
		bus.map_victory.connect(_on_victory)
		bus.map_resolved.connect(_on_map_resolved)
		bus.reward_committed.connect(_on_reward_committed)
		bus.level_up_started.connect(func(): _level_up_active = true)
		bus.level_up_finished.connect(_on_level_up_finished)
		bus.promotion_started.connect(func(): _promotion_active = true)
		bus.promotion_finished.connect(_on_promotion_finished)
	apply_menu_scale(MenuScale.factor_from_settings(self))
	_update_responsive_layout()


func apply_menu_scale(factor: float) -> void:
	# Panel centres via scene anchors + grow_both; MenuScale only type-scales.
	_apply_responsive_frame()
	MenuScale.apply_to($Panel, factor)


func _update_responsive_layout() -> void:
	# Wide viewports keep actions persistently visible beside the scrollable report.
	# Narrow windows collapse to a vertical flow that the panel can contain safely.
	_results_layout.vertical = get_viewport_rect().size.x < 1000.0
	_apply_responsive_frame()


func _apply_responsive_frame() -> void:
	var viewport_size := get_viewport_rect().size
	var safe := Vector4i.ZERO
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null and settings.has_method("get_safe_area_insets"):
		safe = settings.call("get_safe_area_insets")
	var safe_size := Vector2(
		maxf(viewport_size.x - safe.x - safe.z, 0.0), maxf(viewport_size.y - safe.y - safe.w, 0.0)
	)
	var desired := Vector2(
		minf(_PREFERRED_PANEL_SIZE.x, safe_size.x * _SAFE_VIEWPORT_RATIO),
		minf(_PREFERRED_PANEL_SIZE.y, safe_size.y * _SAFE_VIEWPORT_RATIO)
	)
	$Panel.custom_minimum_size = desired
	$Panel.set_anchors_preset(Control.PRESET_CENTER)
	var safe_center := Vector2(safe.x, safe.y) + safe_size * 0.5
	var delta := safe_center - viewport_size * 0.5
	$Panel.offset_left = -desired.x * 0.5 + delta.x
	$Panel.offset_top = -desired.y * 0.5 + delta.y
	$Panel.offset_right = desired.x * 0.5 + delta.x
	$Panel.offset_bottom = desired.y * 0.5 + delta.y


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


func _on_reward_committed(receipt: Dictionary) -> void:
	_reward_receipt = receipt.duplicate(true)


func _try_present() -> void:
	if not _result_pending or _level_up_active or _promotion_active:
		return
	_result_pending = false
	_acquire_modal_lock()
	_refresh_result()
	show()
	if _continue_button.visible and not _continue_button.disabled:
		_continue_button.grab_focus()
	elif _continue_button.disabled and _successor_picker.visible:
		_successor_picker.grab_focus()
	else:
		_focus_nav.call_deferred("grab_default")


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
	var authored_rewards := _summary_line("Rewards", result.get("rewards", []), "None reported")
	if _reward_receipt.is_empty():
		_rewards_label.text = authored_rewards
	else:
		_rewards_label.text = (
			"%s\nGold earned: %d\nTotal gold: %d"
			% [
				authored_rewards,
				int(_reward_receipt.get("gold_earned", 0)),
				int(_reward_receipt.get("total_gold", 0)),
			]
		)
	_casualties_label.text = _summary_line(
		"Casualties", result.get("casualties", []), "None reported"
	)
	_progression_label.text = _summary_line(
		"Progression", result.get("progression", []), "Resolved"
	)
	_save_status_label.text = (
		"Save: writes after Continue" if cm != null else "Save: not a campaign battle"
	)
	_successor_picker.clear()
	_successor_picker.disabled = false
	_successor_label.hide()
	_successor_picker.hide()
	_continue_button.disabled = false
	_save_button.disabled = false
	_continue_button.text = "Return to Menu"
	_campaign_data_error = false
	_result_committed = false
	_committed_complete = false
	_retry_campaign_state.clear()
	_retry_node_id = ""
	_apply_action_policy()
	if cm == null:
		return
	var options: Array = cm.call("get_pending_successor_options")
	var result_complete := bool(result.get("campaign_complete", false))
	if result_complete:
		_continue_button.text = "Finish Campaign"
		return
	if options.is_empty():
		_campaign_data_error = true
		_continue_button.text = "Return to Menu"
		_save_status_label.text = "Save: next battle is unavailable"
		var pending: Dictionary = cm.call("get_pending_result")
		var campaign: Variant = (
			cm.call("get_active_campaign") if cm.has_method("get_active_campaign") else null
		)
		var node_id := String(pending.get("node_id", ""))
		var node: Variant = campaign.call("get_node_by_id", node_id) if campaign != null else null
		var successors: Array = node.next_node_ids if node != null else []
		push_error(
			(
				"Campaign Data Error: campaign='%s' node='%s' successors=%s"
				% [String(pending.get("campaign_id", "")), node_id, str(successors)]
			)
		)
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
		_successor_picker.set_item_metadata(
			_successor_picker.item_count - 1, String(option.get("node_id", ""))
		)
	_continue_button.text = "Continue"
	_continue_button.disabled = true
	_save_button.disabled = true


func _summary_line(label: String, value: Variant, fallback: String) -> String:
	if value is Array and not value.is_empty():
		return "%s: %s" % [label, ", ".join(value.map(func(entry): return str(entry)))]
	if value is String and not value.is_empty():
		return "%s: %s" % [label, value]
	return "%s: %s" % [label, fallback]


func _on_successor_selected(index: int) -> void:
	var node_id: String = String(_successor_picker.get_item_metadata(index))
	var cm := _campaign_manager()
	var choice_invalid := (
		cm == null or node_id == "" or not bool(cm.call("choose_pending_successor", node_id))
	)
	_continue_button.disabled = choice_invalid
	_save_button.disabled = choice_invalid


func _on_continue() -> void:
	var cm := _campaign_manager()
	if cm == null or _campaign_data_error:
		_quit_to_menu()
		return
	if not _result_committed and not _commit_result(cm):
		return
	if _committed_complete or bool(cm.call("is_campaign_complete")):
		if cm.has_method("export_completion_status_record"):
			cm.call("export_completion_status_record")
		cm.call("end_campaign")
		_quit_to_menu()
		return
	cm.call("launch_prepared_node")


func _on_save() -> void:
	var cm := _campaign_manager()
	if cm == null or _campaign_data_error:
		return
	if _successor_picker.visible and _continue_button.disabled:
		_save_status_label.text = "Choose the next chapter before saving."
		_successor_picker.grab_focus()
		return
	var sm := get_node_or_null("/root/SaveManager")
	if not _result_committed and sm != null and sm.has_method("manual_slot_budget"):
		var budget: Dictionary = sm.call("manual_slot_budget", "between_map")
		if bool(budget.get("full", false)):
			_save_status_label.text = (
				"All %d campaign save slots are in use." % int(budget.get("cap", 0))
			)
			return
	if not _result_committed and not _commit_result(cm):
		return
	var slot_id := "results-%d" % int(Time.get_unix_time_from_system() * 1000.0)
	var label := "Campaign Complete" if _committed_complete else "After Victory"
	if bool(cm.call("write_campaign_slot", slot_id, label)):
		_save_status_label.text = "Saved."
		_save_button.disabled = true
	else:
		_save_status_label.text = "Save failed."


func _commit_result(cm: Node) -> bool:
	var result: Dictionary = cm.call("get_pending_result")
	if _retry_campaign_state.is_empty():
		_retry_campaign_state = cm.call("capture_campaign_state")
		_retry_node_id = String(result.get("node_id", ""))
	if (
		not bool(result.get("campaign_complete", false))
		and not bool(cm.call("prepare_pending_advance"))
	):
		_save_status_label.text = "Save: could not validate the next battle"
		return false
	if not bool(cm.call("commit_pending_result")):
		_save_status_label.text = "Save: campaign advance failed"
		return false
	_result_committed = true
	_committed_complete = bool(cm.call("is_campaign_complete"))
	_successor_picker.disabled = true
	_save_status_label.text = "Progress committed and autosaved."
	return true


func _on_retry() -> void:
	if _result_committed:
		_retry_committed_confirm.popup_centered()
		return
	_retry_uncommitted()


func _retry_uncommitted() -> void:
	var cm := _campaign_manager()
	if cm != null:
		cm.call("clear_pending_result")
	var gs := get_node_or_null("/root/GameState")
	var restored := (
		gs != null and gs.has_method("restore_history") and bool(gs.call("restore_history", 0))
	)
	_release_modal_lock()
	if restored and cm != null and bool(cm.call("route_retry_to_prep")):
		return
	get_tree().reload_current_scene()


func _retry_committed_branch() -> void:
	var cm := _campaign_manager()
	var gs := get_node_or_null("/root/GameState")
	var restored := (
		cm != null
		and gs != null
		and not _retry_campaign_state.is_empty()
		and gs.has_method("restore_history")
		and bool(gs.call("restore_history", 0))
		and cm.has_method("restore_retry_branch")
		and bool(cm.call("restore_retry_branch", _retry_campaign_state, _retry_node_id))
	)
	_release_modal_lock()
	if restored and bool(cm.call("route_retry_to_prep")):
		return
	_save_status_label.text = "Retry failed; the saved victory is unchanged."
	_acquire_modal_lock()


func _allows(action_id: String) -> bool:
	var gs := get_node_or_null("/root/GameState")
	var rules: Variant = gs.get("campaign_rules") if gs != null else null
	return (
		rules == null
		or not rules.has_method("allows_battle_result_action")
		or bool(rules.call("allows_battle_result_action", "victory", action_id))
	)


func _apply_action_policy() -> void:
	_continue_button.visible = _allows("continue")
	_retry_button.visible = _allows("retry")
	_save_button.visible = _allows("save") and _campaign_manager() != null
	_quit_button.visible = _allows("quit")


func _campaign_manager() -> Node:
	var cm := get_node_or_null("/root/CampaignManager")
	if cm == null or not bool(cm.call("is_campaign_active")):
		return null
	return cm


func _acquire_modal_lock() -> void:
	if _modal_lock_held:
		return
	var bus := get_node_or_null("/root/EventBus")
	if bus != null and bus.has_method("acquire_gameplay_modal"):
		bus.call("acquire_gameplay_modal", self)
		_modal_lock_held = true


func _release_modal_lock() -> void:
	if not _modal_lock_held:
		return
	var bus := get_node_or_null("/root/EventBus")
	if bus != null and bus.has_method("release_gameplay_modal"):
		bus.call("release_gameplay_modal", self)
	_modal_lock_held = false


func _exit_tree() -> void:
	_release_modal_lock()


func _delete_mid_map_slot_after_resolution() -> void:
	if _suspend_deleted_for_result:
		return
	_suspend_deleted_for_result = true
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null and save_manager.has_method("delete_slot"):
		save_manager.call("delete_slot", "resume_battle")


# Suppress the directional step in _input (BEFORE the GUI focus-nav phase) so the
# engine does not also move focus; _process then drives the single tuned repeat.
func _input(event: InputEvent) -> void:
	if visible and _focus_nav.consume_direction(event):
		get_viewport().set_input_as_handled()


func _unhandled_input(_event: InputEvent) -> void:
	if visible:
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if visible:
		_focus_nav.poll(delta)


func _quit_to_menu() -> void:
	_release_modal_lock()
	# Match GameOverScreen._on_quit(): leaving the map abandons the run, so end the
	# campaign too — otherwise the dead campaign lingers active in memory at the
	# menu (V053-09). Mostly moot once V053-01 keeps this exit off the happy path.
	var cm := get_node_or_null("/root/CampaignManager")
	if cm and cm.has_method("end_campaign"):
		cm.call("end_campaign")
	var gs := get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("reset_map_state"):
		gs.call("reset_map_state")
	get_tree().change_scene_to_file("res://scenes/core/Boot.tscn")
