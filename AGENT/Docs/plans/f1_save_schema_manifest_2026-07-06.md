---
Type: plan
Status: Active - schema manifest
Last verified: 2026-07-06
---

# F1 Save Schema Manifest

**Track ID:** `B1-F1`

**Created:** 2026-07-06

**Source inventory:** [`f1_schema_source_inventory_2026-06-28.md`](f1_schema_source_inventory_2026-06-28.md)

**Lock design:** [`f1_save_schema_lock_design_2026-06-28.md`](../design/f1_save_schema_lock_design_2026-06-28.md)

## Purpose

This manifest is the first locked save-field map for the campaign/save line.
It does not implement save/load. It assigns field paths, ownership, defaults,
serializer owners, Retry behavior, suspend behavior, and fixture obligations so
later feature work does not add persistent state ad hoc.

Rows may describe a field family when the fields move together and share one
serializer/fixture contract.

## Row Status Values

| Value | Meaning |
|---|---|
| `v1` | Reserved for the first playable campaign/save path. |
| `dormant_reserve` | Path is reserved so future work can attach cleanly, but the feature may stay disabled. |
| `post_v1_deferred` | Explicitly not part of v1; keep out of serializers until rescheduled. |
| `explicit_no_save` | Guard row: this state must not enter campaign saves. |

## Top-Level Save Shape

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

`map_runtime` owns mutable active-map facts. `suspend` owns resume-only cursor,
mode, conversation, and interrupted-action facts. Do not duplicate the same
runtime value in both sections unless a later serializer fixture proves why the
copy is necessary.

## Fixture Keys

| Fixture | Meaning |
|---|---|
| `codec_roundtrip` | JSON-safe write/read round-trip. |
| `old_save_default` | Absent field loads through the documented default. |
| `migration_default` | Legacy field shape maps into the new field. |
| `campaign_carry` | Field survives map completion and the next map start. |
| `map_reset` | Field clears or seeds correctly at a fresh map start. |
| `retry_restore` | Retry restores or recomputes the field by rule. |
| `suspend_restore` | Suspend/load restores the field or clears it by rule. |
| `reference_validation` | Ids/registry refs resolve or fail with structured errors. |
| `no_save_guard` | Field is excluded from saves and recomputed/discarded. |

## Manifest

| Field path | Owner | Scope | Lifecycle | Default / migration | Serializer owner | Retry behavior | Suspend behavior | Fixtures | Row status | Source |
|---|---|---|---|---|---|---|---|---|---|---|
| `format_version` | `[CST-1]` | `campaign` | Written by `SaveData` for every persistent document. | New saves write `1`; absent legacy saves route through the legacy adapter or structured unsupported-save error until an adapter exists. | `SaveData` | Not applicable. | Restored. | `codec_roundtrip`, `old_save_default` | `v1` | Campaign save plan; F1 lock design. |
| `save_label` | `[CST-9]` | `campaign` | Player/editor label stored with the save slot. | Empty string. | `SaveData` | Not applicable. | Restored. | `codec_roundtrip`, `old_save_default` | `v1` | Campaign save plan. |
| `origin`, `rule_id` | `B1-LEDGER` | `campaign` | Every document is tagged `manual` or `auto`; automatic saves carry the registry rule id that selected their pool. | Old/unspecified documents normalize to `origin: manual`; `rule_id` is empty only for manual saves. | `SaveManager` finalization via `SaveData` | Not applicable. | Restored and mirrored into the index row. | `codec_roundtrip`, `old_save_default` | `v1` | B1-LEDGER Phase 4; persistence/undo plan. |
| `integrity.payload_hash`, `integrity.schema_hash` | `[CST-10]` | `campaign` | Written when a save document is finalized; recalculated on write. | Empty integrity block for old saves until SaveManager validates files. | `SaveData` / `SaveManager` | Not applicable. | Recomputed on write, validated on load. | `codec_roundtrip`, `old_save_default`, `reference_validation` | `v1` | Campaign save plan. |
| `header.*` | `[CST-9]` | `campaign` | Slot-preview metadata mirrors save contents and is updated atomically with the slot/index pair. | Derived from campaign fields when absent; missing optional text becomes empty string. | `SaveData` / transactional `SaveManager` index mirror | Not applicable. | Restored. | `codec_roundtrip`, `old_save_default` | `v1` | Campaign save plan. |
| `header.campaign_state` | v0.4.0 post-build repair | `campaign` | Derived as `in_progress` while a campaign has a node and `completed` after terminal commit. | Derived from campaign/node identity; stale header values are replaced. | `SaveData` header adapter | Not applicable. | Continue skips `completed`; Load Game retains and labels the record. | `campaign_carry`, `old_save_default`, `codec_roundtrip` | `v1` | v0.4.0 post-build review fix handoff; future CampaignCompletionRecord exporter. |
| `header.save_kind`, `header.turn_number`, `header.map_id` | `B1-LEDGER` | `campaign` | Index-only presentation discriminator for unified slots; derived from the document's active-map state. | `between_map`, turn 1, empty map id. Stale values are replaced from `map_runtime`. | `SaveData` header adapter / transactional index mirror | Not applicable. | Load Game labels `Resume battle — Turn N` versus `Continue — node` without opening slot files. | `codec_roundtrip`, `old_save_default` | `v1` | B1-LEDGER Phase 4. |
| `campaign.campaign_id`, `campaign.node_id`, `campaign.cleared_nodes[]` | `[CST-3]`, `[CNC]` | `campaign` | Created at campaign start; advanced when the results surface commits a win (`CampaignManager.commit_pending_result`), which also writes the autosave slot. | `cleared_nodes` defaults to `[]`; ids must resolve or load fails — an unresolvable id aborts the restore before any state is written. An empty `campaign_id` is a valid save (the bare single-map launch), not a corrupt one. | `CampaignManager` adapter (`capture_campaign_state` / `restore_campaign_state`) via `SaveData` | Restored by snapshot only when the map snapshot includes campaign context. | Restored. The uncommitted pending result is NOT persisted, so a save taken mid-results restores parked on the current node. | `campaign_carry`, `codec_roundtrip`, `reference_validation` | `v1` | Campaign save plan; `[CNC-1..10]`; `B1-CST` Slice 3. |
| `campaign.package_id`, `campaign.package_version` | `B6-CAMPAIGN-SHARING` | `campaign` | Exact installed authored-content identity for both between-map and mid-map saves. Content activates before campaign/map/class ids resolve. | Empty pair selects shipped `res://data`; exactly one empty value is invalid. Saves never carry a caller-controlled package path. | `GameState` + `DataManager` Tier-2 source adapter via `SaveData` | Preserved with campaign context. | Restored before map shell/runtime units. | `campaign_carry`, `suspend_restore`, `old_save_default`, `reference_validation`, `codec_roundtrip` | `v1` | Campaign-pack engine boundary and archive delivery plan. |
| `campaign.rules.*` | `[CST-4/6/11]`, F4 | `campaign_rules` | Seeded from campaign data at start; story/rule effects mutate through CampaignRules. | Missing object builds from author defaults and migration defaults. | `CampaignRules` adapter via `SaveCodec` | Restored when Retry snapshot includes rule state. | Restored. | `campaign_carry`, `migration_default`, `reference_validation` | `v1` | Campaign save plan; campaign rules guide. |
| `campaign.rules.hit_formula` | `[CRR-1..8]`, RULE-001 | `campaign_rules` | Seeded from CampaignRules; affects deterministic attack draw count. | `two_roll`. Unknown id fails reference validation. | `CampaignRules` adapter via `SaveCodec` | Restored; changing it mid-map is replay-breaking unless committed through the rule seam. | Restored. | `campaign_carry`, `reference_validation`, `codec_roundtrip` | `v1` | Combat roll resolver register; B1-PKGA Slice 1b. |
| `campaign.rules.death_mode` | `[DIF-7]` | `campaign_rules` | Chosen at campaign start or through approved rule flips. | Legacy `permadeath_enabled=true` maps to `classic`; false maps to `casual`. | `CampaignRules` adapter via `SaveCodec` | Restored. | Restored. | `migration_default`, `campaign_carry` | `v1` | Difficulty/death-mode register. |
| `campaign.rules.difficulty_profile_id` | `[DIF-7]` | `campaign_rules` | Player picks from author-allowed profiles at campaign start. | Author default profile id; unknown id fails. | `CampaignRules` adapter via `SaveCodec` | Restored. | Restored. | `campaign_carry`, `reference_validation` | `v1` | Difficulty/death-mode register. |
| `campaign.rules.profile_selections` | F4 foundations | `campaign_rules` | Active rule/profile selections carry with the save. | Empty dictionary means use campaign defaults. | `CampaignRules` adapter via `SaveCodec` | Restored. | Restored. | `campaign_carry`, `reference_validation` | `v1` | Foundations end-shapes. |
| `campaign.rules.exposed_tunables` | `[TCV-2/6]`, `[DIF-7]` | `campaign_rules` | Player-visible rule/tuning picks carry if author exposes them. | Empty dictionary; missing keys read registry defaults. | `CampaignRules` adapter via `SaveCodec` | Restored. | Restored. | `campaign_carry`, `old_save_default`, `reference_validation` | `v1` | Typed campaign-variable register. |
| `campaign.vars`, `map_runtime.vars` | `[TCV-1..6]` | `campaign` / `map_runtime` | Campaign vars carry; map vars seed/reset at map start. | Empty dictionary over registry defaults. | `CampaignManager` open-registry adapter via `SaveData`; future TCV registry adds typed validation | Map vars restored; campaign vars restored only if in snapshot context. | Restored; malformed dictionaries/ids fail before apply. | `campaign_carry`, `map_reset`, `old_save_default`, `reference_validation` | `v1` | Typed campaign-variable register. |
| `campaign.flags`, `map_runtime.flags` | `[MET-6]`, F6 | `campaign` / `map_runtime` | Campaign flags carry; map flags reset at map start. | Empty set. | `CampaignManager` open string-set adapter via `SaveData`; future MET registry adds reference validation | Map flags restored. | Restored; empty ids fail and duplicates deduplicate. | `campaign_carry`, `map_reset`, `suspend_restore` | `v1` | Map-events register; foundations end-shapes. |
| `map_runtime.map_id`, `map_runtime.map_path` | `[CST-8]` | `map_runtime` | Active-map identity used to reload the authored map shell before restoring mutable runtime state. | Empty strings for old saves; suspend resume requires `map_path` or load fails. | `GameState` suspend adapter; `SaveData` envelope | Restored if the snapshot includes map identity. | Restored. | `suspend_restore`, `reference_validation` | `v1` | Campaign save plan; B1-SUSPEND Slice 1. |
| `map_runtime.units[]` | `[CST-8]` | `unit_runtime` | Live active-map unit state for every faction, including identity, faction, position, HP/progression, inventory, static config needed to rebuild non-roster enemies. | Empty list means no active-map units; invalid ids or classes fail reference validation. | `GameState` suspend adapter via `SaveCodec` | Restored when Retry snapshot includes active-map runtime units. | Restored by spawning from `map_runtime.units` instead of authored placements. | `suspend_restore`, `codec_roundtrip`, `reference_validation` | `v1` | Campaign save plan; B1-SUSPEND Slice 1. |
| `map_runtime.turn` | `[CST-8]` | `map_runtime` | Active turn number, phase, active faction index, turn order, activation mode, per-unit activation states, and objective/escape/seize bookkeeping. | Missing fields default to turn 1, player phase, whole-phase activation, and empty unit/objective state. | `TurnManager` suspend adapter; `SaveData` envelope | Restored when Retry snapshot includes turn state. | Restored without running start-of-phase effects or AI handoff. | `suspend_restore`, `retry_restore` | `v1` | Campaign save plan; B1-SUSPEND Slice 1. |
| `ledger[]` | `B1-LEDGER` | `map_runtime` | Ordered reason-tagged suspend-complete rewind boundaries persisted only by `mid_map` documents. | Empty for `between_map`; a `mid_map` document without at least round-0 is invalid. | `MapLedger` adapter via `GameState` / `SaveData` | Entry 0 remains Retry; non-zero entries remain spendable Rewind boundaries after reload. | Whole ledger restored before the map scene rebuilds. | `codec_roundtrip`, `retry_restore`, `suspend_restore` | `v1` | B1-LEDGER Phase 4. |
| `map_runtime.objective_latches` | `[TCV-4/6]` | `map_runtime` | Runtime objective latches update from F6/TCV/MET state. | Empty dictionary; objective definitions stay in authoring data. | Objective adapter via `SaveCodec` | Restored. | Restored. | `reference_validation`, `retry_restore`, `suspend_restore` | `v1` | Typed campaign-variable register. |
| `map_runtime.events_fired[]` | `[MET-5]` | `map_runtime` | Created per map; `once:true` events latch, `once:false` events do not. | Empty set. | MET adapter via `SaveCodec` | Restored. | Restored. | `retry_restore`, `suspend_restore`, `map_reset` | `v1` | Map-events register. |
| `map_runtime.objects.*` | `[DCH-6]`, `[DTR-8]`, `[STW-5]`, `[FOW-7]`, `[SAC-12]` | `object_runtime` | Object latches/HP/ammo/toggle state seed from map data and mutate at runtime. | Empty dictionary means every object uses authored initial state. | Map-object adapter via `SaveCodec` | Restored. | Restored. | `retry_restore`, `suspend_restore`, `map_reset`, `reference_validation` | `v1` | Map-object component contract and registers. |
| `map_runtime.discovered_units[]` | `[FOW-5]` | `map_runtime` | Stores ever-seen unit ids for fog memory. | Empty set. | FOW adapter via `SaveCodec` | Restored. | Restored. | `suspend_restore`, `map_reset`, `no_save_guard` | `v1` | Fog-of-war register. |
| `party.resources` | `[SHP]`, `[THL-6]` | `party_inventory` | Party wallet carries and mutates through resource ledger transactions. | Legacy `party_gold` maps to `{party_gold: amount}`. | Resource ledger adapter via `SaveCodec` | Restored only if snapshot includes party state. | Restored. | `campaign_carry`, `migration_default`, `codec_roundtrip` | `v1` | Resource ledger contract; shop/training registers. |
| `party.convoy.entries[]` | `[CST]`, `[CNV]`, `[IEQ]` | `party_inventory` | Convoy/party items carry; prep transactions commit immediately. | Empty list explicitly clears stale live items. | `GameState` flat-item compatibility adapter via `SaveData`; future convoy owns rich entries | Restored if included in map snapshot. | Restored with duplicates preserved and item ids validated through `DataManager`. | `campaign_carry`, `codec_roundtrip`, `retry_restore` | `v1` | Convoy and item/equipment registers. |
| `roster.units[].identity` | `[CST]`, `[RCR-7]` | `roster_unit` | Stable roster ids and public identity carry across maps. | No default for missing id; load fails. | Unit adapter via `SaveCodec` | Restored if included in map snapshot. | Restored. | `campaign_carry`, `codec_roundtrip`, `reference_validation` | `v1` | Campaign save plan; recruit register. |
| `roster.units[].progression` | GDD_03, `[PXP]` | `roster_unit` | Level/EXP/class state carries; map-start derives runtime unit stats. | Existing UnitData defaults for old fields; unknown class id fails. | Unit adapter via `SaveCodec` | Restored. | Restored. | `campaign_carry`, `codec_roundtrip`, `reference_validation` | `v1` | GDD_03; class/PXP plans. |
| `roster.units[].status` | `[DTH]`, `[RCR]`, `[DIF]` | `roster_unit` | Roster membership, death/captured/deployed status carries by campaign rules. | Existing roster units default to available/alive unless legacy state says otherwise. | Unit adapter via `SaveCodec` | Restored. | Restored. | `campaign_carry`, `migration_default`, `reference_validation` | `v1` | Death lifecycle; recruit/capture registers. |
| `roster.units[].inventory.entries[]` | `[IEQ-8]` | `roster_unit` | Persistent item instances carry and mutate through inventory actions. | Legacy weapon/item slots migrate into entries. | Inventory adapter via `SaveCodec` | Restored. | Restored. | `codec_roundtrip`, `migration_default`, `campaign_carry` | `v1` | Items/equipment register. |
| `roster.units[].equipment` | `[IEQ-8]`, `[CEX-21/22]` | `roster_unit` | Equipped item/source pointers and MRU source history carry. | Empty pointers recompute by legal fallback; unknown ids fail. | Inventory/source adapter via `SaveCodec` | Restored. | Restored. | `campaign_carry`, `codec_roundtrip`, `reference_validation` | `v1` | Items/equipment and source/style registers. |
| `roster.units[].proficiency_xp` | `[PXP-1/8]` | `roster_unit` | Track-keyed proficiency values carry. | Legacy `weapon_wexp` maps to matching track ids. | PXP adapter via `SaveCodec` | Restored. | Restored. | `migration_default`, `campaign_carry`, `codec_roundtrip` | `v1` | Proficiency-XP register. |
| `campaign.rules.pxp_profiles` | `[PXP-8]` | `campaign_rules` | Active PXP profile refs carry; definitions stay authoring data. | Empty dictionary means campaign defaults. | CampaignRules/PXP adapter via `SaveCodec` | Restored. | Restored. | `reference_validation`, `campaign_carry` | `v1` | Proficiency-XP register. |
| `roster.units[].skills` | `[SKL-5]`, `[SMV-11]`, `[AGT-11]` | `roster_unit` | Personal, earned, equipped, and cross-map granted skills carry. | Empty dynamic lists; class availability derives. | Skill adapter via `SaveCodec` | Restored. | Restored. | `campaign_carry`, `codec_roundtrip`, `no_save_guard` | `v1` | Skill and action-grant registers. |
| `map_runtime.units[].action_rate_counters` | `[AGT-11]` | `unit_runtime` | Created/reset at faction refresh or map start; needed for mid-turn suspend. | Empty dictionary. | Action-economy adapter via `SaveCodec` | Cleared or restored per snapshot safe point. | Restored. | `suspend_restore`, `map_reset` | `v1` | Action-grant register. |
| `roster.units[].styles` | `[STY]`, `[LDC]` | `roster_unit` | Learned/equipped styles carry. | Empty learned/equipped lists. | Style adapter via `SaveCodec` | Restored. | Restored. | `campaign_carry`, `codec_roundtrip` | `v1` | Source/style register. |
| `map_runtime.units[].source_style_counters` | `[CEX-6/20]`, `[STY]` | `unit_runtime` | Per-map source/style/charge counters reset at map start and restore for active-map saves. | Empty dictionary; refill rules seed values at map start. | Source/style adapter via `SaveCodec` | Restored. | Restored. | `map_reset`, `retry_restore`, `suspend_restore` | `v1` | Source/style register. |
| `roster.units[].source_state` | `[CEX-6/20]` | `roster_unit` | Carry-over charge state persists only when the source refill rule says it carries. | Empty dictionary. | Source adapter via `SaveCodec` | Restored. | Restored. | `campaign_carry`, `codec_roundtrip` | `dormant_reserve` | Source/style register. |
| `suspend.pending_action.source_id`, `suspend.pending_action.style_id` | `[STY]`, `[CEX-23]` | `transient_suspend` | Stored only while an interrupted action needs committed source/style refs. | Null. | Suspend adapter via `SaveCodec` | Not applicable. | Restored or cleared if no interrupted action exists. | `suspend_restore`, `no_save_guard` | `v1` | Source/style register. |
| `map_runtime.units[].conditions[]` | F5, `[STY-12]` | `unit_runtime` | Active map conditions carry through Retry/suspend and clear/expire by duration rules. | Empty list. | Condition adapter via `SaveCodec` | Restored. | Restored. | `retry_restore`, `suspend_restore`, `map_reset` | `v1` | Conditions plans; foundations end-shapes. |
| `roster.units[].conditions[]` | F5 | `roster_unit` | Only condition defs that declare cross-map persistence may write here. | Empty list. | Condition adapter via `SaveCodec` | Restored if present. | Restored. | `campaign_carry`, `codec_roundtrip` | `dormant_reserve` | F1 lock recommendation. |
| `map_runtime.pair_carry` | `[DSP-11]`, `[RCR]`, `[CST]` | `unit_runtime` | Pair-Up, rescue/carry, sleep/capture pointers restore for active map only. | Empty registries. | Pair/carry adapter via `SaveCodec` | Restored. | Restored. | `retry_restore`, `suspend_restore`, `map_reset` | `v1` | Displacement/carry and campaign save registers. |
| `campaign.relationship_graph` | `[REL-9]` | `campaign` | Relationship ranks carry across maps. | Empty graph. | Relationship adapter via `SaveCodec` | Restored if in snapshot context. | Restored. | `campaign_carry`, `codec_roundtrip` | `v1` | Relationship register. |
| `map_runtime.relationship_overrides`, `map_runtime.relationship_gain_counters` | `[STY-17]`, `[PRV]`, `[REL-9]` | `map_runtime` | Map-scope overrides/gain counters reset at map start. | Empty dictionaries. | Relationship adapter via `SaveCodec` | Restored. | Restored. | `suspend_restore`, `campaign_carry`, `map_reset` | `v1` | Relationship and provoke registers. |
| `roster.units[].avatar` | `[MCH-7]` | `roster_unit` | Player-authored main-character/avatar fields carry. | Empty customization block. | Unit adapter via `SaveCodec` | Restored. | Restored. | `campaign_carry`, `codec_roundtrip` | `v1` | Main-character/avatar register. |
| `campaign.recruited_flags`, `roster.units[].recruit_source` | `[RCR-7]`, `[RCV-6]`, `[THL-8]` | `campaign` / `roster_unit` | Recruitment adds roster member and durable recruited flag/source. | Empty recruited set; existing roster units infer authored source when absent. | Recruit adapter via `SaveCodec` | Restored if in snapshot context. | Restored. | `campaign_carry`, `reference_validation` | `v1` | Recruit/capture, recruit conversation, training-hall registers. |
| `suspend.conversation_resume` | `[DLG-11]` | `transient_suspend` | Created only for mid-conversation save/suspend. | Null. | Dialogue adapter via `SaveCodec` | Not applicable. | Restored. | `suspend_restore`, `reference_validation` | `v1` | Dialogue register. |
| `campaign.key_item_custody`, `map_runtime.key_item_custody` | `[DTH-10/11]`, `[TCV-4]` | `campaign` / `map_runtime` | Custody state machine tracks key items through objectives and death disposition. | Empty dictionary; key item definitions stay authoring data. | Item/custody adapter via `SaveCodec` | Map custody restored. | Restored. | `campaign_carry`, `suspend_restore`, `reference_validation` | `v1` | Death-inventory and typed-variable registers. |
| `map_runtime.dropped_items[]` | `[DTH-11]` | `map_runtime` | Dropped-on-tile stash exists only when a death-disposition rule enables it. | Empty list. | Item/custody adapter via `SaveCodec` | Restored. | Restored. | `suspend_restore`, `map_reset`, `reference_validation` | `dormant_reserve` | Death-inventory register. |
| `campaign.battalions[]`, `roster.units[].battalion_attachment` | `[BAT-11/15/16]` | `campaign` / `roster_unit` | Persistent battalion state and attachment refs carry. | Empty battalion list and null attachment refs. | Battalion adapter via `SaveCodec` | Restored if in snapshot context. | Restored. | `campaign_carry`, `retry_restore`, `map_reset` | `dormant_reserve` | Battalion register. |
| `map_runtime.battalion_charges` | `[BAT-15]` | `unit_runtime` / `object_runtime` | Per-map battalion charge pools reset each map. | Empty dictionary. | Battalion adapter via `SaveCodec` | Restored. | Restored. | `suspend_restore`, `map_reset` | `dormant_reserve` | Battalion register. |
| `roster.units[].extra_stats` | `[STM]` | `roster_unit` | Author-extensible stat values carry per unit. | Empty dictionary over stat registry defaults. | Stat adapter via `SaveCodec` | Restored. | Restored. | `campaign_carry`, `reference_validation`, `codec_roundtrip` | `v1` | Extensible stat-model register. |
| `campaign.rules.stat_profile_id` | `[STM]` | `campaign_rules` | Active stat registry/profile selection carries by id. | Author default profile id. | CampaignRules/stat adapter via `SaveCodec` | Restored. | Restored. | `campaign_carry`, `reference_validation` | `v1` | Extensible stat-model register. |
| `roster.units[].groups` | `[TCV-3/6]` | `roster_unit` | Authored groups seed from data; runtime group changes persist only if a feature mutates them. | Empty list over authored groups. | Unit/TCV adapter via `SaveCodec` | Restored. | Restored. | `campaign_carry`, `reference_validation` | `v1` | Typed campaign-variable register. |
| `roster.units[].cap_modifiers` | `[LDC-7/8]` | `roster_unit` | Permanent consumed-item cap modifiers carry; held/class/flag modifiers recompute. | Empty dictionary. | Loadout adapter via `SaveCodec` | Restored. | Restored. | `campaign_carry`, `no_save_guard` | `v1` | Loadout-cap register. |
| `party.bonus_exp` | `[BEA-8]` | `campaign` | Campaign-wide Bonus EXP bank carries and changes through awards/spending. | `0`. | Prep-progression adapter via `SaveCodec` | Restored if in snapshot context. | Restored. | `campaign_carry`, `codec_roundtrip` | `v1` | Bonus EXP / arena register. |
| `party.training_purchase_counts` | `[THL-6]` | `campaign` / `party_inventory` | Optional per-offer counters carry when authors cap offers. | Empty dictionary. | Training-hall adapter via `SaveCodec` | Restored if in snapshot context. | Restored. | `campaign_carry`, `old_save_default` | `v1` | Training-hall register. |
| `campaign.pvp` | `[PVP-8]` | `campaign` | Optional PvP campaign block for budgets, wins, and bought rosters. | Null. | PvP adapter via `SaveCodec` | Not applicable unless PvP campaign is active. | Restored when active. | `campaign_carry`, `old_save_default` | `dormant_reserve` | PvP register; F1 lock recommendation. |
| `map_runtime.rng` | `[CST-8/12]`, RNG-2 | `map_runtime` | Active-map RNG timeline advances on committed non-undoable actions. | Map start seeds from content/campaign; absent snapshots leave the live RNG service untouched. New `SaveData` writes `map_seed` and `history_hash` as decimal strings to preserve 64-bit values through JSON; the RNG adapter accepts ints or strings. | `GameState` Retry/suspend adapters; `SaveData` envelope for persistent/suspend documents. | Restored. | Restored. | `suspend_restore`, `retry_restore`, `codec_roundtrip` | `v1` | RNG design; B1-PKGA Slice 2; B1-SAVECODEC Slice 5; B1-SUSPEND Slice 1. |
| `campaign.rules.rewind_charges_per_map`, `map_runtime.rewind_charges_left` | `[CST-13]`, RNG-3 | `campaign_rules`, `map_runtime` | Rule authors the per-map spend budget; runtime field tracks charges remaining at each rewind/suspend boundary. | Rule default `4`; missing runtime field starts from the rule. `0` disables Rewind; `-1` is infinite. | `CampaignRules` adapter; `GameState` map-runtime adapter | Round-0 restores the authored map-start budget. | Restored, so suspend/reload cannot refill charges. | `campaign_carry`, `codec_roundtrip`, `suspend_restore`, `retry_restore` | `v1` | RNG design; B1-LEDGER Phases 3/5; campaign rules guide. |
| `campaign.rules.save_slot_classes[]`, `campaign.rules.autosave_rules[]` | `B1-LEDGER` | `campaign_rules` | Authored manual slot classes and independent trigger-owned autosave pools. | Classic 3 between-map + 1 consumed mid-map; one `battle_end` keep-1 autosave rule. Empty autosave list disables automatic writes. | `CampaignRules` / `SavePolicy` adapters via `SaveData` | Policy does not alter checkpoint contents. | Restored before save/load UI enforcement and trigger dispatch. | `campaign_carry`, `codec_roundtrip`, `reference_validation` | `v1` | B1-LEDGER Phase 5; campaign rules guide. |
| `suspend.kind` | `[CST-8]` | `transient_suspend` | Set while an in-progress map/dialogue/prep resume exists; cleared on normal completion. | Null. | Suspend adapter via `SaveCodec` | Not applicable. | Restored. | `suspend_restore`, `codec_roundtrip` | `v1` | Campaign save plan. |
| `suspend.cursor_tile`, `suspend.mode` | `[CST-8]` | `transient_suspend` | Resume-only cursor and active mode state. | Null. | Suspend adapter via `SaveCodec` | Not applicable. | Restored. | `suspend_restore` | `v1` | Campaign save plan. |
| `suspend.watch_set`, `suspend.danger_mode` | `[TUR-4]`, `[MRD-1]` | `transient_suspend` | Threat watch-set and danger overlay mode survive mid-map suspend only. | Empty watch set and `none` danger mode. | MRD suspend adapter via `SaveCodec` | Not applicable. | Restored. | `suspend_restore`, `map_reset` | `v1` | Map-readability register; B6-MRD. |
| `settings.*` | SettingsManager | `settings` | Global player settings are stored outside campaign saves. | SettingsManager defaults. | `SettingsManager` | Not applicable. | Not applicable. | `no_save_guard` | `explicit_no_save` | Display/settings guide. |
| `no_save.authoring.aoe_shapes_target_filters` | F16 / action-effect owners | `authoring_data` | Authoring data only. | Not serialized. | None. | Recomputed from loaded content. | Recomputed from loaded content. | `no_save_guard` | `explicit_no_save` | F1 source inventory. |
| `no_save.authoring.requirements` | `[REQ-1..16]` | `authoring_data` | Predicate data reads saved state but is not itself saved. | Not serialized. | None. | Recomputed from loaded content. | Recomputed from loaded content. | `no_save_guard` | `explicit_no_save` | Requirement/predicate register. |
| `no_save.dialogue.atomic_playback` | `[DLG]` | `transient_suspend` | Atomic dialogue playback has no field except `suspend.conversation_resume`. | Not serialized. | None. | Cleared. | Cleared unless the conversation resume block exists. | `no_save_guard` | `explicit_no_save` | Dialogue register. |
| `no_save.authoring.shop_stock_pricing` | `[SHP]`, `[SAC]` | `authoring_data` | Shop stock, labels, and pricing rules live in campaign content. | Not serialized. | None. | Recomputed from loaded content. | Recomputed from loaded content. | `no_save_guard` | `explicit_no_save` | Shop/activate register. |
| `no_save.ui.phb_panel_state` | `[PHB]` | `transient_suspend` | Prep-hub panel UI state is session UI; transactions commit to party/roster fields. | Not serialized. | None. | Cleared. | Cleared unless a future prep suspend explicitly reserves a field. | `no_save_guard` | `explicit_no_save` | Prep-hub register. |
| `no_save.skills.secondary_movement_duplicate_state` | `[SMV]` | `derived` | Secondary movement rides granted-skill persistence; no separate field. | Not serialized. | None. | Recomputed from skills. | Recomputed from skills. | `no_save_guard` | `explicit_no_save` | Secondary-movement register. |
| `no_save.derived.visible_tiles` | `[FOW-5]` | `derived` | Visible tiles derive from unit positions and LoS each frame. | Not serialized. | None. | Recomputed. | Recomputed. | `no_save_guard` | `explicit_no_save` | Fog-of-war register. |
| `no_save.arena_mid_fight` | `[BEA]` | `transient_suspend` | Arena resolves atomically before returning to prep; no mid-match save. | Not serialized. | None. | Cleared. | Cleared. | `no_save_guard` | `explicit_no_save` | Bonus EXP / arena register. |
| `no_save.derived.class_skill_availability` | `[SKL]` | `derived` | Class skill availability derives from class and level. | Not serialized. | None. | Recomputed. | Recomputed. | `no_save_guard` | `explicit_no_save` | Skill register. |
| `no_save.derived.loadout_cap_modifiers` | `[LDC-7/8]` | `derived` | Held/class/flag cap modifiers recompute; only permanent consumed-item modifiers save. | Not serialized. | None. | Recomputed. | Recomputed. | `no_save_guard` | `explicit_no_save` | Loadout-cap register. |
| `no_save.authoring.content_definitions` | Registry-owned content | `authoring_data` | Definitions for classes, items, stats, conditions, profiles, and maps are referenced by id. | Not serialized. | None. | Recomputed from loaded content. | Recomputed from loaded content. | `no_save_guard`, `reference_validation` | `explicit_no_save` | F1 lock design. |

## Follow-Up Fixture Names

`B1-SAVECODEC` and `B1-CST` are responsible for turning the fixture keys above
into concrete tests:

- `test_save_codec_unit_roundtrip`
- `test_save_codec_inventory_entry_roundtrip`
- `test_save_data_campaign_roundtrip`
- `test_save_data_old_save_defaults`
- `test_retry_uses_save_codec`
- `test_suspend_map_runtime_roundtrip`
- `test_map_runtime_resets_on_completion`
- `test_reference_validation_unknown_ids`
- `test_no_save_derived_fields`
