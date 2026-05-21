class_name LevelUpScreen extends Control
# Shown when a player unit levels up. Queues multiple level-ups and shows them
# one at a time; player presses confirm to advance. Blocks all input while open.

# Renders the live confirm keybinding for the "press X to continue" prompt (#13).
const InputDisplay = preload("res://scripts/shared/InputDisplay.gd")

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


func _on_unit_leveled_up(unit: Node, stat_increases: Dictionary, learned_skills: Array) -> void:
	# Only show level-up screen for the player's faction; other factions are silent.
	# M14 stage 5 will broaden this to "the active controlling faction" once a
	# non-blue hotseat phase exists; for stage 1 the blue/player binding holds.
	if not ("team" in unit) or unit.team != "blue":
		return
	var sm := get_node_or_null("/root/SettingsManager")
	if sm and sm.level_up_screen == "skip":
		return
	_queue.append({"unit": unit, "increases": stat_increases, "learned": learned_skills})
	if not visible:
		# First level-up of this batch — tell MapCursor to freeze input so the
		# cursor can't be driven underneath the screen (#12).
		var bus := get_node_or_null("/root/EventBus")
		if bus:
			bus.level_up_started.emit()
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
	# Show the real confirm keybinding rather than a hardcoded "A" (#13). Falls
	# back to "confirm" if no key is bound (e.g. only a mouse button).
	var confirm_key: String = InputDisplay.first_key_for_action("confirm")
	if confirm_key == "":
		confirm_key = "confirm"
	_label_prompt.text = "" if is_auto else "Press %s to continue" % confirm_key
	show()

	if is_auto:
		# SceneTreeTimer outlives nodes — guard against freed self on scene change.
		get_tree().create_timer(1.5).timeout.connect(func():
			if not is_instance_valid(self): return
			_advance()
		, CONNECT_ONE_SHOT)


# Dismiss the current panel, then show the next queued level-up — or, when the
# queue is empty, stay closed and let MapCursor resume input (#12).
func _advance() -> void:
	hide()
	_show_next()
	if not visible:
		var bus := get_node_or_null("/root/EventBus")
		if bus:
			bus.level_up_finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var sm := get_node_or_null("/root/SettingsManager")
	if sm and sm.level_up_screen == "auto":
		return  # timer handles dismissal; player input ignored in auto mode
	# A click anywhere also dismisses (playtest 3 #2). Without this a mouse-only
	# player is stuck on the panel — the keyboard confirm path was the only exit.
	var clicked: bool = event is InputEventMouseButton and event.pressed
	if event.is_action_pressed("confirm") or event.is_action_pressed("cancel") or clicked:
		get_viewport().set_input_as_handled()
		_advance()
