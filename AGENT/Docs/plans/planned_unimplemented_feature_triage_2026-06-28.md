---
Type: plan
Status: Active - planning input
Last verified: 2026-06-29
---

# Planned / Unimplemented Feature Triage

**Started:** 2026-06-28. Initial sorting pass before the unified GDD/v1
definition and build schedule.

**Purpose.** This document compiles planned-but-unimplemented work and gives an
initial triage by size, dependencies, and likely v1 need. It is not the final
v1 scope decision and does not supersede the feature registers.

**Primary inputs.**
- [`feature_dependency_atlas_2026-06-23.md`](feature_dependency_atlas_2026-06-23.md)
- [`design_review_foundation_fix_todo_2026-06-28.md`](../design/design_review_foundation_fix_todo_2026-06-28.md)
- [`f1_save_schema_lock_design_2026-06-28.md`](../design/f1_save_schema_lock_design_2026-06-28.md)
- [`minigame_scripting_runtime_research_2026-06-28.md`](../design/minigame_scripting_runtime_research_2026-06-28.md)
- [`minigame_activity_type_initial_specs_2026-06-28.md`](../design/minigame_activity_type_initial_specs_2026-06-28.md)
- `AGENT/Docs/REGISTERS.md`
- `AGENT/GDD/GDD_10_Roadmap.md`

## Reprioritization Decisions - 2026-06-28

This pass turns the initial triage into the scheduling input for the unified
GDD rewrite. Use these decisions unless the owner explicitly changes the v1
definition.

| Decision | Outcome | Why it matters |
|---|---|---|
| V1 center of gravity | Bands 1-5 below are the conservative v1-core path. Band 6 is v1-lean/stretch. Bands 7-8 are optional, deferred, or parked. | Keeps the new GDD from treating every firmed design as a v1 promise. |
| F1 before feature consumers | Package A, F1 manifest lock, SaveCodec, and the campaign spine precede any feature that adds persistent state. | Prevents ad-hoc fields and migration debt before the first real campaign save. |
| Shared services before feature forks | Registries, action/effect primitives, resource ledger, occupancy, death lifecycle, and projection are build gates for their consumers. | Avoids per-feature runners and closed type-switches. |
| Campaign sharing/exporting | Campaign packaging/import/export is in v1 and belongs on Band 6 after the campaign/save spine exists. | Sharing campaigns is part of the first stable campaign promise, but it depends on the save/content-pack load seams. |
| Activity seam | Side activities are not needed for v1. `ActivityRegistry` / `ActivityRunner` and templates move to Band 8 parked unless the owner later changes scope. | The core campaign should not pay for side-activity infrastructure or public scripting. |
| Calendar-lite counters | Keep `total_maps_played` and `story_maps_played` as optional TCV-readable built-ins, built with F6/TCV only if v1 content uses map-count cadence. | Gives gardens/restocks/territory pressure a generic hook without adding a calendar system. |

## Dependency Rules For Scheduling

| Rule | Applies to |
|---|---|
| New author-facing vocabulary uses an open registry, not a closed enum/list plus `match`. | Objectives, AI profiles, map objects, activities, effects, stats, resource types, difficulty, predicates. |
| New save state must have an F1 manifest row before implementation. | Any campaign, roster, party, map runtime, object runtime, or suspend field. |
| State-changing authored actions route through the action/effect primitive contract. | MET actions, DLG commands, SAC activations, STY effects, shops, objectives, TCV actions. |
| Costs and wallets route through the resource ledger. | Shops, training, arena, style/source costs, battalion charges, item uses, dynamic pricing. |
| Non-standard placement routes through occupancy transactions. | Spawn, reinforcements, forced movement, carry/drop, hidden overlap, object-unit placement. |
| Every death cause routes through `handle_death(ctx)` and `DeathDisposition`. | Combat, F5 ticks, hazards, ring-out, scripts, arena, cover/redirect, battalion host death. |
| Forecasting delegates to the projection service. | Combat preview, F5 ticks, AI valuation, perception masking, source/style effects, F16 projection terms. |
| Side activities use `launch_activity` through the activity seam when scheduled. | Prep panels, on-map activation, dialogue commands, and MET/story calls that start an activity. |

## Triage Labels

| Label | Meaning |
|---|---|
| `V1-blocker` | Needed before broad v1 feature/content builds can proceed safely. |
| `V1-core` | Strong candidate for v1 because many planned features depend on it or it defines the core game loop. |
| `V1-lean` | Likely v1 if schedule allows; meaningful player value but not always foundational. |
| `V1-optional` | Can ship later without breaking the core campaign promise. |
| `Post-v1` | Better after the first stable campaign release. |
| `Parked` | Keep documented, but do not schedule until a later triage/owner decision. |

## Critical Foundation Track

Build or lock these before feature clusters start consuming their state.

| Item | Size | Dependencies | Initial need | Notes |
|---|---:|---|---|---|
| Package A / `RngService` | M | none | V1-blocker | Gates deterministic save/suspend/rewind, random growth migration, and future online correctness. |
| F1 save schema lock | L | Package A sequencing; source inventory | V1-blocker | Lock manifest before Phase C builds. Use the F1 inventory + lock design as the build contract. |
| Save/Campaign cluster `[CST]` | L | Package A, F1 | V1-blocker | Campaign loop, SaveManager, SaveData, CampaignRules consolidation, prep/victory/defeat/suspend. |
| Registry manifest contract | M | F1, DataManager | V1-blocker | Needed to avoid closed enum/match growth across objectives, AI, effects, stats, resources, activities, and difficulty. |
| Action/effect primitive contract | M/L | registry manifest, F8, F11 | V1-blocker | Prevents separate MET/DLG/SAC/STY runners. Should precede state-mutating feature builds. |
| Resource ledger / cost resolver | M | F7, F1, action/effect | V1-blocker | Shops, training, styles, battalions, arena, redirects, and resource costs need one transaction API. |
| Map-object component contract | M | registry manifest, occupancy, F8 | V1-core | Doors, chests, shops, arenas, levers, breakables, braziers, stationary weapons. |
| Occupancy transaction service | M | map/grid, displacement | V1-core | Spawn, forced movement, carry/drop, hidden overlap, object-unit placement. |
| Death lifecycle funnel | M | DTH, action/effect, F1 | V1-core | Required once conditions, hazards, arena, ring-out, battalion host-death, or scripted death exist. |
| Projection/forecast service | M/L | F5, combat, action/effect | V1-core | Keeps combat preview, AI valuation, perception, predicates, and interceptor dry-runs consistent. |
| Designer authoring contract | S/M | registry manifest, validation | V1-optional | Important for future builder, but not a blocker for hand-authored v1 data. |
| Content-pack compatibility/resync | M | campaign packaging, authoring | Post-v1 | Gate for public authoring, not core gameplay v1. |

## Foundation Systems

| Item | Size | Dependencies | Initial need | Notes |
|---|---:|---|---|---|
| F2 ItemDef + components | XL | F1 | V1-core | Centralizes weapons/items/accessories, story flags, per-instance runtime state. |
| F3 Proficiency / XP framework | L | F1, F4 | V1-core | Weapon/item/action proficiency, training, bonus EXP, arena progression. |
| F4 CampaignRules profile mechanism | S/M | F1 | V1-blocker | Cheap, high leverage: rank profiles, triangle, pool profiles, difficulty. |
| F5 ConditionManager | L | combat loop, F1 | V1-core | Needed by capture sleep, staves, status weapons, triangle conditions, projection. |
| F6/TCV typed variable store | L | F1, F8, F16 | V1-core | Story flags, tunables, objective predicates, difficulty variables. |
| F7 resource pools | M | F1, F2, F4 | V1-core | Spells, combat arts, skills, redirects, training resources. |
| F8 MET framework | L | map/grid, F6 | V1-core | Villages, spawns, story flags, triggers, object break actions, objective changes. |
| F9 PHB option-panel framework | M | F1 | V1-core | Prep hub services: shop, convoy, arena, bonus EXP, training, recruit prep. |
| Map-completion counters / calendar-lite cadence | S/M | F1, CampaignData progression, F6/TCV, MET | V1-optional | New triage note 2026-06-28. Track `total_maps_played` and `story_maps_played` as generic campaign counters for "complete after N maps" systems: garden/brewing station timers, activity restock cadence, and territory-pressure mechanics like encroaching armies. Prefer counters as TCV-readable built-ins, not a full calendar. |
| F10 Secondary Movement | M | action flow | V1-lean | FE-like staple and prerequisite for rescue interactions, but can be staged after core campaign spine. |
| F11 skill trigger/effect expansion | M/L | combat loop, action/effect | V1-core | Existing skill system needs effect ids and one exception sign-off for reactive reposition. |
| F12 dynamic skill grant/revoke | M | F11, F6 | V1-core | Story/event skills, item grants, skill shops, on-crossing grants. |
| F13 text indirection | S/M | F1 conventions, F15 | V1-core | Needed before dialogue/story text grows; multi-locale can defer. |
| F14 stat registry / extra stats | M | F1, F4 | V1-core | Charisma/Command/author stats, battalion bonuses, dynamic pricing formulas. |
| F15 dialogue/conversation | L | F13, F8, F16 | V1-core | Recruit, village, support, story scenes. Can ship a staged v1 slice. |
| F16 requirement/predicate system | L | F6, unit/convoy data, Package A for chance | V1-core | Gating for dialogue, MET, tile actions, recruit, shops, objectives, perception. |

## Items / Equipment / Economy

| Item | Size | Dependencies | Initial need | Notes |
|---|---:|---|---|---|
| Item/equipment composition build `[IEQ]` | XL | F1, F2, F3 | V1-core | Big staged migration; should land early because many item features stack on it. |
| Weapon-source / equip model `[CEX-20..24]` | L | F1, F2, STY | V1-core | Needed for learned spells, source/style, auto-equip fallback, universal source floors. |
| Learned spells | M | F1, F2, F7 | V1-lean | Strong FE-like value; can ride source/equip build once F7 exists. |
| Per-map-use items | S | F2, suspend runtime | V1-lean | Small, useful, and already designed; watch suspend counter state. |
| Story-item tracking + locks | S track / XL branch | F2, F6, MET | V1-core for tracking; branch later | Tracking/locks are core. Large branching content can grow later. |
| Convoy | M | F1, F9, IEQ | V1-core | Needed by death disposition defaults, prep, shops, inventory overflow. Detailed panel UI/UX should be designed at the start of the Band 3 convoy/shop slice, after F9/IEQ storage contracts are real enough to avoid throwaway screens. |
| Shop / economy | M | F1, F9, resource ledger | V1-core | Core prep service and on-map panel trigger consumer. Detailed panel UI/UX should pair with convoy UI because buy destination, overflow, sell, and distribution all cross the same inventory surface. |
| Forging | M | F2, shop/economy | Post-v1 | Useful but not required for first campaign stability. |
| Combat arts / weapon arts | M | F2, F7, F11, STY | V1-lean | Good player value, but waits on Source+Style and pools. |
| Bonus EXP | M | F3, F9, TCV | V1-lean | Valuable prep progression sink; not required for core map flow. |
| Arena | M | F3, F9, DTH, resource ledger | V1-optional | Good content, but death/economy interactions increase test surface. |
| Training halls | M | F3, F9, resource ledger, F14 | V1-optional | Powerful reuse surface; can follow convoy/shop/resource ledger. |

## Combat / Tactical Mechanics

| Item | Size | Dependencies | Initial need | Notes |
|---|---:|---|---|---|
| Source + Style pipeline `[STY]` | L | F2, F5, F7, F11, projection | V1-core | Consolidates combat arts, gambits, capture, staves, AoE, effect forecast. |
| Flexible weapon triangle | M + condition slice | F4, F5 | V1-lean | Strong identity feature; condition slice waits on F5. |
| Weapon effect-tag gaps | S each | F5, F11 | V1-lean | Poison/heal/ignore/always-hit can be staged per content need. |
| Item skill effect ids | S each | F11, IEQ | V1-core for existing items; optional beyond that | Implement only the ids needed by v1 content first. |
| Broken-weapon mode | S | IEQ, shop repair later | V1-optional | Designed; can defer if durability/breaking content is not central. |
| Stationary weapons | M | DCH/map_objects, AI profile, STY targeting | V1-optional | Build-ready but coupled to `siege_operator` and map object lifecycle. |
| Skill content M9b | L | F11, F5, projection | V1-core | Existing skill placeholders need real effects or pruning before v1. |
| Skill model expansion `[SKL]` | M | F11, F12, F6 | V1-core | Personal/class/granted skills affect progression and item grants. |
| Redirect / cover / reactive reposition interceptor family | M/L | F5 event, projection, F16 event subject, action/effect | V1-optional | Well-designed but complex; keep after core projection/action contracts. |
| Perception/masking | M | F16, projection, AI valuation | Post-v1 | Interesting but not needed for core campaign. |
| AI combat valuation / engagement brain | L | AIP first build, projection, F16 terms | V1-lean | Needed for smarter AI; v1 can start with a bounded scorer if schedule allows. |

## Map / Tactical Content

| Item | Size | Dependencies | Initial need | Notes |
|---|---:|---|---|---|
| Doors / chests `[DCH]` | S | map_objects, F1 map state | V1-core | Small, unlocks object state and many map interactions. |
| Destructible terrain `[DTR]` | M | DCH, death/action contracts | V1-lean | Good tactical content; object-unit quarantine must be enforced. |
| Fog of War / LoS | M | F1 discovered units, MET, map objects | V1-lean | Useful for campaign variety; symmetric AI/fidelity can stage. |
| Map events / triggers `[MET]` | L | F8, action/effect, F6 | V1-core | Required for villages, recruits, spawns, story branching. |
| Village / house visit | M | F8, F2, F6, F15 optional | V1-core | Classic map content; rides interactive-trigger substrate. |
| Map readability / individual threat range | M | UI/grid, suspend for watch set | V1-lean | Strong UX; some pieces already designed. |
| Spawn occupancy policy | S/M | occupancy transaction, MET spawn | V1-core | Needed before reinforcements; prevents double-occupancy bugs. |
| Grid topology / hex mode | L | grid seam | Parked | Documented thought experiment; not for v1 unless scope changes. |

## Unit Actions / Movement

| Item | Size | Dependencies | Initial need | Notes |
|---|---:|---|---|---|
| Dancer / refresh / action grant | M | F11, F12, action counters | V1-lean | High-value staple; requires action economy counter persistence for suspend. |
| Movement assists | M | occupancy/displacement, action flow | V1-optional | Shove/smite/pivot/swap are good tactics but can stage after core movement. |
| Rescue / carry-drop | L | F10, displacement, occupancy, death lifecycle | V1-lean | Owner previously marked firm; larger dependency surface than dancer. |
| Displacement / carry shared primitive | L | occupancy, STY, action/effect | V1-core if rescue/capture ships | Needed by rescue, capture-carry, shove, ring-out. |
| Utility staves | M | STY, F5, F11 | V1-lean | Strong FE staple; can build once Source+Style exists. |

## Roster / Campaign Flow

| Item | Size | Dependencies | Initial need | Notes |
|---|---:|---|---|---|
| Recruit / capture | L | F6, F8, F15, DSP | V1-core for recruit; capture can stage | Recruit is core campaign content. Capture is richer and depends on carry/sleep. |
| Support / relationship system | XL | F1, F13, F15, PXP hooks | V1-lean | High player value but large. Consider a minimal relationship graph before full support content. |
| Avatar / My Unit | L | F1, F13, relationships | V1-optional | Firmed, but story/UI cascade is large. Keep only if v1 identity depends on it. |
| Difficulty + Casual/Phoenix | M | F4, DTH, TCV | V1-core | Player-facing campaign rules and death mode should land before broad playtest. |
| PvP / scenario | M | standings, PHB, training, M15/online for network | V1-optional | Previously firmed, but not needed for single-player campaign v1. Hotseat-only slice could stage. |
| Battalions / gambits | L | F11, STY, Pair-Up attach, resource ledger, F14, DTH | V1-optional | Big, attractive feature; dependency-heavy. Consider post-core or a narrow v1 slice. |

## AI / Enemy Behavior

| Item | Size | Dependencies | Initial need | Notes |
|---|---:|---|---|---|
| AI first build / composition engine | M/L | Package A, F1 `ai_awake`, registry pattern | V1-core | Needed for campaign maps beyond current simple profiles. |
| AI profile registry conversion | M | registry manifest, AIP | V1-core | Avoid closed `_VALID_AI_PROFILES` and profile `match` growth. |
| `siege_operator` profile | S/M | STW, AI composition | V1-optional | Required only if stationary weapons remain v1. |
| Combat AI valuation | L | projection, F16, AIP | V1-lean | Can stage after AI first build; improves quality but not schema blocker. |
| ML evaluation function | XL/unknown | AI valuation, deterministic model | Parked | Education/experiment; not product v1. |

## Dialogue / Authoring / Content Packs

| Item | Size | Dependencies | Initial need | Notes |
|---|---:|---|---|---|
| Dialogue v1 slice | L | F13, F15, F16, MET | V1-core | Needed for recruit/village/story. Keep v1 slice focused on line/choice/command. |
| Dialogue visual effects full set | M | F15 presentation registry | V1-optional | Presentation growth can follow the v1 dialogue slice. |
| ActivityRegistry / ActivityRunner seam | M | registry manifest, action/effect bridge, PHB/SAC/DLG/MET | Parked | Owner decision 2026-06-29: side activities are not v1. Keep the shared `launch_activity` bridge documented for later; do not schedule it for the core campaign. |
| Activity template prototypes: grid puzzle / QTE / card table | M/L | ActivityRunner; resource ledger for blackjack; StagePresentation optional | Parked | Feasibility prototypes only. Keep the templates as later validation evidence before public scripting: PuzzleScript-style grid puzzle, QTE/lockpick, blackjack/card-table. |
| Designer authoring contract | S/M | registries, validation | V1-optional | Useful before public builder, not before hand-authored campaign. |
| Public campaign builder / authoring GUI | XL | authoring contract, content-pack policy | Post-v1 | Do not schedule before gameplay v1 stabilizes. |
| Campaign self-contained packaging `[ICO]` | M | F1, DataManager load seam | V1-lean | Owner decision 2026-06-29: campaign sharing/exporting is in v1. Build after the campaign/save spine and include import/export validation in the control plane. |
| Content-pack compatibility/resync | M | packaging, authoring | Post-v1 | Public-authoring support gate, not core gameplay. |

## Platform / Tooling / Release Gates

| Item | Size | Dependencies | Initial need | Notes |
|---|---:|---|---|---|
| Input-mode resolver | M | SettingsManager, gamepad layer | V1-lean | Accessibility/platform value; build-ready. |
| Gamepad layer | M | input resolver, selector extraction | V1-lean | Important for Steam Deck/controller; not a content blocker. |
| Key rebinding UI | M | input persistence | V1-lean | Strong accessibility feature; can stage before wider release. |
| Shared selector extraction | S/M | UI surfaces | V1-lean | Reduces input wiring duplication; useful before gamepad. |
| Debug web playtest build | M | renderer/web preset | V1-optional | Useful distribution/testing path; not game-system v1. |
| Map sprite importer productionization | M | tooling | V1-optional | Speeds content production, but not required if maps can be authored manually. |
| Legal/licensing `[LEG]` | S | owner input | V1-blocker for public release | Must be done before distributing asset-containing public builds. |
| Public identity rename `[REN]` | S | owner input | V1-lean | Release polish/branding; not a systems blocker. |
| Online play / remote play | XL | deterministic core, suspend, networking | Post-v1 | Existing decisions remain useful, but build after single-player v1. |
| Apple Vision Pro reach | unknown | web/mobile polish | Parked | Revisit after Safari-verified web release. |
| M12 Laguz system | XL | combat/transform systems | Post-v1 | Large special system; defer. |
| M13 Awakening supplement | XL | broad content/system compatibility | Post-v1 | Large content/system pack; defer. |
| Arbitrary mini-game module / public scripting VM | XL/unknown | ActivityRegistry, content-pack trust policy, sandbox/VM decision | Parked | Do not schedule a general scripting VM for v1. Keep first-party scenes and validated templates ahead of public code. MiniScript/Wren-style VM remains evidence-gated after template prototypes. |

## Reprioritized Dependency Bands

This is a dependency order, not a calendar. A later band can be designed while
an earlier band is being built, but implementation should not consume a missing
foundation or add unmanifested save state.

| Band | Priority | Work | Exit check |
|---|---|---|---|
| 0 | Pre-GDD scope lock | Use this triage to set the unified GDD scope: Bands 1-5 = conservative v1-core, Band 6 = v1-lean/stretch, Bands 7-8 = optional/deferred/parked. | GDD rewrite has one scope table and one dependency table instead of copying old roadmap prose. |
| 1 | Determinism and save gate | Package A / `RngService`, F1 manifest lock, SaveCodec/SaveData, campaign envelope, CampaignRules/profile selections, old-save defaults. | No feature build adds state without an F1 row and fixture obligation. |
| 2 | Shared authoring/runtime contracts | Registry manifest bootstrap, action/effect primitive runner, resource ledger/cost resolver, occupancy transaction service, death lifecycle funnel, projection service slice, DataManager validation seams. | Consumers can call shared APIs; tests cover unknown ids, failed transactions, blocked placement, death routing, and no-mutation projection. |
| 3 | Core authoring foundations | F4 profiles, F6/TCV variables, F16 predicates/terms, F8 MET, F9 PHB panels, F13 text keys, F14 stat registry, F7 pools, calendar-lite counters only if v1 content uses them. | Story/event/economy/map content can be authored through registries and predicates, not one-off branches. |
| 4 | Campaign loop vertical slice | F2 IEQ + F3 PXP, roster/party inventory, convoy, shop/economy, map_objects/DCH, MET spawns/events, village/house visit, dialogue v1 line/choice/command slice, recruit basics, difficulty/death mode. | One short campaign loop can move map -> victory/defeat -> prep -> next map with save/suspend coverage. |
| 5 | Tactical v1 enrichment | F5 conditions, Source+Style, required skill effect ids/grants/loadout caps, utility staves, combat arts if selected, secondary movement, dancer/action grant, AI composition/profile registry, minimum combat AI improvement. | Core v1 maps have enough tactical variety without adding optional systems that multiply test surface. |
| 6 | V1-lean/stretch packs | Campaign sharing/export/import, rescue/carry/capture expansion, fog/LoS, destructibles, support/relationship minimum, bonus EXP, training halls, map readability, input resolver/gamepad/key rebinding. | Each slice has its prerequisites from Bands 1-5 and can be cut or staged, except campaign sharing/exporting is a v1 owner decision. |
| 7 | Optional after stable core | Arena, battalion/gambit narrow slice, stationary weapons, forging, PvP hotseat scenario, advanced AI valuation. | Schedule only after the campaign loop is stable enough to absorb extra permutations. |
| 8 | Post-v1 / parked | Side activities, ActivityRunner, activity templates, public campaign builder, public scripting VM, content-pack compatibility/resync, online play, perception/masking, hex topology, ML evaluation, Laguz, Awakening supplement, Apple Vision Pro/mobile reach. | Revisit after the first stable campaign release or an owner scope change. |

## Feature Priority Changes From The Initial Pass

| Feature/group | Previous lean | Reprioritized lean | Reason |
|---|---|---|---|
| `ActivityRegistry` / `ActivityRunner` | V1-optional, loosely grouped with post-v1 mini-games | Band 8 parked | Owner decision 2026-06-29: side activities are not v1. The seam is right later, but core campaign v1 should not pay for it. |
| Public mini-game scripting VM | Parked | Band 8 parked | Needs trust/sandbox/content-pack policy and evidence from first-party templates. |
| Shared contracts | Spread across Bands 0-1 | Band 2 gate | They are dependency reducers; building consumers first recreates the same closed-switch problem in several systems. |
| Calendar-lite map counters | V1-optional | Band 3 only when consumed | Counters should ride TCV as generic built-ins, not become a garden/restock-specific subsystem. |
| Designer authoring contract | V1-optional | Narrow validation/id rules in Bands 1-3; full editor contract post-v1 | Stable ids and validation help v1 content; public builder UX does not block the short campaign. |
| Campaign sharing/exporting | Conditional V1-lean | Band 6 v1 commitment | Owner decision 2026-06-29: include campaign sharing/exporting in v1 after the campaign/save spine exists. |
| AI valuation | V1-lean | Minimum scorer in Band 5; advanced valuation in Band 7 | Basic AI quality matters for v1 maps; deeper search/perception coupling can wait. |
| Training/bonus EXP/arena/PvP | Mixed V1-lean/optional | Bonus EXP/training can be Band 6; arena/PvP stay Band 7 | Training/bonus EXP reuse the economy/progression spine. Arena/PvP add separate balancing and death/economy cases. |

## Consolidation Guidance

1. Rewrite the GDD around the band split above, not the older milestone order in
   `GDD_10_Roadmap.md`.
2. In the new GDD, mark Bands 1-5 as the v1-core implementation path, Band 6 as
   scoped stretch, and Bands 7-8 as deferred unless the owner changes v1.
3. Update GDD_10 during consolidation so stale navigation points to
   `REGISTERS.md`, this triage, the F1 inventory/lock docs, and the shared
   foundation contracts.
4. Keep public authoring, online play, hex, large supplements, arbitrary
   mini-games, and the public scripting VM out of v1 by default.
