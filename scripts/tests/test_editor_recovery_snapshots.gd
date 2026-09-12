extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_editor_recovery_snapshots.gd
#
# Covers `[CEUI-S40]`'s one recovery primitive: periodic captures, pre-risk captures,
# bounded pruning, a retained explicit-save baseline, and the Asset Manager adopter.

const RecoveryScript = preload("res://scripts/editor/EditorRecoverySnapshots.gd")
const DocumentScript = preload("res://scripts/editor/EditorDocument.gd")
const ManagerScript = preload("res://scripts/editor/EditorAssetManager.gd")
const SchemasScript = preload("res://scripts/data/EntitySchemaRegistry.gd")

const ROOT := "user://test_editor_recovery_snapshots"
const STORE := ROOT + "/recovery.json"

var _passed := 0
var _failed := 0


func _init() -> void:
	_cleanup()
	_periodic_captures_wait_for_the_interval()
	_pre_risk_captures_are_named_and_pruned()
	_explicit_save_survives_recovery_discard_and_reload()
	the_asset_manager_captures_before_import_and_deletion()
	_cleanup()
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % label)
	else:
		_failed += 1
		print("  FAIL: %s%s" % [label, ("  [%s]" % detail) if detail != "" else ""])


func _periodic_captures_wait_for_the_interval() -> void:
	print("\n-- periodic captures wait for the configured interval --")
	var recovery := RecoveryScript.new(STORE, 3, 10.0)
	var first := recovery.capture_periodic("maps", {"value": 1}, 100.0)
	var early := recovery.capture_periodic("maps", {"value": 2}, 109.9)
	var second := recovery.capture_periodic("maps", {"value": 3}, 110.0)
	_check("the first dirty-document tick captures", bool(first["captured"]))
	_check("a tick before the interval does not capture", not bool(early["captured"]))
	_check("the interval boundary captures the next version", bool(second["captured"]))
	_check(
		"periodic entries are identified as periodic",
		recovery.recovery_snapshots("maps")[0]["kind"] == RecoveryScript.KIND_PERIODIC
	)


func _pre_risk_captures_are_named_and_pruned() -> void:
	print("\n-- pre-risk captures are named and pruned by count --")
	var recovery := RecoveryScript.new(STORE, 3, 10.0)
	var first := recovery.capture_before_risk("maps", {"value": 4}, "asset_import", 120.0)
	var second := recovery.capture_before_risk("maps", {"value": 5}, "asset_deletion:hero", 121.0)
	var third := recovery.capture_before_risk("maps", {"value": 6}, "rename_id", 122.0)
	var fourth := recovery.capture_before_risk("maps", {"value": 7}, "asset_bake", 123.0)
	_check("pre-risk capture succeeds", bool(first["captured"]) and bool(second["captured"]))
	_check(
		"the reason names the risky operation",
		String(second["snapshot"]["reason"]) == "asset_deletion:hero"
	)
	_check(
		"recovery entries are pruned to the configured count", recovery.recovery_count("maps") == 3
	)
	_check("the oldest entry is pruned first", recovery.restore("", "maps")["state"]["value"] == 7)
	_check("the newest capture remains after pruning", bool(fourth["captured"]))


func _explicit_save_survives_recovery_discard_and_reload() -> void:
	print("\n-- the last-good explicit save is separate from recovery --")
	var recovery := RecoveryScript.new(STORE, 3, 10.0)
	recovery.capture_before_risk("maps", {"value": 8}, "asset_import", 130.0)
	var saved := recovery.remember_last_good_save("maps", {"value": 0}, 131.0)
	_check("the explicit save is recorded", bool(saved["saved"]))
	_check(
		"discard removes recovery entries", bool(recovery.discard_recovery("", "maps")["discarded"])
	)
	_check(
		"discard does not remove the last-good save",
		recovery.last_good_save("maps")["state"]["value"] == 0
	)
	var reloaded := RecoveryScript.new(STORE, 3, 10.0)
	_check(
		"the last-good save survives a reload",
		reloaded.last_good_save("maps")["state"]["value"] == 0
	)
	_check(
		"discarded recovery entries stay gone after reload", reloaded.recovery_count("maps") == 0
	)


func the_asset_manager_captures_before_import_and_deletion() -> void:
	print("\n-- the Asset Manager is a real pre-risk adopter --")
	var document := (
		DocumentScript
		. open(
			"assets",
			"asset_registry",
			{
				"pack_assets":
				{
					"kind": "asset_registry",
					"schema_version": 1,
					"id": "pack_assets",
					"assets":
					{
						"hero_sheet":
						{
							"path": "assets/hero_sheet.png",
							"decoded_type": "image/png",
							"byte_size": 12,
							"sha256": "b".repeat(64),
							"original_filename": "hero_sheet.png",
						}
					},
				},
			},
			"Assets"
		)
	)
	var manager = ManagerScript.new()
	manager.call("set_registry", document, "pack_assets", SchemasScript.with_core_schemas())
	var recovery = RecoveryScript.new(STORE, 5, 10.0)
	manager.call("set_recovery_snapshots", recovery)
	(
		manager
		. call(
			"stage_import",
			{
				"id": "village_theme",
				"source_path": "user://hero_sheet.png",
				"original_filename": "village_theme.ogg",
				"byte_size": 12,
				"sha256": "a".repeat(64),
			}
		)
	)
	var imported: Dictionary = manager.call("commit_import", [document])
	_check("import still commits through the plan API", bool(imported["committed"]))
	_check("import captures one pre-risk state", recovery.recovery_count("assets") == 1)
	_check(
		"the import snapshot is labelled",
		String(recovery.recovery_snapshots("assets")[0]["reason"]) == "asset_import"
	)
	var before_delete: Dictionary = manager.call(
		"capture_before_deletion", "hero_sheet", [document]
	)
	_check("deletion exposes an immediate pre-risk capture", bool(before_delete["captured"]))
	_check(
		"deletion names the asset in its reason",
		String(before_delete["snapshot"]["reason"]) == "asset_deletion:hero_sheet"
	)
	var restored := recovery.restore("", "assets")
	var restored_state: Dictionary = restored["state"]
	(restored_state["documents"] as Array)[0]["tampered"] = true
	_check(
		"restored state is isolated from stored recovery",
		not recovery.restore("", "assets")["state"]["documents"][0].has("tampered")
	)


func _cleanup() -> void:
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(ROOT)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(STORE))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ROOT))
