extends SceneTree
# Hostile archive metadata is rejected before extraction or installed-state I/O.

const Preflight = preload("res://scripts/resources/CampaignArchivePreflight.gd")
const ROOT := "fixture-pack"


func _init() -> void:
	print("=== Campaign Archive Preflight Test ===")
	var passed := 0
	var failed := 0
	var limits = Preflight.Limits.new(32, 200000, 200000, 500000, 500000)
	var payloads := _fixture_payloads()
	var entries := _entries_for(payloads)

	var valid = Preflight.inspect_entries(entries, payloads, limits)
	if valid.valid and valid.package_id == ROOT:
		print("OK  valid in-memory fixture preflights without extraction")
		passed += 1
	else:
		print("FAIL valid fixture: %s" % [valid.errors])
		failed += 1

	var zip_path := "user://test_campaign_archive_preflight/fixture.zip"
	_write_zip(zip_path, payloads)
	var zip_result = Preflight.inspect_zip(zip_path, limits)
	if zip_result.valid and zip_result.package_id == ROOT:
		print("OK  actual ZIP format and central directory preflight successfully")
		passed += 1
	else:
		print("FAIL actual ZIP: %s" % [zip_result.errors])
		failed += 1

	var outer_limit = Preflight.Limits.new(32, 200000, 200000, 8, 500000)
	var outer_result = Preflight.inspect_zip(zip_path, outer_limit)
	if not outer_result.valid and _has(outer_result.errors, "Archive file exceeds"):
		print("OK  outer archive budget is enforced before ZIP buffering")
		passed += 1
	else:
		print("FAIL outer archive budget: %s" % [outer_result.errors])
		failed += 1

	var unsafe := entries.duplicate(true)
	unsafe.append(_entry("%s/data/../../escape.json" % ROOT, 2))
	unsafe.append(_entry("C:/absolute.json", 2))
	unsafe.append(_entry("%s\\data\\ambiguous.json" % ROOT, 2))
	var unsafe_result = Preflight.inspect_entries(unsafe, payloads, limits)
	if not unsafe_result.valid and _has(unsafe_result.errors, "Unsafe archive path"):
		print("OK  traversal, absolute/drive, and backslash paths are rejected")
		passed += 1
	else:
		print("FAIL unsafe paths: %s" % [unsafe_result.errors])
		failed += 1

	var collisions := entries.duplicate(true)
	collisions.append(entries[0].duplicate(true))
	collisions.append(_entry("Fixture-Pack/MANIFEST.JSON", 2))
	var collision_result = Preflight.inspect_entries(collisions, payloads, limits)
	if (
		not collision_result.valid
		and _has(collision_result.errors, "Duplicate normalized")
		and _has(collision_result.errors, "Case-fold path collision")
	):
		print("OK  duplicate and case-fold collisions are rejected")
		passed += 1
	else:
		print("FAIL collisions: %s" % [collision_result.errors])
		failed += 1

	var hostile_types := entries.duplicate(true)
	hostile_types.append(_entry("%s/assets/link.png" % ROOT, 1, "symlink"))
	hostile_types.append(_entry("%s/assets/device.png" % ROOT, 1, "special file"))
	var types_result = Preflight.inspect_entries(hostile_types, payloads, limits)
	if (
		not types_result.valid
		and _has(types_result.errors, "forbidden symlink")
		and _has(types_result.errors, "forbidden special file")
	):
		print("OK  symlinks and special files are rejected from ZIP metadata")
		passed += 1
	else:
		print("FAIL hostile types: %s" % [types_result.errors])
		failed += 1

	var tiny_limits = Preflight.Limits.new(2, 4, 4, 8, 8)
	var size_result = Preflight.inspect_entries(entries, payloads, tiny_limits)
	if (
		not size_result.valid
		and _has(size_result.errors, "size limits")
		and _has(size_result.errors, "entries; limit")
	):
		print("OK  caller-owned entry and byte budgets are enforced")
		passed += 1
	else:
		print("FAIL size limits: %s" % [size_result.errors])
		failed += 1

	var save_payloads := payloads.duplicate(true)
	var save_path := "%s/data/save.json" % ROOT
	save_payloads[save_path] = _json_bytes(
		{
			"format_version": 1,
			"save_label": "slot",
			"map_runtime": {},
			"suspend": {},
		}
	)
	var catalogue: Dictionary = JSON.parse_string(
		save_payloads["%s/data/catalogue.json" % ROOT].get_string_from_utf8()
	)
	catalogue["entries"].append({"kind": "class", "id": "save", "path": "data/save.json"})
	save_payloads["%s/data/catalogue.json" % ROOT] = _json_bytes(catalogue)
	var save_result = Preflight.inspect_entries(_entries_for(save_payloads), save_payloads, limits)
	if not save_result.valid and _has(save_result.errors, "Save-shaped JSON"):
		print("OK  indexed save-shaped payloads are never accepted as pack content")
		passed += 1
	else:
		print("FAIL save-shaped payload: %s" % [save_result.errors])
		failed += 1

	var bad_payloads := payloads.duplicate(true)
	bad_payloads["%s/manifest.json" % ROOT] = _json_bytes(
		{
			"id": "different",
			"version": "1",
			"builder_content_version": "0.4",
			"format_version": 99,
		}
	)
	bad_payloads["%s/data/class.json" % ROOT] = PackedByteArray("{bad json".to_utf8_buffer())
	bad_payloads["%s/unlisted.txt" % ROOT] = PackedByteArray("no".to_utf8_buffer())
	var bad_result = Preflight.inspect_entries(_entries_for(bad_payloads), bad_payloads, limits)
	if (
		not bad_result.valid
		and _has(bad_result.errors, "unsupported format_version")
		and _has(bad_result.errors, "Invalid JSON")
		and _has(bad_result.errors, "Unindexed file")
	):
		print("OK  incompatible, malformed, and unindexed content fail together")
		passed += 1
	else:
		print("FAIL malformed package: %s" % [bad_result.errors])
		failed += 1

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _fixture_payloads() -> Dictionary:
	var root := ROOT + "/"
	return {
		root + "manifest.json":
		_json_bytes(
			{
				"id": ROOT,
				"version": "1.0",
				"forked_from": "",
				"builder_content_version": "0.4",
				"format_version": 1,
			}
		),
		root + "data/catalogue.json":
		_json_bytes(
			{
				"format_version": 1,
				"entries":
				[
					{"kind": "campaign", "id": "fixture", "path": "data/campaign.json"},
					{"kind": "map_registry", "id": "maps", "path": "data/map_registry.json"},
					{"kind": "map_data", "id": "map_01", "path": "data/map_01.json"},
					{"kind": "roster", "id": "heroes", "path": "data/roster.json"},
					{"kind": "class", "id": "fixture_class", "path": "data/class.json"},
				],
			}
		),
		root + "data/campaign.json":
		_json_bytes(
			{
				"campaign_id": "fixture",
				"label": "Fixture",
				"start_node_id": "start",
				"nodes": [{"node_id": "start", "label": "Start", "map_id": "map_01", "next": []}],
			}
		),
		root + "data/map_registry.json":
		_json_bytes(
			[
				{
					"id": "map_01",
					"label": "Map",
					"map_data_id": "map_01",
					"roster_id": "heroes",
				}
			]
		),
		root + "data/map_01.json":
		_json_bytes(
			{
				"id": "map_01",
				"display_name": "Map",
				"grid": ["..."],
				"player_start_tiles": [[0, 0]],
			}
		),
		root + "data/roster.json":
		_json_bytes(
			{
				"units": [{"unit_id": "hero", "class_id": "fixture_class"}],
			}
		),
		root + "data/class.json":
		_json_bytes(
			{
				"id": "fixture_class",
				"display_name": "Fixture Class",
			}
		),
		root + "assets/icon.png": PackedByteArray([0x89, 0x50, 0x4e, 0x47]),
	}


func _entries_for(payloads: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for path in payloads:
		out.append(_entry(path, payloads[path].size()))
	out.sort_custom(func(a, b): return a["path"] < b["path"])
	return out


func _entry(path: String, size: int, file_type := "file") -> Dictionary:
	return {
		"path": path,
		"compressed_size": size,
		"uncompressed_size": size,
		"file_type": file_type,
		"is_directory": file_type == "directory",
	}


func _write_zip(path: String, payloads: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var packer := ZIPPacker.new()
	packer.open(path)
	var paths: Array = payloads.keys()
	paths.sort()
	for entry_path in paths:
		packer.start_file(entry_path)
		packer.write_file(payloads[entry_path])
		packer.close_file()
	packer.close()


func _json_bytes(value: Variant) -> PackedByteArray:
	return JSON.stringify(value).to_utf8_buffer()


func _has(errors: Array[String], fragment: String) -> bool:
	return errors.any(func(error): return fragment in error)
