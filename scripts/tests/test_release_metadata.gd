extends SceneTree
# Keeps the visible version, Windows export preset, current checklist, and
# setup guide aligned so a playtester cannot mistake a stale build for current.


func _init() -> void:
	print("=== Release Metadata Test ===")
	var passed := 0
	var failed := 0

	var config := ConfigFile.new()
	var load_error := config.load("res://export_presets.cfg")
	if load_error != OK:
		print("FAIL could not load export_presets.cfg: %s" % load_error)
		quit(1)
		return

	# application/product_version is the SINGLE SOURCE OF TRUTH for the release
	# version: scripts/tools/prepare_build.sh reads it to bake build_info.json, which
	# is what the in-game BUILD STAMP reports and what a release tag is checked
	# against. This test used to carry its own hardcoded copy of the number, which
	# made the version bump a six-file hand-edit and the test a seventh — so a bump
	# could pass here while the stamp disagreed. Everything below is now checked
	# AGAINST the stamp's own source rather than against a literal.
	var version: String = config.get_value("preset.0.options", "application/product_version", "")
	var preset_name: String = config.get_value("preset.0", "name", "")
	var export_path: String = config.get_value("preset.0", "export_path", "")
	var exclude_filter: String = config.get_value("preset.0", "exclude_filter", "")
	var expected_name := "Project Prometheus v%s" % version
	var expected_path := "./builds/Project_Prometheus_v%s_debug.exe" % version

	if version.is_empty():
		print("FAIL export preset declares no application/product_version")
		failed += 1
	elif preset_name == expected_name and export_path == expected_path:
		print("OK  export preset name, path, and product version are v%s" % version)
		passed += 1
	else:
		print(
			(
				"FAIL export metadata for product_version v%s: name=%s path=%s"
				% [version, preset_name, export_path]
			)
		)
		failed += 1

	var expected_excludes := [
		"AGENT/**", "scripts/tests/**", "scripts/tools/**", "test_fixtures/**"
	]
	var excludes_ok := true
	for expected in expected_excludes:
		excludes_ok = excludes_ok and expected in exclude_filter
	if excludes_ok:
		print("OK  development-only files are excluded from exports")
		passed += 1
	else:
		print("FAIL export preset packages development-only files: %s" % exclude_filter)
		failed += 1

	var packed := load("res://scenes/ui/MainMenu.tscn")
	var menu: Control = packed.instantiate() if packed != null else null
	if menu != null:
		root.add_child(menu)
		await process_frame
	var label: Label = menu.get_node_or_null("VersionLabel") if menu != null else null
	if label != null and label.text == "v%s" % version:
		print("OK  Main Menu version label matches the export preset")
		passed += 1
	else:
		print("FAIL Main Menu version label does not match v%s" % version)
		failed += 1

	var checklist_path := "res://AGENT/Docs/playtests/playtest_checklist_v%s.md" % version
	if FileAccess.file_exists(checklist_path):
		print("OK  current versioned playtest checklist exists")
		passed += 1
	else:
		print("FAIL missing checklist: %s" % checklist_path)
		failed += 1

	var setup_text := FileAccess.get_file_as_string("res://AGENT/Docs/guides/environment_setup.md")
	if (
		"Currently at `v%s`" % version in setup_text
		and "Project_Prometheus_v%s_debug.exe" % version in setup_text
	):
		print("OK  environment setup names the current build")
		passed += 1
	else:
		print("FAIL environment setup is stale for v%s" % version)
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
