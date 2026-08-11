extends SceneTree

const ControllerLayoutS = preload("res://scripts/resources/ControllerLayout.gd")

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
	print("=== Controller Layout Test ===")

	var defaults := ControllerLayoutS.default_collection()
	_ok(defaults.size() == 6, "default collection exposes six starting combinations")
	_ok(
		defaults[3].orientation == "portrait" and defaults[1].orientation == "landscape",
		"default collection includes separate portrait and landscape layouts"
	)

	var malformed := (
		ControllerLayoutS
		. normalize(
			{
				"schema_version": 1,
				"id": " custom ",
				"name": " Test Layout ",
				"orientation": "sideways",
				"profile": "unknown",
				"theme": " ",
				"global_opacity": 9.0,
				"viewport":
				{"x": -2.0, "y": 3.0, "width": 0.0, "height": INF, "aspect_locked": "yes"},
				"elements":
				[
					{
						"id": "confirm",
						"action": "confirm",
						"x": 2,
						"y": -1,
						"scale": 8,
						"opacity": -1
					},
					{"id": "confirm", "action": "cancel"},
					{"id": "", "action": "cancel"},
					"garbage",
				],
			}
		)
	)
	_ok(
		malformed.id == "custom" and malformed.name == "Test Layout",
		"normalization trims stable identity and display name"
	)
	_ok(
		malformed.orientation == "both" and malformed.profile == "labeled_actions",
		"unknown orientation and profile fail to safe defaults"
	)
	_ok(
		(
			malformed.viewport.x == 0.0
			and malformed.viewport.y == 1.0
			and malformed.viewport.width == 0.01
			and malformed.viewport.height == 1.0
			and not malformed.viewport.aspect_locked
		),
		"viewport geometry and aspect flag are sanitized"
	)
	_ok(
		malformed.global_opacity == 1.0 and malformed.theme == ControllerLayoutS.DEFAULT_THEME,
		"opacity clamps and an empty theme falls back"
	)
	_ok(
		(
			malformed.elements.size() == 1
			and malformed.elements[0].x == 1.0
			and malformed.elements[0].y == 0.0
			and malformed.elements[0].scale == 3.0
			and malformed.elements[0].opacity == 0.0
		),
		"elements clamp and duplicate or malformed IDs are rejected"
	)

	var unsupported := ControllerLayoutS.normalize({"schema_version": 99, "name": "Future"})
	_ok(
		unsupported.schema_version == 1 and unsupported.name == "Default",
		"unknown schema versions fail closed to the current default"
	)

	var authored := ControllerLayoutS.default_combination("Small", "landscape")
	authored.viewport = {"x": 0.9, "y": 0.9, "width": 0.2, "height": 0.2, "aspect_locked": false}
	var authored_copy: Dictionary = authored.duplicate(true)
	var effective := ControllerLayoutS.effective_viewport(authored, Vector2(1000, 500))
	_ok(
		effective == Rect2(360, 140, 640, 360),
		"effective viewport applies the logical minimum and edge clamp"
	)
	_ok(authored == authored_copy, "device-specific clamping does not mutate authored geometry")

	var tiny_effective := ControllerLayoutS.effective_viewport(authored, Vector2(320, 240))
	_ok(
		tiny_effective == Rect2(0, 0, 320, 240),
		"minimum shrinks safely on a smaller physical display"
	)

	var landscape := ControllerLayoutS.default_combination("Landscape", "landscape", 1)
	var shared := ControllerLayoutS.default_combination("Shared", "both", 2)
	var portrait := ControllerLayoutS.default_combination("Portrait", "portrait", 3)
	_ok(
		(
			ControllerLayoutS.select_for_orientation([shared, landscape], "landscape").name
			== "Landscape"
		),
		"orientation-specific layout wins over an earlier shared fallback"
	)
	_ok(
		ControllerLayoutS.select_for_orientation([shared, portrait], "landscape").name == "Shared",
		"shared layout is used when no orientation-specific layout exists"
	)

	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
