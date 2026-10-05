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
	var legacy_lock := (
		ControllerLayoutS
		. normalize(
			{
				"schema_version": ControllerLayoutS.SCHEMA_VERSION,
				"viewport":
				{"x": 0.0, "y": 0.0, "width": 1.0, "height": 1.0, "aspect_locked": true},
			}
		)
	)
	var ratio_lock := (
		ControllerLayoutS
		. normalize(
			{
				"schema_version": ControllerLayoutS.SCHEMA_VERSION,
				"viewport":
				{"width": 1.0, "height": 1.0, "aspect_locked": true, "aspect": 4.0 / 3.0},
			}
		)
	)
	_ok(
		(
			not legacy_lock.viewport.aspect_locked
			and ratio_lock.viewport.aspect_locked
			and is_equal_approx(float(ratio_lock.viewport.aspect), 4.0 / 3.0)
		),
		"a lock without a ratio (every pre-UUI-20 save) reads as unlocked; one with a ratio holds"
	)
	_ok(
		malformed.global_opacity == 1.0 and malformed.theme == ControllerLayoutS.DEFAULT_THEME,
		"opacity clamps and an empty theme falls back"
	)
	# Opacity floors at MIN_ELEMENT_OPACITY rather than 0.0 (Slice 4 step 3): a
	# fully transparent control still takes touches, so zero would leave an
	# invisible dead zone the player cannot find again to undo.
	_ok(
		(
			malformed.elements.size() == 1
			and malformed.elements[0].x == 1.0
			and malformed.elements[0].y == 0.0
			and malformed.elements[0].scale == ControllerLayoutS.MAX_ELEMENT_SCALE
			and malformed.elements[0].opacity == ControllerLayoutS.MIN_ELEMENT_OPACITY
		),
		"elements clamp and duplicate or malformed IDs are rejected"
	)

	# Slice 4 step 4. `enabled` defaults to TRUE, which is what every layout saved
	# before the field existed carries: the alternative default would empty a
	# returning player's controller on upgrade.
	_ok(
		bool(malformed.elements[0].get("enabled", false)),
		"an element that never heard of `enabled` is drawn, not hidden"
	)
	var visibility := (
		ControllerLayoutS
		. normalize(
			{
				"schema_version": 1,
				"elements":
				[
					{"id": "a", "action": "confirm", "enabled": false},
					{"id": "b", "action": "cancel", "enabled": 0},
				],
			}
		)
	)
	_ok(
		not bool(visibility.elements[0].enabled) and bool(visibility.elements[1].enabled),
		"a real false hides a control; a stray 0 does not, because losing one is worse"
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
	# 200x100 is under the retired 640x360 design floor and is drawn as authored
	# [UUI-20]; only the edge clamp moves it back on screen.
	_ok(
		effective == Rect2(800, 400, 200, 100),
		"effective viewport keeps a small authored rect and applies only the edge clamp"
	)
	_ok(authored == authored_copy, "device-specific clamping does not mutate authored geometry")

	var technical := ControllerLayoutS.effective_viewport(authored, Vector2(320, 240))
	_ok(
		technical == Rect2(224, 144, 96, 96),
		"a rect smaller than the editor's handles resolves at the technical minimum"
	)
	var tiny_effective := ControllerLayoutS.effective_viewport(authored, Vector2(80, 60))
	_ok(
		tiny_effective == Rect2(0, 0, 80, 60),
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
