---
Role: dated
Type: design
Status: Active - architecture contract
Last verified: 2026-06-28
---

# Designer Authoring Contract

**Started:** 2026-06-28. Created from M4 in
[`design_review_unimplemented_systems_2026-06-28.md`](../../Code%20Reviews/design_review_unimplemented_systems_2026-06-28.md).

**Managed by:** [`design_review_foundation_fix_todo_2026-06-28.md`](design_review_foundation_fix_todo_2026-06-28.md).

**Purpose.** This is the thin shared contract for eventual campaign-builder and
designer-facing tooling. It records what feature schemas must provide so the
editor can generate safe UI instead of exposing unstable nested dictionaries.

## Authoring Guarantees

Feature schemas should provide:
- stable ids for all authored entities,
- registry manifests for growable vocabularies,
- parameter schemas with labels, help text, defaults, and constraints,
- structured validation errors with path, code, message, and suggested fix,
- preview/test hooks for actions, costs, predicates, projections, and panels,
- import/export metadata,
- copy/fork/resync provenance,
- schema version and migration behavior.

## Editor-Facing Shape

The future editor should be able to generate:
- forms from registry schemas,
- dropdowns from registry ids,
- safe predicate/action builders from declared subjects and params,
- preview buttons from projection and cost contracts,
- validation reports grouped by file/object/path,
- diff/resync summaries for copied default content.

## Schema Rules

1. Data shape must be stable enough for saved campaigns and editor links.
2. Author-facing strings use text ids where localization or reuse matters.
3. Registries declare docs/help text near their schema.
4. Validation errors should be deterministic and machine-readable.
5. Engine-only internals stay hidden from authoring data.
6. Generated editor forms should not require arbitrary GDScript editing.

## Required Cross-Contract Links

The authoring contract relies on:
- registry manifest metadata,
- F1 schema manifest ownership,
- action/effect primitive schemas,
- projection hooks for previews,
- resource ledger cost quotes,
- map object component schemas,
- content-pack compatibility metadata.

## Deferred Scope

This doc does not design the full GUI. It sets the data contract that keeps the
GUI feasible when public authoring becomes a build target.

## Test / Validation Obligations

When implemented, add validation coverage for:
- generated form metadata present for each public registry,
- structured validation errors for bad ids and bad params,
- preview hooks available for previewable actions/costs/predicates,
- copy/fork provenance retained on exported packs,
- schema version present on public authoring files.
