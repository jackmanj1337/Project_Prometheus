extends SceneTree
# New Game enumerates only validated installed packs and activates the exact
# selected source before CampaignManager starts its campaign.

const Registry = preload("res://scripts/resources/CampaignPackRegistry.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const ROOT := "selector-pack"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== New Game Campaign Pack Selection Test ===")
	var passed := 0
	var failed := 0
	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
	var pack := Registry.installed_path(Registry.DEFAULT_STORAGE_ROOT, ROOT, "1.0")
	_write_pack(pack)
	var packed := load("res://scenes/ui/NewGameScreen.tscn")
	var screen: Control = packed.instantiate()
	root.add_child(screen)
	await process_frame
	var run_opt: OptionButton = screen.get_node("Panel/VBox/HBoxRun/OptRun")
	var installed_index := -1
	for index in screen._run_options.size():
		if screen._run_options[index].get("package_id", "") == ROOT \
				and screen._run_options[index].get("campaign_id", "") == "selector_campaign":
			installed_index = index
			break
	if installed_index >= 0 and "Selector Campaign" in run_opt.get_item_text(installed_index) \
			and ROOT in run_opt.get_item_text(installed_index):
		print("OK  New Game appends validated installed campaigns with pack identity"); passed += 1
	else:
		print("FAIL installed selector rows: count=%d" % run_opt.item_count); failed += 1

	var dm: Node = root.get_node("DataManager")
	var run: Dictionary = screen._run_options[installed_index]
	if screen._activate_run_source(run) \
			and dm.call("active_package_identity")["package_id"] == ROOT \
			and dm.call("has_campaign", "selector_campaign"):
		print("OK  selected row activates the exact Tier-2 source before start"); passed += 1
	else:
		print("FAIL installed source activation"); failed += 1
	var cm: Node = root.get_node("CampaignManager")
	var gs: Node = root.get_node("GameState")
	cm.call("start_campaign", "selector_campaign")
	var params: Dictionary = cm.call("resolve_launch_params", cm.call("get_current_node"))
	gs.call("configure_next_map", params["map_data_path"], params["roster_policy"],
		params["roster_source"])
	if params["roster_policy"] == "campaign_pack_roster" \
			and cm.call("_apply_roster_policy", gs, params["roster_policy"], params["roster_source"]) \
			and gs.call("is_roster_ready_for_launch"):
		print("OK  selected campaign resolves its package map and playable roster"); passed += 1
	else:
		print("FAIL package campaign launch resources"); failed += 1
	cm.call("end_campaign")

	var shipped_run: Dictionary = screen._run_options.filter(func(entry: Dictionary) -> bool:
		return entry.get("campaign_id", "") == "proving_grounds")[0]
	if screen._activate_run_source(shipped_run) \
			and dm.call("active_package_identity")["package_id"] == "" \
			and dm.call("has_campaign", "proving_grounds"):
		print("OK  selecting a shipped run restores the shipped content source"); passed += 1
	else:
		print("FAIL shipped source restoration"); failed += 1

	screen.queue_free()
	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _write_pack(root_path: String) -> void:
	var files := {
		"manifest.json": {"id": ROOT, "version": "1.0", "forked_from": "",
			"builder_content_version": "0.4", "format_version": 1},
		"data/catalogue.json": {"format_version": 1, "entries": [
			{"kind": "campaign", "id": "selector_campaign", "path": "data/campaign.json"},
			{"kind": "map_registry", "id": "maps", "path": "data/map_registry.json"},
			{"kind": "map_data", "id": "map_01", "path": "data/map_01.json"},
			{"kind": "roster", "id": "heroes", "path": "data/roster.json"},
			{"kind": "class", "id": "fixture_class", "path": "data/class.json"}]},
		"data/campaign.json": {"campaign_id": "selector_campaign",
			"label": "Selector Campaign", "start_node_id": "start", "nodes": [
				{"node_id": "start", "label": "Start", "map_id": "map_01", "next": []}]},
		"data/map_registry.json": [{"id": "map_01", "label": "Map",
			"map_data_id": "map_01", "roster_id": "heroes"}],
		"data/map_01.json": {"id": "map_01", "display_name": "Map",
			"grid": ["..."], "player_start_tiles": [[0, 0]]},
		"data/roster.json": {"units": [{"unit_id": "hero", "unit_name": "Hero",
			"class_id": "fixture_class"}]},
		"data/class.json": {"id": "fixture_class", "display_name": "Fixture",
			"base_hp": 20, "base_movement": 5},
	}
	for relative in files:
		var path := root_path.path_join(relative)
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(files[relative]))
