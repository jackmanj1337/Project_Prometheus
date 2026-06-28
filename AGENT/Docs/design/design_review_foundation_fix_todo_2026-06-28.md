---
Type: design
Status: Active - review checklist
Last verified: 2026-06-28
---

# Design Review Foundation Fix Todo

**Started:** 2026-06-28. Created from
[`design_review_unimplemented_systems_2026-06-28.md`](../../Code%20Reviews/design_review_unimplemented_systems_2026-06-28.md).

**Purpose.** This is the management list for review findings where the fix is a
shared foundation system, registry pattern, or cross-feature contract. It does
not change the existing feature plans. It records which follow-up design doc
owns each foundation so the later unified GDD/v1 schedule can size and order
them.

## Shared Foundation Todo

| Finding | Foundation to manage | Managing doc | Fix to schedule later |
|---|---|---|---|
| H1 | F1 save schema manifest | [`f1_save_schema_manifest_contract_2026-06-28.md`](f1_save_schema_manifest_contract_2026-06-28.md) | Create one field-owned schema manifest with scope, reset rule, default, migration, serializer path, and fixture per saved field. |
| H2 | Action/effect primitive contract | [`action_effect_primitive_contract_2026-06-28.md`](action_effect_primitive_contract_2026-06-28.md) | Route MET actions, DLG commands, SAC activations, STY effects, TCV actions, DTR `on_break`, and shop side effects through one mutation context/result contract. |
| H3 | Projection/forecast contract | [`projection_forecast_contract_2026-06-28.md`](projection_forecast_contract_2026-06-28.md) | Keep combat preview, F5 projection, AI valuation, perception filtering, interceptors, and predicate projection terms on one side-effect-free projection path. |
| H4 | Author-facing registry manifest pattern | [`registry_manifest_contract_2026-06-28.md`](registry_manifest_contract_2026-06-28.md) and [`open_registry_conversion_checklist_2026-06-28.md`](open_registry_conversion_checklist_2026-06-28.md) | Replace author-facing closed lists with registries that declare ids, schemas, handlers, composition rules, validation, docs text, and tests. |
| M1 | Resource ledger / cost resolver | [`resource_ledger_cost_resolver_contract_2026-06-28.md`](resource_ledger_cost_resolver_contract_2026-06-28.md) | Use one transaction API for cost preview, affordability, commit, refund, overflow, scope, and partial failure. |
| M2 | `map_objects` component lifecycle | [`map_object_component_contract_2026-06-28.md`](map_object_component_contract_2026-06-28.md) | Make map object types registry-backed component compositions instead of a growing object-type switch. |
| M3 | Occupancy transaction / placement service | [`occupancy_transaction_contract_2026-06-28.md`](occupancy_transaction_contract_2026-06-28.md) | Route spawn, forced movement, carry/drop, hidden overlap, and object-unit placement through one legal occupancy mutation service. |
| M4 | Designer authoring contract | [`designer_authoring_contract_2026-06-28.md`](designer_authoring_contract_2026-06-28.md) | Define the data/editor contract for stable ids, generated forms, validation errors, preview hooks, import/export, and copy/fork/resync support. |
| M5 | Difficulty profile manifest | [`difficulty_profile_manifest_contract_2026-06-28.md`](difficulty_profile_manifest_contract_2026-06-28.md) | Model difficulty as a profile that references content variants, TCV presets, AI overlays, fog/perception rules, economy rates, death-mode offerings, and summary text. |
| M6 | Content pack compatibility and resync | [`content_pack_compatibility_resync_contract_2026-06-28.md`](content_pack_compatibility_resync_contract_2026-06-28.md) | Define provenance, compatibility reporting, and future resync policy for self-contained campaign packs before public authoring. |
| M7 | Death lifecycle funnel and enforcement | [`death_lifecycle_contract_2026-06-28.md`](death_lifecycle_contract_2026-06-28.md) | Make `handle_death(ctx)` and `DeathDisposition` the only death/disposition path once multiple death causes exist. |

## Excluded Findings

| Finding | Reason |
|---|---|
| L1 | STW contradiction is a targeted doc/test-note cleanup, not a shared foundation. |
| L2 | Stale navigation text belongs in the later unified GDD/roadmap cleanup pass. |

## Scheduling Notes

- Do not treat this list as a build schedule. It is a dependency-capture list.
- When a foundation is scheduled, use its managing doc as the implementation
  contract and update the affected GDD/roadmap status in the same commit.
- When a foundation creates a mechanical rule, add the DoD#2 check in the same
  change that ratifies the rule.
- Existing feature registers remain the source for player-facing decisions.
  These docs only define shared architecture needed to implement those decisions
  without duplicate systems.
