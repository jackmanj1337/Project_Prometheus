---
Type: plan
Status: Implemented - ownership check
Last verified: 2026-07-15
---

# Document Role Manifest

**Started:** 2026-06-29. Draft role map for the Project Control Plane and GDD
rewrite.

**Purpose.** Define what each active documentation family is allowed to own.
This manifest supports `check_docs.py` enforcement for active-doc ownership and
the later role-separation work in the GDD consolidation.

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
| `design_contract` | Numbered `AGENT/GDD/GDD_01*.md` through `AGENT/GDD/GDD_08_Enemy_AI.md` contracts, including approved GDD 01/07 companions | Short rule/design contracts by domain. | Long deliberation history or full build schedule. | Every active feature should point to one or more GDD owners. |
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
| `AGENT/GDD/GDD_01_Architecture.md` | `design_contract` | Active entry contract | Owns project composition, scene/autoload responsibility, and extension boundaries. |
| `AGENT/GDD/GDD_01_Runtime_Contracts.md` | `design_contract` | Active companion contract | Owns CampaignRules, deterministic events, snapshots, and shared runtime boundaries. |
| `AGENT/GDD/GDD_01_Data_Contracts.md` | `design_contract` | Active companion contract | Owns resource schemas, persistence fields, validation, and authoring bindings. |
| `AGENT/GDD/GDD_02_Core_Mechanics.md` | `design_contract` | Active design contract | Owns combat, turns, EXP, conditions, Source+Style combat behavior. |
| `AGENT/GDD/GDD_03_Units_Classes.md` | `design_contract` | Active design contract | Owns roster, classes, progression, stats, avatar/relationship hooks. |
| `AGENT/GDD/GDD_04_Weapons_Items.md` | `design_contract` | Active design contract | Owns IEQ, convoy, shop/economy, sources/equipment, story items. |
| `AGENT/GDD/GDD_05_Skills.md` | `design_contract` | Active design contract | Owns skills, grants, loadout caps, action grants, secondary movement. |
| `AGENT/GDD/GDD_06_Maps_Objectives.md` | `design_contract` | Active design contract | Owns maps, MET, map objects, objectives, villages, fog, spawn policy. |
| `AGENT/GDD/GDD_07_UI_UX.md` | `design_contract` | Active entry contract | Owns cross-cutting UI state, feedback, accessibility, and parity. |
| `AGENT/GDD/GDD_07_Input_Cursor.md` | `design_contract` | Active companion contract | Owns input bindings/modes, repeat policy, cursor, and threat interaction. |
| `AGENT/GDD/GDD_07_Screens_Panels.md` | `design_contract` | Active companion contract | Owns the screen/panel catalog, settings, and per-surface behavior. |
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
| Existing implementation plans | Their owning feature row says `needs implementation plan` or points to the plan | Add direct Track ID links during feature-index wiring. |
| Research notes | Their topic is deferred or parked | Keep as source evidence, not schedule authority. |

The former blanket `GDD rewrite transition artifacts` exception expired when
`B0-GDD10-REWRITE` and `B0-FEATURE-INDEX-WIRING` became Implemented. Remaining
transition and research sources must now have an explicit owner below.

## Active Source Ownership Map

These non-historical plan/design sources are intentionally grouped under a
tracker row rather than linked individually from the Project Control Plane or
Feature Index. `check_docs.py` treats this table as the explicit exception map;
remove a row when the source gains a direct tracker/index link or a lifecycle
marker.

| Source | Owner | Reason / exit condition |
|---|---|---|
| [`accepted_portfolio_code_state_review_handoff_2026-07-27.md`](accepted_portfolio_code_state_review_handoff_2026-07-27.md) | `REVIEW-ACCEPTED-PORTFOLIO-CODE-STATE-2026-07-27`; accepted portfolio review | Next-session code-state review handoff; retire after every accepted slice has current-code evidence and the first tranche has a readiness verdict. |
| [`dialogue_recruit_capture_integrated_implementation_plan_2026-07-27.md`](dialogue_recruit_capture_integrated_implementation_plan_2026-07-27.md) | `B3-REQ`, `B3-MET`, `B4-DIALOGUE-V1`, `B4-CONVOY`, `SYS-RECRUIT-CAPTURE-2026-07-23` | Cross-track integrated plan; remove this exception after its slices are represented directly in the Control Plane/Feature Index or the plan is superseded by accepted per-slice plans. |
| [`recent_research_implementation_portfolio_review_2026-07-27.md`](recent_research_implementation_portfolio_review_2026-07-27.md) | `PLAN-RECENT-RESEARCH-SYSTEMS-2026-07-27`; recent research portfolio | Cross-plan inventory/review; retire after every listed stream has a consolidated accepted plan or explicit deferred/no-build disposition. |
| [`recent_research_implementation_planning_handoff_2026-07-27.md`](recent_research_implementation_planning_handoff_2026-07-27.md) | `PLAN-RECENT-RESEARCH-SYSTEMS-2026-07-27`; cross-track planning review | Next-session umbrella for inventorying recent research/discussion outcomes and writing or reviewing their implementation plans; retire or supersede after every inventory item has a tracker-backed accepted plan, deferral, or no-build disposition. |
| [`campaign_save_post_audit_followup_handoff_2026-07-15.md`](campaign_save_post_audit_followup_handoff_2026-07-15.md) | `B1-CST`, `B1-LEDGER`, `B6-CAMPAIGN-SHARING`, `B6-CAMPAIGN-STATUS`, documentation/process follow-up | Owner-ratified cross-track audit closeout; retire after its six-phase completion gate is satisfied or remaining phases gain direct tracker rows. |
| [`campaign_pack_boundary_next_session_handoff_2026-07-15.md`](campaign_pack_boundary_next_session_handoff_2026-07-15.md) | `B6-CAMPAIGN-SHARING` | Execution handoff for staged transactional installation; retire after archive slice 3 lands. |
| [`campaign_pack_engine_boundary_plan_2026-07-15.md`](campaign_pack_engine_boundary_plan_2026-07-15.md) | `B1-LEDGER`, `B4-PREP-DEPLOYMENT`, `B6-CAMPAIGN-SHARING` | Cross-track ownership boundary and delivery order; retire after direct tracker sources absorb the boundary and all five milestones land. |
| [`v040_post_build_code_review_fix_handoff_2026-07-15.md`](v040_post_build_code_review_fix_handoff_2026-07-15.md) | `B1-CST`, `B1-LEDGER`, `B6-CAMPAIGN-STATUS` | Post-v0.4.0 persistence/campaign-flow repair handoff; retire after the four fixes land and completion-record follow-up is routed. |
| [`band3_implementation_plan_handoff_2026-06-30.md`](band3_implementation_plan_handoff_2026-06-30.md) | Band 3 rows, led by `B3-REQ` | Input to the combined Band 3 plan; remove after direct source wiring or supersession marking. |
| [`feature_dependency_atlas_2026-06-23.md`](feature_dependency_atlas_2026-06-23.md) | `B0-GDD-CONSOLIDATION` | Cross-feature dependency evidence used by the control-plane/GDD reconciliation. |
| [`planning_backlog_2026-06-20.md`](planning_backlog_2026-06-20.md) | `B0-GDD-CONSOLIDATION` | Pre-control-plane queue evidence; classify its unique detail during consolidation. |
| [`registry_nonschema_slices_handoff_2026-07-09.md`](registry_nonschema_slices_handoff_2026-07-09.md) | `B3-STAT-REGISTRY`, `B5-AI-COMPOSITION` | Implementation evidence for those registry rows. |
| [`scope_reframe_and_gdd_stale_audit_plan_2026-06-29.md`](scope_reframe_and_gdd_stale_audit_plan_2026-06-29.md) | `B0-GDD-CONSOLIDATION` | Scope/stale-assumption audit input; classify after the chapter pass. |
| [`stat_breakdown_character_sheet_plan_2026-06-14.md`](stat_breakdown_character_sheet_plan_2026-06-14.md) | `UI-INSPECTION` | Implemented design record retained for inspection-surface detail. |
| [`v0.4.0_review_fix_handoff_2026-07-13.md`](v0.4.0_review_fix_handoff_2026-07-13.md) | `B2-OCCUPANCY` and adjacent Band 2 rows | v0.4 review/fix evidence; reclassify with release closeout. |
| [`v0.4_next_session_handoff_2026-07-13.md`](v0.4_next_session_handoff_2026-07-13.md) | `B2-DATAMANAGER-SEAMS` and adjacent Band 2 rows | v0.4 execution evidence; reclassify with release closeout. |
| [`ai_system_design_vision_2026-06-22.md`](../design/ai_system_design_vision_2026-06-22.md) | `B5-AI-COMPOSITION` | Supporting AI design vision. |
| [`campaign_asset_taxonomy_and_format_2026-07-01.md`](../design/campaign_asset_taxonomy_and_format_2026-07-01.md) | `B6-CAMPAIGN-SHARING` | Supporting campaign-package asset contract. |
| [`campaign_save_expectations_and_foundations_2026-06-23.md`](../design/campaign_save_expectations_and_foundations_2026-06-23.md) | `B1-CST` | Campaign/save framing evidence. |
| [`candidate_systems_2026-06-23.md`](../design/candidate_systems_2026-06-23.md) | `B0-GDD-CONSOLIDATION` | Early feature-scope evidence to reconcile against tracker rows. |
| [`design_review_foundation_fix_todo_2026-06-28.md`](../design/design_review_foundation_fix_todo_2026-06-28.md) | `B0-GDD-CONSOLIDATION` | Cross-foundation review evidence to reconcile against implemented rows. |
| [`difficulty_profile_manifest_contract_2026-06-28.md`](../design/difficulty_profile_manifest_contract_2026-06-28.md) | `B4-DIFFICULTY-DEATHMODE` | Supporting difficulty authoring contract. |
| [`f1_save_schema_manifest_contract_2026-06-28.md`](../design/f1_save_schema_manifest_contract_2026-06-28.md) | `B1-F1` | Source contract for the implemented F1 manifest. |
| [`foundations_end_shapes_2026-06-23.md`](../design/foundations_end_shapes_2026-06-23.md) | Band 2/3 foundation rows, led by `B2-REGISTRY` | Shared end-shape evidence; keep grouped until per-row reconciliation. |
| [`input_mode_architecture_design_2026-06-20.md`](../design/input_mode_architecture_design_2026-06-20.md) | `B6-INPUT` | Supporting input-mode contract. |
| [`items_equipment_unified_model_2026-06-23.md`](../design/items_equipment_unified_model_2026-06-23.md) | `B4-IEQ` | Supporting item/equipment composition contract. |
| [`mouse_only_cursor_mode_design_2026-06-19.md`](../design/mouse_only_cursor_mode_design_2026-06-19.md) | `B6-INPUT` | Implemented input design evidence. |
| [`open_registry_conversion_checklist_2026-06-28.md`](../design/open_registry_conversion_checklist_2026-06-28.md) | `B2-REGISTRY` | Cross-registry conversion evidence. |
| [`player_facing_scope_map_2026-06-23.md`](../design/player_facing_scope_map_2026-06-23.md) | `B0-GDD-CONSOLIDATION` | Scope evidence to reconcile against control-plane rows. |
| [`terrain_more_info_paging_design_2026-06-19.md`](../design/terrain_more_info_paging_design_2026-06-19.md) | `UI-INSPECTION` | Implemented inspection design evidence. |
| [`ui_ux_art_asset_research_2026-07-02.md`](../design/ui_ux_art_asset_research_2026-07-02.md) | `UI-INSPECTION` | Supporting UI asset research. |

## Enforcement Hooks

| Check | Reads | Rule |
|---|---|---|
| Active doc ownership | This manifest, Project Control Plane, Feature Index | Enforced: active plans/design docs need a direct tracker/index link or an entry in the Active Source Ownership Map. |
| Feature owner anchors | Feature Index, numbered GDD headings | Enforced: every feature row links to one or more reachable GDD section fragments. |
| Role separation | This manifest, `GDD_10`, Project Control Plane | `GDD_10` must not duplicate the full control-plane table; the control plane must not become long-form design prose. |
| Generated index discipline | Generated file headers | Generated indexes must be refreshed after active-doc path/header changes. |
