---
Type: design
Status: Active - architecture contract
Last verified: 2026-06-28
---

# Difficulty Profile Manifest Contract

**Started:** 2026-06-28. Created from M5 in
[`design_review_unimplemented_systems_2026-06-28.md`](../../Code%20Reviews/design_review_unimplemented_systems_2026-06-28.md).

**Managed by:** [`design_review_foundation_fix_todo_2026-06-28.md`](design_review_foundation_fix_todo_2026-06-28.md).

**Purpose.** This is the registry contract for difficulty. It keeps difficulty
from becoming scattered hardcoded branches across content variants, TCV values,
AI behavior, fog/perception, economy, death mode, and forecast fidelity.

## DifficultyProfile Entry

Each profile declares:
- `id`,
- `label_key`,
- `summary_text_key`,
- `content_variant_bundle`,
- `tcv_preset_bundle`,
- `ai_profile_overlay`,
- `fog_perception_rules`,
- `forecast_fidelity_player`,
- `forecast_fidelity_ai`,
- `resource_rate_modifiers`,
- `shop_price_modifiers`,
- `death_mode_offerings`,
- `save_manifest_refs`,
- `compatibility_notes`.

## Rules

1. Difficulty profiles reference other registries instead of hardcoding
   `normal`, `hard`, or similar branches in feature code.
2. The player-facing summary is authored data generated from the profile.
3. Save data records the selected profile id and any locked options.
4. Mid-campaign changes are either disallowed or routed through explicit
   migration/rebalance rules.
5. Profile overlays must be deterministic and load-validated.

## Required Consumers

- map/content variant selection,
- TCV tuning presets,
- AI profile selection and overlays,
- fog/perception policy,
- projection/forecast fidelity,
- economy/resource rates,
- death-mode menu,
- save/load and campaign summary UI.

## Validation

DataManager should validate:
- referenced variant bundles exist,
- TCV presets match declared variable types,
- AI overlays reference registered profile ids,
- forecast fidelity values are allowed by the projection contract,
- resource modifiers reference registered resources,
- death-mode choices reference registered rules,
- summary text is present.

## Test Obligations

Tests should cover:
- profile load validation,
- two profiles producing different TCV/resource/fog settings through data only,
- player summary generated from profile metadata,
- save/load of selected profile id,
- unknown referenced registry id failure.
