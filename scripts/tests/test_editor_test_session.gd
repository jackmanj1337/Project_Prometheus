extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_editor_test_session.gd
#
# Covers `[CEUI-S3]`'s embedded playable session, `[CEUI-S18]`'s three entry points,
# `[CEUI-S19]`/`[CEUI-S20]`'s fixtures and `[CEUI-S33]`'s test report -- `EditorTestSession`
# over a real `EditorWorkingCopy`, plus the surface that hosts the simulator.
#
# THE ASSERTIONS THAT CARRY THE RULINGS, and that nothing else can catch:
#
#   * A SESSION REFUSES TO LAUNCH WITH UNSANDBOXED SAVES (`[CEUI-S3]` point 3, `[CEUI-S9]`
#     call 3). `EditorEntry` can point `save_dir` into the draft, but the hazard is the call
#     being FORGOTTEN, and a session that trusted its caller would autosave into the player's
#     slots -- a data-loss bug, not a UX wrinkle. Asserted against the player's own save root,
#     which is the exact path that would be used if nobody sandboxed anything.
#   * EXACTLY THREE ENTRY POINTS, and a fourth id is refused. `[CEUI-S18]` closed the list and
#     `[CEUI-S51]` keeps pseudolocale capture out of it; a session that accepted an arbitrary
#     entry would be the unstable developer surface option C was rejected for.
#   * VALIDATION-ONLY PRODUCES A REPORT AND NO SESSION. It takes no snapshot and contests no
#     keyboard, which is what makes it the cheap check it was kept for.
#   * THE SNAPSHOT IS DISCARDED AT EXIT, and the report survives. `[DLUX-15]` forbids a
#     preview committing campaign state; the resolution was a snapshot, so a retained one is a
#     thing a later caller could apply.
#   * THE CHANGED-STATE SECTION IS A DIFF AGAINST THE STARTING STATE (`[CEUI-S33]`), not a
#     record of anything persisted -- including for a key the run introduced and one it
#     removed, which a naive diff over the live state alone reports as nothing.
#   * THE SESSION DOES NOT TAKE THE KEYBOARD AT LAUNCH (`[CEUI-S3]` point 4). Click-to-focus
#     and an explicit release; a launch that swallowed the author's next keystroke is the
#     failure the ruling is about.
#   * THE SIMULATOR NEVER GROWS PAST 1:1 (`WIDTH_SIMULATOR_FIXED`). Extra width becomes
#     SURROUND. Asserted at a 4K-ish pane, because the failure is invisible at the size the
#     wireframes were drawn at and only appears on a big monitor.
#   * A DANGLING FIXTURE REFERENCE IS A WARNING AT EVERY GATE (`[CEUI-S19]` guardrail 2). If
#     it were an error it could block `CampaignPackInstaller` and stop a PLAYER installing a
#     pack that is perfectly playable.
#   * A FIXTURE HOLDS DECLARATIVE FIELDS ONLY (`[CEUI-S20]`). A caller handing over runtime
#     state keeps the ruled fields and loses the rest, rather than being trusted not to.

const SessionScript = preload("res://scripts/editor/EditorTestSession.gd")
const WorkingCopyScript = preload("res://scripts/editor/EditorWorkingCopy.gd")
const GateScript = preload("res://scripts/validation/ValidationGate.gd")
const WorkspacesScript = preload("res://scripts/editor/EditorWorkspaces.gd")
const RegistryScript = preload("res://scripts/resources/CampaignPackRegistry.gd")

const FIXTURE := "res://test_fixtures/campaign_packs/two_map_skirmish"
const SOURCE_ID := "two_map_skirmish"
const SOURCE_VERSION := "1.0"
const WORK := "user://test_editor_test_session"

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Editor Test Session Test ===")

	_there_are_exactly_three_entry_points()
	_a_session_refuses_to_launch_with_unsandboxed_saves()
	_validation_only_produces_a_report_and_no_session()
	_the_snapshot_is_discarded_at_exit_and_the_report_survives()
	_the_changed_state_is_a_diff_against_the_starting_state()
	_the_session_does_not_take_the_keyboard_at_launch()
	_the_simulator_never_grows_past_one_to_one()
	_a_fixture_holds_declarative_fields_only()
	_a_dangling_fixture_reference_is_a_warning_at_every_gate()
	_two_theme_scopes_are_declared_and_the_pack_reaches_only_its_viewport()
	await _the_screen_hosts_the_simulator_only_in_the_test_workspace()

	_cleanup()
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % label)
	else:
		_failed += 1
		print("  FAIL: %s%s" % [label, ("  [%s]" % detail) if detail != "" else ""])


## A real working copy on disk, because the sandbox assertion is about PATHS and a stub that
## answered `contains()` however the test wanted would assert nothing. Built the way
## `test_editor_working_copy.gd` builds one: install the shipped fixture, then import a copy.
func _working_copy() -> EditorWorkingCopy:
	var storage := WORK.path_join("packs")
	_remove_tree(storage)
	_remove_tree(WORK.path_join("drafts"))
	var errors: Array[String] = []
	var catalogue := Tier2Catalogue.load_campaign_pack(FIXTURE, errors)
	if catalogue == null:
		return null
	var destination := RegistryScript.build_path(
		storage, SOURCE_ID, SOURCE_VERSION, catalogue.content_fingerprint()
	)
	_copy_tree(FIXTURE, destination)
	var copy := WorkingCopyScript.new(WORK.path_join("drafts"), storage)
	copy.import_from_installed(SOURCE_ID, SOURCE_VERSION)
	return copy


func _cleanup() -> void:
	_remove_tree(WORK)


static func _copy_tree(source: String, destination: String) -> void:
	DirAccess.make_dir_recursive_absolute(destination)
	var directory := DirAccess.open(source)
	if directory == null:
		return
	directory.list_dir_begin()
	var name := directory.get_next()
	while name != "":
		var from := source.path_join(name)
		var to := destination.path_join(name)
		if directory.current_is_dir():
			_copy_tree(from, to)
		else:
			DirAccess.copy_absolute(from, to)
		name = directory.get_next()
	directory.list_dir_end()


static func _remove_tree(target: String) -> void:
	var directory := DirAccess.open(target)
	if directory == null:
		return
	directory.list_dir_begin()
	var name := directory.get_next()
	while name != "":
		var child := target.path_join(name)
		if directory.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(child)
		name = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(target)


func _session() -> EditorTestSession:
	var session := SessionScript.new()
	session.set_working_copy(_working_copy())
	return session


# ---- `[CEUI-S18]` the entry points ----


func _there_are_exactly_three_entry_points() -> void:
	print("\n-- there are exactly three entry points --")
	_check(
		"campaign start, node with a fixture, validation only",
		(
			SessionScript.ENTRY_POINTS
			== (
				[
					SessionScript.ENTRY_CAMPAIGN_START,
					SessionScript.ENTRY_NODE_WITH_FIXTURE,
					SessionScript.ENTRY_VALIDATION_ONLY,
				]
				as Array[String]
			)
		),
		str(SessionScript.ENTRY_POINTS)
	)
	var session := _session()
	var refused := session.launch("arbitrary_runtime_scene", {}, "whatever")
	_check(
		"a fourth id is refused, with its reason",
		(
			not bool(refused["launched"])
			and String(refused["reason"]) == SessionScript.UNKNOWN_ENTRY_REASON
		)
	)
	var rows := SessionScript.entry_points(true, false)
	_check("all three are offered", rows.size() == 3)
	_check(
		"the node entry is GATED without a fixture, not hidden",
		(
			not bool(rows[1]["available"])
			and String(rows[1]["reason"]) == SessionScript.NO_FIXTURE_REASON
		)
	)
	_check("and validation-only stays available, because it needs none", bool(rows[2]["available"]))
	var no_copy := SessionScript.entry_points(false, true)
	_check(
		"with no working copy all three are gated on that instead",
		(
			not bool(no_copy[0]["available"])
			and String(no_copy[0]["reason"]) == SessionScript.NO_WORKING_COPY_REASON
		)
	)


# ---- `[CEUI-S9]` call 3 the save sandbox ----


func _a_session_refuses_to_launch_with_unsandboxed_saves() -> void:
	print("\n-- a session refuses to launch with unsandboxed saves --")
	var copy := _working_copy()
	var session := SessionScript.new()
	session.set_working_copy(copy)
	# The exact path the player's saves use, which is where they go if nobody sandboxed.
	var unsandboxed := session.launch(
		SessionScript.ENTRY_CAMPAIGN_START, {"gold": 100}, "user://saves"
	)
	_check("the launch is refused", not bool(unsandboxed["launched"]))
	_check(
		"and names the hazard rather than the mechanism",
		String(unsandboxed["reason"]) == SessionScript.UNSANDBOXED_SAVES_REASON,
		String(unsandboxed["reason"])
	)
	var nowhere := session.launch(SessionScript.ENTRY_CAMPAIGN_START, {"gold": 100}, "")
	_check(
		"an unset save directory is refused too -- it resolves to the player's default",
		not bool(nowhere["launched"])
	)
	var sandboxed := session.launch(
		SessionScript.ENTRY_CAMPAIGN_START, {"gold": 100}, copy.session_save_dir()
	)
	_check(
		"and the working copy's own session directory is accepted",
		bool(sandboxed["launched"]),
		String(sandboxed["reason"])
	)
	_check("the session is running", session.is_running())
	var twice := session.launch(SessionScript.ENTRY_CAMPAIGN_START, {}, copy.session_save_dir())
	_check(
		"a second launch over a running one is refused",
		(
			not bool(twice["launched"])
			and String(twice["reason"]) == SessionScript.ALREADY_RUNNING_REASON
		)
	)


func _validation_only_produces_a_report_and_no_session() -> void:
	print("\n-- validation-only produces a report and no session --")
	var session := _session()
	var result := session.launch(SessionScript.ENTRY_VALIDATION_ONLY, {"gold": 100}, "")
	_check("it launches with no sandbox needed", bool(result["launched"]), String(result["reason"]))
	_check("no session is running", not session.is_running())
	_check("nothing was snapshotted", session.snapshot().is_empty())
	_check("the keyboard is untouched", session.keyboard_owner() == SessionScript.KEYBOARD_EDITOR)
	_check("and there is a report", session.has_report())
	_check(
		"which names the entry it came from",
		String(session.report()["entry"]) == SessionScript.ENTRY_VALIDATION_ONLY
	)


# ---- `[CEUI-S3]` the snapshot, `[CEUI-S33]` the report ----


func _the_snapshot_is_discarded_at_exit_and_the_report_survives() -> void:
	print("\n-- the snapshot is discarded at exit; the report survives --")
	var copy := _working_copy()
	var session := SessionScript.new()
	session.set_working_copy(copy)
	session.launch(SessionScript.ENTRY_CAMPAIGN_START, {"gold": 100}, copy.session_save_dir())
	_check("the starting state is held while it runs", session.snapshot() == {"gold": 100})
	var report := session.end_session("victory", 7, ["a trigger fired twice"])
	_check("the snapshot is gone", session.snapshot().is_empty())
	_check("the session has ended", session.state() == SessionScript.STATE_ENDED)
	_check("and the report survives it", session.has_report())
	_check(
		"carrying pack identity, seed, outcome, turns and errors",
		(
			String(report["package_id"]) == WorkingCopyScript.mint_draft_id(SOURCE_ID)
			and String(report["outcome"]) == "victory"
			and int(report["turns"]) == 7
			and (report["errors"] as Array).size() == 1
		),
		str(report)
	)
	_check(
		"ending a session that is not running returns nothing",
		session.end_session("again").is_empty()
	)


func _the_changed_state_is_a_diff_against_the_starting_state() -> void:
	print("\n-- the changed-state section is a diff against the starting state --")
	var copy := _working_copy()
	var session := SessionScript.new()
	session.set_working_copy(copy)
	session.launch(
		SessionScript.ENTRY_CAMPAIGN_START, {"gold": 100, "chapter": "one"}, copy.session_save_dir()
	)
	session.record_change("gold", 40)
	session.record_change("recruited", "mira")
	var changed := session.changed_state()
	_check(
		"a changed value reports both sides",
		(changed["gold"] as Dictionary) == {"from": 100, "to": 40},
		str(changed)
	)
	_check(
		"a key the run INTRODUCED is reported with no 'from'",
		(changed["recruited"] as Dictionary) == {"to": "mira"},
		str(changed)
	)
	_check("and an untouched key is absent", not changed.has("chapter"))
	var report := session.end_session("defeat", 3)
	_check(
		"the report carries the diff after the snapshot is gone",
		(report["changed_state"] as Dictionary).has("gold")
	)
	_check(
		"and nothing was committed to the working copy",
		not FileAccess.file_exists("%s/data/gold.json" % copy.path())
	)


func _the_session_does_not_take_the_keyboard_at_launch() -> void:
	print("\n-- the session does not take the keyboard at launch --")
	var copy := _working_copy()
	var session := SessionScript.new()
	session.set_working_copy(copy)
	session.launch(SessionScript.ENTRY_CAMPAIGN_START, {}, copy.session_save_dir())
	_check(
		"the editor still owns it after a launch",
		session.keyboard_owner() == SessionScript.KEYBOARD_EDITOR
	)
	_check("click-to-focus hands it over", session.focus_session())
	_check("and the owner says so", session.keyboard_owner() == SessionScript.KEYBOARD_SESSION)
	session.release_keyboard()
	_check(
		"the explicit release takes it back",
		session.keyboard_owner() == SessionScript.KEYBOARD_EDITOR
	)
	session.end_session("ended")
	_check("and a session that is not running cannot take it", not session.focus_session())


# ---- `WIDTH_SIMULATOR_FIXED` ----


func _the_simulator_never_grows_past_one_to_one() -> void:
	print("\n-- the simulator never grows past 1:1; extra width is surround --")
	var qhd := SessionScript.simulator_rect(Vector2(2560, 1440))
	_check("it reaches 1:1 with room to spare", is_equal_approx(float(qhd["scale"]), 1.0))
	# The failure is invisible at the size the wireframes were drawn at.
	var uhd := SessionScript.simulator_rect(Vector2(3840, 2160))
	_check("and does NOT grow at 4K", is_equal_approx(float(uhd["scale"]), 1.0), str(uhd["scale"]))
	_check(
		"the surplus becomes surround",
		(uhd["surround"] as Vector2).x > 2000.0,
		str(uhd["surround"])
	)
	_check(
		"the drawn size stays the simulated size",
		(uhd["size"] as Vector2) == Vector2(1280, 720),
		str(uhd["size"])
	)
	# It still shrinks: a cropped preview misreports the layout in the other direction.
	var small := SessionScript.simulator_rect(Vector2(640, 360))
	_check(
		"a small pane scales down rather than cropping", is_equal_approx(float(small["scale"]), 0.5)
	)
	var other_class := SessionScript.simulator_rect(Vector2(3840, 2160), Vector2i(600, 900))
	_check(
		"a different simulated size class is respected, not the editor's",
		(other_class["size"] as Vector2) == Vector2(600, 900),
		str(other_class["size"])
	)


# ---- `[CEUI-S19]`/`[CEUI-S20]` fixtures ----


func _a_fixture_holds_declarative_fields_only() -> void:
	print("\n-- a fixture holds declarative fields only --")
	var session := _session()
	(
		session
		. set_fixture(
			{
				"entry_node_id": "crossroads",
				"seed": 42,
				"roster": ["mira"],
				"live_unit_node": "a captured runtime object",
				"map_ledger": {"turns": []},
			}
		)
	)
	var fixture := session.fixture()
	_check("the ruled fields are kept", fixture.has("entry_node_id") and fixture.has("seed"))
	_check(
		"and a captured runtime object is dropped, not trusted",
		not fixture.has("live_unit_node") and not fixture.has("map_ledger"),
		str(fixture.keys())
	)
	_check(
		"the seed is a fixture FIELD, riding the ratified determinism model",
		SessionScript.FIXTURE_FIELDS.has("seed")
	)
	var rows := SessionScript.entry_points(true, true)
	_check("with a fixture the node entry becomes available", bool(rows[1]["available"]))


func _a_dangling_fixture_reference_is_a_warning_at_every_gate() -> void:
	print("\n-- a dangling fixture reference is a warning at every gate --")
	var session := _session()
	session.set_fixture({"entry_node_id": "deleted_node", "map_id": "chapter_01"})
	var report := session.validate_fixture({"chapter_01": true})
	_check("the missing node raises one issue", report.size() == 1, str(report.size()))
	_check("a warning while authoring", report.warnings(GateScript.ACTIVATION).size() == 1)
	# The half that matters: if this escalated it could stop a PLAYER installing a pack that
	# is perfectly playable.
	_check(
		"and STILL a warning at a release-complete export",
		report.warnings(GateScript.EXPORT_LIBRARY).size() == 1
	)
	_check("so it blocks nothing", not report.blocks(GateScript.EXPORT_LIBRARY))
	var clean := session.validate_fixture({"chapter_01": true, "deleted_node": true})
	_check("a fixture that resolves raises nothing", clean.is_empty())


func _two_theme_scopes_are_declared_and_the_pack_reaches_only_its_viewport() -> void:
	print("\n-- two theme scopes, and the pack's reaches only its own viewport --")
	var scopes := SessionScript.theme_scopes()
	_check("there are exactly two", scopes.size() == 2)
	_check(
		"the chrome scope is the editor's and covers the shell",
		(
			String(scopes[0]["id"]) == SessionScript.THEME_SCOPE_CHROME
			and String(scopes[0]["owner"]) == "editor"
		)
	)
	_check(
		"the pack scope is confined to the session's sub-viewport",
		(
			String(scopes[1]["owner"]) == "pack"
			and String(scopes[1]["contains"]).contains("sub-viewport")
		),
		String(scopes[1]["contains"])
	)


# ---- the surface ----


func _the_screen_hosts_the_simulator_only_in_the_test_workspace() -> void:
	print("\n-- the screen hosts the simulator only in the Test workspace --")
	var packed: PackedScene = load("res://scenes/ui/CampaignEditorScreen.tscn")
	var screen: Node = packed.instantiate()
	root.add_child(screen)
	await process_frame

	var shell: CampaignEditorShell = screen.shell()
	var copy := _working_copy()
	screen.open_working_copy(copy)
	screen.rebuild()
	await process_frame

	var panel: Control = screen.get_node(
		"Shell/Body/Workspace/Centre/DocumentColumns/Document/TestSession"
	)
	_check("the simulator is absent in the Content workspace", not panel.visible)

	shell.workspaces().activate(WorkspacesScript.TEST)
	await process_frame
	_check("and present in Test with a working copy", panel.visible)

	var entries: HBoxContainer = screen.get_node(
		"Shell/Body/Workspace/Centre/DocumentColumns/Document/TestSession/Entries"
	)
	_check(
		"all three entry points are drawn, gated ones included",
		entries.get_child_count() == 3,
		str(entries.get_child_count())
	)
	var node_entry: Button = entries.get_child(1) as Button
	_check("the node entry is disabled with no fixture", node_entry.disabled)
	_check("and carries its reason", node_entry.tooltip_text != "")

	# `[CEUI-S33]`: the report is the bottom panel's, which is why `EditorWorkspaces` defaults
	# that panel OPEN for Test.
	var report_panel: Control = screen.get_node(
		"Shell/Body/Workspace/Centre/BottomPanel/TestReport"
	)
	var viewport: SubViewport = (
		screen
		. get_node(
			"Shell/Body/Workspace/Centre/DocumentColumns/Document/TestSession/Surround/Simulator/Viewport"
		)
	)
	_check(
		"the sub-viewport is the SIMULATED size, not the editor's pane",
		viewport.size == SessionScript.DEFAULT_SIMULATED_SIZE,
		str(viewport.size)
	)

	_check("no report yet, so the panel shows issues", not report_panel.visible)
	# Driven through the model with the screen's own working copy, which is what
	# `_refresh_test_session()` keeps in sync.
	screen.test_session().launch(SessionScript.ENTRY_VALIDATION_ONLY, {}, "")
	screen.rebuild()
	await process_frame
	_check("a validation-only run puts a report in the bottom panel", report_panel.visible)
	_check(
		"and Test is the workspace whose panel defaults OPEN",
		(
			String((WorkspacesScript.WORKSPACES[WorkspacesScript.TEST] as Dictionary)["panel"])
			== WorkspacesScript.PANEL_OPEN
		)
	)

	shell.workspaces().activate(WorkspacesScript.CONTENT)
	await process_frame
	_check("leaving Test takes the simulator away again", not panel.visible)

	screen.queue_free()
	await process_frame
