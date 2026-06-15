# Documentation Consolidation Handoff — Ready to Execute

**Date:** 2026-06-13
**Supersedes:** `documentation_consolidation_handoff_2026-06-13.md`
**SUPERSEDED BY:** `documentation_consolidation_master_checklist_2026-06-13.md` —
this handoff only covered Phases 1–3; the master checklist covers the full
Phase 1→7 + Package G scope. Use the master checklist; this file is retained for
provenance (its Appendix A inventory is carried forward there).
**Status:** Superseded.

## Where things stand

Every decision is resolved and recorded. No owner input is outstanding.

- Decision register fully answered: `documentation_consolidation_decisions_2026-06-12.md`
- June reference imported + dispositioned: `decision_record_2026-06-13_june_reference_import.md`
- Governance ratified (status vocabulary, GDD section template, decision-record
  schema/ID namespace): `documentation_governance_2026-06-13.md`
- Plan reconciled: `documentation_consolidation_plan_2026-06-12.md`

## Reading order for next session

1. This handoff
2. `documentation_governance_2026-06-13.md` (the standards you apply)
3. `decision_record_2026-06-13_june_reference_import.md`
4. `documentation_consolidation_decisions_2026-06-12.md`
5. `documentation_consolidation_plan_2026-06-12.md` (Phase 0 = complete; start Phase 1)

## The checklist — execute in this order

### [ ] 1. Phase 1 — file lifecycle / link-migration table

Build a table at `AGENT/Docs/documentation_lifecycle_2026-06-13.md` with one row
per tracked doc: current path, status label, authority scope, action
(keep/merge/move/supersede/delete), merge target, retained headings, inbound
refs, acceptance check. The inbound-reference sweep is already done — see
**Appendix A** below; start from it rather than re-searching.

Exit: every document has an explicit lifecycle and no move would orphan a live link.

### [ ] 2. Update the RNG contract to two-RN (RULE-001) — Package A prerequisite

In `rng_determinism_design_2026-06-11.md`: change the hit draw to two 0–99 draws,
floor the average, compare to resolved hit; crit only after a successful hit;
skill activations at their trigger slots. Update the fixed roll-order fixture
(currently freezes the one-roll order) and the save-compatibility notes. Do this
before any `RngService` code.

Exit: contract, fixture, and save notes all describe the two-RN order.

### [ ] 3. Seed the new index files

- `AGENT/Docs/decision_index.md` — per the DOC-009 schema; one row per existing
  DOC-/RULE-/SET-/OPEN-/RNG-/AWR- ID with status + link + supersession (record
  D-C → superseded by DOC-001).
- `AGENT/GDD/GDD_Feature_Index.md` — the DOC-005 dedicated index, columns per
  plan §5; can start with the initial feature groups in plan §5.

Exit: both files exist and are linked from where they'll live (GDD_00 link added
in Phase 2).

### [ ] 4. Then Phase 2 + interleaved Phase 3/4

Phase 2 rewrites `GDD_00` (authority model from DOC-001, status vocabulary, GDD
section template, doc index, feature-index link, known issues, 1.0 definition +
platform targets). Then Phase 3 chapters using the section template, with each
chapter's Phase-4 adoption-matrix rows completed in the same commit.

## Apply-as-you-go reminders

- Every numbered-GDD section uses the **section template** and a **status label**
  with a `Last verified` date (governance doc). No "current/complete/canonical".
- Corpus rules need an **adoption-matrix row before/with** the GDD edit (DOC-001).
- Moves/deletes happen **only after** the Phase 1 table is reviewed, applied
  atomically with link repairs (DOC-006/008).
- Honor the doc-lifecycle DoD rule (PL#8): update affected GDD sections + flip
  roadmap status in the same commit. Add this rule to `AGENTS.md` during Phase 2.

## Preserve this worktree state

Still deliberately untracked, do not fold into unrelated commits:

- `AGENT/GDD/gdd_update_reference_2026-06-12.md` (move to `AGENT/Docs` is a Phase 1
  action; archived once applied — DOC-010)
- `AGENT/GDD/rng_determinism_design_2026-06-11.md` (move to `AGENT/Docs`; merges
  into the GDD feature-design home — DOC-010)
- combat-preview screenshots + `.import` files in `AGENT/Docs`

## Stop conditions

Pause the affected branch if: a file's useful content has no confirmed merge
target; a move would orphan a live inbound reference; a corpus rule lacks an
exact source heading or project-variation entry; or implementation behavior would
be chosen without an answered decision.

---

## Appendix A — inbound-reference inventory (swept 2026-06-13)

Live = onboarding/active GDD/guide that must be repaired on move. Historical =
audits / superseded plans / session notes (annotate optional, no repair needed).
Self-referential consolidation docs (register/plan/review/handoffs) are omitted —
they describe the moves and update naturally.

### `GDD_10a_Overview.md` → retire (roadmap owns content/order/status, DOC-004)
- **Live:** `README.md:19`; `GDD_00_Overview.md:22,36`
- Historical: `gdd_codebase_alignment_audit_2026-06-11.md:23,68,70,156`;
  `campaign_rules_firming_notes_2026-05-25.md:86`;
  `playtest_triage_execution_plan_2026-05-26.md:195`;
  internal: `GDD_09_Checklist.md:52`, `GDD_Assumptions`/`GDD_Manual_Tasks` rows in
  10a itself (162–163), rng/update-reference (both being moved)

### `GDD_09_Checklist.md` → merge then delete (DOC-006)
- **Live:** `GDD_00_Overview.md:20,37`; `GDD_01_Architecture.md:30`;
  `GDD_10_Roadmap.md:13,41` plus backlog refs `1627,1644,1655,1656,1659,1660,1695`
  ("GDD_09 Phase 2 backlog" — reword to the roadmap's own backlog)
- Historical: `code_review_2026-05-18.md` (many); `code_review_2026-05-21b.md:54`;
  `gdd_codebase_alignment_audit_2026-06-11.md:24,62,69`

### `GDD_Assumptions.md` → merge then delete (DOC-006)
- **Live:** `GDD_00_Overview.md:24,37`
- Historical: `gdd_codebase_alignment_audit_2026-06-11.md:24,63`; `GDD_10a:162`
  (10a retiring); internal `GDD_Assumptions.md:42` self

### `GDD_Manual_Tasks.md` → move to `AGENT/Docs/manual_test_playbook.md` (DOC-007)
- **Live:** `GDD_00_Overview.md:25`; `testing_guide.md:46,150,175,183`;
  `GDD_10_Roadmap.md:1337`; `Play_tester_comments.md:4`
- Historical: `promotion_reclass_test_map_plan_2026-05-23.md` (several);
  `hotseat_test_map_plan_2026-05-21.md:213`; `playtest_fix_plan_2026-06-09.md:6,41`;
  `playtest_triage_execution_plan_2026-05-26.md:194`; `handoff_2026-06-09d.md:62,130`;
  `GDD_10a:48,163` (retiring)

### `gdd_update_reference_2026-06-12.md` → move to `AGENT/Docs` now, archive once applied (DOC-010)
- Only referenced by consolidation docs (self-updating) + the RNG companion

### `rng_determinism_design_2026-06-11.md` → move to `AGENT/Docs`, later merge into GDD feature home (DOC-010)
- Only referenced by consolidation docs + the update reference

**Note:** `README.md:19` is the highest-priority external link (onboarding) — it
points at both `GDD_10_Roadmap.md` (stays) and `GDD_10a_Overview.md` (retires).
