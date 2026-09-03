# Session Note - 2026-08-20 — PREP-V1-S01 blocker clearance

## Branch context

- Branches: `agent/from-integration/overworld-cadence-spec`,
  `agent/from-integration/b3-req-slice5-dispositions`, then `agent/integration`
- Base branch: `agent/integration`
- Base SHA: `0512c6ea` (integration tip at session start)
- Coordination Work IDs: `DESIGN-OVERWORLD-CADENCE-2026-07-25`,
  `B3-REQ-F16-BUILD-2026-08-18-2026-08-19`, `SHELL-FOCUSABLE-DISABLED-ENTRIES-2026-08-17`,
  `REVIEW-ACCEPTED-PORTFOLIO-CODE-STATE-2026-07-27`

## What was done

All four of `PREP-V1-S01`'s non-`completed` dependencies, in the order the control plane
recommended. The owner asked for the cadence branch to be **reviewed before any merge
decision**, and the review is what made the session worth running: three of the four
findings would have landed unnoticed.

### 1. `DESIGN-OVERWORLD-CADENCE` — reviewed, fixed, merged (`0da644f9`)

Seven commits sat unmerged. Reviewed rather than merged on the row's say-so, and found:

- **A regression against a ruling fixed the previous day.** `OverworldScreen` is the
  **fifth** `[EPUX-04]` availability surface and is a bare `Control` — it extends neither
  `ModalScreen` nor uses `FocusNavigator`, so it inherited the
  `SHELL-FOCUSABLE-DISABLED-ENTRIES` fix from **neither** of the two places that row
  repaired. Gated nodes were disabled `Button`s with no reason anywhere: no tooltip, no
  label, and a dead "unavailable" branch in `_on_node_pressed` that a disabled `Button` can
  never emit. Entry focus had no all-gated fallback. Fixed with the reason phrased by
  `CampaignManager` (`get_overworld_nodes().unavailable_reason`), not by the screen —
  `[EPUX-04]` deliberately keeps the disabled treatment with the availability authority.
- **`commit_pending_result`'s revisit early-return skipped `end_campaign_map_rules`**,
  which every other commit path runs, so a revisited node's `rule_overrides` and any
  `end_of_map` rule flips stayed live until the next node entry happened to clear them.
- **`restore_campaign_state` left `_revisiting_node_id` and `_deployment_counted_for`**
  while clearing `_active_node_id` under the comment *"Runtime-only: nothing is on a map
  yet"*. Both are runtime-only in exactly the same way; `restore_retry_branch` is the live
  route that noticed.
- **The surface does not match its own owner ruling.** Ruling (1) of 2026-08-19 says the
  graph uses *canvas pan/zoom*; what shipped is a `ScrollContainer` of `Button` rows with a
  raw-pixel zoom multiplier, and `next_node_ids` reaches the presentation model and is
  never drawn. Not fixed here — `OVERWORLD-GRAPH-CANVAS-2026-08-20`.

### 2. `B3-REQ-F16` — §3 dispositioned, row `completed`

The row was `in_review` on **decisions, not defects**. All seven taken in writing as §6 of
the audit (`fe5427fa`): two honoured in code (`ad4ba215`), four waived with a stated
re-open condition, one withdrawn.

The recursion waiver is the one that carries weight. `FormulaEvaluator` has two independent
bounds — validate-first *and* its own `depth > HARD_MAX_DEPTH` guard.
`RequirementSystem._evaluate_node` takes **no depth parameter at all** and is bounded
*only* by `validate()` running on every `evaluate()`. So the validate-first ordering is
load-bearing: a cached-validation fast path or a trusted-content bypass restores unbounded
recursion over author-supplied content. That is now written down where the next optimiser
will find it.

Finding `[6]` is **withdrawn outright**, not deferred. The audit left "a group check renders
a reason saying 'trait'" as a surviving text question; `_ready()` registers `has_trait` with
`req.has_trait` and `in_group` with `req.in_group`. They share an evaluator and have
distinct text keys. The claim did not survive a look at the code.

### 3. `SHELL-FOCUSABLE-DISABLED-ENTRIES` — verified, stays `in_review` on purpose

Both traversals confirmed on `agent/integration` by reading them, not by trusting the row.
The only residue is the native keyboard/controller pass this container cannot perform, so
no further container work closes it, and it is **not** blocking its consumers. The finding
that matters is in §1: fixing two shared traversals does not make the ruling inheritable —
a new surface that uses neither simply does not get it, and nothing fails when that happens.

### 4. `REVIEW-ACCEPTED-PORTFOLIO-CODE-STATE` — re-scoped, not run

Its handoff still reads *"before any product implementation begins"* and
`Status: WAITING FOR ACCEPTED STABLE v0.5 RELEASE`. Its merge-order steps 3–4 name five
branches that are all archived. And its post-review sequence places "Requirement +
shared record-screen foundations" **after** the gate, while `B3-REQ`/F16 shipped on
2026-08-19/20 with **no dependency edge to this row at all**. Prose ordering, absent from
the graph — the same invisibility failure one level up.

Re-scope proposal plus the first three architecture collisions:
`AGENT/Docs/plans/accepted_portfolio_review_rescope_2026-08-20.md`. Row stays `planned`.

## Commits

Ownership is in `AGENT/Session Notes/CLAIMS.tsv`.

`9cae4dfc` fixes the overworld availability regression and both revisit teardown gaps with
seven new assertions. `ad4ba215` honours the depth budget and deletes the three dead
wrapper classes. `fe5427fa` takes the §3 decisions. `0da644f9` and the dispositions merge
land both branches on `agent/integration`.

## Gates

- `test_overworld_screen` 6 → **10/10**, `test_campaign_manager` 50 → **53/53**,
  `test_requirement` **+3**. Every new assertion **negative-checked**: the fix reverted, the
  assertion fails. One first-draft assertion passed vacuously (an empty status matching an
  empty tooltip) and was tightened — that check is why it was caught.
- Full suite green at the exact staged tree on every push: **146** suites, then **147**.
- `check_docs.py` **46/46**. `check_gdscript_style` PASS.

## Next

`PREP-V1-S01` has one dependency left in `in_review` (the shell row, awaiting the batched
native-host session) and **two new ones surfaced by §6.8**:
`UNMET-REASON-TEXT-TABLE-2026-08-20` — no `req.*` key exists anywhere and `TextDB` is not an
autoload, so every unmet reason renders as its own key and a player would read
`req.has_item` — and `REQ-LEGACY-REGISTRY-RECONCILE-2026-08-20`. The text one is the real
gate: `PREP-V1-S01` builds gated prep entries whose reason must be player-facing.

Before building it, decide the re-scope in
`accepted_portfolio_review_rescope_2026-08-20.md` §2, since deliverable 3 (corrected
dependency edges) is where these newly-found edges belong.

**Tooling gotcha for the next session:** `agent-add-task.sh` **dedupes on `--run-id`**.
Registering a second row with the same run id silently returns the *first* row's id and
creates nothing — it prints `registered <first-row-id>` and exits 0. Generate a fresh run
id per row, and verify against `tasks.json` rather than trusting the printed id.
