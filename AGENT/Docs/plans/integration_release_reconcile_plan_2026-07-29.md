# Integration ← Release Reconcile Plan

**Task:** `PP-INTEGRATION-RELEASE-RECONCILE`
**Prepared:** 2026-07-29, after v0.5.8 landed on `main`
**Branch:** `agent/from-integration/release-reconcile` (from `agent/integration` `4ca5cc0d`)
**Direction:** merge `origin/main` **into** `agent/integration`. Never target `main`.

## Why now

The gate is fully released. v0.5.8 was accepted 2026-07-29,
`B4-RESULT-ACTIONS-2026-07-22` closed on the v0.5.6 evidence, and the promotion
merged to `main` as `db4d2a8b` (PR #16). `agent/staging-area` fast-forwarded back
onto `main`, so `main` is the single settled tip carrying both the release and
the infrastructure that went direct to staging.

Merging **`main`** rather than `agent/stable-release` is deliberate: `main`
additionally carries the infrastructure commits that legitimately bypass the
release line, so one merge reconciles both streams.

## Measured scope

| | |
|---|---|
| `agent/integration` | `4ca5cc0d` |
| `origin/main` | `db4d2a8b` |
| merge base | `8c4016eb` |
| integration-only commits | 138 |
| main-only commits | 179 |
| conflicts | **9** |

**No runtime gameplay file conflicts.** Eight are under `AGENT/`, one is a hook
comment. This is a text-reconciliation job, not a code one.

Earlier audits recorded 11 conflicts; `AGENTS.md` and `scripts/hooks/pre-commit`
dropped out because the v0.5.8 promotion settled them on `main`.

## Conflict-by-conflict resolution

Everything below was inspected on a throwaway trial merge that was aborted; the
branch is clean.

| File | Type | Hunks | Resolution |
|---|---|---|---|
| `scripts/hooks/pre-push` | content | 1 | **Take `main`.** Comment-only — the guard body is identical. Integration's comment claims the `scripts/ci/` checks do not exist on `main`, which the promotion made false. |
| `AGENT/Review Procedures/00_Master_Review_Procedure.md` | content | 1 | **Take either.** Pure reordering of one list; `test_fixtures/**` moves position. Prefer `main`. |
| `AGENT/GDD/GDD_10_Roadmap.md` | content | 1 | **Take integration.** Only `**Last verified:**` — 2026-07-29 vs 2026-07-28. Keep the later. |
| `AGENT/GDD/GDD_07_Screens_Panels.md` | content | 2 | **Split — see open question 1.** Date hunk: `main` is later (2026-07-25 vs 2026-07-19). Content hunk: integration is a superset (adds the open-activity-registry seam status). |
| `AGENT/Docs/plans/project_control_plane_2026-06-29.md` | content | 2 | Date hunk: **take integration** (2026-07-28 > 2026-07-21). Queue hunk: **see open question 2 — both sides are stale.** |
| `AGENT/Docs/INDEX.md` | content | 5 | **Do not hand-merge.** Generated. Take either side, then run `python3 AGENT/Docs/gen_docs_index.py` and commit the regenerated file. |
| `AGENT/Session Notes/INDEX.md` | content | 1 | **Union.** Hand-maintained index; keep both sides' rows, newest first, and add rows for the two renames below. |
| `AGENT/Session Notes/2026-07-17.md` | **add/add** | — | **Keep both — see rename rule.** |
| `AGENT/Session Notes/2026-07-19.md` | **add/add** | — | **Keep both — see rename rule.** |

### Rename rule for the two add/add session notes

These are genuinely different sessions that happened to be written on the same
date on parallel branches — the known filename-collision pattern, not duplicated
work. Both must survive.

- `main` side: branch-context notes from `agent/playtest-release-v0.5-fixes`.
- `integration` side: the v0.5.0 publication note (07-17) and the
  `B5-AI-MIN-SCORER` decision note (07-19).

**Rename the integration side, never `main`'s.** `main`'s paths are published;
renaming them creates divergence that reappears at the next reconcile.

```
AGENT/Session Notes/2026-07-17.md  (integration) -> 2026-07-17-v050-publication.md
AGENT/Session Notes/2026-07-19.md  (integration) -> 2026-07-19-ai-scorer-decisions.md
```

Then take `main`'s file at each original path, and add index rows for the
renamed pair.

## Post-merge steps, in order

1. `python3 AGENT/Docs/gen_docs_index.py` — regenerates `INDEX.md` and
   `REGISTERS.md`; commit in the same change (enforced by `check_docs.py` #18).
2. `python3 AGENT/Docs/check_docs.py`
3. `bash scripts/ci/check_gdscript_style.sh`
4. `bash run_tests.sh` — full suite must be green before push.
5. A session note claiming every non-merge commit by **full SHA** with an
   em-dash separator (`- \`<40-hex>\` — <subject>`), or the pre-commit hook
   rejects the commit.

## Open questions for the owner

1. **`GDD_07_Screens_Panels.md` date vs content.** Integration carries newer
   content (the open activity registry seam marked Implemented 2026-07-19) under
   an *older* `Last verified` date than `main`'s 2026-07-25. Taking the union
   plus the later date asserts a verification that did not cover the added
   sentence. Recommend taking the union content and re-verifying the section
   rather than inheriting either date.
2. **`project_control_plane_2026-06-29.md` playtest-waiting queue.** Both sides
   are stale: integration's section is scoped to the **v0.5.2** return, `main`'s
   to **v0.4.1**. v0.5.8 is now accepted and shipped, so neither is correct and a
   textual merge would preserve a wrong statement either way. Recommend
   rewriting the section against current state as a follow-up rather than
   resolving it inside this merge.

Neither blocks the merge; both need a decision before the resulting text is
trustworthy.

## Constraints

- Target is `agent/integration`. `main` is never a merge target for an agent.
- Deleting the obsolete slash-ref `agent/playtest-release/v0.5-fixes` is tracked
  by the same task but is **independent** and needs explicit approval. Do not
  fold it into this merge.
- `agent/from-staging-area/agents-policy-block-sync` is still unmerged, so both
  `main` and `agent/integration` carry the stale `agent/coordination` policy
  text. It is not a conflict here; land it separately
  (`PP-AGENTS-POLICY-BLOCK-SYNC-2026-07-29`).
