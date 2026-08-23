---
Role: dated
---

# Pass 6 — UI screens, selection & misc data (18 files)

**Boundary:** `ab81a21` (base) → `b7bcfd2` (head). Working tree == head for these
files (HEAD `47068a7` is docs-only past `b7bcfd2`).
**Procedure:** `AGENT/Review Procedures/01_Code_Pillar.md`.
**Verdict:** **1 Medium (carried, re-CONFIRMED) + 3 Low (1 nit). No new correctness
bugs.** This delta is overwhelmingly a clean mechanical set: the `CampaignRules`
consolidation read-migration, the shared `SelectionCursor` adoption, the MenuScale
reactive re-center, and the Continue/suspend lifecycle.

## Files read (at `b7bcfd2`)

Full diffs for all 18; full current-context reads of the new/refactored cores
(`SelectionCursor.gd`, `ModalScreen.gd` seam, `UnitDetailsScreen.gd`,
`AttackPreview.gd`, `HUD.gd` terrain pager, `MenuScale._recenter`). Cross-read
`RngService.gd` (event API contract), `SaveCodec.gd:219` (`has_weapon` consumer),
`NewGameScreen._on_start`. Suites sampled: `test_selection_cursor` (advance/wrap/
reverse/has_inactive/move_2d grid/sparse positions/quiet advance(0)),
`test_data_manager`, `test_attack_preview_selector`, `test_unit_details_screen`.

- `scripts/ui/` (12): SelectionCursor, ModalScreen, UnitDetailsScreen, AttackPreview,
  HUD, LevelUpScreen, MenuScale, MainMenu, MapMenu, NewGameScreen, GameOverScreen,
  ActionMenu.
- `scripts/autoloads/` (2): DataManager, PairUpRegistry.
- `scripts/resources/MapData.gd`, `scripts/units/Unit.gd`,
  `scripts/tools/generate_placeholder_assets.gd`, `scripts/tools/generate_tilesets.gd`.

---

## M1 (carried Medium, re-CONFIRMED) — DataManager closed author-facing vocabularies

`scripts/autoloads/DataManager.gd:13-16, 124`

```
const _VALID_ROSTER_POLICIES  := ["default_roster", "fixed_test_roster", "keep_current_roster"]
const _VALID_ACTIVATION_MODES := ["WHOLE_PHASE", "ALTERNATING"]
const _VALID_OBJECTIVE_TYPES  := ["rout", "defeat_boss", "seize", "escape", "survive", "protect", "turn_limit"]
const _VALID_AI_PROFILES      := ["basic", "passive", "healer"]
const _VALID_STATS: Array[String] := ["strength", "magic", ...]
```

**Problem:** these are closed allow-lists validated with `x in _VALID_*`. Adding an
author objective condition, AI profile, or stat requires an engine edit here —
exactly the closed-vocabulary smell AGENTS.md flags (objective conditions `[TCV-4]`,
AI profiles `[AIP]`, stat model `[STM]`). The ratified direction is a data-driven
open registry the engine reads, not a hardcoded list.

**Why it matters:** author-extensibility (`[EXT]`) — content that should be data
can't be added without touching GDScript.

**Scope note:** pre-existing; **not introduced by this `ab81a21..b7bcfd2` delta**
(the diff only touched the enemy-placement XOR validation and added `has_weapon`,
both correct — see Positives). This is design-level registry debt tracked in the
`[TCV-4]`/`[AIP]`/`[STM]` registers; re-confirmed here as the carried Pass-6 Medium.
Fix belongs to those register resolutions, not a point patch in this pass.

## L1 — `SelectionCursor.configure()` mutates `index` without emitting `changed`

`scripts/ui/SelectionCursor.gd:705-715`

`configure()` on a shrink (`index >= _count`) or invalid-inactive case assigns
`index = -1` directly rather than via `_set_index()`, so no `changed` signal fires.
A consumer that mirrors `index` into a plain field (`_current_index`,
`_terrain_more_page`) and relies on the signal to re-render could desync.

**Benign today:** all three consumers re-establish state right after configure —
AttackPreview `configure()` → `reset()` → `_reset_info_panel()`; UnitDetailsScreen
`reset()` precedes `configure_positions()` (index already -1); HUD configures once in
`_ready()` with a fixed count of 2. Recommend a comment on `configure()` that it is a
silent setup call (callers must `reset()`/re-render), or route the shrink through
`_set_index()`.

## L2 — `NewGameScreen._on_start` launches even when `_persist_rules` no-ops

`scripts/ui/NewGameScreen.gd:124-134, 143-153`

`_persist_rules()` `push_error`s and returns without applying any selection when
`GameState.campaign_rules` is null; `_on_start()` ignores that and proceeds to
`configure_next_map` + `change_scene_to_file`. The player's permadeath / pair-up /
leveling choices would be silently dropped and the map would start on defaults.

**Effectively dead-defensive:** the B1-CST consolidation has GameState always init a
fresh `CampaignRules`, so `campaign_rules` is never null in production. Also note the
asymmetry — `open()` (`:99`) silently skips on null, `_persist_rules()` errors. If the
guard is meant to be real, `_on_start` should abort on persist failure; otherwise both
sites should treat null the same way.

## L3 (nit) — clicking the already-selected entry is now a no-op

`scripts/ui/UnitDetailsScreen.gd:396-399`, `scripts/ui/AttackPreview.gd:414-419`

`_on_entry_clicked` now calls `_selector.set_index(i)`, and `_set_index` early-returns
without emitting when `index == value`. So re-clicking the currently-shown entry no
longer re-runs `_show_entry` (previously it did). Idempotent re-show is harmless;
noted only for behavior-delta completeness.

---

## Positives (verified clean)

1. **Determinism — `Unit.level_up()` RNG event is CORRECT** (`Unit.gd:826-853`,
   `1116-1136`). It matches the documented `RngService` contract
   (`RngService.gd:27-46`): a **dice** action calls `begin_event` + `commit_event`; a
   **non-dice** action calls **commit only**. `growth_random` takes begin+commit;
   `growth_fixed` commits only. `begin_event` is **pure** (reads `map_seed`/
   `history_hash`, returns a seeded RNG, mutates nothing), so `growth_fixed` skipping
   it is intended — `history_hash` advances identically across both methods for the
   same action, exactly as the code comment claims. **Not a begin/commit-asymmetry
   bug.**
2. **No raw RNG** in any of the 18 files except the two `rng-allow`-annotated lines in
   `_level_up_random` (`Unit.gd:1127, 1134`) — the headless fallback when RngService
   is absent, and it draws from the **passed event RNG instance** (`rng.randi_range`),
   not the global. RNG guard green.
3. **CampaignRules read-migration is consistent** across all five consumers
   (ActionMenu, NewGameScreen, PairUpRegistry, Unit ×4 sites, plus doc-only MapData):
   uniform `gs.get("campaign_rules") as CampaignRules` with a null guard falling back
   to the same defaults the loose fields used. Aligns with Pass 2 (B1-CST).
4. **MenuScale reactive re-center** (`MenuScale.gd:221-278`): the `resized`-driven
   re-center replaces four per-trigger deferred bakes; the re-entrancy guard
   (`_RECENTER_GUARD_META`) makes the size-write's nested `resized` a no-op, and the
   hook is connected once per target (`_RESIZE_HOOKED_META`). Sound V028-03 root-cause
   fix.
5. **ModalScreen focus seam** (`ModalScreen.gd:27-110`) is a clean virtual-override
   design: `_focus_default`/`_refresh_input_prompts` virtuals, gamepad→grab /
   touch→release / mouse_keyboard→untouched policy, `is_ancestor_of` scoping so a
   switch never yanks focus off an unrelated surface. UnitDetailsScreen overrides both
   virtuals to drive its selector instead of raw GUI focus.
6. **DataManager enemy-placement XOR validation** (`:408-450`) is correct — errors
   when a placement provides both or neither of `unit_data_path` / `unit_data`,
   validates each source, dedups by `unit_id`. `has_weapon` (`:617`) has a real
   consumer (`SaveCodec.gd:219` weapon-id drop-guard).
7. **SelectionCursor** has real, targeted coverage (`test_selection_cursor.gd`):
   inactive-start wrap, reverse-from-inactive, `has_inactive` cycle, 2-col `move_2d`
   grid walk, sparse `configure_positions`, and quiet `advance(0)`.
8. **GameOverScreen suspend delete** (`:139-153`) is idempotent
   (`_suspend_deleted_for_result` guard) and fires at result presentation — a resolved
   map can't be suspended, so deleting the suspend save is correct.

## Test / verification

- RNG guard: green (only annotated fallback).
- Suites cross-read confirm the selector, data-manager, and unit-details behaviors
  above; no coverage gap that masks a real bug in this delta.
