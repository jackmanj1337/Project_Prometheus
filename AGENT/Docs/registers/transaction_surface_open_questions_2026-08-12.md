---
Type: register
Status: OPEN — research prepared, owner walk not started
Last verified: 2026-08-12
Register: TSV-1..24
Tracker: RESEARCH-TRANSACTION-SURFACE-2026-08-12
---

# Shared Transaction Surface — Owner Questions

Research: [Shared Transaction Surface comparative research](../design/transaction_surface_comparative_research_2026-08-12.md)

This is the `[UBS-2]` base packet. It governs shop, convoy and forge vocabulary.
Downstream shop/convoy responsive presentation is **held** until these questions are ruled.

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

### [TSV-2] Does staging hold funds, stock or item instances?

- **A — No; commit revalidates live state.** For: matches runtime and local single-player
  sessions. Against: a quote can become stale.
- **B — Hold every input until cancel/expiry.** For: strong guarantee. Against: adds saved
  reservations, expiry, contention and recovery complexity without a present consumer.
- **C — Hold item instances but not numeric resources/stock.** For: prevents self-conflict
  inside a session. Against: mixed semantics are difficult to explain.
- **Recommendation: A for v0.8**, paired with visible stale-quote recovery; reserve B's API
  shape only if later asynchronous/shared stock genuinely requires it.

### [TSV-3] What is the commit atomicity boundary?

- **A — Wallet only.** For: already built. Against: a failure after payment can lose funds or
  duplicate an item.
- **B — Resources, exact item instances, stock, capacity/destination and forge mutation in one
  operation.** For: correct all-or-nothing behavior. Against: requires transaction participants
  beyond `ResourceLedger`.
- **C — Ordered best effort with compensating refunds.** For: easier to bolt onto services.
  Against: compensation can itself fail and makes saves harder to reason about.
- **Recommendation: B.** The shared core is not complete until this boundary is real.

### [TSV-4] May a multi-line or quantity commit partially succeed?

- **A — Never.** For: predictable totals, simple receipts and no surprise subset. Against:
  one unavailable line blocks all lines.
- **B — Always buy/transfer the affordable subset.** For: speed. Against: silently changes
  player intent and allocation.
- **C — Only after an explicit revised-quantity offer.** For: recovery without surprise.
  Against: adds one failure path.
- **Recommendation: C.** The original commit is atomic; on failure offer “Adjust to N” and
  require a new confirmation. Do not implement `allow_partial` as silent checkout.

### [TSV-5] When must commit re-quote?

- **A — Every commit.** For: authoritative live validation. Against: quote may change at the
  confirmation boundary.
- **B — Trust the displayed quote.** For: stable price. Against: unsafe without real holds.
- **C — Re-quote only after a timer.** For: fewer calculations. Against: time is not the only
  invalidator.
- **Recommendation: A.** If material values change, stop, highlight the differences and ask
  for reconfirmation rather than committing an unseen result.

## Quote and review

### [TSV-6] What must every quote show?

- **A — Total price only.** For: compact. Against: hides destination, capacity and modifiers.
- **B — Inputs/outputs, quantity, wallet before/after, destination, capacity/overflow,
  modifiers and warnings.** For: informed consent across all panels. Against: needs responsive
  prioritization.
- **C — Panel-specific fields only.** For: maximum specialization. Against: vocabulary drifts.
- **Recommendation: B**, with progressive disclosure but identical underlying fields.

### [TSV-7] How are dynamic price modifiers explained?

- **A — Show final price only.** For: clean rows. Against: shopper choice can feel arbitrary.
- **B — Base, signed modifier and final value on focus/review.** For: auditable without row
  clutter. Against: another detail line.
- **C — Always show the complete formula.** For: maximum transparency. Against: author terms
  can be technical and overwhelming.
- **Recommendation: B.** Offer an optional “Why?” breakdown using authored localized labels;
  never expose raw formula syntax.

### [TSV-8] Which actions require explicit review confirmation?

- **A — Every operation.** For: safest. Against: convoy organization becomes tedious.
- **B — Purchases, sales, forge/destructive changes, multi-line commits and exceptional
  warnings; reversible one-item transfers commit directly.** For: confirmation matches risk.
  Against: requires a stable risk classification.
- **C — Confirm only destructive operations.** For: fast. Against: accidental spending is
  still costly.
- **Recommendation: B.** A user setting may reduce repeated low-risk purchase confirmation,
  but not destructive or exceptional warnings.

### [TSV-9] Where does review live responsively?

- **A — Always modal.** For: one implementation. Against: context and comparison disappear.
- **B — Persistent pane on larger layouts, full-width step/sheet on Compact.** For: uses space
  without creating two workflows. Against: focus restoration needs care.
- **C — Inline row expansion.** For: maintains list context. Against: unstable list geometry
  and poor multi-line review.
- **Recommendation: B**, with one semantic Review region and one focus order.

## Selector and quantity semantics

### [TSV-10] What does the shared selector own?

- **A — Only focus and activation.** For: small primitive. Against: each panel reimplements
  selection, eligibility and quantities.
- **B — Stable identity, focus, selected set, eligibility/reason, quantity, filters/sort and
  detail payload.** For: one reusable accessible selector. Against: a richer contract.
- **C — All business rules too.** For: panels become tiny. Against: creates a monolithic
  shop/convoy/forge switch and violates the open-registry principle.
- **Recommendation: B.** Services provide rules; the selector presents their results.

### [TSV-11] How are stateful items stacked?

- **A — Never stack.** For: identity is obvious. Against: large convoys are noisy.
- **B — Display-stack only when operation-relevant state matches; expand to exact instances
  before commit.** For: preserves `[CNV-1/7]` and readability. Against: expansion rules need
  deterministic ordering.
- **C — Stack by definition ID and average state.** For: shortest list. Against: destroys
  durability/forge truth.
- **Recommendation: B.** Show count and state key; commit records exact stable instance IDs.

### [TSV-12] What does quantity mean for stateful items?

- **A — A fungible count by item ID.** For: familiar. Against: selects the wrong durability or
  forged copy.
- **B — Repeat the same operation over explicitly resolved eligible instances.** For: honest
  instance semantics. Against: mixed stacks may need review.
- **C — Quantity only for infinite shop stock, never owned items.** For: simple ownership.
  Against: bulk convoy and selling remain tedious.
- **Recommendation: B**, with deterministic resolution preview and expansion on differences.

### [TSV-13] May unavailable rows remain selectable?

- **A — Hide them.** For: clean. Against: players cannot learn why an expected item vanished.
- **B — Show disabled but focusable rows with reason and recovery.** For: transparent and
  accessible. Against: longer navigation.
- **C — Author chooses hide/disable for every failure.** For: flexible. Against: transactional
  errors need consistent treatment.
- **Recommendation: B** for owned/known entries; conditional secret stock may still follow
  `[SAC-8]` author-selected hidden versus revealed-disabled discovery policy.

### [TSV-14] Is drag-and-drop a primary transfer control?

- **A — Yes, drag only.** For: direct touch metaphor. Against: inaccessible to keyboard,
  controller and many motor users.
- **B — Optional shortcut over Select → Destination → Confirm.** For: efficient without
  splitting semantics. Against: two gestures to test.
- **C — No drag.** For: smallest matrix. Against: misses a useful tablet/desktop shortcut.
- **Recommendation: B.** Drag must produce the same proposal and preview as discrete actions.

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

### [TSV-16] How is unit-capacity overflow handled?

- **A — Automatic convoy overflow with preview.** For: matches `[CNV-3]` and `[SAC-6]`; no lost
  purchase. Against: can surprise players.
- **B — Block and require another destination.** For: explicit. Against: unnecessary friction
  where convoy is available.
- **C — Prompt on every overflow.** For: explicit. Against: repetitive.
- **Recommendation: A**, with destination line “Unit (N), Convoy (overflow M)” before commit;
  block only when no legal overflow exists.

### [TSV-17] What happens when convoy capacity is also full?

- **A — Discard excess with warning.** For: completes the action. Against: unacceptable item
  loss, especially for paid/story items.
- **B — Reject the whole commit and preserve the proposal.** For: atomic and safe. Against:
  player must free capacity.
- **C — Commit the fitting subset.** For: convenience. Against: violates chosen quantity.
- **Recommendation: B**, with exact shortfall and actions to change destination/quantity or
  open capacity management.

### [TSV-18] How are story/key items treated?

- **A — Ordinary transaction rules.** For: no special UI. Against: conflicts with their
  unsellable, capacity-exempt, cannot-be-lost contract.
- **B — Visible, inspectable, capacity-exempt and unavailable for sell/consume/drop with a
  specific reason.** For: preserves `[CNV-2]`/`[SHP-2]`. Against: extra status vocabulary.
- **C — Hide from all selectors.** For: avoids invalid actions. Against: players cannot find
  or inspect them.
- **Recommendation: B.** A registered operation may explicitly target one only if its author
  contract permits the consequence.

## Cancellation, receipts and reversal

### [TSV-19] What does Cancel mean before commit?

- **A — Close the whole panel.** For: simple. Against: loses distinction between abandoning a
  proposal and leaving the service.
- **B — First cancel clears the active proposal and returns focus; cancel again leaves the
  panel.** For: predictable nested navigation. Against: one extra back press when empty.
- **C — Ask every time.** For: prevents loss. Against: modal fatigue for non-mutating state.
- **Recommendation: B.** Ask only when abandoning a substantial staged multi-line proposal.

### [TSV-20] What must a committed receipt contain?

- **A — Success text and total.** For: compact. Against: cannot support review or reversal.
- **B — Stable receipt ID, operation, subject, exact instances, sources/destinations,
  resource/stock deltas, before/after overlays, warnings and reversibility state.** For:
  auditable and sufficient for `[EPUX-28]` exit review. Against: richer runtime data.
- **C — Full save snapshot.** For: universal rollback. Against: heavy, opaque and conflicts
  with unrelated changes.
- **Recommendation: B.** Persist only if the owning activity's rollback window crosses save.

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

### [TSV-22] What happens when reversal is no longer legal?

- **A — Hide Undo.** For: clean. Against: unexplained disappearance.
- **B — Show its expired/unavailable state and reason in the receipt while the receipt remains
  visible.** For: transparent. Against: more status text.
- **C — Attempt and show a generic failure.** For: minimal prevalidation. Against: frustrating.
- **Recommendation: B.** Examples: output equipped/transferred, stock cadence advanced,
  receipt accepted, or insufficient resources to reverse a credit.

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

### [TSV-24] What state survives responsive recomposition, input change and panel exit?

- **A — Nothing.** For: safest reset. Against: punishes rotation/input switching.
- **B — Within the open activity: subject, source, filters/sort, focused instance, proposal,
  review position and meaningful focus; on ordinary exit keep no uncommitted proposal.** For:
  one coherent responsive experience. Against: requires stable IDs and focus restoration.
- **C — Save every staged proposal between visits.** For: resumable carts. Against: creates
  stale quote/reservation problems and save schema with little benefit.
- **Recommendation: B.** Announce changing totals/capacity as non-focus-stealing status; use
  text plus icon, meet touch targets, and provide non-drag operation for every action.

## Dependency disposition

`TSV-1..24` is the base packet and moves to the front of the transaction research queue.
The downstream shop/convoy research and responsive wireframes must wait for owner rulings,
then cite those rulings instead of reopening transaction states, confirmation, selector,
destination, capacity, error or reversal semantics.
