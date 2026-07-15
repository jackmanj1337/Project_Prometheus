extends SceneTree
# Pack identity and Tier-2 catalogue validation remain pure pre-install checks.

const PackManifestScript = preload("res://scripts/resources/PackManifest.gd")
const Tier2CatalogueScript = preload("res://scripts/resources/Tier2Catalogue.gd")


func _init() -> void:
	print("=== Campaign Package Catalogue Test ===")
	var passed := 0
	var failed := 0

	var manifest_errors: Array[String] = []
	var manifest = PackManifestScript.parse({
		"id": "fixture-pack", "version": "1.2.0", "forked_from": "base-pack",
		"builder_content_version": "0.4", "format_version": 1,
	}, "manifest.json", manifest_errors)
	if manifest != null and manifest.id == "fixture-pack" and manifest_errors.is_empty():
		print("OK  PackManifest parses the required identity contract"); passed += 1
	else:
		print("FAIL valid PackManifest: %s" % [manifest_errors]); failed += 1

	var bad_errors: Array[String] = []
	var bad_manifest = PackManifestScript.parse({
		"id": "Bad Id", "version": "", "builder_content_version": "0.4",
		"format_version": 99,
	}, "manifest.json", bad_errors)
	if bad_manifest == null and bad_errors.size() >= 3:
		print("OK  PackManifest rejects invalid identity and compatibility fields"); passed += 1
	else:
		print("FAIL invalid PackManifest: %s" % [bad_errors]); failed += 1

	var root_path := "user://test_campaign_package_catalogue/fixture-pack"
	_write_json(root_path.path_join("data/catalogue.json"), {
		"format_version": 1,
		"entries": [
			{"kind": "campaign", "id": "fixture", "path": "data/campaign.json"},
			{"kind": "labels", "id": "en", "path": "data/labels.json"},
		],
	})
	_write_json(root_path.path_join("data/campaign.json"), {"campaign_id": "fixture"})
	_write_json(root_path.path_join("data/labels.json"), {"start": "Begin"})
	var validators := {
		"campaign": Callable(self, "_validate_campaign"),
		"labels": Callable(self, "_validate_labels"),
	}
	var catalogue_errors: Array[String] = []
	var catalogue = Tier2CatalogueScript.load_and_validate(
		root_path, validators, catalogue_errors)
	if catalogue != null and catalogue.entries.size() == 2 \
			and catalogue.get_document("campaign", "fixture")["campaign_id"] == "fixture":
		print("OK  indexed Tier-2 documents parse and validate through open handlers"); passed += 1
	else:
		print("FAIL valid Tier-2 catalogue: %s" % [catalogue_errors]); failed += 1

	var malformed_errors: Array[String] = []
	var malformed = Tier2CatalogueScript.parse({
		"format_version": 1,
		"entries": [
			{"kind": "campaign", "id": "same", "path": "../escape.json"},
			{"kind": "campaign", "id": "same", "path": "data/other.json"},
		],
	}, "data/catalogue.json", malformed_errors)
	if malformed == null and malformed_errors.any(
			func(error): return "pack-relative" in error):
		print("OK  catalogue rejects traversal and duplicate identities"); passed += 1
	else:
		print("FAIL malformed catalogue: %s" % [malformed_errors]); failed += 1

	var unknown_errors: Array[String] = []
	var unknown_root := "user://test_campaign_package_catalogue/unknown"
	_write_json(unknown_root.path_join("data/catalogue.json"), {
		"format_version": 1,
		"entries": [{"kind": "future_kind", "id": "x", "path": "data/x.json"}],
	})
	_write_json(unknown_root.path_join("data/x.json"), {})
	var unknown = Tier2CatalogueScript.load_and_validate(unknown_root, {}, unknown_errors)
	if unknown == null and unknown_errors.any(
			func(error): return "no registered validator" in error):
		print("OK  unvalidated content kinds fail loud without a closed switch"); passed += 1
	else:
		print("FAIL unknown kind: %s" % [unknown_errors]); failed += 1

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _validate_campaign(document: Variant, entry: Dictionary,
		errors: Array[String]) -> void:
	if not document is Dictionary or document.get("campaign_id", "") != entry["id"]:
		errors.append("campaign id does not match catalogue identity")


func _validate_labels(document: Variant, _entry: Dictionary,
		errors: Array[String]) -> void:
	if not document is Dictionary:
		errors.append("labels must be an object")


func _write_json(path: String, value: Variant) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "\t", true))
