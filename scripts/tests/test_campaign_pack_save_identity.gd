extends SceneTree
# Package identity round-trips through both campaign and suspend documents and
# reactivates installed content before campaign ids are restored.

const Registry = preload("res://scripts/resources/CampaignPackRegistry.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const ROOT := "save-pack"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Campaign Pack Save Identity Test ===")
	var passed := 0
	var failed := 0
	var pack := Registry.installed_path(Registry.DEFAULT_STORAGE_ROOT, ROOT, "1.0")
	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
	_write_pack(pack)
	var dm: Node = root.get_node_or_null("DataManager")
	var gs: Node = root.get_node_or_null("GameState")
	var cm: Node = root.get_node_or_null("CampaignManager")
	if dm == null or gs == null or cm == null:
		print("FAIL required autoloads unavailable")
		quit(1)
		return

	var selected := bool(dm.call("select_tier2_campaign_source", pack, ROOT, "1.0"))
	var roster: Array = dm.call("get_campaign_pack_roster", "heroes")
	gs.call("load_roster_resources", roster, "campaign_pack_roster", "heroes")
	cm.call("start_campaign", "fixture")
	var save: RefCounted = gs.call("capture_campaign_save", "Pack save")
	if (
		selected
		and save.campaign["package_id"] == ROOT
		and save.campaign["package_version"] == "1.0"
	):
		print("OK  between-map campaign save captures exact package identity")
		passed += 1
	else:
		print("FAIL campaign package capture: %s" % [save.campaign if save else null])
		failed += 1

	dm.call("select_campaign_source", "res://data")
	cm.call("end_campaign")
	var sm: Node = root.get_node_or_null("SaveManager")
	var validation_errors: Array[String] = sm.call("_validate_for_saved_content", save)
	if (
		validation_errors.is_empty()
		and String(dm.call("active_package_identity").get("package_id", "")).is_empty()
	):
		print("OK  package save validates against its catalogue and restores prior content")
		passed += 1
	else:
		print("FAIL package-aware validation ordering: %s" % [validation_errors])
		failed += 1
	if (
		gs.call("configure_campaign_resume", save)
		and dm.call("active_package_identity")["package_id"] == ROOT
		and cm.get("active_campaign_id") == "fixture"
	):
		print("OK  campaign load activates installed package before restoring ids")
		passed += 1
	else:
		print("FAIL package-aware campaign restore")
		failed += 1

	var suspend: RefCounted = gs.call("capture_suspend_save", null, null)
	if suspend.campaign["package_id"] == ROOT and suspend.campaign["package_version"] == "1.0":
		print("OK  mid-map document carries the same package identity")
		passed += 1
	else:
		print("FAIL suspend package capture: %s" % [suspend.campaign])
		failed += 1

	var malformed: Dictionary = save.to_dict()
	malformed["campaign"]["package_version"] = ""
	if not gs.call("configure_campaign_resume", malformed):
		print("OK  incomplete package identity is rejected")
		passed += 1
	else:
		print("FAIL incomplete package identity accepted")
		failed += 1

	dm.call("select_campaign_source", "res://data")
	cm.call("end_campaign")
	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _write_pack(root: String) -> void:
	var files := {
		"manifest.json":
		{
			"id": ROOT,
			"version": "1.0",
			"forked_from": "",
			"builder_content_version": "0.4",
			"format_version": 1
		},
		"data/catalogue.json":
		{
			"format_version": 1,
			"entries":
			[
				{"kind": "campaign", "id": "fixture", "path": "data/campaign.json"},
				{"kind": "map_registry", "id": "maps", "path": "data/map_registry.json"},
				{"kind": "map_data", "id": "map_01", "path": "data/map_01.json"},
				{"kind": "roster", "id": "heroes", "path": "data/roster.json"},
				{"kind": "class", "id": "fixture_class", "path": "data/class.json"},
				{"kind": "weapon", "id": "fixture_blade", "path": "data/weapon.json"}
			]
		},
		"data/campaign.json":
		{
			"campaign_id": "fixture",
			"label": "Fixture",
			"start_node_id": "start",
			"nodes": [{"node_id": "start", "label": "Start", "map_id": "map_01", "next": []}]
		},
		"data/map_registry.json":
		[{"id": "map_01", "label": "Map", "map_data_id": "map_01", "roster_id": "heroes"}],
		"data/map_01.json":
		{"id": "map_01", "display_name": "Map", "grid": ["..."], "player_start_tiles": [[0, 0]]},
		"data/roster.json":
		{
			"units":
			[
				{
					"unit_id": "hero",
					"unit_name": "Hero",
					"class_id": "fixture_class",
					"inventory": [{"weapon_id": "fixture_blade", "uses": -1}]
				}
			]
		},
		"data/class.json":
		{
			"id": "fixture_class",
			"display_name": "Fixture",
			"base_hp": 20,
			"base_movement": 5,
			"allowed_weapon_families": ["sword"],
			"weapon_wexp_bases": {"sword": 1},
			"weapon_wexp_caps": {"sword": 400}
		},
		"data/weapon.json":
		{
			"id": "fixture_blade",
			"display_name": "Fixture Blade",
			"combat_family": "sword",
			"wexp_track": "sword",
			"required_rank": "E",
			"mt": 1,
			"hit": 100,
			"crit": 0,
			"wt": 0,
			"range_min_formula": "1",
			"range_max_formula": "1",
			"uses": -1,
			"cost": 0,
			"wexp": 1
		},
	}
	for relative in files:
		var path := root.path_join(relative)
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(files[relative]))
