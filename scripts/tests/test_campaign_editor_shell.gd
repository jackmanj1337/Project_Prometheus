extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_campaign_editor_shell.gd
#
# Covers the campaign editor shell's first slice: `CampaignEditorShell` (the state) and
# `CampaignEditorScreen` (the renderer), which together are the ADOPTER for
# `ContentTreeDescriptor` and `RecordSelector`.
#
# THE ASSERTIONS THAT CARRY THE RULINGS, and that nothing else can catch:
#
#   * THE SHELL AND THE SCREEN SHOW EXACTLY WHAT THE DESCRIPTOR RETURNED. `[CEUI-S21]`
#     forbids the editor enumerating content families, and the cheapest way to break it is
#     a category list that starts as a convenience and becomes the source of truth. Both
#     the model's rows and the tree's item texts are compared against a fresh descriptor
#     call, so a hand-added or hand-dropped category fails here rather than at review.
#   * A FAMILY THE ENGINE NEVER HEARD OF REACHES THE TREE. The descriptor's own suite
#     proves it produces a category; this proves the SHELL does not filter it back out and
#     that the GROUPS -- which are derived here, not by the descriptor -- accommodate it
#     without an edit.
#   * A LOCKED LAYER IS FOCUSABLE BUT NOT ACTIVATABLE, AND SAYS WHY. `[EPUX-07]` is two
#     requirements pulling opposite ways; a silent no-op passes the second and fails the
#     first, which is exactly what an assertion on `activate()`'s RETURN catches and an
#     assertion on "nothing happened" does not.
#   * HIDING A LAYER LEAVES IT IN THE LIST. Visibility is a canvas concern and lock is an
#     edit concern; implementing visibility as the selector's hidden gate would be the
#     one-line mistake that makes a hidden layer impossible to show again.
#   * BELOW THE FLOOR THE SHELL IS REPLACED, NOT REFLOWED (`[CEUI-S2]`). Driven through
#     editor SCALE rather than by resizing the window, so the assertion is the same on any
#     host: the ruling measures window size divided by scale.

const ShellScript = preload("res://scripts/editor/CampaignEditorShell.gd")
const ScreenScene = preload("res://scenes/ui/CampaignEditorScreen.tscn")
const DescriptorScript = preload("res://scripts/editor/ContentTreeDescriptor.gd")
const EntitySchemasScript = preload("res://scripts/data/EntitySchemaRegistry.gd")
const RegistryCatalogScript = preload("res://scripts/registries/RegistryCatalog.gd")
const RegistryEntryScript = preload("res://scripts/resources/RegistryEntry.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Campaign Editor Shell Test ===")

	_the_tree_is_the_descriptor_and_nothing_else()
	_groups_are_derived_from_the_categories()
	_an_undeclared_family_reaches_the_tree_and_its_group()
	_the_layer_list_is_the_schema_layers()
	_hiding_a_layer_keeps_it_in_the_list()
	_a_locked_layer_is_focusable_but_refuses_activation_with_its_reason()
	_state_survives_a_rederivation()
	await _the_screen_draws_the_shell()
	await _the_screen_replaces_itself_below_the_floor()

	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % label)
	else:
		_failed += 1
		print("  FAIL: %s%s" % [label, ("  -- %s" % detail) if detail != "" else ""])


func _shell_ids(shell: CampaignEditorShell) -> Array[String]:
	return shell.content_selector().ids()


func _descriptor_ids(catalogue: RegistryCatalog = null) -> Array[String]:
	var out: Array[String] = []
	for category in DescriptorScript.build(null, catalogue):
		out.append(String(category["id"]))
	return out


## A catalogue holding one entry under a family no engine constant names -- the open
## registry the ruling protects, reproduced here so the shell is asked the question.
func _catalogue_with_runtime_family(family: String) -> RegistryCatalog:
	var catalogue: RegistryCatalog = RegistryCatalogScript.new()
	catalogue.register_primitive_handler("set_state_value")
	var entry: Resource = RegistryEntryScript.new()
	entry.id = "invented_by_a_pack"
	entry.family = family
	entry.label_key = "%s.invented" % family
	entry.owner_feature = family
	entry.version = 1
	entry.kind = "query"
	entry.primitive_handler = "set_state_value"
	entry.docs_text = "A family no engine constant names."
	entry.test_fixture = {"probe": true}
	var errors: Array[String] = catalogue.register_entry(entry)
	assert(errors.is_empty(), str(errors))
	return catalogue


func _the_tree_is_the_descriptor_and_nothing_else() -> void:
	print("\n-- the tree is the descriptor's output --")
	var shell := ShellScript.new()
	var expected := _descriptor_ids()
	_check(
		"every category the descriptor returned is in the shell, in order",
		_shell_ids(shell) == expected,
		"shell=%s expected=%s" % [str(_shell_ids(shell)), str(expected)]
	)
	_check("the shell invents no category", _shell_ids(shell).size() == expected.size())
	var labels_match := true
	for row in shell.content_selector().rows():
		var category: Dictionary = row["payload"]
		if String(row["id"]) != String(category["id"]):
			labels_match = false
	_check("each row's selector id is the descriptor's category id", labels_match)


func _groups_are_derived_from_the_categories() -> void:
	print("\n-- groups are derived, not declared --")
	var shell := ShellScript.new()
	var groups := shell.groups()
	var from_categories: Dictionary = {}
	for row in shell.content_selector().rows():
		from_categories[String((row["payload"] as Dictionary)["group"])] = true
	_check(
		"a group exists for every group a category claimed, and no others",
		groups.size() == from_categories.size(),
		"groups=%d claimed=%d" % [groups.size(), from_categories.size()]
	)
	var every_category_placed := 0
	var ordered := true
	var previous := -1
	for group in groups:
		every_category_placed += (group["category_ids"] as Array[String]).size()
		if int(group["order"]) < previous:
			ordered = false
		previous = int(group["order"])
	_check(
		"every category lands in exactly one group",
		every_category_placed == shell.content_selector().size(),
		"placed=%d categories=%d" % [every_category_placed, shell.content_selector().size()]
	)
	_check("groups come out in the descriptor's group order", ordered)


func _an_undeclared_family_reaches_the_tree_and_its_group() -> void:
	print("\n-- an undeclared family is not filtered out by the shell --")
	var family := "pack_invented_family"
	var catalogue := _catalogue_with_runtime_family(family)
	var shell := ShellScript.new()
	shell.refresh(null, catalogue)
	_check("the runtime family has a category", shell.content_selector().has(family))
	_check(
		"the shell shows exactly the descriptor's categories with that catalogue",
		_shell_ids(shell) == _descriptor_ids(catalogue)
	)
	var group_id := ""
	for group in shell.groups():
		if family in (group["category_ids"] as Array[String]):
			group_id = String(group["id"])
	_check(
		"it lands in the descriptor's undeclared group with no edit here",
		group_id == DescriptorScript.UNDECLARED_GROUP,
		"group=%s" % group_id
	)


func _the_layer_list_is_the_schema_layers() -> void:
	print("\n-- the layer list is the map schema's layers --")
	var shell := ShellScript.new()
	var expected: Array[String] = []
	for layer in DescriptorScript.map_layers():
		expected.append(String(layer["id"]))
	var actual: Array[String] = []
	for row in shell.layer_rows():
		actual.append(String(row["id"]))
	_check(
		"the layers are the schema's, in the schema's order",
		actual == expected,
		"actual=%s expected=%s" % [str(actual), str(expected)]
	)
	var defaults_ok := true
	for row in shell.layer_rows():
		if not bool(row["visible"]) or bool(row["locked"]):
			defaults_ok = false
	_check("a layer starts visible and unlocked", defaults_ok)
	_check(
		"a layer the schema does not declare cannot be toggled",
		not shell.set_layer_visible("regions", false)
	)


func _hiding_a_layer_keeps_it_in_the_list() -> void:
	print("\n-- hiding is a canvas concern, not a list concern --")
	var shell := ShellScript.new()
	var first := shell.layer_selector().ids()[0]
	_check("hiding a declared layer succeeds", shell.set_layer_visible(first, false))
	_check("the hidden layer is still listed", shell.layer_selector().has(first))
	var found := false
	for row in shell.layer_rows():
		if String(row["id"]) == first:
			found = true
			_check("the row reports it as hidden", not bool(row["visible"]))
	_check("the hidden layer still has a row", found)
	_check(
		"hiding does not make it unavailable -- only lock does that",
		shell.layer_selector().is_available(first)
	)


func _a_locked_layer_is_focusable_but_refuses_activation_with_its_reason() -> void:
	print("\n-- a locked layer is focusable but not activatable --")
	var shell := ShellScript.new()
	var first := shell.layer_selector().ids()[0]
	shell.set_layer_locked(first, true)
	_check("the locked layer is still in the list", shell.layer_selector().has(first))
	_check("the locked layer is still focusable", shell.layer_selector().focus(first))
	var outcome := shell.layer_selector().activate(first)
	_check(
		"activation is refused",
		String(outcome["outcome"]) == RecordSelector.REFUSED_UNAVAILABLE,
		str(outcome)
	)
	_check(
		"the refusal carries the reason rather than being a silent no-op",
		String(outcome["reason"]) == ShellScript.LOCKED_LAYER_REASON,
		str(outcome)
	)
	shell.set_layer_locked(first, false)
	_check(
		"unlocking restores activation",
		String(shell.layer_selector().activate(first)["outcome"]) == RecordSelector.ACTIVATED
	)


func _state_survives_a_rederivation() -> void:
	print("\n-- [TSV-24] state survives a re-derivation --")
	var shell := ShellScript.new()
	var category := shell.content_selector().ids()[1]
	var layer := shell.layer_selector().ids()[1]
	shell.content_selector().focus(category)
	shell.content_selector().select(category)
	shell.layer_selector().focus(layer)
	shell.set_layer_visible(layer, false)
	shell.set_layer_locked(layer, true)

	var state := shell.capture_state()
	# The same re-derivation the screen's reload() performs, with a catalogue that adds a
	# family: the list the author was standing in changes underneath them.
	shell.refresh(null, _catalogue_with_runtime_family("another_pack_family"))
	shell.restore_state(state)

	_check("the focused category survives", shell.content_selector().focused_id() == category)
	_check("the selection survives", shell.content_selector().is_selected(category))
	_check("the focused layer survives", shell.layer_selector().focused_id() == layer)
	_check("per-layer visibility survives", not shell.is_layer_visible(layer))
	_check("per-layer lock survives", shell.is_layer_locked(layer))
	_check("the new family arrived with it", shell.content_selector().has("another_pack_family"))


func _the_screen_draws_the_shell() -> void:
	print("\n-- the screen draws the shell and nothing of its own --")
	var screen: Control = ScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	var tree: Tree = screen.get_node("Shell/Body/TreePane/ContentTree")
	var drawn: Array[String] = []
	var group_item := tree.get_root().get_first_child()
	var non_selectable_groups := true
	while group_item != null:
		if group_item.is_selectable(0):
			non_selectable_groups = false
		var category_item := group_item.get_first_child()
		while category_item != null:
			drawn.append(String((category_item.get_metadata(0) as Dictionary)["id"]))
			category_item = category_item.get_next()
		group_item = group_item.get_next()
	drawn.sort()
	var expected := _descriptor_ids()
	expected.sort()
	_check(
		"the tree's items are exactly the descriptor's categories",
		drawn == expected,
		"drawn=%s expected=%s" % [str(drawn), str(expected)]
	)
	_check("group rows are headings, not selectable records", non_selectable_groups)

	var layer_tree: Tree = screen.get_node("Shell/Body/TreePane/LayerList")
	var layer_count := 0
	var item := layer_tree.get_root().get_first_child()
	while item != null:
		layer_count += 1
		item = item.get_next()
	_check(
		"the layer list draws one row per schema layer",
		layer_count == DescriptorScript.map_layers().size(),
		"drawn=%d" % layer_count
	)

	# The refusal has to leave the screen, or `EW-6`'s status bar has nothing to show.
	var first_layer: String = screen.shell().layer_selector().ids()[0]
	screen.shell().set_layer_locked(first_layer, true)
	var refusals: Array[String] = []
	screen.layer_activation_refused.connect(
		func(_id: String, reason: String) -> void: refusals.append(reason)
	)
	var outcome: Dictionary = screen.activate_layer(first_layer)
	_check(
		"activating a locked layer through the screen refuses",
		String(outcome["outcome"]) == RecordSelector.REFUSED_UNAVAILABLE
	)
	_check(
		"and the reason is emitted for the status bar",
		refusals.size() == 1 and refusals[0] == ShellScript.LOCKED_LAYER_REASON,
		str(refusals)
	)
	screen.queue_free()
	await process_frame


func _the_screen_replaces_itself_below_the_floor() -> void:
	print("\n-- [CEUI-S2] below the floor the shell is replaced, not reflowed --")
	var screen: Control = ScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	var shell_root: Control = screen.get_node("Shell")
	var minimum: Control = screen.get_node("MinimumSizeState")

	# Scale 0.1 makes the effective viewport ten times the window, which clears the floor
	# on any host this runs on.
	screen.set_editor_scale(0.1)
	_check("above the floor the shell is shown", shell_root.visible and not minimum.visible)

	# Scale 8.0 divides any plausible window below 1920 x 880.
	screen.set_editor_scale(8.0)
	_check("below the floor the shell is hidden", not shell_root.visible)
	_check("and the minimum-size state is shown instead", minimum.visible)
	var message: Label = screen.get_node("MinimumSizeState/Message")
	_check(
		"the message names the floor rather than reflowing the editor",
		message.text.contains("1920") and message.text.contains("880"),
		message.text
	)
	screen.queue_free()
	await process_frame
