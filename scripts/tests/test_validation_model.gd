extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_validation_model.gd
#
# Covers `[CEUI-S27]` (two severities, three gates) and `[CEUI-S28]` (the quick-fix
# registration seam) -- the two things the campaign-editor walk found the engine had no
# model for at all. Before this, validators returned flat `Array[String]` and the rule
# "errors block, warnings do not" lived in whichever caller happened to read them.
#
# The assertions that matter, and why each is here rather than left to inspection:
#
#   * WARNINGS NEVER BLOCK. That is the whole payload of two severities; a report holding
#     nothing but warnings must pass every gate.
#   * THE SAME RULE CAN DIFFER BY GATE. The credits register's missing attribution notice
#     (CRD-9) and the localization register's completeness rule (L10N-14) warn while a
#     working copy is a draft and fail at a
#     release-complete export. Neither validator exists yet, so the escalation is proven
#     against a rule this file declares -- an engine rule declared for a producer that does
#     not exist would be dead weight that reads like coverage.
#   * AN UNDECLARED RULE IS AN ERROR. The adopters put pre-model flat arrays behind rule
#     ids; a forgotten declaration must not quietly downgrade a real error to a warning.
#   * V1 SHIPS NO FIXES. `[CEUI-S28]` ruled the seam in and the content out. That is a
#     checkable claim, so it is checked here rather than trusted to the register.
#   * THE ADOPTED CALL SITES STILL PRODUCE THEIR OLD FLAT ARRAY, byte for byte. The report
#     is an addition; the day it changes an existing message is the day something that
#     parses one breaks.

const RulesScript = preload("res://scripts/validation/ValidationRules.gd")
const ReportScript = preload("res://scripts/validation/ValidationReport.gd")
const GateScript = preload("res://scripts/validation/ValidationGate.gd")
const Tier2CatalogueScript = preload("res://scripts/resources/Tier2Catalogue.gd")
const RegistryCatalogScript = preload("res://scripts/registries/RegistryCatalog.gd")
const RegistryEntryScript = preload("res://scripts/resources/RegistryEntry.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Validation Model Test ===")

	_gates_are_three_and_two_share_the_release_axis()
	_warnings_never_block_any_gate()
	_errors_block_every_gate()
	_severity_can_differ_between_draft_and_release()
	_undeclared_rules_fail_closed()
	_v1_engine_rules_register_no_fix()
	_a_registered_fix_is_found_through_the_rule()
	_report_preserves_insertion_order()
	_tier2_report_matches_the_flat_array()
	_registry_catalog_report_carries_the_entry_subject()

	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % label)
	else:
		_failed += 1
		print("  FAIL: %s%s" % [label, ("  -- %s" % detail) if detail != "" else ""])


# ---- gates ----


func _gates_are_three_and_two_share_the_release_axis() -> void:
	print("\n-- gates --")
	_check("three gates", GateScript.GATES.size() == 3, str(GateScript.GATES))
	_check(
		"a Test launch is an activation, not a fourth gate",
		(
			GateScript.is_known(GateScript.ACTIVATION)
			and not GateScript.is_release_complete(GateScript.ACTIVATION)
		)
	)
	_check(
		"both export destinations sit on the release-complete axis",
		(
			GateScript.is_release_complete(GateScript.EXPORT_LIBRARY)
			and GateScript.is_release_complete(GateScript.EXPORT_FILE)
		)
	)
	_check("an invented gate is not known", not GateScript.is_known("test"))


# ---- severity ----


func _warnings_never_block_any_gate() -> void:
	print("\n-- warnings never block --")
	var rules := RulesScript.new()
	rules.declare("probe.warning", RulesScript.SEVERITY_WARNING)
	var report := ReportScript.create(rules)
	report.add("probe.warning", "a survivable authoring gap")
	report.add("probe.warning", "another one")
	for gate in GateScript.GATES:
		_check("warnings do not block %s" % gate, not report.blocks(gate))
	_check("both are reviewable", report.warning_messages(GateScript.ACTIVATION).size() == 2)
	_check("and neither is an error", report.error_messages(GateScript.ACTIVATION).is_empty())


func _errors_block_every_gate() -> void:
	print("\n-- errors block --")
	var rules := RulesScript.new()
	rules.declare("probe.error", RulesScript.SEVERITY_ERROR)
	var report := ReportScript.create(rules)
	report.add("probe.error", "the pack cannot run")
	for gate in GateScript.GATES:
		_check("an error blocks %s" % gate, report.blocks(gate))


func _severity_can_differ_between_draft_and_release() -> void:
	print("\n-- the draft / release-complete axis --")
	# The shape CRD-9 and L10N-14 will take when their validators are written.
	var rules := RulesScript.new()
	rules.declare("probe.missing_notice", RulesScript.SEVERITY_WARNING, RulesScript.SEVERITY_ERROR)
	var report := ReportScript.create(rules)
	report.add("probe.missing_notice", "attribution notice is missing")
	_check("a draft still activates", not report.blocks(GateScript.ACTIVATION))
	_check("export to library refuses", report.blocks(GateScript.EXPORT_LIBRARY))
	_check("export to file refuses too", report.blocks(GateScript.EXPORT_FILE))
	_check(
		"the same issue reads as a warning at activation",
		report.warning_messages(GateScript.ACTIVATION).size() == 1
	)
	_check("and as an error at export", report.error_messages(GateScript.EXPORT_FILE).size() == 1)


func _undeclared_rules_fail_closed() -> void:
	print("\n-- an undeclared rule fails closed --")
	var report := ReportScript.create(RulesScript.new())
	report.add("nobody.declared.this", "something went wrong")
	_check("not silently a warning", report.blocks(GateScript.ACTIVATION))
	_check("it reports as an error", report.error_messages(GateScript.EXPORT_LIBRARY).size() == 1)


func _v1_engine_rules_register_no_fix() -> void:
	print("\n-- [CEUI-S28]: the seam ships, the fixes do not --")
	var rules := RulesScript.engine_rules()
	_check("the engine declares rules", rules.ids().size() >= 8, str(rules.ids()))
	_check(
		"v1 registers no fix for any of them",
		rules.fixable_ids().is_empty(),
		str(rules.fixable_ids())
	)
	_check(
		"the unresolved-id channel stays a warning",
		(
			rules.severity_for(RulesScript.RULE_CONTENT_UNKNOWN_ID, GateScript.ACTIVATION)
			== RulesScript.SEVERITY_WARNING
		)
	)
	_check(
		"and does not escalate at export either -- an inert skill still installs",
		(
			rules.severity_for(RulesScript.RULE_CONTENT_UNKNOWN_ID, GateScript.EXPORT_LIBRARY)
			== RulesScript.SEVERITY_WARNING
		)
	)
	_check(
		"a failed activation blocks",
		(
			rules.severity_for(RulesScript.RULE_CONTENT_ACTIVATION, GateScript.ACTIVATION)
			== RulesScript.SEVERITY_ERROR
		)
	)
	_check(
		"declaring the same id twice is refused",
		not rules.declare(RulesScript.RULE_TIER2_DOCUMENT, RulesScript.SEVERITY_ERROR).is_empty()
	)
	_check(
		"an unknown severity is refused",
		not RulesScript.new().declare("probe.bad", "fatal").is_empty()
	)


func _a_registered_fix_is_found_through_the_rule() -> void:
	print("\n-- the fix seam --")
	var rules := RulesScript.new()
	rules.declare("probe.fixable", RulesScript.SEVERITY_ERROR, "", Callable(self, "_probe_fix"))
	rules.declare("probe.plain", RulesScript.SEVERITY_ERROR)
	_check("a registered fix is found", rules.has_fix("probe.fixable"))
	_check("a rule without one reports none", not rules.has_fix("probe.plain"))
	_check("an unknown rule reports none", not rules.has_fix("probe.missing"))
	_check("the registry lists it", rules.fixable_ids() == ["probe.fixable"])
	var report := ReportScript.create(rules)
	report.add("probe.plain", "no fix for this")
	report.add("probe.fixable", "this one has a fix", {"kind": "class", "id": "knight"})
	var fixable := report.fixable()
	_check("only the fixable issue is offered", fixable.size() == 1)
	if fixable.size() == 1:
		_check("and it carries its subject", fixable[0].subject.get("id", "") == "knight")
		var applied: Variant = rules.fix_for("probe.fixable").call(fixable[0])
		_check("the fix runs against the issue", String(applied) == "fixed:knight")


func _probe_fix(issue: ValidationIssue) -> String:
	return "fixed:%s" % String(issue.subject.get("id", ""))


func _report_preserves_insertion_order() -> void:
	print("\n-- order --")
	var rules := RulesScript.new()
	rules.declare("probe.error", RulesScript.SEVERITY_ERROR)
	var report := ReportScript.create(rules)
	for index in 5:
		report.add("probe.error", "message %d" % index)
	_check(
		"messages come back in the order they were added",
		(
			report.error_messages(GateScript.ACTIVATION)
			== ["message 0", "message 1", "message 2", "message 3", "message 4"]
		)
	)


# ---- the adopted call sites ----


func _tier2_report_matches_the_flat_array() -> void:
	print("\n-- Tier2Catalogue adoption --")
	var root := "user://validation_model_probe_pack"
	_write_broken_pack(root)

	var flat_errors: Array[String] = []
	var flat_catalogue := Tier2CatalogueScript.load_campaign_pack(root, flat_errors)
	_check("the broken pack is refused", flat_catalogue == null)
	_check("and says why", not flat_errors.is_empty(), str(flat_errors))

	var result := Tier2CatalogueScript.load_campaign_pack_report(root)
	var report: ValidationReport = result["report"]
	_check("the report form refuses it too", result["catalogue"] == null)
	_check(
		"the report reproduces the flat array exactly",
		report.error_messages(GateScript.ACTIVATION) == flat_errors,
		"%s vs %s" % [str(report.error_messages(GateScript.ACTIVATION)), str(flat_errors)]
	)
	_check("and it blocks activation", report.blocks(GateScript.ACTIVATION))
	var missing_validator_issues := 0
	for issue in report.issues():
		if issue.rule_id == RulesScript.RULE_TIER2_MISSING_VALIDATOR:
			missing_validator_issues += 1
	_check(
		"the unknown kind is attributed to the missing-validator rule",
		missing_validator_issues == 1,
		str(missing_validator_issues)
	)
	for issue in report.issues():
		if issue.rule_id == RulesScript.RULE_TIER2_MISSING_VALIDATOR:
			_check(
				"with the offending entry as its subject", issue.subject.get("id", "") == "ghost"
			)

	_remove_tree(root)


func _registry_catalog_report_carries_the_entry_subject() -> void:
	print("\n-- RegistryCatalog adoption --")
	var catalogue := RegistryCatalogScript.new()
	var entry := RegistryEntryScript.new()
	entry.id = "broken_entry"
	entry.family = "action_primitives"
	var flat := catalogue.validate_entry(entry)
	_check("the flat form still reports", not flat.is_empty())
	var report := catalogue.validate_entry_report(entry)
	_check("the report reproduces it exactly", report.error_messages(GateScript.ACTIVATION) == flat)
	_check("it blocks activation", report.blocks(GateScript.ACTIVATION))
	var subjects_named := true
	for issue in report.issues():
		if issue.subject.get("id", "") != "broken_entry":
			subjects_named = false
	_check("every issue names the entry", subjects_named)


# ---- fixtures ----


# A pack that fails in two DIFFERENT passes on purpose: an unparseable document (the
# document rule) and a kind with no registered validator (the missing-validator rule).
# One failing pass would not show that adoption attributes each pass to its own rule.
func _write_broken_pack(root: String) -> void:
	_remove_tree(root)
	DirAccess.make_dir_recursive_absolute(root.path_join("data"))
	var catalogue := {
		"format_version": 1,
		"entries":
		[
			{
				"kind": "campaign",
				"id": "probe",
				"path": "data/campaign.json",
				"schema_version": 1,
			},
			{
				"kind": "ghost",
				"id": "ghost",
				"path": "data/ghost.json",
				"schema_version": 1,
			},
		],
	}
	_write_json(root.path_join("data/catalogue.json"), catalogue)
	# Valid JSON, invalid campaign: the campaign validator rejects it, which is the
	# document rule rather than the missing-validator one.
	_write_json(root.path_join("data/campaign.json"), {"id": ""})
	_write_json(root.path_join("data/ghost.json"), {"id": "ghost"})


func _write_json(path: String, data: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("test_validation_model: cannot write %s" % path)
		return
	file.store_string(JSON.stringify(data))
	file.close()


func _remove_tree(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var child := path.path_join(name)
		if dir.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(child)
		name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)
