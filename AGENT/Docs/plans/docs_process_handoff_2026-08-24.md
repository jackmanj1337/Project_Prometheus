---
Role: dated
Type: handoff
Status: Active
Last verified: 2026-08-24
Tracker: MINE-PLAYTEST-CORPUS-2026-08-23, TASK-ID-CITATION-GATE-2026-08-24
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
---

# Next-session handoff — docs and process, after both mining rows closed

**This document adds no open work.** Every item is a tracker row that already exists and
carries its own measurements. This is ordering and context only. If you want to record
something new, put it on the row — a handoff that becomes a second registry is the failure
`TRACKER-DIVERGENCE` cost four sessions to unwind.

It **succeeds but does not replace**
[`doc_consolidation_handoff_2026-08-23.md`](doc_consolidation_handoff_2026-08-23.md). That
document still holds the per-order detail and traps for orders 5 and 7 — the two that are
still open; its order 9 section is spent, and the mining outcome lives in
[`uncovered_doc_corpora_triage_2026-08-23.md`](uncovered_doc_corpora_triage_2026-08-23.md)
§§2.1–2.2 and §*Correction — 2026-08-24*. Use this document for what changed since.

**Updated twice on 2026-08-24.** The first revision re-ordered the queue around the task-id
citation gate; the second, below, records that orders 1 and 2 are done and that two owner
rulings landed.

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

## What changed 2026-08-24, later the same day

Items 1 and 2 of the order below are **done**, and the session that did them produced two
owner rulings and one correction to this document's own premise.

- **`MINE-PLAYTEST-CORPUS-2026-08-23` (order 9) is `completed`.** 64 files / 8,149 lines
  deleted against a scoped 80 / 8,996; `AGENT/Docs/playtests` went 150 → 86 markdown files.
  Mining found **zero salvage** — see the row and §*Correction — 2026-08-24* of
  [`uncovered_doc_corpora_triage_2026-08-23.md`](uncovered_doc_corpora_triage_2026-08-23.md).
- **`PLAYTEST-EVIDENCE-DISPOSITION-2026-08-24` opened and closed the same day**, ruled by the
  owner: *keep every packet directory; a packet's `README.md` must be either analysis or
  nothing.* Five listing-only READMEs deleted; every returned tester checklist survives. The
  rule is §2.2 of the triage.
- **`TRACKER-STALE-DOC-PATHS-2026-08-24` is open and re-scoped**, ruled by the owner: closed
  rows **keep** history's licence to name what history contained, and the general
  path-existence check is **rejected** on signal-to-noise. It is now one narrow check only.
- **`TASK-ID-CITATION-GATE-2026-08-24` is `completed`, and its `repository` was wrong.** It
  sat `in_review` only because nobody closed it out — the PR #32 shape. Verified before
  closing: `citation_liveness()` is live at `coordination/check_tasks.py:588`, runs in the
  default pass *and* the pre-commit hook, and merged to `agent/staging-area` at `c4b9977`.
  Its `repository` said `Project_Prometheus` while the gate code it shipped lives in the
  Container repo; corrected. Its one open call (12 doubled-date ids) was discharged the same
  day, leaving only `TRACKER-DUPLICATE-B3-BUILD-ROWS-2026-08-24`.
- **`track.py update` gained `--title` and `--repository`** (`8d77904`), which is what made
  that correction possible. Both fields were set at registration and then unreachable; the
  only prior remedy was hand-editing `tasks.json`. Sixth and seventh instances of *the CLI
  can state a debt it cannot pay* — the shape is now closed for every field a row carries.
  Four wrong fields across three rows were repaired with it.
- **`STAGING-PROMOTION-96-2026-08-24` is open at `in_review`, PR #34.** The container
  `agent/staging-area` → `main` promotion had **no row at all** — the last one closed
  2026-08-23 and ~98 commits accumulated behind it, including both tracker gates. It is
  `MERGEABLE` and `main` is 0 ahead, so it fast-forwards. **It needs a human merge, and
  nothing in this project notices when one happens** — close the row by hand, and start a
  session with `check_tasks.py --github`.

## Recommended order

| | Row | Why here |
|---:|---|---|
| **1** | `GDD-CAMPAIGN-EDITOR-CHAPTER-2026-08-23` (order 7) | Unchanged, and it is still what releases order 5. Now the largest open item on the track |
| **2** | `TRACKER-STALE-DOC-PATHS-2026-08-24` (order 10) | Re-scoped to one cheap check with 3 known real instances; the expensive 90% was ruled away |
| **—** | `STAGING-PROMOTION-96-2026-08-24` (order 1) | **Not a session.** PR #34 is open and mergeable; it needs your merge, then close the row by hand |
| **3** | `TRACKER-BLOCKED-INVARIANT-2026-08-24` | Small; good filler, not a session |
| **4** | `IS-HISTORICAL-UNDER-MATCHED-2026-08-23` | Small, unordered, and it touches the same `check_docs.py` surface as items 2–3 |
| — | `EXTENSIONLESS-DATED-CITATIONS-2026-08-23` (order 5) | **Blocked** on item 1. Do not start it |
| — | `TRACKER-DUPLICATE-B3-BUILD-ROWS-2026-08-24` | Four rows for two pieces of work. Needs a decision on which pair survives, not an edit |

### Why the mining row's outcome should change how you scope the next one

Order 9 delivered **64 of a scoped 80**, and *every* shortfall was reachability — the mining
discipline itself (§2.1 steps 1–4) changed **not one line of the tree**. Three corrections,
two of them new blind spots that will recur:

1. **Version-parameterised roots.** `playtest_checklist_v0.7.9.md` and
   `playtest_build_v0.7.9.md` are built at run time from `application/product_version` by
   `scripts/tests/test_release_metadata.gd:98` and
   `scripts/ci/check_release_source_branch.py:40`. **No grep for a filename finds a format
   string.** Grep the corpus *directory* out of every `.py`/`.gd`/`.sh`/`.json`/`.yaml`.
2. **Relative paths to an ambiguous basename.** §2's rule matches an ambiguous basename by
   full path only, but documents cite their neighbours *relatively*. Resolve every
   path-shaped token against the citing file's own directory before matching.
3. **Directory-referenced corpora.** An evidence packet is referenced by directory, so
   `evidence/**` is unreachable by any citation walk. That is now ruled (§2.2) rather than
   re-derived.

**The standing lesson, and it is the one to carry:** *if a mining row must cut a step, cut
the ID orphaning — never the post-deletion grep sweep.* The sweep is what caught corrections
2 and 3, with every gate green.

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
6. **The premise trap is now nine deep, and one of the two new instances was written and
   disproved in the same session.** Order 9's scope was wrong three times over. Then
   `TRACKER-STALE-DOC-PATHS-2026-08-24` — opened that afternoon — claimed "30 stale paths,
   all in completed rows"; repo-aware resolution found **794 doc-path citations, 123
   unresolved, 104 completed and 19 open**, most of it drift that predates the deletion
   entirely. **Measure a row's premise even when the row is an hour old and you wrote it.**
7. **A document that names a bad path in order to *discuss* it mints its own violation.**
   `TRACKER-STALE-DOC-PATHS` quoted a deleted path as an example and thereby became an
   instance of the defect it describes — the identical shape as `1e2f39e`, *"Stop the schema
   minting the citation it describes"*. Any gate over cited paths needs an exemption for
   discussion prose, the way check `[1]` already exempts a heading containing "deleted".
8. **The generic-basename trap fired three more times** (instances four, five and six), all in
   one session: `playtest_checklist_v0.5.4.md` matched a copy in a *different tree*
   (`AGENT/v0.5.4/`), `returned_checklist.md` matched the wrong packet's sibling, and
   `README.md` produced 25 of 27 hits in the post-deletion sweep. It is the single most
   reliable source of false positives in this corpus work.
9. **~~`agent-update-task.sh` has no `--title` verb~~ — CLOSED the same day** (`8d77904`).
   `--title` and `--repository` both exist now, validated and tested. Kept here for the
   lesson that outlives it: **the gap was at the CLI layer, not the function.** `apply_update`
   was always generic — it writes whatever field it is handed — so a test asserting on
   `apply_update` alone *passes against the broken code*. Only a round-trip through `main()`
   catches it. 4 of the 8 new tests fail against the old code; the 4 that pass are the ones
   testing the wrong layer.
10. **Pushing from a linked worktree needs the askpass helper by hand.** Plain `git push` in
    `repo/Project_Prometheus_corpora` dies with *"could not read Username"*. Source
    `scripts/lib/repo-common.sh`, call `make_git_askpass`, then `git_auth push …`. The
    pre-push hooks still run and still enforce.

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
- **`AGENT/Docs/playtests` is now 86 markdown files**, and its `evidence/**` subtree is 82
  files / 80.2 MB of which only **10** are markdown. Both mining corpora are done; what is
  left undecided in either is the **61 catalogue-only documents** (29 playtests, 29 Code
  Reviews, 3 design) reachable solely through the Control Plane, which was *kept*.
- **Deleting markdown frees no clone space and deleting binary frees none either** — history
  retains the bytes. Every disposition on this track is a legibility argument, not a size one;
  three separate rows have now been scoped on size and delivered on legibility.
- The evidence subtree's fidelity caveat matters when reading it: returned checklists had
  **trailing whitespace normalised** for the text gate, with wording preserved. That fact
  lives only in `playtests/evidence/v0.6.0/README.md`, which is why that README was kept.
