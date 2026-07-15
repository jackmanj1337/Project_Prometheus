# Campaign Rules

**Last verified:** 2026-07-15
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
They are not global app settings. A campaign JSON `rules` entry may wrap a value
as `{ "authority": "default", "value": ... }` (player-editable seed) or
`{ "authority": "mandate", "value": ... }` (locked author requirement).
Legacy direct values are editable defaults. Mandate ids persist in
`campaign.rules.mandated_rules` beside the resolved values.

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
- `undo_activations: int`
- `undo_rounds: int`
- `save_slot_classes: Array[Dictionary]`
- `autosave_rules: Array[Dictionary]`

The current launch-routing fields that travel with New Game setup are:

- `next_map_data_path: String`
- `next_map_roster_policy: String`
- `next_map_roster_source: String`

The rule object and launch-routing fields are serialized through the save/runtime
contracts; authored profile selection and several later consumers remain planned.
New Game disables the four visible controls when their rule ids are mandated and
never writes a disabled control back over the campaign's value.

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

### `undo_activations` / `undo_rounds` (B1-LEDGER within-map ledger)

Retention budgets for the within-map decaying ledger (`scripts/save/MapLedger.gd`),
the stack of suspend-complete board checkpoints that Retry and mid-map Rewind
restore from. The ledger keeps the UNION of:

- the last `undo_activations` per-activation entries (the fine tier), and
- the last `undo_rounds` round-start entries (the coarse tier),

on top of the round-0 boundary, which is **always** retained so a Retry works
regardless of the budgets. `-1` means retain every entry of that tier (the coarse
tier may legitimately be infinite); `0` keeps none beyond round-0.

`rewind_charges_per_map` is the authoritative player spend meter. A fresh map
starts with that many charges and every successful Rewind consumes one. The undo
fields only express retention depth; while Rewind is enabled, runtime floors the
fine tier to `rewind_charges_per_map + 1` checkpoints so all authored charges can
actually be spent. `0` charges is the no-rewind/ironman-style preset; `-1` is an
infinite spend meter and retains the full fine tier. A rewind
restores the checkpoint's board, party economy, PairUp and RNG state, then drops
the abandoned future; replaying the same actions therefore reproduces the same
outcomes rather than rerolling luck.

### Save slot classes and autosave rules

`save_slot_classes` is a list of
`{count, accepts, consumed_on_load, label}` dictionaries. `accepts` is
`between_map`, `mid_map`, or `any`. The runtime ships three pure-data preset
shapes: classic GBA-style 3 between-map + 1 consumed suspend, one consumable
interchangeable slot, and 30 durable interchangeable slots. Counts apply only to
manual saves. A consumed slot is deleted only after the complete restore/scene
route succeeds; policy is enforced at save/load/UI boundaries, not cryptographically
inside the document format.

`autosave_rules` is an independent list of
`{rule_id, trigger, keep, label, consumed_on_load:false}` dictionaries. Trigger ids
use the open `AutosaveTriggerRegistry`: shipped bindings are `battle_start`,
`battle_end`, `menu_area_exit`, and `shop_exit`, while campaign systems may dispatch
custom string ids through the same registry. An empty list disables autosave.
Each rule rotates only `origin:auto` slots carrying its own `rule_id`; manual slots
and other rules' pools never enter the overwrite candidate set.

Builder warning (non-blocking): **durable mid_map saves require infinite rewind**
(`rewind_charges_per_map = -1`). A durable battle reload combined with finite
decision-undo charges would bypass the authored budget. Consumed mid-map slots are
safe, as are all durable between-map slots because they replay a full battle rather
than undoing an activation. `check_docs.py` enforces this rule for shipped campaign
JSON, while `CampaignData.parse` reports it for authored packages.

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
- `AGENT/GDD/GDD_07_Screens_Panels.md` for New Game and in-map player-facing surfaces
- `AGENT/Docs/archive/reference/campaign_rules_firming_notes_2026-05-25.md` for the original
  decision discussion and historical context
