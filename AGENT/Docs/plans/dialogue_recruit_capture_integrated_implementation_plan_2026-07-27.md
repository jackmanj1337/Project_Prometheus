---
Type: implementation plan
Status: Accepted — implementation plan
Last verified: 2026-07-27
Decision source: ../registers/dialogue_recruit_capture_research_questions_2026-07-27.md
Tracker: SYS-DIALOGUE-CONVERSATION-2026-07-23, SYS-RECRUIT-CAPTURE-2026-07-23
---

# Dialogue, Recruitment, Capture, Trade, and Prison — Integrated Implementation Plan

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md), tracks
`B3-REQ`, `B3-MET`, `B4-DIALOGUE-V1`, `B4-CONVOY`, and the recruit/capture delivery line.

## 1. Outcome

Deliver the accepted V1 as one dependency-ordered system without collapsing its distinct domains:

- one atomic conversation runner and presenter used by story scenes, map Talk, supports, Prison
  visits, and battle barks;
- five independent unit-state dimensions and one authoritative transition service for permanent and
  map-end recruitment, custody, roster membership, controller changes, and transition history;
- dynamic Incapacitate and Capture objectives plus latched Extract milestones;
- shared carry/displacement rules, hard target and initiator locks, live captive release when a
  carrier falls, and authored escape/disposition handling;
- FE7-style on-map Trade and designated-provider Convoy access;
- a subject-first Explore/Prison activity using the Prep activity registry and ordinary dialogue,
  requirement, relationship, inventory, and transition actions;
- whole-conversation and whole-map-end atomicity, with saves relaunching from the preceding committed
  checkpoint;
- low-code source data, templates, validation, previews, and fixtures sufficient to author the V1
  without editing GDScript.

This plan does not implement product code. Product slices target `agent/integration` only after plan
review and owner acceptance.

## 2. Current code and stale assumptions

### Reusable foundations already present

- `RegistryManager`, `RegistryCatalog`, and family-specific registries establish the open-registry
  pattern.
- `ActionRequest`, `ActionContext`, `ActionResult`, `ActionPrimitiveRunner`, and
  `ActionEffectRunner` provide typed action validation/commit. They do **not** yet provide a staged
  journal, overlay reads, inverse/rollback, or multi-action atomic commit.
- `ObjectiveConditionRegistry` validates, evaluates, and displays registered objective conditions.
  `TurnManager.check_victory_conditions()` currently evaluates synchronously and immediately sets
  `_map_over`, awards rewards, and emits results.
- `PrepActivityRegistry` and `PrepActivityDef` provide an inert open panel/activity seam.
- `GridManager._tiles_in_range()` plus staff/attack queries and `MapCursorTargeting` provide useful
  geometry, filtering, overlay, and input patterns.
- `PairUpRegistry` provides one attached/off-map identity implementation and Save/Retry coverage.
- `InventoryEntry`, `SaveCodec`, `MapLedger`, `ResourceLedger`, and snapshot tests provide instance,
  transaction, and deterministic persistence seams.

### Assumptions that this work must replace

- `UnitData` has `team` at the scene-unit layer and only `is_incapacitated`; it lacks affiliation,
  tactical side, controller, typed roster status, and typed custody status.
- `SaveCodec.UNIT_SNAPSHOT_KEYS` has no five-dimensional state, carry/custody record, extra stats, or
  stat constraint effect representation.
- `ConditionManager` remains a no-op stub, while capture and displacement decisions require real
  registered conditions and capabilities.
- `CampaignNode` has deployment/rule fields but no campaign-default/cadence/node-patched activity
  list.
- No Dialogue, Talk, Trade, Convoy, Carry, custody roster, Prison panel, relationship runtime, or map
  event runner exists in the current code.
- Older DLG/RCR/RCV/DSP documents treat faction flip as recruitment, sleep as capture, capture as a
  recruited-state path, mid-line conversation state as saveable, or `captured:<id>` as a loose flag.
  The DRC decisions supersede those assumptions.

## 3. Architecture and ownership

### 3.1 Unit state and transitions

Persist and expose these independent values:

```text
affiliation_id     narrative identity and aggression-matrix fallback
tactical_side_id   current encounter alliance/hostility participation
controller_id      input/AI authority
roster_status      none | guest | member | unavailable | ...registered values
custody_status     free | carried | removed_to_custody | imprisoned | ...registered values
```

`UnitTransitionService` is the only writer for changes spanning these dimensions. A request declares
cause, actor, target, requested before/after fields, recruitment duration/expiry, custody owner and
representation, inventory operations, emitted facts/milestones, and story-override authority. It
validates the full proposed transition, stages it against a supplied state view, and returns a
structured `UnitTransitionResult`. Objective, AI, turn order, roster, UI, dialogue, ledger, save, and
relationship consumers observe that same result.

Do not store derived booleans such as `is_recruited` or `captured:<id>` as competing authorities.
Historical facts may be emitted from transition records when authored content needs them.

### 3.2 Requirements

Extend the shared `[REQ]` registry before Dialogue or Prison gating. Requirements use bounded
`all/any/not` composition and typed subjects such as `actor`, `target`, `visitor`, `prisoner`, `guard`,
`custody_owner`, and `speaker_controller`. Add predicates for the five state dimensions, current and
historical Incapacitate/Capture/Extract, registered conditions/capabilities, spatial relation,
inventory/key-item availability level, relationships, facts/resources, activity/cadence state, and
transition cause. Each returns truth plus a localized unmet-reason descriptor.

### 3.3 Atomic action journals

Add a general `ActionJournal` above `ActionPrimitiveRunner`, not inside the dialogue UI. It contains
ordered validated requests, a read-only authoritative base view, a staged overlay, structured
results, and one commit/abort boundary. Handlers must declare whether they support staging and which
state families they read/write. Later requests evaluate against base plus overlay. Commit revalidates
the journal and applies it once; failure applies none.

V1 Conversation uses one journal for the whole conversation. V1 map-end resolution uses one journal
for provisional victory → events → custody disposition → residual Prison intake → final objective
evaluation → result/reward commit. These workflows may share journal/overlay primitives without
making map-end processing a conversation.

### 3.4 Spatial target queries

Extract a pure `SpatialTargetQuery` from GridManager geometry and the staff-targeting pattern. Inputs
are source tile/entity, min/max range, registered metric/footprint, inclusion of source tile, map
bounds, real occupants, virtual occupants, and a requirement/filter id. Output contains stable target
refs, source/represented tiles, eligibility, and unmet reasons. Staff, aura, Talk, Trade, Rescue,
Capture, Convoy provider, and later interaction modes compose their own filters. Do not depend on
`SkillHandler._manhattan()` or copy heal-specific HP/alliance logic.

### 3.5 Inventory interactions

`InventoryTransferService` owns item-instance slot operations. A two-unit Trade transaction selects
an item or empty slot in each inventory and swaps them atomically. Empty-slot swaps are moves through
the same operation. Key/bound restrictions return structured reasons and forced-effect fallbacks.
Convoy transfers use unit↔store movement through the same ledger, not the two-inventory visual layout.

Trade and Convoy are separate FE7-style partial action marks. Opening/cancelling without a committed
transfer is free. The first transfer commits location; one session may perform multiple transfers;
each interaction may be initiated once per activation; both may occur before a concluding action.
Post-action movement routes through the registered move-again policy.

### 3.6 Dialogue data and presentation

Campaign packs ship validated plain data:

```json
{
  "id": "talk_maro_lena",
  "profile_id": "map_talk",
  "roles": {"actor": "unit:maro", "target": "unit:lena"},
  "requirements": {},
  "entries": [
    {"id":"e001","type":"line","speaker":"actor","text_id":"talk.maro.001"},
    {"id":"e002","type":"choice","decision_owner":"actor_controller","options":[]}
  ]
}
```

V1 entry vocabulary is `line`, `choice`, `label`, and registered presentation/game-action commands.
Presentation cues and game actions live in separate registries with schemas and skip/replay metadata.
Profiles (`story_scene`, `map_talk`, `support`, `prison_visit`, `battle_bark`) own presentation and
interaction policy only. Templates such as `recruitable_enemy_talk` emit ordinary interactions,
requirements, conversations, and actions; they are not runtime profile types.

The V1 presenter is the accepted stage-over-chat-log overlay with static positioned portraits,
map/special background, manual advance, choice UI, history, control/help disclosure, and input parity.
Skip executes the identical journal path and stops at unresolved choices. Replay suppresses game
actions. Save during a conversation warns that load restarts at the preceding committed checkpoint;
no cursor, trail, presentation, or journal is persisted in V1.

### 3.7 Explore and Prison

Explore is a Prep option. It selects a deployable unit or non-deployable camp follower, then resolves
available activities from:

```text
campaign defaults → cadence patches → current CampaignNode add/remove/override patches
```

The Prison activity binds `visitor`, `prisoner`, `guard`, and `custody_owner`, evaluates shared
requirements, and launches a `prison_visit` conversation. It has no universal Recruit/Persuade/etc.
buttons and no separate persuasion score. Explicit conversation actions may change relationships,
facts, costs, attempts, cooldowns, recruitment, release, transfer, or death.

## 4. Data and save contracts

### Campaign definitions

- Conversation catalogue entries, profile entries, presentation/game-action command entries, text
  ids, portrait/background asset ids, low-code templates, and fixtures.
- Interaction definitions for Talk/Trade/Capture/Extract and convoy-provider policies.
- Campaign activity defaults, cadence patches, and `CampaignNode.activity_patches`.
- Aggression-matrix prisoner dispositions with optional dimension/predicate overrides and ordered
  affiliation fallback.
- Registered conditions/capabilities, stat constraint effects, objective selectors/quantifiers,
  extraction zones, key-item availability/restriction/fallback policies.

### Durable run state

- Five unit-state dimensions and recruitment duration/expiry data.
- Typed custody records keyed by stable captive id: owner, carrier/representation, cause, timestamps,
  extraction history, remaining inventory, and transition ids.
- Campaign custody/Prison roster and stable unit snapshots.
- Relationship graph and authored attempt/cooldown facts through their owning systems.
- Transition/event history sufficient for latched milestones; dynamic objective state remains derived.
- Activity/cadence state and node patches through campaign state.
- Trade/Convoy partial-action marks and carry state in mid-map snapshot/ledger only.

Do not persist V1 in-progress conversation state or an in-progress map-end journal. Saving during
either writes the preceding committed checkpoint. Save/load restarts the complete atomic workflow.
Add schema fields only in the vertical slice that validates, captures, restores, and tests them.

### Inventory and key items

A residual prisoner keeps bound/protected/key items; other eligible equipment moves to the appropriate
controlled-faction convoy at map end through the item ledger. Key-item policy independently declares
`present`, `requirement_accessible`, and `player_usable`; prisoner-held default is true/true/false,
pending author testing. Unit/class stat caps limit personal growth only and never clamp effective
effects.

## 5. Dependency-ordered implementation slices

### Slice 0 — Reconciliation and fixtures

- Amend DLG/RCR/RCV/DSP/VIL/STY/PHB/CNV/DTH/F1 sources to point to the DRC rulings.
- Add representative no-code fixtures before runtime work: atomic branch/recruit conversation,
  temporary guest, capture/release/extract, Trade with captive/passenger, designated Convoy provider,
  map-end Prison intake, relationship-gated prison visit, and contradictory stat floor/cap.
- Update pack/Tier-2 family inventories so extraction does not omit the new definitions.

Exit: validators can load fixture documents as inert data or report explicitly unsupported families;
no stale source claims mid-line save or capture-as-recruit.

### Slice 1 — Requirement foundation

- Implement typed requirement schema, composition limits, subject binding, result/reason type, registry,
  human display, and validator.
- Land core state/fact/resource/inventory/spatial/relationship predicates used by later slices.

Tests: truth tables, missing subjects, nested limits, unknown ids, deterministic display, headless
serialization, hostile/malformed pack fixtures.

### Slice 2 — Unit state dimensions and transition service

- Add runtime/persistent fields and compatibility adapter from legacy team/recruited assumptions.
- Implement typed transition request/result, staging support, duration/expiry, roster commit, turn/AI
  controller refresh, structured events, save/rewind codec, and projection purity.
- Permanent recruit commits `roster_status=member`; map-end guest requires explicit expiry outcome.

Tests: every dimension changes independently, permanent/map-end recruit, expiry precedence with death/
custody/permanent recruit, rollback, hotseat controller handoff, save/Retry/Rewind, malformed transition.

### Slice 3 — Conditions, stat constraints, and movement capabilities

- Replace ConditionManager stubs with registered conditions/capabilities and lifecycle ticking.
- Extend effective-stat resolver with additive → setter priority → cap → floor. Floors override caps;
  class/unit caps apply only during personal growth.
- Add hard external-movement target lock and separate initiation lock; only explicitly authorized
  story actions bypass them.

Tests: apply/cure/tick; equal-priority setter rejection; multiple setters/floors/caps; floor-over-cap;
growth cap versus effects; skill/condition sources; preview/display parity; story-override audit.

### Slice 4 — Spatial query, carry, custody, and extraction

- Add shared spatial query and virtual occupant adapters for Pair Up, Rescue, and custody.
- Add carry/custody registry and transactional attach/detach/drop/handoff.
- Captor fall releases captive on the vacated carrier tile, preserving sleep/conditions; subsequent
  escape uses authored cause-displacement rules.
- Add Escape-with-captive and Extract-captive tile actions. Extract fires whenever a captured unit is
  removed alive by those actions or map end.

Tests: occupancy invariants, locks, capacity predicates, carrier fall, blocked placement, attached
save/rewind, extraction causes, death exclusion, hostile rescue/transfer, map-edge behavior.

### Slice 5 — Trade and designated-provider Convoy

- Implement general Trade target policy and slot-swap service/panel.
- Permit adjacent real units and Pair Up/Rescue/captive occupants in actor or adjacent spaces subject
  to relationship/custody rules.
- Implement designated Convoy provider queries. V1 default permits friendly Pair Up/Rescue providers
  through lead/carrier tile and denies aggressively captured providers; policy is author-tunable.
- Implement partial action/location commitment and separate Trade/Convoy usage marks.

Tests: swaps/moves/empty slots/capacity, item identity and uses, key restrictions/fallback, captive
permissions without controller mutation, provider attachment matrix, cancel before/after transfer,
concluding actions, move-again, save/rewind, controller/faction convoy ownership.

### Slice 6 — Conversation catalogue, validator, and atomic journal

- Add conversation/profile/command registries, stable ids, text/assets, requirement binding, graph
  validation, cycle/budget checks, skip/replay metadata, and fixtures.
- Add ActionJournal and staged StateView support to primitives used by V1.
- Implement traversal, choices, overlay reads, successful commit, abort/failure, skip, and replay.

Tests: linear/branching traversal, staged reads, all-or-none mutation, duplicate ids, unreachable labels,
unknown roles/commands/assets/text, loop/budget rejection, skip equivalence, replay suppression.

### Slice 7 — Dialogue presenter and checkpoint behavior

- Build the stage/chat-log overlay and profile-driven interaction controller using shared UI state,
  wide/narrow composition, native focus, controller region transitions, menu scale, touch parity, and
  accessible history.
- Add save warning and restart-from-prior-checkpoint behavior; interruption discards journal.

Tests: presenter state separate from data/runtime, decision ownership, controller/hotseat choice input,
  cancel policy, focus restoration, localization expansion, input parity, Save/Load restart, scene leak.
Windows playtest: keyboard/controller/touch-emulation, 100–200% menu scale, map/special backgrounds,
history, choice confirmation, skip-to-choice, save warning/relaunch.

### Slice 8 — Talk and recruitment integration

- Add registered unit interaction definitions and Talk target query with directed/symmetric policy.
- Bind dialogue roles and route recruit actions through UnitTransitionService.
- Add player eligibility/disabled-reason previews, action cost, activation outcome, immediate permanent
  roster insertion, and map-end guest expiry.

Tests: initiator direction, relationship/condition gates, hostile/allied/temporary sides, action cost,
  staged recruit rollback, turn-order/controller refresh, roster/save state, survival-dependent guest.

### Slice 9 — Objective milestones and atomic map-end resolver

- Add selector/quantifier objective schema with snapshot default and opt-in disclosed dynamic sets.
- Implement dynamic Incapacitate and Capture, historical variants, latched Extract, and extraction-zone
  satisfiability validation. Extract may be sole victory only with a compatible route.
- Replace immediate TurnManager finalization with named staged map-end phases and one V1 journal.
- Run authored end-map events, relation-specific dispositions, residual inventory/Prison intake,
  final victory/defeat evaluation, rewards, result signals, and campaign commit atomically.

Tests: post-action reevaluation only, multi-target atomicity, wake/release revocation, extract routes,
  snapshot/dynamic targets, simultaneous victory/defeat precedence, disposition-caused required-survival
  defeat, event failure rollback, result/reward single emission, Save restart.

### Slice 10 — Explore/Prison

- Add campaign activity defaults, cadence changes, and node add/remove/override patches.
- Add subject-first Explore selection across deployable members and camp followers.
- Add custody roster/Prison panel and prison_visit conversation launcher with requirements, availability,
  key-item status, selected visitor, guard role, relationship/fact/resource actions, and activity cost.

Tests: activity merge order, stable ids, missing visitors/prisoners, no passive relationship gains,
  recruit/release/transfer/death outcomes, attempts/cooldowns, key availability, save/load, empty Prison,
  controller/faction privacy. Windows playtest covers navigation, disabled reasons, conversation return,
  roster refresh, and node/cadence changes.

### Slice 11 — Migration, authoring tools, and release review

- Provide import adapters for legacy dialogue/recruit/capture/objective/save data only at boundaries.
- Ship minimal low-code forms/templates, target/requirement pickers, graph validation, conversation
  simulator with staged diff, objective satisfiability preview, and fixture runner.
- Update GDD 01–08 where behavior changes, GDD 10, Feature Index, Control Plane, save manifest, author
  guides, and open-registry guards in the same slices.
- Run full automated suite, export validation, Windows end-to-end campaign, save/reload/rewind, and
  hostile-content fixtures before release promotion.

## 6. Low-code minimum and validation gates

The minimum author tool is schema-driven rather than a bespoke full editor:

- create from validated templates; edit stable ids, roles, lines, choices, requirements, actions,
  activity policies, objectives, and dispositions through pickers/forms;
- inspect resolved campaign/node/activity/provider policies and unmet reasons;
- simulate a conversation with chosen subjects and show staged versus committed changes;
- preview Trade/Talk/Capture/Extract target sets and objective target snapshots;
- validate all references, graph reachability, authority, lifecycle, save fields, localization/assets,
  action staging support, and platform/resource budgets;
- export identical plain data consumed by runtime.

Pack activation/export must fail on unknown runtime vocabulary, unresolved refs, ambiguous transitions,
unsupported staged actions, unsafe story overrides, unsatisfiable sole-extract objectives, illegal key
fallbacks, or incompatible schema versions. Warnings cover author-test-sensitive defaults, dynamic
objective membership, prisoner-held key accessibility, and unusually broad permissions.

## 7. Cross-system review and V1 cuts

### Required shared foundations

- `[REQ]` is one system for Dialogue, objectives, activities, items, shops, and events.
- ActionJournal/StateView is one transaction foundation for Dialogue and map-end resolution.
- SpatialTargetQuery is one geometry seam for interactions; filters remain domain-owned.
- UnitTransitionService is one authority for recruitment/custody/control/roster changes.
- InventoryTransferService is one instance ledger for Trade, Convoy, and prisoner disposition.

### Explicit V1 deferrals

- mid-conversation or phase-boundary committed checkpoints;
- animated portrait/effect tiers, reflect, camera, scene filters, and full dialogue editor;
- free-text intent resolution beyond the abstract decision-provider seam;
- generic persuasion simulation, prison economy, passive prison timers, or systemic prison escape;
- confiscation/escrow/restoration UI beyond Trade and map-end residual disposition;
- arbitrary Trade/Convoy policy combinations without implemented action/AI support;
- stat contests/RNG displacement resistance beyond deterministic V1 locks;
- remote multiplayer authority transport.

### Plan acceptance gates

Before Slice 1 begins, review this plan against the pack-save, zero-content, formula-registry,
prep/economy, UI architecture, and text-entry plans. The save schema must reserve five-dimensional
state and custody without embedding immutable content; the zero-content catalogue must include every
new authoring family; formula/requirement registries must not duplicate one another; Prep/Convoy must
use shared wallet/inventory ownership; and all dialogue text entry must comply with the minimize-free-
text rule.
