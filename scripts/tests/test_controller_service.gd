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
	var controller_auto_hide_seconds: float = 0.0
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
	await _test_element_editing()
	await _test_optional_controls()

	await _test_gui_reach()
	await _test_tap_outlives_its_frame()
	await _test_modal_reach()

	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


# The d-pad is only worth having if it can work a menu. `Input.action_press()`
# sets the polled action state and synthesizes no event, so before this the whole
# controller could drive the map and none of it could move a focus highlight —
# and the Control Style row that switches profiles lives behind a menu.
func _test_gui_reach() -> void:
	var relay := Node.new()
	root.add_child(relay)
	await process_frame
	var service: Node = relay.get_node_or_null("/root/ControllerService")
	relay.queue_free()
	if service == null:
		_ok(false, "ControllerService autoload is registered for the GUI-reach test")
		return

	var column := VBoxContainer.new()
	var first := Button.new()
	first.text = "first"
	var second := Button.new()
	second.text = "second"
	var activations := [0]
	second.pressed.connect(func() -> void: activations[0] += 1)
	column.add_child(first)
	column.add_child(second)
	root.add_child(column)
	await process_frame
	first.grab_focus()
	await process_frame

	service.set_profile("labeled_actions")
	service.press("g1", "act_down")
	await process_frame
	service.release("g1")
	await process_frame
	var focused: Control = root.gui_get_focus_owner()
	_ok(
		focused == second,
		"a labeled-actions direction moves the focus highlight, so a menu is navigable"
	)

	service.press("g2", "act_confirm")
	await process_frame
	service.release("g2")
	await process_frame
	_ok(activations[0] == 1, "Confirm activates the focused control exactly once")

	# The virtual pad reaches the GUI through the same seam.
	first.grab_focus()
	await process_frame
	service.set_profile("virtual_gamepad")
	service.press("g3", "dpad_down")
	await process_frame
	service.release("g3")
	await process_frame
	_ok(
		root.gui_get_focus_owner() == second,
		"the virtual pad's D-pad moves focus through the same seam"
	)

	# An action with no mirrored ui_* counterpart must not reach the GUI at all.
	first.grab_focus()
	await process_frame
	service.press("g4", "act_zoom_in")
	await process_frame
	service.release("g4")
	await process_frame
	_ok(
		root.gui_get_focus_owner() == first and activations[0] == 1,
		"an unmirrored action drives gameplay only and leaves focus alone"
	)

	service.release_all_actions()
	column.queue_free()
	await process_frame


# Reaching Godot's GUI (above) is only half of it: every screen in `scripts/ui/`
# reads its OWN vocabulary — `cancel`, `confirm`, `open_menu`, `inspect_unit` —
# out of `_input`/`_unhandled_input`, and none of that is a `ui_*` action. A
# controller that delivered only the mirrored `ui_*` event could move a focus
# highlight and could not close the screen it was standing in.
#
# Driven through a real modal, because that is where both halves have to work at
# once and where the defect was found (2026-08-05, on a phone: Settings opened and
# could not be left).
func _test_modal_reach() -> void:
	var relay := Node.new()
	root.add_child(relay)
	await process_frame
	var service: Node = relay.get_node_or_null("/root/ControllerService")
	relay.queue_free()
	if service == null:
		_ok(false, "ControllerService autoload is registered for the modal-reach test")
		return

	var screen: Control = load("res://scenes/ui/SettingsScreen.tscn").instantiate()
	var backs := [0]
	root.add_child(screen)
	screen.back_pressed.connect(func() -> void: backs[0] += 1)
	await process_frame
	screen.open()
	await process_frame
	await process_frame
	var opened_on: Control = root.gui_get_focus_owner()
	service.set_profile("labeled_actions")

	await _tap(service, "act_down")
	_ok(
		root.gui_get_focus_owner() != opened_on and root.gui_get_focus_owner() != null,
		"a tap on the d-pad steps focus inside a modal, which polls rather than listens"
	)

	await _tap(service, "act_back")
	_ok(
		not screen.visible and backs[0] == 1,
		"a tap on Back closes the modal exactly once, through the game's `cancel` action"
	)

	# Confirm on a focused button is the one case where the GUI and a screen-level
	# handler could both answer the same tap. The `ui_*` event goes first precisely
	# so the second one lands on an already-closed screen.
	screen.open()
	await process_frame
	await process_frame
	await _tap(service, "act_confirm")
	_ok(
		not screen.visible and backs[0] == 2,
		"Confirm on the focused Back button fires it once, not once per injected event"
	)

	service.release_all_actions()
	screen.queue_free()
	await process_frame


# One tap with both pointer events inside a single frame — the shape a browser
# produces, since the shell's pointerdown and pointerup arrive as JavaScript
# callbacks between engine frames.
func _tap(service: Node, element_id: String) -> void:
	service.press("tap", element_id)
	service.release("tap")
	await process_frame
	await process_frame
	await process_frame


# The release above must survive the frame its press landed on. A polling consumer
# reads `is_action_pressed()` once per frame, so a press that goes up and back down
# between two polls is not a fast tap — it never happened.
func _test_tap_outlives_its_frame() -> void:
	var relay := Node.new()
	root.add_child(relay)
	await process_frame
	var service: Node = relay.get_node_or_null("/root/ControllerService")
	relay.queue_free()
	if service == null:
		_ok(false, "ControllerService autoload is registered for the tap-timing test")
		return
	service.set_profile("labeled_actions")

	service.press("f1", "act_down")
	service.release("f1")
	_ok(
		Input.is_action_pressed("cursor_down") and service.held_actions().is_empty(),
		"a release in the press's own frame is held back, so one poll still sees it"
	)
	await process_frame
	await process_frame
	_ok(not Input.is_action_pressed("cursor_down"), "the held-back release lands next frame")

	# Lifecycle releases are the exception: a release still pending when the tab
	# blurs or the scene changes is the stuck action this service exists to prevent.
	service.press("f2", "act_down")
	service.release("f2")
	service.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_ok(
		not Input.is_action_pressed("cursor_down"),
		"losing focus lets go at once instead of waiting for a frame that may not come"
	)
	await process_frame


func _test_registry() -> void:
	var registry := ControllerActionRegistryS.new()
	_ok(
		registry.ids_for_profile("virtual_gamepad").size() == 12,
		"virtual gamepad ships a D-pad, four face buttons, two shoulders, start and select"
	)
	_ok(
		registry.ids_for_profile("labeled_actions").size() == 13,
		"labeled actions ship the nine engine-authored controls plus a directional cross"
	)
	# Owner call 2026-08-05: BOTH profiles carry a d-pad. Menu navigation runs on
	# ui_up/ui_down, which only the cursor_* actions mirror, so a profile without
	# them renders controls that cannot move a highlight — and the profile selector
	# that would fix it lives behind a menu the player then cannot reach.
	for probe_profile in ControllerActionRegistryS.VALID_PROFILES:
		var directional: Dictionary = {}
		for id in registry.ids_for_profile(probe_profile):
			directional[String(registry.descriptor(id).action)] = true
		_ok(
			(
				directional.has("cursor_up")
				and directional.has("cursor_down")
				and directional.has("cursor_left")
				and directional.has("cursor_right")
			),
			"profile %s can move a menu highlight in all four directions" % probe_profile
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
			and registry.ids_for_profile("labeled_actions").size() == 14
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

	# ── Slice 4 step 3: the editing messages ─────────────────────────────────
	var moved := ControllerWebBridgeS.parse_event(
		'{"type":"move","element":"act_back","x":0.25,"y":0.75}'
	)
	_ok(
		(
			moved.get("element") == "act_back"
			and is_equal_approx(float(moved.get("x", 0.0)), 0.25)
			and is_equal_approx(float(moved.get("y", 0.0)), 0.75)
		),
		"a well-formed move message parses"
	)
	# 0.0 is a real position — the top-left corner — so a coordinate that is
	# missing, non-numeric or non-finite has to be DROPPED rather than defaulted,
	# or a malformed drag teleports the control instead of doing nothing.
	_ok(
		(
			(
				ControllerWebBridgeS
				. parse_event('{"type":"move","element":"act_back","x":0.5}')
				. is_empty()
			)
			and (
				ControllerWebBridgeS
				. parse_event('{"type":"move","element":"act_back","x":"0.5","y":0.5}')
				. is_empty()
			)
			and (
				ControllerWebBridgeS
				. parse_event('{"type":"move","element":"act_back","x":null,"y":0.5}')
				. is_empty()
			)
			and ControllerWebBridgeS.parse_event('{"type":"move","x":0.5,"y":0.5}').is_empty()
		),
		"a move missing an element or either coordinate is dropped, not defaulted to a corner"
	)
	_ok(
		(
			ControllerWebBridgeS.parse_event('{"type":"select","element":"act_back"}').get(
				"element"
			)
			== "act_back"
		),
		"a select message parses"
	)
	_ok(
		(
			ControllerWebBridgeS.parse_event('{"type":"select"}').get("type") == "select"
			and ControllerWebBridgeS.parse_event('{"type":"select"}').get("element") == ""
		),
		"a select with no element is the deselect message, not a malformed one"
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
		payload.payload_version == 1 and payload.elements.size() == 13,
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


# Slice 4, step 3. Position is dragged in the browser and reported once on
# release; size and opacity are Settings sliders acting on the tapped control.
# The trap the whole feature turns on: an empty element list means "follow the
# registry placement", so the FIRST edit has to freeze the whole placement — a
# layout carrying only the element that moved is the entire controller gone in
# one drag, and the Reset that would undo it is behind a menu the player can no
# longer navigate to.
func _test_element_editing() -> void:
	var stub := StubSettings.new()
	var service := ProbeService.new()
	service.stub = stub
	root.add_child(stub)
	root.add_child(service)
	await process_frame

	service.set_profile("labeled_actions")
	var drawn: int = service.build_payload().elements.size()
	_ok(drawn > 1, "the labeled-action profile draws more than one control to begin with")
	_ok(
		service.active_combination().elements.is_empty(),
		"an unedited combination saves no elements, so it follows the registry placement"
	)

	# ── the materialization trap ─────────────────────────────────────────────
	_ok(service.move_element("act_back", 0.25, 0.75), "a registered control can be dragged")
	_ok(
		service.build_payload().elements.size() == drawn,
		"moving ONE control freezes them all rather than leaving a layout of one"
	)
	var moved: Dictionary = service.element_layout("act_back")
	_ok(
		is_equal_approx(float(moved.get("x", 0.0)), 0.25),
		"the dragged control kept the position it was dropped at"
	)
	var untouched: Dictionary = service.element_layout("act_confirm")
	var confirm_default: Dictionary = {}
	for element: Dictionary in service.registry.default_elements("labeled_actions", "landscape"):
		if String(element.id) == "act_confirm":
			confirm_default = element
	_ok(
		is_equal_approx(float(untouched.get("x", -1.0)), float(confirm_default.get("x", -2.0))),
		"a control nobody dragged still sits at its registry default"
	)

	# ── the allow-list applies to editing, not only to pressing ──────────────
	_ok(
		not service.move_element("not_a_control", 0.5, 0.5),
		"an unregistered element id cannot be moved"
	)
	_ok(
		not service.move_element("pad_south", 0.5, 0.5),
		"a control belonging to the other profile cannot be moved"
	)
	_ok(
		not service.move_element("act_back", NAN, 0.5),
		"a non-finite coordinate is refused rather than clamped to a corner"
	)

	# ── clamping ─────────────────────────────────────────────────────────────
	_ok(service.set_element_scale("act_back", 99.0), "an out-of-range scale is accepted")
	_ok(
		is_equal_approx(
			float(service.element_layout("act_back").get("scale", 0.0)),
			ControllerLayoutS.MAX_ELEMENT_SCALE
		),
		"...and clamped to the model bound the Settings slider is built from"
	)
	_ok(service.set_element_opacity("act_back", 0.0), "a fully transparent control is accepted")
	_ok(
		is_equal_approx(
			float(service.element_layout("act_back").get("opacity", 0.0)),
			ControllerLayoutS.MIN_ELEMENT_OPACITY
		),
		"...and floored, because an invisible control is a dead zone nobody can find again"
	)

	# ── selection ────────────────────────────────────────────────────────────
	_ok(service.select_element("act_back"), "a drawn control can be selected")
	_ok(
		service.build_payload().selected == "act_back",
		"the payload tells the shell what to outline"
	)
	_ok(
		not service.select_element("pad_south"),
		"a control the active profile does not draw cannot be selected"
	)
	_ok(
		service.selected_element_id() == "act_back",
		"the refused selection left the previous one alone"
	)
	_ok(
		service.select_element("") and service.selected_element_id().is_empty(),
		"an empty id is the deselect, not a failure"
	)

	# THE DEFECT A REAL EXPORT FOUND. Selecting used to publish a layout, and a
	# layout makes the shell rebuild every control — so the tap that begins a
	# drag destroyed the node being dragged on its own first frame. Headless and
	# the stub-canvas suite both passed, because neither has an engine
	# republishing underneath the gesture. Selection therefore travels on its own
	# signal, exactly as the canvas rect already does.
	var layouts: Array[Dictionary] = []
	var selections: Array[String] = []
	service.layout_changed.connect(func(payload: Dictionary) -> void: layouts.append(payload))
	service.selection_changed.connect(func(id: String) -> void: selections.append(id))
	service.select_element("act_confirm")
	_ok(
		layouts.is_empty() and selections == ["act_confirm"],
		"selecting reports a selection and NOT a layout, so a drag survives its own first frame"
	)
	# Moving is a real layout change and must still publish one, or the control
	# would snap back to where the engine still thinks it is.
	service.move_element("act_confirm", 0.4, 0.4)
	_ok(layouts.size() == 1, "moving a control does publish a layout")

	# ── persistence ──────────────────────────────────────────────────────────
	service.select_element("act_back")
	var saves_before: int = stub.saves
	service.commit_element_edit()
	_ok(stub.saves > saves_before, "a finished edit is written to settings")
	var stored_elements := 0
	for combination: Dictionary in stub.controller_combinations:
		if String(combination.get("id", "")) == String(service.active_combination().id):
			stored_elements = (combination.get("elements", []) as Array).size()
	_ok(stored_elements == drawn, "the whole frozen placement reached the saved slot")

	# ── reset ────────────────────────────────────────────────────────────────
	service.reset_elements()
	_ok(
		service.active_combination().elements.is_empty(),
		"Reset clears the overrides instead of writing today's defaults into the slot"
	)
	_ok(
		service.build_payload().elements.size() == drawn,
		"...and the controls come back from the registry, all of them"
	)
	_ok(
		service.selected_element_id().is_empty(),
		"Reset drops the selection with the layout it named"
	)

	# ── a profile change invalidates every element id ────────────────────────
	service.move_element("act_back", 0.3, 0.3)
	service.select_element("act_back")
	service.set_profile("virtual_gamepad")
	_ok(
		service.selected_element_id().is_empty(),
		"switching control style clears a selection that named the old style's control"
	)
	_ok(
		service.active_combination().elements.is_empty(),
		"...and clears the frozen placement, whose ids the new profile does not draw"
	)

	# ── the same edits arriving over the bridge ──────────────────────────────
	service.set_profile("labeled_actions")
	_ok(
		(
			ControllerWebBridgeS.dispatch(
				service, ControllerWebBridgeS.parse_event('{"type":"select","element":"act_back"}')
			)
			and service.selected_element_id() == "act_back"
		),
		"a tap on a control in the editor selects it through the bridge"
	)
	var saves_at_drag: int = stub.saves
	_ok(
		(
			ControllerWebBridgeS.dispatch(
				service,
				ControllerWebBridgeS.parse_event(
					'{"type":"move","element":"act_back","x":0.9,"y":0.1}'
				)
			)
			and is_equal_approx(float(service.element_layout("act_back").get("y", 0.0)), 0.1)
		),
		"a finger lifting off a dragged control moves it through the bridge"
	)
	# The drag is reported once, on release, so THAT is the moment it is durable —
	# there is no other commit path behind it.
	_ok(stub.saves > saves_at_drag, "...and that one report is what persists the drag")

	service.queue_free()
	stub.queue_free()
	await process_frame


# Slice 4 step 4: which controls are drawn at all, and how long they stay drawn.
#
# Both halves exist to give a small screen back to the game, and both carry the
# same failure if they are trusted blindly — a control the player cannot see is a
# control they cannot use to undo whatever hid it. That is why one set of controls
# cannot be turned off and why a faded control stops taking touches entirely.
func _test_optional_controls() -> void:
	var stub := StubSettings.new()
	var service := ProbeService.new()
	service.stub = stub
	root.add_child(stub)
	root.add_child(service)
	await process_frame

	service.set_profile("labeled_actions")
	var drawn: int = service.build_payload().elements.size()

	# ── the registry names what may not be removed ───────────────────────────
	_ok(
		service.registry.is_required("act_back") and service.registry.is_required("act_up"),
		"Back and the directional cross declare themselves required"
	)
	_ok(
		not service.registry.is_required("act_zoom_in"),
		"a convenience control does not, so it can be removed"
	)
	_ok(
		not service.registry.is_required("not_a_control"),
		"an unregistered id is not required — it names nothing that could be drawn"
	)

	# ── turning one off ──────────────────────────────────────────────────────
	_ok(service.set_element_enabled("act_zoom_in", false), "an optional control can be hidden")
	_ok(
		not _payload_ids(service).has("act_zoom_in"),
		"...and the shell is no longer told to draw it"
	)
	_ok(
		service.build_payload().elements.size() == drawn - 1,
		"...and only that one control went away"
	)
	# The same materialization trap the drag has: an empty element list means
	# "follow the registry", so the first toggle must freeze the whole placement
	# or hiding Zoom would take every other control with it.
	_ok(
		service.active_combination().elements.size() == drawn,
		"hiding ONE control freezes them all rather than leaving a layout of one"
	)
	_ok(
		(
			service.set_element_enabled("act_zoom_in", true)
			and _payload_ids(service).has("act_zoom_in")
		),
		"and it comes back"
	)

	# ── what may not be turned off ───────────────────────────────────────────
	_ok(
		not service.set_element_enabled("act_back", false),
		"a required control refuses to be hidden"
	)
	_ok(_payload_ids(service).has("act_back"), "...and stays drawn")

	# THE FAIL-CLOSED HALF. `set_element_enabled()` answers to the UI; a cfg edited
	# by hand answers to nothing, and a saved layout that hid Back would leave a
	# phone that cannot leave a menu holding the only row that would undo it. So
	# the payload filter, not the setter, has the last word.
	var tampered: Dictionary = service.active_combination()
	var elements: Array = tampered.elements
	for index in elements.size():
		var element: Dictionary = elements[index]
		if String(element.get("id", "")) in ["act_back", "act_up"]:
			element["enabled"] = false
			elements[index] = element
	tampered.elements = elements
	service.apply_combination(tampered)
	var after_tamper := _payload_ids(service)
	_ok(
		after_tamper.has("act_back") and after_tamper.has("act_up"),
		"a saved layout that hides a required control is overruled, not obeyed"
	)

	# ── the list the Settings row is built from ──────────────────────────────
	service.set_profile("labeled_actions")
	service.set_element_enabled("act_zoom_out", false)
	var listed := service.profile_elements()
	_ok(
		listed.size() == service.registry.ids_for_profile("labeled_actions").size(),
		"every control the profile can draw is offered, not only the drawn ones"
	)
	var hidden_entry: Dictionary = {}
	var required_entry: Dictionary = {}
	for entry: Dictionary in listed:
		if String(entry.id) == "act_zoom_out":
			hidden_entry = entry
		if String(entry.id) == "act_back":
			required_entry = entry
	_ok(
		not bool(hidden_entry.get("enabled", true)),
		"a hidden control is still listed — that list is the only way back to it"
	)
	_ok(
		bool(required_entry.get("required", false)),
		"...and a required one is marked, so the row can disable itself instead of failing"
	)
	# ── auto-hide is a setting, and it travels with the payload ──────────────
	_ok(
		is_equal_approx(float(service.build_payload().auto_hide_seconds), 0.0),
		"auto-hide is off by default, so nothing changes for a player who never asks"
	)
	stub.controller_auto_hide_seconds = 5.0
	_ok(
		is_equal_approx(float(service.build_payload().auto_hide_seconds), 5.0),
		"a chosen delay reaches the shell in the payload a fresh boot renders from"
	)
	stub.controller_auto_hide_seconds = 9.0
	_ok(
		is_equal_approx(service.auto_hide_seconds(), 10.0),
		"a delay no dropdown offers snaps to one that is, rather than living on unreachable"
	)
	# An exact tie takes the shorter delay. Arbitrary either way, but only if it is
	# decided once: a comparison that let the later choice win on equality would
	# make the answer depend on the order of the constant.
	stub.controller_auto_hide_seconds = 7.5
	_ok(is_equal_approx(service.auto_hide_seconds(), 5.0), "...and a tie resolves to the shorter")

	# Its own signal, for the third time and the third time for the same reason:
	# a republished layout rebuilds every control, and rebuilding them to change a
	# timeout would drop whatever a second finger is holding.
	var layouts: Array[Dictionary] = []
	var delays: Array[float] = []
	service.layout_changed.connect(func(payload: Dictionary) -> void: layouts.append(payload))
	service.auto_hide_changed.connect(func(seconds: float) -> void: delays.append(seconds))
	stub.controller_auto_hide_seconds = 3.0
	service.refresh_auto_hide()
	_ok(
		layouts.is_empty() and delays.size() == 1 and is_equal_approx(delays[0], 3.0),
		"changing the delay reports a delay and NOT a layout"
	)

	service.queue_free()
	stub.queue_free()
	await process_frame


func _payload_ids(service: Node) -> Array[String]:
	var ids: Array[String] = []
	for element: Dictionary in service.build_payload().elements:
		ids.append(String(element.id))
	return ids
