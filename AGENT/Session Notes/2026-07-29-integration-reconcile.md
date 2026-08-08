# Session Notes — 2026-07-29 (integration ← main reconcile)

## What was done

Executed `PP-INTEGRATION-RELEASE-RECONCILE` per
`AGENT/Docs/plans/integration_release_reconcile_plan_2026-07-29.md`. Merged
`origin/main` (`db4d2a8b`, carrying accepted v0.5.8 plus the infrastructure that
bypasses the release line) into `agent/integration` on this branch, then
refreshed the stale control-plane prose as a separate commit so the rewrite is
reviewable apart from the mechanical conflict resolution.

138 integration-only / 179 main-only commits, merge base `8c4016eb`, 9
conflicts, none in runtime gameplay code.

### Conflict resolutions

| File | Resolution |
|---|---|
| `scripts/hooks/pre-push` | main — comment only, guard body identical |
| `AGENT/Review Procedures/00_Master_Review_Procedure.md` | main — list reorder only |
| `AGENT/GDD/GDD_10_Roadmap.md` | integration — later `Last verified` |
| `AGENT/GDD/GDD_07_Screens_Panels.md` | main's header date + integration's content |
| `AGENT/Docs/plans/project_control_plane_2026-06-29.md` | integration, then rewritten in `534ff0a4` |
| `AGENT/Docs/INDEX.md` | regenerated, not hand-merged |
| `AGENT/Session Notes/INDEX.md` | union of both sides, 39 rows |
| `AGENT/Session Notes/2026-07-17.md` | both kept — see below |
| `AGENT/Session Notes/2026-07-19.md` | both kept — see below |

## Factual Git state

- Branch: `agent/from-integration/release-reconcile`
- Base: `agent/integration` at `4ca5cc0d`; merged `origin/main` at `db4d2a8b`
- HEAD: `534ff0a4b68bb8ce5e0c9c11259b070e8b9ef465`

## Commits

- `534ff0a4b68bb8ce5e0c9c11259b070e8b9ef465` — Refresh the control-plane work queue after v0.5.8 shipped

`b213dc35` is the merge commit and is exempt from claiming.

## Checks

- `bash run_tests.sh` — **PASS, all suites green** on the merge result.
- `check_docs.py` — green.
- `check_gdscript_style.sh` — 244 files, no problems (237 before the merge).
- `check_session_commit_claims.py` — PASS, 91 commits audited.

## Decisions and context

**The GDD_07 "date vs content" question was not a real conflict.** It looked
like integration claimed newer content under an older verification date. The doc
carries *two* levels of stamp: the document header, and a per-section
`Last verified:` line. The section-level stamp inside "Prep, Service, And
Authoring Panels" reads 2026-07-19 on **both** sides and was never in conflict —
it correctly dates integration's added seam claim. So the header took main's
later date and the body took integration's content, with nothing asserted that
was not verified.

**The control-plane ordering note retired itself in this merge.** It sequenced
`B3-PHB` ahead of `B3-CAMPAIGN-RULES` purely to avoid conflicts with the
then-unmerged v0.5.1 fix `8b77c9d`. That fix was already on `main` and lands here
with this merge, so the constraint is gone and the note now records its own
retirement. Order those two on readiness alone.

**Session-note collisions resolved without touching published paths.**
`2026-07-17.md` and `2026-07-19.md` were genuinely different sessions written the
same day on parallel branches. `main`'s versions stay at the original paths;
integration's became `2026-07-17-v050-publication.md` and
`2026-07-19-ai-scorer-decisions.md`. Renaming only the integration side keeps
`main`'s paths stable so the collision does not recur.

**A duplicate commit claim surfaced and was resolved toward zero divergence.**
`2026-07-26-main-into-integration.md` (integration-only) and
`2026-07-20-staging-infrastructure-intake.md` (written during the promotion, now
on `main`) both claimed the same three infrastructure commits, which fails
`check_session_commit_claims.py`. The intake note keeps its claims because `main`
has no other claimant; the 07-26 note released them. That direction was chosen
deliberately: the 07-26 note exists only on this line, so editing it leaves the
intake note byte-identical on both branches and creates no file that will
conflict at the next merge.

**Two GDD header stamps were bumped to 2026-07-29, and that bump is narrow.**
`check_docs.py`'s stale-verified rule fires when a GDD file is committed with an
older `Last verified` than its commit date, which the merge triggered for
`GDD_02_Core_Mechanics.md` and `GDD_07_Screens_Panels.md`. Both received real
content from the released line (GDD_02: the Fallen/Retreated battle-result
dispositions). The bump records **reconciliation with the shipped line**, not a
fresh line-by-line audit of either document. Read it that way.

## Next session

**Review upcoming work.** With v0.5.8 shipped, `main` and `agent/integration`
reconciled, and no playtest return outstanding, there is no forced next task —
which makes this the right moment to re-derive priority rather than inherit it.
Tracked as `REVIEW-UPCOMING-WORK-2026-07-29`.

Read first:

1. `coordination/ACTIVE_WORK.md` in the container repo — the generated view. Note
   the phase groupings; `1-planning-discussion` and `5-backlog` are where the
   unsequenced work sits.
2. The refreshed queue in
   `AGENT/Docs/plans/project_control_plane_2026-06-29.md` — now ordinary priority
   order, no longer a waiting-for-evidence boundary, and with the `B3-PHB` /
   `B3-CAMPAIGN-RULES` constraint retired.
3. `AGENT/Docs/playtests/playtest_v0.6.0_carryforward_2026-07-29.md` — the five
   items any v0.6.0 build must verify.

Specific questions worth answering in that review:

- Is v0.6.0 cut now, or does a feature set land first? Two carry-forward items
  need a returned **log bundle**, so a v0.6.0 build with no tester available
  gains nothing.
- The text-input feature set owns `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29`
  and depends on `RESEARCH-TEXT-ENTRY-STRATEGY-2026-07-26`, still `in_review`.
  Does the research pass run next?
- `B3-PHB` vs `B3-CAMPAIGN-RULES` now needs a readiness judgement, since the
  merge-conflict reason for their order is gone.
- Cheap and unblocking: `TOOL-SESSION-NOTE-CLAIM-FORMAT-2026-07-29` is a
  one-line fix that every session currently pays for by hand.

Also outstanding, independent of that review:

- This branch needs merging into `agent/integration` (agent→agent, no PR).
- `agent/from-staging-area/agents-policy-block-sync` (`139d331f`) is unmerged, so
  `main` still carries the stale `agent/coordination` policy text.
- Container `agent/from-main/reconcile-prep-tracker` (`c949e74`) needs merging to
  its staging area.
- Deleting the obsolete slash-ref `agent/playtest-release/v0.5-fixes` remains
  approval-gated.
