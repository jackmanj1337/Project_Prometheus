extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_bbcode_escape.gd
# Guards the BBCode escaping helpers and the injection they exist to stop.
#
# The threat: pack-authored display names reach RichTextLabels with `bbcode_enabled`,
# and `[img]` resolves through ResourceLoader, so an unescaped "[" in imported pack
# data is a code-execution primitive rather than a formatting bug. Measured on Godot
# 4.6.3 — see [GDD-07-SCREENS-PANELS].

var _passed := 0
var _failed := 0


func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
		_passed += 1
	else:
		print("FAIL ", msg)
		_failed += 1


func _eq(got: String, want: String, msg: String) -> void:
	_ok(got == want, "%s (got %s, want %s)" % [msg, got, want])


func _init() -> void:
	print("=== BBCode Escape Test ===")

	# ---- opening brackets are what start a tag, so escaping them disarms the payload ----
	_eq(
		BBCode.escape("[img]user://evil.tres[/img]"),
		"[lb]img]user://evil.tres[lb]/img]",
		"every opening bracket becomes [lb]"
	)
	_eq(
		BBCode.escape("[url=http://phish]click[/url]"),
		"[lb]url=http://phish]click[lb]/url]",
		"url tags are neutralised too"
	)

	# ---- legitimate names must survive untouched, including the Class A punctuation ----
	for legit in ["Iron Sword", "O'Neill", "Jean-Luc", "St. Clair", "Sword +2", "Café"]:
		_eq(BBCode.escape(legit), legit, "ordinary name unchanged")

	# A "]" with no opener is already literal in BBCode, so rewriting it would
	# corrupt legitimate text for no security gain.
	_eq(BBCode.escape("HP 10 / 20]"), "HP 10 / 20]", "lone closing bracket stays literal")

	# ---- metas sit inside the tag, where "]" closes it early and [lb] does not help ----
	_eq(
		BBCode.escape_meta("evil]end[/url][img]x[/img]"),
		"evilend/urlimgx/img",
		"meta cannot close its own tag"
	)
	for id in ["iron_sword", "class:knight", "wexp-sword", "stat:hp", "skill_rally"]:
		_eq(BBCode.escape_meta(id), id, "well-formed id untouched")

	# ---- the concrete measured exploit ----
	var escaped := BBCode.escape("Sword[img]user://evil.tres[/img]")
	_ok(not escaped.contains("[img"), "no live [img tag survives escaping")
	_ok(escaped.begins_with("Sword"), "visible text is preserved")

	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
