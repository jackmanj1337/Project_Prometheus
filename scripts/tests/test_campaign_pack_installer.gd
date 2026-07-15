extends SceneTree
# Transactional install tests use a real ZIP and isolated user:// storage.

const Preflight = preload("res://scripts/resources/CampaignArchivePreflight.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const ROOT := "fixture-pack"


func _init() -> void:
	print("=== Campaign Pack Installer Test ===")
	var passed := 0
	var failed := 0
	var scratch := "user://test_campaign_pack_installer"
	Installer._remove_tree(scratch)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(scratch))
	var archive := scratch.path_join("fixture.zip")
	var payloads := _fixture_payloads()
	_write_zip(archive, payloads)
	var preflight = Preflight.inspect_zip(archive, _limits())

	var storage := scratch.path_join("store")
	var result = Installer.new(storage).install_zip(archive, preflight)
	var expected := storage.path_join("installed/%s/1.0" % ROOT)
	if result.installed and result.installed_path == expected \
			and _tree_bytes(expected) == _relative_payloads(payloads) \
			and not result.repair_report.is_empty():
		print("OK  valid fixture installs once by validated identity with optional-media repair report"); passed += 1
	else:
		print("FAIL valid install: errors=%s repairs=%s" % [result.errors, result.repair_report]); failed += 1

	var before := _tree_bytes(expected)
	var duplicate = Installer.new(storage).install_zip(archive, preflight)
	if not duplicate.installed and _has(duplicate.errors, "already installed") \
			and _tree_bytes(expected) == before:
		print("OK  existing version rejection preserves every installed byte"); passed += 1
	else:
		print("FAIL duplicate preservation: %s" % [duplicate.errors]); failed += 1

	var invalid_store := scratch.path_join("invalid_store")
	var bad_payloads := payloads.duplicate(true)
	bad_payloads[ROOT + "/data/class.json"] = _json_bytes({
		"id": "wrong", "display_name": "Broken",
	})
	_write_zip(archive, bad_payloads)
	var invalid = Installer.new(invalid_store).install_zip(archive, preflight)
	if not invalid.installed and not DirAccess.dir_exists_absolute(invalid_store.path_join("installed")) \
			and not DirAccess.dir_exists_absolute(invalid_store.path_join(".staging")):
		print("OK  changed/invalid second-pass tree leaves no installed or staging directory"); passed += 1
	else:
		print("FAIL invalid second pass: %s" % [invalid.errors]); failed += 1

	_write_zip(archive, payloads)
	for stage in ["extraction", "validation", "promotion"]:
		var stage_store := scratch.path_join("failure_" + stage)
		var fault := func(candidate: String) -> bool: return candidate == stage
		var failed_result = Installer.new(stage_store, fault).install_zip(archive, preflight)
		if not failed_result.installed \
				and not DirAccess.dir_exists_absolute(stage_store.path_join("installed")) \
				and not DirAccess.dir_exists_absolute(stage_store.path_join(".staging")):
			print("OK  simulated %s failure cleans all transaction directories" % stage); passed += 1
		else:
			print("FAIL %s cleanup: %s" % [stage, failed_result.errors]); failed += 1

	var invalid_preflight = Preflight.Result.new()
	var rejected_store := scratch.path_join("rejected_store")
	var rejected = Installer.new(rejected_store).install_zip(archive, invalid_preflight)
	if not rejected.installed and not DirAccess.dir_exists_absolute(rejected_store):
		print("OK  invalid archive result cannot create installed state"); passed += 1
	else:
		print("FAIL invalid preflight created state: %s" % [rejected.errors]); failed += 1

	var unsafe_payloads := payloads.duplicate(true)
	unsafe_payloads[ROOT + "/manifest.json"] = _json_bytes({
		"id": ROOT, "version": "../escape", "forked_from": "",
		"builder_content_version": "0.4", "format_version": 1,
	})
	_write_zip(archive, unsafe_payloads)
	var unsafe_preflight = Preflight.inspect_zip(archive, _limits())
	var unsafe_store := scratch.path_join("unsafe_store")
	var outside := scratch.path_join("escape")
	var unsafe = Installer.new(unsafe_store).install_zip(archive, unsafe_preflight)
	if not unsafe.installed and not DirAccess.dir_exists_absolute(outside) \
			and not DirAccess.dir_exists_absolute(unsafe_store.path_join("installed")):
		print("OK  manifest identity cannot escape service-owned final roots"); passed += 1
	else:
		print("FAIL unsafe identity containment: %s" % [unsafe.errors]); failed += 1

	Installer._remove_tree(scratch)
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _limits():
	return Preflight.Limits.new(32, 200000, 200000, 500000, 500000)


func _fixture_payloads() -> Dictionary:
	var root := ROOT + "/"
	return {
		root + "manifest.json": _json_bytes({
			"id": ROOT, "version": "1.0", "forked_from": "",
			"builder_content_version": "0.4", "format_version": 1,
		}),
		root + "data/catalogue.json": _json_bytes({
			"format_version": 1,
			"entries": [
				{"kind": "campaign", "id": "fixture", "path": "data/campaign.json"},
				{"kind": "map_registry", "id": "maps", "path": "data/map_registry.json"},
				{"kind": "map_data", "id": "map_01", "path": "data/map_01.json"},
				{"kind": "roster", "id": "heroes", "path": "data/roster.json"},
				{"kind": "class", "id": "fixture_class", "path": "data/class.json"},
			],
		}),
		root + "data/campaign.json": _json_bytes({
			"campaign_id": "fixture", "label": "Fixture", "start_node_id": "start",
			"nodes": [{"node_id": "start", "label": "Start", "map_id": "map_01", "next": []}],
		}),
		root + "data/map_registry.json": _json_bytes([{
			"id": "map_01", "label": "Map", "map_data_id": "map_01", "roster_id": "heroes",
		}]),
		root + "data/map_01.json": _json_bytes({
			"id": "map_01", "display_name": "Map", "grid": ["..."],
			"player_start_tiles": [[0, 0]],
		}),
		root + "data/roster.json": _json_bytes({
			"units": [{"unit_id": "hero", "class_id": "fixture_class"}],
		}),
		root + "data/class.json": _json_bytes({
			"id": "fixture_class", "display_name": "Fixture Class",
		}),
		# Intentionally incomplete PNG: Tier-1 media is optional and reports repair.
		root + "assets/icon.png": PackedByteArray([0x89, 0x50, 0x4e, 0x47]),
	}


func _write_zip(path: String, payloads: Dictionary) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var packer := ZIPPacker.new()
	packer.open(path)
	var paths: Array = payloads.keys()
	paths.sort()
	for entry_path in paths:
		packer.start_file(entry_path)
		packer.write_file(payloads[entry_path])
		packer.close_file()
	packer.close()


func _relative_payloads(payloads: Dictionary) -> Dictionary:
	var relative := {}
	var prefix := ROOT + "/"
	for path in payloads:
		relative[String(path).trim_prefix(prefix)] = payloads[path]
	return relative


func _tree_bytes(root: String) -> Dictionary:
	var output := {}
	_collect_tree(root, root, output)
	return output


func _collect_tree(root: String, path: String, output: Dictionary) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		var child := path.path_join(name)
		if directory.current_is_dir():
			_collect_tree(root, child, output)
		else:
			var file := FileAccess.open(child, FileAccess.READ)
			output[child.trim_prefix(root + "/")] = file.get_buffer(file.get_length())
		name = directory.get_next()
	directory.list_dir_end()


func _json_bytes(value: Variant) -> PackedByteArray:
	return JSON.stringify(value).to_utf8_buffer()


func _has(errors: Array[String], fragment: String) -> bool:
	return errors.any(func(error): return fragment in error)
