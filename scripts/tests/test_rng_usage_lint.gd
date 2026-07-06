extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_rng_usage_lint.gd
# T5 raw-RNG guard (B1-PKGA Slice 1d; rng_determinism_design §10). Gameplay
# code must never draw from engine-global RNG: every die comes from an
# RngService event RNG (RNG-1). This scan fails on:
#   - raw randi/randf/randi_range/randf_range/randomize calls, or a
#     RandomNumberGenerator.new() construction, in non-test GDScript outside
#     RngService.gd, unless the line carries an end-of-line `# rng-allow:
#     <reason>` tag (presentation randomness and documented fallbacks);
#   - ANY surviving `pre-M9a` tag, even on an otherwise-exempt line — those
#     marked the four raw gameplay sites Slices 1b/1c migrated, so one
#     reappearing means a half-migrated site is hiding behind the old tag.
# The pre-commit/CI shell guard (scripts/ci/check_rng_usage.sh) scans the same
# call patterns as a fast first layer; this suite adds the constructor check +
# the pre-M9a tripwire and runs inside the Godot test harness.

const SCAN_ROOT := "res://scripts"
const EXEMPT_FILES: Array[String] = ["res://scripts/autoloads/RngService.gd"]
const SKIP_DIR := "tests"

var _raw_call: RegEx
var _raw_ctor: RegEx


func _scan_file(path: String, violations: Array[String]) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		violations.append("%s: unreadable" % path)
		return
	var line_no := 0
	while not f.eof_reached():
		var line := f.get_line()
		line_no += 1
		if line.contains("pre-M9a"):
			violations.append("%s:%d: stale pre-M9a tag — migrate the site, don't re-tag it"
				% [path, line_no])
			continue
		if line.contains("rng-allow"):
			continue
		if path in EXEMPT_FILES:
			continue
		if _raw_call.search(line) != null or _raw_ctor.search(line) != null:
			violations.append("%s:%d: raw engine RNG — draw from an RngService event RNG "
				% [path, line_no] + "or tag `# rng-allow: <reason>`")


func _scan_dir(dir_path: String, violations: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		violations.append("%s: unopenable directory" % dir_path)
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			if entry != SKIP_DIR and not entry.begins_with("."):
				_scan_dir(dir_path.path_join(entry), violations)
		elif entry.ends_with(".gd"):
			_scan_file(dir_path.path_join(entry), violations)
		entry = dir.get_next()
	dir.list_dir_end()


func _init() -> void:
	print("=== Raw-RNG Usage Lint (T5) ===")
	_raw_call = RegEx.new()
	_raw_call.compile("\\b(randi|randf|randi_range|randf_range|randomize)\\s*\\(")
	_raw_ctor = RegEx.new()
	_raw_ctor.compile("RandomNumberGenerator\\s*\\.\\s*new\\s*\\(")

	var violations: Array[String] = []
	_scan_dir(SCAN_ROOT, violations)

	for v in violations:
		print("FAIL ", v)
	if violations.is_empty():
		print("OK  no raw gameplay RNG outside RngService; no stale pre-M9a tags")

	print("\n=== Results: %d passed, %d failed ===" % [
		1 if violations.is_empty() else 0, violations.size()])
	quit(0 if violations.is_empty() else 1)
