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
# The shell never names an InputMap action — only a registered element id — so
# the allow-list in ControllerActionRegistry is the whole authorisation surface.

const GLOBAL_NAME := "PrometheusController"
# Canonical renderer source. The build step copies it next to index.html; when
# it is also exported as a resource this class can inject it itself, which keeps
# a plain (non-PWA) web export working with no shell edit.
const SHELL_SCRIPT_PATH := "res://tools/web/controller_shell.js"

const VALID_EVENT_TYPES: Array[String] = ["press", "release", "release_all", "orientation"]

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
	return {"type": type}


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
	return false


# Wires the running service to the browser shell. No-op off the web platform.
func install(service: Node) -> bool:
	if service == null or not is_web() or not Engine.has_singleton("JavaScriptBridge"):
		return false
	_service = service
	var window: Variant = JavaScriptBridge.get_interface("window")
	if window == null:
		return false
	# The shell script normally arrives with the page. Inject the exported copy
	# only when it did not, so a shell that already defines the global wins.
	if window.get(GLOBAL_NAME) == null:
		var source := shell_source()
		if source.is_empty():
			push_warning("ControllerWebBridge: no browser shell renderer available")
			return false
		JavaScriptBridge.eval(source, true)
	_callback = JavaScriptBridge.create_callback(_on_shell_event)
	var controller: Variant = window.get(GLOBAL_NAME)
	if controller == null:
		return false
	controller.setBridge(_callback)
	if not service.layout_changed.is_connected(_on_layout_changed):
		service.layout_changed.connect(_on_layout_changed)
	publish(service.payload_json())
	return true


func publish(payload_json: String) -> void:
	if not is_web():
		return
	var window: Variant = JavaScriptBridge.get_interface("window")
	if window == null:
		return
	var controller: Variant = window.get(GLOBAL_NAME)
	if controller != null:
		controller.apply(payload_json)


func _on_layout_changed(_payload: Dictionary) -> void:
	if _service != null:
		publish(_service.payload_json())


func _on_shell_event(args: Array) -> void:
	if args.is_empty():
		return
	dispatch(_service, parse_event(args[0]))
