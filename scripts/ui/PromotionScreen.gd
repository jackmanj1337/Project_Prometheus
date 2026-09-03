extends "res://scripts/ui/ModalScreen.gd"
# Modal promotion picker. Used both by auto-promotion at class cap and by
# promotion items (Master Seal, class-restricted seals, etc.).

const StatRegistry = preload("res://scripts/core/StatRegistry.gd")

@onready var _label_title: Label = $Panel/VBox/TitleLabel
@onready var _label_unit: Label = $Panel/VBox/LabelUnit
@onready var _label_hint: Label = $Panel/VBox/LabelHint
@onready var _options_scroll: ScrollContainer = $Panel/VBox/OptionsScroll
@onready var _options: VBoxContainer = $Panel/VBox/OptionsScroll/Options
@onready var _btn_cancel: Button = $Panel/VBox/BtnCancel

var _unit: Node = null
var _consume_entry: InventoryEntry = null
var _on_complete: Callable = Callable()
var _on_cancel: Callable = Callable()
var _confirmed: bool = false
var _buttons: Array[Button] = []
var _level_up_active: bool = false
var _queued_unit: Node = null


func _ready() -> void:
	super._ready()
	_btn_cancel.pressed.connect(_close)
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.promotion_available.connect(_on_promotion_available)
		bus.level_up_started.connect(func(): _level_up_active = true)
		bus.level_up_finished.connect(_on_level_up_finished)


func open_for(
	unit: Node,
	consume_entry: InventoryEntry = null,
	on_complete: Callable = Callable(),
	on_cancel: Callable = Callable()
) -> void:
	if unit == null or not is_instance_valid(unit) or unit.data == null:
		return
	_unit = unit
	_consume_entry = consume_entry
	_on_complete = on_complete
	_on_cancel = on_cancel
	_confirmed = false
	_rebuild_options()
	if _buttons.is_empty():
		return
	_emit_promotion_started()
	show()
	# Re-apply the scale AFTER the options are built: ModalScreen._ready() scaled and
	# clamped an empty Options box, so without this the freshly-built (and now taller)
	# panel is never re-clamped/recentred and clips top+bottom at high scale (V025-05c).
	# The Options ScrollContainer keeps the panel a fixed frame that scrolls instead.
	_apply_menu_scale_from_settings()
	_options_scroll.scroll_vertical = 0
	_buttons[0].grab_focus()


func _rebuild_options() -> void:
	for btn in _buttons:
		btn.queue_free()
	_buttons.clear()
	if _unit == null or _unit.data == null:
		return
	var current_class := _class_data(_unit.data.class_id)
	if current_class == null:
		return
	_label_title.text = "Promotion"
	_label_unit.text = (
		"%s  Lv %d %s" % [_unit.data.unit_name, _unit.data.level, current_class.display_name]
	)
	_label_hint.text = "Choose a promoted class"
	for target_id in current_class.promotes_to:
		var target_class := _class_data(String(target_id))
		if target_class == null:
			continue
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_ALL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		# Wrap the long stat-preview line within the panel width instead of forcing
		# the panel wider than the screen (playtest v0.1.4 #5 — promotion modal ran
		# off the right edge). The panel is centered + width-capped in the scene; the
		# buttons must be allowed to shrink/wrap so they don't push past that cap.
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.text = _button_text(target_class)
		_options.add_child(btn)
		btn.pressed.connect(func(): _commit_promotion(target_class.id))
		_buttons.append(btn)


func _button_text(target_class: ClassData) -> String:
	var skill_names: Array[String] = []
	for unlock_level in [5, 15]:
		if target_class.skill_unlocks.has(unlock_level):
			var skill_name := _skill_name(String(target_class.skill_unlocks[unlock_level]))
			if skill_name != "":
				skill_names.append(skill_name)
	var skills_text: String = (
		"Skills: %s" % " / ".join(skill_names) if not skill_names.is_empty() else "Skills: none"
	)
	return (
		"%s\n%s\n%s"
		% [
			target_class.display_name,
			_promotion_preview_text(target_class),
			skills_text,
		]
	)


func _commit_promotion(target_class_id: String) -> void:
	if _unit == null or not is_instance_valid(_unit):
		_close()
		return
	# The screen collects the choice; ProgressionCoordinator commits the class
	# change and the seal together, so neither can land without the other.
	var coordinator := get_node_or_null("/root/ProgressionCoordinator")
	if coordinator == null:
		push_error("PromotionScreen cannot promote without /root/ProgressionCoordinator")
		return
	var outcome: Dictionary = coordinator.commit_promotion(_unit, target_class_id, _consume_entry)
	if not outcome.get("ok", false):
		push_warning("PromotionScreen: promotion refused (%s)" % String(outcome.get("code", "")))
		return
	_confirmed = true
	if _on_complete.is_valid():
		_on_complete.call()
	_close()


func _on_promotion_available(unit: Node) -> void:
	if visible or unit == null or not is_instance_valid(unit):
		return
	if _level_up_active:
		_queued_unit = unit
		return
	open_for(unit)


func _on_level_up_finished() -> void:
	_level_up_active = false
	if _queued_unit == null or visible:
		return
	var queued := _queued_unit
	_queued_unit = null
	if is_instance_valid(queued):
		open_for(queued)


func _close() -> void:
	if not _confirmed and _on_cancel.is_valid():
		_on_cancel.call()
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.promotion_finished.emit()
	super._close()


func _emit_promotion_started() -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.promotion_started.emit()


func _class_data(class_id: String) -> ClassData:
	var dm := get_node_or_null("/root/DataManager")
	return dm.get_class_data(class_id) if dm != null else null


func _skill_name(skill_id: String) -> String:
	var dm := get_node_or_null("/root/DataManager")
	if dm != null:
		if (
			dm.has_method("is_skill_release_available")
			and not bool(dm.call("is_skill_release_available", skill_id))
		):
			return ""
		var skill: SkillData = dm.get_skill(skill_id)
		if skill != null:
			return skill.display_name
	return skill_id


func _stat_short_name(stat: String) -> String:
	# Delegates to the single StatRegistry label vocabulary (was a local match copy).
	return StatRegistry.label_for(stat)


func _promotion_preview_text(target_class: ClassData) -> String:
	if _unit == null or _unit.data == null:
		return "Stats: unavailable"
	var parts: Array[String] = []
	for stat_name in ClassData.STAT_KEYS:
		var old_value: int = (
			int(_unit.data.max_hp) if stat_name == "hp" else int(_unit.data.get(stat_name))
		)
		var bonus: int = int(target_class.promotion_stat_bonuses.get(stat_name, 0))
		var new_value: int = old_value + bonus
		var cap: int = int(target_class.stat_caps.get(stat_name, -1))
		if cap >= 0:
			new_value = mini(new_value, cap)
		parts.append(
			(
				"%s %d %+d -> %d / %s"
				% [
					_stat_short_name(stat_name),
					old_value,
					bonus,
					new_value,
					str(cap) if cap >= 0 else "-"
				]
			)
		)
	return "Stats: %s" % " | ".join(parts)
