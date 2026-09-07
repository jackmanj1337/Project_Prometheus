class_name ValidationRules extends RefCounted
# The rule contract `[CEUI-S27]` and `[CEUI-S28]` ruled, and the open registry that holds
# it. One rule declares three things:
#
#   1. an id, so an issue can be traced back to the check that raised it;
#   2. a severity per GATE, which is how "warns while you author, fails at release" is
#      expressed without a second severity system ([CEUI-S27]); and
#   3. an OPTIONAL registered fix ([CEUI-S28]) -- present in the contract from day one,
#      with no fix shipped in v1.
#
# WHY THE FIX SLOT SHIPS EMPTY. `[CEUI-S28]` resolved `CEUI-20` to "A in contract,
# deferred in content": the seam is the expensive half to add late and the cheap half to
# add now, and the fixes are the opposite. A fix added later registers BESIDE its rule --
# no engine edit, no reshaping of the issues panel. `engine_rules()` below declares no
# fix, and `test_validation_model.gd` asserts that, so v1 shipping report-only is a
# checked fact rather than a claim in a register.
#
# WHY SEVERITY IS PER GATE RATHER THAN PER ISSUE. Two levels only -- error and warning --
# but the same rule can be a warning at `ValidationGate.ACTIVATION` and an error at a
# release-complete export. The credits register's missing attribution notice (CRD-9) and
# the localization register's declared completeness (L10N-14) are the two the walk named,
# and both rulings live in their own registers rather than a GDD chapter today.
# NEITHER VALIDATOR EXISTS YET
# (`grep -rn "attribution" scripts/` finds no check, and nothing reads a locale manifest),
# so no rule declared below escalates today. The mechanism is here because retrofitting a
# gate axis into a flat severity field is the change that touches every call site, and it
# is proven by `test_validation_model.gd` against a rule the test declares itself rather
# than by a speculative engine rule with no producer.
#
# WHY AN UNDECLARED RULE FAILS CLOSED. `severity_for()` answers ERROR for a rule id it has
# never seen. The engine's validators pre-date this model and still return flat
# `Array[String]`; adopting them (see `ValidationReport.adopt_errors`) must not be able to
# downgrade a real error to a warning by forgetting a declaration.

const SEVERITY_ERROR := "error"
const SEVERITY_WARNING := "warning"
const SEVERITIES: Array[String] = [SEVERITY_ERROR, SEVERITY_WARNING]

## The coarse rule ids the shipped validators raise under today. They are coarse because
## the validators are: `CampaignTier2Validators` and `EntitySchemaRegistry` return flat
## message arrays with no per-check identity, so one id per PASS is the finest honest
## granularity available without rewriting them. Finer ids arrive with each validator
## that is rewritten to report issues directly; the contract does not change when they do.
const RULE_TIER2_DOCUMENT := "tier2.document"
const RULE_TIER2_MISSING_VALIDATOR := "tier2.missing_validator"
const RULE_TIER2_ENTITY_SCHEMA := "tier2.entity_schema"
const RULE_TIER2_ASSET_INTEGRITY := "tier2.asset_integrity"
const RULE_TIER2_CROSS_REFERENCE := "tier2.cross_reference"
const RULE_REGISTRY_ENTRY := "registry_catalog.entry"
const RULE_CONTENT_ACTIVATION := "content.activation"
const RULE_CONTENT_UNKNOWN_ID := "content.unknown_id"

var _rules: Dictionary = {}


## The set the engine ships. Open by construction: a caller holds its own instance and
## declares more, which is how a pack-supplied or editor-supplied check joins the model
## without an engine edit.
static func engine_rules() -> ValidationRules:
	var rules := ValidationRules.new()
	rules.declare(RULE_TIER2_DOCUMENT, SEVERITY_ERROR)
	rules.declare(RULE_TIER2_MISSING_VALIDATOR, SEVERITY_ERROR)
	rules.declare(RULE_TIER2_ENTITY_SCHEMA, SEVERITY_ERROR)
	rules.declare(RULE_TIER2_ASSET_INTEGRITY, SEVERITY_ERROR)
	rules.declare(RULE_TIER2_CROSS_REFERENCE, SEVERITY_ERROR)
	rules.declare(RULE_REGISTRY_ENTRY, SEVERITY_ERROR)
	rules.declare(RULE_CONTENT_ACTIVATION, SEVERITY_ERROR)
	# The one warning the engine already raises as a warning on purpose. V070-11 ruled it:
	# an unresolved id leaves the content LIVE AND PLAYABLE with one skill or item inert,
	# so spending a blocking error on it is what teaches a triage pass to skim past errors.
	# It does not escalate at export either -- a pack with an inert skill still installs.
	rules.declare(RULE_CONTENT_UNKNOWN_ID, SEVERITY_WARNING)
	return rules


## `export_severity` defaults to `severity`, so a rule only says the word twice when it
## actually differs between draft and release-complete. `fix` is the `[CEUI-S28]` seam:
## a Callable registered beside the rule, absent in v1.
func declare(
	rule_id: String, severity: String, export_severity: String = "", fix: Callable = Callable()
) -> Array[String]:
	var errors: Array[String] = []
	if rule_id.strip_edges() == "":
		return ["ValidationRules: rule id is empty"]
	if severity not in SEVERITIES:
		errors.append("ValidationRules: rule '%s' has unknown severity '%s'" % [rule_id, severity])
	var resolved_export := export_severity if export_severity != "" else severity
	if resolved_export not in SEVERITIES:
		errors.append(
			(
				"ValidationRules: rule '%s' has unknown export severity '%s'"
				% [rule_id, export_severity]
			)
		)
	if _rules.has(rule_id):
		errors.append("ValidationRules: duplicate rule id '%s'" % rule_id)
	if not errors.is_empty():
		return errors
	_rules[rule_id] = {
		"id": rule_id,
		"severity": severity,
		"export_severity": resolved_export,
		"fix": fix,
	}
	return errors


func has_rule(rule_id: String) -> bool:
	return _rules.has(rule_id)


func ids() -> Array[String]:
	var out: Array[String] = []
	for rule_id in _rules.keys():
		out.append(String(rule_id))
	out.sort()
	return out


## Fails closed for an unknown rule -- see the header. A caller that wants to know whether
## the id was declared asks `has_rule()`; this answers only "does it block".
func severity_for(rule_id: String, gate: String) -> String:
	if not _rules.has(rule_id):
		return SEVERITY_ERROR
	var rule: Dictionary = _rules[rule_id]
	if ValidationGate.is_release_complete(gate):
		return String(rule["export_severity"])
	return String(rule["severity"])


## `[CEUI-S28]`: a fix is REGISTERED BESIDE ITS RULE, so asking whether one exists is a
## registry lookup and never a branch on the rule id.
func has_fix(rule_id: String) -> bool:
	if not _rules.has(rule_id):
		return false
	var fix: Callable = (_rules[rule_id] as Dictionary)["fix"]
	return fix.is_valid()


func fix_for(rule_id: String) -> Callable:
	if not has_fix(rule_id):
		return Callable()
	return (_rules[rule_id] as Dictionary)["fix"]


## Every declared rule that carries a fix. The issues panel builds its Fix affordance from
## this rather than from a hand-kept list; in v1 it is empty and the panel shows none.
func fixable_ids() -> Array[String]:
	var out: Array[String] = []
	for rule_id in ids():
		if has_fix(rule_id):
			out.append(rule_id)
	return out
