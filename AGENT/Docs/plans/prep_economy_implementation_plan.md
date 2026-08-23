---
Role: dated
Type: plan
Status: Active — authored 2026-08-17 against EPUX-1..28, TSV-1..24, SHC-1..8, CUR-1..7, DSX-1..29 and RPD-1..18; its three owner calls ruled and applied 2026-08-18
Last verified: 2026-08-17
Decision source: ../design/prep_economy_bundle_comparative_research_and_questions_2026-07-25.md (EPUX-1..28)
Tracker: PREP-ECONOMY-IMPLEMENTATION-PLAN-2026-08-17, EPIC-PREP-ECONOMY-V1, PREP-V1-S01..S08
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
---

# Prep, Explore, Economy, Inventory and Forging — Integrated Implementation Plan

> **Why this document exists.** `R1`'s precedence diff
> ([`r1_plan_corpus_precedence_diff_2026-08-17.md`](../design/r1_plan_corpus_precedence_diff_2026-08-17.md)
> §4.2) set out to re-derive "the prep/economy plan" and found **there was no such document**.
> What stood between twenty-eight ratified rulings and eight open tracker rows was §6 of
> [`recent_research_implementation_portfolio_review_2026-07-27.md`](recent_research_implementation_portfolio_review_2026-07-27.md)
> — eight numbered paragraphs, last verified 2026-07-27, citing no register at all. The owner
> ruled on 2026-08-17 (§6.1) to **write the standalone plan** rather than amend those paragraphs
> in place. This is that plan, and it supersedes §6 of the portfolio review as the decision source
> for `PREP-V1-S01..S08`.
>
> The eight paragraphs are not merely old. Four registers have ruled on this line since they were
> written — `TSV` and `CUR` and `RPD` on 2026-08-13, `SHC` on 2026-08-13, `DSX` on 2026-08-15 —
> and the paragraphs' silence about them is indistinguishable from currency, which is the blind
> spot `R1` §1.2 describes. §2 below is the divergence list, discharged here.

## 1. Outcome

One responsive, controller-first prep hub with a flat, author-ordered activity list per node and
an optional overworld map between nodes. Six top-level entries, subject-first Explore, an open
registry of roster-config panels, and one explicit advance action. Every surface that moves a
limited thing onto a holder — convoy, shop, forge, Trade, provider convoy, loadout, skills,
techniques, battalions — is **one shell with registered adapters**, not nine screens. Every
transaction quotes, commits atomically and immediately, and explains every refusal in one reason
vocabulary shared with availability gating. Reversal is a single activity-entry snapshot reviewed
at the exit, never a per-purchase undo.

This line **owns six shared primitives that four other epics consume by name** (§6). That is the
reason the plan matters beyond tidiness: with no plan, their assignment to slices was implicit,
and `R1` found three of the four it checked scheduled with the consumer at or before the producer.
This plan finds **a fourth inversion inside the prep line itself** (§6, row 4) that `R1`'s table
recorded as correct because it only checked the `DRC` consumer.

## 2. What the eight paragraphs said, and what is ratified now

The paragraph numbers are §6 items 1–8 of the portfolio review. "Holds" means the sentence
survives re-derivation unchanged and needs no further reading.

| # | What §6 said | What is ratified now | Where |
|---|---|---|---|
| 1 | "build top-level Prep with Explore, Manage Roster, **Map Preview**, and authored advance actions" | Six named entries — Explore / Manage Roster / Map Preview / Save / Move to Next Primary Story Chapter / Start Battle — each gated by a **per-node predicate**, with non-battle nodes hiding the battle-only entries. "Authored advance actions" is two specific actions, not a family. **Map Preview is a canvas**, so the pane model does not apply inside it, and it belongs to `B4-PREP-MAP-DEPLOYMENT`, not to this slice | `EPUX` §Top-level node menu; `[RPD-1..4]`; `[EPUX-03]` |
| 1 | "cadence patches" | Cadence is a **general node-scheduling trigger engine** — counters (`chapter_reached`, `chapters_elapsed`, `deployments_total`, `hours_played`) and shared-registry predicates, latching by default with an author `reversible` flag, OR-composed. Stock is one subscriber among four (activity set, battle target, activity variant, stock) | `EPUX` §Node traversal and cadence model |
| 1 | *silent on availability* | `[EPUX-02]`'s two-state rule — absent hides, gated shows disabled-with-reason — uniform across four surfaces, with a per-entry `visible-disabled-with-reason` (default) or `hidden-until-met` presentation, **evaluated in the shell** so adapters cannot drift. Disabled entries are **focusable but not activatable** | `[EPUX-02]`, `[EPUX-04]`, `[EPUX-07]`, restated `[RPD-15]` |
| 2 | "Adopt subject-first Explore and list/detail/action patterns" | Holds, **plus a pane budget**: at most two panes pairing adjacent levels of the five-level Explore chain, never three, with a **registry-declared** full-width escape hatch for content-dense panels. And the Explore node gains a **generated submenu** supplying the landing facet and landing tab, derived from stock metadata | `[EPUX-03]`; `[SHC-3]`, `[SHC-8]` |
| 3 | "instance-preserving convoy … capacity, safe overflow, key-item … filters and transfer transactions" | Holds, and gains: display-stacking **only on identical effective state** with deterministic expansion to exact instance IDs before commit; the two named bulk operations **Send All to Convoy** and **Resupply**; the pending-items tray as a **holder-region section** gated through the ordinary availability predicate; capacity counted in **instances** (`[CVS-S1]`) with capacity-exemption a **per-instance property** and the Key Items view a **pool facet**, never a sub-view (`[CVS-S2]`) | `[EPUX-10]`/`[TSV-11]`; `[EPUX-12]`; `[EPUX-11]`/`[DSX-S21]`; `[TSV-18]`/`[CEX-16]` |
| 3 | *silent on the surface itself* | **The convoy is the first consumer of a shell no plan builds.** `[DSX-S1]` ruled one shell with N registered adapters — holder · pool · detail, shell-owned verb slot capped at two verbs — across nine consumers. See §6 | `[DSX-S1]`, `[DSX-S2]`, `[DSX-S3]` |
| 4 | "Deliver FE7 Trade and designated-provider Convoy through the DRC integrated plan" | **The intent was right and the row was wrong.** `PREP-V1-S04` duplicated `DRC-V1-S05` and was closed 2026-08-17. Trade now also inherits: second holder as a **group header inside one pool**, canvas region only with a landscape vertical rail, **one adapter with a context-declared verb set**, and the position-commit warning as an ordinary consequence line rather than a dialog | `R1` §6.2; `[DSX-S15]`..`[DSX-S18]` |
| 5 | "Land **owner-ref wallets** … before Shop UI" | Superseded by **multi-currency** `CUR-1..7`: the shop declares a **primary** currency and the header shows that one figure as a **button** opening a scrolling popup of every *holding* — currencies **and** consumable/transformable inventory. The accepted set stays **derived** from stock costs; the primary is validated against it and defaults to the most-priced-in resource, falling back to `party_gold` | `[CUR-1]`, `[CUR-2]` |
| 5 | "atomic quote/commit/**refund**" | **Refund is not the reversal mechanism.** `[TSV-21]` ruled reversal is whole-activity snapshot restore; per-receipt undo does not exist. `ResourceLedger.refund()` stays an engine capability and is never the player's undo | `[TSV-21]`, `[EPUX-28]` |
| 5 | "shopper/**destination** selection" | **Destination is never prompted for.** It is the subject inherited from Explore; pricing subject, source holder and recipient stay distinct concepts bound from one inherited value. Unit-capacity overflow goes to the convoy silently and is reported after the fact | `[TSV-15]`, `[EPUX-13]`, `[TSV-16]`/`[EPUX-11]` |
| 5 | "bulk quantity primitive" | The stepper starts at 1 and **steps backward to a live effective maximum**, and it appears **only on infinite-stock, unstateful items**, firing **N separate atomic transactions**. Never partial; every commit re-quotes and a material change stops and asks again | `[EPUX-21]`, `[TSV-12]`, `[TSV-4]`, `[TSV-5]` |
| 5 | *silent on chrome* | `SHC-1..8` ruled a **measured** package: subject folds into the app bar, tabs and filters merge into one control row, landscape chrome becomes a vertical rail, the app bar collapses after first scroll with a `prefers-reduced-motion` path, and the rows carry affordability. Chrome 190 px → 111 px at the floor | `[SHC-1]`..`[SHC-8]` |
| 5 | "receipt/failure feedback" | `[TSV-19]`: nothing to cancel mid-panel — leave with no prompt if nothing happened, otherwise **confirm/revert on the way out**, and revert leaves the player *in* the store. `[TSV-20]`: one summary line per transaction expanding to the full audit payload. `[DSX-S26]`: a no-receipt store carries a **persistent detail line above the verb** plus a one-time entry notice | `[TSV-19]`, `[TSV-20]`, `[DSX-S26]`, `[DSX-S27]` |
| 6 | "Generic availability/requirements/cost/result contract; subject-first Training Hall … map-placement as an activity property; activity entry snapshot/exit receipt/rollback where authored" | **Holds** — it was written the day after the `EPUX` walk closed. Detail it does not carry: author-labelled sections with **registered benefit presenters**; the `[EPUX-17]` list/detail split reused for forecasts; the per-unit activity budget as an **ordinary wallet resource** refilled by cadence; the entry snapshot as an autosave on a **new activity-entry trigger** | `[EPUX-20]`, `[EPUX-19]`, `EPUX` §Explore, `[EPUX-06]` |
| 7 | "point-allocation upgrade and repair" | Reads as if allocation is the v1 operation. `[EPUX-23]` ruled **all three ship before v1, in the order A → C → B** — fixed `+N`, then transform recipe, then budgeted allocation — chosen so each proves the next one's hard part. Sequencing, not scope | `[EPUX-23]` |
| 7 | "Reuse item picker … subject-scope the selected item" | The picker has **no scope rule of its own**: subject = convoy reaches convoy inventory at that subject's prices, subject = unit reaches that unit's items at that unit's prices. Subject determines **reach and pricing together**, exactly as for the shop | `[EPUX-25]` |
| 7 | *silent on operation presentation* | **Sections plus registered presenters**, mirroring `[EPUX-20]` — explicitly *not* Upgrade/Modify sibling views, which would add a third navigation level the pane budget forbids | `[EPUX-26]` |
| 7 | "no V1 rename" | Holds. Automatic canonical naming (`Iron Sword +2`); the alias was gated on the text-entry research row, **which resolved 2026-07-26** — the gate is now satisfiable, but the v1 cut stands until an owner reopens it | `[EPUX-27]`, `TEXT-01..15` |
| 7 | *silent on permanence* | `[EPUX-28]`: **permanent means permanent after the receipt is accepted**. Within a receipt-bearing forge visit the player may revert to the entry snapshot. No reset recipe in the first slice | `[EPUX-28]` |
| 8 | "Prison … only after Dialogue, requirements, relationships, inventory disposition, and activity resolution exist" | **Holds unchanged.** Composition slice, almost no unique mechanics | `DRC` §Slice 10 |
| — | Cross-bundle gates: migrations need every live consumer; rollback restores RNG and refuses nested gates; one scheduler vocabulary; no mutation during preview | **All four hold**, and each is now traceable to a ruling rather than to a review note | `[EPUX-06]`, `[EPUX-16]`, `[TSV-2]` |

Items 4, 5 and 7 each described a selection flow of its own. `[DSX-S9]` has since ruled all three
into **one dependent-choice layer** — see §6.

## 3. Current code and stale assumptions

Verified against the tree at `agent/integration` on 2026-08-17.

### Reusable foundations already present

- **`PrepActivityRegistry`** (`scripts/resources/PrepActivityRegistry.gd`, 62 lines) is already the
  ratified shape: engine registers panel factories, authored data selects a `panel_type` and
  supplies params, and the registry deliberately stores no UI or save state. Unknown panel types
  fail `validate_activity()` before a panel is created, which is `[EPUX-20]`'s "fail validation
  loudly *before* the player enters the panel" for the panel layer. **Build on it; do not replace
  it.** `B3-PHB-REGISTRY-2026-07-19` is closed.
- **`ResourceLedger`** (`scripts/autoloads/ResourceLedger.gd`, 178 lines) already does
  quote-equals-commit over `CostSpec` aggregates, resolves wallets through `RegistryManager`'s
  `resource_types` entries, refuses to overdraw, and returns structured `shortfalls`. This is the
  spine of `[EPUX-24]`; it is not yet the whole of it (below).
- **`CostSpec`** credits on negative amounts, which is what makes `[CUR-6]`'s money-changer a
  normal shop rather than a feature.
- **`RegistryEntry.label_key`** exists, so `[CUR-1]`'s renderer has the field it needs.
- **`DeploymentPlan`** (`scripts/shared/DeploymentPlan.gd`) validates against party,
  `player_start_tiles` and node constraints; `[RPD-6]` names it as already-built.
- **`SaveData` already carries the durable convoy shape** — `party.convoy.entries` with per-entry
  validation, plus `party.resources`, `bonus_exp` and `training_purchase_counts`. The schema is
  ahead of the runtime, which is the cheap direction.
- **`CampaignManager` dispatches autosave triggers** from a named list at `CampaignManager.gd:67`
  — `battle_start`, `battle_end`, `menu_area_exit`, `shop_exit`.

### Assumptions this work must replace

1. **`InventoryEntry` has no stable instance identity.** There is no `instance_id` field on
   `InventoryEntry` and no item-instance id anywhere in `scripts/resources/`, `scripts/items/` or
   `scripts/units/`. Four ratified rulings require one — `[TSV-10]`'s selector contract,
   `[TSV-11]`'s "expands to exact instance IDs before commit", `[EPUX-10]`'s effective-state
   stacking key and `[EPUX-25]`'s "stable instance IDs are retained". **This is the single
   largest schema debt on the line** and it gates the convoy, the shop, the forge and Trade.
2. **The convoy is a save shape with no runtime.** `GameState.party_items: Array[String]` is the
   whole of it, converted to and from `party.convoy.entries` by
   `_party_items_to_convoy_entries()` (`GameState.gd:1177-1197`), whose own comment says it is
   temporary "until the full convoy system owns richer `InventoryEntry` state". There is no
   capacity, no owner, no per-instance state, no transfer command.
3. **`ResourceLedger` is a wallet, not a transaction core.** `_resolve_wallet()` handles exactly
   two primitives — `party_gold_wallet` and `unit_gold_wallet` — and the atom contains wallet
   records only. `[EPUX-24]`/`[TSV-3]` require **stock, capacity, destination and forge mutation
   to join the wallet inside one operation**. That participant registry does not exist.
4. **`ResourceLedger.reserve()` is a hold that holds nothing** — it sets `transaction.reserved`
   and returns, with a comment saying no consumer needs held balances. It has **zero callers**.
   `[TSV-1]` rejected "reserved" as a false promise and `[TSV-2]` ruled holds moot. **Delete it**;
   leaving a named hold API invites someone to implement one.
5. **`CostSpec.allow_partial` is declared and never read** — zero consumers. `[TSV-4]` ruled
   *never partial, no `allow_partial`*. **Delete the field** in the same change, for the same
   reason.
6. **`MapMenu.gd:75-79` assumes gold is universal.** `_refresh_resource_summary()` calls
   `format_party_gold(gs.party_gold)`, a static returning `"Total gold: %d"`. `[CUR]`'s
   consequence 2 identified this as the whole migration and it is accurate: the engine was never
   gold-only, only this label is.
7. **`ResponsiveLayout` derives its class from logical width alone** (`ResponsiveLayout.gd:167-171`,
   three classes with hysteresis). `[SHC-4]` is the first deliberate override of the width-derived
   class **by a height rule**, so the composition selector needs an explicit **landscape
   predicate**. Inventing a local width threshold would repeat the mistake `[UUI-11]`'s `dense`
   token column was added to avoid.
8. **`ModalScreen._is_focus_disabled()` implements the ratified rule backwards** — it *excludes*
   disabled buttons from focus traversal, against `[EPUX-07]`/`[RPD-15]`'s focusable-but-not-
   activatable. This is shell-level and affects all five availability surfaces, so it is **owned by
   `SHELL-FOCUSABLE-DISABLED-ENTRIES-2026-08-17` and consumed here**, never fixed per adapter.
9. **`PrepScreen.gd` (338 lines) is built against the superseded deployment design.** It is a
   migration owned by `B4-PREP-MAP-DEPLOYMENT`, not by this line; see
   [`b4_prep_deployment_handoff_2026-07-14.md`](b4_prep_deployment_handoff_2026-07-14.md).
   The boundary is stated in §7 `S01`.
10. **`InventoryEntry.forged_mods: Dictionary` is reserved and unread.** It is where `[EPUX-23]`'s
    per-instance overlay lands; nothing reads it today, so the forge slice defines its shape.
11. **No on-map shop, no stock entity, no wallet beyond gold, no benefit provider, no forge
    service exist.** The `shop`/`activate` interactive configs of `SAC-1..12` are designed and
    unbuilt.

## 4. Architecture and ownership

### 4.1 One shell stack, three layers

`[EPUX-04]` ratified shared presentation primitives with domain-owned adapters; `[DSX-S1]`
ratified one distribution shell with N registered adapters. These are **not two shells** — they
are two layers of one stack, and the plan states the relationship explicitly because nothing in
either register does:

1. **Record-screen primitives** (`UIREC-V1`) — pure screen state, controller read models, action
   descriptors, wide/narrow composition adapters, list/detail/action components, input and scale
   contracts. Owns presentation state only; no domain knowledge.
2. **The distribution shell** (`[DSX-S1]`..`[DSX-S3]`) — a *consumer* of layer 1 that fixes three
   regions (**holder · pool · detail**), owns composition, focus, the reason vocabulary, capacity
   presentation and a verb slot **capped at two verbs**, and renders every consumer's empty state
   rather than letting a consumer change layout. The escape hatch is **declared, never improvised**
   — either widen the shell for everyone or take a declared opt-out, on `[EPUX-03]`'s full-width
   precedent.
3. **Adapters** — convoy, shop, forge, Trade, provider convoy, loadout, skills, techniques,
   battalions. An adapter supplies the pool, the holder, the detail sections, verb labels, a
   predicate and its player-facing unmet reason. It supplies **no layout and no gating treatment**.

The derivation is `[EPUX-04]` plus `[DSX-S2]`: holder/pool/detail is a composition *over*
list/detail, and `PREP-V1-S02` already depends on `UIREC-V1-S05`.

> **OWNER RULING 2026-08-18: the three layers are one stack, as stated above.** The distribution
> shell is a **consumer** of `UIREC-V1`'s record-screen primitives, never a peer. Neither `DSX` nor
> `UIREC` says so — `DSX` never cites `UIREC` — so this plan is where the relationship is recorded.
> Consequence for review: a distribution-shell change that cannot be expressed over layer 1's
> primitives is a signal to **widen layer 1**, not to fork a second shell.

### 4.2 The transaction core, and what joins the atom

`[EPUX-24]` ratified one shared atomic quote/commit/rollback core with thin panels. `[TSV-3]`
deferred to it and named the missing piece: a **transaction-participant registry** so stock,
capacity, destination and forge mutation join the wallet in one all-or-nothing operation.

- **States are `candidate → quote → committed`.** There is no staged state, no cart, no hold, no
  reservation and no expiry window (`[TSV-1]`, `[TSV-2]`).
- **Commit re-quotes every time**, and a material change in price, stock, capacity or eligibility
  **stops and asks again** with the differences highlighted. A changed quote is a diff to accept,
  not an error to dismiss (`[TSV-5]`).
- **Never partial** (`[TSV-4]`). A quantity that cannot be afforded or held cannot be selected,
  because the stepper's maximum is live.
- **Every quote carries one field set everywhere** — inputs/outputs, quantity, wallet
  before/after, destination, capacity/overflow, modifiers, warnings — with layout deciding
  visibility by size class, never the field set (`[TSV-6]`).
- **An after-action projection is mandatory** whenever an action changes a cap figure
  (`[DSX-S20]`). It is what makes commit-on-second-selection defensible.

### 4.3 The quantity primitive

One control, two consumers: the item shop and the unit-benefit shop (`[EPUX-21]`). Numeric field
with repeat arrows — holding an arrow scrolls the **quantity**, never the purchase. Starts at 1;
stepping **backward from 1 wraps to the live effective maximum** = min(affordable, destination
space, benefit cap), recomputed as the wallet and destination change so the wrap target is always
genuinely purchasable. Non-divisible benefits present no stepper. On the item shop it appears
**only for infinite-stock, unstateful rows** and fires **N separate atomic transactions**
(`[TSV-12]`); stateful items transact per instance.

### 4.4 One predicate registry answers four questions

`[EPUX-02]`, `[EPUX-06]`, `[EPUX-07]` and the cadence model all ride the shared condition/predicate
registry. One registration serves:

| Question | Ruling |
|---|---|
| May I see it? | `[EPUX-02]` — absent hides, gated shows disabled-with-reason, per-entry presentation |
| Why not? | `[EPUX-07]` — one unified reason contract, **not** a parallel transaction vocabulary |
| Must I confirm it? | `[EPUX-06]` — authored on the action, plus scopeable declarative threshold rules |
| Has the node advanced? | `EPUX` cadence — predicate triggers, latching by default |

Two boundaries the engine must never let an author weaken. **Transactional** failure —
insufficient funds, full capacity, failed eligibility — is always disabled-with-reason and never
hidden (`[TSV-13]`); the author controls what stock exists, the engine controls whether the player
can afford it. And **per-action confirmation strictness is raise-only**: a player setting or an
author mark may raise it, neither may lower it below the authored default.

`ENGINE-PREDICATE-UNMET-REASON-2026-07-26` is the row that gives predicates a player-facing reason
string. A predicate that cannot explain itself can only be authored `hidden-until-met`, and
`hidden-until-met` must not become the authoring-template default.

The eight minimum reasons are members of that one contract: insufficient resource, missing
material, destination full, cap reached, gate unmet, unsellable, invalidated quote, save failure.
Under `[CUR]` a shortfall reason must also name **which** resource is short, and where several are
short the row carries the largest — *most short relative to what is held*, since `[CUR-6]` leaves
deliberately no exchange rate to compare across.

### 4.5 Snapshot, receipt and reversal

There is exactly one reversal mechanism and it is not per-transaction.

- Entering an **author-gated** activity takes **one snapshot** — an ordinary autosave on a **new
  activity-entry trigger** added to `CampaignManager.gd:67`'s list, in its own transient pool with
  its own `rule_id`, so the invariant that an autosave never overwrites a manual save holds.
- Leaving shows a **review receipt**: one summary line per transaction, expanding to the full
  audit payload — receipt ID, operation, subject, exact instance IDs, sources and destinations,
  resource and stock deltas, before/after overlays, warnings, reversibility state (`[TSV-20]`).
- The player **confirms** (accepting the visit and discarding the snapshot) or **reverts** to the
  entry state — and revert **leaves the player in the store**, free to walk out without a second
  prompt (`[TSV-19]`). No transactions this visit means no prompt at all.
- **Exactly one snapshot exists at a time**, which implies **at most one exit-gated activity open
  at a time**. If nesting ever appears, the inner gate is **refused** rather than clobbering the
  snapshot.
- **Rollback restores the RNG stream**, inherited from the ledger's existing determinism, so it is
  never a reroll lever. But determinism only covers *identical* replays, and a different choice is
  trivial inside an arena or a random forge — hence a **non-blocking author-time warning** when an
  exit gate is enabled on an RNG-bearing activity type, modelled on the durable-`mid_map` warning,
  with its check landed in the same change per DoD#2.
- **Receipt rollback is uncharged.** Rewind charges are battle-only; `rewind_charges_per_map = 0`
  already ships as the ironman preset.
- **A store may declare no receipt at all**, and then nothing is reversible. Because the *absence*
  of a mechanism has to be visible, that store carries a **persistent line in the detail above the
  verb** *and* a one-time-per-visit entry notice (`[DSX-S26]`), and the shell states one of three
  reversibility classes — freely reversible, reversible until exit, irreversible (`[DSX-S27]`).
- A **player setting may auto-accept receipts**. This does not breach raise-only, because the
  receipt is a review-and-rewind surface rather than a confirmation (`[TSV-21]`).
- Crash or unclean quit needs no special case: existing relaunch-and-resume restores the player
  with the snapshot live and rollback still offered.
- Player copy is **Confirm** and **Revert**. "Refund" stays reserved for the engine capability
  `ResourceLedger` already names.

### 4.6 Subject resolution

Explore is **subject-first**: pick a subject (a unit, or the convoy), then see every activity that
subject is eligible for, eligibility being a per-subject predicate. The subject then determines
**reach and pricing together** for both the shop and the forge (`[EPUX-14]`, `[EPUX-25]`).

- **Convoy subject** = the author-chosen pricing subject (quartermaster or main character). It is a
  pricing and identity subject **only, never an access gatekeeper**; losing them never bricks the
  convoy, and pricing falls back to a neutral default.
- **Unit subject** = that unit's own items at that unit's prices.
- **On-map surfaces** resolve the subject as the adjacent unit.
- **Subject memory** is firm within a prep visit, best-effort across visits, falling back to the
  first available subject. `[RPD-14]` generalizes the same tiering to the deployment plan, per
  slot. Both are marked provisional for playtest refinement.
- **Convoy disabled** (author toggle) cascades automatically: unit-full hard-blocks with a reason,
  shops fall back to shopper-only buy-to-unit, the convoy is not a selectable Explore subject, the
  forge is therefore per-unit-only with no extra rule, convoy-access auras go inert, and authoring
  tools warn at author time if a no-convoy campaign ships convoy-access skills.

### 4.7 Cadence and node traversal

The node interior is a flat, per-node authored activity list; movement between nodes is strict
linear advance by default, with an **optional author-enabled overworld map** that permits revisits.
The map is a **responsive canvas screen**: its chrome follows the shared UI size classes and its
graph region uses canvas pan/zoom behaviour. A revisit re-enters the cleared node's prep hub rather
than exposing a second activities-only navigation path.
Re-entry defaults keep free revisit safe: shop nodes persist stock and restock on cadence
(defaulting to infinite/non-scarce), battle and story nodes are one-shot unless marked repeatable,
event nodes fire once unless marked re-fireable.

Cadence is one trigger engine with four subscriber properties (available activity set, battle
target, activity variant, stock), counter and predicate trigger families, latching by default with
an author `reversible` flag that **governs future availability only** — content already consumed
stays consumed. Multiple triggers OR together.

Entering a revisited node evaluates cadence but increments no chapter or deployment counter. If the
player subsequently launches a battle, that real deployment event advances deployment cadence.

**Real-time cadence is deferred post-v1.** The schema defines it; it ships **disabled behind a
mockable, injectable clock seam**, because a real-time base needs a trusted clock, rollback-tamper
handling and offline accrual, and would make tests non-deterministic.

### 4.8 Wallets and currency

The engine was never gold-only — `resource_types` is a registry with `subjects` and a
`primitive_handler`, and `CostSpec` names a `resource_id` and a `scope`. Only the UI assumes gold.

- The shop **declares a primary** currency; the header shows that one figure, **abbreviated**
  (exact below 10,000, compact above), as a **button**.
- The button opens a **scrolling popup of everything the player holds that a transaction could
  spend** — currencies first, then consumable and transformable holdings. `kind == "wallet"` orders
  and labels; it does not exclude. The popup is authoritative and unabbreviated, and is bounded by
  the game-view rect: a sheet at Compact, a centred card elsewhere.
- **Abbreviation is opt-in per call site**, never a formatter default, so rounding cannot leak into
  the price breakdown, the consequence preview or the shortfall.
- The **accepted set is derived** from the stock's costs. A declared primary that prices nothing is
  an authoring **warning**, not a failure; an undeclared primary defaults to the resource the
  largest share of stock prices in, falling back to `party_gold`.
- A row shows **two price terms inline, primary first, then `+N`**.
- A **unit-scoped** cost resolves the wallet through the current subject and labels it by owner.
- There is **no exchange feature**. A money-changer is a normal shop whose offers spend one
  resource and credit another; **one authored example ships in a demo pack** so the pattern is
  discoverable rather than folklore.

## 5. Data and save contracts

### Schema changes owed

| Change | Why | Slice |
|---|---|---|
| `InventoryEntry` gains a **stable instance id** | `[TSV-10]`, `[TSV-11]`, `[EPUX-10]`, `[EPUX-25]` | `S03` |
| Convoy becomes a real runtime entity — owner ref, capacity (default unlimited), per-instance entries — retiring `GameState.party_items` | `[EPUX-11]`, `[EPUX-14]`, `EPUX` §Convoy model | `S03` |
| **Stock as a first-class named entity**, with durable counts, referenced by more than one frontend | `[EPUX-16]`, `EPUX` §Shops and stock | `S05` |
| **Cadence state** — counter values, latched predicate states, consumed/played flags, per-node variant pointer | `EPUX` §Node traversal | `S01` |
| **Activity definition and state shared across surfaces**, so an activity placed on a map and reachable from Explore depletes once | `[EPUX-22]` | `S06` |
| Forge overlay lands in the reserved `InventoryEntry.forged_mods` | `[EPUX-23]` | `S07` |
| Transient **activity-entry snapshot** — own `rule_id`, own pool, never overwrites a manual save | `[EPUX-06]` | `S05` |
| `CostSpec.allow_partial` **removed**; `ResourceLedger.reserve()` **removed** | `[TSV-4]`, `[TSV-2]` | `S05` |

### Migration

Existing saves carry `party.convoy.entries` with no instance ids. Assign them **deterministically
on load** — stable across a reload of the same save, or stacking, receipts and rollback all lie.
`party.resources`, `bonus_exp` and `training_purchase_counts` already exist and are consumed rather
than added.

Wallet and storage migrations **cannot land without every live consumer**, per the portfolio
review's cross-bundle gate, which survives re-derivation.

### What is deliberately not persisted

- **The deployment plan.** `[PHB-7]` commits immediately to party state with no hub-suspend
  snapshot and re-derives on re-entry; `[RPD-18]` re-derived the same answer independently. Within-
  visit plan memory is live state discarded with the stage — **not** a save row.
- **Uncommitted proposals.** There are none to keep (`[TSV-1]`, `[TSV-24]`).
- **Receipts**, except where the owning activity's rollback window crosses a save boundary
  (`[TSV-20]`).

### State that survives recomposition

Subject, source, filters and sort, focused instance, the active quote, review position and
meaningful focus all survive responsive recomposition and a change of input mode; rotating a phone
or switching from touch to a pad mid-purchase costs the player nothing (`[TSV-24]`). Stepping back
from detail to pool restores focus to the row that was open, and stepping back out of a dependent
set **keeps the pinned pick** (`[DSX-S13]`). This requires the stable instance ids of §5 and real
focus restoration.

## 6. The six shared primitives this line owns

The `DRC` plan's own decision-source gate states that the primitives it consumes are "owned by the
prep/economy line". With no plan, that ownership was a sentence rather than a schedule. It is a
schedule here.

| # | Primitive | Ruling | Producer | Named consumers |
|---|---|---|---|---|
| 1 | Atomic transaction core + participant registry | `[EPUX-24]`, `[TSV-3]` | `PREP-V1-S05` | `DRC-V1-S05` (Trade), `PREP-V1-S06`, `PREP-V1-S07` |
| 2 | Quantity primitive | `[EPUX-21]`, `[TSV-12]` | `PREP-V1-S05` | item shop, benefit shop, `DRC-V1-S05` |
| 3 | Pending-items tray | `[EPUX-11]`, `[DSX-S21]` | `PREP-V1-S03` | `DRC-V1-S09` (map-end overflow) |
| 4 | Activity-entry snapshot + exit receipt | `[EPUX-06]`, `[EPUX-28]`, `[TSV-19..21]` | `PREP-V1-S05` **(moved from `S06` 2026-08-18)** | `PREP-V1-S05` (shop), `PREP-V1-S06`, `PREP-V1-S07` (forge), `DRC-V1-S10` |
| 5 | **Distribution shell** (holder · pool · detail, verb slot) | `[DSX-S1]`, `[DSX-S2]`, `[DSX-S3]` | `PREP-V1-S02` **(assigned 2026-08-18)** | convoy `S03`, shop `S05`, forge `S07`, `DRC-V1-S05`, plus loadout / skills / techniques / battalions outside this epic |
| 6 | **Dependent-choice layer** | `[DSX-S4]`..`[DSX-S9]` | `B4-PREP-MAP-DEPLOYMENT` **(assigned 2026-08-18)** | deployment placement (**consumer 1, ships first**), convoy transfer into a full holder `S03`, forge `S07`, Trade `DRC-V1-S05`, cap-full replacement outside this epic |

**Row 4 is a new finding, and it is the inversion `R1` did not catch.** `R1`'s table recorded
`[EPUX-06]`'s edge as the one correct one, because it checked only the `DRC` consumer at `S10`.
Inside this line the shop at `S05` needs the receipt too — `[TSV-19]`'s confirm/revert-on-exit is
the shop's exit behaviour and `[DSX-S26]`'s no-receipt disclosure is a shop obligation — and `S06`
is scheduled **after** `S05`. The producer must move to `S05`, which also puts it beside the
transaction core whose commits it reviews. `DRC-V1-S10`'s edge survives, since `S10` depends on
`S06` which depends on `S05`.

**Rows 5 and 6 are primitives no plan builds.** `[DSX-S1]` was ruled 2026-08-15, three weeks after
the paragraphs; a corpus-wide search finds **no plan citing it**. Left unassigned, the program
acquires the several separate selectors `UBS-2` was written to prevent — and it would acquire them
from *this* line, since convoy, shop and forge are three of the nine consumers.

**Row 6 carried a live sequencing hazard, now resolved by assigning the producer upstream.**
`[DSX-S9]` names deployment placement as a consumer and requires the layer to **absorb `RPD`'s
select-then-select gesture rather than ship a second implementation of it**. But
`B4-PREP-MAP-DEPLOYMENT` is a **v0.8.0** row and the whole `PREP-V1` line is not, so the gesture
ships **before** any slice that could have owned the layer.

> **OWNER RULING 2026-08-18: `B4-PREP-MAP-DEPLOYMENT` builds the dependent-choice layer**, with
> deployment placement as **consumer 1**. It builds the state machine either way; building it
> behind the shared interface costs little now and removes a migration later. The alternative —
> build it locally and extract it at `PREP-V1-S03` — is the consumer-before-producer shape `R1`
> found three times in one graph, and `[DSX-S9]`'s "absorbs rather than ships a second
> implementation" would then be a promise rather than a structure.
>
> **What this obliges `B4` to do**, beyond what its re-derived handoff already scopes: build the
> gesture as `[DSX-S4]`'s **one state machine, one commit rule, one cancel rule**, with the kind
> (*counterpart* vs *operation*) selecting only how the second set's rows render; put the second
> set in the **pool region** and the result plus commit verb in the **detail** (`[DSX-S5]`); take
> the first pick as **focus, not a reservation**, with the vocabulary fixed as **pinned**, never
> "staged" (`[DSX-S7]`); treat the **empty slot as an entry in the set** so one gesture covers gift
> and swap (`[DSX-S8]`); add **no confirmation of its own** (`[DSX-S6]`); and keep the pinned pick
> when stepping back out of a dependent set (`[DSX-S13]`).
>
> **Boundary that keeps this affordable.** `B4` owns the *layer*, not the *shell*. Deployment
> placement is a canvas surface (`[RPD-1..4]`), so it consumes the layer's state machine without
> needing `[DSX-S1]`'s holder/pool/detail composition, which stays at `PREP-V1-S02`. If that split
> proves unworkable in build, the escalation is to widen `PREP-V1-S02`'s scope — never to let `B4`
> grow a second shell.

## 7. Dependency-ordered implementation slices

Each row below re-scopes an existing tracker row. Tracker edits owed are listed in §11.

### `PREP-V1-S01` — Prep shell, node menu and activity resolution

The six top-level entries, each gated by a per-node predicate, with non-battle nodes hiding
battle-only entries; campaign activity defaults; node add/remove/override patches; and the cadence
trigger engine with its durable state. Availability follows `[EPUX-02]` evaluated **in the shell**
per `[EPUX-04]`, with per-entry `visible-disabled-with-reason` / `hidden-until-met`.

**Boundary with `B4-PREP-MAP-DEPLOYMENT`:** this slice builds the **Map Preview entry and its
gate**; the canvas behind it, the placement gesture and the readiness rules belong to that row and
its re-derived handoff. Likewise **Save** is re-homed here as a menu entry, with behaviour
unchanged from the built manual save.

Depends on: `B3-PHB-REGISTRY` (closed), `DESIGN-OVERWORLD-CADENCE-2026-07-25`,
`SHELL-FOCUSABLE-DISABLED-ENTRIES-2026-08-17`, `ENGINE-PREDICATE-UNMET-REASON-2026-07-26`.

### `PREP-V1-S02` — Subject-first Explore, the distribution shell, and record-UI adoption

Subject-first Explore with its subject picker and per-subject eligibility predicates; the pane
budget (at most two panes pairing adjacent levels, never three) with the registry-declared
full-width escape hatch; deployable members and camp followers as one subject model.

**Also builds primitive 5** — the distribution shell over `UIREC-V1`'s primitives, with fixed
holder/pool/detail regions, shell-owned reason vocabulary and capacity presentation, and the
two-verb slot. And the **generated Explore submenu** of `[SHC-3]`/`[SHC-8]`, derived from stock
metadata, supplying landing facet and landing tab.

Depends on: `PREP-V1-S01`, `UIREC-V1-S05`, `LOCALIZATION-L10N-BUILD-2026-08-17` (the 1.4× text
extent binds every component here, and `[DSX-S14]` binds the shell-owned context line inside
360 px).

### `PREP-V1-S03` — Inventory and convoy core

Stable instance ids on `InventoryEntry`; the convoy as a runtime entity with an owner ref and
capacity defaulting to unlimited; overflow to convoy; fail-before-commit at a full cap; the
**pending-items tray** as a holder-region section gated through the ordinary availability
predicate (**primitive 3**); capacity counted in instances, with the capacity exemption held as a
**per-instance property** set by the "key item" authoring preset and surfaced as a `[DSX-S23]` pool
facet rather than a dedicated view (`[CVS-S1]`, `[CVS-S2]` — which amend `[CEX-16]` and make this
slice's stable instance id load-bearing, since the properties must survive save/load and
`[EPUX-10]` regrouping); over-capacity legal, spilling to the tray at next prep entry, tray durable
in the save (`[CVS-S3]`); effective-state
display stacking with deterministic expansion; command-verb transfers as the authoritative mutation
command; the two named bulk operations reporting into `[DSX-S24]`'s dismissible result panel; the
convoy-disabled cascade; author-time warning for convoy-access skills in a no-convoy campaign.

Depends on: `PREP-V1-S02`, `B4-IEQ-ITEMS-EQUIPMENT-2026-07-23`, `B4-CONVOY-2026-07-23`, and
`B4-PREP-MAP-DEPLOYMENT-2026-07-22` for **primitive 6** (convoy transfer into a full holder is a
dependent-choice consumer).

### `PREP-V1-S04` — closed

Duplicated `DRC-V1-S05`; closed 2026-08-17 by owner ruling. Trade and designated-provider convoy
ship through the `DRC` integrated plan, now also carrying `[DSX-S15]`..`[DSX-S18]`. Battlefield
convoy access remains the aura effect of `EFFECT-CONVOY-ACCESS-AURA-2026-07-25`.

### `PREP-V1-S05` — Wallets, multi-currency, stock, Shop, and the atomic core

The transaction-participant registry so stock, capacity, destination and forge mutation join the
wallet in one atom (**primitive 1**); the quantity primitive (**primitive 2**); **the
activity-entry snapshot and exit receipt** (**primitive 4**, moved here); multi-currency per
`CUR-1..7` including the header button, the holdings popup and the opt-in abbreviation formatter;
stock as a first-class named entity with cadence-driven restock — the cadence reference on the
**entity** with an optional per-entry override, a tick **resetting** to the authored quantity by
default and **incrementing to a ceiling** where the author selects it, re-roll excluded from v1
(`[CVS-S6]`); remaining stock as a **seventh `[DSX-S19]` cap** whose projection is required only
when finite (`[CVS-S5]`); restock **disclosure** author-declared per shop, default off, phrasable
only for counter trigger families (`[CVS-S7]`); a **quantity stepper clamped to the minimum** of
affordability, remaining stock and destination capacity, naming the binding limit (`[CVS-S9]`);
sell presented symmetrically under `[EPUX-17]` with unsellable rows **gated, not hidden**
(`[CVS-S10]`); selling **final in v1**, with buyback parked as `B8-SHOP-BUYBACK` (`[CVS-S8]`);
the shop panel with Buy/Sell
sibling tabs inheriting subject and landing tab; `[EPUX-17]`'s final-price-in-list /
formula-in-detail split; the `SHC-1..8` chrome package including the landscape predicate on the
composition selector; `[DSX-S26]`'s no-receipt disclosure.

Removes `ResourceLedger.reserve()` and `CostSpec.allow_partial` in the same change.
Retires `MapMenu.format_party_gold` for a `label_key`-driven renderer.

Depends on: `PREP-V1-S03`, `IMPL-ECONOMY-WALLET-CORE`.

### `PREP-V1-S06` — Explore activities and Training

The generic availability/requirement/cost/result activity contract; the subject-first Training Hall
with author-labelled sections and **registered benefit presenters**; before→after forecasts using
the `[EPUX-17]` split; the per-unit activity budget as an ordinary wallet resource refilled by
cadence; **map placement as a property of any Explore activity**, with shared definition/state
across surfaces and the reason-keyed inactive presentation (gated → hidden, proximity →
browse-only, preview → scouting); the arena as a separate registered activity; the author-time
RNG-bearing-exit-gate warning and its DoD#2 check.

**Consumes** primitive 4 rather than building it.

Depends on: `PREP-V1-S02`, `PREP-V1-S05`, `B6-PREP-PROGRESSION-2026-07-23`.

### `PREP-V1-S07` — Forge

Subject-scoped picker (reach and pricing from the subject, no forge-specific scope rule); the
operation registry presented as **sections plus registered presenters**; the per-instance overlay
in `forged_mods` and the effective-stat resolver; automatic canonical naming; transparent
formula/cap/quote preview; permanence **after receipt acceptance**; clear consequence copy when the
chosen instance is equipped.

Operations ship in the ruled order — **A fixed `+N` → C transform recipe → B budgeted allocation**
— each proving the next one's hard part. No reset recipe in the first slice; no alias.

Depends on: `PREP-V1-S03`, `PREP-V1-S05`, and `B4-PREP-MAP-DEPLOYMENT-2026-07-22` for
**primitive 6** — the forge is the layer's *operation*-kind consumer, where deployment placement is
its *counterpart*-kind one, so the forge is what proves `[DSX-S4]`'s "one state machine, two kinds"
is real rather than asserted.

### `PREP-V1-S08` — Prison composition activity

Unchanged. The custody roster and activity compose Dialogue, requirements, relationships, inventory
disposition and activity resolution, and should contain almost no unique mechanics.

Depends on: `PREP-V1-S06`, `DRC-V1-S10`.

## 8. Low-code minimum and validation gates

Every one of these is an author-time or load-time check, and each mechanical rule lands with its
check in the same change per DoD#2.

- Unknown registered ids — panel types, benefit types, forge operations, presenters — **fail
  validation loudly before the player enters the panel**. `PrepActivityRegistry.validate_activity()`
  is the shape to follow.
- A shop declaring a **primary currency it prices nothing in** warns; it does not fail silently.
- Enabling an **exit gate on an RNG-bearing activity type** warns, non-blocking, modelled on the
  durable-`mid_map` warning.
- A **no-convoy campaign shipping convoy-access skills** warns at author time.
- **No hardcoded enums** may appear for activity, currency, benefit, category, panel or
  forge-operation vocabularies. This is the smell `AGENTS.md` names, and `[DSX-S1]`'s escape hatch
  is declared rather than improvised for the same reason.
- Categories and filters are **derived from item metadata** — presentation facets, never engine
  shop enums.
- `hidden-until-met` is never the authoring-template default.
- Every disabled action has **readable text**, not colour or icon-only meaning.
- Bulk operations are **deterministic and report every overflow and every exclusion**.
- Split-faction campaigns never show or mutate another faction's convoy or wallet.
- Quote equals commit; a stale quote fails with **no partial resource or item mutation**.
- Save/load preserves wallets, convoy entries, holders, forge operations, stock counts and cadence
  state, and training purchase counts.
- Keyboard, mouse, touch and controller reach **every** action, with a non-drag path for each.
- Wide, narrow, 100% and 200% Menu Scale preserve selection and focused region.

## 9. V1 cuts, and the seams kept open

**Cut, with the compatibility seam named:**

- **Drag and drop** — the verb path is built as the authoritative mutation command from the start,
  so a later drag layer is an additive input adapter, never a second mutation path (`[EPUX-09]`).
- **Free-text search** in stock and inventory (`[EPUX-15]`).
- **Forge alias** — automatic canonical naming only; the two-name model stays the target
  (`[EPUX-27]`).

Those three are one deferred pointer-and-keyboard tranche, deliberately grouped so v1 degrades on
no input method. `RESEARCH-TEXT-ENTRY-STRATEGY-2026-07-26` resolved 2026-07-26, so the gate is
satisfiable; the cut stands until an owner reopens it.

**Also cut:**

- **Reset/rebase recipes** in the first forge slice (`[EPUX-28]`).
- **Real-time cadence** — schema defined, shipped disabled behind an injectable clock seam.
- **Named player-authored deployment presets** — `[RPD-14]` would need its own register.
- **Multi-select, auto-equip and Optimize** — only the two named deterministic bulk operations
  (`[EPUX-12]`).
- **Any hold or reservation service** — do not reserve the API shape speculatively; the question
  becomes live again only if asynchronous or shared stock is introduced (`[TSV-2]`).
- **Per-receipt undo** — one snapshot per activity, and nothing else (`[TSV-21]`).
- **An exchange or money-changer system** — already expressible as a normal shop (`[CUR-6]`).
- **A walkable hub scene** — rejected for v1; scene-backed activities remain an optional registered
  activity type, never the mandatory shell (`[EPUX-01]`).

## 10. Completion-checklist coverage

Against the portfolio review's §10 checklist, which no product row may leave incomplete:

| Item | Where |
|---|---|
| Authoritative decisions and superseded assumptions | §2, §3 |
| Exact current code touchpoints and state owner | §3 |
| Schema/codec/migration and pack-family changes | §5 |
| Low-code authoring, validation, diagnostics, fixtures | §8 |
| Player flow, accessibility, input, localization, menu scale | §4.1, §4.4, §8; `L10N` dependency in §7 `S02` |
| Preview/commit/rollback, RNG, Save/Retry/Rewind, failure atomicity | §4.2, §4.5 |
| Automated tests and hostile/malformed cases | §8, and per-slice in §7 |
| Windows visual/playtest evidence and export validation | Owed per slice; the shell and chrome slices (`S02`, `S05`) carry measured-viewport evidence gates |
| GDD, roadmap, feature-index, control-plane, author-guide updates | DoD#1 applies per slice |
| Explicit V1 exclusions and post-v1 seams | §9 |

## 11. Owner calls — all three ruled 2026-08-18

> **ALL THREE ANSWERED BY THE OWNER, 2026-08-18, and APPLIED.** Each ruling is recorded at the
> section it governs; this section is the ledger.

1. **Where the dependent-choice layer gets built → `B4-PREP-MAP-DEPLOYMENT`**, with deployment
   placement as consumer 1. Ruling and the obligations it puts on `B4` are in §6, row 6. The
   alternative — build it locally and extract it at `PREP-V1-S03` — was the consumer-before-producer
   shape `R1` found three times in one graph.
2. **Primitive 4 moves from `PREP-V1-S06` to `PREP-V1-S05`.** Applied in §6 and §7. The shop needs
   the receipt and was scheduled a slice earlier than its producer; the primitive now sits beside
   the transaction core whose commits it reviews, and `DRC-V1-S10`'s edge survives via
   `S10 → S06 → S05`.
3. **The distribution shell is a consumer of `UIREC-V1`'s record-screen primitives, not a peer.**
   Ruling in §4.1, with the escalation path — widen layer 1, never fork a second shell.

**Tracker edits applied 2026-08-18** (all through `agent-update-task.sh`, no hand-edits):

- `PREP-V1-S01` gains `SHELL-FOCUSABLE-DISABLED-ENTRIES-2026-08-17` and
  `ENGINE-PREDICATE-UNMET-REASON-2026-07-26`. Both are `[EPUX-02]`/`[EPUX-04]`/`[EPUX-07]`
  prerequisites for shell-owned availability, and the first exists because the shipped
  `ModalScreen._is_focus_disabled()` implements the ruling backwards.
- `PREP-V1-S02` gains the distribution shell in scope and a dependency on
  `LOCALIZATION-L10N-BUILD-2026-08-17`.
- `PREP-V1-S03` and `PREP-V1-S07` gain `B4-PREP-MAP-DEPLOYMENT-2026-07-22`.
- **`DRC-V1-S05` also gains `B4-PREP-MAP-DEPLOYMENT-2026-07-22`.** Not on the pre-ruling list, and
  added deliberately: `[DSX-S9]` names Trade as a consumer of the layer, and leaving a *named*
  consumer unordered is the precise defect this plan exists to fix.
- `PREP-V1-S05` gains the snapshot/receipt primitive in scope; `PREP-V1-S06` loses it and consumes
  it through the `S06 → S05` edge that already existed.
- `B4-PREP-MAP-DEPLOYMENT-2026-07-22` records its widened scope and its new standing as the
  producer of a primitive four other rows consume.
- Every `PREP-V1` row's `decision_ref` points here rather than at §6 of the portfolio review.

**Verified after applying, over the whole 434-row graph rather than by inspection:** still acyclic,
and **all six primitives now sort producer-before-consumer** — the property `R1` found violated
three times and this plan found violated a fourth. Layering the four epics' slices:

| Primitive | Producer | Earliest consumer |
|---|---|---|
| 1 transaction core, 2 quantity | `PREP-V1-S05` | `PREP-V1-S06` / `S07` / `DRC-V1-S05`, one layer later |
| 3 pending-items tray | `PREP-V1-S03` | `DRC-V1-S09`, one layer later |
| 4 snapshot + receipt | `PREP-V1-S05` | in-slice (shop), then `S06` / `S07`, then `DRC-V1-S10` |
| 5 distribution shell | `PREP-V1-S02` | `PREP-V1-S03`, downstream |
| 6 dependent-choice layer | `B4-PREP-MAP-DEPLOYMENT` | `PREP-V1-S03` / `S07` / `DRC-V1-S05`, far downstream |

**Not changed, and deliberately so:** no `PREP-V1` row moved from `planned`, and no slice was
re-numbered. `B4-PREP-MAP-DEPLOYMENT` depends only on `B3-PHB-REGISTRY-2026-07-19` (closed) and
`R1-PLAN-CORPUS-COHESION-REVIEW-2026-08-16`, neither downstream of any `PREP-V1` row, so putting a
primitive there introduced no back-edge.
