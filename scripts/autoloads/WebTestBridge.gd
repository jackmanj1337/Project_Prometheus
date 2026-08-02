extends Node

# Read-only browser inspection surface for explicitly opted-in local web runs.
# Real input still travels through the canvas; query parameters only seed test
# configuration before the first scene lays out. Ordinary web URLs and non-web
# platforms expose nothing, even when built from the same export preset.

const VERSION := 1
const SCREEN_NAMES := {
	"HudLayoutEditor": "hud-layout-editor",
	"SettingsScreen": "settings",
	"NewGameScreen": "new-game",
	"LoadGameScreen": "load-game",
	"UnitDetailsScreen": "unit-details",
	"CampaignLibraryScreen": "campaign-library",
	"MapResultsScreen": "results",
	"GameOverScreen": "game-over",
	"PrepScreen": "prep",
	"GameMap": "game-map",
	"MainMenu": "main-menu",
}

var _bridge: JavaScriptObject
var _publish_elapsed := 0.0


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	var query := _query_parameters()
	if String(query.get("test_bridge", "")) != "1":
		return
	_apply_query_seed(query)
	_install_bridge()
	_publish_snapshot()
	set_process(true)


func _process(delta: float) -> void:
	_publish_elapsed += delta
	if _publish_elapsed < 0.1:
		return
	_publish_elapsed = 0.0
	_publish_snapshot()


func _query_parameters() -> Dictionary:
	var raw: Variant = JavaScriptBridge.eval(
		"JSON.stringify(Object.fromEntries(new URLSearchParams(window.location.search)))"
	)
	var parsed: Variant = JSON.parse_string(String(raw))
	return parsed as Dictionary if parsed is Dictionary else {}


func _apply_query_seed(query: Dictionary) -> void:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null:
		return
	if query.has("content_scale") and String(query["content_scale"]).is_valid_float():
		settings.set_content_scale_factor(float(query["content_scale"]))
	if query.has("menu_scale") and String(query["menu_scale"]).is_valid_float():
		var requested := float(query["menu_scale"])
		var nearest := 0
		var distance := INF
		for index in settings.MENU_SCALE_LEVELS.size():
			var candidate: float = settings.MENU_SCALE_LEVELS[index]
			if absf(candidate - requested) < distance:
				distance = absf(candidate - requested)
				nearest = index
		settings.menu_scale_index = nearest
		settings._apply_menu_scale()
	if query.has("safe"):
		var values := String(query["safe"]).split(",")
		var valid := values.size() == 4
		for value: String in values:
			valid = valid and value.is_valid_int()
		if valid:
			settings.safe_area_insets = Vector4i(
				int(values[0]), int(values[1]), int(values[2]), int(values[3])
			)


func _install_bridge() -> void:
	_bridge = JavaScriptBridge.create_object("Object")
	_bridge.version = VERSION
	var window := JavaScriptBridge.get_interface("window")
	window.__prometheus_test_bridge = _bridge


func _publish_snapshot() -> void:
	if _bridge == null:
		return
	var active := _active_screen()
	var controls: Array[String] = []
	var rects := {}
	var active_node: Node = active["node"]
	if active_node != null:
		_collect_controls(active_node, active_node, controls, rects)
	var screen_id := String(active["id"])
	_bridge.state = (
		JSON
		. stringify(
			{
				"screen": screen_id,
				"modal":
				screen_id if screen_id != "main-menu" and screen_id != "game-map" else null,
				"focus": _focus_snapshot(),
				"viewport": _viewport_snapshot(),
				"scales": _scale_snapshot(),
				"controls": controls,
				"rects": rects,
				"textEntry": _text_entry_snapshot(),
			}
		)
	)


func _focus_snapshot() -> Variant:
	var focus := get_viewport().gui_get_focus_owner()
	if focus == null:
		return null
	return {"path": _relative_path(focus), "text": _control_text(focus)}


func _viewport_snapshot() -> Dictionary:
	var size := get_viewport().get_visible_rect().size
	return {"w": size.x, "h": size.y}


func _scale_snapshot() -> Dictionary:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null:
		return {}
	var safe: Vector4i = settings.get_safe_area_insets()
	return {
		"menu": settings.get_menu_scale(),
		"content": settings.content_scale_factor,
		"effectiveMenu": settings.get_effective_menu_scale(),
		"safe": {"left": safe.x, "top": safe.y, "right": safe.z, "bottom": safe.w},
	}


func _text_entry_snapshot() -> Dictionary:
	var service := get_node_or_null("/root/TextEntryService")
	if service == null:
		return {"active": false}
	var target: LineEdit = service.session.request.target if service.session.active else null
	var overlay: Control = service._overlay if is_instance_valid(service._overlay) else null
	return {
		"active": service.session.active,
		"mode": String(service.active_mode),
		"text": service.session.text,
		"targetText": target.text if target != null else "",
		"targetPath": _relative_path(target) if target != null else "",
		"targetRect": _window_rect(target) if target != null else null,
		"presenterRect": _window_rect(overlay) if overlay != null else null,
	}


func _active_screen() -> Dictionary:
	var scene := get_tree().current_scene
	if scene == null:
		return {"id": "", "node": null}
	var candidates: Array[Node] = [scene]
	candidates.append_array(scene.find_children("*", "Control", true, false))
	for desired_name: String in SCREEN_NAMES:
		for node: Node in candidates:
			if (
				node.name == desired_name
				and (not (node is CanvasItem) or node.is_visible_in_tree())
			):
				return {"id": SCREEN_NAMES[desired_name], "node": node}
	return {"id": scene.name.to_snake_case().replace("_", "-"), "node": scene}


func _window_rect(control: Control) -> Dictionary:
	var rect := control.get_global_rect()
	var transform := get_viewport().get_screen_transform()
	var start := transform * rect.position
	var finish := transform * rect.end
	return {"x": start.x, "y": start.y, "w": finish.x - start.x, "h": finish.y - start.y}


func _relative_path(control: Control) -> String:
	var active: Node = _active_screen()["node"]
	return (
		String(active.get_path_to(control))
		if active != null and active.is_ancestor_of(control)
		else String(control.get_path())
	)


func _control_text(control: Control) -> String:
	if control is BaseButton:
		return control.text
	if control is LineEdit:
		return control.text
	if control is Label:
		return control.text
	return ""


func _collect_controls(
	root_node: Node, active: Node, result: Array[String], rects: Dictionary
) -> void:
	for child: Node in root_node.get_children():
		if child is Control:
			var control := child as Control
			if control.is_visible_in_tree():
				var path := String(active.get_path_to(control))
				rects[path] = _window_rect(control)
				if control.focus_mode != Control.FOCUS_NONE:
					result.append(path)
		_collect_controls(child, active, result, rects)
