# GDD_10a — Consolidated Roadmap Overview

**Companion to `GDD_10_Roadmap.md` — kept short on purpose.**
This file is the at-a-glance map: every planned feature and deferred fix in
**recommended completion order**, with dependency notes. The canonical
specifications live in `GDD_10_Roadmap.md` and the dated playtest / code-review
docs — this file links into them.

> **Authority.** If this file and `GDD_10_Roadmap.md` disagree, `GDD_10_Roadmap.md`
> wins on milestone *content*; this file wins on *ordering*. Update the order
> here when Decision 10 (or its successor) is revised.

Last refreshed: **2026-05-21** against branch `main` @ `8ea7429` (B1–B10 + C1 + C2 + C3 done).

---

## 1. Done (recent, for reference only — no action)

| Source | Items | Verified |
|---|---|---|
| Manual test (Playtest 1) | All 13 findings | `AGENT/Docs/manual_test_findings_analysis.md` header (✅) |
| Playtest 2 — 17 fixes | #1 unit details, #2 auto-end-turn, #3 prev-unit display, #4 New Game dimmer, #5 HUD mouse_filter, #6 heal overlay orange, #7 AI camera pan, #8 weapon swap, #9 cursor returns to actor on cancel, #10/#11 debug aids gated, #12 cursor freeze on level-up, #13/#14 prompt key + Vulnerary value, #15/#16 end-turn focus, #17 camera buffer setting | `AGENT/Session Notes/2026-05-19.md`, all commits one-per-fix on `main` |
| Playtest 3 — bug list | #1 HPBar mouse-eater, #2 mouse dismiss level-up, #3 staff range overlay, #4 menu viewport clamp, #5 camera recentre on phase change, #6 HUD follows cursor, #7 mouse-pan feedback loop, #21 ActionMenu shrink | commits `334a724 … 5b1a87c` |
| Code review 2026-05-18 | GDD_01 resync (D1–D5, D7–D11), `InventoryEntry.validate()` wired in `GameMap._spawn_units`, `Unit.has_skill()` unions `mastery_skills`, `combat_animations` hidden in `SettingsScreen` | grep verified 2026-05-20 |
| Code review 2026-05-19 | Clamp `camera_edge_buffer` on load, scale AI pacing delay with `movement_speed`, AI camera re-pan after movement | commits `d430384`, `fa27b2c` |
| Code review 2026-05-19c | 4 DEBUG-banner nits (2.1–2.4) | commit `958995b` |
| Playtest 4 — #1 | Mouse-bump no longer moves the cursor in keyboard-only mode: setting renamed `mouse_targeting`→`mouse_cursor` (values `enabled`/`disabled`), gate applied to motion in all three states (`FREE`/`UNIT_SELECTED`/`TARGETING`); legacy cfg key migrates | commit `bad9f24`; `test_map_cursor` "mouse_cursor=disabled ignores motion" |
| Playtest 4 — #2 | Camera now returns to the player's end-of-turn view: `MapCursor._on_phase_changed` saves `_camera.position` on `PLAYER → ENEMY` and restores it on `ENEMY → PLAYER`. PT3 #5 safety net (`_scroll_camera_if_needed`) still runs after the restore so a cursor outside the resulting view is panned in. | this commit; `test_map_cursor` "ENEMY saves camera, PLAYER restores it (PT4 #2)" |
| B7 | `NewGameScreen._on_start`: `push_error + return` when GameState absent (scene change was unconditional — would drop the player's choices) | commit `f92899d` |
| B8 | Comment sweep: `UnitData.tile_position` + `mastery_skills` now say "captured by GameState's manual snapshot (not ResourceSaver; not @export)"; `TurnManager._apply_fort_healing` "fort/throne" → "fort". HUD magic `0`, test comment, and `_grid == null` guard items already addressed in earlier sessions. | commit `f92899d` |
| B9 | Singleton-mutating tests already restore unconditionally before the assertion block (satisfies the "restore before next block" option from code_review_2026-05-19 §2). No code change needed. | verified 2026-05-20 |
| B1 | `GridManager.get_terrain_bonuses(tile) → {def, dodge}` accessor; `HUD._update_terrain` + `Unit.get_terrain_*_bonus` route through it. Decouples UI/unit layer from `TERRAIN_*_BONUS` dict names (rename safety). | commit `89f370f` |
| B2 | `EventBus.combat_started` moved to the top of `resolve_combat` (before RNG); was firing at the top of `apply_combat_result` — i.e. after the dice were rolled. `preview_combat` stays silent. Signal name now matches contract; prep for M8 `condition_applied/removed` siblings. | commit `b87d1bb` |
| B3 | `scripts/ui/ModalScreen.gd` base extracted; `SettingsScreen`, `NewGameScreen`, `UnitDetailsScreen` migrated (`hide` in `_ready` + `_unhandled_input` cancel + `closed` signal live in the base). `LevelUpScreen` deliberately out of scope (no Dimmer; cursor-lock via `EventBus.level_up_started/finished`). | commit `ecfecf9` |
| B4 | `scripts/core/CameraController.gd` extracted (RefCounted slice). Sole production writer of `Camera2D.position`. `GameMap` builds and injects via `MapCursor.setup()` (new 4th param); PT4 #2 save/restore state now lives on the controller. `MapCursor._scroll_camera_if_needed` / `_clamp_tile_to_view` are one-line delegations. | commit `d231e0f` |
| B5 | Data-driven `_ENUM_SETTINGS` schema in `SettingsScreen` for the six OptionButton-style settings; one generic handler via `bind()`. Six per-setting handlers + four parallel `_*_OPTIONS` const lists removed (net −49 lines). Sliders + read-only keybindings stay hand-wired (don't fit the OptionButton template). | commit `b4050fd` |
| B6 | `DataManager._validate_cross_references` extended to weapon `effect_tags`, weapon/skill `weapon_type`, item `effect_id`. Canonical lists owned by their producers (`GameConstants.VALID_EFFECT_TAGS`/`VALID_WEAPON_TYPES`, `ItemHandler.IMPLEMENTED_EFFECT_IDS`). Refactored to pure `collect_validation_errors` core + `_ready` loop for testability. | commit `9d7f2a4` |
| C1 stage 1 | Faction-relative refactor (behaviour-neutral): `Unit.team` data rename `player→blue` / `enemy→red`; `controlling_faction` threaded through `MapCursor.setup` + slices with a `set_controlling_faction` setter for stage 5; `CombatResolver.is_player_initiated` → `attacker_faction: String`. 50+ test string literals flipped via sed. | commit `20ef18e`; suite 426 green |
| C1 stage 2 | Alliance-group hostility model on `GameState` (`are_hostile(a, b)` + `get_alliance_group(id)`; defaults `{blue,green}/{red}/{yellow}`). Routes `GridManager` is_passable / dijkstra / get_attackable / get_healable + `MapCursorTargeting` attack/heal gates through it. New `GridManager._hostile` / `MapCursorTargeting._is_target_hostile` chokepoints with headless fallback to the strict same-team binary. | commit `c5c9c32`; +2 test_game_state cases |
| C1 stage 3 | N-faction data + activation scheduler: new `FactionData` Resource (id, color, alliance_group, controller); `MapData` adds `factions` / `turn_order` / `activation_mode`; `GameState._units_by_faction` + `get_living_units_of()` (legacy `get_living_player/enemy_units` kept as wrappers); `TurnManager` rebuilt with `_turn_order` + `_active_faction_idx` + `_activation_mode`, mode-aware `_begin_phase` (Decision 9), `_advance_faction` (skips empties per Decision 2), new `end_alternating_activation` primitive. WHOLE_PHASE = today's behaviour; ALTERNATING tested via primitive. | commit `0c68254`; +8 test cases across test_game_state + test_turn_manager |
| C2 stage 1 | `ObjectiveCondition` Resource + per-group `MapData.victory_conditions` / `defeat_conditions` dictionaries keyed by alliance group (Decision 8 / 2026-05-17). Single typed resource with type + per-type fields (faction_id, unit_ids, tiles, allowed_unit_ids, turns). Behaviour-neutral schema-only — evaluator still reads the legacy `objective_type`. | commit `316e509`; +3 test_data_layer |
| C2 stage 2 | Generic per-group evaluator. `check_victory_conditions` rewritten: per-group condition lists (legacy translated to implicit blue-group conditions); per-group AND-victory / OR-defeat; implicit "group routed" default; ≤1-group-standing → last wins; 0 → draw → map_defeat. New `_group_eliminated_round` dict + `get_group_eliminated_round()` accessor for stage 4 standings. Internal `_group_routed` sentinel keeps `rout` semantics clean. | commit `badeec6`; +5 test_turn_manager |
| C2 stage 3 | defeat_boss / seize / escape / survive condition evaluators. `_seize_records` + `_escape_records` runtime tracking. Public APIs `record_seize(unit)`, `record_escape(unit)`, `can_seize(unit, tile)`. ActionMenu `BtnSeize` button gated by `can_seize`; MapCursor handles `"seize"` action_chosen → records + finishes. Auto-escape on unit_moved into a zone. Escape-aware protect (escapees count as alive) + escape-aware group_routed (groups with any escapee aren't "wiped"). | commit `bd2d12e`; +3 test_action_menu, +7 test_turn_manager |
| C2 stage 4 | Ranked-standings results screen + HUD objective readout. New `EventBus.map_resolved(winner_group, standings)` signal emitted alongside map_victory / map_defeat; `_build_standings` orders losers by elim-round DESC (stable). `GameOverScreen` renders standings; `HUD` has an ObjectivePanel listing blue's Win/Lose conditions from `ObjectiveCondition.get_display_text()`. | commit `8fed076`; +2 test_turn_manager, +1 test_data_layer, +2 test_hud |
| C2 stage 5 | Decision 7 phase-boundary sweep on `start_enemy_phase` + `_map_over` chokepoint in `EnemyAI.run_enemy_phase` (bails between units when map is over). Legacy `objective_type` / `turn_limit` / `required_survivor_ids` / `objective_params` fields deleted from MapData; `_apply_legacy_conditions` / `_has_legacy_blue_conditions` deleted from TurnManager; HUD legacy translation deleted. `map_001_data.tres` migrated to `victory_conditions = {"allies": [rout()]}`. All legacy-field tests converted to authored conditions. | this commit; +1 test_turn_manager (phase-boundary sweep) |
| C3 | M14 stages 4–5 completed: faction-driven AI loop (`run_ai_phase(faction)`), sequential non-blue AI dispatch in `TurnManager`, green/yellow spawn support via per-placement `faction` tags, faction-aware `PhaseBanner` + HUD labels from `FactionData`, authored faction color application on unit sprites, deterministic TurnManager AI-loop seam/tests, and C3 content resource `map_001_c3_factions_data.tres`. | commits `cca788d`, `bf0d9b1`, `8ea7429`; suite green (`test_enemy_ai` 20, `test_turn_manager` 47, `test_hud` 12, `test_unit_stats` 32) |

---

## 2. Recommended completion order

Numbering is the work order. Status: ⬜ = pending, 🟦 = in flight, ⚫ = deferred.

### Bucket A — Open playtest bugs (do first; small)

| # | Item | Source | Notes |
|---|---|---|---|
| A1 ✅ | ~~PT4 #1 — mouse-bump moves cursor in keyboard-only mode~~ | — | Shipped 2026-05-20; see §1 row. |
| A2 ✅ | ~~PT4 #2 — Camera doesn't return to player's end-of-turn view~~ | — | Shipped 2026-05-20; see §1 row. Bucket A is now empty. |

### Bucket B — Tech-debt prep work (slot before the milestones that need it)

These are code-review followups whose natural slot is **before** a specific upcoming milestone. Doing them out of order doesn't break anything; doing them late means refactoring around new code.

| # | Item | Why slot here | Source |
|---|---|---|---|
| B1 ✅ | ~~`GridManager.get_terrain_bonuses(tile) → {def, dodge}` accessor; route `HUD.gd:152` + `Unit.gd:168` through it~~ | — | Shipped 2026-05-20; commit `89f370f` |
| B2 ✅ | ~~Rename / re-time `combat_started` (currently emits *after* `resolve_combat`) — either move emit to top of `resolve_combat` or rename to `combat_applying`; document the chosen contract on the signal~~ | — | Shipped 2026-05-20; commit `b87d1bb` (moved emit to top of `resolve_combat`) |
| B3 ✅ | ~~Extract a **`ModalScreen` base** (Dimmer + open/close + cursor lock) — `SettingsScreen`, `NewGameScreen`, `LevelUpScreen`, `UnitDetailsScreen` all hand-roll modality~~ | — | Shipped 2026-05-20; commit `ecfecf9`. `LevelUpScreen` deliberately out of scope (no Dimmer). |
| B4 ✅ | ~~Extract a **`CameraController`** (autoload or `GameMap`-owned node) — `MapCursor._scroll_camera_if_needed`, `GameMap._on_ai_unit_acting`, and `GameMap`'s initial placement all write `Camera2D.position` directly~~ | — | Shipped 2026-05-20; commit `d231e0f`. RefCounted slice owned by `GameMap`, injected into `MapCursor.setup()`. |
| B5 ✅ | ~~Data-driven **Settings schema** — `SettingsManager` field + `SettingsScreen` row + `_on_*_changed` triplet per setting is growing linearly; replace with a registry~~ | — | Shipped 2026-05-20; commit `b4050fd`. Schema covers the six OptionButton-style settings; sliders + keybindings stay hand-wired by design. |
| B6 ✅ | ~~Extend `DataManager._validate_cross_references` to weapon `effect_tags`, weapon/skill `weapon_type`, item `effect_id`~~ | — | Shipped 2026-05-20; commit `9d7f2a4`. Canonical lists owned by their producers (GameConstants, ItemHandler). |
| B7 ✅ | ~~`NewGameScreen._on_start` — guard scene change if `GameState` autoload missing~~ | — | Shipped 2026-05-20; commit `f92899d` |
| B8 ✅ | ~~Carry-over Lows: UnitData comment wording; TurnManager "fort/throne"~~ | — | Shipped 2026-05-20; commit `f92899d`. HUD magic `0`, test comment, `_grid==null` guard items verified already done. |
| B9 ✅ | ~~Tighten singleton-mutating tests~~ | — | Verified 2026-05-20: all three test files already restore unconditionally before assertions. No code change needed. |
| B10 ⬜ | **Review and integrate `revised_classes_and_skills.md`.** A new 2567-line classes + skills reference (Awakening flavoured — base + promoted classes, stat caps, growth rates, skill descriptions for ~225 sections) landed in `AGENT/GDD/Content Expansion/`. Sits alongside the existing `classes.md`, `skills.md`, `awakening_classes_supplement.md`, `awakening_skills_supplement.md` — the word "revised" implies a supersession but is not declared. **Open question:** which existing docs does this replace vs. extend, and what does it imply for M9 (skill `effect_id`s), M11 (content expansion .tres authoring) and M13 (Awakening supplement)? Reconcile before M9 starts so the .tres data is authored against one source of truth, not four overlapping ones. | Do **before C5 (M9)**: M9 stamps `effect_id`s and `.tres` data into the codebase; doing so against a yet-to-be-reconciled spec is a guaranteed re-author. | `AGENT/GDD/Content Expansion/revised_classes_and_skills.md`; sibling docs in the same folder |

### Bucket C — Phase 2 milestones (Decision 10 order)

> Implementation order per `AGENT/Docs/design_decisions_log_2026-05-17.md` Decision 10:
> **M14 stages 1–3 → M16 → M14 stages 4–5 (+content) → M8 → M9 → M10 → M11 → M12 → M13**.
> M15 Part A (hotseat) slots anywhere after M14 stage 5.
> M14 green/yellow content + Maps 002–005 ride after M16.

| # | Milestone | Goal (1-liner) | Depends on | Source |
|---|---|---|---|---|
| C1 ✅ | ~~**M14 stages 1–3**~~ | ~~Replace hardcoded `"player"` with faction-relative concepts; alliance-group hostility helper; faction-as-data + activation-scheduler `TurnManager` (`WHOLE_PHASE`/`ALTERNATING`). **Behaviour-neutral.**~~ | — | Shipped 2026-05-20; commits `20ef18e` / `c5c9c32` / `0c68254`. See §1 + Session Notes 2026-05-20. Small stage-3 follow-ups (cursor branching on activation_mode, AI-faction dispatch from start_map non-blue path) fold into C3. |
| C2 ✅ | ~~**M16 — Objective System**~~ | ~~Replace single `objective_type` with multi-condition victory/defeat per faction (Rout, Seize, Boss, Escape, Survive, Defend, Survivor-survives, …).~~ | — | Shipped 2026-05-20 across 5 stages; see §1 + Session Notes 2026-05-20. Decision 7 phase-boundary sweep + `_map_over` chokepoint live; legacy MapData fields removed. |
| C3 ✅ | ~~**M14 stages 4–5 (+content)**~~ | ~~Faction-agnostic AI (`run_ai_phase(faction)`); green/yellow spawns + per-unit faction tags in `MapData`; `PhaseBanner` reads from faction data.~~ | C1, C2 (stage 4 AI reads M16 objective data) | Shipped 2026-05-21; commits `cca788d`, `bf0d9b1`, `8ea7429`. See §1 row and Session Notes 2026-05-21. |
| C4 ⬜ | **M8 — Status Conditions** | Full `ConditionManager` (Poison/Sleep/Silence/Berserk/Stun); ticking at start of holder's **activation**; hooks in `TurnManager` / `CombatResolver` / `ActionMenu` / `EnemyAI` / `SkillHandler`; Restore staff + Panacea. | C3 (tick point is "start of activation" — well-defined in either activation mode); B2, B3 recommended | `GDD_10_Roadmap.md` § Milestone 8 |
| C5 ⬜ | **M9 — Skill Content** | Implement all deferred `effect_id` handlers (stat bonuses, auras, on-hit/on-attack triggers, healer skills, terrain skills, weapon-skill triggers, special masteries). Mostly content on the existing modifier/trigger pipeline. | C4; B6 recommended | `GDD_10_Roadmap.md` § Milestone 9 |
| C6 ⬜ | **M10 — Extra-Turn System** | Canto, Special Dance, Galeforce, Pavise/Aegis double-act and similar. Each grants an extra **activation**. | C5; **M14 stages 1–5** (extra turn = extra activation) | `GDD_10_Roadmap.md` § Milestone 10 |
| C7 ⬜ | **M11 — Content Expansion** | All remaining classes / weapons / skills / items from the base handbook + Awakening supplement. | C6; B5 recommended | `GDD_10_Roadmap.md` § Milestone 11 |
| C8 ⚫ | **M12 — Laguz System** `[DEFERRED]` | Shift gauge, Beast/Bird/Dragon tribes, transformed forms, brand items. Data fields already on `UnitData`/`ClassData`. | C7 | `GDD_10_Roadmap.md` § Milestone 12 |
| C9 ⚫ | **M13 — Awakening Supplement** `[DEFERRED]` | Awakening classes (Lord/Bride/Dread Fighter/Manakete/etc), Pair-Up *data only* (logic explicitly out of scope), Awakening-only skills not covered in M9. | C8 | `GDD_10_Roadmap.md` § Milestone 13 |
| C10 ⬜ | **M15 Part A — Hotseat** | Any non-blue faction can be human-controlled. Local-only. May slot **anywhere after C3**. | C3 | `GDD_10_Roadmap.md` § Milestone 15 |
| C11 ⚫ | **M15 Part B — Remote Control** `[DEFERRED]` | Network-driven faction controller. Online design ratified 2026-05-17; build deferred. | C10 + Phase-3 mid-battle suspend save (Decision 10 / D14) | `GDD_10_Roadmap.md` § Milestone 15 |

### Bucket D — Cross-cutting obligation (release-gate, not order-gated)

| # | Item | When | Source |
|---|---|---|---|
| D1 ⚠️ | **Pre-Release Cleanup** — delete the playtest-2 debug testing aids (`debug_force_levelup`, `debug_growth_boost`) **and** the DEBUG MODE HUD banner (5-file ecosystem) | Before **any** non-debug build ships. RELEASE BLOCKER. | `GDD_10_Roadmap.md` § Pre-Release Cleanup (has per-file grep anchors) |

### Bucket E — Phase 3 Backlog (post-M13; not yet milestoned)

Grouped exactly as in `GDD_10_Roadmap.md` § Phase 3 Backlog. No internal ordering yet — pick from the bucket your post-M13 stack benefits from.

- **Content** — remaining handbook classes; forging UI + shop; promotion UI for 3+-path classes.
- **Systems** — between-map save/load; mid-battle suspend save (pull forward with M15 Part B); fog of war + LoS; rescue and carry; additional AI profiles (territorial/guard_tile/healer/boss); stationary weapon use; door/chest/key; pre-battle deployment screen; enforce `GameState.max_skills` / `max_inventory`.
- **Maps** — Maps 002–005 (Seize, Boss Defeat, Escape, Survive/Defend) authored against M16.
- **Polish** — real sprites/tilesets/UI art; combat animations (then re-enable `SettingsManager.combat_animations`); skill activation FX; music + SFX; story + dialogue; release packaging (Steam / itch.io / GitHub).
- **UI / UX & Settings** (merged from playtests 2 & 3 "later milestones"): range-on-hover overlay, movement path arrows, individual unit threat range, grid visibility slider, camera settings, UI scale + reposition, display resolution options, key rebinding UI, full character sheet, "More info" inspection mode, gamepad/touch support, attack-by-target selection, richer combat prediction (crit + WT + effective), prediction layout, minimap toggle.

---

## 3. Dependency graph (key edges only)

```
 C1 (M14 s1-3) ──▶ C2 (M16) ──▶ C3 (M14 s4-5) ──▶ C4 (M8) ──▶ C5 (M9) ──▶ C6 (M10) ──▶ C7 (M11) ──▶ C8 (M12) ──▶ C9 (M13)
                                       │
                                       └──▶ C10 (M15 Part A)  ──▶ C11 (M15 Part B, deferred)

 B10 (content-doc reconciliation) ──▶ C5, C7 (M9, M11)

 D1 (Pre-Release Cleanup) — gate at release time, not in milestone order
```

(Bucket A is empty; Bucket B prereqs B1–B9 have shipped — only B10 remains. See §1 for the done list.)

---

## 4. Source documents

Update this index when adding new findings docs.

- **Roadmap (canonical):** `AGENT/GDD/GDD_10_Roadmap.md`
- **Design decisions:** `AGENT/Docs/design_decisions_log_2026-05-17.md` (Decision 10 = the ordering rule)
- **GDD assumptions:** `AGENT/GDD/GDD_Assumptions.md`
- **Manual / editor tasks:** `AGENT/GDD/GDD_Manual_Tasks.md` (Pending = **none**)
- **Playtests:**
  - 1 (`playtest1_findings_2026-05-18.md`) — fully analysed in `manual_test_findings_analysis.md`, all done
  - 2 (`playtest2_findings_2026-05-19.md` + `playtest2_fix_plan_2026-05-19.md`) — all done
  - 3 (`playtest3_findings_2026-05-19.md`) — bugs #1–7 + #21 done; "later milestones" merged into `GDD_10_Roadmap.md` § UI/UX & Settings
  - 4 (`playtest4_findings_2026-05-19.md`) — bugs **A1, A2** above
- **Code reviews (most recent first):**
  - 2026-05-19c (`AGENT/Code Reviews/code_review_2026-05-19c.md`) — DEBUG-banner; 4 nits, all done
  - 2026-05-19b (`code_review_2026-05-19b.md`) — playtest 3 diagnosis; all bugs done
  - 2026-05-19 (`code_review_2026-05-19.md`) — playtest-2-fixes review; top 4 done; remainder = **B9** + architectural backlog (B3/B4/B5)
  - 2026-05-18 (`code_review_2026-05-18.md`) — full-codebase review + documentation audit; most done; remainder = **B1, B2, B6, B7, B8**

---

## 5. How to keep this file accurate

1. When a Bucket-A or Bucket-B item ships, move it under §1 (Done) with the commit hash and delete its row from Bucket A/B.
2. When a milestone in Bucket C completes, mark ⬜→✅ and add a one-liner in §1 referencing the session note.
3. When a new playtest lands, add a new row to §4, then triage its items into Bucket A (bugs) or Bucket E (later milestones) **on the same day** so this file doesn't drift.
4. When Decision 10 (or its successor) is revised, update the order in Bucket C and the dependency graph in §3 in the same commit as the decision log change.
