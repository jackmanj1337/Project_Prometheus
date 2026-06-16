# GDD_10 — Phase 2 Implementation Roadmap

**Status:** Active — live Phase 2 milestone tracker. Status Snapshot table (below) is authoritative.
**Last verified:** 2026-06-16

---

> **Historical roadmap note:** completed migration sections below may mention
> deprecated field names or legacy systems while describing the path from the
> old implementation to the current one. That wording is historical context, not
> the live schema. For the current code-facing contract, use `GDD_01`, `GDD_03`,
> and `GDD_06`.

## How to Use This Document

This is the **Phase 2 roadmap** — the continuation of the MVP phase (milestones
M0–M7, historical build record in `GDD_09_Checklist.md` — deleted Stage 5.2, retrieve
via Git). It defines milestones **M8–M16**, to be implemented after the MVP is stable.
Each milestone produces a testable build.

> The MVP amendments A1–A4 that once lived here (Phase-2 data fields +
> `ConditionManager`, the modifier hooks, the combat context pipeline, and the grid
> skill-hook stubs) are **complete** and have been folded into GDD_01–GDD_08. They
> are no longer tracked separately.

**Priority rules used in this document:**

- Tasks that add new `effect_id` match blocks, new `.tres` data files, or new UI
  panels on top of working infrastructure are straightforward content additions.
- Tasks that change existing combat, grid, or data systems are flagged where they
  occur — the MVP amendments already laid the groundwork (modifier system, combat
  context pipeline, condition stubs, grid skill hooks).
- The **Laguz System (M12)** is fully specced but marked `[DEFERRED]`. Its data
  fields already exist on `UnitData` / `ClassData` (folded in during the MVP), so no
  future resource refactoring is needed.
- **Pair Up pass 1 is implemented:** pairing, stat bonuses, Pair Up/Swap/Separate
  actions, campaign toggle, and snapshot persistence. Dual Strike, Dual Guard,
  adjacent support, forecast integration, and related skills remain deferred
  until explicitly scheduled.

---

## Status Snapshot

The MVP (M0–M7) build is historical (see `GDD_09_Checklist.md` — deleted Stage 5.2,
retrieve via Git). This table tracks Phase 2.

| Milestone | Status | Notes |
| --- | --- | --- |
| M8 — Status Conditions | [READY TO START] | After M9a engine slice; design locks reviewed 2026-05-25; conditions tick per-unit-activation |
| M9 — Skill Content Implementation | [READY TO START] | Promoted split: M9a engine first, then M8, then M9b content |
| M10 — Extra-Turn System | — | After M9; **needs M14 stages 1–5** (extra turn = extra activation) |
| M11 — Content Expansion | — | After M10 |
| M12 — Laguz System | [DEFERRED] | After M11; fully specced below |
| M13 — Awakening Supplement | [DEFERRED] | After M12 |
| M14 — Faction System | [COMPLETE] | Shipped across 2026-05-20 and 2026-05-21; see session notes for stages 1–5 |
| M15 — Hotseat & Remote Control | [PART A IN VALIDATION / PART B DEFERRED] | Hotseat core landed 2026-05-21; remaining Part A work is validation/content; online design ratified 2026-05-17 |
| M16 — Objective System | [COMPLETE] | Shipped 2026-05-20; per-group victory/defeat and standings live |

**Implementation order** (dependency-clean — `AGENT/Docs/design_decisions_log_2026-05-17.md`,
Decision 10, revised by the 2026-05-26 M9a promotion): **M14 stages 1–3 → M16 →
M14 stages 4–5 (+content) → [current playtest/bug-fix round] → **Display &
Accessibility controls** (near-term, see section below) → M9a (engine) → M8 →
M9b (content/data) → M10 → M11 → M12 → M13 → Phase 3.** M15 Part A (hotseat) gates nothing and may slot anytime
after M14 stage 5. M14 green/yellow content + Maps 002–005 ride after M16.
The 2026-05-25 milestone-lock review clarified open design choices for M8/M9/M15/maps;
2026-05-26 explicitly promoted **M9a** ahead of M8 so the skill engine can land before
bulk condition/content work.

---

## Playtest Follow-Up — Initial Responses (2026-06-16)

Items below are implemented and ready for playtest / visual confirmation:

1. [x] **Main character sheet compact stats use effective-display totals.**
       The `I` sheet's compact stat block now uses `StatContributions` +
       `StatBreakdown.effective_display`, so Pair Up and other combat-only stat
       sources are visible without opening More Info. Guard:
       `scripts/tests/test_unit_details_screen.gd`.
2. [x] **Paired units are visible and inspectable from the map/sheet.** Paired leads
       show a `PU` badge on the map, and `UnitDetailsScreen` adds `View Support` /
       `View Lead` to jump between paired partners. Guards:
       `scripts/tests/test_unit_stats.gd`,
       `scripts/tests/test_unit_details_screen.gd`.
3. [x] **New Game map selector keeps last-launched semantics.** Rule toggles still
       persist on change, but the `Map` dropdown reopens from
       `GameState.next_map_data_path` until Start configures a new map/roster choice.
       Guard: `scripts/tests/test_new_game_screen.gd`.
4. [x] **F9 debug hotseat override.** Debug builds now use F9 to route every faction
       through hotseat control and show `hotseat-all` in the debug banner. Toggling F9
       off during a normally AI-controlled phase cancels transient cursor menus /
       selections and resumes that same faction through AI. Guards:
       `scripts/tests/test_turn_manager.gd`,
       `scripts/tests/test_enemy_ai.gd`,
       `scripts/tests/test_map_cursor.gd`,
       `scripts/tests/test_hud.gd`.

Manual visual confirmation still needed: `PU` badge placement on all common unit
facings/tints, paired-partner button focus/order on the `I` sheet, New Game reopen
selection after Back, and the F9 on/off handoff during a live enemy phase. These ship
in the **v0.1.7.0** combined playtest build alongside the Display & Accessibility
features; see `AGENT/Docs/playtest_checklist_v0.1.7.0.md`.

---

## Current Playtest / Bug-Fix Round — v0.1.5.0 findings (2026-06-14)

Live action list for the v0.1.5.0 return pass. Evidence:

- Completed handbook: `AGENT/Docs/playtest_checklist_v0.1.5.0_returned_2026-06-14.md`
- Session error log: `AGENT/Docs/godot_v0.1.5.0_2026-06-14.log`

The v0.1.5.0 pass re-verified the entire v0.1.4 fix set as **passing** (sections
1–7, plus 8.1–8.2, 8.6–8.11, and 9) — only the items below need action.

1. [x] **Pair Up bonuses still report as absent (handbook 8.5).** Tester:
       *"Pairup did not grant any bonuses, and no pairup line showed in lead unit
       character sheet."* **Resolved for the visible sheet surface (2026-06-16):**
       compact stats now show effective-display totals, the paired partner can be
       opened directly from the sheet, and paired leads show a map `PU` badge.
       Earlier investigation below is retained as historical triage context.
       The shipped binary is SHA-verified (`d91ca65…c5c5`) and was built *after* the
       8.5 commits (`b53a385`, `913d39e`), so it contains the fix. A new faithful
       end-to-end regression — `scripts/tests/test_pair_up_bonus_e2e.gd` — loads the
       **real Map 950 roster** (`unit_12_hero_skill_cap` lead + `unit_01_cavalier`
       support), builds **real `Unit` scene instances**, registers them with the live
       `GameState`/`PairUpRegistry`/`PairUpBonusResolver` autoloads, and asserts both
       paths: the resolver returns the handbook bonus `{Str 3, Def 3, Spd 3, Skl 2,
       Lck 1}` **and** `HUD._show_unit` renders `Paired  +3 Str +2 Skl +3 Spd +3 Def
       +1 Lck`. It passes. So the in-build code path is correct; the failure is not
       reproducible headlessly. **Log reviewed (2026-06-14):** the tester's
       `godot.log` (now `AGENT/Docs/godot_v0.1.5.0_2026-06-14.log`) is **clean** — the
       only entries are the expected pre-M9 `armsthrift` / `dash` skill-stub warnings,
       and their backtraces show the combatant carrying `armsthrift`+`dash` (i.e. the
       Hero) attacking. There is **no** `PairUpBonusResolver` / table-load /
       `find_unit_by_id` / data-validation error, so the bonus chain did not fail or
       crash in that run. The log does not capture bonus magnitudes or which unit was
       lead, so it neither confirms nor refutes the report. **Still needed for a
       definitive answer:** a precise repro — (a) which unit was made the *lead*
       (initiating Pair Up from the Cavalier would put the Hero off-map, so hovering
       the Hero would show nothing), and (b) whether the panel checked was the HUD
       unit-info panel (which carries the line) or the `I` inspect screen (which does
       not). Working hypothesis: tester procedure, not a code defect.
2. [x] **Reclass option lines force a horizontal scroll (handbook 8.6 /
       General Map 950 comment).** Tester asked for the class-change stat lines to
       *"wrap around to a second line instead of a horizontal scroll wheel."* Root
       cause: `ReclassScreen`'s option buttons (unlike `PromotionScreen`'s) had no
       `autowrap_mode`, and `OptionsScroll` allowed horizontal scrolling, so the long
       `old +Δ -> new / cap` line overflowed sideways. **Fixed (2026-06-14):** disabled
       the scroll container's horizontal scroll (`horizontal_scroll_mode = 0`) so each
       button is width-capped to the panel, and set the buttons to
       `AUTOWRAP_WORD_SMART` — matching the promotion modal. Regression guard added to
       `scripts/tests/test_reclass_screen.gd`. Docs: GDD_07 §Promotion / Reclass Modal.
3. [x] **Defender Battle Speed hidden when it cannot counter (handbook 8.3).**
       Tester: *"defender battle speed does not display when they cannot counter."*
       The note previously showed only the attacker's Battle Speed plus "(no counter)".
       **Fixed (2026-06-14, decision: show it anyway):** `AttackPreview._battle_speed_note()`
       now always shows both sides — `Attacker N vs Defender M … (defender cannot
       counter)` — since the value is informative and the attacker can still double a
       non-countering defender. `defender_battle_speed` was already populated
       unconditionally by `preview_combat`. Regression guard in
       `test_attack_preview_selector.gd`; GDD_07 updated (DoD#1).

**Enhancement requests (logged; not defects):**

- [ ] **Show which weapons are in use in the combat preview (handbook 2.4).** Tester:
      *"It would be helpful long term to have combat preview display what weapons are
      being used."* The preview shows damage/hit/crit but not the equipped weapon names.
      Candidate for the combat-preview polish backlog.
- [x] **Comprehensive character-sheet stat breakdown.** The `I` inspect sheet now
      shows, per stat, personal base + class base + class cap (loud `NO_CAP_DEFINED`
      placeholder; "—" for intentionally-uncapped MOV/CON/LoS) and every active bonus
      (pair-up + the unit's stat skills + items/tonics) with amount + source, boosted
      stats in green. **Implemented (2026-06-14):** `StatBreakdown` decomposition +
      caps; new `StatContributions` collector surfaces combat-only sources (pair-up,
      stat skills) the same way combat resolves them, with `test_stat_contributions.gd`
      as a drift guard binding the sheet to combat; `UnitDetailsScreen` renders the
      breakdown + green. Caps invariant enforced by `test_class_stat_caps.gd` (DoD#2;
      Soldier is a documented cap-less placeholder). Closes the #8.5 surface gap — the
      pair-up bonus now appears on the sheet, not just the HUD panel (verified by
      `test_pair_up_bonus_e2e.gd`). Auras stay M9 (stubs, hit/dodge/crit only). Design:
      `AGENT/Docs/stat_breakdown_character_sheet_plan_2026-06-14.md`.

**Needs tester clarification (left unchecked on the returned handbook, no comment):**

- 3.1 (Routing Red does not win — Map 002) and 8.4 (Strength Tonic modifier &
  expiration — Map 950) were returned **unchecked with no comment**. Treat as
  `NOT RUN` pending confirmation, not as failures — request a re-run or a note.
- 7.4 camera **panning** memory could not be exercised because *"map is still too
  small"* — a fixture coverage gap, not a defect (the danger-view half passed).

---

## Playtest / Bug-Fix Round — v0.1.4 findings (2026-06-14, resolved)

Items are the defects returned by the v0.1.4 live pass; all are resolved and were
re-verified by the v0.1.5.0 pass above. Evidence:

- Completed handbook: `AGENT/Docs/playtest_checklist_v0.1.4_returned_2026-06-14.md`
- Error-log excerpt + counts: `AGENT/Docs/godot_v0.1.4_2026-06-14_sample.log`
- Promotion-modal screenshot: `950MERC Promotion.png` (in `AGENT/Docs/`)

Ordered cheapest-and-noisiest first, then core-mechanic, then UI, then UX.

1. [x] **Unknown weapon id `iron_axe` (handbook 9.1).** `DataManager` logged
       `unknown weapon id 'iron_axe'` 11,829 times in one pass. Root cause: no
       axe weapon existed in `data/weapons/`, but four Fighter units reference it —
       `data/maps/map_003_defeat_boss/units/m003_fighter_1.tres`,
       `data/maps/map_003_defeat_boss/units/m003_boss.tres`,
       `data/maps/map_004_escape/units/m004_fighter_1.tres`, and
       `data/maps/map_005_defend/units/m005_fighter_1.tres`.
       **Fixed (2026-06-14):** added `data/weapons/iron_axe.tres` (E, Mt 8/Hit 75)
       and registered it in `resource_manifest.json`. Regression guard:
       `scripts/tests/test_unit_inventory_refs.gd` now fails on any unit inventory
       weapon_id / item_id that does not resolve in DataManager.
2. [x] **Pair Up `Swap` is a no-op (handbook 2.7).** Choosing `Swap` on a paired
       lead spent the action but did not trade lead/support roles; the original
       lead stayed on the map. **Fixed (2026-06-14):** `MapCursor._commit_swap_roles`
       now physically swaps the pair after `swap_roles()` — the new lead takes the
       on-map tile + becomes visible, the old lead moves to `OFF_MAP_TILE` + hides,
       both go DONE. Regression guard added to `scripts/tests/test_map_cursor.gd`
       (asserts positions + visibility, not just role labels).
3. [x] **Pair Up support bonuses not applied (handbook 8.5).** After pairing, no
       stat change reached the combat preview or live combat. **Root cause found via
       the new preview-delta test (2026-06-14):** `CombatResolver._apply_pair_up_bonuses`
       stamped every stat under one shared modifier source, and `add_modifier` removes
       all modifiers sharing a source before adding — so each stat wiped the previous
       one and only the last (luck) survived, leaving damage unchanged. **Fixed:**
       distinct source per stat (`pair_up:<support_id>:<stat>`). Guard:
       `test_combat.gd` asserts a paired lead's preview damage rises by the support's
       strength contribution. (The earlier triage note that called this a "correct
       code path" was wrong — the bug only shows with a multi-stat bonus.) UX follow-up
       **done (2026-06-14):** pair-up bonuses are combat-only modifiers, so they never
       showed on the unit-info panel; the panel now displays a "Paired  +N Str +N Def …"
       line for a paired lead (`HUD._pairup_bonus_text`, queried on demand), closing the
       "no change post-pairup" confusion. Guard in `test_hud.gd`.
4. [x] **Allied-Rout map never ends (handbook 2.8).** On Map 001, after the unpaired
       allies died, Red ignored the surviving paired archer, beelined to `(1,1)`,
       and no defeat screen fired. **Fixed (2026-06-14), two parts:**
       (A) `TurnManager._eval_rout` now counts true liveness via
       `GameState.get_all_living_units_of` (new), so a Rout no longer resolves while
       a hidden paired support is alive — the prior `get_living_units_of` excluded
       supports. (B) `EnemyAI._living_hostiles_for_faction` now drops any unit at
       `OFF_MAP_TILE` regardless of pair role, so a desynced off-map unit can't drag
       the AI toward the `(-1,-1)` corner (the `(1,1)` beeline). Regression guards in
       `scripts/tests/test_turn_manager.gd` and `scripts/tests/test_enemy_ai.gd`.
5. [x] **Promotion modal runs off the right edge (handbook 8.7 and 8.11).** The
       promotion class-choice modal was left-pinned with fixed offsets, and the long
       per-stat preview rows forced it wider than the screen, so it clipped off the
       right edge (both manual Master Seal 8.7 and Auto Promote 8.11 — same scene).
       **Fixed (2026-06-14):** `PromotionScreen.tscn` panel is now centered via
       anchors with symmetric grow, and `PromotionScreen.gd` sets the option buttons
       to autowrap so the stat line wraps within the capped width instead of pushing
       the panel off-screen. Regression guard: `test_promotion_screen.gd` asserts the
       panel stays on-screen and horizontally centered. (Headless bounds check only —
       a build-time visual confirm is still worth doing.)
6. [x] **New Game settings not persisted unless a map is started (handbook 1.2).**
       Changing `Pair Up` / `Auto Promote` and closing the New Game panel *without*
       starting a map discarded the change. **Fixed (2026-06-14):** `NewGameScreen`
       now writes each rule toggle through to `GameState` on `item_selected` (shared
       `_persist_rules`, also called by Start), so close/reopen remembers them.
       Regression guard in `scripts/tests/test_new_game_screen.gd`. (The `Map`
       dropdown remains Start-only by design — it configures roster policy too.)

**Lower-severity observations** (confirm and fold in or defer; not yet release-blocking):

- [x] **Combat preview shifts and overlaps (handbook 2.4).** The preview could cover
      the unit-info / objective / terrain HUD panels. **Fixed (2026-06-14):**
      `AttackPreview._reposition_for` now nudges the panel clear of the visible HUD
      panels' screen rects (`_place_clear_of`, a pure helper) after the viewport clamp;
      degrades to the plain clamp when the HUD isn't reachable. Guards in
      `test_attack_preview_position.gd`. (The deferred mouse-follow camera catch-up in
      §10 is separate and unchanged.)
- [x] **Battle Speed not shown in combat preview (handbook 8.3).** Testers couldn't
      verify the follow-up threshold because Battle Speed wasn't shown. **Fixed
      (2026-06-14):** `preview_combat` now returns `attacker_battle_speed` /
      `defender_battle_speed` / `follow_up_threshold`, and the Damage field's More
      Info shows both sides' Battle Speed, the +5 threshold, and who doubles. Guard
      in `test_combat.gd`.
- [x] **Reclass to Soldier grants no level-1 skill (handbook 8.6).** Demoting the
      General to Soldier added no starting skill (reclass to Mercenary correctly
      granted `armsthrift`). **Resolved as not-a-bug (decision 2026-06-14):** the
      placeholder Soldier intentionally authors no `skill_unlocks`, so it grants no
      class skill — working as designed. The reclass code is correct (it grants a
      level-1 skill for any class that authors one). Documented in GDD_03 §Known gaps.

> Note: the `armsthrift` (x80), `dash` (x25), and `disarm` (x2) `SkillHandler`
> stub warnings in the same log are expected pre-M9 (skill content lands in
> Milestone 9), not defects in this round.

---

## Near-Term — Display & Accessibility Controls

Bumped up from the Phase 3 backlog (2026-06-11): scheduled to begin **immediately
after the current playtest / bug-fix round wraps**, ahead of the remaining Phase 2
content milestones. Grouped because they share UI-scaling and screen-space
plumbing. Ordered cheapest-now-first where it ties, hardest-to-retrofit-first
otherwise — see the per-item coupling notes for why the order matters.

1. [x] **Map zoom** — Implemented. Player-controlled camera zoom (scroll wheel /
      `+`/`-`/`0`) over eight levels 0.25×–4× (see `GDD_01_Architecture.md` §Camera
      Zoom). The zoom-aware view math is centralized in `CameraController`
      (`_visible_world_size()`); `MapCursor` drives the input and persists the level
      as `SettingsManager.map_zoom_index`; `GameMap` applies it on map load. The one
      known zoom-naive spot (`AttackPreview._reposition_for`, which offset by a raw
      tile instead of the on-screen `TILE_SIZE × zoom`) is fixed. Tests in
      `test_camera_controller.gd` (zoom-1 parity + 0.5×/2× framing/pan).
2. [x] **Display resolution options** — Implemented. Window-mode dropdown
      (Windowed / Borderless / Fullscreen) + a windowed-resolution picker
      (1280×720 / 1600×900 / 1920×1080) in Settings, persisted to `settings.cfg`
      under a new `[display]` section and applied via `DisplayServer` in
      `SettingsManager._apply_display()`. Aspect policy stays `keep` (letterbox) — the
      existing `canvas_items` + `keep` stretch letterboxes non-16:9 screens, so no
      `stretch/aspect` change was needed.
3. [x] **UI scale (accessibility)** — Implemented. A Settings stepped slider scales
      the whole GUI uniformly via `Window.content_scale_factor`
      (`SettingsManager.UI_SCALE_LEVELS` 0.75×–2.0×, `_apply_ui_scale()`), chosen over
      a font-only `Theme` scalar because it scales fixed-size nodes too (nothing
      clips) and is resolution-independent across desktop / Steam Deck / web. A
      separate text-only scalar can layer on later (overlaps item 4). See
      `GDD_07_UI_UX.md` §Accessibility.
4. [x] **UI layout scale & movement** — Implemented (HUD readouts). The player
      repositions + scales the five persistent HUD panels via an in-map "Edit HUD
      Layout" mode (`HudLayoutEditor`), persisted per panel as `{ offset, scale }` in
      `SettingsManager.hud_layout` and applied by `HUD.apply_layout` (on-screen clamp;
      per-panel scale composes on top of item 3's global scale). Scope is the
      persistent readouts only — the cursor-anchored contextual menus are not movable
      (a later extension if wanted). See `GDD_07_UI_UX.md` §Accessibility. Tests:
      `test_hud_layout` (12) + `test_hud_layout_editor` (6); drag UX is playtest-verified.

---

## Release Gates & Package G Decisions

> These items are cross-cutting release obligations, not milestone-ordered work. Each
> has a decision record owner; track as roadmap entries so nothing falls through.

### 1.0 Definition (D-B)

**Scope:** 1.0 = all offline non-pipeline features + one short campaign.
M15 Part B (online) is post-1.0.
M11 re-scoped: campaign content required for 1.0; full corpus coverage is post-1.0.

**Campaign prerequisites (D-D):** the following are prerequisite dependency edges to
the campaign milestone, not standalone optional work:
- Pre-battle deployment screen (roster selection, convoy/trade initial state)
- Shop / item-purchase screen
- Recruit mechanic (green ally → player unit)

These three items gate the campaign milestone; they do not gate M8–M11 individually.

### Public-Identity Rename Gate (D-A)

All Fire Emblem–derived names are placeholders. A data-pass rename to project-owned
names is required **no later than the first public release-candidate**.
- Scope: faction names, class names, item names, GDD prose, data file strings.
- This rename does **not** resolve the legal/licensing gate (D-A and DOC-012 are
  separate, consecutive gates — rename first, then licensing review).

### Legal / Licensing Gate (DOC-012 / OPEN-12)

**Blocking pre-1.0 gate.** Before any public release, research the source handbook /
corpus license for derivative digital works and decide attribution strategy.
- D-A rename does not resolve this; it runs after the rename.
- Scope: all corpus-derived rules, text, and structural content.
- Owner: DOC-012 decision record.

### Renderer & Platform Targets (OPEN-8 / OPEN-11)

Ratified 2026-06-13 (June decision record):
- **Renderer:** Compatibility (OpenGL) — required for web export; Forward+ not needed.
- **Desktop:** primary target.
- **Steam Deck:** letterbox (keep 16:9) at first verification; revisit "expand" once
  UI-scale setting exists (OPEN-11).
- **Web:** playtest channel.
- **Gamepad:** with the key-rebind milestone.
- **Mobile:** deferred.

Cross-referenced in GDD_00 §Tech Stack; GDD_07 §Accessibility & Input Parity.

### CampaignRules Stub (OPEN-4 / GDD_01 §CampaignRules Contract)

**Status: Stub created (Stage 4.3, 2026-06-13)** — `scripts/resources/CampaignRules.gd`.

The `CampaignRules` Resource defines the per-save bundle of gameplay rules. Today the
fields are loose on `GameState`; the stub establishes the class and adds the key new
field from OPEN-4:

- **`exp_gaining_factions: Array[String]`** — default `["blue", "green"]`; Red (enemy)
  does not gain EXP. Drives `CombatResolver` EXP gating (GDD_02 §EXP).

**Next step (post-stub):** wire `CampaignRules` into `GameState` (replace loose fields
with a `campaign_rules` member), update the snapshot serializer, and update `NewGameScreen`
to populate the object. This is a Phase 3 task (requires campaign save/load design).

### New Backlog Items (from June decisions)

- **Broken-weapon degraded mode (OPEN-5):** optional rule — a 0-use weapon stays
  usable with a stat penalty and infinite uses while broken, repairable at special
  shops/items. Likely a `CampaignRules` toggle. Tracked in Phase 3 Backlog §Systems
  and GDD_04 §Inventory Management.
- **SFX deferred (PL#9):** no interim SFX. Wait for the Phase 3 audio milestone
  (Polish §Sound effects). No code placeholder needed.

---

## Phase 2 Milestones (M8–M16)

---

## Milestone 8 — Status Conditions

**Goal:** Full implementation of all status conditions. Units can be inflicted with
conditions via weapons, staves, and skills. Conditions tick down each turn, have
their prescribed effects, and can be removed by Restore staves and Panacea items.
**Test:** Apply each condition via a staff or skill in a test map. Verify visual
indicator appears. Verify all mechanical effects. Verify removal by Restore staff.

> **Sequencing & dependency.** M8 lands **after M14 core** (the activation
> scheduler, Decision 9). Conditions tick "at start of holder's turn" — this must
> mean **start of the holder's *activation***, which is well-defined in both
> `WHOLE_PHASE` and `ALTERNATING` modes (a unit always has an activation), rather
> than start of a faction phase. Building M8 on the finished turn model avoids
> re-wiring tick points later. See decisions log 2026-05-17, Decision 10.

### Locked design decisions — 2026-05-25 review

These four open questions from the planning notes were resolved before
implementation begins. See `AGENT/Docs/campaign_rules_firming_notes_2026-05-25.md`
for the deliberation log.

- **Poison lethality — configurable per source.** Poison damage **floors at 1 HP
  by default** (Poison alone cannot kill). The damage source carries an optional
  `can_be_lethal: bool` flag (default `false`); only sources with the flag
  explicitly set may reduce the holder to 0 HP. This preserves classic FE
  semantics while leaving the door open for a future "lethal poison" boss skill.
- **Berserk targeting — highest projected damage, then nearest, then unit id.**
  The Berserk AI profile reaches every legal target it can attack this
  activation, ranks them by **projected damage** (the same expected-damage
  calculation the threat preview will already need: hit/crit-weighted, after
  mitigation), then tiebreaks **nearest in tiles**, then **lowest unit id** for
  determinism. Behaviour is therefore reproducible under a fixed RNG seed.
- **Silence scope — tomes and staves only.** Silence blocks actions whose
  primary `weapon_type` is `TOME` or `STAFF`. It does **not** block physical
  weapons or active non-magical skills. The condition is a pure filter on
  weapon type; no per-skill `silenceable` flag is added in M8. (If a future
  active skill genuinely needs Silencing, add the flag then.)
- **Condition schema — minimal `{ type, turns_remaining }`.** Standard
  conditions store only those two fields; extra fields are added per
  condition only when the condition genuinely needs them (e.g. Hex's
  skill-granted effect id). Do **not** preemptively add `source_id`,
  `magnitude`, `tags`, or `metadata` columns to every condition.

### Condition Definitions

All conditions store as `{ "type": String, "turns_remaining": int }` in
`UnitData.conditions`. The `ConditionManager` autoload (stubbed in M1) is
fully implemented here.

| Condition | Effect | Duration | Tick Point |
| --- | --- | --- | --- |
| Poison | −3 HP at start of holder's turn; −10 Accuracy and Dodge during combat | 5 turns | Start of holder's turn |
| Sleep | Cannot move, act, or counterattack; Dodge set to 0 | 3 turns | Start of holder's turn |
| Silence | Cannot use tomes or staves | 4 turns | Start of holder's turn |
| Berserk | Must attack the target with the highest projected damage (nearest → lowest unit id tiebreak) in range each turn, including allies | 3 turns | Start of holder's turn |
| Stun | Cannot move, act, or counterattack; Dodge set to 0 | 1 turn | Start of holder's turn |
| Hex | −6 STR and −6 MAG (via active_modifiers, "combat" duration_type by default) | Custom | Applied by skill |

### `ConditionManager.gd` — full implementation

```gdscript
extends Node

const CONDITION_POISON   := "poison"
const CONDITION_SLEEP    := "sleep"
const CONDITION_SILENCE  := "silence"
const CONDITION_BERSERK  := "berserk"
const CONDITION_STUN     := "stun"

func apply_condition(unit: Node, condition_type: String, duration: int) -> void:
    # Do not stack: refresh duration if already present.
    remove_condition(unit, condition_type)
    unit.data.conditions.append({ "type": condition_type, "turns_remaining": duration })
    EventBus.condition_applied.emit(unit, condition_type)
    # For Poison, also add active_modifier to accuracy and dodge:
    if condition_type == CONDITION_POISON:
        unit.add_modifier("accuracy", -10, "poison_acc", -1, "permanent")
        unit.add_modifier("dodge",    -10, "poison_dod", -1, "permanent")
    _update_unit_visual(unit)

func remove_condition(unit: Node, condition_type: String) -> void:
    unit.data.conditions = unit.data.conditions.filter(
        func(c): return c["type"] != condition_type
    )
    if condition_type == CONDITION_POISON:
        unit.remove_modifier("poison_acc")
        unit.remove_modifier("poison_dod")
    _update_unit_visual(unit)
    EventBus.condition_removed.emit(unit, condition_type)

func tick_conditions(unit: Node) -> void:
    # Called by TurnManager at the start of the unit's turn.
    # Apply per-turn effects, then decrement. Remove at 0.
    for condition in unit.data.conditions.duplicate():
        match condition["type"]:
            CONDITION_POISON:
                # Default Poison floors at 1 HP. A lethal-poison source would
                # carry `can_be_lethal = true` and call `take_damage` directly.
                var damage := 3
                if unit.data.hp - damage < 1:
                    damage = max(unit.data.hp - 1, 0)
                unit.take_damage(damage)
                EventBus.unit_damaged.emit(unit, damage)
        condition["turns_remaining"] -= 1
    unit.data.conditions = unit.data.conditions.filter(
        func(c): return c["turns_remaining"] > 0
    )
    _update_unit_visual(unit)

func has_condition(unit: Node, condition_type: String) -> bool:
    for condition in unit.data.conditions:
        if condition["type"] == condition_type:
            return true
    return false

func clear_all_conditions(unit: Node) -> void:
    # Called by Boon skill and Restore staff.
    for condition in unit.data.conditions:
        if condition["type"] == CONDITION_POISON:
            unit.remove_modifier("poison_acc")
            unit.remove_modifier("poison_dod")
    unit.data.conditions.clear()
    _update_unit_visual(unit)

func _update_unit_visual(unit: Node) -> void:
    # Updates the condition icon above the unit sprite.
    # Priority: Berserk > Sleep > Stun > Silence > Poison
    # [PLACEHOLDER] icon display
```

### Condition enforcement hooks

```gdscript
# In TurnManager: start of each unit's activation (player and enemy)
ConditionManager.tick_conditions(unit)
if ConditionManager.has_condition(unit, "sleep") or ConditionManager.has_condition(unit, "stun"):
    TurnManager.set_unit_state(unit, UnitState.DONE)
    return  # unit cannot act

# In CombatResolver._collect_combat_modifiers():
if ConditionManager.has_condition(defender, "sleep") or ConditionManager.has_condition(defender, "stun"):
    context.flags.defender_cannot_counter = true
    context.def_mod.dodge = -9999  # cannot dodge

# In ActionMenu: grey out "Staff" and tomes if unit has Silence
if ConditionManager.has_condition(acting_unit, "silence"):
    # disable staff and tome options

# In EnemyAI: Berserk overrides normal AI — attack highest-damage target regardless of team
if ConditionManager.has_condition(unit, "berserk"):
    _run_berserk(unit)  # new AI profile
```

### New EventBus signals

```gdscript
signal condition_applied(unit: Node, condition_type: String)
signal condition_removed(unit: Node, condition_type: String)
```

### Poison weapon effect

Venin weapons (Venin Axe, Venin Edge, Venin Lance, Venin Bow, Venin Dagger, Toxin tome)
inflict Poison on hit. Add `"effect_tags": ["poison_on_hit"]` to each Venin weapon `.tres`.
Handle in `SkillHandler.apply_trigger(attacker, "on_hit", context)` — if weapon has
`"poison_on_hit"` tag, call `ConditionManager.apply_condition(defender, "poison", 5)`.

### Checklist — M8

- [ ] Implement `ConditionManager.apply_condition()` with duplicate-refresh logic
- [ ] Implement `ConditionManager.remove_condition()` with modifier cleanup for Poison
- [ ] Implement `ConditionManager.tick_conditions()` with Poison damage
- [ ] Implement Poison-floors-at-1-HP-by-default; respect `can_be_lethal` on the
      condition's source data when present
- [ ] Implement Berserk targeting as **highest projected damage → nearest →
      lowest unit id** (reuse the threat-projection helper from AI)
- [ ] Silence filter: block actions whose `weapon_type` is `TOME` or `STAFF`
      (no other categories)
- [ ] Keep stored condition records to `{ type, turns_remaining }` — no extra
      schema fields unless an individual condition (e.g. Hex) needs them
- [ ] Implement `ConditionManager.has_condition()`
- [ ] Implement `ConditionManager.clear_all_conditions()` (for Restore/Boon/Panacea)
- [ ] Add `condition_applied` and `condition_removed` signals to `EventBus.gd`
- [ ] Hook `tick_conditions()` into `TurnManager` at the start of each unit's activation
- [ ] Hook Sleep and Stun lock into `TurnManager` to skip acting units
- [ ] Hook Sleep and Stun `defender_cannot_counter` flag into `CombatResolver`
- [ ] Hook Silence check into `ActionMenu` to disable tome/staff options
- [ ] Hook Berserk profile into `EnemyAI`; add `_run_berserk()` function
- [ ] Add `"poison_on_hit"` effect tag to all Venin weapon `.tres` files
- [ ] Handle `"poison_on_hit"` tag in `SkillHandler.apply_trigger("on_hit")`
- [ ] Implement condition icon display above unit sprite `[PLACEHOLDER visual]`
- [ ] Create `.tres` data for Restore staff (`effect_tags: ["remove_conditions"]`)
- [ ] Handle Restore staff use calling `ConditionManager.clear_all_conditions(target)`
- [ ] Handle Panacea item use calling `ConditionManager.clear_all_conditions(self)`
- [ ] Verify: a Poisoned unit takes 3 damage at the start of each of its turns
- [ ] Verify: Poison expires after 5 turns
- [ ] Verify: a Sleeping unit cannot move, act, or counterattack
- [ ] Verify: Sleep expires after 3 turns
- [ ] Verify: a Silenced unit cannot use staves or tomes in the Action Menu
- [ ] Verify: a Stunned unit loses its turn and cannot counterattack (1 turn)
- [ ] Verify: a Berserk unit attacks the most vulnerable target regardless of team
- [ ] Verify: Restore staff removes all conditions from the target
- [ ] Verify: Panacea removes all conditions from the user
- [ ] Verify: Venin weapon inflicts Poison on a successful hit

---

## Milestone 9 — Skill Content Implementation

**Goal:** Implement all skill `effect_id` handlers that were architecturally deferred
from MVP. All skills present in the base handbook and Awakening supplement are
functional. **Test:** Equip each category of skill on a test unit and manually verify
its effect triggers correctly and produces the expected change in numbers or behavior.

This milestone adds `match` blocks to `SkillHandler.apply_trigger()` for every
deferred effect. The infrastructure (modifier pipeline, trigger types, counter system)
is already in place from the MVP amendments.

### Locked design decisions — 2026-05-25 review

These four open questions from the planning notes were resolved before
implementation begins. See `AGENT/Docs/campaign_rules_firming_notes_2026-05-25.md`
for the deliberation log.

- **Internal M9a / M9b split (public roadmap unchanged).** Work M9 internally as
  two phases: **M9a** finishes the *engine* — every `match` arm in
  `SkillHandler.apply_trigger()` for the effect families below, plus shared
  helpers — landing first against a minimal authored test set. **M9b** then
  authors the bulk of the production skill `.tres` files against the locked
  engine. The roadmap and downstream milestone numbers stay unchanged; the
  split is a discipline tool to avoid mid-content engine refactors.
- **Trigger discipline — strict reuse, flags first.** Do **not** introduce a
  new `trigger` type during M9 unless an existing trigger combined with a
  context flag (`context.flags.*`) demonstrably cannot express the skill. If a
  new trigger is genuinely required, justify it in the skill's design note
  before adding it. The trigger surface area drives interaction-ordering
  complexity, so it is deliberately kept small.
- **Effect computation — hybrid (dynamic for state, stored for static).**
  Threshold- and state-dependent effects (e.g. **Resolve**, **Frenzy**, the
  pre-mitigation halving applied by **Aegis**) are evaluated **at query time**
  off the current state, not stored as toggled modifiers. Static passives
  (e.g. **Zeal**, **Tough**) remain stored modifiers added on initialisation.
  Rule of thumb: if the contribution depends on a condition that can change
  during a unit's lifetime, evaluate it dynamically.
- **Pair Up / Rescue — fully out of M9.** No skill content or engine code in
  M9 may depend on `pair_up`, `support`, or `rescue` semantics; these are
  campaign-rule features and will be handled in the campaign-rules milestone
  (per the 2026-05-25 scope decision). M9-era Pair Up references in the
  checklist below are explicitly marked *skip* / *defer*. Any unavoidable
  integration retrofit lands later, once the campaign rules are specified.

### Generic stat skills — passive bonuses

These use `trigger = "passive"` and `effect_id = "stat_bonus"`. The SkillHandler
reads `effect_params` to know which stat and amount to add as a permanent modifier
when the unit is initialized. Already handled if the MVP implementation supports
`effect_params` — verify and stub if not.

- [ ] Implement `"stat_bonus"` effect: reads `effect_params["stat"]` and
      `effect_params["delta"]` and calls `unit.add_modifier(stat, delta, skill.id, -1, "permanent")`
      when the unit initializes
- [ ] Create `.tres` files for all generic stat-bonus skills:
      Barrier (+2 RES), Celerity (+2 MOV), Clear Vision (+2 LoS), Focus (+2 MAG),
      Fortunate (+2 LUK), Perceptive (+2 LoS), Prowess (+2 SKL), Swift (+2 SPD),
      Tough (+2 DEF), Vigor (+5 MaxHP), Zeal (+2 STR)

### Aura skills — `on_combat_apply_modifiers`

Called for every unit on the map during `_collect_combat_modifiers()` in
`CombatResolver`. Each aura checks distance from the skill holder to the attacker
or defender, then adds to `context.atk_mod` or `context.def_mod`.

- [x] Implement `"charm"` aura: allies within 3 spaces of skill holder gain +10 accuracy
      and +10 dodge during combat *(SkillHandler implemented; .tres file is Phase 2)*
- [x] Implement `"anathema"` aura: enemies within 3 spaces of skill holder suffer −10
      accuracy and −10 dodge during combat *(SkillHandler implemented; .tres file is Phase 2)*
- [x] Implement `"daunt"` aura: enemies within 3 spaces suffer −10 accuracy and −10 crit
      *(SkillHandler implemented; .tres file is Phase 2)*
- [ ] Implement `"motivate"` aura: adjacent allies gain +3 DEF, RES, and LUK during combat
- [ ] Implement `"air_superiority"` aura on skill holder: +4 STR, SKL, SPD when fighting
      a Flying unit
- [ ] Implement `"flanking"`: +3 STR, SKL, SPD when an ally is on the opposite side of
      the target. Check if a player ally occupies the tile directly opposite the attacker
      relative to the defender.
- [ ] Implement `"demoiselle"`: male allied units within 3 spaces take −4 damage
- [ ] Implement `"gentilhomme"`: female allied units within 3 spaces take −4 damage
- [ ] Implement Awakening `"charm"` (Lord/Bride version): same as Charm above — confirm
      they share the same `effect_id`
- [ ] Implement `"tailwind"`: adjacent allies get +5 SPD (Laguz Hawk promotion — defer
      Laguz-specific trigger to M12; implement the aura logic here so it's ready)
- [ ] Implement `"solidarity"`: when this unit is Support in a Pair Up — skip; Pair Up
      is out of scope

### Combat skills — `on_attack`, `on_hit`, `on_kill`, `on_damaged`

- [ ] Implement `"sol"`: `on_attack` SKL/2% activation; attacker heals 50% of damage dealt
      in that attack. Call `attacker.heal(floor(damage * 0.5))`
- [ ] Implement `"luna"`: `on_attack` SKL/2%; set `context.flags.attacker_ignores_def = 0.5`
      for that attack
- [ ] Implement `"ignis"`: `on_attack` SKL/2%; if physical attack, add `floor(attacker.get_effective_stat("magic") / 2)` to damage (vs DEF); if magical, add `floor(STR/2)` to damage (vs RES)
- [ ] Implement `"aether"`: `on_attack` SKL/2%; simultaneously triggers Sol and Luna effects
- [ ] Implement `"vengeance"`: `on_attack` SKL/2%; add `floor(attacker.data.damage_taken_this_map / 2)` to damage
- [ ] Implement `"lifetaker"`: `on_kill`; attacker heals `floor(killing_blow_damage / 2)`
- [ ] Implement `"galeforce"`: `on_kill`; check `skill_use_counters["galeforce"] == 0`;
      if so, reset attacker state to READY and consume one use
- [ ] Implement `"aggressor"`: `on_combat_apply_modifiers`; if `context.is_player_initiated`
      and attacker has Aggressor, add +10 to `context.atk_mod.damage`
- [ ] Implement `"loot"`: `on_kill`; add 20 gold to `attacker.data.gold`
- [ ] Implement `"gamble"`: `player_activated` before attack; halve accuracy, double crit
      for that combat. Add "active" flag cleared after combat end
- [ ] Implement `"wrath"`: `on_combat_apply_modifiers` passive check; if attacker HP ≤ 50%,
      add +50 to `context.atk_mod.crit`
- [ ] Implement `"resolve"`: passive; if unit HP ≤ 50%, `get_effective_stat()` multiplies
      STR, MAG, SKL, SPD by 1.5. Implement as a modifier applied/removed by a tick check,
      or handle directly in `get_effective_stat()` with a HP threshold branch
- [ ] Implement `"frenzy"`: passive; +50% STR when HP ≤ 50% (Berserker promotion) — same
      pattern as Resolve but STR only
- [ ] Implement `"adept"`: `on_attack` SKL/2% during non-additional attacks: add 1 to
      `context.atk_mod.strikes`
- [ ] Implement `"cancel"`: `on_attack` SKL/2%; set a flag on the defender that negates
      their next attack this combat
- [ ] Implement `"corrosion"`: `on_attack` SKL/2%; reduce defender's equipped weapon uses
      by attacker's level
- [ ] Implement `"drain"` (Warlock): `on_hit` on crit; attacker heals 50% of crit damage
- [ ] Implement `"cripple"` (Warrior occult): `on_hit` on crit; apply −50% STR modifier to
      defender for 2 turns (`add_modifier("strength", -floor(strength * 0.5), "cripple", 2, "map_turn")`)
- [ ] Implement `"reaper"` (Assassin): `on_combat_apply_modifiers`; if weapon type is
      "knife" or "dagger", double effective SKL for crit calculation
- [ ] Implement `"nihil"`: `on_combat_start`; set `context.flags.nihil = true` preventing
      SkillHandler from calling the defender's battle skills
- [ ] Implement `"vantage"`: `on_combat_start`; set `context.flags.vantage = true`
- [ ] Implement `"discipline"` (Negate weapon triangle): `on_combat_apply_modifiers`;
      zero out any weapon triangle bonuses in context
- [ ] Implement `"unorthodox"` (Reverse weapon triangle): `on_combat_apply_modifiers`;
      negate the triangle result before it is applied (flip advantage ↔ disadvantage)
- [ ] Implement `"nullify"` (Negate bonus damage): `on_combat_start`; set
      `context.flags.skip_effectiveness = true`
- [ ] Implement `"pavise"` (Great Knight): `on_combat_start`; set
      `context.flags.defender_negate_crits = true`; enforce in `_resolve_single_attack()`
- [ ] Implement `"patience"` (Awakening): `on_combat_apply_modifiers`; if
      `!context.is_player_initiated` and unit is defender, add +10 accuracy and +10 dodge
- [ ] Implement `"prescience"` (Awakening): +15 Hit/Dodge when initiating
- [ ] Implement `"underdog"` (Awakening Villager): +15 Hit/Dodge vs higher-level enemy
- [ ] Implement `"lucky_seven"` (Awakening): +20 Hit/Dodge on turns 1–7
- [ ] Implement `"odd_rhythm"`: +15 Hit/Dodge on odd `context.turn_number`
- [ ] Implement `"even_rhythm"`: +15 Hit/Dodge on even `context.turn_number`
- [ ] Implement `"rightful_king"` (Great Lord): `on_combat_apply_modifiers`; before each
      activation roll, add +10 to the activation percentage (hook into `_roll_activation_pct()`)
- [ ] Add `_roll_activation_pct(base_pct: int, unit: Node) -> bool` helper to
      SkillHandler that adds any Rightful King bonus before rolling

### Faire and Breaker skills

- [x] Implement `"*faire"` family: `on_combat_start`; if attacker has the matching
      faire skill and weapon type matches, add +5 to `context.atk_mod.damage`
- [x] Create MVP `.tres` for: Swordfaire, Lancefaire, Bowfaire (sword/lance/bow coverage)
- [ ] Create remaining `.tres` for: Axefaire, Tomefaire (Phase 2 content)
- [x] Implement `"*breaker"` family: `on_combat_start`; check defender's equipped
      weapon type; add +50 accuracy to the holder's side
- [x] Create MVP `.tres` for: Swordbreaker, Lancebreaker, Bowbreaker
- [ ] Create remaining `.tres` for: Axebreaker, Tomebreaker (Phase 2 content)

### Defensive and damage-reduction skills

- [ ] Implement `"dragonskin"` (Manakete): `on_combat_start`; set
      `context.flags.damage_multiplier` for defender to 0.5; also set
      `context.flags.skip_effectiveness = true`. Note: Dragonskin is a Laguz-tier
      skill but the flag infrastructure is ready
- [ ] Implement `"ironhide"` (Wyvern Lord): `on_combat_start`; if attacker's weapon rank
      is E or D and `!weapon.uses_mag`, set `context.atk_mod.damage` to a value that
      floors final damage to 0
- [ ] Implement `"iote_shield"` (Awakening, flying only): `on_combat_start`; set
      `skip_effectiveness = true` for all flying-effective weapons against this unit
- [ ] Implement `"aegis"` (Mage Knight): passive `get_effective_stat("defense")` adds 25% of
      RES to DEF. Handle as a dynamic modifier in `get_effective_stat()` rather than
      a stored modifier, since RES can change
- [ ] Implement `"charge"` (Great Knight occult): `on_combat_apply_modifiers`; if unit
      used full movement before attacking, apply 1.5× damage multiplier

### Reactive skills — `on_ally_attacked`, `on_enemy_leaves_adjacent`

These require the Phase 2 trigger types already declared on `SkillData` (see GDD_01).

- [ ] Hook `on_ally_attacked` trigger: in `CombatResolver.resolve_combat()`, after the
      context is built, fire `SkillHandler.apply_trigger(adjacent_unit, "on_ally_attacked", context)`
      for all units adjacent to the defender (not on the attacker's team). The context
      includes the full combat so skills can read damage values
- [ ] Implement `"counter"` (Vanguard occult): `on_damaged` SKL/2%; if damage source is
      range 1 melee, apply the same damage amount to the attacker (no counterattack roll)
- [ ] Implement `"parry"` (Guardian occult): `on_ally_attacked` SKL/2%; if damage would
      be ≥ 50% of target's current HP, set damage to 0 and deal half to attacker instead
- [ ] Implement `"redirect"` (Guardian promotion): `player_activated` once per turn;
      unit takes the hit for an adjacent ally, recalculated against this unit's DEF or RES
- [ ] Hook `on_enemy_leaves_adjacent` trigger: in `Unit.move_along_path()`, after each
      tile step, check if any enemy that was adjacent at the previous tile is no longer
      adjacent; emit the trigger for eligible units
- [ ] Implement `"no_escape"` (Warrior occult): `on_enemy_leaves_adjacent` SKL/2%;
      make one attack against the leaving enemy with no counterattack from them

### Per-map activated skills

- [ ] Implement `"challenge"` (Paladin occult): `player_activated` 3×/map; apply +3 STR,
      SPD, SKL, DEF when fighting the selected target. Store selected enemy node ID in
      a skill context dict on the unit. Clear when a different target is chosen
- [ ] Implement `"rise"` (Necromancer promotion): `player_activated` 3×/map; on kill,
      create a new unit node with ½ the dead unit's stats (rounded down), team = player,
      ai_profile = "passive", placed on the vacated tile
- [ ] Implement `"strike_true"` (Paladin promotion): if attacker missed by ≤10%, re-roll
      once. Track via `max_uses_per_combat = 1` in SkillData

### Movement skills (using A4 stubs)

- [ ] Implement `SkillHandler.get_move_cost_override()` for `"acrobat"`:
      return 1 for all terrain except wall and deep sea
- [ ] Implement `get_move_cost_override()` for `"swiftfoot"`:
      return 1 for all terrain that normally costs > 1 (except wall and sea)
- [ ] Implement `SkillHandler.can_pass_through_enemies()` for `"pass"`: return true
- [ ] Implement `SkillHandler.can_phase_through()` for `"phasing"`: allow passing
      through wall tiles during one movement per turn. Track via a per-turn flag reset
      in `TurnManager`
- [ ] Implement `"smite"`: replaces standard Shove; pushes target 2 tiles instead of 1.
      Modify Shove action handler to check for Smite and adjust distance
- [ ] Implement `"lunge"`: `player_activated`; allows initiating combat with a range-1
      weapon as though it were range 2. Add +10 to `context.atk_mod.crit`. The unit
      must occupy a tile that would be in range-2 of the target. No movement occurs
- [ ] Implement `"dash"` (Hero promotion): allow one diagonal move step per activation
      of the action. Diagonal costs the same as one orthogonal move. Increment available
      diagonal steps at levels 6, 11, 16. Track per-combat diagonal steps on Unit
- [ ] Implement `"bulldozer"` (Brawler promotion): after shoving an enemy, apply a
      `"stun"` condition for 1 turn (movement = 0 equivalent — use the Stun condition
      with a flag checked in TurnManager to set MOV to 0)
- [ ] Implement `"trample"` (Raider promotion): `player_activated`; during movement,
      deal 4 damage to each enemy tile passed through; unit takes 2 damage per enemy hit.
      Resolved in `Unit.move_along_path()` when Trample is active
- [ ] Implement `"hit_and_run"` (Hawk occult): `on_kill`; after killing an enemy during
      player phase, unit may move up to full MOV, healing 1 HP per tile moved
- [ ] Implement `"bastion"` (General promotion): `player_activated` as an action; marks
      one adjacent empty tile as blocked until this unit's next turn. Store the blocked
      tile in `GameState` or `GridManager._bastion_tiles: Dictionary` (unit → tile).
      `is_passable()` checks this dict. Clear at start of unit's next turn
- [ ] Implement `"nimble"` (Cat promotion — deferred to M12): stub now, wire in M12

### Healing and support skills at start_of_turn

- [ ] Implement `"renewal"` (already in MVP): verify it calls `unit.heal(ceil(data.max_hp * 0.1))`
- [ ] Implement `"boon"` (Paragon promotion): `start_of_turn`; for each adjacent ally,
      call `ConditionManager.clear_all_conditions(ally)` (requires M8)
- [ ] Implement `"holy_aura"` (Bishop occult): `start_of_turn` LUK/2%; allies in 2-space
      radius heal 20% of their max HP
- [ ] Implement `"grace"` (Heron promotion — Laguz): defer to M12; stub here
- [ ] Implement `"holy_conduit"` (Valkyrie promotion): `on_hit` on crit with light tome;
      adjacent ally heals HP equal to damage dealt

### Weapon-buff skills

- [ ] Implement `"infuse"` (Soulblade): `player_activated` before attack; reduce crit to 0,
      add `floor(MAG/2)` to damage calculated against RES instead of DEF for that attack
- [ ] Implement `"firebreathing"` (Dracoknight): fire attribute spells additionally hit
      one tile in a straight line behind the target. Resolve in a new AoE handler
      (see M9 AoE section)
- [ ] Implement `"vortex"` (Raven promotion — Laguz): defer to M12

### Awakening-specific skills

- [ ] Implement `"veteran"` (Tactician starting): in `Unit.add_exp()`, if unit has
      `"veteran"`, multiply amount by 1.5 before adding
- [ ] Create `.tres` files for all Awakening generic skills:
      Sol, Luna, Ignis, Aether, Galeforce, Aggressor, Vengeance, Lifetaker,
      Patience, Solidarity, Iote's Shield, Acrobat, Pass, Lucky Seven, Odd Rhythm,
      Even Rhythm, Prescience, Underdog, all Faire skills, all Breaker skills,
      all Rally skills (data files; Rally effects in M10), all Pair Up skills (data files only)
- [ ] Create `.tres` files for Awakening class-specific skills:
      Veteran, Rightful King, Ignis, Anathema, Vengeance, Tomebreaker, Lifetaker,
      Shadowgift, Beastbane, Stoneborn, Dragonskin, Wyrmsbane, Special Dance,
      Charm, Galeforce, Sol, Acrobat, Pass, Aggressor, Swordfaire, Deliverer,
      Lancebreaker, Odd Rhythm, Even Rhythm, Rally Magic, Rally Spectrum

### AoE damage framework

Several skills require attacking multiple targets simultaneously (Firebreathing, Inferno,
Whirlwind, Holy Aura, Meteor-type siege tomes). This needs a thin AoE layer on top of
`CombatResolver`.

- [ ] Add `resolve_aoe_attack(attacker: Node, target_tiles: Array[Vector2i]) -> Array[Dictionary]`
      to `CombatResolver`
- [ ] For each tile in `target_tiles`, if a unit occupies it and it is an enemy, apply
      the attacker's damage calculation against that unit. No counterattacks from AoE targets
      unless noted by the skill
- [ ] Apply weapon durability once for the whole AoE use (not per-target)
- [ ] Implement Firebreathing: fire spells hit target tile and one tile directly behind it
      (straight line away from attacker). Call `resolve_aoe_attack()` with both tiles
- [ ] Implement Inferno (Dracoknight occult): `on_hit` MAG/2%; primary target takes
      normal damage; adjacent enemies receive an `active_modifier` of `delta = -floor(MAG/2)`
      to `"hp"` with `duration_type = "turn"` (applied at their next turn start).
      Use a new `"delayed_damage"` duration type ticked in ConditionManager
- [ ] Implement Whirlwind (Raven occult): `on_hit` SPD/2%; push all enemies adjacent to
      attacker back 1 tile. Use existing Shove logic per adjacent enemy. Damage resolved
      against primary target only

### Checklist — M9 (summary)

- [ ] All generic stat-bonus skill `.tres` files created and passive effect working
- [ ] All aura skills verified in combat preview numbers
- [ ] All combat skills (Sol through Cancel) verified with manual test combats
- [ ] All Faire and Breaker skill `.tres` files created and verified
- [ ] Movement skill stubs replaced with real implementations in SkillHandler
- [ ] Reactive skills (Counter, Parry, Redirect, No Escape) verified with edge cases
- [ ] Per-map skills (Challenge, Rise, Strike True) use counter system correctly
- [ ] AoE framework implemented and used by Firebreathing
- [ ] All Awakening skill `.tres` files created
- [ ] Rightful King bonus hooks into activation rolls correctly
- [ ] Verify: a unit with no skills still functions identically to before M9

---

## Milestone 10 — Extra-Turn System (Canto and Dancer)

**Goal:** Units with Canto (Bard line, Heron), Special Dance (Dancer), Galeforce,
Encore, and Master Horseman can grant additional turns to themselves or allies within
the rules of each skill. **Test:** Use each extra-turn mechanic in a live map. Verify
turn state transitions. Verify per-map/per-turn limits. Verify cursor and UI behave
correctly during the extra turn.

> **Dependency.** M10 needs **M14 stages 1–5**, not just "after M9." Per Decision 9
> an extra turn is an extra *activation* inserted into the scheduler (stage 3,
> mode-aware), and `grant_extra_turn` must re-enter the **active controller** — AI,
> hotseat, or cursor — not hardcode `MapCursor` (controller abstraction, stage 5).
> Write `grant_extra_turn` against the scheduler, never assuming a turn model. See
> decisions log 2026-05-17, Decision 10.

### TurnManager extensions

```gdscript
func grant_extra_turn(unit: Node, options: Dictionary = {}) -> void:
    # Reactivates a DONE or MOVED unit.
    # options can include:
    #   "can_move": bool    (default true)
    #   "can_act": bool     (default true)
    #   "is_self": bool     (true for Galeforce/Encore; false for Canto/Dance targets)
    # Sets unit state to READY (or MOVED if can_move = false).
    # Emits EventBus.extra_turn_granted(unit).
    # The MapCursor must re-lock input until the extra turn is resolved.
    set_unit_state(unit, UnitState.READY if options.get("can_move", true) else UnitState.MOVED)
    EventBus.extra_turn_granted.emit(unit)

signal extra_turn_granted(unit: Node)  # add to EventBus.gd
```

### Canto skill implementation

Canto is a `player_activated` class skill. Triggering Canto:

- The Canto-holder selects one adjacent ally who is `DONE` this turn.
- `TurnManager.grant_extra_turn(target)` is called.
- Promotion modifiers:
  - **Resonance** (Troubadour): Canto can target up to 2 adjacent allies instead of 1.
  - **Battle Cry** (Skald): Canto target(s) gain +3 STR, MAG, SPD until end of their
    extra turn. Apply via `target.add_modifier()` with `duration_type = "combat"`.
  - **Reverberate** (Heron): In animal form only — Canto targets ALL adjacent allies.
    (Wire to M12 Laguz shift state check.)

```gdscript
# In ActionMenu — add "Canto" option for units with the skill
# Canto action handler:
func _execute_canto(canto_unit: Node) -> void:
    var max_targets: int = 2 if canto_unit.has_skill("resonance") else 1
    # Show target selection UI filtered to adjacent DONE allies
    # On confirm per target:
    if canto_unit.has_skill("battle_cry"):
        target.add_modifier("strength", 3, "battle_cry", 1, "combat")
        target.add_modifier("magic", 3, "battle_cry_mag", 1, "combat")
        target.add_modifier("speed", 3, "battle_cry_spd", 1, "combat")
    TurnManager.grant_extra_turn(target)
    # After max_targets resolved, canto_unit is set to DONE
    TurnManager.set_unit_state(canto_unit, TurnManager.UnitState.DONE)
```

### Mounted-unit movement remainder

Beyond the Canto *skill*, all **mounted** classes (cavalry, fliers, etc.) should
behave like classic Fire Emblem Canto: after taking any non-Wait action that does
not itself end the turn, a mounted unit may spend its **remaining movement**
before its turn ends. (Playtest 3 finding #17.) Built on `grant_extra_turn`:

- After a mounted unit's action resolves, if the unit has unused movement, call
  `grant_extra_turn(unit, { "can_move": true, "can_act": false, "is_self": true })`
  so it re-enters the active controller able to move but not act again.
- The leftover range is the unit's `move` stat minus tiles already spent.
- A unit that chose **Wait** (or any other turn-ending action) gets no remainder.
- Knight Ring (M11 — "unit treated as Mounted for movement remainder") grants
  this to a non-mounted holder via the same code path, gated on the item flag.

### Encore (Skald occult)

`on_combat_end` SKL/2%; after Skald initiates combat, grant an extra turn to the Skald
itself. Max 2× per turn — tracked via `skill_use_counters["encore"]`. Uses
`TurnManager.grant_extra_turn(skald, { "is_self": true })`.

### Special Dance (Dancer)

Special Dance is a `player_activated` class skill with these rules:
- Target: one adjacent ally who has already acted this turn (state = `DONE`).
- Cannot target the same unit consecutively. Track via `last_dance_target: NodePath` on unit.
- Cannot target self.
- Player chooses one stat (STR, SPD, SKL, or LUK); target gains +4 to that stat for 1 turn.
- Dancer's turn ends.

```gdscript
func _execute_special_dance(dancer: Node, target: Node, chosen_stat: String) -> void:
    target.add_modifier(chosen_stat, 4, "special_dance", 1, "map_turn")
    dancer.data.skill_use_counters["last_dance_target"] = str(target.get_instance_id())
    TurnManager.grant_extra_turn(target)
    TurnManager.set_unit_state(dancer, TurnManager.UnitState.DONE)
```

### Galeforce (Dark Flier promotion)

Already specified in M9's `"galeforce"` implementation. Confirm here that:
- `grant_extra_turn(self, { "is_self": true })` is called correctly
- `skill_use_counters["galeforce"]` prevents double-activation per map turn

### Master Horseman (Nomad Trooper occult)

`on_combat_end` after a turn-ending action, SKL/2%: unit may move again and then
perform one more action. Implement as:
- Set unit state back to MOVED (can act but not move again after the second action).
- Track with `skill_use_counters["master_horseman"]` (once per turn).

### Rally skills

Rally skills are `player_activated` actions. They end the user's turn and buff
all allies within 3 spaces for 1 full round.

- [ ] Add "Rally" to the ActionMenu as an option when unit has any Rally skill
- [ ] Show a skill submenu listing all Rally skills the unit has
- [ ] On confirm, call `rally_handler(caster, radius: int, modifiers: Dictionary)`
      which iterates all allies within radius, applies `add_modifier()` for each stat
      in the modifiers dict with `duration = 1` and `duration_type = "map_turn"`
- [ ] Implement all 8 Rally `.tres` skills using the same `effect_id = "rally"` with
      `effect_params` specifying stat and delta. Special-case Rally Spectrum (+2 to all)
- [ ] Verify: Rally modifiers appear in the unit's stat readout and expire correctly

### Checklist — M10

- [ ] Add `grant_extra_turn()` to `TurnManager`
- [ ] Add `extra_turn_granted` signal to `EventBus.gd`
- [ ] Implement Canto action in `ActionMenu`; select adjacent DONE allies
- [ ] Implement Resonance modifier on Canto (up to 2 targets)
- [ ] Implement Battle Cry modifier (stat boost on Canto targets)
- [ ] Implement mounted-unit movement remainder: after a non-Wait action a mounted
      unit may spend leftover movement (playtest 3 #17)
- [ ] Verify: a mounted unit that selects Wait does NOT receive leftover movement
- [ ] Verify: a mounted unit's leftover-movement range excludes already-spent tiles
- [ ] Implement Encore (self extra-turn after combat, 2× per turn max)
- [ ] Implement Special Dance with consecutive-target tracking
- [ ] Implement stat choice selection UI for Special Dance `[PLACEHOLDER UI]`
- [ ] Verify: Galeforce triggers and grants a second turn after a kill
- [ ] Verify: Master Horseman re-enables an action after post-combat movement
- [ ] Implement Rally action in ActionMenu with skill submenu
- [ ] Implement `rally_handler()` in SkillHandler
- [ ] Create all 8 Rally skill `.tres` files with appropriate `effect_params`
- [ ] Verify: Rally Spectrum buffs all 8 stats simultaneously
- [ ] Verify: Rally modifiers expire exactly 1 full round after being applied
- [ ] Verify: Dancer cannot target the same unit twice in a row
- [ ] Verify: cursor input is locked correctly during an ally's extra turn
- [ ] Verify: a unit that uses Galeforce is only granted one extra turn per map turn even
      if they kill multiple enemies during that extra turn

---

## Milestone 11 — Content Expansion

**Goal:** All classes, weapons, skills, and items from the base handbook and Awakening
supplement exist as `.tres` files and load without error. No new systems are required
— this milestone is purely data. **Test:** `DataManager` loads all resources without
errors. Verify every class, weapon, and skill appears correctly in the editor Inspector.

### Classes

- [ ] Create `ClassData.tres` for all Beorc base classes not in MVP:
      Archer, Bard, Brigand, Cavalier, Druid, Fighter, Knight, Mage, Mercenary,
      Myrmidon, Nomad, Pegasus Knight, Soldier, Thief, Wyvern Rider
- [ ] Create `ClassData.tres` for all Beorc promoted classes:
      Ranger, Sniper, Skald, Troubadour, Berserker, Brawler, Paladin, Vanguard,
      Bishop, Paragon, Necromancer, Warlock, Guardian, Warrior, General, Great Knight,
      Mage Knight, Sage, Hero, Sentinel, Soulblade, Swordmaster, Nomad Trooper, Raider,
      Falcoknight, Valkyrie, Commander, Halberdier, Assassin, Rogue,
      Dracoknight, Wyvern Lord
- [ ] Create `ClassData.tres` for all Awakening supplement classes:
      Lord, Tactician, Dark Mage, Barbarian, Dancer, Villager
- [ ] Create `ClassData.tres` for all Awakening promoted classes:
      Great Lord, Grandmaster, Sorcerer, Dark Knight, Bow Knight, War Monk, War Cleric,
      Dark Flier, Griffon Rider, Trickster, Dread Fighter, Bride
- [ ] Create `ClassData.tres` for all Laguz base classes (Laguz fields populated;
      logic deferred to M12):
      Cat, Tiger, Hawk, Heron, Raven, Taguel, Manakete
- [ ] Verify: Cavalier `proficiencies` correctly represents "choose one of Axe/Lance/Sword"
      — implement as a new `ClassData` field `proficiency_choice: bool = false` with
      `proficiency_options: Array[String]` presented to the player/GM at unit creation
- [ ] Verify: Mage `proficiencies` supports "choose two Anima types"
- [ ] Verify: Dancer does not have a `promotes_to` entry (non-promoting class)
- [ ] Verify: Villager `promotes_to` is empty (GM-discretion promotion handled at runtime)

### Weapons

- [ ] Create `WeaponData.tres` for all axes (Bronze through Urvan, including Bolt Axe,
      Brave Axe, Halberd, Hammer, Wyrm Axe, etc.)
- [ ] Create `WeaponData.tres` for all bows (Bronze through Rienfleche, including
      Bright Bow with `triangle_family = "light"`, Double Bow with `range_min = 1`)
- [ ] Create `WeaponData.tres` for all lances (Bronze through Wishblade, including
      Flame Lance with `triangle_family = "fire"`, Brave Lance)
- [ ] Create `WeaponData.tres` for all swords (Bronze through Vague Katti, including
      Sonic Sword with `triangle_family = "wind"`, Runesword with lifesteal tag,
      Brave Sword)
- [ ] Create `WeaponData.tres` for all knives (Bronze Knife through Peshkatz)
- [ ] Create `WeaponData.tres` for all staves (Heal through Ashera Staff)
- [ ] Create `WeaponData.tres` for all Fire tomes (Fire through Forblaze);
      Forblaze has a unique AoE — add `effect_tags: ["aoe_straight_line"]` and handle
      in the AoE framework from M9
- [ ] Create `WeaponData.tres` for all Thunder tomes (Thunder through Arcblast)
- [ ] Create `WeaponData.tres` for all Wind tomes (Wind through Aircalibur);
      Aircalibur has range 1–4
- [ ] Create `WeaponData.tres` for all Light tomes (Light through Aureola);
      Chastise and Aura have special `mt` formulas — add `effect_tags` to handle at runtime
- [ ] Create `WeaponData.tres` for all Dark tomes (Flux through Ereshkigal);
      Twilight ignores RES (`effect_tags: ["ignore_res"]`), Eclipse sets HP to 1
      (`effect_tags: ["set_hp_1"]`), Nosferatu has lifesteal (`effect_tags: ["lifesteal"]`)
- [ ] Create `WeaponData.tres` for all Laguz natural weapons (Beak/Claw/Fang/Talon
      at ranks E/D/C/A/S); set `is_natural_weapon = true` on all
- [ ] Create `WeaponData.tres` for Taguel Beaststones and Manakete Dragonstones
- [ ] Create `WeaponData.tres` for stationary battlefield weapons (Ballista variants,
      Onager); add `effect_tags: ["aoe_adjacent"]` to Onager
- [ ] Set `strikes_per_attack = 2` on: Brave Axe, Brave Bow, Brave Dagger,
      Brave Lance, Brave Sword
- [ ] Verify: all weapon `effect_tags` for effectiveness are spelled identically to the
      strings used in `_get_effectiveness_multiplier()` in CombatResolver

### Skills

- [ ] Create `SkillData.tres` for all generic handbook skills not yet created
- [ ] Create `SkillData.tres` for all promotion and occult skills not yet created
- [ ] Create `SkillData.tres` for all Awakening generic skills
- [ ] Create `SkillData.tres` for all Awakening class-specific skills
- [ ] Create `SkillData.tres` placeholder for all Laguz-specific skills
      (Feral Instincts, Wildheart, Primal Tenacity, Untamed Persistence, Pounce,
      Hit and Run, Ancient Verse, Whirlwind, Roar; mark `effect_id` as `"deferred_laguz"`)
- [ ] Create `SkillData.tres` for Pair Up skills (data only — logic never implemented):
      Dual Strike+, Dual Guard+, Dual Support+ (mark with a comment in description field)
- [ ] Verify: `DataManager._load_directory()` loads all new skill files without errors

### Items

- [ ] Create `ItemData.tres` for all healing items (Herb, Vulnerary, Concoction, Elixir)
- [ ] Create `ItemData.tres` for all Laguz items (Laguz Stone, Laguz Pearl, Laguz Gem);
      effects deferred to M12 — stubs that print a warning in MVP
- [ ] Create `ItemData.tres` for condition items (Antitoxin, Panacea)
- [ ] Create `ItemData.tres` for all key items (Chest Key, Door Key, Master Key)
- [ ] Create `ItemData.tres` for equip items (Full Guard, Wing Guard, Laguz Guard,
      Iron Rune, Knight Ring, Knight Ward); implement equip-slot logic:
      only 1 equip item may be active; it is read by `_collect_combat_modifiers()`
- [ ] Implement equip-item effects in `_collect_combat_modifiers()`:
      Full Guard → `skip_effectiveness = true`, Iron Rune → `defender_negate_crits = true`,
      Knight Ring → unit treated as Mounted for movement remainder, Knight Ward → stat bonus
- [ ] Create `ItemData.tres` for all stat items (Arms Scroll, Boots, Dracoshield, etc.)
- [ ] Implement stat item effects: permanent `add_modifier()` with `duration_type = "permanent"`
      where appropriate, or direct `UnitData` stat increase for items like Boots (+2 MOV permanent)
- [ ] Create `ItemData.tres` for sellable items (gems, Coin)
- [ ] Create `ItemData.tres` for all promotion items (Master Seal, class-specific seals,
      Laguz Seal, Occult Scroll)
- [ ] Create `ItemData.tres` for other items (Light Rune, Pure Water, Torch)
- [ ] Implement Light Rune: places a blocked-tile marker like Bastion (see M9) but
      uses 1 of the item's remaining uses per placement
- [ ] Implement Pure Water and Ward staff: apply `add_modifier("resistance", 7, "pure_water", -1, "map_turn")`
      where duration counts down by 1 each full round until reaching 0
- [ ] Implement Torch: `add_modifier("line_of_sight", 4, "torch", -1, "map_turn")` with same countdown
- [ ] Verify: no item causes a crash if used when the relevant Phase 2 system is not yet
      fully implemented — all stub paths must print a warning and no-op gracefully

### Checklist — M11

- [ ] All class `.tres` files load in DataManager without errors
- [ ] All weapon `.tres` files load without errors; Brave weapons have `strikes_per_attack = 2`
- [ ] All skill `.tres` files load without errors
- [ ] All item `.tres` files load without errors
- [ ] Equip item slot logic enforces 1-at-a-time limit
- [ ] Verify a promoted Cavalier can be created with the correct proficiency choice flow
- [ ] Verify Dancer has no promotion option in the class data

---

## Milestone 12 — Laguz System `[DEFERRED]`

**Goal:** Full Laguz gameplay. Laguz units have a functional shift gauge that fills and
drains each turn and per combat. They can shift to animal form gaining stat boosts and
natural weapons, and shift back. All Laguz-specific skills are active. Laguz items work.
**Test:** Play a map with one Laguz unit. Verify gauge fills in humanoid form, shifts on
confirm, stats update, natural weapon equips, and gauge drains in animal form. Verify
all Laguz class skills trigger correctly.

**Pre-condition:** M11 complete (all Laguz data `.tres` files exist).

### Data architecture (Laguz fields already on UnitData and ClassData — see GDD_01)

No new fields required. All shift gauge parameters live in `ClassData`. Runtime state
(`shift_gauge`, `is_shifted`) lives in `UnitData` and is already included in snapshots.

### Shift gauge system

```gdscript
# In TurnManager.start_player_phase() and per-enemy-turn:
func _tick_shift_gauge(unit: Node) -> void:
    if not unit.data.shift_profile_id:
        return  # not a Laguz
    var class_data: ClassData = DataManager.get_class_data(unit.data.shift_profile_id)
    if unit.data.is_shifted:
        unit.data.shift_gauge -= class_data.shift_gain_per_turn_animal
    else:
        unit.data.shift_gauge += class_data.shift_gain_per_turn_humanoid
    unit.data.shift_gauge = clamp(unit.data.shift_gauge, 0, class_data.max_shift_gauge)
    # Force-shift or force-unshift at gauge limits:
    if unit.data.is_shifted and unit.data.shift_gauge == 0:
        _unshift(unit)
    EventBus.shift_gauge_changed.emit(unit, unit.data.shift_gauge)

# Per-combat gauge change (call from CombatResolver after exchange resolves):
func _apply_combat_shift_change(unit: Node) -> void:
    var class_data: ClassData = DataManager.get_class_data(unit.data.shift_profile_id)
    if unit.data.is_shifted:
        unit.data.shift_gauge -= class_data.shift_gain_per_combat_animal
    else:
        unit.data.shift_gauge += class_data.shift_gain_per_combat_humanoid
    unit.data.shift_gauge = clamp(unit.data.shift_gauge, 0, class_data.max_shift_gauge)
    if unit.data.is_shifted and unit.data.shift_gauge == 0:
        _unshift(unit)
    EventBus.shift_gauge_changed.emit(unit, unit.data.shift_gauge)
```

### Shifting — form change

```gdscript
func _shift(unit: Node) -> void:
    # Requires shift_gauge at max (or Feral Instincts active).
    # Applies animal form stat bonuses as active_modifiers with duration = -1, source = "shift".
    var class_data: ClassData = DataManager.get_class_data(unit.data.shift_profile_id)
    var pct: float = class_data.animal_stat_bonus_pct  # 0.5 normally; 0.25 with Feral Instincts
    for stat in ["strength", "magic", "defense", "resistance", "skill", "speed"]:
        var base: int = unit.data.get(stat)
        unit.add_modifier(stat, floor(base * pct), "shift", -1, "permanent")
    # CON boost:
    unit.add_modifier("constitution", floor(unit.data.constitution * class_data.animal_con_bonus_pct),
                       "shift_con", -1, "permanent")
    # MOV +2:
    unit.add_modifier("movement", 2, "shift_mov", -1, "permanent")
    unit.data.is_shifted = true
    SkillHandler.apply_trigger(unit, "on_shift", {})
    EventBus.unit_shifted.emit(unit, true)

func _unshift(unit: Node) -> void:
    unit.remove_modifier("shift")
    unit.remove_modifier("shift_con")
    unit.remove_modifier("shift_mov")
    unit.data.is_shifted = false
    SkillHandler.apply_trigger(unit, "on_shift", {})
    EventBus.unit_shifted.emit(unit, false)
```

### Natural weapons

```gdscript
# In Unit.get_equipped_weapon():
# When unit.data.is_shifted, return the natural weapon for the unit's wexp rank.
func get_equipped_weapon() -> WeaponData:
    if data.is_shifted and data.shift_profile_id:
        var class_data: ClassData = DataManager.get_class_data(data.shift_profile_id)
        var weapon_type: String = class_data.natural_weapon_type  # "fang" | "claw" | etc.
        var rank: String = _get_weapon_rank(weapon_type)
        # Look up the natural weapon matching type + rank:
        return DataManager.get_natural_weapon(weapon_type, rank)
    # Standard equipped weapon logic:
    for entry in data.inventory:
        if entry["type"] == "weapon" and entry["uses_remaining"] > 0:
            var weapon := DataManager.get_weapon(entry["weapon_id"])
            if weapon and can_equip(weapon):
                return weapon
    return null
```

### Humanoid Laguz combat restriction

```gdscript
# In CombatResolver._build_combat_context():
# A Laguz in humanoid form can ONLY counterattack — they cannot initiate.
# Check: if attacker.data.shift_profile_id and not attacker.data.is_shifted:
#    this unit may not initiate combat. Enforce in MapCursor._on_confirm():
#    the Attack option is hidden if acting unit is an unshifted Laguz.
# This unit CAN appear as the defender and counter using their natural weapon IF shifted,
# or cannot counter at all if humanoid (no weapon to counter with).
```

### Laguz-specific action: Shift

- Add "Shift" to `ActionMenu` when the acting unit has `shift_profile_id` set.
- Shifting is a free action (does not end turn) if the gauge is at maximum.
- Feral Instincts allows shifting at any gauge level (at reduced bonus; see skill).
- Unshifting is always a free action.

### Laguz items

- **Laguz Stone**: adds `shift_gain_per_turn_humanoid × 2` to shift gauge (simulates 1 round
  in humanoid form). Does not shift the unit directly.
- **Laguz Pearl**: fills gauge to maximum. Does not shift.
- **Laguz Gem**: fills gauge to maximum (3 uses).
- All three: implement in the item use handler. Emit `EventBus.shift_gauge_changed`.

### Primal Tenacity skill

At the end of each map, if the unit has Primal Tenacity, save `shift_gauge` to
`UnitData` (already stored there). On next map load, instead of resetting
`shift_gauge` to `class_data.shift_gauge_start`, use the saved value.
Add a flag check in `GameMap._ready()` after spawning units.

### Laguz-specific skills — full implementation

- [ ] Implement `"feral_instincts"`: reduces bonus to 25% (`pct = 0.25` in `_shift()`);
      reduces MOV bonus by 1 (`add_modifier("movement", 1, ...)` instead of 2); allows
      shifting at any gauge level; EXP gain is halved while shifted (check in `Unit.add_exp()`)
- [ ] Implement `"wildheart"`: add 5 to `unit.data.shift_gauge` at map start (can stack;
      check count of "wildheart" in skills array and multiply)
- [ ] Implement `"primal_tenacity"`: preserve shift gauge between maps (see above)
- [ ] Implement `"untamed_persistence"`: add +2 to `shift_gain_per_turn_humanoid` at
      runtime (per instance of the skill in the skills array)
- [ ] Implement `"nimble"` (Cat): `get_move_cost_override` returns 1 for all non-wall terrain
- [ ] Implement `"tailwind"` (Hawk): aura skill — already wired in M9; activate now
- [ ] Implement `"grace"` (Heron): `start_of_turn`; adjacent allies heal MAG HP
- [ ] Implement `"reverberate"` (Heron): when Heron is in animal form and Canto is used,
      target ALL adjacent allies rather than 1
- [ ] Implement `"pounce"` (Cat occult): `player_activated`; after movement in a straight
      line, swap positions with enemy at the end of that line; make 3 consecutive attacks
      instead of normal attacks; resolved via `resolve_combat` called 3 times with
      counterattack suppressed on attacks 2 and 3
- [ ] Implement `"hit_and_run"` (Hawk occult): already specced in M9; ensure the
      "move after combat" hook respects Hawk's flying movement rules
- [ ] Implement `"ancient_verse"` (Heron occult): `player_activated`; replaces Canto;
      presents 3 choices — heal MAG HP, grant +DEF/RES equal to ¼ LUK, or restore
      2 weapon uses to equipped weapon
- [ ] Implement `"vortex"` (Raven promotion): `player_activated`; attack as though using
      an Elwind of rank equal to highest proficiency, calculated with SKL instead of MAG
      for damage, without needing the tome or proficiency
- [ ] Implement `"rend"` (Tiger promotion): `player_activated` before attack; crit is
      reduced to 0 and weapon Mt is doubled for that attack
- [ ] Implement `"roar"` (Tiger occult): `on_attack` STR/2%; deal 3× STR damage and
      inflict Stun on defender (requires M8)
- [ ] Implement `"beastbane"` (Taguel): +50 Hit/Dodge vs Beast, Mounted, or Armoured units
- [ ] Implement `"stoneborn"` (Taguel occult): `start_of_turn` while shifted; SKL/2%;
      choose 1 enemy within 2 spaces; apply `add_modifier("defense", -4, "stoneborn", 1, "turn")`
      and same for RES
- [ ] Implement `"dragonskin"` (Manakete): already specced in M9; activate here
- [ ] Implement `"wyrmsbane"` (Manakete occult): +50 Hit/Dodge vs Dragon, Mounted, Armoured

### HUD — Shift Gauge display

```gdscript
# New UI element in HUD.tscn: ShiftGaugePanel (CanvasLayer child)
# Only visible when selected unit has shift_profile_id set.
# Shows:
#   - Gauge fill bar (shift_gauge / max_shift_gauge)
#   - Current form label ("Humanoid" / "Animal")
#   - Animal-form stat preview (what stats will be in animal form)
# Updates on EventBus.shift_gauge_changed signal.
# [PLACEHOLDER visual — use a ProgressBar for MVP of this milestone]
```

### New EventBus signals for Laguz

```gdscript
signal shift_gauge_changed(unit: Node, new_value: int)
signal unit_shifted(unit: Node, is_animal_form: bool)
```

### Checklist — M12

- [ ] Add `shift_gauge_changed` and `unit_shifted` signals to `EventBus.gd`
- [ ] Implement `_tick_shift_gauge()` in TurnManager, called for each unit at turn start
- [ ] Implement `_apply_combat_shift_change()` in TurnManager; hook into
      `CombatResolver.resolve_combat()` post-resolution
- [ ] Implement `_shift()` and `_unshift()` in TurnManager or a new `LaguzManager.gd` autoload
- [ ] Implement `Unit.get_equipped_weapon()` Laguz branch with rank-matched natural weapon
- [ ] Add `DataManager.get_natural_weapon(type, rank)` lookup method
- [ ] Enforce humanoid Laguz combat restriction in `MapCursor` and `ActionMenu`
- [ ] Add "Shift" option to `ActionMenu` for Laguz units
- [ ] Implement gauge-at-max check for standard shift; Feral Instincts bypass
- [ ] Implement all 3 Laguz item effects (Stone, Pearl, Gem)
- [ ] Implement Primal Tenacity gauge preservation (save/load between maps)
- [ ] Create `ShiftGaugePanel` UI scene and script `[PLACEHOLDER visual]`
- [ ] Wire `ShiftGaugePanel` to `shift_gauge_changed` signal
- [ ] Implement all Laguz class skills listed above
- [ ] Verify: Cat gauge fills and drains at correct per-turn and per-combat rates
- [ ] Verify: shift applies correct +50% (or +25% with Feral Instincts) stat modifiers
- [ ] Verify: natural weapons match the correct rank based on wexp
- [ ] Verify: unshifted Laguz cannot initiate combat
- [ ] Verify: Reverberate causes Canto to target all adjacent allies when Heron is shifted
- [ ] Verify: Primal Tenacity preserves gauge value correctly between two maps
- [ ] Verify: Wildheart stacks correctly with multiple copies of the skill
- [ ] Verify: a Taguel and Manakete function identically to standard Laguz in terms of
      gauge mechanics, using their Beaststone/Dragonstone weapons in animal form

---

## Milestone 13 — Awakening Supplement `[DEFERRED]`

**Goal:** All Awakening classes, skills, and rules are fully functional. The Lord,
Tactician, Dancer, Villager, Dark Mage, Barbarian, Taguel, and Manakete class lines
are playable alongside all Awakening promoted classes. All Awakening skills work.
**Test:** Play a map with a full Awakening roster. Verify every class-specific skill
triggers. Verify Galeforce does not infinite-loop.

**Pre-condition:** M11 and M12 complete.

### New game rules from the Awakening supplement

The following rules differences from the base handbook must be enforced:

- **Dark Mage** is distinct from **Druid** — same Dark proficiency, different base stats
  and skill line (Anathema starting skill, Vengeance/Tomebreaker or Lifetaker/Shadowgift
  on promotion). No code change required — handled by ClassData.
- **Barbarian** promotes to Berserker or Warrior (same promoted classes as Brigand).
  Add `"berserker"` and `"warrior"` to `Barbarian.promotes_to`.
- **Dark Knight** is an alternate promotion for **Mage** in addition to Mage Knight and
  Sage. Add `"dark_knight"` to `Mage.promotes_to`.
- **Dancer** does not promote. Enforce by leaving `promotes_to` empty and hiding the
  promotion option in UI when `promotes_to.is_empty()`.
- **Villager** promotes at GM discretion to any non-mounted non-magical class.
  Implement as a runtime class selection presented to the player at promotion,
  filtered by the allowed class list. Store the chosen promoted class in UnitData.
- **Griffon Rider** does NOT have the Dragon special quality. Verify ClassData.
- **Master Seal** works on all Beorc classes including Awakening additions.
- **Laguz Seal** works on Taguel and Manakete in addition to standard Laguz.

### Awakening class-specific skills

All data files created in M11. Wire effect_id implementations here for any
class skills not already implemented in M9:

- [ ] Verify `"veteran"` (Tactician) is implemented and working (from M9)
- [ ] Verify `"rightful_king"` (Great Lord) activation bonus is working (from M9)
- [ ] Verify `"ignis"` (Grandmaster) is implemented (from M9)
- [ ] Verify `"anathema"` (Dark Mage) aura is working (from M9)
- [ ] Verify `"vengeance"` (Sorcerer) is implemented (from M9)
- [ ] Verify `"tomebreaker"` (Sorcerer) is working (Breaker family from M9)
- [ ] Verify `"lifetaker"` (Dark Knight) is implemented (from M9)
- [ ] Implement `"shadowgift"` (Dark Knight/Sorcerer occult): allows equipping Dark tomes
      regardless of proficiency. Add a check in `Unit.can_equip()`: if unit has Shadowgift
      and weapon type is "dark" or any dark-type, bypass the proficiency rank check
- [ ] Verify `"beastbane"` (Taguel) and `"stoneborn"` are implemented (from M12)
- [ ] Verify `"dragonskin"` (Manakete) and `"wyrmsbane"` are implemented (from M12)
- [ ] Verify `"special_dance"` (Dancer) is implemented (from M10)
- [ ] Verify `"charm"` (Lord/Bride) is implemented (from M9)
- [ ] Verify `"galeforce"` (Dark Flier) is implemented and respects once-per-map-turn limit
- [ ] Verify `"sol"` (War Monk/War Cleric) is implemented (from M9)
- [ ] Verify `"acrobat"` (Trickster) movement override is working (from M9)
- [ ] Verify `"pass"` (Trickster occult) movement override is working (from M9)
- [ ] Verify `"aggressor"` (Dread Fighter) applies correctly on initiation (from M9)
- [ ] Verify `"swordfaire"` (Dread Fighter occult) works (Faire family from M9)
- [ ] Implement `"deliverer"` (Griffon Rider): grant Savior effect (no rescue penalties)
      plus no MOV penalty while rescuing. Verify Savior is implemented; if so, Deliverer
      reuses the same modifier logic
- [ ] Verify `"lancebreaker"` (Griffon Rider occult) is working (Breaker family from M9)
- [ ] Verify `"odd_rhythm"` (War Monk) is implemented (from M9)
- [ ] Verify `"rally_magic"` (Dark Flier occult) is implemented (Rally family from M10)

### Promotion options for existing classes

- [ ] Update `Mage.promotes_to` to include `"dark_knight"` option
- [ ] Update `Brigand.promotes_to` to verify it includes both Berserker and Warrior
- [ ] Add `Barbarian.promotes_to = ["berserker", "warrior"]`
- [ ] Update any UI that lists promotion choices to handle classes with 3+ options

### Checklist — M13

- [ ] All Awakening class data verified in editor Inspector
- [ ] Dancer promotion restriction enforced in UI
- [ ] Villager runtime promotion class-selection UI implemented
- [ ] Shadowgift bypasses Dark tome proficiency check correctly
- [ ] Dark Knight available as Mage promotion option in UI
- [ ] Griffon Rider confirmed to lack Dragon special quality in ClassData
- [ ] All Awakening skills verified functional via test play
- [ ] Galeforce verified it cannot trigger more than once per map turn even with
      multiple kills during an extra turn
- [ ] Laguz Seal functions on Taguel and Manakete
- [ ] Verify: no skill or class change causes an error when a unit with that class/skill
      is serialized and deserialized for the mid-battle suspend save

---

## Milestone 14 — Faction System

**Goal:** Replace the two-team player/enemy binary with a **data-driven, N-faction
model**: multiple armies, alliance-based hostility, a configurable turn order, and a
per-faction *controller*. All factions are AI-controlled in this milestone — human
controllers are added in M15. The default configuration is the four armies **blue**
(player), **green**, **red**, **yellow**, with turn order `blue → green → red → yellow`.

> **Current state (2026-06-11):** The faction model, hostility rules,
> per-faction dispatch, scheduler, data/content, and tests are complete.
> Tactical target scoring by HP, strength, terrain danger, and objective
> criticality is deferred to its own AI task and is not part of M14 completion.

Full design rationale, the architecture-seam analysis, and the staged breakdown live
in `AGENT/Docs/second_player_control_feasibility.md` (§§2–5, 9). This milestone is
stages 1–4 + content of that document.

**Supersedes** the Phase 3 Backlog item "Ally NPC phase" — green allies are a faction,
not a bolted-on phase.

**Test:** A map with blue + AI green + AI red + AI yellow plays a full battle. Green
attacks red and yellow but never blue; yellow attacks everyone; turn order is
blue → green → red → yellow; per-group victory/defeat resolves with correct standings.

> **Sequencing.** Stages 1–3 are behaviour-neutral refactors guarded by the existing
> test suite (default `WHOLE_PHASE` activation mode + still 2 factions = today's
> behaviour). They are the **lowest-risk foundation and are built first** — M16 and
> all of M8/M9/M10 depend on them. Per Decision 10 (decisions log 2026-05-17), **M16
> lands between M14 stage 3 and stages 4–5**: stage 4's AI objective-criticality
> scoring reads M16 objective data. The "M14" number reflects feature grouping,
> **not** strict build order — see the implementation order in the Status Snapshot.

### Stage 1 — Faction-relative refactor (behaviour-neutral)

Replace every hardcoded `"player"` comparison with an "active controlling faction"
concept threaded through `MapCursor` and its slices. Affected: `MapCursorSelection`
(unit select), `MapCursorTargeting` (target validity), `TurnManager` (READY reset,
end-turn gate), and `CombatResolver.is_player_initiated` → `is_initiator` / attacker
faction. No behaviour change; the suite stays green.

### Stage 2 — Hostility model (behaviour-neutral)

Add an **alliance-group** hostility helper: each faction declares a group; two units
are hostile iff in different groups. Default groups: `{blue, green}`, `{red}`,
`{yellow}`. Rewrite "attackable / healable / blocks movement" in `GridManager`,
`MapCursorTargeting`, and `EnemyAI` to query it. Still two factions here, so still
behaviour-neutral.

### Stage 3 — N-faction core, data-driven

A faction is **data**, not a code enum — a faction resource/list carrying `id`,
display colour, alliance group, and controller. `GameState` gains per-faction unit
buckets + `get_living_units_of(faction)`.

`TurnManager` is rebuilt as an **activation scheduler**, not a fixed phase cycle —
its primitive is `activate_one_unit(faction)`, and a pluggable "who activates next?"
policy drives an arbitrary-length cycle (see decisions log 2026-05-17, Decision 9):
- `MapData.activation_mode` = `WHOLE_PHASE | ALTERNATING`, **default `WHOLE_PHASE`**.
- **`WHOLE_PHASE`** — exhaust one faction's units, then advance (FE-style
  I-Go-You-Go; the baseline, keeps all existing specs valid).
- **`ALTERNATING`** — advance to the next faction after every single unit; when all
  units have acted, the round counter advances and all units refresh.
- The configurable per-map turn-order list (default `blue → green → red → yellow`)
  is the phase order in whole-phase mode / the round-robin order in alternating
  mode. The cycle skips any faction with zero living units.

Building this data-driven is what makes a 5th+ faction pure data later (feasibility
doc §9).

### Stage 4 — Faction-agnostic AI Dispatch

`EnemyAI` runs for any AI-controlled faction and targets hostile units through
the alliance model. Advanced tactical scoring (target HP/strength, terrain
danger, and objective criticality) is a separate deferred AI task.

### Content & UX

Green/yellow spawns + per-unit faction tags in `MapData`; faction colour and
phase-banner label **read from faction data**, never hardcoded per army. `PhaseBanner`
and any turn-order display built to list N factions.

### Related — objective system (Milestone 16)

Green-specific win/lose conditions (a green unit must escape; a green unit's death is
a blue defeat) need the richer per-map objective system — now **Milestone 16**, which
also unblocks Maps 002–005 (Seize / Boss / Escape / Survive). M16 is independent of
M14's plumbing, but M14 maps using green objectives depend on M16; land M16 before or
alongside M14's green-objective content.

### Checklist — M14

- [x] Stage 1: replace literal `"player"` in `MapCursorSelection`,
      `MapCursorTargeting`, `TurnManager`; suite stays green
- [x] Stage 1: `CombatResolver.is_player_initiated` → `is_initiator` / attacker faction
- [x] Stage 2: alliance-group hostility helper; default groups `{blue,green} {red} {yellow}`
- [x] Stage 2: `GridManager` / `MapCursorTargeting` / `EnemyAI` query the hostility model
- [x] Stage 3: faction defined as data (id, colour, alliance group, controller)
- [x] Stage 3: `GameState` per-faction unit buckets + `get_living_units_of()`
- [x] Stage 3: `TurnManager` rebuilt as an activation scheduler — primitive
      `activate_one_unit(faction)` + pluggable scheduling policy
- [x] Stage 3: `MapData.activation_mode` (`WHOLE_PHASE | ALTERNATING`, default
      `WHOLE_PHASE`); whole-phase + alternating policies; configurable per-map
      turn-order list, default `blue → green → red → yellow`; skips zero-unit factions
- [x] Stage 3: player controller branches on mode (whole-phase keeps End Turn;
      alternating returns control after one committed unit)
- [x] Stage 3: `_begin_phase` timing mode-aware (army-phase start vs round start)
- [x] Stage 4: faction-agnostic AI dispatch for all hostile units
- [ ] Separate tactical-AI task: HP / strength / terrain danger / objective-critical scoring
- [x] Content: green + yellow spawns and per-unit faction tags in `MapData`
- [x] UX: faction colour + `PhaseBanner` label read from faction data, N-faction-ready
- [x] Verify: green attacks red/yellow, never blue; yellow attacks all
- [x] Verify: a map omitting green or yellow runs correctly (cycle skips it)
- [x] Verify: both activation modes run correctly (whole-phase and alternating)
- [x] Tests for the hostility model, both scheduling policies, and AI dispatch

---

## Milestone 15 — Hotseat & Remote Control

**Goal:** Let any **non-blue** faction be controlled by a human instead of AI — first
locally via **hotseat**, later over the network via **remote play**. Blue is always
human (player 1). Builds directly on the M14 controller abstraction; adds two new
controller types alongside the existing `AI`.

Design rationale: feasibility doc §§3.3, 5 (stages 6, 8).

**Depends on M14.**

### Part A — Hotseat (shipping target)

> **Current state (refreshed 2026-06-11).** Core Part-A implementation landed on
> 2026-05-21 (controller seam, `HotseatController`, generic phase commit flow,
> cursor faction handoff, tests). The detailed build/test plan in
> `AGENT/Docs/implementation_plan_2026-05-21.md` remains the reference for the
> architecture and validation scope. The WHOLE_PHASE validation map/launch path
> and `Faction - Controller` HUD/banner text are implemented. Remaining Part-A
> work is the manual acceptance checklist in `AGENT/Docs/manual_test_playbook.md`.
>
> Part A is scoped to **WHOLE_PHASE maps only**; `ALTERNATING` hotseat remains
> deferred. The `grant_extra_turn` checklist item below is still **blocked on M10**
> because that feature does not exist in the codebase yet.

#### Locked design decisions — 2026-05-25 review

These four Part-A open questions from the planning notes were resolved before
implementation begins. See `AGENT/Docs/campaign_rules_firming_notes_2026-05-25.md`.

- **Per-player keybindings — skip for Part A.** All hotseat slots share the
  existing single `InputMap` action set. Per-player keybinding profiles are
  deferred to the same later backlog item that picks up split-controller /
  shared-couch co-op. `WHOLE_PHASE` hotseat means only one player interacts at
  a time on one keyboard, so personal binds add no value yet.
- **Hotseat assignment — per-map data.** A map's `.tres` declares each
  faction's controller (`AI` or `HOTSEAT`). The proposed CLI/dev override is
  deferred. **No pre-battle lobby UI in Part A**.
- **HUD controller label — `Faction - Controller` text.** The active phase
  banner reads e.g. `Red - Player 2` or `Green - AI`. Faction-first matches
  the in-game identity; the controller half eliminates the "whose turn is it?"
  ambiguity for hotseat sessions. Icons are optional decoration but must not
  replace the text.
- **`ALTERNATING` hotseat — fully out of Part A.** No code path in Part A may
  rely on `ALTERNATING` behaviour. `ALTERNATING` is revisited only after the
  extra-turn / activation-scheduler work is settled (the scheduler may simplify
  or eliminate the special case altogether).

Controller types `AI | HOTSEAT`. A `HOTSEAT` faction's activations are driven through
the existing `MapCursor` instead of the AI — the cursor is *not* locked for a
human-controlled non-blue faction. Control hand-off follows the map's
`activation_mode` (Decision 9): in `WHOLE_PHASE` the hotseat player drives the whole
faction phase and End Turn hands off; in `ALTERNATING` control passes after each
committed unit. Shared screen, turns alternate (natural for turn-based tactics).

*Optional polish:* per-phase keybindings — each hotseat slot gets its own `InputMap`
action set (`p2_cursor_up`, …); `MapCursorInput` is told which set to read. Because
phases alternate rather than run simultaneously, shared keys already work — this is a
convenience, not a requirement.

**Test:** Assign green to a hotseat slot; a second person plays the green phase via
the cursor while red and yellow remain AI. Verify the cursor drives green units,
End Turn passes to the red phase, and blue play is unaffected.

### Part B — Remote Play `[DEFERRED]`

A `REMOTE` controller type: the faction's phase awaits a remote player's committed
actions instead of a local `MapCursor`. The phase-boundary seam makes the *hook*
trivial; the real work is networking, and it splits into two distinct jumps.

**Hotseat → LAN — the hard architectural jump** (one game instance becomes two that
must agree):
- *Sync model.* Use the ratified host-authoritative client-server model. The
  host owns simulation truth, validates commands, and broadcasts results.
- *Command layer.* Today a turn is imperative `MapCursor` calls resolved locally.
  LAN needs each faction's turn serialised as committed **commands** (move unit→tile,
  attack, use item) sent and re-applied on the other machine.
- *Determinism.* Combat RNG (hit / crit rolls) must be seeded and synchronised, or
  all rolls resolved host-side — the sim must produce identical results on both peers.
- *Animation replay.* The remote machine replays the opponent's moves from the
  command stream rather than teleporting units.
- *Phase handoff over the wire.* The `REMOTE` controller awaits a "phase committed"
  network message in place of a local controller.

**LAN → online — mostly infrastructure, not gameplay** (the architecture above
carries over unchanged):
- *Connectivity.* NAT traversal / port forwarding / relay servers plus matchmaking —
  a backend service, where LAN needed none.
- *Disconnect & reconnect.* Internet links drop; a mid-match drop must pause, allow
  reconnect (or AI substitution) and resume from synced state — the biggest online
  item for a turn-based game.
- *Trust.* Online opponents are untrusted; commands must be validated server-side
  (legal-move checks). Hotseat and LAN trust the room.
- *Latency.* Turn-based play tolerates 100 ms+ easily (not real-time); the only cost
  is "waiting for opponent" UI and timeouts — far cheaper than for an action game.
- *Versioning.* Peers must run compatible game versions.

A milestone-sized effort of its own; it gates no other milestone. **Designing
Part A's controller to emit a stream of committed actions per phase** — rather than
only imperative cursor calls — is the single thing that most reduces the LAN jump
later. LAN first, online after.

The full set of online design decisions — synchronization model, transport,
matchmaking, reconnection, trust, army source, and more — is catalogued in
`AGENT/Docs/online_play_design_decisions.md` (20 decisions, D1–D20). **All 20 were
ratified on 2026-05-17** — see `AGENT/Docs/design_decisions_log_2026-05-17.md` for
the recorded outcomes. The decisions that drive Part B's build:
- **Sync model:** host-authoritative client-server (host owns the truth, validates
  and broadcasts) — *not* lockstep, so no determinism burden.
- **Transport:** Godot's high-level multiplayer API over ENet, kept swappable;
  distribution (Steam vs off-Steam) deliberately left undecided.
- **Command layer:** per-action streaming of committed command objects — Part A's
  hotseat controller should emit these from day one.
- **Reconciliation:** full authoritative snapshot each phase (commands stream live
  for presentation; the snapshot is the truth).
- **Disconnect:** pause + reconnect window, then AI substitution or
  save-and-continue; no host migration.
- **Army source:** preset/authored armies (builder & draft are future expansions).

### Checklist — M15

**Part A — Hotseat**

- [ ] Controller enum `AI | HOTSEAT` (kept open for `REMOTE`); per-faction assignment
      sourced from the map's `.tres` defaults, overridable by a CLI/dev flag
      (no lobby UI in Part A)
- [ ] `HOTSEAT` faction phase routes through `MapCursor`, not `run_ai_phase`
- [ ] `MapCursor` not locked during a human-controlled non-blue phase; End Turn ends it
- [ ] `grant_extra_turn` (M10) re-enters the *active controller*, not "the cursor", so
      an extra turn during a hotseat phase is driven correctly
- [ ] HUD phase banner shows `Faction — Controller` text (e.g. `Red — Player 2`,
      `Green — AI`)
- [ ] [Deferred] per-player `InputMap` action sets — skipped in Part A; revisit
      with split-controller co-op
- [ ] No code path may rely on `ALTERNATING` activation mode in Part A
- [ ] Verify: a hotseat player drives their faction; AI factions unaffected
- [ ] Verify: a map with all non-blue factions AI still plays exactly as M14

**Part B — Remote Play `[DEFERRED]`**

- [ ] `REMOTE` controller type; phase awaits remote committed actions
- [ ] State synchronisation between machines
- [ ] Command relay + remote move-animation replay
- [ ] Latency / disconnect handling
- [ ] LAN session setup; (later) online

---

## Milestone 16 — Objective System

**Goal:** Replace the single-`objective_type` map objective with a **multi-condition
objective system** — each map carries typed victory and defeat conditions evaluated
**per aggression group** (`{blue,green}`, `{red}`, `{yellow}`, …), not for blue
alone. The map ends with a **ranked-standings results screen**. This generalizes the
feasibility doc §6 workstream (`AGENT/Docs/second_player_control_feasibility.md`);
the per-group decoupling supersedes §6's blue-centric framing — see decisions log
2026-05-17, Decision 8.

**Test:** maps exercising each condition type, a compound victory (rout red AND
yellow), a green-escape victory, a green-death defeat, and a 3-group match where
groups are eliminated in order, all resolve correctly with the right standings.

> **Sequencing.** M16 **depends on M14 stages 1–3** — per-group victory (Decision 8)
> needs the aggression-group model (stage 2), per-faction unit buckets (stage 3), and
> the activation scheduler (stage 3, for the activation-boundary victory sweep). The
> earlier "M16 independent of M14" framing is superseded. Build M16 immediately after
> M14 stages 1–3, before M14 stages 4–5 (stage 4's AI objective-criticality scoring
> reads M16 data). M14 green-objective maps and Phase 3 Maps 002–005 then ride after
> M16. See decisions log 2026-05-17, Decision 10.

### Current state

> **Current state (2026-06-11):** M16 is shipped. `MapData` carries typed,
> per-group `victory_conditions` and `defeat_conditions`; the generic evaluator
> supports Rout, Defeat Boss, Protect, Turn Limit, Survive, Seize, and Escape,
> with standings and objective HUD output. The legacy single-objective fields
> have been removed.

### Condition model — per aggression group

`MapData` carries **per-group** condition sets: each aggression group has its own
`victory_conditions` and `defeat_conditions` arrays of small typed condition
resources. `check_victory_conditions` becomes a generic evaluator looping every
group: for each group, **victory = AND of its victory conditions; defeat = OR of any
of its defeat conditions.**

Win resolution:
- Meeting a victory condition wins the map for that group.
- Meeting a defeat condition eliminates that group.
- The map also ends when **≤1 group remains** — the last group standing wins.
- All remaining groups eliminated simultaneously → **draw**.
- Rout is never implicit. A group is eliminated only by an authored defeat
  condition. Zero deployed units may remain a valid state for reinforcements or
  for objectives that can still fail without opposition.

`rout`/`seize` author naturally as a group's *defeat*; `escape`/`survive` as the
achiever group's *victory*. Condition types:

- **rout** — a named faction (or group) has zero living units. Compound by listing
  several (rout red AND rout yellow).
- **defeat_boss** — one or more named unit ids are dead.
- **seize** — a unit carrying the `can_seize` tag uses a dedicated **Seize
  action** (an `ActionMenu` entry) while on a named seize tile. The condition
  resource carries the tile id(s); seize eligibility is determined by the
  per-unit `can_seize` tag (2026-05-25 review), not by class and not by a
  per-map allowlist. *Not* passive occupation — see decisions log 2026-05-17,
  Decision 4.
- **escape** — named units reach an escape **zone** (a set of tiles — region /
  edge / doorway; a size-1 zone is a single tile). A named unit on a zone tile
  may pick the **Escape action** from the `ActionMenu` (post-2026-05-20 review —
  H-1 reversed the original auto-fire-on-entry half of Decision 5; see
  decisions log addendum). Picking Escape removes the unit from the map; the
  condition is met when all named units have escaped. May include green units.
- **survive** — a group lasts N turns, or holds a named tile for N turns.
- **protect / unit_survives** — a named unit must stay alive; its death is a defeat
  for its group (may include green units — replaces today's `required_survivor_ids`).
- **turn_limit** — turn count exceeds the limit → defeat for the group it is
  authored on (e.g. the attacker fails to win in time).

A green unit id simply appears in an escape / protect condition like any other unit —
no faction special-casing; allied factions share a group, so they win and lose
together automatically.

### Results screen

At map end, a **ranked-standings** results screen: the winning group first, then the
losing groups ordered by elimination round (1st / 2nd / 3rd / 4th placement); a draw
occupies the top slot. The player is always blue, so the screen leads with a clear
**Victory / Defeat** from blue's group's standpoint, then shows the standings. Each
group records an "eliminated on round N" field to drive the ordering.

**Evaluation trigger model (N-faction cycle).** The evaluator is decoupled from phase
*count* — see decisions log 2026-05-17, Decision 7:
- A **phase-boundary sweep** runs the full evaluator at the start of every faction's
  phase (the catch-all).
- **Event-driven** evaluation also fires right after a death, a Seize action, and an
  escape, so a win/loss registers immediately rather than at the next phase boundary.
- **Round-counter** conditions (`turn_limit`, `survive` N turns) read `turn_number`,
  which increments once per *round* (cycle wrap), not per phase.
- The `_map_over` latch halts the turn cycle at a single chokepoint
  (`advance_to_next_phase`); AI / hotseat controllers also check it to abort a
  decided map early.

### Locked design decisions — 2026-05-25 review (Maps 002–005 followup)

M16 itself is shipped. These five decisions govern the **objective-map followup**
— authoring Maps 002–005 against the implemented condition system. See
`AGENT/Docs/campaign_rules_firming_notes_2026-05-25.md` for the deliberation log.

- **Showcase plan — one map per primary objective type.** Maps 002–005 cover
  exactly the four types implemented in M16: **Seize**, **Defeat Boss**,
  **Escape**, **Survive / Defend** — one map each. The goal is to validate the
  typed condition system through real content; map variety within a type is a
  later authoring pass.
- **Primary objectives — one per early map.** Each of the four maps declares
  **exactly one** primary victory objective for blue (multi-primary and
  optional-secondary objectives are out of scope until the basics are
  validated). Defeat conditions are still varied per map (see below).
- **Allowed seizer — per-unit `can_seize` tag.** Seize eligibility is
  determined by a **tag on the unit's data** (not derived from class, and not
  declared as a per-map `allowed_unit_ids` allowlist). The Seize action is
  available only to units carrying the tag while standing on a configured
  seize tile. Authors set the tag on the relevant lord-class units; new
  characters opt in by being tagged.
- **Escape semantics — alive, removed, no further actions this map.** An
  escaped unit counts as alive for survival/protection conditions, is removed
  from the active board, and may not act further on the current map. (Classic
  FE Escape semantics; matches the typed condition system's expectations.)
- **Authored defeat standard.** Every Phase-3 objective map declares at least
  one authored defeat condition appropriate to the scenario. Rout is authored
  explicitly only when a full wipe should eliminate that group.

### Checklist — M16

- [x] Define typed condition resources for each condition type above
- [x] `MapData`: **per-group** `victory_conditions` + `defeat_conditions` sets
      (inspector-editable)
- [x] `check_victory_conditions` → generic evaluator looping every group
      (per group: AND victory / OR defeat); plus the ≤1-group-standing and draw rules
- [x] Explicit authored Rout defeats; no implicit group elimination
- [x] Per-group "eliminated on round N" tracking to drive standings
- [x] Ranked-standings results screen (winner first, losers by elimination order,
      draw in the top slot; blue-perspective Victory/Defeat header)
- [x] Add a **Seize** entry to `ActionMenu`, gated by "on a seize tile" AND "this
      unit may seize" (decisions log 2026-05-17, Decision 4)
- [x] `escape` zone: explicit Escape action removes units; HUD/turn-order handling for escapees
- [x] Migrate the existing `"rout"` / `turn_limit` / `required_survivor_ids` map(s)
      to the new per-group condition sets
- [x] Objective readout in the HUD lists the active conditions
- [x] Verify: compound victory (rout red AND yellow) resolves only when both are met
- [x] Verify: a green-escape victory and a green-death defeat fire correctly
- [x] Verify: a 3-group match eliminates groups in order with correct standings;
      simultaneous elimination resolves to a draw
- [x] Tests for the evaluator, each condition type, and the standings logic
- [x] Phase 3 Maps 002–005 authored against the condition system — one map
      per primary objective (Seize / Defeat Boss / Escape / Survive-Defend),
      one primary objective each, ≥1 authored defeat condition beyond rout
- [x] Define a `can_seize` tag on `UnitData`; gate the Seize action on the
      tag rather than on class or a per-map allowlist

---

## Phase 3 Backlog (Post-Awakening)

The following items are planned but not yet milestoned. Implement after M13 is stable.

### Code Health (tech debt)

- [ ] **Decompose `DataManager._ready()`** (~525 lines) into named, testable phases
      (`_load_all_resources`, `_validate_cross_references`, `_build_default_roster`,
      `_dedup_unit_ids`). Behavior-preserving refactor for readability and unit-testable
      load/validate. Source: code review 2026-06-13 (AGENT/Code Reviews) §2, Medium.

### Content

- [ ] All remaining handbook classes not covered in M11 (GM-discretion additions)
- [ ] Full forging UI and shop system (already architected in Phase 3 backlog)
- [ ] Class promotion UI for classes with 3+ promotion paths

### Systems

- [ ] Firm up the **campaign-rules contract** before building the full save / prep
      loop. `pair_up`, `support`, and `rescue` are campaign rules, not one-off map
      toggles. When the between-map save/load, deployment, convoy, trade, and
      progression-management screens are designed, treat these as part of the same
      contract and answer the open questions in
      `AGENT/Docs/campaign_rules_firming_notes_2026-05-25.md`.
      Each campaign, including a single-map campaign, must be able to author a
      default value for every New Game rule and mark that rule as either
      player-adjustable or designer-locked. Store adjustable selections in that
      campaign save. This ownership model is deliberately deferred from the
      June 2026 playtest bug-fix series; until the campaign layer exists, retain
      the current last-selected New Game behavior.
- [ ] Between-map save / load (Phase 3 backlog)
- [ ] Mid-battle suspend save — full serialization of: all unit `UnitData` (including
      `active_modifiers`, `conditions`, `skill_use_counters`, `shift_gauge`, `is_shifted`),
      all unit tile positions, **activation-scheduler state** (turn-order index /
      next activation, round number, per-unit activation states, the `activation_mode`
      policy, per-group "eliminated on round N"), AI state (which units have acted),
      active Bastion/Light Rune blocked tiles, current map ID. The `UnitData` field
      design (Phase 2 runtime-state fields on `UnitData`, see GDD_01) ensures all
      runtime state is serializable without scene tree traversal. **Note (Decision 10):** M15 Part B's disconnect
      save-and-continue (D14) depends on this — when Part B is built, pull this item
      forward to sit with it rather than leaving it post-M13.
- [ ] Fog of war and LoS (Phase 3 backlog)
- [ ] Rescue and carry system (Phase 3 backlog) — treat rescue availability,
      support bonuses, and Pair Up coexistence as campaign-rule decisions, not a
      map-local ruleset
- [ ] ~~Ally NPC phase (Phase 3 backlog)~~ — **superseded by Milestone 14 (Faction System)**: green allies are a faction, not a bolted-on phase
- [ ] Additional AI profiles: territorial, guard_tile, healer, boss (Phase 3 backlog)
- [ ] Stationary weapon interaction (Ballista/Onager use by player; already have WeaponData)
- [ ] Door and chest interaction system (Pick skill, Unlock staff, Key items)
- [ ] Pre-battle deployment screen — designed together with convoy, trade, campaign
      rules, and save/load ownership so roster/inventory state has one canonical flow
- [ ] Finish cap-management UI. `GameState.max_skills` is enforced for
      auto-equipped learned skills and defaults to 5; manual skill swapping is
      not built. `max_inventory` remains future-facing until trade/inventory UI.
- [ ] Review and productionize `AGENT/Docs/fe_map_sprite_importer_guide.md` — align
      naming/layout assumptions with project asset standards, add validation/error
      handling requirements, and define how imported outputs plug into faction-aware
      runtime data. **Decisions needed before implementation** (raised 2026-05-21):
  - [ ] **Frame size & row order:** the guide hardcodes `FRAME_WIDTH/HEIGHT = 32`
        and a `down/left/right/up` row order. Confirm the canonical frame size
        (tie to `GameConstants.TILE_SIZE`) and direction order, and make both
        exported plugin settings rather than `const`s so a mismatched sheet is a
        config change, not a code edit.
  - [ ] **Output shape vs. the `Unit` scene:** the guide generates a standalone
        `_unit.tscn` (`Node2D + AnimatedSprite2D`) that `GameMap._spawn_unit()`
        cannot consume — real units are the `Unit` scene with `Sprite2D`, HP bar,
        `UnitData`, and faction tint (`apply_faction_visual`). Recommended: import
        generates the `SpriteFrames` `.tres` only, and `Unit` switches from
        `Sprite2D` to `AnimatedSprite2D` to consume it. Do NOT fork the unit
        pipeline by generating whole scenes.
  - [ ] **Folder layout:** the guide proposes `res://assets/raw/` +
        `res://assets/generated/`; the project already splits source under
        `assets/` and resources under `data/`. Decide raw art → `assets/`,
        generated `.tres` → `data/` to match existing conventions.
  - [ ] **Testability:** an `EditorPlugin` button cannot be exercised by the
        headless `run_tests.sh`. Split the importer — region math and filename
        parsing into a plain `RefCounted` covered by headless tests; the
        `EditorPlugin` becomes a thin button that calls it.

### Maps

- [ ] Maps 002–005 per Phase 3 backlog (Seize, Boss Defeat, Escape, Survive/Defend)
      — authored against the Milestone 16 Objective System condition types

### Polish

- [ ] [PLACEHOLDER] All unit sprites and class portraits
- [ ] [PLACEHOLDER] Terrain tile sprites
- [ ] [PLACEHOLDER] UI panel art and Shift Gauge visual
- [ ] [PLACEHOLDER] Combat animations — hit, miss, crit, death
- [ ] [PLACEHOLDER] Skill activation flash effects
- [ ] [PLACEHOLDER] Music per phase and map
- [ ] [PLACEHOLDER] Sound effects (shift, condition apply, skill trigger, etc.)
- [ ] [PLACEHOLDER] Story and dialogue system
- [ ] Steam / itch.io / GitHub release packaging

### UI / UX & Settings

Merged from the playtest findings docs ("Features to add to the to-do list" /
"Add to later milestones"): `AGENT/Docs/playtest2_findings_2026-05-19.md` and
`AGENT/Docs/playtest3_findings_2026-05-19.md`. These are deferred enhancements,
not playtest bugs — the bugs are tracked separately (playtest 2 in
`AGENT/Docs/playtest2_fix_plan_2026-05-19.md`, playtest 3 in the dated code
review under `AGENT/Code Reviews/`).

- [ ] **Range display on hover** — show a unit's movement/attack range when the
      cursor merely hovers over it (transparent overlay), then render it more
      opaque once the unit is actually selected. Needs a second, dimmer overlay
      style alongside the existing solid `OVERLAY_BLUE`/`OVERLAY_RED` tiles.
- [ ] **Movement path arrows** — draw the planned move path as directional
      arrow tiles from the unit to the cursor while in `UNIT_SELECTED`.
      `MapCursorSelection.plan_path_to` already computes the tile list.
- [ ] **Individual unit threat range** — show one enemy's threat area on
      hover/select, distinct from the existing all-enemies danger zone toggle
      (`GridManager.get_enemy_danger_tiles`). Pairs with the hover feature above.
- [ ] **Grid visibility slider** — a setting controlling terrain grid-line
      opacity (0 = hidden). New `SettingsManager` field + `SettingsScreen` row.
- [ ] **Camera settings** — expose camera behaviour in Settings: edge-pan
      buffer distance and scroll responsiveness. (The playtest bug list also
      asks for an adjustable camera buffer — see fix plan item #17; this backlog
      item is the broader settings-screen surface for it.)
- [ ] **Display & accessibility controls** (map zoom, display resolution, text/font
      size, UI layout scale & movement) — **bumped up 2026-06-11**; now scheduled
      right after the current playtest/bug-fix round. The four detailed items moved
      to *Near-Term — Display & Accessibility Controls* under the Status Snapshot.
- [ ] **Key rebinding UI** — the `SettingsScreen` keybinding list is currently
      read-only (built by `_populate_keybindings`). `SettingsManager.rebind_action`
      already exists; this item is the capture UI that calls it. Originally
      deferred to "Phase 2" in Session M notes. (Re-flagged as playtest 3 #19,
      "ability to remap controls" — same feature, no separate entry.)
- [ ] **Full character sheet** — flesh out the unit details / character sheet
      screen (`scripts/ui/UnitDetailsScreen.gd`) with the complete stat block,
      growth rates, class, equipped weapon, and skill list. (Playtest 3 #12.)
- [ ] **"More info" inspection mode** — a toggle button that makes individual UI
      elements (weapon stats, skill descriptions, per-stat explanations, item
      function) selectable. While active, keybindings move a focus highlight
      between elements and surface an info box. Setting: info box appears on
      mouse-hover vs. confirm-click. Pairs with the character sheet above.
      (Playtest 3 #13.)
- [ ] **Gamepad & touch-screen support** — investigate input support beyond
      mouse + keyboard. Scope open — controller rebinding ties into the Key
      rebinding UI above; touch needs an on-screen control surface. (Playtest 3
      #14 — flagged as a question, not yet committed.)
- [ ] **Attack-by-target selection** — let the player initiate combat by
      selecting a valid in-range enemy directly, rather than choosing "Attack"
      from the Action Menu first. (Playtest 3 #15.)
- [ ] **Richer combat prediction** — the combat forecast should also show crit
      chance, weapon-triangle advantage/disadvantage, and effective-damage flags
      (e.g. anti-cavalry). (Playtest 3 #16.)
- [ ] **Combat-prediction layout** — the selected-unit info panel must not
      overlap the combat prediction panel. (Playtest 3 #18.)
- [ ] **Minimap toggle** — bind the minimap to a button instead of leaving it
      always-on / unavailable. (Playtest 3 #20.)
- [x] ~~**Action Menu shrink-to-fit** — hide unavailable actions so the menu
      shrinks, rather than showing greyed-out options.~~ Shipped 2026-05-19,
      pulled forward from the backlog. `ActionMenu.show_for` now sets
      `visible` instead of `disabled`; the VBox collapses the gap so the menu
      auto-shrinks. (Playtest 3 #21.)

### Pre-Release Cleanup

> ⚠️ **RELEASE BLOCKER** — must be cleared before any non-debug build ships.

- [ ] **Remove the playtest 2 debug testing aids.** Two temporary aids were
      added for playtest iteration (see `AGENT/Docs/playtest2_fix_plan_2026-05-19.md`
      items #10 and #11):
      - **#10** — force-level-up on any attack (debug flag in
        `CombatResolver.calculate_exp`).
      - **#11** — inflated MVP-unit stat growths (debug multiplier in
        `Unit._level_up_random` / `_level_up_fixed`).

      Both are gated behind `OS.is_debug_build()` so they cannot affect a
      release build, but the code itself must still be deleted before release
      so it doesn't rot. Grep for `is_debug_build` and the `debug_force_levelup`
      flag to find every site.
- [ ] **Remove the F9 all-faction hotseat debug override.** Added 2026-06-16 for
      midgame AI/debug testing. It is gated by `OS.is_debug_build()` and listed in
      the debug HUD as `hotseat-all`, but it is temporary test plumbing and must be
      removed before a non-debug build ships.

      Files to clean:
      - `project.godot` — `debug_toggle_hotseat_override`
      - `scripts/autoloads/GameState.gd` — `_debug_hotseat_override_v`,
        `debug_hotseat_override`, and the F9 branch in `_unhandled_input`
      - `scripts/core/TurnManager.gd` — `_debug_hotseat_override_latch`,
        `is_debug_hotseat_override_active`, `_debug_hotseat_override_active_for`,
        `_on_debug_flags_changed`, and the override branches in `_controller_for`,
        `is_locally_controlled_faction`, and `start_enemy_phase`
      - `scripts/core/EnemyAI.gd` — `_debug_hotseat_override_active` and the AI abort
        checkpoints
      - `scripts/core/HotseatController.gd`, `scripts/core/MapCursor.gd`, and
        `scripts/core/MapCursorTargeting.gd` — transient-control cancellation helpers
      - `scripts/ui/HUD.gd` — `hotseat-all` debug banner aid
      - Tests: `test_turn_manager.gd`, `test_enemy_ai.gd`, `test_map_cursor.gd`,
        and `test_hud.gd` F9 coverage
- [ ] **Remove the debug-mode HUD banner.** A red "DEBUG MODE" label is shown
      on the HUD whenever `OS.is_debug_build()` is true, listing which debug
      aids (force-levelup, growth-boost, hotseat-all) are flipped on so playtesters
      know the stats on screen may not reflect release behaviour. It is gated on
      `OS.is_debug_build()` and never appears in a release build, but the code
      must still be deleted before release. The banner is an N-file ecosystem —
      delete every site below. Added 2026-05-19; extended 2026-05-19.

      Files to clean (grep anchors after each):
      - `scenes/ui/HUD.tscn` — `DebugLabel` node
        (grep: `DebugLabel`)
      - `scripts/ui/HUD.gd` — `@onready _debug_label`, `_setup_debug_banner`,
        `_refresh_debug_banner`, `_collect_active_debug_aids`,
        `_apply_debug_banner`, the `_setup_debug_banner()` call in `_ready`,
        and the "Debug-mode banner" section header / comment block
        (grep: `_debug_label\|debug_banner\|debug_aids`)
      - `scripts/autoloads/EventBus.gd` — `signal debug_flags_changed()` +
        comment block
        (grep: `debug_flags_changed`)
      - `scripts/autoloads/GameState.gd` — `_debug_force_levelup_v` and
        `_debug_growth_boost_v` / `_debug_hotseat_override_v` backing vars,
        `debug_force_levelup` / `debug_growth_boost` / `debug_hotseat_override`
        getter+setter blocks, and `_emit_debug_flags_changed()`
        (grep: `_debug_force_levelup_v\|_debug_growth_boost_v\|_debug_hotseat_override_v\|debug_flags_changed`)
      - `scripts/tests/test_hud.gd` — the entire suite (or at minimum the
        live-toggle block) and its entry in `run_tests.sh`
        (grep: `test_hud`)

---

## Appendix A — Completion History

Condensed record of shipped items for quick reference. Full verification details in
the linked session notes and commit hashes.

| Item | Shipped | Verification ref |
|---|---|---|
| Playtest 1 — all 13 findings | 2026-05-18 | `AGENT/Docs/manual_test_findings_analysis.md` (all ✅) |
| Playtest 2 — 17 fixes (#1–17) | 2026-05-19 | `AGENT/Session Notes/2026-05-19.md`; one commit per fix |
| Playtest 3 — bugs #1–7, #21 | 2026-05-19 | commits `334a724 … 5b1a87c` |
| Code reviews 2026-05-18/19/19c | 2026-05-20 | All Lows resolved; B-items see Tech Debt rows |
| Playtest 4 — #1 mouse-bump, #2 camera | 2026-05-20 | commits `bad9f24`, `f92899d` |
| B1–B9 — Tech-debt prep (all) | 2026-05-20 | commits `89f370f` … `9d7f2a4` |
| M14 stages 1–3 — Faction refactor | 2026-05-20 | commits `20ef18e`, `c5c9c32`, `0c68254`; suite 426 green |
| M16 — Objective System (5 stages) | 2026-05-20 | commits `316e509` … `8fed076`; legacy fields removed |
| M14 stages 4–5 — AI dispatch + faction content | 2026-05-21 | commits `cca788d`, `bf0d9b1`, `8ea7429`; suite green |
| M15 Part A — Hotseat foundations | 2026-05-21 | commits `1ba6640`, `49f7420`, `4e68cc7`; manual validation pending |
| Class / Skill rebuild — promotion + reclass | 2026-05-21 | commits `ae37743` … `48743b5` |
| Pair Up pass 1 (partial) | 2026-05-22 | commits `5de5103` … `993a413`; DS/DG + forecast deferred |
| More Info phase 1 | 2026-05-24 | commits `5630f40` … `4d0ea2e` |

---

## Appendix B — Work Item Ordering (Bucket Summary)

**Current position:** Phase 2, post-playtest/bug-fix round. Bucket A (playtest bugs)
and B1–B9 (tech-debt prep) are complete. B10 (corpus reconciliation) is the
documentation consolidation work on the `awakening-compatability-refactor` branch.

| Bucket | Items | Status |
|---|---|---|
| A — Open playtest bugs | A1, A2 | ✅ All done |
| B — Tech-debt prep | B1–B9 | ✅ All done; B10 = doc consolidation (this branch) |
| C — Phase 2 milestones | C1–C3 done; C4 (M9a) → C5 (M8) → C6 (M9b) → C7 (M10) → C8 (M11) → C9 (M12, deferred) → C10 (M13, deferred); C11 (M15A, in validation) | See Status Snapshot |
| D — Release gate | D1: remove debug aids | Before any non-debug build ships |
| E — Phase 3 backlog | Forging, fog, rescue, campaign save, additional maps, polish | Post-M13 |

**Dependency graph (key edges):**

```
C1 (M14 s1-3) ──▶ C2 (M16) ──▶ C3 (M14 s4-5) ──▶ C4 (M9a) ──▶ C5 (M8) ──▶ C6 (M9b) ──▶ C7 (M10) ──▶ C8 (M11) ──▶ C9 (M12) ──▶ C10 (M13)
                                      │
                                      └──▶ C11 (M15A) ──▶ C12 (M15B, deferred)

B10 (corpus/doc consolidation) ──▶ C4, C6, C8 (M9a, M9b, M11)

D1 (pre-release cleanup) — gate at release time, not in milestone order
```

---

## Appendix C — Source Documents

| Document | Purpose |
|---|---|
| `AGENT/GDD/GDD_10_Roadmap.md` | **This file** — canonical Phase 2 roadmap, milestone specs, backlog |
| `AGENT/Docs/design_decisions_log_2026-05-17.md` | Decision 10 = ordering rule; design locks |
| `AGENT/GDD/GDD_Feature_Index.md` | Feature → rule owner / roadmap owner routing table (DOC-005) |
| `AGENT/Docs/documentation_lifecycle_2026-06-13.md` | Document lifecycle table (Stage 1 output) |
| `AGENT/Docs/decision_index.md` | All DOC-/RULE-/SET-/OPEN-/RNG-/AWR- decisions (DOC-009) |
| `AGENT/GDD/GDD_Adoption_Matrix.md` | Per-rule corpus adoption status |
| `AGENT/Docs/testing_guide.md` | Test execution and naming conventions |
| `AGENT/Docs/manual_test_playbook.md` | Manual playtest checklists (moved from `AGENT/GDD/` in Stage 5.2) |
