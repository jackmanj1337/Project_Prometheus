# Documentation Sorting / Storage / Retrieval — Audit & Findings

**Date opened:** 2026-06-23
**Status:** Active — audit input for the doc-reorg design walk (no moves yet).
**Reconciles with:** `documentation_governance_2026-06-13.md` (status vocab, DOC-009 decision
schema), `documentation_lifecycle_2026-06-13.md` (the consolidation's move/keep table),
`decision_index.md` (DOC/RULE/SET/OPEN/RNG/AWR namespace), the
`documentation_consolidation_*` series, `AGENT/Docs/check_docs.py` (17 checks).
**Pairs with:** `documentation_system_design_2026-06-23.md` (the decisions register — written
after this audit, walked + ratified before any file moves).

> This is **findings only**. It inventories and classifies what exists and names the pain
> points. It does **not** move, rename, or delete anything. The design register proposes the
> changes; nothing is migrated until the owner ratifies.

---

## 0. What already exists (build on it, don't reinvent)

The June 2026 consolidation already established a real governance spine. The reorg must
extend these, not replace them:

- **Status vocabulary** (DOC-003): `Implemented / Pending validation / Known issue /
  Target design / Planned / Deferred / Open decision / Historical / Superseded` + `Split`,
  with `Last verified: YYYY-MM-DD`. The words *current / complete / canonical* are banned in
  status lines. Enforced by `check_docs.py` checks 7–8 (numbered GDD chapters only).
- **Decision system** (DOC-009): dated `decision_record_*` files + a central
  `decision_index.md` mapping every `DOC-/RULE-/SET-/OPEN-/RNG-/AWR-` ID to a home + status.
- **Historical/ARCHIVED marker convention**: `check_docs.py._is_historical()` already reads a
  `> **Historical**` / `> **ARCHIVED**` blockquote in the first 10 lines to exempt a file from
  active-doc path checks. **This is the supersession hook we should reuse.**
- **check_docs.py**: 17 structural checks, run in pre-commit + CI. Any new mechanical
  convention we add must land a check here (DoD#2).

**The gap is not governance — it is sorting, storage, and a catalog.** Governance describes
*how a doc should be labelled*; nothing describes *where docs live* or *gives a single index
of the open-question registers*.

---

## 1. Inventory of `AGENT/Docs/` (126 entries)

Counts below are by **type** then cross-cut by **lifecycle**. Full per-file dispositions are
in the design register's migration table; this section establishes the shape of the problem.

### 1a. By TYPE

| Type | Count (approx) | Examples |
|---|---|---|
| **Open-question / decisions registers** (`[XXX-n]` namespace) | 19 | `ai_profiles_*`, `doors_chests_*`, `campaign_content_overlay_*`, `datamanager_decomposition_*`, `campaign_save_open_decisions_*`, `legal_licensing_*` |
| **Design / vision docs** | ~12 | `ai_system_design_vision_*`, `input_mode_architecture_design_*`, `display_scaling_resolution_design_*`, `rng_determinism_design_*`, `individual_threat_range_design_*` |
| **Implementation plans** | ~12 | `*_implementation_plan_*`, `class_skill_rebuild_plan_*`, `m6_promotion_plan_*`, `unit_progression_extraction_plan_*`, `awakening_compatability_refactor_plan_*` (AWR home — Active) |
| **Handoffs** | 5 | `handoff_2026-06-09d`, `handoff_2026-06-13j`, `handoff_2026-06-20*` (3) |
| **Playtest builds** | 6 | `playtest_build_v0.1.4 … v0.2.3` |
| **Playtest checklists (+ `_returned_`)** | ~15 | `playtest_checklist_v0.1.3 … v0.2.3`, `*_returned_*`, `playtest_checklist_display_accessibility_*` |
| **Playtest findings / fix / triage plans** | ~10 | `playtest1..4_findings_*`, `playtest_*_fix_plan_*`, `playtest_v0.2.x_triage_plan_*`, `manual_test_findings_analysis` |
| **Decision logs / records / index** | 4 | `decision_index`, `decision_record_2026-06-13_*`, `design_decisions_log_2026-05-17`, `online_play_design_decisions` |
| **Governance / consolidation** | ~10 | `documentation_governance_*`, `documentation_lifecycle_*`, `documentation_consolidation_{plan,decisions,handoff,handoff b,master_checklist,preimplementation_review}_*`, `documentation_review_2026-06-13/14`, `documentation_review_instructions` |
| **Active guides / runbooks** (check_docs-protected) | 8 | `testing_guide`, `map_authoring_guide`, `environment_setup`, `campaign_rules`, `manual_test_playbook`, `Docker Instructions`, `new_machine_transfer_checklist`, `fe_map_sprite_importer_guide` |
| **Reference / feasibility / Q&A** | ~8 | `second_player_control_feasibility`, `pair_up_combat_refactor_{questions,answers}_*`, `d2_*`/`d3_* design`, `campaign_rules_firming_notes_*`, `gdd_codebase_alignment_audit_*` |
| **Non-markdown assets** | 14 | 4 PNG (+4 `.import`), 2 `.log`, `code_review_instructions.txt`, `check_docs.py` |
| **Today's active campaign/save thread** | 5 | `campaign_save_expectations_and_foundations_*`, `player_facing_scope_map_*`, `planning_backlog_2026-06-20`, + the two resolved registers above |

### 1b. By LIFECYCLE (from each file's Status header)

- **Active drivers / live** (~20): the 8 active guides, `decision_index`, `documentation_governance`,
  `planning_backlog_2026-06-20`, `campaign_save_expectations_and_foundations_2026-06-23`,
  `player_facing_scope_map_2026-06-23`, `awakening_compatability_refactor_plan` (AWR home),
  `v0.2.2_review_checkbacks`, `documentation_consolidation_decisions` (REG home for DOC/RULE/SET).
- **OPEN registers** (4): `campaign_save_open_decisions` (`[CST]` — partially, CST-13 open),
  `legal_licensing` (`[LEG]`), `map_sprite_importer` (`[IMP]`), `public_identity_rename` (`[REN]`).
- **RESOLVED registers** (~12): `[AIP]`, `[BWN]`, `[ICO]`, `[DMR]`, `[DCH]`, `[DTR]`, `[FOW]`,
  `[MET]`, `[MRD]`, `[PKGA]`, `[STW]`, `[ICD]`. Most are "build-ready" — resolved on the
  *design* side, awaiting *execution*.
- **Target design, not yet built** (~9): the input-mode / gamepad / scaling / threat-range /
  selector / web-debug design + plan docs; `rng_determinism_design`; `ai_first_build_design`.
- **Implemented** (~3): `mouse_only_cursor_mode_design`, `terrain_more_info_paging_design`,
  `stat_breakdown_character_sheet_plan`.
- **Superseded / executed-historical** (~25+): all the May implementation/test-map plans, the
  v0.1.x/v0.2.0 playtest checklists+returns+findings+fix/triage plans, the consolidation
  plan/checklist/handoffs/reviews, `design_decisions_log_2026-05-17`, the `.png`/`.log` evidence.

**~half of `AGENT/Docs/` is historical evidence sitting in the same flat namespace as the
~20 docs you actually steer by.**

---

## 2. Pain points (concrete)

1. **Flat directory, 126 entries, no active-vs-archive separation.** Resolved registers,
   shipped plans, year-old playtest returns, and today's live scope map are all peers in one
   `ls`. Retrieval is "remember the filename or grep."
2. **No catalog of the registers.** `decision_index.md` covers the `DOC/RULE/SET/OPEN/RNG/AWR`
   namespace but **does not know the `[CST/DMR/ICO/AIP/DCH/DTR/FOW/MET/MRD/STW/PKGA/ICD/BWN/
   LEG/IMP/REN]` register namespace at all.** There are ~19 registers and ~150 individual
   `[XXX-n]` IDs with no single place that says *which are OPEN vs RESOLVED and where each was
   resolved.* Roadmap §H tracks this **in prose** (a dense ~150-line paragraph), not a manifest.
3. **Supersession is invisible.** The 2026-06-23a base+overlay content model was *reversed* by
   `[ICO-1..6]` the same day; the only record that the old direction is dead lives in session
   notes + a parenthetical in roadmap §H. A reader opening a superseded doc gets no in-file
   signal. The `_is_historical()` marker exists in code but is barely used in `AGENT/Docs/`.
4. **Two parallel "where was X decided?" systems that don't cross-reference.** `decision_index`
   (governance IDs) and the register files (feature IDs) never point at each other, and neither
   is reachable from a doc map.
5. **Retrieval is grep-only.** There is no `AGENT/Docs/INDEX.md` (Session Notes has one;
   `AGENT/Docs/` does not). New session onboarding = read the latest session note + grep.
6. **Status headers are inconsistent.** ~40 of the `.md` files have **no Status header at all**
   (every playtest build/checklist, the guides, the May plans). The governance vocab is only
   *enforced* on `GDD_00–08`, so `AGENT/Docs/` drifted.

---

## 3. Constraints carried into the design

- **Lose nothing from today's thread**: the 5 campaign/save docs + 8 session notes (a–h) + the
  i rollup. These are explicitly in-scope to *preserve*, not touch beyond an archive marker if
  ever superseded.
- **Git is the backstop**: deleted files remain recoverable. So the bar for *keeping a file in
  the working tree* is "contains information not already captured elsewhere." Pure duplicates /
  fully-superseded scaffolding *may* be deletion candidates — but only with owner confirmation
  and never for anything with unique rationale.
- **Every mechanical rule ships with a `check_docs.py` guard** in the same commit (DoD#2).
- **`git mv` for every move** (preserve history); update live inbound refs + GDD/roadmap
  pointers in the same commit (DoD#1); keep check_docs green (17/17 today); no `__pycache__`.
- **No bulk move or deletion without explicit owner confirmation.**

---

## 4. Inbound-reference reality (what a move must not orphan)

`check_docs.py` already guards against active docs linking to dead paths (checks 1–2) and lists
the **active guide set** that must keep working paths (`testing_guide`, `map_authoring_guide`,
`environment_setup`, `campaign_rules`, `manual_test_playbook`, `Docker Instructions`,
`new_machine_transfer_checklist`). The check itself hard-codes these `AGENT/Docs/...` paths —
**so moving any guide means updating `check_docs.py`'s path lists in the same commit.** The
master review procedure (`AGENT/Review Procedures/00_*`) names top-level dirs (check 11); adding
an archive subfolder under `AGENT/Docs/` does not trip it (it scans repo-root dirs only), but a
new top-level dir would. Design should prefer subfolders under `AGENT/Docs/` over new top-level
dirs for this reason.

---

## 5. Handoff to the design register

The design walks five decisions, each options + recommendation, ratified before any move:
1. Taxonomy of doc types + reuse of the lifecycle vocabulary.
2. Storage layout (subfolders by type vs active/archive split; naming; required headers).
3. Central index/manifest: a **registers catalog** + the existing decision index + a doc map —
   generated vs hand-maintained.
4. Supersession marking (reuse the `_is_historical()` blockquote + a `Superseded-by:` field).
5. Retrieval workflow — the canonical "where is X decided / what's active" path.
</content>
