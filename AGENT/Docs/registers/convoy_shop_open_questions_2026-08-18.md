---
Type: register
Status: PARTIAL — `CVS-1..10` authored 2026-08-18; `CVS-1..8` ruled `[CVS-S1]`..`[CVS-S8]`; `CVS-9..10` pending
Last verified: 2026-08-18
Register: CVS-1..10
Tracker: CONVOY-SHOP-PACKET-WALK-2026-08-18-2026-08-18
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Convoy and Shop — Owner Questions

The residue of `S5`+`S6`, which **already ran** as the widened `DSX-1..28` walk on 2026-08-15 — see
§0 of the precedence check, and read it first:
[`convoy_shop_precedence_diff_2026-08-18.md`](../design/convoy_shop_precedence_diff_2026-08-18.md).
These are the questions a shell walk structurally could not reach: not how a number is drawn, but
what the number counts.

**What this packet does not touch.** The shared distribution shell and everything it owns —
composition, focus, the reason vocabulary, the verb slot, the Compact chain, on-map placement, the
dependent-choice layer, capacity *presentation*, reversibility classes, no-receipt disclosure — is
ratified as `DSX-1..28`. Transaction semantics are `TSV-1..24`; the shop chrome is `SHC-1..8`;
multi-currency is `CUR-1..7`; the convoy and shop *models* are `CNV-1..8`, `SHP-1..6`, `SAC-5..9`
and the `EPUX` prep/economy walk. The cadence trigger engine is ratified in `EPUX` §Node traversal
and cadence model and is not reopened — this packet asks only what **subscribes** to it.

Two ratified constraints bound every answer below. `[DSX-S1]`: widen the shell for everyone or use
the **declared** escape hatch, never a bespoke screen. `[DSX-S6]`: no engine-side confirmation keyed
on cost or irreversibility — confirmation is `[EPUX-06]`'s authored, raise-only predicate.

## Comparative grounding

Four of these questions have no answer in the corpus, so genre precedent is the only prior art:

- **Convoy capacity** in the mainline entries this project takes as reference is either unlimited or
  counted in *items*, not stacks — but those entries also have no per-instance durability *and* no
  forging overlay competing to define what "the same item" means. `[EPUX-10]` gives this project a
  stacking key those games did not need, which is exactly why the accounting unit has to be stated.
- **Limited stock** is the exception rather than the rule in the reference genre: common weapons are
  effectively infinite, and scarcity is expressed through a small number of one-off entries and
  secret shops. Restock-on-a-clock is far more common in CRPGs and roguelikes, where the shop
  refreshes its whole offer rather than topping up depleted counts.
- **Restock disclosure** is rare anywhere. Most shops that restock do it silently; the player learns
  the rhythm. Games that do disclose it usually do so because the restock is a *reward* for
  progression rather than a timer.
- **Buyback** is near-universal in CRPGs (the just-sold item stays repurchasable, usually at the
  price paid, often only for the current visit) and near-absent in the reference genre, where a
  sale is final.

None of this settles anything; it says which options have been carried by real games and which are
this project's own invention.

---

## Section 1 — Convoy

### `[CVS-1]` What one unit of `convoy_capacity` counts  **[RESOLVED]**

`[DSX-S19]`'s cap model renders current/limit/projection identically for six caps, and `[DSX-S20]`
makes the after-action projection mandatory. Neither says what `convoy_capacity` counts, and
`[EPUX-10]` stacks entries with identical effective state, so a row and an instance are not the same
thing. `[EPUX-12]`'s `SEND ALL TO CONVOY` halts on "convoy full" against the same undefined number.
Measured: `convoy_capacity` does not exist in code; `CampaignRules.gd:28` has only `max_inventory`.

- **A — Instances.** Five identical vulneraries cost 5. For: the number matches what the player
  owns, and the projection is trivially computable at the moment of transfer. Against: a stacked row
  displaying "×5" costs five capacity, so the row count and the capacity figure disagree on screen.
- **B — Stack rows.** Five identical vulneraries cost 1. For: capacity matches the list the player
  is looking at. Against: capacity becomes a function of the `[EPUX-10]` stacking key, so forging or
  spending one use of one copy silently costs capacity by splitting a stack — a cap that changes
  without a transfer.
- **C — Instances, with an author-set per-stack allowance.** For: expressive. Against: a third
  number in a model `[DSX-S19]` deliberately unified to one shape.
- **Recommendation: A.** B's failure mode is disqualifying: `[DSX-S20]` promises a projection
  *before* the action, and under B a use of an item can change capacity with no action in the
  surface at all. A also keeps the sentinel meaningful — `unlimited` is the default and the common
  case, so the expensive branch is the rare one.

### `[CVS-2]` How the key-item class is declared, and where it renders  **[RESOLVED]**

`[CEX-16]` exempts key items from `convoy_capacity` and gives them "a dedicated Convoy Key Items
view" (2026-06-23) — nine weeks before `[DSX-S1]` ruled one shell with adapters and a *declared*
escape hatch. `[SHP-2]` makes them unsellable, `[EPUX-12]` excludes them from bulk transfer up
front, `[DTH-5]` gives them a disposition chain with `lost` banned. No ruling says how an item joins
the class.

- **A — An author flag on the item definition; the view is a pool facet.** For: the flag is one
  field, the facet is `[DSX-S23]`'s existing control-row mechanism, and the four ratified behaviours
  all read the same flag. Against: an item that is a key item in one campaign and ordinary in
  another needs a definition per campaign.
- **B — A campaign-level registry of item ids.** For: campaign-scoped without duplicating
  definitions; matches `[CEX-16]`'s designer-facing tracking panel, which is a derived scan over
  exactly this list. Against: a second place to look when asking "is this a key item".
- **C — Derived: an item referenced by a story predicate is a key item.** For: nothing to author.
  Against: makes the class invisible until predicates are written, and an author cannot mark a relic
  before the quest that needs it exists.
- **Recommendation: B, with the view as a pool facet, never a sub-view.** The registry is what
  `[CEX-16]`'s tracking panel already implies, and campaign scope is right because key-ness is a
  property of the story rather than of the item. The "dedicated view" half of `[CEX-16]` is
  **amended, not reopened**: it becomes a facet under `[DSX-S23]`, which is the same affordance
  `[CEX-16]` wanted and the one the shell can actually deliver.

### `[CVS-3]` Over-capacity that no transfer caused  **[RESOLVED]**

`[DSX-S21]` homes the pending-items tray in the holder region and gates **prep exit** through the
availability predicate; `EPUX` defaults the policy to hold-pending. Two paths sidestep both:
`GameState.active_mid_map_rule_overrides` already overrides `max_inventory` mid-map
(`test_mutable_campaign_state.gd:90`), and a campaign update can lower a cap under an existing save.
Quit-to-menu is also not prep exit.

- **A — Over-capacity is a legal state; the cap blocks additions only.** For: no data is ever
  destroyed, and the cap model already has a shape for it (current > limit). Against: the player can
  sit permanently over a cap with no prompt to resolve it.
- **B — Excess spills into the pending tray on load.** For: reuses the ratified mechanism and forces
  a resolution. Against: the tray's gate is prep exit, so a mid-battle override would fill a tray
  the player cannot reach until prep.
- **C — Refuse the load / refuse the override.** For: the invariant never breaks. Against: bricks a
  save on a content update, which is the one outcome a campaign update must never produce.
- **Recommendation: A for the state, B for the trigger, and the tray survives quit.** Over-capacity
  is legal and additions fail with the ordinary reason; spill to the tray happens at the next prep
  entry rather than on load, which keeps the mid-battle case coherent. The tray itself must persist
  in the save — a pending item that evaporates on quit is `[TSV]`'s "no silent loss" broken through
  a door nobody is watching.

### `[CVS-4]` What battlefield convoy access costs the unit  **[RESOLVED]**

Mid-battle access is an aura effect over the existing radius metric (`EPUX`), with a
context-declared Deposit/Withdraw verb set (`[DSX-S17]`) in the canvas region (`[DSX-S16]`), and no
browsing other units' inventories (`[CNV-5]`). Nothing says what it costs. Measured:
`TileActions.gd` returns `false` for `shop`/`visit`/`activate` — all placeholders, so no default has
been set in code.

- **A — It ends the unit's turn, like an item use.** For: consistent with the engine's existing
  action economy; scarcity keeps the aura a real tactical asset. Against: fetching a single
  vulnerary costs a whole turn, which in practice means players never use it.
- **B — It is free, and may follow movement.** For: pure convenience, and it makes the aura skill
  worth carrying. Against: a free full-inventory swap adjacent to the bearer is a large tactical
  effect for a passive.
- **C — Free while the unit has not acted; ends the turn if taken after acting.** For: matches the
  existing shape of trade-then-act rules. Against: a third rule to teach.
- **Recommendation: A, as the engine default, with the cost author-declarable on the aura effect.**
  The action economy is a rules decision, not a UI one, and the corpus's consistent instinct is that
  rules belong to authors — `[EPUX-06]`, `[DSX-S27]` and `[SAC-5..9]` all put policy in content.
  Shipping free-by-default is the harder thing to walk back. `[DSX-S18]`'s position-commit
  consequence line applies unchanged when the access follows movement.

---

## Section 2 — Stock and cadence

### `[CVS-5]` Does remaining stock adopt the `[DSX-S19]` cap model?  **[RESOLVED]**

`[DSX-S19]` names six caps; stock is not among them, because stock was not in front of the `DSX`
walk. Stock's default is the same `unlimited` sentinel, and `[DSX-S20]` would make an after-action
projection mandatory on every purchase if stock is a cap figure.

- **A — Yes, stock is a seventh cap.** Hatched bar when unlimited, current/limit and a projection
  when finite. For: one model, one renderer, and the sentinel case is already drawn. Against: a
  projection on every purchase row in a shop where almost everything is unlimited.
- **B — Stock is a row affordance, not a cap.** A remaining-count badge on finite rows only; nothing
  at all on unlimited rows. For: the common case costs nothing. Against: a second way to show a
  bounded quantity, which is the fork `[DSX-S19]` exists to prevent.
- **C — A, but the projection is required only for finite stock.** For: keeps one model while making
  the unlimited case free. Against: a conditional obligation inside a rule that was ruled
  unconditional.
- **Recommendation: C.** The cap model wins, but `[DSX-S20]`'s "whenever an action changes a cap
  figure" is already conditional in its own terms — buying from unlimited stock changes no figure,
  so nothing is being weakened. Under `[CVS-1]`'s answer the purchase still shows a projection
  against the *destination's* capacity, so consequence-before-action is intact either way.

### `[CVS-6]` Where the restock cadence reference lives, and what a tick does  **[RESOLVED]**

The 2026-08-18 boundary ruling put `quantity` (default `unlimited`) plus "a restock cadence
reference" on `ShopStockEntry`; `[EPUX-16]` ruled restock author-defined, default infinite, applying
to the shared pool across surfaces. `ShopStockEntry.gd` does not exist yet, so the schema is still
free.

Two parts:

**(a) Placement.** A — per stock **entity**, with an optional per-entry override. B — per entry
only. C — per shop frontend.
**(b) Tick semantics.** A — **reset** to the authored quantity. B — **increment** by N up to the
authored quantity as a ceiling. C — **re-roll** the entry set from an author table.

- **Recommendation: (a) A, (b) A with B author-selectable, C out of scope for v1.** Entity placement
  is what `[EPUX-16]`'s shared-pool ruling already implies, and the per-entry override costs one
  optional field. Reset is the behaviour an author gets right without thinking; increment is the one
  that expresses a rebuilding economy and is cheap alongside it. Re-roll is a different feature — a
  randomized offer — and pulling it in now would make stock depend on `RNG` policy, seeded runs and
  the determinism rules, none of which this packet has in front of it. Recorded as a named
  post-v1 candidate rather than a silent omission.

### `[CVS-7]` May a shop disclose its restock schedule?  **[RESOLVED]**

A sold-out row is *gated*, so `[EPUX-07]`/`[RPD-15]` already give it visible-disabled-with-reason
and focusable-not-activatable. The open part is the reason string. "Sold out" needs nothing;
"restocks next chapter" needs the shop to expose its cadence — and a cadence keyed on
`deployments_total` or `hours_played` cannot be phrased in chapters at all.

- **A — Never disclose.** Reason is always "Sold out". For: one string, no cadence family can
  embarrass it, and it matches how restocking shops behave almost everywhere. Against: a player
  cannot plan around scarcity they cannot see.
- **B — Always disclose, phrased per trigger family.** For: plannable. Against: requires a
  player-facing phrasing for every trigger family including predicates, whose condition text is
  authored for a different audience — and `L10N-7`'s 1.4× extent has to hold for all of them inside
  360 px.
- **C — Author-declared per shop, default off, with the engine supplying phrasings only for the
  counter families it can express.** For: scarcity as a design lever where an author wants it, and
  no obligation to phrase a predicate. Against: two possible reason strings for one state.
- **Recommendation: C.** The asymmetry is the point: counters are countable and can be phrased
  honestly, predicates cannot, and an author who wants a plannable economy is choosing to reveal a
  counter. Default off keeps `A`'s behaviour for every campaign that does not opt in.

### `[CVS-8]` Does selling add the item to the shop's stock?  **[RESOLVED]**

Unruled anywhere. `[SHP-6]` prices sells at 50% of value × durability% remaining plus the shop's
incoming modifier; `[EPUX-16]`'s finite stock is shared across surfaces; a restock tick under
`[CVS-6]` must decide whether player-sold entries survive it.

- **A — No. A sale removes the instance from the game.** For: the reference genre's behaviour;
  no new stock rows, no pricing question, no interaction with restock. Against: an accidental sale
  is unrecoverable — though `[TSV-19]`/`[DSX-S27]`'s receipt already covers the accident *within the
  activity*.
- **B — Yes, permanently: sold instances join the shared stock at their own state.** For: a living
  economy; a player can re-buy a forged blade they regret selling. Against: buy price for a used
  instance is undefined, sold items pollute a curated stock list, and every restock tick has to rule
  on them.
- **C — Buyback for the current visit only, outside stock.** A separate list, cleared on exit, at
  the exact price paid. For: solves the accident without inventing an economy. Against: a fourth
  list in a surface with three fixed regions.
- **Recommendation: A.** The accident case that motivates buyback everywhere else is already solved
  here by the receipt — `[TSV-19]` reverts the whole activity, and `[DSX-S27]` requires a
  no-receipt store to say so above the verb. B makes the used-instance buy price a new authored
  formula and forces a rule into every restock tick; C adds a region the shell does not have. If
  this is ever wanted, it is `[EPUX-16]`'s stock entity gaining a player-sold section, and it can be
  added without changing anything ruled here.

---

## Section 3 — Both halves

### `[CVS-9]` Quantity purchase under three simultaneous clamps **[OPEN]**

`[EPUX-21]` ruled a quantity stepper for divisible benefits, always showing remaining resource and
the effective cap live. With finite stock and `[CVS-1]`'s capacity unit, three limits now compete:
affordability, remaining stock, and destination capacity.

- **A — Clamp to the minimum of the three; name the binding one.** For: the stepper can never
  produce a failing transaction, and the reason contract `[EPUX-07]` already has a producer for each
  limit. Against: the player cannot see the other two limits at all.
- **B — Do not clamp; let the commit fail with a reason.** For: the limits stay visible. Against:
  it re-introduces the failure `[DSX-S20]`'s mandatory projection exists to prevent, and `[TSV-4]`
  already rejected partial commits.
- **C — Clamp to the minimum, and show all three figures.** For: complete. Against: three cap
  figures in a Compact detail column already measured at ~1.9 screens (`[DSX-S11]`).
- **Recommendation: A, with the binding limit named in the projection line.** `[DSX-S11]` promoted
  "the reason leads" to a rule; naming the binding limit *is* that rule applied to a clamp. The
  other two figures are one step away in the same surface — the wallet popup for affordability
  (`CUR-2`), the context line for capacity (`[DSX-S14]`) — so C buys visibility the surface already
  provides.

### `[CVS-10]` Sell-side presentation under `[EPUX-17]` **[OPEN]**

`[EPUX-17]` ruled final price in the list and the full formula in the detail pane — as a *buy*
question. `[SHP-6]` gives sell three composable terms (campaign formula × durability%, the shop's
incoming modifier, a per-entry `sell_yields` override that wins before the modifier), and the sell
view lists the **shopper's whole inventory**, not stock.

- **A — Symmetric: final yield in the list, the three-term breakdown in the detail.** For: one rule
  for both tabs of one session (`[EPUX-13]`), and the durability term is exactly the kind of thing
  `[EPUX-17]` put in the detail so the list stays readable. Against: none identified.
- **B — Yield only, no breakdown.** For: shorter detail pane. Against: durability scaling is
  invisible, so two identical-looking swords sell for different amounts with no explanation — the
  precise failure `[EPUX-17]` was ruled to prevent.
- **C — Breakdown in the list rows.** For: comparison without drilling in. Against: breaks the
  `[DSX-S22]` row budget and `[DSX-S23]`'s per-class field truncation.
- **Recommendation: A.** Note the one asymmetry to carry into the build: because the sell list is
  the shopper's inventory, an item the shop **will not buy** (`[SHP-2]`'s key items, or an author's
  incoming filter) is a gated row under `[EPUX-07]` — visible, disabled, with a reason — rather than
  a hidden one, so the player is never left wondering where an item went.

---

## Owner rulings

Walked 2026-08-18. Rulings are `[CVS-S*]` and are recorded as they are taken.

### Section 1 — convoy (`CVS-1..4`)

- **`[CVS-S1]` — `CVS-1` → A. Capacity counts instances.** Five identical vulneraries cost five.
  The stacked row shows `×5` and the capacity figure says five, so `[DSX-S19]`'s current/limit and
  `[DSX-S20]`'s mandatory projection are both computable at the moment of transfer, and no action
  outside the surface can change a cap figure. `convoy_capacity` keeps `[CNV-2]`'s `-1` unlimited
  sentinel as its default, so the counting rule only binds campaigns that opt into scarcity.
- **`[CVS-S2]` — `CVS-2` → none of the three. Key-ness is a set of per-instance properties, not a
  class.** The four ratified behaviours become **independent properties on the item instance**:
  exempt from `convoy_capacity` (`[CEX-16]`), unsellable (`[SHP-2]`), excluded from bulk transfer
  (`[EPUX-12]`), and routed to the key-item disposition chain with `lost` banned (`[DTH-5]`).
  "Key item" is the **authoring preset** that sets them together, not an engine type, and an author
  may set any combination without asking permission for it.
  - **The convoy keeps a view of all key items** — as a pool facet under `[DSX-S23]`, never a
    sub-view, because `[DSX-S1]` allows a widened shell or a declared opt-out and not a bespoke
    screen. This **amends** `[CEX-16]`'s "dedicated Convoy Key Items view", which predates
    `[DSX-S1]` by nine weeks; the affordance `[CEX-16]` wanted is preserved, the screen it implied
    is not. "At least in the convoy" is the floor — the facet is shell-level, so any consumer with
    a holder region can offer it.
  - **Derived in session, flag if wrong:** the facet filters on the preset's **story-item marker**,
    not on a conjunction of the four behaviours. A conjunction would silently drop an instance the
    moment an author set an unusual combination, and the marker is also what `[CEX-14]`'s inline tag
    and auto More-Info explanation already need.
  - **Why this is better than the class it replaces, not merely different.** Per-instance
    properties enter `[EPUX-10]`'s effective-state stacking key, so a story-critical copy never
    stacks with an ordinary one — which the class model could not express at all. And `[CEX-18]`'s
    item-mutation actions can now **promote or demote a specific instance** mid-campaign: an
    ordinary sword becomes a relic by acquiring properties, rather than by being a different item.
  - **Measured:** `InventoryEntry.gd` has none of these fields today, and no stable instance id —
    `PREP-V1-S03` adds the id, and this ruling makes it load-bearing rather than convenient, since
    per-instance properties have to survive save/load and `[EPUX-10]` regrouping.
- **`[CVS-S3]` — `CVS-3` → A for the state, B for the trigger, and the tray is durable.**
  Over-capacity is a legal state and the cap blocks additions only, with the ordinary `[EPUX-07]`
  reason; excess spills into the pending-items tray at **next prep entry** rather than on load, so a
  mid-battle `max_inventory` override cannot fill a tray the player has no way to reach. The tray
  persists in the save: a pending item that evaporates on quit-to-menu is silent loss through a door
  `[DSX-S21]`'s prep-exit gate does not watch.
- **`[CVS-S4]` — `CVS-4` → the question was asked at the wrong altitude, and is answered by adding
  one rule to a ratified default.**
  - **The precedence check missed the `[CNV-5]` amendment of 2026-07-27**, which already rules this
    and delegates the detail to `[DRC-30]`. The default therefore is not chosen here, it is
    **cited**: the FE7 partial-action preset — opening and cancelling without a transfer is free,
    the first committed deposit/withdrawal commits the actor's location, a session may hold multiple
    transfers, closing returns to the remaining-action menu, and Convoy may be initiated once per
    activation on a mark kept **separate** from Trade's. Which is to say: **it already works like
    Trade**, and `[DRC-30]` already makes action cost, session limit, post-action movement and
    provider range author-tunable policy fields in an open preset registry.
  - **What is new, and is the actual ruling: cost is overridable per source, and the most permissive
    source wins.** A unit may be covered by more than one grant at once — `EPUX`'s convoy-access
    **aura** and `[CNV-5]`'s **designated provider** are two different mechanisms, and a campaign
    rule is a third. Each source carries its own `[DRC-30]` preset; when several cover the same
    unit, the unit gets the **cheapest** one rather than the first evaluated, the nearest, or the
    last registered. Composition is therefore order-independent, which is what keeps it testable —
    the same shape as the cadence engine's OR-composed triggers.
  - **Consequence to specify in the build:** "most permissive" needs a total order over presets, so
    the registry must rank its policy fields (free < commits location < once-per-activation <
    ends activation) rather than leave permissiveness to be judged case by case.

### Section 2 — stock and cadence (`CVS-5..8`)

- **`[CVS-S5]` — `CVS-5` → C. Stock is a seventh `[DSX-S19]` cap, and the projection is required
  only when the stock is finite.** One cap model, one renderer, and the `unlimited` sentinel's
  hatched bar is already drawn. `[DSX-S20]` is not weakened by the exception: it obliges a
  projection "whenever an action changes a cap figure", and a purchase from unlimited stock changes
  no figure. Consequence-before-action survives either way, because under `[CVS-S1]` the same
  purchase still projects against the **destination's** capacity.
- **`[CVS-S6]` — `CVS-6` → (a) the stock **entity**, with an optional per-entry override;
  (b) **reset** to the authored quantity by default, **increment by N to a ceiling** author-
  selectable, **re-roll out of v1**.** Entity placement is what `[EPUX-16]`'s shared-pool ruling
  already implies — one pool depleting across the on-map storefront and the Explore-tab shop cannot
  restock on two schedules — and the per-entry override costs one optional field for the one-off
  rare item. Reset is what an author gets right without thinking about it; increment expresses a
  rebuilding economy and is cheap beside it.
  - **Re-roll is not a smaller version of the same feature and is deliberately excluded.** A
    randomized offer makes stock depend on `RNG` policy, seeded runs and the determinism rules, none
    of which this packet has in front of it. Recorded as a named post-v1 candidate rather than a
    silent omission.
  - This is schema for `B4-SHOP-ECONOMY` (upstream) and entity behaviour for `PREP-V1-S05`
    (downstream); both plans need the same sentence. `ShopStockEntry.gd` does not exist yet, so
    nothing is being migrated.
- **`[CVS-S7]` — `CVS-7` → C. Disclosure is author-declared per shop, default off, and the engine
  supplies phrasings only for the counter families it can honestly express.** A sold-out row is
  gated, so `[EPUX-07]`/`[RPD-15]` already give it visible-disabled-with-reason and
  focusable-not-activatable; this ruling is only about the reason string. The asymmetry **is** the
  ruling: `chapter_reached`, `chapters_elapsed`, `deployments_total` and `hours_played` are
  countable and can be phrased, predicate triggers are authored for a different audience and cannot,
  so a shop keyed on a predicate simply reads "Sold out". Default off keeps option A's behaviour for
  every campaign that does not opt in, and `L10N-7`'s 1.4× extent binds whatever phrasing ships.
- **`[CVS-S8]` — `CVS-8` → A for v1. A sale is final; nothing joins the shop's stock.** The accident
  that motivates buyback everywhere else is already covered here by `[TSV-19]`'s receipt, and
  `[DSX-S27]`/`[DSX-S26]` make a no-receipt store say so above the verb. B would require a buy price
  for a used instance and a rule about player-sold entries in every `[CVS-S6]` restock tick.
  - **Post-v1, and wanted (owner, 2026-08-18): stores keep what you sell them, and you can buy it
    back.** Parked as `B8-SHOP-BUYBACK` in the control plane's Band 8 table and tracked as
    `BACKLOG-SHOP-BUYBACK-2026-08-18-2026-08-18`. It is additive over everything ruled here — it becomes a
    player-sold section on `[EPUX-16]`'s stock entity, so it needs no change to `[CVS-S5]`'s cap
    model, `[CVS-S6]`'s tick, or `[SHP-6]`'s sell formula. The two questions it must answer when it
    is picked up are the buy price of a used instance (the sell yield paid, the shop's outgoing
    modifier over the item's damaged value, or an author formula) and whether a restock tick clears
    the player-sold section.

## Consequences to check at the walk

- `[CVS-1]` is the hinge — `[CVS-3]`, `[CVS-5]` and `[CVS-9]` all read differently depending on it.
- If `[CVS-2]` amends `[CEX-16]`, the amendment must be propagated to `[CEX-16]` itself and to the
  `PREP-V1-S03` slice text, which currently says "story items capacity-exempt with a **Key Items
  view**".
- `[CVS-6]`'s answer is schema for `B4-SHOP-ECONOMY` (upstream) and entity behaviour for
  `PREP-V1-S05` (downstream) — both plans need the same sentence.
- `[CVS-4]` is a rules decision that lands in `TurnManager`/`TileActions`, not in the shell; it
  belongs to the convoy build row, not to `PREP-V1-S05`.
- Nothing here changes an album. If `[CVS-5]` or `[CVS-7]` adds a figure or a reason string to a
  drawn frame, the shop transaction album's `.src.html` needs a re-bake — never a hand-edit.
