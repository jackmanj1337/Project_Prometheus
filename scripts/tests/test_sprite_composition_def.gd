extends SceneTree
## Pure contracts for authored sprite composition and faction palettes.

const Composition = preload("res://scripts/resources/SpriteCompositionDef.gd")
const Palette = preload("res://scripts/resources/FactionPaletteDef.gd")


func _init() -> void:
	print("=== Sprite Composition Definition Test ===")
	var passed := 0
	var failed := 0

	var palette_errors: Array[String] = []
	var palette := (
		Palette
		. parse(
			{
				"schema_version": 1,
				"id": "blue_normal",
				"display_name": "Blue normal",
				"fallback_tint": [64, 96, 192, 255],
				"mappings": [{"from": [255, 0, 0, 255], "to": [0, 0, 255, 255], "role": "armour"}],
			},
			"palette",
			palette_errors
		)
	)
	if palette != null and palette_errors.is_empty() and palette.normalized_mappings().size() == 1:
		_ok("palette parses exact RGBA mappings", passed)
		passed += 1
	else:
		_fail("palette parse: %s" % palette_errors, failed)
		failed += 1

	var palette_round_trip: Dictionary = palette.to_dict() if palette != null else {}
	if (
		palette != null
		and palette_round_trip.get("fallback_tint") == [64, 96, 192, 255]
		and palette_round_trip.get("mappings", []).size() == 1
		and palette_round_trip["mappings"][0]["role"] == "armour"
	):
		_ok("palette remains JSON-friendly and preserves metadata", passed)
		passed += 1
	else:
		_fail("palette round trip", failed)
		failed += 1

	var duplicate_palette := Palette.new()
	duplicate_palette.id = "duplicate"
	duplicate_palette.mappings = [
		{"from": [255, 0, 0, 255], "to": [0, 0, 255, 255]},
		{"from": [255, 0, 0, 255], "to": [0, 255, 0, 255]},
	]
	if duplicate_palette.validation_errors().any(
		func(error: String): return "duplicates source" in error
	):
		_ok("duplicate palette sources fail loudly", passed)
		passed += 1
	else:
		_fail("duplicate palette sources accepted", failed)
		failed += 1

	var large_palette := Palette.new()
	large_palette.id = "large"
	for index in 17:
		large_palette.mappings.append(
			{"from": [index + 1, 0, 0, 255], "to": [0, index + 1, 0, 255]}
		)
	if (
		large_palette.validation_errors().is_empty()
		and large_palette.validation_warnings().size() == 1
	):
		_ok("sixteen-entry guidance is a warning while thirty-two is the hard cap", passed)
		passed += 1
	else:
		_fail("palette capacity guidance", failed)
		failed += 1
	var over_capacity := Palette.new()
	over_capacity.id = "over_capacity"
	for index in 33:
		over_capacity.mappings.append(
			{"from": [index % 255, 1, 1, 255], "to": [1, index % 255, 1, 255]}
		)
	if over_capacity.validation_errors().any(func(error: String): return "more than 32" in error):
		_ok("palette mappings above the runtime cap fail", passed)
		passed += 1
	else:
		_fail("palette hard cap", failed)
		failed += 1

	var base := {
		"schema_version": 1,
		"id": "base_unit",
		"anchors":
		[
			{"id": "feet", "parent": "origin", "offset": [0, 32]},
			{"id": "badge", "parent": "feet", "offset": [0, -36]},
		],
		"layers":
		[
			{"id": "body", "asset_id": "unit_sheet", "animation": "idle", "anchor": "feet"},
			{
				"id": "badge",
				"asset_id": "tier_badge",
				"anchor": "badge",
				"palette_id": "blue_normal"
			},
		],
	}
	var child := {
		"schema_version": 1,
		"id": "promoted_unit",
		"base_composition_id": "base_unit",
		"layer_operations":
		[
			{
				"op": "replace",
				"layer_id": "body",
				"layer": {"id": "body", "asset_id": "promoted_sheet", "anchor": "feet"}
			},
			{
				"op": "insert_before",
				"relative_to": "body",
				"layer": {"id": "shadow", "asset_id": "shadow_sheet", "anchor": "feet"}
			},
			{"op": "move_after", "layer_id": "badge", "relative_to": "body"},
		],
	}
	var resolved := Composition.resolve(child, {"base_unit": base})
	var resolved_layers: Array = resolved["composition"].get("layers", [])
	if (
		resolved["errors"].is_empty()
		and resolved_layers.size() == 3
		and resolved_layers[0]["id"] == "shadow"
		and resolved_layers[1]["id"] == "body"
		and resolved_layers[1]["asset_id"] == "promoted_sheet"
		and resolved_layers[2]["id"] == "badge"
	):
		_ok("inheritance resolves replace, insert, and reorder by stable layer id", passed)
		passed += 1
	else:
		_fail("layer operation resolution: %s / %s" % [resolved["errors"], resolved_layers], failed)
		failed += 1

	var invalid_errors: Array[String] = []
	var invalid := (
		Composition
		. parse(
			{
				"schema_version": 1,
				"id": "invalid",
				"anchors":
				[
					{"id": "a", "parent": "b", "offset": [0, 0]},
					{"id": "b", "parent": "a", "offset": [0, 0]},
				],
				"layers": [{"id": "unit", "asset_id": "unit_sheet", "anchor": "missing"}],
			},
			"invalid",
			invalid_errors
		)
	)
	if (
		invalid == null
		and invalid_errors.any(func(error: String): return "anchor cycle" in error)
		and invalid_errors.any(func(error: String): return "missing anchor" in error)
	):
		_ok("anchor cycles and missing layer anchors are rejected", passed)
		passed += 1
	else:
		_fail("anchor validation: %s" % invalid_errors, failed)
		failed += 1

	var inheritance_cycle := (
		Composition
		. resolve(
			{"schema_version": 1, "id": "one", "base_composition_id": "two"},
			{"two": {"schema_version": 1, "id": "two", "base_composition_id": "one"}},
		)
	)
	if inheritance_cycle["errors"].any(func(error: String): return "inheritance cycle" in error):
		_ok("composition inheritance cycles are rejected", passed)
		passed += 1
	else:
		_fail("inheritance cycle accepted", failed)
		failed += 1

	var malformed_operation_errors: Array[String] = []
	var malformed_operation := (
		Composition
		. parse(
			{
				"schema_version": 1,
				"id": "malformed",
				"layers": [{"id": "body", "asset_id": "unit_sheet"}],
				"layer_operations":
				[{"op": "replace", "layer_id": "body", "layer": {"id": "other"}}],
			},
			"malformed",
			malformed_operation_errors
		)
	)
	if (
		malformed_operation == null
		and malformed_operation_errors.any(
			func(error: String): return "must match layer_id" in error
		)
	):
		_ok("malformed layer operations fail during schema validation", passed)
		passed += 1
	else:
		_fail("malformed operation accepted: %s" % malformed_operation_errors, failed)
		failed += 1

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _ok(message: String, _passed: int) -> void:
	print("OK  " + message)


func _fail(message: String, _failed: int) -> void:
	print("FAIL " + message)
