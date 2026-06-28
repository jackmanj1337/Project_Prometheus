---
Type: design
Status: Active - architecture contract
Last verified: 2026-06-28
---

# F1 Save Schema Lock Design

**Started:** 2026-06-28. Phase B design document for the F1 save-schema lock.

**Inputs.**
- [`f1_schema_source_inventory_2026-06-28.md`](../plans/f1_schema_source_inventory_2026-06-28.md)
- [`f1_save_schema_manifest_contract_2026-06-28.md`](f1_save_schema_manifest_contract_2026-06-28.md)
- [`campaign_save_technical_plan_2026-06-21.md`](../plans/campaign_save_technical_plan_2026-06-21.md)
- [`feature_dependency_atlas_2026-06-23.md`](../plans/feature_dependency_atlas_2026-06-23.md)

**Purpose.** This document defines the target shape of the F1 schema lock. It
does not implement save/load. It gives the later build a concrete schema
boundary, field-bucket layout, fixture obligations, and open decisions that
must be closed before code starts reserving fields ad hoc.

## Lock Goals

F1 is locked when:

1. Every planned persistent, runtime, suspend, and explicit no-save field has a
   manifest row.
2. Retry, persistent save, and suspend share the JSON-safe codec contract.
3. Feature builds can add concrete fields only by updating the manifest.
4. Runtime state is split cleanly from authoring data and derived state.
5. Load defaults are explicit even before 1.0 migration support exists.
6. Tests prove the field class behavior: campaign carry, map reset, Retry,
   suspend, old-save defaults, and reference validation.

## Schema Model

Use one top-level save document with stable sections. Exact key spelling can be
finalized in the manifest, but the section ownership should not drift.

```text
SaveData
  format_version
  save_label
  integrity
  header
  campaign
  party
  roster
  map_runtime
  suspend
```

### `campaign`

Campaign-level state that survives map completion.

Expected buckets:
- `campaign_id`, `node_id`, `cleared_nodes`
- `rules`
- `profile_selections`
- `difficulty`
- `death_mode`
- `campaign_vars`
- `campaign_flags`
- `relationship_graph`
- `key_item_custody`
- optional `pvp`

Authoring definitions are not copied here. Store ids and player/runtime choices.

### `party`

Roster-level inventory/economy state.

Expected buckets:
- `resources` (`party_gold` evolves into resource-keyed wallet)
- `convoy` / party items
- `bonus_exp`
- optional `training_purchase_counts`
- future campaign-level pool/wallet state

Prep-panel transactions commit here immediately. Do not serialize transient PHB
panel UI.

### `roster`

Persistent unit records for campaign units.

Expected per-unit buckets:
- identity, class, level, EXP, faction/roster status
- avatar/main-character fields
- inventory entries and equipment/source pointers
- `proficiency_xp`
- learned/equipped skills, granted skills, learned/equipped styles
- persistent source/style charge state
- `extra_stats`
- persistent cap modifiers
- battalion attachment refs
- per-unit groups/tags if runtime mutable

Class-skill availability, held/class-derived cap modifiers, authored stat
definitions, and item definitions are derived/authoring data and are not stored
as roster fields.

### `map_runtime`

Mutable state for the active map. Null for between-map saves.

Expected buckets:
- `map_id`, turn/phase/faction cursor when active
- live unit runtime state and positions
- `unit_states`
- `map_vars` and map flags
- `map_events_fired`
- `map_objects_state`
- `discovered_units`
- AI wake/latch state
- map-scope relationship overrides
- dropped-item stash
- pair/carry registry state
- active conditions and map-duration modifiers
- per-map item/source/style/pool counters
- action/rate-limit counters needed for mid-turn suspend

Map runtime clears on normal map completion unless a feature explicitly promotes
state into `campaign`, `party`, or `roster`.

### `suspend`

Resume-only state for in-progress play. Null for normal between-map saves.

Expected buckets:
- suspend kind: map, dialogue, or prep if prep ever needs explicit resume
- cursor tile and active UI/gameplay mode needed to resume safely
- threat-range `_watch_set` and `_danger_mode`
- RNG seed/history summary
- `conversation_resume`
- any deferred safe-point action state

The suspend block must not become a second campaign state store. It references
campaign/party/roster/map runtime fields and stores only what is needed to
resume an interrupted session.

## Recommended Decisions

These settle the inventory items that were still marked "decide in lock."

| Topic | Recommendation |
|---|---|
| Active conditions across maps | Default to map/suspend state. Allow cross-map persistence only when F5 condition data explicitly declares it; if so, store that condition in the roster unit record with the same condition instance shape. |
| Action/rate-limit counters | Mid-turn suspend is in scope, so reserve transient counters in `map_runtime` and restore them on suspend/load. They still clear at faction refresh/map reset. |
| PvP campaign fields | Reserve an optional `campaign.pvp` block with default `null`. This keeps the schema open without forcing the PvP build into v1. |
| `conversations_seen` | Do not reserve a separate field yet. One-time conversations invoked through MET ride `map_events_fired`; add `conversations_seen` only if direct non-MET conversation invocation becomes v1. |
| Machine-readable manifest | Start with a Markdown manifest table using the inventory template. Promote to JSON/YAML only when automated manifest checks need structured input. |
| `map_runtime` vs `suspend` ownership | Runtime facts live in `map_runtime`; resume cursor/UI facts live in `suspend`. Avoid duplicating the same value in both. |

## Manifest Work Product

The F1 lock should create or extend a manifest table with one row per field
family. The row shape is defined in
[`f1_schema_source_inventory_2026-06-28.md`](../plans/f1_schema_source_inventory_2026-06-28.md).

The first manifest should contain:
- every row in the source inventory,
- every explicit no-save decision,
- a proposed field path,
- the required fixtures for that row,
- the owner register/doc,
- whether the row is v1, optional dormant reserve, or post-v1 deferred.

## Serializer Design

The codec follows `[CST-2]`: one JSON-safe serializer serves both Retry and
persistent save.

Required serializer rules:
- write JSON primitives only,
- normalize vectors to arrays or typed dicts,
- serialize resources by ids and state, not object references,
- fail with structured errors for unresolved ids,
- apply defaults in one place,
- keep field-version handling near the codec,
- expose pure `to_dict` / `from_dict` seams for headless tests.

Feature adapters may own their field-specific conversion, but the main
`SaveCodec` remains the only path into and out of save data.

## Validation Rules

At load:
- unknown `format_version` follows the loader policy,
- unknown registry ids fail with structured errors unless the field declares a
  safe fallback,
- map-runtime ids must resolve against the active campaign/map content pack,
- no authoring data is required to be copied into saves except by id/reference,
- absent fields use documented defaults only.

At author-data load:
- object ids, unit ids, event ids, variable ids, condition ids, profile ids, and
  registry refs must be stable enough for saved references.

## Fixture Obligations

Every manifest row selects fixture ids from the source inventory matrix.

Minimum test set for the F1 build:
- `test_save_codec_unit_roundtrip`
- `test_save_codec_inventory_entry_roundtrip`
- `test_save_data_campaign_roundtrip`
- `test_save_data_old_save_defaults`
- `test_retry_uses_save_codec`
- `test_suspend_map_runtime_roundtrip`
- `test_map_runtime_resets_on_completion`
- `test_reference_validation_unknown_ids`
- `test_no_save_derived_fields`

Feature rows add targeted fixtures when their build lands.

## Build Slices

This is the preferred build order once Package A / RNG sequencing allows F1
execution.

1. **Manifest lock.** Create the first complete Markdown manifest from the
   inventory, assign field paths, mark v1/dormant/deferred rows.
2. **Codec foundation.** Build `SaveCodec` and move Retry unit/inventory
   snapshots onto JSON-safe primitives.
3. **Campaign envelope.** Build SaveData, SaveManager file I/O, integrity,
   campaign graph, CampaignRules consolidation, and defaults.
4. **Roster/party state.** Add roster, inventory, proficiency, skills, sources,
   styles, resources, and extra-stats serialization.
5. **Map runtime.** Add map events, map objects, live units, AI wake, fog memory,
   relationship overrides, conditions, carry/pair state, counters, and dropped
   items.
6. **Suspend.** Add active map suspend and conversation resume state.
7. **Validation and guards.** Add manifest completeness checks and reference
   validation once field paths stabilize.

## DoD

F1 lock implementation is not done until:
- the manifest row exists for every saved field,
- explicit no-save rows exist for derived/authoring/session-only decisions,
- all row fixtures either pass or are marked deferred with the feature owner,
- GDD_01/GDD_07/GDD_10 are updated in the same behavior-changing commit,
- DoD#2 checks enforce any mechanical manifest rules ratified by the build.

## Open Risks

- The manifest can become too large for Markdown. If row ownership becomes hard
  to check, promote it to a machine-readable file before Phase C feature builds.
- `map_runtime` could become a dumping ground. Keep owner/source/fixture columns
  mandatory.
- Cross-map condition persistence needs a clear F5 registry flag before any
  feature relies on it.
- Optional PvP fields should remain dormant unless the v1 scope triage keeps PvP
  in scope.
