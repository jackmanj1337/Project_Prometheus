extends SceneTree

const TextDBScript = preload("res://scripts/text/TextDB.gd")
const RequirementSystemScript = preload("res://scripts/autoloads/RequirementSystem.gd")
const FIXTURE := "res://scripts/tests/fixtures/text/basic.json"


func _init() -> void:
	var passed := 0
	var failed := 0
	var db = TextDBScript.new()

	if db.load_json_table(FIXTURE).is_empty() and db.tr_key("req.has_item") == "Carry the seal":
		passed += 1
		print("OK  a data-defined text table loads without an engine edit")
	else:
		failed += 1
		print("FAIL fixture table load")

	if db.tr_key("req.class_level", {"n": 12}) == "Reach level 12":
		passed += 1
		print("OK  named placeholders are substituted")
	else:
		failed += 1
		print("FAIL named placeholder substitution")

	var first_missing := db.tr_key("req.unknown")
	db.tr_key("req.unknown")
	if first_missing == "#missing:req.unknown" and db.validation_warnings().size() == 1:
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

	# The shipped engine table must cover the WHOLE registered predicate vocabulary. Adding
	# a predicate adds two text keys, and nothing else notices if they go unauthored — the
	# player just reads the key id. Note the assertion shape: it compares the RENDERED
	# string against the key and against the missing marker, because both fallbacks return
	# a non-empty, plausible-looking string. An "is it non-empty?" check passes either way
	# and would prove nothing about whether the table was ever consulted.
	var engine = TextDBScript.new()
	var engine_errors: Array[String] = engine.load_json_table(TextDBScript.ENGINE_TABLE)
	var registry = RequirementSystemScript.new()
	registry._ready()
	var uncovered: Array[String] = []
	for key in registry.all_text_keys():
		var rendered: String = engine.tr_key(key)
		if rendered == key or rendered.begins_with(TextDBScript.MISSING_PREFIX):
			uncovered.append(key)
	if engine_errors.is_empty() and uncovered.is_empty():
		passed += 1
		print("OK  the engine table covers every registered predicate key")
	else:
		failed += 1
		print("FAIL engine table coverage: %s %s" % [engine_errors, uncovered])

	# End to end through the autoload seam: a caller that passes NO table still reads a
	# sentence, because render_reason resolves /root/TextDB itself. Before this row every
	# production caller fell through to the bare key, so this is the behaviour the row
	# exists to create.
	# End to end through the REAL autoload, which is the behaviour this row exists to
	# create: a caller that passes no table still reads a sentence, because render_reason
	# resolves /root/TextDB itself. Before the autoload existed, no production caller could
	# obtain a table at all and every unmet reason rendered as its own key.
	#
	# The frame wait is load-bearing, not ceremony. Inside a SceneTree script's _init() the
	# root Window is not yet inside the tree (is_inside_tree() is false and get_path() is
	# empty), so absolute lookups return null and queued _ready() calls have not run. A
	# test written without it measures the harness, not the wiring.
	var system = RequirementSystemScript.new()
	root.add_child(system)
	await process_frame

	var table: Node = root.get_node_or_null("TextDB")
	if table != null and table.has_method("tr_key"):
		passed += 1
		print("OK  TextDB is registered as an autoload and is reachable at /root/TextDB")
	else:
		failed += 1
		print("FAIL TextDB autoload missing from /root")

	var unmet: Dictionary = system.evaluate(
		{"predicate_id": "flag", "params": {"scope": "campaign", "name": "the seal"}}, {}
	)
	var sentence: String = system.render_reason(unmet.reasons[0])
	if sentence == "Requires the seal.":
		passed += 1
		print("OK  an unmet reason renders as a sentence with no table threaded through")
	else:
		failed += 1
		print("FAIL autoload-resolved reason rendering: '%s'" % sentence)

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)
