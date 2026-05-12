extends Control
# Full-screen overlay for victory and defeat results.
# Triggered by EventBus.map_victory and EventBus.map_defeat.

@onready var _title: Label = $Panel/VBox/Title
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


func _on_victory() -> void:
	_title.text = "Victory!"
	_show_overlay()


func _on_defeat() -> void:
	_title.text = "Defeat..."
	_show_overlay()


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
