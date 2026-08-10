# Session Note - 2026-08-10-23-04-00Z-ui-theming-alignment-agenda

## Branch context

- Branch: `agent/from-integration/ui-theming-alignment-agenda`
- Base branch: `agent/integration`
- Base SHA: `2418fb92`
- Coordination Work ID: `SESSION-UI-THEMING-ALIGNMENT-2026-08-10`

## What was done

Documentation only. The bulk of this session ran in the container repo, walking the five
open questions carried forward from `2026-08-10-20-53-25Z` there; its note
(`2026-08-10-22-56-27Z-five-open-questions-walked-and-theming-agenda`, container
`agent/staging-area`) is the fuller record. **This note exists so the agenda is not
invisible to a session that starts here** — the exact failure mode the tracker rule warns
about.

Added `AGENT/Docs/registers/ui_theming_alignment_open_questions_2026-08-10.md`, turning
`SESSION-UI-THEMING-ALIGNMENT-2026-08-10`'s eight decisions (T1–T8) into register
`[UITH-1..8]` with measured evidence and a recommendation per item, plus the regenerated
`INDEX.md` / `REGISTERS.md`.

**Reading the code changed the question.** The row was written as "align theming with the
in-flight redesigns." What is actually true is that **three systems already write the same
properties and do not know about each other**: `ResponsiveLayout.DENSITY_TOKENS` (per-node
overrides in logical px), `MenuScale._scaled_theme()` (a derived duplicate Theme), and
`manasoul_ui.tres` StyleBox `content_margin_*` (baked into the paint resources).

Read from source, not assumed:

- `ResponsiveLayout.gd:80` **already legislates T1** — "No scene may carry a hard-coded
  pixel value; it reads a token from here" — and the other two systems both violate it.
- `MainMenu.gd:69` implements `apply_menu_scale(_factor)` and **ignores the factor**,
  calling `_apply_responsive_tokens()` instead, because applying both "would multiply the
  two density authorities" (`:81-83`). One screen has escaped; no general rule replaced it.
- `MenuScale._scaled_theme()` duplicates the authored base Theme — correct, that is the
  V030-BUG-01 fix — then overwrites the five `_SCALED_CONSTANTS` with
  `roundi(ENGINE_DEFAULT * factor)`, **not** the authored value. Any pack-authored
  container constant is silently discarded. That is T4's constraint made concrete.

**Probable second live defect, not yet confirmed by render:** MenuScale scales
`default_font_size` but never StyleBox `content_margin_*`, so on the seven scenes importing
`manasoul_ui.tres` a raised Menu Scale should put double-size type inside unchanged 14 px /
12×7 padding. One 200% screenshot from the existing album settles it. Same blind spot as
the known `SettingsScreen` slider split — the 133-shot album passes 133/133 and no current
or proposed pixel check can see either.

**Tracker correction:** the row claimed the V080 branch built "a `ResponsiveLayout` class
plus density tokens." It did not. `ResponsiveLayout.gd` is an autoload **already on
`agent/integration`**; `agent/from-integration/v080-responsive-main-menu` is 2 commits over
5 files, adds no new class, and only *consumes* it from `MainMenu.gd`. No held-back
infrastructure blocks the theming session, and T8 is smaller than it looked.

**Flagged, deliberately not edited:**
`AGENT/Docs/design/ui_ux_architecture_research_and_questions_2026-07-24.md` still states
under `UI-TOOL-01` that the web test bridge "must … stay absent from production exports."
That was superseded on 2026-08-10, when the owner decided the bridge **ships** in public
web builds, gated and read-only. Left in place because that doc is an accepted record of a
2026-07-24 decision; `[UITH-7]`'s session should choose whether to annotate it in place.

Counts re-verified this session (the row's originals were accurate): 7 of 21
`scenes/ui/*.tscn` import the theme, which defines four types only; `SettingsScreen.tscn`
imports it and holds 8 `HSlider` nodes; unthemed are 94 `Label`, 27 `RichTextLabel`, 11
`ScrollContainer`, 8 `HSlider`, 7 `HSeparator`, 0 `LineEdit`; `theme_type_variation` has
zero uses.

## Commits

Two commits, `06dbf504` and `1dc2d79a`: the register plus its regenerated indices, then
the `CLAIMS.tsv` row. Both pushed. Ownership is in `AGENT/Session Notes/CLAIMS.tsv`.

## Gates

- `python3 AGENT/Docs/gen_docs_index.py` — regenerated and committed in the same change.
- `python3 AGENT/Docs/check_docs.py` — PASS, all 43 checks.
- Full pre-commit battery green (RNG guard, analyzer tests 12/12, scene integrity,
  session claims, evidence matrices, GDScript style over 314 files).
- `bash scripts/session_closeout.sh` — green.
- **No Godot test evidence:** the pre-commit hook skipped the suite as a docs-only change.
  Correct for this content, but stated rather than left to inference.

## Next

**Hold the owner session and walk `[UITH-1..8]`** from the new register. It is prepared to
be reacted to, not derived — every item carries a recommendation. `[UITH-2]` (does theming
ride `EPIC-SHARED-RECORD-UI-V1` or precede it) gates the rest of the sequencing.
`[UITH-7]`'s theme-provenance field should be folded into
`BRIDGE-SNAPSHOT-STALENESS-2026-08-10`'s lockstep `VERSION` bump before that row is built,
since it does not depend on the role list and is the only proposed check that would have
caught the 7-of-21 split.

Blocker unchanged: the v0.7.3 native Windows return preempts this and everything else.
