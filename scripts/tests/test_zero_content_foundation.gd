extends SceneTree
# Zero-content foundation: inactive boot, transactional compatibility loading,
# atomic Tier-2 activation, and a reversible empty state.

const DataManagerScript = preload("res://scripts/autoloads/DataManager.gd")
const RegistryManagerScript = preload("res://scripts/autoloads/RegistryManager.gd")


func _init() -> void:
	print("=== Zero Content Foundation Test ===")
	var passed := 0
	var failed := 0
	var setting := DataManagerScript.COMPATIBILITY_SETTING
	var previous: Variant = ProjectSettings.get_setting(setting, false)
	ProjectSettings.set_setting(setting, false)

	var registry := RegistryManagerScript.new()
	registry.name = "RegistryManager"
	root.add_child(registry)
	var manager := DataManagerScript.new()
	manager.name = "DataManager"
	root.add_child(manager)
	await process_frame

	if (
		manager.content_state() == DataManagerScript.ContentState.INACTIVE
		and not manager.has_playable_content()
		and manager.get_campaign_ids().is_empty()
		and registry.ids("objective_conditions").is_empty()
		and registry.load_errors().is_empty()
	):
		print("OK  headless boot has valid empty data and registry catalogues")
		passed += 1
	else:
		print("FAIL inactive boot: %s / %s" % [manager.content_status(), registry.load_errors()])
		failed += 1

	if manager.activate_project_data_compatibility() and manager.has_playable_content():
		print("OK  explicit compatibility activation restores project content")
		passed += 1
	else:
		print("FAIL compatibility activation: %s" % [manager.content_status()])
		failed += 1

	var detached_manager := DataManagerScript.new()
	if not detached_manager.select_saved_campaign_source("", ""):
		print("OK  failed shipped-content activation propagates to save restoration")
		passed += 1
	else:
		print("FAIL save restoration accepted a failed shipped-content activation")
		failed += 1
	detached_manager.free()

	var identity_before: Dictionary = manager.active_package_identity()
	var campaigns_before: Array[String] = manager.get_campaign_ids()
	if (
		not manager.activate_project_data_compatibility("user://missing-zero-content-source")
		and manager.active_package_identity() == identity_before
		and manager.get_campaign_ids() == campaigns_before
		and manager.has_playable_content()
	):
		print("OK  invalid compatibility candidate cannot partially replace live content")
		passed += 1
	else:
		print("FAIL compatibility rollback: %s" % [manager.content_status()])
		failed += 1

	manager.deactivate_campaign_package()
	if (
		manager.content_state() == DataManagerScript.ContentState.INACTIVE
		and manager.get_campaign_ids().is_empty()
		and registry.ids("objective_conditions").is_empty()
	):
		print("OK  deactivation returns both managers to the empty state")
		passed += 1
	else:
		print("FAIL deactivation: %s" % [manager.content_status()])
		failed += 1

	ProjectSettings.set_setting(setting, previous)
	manager.queue_free()
	registry.queue_free()
	await process_frame
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)
