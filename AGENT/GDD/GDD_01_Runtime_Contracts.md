---
Role: topic
Topic ID: GDD-01-RUNTIME-CONTRACTS
Last verified: 2026-09-01
---

# GDD_01 — Runtime Contracts

**Status:** Active runtime contract — split status per section.
**Last verified:** 2026-09-01
**Governance:** section template + status vocabulary in
`AGENT/Docs/governance/documentation_governance_2026-06-13.md`.

This companion chapter owns CampaignRules, deterministic event/RNG behavior, snapshot
and suspend boundaries, online simulation obligations, the shared effect execution
protocol, and the binding service/API invariants shared by multiple feature chapters.
Project composition remains in
[GDD_01 — Architecture](GDD_01_Architecture.md); resource shapes live in
[GDD_01 — Data Contracts](GDD_01_Data_Contracts.md).

---
## CampaignRules Contract

Status: **Split** — the live per-save `CampaignRules` object is **Implemented**
(2026-07-06, `B1-CST` kickoff) and campaign mandate/default seeding is
**Implemented** (2026-07-15); authored rule-profile registries remain
**Target design**
Last verified: 2026-07-22

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
| `rewind_cost_mode` | String (`per_activation`) | `per_activation` prices a selected target by activations crossed; `full_history` prices any retained target at one charge |
| `undo_activations` | int (0) | B1-LEDGER requested fine-tier retention; runtime floors this to `rewind_charges_per_map + 1` while Rewind is enabled so every charge remains spendable; `-1` = infinite |
| `undo_rounds` | int (0) | B1-LEDGER within-map ledger: retain the last N round-start entries; `-1` = infinite, `0` = none beyond round-0 |
| `battle_result_actions` | Dictionary | Open per-outcome action visibility policy. Shipped consumers read `victory.{continue,retry,save,quit}` and `defeat.{retry,reload,load,rewind,quit}`; missing/unknown action ids default visible for forward and old-save compatibility. Runtime availability remains an additional gate (for example Defeat Rewind hides with no usable charge/history). |
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

**Post-battle action policy (Implemented 2026-07-22).** Campaign data may hide
individual victory/defeat actions through `battle_result_actions` without an
engine campaign-id switch. Visibility never grants an unavailable operation:
Rewind also requires retained history and charges, and Save requires campaign
state plus manual-slot capacity. The policy round-trips in campaign saves.

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
Last verified: 2026-07-28

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
  completed activation queues one coalesced post-action checkpoint tagged with
  unit identity and start/end coordinates; refreshed
  round starts add coarse checkpoints. `rewind_charges_per_map` is the sole
  spend meter and `undo_activations`/`undo_rounds` remain retention preferences.
  In `per_activation` mode, fine retention is floored to `charges-per-map + 1`
  while charges are positive so sequential spends cannot prune their own reachable
  boundaries. `full_history` mode keeps every activation regardless of that cap.
  Rewind stages the target and a clone-truncated ledger as a durable suspend payload,
  validates it, restores its full board,
  party economy, PairUp, cursor, turn, and RNG state through a scene reload, spends
  the selector's authored cost, and only then truncates the abandoned future.
  The selector targets the checkpoint before the chosen activation, so a player
  phase-start selection can genuinely undo the final enemy action. In
  `per_activation` mode cost equals activations crossed; `full_history` makes any
  retained activation cost one charge. Identical replay
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
  Map initialization reinstalls the staged document after its ordinary map-state
  reset, preserving the complete ledger and remaining rewind charges. AI activation
  history entries use the same explicit controller boundary, so a Rewind into one
  resumes the scheduler rather than waiting for player input during AI control.
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
Last verified: 2026-08-09

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
Explicit ZIP directory metadata at or below that namespace is accepted; only
files outside the single package root are rejected.

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
Registered `map_registry` documents are read through their validated `entries`
envelope when synthetic single-map campaigns are summarized; the legacy bare-array
form remains supported only for compatibility content. Malformed candidates remain
excluded with diagnostics. Refresh reconstructs the cache from disk so deleted or
repaired packs cannot leave stale selector rows. The exported-fixture lifecycle test
proves export, preflight, install, discovery, explicit selection, and playable launch
as one player-facing path.

**Full backup and restore Implemented 2026-08-27** (pack-associated save plan, Slice 3).
A backup is one ZIP holding two independently validated halves: `backup.json`
(the envelope), `packs/{id}-{version}.zip` clean pack archives produced by the
ordinary exporter, and a `user_state/` half with `manifest.json`, verbatim save
documents and campaign status records. `BackupEnvelope` owns the shape and is
pure: component paths are derived from identity rather than read from the
document, digests are `sha256` with both the algorithm and the 64-hex length
enforced, and one discriminator classifies a portable save, an installable pack
and a backup so no entry point can process one as another. `CampaignBackupService`
owns bytes. Pack bytes come only from `CampaignPackExporter`, which is what makes
"no user state inside an installable pack" structural rather than a second rule;
saves are copied byte for byte, because those are the bytes save resolution must
later agree with.

Inspection is inert and commits nothing: it enforces the outer size budget before
buffering, reuses the archive preflight's containment and entry parsing, rejects
duplicate and case-folded paths, verifies every declared digest against the stored
bytes, and refuses any file the envelope does not account for. Restore is two
phases. Phase one validates each selected component through the validator that
owns it — packs through preflight, saves through `SaveManager.inspect_portable_save`,
status records through `CampaignStatusRecord` — writing only inside a staging
directory. Phase two snapshots the save index, the target slots and the target
status files, then installs and writes; any failure rolls all of it back,
including a package installed moments earlier. The source archive is never
modified. A package already installed at the same id and version is skipped rather
than refused; an occupied save slot is refused until the caller explicitly
replaces it; and `SaveManager.restore_slot` preserves the recorded origin and
`rule_id` and does not apply the manual-slot budget, which bounds saves a player
creates during play rather than saves being put back.

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
Save restoration first performs structure/integrity checks without resolving
content references, selects the exact saved `{package_id, package_version}` from
the service-owned installed registry (or shipped content), validates references
against that catalogue, and then restores the previously active catalogue. Only
after that preflight succeeds may permanent package/campaign mutation begin.
Crossing the warning produces an acknowledgement warning but still runs integrity,
schema, and reference validation; crossing the maximum hard-rejects before the file
is buffered. Platform-specific values, including a future stricter Web ceiling,
must be selected by `ImportBudgets` rather than copied into UI/parser code. Change
budgets only there, keep campaign and save budgets independent, rerun
`test_save_import_budgets.gd`, and record new representative evidence before
raising or lowering a platform limit.

Tier-2 activation adapts validated JSON into existing runtime Resource types in
memory, then atomically replaces the `DataManager` campaign/class/map/roster
registries. Engine-owned registry entries remain active alongside that package
session, including the map-start occupancy policies; package activation does not
erase them. A failed adapter or engine-baseline candidate leaves the previously
active source untouched.
Between-map and suspend saves carry exact `{package_id, package_version}` and
reactivate only the matching service-owned installed path before resolving any
campaign, map, roster, or class id. An empty identity selects shipped content;
partial identity is invalid, and save files never supply filesystem paths.

The inactive state is also a supported runtime state (**Implemented
2026-07-30**): gameplay catalogues and package-authored registry entries may both
be empty while engine-owned primitives and policies remain available to the main
shell, settings, input, and package-management services. Explicit deactivation
returns to that state.

**Quit-to-shell deactivates the content package (`[CSA-28]` clause (f)), through one
path.** The skin follows `active_package_identity`, so leaving a run must leave the
identity as well. Three screens used to open `Boot.tscn` by hand with slightly different
pre-work and none of them deactivated, so **the main menu was reached with the last-played
pack still loaded** — ratified since 2026-07-31 but unimplemented, and unnoticed because
nothing depended on it. `[CEUI-S13]` is what began to: the campaign editor is offered
**only on the main menu**, where no pack is active, so the editor never ends a run and
shows no confirmation for doing so — the requirement became a **precondition on where the
entry point lives** rather than a transition the editor performs. Activating an editor
working copy over a still-active player pack is the provenance failure `[CEUI-S9]` call 1
exists to prevent: the editor imports a **copy**, editing never touches the library
original, the working copy activates under its **own distinct identity** and must never
masquerade as the installed `{package_id, package_version}`, and the only route back is an
explicit, validated, author-confirmed export. `CampaignManager.quit_to_shell()` is that
single path. It deliberately does **not** end the campaign: two of its three callers
already do and the third (quit from the in-map menu) never has, so campaign progress and
content activation stay separate concerns and this path owns only the second.

Project `data/`
loads only through the temporary, setting-gated compatibility activation used
during base-pack extraction; it is no longer an unconditional autoload side
effect.

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

### Gameplay modal and reward notification contracts

Status: **Implemented** (2026-07-16)
Last verified: 2026-07-16

- Full-screen gameplay overlays acquire/release the owner-counted EventBus gameplay
  modal lock. `MapCursor` consults it in event callbacks and held-input polling.
- A successful victory ledger commit emits a copied reward receipt containing
  `gold_earned`, resulting `total_gold`, and `items_awarded`; failure emits none.

---

## Shared Effect Execution Contract

Status: **Target design** — designed by Session 4 of the cross-system architecture
review; no code implements it yet
Last verified: 2026-08-31

### Summary

Every authored state change — item use, weapon/attack effects, triggered skills,
status conditions, terrain and crossing hazards, traps, map-object interactions,
story/dialogue actions, objective rewards, cadence actions and shop purchases —
executes through one typed protocol. The protocol owns validation, requirement
gating, isolated preview, ordered commit, RNG accounting, touched-field evidence,
presentation events and rollback. It does **not** own game state: each write is
still performed against the domain authority that owns that state.

Three roles, and nothing may hold two of them for the same operation:

- a **source adapter** owns *when and why* — trigger timing, activation policy,
  authored-source rules, and its own private bookkeeping (durability, use counters,
  duration, stock);
- a **domain authority** owns *a class of state* — `ResourceLedger` for wallets,
  inventory/convoy for custody, progression for class and EXP, `CampaignVars` for
  authored variables, the condition adapter for duration, combat formulas for damage;
- a **coordinator** owns *atomicity across authorities* and nothing else.

The protocol replaces three execution models the review measured: item can-apply /
preview / commit callables returning ad-hoc dictionaries, skill handlers that mutate
units and shared context dictionaries and return a boolean, and combat forecasting by
live mutation plus hand-maintained snapshot restoration. The collision matrix and the
per-path dispositions that produced this contract are in
[GDD_01 — Architecture](GDD_01_Architecture.md) under *Cross-System Review and
Documentation Consolidation*.

### Specs

Specs are binding and citable as `EFX-n`. Exact method signatures stay code-owned;
these are the invariants an implementation may not choose differently.

#### Envelopes — reuse, never duplicate

`EFX-1 — The existing envelopes are the contract's envelopes.` No parallel request,
context, result, preview or transaction type may be introduced. Each shipped type
keeps its identity and gains only additive fields with safe defaults:

| Existing type | Role in the contract | Additive fields | Why not a new type |
|---|---|---|---|
| `ActionRequest` | one step of a composition | `step_id`, `target_ref`, `requirements`, `required`, `on_failure` | already the typed per-primitive envelope; `params` deep-duplication is the immutability guarantee the contract needs |
| `ActionContext` | the execution envelope for one transaction | `phase`, `transaction`, `diagnostics`, `knowledge_policy` | already carries `subjects`, `target_refs`, `source_ref`, `state_view`, `resource_sink`, `rng_stream`, `safe_point`, `dry_run` — the whole seam was reserved for this |
| `ActionResult` | both the per-step result and the aggregate | `step_id`, `steps`, `deltas`, `halted_at`, `uncertain` | already carries `affected_ids`, `events_emitted`, `resources_spent`, `rng_draws`, `save_fields_touched` |
| `ProjectionResult` / `ProjectionContext` | the preview envelope | none | `state_deltas`, `projected_events`, `rng_summary`, `knowledge_flags` and the audience split already exist; effect preview becomes a second `kind` alongside `combat` |
| `ResourceTransaction` | the payment participant's prepared record | none | already quote/reserve/commit/refund with recorded deltas |
| `CrossingOutcome` | the movement scheduler's own outcome | none | stays movement evidence; its effect callable is what the contract removes, not its shape |
| `RequirementSystem.evaluate()` result | the requirement gate result | none | `{met, reasons, trace, errors}` with per-reason `code`/`predicate_path`/`gate`/`text_key`/`params` is already the structured unmet-reason shape |
| `RegistryEntry` | the primitive declaration | none | `primitive_handler`, `params_schema`, `subjects`, `composition`, `projection_support`, `save_fields` are already the declaration this contract validates against |

`EFX-2 — Compositions are authored data, not code.` A composition is a registry
entry in the family `effect_compositions`:

```text
{ composition_id, steps: [ Step, ... ], on_failure: "abort" }
Step = { step_id, primitive_id, params, target, requirements?,
         required: true, on_failure: "abort" }
```

`step_id` is unique within its composition. Order is explicit and is execution order.
Adding an authored effect for any source must be a composition plus already-registered
primitives — never a new engine `match`.

`EFX-3 — Targets are typed references, never live objects.` Authored data carries
`target = {kind, key}` with `kind` in `subject | self | source | tile | group |
party | campaign`. Resolution happens once, before any step prepares, against
`ActionContext.subjects` / `target_refs`. An unresolvable reference fails the whole
transaction with `unresolved_target` and names the step and the reference. A handler
never resolves its own target.

#### Phases and isolation

`EFX-4 — Four phases: validate, prepare, commit, rollback.` `ActionContext.phase`
names the phase. `validate` is schema and vocabulary only. `prepare` runs handler
logic and produces a journal. `commit` applies the journal. `rollback` reverses
committed participants. `dry_run` keeps its present meaning and is now precise:
*prepare, then discard* — it is the preview path, not a separate code path.

`EFX-5 — Prepare never touches live state.` Handlers read and write through
`ActionContext.state_view`, a read-through overlay: a read returns the overlay value
if the transaction has already written that field, otherwise the live authority's
value; a write records a journal entry and never reaches the authority. Mutate-and-restore
is prohibited. This is the rule that removes the combat forecast's dependence on a
hand-maintained restore list, and the reason preview cannot corrupt a save.

`EFX-6 — The journal is the unit of evidence.` One entry per write:

```text
{ step_id, authority_id, save_field, ref, before, after }
```

`before` is what the authority held when the step read it, and is what makes both
revalidation (EFX-16) and rollback possible.

`EFX-7 — Handlers run exactly once per transaction.` A successful prepare yields a
journal that `commit` applies without re-entering handler code. Anything a handler
computes and does not put in the journal or the step result does not exist.

#### Requirements

`EFX-8 — One predicate language.` Requirement gates evaluate through
`RequirementSystem.evaluate()` and consume its result unchanged. The contract adds no
second predicate vocabulary and no `RequirementResult` class. An unmet required gate
fails the transaction with `requirement_unmet`, carrying the `reasons` array verbatim
so `gate` (`visible_disabled` / `hidden_until_met`) and `text_key` survive to the UI.
Objective conditions become compositions of these same predicates; a requirement stays
non-mutating, and a status condition stays an effect.

`EFX-9 — Gates see earlier prepared steps.` A step's requirements evaluate against the
state view at the moment that step is reached, so step 3 observes what steps 1–2
prepared. Without this, ordering in an authored composition would be decorative.

#### Preview and uncertainty

`EFX-10 — Preview is prepare, projected.` Effect preview is a `ProjectionContext` of
kind `effect`; the result is a `ProjectionResult` whose `state_deltas` are the journal
entries, `projected_events` the steps' `events_emitted`, and `rng_summary.committed_draws`
always `0`. Preview calls neither `RngService.begin_event()` nor `commit_event()` and
never advances `history_hash` (RNG-1, RNG-2). `ProjectionService`'s existing guard —
invalidating a projection that changed guarded save state — applies to effect
projections too and is the executable form of EFX-5.

`EFX-11 — Uncertainty is reported, never omitted.` A step whose outcome depends on a
die contributes to `ProjectionResult.rng_summary.uncertain`:

```text
{ step_id, primitive_id, draws, outcomes: [ { label, probability, deltas } ] }
```

Knowledge policy (`ProjectionContext.knowledge_policy`, surfaced through
`knowledge_flags`) decides how much of that is *displayed*; it never decides whether
the entry exists. This is the defect being closed: random skill activations currently
vanish from the forecast rather than appearing as a probability.

`EFX-12 — Preview and commit share definitions and order.` The same composition, the
same handlers, the same step order. A preview that can disagree with its commit for
reasons other than an intervening die or an intervening committed action is a defect,
not a tuning parameter.

#### Ordered failure policy

`EFX-13 — Two fields, three behaviours.` Each step declares `required` (default
`true`) and `on_failure`:

| `on_failure` | Legal when | Behaviour |
|---|---|---|
| `abort` | any step; the only legal value for `required: true` | the transaction fails, no participant commits, no event is emitted |
| `skip` | `required: false` only | the step is dropped, its failure is recorded as a diagnostic, later steps continue |
| `halt` | `required: false` only | stop preparing further steps and commit what has prepared; the aggregate result sets `halted_at` |

`EFX-14 — A failed required step cannot leave partial state`, and this is structural
rather than disciplined: prepare wrote nothing live, so abandoning a transaction is
discarding an object.

#### Multi-authority transactions

`EFX-15 — Participants, not a god object.` A transaction has the effect journal plus
zero or more `TransactionParticipant`s, each `prepare` / `commit` / `rollback`.
`ResourceLedger` participates through its existing quote → commit → refund path;
inventory custody, progression, campaign position, condition duration, map-object
instance state and shop stock each participate as their own authority. The effect
runner never becomes the wallet, the inventory or the campaign owner — that is the
god object this contract exists to avoid, and it is why `ResourceLedger` is preserved
rather than absorbed.

`EFX-16 — Commit revalidates, then applies.` Commit first re-reads each journal
entry's `before` from its live authority. Any mismatch aborts with `stale_precondition`
and applies nothing. Participants then commit in declared order and the journal applies
**last**, so every fallible commit happens before the infallible one and rollback is
confined to participants that support it.

`EFX-17 — Rollback obligation.` A participant that can fail after another participant
has committed must implement `rollback()`. A participant that cannot roll back must be
ordered first or must not participate. On failure, already-committed participants roll
back in reverse commit order; a rollback that itself fails is a hard diagnostic naming
the authority and the entry, never a silent partial state.

#### Determinism and RNG

`EFX-18 — The source adapter owns the RNG event; the runner never seeds.` The adapter
calls `RngService.begin_event(kind, record)`, passes the stream in
`ActionContext.rng_stream`, and calls `commit_event(kind, record)` exactly once, only
after the transaction commits. A previewed, aborted or rolled-back transaction never
advances `history_hash`.

`EFX-19 — Draws are declared and counted.` Every step result reports `rng_draws`; the
aggregate equals their sum. A primitive that draws more than its registry entry
declares fails with `undeclared_rng_draw`. Draw order within a step follows the entry's
declared order, nested inside the canonical roll order in
*Determinism, Snapshot & Online Contract*.

`EFX-20 — Migration must not move the dice.` Porting an existing behaviour onto this
contract must not change the number or order of draws. A change that does is
save/replay-breaking under RNG-2 and needs an explicit version note, not a silent
handler rewrite.

#### Results, evidence and events

`EFX-21 — One result type, two scopes.` The aggregate `ActionResult` carries
`steps: Array[ActionResult]`, unions `affected_ids`, `events_emitted`,
`save_fields_touched` and `resources_spent`, and sums `rng_draws`. No caller may
discard a step result: today `ItemHandler` drops the `affected_ids` and
`save_fields_touched` that `ActionEffectRunner` already produces, which is how a typed
result becomes an untyped dictionary again.

`EFX-22 — Touched fields are declared, then checked.` The set of `save_field` values a
composition APPENDS to the journal must be a subset of the union of the participating
registry entries' `save_fields`. A write outside that set fails prepare with
`undeclared_save_field`. Every mutating entry declares at least one save field — already
true today, now enforced against actual writes rather than intent.

Two clauses of that sentence are load-bearing and were both wrong in the first
implementation (corrected 2026-09-01 by the Session 8 build). **Appends**: the check
covers the entries this composition added, not the whole journal, or a composition
prepared into a transaction that already holds other prepared writes is refused for
fields it never touched. **Compared on the property**: an entry declares
`"UnitData.hp"` because the qualified name tells a reader which resource the write lands
on, while the journal records the raw property `"hp"` because that is what the authority
writes through; the two are compared on the property and the prefix stays documentation.
Before the correction, any composition step touching a `UnitData` field was refused —
`apply_active_modifier` had shipped with the mismatch since Session 6 and nothing caught
it, because no authored composition had used it.

`EFX-23 — Presentation events fire only after commit.` `events_emitted` names EventBus
signals. The runner emits nothing during prepare, and after a successful commit emits
in journal order. A failed or rolled-back transaction emits none. This matches the
victory reward receipt rule in *Shared Runtime Service Boundaries*.

`EFX-24 — Diagnostics are separate from failure.` `ActionContext.diagnostics` collects
non-fatal notes: skipped optional steps, clamped values, gates hidden by presentation
policy. Diagnostics never gate player display, never change the result's `ok`, and
never persist.

#### Identity, replay and compatibility

`EFX-25 — Transaction identity is derived, not random.` `transaction_id` is a
deterministic function of the composition id and the source adapter's RNG event record,
so an identical replay produces an identical id. It is runtime-only evidence for
diagnostics and idempotence checks within one map session.

`EFX-26 — The contract persists nothing of its own.` No journal, transaction id,
diagnostic or step result reaches `SaveData`. Replay evidence remains the existing RNG
timeline plus the map ledger. Durable state introduced by a *migrated domain* —
`UnitData.conditions`, a future `map_objects_state` — is that domain's schema change,
declares its save fields, and appears in snapshot-coverage tests.

`EFX-27 — Campaign data stays backward compatible.` `effect_compositions` is an
optional registry family, not a member of `REQUIRED_FAMILIES`: a pack that authors none
validates exactly as it does today. `RegistryEntry` gains only optional fields with
defaults, so existing `.tres` entries load unchanged. An unknown field inside an
authored step is an authoring error reported with its exact path, matching the Tier-2
validators' `unknown_field` behaviour rather than being tolerated.

`EFX-28 — No compatibility execution paths.` The retired mechanisms named by the
review — mutating combat resolution, item-specific commit callables, query-only skill
handlers, arbitrary crossing effect callables, direct reward inventory writes, legacy
campaign-variable write APIs and UI-owned progression commits — are removed once their
callers migrate. Compatibility is limited to decoding existing *data and saves* into
the new authorities. Wrapping an old dispatcher in a typed envelope does not satisfy
this contract.

#### Stat evaluation and conditions

`EFX-29 — Stat evaluation resolves against the transaction, not against live state.`
`Unit.get_effective_stat()` and every derived formula take an optional state view. Given
one, a stat read sees the `active_modifiers` that transaction has PREPARED plus its
combat-duration scratch layer; given none, it reads live state exactly as before. This is
the clause that lets a combat-duration bonus — Resolve, a "+2" skill, a Pair Up bonus —
be visible to `compute_damage()` without being written. Preview, projection and resolve
must all be handed the same view, so the three cannot disagree by construction rather
than by each remembering to.

`EFX-30 — Scratch modifiers are read and never committed.` A modifier whose
`duration_type` is `combat` lives in the sink's scratch layer for the length of the
transaction and dies with it. An abandoned forecast therefore leaves nothing behind, and
no scope, snapshot or restore pair exists to guarantee it — the guarantee is structural.

`EFX-31 — Conditions are content.` `conditions` is an open registry family. The engine
ships no condition ids: identity, stacking rule, duration, tags, immunity, subscriptions
and consequences are all authored, and a pack adds a condition with no engine edit. The
engine owns the RULE SET a definition selects from (`refresh_duration`, `add_instance`,
`take_max`), never the choice.

`EFX-32 — Scheduling is subscription to NAMED tick sources.` `tick_sources` is a second
open registry family. A condition declares the sources it listens to; a firing of a
source ticks only its subscribers. Sources are addressable so an authored effect can fire
tick A without firing tick B, which a bare "tick this unit" call, a boolean, or an engine
enum cannot express. Engine sources declare the lifecycle point that publishes them and
are refused if the engine does not publish it; authored sources are fired only by the
`fire_tick_source` primitive. Ordering within one firing is registry order — priority,
then id — never dictionary order.

`EFX-33 — One firing is one transaction.` A tick that both damages and expires is two
authorities in one prepared transaction and commits whole or not at all. There is
therefore no mid-tick state, which is why a save taken "during" a tick needs no special
handling.

`EFX-34 — A condition contributes by being held, never by writing.` A definition's
`stat_modifiers` are DERIVED from the held entry at read time, once per stack, through
the same view every other read uses. A condition never prepares or commits a modifier of
its own, so its contribution is identical in a forecast, in a projection and in a
resolved fight, and expiring it removes the contribution with no cleanup step.

#### Authority split

| Concern | Owner | Never owned by |
|---|---|---|
| trigger timing, activation policy, use counters, durability, stock | source adapter | runner, coordinator |
| damage, healing, modifiers, variables, custody, wallets, class change | domain authority, called by a primitive handler | source adapter |
| atomicity across two or more authorities | coordinator | primitive handler, UI |
| validation, requirements, preview, ordering, RNG accounting, evidence | the protocol | source adapter |
| what the player sees | UI, reading a result | any of the above |

#### Adapter contracts

| Source | Owns (keeps) | Submits | Must not own |
|---|---|---|---|
| Combat / weapons | strike ordering, hit and crit resolution, formulas, forecast math | one prepared combat transaction covering HP, durability, wEXP, EXP, modifiers, death | live mutation during resolve; a second commit half |
| Items | custody, availability, consumption, durability | effect composition plus consumption in one transaction | heal/modifier primitives; a private preview language |
| Promotion / reclass | the modal as a *choice collector* only | the chosen class change plus consumption, through a progression coordinator | committing gameplay state from UI |
| Skills | trigger windows, Nihil, activation chance, per-map and per-combat limits | effect compositions; passive skills move to declarative contribution registries | reusable state mutations; boolean results |
| Status conditions | authored definitions, stacking, duration, immunity, named tick-source subscription | apply / periodic / expiry / cleanse / removal compositions | a private dispatcher; engine-owned condition ids; a private timer |
| Terrain | stateless queries and phase timing | healing and hazard compositions | durable per-instance state |
| Crossings and traps | deterministic trigger ordering and movement interruption | prepared effect requests; consumes results | arbitrary effect callables; one-shot state (that is a map object) |
| Map objects and story events | instance components, narrative sequencing | ordered compositions gated by shared requirements | per-object classes; a story-only mutation language |
| Objectives | AND/OR aggregation, victory timing, action scheduling | requirement compositions with structured reasons | being effect primitives; a second availability derivation for Seize/Escape |
| Rewards and cadence | authored reward content; cadence as a pure clock/selector | one transaction over ledger credit plus custody; prepared cadence effects | direct `party_items` writes; cadence executing effects |
| Purchases and services | quote workflow, goods, stock, shop UI | one purchase transaction over payment plus required outcomes | wallets (that is `ResourceLedger`) and custody (that is inventory) |

#### Worked example — a shop purchase, three authorities

An authored shop sells a vulnerary for 300 gold; the purchase grants the item and
sets a campaign flag the shopkeeper's later dialogue reads. Payment, custody, stock and
an authored variable are four authorities, and a partial commit is player-visible money
loss.

**Prepare.** The shop adapter resolves `target = {kind: "party"}`, opens no RNG event
(no step declares a draw), and prepares in order:

1. `ResourceLedger.quote([CostSpec gold 300])` → `ResourceTransaction{ok, deltas,
   wallets_touched}`. It is a participant, not a journal entry — the ledger owns wallets.
2. stock participant prepares a decrement of the shop's stock entry.
3. step `grant_item` prepares against the state view → journal
   `{step_id: "grant", authority_id: "inventory", save_field: "party_items",
   before: [...], after: [...]}`.
4. step `set_flag` has `requirements` naming the purchase's completion; it prepares
   → journal `{authority_id: "campaign_vars", save_field: "campaign_vars.met_merchant"}`.

Nothing has been written. `EFX-22` checks the two journal fields against the entries'
declared `save_fields`.

**Preview.** The same prepare, projected: `state_deltas` shows −300 gold, +1 vulnerary,
the flag transition and the stock decrement; `rng_summary.committed_draws` is `0` and
`uncertain` is empty. The shop UI renders affordability and the resulting item from one
structure instead of re-deriving it. If the player cannot afford it, the failure is
`requirement_unmet` or the ledger's shortfall, with reasons the UI can render — not a
disabled button with no explanation.

**Commit.** Revalidate every `before` against the live authorities; a stale wallet or a
sold-out stock row aborts with `stale_precondition` and nothing is applied. Then the
fallible participants commit in order — ledger, then stock — and the journal applies
last, granting the item and setting the flag together. If the stock commit fails, the
ledger refunds through its recorded deltas and the journal is discarded: the player is
not charged and holds nothing. On success, `events_emitted` fires after the commit, in
journal order.

The same shape covers the reward collision the review found: victory gold currently
commits through `ResourceLedger` while reward items are appended directly to
`GameState.party_items`, so a failure between them charges nothing but grants nothing —
one player-visible reward across two uncoordinated commits. Under this contract it is
one transaction with the ledger as a participant and custody in the journal.

### Known gaps

Rewritten 2026-09-01. The previous list opened "No code implements this contract" and
was written before Session 6; Sessions 6, 7 and 8 have since implemented the journal,
state view, participants, compositions, projection, combat, items, progression, skills,
stat evaluation and conditions. What follows is what is still open.

- Crossings and terrain healing migrated in Session 9: authored crossing compositions
  commit through the shared runner, fog visibility is a transaction participant, and
  healing uses `apply_hp_delta`. Map objects, story actions and cadence actions do not
  exist yet; rewards remain an existing half-transaction, while purchases have no
  production vertical slice. Their adapter contracts remain specification until those
  separately bounded builds or Session 10 land them.
- `phase_end` is not an engine tick-source lifecycle. `TurnManager` has no single point
  where every faction's phase ends, so an authored source naming it is refused rather
  than admitted and never fired. Adding it is a `TurnManager` change plus one entry in
  `TickSourceDef.ENGINE_LIFECYCLES`.
- A Tier-2 pack that declares ANY registry entry REPLACES the whole catalogue instead of
  layering over the engine's, so a pack must re-declare every engine family its content
  depends on — the FE proving-grounds pack re-declares `apply_active_modifier`, the
  objective conditions and now the `phase_start` tick source for that reason alone.
  Tracked as `PACK-REGISTRY-LAYERING-2026-09-01`.
- The FE proving-grounds pack is the only pack authoring conditions. Pack 0 authors
  none, so the second adopter for the condition family is still hypothetical.

### Anchors

- `scripts/actions/ActionRequest.gd`, `ActionContext.gd`, `ActionResult.gd`
- `scripts/actions/ActionPrimitiveRunner.gd`, `scripts/autoloads/ActionEffectRunner.gd`
- `scripts/autoloads/RequirementSystem.gd`
- `scripts/autoloads/ResourceLedger.gd`, `scripts/resources/ResourceTransaction.gd`
- `scripts/autoloads/ProjectionService.gd`, `scripts/projection/ProjectionContext.gd`,
  `scripts/projection/ProjectionResult.gd`
- `scripts/autoloads/RngService.gd`
- `scripts/core/CrossingResolver.gd`, `scripts/core/CrossingOutcome.gd`
- `scripts/registries/RegistryCatalog.gd`, `scripts/resources/RegistryEntry.gd`
- `scripts/actions/EffectStateView.gd`, `EffectMutationJournal.gd`, `EffectTransaction.gd`,
  `TransactionParticipant.gd`, `UnitStateSink.gd`, `SinkTransaction.gd`
- `scripts/autoloads/ConditionManager.gd`, `scripts/conditions/ConditionModel.gd`,
  `scripts/resources/ConditionDef.gd`, `scripts/resources/TickSourceDef.gd`

---
