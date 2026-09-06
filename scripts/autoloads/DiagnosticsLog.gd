extends Node
# DiagnosticsLog — the one structured channel every diagnostics record is written
# through, and the owner of the session header.
#
# Why this exists: three playtest rounds in a row were decided by instrumentation
# or lost for the want of it. v0.7.16 closed a two-round-old defect in a day
# because someone had hand-built a trace for exactly one widget, and then lost
# three sections to save failures whose exact causes were already in the returned
# log while the dialogs the tester read said only that something had failed. The
# ruling that followed (2026-09-05): stop spending tester attention on
# observations the build can make itself.
#
# Precedent, not a parallel: scripts/autoloads/TransitionTelemetry.gd is already a
# bounded-ring telemetry autoload with an opt-in print policy keyed on
# OS.is_debug_build(). This generalises that shape — one record format, per-category
# gates, a bounded ring, a per-session cap and a dedupe key — rather than sitting
# beside it. TransitionTelemetry keeps its own JSON `TRANSITION` lines; it is a
# transition watchdog, and rewriting it is not this row's job.
#
# Record format (principle 4 — machine-readable first, human-readable anyway):
#
#     ts_ms | category | event | key=value key=value ...
#
# One line per record, greppable by eye and parseable by script.
#
# Budget discipline is a hard requirement, not a nicety. V0715-05 was an
# error-storm defect: expected states are recorded at info severity and NEVER
# push_error. Every category carries a per-session cap, and a record that repeats
# collapses to a single follow-up line with a count instead of N lines.

const DiagnosticsSession = preload("res://scripts/shared/DiagnosticsSession.gd")
const DiagnosticsReturnBundle = preload("res://scripts/shared/DiagnosticsReturnBundle.gd")

# The category vocabulary. Each gates independently, defaults on, and is
# individually suppressible at runtime (set_category_enabled) or at launch
# (PROMETHEUS_DIAG_CATEGORIES) so a noisy category can be silenced without a
# rebuild. Unknown categories are rejected rather than silently created: a typo
# that invents a category would produce records nobody has gated or capped.
const CATEGORIES: Array[StringName] = [
	&"session",
	&"viewport",
	&"layout",
	&"nav",
	&"save",
	&"pack",
	&"battle",
	&"campaign",
	&"ai",
	&"input",
]

const CATEGORY_SESSION := &"session"

# Bounded in memory, as TransitionTelemetry already does with MAX_RECORDS. The
# ring is what a crash-time dump and the return bundle read; it is not the log.
const MAX_RECORDS := 512

# Per-category, per-session line budget. Reaching it emits one `capped` record and
# then silences that category — a runaway subscriber can cost one category, never
# the log. Overridable per category (set_category_cap) and at launch
# (PROMETHEUS_DIAG_CAP).
const DEFAULT_CATEGORY_CAP := 400

const LOG_DIR := "user://logs"

# Launch-time overrides, so a support session can change what is recorded without a
# rebuild. PROMETHEUS_DIAG_CATEGORIES accepts:
#   (unset) / "all"   every category on
#   "none"            every category off
#   "save,pack"       only the named categories on
#   "-layout,-battle" every category on except the named ones
# Mixing bare and -prefixed names is an allow-list plus removals.
const ENV_CATEGORIES := "PROMETHEUS_DIAG_CATEGORIES"
const ENV_CAP := "PROMETHEUS_DIAG_CAP"

# Printing to stdout duplicates every record into godot.log. That is deliberate for
# a debug build — the tester bundle ships the debug executable, the return collects
# both files, and a headless suite can then assert on stdout. A release build keeps
# the file and the ring only, exactly as TransitionTelemetry reasoned about its own
# unconditional print.
var print_records := OS.is_debug_build()

var records: Array[Dictionary] = []

var _enabled: Dictionary = {}  # StringName -> bool
var _caps: Dictionary = {}  # StringName -> int
var _emitted: Dictionary = {}  # StringName -> int, lines actually written
var _dropped: Dictionary = {}  # StringName -> int, records refused after the cap
# Kept separate from _enabled on purpose: an exhausted budget and a deliberately
# suppressed category are different states, and folding them together would both
# lose the dropped count and let a re-enable silently un-cap.
var _capped: Dictionary = {}  # StringName -> bool
# Repeat collapse state, per category: the last record's dedupe key and how many
# times it has been seen since it was written.
var _last_key: Dictionary = {}  # StringName -> String
var _last_count: Dictionary = {}  # StringName -> int

var _error_count := 0
var _file: FileAccess = null
var _file_path := ""
var _file_open_attempted := false
var _header_written := false
var _automatic_bundle_attempted := false
var last_bundle_result: Dictionary = {}


func _ready() -> void:
	reset()
	get_tree().node_added.connect(_on_tree_node_added)
	call_deferred("_attach_settings_actions")


func _exit_tree() -> void:
	if _error_count > 0 and not _automatic_bundle_attempted:
		_automatic_bundle_attempted = true
		var automatic_result := export_return_bundle("error_exit", false)
		if not bool(automatic_result.get("ok", false)):
			print("DIAGNOSTICS_BUNDLE_ERROR %s" % str(automatic_result.get("errors", [])))
	close()


# Restores every gate, cap and counter to its launch state. Called from _ready();
# public so a suite can drive the channel repeatedly without a fresh boot.
func reset() -> void:
	records.clear()
	_error_count = 0
	_automatic_bundle_attempted = false
	last_bundle_result = {}
	_header_written = false
	for category in CATEGORIES:
		_enabled[category] = true
		_caps[category] = DEFAULT_CATEGORY_CAP
		_emitted[category] = 0
		_dropped[category] = 0
		_capped[category] = false
		_last_key[category] = ""
		_last_count[category] = 0
	_apply_environment_overrides()


# The support hotkey is deliberately outside the editable gameplay bindings: it
# must remain available when a profile's controls are damaged. Settings exposes
# the same action with its label so a tester does not need to memorize it.
func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if (
		not key.pressed
		or key.echo
		or key.keycode != KEY_F12
		or not key.ctrl_pressed
		or not key.shift_pressed
	):
		return
	export_return_bundle("hotkey")
	get_viewport().set_input_as_handled()


func _on_tree_node_added(node: Node) -> void:
	if node.name == "SettingsScreen":
		call_deferred("_attach_settings_action", node)


func _attach_settings_actions() -> void:
	for node in get_tree().root.find_children("SettingsScreen", "Control", true, false):
		_attach_settings_action(node)


func _attach_settings_action(settings_screen: Node) -> void:
	if not is_instance_valid(settings_screen):
		return
	var vbox := settings_screen.get_node_or_null("Panel/ScrollContainer/Margin/VBox")
	if vbox == null or vbox.get_node_or_null("BtnExportDiagnostics") != null:
		return
	var button := Button.new()
	button.name = "BtnExportDiagnostics"
	button.text = "Export Diagnostics"
	button.tooltip_text = (
		"Export a diagnostics bundle with logs, build information, settings, saves, and "
		+ "installed pack manifests. Hotkey: Ctrl+Shift+F12."
	)
	button.pressed.connect(func() -> void: export_return_bundle("settings"))
	vbox.add_child(button)
	var back := vbox.get_node_or_null("BtnBack")
	if back != null:
		vbox.move_child(button, back.get_index())


func export_return_bundle(reason: String = "manual", notify_player: bool = true) -> Dictionary:
	# Flush first so the archive contains the current record tail even when the
	# tester exports immediately after an error or a visible failure state.
	snapshot()
	var result := DiagnosticsReturnBundle.write(self, reason)
	last_bundle_result = result.duplicate(true)
	if notify_player:
		_show_bundle_result(result)
	return result


func _show_bundle_result(result: Dictionary) -> void:
	var path := String(result.get("absolute_path", result.get("path", "")))
	if DisplayServer.get_name() == "headless":
		print(
			(
				"DIAGNOSTICS_BUNDLE %s %s"
				% [
					"OK" if bool(result.get("ok", false)) else "ERROR",
					path if not path.is_empty() else str(result.get("errors", []))
				]
			)
		)
		return
	var dialog := AcceptDialog.new()
	dialog.title = "Diagnostics Bundle"
	dialog.dialog_text = (
		"Diagnostics bundle written to:\n%s" % path
		if bool(result.get("ok", false))
		else "Diagnostics bundle could not be written.\n%s" % str(result.get("errors", []))
	)
	get_tree().root.add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.close_requested.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(760, 240))


# ── Recording ────────────────────────────────────────────────────────────────


# The one entry point. `fields` is rendered in insertion order as key=value pairs.
# `dedupe_key` overrides the default collapse key (event plus the rendered fields)
# for a record whose fields always differ but which is conceptually the same line —
# a per-frame measurement, say. Never push_errors: an expected state is info.
func record(
	category: StringName, event: StringName, fields: Dictionary = {}, dedupe_key: String = ""
) -> void:
	_write(category, event, fields, dedupe_key, false)


# For a genuinely unexpected state. Recorded like any other line but marked with
# sev=error, counted, and reported by error_count() — which is what the return
# bundle keys its automatic export on. Still does not push_error: the storm this
# channel must not reproduce was made of push_error calls on states that turned out
# to be expected. Call push_error at the call site when the engine itself is wrong.
func record_error(
	category: StringName, event: StringName, fields: Dictionary = {}, dedupe_key: String = ""
) -> void:
	_write(category, event, fields, dedupe_key, true)


func _write(
	category: StringName, event: StringName, fields: Dictionary, dedupe_key: String, is_error: bool
) -> void:
	if not _enabled.has(category):
		# An unknown category is a caller bug, not a runtime condition. Say so once
		# through the session category rather than inventing an ungated bucket.
		_write(
			CATEGORY_SESSION,
			&"unknown_category",
			{"category": String(category), "event": String(event)},
			"unknown_category:%s" % category,
			true
		)
		return
	if not bool(_enabled[category]) or bool(_capped[category]):
		if bool(_capped[category]):
			_dropped[category] = int(_dropped[category]) + 1
		return

	var rendered := _render_fields(fields)
	if is_error:
		rendered = "sev=error" if rendered.is_empty() else "sev=error %s" % rendered
	var key := dedupe_key if not dedupe_key.is_empty() else "%s %s" % [event, rendered]

	# Repeat collapse. The first occurrence is written immediately so the log stays
	# live for a crash; the repeats only increment a counter, and the run is closed
	# out by a single `<event>_repeat xN` line when a different record arrives in
	# this category (or at flush/close). Buffering the first line instead would lose
	# exactly the records a crash makes interesting.
	if String(_last_key[category]) == key:
		_last_count[category] = int(_last_count[category]) + 1
		if not records.is_empty():
			var last: Dictionary = records[records.size() - 1]
			if last["category"] == String(category) and last["dedupe_key"] == key:
				last["repeat"] = int(last["repeat"]) + 1
		return
	_flush_repeat(category)

	if int(_emitted[category]) >= int(_caps[category]):
		# One line saying the budget is spent, then silence for this category only.
		# Written through _emit_line so the cap check it just failed cannot swallow
		# the very record that explains the silence.
		_capped[category] = true
		_dropped[category] = int(_dropped[category]) + 1
		_emit_line(
			category,
			&"capped",
			"limit=%d note=category_silenced_for_this_session" % int(_caps[category]),
			"capped",
			false
		)
		return

	if is_error:
		_error_count += 1
	_last_key[category] = key
	_last_count[category] = 1
	_emit_line(category, event, rendered, key, is_error)


func _emit_line(
	category: StringName, event: StringName, rendered: String, key: String, is_error: bool
) -> void:
	var entry := {
		"ts_ms": Time.get_ticks_msec(),
		"category": String(category),
		"event": String(event),
		"fields": rendered,
		"dedupe_key": key,
		"repeat": 1,
		"error": is_error,
	}
	records.append(entry)
	while records.size() > MAX_RECORDS:
		records.pop_front()
	_emitted[category] = int(_emitted[category]) + 1
	_output(format_record(entry))


# Closes an open run of repeats for one category, writing the `xN` follow-up line
# the collapse owes its reader. Deliberately bypasses the cap: this line stands for
# records the cap already spared, and dropping it would leave a count nobody can
# read.
func _flush_repeat(category: StringName) -> void:
	var count := int(_last_count.get(category, 0))
	var event_name := &"repeat"
	if count > 1 and not records.is_empty():
		event_name = StringName("%s_repeat" % String(records[records.size() - 1]["event"]))
	_last_key[category] = ""
	_last_count[category] = 0
	if count > 1:
		_emit_line(category, event_name, "x%d" % (count - 1), "", false)


func format_record(entry: Dictionary) -> String:
	var line := (
		"%d | %s | %s" % [int(entry["ts_ms"]), String(entry["category"]), String(entry["event"])]
	)
	var fields := String(entry["fields"])
	if not fields.is_empty():
		line += " | %s" % fields
	return line


func _output(line: String) -> void:
	if print_records:
		print("DIAG %s" % line)
	var file := _ensure_file()
	if file != null:
		file.store_line(line)
		# Flushed per record on purpose: the sessions this channel exists for are the
		# ones that end in a crash or a force-quit, and an unflushed tail is exactly
		# the part a return needs. The per-category caps bound how often this happens.
		file.flush()


# ── Session header ───────────────────────────────────────────────────────────


# Written once at boot (Boot.gd calls this straight after the BUILD STAMP) and
# idempotent, so a second caller cannot double the header. The mutable parts —
# settings, window, content — have their own emitters below and are re-emitted on
# change by whoever owns that change.
func write_session_header() -> void:
	if _header_written:
		return
	_header_written = true
	# Connected here rather than in _ready(): this autoload is registered FIRST so
	# every later autoload can record during its own _ready(), which means
	# /root/SettingsManager does not exist yet at that point. Boot calls this after
	# the whole autoload list is up.
	#
	# The settings block is the mutable half of the header, and half of the v0.7.16
	# checklist's Section 0 existed only to put the build into a known state and have
	# it read back. Re-emitting on change makes the build say what state it is in.
	# An unchanged snapshot collapses to a repeat line, so a save() that changed
	# nothing costs one counter increment.
	var settings := get_node_or_null("/root/SettingsManager")
	if (
		settings != null
		and settings.has_signal("settings_changed")
		and not settings.settings_changed.is_connected(_on_settings_changed)
	):
		settings.settings_changed.connect(_on_settings_changed)
	_record_all(DiagnosticsSession.build_records())
	_record_all(DiagnosticsSession.platform_records())
	_record_all(DiagnosticsSession.display_records())
	emit_window_snapshot()
	emit_settings_snapshot()
	emit_content_snapshot()
	_record_all(DiagnosticsSession.user_data_records(get_node_or_null("/root/SettingsManager")))
	_record_all(DiagnosticsSession.rng_records(get_node_or_null("/root/RngService")))
	# Last, because the file is opened lazily by the first record above — before that
	# there is no path to report.
	record(CATEGORY_SESSION, &"log_open", {"path": globalized_file_path()})


func emit_window_snapshot() -> void:
	_record_all(DiagnosticsSession.window_records(get_node_or_null("/root/ResponsiveLayout")))


func emit_settings_snapshot() -> void:
	_record_all(DiagnosticsSession.settings_records(get_node_or_null("/root/SettingsManager")))


func emit_content_snapshot() -> void:
	_record_all(DiagnosticsSession.content_records(get_node_or_null("/root/DataManager")))


func _record_all(session_records: Array) -> void:
	for item: Dictionary in session_records:
		record(
			StringName(item.get("category", CATEGORY_SESSION)),
			StringName(item.get("event", "record")),
			item.get("fields", {}),
			String(item.get("dedupe_key", ""))
		)


func _on_settings_changed() -> void:
	if not _header_written:
		return
	emit_settings_snapshot()


# ── Gates, caps and inspection ───────────────────────────────────────────────


func is_category_enabled(category: StringName) -> bool:
	return bool(_enabled.get(category, false))


func set_category_enabled(category: StringName, enabled: bool) -> void:
	if not _enabled.has(category):
		return
	if not enabled:
		_flush_repeat(category)
	_enabled[category] = enabled


func category_cap(category: StringName) -> int:
	return int(_caps.get(category, 0))


func set_category_cap(category: StringName, cap: int) -> void:
	if _caps.has(category):
		_caps[category] = maxi(0, cap)


func error_count() -> int:
	return _error_count


func file_path() -> String:
	return _file_path


func globalized_file_path() -> String:
	return "" if _file_path.is_empty() else ProjectSettings.globalize_path(_file_path)


# The ring, with every pending repeat run closed out first, so a reader never sees
# a count that is still moving. This is what the return bundle serialises.
func snapshot() -> Array[Dictionary]:
	flush()
	return records.duplicate(true)


func counters() -> Dictionary:
	var result := {}
	for category: StringName in CATEGORIES:
		result[String(category)] = {
			"enabled": bool(_enabled[category]),
			"capped": bool(_capped[category]),
			"cap": int(_caps[category]),
			"emitted": int(_emitted[category]),
			"dropped": int(_dropped[category]),
		}
	return result


func flush() -> void:
	for category: StringName in CATEGORIES:
		_flush_repeat(category)
	if _file != null:
		_file.flush()


func close() -> void:
	flush()
	if _file != null:
		_file.close()
		_file = null


# ── Internals ────────────────────────────────────────────────────────────────


# Rendered in insertion order. A value that would break the `key=value` split — a
# space, a `|`, an `=` or a quote — is JSON-quoted, so the line stays parseable
# without the reader having to guess where a field ended.
func _render_fields(fields: Dictionary) -> String:
	var parts := PackedStringArray()
	for key: Variant in fields:
		parts.append("%s=%s" % [String(key), _render_value(fields[key])])
	return " ".join(parts)


func _render_value(value: Variant) -> String:
	match typeof(value):
		TYPE_DICTIONARY, TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY:
			return JSON.stringify(value)
		TYPE_BOOL:
			return "true" if bool(value) else "false"
		TYPE_FLOAT:
			# Fixed precision keeps a float from re-rendering differently run to run,
			# which would defeat the dedupe key on an otherwise identical record.
			return "%.4f" % float(value)
	var text := str(value)
	if text.is_empty():
		return '""'
	for forbidden in [" ", "|", "=", '"', "\n", "\t"]:
		if forbidden in text:
			return JSON.stringify(text)
	return text


# Opened lazily on the first record. A headless test suite boots every autoload, so
# opening at _ready would leave one empty log per suite in the worker's isolated
# user:// for a run that recorded nothing.
func _ensure_file() -> FileAccess:
	if _file != null:
		return _file
	if _file_open_attempted:
		return null
	_file_open_attempted = true
	if DirAccess.make_dir_recursive_absolute(LOG_DIR) != OK:
		return null
	# Colons are illegal in Windows filenames and the tester is on Windows, so the
	# timestamp is ISO-8601 BASIC (no separators) rather than the extended form.
	var stamp := Time.get_datetime_string_from_system(true).replace("-", "").replace(":", "")
	_file_path = "%s/diagnostics-%s-%d.log" % [LOG_DIR, stamp, OS.get_process_id()]
	_file = FileAccess.open(_file_path, FileAccess.WRITE)
	if _file == null:
		_file_path = ""
	return _file


func _apply_environment_overrides() -> void:
	var cap_text := OS.get_environment(ENV_CAP).strip_edges()
	if cap_text.is_valid_int():
		for category: StringName in CATEGORIES:
			_caps[category] = maxi(0, cap_text.to_int())

	var spec := OS.get_environment(ENV_CATEGORIES).strip_edges().to_lower()
	if spec.is_empty() or spec == "all":
		return
	if spec == "none":
		for category: StringName in CATEGORIES:
			_enabled[category] = false
		return
	var names := spec.split(",", false)
	# A spec made only of removals is "everything except these"; any bare name makes
	# it an allow-list, and removals then subtract from that list.
	var has_allow := false
	for raw in names:
		if not raw.strip_edges().begins_with("-"):
			has_allow = true
	if has_allow:
		for category: StringName in CATEGORIES:
			_enabled[category] = false
	for raw in names:
		var name_text := raw.strip_edges()
		var remove := name_text.begins_with("-")
		if remove:
			name_text = name_text.substr(1)
		var category := StringName(name_text)
		if _enabled.has(category):
			_enabled[category] = not remove
