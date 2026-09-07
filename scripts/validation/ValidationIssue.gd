class_name ValidationIssue extends RefCounted
# One thing a validator found. Deliberately a dumb record: it carries WHAT was found and
# WHERE, and nothing about how bad it is.
#
# Severity is not stored here because `[CEUI-S27]` made it a function of the GATE -- the
# same finding warns while a working copy is a draft and fails at a release-complete
# export. A severity field on the issue would have to be recomputed per gate anyway, and
# the first caller that forgot to would silently ship the draft answer at export.
# `ValidationRules.severity_for()` owns it instead, and `ValidationReport` asks.
#
# `subject` is how the issues panel navigates to the finding ([CEUI-S26]) and how a
# registered fix ([CEUI-S28]) knows what to act on. Its keys are open; the ones the
# engine fills are `kind`, `id` and `field`.

var rule_id: String = ""
var message: String = ""
var subject: Dictionary = {}


static func create(from_rule: String, text: String, about: Dictionary = {}) -> ValidationIssue:
	var issue := ValidationIssue.new()
	issue.rule_id = from_rule
	issue.message = text
	issue.subject = about.duplicate(true)
	return issue


func describe() -> String:
	return "[%s] %s" % [rule_id, message]
