class_name EditorTestSession extends RefCounted
# `[CEUI-S3]`'s embedded playable session and `[CEUI-S33]`'s test report: what the Test
# workspace runs, what it is allowed to change, and what it hands back. Headless state, like
# every other piece of the editor, so five rulings can be asserted without a viewport.
#
# THE SESSION IS A SNAPSHOT, AND THAT IS WHY A PLAYABLE SESSION IS ALLOWED AT ALL.
# `[DLUX-15]` forbids preview from committing campaign state, spending resources, firing
# authoritative triggers or creating Rewind history -- all of which a PLAYABLE session does
# by definition. `[CEUI-S3]` point 2 resolved that not with an exemption but with the
# ratified snapshot primitive: the session CAPTURES a starting state at launch and DISCARDS
# it at exit. Nothing here writes through to the working copy, and `end_session()` is the
# only way a session ends, so there is no path on which the snapshot survives.
#
# A FIXTURE IS THAT SNAPSHOT'S STARTING STATE, NAMED -- NOT A SECOND CONCEPT (`[CEUI-S19]`).
# `[CEUI-S20]` made its fields DECLARATIVE authored values, never captured runtime objects,
# because option C's serialized runtime state buys a migration obligation every time the
# runtime changes -- and `[CEUI-S19]` ships fixtures inside packs, which would make that
# obligation other people's problem too. `FIXTURE_FIELDS` is that field list and there is no
# other. THE SEED RIDES `EXT-4`'s determinism model; it is not a fixture-local seed concept.
#
# THERE ARE EXACTLY THREE ENTRY POINTS AND `[CEUI-S18]` CLOSED THE LIST. Campaign start,
# node/map with a fixture, and validation-only. `[CEUI-S51]` added the sentence that keeps it
# closed: `[L10N-16]`'s pseudolocale captures launch from the LOCALIZATION workspace and are
# NOT a fourth entry -- they reuse this session like every other launch, one runtime, one
# mechanism, a different button. Launching an arbitrary runtime scene is not among them
# either: it is an unstable developer surface that would be depended on.
#
# VALIDATION-ONLY RUNS NO SESSION, AND IT IS STILL AN ENTRY POINT. It produces a report and
# no snapshot, which is the whole of what makes it the cheap check `[CEUI-S18]` kept it for.
#
# THE SAVE SANDBOX IS A PRECONDITION, NOT A COURTESY (`[CEUI-S3]` point 3, `[CEUI-S9]` call
# 3). An embedded session that autosaves into the player's slots is a data-loss bug, not a UX
# wrinkle, so `launch()` REFUSES a save scope that is not inside the working copy. Checking it
# here rather than trusting `EditorEntry.sandbox_saves()` to have been called is the
# difference between an obligation and an assertion: the hazard is the call being forgotten.
#
# THE SIMULATOR IS SIZED BY THE SIMULATED SIZE CLASS, NOT BY THE EDITOR (`WIDTH_SIMULATOR_FIXED`).
# Extra width becomes SURROUND. Stretching the view to fill a 4K editor would silently change
# the size class the author believes they are previewing -- the exact failure `[DLUX-15]`'s
# per-size-class preview obligation exists to prevent. The wireframes measured it: a 1280x720
# preview reaches 1:1 at the QHD viewport and must not grow beyond it, which is why
# `simulator_rect()` caps the scale at 1.0 and never at the available width.
#
# TWO THEMES RENDER AT ONCE (`EW-8`, `[UUI-14]`/`[UUI-16]`), AND THE PROOF IS ANOTHER ROW.
# This file states the boundary as data -- which scope owns which theme, and that the pack's
# scope is the session's sub-viewport and nothing above it. Asserting that no pack theme
# reaches editor chrome is `EDITOR-TWO-THEME-PROOF-2026-09-07`, because that is a RENDERED
# check and this is the model it checks against.
#
# KEYBOARD OWNERSHIP IS CONTESTED HERE FOR THE FIRST TIME (`[CEUI-S3]` point 4). The status
# bar has carried a keyboard owner since the shell shipped, with nothing to contest it; a
# playable session capturing arrow keys while the editor has focused fields is what makes the
# value mean something. Click-to-focus the game view, an explicit release key, and a visible
# indication of which context holds it -- and the session NEVER takes the keyboard implicitly
# at launch, because a launch the author started from a toolbar button would otherwise
# swallow the next thing they typed.

const ReportScript = preload("res://scripts/validation/ValidationReport.gd")
const RulesScript = preload("res://scripts/validation/ValidationRules.gd")
const WorkingCopyScript = preload("res://scripts/editor/EditorWorkingCopy.gd")

## `[CEUI-S18]`'s three, and the list is closed. See the header on pseudolocale captures.
const ENTRY_CAMPAIGN_START := "campaign_start"
const ENTRY_NODE_WITH_FIXTURE := "node_with_fixture"
const ENTRY_VALIDATION_ONLY := "validation_only"
const ENTRY_POINTS: Array[String] = [
	ENTRY_CAMPAIGN_START, ENTRY_NODE_WITH_FIXTURE, ENTRY_VALIDATION_ONLY
]
const ENTRY_LABELS: Dictionary = {
	ENTRY_CAMPAIGN_START: "Play from the start",
	ENTRY_NODE_WITH_FIXTURE: "Play this node",
	ENTRY_VALIDATION_ONLY: "Validate only",
}

## `[CEUI-S20]`'s declarative fixture fields. Entry node/map, seed, roster and loadouts,
## campaign flags and resources, difficulty/profile, and optional turn/state setup. A field
## not in this list is not a fixture field -- and every one of them is an authored VALUE, so
## nothing here can hold a captured runtime object.
const FIXTURE_FIELDS: Array[String] = [
	"entry_node_id",
	"map_id",
	"seed",
	"roster",
	"loadouts",
	"campaign_flags",
	"resources",
	"difficulty",
	"ai_profile",
	"turn_setup",
]

## `[CEUI-S3]` point 4. Two owners, named, because "which context has the keyboard" must have
## one answer the status bar can print.
const KEYBOARD_EDITOR := "Editor"
const KEYBOARD_SESSION := "Test session"

## `[UUI-14]`/`[UUI-16]`, `EW-8`. Two theme scopes in one window; the pack's reaches the
## session's sub-viewport and nothing above it.
const THEME_SCOPE_CHROME := "editor_chrome"
const THEME_SCOPE_SESSION := "pack_session"

## The size class the embedded session simulates unless the author picks another. It is a
## SIMULATED size, not the editor's, which is the whole of `WIDTH_SIMULATOR_FIXED`.
const DEFAULT_SIMULATED_SIZE := Vector2i(1280, 720)

## `[CEUI-S19]` guardrail 2: a fixture may reference content the author later renames or
## deletes, and if that were an ERROR it could block `CampaignPackInstaller` and stop a PLAYER
## installing a pack that is perfectly playable. A broken test setup must never be able to do
## that, so it warns at every gate -- including the release-complete ones.
const RULE_FIXTURE_REFERENCE_DANGLING := "test.fixture_reference_dangling"

## The states a session can be in. `ENDED` is distinct from `IDLE` because a report outlives
## the session that produced it and `IDLE` has nothing to report.
const STATE_IDLE := "idle"
const STATE_RUNNING := "running"
const STATE_ENDED := "ended"

## Author-facing refusals.
const NO_WORKING_COPY_REASON := "Import a campaign working copy before testing it."
const UNKNOWN_ENTRY_REASON := "That is not one of the three ways to launch a test."
const ALREADY_RUNNING_REASON := "A test session is already running. End it before starting another."
const NOT_RUNNING_REASON := "No test session is running."
const NO_FIXTURE_REASON := "Choose a node or map to play before launching this test."
## `[CEUI-S9]` call 3. The hazard is the editor session writing into PLAYER slots, so the
## refusal names that rather than the mechanism.
const UNSANDBOXED_SAVES_REASON := (
	"A test session may not run while saves would go to the player's slots. "
	+ "Sandbox the session's saves into the working copy first."
)


## `[CEUI-S19]`'s dangling-reference rule declared beside the engine's. It stays a WARNING at
## every gate, which is why it names its export severity explicitly rather than defaulting.
static func rules() -> ValidationRules:
	var declared := RulesScript.engine_rules()
	declared.declare(
		RULE_FIXTURE_REFERENCE_DANGLING, RulesScript.SEVERITY_WARNING, RulesScript.SEVERITY_WARNING
	)
	return declared


## `{id, label, available, reason}` for each of the three, resolved against current state.
## `EPUX-02`'s gated-shows-disabled-with-reason, which `[CEUI-S52]` says the editor inherits
## by construction rather than redeclaring.
##
## Validation-only stays available with no fixture, because it needs none -- offering all
## three and gating two is what makes the cheap check reachable on a draft that cannot run.
static func entry_points(has_working_copy: bool, has_fixture: bool) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in ENTRY_POINTS:
		var available := has_working_copy
		var reason := "" if available else NO_WORKING_COPY_REASON
		if available and id == ENTRY_NODE_WITH_FIXTURE and not has_fixture:
			available = false
			reason = NO_FIXTURE_REASON
		(
			out
			. append(
				{
					"id": id,
					"label": String(ENTRY_LABELS[id]),
					"available": available,
					"reason": reason,
				}
			)
		)
	return out


## `WIDTH_SIMULATOR_FIXED`. `{scale, size, surround}` for a simulated size inside `available`.
##
## THE SCALE IS CAPPED AT 1.0 AND THAT CAP IS THE RULING. Extra width becomes SURROUND, not
## simulator: a view that grew to fill the editor would show the author a size class they are
## not previewing. The wireframes measured the 1280x720 preview reaching 1:1 at the QHD
## viewport, and this is the line that stops it there.
##
## It DOES shrink below 1.0, because a preview that overflowed its pane would be cropped, and
## a cropped preview misreports the layout in the other direction.
static func simulator_rect(
	available: Vector2, simulated: Vector2i = DEFAULT_SIMULATED_SIZE
) -> Dictionary:
	if simulated.x <= 0 or simulated.y <= 0 or available.x <= 0.0 or available.y <= 0.0:
		return {"scale": 0.0, "size": Vector2.ZERO, "surround": Vector2.ZERO}
	var scale: float = minf(available.x / float(simulated.x), available.y / float(simulated.y))
	scale = minf(scale, 1.0)
	var size := Vector2(float(simulated.x) * scale, float(simulated.y) * scale)
	return {
		"scale": scale,
		"size": size,
		"surround": Vector2(maxf(available.x - size.x, 0.0), maxf(available.y - size.y, 0.0)),
	}


## `EW-8`. The two scopes and what each may paint, as data the two-theme proof asserts
## against. The pack scope's `contains` is the SUB-VIEWPORT and nothing above it, which is the
## structural half of the isolation -- a theme assigned to a subtree cannot reach a sibling.
static func theme_scopes() -> Array[Dictionary]:
	return [
		{
			"id": THEME_SCOPE_CHROME,
			"owner": "editor",
			"ruling": "UUI-14",
			"contains": "the editor shell, its chrome and every panel",
		},
		{
			"id": THEME_SCOPE_SESSION,
			"owner": "pack",
			"ruling": "UUI-16",
			"contains": "the embedded session's sub-viewport only",
		},
	]


var _working_copy: EditorWorkingCopy = null
var _state: String = STATE_IDLE
var _entry: String = ""
## `[CEUI-S3]` point 2: the starting state, captured at launch and discarded at exit. The
## report's changed-state section is a diff against THIS, which is why it is held rather than
## applied -- there is no committed state to report, so what the author wants to see is what
## this run WOULD have changed.
var _snapshot: Dictionary = {}
var _live_state: Dictionary = {}
var _fixture: Dictionary = {}
var _keyboard_owner: String = KEYBOARD_EDITOR
var _simulated_size: Vector2i = DEFAULT_SIMULATED_SIZE
var _report: Dictionary = {}


func set_working_copy(working_copy: EditorWorkingCopy) -> void:
	_working_copy = working_copy


func state() -> String:
	return _state


func is_running() -> bool:
	return _state == STATE_RUNNING


func entry() -> String:
	return _entry


## `[CEUI-S20]`: only the declared fields are kept. A caller that hands over a captured
## runtime object gets the fields the ruling names and nothing else, which is how "declarative
## authored values, never captured runtime objects" is enforced rather than asked for.
static func normalize_fixture(fixture: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for field in FIXTURE_FIELDS:
		if fixture.has(field):
			out[field] = fixture[field]
	return out


func set_fixture(fixture: Dictionary) -> void:
	_fixture = normalize_fixture(fixture)


func fixture() -> Dictionary:
	return _fixture.duplicate(true)


func has_fixture() -> bool:
	return not _fixture.is_empty()


## `[CEUI-S19]` guardrail 2. `known_ids` is what the working copy actually holds; every
## fixture reference outside it is a WARNING, never an error, at every gate.
func validate_fixture(known_ids: Dictionary) -> ValidationReport:
	var report := ReportScript.create(rules())
	for field in ["entry_node_id", "map_id"]:
		var referenced := String(_fixture.get(field, ""))
		if referenced == "" or known_ids.has(referenced):
			continue
		report.add(
			RULE_FIXTURE_REFERENCE_DANGLING,
			(
				"The fixture's %s refers to '%s', which this campaign no longer has."
				% [field.replace("_", " "), referenced]
			),
			{"field": field, "referenced_id": referenced}
		)
	return report


# ---- launching ----


## Starts a session. `starting_state` is the state to snapshot; `save_dir` is where the
## session's saves would go, and it is CHECKED rather than trusted -- see the header.
##
## `{launched, reason, report}`. Validation-only launches nothing and returns a report, which
## is why it is a distinct branch rather than a session that immediately ends: a session that
## ran would have taken a snapshot and contested the keyboard for a check that does neither.
func launch(
	entry_id: String, starting_state: Dictionary = {}, save_dir: String = "", seed_value: int = 0
) -> Dictionary:
	if not ENTRY_POINTS.has(entry_id):
		return {"launched": false, "reason": UNKNOWN_ENTRY_REASON, "report": {}}
	if _working_copy == null or not _working_copy.is_open():
		return {"launched": false, "reason": NO_WORKING_COPY_REASON, "report": {}}
	if _state == STATE_RUNNING:
		return {"launched": false, "reason": ALREADY_RUNNING_REASON, "report": {}}
	if entry_id == ENTRY_NODE_WITH_FIXTURE and not has_fixture():
		return {"launched": false, "reason": NO_FIXTURE_REASON, "report": {}}
	if entry_id == ENTRY_VALIDATION_ONLY:
		_entry = entry_id
		_state = STATE_ENDED
		_report = _build_report("validated", 0, [], {})
		return {"launched": true, "reason": "", "report": report()}
	if not _is_sandboxed(save_dir):
		return {"launched": false, "reason": UNSANDBOXED_SAVES_REASON, "report": {}}
	_entry = entry_id
	_state = STATE_RUNNING
	_snapshot = starting_state.duplicate(true)
	_live_state = starting_state.duplicate(true)
	_report = {}
	if seed_value != 0:
		_fixture["seed"] = seed_value
	# The keyboard is deliberately NOT taken here. See the header: a launch from a toolbar
	# button that swallowed the author's next keystroke is the failure `[CEUI-S3]` point 4 is
	# about, and click-to-focus is what the ruling names instead.
	_keyboard_owner = KEYBOARD_EDITOR
	return {"launched": true, "reason": "", "report": {}}


## `[CEUI-S9]` call 3, asserted rather than assumed: the session's saves must land inside the
## working copy. An empty path is refused too -- "nowhere configured" resolves to the player's
## default, which is the exact hazard.
func _is_sandboxed(save_dir: String) -> bool:
	if _working_copy == null or save_dir.strip_edges() == "":
		return false
	return _working_copy.contains(save_dir) and not _working_copy.is_installed_path(save_dir)


# ---- the running session ----


## What the session has changed so far. Held apart from the snapshot so the report can diff
## the two; this is the ONLY state a session mutates, and it goes when the session does.
func record_change(key: String, value: Variant) -> bool:
	if _state != STATE_RUNNING:
		return false
	_live_state[key] = value
	return true


func live_state() -> Dictionary:
	return _live_state.duplicate(true)


## The starting state, for anything that wants to show what the run began from. Empty once
## the session has ended, because `[CEUI-S3]` discards it there.
func snapshot() -> Dictionary:
	return _snapshot.duplicate(true)


# ---- `[CEUI-S3]` point 4: keyboard ownership ----


func keyboard_owner() -> String:
	return _keyboard_owner


## Click-to-focus the game view. Refuses when nothing is running, so the status bar can never
## say a session owns the keyboard while no session exists.
func focus_session() -> bool:
	if _state != STATE_RUNNING:
		return false
	_keyboard_owner = KEYBOARD_SESSION
	return true


## The explicit release `[CEUI-S3]` point 4 names. Always succeeds: the way out of a session
## that has the keyboard must not itself depend on the session being in a good state.
func release_keyboard() -> void:
	_keyboard_owner = KEYBOARD_EDITOR


func simulated_size() -> Vector2i:
	return _simulated_size


## The size class the author is previewing. Changing it while a session runs is allowed --
## that is the per-size-class preview obligation (DLUX-15) being exercised, not a new session.
func set_simulated_size(size: Vector2i) -> bool:
	if size.x <= 0 or size.y <= 0:
		return false
	_simulated_size = size
	return true


# ---- `[CEUI-S33]` the report ----


## Ends the session, DISCARDS the snapshot, and returns the report.
##
## The snapshot is cleared here and not merely marked stale, because `[CEUI-S3]` says the
## session discards it at exit and a retained copy is a thing a later caller could apply.
## The REPORT survives -- it is the artifact, and it holds the diff it needs.
func end_session(outcome: String, turns: int = 0, errors: Array = []) -> Dictionary:
	if _state != STATE_RUNNING:
		return {}
	_report = _build_report(outcome, turns, errors, changed_state())
	_snapshot.clear()
	_live_state.clear()
	_state = STATE_ENDED
	_keyboard_owner = KEYBOARD_EDITOR
	return report()


## `[CEUI-S33]`: the changed-state section is a DIFF AGAINST THE SNAPSHOT'S STARTING STATE,
## not a record of anything persisted. The session commits nothing, so there is no persisted
## state to report -- what the author wants is what this run WOULD have changed.
##
## `{key: {from, to}}`, including keys the run introduced (`from` absent).
func changed_state() -> Dictionary:
	var out: Dictionary = {}
	for key in _live_state:
		if not _snapshot.has(key):
			out[String(key)] = {"to": _live_state[key]}
			continue
		if _snapshot[key] != _live_state[key]:
			out[String(key)] = {"from": _snapshot[key], "to": _live_state[key]}
	for key in _snapshot:
		if not _live_state.has(key):
			out[String(key)] = {"from": _snapshot[key]}
	return out


## `[CEUI-S33]`'s content: fixture and pack version, seed, outcome, turns, errors,
## changed-state preview, navigable content references.
##
## IT IS A REPORT AND NOT A RECEIPT, AND THE WORD IS THE RULING. `[TSV-20]` owns *receipt* for
## a committed player-facing transaction record; an editor test report is a different artifact
## with a different lifetime, and letting one word mean both is how the duplicate-mechanism
## shape starts.
func report() -> Dictionary:
	return _report.duplicate(true)


func has_report() -> bool:
	return not _report.is_empty()


func _build_report(outcome: String, turns: int, errors: Array, changed: Dictionary) -> Dictionary:
	var identity: Dictionary = _working_copy.identity() if _working_copy != null else {}
	var references: Array[Dictionary] = []
	# Navigable content references: the ids the fixture named, so the report's rows are
	# somewhere the author can be sent rather than text about content.
	for field in ["entry_node_id", "map_id"]:
		var referenced := String(_fixture.get(field, ""))
		if referenced != "":
			references.append({"field": field, "id": referenced})
	return {
		"entry": _entry,
		"fixture": fixture(),
		"package_id": String(identity.get("package_id", "")),
		"package_version": String(identity.get("package_version", "")),
		"seed": int(_fixture.get("seed", 0)),
		"outcome": outcome,
		"turns": turns,
		"errors": Array(errors),
		"changed_state": changed,
		"references": references,
	}
