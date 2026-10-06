extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_controller_placement.gd
#
# MOBILE-WEB-CONTROLLER-2026-08-04 slice 4: the registry's controls go in the
# columns the game view leaves ([UUI-2]), for both profiles, at the [UUI-20] test
# floor and the measured phone. "Nothing covers the game" is checked as geometry:
# every control's box, sized the way the shell sizes it, must miss the canvas, the
# other controls and the window edge.

const ControllerActionRegistryS = preload("res://scripts/resources/ControllerActionRegistry.gd")
const ControllerPlacementS = preload("res://scripts/resources/ControllerPlacement.gd")
const SettingsManagerS = preload("res://scripts/autoloads/SettingsManager.gd")

var _passed := 0
var _failed := 0


func _ok(condition: bool, message: String) -> void:
	if condition:
		print("OK  ", message)
		_passed += 1
	else:
		print("FAIL ", message)
		_failed += 1


func _init() -> void:
	print("=== Controller Placement Test ===")
	_test_columns_clear_the_game()
	_test_uui2_arrangement()
	_test_descriptor_hints()
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


# The canvas Widest That Fits gives this window, in pixels -- the case the defaults
# are drawn against.
func _widest_canvas(available: Vector2, orientation: String) -> Rect2:
	var view := SettingsManagerS.game_view_viewport(
		orientation, SettingsManagerS.GAME_VIEW_WIDEST, 1.0, available, true
	)
	return Rect2(
		Vector2(float(view.x), float(view.y)) * available,
		Vector2(float(view.width), float(view.height)) * available
	)


func _boxes(
	registry: ControllerActionRegistry,
	profile: String,
	available: Vector2,
	canvas: Rect2,
	orientation: String
) -> Dictionary:
	var placed := ControllerPlacementS.place(
		registry.descriptors_for_profile(profile), available, canvas, orientation
	)
	var b := ControllerPlacementS.button_px(available)
	var boxes := {}
	for id: String in placed:
		var d := registry.descriptor(id)
		var w := b * (ControllerPlacementS.PILL_WIDTH_FACTOR if d.group == "action" else 1.0)
		var centre: Vector2 = placed[id] * available
		boxes[id] = Rect2(centre - Vector2(w, b) * 0.5, Vector2(w, b))
	return boxes


func _test_columns_clear_the_game() -> void:
	var registry := ControllerActionRegistryS.new()
	var cases := [
		[Vector2(667, 375), "landscape"],
		[Vector2(852, 393), "landscape"],
		[Vector2(375, 667), "portrait"],
		[Vector2(393, 852), "portrait"],
	]
	for profile: String in ["labeled_actions", "virtual_gamepad"]:
		for case: Array in cases:
			var available: Vector2 = case[0]
			var orientation: String = case[1]
			var canvas := _widest_canvas(available, orientation)
			var boxes := _boxes(registry, profile, available, canvas, orientation)
			var window := Rect2(Vector2.ZERO, available)
			var on_game: Array[String] = []
			var off_screen: Array[String] = []
			var collisions: Array[String] = []
			var ids := boxes.keys()
			for i in ids.size():
				var box: Rect2 = boxes[ids[i]]
				# Shrunk a hair so boxes that only share an edge do not count.
				var inner := box.grow(-0.5)
				if inner.intersects(canvas):
					on_game.append(ids[i])
				if not window.encloses(box):
					off_screen.append(ids[i])
				for j in range(i + 1, ids.size()):
					if inner.intersects((boxes[ids[j]] as Rect2).grow(-0.5)):
						collisions.append("%s/%s" % [ids[i], ids[j]])
			var tag := "%s %dx%d" % [profile, int(available.x), int(available.y)]
			_ok(
				boxes.size() == registry.ids_for_profile(profile).size(),
				"%s: every control is placed" % tag
			)
			_ok(on_game.is_empty(), "%s: no control covers the game %s" % [tag, on_game])
			_ok(collisions.is_empty(), "%s: no two controls overlap %s" % [tag, collisions])
			_ok(off_screen.is_empty(), "%s: every control is on screen %s" % [tag, off_screen])


# [UUI-2]: D-pad plus SELECT/START in the left column, face buttons plus MENU in the
# right, shoulders at the top of each.
func _test_uui2_arrangement() -> void:
	var registry := ControllerActionRegistryS.new()
	var available := Vector2(852, 393)
	var canvas := _widest_canvas(available, "landscape")
	var pad := ControllerPlacementS.place(
		registry.descriptors_for_profile("virtual_gamepad"), available, canvas, "landscape"
	)
	var left_edge := canvas.position.x / available.x
	var right_edge := canvas.end.x / available.x
	var in_left := func(id: String) -> bool: return (pad[id] as Vector2).x < left_edge
	var in_right := func(id: String) -> bool: return (pad[id] as Vector2).x > right_edge
	_ok(
		["dpad_up", "dpad_down", "dpad_left", "dpad_right", "pad_select", "pad_start"].all(in_left),
		"virtual pad: the D-pad and SELECT/START sit in the left column"
	)
	_ok(
		["pad_south", "pad_east", "pad_west", "pad_north"].all(in_right),
		"virtual pad: the face buttons sit in the right column"
	)
	_ok(
		(
			(pad.shoulder_left as Vector2).y < (pad.pad_select as Vector2).y
			and (pad.shoulder_right as Vector2).y < (pad.pad_north as Vector2).y
			and in_left.call("shoulder_left")
			and in_right.call("shoulder_right")
		),
		"virtual pad: each shoulder sits at the top of its own column"
	)
	_ok(
		(
			(pad.dpad_up as Vector2).y < (pad.dpad_left as Vector2).y
			and (pad.dpad_left as Vector2).y < (pad.dpad_down as Vector2).y
			and (pad.dpad_left as Vector2).x < (pad.dpad_up as Vector2).x
			and (pad.dpad_up as Vector2).x < (pad.dpad_right as Vector2).x
		),
		"the D-pad keeps its cross shape"
	)

	var words := ControllerPlacementS.place(
		registry.descriptors_for_profile("labeled_actions"), available, canvas, "landscape"
	)
	var words_right := func(id: String) -> bool: return (words[id] as Vector2).x > right_edge
	var words_left := func(id: String) -> bool: return (words[id] as Vector2).x < left_edge
	_ok(
		["act_confirm", "act_back", "act_menu"].all(words_right),
		"labelled actions: Confirm, Back and Menu sit in the right column"
	)
	_ok(
		["act_up", "act_down", "act_left", "act_right"].all(words_left),
		"labelled actions: the directional cross sits in the left column"
	)
	_ok(
		ControllerPlacementS.place([], Vector2.ZERO, canvas, "landscape").is_empty(),
		"an unmeasured window places nothing, so the descriptors' own x/y apply"
	)


func _test_descriptor_hints() -> void:
	var registry := ControllerActionRegistryS.new(false)
	var base := {
		"action": "confirm", "label": "Extra", "group": "face", "profiles": ["virtual_gamepad"]
	}
	var bad_cell := base.duplicate()
	bad_cell.id = "bad_cell"
	bad_cell.cell = [2, 0]
	registry.register(bad_cell)
	var no_column := base.duplicate()
	no_column.id = "no_column"
	no_column.x = 0.9
	registry.register(no_column)
	_ok(
		registry.descriptor("bad_cell").cell == null,
		"a cell outside -1..1 is no cell, so the control stacks instead of landing on another"
	)
	_ok(
		registry.descriptor("no_column").column == "",
		"a descriptor that names no column registers without one"
	)
	var available := Vector2(852, 393)
	var placed := ControllerPlacementS.place(
		registry.descriptors_for_profile("virtual_gamepad"),
		available,
		Rect2(164, 0, 524, 393),
		"landscape"
	)
	_ok(
		(placed.no_column as Vector2).x * available.x > 688.0,
		"...and is placed in the column on the side its own x is on"
	)
