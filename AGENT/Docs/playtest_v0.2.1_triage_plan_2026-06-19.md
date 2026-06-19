# v0.2.1 Playtest Triage and Fix Plan — 2026-06-19

Status: Planned — awaiting approval
Last verified: 2026-06-19

## Scope

Plan-only triage of the returned v0.2.1 playtest package. **No source changes until
the user approves this plan.** Item IDs (`V021-NN`) match the GDD_10 "v0.2.1 findings"
action list.

Evidence:

- Returned checklist (verbatim, archived 2026-06-19):
  `AGENT/Docs/playtest_checklist_v0.2.1_returned_2026-06-19.md`
- Blank handbook the tester filled: `AGENT/Docs/playtest_checklist_v0.2.1.md`

Re-verification result: the v0.2.0 fixes **1.1 / 1.2 / 1.3 / 1.5** passed (camera
jitter, live Map Zoom slider, forecast placement, one-based Seize coordinates). The
v0.2.0 fixes **1.4 (F9)** and **1.6 (HUD reset / terrain)** regressed or were only
partially fixed and come back as `V021-01` and `V021-02/03/04`.

Error log: the Error-log check was returned unmarked with no comment. Treat as
`NOT RUN`; request a rerun note before treating any log line as a defect.

## Triage Summary

**Confirmed bugs (fix before the next build):**

- `V021-01` — F9 hotseat mid-activation desync (AI units don't dim; re-control lets AI
  re-move spent units; mid-move toggle teleports without spending movement).
- `V021-02` — HUD layout editor leaks input (Esc the Settings modal, still drive cursor /
  open menus while editor is open) and reset still misplaces expanded terrain More Info.
- `V021-03` — HUD editor sample text escapes the panel bounds.
- `V021-04` — Resizing the terrain corner in the editor breaks corner-snap.
- `V021-06` — Character-sheet directional selector axis inversion (Up→Left, Down→Right).
- `V021-07` — Map HUD pair-up line: drop the per-stat bonuses, raise the default block so
  `Support: <name>` is not clipped off-screen.
- `V021-08` — Long menus clip top/bottom at large Menu Scale (vertical fit).

**Clarity / content requests:**

- `V021-09` — Pair Up duration wording `(this combat)` → `(until separated)`.
- `V021-10` — Relocate most class-summary detail into the class More Info side panel.
- `V021-11` — Surface class movement type in More Info; reclassify `Light-footed`
  trait → movement type (data-model; needs design decision — see Open Decisions).
- `V021-12` — (stretch) clickable skill info boxes in class More Info via the selector.

**Reopened deferred issues:**

- `V021-13` — Map Menu backdrop click dismisses the menu.
- `V021-14` — Weapon names in the combat preview.
- `V021-15` — Directional More Info selector for the combat forecast + terrain panel.

**Design projects (design before scheduling):**

- `V021-05` — Terrain More Info paging (description vs movement costs on F-flippable
  pages; one page hidden to free map area; extensible).
- `V021-16` — Cancel-over-unselected-unit opens the character sheet.
- `V021-17` — Mouse-only / touch cursor mode (click-to-move-cursor, second click selects;
  terrain page button / click-to-switch in this mode).
- `V021-18` — Crisp scaling rework (resize fonts/metrics instead of zooming the canvas).
- `V021-19` — Native 1440p / 4K resolutions + Steam Deck / mobile / safe-area handling.

## Resolved Decisions (user, 2026-06-19)

1. **Next-build scope → everything, including the design projects.** v0.2.2 takes on the
   confirmed bugs, the content/reopened requests, and the design-project work. The two
   "DESIGN" items get full standalone designs *before* implementation (see Decision 4).
2. **Map HUD pair-up line (V021-07) → remove the stats.** Drop the per-stat bonus line
   from the *map* HUD entirely (the full breakdown stays on the `I` sheet) and raise the
   default unit-info block so `Support: <name>` is not clipped.
3. **Movement type (V021-11) → explicit tags + precedence hierarchy, no new field.** Keep
   movement type as a `special_qualities` tag (the current model). Add an explicit
   **`infantry`** default tag so every class's movement cost is marked rather than
   inferred from absence, and define a **movement-type precedence hierarchy** so a unit
   carrying more than one movement tag (e.g. armoured+flying, mounted+armoured) resolves
   to a single, deterministic movement type for both terrain cost and display. Surface
   the resolved movement type in class More Info. Effectiveness/vulnerability stays on
   `vulnerability_groups`, untouched. (See Workstream C → V021-11 for the proposed
   hierarchy.)
4. **Design depth → full designs for both now.** Write standalone design docs for
   `V021-05` (terrain paging) and `V021-17` (mouse-only / touch mode) before implementing:
   - `AGENT/Docs/terrain_more_info_paging_design_2026-06-19.md`
   - `AGENT/Docs/mouse_only_cursor_mode_design_2026-06-19.md`

## Recommended Order (v0.2.2 — full scope)

1. **Hotseat correctness:** `V021-01`.
2. **HUD editor correctness:** `V021-02`, `V021-03`, `V021-04`.
3. **Character-sheet input + wording:** `V021-06`, `V021-09`.
4. **Map HUD pair-up line:** `V021-07`.
5. **Menu vertical fit:** `V021-08`.
6. **Class More Info + movement type:** `V021-10`, `V021-11`.
7. **Terrain paging (design → build):** `V021-05`, then the directional-selector reuse
   `V021-15`.
8. **Reopened quick wins:** `V021-13`, `V021-14`, `V021-16`.
9. **Larger reworks / platform (later in the build or split out):** `V021-12` (stretch),
   `V021-17` (mouse mode — design now, build after the core), `V021-18` (crisp scaling
   rework), `V021-19` (1440p/4K + safe-area).

This still lands play-blocking bugs first, then the tester-visible UI work, then the
designed systems. `V021-18` (scaling rework) and `V021-19` (multi-res) are the heaviest;
if the build grows too large they are the natural split point into a v0.2.3.

---

## Workstream A — Hotseat Activation State (V021-01)

Tester: manually-moved units stay DONE, but AI-moved units don't dim until phase end;
re-taking control then handing back lets the AI re-move every unit; toggling control
*mid-movement* lands the unit at its destination without spending movement. Tester
recommends rolling state back to the unit's activation start on toggle.

Likely files:

- `scripts/core/TurnManager.gd`
- `scripts/core/HotseatController.gd`
- `scripts/core/EnemyAI.gd`
- `scripts/tests/test_turn_manager.gd`, `scripts/tests/test_enemy_ai.gd`

Likely cause (to confirm):

- The DONE/READY state for AI-moved units is committed at phase end, not at the moment
  the unit finishes its activation, so a mid-phase control handoff sees them as still
  available. The mid-movement teleport suggests movement is applied to the unit's tile
  immediately but the "spent movement / set DONE" bookkeeping happens at the end of an
  interruptible AI step.

Plan:

1. Reproduce headlessly: AI moves unit A (DONE), toggle F9 to player and back, assert A
   stays DONE and is not re-moved.
2. Define an activation boundary: a unit's READY→DONE transition and its committed
   position must both land at activation end, atomically, before the next unit or a
   control handoff.
3. For the mid-movement toggle, either (a) finish/commit the in-flight activation before
   yielding control, or (b) snapshot at activation start and roll back on toggle (tester's
   suggestion). Recommendation: prefer **commit-then-yield** (simpler, deterministic) and
   only fall back to rollback if an activation can be genuinely half-applied.
4. Make AI-moved units dim (set DONE visual) at activation end, matching manual moves.

Open question for implementation: does `EnemyAI` apply movement in a single step or an
animated/tweened sequence that can be interrupted? That determines commit-vs-rollback.

## Workstream B — HUD Layout Editor & Terrain Panel (V021-02/03/04, and design V021-05)

### V021-02 — Editor input leak + reset reflow

Likely files: `scripts/ui/HudLayoutEditor.gd`, `scripts/ui/HUD.gd`,
`scripts/ui/SettingsScreen.gd`, `scripts/tests/test_hud_layout.gd`,
`scripts/tests/test_hud_layout_editor.gd`.

Plan:

1. While the editor is active, capture input so closing the Settings modal does not hand
   raw cursor/menu input back to the map. Either keep a modal guard that blocks
   `MapCursor` input until the editor is dismissed, or make leaving Settings also exit the
   editor. Recommendation: editor is its own modal state; exiting Settings exits the editor.
2. Harden the reset/apply-layout reflow of expanded terrain More Info so repeated
   resize/reset cycles keep it anchored to the compact panel (extend the V020-06 fix with
   the stress sequence the tester found).

### V021-03 — Sample text bounds

Plan: clip/contain editor sample text to the panel rect and position it like the real
readout; keep it editor-only (never leaks into play). `HudLayoutEditor`.

### V021-04 — Corner-snap on resize

Plan: clamp the terrain corner's editor size/offset so it stays seated in its corner and
on-screen; lock max size as the tester suggested if free resize can't stay snapped.
`HUD` corner anchoring + editor bounds. Add a regression test for resized-then-snapped.

### V021-05 — Terrain More Info paging (DESIGN — full doc written)

Full standalone design: `AGENT/Docs/terrain_more_info_paging_design_2026-06-19.md`.
Splits the terrain panel's description / movement-cost / actions content onto `F`-flipped
pages with one page fully hidden to free map area, integrates with the existing
`TerrainCorner/TerrainMoreInfoPanel/Scroll/VBox` nodes and the More Info priority cycle,
and coordinates with V021-15 (terrain selector) and V021-07 (block reposition).

## Workstream C — Character Sheet & More Info (V021-06/09/10/11/12, V021-15)

### V021-06 — Directional selector axis inversion

Likely files: `scripts/ui/UnitDetailsScreen.gd`,
`scripts/tests/test_unit_details_screen.gd`.

Cause (to confirm): the selector treats the entry list as 1-D, mapping Up/Down onto
previous/next which visually reads as Left/Right across a row-major layout. Fix: map
Up/Down to vertical row movement and Left/Right to horizontal, matching the on-screen
grid. Add a test asserting Down moves the `▶` marker to the row below.

### V021-09 — Pair Up duration wording

Likely files: `scripts/shared/StatBreakdown.gd`, `scripts/shared/StatContributions.gd`,
`scripts/tests/test_unit_details_screen.gd`. Change the `"combat"` duration_type render
for Pair Up from `this combat` to `until separated`. Confirm scope: only Pair Up, or all
combat-duration sources? Recommendation: label Pair Up specifically; keep generic
combat-only sources as `this combat`. Update pinned test assertions.

### V021-10 — Relocate class summary into More Info

Likely files: `scripts/ui/UnitDetailsScreen.gd`, `scripts/shared/MoreInfoContent.gd`,
`scripts/resources/ClassData.gd`, `scripts/tests/test_unit_details_screen.gd`,
`scripts/tests/test_more_info_content.gd`. Keep the inline class row compact (display
name + maybe tier); move tier/traits/weapon families/skill unlocks into the class More
Info side panel built from `ClassData`. Update GDD_07.

### V021-11 — Movement type: explicit `infantry` tag + precedence hierarchy

Decision 3: keep movement type as a `special_qualities` tag (no new field). Today the
movement type is inferred — `GridManager.get_move_cost()` checks `has_quality("mounted")`
/ `has_quality("armoured")` / `has_quality("light_footed")` for the desert rule and
otherwise falls through to the base "foot" cost; a unit with none of those tags has no
explicit movement marker. Flying is currently only an effectiveness/vulnerability concept
(`vulnerability_groups`), not a terrain-cost movement class.

Likely files: `scripts/resources/ClassData.gd` (data only), `data/classes/*.tres`,
`scripts/core/GridManager.gd`, `scripts/units/Unit.gd` (`has_quality`),
`scripts/shared/GameConstants.gd`, `scripts/ui/UnitDetailsScreen.gd`,
`scripts/shared/MoreInfoContent.gd`, `scripts/shared/GridManager`/`Unit` tests,
`AGENT/Docs/check_docs.py` (DoD#2 if a movement-type rule is ratified).

Plan:

1. Define the **movement-type set** and add the explicit default `infantry`:
   `flying`, `mounted`, `armoured`, `light_footed`, `infantry` (default). Author the
   correct movement tag into every class's `special_qualities`, including `infantry` for
   the classes that currently have none. (`special_qualities` is not allowlist-validated,
   so no schema break — but add a `VALID_MOVEMENT_TYPES` const in `GameConstants` and a
   resolver, and consider a `check_docs`/test rule that every class declares exactly one
   movement type.)
2. Add a **resolver** `movement_type_of(unit/class) -> String` that returns the single
   highest-precedence movement tag present, defaulting to `infantry`. Proposed precedence
   (highest first, for terrain cost + display): **`flying` > `mounted` > `armoured` >
   `light_footed` > `infantry`**. Rationale: fliers ignore ground terrain so flying wins
   the *cost* resolution; among ground types the mount/armour penalty dominates the
   light bonus. Effectiveness is independent and still reads every tag in
   `vulnerability_groups`, so an "armoured flying" unit is still hit by both anti-armour
   and anti-flying weapons even though its *movement* resolves to flying.
3. Refactor `GridManager.get_move_cost()` / `get_move_costs_for_groups()` to key off the
   resolved movement type instead of ad-hoc `has_quality` checks, and add a `flying` cost
   column (fliers ignore ground costs; river/sea passable) so the set is complete. Keep
   the desert rule (mounted/armoured 3, light 1, infantry/flying per their rule).
4. Surface the resolved movement type as its own line in class More Info (V021-10), and
   stop listing movement tags under the generic `Traits:` line in `UnitDetailsScreen`
   (line 133) so movement type and genuine traits are visually separate.

Open question for implementation: confirm the `flying` cost rule (full ignore vs. a
flat 1) and whether any current class should resolve to a different type than its single
tag implies. No class today carries two movement tags, so the hierarchy is forward-looking
but defined now per the decision.

### V021-12 — (stretch) clickable skill info boxes

After V021-06, let class-skill entries in More Info open their own description boxes via
the same selector. Depends on the selector fix; schedule as stretch.

### V021-15 — Selector for forecast + terrain (reopened)

Extend the character-sheet selector model to the combat forecast and terrain More Info.
Pairs with V021-05 (terrain paging) and V021-06 (selector fix). Reuse the focus model
rather than duplicating per surface.

## Workstream D — Map HUD & Menus (V021-07, V021-08)

### V021-07 — Map HUD pair-up line (Decision 2: remove stats)

Likely files: `scripts/ui/HUD.gd` (`_pairup_bonus_text` / `_show_unit`),
`scripts/tests/test_hud.gd`. Remove the per-stat `Paired +N Str +N Def …` line from the
map HUD entirely (the full breakdown stays on the `I` sheet via `StatContributions`), keep
the `Support: <name>` line from V020-09, and raise the default unit-info block position so
the support line is not clipped off the screen edge. Coordinate the new default block
position with the terrain-panel design (V021-05). Update GDD_07 §UI and the `test_hud`
assertions that currently pin the `Paired +N …` text (they will flip to assert the line is
gone and `Support:` is present).

### V021-08 — Long menus clip at large Menu Scale

Likely files: `scripts/autoloads/SettingsManager.gd` (`_apply_menu_scale`),
menu/modal scenes, `scripts/tests/test_menu_scale.gd`. Menus center horizontally but tall
menus (character sheet) overflow top/bottom at large scale. Fix vertical fit: constrain
scaled menu height to the viewport (scroll or clamp) so the top/bottom stay reachable.
This is the layout-fit half; the rendering-softness half is the separate V021-18 rework.

## Workstream E — Reopened Quick Wins (V021-13, V021-14, V021-16)

### V021-13 — Map Menu backdrop dismiss

Locate the Map Menu scene/script (the `M`-key menu) and add a backdrop click that
dismisses it, matching common modal behavior. Add a test if a headless seam exists.

### V021-14 — Weapon names in combat preview

Likely files: `scripts/ui/AttackPreview.gd`, `scripts/tests/test_attack_preview_*.gd`.
The forecast has the combatants and weapons available (the sheet already renders weapon
stats); add the equipped weapon name for each side to the forecast. Update GDD_07.

### V021-16 — Cancel-over-unit opens the sheet

Likely files: `scripts/core/MapCursor.gd`, `scripts/tests/test_map_cursor.gd`. When
Cancel is pressed (keyboard or mouse) while hovering an unselected unit with no active
selection, open that unit's character sheet. Confirm it does not conflict with existing
Cancel semantics (deselect / close menu).

## Workstream F — Design Projects / Platform (V021-17, V021-18, V021-19)

- `V021-17` mouse-only / touch cursor mode — full standalone design:
  `AGENT/Docs/mouse_only_cursor_mode_design_2026-06-19.md`. Cursor decouples from hover,
  jumps on click, second click selects; terrain page button / click-switch in this mode.
- `V021-18` crisp scaling rework — investigate theme font-size / control-metric scaling
  instead of `content_scale_factor` / node `scale`. Affects Menu Scale and HUD Layout.
- `V021-19` native 1440p / 4K resolutions + Steam Deck / mobile / safe-area insets.
  Ties to OPEN-11 and the Renderer & Platform Targets gate in GDD_10.

## Verification Plan (after approved implementation)

1. `python3 AGENT/Docs/check_docs.py`
2. Focused tests per workstream:
   - `test_turn_manager.gd`, `test_enemy_ai.gd` (V021-01)
   - `test_hud_layout.gd`, `test_hud_layout_editor.gd` (V021-02/03/04)
   - `test_unit_details_screen.gd`, `test_more_info_content.gd` (V021-06/10/11/12)
   - `test_hud.gd` (V021-07), `test_menu_scale.gd` (V021-08)
   - `test_map_cursor.gd` (V021-16), `test_attack_preview_*.gd` (V021-14)
3. Full suite: `TEST_JOBS=8 ./run_tests.sh`
4. Manual Windows retest of the failed items plus the Error-log check (NOT RUN this pass).

## DoD reminders

- Any behavior change updates the matching GDD_01–08 section(s) and flips the GDD_10
  status in the **same** commit (DoD#1).
- Any new mechanical/checkable doc rule lands its `check_docs.py` check in the same
  change (DoD#2).
