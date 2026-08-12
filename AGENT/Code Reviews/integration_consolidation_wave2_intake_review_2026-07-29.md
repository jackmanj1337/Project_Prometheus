# Integration Consolidation Wave 2 — Campaign Research Intake Review

**Status:** Accepted consolidation evidence
**Reviewed:** 2026-07-29
**Source:** `agent/from-integration/campaign-data-research`
**Target base:** `agent/integration` at `b371f35ed993e193918a80a708b8d832c7263cf9`

## Verdict

Recover the eleven final research/decision documents below, union their still-valid
cross-references into current registers, and omit the source branch's historical
session churn, documentation relocation, obsolete handoffs, generated files, and
older copies of current control documents. The 84-commit branch must not be merged.

## Recovered source manifest

| Recovered file | Final source commit |
|---|---|
| `design/campaign_backup_content_addressed_format_2026-07-25.md` | `219108ad42cbcbbf8d1adb35f07b7a7d33aa9274` |
| `design/campaign_library_owner_questions_2026-07-23.md` | `27be6e693a5a879a1216975ccc89af778f378b4a` |
| `design/campaign_library_ux_decisions_2026-07-24.md` | `f749ef43636c1d98f2fb079ee929e3cf4d04fc25` |
| `design/campaign_library_ux_research_2026-07-23.md` | `134710f28361b6c90c9f1a547b4103cbd9cc5bdb` |
| `design/ios_native_target_feasibility_2026-07-25.md` | `219108ad42cbcbbf8d1adb35f07b7a7d33aa9274` |
| `design/prep_economy_bundle_comparative_research_and_questions_2026-07-25.md` | `c1c3912e20794decc0ac9451d20d6655bdb3c774` |
| `design/text_entry_layout_implementation_research_2026-07-26.md` | `e132411251c568613da719784561eb8ae078ff6a` |
| `design/text_entry_naming_and_sanitization_2026-07-26.md` | `e132411251c568613da719784561eb8ae078ff6a` |
| `design/text_entry_strategy_research_and_questions_2026-07-26.md` | `e132411251c568613da719784561eb8ae078ff6a` |
| `design/ui_ux_architecture_research_and_questions_2026-07-24.md` | `9e6fd9027c6f3f3e4e113aa16e2aad209b38cd7a` |
| `design/ui_ux_interaction_vocabulary_2026-07-24.md` | `19955ae5a5fae4eb2691ebb081db3566fd9459f1` |

Paths in the table are relative to `AGENT/Docs/`. Each recovered file is the exact
final blob from the source tip. Current ownership is recorded in
`plans/doc_role_manifest_2026-06-29.md`.

## Omitted-source classification

This classification is exhaustive over
`git diff --name-only agent/integration...agent/from-integration/campaign-data-research`.
The rules are mutually ordered as written; the recovered manifest above is removed
first.

1. **Generated:** `AGENT/Docs/INDEX.md`, `AGENT/Docs/REGISTERS.md`, and
   `AGENT/Session Notes/INDEX.md`. Regenerate the Docs indexes and union only the
   current consolidation note into the session index.
2. **Historical-only notes:** every remaining `AGENT/Session Notes/**` source path.
   They narrate iterative question walks and claim source-only commits; the final
   accepted decisions are preserved in the recovered documents. Importing 29 old
   date-only notes would create filename collisions without adding active authority.
3. **Documentation-cleanup experiment:** every changed path below
   `AGENT/Docs/archive/**` or `AGENT/GDD/Content Expansion/**`, plus
   `AGENT/Docs/handoff_container_tooling_goal_2026-07-17.md`,
   `AGENT/GDD/Play_tester_comments.md`, `AGENT/Docs/documentation_review_2026-07-15.md`,
   `AGENT/GDD/gdd_update_reference_2026-06-12.md`, both documentation-lifecycle
   files, and `AGENT/Review Procedures/00_Master_Review_Procedure.md`. This broad
   relocation was not part of the accepted product consolidation and would delete
   evidence or rewrite live navigation.
4. **Already present exactly:** `AGENTS.md`, `GDD_Feature_Index.md`, and the plans
   for Band 5 conditions, class EXP/PXP, F1 save schema, FE schema handoff, formula
   registries, multi-owner economy, pack-associated saves, rule profiles, and the
   zero-content engine. Blob comparison against current integration is exact.
5. **Superseded handoffs:** the campaign-data research/planning handoffs,
   campaign-library research handoff, UI/UX research-goal handoff, and both
   zero-content-blocker handoffs. Their questions were answered and their durable
   results are now in the recovered decision/research documents or already-present
   implementation plans.
6. **Current files win:** the full-review rollup, manual playbook, Awakening plan,
   campaign-data findings, campaign-save follow-up, Project Control Plane, GDD 00,
   and GDD 10. Source copies contain old release queues, old paths, or omit later
   v0.5.8/Wave 1 decisions. No unique current decision was found in their source
   diff beyond links handled elsewhere.
7. **Semantic union:** `doc_role_manifest_2026-06-29.md` receives ownership rows
   for all eleven recovered sources. The convoy, forging, prep-hub, shop, and
   training registers receive only the still-valid EPUX cross-reference blocks;
   their newer dialogue/custody amendments remain intact.

The categories above account for every changed source path. A final name-status
comparison plus generated-index, documentation, claim, and full-suite gates is
required before this review is closed.
