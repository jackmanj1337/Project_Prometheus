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

## Walked the same session — SHC-1..8 and CUR-1..7

`SHC-1..8` were walked on 2026-08-13. Seven took the recommendation: the subject folds into
the app bar with the **node name** giving way; tabs and filters merge to one row with a
segmented mode control leading; the Explore node supplies both landing facet and landing tab;
landscape chrome turns 90 degrees into a vertical rail; the app bar collapses on scroll as a
supplement only; and affordability rides `TSV-13`'s disabled-with-reason rows.

**`SHC-6` was held mid-walk because its premise was wrong.** All three options assumed one
wallet holding one universally accepted currency. The engine never assumed that:
`resource_types` is a required open-registry family, `CostSpec` carries `resource_id` *and*
`scope` per cost, `quote()` takes an array of costs, `ResourceTransaction.wallets_touched` is
plural, `SaveData` already migrated `party_gold` into a resource map, and `[SHP-1b]` ruled
prices resource-keyed in June with an explicit instruction not to enumerate the currency set.
**Only `MapMenu.gd:75` assumes gold** — the inverted-dependency anti-pattern again, a generic
engine capability narrowed by the surface presenting it.

That produced `CUR-1..7`, walked and ruled the same day. The shop declares a **primary
currency**; the header shows it as a **button** opening the full holdings; the accepted set
stays **derived** from the stock's costs, making the authored primary a display designation
that must be validated against the derived set and defaulted when unset. Rows lead with the
primary and show two terms before overflowing. Shortfalls name the largest **relative to what
is held**. No exchange feature: `CostSpec` credits on negative amounts, so a money-changer is
an ordinary shop whose offers spend one resource and credit another.

**Two owner corrections followed**, both recorded against the original rulings rather than
silently replacing them. The holdings popup lists **everything spendable, inventory
included** — `kind == "wallet"` survives as the grouping predicate, not an exclusion filter —
which closed a gap the wallet-only version had opened. And the bar figure is **abbreviated**
with the full count in the popup, flipping `SHC-6` from A to B: the argument against
abbreviation was that rounding misleads where the decision is hardest, which was true only
while there was nowhere else to look. `CUR-1` built that place.

## Redraw — the projections were exact

The album was rebuilt against all fifteen rulings and re-measured. Chrome at the design floor
fell **190 to 111 px**, the list grew **161 to 241 px**, and the row budget went **2.9 to
4.3**. Landscape went **3.6 to 7.0**. Both projections landed exactly. Two new states were
added: a two-currency shop (Ember Forge) and the holdings popup. 113 to **137 frames**.

Two things were recorded honestly rather than quietly dropped. **`SHC-3`'s entry facet does
not delete the control row** — the facets stay reachable inside the shop, so the projected
5.0-row figure was wrong. And **`SHC-4` moved the landscape constraint rather than removing
it**: a detail pane in the 524-px rect is now 210 px, narrower than the 240 px it had before.
Height was bought with width, and 524 px has now defeated three independent surfaces.

## Album sources recovered into the repo

**Four UI albums existed only as published Artifact URLs**, including the proof set that
`unified_ui_decisions_2026-08-12.md` cites as its specification. A published page can be
edited or deleted independently of this repo, so the drawings the UI is built against were
one deletion from being unrecoverable.

All four were recovered to `AGENT/Docs/wireframes/albums/`, the publish-time skeleton and
injected frame runtime stripped, and each **verified to render standalone** in Chromium with
no page errors — 35 inline SVG frames in the proof set, 17 plus three embedded base64
web-export captures in the research album, both themes intact. The shop album was
consolidated into the same directory so there is one home rather than a copy that drifts.

Three caveats are recorded in `albums/README.md` and worth repeating here:

1. They are **body fragments**, because the Artifact service supplies the
   `<html><head><body>` skeleton at publish time. The README carries the wrapper needed to
   open one locally.
2. They are **drawings, not a component library**. HTML because it draws responsive layouts
   quickly and measurably; the UI itself is Godot scenes. Where an album and
   `ResponsiveLayout.DENSITY_TOKENS` disagree, the engine wins and the album is stale.
3. The published URLs are convenience copies and **do not sync**. Editing a file here means
   republishing if the URL should match.

## Next

Continue the owner-question queue. Ready for a walk, in the order the unbuilt-screen agenda
sets: the **convoy/shop presentation packet** now that `TSV` and `CUR` are settled (convoy
precedes shop), then `L10N-1..18` and `CRD-1..10`, which are independent and need no
predecessor. `CEUI-1..40` is ready except its search-specific rows, which wait on
`NMTE-1..20`. `SKF-1..12` and `DRC-1..33` are written and unwalked.

Build work this album unblocks, none of it started: the composition selector needs a
**landscape predicate** — `SHC-4` is the first deliberate override of the width-derived size
class by a height rule, and faking it with a width threshold would repeat what `UUI-11` added
the `dense` column to avoid. The Explore node needs its **generated submenu** (`SHC-3` and
`SHC-8` both write to it). `MapMenu.gd:75` becomes a resource-list renderer reading
`label_key` off the registry entry — that one call site is the whole of the gold assumption.
And abbreviation must be **opt-in per call site**, since the price breakdown, consequence
preview and shortfall all have to stay exact.

Still open and untouched: `TSV-10..24` beyond the four ruled in session, and `SHP-1..5`, so
every price in the album remains illustrative.
