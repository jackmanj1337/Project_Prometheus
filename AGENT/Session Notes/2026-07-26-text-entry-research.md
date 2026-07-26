# Session Note - 2026-07-26-text-entry-research

## What was done

Research + owner-questions pass for `RESEARCH-TEXT-ENTRY-STRATEGY-2026-07-26`, filed as
`AGENT/Docs/design/text_entry_strategy_research_and_questions_2026-07-26.md` in the same
shape as the campaign-library and prep/economy packets: sourced comparative evidence, then
a stable-ID question list (`TEXT-01`..`TEXT-08`) with a recommendation per question.

**The row's first-thing-to-check is answered, and the answer is no.** It asked whether
Godot's built-in virtual-keyboard support might be adequate and shrink the question set to
a settings policy. It is not: `DisplayServer`'s virtual keyboard is implemented on Android,
iOS, and Web only, and the desktop display servers reject the call with "Virtual keyboard
not supported by this display server". Our only shipping target is Windows Desktop and the
Steam Deck is desktop Linux, so on both `LineEdit.virtual_keyboard_enabled` — which
defaults to `true` — does nothing. The web path exists but is experimental and has two open
upstream bugs, one of which (no support inside `SubViewport`) matters for the web build.

Findings that drove the recommendations:

- **Steam Deck Verified *requires* an automatic on-screen keyboard for text input.** That
  is a certification gate, and Valve's own OSK satisfies it via GodotSteam
  (`showFloatingGamepadTextInput` / `showGamepadTextInput`). Cheapest compliant answer for
  the Deck is Valve's keyboard, not ours.
- **Fire Emblem's real lesson is scarcity, not layout.** The series' entire free-text
  surface is the avatar name — ~8 characters in practice in Awakening (12 absolute,
  variable-width font), 8 in Three Houses, same shape in Engage. Fates replaced text with a
  graph/slider system. Awakening word-filters the name only because StreetPass transmits
  it. On Switch it uses the system keyboard rather than building one.
- **A daisywheel is ~2 input actions per character; a grid QWERTY is up to ~12.** Every
  off-the-shelf Godot addon implements the slow one.
- **Four open-source Godot keyboards surveyed; none is a safe dependency.** The only
  Godot 4 + permissive + controller option (greenpixels) is 11 commits with no releases;
  the only daisywheel implementation (HauntedBees) is Godot 3.4 under **AGPL-3.0 with a
  bespoke commercial clause** that should not be accepted here — read the pattern, do not
  vendor the code; the most popular (martinfuchs) does not mention controller support and
  states no engine version; the fourth is a 2-commit stub.

Recommendation is to split this into three deliverables and not build a keyboard first:
hold the line on minimising text entry, adopt the Steam OSK when a Steam build is
scheduled, and only then build our own keyboard — daisywheel-first, with a data-driven
JSON layout registry per the open-registry principle `[EXT]`.

Unresolved items are listed explicitly in the packet rather than papered over: whether a
*custom* keyboard alone passes Deck Verified is not settled by the sources; two addons'
engine versions are undocumented; and the GodotSteam docs page returned HTTP 403 to
automated retrieval, so its exact signatures should be read directly before implementation.

## Commits claimed

- `7940ecb25ef3a66f73cfa04025f922df57bf062c` — Add text-entry strategy research and TEXT-01..08 owner questions

## Gates

- `python3 AGENT/Docs/gen_docs_index.py` — regenerated `INDEX.md` / `REGISTERS.md`.
- `python3 AGENT/Docs/check_docs.py` — **PASS: all documentation checks green** (41 checks).
  It first failed `[active-doc-ownership]`; fixed by registering the packet in the Active
  Source Ownership Map in `AGENT/Docs/plans/doc_role_manifest_2026-06-29.md`, which is the
  intended mechanism rather than a workaround.
- `check_gdscript_style` — PASS, 238 tracked GDScript files (no code changed).
- Godot test suite skipped by the hook: docs-only change.

## Next

Owner walk of `TEXT-01`..`TEXT-08`, branch by branch, in the same style as the EPUX walk.
`TEXT-06` (ratify a rule that no v1 feature requires free text) and `TEXT-01` (the v1
capability) are the two that gate the rest. Nothing in v1 waits on any of it — every
dependent feature (`EPUX-09` drag/drop, `EPUX-15` free-text search, `EPUX-27` forge alias)
was already cut — so this unblocks future work rather than current work.
