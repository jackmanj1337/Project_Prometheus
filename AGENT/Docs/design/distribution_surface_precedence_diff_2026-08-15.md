---
Role: dated
Type: design
Status: Written before the walk (DOC-014); findings F1–F12 changed the packet. Walk ran 2026-08-15 — DSX-1..28 RESOLVED
Last verified: 2026-08-15
Tracker: DISTRIBUTION-SURFACE-2026-08-15
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Distribution Surface — Precedence Diff

Written before [`distribution_surface_open_questions_2026-08-15.md`](../registers/distribution_surface_open_questions_2026-08-15.md)
is walked, per the standing rule that a precedence diff precedes every walk. This is the `S5`+`S6`
session of [`research_and_discussion_sequencing_2026-08-13.md`](../plans/research_and_discussion_sequencing_2026-08-13.md),
widened by owner decision on 2026-08-15 from *convoy + shop* to **every surface that moves a
limited thing onto a holder**: convoy, loadout, skills, techniques (styles), battalions, shop,
forge, on-map Trade and provider convoy access.

## 1. What was checked, against what

| Checked | Against |
|---|---|
| The convoy/shop screen questions | `CNV-1..8`, `SHP-1..6`, `SAC-1..12`, `IEQ-1..9`, `CEX-16` |
| Transaction vocabulary | `TSV-1..24`, `SHC-1..8`, `CUR-1..7` |
| Interaction rulings | `EPUX-01..28` (08–17 inventory/shop, 23–28 forge) |
| The assignable families now in scope | `SKL-1..6`, `STY-1..17`, `LDC-1..9`, `BAT-1..16` |
| Responsive contract | `UUI-1..19`, `RPD-1..18`, `L10N-7`, `DRC` (`UBS-4` Compact ruling) |
| On-map behaviour | `CNV-5` (2026-07-27 amendment), `DRC-30`, `DRC-31`, `EPUX-11` |

## 2. Findings

### F1 — `SHP-1..5` are not open, and two documents say they are

Every one of `SHP-1..5` carries an owner `Resolution` from 2026-06-23k, and the register header
reads `Status: RESOLVED 2026-07-02`. Only the inline `**[OPEN]**` markers were never flipped.

Two documents propagate the false claim and draw a conclusion from it:
[`transaction_surface_open_questions_2026-08-12.md`](../registers/transaction_surface_open_questions_2026-08-12.md)
closes with *"Still open elsewhere and still blocking: `SHP-1..5`"*, and
[`shop_transaction_wireframes_2026-08-12.md`](shop_transaction_wireframes_2026-08-12.md) says
*"`SHP-1..5` are still open in their own register, so all prices here are illustrative."*

**Effect on the packet:** the price *model* is settled — resource-keyed buy cost and sell yield,
campaign-default sell formula scaled by durability, per-shop incoming and outgoing modifiers. The
album's prices are illustrative because no *content* exists, which is a much weaker statement and
blocks nothing. **Do not ask any pricing-model question in this packet.**

**Owed edit:** flip the five inline markers and correct both citing sentences.

### F2 — The shop wireframes document is stale in three places

It states `TSV-10..24` "remain open" (all twenty-four are RESOLVED as of 2026-08-13), repeats it in
*What this does not decide*, and still carries `Status: Wireframes drafted as hypotheses`. The `SHC`
and `CUR` walks have since been drawn into the album.

### F3 — `UBS-6`'s own text carries a superseded premise

The agenda entry that *is* this session's brief describes the surface as running over *"the single
`party_gold` wallet"*. `CUR-1..7` ruled multi-wallet presentation, and the finding underneath it was
that **the engine never assumed one currency** — `resource_types` is a required open registry,
`CostSpec` carries `resource_id` + `scope`, `ResourceTransaction.wallets_touched` is plural, and
`SaveData` already migrates `party_gold` into a resource map. `MapMenu.gd:75` is the only gold
assumption in the program.

### F4 — `DISCUSS-CONVOY-SHOP-UX-2026-07-23` is `completed`, and that means the research finished

Standing rule 3, hit for the fourth time. Its rulings are `EPUX-08..17`: organization axis (`C`,
unit-first plus a global sibling), verbs not drag (`A` for v1, with the verb path as the
authoritative mutation command), the effective-state stacking key, overflow to convoy with the
pending-items tray, the two named bulk operations, Buy/Sell sibling tabs, subject-inherited
sessions, derived filters with no free-text search, final price in the list and formula in the
detail. **This packet cites all of it and re-asks none of it.**

### F5 — Four ratified rulings delegate presentation to a surface nobody has drawn

- `CNV-8` (2026-06-30) specifies the convoy panel's functions "building on the `[PHB]` panel surface
  + the `B6-INPUT` shared selector".
- `BAT-10` says battalion assignment reuses "the existing equip/loadout UI affordances".
- `LDC-1` generalizes the skills earned/equipped/cap pattern to styles and granted sources — one
  mechanism, no presentation.
- `RPD-11` makes Manage Roster an **open registry** of roster-config panels with Loadout, Skills,
  Details and Swap as *shipped defaults, not the set*.

There are no loadout frames in any album. **This is why the owner's scope widening is not scope
creep:** four decisions already point at one undrawn surface, and drawing it once is the cheapest
way to honour all four. It is also the `RPD-18` failure mode in advance — the risk is not that we
re-derive something, it is that we derive four somethings.

### F6 — "Technique" has no term in the corpus

Confirmed with the owner 2026-08-15: **technique = style** (`STY-1..17`, combat arts and gambits,
capped by `LDC-2`'s `max_styles`). The packet uses *technique (style)* on first mention and `style`
in citations, so no fifth family is created by vocabulary drift.

### F7 — "Battlefield shop = the same interface, different trigger" has a measurable cost

Owner ruling, 2026-08-15. It removes a whole screen from the program, and it imports the full prep
shop chrome into the tightest rectangle the project has: the 4:3 game rect at 852×393 is **524
logical px**, a number `UUI-19` and the shop album reached independently.

The proof set draws the consequence and proposes the resolution: an on-map distribution surface
occupies the **canvas region only and never the control band**, which is exactly what `DRC` ruled
for conversations at Compact (`UBS-4`). Measured, with `SHC-5`'s landscape rail applied:

| | Horizontal chrome | `SHC-5` vertical rail |
|---|---|---|
| Chrome cost | 117 px of 393 | 64 px wide + a 28 px context line |
| Pane window | 250 px | **340 px** |
| Rows visible | 5.2 | **7.1** |
| Battlefield-shop detail | 1.81 screens | **1.33 screens** |

The rail is worth 90 px of height on-map. This independently reproduces the `SHC` walk's measured
3.6 → 7.0 landscape row gain to within a tenth of a row, which is a useful check that these frames
and the shop album agree.

### F8 — Trade is the only consumer with two holders

Every other consumer is *one holder, one pool*. `DRC-30`'s unit↔unit Trade is holder↔holder, and
`EPUX-03` caps adjacent panes at two. The proof set draws the proposal — the second holder becomes a
**group header inside the pool** — and it is drawn as a hypothesis, not a ruling. `DSX-9` asks it.

### F9 — A word collision already recorded; do not re-arbitrate it

`DRC-30`'s walk recorded that `TSV`'s *"no cart, no staging"* forbids a **user-visible cart that
accumulates intent**, while the two-primitive ruling's **staged transaction** is the *internal atomic
commit mechanism for a single operation*. Different senses of one word. This packet uses "staged"
only in the second sense.

### F10 — The forge is already subject-scoped like the shop

`EPUX-25` ruled the forge's picker reach falls out of the subject-first Explore model rather than a
forge-specific policy, `EPUX-24` made forge and shop **thin panels over one atomic core**, and
`EPUX-26` ruled operation **sections plus registered presenters** rather than a third navigation
level. The owner's "a version of forge" is therefore already specified as a panel: what this session
adds is its *responsive presentation*, not its design. `FRG-1..20` and `EPUX-23..28` are not
reopened.

## 3. Cited, never restated

| Register | Owns |
|---|---|
| `TSV-1..24` | Transaction states, atomicity, quote contents, confirmation, cancellation, receipts, reversal, error contract, state survival |
| `SHC` / `CUR` | Shop header condensation, landscape rail, primary currency as a button, holdings popup |
| `EPUX-08..12` | Organization axis, verbs-not-drag, stacking key, overflow and the pending tray, the two bulk operations |
| `EPUX-13..17` | Buy/Sell tabs, shopper and destination, derived facets, stock cadence, price disclosure split by pane |
| `EPUX-23..28` | Forge operations, shared core, subject scope, sections + presenters, automatic naming, exit-receipt reversal |
| `CNV-1..8` | Convoy storage, capacity rule, per-unit cap enforcement, single shared store, stacking, panel functions |
| `SHP-1..6` | Price model, buy and sell, stock model, destination rule, gold ledger, sell-price formula |
| `SKL` / `STY` / `LDC` / `BAT` | The five assignable families and the one earned/equipped/cap mechanism over them |
| `UUI` / `RPD` / `L10N-7` | Size classes, density tokens, control region, panel registry, 1.4× text extent |

## 4. What the draw measured

From [`distribution_surface_proof_set.html`](../wireframes/albums/distribution_surface_proof_set.html),
read from the rendered layout:

| Frame | Chrome | Pane window | Content extent | Screens |
|---|---|---|---|---|
| Convoy pool, 360×640, control band | 117 px | 209 px | 496 px | 2.37 |
| Convoy detail, 360×640, control band | 117 px | 209 px | 401 px | **1.92** |
| Skills detail, 360×640, control band | 117 px | 209 px | 389 px | **1.86** |
| Shop pool, 360×640, control band | 117 px | 209 px | 352 px | 1.68 |
| Convoy pool, 360×640, overlay opt-in | 117 px | 497 px | 496 px | **fits** |
| Trade pool, 852×393, canvas + rail | 28 px | 340 px | 549 px | 1.62 |
| Trade detail, 852×393, canvas + rail | 28 px | 340 px | 422 px | 1.24 |
| Battlefield shop detail, 852×393 | 28 px | 340 px | 451 px | 1.33 |
| Every consumer at 1920×1080 | 72 px | 982 px | 145–407 px | fits |

**Three findings the numbers produced:**

1. **The two-screen detail column is structural to the family, not a shop problem.** The shop album
   measured a routine purchase at 1.9 screens at the Compact floor. A routine *convoy transfer*
   measures 1.92 and a *skill equip* 1.86 — three unrelated consumers, the same number. Whatever is
   decided about the Compact detail step applies to all of them at once.
2. **The overlay opt-in is the only configuration where a pool is workable at the floor**: 4.4 rows
   with the control band, 10.4 with the opt-in.
3. **The controller row token is a single-line token.** Every consumer here needs a name and a
   sub-line, which measures **35 px against a 28 px `--row`** — a 25% overrun before `L10N-7`'s 1.4×
   extent is applied. The frames let the row grow so the measurement is honest; `DSX-16` asks what
   the contract should be.

## 5. Questions this diff removed before the walk

- *"Can the player sell from the convoy?"* — `SHP-6` lists the shopper's whole inventory and the
  drawn album already sells convoy-held items. Settled; not asked.
- *"Does the shop need its own selector / transaction core?"* — `EPUX-24`, `TSV-10`. Not asked.
- *"How are prices modelled?"* — F1. Not asked.
- *"Where do bought items go?"* — `SHP-4` + `SAC-6` + `EPUX-14`. Not asked.
- *"Is there free-text search or drag-and-drop?"* — `EPUX-09`, `EPUX-15`: both post-v1, both
  deliberately layered over an input-agnostic v1. Not asked.
- *"Which prep panel hosts this?"* — `RPD-11`: the Manage Roster open registry. Not asked.

## 6. The dependent-choice layer — checked before it was drawn

Owner proposal, 2026-08-15, added after the first draw: one layer where a pick produces a second,
dependent set of choices. Two precedence findings changed it before a frame existed.

### F11 — The gesture is already ratified, for a fifth consumer

`RPD`'s amendment to the prep-hub section (2026-08-13) ruled the auto-fill-then-swap placement
model's gesture: **select-then-select, committing on the second selection, no confirm — "a swap is
reversible so it earns no `CAU-4` tag."** That is this layer, ruled for deployment placement.

Two consequences. The layer must **absorb** that gesture rather than become a second implementation
of it — this is exactly the "repeated mechanisms that should be one" shape `R3` is chartered to find,
and finding it *before* building is cheaper than finding it in the pass. And the *reversibility
clause* transfers with the gesture: no-confirm is conditioned on the action being reversible, which
is why `DSX-25` sends the irreversible cases to `DSX-21`'s reversibility classes rather than to a
dialog. `TSV-8` and `RPD-9` both rejected engine-side risk classification; a confirm invented inside
this layer would be the third attempt.

### F12 — `EPUX-26` rejected a second *level*, not a second *set*

The ruling reads: *"Rejecting B avoids a third navigation level (item → mode → operation), which the
`EPUX-03` pane budget caps at two adjacent panes."* It rules the forge shows **one operation list
grouped into labelled sections, each rendered by its registered presenter** — and it names no pane.

So a dependent set is legal exactly when it **replaces a region rather than adding one**. It is worth
recording the related near-miss: the skeleton's three regions at Expanded are not three levels of the
Explore chain either. The holder is the subject *already chosen*; the chain is still
`pool → detail`. The shop's ruled Expanded composition (character sheet / list / detail, 2026-08-12)
already established that reading, after `EPUX-03`. The pane budget counts navigation levels, not
visual regions.

### What the draw then measured

Both placements, at 852×393 — the tightest viewport in the program:

| | Pool region | Detail region |
|---|---|---|
| Trade, set in the **pool** | set, **fits** (256 / 338 px) | result + verb, 1.26 screens |
| Trade, set in the **detail** | stale inventory, 1.62 screens | set + result, **2.14 screens** |
| Forge, set in the **pool** | set, **fits** (324 / 338 px) | result + verb, 1.05 screens |
| Forge, set in the **detail** | eligible items, fits | set + result, **2.04 screens** |

**One rule, not two.** Pool placement wins for *both* kinds, and the margin is large: a full screen for
the operation kind, and for the counterpart kind a whole wasted pane on top of 0.9 screens. The
result is not a preference — detail placement pushes the commit verb below two screens of scrolling
at the viewport where the battlefield already costs the most, which is the same inversion the
2026-08-12 single-scroll ruling was written to prevent.

**A third consumer appeared while drawing it.** Equipping a skill into a full cap is a counterpart
set with no trade and no economy in it: pick the incoming skill, then pick what it displaces. The
same is true of techniques, battalions and a convoy transfer into a full holder. A layer that has
three consumers on the day it is proposed — and a fourth already ratified in `RPD` — is a primitive.

## 7. Walk order

`DSX-1..3` first — they set what the surface *is*, and eight adapters inherit the answer. Then the
Compact chain (`4..8`), on-map (`9..12`), caps and capacity (`13..15`), rows and authoring
(`16..18`), and the handed-over residue last (`19..22`), which is where the no-receipt store problem
`TSV` explicitly assigned to this session lives. **`DSX-23..28` (the dependent-choice layer) is
walked after `DSX-3` and before the Compact chain** — it changes what the pool region *is*, so the
collapse rules must be written knowing the answer.
