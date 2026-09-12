extends SceneTree

const EntitySchemas = preload("res://scripts/data/EntitySchemaRegistry.gd")

const FIXTURE_ROOT := "res://scripts/tests/fixtures/drc_slice0"
const EXPECTED_FILES := [
	"atomic_branch_recruit_conversation.json",
	"temporary_guest.json",
	"capture_release_extract.json",
	"trade_captive_passenger.json",
	"designated_convoy_provider.json",
	"map_end_prison_intake.json",
	"relationship_gated_prison_visit.json",
	"contradictory_stat_floor_cap.json",
]


func _init() -> void:
	print("=== DRC Slice 0 Fixture Test ===")
	var passed := 0
	var failed := 0
	var seen_ids := {}
	var schemas := EntitySchemas.new()
	for filename in EXPECTED_FILES:
		var path := "%s/%s" % [FIXTURE_ROOT, filename]
		var document: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not document is Dictionary:
			print("FAIL %s is not a JSON object" % filename)
			failed += 1
			continue
		var id := String(document.get("id", ""))
		var kind := String(document.get("kind", ""))
		var version := int(document.get("schema_version", 0))
		var diagnostics: Array[Dictionary] = schemas.validate_document(
			kind, version, document, {}, {}
		)
		var explicitly_unsupported: bool = (
			diagnostics.size() == 1 and diagnostics[0].get("code") == "schema_unknown"
		)
		var avoids_retired_shapes: bool = (
			not document.has("conversation_resume")
			and not document.has("visited_trail")
			and not document.has("captured")
			and not document.has("recruited")
		)
		if (
			not id.is_empty()
			and not kind.is_empty()
			and version == 1
			and not seen_ids.has(id)
			and explicitly_unsupported
			and avoids_retired_shapes
		):
			seen_ids[id] = true
			print("OK  %s is inert data with an explicit unsupported-family diagnostic" % filename)
			passed += 1
		else:
			print("FAIL %s: id=%s kind=%s diagnostics=%s" % [filename, id, kind, diagnostics])
			failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
