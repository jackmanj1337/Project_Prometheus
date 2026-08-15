---
Type: design
Status: Accepted as the family skeleton — [DSX-S25] 2026-08-15; compositions ruled 2026-08-12, header/currency ruled 2026-08-13
Last verified: 2026-08-12
Tracker: SHOP-TRANSACTION-WIREFRAMES-2026-08-12
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Shop — Responsive Transaction Wireframes

## What this is

Nine lifecycle states of one shop visit, drawn at ten viewports. The frames are real HTML
laid out at true logical pixels against `ResponsiveLayout.DENSITY_TOKENS`, not sketches, so
the measurements quoted in the captions are what the layout produced rather than estimates.

- Album source: [`../wireframes/albums/shop_transaction_album.html`](../wireframes/albums/shop_transaction_album.html) — self-contained,
  opens in any browser. Every frame comes from one `renderDevice(state, viewport, occlusion)`
  function, so changing a ruling redraws all 113 frames instead of editing frames by hand.
- Contact sheets: [`shop_wireframes/`](shop_wireframes/), one PNG per lifecycle state.
- Regenerate: `node AGENT/Docs/design/shop_wireframes/render_sheets.mjs`.

**Status.** These are hypotheses for discussion, not accepted UI contracts —
the same standing as the prep/deployment album. Two composition decisions were taken while
drawing and are called out below as ruled; everything else awaits an owner walk.

## Dependency position

This consumes the ratified transaction vocabulary rather than reopening it:

- `TSV-1..9` — activity checkpoint, one atomic transaction at a time, no cart or
  reservation, visit history, exit Confirm/Restore, explicit per-item action, price
  breakdown and consequence in the selected item's description.
- `EPUX-13..17` — one shop session with Buy/Sell sibling tabs, subject inherited from
  Explore, derived category filters with no free-text search in v1, final price in the list
  and full formula in the detail pane, author-defined stock cadence.
- `UUI-1..19` — size classes, density tokens, control region as the game view's leftover,
  modals bounded by the game-view rect, background bleeds while content insets, and the pack
  theme boundary (the shop is inside it, so every surface here is repainted by the pack).

`TSV-10..24` were open when this was drawn, and four were ruled in session to unblock it. **All
twenty-four are RESOLVED as of 2026-08-13**; the table below records what the frames were drawn
against:

| Question | Ruling used here |
|---|---|
| Quantity semantics (`TSV-12`) | Stepper only on infinite-stock, unstateful items; it fires N separate atomic transactions |
| Destination (`TSV-15/16`) | Fixed to the inherited subject, convoy overflow silent and reported after the fact |
| Viewport set | Ratified six plus 1080p, 1440p, 4K, and 4K at 2.0 content scale |
| Occlusion | Compact drawn in both states per `UUI-12` |

Frames drawn against a register *recommendation* rather than a ruling carry the ID in grey
in the album.

## The nine states

| # | State | What it establishes |
|---|---|---|
| 01 | Entry | Checkpoint taken and announced as status; subject inherited, never prompted for |
| 02 | Browse (Buy) | Derived category facets, final price only, focus distinct from selection |
| 03 | Selection | Price formula with localized signed modifiers; consequence preview |
| 04 | Committed | One atomic transaction appended to the visit; quantity stepper; silent overflow reported |
| 05 | Sell | Sibling tab keeps shopper and filters; durability-scaled yield; key item disabled with reason |
| 06 | Blocked | Named shortfall, proposal preserved, recovery offered as an action |
| 07 | Exceptional consequence | Focused warning, bounded by the game view, at fixed safe scale |
| 08 | Exit review | Visit history with Confirm Visit / Restore Checkpoint, whole-visit only |
| 09 | Deep detail | An item carrying every function at once — the stress case |

State 09 is deliberately the worst case: forged three times with history, effective against
two classes, two on-hit effects, two equipped passives, weapon triangle both ways, three
gated requirements, a four-term price, four consequences and two warnings.

## Compositions

### Ruled: single-scroll at every size class

**Decision (2026-08-12): the detail surface flows and ends in its own action. Nothing docks,
at any size class.**

The first cut pinned the purchase button and the status bar to the bottom of the pane while
content clipped above them. That inverts `TSV-6`, which exists precisely so the consequence
is seen before the action — the action was reachable before its own cost was readable.

The complex item then showed the cost of leaving the pattern anywhere. At 1024×768 and
1280×720 Sunder's pane clipped after Weapon triangle, so the price, the consequences and
**both** warnings — including "cannot be sold, permanent for the campaign" — sat below the
fold while the Buy button stayed permanently on screen. A player could commit an
irreversible purchase whose warning had never rendered.

Under the ruling, consequence-before-action is structural rather than something reviewers
have to remember. Measured extents, from the album:

| Surface | Extent | Window | Screens |
|---|---|---|---|
| Routine purchase, Compact floor, control band | 478 px | 247 px | 1.9 |
| Routine purchase, Compact floor, overlay opt-in | 502 px | 535 px | fits |
| Complex item, Compact floor, overlay opt-in | 1690 px | 535 px | 3.2 |
| Complex item, Compact floor, control band | 1690 px | 246 px | 6.9 |
| Complex item, 1024×768 detail pane | 1236 px | 649 px | 1.9 |
| Complex item, 1920×1080 detail pane | 1192 px | 961 px | 1.2 |
| Complex item, 2560×1440 detail pane | — | 1321 px | fits |

Compact step frames are drawn twice: clipped to the viewport, and at **full scroll extent**
so the whole column can be read at once.

### Ruled: Expanded is character sheet / list / detail, with category tabs on top

**Decision (2026-08-12):** at Expanded, categories are promoted from chips to a tab strip
under Buy/Sell, and the left column carries a **compact character sheet** for the shopping
subject — portrait, level and class, HP, the eight stats, equipped weapon with durability,
inventory and convoy counts, and the pricing subject.

The character sheet earns the column by carrying the **equipped-weapon comparison for the
current selection**: with Sunder, Attack 19 → 28 (+9), Hit 105 → 110 (+5), Critical 12 → 27
(+15), Avoid 30 → 28 (−2). The question in a shop is not what an item costs but what it does
to this unit. Consumables state "no combat change" rather than showing an empty comparison.

Medium keeps chips rather than a second tab strip: `UUI-19` already measured that the
524-px landscape rect cannot hold six Settings tabs, and promoting categories there would
repeat a known failure.

## Findings

Five constraints not previously recorded. Each is visible in a frame in the album.

1. **The docked action inverted `TSV-6`** — resolved by the single-scroll ruling above.
2. **The failure reason is the worst casualty of the fold.** In the blocked state the
   shortfall sits two thirds down the column. Whatever else scrolls, the reason a commit was
   refused should lead the step.
3. **852×393 is the tightest transaction surface in the set.** The 4:3 rect is 524 logical
   px, and list plus detail leaves the detail 240 px at touch tokens — the same 524 px that
   `UUI-19` found too narrow for six tabs. Two independent surfaces have now hit this number.
4. **4K at 1.0 content scale is not a usable configuration.** The 14 px controller token is
   0.36% of display height; the bounded workspace keeps the layout correct and unreadable at
   once. This argues for `content_scale_factor` defaulting by display size rather than to
   1.0 — and that setting already carries `reachability_risk` under `UUI-18`.
5. **The complex item retired the docked action everywhere**, which is what produced the
   ruling in the first place.

## Ruled: header condensation and currency presentation

Walked 2026-08-13 — `SHC-1..8` in
[`shop_header_condensation_open_questions_2026-08-12.md`](../registers/shop_header_condensation_open_questions_2026-08-12.md)
and `CUR-1..7` in
[`shop_currency_presentation_open_questions_2026-08-13.md`](../registers/shop_currency_presentation_open_questions_2026-08-13.md).
The album is redrawn against both, so those frames show decided behaviour rather than
hypotheses:

- One header line — subject inline, the **node name** gives way, and the currency figure is a
  **button** opening the full holdings.
- One control row — `[Buy|Sell]` segmented control leading the derived facets.
- Landscape turns the chrome 90° into a vertical rail.
- The header figure is **abbreviated** (`128k g`); the popup carries full counts (`128,400 g`).
- The holdings popup lists **everything spendable**, inventory included, grouped and scrolling.

**Measured after the redraw:** chrome at the design floor fell 190 → 111 px and the list grew
161 → 241 px, **2.9 → 4.3 rows**. Landscape went 3.6 → **7.0 rows**. Both projections were
exact. Full table in the `SHC` register.

## Adopted as the family skeleton (2026-08-15)

`[DSX-S25]` ruled this album's Expanded composition — character sheet / list / detail — **is** the
distribution surface's `holder · pool · detail` skeleton, shared with convoy, loadout, skills,
techniques, battalions, forge and on-map Trade. The character sheet is the holder; the category tab
strip is the control row's facets. **No redraw follows** — the unification is a naming change. Two
rulings do reach these frames: `[DSX-S17]` makes the battlefield shop this same adapter with a
context-declared verb set, and `[DSX-S26]` requires a no-receipt store to say so in the detail above
the verb *and* once at entry. See
[`distribution_surface_open_questions_2026-08-15.md`](../registers/distribution_surface_open_questions_2026-08-15.md).

## What this does not decide

- ~~`TSV-10..24` remain open; `SHP-1..5` are still open in their own register~~ — **both corrected
  2026-08-15** (`DSX` diff, F1/F2). `TSV-1..24` resolved 2026-08-13 and `SHP-1..5` were never open.
  Prices here are illustrative because no *content* exists, not because a register blocks them.
- No paint is specified. Under `UUI-16` the shop is inside the pack theme boundary.
- No engine seam is proposed. `ResourceLedger.quote/commit` already exists; the checkpoint
  participant registry `TSV-3` requires does not.
