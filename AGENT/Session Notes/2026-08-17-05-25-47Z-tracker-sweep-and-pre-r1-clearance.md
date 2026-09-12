# Session Note - 2026-08-17-05-25-47Z

## Branch context

- Branch: `agent/integration` (plus `agent/from-integration/crossing-resolver-pcm7-coverage`)
- Base branch: `agent/integration`
- Base SHA: `eb8a3811399c2867a0dccfafb6e32bf730e9f074`
- Coordination Work ID: `R1-PLAN-CORPUS-COHESION-REVIEW-2026-08-16`

## What was done

A review of what was still open across the tracker, followed by acting on it. Tracker edits
landed on the container docs line (`agent/staging-area`); product and documentation changes
landed here on `agent/integration`.

**Eight rows closed on evidence.** `V070-WINDOWS-RETURN-TRIAGE` — but only after merging its
branch, because the entire v0.7.0 return evidence base (root-cause review with findings
V070-01..13, returned checklist, returned decision sheet, seven screenshots) existed **only**
there, and two open rows cited paths from it that did not resolve on `agent/integration`.
`IMPL-CROSSING-RESOLVER`, after adding the missing `[PCM-7]` coverage. `V071-RETURN-TRIAGE`,
`V070-RETURN-FIXES` and both `V076` rows, all discharged by the returned v0.7.6 checklist.
`IMPL-FILEDIALOG-ESCAPE-TEXTINPUT`, discharged by that checklist's §3 — which dropped one of
the four gates on the v0.8.0 screen conversions. `GENERAL-PLANNING-SCHEDULING`, superseded on
all three of its own findings.

**One stale blocker cleared.** `REVIEW-ACCEPTED-PORTFOLIO-CODE-STATE-2026-07-27` was `blocked`
on "an accepted numeric stable v0.5 tag/commit and completion of the stable-release →
`agent/integration` reconciliation". Both landed at v0.7.7 on 2026-08-12; verified by ancestry
that `cfc7749f`, `8f777ae6` and `82819f5a` are all ancestors of `agent/integration`. It
transitively gated 47 open rows.

**`[PCM-7]` needed no production change.** `CrossingResolver.gd:174-176` already sets
`movement_permanent` before the effect key is read, matching the ruling. What was missing was
coverage: the `TileTrigger` fixture always injects an effect Callable, so no test could build
the effect-less trigger the ruling is about. Added `EffectlessTrigger` with halt and continue
cases (suite 29 → 34). Mutation-checked — narrowing `_fire` to `if declaration.has("effect")`
fails only the two new assertions and passes the other 32, so the narrow reading would have
shipped green.

**Twenty-three documents were invisible in `INDEX.md`.** `gen_docs_index.py` sorts by
front-matter `Type:`; a value outside the DSR-1 taxonomy matches no section, falls through the
filename heuristic, and the document is silently absent while every check stays green, because
check `[18]` only compares the index to itself. Among the twenty-three: seven implementation
plans, five decision records, both UI architecture docs, and the six 2026-08-12 comparative
research docs — including **two of `R1`'s own named targets**. Normalized by directory,
regenerated, and added check `[45]`.

**`R1` turned out to be fully specified**, not unscoped as its row summary suggested —
`research_and_discussion_sequencing_2026-08-13.md:142-159` gives it five named instances, and
§7 names the responsive conversions as one of the three build lines it orders. Wired as a
dependency of the conversions and of `B4-PREP-MAP-DEPLOYMENT`, then its working set cleared by
executing the claim sweep.

**The `ResponsiveLayout.gd` claim was a sequencing bug, not a conflict.**
`EDITOR-BUILD-PREREQUISITES` had correctly diagnosed that context-scoping is cheap only at one
production consumer. Verified: `UnitDetailsScreen.gd:108,122` is the only one today, and the
held branch `agent/from-integration/v080-responsive-main-menu` already adds `MainMenu.gd:88`.
The window closes when the v0.8.0 release window opens. The work moved into Phase 0, ahead of
both the release window and the `dense` token column.

## Deviations and corrections

- I initially offered `IMPL-ZERO-CONTENT-BASE-PACK` as an easy close, quoting "THE EXIT
  CONDITION IS MET 2026-08-07". That sentence refers to the *original* Slice 4 exit; the row
  was re-scoped the same day by `S7` under a harder exit. Corrected before anything was acted
  on, and the row's own prose now carries the correction.
- `v0.8.0` scope was reconciled rather than assumed: the release-window row listed palette-swap
  as a dependency while its own recorded owner decision held it outside the window.
- Three merge conflicts (`CLAIMS.tsv`, `Session Notes/INDEX.md`, `Docs/INDEX.md`) were resolved
  by each file's own rule — sorted union, newest-first union, and regeneration — not by picking
  a side.

## Gotchas worth keeping

- **`track.py update` has no `--phase`, `--blockers` or `--depends-on`.** Every change to those
  fields is a hand-edit on the docs line. That gap is also why 19 rows had drifted to no phase.
- **An off-taxonomy `Type:` is silent.** Now caught by check `[45]`, which reads front matter
  only — `governance/documentation_system_design_2026-06-23.md` contains an example `Type:`
  line inside a fenced code block and would otherwise fail forever.
- **`scripts/agent-push.sh` requires a clean tree**, and the container repo has 5.8 MB of
  untracked `design-previews/` PNGs in its root. Pushed with plain `git push`; the pre-push
  hook still enforced.

## Next session

Owned by [`AGENT/Docs/plans/pre_r1_handoff_2026-08-17.md`](../Docs/plans/pre_r1_handoff_2026-08-17.md).
Short version: run `R1`, starting with the precedence diff; Phase 0 with the context-scoping
first; `S7` when there is appetite for a bundle. Registered in the Project Control Plane under
Immediate Next Actions.

## Commits

Ownership is recorded in `AGENT/Session Notes/CLAIMS.tsv`, NOT here.
