# GDD_10 - Build Guide And Roadmap

**Status:** Active - build guide.
**Last verified:** 2026-08-02

This document is the human-readable build guide. It explains build order,
near-term focus, release/validation queues, and where to find detail.

The row-per-work-item tracker is the Project Control Plane:
[`AGENT/Docs/plans/project_control_plane_2026-06-29.md`](../Docs/plans/project_control_plane_2026-06-29.md).
Use Track IDs from that document when updating work status.

The legacy Phase 2 roadmap was archived at
[`AGENT/Docs/archive/plans/gdd10_legacy_phase2_roadmap_2026-06-29.md`](../Docs/archive/plans/gdd10_legacy_phase2_roadmap_2026-06-29.md).
It is historical source detail, not the active schedule.

---

## How To Use This Guide

1. Start from the Project Control Plane for exact row status, dependencies,
   source docs, tests, and next action.
2. Use this file to understand build order and the next practical work queue.
3. When feature behavior changes, update the owning `GDD_01`-`GDD_08`
   section and the matching control-plane row in the same change.
4. When adding, moving, or retitling docs, regenerate `AGENT/Docs/INDEX.md` and
   `AGENT/Docs/REGISTERS.md`.
5. When adding a mechanical documentation rule, extend
   `AGENT/Docs/check_docs.py` in the same change.

## Authority Map

| Need | Go to |
|---|---|
| Exact work rows, dependencies, source docs, tests, and next action | [`project_control_plane_2026-06-29.md`](../Docs/plans/project_control_plane_2026-06-29.md) |
| What old `GDD_10` rows mapped to | [`gdd10_active_work_coverage_matrix_2026-06-29.md`](../Docs/plans/gdd10_active_work_coverage_matrix_2026-06-29.md) |
| Dependency-band scope source | [`planned_unimplemented_feature_triage_2026-06-28.md`](../Docs/plans/planned_unimplemented_feature_triage_2026-06-28.md) |
| Document role rules | [`doc_role_manifest_2026-06-29.md`](../Docs/plans/doc_role_manifest_2026-06-29.md) |
| Preferred terms and retired aliases | [`project_vocabulary_manifest_2026-06-29.md`](../Docs/plans/project_vocabulary_manifest_2026-06-29.md) |
| Feature lookup by domain | [`GDD_Feature_Index.md`](GDD_Feature_Index.md) |
| Open/resolved register lookup | [`AGENT/Docs/REGISTERS.md`](../Docs/REGISTERS.md) |

## V1 Scope Snapshot

| Scope | Meaning | Tracker rows |
|---|---|---|
| V1-core | Conservative first playable campaign path. | Bands 1-5 |
| V1-lean/stretch | Valuable v1-adjacent work after core prerequisites. Campaign sharing/export/import is in v1 by owner decision. | Band 6 |
| Optional after stable core | Useful systems that add test permutations after the campaign loop works. | Band 7 |
| Post-v1 / parked | Later work or parked experiments. Side activities, public scripting VM, online play, Laguz, and Awakening are here. | Band 8 |

## Build Order

The dependency order is not a calendar. Later design can continue while earlier
bands are implemented, but implementation should not consume missing
foundations or add unmanifested save state.

| Band | Name | Build purpose | Exit check |
|---|---|---|---|
| 0 | Scope and tracking | Finish the tracking system, role/vocabulary discipline, `GDD_10` rewrite, and feature-index wiring. | `GDD_10` links to Track IDs; feature index can route features to rows. |
| 1 | Determinism and save gate | Package A, F1, SaveCodec, campaign/save envelope, suspend foundations. | New save state has F1 rows and fixture obligations. |
| 2 | Shared authoring/runtime contracts | Registries, action/effect runner, resource ledger, occupancy, death lifecycle, projection, load seams. | Feature consumers can call shared APIs instead of adding closed switches. |
| 3 | Core authoring foundations | CampaignRules profiles, TCV, predicates, MET, PHB, text, stat registry, resource pools. | Story/event/economy/map content can be authored through registries and predicates. |
| 4 | Campaign loop vertical slice | IEQ, PXP, convoy, shop, map objects, DCH, villages, dialogue v1, recruit, difficulty/death mode, deployment. | A short campaign can move map -> victory/defeat -> prep -> next map with save coverage. |
| 5 | Tactical v1 enrichment | Conditions, skills/effects, Source+Style, action grants, secondary movement, AI composition, minimum scorer, utility staves. | V1 maps have enough tactical variety without optional-system overload. |
| 6 | V1-lean/stretch packs | Campaign sharing/export/import, CampaignStatusRecord, property capture, rescue/carry, fog, destructibles, relationship minimum, prep progression, map readability, input, web debug. | Each slice has prerequisites from Bands 1-5 and can be staged. |
| 7 | Optional after stable core | Arena, battalions, stationary weapons, forging, PvP, property recruitment/production, AI recruitment choices, advanced AI valuation. | Schedule only after the campaign loop is stable enough to absorb extra cases. |
| 8 | Post-v1 / parked | Side activities, public builder, content resync, remote play, Laguz, Awakening, hex, perception, ML, Vision Pro. | Revisit after first stable campaign release or owner scope change. |

## Next Work Queue

### Text-entry input foundation

Status: **Pending validation 2026-08-02.** The shared constrained request/session model,
open entry-mode registry (`grid`, `hardware`, reserved `system`), persisted resolver
setting, hardware and grid presenters, printable-US-ASCII data layout, and the
FileDialog first-Escape/path-entry adopter are implemented. The v0.6.0 return repair
adds the single `TextEntryService` session/arbitration owner and a prebuilt reusable
grid-keyboard scene, with deferred construction and focus-withdrawal guards.
FileDialog now adopts that service through an explicit filename-edit state whose
first Escape exits editing and whose second Escape remains FileDialog-owned. The
production-backed Playwright surface is **Implemented 2026-08-02** through the opt-in
read-only Web state bridge; responsive album generation and review are in progress. Windows event-order/crash
and visual validation remains mandatory;
the wheel and Steam system-keyboard backend remain later slices by design.

### Controller transition diagnostics

Status: **Implemented; pending native Windows/controller validation 2026-08-02.**
Bounded structured telemetry now correlates attack confirmation through combat,
records EXP/level-up/end-turn/modal/focus/input/turn transitions, and tracks explicit
cursor-suppression ownership. A diagnostic-only one-shot watchdog reports stale
suppression state without mutating it. Automated coverage pins balanced ownership,
correlation continuity, legitimate long-transition standdown, one-shot reporting,
complete snapshot fields, immutability, and the bounded buffer. Closure still needs
the dedicated Windows playtest branch and returned controller log.

### Campaign data-ownership implementation line

The approved planning sources are
[`zero_content_engine_implementation_plan_2026-07-23.md`](../Docs/plans/zero_content_engine_implementation_plan_2026-07-23.md),
[`formula_registries_implementation_plan_2026-07-23.md`](../Docs/plans/formula_registries_implementation_plan_2026-07-23.md),
[`pack_associated_save_implementation_plan_2026-07-23.md`](../Docs/plans/pack_associated_save_implementation_plan_2026-07-23.md),
[`multi_owner_economy_implementation_plan_2026-07-23.md`](../Docs/plans/multi_owner_economy_implementation_plan_2026-07-23.md),
and [`rule_profiles_implementation_plan_2026-07-23.md`](../Docs/plans/rule_profiles_implementation_plan_2026-07-23.md).
The machine-checkable order lives in `coordination/tasks.json`: inactive
zero-content boot -> v1 formula registries -> all Tier-2 families -> base-pack
extraction -> pack-save schema/load -> wallet migration -> rule profiles, with
export/backup and final no-content export gates following their recorded
dependencies. Start with the zero-content foundation task after its release-line
and result-action prerequisites clear.

**Zero-content foundation Implemented 2026-07-30:** inactive headless boot,
explicit transactional project-data compatibility activation, atomic Tier-2
session replacement, package deactivation, and the Main Menu No Packs state are
covered by focused regressions. The temporary compatibility setting remains on
until base-pack extraction; the v1 formula-registry slice is the next dependency.
The v0.6.0 return repair on 2026-08-02 pinned the required boundary: activating a
Tier-2 package preserves the engine-owned registry baseline, so `nearest_free`
and the other map-start policies remain available during live unit placement.

**Formula Registry V1 Implemented 2026-07-30:** separate immutable hit, range,
cost, and requirement primitive registries now validate bounded inputs and fail
unknown ids. Combat uses registered `two_roll`/`single_roll`; weapon range uses
registered literal/stat-divisor evaluation behind the legacy-string adapter; the
ledger supports fixed and quantity-times-unit-price quotes without moving mutation
authority. Pack selector migration remains part of base-pack extraction.

### B1-CST campaign / save spine

**All three slices are Implemented (2026-07-14)** — a campaign runs end to end:
the graph is authored, the position walks it, and the run survives a quit. The
sequenced slices are in
[`b1_cst_save_spine_handoff_2026-07-14.md`](../Docs/plans/b1_cst_save_spine_handoff_2026-07-14.md).
What the spine deliberately did **not** own, and where it went: manual-save
and prep/deployment landed under `B4-PREP-DEPLOYMENT`; package-aware selection,
map-registry one-node auto-wrap, and last-started/imported preference landed under
`B6-CAMPAIGN-SHARING`. Explicit branch-node choice, the dedicated
`MapResultsScreen`, and the full defeat recovery menu are also Implemented.
Live Windows validation of these new surfaces remains a release qualifier.

`B6-CAMPAIGN-SHARING` is Implemented from its isolated package prerequisites
through player-facing transfer:
`AssetResolver` provides pack-scoped raw-media loader primitives behind open
asset-group/id/fallback registrations, including repair reporting and path
containment. `PackManifest` and the canonical Tier-2 catalogue parser now
validate package compatibility, safe unique Tier-2 document identities/paths,
and registry-dispatched content-family schemas without installing or selecting
anything. The first concrete validator set now proves a complete campaign/map/
roster/class fixture and all cross-document ids. The package pipeline includes
pure ZIP preflight now verifies the actual format and central-directory metadata,
normalizes the one-root package namespace, rejects collisions/unsafe paths/
symlinks/special files, applies caller-supplied entry and byte limits, validates
all structured content in memory, and excludes unindexed or save-shaped files.
The engine now performs rollback-safe staged installation after preflight:
admitted entries extract only below a unique service-owned staging root, the
filesystem is validated a second time, and a validated `{id, version}` is
atomically promoted. Existing versions are rejected byte-for-byte; extraction,
validation, and promotion failures clean staging without touching installed or
runtime/save state. Deterministic export now admits only validated indexed data
and approved media in lexical order, excludes saves/caches/unrelated files by
construction, and re-preflights its artifact; export/import tests preserve every
admitted byte. Installed-pack discovery now revalidates path identity and the
complete catalogue into deterministic cached summaries while excluding broken
candidates. The explicit Tier-2 runtime adapter now constructs existing engine
Resource types in memory, swaps sources atomically, resolves package-scoped map
ids, and restores exact package identity from campaign/suspend saves before
reference validation. New Game now appends validated installed campaigns with
visible pack identity, activates the exact selected source before starting, and
restores shipped content when a shipped row is chosen. Its Manage Campaigns
overlay provides filesystem ZIP import/export, structured failure/repair
feedback, inert install plus selector refresh, and deterministic re-preflighted
export. `B6-CAMPAIGN-SHARING` is Implemented; future editing/repair controls
remain separate builder work.

| Order | Track ID | To-do | Decision state |
|---:|---|---|---|
| 1 | `B1-CST` Slice 1 | **Implemented 2026-07-14:** `CampaignData`/`CampaignNode` progression graph, the shipped `proving_grounds` campaign, DataManager catalogue loading, and loud structural/reference validation. | Graph is authored JSON per [CST-3]; shipped nodes now bind by `encounter_id`, while `map_id` remains the compatibility route. |
| 2 | `B1-CST` Slice 2 | **Implemented 2026-07-15:** `CampaignManager` walks the graph; `MapResultsScreen` owns victory/Continue and explicit branch choice; `GameOverScreen` owns defeat with Retry, most-recent/any save load, Rewind, and Main Menu. Handoff: [`b1_cst_slice2_prep_results_flow_handoff_2026-07-14.md`](../Docs/plans/b1_cst_slice2_prep_results_flow_handoff_2026-07-14.md). | A win records before validated choice/preparation/commit/autosave. Defeat recovery reuses the unified slot discriminator and deterministic ledger rewind. Shared standings formatting preserves the future PvP/scenario seam. |
| 3 | `B1-CST` Slice 3 | **Implemented 2026-07-16:** the campaign envelope and between-map save round-trip position, flags/vars, rules, roster, gold, and party-item convoy compatibility; `SaveManager` owns transactional campaign slots and the **Load Game slot picker**. Terminal autosaves are retained as completion records but excluded from Continue. Successor map/roster preparation now precedes result commit. Portable save transfer exports one integrity-stamped JSON and imports through ZIP/JSON sniffing plus acknowledged tamper/large-file warnings. Suspend captures idle boundaries for every local faction; during AI control it queues until the acting unit commits, then Continue resumes that already-started faction without replaying phase-start effects. Surface contract: [GDD_07 — Screens And Panels](GDD_07_Screens_Panels.md) §Load Game Screen. | Restore stages mutable state and validates item references before package/campaign mutation; duplicate items carry and explicit empty fields clear stale state. Slot + index row + Continue pointer and portable artifact replacement use rollback-capable staged promotion. `ImportBudgets.gd` owns adjustable portable-save warning/maximum and separate campaign-archive caps. The maximum rejects before buffering; the warning retains integrity/schema validation and requires acknowledgement. Representative between-map, mid-map, large-roster/convoy, and shipped-policy ledger measurements have explicit warning-budget headroom. The pending result is deliberately NOT persisted and remains retryable when successor validation fails. **The manual-save surface is reassigned to `B4-PREP-DEPLOYMENT`** (2026-07-14). |
| 4 | `B4-ENCOUNTER-MODEL` Slices 1-2 | **Implemented 2026-07-16:** manifest-backed `BattleMapDef`/`BattleEncounterDef` catalogues, `encounter_id -> battle_map_id` campaign resolution, one runtime bundle, all eight shipped split pairs, and explicit monolithic `MapData` compatibility. | No generated forces, map pools, scaling, skirmish UI, or Slice 3+ behavior. Saves retain campaign `node_id` and the existing staged source string. |

**Immediate post-goal housekeeping:** after the campaign/save follow-up completion
gate closes, inventory remote branches, preserve build/evidence branches that remain
historically necessary, and delete only merged or explicitly obsolete GitHub branches.
Do not fold that repository-administration pass into this goal or delete branches
without confirming their remote merge/evidence status.

### B6 mutable campaign rule state

Status: **Implemented 2026-07-15** for `B6-PER-MAP-OVERRIDES` Slices 1-2.

The open three-layer resolver now applies triggered mid-map overrides above
node-authored `rule_overrides` above effective campaign defaults, with mandates
short-circuiting both overlays. `end_of_map` flips remain temporary;
`permanent` flips append to the shared `MutableCampaignState` patch log. The
store also reserves open carry-forward facts and imported-record identity for
`B6-CAMPAIGN-STATUS`. Campaign, suspend, and ledger paths round-trip the proper
layers, including old-save empty-store migration and Retry/Rewind rollback.

Status: **Implemented 2026-07-15** for `B6-CAMPAIGN-STATUS` Slice 4.
Completed runs export compact checksummed status records. New Game supports
same-campaign/declared-sequel scan, None, and explicit manual foreign import;
facts and source identity enter the shared mutable store and campaign-variable
path. Corrupt/incompatible automatic imports are inert. Replacement export uses
staged promotion with rollback so a failed finalize preserves the prior record.

### B1-LEDGER unified persistence & undo

Retry, Rewind, and Suspend become three reads of ONE within-map history — a
two-tier decaying ledger — with campaign save the layer above it. The design is
in
[`persistence_undo_unified_handoff_2026-07-15.md`](../Docs/plans/persistence_undo_unified_handoff_2026-07-15.md);
the sequenced BUILD/SCRAP plan is
[`persistence_undo_implementation_plan_2026-07-15.md`](../Docs/plans/persistence_undo_implementation_plan_2026-07-15.md).
A returned v0.4.0 playtest preempts this work; Rewind (Phase 3) is the one
deferrable phase, gated on the Phase 1 entry-size measurement.

| Order | Track ID | To-do | Decision state |
|---:|---|---|---|
| 0 | `B1-LEDGER` Phase 0 | **Implemented 2026-07-15:** the dedicated control-plane tracker row (this row's home), replacing the persistence work's prior parking under `B1-PKGA`/`B1-CST`. | Docs-only housekeeping; no behavior change. |
| 1 | `B1-LEDGER` Phase 1 | **Implemented 2026-07-15:** the suspend-complete board serializer is factored into `GameState._capture_map_runtime_entry()` and shared by `capture_suspend_save()` and the new within-map history (`push_history` / `history_size` / `peek_history`); `take_map_snapshot()` seeds the round-0 entry. Contract: [GDD_01 — Runtime Contracts](GDD_01_Runtime_Contracts.md) §Determinism, Snapshot & Online. | An entry is SUSPEND-complete (all factions + turn + cursor + RNG + PairUp), unlike the party-only Retry snapshot. The refactor is byte-identical for suspend/Retry. Measured ~2 KB/unit (14-unit board ≈ 28 KB), so the ledger is not memory-bound — Phase 3 Rewind is clear to build. Retry still reads the party-only snapshot until Phase 2. |
| 2 | `B1-LEDGER` Phase 2 | **Implemented 2026-07-15:** the two-tier decaying ledger is `scripts/save/MapLedger.gd` (a reason-tagged list; `prune()` keeps `(last undo_activations activations) UNION (last undo_rounds round-starts)` + the always-retained round-0); the `undo_activations` / `undo_rounds` budgets are on `CampaignRules` and both codecs; each entry folds the party economy (gold/items/roster); Retry is now `GameState.restore_history(0)` (from `GameOverScreen`), and the party-only `restore_map_snapshot` / `_map_start_snapshot` path is deleted. Tests: `test_map_ledger` (prune 1/N/∞), migrated `test_rng_snapshot` / `test_pair_up_registry` / `test_game_state`, party-economy rollback in `test_ledger_entry`. | Prune is data, not a mode `match`. Party economy per-entry (DECIDED 2026-07-15) so a rewind undoes village/chest gold. Budgets are RETENTION depth; spending them mid-battle is Phase 3. |
| 3 | `B1-LEDGER` Phase 3 | **Implemented 2026-07-15:** `TurnManager` pushes coalesced post-activation and refreshed round-start checkpoints; Map Menu exposes `Rewind (N)`; `GameState.rewind_last_action()` validates and stages the target through the active-map resume path, spends one `rewind_charges_per_map` charge, and truncates the abandoned future only after acceptance. Tests cover push, spend/exhaustion, party-economy rollback, branch truncation, identical replay, and changed-action divergence. | `rewind_charges_per_map` is the sole spend meter; `undo_activations`/`undo_rounds` are retention preferences. Fine retention is floored to charges + 1 so the authored spend budget remains reachable. RNG restore makes rewind decision-undo, not luck-scumming. |
| 4 | `B1-LEDGER` Phase 4 | **Implemented 2026-07-15:** all documents use the named slot store; `map_runtime.map_path` distinguishes `mid_map` from `between_map`; `GameState.capture_save` selects the shape; mid-map slots persist the whole ledger and campaign envelope; every slot carries `origin` plus autosave `rule_id`; mirrored headers label `Resume battle — Turn N` versus `Continue — node`. Continue and Load share one loader. | Scrapped `SUSPEND_FILENAME`, the dedicated suspend CRUD API, and the separate Continue kind. The reserved Map Menu slot is `resume_battle`; map resolution deletes it. Slot/index replacement remains transactional. |
| 5 | `B1-LEDGER` Phase 5 | **Implemented 2026-07-15:** campaign-authored `save_slot_classes` and `autosave_rules`; pure GBA 3+1, single-consumable, and 30-any presets; open `AutosaveTriggerRegistry` with battle start/end, menu/shop exit and custom ids; rule-owned rotation; consumed-on-success loads; infinite Rewind (`-1`); runtime and `check_docs.py` durable-mid_map warnings. Tests cover presets, malformed authoring, dispatch, rotation, counts, consumption, and warnings. | Policy is enforced at save/load/UI boundaries. Autosave candidates structurally require `origin:auto` + matching `rule_id`, so manual and other-rule slots cannot be overwritten. Check 33 requires infinite rewind for durable mid-map authored policy. `B1-LEDGER` is Implemented across Phases 0-5. |

### B3-PHB prep activity registry

Status: **In implementation** — the open registry seam is **Implemented
2026-07-19**; node integration and concrete service panels remain **Target design**.

`PrepActivityRegistry` validates data-defined activity ids against registered panel
factories and creates panels from copied authored parameters/context without retaining
UI state. An inert fixture proves the open extension path. Convoy, shop, arena,
training, recruitment, hub-node flow, and on-map placement remain in their owning
tracks.

### B4-PREP-DEPLOYMENT prep screen

The between-map surface: pick who deploys, place them, optionally save, begin the
battle. Sequenced slices are in
[`b4_prep_deployment_handoff_2026-07-14.md`](../Docs/plans/b4_prep_deployment_handoff_2026-07-14.md).
It inherits two things already built: the `[CST-5]` node deployment constraints
(authored on `CampaignNode` since `B1-CST` Slice 1 with no reader) and
`CampaignManager.write_campaign_slot` (the manual-save seam). `B3-PHB` is **not**
a prerequisite — shops/trade/convoy panels are a later slice, not a blocker.
A returned v0.4.0 playtest preempts work here.

| Order | Track ID | To-do | Decision state |
|---:|---|---|---|
| 1 | `B4-PREP-DEPLOYMENT` Slice 1 | **Implemented 2026-07-14:** the deployment plan seam, no UI. `GameState.next_map_deployment` (`unit_id` -> start tile) stages the plan; `GameMap._spawn_units` consumes it and falls back to the historical roster-order rule when it is absent; `scripts/shared/DeploymentPlan.gd` validates a plan against the party, the map's `player_start_tiles`, and the node's `required_units` / `excluded_units` / `deployment_cap`. Contract: [GDD_01 — Data Contracts](GDD_01_Data_Contracts.md) §Deployment Plan Contract. | Deployment stops being INFERRED and becomes a CHOICE. The plan is not persisted (a campaign save is parked between maps, so a reload lands back on prep) but DOES survive a Retry. `GameMap` revalidates and refuses an illegal plan rather than spawning a half-legal board. **A fallen `required_unit` is EXCUSED, not a launch block** — blocking would strand the campaign; whether a key death ends the run is a campaign-rules question. |
| 2 | `B4-PREP-DEPLOYMENT` Slice 2 | **Implemented 2026-07-15:** `PrepScreen` is a pure destination screen listing the living eligible party, required/optional deploy toggles, ordered placement onto `player_start_tiles`, and Begin Battle gated by `DeploymentPlan.validate`. Campaign launch and non-suspend campaign Retry route here; bare-map and suspend-resumed Retry retain direct reload. | Launch staging/roster policy remains solely in `CampaignManager`; prep only authors `GameState.next_map_deployment`. The previous plan preselects after ledger rollback, so victory and defeat Retry may redeploy without reseeding the party. Surface contract: [GDD_07 — Screens And Panels](GDD_07_Screens_Panels.md) §Prep, Service, And Authoring Panels. |
| 3 | `B4-PREP-DEPLOYMENT` Slice 3 | **Implemented 2026-07-15:** Prep writes a player-named campaign slot through `CampaignManager.write_campaign_slot`; successful slots appear in the existing Load Game picker. | `SaveManager.is_valid_slot_id` rejects unsafe player-supplied filenames without sanitizing or writing; labels remain independent display text. |

### v0.3.3 returned-playtest defects

The v0.3.3 focused rerun returned on 2026-07-14. The permanent checklist and
root-cause packet are
[`playtest_checklist_v0.3.3_returned_2026-07-14.md`](../Docs/playtests/playtest_checklist_v0.3.3_returned_2026-07-14.md)
and
[`playtest_v0.3.3_results_triage_plan_2026-07-14.md`](../Docs/playtests/playtest_v0.3.3_results_triage_plan_2026-07-14.md).

| Order | Track ID | To-do | Decision state |
|---:|---|---|---|
| 1 | `VAL-V030-GAMEPAD` | Implemented 2026-07-14: raw joy-axis zoom no longer bypasses the 0.85 threshold or double-consumes a pull; final live validation remains. | Single-owner polling fix implemented with event-path regression coverage. |
| 2 | `B6-MRD` | Implemented 2026-07-14: watch sets, danger mode, markers, pruning, and versioned suspend state are isolated by controlling faction. | Watch state belongs to the controlling faction; no player/seat ownership. |
| 3 | `UI-INSPECTION` | v0.3.6 passed Action Menu shrink-wrap, ornament clearance, reopen growth, and edge clamping live. | Accepted for now; recheck visual spacing during the broader UI redesign pass. |
| 4 | `UI-INSPECTION` | v0.3.6 passed bounded Settings/Unit Details focus traversal live, including mixed-height lookahead and endpoint clamps. | Accepted for now; recheck focus-scroll context during the broader UI redesign pass. |
| 5 | `UI-INSPECTION` | **Implemented 2026-07-16:** Mana Soul theme rollout covers Main/Settings/Item/Weapon menus; Main Menu uses a tested pinned-large safe rectangle rather than tactical Menu Scale. | Headless layout/theme tests pass; retain visual polish for the broader UI redesign. |

Menu threat retention and `dual_outline` passed. `VAL-V030-GAMEPAD` remains
Pending validation; the repaired UI surfaces passed the v0.3.6 focused rerun,
with polish retained under `UI-INSPECTION`. The next-session execution packet is
[`v0.3.3_playtest_fix_handoff_2026-07-14.md`](../Docs/plans/v0.3.3_playtest_fix_handoff_2026-07-14.md).

### v0.4.0 release gate

v0.4.0 is bounded to the seven Band 2 shared-contract slices. The release
checklist is [`v0.4.0_release_checklist_2026-07-13.md`](../Docs/plans/v0.4.0_release_checklist_2026-07-13.md).
All seven rows are implemented; the next session is a full-delta code review
against that checklist. Metadata/export work starts only after review findings
are resolved. Band 3 consumers are outside this release boundary.

> **Focused rerun build `v0.3.1` RETURNED 2026-07-12** (source `c7ce311`) —
> the live vehicle for the items below. Handbook:
> [`playtest_checklist_v0.3.1.md`](../Docs/playtests/playtest_checklist_v0.3.1.md);
> manifest (size/SHA-256):
> [`playtest_build_v0.3.1.md`](../Docs/playtests/playtest_build_v0.3.1.md).
> Returned checklist:
> [`playtest_checklist_v0.3.1_returned_2026-07-12.md`](../Docs/playtests/playtest_checklist_v0.3.1_returned_2026-07-12.md).
> Triage plan:
> [`playtest_v0.3.1_results_triage_plan_2026-07-12.md`](../Docs/playtests/playtest_v0.3.1_results_triage_plan_2026-07-12.md).
> Suspend and maximize readout hold; stick targeting passes; gamepad/display
> v0.3.2 closes the display gate and accepts MRD-7 `dual_outline`; the gamepad
> gate stays open only for zoom feel, with menu-overlay retention and scale-aware
> menu focus lookahead routed as bounded follow-ups.

| Order | Track ID | Work item | Why next |
|---:|---|---|---|
| 1 | `VAL-V030-GAMEPAD` | Fix the v0.3.3 trigger double-consumption defect | Raw joy-axis events bypass the polling threshold and can step once below 0.85, then again when polling crosses it. Route analog triggers exclusively through the threshold-aware poller and retest. |
| 2 | `B6-MRD` | Decide and implement watch-view ownership | Menu threat retention and `dual_outline` passed, but one global watch set leaks markers across faction handoffs. Per-faction state is recommended; include suspend migration. |
| 3 | `UI-INSPECTION` | Fix the two v0.3.3 high-scale layout findings | Make Action Menu width content-driven at 2x and calculate lookahead from visual owner rows rather than leaf slider height. Keep the existing deferred keybind/Main Menu tasks queued. |

## Parallel Queue

The v0.3.0 return arrived and was triaged 2026-07-08 via the return triage kit
([`playtest_v0.3.0_results_triage_plan_2026-07-08.md`](../Docs/playtests/playtest_v0.3.0_results_triage_plan_2026-07-08.md));
the focused v0.3.0.d rerun returned 2026-07-10 and moved the remaining fixes
into the Next Work Queue above. The rows below stay safe parallel candidates.

| Priority | Track ID / area | To-do | Notes |
|---:|---|---|---|
| 1 | `VAL-V030-GAMEPAD` / `VAL-V023-DISPLAY` | v0.3.2 focused rerun intake DONE 2026-07-13. | Returned checklist and two logs moved to permanent docs/evidence homes; [`playtest_v0.3.2_results_triage_plan_2026-07-13.md`](../Docs/playtests/playtest_v0.3.2_results_triage_plan_2026-07-13.md) records root causes and decisions. Display is Implemented; gamepad remains Pending validation only for zoom feel. |
| 2 | `B2-ACTION-EFFECT`, `B2-RESOURCE-LEDGER`, `B2-OCCUPANCY`, `B2-DEATH-LIFECYCLE`, `B2-PROJECTION`, plus `B3-TCV`, `B5-AI-COMPOSITION`, `B3-STAT-REGISTRY` | Continue the open-registry stream. | **Band 2 contracts Implemented; objective/item registry follow-up added 2026-07-15:** source registries strict-replace from the selected content root; actions validate/dry-run; fixed wallets transact atomically; map-start placement, death, and combat projection use shared services. Objective conditions and item effects now load compatibility-preserving data entries and dispatch validation/evaluation/display or preview/commit without closed id switches. AI/perception projection adapters, generalized requirement/event composition, formulas, pools, broader placement/death consumers, custody, and persistent delay remain deferred. |
| 2A | `B5-AI-MIN-SCORER` Slice A | **Implemented 2026-07-19:** additive `CombatResolver.project_exchange()` ordered projection with bounded outcome branches, symmetric style slots, parameterized proc policy, and tile-excluded deterministic caches. | No shipped AI behavior changes. Weight/scoring adoption and joint tile/target/source search remain Slices B/C. |
| 2B | `B3-REFERENCE-MODEL` | Build the renderer-neutral semantic reference foundation after the narrow CampaignRules profile slice and before `B4-PXP`. | Approved target design 2026-07-30: activated rules emit structured facts, relations, safe provenance, and separate author notes for More Info, headless GFM/PDF export, and later HTML/Compendium/editor consumers. PXP is the first complex emitter proof; skill conversion follows. Plan: [`generated_reference_model_implementation_plan_2026-07-30.md`](../Docs/plans/generated_reference_model_implementation_plan_2026-07-30.md). |
| 3 | `UI-INSPECTION` | Prototype draft UI assets headlessly. | Build a mockup-only Godot `Control` scene/script that copies curated draft UI sheets into a temporary Theme, renders static Action Menu / UnitDetails / AttackPreview / shop-or-convoy list screenshots at supported menu scales, and checks for nonblank output, clipping, and bad slice margins. Keep it separate from production UI until the screenshots survive review. |
| 4 | `CLEAN-OBJDB-LEAK` | Clean benign test fixture leaks. | Optional cleanup from the ObjectDB audit; reduces noisy suite exits without changing player behavior. |
| 5 | `REL-PACKAGING` | Draft the release packaging flow. | Define shipped files, hashes, tags, manifests, checklist pairing, and future public/playtest packaging steps. |

### Persistent build items (schema reserved; implementation sequencing remains)

| Track ID | Reserved item | Remaining prerequisite |
|---|---|---|
| `B5-AI-COMPOSITION` (step 3+) | The MVP dispositions + activation from `ai_first_build_design_2026-06-22.md` §9 steps 3-6: `territorial`/`tethered` (sleep+latch / leashed return-home), `flee` (±`goal_tile`), `seek_tile`, group-keyed aggro, and the MET `set_ai` action. (`weakest` already ships through `hunter`.) | F1 is implemented and reserves active-map AI wake/latch state. The build slice must now add the exact `ai_awake` serializer/snapshot representation and fixtures while coordinating `set_ai` with the unbuilt MET/action runner. |
| `B3-STAT-REGISTRY` (storage slice) | The author-extensible stat STORAGE model ([STM-3]): `UnitData.extra_stats` name->value dict, `ClassData` extra-stat bases/caps/growths, the `get_effective_stat` read-path fallback, and the author-declared stat registry on `CampaignRules`/manifest so adding a stat becomes one data entry (zero engine edit). | F1 is implemented with `roster.units[].extra_stats` and `campaign.rules.stat_profile_id` rows. The build slice must add their stat adapter, reference validation, old-save defaults, and codec round-trip fixtures together. |

## Validation And Release Queues

These are not blocked by the full Band 1-5 build path, but they should not be
lost during foundation work.

| Track ID | Queue | Action |
|---|---|---|
| `REL-V042-PORT` | Release gate | **Implemented 2026-07-16:** accepted v0.4 fixes are ported to the split results/defeat architecture: owner-counted modal locking, committed reward totals, Map Menu party gold, independent Character Sheet prose scrolling, and release-availability gating for deferred skills. A fresh tagged release train and live rerun remain Pending validation. |
| `VAL-V023-DISPLAY` | Validation | **Implemented 2026-07-13:** v0.3.2 passed width-only and height-only resize tracking, one-second convergence, relaunch persistence, maximize labeling, and restore-to-saved-size. Evidence and routing: `playtest_v0.3.2_results_triage_plan_2026-07-13.md`. |
| `UI-VIEWPORT-ASPECT` | Validation | **Implemented 2026-08-02, Pending native validation:** viewport **expand** model + persisted `content_scale_factor` UI-scale setting (default on the identity diagonal), menu-scale reconciliation, independent-axis resolution write-back, and `snap_2d_transforms_to_pixel`. Centered temporary windows now use 90%-of-safe-viewport caps and scroll ownership; Campaign Library's absolute frame migrated. Version-2 HUD layout stores panel and safe-viewport attachment points, logical offset, and scale; all 8×8 pairs are tested and full panels clamp to the safe rectangle. Production-backed Playwright album covers 19 surfaces at seven odd/720p/16:10/1080p/1440p/4K scale-and-padding cases. Design floor ratified at 1280×720. Headless suite green; native closure remains gated on the owner Windows visual matrix. Detail: `viewport_expand_more_tiles_scoping_2026-07-11.md` §0.1. |
| `VAL-V030-GAMEPAD` | Validation | v0.3.2 passed dropdown standdown, character-sheet navigation/scrolling, menu cadence, and contextual-menu anchoring. Gate remains Pending validation only for asymmetric LT/RT zoom feel; source diagnosis points to uneven zoom ratios rather than separate trigger timers. Triage: `playtest_v0.3.2_results_triage_plan_2026-07-13.md`. |
| `REL-V023-MERGE` | Release gate | Merge the v0.2.3 branch to `main` only after validation passes. |
| `VAL-V022-CHECKBACKS` | Validation | Walk the v0.2.2 live-verify check-backs during playtest triage. |
| `VAL-PLAYTEST-RERUN` | Validation | Rerun outstanding playtest items before promoting them to defects. |
| `REL-REN` | Release gate | Owner must choose public naming direction before first public RC. |
| `REL-LEG` | Release gate | Audit FE-derived numeric values and every shipped asset before public release; LEG-1 confirmed there is no source handbook/corpus to license. |
| `REL-PACKAGING` | Release gate | Draft release packaging flow after v0.2.3 process settles. |
| `REL-WEB-DEMO` | Release gate | Draft the slice-first playable web-demo plan after the campaign-loop foundations are accepted. |

## Cleanup Queue

Release hardening has three active cleanup rows. Keep them separate from feature
work until a non-debug release is being cut.

| Track ID | Cleanup |
|---|---|
| `CLEAN-DEBUG-AIDS` | Remove force-levelup and growth-boost debug aids. |
| `CLEAN-F9-HOTSEAT` | Remove F9 all-faction hotseat override. |
| `CLEAN-DEBUG-HUD` | Remove debug-mode HUD banner ecosystem. |

The stale `GDD_10` milestone body has been replaced by this Track-ID build
guide. Future cleanup should happen in the owning tracker row or numbered GDD
chapter rewrite, not by restoring legacy milestone order.

## Parked Or Post-v1 Work

Do not schedule these for v1 unless the owner explicitly changes scope:

| Track ID | Work |
|---|---|
| `B8-ACTIVITIES` | Side activities, ActivityRunner, activity templates, public scripting VM. |
| `B8-PUBLIC-BUILDER` | Public campaign builder / authoring GUI. |
| `B8-CONTENT-RESYNC` | Public content-pack compatibility/resync. |
| `B8-REMOTE-PLAY` | Remote / online play. |
| `B8-LAGUZ` | Laguz system. |
| `B8-AWAKENING` | Awakening supplement. |
| `B8-HEX` | Optional hex topology. |
| `B8-PERCEPTION` | Perception / masking. |
| `B8-ML-EVAL` | ML evaluation experiment. |
| `B8-VISION-PRO` | Apple Vision Pro reach. |
| `B8-TILE-RESCALE` | Native-resolution pixel-art selection and possible `TILE_SIZE` rescale; research and cost assessment are linked from the control plane. |

## Update Discipline

When work changes:

| Change | Required documentation update |
|---|---|
| Behavior changes | Update affected `GDD_01`-`GDD_08` section and the matching control-plane row. |
| Work status changes | Update the Project Control Plane row; keep this guide as a summary. |
| New feature or scope split appears | Add or adjust a Track ID in the Project Control Plane, then wire the feature index. |
| New active doc is added or moved | Regenerate `AGENT/Docs/INDEX.md`; if it is a register change, regenerate `REGISTERS.md` too. |
| Mechanical doc rule is ratified | Add `check_docs.py` enforcement in the same change. |
| Session ends | Add a session note and newest-first row in `AGENT/Session Notes/INDEX.md`. |

## Known Follow-ups

No completed Band 0 documentation task remains queued here. Future owner-heading or
scope changes must update the exact Feature Index links and their control-plane rows
in the same change.
