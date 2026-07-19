extends SceneTree

const PrepActivityDefScript = preload("res://scripts/ui/prep/PrepActivityDef.gd")
const PrepActivityRegistryScript = preload("res://scripts/resources/PrepActivityRegistry.gd")


func _init() -> void:
	print("=== Prep Activity Registry Test ===")
	var passed := 0
	var failed := 0
	var registry = PrepActivityRegistryScript.new()

	if registry.register_panel_type("fixture", _fixture_factory).is_empty():
		print("OK  panel factories register by open id")
		passed += 1
	else:
		print("FAIL fixture factory registration")
		failed += 1

	var activity = PrepActivityDefScript.new()
	activity.id = "inert_fixture"
	activity.panel_type = "fixture"
	activity.label = "Fixture"
	activity.params = {"message": "unchanged"}
	var errors: Array[String] = registry.register_activity(activity)
	var panel: Variant = registry.create_panel("inert_fixture", {"node_id": "chapter_1"})
	if (
		errors.is_empty()
		and panel == {"message": "unchanged", "node_id": "chapter_1"}
		and registry.activity_ids() == ["inert_fixture"]
	):
		print("OK  data-defined activity resolves without an engine switch")
		passed += 1
	else:
		print("FAIL activity resolution: errors=%s panel=%s" % [errors, panel])
		failed += 1

	var unknown = PrepActivityDefScript.new()
	unknown.id = "unknown"
	unknown.panel_type = "not_registered"
	if registry.validate_activity(unknown).any(func(error): return "unknown panel type" in error):
		print("OK  unknown panel types fail loud validation")
		passed += 1
	else:
		print("FAIL unknown panel type validation")
		failed += 1

	# Factories receive copies, so registry-owned authored parameters cannot be
	# mutated into accidental UI state by a panel implementation.
	if activity.params == {"message": "unchanged"}:
		print("OK  registry retains no mutable panel state")
		passed += 1
	else:
		print("FAIL factory mutated authored activity parameters")
		failed += 1

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _fixture_factory(params: Dictionary, context: Dictionary) -> Dictionary:
	var result := params
	result["node_id"] = context.get("node_id", "")
	return result
