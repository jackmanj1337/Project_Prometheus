---
Type: register
Status: RESOLVED — TSV-1..24 dispositioned 2026-08-13
Last verified: 2026-08-13
Register: TSV-1..24
Tracker: RESEARCH-TRANSACTION-SURFACE-2026-08-12
Resolved-in: this register — owner walk 2026-08-13
---

# Shared Transaction Surface — Owner Questions

Research: [Shared Transaction Surface comparative research](../design/transaction_surface_comparative_research_2026-08-12.md)

This is the `[UBS-2]` base packet. It governs shop, convoy and forge vocabulary.
Downstream shop/convoy responsive presentation was **held** until these questions were
ruled. That hold is now lifted.

## Disposition — walked 2026-08-13

**Ten of the twenty-four were already answered** by decisions ratified before this packet was
written, and are recorded below as **deferred to** those decisions rather than re-ruled. The
packet did not check itself against the `EPUX` walk of 2026-07-25/26, so several of its
recommendations argue for positions that ratified text had already settled — twice in the
opposite direction.

| Disposition | Questions |
|---|---|
| **Ruled 2026-08-13** | `TSV-1`, `TSV-4`, `TSV-5`, `TSV-6`, `TSV-10`, `TSV-11`, `TSV-13`, `TSV-19`, `TSV-20`, `TSV-21`, `TSV-24` |
| **Ruled 2026-08-12** while drawing the shop album | `TSV-12`, `TSV-15`, `TSV-16` |
| **Deferred** to ratified `EPUX` / `CEX` / `SHP` decisions | `TSV-3`, `TSV-7`, `TSV-8`, `TSV-9`, `TSV-14`, `TSV-17`, `TSV-18`, `TSV-23` |
| **Moot** — the premise was removed by another ruling | `TSV-2`, `TSV-22` |

**Where the packet was wrong, and it matters:**

- **`TSV-8`** recommended a fixed engine-side risk classification for which actions confirm.
  `EPUX-06` had already ratified the opposite: confirmation is **authored on the action**
  through predicates, raise-only.
- **`TSV-4`** recommended an "Adjust to N" recovery offer. `EPUX-21`'s live effective maximum
  and `EPUX-11`'s fail-before-commit make the case it recovers from unreachable.
- **`TSV-20/21/22`** were written for **per-receipt undo**. `EPUX-06`/`EPUX-28` ratified
  **whole-activity snapshot rollback**. These are different mechanisms, not two descriptions
  of one; `[TSV-21]` resolves it in favour of the ratified model.

**The `TSV-1..9` provenance gap this walk closed.**
[`shop_transaction_wireframes_2026-08-12.md`](../design/shop_transaction_wireframes_2026-08-12.md)
and the shop album both cite `TSV-1..9` as *ratified transaction vocabulary*, and the album
marks those frames as drawn-to-a-ruling rather than drawn-to-a-recommendation. No such ruling
existed on any branch — `[TSV-1]` in bracket form appeared only in this file, whose header
still read "owner walk not started". The substance did trace to ratified `EPUX` decisions
under different ids, so the album's drawings stand; but it was citing ids that had never been
walked. `TSV-1..9` are now genuinely dispositioned above.

## Transaction states and atomicity

### [TSV-1] What player-visible transaction states exist?

- **A — Focused / confirmed only.** For: simplest vocabulary. Against: cannot explain live
  quotes, multi-line proposals or invalidation.
- **B — Candidate / quote / staged / committed receipt.** For: maps honestly to selection,
  non-mutating preview, session-local proposal and durable change. Against: four states need
  disciplined copy and tests.
- **C — Candidate / quote / reserved / committed.** For: familiar commerce language.
  Against: current `reserve()` holds nothing, so “reserved” is a false promise.
- **Recommendation: B.** Use “staged” until a real hold service exists.

**Owner ruling (2026-08-13): candidate → quote → committed. There is no staged state.**

`EPUX-06` keeps immediate transaction persistence and `EPUX-28` makes the exit review
receipt the undo window, which together rule out option B's session-local proposal layer.
There is no cart, no staging and no reservation: a selection produces a live quote, and
confirming it commits atomically. Reversal is not a pre-commit hold — it is the
activity-entry snapshot described in `[TSV-19]`/`[TSV-21]` below.

This confirms what `shop_transaction_wireframes_2026-08-12.md` was already drawn against,
which until now cited a ruling that existed nowhere.

### [TSV-2] Does staging hold funds, stock or item instances?

- **A — No; commit revalidates live state.** For: matches runtime and local single-player
  sessions. Against: a quote can become stale.
- **B — Hold every input until cancel/expiry.** For: strong guarantee. Against: adds saved
  reservations, expiry, contention and recovery complexity without a present consumer.
- **C — Hold item instances but not numeric resources/stock.** For: prevents self-conflict
  inside a session. Against: mixed semantics are difficult to explain.
- **Recommendation: A for v0.8**, paired with visible stale-quote recovery; reserve B's API
  shape only if later asynchronous/shared stock genuinely requires it.

**Owner ruling (2026-08-13): moot — nothing is held, because nothing is staged.**

Answered by implication from `[TSV-1]`. There is no interval between quote and commit in
which a hold could exist, so option A holds by construction rather than by choice. Do not
build a hold service, and do not reserve B's API shape speculatively — the question
becomes live again only if asynchronous or shared stock is ever introduced.

### [TSV-3] What is the commit atomicity boundary?

- **A — Wallet only.** For: already built. Against: a failure after payment can lose funds or
  duplicate an item.
- **B — Resources, exact item instances, stock, capacity/destination and forge mutation in one
  operation.** For: correct all-or-nothing behavior. Against: requires transaction participants
  beyond `ResourceLedger`.
- **C — Ordered best effort with compensating refunds.** For: easier to bolt onto services.
  Against: compensation can itself fail and makes saves harder to reason about.
- **Recommendation: B.** The shared core is not complete until this boundary is real.

**Deferred to `EPUX-24` (ratified 2026-07-26) — not re-ruled here.**

`EPUX-24` ratified option C, *"shared atomic transaction core, thin panels"*, which is this
question's option B. The boundary is already decided. What remains is implementation: the
transaction-participant registry that lets stock, capacity, destination and forge mutation
join the wallet inside one operation does not exist yet, and `ResourceLedger` alone cannot
provide it.

### [TSV-4] May a multi-line or quantity commit partially succeed?

- **A — Never.** For: predictable totals, simple receipts and no surprise subset. Against:
  one unavailable line blocks all lines.
- **B — Always buy/transfer the affordable subset.** For: speed. Against: silently changes
  player intent and allocation.
- **C — Only after an explicit revised-quantity offer.** For: recovery without surprise.
  Against: adds one failure path.
- **Recommendation: C.** The original commit is atomic; on failure offer “Adjust to N” and
  require a new confirmation. Do not implement `allow_partial` as silent checkout.

**Owner ruling (2026-08-13): never partial. No `allow_partial`, and no "Adjust to N" offer.**

The packet's recommendation C is superseded by the ratified pair it did not account for:
`EPUX-21`'s quantity stepper *"steps backward to a live effective maximum"*, so an
unaffordable or unholdable quantity cannot be selected in the first place, and `EPUX-11`
ruled **fail-before-commit for buys** when capacity is terminal. The recovery path C exists
to serve is therefore unreachable through normal interaction.

A quantity that goes stale between quote and confirm is handled by the `[TSV-5]` re-quote,
which surfaces the change and asks again — not by silently committing a subset.

### [TSV-5] When must commit re-quote?

- **A — Every commit.** For: authoritative live validation. Against: quote may change at the
  confirmation boundary.
- **B — Trust the displayed quote.** For: stable price. Against: unsafe without real holds.
- **C — Re-quote only after a timer.** For: fewer calculations. Against: time is not the only
  invalidator.
- **Recommendation: A.** If material values change, stop, highlight the differences and ask
  for reconfirmation rather than committing an unseen result.

**Owner ruling (2026-08-13): re-quote on every commit; on material change, stop and reconfirm.**

Option A. Without holds the displayed quote is only a snapshot, so commit revalidates
against live state every time. If price, stock, capacity or eligibility moved, the commit
does **not** proceed: the differences are highlighted and the player confirms the new quote
or backs out. A changed quote is a diff to accept, not an error to dismiss and restart.

Cheap here precisely because `[TSV-1]` removed the cart — there is one line to re-quote.

## Quote and review

### [TSV-6] What must every quote show?

- **A — Total price only.** For: compact. Against: hides destination, capacity and modifiers.
- **B — Inputs/outputs, quantity, wallet before/after, destination, capacity/overflow,
  modifiers and warnings.** For: informed consent across all panels. Against: needs responsive
  prioritization.
- **C — Panel-specific fields only.** For: maximum specialization. Against: vocabulary drifts.
- **Recommendation: B**, with progressive disclosure but identical underlying fields.

**Owner ruling (2026-08-13): one field set everywhere, progressive disclosure by size class.**

Option B. `EPUX-17` had ratified only the *price* half of this (final price in the list, full
formula in the selected item's More Info panel); the rest of the quote was unruled. Every
quote, in every panel, carries the same underlying fields — inputs/outputs, quantity, wallet
before/after, destination, capacity/overflow, modifiers, warnings. Layout decides what is
visible at a glance versus on focus; the field set does not vary by panel.

The album's single-scroll ruling already guarantees the ordering constraint this depends on:
consequence is readable before the action that causes it.

### [TSV-7] How are dynamic price modifiers explained?

- **A — Show final price only.** For: clean rows. Against: shopper choice can feel arbitrary.
- **B — Base, signed modifier and final value on focus/review.** For: auditable without row
  clutter. Against: another detail line.
- **C — Always show the complete formula.** For: maximum transparency. Against: author terms
  can be technical and overwhelming.
- **Recommendation: B.** Offer an optional “Why?” breakdown using authored localized labels;
  never expose raw formula syntax.

**Deferred to `EPUX-17` (ratified 2026-07-26) — not re-ruled here.**

`EPUX-17` ratified final price in the list with the full formula in the selected item's More
Info panel, using authored localized labels. That is this question's option B, and it also
establishes the list/detail split `EPUX-19` reuses. Raw formula syntax is never exposed.

### [TSV-8] Which actions require explicit review confirmation?

- **A — Every operation.** For: safest. Against: convoy organization becomes tedious.
- **B — Purchases, sales, forge/destructive changes, multi-line commits and exceptional
  warnings; reversible one-item transfers commit directly.** For: confirmation matches risk.
  Against: requires a stable risk classification.
- **C — Confirm only destructive operations.** For: fast. Against: accidental spending is
  still costly.
- **Recommendation: B.** A user setting may reduce repeated low-risk purchase confirmation,
  but not destructive or exceptional warnings.

**Deferred to `EPUX-06` (ratified 2026-07-26) — and this packet's recommendation was wrong.**

`EPUX-06` ratified option C: confirmation is **authored on the action**, plus declarative
threshold rules, both expressed as predicates, with player/author strictness **raise-only**.
Recommendation B here — a fixed engine-side risk classification — is superseded. There is no
hardcoded list of "risky" operations; the author declares which actions confirm, and a player
may only make that stricter.

Note this is the same shape as the `[TSV-13]` ruling below: presentation policy is authored
through the predicate system, not switched on in engine code.

### [TSV-9] Where does review live responsively?

- **A — Always modal.** For: one implementation. Against: context and comparison disappear.
- **B — Persistent pane on larger layouts, full-width step/sheet on Compact.** For: uses space
  without creating two workflows. Against: focus restoration needs care.
- **C — Inline row expansion.** For: maintains list context. Against: unstable list geometry
  and poor multi-line review.
- **Recommendation: B**, with one semantic Review region and one focus order.

**Deferred to `EPUX-03` + `UUI` — not re-ruled here.**

`EPUX-03` ratified at most two panes pairing adjacent levels of the Explore chain, with a
registry-declared full-width preference for content-dense panels; the shop album's
single-scroll ruling then settled the Compact composition. Together these are this question's
option B. One semantic Review region and one focus order still hold as a constraint on the
implementation.

## Selector and quantity semantics

### [TSV-10] What does the shared selector own?

- **A — Only focus and activation.** For: small primitive. Against: each panel reimplements
  selection, eligibility and quantities.
- **B — Stable identity, focus, selected set, eligibility/reason, quantity, filters/sort and
  detail payload.** For: one reusable accessible selector. Against: a richer contract.
- **C — All business rules too.** For: panels become tiny. Against: creates a monolithic
  shop/convoy/forge switch and violates the open-registry principle.
- **Recommendation: B.** Services provide rules; the selector presents their results.

**Owner ruling (2026-08-13): B — the selector owns presentation state, services own rules.**

The shared selector owns stable identity, focus, the selected set, eligibility together with
its reason, quantity, filters/sort and the detail payload. It does **not** own business
rules: services decide what is eligible and why, and the selector presents their results.

Option C is rejected for the reason `AGENTS.md` gives generally — a selector that owned the
rules would become a monolithic shop/convoy/forge switch, which is the closed-enum smell the
open-registry principle exists to prevent.

### [TSV-11] How are stateful items stacked?

- **A — Never stack.** For: identity is obvious. Against: large convoys are noisy.
- **B — Display-stack only when operation-relevant state matches; expand to exact instances
  before commit.** For: preserves `[CNV-1/7]` and readability. Against: expansion rules need
  deterministic ordering.
- **C — Stack by definition ID and average state.** For: shortest list. Against: destroys
  durability/forge truth.
- **Recommendation: B.** Show count and state key; commit records exact stable instance IDs.

**Owner ruling (2026-08-13): B — display-stack only when operation-relevant state matches.**

Rows stack only where the state that matters *to the current operation* is identical; the row
shows a count and a state key, and the stack expands to exact instance IDs before commit.
Preserves `[CNV-1]`/`[CNV-7]` instance identity while keeping a large convoy readable at
Compact, where the list is the entire screen.

Consistent with `EPUX-10`, ratified 2026-07-26 as *"stack only on identical effective
state"*. Expansion ordering must be deterministic.

### [TSV-12] What does quantity mean for stateful items?

- **A — A fungible count by item ID.** For: familiar. Against: selects the wrong durability or
  forged copy.
- **B — Repeat the same operation over explicitly resolved eligible instances.** For: honest
  instance semantics. Against: mixed stacks may need review.
- **C — Quantity only for infinite shop stock, never owned items.** For: simple ownership.
  Against: bulk convoy and selling remain tedious.
- **Recommendation: B**, with deterministic resolution preview and expansion on differences.

**Ruled in session 2026-08-12 while drawing the shop album; restated here.**

The quantity stepper appears only on infinite-stock, unstateful items, and it fires N
separate atomic transactions rather than one bulk operation. Stateful items are transacted
per instance.

This is the `EPUX-21` shared quantity primitive applied to the item shop, and it is what
makes `[TSV-4]`'s "never partial" reachable: N atomic transactions each revalidate.

### [TSV-13] May unavailable rows remain selectable?

- **A — Hide them.** For: clean. Against: players cannot learn why an expected item vanished.
- **B — Show disabled but focusable rows with reason and recovery.** For: transparent and
  accessible. Against: longer navigation.
- **C — Author chooses hide/disable for every failure.** For: flexible. Against: transactional
  errors need consistent treatment.
- **Recommendation: B** for owned/known entries; conditional secret stock may still follow
  `[SAC-8]` author-selected hidden versus revealed-disabled discovery policy.

**Owner ruling (2026-08-13): hide and disable are both author-controlled, and they are one connected system.**

Neither the packet's B nor its C as written. The shape is:

- **Presence is decided by the availability predicate system.** Shop stock already changes
  based on predicate expressions; an author who wants an option *absent* uses that system.
  There is no separate per-failure "hide" toggle in the transaction layer.
- **What is present but not takeable is shown disabled with an explanation.** The
  explanation comes either from the semantic explanation system (generated) or from
  author-written text, the latter existing specifically so story elements can be concealed
  while the row still explains itself.
- **The two must be connected surfaces, not independent knobs**, so an author is not left
  guessing which mechanism governs a given row.

This inherits `EPUX-02` (absent hides, gated shows disabled-with-reason, per-entry author-set
gate presentation defaulting to visible-disabled) and `EPUX-07`'s single reason contract
rather than creating a transaction-specific vocabulary, and it is `[SAC-8]`'s
hidden-versus-revealed discovery policy expressed through predicates.

**Boundary to hold:** *transactional* failure is not an authoring choice. Insufficient funds,
full capacity and failed eligibility are always disabled-with-reason, never hidden — the
author controls what stock exists, the engine controls whether the player can afford it. The
shop album's affordability treatment depends on this.

### [TSV-14] Is drag-and-drop a primary transfer control?

- **A — Yes, drag only.** For: direct touch metaphor. Against: inaccessible to keyboard,
  controller and many motor users.
- **B — Optional shortcut over Select → Destination → Confirm.** For: efficient without
  splitting semantics. Against: two gestures to test.
- **C — No drag.** For: smallest matrix. Against: misses a useful tablet/desktop shortcut.
- **Recommendation: B.** Drag must produce the same proposal and preview as discrete actions.

**Deferred to `EPUX-09` (ratified 2026-07-26) — not re-ruled here.**

`EPUX-09` ratified **A for v1 — command verbs only**, with drag/drop post-v1 as an *additive
adapter over the same authoritative mutation command*. That is this question's option B with
an explicit v1 cut, and the shared-command requirement is what guarantees drag produces the
same proposal and preview as the discrete path. Drag belongs to the deferred "pointer and
keyboard" tranche alongside free-text search and forge alias.

## Destination, capacity and overflow

### [TSV-15] When is destination selected?

- **A — Before browsing.** For: filters availability and matches subject-first Explore.
  Against: bulk convoy purchases may not need a unit.
- **B — After item selection.** For: item-first shopping. Against: price/eligibility may depend
  on subject and force a re-quote.
- **C — Subject/source first, persistent destination shown, with destination change before
  commit where policy allows.** For: honors `[SAC-5/6]` while keeping correction cheap.
  Against: requires clear subject-versus-destination labels.
- **Recommendation: C.** Never conflate pricing subject, source holder and recipient.

**Ruled in session 2026-08-12 while drawing the shop album; restated here.**

Destination is fixed to the subject inherited from Explore and is never prompted for inside
the shop. Consistent with `EPUX-13` (the session inherits its subject) and `EPUX-14` (convoy
owner as pricing subject, no gatekeeping). Pricing subject, source holder and recipient
remain distinct concepts even though the shop binds them from one inherited value.

### [TSV-16] How is unit-capacity overflow handled?

- **A — Automatic convoy overflow with preview.** For: matches `[CNV-3]` and `[SAC-6]`; no lost
  purchase. Against: can surprise players.
- **B — Block and require another destination.** For: explicit. Against: unnecessary friction
  where convoy is available.
- **C — Prompt on every overflow.** For: explicit. Against: repetitive.
- **Recommendation: A**, with destination line “Unit (N), Convoy (overflow M)” before commit;
  block only when no legal overflow exists.

**Ruled in session 2026-08-12, and matches `EPUX-11`.**

Unit-capacity overflow goes to the convoy silently and is reported after the fact rather than
prompted for. `EPUX-11` ratified overflow-to-convoy, so this is that decision's presentation
half.

### [TSV-17] What happens when convoy capacity is also full?

- **A — Discard excess with warning.** For: completes the action. Against: unacceptable item
  loss, especially for paid/story items.
- **B — Reject the whole commit and preserve the proposal.** For: atomic and safe. Against:
  player must free capacity.
- **C — Commit the fitting subset.** For: convenience. Against: violates chosen quantity.
- **Recommendation: B**, with exact shortfall and actions to change destination/quantity or
  open capacity management.

**Deferred to `EPUX-11` (ratified 2026-07-26) — not re-ruled here.**

`EPUX-11` ratified full-cap terminal handling as **fail-before-commit for buys**, with a
**pending-items tray** for unavoidable acquisitions such as rewards and loot. That is this
question's option B for the purchase path, plus a mechanism the packet did not consider for
the path where refusing the item is not an option. Nothing is ever discarded.

### [TSV-18] How are story/key items treated?

- **A — Ordinary transaction rules.** For: no special UI. Against: conflicts with their
  unsellable, capacity-exempt, cannot-be-lost contract.
- **B — Visible, inspectable, capacity-exempt and unavailable for sell/consume/drop with a
  specific reason.** For: preserves `[CNV-2]`/`[SHP-2]`. Against: extra status vocabulary.
- **C — Hide from all selectors.** For: avoids invalid actions. Against: players cannot find
  or inspect them.
- **Recommendation: B.** A registered operation may explicitly target one only if its author
  contract permits the consequence.

**Deferred to `[CEX-16]` + `[SHP-2]` — not re-ruled here, with one new clause.**

Already ratified: story items (`ItemDef.story`) are **exempt from `convoy_capacity`**, never
count against the cap, cannot be lost, and surface in a dedicated convoy **Key Items view**
(`[CEX-16]`, 2026-06-24d); key and non-sellable items are sell-gated by `item_type`
(`[SHP-2]`, 2026-06-23k). The "specific reason" half is `EPUX-07`'s unified reason contract.

New and adopted from this packet: **a registered operation may explicitly target a story item
only if its author contract permits the consequence.** This is the escape hatch for an
authored plot event that consumes a key item, and it is opt-in per operation.

## Cancellation, receipts and reversal

### [TSV-19] What does Cancel mean before commit?

- **A — Close the whole panel.** For: simple. Against: loses distinction between abandoning a
  proposal and leaving the service.
- **B — First cancel clears the active proposal and returns focus; cancel again leaves the
  panel.** For: predictable nested navigation. Against: one extra back press when empty.
- **C — Ask every time.** For: prevents loss. Against: modal fatigue for non-mutating state.
- **Recommendation: B.** Ask only when abandoning a substantial staged multi-line proposal.

**Owner ruling (2026-08-13): there is nothing to cancel mid-panel; the only boundary is the exit.**

The question presupposed a proposal that could be abandoned. `[TSV-1]` removed it, so the
answer is about leaving the store:

- **No transactions this visit → leave with no prompt.** Nothing happened; do not ask.
- **Any transaction this visit → confirm/revert on the way out.** *Confirm* accepts the visit
  and exits. *Revert* restores the activity-entry snapshot — the state where nothing has been
  done — and **leaves the player in the store**, free to walk out from there without a second
  prompt. Revert is not itself an exit.

Two additions from the same ruling:

- **A store declares whether it offers a receipt.** This is `EPUX-06`'s author-chosen exit
  review made explicit per shop.
- **A player setting may auto-accept receipts.** See the boundary note under `[TSV-21]` for
  why this does not breach `EPUX-06`'s raise-only rule.

### [TSV-20] What must a committed receipt contain?

- **A — Success text and total.** For: compact. Against: cannot support review or reversal.
- **B — Stable receipt ID, operation, subject, exact instances, sources/destinations,
  resource/stock deltas, before/after overlays, warnings and reversibility state.** For:
  auditable and sufficient for `[EPUX-28]` exit review. Against: richer runtime data.
- **C — Full save snapshot.** For: universal rollback. Against: heavy, opaque and conflicts
  with unrelated changes.
- **Recommendation: B.** Persist only if the owning activity's rollback window crosses save.

**Owner ruling (2026-08-13): summary line per transaction, full audit detail on expansion.**

Not the packet's B as a flat wall of fields. The receipt lists **one summary line per
transaction** by default and expands to the full audit payload — stable receipt ID,
operation, subject, exact instance IDs, sources and destinations, resource and stock deltas,
before/after overlays, warnings, reversibility state.

The default view has to stay legible at the Compact row budget, where the receipt appears at
the moment the player is trying to leave; the audit detail has to exist so that "revert the
whole visit" is an informed choice rather than a leap. Persist only if the owning activity's
rollback window crosses a save boundary.

### [TSV-21] What does Refund mean?

- **A — Always reverse any commit.** For: forgiving. Against: impossible after consuming,
  transferring or externally changing outputs.
- **B — A domain reversal of the original receipt, allowed only inside its declared window and
  revalidated atomically.** For: honest and compatible with `[EPUX-28]`. Against: more than
  `ResourceLedger.refund()` alone.
- **C — Wallet reversal only.** For: already partly built. Against: duplicates items or leaves
  forged state behind.
- **Recommendation: B.** Player copy should use “Undo” or operation-specific “Buy Back” where
  appropriate; reserve “refund” for the engine capability.

**Owner ruling (2026-08-13): reversal is whole-activity snapshot restore. Per-receipt undo does not exist.**

This resolves a conflict the packet did not see. `TSV-20/21/22` were written for per-receipt
undo, but `EPUX-06` ratified rollback to an **activity-entry snapshot**, exactly one kept and
discarded on acceptance, and `EPUX-28` ratified that the exit review receipt **is** the undo
window — permanent means permanent *after acceptance*. Those are different mechanisms.

**EPUX stands.** There is one snapshot, taken at activity entry, restored or accepted at
exit. There is no undo of an individual transaction, and no second reversal window. A player
who regrets the third of eight purchases reverts the whole visit or keeps it.

Consequences the owner accepted explicitly:

- **A store that declares no receipt has no reversal at all**, and that is a deliberate
  authoring lever — every transaction there is immediately permanent. High-stakes and story
  shops are expected to use it. The player must be able to tell which kind of store they are
  in *before* spending.
- **Auto-accept does not breach `EPUX-06`'s raise-only rule.** Raise-only governs per-action
  **confirmation prompts**, which stay author-controlled and cannot be weakened by a player.
  The exit receipt is a **review-and-rewind** surface, a separate mechanism, so a player may
  auto-accept it. `EPUX-06` needs one sentence marking that boundary so the next reader does
  not read the two as contradictory.

Player-facing copy uses "Confirm" and "Revert"; reserve "refund" for the engine capability
`ResourceLedger` already names.

### [TSV-22] What happens when reversal is no longer legal?

- **A — Hide Undo.** For: clean. Against: unexplained disappearance.
- **B — Show its expired/unavailable state and reason in the receipt while the receipt remains
  visible.** For: transparent. Against: more status text.
- **C — Attempt and show a generic failure.** For: minimal prevalidation. Against: frustrating.
- **Recommendation: B.** Examples: output equipped/transferred, stock cadence advanced,
  receipt accepted, or insufficient resources to reverse a credit.

**Retired by the `[TSV-21]` ruling — no longer a live question.**

The question assumed a per-receipt reversal window that could lapse while its receipt stayed
on screen. Under whole-activity snapshot restore there is no such interval: inside the
activity the snapshot is always restorable, and after acceptance it is discarded and nothing
is. Legality is binary and positional, not a decaying window, so there is no
expired-with-reason state to present.

Should per-receipt undo ever return, this question returns with it.

## Errors, accessibility and persistence

### [TSV-23] What is the shared error contract?

- **A — Raw service string.** For: fastest implementation. Against: not localized, stable or
  actionable.
- **B — Stable reason ID + localized summary + parameters + affected field/line + recovery
  actions; diagnostics logged separately.** For: reusable and testable. Against: requires a
  reason registry/presenter.
- **C — Panel-authored prose.** For: tailored. Against: three vocabularies drift.
- **Recommendation: B.** Preserve proposal and focus the first affected field without hiding
  the rest of the failure summary.

**Deferred to `EPUX-07` (ratified 2026-07-26) — not re-ruled here.**

`EPUX-07` ratified option C on **one unified reason contract shared with `EPUX-02`** rather
than a parallel transaction vocabulary, and settled that disabled entries are
**focusable-but-not-activatable**. That is this question's option B, already generalized
beyond transactions. Preserving the proposal and focusing the first affected field without
hiding the rest of the failure summary remains a constraint on the presenter.

### [TSV-24] What state survives responsive recomposition, input change and panel exit?

- **A — Nothing.** For: safest reset. Against: punishes rotation/input switching.
- **B — Within the open activity: subject, source, filters/sort, focused instance, proposal,
  review position and meaningful focus; on ordinary exit keep no uncommitted proposal.** For:
  one coherent responsive experience. Against: requires stable IDs and focus restoration.
- **C — Save every staged proposal between visits.** For: resumable carts. Against: creates
  stale quote/reservation problems and save schema with little benefit.
- **Recommendation: B.** Announce changing totals/capacity as non-focus-stealing status; use
  text plus icon, meet touch targets, and provide non-drag operation for every action.

**Owner ruling (2026-08-13): B — everything survives within the activity; nothing uncommitted survives exit.**

Subject, source, filters and sort, focused instance, the active quote, review position and
meaningful focus all survive responsive recomposition and a change of input mode. Rotating a
phone or switching from touch to a pad mid-purchase costs the player nothing. On ordinary
exit, no uncommitted proposal is kept — and under `[TSV-1]` there is none to keep.

This requires stable instance IDs and real focus restoration, both of which
`[TSV-10]`'s selector contract already owes. The mobile-web controller makes rotation and
input switching routine, so option C's reset-on-recomposition is not acceptable. Announce
changing totals and capacity as non-focus-stealing status; every action must have a
non-drag path (`EPUX-09`).

## Consequences of the ruled set

1. **The transaction model is small.** No cart, no staging, no holds, no per-receipt undo,
   no partial commits, no expiry windows. One quote, one atomic commit, one snapshot per
   activity. Four of this packet's twenty-four questions were arguing for machinery that the
   ratified model does not need.

2. **Author-controlled presentation is the recurring shape, and it now appears three times.**
   `EPUX-06` puts confirmation on the action as a predicate; `[TSV-13]` puts hide-versus-
   disable on the availability predicate system; `[TSV-19]`/`[TSV-21]` put receipt existence
   on the store. An author configures this surface through data in all three cases, which is
   the open-registry principle holding rather than being restated.

3. **Two things the engine must never let an author weaken.** Transactional failure —
   insufficient funds, full capacity, failed eligibility — is always disabled-with-reason and
   never hidden (`[TSV-13]`). And per-action confirmation strictness is raise-only
   (`EPUX-06`), which the new auto-accept setting does **not** touch because the receipt is a
   review surface rather than a confirmation.

4. **`EPUX-06` needs one clarifying sentence**, marking the boundary between per-action
   confirmation (raise-only, author-controlled) and exit review (player may auto-accept).
   Without it the next reader will correctly spot an apparent contradiction. This is the one
   edit this walk owes an already-ratified document.

5. **A no-receipt store is a real authoring lever with a real obligation.** Where no receipt
   is declared there is no reversal of any kind, so the player has to be able to tell, before
   spending, which kind of store they are standing in. That is an unsolved presentation
   problem and belongs to the convoy/shop presentation work, not here.

6. **The unbuilt engine pieces this names.** The transaction-participant registry (`TSV-3`,
   via `EPUX-24`) so stock, capacity, destination and forge mutation can join the wallet in
   one atomic operation. The shared selector contract (`TSV-10`) with stable instance IDs and
   focus restoration (`TSV-24`). The pending-items tray (`EPUX-11`, surfaced by `TSV-17`).
   Deterministic stack expansion (`TSV-11`). None exist today.

## Dependency disposition

`TSV-1..24` is the base packet, and the hold it placed on downstream work is **lifted**. The
convoy and shop presentation work now cites these rulings rather than reopening transaction
states, confirmation, selector, destination, capacity, error or reversal semantics.

Still open elsewhere and still blocking: `SHP-1..5`, so every price drawn in the shop album
remains illustrative.
