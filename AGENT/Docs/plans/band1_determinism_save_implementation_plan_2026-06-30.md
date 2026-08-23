---
Role: dated
Type: plan
Status: Active - implementation plan
Last verified: 2026-06-30
---

# Band 1 Determinism And Save Implementation Plan

**Track IDs:** `B1-PKGA`, `B1-F1`, `B1-SAVECODEC`, `B1-CST`

## Purpose

Turn the already-ratified Band 1 design docs into a code-ready execution
sequence. This plan exists to guide implementation; it does not reopen Package A,
F1, or campaign/save decisions.

## Scope

This plan covers the first Band 1 implementation run:

1. `B1-PKGA` Step 1: `RngService` autoload, gameplay RNG migration, two-RN hit,
   and raw-RNG guard.
2. `B1-PKGA` Step 2: include `RngService` state in the existing Retry/snapshot
   path.
3. `B1-F1`: create the first F1 save-schema manifest from the source inventory.
4. `B1-SAVECODEC` / `B1-CST` kickoff: build the JSON-safe codec, `SaveData`
   envelope, old-save default fixtures, Retry-on-codec migration, and the
   CampaignRules consolidation kickoff plan.

## Non-Goals

- Do not build the full Turnwheel mechanic in the first campaign/save kickoff.
  `[CST-13]` is resolved to hooks-only inside the campaign/save spine; the full
  mechanic is the immediate follow-on after `SaveCodec`, `SaveData`, and
  CampaignRules charge persistence exist.
- Do not build full mid-battle suspend in this plan. `B1-SUSPEND` follows after
  `SaveCodec` / `SaveData` and exact runtime fields are locked.
- Do not build the whole campaign loop in one step. This plan stops at the
  save/campaign spine kickoff and leaves prep, results, Continue/Load UI, and
  export/import as later `B1-CST` slices.
- Do not add Band 2 registries or Band 3+ feature state without F1 manifest
  rows.
- Do not add author-facing closed enums where future content needs an open
  registry.

## Source Docs

- [`rng_determinism_design_2026-06-11.md`](../design/rng_determinism_design_2026-06-11.md)
- [`package_a_rngservice_open_questions_2026-06-21.md`](../registers/package_a_rngservice_open_questions_2026-06-21.md)
- [`f1_save_schema_lock_design_2026-06-28.md`](../design/f1_save_schema_lock_design_2026-06-28.md)
- [`f1_save_schema_manifest_contract_2026-06-28.md`](../design/f1_save_schema_manifest_contract_2026-06-28.md)
- [`f1_schema_source_inventory_2026-06-28.md`](f1_schema_source_inventory_2026-06-28.md)
- [`campaign_save_technical_plan_2026-06-21.md`](campaign_save_technical_plan_2026-06-21.md)
- [`campaign_save_open_decisions_2026-06-21.md`](../registers/campaign_save_open_decisions_2026-06-21.md)
- [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)

## Decisions Not To Reopen

- `[PKGA-1]`: Package A is the first execution milestone.
- `[PKGA-2]`: only Package A Steps 1-2 gate campaign/save.
- `[PKGA-3]`: `rewind_charges` lands with CampaignRules consolidation, not
  Package A Step 1.
- `[PKGA-4]`: two-RN hit ships with Package A Step 1.
- `[CST-1]`: `SaveManager` owns file I/O; `SaveData` is the pure seam.
- `[CST-2]`: one JSON-safe serializer serves both Retry and persistent save.
- `[CST-4]`: hard-migrate rules to `gs.campaign_rules.*`; no loose-field shims.
- `[CST-8]`: suspend is between committed actions for human-controlled factions.
- `[CST-12]`: Package A precedes the campaign/save spine.

## Code Grounding Checklist

Current code touchpoints verified 2026-06-30:

- `project.godot` autoload order is `GameConstants`, `EventBus`,
  `SettingsManager`, `GameState`, then data/gameplay services. Insert
  `RngService` after `EventBus` and before `SettingsManager` / `GameState`.
- Raw gameplay RNG currently exists at:
  - `scripts/core/CombatResolver.gd`: hit and crit rolls.
  - `scripts/units/Unit.gd`: random growth rolls in `_level_up_random`.
  - `scripts/skills/SkillHandler.gd`: `activation_chance_stat` rolls.
- Existing Retry snapshot ownership is in `scripts/autoloads/GameState.gd`:
  `take_map_snapshot`, `restore_map_snapshot`, `_snapshot_unit_data`, and
  `_restore_unit_data`.
- Combat callers to update are:
  - `scripts/core/MapCursorTargeting.gd`
  - `scripts/core/EnemyAI.gd`
  - combat tests / mocks under `scripts/tests/`.
- Existing action commit points to audit for non-dice event commits:
  `MapCursor._finish_action`, `MapCursor._commit_seize`,
  `MapCursor._commit_escape`, `ItemHandler.apply_item`, and
  `TurnManager.set_unit_state`.
- Test harness is glob-discovered through `run_tests.sh`; add `test_*.gd`
  suites under `scripts/tests/`.
- CI wrapper is `scripts/ci/run_headless_tests.sh`.

## Slice 0 - Preflight

**Goal:** make the first code change small enough to review.

Implementation checklist:

- Run `rg -n "randi|randf|RandomNumberGenerator|randomize" scripts`.
- Run `rg -n "resolve_combat|apply_combat_result|set_unit_state|record_move_start|apply_item|record_seize|record_escape" scripts`.
- Confirm the exact Godot version accepts the signed decimal mixer constants
  from the RNG design. If it rejects them, re-express the same values as hex
  integer literals; do not change the mixer math.
- Note the agreed combat event-record API shape (this API does **not** exist
  yet — Slice 1b adds it): `TurnManager.get_action_start_tile(unit)` supplies
  the pre-move tile; combat callers pass
  `[attacker_id, from_tile, to_tile, defender_id]` into
  `resolve_combat(attacker, defender, event_record := [])`; the result stores
  the same record for `apply_combat_result`.

Tests:

- No new test required in this slice.

Docs:

- If the official event-record API exposes a real blocker, update
  [`band1_implementation_questions_review_2026-06-30.md`](../../Code%20Reviews/band1_implementation_questions_review_2026-06-30.md)
  instead of pausing implementation.

## Slice 1 - `B1-PKGA` Step 1: RngService And RNG Migration

**Goal:** all gameplay dice route through deterministic event RNG, and future raw
gameplay RNG is blocked by tests.

This step is split into four sub-slices so each lands as a small, independently
green, independently bisectable commit. The original single-commit form touched
eight production files and migrated three unrelated RNG sites at once, which is
hard to review and hard to bisect when a determinism test regresses.

**Ordering constraint (do not reorder):** the raw-RNG guard must land *last*, in
Slice 1d. While raw RNG still exists in `CombatResolver`, `Unit`, and
`SkillHandler` (i.e. before Slices 1b/1c land), the guard would fail on
still-present code. Slices 1a-1c each stay green on their own; the guard closes
the door only once there is no raw gameplay RNG left to flag.

### Slice 1a - RngService autoload (behavior-neutral)

Files to touch:

- `project.godot`
- `scripts/autoloads/RngService.gd` (new)
- `scripts/tests/test_rng_service.gd` (new)

Implementation steps:

1. Add `scripts/autoloads/RngService.gd`.
   - Implement `map_seed`, `history_hash`, `start_map`, `begin_event`,
     `commit_event`, `to_save_dict`, `from_save_dict`, `_mix`,
     `_hash_string`, and `_entropy_seed`.
   - Keep presentation randomness out of this service.
2. Register `RngService` in `project.godot`.
   - Exact order: `GameConstants`, `EventBus`, `RngService`,
     `SettingsManager`, `GameState`, then the existing services.
   - This order is enforced by `check_docs.py` check 21 once the autoload exists.

Tests:

- `test_rng_service.gd`
  - fixed seed produces stable event numbers,
  - identical event + identical history repeats,
  - different committed history changes later events,
  - `to_save_dict` / `from_save_dict` preserves `map_seed` and `history_hash`.

Docs and tracking:

- Behavior-neutral: no GDD update. Note the new autoload on the `B1-PKGA` row.

### Slice 1b - Combat RNG migration (behavior-changing: two-RN hit)

Files to touch:

- `scripts/core/CombatResolver.gd`
- `scripts/core/MapCursorTargeting.gd`
- `scripts/core/EnemyAI.gd`
- `scripts/core/TurnManager.gd`
- `scripts/tests/test_rng_combat_determinism.gd` (new or folded into
  `test_combat.gd` if simpler)

Implementation steps:

1. Add combat event-record plumbing.
   - `TurnManager.get_action_start_tile(unit)` returns the recorded move-start
     tile, falling back to `unit.tile_position`.
   - `CombatResolver.make_attack_event_record(attacker, defender, from_tile)`
     returns `[attacker_id, from_tile, to_tile, defender_id]`.
   - `resolve_combat(attacker, defender, event_record := [])` uses the passed
     record or a deterministic fallback for headless tests.
   - The result dictionary stores `rng_event_kind` and `rng_event_record`.
   - `apply_combat_result` commits the stored record exactly once.
   - Do not let `TurnManager` double-commit combat.
2. Migrate `CombatResolver` hit and crit rolls behind the author-selectable
   roll-resolver seam (`[CRR-1..8]`, see
   [`combat_roll_resolver_open_questions_2026-06-30.md`](../registers/combat_roll_resolver_open_questions_2026-06-30.md)).
   - `resolve_combat` calls `RngService.begin_event("attack", record)` after
     `combat_started` and before the first roll.
   - Store the returned RNG in the combat context as `"rng"`.
   - **Do not hard-code the two-RN rule at the roll site.** Build a small pure
     resolver seam now (`[CRR-2]`): the engine draws a resolver-declared, fixed
     `rn_count` of `[0,100)` integers in canonical order and passes them to a
     pure `did_hit(displayed_hit, rns) -> bool`.
   - Ship two built-in resolvers: `two_roll` (RULE-001 default,
     `(rns[0] + rns[1]) / 2 < hit`) and `single_roll` (`rns[0] < hit`).
   - Select the resolver from `CampaignRules.hit_formula` (campaign default;
     `two_roll` is the default value). Two built-ins = a bounded set, not a
     content-growth enum; registry promotion + author tiers are the Band 3
     follow-on `B3-COMBAT-ROLL-RESOLVER`, not this slice.
   - Crit draws only after a hit. Keep crit a single draw for now; `[CRR-6]`
     reserves the resolver family for crit/activation later.
   - Preserve the existing exchange order.

Tests:

- `test_rng_combat_determinism.gd`
  (T-numbers here and below are the §10 test matrix of
  [`rng_determinism_design_2026-06-11.md`](../design/rng_determinism_design_2026-06-11.md);
  full coverage across this plan: T1/T3/T7 in this slice, T4/T5 in Slice 1d,
  T2 in Slice 2, T6 with the `B1-SUSPEND` follow-on)
  - T1 replay determinism for a scripted attack sequence,
  - T3 butterfly/isolation with Wait or another committed action between two
    attacks,
  - T7 literal roll-order fixture for **each** built-in resolver
    (`single_roll` and `two_roll` reproduce their literal outcomes for fixed
    `rns`).
- `test_combat.gd` and `test_enemy_ai.gd` must stay green. **Watchout:** any
  existing fixture that hard-codes a single-RN hit/miss outcome must be rewritten
  to the configured resolver's expectation in this same commit — "stay green"
  here means *updated*, not unchanged.

Docs and tracking:

- This changes player-visible hit math **and** reframes a ratified rule. In the
  same commit: update `GDD_01`, `GDD_02`, the RNG design doc, and the decision
  log so RULE-001 reads as the **default** resolver preset, not the only hit rule
  (`[CRR-1]`); update the `B1-PKGA` row; add a playtest note that the default hit
  RNG is two-RN true hit and is now author-selectable.
- F1: reserve a `campaign.hit_formula` manifest row in Slice 3 / Slice 6
  (`[CRR-4]`).

### Slice 1c - Growth and skill-activation migration

Files to touch:

- `scripts/skills/SkillHandler.gd`
- `scripts/units/Unit.gd`
- `scripts/tests/test_skill_item_handler.gd` (extend)

Implementation steps:

1. Migrate `SkillHandler` activation rolls.
   - Random activation reads `context["rng"]`.
   - Preview paths still skip random activations and draw nothing.
   - If `context["rng"]` is missing in a non-preview gameplay path, fail loudly
     instead of silently falling back to raw RNG.
2. Migrate `Unit.level_up`.
   - `growth_random` wraps one `levelup` event per level:
     `begin_event("levelup", [unit_id, new_level])`, draw stats in
     `ClassData.STAT_KEYS` / `_GROWTH_STATS` order, then `commit_event`.
   - `growth_fixed` draws nothing but still commits the levelup event.

Tests:

- Extend `test_skill_item_handler.gd` for deterministic activation under a fixed
  seed and for the loud-fail on missing `context["rng"]`.
- Add a growth-determinism assertion (fixed seed reproduces the same stat gains).
- `test_skill_item_handler.gd` and any level-up suite must stay green.

Docs and tracking:

- If growth/skill RNG ordering is documented anywhere in `GDD_02`, update it.
  Otherwise note the migration on the `B1-PKGA` row.

### Slice 1d - Non-dice event commits and the raw-RNG guard

Files to touch:

- `scripts/core/TurnManager.gd` (and the action commit points it owns)
- `scripts/items/ItemHandler.gd`
- `scripts/tests/test_rng_usage_lint.gd` (new) or an equivalent shell guard in
  `run_tests.sh`

Implementation steps:

1. Commit non-dice event records for existing action paths where safe.
   - `wait`, `seize`, `escape`, and `item` should commit once the action is
     non-undoable.
   - Equip remains neutral and must not commit.
   - Trade, shove, pair-up, and other future actions can land with their owner
     slices if they are not currently in the action surface.
2. Add the raw-RNG guard (this must be the last sub-slice — see the ordering
   constraint above).
   - The guard must fail on `randi`, `randf`, `RandomNumberGenerator`, or
     `randomize` in gameplay folders unless the line is in `RngService.gd` or
     carries the existing exemption tag convention: an end-of-line
     `# rng-allow: <reason>` comment (already used at the four current raw
     sites as `# rng-allow: pre-M9a (RNG-1)`). Presentation/test exemptions use
     the same tag with their reason.
   - The migrated sites' stale `pre-M9a` tags must be **removed** by Slices
     1b/1c along with the raw calls; the guard should also fail on any
     surviving `pre-M9a` tag so a half-migrated site cannot hide behind it.

Tests:

- `test_rng_usage_lint.gd`
  - T5 raw gameplay RNG guard (passes only because Slices 1b/1c removed all raw
    gameplay RNG).
- T4 equip neutrality (a committed action does not advance RNG, equip commits
  nothing) — place here or in 1b, wherever the equip path is exercised.
- Existing suites that must stay green: `test_turn_manager.gd`,
  `test_map_cursor.gd`.

Docs and tracking:

- Update the `B1-PKGA` row to mark Step 1 complete once 1d lands.

## Slice 2 - `B1-PKGA` Step 2: Snapshot Contract

**Goal:** Retry restores the deterministic RNG timeline.

Files to touch:

- `scripts/autoloads/GameState.gd`
- `scripts/autoloads/RngService.gd`
- `scripts/tests/test_snapshot_coverage.gd`
- `scripts/tests/test_rng_snapshot.gd` (new)

Implementation steps:

1. Add `var _snapshot_rng: Dictionary = {}` to `GameState`.
2. In `take_map_snapshot`, store `RngService.to_save_dict()` when the autoload
   exists.
3. In `restore_map_snapshot`, call `RngService.from_save_dict(_snapshot_rng)`
   after snapshot validation and before scene reload.
4. Extend snapshot validation to check `map_seed` and `history_hash` are ints
   when the RNG snapshot exists.
5. Keep this slice narrow. Do not introduce `SaveCodec` here.

Tests:

- `test_rng_snapshot.gd` (this is the design matrix's T2 snapshot round-trip)
  - snapshot, mutate RNG history, restore, and assert `map_seed` /
    `history_hash` deep-equal the original snapshot.
  - replay one attack after restore and assert it matches the original branch.
- Extend `test_snapshot_coverage.gd` only if the test needs to assert the
  top-level RNG snapshot shape.

Docs and tracking:

- Update the `B1-PKGA` row when Step 2 lands.
- No GDD behavior update is needed beyond Slice 1 unless the snapshot schema
  differs from the ratified RNG contract.

## Slice 3 - `B1-F1`: Save Schema Manifest Lock

**Goal:** no new save state is added without a manifest row, default, serializer
owner, and fixture obligation.

Files to create or touch:

- `AGENT/Docs/plans/f1_save_schema_manifest_2026-07-06.md`
- `AGENT/Docs/plans/f1_schema_source_inventory_2026-06-28.md` if inventory
  cleanup is needed
- `AGENT/Docs/plans/project_control_plane_2026-06-29.md`
- `AGENT/Docs/INDEX.md` generated by `gen_docs_index.py`

Implementation steps:

1. Create the manifest from the source inventory row template.
2. Use the lock-design top-level sections:
   - `format_version`
   - `save_label`
   - `integrity`
   - `header`
   - `campaign`
   - `party`
   - `roster`
   - `map_runtime`
   - `suspend`
3. For every field family, assign:
   - field path,
   - owner,
   - scope,
   - lifecycle,
   - default / migration behavior,
   - serializer owner,
   - Retry behavior,
   - suspend behavior,
   - fixtures,
   - source.
4. Apply the already-ratified recommendations:
   - active conditions default to `map_runtime` / suspend state,
   - cross-map conditions require future condition data to declare persistence,
   - action/rate-limit counters reserve `map_runtime` / suspend fields,
   - `campaign.pvp` is a dormant optional block unless v1 scope changes,
   - `conversations_seen` remains an explicit no-save row until direct non-MET
     invocation becomes v1,
   - runtime facts live in `map_runtime`; resume/UI facts live in `suspend`.
5. Add explicit no-save rows for authoring data, derived state, presentation
   state, and PHB panel UI state.
6. Do not promote the manifest to JSON/YAML in this slice unless Markdown row
   ownership becomes unreviewable.

Tests:

- This is a documentation/schema lock. The implementation follow-up must create
  these fixture names, but the manifest slice can be docs-only:
  - `test_save_codec_unit_roundtrip`
  - `test_save_codec_inventory_entry_roundtrip`
  - `test_save_data_campaign_roundtrip`
  - `test_save_data_old_save_defaults`
  - `test_retry_uses_save_codec`
  - `test_suspend_map_runtime_roundtrip`
  - `test_map_runtime_resets_on_completion`
  - `test_reference_validation_unknown_ids`
  - `test_no_save_derived_fields`

Docs and tracking:

- Run `python3 AGENT/Docs/gen_docs_index.py`.
- Run `python3 AGENT/Docs/check_docs.py`.
- Update the `B1-F1` row to point at the manifest.

## Slice 4 - `B1-SAVECODEC`: Codec Foundation

**Goal:** one JSON-safe serializer serves Retry and persistent save.

Files to create or touch:

- `scripts/save/SaveCodec.gd` or `scripts/core/SaveCodec.gd`
- `scripts/autoloads/GameState.gd`
- `scripts/resources/InventoryEntry.gd`
- `scripts/resources/UnitData.gd`
- `scripts/tests/test_save_codec.gd`
- `scripts/tests/test_snapshot_coverage.gd`

Implementation steps:

1. Add pure serializer helpers:
   - vector helpers: `Vector2i` to/from JSON-safe array or dict,
   - inventory entry to/from dict,
   - unit data to/from dict for fields currently covered by Retry.
2. Replace `_snapshot_unit_data` and `_restore_unit_data` internals with the
   shared codec while keeping the public GameState methods stable.
3. Preserve lossless `InventoryEntry` round-trips:
   - entry type,
   - weapon/item ids,
   - uses remaining,
   - forge/equip modifiers.
4. Fail with structured errors for unknown ids once DataManager validation is
   available in the test context.
5. Keep file I/O out of `SaveCodec`.

Tests:

- `test_save_codec_unit_roundtrip`
- `test_save_codec_inventory_entry_roundtrip`
- `test_retry_uses_save_codec`
- Existing `test_snapshot_coverage.gd` must still prove runtime fields are not
  dropped.

Docs and tracking:

- This changes Retry serialization behavior, so update `GDD_01` and the
  `B1-SAVECODEC` control-plane row in the same implementation commit.

## Slice 5 - `B1-SAVECODEC` / `B1-CST`: SaveData Envelope

**Goal:** define the I/O-free save document seam before SaveManager writes files.

Files to create or touch:

- `scripts/save/SaveData.gd`
- `scripts/tests/test_save_data.gd`
- `AGENT/Docs/plans/f1_save_schema_manifest_2026-07-06.md`

Implementation steps:

1. Add a `SaveData` RefCounted with `to_dict` / `from_dict`.
2. Include top-level sections from the manifest:
   `format_version`, `save_label`, `integrity`, `header`, `campaign`, `party`,
   `roster`, `map_runtime`, and `suspend`.
3. Apply absent-field defaults in one place.
4. Keep integrity hash calculation stubbed or isolated if full SaveManager file
   I/O is not in this slice.
5. Add old-save default fixtures before adding more campaign fields.

Tests:

- `test_save_data_campaign_roundtrip`
- `test_save_data_old_save_defaults`
- `test_reference_validation_unknown_ids` can be skeletal until campaign content
  ids are loaded through the save path.

Docs and tracking:

- Update the F1 manifest rows with the final serializer owner names.
- Update `B1-SAVECODEC` when `SaveData` exists.

## Slice 6 - `B1-CST`: CampaignRules Consolidation Kickoff

**Goal:** prepare the hard migration to `gs.campaign_rules.*` without mixing it
with the whole campaign UI.

Files to inspect before coding:

- `scripts/autoloads/GameState.gd`
- `scripts/resources/CampaignRules.gd`
- all call sites of:
  - `permadeath_enabled`
  - `leveling_method`
  - `auto_promote_at_max_level`
  - `pair_up_enabled`
  - `max_skills`
  - `max_inventory`
  - `exp_gaining_factions`

Implementation steps:

1. Produce the call-site grep list in the implementation PR/commit notes.
2. Add or complete `CampaignRules` fields, including
   `rewind_charges_per_map` and `hit_formula` (default `two_roll`; selects the
   built-in roll resolver from Slice 1b — `[CRR-4]`).
3. Add `GameState.campaign_rules`.
4. Hard-migrate call sites to `gs.campaign_rules.<field>`.
5. Delete loose fields after tests pass.
6. Keep author-tunable CampaignRules profiles for `B3-CAMPAIGN-RULES`.

Tests:

- Extend `test_game_state.gd`.
- Add focused rule-default and rule-migration assertions.
- Existing Pair Up, level-up, inventory, skill-cap, and defeat tests must stay
  green.

Docs and tracking:

- This changes behavior ownership, so update `GDD_01`, `GDD_02` where rules are
  described, `GDD_07` if UI wording changes, and `B1-CST` /
  `B1-CAMPAIGN-RULES-SAVE` rows.

## Follow-On Slices

These remain Band 1 but should not be folded into the first implementation
commit:

- `B1-SUSPEND`: active map suspend/save, live enemy state, turn/phase cursor,
  `_unit_states`, watch set, danger mode, pair/carry state, and RNG summary.
  Carries the design matrix's T6 suspend round-trip test.
- `B1-CST` campaign graph and prep/results flow:
  `CampaignData`, SaveManager file I/O, campaign selector, prep deployment,
  victory/defeat screens, Continue/Load, autosave/manual slots, export/import.
- Turnwheel mechanic: `[CST-13]` is resolved to hooks-only in the first
  campaign/save spine pass; build the full mechanic as the immediate follow-on
  after charge persistence exists.

## Definition Of Done

For each implementation slice:

- Run focused tests for the slice.
- Run `bash run_tests.sh` unless the owner explicitly accepts a narrower pass.
- Run `python3 AGENT/Docs/check_docs.py` for documentation changes.
- Run `git diff --check`.
- If behavior changes, update the owning `GDD_01`-`GDD_08` section and the
  matching control-plane row in the same commit.
- If a mechanical rule is ratified, add the durable check in the same change.
- Add a session note and newest-first index row before stopping.

## Resolved Review Items

Implementation questions are tracked in
[`band1_implementation_questions_review_2026-06-30.md`](../../Code%20Reviews/band1_implementation_questions_review_2026-06-30.md).
The two known questions were resolved 2026-06-30. Do not reopen them unless a
later code slice proves the official path is wrong.
