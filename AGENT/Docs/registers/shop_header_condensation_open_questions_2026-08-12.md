---
Type: register
Status: RESOLVED — SHC-1..8 ruled 2026-08-13 (SHC-6 via [CUR-1..7])
Last verified: 2026-08-12
Register: SHC-1..8
Tracker: SHOP-TRANSACTION-WIREFRAMES-2026-08-12
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Compact Header Condensation — Owner Questions

Drawn from [`shop_transaction_wireframes_2026-08-12.md`](../design/shop_transaction_wireframes_2026-08-12.md).
Walked with the owner on 2026-08-13. Seven of eight took the recommendation. `SHC-6` was
held mid-walk because the owner rejected its premise — a single wallet figure assumes gold is
accepted at every store, which the engine has never assumed — and was then resolved through
[`CUR-1..7`](shop_currency_presentation_open_questions_2026-08-13.md), walked the same day.

## The measured problem

Every figure below is measured from the album's rendered layout, not estimated.

| Viewport | Game view | Chrome | List | Chrome share | Rows visible |
|---|---|---|---|---|---|
| 360×640, control band | 352 | **190** | 161 | **54%** | 2.9 |
| 852×393, control band | 393 | **190** | 202 | **48%** | 3.6 |
| 393×852, control band | 469 | 190 | 278 | 41% | 5.0 |
| 768×1024, control band | 563 | 190 | 372 | 34% | 6.6 |
| 360×640, overlay opt-in | 640 | 190 | 449 | 30% | 8.0 |
| 1024×768 | 768 | 89 | 649 | 12% | 22.6 |
| 1920×1080 | 1080 | 89 | 961 | 8% | 33.4 |

The chrome is a fixed 190 px at every touch viewport — header 72, subject strip 37, Buy/Sell
tabs 41, filter chips 40. It does not adapt, so it costs 8% at FHD and **54% at the design
floor**: the shop spends more than half the game view before the first item.

### The structural point

**Size class is derived from width alone, but this problem is vertical.** 852×393 is classed
Medium — it gets Medium's two-pane composition and Medium's touch tokens — while having a
*worse* vertical budget than the 360×640 Compact floor. The chrome band is horizontal, so it
is charged entirely against the axis landscape has least of, and the class that decides how
much chrome to draw is keyed on the axis landscape has most of.

Landscape also has 328 px of width sitting in reserved control columns and 524 px of game
view, so it is the one case where the answer is not "remove chrome" but **"turn it 90°."**

### What each band actually is

| Band | px | What it is | Is it a control? |
|---|---|---|---|
| App bar | 72 | Shop identity, node, wallet, back | Navigation + status |
| Subject strip | 37 | "Shopping as Arden · destination fixed" | **Pure status** — the decision was made in Explore (`EPUX-13`) and the destination is fixed (`TSV-15` ruling) |
| Buy/Sell tabs | 41 | Session mode | Control — changes the meaning of every price |
| Filter chips | 40 | Derived category facets (`EPUX-15`) | Control — narrows the list only |

Only two of the four bands are controls. One of them, the subject strip, displays a decision
the player already made on the previous screen and cannot change here — which is what makes
"fold it into a previous menu" the right instinct.

## Constraints that must not be reopened

- `EPUX-13` — **one** shop session with Buy/Sell **sibling tabs**; separate buy and sell
  activities were considered and rejected. Shopper and filters survive the tab switch.
- `EPUX-15` — categories are derived facets, never engine shop enums; no free-text search in v1.
- `TSV-6` / single-scroll ruling — consequence before action; nothing docks.
- `UUI-12` — the fullscreen overlay is an opt-in, so no design may *require* it.
- `UUI-11` — density tokens are shared. Header 72 / footer 64 belong to every screen; the
  shop cannot mint a local exception (that is the failure `UUI-11` added the `dense` column
  to avoid).

## Options

### [SHC-1] Does the subject strip survive on Compact?

- **A — Keep it.** For: the shopper is always visible, so shopper-relative prices are never
  unexplained. Against: 37 px, ~11% of the floor's game view, for a line the player cannot act on.
- **B — Fold the subject into the app bar.** One line: `‹ Causeway Quartermaster · Arden · 2,480 g`.
  For: keeps the fact, frees the band. Against: the app bar gets busy at 360 px, where the shop
  name already truncates.
- **C — Drop it from Compact entirely.** For: the price breakdown already names the subject
  ("Arden's bearing −80 g"), so it is redundant where it matters. Against: not visible while
  browsing, only after selecting.
- **Recommendation: B**, with the shop *node* dropped from Compact rather than the subject.
  Identity survives, and the strip's 37 px goes to the list.

**Owner ruling (2026-08-13): B.** The subject folds into the app bar and the node name is
what gives way. The strip was displaying a decision the player cannot act on here.

### [SHC-2] Do the tabs and the filter row merge into one control row?

- **A — Keep two rows.** For: mode and facet are different kinds of choice and look it.
  Against: 81 px of controls above a 161 px list.
- **B — One row: mode as a leading segmented control, facets after it.**
  `[Buy|Sell] · All · Weapons · Items`. For: saves 40 px, keeps both reachable, one focus line.
  Against: risks reading mode and facet as peers when a mode switch changes every price and a
  facet only filters. Mitigated by a visual break and a persistent segmented shape.
- **C — Mode moves into the app bar as a toggle.** For: maximum separation of kinds.
  Against: hides a first-class mode in navigation chrome; poor for controller focus order.
- **Recommendation: B.**

**Owner ruling (2026-08-13): B.** One control row, mode leading as a segmented control.
The mode/facet distinction is carried by shape and a visual break, not by a second row.

### [SHC-3] Does the *first* category selection move into the previous menu?

This is the "condense into previous menus" idea applied to the band that is pure filtering.

- **A — No.** For: one entry point, all stock, filter in place. Against: the facet row is
  permanent even for a five-item stock that needs no filtering.
- **B — Yes: the Explore node lists derived categories as entry points.**
  `Causeway Quartermaster ▸ Everything · Weapons · Items · Equipment`. You enter pre-filtered,
  and facets move behind an app-bar affordance. For: removes 40 px in the common case; the
  categories are already derived, so the menu is generated, not authored. Against: an extra
  decision before the shop, and a second place category vocabulary appears.
- **C — Only when the stock exceeds a threshold.** For: simple shops stay one-tap. Against:
  the entry menu changes shape with stock size, which is hard to learn.
- **Recommendation: B**, with "Everything" first and the last choice remembered per shop, so
  the extra decision costs one keypress and can be skipped by muscle memory.

**Owner ruling (2026-08-13): B.** The Explore node lists derived categories as entry points.
"Everything" leads and the last choice is remembered per shop. The categories are derived
from stock metadata, so the entry menu is generated — authors gain no new obligation.

### [SHC-4] Landscape: does the chrome go vertical?

- **A — Keep the top band.** For: one composition everywhere. Against: charges 190 px against
  the 393 px axis, leaving 3.6 rows in a rect that has width to spare.
- **B — Left rail in landscape.** Identity, wallet, mode and facets in a ~140 px vertical rail
  inside the 524 px rect; the list gets the full 393 px height (7.0 rows). For: spends the axis
  that is cheap. Against: a second Compact composition to build and test; 384 px left for
  list plus detail is tight.
- **C — Rail only under the `UUI-12` overlay opt-in**, where the full 852 px is available.
  For: no width pressure at all. Against: the default separated case — the one that must
  work — is left unimproved, which is exactly the trap `UUI-12` warns about.
- **Recommendation: B.** Landscape is a genuinely different problem, not a narrow desktop:
  it is the only viewport where the scarce axis and the chrome axis are the same one.

**Owner ruling (2026-08-13): B.** Landscape chrome becomes a vertical rail. This is the
first place the width-derived size class is deliberately overridden by a height rule, so the
composition selector needs an explicit landscape predicate rather than a width threshold.

### [SHC-5] Does the app bar collapse on scroll?

- **A — No.** For: stable target, no reflow. Against: leaves the worst case unimproved.
- **B — Collapse to a slim line after the first scroll**, keeping back, name and wallet.
  For: the single-scroll ruling already makes the app bar the only fixed element, so
  collapsing it is consistent; costs nothing on entry. Against: the *first* screen — the
  expensive one — is unchanged, and motion needs a `prefers-reduced-motion` path.
- **C — Compact only.** For: targeted. Against: two app-bar behaviours.
- **Recommendation: B**, as a supplement to SHC-1/2, never as the primary fix. It improves
  the second screen; SHC-1/2/3 improve the first.

**Owner ruling (2026-08-13): B.** Collapse after the first scroll, with a
`prefers-reduced-motion` path. Explicitly a supplement: it may never be counted as the fix
for the first-screen budget.

### [SHC-6] Does the wallet stay persistent on Compact?

- **A — Yes, full figure.** For: affordability scanning is the second most common question in
  a shop. Against: widest element in a truncating bar.
- **B — Persistent but abbreviated** (`2.4k g`, full figure in the detail). For: keeps the
  glance, frees width. Against: rounding near a boundary can mislead — 2.4k against a 2,480 g
  price is exactly the case where the player needs the truth.
- **C — Detail pane only.** For: maximum width. Against: removes the glance entirely.
- **Recommendation: A.** B's failure mode lands precisely where the decision is hardest. Win
  the width back from the node name (SHC-1) instead.

**HELD (2026-08-13) — the premise is wrong.** All three options assume one wallet holding one
currency that every shop accepts. The engine has never assumed that: `resource_types` is a
required open-registry family, `CostSpec` carries `resource_id` + `scope` per cost, `quote()`
takes an **array** of costs so one item can cost several resources at once, and `[SHP-1b]`
already ruled prices resource-keyed and extensible with an explicit instruction not to
enumerate the currency set. Only the **UI** assumes gold — `MapMenu.gd:75` reads
`format_party_gold(gs.party_gold)`.

**Resolved (2026-08-13) via [`CUR-1..7`](shop_currency_presentation_open_questions_2026-08-13.md): B, on a corrected premise.**
The figure is **persistent but abbreviated** — the full count lives in the holdings popup the
figure opens.

This is B, which the recommendation argued *against* on the grounds that rounding misleads
exactly where the decision is hardest. That objection was correct for the surface as it stood:
there was nowhere else to see the true number. `CUR-1` changed the surface. The full count is
one press away, and every figure a commit is actually made against — the price breakdown, the
consequence preview, the shortfall — stays at full precision. Abbreviation is confined to the
glance.

What also changed is *why* there is one figure at all: the header shows the **shop's declared
primary currency**, not an assumed universal gold, and that figure is a **button** opening the
full holdings list — currencies and consumable or transformable inventory alike.

The width this needs still comes from the node name, exactly as `SHC-1` ruled.

### [SHC-7] Where does affordability live if chrome shrinks?

- **A — Wallet only**, player does the arithmetic. Against: every row becomes mental subtraction.
- **B — Unaffordable rows already carry a reason** (`TSV-13` recommendation), so the list
  itself answers it. For: no chrome cost at all; consistent with the disabled-with-reason model.
  Against: depends on `TSV-13` being ruled that way.
- **C — Affordability chip in the app bar** ("6 of 8 affordable"). Against: chrome, and a
  number nobody asked for.
- **Recommendation: B**, and record it as a dependency on `TSV-13`.

**Owner ruling (2026-08-13): B.** The rows carry affordability. **Dependency recorded:** if
`TSV-13` is ruled away from disabled-with-reason, this returns as an open question. Under
`[CUR]` the reason string must also name *which* resource is short, not just "not enough".

### [SHC-8] Can the previous menu pre-select the landing tab?

- **A — No, Buy always lands.** For: predictable. Against: a "sell your loot" trip pays a tab
  switch every time.
- **B — The entry point sets the landing tab; the tabs remain inside.**
  `Quartermaster ▸ Buy / Sell`. For: cheaper common case. **This does not reopen `EPUX-13`** —
  it is still one session, tabs are still siblings, shopper and filters still survive the
  switch. Only the initial tab is inherited, exactly as the subject already is.
- **C — Remember the last tab per shop.** For: no menu growth. Against: surprising on return.
- **Recommendation: B**, and it composes with SHC-3: one entry menu supplies both landing tab
  and landing facet.

**Owner ruling (2026-08-13): B.** The entry point sets the landing tab; the tabs remain
inside the session. `EPUX-13` is untouched — one session, sibling tabs, shopper and filters
surviving the switch. Only the initial tab is inherited, exactly as the subject already is.

## Ruled package, measured

Applying the walked rulings SHC-1 (B), SHC-2 (B), SHC-3 (B) and SHC-4 (B):

| Viewport | Chrome now | Chrome after | List now | List after | Rows |
|---|---|---|---|---|---|
| 360×640, band | 190 | **113** | 161 | **238** | 2.9 → 4.3 |
| 360×640, band + SHC-3 entry filter | 190 | **73** | 161 | **278** | 2.9 → 5.0 |
| 852×393, band, vertical rail | 190 | **0** (rail) | 202 | **393** | 3.6 → 7.0 |
| 393×852, band | 190 | 113 | 278 | 355 | 5.0 → 6.3 |

The floor gains 1.4 rows from folding two bands and 2.1 rows if the entry menu also supplies
the facet. Landscape roughly doubles.

The figures in that table remain **projected**. Everything else in the album is measured;
these become measured when the frames are redrawn.

## Consequences to carry into implementation

1. **The composition selector needs a landscape predicate.** `SHC-4` is the first deliberate
   override of the width-derived size class by a height rule. It cannot be expressed as a
   width threshold, and inventing a local one would repeat the mistake `UUI-11` added the
   `dense` token column to avoid.
2. **The Explore node gains a generated submenu.** `SHC-3` and `SHC-8` both write to it —
   one entry menu supplies landing facet and landing tab. It is derived from stock metadata,
   so it is generated, not authored.
3. **`SHC-7` is a live dependency on `TSV-13`.** If disabled-with-reason rows are ruled away,
   affordability loses its home and returns as an open question.
4. **`SHC-5` may not be counted as the fix.** It improves the second screen; the first-screen
   budget is `SHC-1/2/3`'s job.
5. **The currency figure is a button at every size class** (`CUR-1`), so the app bar now
   contains an interactive control rather than pure status. Its touch target must meet
   `min_target` under the `dense` token column, and it must sit in the focus order ahead of
   the control row.
6. **Two precisions coexist.** The bar abbreviates; the popup, the price breakdown, the
   consequence preview and the shortfall do not. A formatter that abbreviates by default
   would leak rounding into the surfaces that must not round, so the abbreviation must be
   opt-in per call site, not the default.

## Next step

Redraw the affected Compact and landscape frames against `SHC-1..8` and `CUR-1..7` so the
ruled package's numbers are measured rather than projected, and add the two-currency and
wallet-popup cases the album has no frames for.
