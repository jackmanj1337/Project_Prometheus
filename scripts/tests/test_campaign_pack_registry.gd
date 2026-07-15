extends SceneTree
# Installed-pack discovery validates candidates and caches inert summaries.

const Registry = preload("res://scripts/resources/CampaignPackRegistry.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")


func _init() -> void:
	print("=== Campaign Pack Registry Test ===")
	var passed := 0
	var failed := 0
	var scratch := "user://test_campaign_pack_registry"
	Installer._remove_tree(scratch)
	_write_pack(scratch.path_join("installed/zeta/2.0"), "zeta", "2.0", "z_campaign", "Zed")
	_write_pack(scratch.path_join("installed/alpha/1.0"), "alpha", "1.0", "a_campaign", "Alpha")
	_write_pack(scratch.path_join("installed/wrong/1.0"), "different", "1.0", "bad", "Bad")
	_write_bytes(scratch.path_join("installed/broken/1.0/manifest.json"), "{".to_utf8_buffer())

	var registry := Registry.new(scratch)
	var summaries = registry.refresh()
	if summaries.size() == 2 \
			and summaries[0]["package_id"] == "alpha" \
			and summaries[1]["package_id"] == "zeta" \
			and summaries[0]["campaigns"] == [{"campaign_id": "a_campaign",
				"label": "Alpha", "rules": {}}]:
		print("OK  valid installed packs produce deterministic campaign summaries"); passed += 1
	else:
		print("FAIL discovery summaries: %s" % [summaries]); failed += 1

	if registry.errors().size() >= 2 \
			and registry.errors().any(func(error): return "path identity" in error) \
			and registry.errors().any(func(error): return "invalid manifest" in error):
		print("OK  malformed and path-mismatched candidates are excluded with diagnostics"); passed += 1
	else:
		print("FAIL discovery diagnostics: %s" % [registry.errors()]); failed += 1

	var found := registry.find("zeta", "2.0")
	found["campaigns"].clear()
	if registry.find("zeta", "2.0")["campaigns"].size() == 1 \
			and registry.find("missing", "1.0").is_empty():
		print("OK  summary reads are deep-copy cached and exact-identity keyed"); passed += 1
	else:
		print("FAIL summary cache isolation"); failed += 1

	Installer._remove_tree(scratch.path_join("installed/alpha"))
	var refreshed = registry.refresh()
	if refreshed.size() == 1 and refreshed[0]["package_id"] == "zeta":
		print("OK  refresh drops removed packs instead of retaining stale summaries"); passed += 1
	else:
		print("FAIL stale summary refresh: %s" % [refreshed]); failed += 1

	Installer._remove_tree(scratch)
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _write_pack(root: String, id: String, version: String,
		campaign_id: String, label: String) -> void:
	var files := {
		"manifest.json": {
			"id": id, "version": version, "forked_from": "",
			"builder_content_version": "0.4", "format_version": 1,
		},
		"data/catalogue.json": {
			"format_version": 1,
			"entries": [
				{"kind": "campaign", "id": campaign_id, "path": "data/campaign.json"},
				{"kind": "map_registry", "id": "maps", "path": "data/map_registry.json"},
				{"kind": "map_data", "id": "map_01", "path": "data/map_01.json"},
				{"kind": "roster", "id": "heroes", "path": "data/roster.json"},
				{"kind": "class", "id": "fixture_class", "path": "data/class.json"},
			],
		},
		"data/campaign.json": {
			"campaign_id": campaign_id, "label": label, "start_node_id": "start",
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
		"data/class.json": {"id": "fixture_class", "display_name": "Fixture"},
	}
	for relative in files:
		_write_bytes(root.path_join(relative), JSON.stringify(files[relative]).to_utf8_buffer())


func _write_bytes(path: String, bytes: PackedByteArray) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)
