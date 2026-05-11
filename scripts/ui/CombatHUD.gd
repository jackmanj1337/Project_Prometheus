extends CanvasLayer
# Spawns floating text labels above units when they take damage, are healed,
# or when an attack misses. Labels float upward and fade out over ~0.8 seconds.

func _ready() -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.combat_resolved.connect(_on_combat_resolved)
		bus.unit_healed.connect(_on_unit_healed)


func _on_combat_resolved(_attacker: Node, _defender: Node, result: Dictionary) -> void:
	for exchange in result.get("exchanges", []):
		var def_unit: Node = exchange.get("defender")
		if not is_instance_valid(def_unit):
			continue
		if exchange.get("hit", false):
			var dmg: int = exchange.get("damage", 0)
			var text: String = "CRIT! %d" % dmg if exchange.get("crit", false) else str(dmg)
			var color := Color.ORANGE_RED if def_unit.team == "player" else Color.ORANGE
			_spawn_label(def_unit, text, color)
		else:
			_spawn_label(def_unit, "Miss", Color.WHITE)


func _on_unit_healed(unit: Node, amount: int) -> void:
	_spawn_label(unit, "+%d" % amount, Color.GREEN)


func _spawn_label(unit: Node, text: String, color: Color) -> void:
	if not is_instance_valid(unit) or not unit.is_inside_tree():
		return
	var lbl := Label.new()
	lbl.text = text
	lbl.modulate = color
	lbl.add_theme_font_size_override("font_size", 20)

	# Convert unit's world position to screen space for CanvasLayer placement
	var world_pos: Vector2 = unit.position + Vector2(GameConstants.TILE_SIZE * 0.5, 0.0)
	var screen_pos: Vector2 = get_viewport().canvas_transform * world_pos
	lbl.position = screen_pos + Vector2(-20.0, -20.0)
	add_child(lbl)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position", lbl.position + Vector2(0.0, -40.0), 0.8)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.8)
	tween.finished.connect(lbl.queue_free)
