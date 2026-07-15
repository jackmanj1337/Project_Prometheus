---
Type: design
Status: Active - architecture contract
Last verified: 2026-06-28
---

# Content Pack Compatibility / Resync Contract

**Started:** 2026-06-28. Created from M6 in
[`design_review_unimplemented_systems_2026-06-28.md`](../../Code%20Reviews/design_review_unimplemented_systems_2026-06-28.md).

**Managed by:** [`design_review_foundation_fix_todo_2026-06-28.md`](design_review_foundation_fix_todo_2026-06-28.md).

**Purpose.** This is the future public-authoring compatibility contract for
self-contained campaign packs. It keeps copied default content, forked packs,
schema versions, and support reports traceable without changing the runtime
decision that packs are self-contained.

## Pack Provenance

Each pack should report:
- pack id and version,
- engine schema version,
- source template/default-content version,
- fork timestamp,
- author id/name metadata,
- imported dependency list if any,
- migration history,
- compatibility warning list.

## Compatibility Report

The loader or editor should be able to produce:
- schema version compatibility,
- missing registry ids,
- stale copied default resources,
- changed default-content source ids,
- migration defaults applied,
- unsupported primitive ids,
- optional resync suggestions.

Runtime may still load valid self-contained packs without central patch
propagation. The public authoring tool should make stale or incompatible copies
visible.

## Resync Policy

Future resync from defaults should:
- compare copied resources by stable id and provenance,
- show three-way changes when possible,
- preserve author edits by default,
- allow accepting default fixes per resource/field,
- record resync history in pack metadata,
- never silently overwrite authored content.

## Release Gate

This does not block gameplay v1 unless public authoring ships with v1. It should
be a gate before broad campaign-builder/public-authoring release, because
supporting user packs without provenance will be expensive.

## Cross-Contract Links

This contract depends on:
- designer authoring metadata,
- registry manifest versions,
- F1 schema versions and migration defaults,
- content overlay/import rules,
- validation error shape.

## Test Obligations

Tests should cover:
- pack provenance preserved through copy/export,
- stale default-content warning emitted,
- unsupported schema version reported,
- missing registry id reported with path,
- resync suggestion does not mutate content until accepted.
