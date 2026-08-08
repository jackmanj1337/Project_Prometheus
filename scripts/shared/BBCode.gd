class_name BBCode
extends RefCounted
# Escaping helpers for text that reaches a RichTextLabel with `bbcode_enabled`.
#
# Why this exists: pack-authored strings (weapon/class/skill display names, unit
# names) are interpolated into BBCode markup in the details and preview screens.
# Campaign packs are imported from player-supplied ZIPs, so those strings are
# untrusted input crossing into a markup parser.
#
# This is not cosmetic. `[img]` resolves through `ResourceLoader.load()`, and a
# `.tres` can carry an embedded script whose `_init()` runs on load — so an
# unescaped `[` is an arbitrary-code-execution primitive, not just broken
# formatting. `CampaignArchivePreflight` currently denies the second half of that
# chain by refusing to extract `.tres`/`.res`/`.tscn` from a pack; escaping here
# closes the first half so neither control is load-bearing alone.
#
# Godot 4.6 has no `String.bbcode_escape()` — the method exists upstream but is
# not in this engine version (verified: it is a parse error), so the manual
# bracket swap below is the only option. Revisit on the next engine bump.


# Escapes body text so a bbcode_enabled RichTextLabel renders it literally.
#
# Only `[` needs escaping: BBCode tags open with `[`, so an unmatched `]` is
# already rendered as a literal character. `[lb]` is Godot's documented escape
# for a literal left bracket.
static func escape(text: String) -> String:
	return text.replace("[", "[lb]")


# Escapes a value that goes INSIDE a tag's attribute, e.g. the `id` part of
# `[url=id]label[/url]`.
#
# `escape()` is wrong here: `[lb]` is itself markup and is not expanded inside a
# tag's attribute, and — more importantly — the dangerous character in an
# attribute is `]`, which closes the tag early and hands the remainder of the
# string to the parser as markup. There is no escape sequence for that, so the
# brackets are removed instead.
#
# Well-formed ids contain neither bracket, so this is a no-op in practice and a
# breakout guard in the hostile case. A mangled id simply fails its lookup:
# `_on_entry_clicked` already logs-and-ignores metas it does not recognise.
static func escape_meta(text: String) -> String:
	return text.replace("[", "").replace("]", "")
