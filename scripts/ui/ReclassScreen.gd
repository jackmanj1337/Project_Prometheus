extends "res://scripts/ui/ModalScreen.gd"
# Modal Second Seal picker. Shows every legal result from Unit.get_second_seal_options()
# and only consumes the item after a confirmed, successful reclass.

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


func _ready() -> void:
	super._ready()
	_btn_cancel.pressed.connect(_close)


func open_for(unit: Node, consume_entry: InventoryEntry = null,
		on_complete: Callable = Callable(), on_cancel: Callable = Callable()) -> void:
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
	_emit_reclass_started()
	show()
	_options_scroll.scroll_vertical = 0
	_buttons[0].grab_focus()


func _rebuild_options() -> void:
	for btn in _buttons:
		btn.queue_free()
	_buttons.clear()
	if _unit == null or _unit.data == null or not _unit.has_method("get_second_seal_options"):
		return
	var current_class := _class_data(_unit.data.class_id)
	if current_class == null:
		return
	_label_title.text = "Second Seal"
	_label_unit.text = "%s  Lv %d %s" % [
		_unit.data.unit_name, _unit.data.level, current_class.display_name]
	_label_hint.text = "Choose a new class or reset this one"
	for option in _unit.get_second_seal_options():
		var target_class := _class_data(String(option["class_id"]))
		if target_class == null:
			continue
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_ALL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.text = _button_text(target_class, option)
		_options.add_child(btn)
		var captured_option: Dictionary = option
		btn.pressed.connect(func(): _commit_reclass(captured_option))
		_buttons.append(btn)


func _button_text(target_class: ClassData, option: Dictionary) -> String:
	var weapon_text: String = ", ".join(target_class.get_allowed_weapon_families()) \
		if not target_class.get_allowed_weapon_families().is_empty() else "none"
	var skill_lines: Array[String] = []
	var unlock_levels: Array = target_class.skill_unlocks.keys()
	unlock_levels.sort()
	for unlock_level in unlock_levels:
		skill_lines.append("Lv %s %s" % [str(unlock_level), _skill_name(String(target_class.skill_unlocks[unlock_level]))])
	var skills_text: String = ", ".join(skill_lines) if not skill_lines.is_empty() else "none"
	var summary: String = "Reset to Lv 1" if bool(option.get("is_self_reset", false)) else "No promotion bonuses gained"
	return "%s\n%s | Tier %d | Weapons: %s\nSkills: %s\n%s" % [
		String(option.get("label", target_class.display_name)),
		String(option.get("note", "Reclass")),
		target_class.tier,
		weapon_text,
		skills_text,
		summary,
	]


func _commit_reclass(option: Dictionary) -> void:
	if _unit == null or not is_instance_valid(_unit):
		_close()
		return
	if not _unit.reclass(String(option["class_id"]), String(option["class_line_id"])):
		return
	var ih := get_node_or_null("/root/ItemHandler")
	if ih != null and _consume_entry != null:
		ih.consume_entry(_unit, _consume_entry)
	_confirmed = true
	if _on_complete.is_valid():
		_on_complete.call()
	_close()


func _close() -> void:
	if not _confirmed and _on_cancel.is_valid():
		_on_cancel.call()
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.reclass_finished.emit()
	super._close()


func _emit_reclass_started() -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.reclass_started.emit()


func _class_data(class_id: String) -> ClassData:
	var dm := get_node_or_null("/root/DataManager")
	return dm.get_class_data(class_id) if dm != null else null


func _skill_name(skill_id: String) -> String:
	var dm := get_node_or_null("/root/DataManager")
	if dm != null:
		var skill: SkillData = dm.get_skill(skill_id)
		if skill != null:
			return skill.display_name
	return skill_id
