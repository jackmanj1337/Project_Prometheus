# v0.2.1 Playtest Triage and Fix Plan — 2026-06-19

Status: Reviewed — approved for implementation (forward-compat review folded in 2026-06-20)
Last verified: 2026-06-20

## Scope

Triage + fix/design plan for the returned v0.2.1 playtest package. **Approved for
implementation** (user, 2026-06-20). The implementation playbook is
`AGENT/Docs/handoff_2026-06-20.md`. Item IDs (`V021-NN`) match the GDD_10 "v0.2.1
findings" action list.

**Build split (decided 2026-06-20):** the work ships as **two builds**:

- **v0.2.2** — bug fixes, tester-visible UI, and the designed systems (terrain paging,
  mouse/touch mode). Most V021 items.
- **v0.2.3 "Display Scaling & Resolution"** — `V021-18` (crisp font/metric scaling
  rework) + `V021-19` (native 1440p/4K + Steam Deck / mobile / safe-area). These two are
  one coupled display system and would otherwise rework the just-shipped v0.2.0 Menu
  Scale; they are split out so v0.2.2 stays shippable.

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
- `V021-11` — Surface class movement type in More Info; formalize movement type as an
  explicit `special_qualities` subset with an `infantry` default + precedence hierarchy
  (Decision 3; corrections in Forward-Compat F3).
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
5. **Split V021-18 + V021-19 into v0.2.3 (2026-06-20).** See the Build split above and
   Forward-Compatibility F4.
6. **V021-01 depth → minimal, principled activation-boundary fix (2026-06-20).** Commit a
   unit's position + DONE state atomically at activation end before any handoff; do **not**
   build a general snapshot/rollback primitive here — that is M15B's call (Forward-Compat
   F1). Veto path open if the tester's full-rollback ask is preferred.
7. **Duration-tag taxonomy (user, 2026-06-20).** Replace the ad-hoc `duration_type`
   strings with a fixed vocabulary (drives V021-09 and is inherited by M8/M9):

   | Tag | Scope |
   | --- | --- |
   | `this combat` | a single attack action — one engagement, **including follow-ups and counters** |
   | `until separated` | persists across combats until a Pair Up splits |
   | `until unequipped` | persists while the granting weapon/item is held/equipped |
   | `until end of map` | persists for the whole chapter |
   | `x turns` | counts down N turns, then expires |

   Re-tag existing sources to the right bucket (see Workstream C → V021-09). `this combat`
   is now narrower than today's catch-all `"combat"`: it means one engagement only, so
   genuinely per-engagement skill/condition procs keep it while Pair Up / tonics / item
   bonuses move to their own tags.

## Recommended Order

### Build v0.2.2 (fixes + UI + designed systems)

1. **Hotseat correctness:** `V021-01` (minimal activation-boundary fix — F1).
2. **HUD editor correctness:** `V021-02`, `V021-03`, `V021-04`.
3. **Character-sheet input + duration vocabulary:** `V021-06`, `V021-09` (taxonomy).
4. **Map HUD pair-up line:** `V021-07`.
5. **Menu vertical fit:** `V021-08` (safe under either scaling model — F4).
6. **Class More Info + movement type:** `V021-10`, `V021-11` (corrected — F3).
7. **Terrain paging → shared selector:** `V021-05`, then `V021-15` built as **one shared
   selector component** (F5).
8. **Reopened quick wins:** `V021-13`, `V021-14`, `V021-16`.
9. **Mouse/touch mode + stretch:** `V021-17` (mobile down-payment — F5), `V021-12` (stretch).

### Build v0.2.3 (Display Scaling & Resolution)

10. `V021-18` (font/metric scaling rework) + `V021-19` (1440p/4K + safe-area), designed
    and built together; ties to OPEN-11 (Steam Deck) and the Renderer & Platform gate.

Play-blocking bugs first, then tester-visible UI, then the designed systems; the heaviest
display rework is isolated in v0.2.3.

---

## Forward-Compatibility Notes (review 2026-06-20)

How these items touch future milestones — build them in the milestone's direction so they
are down-payments, not throwaway fixes.

- **F1 — `V021-01` is M15 architecture.** This is the *second* fix at the hotseat seam
  (after V020-04). The activation-boundary commit it establishes is what **M15B (online
  remote control)** must serialize on handoff, what **M10 (extra-turn = extra activation)**
  inserts into the scheduler, and what **M8 (conditions tick at start of activation; sleep/
  stun set DONE)** keys off. There is already a snapshot/serialization seam (Pair Up
  snapshot persistence; mid-battle suspend save serializes `UnitData`) — extend it, don't
  invent an F9-only path. Decision 6: minimal-principled boundary now; full rollback is M15B.
- **F2 — `V021-09` must not overload `"combat"`.** M8 (Hex) and M9 combat procs use
  `duration_type="combat"`. The new taxonomy (Decision 7) gives Pair Up / tonics / items
  their own tags and reserves `this combat` for one-engagement effects, handing M8/M9 a
  clean vocabulary instead of string-special-casing.
- **F3 — `V021-11` couples to M9 + M12.** `GridManager.get_move_cost()` checks **skill
  overrides first** (Acrobat/Pass/Nimble stubs; M9 `dash`), so the movement-type resolver
  must preserve **skill-override > movement-type cost** ordering. `special_qualities` also
  holds **`dragon`/`beast`/`laguz`** (M12/M13 type tags, *not* movement) — the resolver
  reads only the movement subset and ignores the rest (a Hawk laguz `["laguz","flying"]`
  resolves flying). Corrections: **Great Knight is `["armoured","mounted"]` today**, so the
  hierarchy is load-bearing now, not forward-looking; the DoD check is "**≥1** movement
  type" not "exactly one"; and GDD_03's valid-`special_qualities` list is already missing
  `light_footed` and must be reconciled (+`infantry`).
- **F4 — `V021-18` + `V021-19` re-open just-shipped scaling.** Menu Scale (v0.2.0 V020-16)
  scales Control-node `.scale` with `content_scale_factor=1.0` (raster zoom → blurry).
  Font/metric scaling (V021-18) replaces that mechanism and is the right base for native
  1440p/4K (V021-19). Split into v0.2.3 so v0.2.2 doesn't rework new code twice. `V021-08`
  (vertical clip) stays in v0.2.2 — a scroll/clamp container helps under either model.
- **F5 — input-layer items feed the rebind / input-parity milestone.** `V021-06` (axis),
  `V021-15` (selector on 3 surfaces), `V021-16` (cancel-opens-sheet), `V021-17` (mouse/
  touch mode) are all input changes the **gamepad / key-rebind milestone** (GDD_07
  §Accessibility & Input Parity; known joypad-binding gap) will reconcile. Build `V021-15`
  as **one shared selector component** (single joypad-wiring point later), and treat
  `V021-17`'s `mouse_cursor` tri-state as the first entry in a coherent input-mode concept
  and a **mobile** (deferred platform) down-payment.
- **F6 — `V021-14` / `V021-10` grow the rename surface (awareness only).** Surfacing more
  weapon/class names in the UI adds strings the **Public-Identity Rename Gate (D-A)** must
  rename before first public RC. No action beyond tracking.

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
3. For the mid-movement toggle, **commit-then-yield** (Decision 6): finish/commit the
   in-flight activation (apply move, set DONE) *before* yielding control on an F9 toggle,
   so control never changes hands mid-activation. Do **not** build a general snapshot/
   rollback primitive here — that belongs to M15B (see F1). If `EnemyAI` applies movement
   via an interruptible tween, gate the F9 handoff to fire only on activation boundaries
   (between units), not mid-step.
4. Make AI-moved units dim (set DONE visual) at activation end, matching manual moves.

Forward-compat (F1): the activation boundary this establishes — *position + READY→DONE
commit atomically at activation end, before any control handoff* — is the seam **M15B
(online)** serializes, **M10 (extra activation)** inserts into, and **M8 (sleep/stun set
DONE at start of activation)** keys off. Reuse the existing snapshot/serialization seam
(Pair Up snapshot persistence; suspend-save `UnitData` serialization) rather than a new
F9-only path. This is the second patch at this seam (V020-04 was first); if a third is
needed, escalate to a principled activation-state model under M15.

Open question for implementation: confirm whether `EnemyAI` applies movement in a single
step or an interruptible tween — that decides whether step 3 needs the boundary-gated
handoff. Resolve by reading `EnemyAI` move application before coding.

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

### V021-09 — Duration-tag taxonomy (not just Pair Up wording)

Decision 7 turns this from a one-word relabel into a small `duration_type` vocabulary the
character sheet renders and **M8/M9 inherit** (F2). Today `StatBreakdown.format_duration`
returns `"this combat"` for `duration_type=="combat"`, and Pair Up reaches it with
`duration_type="combat", remaining=-1` (`StatContributions` line ~97) — the same `"combat"`
type M8 Hex and M9 combat procs will use, so a blanket relabel would mislabel them.

Likely files: `scripts/shared/StatBreakdown.gd` (`format_duration`),
`scripts/shared/StatContributions.gd` (source tagging),
`scripts/skills/SkillHandler.gd` / item handlers (modifier duration_type at add time),
`scripts/shared/GameConstants.gd` (vocabulary const), `AGENT/Docs/check_docs.py`
(DoD#2 if the vocabulary is ratified as a checkable rule),
`scripts/tests/test_unit_details_screen.gd`, `scripts/tests/test_stat_contributions.gd`.

Plan:

1. Define the fixed vocabulary in one place (e.g. `GameConstants.VALID_DURATION_TYPES`):
   `this_combat`, `until_separated`, `until_unequipped`, `until_end_of_map`, `x_turns`.
   (Keep `permanent` for innate/class bonuses — it renders blank, not a duration.)
2. `format_duration` renders each: `this combat`, `until separated`, `until unequipped`,
   `until end of map`, and `N turns` (from `remaining`) respectively.
3. **Re-tag existing sources** to the right bucket:
   - Pair Up → `until_separated` (was `combat`).
   - Stat tonics / `stat_buff` items with a turn count (Debuff Tonic, M9 Cripple) → `x_turns`.
   - Weapon/item *while-equipped* stat bonuses → `until_unequipped`.
   - Genuinely per-engagement procs (faire/breaker, M9 combat skills, M8 Hex) → `this_combat`.
   - Map-scoped buffs → `until_end_of_map`.
4. Update pinned test assertions (`test_unit_details_screen`, `test_stat_contributions`,
   any combat tests that assert breakdown text). Update GDD_07 §Character Sheet and the
   stat-breakdown contract; if `VALID_DURATION_TYPES` becomes a rule, add the check (DoD#2).

Note for M8/M9: this vocabulary is the shared duration surface those milestones tag into —
landing it here means they author against a stable enum instead of inventing strings.

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

1. Define the **movement-type subset** in one place (`GameConstants.VALID_MOVEMENT_TYPES`)
   and add the explicit default `infantry`: `flying`, `mounted`, `armoured`,
   `light_footed`, `infantry`. This is a *subset* of `special_qualities` — the array also
   holds non-movement type tags **`dragon` / `beast` / `laguz`** (M12/M13, per GDD_03) and
   the resolver must ignore those (F3). Author the correct movement tag into every class's
   `special_qualities`, adding `infantry` to the ~10 classes that currently have none
   (archer, bishop, fighter, hero, mercenary, sage, sentinel, sniper, soldier, war_cleric,
   war_monk). `special_qualities` is not allowlist-validated, so no schema break.
2. Add a **resolver** `movement_type_of(unit/class) -> String` returning the single
   highest-precedence movement tag present (ignoring non-movement tags), defaulting to
   `infantry`. Precedence (highest first, for terrain cost + display): **`flying` >
   `mounted` > `armoured` > `light_footed` > `infantry`**. Fliers ignore ground terrain so
   flying wins the *cost* resolution; among ground types mount/armour penalty dominates the
   light bonus. **This is load-bearing today:** `great_knight` is `["armoured","mounted"]`
   → resolves `mounted` (cost-identical in desert; deterministic for display). Effectiveness
   is independent — `vulnerability_groups` still reads every tag, so an armoured+mounted (or
   future armoured+flying) unit is hit by all matching effective weapons regardless of its
   resolved *movement* type.
3. Refactor `GridManager.get_move_cost()` / `get_move_costs_for_groups()` to key off the
   resolved movement type instead of ad-hoc `has_quality` checks — **preserving the
   skill-override-first ordering** (Acrobat/Pass/Nimble stubs and M9 `dash` are checked
   before base cost; F3). Add a `flying` cost column (fliers ignore ground costs; river/sea
   passable) so the set is complete. Keep the desert rule (mounted/armoured 3, light 1,
   infantry base, flying per the flying rule).
4. Surface the resolved movement type as its own line in class More Info (V021-10), and
   stop listing movement tags under the generic `Traits:` line in `UnitDetailsScreen`
   (line 133) so movement type and genuine traits are visually separate.
5. **DoD#1/#2:** reconcile GDD_03's valid-`special_qualities` list — it currently omits
   `light_footed` (live in data/code) and `infantry` (new). Add a `check_docs`/test rule
   that every class declares **≥1** movement type (not "exactly one" — `great_knight`
   carries two), enforced via `VALID_MOVEMENT_TYPES`.

Open question for implementation: confirm the `flying` cost rule (full ground-ignore vs. a
flat 1, with river/sea passable). Resolve before coding step 3.

### V021-12 — (stretch) clickable skill info boxes

After V021-06, let class-skill entries in More Info open their own description boxes via
the same selector. Depends on the selector fix; schedule as stretch.

### V021-15 — Shared directional selector for forecast + terrain (reopened)

Extend the selector to the combat forecast and terrain More Info — but build it as **one
shared selector component**, not three per-surface copies (F5). The sheet (V021-06), the
forecast, and the terrain panel all consume the same focus model, so the future **gamepad/
key-rebind milestone** has a single place to wire joypad events. Pairs with V021-05
(terrain paging) and V021-06 (axis fix; do that first so the shared component is correct).

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

## Workstream F — Mouse/Touch Mode (V021-17, v0.2.2) + Display v0.2.3 (V021-18, V021-19)

- `V021-17` mouse-only / touch cursor mode (**v0.2.2**) — full standalone design:
  `AGENT/Docs/mouse_only_cursor_mode_design_2026-06-19.md`. Re-introduces a third
  `mouse_cursor` value (`follow|click|disabled`); cursor decouples from hover, jumps on
  click, second click selects; terrain page button / click-switch in this mode. Build the
  `mouse_cursor` tri-state as the first entry of a coherent input-mode concept (F5) and a
  **mobile** down-payment.

The two items below are **v0.2.3 "Display Scaling & Resolution"** (Decision 5 / F4) — one
coupled system, split out so v0.2.2 does not rework the just-shipped Menu Scale:

- `V021-18` crisp scaling rework — replace Control-node `.scale` raster zoom with theme
  font-size / control-metric scaling. Affects Menu Scale (v0.2.0 V020-16) and HUD Layout.
  This is the right foundation for V021-19.
- `V021-19` native 1440p / 4K resolutions + Steam Deck / mobile / safe-area insets.
  Ties to OPEN-11 and the Renderer & Platform Targets gate in GDD_10. Design alongside
  V021-18 (font-based scaling makes native high-DPI crisp).

## Verification Plan (after approved implementation)

1. `python3 AGENT/Docs/check_docs.py`
2. Focused tests per workstream:
   - `test_turn_manager.gd`, `test_enemy_ai.gd` (V021-01)
   - `test_hud_layout.gd`, `test_hud_layout_editor.gd` (V021-02/03/04)
   - `test_unit_details_screen.gd`, `test_more_info_content.gd` (V021-06/10/12),
     `test_stat_contributions.gd` (V021-09 re-tags)
   - `test_grid_manager.gd` (V021-11 movement-type resolver + costs)
   - `test_hud.gd` (V021-07, V021-05 paging), `test_menu_scale.gd` (V021-08)
   - `test_map_cursor.gd` (V021-16, V021-17 click-mode), `test_settings_manager.gd`
     (V021-17 `mouse_cursor` migration), `test_attack_preview_*.gd` (V021-14)
3. Full suite: `TEST_JOBS=8 ./run_tests.sh`
4. Manual Windows retest of the failed items plus the Error-log check (NOT RUN this pass).

## DoD reminders

- Any behavior change updates the matching GDD_01–08 section(s) and flips the GDD_10
  status in the **same** commit (DoD#1).
- Any new mechanical/checkable doc rule lands its `check_docs.py` check in the same
  change (DoD#2).
