# GDD_01 — Runtime Contracts

**Status:** Active runtime contract — split status per section.
**Last verified:** 2026-07-15
**Governance:** section template + status vocabulary in
`AGENT/Docs/governance/documentation_governance_2026-06-13.md`.

This companion chapter owns CampaignRules, deterministic event/RNG behavior, snapshot
and suspend boundaries, online simulation obligations, and the binding service/API
invariants shared by multiple feature chapters. Project composition remains in
[GDD_01 — Architecture](GDD_01_Architecture.md); resource shapes live in
[GDD_01 — Data Contracts](GDD_01_Data_Contracts.md).

---
## CampaignRules Contract

Status: **Split** — the live per-save `CampaignRules` object is **Implemented**
(2026-07-06, `B1-CST` kickoff) and campaign mandate/default seeding is
**Implemented** (2026-07-15); authored rule-profile registries remain
**Target design**
Last verified: 2026-07-15

### Summary
`CampaignRules` is the per-save bundle of gameplay rules chosen at New Game and carried by
the save/runtime state — distinct from global app **settings** (`SettingsManager`, on
disk) and from per-map **launch state**. `GameState.campaign_rules` is the live
source of truth; rule call sites read fields from that object, and loose `GameState`
rule fields are not retained as shims.

### Specs

**Implemented (live per-save fields on `GameState.campaign_rules`).**

| Field | Type | Meaning |
|---|---|---|
| `permadeath_enabled` | bool | Defeated allied units lost for the run (GDD_02 §Permadeath) |
| `leveling_method` | String | `growth_random` / `growth_fixed` (GDD_02 §Leveling) |
| `auto_promote_at_max_level` | bool | Auto-promote at class cap (GDD_02 §Promotion timing) |
| `pair_up_enabled` | bool | Enables Pair Up actions (GDD_05 §Pair Up) |
| `max_skills` | int (5) | Equipped-skill cap (GDD_05) |
| `max_inventory` | int (8) | Inventory slot cap, not yet enforced (GDD_04) |
| `exp_gaining_factions` | Array[String] | EXP-eligible factions; field present, combat EXP consumer remains a target |
| `hit_formula` | String | Built-in hit resolver id; `two_roll` is the shipped default |
| `rewind_charges_per_map` | int (4) | Authoritative per-map player spend meter; each successful Rewind consumes one; `0` disables and `-1` is infinite |
| `undo_activations` | int (0) | B1-LEDGER requested fine-tier retention; runtime floors this to `rewind_charges_per_map + 1` while Rewind is enabled so every charge remains spendable; `-1` = infinite |
| `undo_rounds` | int (0) | B1-LEDGER within-map ledger: retain the last N round-start entries; `-1` = infinite, `0` = none beyond round-0 |
| `save_slot_classes` | Array[Dictionary] | Manual slot pools: `{count, accepts, consumed_on_load, label}`; accepts `between_map`, `mid_map`, or `any` |
| `autosave_rules` | Array[Dictionary] | Independent automatic pools: `{rule_id, trigger, keep, label, consumed_on_load:false}` |

> Launch-routing fields (`next_map_data_path`, `next_map_roster_policy`,
> `next_map_roster_source`) travel with New Game but are **launch state, not rules**.
> Evergreen rule reference: `AGENT/Docs/guides/campaign_rules.md`.

**Save policy and autosave registry (B1-LEDGER Phase 5, Implemented 2026-07-15).**
Campaign JSON may override the two policy lists. Manual counts are enforced by the
first compatible slot class; load consumes a slot only after its full restore and
scene route succeeds. Autosave triggers are open string ids dispatched through
`AutosaveTriggerRegistry`, including shipped `battle_start`, `battle_end`,
`menu_area_exit`, and `shop_exit` plus author custom ids. `keep` rotates only rows
whose structural metadata is `origin:auto` with the same `rule_id`; manual and
other-rule rows are absent from the candidate set and guarded by an assertion.
The prior node-commit autosave is now the default `battle_end` rule. Empty rules
disable autosave. Three preset shapes (GBA 3+1, single-consumable, 30-any) are pure
data. A non-blocking builder warning reports durable `mid_map` classes unless
`rewind_charges_per_map = -1`; `check_docs.py` check 33 enforces it for shipped JSON.

**Campaign authority (Implemented 2026-07-15).** Each campaign rule may be an
editable `default` or locked `mandate`. Campaign start seeds the normalized
values and mandate ids; New Game disables mandated controls, applies player
choices only to defaults, and the rules codec persists `mandated_rules[]` in
between-map and mid-map saves.

**Mutable rule layers (Implemented 2026-07-15, `B6-PER-MAP-OVERRIDES`).**
`GameState.get_effective_campaign_rule(rule_id)` resolves, highest first,
active mid-map override → node `rule_overrides` → effective campaign default.
Mandates short-circuit both overlay layers. `apply_rule_flip` accepts the fixed
`revert_scope` vocabulary `end_of_map|permanent`: the first writes only the
active map layer, while the second appends an ordered `{rule_id,value,reason,source}`
patch to `MutableCampaignState`. Existing typed `CampaignRules` properties mirror
effective values, while unknown fixture/future ids use the same dictionary
resolver without an engine switch. Map launch seeds the node layer; commit or
campaign cancel clears temporary layers.

The same mutable store owns open `carry_forward_facts` and
`imported_record_ref`, preventing CampaignStatusRecord from creating a parallel
persistence path. Permanent patches and facts persist in campaign saves;
per-map/active overrides additionally persist in suspend and every ledger
checkpoint, so Retry/Rewind abandons rule mutations from the discarded future.
Old saves default to an empty store.

Every successful `apply_rule_flip` emits `campaign_rule_flipped`; GameMap shows a
bounded player-facing notification containing rule, value, reason, and temporary
versus permanent scope. Prep renders the effective rules and mandate locks as a
read-only summary, so the player can inspect the run contract between maps.

**Target design (author profiles and later consumers).**
- Treat shipped rule numbers and relationships as selected rule-profile values, not
  engine constants. Developer-provided presets support the project/corpus targets;
  campaigns may select or override exposed profiles through validated data.
- `CombatResolver` still needs to consume `exp_gaining_factions` for EXP gating.
- **Follow-up threshold override:** the Battle-Speed follow-up threshold is read from
  CampaignRules/profile data (GDD_02 §Combat Resolution).
- **Broken-weapon degraded mode (OPEN-5):** likely a `CampaignRules` toggle (GDD_04).

### Known gaps
- The authored rule-profile registry and EXP faction gating remain later consumers.

### Anchors
- Code: `scripts/autoloads/GameState.gd`, `scripts/resources/CampaignRules.gd`,
  `scripts/save/SaveData.gd`
- Tests: `scripts/tests/test_game_state.gd`, `scripts/tests/test_save_data.gd`,
  Pair Up / New Game / Unit progression suites
- Guide: `AGENT/Docs/guides/campaign_rules.md`
- Decisions: OPEN-4, OPEN-5, RNG-3, D-D
- Roadmap: GDD_10 `B1-CST`; EXP gating owner: GDD_02

---

## Determinism, Snapshot & Online Contract

Status: **Split** — RNG-1 dice sourcing + event commits, the RNG-2 Retry
snapshot, the I/O-free `SaveData` envelope, the active-map suspend
serializer/scene-restore foundation, and the unified `SaveManager` slot store are
**Implemented** (2026-07-06, B1-PKGA Steps 1-2, B1-SAVECODEC Slices 4-5,
B1-SUSPEND Slice 1, SaveManager disk seam, Map Menu Suspend & Quit, Main Menu
Continue/delete lifecycle); the §8.1 snapshot generalization landed across
2026-07-15 (B1-LEDGER Phase 1: suspend saves and the within-map ledger share one
suspend-complete board serializer; Phase 2: the two-tier decaying ledger, the
`undo_activations`/`undo_rounds` budgets, and Retry re-expressed as
`restore_history(0)` — the party-only snapshot path is scrapped);
Phase 3 live checkpoint pushes and player-spendable deterministic rewind are
**Implemented** (2026-07-15); object/AI future fields remain **Target design**
Last verified: 2026-07-15

### Summary
All gameplay randomness flows through a hash-chained, context-seeded `RngService` so
that rewind, suspend save, and Retry reproduce identical outcomes, and online play can
be host-authoritative. This section is the **binding contract**; the implementation
plan (code, integration sweep, tests, build order) is
`AGENT/Docs/design/rng_determinism_design_2026-06-11.md`.

### Specs (binding rules)

- **RNG-1 — Hash-chained context-seeded dice.** Every gameplay die derives from
  `seed = mix(map_seed, history_hash, event_record)`. `history_hash` advances on every
  **committed, non-undoable** unit action; equip, undone moves, menu/cursor/preview
  **never** advance it. Each dice-bearing event draws from its own freshly seeded RNG
  in the canonical roll order; level-ups are chained per `(unit_id, new_level)`.
- **RNG-2 — RNG state lives in the snapshot.** `{map_seed, history_hash}` serializes
  into every map snapshot (Retry, rewind checkpoints, suspend save); replaying the
  identical committed-action sequence reproduces outcomes byte-for-byte.
  `RngService` keeps those values as 64-bit integers in memory; persistent
  `SaveData` documents write them as decimal strings so Godot JSON cannot round
  large hashes.
- **RNG-3 — Accepted exploits, priced by rewind charges.** Probing and Wait-to-reroll
  are knowingly permitted, bounded by a `CampaignRules` rewind-charge pool (default 3–5;
  0 = ironman). No further anti-manipulation machinery.
- **RNG-4 — Online is host-authoritative (M15B, post-1.0).** The host simulates and
  broadcasts result payloads through the `resolve_combat()` / `apply_combat_result()` +
  snapshot seams; determinism guarantees are **engine-local**. The custom mixer is still
  mandatory (protects suspend saves across Godot upgrades).
- **Canonical roll order (binding).** Per `attack` event: per strike, the **selected
  hit resolver's fixed `rn_count`** of 0–99 hit RNs (CRR-1..8) — default `two_roll` =
  RULE-001 (two RNs, hit when `floor((r1+r2)/2) < To-Hit`); `single_roll` is the
  second built-in (`rns[0] < To-Hit`, one RN); selection lives in
  `CampaignRules.hit_formula` — then a **crit RN only on a hit**, then
  skill-activation rolls at their trigger slots; then `levelup` events (one growth
  roll per stat in `ClassData.STAT_KEYS` order). Reordering — including changing a
  resolver's draw count — is a **save/replay-breaking** change.
- **Frame-atomicity (already true).** Combat resolves within one frame
  (`resolve_combat()` builds + rolls; `apply_combat_result()` commits); snapshots exist
  only **between** committed actions, so there is no mid-exchange state to serialize.
- **Snapshot contract.** Generalize `GameState.take_map_snapshot()` into one
  `Dictionary` (`schema_version`, `map_id`, `campaign_rules`, `rng`, `turn`, `party`,
  `pair_up`, `units[]` including non-`@export` runtime fields). Retry = restore
  checkpoint 0; a mid-map slot persists this dict plus the whole ledger; rewind = a ring of
  these. **The battle-resume slot persists until the map resolves (OPEN-13)**, then deletes (no
  delete-on-load — RNG-2 already blocks reload-scumming). The Retry-facing
  unit/inventory snapshot routes through `SaveCodec` as JSON-safe dictionaries,
  and the top-level `SaveData` envelope now defines the I/O-free document seam
  with locked-section defaults (2026-07-06, `B1-SAVECODEC` Slices 4-5).
  **B1-LEDGER Phase 1 (2026-07-15) began the generalization:**
  `GameState._capture_map_runtime_entry()` is the one suspend-complete board
  serializer — all factions' unit runtime dicts, turn/scheduler state, PairUp
  carry, RNG timeline, and the cursor/threat-view block — and BOTH
  `capture_suspend_save()` (composing it with the campaign/party/roster layers)
  and the within-map history (`push_history` / `peek_history`) read it, so a
  suspend save and a ledger entry serialize the live board identically.
  `take_map_snapshot()` now seeds the round-0 ledger entry (checkpoint 0). Measured
  size of one entry: ~2 KB/unit (a 14-unit board ≈ 28 KB binary / 16 KB JSON),
  so the ledger tiers are not memory-bound at realistic depths.
  **B1-LEDGER Phase 2 (2026-07-15) landed the ledger + Retry-on-ledger:** the
  within-map history is now a decaying `MapLedger` (`scripts/save/MapLedger.gd`) —
  a single reason-tagged list whose `prune()` keeps the UNION of the last
  `undo_activations` per-activation entries and the last `undo_rounds` round-start
  entries, with the round-0 boundary always retained (tiers are data, not a mode
  `match`). Each entry also folds the **party economy** (gold/items/roster) so a
  Retry and mid-map rewind roll party rewards back with the board.
  Retry is now `GameState.restore_history(0)` (`GameOverScreen` calls it); the
  separate `restore_map_snapshot`/`_map_start_snapshot` party-only path is deleted.
  The `undo_activations`/`undo_rounds` retention budgets are new `CampaignRules`
  fields (see §CampaignRules Contract).
  **B1-LEDGER Phase 3 (2026-07-15) made the history live and spendable:** every
  completed activation queues one coalesced post-action checkpoint; refreshed
  round starts add coarse checkpoints. `rewind_charges_per_map` is the sole
  spend meter and `undo_activations`/`undo_rounds` remain retention preferences.
  While charges are positive, fine retention is floored to `charges-per-map + 1`
  so sequential spends cannot prune their own reachable boundaries. Rewind stages
  the target as a durable suspend payload, validates it, restores its full board,
  party economy, PairUp, cursor, turn, and RNG state through a scene reload, spends
  one charge, and only then truncates the abandoned future. Identical replay
  reproduces the same RNG chain; choosing a different committed action diverges.
- **Active-map suspend foundation.** `GameState.capture_suspend_save()` now captures
  a `SaveData` document between committed actions while the cursor is in free,
  unsuppressed local control: map id/path, live unit runtime dictionaries for all
  factions, turn/scheduler cursor, per-unit activation states, objective bookkeeping,
  PairUpRegistry, RNG timeline, cursor tile, and versioned per-controlling-faction
  MRD threat views (`watch_set` + `danger_mode`). Legacy single-view suspend fields
  load as the saved controlling faction's view.
  `GameState.configure_suspend_resume()` stages that document; `GameMap` then spawns
  from `map_runtime.units` instead of authored placements and restores
  `TurnManager`, PairUpRegistry, `RngService`, and `MapCursor`. Phase 4 replaced
  the dedicated suspend file/API with the same named-slot store used between maps.
  Map Menu `Suspend & Quit` writes the reserved `resume_battle` slot from the
  free/local-control boundary before returning to `Boot.tscn`; Main Menu Continue
  and Load both load it through the same discriminator-driven path, staging it through
  `GameState.configure_suspend_resume()`, and launches `GameMap`. The suspend
  slot is deleted when a map result is requested, not when it is loaded. The slot
  persists `ledger[]`, so pre-suspend Rewind boundaries survive process restart;
  its campaign envelope also restores the active graph position. Every slot carries
  `origin` and automatic slots additionally carry `rule_id`.
  During an AI-controlled faction, the Map Menu remains available in a restricted
  mode: End Turn and Rewind are disabled, and Suspend latches one pending intent.
  The acting AI unit finishes first; `TurnManager` synchronously seals its ledger
  entry, then writes the slot before another unit activates. The turn snapshot
  records `controller_boundary = "between_ai_activations"`. Continue re-enters the
  already-started AI faction, skips serialized `DONE` units, and does not replay
  phase-start healing, modifier ticks, or skills. A failed slot write clears the
  intent and leaves the AI phase running; a committed map outcome cancels it.
- **Portable save transfer.** Every slot write and filesystem export stamps a
  canonical SHA-256 over the full payload (with blank stamp fields) and a second
  SHA-256 over format version, package/campaign identity, progression, campaign
  rules, and optional authored dotted `protected_fields`. Load Game exports one
  pretty-printed JSON document. Import sniffs ZIP/JSON leading bytes, validates
  the SaveData schema, and treats hash mismatch as advisory: changed content
  requires explicit player acknowledgement, protected changes add a stronger
  warning, and only parse/schema/version failures hard-reject. Save JSON includes
  an inline `_warning` explaining that editing can produce invalid state.
- **Persistence ban.** Engine `hash()` / `String.hash()` are permanently banned in this
  subsystem; the SplitMix64-style mixer and string-fold are frozen (changing them is
  save-breaking).

### Known gaps
- Package A Steps 1-2 are complete (2026-07-06): dice sourcing, non-dice event
  commits (wait/seize/escape/item/staff/pair actions, player and AI), the
  raw-RNG lint (T5), equip neutrality (T4), and the Retry snapshot carrying
  `{map_seed, history_hash}` (T2). `B1-SAVECODEC` Slices 4-5 also landed
  (2026-07-06): Retry unit/inventory snapshots now use JSON-safe `SaveCodec`
  dictionaries, and `SaveData` owns the top-level section defaults plus old-save
  default fixtures. `B1-CST` kickoff also moved live rule ownership into
  `GameState.campaign_rules` and expanded save-rule defaults. `B1-SUSPEND` Slice 1
  now restores active-map live enemies, scheduler state, PairUp, RNG, and MRD cursor
  state from `SaveData.map_runtime` / `SaveData.suspend`. B1-LEDGER Phases 3-4
  added live Rewind and the unified slot namespace: Map Menu writes a normal
  `resume_battle` slot with the whole ledger, Continue/Load discriminate by
  `map_runtime.map_path`, and result-time cleanup deletes that slot. Remaining:
  future object/AI runtime fields when those systems exist.

### Anchors
- Code: `scripts/autoloads/RngService.gd`; `scripts/autoloads/SaveManager.gd`;
  `scripts/save/SaveCodec.gd`; `scripts/save/SaveData.gd`;
  `scripts/save/SaveIntegrity.gd`; `scripts/core/GameMap.gd`;
  `CombatResolver.gd`, `TurnManager.gd`
  (`get_action_start_tile`, `commit_action_event`), `SkillHandler.gd`
  (activation from the event RNG), `Unit.gd` (`level_up` chained `levelup`
  events), `MapCursor.gd` / `MapCursorTargeting.gd` / `EnemyAI.gd` (non-dice
  commit points and suspend cursor state)
- Tests: `scripts/tests/test_rng_service.gd`,
  `scripts/tests/test_rng_combat_determinism.gd` (T1/T3/T7),
  `scripts/tests/test_main_menu.gd` (Continue load/failure UX),
  `scripts/tests/test_game_over_sequencing.gd` (result-time suspend cleanup),
  `scripts/tests/test_save_manager.gd` (suspend disk slot),
  `scripts/tests/test_rng_usage_lint.gd` (T5), `test_map_cursor.gd` (T4 +
  wait-commit), `scripts/tests/test_rng_snapshot.gd` (T2),
  `scripts/tests/test_save_codec.gd`; `scripts/tests/test_save_data.gd`;
  `scripts/tests/test_suspend_map_runtime.gd` (T6 scene restore)
- Decisions: RNG-1…4, RULE-001, CRR-1..8, OPEN-13
- Implementation plan: `AGENT/Docs/design/rng_determinism_design_2026-06-11.md`
- Combat-facing rules: GDD_02 → Combat Resolution & Hit RNG

---

## Campaign-Pack Storage Contract

Status: **Implemented** — archive validation/storage, deterministic export,
installed-pack discovery/activation, exact save identity, and the player-facing
import/export/selection flow shipped 2026-07-15 (`B6-CAMPAIGN-SHARING`)
Last verified: 2026-07-15

### Summary

Campaign packages are inert, data-only archives that are fully validated before
installation or activation; portable saves use separate bounded import policy.

### Specs

Campaign packs contain indexed authored JSON and approved pack-scoped media;
they never contain executable behavior or save-shaped state. Import is a
transactional storage operation owned by the engine: `CampaignArchivePreflight`
admits one safe archive namespace in memory, then `CampaignPackInstaller`
extracts only admitted paths into a unique service-owned staging directory,
revalidates the staged manifest, Tier-2 catalogue, concrete schemas,
cross-references, and optional media, and atomically renames the validated tree
under `installed/{pack_id}/{version}`. Existing identities are rejected rather
than overwritten or merged. Every failure removes staging and leaves installed
bytes, active content, selector state, settings, and saves unchanged.

Installation is deliberately inert. `CampaignLibraryScreen` refreshes discovery
after a successful import, but neither preflight nor install selects, activates,
or launches content. Selection remains an explicit New Game action.

`CampaignPackExporter` derives a lexical archive entry list only from the
validated manifest, canonical Tier-2 catalogue, and approved `assets/` media.
It cannot include campaign slots, suspend state, `.godot` caches, or unrelated
files because those paths never enter the admitted set. The completed archive
must pass the same hostile preflight used by import before it is returned.
Preflight rejects an archive whose outer file length exceeds the compressed
budget before allocating its bytes. Export replacement stages the new artifact
beside the destination and restores the previous artifact if promotion fails.

`CampaignPackRegistry` scans only `installed/{id}/{version}` directories,
revalidates each manifest/catalogue and path identity, and caches deterministic
read-only summaries containing pack provenance and authored campaign labels.
Malformed candidates remain excluded with diagnostics. Refresh reconstructs the
cache from disk so deleted or repaired packs cannot leave stale selector rows.

New Game's **Manage Campaigns** overlay uses filesystem FileDialogs for ZIP
import and export. Import runs hostile preflight before the transactional
installer and reports validation errors or optional-media repair counts without
leaving the screen. Export offers validated installed package identities and
uses the deterministic exporter, including its mandatory output re-preflight.
All player-selected artifact budgets are owned by
`scripts/resources/ImportBudgets.gd`. Campaign archive entry-count, per-entry,
compressed-total, and uncompressed-total caps remain separate from portable-save
budgets because package media dominates archive size. `CampaignArchivePreflight`
rejects the outer archive before buffering and accepts caller-supplied limits for
tests and build tools.

Portable JSON saves use the configuration owner's desktop warning and maximum.
Crossing the warning produces an acknowledgement warning but still runs integrity,
schema, and reference validation; crossing the maximum hard-rejects before the file
is buffered. Platform-specific values, including a future stricter Web ceiling,
must be selected by `ImportBudgets` rather than copied into UI/parser code. Change
budgets only there, keep campaign and save budgets independent, rerun
`test_save_import_budgets.gd`, and record new representative evidence before
raising or lowering a platform limit.

Tier-2 activation adapts validated JSON into existing runtime Resource types in
memory, then atomically replaces the `DataManager` campaign/class/map/roster
registries. A failed adapter leaves the previously active source untouched.
Between-map and suspend saves carry exact `{package_id, package_version}` and
reactivate only the matching service-owned installed path before resolving any
campaign, map, roster, or class id. An empty identity selects shipped content;
partial identity is invalid, and save files never supply filesystem paths.

### Known gaps

- Public campaign-builder editing/repair and installed-content resynchronization
  remain deferred under their separate control-plane tracks.
- A stricter Web portable-save budget awaits browser measurement evidence.

### Anchors

Code: `scripts/resources/ImportBudgets.gd`,
`scripts/resources/CampaignArchivePreflight.gd`,
`scripts/resources/CampaignPackInstaller.gd`,
`scripts/resources/CampaignPackExporter.gd`,
`scripts/resources/CampaignPackRegistry.gd`,
`scripts/resources/CampaignTier2RuntimeAdapter.gd`,
`scripts/resources/Tier2Catalogue.gd`, `scripts/assets/AssetResolver.gd`; tests:
`test_campaign_archive_preflight.gd`, `test_save_import_budgets.gd`,
`test_campaign_pack_installer.gd`,
`test_campaign_pack_exporter.gd`, `test_campaign_pack_registry.gd`.
Runtime/save tests: `test_campaign_tier2_runtime_adapter.gd`,
`test_campaign_pack_save_identity.gd`. Player-surface test:
`test_campaign_library_screen.gd`.

---

## Shared Runtime Service Boundaries

Status: **Implemented**, with registry expansion and later feature consumers tracked
by their owning rows
Last verified: 2026-07-13

### Summary

Shared runtime services own cross-system mutations and projections so feature
callers cannot partially reproduce transaction or validation rules.

### Specs

Exact method signatures are code-owned and should be read from the scripts below.
The binding cross-system invariants are:

- `GridManager` owns geometry, terrain queries, movement/range calculation, and
  overlays. Occupancy mutations route through `OccupancyService`; feature rules for
  terrain and movement live in `GDD_02` and `GDD_06`.
- `CombatResolver` separates forecast/build from result application. Forecasts do
  not commit RNG or lasting state, and combat death routes through
  `DeathLifecycle`. Shared audience-specific forecast output routes through
  `ProjectionService` (`B2-PROJECTION`).
- `TurnManager` owns action-start tiles, scheduler/phase state, and committed
  non-dice action events. Its serializable runtime state participates in suspend
  restore and deterministic replay.
- `Unit` is the runtime adapter around `UnitData`. Combat stat reads use the
  effective-stat path; inventory/progression mutation must preserve snapshot
  coverage.
- `MapCursor` owns tactical interaction state, but its input, danger-zone, and
  modal behavior are specified by `GDD_07`. Cursor state required for suspend is
  part of the snapshot contract above.
- Registry-backed mutation, resource spending, placement, death, and forecasting
  must enter through `ActionEffectRunner`, `ResourceLedger`,
  `OccupancyService`, `DeathLifecycle`, and `ProjectionService` respectively;
  callers must not recreate their validation or partial-mutation rules.

### Known gaps

- Broader registry consumers remain owned by their control-plane tracks; this
  section fixes service boundaries, not their delivery schedule.

### Anchors

- `scripts/core/GridManager.gd`
- `scripts/core/CombatResolver.gd`
- `scripts/core/TurnManager.gd`
- `scripts/units/Unit.gd`
- `scripts/core/MapCursor.gd`
- `scripts/autoloads/ActionEffectRunner.gd`
- `scripts/autoloads/ResourceLedger.gd`
- `scripts/autoloads/OccupancyService.gd`
- `scripts/autoloads/DeathLifecycle.gd`
- `scripts/autoloads/ProjectionService.gd`

Tests are the executable signature and behavior guard. Start with the matching
`scripts/tests/test_*.gd` suite and `scripts/tests/test_snapshot_coverage.gd`
when a mutable field changes.

---
