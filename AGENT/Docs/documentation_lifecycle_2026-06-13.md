# Documentation File Lifecycle & Link-Migration Table

**Date opened:** 2026-06-13
**Status:** Active — Phase 1 / Stage 1.1 deliverable of the consolidation.
**Plan:** `documentation_consolidation_master_checklist_2026-06-13.md` (Stage 1.1)
**Inbound sweep:** verified 2026-06-13 (live refs re-checked against README, GDD_00,
GDD_01, GDD_10, testing_guide).

## Purpose & gate

One lifecycle per tracked document so no move orphans a live link. **Gate (DOC-006/
008/010):** no move/delete happens until this table is reviewed; each move/delete is
applied **atomically with its link repairs** in the stage noted. "Live" inbound refs
(onboarding / active GDD / active guide) MUST be repaired on move; "Historical" refs
(audits, superseded plans, session notes) need no repair.

Actions: **keep** · **rewrite** (keep path, rewrite content in a later stage) ·
**move** · **merge→delete** · **delete/retire** · **archive** · **supersede-in-place**.

---

## A. Files that MOVE / MERGE / DELETE (need atomic link repair)

| Doc | Status | Authority scope | Action | Target / retained headings | Live inbound refs to repair | Stage | Acceptance check |
|---|---|---|---|---|---|---|---|
| `GDD_10a_Overview.md` | Historical | (claimed roadmap order) | **delete/retire** (DOC-004) | Unique ordering/concise history → merge into `GDD_10_Roadmap.md` | `README.md:19,?`; `GDD_00:22,36` | 4.1 | File gone; README + GDD_00 point only to GDD_10; no live link resolves to 10a |
| `GDD_09_Checklist.md` | Historical | MVP build sequence | **merge→delete** (DOC-006) | Any still-open items → roadmap backlog | `GDD_00:20,37`; `GDD_01:30`; `GDD_10_Roadmap.md` (11 backlog refs) | 5.2 | File gone; refs reworded to roadmap's own backlog; no live link to GDD_09 |
| `GDD_Assumptions.md` | Historical | GBA-convention assumptions | **merge→delete** (DOC-006) | Still-valid assumptions → owning GDD section as Target/Implemented | `GDD_00:24,37` | 5.2 | File gone; GDD_00 supporting-docs lines removed/redirected |
| `GDD_Manual_Tasks.md` | Implemented (operational) | manual acceptance steps | **move** (DOC-007) | → `AGENT/Docs/manual_test_playbook.md` (content unchanged) | `GDD_00:25`; `testing_guide.md:46,150,175,183`; `GDD_10_Roadmap.md:1337` | 5.2 | New path exists; all 4 live refs updated; feature index manual-coverage cells point to new path |
| ~~`AGENT/GDD/rng_determinism_design_2026-06-11.md`~~ → `AGENT/Docs/rng_determinism_design_2026-06-11.md` | Target design (impl. plan) | RNG/save/rewind/online | **DONE (3.1)** move + merge (DOC-010) | Binding rules merged into `GDD_01 §Determinism` + `GDD_02 §Combat`; file moved to Docs, re-scoped as implementation plan, now tracked | none live | 3.1 ✓ | Binding rules in GDD_01/02 ✓; file archived once `RngService` + tests land |
| `gdd_update_reference_2026-06-12.md` | Historical (once applied) | June update input | **archive** (DOC-010) | All dispositions already imported to decision record | none live (consolidation docs only) | 5.2 | Marked Historical/archived after all dispositions reflected in GDD/roadmap |

> **Stage 2 update (2026-06-13):** `GDD_00` was rewritten and no longer links these
> four files as *authority* sources — they now appear only in its "Documents being
> retired or migrated" subsection as status notes. Those bullets (not the old
> line numbers 20/22/24/25/36/37) are what each file's deletion removes. README and the
> other live refs in this table are unchanged.

> `Play_tester_comments.md` (`AGENT/GDD`) — Historical raw notes. **Action: keep**
> (not a contract). Optional: relocate to `AGENT/Docs` with the playbook later; no live
> dependency forces a move, so out of Stage 1 scope.

---

## B. Live numbered GDD — keep path, rewrite content

| Doc | Status | Action | Stage |
|---|---|---|---|
| `GDD_00_Overview.md` | Active entry point | **rewrite** (authority model, status vocab, indices, platform targets) | 2.1 |
| `GDD_01_Architecture.md` | Active contract | **rewrite** (data/serialization, RNG autoload, pipeline order, CampaignRules) — DONE 2026-06-13 | 3.5 |
| `GDD_02_Core_Mechanics.md` | Active contract | **rewrite** (two-RN, modifier pipeline, combat rulings; absorb RNG binding rules) | 3.1 |
| `GDD_03_Units_Classes.md` | Active contract | **rewrite** (progression, promotion/reclass, class corpus adoption) | 3.2 |
| `GDD_04_Weapons_Items.md` | Active contract | **rewrite** (triangle, rank bonuses, WEXP, economy) — DONE 2026-06-13 | 3.3 |
| `GDD_05_Skills.md` | Active contract | **rewrite** (skills, Pair Up, conditions precedence) — DONE 2026-06-13 | 3.4 |
| `GDD_06_Maps_Objectives.md` | Active contract | **rewrite** (terrain split tables, objectives) — DONE 2026-06-13 | 3.6 |
| `GDD_07_UI_UX.md` | Active contract | **rewrite** (UI/input/accessibility) | 3.7 |
| `GDD_08_Enemy_AI.md` | Active contract | **rewrite** (AI parity, performance) | 3.8 |
| `GDD_10_Roadmap.md` | Active roadmap | **rewrite** (sole roadmap owner; absorb 10a; stable IDs; Package G owners) | 4 |
| `GDD_Feature_Index.md` | Active (seed) | **keep** (populate anchors during Stage 3) | 3 |

---

## C. Active `AGENT/Docs` — keep (verify in Stage 5/6)

| Doc(s) | Status | Action |
|---|---|---|
| `documentation_consolidation_master_checklist_2026-06-13.md` | Active | keep (this consolidation's live checklist) |
| `documentation_consolidation_plan_2026-06-12.md`, `..._decisions_2026-06-12.md`, `documentation_governance_2026-06-13.md`, `decision_index.md`, `decision_record_2026-06-13_june_reference_import.md`, `documentation_lifecycle_2026-06-13.md` (this file) | Active | keep (decision/governance system) |
| `documentation_consolidation_preimplementation_review_2026-06-13.md` | Historical | supersede-in-place (header) — readiness review, now executed |
| `documentation_consolidation_handoff_2026-06-13.md`, `..._handoff_2026-06-13b.md` | Superseded | keep (already point to master checklist) |
| `testing_guide.md`, `map_authoring_guide.md`, `fe_map_sprite_importer_guide.md`, `environment_setup.md`, `Docker Instructions.md` | Active guides | keep → verify paths/commands + `Last verified` (Stage 5.1); repair `GDD_Manual_Tasks` link in testing_guide on its move |
| `campaign_rules.md` | Active design/data | keep → reconcile with CampaignRules stub (Stage 4.3) |
| `online_play_design_decisions.md` | Active design | keep → merges/links into GDD_01 online seam (Stage 3.5); RNG-4 owns the contract |

---

## D. Awakening corpus reference (`AGENT/GDD/Content Expansion/`)

| Group | Status | Action |
|---|---|---|
| `New_Content_Expansion/awakening_*.md` (12 reference files + 2 indexes) | Reference (corpus) | **keep** — corpus owns Awakening reference data only; never project rules (DOC-001). Cited via adoption matrix. |
| ~~`New_Content_Expansion/project_adoption_matrix.md`~~ → `AGENT/GDD/GDD_Adoption_Matrix.md` | Active | **DONE (Stage 3.0)** — expanded into the systematic matrix and **moved** to the live GDD set (project authority artifact, not corpus, per DOC-001). 3 corpus inbound links repaired (`awakening_project_index.md`, `awakening_master_index.md` ×2). |
| `Old_Deferred/*.md` (9 files) | Historical (archived source) | **keep** — archived homebrew/source material, never live rules; no live inbound refs |

---

## E. Historical bulk — category rules (keep in place; supersession headers in Stage 5.3)

These are dated evidence/instructions superseded by current contracts. **Action: keep,
mark Historical/Superseded with a header; remove any current-doc link that implies they
are still active.** None are deleted (provenance via Git). Live docs must not link to
them as instructions.

| Category (path) | Count | Status | Notes |
|---|---|---|---|
| `AGENT/Session Notes/*.md` | 78 | Historical | Work record + handoff context; never current rules. Keep. |
| `AGENT/Code Reviews/*.md` | 21 | Historical | Dated findings/evidence; never current rules. Keep. |
| `AGENT/Docs` superseded plans: `implementation_plan_2026-05-16*.md`, `implementation_plan_2026-05-21.md`, `class_skill_rebuild_plan_2026-05-21.md`, `m6_promotion_plan_2026-05-21.md`, `m7_second_seal_plan_2026-05-21.md`, `combat_preview_render_fix_plan_2026-06-10.md`, `more_info_mode_plan_2026-05-24.md` | — | Superseded | Implemented or replaced; supersession header in Stage 5.3. |
| `AGENT/Docs` test/playtest history: `playtest1…4_findings_*.md`, `playtest2_fix_plan_2026-05-19.md`, `playtest_fix_plan_2026-06-09.md`, `playtest_triage_execution_plan_2026-05-26.md`, `playtest_build_v0.1.4.md`, `playtest_checklist_v0.1.3*.md`, `playtest_checklist_v0.1.4.md`, `manual_test_findings_analysis.md`, `hotseat_test_map_plan_2026-05-21.md`, `promotion_reclass_test_map_plan_2026-05-23.md`, `handoff_2026-06-09d.md` | — | Historical | Evidence; confirmed bugs migrate to roadmap tracker (Stage 4.2), then prose stays as history. |
| `AGENT/Docs` design Q&A / feasibility: `pair_up_combat_refactor_questions/answers_2026-05-23.md`, `campaign_rules_firming_notes_2026-05-25.md`, `second_player_control_feasibility.md`, `d2_mapcursortargeting_design.md`, `d3_mapcursor_slicing_design.md` | — | Historical | Rationale preserved; useful content already in code/contracts. |
| `AGENT/Docs/design_decisions_log_2026-05-17.md` | 1 | Historical | Superseded by the DOC-009 dated-record + index system; header in Stage 5.3. |
| `AGENT/Docs/gdd_codebase_alignment_audit_2026-06-11.md` | 1 | Historical | Audit evidence feeding the consolidation; keep. |

### E-special: active roadmap source

| Doc | Status | Action |
|---|---|---|
| `awakening_compatability_refactor_plan_2026-05-22.md` | **Active** | keep — home of the `AWR-` milestone IDs (AWR-2, AWR-8, …). Reconciled with `GDD_10_Roadmap.md` in Stage 4; do **not** treat as historical. |

---

## Exit criterion (Stage 1.1)

Met: every tracked document has an explicit lifecycle (rows in A–E), and every file
slated to **move/delete** (Section A) has its live inbound references enumerated with a
repair stage, so no planned move would orphan a live link.
