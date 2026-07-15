# v0.3.0 Full-Scan — Consolidated Code-Pillar Review (2026-07-08)

> Rollup for the resumable full code-pillar scan of the v0.3.0 production delta
> (`AGENT/Code Reviews/v030_full_scan/`). This is the Pass 7 (final) synthesis:
> it reads across passes 1–6, hunts cross-cutting/seam issues, and carries the
> per-pass findings into one prioritized list. **Document-only; no production
> code was edited.** Fixes land later as focused commits.

Procedure:

- `AGENT/Review Procedures/00_Master_Review_Procedure.md`
- `AGENT/Review Procedures/01_Code_Pillar.md`

Per-pass findings files (this folder):

- `01_save_persistence.md` · `02_determinism.md` · `03_input_model.md`
- `04_input_display.md` · `05_map_turn_core.md` · `06_ui_misc.md`

Supersedes for the code pillar: the composed
`AGENT/Code Reviews/code_review_v0.3.0_release_delta_2026-07-07.md` (score 6/10),
which leaned on prior reviews for coverage. This scan freshly read every changed
line across all 38 production `.gd` files.

**Overall health:** 6/10

The v0.3.0 delta is mechanically much stronger than the v0.2.8 base — save/suspend,
controller input, prompt swapping, MRD overlays, the CampaignRules consolidation, and
the deterministic-RNG seams all now have real automated coverage, clean seams, and
disciplined determinism plumbing. **The line-by-line read found zero new correctness
bugs** across all 38 files; it confirmed the single carried High and the three carried
Mediums and otherwise turned up only Low cleanups plus strong positives. The score
holds at 6/10 because it is not build-ready: one production RNG-lifecycle bug (High) is
a genuine determinism/release blocker, and two player-facing input Mediums leave
Settings out of sync with shipped controls. Landing H1 + the two input Mediums would
move this to ~8/10 — the substrate quality is high.

## 1. Snapshot

| | |
|---|---|
| Branch / head | `v0.3.0-features` @ `77895ea` (docs-only past the reviewed head) |
| Reviewed boundary | base `ab81a21` (v0.2.8 exe source) → head `b7bcfd2` (pre-build v0.3.0 snapshot) |
| Working tree before this note | clean |
| Delta size | ~8,326 insertions / ~575 deletions across 38 production `.gd` files |
| Files covered | **38 / 38** (see §5 coverage assertion) |
| `check_docs.py` | PASS, 26/26 |
| `check_rng_usage.sh` | PASS — no unmarked engine-RNG use in non-test GDScript |
| Full suite / scenes / analyzer | not re-run this pass (document-only; no code edits since the head that last passed them) |
| Cadence | one pass per invocation; `_TRACKER.md` is the resume anchor |

## 2. Findings roll-up (by severity)

### High (1) — release blocker

**H1 — Fresh maps never call `RngService.start_map()`; production RNG runs unseeded.**
`scripts/core/GameMap.gd:114-127` (fix site) · `scripts/autoloads/RngService.gd:21`
(never called in production) · root confirmed in Pass 2 (`02_determinism.md` H1) and
Pass 5 (`05_map_turn_core.md` H1).

On the fresh (`not is_resuming`) branch, `GameMap._ready()` takes the Retry snapshot
(`:115`) and starts the turn manager (`:127`) but nothing calls `RngService.start_map()`
— `TurnManager.start_map` is a different method and does not call it either. Consequences:
(1) **zero cross-session entropy** — `map_seed` stays `0`, so identical committed inputs
draw byte-identical dice run-to-run; (2) **`history_hash` bleeds between maps** in a
session — map N's chain carries into map N+1; (3) **Retry snapshots the stale chain**.
Suspend/resume are unaffected (the resume branch restores via `RngService.from_save_dict`).

**Root cause / lesson:** classic *tests seed, production forgets* — every RNG suite
(`test_rng_service`, `test_rng_snapshot`, `test_rng_combat_determinism`) calls
`start_map(seed)` manually, so the API looks healthy in isolation while no production
path ever rolls a seed. **Fix:** on the fresh branch only, call
`RngService.start_map()` (via `get_node_or_null("/root/RngService")`, null-guarded for
headless) **before** `take_map_snapshot()` at `GameMap.gd:114-115`; leave the resume
branch alone. Add a regression test asserting `map_seed != 0` after a fresh `GameMap`
bring-up and `history_hash == 0` at the start of a second map in the same session.

### Medium (3)

**M1 — Settings → Input Mode change doesn't refresh the active mode/prompts until the
next input event.** `InputModeManager.gd:53` (private `_refresh_active_input_mode`, no
public re-resolve entry point) + `SettingsScreen.gd:104-113` (the `input_mode` row has
no `"apply"` hook). Pass 3 M1 owns the root (missing public API); Pass 4 M2 owns the
wiring half — **one Medium, not two.** After the player picks a mode, on-screen prompts
keep showing the old mode until an unrelated event nudges the resolver; the control
looks inert. **Fix (preferred, closes reset path too):** have `InputModeManager`
subscribe to a `SettingsManager` "settings changed" signal so any persist re-resolves
the mode. Alternative: add public `InputModeManager.refresh_from_settings()` + a
`SettingsManager` proxy the `"apply"` hook can reach (the hook calls a method **on
SettingsManager**, so it can't invoke an InputModeManager method directly — a fix-shape
wrinkle noted in Pass 4). `reset_section_to_defaults("controls")` must route through the
same path.

**M2 — Rebind UI omits 5 shipped, player-facing actions.** `SettingsScreen.gd:630-643`
(`_KEYBIND_LABELS` lists 12 actions; `more_info`, `peek_range`, `zoom_in`, `zoom_out`,
`zoom_reset` are absent — all grep-confirmed live consumers). Two consequences: the
actions are **unbindable**, and — more important — `_recompute_keybind_conflicts()` only
scans the listed 12, so rebinding a listed action **onto** an omitted action's key (e.g.
`more_info`'s default `F`) produces **no red row and no Apply block** — a silent
double-bind that defeats the staged-apply safety guarantee. **Fix:** add the 5 rows;
stronger fix (matches the `AGENTS.md` open-registry principle) derives the editable set
from the InputMap minus debug/`ui_*` actions with a display-label override map, so a
future action can't silently fall out again.

**M3 — DataManager closed author-facing vocabularies (registry debt).**
`DataManager.gd:13-16, 124` (`_VALID_ROSTER_POLICIES`, `_VALID_ACTIVATION_MODES`,
`_VALID_OBJECTIVE_TYPES` `[TCV-4]`, `_VALID_AI_PROFILES` `[AIP]`, `_VALID_STATS`
`[STM]`). Closed `x in _VALID_*` allow-lists: adding an author objective condition, AI
profile, or stat requires an engine edit — exactly the closed-vocabulary smell
`AGENTS.md` flags. **Scope:** *pre-existing, not introduced by this delta* (the diff
only touched the enemy-placement XOR validation and added `has_weapon`, both correct).
This is design-level debt tracked in the `[TCV-4]`/`[AIP]`/`[STM]` registers; fix
belongs to those register resolutions, not a point patch.

### Low (20) — cleanups, no correctness impact

| # | Pass | Location | Summary |
|---|---|---|---|
| L1 | 1 | `SaveManager.gd:31-35` | `has_continue_save()` dead if/else + needless index disk read on the MainMenu path |
| L2 | 1 | `SaveData.gd:458-467` | dead `_vector_array_from_variant()` |
| L3 | 1 | `SaveData.gd:126-132` | `_normalize_rules()` merges then wholesale-overwrites the same keys (`_merge_missing` is inert) |
| L4 | 1 | `SaveData.gd` vs `SaveCodec.gd` | duplicated JSON coercers (`_as_int`, `_int_dict_from_variant`, `_string_array_from_variant`) |
| L5 | 1 | `SaveData.gd:34-37` | `from_dict()` uses string-path `load()` where `SaveData.new()` would do |
| L6 | 1 | `SaveManager.gd:38-56` | `save_suspend()` non-atomic single-slot write (highest-value hardening in the save subsystem) |
| L7 | 1 | `SaveCodec`/`SaveData` loaders | silent drops in tolerant loaders (informational) |
| L8 | 2 | `CombatResolver.gd:124-126` | stale "not yet wired" comment — `campaign_rules` is live |
| L9 | 2 | 4 files | `_string_array_from_variant` duplicated ×4 (extends L4) |
| L10 | 3 | `SettingsManager`/`InputModeManager` | input-mode vocab + `normalize_input_mode` duplicated (two sources of truth) |
| L11 | 3 | `InputModeManager.gd:53-58` | rebuilds availability Dict + re-queries `OS.has_feature` per input event |
| L12 | 4 | `SettingsScreen.gd:701-718` | `pad_rebind` stored via node-path re-fetch instead of the in-scope local |
| L13 | 4 | `InputDisplay.gd:199` | `more_info_hint_for` hardcodes `"F"` fallback when `more_info` is unbound |
| L14 | 5 | `TurnManager.gd:231-232` | dead `_array_from_variant` |
| L15 | 5 | `GridManager.gd:562-576` | unused overlay `blend` metadata + `overlay_layer_blends()` (speculative abstraction ahead of consumer) |
| L16 | 5 | `MapCursor.gd:1439-1440` | `_pending_item_id` not cleared on promotion/reclass cancel (nit) |
| L17 | 5 | `MapCursor.gd:1499-1519` | keyboard-held zoom now auto-repeats via the shared `_poll_held_zoom` (behavior change; confirm intended) |
| L18 | 6 | `SelectionCursor.gd:705-715` | `configure()` mutates `index` on shrink without emitting `changed` |
| L19 | 6 | `NewGameScreen.gd:124-153` | `_on_start` launches even when `_persist_rules` no-ops on null `campaign_rules` (dead-defensive) |
| L20 | 6 | `UnitDetailsScreen.gd:396`, `AttackPreview.gd:414` | re-clicking the selected entry is now a no-op (nit) |

## 3. Cross-cutting themes (the value of reading all 38 together)

1. **Closed-vocabulary vs open-registry — the recurring architectural smell.** It shows
   up three times: M2 (rebind list is a hand-maintained closed dict that *drifted behind*
   the InputMap), M3 (DataManager `_VALID_*` allow-lists), and L10 (input-mode vocab
   duplicated across two autoloads). Per `AGENTS.md`, author-facing extension points
   should be data the engine reads. M2 is the notable one because the closed list isn't
   just extensibility debt — it opened a **conflict-detection blind spot** (safety), which
   is why it's a Medium. Deriving editable actions from the InputMap and centralizing the
   input-mode vocabulary in one owner would retire two of these at once.

2. **Duplicated JSON/coercion helpers.** L4 (SaveData vs SaveCodec), L9
   (`_string_array_from_variant` ×4), and L10 (input-mode normalizer ×2) are the same
   theme: primitive coercers/vocabularies copied across the save + determinism + input
   seams. `SaveCodec` already holds the static save-layer coercers and is the natural
   shared owner; three-plus copies crosses the code-pillar shared-helper threshold. Pure
   cleanup — behavior is currently consistent, but a future tolerance tweak must be made
   in every copy or they drift.

3. **"Tests seed/stub, production forgets."** H1 is the marquee case and the single most
   important lesson from this scan: a fully unit-tested API (`start_map`) that no
   production path ever calls, kept green because every test seeds manually. The
   regression test proposed in H1 (assert seed/history from a *fresh `GameMap` boot*, not
   a manual `start_map`) is the shape that would have caught it — test the production
   entry point, not just the primitive.

4. **Dead code / speculative abstraction ahead of a consumer.** L2, L14
   (`_array_from_variant` in two files), and L15 (overlay `blend` flag + accessor with no
   consumer) are the same pattern — helpers/metadata added alongside a real feature but
   never wired in. Each reads as if load-bearing to a future maintainer.

## 4. Seams verified CLEAN (no action — recorded so re-reviews don't re-chase them)

- **Determinism substrate is sound.** Roll order is outcome-independent (all
  `hit_rn_count` draws consumed even on a miss); `EnemyAI` commits exactly one RNG event
  per completed action (attack/staff/Wait) so red chains identically to blue;
  `SkillHandler` **loud-fails** on a missing `context["rng"]` instead of falling back to
  raw `randi()`; `_original_tiles` stale-pre-move-tile hazard is explicitly erased
  *after* the record is built. **No raw RNG** in any of the 38 files except the two
  `rng-allow`-annotated `Unit._level_up_random` lines, which draw from the *passed event
  RNG*, not the global.
- **`Unit.level_up()` begin/commit is CORRECT, not an asymmetry bug.** Per the documented
  `RngService` contract, a dice action calls `begin_event`+`commit_event` and a non-dice
  action commits only; `begin_event` is pure, so `growth_fixed` committing without begin
  advances `history_hash` identically. (This was the specific thing Pass 6 set out to
  falsify — it holds.)
- **The Pass-3 arm-on-decode double-move concern resolves CLEAN in Pass 5.** The keyboard/
  d-pad edge arms `_held_dir` synchronously before the same-frame `poll_direction`, so the
  poll sees `dir == _held_dir` and ticks the DELAY timer instead of re-stepping — no
  double-move.
- **Input vocabulary is consistent across three sites.** InputDisplay ↔ InputModeManager
  `MODE_*` ↔ SettingsScreen `_ENUM_SETTINGS` input_mode values match exactly; the staged
  keybind apply never touches the live InputMap until conflicts clear; Esc always aborts
  capture.
- **Save layering + large-int RNG safety.** `SaveData`/`SaveCodec` stay pure `RefCounted`
  with zero I/O; `map_seed`/`history_hash` round-trip as decimal strings to dodge Godot's
  lossy JSON number path; legacy-save migrations are centralized and covered.
- **UI seams.** `CampaignRules` read-migration is uniform + null-guarded across all five
  consumers; `MenuScale` reactive re-center has a sound re-entrancy guard replacing four
  per-trigger bakes; the `ModalScreen` focus seam is a clean virtual-override design; the
  `GridManager` overlay-precedence registry is a proper open registry.

## 5. Coverage assertion — 38 / 38

Every production `.gd` file in the `ab81a21..b7bcfd2` delta (per
`git diff --stat ab81a21 b7bcfd2 -- 'scripts/**/*.gd'`, excluding `scripts/tests/`) was
read at head `b7bcfd2` and reviewed against `01_Code_Pillar.md`, with no overlaps:

| Pass | Subsystem | Files |
|---|---|---:|
| 1 | Save/persistence codec | 3 |
| 2 | Determinism: state + RNG + combat | 7 |
| 3 | Input model & settings persistence | 3 |
| 4 | Input display & rebind UI | 2 |
| 5 | Map/turn core | 5 |
| 6 | UI screens, selection & misc data | 18 |
| **Total** | | **38** |

The full file→pass map is in `00_scope.md §"File → pass map (all 38, no overlaps)"`.

## 6. Recommended landing order (fixes are a later, separate effort)

1. **H1** — seed RNG on the fresh `GameMap` branch + regression test. Release blocker;
   one localized site.
2. **M1** — input-mode refresh (prefer the SettingsManager settings-changed signal so the
   reset path is covered for free).
3. **M2** — add the 5 missing rebind rows (or derive the editable set from the InputMap);
   closes the conflict blind spot.
4. **M3** — track under the `[TCV-4]`/`[AIP]`/`[STM]` register resolutions, not a point
   patch. Not a v0.3.0 blocker.
5. **Lows** — opportunistic; L1 (dead menu-path read) and L6 (atomic suspend write) are
   the two worth doing before the build; the duplication Lows (L4/L9/L10) are best done as
   one consolidation.

Once H1, M1, and M2 land, re-run the full suite + scene integrity + analyzer (not just
docs/RNG, since those are code edits) before cutting the v0.3.0 build.
