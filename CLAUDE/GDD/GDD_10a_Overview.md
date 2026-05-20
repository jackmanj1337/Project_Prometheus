# GDD_10a — Consolidated Roadmap Overview

**Companion to `GDD_10_Roadmap.md` — kept short on purpose.**
This file is the at-a-glance map: every planned feature and deferred fix in
**recommended completion order**, with dependency notes. The canonical
specifications live in `GDD_10_Roadmap.md` and the dated playtest / code-review
docs — this file links into them.

> **Authority.** If this file and `GDD_10_Roadmap.md` disagree, `GDD_10_Roadmap.md`
> wins on milestone *content*; this file wins on *ordering*. Update the order
> here when Decision 10 (or its successor) is revised.

Last refreshed: **2026-05-20** against branch `main` @ `f92899d` (B1–B9 done).

---

## 1. Done (recent, for reference only — no action)

| Source | Items | Verified |
|---|---|---|
| Manual test (Playtest 1) | All 13 findings | `CLAUDE/Docs/manual_test_findings_analysis.md` header (✅) |
| Playtest 2 — 17 fixes | #1 unit details, #2 auto-end-turn, #3 prev-unit display, #4 New Game dimmer, #5 HUD mouse_filter, #6 heal overlay orange, #7 AI camera pan, #8 weapon swap, #9 cursor returns to actor on cancel, #10/#11 debug aids gated, #12 cursor freeze on level-up, #13/#14 prompt key + Vulnerary value, #15/#16 end-turn focus, #17 camera buffer setting | `CLAUDE/Session Notes/2026-05-19.md`, all commits one-per-fix on `main` |
| Playtest 3 — bug list | #1 HPBar mouse-eater, #2 mouse dismiss level-up, #3 staff range overlay, #4 menu viewport clamp, #5 camera recentre on phase change, #6 HUD follows cursor, #7 mouse-pan feedback loop, #21 ActionMenu shrink | commits `334a724 … 5b1a87c` |
| Code review 2026-05-18 | GDD_01 resync (D1–D5, D7–D11), `InventoryEntry.validate()` wired in `GameMap._spawn_units`, `Unit.has_skill()` unions `mastery_skills`, `combat_animations` hidden in `SettingsScreen` | grep verified 2026-05-20 |
| Code review 2026-05-19 | Clamp `camera_edge_buffer` on load, scale AI pacing delay with `movement_speed`, AI camera re-pan after movement | commits `d430384`, `fa27b2c` |
| Code review 2026-05-19c | 4 DEBUG-banner nits (2.1–2.4) | commit `958995b` |
| Playtest 4 — #1 | Mouse-bump no longer moves the cursor in keyboard-only mode: setting renamed `mouse_targeting`→`mouse_cursor` (values `enabled`/`disabled`), gate applied to motion in all three states (`FREE`/`UNIT_SELECTED`/`TARGETING`); legacy cfg key migrates | commit `bad9f24`; `test_map_cursor` "mouse_cursor=disabled ignores motion" |
| Playtest 4 — #2 | Camera now returns to the player's end-of-turn view: `MapCursor._on_phase_changed` saves `_camera.position` on `PLAYER → ENEMY` and restores it on `ENEMY → PLAYER`. PT3 #5 safety net (`_scroll_camera_if_needed`) still runs after the restore so a cursor outside the resulting view is panned in. | this commit; `test_map_cursor` "ENEMY saves camera, PLAYER restores it (PT4 #2)" |
| B7 | `NewGameScreen._on_start`: `push_error + return` when GameState absent (scene change was unconditional — would drop the player's choices) | commit `f92899d` |
| B8 | Comment sweep: `UnitData.tile_position` + `mastery_skills` now say "captured by GameState's manual snapshot (not ResourceSaver; not @export)"; `TurnManager._apply_fort_healing` "fort/throne" → "fort". HUD magic `0`, test comment, and `_grid == null` guard items already addressed in earlier sessions. | commit `f92899d` |
| B9 | Singleton-mutating tests already restore unconditionally before the assertion block (satisfies the "restore before next block" option from code_review_2026-05-19 §2). No code change needed. | verified 2026-05-20 |

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
| B1 ⬜ | `GridManager.get_terrain_bonuses(tile) → {def, dodge}` accessor; route `HUD.gd:152` + `Unit.gd:168` through it | Closes UI→system coupling leak. Independent of milestones — do whenever. | 05-18 review §2 (Medium) |
| B2 ⬜ | Rename / re-time `combat_started` (currently emits *after* `resolve_combat`) — either move emit to top of `resolve_combat` or rename to `combat_applying`; document the chosen contract on the signal | Do **before M8**: M8 adds `condition_applied/removed` siblings to `EventBus`; cleaning up the misleading sibling first prevents future listeners from coding to a lie. | 05-18 review §2 (Low) |
| B3 ⬜ | Extract a **`ModalScreen` base** (Dimmer + open/close + cursor lock) — `SettingsScreen`, `NewGameScreen`, `LevelUpScreen`, `UnitDetailsScreen` all hand-roll modality | Do **before M8/M9 content waves** — those will add condition icons, skill detail popups, etc., each tempted to reinvent again. | 05-19 review §4, 05-19b §4 |
| B4 ⬜ | Extract a **`CameraController`** (autoload or `GameMap`-owned node) — `MapCursor._scroll_camera_if_needed`, `GameMap._on_ai_unit_acting`, and `GameMap`'s initial placement all write `Camera2D.position` directly | Do **before M14 stage 1** — Stage 1 threads the "active controlling faction" through `MapCursor` slices; consolidating camera ownership first keeps the diff smaller. Also unblocks Bucket A2. | 05-19 review §4 |
| B5 ⬜ | Data-driven **Settings schema** — `SettingsManager` field + `SettingsScreen` row + `_on_*_changed` triplet per setting is growing linearly; replace with a registry | Do **before M11** content pass and the Phase-3 UI/UX backlog (grid slider, camera settings, UI scale, resolution, rebind UI all add to this layer). | playtest-2 fix plan §4, 05-19 review §4 |
| B6 ⬜ | Extend `DataManager._validate_cross_references` to weapon `effect_tags`, weapon/skill `weapon_type`, item `effect_id` | Do **before M9** — M9 adds many new `effect_id`s in `.tres`; cheap typos otherwise become silent no-ops. | 05-18 review §2 (Medium) |
| B7 ✅ | ~~`NewGameScreen._on_start` — guard scene change if `GameState` autoload missing~~ | — | Shipped 2026-05-20; commit `f92899d` |
| B8 ✅ | ~~Carry-over Lows: UnitData comment wording; TurnManager "fort/throne"~~ | — | Shipped 2026-05-20; commit `f92899d`. HUD magic `0`, test comment, `_grid==null` guard items verified already done. |
| B9 ✅ | ~~Tighten singleton-mutating tests~~ | — | Verified 2026-05-20: all three test files already restore unconditionally before assertions. No code change needed. |
| B10 ⬜ | **Review and integrate `revised_classes_and_skills.md`.** A new 2567-line classes + skills reference (Awakening flavoured — base + promoted classes, stat caps, growth rates, skill descriptions for ~225 sections) landed in `CLAUDE/GDD/Content Expansion/`. Sits alongside the existing `classes.md`, `skills.md`, `awakening_classes_supplement.md`, `awakening_skills_supplement.md` — the word "revised" implies a supersession but is not declared. **Open question:** which existing docs does this replace vs. extend, and what does it imply for M9 (skill `effect_id`s), M11 (content expansion .tres authoring) and M13 (Awakening supplement)? Reconcile before M9 starts so the .tres data is authored against one source of truth, not four overlapping ones. | Do **before C5 (M9)**: M9 stamps `effect_id`s and `.tres` data into the codebase; doing so against a yet-to-be-reconciled spec is a guaranteed re-author. | `CLAUDE/GDD/Content Expansion/revised_classes_and_skills.md`; sibling docs in the same folder |

### Bucket C — Phase 2 milestones (Decision 10 order)

> Implementation order per `CLAUDE/Docs/design_decisions_log_2026-05-17.md` Decision 10:
> **M14 stages 1–3 → M16 → M14 stages 4–5 (+content) → M8 → M9 → M10 → M11 → M12 → M13**.
> M15 Part A (hotseat) slots anywhere after M14 stage 5.
> M14 green/yellow content + Maps 002–005 ride after M16.

| # | Milestone | Goal (1-liner) | Depends on | Source |
|---|---|---|---|---|
| C1 ⬜ | **M14 stages 1–3** | Replace hardcoded `"player"` with faction-relative concepts; alliance-group hostility helper; faction-as-data + activation-scheduler `TurnManager` (`WHOLE_PHASE`/`ALTERNATING`). **Behaviour-neutral.** | B4 (CameraController extraction recommended) | `GDD_10_Roadmap.md` § Milestone 14 (stages 1–3 only) |
| C2 ⬜ | **M16 — Objective System** | Replace single `objective_type` with multi-condition victory/defeat per faction (Rout, Seize, Boss, Escape, Survive, Defend, Survivor-survives, …). | C1 (per-group victory needs faction model) | `GDD_10_Roadmap.md` § Milestone 16 |
| C3 ⬜ | **M14 stages 4–5 (+content)** | Faction-agnostic AI (`run_ai_phase(faction)`); green/yellow spawns + per-unit faction tags in `MapData`; `PhaseBanner` reads from faction data. | C1, C2 (stage 4 AI reads M16 objective data) | `GDD_10_Roadmap.md` § Milestone 14 stages 4–5 |
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
 A1, A2  ────────────────────────┐  open bugs — do first
                                 │
 B4 (CameraController) ──▶ C1    │
                                 │
 C1 (M14 s1-3) ──▶ C2 (M16) ──▶ C3 (M14 s4-5) ──▶ C4 (M8) ──▶ C5 (M9) ──▶ C6 (M10) ──▶ C7 (M11) ──▶ C8 (M12) ──▶ C9 (M13)
                                       │
                                       └──▶ C10 (M15 Part A)  ──▶ C11 (M15 Part B, deferred)

 B2 (combat_started) ──▶ C4
 B3 (ModalScreen)    ──▶ C4, C5
 B5 (Settings schema)──▶ C7 + Phase-3 UI backlog
 B6 (DataManager validation) ──▶ C5
 B10 (content-doc reconciliation) ──▶ C5, C7 (M9, M11)

 D1 (Pre-Release Cleanup) — gate at release time, not in milestone order
```

---

## 4. Source documents

Update this index when adding new findings docs.

- **Roadmap (canonical):** `CLAUDE/GDD/GDD_10_Roadmap.md`
- **Design decisions:** `CLAUDE/Docs/design_decisions_log_2026-05-17.md` (Decision 10 = the ordering rule)
- **GDD assumptions:** `CLAUDE/GDD/GDD_Assumptions.md`
- **Manual / editor tasks:** `CLAUDE/GDD/GDD_Manual_Tasks.md` (Pending = **none**)
- **Playtests:**
  - 1 (`playtest1_findings_2026-05-18.md`) — fully analysed in `manual_test_findings_analysis.md`, all done
  - 2 (`playtest2_findings_2026-05-19.md` + `playtest2_fix_plan_2026-05-19.md`) — all done
  - 3 (`playtest3_findings_2026-05-19.md`) — bugs #1–7 + #21 done; "later milestones" merged into `GDD_10_Roadmap.md` § UI/UX & Settings
  - 4 (`playtest4_findings_2026-05-19.md`) — bugs **A1, A2** above
- **Code reviews (most recent first):**
  - 2026-05-19c (`CLAUDE/Code Reviews/code_review_2026-05-19c.md`) — DEBUG-banner; 4 nits, all done
  - 2026-05-19b (`code_review_2026-05-19b.md`) — playtest 3 diagnosis; all bugs done
  - 2026-05-19 (`code_review_2026-05-19.md`) — playtest-2-fixes review; top 4 done; remainder = **B9** + architectural backlog (B3/B4/B5)
  - 2026-05-18 (`code_review_2026-05-18.md`) — full-codebase review + documentation audit; most done; remainder = **B1, B2, B6, B7, B8**

---

## 5. How to keep this file accurate

1. When a Bucket-A or Bucket-B item ships, move it under §1 (Done) with the commit hash and delete its row from Bucket A/B.
2. When a milestone in Bucket C completes, mark ⬜→✅ and add a one-liner in §1 referencing the session note.
3. When a new playtest lands, add a new row to §4, then triage its items into Bucket A (bugs) or Bucket E (later milestones) **on the same day** so this file doesn't drift.
4. When Decision 10 (or its successor) is revised, update the order in Bucket C and the dependency graph in §3 in the same commit as the decision log change.
