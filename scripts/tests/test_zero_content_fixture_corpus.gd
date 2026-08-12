extends SceneTree
# The engine, not the temporary pack-local Python specification, owns Z0/Z1
# diagnostics. Every fixture root is checked against its external expectation.

const Validator = preload("res://scripts/resources/ZeroContentFixtureValidator.gd")
const FIXTURES := "res://test_fixtures/zero_content"
const EXPECTED := "res://test_fixtures/zero_content_expected_errors"


func _init() -> void:
	var passed := 0
	var failed := 0
	for fixture_name in _fixture_names():
		var actual := Validator.validate(FIXTURES.path_join(fixture_name))
		var expected := _expected(fixture_name)
		if actual == expected:
			print("OK  %s matches its expected diagnostics" % fixture_name)
			passed += 1
		else:
			print("FAIL %s expected=%s actual=%s" % [fixture_name, expected, actual])
			failed += 1
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed else 0)


func _fixture_names() -> Array[String]:
	var names: Array[String] = []
	var directory := DirAccess.open(FIXTURES)
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		if directory.current_is_dir() and name.begins_with("z"):
			names.append(name)
		name = directory.get_next()
	directory.list_dir_end()
	names.sort()
	return names


func _expected(fixture_name: String) -> Array[Dictionary]:
	var path := EXPECTED.path_join("%s.json" % fixture_name)
	if not FileAccess.file_exists(path):
		return []
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var result: Array[Dictionary] = []
	for error in value:
		result.append(error)
	return result
