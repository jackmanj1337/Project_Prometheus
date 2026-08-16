---
Type: design
Status: Research prepared; owner questions open
Last verified: 2026-08-12
Tracker: RESEARCH-TRANSACTION-SURFACE-2026-08-12
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Shared Transaction Surface — Comparative Research

## Purpose and dependency position

This is the base vocabulary requested by `[UBS-2]`. Shop, convoy and forge all select
item instances or offers, calculate consequences, commit mutations and explain failure.
They must not invent three meanings for the same actions. This packet settles the shared
quote/reserve/commit/refund contract and selector semantics before a downstream shop and
convoy presentation packet is drawn.

**Held downstream:** shop/convoy responsive composition, row density and wireframes remain
held until `TSV-1..24` receive owner rulings. Forge-specific operation authoring remains
governed by `[EPUX-23..28]` and `[FRG]`; this packet only defines the transaction surface
those operations use.

## Existing Prometheus contract

The implementation is already more precise than much of the older planning prose:

- `ResourceLedger.quote(costs, ctx)` resolves formulas, subjects and wallets and returns a
  `ResourceTransaction` without mutation.
- `reserve()` currently sets `reserved = true` but **holds neither balance nor stock**.
  `commit()` does not consume a reservation; it prepares again against live state.
- `commit()` atomically applies the resolved wallet deltas only after all costs validate.
- `refund(transaction)` reverses the exact runtime wallet records once, provided the
  transaction was committed and all component costs were refundable. It does not restore an
  item transfer, consumed material, stock count or forged instance today.
- A result can expose `failure_reason`, resource-keyed `shortfalls`, missing resources,
  wallets touched, deltas and author-facing `display_summary` data.
- `CostSpec.previewable`, `refundable` and `allow_partial` exist, but preview suppression and
  partial completion are not implemented as player-facing policies.
- `[CNV]` has already settled state-preserving inventory entries, author-defined unit and
  convoy capacity, story-item exemptions, overflow to convoy and display-only stacking.
- `[SHP]` has settled resource-keyed prices, buy and sell, shopper-relative modifiers,
  durability-scaled sell values and buy-to-shopper with convoy overflow.
- `[EPUX-24]` has settled one atomic core beneath separate thin shop and forge panels.

The packet therefore distinguishes four states instead of pretending the runtime already
implements a commerce cart:

1. **Candidate** — focus/selection only; no promise.
2. **Quote** — a dated preview computed from current context; no promise.
3. **Staged session** — local proposed operations and running totals; still no held funds or
   stock under the current implementation.
4. **Committed receipt** — mutations succeeded as one operation and may be eligible for an
   explicit reversal policy.

“Reserved” should not be player copy until it acquires real hold semantics. Calling a mere
staged proposal reserved would falsely promise that later live changes cannot invalidate it.

## Comparative findings

### Fire Emblem: selection, consequence and destination belong together

Recent Fire Emblem games keep buy/sell, convoy and forge as recognizably separate services,
but their useful common rhythm is consistent: choose an offer or owned item, inspect its
stats/uses and price, choose or infer a recipient, confirm, then return to a stable list.
Engage's Somniel colocates equipment purchasing, inventory access and forging, reinforcing
that players experience them as one preparation workflow even when each retains a focused
panel. Three Houses similarly makes inventory and marketplace work part of the between-
battle preparation loop. The lesson is not to merge every screen; it is to preserve one
selection and consequence language across them.

Direct player criticism of Engage's separated buy and sell paths is weak evidence on its
own, but it exposes a real cost: mode switches hide whether a focused owned item can be sold
and whether a focused offer can be compared against a recipient's equipment. Prometheus can
retain explicit Buy/Sell modes while keeping balance, destination and comparison persistent.

Sources:

- [Nintendo: Fire Emblem Engage overview](https://www.nintendo.com/us/store/products/fire-emblem-engage-switch/)
- [Nintendo: Fire Emblem: Three Houses overview](https://www.nintendo.com/us/store/products/fire-emblem-three-houses-switch/)
- [Engage shop/convoy criticism and observations](https://www.reddit.com/r/fireemblem/comments/11lqnhp/i_hate_the_shop_ui/)
- [Series shop and inventory discussion](https://www.reddit.com/r/fireemblem/comments/q7r0gr/a_rarely_praised_gameplay_implementation_in_the/)

### Accessible commerce: errors must preserve work and explain recovery

Commerce guidance transfers well to game transactions when stripped of account/payment
details. A failed commit should identify the exact problem, preserve the proposal, and give
the next useful action: lower quantity, change destination, free capacity or choose another
resource source. It should not silently clear the cart or announce only “Unavailable.”

W3C guidance requires error identification in text, meaningful focus order and
programmatically exposed status changes. Its target-size guidance supports large direct-
touch rows and controls; drag cannot be the only transfer method. Dynamic affordability,
capacity and success messages should be available to assistive technology without stealing
focus for routine updates, while a blocking confirmation/error dialog takes focus and
returns it meaningfully when dismissed.

Sources:

- [W3C WAI: user notifications and recoverable errors](https://www.w3.org/WAI/tutorials/forms/notifications/)
- [W3C WAI: status messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html)
- [W3C WAI: meaningful focus order](https://www.w3.org/WAI/WCAG22/Understanding/focus-order.html)
- [W3C WAI: target size](https://www.w3.org/WAI/WCAG21/Understanding/target-size.html)
- [W3C WAI: content on hover or focus](https://www.w3.org/WAI/WCAG22/Understanding/content-on-hover-or-focus.html)

## Recommended base model

### One command shape

Every operation should provide a declarative proposal:

`subject + source + selected instance/offer + quantity + destination + inputs + outputs`

The shared service validates ownership, eligibility, resources, stock/capacity, destination
and item-instance consequences, then produces a quote with reason-keyed findings. A commit
revalidates the complete proposal against live state and applies all resource, inventory,
stock and instance mutations atomically. Panels specialize the proposal, never the commit
rules.

### One selector language

The selector owns stable item-instance identity, selection state, filtering/sorting,
eligibility state, quantity and a focused-detail payload. It does not own shop, convoy or
forge business rules. Rows always distinguish:

- focused from selected;
- eligible from unavailable-with-reason;
- one instance from a display stack;
- source/holder from intended destination;
- current value from proposed value.

Stacked display expands deterministically when individual instances differ or an operation
needs a particular instance. Quantity means repeat identical operations over explicitly
resolved instances; it never converts stateful items into fungible storage.

### Quote and confirmation

The quote is a continuously refreshed preview containing item/resource inputs, outputs,
wallet before/after, quantity, destination, capacity/overflow result, price modifiers and
warnings. Routine reversible single-item transfers may commit with one deliberate action.
Purchases, sales, forge operations, destructive replacement, story-item consequences and
multi-line staged sessions use an explicit review/confirm step. Settings may reduce repeated
low-risk confirmation, but never destructive or exceptional confirmation.

### Failure and cancellation

Commit is the only boundary that changes durable state. Back/cancel before commit discards
the proposal and restores focus without a refund. A failed commit keeps the proposal, marks
the stale fields and offers recovery. Refund/reversal is an explicit domain operation over
the original receipt—not a generic promise made by `ResourceLedger.refund()`—because item,
stock and forge state must also reverse atomically.

### Responsive and accessible behavior

Compact presents selector then review as adjacent steps over one proposal. Medium and
Expanded may show selector, detail and review simultaneously, but preserve the same logical
focus order and action names. The focused item, proposal and filter survive responsive
recomposition. Touch rows meet the project's touch target, every drag action has select /
destination / confirm equivalents, and price/capacity/errors use text plus icon—not color.

## Runtime gaps the owner decisions must acknowledge

1. Real balance/stock holds do not exist; either rename the UX state “staged” or implement a
   reservation registry with expiry/release rules.
2. Wallet commit is atomic, but a shared transaction needs inventory, stock and forged-state
   participants with prepare/apply/rollback or an outer snapshot transaction.
3. Refund currently knows only wallet records. A durable receipt must identify exact item
   instances, source/destination, stock deltas and before/after overlays.
4. `allow_partial` has no semantics. The recommended base rejects partial checkout and keeps
   quantity reduction as an explicit player correction.
5. Player-facing reasons must be stable reason IDs plus localized parameters, not raw
   `ResourceLedger:` diagnostic strings.

## Questions and downstream gate

Owner choices are in
[`transaction_surface_open_questions_2026-08-12.md`](../registers/transaction_surface_open_questions_2026-08-12.md)
as `TSV-1..24`. The shop/convoy research and wireframe packet may begin after those rulings;
it should consume this vocabulary rather than reopen it.
