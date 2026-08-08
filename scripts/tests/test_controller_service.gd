extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_controller_service.gd
#
# Covers Slice 2 of the mobile-web controller: the action allow-list, press
# reference counting, lifecycle release, profile swapping, and the shell bridge
# protocol. Everything here is headless — the browser half is covered by
# tools/web/controller_shell.test.mjs.

const ControllerActionRegistryS = preload("res://scripts/resources/ControllerActionRegistry.gd")
const ControllerPressLedgerS = preload("res://scripts/resources/ControllerPressLedger.gd")
const ControllerWebBridgeS = preload("res://scripts/shared/ControllerWebBridge.gd")
const ControllerServiceS = preload("res://scripts/autoloads/ControllerService.gd")

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
	print("=== Controller Service Test ===")

	_test_registry()
	_test_ledger()
	_test_bridge_parsing()
	await _test_service()

	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_registry() -> void:
	var registry := ControllerActionRegistryS.new()
	_ok(
		registry.ids_for_profile("virtual_gamepad").size() == 12,
		"virtual gamepad ships a D-pad, four face buttons, two shoulders, start and select"
	)
	_ok(
		registry.ids_for_profile("labeled_actions").size() == 9,
		"labeled actions ship the nine engine-authored controls"
	)
	_ok(
		registry.action_for("act_confirm") == "confirm" and registry.action_for("nope") == "",
		"element ids resolve to actions and unknown ids resolve to nothing"
	)
	for element in registry.default_elements("labeled_actions"):
		if not InputMap.has_action(String(element.action)):
			_ok(false, "descriptor names an action that is not in the InputMap: " + element.id)
			return
	_ok(true, "every labeled-action descriptor names a real InputMap action")

	var errors := registry.register({"id": "act_confirm", "action": "cancel", "label": "Dupe"})
	_ok(
		not errors.is_empty() and registry.action_for("act_confirm") == "confirm",
		"a duplicate id is rejected and cannot repoint an existing element"
	)
	_ok(
		not registry.register({"id": "x", "action": "confirm", "label": "X"}).is_empty(),
		"a descriptor naming no valid profile is rejected"
	)
	_ok(
		not (
			registry
			. register({"id": "y", "action": "", "label": "Y", "profiles": ["off"]})
			. is_empty()
		),
		"an empty action and an invalid profile are both rejected"
	)
	_ok(
		(
			(
				registry
				. register(
					{
						"id": "act_extra",
						"action": "peek_range",
						"label": "Peek",
						"group": "action",
						"profiles": ["labeled_actions"],
					}
				)
				. is_empty()
			)
			and registry.ids_for_profile("labeled_actions").size() == 10
		),
		"a new control is a registry entry, not an engine edit"
	)


func _test_ledger() -> void:
	var ledger := ControllerPressLedgerS.new()

	var first := ledger.press("1", "confirm")
	var second := ledger.press("2", "confirm")
	_ok(
		first.pressed == "confirm" and second.pressed == "",
		"a second finger on the same action does not re-press it"
	)
	_ok(ledger.holders("confirm") == 2, "both pointers are counted")
	_ok(
		ledger.release("1") == "" and ledger.holders("confirm") == 1,
		"releasing one finger leaves the action down for the other"
	)
	_ok(ledger.release("2") == "confirm", "the last release lets the action up")
	_ok(ledger.held_actions().is_empty(), "nothing is held once every pointer is gone")

	_ok(
		(
			ledger.press("3", "cancel").pressed == "cancel"
			and ledger.press("3", "cancel").pressed == ""
		),
		"a repeated pointerdown from the same pointer is idempotent"
	)
	var slid := ledger.press("3", "confirm")
	_ok(
		slid.released == "cancel" and slid.pressed == "confirm" and ledger.holders("cancel") == 0,
		"a pointer sliding to another control releases the first"
	)
	_ok(ledger.release("missing") == "", "releasing an unknown pointer is a no-op")

	ledger.press("4", "cursor_up")
	var dropped := ledger.release_all()
	_ok(
		dropped == ["confirm", "cursor_up"] and ledger.pointer_count() == 0,
		"release_all reports every held action in a stable order"
	)


func _test_bridge_parsing() -> void:
	var press := ControllerWebBridgeS.parse_event(
		'{"type":"press","pointer":"7","element":"act_back"}'
	)
	_ok(
		press.get("type") == "press" and press.get("element") == "act_back",
		"a well-formed press message parses"
	)
	_ok(
		ControllerWebBridgeS.parse_event('{"type":"press","pointer":"7"}').is_empty(),
		"a press with no element is dropped rather than half-applied"
	)
	_ok(
		(
			ControllerWebBridgeS.parse_event('{"type":"evil","pointer":"1"}').is_empty()
			and ControllerWebBridgeS.parse_event("not json").is_empty()
			and ControllerWebBridgeS.parse_event(42).is_empty()
		),
		"unknown types and malformed messages are dropped"
	)
	_ok(
		(
			ControllerWebBridgeS
			. parse_event('{"type":"orientation","orientation":"sideways"}')
			. is_empty()
		),
		"an unknown orientation is dropped"
	)
	_ok(
		ControllerWebBridgeS.parse_event('{"type":"release_all"}').get("type") == "release_all",
		"release_all needs no payload"
	)
	_ok(
		not ControllerWebBridgeS.is_web() and ControllerWebBridgeS.shell_source() != "",
		"the renderer source ships in the project even though this host is not web"
	)


func _test_service() -> void:
	var relay := Node.new()
	root.add_child(relay)
	await process_frame
	var service: Node = relay.get_node_or_null("/root/ControllerService")
	relay.queue_free()
	if service == null:
		_ok(false, "ControllerService autoload is registered")
		return
	_ok(true, "ControllerService autoload is registered")

	service.set_profile("labeled_actions")
	_ok(service.profile() == "labeled_actions", "the profile can be selected")

	# ── allow-list ───────────────────────────────────────────────────────────
	_ok(
		not service.press("p1", "definitely_not_an_element"),
		"an unregistered element id is refused"
	)
	_ok(
		not service.press("p1", "pad_south"),
		"an element from another profile is refused while it is not displayed"
	)
	_ok(
		service.press("p1", "act_confirm") and Input.is_action_pressed("confirm"),
		"a registered element presses its action"
	)

	# A saved layout that claims a different action must not be believed: the
	# registry, not the payload, decides what an element does.
	var tampered: Dictionary = service.active_combination()
	tampered.elements = [
		{
			"id": "act_confirm",
			"action": "debug_toggle_force_levelup",
			"x": 0.5,
			"y": 0.5,
			"scale": 1.0,
			"opacity": 1.0,
		}
	]
	service.apply_combination(tampered)
	_ok(
		not Input.is_action_pressed("confirm"),
		"applying a different combination releases what was held"
	)
	var payload: Dictionary = service.build_payload()
	_ok(
		payload.elements.size() == 1 and payload.elements[0].action == "confirm",
		"a tampered saved action is overridden by the registry"
	)
	service.press("p9", "act_confirm")
	_ok(
		(
			Input.is_action_pressed("confirm")
			and not Input.is_action_pressed("debug_toggle_force_levelup")
		),
		"the tampered element still fires only its registered action"
	)
	service.release("p9")

	# ── payload shape ────────────────────────────────────────────────────────
	# Round-tripping the profile restores the registry defaults, because element
	# ids are profile-specific and cannot carry across.
	service.set_profile("virtual_gamepad")
	service.set_profile("labeled_actions")
	payload = service.build_payload()
	_ok(
		payload.payload_version == 1 and payload.elements.size() == 9,
		"the labeled-actions payload carries every displayed control"
	)
	_ok(
		payload.elements[0].glyph == "",
		"labeled actions carry no pad glyph, so a rebinding cannot reword them"
	)
	_ok(
		payload.colors.surface == "#000000" and payload.colors.button.begins_with("#"),
		"only validated hex colours reach the shell"
	)
	service.set_profile("virtual_gamepad")
	payload = service.build_payload()
	var confirm_glyph := ""
	for element: Dictionary in payload.elements:
		if element.id == "pad_south":
			confirm_glyph = String(element.glyph)
	_ok(
		confirm_glyph != "" and payload.elements.size() == 12,
		"the virtual pad resolves its glyph from the live Confirm binding (%s)" % confirm_glyph
	)

	# ── lifecycle release ────────────────────────────────────────────────────
	service.press("p2", "pad_south")
	service.press("p3", "dpad_up")
	_ok(
		Input.is_action_pressed("confirm") and Input.is_action_pressed("cursor_up"),
		"two controls can be held at once"
	)
	service.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_ok(
		not Input.is_action_pressed("confirm") and not Input.is_action_pressed("cursor_up"),
		"losing focus releases every held action"
	)

	service.press("p4", "pad_south")
	service.set_editing(true)
	_ok(
		not Input.is_action_pressed("confirm") and not service.press("p5", "pad_south"),
		"entering the editor releases held actions and stops accepting presses"
	)
	_ok(service.build_payload().editing, "the payload tells the shell it is editing")
	service.set_editing(false)

	service.press("p6", "pad_south")
	service.set_orientation("portrait")
	_ok(
		not Input.is_action_pressed("confirm"),
		"rotating releases actions held under the previous layout"
	)
	service.set_orientation("landscape")

	service.press("p7", "pad_south")
	service.set_profile("labeled_actions")
	_ok(
		not Input.is_action_pressed("confirm") and service.held_actions().is_empty(),
		"switching profile releases what the old profile was holding"
	)

	# ── the shell protocol end to end ────────────────────────────────────────
	var pressed := ControllerWebBridgeS.dispatch(
		service,
		ControllerWebBridgeS.parse_event('{"type":"press","pointer":"js1","element":"act_menu"}')
	)
	_ok(
		pressed and Input.is_action_pressed("open_menu"),
		"a shell press message reaches the InputMap"
	)
	_ok(
		not ControllerWebBridgeS.dispatch(service, ControllerWebBridgeS.parse_event("garbage")),
		"a malformed shell message changes nothing"
	)
	ControllerWebBridgeS.dispatch(
		service, ControllerWebBridgeS.parse_event('{"type":"release_all"}')
	)
	_ok(
		not Input.is_action_pressed("open_menu") and service.held_actions().is_empty(),
		"a shell release_all clears the ledger"
	)
	_ok(
		JSON.parse_string(service.payload_json()) != null,
		"the payload serializes to JSON for the bridge"
	)
