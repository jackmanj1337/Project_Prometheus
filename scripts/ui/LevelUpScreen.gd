class_name LevelUpScreen extends Control
# Shown when a player unit levels up. Queues multiple level-ups and shows them
# one at a time; player presses confirm to advance. Blocks all input while open.

# Renders the live confirm keybinding for the "press X to continue" prompt (#13).
const InputDisplay = preload("res://scripts/shared/InputDisplay.gd")

@onready var _label_name:   Label = $Panel/VBox/LabelName
@onready var _label_level:  Label = $Panel/VBox/LabelLevel
@onready var _label_stats:  Label = $Panel/VBox/LabelStats
@onready var _label_prompt: Label = $Panel/VBox/LabelPrompt
@onready var _panel: Panel = $Panel

# Human-readable names for each growth stat (matches Unit._GROWTH_STATS order)
const _STAT_NAMES: Dictionary = {
	"hp": "HP", "strength": "Str", "magic": "Mag", "defense": "Def",
	"resistance": "Res", "skill": "Skl", "speed": "Spd", "luck": "Luk",
}
const _SKILL_FULL_SUFFIX := " (skill slots full - equip from battle prep)"
const _PANEL_HALF_WIDTH := 120.0
const _BASE_PANEL_HALF_HEIGHT := 100.0
const _EXTRA_PANEL_LINE_HEIGHT := 18.0

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
	if stats_text == "":
		stats_text = "(No stats increased)\n"
	# Announce any class skills learned at this level (Unit.skill_unlocks grant).
	var learned: Array = item.get("learned", [])
	if not learned.is_empty():
		var dm := get_node_or_null("/root/DataManager")
		for learned_entry in learned:
			var skill_id: String = _learned_skill_id(learned_entry)
			var suffix: String = "" if _learned_skill_equipped(learned_entry) else _SKILL_FULL_SUFFIX
			stats_text += "Learned %s!%s\n" % [_skill_display_name(dm, skill_id), suffix]
	_label_stats.text = stats_text.strip_edges()
	_resize_panel_for_stats(_label_stats.text)

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


func _resize_panel_for_stats(stats_text: String) -> void:
	var line_count: int = maxi(1, stats_text.split("\n").size())
	var extra_lines: int = maxi(0, line_count - 5)
	var half_height: float = _BASE_PANEL_HALF_HEIGHT + (extra_lines * _EXTRA_PANEL_LINE_HEIGHT)
	_panel.offset_left = -_PANEL_HALF_WIDTH
	_panel.offset_right = _PANEL_HALF_WIDTH
	_panel.offset_top = -half_height
	_panel.offset_bottom = half_height


# Resolves a skill id to its display name via DataManager, falling back to the
# raw id if the catalogue or skill is unavailable.
func _skill_display_name(dm: Node, skill_id: String) -> String:
	if dm != null:
		var sk = dm.get_skill(skill_id)
		if sk != null:
			return sk.display_name
	return skill_id


func _learned_skill_id(learned_entry: Variant) -> String:
	if learned_entry is Dictionary:
		return String((learned_entry as Dictionary).get("id", ""))
	return String(learned_entry)


func _learned_skill_equipped(learned_entry: Variant) -> bool:
	if learned_entry is Dictionary:
		return bool((learned_entry as Dictionary).get("equipped", true))
	return true


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
