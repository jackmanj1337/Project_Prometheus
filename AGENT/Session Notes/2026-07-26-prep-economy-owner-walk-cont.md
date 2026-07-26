# Session Note - 2026-07-26 (prep/economy owner walk, continued)

Continues [2026-07-25-prep-economy-owner-walk.md](2026-07-25-prep-economy-owner-walk.md).
Register: `AGENT/Docs/design/prep_economy_bundle_comparative_research_and_questions_2026-07-25.md`.

## What was done

**Session setup.** Restored both working branches for the continued walk:

- `Project_Prometheus` → `agent/from-integration/campaign-data-research` (was already
  checked out; clean and synced at `6dc7ca0` before this session's commit).
- Container repo → switched from `main` to
  `agent/from-staging-area/campaign-research-findings-tracker`, which holds the walk's
  tracker rows. Confirmed that branch is content-strictly-ahead of `main` (main's only
  extra commit, the PR #18 merge `34732d9`, is content-identical to its second parent
  `bf69c4e`, which the branch already contains) — so no merge was needed in either
  direction.

**Contamination reverted.** Four tracked files in `Project_Prometheus` carried uncommitted
edits rewriting `godot-prometheus-env` → `pydev-env` and `GODOT_ENV_ROOT` → `PYDEV_ENV_ROOT`
— leakage from the pydev-env fork's rename sweep (see the pydev-env workspace branch on the
container repo). Wrong for this repo; restored. Affected: `AGENTS.md`,
`AGENT/Code Reviews/process_history_tooling_review_2026-07-17.md`,
`AGENT/Docs/archive/handoffs/handoff_container_tooling_goal_2026-07-17.md`,
`AGENT/Docs/playtests/playtest_checklist_v0.5.2_returned_2026-07-21.md`.

**EPUX-02 ratified — availability presentation.** Option **B**, extended in two ways the
original single-flat-list framing did not anticipate:

1. **Two-state rule.** *Absent* (the campaign never authored the entry) → **hidden**.
   *Gated* (authored, predicate currently false) → **shown disabled with a reason**.
   This generalizes what the ratified prep-hub section already said for the absent half
   ("non-battle nodes hide the battle-only entries"; "only panels the campaign actually
   uses appear") and supplies the gated half.
2. **Uniform across all four availability surfaces** the ratified structure created: the
   top-level node menu, the Explore subject picker, the Explore per-subject activity list,
   and the Manage Roster panel registry. No surface-specific exceptions.
3. **Gate presentation is a per-entry authoring property** — `visible-disabled-with-reason`
   (default) or `hidden-until-met`. Same predicate; only the presentation of an *unmet*
   predicate differs. Rationale: plain B cannot express "authored, gated, and **secret**",
   which is a real authorial intent — a story-locked shop whose disabled label would spoil
   a deliberate reveal. The default preserves B's discoverability.

**Implication recorded for implementation:** the open predicate registry must expose a
player-facing **unmet-reason string**, not just a boolean. A predicate that cannot explain
itself can only be authored `hidden-until-met`. Also noted that `hidden-until-met` must not
become the lazy default in authoring templates.

**Flagged derived-not-ruled:** whether disabled entries stay keyboard/controller-focusable
so the reason is screen-reader reachable rather than hover-only. Recommended
focusable-but-not-activatable; deferred to EPUX-04/06/07 and the accessibility pass.

**EPUX-03 ratified — wide/narrow composition.** Option **C**, confirming accepted
`UI-ARCH-02`: one presentation controller/state model, wide list/detail and narrow
sequential compositions selected by **measured content width** (never a platform or device
name), selection and focus preserved across the transition. 200% Menu Scale can force narrow
at a nominally wide viewport, so narrow is not a "mobile-only" path.

Added a **pane-budget contract**, which the original single-list framing had no reason to
consider: the ratified structure creates a chain up to five levels deep (node menu → Explore
→ subject picker → activity list → activity panel).

- **Default: at most two panes, pairing adjacent levels** — subject | activity-list, then
  activity-list | panel. Never three: a third pane collapses at 200% Menu Scale and steals
  width from the terminal panel, which needs it most.
- **Full-width escape hatch** (owner addition): a panel may declare it wants the whole
  available width, and the shell presents it alone, dropping the companion pane; the parent
  level stays reachable by back/breadcrumb. For content-dense panels — shop grids, forge
  before/after, Map Preview, the global item-first bulk view.
- Declared by the **panel type in the registry** (a property of its content shape), not a
  per-campaign authoring knob — campaign authors do not make layout decisions.
- A **preference, not an override**: meaningful only when there is room for two panes at
  all; moot in the narrow composition. Taking or releasing full width preserves selection
  and focus like any wide↔narrow transition.

**EPUX-04 ratified — shared screen shell.** Option **C**, confirming accepted `UI-ARCH-01`:
shared presentation primitives keyed by an opaque stable record id, domain managers keeping
ownership of records and mutations, queries/actions as callbacks and action descriptors. No
campaign schema in the shared layer, no hardcoded activity enum. (Option B is the closed
type-switch this repo treats as a smell.)

**Availability gating promoted to a shell primitive.** The EPUX-02 ruling requires one
gating rule across all four surfaces; that is only enforceable if the shell implements it.
So the shell owns predicate evaluation, the hidden-vs-disabled decision, the disabled visual
treatment, and unmet-reason placement — adapters supply only the predicate, its player-facing
reason string, and the per-entry gate presentation. Four adapters therefore cannot drift into
four disabled treatments, and EPUX-02 is testable in one place. This also makes the deferred
focusability question a shell-level decision.

**EPUX-06 ratified — confirmation policy.** Option **C**: consequence-heavy operations
confirm, ordinary repeatable purchases commit directly after an explicit action.

- **Confirmation is authored, never hardcoded.** The author declares it on the action.
  There is deliberately no engine-side enum of "consequence-heavy operation types" — that
  is the closed type-switch this repo rejects, and it would mean an engine edit before any
  new operation could be safe.
- **Plus declarative threshold rules** (owner addition): authors may write scopeable rules
  evaluated against the transaction — *"purchases over X of resource Y in this shop
  require confirmation"* — at shop, node, or campaign scope.
- Both forms are **predicates**, so this reuses the registry already serving EPUX-02 gating
  and EPUX-07 reasons. One mechanism now answers three questions: *may I see it, why not,
  must I confirm it.* New confirmation rules are authored, not coded.
- **Strictness is a raise-only floor:** a player accessibility/safety setting may raise it
  globally, authors may mark specific operations always-confirm, and neither may lower a
  declared default.

**Exit review with rollback (owner-added).** Reopened the batched-confirmation option and
landed somewhere better than any of the three models offered: transactions **still commit
immediately** — the retained *immediate transaction persistence* decision is untouched, and
no staging layer, stock reservation, or quote/commit divergence is introduced.

- **Author-chosen per activity type**: the registry declares which activities carry an exit
  gate, so a large shop can have one and a quick training hall need not.
- Entering a gated activity takes a **snapshot** — a rewind point on the existing
  persistence/ledger machinery, not a new mechanism.
- Leaving shows a **review receipt** (what was done, net resource change); the player
  acknowledges it or **rolls back to the entry snapshot**, discarding everything done inside.
- This yields true back-out *without* a staged cart, so dependent operations still work —
  buy a weapon and then forge it — because everything genuinely committed.
**Exit-rollback sub-questions resolved (same session).** All three were raised as deferrals
and then answered by the owner; notably all three land on machinery the unified persistence
design already has (`AGENT/Docs/plans/persistence_undo_unified_handoff_2026-07-15.md`), so
nothing parallel is being invented.

- **RNG: rollback restores the stream.** Replaying identical actions yields identical
  outcomes, so rollback is never a reroll lever. Not a new guarantee — the handoff's
  "Determinism — the real anti-scum" section already states each ledger snapshot carries the
  RNG timeline and rewinding restores RNG-at-that-point. Receipt rollback inherits it.
- **…but authors are warned off RNG-bearing activities.** Determinism only covers *identical*
  replays — the handoff's own wording is "only DIFFERENT choices change results" — and inside
  an arena or a random forge a different choice is trivial, so the guarantee does not protect
  these the way it protects a battle. Ruling: a **non-blocking campaign-builder warning**
  when an exit gate is enabled on an RNG-bearing activity type, modelled on the existing
  durable-`mid_map`-vs-finite-rewind warning. Per **DoD#2** the automated check lands with
  the feature, modelled on `check_docs.py`.
- **Receipt rollback is uncharged; rewind charges are battle-only.** Confirmed against the
  code: `rewind_charges_per_map` is already per-map and `undo_activations`/`undo_rounds` are
  within-map ledger budgets. Charges exist as a convenience for casual players who would
  save-scum anyway and are disableable for a harder run — already expressible today as the
  `rewind_charges_per_map = 0` ironman preset. So both halves of this ruling are already
  true in the shipped `CampaignRules`; nothing to add.
- **Intended scope: bulk purchase and sale** — not grants, transforms, or RNG activities.
  This is the intent behind both the author warning and the gate being author-chosen.
- **Retention: exactly one snapshot, discarded on acceptance.** Consequences recorded:
  bounds web/console cost; implies the **invariant that at most one exit-gated activity is
  open at a time** (the ratified Explore structure already satisfies this — if nesting is
  ever introduced the inner gate must be *refused*, never silently replace the live snapshot
  and destroy the outer rollback); the snapshot is a transient auto doc with its own
  `rule_id` and pool, so the never-overwrite-a-manual-save invariant holds.
- **Gap found, then approved:** the shipped autosave triggers are `battle_start` /
  `battle_end` / `shop_exit` — all **exit**-time. Rollback needs an **entry** snapshot. The
  owner approved this as an ordinary autosave on a new **activity-entry trigger**, not a
  bespoke mechanism; it is the one piece of new plumbing the feature adds.
- **Crash/quit needs no special case.** A live snapshot surviving an unclean exit is handled
  by the existing **relaunch-and-resume** path — the player resumes where they were with the
  snapshot live and rollback still offered. No rollback-on-reload flow and no
  snapshot-dropping rule. This closed the last open item on the exit-rollback design.

**EPUX-07 ratified — result and failure feedback.** Option **C**: prevention first — an
unavailable action is disabled with an inline reason, and a structured error modal appears
**only** for an unexpected commit failure. Already consistent with the EPUX-11 ruling, where
a full destination fails before commit with no partial mutation.

**One reason contract, not two.** The eight minimum reasons (insufficient resource, missing
material, destination full, cap reached, gate unmet, unsellable, invalidated quote, save
failure) are members of the **same** shell-level contract as the EPUX-02 predicate
unmet-reason — "gate unmet" *is* that reason. A parallel transaction-only vocabulary would
mean two mechanisms, two visual treatments, and two test surfaces answering one player
question, which is what promoting gating into the shell was meant to prevent.

**Focusability settled.** Disabled entries **remain in the focus order** so their reason is
reachable by keyboard, controller, and screen reader; confirming does nothing or re-announces
the reason. A reason reachable only by pointer hover is the "inaccessible and opaque" failure
option A is rejected for. Shell-level, so implemented and tested once across all four
availability surfaces. This closes the question deferred from both EPUX-02 and EPUX-04.

**Correction to the register's own status section.** EPUX-28 was briefly mis-read as ruled.
It is **not** — it has a recommendation (C) only. The false positive came from regex-splitting
the doc on `### [EPUX-nn]`: EPUX-28 is the last question, so its body runs into the following
`## Node traversal and cadence model (owner-ratified 2026-07-25)` heading. The "Decision
status" section is the authority; trust it over a grep.

---

## Walk resumed — the remaining 16 questions, all ratified

The session reopened after the close above and ran the whole remainder. **All 28 EPUX
questions are now ratified; the packet has no open owner decision.** Per-question detail is in
the register's `OWNER RULING` blocks; what follows is what a reader needs that the individual
answers do not say.

### The answers that were not the recommendation

Four of the sixteen departed from the research recommendation, and those are the ones worth
re-reading:

- **EPUX-09 — A, not C.** v1 ships command verbs only; drag/drop is post-v1. C is not
  rejected, it is *staged*: the verb path is built as the authoritative mutation command, so
  a later drag layer is an additive input adapter, never a second mutation path.
- **EPUX-15 — C with the search half cut.** Derived filters yes, free-text search no, because
  text entry degrades on controller and a surface that behaves differently per input method
  is worse than one that offers less.
- **EPUX-25 — none of A/B/C as written.** The forge is **subject-scoped like the shop**: the
  subject determines reach *and* pricing. This was the cleanest ruling of the session — it
  replaced a forge-specific scope policy with a rule already ratified for shops, and the
  convoy-disabled cascade then falls out with no extra clause.
- **EPUX-26 — sections + presenters, not B.** B's item → mode → operation chain is three
  navigation levels, and the EPUX-03 pane budget caps panes at two adjacent levels. Reusing
  the EPUX-20 pattern removed the conflict and an engine-side Upgrade/Modify split at once.

### Two rulings generalized well past their question

- **EPUX-21** was asked as "stepper or hold-to-repeat" for Training Hall benefits. The ruling
  made the stepper a **shared quantity primitive** — starts at 1, steps backward to a *live*
  effective maximum (min of affordable, destination space, benefit cap), used by the **item
  shop and the unit-benefit shop alike**. Consequence the shop block never reached on its own:
  **the shop now has quantity purchasing.** The live-maximum rule also means the control can
  never offer a quantity that fails at commit, which is quote-equals-commit enforced in the
  affordance rather than checked after it.
- **EPUX-22** was asked as "where does the arena live". The ruling made **map placement a
  general property of any Explore activity**, carrying the shared-definition/shared-state
  pattern and the reason-keyed inactive presentation (gated → hidden, proximity →
  browse-only, preview → scouting) off shops and onto every activity. Option C ("always launch
  from map nodes") stopped being a separate answer — it is now an authoring choice.

### The EPUX-28 conflict, resolved

Flagged at the top of the session: EPUX-06 had ratified an optional exit review receipt with
rollback to an activity-entry snapshot, while EPUX-28's recommendation said forge operations
are permanent by default. On a receipt-bearing forge both were true.

Resolution: **the receipt *is* the undo window** — permanent means permanent **after the
receipt is accepted**. One rule instead of two competing ones, no forge-specific exception in
a mechanism deliberately made uniform, and forging is deterministic so EPUX-06's RNG warning
does not apply to it. An author wanting no take-backs just does not enable the receipt.

### Deferred as a set, not one at a time

Three v1 cuts have the same root cause — text entry and pointers are not available on every
input method: **drag/drop** (EPUX-09), **free-text search** (EPUX-15), and **forge alias**
(EPUX-27). Rather than pay that analysis three times, the underlying capability is spun out as
`RESEARCH-TEXT-ENTRY-STRATEGY-2026-07-26`: a touch/controller-friendly on-screen keyboard
(acceptable even with a limited character set) plus a setting choosing between the in-game
keyboard, the OS keyboard, or an assumed hardware keyboard. Resolving it unblocks all three
together and any future text input.

### Also spun out

`ENGINE-ITEM-HELD-PREDICATE-2026-07-26` — gating activities and **Start Battle** on whether an
item is held, scoped to *any deployed unit*, *a named unit*, or *the convoy*. Registered as a
predicate in the shared condition registry rather than as an inventory feature, so one
registration serves four consumers: availability gates (EPUX-02), confirmation thresholds
(EPUX-06), cadence triggers, and battle-start gating.

### Convention consolidation

Two presentation conventions each picked up a second consumer this session, which is the
reason to prefer them over per-service designs: **list summary / detail-panel full breakdown**
(EPUX-17 prices → EPUX-19 benefit forecasts) and **labelled sections + registered presenters**
(EPUX-20 benefit types → EPUX-26 forge operations).

## Commits claimed

- `8988c31073a9714273b11e6f215d401659f6720a` — Ratify EPUX-02: absent hides, gated disables, per-entry secret gates
- `c5aac36727992a0a6552b33a3bd79997a7ca181e` — Ratify EPUX-03/04: pane-budget contract + gating as a shell primitive
- `eeb34a3c3075497051710f0002112ada4192c813` — Ratify EPUX-06/07: authored confirmation rules, exit rollback, one reason contract
- `fd6786bec3ebeb9ed78ae202919b372e6c7cecbd` — Resolve the three exit-rollback sub-questions; one snapshot, discarded on accept
- `9c43ebb4d5dd609946cc0a44815c8598262784da` — Approve activity-entry autosave trigger; crash resolved by relaunch-and-resume
- `4b6710610e57a30d64e0c76011f5e741da1e7a06` — Rule EPUX-09/10/12/13/15/17/19/20/21/22: inventory, shop, and activities blocks
- `c1c3912e20794decc0ac9451d20d6655bdb3c774` — Rule EPUX-23..28; claim 4b67106; the 28-question walk is complete

## Gates

- `scripts/agent-commit.sh` pre-commit (docs-only path): analyzer tool tests 12 passed;
  scene-integrity 22 scene-attached scripts PASS; session-claims PASS (136 commits audited);
  evidence-matrices PASS; gdformat/gdlint 238 files unchanged, no problems. Godot suite
  skipped as docs-only.
- `scripts/agent-push.sh --repo Project_Prometheus` full suite: **all suites green**.
  Receipt: `audit/check-receipts/Project_Prometheus-full.json` (tree `4ca9391b60de`, exit 0).
- First push attempt was correctly rejected by the session-claims gate (`8988c31` claimed
  0 times); this note is the claim.
- `AGENT/Docs/gen_docs_index.py` re-run — no index changes (doc header unchanged).

Walk-continuation gates (second half of the session):

- `scripts/agent-commit.sh --repo Project_Prometheus` × 3, docs-only path: analyzer tool
  tests 12 passed; scene-integrity 22 scene-attached scripts PASS; session-claims PASS
  (147 commits audited on the second); evidence-matrices PASS; gdformat/gdlint 238 files
  unchanged. Godot suite skipped as docs-only.
- The `4b67106` commit was correctly rejected by the session-claims gate on the next
  attempt until this note claimed it — the gate working as intended, same as earlier in
  the session.
- Container repo: `check_tasks.py` **OK, 161 tasks valid, no conflicts**;
  `gen_active_work.py` re-run; container fast suite 63 passed / 1 skipped.
- **Tracker view gap found, not fixed** (owner call, recorded in `AGENT/WAITING_WORK.md`):
  `gen_active_work.py` renders only phases listed in `settings.phases` and silently drops
  the rest — **41 tasks**, including all 32 `1-planning-discussion` rows, so every row spun
  out of this walk is invisible in `ACTIVE_WORK.md`. `check_tasks.py` misses it because it
  validates schema, not view coverage. `tasks.json` remains the complete picture.

## Next

**The prep/economy walk is finished — all 28 EPUX questions are ratified and the packet has
no open owner decision.** The mid-session "open after this session: 16 questions" plan was
superseded when the walk resumed and ran the remainder; the register's "Decision status"
section is the authority.

### Owner-selected order for the next two sessions (2026-07-26)

Implementation planning for this bundle is **not** next. The owner picked two smaller
items first; both are interruptible, and a **v0.5.7 return preempts either**.

1. **Fix the tracker view-coverage gap** — `COORD-ACTIVE-WORK-PHASE-COVERAGE-2026-07-26`
   (Container repo, `0-unblock`, infrastructure so it goes straight to
   `agent/staging-area`). First because every later handoff is only as trustworthy as
   `ACTIVE_WORK.md`, and right now that file omits 41 of 162 rows. Note the DoD#2
   requirement: the `check_tasks.py` assertion lands in the *same* change as the fix.
2. **Research + questions pass on text-entry strategies** —
   `RESEARCH-TEXT-ENTRY-STRATEGY-2026-07-26`. Produces a research doc plus a stable-id
   owner-question packet under `AGENT/Docs/design/`, walked the same way this bundle was.
   Check Godot's built-in virtual keyboard first — if the platform affordance is adequate
   on Windows/Steam Deck/controller, the question set collapses to selection policy.

### Then: implementation planning for this bundle

Inputs, in order:

1. The **cross-bundle implementation order** already in the register (shared activity shell →
   wallet/quote vocabulary → inventory + convoy + transfers → shop panel → Training Hall
   adapters → other activity panels → forge).
2. Three **shared primitives** this session created or confirmed, which should be planned
   before the services that consume them, because two services each now depend on them:
   the **transaction core** (EPUX-24), the **quantity primitive** (EPUX-21), and the
   **activity map-placement / shared-state model** (EPUX-22).
3. The **v1 cut line**: no drag/drop, no free-text search, no forge alias, no reset recipes.
   Forge ships all three operations in A → C → B order.

**Tracked rows carrying design that is decision-complete but unimplemented:**

- `DESIGN-ACTIVITY-EXIT-ROLLBACK-2026-07-26` — from earlier this session; complete shape, no
  owner decisions: an activity-**entry** autosave trigger (the one new piece of plumbing,
  since the shipped triggers are all exit-time), the single-snapshot retention rule and its
  at-most-one-gated-activity invariant, crash handled by the existing relaunch-and-resume
  path, and the non-blocking author warning against RNG-bearing exit gates plus its DoD#2
  check. **EPUX-28 now depends on this row** — the receipt it describes is the forge's undo
  window, so forging cannot be planned as reversible until it exists.
- `ENGINE-ITEM-HELD-PREDICATE-2026-07-26` — scoped item-holding predicate; four consumers,
  one registration.
- `RESEARCH-TEXT-ENTRY-STRATEGY-2026-07-26` — research, not implementation. Gates the whole
  deferred pointer-and-keyboard tranche; nothing in v1 waits on it.

**Do not re-open ratified questions on a grep.** The same trap noted earlier in this session
still applies: `### [EPUX-nn]` regex splits mis-attribute the last question's body. Read the
"Decision status" section.
