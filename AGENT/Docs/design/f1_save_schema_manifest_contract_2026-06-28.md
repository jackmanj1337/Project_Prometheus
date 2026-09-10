---
Type: design
Status: Active - architecture contract
Last verified: 2026-09-10
---

# F1 Save Schema Manifest Contract

**Started:** 2026-06-28. Created from H1 in
[`design_review_unimplemented_systems_2026-06-28.md`](../../Code%20Reviews/design_review_unimplemented_systems_2026-06-28.md).

**Managed by:** [`design_review_foundation_fix_todo_2026-06-28.md`](design_review_foundation_fix_todo_2026-06-28.md).

**Lock design:** [`f1_save_schema_lock_design_2026-06-28.md`](f1_save_schema_lock_design_2026-06-28.md).

**Source inventory:** [`../plans/f1_schema_source_inventory_2026-06-28.md`](../plans/f1_schema_source_inventory_2026-06-28.md).

**Concrete manifest plan:** [`../plans/f1_save_schema_manifest_2026-07-06.md`](../plans/f1_save_schema_manifest_2026-07-06.md).

**Purpose.** This is the master build document shape for F1. It turns the
Phase B save-schema reserve list into a field-owned manifest before features
start adding persistent state independently.

## Contract

Every saved field needs a manifest row before implementation consumes it.

Required row fields:
- `field_path`: JSON path or resource path used by the serializer.
- `owner`: feature/register that owns the field.
- `scope`: one of the scope names in the source inventory glossary
  (`campaign`, `campaign_rules`, `roster_unit`, `party_inventory`,
  `map_runtime`, `object_runtime`, `unit_runtime`, `transient_suspend`,
  `settings`, `authoring_data`, or `derived`).
- `lifetime`: when the value is created, reset, carried forward, or deleted.
- `default`: migration-safe default for old saves.
- `migration_rule`: what happens when loading a save without the field.
- `serializer`: code path that writes and reads the field.
- `fixture`: test fixture that proves round-trip behavior.
- `authoring_source`: map data, campaign data, runtime event, player choice, or
  generated state.
- `retry_behavior`: whether Retry restores, recomputes, or clears the field.
- `row_status`: `v1`, `dormant_reserve`, `post_v1_deferred`, or
  `explicit_no_save`.

## Required Consumers

The manifest must cover at least:
- campaign identity, route, flags, and typed variables,
- map latches, objectives, event state, and object state,
- per-unit inventory, equipment, proficiency, conditions, skills, styles, and
  extension stats,
- party wallets, per-unit pools, shop purchase counts, battalion state, and
  training state,
- dialogue resume state and relationship overrides,
- difficulty/death-mode selections and CampaignRules profile ids,
- suspend-only transient state that should not survive normal map completion.

## Invariants

1. Retry and persistent save use the same JSON-safe serializer.
2. A feature may not add a saved field without a manifest row.
3. Reset behavior is explicit; no field is "whatever the old code does."
4. Migration defaults are data, not comments hidden in loader branches.
5. Object, unit, and map ids are stable enough for save references.
6. Tests prove old-save defaults, save/load round trip, and Retry behavior for
   every new scope class.
7. Cross-pack-version migration is explicit and copy-on-write: source saves are immutable,
   destination identity is applied only to a fully validated candidate, and failure commits nothing.
8. Pack-authored migration is declarative data, never executable pack code.

## Pack-version migration boundary

The v1 migration surface is deliberately bounded: one destination pack version may declare a
deterministic, complete same-id migration chain from named earlier versions. Stable ids pass through
unchanged; explicit aliases cover saved references that were renamed. Every referenced id and
progression position must resolve under the destination before commit. Removed/ambiguous references,
incompatible topology, unsupported save schema, and incomplete declarations produce a diagnostic and
preserve the source save. The engine's chain planner is deterministic and only follows complete,
allow-listed declarative edges; it never guesses a path.

The declaration model reserves `source_package_id` as well as `source_package_version`. v1 validation
requires the source and destination package ids to match. A future policy may lift that restriction so
a pack can accept a direct migration from any named pack/version with sufficient declarations; cross-
package migration and automatic newest-version selection remain outside v1. This implementation
extension was landed and covered on 2026-08-27; it does not change the no-pack-scripts rule.

## Build Notes

- The first implementation may be prose plus fixtures, but it should become
  machine-readable once migration checks need automation.
- Feature docs can link to their manifest rows rather than restating save
  behavior.
- DataManager validation should reject authored ids that would create unstable
  save paths.

## DoD#2 Hooks

When ratified mechanically, add checks that:
- every manifest row has owner, scope, default, migration rule, serializer, and
  fixture,
- every serializer-owned field has a manifest row,
- no feature saves ad hoc dictionaries outside the approved scopes,
- generated docs/indexes stay updated when the manifest doc moves or changes
  header metadata.
