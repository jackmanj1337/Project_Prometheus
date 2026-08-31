---
Role: topic
Topic ID: GDD-01-ARCHITECTURE
Last verified: 2026-08-31
---

# GDD_01 — Architecture & Project Structure

**Status:** Active architecture contract; runtime and data detail are split into the
companion GDD_01 contracts linked below.
**Last verified:** 2026-08-31
**Governance:** section template + status vocabulary in
`AGENT/Docs/governance/documentation_governance_2026-06-13.md`.

This entry chapter owns project composition, scene/autoload responsibility, extension
boundaries, and contributor-facing architectural constraints. Binding runtime behavior
lives in `GDD_01_Runtime_Contracts.md`; resource and serialization shapes live in
`GDD_01_Data_Contracts.md`. Feature chapters `GDD_02`–`GDD_08` own gameplay rules.

---

## Companion Contracts

- [Runtime contracts](GDD_01_Runtime_Contracts.md) — CampaignRules, determinism,
  snapshots, online boundaries, and service/API invariants.
- [Data contracts](GDD_01_Data_Contracts.md) — resource schemas, persistence fields,
  validation, and authoring invariants.

Display configuration and input behavior are owned by `GDD_07` and the display/settings
guide (`B6-INPUT` for remaining input work). Tactical camera behavior is owned by
`GDD_06 §Tactical Camera`. These contracts are linked instead of duplicated here.

## Cross-System Review and Documentation Consolidation

Status: **Planned**
Last verified: 2026-08-31

This section is the maintained plan for the cross-system architecture review and the
documentation consolidation. It deliberately lives in the GDD rather than creating
another plan, discussion, research, handoff, or update document. Git is the historical
record: once current obligations and decisions have been absorbed into the GDD and the
workspace tracker, superseded project documents are deleted instead of archived in a
second documentation tree.

### Review Boundary

The review follows one authored campaign from package data through validation,
activation, runtime state, scenes and services, save/load, and player-facing UI. It
checks these cross-system boundaries against code and against both campaign-pack repos:

1. package manifest/catalogue -> `DataManager` and registry admission;
2. registry/predicate declarations -> engine-owned primitive handlers;
3. authored actions -> validation, preview, commit, and save-field ownership;
4. campaign and battle state -> deterministic snapshot/save contracts;
5. shared services -> scene-local controllers and responsive UI surfaces;
6. engine authoring capability -> a selected, playable campaign-pack adopter.

The first inventory found 349 GDScript files, 104 named classes, 26 scenes, and 31
autoloads in the engine repo. The two external campaign-pack repos are predominantly
JSON data. This confirms that the primary architectural seam is not repo-to-repo code
reuse; it is the versioned data contract accepted by the engine. The review must
therefore identify every place where a campaign feature still requires an engine edit,
where two services own the same mutation, or where an engine extension point lacks a
real pack adopter.

### Unified Authored Effect Pipeline

Status: **Target design** — specified as `EFX-1`–`EFX-28` in
[GDD_01 — Runtime Contracts](GDD_01_Runtime_Contracts.md)
Last verified: 2026-08-31

Every authored source that can inspect or change game state converges on one effect
execution contract. Items and skills are initial adapters, not privileged execution
paths. The same pipeline covers attack/weapon effects, applied and periodic condition
effects, traps, terrain and environmental hazards, map-object interactions, authored
story/dialogue events, objective/reward actions, campaign cadence actions, and effects
attached to economic operations such as a shop purchase.

The source owns **when and why** execution is requested. For example, combat owns hit
timing and attacker/defender context; a condition owns its turn/lifecycle trigger; a
terrain hazard owns entry/occupancy timing; a story event owns narrative sequencing;
and a shop owns its quote and purchase workflow. None of those sources owns a second
mutation language. Each submits an ordered, data-authored effect composition through
the shared runner.

The shared pipeline owns:

- registry resolution and parameter-schema validation;
- requirement/predicate evaluation and structured unmet reasons;
- target/subject resolution through an explicit context;
- deterministic preview or dry-run using the same definitions as commit;
- ordered composition, including declared stop/continue behavior on failure;
- mutation through engine-owned primitive handlers;
- structured results, touched save fields, presentation events, and diagnostics;
- deterministic RNG access, snapshot/rollback participation, and replay evidence.

Domain adapters retain only rules that are genuinely specific to their source:
inventory consumption and durability for items, trigger windows and use counters for
skills, hit resolution for attacks, duration/stack lifecycle for conditions,
activation/disarm state for traps, occupancy timing for terrain, and narrative
progression for story events. These adapters must not implement effect primitives that
another source could reuse.

Economic operations compose two distinct authorities. `ResourceLedger` continues to
own quote, affordability, and wallet mutation; the effect runner owns the purchased
outcome. A purchase coordinator prepares both, then commits them as one operation: a
failed payment applies no effects, and a failed required effect leaves no charge.
Optional post-purchase presentation is not part of the transaction. Goods represented
as inventory custody use the inventory/convoy service as their mutation primitive
rather than special shop-only state.

Conditions and requirements remain different concepts even though both use shared
registries. A requirement is a non-mutating predicate that answers whether an action is
available. A condition is durable gameplay state whose application, tick, expiry, and
removal are effects. Objective conditions should become compositions of the shared
requirement predicates; status conditions should become consumers of the shared effect
pipeline. This prevents the word "condition" from creating a second combined
predicate-and-mutation framework.

Migration is complete only when adding an authored effect composition for any listed
source requires data plus already-registered primitives, not a new source-specific
`match`, and when cross-source contract tests run the same primitive from at least an
item, a combat/condition source, and a map/story/economy source.

### Execution Sessions

Status: **Planned**
Last verified: 2026-08-31

These are bounded work sessions, not session-note documents. Outcomes go into commits,
this GDD section, and the canonical tracker. A session may stop earlier when a finding
changes the architecture, but it must not silently widen past its stated boundary.

#### Session 1 — Combat, item, and skill mutation inventory

Trace attacks, weapons, combat resolution, item use, skill triggers, previews, RNG,
direct state writes, registry dispatch, and save/snapshot participation. Record every
effect producer and mutation owner in the GDD. This is the first half of step 1.

Exit: every combat/item/skill path has a source, trigger, validator, preview path,
commit path, result shape, mutation target, and current tests identified.

Session 1 evidence inventory (in progress, 2026-08-31):

| Path | Source and trigger | Validation | Preview / projection | Commit and mutation owner | Result and persistence | Disposition |
|---|---|---|---|---|---|---|
| Direct-use items | `MapCursor` selects an `InventoryEntry`; `ItemMenu` and `ActionMenu` query availability; `ItemHandler` resolves `ItemData.effect_id`. | `DataManager` calls `ItemEffectRegistry.validate_item()` at load, while `ItemHandler.can_apply_item()` repeats runtime availability. Registry entries select separate validation and runtime handler ids. | `ItemEffectRegistry.preview()` calls a dedicated handler, but the built-in heal and stat-buff previews return only `{ok, mode}` and do not calculate affected values or touched fields. | `ItemHandler` owns dispatch and inventory consumption. Flat/full healing call `Unit.heal()` directly; stat buffs alone adapt to `ActionEffectRunner`; successful handlers then decrement or erase the inventory entry. | Item handlers return ad-hoc dictionaries with `ok`, `consume`, `mode`, and `error`. Only the stat-buff primitive produces an `ActionResult`, and `ItemHandler` discards its affected ids and `save_fields_touched`. Inventory/HP/modifiers persist through `UnitData`; no item-level transaction or rollback record binds effect and consumption. | **Migrate.** Keep item custody/consumption as the item adapter; move healing and every reusable outcome to shared primitives and return the shared structured result. |
| Promotion and reclass items | `MapCursor` opens a modal when the item preview reports `promotion` or `reclass`; `PromotionScreen` / `ReclassScreen` later perform the domain workflow. | Registry availability checks class/group eligibility or `can_use_second_seal()`. | Preview chooses a screen mode rather than projecting the outcome. Direct commit deliberately fails with `screen_required`. | The modal screens own the eventual class mutation and consumption rather than the item dispatcher. | The item registry cannot describe the modal transaction's affected fields or outcome; UI flow is part of execution ownership. | **Redesign as a coordinator.** The screen may gather a required choice, but the final class-change effect and item consumption need one commit boundary. |
| Triggered skills | `CombatResolver`, `TurnManager`, and future trigger owners call `SkillHandler.apply_trigger()` with mutable dictionaries. `SkillHandler` filters trigger, availability, Nihil, per-map/per-combat limits, and activation chance before `SkillEffectRegistry.execute()`. | `EntitySchemaRegistry` validates the effect id vocabulary. `SkillEffectRegistry` stores only handler and implemented flags; parameter validation is embedded independently in each handler or absent. | Combat passes `preview=true, dry_run=true`: random skills are omitted, deterministic handlers execute against live units/context, and `CombatResolver` later restores a hand-selected unit snapshot. There is no registry-level preview contract or structured forecast. | Individual handlers directly mutate `Unit`, `UnitData.active_modifiers`, or the caller's combat dictionary. `SkillHandler` itself commits use counters after a handler returns `true`. | The only handler result is a boolean. Affected ids, emitted events, touched save fields, diagnostics, and RNG draws are not reported. Per-map counters and active modifiers are durable save state; `_combat_skill_uses` is handler-local transient state. | **Replace dispatcher semantics.** Keep trigger scheduling, activation policy, counters, and Nihil in the skill adapter; execute reusable outcomes through shared requests/results. |
| Passive/query skills | `GridManager`, `Unit`, and combat calculations directly call `get_move_cost_override()`, `can_pass_through_enemies()`, `can_phase_through()`, `get_wexp_multiplier()`, and `get_staff_heal_bonus()`. | Each query scans `SkillData` and interprets effect ids/params itself. Several registered handlers are deliberately `_apply_query_only` and never execute. | Query return value is its own projection; there is no common context, unmet reason, or result. | These paths modify later calculations rather than state directly, but bypass `SkillEffectRegistry.execute()` and create a second skill vocabulary interpreter inside `SkillHandler`. | No shared evidence shape. Their effects become visible only in the consuming system's result or mutation. | **Separate declarative contributions from effects.** Retain pure queries as a stat/movement contribution seam, but stop representing them as executable handlers that intentionally return false. |
| Combat forecast | `ProjectionService` delegates to `CombatResolver.preview_combat()`; `project_exchange()` is a second, probabilistic projection API. | Inputs are assumed to be valid live unit nodes and equipped weapons. Combat formulas and skill handlers perform local checks. | `preview_combat()` applies deterministic skill handlers to live objects, then restores only HP, active modifiers, skill counters, and damage-taken. `project_exchange()` separately snapshots `_combat_skill_uses` and models ordered HP/durability branches. Random activations are excluded. | Intended to be non-mutating, but safety depends on every present and future skill mutation fitting the manually maintained snapshot. Context dictionaries are mutated during both paths. | Both return large ad-hoc dictionaries. Neither uses `ActionResult`, declares touched fields, or proves rollback completeness. | **Converge.** Preserve combat-specific forecast math, but make effect preview operate on an explicit state view or transaction rather than mutate-and-restore live nodes. |
| Combat resolution | Attack confirmation calls `resolve_combat()`, which emits `combat_started`, begins an RNG event, applies combat-start and per-strike skills, consumes skill counters, and builds exchanges. | Formula, range, target, and action legality are primarily established by upstream targeting; resolver checks are distributed through formulas and skill handlers. | Resolution simulates HP and durability locally but is not a dry run: skill handlers may already mutate live units and persistent counters. | `resolve_combat()` owns RNG draws, skill effects, and exchange construction. `apply_combat_result()` later owns weapon durability, HP/damage totals, wEXP, EXP, combat-modifier cleanup, RNG-chain commit, death lifecycle, and `combat_resolved`. | Resolver returns an ad-hoc dictionary containing exchanges, context, and RNG identity. The once-guard for RNG commit is written into that dictionary. No encompassing transaction reports every touched save field. | **Highest-priority boundary fix.** Resolution and application currently split one logical transaction after some live mutations have already committed. Prepare against isolated state, then atomically commit the accepted combat result and all attached effects. |

The existing `ActionEffectRunner` is a useful seed, not yet the shared contract. It
has typed `ActionRequest`, `ActionContext`, and `ActionResult` envelopes, registry-based
parameter/subject validation, and one `apply_active_modifier` primitive. It currently
has no composition request, requirement gate, preview result, rollback protocol,
transaction coordinator, RNG accounting, or handler registration seam beyond its one
hardcoded handler dictionary. `dry_run` returns validation success without projecting
an outcome. Only the item stat-buff path uses it in production.

The first confirmed collision is therefore three execution models rather than three
mere registries:

1. items select independent can-apply/preview/commit callables and return dictionaries;
2. skills mutate units and shared context dictionaries and return booleans;
3. combat forecasts by live mutation plus partial snapshot restoration, then divides
   committed work between `resolve_combat()` and `apply_combat_result()`.

Implemented code receives no preservation preference here. The target is to grow the
typed action primitive seam and migrate these callers, not to wrap all three existing
dispatchers and call the wrappers a unified pipeline.

#### Session 2 — Condition, world, story, and economy mutation inventory

Trace condition application/ticks/removal, terrain and environmental hazards, traps,
map objects, dialogue/story actions, objectives, rewards, cadence actions, shops, and
other transactions. Check both campaign-pack repos for authored examples and missing
adopters. This completes step 1.

Exit: the inventory covers every currently implemented or explicitly planned source,
and unadopted engine seams are named rather than inferred from tests alone.

Session 2 evidence inventory (2026-08-31):

| Path | Source and trigger | Validation | Preview / projection | Commit and mutation owner | Result and persistence | Adoption and disposition |
|---|---|---|---|---|---|---|
| Status-condition lifecycle | The planned `ConditionManager` API names apply, remove, faction-phase tick, query, and clear-all operations for poison, sleep, silence, berserk, and stun. GDD_02 assigns duration effects to the holder's faction-phase start and behavioural enforcement to activation-time consumers. | No condition definition/schema/registry exists. The autoload accepts an unchecked string id and duration. | None. `has_condition()` always returns false and there is no projected application, tick, expiry, cleanse, or affected-field result. | None: every method is a no-op and no production or test caller invokes the autoload. Planned state is `UnitData.conditions`; it is not present in the live resource. | No result shape, events, save field, snapshot handling, migration, or lifecycle tests exist. | Neither pack authors conditions. **Build on the shared effect contract, do not graduate the stub into a private dispatcher.** Keep scheduling/stacking/duration in the condition adapter; application, periodic consequences, cleanse, and removal consequences use shared primitives. |
| Passive terrain and phase-start terrain healing | Pack `terrain` rows activate through `DataManager`/`TerrainRegistry`. Movement, defence, avoid, label, art, and healing consumers query the active registry; `TurnManager._begin_phase()` calls `_apply_fort_healing()` for the active faction. | Tier-2 schema and `TerrainRegistry.apply_authored_documents()` validate ids, movement vocabulary/ranges, variants, and `heal_fraction` in `[0,1]`. | Movement/bonuses are pure queries. Healing has no preview; callers can query the fraction but not an outcome or touched fields. | `TurnManager` computes `max(1, floor(max_hp * fraction))` and calls `Unit.heal()` directly before start-of-turn skills. Terrain has no mutation/transaction owner of its own. | HP persists in `UnitData` and map snapshots, but terrain healing returns no receipt and is not tied to the phase commit as an effect result. Terrain definitions are package data; tile terrain is static map data. | The FE pack authors all seven terrain rows, including `fort.heal_fraction = 0.1`, and playable maps use forts. Pack 0 has no content data. **Retain terrain as the stateless source/query adapter; migrate healing and future reusable hazard outcomes to shared primitives.** |
| Crossing hazards and traps | `Unit.move_along_path()` delegates continuous paths to the singleton `CrossingService`; registered probes may fire ordered halt/continue and ends-activation declarations with an effect callable. Planned terrain hazards, one-shot traps, fog ambush, perception-on-cross, and traversing displacement share this seam. | `CrossingResolver` validates consumer registration and normalizes trigger dictionaries at runtime, but there is no authored trigger schema, effect-id validation, target context, or package admission path. | Resolution runs over the requested path before animation and returns the actual path plus fired ids, halt state, activation cost, permanence, and errors. The effect callable itself has no preview contract. | The resolver invokes arbitrary callables during path resolution. It owns trigger ordering and movement interruption, not rollback or the consequence mutation. No production consumer is registered, so the shipped seam is inert. | `CrossingOutcome` is transient. A fired trigger makes movement non-undoable, but arbitrary effect writes are not reported; persistent one-shot state has no implemented owner. | Neither pack authors crossings, hazards, or traps. **Retain the crossing scheduler, replace arbitrary mutation callables with shared effect requests/results.** Reusable stateless hazards remain terrain; a sprung/disarmed one-shot trap is a `map_object` with durable instance state. |
| Stateful map objects and interactions | Planned doors, chests, villages, shops, breakables, traps, and stationary weapons use one `map_objects` component model. `TileActions` reserves `activate`, `visit`, and `shop`, but only shipped `seize` and `escape` gates can become available. | No `map_object` resource/schema, component registry, instance-state validator, or pack loader exists. Placeholder tile actions always return false. | No interaction availability reasons, object-state projection, loot preview, or effect preview exists. | No commit path exists. Target ownership is per-instance `map_objects_state`; terrain deliberately cannot own stateful instances. | No save field, result envelope, migration, or tests beyond the false placeholder gates exist. | Neither pack authors map objects. **Build the instance/component adapter over shared requirements and ordered effects; do not add bespoke door/chest/shop classes or a second action language.** |
| Battle objectives and objective actions | `TurnManager.check_victory_conditions()` evaluates authored victory groups as AND and defeat groups as OR through `ObjectiveConditionRegistry`; death, phase/action transitions, explicit Seize, and explicit Escape trigger checks. | `DataManager` validates condition ids and parameters through the open registry. Seven built-ins are registered, but their evaluation callables are installed by `TurnManager`, coupling a nominally reusable registry to one scene controller. | Objective evaluation is non-mutating and returns only bool. `RequirementSystem.evaluate_objective_condition()` can wrap it in a structured requirement result, but production `TurnManager` bypasses that bridge. Seize/Escape availability is separately re-derived by `can_seize()`/`can_escape()`. | Objective predicates do not mutate. Seize/Escape action methods record local objective state/spend activation, then the victory evaluator commits `_map_over`, elimination/winner state, and signals. | Runtime escape/seize/elimination state participates in map snapshots/suspend through the existing map runtime; the registry itself reports no trace or unmet reasons. | The FE pack registers and plays rout, seize, defeat-boss, escape, survive, protect, and turn-limit objectives across eight maps. Pack 0 has none. **Converge objective definitions on shared requirement compositions and structured reasons; keep battle aggregation and action timing in the objective adapter.** |
| Victory rewards | A blue-group victory calls `_apply_victory_rewards()` once before `map_victory`. Maps author `reward_gold` and `reward_items`. | `DataManager` validates reward item ids; gold is an integer. There is no capacity/preflight check for the full reward composition. | No reward preview. The results UI observes only a post-commit receipt. | Gold is credited through `ResourceLedger.commit()` using a negative cost. Items are then appended directly to `GameState.party_items`; a failure after gold commit has no encompassing rollback boundary. | Receipt is `{gold_earned,total_gold,items_awarded}` and `reward_committed` drives read-only UI. Treasury and convoy-shaped party items persist in save/map history, but the receipt has no touched-field declaration. | The FE pack authors gold rewards on eight maps; it authors no reward items. Pack 0 has neither. **Migrate the reward composition to one transaction coordinating ledger and inventory custody; use shared grant primitives and return one structured result.** |
| Campaign/story state actions | `CampaignManager` exposes direct setters for legacy string flags/vars and carry-forward facts; typed `CampaignVars` separately validates registered bool/int/enum definitions and map/campaign scope. `MutableCampaignState` separately appends permanent rule patches and durable imported facts. There is no dialogue/story/event runner that invokes any of them from package data. | Direct legacy setters validate only non-empty ids. `CampaignVars.set_var()` validates registered type/range/enum; rule patches validate only non-empty rule id. No authored story-action schema validates an ordered mutation composition. | Requirements can query flags and typed variables without mutation. No change preview, old/new value result, requirement gate, or narrative transaction projection exists. | Each store mutates itself immediately. Campaign restore validates an envelope before replacing campaign position/flags/vars/cadence, but ordinary setters and rule-patch appends are independent writes. | Legacy flags/vars and typed campaign vars persist in the campaign envelope; map vars reset; rule patches/facts persist through `MutableCampaignState`. Setters return bool only and emit no shared evidence. | Neither pack authors campaign vars, dialogue, story actions, or rule patches. **Define story/dialogue as sequencing adapters over shared flag/variable/rule/item/condition primitives. Consolidate the overlapping legacy/typed variable write authority during contract-gap review.** |
| Campaign results, node advancement, and cadence | Map signals create a transient pending result. Results UI chooses a valid successor, then `commit_pending_result()` advances cleared/current node state, increments chapter/reached cadence counters, ends map rules, and autosaves. Launch and explicit campaign events increment other counters; `CadenceEngine` evaluates open counter/predicate families and resolves subscriptions. | Campaign graph/successor ids and cadence definitions are validated at pack admission. Runtime successor choice is checked against the authored edge list; requirement predicates validate through `RequirementSystem`. | Pending result and successor options are explicit projections. Cadence returns fired/active/next state, but callers mutate live cadence state during evaluation; there is no dry-run/commit distinction for the combined node advance. | `CampaignManager` owns pending-result and position commit, while `CadenceEngine.increment_counter()` mutates the supplied state dictionary and `evaluate()` returns a normalized replacement. Current implemented subscription consumer is battle-target selection; activity sets/variants and stock restock are seams only. | Campaign id, node, cleared nodes, flags, vars, and cadence dictionaries persist and autosave together after advance. Pending result is deliberately transient. Cadence returns ids/state, not effects or touched fields. | The FE campaign adopts the five-node/result path but authors no cadence triggers/subscriptions; Pack 0 has no campaign. **Retain cadence as a deterministic clock/selector, not an effect executor. Route any fired cadence actions through the shared pipeline and define node-advance atomicity in Session 3.** |
| Resource ledger and shops/services | `ResourceLedger` is an implemented wallet authority for quote, reserve-without-hold, commit, and recorded-delta refund across party/unit gold. Production uses it only for victory credits. Shop exit is merely a seeded cadence counter id; `TileActions.shop` is unavailable. | `RegistryManager` resolves resource types/subjects; `CostFormulaRegistry` validates/evaluates fixed or quantity-price costs. All wallets are prepared before commit, preventing partial multi-wallet charges. No goods, stock, capacity, service, or authored outcome schema exists. | `quote()` is side-effect-free and returns deltas, shortfalls, summaries, and wallet ids. It cannot preview inventory/effect outcomes. `reserve()` records intent but holds no balance and commit does not accept the reservation. | Ledger atomically mutates its prepared wallet records. There is no purchase coordinator; inventory acquisition, stock decrement/restock, forging/training outcomes, and shop UI are planned. | `ResourceTransaction` is transient and refundable; wallet values persist through `GameState`/`UnitData`. No purchase receipt or save-owned stock entity exists. | Neither pack authors usable shops, costs, stock, or purchases. **Retain `ResourceLedger` as payment authority. Build a purchase coordinator that revalidates payment and required outcome, then atomically commits ledger plus custody/effects; never make the effect runner the wallet owner.** |

Pack adoption is therefore narrow but real: the FE pack proves terrain queries/healing,
all shipped objective families, map rewards, and campaign result advancement through
`select_campaign()`. It does **not** prove conditions, crossings, hazards/traps, map
objects, dialogue/story mutations, cadence authoring, or shops. The general-purpose
Pack 0 checkout contains only provenance metadata and proves none of this surface.
Tests and engine fixtures are not substitutes for those missing adopters.

Session 2 confirms that the world/story/economy side is not one competing dispatcher.
It is a mix of direct writes, useful schedulers, and unbuilt contracts:

1. terrain healing, reward items, flags/variables, and rule patches write state through
   separate owners with no common result or rollback boundary;
2. objective evaluation and cadence are non-mutating evaluators/schedulers that should
   feed the shared requirement/effect contracts, not be absorbed as effect primitives;
3. crossings provide deterministic ordering and previewable movement interruption, but
   their arbitrary effect callable is an unsafe mutation escape hatch;
4. status conditions, map objects, story actions, and shops have no implemented
   execution path to preserve, so their first build should use the shared contract;
5. rewards already demonstrate the economy collision: ledger credit and inventory grant
   are one player-visible reward but two commits, exactly the partial-transaction shape
   the purchase coordinator must prevent.

#### Session 3 — Duplication and contract-gap review

Compare the complete inventory against the target pipeline. Classify direct mutations,
parallel dispatchers, duplicated primitives, incompatible context/result shapes,
preview/commit divergence, non-deterministic RNG, missing touched-field declarations,
and rollback gaps. This is step 2.

Exit: every path is classified as retain as source adapter, migrate to shared primitive,
merge with another handler, redesign, or remove.

Session 3 collision and convergence matrix (2026-08-31):

| Path | Present role and duplicated primitive | Context/result and preview gap | Transaction, RNG, and persistence gap | Adoption | Classification |
|---|---|---|---|---|---|
| Combat prepare/apply | `CombatResolver` is both combat scheduler/formula owner and partial effect executor; `resolve_combat()` mutates skills/counters before `apply_combat_result()` commits the remaining exchange. Damage, healing, modifier, counter, durability, EXP, death, and event writes span both methods. | Two large dictionaries and manually selected snapshots stand in for an explicit state view and prepared result. Forecast and commit do not share a complete effect projection. | RNG begins during resolve and commits during apply through a mutable once-guard. No rollback boundary covers skill state, HP, durability, progression, and death together. All are save/snapshot relevant. | Core playable combat path. | **Redesign.** Retain combat timing, formulas, strike ordering, and hit/crit RNG as a source coordinator. Replace live mutation during resolve with an isolated prepared combat transaction; commit the accepted exchange and attached effects once. Remove the mutating `resolve_combat()` contract after migration. |
| Direct item use | `ItemHandler` owns item selection/consumption while `ItemEffectRegistry` owns a second can-apply/preview/commit language. Heal duplicates the general HP primitive; stat modifiers already partially use `ActionEffectRunner`. | Item dictionaries discard shared affected ids and touched fields. Preview reports a mode, not the same projected deltas later committed. | Effect and inventory decrement are separate writes with no rollback. Items use no RNG today, but the shape cannot safely add it. HP, modifiers, and inventory persist. | Core engine content; external packs currently do not author items. | **Migrate.** Retain the item adapter for custody, availability, and consumption. Merge heal/modifier outcomes with shared primitives and coordinate effect plus consumption as one commit. Remove registry commit handlers once all item definitions select compositions. |
| Promotion/reclass item | Modal UI, class-change services, and item consumption divide one action; the screen effectively becomes the transaction owner. | Preview only selects a modal and cannot project the chosen class outcome. UI-held choice is absent from the item request/result. | Class, stats, skills, equipment legality, and inventory consumption lack one atomic boundary; no RNG is required. | Engine validation map only; no external pack adopter. | **Redesign.** Retain the modal solely as a choice collector. A progression coordinator validates the selected destination, prepares the class-change effect composition, and commits it with consumption. UI must not mutate gameplay state. |
| Triggered skills | `SkillHandler` should schedule/filter triggers, but handler callables also implement reusable damage/heal/modifier/context mutations. Query-only skills masquerade as handlers that return false. | Boolean results and mutable context dictionaries cannot report targets, deltas, diagnostics, or preview parity. Random skills disappear from forecast rather than produce an explicit uncertainty/probability result. | Handler writes and use counters commit independently, and combat preview restores only a hand-maintained subset. RNG ownership is split between caller and handler policy. Counters/modifiers persist. | Core combat and phase paths. | **Migrate and split.** Retain trigger timing, Nihil, activation policy, and limits in the skill adapter. Migrate state changes to shared primitives; move passive/query skills to declarative contribution registries; remove query-only executable handlers. |
| Status conditions | The autoload is a no-op placeholder, so there is no implementation worth wrapping. Planned apply/tick/remove consequences overlap item, skill, and terrain primitives. | No request, projection, result, or lifecycle evidence exists. | Planned duration/stack state and consequences would otherwise create a private transaction/RNG path and a new save field. | No pack adopter. | **Redesign from the first build.** Keep condition definitions, stacking, duration, immunities, and trigger scheduling in a condition adapter; express application, periodic, expiry, cleanse, and removal consequences as shared compositions. Remove the present stub when the real adapter lands rather than preserve its unchecked string API. |
| Terrain healing/hazards | `TerrainRegistry` is a valid stateless query source; `TurnManager` directly implements the reusable heal primitive. | Queries are safe, but healing has no projected delta or structured result. | Phase-start HP writes are outside a declared phase/effect transaction. No RNG today; HP persists. | FE pack terrain and healing are played. | **Retain source adapter; migrate mutation.** Keep terrain lookup and phase timing. Merge healing with the shared HP primitive and route future hazards through compositions. Terrain never owns durable instance state. |
| Crossing callable and traps | `CrossingResolver` is a useful deterministic scheduler, but an arbitrary callable is an unbounded second mutation language. Stateful traps overlap the planned map-object instance model. | Path/halt projection is structured; callable consequences have no target context, preview, or result. | Effects can commit during path resolution with no rollback or touched fields. One-shot state has no owner. | No production consumer or pack adopter. | **Retain scheduler; replace escape hatch.** Crossing emits prepared shared-effect requests and consumes results. Remove arbitrary effect callables. Model reusable terrain triggers as stateless sources and one-shot traps as durable map-object instances. |
| Stateful map objects/story events | These are unbuilt source adapters. Their planned door/chest/village/dialogue/reward operations would duplicate requirements and mutation dispatch if implemented per object or event type. | No shared target reference, ordered result, preview, or unmet-reason shape exists. | No instance transaction, rollback, RNG accounting, or save-owned `map_objects_state` exists. | No pack adopter. | **Redesign from the first build.** One component/sequencing adapter evaluates shared requirements and submits ordered effect compositions. Do not add per-object classes or a story-specific mutation language. |
| Objectives and action gates | Objective predicates, `RequirementSystem`, and `can_seize()`/`can_escape()` express overlapping availability logic. `ObjectiveConditionRegistry` evaluators are installed by `TurnManager`, obscuring ownership. | Production returns bool while the requirement bridge can already return structured unmet reasons. Seize/Escape re-derive the same facts. | Predicates remain non-mutating; objective action state and battle-end state commit in scene code. No RNG. Runtime objective state persists in map snapshots. | All shipped FE objective families are played. | **Merge predicate contracts.** Objective definitions become shared requirement compositions; retain battle AND/OR aggregation, victory timing, and action scheduling in the objective adapter. Migrate Seize/Escape availability to the same evaluation trace. Do not turn objectives into effect primitives. |
| Victory rewards | Gold credit uses `ResourceLedger`, while item grant writes `party_items` directly. Both are one authored/player-visible reward. | Post-commit receipt is not a preflight and does not expose touched fields or per-effect failure. | Gold may commit before item failure. Ledger refund cannot by itself roll back custody. No RNG today; treasury and inventory persist. | FE pack gold rewards are played; item rewards are not. | **Redesign as a transaction coordinator.** Retain ledger credit and inventory custody as distinct primitive authorities, but prepare and commit the complete required reward once. Remove direct `party_items.append()` from reward execution. |
| Campaign/story variables | Legacy flags/string vars, typed `CampaignVars`, and `MutableCampaignState` facts/rule patches are three write APIs with overlapping durable campaign-state purpose. | Only typed vars validate type/range; none returns old/new values, touched fields, or a shared preview. | Setters commit independently with no composition rollback or RNG evidence. Campaign and map scopes have different persistence lifetimes. | No authored pack adopter. | **Merge authority and migrate.** `CampaignVars` becomes the single authored variable authority with explicit bool/int/enum definitions and campaign/map scope. Migrate legacy flag/var reads and save payloads through compatibility decoding, then remove legacy write APIs. Keep permanent rule patches and imported provenance facts in `MutableCampaignState` because they are append-only policy/provenance records, not ordinary variables; expose their changes through distinct shared primitives. |
| Campaign advance/cadence | `CampaignManager` owns node/results progression; `CadenceEngine` correctly acts as a clock/selector but mutates caller-owned cadence dictionaries during evaluation. Fired subscriptions risk becoming a second action runner. | Pending result/successors are useful projections. Cadence needs prepare-versus-commit state and a result that names fired ids without executing them. | Node, cleared set, cadence counters, rule teardown, and autosave form one logical campaign transition, but there is no atomic prepared boundary. No RNG. All except pending result persist together. | FE campaign advancement is played; authored cadence is not. | **Retain both roles; redesign coordination.** Make cadence evaluation pure over a copied state, then commit campaign position plus next cadence state atomically before dispatching prepared required cadence effects within the same transaction. Presentation/subsequent optional activities occur afterward. Cadence never executes effects. |
| Purchases/services | `ResourceLedger` already owns wallet quote/commit/refund. Planned goods, inventory, stock, forging, and training require other authorities; folding them into the ledger or runner would create a god object. | Ledger quote cannot project goods/effects, and reservations do not hold balance or bind a later commit. No purchase result exists. | Payment, stock, custody, and required effects need one optimistic-revalidation and rollback boundary. Formula evaluation may need deterministic context but not gameplay RNG by default. Wallet and future stock/custody state persist. | No implementation or pack adopter. | **Retain ledger; add a thin coordinator.** Prepare payment and required outcomes with their owning services, revalidate, then commit or roll back as one purchase. The effect runner does not own wallets, inventory, or stock. |

The matrix resolves the architectural analysis without an owner-policy fork. The
common boundary is not one service that owns all state; it is one typed execution and
transaction protocol whose primitive handlers continue to delegate each write to the
domain authority for that state. `ResourceLedger`, inventory custody, progression,
campaign position, condition duration, map-object instance state, and combat formulas
therefore remain separate authorities. Source adapters own timing and authored-source
rules; coordinators own atomicity across those authorities; shared requests/results own
validation, preview evidence, touched fields, RNG accounting, and failure reporting.

The removals are explicit: mutating combat resolution, item-specific commit callables,
query-only skill handlers, arbitrary crossing effect callables, direct reward inventory
writes, legacy campaign-variable write APIs, and UI-owned progression commits do not
survive as compatibility execution paths. Compatibility is limited to data/save
decoding into the new authorities. Session 4 must design the concrete protocol that
makes those migrations possible; it must not preserve the old result dictionaries or
boolean handler contracts inside a nominally typed wrapper.

#### Session 4 — Shared effect contract design

Specify the request, context, target references, ordered composition, requirement gate,
preview, commit, result, diagnostics, touched save fields, deterministic RNG, failure
policy, and rollback protocol. Define how domain adapters and `ResourceLedger` compose
without sharing ownership. This is step 3.

Exit: the contract is precise enough to implement without consulting a discussion or
research document, and includes compatibility rules for saves and campaign data.

Session 4 outcome (2026-08-31): the contract is
[GDD_01 — Runtime Contracts § Shared Effect Execution Contract](GDD_01_Runtime_Contracts.md),
specs `EFX-1`–`EFX-28`. It lives in the runtime companion because that chapter owns
binding runtime behavior; this chapter keeps the review plan and the collision matrix
that produced it.

Its load-bearing rulings, so this section can be read without following the link:

- **No new envelopes.** `ActionRequest`, `ActionContext`, `ActionResult`,
  `ProjectionContext`/`ProjectionResult`, `ResourceTransaction`, `CrossingOutcome`,
  `RegistryEntry` and the `RequirementSystem.evaluate()` result each keep their identity
  and gain only additive fields with defaults (`EFX-1`).
- **Prepare never touches live state** (`EFX-5`). Handlers read and write through an
  overlay state view and produce a journal; commit applies the journal. This is what
  replaces combat's mutate-and-restore forecast and makes an abandoned transaction
  structurally incapable of leaving partial state (`EFX-14`).
- **Commit revalidates, then applies the journal last** (`EFX-16`), so the fallible
  participants — `ResourceLedger`, stock, custody — commit before the infallible one and
  rollback is confined to participants that support it (`EFX-17`).
- **The source adapter owns the RNG event, the runner never seeds** (`EFX-18`), previews
  never advance `history_hash` (`EFX-10`), uncertainty is reported rather than omitted
  from forecasts (`EFX-11`), and migration must not change draw count or order
  (`EFX-20`).
- **Touched save fields are checked against declarations, not just declared**
  (`EFX-22`), and the contract itself persists nothing (`EFX-26`).
- **`effect_compositions` is an optional registry family** (`EFX-27`), so packs that
  author none validate exactly as they do today; compatibility is data and save decoding
  only, never a retained execution path (`EFX-28`).

#### Session 5 — Migration graph and implementation registration

Turn the contract into dependency-ordered implementation slices and register each in
`coordination/tasks.json`. Sequence item reference work, combat/skills, conditions,
world/story sources, economy, cleanup, pack adoption, and playtest evidence. This
combines steps 4 and 5.

Exit: every implementation slice has claimed paths, dependencies, acceptance evidence,
and a named campaign-pack adopter; no execution plan exists only in prose.

#### Session 6 — Cross-source proof primitive

Implement one small primitive end to end through the shared contract. Exercise it from
an item, a combat or condition source, and a map, story, or economy source. Author the
non-test proof in a campaign pack and load it through `select_campaign()`. This is
step 6.

Exit: validation, preview, commit, deterministic replay, touched-field reporting,
save/load, and failure behavior pass through the same primitive in all three sources.

#### Session 7 — Combat, item, and skill migration

Make items, attacks/weapons, and skills thin domain adapters over the shared executor.
Preserve inventory consumption, durability, hit timing, trigger windows, counters, and
combat forecast behavior while removing duplicate effect implementations. This is the
first implementation slice of step 7.

Exit: no reusable mutation primitive remains private to these three source adapters.

#### Session 8 — Condition lifecycle migration

Move status application, stacking, duration, tick, expiry, cleanse, and removal effects
onto the shared executor. Keep lifecycle scheduling in the condition domain and keep
requirements non-mutating. This is the second implementation slice of step 7.

Exit: condition preview/commit and replay use the shared contract, with save migration
coverage for any durable schema change.

#### Session 9 — World and authored-event migration

Migrate terrain hazards, traps, map objects, objectives/rewards, dialogue/story actions,
and cadence actions. Consolidate identical damage, healing, movement, variable, item,
and condition primitives instead of retaining source-specific versions. This is the
third implementation slice of step 7.

Exit: a campaign pack authors and plays at least one world/event composition without an
engine source switch.

#### Session 10 — Economy and purchase migration

Compose shop/service quotes, `ResourceLedger`, inventory custody, and authored outcomes
under the atomic purchase coordinator. Cover insufficient funds, stock/capacity
failure, required-effect failure, rollback, receipts, and preview. This is the fourth
implementation slice of step 7.

Exit: no failed purchase charges the player or partially applies a required outcome.

#### Session 11 — Legacy-path removal and regression proof

Remove obsolete effect registries, source-specific dispatch paths, compatibility
branches, and duplicate tests only after all callers migrate. Run the full engine and
campaign-pack suites and complete required playtests. This completes step 7.

Exit: repository search finds no retired dispatch path or direct mutation prohibited by
the new contract, and all automated and required visual evidence is green.

#### Session 12 — Documentation cutover and historical-only verification

For each migrated domain, merge remaining binding decisions and unfinished scope into
the appropriate GDD chapter and tracker rows, then delete the superseded registers,
plans, discussions, research, handoffs, updates, reviews, and obsolete generators or
checks. Update all references before deletion and verify retrieval with Git. This is
the final sweep of step 8; smaller domain documentation deletions should already have
occurred in Sessions 7–10 when their code migrations made them safe.

Exit: no live tracker or repository reference points to deleted documentation, the GDD
is sufficient for current work, documentation checks reflect the reduced model, and
historical material is accessible only through Git.

### Initial Findings

- The former autoload map was stale: it documented 21 singletons while
  `project.godot` registers 31. The corrected composition below is the baseline for
  dependency and ownership review.
- Documentation is much larger than the current-truth spine: `AGENT/Docs` contains
  462 Markdown files and about 119,000 lines, compared with about 35,000 lines in the
  GDD. Plans, registers, design packets, and playtests repeat decisions across types.
- Deletion cannot be a blind file sweep. At review start, 109 non-terminal tracker
  rows cited 88 distinct Docs/GDD files, and ten active claims overlapped the proposed
  consolidation area. Those references are live dependencies that must be migrated
  before their source files disappear.
- Documentation machinery is coupled to runtime tooling: hooks, `check_docs.py`, the
  generated Docs indexes, release checks, and a small number of tests refer to
  `AGENT/Docs`. The consolidation must retire or redirect those consumers in the same
  change as the document classes they enforce.

### Target Documentation Model

The maintained project design has one subject-sorted source: `AGENT/GDD/`.

- GDD_00 owns product intent and reading order.
- GDD_01 owns architecture, data/runtime contracts, and this consolidation plan.
- GDD_02–08 own gameplay and player-facing behavior by domain.
- GDD_10 owns the implementation roadmap and status of unfinished product work.
- GDD_11 owns campaign-editor and authoring workflow behavior.
- The feature index and adoption matrix may remain generated views only if they derive
  entirely from GDD-owned data and materially improve retrieval; otherwise they are
  retired too.

Repository policy (`AGENTS.md`), licensing, root setup/readme material, machine-owned
tracker data, and code/test comments are operational inputs rather than historical
design documents and are outside the GDD merge. No `AGENT/Docs/archive` replacement is
created. Removed discussion, research, register, plan, handoff, review, playtest-update,
and superseded GDD files remain retrievable through Git history only.

### Consolidation Gates and Waves

Each wave edits current truth into its destination chapter before deleting its sources.
A source is removable only when its unresolved work is represented in
`coordination/tasks.json`, its binding decisions are present in a GDD chapter, no
non-terminal tracker row cites it, and no code/check/generator requires its path.

1. **Map the system.** Trace the six boundaries above, record ownership conflicts and
   missing pack adopters in the appropriate GDD chapters, and correct facts that have
   drifted from code.
2. **Define the migration manifest in place.** Classify every maintained Markdown file
   as merge into a named GDD chapter, operational exception, generated view to rebuild,
   or delete after verification. The canonical tracker holds execution rows and
   dependencies; there is no separate manifest document.
3. **Absorb live decisions and work.** Move resolved rules from registers/design
   packets into GDD_01–08/11. Move unfinished scope, ordering, and acceptance evidence
   into GDD_10 plus tracker fields. Update tracker references to GDD anchors.
4. **Retire document classes.** Delete migrated discussion/research registers, plans,
   dated updates, handoffs, reviews, frozen session notes, duplicate guides, historical
   archives, and obsolete GDD supplements. Retire their templates, indexes, generators,
   and checks in the same wave; do not add a replacement governance layer.
5. **Prove the cutover.** Require zero live tracker references to deleted paths, zero
   repository references to retired document classes, valid GDD links/statuses, green
   fast/full suites, and a clean Godot import. Sample deleted decisions through `git log`
   and `git show` to verify that Git alone provides historical retrieval.

Because active product work still owns some source documents, waves 3–4 proceed by
domain and dependency rather than one destructive commit. A domain is complete only
when its GDD is sufficient to implement or review the remaining tracker rows without
consulting the deleted source documents.

---
## Core Philosophy: Data-Driven Design

All game content — classes, weapons, items, skills, maps — is defined in **data files**,
not in code. Game logic reads and executes these definitions at runtime. Author-facing
vocabularies follow the `[EXT]` rule: open registries and data compositions, not closed
engine switches, unless a section explicitly marks an engine-only exception. This means:

- Adding a new class = write a new `.tres` resource file, no code changes needed
- Adding a new skill that composes existing primitives = write a skill resource and
  configure its effect/requirement data
- Adding a new map = write a map data file and a Godot TileMap scene

The only time code changes are needed is when introducing a **new engine primitive**.
Those primitives ship through the engine release cadence; content authors get a
growable named library of data compositions and developer-provided presets.

### Authoring Extension Boundary

Status: **Implemented - contract groundwork**
Last verified: 2026-07-15

Public campaign packages are data + assets first. The in-app authoring surface must not
run arbitrary executable code from shared campaigns. A future sandboxed scripting layer
is allowed only as a bounded expansion; full unrestricted power-user access is forking
the public source.

The author-facing vocabulary families that must be registry-backed are tracked in the
Project Control Plane and vocabulary manifest: objective predicates/actions, AI
profiles/presets, map-object components, PHB panels, action/effect primitives, stat
names, resource types, difficulty/rule profiles, requirement predicates/terms, and
future activities.

The first campaign-package presentation seam is implemented in
`scripts/assets/AssetResolver.gd`. It separates the small engine-facing loader
primitive registry from author-defined asset groups, ids, and fallback chains.
Adding a portrait, icon, or other group that reuses a registered loader is data
registration and requires no resolver switch edit. Resolution is scoped to one
campaign root, rejects paths that escape that root, and produces a structured
repair report for missing optional assets instead of crashing the pack. PNG,
TTF/OTF, OGG, and WAV raw-loader primitives exist. `PackManifest` plus the
canonical Tier-2 catalogue validate structured package content in memory, and
`CampaignArchivePreflight` inspects actual ZIP central-directory metadata before
extraction. It rejects unsafe/ambiguous paths, collisions, symlinks and special
files, caller-bounded entry/byte totals, unindexed files, and save-shaped JSON.
Preflight is read-only and leaves activation, save state, and installed-pack
storage untouched. Player-library admission additionally requires at least one
non-development campaign whose Tier-2 starting graph and runtime references validate;
the same predicate runs again on the staged tree before atomic promotion.

Installed package versions coexist. Discovery never activates content, while New Game
activates the exact selected package id/version transactionally. Direct save migration
is destination-declared data: v1 accepts one same-package-id source-version edge,
walks only registered durable-reference families on a deep copy, validates every
destination id and the complete save, and commits a new slot without overwriting the
source. Cross-package, chained, scripted, ambiguous, lossy, or best-effort migration
is rejected.

Objective conditions and item effects now use the same data/primitive split.
`engine_data/registries/objective_conditions/` binds authored condition ids to
validation, evaluation, and display primitives;
`engine_data/registries/item_effects/` binds item effect ids to validation, preview,
and commit primitives. Existing ids and resource fields are unchanged. A new id
that reuses registered primitives is a registry resource; a genuinely new engine
behavior adds and tests a primitive handler without extending a central switch.
Whole-pack validation bootstraps those declarations in two passes: it first validates
every registry-entry shape and resolves its primitive against the engine catalogue,
then admits the valid ids into a fresh pack-scoped schema registry before validating
dependent documents. Invalid declarations and duplicate ids within one pack fail
atomically; identical local ids in separately validated packs remain independent.

### Action/Effect Execution Boundary

Status: **Implemented - contract groundwork**
Last verified: 2026-07-13

State-changing authored actions use a structured `ActionRequest`, `ActionContext`,
and `ActionResult`. `ActionEffectRunner` resolves the request's primitive entry
through `RegistryManager`, validates required subjects and the declared parameter
schema, and only then invokes the engine-owned handler. Unknown primitives,
unavailable handlers, missing subjects, and malformed parameters return structured
failures before mutation. Dry-run requests follow the same validation path and do
not invoke a handler. Parameters omitted from schemas that mark them optional reach
the handler through neutral defaults rather than failing after validation.

The first proof primitive, `apply_active_modifier`, is shared by the existing item
domain and a map-event fixture. It reports `UnitData.active_modifiers` as its touched
save field; all registry entries marked as mutations must declare at least one save
field. Requirement-gated availability remains owned by `B3-REQ`. Existing item
effects now preview/commit through `ItemEffectRegistry`, and existing objectives
validate, display, and evaluate through `ObjectiveConditionRegistry`; map-event,
dialogue, economy, and generalized requirement composition remain later consumers.

### Resource Transaction Boundary

Status: **Implemented - contract groundwork**
Last verified: 2026-07-13

`ResourceLedger` is the shared affordability and mutation path for registered
wallets. Fixed `CostSpec` records can be quoted without mutation, reserved as
transient non-mutating records, committed atomically across multiple wallets, and
refunded from the recorded committed deltas. Every result is a structured
`ResourceTransaction` containing wallet ids, deltas, shortfalls, and a failure
reason. Unknown resources, unresolved subjects, unsupported scopes, formula terms,
and insufficient balances fail before any wallet changes. A failed refund reports
only its shortfall; its public wallet/delta fields never claim unapplied reversals.

The first registry-backed adapters expose the existing `GameState.party_gold` and
legacy `UnitData.gold` fields. Victory gold now credits the party adapter while item
rewards retain their existing append behavior. Dynamic formula terms, persistent
holds, custom resource pools, and shop/training consumers remain with their owning
later tracks.

### Death Lifecycle Boundary

Status: **Implemented - contract groundwork**
Last verified: 2026-07-13

All production combat deaths enter `DeathLifecycle.handle_death(DeathContext)`.
The context snapshots identity, inventory, tile, source, responsible actor, and a
simultaneous-death group before disposition begins. `DeathDisposition` is the one
future custody/inventory hook; its initial implementation is deliberately a no-op.
`DeathLifecycle` is the sole implementation: combat reports a missing autoload as
an error and stops death processing instead of entering a compatibility fallback.
The lifecycle reads `GameState.campaign_rules`, releases Pair Up support,
unregisters the unit, emits `unit_died` once, and queues the scene node for removal.
`Unit.handle_death()` remains only as a compatibility wrapper. Non-combat causes,
object teardown, key-item custody, and battalion disposition remain later consumers.

For the step-by-step "how do I add or validate one safely?" workflows, prefer
the dedicated guides in `AGENT/Docs/` over repeating local checklists in every
GDD chapter.

### Onboarding Read Order

For a new developer, the shortest accurate path through the docs is:

1. This file (`GDD_01`) for project structure and runtime ownership
2. `GDD_02` for battle-loop rules
3. `GDD_03` for unit/class progression state
4. `GDD_06` for map/objective authoring
5. `GDD_07` for UI surfaces and player flow

`GDD_09_Checklist.md` was the MVP build checklist — deleted in Stage 5.2 (retrieve
via Git). `GDD_10_Roadmap.md` is the sole roadmap. Neither should be treated as the
primary source for shipped behavior; use GDD_01–GDD_08 for that.

Cross-cutting workflow guides:

- `AGENT/Docs/guides/map_authoring_guide.md`
- `AGENT/Docs/guides/testing_guide.md`
- `AGENT/Docs/guides/campaign_rules.md`

---

## Godot Project Folder Structure

```
res://
├── project.godot
│
├── assets/
│   ├── sprites/
│   │   ├── units/                   # [PLACEHOLDER] 64x64 unit sprites per class
│   │   ├── terrain/                 # [PLACEHOLDER] 64x64 tile sprites
│   │   ├── ui/                      # [PLACEHOLDER] UI panels, icons, cursors
│   │   ├── weapons/                 # [PLACEHOLDER] 16x16 weapon icons
│   │   └── cursor/                  # [PLACEHOLDER] map cursor sprite (animated)
│   ├── audio/
│   │   ├── music/                   # [PLACEHOLDER]
│   │   └── sfx/                     # [PLACEHOLDER]
│   └── fonts/                       # [PLACEHOLDER] pixel font recommended
│
├── data/
│   ├── classes/                   # 24 ClassData .tres files (base + promoted + hidden enemy-only fighter)
│   │   ├── archer.tres
│   │   ├── bishop.tres
│   │   ├── bow_knight.tres
│   │   ├── cavalier.tres
│   │   ├── cleric.tres
│   │   ├── ...
│   │   └── war_monk.tres
│   ├── weapons/
│   │   ├── iron_sword.tres
│   │   ├── steel_sword.tres
│   │   ├── iron_lance.tres
│   │   ├── javelin.tres
│   │   ├── iron_bow.tres
│   │   ├── fire.tres
│   │   ├── elfire.tres
│   │   ├── thunder.tres
│   │   ├── wind.tres
│   │   └── heal_staff.tres
│   ├── items/                     # 8 ItemData .tres files
│   │   ├── vulnerary.tres
│   │   ├── elixir.tres
│   │   ├── master_seal.tres
│   │   ├── orion_bolt.tres
│   │   ├── guiding_ring.tres
│   │   ├── second_seal.tres
│   │   ├── strength_tonic.tres
│   │   └── debuff_tonic.tres        # Map 950 validation-only stat-debuff item
│   ├── skills/                    # 54 SkillData .tres files
│   │   ├── renewal.tres
│   │   ├── vantage.tres
│   │   ├── ...
│   │   └── s_rank_mastery.tres
│   ├── roster/
│   │   ├── default/               # Six starter UnitData .tres files
│   │   │   ├── unit_01_cavalier.tres
│   │   │   ├── unit_02_mercenary.tres
│   │   │   ├── unit_03_archer.tres
│   │   │   ├── unit_04_mage.tres
│   │   │   ├── unit_05_cleric.tres
│   │   │   └── unit_06_knight.tres
│   │   └── test/
│   │       ├── map_900_hotseat_validation/
│   │       └── map_950_promotion_validation/
│   ├── pair_up/
│   │   └── pair_up_bonus_table.tres
│   └── maps/
│       ├── map_001_rout/
│       │   ├── map_001_data.tres
│       │   ├── map_001_c3_factions_data.tres
│       │   └── enemies/
│       ├── map_900_hotseat_validation/
│       │   └── map_900_hotseat_validation_data.tres
│       └── map_950_promotion_validation/
│           ├── map_950_promotion_validation_data.tres
│           └── enemies/
│
├── scenes/
│   ├── core/
│   │   ├── Boot.tscn
│   │   └── GameMap.tscn
│   ├── units/
│   │   └── Unit.tscn
│   └── ui/
│       ├── ActionMenu.tscn
│       ├── AttackPreview.tscn
│       ├── GameOverScreen.tscn      # also shown for victory
│       ├── HUD.tscn
│       ├── ItemMenu.tscn
│       ├── LevelUpScreen.tscn
│       ├── MainMenu.tscn
│       ├── MapMenu.tscn
│       ├── NewGameScreen.tscn
│       ├── PhaseBanner.tscn
│       ├── PromotionScreen.tscn
│       ├── ReclassScreen.tscn
│       ├── SettingsScreen.tscn
│       ├── UnitDetailsScreen.tscn
│       └── WeaponMenu.tscn
│       # CombatHUD still has no scene — CombatHUD.gd is attached to a bare
│       # CanvasLayer inside GameMap.tscn and builds its labels in code.
│
└── scripts/
    ├── autoloads/
    │   ├── ConditionManager.gd       # status-condition stub (M8)
    │   ├── DataManager.gd
    │   ├── EventBus.gd
    │   ├── GameState.gd
    │   ├── InputModeManager.gd
    │   ├── PairUpBonusResolver.gd
    │   ├── PairUpRegistry.gd
    │   ├── RngService.gd              # deterministic dice (RNG-1..4, CRR)
    │   └── SettingsManager.gd
    ├── core/
    │   ├── Boot.gd
    │   ├── CameraController.gd
    │   ├── CombatResolver.gd         # also an autoload (/root/CombatResolver)
    │   ├── EnemyAI.gd                # also an autoload (/root/EnemyAI)
    │   ├── GameMap.gd
    │   ├── GridManager.gd            # scene node, child of GameMap
    │   ├── HotseatController.gd
    │   ├── MapCursor.gd              # scene node, child of GameMap
    │   ├── MapCursorInput.gd         # RefCounted slice — key decode + auto-repeat
    │   ├── MapCursorSelection.gd     # RefCounted slice — selection + path planning
    │   ├── MapCursorTargeting.gd     # RefCounted slice — attack/staff targeting
    │   └── TurnManager.gd            # scene node, child of GameMap
    ├── items/
    │   └── ItemHandler.gd            # autoload — item-effect dispatcher
    ├── resources/
    │   ├── ClassData.gd
    │   ├── FactionData.gd
    │   ├── InventoryEntry.gd
    │   ├── ItemData.gd
    │   ├── MapData.gd
    │   ├── ObjectiveCondition.gd
    │   ├── PairUpBonusTable.gd
    │   ├── SkillData.gd
    │   ├── UnitData.gd
    │   └── WeaponData.gd
    ├── shared/
    │   ├── GameConstants.gd          # autoload — project-wide constants
    │   ├── InputDisplay.gd
    │   ├── MoreInfoContent.gd
    │   ├── StatBreakdown.gd
    │   └── TileActions.gd
    ├── skills/
    │   └── SkillHandler.gd           # autoload — skill-effect dispatcher
    ├── tests/                        # headless test suites; run via run_tests.sh
    ├── tools/                        # placeholder-asset + tileset generators
    ├── ui/
    │   ├── ActionMenu.gd
    │   ├── AttackPreview.gd
    │   ├── CombatHUD.gd
    │   ├── GameOverScreen.gd
    │   ├── HUD.gd
    │   ├── ItemMenu.gd
    │   ├── LevelUpScreen.gd
    │   ├── MainMenu.gd
    │   ├── MapMenu.gd
    │   ├── ModalScreen.gd
    │   ├── NewGameScreen.gd
    │   ├── PhaseBanner.gd
    │   ├── PromotionScreen.gd
    │   ├── ReclassScreen.gd
    │   ├── SelectionCursor.gd
    │   ├── SettingsScreen.gd
    │   ├── UnitDetailsScreen.gd
    │   └── WeaponMenu.gd
    └── units/
        └── Unit.gd
```

---

## Scene Node Trees

### `GameMap.tscn`
Root scene for every battle. Instanced fresh per map.

```
GameMap (Node2D)                 # script: GameMap.gd
├── TileMapLayer_Terrain         # base terrain tiles, painted at runtime from MapData.grid
├── TileMapLayer_Overlay         # movement/attack/heal/danger highlight tiles
├── UnitsContainer (Node2D)      # all Unit scenes instanced here at runtime
├── MapCursor (Node2D)           # script: MapCursor.gd
│   └── Sprite2D                 # cursor sprite
├── Camera2D                     # follows cursor; clamps to map bounds
├── GridManager (Node)           # script: GridManager.gd
├── TurnManager (Node)           # script: TurnManager.gd
├── HUDLayer (CanvasLayer)
│   ├── ActionMenu
│   ├── ItemMenu
│   ├── MapMenu
│   ├── AttackPreview
│   └── WeaponMenu
├── LevelUpLayer (CanvasLayer)
│   └── LevelUpScreen
├── PromotionLayer (CanvasLayer)
│   └── PromotionScreen
├── ReclassLayer (CanvasLayer)
│   └── ReclassScreen
├── CombatHUDLayer (CanvasLayer) # script: CombatHUD.gd; builds labels in code
├── HUDMainLayer (CanvasLayer)
│   └── HUD                      # HUD.tscn instance; script: HUD.gd
├── BannerLayer (CanvasLayer)
│   └── PhaseBanner
├── GameOverLayer (CanvasLayer)
│   └── GameOverScreen
├── SettingsLayer (CanvasLayer)
│   └── SettingsScreen
└── UnitDetailsLayer (CanvasLayer)
    └── UnitDetailsScreen
```

> **Note:** `CombatResolver` and `EnemyAI` are **autoload singletons**
> (`/root/CombatResolver`, `/root/EnemyAI`) — they are *not* children of
> `GameMap`. Code reaches them via `get_node_or_null("/root/...")`.

### `Boot.tscn`
The first scene loaded by Godot (set as the main scene in `project.godot`).
For MVP it is a plain `Node` with a single script that immediately transitions
to the Main Menu. In Phase 2+ this is where a splash screen or loading bar
would live.

```gdscript
# scripts/core/Boot.gd
extends Node

func _ready() -> void:
    get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
```

`Boot` also acts as the stable re-entry point when quitting from an in-progress map:
UI flows return to `Boot.tscn`, then `Boot` routes back to `MainMenu.tscn`.

### `Unit.tscn`
One instance per unit on the map.

```
Unit (Node2D)                       # script: Unit.gd
├── Sprite2D                        # [PLACEHOLDER] 64x64 class sprite; team-tinted in code
└── HPBar (ProgressBar)             # small bar above sprite; max_value = data.max_hp
```

> `Unit.gd` references only `$Sprite2D` and `$HPBar`. A condition-icon node and a
> selection-highlight node are planned (`[PLACEHOLDER]`) but not yet wired.

### `HUD.tscn`

The HUD is now spread across separately-instanced scenes and layers inside
`GameMap.tscn`. `HUD.tscn` owns the persistent map-side panels; menus/modals such
as `ActionMenu`, `AttackPreview`, `PromotionScreen`, `ReclassScreen`, and
`UnitDetailsScreen` are sibling layer instances in the main map scene. The tree
below reflects the current `HUD.tscn` internals; the `.tscn` files remain
authoritative for exact node names and paths.

```
HUD (Control)
├── PhaseLabel (Label)
├── TurnLabel (Label)
├── DebugLabel (Label)                      # debug-build only; hidden in release
├── UnitInfoPanel (PanelContainer)
│   └── VBox
│       ├── UnitName (Label)
│       ├── UnitClass (Label)
│       ├── UnitHP (Label)
│       ├── UnitWeapon (Label)
│       └── MasteryLabel (Label, created dynamically when needed)
├── TerrainInfoPanel (PanelContainer)
│   └── VBox
│       ├── TerrainName (Label)
│       ├── TerrainDef (Label)
│       ├── TerrainDodge (Label)
│       ├── TerrainDescription (RichTextLabel)   # More Info expanded mode
│       ├── TerrainMoveCosts (RichTextLabel)     # More Info expanded mode
│       ├── TerrainActions (RichTextLabel)       # More Info expanded mode
│       └── TerrainHint (Label)
└── ObjectivePanel (PanelContainer)
    └── VBox
        ├── ObjectiveHeader (Label)
        └── ObjectiveList (Label)
```

Related sibling UI scenes/layers in `GameMap.tscn`:
- `ActionMenu.tscn` — post-move action list, including Pair Up / Swap / Separate,
  Seize, Escape, Equip, Item, Staff, Wait as applicable
- `ItemMenu.tscn` and `WeaponMenu.tscn` — submenus launched from the action flow
- `AttackPreview.tscn` — combat forecast with More Info side panel
- `UnitDetailsScreen.tscn` — inspect-unit character sheet with More Info side panel
- `LevelUpScreen.tscn`, `PromotionScreen.tscn`, `ReclassScreen.tscn` — blocking
  progression modals
- `MapMenu.tscn`, `SettingsScreen.tscn`, `PhaseBanner.tscn`, `GameOverScreen.tscn`

The `.tscn` files are authoritative for exact composition and should be checked
before updating this document again.

---

## Autoload Composition

The exact registration order is owned by `project.godot [autoload]`; the
“Autoload load order” note below records the dependency invariant and current order.
Responsibilities are divided as follows:

| Layer | Autoloads | Responsibility |
|---|---|---|
| Text and requirements | `TextDB`, `RequirementSystem` | Localized text resolution and shared authored requirement evaluation |
| Shared foundation | `GameConstants`, `EventBus`, `RngService`, `SettingsManager`, `ResponsiveLayout`, `InputModeManager`, `TextEntryService`, `TransitionTelemetry`, `WebTestBridge`, `ControllerService`, `GameState` | Common vocabulary/events, deterministic RNG, app settings/input services, transition/test integration, and live campaign/map state |
| Extensibility and transactions | `RegistryManager`, `CampaignVars`, `ActionEffectRunner`, `ResourceLedger`, `OccupancyService`, `CrossingService`, `DeathLifecycle`, `ProjectionService` | Registry resolution, campaign variables, and shared mutation, placement, crossing, death, and forecast boundaries |
| Content and persistence | `DataManager`, `CampaignManager`, `SaveManager` | Content load/validation, campaign progression, and save-slot disk I/O |
| Gameplay services | `ConditionManager`, `SkillHandler`, `ItemHandler`, `CombatResolver`, `EnemyAI`, `PairUpRegistry`, `PairUpBonusResolver` | Feature execution shared across scenes |

`GameState` owns live state and Retry/suspend capture orchestration; the binding
snapshot and deterministic-event rules live in
[GDD_01 — Runtime Contracts](GDD_01_Runtime_Contracts.md). `DataManager` performs
strict replace-load for a selected self-contained content root; its resource shapes
and validation obligations live in
[GDD_01 — Data Contracts](GDD_01_Data_Contracts.md).

New Game launch is selector-driven through `data/maps/map_registry.json`. A launch
commits an explicit map path and roster policy/source before opening `GameMap`;
missing roster preparation fails loud instead of substituting the default roster.
The operational authoring flow is in
[Map And Campaign Content Authoring Guide](../Docs/guides/map_authoring_guide.md).

Input persistence and mode resolution belong to `GDD_07` and `B6-INPUT`.
Condition behavior belongs to `GDD_02` and its planned condition-effects track. Event payloads and
service signatures are code-owned; GDD chapters document only cross-system
invariants.

---

## Implementation Notes

Decisions made during initial implementation that affect future work. These do
not change the design but document non-obvious choices a fresh contributor would
otherwise repeat as bugs.

### Method names that collide with Godot built-ins

GDScript prints a warning (treated as error by default) when a class method
shadows a `Node` or `Object` built-in with a different signature. Two such
collisions came up; both were renamed:

- `DataManager.get_class(id)` → **`get_class_data(id)`** (collides with `Object.get_class() -> String`)
- `GridManager.get_path_to(...)` → **`get_movement_path(...)`** (collides with `Node.get_path_to(Node, bool) -> NodePath`)

When adding new methods to nodes, sanity-check against the engine docs.
Common at-risk names include `damage` (Node has none — fine to use as a method
on `Unit.gd`), `get_path`, `get_node`, `get_class`, `get_children`.

### Autoload load order

Project registration order (`project.godot [autoload]`) is the full 31:

`TextDB → RequirementSystem → GameConstants → EventBus → RngService →
SettingsManager → ResponsiveLayout → InputModeManager → TextEntryService →
TransitionTelemetry → WebTestBridge → ControllerService → GameState →
RegistryManager → CampaignVars → ActionEffectRunner → ResourceLedger →
OccupancyService → CrossingService → DeathLifecycle → ProjectionService →
DataManager → CampaignManager → SaveManager → ConditionManager → SkillHandler →
ItemHandler → CombatResolver → EnemyAI → PairUpRegistry → PairUpBonusResolver`.

Each autoload's `_ready()` runs in that order, so startup code must not assume a
later autoload is initialized. `RngService` intentionally precedes all gameplay
consumers. The Band 2 shared services precede `DataManager`, whose boot validation
uses the registry foundation. `SaveManager` follows data loading and owns disk I/O;
snapshot encoding remains in the runtime/data contracts.

`ConditionManager` is an implemented seam with no-op condition behavior while
the condition-effects implementation remains planned. `SkillHandler`, `ItemHandler`,
`CombatResolver`, and `EnemyAI` are autoloads rather than scene nodes. Runtime
code and headless tests should resolve autoloads through `/root/<name>` when
compile-time singleton identifiers are unavailable.

### Legacy user-data migration

Status: **Implemented**
Last verified: 2026-08-09

The application-name change to `Project Prometheus` moved the platform `user://`
directory. `UserDataMigration` carries each owned legacy root through a staging path
and renames it into place only after that root copies completely. A failed nested copy
removes the staging tree and leaves the global completion marker absent, so a later
launch retries. Successfully committed roots and data already present under the new
name are never overwritten; the legacy directory remains the rollback source.

### Export-safe content loading

Exported builds cannot reliably enumerate `res://` directories the same way the editor
can. The project's live rule is:

- use `scripts/shared/ResourceManifest.gd`
- author `resource_manifest.json` in content directories that must load in exports
- let `DataManager` and `GameState.load_roster_from_directory()` resolve through the
  manifest first, only falling back to raw directory listing in editor/headless runs

If new exported content appears to load in-editor but vanish in a packaged build, check
for a missing or stale `resource_manifest.json` first.

### `.tres` files in headless mode

When `.tres` files are created via the editor, their header reads
`[gd_resource type="ClassData" ...]` (using the `class_name` of the custom
class). Godot resolves "ClassData" through the global class registry, which is
populated by `class_name`-bearing scripts.

In **headless `--script` runs**, the global class registry is not initialized.
A `.tres` with `type="ClassData"` then fails to load with "Cannot get class
'ClassData'". The fix used in this project: write `.tres` files with
`type="Resource"` and let the `script = ExtResource(...)` line in the resource
body assign the actual class. Custom-typed properties (e.g. `Array[Vector2i]`)
still serialize correctly because the script defines the property types.

The editor will rewrite the type to the proper class name on first save,
which is fine — both forms load correctly.

### Autoloads inside test scripts

A script run via `godot --headless --path <project> --script <script>` does
**not** parse identifiers like `GameState`, `EventBus`, etc. at compile time —
those identifiers are resolved by the editor at parse time, but `--script` mode
skips that step. Scripts that may run in test mode (anything in `scripts/core/`
or `scripts/units/`) must access autoloads via runtime lookup:

```gdscript
if is_inside_tree():
    var bus := get_node_or_null("/root/EventBus")
    if bus:
        bus.cursor_moved.emit(tile)
```

This pattern works in both runtime and test mode. The autoloads do load at
runtime even when test scripts are executed via `--script` — only the
**parse-time identifier resolution** fails. Runtime `get_node_or_null` works.

### Map painting is data-driven

`GameMap.gd` paints `TileMapLayer_Terrain` at runtime from `MapData.grid`.
This means a data-driven map is added by authoring the terrain string grid in
the map resource, not by editing code-side constants. The string-grid format is
documented in `GDD_06`.

`_validate_map()` asserts row count, row length, and that every char is a
known terrain on `_ready` — transcription bugs fail loud at map load.

### Common onboarding gotchas

- If a new gameplay resource exists on disk but not at runtime, check `DataManager`
  validation errors and the relevant `resource_manifest.json`.
- If a map exists but cannot be chosen from New Game, check `map_registry.json`.
- If a test script needs an autoload, use `get_node_or_null("/root/...")` rather than
  compile-time identifiers.
- If a change affects battle retry behavior, inspect both `GameState.take_map_snapshot()`
  and `restore_map_snapshot()`; Retry rewinds more than HP.

### Test infrastructure

All tests live under `scripts/tests/test_*.gd` and run via
`bash run_tests.sh` (a bash wrapper) or per-suite via
`godot --headless --path . --script res://scripts/tests/<name>.gd`.

Each test extends `SceneTree`, prints `OK`/`FAIL` lines, and exits with code
0/1 for green/red.

Tool scripts (`scripts/tools/`) regenerate placeholder assets and tilesets
deterministically — re-run them after sprite or terrain changes.
