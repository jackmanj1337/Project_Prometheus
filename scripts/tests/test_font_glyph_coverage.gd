extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_font_glyph_coverage.gd
#
# `UI-FONT-MISSING-EM-DASH-GLYPH-2026-09-22`. The UI font kit is ASCII-only, so every
# non-ASCII character the UI drew rendered as a missing-glyph box. The reported one was the
# em dash; the measurement found seventeen, including the combat interaction readout's
# shape glyphs -- the DEFAULT presentation for every authored relationship row.
#
# THE ASSERTIONS THAT CARRY THE FIX, and that nothing else can catch:
#
#   * THE REQUIRED SET IS MINED FROM THE SOURCE, NOT LISTED HERE. A hardcoded list would
#     pass forever while the next screen added a character nobody checked -- which is
#     exactly how seventeen of them accumulated. The ruling asked for a check that catches
#     the NEXT one before a tester does, and only a scan does that. The cost is that adding
#     a non-ASCII character to a player-facing string can fail this suite; that is the
#     intended behaviour, and the fix is a fallback that covers it, never deleting the case.
#   * THE BASE FACE IS STILL THE PIXEL KIT. A fallback that quietly became the primary font
#     would make every glyph render and every screen look wrong, and would pass a check
#     that only asked about coverage. Asserted by reading the resolved font's base.
#   * A PACK FONT KEEPS THE FALLBACK BEHIND IT. An author chooses their letters; they do
#     not get to choose whether the em dash renders. Without this a pack shipping a pixel
#     face re-introduces the whole defect for its own players, and no engine test would
#     see it.
#   * DEACTIVATION RESTORES THE ENGINE FACE. The failure this catches is a pack's
#     typography outliving its content -- the main menu still wearing a campaign's letters
#     after the campaign is gone. Invisible in any test that only activates.

const UiFontStackScript = preload("res://scripts/ui/UiFontStack.gd")
const ManifestScript = preload("res://scripts/resources/PackManifest.gd")

## Where player-facing text is built. `scripts/tests` is excluded because a test's own
## strings are not drawn, and `scripts/tools` because those are developer probes.
const SCANNED_DIRS: Array[String] = [
	"res://scripts/ui",
	"res://scripts/combat",
	"res://scripts/autoloads",
	"res://scripts/save",
	"res://scripts/shared",
	"res://scripts/editor",
]

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Font Glyph Coverage Test ===")
	await process_frame

	_the_ui_face_covers_every_character_the_ui_draws()
	_the_pixel_kit_is_still_the_primary_face()
	_a_pack_font_keeps_the_fallback_behind_it()
	_deactivation_restores_the_engine_face()
	_a_pack_face_cannot_escape_its_pack()
	_a_manifest_font_path_is_contained()

	UiFontStackScript.apply()
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % label)
	else:
		_failed += 1
		print("  FAIL: %s%s" % [label, ("  [%s]" % detail) if detail != "" else ""])


# ---- the mined requirement ----


## Every codepoint above ASCII that appears outside a comment, with one example site each
## so a failure names somewhere to look rather than only a number.
func _required_codepoints() -> Dictionary:
	var found := {}
	for dir_path in SCANNED_DIRS:
		_scan_dir(dir_path, found)
	return found


func _scan_dir(dir_path: String, found: Dictionary) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for name in dir.get_directories():
		_scan_dir(dir_path.path_join(name), found)
	for name in dir.get_files():
		if not name.ends_with(".gd"):
			continue
		_scan_file(dir_path.path_join(name), found)


func _scan_file(path: String, found: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var line_number := 0
	while not file.eof_reached():
		var line := file.get_line()
		line_number += 1
		# Comments are documentation, not drawn text. They are where the em dash is used
		# most in this repo, so counting them would swamp the real finding.
		if line.strip_edges().begins_with("#"):
			continue
		for character in line:
			var code := character.unicode_at(0)
			if code > 127 and not found.has(code):
				found[code] = "%s:%d" % [path, line_number]
	file.close()


func _the_ui_face_covers_every_character_the_ui_draws() -> void:
	print("\n-- the UI face covers every character the UI draws --")
	UiFontStackScript.apply()
	var font: Font = (load(UiFontStackScript.THEME_PATH) as Theme).default_font
	_check("the theme resolves a font", font != null)
	if font == null:
		return
	var required := _required_codepoints()
	_check("the scan found characters to check", required.size() > 0, str(required.size()))
	var missing: Array[String] = []
	for code in required:
		if not font.has_char(int(code)):
			missing.append("U+%04X (%s)" % [code, required[code]])
	_check(
		"every one of the %d non-ASCII characters resolves to a glyph" % required.size(),
		missing.is_empty(),
		", ".join(missing)
	)


func _the_pixel_kit_is_still_the_primary_face() -> void:
	print("\n-- the pixel kit is still the primary face --")
	UiFontStackScript.apply()
	var font: Font = (load(UiFontStackScript.THEME_PATH) as Theme).default_font
	var variation := font as FontVariation
	_check("the UI face is a variation carrying a fallback", variation != null)
	if variation == null:
		return
	var base: Font = variation.base_font
	_check(
		"its base is the authored pixel kit, not the fallback",
		base != null and base.resource_path.contains("TinyRPG"),
		base.resource_path if base != null else "<null>"
	)
	_check("and a fallback stands behind it", variation.fallbacks.size() >= 1)


# ---- the pack face ----


func _a_pack_font_keeps_the_fallback_behind_it() -> void:
	print("\n-- a pack font keeps the fallback behind it --")
	# The pixel kit shipped with the engine stands in for "a pack that ships a pixel face":
	# it is the exact failing case, an ASCII-only font an author might reasonably choose.
	var pack_root := "res://Draft UI assets/tinyrpgfontkit01_v1_2"
	var pack_face := "TinyRPG-BrilliantStrength.ttf"
	_check("applying a pack face succeeds", UiFontStackScript.apply(pack_root, pack_face))
	var font: Font = (load(UiFontStackScript.THEME_PATH) as Theme).default_font
	_check("the pack's face is now the base", font != null and (font as FontVariation) != null)
	# Identity is asked of the SERVICE, not of the resource: a pack face is built at runtime
	# and has no `resource_path`, so the theme cannot say whose letters these are.
	_check(
		"and the service reports the PACK's face as the one drawing",
		UiFontStackScript.active_font_path() == pack_root.path_join(pack_face),
		UiFontStackScript.active_font_path()
	)
	_check("the em dash still renders through the fallback", font != null and font.has_char(0x2014))
	_check(
		"as do the interaction readout's shape glyphs",
		font != null and font.has_char(0x25B2) and font.has_char(0x25BC) and font.has_char(0x25A0)
	)


func _deactivation_restores_the_engine_face() -> void:
	print("\n-- deactivation restores the engine face --")
	var pack_root := "res://Draft UI assets/tinyrpgfontkit01_v1_2"
	var badge := "TinyRPG-BadgeFont.ttf"
	UiFontStackScript.apply(pack_root, badge)
	UiFontStackScript.apply()
	_check(
		"the engine's own face is back",
		UiFontStackScript.active_font_path().is_empty(),
		UiFontStackScript.active_font_path()
	)
	var font: Font = (load(UiFontStackScript.THEME_PATH) as Theme).default_font
	var variation := font as FontVariation
	_check(
		"and the theme names the authored engine resource again",
		font != null and font.resource_path == UiFontStackScript.ENGINE_FONT_PATH,
		font.resource_path if font != null else "<null>"
	)
	_check(
		"whose base is the pixel kit",
		(
			variation != null
			and variation.base_font != null
			and variation.base_font.resource_path.contains("FineFantasyStrategies")
		)
	)

	# A face that cannot be loaded must fall back to the ENGINE, never leave the previous
	# pack's standing: a pack whose font went missing between validation and activation
	# should look like the engine, not like whoever was active before it. `load_dynamic_font`
	# returns OK for a missing file, so this is guarded by hand -- see `_load_pack_font`.
	UiFontStackScript.apply(pack_root, badge)
	_check(
		"an unresolvable face reports failure", not UiFontStackScript.apply(pack_root, "nope.ttf")
	)
	_check(
		"and the engine face is what is drawing, not the previous pack's",
		UiFontStackScript.active_font_path().is_empty(),
		UiFontStackScript.active_font_path()
	)
	var after: Font = (load(UiFontStackScript.THEME_PATH) as Theme).default_font
	_check(
		"which the theme confirms",
		after != null and after.resource_path == UiFontStackScript.ENGINE_FONT_PATH,
		after.resource_path if after != null else "<null>"
	)


## `AssetResolver` refuses a path that escapes its pack, and routing through it is what
## check 32 requires. Asserted at THIS boundary as well as at the manifest's, because the
## two refusals are independent: a manifest is parsed once at install, and this runs on
## every activation, including one restored from a save.
func _a_pack_face_cannot_escape_its_pack() -> void:
	print("\n-- a pack face cannot escape its pack --")
	var pack_root := "res://Draft UI assets/tinyrpgfontkit01_v1_2"
	UiFontStackScript.apply()
	for escape in [
		"../tinyrpg_fontkit02_v1_0/Tiny RPG - Mana Root.ttf", "/etc/passwd", "res://x.ttf"
	]:
		_check("refuses %s" % escape, not UiFontStackScript.apply(pack_root, escape), "accepted it")
	_check(
		"and the engine face is still what is drawing",
		UiFontStackScript.active_font_path().is_empty(),
		UiFontStackScript.active_font_path()
	)


func _a_manifest_font_path_is_contained() -> void:
	print("\n-- a manifest font path is contained --")
	var base := {
		"id": "pack-a",
		"version": "1.0.0",
		"builder_content_version": "0.1.0",
		"format_version": 1,
	}
	for accepted in ["assets/fonts/Face.ttf", "assets/Face.otf"]:
		var data := base.duplicate()
		data["ui_font"] = accepted
		var errors: Array[String] = []
		var manifest = ManifestScript.parse(data, "manifest.json", errors)
		_check(
			"accepts %s" % accepted,
			manifest != null and manifest.ui_font == accepted,
			", ".join(errors)
		)
	for refused in [
		"../../etc/Face.ttf",
		"assets/../../Face.ttf",
		"/abs/Face.ttf",
		"fonts/Face.ttf",
		"assets/Face.png",
	]:
		var data := base.duplicate()
		data["ui_font"] = refused
		var errors: Array[String] = []
		var manifest = ManifestScript.parse(data, "manifest.json", errors)
		_check("refuses %s" % refused, manifest == null, "accepted it")
	var absent := base.duplicate()
	var absent_errors: Array[String] = []
	var no_font = ManifestScript.parse(absent, "manifest.json", absent_errors)
	_check(
		"a manifest with no ui_font is still valid and means the engine face",
		no_font != null and no_font.ui_font.is_empty(),
		", ".join(absent_errors)
	)
