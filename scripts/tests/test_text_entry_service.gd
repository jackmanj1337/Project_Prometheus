extends SceneTree

const TextEntryServiceScript = preload("res://scripts/autoloads/TextEntryService.gd")
const TextEntryResultScript = preload("res://scripts/ui/text_entry/TextEntryResult.gd")

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
	_test_pure_contract()
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
	request.title = "Name export"
	request.prompt = "Choose a name"
	request.placeholder = "campaign-backup"
	request.confirm_label = "Choose Folder"
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
	var results: Array = []
	service.result_ready.connect(func(result: RefCounted) -> void: results.append(result))
	_check(service.begin(competing, &"grid"), "a competing request starts after arbitration")
	await process_frame
	_check(
		service.session.active and service.session.request == competing,
		"the competing request replaces the prior session"
	)
	_check(
		(
			results.size() == 1
			and results[0].status == TextEntryResultScript.Status.CANCELLED
			and results[0].value == "A"
		),
		"session replacement returns one cancellation result for the old generation"
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
	_check(
		(
			results.size() == 2
			and results[1].status == TextEntryResultScript.Status.CANCELLED
			and results[1].value == "B"
		),
		"explicit cancellation returns the dismissal-policy value once"
	)
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
	_check(
		results[-1].status == TextEntryResultScript.Status.SUBMITTED and results[-1].value == "AC",
		"submission returns the validated value"
	)

	service.queue_free()
	first.queue_free()
	second.queue_free()
	outside.queue_free()
	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _test_pure_contract() -> void:
	var request := TextEntryRequest.for_purpose(TextEntryRequest.Purpose.NAME)
	request.initial_text = "  Abcd  "
	request.max_characters = 12
	request.normalizer = func(value: String) -> String: return value.strip_edges().to_lower()
	request.validator = func(value: String) -> StringName:
		return &"too_short" if value.length() < 3 else &""
	var session := TextEntrySession.new()
	session.begin(request)
	_check(session.text == "  Abcd  ", "normalization is deferred until submission")
	session.set_selection(6, 2)
	_check(session.insert("XY"), "insertion replaces the selected range")
	_check(session.text == "  XY  ", "selection replacement preserves surrounding text")
	session.set_selection(3)
	_check(session.backspace() and session.text == "  Y  ", "backspace edits at the caret")
	session.set_selection(2)
	_check(session.delete_forward() and session.text == "    ", "forward delete edits at the caret")
	_check(
		session.validation_code == &"empty_not_allowed" and not session.submit(),
		"invalid normalized values cannot submit and expose a stable code"
	)
	_check(session.insert("Valid"), "valid text can be inserted after a rejected submit")
	_check(session.submit() and session.text == "valid", "submission returns normalized text")
	_check(not session.submit() and not session.cancel(), "a generation completes at most once")
	session.free()
