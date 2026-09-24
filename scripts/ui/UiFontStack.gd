class_name UiFontStack extends RefCounted
# The player-facing face, and the one place that decides which font is drawing.
# `UI-FONT-MISSING-EM-DASH-GLYPH-2026-09-22`.
#
# TWO RULES, AND THE SECOND IS THE ONE THAT KEEPS BEING FORGOTTEN.
#
#   1. The ACTIVE PACK's face wins while that pack is active. `[ICO-1..6]` loads one pack
#      at a time, so there is exactly one answer to "whose font is this" and no precedence
#      question to invent.
#   2. THE FALLBACK IS ALWAYS BEHIND IT. A pack that ships a pixel face has the same
#      ASCII-only gap the engine's own kit had, and without this it would re-introduce the
#      missing-glyph boxes for every author who styles their campaign. An author chooses
#      the letters; they do not get to choose whether the em dash renders.
#
# WHY IT MUTATES SHARED THEMES. The themed UI scenes name `manasoul_ui.tres` through an
# `ext_resource`, so they hold ONE Theme instance and writing `default_font` on it reaches
# all of them at once. The alternative -- walking the tree re-theming controls -- would
# have to run again for every scene instantiated afterwards, which is a rule that decays
# silently the first time someone adds a screen.
#
# NOT EVERY SCENE IS THEMED, and two more writes cover what the shared theme cannot
# (PACK-FONT-MISSES-MENUSCALE-SCREENS-2026-09-24, found by the v0.8.3 walk):
#   - The HUD, the Map Menu and Prep name no theme and draw Godot's default theme's face.
#     A pack's face is written there too while the pack is active, and the ORIGINAL face
#     is put back on deactivation, so with no pack active those screens are unchanged.
#   - `MenuScale` hands scaled screens a COPY of the shared theme, and the copy kept the
#     face it was copied with. `MenuScale.sync_fonts()` re-reads it after every change.
#
# DEACTIVATION IS NOT OPTIONAL. `apply()` with an empty path restores the engine face, and
# `DataManager._commit_session` calls this on EVERY activation rather than only when a
# pack declares a font -- otherwise the previous pack's face would outlive its content and
# the main menu would keep a campaign's typography after the campaign was gone.

## The engine's own face: the pixel kit with the glyph-coverage fallback already behind it.
## Authored as a resource rather than assembled here so that the theme, an author reading
## the theme, and this object all name the same thing.
const ENGINE_FONT_PATH := "res://assets/fonts/ui_font.tres"

## The face consulted for codepoints the primary face does not carry. Named separately from
## `ENGINE_FONT_PATH` because a PACK font needs the same fallback behind it and must not
## inherit the engine's pixel kit as a second face -- the pack chose its letters.
const FALLBACK_FONT_PATH := "res://assets/fonts/DejaVuSans.ttf"

const THEME_PATH := "res://assets/themes/manasoul_ui.tres"

const MenuScaleScript := preload("res://scripts/ui/MenuScale.gd")

## Godot's own default-theme face, captured the first time a pack face replaces it so
## deactivation restores exactly that and not the engine's pixel kit: unthemed screens
## have never drawn the pixel kit, and a pack leaving should not start them doing so.
static var _godot_default_font: Font = null

## The face currently drawing, as the path `apply()` was given -- empty for the engine's
## own. Kept because the theme cannot answer it: a pack face is built at runtime and has no
## `resource_path`, so "which pack's letters are on screen" is otherwise unobservable, by a
## test or by a diagnostics bundle.
static var _active_path := ""

## The `AssetResolver` group this registers to reach `HANDLER_FONT`. A pack's face is not a
## catalogued asset id -- it belongs to the pack as a whole rather than to any record -- so
## it resolves through the path escape hatch, which is still contained by
## `_safe_relative_path`.
const ASSET_GROUP := "ui_font"


## Applies the face a pack declared, or restores the engine face when no path is given.
## Returns true when the theme now draws what was asked for.
##
## TAKES A ROOT AND A PACK-RELATIVE PATH, not one absolute path, because that is what
## `AssetResolver` is shaped to take -- and going through it is not optional here. Check 32
## (`campaign-asset-boundary`, `B6-CAMPAIGN-SHARING` DoD#2) rejects any `load_dynamic_font`
## outside the resolver, and it is right to: the resolver is the one place that refuses a
## path escaping its pack, records a structured repair-report entry for a face that would
## not load, and knows what a Tier-1 media format is. A face loaded past it would be the
## only pack media in the engine with none of that.
##
## A path that cannot be resolved restores the ENGINE face rather than leaving the previous
## pack's: a pack whose font went missing between validation and activation should look
## like the engine, never like whoever was active before it.
static func apply(pack_root: String = "", relative_path: String = "") -> bool:
	var theme := _theme()
	if theme == null:
		return false
	if pack_root.is_empty() or relative_path.is_empty():
		_set_face(theme, _engine_font(), "")
		return theme.default_font != null
	var pack_font := _load_pack_font(pack_root, relative_path)
	if pack_font == null:
		_set_face(theme, _engine_font(), "")
		return false
	_set_face(theme, pack_font, pack_root.path_join(relative_path))
	return true


## Writes the face everywhere a screen can read it from: the shared theme, Godot's default
## theme while a pack is active, and every copy `MenuScale` has made of the shared theme.
static func _set_face(theme: Theme, font: Font, active_path: String) -> void:
	theme.default_font = font
	_active_path = active_path
	var godot_theme := ThemeDB.get_default_theme()
	if active_path.is_empty():
		if _godot_default_font != null:
			godot_theme.default_font = _godot_default_font
	else:
		if _godot_default_font == null:
			_godot_default_font = godot_theme.default_font
		godot_theme.default_font = font
	MenuScaleScript.sync_fonts()


## Godot's own default face, whatever pack is active. For a surface that must never take a
## pack's letters -- the campaign editor's chrome (`EW-8`) -- and so pins it explicitly now
## that an active pack's face is also written to Godot's default theme.
static func godot_face() -> Font:
	if _godot_default_font != null:
		return _godot_default_font
	return ThemeDB.get_default_theme().default_font


## The path of the face currently drawing, or empty for the engine's own.
static func active_font_path() -> String:
	return _active_path


## The pack's face with the coverage fallback behind it. A `FontVariation` wrapper rather
## than the resolved `FontFile` itself because that resource is cached and shared: writing
## `fallbacks` onto it would mutate a font the installer and exporter also hold.
##
## `AssetResolver` already declines a missing file and a path that escapes the pack. The
## extra guard is for what it cannot see: `FontFile.load_dynamic_font` RETURNS OK for a file
## that exists but is not a font, and hands back a face with no glyphs in it. Installing one
## would blank every string on every screen while the engine face sat there unused, so a
## font that cannot draw a capital A is refused whatever the loader said.
static func _load_pack_font(pack_root: String, relative_path: String) -> Font:
	var resolver := AssetResolver.new(pack_root)
	resolver.register_group(ASSET_GROUP, AssetResolver.HANDLER_FONT)
	var resolved := resolver.resolve(ASSET_GROUP, relative_path)
	var file := resolved as FontFile
	if file == null or not file.has_char(65):
		return null
	var variation := FontVariation.new()
	variation.base_font = file
	var fallback := _fallback_font()
	if fallback != null:
		variation.fallbacks = [fallback] as Array[Font]
	return variation


static func _theme() -> Theme:
	return load(THEME_PATH) as Theme


static func _engine_font() -> Font:
	return load(ENGINE_FONT_PATH) as Font


static func _fallback_font() -> Font:
	return load(FALLBACK_FONT_PATH) as Font
