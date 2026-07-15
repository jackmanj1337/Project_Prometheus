extends SceneTree
# Advisory whole/protected hashes, including author-designated dotted paths.

const Integrity = preload("res://scripts/save/SaveIntegrity.gd")


func _init() -> void:
	print("=== Save Integrity Test ===")
	var passed := 0
	var failed := 0
	var source := {
		"format_version": 1,
		"integrity": {},
		"header": {"label": "Before"},
		"campaign": {
			"campaign_id": "fixture", "node_id": "n1", "cleared_nodes": [],
			"rules": {}, "protected_fields": ["party.resources.reputation"],
		},
		"party": {"resources": {"reputation": 7}},
	}
	var stamped: Dictionary = Integrity.stamp(source)
	if Integrity.verify(stamped).is_empty():
		print("OK  freshly stamped save verifies"); passed += 1
	else:
		print("FAIL freshly stamped save warned"); failed += 1
	var ordinary := stamped.duplicate(true)
	ordinary["header"]["label"] = "Edited"
	var ordinary_warnings: Array[String] = Integrity.verify(ordinary)
	if ordinary_warnings == [Integrity.PAYLOAD_WARNING]:
		print("OK  ordinary edits warn only on the whole payload"); passed += 1
	else:
		print("FAIL ordinary warning set: %s" % [ordinary_warnings]); failed += 1
	var protected := stamped.duplicate(true)
	protected["party"]["resources"]["reputation"] = 99
	var protected_warnings: Array[String] = Integrity.verify(protected)
	if Integrity.PAYLOAD_WARNING in protected_warnings \
			and Integrity.PROTECTED_WARNING in protected_warnings:
		print("OK  authored dotted paths participate in the protected hash"); passed += 1
	else:
		print("FAIL authored protected warning set: %s" % [protected_warnings]); failed += 1
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)
