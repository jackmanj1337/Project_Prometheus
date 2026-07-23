---
Type: planning handoff
Status: Planned — autonomous execution bounded; owner gates separated
Last verified: 2026-07-23
Tracker: PLAN-ZERO-CONTENT-BLOCKER-HANDOFF-2026-07-23
Questions: zero_content_blockers_owner_questions_2026-07-23.md
---

# Zero-Content Prerequisites — Autonomous Execution Handoff

## Outcome

Clear as much of `B4-RESULT-ACTIONS-2026-07-22` and
`PP-INTEGRATION-RELEASE-RECONCILE` as evidence and branch policy permit, without
stopping for questions that can be answered from code, tests, history, returned
playtest artifacts, or existing decisions. Stop only at the explicit owner gates in
[`zero_content_blockers_owner_questions_2026-07-23.md`](zero_content_blockers_owner_questions_2026-07-23.md).

When both prerequisites are terminal and present on `agent/integration`, start
`IMPL-ZERO-CONTENT-FOUNDATION` from that exact integration head.

## Verified starting state

- Results actions are implemented on `agent/playtest-release-v0.5.4-fixes`:
  `229ed41` contains the behavioral implementation and `383f91f` its first closeout.
  `CampaignRules.battle_result_actions` independently controls victory/defeat
  actions; Save commits once and stays on Results; Retry, Continue and Quit remain
  separate. Headless coverage was 7/7 focused and the release branch is green.
- The follow-up input-ordering repair and v0.5.5 build are pushed through `755b99f`.
  The baked artifact is commit `6651481`, size `102184552`, SHA-256
  `f1041663c03afd5a0ee0349fd99171cb63cfb7a5ce6ee74c903a434ad1c6f200`.
- The only remaining Results-actions evidence is the live Windows/controller pass in
  `playtest_checklist_v0.5.5.md`; the container cannot supply it.
- Remote tips at audit time:
  `agent/integration` = `0aa74b8`, `agent/playtest-release` = `18283e2`,
  `agent/stable-release` = `c88ce98`, release-fix source = `755b99f`.
- `agent/integration...agent/playtest-release-v0.5.4-fixes` is 58 integration-only
  and 78 release-only commits, with merge base `258ed12`.
- `git merge-tree --write-tree` found 11 textual conflicts: `AGENT/Docs/INDEX.md`,
  Project Control Plane, GDD 07 Screens/Panels, GDD 10, master review procedure,
  session notes `2026-07-17.md` and `2026-07-19.md`, session-note index, `AGENTS.md`,
  and `scripts/hooks/pre-commit`/`pre-push`. It found no runtime gameplay conflict.

## Phase 0 — preserve and refresh evidence (autonomous now)

1. Fetch/prune all refs and record exact tips, merge bases, ahead/behind counts and
   remote existence. Do not delete or force-update any ref.
2. Check `AGENT/Incoming/v0.5.5/` before starting other work. If a return exists,
   verify artifact/checklist/log identity before interpreting behavior.
3. Re-run full checks on the exact release-fix head if its receipt is missing or no
   longer exact. Do not rebuild or replace the published v0.5.5 artifact.
4. Compare `B4-RESULT-ACTIONS` symbols and tests by content, not hashes, against every
   prospective target. If equivalent behavior already landed independently, record
   that and avoid a duplicate cherry-pick.
5. Refresh the merge-tree report against current remote tips. Classify each conflict
   as mechanical union, generated output, policy/hook authority, true behavioral
   conflict, or already-landed content.

## Phase 1 — intake v0.5.5 (autonomous when return appears)

1. Preserve returned checklist, original `godot.log`, and screenshots under the
   normal playtest evidence paths; never edit the originals.
2. Derive PASS/FAIL/NOT RUN from evidence. Blank boxes are unknown, not passes.
3. Validate build stamp, hash/size statements, runtime errors, controller identity,
   and the focused A1–A7 behaviors. B4 Results actions specifically requires A6;
   controller navigation/shared input repair requires A1–A5. Carried B/C gaps do not
   automatically invalidate A6 unless they reveal a release regression.
4. For a reproducible defect, write a root-cause review first, reproduce headlessly
   where possible, add a tracker child, fix on a new `agent/**` branch from the
   release-fix source, run full checks, and cut a new numbered verification artifact.
   Do not reinterpret a failure as acceptance.
5. For complete passing evidence, update `B4-RESULT-ACTIONS-2026-07-22` from
   `playtesting` to `completed`, attach exact artifact/evidence/source SHAs, and mark
   the enclosing v0.5.5 validation row accordingly. This evidence permits presenting
   the release-acceptance gate; it does not silently answer it.
6. For incomplete evidence, execute any missing headless/log checks locally. Route
   only genuinely live Windows/controller/visual gaps to the owner question packet.

## Phase 2 — promote an accepted release (owner gate, then autonomous)

After the owner explicitly accepts the evidenced release:

1. Merge the verified release-fix source into `agent/playtest-release`; the target is
   `agent/**`, so agents may merge after checks. Preserve exact artifact/source
   identity and do not squash behavioral history.
2. Run the full suite and documentation/process guards on the merge result. Resolve
   only evidence-backed conflicts; if a conflict changes behavior with two viable
   meanings, stop and add the exact hunk/choice to the questions document.
3. Merge the verified playtest release into `agent/stable-release`, run full checks,
   and record the accepted release evidence. Do not merge into `main` or
   `agent/staging-area` as part of this prerequisite.

## Phase 3 — reconcile stable release and integration (autonomous)

Create a dedicated branch from current `agent/integration`, for example
`agent/from-integration/reconcile-v055-release`, and merge the accepted
`agent/stable-release` into it.

Conflict policy:

- Generated `AGENT/Docs/INDEX.md`: resolve source documents first, then regenerate.
- Project Control Plane, GDD 07/GDD 10 and review procedure: preserve the union of
  non-duplicated decisions/status/evidence; newer accepted behavior wins only where
  prose describes the same shipped surface. Do not discard integration-only AI,
  registry, research, licensing or MRD work.
- Session notes and index: preserve both historical files/rows. Never choose one
  branch's history wholesale.
- `AGENTS.md`: use the current managed shared-policy block and preserve uncovered
  repo-specific rules; run the shared-block sync check.
- Hooks: take the newest policy-complete guards, then compare both sides function by
  function so docs/RNG/test/merge/push enforcement is a union. Verify executable bits
  and `core.hooksPath`.
- Runtime files that auto-merge still require content review for silent semantic
  regressions, especially `CampaignManager`, Tier-2 validators/adapters, SaveData,
  GameState, Results/Defeat UI, rewind, focus navigation and release metadata.

Then run:

1. all 107+ project suites (the exact count may grow);
2. `AGENT/Docs/check_docs.py`, RNG, analyzer, scene-integrity, session-claim and
   evidence-matrix guards;
3. focused Results actions, campaign/save, Tier-2, rewind, focus/controller-input,
   AI projection and MRD fixtures;
4. `git diff --check`, hook verification, and a content-level audit showing both
   sides' unique features survived.

If green, merge the reconciliation branch into `agent/integration`, push both refs,
and complete `PP-INTEGRATION-RELEASE-RECONCILE`. Correct its stale tracker target from
`main` to `agent/integration`; product does not bypass the release line or merge to
non-`agent/**` targets.

## Phase 4 — stale slash ref (separate destructive gate)

`agent/playtest-release/v0.5-fixes` at `21b28df` is obsolete, but remote deletion is
destructive and unnecessary to validate reconciliation. Confirm its commits are
reachable from retained refs, record the reachability proof, and wait for explicit
owner approval before deleting it. Failure or refusal to delete this naming artifact
does not block zero-content implementation once the release content is reconciled.

## Escalation rules

Do not ask about choices already settled in the Results-actions decision record or
campaign data-ownership findings. Ask only when:

- release acceptance has reached its human gate;
- live Windows/controller evidence is materially incomplete;
- a real behavioral merge conflict has two valid outcomes not resolved by newer
  accepted evidence; or
- destructive remote-ref deletion is proposed.

Every new defect or deferred question must receive a canonical tracker row or update;
nothing remains only in this handoff.

## Exit criteria

- `B4-RESULT-ACTIONS-2026-07-22` is completed with live evidence or has a focused
  repair child and new playtest gate.
- Accepted release content is on `agent/stable-release`.
- Stable release and integration are reconciled without dropping either side's
  independently landed work; full checks are green on `agent/integration`.
- `PP-INTEGRATION-RELEASE-RECONCILE` is completed with exact SHAs and evidence.
- Any unanswered owner gate is present in the questions document and tracker.
- `IMPL-ZERO-CONTENT-FOUNDATION` has no remaining prerequisite except any deliberately
  independent stale-ref cleanup.
