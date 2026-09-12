extends SceneTree

# The save/pack diagnostics contract is intentionally tested at the real service
# boundary: a refusal names its stable reason, and a save record carries both
# identity blocks plus the catalogue that was active when the check ran.

const SaveDataScript = preload("res://scripts/save/SaveData.gd")
const Recovery = preload("res://scripts/save/SaveRecovery.gd")

var passed := 0
var failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var diagnostics := root.get_node_or_null("DiagnosticsLog")
	var save_manager := root.get_node_or_null("SaveManager")
	var data_manager := root.get_node_or_null("DataManager")
	if diagnostics == null or save_manager == null or data_manager == null:
		print("FAIL save/pack diagnostic autoloads are unavailable")
		quit(1)
		return
	diagnostics.print_records = false
	diagnostics.reset()

	# This is an actual public save gate and must produce an expected refusal rather
	# than a silent return or a push_error storm.
	var refused := bool(save_manager.call("save_slot", "invalid_source", null))
	var save_record := _last_record(diagnostics, "save", "save_slot")
	_check(not refused and not save_record.is_empty(), "invalid save source is recorded")
	_check(
		String(save_record.get("fields", "")).contains("reason_code=invalid_source"),
		"save refusal carries a stable reason code",
		str(save_record)
	)

	# Exercise the pack lifecycle subscriber through a real content-state transition.
	data_manager.call("deactivate_campaign_package")
	var pack_record := _last_record(diagnostics, "pack", "deactivate")
	_check(
		not pack_record.is_empty() and "outcome=completed" in String(pack_record.get("fields", "")),
		"pack deactivation is recorded",
		str(pack_record)
	)
	var compatibility_setting := "prometheus/content/activate_project_data_compatibility"
	var compatibility_before := bool(ProjectSettings.get_setting(compatibility_setting, true))
	ProjectSettings.set_setting(compatibility_setting, false)
	var missing_identity := bool(data_manager.call("select_saved_campaign_source", "", ""))
	ProjectSettings.set_setting(compatibility_setting, compatibility_before)
	var missing_identity_record := _last_record(diagnostics, "pack", "validate")
	var missing_identity_fields := String(missing_identity_record.get("fields", ""))
	_check(
		(
			not missing_identity
			and "reason_code=saved_campaign_identity_missing" in missing_identity_fields
			and "DataManager:" not in missing_identity_fields
		),
		"missing saved campaign identity uses a stable diagnostic code",
		missing_identity_fields
	)

	# The identity blocks are the evidence that resolved V0716-02 and V0716-03:
	# they remain adjacent even when the current catalogue is unrelated.
	var save := SaveDataScript.new()
	save.source = {
		"package_id": "fixture-pack",
		"package_version": "2.0.0",
		"content_schema_version": 7,
		"content_fingerprint": "sha256:" + "a".repeat(64),
		"campaign_id": "campaign",
	}
	save.campaign = {
		"package_id": "fixture-pack", "package_version": "2.0.0", "campaign_id": "campaign"
	}
	save_manager.call(
		"_record_save_operation", "load", {"slot": "identity_probe", "outcome": "completed"}, save
	)
	var identity_record := _last_record(diagnostics, "save", "load")
	var fields := String(identity_record.get("fields", ""))
	_check(
		(
			fields.contains("campaign={")
			and fields.contains("source={")
			and fields.contains("fixture-pack")
			and fields.contains("sha256:")
		),
		"save records carry campaign and source identity blocks",
		fields
	)

	var message := Recovery.message(
		Recovery.describe(
			Recovery.REASON_MISSING_CONTENT,
			{"package_id": "fixture-pack", "package_version": "2.0.0"},
			[],
			["map:missing_boss"]
		)
	)
	_check(
		(
			"Unresolved content: map:missing_boss." in message
			and "migration_" not in message
			and "campaign-pack://" not in message
		),
		"recovery wording names missing content without leaking engine codes",
		message
	)

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed else 0)


func _last_record(diagnostics: Node, category: String, event: String) -> Dictionary:
	for index in range(diagnostics.records.size() - 1, -1, -1):
		var entry: Dictionary = diagnostics.records[index]
		if (
			String(entry.get("category", "")) == category
			and String(entry.get("event", "")) == event
		):
			return entry
	return {}


func _check(ok: bool, label: String, detail: String = "") -> void:
	if ok:
		passed += 1
		print("OK  %s" % label)
	else:
		failed += 1
		print("FAIL %s %s" % [label, detail])
