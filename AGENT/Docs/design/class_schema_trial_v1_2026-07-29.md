---
Type: design
Status: Trial contract — implementation validation required before v1 freeze
Last verified: 2026-07-29
Tracker: CLASS-SCHEMA-TRIAL-V1-2026-07-29
---

# Class package schema trial v1

**Managed by:** [`project_control_plane_2026-06-29.md`](../plans/project_control_plane_2026-06-29.md)

## Purpose and freeze boundary

This contract is precise enough to build validators, adapters, and small package
fixtures for the class/provenance/advancement vertical slice. It is deliberately
named `trial-v1`: implementation may expose a defect, but changes must update the
contract and every fixture together. Bulk content transcription must wait until the
trial passes and the registry is promoted to content schema version 1.

The engine-owned declarative registry remains canonical. The machine-readable
projection is `test_fixtures/schema_trial/trial_v1/schema_registry.json`. The sample
packs are conformance inputs, not shipped content.

## Common document envelope

Every catalogue document is a JSON object with these required fields:

| Field | Type | Rule |
|---|---|---|
| `kind` | nonempty string | Must equal the catalogue entry's registered kind. |
| `schema_version` | integer | Must be `1` for this trial. |
| `id` | nonempty string | Unique within `(kind, package)`; lowercase snake case. |
| `display_name` | nonempty string | Author-facing label. |
| `source_refs` | nonempty array of unique strings | Every id resolves in the package source registry. |
| `occurrence_audit_refs` | array of unique strings | Defaults to `[]`; every id resolves in the occurrence-audit registry. |

Unknown fields fail. `null` never means “use the default”: omit an optional field.
Defaults are applied only after validation and are part of the schema version.
Document identity, schema fields, and provenance fields cannot be overridden.

## Package and catalogue projection

The trial manifest requires `package_id`, `package_version`,
`content_schema_version`, `display_name`, `completion_status`, `default_enabled`,
`catalogue_path`, `source_registry_path`, and `occurrence_audit_path`.
`completion_status` is `draft` or `complete`; `default_enabled` is independent.

Each catalogue entry requires `kind`, `id`, `path`, and `schema_version`. Paths are
safe package-relative JSON paths. The entry identity and schema version must equal
the loaded document. Duplicate identities, duplicate/case-colliding paths, unindexed
identity documents, and unknown kinds fail before adaptation.

## Source and occurrence registries

`source_registry` is one identity document whose `sources` object is keyed by stable
source id. Each record requires `locator`, `title`, `attribution`, `rights_status`,
and `verified_at`; optional `notes` and `content_hash` are strings. The key is the
source id; records do not repeat `source_id`.

`occurrence_audit` owns an `occurrences` object keyed by stable occurrence id. Each
record requires `source_ref`, `document_ref` (`kind:id`), JSON Pointer `field_path`,
`source_locator_detail`, `literal_value`, `interpretation`, and `decision_state`.
`decision_state` is `transformed`, `disputed`, `conflicting`, or `ambiguous`.
References must resolve, and `field_path` must exist in the target document.

Missing `source_refs`, dangling source references, missing required occurrence
coverage, and dangling occurrence references use distinct errors:
`provenance_document_missing`, `provenance_source_unresolved`,
`provenance_occurrence_missing`, and `provenance_occurrence_unresolved`.

## Class document

The class schema admits the common envelope plus the established `ClassData` fields
listed by the machine-readable registry. Required class mechanics are `tier`,
`max_level`, `base_movement`, `internal_level_rule`, `weapon_wexp_bases`,
`weapon_wexp_caps`, `player_growth_rates`, `enemy_growth_rates`, `stat_caps`, and
`advancement_edge_refs`. All other admitted fields have explicit defaults.

Stat maps use registered stat ids and integer values. Growth rates are integers
greater than or equal to zero. Caps and base stats are nonnegative integers. WEXP
maps use registered track ids and nonnegative integers, with each base less than or
equal to its cap. `skill_unlocks` keys are decimal level strings and values are skill
ids. Reference arrays contain unique registered ids.

### Class variants

`variants` defaults to `[]`. Each variant requires:

```json
{
  "variant_id": "female",
  "eligibility": {
    "handler_id": "fact_contains_v1",
    "schema_version": 1,
    "parameters": {"fact_id": "sex", "value": "female"}
  },
  "overrides": {"stat_caps": {"speed": 30}}
}
```

Only these class-owned fields may be overridden in trial v1: base-stat fields,
`base_movement`, `base_constitution`, `base_line_of_sight`, `weapon_wexp_bases`,
`weapon_wexp_caps`, `allowed_weapon_families`, `class_groups`, `special_qualities`,
`vulnerability_groups`, `player_growth_rates`, `enemy_growth_rates`, `stat_caps`,
`skill_unlocks`, `sprite_id`, and `default_movement_profile_id`.

Variant ids are unique within the class. A variant cannot override `id`, `kind`,
`schema_version`, display metadata, provenance, tier, level rules, availability,
advancement references, or other variants. Overrides replace the complete value of
the named field; there is no recursive merge.

## Advancement edge document

An `advancement_edge` requires `source_class_ref`, one nonempty
`destination_class_refs` array, `route_refs`, `transition`, `stat_gains`,
`weapon_wexp_grants`, and `variants`. A fixed edge has one destination; a branching
edge has more than one. Both use the same schema and commit path.

`transition` is a trusted descriptor with exactly `handler_id`, `schema_version`, and
`parameters`. Trial v1 uses `class_advancement_v1`. Edge variants have the same
shape as class variants but may override only `destination_class_refs`, `stat_gains`,
`weapon_wexp_grants`, and `operations`. An optional `selected_class_variant_id`
selects a destination variant after eligibility validation.

## Advancement route document

A route requires one `trigger`, zero or more ordered `requirements`, one `cost`, one
`selection`, one `transition`, and integer `priority`. Every executable descriptor
uses the single shape `{handler_id, schema_version, parameters}`. This resolves the
earlier `handler`/`formula_id`/`id` naming conflict for this slice.

Descriptors are validated against trusted engine registries before any preview.
Unknown ids, versions, or parameters fail. Requirements preserve authored array
order. Eligible routes sort by descending priority then route id. Preview, failed,
and cancelled transitions mutate nothing; commit records route, edge, destination,
and selected variant ids.

## Durable state reserved by the trial

The save projection stores nullable `class_variant_id` and
`advancement_edge_variant_id` alongside `class_id`. Omitted legacy values migrate to
`null`, meaning the unvaried base entity. Unknown, ineligible, or cross-package ids
fail restore after package resolution. Progression pressure is intentionally outside
this class-schema trial and will be added by its separately tracked slice.

## Implementation exit before freeze

The schema may be promoted from `trial-v1` to content schema version 1 only after:

1. both valid sample packs pass the Godot validator and runtime adapter;
2. the invalid pack returns every error in `expected_errors.json` at the exact path;
3. fixed and branching advancement preview and commit share one code path;
4. cancellation and validation failure leave unit, inventory, and event state equal;
5. selected variants round-trip through save, suspend, Retry, and Rewind fixtures;
6. generated reference documentation and validator parity tests agree; and
7. an authoring review confirms the provenance records remain readable after an
   entity is split or renamed.
