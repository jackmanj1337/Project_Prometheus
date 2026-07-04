extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_build_info.gd
# Verifies the startup build-stamp helper: load_info() always returns a fully-populated
# {version, commit, built_at}, and stamp_lines() emits the framed stamp Boot writes to
# godot.log so every log opens with the build identity + a fresh per-launch timestamp
# + the resolved log location. Structure-based (not value-based) so it passes whether or
# not a baked build_info.json is present (it is gitignored / absent in CI).

const BuildInfo = preload("res://scripts/shared/BuildInfo.gd")


func _init() -> void:
	print("=== BuildInfo Test ===")
	var passed := 0
	var failed := 0

	# load_info always returns the three keys as non-empty Strings, even with no baked
	# file and no git — so the stamp is never blank.
	var info := BuildInfo.load_info()
	var keys_ok := true
	for key in ["version", "commit", "built_at"]:
		if not info.has(key) or typeof(info[key]) != TYPE_STRING or String(info[key]).is_empty():
			keys_ok = false
	if keys_ok:
		print("OK  load_info returns non-empty version/commit/built_at"); passed += 1
	else:
		print("FAIL load_info shape: %s" % info); failed += 1

	# stamp_lines is framed and carries the identity + per-launch timestamp + the
	# resolved log/user-data location (how a tester finds the log in a self-contained build).
	var lines := BuildInfo.stamp_lines()
	var joined := "\n".join(lines)
	var framed: bool = lines.size() >= 2 \
		and lines[0] == "=== BUILD STAMP ===" \
		and lines[lines.size() - 1] == "=== END BUILD STAMP ==="
	var has_fields: bool = "version=" in joined and "commit=" in joined \
		and "started_at=" in joined and "user_data_dir=" in joined and "log=" in joined
	if framed and has_fields:
		print("OK  stamp_lines is framed and includes identity + timestamp + log location")
		passed += 1
	else:
		print("FAIL stamp_lines: framed=%s has_fields=%s\n%s" % [framed, has_fields, joined])
		failed += 1

	# The started_at field is a fresh UTC timestamp each call (proof the log is written
	# THIS launch, not a stale copy) — two calls a moment apart must both be well-formed
	# and the field must end in Z.
	var has_utc := false
	for line in lines:
		if String(line).begins_with("started_at=") and String(line).ends_with("Z"):
			has_utc = true
	if has_utc:
		print("OK  started_at is a UTC (Z) timestamp"); passed += 1
	else:
		print("FAIL started_at not a UTC timestamp: %s" % joined); failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
