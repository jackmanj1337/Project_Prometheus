extends SceneTree

const CampaignVarsScript = preload("res://scripts/autoloads/CampaignVars.gd")
const CampaignVarDefScript = preload("res://scripts/resources/CampaignVarDef.gd")
const FIXTURE := "res://scripts/tests/fixtures/campaign_vars/test_mode.tres"


func _init() -> void:
	var passed := 0
	var failed := 0
	var store = CampaignVarsScript.new()

	var flag = _definition("story_open", "bool", false, "campaign")
	var count = _definition("wins", "int", 0, "campaign")
	count.min_value = 0
	count.max_value = 3
	var map_mode = _definition("weather", "enum", "clear", "map")
	var weather_options: Array[String] = ["clear", "rain"]
	map_mode.options = weather_options
	for definition in [flag, count, map_mode]:
		if not store.register_definition(definition).is_empty():
			failed += 1

	if store.set_var("story_open", true) and store.get_var("story_open") == true:
		passed += 1
	else:
		failed += 1
		print("FAIL bool round-trip")
	if store.set_var("wins", 3) and not store.set_var("wins", 4) and not store.set_var("wins", 1.0):
		passed += 1
	else:
		failed += 1
		print("FAIL int validation")
	if store.set_var("weather", "rain") and not store.set_var("weather", "snow"):
		store.reset_map_scope()
		if store.get_var("weather") == "clear":
			passed += 1
		else:
			failed += 1
	else:
		failed += 1
		print("FAIL enum/reset validation")

	store.set_var("story_open", true)
	var saved := store.capture_campaign_values()
	store.clear_all()
	if store.restore_campaign_values(saved) and store.get_var("story_open") == true:
		passed += 1
	else:
		failed += 1
		print("FAIL campaign save round-trip")

	if store.get_var("missing") == null and not store.validation_errors().is_empty():
		passed += 1
	else:
		failed += 1
		print("FAIL unknown id policy")

	var fixture: Resource = ResourceLoader.load(FIXTURE)
	if (
		fixture != null
		and store.register_definition(fixture).is_empty()
		and store.get_var("test_mode") == "normal"
	):
		passed += 1
	else:
		failed += 1
		print("FAIL data-defined variable load")

	var unit := UnitData.new()
	unit.groups = ["royal", "fliers"]
	var duplicate: UnitData = unit.duplicate(true)
	if duplicate.groups == unit.groups:
		passed += 1
	else:
		failed += 1
		print("FAIL UnitData.groups resource round-trip")

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _definition(id: String, value_type: String, default_value: Variant, scope: String) -> Resource:
	var definition: Resource = CampaignVarDefScript.new()
	definition.id = id
	definition.value_type = value_type
	match value_type:
		"bool":
			definition.default_bool = bool(default_value)
		"int":
			definition.default_int = int(default_value)
		"enum":
			definition.default_enum = String(default_value)
	definition.scope = scope
	return definition
