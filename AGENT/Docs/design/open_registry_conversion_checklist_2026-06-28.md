---
Type: design
Status: Active - review checklist
Last verified: 2026-06-29
---

# Open Registry Conversion Checklist

**Started:** 2026-06-28. Created from the H4 review walk in
`AGENT/Code Reviews/design_review_unimplemented_systems_2026-06-28.md`.

**Purpose.** This document lists each known closed-vocabulary danger area and
the recommended registry-shaped fix. It is a review checklist for future
implementation, not a rewrite of existing plans.

**Managed by:** [`design_review_foundation_fix_todo_2026-06-28.md`](design_review_foundation_fix_todo_2026-06-28.md).

**Master contract:** [`registry_manifest_contract_2026-06-28.md`](registry_manifest_contract_2026-06-28.md).

**Rule.** When a vocabulary can grow with authored content, adding content must
mean adding data to a registry or composition, not editing a GDScript enum,
constant list, or `match` branch. Engine releases may add new primitive
handlers, but campaign packs compose the primitives as data.

Primary sources:
- `AGENTS.md:11` - author-facing extension points are open registries.
- `AGENT/Docs/registers/authoring_extensibility_open_questions_2026-06-26.md:30`
  - chosen model = data-composition over engine primitives.
- `AGENT/Docs/registers/authoring_extensibility_open_questions_2026-06-26.md:96`
  - validate structurally against primitive registries.
- `AGENT/Docs/registers/authoring_extensibility_open_questions_2026-06-26.md:127`
  - one model for all author vocabularies.

## Checklist

| Area | Problem | Recommended fix |
|---|---|---|
| Objective conditions | `ObjectiveCondition.type` is a string dispatched by type-specific code; TCV calls this out as a closed enum that blocks predicate/flag objectives. | Add an `ObjectiveCondition` registry. Built-ins (`rout`, `seize`, `protect`, etc.) become registry entries with evaluator + display + validation metadata. Add the TCV `predicate`/`flag` condition as a registry entry, not a new hardcoded branch. |
| AI profiles | Existing AI dispatch uses `ai_profile` strings, `_VALID_AI_PROFILES`, and `EnemyAI._act()` branching. AIP's future list grows with content (`fog_scout`, `chest_looter`, `siege_operator`, `dancer`). | Build an `AIProfileRegistry` / `AISpec` resolver. Profiles are data presets over axes (activation, disposition, target policy, role action). Engine primitive planners are registered handlers. DataManager validates profile ids against the registry, not a fixed array. |
| `map_objects` object types | SAC says doors, chests, levers, shops, arenas, and panel triggers are all author-defined `map_objects`. STW's slice still says to add `"siege_weapon"` to a type guard. | Build a `MapObjectTypeRegistry` with component capabilities: passability, activatable, panel trigger, vision source, attackable object, ammo, state serializer. Validation checks each object type has valid components. Do not add one branch per object type. |
| Tile actions | `TileActions.ACTION_LABELS`, `_ACTION_ORDER`, and `is_available()` are closed around `seize`, `escape`, `shop`, `visit`, `activate`. SAC requires per-instance labels and multiple activatables on one tile. | Replace fixed tile-action lists with registered `TileActionProvider`s. Providers declare id, priority, label source, availability predicate, and commit action. Map-object `activate` entries provide labels from authored data. |
| MET triggers | MET starts with seed triggers and says later triggers are added on demand. If implemented as one fixed `match`, every new trigger edits the runner. | Add a `MapEventTriggerRegistry`. Each trigger type is a registered adapter over EventBus or a polling source, with parameter schema and subscription policy. Author events reference trigger ids. |
| MET actions / DTR `on_break` actions | MET action vocabulary grows from `reveal_tiles`/`flag`/`spawn` to `set_ai`, `light`, `set_relationship`, `set_var`, `end_map`, dialogue, loot, and more. DTR `on_break` shares it. | Add a `MapEventActionRegistry` whose handlers implement the action/effect primitive contract. Each action declares schema, safe point, subject needs, save side effects, and result ids. |
| Dialogue commands | DLG commands include scene ops and MET-like state mutations; SAC adds `shop` as a DLG command. Closed command branching would duplicate MET/SAC logic. | Add a `DialogueCommandRegistry`. Presentation commands route to DLG scene primitives; state-mutating commands delegate to the master action/effect primitive contract instead of custom dialogue-only mutation code. |
| Dialogue visual effects | DLG visual effects are explicitly author-extensible and add ids without changing format. | Add a `DialogueEffectRegistry` with presentation-only handlers, parameter schemas, playback modes, layer behavior, and validation. Keep it separate from state-mutation actions because presentation is determinism-exempt. |
| Source/Style effect kinds | `EffectSpec.kind` lists `strike`, `heal`, `teleport`, `fetch`, `repair`, `cure`, `inflict`, `bolster`, `displace`, and will grow. | Add an `EffectKindRegistry`. Each kind declares target needs, payload schema, projection support, commit handler, allowed gates, and interaction with cost/RNG. Source/style data references kind ids. |
| Target filters | `target_filter` values like `enemy`, `ally`, `self`, `empty_tile`, `weapon_holder`, `any`, and future filters can grow. | Add a `TargetFilterRegistry` or predicate-backed target filter layer. Built-ins resolve through faction relationships and context subjects. Custom filters should compose F16 predicates where possible. |
| AoE / shape generators | STY lists shape names (`single`, `multi`, `blast`, `line`, `cone`, `cross`, `rectangle`, `all_matching`) and future topology/LoS variants. | Add a `ShapeRegistry` with geometry handler, parameter schema, grid-topology support, preview metadata, and deterministic target order. Do not hardcode shape switches in every targeting caller. |
| F5 condition ids and condition effect kinds | F5 is planned as author-extensible `ConditionData`, but implementation could still hardcode poison/sleep/silence branches. | Build `ConditionData` as the registry entry. Condition effect primitives (`stat_modifier`, `damage_over_time`, `action_lock`, tag/immunity) are registered handlers. Individual conditions are data. |
| F16 predicates | REQ defines a typed predicate vocabulary and arithmetic terms. This is already the model to copy. | Implement F16 as `PredicateRegistry`, `TermRegistry`, and `OperatorRegistry`. Built-in predicates are primitive handlers; author-defined requirements are named data compositions. Validate arity, subjects, types, and complexity budget. |
| Objective custody / key-item predicates | DTH adds key-item custody objectives and TCV routes them through predicate/flag objective conditions. | Implement custody as a query primitive exposed to F16/ObjectiveCondition registry. Do not add a new objective-specific evaluator for each custody state. |
| Stat names | STM identifies hardcoded stat lists (`STAT_KEYS`, `_GROWTH_STATS`, UI label dicts, `_VALID_STATS`). | Build the F14 stat registry: `legacy_stats + registry.stats`. Growth, caps, level-up, UI labels, validation, and formula terms iterate the registry. Add a guard against new direct base-stat field reads where registry access is required. |
| Movement types and vulnerability groups | Movement types are enforced by `GameConstants.VALID_MOVEMENT_TYPES` and `check_docs.py`; vulnerability groups and weapon effectiveness still use fixed lists and tag switches. | Build separate movement-type and vulnerability-group registries. Classes declare one movement type and any vulnerability groups as data. Weapons declare `effective_against` vulnerability groups. Existing ids and multipliers ship as developer presets. |
| Resource types and cost scopes | SHP and THL move from `party_gold` toward resource-keyed costs, roster wallets, and per-unit pools. | Add a `ResourceRegistry` and `CostResolver`. Resources declare id, scope, display, default, bounds, persistence, and spend/refill policy. Costs reference `{resource_id, scope}` and commit through one transaction API. |
| Proficiency tracks and rank profiles | PXP replaces fixed WEXP tracks/ranks with track ids and named rank profiles, but current code validates against hardcoded WEXP tracks. | Build a `ProficiencyTrackRegistry` plus F4 rank-profile registry. Legacy weapon tracks are seeded data. Items, skills, styles, and battalions declare tracks through data. |
| Skill / item / source effect ids | `SkillData.effect_id`, item `effect_id`, style grants, and on-crossing events will keep growing. | Add a shared effect-handler registry by domain: skill effects, item effects, action effects. Validation checks ids resolve to a handler with a declared schema. Grant/revoke, secondary movement, action-grant, and stat gains should be handlers, not ad hoc switches. |
| Activity / panel types and mini-games | SAC explicitly warns not to hardcode panel/activity types and proposes scene-backed activities. | Add an `ActivityRegistry` where built-in panels and future mini-games both register `activity_id -> scene/config/result bridge`. The shared `launch_activity` primitive must be callable from prep, map activations, dialogue commands, and MET story/map events. First-party scenes can ship now; modder code trust remains a separate future policy. |
| Difficulty variant bundles | DIF difficulty combines content variants, TCV presets, AI overlays, fog/perception rules, resource rates, and death-mode offerings. | Add a `DifficultyProfile` registry/manifest. Profiles reference other registries rather than hardcoding "normal/hard" branches. The player-facing summary is data generated from the profile. |
| Validation checks | Existing DoD#2 patterns sometimes say "add the value to the valid set guard." That is correct for fixed engine-only settings, but wrong for author-extensible content vocabularies. | For author-extensible vocabularies, DoD#2 checks should validate registry shape and references: every referenced id resolves, every registry entry has required handler/schema metadata, no unregistered primitive is used, and generated docs/indexes are updated. |

## Implementation Pattern

Use this pattern unless a feature proves it needs something narrower:

1. **Registry resource/data.** A manifest or `CampaignRules` registry declares
   ids, labels, parameter schema, defaults, and author-facing docs text.
2. **Primitive handler.** Engine code registers built-in handlers by id. A new
   primitive requires an engine release; a new composition does not.
3. **Composition support.** Authors can define named compositions/macros where
   EXT allows it, using existing primitives.
4. **Load validation.** DataManager validates unknown ids, wrong parameter
   shapes, missing subjects, bad references, and complexity limits at load.
5. **Runtime lookup.** Consumers ask the registry for the handler/composition;
   they do not `match` directly on author ids.
6. **Tests.** Each registry gets tests for valid built-ins, unknown ids,
   malformed params, composition expansion, deterministic ordering, and one
   representative new data-defined entry where possible.

## Fixed-List Exception

Closed enums/lists are still acceptable for engine-internal state that authors
do not extend, such as `TurnManager.UnitState`, input-mode internals, UI
settings enum rows, or hard platform/display choices. The smell only applies
when new campaign content would require editing the engine.

## Immediate Review Notes

- Treat this as a conversion checklist when implementing H4-related features.
- Do not edit older registers just to rewrite history. Add cross-reference
  notes when those docs are next touched for implementation.
- The first implementation of each registry should add the relevant DoD#2
  validation/check in the same change.
