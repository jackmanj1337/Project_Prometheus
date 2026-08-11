extends SceneTree
## Headless contract for the Unit AnimatedSprite2D seam and fallback behavior.


func _init() -> void:
	print("=== Unit Animated Sprite Test ===")
	var passed := 0
	var failed := 0
	var packed: PackedScene = load("res://scenes/units/Unit.tscn")
	var unit: Unit = packed.instantiate()
	root.add_child(unit)
	await process_frame

	var sprite := unit.get_node_or_null("Sprite2D") as AnimatedSprite2D
	if sprite != null and sprite.sprite_frames.has_animation(&"default"):
		print("OK  Unit scene uses AnimatedSprite2D with a placeholder animation")
		passed += 1
	else:
		print("FAIL Unit sprite node or placeholder animation")
		failed += 1

	var custom := SpriteFrames.new()
	custom.remove_animation(&"default")
	custom.add_animation(&"walk")
	unit.set_sprite_frames(custom, &"idle")
	if sprite.sprite_frames == custom and sprite.animation == &"walk":
		print("OK  missing preferred/default animation falls back deterministically")
		passed += 1
	else:
		print("FAIL deterministic animation fallback")
		failed += 1

	var before := sprite.sprite_frames
	unit.set_sprite_frames(null)
	if sprite.sprite_frames == before:
		print("OK  unresolved sprite frames preserve the current placeholder")
		passed += 1
	else:
		print("FAIL unresolved frames replaced the placeholder")
		failed += 1

	var dm := root.get_node_or_null("DataManager")
	var class_data: ClassData = dm.get_class_data("knight") if dm != null else null
	var old_sprite_id := class_data.sprite_id if class_data != null else ""
	if class_data != null:
		class_data.sprite_id = "knight_map_sprite"
	var data := UnitData.new()
	data.class_id = "knight"
	unit.data = data
	if unit.class_sprite_id() == "knight_map_sprite":
		print("OK  sprite identity resolves through UnitData.class_id to ClassData.sprite_id")
		passed += 1
	else:
		print("FAIL class-keyed sprite identity: %s" % unit.class_sprite_id())
		failed += 1
	if class_data != null:
		class_data.sprite_id = old_sprite_id

	unit.queue_free()
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)
