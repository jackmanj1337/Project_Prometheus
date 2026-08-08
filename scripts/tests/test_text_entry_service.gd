extends SceneTree

const TextEntryServiceScript = preload("res://scripts/autoloads/TextEntryService.gd")

var passed := 0
var failed := 0


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, label: String) -> void:
	if condition:
		print("OK  %s" % label)
		passed += 1
	else:
		print("FAIL %s" % label)
		failed += 1


func _run() -> void:
	var service := TextEntryServiceScript.new()
	service.name = "TextEntryService"
	root.add_child(service)
	var first := LineEdit.new()
	first.text = "A"
	root.add_child(first)
	var second := LineEdit.new()
	second.text = "B"
	root.add_child(second)
	await process_frame

	var request := TextEntryRequest.for_purpose(TextEntryRequest.Purpose.NAME)
	request.target = first
	request.host_viewport = root
	_check(service.begin(request, &"grid"), "service opens the prebuilt grid keyboard")
	await process_frame
	_check(
		service.session.active and service.active_mode == &"grid",
		"service owns the active grid session"
	)
	_check(
		root.get_node_or_null("GridKeyboard") != null,
		"grid keyboard scene is hosted in the requested viewport"
	)
	service.session.insert("b")
	_check(first.text == "Ab", "service mirrors validated edits to the target")
	service.session.backspace()
	_check(first.text == "A", "service applies backspace through the shared session")
	var presenter: GridTextEntryPresenter = service._overlay._presenter
	var start_position: Vector2i = presenter._position
	var move := InputEventAction.new()
	move.action = &"ui_right"
	move.pressed = true
	presenter._gui_input(move)
	_check(presenter._position != start_position, "grid navigation moves through enabled keys")
	var first_layer := presenter.active_layer
	service._overlay._on_action(&"switch_layer")
	_check(presenter.active_layer != first_layer, "grid action switches data-defined layers")
	request.allowed_characters = "A "
	presenter.set_layer(first_layer)
	var space_button: Button
	var disabled_found := false
	for row: Array in presenter._rows:
		for button: Button in row:
			if button.text == "Space":
				space_button = button
			if button.disabled:
				disabled_found = true
	_check(space_button != null and space_button.text == "Space", "Space is visibly labelled")
	_check(disabled_found, "characters rejected by the request render disabled")

	var competing := TextEntryRequest.for_purpose(TextEntryRequest.Purpose.NAME)
	competing.target = second
	competing.host_viewport = root
	_check(service.begin(competing, &"grid"), "a competing request starts after arbitration")
	await process_frame
	_check(
		service.session.active and service.session.request == competing,
		"the competing request replaces the prior session"
	)
	await process_frame
	var keyboards := root.get_children().filter(
		func(child: Node) -> bool: return child is TextEntryOverlay
	)
	_check(keyboards.size() == 1, "arbitration leaves exactly one reusable keyboard")

	competing.dismissal_policy = TextEntryRequest.DismissalPolicy.RESTORE_INITIAL
	service.session.insert("c")
	_check(second.text == "Bc", "second field receives session edits")
	_check(service.cancel() and second.text == "B", "cancel restores text when requested")
	await process_frame
	_check(
		not service.session.active and service.active_mode.is_empty(), "cancel releases ownership"
	)
	second.grab_focus()
	_check(service.begin(competing, &"grid"), "a field can re-enter grid editing")
	await process_frame
	var outside := Button.new()
	root.add_child(outside)
	outside.grab_focus()
	await process_frame
	await process_frame
	_check(not service.session.active, "focus withdrawal cancels the scoped grid session")

	var hardware_request := TextEntryRequest.for_purpose(TextEntryRequest.Purpose.NAME)
	hardware_request.target = first
	_check(service.begin(hardware_request, &"hardware"), "hardware uses the same service")
	var key := InputEventKey.new()
	key.pressed = true
	key.unicode = KEY_C
	var handled := service._hardware.handle(key)
	_check(
		handled and first.text == "AC",
		"hardware edits the same target (text=%s session=%s)" % [first.text, service.session.text]
	)
	_check(service.submit(), "hardware submits through the shared session")

	service.queue_free()
	first.queue_free()
	second.queue_free()
	outside.queue_free()
	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
