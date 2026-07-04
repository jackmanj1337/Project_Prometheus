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
	var options: VBoxContainer = screen.get_node("Panel/VBox/OptionsScroll/Options")
	if screen.visible and options.get_child_count() == 2:
		print("OK  promotion screen opens and lists the current class targets")
		passed += 1
	else:
		print("FAIL promotion options: visible=%s count=%d" % [
			screen.visible, options.get_child_count()])
		failed += 1

	# Promotion modal must stay on-screen and centered (playtest v0.1.4 #5: it ran
	# off the right edge because the panel was left-pinned with fixed offsets and the
	# long stat rows forced it wider than the screen). Now centered + width-capped
	# with autowrapping option labels.
	await process_frame
	var panel: Control = screen.get_node("Panel")
	var view_w: float = screen.get_viewport().get_visible_rect().size.x
	var left_margin: float = panel.position.x
	var right_margin: float = view_w - (panel.position.x + panel.size.x)
	var on_screen: bool = left_margin >= -1.0 and right_margin >= -1.0
	var centered: bool = absf(left_margin - right_margin) <= 2.0
	if on_screen and centered:
		print("OK  promotion modal fits on-screen and is horizontally centered"); passed += 1
	else:
		print("FAIL modal bounds: view_w=%.0f panel.x=%.0f panel.w=%.0f left=%.1f right=%.1f" % [
			view_w, panel.position.x, panel.size.x, left_margin, right_margin]); failed += 1

	# V025-05c: at max Menu Scale the picker used to clip top+bottom because _ready()
	# scaled an empty Options box and nothing re-clamped after the buttons were built.
	# With the Options ScrollContainer + re-apply-after-rebuild, the panel must stay
	# within the viewport height at 2.0x (the list scrolls instead of overflowing).
	screen.apply_menu_scale(2.0)
	await process_frame
	await process_frame  # let the fit clamp / recenter settle
	var view_h: float = screen.get_viewport().get_visible_rect().size.y
	var top_margin: float = panel.position.y
	var bottom_margin: float = view_h - (panel.position.y + panel.size.y)
	if top_margin >= -1.0 and bottom_margin >= -1.0:
		print("OK  promotion modal fits the viewport height at 2.0x (V025-05c)"); passed += 1
	else:
		print("FAIL 2.0x vertical fit: view_h=%.0f panel.y=%.0f panel.h=%.0f top=%.1f bottom=%.1f" % [
			view_h, panel.position.y, panel.size.y, top_margin, bottom_margin]); failed += 1
	screen.apply_menu_scale(1.0)
	await process_frame

	var first_button: Button = options.get_child(0)
	var first_label: String = first_button.text
	first_button.pressed.emit()
	await process_frame
	if not screen.visible and signal_watcher.completed and unit.promoted_to == "paladin" \
			and unit.data.inventory.is_empty() and signal_watcher.started == 1 \
			and signal_watcher.finished == 1 and "Paladin" in first_label \
			and "Str 8 +3 -> 11 / 42" in first_label \
			and "HP 18 +7 -> 25 / 80" in first_label:
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
	unit.data.hp = 18
	unit.data.max_hp = 18
	unit.data.strength = 8
	unit.data.magic = 0
	unit.data.defense = 6
	unit.data.resistance = 3
	unit.data.skill = 7
	unit.data.speed = 7
	unit.data.luck = 5
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
