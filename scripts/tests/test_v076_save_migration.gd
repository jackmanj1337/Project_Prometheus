extends SceneTree

const Migration = preload("res://scripts/save/SaveMigrationService.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const ROOT := "user://test_v076_save_migration"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== v0.7.6 Direct Save Migration Test ===")
	var passed := 0
	var failed := 0
	var source: SaveData = (
		(
			SaveData
			. from_dict(
				{
					"save_label": "Original",
					"campaign":
					{
						"package_id": "fixture-pack",
						"package_version": "1.0.0",
						"campaign_id": "old_campaign",
						"node_id": "old_node",
						"cleared_nodes": []
					},
					"roster":
					{
						"units":
						[
							{
								"unit_id": "hero",
								"class_id": "old_class",
								"skills": ["old_skill"],
								"inventory": []
							}
						]
					},
				}
			)
		)
		as SaveData
	)
	var declaration := _declaration()
	var manifest_errors: Array[String] = []
	var manifest := PackManifest.parse(
		{
			"id": "fixture-pack",
			"version": "2.0.0",
			"builder_content_version": "1.0",
			"format_version": 1,
			"save_migrations": [declaration]
		},
		"manifest.json",
		manifest_errors
	)
	if manifest != null and manifest.save_migrations.size() == 1:
		passed += 1
		print("OK  destination manifest admits one validated direct declaration")
	else:
		failed += 1
		print("FAIL manifest migration declaration: %s" % [manifest_errors])
	var existing := {
		"campaign:new_campaign": true,
		"campaign_node:new_node": true,
		"unit:hero": true,
		"class:new_class": true,
		"skill:new_skill": true,
	}
	var exists := func(family: String, id: String) -> bool:
		return existing.has("%s:%s" % [family, id])
	var preview := Migration.preview(source, "fixture-pack", declaration, exists)
	if (
		preview["ok"]
		and preview["save"].campaign["campaign_id"] == "new_campaign"
		and preview["save"].campaign["package_version"] == "2.0.0"
		and source.campaign["campaign_id"] == "old_campaign"
	):
		passed += 1
		print("OK  direct migration maps a deep copy and preserves the source")
	else:
		failed += 1
		print("FAIL direct migration: %s" % [preview])

	var ambiguous := _declaration()
	ambiguous["aliases"]["class"] = {"old_class": "same", "other": "same"}
	var ambiguity_errors := Migration.validate_declaration(ambiguous, "fixture-pack")
	var cross_errors := Migration.validate_declaration(declaration, "different-pack")
	if (
		ambiguity_errors.any(func(e): return "ambiguous" in e)
		and "cross_package_migration_unsupported" in cross_errors
	):
		passed += 1
		print("OK  ambiguous aliases and cross-package v1 moves are rejected")
	else:
		failed += 1
		print("FAIL declaration validation: %s / %s" % [ambiguity_errors, cross_errors])

	var missing := Migration.preview(
		source, "fixture-pack", declaration, func(_f, _i): return false
	)
	if not missing["ok"] and missing["errors"].any(func(e): return "destination_missing" in e):
		passed += 1
		print("OK  unmapped or removed destination references block migration")
	else:
		failed += 1
		print("FAIL missing destination: %s" % [missing])

	Installer._remove_tree(ROOT)
	var manager := root.get_node("SaveManager")
	manager.configure_save_dir_for_tests(ROOT)
	var saved: bool = manager.save_slot("source", source)
	manager._test_fail_before_index_replace = true
	var commit: Dictionary = manager.migrate_save_document_into_slot(
		source, "migrated", "fixture-pack", declaration, exists
	)
	manager._test_fail_before_index_replace = false
	if (
		saved
		and not commit["ok"]
		and manager.has_slot("source")
		and not manager.has_slot("migrated")
	):
		passed += 1
		print("OK  failed commit rolls back destination and preserves source bytes")
	else:
		failed += 1
		print("FAIL migration rollback: %s" % [commit])
	Installer._remove_tree(ROOT)
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed else 0)


func _declaration() -> Dictionary:
	return {
		"source_package_id": "fixture-pack",
		"source_package_version": "1.0.0",
		"destination_package_version": "2.0.0",
		"aliases":
		{
			"campaign": {"old_campaign": "new_campaign"},
			"campaign_node": {"old_node": "new_node"},
			"map": {},
			"unit": {},
			"item": {},
			"class": {"old_class": "new_class"},
			"skill": {"old_skill": "new_skill"},
		},
	}
