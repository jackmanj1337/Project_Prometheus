# GDD_07 — UI & UX

---

## Design Reference

The UI is inspired by **Fire Emblem: The Blazing Blade (GBA)**. Key principles:

- Clean, minimal overlays that do not block map visibility unnecessarily
- All important numbers are always visible before the player commits to an action
- Panels appear and disappear quickly; no slow animations on menus
- Keyboard-primary input with full mouse support

---

## Input System

All input is handled through Godot's **Input Map** (defined in Project Settings).
`MapCursor.gd` is the primary input handler during gameplay.

### Action Definitions

| Action | Primary Keys | Mouse |
|---|---|---|
| `cursor_up` | W, Up Arrow | — |
| `cursor_down` | S, Down Arrow | — |
| `cursor_left` | A, Left Arrow | — |
| `cursor_right` | D, Right Arrow | — |
| `confirm` | Z, Enter, Space | Left Click |
| `cancel` | X, Escape | Right Click |
| `next_unit` | Tab | — |
| `prev_unit` | Shift + Tab | — |
| `show_danger_zone` | Q (toggle) | Middle Click (toggle) |
| `open_menu` | M; also confirm/cancel on an empty tile | Left/Right Click on an empty tile |
| `open_settings` | O | — |

`show_danger_zone` is a **toggle** (press once to show the enemy threat area,
again to hide it) and works only in the free cursor state. `open_settings`
opens the Settings screen during a map (see Map Menu / Settings Screen below).

> **Menus and the game's keys.** Menus (Main Menu, Map Menu, Settings, the
> Action / Item menus) navigate via Godot's built-in `ui_*` actions.
> `SettingsManager._mirror_game_keys_to_ui()` copies the `cursor_*` / `confirm` /
> `cancel` bindings onto `ui_*` at startup, so WASD / Z / X drive menus exactly
> as they drive the map cursor.

### Mouse Behavior
- **Left Click on tile:** Same as moving cursor to that tile and pressing `confirm`
- **Right Click:** Same as pressing `cancel`
- **Hovering** over a tile with the mouse moves the cursor to that tile instantly
  (no movement delay — cursor teleports to hovered tile)
- Mouse and keyboard cursor control can be mixed freely at any time

### Cursor Key Repeat
When a directional key is held:
- First move: immediate
- Delay before repeat begins: 0.25 seconds
- Repeat rate: every 0.10 seconds

---

## Cursor System

The `MapCursor` is a `Node2D` with an `AnimatedSprite2D` child.
It sits on top of all tiles and indicates the currently focused tile.

At map start `GameMap` places the cursor on the first player unit (via
`MapCursor.center_on_tile()`), not the map's (0,0) corner, so play begins
focused on the player's force.

**Visual:** [PLACEHOLDER] A flashing yellow/white square outline, 64×64 px.
Animation: 4-frame blink at 8 fps.

**States:**
- `free` — cursor moves freely; hovering shows unit/terrain info
- `unit_selected` — a player unit is selected; movement range shown in blue
- `unit_moved` — selected unit has moved; action menu is open
- `targeting` — player is selecting an enemy to attack; attack range shown in red
- `locked` — cursor cannot move (during animations, enemy phase)

**State Transitions:**
```
free
  → [confirm on player unit] → unit_selected
  → [confirm or cancel on an empty tile, or the open_menu key (M)]
        → map menu opens (cursor locked until it closes)

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

---

### Main Menu

**Scene:** `MainMenu.tscn`
**Trigger:** Game start / quit from map

**Layout (centered on 1280×720):**
```
┌─────────────────────────────────┐
│    [PLACEHOLDER — Game Title]   │
│                                 │
│         [ New Game ]            │
│         [ Continue ]     (greyed if no save — Phase 2)
│         [ Settings ]            │
│         [ Quit ]                │
└─────────────────────────────────┘
```

**Behavior:**
- "New Game" → character creation flow (Phase 2) or directly to map 001 for MVP
- "Continue" → load save (Phase 2)
- "Settings" → opens Settings screen (see below); available from MVP onwards
- For MVP: "New Game", "Settings", and "Quit" are functional

---

### In-Map HUD (persistent overlay)

The HUD is always visible during a map. It uses a `CanvasLayer` so it is unaffected
by camera movement.

**Layout:**

```
┌──────────────────────────────────────────────────────┐  ← top of screen
│ Phase Label (top-left)           Turn Label (top-right)│
│ e.g. "Player Phase"              e.g. "Turn  3"        │
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

**Terrain Info Panel** (`TerrainInfoPanel.tscn`):
- Always shown (updates as cursor moves)
- Shows terrain name, DEF bonus, Dodge bonus
- Size: ~180 × 80 px

**Phase Label:**
- Text: "Player Phase" (blue) or "Enemy Phase" (red)
- Updates on phase change; fades in briefly after banner

**Turn Label:**
- Text: "Turn  3"
- Increments at the start of each Player Phase

---

### Phase Banner

**Scene:** `PhaseBanner.tscn`
**Trigger:** Each phase change

**Layout:**
```
[full-width colored bar slides in from right, pauses, slides out to left]
┌────────────────────────────────────────┐
│           PLAYER PHASE                 │   ← blue background
└────────────────────────────────────────┘
```

**Animation (Tween):**
1. Banner starts off-screen right (x = 1280)
2. Slides to center (x = 0) over 0.3 seconds
3. Holds for 0.8 seconds
4. Slides off-screen left (x = -1280) over 0.3 seconds
5. `cursor.unlock()` called after animation completes

Colors:
- Player Phase: dark blue background, white text
- Enemy Phase: dark red background, white text

Font size: 40px, bold [PLACEHOLDER font]

---

### Action Menu

**Scene:** `ActionMenu.tscn`
**Trigger:** After a player unit successfully moves (or confirms on its current tile)

**Layout (positioned near the moved unit, offset to avoid covering it):**
```
┌────────────┐
│  Attack    │  ← disabled if no enemies in range
│  Staff     │  ← disabled if no healing staff / no targets in range
│  Item      │  ← disabled if no usable items
│  Wait      │  ← always available
└────────────┘
```

> Buttons: `BtnAttack`, `BtnStaff`, `BtnItem`, `BtnWait`. **Trade is designed but
> not yet implemented** — there is no Trade button in the current `ActionMenu.tscn`.

**Behavior:**
- Menu appears adjacent to the unit's new tile; repositioned if too close to screen edge
- Navigate with `cursor_up` / `cursor_down` (wraps, skipping disabled buttons);
  confirm with `confirm`; close with `cancel`
- Closing with cancel triggers undo: unit returns to its pre-move tile

**Button widths:** 120 px; height per button: 30 px
**Font size:** 18px

---

### Target Selection

**Trigger:** Player selects "Attack" or "Staff" from the Action Menu.
**Owner:** `MapCursorTargeting` (a `RefCounted` slice of `MapCursor`).

There is **no target-list panel**. Target selection happens on the map itself:

- The valid target tiles are highlighted with overlay tiles — **red** for Attack
  targets, **green** for Staff (heal) targets.
- The cursor snaps to the first valid target. Direction keys **cycle** the cursor
  between valid target tiles (the list wraps). With the mouse, motion snaps the
  cursor to the nearest valid target — unless Mouse Targeting is "Keyboard Only".
- `confirm` on an Attack target opens the Attack Preview; `confirm` on a Staff target
  applies the heal immediately. `cancel` returns to the Action Menu.

---

### Attack Preview Panel

**Scene:** `AttackPreview.tscn`
**Trigger:** Player selects a target from the Target Select List

**Layout (centered at bottom of screen, above terrain panel):**
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
  their Hit/Dmg/Crit shows `--`
- If attacker gets a follow-up, show `×2 attacks` below their crit
- Preview is calculated by `CombatResolver.preview_combat()` — no RNG
- Confirm triggers `CombatResolver.resolve_combat()` (with RNG)

**Size:** ~500 × 130 px
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
- Player presses `confirm` to dismiss
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
- `Close`: closes the map menu and returns to the map.
- `cancel` also closes the map menu.

> A *Quit to Menu* entry is designed but not yet built — the MVP `MapMenu.tscn`
> has only End Turn / Settings / Close.

---

### Settings Screen

**Scene:** `SettingsScreen.tscn`
**Trigger:** "Settings" button in Main Menu or Map Menu, or the `open_settings`
key (O) during a map
**Script:** `scripts/ui/SettingsScreen.gd`

The Settings screen is a single panel — **not tabbed**. A full-rect opaque
`Dimmer` behind the panel makes it modal (the screen behind is fully hidden).
The panel's contents live in a `ScrollContainer` so the list never overflows.
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
│   Mouse Targeting    [ Snap to Target ▾ ]         │
│   ─────────────────────────────────────────       │
│   Controls                                        │
│   Move Up               W / Up                    │
│   Confirm               Z / Enter / Space         │
│   ... (one row per game action — read-only)        │
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

**Mouse Targeting** (`mouse_targeting`, default `"snap"`) — `Snap to Target` makes
mouse motion during target selection jump the cursor to the nearest valid target;
`Keyboard Only` ignores mouse motion while targeting.

#### Controls (read-only)

A **Controls** section lists every game action and the key(s) bound to it,
read live from the `InputMap` when the screen opens (`_populate_keybindings()`
builds one row per action). It is **display-only** — there is no rebind UI in the
MVP. `SettingsManager` already stores a `keybindings` dictionary and applies it to
the `InputMap` at startup, so a rebind UI is the only missing piece (Phase 2).

#### Hidden / not yet implemented

- **Combat Animations** (`combat_animations`) — a `SettingsManager` field with an
  `OptCombatAnim` control that is **hidden**: no combat-animation system consumes the
  setting yet (MVP combat is instant). It will be shown when that system lands.
- **Key rebinding** — the Controls section above is read-only; letting the player
  reassign keys is Phase 2.
- **Permadeath** and **Leveling Method** are *not* on the Settings screen — they are
  per-save rules chosen on the **New Game** screen and stored on `GameState`.

---

### Game Over Screen

**Trigger:** `EventBus.map_defeat` signal

**Layout (full-screen dark overlay):**
```
[dark overlay fades in over 1 second]

        GAME OVER

   [ Retry Map ]
   [ Quit to Menu ]
```

- "Retry Map" reloads the current map from scratch
  (player unit stats and inventory are preserved from map start — not mid-map)
- Unit data is **never deleted** (permadeath only sets `is_incapacitated`)

---

### Victory Screen

**Trigger:** `EventBus.map_victory` signal

There is **no separate `VictoryScreen` scene** — `GameOverScreen.tscn` /
`GameOverScreen.gd` serves **both** outcomes: a "VICTORY" title on `map_victory` and
a "GAME OVER" title on `map_defeat`. The next-map / campaign flow beyond the current
map is a `[PLACEHOLDER]` (campaign structure is Phase 2).

---

## UI State Machine

The HUD operates as a state machine. Only one primary panel is active at a time.
`MapCursor` manages state and shows/hides panels by calling methods on `HUD`.

```
HUD States:
  FREE          — UnitInfoPanel + TerrainInfoPanel visible
  UNIT_SELECTED — same as FREE (overlays on map, no extra panel)
  ACTION_MENU   — ActionMenu visible
  TARGETING     — TargetSelectList visible + AttackPreview visible
  STAFF_TARGET  — TargetSelectList visible (staff mode)
  ITEM_MENU     — ItemMenu visible
  MAP_MENU      — MapMenu visible (pauses cursor)
  LEVEL_UP      — LevelUpScreen visible (cursor locked)
  GAME_OVER     — GameOverScreen visible (cursor locked)
  VICTORY       — VictoryScreen visible (cursor locked)
  LOCKED        — All panels hidden except UnitInfoPanel; cursor locked
```

---

## Visual Feedback Summary

| Event | Visual Feedback |
|---|---|
| Unit selected | Blue movement tiles appear; selection ring on unit |
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
