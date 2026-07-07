class_name LevelUpScreen extends Control
# Shown when a player unit levels up. Queues multiple level-ups and shows them
# one at a time; player presses confirm to advance. Blocks all input while open.

# Renders the live confirm keybinding for the "press X to continue" prompt (#13).
const InputDisplay = preload("res://scripts/shared/InputDisplay.gd")
const MenuScale = preload("res://scripts/ui/MenuScale.gd")

@onready var _label_name:   Label = $Panel/Margin/VBox/LabelName
@onready var _label_level:  Label = $Panel/Margin/VBox/LabelLevel
@onready var _label_stats:  Label = $Panel/Margin/VBox/LabelStats
@onready var _label_prompt: Label = $Panel/Margin/VBox/LabelPrompt
@onready var _panel: PanelContainer = $Panel

# Human-readable names for each growth stat (matches Unit._GROWTH_STATS order)
const _STAT_NAMES: Dictionary = {
	"hp": "HP", "strength": "Str", "magic": "Mag", "defense": "Def",
	"resistance": "Res", "skill": "Skl", "speed": "Spd", "luck": "Luk",
}
const _SKILL_FULL_SUFFIX := " (skill slots full - equip from battle prep)"

var _queue: Array[Dictionary] = []


func _ready() -> void:
	add_to_group(MenuScale.GROUP)
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.unit_leveled_up.connect(_on_unit_leveled_up)
	# Prompt/glyph swapping (B6-INPUT): re-render the "press X to continue" prompt
	# when the input scheme changes while the screen is up.
	var imm := get_node_or_null("/root/InputModeManager")
	if imm != null and imm.has_signal("input_mode_changed"):
		imm.connect("input_mode_changed", _on_input_mode_changed)
	_apply_menu_scale_from_settings()
	hide()


func _on_input_mode_changed(_mode: String) -> void:
	if visible:
		_update_confirm_prompt()


# Renders the dismissal prompt for the active input scheme: blank in auto mode,
# else "Press <key/glyph> to continue" using the live confirm binding (keyboard key
# or brand-correct pad label). Falls back to the word "confirm" if nothing is bound.
func _update_confirm_prompt() -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm != null and sm.level_up_screen == "auto":
		_label_prompt.text = ""
		return
	var confirm_label: String = InputDisplay.live_action_prompt("confirm", self)
	if confirm_label == "":
		confirm_label = "confirm"
	_label_prompt.text = "Press %s to continue" % confirm_label


func apply_menu_scale(factor: float) -> void:
	# Deferred so the first-show sizing runs after the (dynamic) stat label has been
	# laid out — otherwise the panel pins a degenerate narrow/tall frame (V025-05a).
	MenuScale.apply_to_deferred(_panel, factor, true)


func _apply_menu_scale_from_settings() -> void:
	apply_menu_scale(MenuScale.factor_from_settings(self))


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

	var sm := get_node_or_null("/root/SettingsManager")
	var is_auto: bool = sm != null and sm.level_up_screen == "auto"
	# Show the real confirm binding rather than a hardcoded "A" (#13), following the
	# active input scheme (keyboard key or brand-correct pad glyph, B6-INPUT).
	_update_confirm_prompt()
	# Show first so the panel and its labels lay out, THEN scale/recenter (deferred).
	show()
	_apply_menu_scale_from_settings()

	if is_auto:
		# SceneTreeTimer outlives nodes — guard against freed self on scene change.
		get_tree().create_timer(1.5).timeout.connect(func():
			if not is_instance_valid(self): return
			_advance()
		, CONNECT_ONE_SHOT)


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


# Mouse clicks are handled here, not in _unhandled_input: the root is a full-rect
# STOP control, so on desktop the GUI phase delivers (and consumes) mouse buttons
# here before they can reach _unhandled_input — which is why the v0.2.4 click-dismiss
# in _unhandled_input never fired on the real build (V025-05b). The whole Panel
# subtree is mouse_filter=IGNORE in the scene so a click anywhere reaches this root.
func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	var sm := get_node_or_null("/root/SettingsManager")
	if sm and sm.level_up_screen == "auto":
		accept_event()  # timer handles dismissal; swallow clicks in auto mode
		return
	# A primary/back click dismisses (playtest 3 #2), but wheel events are also
	# InputEventMouseButton in Godot. Only real click buttons advance the panel.
	if event is InputEventMouseButton and event.pressed \
			and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		accept_event()
		_advance()


# Keyboard dismissal only — mouse is handled in _gui_input (see note above). The
# blanket set_input_as_handled keeps map key input frozen while the screen is open.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var sm := get_node_or_null("/root/SettingsManager")
	if sm and sm.level_up_screen == "auto":
		get_viewport().set_input_as_handled()
		return  # timer handles dismissal; player input ignored in auto mode
	if event.is_action_pressed("confirm") or event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		_advance()
		return
	get_viewport().set_input_as_handled()
