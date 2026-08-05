class_name ControllerWebBridge
extends RefCounted

# The Godot ↔ browser seam for the on-screen controller.
#
# Everything that can be tested without a browser is a pure static function
# here: parsing a shell message, and turning a parsed message into service
# calls. `install()` is the only part that needs JavaScriptBridge, so headless
# suites exercise the whole protocol including the fail-closed paths.
#
# Message shape, shell → engine (JSON string, one object):
#   {"type":"press",       "pointer":"7", "element":"act_confirm"}
#   {"type":"release",     "pointer":"7"}
#   {"type":"release_all"}
#   {"type":"orientation", "orientation":"portrait"}
#   {"type":"metrics",     "width":844, "height":390, "dpr":3}
# The shell never names an InputMap action — only a registered element id — so
# the allow-list in ControllerActionRegistry is the whole authorisation surface.
#
# `metrics` reports the WINDOW, which is the one thing Godot cannot measure for
# itself under canvas_resize_policy=0 — DisplayServer reports the canvas, and the
# canvas is precisely what we are trying to decide the size of.

const GLOBAL_NAME := "PrometheusController"
# Canonical renderer source, shipped INSIDE the pck so this class can inject it
# itself and no HTML shell edit or copy step is required. The web preset's
# `include_filter` is what puts it there — `tools/**` is otherwise excluded, and
# note that `exclude_filter` WINS over `include_filter`, so the exclusion is
# narrowed to spare exactly this file rather than listing it as an include and
# assuming that is enough (it is not; the file silently vanishes from the pck).
const SHELL_SCRIPT_PATH := "res://tools/web/controller_shell.js"

const LAYOUT_GLOBAL_NAME := "PrometheusWebLayout"

const VALID_EVENT_TYPES: Array[String] = [
	"press", "release", "release_all", "orientation", "metrics"
]

var _callback: Variant = null
var _service: Node = null


static func is_web() -> bool:
	return OS.has_feature("web")


# Reads the renderer source, or "" when it was not exported. Callers treat "" as
# "the shell already provides its own copy".
static func shell_source() -> String:
	if not FileAccess.file_exists(SHELL_SCRIPT_PATH):
		return ""
	var file := FileAccess.open(SHELL_SCRIPT_PATH, FileAccess.READ)
	return file.get_as_text() if file != null else ""


# Normalizes one shell message. Returns {} for anything malformed, unknown, or
# missing its required field — never a partially-filled event.
static func parse_event(raw: Variant) -> Dictionary:
	var data: Variant = raw
	if raw is String:
		# The instance parser returns an error code instead of logging one, so a
		# hostile page cannot spam the player's log by sending junk.
		var json := JSON.new()
		if json.parse(raw) != OK:
			return {}
		data = json.data
	if not data is Dictionary:
		return {}
	var source: Dictionary = data
	var type := String(source.get("type", ""))
	if not type in VALID_EVENT_TYPES:
		return {}
	var pointer := String(source.get("pointer", ""))
	match type:
		"press":
			var element := String(source.get("element", ""))
			if pointer.is_empty() or element.is_empty():
				return {}
			return {"type": type, "pointer": pointer, "element": element}
		"release":
			if pointer.is_empty():
				return {}
			return {"type": type, "pointer": pointer}
		"orientation":
			var orientation := String(source.get("orientation", ""))
			if not orientation in ["portrait", "landscape"]:
				return {}
			return {"type": type, "orientation": orientation}
		"metrics":
			# A zero or negative window is not a smaller window — it is a window
			# reported mid-teardown or before layout. Sizing the canvas to it would
			# blank the game, and nothing would be left to touch to recover.
			var width := _safe_float(source.get("width", 0.0))
			var height := _safe_float(source.get("height", 0.0))
			if width <= 0.0 or height <= 0.0:
				return {}
			return {"type": type, "width": width, "height": height}
	return {"type": type}


# Rejects NAN/INF as well as non-numbers: a non-finite width survives arithmetic
# and only fails at the CSS boundary, where it silently collapses the canvas.
static func _safe_float(value: Variant) -> float:
	if value is float or value is int:
		var number := float(value)
		return number if is_finite(number) else 0.0
	return 0.0


# Applies a parsed event to the service. Returns true when the event changed
# something, so a caller (or a test) can tell an ignored message from a handled
# one. A malformed message is simply dropped.
static func dispatch(service: Node, event: Dictionary) -> bool:
	if service == null or event.is_empty():
		return false
	match String(event.get("type", "")):
		"press":
			return bool(service.press(String(event.pointer), String(event.element)))
		"release":
			return bool(service.release(String(event.pointer)))
		"release_all":
			return not service.release_all_actions().is_empty()
		"orientation":
			service.set_orientation(String(event.orientation))
			return true
		"metrics":
			return bool(
				service.set_available_pixels(Vector2(float(event.width), float(event.height)))
			)
	return false


# Resolves the shell's global object, or null when the page has not defined it.
#
# `get_interface(name)` is the only reliable way to read a JS global from GDScript.
# The obvious-looking alternative — fetching the `window` interface and calling
# `window.get("PrometheusController")` — compiles, runs, and returns NIL even when
# the global demonstrably exists (measured against this export: `window.get` gave
# TYPE_NIL while `get_interface` gave TYPE_OBJECT for the same property in the same
# frame). That silent nil is what made `install()` fail closed on every device.
static func _shell() -> Variant:
	# `get_interface` on an undefined global logs "No interface ... registered" at
	# ERROR level, and the first call is EXPECTED to miss (that is what triggers the
	# injection). Probing with `eval` first keeps a normal boot's log clean, so a
	# real controller error still stands out instead of being one red line among two.
	if not bool(JavaScriptBridge.eval("typeof window.%s !== 'undefined'" % GLOBAL_NAME, true)):
		return null
	return JavaScriptBridge.get_interface(GLOBAL_NAME)


# Wires the running service to the browser shell. No-op off the web platform.
func install(service: Node) -> bool:
	if service == null or not is_web() or not Engine.has_singleton("JavaScriptBridge"):
		return false
	_service = service
	# The shell script normally arrives with the page. Inject the exported copy
	# only when it did not, so a shell that already defines the global wins.
	if _shell() == null:
		var source := shell_source()
		if source.is_empty():
			push_warning("ControllerWebBridge: no browser shell renderer available")
			return false
		JavaScriptBridge.eval(source, true)
	_callback = JavaScriptBridge.create_callback(_on_shell_event)
	var controller: Variant = _shell()
	if controller == null:
		return false
	controller.setBridge(_callback)
	if not service.layout_changed.is_connected(_on_layout_changed):
		service.layout_changed.connect(_on_layout_changed)
	if not service.canvas_rect_changed.is_connected(_on_canvas_rect_changed):
		service.canvas_rect_changed.connect(_on_canvas_rect_changed)
	# Seed the window size from the shell rather than waiting for its first
	# `metrics` message: until the service knows the window it cannot size the
	# canvas, and the player would watch the controls sit on top of a full-window
	# game for a beat. setBridge() also reports metrics, so this is belt-and-braces
	# for a shell that was already present and never re-reported.
	_seed_metrics(service)
	publish(service.payload_json())
	publish_canvas(service.canvas_rect_json())
	return true


# Reads the window rect straight out of the layout global. Failure is fine and
# silent — the shell's own `metrics` message is the authoritative path.
func _seed_metrics(service: Node) -> void:
	var layout: Variant = _layout()
	if layout == null:
		return
	var parsed := parse_event(_metrics_event_from(str(layout.query())))
	if not parsed.is_empty():
		dispatch(service, parsed)


# The shell's `query()` reports a viewport, not an event; relabel it so it goes
# through exactly the same validation as a message that arrived over the bridge.
static func _metrics_event_from(query_json: String) -> String:
	var json := JSON.new()
	if json.parse(query_json) != OK or not json.data is Dictionary:
		return ""
	var source: Dictionary = json.data
	source["type"] = "metrics"
	return JSON.stringify(source)


func publish(payload_json: String) -> void:
	if not is_web():
		return
	var controller: Variant = _shell()
	if controller != null:
		controller.apply(payload_json)


# Hands the canvas rectangle to the shell. Separate from `publish()` because the
# two have different cadences and different costs: the controller payload rebuilds
# every button (and drops held presses doing it), while this only moves the canvas.
# A window resize must do the second without the first.
func publish_canvas(rect_json: String) -> void:
	if not is_web() or rect_json.is_empty():
		return
	var layout: Variant = _layout()
	if layout != null:
		layout.apply(rect_json)


static func _layout() -> Variant:
	if not bool(
		JavaScriptBridge.eval("typeof window.%s !== 'undefined'" % LAYOUT_GLOBAL_NAME, true)
	):
		return null
	return JavaScriptBridge.get_interface(LAYOUT_GLOBAL_NAME)


func _on_layout_changed(_payload: Dictionary) -> void:
	if _service != null:
		publish(_service.payload_json())
		# The active combination carries the viewport, so a layout change can move
		# the canvas too — switching to a portrait preset is exactly that.
		publish_canvas(_service.canvas_rect_json())


func _on_canvas_rect_changed(_rect: Rect2) -> void:
	if _service != null:
		publish_canvas(_service.canvas_rect_json())


func _on_shell_event(args: Array) -> void:
	if args.is_empty():
		return
	dispatch(_service, parse_event(args[0]))
