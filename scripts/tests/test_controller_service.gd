extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_controller_service.gd
#
# Covers Slice 2 of the mobile-web controller: the action allow-list, press
# reference counting, lifecycle release, profile swapping, and the shell bridge
# protocol. Everything here is headless — the browser half is covered by
# tools/web/controller_shell.test.mjs.

const ControllerActionRegistryS = preload("res://scripts/resources/ControllerActionRegistry.gd")
const ControllerLayoutS = preload("res://scripts/resources/ControllerLayout.gd")
const ControllerPressLedgerS = preload("res://scripts/resources/ControllerPressLedger.gd")
const ControllerWebBridgeS = preload("res://scripts/shared/ControllerWebBridge.gd")
const ControllerServiceS = preload("res://scripts/autoloads/ControllerService.gd")


# Stands in for the SettingsManager autoload so the persistence round-trip can be
# proven without writing user://settings.cfg — test_settings_manager.gd reads that
# file back in the same parallel run, and two suites racing on it is contention,
# not a defect. The cfg round-trip of the two new keys is covered there instead.
class StubSettings:
	extends Node
	signal settings_changed

	var controller_combinations: Array = []
	var controller_active_id: String = ""
	var saves: int = 0

	func save() -> void:
		saves += 1
		settings_changed.emit()


# The service with its settings lookup pointed at the stub. Everything else — the
# model, the selection rules, the payload — is the production code path.
class ProbeService:
	extends ControllerServiceS

	var stub: Node = null

	func _settings_node() -> Node:
		return stub


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
	await _test_persistence()
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


# Slice 4, step 1. The service used to rebuild ControllerLayout.default_collection()
# on every launch, so a profile change or a moved control lasted exactly one
# session — every other control setting was durable and this one was not.
func _test_persistence() -> void:
	var stub := StubSettings.new()
	var service := ProbeService.new()
	service.stub = stub
	root.add_child(stub)
	root.add_child(service)
	await process_frame

	_ok(
		service.combinations().size() == ControllerLayoutS.DEFAULT_SLOT_COUNT,
		"an empty save falls back to the built-in collection"
	)
	_ok(
		service.active_combination_id().is_empty(),
		"with nothing saved no slot is chosen, so the orientation decides"
	)

	# ── choosing a slot ──────────────────────────────────────────────────────
	var slots: Array[Dictionary] = service.combinations()
	var portrait_slot_id := ""
	var landscape_slot_id := ""
	for slot in slots:
		if String(slot.orientation) == "portrait" and portrait_slot_id.is_empty():
			portrait_slot_id = String(slot.id)
		if String(slot.orientation) == "landscape" and landscape_slot_id.is_empty():
			landscape_slot_id = String(slot.id)
	_ok(
		not portrait_slot_id.is_empty() and not landscape_slot_id.is_empty(),
		"the built-in collection offers a slot pinned to each orientation"
	)

	_ok(
		not service.select_combination("no-such-slot"),
		"an id no slot carries is refused rather than blanking the controls"
	)
	_ok(
		service.active_combination_id().is_empty(),
		"the refused selection left the previous choice alone"
	)
	_ok(
		(
			service.select_combination(landscape_slot_id)
			and String(service.active_combination().id) == landscape_slot_id
		),
		"a saved slot can be chosen by id"
	)

	# A landscape-pinned slot cannot serve a portrait screen: its viewport and
	# element fractions were authored for the other shape.
	service.set_orientation("portrait")
	_ok(
		String(service.active_combination().id) != landscape_slot_id,
		"a landscape-pinned choice is not applied to a portrait screen"
	)
	service.set_orientation("landscape")
	_ok(
		String(service.active_combination().id) == landscape_slot_id,
		"rotating back restores the choice rather than discarding it"
	)

	# ── committing an edit ───────────────────────────────────────────────────
	service.set_profile("virtual_gamepad")
	_ok(
		service.active_combination().elements.is_empty(),
		"a profile change leaves elements empty so registry placements are not frozen"
	)
	service.commit_active_combination()
	var committed_count := 0
	for slot in service.combinations():
		if String(slot.id) == landscape_slot_id and String(slot.profile) == "virtual_gamepad":
			committed_count += 1
	_ok(committed_count == 1, "committing writes the edit back into its own slot only")

	# Editing the combination the orientation picked must not pin it: a player who
	# changes control style on Automatic would otherwise stop rotating between
	# layouts, and nothing would tell them why.
	service.select_combination("")
	var automatic_slot_id := String(service.active_combination().id)
	service.set_profile("labeled_actions")
	service.commit_active_combination()
	_ok(
		service.active_combination_id().is_empty(),
		"committing an edit on Automatic does not silently pin the arrangement"
	)
	var automatic_committed := false
	for slot in service.combinations():
		if String(slot.id) == automatic_slot_id and String(slot.profile) == "labeled_actions":
			automatic_committed = true
	_ok(automatic_committed, "the edit still reached the slot the orientation picked")
	service.select_combination(landscape_slot_id)
	service.set_profile("virtual_gamepad")
	service.commit_active_combination()

	var invented: Dictionary = service.active_combination()
	invented.id = "player-made-slot"
	service.apply_combination(invented)
	service.commit_active_combination()
	_ok(
		(
			service.combinations().size() == ControllerLayoutS.DEFAULT_SLOT_COUNT + 1
			and service.active_combination_id() == "player-made-slot"
		),
		"committing a combination the collection has not seen adds it as a new slot"
	)

	# ── the round trip that was missing ──────────────────────────────────────
	service.select_combination(landscape_slot_id)
	service.save_layout()
	_ok(
		stub.saves == 1 and stub.controller_active_id == landscape_slot_id,
		"save_layout writes the chosen slot through to settings and persists once"
	)
	_ok(
		stub.controller_combinations.size() == ControllerLayoutS.DEFAULT_SLOT_COUNT + 1,
		"save_layout writes the whole collection, not just the active slot"
	)

	var reloaded := ProbeService.new()
	reloaded.stub = stub
	root.add_child(reloaded)
	await process_frame
	_ok(
		(
			reloaded.active_combination_id() == landscape_slot_id
			and String(reloaded.active_combination().profile) == "virtual_gamepad"
		),
		"a fresh launch restores the chosen slot and its profile"
	)
	_ok(
		reloaded.combinations().size() == ControllerLayoutS.DEFAULT_SLOT_COUNT + 1,
		"a fresh launch restores the player-made slot too"
	)

	# ── the echo guard ───────────────────────────────────────────────────────
	# Reloading emits layout_changed, which makes the shell rebuild every button
	# and drops whatever is held. The service's own save must not trigger that.
	var rebuilds := [0]
	reloaded.layout_changed.connect(func(_payload: Dictionary) -> void: rebuilds[0] += 1)
	reloaded.save_layout()
	_ok(rebuilds[0] == 0, "the service ignores the settings_changed echo of its own save")

	# A Controls reset clears both keys, and that IS an external change.
	stub.controller_combinations = []
	stub.controller_active_id = ""
	stub.save()
	_ok(
		(
			rebuilds[0] > 0
			and reloaded.active_combination_id().is_empty()
			and reloaded.combinations().size() == ControllerLayoutS.DEFAULT_SLOT_COUNT
		),
		"an external settings change reloads the layout"
	)

	# A corrupt cfg costs the customisation and nothing else.
	stub.controller_combinations = ["not a combination", 7, {"schema_version": 99}]
	stub.controller_active_id = "gone"
	stub.save()
	_ok(
		(
			reloaded.combinations().size() == 3
			and not reloaded.active_combination().is_empty()
			and reloaded.build_payload().elements.size() > 0
		),
		"unusable saved entries normalize to defaults instead of leaving no controls"
	)

	service.queue_free()
	reloaded.queue_free()
	stub.queue_free()
	await process_frame


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

	# ── the canvas rectangle ─────────────────────────────────────────────────
	# Slice 1: with canvas_resize_policy=0 the shell owns the canvas, so the model
	# has to turn "the window is 844x390" into real pixels the shell can apply.
	_ok(
		service.canvas_rect_json().is_empty(),
		"no canvas rect is published before the window size is known"
	)
	_ok(
		(
			ControllerWebBridgeS.parse_event('{"type":"metrics","width":844,"height":390}').get(
				"width"
			)
			== 844.0
		),
		"a metrics message parses"
	)
	_ok(
		(
			ControllerWebBridgeS.parse_event('{"type":"metrics","width":0,"height":390}').is_empty()
			and (
				ControllerWebBridgeS
				. parse_event('{"type":"metrics","width":-8,"height":390}')
				. is_empty()
			)
			and (
				ControllerWebBridgeS
				. parse_event('{"type":"metrics","width":"wide","height":390}')
				. is_empty()
			)
		),
		"a zero, negative, or non-numeric window is rejected rather than applied"
	)

	var moved := ControllerWebBridgeS.dispatch(
		service, ControllerWebBridgeS.parse_event('{"type":"metrics","width":844,"height":390}')
	)
	_ok(moved, "a metrics message is accepted once")
	_ok(
		not ControllerWebBridgeS.dispatch(
			service, ControllerWebBridgeS.parse_event('{"type":"metrics","width":844,"height":390}')
		),
		"an unchanged window size reports no change, so the canvas is not re-applied"
	)

	# Landscape default is the full window: the controller overlays it, which is
	# the pre-existing behaviour and must not regress.
	var landscape_rect: Rect2 = service.canvas_rect()
	_ok(
		landscape_rect.size.is_equal_approx(Vector2(844.0, 390.0)),
		"the landscape default fills the window"
	)

	# Portrait is the case the reference targets: the canvas takes the top slice and
	# the rest of the screen becomes dedicated controller space.
	service.set_orientation("portrait")
	ControllerWebBridgeS.dispatch(
		service, ControllerWebBridgeS.parse_event('{"type":"metrics","width":390,"height":844}')
	)
	var portrait_rect: Rect2 = service.canvas_rect()
	_ok(
		portrait_rect.size.y < 844.0 * 0.75 and portrait_rect.size.y > 0.0,
		"the portrait canvas leaves most of the lower screen free for controls"
	)
	_ok(
		(
			portrait_rect.position.x >= 0.0
			and portrait_rect.position.y >= 0.0
			and portrait_rect.position.x + portrait_rect.size.x <= 390.0
			and portrait_rect.position.y + portrait_rect.size.y <= 844.0
		),
		"the canvas rect stays inside the window"
	)
	var decoded: Variant = JSON.parse_string(service.canvas_rect_json())
	_ok(
		decoded is Dictionary and decoded.has("x") and decoded.has("width"),
		"the canvas rect serializes for the shell"
	)

	# ── Game View settings override ──────────────────────────────────────────
	var sm := service.get_node_or_null("/root/SettingsManager")
	if sm != null:
		var restore_preset: String = sm.game_view_preset
		var restore_size: float = sm.game_view_size
		var restore_offset: float = sm.game_view_offset

		# "auto" must leave the layout preset's own viewport alone — that is what
		# keeps this setting additive instead of flattening every combination.
		sm.game_view_preset = "auto"
		var auto_rect: Rect2 = service.canvas_rect()
		_ok(auto_rect.size.y < 844.0 * 0.75, "Automatic defers to the layout's own portrait band")

		sm.game_view_preset = "custom"
		# Above the model's 360px minimum, so this exercises the setting rather
		# than the floor clamp.
		sm.game_view_size = 0.7
		sm.game_view_offset = 0.0
		var custom_rect: Rect2 = service.canvas_rect()
		_ok(
			absf(custom_rect.size.y - 844.0 * 0.7) < 2.0,
			"a custom size resizes the portrait canvas"
		)

		# The override must not be written back into the combination, or coming
		# back to Automatic would keep the last custom rect forever.
		sm.game_view_preset = "auto"
		_ok(
			service.canvas_rect().size.is_equal_approx(auto_rect.size),
			"switching back to Automatic restores the layout's rect"
		)

		sm.game_view_preset = "custom"
		_ok(
			sm.normalize_game_view_offset(0.9, 0.5) <= 0.5,
			"an offset that would push the canvas off-screen is clamped against the size"
		)
		_ok(
			(
				sm.normalize_game_view_size("wide") == 1.0
				and sm.normalize_game_view_preset("nonsense") == "auto"
			),
			"malformed Game View values fall back instead of being applied"
		)

		var portrait_view: Dictionary = sm.game_view_viewport("portrait", 0.55, 0.03, false)
		var landscape_view: Dictionary = sm.game_view_viewport("landscape", 0.55, 0.2, false)
		_ok(
			(
				is_equal_approx(float(portrait_view.width), 1.0)
				and is_equal_approx(float(portrait_view.height), 0.55)
				and is_equal_approx(float(landscape_view.height), 1.0)
				and is_equal_approx(float(landscape_view.width), 0.55)
			),
			"portrait bands vertically and landscape pillars horizontally"
		)

		sm.game_view_preset = restore_preset
		sm.game_view_size = restore_size
		sm.game_view_offset = restore_offset
