class_name ValidationReport extends RefCounted
# What a validation pass produced, and the one place a gate decision is made.
#
# THE INTEROP IS THE POINT, not an afterthought. Every validator in the engine today
# returns a flat `Array[String]` -- `Tier2Catalogue.load_and_validate`,
# `CampaignTier2Validators`' three collect_* passes, `RegistryCatalog.validate_entry` --
# and `DataManager` keeps two hand-rolled channels beside them (`_activation_errors` and
# `_content_warnings`). Rewriting all of that in one change would be a large edit with no
# behaviour to show for it. `adopt_errors()` lets a caller put an existing flat array
# behind a rule id and get a report NOW, and `messages()` hands the flat array back in
# insertion order, so an adopted call site produces byte-identical output to the one it
# replaced. That is what keeps this an addition rather than a migration.
#
# ORDER IS PRESERVED because callers render it. Issues come back in the order they were
# added, filtered but never re-sorted; a validation list that reorders itself between runs
# is unreadable next to a diff.

const RulesScript = preload("res://scripts/validation/ValidationRules.gd")

var rules: ValidationRules = null

var _issues: Array[ValidationIssue] = []


static func create(rule_set: ValidationRules = null) -> ValidationReport:
	var report := ValidationReport.new()
	report.rules = rule_set if rule_set != null else RulesScript.engine_rules()
	return report


func add(rule_id: String, message: String, subject: Dictionary = {}) -> void:
	_issues.append(ValidationIssue.create(rule_id, message, subject))


## Puts an existing flat error array behind one rule id. Returns how many were taken, so a
## caller can adopt and then assert it adopted something.
func adopt_errors(rule_id: String, messages: Array, subject: Dictionary = {}) -> int:
	for message in messages:
		add(rule_id, String(message), subject)
	return messages.size()


func is_empty() -> bool:
	return _issues.is_empty()


func size() -> int:
	return _issues.size()


func issues() -> Array[ValidationIssue]:
	return _issues.duplicate()


## Every issue whose severity AT THIS GATE is `severity`. The gate argument is not
## optional anywhere in this class: "is this an error?" has no answer without one.
func issues_at(gate: String, severity: String) -> Array[ValidationIssue]:
	var out: Array[ValidationIssue] = []
	for issue in _issues:
		if rules.severity_for(issue.rule_id, gate) == severity:
			out.append(issue)
	return out


func errors(gate: String) -> Array[ValidationIssue]:
	return issues_at(gate, RulesScript.SEVERITY_ERROR)


func warnings(gate: String) -> Array[ValidationIssue]:
	return issues_at(gate, RulesScript.SEVERITY_WARNING)


## The flat array the pre-model call sites expect, in insertion order.
func messages(gate: String, severity: String) -> Array[String]:
	var out: Array[String] = []
	for issue in issues_at(gate, severity):
		out.append(issue.message)
	return out


func error_messages(gate: String) -> Array[String]:
	return messages(gate, RulesScript.SEVERITY_ERROR)


func warning_messages(gate: String) -> Array[String]:
	return messages(gate, RulesScript.SEVERITY_WARNING)


## The gate decision, and the whole reason the two severities exist: WARNINGS NEVER BLOCK
## ANYTHING ([CEUI-S27]). They are reviewable in the issues panel and that is all.
func blocks(gate: String) -> bool:
	for issue in _issues:
		if rules.severity_for(issue.rule_id, gate) == RulesScript.SEVERITY_ERROR:
			return true
	return false


## Issues carrying a registered fix ([CEUI-S28]), in insertion order. Empty in v1 -- no
## engine rule declares a fix -- and the panel is built from this rather than from a
## rule-id branch, so the day a fix is registered the affordance appears with no editor
## edit. Not gate-scoped: a fix for a warning is still offered, because a warning the
## author can clear in one click is exactly the kind worth clearing before it escalates.
func fixable() -> Array[ValidationIssue]:
	var out: Array[ValidationIssue] = []
	for issue in _issues:
		if rules.has_fix(issue.rule_id):
			out.append(issue)
	return out


func append_report(other: ValidationReport) -> void:
	for issue in other.issues():
		_issues.append(issue)
