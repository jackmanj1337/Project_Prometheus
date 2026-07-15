extends SceneTree
# Export admits only validated package files and round-trips their exact bytes.

const Exporter = preload("res://scripts/resources/CampaignPackExporter.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const Preflight = preload("res://scripts/resources/CampaignArchivePreflight.gd")
const ROOT := "export-fixture"


func _init() -> void:
	print("=== Campaign Pack Exporter Test ===")
	var passed := 0
	var failed := 0
	var scratch := "user://test_campaign_pack_exporter"
	Installer._remove_tree(scratch)
	var source := scratch.path_join("source")
	_write_fixture(source)
	_write_bytes(source.path_join("save_slot.json"), _json_bytes({
		"save_label": "forbidden", "map_runtime": {}, "suspend": {},
	}))
	_write_bytes(source.path_join(".godot/cache.bin"), PackedByteArray([1, 2, 3]))
	_write_bytes(source.path_join("assets/readme.txt"), "not media".to_utf8_buffer())

	var first_path := scratch.path_join("first.zip")
	var second_path := scratch.path_join("second.zip")
	var exporter := Exporter.new()
	var first = exporter.export_zip(source, first_path, _limits())
	var second = exporter.export_zip(source, second_path, _limits())
	if first.exported and second.exported \
			and _read_bytes(first_path) == _read_bytes(second_path):
		print("OK  repeated exports are byte-deterministic"); passed += 1
	else:
		print("FAIL deterministic exports: first=%s second=%s" % [first.errors, second.errors]); failed += 1

	var entry_paths: Array[String] = []
	if first.preflight != null:
		for entry in first.preflight.entries:
			if not entry.get("is_directory", false):
				entry_paths.append(String(entry["path"]))
	var sorted_paths := entry_paths.duplicate()
	sorted_paths.sort()
	if entry_paths == sorted_paths \
			and not entry_paths.any(func(path): return "save" in path or ".godot" in path or path.ends_with("readme.txt")):
		print("OK  archive order is lexical and excludes saves, caches, and unrelated files"); passed += 1
	else:
		print("FAIL admitted export paths: %s" % [entry_paths]); failed += 1

	var install = Installer.new(scratch.path_join("store")).install_zip(first_path, first.preflight)
	if install.installed and _tree_bytes(source, true) == _tree_bytes(install.installed_path, false):
		print("OK  preflighted export/import round trip preserves every admitted byte"); passed += 1
	else:
		print("FAIL round trip: %s" % [install.errors]); failed += 1

	var broken := scratch.path_join("broken")
	_write_fixture(broken)
	DirAccess.remove_absolute(broken.path_join("data/class.json"))
	var broken_result = exporter.export_zip(broken, scratch.path_join("broken.zip"), _limits())
	if not broken_result.exported and not FileAccess.file_exists(broken_result.archive_path):
		print("OK  missing required content rejects export without an artifact"); passed += 1
	else:
		print("FAIL broken export: %s" % [broken_result.errors]); failed += 1

	Installer._remove_tree(scratch)
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _limits():
	return Preflight.Limits.new(32, 200000, 200000, 500000, 500000)


func _write_fixture(root: String) -> void:
	var files := {
		"manifest.json": {
			"id": ROOT, "version": "1.0", "forked_from": "",
			"builder_content_version": "0.4", "format_version": 1,
		},
		"data/catalogue.json": {
			"format_version": 1,
			"entries": [
				{"kind": "campaign", "id": "fixture", "path": "data/campaign.json"},
				{"kind": "map_registry", "id": "maps", "path": "data/map_registry.json"},
				{"kind": "map_data", "id": "map_01", "path": "data/map_01.json"},
				{"kind": "roster", "id": "heroes", "path": "data/roster.json"},
				{"kind": "class", "id": "fixture_class", "path": "data/class.json"},
			],
		},
		"data/campaign.json": {
			"campaign_id": "fixture", "label": "Fixture", "start_node_id": "start",
			"nodes": [{"node_id": "start", "label": "Start", "map_id": "map_01", "next": []}],
		},
		"data/map_registry.json": [{
			"id": "map_01", "label": "Map", "map_data_id": "map_01", "roster_id": "heroes",
		}],
		"data/map_01.json": {
			"id": "map_01", "display_name": "Map", "grid": ["..."],
			"player_start_tiles": [[0, 0]],
		},
		"data/roster.json": {"units": [{"unit_id": "hero", "class_id": "fixture_class"}]},
		"data/class.json": {"id": "fixture_class", "display_name": "Fixture Class"},
	}
	for relative in files:
		_write_bytes(root.path_join(relative), _json_bytes(files[relative]))


func _tree_bytes(root: String, exclude_unadmitted: bool) -> Dictionary:
	var output := {}
	_collect_tree(root, root, output, exclude_unadmitted)
	return output


func _collect_tree(root: String, path: String, output: Dictionary,
		exclude_unadmitted: bool) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		var child := path.path_join(name)
		if directory.current_is_dir():
			if not exclude_unadmitted or name != ".godot":
				_collect_tree(root, child, output, exclude_unadmitted)
		else:
			var relative := child.trim_prefix(root + "/")
			if not exclude_unadmitted or relative.begins_with("data/") or relative == "manifest.json" \
					or relative.get_extension().to_lower() in Exporter.APPROVED_MEDIA_EXTENSIONS:
				output[relative] = _read_bytes(child)
		name = directory.get_next()
	directory.list_dir_end()


func _write_bytes(path: String, bytes: PackedByteArray) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)


func _read_bytes(path: String) -> PackedByteArray:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_buffer(file.get_length()) if file != null else PackedByteArray()


func _json_bytes(value: Variant) -> PackedByteArray:
	return JSON.stringify(value).to_utf8_buffer()
