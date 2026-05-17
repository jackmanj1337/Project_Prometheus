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
| `show_danger_zone` | Q (hold) | Middle Click (hold) |
| `open_menu` | M; also confirm/cancel on an empty tile | Left/Right Click on an empty tile |

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
│  Attack    │  ← greyed if no enemies in range
│  Staff     │  ← greyed if no staff equipped / no targets
│  Item      │  ← greyed if inventory empty
│  Trade     │  ← greyed if no adjacent ally
│  Wait      │
└────────────┘
```

**Behavior:**
- Menu appears adjacent to the unit's new tile; repositioned if too close to screen edge
- Navigate with `cursor_up` / `cursor_down`; confirm with `confirm`; close with `cancel`
- Closing with cancel triggers undo: unit returns to its pre-move tile

**Button widths:** 120 px; height per button: 30 px
**Font size:** 18px

---

### Target Select List

**Scene:** `TargetSelectList.tscn`
**Trigger:** Player selects "Attack" or "Staff" from Action Menu

**Layout (positioned near cursor; repositioned if near edge):**
```
┌──────────────────────────┐
│ ► Garet  (Knight)  HP 21 │  ← highlighted entry
│   Archer             HP 14│
└──────────────────────────┘
```

**Behavior:**
- Lists all valid targets (enemies for Attack, allies for Staff)
- Navigate with `cursor_up` / `cursor_down`
- As each target is highlighted, cursor snaps to that target's tile on the map
- Attack preview updates in real time as selection changes
- Confirm: opens full AttackPreview panel
- Cancel: returns to Action Menu

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

### Staff Use Panel

**Scene:** Reuse `TargetSelectList.tscn` with "Staff" mode.
**Trigger:** Player selects "Staff" from Action Menu

- Lists all allies within staff range who are below max HP
- Shows each ally's name, current HP, and max HP
- Selecting one shows a preview: "Heal: +17 HP" (or whatever 10+MAG equals)
- Confirm uses the staff, heals the target, ends the unit's turn

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
│   Quit to Menu   │
└──────────────────┘
```

**Behavior:**
- `End Turn`: calls `TurnManager.end_player_phase()` after confirmation prompt
  "End turn? Some units have not acted. [Yes / No]"
- `Settings`: opens the Settings screen (see below); map is paused while open
- `Quit to Menu`: returns to Main Menu (with confirmation prompt)
- Cancel closes the map menu

---

### Settings Screen

**Scene:** `SettingsScreen.tscn`
**Trigger:** "Settings" button in Main Menu or Map Menu
**Script:** `scripts/ui/SettingsScreen.gd`

The Settings screen is a full-screen panel with a tab bar across the top.
Three tabs: **Audio**, **Controls**, **Gameplay**.
Changes take effect immediately and are saved automatically on close via
`SettingsManager.save()`. Cancel or pressing `cancel` discards unsaved changes
and restores previous values.

All settings persist between sessions using `user://settings.cfg`
(Godot's `ConfigFile`). See `GDD_01` for `SettingsManager` details.

---

#### Layout

```
┌──────────────────────────────────────────────────┐
│  [ Audio ]   [ Controls ]   [ Gameplay ]         │  ← tab bar
├──────────────────────────────────────────────────┤
│                                                  │
│  (tab content — see each tab below)              │
│                                                  │
│                                                  │
│                                                  │
│                                                  │
│       [ Reset to Defaults ]   [ Close ]          │
└──────────────────────────────────────────────────┘
```

- "Reset to Defaults" resets only the **currently active tab** to defaults,
  with a confirmation prompt: "Reset [Audio / Controls / Gameplay] to defaults?"
- "Close" saves all changes and returns to the previous screen
- Pressing `cancel` closes the screen (same as "Close")

---

#### Tab 1 — Audio

```
  Master Volume    [━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]  80%
  Music Volume     [━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]  70%
  SFX Volume       [━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]  90%
```

- Each slider is a Godot `HSlider`, range 0–100, step 1
- Numeric value shown to the right of each slider (e.g. "80%")
- Sliders update audio bus volumes in real time as they are dragged
- Three Godot Audio Buses must be configured: `Master`, `Music`, `SFX`
  - Background music plays through the `Music` bus
  - All other sounds play through the `SFX` bus
  - Both are children of the `Master` bus in the Audio panel

| Setting Key | Default | Range |
|---|---|---|
| `audio/master_volume` | 80 | 0–100 |
| `audio/music_volume` | 70 | 0–100 |
| `audio/sfx_volume` | 90 | 0–100 |

---

#### Tab 2 — Controls

Displays a list of all remappable actions. The player can click any row to
reassign it.

```
  cursor_up          W / Up Arrow          [ Rebind ]
  cursor_down        S / Down Arrow        [ Rebind ]
  cursor_left        A / Left Arrow        [ Rebind ]
  cursor_right       D / Right Arrow       [ Rebind ]
  confirm            Z / Enter / Space     [ Rebind ]
  cancel             X / Escape            [ Rebind ]
  next_unit          Tab                   [ Rebind ]
  prev_unit          Shift + Tab           [ Rebind ]
  show_danger_zone   Q                     [ Rebind ]
  open_menu          Escape                [ Rebind ]
```

**Rebind Flow:**
1. Player clicks `[ Rebind ]` on a row
2. That row highlights and shows: `"Press any key..."`
3. The next key or mouse button pressed is captured
4. If the key is already bound to a **different** action, show a warning:
   `"[Key] is already used for [action]. Replace it?"  [ Yes ] [ No ]`
   - Yes: removes the old binding and assigns to this action
   - No: cancels and returns to waiting
5. If player presses `Escape` during rebind: cancel without changing the binding
6. Mouse buttons (Left, Right, Middle) are valid rebind targets
7. The new binding is saved immediately to `SettingsManager`

**Implementation notes:**
- Use `InputEventKey` and `InputEventMouseButton` to capture events
- After rebinding, call `InputMap.action_erase_events(action)` then
  `InputMap.action_add_event(action, event)` to apply immediately
- `SettingsManager.save()` writes the new bindings to `user://settings.cfg`
- `SettingsManager.load()` reads and re-applies bindings on game start

**Non-remappable inputs:** Mouse hover (always moves cursor) and mouse clicks
(always confirm/cancel) cannot be rebound. Their behavior is hardcoded.

---

#### Tab 3 — Gameplay

```
  Combat Animations     [ All Units ▾ ]
  Movement Speed        [ Normal ▾ ]
  Phase Banner          [ Show ▾ ]
  Level Up Screen       [ Show ▾ ]
  Permadeath            [ Off ▾ ]
  Leveling Method       [ Growth Rates ▾ ]
```

Each setting uses an `OptionButton` (dropdown). Options and behavior below.

---

**Combat Animations**
Controls whether hit/miss/crit visual effects play during combat resolution.

| Option | Behavior |
|---|---|
| All Units | Animations play for every unit (default) |
| Player Units Only | Full animations for player units; enemy hits are instant |
| Enemy Units Only | Full animations for enemies; player hits are instant |
| None | All combat effects are instant; HP bars update immediately |

Setting key: `gameplay/combat_animations`  Default: `"all"`

When "instant" mode is active for a given exchange, `CombatResolver.apply_combat_result()`
skips the `await get_tree().create_timer(0.25)` pause between hits and plays no
flash animation. HP bars still update visually.

---

**Movement Speed**
Controls how fast unit sprites move across tiles when travelling their path.

| Option | Behavior |
|---|---|
| Normal | 0.12 seconds per tile (default) |
| Fast | 0.06 seconds per tile |
| Instant | Units snap to their destination immediately (no tween) |

Setting key: `gameplay/movement_speed`  Default: `"normal"`

`Unit.move_along_path()` reads this setting to set tween duration.
At "Instant", the tween is skipped entirely and `snap_to_tile()` is called directly.
The `unit_moved` signal is still emitted after the snap.

---

**Phase Banner**
Controls whether the "PLAYER PHASE" / "ENEMY PHASE" banner animation plays.

| Option | Behavior |
|---|---|
| Show | Full slide-in / hold / slide-out animation (default) |
| Skip | Banner does not appear; phase change is still announced via the Phase Label in the HUD |

Setting key: `gameplay/phase_banner`  Default: `"show"`

When skipped, `TurnManager` still updates the Phase Label in the HUD and calls
`cursor.unlock()` immediately rather than waiting for the animation.

---

**Level Up Screen**
Controls whether the level-up stat screen pauses for player input.

| Option | Behavior |
|---|---|
| Show | Screen appears; player presses confirm to dismiss (default) |
| Auto-dismiss | Screen appears briefly (1.5 seconds) then dismisses itself |
| Skip | Level-up screen does not appear; a small pop-up text shows briefly (e.g. "+Level!") |

Setting key: `gameplay/level_up_screen`  Default: `"show"`

---

**Permadeath**
Mirrors `GameState.permadeath_enabled`. Also accessible here for convenience.

| Option | Behavior |
|---|---|
| Off | Dead units are absent this map only; return next map (default) |
| On | Dead units are flagged incapacitated; cannot be deployed again |

Setting key: `gameplay/permadeath`  Default: `"off"`

> Note: Changing this mid-campaign takes effect from the next map onward.
> A warning is shown: "Changing permadeath setting takes effect on the next map."

---

**Leveling Method**
Mirrors the campaign leveling method. Changes take effect on the next level-up.

| Option | Behavior |
|---|---|
| Growth Rates | Each stat has a % chance to increase per level (default) |
| Point Buy | Player assigns a pool of points each level |
| Coin Flip | Each stat: 50% chance of +1 |
| Dice Roll | Roll d6 and spend result as points |

Setting key: `gameplay/leveling_method`  Default: `"growth_rates"`

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

**Layout (full-screen overlay):**
```
[light overlay fades in]

        VICTORY!

   Rewards:
   Gold: +500
   [Item name if any]

   [ Continue ]          [PLACEHOLDER — next map or campaign screen]
```

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
