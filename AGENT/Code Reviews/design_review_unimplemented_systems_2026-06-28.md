---
Role: dated
---

# Design Review - Unimplemented Planned Systems (2026-06-28)

**Scope:** documentation/design review only. Current snapshot:
`docs-reorg-2026-06-23` at `ed91d59`, clean worktree before this report. Reviewed
active design/planning/register material under `AGENT/Docs`, the roadmap, and the
latest session note. This report intentionally does **not** change any plans,
registers, roadmap items, GDD chapters, or scheduling.

**Review lens:** code-review style risk triage for design work that has been
decided or scheduled but not implemented. I looked for architectural gaps, bad
assumptions, likely consolidation points, and places where the current plans can
produce duplicated code or contradictory behavior when implementation resumes.

## Executive Summary

Overall design health is good: the project has converged on the right broad
shape - data-driven authoring, reusable primitives, one pipeline for similar
actions, and explicit save/schema ownership. The main risk is that many of those
"shared" primitives are currently prose agreements, not implementation contracts.
If implementation starts feature-by-feature before those contracts are made
concrete, the codebase will likely grow several parallel action runners, preview
systems, resource ledgers, map-object lifecycles, and authoring registries.

Highest-risk items to settle before major feature builds:

1. Turn the F1 save lock into a field-owned schema manifest and fixtures.
2. Define one action/effect execution contract across MET, DLG, SAC, STY, TCV,
   DTR, FOW, and shop/panel triggers.
3. Define one projection/forecast API used by F5, combat, AI valuation,
   perception masking, interceptors, and UI preview.
4. Replace older closed vocabulary plans with open registry manifests.
5. Introduce one resource/cost transaction resolver before shops, styles,
   battalions, training, redirects, and arena land.

**Foundation follow-up management:** shared-foundation findings from this review
are tracked in
`AGENT/Docs/design/design_review_foundation_fix_todo_2026-06-28.md`. That index
links each foundation problem to its managing design/contract doc for later
scheduling. L1 and L2 remain cleanup/navigation findings, not foundation docs.

## Findings

### H1 - The F1 save-schema lock is too broad to remain a prose reserve list

**Evidence:** the atlas says F1 is the foundation everything persists through
and explicitly warns to lock the reserved schema before builds reserve ad hoc
fields (`AGENT/Docs/plans/feature_dependency_atlas_2026-06-23.md:26`). Phase B
already lists dozens of fields across proficiency, equipped sources, styles,
conditions, relationship overrides, dialogue resume, story flags, battalions,
F14 stats, TCV variables, objective predicate refs, resource wallets, and more
(`AGENT/Docs/plans/feature_dependency_atlas_2026-06-23.md:367`). The save plan
also makes Retry depend on the same JSON-safe serializer as persistent saves
(`AGENT/Docs/plans/campaign_save_technical_plan_2026-06-21.md:61`), and CST
accepts one serializer for both Retry and save with a hard `test_save_codec`
obligation (`AGENT/Docs/registers/campaign_save_open_decisions_2026-06-21.md:89`).

**Problem:** the design correctly identifies F1 as the bottleneck, but the
schema is spread across many registers. That makes it easy to add fields without
clear owner, reset scope, migration rule, or test fixture.

**Impact:** mid-battle suspend, Retry, save/load, and campaign migration can
silently diverge. The worst case is a feature that works live but corrupts or
rewinds incorrectly because one transient counter, map latch, or per-unit field
was omitted.

**Recommendation:** before Phase C builds, create a single F1 schema manifest
artifact. Each field should record owner register, scope (`campaign`, `map`,
`unit`, `object`, `settings`, `transient-suspend`), reset rule, migration
default, serializer path, and test fixture. Treat the manifest as the thing that
locks F1, not the prose list alone.

**Walk note 2026-06-28:** accepted as an important Phase B concern, not a new
feature-plan change. Phase B was already expected to do much of this work, but
it should explicitly produce a **master F1 build document** where every schema
field/reservation is tracked at least in prose before implementation consumes
the schema.

### H2 - Action/effect execution is converging, but the shared contract is not concrete yet

**Evidence:** Source+Style defines one combat-like pipeline with `EffectSpec`
sets, per-effect `target_filter`, gates, combo costs, and multi-effect
resolution (`AGENT/Docs/registers/source_style_combat_model_2026-06-24.md:25`,
`AGENT/Docs/registers/source_style_combat_model_2026-06-24.md:32`). MET defines
trigger -> ordered action-list events and a `MapEventManager` that runs at a
deferred safe point (`AGENT/Docs/registers/map_events_triggers_open_questions_2026-06-21.md:52`,
`AGENT/Docs/registers/map_events_triggers_open_questions_2026-06-21.md:197`).
SAC makes `map_objects` activate actions open PHB panels and feed F16/F6 state
(`AGENT/Docs/registers/shop_activate_configs_open_questions_2026-06-27.md:34`,
`AGENT/Docs/registers/shop_activate_configs_open_questions_2026-06-27.md:59`).
TCV adds imperative `end_map` plus declarative objective predicate refs
(`AGENT/Docs/registers/typed_campaign_variable_store_open_questions_2026-06-27.md:66`).
DLG can run commands, including `shop`, inside conversations
(`AGENT/Docs/registers/shop_activate_configs_open_questions_2026-06-27.md:104`).

**Problem:** these all describe "engine primitives run from authored data", but
they do not yet share a concrete runner contract: execution context, subject
binding, safe point, transaction boundaries, previewability, rollback policy,
RNG policy, and result reporting.

**Impact:** implementation can accidentally create a MET action runner, a DLG
command runner, an activate runner, and a combat effect runner with slightly
different behavior. That will make scripted victories, shops, object breaks,
dialogue choices, event spawns, and effects hard to compose and test.

**Recommendation:** define a shared `ActionContext` / `EffectContext` contract
before building MET/DLG/SAC/STY integrations. Keep vocabularies distinct where
needed, but require all state-mutating primitives to declare: subjects, inputs,
safe point, validation, dry-run support, commit result, RNG access, and save
side effects.

**Walk note 2026-06-28:** accepted. The follow-up should be a **master
action/effect primitive contract document**, not a loose reminder scattered
through feature plans. Each danger-area implementation note - MET actions, DLG
commands, SAC activations/panel triggers, STY effects, TCV variable/objective
actions, DTR `on_break`, FOW object actions, and shop/panel side effects -
should point back to that master contract when those docs are next edited. The
goal is a shared mutation contract, not one merged vocabulary.

### H3 - Forecast/projection work is being specified in feature silos

**Evidence:** REQ-15 says condition outcome projection must delegate to F5 and
be shared by damage-preview UI and predicates
(`AGENT/Docs/registers/requirement_predicate_system_open_questions_2026-06-25.md:274`).
REQ then explicitly maps that pattern onto combat forecasting for AI valuation
(`AGENT/Docs/registers/requirement_predicate_system_open_questions_2026-06-25.md:292`).
PER-9/PER-10 add player-vs-AI forecast-fidelity channels and a hard rule that
perception filters only projection inputs, never `resolve_combat()`
(`AGENT/Docs/registers/perception_masking_open_questions_2026-06-27.md:131`,
`AGENT/Docs/registers/perception_masking_open_questions_2026-06-27.md:151`).
The atlas F5 row also pulls in source-bearing effect events and pure dry-run of
the interceptor pipeline (`AGENT/Docs/plans/feature_dependency_atlas_2026-06-23.md:30`).

**Problem:** F5 projection, `CombatResolver.forecast_outcome`, AI valuation,
perception filtering, redirect/cover dry-runs, and UI preview are all being
specified as adjacent requirements. There is no named projection service or
context object yet.

**Impact:** previews can diverge from resolution, AI can evaluate a different
outcome than the player sees, and interceptors/conditions can be double-counted
or skipped in dry-runs.

**Recommendation:** define one `ProjectionContext` layer before F5/VAL/PER/ICP
implementation. It should carry audience (`player`, `ai`, `debug`), fidelity
rules, hypothetical action, dry-run flag, RNG policy, and effect/interceptor
pipeline participation. `resolve_combat()` stays canonical; all forecasts call
the same projection layer.

**Walk note 2026-06-28:** accepted. Created the master contract at
`AGENT/Docs/design/projection_forecast_contract_2026-06-28.md`. Future F5,
VAL, PER/FOW, STY preview, interceptor/redirect/cover, and F16 projection-term
work should point back to that contract instead of creating separate forecast
rules.

### H4 - Older closed vocabulary plans conflict with the newer open-registry rule

**Evidence:** the current project instruction says author-facing extension
points should be open registries, not enum + match switches. EXT later ratifies
one model for author vocabularies: data-composition over engine primitive
registries, validated structurally at load
(`AGENT/Docs/registers/authoring_extensibility_open_questions_2026-06-26.md:13`,
`AGENT/Docs/registers/authoring_extensibility_open_questions_2026-06-26.md:92`,
`AGENT/Docs/registers/authoring_extensibility_open_questions_2026-06-26.md:127`).
But earlier AIP still documents a closed `_VALID_AI_PROFILES` list and tests
unknown strings against that list
(`AGENT/Docs/registers/ai_profiles_open_questions_2026-06-21.md:31`,
`AGENT/Docs/registers/ai_profiles_open_questions_2026-06-21.md:280`). STW also
calls for adding `"siege_weapon"` to a type-set guard
(`AGENT/Docs/registers/stationary_weapons_open_questions_2026-06-21.md:143`).

**Problem:** those older plans are understandable historically, but if built
literally they recreate the exact closed-enum smell the newer architecture
rejects.

**Impact:** adding content will require engine edits and test/check updates for
every new AI profile, activity type, object type, effect kind, or predicate.
That undermines the no-code authoring model and will slow v1 content creation.

**Recommendation:** when implementing each vocabulary, replace fixed const lists
with registry manifests and load-time registry validation. DoD#2 checks should
verify "all referenced ids resolve to a registry entry" and "registries declare
required primitive handlers", not "this hardcoded list contains every value".

**Walk note 2026-06-28:** user requested a specific problem/fix list for H4.
Created `AGENT/Docs/design/open_registry_conversion_checklist_2026-06-28.md`
as the saved review checklist. It enumerates the closed-vocabulary danger areas
and gives a recommended registry-shaped fix for each one.

### M1 - Resource/cost/accounting needs one transaction resolver

**Evidence:** Source+Style has additive and override combo costs
(`AGENT/Docs/registers/source_style_combat_model_2026-06-24.md:86`). Training
adds roster-shared wallets plus per-unit pools
(`AGENT/Docs/registers/training_halls_open_questions_2026-06-27.md:55`).
Battalions consume charges/rate limits/endurance and separate persistent state
from transient per-turn counters
(`AGENT/Docs/registers/battalion_attached_augment_open_questions_2026-06-25.md:137`,
`AGENT/Docs/registers/battalion_attached_augment_open_questions_2026-06-25.md:195`).
SAC/Shop adds dynamic pricing and conditional stock over a shopper subject
(`AGENT/Docs/registers/shop_activate_configs_open_questions_2026-06-27.md:92`).
THL reserves a party resource wallet and optional purchase counts
(`AGENT/Docs/registers/training_halls_open_questions_2026-06-27.md:91`).

**Problem:** the designs share the idea of multi-resource costs, but there is no
single transaction API yet for "can afford", "preview", "commit", "refund",
"overflow", "per-subject scope", and "partial failure".

**Impact:** shops, styles, training, battalions, arena bets, redirects, skills,
and item uses can each implement affordability and spending differently. That
will create UI mismatches and save bugs.

**Recommendation:** define one `CostResolver` / `ResourceLedger` primitive. It
should support party, per-unit, item/source, battalion, HP, uses, and future
custom scopes; dry-run and commit; atomic multi-resource costs; and a result
object the UI can render.

### M2 - `map_objects` is the right unification, but it needs a lifecycle/component interface

**Evidence:** SAC declares one unified `map_objects` model for doors, chests,
levers, switches, shops, arenas, panel triggers, and activatables
(`AGENT/Docs/registers/shop_activate_configs_open_questions_2026-06-27.md:34`).
Panel triggers reuse the same PHB panel UI from prep and on-map callers
(`AGENT/Docs/registers/shop_activate_configs_open_questions_2026-06-27.md:59`).
DTR turns breakables into real Units quarantined from roster systems and calls
that the main risk surface
(`AGENT/Docs/registers/destructible_terrain_open_questions_2026-06-21.md:114`).
STW rides the same object state and ammo model
(`AGENT/Docs/registers/stationary_weapons_open_questions_2026-06-21.md:117`).
FOW braziers are also `map_objects` with lit state.

**Problem:** "one `map_objects` model" is correct, but object types currently
imply different lifecycle needs: passability overlay, action menu labels,
activation, panel launch, ammo, lit state, broken HP, object-unit quarantine,
loot, and save state. Without a component contract, this can become one giant
type switch.

**Impact:** every new object type can require edits in DataManager, TileActions,
GridManager, GameMap, save code, and UI. Breakables are especially risky because
they are Units that must be excluded from many unit loops.

**Recommendation:** implement `map_objects` as registry-backed components:
`passability_provider`, `activatable`, `panel_trigger`, `vision_source`,
`attackable_object`, `state_serializer`, and `on_event`. Object types compose
components; they do not branch through one closed switch.

### M3 - Spawn/occupancy policy is known, but should become a shared occupancy transaction

**Evidence:** MET now records that `GameMap._spawn_unit` has no occupancy check
and that public spawn must use nearest-free/delay/skip behavior
(`AGENT/Docs/registers/map_events_triggers_open_questions_2026-06-21.md:113`).
The atlas repeats the same deferred code finding and calls for DataManager
validation plus spawn occupancy policy
(`AGENT/Docs/plans/feature_dependency_atlas_2026-06-23.md:401`). PER-8 also
allows masked units to be treated as passable/empty to unaware units, then
resolve overlap through DSP/Pair-Up style machinery
(`AGENT/Docs/registers/perception_masking_open_questions_2026-06-27.md:111`).

**Problem:** spawn, displacement, carry, hidden occupancy, breakable object units,
and pathfinding all need to mutate or query occupancy under special rules.

**Impact:** double-occupancy bugs and hidden blocked tiles will be hard to debug
if every system calls `tile_position = dest` directly.

**Recommendation:** promote `DisplacementService.relocate` / occupancy mutation
into the only legal path for non-move placement, including spawn, drop, forced
movement, hidden overlap resolution, and object-unit placement.

### M4 - The designer authoring contract is still open while many schemas assume it

**Evidence:** the campaign-save framing document says 4a-4e authoring is the
open frontier and still has no firmed authoring contract/register
(`AGENT/Docs/design/campaign_save_expectations_and_foundations_2026-06-23.md:84`,
`AGENT/Docs/design/campaign_save_expectations_and_foundations_2026-06-23.md:113`).
GDD_10 also calls out the designer/authoring half as open and deferred behind
finishing player-facing features
(`AGENT/GDD/GDD_10_Roadmap.md:163`).

**Problem:** many feature schemas are being designed with eventual GUI/builder
support in mind, but the authoring contract has not stated what must be easy,
validated, previewable, copied, imported, or generated.

**Impact:** implementation may optimize for engine convenience and later force
the editor to expose awkward nested dictionaries, unstable ids, or hard-to-debug
validation errors.

**Recommendation:** before the unified GDD/build schedule, do a thin authoring
contract pass: stable ids, registry manifests, copy/fork/resync behavior, schema
versioning, validation error shape, preview/test hooks, and what the GUI must
generate without hand-editing.

### M5 - Difficulty is spread across variants, variables, AI, fog, and forecast fidelity

**Evidence:** DIF defines difficulty as authored content variants plus bundles
of tuning presets, not a built-in stat formula
(`AGENT/Docs/registers/difficulty_death_mode_open_questions_2026-06-27.md:46`).
TCV generalizes tunables into a typed variable registry and tag-scoped effects
(`AGENT/Docs/registers/typed_campaign_variable_store_open_questions_2026-06-27.md:44`,
`AGENT/Docs/registers/typed_campaign_variable_store_open_questions_2026-06-27.md:52`).
FOW keeps AI knowledge/fog as a future CampaignRules dial
(`AGENT/Docs/registers/fog_of_war_los_open_questions_2026-06-21.md:106`).
PER adds two forecast-fidelity channels for player and AI
(`AGENT/Docs/registers/perception_masking_open_questions_2026-06-27.md:131`).

**Problem:** these are all valid difficulty levers, but there is no single
player-facing `DifficultyProfile` manifest that says what a difficulty actually
changes.

**Impact:** authors can accidentally stack changes in multiple places, and
players may not understand what "Hard" means. It also complicates save migration
because difficulty might select content, vars, AI, fog, forecast fidelity, and
resource rates at once.

**Recommendation:** model difficulty as a manifest that references content
variant, TCV preset bundle, AI profile overlay, fog/perception rules, economy
multipliers, death-mode offering, and player-facing summary text.

### M6 - Self-contained content packs need a future resync/compatibility policy before public authoring

**Evidence:** ICO chooses fully self-contained campaign packs, accepting content
duplication and no central patch propagation
(`AGENT/Docs/registers/campaign_content_overlay_open_questions_2026-06-23.md:51`).
The version stamp becomes provenance only, with no runtime load gate
(`AGENT/Docs/registers/campaign_content_overlay_open_questions_2026-06-23.md:107`).
All content is copied to `user://` and raw-loaded through one path
(`AGENT/Docs/registers/campaign_content_overlay_open_questions_2026-06-23.md:126`).
The deferred list includes the resync-from-defaults tool
(`AGENT/Docs/registers/campaign_content_overlay_open_questions_2026-06-23.md:187`).

**Problem:** the portability tradeoff is sound for runtime, but public authoring
will need a support story for default-content fixes, stale starter palettes, and
broken user copies.

**Impact:** bugs fixed in the shipped default content will remain in forked
campaigns unless authors manually resync. Support/debug reports will be noisy
unless packs clearly report their fork provenance and schema/content version.

**Recommendation:** do not block gameplay v1 on a full resync tool, but make the
compatibility/resync policy a release gate for the campaign builder/public
authoring milestone.

### M7 - Death/lifecycle consolidation is strong, but must be mechanically enforced

**Evidence:** DTH correctly requires one `handle_death(ctx)` funnel plus a
`DeathDisposition` resolver, and explicitly says condition ticks, hazards, and
ring-out must route through it
(`AGENT/Docs/registers/death_inventory_disposition_open_questions_2026-06-27.md:132`).
It also makes simultaneous death snapshot-then-resolve deterministic
(`AGENT/Docs/registers/death_inventory_disposition_open_questions_2026-06-27.md:124`).

**Problem:** this is exactly the kind of rule that rots if it stays prose-only.
New death causes will arrive from F5, DSP, terrain, MET/script, redirect/cover,
arena, and battalion host-death.

**Impact:** inventory, key-item custody, EXP credit, objectives, and battalion
detach behavior can diverge depending on how a unit died.

**Recommendation:** when the second death cause lands, add the DoD#2 check the
register already suggests: no direct death/disposition path outside
`handle_death(ctx)` and `DeathDisposition`.

### L1 - STW has a direct contradiction in its test notes

**Evidence:** STW-3 resolves to move-and-fire allowed with no MOVED-state gate
(`AGENT/Docs/registers/stationary_weapons_open_questions_2026-06-21.md:98`,
`AGENT/Docs/registers/stationary_weapons_open_questions_2026-06-21.md:147`).
The test notes still say "A unit that moved can't fire"
(`AGENT/Docs/registers/stationary_weapons_open_questions_2026-06-21.md:158`).

**Problem:** the test note contradicts the resolved behavior.

**Impact:** an implementer could write the wrong test or add the rejected gate.

**Recommendation:** when plans are next edited, change the STW test note to
assert move-and-fire is allowed, and that the siege range disappears after the
unit leaves the tile.

**Walk note 2026-06-28:** corrected the STW test note in
`AGENT/Docs/registers/stationary_weapons_open_questions_2026-06-21.md` to match
the resolved move-and-fire behavior.

### L2 - Some navigation docs are stale enough to mislead implementation

**Evidence:** GDD_10 still says "All other registers remain OPEN" in a block
that predates many resolved registers
(`AGENT/GDD/GDD_10_Roadmap.md:184`, `AGENT/GDD/GDD_10_Roadmap.md:204`). The
generated registry index has many of those later registers marked RESOLVED. GDD
also still lists the older critical path to campaign work as Package A -> save
spine -> DCH/AIP/FOW slices
(`AGENT/GDD/GDD_10_Roadmap.md:300`), while the later atlas adds a larger Phase A
and Phase B foundation lock.

**Problem:** this is not a design flaw by itself, but it creates ambiguity about
which document is authoritative.

**Impact:** contributors can schedule or implement from outdated roadmap text
instead of the later register/atlas state.

**Recommendation:** leave it untouched for now per this review's scope. During
the later unified GDD pass, explicitly retire or supersede stale navigation text
instead of trying to patch every older statement in place.

**Walk note 2026-06-28:** added
`AGENT/Docs/plans/unified_gdd_pass_followups_2026-06-28.md` as a discoverable
planning note for the unified GDD/v1 pass.

## Scheduled / Not Implemented Inventory

**Near-term execution already scheduled elsewhere:** Package A/RngService is the
execution gate for the save spine and deterministic systems. GDD_10 still names
Package A -> campaign/save -> DCH/AIP/FOW save slices as the campaign critical
path (`AGENT/GDD/GDD_10_Roadmap.md:300`).

**Phase A foundation setup in the atlas:** F2 ItemDef, F3 proficiency, F4
CampaignRules profiles, F5 conditions, F6/TCV variables, F7 resource pools, F8
MET, F9 PHB, F10 secondary movement, F11 skill effect ids, F12 grant/revoke, F13
text indirection, F14 stat registry, F15 dialogue, and F16 requirements are all
decided or mostly decided but not built
(`AGENT/Docs/plans/feature_dependency_atlas_2026-06-23.md:24`).

**Phase B save lock:** the concrete schema must reserve the large Phase B list
before builds proceed (`AGENT/Docs/plans/feature_dependency_atlas_2026-06-23.md:367`).

**Phase C deferred code findings to check during builds:** `on_level_up` trigger
not wired, raw `randi()` in random growths, and `_spawn_unit` lacking occupancy
guards (`AGENT/Docs/plans/feature_dependency_atlas_2026-06-23.md:385`).

## Positive Observations

- Source+Style is a good consolidation. It prevents separate combat-art,
  gambit, staff, capture, and utility-action pipelines
  (`AGENT/Docs/registers/source_style_combat_model_2026-06-24.md:59`).
- PHB/SAC dual-surface is the right model: one panel UI, surfaced from prep or
  map triggers (`AGENT/Docs/registers/shop_activate_configs_open_questions_2026-06-27.md:59`).
- DTH's single death funnel and snapshot-then-resolve rule are strong and should
  prevent a whole class of item/key-objective bugs if enforced
  (`AGENT/Docs/registers/death_inventory_disposition_open_questions_2026-06-27.md:124`).
- EXT's no-code, registry/composition model is the correct authoring boundary
  for self-contained packs (`AGENT/Docs/registers/authoring_extensibility_open_questions_2026-06-26.md:30`).
- The atlas is doing useful dependency work. It is already surfacing code gaps
  at the point they matter, instead of hiding them in feature docs
  (`AGENT/Docs/plans/feature_dependency_atlas_2026-06-23.md:385`).

## Recommended Triage Order

1. F1 schema manifest and serializer fixtures.
2. Author-facing registry manifest pattern and DoD#2 guard.
3. Shared action/effect execution contract.
4. Shared projection/forecast context.
5. Resource ledger/cost transaction primitive.
6. `map_objects` component lifecycle and occupancy transaction.
7. Designer authoring contract 4a-4e.
8. Then the unified GDD/v1 definition/build schedule.

## Assumptions / Limits

- I did not run the game or inspect every implementation file; this is a design
  and architecture review grounded in the current docs/registers.
- I treated generated indexes as navigation and registers/atlas as the stronger
  design source when roadmap prose was stale.
- I did not edit any plan, GDD, roadmap, register, or generated index.
