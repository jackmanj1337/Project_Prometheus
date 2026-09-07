extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_record_selector.gd
#
# Covers `[TSV-10]`, `[TSV-24]`, `[EPUX-04]` and `[EPUX-07]` — the shared selector, which
# `[CEUI-S15]` ruled the campaign editor's reference picker IS rather than a sixth private
# copy. Until this landed, none of it existed in code; `TSV`'s ruled set names it unbuilt.
#
# The assertions that carry the rulings:
#
#   * FOCUS PASSES THROUGH A GATED ENTRY, and activating it refuses WITH THE REASON.
#     `[EPUX-07]`'s two halves pull against each other, and the failure mode is a silent
#     no-op that satisfies "not activatable" while quietly failing "focusable" — the
#     reason becomes unreachable to exactly the keyboard and screen-reader user it was
#     written for. That is the shape `check_availability_reasons.py` was written after six
#     hand-applications of the same fix.
#   * THE SHELL DECIDES HIDDEN VERSUS DISABLED, not the adapter. `[EPUX-04]` promoted
#     gating into the shell precisely so four adapters cannot drift into four treatments,
#     so the test drives one provider returning both gates and checks the selector's
#     answer, not the provider's.
#   * `[TSV-24]` STATE SURVIVES BY STABLE ID. An index survives nothing: recomposition
#     usually arrives with a filter or availability change that moves every row, which is
#     why the restore test deliberately reorders and removes rows first.
#   * A DUPLICATE ID IS REFUSED. Two rows answering to one id makes focus restoration
#     ambiguous forever after, and it is silent at the point it is introduced.

const SelectorScript = preload("res://scripts/shared/RecordSelector.gd")

var _passed := 0
var _failed := 0


class Recorder:
	extends RefCounted
	var focus_events: Array = []
	var selection_events := 0

	func on_focus_changed(new_id: String, previous_id: String) -> void:
		focus_events.append([previous_id, new_id])

	func on_selection_changed() -> void:
		selection_events += 1


func _init() -> void:
	print("=== Record Selector Test ===")

	_records_are_keyed_by_a_stable_opaque_id()
	_a_duplicate_id_is_refused()
	_focus_passes_through_a_gated_entry()
	_activating_a_gated_entry_returns_its_reason()
	_the_shell_owns_hidden_versus_disabled()
	_a_gate_without_a_reason_still_gets_one()
	_selection_refuses_unavailable_records()
	_multi_select_is_opt_in()
	_filters_remove_rather_than_disable()
	_sort_is_the_callers_and_absence_preserves_authored_order()
	_state_survives_recomposition_by_id()
	_focus_repairs_when_its_record_disappears()
	_quantity_is_per_record()
	_no_domain_vocabulary_leaked_into_the_selector()

	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % label)
	else:
		_failed += 1
		print("  FAIL: %s%s" % [label, ("  -- %s" % detail) if detail != "" else ""])


func _selector(ids: Array) -> RecordSelector:
	var selector := SelectorScript.new()
	var records: Array = []
	for id in ids:
		records.append({"id": String(id), "payload": {"name": String(id).to_upper()}})
	selector.set_records(records)
	return selector


func _records_are_keyed_by_a_stable_opaque_id() -> void:
	print("\n-- records --")
	var selector := _selector(["alpha", "beta", "gamma"])
	_check("all three are visible", selector.ids() == ["alpha", "beta", "gamma"])
	_check("focus starts on the first", selector.focused_id() == "alpha")
	_check("the payload is returned untouched", selector.row("beta")["payload"]["name"] == "BETA")
	_check(
		"and is the detail when no provider is set", selector.detail_for("beta")["name"] == "BETA"
	)
	selector.detail_provider = func(id: String, _payload: Variant) -> String:
		return "detail:%s" % id
	_check("a provider overrides it", selector.detail_for("beta") == "detail:beta")


func _a_duplicate_id_is_refused() -> void:
	print("\n-- duplicate ids --")
	var selector := SelectorScript.new()
	var errors := selector.set_records(
		[{"id": "one"}, {"id": "one"}, {"id": ""}, {"payload": 1}, {"id": "two"}]
	)
	_check(
		"the duplicate, the blank and the id-less are all reported", errors.size() == 3, str(errors)
	)
	_check(
		"and only the distinct ids survive", selector.ids() == ["one", "two"], str(selector.ids())
	)


func _focus_passes_through_a_gated_entry() -> void:
	print("\n-- [EPUX-07]: focusable but not activatable --")
	var selector := _selector(["alpha", "beta", "gamma"])
	selector.availability_provider = func(id: String, _payload: Variant) -> Dictionary:
		if id == "beta":
			return {"available": false, "reason": "Needs a bridge repaired first."}
		return {"available": true}
	selector.refresh()
	_check("the gated row is still listed", selector.ids() == ["alpha", "beta", "gamma"])
	_check("focus lands on it", selector.focus_next() == "beta")
	_check("and moves off it", selector.focus_next() == "gamma")
	_check("backwards passes through too", selector.focus_previous() == "beta")
	_check("its row carries the reason", selector.row("beta")["reason"] != "")
	_check("and an available row carries none", selector.row("alpha")["reason"] == "")


func _activating_a_gated_entry_returns_its_reason() -> void:
	print("\n-- activation refuses out loud --")
	var selector := _selector(["alpha", "beta"])
	selector.availability_provider = func(id: String, _payload: Variant) -> Dictionary:
		if id == "beta":
			return {"available": false, "reason": "Needs a bridge repaired first."}
		return {"available": true}
	selector.refresh()
	var refused := selector.activate("beta")
	_check("it refuses", refused["outcome"] == SelectorScript.REFUSED_UNAVAILABLE)
	_check(
		"and hands back the adapter's reason, not a generic one",
		refused["reason"] == "Needs a bridge repaired first.",
		str(refused)
	)
	_check(
		"an available record activates",
		selector.activate("alpha")["outcome"] == SelectorScript.ACTIVATED
	)
	_check(
		"an unknown id is a distinct outcome",
		selector.activate("nope")["outcome"] == SelectorScript.REFUSED_UNKNOWN
	)


func _the_shell_owns_hidden_versus_disabled() -> void:
	print("\n-- [EPUX-04]: the shell decides the treatment --")
	var selector := _selector(["visible_gate", "hidden_gate", "open"])
	selector.availability_provider = func(id: String, _payload: Variant) -> Dictionary:
		if id == "visible_gate":
			return {
				"available": false,
				"reason": "Not yet.",
				"gate": SelectorScript.GATE_VISIBLE_DISABLED,
			}
		if id == "hidden_gate":
			return {
				"available": false,
				"reason": "Not yet.",
				"gate": SelectorScript.GATE_HIDDEN_UNTIL_MET,
			}
		return {"available": true}
	selector.refresh()
	_check(
		"hidden-until-met is absent, visible-disabled is present",
		selector.ids() == ["visible_gate", "open"],
		str(selector.ids())
	)
	_check(
		"the default gate is visible-disabled",
		selector.row("open")["gate"] == SelectorScript.GATE_VISIBLE_DISABLED
	)


func _a_gate_without_a_reason_still_gets_one() -> void:
	print("\n-- a blank reason is a bug at the point it is read --")
	var selector := _selector(["alpha"])
	selector.availability_provider = func(_id: String, _payload: Variant) -> Dictionary:
		return {"available": false}
	selector.refresh()
	_check("a placeholder stands in", selector.unmet_reason("alpha") != "")


func _selection_refuses_unavailable_records() -> void:
	print("\n-- selection --")
	var selector := _selector(["alpha", "beta"])
	selector.availability_provider = func(id: String, _payload: Variant) -> Dictionary:
		return {"available": id != "beta", "reason": "gated"}
	selector.refresh()
	var recorder := Recorder.new()
	selector.selection_changed.connect(recorder.on_selection_changed)
	_check("an available record selects", selector.select("alpha"))
	_check("a gated one does not", not selector.select("beta"))
	_check("only one signal fired", recorder.selection_events == 1)
	_check("and it is selected", selector.selected_ids() == ["alpha"])
	_check("toggling clears it", selector.toggle("alpha") and selector.selected_ids().is_empty())


func _multi_select_is_opt_in() -> void:
	print("\n-- multi-select --")
	var selector := _selector(["alpha", "beta", "gamma"])
	selector.select("alpha")
	selector.select("beta")
	_check(
		"single-select replaces", selector.selected_ids() == ["beta"], str(selector.selected_ids())
	)
	selector.allow_multi_select = true
	selector.select("alpha")
	selector.select("gamma")
	_check(
		"multi-select accumulates in visible order",
		selector.selected_ids() == ["alpha", "beta", "gamma"],
		str(selector.selected_ids())
	)


func _filters_remove_rather_than_disable() -> void:
	print("\n-- filters --")
	var selector := _selector(["alpha", "beta", "gamma"])
	selector.filter = func(id: String, _payload: Variant) -> bool: return id != "beta"
	selector.refresh()
	_check("the filtered record is gone entirely", selector.ids() == ["alpha", "gamma"])
	_check("not merely disabled", selector.row("beta")["available"])


func _sort_is_the_callers_and_absence_preserves_authored_order() -> void:
	print("\n-- sort --")
	var selector := _selector(["gamma", "alpha", "beta"])
	_check("no comparator keeps the authored order", selector.ids() == ["gamma", "alpha", "beta"])
	selector.sort_comparator = func(a: Dictionary, b: Dictionary) -> bool:
		return String(a["id"]) < String(b["id"])
	selector.refresh()
	_check("a comparator reorders", selector.ids() == ["alpha", "beta", "gamma"])


func _state_survives_recomposition_by_id() -> void:
	print("\n-- [TSV-24]: survival by stable id --")
	var selector := _selector(["alpha", "beta", "gamma", "delta"])
	selector.allow_multi_select = true
	selector.focus("gamma")
	selector.select("gamma")
	selector.select("delta")
	selector.set_quantity("delta", 3)
	var state := selector.capture_state()

	# Recomposition: the same records arrive reordered, and one is filtered away. An
	# index-keyed restore would land on the wrong row; that is the whole point.
	(
		selector
		. set_records(
			[
				{"id": "delta", "payload": {}},
				{"id": "gamma", "payload": {}},
				{"id": "beta", "payload": {}},
				{"id": "alpha", "payload": {}},
			]
		)
	)
	selector.filter = func(id: String, _payload: Variant) -> bool: return id != "beta"
	selector.refresh()
	selector.restore_state(state)

	_check("focus is back on the same record", selector.focused_id() == "gamma")
	_check(
		"the selection is back, in the new visible order",
		selector.selected_ids() == ["delta", "gamma"],
		str(selector.selected_ids())
	)
	_check("the quantity came with it", selector.quantity("delta") == 3)


func _focus_repairs_when_its_record_disappears() -> void:
	print("\n-- focus repair --")
	var selector := _selector(["alpha", "beta", "gamma"])
	var recorder := Recorder.new()
	selector.focus_changed.connect(recorder.on_focus_changed)
	selector.focus("gamma")
	_check("focus moved", selector.focused_id() == "gamma")
	selector.set_records([{"id": "alpha"}, {"id": "beta"}])
	_check("it falls back rather than dangling", selector.focused_id() == "alpha")
	selector.set_records([{"id": "alpha"}, {"id": "beta"}])
	_check(
		"a rebuild landing on the same id publishes nothing",
		recorder.focus_events.size() == 2,
		str(recorder.focus_events)
	)
	selector.set_records([])
	_check("an empty list leaves no focus", selector.focused_id() == "")


func _quantity_is_per_record() -> void:
	print("\n-- quantity --")
	var selector := _selector(["alpha", "beta"])
	_check("the default is one", selector.quantity("alpha") == 1)
	_check("it sets", selector.set_quantity("alpha", 4) and selector.quantity("alpha") == 4)
	_check("zero is refused", not selector.set_quantity("alpha", 0))
	_check("and it stayed", selector.quantity("alpha") == 4)
	_check("an unknown id is refused", not selector.set_quantity("nope", 2))
	_check("the other record is untouched", selector.quantity("beta") == 1)


func _no_domain_vocabulary_leaked_into_the_selector() -> void:
	print("\n-- [TSV-10] option C stayed rejected --")
	# The ruling's whole objection to option C is that a selector owning business rules
	# becomes a monolithic shop/convoy/forge switch. The cheapest durable guard is to read
	# the file: a domain noun appearing here is the first line of that switch.
	var file := FileAccess.open("res://scripts/shared/RecordSelector.gd", FileAccess.READ)
	_check("the source is readable", file != null)
	if file == null:
		return
	var source := file.get_as_text().to_lower()
	file.close()
	var body: Array[String] = []
	for line in source.split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.begins_with("#"):
			continue
		body.append(trimmed)
	var code := "\n".join(body)
	for noun in ["convoy", "forge", "weapon", "unit_data", "campaign", "shop", "inventory"]:
		_check("no '%s' in the shared selector's code" % noun, not code.contains(noun))
