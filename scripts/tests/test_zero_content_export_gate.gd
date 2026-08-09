extends SceneTree
# Guards the release boundary: authoring data stays available to the extractor in
# editor checkouts, but no export may bake it into the engine package.


func _init() -> void:
	var config := ConfigFile.new()
	var errors: Array[String] = []
	if config.load("res://export_presets.cfg") != OK:
		errors.append("cannot load export_presets.cfg")
	else:
		var preset := 0
		while config.has_section("preset.%d" % preset):
			var excluded := String(config.get_value("preset.%d" % preset, "exclude_filter", ""))
			if "data/**" not in excluded.split(","):
				errors.append("preset %d does not exclude data/**" % preset)
			preset += 1
		if preset == 0:
			errors.append("no export presets found")
	var manager_source := FileAccess.get_file_as_string("res://scripts/autoloads/DataManager.gd")
	if 'OS.has_feature("editor")' not in manager_source:
		errors.append("project-data compatibility activation is not editor-gated")
	var source := FileAccess.get_file_as_string("res://scripts/ui/NewGameScreen.gd")
	if 'select_campaign_source", "res://data"' in source:
		errors.append("New Game can still reactivate res://data")
	if errors.is_empty():
		print("OK  every export excludes project data and compatibility activation is editor-only")
		quit(0)
	else:
		for error in errors:
			print("FAIL " + error)
		quit(1)
