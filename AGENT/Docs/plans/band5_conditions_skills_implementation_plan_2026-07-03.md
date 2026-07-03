---
Type: plan
Status: Active - implementation plan
Last verified: 2026-07-03
---

# Band 5 Conditions And Skill Effects Implementation Plan

**Started:** 2026-07-03.

**Track IDs:** `B5-CONDITIONS`, `B5-DURATION-LIFECYCLE`, `B5-SKILLS-EFFECTS`,
`B5-LOADOUT-CAPS` (shell + skills adapter only).

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
Band 5 rows. Drafted from
[`band5_implementation_plan_handoff_2026-07-02.md`](band5_implementation_plan_handoff_2026-07-02.md)
(Content-chain steps 1-3) against the settled **Q1/Q4** walkthrough decisions of
2026-07-01.

## Purpose

Build the first content-chain foundation of Band 5: a single combined condition
+ duration-lifecycle substrate, the effect-id registry conversion for skills,
and the loadout-panel shell with its skills adapter. Conditions underlie skills,
staves (Plan 2), and action grants (Plan 3); the lifecycle store is shared by
IEQ equipment (`until_unequipped`) and Band 5 conditions/skills — one lifecycle
engine, many producers, not one per feature.

This is a build plan only. It does not authorize starting `B5-CONDITIONS` before
the Band 1-3 gates and (for the accessory lifecycle producer) `B4-IEQ` land.

## Scope

1. Turn the `ConditionManager` M8 stub into a real registry-backed condition
   substrate: `ConditionDef` data, per-unit active-condition store, apply /
   refresh / remove / cure / tick, and per-turn effects (poison damage).
2. Land the **general capability-gating primitive**: conditions suppress named
   capability tags (`attack`, `staff_use`, `skill_use`, `move`, `trade`, …) that
   actions declare they require; sleep suppresses all; berserk overrides target
   selection. Adding a condition or a gated capability stays pure data.
3. Land the shared **duration-lifecycle store** (`B5-DURATION-LIFECYCLE`):
   `until_unequipped` / `until_end_of_map` / fixed-N tick modes, with conditions
   as the first Band 5 producer and IEQ equipment registering into the same
   store.
4. Convert `SkillHandler`'s hardcoded `_dispatch` seam into a
   registry-backed effect-id lookup (`B5-SKILLS-EFFECTS` machinery), add
   grant/revoke, and wire the `on_level_up` engine trigger.
5. Build the `LoadoutPanel` shell with registry-backed category adapters and ship
   the **skills adapter first** (`B5-LOADOUT-CAPS` shell only; styles/sources
   adapters land in Plan 2).

The **Q2 required-v1 effect/condition manifest is DEFERRED** (demo-campaign
gated). This plan builds the machinery and proves it with fixtures only; the
manifest slots in as a late content slice.

## Non-Goals

- Do not finalize the v1 effect/condition/staff manifest (Q2 — demo-campaign
  gated). Build machinery + fixtures; leave the concrete id list to the content
  slice.
- Do not build Source+Style, utility staves, action grants, or secondary
  movement here. They consume this foundation in Plans 2 and 3.
- Do not build the styles or granted-sources loadout adapters — only the shell +
  skills adapter. Plan 2 registers the other adapters into this shell.
- Do not add a second lifecycle implementation for equipment. `B4-IEQ`'s
  `until_unequipped` producer registers into the store this plan builds.
- Do not replace author-facing condition ids, capability tags, effect ids, or
  duration modes with a closed `enum` + `match`. If blocking an action needs an
  engine `match`, the substrate is wrong (Q1 watchout).
- Do not add saved condition/skill/loadout fields without F1 manifest rows.

## Source Docs

- [`band5_implementation_plan_handoff_2026-07-02.md`](band5_implementation_plan_handoff_2026-07-02.md)
- [`band5_plus_preimplementation_questions_review_2026-06-30.md`](../../Code%20Reviews/band5_plus_preimplementation_questions_review_2026-06-30.md)
  → "Walkthrough Decisions (2026-07-01)" Q1, Q4.
- [`skill_model_open_questions_2026-06-23.md`](../registers/skill_model_open_questions_2026-06-23.md)
- [`loadout_cap_open_questions_2026-06-27.md`](../registers/loadout_cap_open_questions_2026-06-27.md)
- [`band1_determinism_save_implementation_plan_2026-06-30.md`](band1_determinism_save_implementation_plan_2026-06-30.md)
- [`band2_shared_runtime_contracts_implementation_plan_2026-06-30.md`](band2_shared_runtime_contracts_implementation_plan_2026-06-30.md)
- [`band3_core_authoring_foundations_implementation_plan_2026-06-30.md`](band3_core_authoring_foundations_implementation_plan_2026-06-30.md)
- [`band4_items_equipment_implementation_plan_2026-06-30.md`](band4_items_equipment_implementation_plan_2026-06-30.md)
  (the `until_unequipped` producer boundary — see Q-B5-3).

## Decisions Not To Reopen

- One combined condition + lifecycle substrate; conditions, duration modes,
  capability gating, and cure hooks are one system, not four.
- Capability gating is general: conditions suppress declared capability tags;
  actions declare the tags they require. No per-condition engine branch.
- Sleep suppresses all capabilities; berserk overrides target selection rather
  than suppressing capabilities.
- Duration lifecycle is one store with many producers. `B4-IEQ`'s
  `until_unequipped` equipment producer and Band 5 conditions/skills register
  into it.
- Conditions, capability tags, effect ids, and duration modes are open
  registries / pure data.
- Effects execute through `B2-ACTION-EFFECT`; forecasted conditions render
  through `B2-PROJECTION`.
- The loadout shell iterates registered categories; each declares its own
  cap-rule predicate and row renderer. A new category is a registration, not a
  panel edit.
- Earned superset / equipped subset caps: a unit's learned skills are the
  superset; equipped skills are the capped subset.
- F1 owns saved fields (active conditions, lifecycle entries, learned/equipped
  skills, skill counters) before code.

## Dependency Note

Plan now; implement after gates. Minimum upstream gates before code:

- `B1-F1` for saved-field rows: active conditions, lifecycle-store entries,
  learned/equipped skill loadout, and skill counters.
- `B2-REGISTRY` for condition ids, capability tags, effect ids, and loadout
  category ids.
- `B2-ACTION-EFFECT` for the effect execution seam skills/conditions run
  through.
- `B2-PROJECTION` for forecasted condition application/expiry (poison tick, cure
  preview).
- `B3-REQ` for loadout cap predicates and condition-apply target filters.
- `B3-PHB` for the prep-hub panel host the `LoadoutPanel` mounts in.
- `B3-STAT-REGISTRY` so poison/condition stat effects target author stats.
- `B4-IEQ` (Slice 5 accessory lifecycle) for the `until_unequipped` producer
  that registers into this plan's lifecycle store.

## Existing Code Touchpoints

Verified 2026-07-03:

- `scripts/autoloads/ConditionManager.gd` (37 lines) is an M8 stub — all methods
  no-op. It already fixes the five v1 condition id constants (`poison`, `sleep`,
  `silence`, `berserk`, `stun`) and the autoload order
  (`… DataManager → ConditionManager`). This plan fills the stub.
- `scripts/resources/UnitData.gd` already has
  `conditions: Array[Dictionary]` (`[{ "type": "poison", "turns_remaining": 3 }]`),
  `skills` (equipped), a learned-skills array, `skill_use_counters: Dictionary`,
  and `ai_profile`. Snapshot-captured fields are documented inline.
- `scripts/skills/SkillHandler.gd` (473 lines) already builds a `_dispatch:
  Dictionary` of `effect_id → Callable` in `_ready()` — a registry in spirit but
  hardcoded. `NIHIL_EXEMPT_SKILLS` and per-combat/per-map counters exist. This is
  the seam `B5-SKILLS-EFFECTS` migrates to registry-backed lookup.
- `scripts/resources/SkillData.gd` lists triggers including `on_level_up`, which
  is the unwired engine trigger to resolve. `activation_chance_stat` /
  `activation_divisor` already route activation rolls; those rolls must go
  through `RngService` (Band 1) and any contest through F16 `REQ-10`.
- `scripts/core/TurnManager.gd` is the caller of `ConditionManager.tick_conditions`
  at each unit activation; capability gating hooks the action-menu / turn flow.
- `scripts/ui/ActionMenu.gd` already gates Attack / Staff / Skill rows — the
  capability-tag check plugs in here.
- Tests to extend: `test_condition_manager.gd` (new), `test_skill_item_handler.gd`,
  `test_turn_manager.gd`, `test_snapshot_coverage.gd`, `test_unit_details_screen.gd`.

## Slice 0 - Preflight After Band 1-3 Gates

**Goal:** confirm the substrate can be built without breaking the stubbed
condition/skill paths.

Implementation checklist:

- Run `rg -n "ConditionManager|apply_condition|tick_conditions|has_condition|_dispatch|skill_use_counters|conditions" scripts data`.
- Confirm F1 rows exist or reserve them: `UnitData.conditions` (promoted to the
  new active-condition shape), lifecycle-store entries, learned/equipped skill
  loadout arrays, `skill_use_counters`.
- Confirm `RegistryManager`, `B2-ACTION-EFFECT`, `B2-PROJECTION`, `B3-REQ`,
  `B3-PHB`, and `B3-STAT-REGISTRY` are in place.
- Confirm the old `GDD_10` M8 condition checklist has been rewritten around the
  registry/condition lifecycle (control-plane `B5-CONDITIONS` next-action) — do
  this rewrite as part of this slice's docs work if not already done.

Tests: none required in preflight.

## Slice 1 - ConditionDef And Capability-Tag Registry

**Goal:** add the condition vocabulary as data and the capability-tag surface
actions declare against, without behavior yet.

Files to create or touch:

- `scripts/resources/ConditionDef.gd`
- `scripts/autoloads/DataManager.gd` (load/validate condition defs)
- `scripts/autoloads/RegistryManager.gd` (capability-tag ids)
- `scripts/tests/test_condition_def.gd`
- developer preset data under the `B2-REGISTRY` condition path.

Implementation steps:

1. Add `ConditionDef` fields: `id`, `display_name`, `description`,
   `icon` (id/path per the asset resolver), `suppresses` (Array of capability
   tags), `overrides_targeting` (bool, for berserk), `per_turn_effect`
   (effect-id + params, e.g. poison damage), `default_duration_mode`, `stackable`
   / refresh policy, and `cured_by` tags (Restore/Panacea hooks).
2. Register capability-tag ids (`attack`, `staff_use`, `skill_use`, `move`,
   `trade`, …) through `RegistryManager`. Actions reference these ids; the set
   grows by data.
3. Add validators: unknown capability tag, unknown per-turn effect id, unknown
   cure tag, missing id.
4. Load condition defs through `DataManager` validate/report phases.

Tests:

- A poison def validating with a `per_turn_effect`.
- A silence def suppressing `[staff_use, skill_use]` validates.
- Unknown capability tag / effect id / cure tag reports a useful error.
- Condition defs load deterministically.

F1 obligations: no saved state in this slice (defs are content, not save).

DoD#2 obligations: add a validator test that a new `ConditionDef` + new
capability tag load through registry data with no engine switch edit.

## Slice 2 - Duration-Lifecycle Store

**Goal:** one lifecycle engine with `until_unequipped` / `until_end_of_map` /
fixed-N tick modes, keyed by stable source, that many producers register into.

Files to create or touch:

- `scripts/autoloads/LifecycleStore.gd` (or a `RefCounted` owned by an existing
  autoload — pick per Band 2 service conventions)
- `scripts/resources/UnitData.gd` (per-unit lifecycle entries)
- `scripts/autoloads/TurnManager.gd` (end-of-map + tick hooks)
- `scripts/tests/test_lifecycle_store.gd`
- `scripts/tests/test_snapshot_coverage.gd`

Implementation steps:

1. Add a lifecycle entry shape: `{ source_key, payload_ref, mode, remaining }`
   where `mode ∈ {until_unequipped, until_end_of_map, fixed_n}` (mode ids are
   registry data, not a closed enum) and `source_key` is stable and unique
   (mirrors the `B4-IEQ` `item:<instance_id>:<stat>` convention).
2. Add `register(entry)`, `remove(source_key)`, `tick(unit)` (decrements
   fixed-N; fires expiry), and `clear_end_of_map()` hooks.
3. `TurnManager` calls `tick` at the right activation point and
   `clear_end_of_map()` on map clear/cancel. Confirm ordering against the
   condition tick in Slice 3 (one tick pass, not two).
4. Snapshot coverage: lifecycle entries are mutable runtime state — deep-copy
   safe, survive suspend (except `until_unequipped`, re-derived from equipment on
   load if cheaper — decide per Q-B5-3).

Tests:

- Fixed-N entry decrements and expires on the right tick.
- `until_end_of_map` entry clears on map clear, survives suspend mid-map.
- `until_unequipped` entry removed when its producer deregisters.
- Snapshot/restore round-trips lifecycle entries.

F1 obligations: lifecycle-store entries need manifest rows before code.

## Slice 3 - ConditionManager Behavior

**Goal:** fill the stub — apply / refresh / remove / cure / tick, wired to the
lifecycle store and capability gating.

Files to touch:

- `scripts/autoloads/ConditionManager.gd`
- `scripts/resources/UnitData.gd` (active-condition store shape)
- `scripts/core/TurnManager.gd`
- `scripts/ui/ActionMenu.gd` (capability gating)
- `scripts/units/Unit.gd` (targeting override for berserk)
- `scripts/tests/test_condition_manager.gd`

Implementation steps:

1. Promote `UnitData.conditions` to reference the active-condition store (still
   an `Array[Dictionary]` per entry, but each entry now names a `ConditionDef`
   id + a lifecycle `source_key`).
2. Implement `apply_condition` (register a lifecycle entry per the def's duration
   mode; refresh policy from the def), `remove_condition`, `has_condition`,
   `clear_all_conditions`, and `cure(tags)` for Restore/Panacea.
3. `tick_conditions` fires each condition's `per_turn_effect` through
   `B2-ACTION-EFFECT` and lets the lifecycle store decrement/expire.
4. Capability gating: add `unit_capability_suppressed(unit, tag)` reading the
   union of the unit's active conditions' `suppresses`. `ActionMenu` and the
   action flow disable rows whose declared capability tag is suppressed. Sleep =
   a def suppressing all tags.
5. Berserk: `overrides_targeting` reroutes target selection (hostile-to-all)
   without touching capability suppression.
6. Route condition application forecasts through `B2-PROJECTION` (poison tick,
   cure preview) so the AI and UI see the same outcome.

Tests:

- Poison ticks damage each activation and expires on schedule.
- Silence disables the staff/skill action rows but not attack/move.
- Sleep disables all action rows; waking (cure or duration) restores them.
- Berserk retargets without suppressing capabilities.
- `cure`/`clear_all_conditions` removes conditions and their lifecycle entries.
- Snapshot/restore round-trips active conditions.

F1 obligations: active-condition store rows must exist before code.

DoD#1 obligations: update `GDD_02`, `GDD_05`, `GDD_Feature_Index`, and `GDD_10`
M8 with the condition behavior landing.

## Slice 4 - Skill Effect Registry Conversion

**Goal:** migrate `SkillHandler`'s hardcoded dispatch to registry-backed effect
lookup and add grant/revoke + the `on_level_up` trigger. No new content ids.

Files to touch:

- `scripts/skills/SkillHandler.gd`
- `scripts/resources/SkillData.gd`
- `scripts/autoloads/RegistryManager.gd`
- `scripts/core/LevelUpScreen.gd` / the level-up flow (for `on_level_up`)
- `scripts/tests/test_skill_item_handler.gd`

Implementation steps:

1. Register skill effect ids through `B2-ACTION-EFFECT` / `RegistryManager`;
   `SkillHandler._dispatch` becomes a lookup into the registry rather than a
   literal built in `_ready()`. Existing effect handlers register as the
   built-in default set.
2. Add grant / revoke: a skill or effect may grant another effect id (data), and
   revoke it on expiry — routed through the lifecycle store for durationed
   grants. Keep `NIHIL_EXEMPT_SKILLS` semantics.
3. Wire the `on_level_up` trigger: the level-up flow calls the skill trigger
   pass. This is the must-resolve engine trigger from Q2 (engine, not content).
4. Keep per-combat / per-map counters (`skill_use_counters`) intact; ensure
   activation rolls route through `RngService` and any opposed check through F16
   `REQ-10`.

Tests:

- Existing skill effects still fire through the registry lookup (no behavior
  change).
- A fixture skill granting/revoking an effect applies and cleanly reverts.
- `on_level_up`-triggered fixture skill fires exactly once per level-up.
- Unknown effect id fails through registry validation (startup error, not silent
  no-op — preserves the current `SkillHandler` guarantee).

F1 obligations: learned/equipped skill loadout + counters need rows (shared with
Slice 5).

DoD#2 obligations: add a guard that a new skill effect id registers as data and
does not require editing a closed dispatch literal.

## Slice 5 - Loadout Panel Shell And Skills Adapter

**Goal:** one `LoadoutPanel` shell iterating registered category adapters; ship
the skills adapter (earned superset / equipped subset with caps).

Files to create or touch:

- `scripts/ui/LoadoutPanel.gd` + scene
- `scripts/loadout/LoadoutCategoryAdapter.gd` (interface / base)
- `scripts/loadout/SkillsLoadoutAdapter.gd`
- `scripts/resources/UnitData.gd` (equipped subset field if not already present)
- `scripts/autoloads/GameState.gd` (caps source)
- `scripts/tests/test_loadout_panel.gd`

Implementation steps:

1. Define the category-adapter interface: `list_earned(unit)`,
   `list_equipped(unit)`, `cap_predicate(unit)` (count vs weight vs slot — a
   `B3-REQ` predicate), `row_renderer(entry)`, `can_equip(unit, entry)`,
   `equip`/`unequip`.
2. `LoadoutPanel` iterates registered categories (registry, not a hardcoded
   three), rendering each category's rows via its renderer and enforcing its cap
   predicate. Mounts in the `B3-PHB` prep hub (prep-only).
3. Skills adapter: earned = learned skills; equipped subset capped by
   `GameState.max_skills` (the existing cap). Enforce cap + auto-unequip on cap
   reduction (e.g. reclass). Route the equipped set through F1-saved fields.
4. Leave `register_category(id, adapter)` open so Plan 2 registers styles and
   granted-sources adapters with no panel edit.

Tests:

- Skills adapter lists earned superset and capped equipped subset.
- Equipping past the cap is rejected; reducing the cap auto-unequips the
  overflow.
- The panel iterates a second fixture category without a panel-code edit
  (proves the registry seam Plan 2 relies on).
- Equipped loadout round-trips through snapshot/save.

F1 obligations: equipped-skill loadout + any per-unit cap override rows must
exist before code.

DoD#1 obligations: update `GDD_05`, `GDD_07`, `GDD_Feature_Index`, `GDD_10` with
the loadout panel landing.

DoD#2 obligations: add a guard that a new loadout category registers into the
shell without editing `LoadoutPanel` category logic.

## Implementation Commit Order

1. Slice 0 preflight (no code; gate confirmation + M8 checklist rewrite).
2. Slice 1 `ConditionDef` + capability-tag registry.
3. Slice 2 lifecycle store (shared engine).
4. Slice 3 `ConditionManager` behavior + capability gating.
5. Slice 4 skill effect registry conversion + `on_level_up`.
6. Slice 5 loadout shell + skills adapter.

Land the `until_unequipped` producer join with `B4-IEQ` Slice 5 (one lifecycle
engine, two producers). Do not start before the Band 1-3 gates and `B4-IEQ` (for
the accessory producer) exist. The Q2 manifest is a later demo-gated content
slice on top of this machinery.

## Verification Checklist

Same as the Band 2/3/4 plans. Run after each implementation slice:

```bash
python3 AGENT/Docs/check_docs.py
git diff --check
./run_tests.sh
```

Docs-only edits to this plan require:

```bash
python3 AGENT/Docs/gen_docs_index.py
python3 AGENT/Docs/check_docs.py
git diff --check
```
