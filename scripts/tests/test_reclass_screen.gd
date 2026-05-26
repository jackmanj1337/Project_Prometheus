extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_reclass_screen.gd
# Covers the ReclassScreen modal: it should list legal reclass options and only
# consume a Second Seal after a confirmed valid class change.


func _init() -> void:
	print("=== ReclassScreen Test ===")
	var passed := 0
	var failed := 0

	var bus: Node = load("res://scripts/autoloads/EventBus.gd").new()
	bus.name = "EventBus"
	root.add_child(bus)
	var dm: Node = load("res://scripts/autoloads/DataManager.gd").new()
	dm.name = "DataManager"
	root.add_child(dm)
	var item_handler: Node = load("res://scripts/items/ItemHandler.gd").new()
	item_handler.name = "ItemHandler"
	root.add_child(item_handler)
	await process_frame

	var packed := load("res://scenes/ui/ReclassScreen.tscn")
	if packed == null:
		print("FAIL could not load ReclassScreen.tscn")
		quit(1)
		return
	var screen: Control = packed.instantiate()
	root.add_child(screen)
	await process_frame

	var watcher := _make_signal_watcher()
	root.add_child(watcher)
	bus.reclass_started.connect(Callable(watcher, "on_started"))
	bus.reclass_finished.connect(Callable(watcher, "on_finished"))

	var unit := _make_unit()
	var seal := InventoryEntry.make_item("second_seal", 1)
	unit.data.inventory.append(seal)
	root.add_child(unit)
	await process_frame

	screen.open_for(unit, seal, Callable(watcher, "on_completed"))
	await process_frame
	var options_scroll: ScrollContainer = screen.get_node("Panel/VBox/OptionsScroll")
	var options: VBoxContainer = screen.get_node("Panel/VBox/OptionsScroll/Options")
	if screen.visible and options.get_child_count() == 2:
		print("OK  reclass screen opens and lists the legal options")
		passed += 1
	else:
		print("FAIL reclass options: visible=%s count=%d" % [screen.visible, options.get_child_count()])
		failed += 1
	if options_scroll.custom_minimum_size.y >= 0:
		print("OK  reclass options live inside a scroll container")
		passed += 1
	else:
		print("FAIL reclass options missing scroll container")
		failed += 1

	var first_button: Button = options.get_child(0)
	var first_text: String = first_button.text
	first_button.pressed.emit()
	await process_frame
	if not screen.visible and watcher.completed and unit.reclass_target == "knight" \
			and unit.reclass_line == "knight" and unit.data.inventory.is_empty() \
			and watcher.started == 1 and watcher.finished == 1 \
			and "No promotion bonuses gained" in first_text:
		print("OK  confirming a reclass consumes the seal and closes the modal")
		passed += 1
	else:
		print("FAIL reclass confirm: visible=%s completed=%s target=%s line=%s inv=%d started=%d finished=%d text=%s" % [
			screen.visible, watcher.completed, unit.reclass_target, unit.reclass_line,
			unit.data.inventory.size(), watcher.started, watcher.finished, first_text])
		failed += 1

	screen.queue_free()
	unit.queue_free()
	watcher.queue_free()
	item_handler.queue_free()
	dm.queue_free()
	bus.queue_free()

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _make_unit() -> Node:
	var stub := GDScript.new()
	stub.source_code = """
extends Node
var data: UnitData = UnitData.new()
var reclass_target: String = ""
var reclass_line: String = ""
func get_second_seal_options() -> Array[Dictionary]:
	return [
		{"class_id": "knight", "class_line_id": "knight", "label": "Knight", "target_tier": 1, "is_self_reset": false, "note": "Demote"},
		{"class_id": "archer", "class_line_id": "archer", "label": "Archer", "target_tier": 1, "is_self_reset": false, "note": "Demote"},
	]
func reclass(target_class_id: String, target_line_id: String = "") -> bool:
	reclass_target = target_class_id
	reclass_line = target_line_id
	data.class_id = target_class_id
	data.class_line_id = target_line_id
	data.level = 1
	data.exp = 0
	return true
"""
	stub.reload()
	var unit: Node = stub.new()
	unit.data.unit_name = "Seal User"
	unit.data.class_id = "paladin"
	unit.data.class_line_id = "cavalier"
	unit.data.level = 9
	return unit


func _make_signal_watcher() -> Node:
	var stub := GDScript.new()
	stub.source_code = """
extends Node
var started: int = 0
var finished: int = 0
var completed: bool = false
func on_started() -> void:
	started += 1
func on_finished() -> void:
	finished += 1
func on_completed() -> void:
	completed = true
"""
	stub.reload()
	return stub.new()
