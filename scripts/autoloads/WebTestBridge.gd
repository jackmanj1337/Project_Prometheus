extends Node
# adopter-allow: the consumer cannot be in this repository by construction.
# This is a read-only inspection surface published over JavaScriptBridge and read
# by the Playwright harness in the container repo (tools/playwright/lib/bridge.mjs
# compares its VERSION). Engine code calling it would defeat the point: it exists
# so tests can observe the running game without the game knowing.

# Read-only browser inspection surface for explicitly opted-in local web runs.
# Real input still travels through the canvas; query parameters only seed test
# configuration before the first scene lays out. Ordinary web URLs and non-web
# platforms expose nothing, even when built from the same export preset.

const VERSION := 3
const SCREEN_NAMES := {
	"ActionMenu": "action-menu",
	"AttackPreview": "attack-preview",
	"WeaponMenu": "weapon-menu",
	"ItemMenu": "item-menu",
	"MapMenu": "map-menu",
	"HUD": "hud",
	"LevelUpScreen": "level-up",
	"PromotionScreen": "promotion",
	"ReclassScreen": "reclass",
	"RewindSelector": "rewind",
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
const GALLERY_SCENES := {
	"settings": "res://scenes/ui/SettingsScreen.tscn",
	"new-game": "res://scenes/ui/NewGameScreen.tscn",
	"load-game": "res://scenes/ui/LoadGameScreen.tscn",
	"campaign-library": "res://scenes/ui/CampaignLibraryScreen.tscn",
	"unit-details": "res://scenes/ui/UnitDetailsScreen.tscn",
	"prep": "res://scenes/ui/PrepScreen.tscn",
	"results": "res://scenes/ui/MapResultsScreen.tscn",
	"game-over": "res://scenes/ui/GameOverScreen.tscn",
	"promotion": "res://scenes/ui/PromotionScreen.tscn",
	"reclass": "res://scenes/ui/ReclassScreen.tscn",
	"level-up": "res://scenes/ui/LevelUpScreen.tscn",
	"rewind": "res://scenes/ui/RewindSelector.tscn",
	"action-menu": "res://scenes/ui/ActionMenu.tscn",
	"attack-preview": "res://scenes/ui/AttackPreview.tscn",
	"weapon-menu": "res://scenes/ui/WeaponMenu.tscn",
	"item-menu": "res://scenes/ui/ItemMenu.tscn",
	"map-menu": "res://scenes/ui/MapMenu.tscn",
	"hud": "res://scenes/ui/HUD.tscn",
}

var _bridge: JavaScriptObject
var _publish_elapsed := 0.0
var _publish_sequence := 0
var _focus_history: Array[String] = []
var _last_focus_path := ""


func _ready() -> void:
	# Scripts defining _process() start with processing enabled. Make the opt-in
	# boundary structural so ordinary builds do not tick this autoload at all.
	set_process(false)
	if not OS.has_feature("web"):
		return
	var query := _query_parameters()
	if String(query.get("test_bridge", "")) != "1":
		return
	_apply_query_seed(query)
	_install_bridge()
	_publish_snapshot()
	set_process(true)
	if query.has("gallery"):
		_open_gallery_screen.call_deferred(String(query["gallery"]))


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


# Seeds are per-RUN test configuration, so none of them may outlive the run. Three
# seeds previously behaved two different ways: content scale went through a setter that
# persists to the settings file, while menu scale and safe-area insets were assigned in
# memory. That left the last instrumented run's content scale on disk, so a later run
# that omitted the parameter silently inherited it — the kind of cross-run bleed that
# makes an album case unreproducible.
func _apply_query_seed(query: Dictionary) -> void:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null:
		return
	if query.has("content_scale") and String(query["content_scale"]).is_valid_float():
		settings.set_content_scale_factor(float(query["content_scale"]), false)
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


# The gallery selects an initial production scene for visual inspection; it does
# not add test-only widgets or bypass input once that scene is visible. Screens
# that need gameplay state intentionally render their safe empty-state shell.
func _open_gallery_screen(screen_id: String) -> void:
	if screen_id == "main-menu" or not GALLERY_SCENES.has(screen_id):
		return
	while get_tree().current_scene == null or get_tree().current_scene.name == "Boot":
		await get_tree().process_frame
	var embedded_names := {
		"settings": "SettingsScreen", "new-game": "NewGameScreen", "load-game": "LoadGameScreen"
	}
	if embedded_names.has(screen_id):
		var embedded := get_tree().current_scene.find_child(
			String(embedded_names[screen_id]), true, false
		)
		if embedded != null and embedded.has_method("open"):
			embedded.call("open")
		return
	var packed := load(String(GALLERY_SCENES[screen_id])) as PackedScene
	if packed == null:
		return
	var gallery_screen := packed.instantiate()
	get_tree().current_scene.add_child(gallery_screen)
	await get_tree().process_frame
	if (
		gallery_screen.has_method("open")
		and screen_id in ["settings", "new-game", "load-game", "campaign-library"]
	):
		gallery_screen.call("open")
	else:
		gallery_screen.show()


func _publish_snapshot() -> void:
	if _bridge == null:
		return
	_publish_sequence += 1
	var active := _active_screen()
	var controls: Array[String] = []
	var rects := {}
	var active_node: Node = active["node"]
	if active_node != null:
		_collect_controls(active_node, active_node, controls, rects)
	var screen_id := String(active["id"])
	var focus: Variant = _focus_snapshot()
	_remember_focus(focus)
	_bridge.state = (
		JSON
		. stringify(
			{
				"sequence": _publish_sequence,
				"frame": Engine.get_frames_drawn(),
				"publishedAtMsec": Time.get_ticks_msec(),
				"screen": screen_id,
				"modal":
				screen_id if screen_id != "main-menu" and screen_id != "game-map" else null,
				"modalStack": _modal_stack_snapshot(active),
				"focus": focus,
				"focusHistory": _focus_history.duplicate(),
				"inputMode": _input_mode_snapshot(),
				"viewport": _viewport_snapshot(),
				"scales": _scale_snapshot(),
				"controls": controls,
				"rects": rects,
				"textEntry": _text_entry_snapshot(),
				"activePackage": _active_package_snapshot(),
				"importDiagnostics": _import_diagnostic_codes(active_node),
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
	var overlay: Control = service.overlay()
	return {
		"active": service.session.active,
		"generation": int(service.get("_generation")),
		"mode": String(service.active_mode),
		"text": service.session.text,
		"consumer": String(service.last_input_consumer),
		"semanticTransitions": service.semantic_transition_count,
		"targetText": target.text if target != null else "",
		"targetPath": _relative_path(target) if target != null else "",
		"targetRect": _window_rect(target) if target != null else null,
		"presenterRect": _window_rect(overlay) if overlay != null else null,
	}


func _remember_focus(focus: Variant) -> void:
	var path := String(focus.get("path", "")) if focus is Dictionary else ""
	if path == _last_focus_path:
		return
	_last_focus_path = path
	_focus_history.append(path)
	if _focus_history.size() > 12:
		_focus_history.pop_front()


func _input_mode_snapshot() -> Dictionary:
	var manager := get_node_or_null("/root/InputModeManager")
	if manager == null:
		return {}
	return {
		"active": String(manager.active_input_mode),
		"lastDetected": String(manager.last_detected_input_mode),
	}


func _active_package_snapshot() -> Dictionary:
	var manager := get_node_or_null("/root/DataManager")
	if manager == null or not manager.has_method("active_package_identity"):
		return {}
	var identity: Dictionary = manager.call("active_package_identity")
	# Paths are machine-local implementation details; tests need durable identity.
	return {
		"packageId": String(identity.get("package_id", "")),
		"packageVersion": String(identity.get("package_version", "")),
	}


func _modal_stack_snapshot(active: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var active_node: Node = active.get("node")
	if active_node != null and String(active.get("id", "")) not in ["main-menu", "game-map"]:
		result.append({"id": String(active["id"]), "path": String(active_node.get_path())})
	var service := get_node_or_null("/root/TextEntryService")
	if service != null and service.session.active:
		var overlay: Control = service.overlay()
		(
			result
			. append(
				{
					"id": "text-entry",
					"path": String(overlay.get_path()) if overlay != null else "",
					"inputOwner": true,
				}
			)
		)
	return result


func _import_diagnostic_codes(active: Node) -> Array[String]:
	var result: Array[String] = []
	if active == null:
		return result
	for dialog: Node in active.find_children("*", "AcceptDialog", true, false):
		if not dialog.visible:
			continue
		for code: String in _diagnostic_codes_from_text(String(dialog.dialog_text)):
			if code not in result:
				result.append(code)
	result.sort()
	return result


static func _diagnostic_codes_from_text(value: String) -> Array[String]:
	var result: Array[String] = []
	var matcher := RegEx.new()
	matcher.compile("(?:^|[^a-z0-9])([a-z][a-z0-9]*(?:_[a-z0-9]+)+)(?=$|[^a-z0-9])")
	for match: RegExMatch in matcher.search_all(value.to_lower()):
		var code := match.get_string(1)
		if code not in result:
			result.append(code)
	return result


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
				rects[path] = _control_snapshot(control)
				if control.focus_mode != Control.FOCUS_NONE:
					result.append(path)
		_collect_controls(child, active, result, rects)


func _control_snapshot(control: Control) -> Dictionary:
	var snapshot := _window_rect(control)
	snapshot["theme"] = _theme_provenance(control)
	var semantic_id := _semantic_control_id(control)
	if not semantic_id.is_empty():
		snapshot["semanticId"] = semantic_id
	var text := _control_text(control)
	if text == "":
		return snapshot
	var minimum := control.get_combined_minimum_size()
	var font := control.get_theme_font("font")
	var font_size := control.get_theme_font_size("font_size")
	var measured := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var content_fits := measured.x <= control.size.x + 0.5 and measured.y <= control.size.y + 0.5
	snapshot["text"] = text
	snapshot["truncation"] = {
		"fits": content_fits,
		"measuredTextWidth": measured.x,
		"measuredTextHeight": measured.y,
		"minimumWidth": minimum.x,
		"minimumHeight": minimum.y,
		"availableWidth": control.size.x,
		"availableHeight": control.size.y,
		"overrunBehavior": _overrun_behavior(control),
	}
	if control is Label:
		snapshot["truncation"]["lineCount"] = control.get_line_count()
		snapshot["truncation"]["visibleLineCount"] = control.get_visible_line_count()
		snapshot["truncation"]["fits"] = (
			snapshot["truncation"]["fits"]
			and control.get_visible_line_count() >= control.get_line_count()
		)
	return snapshot


static func _theme_provenance(control: Control) -> Dictionary:
	var candidate: Node = control
	while candidate != null:
		if candidate is Control and (candidate as Control).theme != null:
			var resource := (candidate as Control).theme as Theme
			return {
				"source": "control",
				"owner": String(candidate.get_path()),
				"resource":
				resource.resource_path if not resource.resource_path.is_empty() else "<embedded>",
			}
		candidate = candidate.get_parent()
	var fallback := ThemeDB.get_default_theme()
	return {
		"source": "theme-db-default",
		"owner": "ThemeDB",
		"resource":
		fallback.resource_path if not fallback.resource_path.is_empty() else "<built-in>",
	}


static func _semantic_control_id(control: Control) -> String:
	match String(control.name):
		"BtnImport":
			return "campaign.import"
		"Value":
			return "text-entry.value"
		"Cancel":
			return "text-entry.cancel"
		"Confirm":
			return "text-entry.confirm"
	return ""


func _overrun_behavior(control: Control) -> Variant:
	for property: Dictionary in control.get_property_list():
		if property["name"] == "text_overrun_behavior":
			return control.get("text_overrun_behavior")
	return null
