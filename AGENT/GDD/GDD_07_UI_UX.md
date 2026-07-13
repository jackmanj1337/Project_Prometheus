# GDD_07 — UI & UX

**Status:** Active contract — split status per section (most UI surfaces are
**Implemented**; combat-animation feedback and HUD scale polish are **Planned**).
UI is project-specific; it has no corpus-adoption rows.
**Last verified:** 2026-07-13
**Governance:** section template + status vocabulary in
`AGENT/Docs/governance/documentation_governance_2026-06-13.md`.

This chapter owns the UI surfaces, input map, input parity (keyboard/mouse + hotseat),
and accessibility contracts. Platform/renderer targets (desktop primary, Steam Deck
letterbox, web playtest, gamepad with the rebind milestone — OPEN-8/11) are owned by
`GDD_00 §Platform Targets`; the `SettingsManager` schema is owned by `GDD_01`.

---

## Design Reference

Status: **Reference** (design principles)
Last verified: 2026-06-13

The UI is inspired by **Fire Emblem: The Blazing Blade (GBA)**. Key principles:

- Clean, minimal overlays that do not block map visibility unnecessarily
- All important numbers are always visible before the player commits to an action
- Panels appear and disappear quickly; no slow animations on menus
- Keyboard-primary input with full mouse support

---

## Input System

Status: **Implemented** (keyboard + mouse parity; gamepad binding/menu-control,
headless map-cursor decoder, profile-ready keybind persistence, and key-rebind capture
for keyboard/mouse + gamepad); live controller feel **Target design** / pending
validation.
Last verified: 2026-07-12

All input is handled through Godot's **Input Map** (defined in Project Settings).
`MapCursor.gd` is the primary input handler during gameplay.
`MapCursorInput.decode(event)` translates keyboard and d-pad/button events into
state-agnostic intents; `_process()` polls the cursor vector for left-stick
movement and the zoom action strengths for held LT/RT zoom.

### Action Definitions

| Action | Primary Keys | Mouse | Gamepad |
|---|---|---|---|
| `cursor_up` | W, Up Arrow | — | D-pad Up / Left Stick Up |
| `cursor_down` | S, Down Arrow | — | D-pad Down / Left Stick Down |
| `cursor_left` | A, Left Arrow | — | D-pad Left / Left Stick Left |
| `cursor_right` | D, Right Arrow | — | D-pad Right / Left Stick Right |
| `confirm` | Z, Enter, Space | Left Click | Pad A |
| `cancel` | X, Escape | Right Click | Pad B |
| `next_unit` | Tab | — | RB |
| `prev_unit` | Shift + Tab | — | LB |
| `show_danger_zone` | Q (threat resolver) | Middle Click (threat resolver) | R3 |
| `peek_range` | E (hold to peek) | — | View (hold) |
| `inspect_unit` | I | — | Pad Y |
| `more_info` | F | — | Pad X |
| `open_menu` | M; also confirm/cancel on an empty tile | Left/Right Click on an empty tile | Start |
| `open_settings` | O | — | via Start -> Settings |
| `zoom_in` | = | Wheel Up | RT |
| `zoom_out` | - | Wheel Down | LT |
| `zoom_reset` | 0 | — | L3 |
| `debug_toggle_hotseat_override` | F9 | — | — |

`show_danger_zone` is the **threat resolver** (free cursor state only, see
*Threat Overlay* below): over a hostile attack-capable enemy it toggles that
enemy's membership in a persistent **watch set**; over empty/terrain it cycles
the **danger mode**. `open_settings`
opens the Settings screen during a map (see Map Menu / Settings Screen below).
`debug_toggle_hotseat_override` is debug-build-only; it temporarily routes every
faction through hotseat control for live testing and is listed in the debug HUD
banner as `hotseat-all` while active.

> **Menus and the game's keys.** Menus (Main Menu, Map Menu, Settings, the
> Action / Item menus) navigate via Godot's built-in `ui_*` actions.
> `SettingsManager._mirror_game_keys_to_ui()` copies the `cursor_*` / `confirm` /
> `cancel` bindings onto `ui_*` at startup, so WASD / Z / X and their pad
> equivalents drive menus exactly as they drive the map cursor. Saved bindings use
> per-device slots (`kbd`, `pad`), so rebinding one device class preserves the other.

> **On-screen prompts follow the active scheme (B6-INPUT prompt swapping).** Player-facing
> control hints — the level-up "Press _X_ to continue" line and the More Info hints on the
> combat forecast, character sheet, and compact terrain panel — render the binding for the
> **active input mode** (`InputModeManager.active_input_mode`) and re-render live when the
> scheme changes. In keyboard/touch modes they show the key (or a tap verb); in gamepad mode
> they show the **brand-correct pad label**. Because SDL normalizes button _position_
> (`JOY_BUTTON_A` = physical bottom on every pad), the bindings are brand-correct with no
> per-brand code; only the printed label differs — Nintendo swaps the A/B and X/Y positions
> vs Xbox, and PlayStation prints words such as `Cross` / `Square` until the `UI-INSPECTION`
> glyph pass proves font coverage. Brand is classified heuristically from the last active
> joypad device's `Input.get_joy_name()` (Godot has no native controller-type API), so a
> wrong guess is cosmetic, never a mis-input. `InputDisplay` owns the mode/brand-aware
> prompt helpers; `InputModeManager` owns last-active-pad tracking.

### Mouse Behavior
- **Left Click on tile:** Same as moving cursor to that tile and pressing `confirm`
- **Right Click:** Same as pressing `cancel`
- **Hovering** over a tile with the mouse moves the cursor to that tile instantly
  (no movement delay — cursor teleports to hovered tile)
- Mouse and keyboard cursor control can be mixed freely at any time

### Threat Overlay

Status: **Implemented** (watch set + mode cycle; source-4 darker-red watch tile
authored as a placeholder colour; "D" markers; suspend restore of
watch-set/mode state; MRD-7 selection/targeting compose plumbing and
shared-cell visual prototypes including the v0.3.1-requested dual outline)
Last verified: 2026-07-12

The `show_danger_zone` action (MMB / Q / R3) drives two orthogonal pieces of state through one resolver, in
the free cursor state only:

- **Watch set** — a persistent set of hostile, attack-capable enemies the player
  hand-picks. The resolver over such an enemy toggles its membership (stored as
  stable unit ids, so a defeated enemy is pruned and a suspend save can
  round-trip them). Each watched enemy shows a small **"D"** marker on its tile.
- **Danger mode** — the overlay display mode, one of exactly **`none`**,
  **`full`**, **`selected`**, **`combined`**. The resolver over empty terrain
  cycles `full → selected → combined → none` (starting from `none → full`).
  - `full` paints every hostile enemy's threat (dark red).
  - `selected` paints the watch set's threat (a distinct darker red).
  - `combined` paints both, with the watch set winning shared cells.
  - `none` paints no threat.

Adding a member auto-promotes the mode on the empty→non-empty transition
(`none→selected`, `full→combined`); removing the last member auto-demotes it
(`selected→none`, `combined→full`). The overlays share one layer, ordered by the
[MRD-1] overlay precedence registry (range < faction threat < watch threat <
opaque top layers). The set + mode survive phase changes, menus, and unit
selection (teardown clears only the paint; a return to the free state recomputes
it from live positions); a fresh map load clears them, while a suspend resume
restores them from `suspend.watch_set` / `suspend.danger_mode`.

Selection and targeting overlays are built as registry layer specs and composed
with retained threat specs, so selecting a unit or entering attack/staff/pair-up
targeting does not clear watched-threat paint or "D" markers ([MRD-7]).
Threatened tiles inside movement/target range have five debug render modes:
`single_layer`, `border_through`, `stacked`, `stacked_perimeter`, and
`dual_outline`. `border_through` bakes threat colour into the tile center with
a strong range-colour border on the shared overlay layer; `stacked` paints
retained threat on the base overlay and range on a second `TileMapLayer`;
`stacked_perimeter` keeps that stacked fill and swaps threat tiles to generated
edge-mask sources based on the union of threatened tiles, creating one outline
around each contiguous threat area. `dual_outline` (V031-MRD-01, the
v0.3.1-requested candidate, 2026-07-12) keeps the stacked fill and strokes two
strong world-space outlines on a `ThreatPerimeterOverlay` draw surface rendered
**above unit sprites**: a bright-red line around the union of ALL threatened
tiles and a dark-red line around the WATCHED subset, dark drawn over bright on
shared edges (colours/widths are exported placeholders for the live
comparison). The default remains `single_layer` until the focused live rerun
accepts a presentation; debug builds can cycle the five modes with **F8** for
that comparison pass.

**Hover-to-peek** (`peek_range`, hold **E**, free cursor state) previews the
unit under the cursor's reach — blue move range + red attack reach — as an
exclusive opaque top layer over any threat overlay. The reach is computed once
per hovered unit and cached: moving the cursor to a *different* unit recomputes,
staying on the same unit reuses the cache (no per-tick recompute). Releasing the
key clears the peek and restores the threat overlay.

**Movement path arrows.** While a unit is selected, a directional chain traces
its cheapest path (`get_movement_path`) from the unit to the cursor tile, drawn
above the blue move-range overlay. Only the path to the *current* cursor tile is
recomputed as the cursor moves (no range recompute); it clears on move-commit or
deselect. (Placeholder polyline render — UI polish may swap for arrow-tile art.)

### Cursor Direction Repeat
When a directional key, d-pad direction, or left-stick direction is held:
- First move: immediate
- Delay before repeat begins: 0.25 seconds
- Repeat rate: every 0.10 seconds

Custom modal menus that own selection (`ActionMenu`, `UnitDetailsScreen`) use
a slower menu-specific 0.30s / 0.15s policy through `MenuRepeatPolicy` instead
of per-event stick-axis stepping, so a held stick/key has one immediate step
followed by stable repeat. Menus stepped at the map-cursor cadence until the
v0.3.1 return called that "a little fast" for discrete rows (V031-GP-03,
2026-07-12); `MENU_KEY_REPEAT_DELAY/RATE` now own the menu timing while the
map cursor keeps 0.25s / 0.10s.

Engine-focus modals (`SettingsScreen`, `NewGameScreen`, Promotion/Reclass) use
the shared `ModalScreen` vertical repeat path. Horizontal input stays with the
focused control, so sliders and option buttons keep their own left/right
behavior. While a capture-mode UI is active — an open `OptionButton` dropdown
or any other embedded popup Window — the polled repeat and focus containment
stand down entirely, and the popup-close frame re-latches the repeat to
neutral, so picking from a dropdown never moves the panel focus behind it
(V031-GP-02, fixed 2026-07-12; the polled `Input` singleton cannot see event
capture, so the standdown is checked explicitly).

Held map zoom ignores LT/RT values below a 0.35 activation threshold. Any pull
past the threshold steps the zoom once, then repeats on one constant slow
cadence (0.45s initial delay and per-step rate) — pull depth does not change
the speed. The earlier strength-scaled timer (0.45s to 0.18s by pull depth)
kept reading as "too sensitive" on live returns and was removed by owner
decision on the v0.3.1 return (2026-07-12, V031-GP-04); per-player sensitivity
sliders remain a `B6-INPUT` backlog item. The live feel check rides the next
focused rerun.

---

## Cursor System

Status: **Implemented** (static cursor art; animated art is a later presentation pass)
Last verified: 2026-06-13

The `MapCursor` is a `Node2D` with a `Sprite2D` child.
It sits on top of all tiles and indicates the currently focused tile.

At map start `GameMap` places the cursor on the first player unit (via
`MapCursor.center_on_tile()`), not the map's (0,0) corner, so play begins
focused on the player's force.

**Visual:** current cursor art is a static 64x64 sprite. Animated cursor art is
a future presentation pass.

**States:**
- `free` — cursor moves freely; hovering shows unit/terrain info
- `unit_selected` — a controllable unit is selected; movement range shown in blue
- `unit_moved` — selected unit has moved; action menu is open
- `targeting` — the active controller is selecting a target; attack range shown in red
- `locked` — cursor cannot move (during animations or controller handoff)

**State Transitions:**
```
free
  → [confirm on controllable unit] → unit_selected
  → [confirm or cancel on an empty tile, or the open_menu key (M)]
        → map menu opens (cursor locked until it closes)
  → [cancel over an unselected unit] → that unit's character sheet opens (V021-16)

unit_selected
  → [confirm on move tile] → unit_moved (unit moves)
  → [cancel] → free (deselect)
  → [next_unit] → unit_selected (select next unacted unit)

unit_moved
  → [Attack] → targeting
  → [Staff] → targeting (green overlay for allies)
  → [Item / Wait] → free (action resolved)
  → [cancel] → unit_selected (undo move)

targeting
  → [confirm on valid target] → show AttackPreview
    → [confirm] → resolve combat → free
    → [cancel] → targeting
  → [cancel] → unit_moved (back to action menu)

locked
  → [automatic] → previous state (unlocked by TurnManager after animation)
```

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
setup screen that writes per-run rules onto `GameState`, then launches the chosen
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
  to `GameState` the moment they change, so closing the panel with Back and reopening
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
  target; `Click` waits for a click/tap to move, and `Off` ignores mouse motion.
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
Focus stepping keeps ~1.5 rows of lookahead context visible past the focused
row in the movement direction (V031-GP-01, 2026-07-12) — `follow_focus` alone
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
  per-save rules chosen on the **New Game** screen and stored on `GameState`.

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

## UI State Machine

Status: **Implemented**
Last verified: 2026-06-13

The HUD operates as a state machine. Only one primary panel is active at a time.
`MapCursor` manages state and shows/hides panels by calling methods on `HUD`.

```
HUD States:
  FREE          — UnitInfoPanel + TerrainInfoPanel + ObjectivePanel visible
  UNIT_SELECTED — same as FREE (movement overlay active)
  ACTION_MENU   — contextual ActionMenu visible
  TARGETING     — target cycling active; AttackPreview may be visible
  STAFF_TARGET  — target cycling active for healing staff use
  ITEM_MENU     — ItemMenu visible
  WEAPON_MENU   — WeaponMenu visible
  MAP_MENU      — MapMenu visible (pauses cursor)
  DETAILS       — UnitDetailsScreen visible
  LEVEL_UP      — LevelUpScreen visible (cursor locked)
  PROMOTION     — PromotionScreen visible
  RECLASS       — ReclassScreen visible
  RESULTS       — GameOverScreen visible for victory / defeat / draw
  LOCKED        — cursor input suspended during animation or controller handoff
```

---

## Visual Feedback Summary

Status: **Split** — state/HP/level-up feedback **Implemented**; combat hit/miss/crit/death FX **Planned** (with the combat-animation system)
Last verified: 2026-06-13

| Event | Visual Feedback |
|---|---|
| Unit selected | Blue movement tiles appear; a dedicated selection ring is planned |
| Unit moved | Blue/red tiles update for new position |
| Unit acted (DONE) | Unit sprite darkened/greyed |
| New player phase | All unit sprites return to normal color |
| Attack hits | [PLACEHOLDER] brief flash on target sprite |
| Attack misses | [PLACEHOLDER] "Miss" text above target |
| Critical hit | [PLACEHOLDER] brighter flash; different sound |
| Unit dies | [PLACEHOLDER] death animation; unit fades out |
| Unit healed | [PLACEHOLDER] green flash; HP bar updates |
| Level up | Gold flash on unit sprite; LevelUpScreen shown |
| Weapon breaks | [PLACEHOLDER] weapon removed from inventory notification |

---

## Accessibility & Input Parity

Status: **Split** — implemented options listed below **Implemented**; combat-animation
toggle **Planned**
Last verified: 2026-06-15

### Summary
The accessibility and parity contract the UI must honor across input methods and players.

### Specs

**Implemented.**
- **Input parity:** every gameplay action is reachable by keyboard and mouse;
  the first gamepad binding slice adds pad defaults for normal-play actions while
  keeping debug actions keyboard-only. `SettingsManager._mirror_game_keys_to_ui()`
  mirrors `cursor_*`/`confirm`/`cancel` onto Godot `ui_*` so menus and the map
  cursor share bindings.
- **Key rebinding:** Settings derives rows from the live `InputMap` and exposes
  keyboard/mouse and gamepad capture for every normal game action. Captures stage in a
  pending buffer; same-slot conflicts block Apply until Clear/Revert/recapture resolves
  them. Debug-only actions stay read-only.
- **Hotseat parity:** non-blue human (hotseat) phases use blue's commit/UI flow — only
  the commandable faction differs (GDD_02 §Turn Structure). No player has a UI affordance
  another lacks.
- **Mouse Cursor mode** (`mouse_cursor`, `follow|click|disabled`): `Follow` is hover-to-cursor,
  `Click` is touch-friendly first-click move / second-click confirm, and `Disabled` ignores
  all mouse *motion* so stray bumps cannot nudge the cursor during keyboard play (PT4 #1).
  Click mode also lets a mouse/touch player cycle terrain More Info by clicking the terrain
  panel.
- **Pacing options:** `movement_speed` (Normal/Fast/Instant), `phase_banner` (Show/Skip),
  `level_up_screen` (Show/Auto/Skip) let players reduce animation/wait time.
- **Always-visible numbers:** all combat-relevant values (Hit/Dmg/Crit, terrain bonuses,
  WEXP, modifiers) are shown before commit (Attack Preview, Unit Details + More Info).
- **Menu Scale** (`menu_scale_index` → `SettingsManager.MENU_SCALE_LEVELS`, 0.5×–2.0×):
  a Settings stepped slider scales menu/modal panels through the shared
  `menu_scale_targets` group. It does not change `Window.content_scale_factor`, so
  persistent HUD readouts remain governed by HUD Layout. **Crisp scaling (V021-18 / D2,
  v0.2.3):** `MenuScale.apply_to` leaves `Control.scale` at ONE and scales *type* instead
  of bitmap-stretching the panel (the old blur source). A factor-scaled `Theme` (derived
  from the engine default `default_font_size` + container metrics, cached per factor)
  drives every default-sized label, and a tree-walk scales each explicit
  `theme_override_font_sizes` / `theme_override_constants` off a captured base (titles,
  etc.) without compounding on re-apply. Text is rendered at its true pixel size at every
  factor, so it stays crisp. Centered panels are recentred at their natural size (the
  CENTER anchor preset); a panel built around a `ScrollContainer` keeps its authored frame
  and scrolls, everything else shrink-wraps to content. **V021-08 (clamp):** when a
  grow-to-content menu's scaled content would overflow the viewport, the applied factor is
  dialled down (uniform, min-axis) so its top/bottom stay reachable — now by reducing the
  *font factor*, not the bitmap scale. `LevelUpScreen`'s panel was converted `Panel`→
  `PanelContainer` (+ a `MarginContainer`) so it shrink-wraps the variable-length stat list
  instead of the old manual offset juggling. *Deviation from the D2 design doc:* the scenes
  still carry per-node font overrides, so we derive the theme at runtime and walk the
  overrides rather than restyling all ~11 scenes onto one authored base Theme — factor 1 is
  byte-identical to today, and an authored base Theme can later seed the derived theme.
  **V023-01:** the Settings screen itself uses stable row label/control columns after each
  live scale pass so dragging the Menu Scale slider does not move the slider under the
  pointer. Existing saves migrate old scale indices forward one slot so adding `0.5×` does
  not turn a saved `1.0×` into `0.75×`; the shift only applies when the cfg actually
  stored an index, so a pre-menu-scale cfg keeps the `1.0×` default (v0.2.5 guard).
  **V023-01 vertical follow-up (v0.2.5):** the column lock only held the x-axis — rows
  above the slider still changed height with the new font size, shifting it vertically
  mid-drag. `SettingsScreen.apply_menu_scale` now anchors the slider's row: it captures
  the row's on-screen y before the re-scale and restores it one (deferred-layout) frame
  later via the panel `ScrollContainer`'s `scroll_vertical`. The compensation clamps at
  the scroll extremes, where a small residual shift is accepted.
  **V027-04a / V030D-DSP-02 (resize self-heal):** `SettingsManager` re-applies
  Menu Scale from viewport and root-Window `size_changed` signals (deferred, coalesced
  to one pass per settled frame). The root-Window signal covers one-axis edge drags
  where the OS client size changes but the kept 16:9 viewport does not.
  **V028-03 (reactive re-center, root cause):** centering itself is now a standing
  reactive constraint, not a per-trigger deferred bake. Each centered panel's own
  `resized` signal drives `MenuScale._recenter`, so it re-centers at the exact frame the
  *panel* size settles. The previous code hard-set `target.size` then baked absolute
  CENTER offsets against the size at that instant; Godot computes the real final size in
  a later deferred layout pass, so any post-bake growth left the panel off-center until
  the next explicit re-apply — one bug patched per-trigger four times (V025-05a first
  show, V026-01a 2.0× apply, V027-04a edge drag, V028-03 Windows maximize, whose
  window-mode change reflows across several frames so a single deferred re-apply fired
  too early). A re-entrancy guard skips the nested pass emitted by our own size write.
  (The clean structural form — wrap each panel in a `CenterContainer` and delete the
  imperative `_recenter` — is deferred to `UI-VIEWPORT-ASPECT`.)
- **Display controls** (window mode + windowed resolution): see
  `GDD_01_Architecture.md` §Rendering and Display Settings. The Settings
  readout distinguishes preset requests, custom client sizes, native
  Borderless/Fullscreen size, and transient maximize state: while a Windowed
  window is maximized it shows live **`Maximized (W×H)`** from the actual client
  size, then returns to the saved windowed readout on restore. Settings listens to
  the settled display-size notification, so this label refreshes even when maximize
  correctly avoids a Resolution write-back; maximize is still never persisted as a
  Resolution value.
- **Map zoom** (0.25×–4×, scroll wheel / `+`/`-`/`0`): the Settings slider applies
  immediately when a map is active and persists through `SettingsManager`; see
  `GDD_01_Architecture.md` §Camera Zoom.
- **Terrain Dim** (`grid_dim`, 0%–50%, [MRD-5]): a Settings slider fades the terrain
  `TileMapLayer` only (units + overlays stay full opacity) so threat/range overlays
  read more clearly against busy terrain. Applied live to every layer in the
  `grid_dim_target` group via `SettingsManager.set_grid_dim`; persists like the other
  display floats. Default 0% (no dim).
- **Per-panel HUD layout** (`hud_layout`, Display & Accessibility item 4): the player
  repositions and scales the five persistent HUD readouts (phase/turn labels, unit
  info, objective, terrain corner) via an in-map "Edit HUD Layout" mode (drag frames +
  per-panel Scale, Reset/Done/Cancel). Editor affordances (V020-12): each panel frame
  has a bright-red outline (yellow when selected) drawn with styleboxes, the scale
  buttons read `Scale Panel −/+`, and every frame shows editor-only sample text whose
  font scales with the panel so the chosen size is visible (the sample never touches
  the live HUD nodes; the frame clips it to its bounds so it can't overflow — V021-03).
  The editor is a **hard modal** (V021-02): while it is open `HudLayoutEditor._input`
  swallows every non-mouse input and routes `cancel` to its own Cancel, so the map
  cursor / menus underneath stay inert even if the launching Settings screen is
  dismissed. Persisted per panel as `{ offset, scale }` in
  `SettingsManager.hud_layout`; applied by `HUD.apply_layout` with an on-screen clamp.
  Scope: the persistent readouts only — contextual menus (cursor-anchored) are not
  movable and use Menu Scale instead.
  Terrain More Info expands above the compact terrain panel; layout offsets anchor the
  compact panel so Reset/Edit keep it in place while the expanded box is open.
  **Terrain More Info paging (V021-05):** the `more_info` key (`F`) cycles the terrain
  surface **Hidden → Description → Movement → Hidden** (`_terrain_more_page`: −1 hidden,
  0 description + tile actions, 1 the move-cost table incl. the Flying row). "Hidden" is
  the default and fully hides the box so the map area behind it is reclaimed; the compact
  readout stays visible. Pages are logical groupings of the existing expanded rows (no
  scene-tree restructure), so the panel auto-sizes to the active page and
  `_terrain_expanded_offset` derives the reflow from the active page's height — which
  hardens the V021-02 reset bug (the offset is computed, never cached). `Def`/`Dodge`
  live on the always-visible compact panel, so the movement page doesn't restate them.
  Click-mode paging hit-tests both the compact panel and the expanded More Info panel, so
  clicking the Movement page cycles back to Hidden reliably (V023-09a).
- **Safe-area provider (V021-19 / D5 / E6):** HUD edge-anchoring (`HUD._clamp_panel_on_screen`)
  reads a single source — `SettingsManager.get_safe_area_insets()` → `Vector4i(left, top,
  right, bottom)` — so the on-screen clamp respects unsafe screen margins (notch / rounded
  corners / home-indicator). It returns **zero on desktop and in the browser** (the web
  shell reserves its bottom inset via CSS outside the canvas), so desktop layout is
  unchanged. A soon mobile-web release feeds real in-canvas insets by writing the one
  `safe_area_insets` member (from `DisplayServer.get_display_safe_area()` / `JavaScriptBridge`)
  with no call-site re-plumbing; mobile stays **Deferred** as a platform until that feed lands.
- **HUD panel scale stays `panel.scale` for now (D3):** the per-panel HUD scale keeps using
  `Control.scale`; the crisp font/metric rework (V021-18) is staged to menus/modals first
  (the web-visible win). The bottom-right terrain-corner pivot polish (**V021-04**) remains
  **Deferred** until the HUD migrates onto the crisp path.

**Planned.**
- **Combat-animation toggle** (`combat_animations`): scaffolded but hidden until a
  combat-animation system consumes it.

### Anchors
- Code: `scripts/autoloads/SettingsManager.gd`, `scripts/core/MapCursor.gd`,
  `scripts/core/HotseatController.gd`
- Tests: `scripts/tests/test_settings_manager.gd`, `test_settings_screen.gd`
- Decisions: OPEN-11 (GDD_00 §Platform Targets)
- Owner of platform/renderer targets: GDD_00; SettingsManager schema: GDD_01
