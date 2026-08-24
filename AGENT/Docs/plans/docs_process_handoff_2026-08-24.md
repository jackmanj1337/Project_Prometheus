---
Role: dated
Type: handoff
Status: Active
Last verified: 2026-08-24
Tracker: TASK-ID-CITATION-GATE-2026-08-24
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
---

# Next-session handoff — docs and process, with the queue re-ordered by one new measurement

**This document adds no open work.** Every item is a tracker row that already exists and
carries its own measurements. This is ordering and context only. If you want to record
something new, put it on the row — a handoff that becomes a second registry is the failure
`TRACKER-DIVERGENCE` cost four sessions to unwind.

It **succeeds but does not replace**
[`doc_consolidation_handoff_2026-08-23.md`](doc_consolidation_handoff_2026-08-23.md). That
document still holds the per-order detail and traps for orders 5, 7 and 9; read it for those
and use this one for what changed since.

## What changed since 2026-08-23

- **`UITH` is closed.** `[UITH-7]` and `[UITH-8]`, the two owner calls that document was
  waiting on, were ruled 2026-08-24. Its "Two owner calls waiting" section is updated in
  place. `SESSION-UI-THEMING-ALIGNMENT-2026-08-10` is `completed`; theming is no longer
  gated on a decision, only on sequencing.
- **Order 5 was rendering as ready to pick up.** `EXTENSIONLESS-DATED-CITATIONS-2026-08-23`
  has said "stays blocked" in its prose since it was opened while its `blockers` field was
  empty, so every generated view showed it unblocked. The field now names
  `GDD-CAMPAIGN-EDITOR-CHAPTER-2026-08-23`. Nothing was newly decided — the reference
  already named that row as the cheapest route to the two missing stable IDs.
- **Two tracker-CLI gaps closed:** `--clear-dependencies` (2026-08-23) and
  `--rename-task-id` plus the doubled-date fix in `unique_task_id` (2026-08-24). Both are
  the same shape the tooling keeps producing — *the CLI can state a debt it cannot pay* —
  and that shape is now six deep.

## Recommended order

| | Row | Why here |
|---:|---|---|
| **1** | `TASK-ID-CITATION-GATE-2026-08-24` | New, measured, and it **changes a decision the last two sessions made** |
| **2** | `MINE-PLAYTEST-CORPUS-2026-08-23` (order 9) | Unchanged: largest remaining win, fully unblocked, method now exists |
| **3** | `GDD-CAMPAIGN-EDITOR-CHAPTER-2026-08-23` (order 7) | Unchanged, and it is what releases order 5 |
| **4** | `TRACKER-BLOCKED-INVARIANT-2026-08-24` | Small; good filler, not a session |
| — | `EXTENSIONLESS-DATED-CITATIONS-2026-08-23` (order 5) | **Now correctly shown as blocked.** Do not start it |

### Why the new row goes first

It is the only item that makes an existing decision look wrong, and it is cheap to confirm.

`task_id`s live in `coordination/tasks.json` in the **Container** repo and are cited in
Markdown in the **Prometheus** repo. `check_docs.py` cannot read the tracker and
`check_tasks.py` cannot read the Markdown, so a citation to a row that does not exist is
invisible to both — the same structural blindness check `[30]` exists as a floor for.

Measured 2026-08-24 over `git ls-files '*.md'` at `70f5765b`: **257 distinct task-id-shaped
tokens cited, 246 resolve across 155 files, 11 dangle.** The 11 are not one population:

- **Six are in a single file**, `plans/v0.6.0_return_fix_goal_handoff_2026-08-02.md`. One
  handoff naming six rows that were never registered is a *different* defect from a stale
  citation. Check whether that work exists under other ids before repairing anything.
- **Two are the doubled-date defect**, and this is the part that matters:
  `RESEARCH-SEQUENCING-2026-08-13` and `S3-NMTE-PRECEDENCE-DIFF-2026-08-14` are cited in the
  **clean** form while the tracker holds the doubled one. On 2026-08-24 the 12 remaining
  doubled ids were left alone on the argument that a sweep could not be verified. That
  argument is now weaker: for at least two of them, **renaming repairs a citation instead of
  stranding one**, because the corpus already cites the id the author meant. Re-measure per
  id before deciding — `--rename-task-id` exists now and refuses the unsafe cases.
- **Three are one-offs.**

## Traps, in the order they will bite

1. **A keyword sweep is not evidence.** Triage §2.1. The blocked-invariant row deliberately
   proposes a check for the *field* invariant (2 hard instances) and explicitly declines to
   gate on the 14 rows that merely say "blocked" in prose — most will be past-tense
   narration. Read those; do not act on the count.
2. **Re-measure anything you carry into a living document.** Absorbing `UITH` found five
   stale figures in a thirteen-day-old register, one of which **inverted a conclusion**.
3. **A recommendation goes stale the same way a premise does.** Both `UITH` recommendations
   were void on arrival 2026-08-24 — the row one of them said to fold work into had
   completed, and the branch the other said to merge later had already merged. The standing
   "row is wrong about its own premise" trap is seven instances deep and this was the first
   time it fired on a *recommendation*, so re-measure those too.
4. **A claim must land in a later commit than the one it claims.** Amending a commit after
   running `check_session_commit_claims.py --fix` orphans the claim against a sha that no
   longer exists, and the amended commit is then unclaimed.
5. **`agent-add-task.sh` refuses a second `docs`-area row on `(not yet created)`.** Area plus
   branch is the conflict key, so planned rows need a distinct intended branch name rather
   than the placeholder.

## Reproducible facts worth not re-deriving

- Citation measurement: match `[A-Z][A-Z0-9]*(-[A-Z0-9]+){2,}` with a dated suffix against
  `task_id`s in `tasks.json`. Both checkouts are present under `repo/` in the container
  workspace, which is the only place the boundary can be crossed today.
- The tracker CLI's clear-verbs are `--clear-paths`, `--clear-blockers`,
  `--clear-decision-required`, `--clear-trigger`, `--clear-order`, `--clear-dependencies`.
  `--depends-on` and `--blockers` **replace**; repeat the flag per value.
- A `planned` row cannot hold a claimed path. Register with the intended path, then
  `--clear-paths` and record the paths in the reference.
- The docs line for Prometheus is `agent/integration`; for the Container repo it is
  `agent/staging-area`. Tracker scripts push straight to origin and leave the local checkout
  stale — fast-forward after every one.
