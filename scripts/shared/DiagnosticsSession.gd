extends RefCounted
# Builds the DiagnosticsLog session header: the block of records written once at
# boot that says exactly what build, on what machine, in what state, against what
# content, this session is.
#
# It is a plain RefCounted of static functions returning [{category, event, fields}]
# rather than code inside the autoload, so a suite can assert on the header without
# a boot, a window or a file. DiagnosticsLog just records what these return.
#
# No class_name on purpose — a new class_name script needs a global-class-cache
# entry before a headless --script run can resolve it (see BuildInfo.gd for the same
# note). Callers preload this script and use the static methods.
#
# What the header must carry is not a wishlist: half of the v0.7.16 checklist's
# Section 0 existed only to put the build into a known state and have the tester
# transcribe it back, and its Section 1 was build identity by hand. Both are here.

const BuildInfo = preload("res://scripts/shared/BuildInfo.gd")
const CampaignPackRegistry = preload("res://scripts/resources/CampaignPackRegistry.gd")
const UserDataMigrationScript = preload("res://scripts/shared/UserDataMigration.gd")

const CATEGORY := &"session"

# DisplayServer reports this name when there is no display at all (headless CI, a
# --script suite). Every screen and window query is guarded on it: asking a headless
# server for screen 0 is not a diagnostic, it is a crash.
const HEADLESS_DISPLAY := "headless"

const WINDOW_MODES: Dictionary = {
	DisplayServer.WINDOW_MODE_WINDOWED: "windowed",
	DisplayServer.WINDOW_MODE_MINIMIZED: "minimized",
	DisplayServer.WINDOW_MODE_MAXIMIZED: "maximized",
	DisplayServer.WINDOW_MODE_FULLSCREEN: "fullscreen",
	DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN: "exclusive_fullscreen",
}

const VSYNC_MODES: Dictionary = {
	DisplayServer.VSYNC_DISABLED: "disabled",
	DisplayServer.VSYNC_ENABLED: "enabled",
	DisplayServer.VSYNC_ADAPTIVE: "adaptive",
	DisplayServer.VSYNC_MAILBOX: "mailbox",
}

const CONTENT_SCALE_MODES: Dictionary = {
	Window.CONTENT_SCALE_MODE_DISABLED: "disabled",
	Window.CONTENT_SCALE_MODE_CANVAS_ITEMS: "canvas_items",
	Window.CONTENT_SCALE_MODE_VIEWPORT: "viewport",
}

const CONTENT_SCALE_ASPECTS: Dictionary = {
	Window.CONTENT_SCALE_ASPECT_IGNORE: "ignore",
	Window.CONTENT_SCALE_ASPECT_KEEP: "keep",
	Window.CONTENT_SCALE_ASPECT_KEEP_WIDTH: "keep_width",
	Window.CONTENT_SCALE_ASPECT_KEEP_HEIGHT: "keep_height",
	Window.CONTENT_SCALE_ASPECT_EXPAND: "expand",
}


# Build identity — the same version/commit/built_at the exporter bakes into
# res://build_info.json and the BUILD STAMP prints, so the diagnostics log and
# godot.log can be checked against each other without trusting either alone.
static func build_records() -> Array:
	var info := BuildInfo.load_info()
	return [
		_record(
			&"build",
			{
				"version": info["version"],
				"commit": info["commit"],
				"built_at": info["built_at"],
				"debug": OS.is_debug_build(),
				"editor": OS.has_feature("editor"),
				"template": OS.has_feature("template"),
				"engine": Engine.get_version_info().get("string", ""),
			}
		),
	]


static func platform_records() -> Array:
	var timezone: Dictionary = Time.get_time_zone_from_system()
	var memory: Dictionary = OS.get_memory_info()
	return [
		_record(
			&"platform",
			{
				"os": OS.get_name(),
				"os_version": OS.get_version(),
				"distribution": OS.get_distribution_name(),
				"model": OS.get_model_name(),
				"cpu": OS.get_processor_name(),
				"cpu_threads": OS.get_processor_count(),
				"physical_memory": int(memory.get("physical", -1)),
				"locale": OS.get_locale(),
				"timezone": String(timezone.get("name", "")),
				"timezone_bias_minutes": int(timezone.get("bias", 0)),
			}
		),
		_record(
			&"gpu",
			{
				"display_server": DisplayServer.get_name(),
				"adapter": RenderingServer.get_video_adapter_name(),
				"vendor": RenderingServer.get_video_adapter_vendor(),
				"type": RenderingServer.get_video_adapter_type(),
				"api": RenderingServer.get_video_adapter_api_version(),
			}
		),
	]


# One record per screen, with its DPI, refresh rate and scale — the facts a
# "looks wrong on my monitor" return turns on, and which no tester should have to
# find in Display Settings.
static func display_records() -> Array:
	if DisplayServer.get_name() == HEADLESS_DISPLAY:
		return [_record(&"display", {"headless": true, "screen_count": 0})]
	var screen_count := DisplayServer.get_screen_count()
	var current := DisplayServer.window_get_current_screen()
	var result: Array = [
		_record(&"display", {"screen_count": screen_count, "window_screen": current}),
	]
	for index in screen_count:
		var usable := DisplayServer.screen_get_usable_rect(index)
		(
			result
			. append(
				_record(
					&"screen",
					{
						"index": index,
						"size": str(DisplayServer.screen_get_size(index)),
						"usable": "%s+%s" % [str(usable.size), str(usable.position)],
						"dpi": DisplayServer.screen_get_dpi(index),
						"refresh_hz": DisplayServer.screen_get_refresh_rate(index),
						"scale": DisplayServer.screen_get_scale(index),
						"current": index == current,
					}
				)
			)
		)
	return result


# Window geometry and the WHOLE content-scale configuration. The defect class the
# v0.7.15 and v0.7.16 rounds kept hitting is a coordinate derived from a viewport
# that has since changed, and none of these values were in any returned log.
# DIAG-VIEWPORT-TRACE re-emits this on every change; here it is the resting state.
static func window_records(layout: Node = null) -> Array:
	if DisplayServer.get_name() == HEADLESS_DISPLAY:
		return [_record(&"window", {"headless": true})]
	var fields := {
		"mode": WINDOW_MODES.get(DisplayServer.window_get_mode(), "unknown"),
		"size": str(DisplayServer.window_get_size()),
		"position": str(DisplayServer.window_get_position()),
		"borderless": DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS),
		"vsync": VSYNC_MODES.get(DisplayServer.window_get_vsync_mode(), "unknown"),
	}
	var window: Window = layout.get_window() if layout != null and layout.is_inside_tree() else null
	if window != null:
		fields["viewport_size"] = str(window.get_visible_rect().size)
		fields["content_scale_mode"] = CONTENT_SCALE_MODES.get(window.content_scale_mode, "unknown")
		fields["content_scale_aspect"] = CONTENT_SCALE_ASPECTS.get(
			window.content_scale_aspect, "unknown"
		)
		fields["content_scale_size"] = str(window.content_scale_size)
		fields["content_scale_factor"] = window.content_scale_factor
		fields["stretch_scale"] = window.get_stretch_transform().get_scale().x
	if layout != null:
		fields["size_class"] = String(layout.get("size_class"))
		fields["logical_size"] = str(layout.get("logical_size"))
		fields["menu_mode"] = String(layout.get("menu_mode"))
		fields["density"] = String(layout.get("info_density"))
	return [_record(&"window", fields)]


# Every persisted setting, one record per section. Sourced from
# SettingsManager.snapshot(), which is the same list save() writes, so the header
# cannot drift from the file.
static func settings_records(settings: Node = null) -> Array:
	if settings == null or not settings.has_method("snapshot"):
		return [_record(&"settings", {"available": false})]
	var result: Array = []
	var snapshot: Dictionary = settings.call("snapshot")
	for section: Variant in snapshot:
		var fields := {"section": String(section)}
		fields.merge(snapshot[section])
		result.append(_record(&"settings", fields))
	return result


# The active content identity, plus every installed pack. Fingerprints are what
# V0716-03 turned on: a save and the installed content disagreeing about which
# campaign they belonged to, invisible until both blocks were printed together.
static func content_records(data_manager: Node = null) -> Array:
	var active := {}
	var result: Array = []
	if data_manager != null and data_manager.has_method("content_status"):
		var status: Dictionary = data_manager.call("content_status")
		active = status.get("package", {})
		(
			result
			. append(
				_record(
					&"content",
					{
						"state": int(status.get("state", -1)),
						"playable": bool(status.get("playable", false)),
						"package_id": String(active.get("package_id", "")),
						"package_version": String(active.get("package_version", "")),
						"content_schema_version": int(active.get("content_schema_version", 0)),
						"content_fingerprint": String(active.get("content_fingerprint", "")),
						"errors": int((status.get("errors", []) as Array).size()),
						"warnings": int((status.get("warnings", []) as Array).size()),
					}
				)
			)
		)
	else:
		result.append(_record(&"content", {"available": false}))

	# A full refresh() parses every installed pack's catalogue, which is the only
	# way to get its schema version and fingerprint — the manifest alone does not
	# carry them. MainMenu does the same refresh moments later; paying for it once
	# more at boot buys the identity block that decided the last two returns.
	var registry := CampaignPackRegistry.new(CampaignPackRegistry.DEFAULT_STORAGE_ROOT)
	var summaries := registry.refresh()
	result.append(_record(&"packs", {"installed": summaries.size()}))
	for summary: Dictionary in summaries:
		(
			result
			. append(
				_record(
					&"pack",
					{
						"package_id": String(summary.get("package_id", "")),
						"package_version": String(summary.get("package_version", "")),
						"content_schema_version": int(summary.get("content_schema_version", 0)),
						"content_fingerprint": String(summary.get("content_fingerprint", "")),
						"campaigns": int((summary.get("campaigns", []) as Array).size()),
						"active":
						(
							(
								String(summary.get("package_id", ""))
								== String(active.get("package_id", ""))
							)
							and (
								String(summary.get("package_version", ""))
								== String(active.get("package_version", ""))
							)
						),
						"path": String(summary.get("path", "")),
					}
				)
			)
		)
	for error: String in registry.errors():
		result.append(_record(&"pack_error", {"detail": error}))
	return result


# Where the player's data actually is, and whether the v0.7.1 rename migration ran.
# An install that launched with no saves and default settings because user:// moved
# is indistinguishable from data loss without this record.
static func user_data_records(settings: Node = null) -> Array:
	var fields := {
		"user_data_dir": OS.get_user_data_dir(),
		"godot_log": ProjectSettings.globalize_path("user://logs/godot.log"),
		"legacy_dir": UserDataMigrationScript.legacy_dir(),
		"migration_marker": FileAccess.file_exists(UserDataMigrationScript.MARKER_PATH),
	}
	# SettingsManager runs the migration (it is the first user:// reader) and keeps
	# its report. Absent that node the marker above is still the durable answer.
	if settings != null:
		var report: Variant = settings.get("user_data_migration_report")
		if report is Dictionary:
			fields["migration_ran"] = bool((report as Dictionary).get("ran", false))
			fields["migration_copied"] = (report as Dictionary).get("copied", [])
			fields["migration_skipped"] = (report as Dictionary).get("skipped", [])
			fields["migration_errors"] = (report as Dictionary).get("errors", [])
	return [_record(&"user_data", fields)]


# The two ints that restore the entire dice timeline (RNG-1..RNG-4), so a returned
# session can be replayed rather than guessed at. Zero at boot: a seed is rolled per
# map in start_map(), and DIAG-BATTLE-CAMPAIGN re-records it there.
static func rng_records(rng: Node = null) -> Array:
	if rng == null:
		return [_record(&"rng", {"available": false})]
	return [
		_record(
			&"rng",
			{"map_seed": int(rng.get("map_seed")), "history_hash": int(rng.get("history_hash"))}
		),
	]


static func _record(event: StringName, fields: Dictionary) -> Dictionary:
	return {"category": CATEGORY, "event": event, "fields": fields}
