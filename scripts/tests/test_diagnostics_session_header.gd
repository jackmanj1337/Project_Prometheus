extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_diagnostics_session_header.gd
#
# The session header is the half of this row that replaces tester transcription:
# Section 1 of the v0.7.16 checklist was build identity copied out by hand, and half
# of its Section 0 existed only to put the build into a known state and read that
# state back. Both are assertions here instead.
#
# Each block is checked for the FIELDS a return actually needs, never for values —
# the values differ on every host, which is the entire point of recording them.

const DiagnosticsSession = preload("res://scripts/shared/DiagnosticsSession.gd")

var passed := 0
var failed := 0


func _init() -> void:
	print("=== DiagnosticsSession Header Test ===")
	# Autoloads are queued, not ready, inside _init(): SettingsManager has not read
	# user:// yet and DataManager has no content state without this.
	await process_frame

	_test_build_block()
	_test_platform_block()
	_test_display_and_window_blocks()
	_test_settings_block_matches_the_saved_file()
	_test_content_block()
	_test_user_data_block()
	_test_rng_block()
	await _test_header_is_written_once_and_covers_every_block()

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _check(ok: bool, label: String, detail: String = "") -> void:
	if ok:
		print("OK  %s" % label)
		passed += 1
	else:
		print("FAIL %s%s" % [label, ("\n     %s" % detail) if not detail.is_empty() else ""])
		failed += 1


func _fields_of(session_records: Array, event: String) -> Dictionary:
	for item: Dictionary in session_records:
		if String(item["event"]) == event:
			return item["fields"]
	return {}


func _has_keys(fields: Dictionary, keys: Array) -> bool:
	for key in keys:
		if not fields.has(key):
			return false
	return true


# Identity must be the same version/commit/built_at the BUILD STAMP prints, so the
# two logs a return carries can be checked against each other.
func _test_build_block() -> void:
	var fields := _fields_of(DiagnosticsSession.build_records(), "build")
	var ok := (
		_has_keys(fields, ["version", "commit", "built_at", "debug", "engine"])
		and not String(fields["version"]).is_empty()
		and not String(fields["commit"]).is_empty()
	)
	_check(ok, "build block carries version, commit, built_at and debug/release", str(fields))


func _test_platform_block() -> void:
	var records := DiagnosticsSession.platform_records()
	var platform := _fields_of(records, "platform")
	var gpu := _fields_of(records, "gpu")
	var ok := (
		_has_keys(
			platform,
			[
				"os",
				"os_version",
				"cpu",
				"cpu_threads",
				"physical_memory",
				"locale",
				"timezone",
			]
		)
		and _has_keys(gpu, ["display_server", "adapter", "vendor", "api"])
	)
	_check(ok, "platform block carries OS, CPU, memory, locale and GPU/driver", str(records))


# Headless is the only display this suite can have, so what is asserted is that the
# blocks are produced and say so rather than crashing on a screen query. The fields
# themselves are exercised on a real host by the round's native pass.
func _test_display_and_window_blocks() -> void:
	var display := _fields_of(DiagnosticsSession.display_records(), "display")
	var layout: Node = root.get_node_or_null("ResponsiveLayout")
	var window := _fields_of(DiagnosticsSession.window_records(layout), "window")
	var headless := DisplayServer.get_name() == DiagnosticsSession.HEADLESS_DISPLAY
	var ok := (
		not display.is_empty()
		and not window.is_empty()
		and (
			(headless and bool(display.get("headless", false)))
			or _has_keys(display, ["screen_count", "window_screen"])
		)
		and (
			(headless and bool(window.get("headless", false)))
			or _has_keys(
				window, ["mode", "size", "content_scale_factor", "content_scale_mode", "size_class"]
			)
		)
	)
	_check(ok, "display and window blocks survive a headless server", "%s %s" % [display, window])


# The header and settings.cfg read from ONE list (SettingsManager.snapshot()), so a
# setting added later cannot appear in the file and be missing from the log. This
# asserts that agreement directly rather than re-listing the keys here.
func _test_settings_block_matches_the_saved_file() -> void:
	var settings: Node = root.get_node_or_null("SettingsManager")
	if settings == null:
		_check(false, "SettingsManager autoload is registered")
		return
	settings.save()
	var cfg := ConfigFile.new()
	if cfg.load(settings.SETTINGS_PATH) != OK:
		_check(false, "settings.cfg is readable after save()")
		return

	var snapshot: Dictionary = settings.snapshot()
	var agrees := true
	var detail := ""
	for section: Variant in snapshot:
		for key: Variant in snapshot[section]:
			if not cfg.has_section_key(String(section), String(key)):
				agrees = false
				detail = "missing from cfg: %s/%s" % [section, key]
	for section in cfg.get_sections():
		for key in cfg.get_section_keys(section):
			if not (snapshot.has(section) and (snapshot[section] as Dictionary).has(key)):
				agrees = false
				detail = "missing from snapshot: %s/%s" % [section, key]
	_check(agrees, "snapshot() and settings.cfg describe exactly the same keys", detail)

	var records := DiagnosticsSession.settings_records(settings)
	var sections := []
	for item: Dictionary in records:
		sections.append(String((item["fields"] as Dictionary)["section"]))
	var display_fields := {}
	for item: Dictionary in records:
		if String((item["fields"] as Dictionary).get("section", "")) == "display":
			display_fields = item["fields"]
	var ok := (
		sections == ["audio", "gameplay", "display", "controls"]
		and _has_keys(
			display_fields,
			["window_mode", "resolution", "menu_scale_index", "content_scale_factor"]
		)
	)
	_check(ok, "settings block emits one record per section, keyed by section", str(sections))


# V0716-03 was the save's identity block and the installed content's disagreeing.
# The header records both sides so the disagreement is visible at a glance rather
# than after a headless probe.
func _test_content_block() -> void:
	var data_manager: Node = root.get_node_or_null("DataManager")
	var records := DiagnosticsSession.content_records(data_manager)
	var content := _fields_of(records, "content")
	var packs := _fields_of(records, "packs")
	var ok := (
		_has_keys(
			content,
			[
				"state",
				"playable",
				"package_id",
				"package_version",
				"content_schema_version",
				"content_fingerprint",
			]
		)
		and packs.has("installed")
	)
	_check(ok, "content block carries the active identity block and the pack count", str(records))


func _test_user_data_block() -> void:
	var settings: Node = root.get_node_or_null("SettingsManager")
	var fields := _fields_of(DiagnosticsSession.user_data_records(settings), "user_data")
	var ok := (
		_has_keys(fields, ["user_data_dir", "godot_log", "legacy_dir", "migration_marker"])
		and not String(fields["user_data_dir"]).is_empty()
		# SettingsManager runs the migration at _ready and keeps its report, so with
		# the autoload present the header must be able to say whether it ran.
		and (settings == null or fields.has("migration_ran"))
	)
	_check(ok, "user data block resolves the data root and the migration outcome", str(fields))


func _test_rng_block() -> void:
	var rng: Node = root.get_node_or_null("RngService")
	var fields := _fields_of(DiagnosticsSession.rng_records(rng), "rng")
	if rng == null:
		_check(false, "RngService autoload is registered")
		return
	rng.start_map(4242)
	var seeded := _fields_of(DiagnosticsSession.rng_records(rng), "rng")
	var ok: bool = (
		_has_keys(fields, ["map_seed", "history_hash"]) and int(seeded["map_seed"]) == 4242
	)
	_check(ok, "rng block reports the seed a session can be replayed from", str(seeded))


# The header as the channel actually writes it: every block present, written once,
# and a second call cannot double it.
func _test_header_is_written_once_and_covers_every_block() -> void:
	var log_node: Node = root.get_node_or_null("DiagnosticsLog")
	if log_node == null:
		_check(false, "DiagnosticsLog autoload is registered")
		return
	log_node.print_records = false
	log_node.reset()
	log_node.write_session_header()
	var first_size: int = log_node.records.size()
	log_node.write_session_header()

	var events := {}
	var non_session := []
	for entry: Dictionary in log_node.records:
		events[String(entry["event"])] = true
		if String(entry["category"]) != "session":
			non_session.append(String(entry["category"]))
	var required := [
		"build",
		"platform",
		"gpu",
		"display",
		"window",
		"settings",
		"content",
		"packs",
		"user_data",
		"rng",
		"log_open"
	]
	var missing := []
	for event in required:
		if not events.has(event):
			missing.append(event)
	var ok: bool = (
		missing.is_empty()
		and non_session.is_empty()
		and log_node.records.size() == first_size
		and log_node.error_count() == 0
	)
	_check(
		ok,
		"write_session_header emits every block once, all under `session`",
		"missing=%s stray=%s errors=%d" % [missing, non_session, log_node.error_count()]
	)

	# Principle 2, asserted rather than assumed: the header must not spend a
	# meaningful part of any category's budget before gameplay records a thing.
	var emitted: int = int((log_node.counters()["session"] as Dictionary)["emitted"])
	_check(
		emitted < int(log_node.category_cap(&"session")) / 4,
		"the header costs well under a quarter of the session budget",
		"emitted=%d cap=%d" % [emitted, log_node.category_cap(&"session")]
	)
