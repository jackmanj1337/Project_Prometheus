extends SceneTree
# Quit-to-shell returns content to the boot baseline.
#
# [CSA-28](f) ruled that quit-to-shell deactivates the campaign package. Nothing
# implemented it: deactivate_campaign_package() had no production caller and MainMenu
# reads only the installed-pack registry, so the menu was reached with the last-played
# pack still loaded. Nothing depended on that until [CEUI-S13] made the campaign editor
# main-menu-only -- the editor activates its own working copy, and doing so over a live
# player pack is the provenance failure [CEUI-S9] call 1 exists to prevent.
#
# AUTOLOAD NAME RACE -- read this before adding a stand-in here. Autoloads ARE
# instantiated under `godot --script`, so root already holds a real GameState,
# DataManager and CampaignManager. Adding a stand-in named "GameState" does not shadow
# the autoload: Godot renames the newcomer (observed: "@Node@3"), and every
# "/root/GameState" lookup inside production code still resolves to the autoload. A
# suite built that way asserts against objects nothing under test ever touches, and it
# goes green while testing nothing. This suite therefore drives the REAL autoloads
# throughout. A detached manager was tried and rejected: it is outside the tree, so
# activate_project_data_compatibility() cannot resolve RegistryManager and fails with
# "RegistryManager is unavailable" -- which would have made the bridge test pass for
# the wrong reason.
#
# The scene change inside quit_to_shell() is deferred to the end of the frame, so the
# assertions below run before it lands.

const DataManagerScript = preload("res://scripts/autoloads/DataManager.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Quit To Shell Deactivates Test ===")
	var setting := DataManagerScript.COMPATIBILITY_SETTING
	var previous: Variant = ProjectSettings.get_setting(setting, false)

	await process_frame
	_test_baseline_clears_active_package(setting)
	_test_baseline_restores_the_editor_bridge(setting)
	_test_quit_to_shell_deactivates_the_live_autoload(setting)

	ProjectSettings.set_setting(setting, previous)
	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _check(condition: bool, label: String, detail: String = "") -> void:
	if condition:
		print("OK  %s" % label)
		_passed += 1
	else:
		print("FAIL %s%s" % [label, "" if detail.is_empty() else " -- " + detail])
		_failed += 1


# The live autoload is used throughout: activate_project_data_compatibility() resolves
# RegistryManager through the tree, so a detached manager fails it with "RegistryManager
# is unavailable" and would make the bridge test pass for the wrong reason.
func _live_manager_with_active_pack() -> Node:
	var manager := root.get_node_or_null("/root/DataManager")
	if manager == null:
		return null
	manager._active_package_id = "coastal-trail"
	manager._active_package_version = "1.2.0"
	manager._active_package_path = "user://campaign_packs/coastal-trail/1.2.0"
	return manager


# What "a pack is active" means: an installed pack is identified by id AND version.
# Path alone does not name one -- with the editor bridge on, path is "res://data",
# which is the project tree rather than an installed pack. [ICO] identity is the id.
func _names_a_pack(manager: Node) -> bool:
	var identity: Dictionary = manager.active_package_identity()
	return (
		not String(identity.get("package_id", "")).is_empty()
		or not String(identity.get("package_version", "")).is_empty()
	)


func _identity_is_wholly_empty(manager: Node) -> bool:
	var identity: Dictionary = manager.active_package_identity()
	return not _names_a_pack(manager) and String(identity.get("path", "")).is_empty()


func _test_baseline_clears_active_package(setting: String) -> void:
	ProjectSettings.set_setting(setting, false)
	var manager := _live_manager_with_active_pack()
	if manager == null:
		_check(false, "the DataManager autoload is present")
		return
	manager.reset_to_boot_content_baseline()
	_check(
		_identity_is_wholly_empty(manager),
		"the boot baseline clears the active package identity outright",
		str(manager.active_package_identity())
	)
	_check(
		not manager.has_playable_content(),
		"no playable content survives the reset when compatibility is off"
	)


func _test_baseline_restores_the_editor_bridge(setting: String) -> void:
	# The bridge is activated at DataManager._ready, before any scene exists. A reset
	# that only cleared would leave an in-editor dev session with no content after the
	# first return to the menu, and it would not come back until relaunch.
	ProjectSettings.set_setting(setting, true)
	var manager := _live_manager_with_active_pack()
	if manager == null:
		_check(false, "the DataManager autoload is present")
		return
	manager.reset_to_boot_content_baseline()
	_check(
		manager.has_playable_content(),
		"the boot baseline restores the editor project-data bridge",
		str(manager.content_status())
	)
	# The bridge loads from the project tree, so it sets path to "res://data" while
	# leaving id and version empty. That is content being available, not a pack being
	# active, and it is the distinction [CEUI-S13] depends on.
	_check(
		not _names_a_pack(manager),
		"restoring the bridge does not restore a campaign package identity",
		str(manager.active_package_identity())
	)
	_check(
		String(manager.active_package_identity().get("path", "")) == "res://data",
		"the bridge reports the project tree as its source, not an installed pack",
		str(manager.active_package_identity())
	)


# The wiring test, against the live autoloads production code actually resolves.
func _test_quit_to_shell_deactivates_the_live_autoload(setting: String) -> void:
	# Compatibility off, so the assertion is the exported-player case: nothing active.
	ProjectSettings.set_setting(setting, false)
	var cm := root.get_node_or_null("/root/CampaignManager")
	var dm := root.get_node_or_null("/root/DataManager")
	_check(
		cm != null and dm != null and cm.has_method("quit_to_shell"),
		"the CampaignManager autoload exposes quit_to_shell"
	)
	if cm == null or dm == null or not cm.has_method("quit_to_shell"):
		return

	dm._active_package_id = "coastal-trail"
	dm._active_package_version = "1.2.0"
	dm._active_package_path = "user://campaign_packs/coastal-trail/1.2.0"
	_check(_names_a_pack(dm), "precondition: the live DataManager reports an active package")

	cm.quit_to_shell()

	_check(
		_identity_is_wholly_empty(dm),
		"quit_to_shell deactivates the package on the live DataManager",
		str(dm.active_package_identity())
	)
