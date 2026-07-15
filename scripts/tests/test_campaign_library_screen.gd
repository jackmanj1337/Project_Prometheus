extends SceneTree
# Exercises the real UI callbacks behind both FileDialogs: export an installed
# pack, remove it, import the artifact, and verify discovery refreshes inertly.

const Registry = preload("res://scripts/resources/CampaignPackRegistry.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const ROOT := "library-pack"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Campaign Library Screen Test ===")
	var passed := 0
	var failed := 0
	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
	var save_manager := root.get_node_or_null("SaveManager")
	if save_manager == null:
		save_manager = load("res://scripts/autoloads/SaveManager.gd").new()
		save_manager.name = "SaveManager"
		root.add_child(save_manager)
	save_manager.configure_save_dir_for_tests("user://test_campaign_library_saves")
	DirAccess.make_dir_recursive_absolute("user://test_campaign_library_saves")
	var save_dir := DirAccess.open("user://test_campaign_library_saves")
	for file_name in save_dir.get_files():
		save_dir.remove(file_name)
	var source := Registry.installed_path(Registry.DEFAULT_STORAGE_ROOT, ROOT, "1.0")
	_write_pack(source)
	var screen: Control = load("res://scenes/ui/CampaignLibraryScreen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.open()
	var package_opt: OptionButton = screen.get_node("Panel/VBox/HBoxPackage/OptPackage")
	var export_button: Button = screen.get_node("Panel/VBox/BtnExport")
	if package_opt.item_count == 1 and ROOT in package_opt.get_item_text(0) \
			and not export_button.disabled:
		print("OK  installed packages populate the export picker"); passed += 1
	else:
		print("FAIL installed package picker"); failed += 1

	var archive := "user://campaign-library-test.zip"
	screen._on_export_file_selected(archive)
	if FileAccess.file_exists(archive) \
			and "Exported %s 1.0" % ROOT in screen.get_node("ResultDialog").dialog_text:
		print("OK  export FileDialog callback writes a validated archive"); passed += 1
	else:
		print("FAIL export callback"); failed += 1

	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
	var dm := root.get_node_or_null("DataManager")
	var identity_before: Dictionary = dm.call("active_package_identity") if dm else {}
	var signal_state := {"changed": 0}
	screen.campaigns_changed.connect(func(): signal_state["changed"] += 1)
	screen._on_import_file_selected(archive)
	var installed := Registry.new(Registry.DEFAULT_STORAGE_ROOT).refresh()
	var identity_after: Dictionary = dm.call("active_package_identity") if dm else {}
	var preferences: Array[Dictionary] = save_manager.campaign_preference_candidates()
	if installed.size() == 1 and signal_state["changed"] == 1 \
			and identity_after == identity_before and preferences.size() == 1 \
			and preferences[0]["campaign_id"] == "library_campaign":
		print("OK  import installs, signals discovery refresh, and remains inert"); passed += 1
	else:
		print("FAIL import callback installed=%d changed=%d inert=%s" % [
			installed.size(), signal_state["changed"], identity_after == identity_before]); failed += 1

	var bad := "user://campaign-library-bad.zip"
	var bad_file := FileAccess.open(bad, FileAccess.WRITE)
	bad_file.store_string("not a zip")
	bad_file.close()
	screen._on_import_file_selected(bad)
	if "Import failed" in screen.get_node("ResultDialog").dialog_text \
			and Registry.new(Registry.DEFAULT_STORAGE_ROOT).refresh().size() == 1:
		print("OK  invalid artifacts report failure without changing installed state"); passed += 1
	else:
		print("FAIL invalid import handling"); failed += 1

	screen.queue_free()
	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
	DirAccess.remove_absolute(archive)
	DirAccess.remove_absolute(bad)
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _write_pack(root_path: String) -> void:
	var files := {
		"manifest.json": {"id": ROOT, "version": "1.0", "forked_from": "",
			"builder_content_version": "0.4", "format_version": 1},
		"data/catalogue.json": {"format_version": 1, "entries": [
			{"kind": "campaign", "id": "library_campaign", "path": "data/campaign.json"},
			{"kind": "map_registry", "id": "maps", "path": "data/map_registry.json"},
			{"kind": "map_data", "id": "map_01", "path": "data/map.json"},
			{"kind": "roster", "id": "heroes", "path": "data/roster.json"},
			{"kind": "class", "id": "fighter", "path": "data/class.json"}]},
		"data/campaign.json": {"campaign_id": "library_campaign", "label": "Library",
			"start_node_id": "start", "nodes": [{"node_id": "start", "label": "Start",
				"map_id": "map_01", "next": []}]},
		"data/map_registry.json": [{"id": "map_01", "label": "Map",
			"map_data_id": "map_01", "roster_id": "heroes"}],
		"data/map.json": {"id": "map_01", "display_name": "Map", "grid": ["..."],
			"player_start_tiles": [[0, 0]]},
		"data/roster.json": {"units": [{"unit_id": "hero", "unit_name": "Hero",
			"class_id": "fighter"}]},
		"data/class.json": {"id": "fighter", "display_name": "Fighter",
			"base_hp": 20, "base_movement": 5},
	}
	for relative in files:
		var path := root_path.path_join(relative)
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(files[relative]))
