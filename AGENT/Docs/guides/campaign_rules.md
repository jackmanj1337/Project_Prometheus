# Campaign Rules

**Last verified:** 2026-07-13
**See also:** `GDD_01_Runtime_Contracts.md` §CampaignRules Contract;
`scripts/resources/CampaignRules.gd`

This file is the evergreen reference for campaign-level gameplay rules chosen at
`New Game` and carried by the current save/runtime state.

Use it together with:

1. `AGENT/GDD/GDD_02_Core_Mechanics.md`
2. `AGENT/GDD/GDD_03_Units_Classes.md`
3. `AGENT/GDD/GDD_01_Runtime_Contracts.md`

## Current rule set

The current New Game flow exposes these gameplay rule toggles:

- `permadeath_enabled`
- `auto_promote_at_max_level`
- `leveling_method`
- `pair_up_enabled`

Map selection travels through the same launch flow, but it is launch state, not
itself a campaign rule.

These values are written into `GameState.campaign_rules` before the map starts.
They are not global app settings.

If this distinction is ignored, the likely bug is rules leaking between saves or
being treated as user preferences instead of save-specific gameplay state.

## Current `CampaignRules` fields

The live campaign-rule fields are:

- `permadeath_enabled: bool`
- `leveling_method: String`
- `auto_promote_at_max_level: bool`
- `pair_up_enabled: bool`
- `max_skills: int`
- `max_inventory: int`
- `exp_gaining_factions: Array[String]`
- `hit_formula: String`
- `rewind_charges_per_map: int`

The current launch-routing fields that travel with New Game setup are:

- `next_map_data_path: String`
- `next_map_roster_policy: String`
- `next_map_roster_source: String`

The rule object and launch-routing fields are serialized through the save/runtime
contracts; authored profile selection and several later consumers remain planned.

## Rule meanings

### `permadeath_enabled`

- `false`: defeated allied units are not permanently removed
- `true`: defeated allied units are treated as lost for the run

This rule affects progression expectations, roster continuity, and future save
ownership. It should stay explicit in save data.

### `leveling_method`

Current documented values:

- `growth_random`
- `growth_fixed`

This is a save-level gameplay rule, not a graphics/input preference.

### `auto_promote_at_max_level`

- `false`: reaching cap does not immediately open the promotion flow
- `true`: promotable units can trigger the promotion flow automatically after
  the level-up finishes

This changes the live progression loop and should be validated whenever level-up
or promotion behavior changes.

### `pair_up_enabled`

- `false`: Pair Up actions should not appear or execute
- `true`: `Pair Up`, `Swap`, and `Separate` are available when normal action
  requirements are met

This is a campaign rule, not a per-map gimmick flag.

## Rules that are campaign-level by design

The design direction already locked in the project docs is:

- `pair_up`
- `support`
- `rescue`

These should be treated as campaign rules. They should not be introduced as
ad-hoc one-off map flags unless a future mode deliberately overrides the base
ruleset.

Important current-state note:

- Pair Up is implemented and exposed today.
- Support and Rescue are not the current shipped player-facing systems yet, but
  their eventual ownership is already treated as campaign-level.

Why:

- they affect save ownership
- they change balancing and content value
- they need clear UX in New Game or prep/deployment flow

## Current locked guidance

The strongest currently locked guidance is:

- campaign rules are chosen at `New Game`
- campaign rules remain stable for the life of that save unless a migration
  feature is built deliberately
- campaign saves should store rule flags explicitly
- Pair Up and Rescue should be treated as mutually exclusive until a combined
  ruleset is designed and tested
- support-related long-term data should be versioned separately from transient
  map runtime state

Those rules come from the 2026-05-25 campaign-rules decision pass and should be
kept here instead of relying on a dated note for day-to-day onboarding.

## What is not a campaign rule

Do not confuse these with campaign rules:

- mouse-control preference
- global settings in `SettingsManager`
- per-map authored factions/objectives
- per-map roster content

Those affect UX or map content, not the save's gameplay ruleset.

## Developer guidance

When adding a new long-term gameplay toggle, ask:

1. Does this change unit progression, roster state, or save semantics across maps?
2. Does the player need to understand it before starting a run?
3. Would changing it mid-save create migration or balance problems?

If the answer is mostly yes, it probably belongs here as a campaign rule instead
of in `SettingsManager` or a one-off map flag.

## Common mistakes

- Storing a gameplay rule in global settings instead of save/runtime state
- Treating Pair Up as a content flag on one map instead of a run-wide rule
- Forgetting that rule-dependent UI and action gating must match the active save
- Adding a new long-term rule without deciding save ownership or migration behavior

## Related source docs

- `AGENT/GDD/GDD_02_Core_Mechanics.md` for battle-loop effects
- `AGENT/GDD/GDD_03_Units_Classes.md` for progression-facing effects
- `AGENT/GDD/GDD_07_UI_UX.md` for New Game and in-map player-facing surfaces
- `AGENT/Docs/archive/reference/campaign_rules_firming_notes_2026-05-25.md` for the original
  decision discussion and historical context
