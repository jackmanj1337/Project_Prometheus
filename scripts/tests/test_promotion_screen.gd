extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_promotion_screen.gd
# Covers the PromotionScreen modal: it should list promotion targets, consume a
# promotion item on confirm, and defer auto-promotion prompts until the level-up
# screen finishes.


func _init() -> void:
	print("=== PromotionScreen Test ===")
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

	var packed := load("res://scenes/ui/PromotionScreen.tscn")
	if packed == null:
		print("FAIL could not load PromotionScreen.tscn")
		quit(1)
		return
	var screen: Control = packed.instantiate()
	root.add_child(screen)
	await process_frame

	var signal_watcher := _make_signal_watcher()
	root.add_child(signal_watcher)
	bus.promotion_started.connect(Callable(signal_watcher, "on_started"))
	bus.promotion_finished.connect(Callable(signal_watcher, "on_finished"))

	var unit := _make_unit("Test Cav", "cavalier")
	var seal := InventoryEntry.make_item("master_seal", 1)
	unit.data.inventory.append(seal)
	root.add_child(unit)
	await process_frame

	screen.open_for(unit, seal, Callable(signal_watcher, "on_completed"))
	await process_frame
	var options: VBoxContainer = screen.get_node("Panel/VBox/Options")
	if screen.visible and options.get_child_count() == 2:
		print("OK  promotion screen opens and lists the current class targets")
		passed += 1
	else:
		print("FAIL promotion options: visible=%s count=%d" % [
			screen.visible, options.get_child_count()])
		failed += 1

	var first_button: Button = options.get_child(0)
	var first_label: String = first_button.text
	first_button.pressed.emit()
	await process_frame
	if not screen.visible and signal_watcher.completed and unit.promoted_to == "paladin" \
			and unit.data.inventory.is_empty() and signal_watcher.started == 1 \
			and signal_watcher.finished == 1 and "Paladin" in first_label:
		print("OK  confirming a promotion promotes the unit, consumes the seal, and closes")
		passed += 1
	else:
		print("FAIL confirm promotion: visible=%s done=%s target=%s inv=%d started=%d finished=%d text=%s" % [
			screen.visible, signal_watcher.completed, unit.promoted_to, unit.data.inventory.size(),
			signal_watcher.started, signal_watcher.finished, first_label])
		failed += 1

	var queued_unit := _make_unit("Queue Mage", "mage")
	root.add_child(queued_unit)
	await process_frame
	bus.level_up_started.emit()
	bus.promotion_available.emit(queued_unit)
	await process_frame
	var hidden_while_leveling := not screen.visible
	bus.level_up_finished.emit()
	await process_frame
	if hidden_while_leveling and screen.visible and screen.get_node("Panel/VBox/LabelUnit").text.contains("Queue Mage"):
		print("OK  promotion_available waits for level-up to finish before opening")
		passed += 1
	else:
		print("FAIL queued promotion: hidden=%s visible=%s label=%s" % [
			hidden_while_leveling, screen.visible,
			screen.get_node("Panel/VBox/LabelUnit").text])
		failed += 1

	screen.get_node("Panel/VBox/BtnCancel").pressed.emit()
	await process_frame

	screen.queue_free()
	unit.queue_free()
	queued_unit.queue_free()
	signal_watcher.queue_free()
	item_handler.queue_free()
	dm.queue_free()
	bus.queue_free()

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _make_unit(unit_name: String, class_id: String) -> Node:
	var stub := GDScript.new()
	stub.source_code = """
extends Node
var data: UnitData = UnitData.new()
var promoted_to: String = ""
func promote(target_class_id: String) -> bool:
	promoted_to = target_class_id
	data.class_id = target_class_id
	data.is_promoted = true
	data.level = 1
	data.exp = 0
	return true
"""
	stub.reload()
	var unit: Node = stub.new()
	unit.data.unit_name = unit_name
	unit.data.class_id = class_id
	unit.data.level = 10
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
