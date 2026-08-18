---
Type: design
Status: Precedence check complete; the surviving questions are `CVS-1..10`
Last verified: 2026-08-18
Tracker: CONVOY-SHOP-PACKET-WALK-2026-08-18-2026-08-18
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Convoy and Shop — Precedence Diff

The residue of `S5`+`S6`. The questions this produces are
[`convoy_shop_open_questions_2026-08-18.md`](../registers/convoy_shop_open_questions_2026-08-18.md).

## 0. The session this packet was going to be has already happened

**Found while checking, and it changes what this document is.** The sequencing plan's Stage C, the
`UBS-6` agenda and the tracker all still say the combined convoy/shop sitting is the **next
session**. The control plane says otherwise, and it is right: `DSX-1..28`, walked and closed
2026-08-15, **is** `S5`+`S6` — *"widened by the owner from convoy + shop to every surface that moves
a limited thing onto a holder"*. The sitting ran; it ran under a wider name, and the three documents
that scheduled it were never updated.

So this is not the S5/S6 packet. It is the **residue** that widening left behind: a shell walk asks
how a number is drawn, and these are the questions about what the number *is*. That is also why the
`UBS-6` agenda's own five-item list mostly evaporates on contact below — the walk it was written for
answered it, under different question ids.

**Stale text owed an edit, reported not edited** (each is claimed by another row):
`research_and_discussion_sequencing_2026-08-13.md` Stage C, which still schedules `S5`/`S6` as
pending and unordered; and the `UBS-6` section of `unbuilt_screen_research_agenda_2026-08-12.md`,
whose "**LIVE**; this is the NEXT SESSION" heading outlived the walk — already carrying one stale
line reported by `R1` on 2026-08-18.

## 1. Why this one is mostly subtraction

Every other dependent packet was authored before its contracts resolved and then checked. This one
is the reverse: the contracts resolved **first** — `TSV-1..24`, `SHC-1..8`, `CUR-1..7` on 2026-08-13,
`DSX-1..28` on 2026-08-15 — and the packet is authored after all of them, including after the walk
that was supposed to be its own (§0).

The consequence is that the `UBS-6` agenda, written 2026-08-12, is the wrong agenda. It lists five
things to settle. **Two of them no longer exist**, two are settled at the level it framed them and
survive only one layer down, and the item it names in half a line — refresh cadence — turns out to
be the largest genuinely open area in the pair. What follows is the check, item by item, and then
the findings that produced questions the agenda never anticipated.

### The `UBS-6` agenda, checked

| Agenda item | Disposition | Where |
|---|---|---|
| The shared selector's shape at Compact, "where a list *is* the screen" | **Dead — fully ruled** | `[DSX-S10]` sequential chain (holder → pool → detail, four steps under `[DSX-S5]`); `[DSX-S11]` accepts the ~1.9-screen detail column, *measured on a convoy transfer and a shop purchase among the three*; `[DSX-S2]` fixed regions |
| How a reserved-but-uncommitted transaction is shown if the player backs out | **Dead — the state does not exist** | `[DSX-S7]`: the first pick is **focus, not a reservation**, `TSV-2` ruled moot, cancel at stage 2 is `TSV-19` cancel-before-commit, vocabulary fixed as *pinned* |
| Convoy capacity presentation | **Presentation ruled; accounting never specified** | `[DSX-S19]`/`[DSX-S20]` — see `F2`, which is `CVS-1` |
| The key-items exemption (`CNV-2`, `CEX-16`) | **Survives, and now collides** | `F3` — `CVS-2` |
| `SHP-6`'s sell-price model | **Model ruled 2026-07-02; presentation never ruled** | `F8` — `CVS-10` |
| Refresh cadence | **Open, and larger than the agenda's half-line** | `F4`, `F5`, `F6`, `F7` — `CVS-5`..`CVS-8` |

Asking the first two would have manufactured decisions the corpus has already taken — the failure
`DOC-014` names and `RPD-18` demonstrated. They are recorded here so a later reader can see they
were checked rather than forgotten.

## 2. Findings

### F1 — The transaction *surface* is finished; the transaction *content* is not

`TSV`, `SHC`, `CUR` and `DSX` between them settle composition, focus, the reason vocabulary, the
verb slot and its two-verb cap, capacity presentation, the Compact chain, on-map placement, the
dependent-choice layer, bulk-operation reporting, reversibility classes and no-receipt disclosure.
Nothing in this packet reopens any of it, and no question below is a layout question.

What none of them settle is what the shop and the convoy are actually *counting* — capacity units,
stock quantities, restock semantics, buyback. Those questions did not surface in the `DSX` walk
because a shell walk asks how a number is drawn, not what increments it.

### F2 — Capacity presentation is ruled; the accounting unit was never named

`[DSX-S19]` gives one cap model — label, current, limit, an `unlimited` sentinel, an after-action
projection — rendered identically across `max_inventory`, `convoy_capacity`, `max_skills`,
`max_styles`, `max_sources` and the battalion slot. `[DSX-S20]` makes the projection **mandatory**
whenever an action changes a cap figure.

No ruling says what one unit of `convoy_capacity` *is*. `[EPUX-10]` stacks entries with identical
effective state, so five identical vulneraries are one row and five instances; the cap model cannot
render "current" and the projection cannot be computed until that is decided, and `[EPUX-12]`'s
`SEND ALL TO CONVOY` halts on "convoy full" against the same undefined number.

**Measured:** `convoy_capacity` **does not exist in code**. `CampaignRules.gd:28` has
`max_inventory: int = 8` and nothing else; the convoy is persisted as an untyped
`party.convoy.entries` array (`SaveData.gd:271-279`) with a malformed→legacy fallback and no
service. Nothing in the engine constrains the answer, which makes this cheap to rule now and
expensive to rule after `PREP-V1-S03`.

### F3 — The key-items exemption predates the one-shell ruling and collides with it

Four ratified rulings treat key items as a class: `[CEX-16]` exempts them from `convoy_capacity`
and gives them "a dedicated **Convoy Key Items view**"; `[SHP-2]` makes them unsellable;
`[EPUX-12]` excludes them from `SEND ALL TO CONVOY` **up front** rather than halting on them;
`[DTH-5]` gives them their own disposition chain with `lost` banned.

`[CEX-16]` is 2026-06-23. `[DSX-S1]` — one shell, N registered adapters, and the escape hatch is
*declared*, never improvised — is 2026-08-15. A "dedicated view" is now either a facet of the pool
region or exactly the bespoke screen that ruling forbids. And across all four rulings **nothing says
how an item joins the class**: whether `key` is an author flag on the item definition, a campaign
registry of ids, or derived from being referenced by a story predicate.

### F4 — The restock cadence reference is named, but has no semantics

The 2026-08-18 boundary ruling put `quantity` on `ShopStockEntry` (default `unlimited` sentinel)
"plus a restock cadence reference", and homed the trigger engine at `PREP-V1-S01` with stock as one
subscriber of four. `[EPUX-16]` ruled restock author-defined, defaulting to infinite. The cadence
engine itself — counter families, predicate triggers, latching, OR-composition, durable state — is
fully ratified in `EPUX` §Node traversal and cadence model, and is **not** reopened here.

Two things the reference does not yet have:

1. **Where it lives.** `[EPUX-16]` says shared finite stock depletes across surfaces and restock
   applies to the shared pool, which points at the stock *entity*; the field landed on the stock
   *entry*. Both can be true — an entity cadence with a per-entry override is the obvious shape —
   but no ruling says so.
2. **What a tick does.** Reset to the authored quantity, add N up to a ceiling, or re-roll the
   entry set. These are different economies, and the third is how a genre secret shop works.

**Measured:** `scripts/resources/shop/ShopStockEntry.gd` **does not exist**. The quantity field is
plan text, not code, so the schema can still be shaped by this walk rather than migrated after it —
which is the same argument the boundary ruling itself made about shipping a schema with nowhere to
put a count.

### F5 — Remaining stock is not one of the cap model's caps

`[DSX-S19]` enumerates six caps and stock is not among them. Yet remaining stock is a number the
player must read before committing, its default value is the `unlimited` sentinel the same ruling
invented a hatched bar for, and `[DSX-S20]` would make an after-action projection mandatory on
every single purchase if stock is a cap figure.

Extending the model is the consistent answer and probably the right one, but it is a real cost —
a projection on every purchase row — and it was never put to the owner because stock was not in
front of the `DSX` walk.

### F6 — A sold-out row inherits its vocabulary, but not its words

`[EPUX-07]`, `[RPD-15]` and `[DSX-S21]` give one availability vocabulary: absent hides, gated shows
**disabled with a reason**, and disabled entries are focusable but not activatable. A sold-out stock
row is gated, so the shape of the answer is inherited and is not a question.

The *reason string* is. "Sold out" is producible today; "restocks next chapter" requires the shop to
disclose its cadence, and a cadence keyed on `deployments_total` or `hours_played` cannot be phrased
in chapters at all. Whether the engine may disclose a restock schedule — and whether an author can
suppress it — is an authoring decision with no precedent in the corpus.

### F7 — Buyback has no ruling anywhere, and three ratified rulings meet inside it

Nothing in `SHP-1..6`, `SAC-5..9`, `EPUX-13..17`, `TSV` or `DSX` says whether selling an item adds
it to the shop's stock. The question is not cosmetic once the other rulings are in place:

- `[SHP-6]` prices sells at 50% of value **scaled by percent durability remaining**, so a
  buyback-bearing shop must decide what a 3/40 iron sword costs to buy back, and from which formula.
- `[EPUX-16]`'s finite stock is shared across surfaces, so a sold entry appears at the on-map
  storefront too.
- A restock tick under `F4` must decide whether player-sold entries survive it.

An engine with no buyback is a defensible answer; an engine that grows one by accident, one slice at
a time, is not.

### F8 — Sell-side presentation was never given `[EPUX-17]`'s split

`[EPUX-17]` ruled **final price in the list, full formula in the detail pane** — authored, and
walked, as a buy question. `[SHP-6]` then gave the sell side three composable terms: the campaign
formula (50% × durability%), the shop's **incoming**-price modifier symmetric with the buy-side
`[SAC-5..9]` modifiers, and a per-entry `sell_yields` override that wins before the incoming
modifier.

Symmetry is the likely answer, but it is not automatic: the sell view lists **the shopper's whole
inventory**, not stock, which is a different list with different rows — the reason `[SHP-6]` had to
be raised at all.

### F9 — The battlefield convoy has a surface, a trigger and a verb set, but no action economy

`EPUX` made mid-battle convoy access an **aura effect** reusing the existing radius machinery;
`[DSX-S17]` gave it a context-declared Deposit/Withdraw verb set; `[DSX-S16]` put it in the canvas
region with `SHC-5`'s landscape rail; `[CNV-5]` bars browsing other units' inventories mid-battle.

No ruling says whether using it **costs the unit's action**, whether it may follow movement, or
whether `[DSX-S18]`'s position-commit consequence line applies. That is not a presentation detail:
a free convoy is a fundamentally different battlefield rule from one that costs a turn, and it is
the kind of rule that gets decided by whoever writes `TurnManager` first.

**Measured:** `TileActions.gd` returns `false` for `shop`, `visit` and `activate` — all three are
declared placeholders with no gate, so nothing in code has taken this decision by default yet.

### F10 — Over-capacity is reachable today, and the tray's gate does not cover it

`[DSX-S21]` homes the pending-items tray in the holder region and gates prep exit through the
ordinary availability predicate. `EPUX` sets the default policy to hold-pending.

Neither covers the two ways a holder ends up over its cap without any transfer having happened:
`GameState.active_mid_map_rule_overrides` already overrides `max_inventory` mid-map
(`test_mutable_campaign_state.gd:90` sets it to 11), and a campaign update can lower a cap under an
existing save. And **quit-to-menu is not prep exit**, so a player can leave with a non-empty tray
through a door the gate does not watch.

## 3. Cited, never restated

The packet cites and does not reopen: `TSV-1..24` and `[TSV-19]`/`[TSV-21]`/`[TSV-24]`;
`SHC-1..8`; `CUR-1..7`; `DSX-1..28` and `[DSX-S1]`..`[DSX-S29]`; `EPUX-01..28`, in particular
`[EPUX-09]`..`[EPUX-17]`, `[EPUX-21]` and the cadence model; `CNV-1..8`; `SHP-1..6`; `SAC-5..9`;
`CEX-16`; `DTH-1..6`; `IEQ`; `RPD-14`/`RPD-15`; `L10N-7`'s 1.4× extent.

Two are load-bearing enough to restate as constraints rather than citations: **`[DSX-S1]`'s declared
escape hatch** bounds every answer below — widen the shell or use the declared opt-out, never a
bespoke screen — and **`[DSX-S6]`'s no-engine-confirmation rule** means no answer here may introduce
a confirm keyed on cost or irreversibility.

## 4. Walk order

Convoy first, per the ruled internal section order — items need a home before they can be bought.

1. `CVS-1`..`CVS-4` — convoy: accounting unit, key items, over-capacity, battlefield action economy.
2. `CVS-5`..`CVS-8` — stock and cadence: the cap model, restock semantics, disclosure, buyback.
3. `CVS-9`..`CVS-10` — the two that need both halves settled first: quantity under three clamps,
   and sell-side presentation.

`CVS-1` is the hinge: `CVS-3`, `CVS-5` and `CVS-9` all read differently depending on what a unit of
capacity is.
