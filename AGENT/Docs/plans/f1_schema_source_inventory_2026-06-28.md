---
Role: dated
Type: plan
Status: Active - planning input
Last verified: 2026-06-28
---

# F1 Schema Source Inventory

**Started:** 2026-06-28. Pre-F1 prep for the Phase B save-schema lock.

**Purpose.** This document gathers the scattered F1/save-surface notes before
the actual F1 lock is written. It also defines the manifest row template,
scope/lifecycle glossary, and fixture matrix the lock should use.

**Inputs.**
- [`f1_save_schema_manifest_contract_2026-06-28.md`](../design/f1_save_schema_manifest_contract_2026-06-28.md)
- [`campaign_save_technical_plan_2026-06-21.md`](campaign_save_technical_plan_2026-06-21.md)
- [`feature_dependency_atlas_2026-06-23.md`](feature_dependency_atlas_2026-06-23.md)
- Feature/register save notes cited in the inventory table below.

## Manifest Row Template

Use this row shape in the F1 lock. A row may represent one field or a tightly
coupled field family.

| Column | Required meaning |
|---|---|
| Field path | Proposed save path or manifest id. Use `TBD` only when the lock must decide the exact path. |
| Owner | Feature/register responsible for the field semantics. |
| Scope | One of the glossary scopes below. |
| Lifecycle | When the field is created, reset, carried forward, or deleted. |
| Default / migration | Load behavior when the field is absent. Pre-1.0 may be "default only", but the value must still be explicit. |
| Serializer owner | `SaveCodec`, `SaveData`, `GameState`, `CampaignRules`, a registry serializer, or a feature-specific adapter called by the main codec. |
| Retry behavior | Restored, recomputed, cleared, or not applicable. |
| Suspend behavior | Restored, recomputed, cleared, or not applicable. |
| Fixtures | Required fixture classes from the fixture matrix. |
| Row status | `v1`, `dormant_reserve`, `post_v1_deferred`, or `explicit_no_save`. |
| Source | Register/design source that introduced the row. |

## Scope / Lifecycle Glossary

| Term | Meaning | Reset rule |
|---|---|---|
| `campaign` | State that survives across maps in one campaign save. | Reset only on new campaign or explicit story/rule action. |
| `campaign_rules` | Player/author rule choices and active profile selections. | Seeded at campaign creation; story flips mutate through approved rule seam. |
| `roster_unit` | Persistent per-unit state for units in the campaign roster. | Carried across maps; map-start may derive temporary runtime fields from it. |
| `party_inventory` | Party wallets, convoy/items, roster-level resources. | Carried across maps unless explicitly spent or reset by campaign rule. |
| `map_runtime` | Per-map mutable state such as fired events, object latches, map flags, dropped items, and discovered units. | Created at map start; cleared on map completion unless explicitly promoted to campaign state. |
| `object_runtime` | Mutable state for authored map objects. | Lives inside `map_runtime`; restored by Retry/suspend. |
| `unit_runtime` | Per-map state on live units, including positions, conditions, action states, carry state, AI wake state, and transient counters. | Created at map start; cleared on map completion unless copied into roster state. |
| `transient_suspend` | State needed only to resume an in-progress map or conversation. | Cleared on normal map completion and not used for between-map saves. |
| `settings` | Player/global settings outside a campaign save. | Owned by `SettingsManager`, not the F1 campaign save. |
| `authoring_data` | Definitions in campaign/map/content files. | Not serialized into a save except by id/reference. |
| `derived` | Recomputed from authored data or other saved state. | Never stored; tests should prove recomputation if risky. |

## Fixture Matrix

| Fixture id | Required for | What it proves |
|---|---|---|
| `codec_roundtrip` | Every JSON-owned field and every `SaveCodec` adapter. | Field writes only JSON primitives and reads back losslessly. |
| `old_save_default` | Every new field with an absent-field default. | Loading a save without the field produces the documented default. |
| `retry_restore` | Map-start snapshot fields and state Retry promises to restore. | Retry restores the field exactly or recomputes it by rule. |
| `suspend_restore` | Mid-map, mid-turn, and mid-conversation fields. | Suspend/load resumes without losing state or re-firing latches. |
| `map_reset` | Per-map counters, latches, and transient state. | New map setup clears or seeds the field correctly. |
| `campaign_carry` | Campaign/roster/rules fields. | The field survives map completion and next-map prep. |
| `migration_default` | Fields replacing older data such as `permadeath_enabled` or `weapon_wexp`. | Old shape maps to the new shape without data loss where applicable. |
| `reference_validation` | Fields storing ids or registry references. | Saved ids resolve to loaded campaign content or fail with a structured error. |
| `no_save_guard` | Explicit derived/authoring/session fields. | The field is not serialized and is recomputed or discarded as designed. |

## Source Inventory

| Field family | Owner/source | Scope | Lifecycle and default | Fixtures |
|---|---|---|---|---|
| Save envelope: `format_version`, `save_label`, integrity hashes, header metadata | `[CST-1/9/10]`, campaign save plan | `campaign` | Created by SaveManager. `format_version` default is not optional; unknown versions warn/fail per loader rule. | `codec_roundtrip`, `old_save_default`, `reference_validation` |
| Campaign graph position: `campaign_id`, `node_id`, cleared nodes | `[CST-3]` | `campaign` | Created at campaign start, advanced on victory. | `campaign_carry`, `codec_roundtrip`, `reference_validation` |
| CampaignRules object and rule mandates/defaults | `[CST-4/6/11]`, F4 | `campaign_rules` | Seeded from campaign data; story flips mutate through the rule-flip seam. | `campaign_carry`, `migration_default`, `reference_validation` |
| `death_mode` replacing `permadeath_enabled` | `[DIF-7]` | `campaign_rules` | Default maps old bool to `classic` or `casual` per migration rule; stored as enum. | `migration_default`, `campaign_carry` |
| Difficulty / content variant selection | `[DIF-7]`, difficulty profile contract | `campaign_rules` | Chosen at campaign start from author-allowed profiles. | `campaign_carry`, `reference_validation` |
| Active profile selections and per-save overrides | F4 foundations doc | `campaign_rules` | Stored by profile type/name; defaults come from CampaignRules. | `campaign_carry`, `reference_validation` |
| Typed campaign variable store | `[TCV-6]` | `campaign` + `map_runtime` | Campaign vars persist; map vars reset at map start. Defaults come from the variable registry. | `campaign_carry`, `map_reset`, `old_save_default`, `reference_validation` |
| Player exposed-tunable picks | `[TCV-2/6]`, `[DIF-7]` | `campaign_rules` | Picked at start or mid-run when author exposes the variable. | `campaign_carry`, `old_save_default` |
| Objective predicate/flag references | `[TCV-4/6]` | `authoring_data` with saved references/latches | Objective definitions are authoring data; runtime latches read F6/TCV/MET state. | `reference_validation`, `suspend_restore` |
| F6 story flags and map flags | `[MET-6]`, F6 foundations doc | `campaign` + `map_runtime` | Campaign flags carry; map flags reset per map and restore on suspend. | `campaign_carry`, `map_reset`, `suspend_restore` |
| Map event fired ids | `[MET-5]` | `map_runtime` | Created per map; `once:true` events latch, `once:false` skip the latch. | `retry_restore`, `suspend_restore`, `map_reset` |
| Map object state: opened, looted, broken, HP, ammo, lit/toggled state | `[DCH-6]`, `[DTR-8]`, `[STW-5]`, `[FOW-7]`, `[SAC-12]` | `object_runtime` | Created from map objects; restored by Retry/suspend; cleared on new map. | `retry_restore`, `suspend_restore`, `map_reset`, `reference_validation` |
| Discovered enemy units | `[FOW-5]` | `map_runtime` | Stores ever-seen unit ids; visible tiles recompute and are not saved. | `suspend_restore`, `map_reset`, `no_save_guard` |
| AI wake/latch state | `[AIP-5]` | `unit_runtime` | Created false/default at map start; saved once awakened. | `retry_restore`, `suspend_restore`, `map_reset` |
| Party gold / resource wallet | `[SHP]`, `[THL-6]`, resource ledger contract | `party_inventory` | `party_gold` evolves into `{resource_id: amount}`; defaults seed legacy gold. | `campaign_carry`, `migration_default`, `codec_roundtrip` |
| Convoy / party items / roster inventory | `[CST]`, `[CNV]`, `[IEQ]` | `party_inventory` + `roster_unit` | Persistent party state; prep transactions commit immediately per `[PHB-7]`. | `campaign_carry`, `codec_roundtrip`, `retry_restore` |
| `InventoryEntry.def_id`, `uses_remaining`, `forged_mods`, equipped pointers | `[IEQ-8]` | `roster_unit` | Migrates existing weapon/item instance data into ItemDef instance refs. | `codec_roundtrip`, `migration_default`, `campaign_carry` |
| `InventoryEntry.map_uses_remaining` | `[CEX-13]` | `unit_runtime` | Refills to `uses_per_map` at map start; only needed for suspend/Retry. | `retry_restore`, `suspend_restore`, `map_reset` |
| Equipped source pointer, source priority, and MRU equip history | `[CEX-21/22]` | `roster_unit` | Persistent per unit; auto-fallback updates MRU by rule. | `campaign_carry`, `codec_roundtrip` |
| Per-source charge state / learned spell charge state | `[CEX-6/20]`, atlas Phase B | `roster_unit` or `unit_runtime` depending refill rule | Persistent only for carry-over charges; per-map charges reset. | `campaign_carry`, `map_reset`, `suspend_restore` |
| `UnitData.proficiency_xp` replacing `weapon_wexp` | `[PXP-1/8]` | `roster_unit` | Migrates legacy WEXP into track-keyed dict. | `migration_default`, `campaign_carry`, `codec_roundtrip` |
| PXP rank profiles and gain config | `[PXP-8]` | `campaign_rules` / `authoring_data` | Campaign profile refs persist; profile definitions are authoring data. | `reference_validation`, `campaign_carry` |
| Personal, earned, and granted skills | `[SKL-5]`, `[SMV-11]`, `[AGT-11]` | `roster_unit` | Personal/granted dynamic skills persist; class availability derives; granted durations persist if cross-map. | `campaign_carry`, `codec_roundtrip`, `no_save_guard` |
| Action-grant and rate-limit counters | `[AGT-11]` | `unit_runtime` / `transient_suspend` | Cleared at faction refresh; serialized only for mid-turn suspend. | `suspend_restore`, `map_reset` |
| Learned/equipped styles and per-style charge state | `[STY]` F1 implications | `roster_unit` or `unit_runtime` depending refill rule | Learned/equipped lists persist; per-map charges reset. | `campaign_carry`, `map_reset`, `suspend_restore` |
| Optional committed attack `style_id` | `[STY]`, `[CEX-23]` | `transient_suspend` | Stored only if an in-progress action/suspend needs the source+style reference. | `suspend_restore`, `no_save_guard` |
| Active conditions per unit | F5, `[STY-12]`, foundations doc | `unit_runtime` and possibly `roster_unit` for cross-map conditions | Default none; duration/source/potency persist for any active saved condition. | `retry_restore`, `suspend_restore`, `campaign_carry` if cross-map |
| Captured/sleep/carry state | `[DSP-11]`, `[RCR]`, `[STY-6]` | `unit_runtime` + `campaign` flags | Carry pointers restore mid-map; captured flags persist through F6. Avoid double-storing sleep outside F5. | `retry_restore`, `suspend_restore`, `campaign_carry` |
| Pair-Up and Carry registries | `[CST]`, `[DSP-11]` | `unit_runtime` | Pair-Up registry restores for Retry/suspend; between-map persistence remains deferred unless a feature chooses it. | `retry_restore`, `suspend_restore`, `map_reset` |
| Runtime faction relationship overrides | `[STY-17]`, `[PRV]` | `map_runtime` + `campaign` | Map-scope overrides reset; campaign-scope overrides carry. Authored matrix is data, not save. | `suspend_restore`, `campaign_carry`, `map_reset` |
| Relationship graph and per-map gain counters | `[REL-9]` | `campaign` + `map_runtime` | Relationship ranks carry; per-map gain counters reset each map. | `campaign_carry`, `map_reset`, `codec_roundtrip` |
| Main-character/avatar identity fields | `[MCH-7]` | `roster_unit` | Player-authored fields carry with roster unit. | `campaign_carry`, `codec_roundtrip` |
| Recruited roster membership and `recruited:<id>` flags | `[RCR-7]`, `[RCV-6]` | `campaign` + `roster_unit` | Recruiting adds roster member and F6 flag. | `campaign_carry`, `reference_validation` |
| Conversation resume block `{conversation_id, cursor, visited_trail?}` | `[DLG-11]` | `transient_suspend` | Created only for mid-conversation save/suspend; stable entry ids required. | `suspend_restore`, `reference_validation` |
| `conversations_seen` fired set | `[RCV-6]`, `[DLG-10]` | deferred / conditional | Do not reserve while conversations are only MET actions; reserve if direct invocations appear. | `no_save_guard` now; `suspend_restore` if added |
| Key-item custody state | `[DTH-10/11]`, `[TCV-4]` | `campaign` + `map_runtime` | Tracks item custody for objectives; never allows `lost` for key items. | `campaign_carry`, `suspend_restore`, `reference_validation` |
| Per-map dropped-item stash | `[DTH-11]` | `map_runtime` | Reserve only if `drop_on_tile` is enabled; cleared/resolved on map end by rule. | `suspend_restore`, `map_reset`, `reference_validation` |
| Battalion attachment, endurance, EXP/rank, exhausted/disband state | `[BAT-11/15/16]` | `campaign` + `roster_unit` | Attachment and persistent battalion state carry; charges reset per map. | `campaign_carry`, `retry_restore`, `map_reset` |
| Battalion charges | `[BAT-15]` | `unit_runtime` / `object_runtime` | Per-map budget; reset each map and restored for suspend. | `suspend_restore`, `map_reset` |
| `UnitData.extra_stats` and stat registry references | `[STM]` | `roster_unit` + `campaign_rules` / `authoring_data` | Extra stats carry per unit; stat definitions are campaign data/registry. | `campaign_carry`, `reference_validation`, `codec_roundtrip` |
| Per-unit groups/tags | `[TCV-3/6]` | `roster_unit` or `unit_runtime` by owner decision | Authored groups seed from data; runtime additions persist only if feature mutates them. | `campaign_carry`, `reference_validation` |
| Loadout cap modifiers | `[LDC-7/8]` | `roster_unit` | Only persistent consumed-item cap modifiers store; held/class/flag modifiers recompute. | `campaign_carry`, `no_save_guard` |
| Bonus-EXP pool | `[BEA-8]` | `campaign` | Campaign-wide bank, awarded by objectives/events and spent in prep. | `campaign_carry`, `codec_roundtrip` |
| Training purchase counts | `[THL-6]` | `campaign` / `party_inventory` | Optional, only for author-capped offers. | `campaign_carry`, `old_save_default` |
| Bought recruits | `[THL-8]`, `[PVP-3]` | `roster_unit` | Ride roster save; generator specs are authoring data. | `campaign_carry`, `reference_validation` |
| PvP campaign fields: per-faction budgets, round wins, bought rosters | `[PVP-8]` | `campaign` | Reserve if PvP campaign type remains in v1 scope; otherwise defer with explicit no-field row. | `campaign_carry`, `old_save_default` |
| Mid-battle suspend board state | `[CST-8]` | `transient_suspend` | Live enemies, positions, turn/phase, activation cursor, unit states, cursor tile, pair/carry registries, RNG summary. Cleared on map completion. | `suspend_restore`, `codec_roundtrip` |
| Threat range watch set and danger mode | `[TUR-4]`, campaign save plan | `transient_suspend` / UI runtime | Survives mid-map suspend; not campaign progress. | `suspend_restore`, `map_reset` |
| RNG map seed/history and rewind charges | `[CST-8/12/13]`, RNG design | `campaign_rules` + `transient_suspend` | Package A owns deterministic fields; rewind mechanic remains deferred but charge persistence is reserved. | `suspend_restore`, `campaign_carry`, `codec_roundtrip` |

## Explicit No-Save Decisions

Track these in the F1 lock so future builds do not add fields by accident.

| Topic | Decision |
|---|---|
| AoE shapes and target filters | Authoring data only; no save field. |
| F16 requirement data | Authoring data; reads saved state but adds no top-level save field except chance latches riding F6/DLG. |
| Atomic dialogue playback | No field unless mid-conversation save is active. |
| Shop stock, labels, dynamic pricing rules | Campaign content/authoring; shopper is session-scoped. |
| PHB panel UI state | No bespoke hub suspend; transactions commit immediately to party state. |
| Secondary Movement | No new field beyond the granted skill persistence. |
| Battleground visible tiles | Recomputed from unit positions and LoS; only discovered-unit memory persists. |
| Arena mid-fight state | No mid-match save; arena resolves atomically before returning to prep. |
| Class-skill availability | Derived from class + level; not stored. |
| Held/class/flag loadout cap modifiers | Recomputed; only permanent consumed-item cap modifiers store. |

## Lock-Doc Inputs Still To Decide

- Exact JSON field paths for every row.
- Whether active conditions can persist across maps or only in map/suspend state.
- Which action/rate-limit counters must serialize for mid-turn suspend.
- Whether PvP campaign fields are v1 or deferred rows.
- Whether `conversations_seen` becomes real before v1.
- Which fields become machine-readable manifest data in the first F1 implementation.
