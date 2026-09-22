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
# WHY IT MUTATES A SHARED `Theme`. Every UI scene names `manasoul_ui.tres` through an
# `ext_resource`, so they hold ONE Theme instance and writing `default_font` on it reaches
# all of them at once. The alternative -- walking the tree re-theming controls -- would
# have to run again for every scene instantiated afterwards, which is a rule that decays
# silently the first time someone adds a screen.
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
		theme.default_font = _engine_font()
		_active_path = ""
		return theme.default_font != null
	var pack_font := _load_pack_font(pack_root, relative_path)
	if pack_font == null:
		theme.default_font = _engine_font()
		_active_path = ""
		return false
	theme.default_font = pack_font
	_active_path = pack_root.path_join(relative_path)
	return true


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
