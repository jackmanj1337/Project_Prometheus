extends Control
# Full-screen overlay for victory and defeat results.
# Triggered by EventBus.map_victory and EventBus.map_defeat. M16 stage 4 added
# EventBus.map_resolved which carries the full per-group standings; this
# screen renders the ranked list under the blue-perspective Victory/Defeat
# header. Today's victory/defeat handlers stay as fallbacks for callers that
# emit one of those without map_resolved (none in-tree, but headless tests
# exercise both paths independently).

@onready var _title: Label = $Panel/VBox/Title
@onready var _standings_label: Label = $Panel/VBox/Standings
@onready var _retry_btn: Button = $Panel/VBox/RetryButton
@onready var _quit_btn: Button = $Panel/VBox/QuitButton


func _ready() -> void:
	hide()
	_retry_btn.pressed.connect(_on_retry)
	_quit_btn.pressed.connect(_on_quit)
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.map_victory.connect(_on_victory)
		bus.map_defeat.connect(_on_defeat)
		bus.map_resolved.connect(_on_map_resolved)


func _on_victory() -> void:
	_title.text = "Victory!"
	_show_overlay()


func _on_defeat() -> void:
	_title.text = "Defeat..."
	_show_overlay()


# M16 stage 4: paint the ranked standings under the title. Receives the same
# winner / standings the TurnManager evaluator built (Decision 8).
func _on_map_resolved(winner_group: String, standings: Array) -> void:
	# The header is set by the matching map_victory / map_defeat call which fires
	# right before this one — overwrite only when we have a clearer state to show.
	if winner_group == "":
		_title.text = "Draw"
	_standings_label.text = _format_standings(winner_group, standings)


# Renders the standings as "N. <group label> [— turn X]" lines. The blue group
# gets a trailing "(you)" hint so the player can scan their placement at a glance.
func _format_standings(winner_group: String, standings: Array) -> String:
	if standings.is_empty():
		return ""
	var lines: Array[String] = []
	if winner_group == "":
		lines.append("Draw — all groups eliminated")
	for entry in standings:
		var rank: int = entry.get("rank", 0)
		var group: String = entry.get("group", "")
		var elim: int = entry.get("eliminated_round", -1)
		var blue: bool = entry.get("is_blue_group", false)
		var label: String = "%d. %s" % [rank, group.capitalize()]
		if elim >= 0:
			label += " — eliminated turn %d" % elim
		if blue:
			label += " (you)"
		lines.append(label)
	return "\n".join(lines)


func _show_overlay() -> void:
	show()
	_retry_btn.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	# Block all input while the overlay is up
	get_viewport().set_input_as_handled()


func _on_retry() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs and gs.has_method("restore_map_snapshot"):
		gs.restore_map_snapshot()
	get_tree().reload_current_scene()


func _on_quit() -> void:
	# Return to Boot/MainMenu — Boot re-routes to MainMenu in non-dev builds
	get_tree().change_scene_to_file("res://scenes/core/Boot.tscn")
