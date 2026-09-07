extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_editor_documents.gd
#
# Covers the campaign editor shell's second slice: `EditorDocument` (`[CEUI-S6]`'s staged
# transaction), `EditorDocumentSet` (`[CEUI-3]`'s tabs), `EditorWorkspaces` (`[CEUI-S12]`
# plus `EW-4`/`EW-5`/`EW-7`), `EditorIssues` (`[CEUI-S26]`) and the screen that draws them.
#
# THE ASSERTIONS THAT CARRY THE RULINGS, and that nothing else can catch:
#
#   * VALIDATION SEES COMMITTED EDITS AND NOT STAGED ONES (`[CEUI-S25]`). The ruling's
#     whole point is that the validator never consumes in-progress state, and the way that
#     breaks is a well-meaning "validate as you type". Asserted by counting validator calls
#     across a staging sequence, which a test of the resulting VALUES cannot see.
#   * A MULTI-FIELD EDIT IS ONE UNDO UNIT, AND UNDOING TO CLEAN IS CLEAN. `[CEUI-13]` made
#     the staged overlay the unit; the subtle half is that undo must restore
#     ABSENT-FROM-THE-OVERLAY rather than the saved value, or `is_dirty()` stays true
#     forever after the first edit and every dirty marker in the shell lies.
#   * SAVING DOES NOT CLEAR THE HISTORY AND DISCARDING DOES. `[CEUI-S6]` call 1 excludes
#     file operations from Undo and call 2 scopes the history to the session; those are
#     two different statements, and collapsing them either loses history a save never
#     touched or keeps history a discard was supposed to take.
#   * TABS ARE INDEPENDENT TRANSACTIONS (`[CEUI-3]`/`[CEUI-14]`). Proven by editing and
#     undoing in one document and asserting the other is untouched -- the failure mode is
#     a convenience helper that quietly rebuilds the project-wide history `[CEUI-S6]`
#     declined to adopt.
#   * THE PANEL DEFAULT IS A FUNCTION OF WORKSPACE AND HEIGHT TOGETHER. `EW-5` ruled it per
#     workspace and `EW-4` ruled it by height; either alone passes half the ruled cases.
#     Asserted at the floor and above it for a workspace that wants the panel and one that
#     does not.
#   * A COMMIT MAKES THE PACK PASS STALE, AND NEVER-VALIDATED IS NOT CLEAN (`[CEUI-S26]`).
#     "Staleness is shown, not avoided" is the ruling; a panel that showed zero issues for
#     a pack nobody had checked would satisfy every count assertion and still be wrong.
#   * SEVERITY IS RESOLVED PER GATE, NOT STORED (`[CEUI-S27]`). A rule that warns in a
#     draft and errors at a release-complete export must group as an ERROR, or a
#     release-blocking finding files itself under Warnings until the author tries to
#     export.
#   * AN ISSUE WHOSE DOCUMENT IS NOT OPEN IS FOCUSABLE BUT REFUSES WITH ITS REASON
#     (`[EPUX-07]`, via `[CEUI-S26]`'s closing paragraph). Same shape as the locked layer,
#     and the same silent-no-op failure.
#   * THE FLOOR FAILS ON HEIGHT ALONE. The wireframes measured FHD at 125% -- a common
#     Windows default -- failing by 216 px of height at full width. A floor check that
#     guarded width would pass the single configuration most likely to hit it.

const ShellScript = preload("res://scripts/editor/CampaignEditorShell.gd")
const DocumentScript = preload("res://scripts/editor/EditorDocument.gd")
const DocumentSetScript = preload("res://scripts/editor/EditorDocumentSet.gd")
const WorkspacesScript = preload("res://scripts/editor/EditorWorkspaces.gd")
const IssuesScript = preload("res://scripts/editor/EditorIssues.gd")
const MetricsScript = preload("res://scripts/editor/EditorShellMetrics.gd")
const ReportScript = preload("res://scripts/validation/ValidationReport.gd")
const RulesScript = preload("res://scripts/validation/ValidationRules.gd")
const GateScript = preload("res://scripts/validation/ValidationGate.gd")
const ScreenScene = preload("res://scenes/ui/CampaignEditorScreen.tscn")
const ResponsiveLayoutScript = preload("res://scripts/autoloads/ResponsiveLayout.gd")

## A rule that is a warning in a draft and an error at a release-complete export -- the
## exact shape `[CEUI-S27]` ruled and the reason severity is not stored on an issue.
const RULE_EXPORT_ONLY := "test.export_only"
const RULE_ALWAYS_ERROR := "test.always_error"

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Editor Documents, Tabs, Workspaces and Issues Test ===")

	_a_staged_edit_is_invisible_until_it_commits()
	_a_commit_is_one_undo_unit_and_undoing_to_clean_is_clean()
	_a_new_edit_drops_the_redo_branch()
	_saving_keeps_the_history_and_discarding_takes_it()
	_a_bulk_edit_is_one_commit_over_many_records()
	_an_external_change_offers_reload_or_keep_mine()
	_tabs_are_independent_transactions()
	_reopening_an_open_document_activates_its_tab()
	_closing_a_dirty_tab_refuses_and_says_why()
	_closing_the_active_tab_lands_on_its_neighbour()
	_the_seven_workspaces_are_the_ruled_seven()
	_the_panel_default_is_workspace_and_height_together()
	_the_second_column_is_offered_never_automatic()
	_the_panel_combines_the_pack_pass_and_the_open_documents()
	_a_commit_makes_the_pack_pass_stale_and_unvalidated_is_not_clean()
	_severity_is_resolved_per_gate()
	_an_unopenable_issue_is_focusable_but_refuses()
	_the_header_gates_test_and_export_on_a_working_copy()
	_shell_state_survives_a_recomposition()
	_the_floor_fails_on_height_alone()
	_a_region_collapses_without_moving()
	_the_input_warning_warns_and_changes_nothing_else()
	await _the_screen_draws_the_documents_and_the_issues()

	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % label)
	else:
		_failed += 1
		print("  FAIL: %s%s" % [label, ("  [%s]" % detail) if detail != "" else ""])


func _document(id: String = "doc_a") -> EditorDocument:
	return DocumentScript.open(
		id,
		"class",
		{"knight": {"hp": 20, "move": 5}, "mage": {"hp": 14, "move": 4}},
		id.capitalize()
	)


func _rules() -> ValidationRules:
	var rules := RulesScript.engine_rules()
	rules.declare(RULE_EXPORT_ONLY, RulesScript.SEVERITY_WARNING, RulesScript.SEVERITY_ERROR)
	rules.declare(RULE_ALWAYS_ERROR, RulesScript.SEVERITY_ERROR)
	return rules


# ---- `[CEUI-S6]` / `[CEUI-S25]` the staged transaction ----


func _a_staged_edit_is_invisible_until_it_commits() -> void:
	print("\n-- [CEUI-S25] validation sees committed edits, never the one being typed --")
	var document := _document()
	var calls: Array[int] = []
	var validator := func(_doc: EditorDocument) -> ValidationReport:
		calls.append(1)
		return ReportScript.create(_rules())

	document.stage("knight", "hp", 21)
	document.stage("knight", "hp", 22)
	document.stage("knight", "move", 6)
	_check("the validator has not run while the edit is staged", calls.is_empty())
	_check("the staged value is readable", int(document.value("knight", "hp")) == 22)
	_check("but the document is not dirty yet", not document.is_dirty())

	document.commit_edit(validator)
	_check("committing runs the validator exactly once", calls.size() == 1, str(calls.size()))
	_check("and the document is dirty", document.is_dirty())
	_check("and nothing is staged any more", not document.has_staged_edit())

	document.discard_staged()
	document.commit_edit(validator)
	_check("committing nothing runs no validator and adds no undo step", calls.size() == 1)
	_check("and pushes no undo entry", document.undo_depth() == 1, str(document.undo_depth()))


func _a_commit_is_one_undo_unit_and_undoing_to_clean_is_clean() -> void:
	print("\n-- [CEUI-13] one commit is one undo unit, however many fields it touched --")
	var document := _document()
	document.stage("knight", "hp", 30)
	document.stage("knight", "move", 9)
	document.commit_edit()
	_check("three fields in one commit are one undo step", document.undo_depth() == 1)

	_check("undo succeeds", document.undo())
	_check(
		"both fields are back",
		int(document.value("knight", "hp")) == 20 and int(document.value("knight", "move")) == 5
	)
	# The failure this catches: restoring the SAVED value into the overlay leaves the
	# overlay non-empty, so the document reads dirty forever after its first edit.
	_check("undoing to the start leaves the document CLEAN", not document.is_dirty())
	_check(
		"and no record is listed as dirty",
		document.dirty_record_ids().is_empty(),
		str(document.dirty_record_ids())
	)

	_check("redo succeeds", document.redo())
	_check("the values come back", int(document.value("knight", "hp")) == 30)
	_check("and the document is dirty again", document.is_dirty())


func _a_new_edit_drops_the_redo_branch() -> void:
	print("\n-- a new commit invalidates redo --")
	var document := _document()
	document.stage("knight", "hp", 30)
	document.commit_edit()
	document.undo()
	_check("redo is available after an undo", document.can_redo())
	document.stage("knight", "hp", 40)
	document.commit_edit()
	_check("a new commit clears the redo branch", not document.can_redo())
	_check("and the new value stands", int(document.value("knight", "hp")) == 40)


func _saving_keeps_the_history_and_discarding_takes_it() -> void:
	print("\n-- [CEUI-S6] save is a file operation; discard is the session boundary --")
	var document := _document()
	document.stage("knight", "hp", 30)
	document.commit_edit()
	var written := document.save()
	_check("save returns the records to write", int((written["knight"] as Dictionary)["hp"]) == 30)
	_check("and the document is clean", not document.is_dirty())
	_check("but the history is NOT cleared -- save is not an undo boundary", document.can_undo())
	document.undo()
	# The ordinary document behaviour, and the reason the undo entry records EFFECTIVE
	# values: after a save the overlay is empty, so an entry describing overlay cells would
	# undo to nothing observable -- the history would stop working at a save, which
	# `[CEUI-S6]` call 2 ("session-scoped") does not say.
	_check(
		"undoing past a save restores the pre-edit value", int(document.value("knight", "hp")) == 20
	)
	_check("and makes the document dirty against disk again", document.is_dirty())

	var second := _document()
	second.stage("knight", "hp", 30)
	second.commit_edit()
	second.discard()
	_check("discard reverts the overlay", int(second.value("knight", "hp")) == 20)
	_check(
		"and takes the session-scoped history with it",
		not second.can_undo() and not second.can_redo()
	)


func _a_bulk_edit_is_one_commit_over_many_records() -> void:
	print("\n-- [CEUI-S23] a multi-selection edit is ONE staged transaction --")
	var document := _document()
	var applied := (
		document
		. stage_many(
			[
				{"record_id": "knight", "field": "move", "value": 7},
				{"record_id": "mage", "field": "move", "value": 7},
			]
		)
	)
	_check("both cells stage", applied == 2)
	document.commit_edit()
	_check("as one undo step", document.undo_depth() == 1)
	_check(
		"both records are dirty",
		document.dirty_record_ids() == ["knight", "mage"],
		str(document.dirty_record_ids())
	)
	document.undo()
	_check(
		"and one undo reverts both",
		int(document.value("knight", "move")) == 5 and int(document.value("mage", "move")) == 4
	)


func _an_external_change_offers_reload_or_keep_mine() -> void:
	print("\n-- [CEUI-S24] reload or keep mine, and no merge --")
	var document := _document()
	document.stage("knight", "hp", 30)
	document.commit_edit()
	_check(
		"a first external change is noted", document.note_external_change({"knight": {"hp": 99}})
	)
	_check(
		"a second is not stacked over the unanswered one",
		not document.note_external_change({"knight": {"hp": 55}})
	)
	_check(
		"keep mine leaves the overlay standing",
		document.resolve_external_change(DocumentScript.EXTERNAL_KEEP_MINE)
	)
	_check("so the author's value survives", int(document.value("knight", "hp")) == 30)
	# Disk must NOT be folded into the saved state: doing so would make the document read
	# clean while still differing from the file it is about to overwrite.
	_check("and the document is still dirty against disk", document.is_dirty())

	var second := _document()
	second.stage("knight", "hp", 30)
	second.commit_edit()
	second.note_external_change({"knight": {"hp": 99}})
	second.resolve_external_change(DocumentScript.EXTERNAL_RELOAD)
	_check("reload takes disk", int(second.value("knight", "hp")) == 99)
	_check(
		"and discards the overlay by the ordinary path",
		not second.is_dirty() and not second.can_undo()
	)


# ---- `[CEUI-3]` tabs ----


func _tabs_are_independent_transactions() -> void:
	print("\n-- [CEUI-3]/[CEUI-14] each tab is its own transaction and its own history --")
	var tabs := DocumentSetScript.new()
	var first := tabs.open(_document("doc_a"))
	var second := tabs.open(_document("doc_b"))
	first.stage("knight", "hp", 30)
	first.commit_edit()
	_check(
		"only the edited document is dirty", tabs.dirty_ids() == ["doc_a"], str(tabs.dirty_ids())
	)
	_check("the other has no history to undo", not second.can_undo())
	first.undo()
	_check("undoing in one leaves the other untouched", int(second.value("knight", "hp")) == 20)
	_check("and the set reports nothing dirty", not tabs.any_dirty())


func _reopening_an_open_document_activates_its_tab() -> void:
	print("\n-- reopening an open id activates rather than duplicating --")
	var tabs := DocumentSetScript.new()
	var first := tabs.open(_document("doc_a"))
	tabs.open(_document("doc_b"))
	var again := tabs.open(first)
	_check("no second tab is created", tabs.size() == 2, str(tabs.size()))
	_check("the original document is returned", again == first)
	_check("and its tab is active", tabs.active_id() == "doc_a")


func _closing_a_dirty_tab_refuses_and_says_why() -> void:
	print("\n-- [CEUI-S6] close-without-saving is allowed, but never silently --")
	var tabs := DocumentSetScript.new()
	var document := tabs.open(_document("doc_a"))
	document.stage("knight", "hp", 30)
	document.commit_edit()
	var refused := tabs.close("doc_a")
	_check(
		"closing a dirty tab refuses", String(refused["outcome"]) == DocumentSetScript.REFUSED_DIRTY
	)
	_check(
		"and returns the reason rather than doing nothing",
		String(refused["reason"]) == DocumentSetScript.DIRTY_CLOSE_REASON
	)
	_check("the tab is still open", tabs.has("doc_a"))
	var closed := tabs.close("doc_a", true)
	_check("asking for it closes", String(closed["outcome"]) == DocumentSetScript.CLOSED)
	_check("and the tab is gone", not tabs.has("doc_a"))
	_check(
		"an unknown id refuses too",
		String(tabs.close("nope")["outcome"]) == DocumentSetScript.REFUSED_UNKNOWN
	)


func _closing_the_active_tab_lands_on_its_neighbour() -> void:
	print("\n-- closing the active tab leaves the author where they were --")
	var tabs := DocumentSetScript.new()
	tabs.open(_document("doc_a"))
	tabs.open(_document("doc_b"))
	tabs.open(_document("doc_c"))
	tabs.activate("doc_b")
	tabs.close("doc_b")
	_check(
		"the neighbour becomes active, not the first tab",
		tabs.active_id() == "doc_c",
		tabs.active_id()
	)
	tabs.close("doc_c")
	_check(
		"closing the last one falls back to what is left",
		tabs.active_id() == "doc_a",
		tabs.active_id()
	)
	tabs.close("doc_a")
	_check(
		"closing everything leaves no active document",
		tabs.active_id() == "" and tabs.active() == null
	)


# ---- `[CEUI-S12]` workspaces, `EW-4`/`EW-5`/`EW-7` ----


func _the_seven_workspaces_are_the_ruled_seven() -> void:
	print("\n-- [CEUI-S12] Content, Maps, Graph, Assets, Localization, Test, Release --")
	var workspaces := WorkspacesScript.new()
	_check(
		"the list and its order are the ruling's",
		(
			WorkspacesScript.ORDER
			== [
				WorkspacesScript.CONTENT,
				WorkspacesScript.MAPS,
				WorkspacesScript.GRAPH,
				WorkspacesScript.ASSETS,
				WorkspacesScript.LOCALIZATION,
				WorkspacesScript.TEST,
				WorkspacesScript.RELEASE,
			]
		),
		str(WorkspacesScript.ORDER)
	)
	var fully_declared := true
	for workspace_id in WorkspacesScript.ORDER:
		var declared: Dictionary = WorkspacesScript.WORKSPACES[workspace_id]
		if not declared.has("width_response") or not declared.has("panel"):
			fully_declared = false
	_check("every workspace declares a width response and a panel default", fully_declared)
	_check("Content is the default workspace", workspaces.active_id() == WorkspacesScript.CONTENT)
	_check(
		"switching works",
		(
			workspaces.activate(WorkspacesScript.MAPS)
			and workspaces.active_id() == WorkspacesScript.MAPS
		)
	)
	# A silent fallback would turn a typo into a workspace that never opens.
	_check("an unknown workspace is refused, not silently ignored", not workspaces.activate("nope"))
	_check("and the active one is unchanged", workspaces.active_id() == WorkspacesScript.MAPS)


func _the_panel_default_is_workspace_and_height_together() -> void:
	print("\n-- EW-4 + EW-5: the panel default is per workspace AND by height --")
	var workspaces := WorkspacesScript.new()
	workspaces.set_metrics(1260.0, MetricsScript.VIEWPORT_FLOOR.y)
	_check(
		"at the floor Content collapses the panel",
		not workspaces.is_panel_open(WorkspacesScript.CONTENT)
	)
	_check("Maps collapses it at every height", not workspaces.is_panel_open(WorkspacesScript.MAPS))
	_check(
		"Release keeps it open even at the floor",
		workspaces.is_panel_open(WorkspacesScript.RELEASE)
	)

	workspaces.set_metrics(1900.0, MetricsScript.VIEWPORT_ROOMY_CLASS.y)
	_check("above the floor Content opens it", workspaces.is_panel_open(WorkspacesScript.CONTENT))
	_check("and Maps still does not", not workspaces.is_panel_open(WorkspacesScript.MAPS))

	workspaces.set_panel_open(false, WorkspacesScript.CONTENT)
	workspaces.set_metrics(1900.0, MetricsScript.VIEWPORT_LARGE_CLASS.y)
	_check(
		"an author's override outranks the height rule from then on",
		not workspaces.is_panel_open(WorkspacesScript.CONTENT)
	)
	workspaces.clear_panel_override(WorkspacesScript.CONTENT)
	_check(
		"clearing it returns the workspace to the ruled default",
		workspaces.is_panel_open(WorkspacesScript.CONTENT)
	)


func _the_second_column_is_offered_never_automatic() -> void:
	print("\n-- EW-7: offered above the threshold, remembered, never automatic --")
	var workspaces := WorkspacesScript.new()
	var threshold := WorkspacesScript.split_threshold()
	workspaces.set_metrics(threshold - 1.0, MetricsScript.VIEWPORT_ROOMY_CLASS.y)
	_check("below the threshold the split is not offered", not workspaces.is_split_offered())
	_check("and cannot be enabled", not workspaces.set_split_enabled(true))
	workspaces.set_metrics(threshold, MetricsScript.VIEWPORT_ROOMY_CLASS.y)
	_check("at the threshold it is offered", workspaces.is_split_offered())
	# Automatic would be exactly the resize-changes-the-layout instability `CEUI-4` fixed.
	_check("but it is still off", not workspaces.is_split_enabled())
	_check("enabling works", workspaces.set_split_enabled(true) and workspaces.is_split_enabled())
	workspaces.set_metrics(threshold - 100.0, MetricsScript.VIEWPORT_ROOMY_CLASS.y)
	_check("shrinking below the threshold takes the column away", not workspaces.is_split_enabled())
	workspaces.set_metrics(threshold + 100.0, MetricsScript.VIEWPORT_ROOMY_CLASS.y)
	_check("and widening brings it back -- it was remembered", workspaces.is_split_enabled())
	workspaces.activate(WorkspacesScript.MAPS)
	_check("it is remembered PER workspace, so Maps has none", not workspaces.is_split_enabled())
	workspaces.activate(WorkspacesScript.CONTENT)
	_check("and Content still has its own", workspaces.is_split_enabled())


# ---- `[CEUI-S26]` the issues panel ----


func _the_panel_combines_the_pack_pass_and_the_open_documents() -> void:
	print("\n-- [CEUI-S26] the last full pass, with open documents live over it --")
	var panel := IssuesScript.new(_rules())
	var pack := ReportScript.create(_rules())
	pack.add(RULE_ALWAYS_ERROR, "stale knight problem", {"document": "doc_a", "record": "knight"})
	pack.add(RULE_ALWAYS_ERROR, "mage problem", {"document": "doc_b", "record": "mage"})
	panel.set_pack_pass(pack, "pass 1")
	_check(
		"both pack findings are listed", panel.entries().size() == 2, str(panel.entries().size())
	)

	var live := ReportScript.create(_rules())
	live.add(RULE_ALWAYS_ERROR, "fresh knight problem", {"document": "doc_a", "record": "knight"})
	panel.set_document_report("doc_a", live)
	var messages: Array[String] = []
	for entry in panel.entries():
		messages.append(String(entry["message"]))
	# Two entries for one finding, one of them known-stale, is the panel disagreeing with
	# itself in front of the author.
	_check(
		"the live document supersedes the pack pass for that document",
		not messages.has("stale knight problem"),
		str(messages)
	)
	_check("and the fresh finding is there instead", messages.has("fresh knight problem"))
	_check("the other document's pack finding survives", messages.has("mage problem"))

	panel.forget_document("doc_a")
	messages.clear()
	for entry in panel.entries():
		messages.append(String(entry["message"]))
	_check(
		"closing the document brings the pack finding back",
		messages.has("stale knight problem"),
		str(messages)
	)


func _a_commit_makes_the_pack_pass_stale_and_unvalidated_is_not_clean() -> void:
	print("\n-- [CEUI-S26] staleness is shown, not avoided --")
	var panel := IssuesScript.new(_rules())
	_check("a pack nobody validated is NOT clean", not panel.has_pack_pass())
	_check(
		"and the status line says so rather than reporting zero issues",
		panel.freshness_summary() == "Not validated",
		panel.freshness_summary()
	)

	var pack := ReportScript.create(_rules())
	pack.add(RULE_ALWAYS_ERROR, "a problem", {"document": "doc_b", "record": "mage"})
	panel.set_pack_pass(pack, "pass 1")
	_check("a fresh pass is not stale", not panel.is_pack_pass_stale())
	_check("and the summary names the pass", panel.freshness_summary().contains("pass 1"))

	panel.set_document_report("doc_a", ReportScript.create(_rules()))
	_check("any commit makes the pack pass stale", panel.is_pack_pass_stale())
	_check(
		"and the summary says edited since",
		panel.freshness_summary().contains("edited since"),
		panel.freshness_summary()
	)
	var stale_flags: Array[bool] = []
	for entry in panel.entries():
		if String(entry["origin"]) == IssuesScript.ORIGIN_PACK:
			stale_flags.append(bool(entry["stale"]))
	_check(
		"and every surviving pack entry is marked stale", stale_flags == [true], str(stale_flags)
	)


func _severity_is_resolved_per_gate() -> void:
	print("\n-- [CEUI-S27] the same finding warns in a draft and blocks a release export --")
	var panel := IssuesScript.new(_rules())
	var pack := ReportScript.create(_rules())
	pack.add(
		RULE_EXPORT_ONLY,
		"incomplete locale",
		{"document": "doc_a", "record": "en", "field": "greeting"}
	)
	panel.set_pack_pass(pack, "pass 1")
	var entry: Dictionary = panel.entries()[0]
	_check(
		"it groups as an ERROR because it errors at one gate",
		String(entry["severity"]) == RulesScript.SEVERITY_ERROR,
		String(entry["severity"])
	)
	_check(
		"and it names the gates it blocks",
		(entry["blocks_gates"] as Array).has(GateScript.EXPORT_LIBRARY),
		str(entry["blocks_gates"])
	)
	_check(
		"activation is not one of them",
		not (entry["blocks_gates"] as Array).has(GateScript.ACTIVATION),
		str(entry["blocks_gates"])
	)
	_check(
		"the panel counts it as an error", panel.error_count() == 1 and panel.warning_count() == 0
	)
	var grouped := panel.grouped()
	_check(
		"errors come first in the grouping",
		String(grouped[0]["severity"]) == RulesScript.SEVERITY_ERROR
	)
	_check(
		"and content grouping keys on the document",
		String((grouped[0]["groups"] as Array)[0]["group"]) == "doc_a"
	)


func _an_unopenable_issue_is_focusable_but_refuses() -> void:
	print("\n-- [EPUX-07] via [CEUI-S26]: an entry whose target cannot be opened --")
	var panel := IssuesScript.new(_rules())
	var openable: Array[String] = ["doc_a"]
	panel.openable_provider = func(document_id: String) -> bool: return openable.has(document_id)
	var pack := ReportScript.create(_rules())
	pack.add(
		RULE_ALWAYS_ERROR, "reachable", {"document": "doc_a", "record": "knight", "field": "hp"}
	)
	pack.add(RULE_ALWAYS_ERROR, "unreachable", {"document": "doc_z", "record": "ghost"})
	panel.set_pack_pass(pack, "pass 1")

	var reachable := ""
	var unreachable := ""
	for entry in panel.entries():
		if String(entry["message"]) == "reachable":
			reachable = String(entry["id"])
		else:
			unreachable = String(entry["id"])
	_check("the unreachable entry is still LISTED", unreachable != "")
	_check("and still focusable", panel.selector().focus(unreachable))
	var refused := panel.activate(unreachable)
	_check(
		"activating it refuses", String(refused["outcome"]) == RecordSelector.REFUSED_UNAVAILABLE
	)
	_check(
		"with the reason, not a silent no-op",
		String(refused["reason"]) == IssuesScript.UNOPENABLE_REASON
	)
	var opened := panel.activate(reachable)
	_check("the reachable one activates", String(opened["outcome"]) == RecordSelector.ACTIVATED)
	# `[CEUI-S26]` navigates to the object AND field; a record id alone is not actionable
	# when the record has forty fields.
	_check(
		"and returns the object AND the field",
		(
			String((opened["target"] as Dictionary)["record"]) == "knight"
			and String((opened["target"] as Dictionary)["field"]) == "hp"
		),
		str(opened["target"])
	)


# ---- `[CEUI-S11]` the header, and `[TSV-24]` ----


func _the_header_gates_test_and_export_on_a_working_copy() -> void:
	print("\n-- [CEUI-S11] the ruled six, gated with reasons per EPUX-02 --")
	var shell := ShellScript.new()
	var ids: Array[String] = []
	for action in shell.header_actions():
		ids.append(String(action["id"]))
	_check(
		"the header carries exactly the ruled actions", ids == ShellScript.HEADER_ACTIONS, str(ids)
	)
	var by_id: Dictionary = {}
	for action in shell.header_actions():
		by_id[String(action["id"])] = action

	# Not an "unimplemented" placeholder: `[CEUI-S9]` makes Test activate the working copy
	# and Export write it out, so with none open there is genuinely nothing to test.
	_check(
		"Test is gated without a working copy",
		not bool((by_id[ShellScript.HEADER_ACTION_TEST] as Dictionary)["available"])
	)
	_check(
		"and says why",
		(
			String((by_id[ShellScript.HEADER_ACTION_TEST] as Dictionary)["reason"])
			== ShellScript.NO_WORKING_COPY_REASON
		)
	)
	_check(
		"Undo is gated with no document open",
		not bool((by_id[ShellScript.HEADER_ACTION_UNDO] as Dictionary)["available"])
	)
	_check(
		"with the no-document reason, not the no-history one",
		(
			String((by_id[ShellScript.HEADER_ACTION_UNDO] as Dictionary)["reason"])
			== ShellScript.NO_DOCUMENT_REASON
		)
	)

	shell.set_working_copy({"id": "my_draft", "label": "My draft"})
	var document := shell.open_document("doc_a", "class", {"knight": {"hp": 20}}, "Classes")
	by_id.clear()
	for action in shell.header_actions():
		by_id[String(action["id"])] = action
	_check(
		"a working copy ungates Test and Export",
		(
			bool((by_id[ShellScript.HEADER_ACTION_TEST] as Dictionary)["available"])
			and bool((by_id[ShellScript.HEADER_ACTION_EXPORT] as Dictionary)["available"])
		)
	)
	_check(
		"Undo is still gated with an empty history",
		not bool((by_id[ShellScript.HEADER_ACTION_UNDO] as Dictionary)["available"])
	)
	_check(
		"now with the no-history reason",
		(
			String((by_id[ShellScript.HEADER_ACTION_UNDO] as Dictionary)["reason"])
			== ShellScript.NO_UNDO_REASON
		)
	)

	document.stage("knight", "hp", 30)
	shell.record_pack_validation(ReportScript.create(_rules()), "pass 0")
	shell.commit_active_edit()
	by_id.clear()
	for action in shell.header_actions():
		by_id[String(action["id"])] = action
	_check(
		"committing ungates Undo",
		bool((by_id[ShellScript.HEADER_ACTION_UNDO] as Dictionary)["available"])
	)
	_check("the draft status reports the draft dirty", bool(shell.draft_status()["dirty"]))
	# A commit routed through the shell has to reach the panel, or the panel shows the
	# previous results as current.
	_check(
		"and the commit reached the issues panel, which now reads stale",
		shell.issues().is_pack_pass_stale()
	)
	_check(
		"undo through the shell routes to the active document",
		shell.undo() and int(document.value("knight", "hp")) == 20
	)


func _shell_state_survives_a_recomposition() -> void:
	print("\n-- [TSV-24] documents, workspace and panel state survive --")
	var shell := ShellScript.new()
	shell.open_document("doc_a", "class", {"knight": {"hp": 20}}, "Classes")
	shell.open_document("doc_b", "map_data", {"m1": {"width": 10}}, "Maps")
	shell.documents().activate("doc_a")
	shell.workspaces().activate(WorkspacesScript.ASSETS)
	shell.workspaces().set_panel_open(true, WorkspacesScript.ASSETS)
	var state := shell.capture_state()

	shell.refresh()
	shell.restore_state(state)
	_check(
		"both tabs are still open",
		shell.documents().ids() == ["doc_a", "doc_b"],
		str(shell.documents().ids())
	)
	_check("the active tab survives", shell.documents().active_id() == "doc_a")
	_check(
		"the active workspace survives", shell.workspaces().active_id() == WorkspacesScript.ASSETS
	)
	_check(
		"and the author's panel override with it",
		shell.workspaces().is_panel_open(WorkspacesScript.ASSETS)
	)


func _the_floor_fails_on_height_alone() -> void:
	print("\n-- [CEUI-S2] the floor is effective, and height is the half that fails --")
	_check(
		"the floor itself is not below the floor",
		not MetricsScript.is_below_floor(MetricsScript.VIEWPORT_FLOOR)
	)
	# FHD at Windows' 125%: full width, 216 px short on height. The wireframes measured it
	# as the one common configuration that fails, and a width-only guard would pass it.
	_check(
		"FHD at 125% fails on height at full width",
		MetricsScript.is_below_floor(Vector2(1536, 864))
	)
	# `[CEUI-S2]` measures window / scale, so a 4K window at editor scale 2.0 is AT the
	# floor rather than double it.
	_check(
		"a 3840x1760 window at editor scale 2.0 is exactly the floor",
		MetricsScript.effective_size(Vector2(3840, 1760), 2.0) == MetricsScript.VIEWPORT_FLOOR
	)
	_check(
		"a non-positive scale reads as below the floor rather than dividing",
		MetricsScript.effective_size(Vector2(3840, 2160), 0.0) == Vector2.ZERO
	)
	_check(
		"the message names both the floor and the window",
		MetricsScript.minimum_size_message(Vector2(1536, 864)).contains("1536")
	)


func _a_region_collapses_without_moving() -> void:
	print("\n-- CEUI-1: regions collapse; CEUI-4: they never rearrange --")
	var shell := ShellScript.new()
	_check("regions start shown", not shell.is_region_collapsed(ShellScript.REGION_TREE))
	_check("collapsing the tree works", shell.set_region_collapsed(ShellScript.REGION_TREE, true))
	_check("and it reports collapsed", shell.is_region_collapsed(ShellScript.REGION_TREE))
	_check(
		"the Inspector is unaffected", not shell.is_region_collapsed(ShellScript.REGION_INSPECTOR)
	)
	# The bottom panel is EditorWorkspaces' -- two owners for one region's visibility is
	# how `EW-5`'s per-workspace default quietly stops being applied.
	_check(
		"the bottom panel is not a collapsible region here",
		not shell.set_region_collapsed("bottom_panel", true)
	)
	_check("nor is an invented one", not shell.set_region_collapsed("nope", true))
	var state := shell.capture_state()
	shell.set_region_collapsed(ShellScript.REGION_TREE, false)
	shell.restore_state(state)
	_check("collapse survives a recomposition", shell.is_region_collapsed(ShellScript.REGION_TREE))


func _the_input_warning_warns_and_changes_nothing_else() -> void:
	print("\n-- EW-9 option A: warn on non-kbm input, and change nothing --")
	var shell := ShellScript.new()
	_check("mouse and keyboard raises no warning", not bool(shell.input_mode_warning()["active"]))
	shell.set_input_mode("touch")
	var warning := shell.input_mode_warning()
	_check("a touch author is warned", bool(warning["active"]))
	_check(
		"and the warning says what is missing",
		String(warning["message"]) == ShellScript.NON_KBM_INPUT_WARNING
	)
	shell.set_input_mode("gamepad")
	_check("so is a gamepad author", bool(shell.input_mode_warning()["active"]))
	# Option B -- growing targets when the warning fires -- was rejected as a second
	# responsive state by another name, and `[CEUI-5]` spent real cost removing those. The
	# invariant is that the token column is untouched, not merely that nothing visibly
	# reflowed.
	var kbm := ResponsiveLayoutScript.tokens_for_mode(ResponsiveLayoutScript.MENU_MODE_EDITOR)
	shell.set_input_mode(ShellScript.INPUT_MODE_MOUSE_KEYBOARD)
	var after := ResponsiveLayoutScript.tokens_for_mode(ResponsiveLayoutScript.MENU_MODE_EDITOR)
	_check("the editor token column is identical either way", kbm == after)
	_check(
		"and the minimum target stays 24",
		float(after["min_target"]) == 24.0,
		str(after["min_target"])
	)


# ---- the screen ----


func _the_screen_draws_the_documents_and_the_issues() -> void:
	print("\n-- the screen draws the tabs, the workspace bar, the header and the panel --")
	var screen: Control = ScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	var shell: CampaignEditorShell = screen.shell()
	shell.set_working_copy({"id": "my_draft", "label": "My draft"})
	var document := shell.open_document("doc_a", "class", {"knight": {"hp": 20}}, "Classes")
	shell.open_document("doc_b", "map_data", {"m1": {"width": 10}}, "Maps")
	await process_frame

	var tabs: TabBar = screen.get_node("Shell/Body/Workspace/Centre/Tabs")
	_check("the strip draws one tab per open document", tabs.tab_count == 2, str(tabs.tab_count))

	# The tab set activates the last document opened, so the edit is committed against the
	# document it was staged on rather than whichever tab happens to be in front.
	shell.documents().activate("doc_a")
	document.stage("knight", "hp", 30)
	shell.commit_active_edit()
	await process_frame
	# `[CEUI-S17]` binds the editor to non-colour channels, so the dirty marker has to be
	# readable from the label itself.
	var dirty_label := ""
	for index in tabs.tab_count:
		if tabs.get_tab_tooltip(index) == "doc_a":
			dirty_label = tabs.get_tab_title(index)
	_check(
		"a dirty tab says so in text, not only in colour", dirty_label.contains("*"), dirty_label
	)

	var refusals: Array[String] = []
	screen.document_close_refused.connect(
		func(_id: String, reason: String) -> void: refusals.append(reason)
	)
	var outcome: Dictionary = screen.close_document("doc_a")
	_check(
		"closing a dirty tab through the screen refuses",
		String(outcome["outcome"]) == DocumentSetScript.REFUSED_DIRTY
	)
	_check(
		"and the reason leaves the screen for the confirmation to use",
		refusals.size() == 1,
		str(refusals)
	)
	_check("the tab is still there", tabs.tab_count == 2)

	var workspace_buttons: Control = screen.get_node("Shell/WorkspaceBar/Workspaces")
	_check(
		"the workspace bar draws the ruled seven",
		workspace_buttons.get_child_count() == WorkspacesScript.ORDER.size(),
		str(workspace_buttons.get_child_count())
	)
	var labels: Array[String] = []
	for child in workspace_buttons.get_children():
		labels.append((child as Button).text)
	# `[CEUI-S11]`: labels always, never icons and never truncated.
	_check("with text labels, never icons", not labels.has(""), str(labels))

	var actions: Control = screen.get_node("Shell/Header/ActionScroll/Actions")
	_check(
		"the header draws the ruled actions",
		actions.get_child_count() == ShellScript.HEADER_ACTIONS.size()
	)
	var gated_says_why := true
	for child in actions.get_children():
		var button: Button = child
		if button.disabled and button.tooltip_text == "":
			gated_says_why = false
		if button.text == "":
			gated_says_why = false
	_check("every action carries a label, and every gated one a reason", gated_says_why)

	var panel := ReportScript.create(_rules())
	panel.add(
		RULE_ALWAYS_ERROR,
		"a knight problem",
		{"document": "doc_a", "record": "knight", "field": "hp"}
	)
	panel.add(RULE_EXPORT_ONLY, "a release problem", {"document": "doc_z", "record": "ghost"})
	shell.record_pack_validation(panel, "pass 1")
	await process_frame
	var issues: Tree = screen.get_node("Shell/Body/Workspace/Centre/BottomPanel/Issues")
	var leaves := 0
	var severity_item := issues.get_root().get_first_child()
	while severity_item != null:
		var group_item := severity_item.get_first_child()
		while group_item != null:
			var leaf := group_item.get_first_child()
			while leaf != null:
				leaves += 1
				leaf = leaf.get_next()
			group_item = group_item.get_next()
		severity_item = severity_item.get_next()
	_check(
		"the panel draws every entry under severity and content headings", leaves == 2, str(leaves)
	)

	# `doc_z` is not open, so its entry is the gated one.
	var refused_entries: Array[String] = []
	screen.issue_activation_refused.connect(
		func(_id: String, reason: String) -> void: refused_entries.append(reason)
	)
	var navigated: Array[String] = []
	screen.issue_navigated.connect(
		func(doc_id: String, record: String, field: String) -> void:
			navigated.append("%s/%s/%s" % [doc_id, record, field])
	)
	for entry in shell.issues().entries():
		screen.activate_issue(String(entry["id"]))
	_check(
		"the entry whose document is not open refuses with its reason",
		refused_entries == [IssuesScript.UNOPENABLE_REASON],
		str(refused_entries)
	)
	_check(
		"and the reachable one navigates to the object and field",
		navigated == ["doc_a/knight/hp"],
		str(navigated)
	)

	var tree_pane: Control = screen.get_node("Shell/Body/TreePane")
	_check("the tree pane starts shown", tree_pane.visible)
	screen.set_region_collapsed(ShellScript.REGION_TREE, true)
	_check("collapsing hides it", not tree_pane.visible)
	screen.set_region_collapsed(ShellScript.REGION_TREE, false)
	_check("and restoring brings it back in place", tree_pane.visible)

	var input_warning: Control = screen.get_node("Shell/InputWarning")
	_check("no warning strip for a keyboard author", not input_warning.visible)
	var tree_width_before := tree_pane.custom_minimum_size.x
	screen.set_input_mode("touch")
	_check("a touch author gets the strip", input_warning.visible)
	# `EW-9`: warn, never reflow. The composition is identical with the strip up.
	_check("and the composition is untouched", tree_pane.custom_minimum_size.x == tree_width_before)
	_check(
		"the four regions are all still present",
		tree_pane.visible and screen.get_node("Shell/Body/Workspace/Inspector").visible
	)
	screen.set_input_mode(ShellScript.INPUT_MODE_MOUSE_KEYBOARD)
	_check("and it goes away again", not input_warning.visible)

	var validation: Label = screen.get_node("Shell/StatusBar/Validation")
	_check(
		"the status bar carries the validation freshness",
		validation.text.contains("pass 1"),
		validation.text
	)
	var keyboard: Label = screen.get_node("Shell/StatusBar/KeyboardOwner")
	screen.set_keyboard_owner("Issues")
	_check(
		"and states which context owns the keyboard",
		keyboard.text.contains("Issues"),
		keyboard.text
	)

	screen.queue_free()
	await process_frame
