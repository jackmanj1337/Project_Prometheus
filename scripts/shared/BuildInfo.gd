extends RefCounted
# Build identity for the startup log stamp. Exported builds read the git commit +
# version baked into res://build_info.json by scripts/prepare_build.sh at export time
# (git is not available at runtime in a shipped build). In the editor there is no baked
# file, so the commit is read live from git and the values are tagged "-dev".
#
# No class_name on purpose: a new class_name script needs a manual global-class-cache
# entry or headless --script runs can't resolve it (project MEMORY note). Callers
# preload this script and use the static methods.

const INFO_PATH := "res://build_info.json"


# Returns {version, commit, built_at} as Strings, always populated (never missing a
# key). Falls back to safe placeholders so the stamp is printable even with no baked
# file and no git.
static func load_info() -> Dictionary:
	var info := {"version": "dev", "commit": "unknown", "built_at": "n/a"}
	if FileAccess.file_exists(INFO_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(INFO_PATH))
		if parsed is Dictionary:
			for key in ["version", "commit", "built_at"]:
				if (parsed as Dictionary).has(key):
					info[key] = str((parsed as Dictionary)[key])
	# Dev runs from the editor have no baked file — read the live commit so the stamp
	# still identifies the working tree. Tagged -dev so it's never confused for a build.
	if OS.has_feature("editor"):
		var live := _live_git_commit()
		if live != "":
			info["commit"] = "%s-dev" % live
	return info


# The startup stamp lines, written to the log by Boot so every log opens with the exact
# build identity, a fresh run timestamp (proves the log was written THIS launch), and
# the resolved user-data / log location (so a tester can always find the file — in an
# exported build this is the OS user-data dir, e.g. %APPDATA%\...\logs\godot.log).
static func stamp_lines() -> PackedStringArray:
	var info := load_info()
	# UTC ISO-8601; changes every launch so a stale log is obvious.
	var started_at := "%sZ" % Time.get_datetime_string_from_system(true)
	return PackedStringArray(
		[
			"=== BUILD STAMP ===",
			(
				"version=%s  commit=%s  built_at=%s"
				% [info["version"], info["commit"], info["built_at"]]
			),
			"started_at=%s" % started_at,
			"exe=%s" % OS.get_executable_path(),
			"user_data_dir=%s" % OS.get_user_data_dir(),
			"log=%s" % ProjectSettings.globalize_path("user://logs/godot.log"),
			"=== END BUILD STAMP ===",
		]
	)


# Machine/runtime facts that a returned playtest log can collect without asking the
# tester to transcribe Device Manager or dxdiag. Keep this separate from BUILD STAMP:
# build identity is immutable, while these values describe the host that launched it.
static func runtime_environment_lines() -> PackedStringArray:
	var timezone: Dictionary = Time.get_time_zone_from_system()
	var display_name := DisplayServer.get_name()
	var window_size := Vector2i.ZERO
	var window_mode := -1
	var screen_size := Vector2i.ZERO
	if display_name != "headless":
		window_size = DisplayServer.window_get_size()
		window_mode = DisplayServer.window_get_mode()
		screen_size = DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	return PackedStringArray(
		[
			"=== RUNTIME ENVIRONMENT ===",
			"os_name=%s" % OS.get_name(),
			"os_version=%s" % OS.get_version(),
			"os_distribution=%s" % OS.get_distribution_name(),
			"device_model=%s" % OS.get_model_name(),
			"cpu=%s" % OS.get_processor_name(),
			"cpu_threads=%d" % OS.get_processor_count(),
			"locale=%s" % OS.get_locale(),
			"timezone=%s bias_minutes=%s" % [timezone.get("name", ""), timezone.get("bias", 0)],
			"display_server=%s" % display_name,
			"rendering_api=%s" % RenderingServer.get_video_adapter_api_version(),
			"gpu_name=%s" % RenderingServer.get_video_adapter_name(),
			"gpu_vendor=%s" % RenderingServer.get_video_adapter_vendor(),
			"gpu_type=%s" % RenderingServer.get_video_adapter_type(),
			(
				"window_mode=%d window_size=%s screen_size=%s"
				% [window_mode, window_size, screen_size]
			),
			"=== END RUNTIME ENVIRONMENT ===",
		]
	)


# Live short commit from git, or "" when git/.git is unavailable (exported build).
static func _live_git_commit() -> String:
	var out: Array = []
	var code := OS.execute("git", ["rev-parse", "--short", "HEAD"], out, false)
	if code == 0 and not out.is_empty():
		return String(out[0]).strip_edges()
	return ""
