---
Type: register
Status: RESOLVED — DSX-1..28 walked 2026-08-15; rulings [DSX-S1]..[DSX-S29]
Last verified: 2026-08-15
Register: DSX-1..29
Tracker: DISTRIBUTION-SURFACE-2026-08-15
Resolved-in: this register — owner walk 2026-08-15
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Distribution Surface — Owner Questions

The `S5`+`S6` packet, widened by owner decision 2026-08-15 to cover every surface that moves a
limited thing onto a holder: **convoy, loadout, skills, techniques (styles), battalions, shop,
forge, on-map Trade and provider convoy access** — plus the dependent-choice layer (§G).

- Precedence diff (read first): [`distribution_surface_precedence_diff_2026-08-15.md`](../design/distribution_surface_precedence_diff_2026-08-15.md)
- Proof set (measured, not sketched): [`distribution_surface_proof_set.html`](../wireframes/albums/distribution_surface_proof_set.html)
- **Album, drawn to these rulings and AWAITING APPROVAL:** [`distribution_surface_album.html`](../wireframes/albums/distribution_surface_album.html)
  — 71 frames, nine consumers, six viewports. `UBS-6` lifts when it is approved (`[DSX-S28]`).

**What this packet does not touch.** Transaction semantics (`TSV-1..24`), shop header and currency
(`SHC`, `CUR`), the interaction rulings (`EPUX-08..17`), the forge design (`EPUX-23..28`, `FRG`),
the price model (`SHP-1..6` — see diff F1), the five assignable families (`SKL`, `STY`, `LDC`,
`BAT`) or the panel registry (`RPD-11`). Every one is cited, none is reopened.

---

## Owner rulings

Walked 2026-08-15. Rulings are `[DSX-S*]` and are recorded as they are taken.

### Block A — what the surface is (`DSX-1..3`)

- **`[DSX-S1]` — `DSX-1` → A. One shell, N registered adapters.** The shell owns composition,
  focus, the reason vocabulary, capacity presentation and the verb slot; an adapter supplies the
  pool, the holder, the detail sections and the verb labels. Consumers are data, and a new consumer
  costs a data block rather than a screen. **With one qualification taken in session: the escape
  hatch is *declared*, not improvised.** When a consumer eventually needs something the shell does
  not have, the resolution is either to widen the shell for everyone or to use a declared opt-out —
  never a bespoke screen that quietly leaves the family. `EPUX-03`'s full-width panel is the
  existing precedent for what "declared" means.
- **`[DSX-S2]` — `DSX-2` → A. Fixed roles: holder, pool, detail.** Every consumer fills all three;
  a consumer with nothing for a region gets that region's **empty state**, not a different layout.
  This is what lets the responsive collapse rules be written once. The shop's ruled Expanded
  composition (character sheet / list / detail, 2026-08-12) is this skeleton under other names.
- **`[DSX-S3]` — `DSX-3` → A. The shell owns the verb slot**, at the end of the detail column, with
  adapter-supplied labels. Consequence-before-action stays structural rather than remembered, which
  is what the 2026-08-12 single-scroll ruling bought and what an adapter-positioned action would
  give back. **Capped at two verbs in session: a primary plus one alternate.** Anything further is
  a pool row or a facet. Three verbs stop being readable in the 210 px on-map detail column, and an
  uncapped slot is how an adapter smuggles a bespoke action bar back into a shared shell.

### Block G — the dependent-choice layer (`DSX-23..28`)

- **`[DSX-S4]` — `DSX-23` → A. One layer, two kinds of second set.** *Counterpart* (another
  instance, which will be displaced or swapped) and *operation* (a transform applied to the first
  pick). One state machine, one commit rule, one cancel rule; the kind selects only how the set's
  rows are rendered. Three consumers existed the day it was proposed, and the third — equipping into
  a full cap — contains no trade and no economy, which is what makes it a primitive rather than a
  trade feature.
- **`[DSX-S5]` — `DSX-24` → A. The dependent set always takes the pool region; the result and the
  commit verb always take the detail.** Settled by measurement at 852×393 rather than by preference:
  pool placement wins for **both** kinds, by a full screen for the operation kind and by a wasted
  pane plus 0.9 screens for the counterpart kind. Option C's premise does not survive contact — once
  stage 2 begins the pool's original rows are no longer actionable, so keeping them visible costs a
  pane and buys nothing.
- **`[DSX-S6]` — `DSX-25` → yes, and the layer adds no confirmation of its own.** `RPD`'s ratified
  select-then-select gesture is adopted unchanged: commit on the second selection. **No engine
  default keyed on cost or irreversibility.** Confirmation stays `EPUX-06`'s authored, raise-only
  predicate on the action, and the shell's only obligation is to state the reversibility class
  (`[DSX-S*]` for `DSX-21`) in the result region before the verb. An author who wants a confirm on
  an expensive forge operation raises it there. **Recorded as a deliberate call, not an oversight:**
  a rule of the form "confirm when irreversible and spending" is exactly the engine-side risk
  classification `TSV-8` rejected and `RPD-9` rejected again, and this walk is the third time the
  argument has been available to take by accident.
- **`[DSX-S7]` — `DSX-26` → the first pick is focus, not a reservation.** Nothing is held; `TSV-2`
  was ruled moot. Cancelling at stage 2 returns to stage 1 with no mutation, which is `TSV-19`'s
  cancel-before-commit. The vocabulary is fixed as **pinned**, never "staged", so `DRC-30`'s
  cart/staged word collision cannot be re-litigated through wording.
- **`[DSX-S8]` — `DSX-27` → the empty slot is an entry in the set.** One gesture covers gift and
  swap; where nothing comes back the result region says so rather than naming an item. No second
  interaction exists to be learned or tested.
- **`[DSX-S9]` — `DSX-28` → adopted by Trade, forge, cap-full replacement (skills, techniques,
  battalions, loadout), and convoy transfer into a full holder.** Deployment placement is the fifth
  consumer and is **already ratified**, so the binding requirement is that this layer *absorbs*
  `RPD`'s gesture rather than shipping a second implementation of it. Registered as a named
  candidate in `R3`'s optimization pass in the same session, per the propagation rule.

### Block B — the Compact chain (`DSX-4..8`)

- **`[DSX-S10]` — `DSX-4` → A. A sequential chain at Compact**, with a context line carrying the
  holder's identity and cap figures. The holder step is **reachable but not on the path**: entering
  from Manage Roster the holder is already chosen, so the chain starts at the pool. Option C is
  unavailable — 209 px cannot hold two panes. **Extended in session: with `[DSX-S5]`, a stage-2
  operation is a four-step chain** (holder → pool → dependent set → result), one step deeper than
  anything else in the family. That is the family's step budget, ruled here rather than discovered
  while drawing the album.
- **`[DSX-S11]` — `DSX-5` → A. The ~1.9-screen detail column at the floor is accepted, and the
  reason leads.** Measured at 1.92 for a convoy transfer, 1.86 for a skill equip and 1.9 for a shop
  purchase — three unrelated consumers, one number, so it is the cost of consequence-before-action
  at 209 px rather than any one screen's problem. B would re-introduce the inversion the single-
  scroll ruling removed; C would hide consequence, which is the one thing that may not be hidden.
  The shop album's finding 2 (the failure reason is the worst casualty of the fold) is **promoted
  from a review note to a rule**: whatever else scrolls, the reason a commit was refused leads the
  step.
- **`[DSX-S12]` — `DSX-6` → A. The overlay opt-in is recommended in-surface**, as a one-time
  dismissible hint on first Compact entry, and never adopted automatically. Measured: 4.4 rows with
  the control band against 10.4 with the opt-in. B would change the layout without the player asking
  and would thrash the controller republish path — the defect class the existing suites structurally
  cannot catch. C would leave a 2.4× row difference undiscovered.
- **`[DSX-S13]` — `DSX-7` → `TSV-24` extends verbatim to every consumer**, plus two additions.
  Stepping back from detail to pool **restores focus to the row that was open**. And stepping back
  out of a dependent set **keeps the pinned pick** — the player is changing their mind about the
  counterpart, not about the item — with the pin dropped only on leaving the pool step entirely.
  This is what makes "Change" cheap rather than a restart.
- **`[DSX-S14]` — `DSX-8` → the context line is shell-owned**, built from the cap model
  (`DSX-13`), with the adapter supplying only the holder's display name. An adapter-authored string
  cannot be length-checked, and `L10N-7` binds this line to 1.4× text extent inside 360 px.

### Block C — on-map (`DSX-9..12`)

- **`[DSX-S15]` — `DSX-9` → A. Trade's second holder is a group header inside one pool**, with both
  capacity figures on the context line. It keeps `EPUX-03`'s two-pane cap and keeps the detail pane
  at the exact moment `DRC-30` needs it — to name the return item and carry the position-commit
  warning. **Softened by `[DSX-S5]`:** under the dependent-choice layer the second inventory *is*
  the counterpart set, so the grouped pool is the **entry state** — both inventories visible, the
  pick taken from the actor's own, and the counterpart list then replacing the pool. A is the
  composition that makes that transition legible instead of a jump between two screens.
- **`[DSX-S16]` — `DSX-10` → A. An on-map distribution surface takes the canvas region only, never
  the control band**, with `SHC-5`'s vertical rail in landscape. Measured: the rail buys 90 px of
  height (window 250 → 340 px, 5.2 → 7.1 rows, battlefield-shop detail 1.81 → 1.33 screens),
  reproducing the `SHC` walk's landscape gain to within a tenth of a row. C is unavailable at 524
  px; B breaks the never-overlap-the-canvas rule and thrashes the controller. This is `DRC`'s
  conversation ruling applied to a second surface rather than a new rule.
- **`[DSX-S17]` — `DSX-11` → B. One adapter, a context-declared verb set.** The provider convoy
  exposes Deposit/Withdraw and nothing else; the battlefield shop exposes Buy/Sell. This is option A
  plus the one restriction `CNV-5` already requires — no browsing other units' inventories
  mid-battle — expressed as a verb set rather than as a different screen, which is what keeps
  "same interface, different trigger" true in implementation and not only in intent.
- **`[DSX-S18]` — `DSX-12` → the position-commit warning is an ordinary consequence line in the
  detail, above the verb.** Not a confirmation dialog. Committing an actor's position mid-battle is
  consequential enough that a dialog is the instinctive answer, which is exactly why it is ruled
  explicitly: `EPUX-06` owns confirmation as an authored, raise-only predicate, and a hardcoded
  dialog here would be the engine weakening that. A campaign that wants a confirm on Trade raises
  one on the action.

### Block D — caps, capacity and quantity (`DSX-13..15`)

- **`[DSX-S19]` — `DSX-13` → A. One shell-level cap model** — label, current, limit, an `unlimited`
  sentinel, and an after-this-action projection — rendered identically for `max_inventory`,
  `convoy_capacity`, `max_skills`, `max_styles`, `max_sources` and the battalion's single slot.
  `LDC-1` already unified the mechanism; presenting it six ways would re-fork what that ruling
  merged. The sentinel renders as a hatched bar rather than a fraction, because "62 items ·
  uncapped" has no denominator — the case option B would have got wrong six separate times.
- **`[DSX-S20]` — `DSX-14` → the after-action projection is mandatory** whenever an action changes
  a cap figure. It is `TSV-6`'s consequence obligation applied to the assignment half of the family,
  and it is what makes `[DSX-S6]`'s no-confirm defensible: when the commit lands on the second
  selection, the projection is the only thing standing between the player and a surprise.
- **`[DSX-S21]` — `DSX-15` → A. The pending-items tray is a holder-region section**, present only
  when non-empty, with its prep-exit gate expressed through the existing availability predicate
  (`EPUX-02`/`EPUX-07`) so that "cannot leave prep: 3 pending items" is the same reason string as
  every other gate. C would invent a sixth availability vocabulary, which `RPD-10` already did once
  and had to be walked back. **Consequence noted in session:** because `[DSX-S2]` gives every
  consumer a holder region, the tray is visible from convoy, loadout or skills alike — which is
  correct, since it is a prep-exit obligation rather than the property of the screen that created it.

### Block E — rows and authoring (`DSX-16..18`)

- **`[DSX-S22]` — `DSX-16` → A. `--row` is a floor, not a height.** Rows grow when their content
  does; the density token is a minimum. Measured: a name plus a sub-line is 35 px against a 28 px
  `--row` at controller density, a 25% overrun before `L10N-7`'s 1.4× extent applies. B would drop
  the sub-line and with it durability, holder and state — the information the sub-line exists to
  carry. C would change every screen in the program on one screen's evidence.
- **`[DSX-S23]` — `DSX-17` → A. The author supplies a row-field priority order; the size class
  truncates it against a per-class budget.** `CNV-8`'s author-selected field set predates the
  responsive programme, so this resolves the collision rather than reopening the ruling. B would
  hand an author a way to break the 360×640 floor; C would discard a ratified authoring lever.
- **`[DSX-S24]` — `DSX-18` → A. Bulk operations report in a dismissible result panel in the detail
  region**, listing moved and kept-with-reason, using the `EPUX-07` reason contract for "kept: not
  transferable" and announced as non-focus-stealing status per `TSV-24`. This is the same region
  `[DSX-S5]` gives the stage-2 result — one region with two reasons to show an outcome, which is
  consistency rather than crowding.

### Block F — the handed-over residue (`DSX-19..22`)

- **`[DSX-S25]` — `DSX-19` → A. The shop album's composition is the family skeleton, and the album
  stands unchanged.** The character sheet is the holder; the category tab strip is the control row's
  facets. The unification is a naming change with no redraw — the cheapest one available.
- **`[DSX-S26]` — `DSX-20` → C. Both, with the detail line mandatory.** A no-receipt store carries a
  persistent line in the detail above the verb, and a one-time-per-visit notice at entry. An entry
  notice alone has been forgotten by the third purchase; a line above the verb is read at the moment
  it matters. This is the one place in the family where the **absence** of a mechanism has to be
  visible, so it is deliberately over-stated. Discharges the problem `TSV`'s consequence 5 assigned
  to this session by name.
- **`[DSX-S27]` — `DSX-21` → three reversibility classes, declared per consumer and stated once in
  the shell:** *freely reversible* (assignment), *reversible until exit* (receipt-bearing
  activities), *irreversible* (no-receipt stores). This is load-bearing rather than descriptive:
  `[DSX-S6]` made the reversibility statement the shell's substitute for a confirmation, so these
  three classes are what that ruling stands on.
- **`[DSX-S28]` — `DSX-22` → NOT as recommended. `UBS-6` lifts when the album is approved, not at
  the walk.** The owner's order: draw the family's album sheets to these rulings, have them
  approved, and only then lift the gate. The gate therefore turns on a verified artifact rather than
  on the intent to produce one. **Follow-up this creates:** `UBS-8` was lifted at the close of the
  `CEUI` walk on 2026-08-14, before its editor album was approved, so the two surviving gates were
  released by different standards. Raised at the walk and left open — see the note below.

### Follow-up ruled after the walk

- **`[DSX-S29]` — `UBS-8`'s lift is provisional too (owner, 2026-08-15).** The consistency question
  `[DSX-S28]` raised is answered by extending the stricter standard rather than narrowing it: **a
  `UBS` gate turns on its album being approved, not on its walk closing.** `UBS-8` was lifted at the
  close of the `CEUI` walk on 2026-08-14, before its editor album was approved, so that lift is now
  provisional on the same terms as `UBS-6`. Both surviving gates are released by one rule, and `R2`
  waits on approvals rather than walks. Propagated in session to the `UBS` agenda, the `CEUI`
  register and the sequencing plan's Stage C and `R2` entries.

---

## A. What the surface is

### [DSX-1] Is this one surface with adapters, or a family of related screens?

The proof set draws one skeleton — **holder · pool · detail** — for all eight consumers, and at
1920×1080 every consumer fits it with content extents of 145–407 px against a 982 px window.

- **A — One shell, N registered adapters.** The shell owns composition, focus, the reason
  vocabulary, capacity presentation and the verb slot; an adapter supplies the pool, the holder,
  the detail sections and the verbs. Consumers are data.
- **B — A shared component kit**, each screen composed separately from the same parts.
- **C — Related but independent screens** held consistent by review.
- **Recommendation: A.** `LDC-1` already rules one mechanism, `EPUX-24` one transaction core,
  `RPD-11` one panel registry, and `TSV-10` one selector contract. B and C are how the program
  acquires the four selectors `UBS-2` was written to prevent. A also makes the eighth consumer
  free, which matters because three of the eight arrived in this session alone.

### [DSX-2] Are the three regions named and fixed, or is the composition per-consumer?

- **A — Fixed roles: holder, pool, detail.** Every consumer fills all three; a consumer with
  nothing to put in a region gets the region's empty state, not a different layout.
- **B — Per-consumer composition** chosen from a menu of regions.
- **Recommendation: A**, because the responsive collapse rules (`DSX-4`, `DSX-6`) can only be
  written once if the regions are the same everywhere. The shop's ruled Expanded composition
  (character sheet / list / detail) already **is** this skeleton — see `DSX-19`.

### [DSX-3] Does the shell own the verb slot, or does each adapter draw its own actions?

- **A — Shell-owned verb slot at the end of the detail column**, adapter-supplied labels.
  Consequence-before-action stays structural, as the 2026-08-12 single-scroll ruling made it.
- **B — Adapter-drawn actions**, positioned per consumer.
- **Recommendation: A.** The docked-action failure that ruling fixed was a *position* bug, and a
  position bug can only be fixed once if position is not an adapter's choice.

---

## B. The Compact chain

### [DSX-4] What is the Compact composition?

Measured at the 360×640 floor with the control band: chrome 117 px, canvas 352 px, pane window
209 px.

- **A — A three-step sequential chain** (holder → pool → detail) with a context line carrying the
  holder's identity and cap figures.
- **B — Two steps**, folding the holder permanently into the context line.
- **C — Pool and detail as a two-pane split at Compact.** 209 px cannot hold two panes.
- **Recommendation: A**, with the holder step reachable but not on the path: entering from Manage
  Roster the holder is already chosen, so the chain starts at the pool. C is unavailable.

### [DSX-5] The detail column measures ~1.9 screens at the floor for a *routine* operation. Is that accepted?

Convoy transfer 1.92, skill equip 1.86, shop purchase 1.9 (album). Three unrelated consumers, one
number — it is the cost of consequence-before-action at 209 px.

- **A — Accept it.** Scrolling a detail column is ordinary; the ruling that produced it exists
  precisely so the consequence cannot be skipped.
- **B — Prioritize within the detail**, showing consequence and verb first with the rest behind a
  More Info step.
- **C — Shorten the content** at Compact by dropping sections.
- **Recommendation: A, plus a rule that the *reason* leads.** The shop album's finding 2 already
  says the failure reason is the worst casualty of the fold. B re-introduces the inversion the
  single-scroll ruling removed; C hides consequence, which is the one thing that must not be hidden.

### [DSX-6] Does the overlay opt-in become the recommended configuration for this family?

With the control band: 4.4 rows. With the `UUI-12` opt-in: 10.4 rows, and the pool fits in one
window.

- **A — Recommend it in-surface** — a one-time, dismissible hint on first entry at Compact.
- **B — Adopt it automatically** for this family and restore the band on exit.
- **C — Leave it as a global setting** with no surface-level treatment.
- **Recommendation: A.** B is a layout change the player did not ask for and would thrash the
  controller republish path; C leaves a 2.4× row difference undiscovered.

### [DSX-7] What survives a step-back in the chain?

`TSV-24` already rules that subject, source, filters, sort, focused instance, active quote, review
position and meaningful focus survive recomposition and input change.

- **Recommendation: extend `TSV-24` verbatim to every consumer**, and add that stepping back from
  detail to pool restores focus to the row that was open. No new rule, one more consumer set.

### [DSX-8] Is the context line's content fixed or adapter-supplied?

It carries the holder's identity plus cap figures in one 360-px line, and `L10N-7` binds it to 1.4×
text extent.

- **Recommendation: shell-owned, built from the cap model** (`DSX-13`), with the adapter supplying
  only the holder's display name. An adapter-authored string cannot be length-checked.

---

## C. On-map

### [DSX-9] Trade has two holders. Does the second fold into the pool?

The only consumer that is holder↔holder. `EPUX-03` caps adjacent panes at two.

- **A — The second holder is a group header inside one pool** (drawn in the proof set): both
  inventories in one list, both capacity figures in the context line.
- **B — Two pools side by side**, detail suppressed until a swap is chosen.
- **C — A dedicated Trade composition** outside the skeleton.
- **Recommendation: A.** It keeps the two-pane cap, keeps the detail pane that must state the return
  item and the position-commit warning, and keeps Trade inside the family. B loses the detail pane
  at the moment `DRC-30` most needs it; C is the fourth selector.

### [DSX-10] Does an on-map distribution surface take the canvas region only?

Proposed: yes — the same ruling `DRC` made for conversations at Compact (`UBS-4`).

- **A — Canvas only, never the control band**, with `SHC-5`'s vertical rail in landscape.
- **B — Full-screen modal over the battle.**
- **C — Inside the control region.**
- **Recommendation: A.** Measured: the rail buys 90 px of height (250 → 340 px window, 5.2 → 7.1
  rows, battlefield-shop detail 1.81 → 1.33 screens), and it reproduces the `SHC` walk's landscape
  gain to within a tenth of a row. C is unavailable at 524 px; B breaks the never-overlap-the-canvas
  rule and thrashes the controller.

### [DSX-11] Is the battlefield shop *identical* to the prep shop, or the same interface with a reduced verb set?

Owner 2026-08-15: same interface, different trigger. `CNV-5` separately restricts on-map convoy
access to deposit/withdraw with no browsing of other units.

- **A — Identical adapter; context supplies only the subject and the region.**
- **B — One adapter, a context-declared verb set** (the provider convoy shows Deposit/Withdraw and
  nothing else; the battlefield shop shows Buy/Sell).
- **Recommendation: B**, which is A plus the one thing `CNV-5` already requires. The restriction is
  a verb set, not a different screen — that is what keeps "different trigger" true.

### [DSX-12] Where does the position-commit warning live?

`CNV-5` and `DRC-30`: opening and cancelling is free; the first committed transfer commits the
actor's location and marks the once-per-activation usage.

- **Recommendation: in the detail, above the verb, as an ordinary consequence line** — not a
  confirmation dialog. `EPUX-06` makes confirmation an authored, raise-only predicate on the action;
  a hardcoded dialog here would be the engine weakening that, and `TSV-8` lost the same argument.

---

## D. Caps, capacity and quantity

### [DSX-13] Is there one cap model across items, skills, techniques, battalions and convoy?

Five caps exist: `max_inventory`, `convoy_capacity` (sentinel = unlimited), `max_skills`,
`max_styles`, `max_sources`, plus the battalion's implicit one slot.

- **A — One shell-level cap model**: label, current, limit, an `unlimited` sentinel, and an
  after-this-action projection. Rendered identically everywhere.
- **B — Per-consumer capacity presentation.**
- **Recommendation: A.** `LDC-1` already unified the *mechanism*; presenting it five ways would
  re-fork what that ruling merged. The proof set draws the sentinel as a hatched bar rather than a
  fraction, because "62 items · uncapped" has no denominator.

### [DSX-14] Is the after-action projection mandatory?

The frames show "After equipping: 5/5 — full" and "Destination: Arden · 6/8".

- **Recommendation: mandatory whenever the action changes a cap figure.** It is the same obligation
  as `TSV-6`'s consequence, applied to the assignment half of the family.

### [DSX-15] How is the pending-items tray surfaced?

`EPUX-11` ruled unavoidable acquisitions go to a pending tray resolved before leaving prep, default
hold-pending. `DRC-31` sends map-end sweep overflow to the same tray. It has never been designed.

- **A — A holder-region section** that appears only when non-empty, with an exit gate.
- **B — A separate prep panel** in the Manage Roster registry.
- **C — A blocking dialog on prep exit.**
- **Recommendation: A**, with the exit gate expressed through the existing availability predicate
  (`EPUX-02`/`EPUX-07`) so "cannot leave prep: 3 pending items" is the same reason string as every
  other gate. C invents a sixth availability vocabulary; `RPD-10` already was a sixth once.

---

## E. Rows, authoring and reporting

### [DSX-16] The controller row token is a single-line token. What is the contract?

Measured: a name plus a sub-line renders **35 px against a 28 px `--row`** at controller density — a
25% overrun before `L10N-7`'s 1.4× extent applies.

- **A — Rows grow; the token is a minimum.** Honest, and the layout never clips.
- **B — Sub-line is dropped at controller density.** Loses durability, holder and state — the
  information the sub-line exists to carry.
- **C — Raise the controller row token** and re-measure every screen that uses it.
- **Recommendation: A**, and record that `--row` is a floor rather than a height. C is a
  program-wide change made from one screen's evidence.

### [DSX-17] `CNV-8` lets the author select row fields. Against a 360-px row, is that absolute?

`CNV-8` (2026-06-30) predates the responsive programme: name, uses info, count, base value, stack
value, author-chosen.

- **A — The author supplies a priority order; the size class truncates against a per-class budget.**
- **B — The author's selection is absolute at every size class.**
- **C — Engine-fixed fields.**
- **Recommendation: A.** B hands an author a way to break the 360×640 floor, and `L10N-7` already
  binds every responsive component to 1.4× extent; C discards a ratified authoring lever.

### [DSX-18] Where do `EPUX-12`'s bulk operations report?

Send All to Convoy halts on a full convoy and reports what moved; Resupply reports every swap; both
are "player-directed and fully reported, never silent". A receipt is not available — `TSV-20/21`
ruled receipts a store-declared surface and there is no per-receipt undo.

- **A — A dismissible result panel in the detail region**, listing moved / kept-with-reason.
- **B — A status announcement only.**
- **C — A modal summary.**
- **Recommendation: A**, using the `EPUX-07` reason contract for "kept: not transferable", announced
  as non-focus-stealing status per `TSV-24`. B loses the list; C is a modal for a non-blocking event.

---

## F. Handed-over residue

### [DSX-19] Does the shop album's composition become the family skeleton?

The album's ruled Expanded composition is character sheet / list / detail with category tabs on top.
The distribution skeleton is holder / pool / detail. The proof set draws them as the same three
columns.

- **A — Yes; the album stands unchanged and the region names generalize.** The character sheet *is*
  the holder; category tabs are the control row's facets.
- **B — Redraw the shop to the skeleton** where they differ.
- **Recommendation: A.** Owner has already said the album stands; the measurement says it need not
  move. This is the cheapest possible unification — a naming change.

### [DSX-20] How does a player know, before spending, that a store issues no receipt?

`TSV`'s consequence 5 assigned this problem to this session by name: where no receipt is declared
there is no reversal of any kind, and *"the player has to be able to tell, before spending, which
kind of store they are standing in."*

- **A — A persistent line in the detail, above the verb**, on every no-receipt transaction ("This
  store issues no receipt: once bought, the visit cannot be restored").
- **B — An entry-time notice** when the session opens.
- **C — Both.**
- **Recommendation: C**, with A mandatory and B a one-time-per-visit status. A notice seen once at
  entry has been forgotten by the third purchase; a line above the verb is read at the moment it
  matters. This is the only place in the family where the *absence* of a mechanism has to be
  visible, so it should be over- rather than under-stated.

### [DSX-21] Does the family need an entry-time distinction between reversible and irreversible sessions at all?

`EPUX-06`/`EPUX-28` give activities an optional exit receipt with rollback to an activity-entry
snapshot; the forge inherits it (`EPUX-28`); assignment operations (skills, techniques, battalions,
loadout) are freely reversible by re-assignment and need no receipt at all.

- **Recommendation: three classes, stated once in the shell** — *freely reversible* (assignment),
  *reversible until exit* (receipt-bearing activities), *irreversible* (no-receipt stores). Every
  consumer declares which it is, and `DSX-20`'s line is the third class's presentation. Without this
  the player has to infer reversibility per screen, which is exactly what `TSV` flagged.

### [DSX-22] Does `UBS-6` lift at this walk, or at the album?

`UUI-15` holds convoy and shop out of the wireframe album until their session runs; `S7`/`S8`
(compendium) is the only other survivor.

- **Recommendation: lift at the walk**, with the full album drawn to the rulings afterward — the
  order the editor arc used. The proof set is not the album; it is the measurement that makes the
  album drawable.

---

---

## G. The dependent-choice layer

Owner proposal, 2026-08-15: a shared layer where the player picks one thing and is then given a
second set of choices that exists only because of the first. Trade picks an item, then a counterpart
in someone else's inventory; the forge picks an item, then a modification to apply to it.

**Two things found before drawing it.** `RPD` already ratified this gesture for deployment placement
— *select-then-select, committing on the second selection, no confirm, because a swap is reversible
and so earns no `CAU-4` tag*. And `EPUX-26` rejected a second navigation **level** for the forge
(`item → mode → operation`) on `EPUX-03` pane-budget grounds — but it named no pane, so a second
choice **set** that replaces a region is not what it rejected.

### [DSX-23] Is this one layer with two kinds of second set?

- **A — One layer, two kinds.** *Counterpart* — another instance, which will be displaced or
  swapped. *Operation* — a transform applied to the first pick. One state machine, one commit rule,
  one cancel rule; the kind selects only how the set's rows are rendered.
- **B — Two mechanisms**, one for trade-like swaps and one for forge-like operations.
- **Recommendation: A.** The proof set draws a third consumer — replacing a skill at a full cap —
  which is a counterpart set with no trade and no economy in it. A layer that already has three
  consumers on the day it is proposed is a primitive, not a feature.

### [DSX-24] Which region does the dependent set take?

Drawn both ways and measured at 852×393, the tightest viewport in the program:

| | Pool region | Detail region |
|---|---|---|
| Trade, set in the **pool** (P) | set, **fits** | result + verb, 1.26 screens |
| Trade, set in the **detail** (D) | stale inventory, 1.62 screens | set + result, **2.14 screens** |
| Forge, set in the **pool** (P) | set, **fits** | result + verb, 1.05 screens |
| Forge, set in the **detail** (D) | eligible items, fits | set + result, **2.04 screens** |

- **A — The set always takes the pool; the result and commit verb always take the detail.**
- **B — Placement per kind** (counterpart in the pool, operation in the detail).
- **C — Always the detail**, keeping the pool visible.
- **Recommendation: A, and the measurement is not close.** P beats D for *both* kinds at 852×393 —
  by a full screen for the operation kind, and for the counterpart kind by a whole stale pane on
  top of 0.9 screens. C's supposed benefit is illusory: once stage 2 begins, the pool's contents are
  no longer actionable, so keeping them costs a pane and buys nothing. A also keeps one rule instead
  of two, and adds no navigation level, which is what `EPUX-26` actually forbade.

### [DSX-25] Does the layer commit on the second selection?

- **Recommendation: yes — adopt `RPD`'s ratified gesture unchanged**, and let confirmation stay
  where `EPUX-06` put it: an authored, raise-only predicate on the action. The layer must never add
  a confirm of its own. Where the operation is *not* reversible — a no-receipt forge, a Trade that
  commits the actor's position — the warning is `DSX-21`'s reversibility class stated in the result
  region, not a dialog. `TSV-8` and `RPD-9` both lost the argument for engine-side risk
  classification; this must not be the third attempt.

### [DSX-26] Is the first pick a reservation?

- **Recommendation: no. It is focus, and nothing is held.** `TSV-2` (does staging hold funds, stock
  or item instances) was ruled **moot**; cancelling at stage 2 returns to stage 1 with no mutation,
  which is `TSV-19`'s cancel-before-commit. Record this next to `DRC-30`'s word collision: a cart
  accumulates intent **across** selections, and this is one operation with two selections. The
  packet uses "pinned", not "staged", for the first pick, so the collision cannot be re-litigated by
  vocabulary.

### [DSX-27] Does the empty-slot case belong to the layer?

When the trade target has a free slot, nothing needs to come back.

- **Recommendation: the empty slot is an entry in the set.** One gesture covers gift and swap, the
  result region states "nothing returns" instead of naming an item, and there is no second
  interaction to learn. Drawn only as a note in the proof set — the frame shows the full-inventory
  case, which is the harder one.

### [DSX-28] Which consumers adopt it, and what must not happen?

- **Recommendation: Trade, forge, cap-full replacement (skills, techniques, battalions, loadout),
  and convoy transfer into a full holder.** Deployment placement is the fifth and it is **already
  ratified** — so the requirement is that the layer *absorbs* `RPD`'s gesture rather than becoming a
  second implementation of it. That check belongs in `R3`'s optimization pass, where "repeated
  mechanisms that should be one" is the stated yield.

## Consequences to check at the walk

1. **Eight consumers, one shell** means every ruling here is taken eight times over. Anything ruled
   "per consumer" should be justified by a difference in the *content*, not in the screen.
2. **Three of the eight consumers arrived on 2026-08-15.** If the shell is right, that should have
   been cheap — and it was: the frames took an adapter each. That is the argument for `DSX-1 A`, and
   also the test of it.
3. **The unbuilt engine pieces this names** are the ones `TSV` already named — the transaction
   participant registry (`EPUX-24`), the shared selector with stable instance IDs (`TSV-10`,
   `TSV-24`), deterministic stack expansion (`TSV-11`), the pending-items tray (`EPUX-11`) — plus
   one new: **a cap model** (`DSX-13`) that presents `max_inventory`, `convoy_capacity`,
   `max_skills`, `max_styles`, `max_sources` and the battalion slot identically.
