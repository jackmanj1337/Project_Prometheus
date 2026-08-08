extends SceneTree

# Committed malformed/legacy artifacts ensure validation is exercised against
# stable bytes rather than only dictionaries assembled inside a test.
const SaveDataScript = preload("res://scripts/save/SaveData.gd")
const PackManifestScript = preload("res://scripts/resources/PackManifest.gd")
const Tier2CatalogueScript = preload("res://scripts/resources/Tier2Catalogue.gd")

const FIXTURE_ROOT := "res://test_fixtures"


func _init() -> void:
	print("=== Malformed Save And Package Fixtures Test ===")
	var passed := 0
	var failed := 0

	var malformed_text := FileAccess.get_file_as_string(
		FIXTURE_ROOT.path_join("saves/malformed_truncated.json")
	)
	var malformed_parser := JSON.new()
	if malformed_parser.parse(malformed_text) != OK:
		print("OK  truncated save fixture fails at the JSON boundary")
		passed += 1
	else:
		print("FAIL truncated save fixture unexpectedly parsed")
		failed += 1

	var legacy_raw: Variant = _read_json("saves/legacy_minimal.json")
	var legacy: RefCounted = SaveDataScript.from_dict(legacy_raw)
	if (
		legacy.campaign["campaign_id"] == "legacy_fixture"
		and legacy.party["resources"]["party_gold"] == 125
		and legacy.campaign["rules"]["death_mode"] == "casual"
	):
		print("OK  committed legacy save fixture follows the defaulting path")
		passed += 1
	else:
		print("FAIL legacy fixture defaults: %s" % [legacy.to_dict()])
		failed += 1

	var manifest_errors: Array[String] = []
	var manifest = PackManifestScript.parse(
		_read_json("packages/missing_manifest_fields.json"),
		"missing_manifest_fields.json",
		manifest_errors
	)
	if manifest == null and manifest_errors.size() >= 3:
		print("OK  malformed manifest fixture fails identity and compatibility validation")
		passed += 1
	else:
		print("FAIL malformed manifest fixture: %s" % [manifest_errors])
		failed += 1

	var catalogue_errors: Array[String] = []
	var catalogue = Tier2CatalogueScript.parse(
		_read_json("packages/duplicate_catalogue_identity.json"),
		"duplicate_catalogue_identity.json",
		catalogue_errors
	)
	if (
		catalogue == null
		and catalogue_errors.any(func(error): return "duplicates kind/id" in error)
	):
		print("OK  duplicate package identities fail loud from committed fixture bytes")
		passed += 1
	else:
		print("FAIL duplicate catalogue fixture: %s" % [catalogue_errors])
		failed += 1

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _read_json(relative_path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_ROOT.path_join(relative_path)))
