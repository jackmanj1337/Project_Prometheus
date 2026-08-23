---
Role: dated
Type: plan
Status: Planned — opens `DRC-PLAN-REDERIVATION-2026-08-13`; unblocked, nothing waits on it
Last verified: 2026-08-13
Tracker: DRC-PLAN-REDERIVATION-2026-08-13
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
---

# Next-session handoff — re-derive the dialogue/recruit/capture implementation plan

**The task.** Bring
[`dialogue_recruit_capture_integrated_implementation_plan_2026-07-27.md`](dialogue_recruit_capture_integrated_implementation_plan_2026-07-27.md)
back into agreement with the decisions it derives from, and clear its **Needs revision** marker.

**This is not a research walk.** Every question the plan derives from is now ruled — `DRC-1..33` was
closed across four sittings on 2026-08-13 and the register is `RESOLVED`. Nothing here is
reopenable. If a section of the plan looks wrong, the fix is to change the plan, not to re-ask the
question.

**What it unblocks:** thirteen tracker rows — `DRC-V1-S00..S11` and `EPIC-DIALOGUE-CUSTODY-V1` —
which currently describe a design that no longer holds and may not be picked up for build.

---

## The finding that should shape the session

**The plan is in materially better shape than its tracker row implies.** The row's prose reads as
though the spine is invalid. It is not. Two of the three architecture sections that carry the most
weight already anticipate rulings made sixteen days later:

- **§3.1 already lists exactly `DRC-19`'s five dimensions** — `affiliation_id`, `tactical_side_id`,
  `controller_id`, `roster_status`, `custody_status` — and already names a single
  `UnitTransitionService` as "the only writer", which is the transition-ownership ruling that
  unwound `[RCR-3]`'s inversion.
- **§3.1 already says "do not store derived booleans such as `is_recruited` or `captured:<id>` as
  competing authorities."** That is the ruling `[RCR-2]`'s auto-set `recruited:<id>` flag lost to.
  The plan was right and the register was wrong.
- **§3.3 already puts `ActionJournal` "above `ActionPrimitiveRunner`, not inside the dialogue UI"**,
  with staging, a read-only base view, an overlay and one commit/abort boundary — which is `DLUX`
  §7.3's ownership rule and most of the staged-transaction primitive.
- **§3.2's requirements already "return truth plus a localized unmet-reason descriptor"**, which is
  `[EPUX-02]`'s reason surface.

So budget the session for **surgical reconciliation across a plan that is mostly sound**, not a
rewrite. The divergences below are real but bounded, and several are naming rather than structure —
which matters, because a naming divergence left in place is how four ratified mechanisms came to
exist for one concept in the first place.

---

## Read in this order

1. **The register's four owner-ruling sections dated 2026-08-13**, in
   [`dialogue_recruit_capture_research_questions_2026-07-27.md`](../registers/dialogue_recruit_capture_research_questions_2026-07-27.md).
   This is the decision source. The pre-walk recommendation text above those sections is **not** —
   several recommendations were rejected.
2. **The three precedence diffs** —
   [`skf_drc_precedence_diff`](../design/skf_drc_precedence_diff_2026-08-13.md),
   [`drc_group_a_precedence_diff`](../design/drc_group_a_precedence_diff_2026-08-13.md),
   [`drc_groups_bcde_precedence_diff`](../design/drc_groups_bcde_precedence_diff_2026-08-13.md).
   **Eleven questions were disposed of without ever being asked.** The plan must not reintroduce
   them.
3. **Session notes** `2026-08-13-18-32-29Z` (Groups A–E) and `2026-08-13-11-40-00Z` (the first
   walk).

---

## Concrete divergences, by plan section

### §2 — "Assumptions that this work must replace"

The list is correct but now **incomplete**. Add:

- **`[RCV-4]`'s `recruit(unit)` contract is gone**, replaced by the sparse five-dimension patch. It
  cannot represent `DRC-21`'s ruled map-end expiry at all.
- **`[RCR-2]`'s auto-set `recruited:<id>` flag is retired** in favour of `[REQ-13(b)]` runtime
  unit-state predicates. (The plan already forbids the *shape*; name the specific retirement so a
  reader of `RCR` finds it.)
- **`[RCR-3]`'s inversion** — the roster held an API writing four dimensions it does not own.

### §3.1 — Unit state and transitions

Three changes, one of them structural:

1. **The request is a SPARSE PATCH, not a before/after pair.** `DRC-20` ruled a sparse patch over
   all five dimensions with *unset meaning unchanged*. §3.1 currently says "requested before/after
   fields". This is the divergence most likely to be built wrong if left: the written field list
   that `DRC-20` inspected covered only **three** of the five dimensions, so a transition could not
   move a recruited enemy out of the enemy turn group.
2. **The patch scope is the five dimensions AND NOTHING ELSE** (`DRC-23`, narrowed by the owner past
   the recommendation). §3.1's request currently also carries inventory operations, emitted
   facts/milestones and story-override authority. Behaviour changes — AIP profile, scripted order —
   move to **the effect system, bundled into the recruitment presets**, so there is one mechanism
   for "recruitment also changes X" rather than two.
3. **Add `target_activation`** (`DRC-20`, renamed from the ambiguous `activation_policy`;
   `DRC-22` ruled **preserve** as the default with refresh permitted under a `[DLUX-10]` author-time
   warning). Note the split by subject: `DRC-13`'s interaction-policy registry owns the **actor's**
   cost; the transition owns the **target's** arrival. §3.1 currently has "recruitment
   duration/expiry" and nothing on activation.

### §3.3 — Atomic action journals

**Re-express in the two-primitive vocabulary.** The journal is a **consumer** of the staged
transaction, not the primitive itself. The ruling unified four ratified mechanisms — `MapLedger`,
`[EPUX-24]`'s transaction core, `[EPUX-06]`'s activity snapshot, and this journal — into:

- a **staged transaction** (overlay + commit/discard), consumed by the dialogue journal, the map-end
  pipeline, `EPUX-24`'s core and Trade;
- a **snapshot** (capture + restore *including the RNG stream*), consumed by `MapLedger` and
  `EPUX-06`'s receipt, with retention/charging/trigger policy layered on top.

Record the nesting explicitly, because the plan currently cannot express it: **a conversation
STAGES inside an activity that is SNAPSHOT.** Prefer staging; snapshot only to undo something
already committed. Add the derived consequence: **an open conversation does not count against
`[EPUX-06]`'s at-most-one-gated-activity invariant** — that invariant bounds snapshot cost, and the
other reading would forbid a conversation inside a gated activity and break Prison outright.

**Also record the word collision** so it is not later read as a contradiction: `TSV`'s *"no
staging"* forbids a **user-visible cart**; the two-primitive *staged transaction* is an **internal
atomic commit**. Different concepts, same word.

### §3.5 — Inventory interactions

- **Trade commits ONE TRANSACTION PER SWAP** (`DRC-30`) — the only `TSV`-consistent reading, and
  what `DRC-30`'s own first-swap-marks-traded rule presupposes.
- **Consume `[EPUX-24]`'s transaction core and `[EPUX-21]`'s quantity primitive BY NAME.** Do not
  let Trade become a third transaction implementation beside shop and convoy.
- **Captive-trade permission comes from `DRC-12`'s descriptor predicate**, not a controller fiction.
- The transition record **REFERENCES** ledger entries rather than embedding them (`DRC-33`) —
  embedding would duplicate the item-instance ledger `DRC-30` already owns.

### §3.6 — Dialogue data and presentation

- **Flat ordered entries with stable line IDs; no runtime node objects** (`DRC-2`). Jumps, labels
  and requirements target a line ID directly.
- **Tool-generated stable ID plus an optional author alias** (`DRC-4`); the alias is what jumps,
  exports and localization keys use, and the validator enforces alias uniqueness within the pack.
- **Profiles are `[DLUX-3]`'s**: `story`, `map_talk`, `support`, `bark`. **`prison_visit` is
  dropped** — Prison invokes `story`, and `DRC-31` already routed its policy elsewhere.
- **`UBS-4` placement:** dialogue occupies the **canvas region only, never the control band**, at
  every size class; `story` takes the full canvas, `map_talk` a lower band that shrinks
  proportionally as the class grows. In gamepad mode the pad reaches history, pause, skip, advance,
  and **scrolls a line within its line object** — which is also the answer to `[L10N-7]`'s 1.4×
  extent.
- **`[DLUX-16]` stage direction:** the stage is **screen-absolute and non-mirroring**; the box
  justifies to reading direction and renders `Speaker: line` as **one inline run from a single
  localizable template** — never `name + ": " + text` assembled in GDScript.
- **`DRC-9` stands, and is now structural:** a conversation *is* a staged transaction, so nothing
  leaks into a save by construction rather than by rule.

### §3.7 — Explore and Prison

- **Capture is registered methods** with v1 = `non_lethal_carry` **plus a first-class
  `take_custody`**, so story capture stops faking a sleep status it does not mean (`DRC-27`).
- **The capture method is a field group on the EXISTING `DRC-13` interaction entry, NOT a second
  registry.**
- **`custody_status` is authoritative; carry is DERIVED** (`DRC-29`). `CarryRegistry` keeps the
  physical mechanics but is not a second source of truth.
- **One `incapacitated_and_carryable` profile** from existing `REQ` terms, with the size /
  carry-capacity term **deferred** — it needs a unit size attribute that does not exist (`DRC-28`).
- **The transition attaches to the OPPORTUNITY, with no `recruitable` truth flag on the unit**
  (`DRC-25`).
- **Prison commits stay REVERSIBLE** through the `[EPUX-06]` exit receipt, uniformly, with no
  carve-out for recruitment.
- **The map-end sweep takes `[EPUX-11]`'s PENDING-ITEMS TRAY**, not fail-before-commit (`DRC-31`) —
  a residual-captive sweep is an *unavoidable* acquisition, and the wrong reading would **halt
  map-end resolution on a full convoy**.
- **Automatic map-end disposition EMITS the `CAU-4` `execution` tag but does NOT confirm**
  (`DRC-32`) — confirmation attaches to player-initiated actions, and automatic resolution has no
  decision point. It surfaces in the map-end report.

### §3.2 / eligibility disclosure

- Eligibility uses the **shared two-value Requirement vocabulary** — absent hides, gated shows
  disabled with a reason — and **the tactical map is a fifth `[EPUX-02]` surface** (`DRC-11`).
  `secret|hinted|explicit` was rejected; *hinted* becomes authored content on `[EPUX-07]`'s reason.
- **New since the `DRC` walk, and it applies here too:** disabled entries are **focusable but not
  activatable**, at the shell, across all five surfaces (`[RPD-15]`, 2026-08-13). If the plan
  specifies focus behaviour for gated Talk/recruit entries, it inherits this rather than deciding it.
- **`CAU-4` gained `recruitment`, `custody_change` and `execution` tags**, closing `DRC-14`.
  Confirmation authority is **split by origin**: an author's predicate on a specific action is a
  floor no player setting can lower; `CAU-4`'s presets govern the **engine-derived tag set only**.

### §5 — Slices

Re-check these four; the rest should survive:

- **Slice 2 (unit state + transition service)** — absorbs the sparse-patch shape, the
  five-dimensions-only scope, `target_activation`, and the single-writer ownership.
- **Slice 5 (Trade and Convoy)** — absorbs per-swap commit and the by-name consumption of
  `EPUX-24`/`EPUX-21`.
- **Slice 6 (conversation catalogue, validator, journal)** — absorbs flat entries, tool-generated
  IDs, `DRC-17`'s **four residue checks that block** (graph reachability, unsafe cycles, duplicate
  consequences, recruit/capture target compatibility) and that **authored fixtures are supported,
  not mandatory** — making them mandatory would gate the fork-a-public-pack onboarding model behind
  writing tests.
- **Slice 9 (map-end resolver)** — absorbs the pending-items tray, the emitted-not-confirmed
  execution tag, and the snapshot/stage nesting.

---

## Propagation debts to fold in

None blocking; all were recorded for this re-derivation.

1. **`[RCR-4]` owes `[REQ]` a banner — the load-bearing one.** `REQ` absorbed recruit eligibility in
   June under "one evaluator + one display path" and `RCR-4` records none of it. It matters because
   **`REQ`'s display path supplies the reason string `DRC-11`'s fifth-surface ruling depends on** —
   and, since 2026-08-13, `[RPD-10]`'s deploy-eligibility too.
2. **`[RCR-7]`/`[RCV-6]` save reservations predate the five-dimension model.**
3. **`[REQ-13(b)]`'s `is_captured` should read `custody_status`.**
4. **`[RCV-4]`, `[RCR-3]` and `[RCR-2]` need amendment banners.** `RCV-4` still named `RCR-1`'s
   superseded faction flip **by name** as its contract as of the Group A check.

---

## Do not reopen

- **The eleven questions disposed of without being asked.** Eight closed by precedence against
  `DLUX-1..16` (`DRC-3`, `5`, `6`, `8`, `10`, `15`, `16`, `18`); `DRC-26` and `DRC-33`'s option
  choice dropped in the B–E walk; plus `DRC-11`, `13`, `14` ruled in the first.
- **`DLUX-1..16` in general.** It was ratified 2026-08-09 and is more permissive than `DRC` in at
  least one place (`DLUX-13` permits prose templates at authoring time where `DRC-18` did not).
- **The two-primitive ruling**, which reopens none of the four mechanisms it unified.

---

## Gates and definition of done

- `python3 AGENT/Docs/check_docs.py` after every edit; `gen_docs_index.py` committed in the **same**
  change (check 18).
- **Clear the `Needs revision` marker and the divergence list** in the plan's header block, and flip
  `Status:` — but only once the `Decision source` register reads `RESOLVED`, which it now does.
- **Update the thirteen gated rows** (`DRC-V1-S00..S11`, `EPIC-DIALOGUE-CUSTODY-V1`) to remove the
  gate, via `scripts/agent-update-task.sh --append-reference`.
- Claim commits **as you go** (`python3 scripts/ci/check_session_commit_claims.py --fix`) — the
  `session-claims` hook refuses a commit when an earlier one is unclaimed, and the last commit of a
  session always needs a follow-up claim commit before `agent-push.sh` will pass.

---

## Also left open by the `RPD` walk of 2026-08-13

Not part of this session's scope, recorded here so it is not lost:

- **`B4-PREP-MAP-DEPLOYMENT-2026-07-22` now has a decision source it does not cite.** Its reference
  points at `prep_hub_open_questions_2026-06-23.md` and the July handoff, both of which predate
  `RPD-1..18`. Map Preview being a **canvas**, the select-then-select **no-confirm** swap, the
  **registry-projected** quick card and the **staged-transaction** deployment plan are all rulings
  that row must absorb before it is built. It is `planned` and scoped into v0.8.0, so this is not
  urgent — but it is the same "plan derives from a decision source that moved" shape this handoff
  exists to fix, caught early this time.
- **`NMTE-1..20` is the last unwalked packet** of the written set and still gates `CEUI`'s search
  rows.
