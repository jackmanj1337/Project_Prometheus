extends SceneTree
# Portable status export/scan/import over the shared mutable campaign store.

const StoreScript = preload("res://scripts/resources/CampaignStatusStore.gd")
const StateScript = preload("res://scripts/resources/MutableCampaignState.gd")
const CampaignManagerScript = preload("res://scripts/autoloads/CampaignManager.gd")
const TEST_ROOT := "user://test_campaign_status_records"

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Campaign Status Record Test ===")
	_clean()
	var store := StoreScript.new(TEST_ROOT)
	var source := {
		"author_id": "author_a",
		"campaign_id": "short_campaign",
		"campaign_version": "1.0.0",
		"compatible_status_sources": [],
	}
	var state := StateScript.new()
	state.carry_forward_facts = {
		"villages_saved": 3,
		"new_fact_from_content": ["unit_a"],
	}
	var exported: Dictionary = store.export_completion(
		source,
		state,
		{"completed": true, "ending_id": "ending_a"},
		{"maps_completed": 5},
		"record_fixed"
	)
	_check(
		not exported.is_empty() and FileAccess.file_exists(exported.get("path", "")),
		"a completed run exports a compact checksummed record"
	)
	var first_record := FileAccess.get_file_as_string(exported["path"])
	var replaced: Dictionary = store.export_completion(
		source,
		state,
		{"completed": true, "ending_id": "ending_a"},
		{"maps_completed": 5},
		"record_fixed"
	)
	_check(
		(
			not replaced.is_empty()
			and FileAccess.get_file_as_string(exported["path"]) == first_record
			and not FileAccess.file_exists(exported["path"] + ".bak")
		),
		"status export replaces an existing record through staged promotion"
	)

	var same_campaign: Array[Dictionary] = store.scan_compatible(source)
	var sequel := {
		"author_id": "author_a",
		"campaign_id": "sequel",
		"campaign_version": "1.0.0",
		"compatible_status_sources":
		[
			{
				"author_id": "author_a",
				"campaign_id": "short_campaign",
				"campaign_versions": ["1.0.0"],
			}
		],
	}
	var sequel_matches: Array[Dictionary] = store.scan_compatible(sequel)
	var foreign := {
		"author_id": "author_b",
		"campaign_id": "foreign",
		"campaign_version": "1.0.0",
		"compatible_status_sources": [],
	}
	_check(
		(
			same_campaign.size() == 1
			and sequel_matches.size() == 1
			and store.scan_compatible(foreign).is_empty()
		),
		(
			"auto-scan finds same-campaign and declared sequel records, not foreign ones%s"
			% ("" if store.last_errors.is_empty() else ": %s" % "; ".join(store.last_errors))
		)
	)
	if sequel_matches.is_empty():
		_clean()
		print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
		quit(1)
		return

	var imported := StateScript.new()
	_check(
		(
			store.import_into(sequel_matches[0]["record"], sequel, imported)
			and imported.carry_forward_facts.get("villages_saved", 0) == 3
			and imported.carry_forward_facts.get("new_fact_from_content", []) == ["unit_a"]
			and imported.imported_record_ref.get("record_id", "") == "record_fixed"
		),
		"compatible import writes arbitrary fact ids and source identity"
	)
	var cm: Node = CampaignManagerScript.new()
	_check(
		(
			cm.import_carry_forward_facts(imported.carry_forward_facts)
			and cm.get_campaign_var("villages_saved") == 3
			and cm.get_campaign_var("new_fact_from_content") == ["unit_a"]
		),
		"imported facts seed the normal campaign-variable predicate store"
	)
	cm.free()

	var clean_state := StateScript.new()
	_check(
		clean_state.carry_forward_facts.is_empty() and clean_state.imported_record_ref.is_empty(),
		"choosing None leaves a clean mutable campaign state"
	)
	_check(
		(
			not store.import_into(exported["record"], foreign, clean_state)
			and clean_state.carry_forward_facts.is_empty()
			and store.import_into(exported["record"], foreign, clean_state, true)
		),
		"foreign records require the explicit manual-import path"
	)

	var tampered: Dictionary = exported["record"].duplicate(true)
	tampered["facts"]["villages_saved"] = 99
	var unchanged := StateScript.new()
	unchanged.carry_forward_facts = {"keep": true}
	_check(
		(
			not store.import_into(tampered, source, unchanged, true)
			and unchanged.carry_forward_facts == {"keep": true}
		),
		"checksum failure rejects without changing new-run state"
	)

	_clean()
	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _check(ok: bool, label: String) -> void:
	if ok:
		print("OK  %s" % label)
		_passed += 1
	else:
		print("FAIL %s" % label)
		_failed += 1


func _clean() -> void:
	var dir := DirAccess.open(TEST_ROOT)
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
	DirAccess.remove_absolute(TEST_ROOT)
