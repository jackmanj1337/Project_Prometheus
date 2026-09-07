class_name EditorIssues extends RefCounted
# `[CEUI-S26]`'s issues panel: the last full pack pass, plus live results for the open
# documents, in one list grouped by severity and by content.
#
# WHY BOTH HALVES. Scoping the panel to open documents would make it never stale and never
# useful -- an author would have no standing view of the pack's health, which is the whole
# reason `CEUI-18` made the panel persistent rather than a dialog. So pack-wide entries
# stay, and STALENESS IS SHOWN RATHER THAN AVOIDED: every pack-wide entry carries the pass
# it came from, and the moment any document commits an edit the pack pass is marked stale,
# because a commit anywhere can invalidate a cross-reference anywhere. The panel must never
# claim a clean pack it has not re-checked, and `has_pack_pass()` exists so a pack nobody
# has validated reads as UNVALIDATED rather than as clean.
#
# SEVERITY IS RESOLVED PER GATE AND IS NOT STORED ON THE ISSUE. `[CEUI-S27]`/`[CEUI-S28]`
# ruled that the same finding warns in a draft and fails at a release-complete export, so
# `ValidationRules.severity_for(rule, gate)` is asked once per gate here. An entry is
# grouped as an ERROR when it is an error at ANY gate and as a warning only when it is a
# warning at every one -- grouping by a single chosen gate would file a release-blocking
# error under Warnings for as long as the author was not exporting.
#
# THE ENTRY LIST IS A `RecordSelector`, BECAUSE `[CEUI-S26]` SAID SO. The ruling ends by
# binding the panel to the shell's existing vocabulary rather than an issue-state one:
# `EPUX-02`'s gated-shows-disabled-with-reason and `[EPUX-07]`'s focusable-but-not-
# activatable govern entries whose target cannot currently be opened. That is the
# selector's availability provider exactly, so an entry pointing at something unopenable
# stays in the list, stays focusable, and returns its reason when activated.
#
# `[CEUI-S17]`: severity never travels as colour. Every entry carries `severity` and
# `blocks_gates` as values a surface renders as text.

const RulesScript = preload("res://scripts/validation/ValidationRules.gd")
const GateScript = preload("res://scripts/validation/ValidationGate.gd")

## Keys this class reads out of `ValidationIssue.subject` to build `[CEUI-S26]`'s
## navigate-to-the-object-AND-FIELD target. All three are optional; an issue whose subject
## names none of them is still listed, and is simply not navigable.
const SUBJECT_DOCUMENT := "document"
const SUBJECT_RECORD := "record"
const SUBJECT_FIELD := "field"

const ORIGIN_PACK := "pack_pass"
const ORIGIN_DOCUMENT := "open_document"

## Author-facing, and the reason an entry refuses activation. `[EPUX-07]` requires the
## reason to be reachable by someone standing on the entry.
const UNOPENABLE_REASON := "This issue's document is not available in the editor."

signal entries_changed

var rules: ValidationRules = null
## `func(document_id: String) -> bool`. Absent, every target is openable -- the panel does
## not invent gates any more than the selector does.
var openable_provider: Callable = Callable()

var _selector := RecordSelector.new()
var _pack_issues: Array[ValidationIssue] = []
var _pack_pass_label: String = ""
var _has_pack_pass: bool = false
# Bumped by every live document report. A pack pass captured before the current value is
# stale; capturing a pass resets it.
var _commits_since_pass: int = 0
# document id -> Array[ValidationIssue]
var _document_issues: Dictionary = {}


func _init(rule_set: ValidationRules = null) -> void:
	rules = rule_set if rule_set != null else RulesScript.engine_rules()
	_selector.availability_provider = _entry_availability
	_rebuild()


func selector() -> RecordSelector:
	return _selector


# ---- the two inputs ----


## `[CEUI-S25]`'s explicit full-pack Validate, and the automatic passes at Test and at
## Export. `pass_label` is what the panel shows beside a stale marker; it is the author's
## anchor for "which run said this", so an empty one is replaced rather than shown blank.
func set_pack_pass(report: ValidationReport, pass_label: String = "") -> void:
	_pack_issues = report.issues() if report != null else []
	_pack_pass_label = pass_label if pass_label != "" else "last full pass"
	_has_pack_pass = true
	_commits_since_pass = 0
	# The live per-document results are DISCARDED, because a full pass re-validated those
	# documents too and its answer for them is the newer one. Keeping them would let a
	# document's stale live report suppress the fresh pack finding for the same document
	# -- the panel would show a clean document the pass had just failed, which is the
	# inverse of the staleness the ruling is guarding against.
	_document_issues.clear()
	if report != null and report.rules != null:
		rules = report.rules
	_rebuild()


## The live half: one open document's results, refreshed as it commits per `[CEUI-S25]`.
## These SUPERSEDE the pack pass's entries for the same document -- two entries for one
## finding, one of them known-stale, is the panel disagreeing with itself.
func set_document_report(document_id: String, report: ValidationReport) -> void:
	_document_issues[document_id] = report.issues() if report != null else []
	_commits_since_pass += 1
	if report != null and report.rules != null:
		rules = report.rules
	_rebuild()


## Called when a document closes. Its live entries go, and the pack pass's entries for it
## come back -- stale, and marked so.
func forget_document(document_id: String) -> void:
	if not _document_issues.has(document_id):
		return
	_document_issues.erase(document_id)
	_rebuild()


func clear() -> void:
	_pack_issues = []
	_document_issues.clear()
	_has_pack_pass = false
	_pack_pass_label = ""
	_commits_since_pass = 0
	_rebuild()


# ---- what the panel draws ----


## Every entry, in the panel's order: errors before warnings, then grouped by content,
## then by rule. `{id, severity, blocks_gates, rule_id, message, origin, stale, pass_label,
## document, record, field, group}`.
func entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row in _selector.rows():
		var entry: Dictionary = (row["payload"] as Dictionary).duplicate(true)
		entry["available"] = bool(row["available"])
		entry["reason"] = String(row["reason"])
		entry["focused"] = bool(row["focused"])
		out.append(entry)
	return out


## `[CEUI-S26]`'s two groupings, materialized so a surface draws headers instead of
## re-deriving them: `{severity, count, groups: [{group, count, entry_ids}]}` per severity,
## errors first.
func grouped() -> Array[Dictionary]:
	var by_severity: Dictionary = {}
	for entry in entries():
		var severity := String(entry["severity"])
		if not by_severity.has(severity):
			by_severity[severity] = {"severity": severity, "count": 0, "groups": [], "index": {}}
		var bucket: Dictionary = by_severity[severity]
		bucket["count"] = int(bucket["count"]) + 1
		var group := String(entry["group"])
		if not (bucket["index"] as Dictionary).has(group):
			var created := {"group": group, "count": 0, "entry_ids": [] as Array[String]}
			(bucket["index"] as Dictionary)[group] = created
			(bucket["groups"] as Array).append(created)
		var group_bucket: Dictionary = (bucket["index"] as Dictionary)[group]
		group_bucket["count"] = int(group_bucket["count"]) + 1
		(group_bucket["entry_ids"] as Array[String]).append(String(entry["id"]))
	var out: Array[Dictionary] = []
	for severity in [RulesScript.SEVERITY_ERROR, RulesScript.SEVERITY_WARNING]:
		if by_severity.has(severity):
			var bucket: Dictionary = by_severity[severity]
			bucket.erase("index")
			out.append(bucket)
	return out


func error_count() -> int:
	return _count_of(RulesScript.SEVERITY_ERROR)


func warning_count() -> int:
	return _count_of(RulesScript.SEVERITY_WARNING)


func has_pack_pass() -> bool:
	return _has_pack_pass


## True once anything has committed since the pack pass. Distinct from `has_pack_pass()`:
## never-validated and validated-then-edited are different states, and collapsing them
## would let a pack nobody has checked present as merely out of date.
func is_pack_pass_stale() -> bool:
	return _has_pack_pass and _commits_since_pass > 0


## `EW-6`'s status-bar line: the standing validation count and its freshness, as one
## author-facing string so two surfaces cannot word it differently.
func freshness_summary() -> String:
	if not _has_pack_pass:
		return "Not validated"
	var counts := "%d error(s), %d warning(s)" % [error_count(), warning_count()]
	if is_pack_pass_stale():
		return "%s - %s, edited since" % [counts, _pack_pass_label]
	return "%s - %s" % [counts, _pack_pass_label]


## `[CEUI-S26]`: navigable to the object AND field. Returns `{document, record, field}` for
## the entry, or `{}` when it names no target. Activation goes through the selector so a
## target that cannot be opened refuses with its reason rather than silently doing nothing.
func activate(entry_id: String) -> Dictionary:
	var outcome := _selector.activate(entry_id)
	if String(outcome["outcome"]) != RecordSelector.ACTIVATED:
		return outcome
	var row := _selector.row(entry_id)
	var payload: Dictionary = row["payload"]
	outcome["target"] = {
		"document": String(payload["document"]),
		"record": String(payload["record"]),
		"field": String(payload["field"]),
	}
	return outcome


# ---- internals ----


func _count_of(severity: String) -> int:
	var total := 0
	for entry in entries():
		if String(entry["severity"]) == severity:
			total += 1
	return total


func _rebuild() -> void:
	var live_documents: Dictionary = {}
	for document_id in _document_issues:
		live_documents[String(document_id)] = true

	var records: Array = []
	var seen: Dictionary = {}
	# Errors first, then warnings, so the selector's preserved caller order IS the panel's
	# order and no comparator has to re-derive a ranking the severities already state.
	for severity in [RulesScript.SEVERITY_ERROR, RulesScript.SEVERITY_WARNING]:
		for document_id in _sorted_keys(_document_issues):
			_collect(
				records, seen, _document_issues[document_id], severity, ORIGIN_DOCUMENT, false, ""
			)
		for issue in _pack_issues:
			# Superseded: the open document's live report is the current word on it.
			if live_documents.has(_subject_of(issue, SUBJECT_DOCUMENT)):
				continue
			_collect(
				records,
				seen,
				[issue],
				severity,
				ORIGIN_PACK,
				is_pack_pass_stale(),
				_pack_pass_label
			)
	_selector.set_records(records)
	entries_changed.emit()


func _collect(
	records: Array,
	seen: Dictionary,
	issues: Array,
	severity: String,
	origin: String,
	stale: bool,
	pass_label: String
) -> void:
	for issue in issues:
		var validation_issue: ValidationIssue = issue
		var resolved := _severity_of(validation_issue)
		if String(resolved["severity"]) != severity:
			continue
		var document := _subject_of(validation_issue, SUBJECT_DOCUMENT)
		var record := _subject_of(validation_issue, SUBJECT_RECORD)
		var field := _subject_of(validation_issue, SUBJECT_FIELD)
		# The id has to be stable across rebuilds -- it is what `RecordSelector` restores
		# focus by -- and unique, because one rule can fire on many records.
		var entry_id := (
			"%s|%s|%s|%s|%s" % [origin, validation_issue.rule_id, document, record, field]
		)
		if seen.has(entry_id):
			continue
		seen[entry_id] = true
		(
			records
			. append(
				{
					"id": entry_id,
					"payload":
					{
						"id": entry_id,
						"severity": severity,
						"blocks_gates": resolved["blocks_gates"],
						"rule_id": validation_issue.rule_id,
						"message": validation_issue.message,
						"origin": origin,
						"stale": stale,
						"pass_label": pass_label,
						"document": document,
						"record": record,
						"field": field,
						# What `[CEUI-S26]`'s "grouped by content" groups on: the document when
						# the issue names one, and the rule otherwise, so an issue with no
						# object still lands somewhere an author can read.
						"group": document if document != "" else validation_issue.rule_id,
					},
				}
			)
		)


## The per-gate resolution, done once per issue: `{severity, blocks_gates}`. An undeclared
## rule answers ERROR at every gate -- `ValidationRules` chose that default so a forgotten
## declaration cannot downgrade a real error, and the panel must not undo it by treating
## unknown as unremarkable.
func _severity_of(issue: ValidationIssue) -> Dictionary:
	var blocks: Array[String] = []
	var any_error := false
	for gate in GateScript.GATES:
		if rules.severity_for(issue.rule_id, gate) == RulesScript.SEVERITY_ERROR:
			any_error = true
			blocks.append(gate)
	return {
		"severity": RulesScript.SEVERITY_ERROR if any_error else RulesScript.SEVERITY_WARNING,
		"blocks_gates": blocks,
	}


func _subject_of(issue: ValidationIssue, key: String) -> String:
	return String(issue.subject.get(key, ""))


func _entry_availability(_id: String, payload: Variant) -> Dictionary:
	var entry: Dictionary = payload
	var document := String(entry["document"])
	if document == "":
		# Not a gate: an issue that names no object is not navigable, and the selector
		# would have to invent a reason for a refusal that is not a refusal.
		return {"available": true, "reason": ""}
	if not openable_provider.is_valid() or bool(openable_provider.call(document)):
		return {"available": true, "reason": ""}
	return {
		"available": false,
		"reason": UNOPENABLE_REASON,
		"gate": RecordSelector.GATE_VISIBLE_DISABLED,
	}


func _sorted_keys(source: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for key in source:
		out.append(String(key))
	out.sort()
	return out
