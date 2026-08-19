extends SceneTree

const TextDBScript = preload("res://scripts/text/TextDB.gd")
const FIXTURE := "res://scripts/tests/fixtures/text/basic.json"


func _init() -> void:
	var passed := 0
	var failed := 0
	var db = TextDBScript.new()

	if db.load_json_table(FIXTURE).is_empty() and db.tr_key("requirement.item") == "Carry the seal":
		passed += 1
		print("OK  a data-defined text table loads without an engine edit")
	else:
		failed += 1
		print("FAIL fixture table load")

	if db.tr_key("requirement.level", {"level": 12}) == "Reach level 12":
		passed += 1
		print("OK  named placeholders are substituted")
	else:
		failed += 1
		print("FAIL named placeholder substitution")

	var first_missing := db.tr_key("requirement.unknown")
	db.tr_key("requirement.unknown")
	if first_missing == "#missing:requirement.unknown" and db.validation_warnings().size() == 1:
		passed += 1
		print("OK  missing keys are visible and reported once")
	else:
		failed += 1
		print("FAIL missing-key policy: %s %s" % [first_missing, db.validation_warnings()])

	var malformed_errors: Array[String] = db.add_table({"bad": 3}, "fixture")
	if not malformed_errors.is_empty() and not db.has_key("bad"):
		passed += 1
		print("OK  non-string table values fail validation")
	else:
		failed += 1
		print("FAIL malformed table validation")

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)
