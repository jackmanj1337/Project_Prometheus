# Session Note - 2026-08-12

## Branch context

- Branch: `agent/integration` (docs line — the docs-guard hook refuses plan docs on a feature branch)
- Base branch: `agent/integration`
- Base SHA: `116eaff76e56dc34f51694783d3d34668b76e7af`
- Coordination Work ID: `UNIFIED-UI-PROGRAMME-2026-08-12`

## What was done

Owner walk over the whole UI surface, then the first deliverables built against its answers.

**The search.** Swept `coordination/tasks.json`, `AGENT/Docs/` and the built scenes for
everything with significant UI impact: **54 open UI-affecting tracker rows** against **23
built UI scenes**. Four workstreams were already consolidated in
`responsive_ui_programme_2026-08-06.md`; four more were not — pack-authorable theming, the
shared record-screen epic (`UIREC-V1-S01..S06`), the unratified display-layers discussion,
and the campaign editor UI.

**The walk.** Seventeen decisions ratified as `UUI-1..17`. The load-bearing ones:

- **Landscape game view** = preset list with **4:3 default**, replacing the full-bleed
  `{x:0,y:0,w:1,h:1}` that reserves no dead space and makes both shipped landscape presets
  overlays. Landscape controls = two side columns.
- **Portrait band** = player-adjustable, **55% default**, fixing the measured 26%.
- **Menu Scale multiplies the density tokens** and stops writing Themes. This retires
  `MenuScale._scaled_theme()` and `_SCALED_CONSTANTS`, which today overwrite five container
  constants with `roundi(engine_default * factor)` — so an authored `separation = 10`
  silently becomes `4`. It also fixes the cramped-padding defect, where Menu Scale 2.0×
  doubles the type inside an unchanged 14px panel margin on the seven themed scenes.
  `MainMenu.gd:69`'s unilateral opt-out becomes the general rule.
- **`content_margin_*` derived from tokens**; a pack authors **paint + font face only**.
- **Theme boundary is the pack selection point** (owner): everything reachable after
  selecting a pack follows the pack's theme, **including Settings**; Main Menu, Campaign
  Library, pack management and the campaign editor use built-in chrome themes. Several
  themes ship (plain light, plain dark, fantasy parchment, pixelated retro sci-fi) and are
  also published through the Pack 0 repo, where authors may copy them into their own packs.
- **Unbuilt screens are held** for research sessions before any wireframe is drawn.

**The deliverables.** A 4-screen × 6-viewport wireframe proof set (Main Menu, Campaign
Library, Settings, map HUD), the unified programme plan, the `UBS-1..9` research agenda, and
25 standalone SVG frames extracted from the album so the two cannot drift.

## Commits

Ownership is in `AGENT/Session Notes/CLAIMS.tsv`.

`c4a073e5` carries the whole deliverable. It landed on `agent/integration` rather than the
`agent/from-integration/unified-ui-programme` branch it was started on: the docs-guard
pre-commit hook refuses plan docs on a feature branch, correctly, because a plan on an
unmerged branch is invisible to anyone not standing on it. The feature branch was created
and then abandoned with zero commits.

`AGENT/Docs/plans/doc_role_manifest_2026-06-29.md` gained an ownership-map row for the new
plan — check `[30] active-doc-ownership` requires plans and design docs to have either a
direct Control Plane / Feature Index link or a manifest entry, and a cross-cutting
sequencing view belongs in the manifest rather than adding noise to a navigation table.

## Gates

- `bash run_tests.sh` — **PASS, all suites green** (run twice: once by `agent-commit.sh`,
  once by `agent-push.sh`). Receipts at
  `audit/check-receipts/Project_Prometheus-{fast,full}.json`, tree `a4648f92`.
- `python3 AGENT/Docs/check_docs.py` — **PASS, all 43 checks green.**
- `python3 AGENT/Docs/gen_docs_index.py` — regenerated, committed in the same change.
- SVG wellformedness — 25/25 parse as XML. First extraction produced 25/25 malformed
  because HTML named entities (`&middot;`, `&times;`, `&mdash;`) are not defined in XML;
  the extractor now rewrites them to numeric character references.

## Two findings raised

1. **The published Compact row budget is optimistic by half a row.**
   `responsive_ui_redesign_2026-08-06.md` spends header 56 + footer 56 for 240px of content
   and 4.3 rows, but `ResponsiveLayout.DENSITY_TOKENS` publishes header 72 / footer 64,
   giving 216px and **3.9 rows**. The album is drawn against the token values. The doc and
   the code disagree and one needs correcting.
2. **No localization or i18n row exists anywhere in the tracker.** Fonts are pack-swappable
   and every layout must survive ~1.3× text extent — the constraint a translation imposes —
   but nothing owns it and no size-class decision was taken with it in mind.

## Addendum — UUI-18 and UUI-19 (same session, owner review of the proof set)

Two additions on reviewing the album, both about Settings.

**UUI-18 — confirm-or-revert keyed on reachability risk.** `DisplayConfirmDialog.gd` already
implements the 15s apply-then-confirm-or-revert correctly; the defect is its *reach*.
`confirm: true` is set on exactly two schema rows, `window_mode` (`SettingsScreen.gd:153`)
and `resolution` (`:162`). The setting that can strand a player most completely —
**Control Style = Off on a touch-only device** — is in Controls, so no display-scoped rule
would ever catch it. The trigger becomes a `reachability_risk` property covering eight
settings, including `content_scale_factor`, which re-classes the very screen the control
sits on.

Two things fall out that were not obvious until the frame was drawn. The dialog must be
**exempt from the setting it is confirming**, or Viewport Scale 4.0 renders its own escape
hatch unreadable and Menu Mode = controller drops `min_target` to 0 underneath it. And
`SettingsScreen._ready()` currently reuses `confirm: true` to decide which rows to hide
where `is_display_config_supported()` is false — two concerns sharing one flag, which have
to be separated because a reachability-risk row is not automatically display-dependent.

**UUI-19 — Settings paged by section, tabs on wide screens.** Six sections become six pages;
Compact shows a section index then the section page, Medium and Expanded show a tab strip.
This is the real answer to the row budget on the worst screen in the programme: 25+ rows
against 3.9 visible was six screens of scrolling. Consequence worth recording — **Settings
is therefore not a UIREC list/detail record screen**, it is a tabbed pager, a third
composition alongside the record screens and the free-position HUD, and it needs its own
`[tab]` role.

Measured while drawing: six tabs do **not** fit 524 logical px — "Accessibility" alone needs
roughly 105 at the 16px body token — so the strip scrolls at Medium and only fits outright
at Expanded.

Album regrown 24 → 26 frames; Settings carries eight. `check_docs.py` green, SVGs 27/27
wellformed. Commit `8ddfbde5`.

## Next

Owner reviews the proof set. On acceptance, the remaining nineteen built screens are drawn
to the same conventions. Independently unblocked and needing no acceptance: programme phase
0 — the `SettingsScreen` slider/scrollbar paint fix (8 `HSlider` nodes rendering
engine-default grey inside 9-slice panels on a screen players see today), publishing the
role list into the interaction vocabulary, and adding the `dense` token column.

Blocker unchanged: `V07X-ACCEPTANCE-GATE-2026-08-11` still gates the v0.8.0 window, and one
Windows session still gates the Settings conversion, persisted Menu Mode/density, and the
text-entry vocabulary change.
