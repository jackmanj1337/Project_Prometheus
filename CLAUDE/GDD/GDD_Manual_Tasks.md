# GDD — Manual Tasks Reference

Tasks in this document **cannot be done by editing files directly** — they require
action inside the Godot editor or another tool. Each entry includes step-by-step
instructions and notes on what breaks if the task is skipped.

Check items off as they are completed (`- [ ]` → `- [x]`).

---

## ✅ Settings menu — Completed (M5)

`scenes/ui/SettingsScreen.tscn` exists and is wired into both `MainMenu` and
`MapMenu`; the Settings menu is reachable in-game. Kept here as a structural
reference. The **authoritative** node layout is the header comment in
`scripts/ui/SettingsScreen.gd` — node names must match exactly (`@onready` paths):

```
SettingsScreen  (Control, full-rect anchor)
  Panel
    VBox
      Label "Settings"
      HBoxMaster / HBoxMusic / HBoxSFX  (each: Label + HSlider + Label;
        node names SliderMaster/Music/SFX, LabelMaster/Music/SFX)
      HSeparator
      OptCombatAnim     (OptionButton)  # hidden at runtime — no system uses it yet
      OptMovementSpeed  (OptionButton)  # Normal / Fast / Instant
      OptPhaseBanner    (OptionButton)  # Show / Skip
      OptLevelUpScreen  (OptionButton)  # Show / Auto / Skip
      OptMouseTargeting (OptionButton)  # Snap to Target / Keyboard Only
      HSeparator
      BtnBack           (Button)
```

There is **no** Permadeath or Leveling Method control on this screen — those are
per-save rules set on the New Game screen (`NewGameScreen.tscn`).

---

## Completed Manual Tasks

### ✅ Register `ConditionManager` as an Autoload — Done 2026-05-13

`ConditionManager` is registered in `project.godot` after `DataManager` in the autoload
order. This was done via direct file edit (no editor action needed).

---

## One-Time Setup (M0 — already done, listed for reference)

These were completed during initial project setup. Re-do only if the project is
reset or the settings are lost.

### Audio Bus Setup

1. Open the **Audio** panel at the bottom of the Godot editor.
2. Confirm three buses exist in this order: **Master** (index 0), **Music** (index 1), **SFX** (index 2).
3. Music and SFX buses must have their **Send** set to `Master`.
4. If missing: click **Add Bus**, rename it, set Send, repeat.

### Input Map

Go to **Project → Project Settings → Input Map** and confirm all actions exist:

| Action | Keys |
|---|---|
| `cursor_up` | W, Up Arrow |
| `cursor_down` | S, Down Arrow |
| `cursor_left` | A, Left Arrow |
| `cursor_right` | D, Right Arrow |
| `confirm` | Z, Enter, Space, Left Mouse Button |
| `cancel` | X, Escape, Right Mouse Button |
| `next_unit` | Tab |
| `prev_unit` | Shift + Tab |
| `show_danger_zone` | Q, Middle Mouse Button |
| `open_menu` | M |
| `open_settings` | O |

### Project Display Settings

Go to **Project → Project Settings → Display → Window**:

| Setting | Value |
|---|---|
| Size / Viewport Width | 1280 |
| Size / Viewport Height | 720 |
| Stretch / Mode | `canvas_items` |
| Stretch / Aspect | `keep` |

Go to **Project → Project Settings → Rendering → 2D**:
- Enable **Snap / Snap 2D Vertices To Pixel**.

---

## Milestone 2 — TileSet / TileMap (already done, listed for reference)

These tasks require the Godot TileSet editor and cannot be scripted.

### Terrain TileSet

- The shared TileSet is saved at `assets/terrain_tileset.tres`.
- It must have a **Custom Data Layer** named `terrain_type` (type: String).
- Each tile must have its `terrain_type` value set:
  `plain`, `forest`, `mountain`, `fort`, `sea`, `desert`, `wall`.
- To add or edit: open the TileSet resource, go to **Custom Data Layers**, confirm
  the layer exists, then select each tile and set its value in the **Custom Data** panel.

### Overlay TileSet

- Saved at `assets/overlay_tileset.tres`.
- Four tiles: blue (movement), red (attack), green (heal), dark-red (danger zone).
- No custom data needed — tiles are identified by atlas position.

---

## Upcoming Manual Tasks (not yet needed — listed for future reference)

### M5 — Scene Node Wiring

When building UI scenes, several nodes must be connected to signals via the editor's
**Node → Signals** panel rather than code. These are noted with `[PLACEHOLDER]` in the
scene design. No action needed until M5 work begins.

### Sprite / Asset Import Settings

When real art assets arrive, each imported sprite will need:
- **Import → Preset:** `2D Pixel` (disables filtering/mipmaps for pixel art)
- Verify in **Import** panel after dropping files into `assets/sprites/`

### M12 — Laguz Shift Gauge UI

A `ShiftGaugePanel` scene needs to be built in the editor as a `CanvasLayer` child
of `HUD.tscn`. A placeholder `ProgressBar` is acceptable for M12 MVP.
Full visual is marked `[PLACEHOLDER]` in `GDD_10_Roadmap.md` (Milestone 12).

---

## How to Update This Document

Add a new entry whenever a task arises that:
- Requires clicking through Godot Project Settings, the editor UI, or the Import panel
- Cannot be completed by editing `.gd`, `.tres`, `.tscn`, or `.md` files directly
- Would be forgotten or unclear to a fresh contributor

Mark completed entries with `[x]` and add a date note if helpful.
