extends SceneTree
## Headless contract for exact, non-compositional unit palette remaps.

const PaletteSwap = preload("res://scripts/core/UnitPaletteSwap.gd")


func _init() -> void:
	print("=== Unit Palette Swap Test ===")
	var passed := 0
	var failed := 0
	var red := [255, 0, 0, 255]
	var blue := [0, 0, 255, 255]
	var green := [0, 255, 0, 255]
	var mappings := [{"from": red, "to": blue}]

	if PaletteSwap.remap_color(Color8(255, 0, 0), mappings) == Color8(0, 0, 255):
		print("OK  exact RGBA input is remapped")
		passed += 1
	else:
		print("FAIL exact RGBA remap")
		failed += 1

	if PaletteSwap.remap_color(Color8(0, 255, 0), mappings) == Color8(0, 255, 0):
		print("OK  unmatched colours remain unchanged")
		passed += 1
	else:
		print("FAIL unmatched colour changed")
		failed += 1

	var duplicate := PaletteSwap.normalized_mappings(
		[{"from": red, "to": blue}, {"from": red, "to": green}]
	)
	if duplicate["mappings"].size() == 1 and duplicate["warnings"].size() == 1:
		print("OK  first duplicate input wins with an authoring warning")
		passed += 1
	else:
		print("FAIL duplicate handling: %s" % [duplicate])
		failed += 1

	var many: Array = []
	for index in 33:
		many.append({"from": [index, 0, 0, 255], "to": [0, index, 0, 255]})
	if PaletteSwap.normalized_mappings(many)["mappings"].size() == PaletteSwap.MAX_MAPPINGS:
		print("OK  runtime capacity is pinned to the shared 32-entry maximum")
		passed += 1
	else:
		print("FAIL palette capacity")
		failed += 1

	var material := PaletteSwap.build_material(mappings)
	if (
		material != null
		and material.get_shader_parameter("from_0") == Color8(255, 0, 0)
		and material.get_shader_parameter("to_0") == Color8(0, 0, 255)
	):
		print("OK  material uniforms preserve deterministic mapping order")
		passed += 1
	else:
		print("FAIL material uniforms: %s" % [material])
		failed += 1

	var packed: PackedScene = load("res://scenes/units/Unit.tscn")
	var unit: Unit = packed.instantiate()
	root.add_child(unit)
	await process_frame
	var dm := root.get_node_or_null("DataManager")
	var class_data: ClassData = dm.get_class_data("knight") if dm != null else null
	var old_sprite_id := class_data.sprite_id if class_data != null else ""
	if class_data != null:
		class_data.sprite_id = "hero_map"
	var unit_data := UnitData.new()
	unit_data.class_id = "knight"
	unit.data = unit_data
	unit.team = "blue"
	unit.apply_pack_sprite_asset({"hero_map": {"supported_swap_ids": ["blue_normal", "blue_done"]}})
	var swaps := {
		"blue_normal": {"faction_id": "blue", "state": "normal", "mappings": mappings},
		"blue_done": {"faction_id": "blue", "state": "done", "mappings": mappings},
	}
	var sprite := unit.get_node("Sprite2D") as AnimatedSprite2D
	var hp_bar := unit.get_node("HPBar") as ProgressBar
	var hp_modulate := hp_bar.modulate
	var repairs := unit.apply_palette_catalogue(swaps)
	unit.set_done_appearance()
	var done_material := sprite.material
	unit.reset_appearance()
	if repairs.is_empty() and done_material != null and sprite.material != null:
		print("OK  normal and done choose one keyed swap without layering")
		passed += 1
	else:
		print("FAIL Unit keyed swap: repairs=%s material=%s" % [repairs, done_material])
		failed += 1
	unit.apply_palette_catalogue({})
	if sprite.material == null and hp_bar.modulate == hp_modulate:
		print("OK  missing swap falls back without changing the HP-bar faction cue")
		passed += 1
	else:
		print("FAIL Unit fallback or HP-bar identity")
		failed += 1
	if class_data != null:
		class_data.sprite_id = old_sprite_id
	unit.queue_free()

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)
