---
Type: plan
Status: Active - planning input
Last verified: 2026-06-29
---

# Document Role Manifest

**Started:** 2026-06-29. Draft role map for the Project Control Plane and GDD
rewrite.

**Purpose.** Define what each active documentation family is allowed to own.
This manifest supports future `check_docs.py` enforcement for role separation,
active-doc ownership, and stale planning-doc cleanup.

This is a target structure, not an enforcement check yet.

## Role Rules

1. A document has one primary role.
2. A document can link to other roles, but it must not silently take over their
   job.
3. Work status lives in the Project Control Plane unless a GDD chapter carries
   the short design-section status required by governance.
4. Generated indexes are navigation only and are never hand-edited.
5. Resolved registers stay decision evidence. Do not archive them just because
   their open questions are resolved.
6. Session notes are historical handoff records. They do not own active plans.

## Role Vocabulary

| Role ID | Allowed paths | Owns | Must not own | Control-plane rule |
|---|---|---|---|---|
| `authority_index` | `AGENT/GDD/GDD_00_Overview.md` | Authority model, release definition, navigation entry points. | Feature detail, work queues, register deliberation. | May link to tracker rows but does not duplicate them. |
| `design_contract` | `AGENT/GDD/GDD_01_Architecture.md` through `AGENT/GDD/GDD_08_Enemy_AI.md` | Short rule/design contracts by domain. | Long deliberation history or full build schedule. | Every active feature should point to one or more GDD owners. |
| `build_guide` | `AGENT/GDD/GDD_10_Roadmap.md` | Human build guide, dependency-band narrative, next-work queue, release/validation summaries. | Full control-plane table, stale milestone checklist detail. | Links to Track IDs; does not own row schema. |
| `control_plane` | `AGENT/Docs/plans/project_control_plane_2026-06-29.md` | Row-per-work-item tracker, dependencies, owners, sources, tests, next actions. | Long-form design explanation, historical session narrative. | Source for Track IDs and tracker schema. |
| `feature_index` | `AGENT/GDD/GDD_Feature_Index.md` | Feature lookup from feature name to GDD owner, Track ID, decisions, plans, tests, and code/data anchors. | Roadmap sequencing or deliberation. | References Track IDs after wiring pass. |
| `generated_index` | `AGENT/Docs/INDEX.md`, `AGENT/Docs/REGISTERS.md` | Generated navigation. | Hand-authored status, schedule, or exceptions. | Must be regenerated after active-doc add/move/retitle/header changes. |
| `decision_index` | `AGENT/Docs/decisions/decision_index.md` | Governance and decision ID lookup. | Feature scheduling. | Referenced by GDD and tracker rows when decision IDs matter. |
| `decision_register` | `AGENT/Docs/registers/*.md` | Open-question answers, resolved design decisions, rationale, and cross-links. | Active build order after a tracker row exists. | Register rows supply `Decision source` values. |
| `implementation_plan` | `AGENT/Docs/plans/*.md` except the control plane and generated transition artifacts | Build plans, inventories, triage inputs, migration plans. | Owning live status without a tracker row. | Active plans need a Track ID or explicit exception. |
| `design_source` | `AGENT/Docs/design/*.md` | Architecture contracts, design visions, research, and source evidence. | Schedule ownership. | Active design docs need a Track ID, feature-index row, or source exception. |
| `playtest_validation` | `AGENT/Docs/playtests/*.md` | Build manifests, playtest checklists, validation queues, and returned-test evidence. | Hiding release blockers outside the tracker. | Blocking validation needs a `VAL-*` or `REL-*` row. |
| `operational_guide` | `AGENT/Docs/guides/*.md` | How-to runbooks for setup, testing, map authoring, and tools. | Design authority or work status. | Linked from tracker rows only when needed for execution. |
| `governance` | `AGENT/Docs/governance/*.md` | Documentation rules, lifecycle, reviews, and system design. | Feature-specific implementation schedule. | New mechanical rules require `check_docs.py` coverage in the same change. |
| `review_procedure` | `AGENT/Review Procedures/*.md`, `AGENT/Code Reviews/*.md` | Review methods and review outputs. | Active roadmap ownership. | Findings that create work must get tracker rows. |
| `session_note` | `AGENT/Session Notes/*.md`, `AGENT/Session Notes/INDEX.md` | Historical session summary, commits, and next-session handoff. | Active source of truth for design or schedule. | New session notes need an index row. |
| `archive` | `AGENT/Docs/archive/**` | Historical or superseded evidence. | Active work ownership. | Files need the required archive marker in the first 10 lines. |

## Named Documents

| Path | Role ID | Status after rewrite | Notes |
|---|---|---|---|
| `AGENT/GDD/GDD_00_Overview.md` | `authority_index` | Active entry point | Should point to `GDD_10`, feature index, generated indexes, and governance. |
| `AGENT/GDD/GDD_01_Architecture.md` | `design_contract` | Active design contract | Owns save/schema/registry/action/resource/occupancy/death/projection architecture. |
| `AGENT/GDD/GDD_02_Core_Mechanics.md` | `design_contract` | Active design contract | Owns combat, turns, EXP, conditions, Source+Style combat behavior. |
| `AGENT/GDD/GDD_03_Units_Classes.md` | `design_contract` | Active design contract | Owns roster, classes, progression, stats, avatar/relationship hooks. |
| `AGENT/GDD/GDD_04_Weapons_Items.md` | `design_contract` | Active design contract | Owns IEQ, convoy, shop/economy, sources/equipment, story items. |
| `AGENT/GDD/GDD_05_Skills.md` | `design_contract` | Active design contract | Owns skills, grants, loadout caps, action grants, secondary movement. |
| `AGENT/GDD/GDD_06_Maps_Objectives.md` | `design_contract` | Active design contract | Owns maps, MET, map objects, objectives, villages, fog, spawn policy. |
| `AGENT/GDD/GDD_07_UI_UX.md` | `design_contract` | Active design contract | Owns UI/UX, input, PHB panels, dialogue presentation, validation surfaces. |
| `AGENT/GDD/GDD_08_Enemy_AI.md` | `design_contract` | Active design contract | Owns AI composition, profile registry, valuation, perception deferrals. |
| `AGENT/GDD/GDD_10_Roadmap.md` | `build_guide` | Active build guide | Rewrite around dependency bands and Track ID links. |
| `AGENT/GDD/GDD_Feature_Index.md` | `feature_index` | Active feature lookup | Track IDs are wired; exact section anchors follow GDD chapter rewrites. |
| `AGENT/Docs/plans/project_control_plane_2026-06-29.md` | `control_plane` | Active tracker | Row schema and Track IDs live here. |
| `AGENT/Docs/plans/gdd10_active_work_coverage_matrix_2026-06-29.md` | `implementation_plan` | Active transition input | Keep until `GDD_10` rewrite and control-plane seeding are verified. |
| `AGENT/Docs/plans/planned_unimplemented_feature_triage_2026-06-28.md` | `implementation_plan` | Active planning input | Scheduling source for dependency bands. |
| `AGENT/Docs/plans/living_project_tracking_system_plan_2026-06-29.md` | `implementation_plan` | Active planning input | System-design source for this tracking overhaul. |
| `AGENT/Docs/INDEX.md` | `generated_index` | Active generated index | Do not hand-edit. |
| `AGENT/Docs/REGISTERS.md` | `generated_index` | Active generated index | Do not hand-edit. |

## Ownership Exceptions For Active Plans

Some active plans are transition artifacts and may be referenced by the control
plane as a group rather than one row per document.

| Exception | Allowed while | Required cleanup |
|---|---|---|
| GDD rewrite transition artifacts | `B0-GDD10-REWRITE` and `B0-FEATURE-INDEX-WIRING` remain open | Archive or mark superseded after their content is folded into the control plane and GDD rewrite. |
| Existing implementation plans | Their owning feature row says `needs implementation plan` or points to the plan | Add direct Track ID links during feature-index wiring. |
| Research notes | Their topic is deferred or parked | Keep as source evidence, not schedule authority. |

## Future Enforcement Hooks

| Check | Reads | Rule |
|---|---|---|
| Active doc ownership | This manifest, `AGENT/Docs/INDEX.md`, Project Control Plane | Active plans/design docs need a Track ID, feature-index row, generated-index exception, or archive/supersession marker. |
| Role separation | This manifest, `GDD_10`, Project Control Plane | `GDD_10` must not duplicate the full control-plane table; the control plane must not become long-form design prose. |
| Generated index discipline | Generated file headers | Generated indexes must be refreshed after active-doc path/header changes. |
