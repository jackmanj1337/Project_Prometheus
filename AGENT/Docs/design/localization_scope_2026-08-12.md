---
Role: dated
Type: design
Status: Research recorded; owner questions open
Last verified: 2026-08-12
Tracker: LOCALIZATION-I18N-SCOPE-2026-08-12
---

# Localization Scope — Comparative and Technical Research

## Decision boundary

This packet decides whether localization is a v1 capability, a post-v1 seam, or explicitly
out of scope. It does not select target languages or commission translations. The decision
must precede responsive conversion because text expansion, bidirectional layout, font
coverage and pack-authored strings alter the component contract.

## Platform findings

Godot already provides `TranslationServer`, runtime locale changes, resource remaps,
pseudolocalization, bidirectional text and UI mirroring. Its documentation recommends an
automatic OS-locale default plus an in-game override. Pseudolocalization exposes expansion
and missing-glyph problems, but does not prove CJK or RTL support. Dynamic fonts accept
ordered fallbacks; system fallback is not available on Web and can be unreliable on Android,
so a shipping web build cannot treat the host font as its only CJK strategy.

Primary sources:

- [Internationalizing games](https://docs.godotengine.org/en/stable/tutorials/i18n/internationalizing_games.html)
- [Pseudolocalization](https://docs.godotengine.org/en/stable/tutorials/i18n/pseudolocalization.html)
- [Using fonts and fallbacks](https://docs.godotengine.org/en/4.5/tutorials/ui/gui_using_fonts.html)

## Prometheus-specific constraints

- Campaign packs are self-contained and exactly one is active. A pack translation cannot
  import strings or fonts from another pack.
- Pack themes may author font faces, but layout metrics remain engine-owned. Missing script
  coverage therefore needs validation or an engine fallback chain.
- The six responsive proof viewports plus FHD and 4K must survive locale changes without
  rebuilding screen state.
- IDs and registry keys are stable machine vocabulary and must never be translated.
- User-authored names and free text are content, not translation keys.

## Recommendation

Choose **v1 localization-ready infrastructure with English as the only guaranteed first-party
locale**. Ship extraction, stable message IDs, plural/format helpers, runtime locale switching,
pseudolocalization, RTL-aware components, and pack translation/font validation. Additional
human translations can arrive independently. This pays the architectural cost while the UI
is already being rebuilt without promising translation work the project cannot yet staff.

Owner decisions are `L10N-1..18` in the companion register.
