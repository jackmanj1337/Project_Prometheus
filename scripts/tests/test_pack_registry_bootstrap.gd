extends SceneTree
# Pack registry declarations must be validated before dependent entity schemas.

const Validators = preload("res://scripts/resources/CampaignTier2Validators.gd")
const Tier2CatalogueScript = preload("res://scripts/resources/Tier2Catalogue.gd")


func _init() -> void:
	print("=== Pack Registry Bootstrap Test ===")
	var passed := 0
	var failed := 0

	var valid = _catalogue([_registry_entry("custom_heal", "heal_flat")])
	valid.entries.append(_entry("item", "tonic"))
	valid.documents["item\ntonic"] = _item("custom_heal")
	var valid_errors := Validators.collect_entity_schema_errors(valid)
	if valid_errors.is_empty():
		print("OK  pack-declared item effect is admitted before dependent content")
		passed += 1
	else:
		print("FAIL valid declaration: %s" % [valid_errors])
		failed += 1

	var unknown = _catalogue([_registry_entry("custom_heal", "invented_code")])
	unknown.entries.append(_entry("item", "tonic"))
	unknown.documents["item\ntonic"] = _item("custom_heal")
	var unknown_errors := Validators.collect_entity_schema_errors(unknown)
	if (
		_has_code(unknown_errors, "vocabulary_value_unknown")
		and not _has_path(unknown_errors, "$[item@1:tonic].effect_id")
	):
		print("OK  unknown primitive rejects the bootstrap atomically")
		passed += 1
	else:
		print("FAIL unknown primitive atomicity: %s" % [unknown_errors])
		failed += 1

	var duplicate = _catalogue(
		[
			_registry_entry("custom_heal", "heal_flat", "first"),
			_registry_entry("custom_heal", "heal_full", "second"),
		]
	)
	var duplicate_errors := Validators.collect_entity_schema_errors(duplicate)
	if _has_code(duplicate_errors, "registry_entry_duplicate"):
		print("OK  duplicate ids fail within one pack with a stable code")
		passed += 1
	else:
		print("FAIL duplicate identity: %s" % [duplicate_errors])
		failed += 1

	var first_pack_errors := Validators.collect_entity_schema_errors(
		_catalogue([_registry_entry("shared_local_id", "heal_flat")])
	)
	var second_pack_errors := Validators.collect_entity_schema_errors(
		_catalogue([_registry_entry("shared_local_id", "heal_flat")])
	)
	if first_pack_errors.is_empty() and second_pack_errors.is_empty():
		print("OK  identical local ids remain independent across separate packs")
		passed += 1
	else:
		print("FAIL separate-pack identity: %s / %s" % [first_pack_errors, second_pack_errors])
		failed += 1

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


static func _catalogue(registry_documents: Array[Dictionary]):
	var catalogue := Tier2CatalogueScript.new()
	catalogue.entries.append(_entry("source_registry", "sources"))
	catalogue.documents["source_registry\nsources"] = {
		"schema_version": 1,
		"sources":
		{
			"fixture":
			{
				"locator": "test://pack-registry-bootstrap",
				"title": "Pack registry bootstrap fixture",
				"rights_status": "project_original",
				"verified_at": "2026-08-11",
			}
		}
	}
	for document in registry_documents:
		var catalogue_id := String(document["id"])
		catalogue.entries.append(_entry("registry_entry", catalogue_id))
		catalogue.documents["registry_entry\n%s" % catalogue_id] = document
	return catalogue


static func _entry(kind: String, id: String) -> Dictionary:
	return {"kind": kind, "id": id, "path": "data/%s.json" % id}


static func _registry_entry(
	entry_id: String, primitive_handler: String, suffix: String = "only"
) -> Dictionary:
	return {
		"kind": "registry_entry",
		"schema_version": 1,
		"id": "item_effects__%s__%s" % [entry_id, suffix],
		"display_name": entry_id,
		"source_refs": ["fixture"],
		"family": "item_effects",
		"entry_id": entry_id,
		"label_key": "item_effect.%s" % entry_id,
		"owner_feature": "test",
		"version": 1,
		"entry_kind": "mutation",
		"primitive_handler": primitive_handler,
		"params_schema": {},
		"save_fields": ["UnitData.hp"],
		"docs_text": "Fixture entry.",
		"test_fixture": {"amount": 1},
	}


static func _item(effect_id: String) -> Dictionary:
	return {
		"kind": "item",
		"schema_version": 1,
		"id": "tonic",
		"display_name": "Tonic",
		"source_refs": ["fixture"],
		"item_type": "healing",
		"uses": 1,
		"cost": 1,
		"effect_id": effect_id,
		"effect_params": {"amount": 1},
		"field_completeness": {"provenance": "not_applicable"},
	}


static func _has_code(errors: Array[String], code: String) -> bool:
	return errors.any(func(error: String) -> bool: return error.contains(": %s at " % code))


static func _has_path(errors: Array[String], path: String) -> bool:
	return errors.any(func(error: String) -> bool: return error.ends_with(" at %s" % path))
