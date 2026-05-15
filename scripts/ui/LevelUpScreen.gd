class_name LevelUpScreen extends Control
# Shown when a player unit levels up. Queues multiple level-ups and shows them
# one at a time; player presses confirm to advance. Blocks all input while open.

@onready var _label_name:   Label = $Panel/VBox/LabelName
@onready var _label_level:  Label = $Panel/VBox/LabelLevel
@onready var _label_stats:  Label = $Panel/VBox/LabelStats
@onready var _label_prompt: Label = $Panel/VBox/LabelPrompt

# Human-readable names for each growth stat (matches Unit._GROWTH_STATS order)
const _STAT_NAMES: Dictionary = {
	"hp": "HP", "strength": "Str", "magic": "Mag", "defense": "Def",
	"resistance": "Res", "skill": "Skl", "speed": "Spd", "luck": "Luk",
}

var _queue: Array[Dictionary] = []


func _ready() -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.unit_leveled_up.connect(_on_unit_leveled_up)
	hide()


func _on_unit_leveled_up(unit: Node, stat_increases: Dictionary) -> void:
	# Only show level-up screen for player units; enemy level-ups are silent.
	if not ("team" in unit) or unit.team != "player":
		return
	var sm := get_node_or_null("/root/SettingsManager")
	if sm and sm.level_up_screen == "skip":
		return
	_queue.append({"unit": unit, "increases": stat_increases})
	if not visible:
		_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		return
	var item: Dictionary = _queue.pop_front()
	var unit: Node = item["unit"]
	var increases: Dictionary = item["increases"]

	var unit_name: String = unit.data.unit_name if (unit and is_instance_valid(unit) and unit.data) else "???"
	var level: int = unit.data.level if (unit and is_instance_valid(unit) and unit.data) else 0
	_label_name.text = unit_name
	_label_level.text = "Level Up!  Lv %d" % level

	var stats_text := ""
	for stat in increases:
		if increases[stat] > 0:
			stats_text += "%s  +%d\n" % [_STAT_NAMES.get(stat, stat), increases[stat]]
	_label_stats.text = stats_text.strip_edges() if stats_text != "" else "(No stats increased)"

	var sm := get_node_or_null("/root/SettingsManager")
	var is_auto: bool = sm != null and sm.level_up_screen == "auto"
	_label_prompt.text = "" if is_auto else "Press A to continue"
	show()

	if is_auto:
		# SceneTreeTimer outlives nodes — guard against freed self on scene change.
		get_tree().create_timer(1.5).timeout.connect(func():
			if not is_instance_valid(self): return
			hide()
			_show_next()
		, CONNECT_ONE_SHOT)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var sm := get_node_or_null("/root/SettingsManager")
	if sm and sm.level_up_screen == "auto":
		return  # timer handles dismissal; player input ignored in auto mode
	if event.is_action_pressed("confirm") or event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		hide()
		_show_next()
