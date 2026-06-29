---
Type: design
Status: Active - architecture contract
Last verified: 2026-06-29
---

# Registry Manifest Contract

**Started:** 2026-06-28. Created from H4 in
[`design_review_unimplemented_systems_2026-06-28.md`](../../Code%20Reviews/design_review_unimplemented_systems_2026-06-28.md).

**Managed by:** [`design_review_foundation_fix_todo_2026-06-28.md`](design_review_foundation_fix_todo_2026-06-28.md).

**Companion checklist:** [`open_registry_conversion_checklist_2026-06-28.md`](open_registry_conversion_checklist_2026-06-28.md).

**Purpose.** This is the shared contract for author-facing registries. It
defines what every registry entry must declare so content growth does not
require new enum values, hardcoded const lists, or `match` branches.

## Registry Entry Shape

Every author-facing registry entry should declare:
- `id`: stable authored id.
- `label_key`: text indirection id for UI.
- `owner_feature`: feature/register that owns the entry family.
- `version`: schema version for migration and compatibility reporting.
- `kind`: entry type when the registry supports multiple families.
- `primitive_handler`: engine primitive id or composition id.
- `params_schema`: allowed parameters, defaults, and type checks.
- `subjects`: expected actor, target, object, item/source, tile, event, or
  variable bindings.
- `composition`: optional data-defined composition over approved primitives.
- `projection_support`: whether the entry supports preview/forecast.
- `save_fields`: F1 manifest refs touched by this entry.
- `docs_text`: author-facing help string or docs id.
- `test_fixture`: representative fixture or validation case.

## Required Registry Families

The H4 checklist names the known candidates:
- objective conditions,
- AI profiles,
- map object types,
- tile action providers,
- MET triggers and actions,
- dialogue commands and visual effects,
- source/style effect kinds,
- target filters,
- AoE/shape generators,
- condition data and condition effect primitives,
- F16 predicates, terms, and operators,
- stat names,
- movement types and vulnerability groups,
- resource types and cost scopes,
- proficiency tracks and rank profiles,
- skill/item/source effect handlers,
- activity/panel/mini-game types,
- difficulty profiles.

## Registry Loader Rules

1. Load built-in primitive handlers first.
2. Load campaign registry entries second.
3. Validate entry ids, schemas, subject bindings, handler references, and
   composition depth.
4. Reject unknown ids at load time where possible.
5. Sort deterministic output by explicit priority, then stable id.
6. Surface structured errors usable by a future editor.

## Closed-List Exception

Closed enums remain acceptable for engine-only state that authors cannot extend,
such as internal input modes, display options, and private turn-state rows. The
registry rule applies when new campaign content would otherwise require an
engine edit.

## DoD#2 Hooks

When the registry foundation becomes mechanical, add checks that:
- author-facing vocabularies use registry validation, not fixed valid-value
  arrays,
- each registry entry has handler/schema metadata,
- compositions reference known primitives,
- docs/indexes include new live registry docs,
- tests cover unknown ids and one data-defined entry for each registry family.
