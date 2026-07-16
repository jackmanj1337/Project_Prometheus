extends "res://scripts/ui/ModalScreen.gd"
# Modal Second Seal picker. Shows every legal result from Unit.get_second_seal_options()
# and only consumes the item after a confirmed, successful reclass.

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


func _ready() -> void:
	super._ready()
	_btn_cancel.pressed.connect(_close)


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
	_emit_reclass_started()
	show()
	# Re-apply scale after the options are built (same reason as PromotionScreen /
	# V025-05c): _ready() scaled an empty Options box. The ScrollContainer keeps the
	# panel a fixed frame, so this just re-centres it against real content.
	_apply_menu_scale_from_settings()
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
	_label_unit.text = (
		"%s  Lv %d %s" % [_unit.data.unit_name, _unit.data.level, current_class.display_name]
	)
	_label_hint.text = "Choose a new class or reset this one"
	for option in _unit.get_second_seal_options():
		var target_class := _class_data(String(option["class_id"]))
		if target_class == null:
			continue
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_ALL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		# Wrap the long per-stat `old +Δ -> new / cap` line within the panel width
		# instead of letting it overflow into a horizontal scrollbar (playtest
		# v0.1.5.0 #8.6 — the reclass option lines forced a horizontal scroll). The
		# OptionsScroll's horizontal scroll is disabled in the scene, so each button
		# is width-capped to the panel and autowrap takes effect — mirroring the
		# PromotionScreen fix (playtest v0.1.4 #5).
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.text = _button_text(target_class, option)
		_options.add_child(btn)
		var captured_option: Dictionary = option
		btn.pressed.connect(func(): _commit_reclass(captured_option))
		_buttons.append(btn)


func _button_text(target_class: ClassData, option: Dictionary) -> String:
	var weapon_text: String = (
		", ".join(target_class.get_allowed_weapon_families())
		if not target_class.get_allowed_weapon_families().is_empty()
		else "none"
	)
	var skill_lines: Array[String] = []
	var unlock_levels: Array = target_class.skill_unlocks.keys()
	unlock_levels.sort()
	for unlock_level in unlock_levels:
		var skill_name := _skill_name(String(target_class.skill_unlocks[unlock_level]))
		if skill_name != "":
			skill_lines.append("Lv %s %s" % [str(unlock_level), skill_name])
	var skills_text: String = ", ".join(skill_lines) if not skill_lines.is_empty() else "none"
	var summary: String = (
		"Reset to Lv 1"
		if bool(option.get("is_self_reset", false))
		else "No promotion bonuses gained"
	)
	return (
		"%s\n%s | Tier %d | Weapons: %s\n%s\nSkills: %s\n%s"
		% [
			String(option.get("label", target_class.display_name)),
			String(option.get("note", "Reclass")),
			target_class.tier,
			weapon_text,
			_reclass_preview_text(target_class, option),
			skills_text,
			summary,
		]
	)


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
		if (
			dm.has_method("is_skill_release_available")
			and not bool(dm.call("is_skill_release_available", skill_id))
		):
			return ""
		var skill: SkillData = dm.get_skill(skill_id)
		if skill != null:
			return skill.display_name
	return skill_id


func _reclass_preview_text(target_class: ClassData, option: Dictionary) -> String:
	if _unit == null or _unit.data == null:
		return "Stats: unavailable"
	var source_class := _class_data(_unit.data.class_id)
	if source_class == null:
		return "Stats: unavailable"
	var source_line := _line_base_class(source_class, _unit.data.class_line_id)
	var target_line := _line_base_class(
		target_class, String(option.get("class_line_id", target_class.id))
	)
	if source_line == null or target_line == null:
		return "Stats: unavailable"
	var is_self_reset: bool = bool(option.get("is_self_reset", false))
	var parts: Array[String] = []
	for stat_name in ClassData.STAT_KEYS:
		var old_value: int = (
			int(_unit.data.max_hp) if stat_name == "hp" else int(_unit.data.get(stat_name))
		)
		var new_value: int = old_value
		if not is_self_reset:
			if source_class.tier == 2:
				new_value -= int(source_class.promotion_stat_bonuses.get(stat_name, 0))
			new_value += (
				_base_stat_for(target_line, stat_name) - _base_stat_for(source_line, stat_name)
			)
			if stat_name == "hp":
				new_value = max(1, new_value)
			else:
				new_value = max(0, new_value)
			new_value = _clamp_preview_to_cap(new_value, target_class, stat_name)
		var delta: int = new_value - old_value
		var cap: int = int(target_class.stat_caps.get(stat_name, -1))
		var cap_text: String = str(cap) if cap >= 0 else "-"
		parts.append(
			(
				"%s %d %+d -> %d / %s"
				% [_stat_short_name(stat_name), old_value, delta, new_value, cap_text]
			)
		)
	return "Stats: %s" % " | ".join(parts)


func _line_base_class(class_data: ClassData, line_id: String) -> ClassData:
	if class_data == null:
		return null
	if class_data.tier == 1:
		return class_data
	return _class_data(line_id)


func _base_stat_for(class_data: ClassData, stat_name: String) -> int:
	if class_data == null:
		return 0
	match stat_name:
		"hp":
			return class_data.base_hp
		"strength":
			return class_data.base_strength
		"magic":
			return class_data.base_magic
		"defense":
			return class_data.base_defense
		"resistance":
			return class_data.base_resistance
		"skill":
			return class_data.base_skill
		"speed":
			return class_data.base_speed
		"luck":
			return class_data.base_luck
	return 0


func _clamp_preview_to_cap(value: int, target_class: ClassData, stat_name: String) -> int:
	var cap: int = int(target_class.stat_caps.get(stat_name, -1))
	return mini(value, cap) if cap >= 0 else value


func _stat_short_name(stat: String) -> String:
	# Delegates to the single StatRegistry label vocabulary (was a local match copy).
	return StatRegistry.label_for(stat)
