# GDD_07 — Screens And Panels

**Status:** Active surface contract — implemented, validation-pending, and planned
slices are labelled per section.
**Last verified:** 2026-07-13
**Governance:** section template + status vocabulary in
`AGENT/Docs/governance/documentation_governance_2026-06-13.md`.

This companion owns the screen/panel catalog and each surface's player-facing behavior.
Cross-cutting navigation, feedback, and accessibility remain in
[GDD_07 — UI & UX](GDD_07_UI_UX.md); tactical input/cursor mechanics live in
[GDD_07 — Input And Cursor](GDD_07_Input_Cursor.md).

---

## Screens and Panels

Status: **Split** — MVP screens are **Implemented**; the V030-SUS-01 suspend Continue restore fixes are **Pending validation** (fixed 2026-07-09, awaiting live rerun); manual save slots + combat-animation feedback are **Planned**
Last verified: 2026-07-09

---

### Main Menu

**Scene:** `MainMenu.tscn`
**Trigger:** Game start / quit from map

**Layout (centered on 1280×720):**
```
┌─────────────────────────────────┐
│    [PLACEHOLDER — Game Title]   │
│                                 │
│         [ Continue ]     (greyed if no suspend save)
│         [ New Game ]            │
│         [ Settings ]            │
│         [ Quit ]                │
└─────────────────────────────────┘
```

**Behavior:**
- "Continue" → loads `user://saves/suspend.json` through `SaveManager`, stages
  the payload on `GameState`, and launches `GameMap`. It is disabled when no
  suspend save exists; load failure opens an error dialog and stays on Main Menu.
  On restore (V030-SUS-01, fixed 2026-07-09): units whose serialized state is
  DONE re-apply the darkened DONE appearance (so a spent unit reads as spent, not
  as an actable one it silently refuses); a paired support restored onto the
  off-map sentinel `(-1,-1)` stays hidden instead of drawing at the placeholder;
  and the restore emits `turn_changed` so the HUD turn counter reflects the
  restored turn immediately rather than after the next round boundary.
- "New Game" → opens the `NewGameScreen` overlay
- "Settings" → opens Settings screen (see below); available from MVP onwards
- For MVP: "Continue", "New Game", "Settings", and "Quit" are functional

---

### New Game Screen

**Scene:** `NewGameScreen.tscn`
**Trigger:** "New Game" from the Main Menu

The live new-game flow is no longer a direct jump into `Map 001`. It is a modal
setup screen that writes per-run rules onto `GameState.campaign_rules`, then launches the chosen
map through `GameMap.tscn`.

**Current options:**
- `Map` — populated from `data/maps/map_registry.json`
- `Permadeath` — Off / On
- `Auto Promote` — Off / On
- `Leveling` — Random / Fixed
- `Pair Up` — Off / On

**Behavior:**
- Selecting a map also selects its roster policy (`default_roster`, fixed test roster,
  or keep-current when that mode is authored later)
- The rule toggles (`Permadeath`, `Auto Promote`, `Leveling`, `Pair Up`) write through
  to `GameState.campaign_rules` the moment they change, so closing the panel with Back and reopening
  it remembers the choices — Start is not required to persist them. (The `Map`
  selection and roster are only configured on Start.)
- The `Map` dropdown seeds from `GameState.next_map_data_path`, which represents the
  last configured/launched map. Choosing a different map and backing out without Start
  does not overwrite that path, so reopening the screen returns to the last launched
  selection rather than an unsaved dropdown choice.
- Starting the run calls `GameState.configure_next_map(...)`, applies the roster
  policy, then changes to `GameMap.tscn`
- Back returns to the Main Menu without reloading the scene

This screen is onboarding-relevant because the map registry is now the canonical
launch surface for the validation maps and objective showcase maps.

Target campaign starts will select a campaign package/slice first, then a map or saved
campaign entry as appropriate. The current map dropdown is a developer/debug surface and
validation preset, not the final builder-facing campaign browser.

### Prep, Service, And Authoring Panels

Status: **Target design**
Last verified: 2026-06-29

Prep services and on-map services use the shared PHB panel model. Shops, convoy,
training, arena, villages, object activation panels, and future side activities should
register panel/activity ids and data schemas; the UI opens the registered panel with an
actor/context instead of branching on a closed panel enum.

The public builder/authoring GUI is deferred (`B8-PUBLIC-BUILDER`). Until then, the
portfolio path is data-only authoring through resources/manifests plus a slice-first web
demo. Any later public scripting UI is bounded by the sandbox ceiling from SET-013.

---

### In-Map HUD (persistent overlay)

The HUD is always visible during a map. It uses a `CanvasLayer` so it is unaffected
by camera movement.

**Layout:**

```
┌──────────────────────────────────────────────────────┐  ← top of screen
│ Phase Label (top-left)           Turn Label (top-right)│
│ e.g. "Blue Phase"                e.g. "Turn  3"        │
└──────────────────────────────────────────────────────┘

              [MAP VIEW — tiles, units, cursor]

┌──────────────────────┐               ┌────────────────┐
│ UNIT INFO PANEL       │               │ TERRAIN PANEL  │
│ [Portrait] Name       │               │ Forest         │
│            Class      │               │ DEF    +1      │
│            HP 17/21   │               │ Dodge  +15     │
│            Iron Lance │               └────────────────┘
└──────────────────────┘
  ↑ bottom-left                           ↑ bottom-right
```

**Unit Info Panel** (`UnitInfoPanel.tscn`):
- Shown when cursor hovers over any unit (ally or enemy)
- Hidden when cursor is on an empty tile with no unit
- Size: ~300 × 110 px
- Portrait: [PLACEHOLDER] 64×64 px class portrait
- For a paired **lead**, a `Support: <name>` line names the off-map partner so the
  player can see who they paired with without opening the character sheet (V020-09).
  **V021-07:** the per-stat `Paired +N Str +N Def …` deltas were removed from the
  *map* HUD — they crowded the bottom-left panel and pushed the support name off the
  screen edge; the full per-stat breakdown lives on the `I` character sheet (via
  `StatContributions`). The default `UnitInfoPanel` position was also raised so the
  block has headroom for its lines on the 720-tall reference viewport. Supports are
  off-map and never displayed as the panel's own hovered unit.
- On the map, a visible paired lead shows a small `PU` badge on the unit sprite.
  The marker is driven by `PairUpRegistry.pair_up_changed`, so Pair Up, Swap,
  Separate, clear, and snapshot restore all refresh the badge without polling.

**Terrain Info Panel** (`TerrainInfoPanel.tscn`):
- Always shown (updates as cursor moves)
- Shows terrain name, DEF bonus, Dodge bonus
- In the current build it also hosts the phase-1 More Info terrain text:
  description, move-cost notes, and available tile actions
- Size: ~180 × 80 px

**Objective Panel:**
- Lists the active blue-group win/lose conditions from authored `ObjectiveCondition`
  resources
- Tile coordinates shown in objective text are player-facing one-based coordinates;
  the underlying objective data and evaluator stay zero-based.
- Hidden on maps that do not author objective text for the current view

**Phase Label:**
- Text is faction-driven, not hardcoded player/enemy text
- Uses `Faction - Controller` text from one shared formatter, for example
  `Blue - Player 1`, `Red - AI`, or `Green - Player 2`
- Updates on phase change; fades in briefly after banner

**Turn Label:**
- Text: "Turn  3"
- Increments when the scheduler wraps back to blue in whole-phase maps

---

### Phase Banner

**Scene:** `PhaseBanner.tscn`
**Trigger:** Each phase change

**Layout:**
```
[full-width colored bar slides in from right, pauses, slides out to left]
┌────────────────────────────────────────┐
│            BLUE PHASE                  │   ← example; display text is authored
└────────────────────────────────────────┘
```

**Animation (Tween):**
1. Banner starts off-screen right (x = 1280)
2. Slides to center (x = 0) over 0.3 seconds
3. Holds for 0.8 seconds
4. Slides off-screen left (x = -1280) over 0.3 seconds
5. `cursor.unlock()` called after animation completes

Colors:
- Driven from `FactionData.color` for the acting faction
- Text uses the faction's authored display name

Font size: 40px, bold [PLACEHOLDER font]

---

### Action Menu

**Scene:** `ActionMenu.tscn`
**Trigger:** After a controllable unit successfully moves (or confirms on its current tile)

**Layout (positioned near the moved unit, offset to avoid covering it):** anchored to
the unit tile's **far edge plus a constant 4px gap** (`MapCursor._place_menu_near`,
V027-02) — the tile-width term scales with map zoom but the gap does not, the same
model the Attack Preview uses, so the menu hugs the unit without covering it at any
zoom. Flips to the left side when the right doesn't fit; keeps its side across zoom
repositions (V025-03 stickiness).
```
┌────────────┐
│  Attack    │
│  Staff     │
│  Item      │
│  Equip     │
│  Seize     │
│  Escape    │
│  Pair Up   │
│  Swap      │
│  Separate  │
│  Wait      │
└────────────┘
```

The menu is **contextual**. Unavailable actions are hidden entirely rather than shown
disabled, so the visible row set depends on the acting unit, tile, and current map.

**Behavior:**
- Menu appears adjacent to the unit's new tile; repositioned if too close to screen edge.
  The tile anchor is remembered while the menu is open, so map zoom or the Settings
  Map Zoom slider re-place the contextual Action/Item/Weapon menu against the same tile
  instead of leaving it at a stale screen position (V023-03).
- Navigate with `cursor_up` / `cursor_down` (wraps, skipping disabled buttons);
  confirm with `confirm`; close with `cancel`
- Closing with cancel triggers undo: unit returns to its pre-move tile
- `Seize` / `Escape` are gated by shared `TileActions` logic so the action menu and
  terrain More Info panel agree
- `Pair Up`, `Swap`, and `Separate` are shown only when the pairing state allows them

**Button widths:** 120 px; height per button: 30 px
**Font size:** 18px

---

### Target Selection

**Trigger:** Player selects "Attack" or "Staff" from the Action Menu.
**Owner:** `MapCursorTargeting` (a `RefCounted` slice of `MapCursor`).

There is **no target-list panel**. Target selection happens on the map itself:

- The valid target tiles are highlighted with overlay tiles — **red** for Attack
  targets, **green** for Staff (heal) targets.
- The cursor snaps to the first valid target. Direction keys, d-pad directions,
  and the left stick **cycle** the cursor between valid target tiles (the list wraps).
  With `Mouse Cursor = Follow`, mouse motion snaps the cursor to the nearest valid
  target; `Click` waits for a click/tap to move, and `Off` (`disabled`) ignores mouse motion.
- `confirm` on an Attack target opens the Attack Preview; `confirm` on a Staff target
  applies the heal immediately. `cancel` returns to the Action Menu.

---

### Attack Preview Panel

**Scene:** `AttackPreview.tscn`
**Trigger:** Player confirms an attack target during on-map target selection

**Layout (anchored near the defender on screen rather than fixed to the bottom):**
```
┌────────────────────────────────────────────────┐
│   [Attacker Name]          [Defender Name]     │
│   Hit:   82%               Hit:   55%          │
│   Dmg:    7                Dmg:    4            │
│   Crit:   5%               Crit:   0%           │
│   ×2 attacks               ×1 attack            │
│                                                │
│             [Z/Enter = Confirm]                │
│             [X/Esc   = Cancel ]                │
└────────────────────────────────────────────────┘
```

**Rules:**
- If the defender cannot counterattack (out of range, or no weapon):
  the defender side collapses to a `No counter` readout and omits the normal
  hit/crit rows
- If attacker gets a follow-up, show `×2 attacks` below their crit
- Preview calls `ProjectionService.project_combat()`, whose combat adapter delegates
  to `CombatResolver.preview_combat()` — no committed RNG or live-state mutation
- A failed projection clears the prior More Info selection list, so stale forecast
  rows cannot remain navigable after the preview becomes invalid
- Confirm triggers `CombatResolver.resolve_combat()` (with RNG)
- The current panel also shows weapon-triangle and effectiveness markers
- A **weapon row** under each combatant's name shows the equipped weapon's display
  name ("Unarmed" when none), so matchups read at a glance without opening the sheet
  (V021-14). It's a plain readout, not a selectable More Info field. These rows are
  measured with the rest of the forecast rows so exported builds cannot collapse them
  to zero height (V023-04).
- Neutral weapon-triangle/effectiveness states render a low-emphasis gray `Neutral`
  marker instead of a blank cycle-only row (V023-04).
- Phase-1 More Info adds an info box on the right; `more_info` cycles through each
  preview field and clicking a field opens its description. The info text is a bounded
  scroll area with enough vertical fill to avoid clipping longer descriptions at large
  display/zoom settings (V023-04).
- The **Damage** field's More Info also shows each side's **Battle Speed** and the
  follow-up threshold (and who, if anyone, doubles) — the values needed to verify
  the follow-up math (handbook 8.3). `preview_combat()` returns
  `attacker_battle_speed` / `defender_battle_speed` / `follow_up_threshold`.
  Both sides' Battle Speed are shown **even when the defender cannot counter**
  (playtest v0.1.5.0 #8.3): the defender's speed is still informative and the
  attacker can double a non-countering defender, so the note reads
  `Attacker N vs Defender M … (defender cannot counter)` rather than hiding the
  defender's value.

**Size:** Content-sized three-column layout, clamped/repositioned to the viewport.
On every show, sizing + placement re-run once one frame later with the panel held
transparent (V027-03a): RichTextLabel content minimums read inflated until a layout
frame passes, which used to freeze dead space under the rows on the first open.
**Placement:** Anchored beside the defender (right, else left), kept inside the viewport,
and nudged clear of the visible HUD panels (objective / unit-info / terrain corners)
and the defender tile so it does not cover them (`AttackPreview._place_clear_of`).
Avoidance is best-effort: a panel too tall to clear an avoid rect is left clamped
on-screen rather than pushed off. Placement always reads a **settled canvas
transform**: every camera write callers read synchronously — including cursor-driven
scrolls (`keep_cursor_in_view`, V027-03b) — flushes via `force_update_scroll`
(V026-03/04a), and the zoom-reposition hook re-runs once one frame later (coalesced)
as a self-heal for anything that lands after it.
**Font size:** 18px

---

### Staff Use

**Trigger:** Player selects "Staff" from the Action Menu — enabled only when the unit
has a healing staff equipped and at least one injured ally in range.

Staff targeting uses the same green-overlay + cursor-cycling flow as attack targeting
(see Target Selection). Confirming on an ally heals them for `10 + MAG` HP via
`Unit.perform_staff_heal()`, awards the healer EXP and wEXP, and ends the unit's
turn. There is no separate staff-preview panel in MVP.

---

### Item Menu

**Trigger:** Player selects "Item" from Action Menu
**Layout:** Same style as Action Menu; lists inventory items with uses remaining

```
┌──────────────────────┐
│  Vulnerary    (3)    │
│  Elixir       (3)    │
└──────────────────────┘
```

- Selecting an item and confirming uses it (healing items restore HP immediately)
- Ends the unit's turn after use
- Cancel returns to Action Menu

---

### Unit Details Screen

**Scene:** `UnitDetailsScreen.tscn`
**Trigger:** `inspect_unit` while the cursor is over a unit

This is the live character-sheet overlay. It shows:

- unit name, class, level, internal level (labelled `Internal Lv`, not `Int`), and EXP
- a compact **class summary** section (V020-11): the title uses `ClassData.display_name`,
  and a selectable class row shows just **name + tier** (V021-10). Selecting it opens the
  full class detail in the More Info side panel: `ClassData.description`, the resolved
  **Movement** type (V021-11), non-movement **Traits**, allowed weapon families, and
  class-skill unlocks. (The relocation keeps the inline row uncluttered and gives the
  movement type its own line instead of burying movement tags under Traits.)
- full core stat block using the effective display totals, with a final utility-stat
  row for **Constitution (`Con`)** and **Line of Sight (`LoS`)** — both intentionally
  uncapped, so their breakdown shows class cap "—" (V020-15)
- inventory with remaining uses
- equipped skills
- weapon ranks / WEXP progress
- a `View Support` / `View Lead` button when the inspected unit is paired, letting
  the player inspect the hidden support unit without leaving the sheet

The screen is read-only. It exists for inspection, not inventory management.
The main sheet column lives inside a fixed, centered scroll frame, so Menu Scale keeps
the modal centered while overflow content remains reachable at large factors (V023-02a).

**More Info integration:**
- every class, stat, inventory entry, skill, and weapon-rank row is selectable
- selection is driven three ways (V020-10): clicking a row, the cursor keys / d-pad
  (handled in `_input` before GUI focus navigation so arrows don't move button focus),
  or `more_info` (F) forward cycling; the selected row is marked with a `▶` highlight
- the cursor keys follow the on-screen grid (V021-06): each entry records its visual
  `(row, col)` during build (the stat block is two columns per row; skills share one
  row), so **Up/Down** move to the nearest entry one row away (matching column) and
  **Left/Right** step through the flat reading order. The earlier mapping pointed both
  Up and Left at the same backward step, so Up/Down read as Left/Right across the grid.
- the selection model is backed by `SelectionCursor`, shared UI navigation logic that
  supports sparse visual rows. The sheet adds a terminal `Back` control zone (V026-02e):
  moving down past the last content row focuses `Back`, and `confirm` closes the sheet.
  This keeps Back reachable by keyboard/gamepad even though the sheet consumes cursor
  directions before Godot focus navigation.
- the `View Support` / `View Lead` button is likewise a selectable **pair** control
  entry when a partner exists (V031-GP-05, 2026-07-12): traversal visits it just
  before `Back`, focusing the button, and `confirm` activates it — previously it was
  reachable only by mouse or the `next_unit`/`prev_unit` pair-jump shortcut, which the
  v0.3.1 tester read as the focus selector "skipping" it. The pair-jump shortcut stays.
- selection drives the scroll (V031-GP-05): the custom selector moves a text highlight,
  not GUI focus, so `follow_focus` alone never fired for content rows — on each
  selection change the sheet scrolls the owning section label into view
  (`ensure_control_visible`), and the control entries scroll via their real focus grab.
- all three More-Info surfaces route navigation through this one `SelectionCursor` core
  (B6-INPUT selector adoption): the character sheet (2-D grid), the combat forecast
  (`AttackPreview`, 1-D forward cycle), and the terrain pager (`HUD`, with the -1 = Hidden
  inactive stop). One core = one place the gamepad d-pad wiring attaches. Pure refactor —
  navigation behaviour on each surface is unchanged.
- stat entries show authored description text plus the full stat breakdown
- inventory **weapon** entries show their full stat block in the side panel —
  Mt/Hit/Crit, Wt, range (resolved against the inspected unit), required rank +
  family, uses, and effect tags (V020-10); item entries show their authored
  description
- the compact stat rows use the same `effective_display` value as the More Info
  breakdown, including Pair Up and other combat-only stat contributions

**Stat breakdown (per selected stat):**
- **Personal base / Class base** — the stored stat split into the unit's own value
  and the current class's base contribution (`personal_base = stored − class base`,
  clamped at 0 for authored units that store a stat below their class base).
- **Class cap** — the class's ceiling from `ClassData.stat_caps`. Stats outside
  `STAT_KEYS` (MOV/CON/LoS) are intentionally uncapped and show "—"; a `STAT_KEYS`
  stat with no authored cap shows a loud **`NO_CAP_DEFINED`** (a data-integrity
  signal — guarded by `test_class_stat_caps.gd`, so it should never appear in a
  shipped build).
- **Effective** — the displayed total including combat-only bonuses; rendered
  **green** when an active bonus raises it above base, **red** when a net debuff
  lowers it below base, plain otherwise.
- **Bonuses** — every active bonus with amount + source. Persistent sources
  (items/tonics) come from `active_modifiers`; **combat-only sources (Pair Up, the
  unit's own stat skills) are computed by `StatContributions`**, because they are
  stamped only at combat start (`duration_type="combat"`) and never live in
  `active_modifiers` outside a fight. `StatContributions` is the single authority
  the combat path also resolves through, and `test_stat_contributions.gd` is a
  drift guard asserting the sheet and combat report identical numbers. Each bonus's
  duration is shown by **scope label** drawn from the fixed V021-09 vocabulary
  (`GameConstants.VALID_DURATION_TYPES`, rendered by `StatBreakdown.format_duration`):
  `this_combat` → "this combat", `until_separated` → "until separated" (Pair Up),
  `until_unequipped` → "until unequipped", `until_end_of_map` → "until end of map",
  `x_turns` → "N turns", `permanent` → "—" (always-on stat skills). **The label is
  distinct from the lifecycle tick point.** A real `active_modifier` still carries its
  own `duration_type` for *when it decrements/clears* (`turn` per faction phase,
  `map_turn` per round, `combat` cleared at end of combat, `permanent` never) — Pair
  Up, for instance, is stamped `combat` (recomputed each fight) yet displays "until
  separated". `format_duration` accepts both the vocabulary and the legacy lifecycle
  types and maps each to the same wording; scope labels are matched before the
  negative-remaining "—" fallback so their `-1` sentinel isn't swallowed. M8
  conditions / M9 procs author against this vocabulary so they never reintroduce an
  ad-hoc string. (Aura skills are M9 stubs that target hit/dodge/crit, not base
  stats, so they contribute nothing here yet.)

This closes the v0.1.5.0 #8.5 surface gap: the Pair Up bonus now appears on the
compact character sheet, the detailed stat breakdown, the HUD unit-info panel, and
the paired lead's map badge.

This screen is one of the primary onboarding-relevant UI surfaces because it exposes
the runtime meaning of modifiers, skills, and WEXP without opening the code.

---

### Level Up Screen

**Scene:** `LevelUpScreen.tscn`
**Trigger:** Unit reaches 100 EXP and levels up

**Layout (centered panel, blocks all input until dismissed):**
```
┌────────────────────────────────┐
│   Elan leveled up!  Lv 4 → 5  │
│                                │
│   HP    21  →  22   ▲          │
│   STR    7  →   7              │
│   MAG    0  →   0              │
│   DEF    6  →   7   ▲          │
│   RES    3  →   3              │
│   SKL    6  →   7   ▲          │
│   SPD    6  →   6              │
│   LUK    6  →   7   ▲          │
│                                │
│         [Press Z]              │
└────────────────────────────────┘
```

**Behavior:**
- Stats that increased are shown with a `▲` marker and highlighted in yellow
- Stats that did not increase are shown in white
- Player presses `confirm`/`cancel`, or left/right-clicks, to dismiss. Wheel and zoom
  input are consumed while the popup is visible and do not dismiss it (V023-05).
- If multiple level-ups occur at once (EXP overflow), show one screen per level
- After dismissal, combat or turn resolution continues

---

### Map Menu

**Scene:** `MapMenu.tscn`
**Trigger:** `open_menu` action on an empty tile, or dedicated menu key

**Layout (centered overlay on top of map; map still visible behind):**
```
┌──────────────────┐
│   End Turn       │
│   Settings       │
│   Suspend & Quit │
│   Quit to Menu   │
│   Close          │
└──────────────────┘
```

**Behavior:**
- `End Turn`: calls `TurnManager.end_player_phase()`. If any unit has not acted,
  a confirmation prompt is shown first; if every unit is already done it ends
  immediately. (Note: the phase also ends automatically once the last unit acts.)
- `Settings`: opens the Settings screen (see below); the cursor stays locked
  while it is open. Settings is also reachable directly via the `open_settings`
  key (O) during a map.
- `Suspend & Quit`: available only when the cursor opened the menu from a free
  boundary **during the blue player phase**. It confirms, writes
  `user://saves/suspend.json` through `SaveManager`, then returns to
  `Boot.tscn`; if the write fails, a failure dialog keeps the player on the map.
  The blue-phase gate is the v1 answer to V030-SUS-01 (c): a non-blue capture
  (e.g. debug-hotseating the red team) would restore a phase that locks the
  cursor but never re-enters the awaited faction scheduler, leaving the resumed
  map with a frozen cursor and no way to act. Restoring the scheduler loop for a
  non-blue active faction is the deferred alternative.
- `Quit to Menu`: returns to `Boot.tscn` after confirmation and clears map-scoped
  runtime state through `GameState.reset_map_state()`
- `Close`: closes the map menu and returns to the map.
- `cancel` also closes the map menu.
- A **left-click on the backdrop** (anywhere outside the centered panel) dismisses
  the menu (V021-13), matching common modal behaviour — handled via the menu's
  full-rect `gui_input`.

---

### Settings Screen

**Scene:** `SettingsScreen.tscn`
**Trigger:** "Settings" button in Main Menu or Map Menu, or the `open_settings`
key (O) during a map
**Script:** `scripts/ui/SettingsScreen.gd`

The Settings screen is a single panel — **not tabbed**. A full-rect opaque
`Dimmer` behind the panel makes it modal (the screen behind is fully hidden).
The panel's contents live in a `ScrollContainer` so the list never overflows.
Focus stepping keeps up to three row heights of lookahead context visible past
the focused row, capped below half the viewport at large Menu Scale values
(V032-D2, 2026-07-13) — `follow_focus` alone
scrolled the focused row just barely into view, so the tester couldn't see
what the next step moved toward.
It is an overlay opened with `open()` and dismissed by the `Back` button or the
`cancel` action. Each
control writes its change to `SettingsManager` immediately (volume via `set_volume()`,
which persists; option changes call `SettingsManager.save()`), so there is no separate
save-or-discard step.

All settings persist between sessions in `user://settings.cfg` (Godot's `ConfigFile`).
See GDD_01 → SettingsManager.

#### Layout (single VBox panel)

```
┌──────────────────────────────────────────────────┐
│                   Settings                       │
│                                                   │
│   Master   [━━━━━━━━━━━━━━━━━━━━]   80            │
│   Music    [━━━━━━━━━━━━━━━━━━━━]   70            │
│   SFX      [━━━━━━━━━━━━━━━━━━━━]   90            │
│   ─────────────────────────────────────────       │
│   Movement Speed     [ Normal ▾ ]                 │
│   Phase Banner       [ Show ▾ ]                   │
│   Level Up Screen    [ Show ▾ ]                   │
│   Mouse Cursor       [ Follow ▾ ]                 │
│   Auto End Turn      [ On ▾ ]                     │
│   Camera Edge Buffer [━━●━━━━] 2                  │
│   Map Zoom           [━━●━━━━] 1.0x               │
│   Menu Scale         [━━●━━━━] 1.0x               │
│   Terrain Dim        [●━━━━━━] 0%                 │
│   ─────────────────────────────────────────       │
│   Controls                                        │
│   Move Up               W / Up                    │
│   Confirm               Z / Enter / Space         │
│   ... (one row per game action — editable)         │
│   ─────────────────────────────────────────       │
│                   [ Back ]                        │
└──────────────────────────────────────────────────┘
```

---

#### Audio

Three `HSlider` controls — `Master`, `Music`, `SFX` — range 0–100, step 1. Dragging a
slider updates the matching audio bus in real time and saves immediately. Buses are
looked up by name (`Master` / `Music` / `SFX`); a missing bus is silently skipped.

| Setting | Default | Range |
|---|---|---|
| `master_volume` | 80 | 0–100 |
| `music_volume` | 70 | 0–100 |
| `sfx_volume` | 90 | 0–100 |

#### Gameplay options

Each is an `OptionButton`; selecting an option saves immediately.

**Movement Speed** (`movement_speed`, default `"normal"`) — how fast unit sprites
travel. `Unit.move_along_path()` reads it via `SettingsManager.get_movement_speed_seconds()`.

| Option | Per-tile duration |
|---|---|
| Normal | 0.12 s |
| Fast | 0.06 s |
| Instant | 0 s — `snap_to_tile()`, no tween (the `unit_moved` signal still fires) |

**Phase Banner** (`phase_banner`, default `"show"`) — `Show` plays the full
slide-in / hold / slide-out banner; `Skip` suppresses it (the HUD phase label still
updates).

**Level Up Screen** (`level_up_screen`, default `"show"`) — `Show` waits for a
`confirm` press; `Auto` auto-dismisses after ~1.5 s; `Skip` shows only a brief pop-up.

**Mouse Cursor** (`mouse_cursor`, default `follow`) — fixed vocabulary:
`follow`, `click`, `disabled` (V021-17; enforced by DOC-011
`check_docs.py`). `Follow` lets mouse motion drive the on-map cursor (in
`FREE` / `UNIT_SELECTED` it follows the pointer; in `TARGETING` it snaps to the
nearest valid target). `Click` makes hover inert: the first left-click/tap moves
the cursor to that tile, and a second left-click/tap on the same tile confirms.
In click mode, clicking the terrain panel cycles More Info pages
Hidden → Description → Movement → Hidden. `Off` (`"disabled"`) ignores mouse
motion entirely in every state, so stray bumps cannot nudge the cursor during
keyboard play (PT4 #1). Right-click/cancel and the middle-click threat resolver
(see *Threat Overlay*) stay intentional mouse actions. Legacy values still load: `"enabled"` → `"follow"`;
old `mouse_targeting="snap"` → `"click"`.

**Auto End Turn** (`auto_end_turn`, default `true`) — when On, the acting human
phase commits automatically after every controllable unit is `DONE`.

**Camera Edge Buffer** (`camera_edge_buffer`, default `2`, range `0-5`) — number
of tiles from the viewport edge that trigger camera panning. The value is
clamped when loaded from the settings file.

#### Controls (editable)

A **Controls** section lists every game action and the bindings read live from the
`InputMap` when the screen opens (`_populate_keybindings()` builds one row per action).
Normal game-action rows expose keyboard/mouse and gamepad capture buttons; debug-only rows
stay read-only. Captures are staged in a pending buffer and do not touch the live
`InputMap` until **Apply**. A same-slot conflict marks both rows red and disables Apply;
each conflicting row exposes **Clear**, which leaves that device slot unbound. **Revert**
discards pending edits, and **Reset Controls** is always visible.

`SettingsManager` persists the backing model under `[controls].profiles`: the active
`"Default"` profile maps each action to `{"kbd": token, "pad": token}` using
hand-editable strings (`Z`, `Mouse1`, `JoyA`, `JoyAxis5+`). Old `Object(InputEvent...)`
cfg blobs migrate into that profile shape.

The **Input Prompts** dropdown (`input_mode`, default `auto`) exposes the fixed
vocabulary `auto`, `gamepad`, `touch`, `mouse_keyboard` (enforced by DOC-011
`check_docs.py`). The visible label is deliberately prompt-focused: the setting
changes prompts and focus defaults, not which physical devices are allowed. It
is a **gray-state selector**: modes unsupported on the current platform (e.g.
`touch` on desktop) are shown **disabled**, not hidden, so the vocabulary stays
visible and self-documenting. The chosen value is the persisted preference;
`InputModeManager` resolves the runtime `active_input_mode`, emits
`input_mode_changed`, records the last joypad device that sent real input for
brand-aware prompts, and still falls back at runtime if a saved value is
unavailable — so a stale saved mode is safe. Availability comes from
`InputModeManager.available_modes()` via `SettingsScreen._apply_mode_availability`.

**Focus-grab subscribers.** The shared `ModalScreen` base subscribes every modal to
`input_mode_changed`. While a modal is visible, a live switch **to gamepad** grabs a
sensible default focus (`_focus_default()` — overridable; the base picks the first
focusable control, `SettingsScreen` picks Back, `UnitDetailsScreen` seeds its
`SelectionCursor`). A switch **to touch** drops the stale focus highlight
(`_release_stale_focus()`). A switch to `mouse_keyboard` is deliberately left alone —
that mode lumps mouse and keyboard together, and keyboard nav still wants the
highlight. Hidden modals ignore the switch.

Visible engine-focus modals also contain focus: if focus navigation escapes to a
background control while the modal is open, the modal reclaims focus. This is backed
by a MainMenu-hosted New Game regression test so the live parent scene, not only the
isolated modal scene, is covered.

#### Hidden / not yet implemented

- **Touch Controls** (`touch_controls`, default `dedicated`) — fixed vocabulary:
  `dedicated`, `virtual_gamepad` (enforced by DOC-011 `check_docs.py`). Until
  the dedicated touch layer ships, the resolver can still fall back to the virtual
  gamepad presentation while preserving the authored preference.
- **Combat Animations** (`combat_animations`) — a `SettingsManager` field with an
  `OptCombatAnim` control that is **hidden**: no combat-animation system consumes the
  setting yet (MVP combat is instant). It will be shown when that system lands.
- **Permadeath** and **Leveling Method** are *not* on the Settings screen — they are
  per-save rules chosen on the **New Game** screen and stored on
  `GameState.campaign_rules`.

---

### Promotion / Reclass Modal

**Scene:** `PromotionScreen.tscn` (the reclass picker mirrors this layout)
**Trigger:** auto-promotion at the class cap, or using a promotion seal (the
modal/interrupt timing is owned by GDD_02 → Promotion — Trigger Timing)

A full-rect `Dimmer` + a centered `PanelContainer` listing one button per
`promotes_to` target. Each button shows the class name, a per-stat
`old +Δ -> new / cap` preview line, and the class's learned skills.

The panel is **centered via anchors with symmetric grow**, and the option
buttons **autowrap** their long stat-preview line within a capped panel width.
This is deliberate: the per-stat preview is wide, so a left-pinned fixed-offset
panel (the pre-fix layout) ran off the right edge of the screen at the play
resolution. Symmetric grow guarantees that even if content does expand, it stays
centered rather than spilling past one edge.

The reclass picker (`ReclassScreen.tscn`, Second Seal) uses the **same centered
panel**; it additionally wraps its longer option list in a `ScrollContainer`
(reclass can offer many targets, where promotion offers ≤3). That scroll container
**scrolls vertically only** (`horizontal_scroll_mode` disabled), which width-caps
each option button to the panel so its buttons **autowrap** their long
`old +Δ -> new / cap` line the same way the promotion buttons do — without a
horizontal scrollbar (playtest v0.1.5.0 #8.6). Both modals were left-pinned
originally; the reclass panel was re-centered alongside the promotion fix (code
review 2026-06-14 #1) for resolution-robustness.

---

### Game Over Screen

**Trigger:** `EventBus.map_defeat`, `EventBus.map_victory`, and `EventBus.map_resolved`

**Layout (full-screen dark overlay):**
```
[dark overlay fades in over 1 second]

        DEFEAT / VICTORY / DRAW

   [ Retry Map ]
   [ Quit to Menu ]
```

- "Retry Map" reloads the current map from scratch
  (player unit stats and inventory are preserved from map start — not mid-map)
- Unit data is **never deleted** (permadeath only sets `is_incapacitated`)
- The current screen also renders ranked standings when `map_resolved` supplies them
- **Presents under pending progression** (`B5-VICTORY-PROGRESSION-SEQ`): a result that
  lands while a level-up or promotion is still on screen is held, and the overlay appears
  only once the level-up/promotion queue has drained — so progression earned on the
  killing blow (kill → level up → promote → THEN victory) resolves first. `GameOverScreen`
  tracks the `level_up_started/finished` + `promotion_started/finished` signals and defers
  its present; a promotion queued behind a level-up starts synchronously during
  `level_up_finished`, so the re-check is deferred a frame to let that cascade settle.
- "Quit to Menu" resets map-scoped state and returns to `Boot.tscn`

---

### Victory Screen

There is **no separate `VictoryScreen` scene** — `GameOverScreen.tscn` /
`GameOverScreen.gd` serves victory, defeat, and draw. It switches the title based on
the emitted outcome and may render multi-group standings below the header.

---
