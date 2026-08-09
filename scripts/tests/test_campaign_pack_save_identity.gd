extends SceneTree
# Package identity round-trips through both campaign and suspend documents and
# reactivates installed content before campaign ids are restored.

const Registry = preload("res://scripts/resources/CampaignPackRegistry.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const ROOT := "save-pack"
const TEST_SAVE_DIR := "user://test_campaign_pack_save_identity"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Campaign Pack Save Identity Test ===")
	var passed := 0
	var failed := 0
	var pack := Registry.installed_path(Registry.DEFAULT_STORAGE_ROOT, ROOT, "1.0")
	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
	Installer._remove_tree(TEST_SAVE_DIR)
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
	sm.call("configure_save_dir_for_tests", TEST_SAVE_DIR)
	dm.call("select_tier2_campaign_source", pack, ROOT, "1.0")
	var slot_written := bool(sm.call("save_slot", "package", save, "manual", ""))
	dm.call("select_campaign_source", "res://data")
	var loaded_slot: RefCounted = sm.call("load_slot", "package")
	if (
		slot_written
		and loaded_slot != null
		and String(dm.call("active_package_identity").get("package_id", "")).is_empty()
	):
		print("OK  ordinary load_slot validates saved package content and restores prior source")
		passed += 1
	else:
		print("FAIL ordinary package slot load path")
		failed += 1

	# A valid package identity commits its ContentSession before campaign ids can
	# be resolved. Force that later check to fail and prove the wider resume
	# transaction restores every live owner, not just the package label.
	cm.call("start_campaign", "proving_grounds")
	cm.call("set_campaign_flag", "prior_flag")
	cm.call("set_campaign_var", "prior_var", 7)
	gs.set("party_gold", 321)
	gs.set("party_items", ["vulnerary"] as Array[String])
	gs.set("mandated_campaign_rules", ["death_mode"] as Array[String])
	var prior_identity: Dictionary = dm.call("active_package_identity")
	var prior_campaigns: Array[String] = dm.call("get_campaign_ids")
	var prior_campaign: Dictionary = cm.call("capture_campaign_state")
	var prior_mutable: Dictionary = gs.call("capture_mutable_campaign_state")
	var prior_roster_ids: Array[String] = _roster_ids(gs.get("player_roster"))
	var registry_manager: Node = root.get_node_or_null("RegistryManager")
	var prior_registry_ids: Array[String] = registry_manager.call("ids", "objective_condition")
	var late_rejection: Dictionary = save.to_dict()
	late_rejection["campaign"]["campaign_id"] = "missing_after_package_activation"
	var rejected: bool = not gs.call("configure_campaign_resume", late_rejection)
	var rollback_ok: bool = (
		rejected
		and dm.call("active_package_identity") == prior_identity
		and dm.call("get_campaign_ids") == prior_campaigns
		and dm.call("get_class_data", "mercenary") != null
		and dm.call("get_class_data", "fixture_class") == null
		and registry_manager.call("ids", "objective_condition") == prior_registry_ids
		and cm.call("capture_campaign_state") == prior_campaign
		and gs.call("capture_mutable_campaign_state") == prior_mutable
		and int(gs.get("party_gold")) == 321
		and gs.get("party_items") == ["vulnerary"]
		and gs.get("mandated_campaign_rules") == ["death_mode"]
		and _roster_ids(gs.get("player_roster")) == prior_roster_ids
	)
	if rollback_ok:
		print("OK  late package-resume rejection restores the complete prior session")
		passed += 1
	else:
		print(
			(
				"FAIL late resume rollback: identity=%s campaigns=%s campaign=%s mutable=%s"
				% [
					dm.call("active_package_identity"),
					dm.call("get_campaign_ids"),
					cm.call("capture_campaign_state"),
					gs.call("capture_mutable_campaign_state"),
				]
			)
		)
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
	var missing_slot: RefCounted = sm.call("load_slot", "package")
	if (
		missing_slot == null
		and String(dm.call("active_package_identity").get("package_id", "")).is_empty()
	):
		print("OK  missing saved package fails closed and preserves the prior source")
		passed += 1
	else:
		print("FAIL missing package slot mutated active content")
		failed += 1
	Installer._remove_tree(TEST_SAVE_DIR)
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _roster_ids(roster: Array) -> Array[String]:
	var ids: Array[String] = []
	for unit in roster:
		ids.append(String(unit.unit_id))
	return ids


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
