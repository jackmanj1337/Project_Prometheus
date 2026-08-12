# Session Note - 2026-08-12

## Branch context

- Branch: `agent/integration` (the docs line)
- Base branch: `agent/integration`
- Base SHA: `82819f5ac422ec5395e20116e4f05c3965e14e47`
- Coordination Work ID: `SHOP-TRANSACTION-WIREFRAMES-2026-08-12`

## What was done

Drew the shop transaction surface as a responsive wireframe album — nine lifecycle states
across ten viewports, 113 frames — and recorded two composition rulings plus five findings.

The album consumes the ratified vocabulary (`TSV-1..9`, `EPUX-13..17`, `UUI-1..19`) rather
than reopening it. `UUI-15` had held shop wireframes pending an owner session and
`TSV-10..24` are still open; the owner ruled four of those in session to unblock the drawing
(quantity stepper scope, fixed destination with silent overflow, the viewport set, and
drawing Compact in both occlusion states). Frames drawn against a mere register
recommendation are marked as such in the album.

Frames are real HTML at true logical pixels against `ResponsiveLayout.DENSITY_TOKENS`, and
every number quoted in a caption is measured from the rendered layout after mount, not
estimated. That matters: the first pass quoted hand-estimated extents that were close but
wrong, and this album's whole value is that its measurements can be trusted.

**Two compositions were ruled while drawing.**

1. *Single-scroll at every size class.* The first cut docked the action and status bars to
   the bottom of the pane while content clipped above them, which inverts `TSV-6` — the
   action was reachable before its own cost was readable. The complex-item stress case then
   showed the cost on desktop: at 1024×768 and 1280×720 the pane clipped after Weapon
   triangle, leaving the price, the consequences and both warnings — including "cannot be
   sold, permanent for the campaign" — below the fold while the Buy button stayed on screen.
   Nothing docks now, at any size class; consequence-before-action is structural.
2. *Expanded is character sheet / list / detail with category tabs on top.* Categories were
   promoted from chips to a tab strip, and the left column now carries a compact character
   sheet that includes the equipped-weapon comparison for the current selection. Medium
   keeps chips: `UUI-19` already measured that the 524-px landscape rect cannot hold a
   second strip.

**Findings.** Five, all visible in frames: the docked-action inversion (resolved above); the
blocked state putting its shortfall two thirds down the column; 852×393 being the tightest
transaction surface in the set at 240 px of detail pane — the same 524 px `UUI-19` hit; 4K at
1.0 content scale being correct and unreadable at once; and the complex item retiring the
docked action everywhere.

**Header condensation.** Measured that chrome is a fixed 190 px at every touch viewport —
54% of the game view at the 360×640 floor, 48% at 852×393 — and does not adapt. Wrote
`[SHC-1..8]` as options for an owner walk. The structural observation is that size class is
derived from width alone while this problem is vertical: 852×393 is classed Medium and gets
Medium's composition despite a worse vertical budget than the Compact floor, which is why
the landscape recommendation is to turn the chrome 90° into a rail rather than shrink it.

## Commits

Ownership is recorded in `AGENT/Session Notes/CLAIMS.tsv`.

Landed on the docs line rather than a feature branch. `agent/from-integration/shop-transaction-wireframes`
was started first, but the docs-guard hook correctly refused the role-manifest edit on a
feature branch, and that entry cannot land separately because ownership-map rows must point
at files that exist. The change is documentation and design evidence only — no GDScript — so
the whole set belongs on `agent/integration`. The empty feature branch was abandoned.

Two docs and the album source landed together: the wireframe research doc, the `SHC`
options register, the self-contained album HTML, and nine per-state contact sheets with the
Playwright generator that produces them. Both new design sources are registered in the role
manifest's Active Source Ownership Map — they span the shop, convoy and responsive-UI tracks,
so a direct Feature Index link would sit under three rows at once.

## Gates

- `python3 AGENT/Docs/gen_docs_index.py` — regenerated, committed in the same change.
- `python3 AGENT/Docs/check_docs.py` — PASS, all 43 checks green.
- `node AGENT/Docs/design/shop_wireframes/render_sheets.mjs` — wrote 9 sheets, no page errors.
- `bash run_tests.sh` (fast suite, run by `agent-commit.sh`) — PASS, all suites green.

Two doc-system gotchas worth carrying. `Type: design research` is **not** in the
`gen_docs_index.py` taxonomy, so a doc using it is silently dropped from `INDEX.md` while
`check_docs.py` still passes — use `Type: design`. The sibling 2026-08-12 research packets on
`agent/from-integration/responsive-prep-deployment-research` use the invalid value and will
carry the same silent gap when they land. Second, an options register belongs in
`AGENT/Docs/registers/` with `Type: register`; that is what puts it in `REGISTERS.md` where an
owner walk can find it.

## Next

Walk `SHC-1..8`, then redraw the affected Compact and landscape frames so the projected
savings in the recommended package become measured. The cheapest first cut is `SHC-1(B)` plus
`SHC-2(B)` — two layout edits, no ruling reopened, 77 px returned, 2.9 → 4.3 rows at the
floor.

Still open and untouched by this session: `TSV-10..24` and `SHP-1..5`, so every price in the
album is illustrative.
