extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_diagnostics_log.gd
#
# Exercises the DiagnosticsLog channel itself: the record format, the independent
# category gates, the per-session cap and the dedupe collapse. Those last two are
# not polish — V0715-05 was an error-storm defect, and a diagnostics programme that
# reproduced it would be worse than none. Every assertion here is about the budget
# or the parseability of a line, because those are the two properties every other
# DIAG row depends on.
#
# Drives the REAL /root/DiagnosticsLog autoload rather than an instance of its own:
# autoloads are live under `godot --headless --script`, and a stand-in named after
# one is silently renamed by the engine while production code still resolves the
# real node — a suite that goes green while testing nothing.

var passed := 0
var failed := 0


func _init() -> void:
	print("=== DiagnosticsLog Test ===")
	# Autoloads are queued, not ready, inside _init(): without this the channel has
	# not run reset() and every gate reads false.
	await process_frame

	var log_node: Node = root.get_node_or_null("DiagnosticsLog")
	if log_node == null:
		print("FAIL DiagnosticsLog autoload is not registered")
		print("\n=== Results: 0 passed, 1 failed ===")
		quit(1)
		return
	# Keep the suite's own output readable; the file and the ring are what is asserted.
	log_node.print_records = false

	_test_categories_default_on(log_node)
	_test_record_format(log_node)
	_test_value_quoting(log_node)
	_test_repeat_collapse(log_node)
	_test_category_cap(log_node)
	_test_gate_silences_one_category(log_node)
	_test_unknown_category_is_reported(log_node)
	_test_error_severity_is_counted(log_node)
	_test_ring_is_bounded(log_node)
	_test_file_receives_the_same_lines(log_node)

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _check(ok: bool, label: String, detail: String = "") -> void:
	if ok:
		print("OK  %s" % label)
		passed += 1
	else:
		print("FAIL %s%s" % [label, ("\n     %s" % detail) if not detail.is_empty() else ""])
		failed += 1


# The ten categories the work order names must all exist and all be on by default:
# a category that has to be switched on is a category nobody will have on when the
# defect appears.
func _test_categories_default_on(log_node: Node) -> void:
	log_node.reset()
	var expected := [
		"session", "viewport", "layout", "nav", "save", "pack", "battle", "campaign", "ai", "input"
	]
	var names: Array = []
	for category in log_node.CATEGORIES:
		names.append(String(category))
	var all_on := true
	for category in log_node.CATEGORIES:
		if not log_node.is_category_enabled(category):
			all_on = false
	_check(names == expected and all_on, "ten categories, all gated on by default", str(names))


func _test_record_format(log_node: Node) -> void:
	log_node.reset()
	log_node.record(&"save", &"save_slot", {"slot": 2, "outcome": "refused"})
	var line: String = log_node.format_record(log_node.records[0])
	var parts := line.split(" | ")
	var ok: bool = (
		parts.size() == 4
		and parts[0].is_valid_int()
		and parts[1] == "save"
		and parts[2] == "save_slot"
		and parts[3] == "slot=2 outcome=refused"
	)
	_check(ok, "record renders as ts_ms | category | event | key=value", line)


# A field whose value contains a space or a separator must not be able to break the
# split — a reader of the returned log has to be able to tell where a field ended.
func _test_value_quoting(log_node: Node) -> void:
	log_node.reset()
	log_node.record(&"pack", &"refused", {"reason": "training sword not found", "ids": ["a", "b"]})
	var line: String = log_node.format_record(log_node.records[0])
	var ok: bool = (
		'reason="training sword not found"' in line
		and 'ids=["a","b"]' in line
		and line.split(" | ").size() == 4
	)
	_check(ok, "values containing spaces or separators are quoted", line)


# The error-storm guard. The first occurrence is written immediately (a crash must
# not swallow it), the repeats only increment a counter, and the run is closed out
# by one xN line when a different record arrives.
func _test_repeat_collapse(log_node: Node) -> void:
	log_node.reset()
	for i in 5:
		log_node.record(&"layout", &"label_clipped", {"path": "MainMenu/NewGame"})
	var after_repeats: int = log_node.records.size()
	var repeat_count: int = int(log_node.records[0]["repeat"])
	log_node.record(&"layout", &"label_clipped", {"path": "Settings/Apply"})
	var events: Array = []
	for entry: Dictionary in log_node.records:
		events.append(String(entry["event"]))
	var ok: bool = (
		after_repeats == 1
		and repeat_count == 5
		and events == ["label_clipped", "label_clipped_repeat", "label_clipped"]
		and String(log_node.records[1]["fields"]) == "x4"
	)
	_check(ok, "five identical records collapse to one line plus an x4 follow-up", str(events))


# A runaway subscriber costs its own category and nothing else: the cap is per
# category, it says so once, and it does not silence the log.
func _test_category_cap(log_node: Node) -> void:
	log_node.reset()
	log_node.set_category_cap(&"battle", 3)
	for i in 10:
		log_node.record(&"battle", &"combat", {"index": i})
	log_node.record(&"save", &"load", {"slot": 1})
	var counters: Dictionary = log_node.counters()
	var battle: Dictionary = counters["battle"]
	var last_battle_event := ""
	for entry: Dictionary in log_node.records:
		if entry["category"] == "battle":
			last_battle_event = String(entry["event"])
	var ok: bool = (
		int(battle["emitted"]) == 4  # three records, then the capped line
		and int(battle["dropped"]) == 7
		and bool(battle["capped"])
		# Capped and suppressed are separate states: the gate was never touched here.
		and bool(battle["enabled"])
		and last_battle_event == "capped"
		and not bool(counters["save"]["capped"])
		and int(counters["save"]["emitted"]) == 1
	)
	_check(ok, "a spent category cap silences that category alone", str(counters["battle"]))


func _test_gate_silences_one_category(log_node: Node) -> void:
	log_node.reset()
	log_node.set_category_enabled(&"ai", false)
	log_node.record(&"ai", &"activation", {"unit": "brigand_01"})
	log_node.record(&"nav", &"screen_opened", {"screen": "MainMenu"})
	var categories: Array = []
	for entry: Dictionary in log_node.records:
		categories.append(String(entry["category"]))
	_check(
		categories == ["nav"] and not log_node.is_category_enabled(&"ai"),
		"a suppressed category records nothing while its neighbours continue",
		str(categories)
	)


# A typo that invented a category would produce records nobody has gated or capped,
# so an unknown name is reported through `session` instead of silently creating one.
func _test_unknown_category_is_reported(log_node: Node) -> void:
	log_node.reset()
	log_node.record(&"combat", &"anything", {})
	var ok: bool = (
		log_node.records.size() == 1
		and String(log_node.records[0]["category"]) == "session"
		and String(log_node.records[0]["event"]) == "unknown_category"
		and log_node.error_count() == 1
	)
	_check(ok, "an unknown category is reported, not silently created", str(log_node.records))


# record_error marks and counts the line — that count is what the return bundle keys
# its automatic export on — but the channel still never push_errors, because the
# storm it must not reproduce was made of push_error calls on expected states.
func _test_error_severity_is_counted(log_node: Node) -> void:
	log_node.reset()
	log_node.record(&"save", &"save_slot", {"slot": 1})
	log_node.record_error(&"save", &"save_slot", {"slot": 1, "outcome": "unresolved_id"})
	var ok: bool = (
		log_node.error_count() == 1
		and not bool(log_node.records[0]["error"])
		and bool(log_node.records[1]["error"])
		and String(log_node.records[1]["fields"]).begins_with("sev=error ")
	)
	_check(
		ok, "record_error marks sev=error and is counted; record() is not", str(log_node.records)
	)


func _test_ring_is_bounded(log_node: Node) -> void:
	log_node.reset()
	log_node.set_category_cap(&"input", 4096)
	var target: int = int(log_node.MAX_RECORDS) + 100
	for i in target:
		log_node.record(&"input", &"event", {"index": i})
	var ok: bool = (
		log_node.records.size() == int(log_node.MAX_RECORDS)
		and String(log_node.records[0]["fields"]) == "index=100"
	)
	_check(ok, "the in-memory ring stays bounded at MAX_RECORDS", str(log_node.records.size()))


# The file is the artifact a return actually carries, so it must hold the same lines
# the ring does — and hold them before the process exits, not at close().
func _test_file_receives_the_same_lines(log_node: Node) -> void:
	log_node.reset()
	log_node.record(&"campaign", &"chapter_start", {"node": "map_002"})
	log_node.record(&"campaign", &"chapter_end", {"node": "map_002", "turns": 11})
	var path: String = log_node.file_path()
	if path.is_empty():
		_check(false, "the diagnostics log file is opened on the first record")
		return
	var text := FileAccess.get_file_as_string(path)
	var ok: bool = (
		"| campaign | chapter_start | node=map_002" in text
		and "| campaign | chapter_end | node=map_002 turns=11" in text
		and path.begins_with("user://logs/diagnostics-")
		# Colons are illegal in Windows filenames and the tester is on Windows.
		and not (":" in path.get_file())
	)
	_check(ok, "records reach the log file, at a Windows-legal path", "%s\n%s" % [path, text])
