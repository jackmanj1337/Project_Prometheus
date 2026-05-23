# GDD — Manual Tasks Reference

Tasks here need action inside the Godot editor (or a tool run) — they are not done
by editing `.gd` / `.tres` / `.tscn` / `.md` files directly. Each entry notes what
breaks if it is skipped. Check items off as completed (`- [ ]` → `- [x]`).

> Last verified against the project: 2026-05-23 (Pair Up pass 1 partial — see
> Pair Up Pass 1 Playtest section below for new items).

---

## Pending

### Class / Skill Live Playtest

Run this before treating the class/skill track as fully signed off. Skipping it
leaves the newly-implemented promotion, level-1 class-skill, and Second Seal
flows verified only by headless tests, not by actual in-map play.

- [ ] Start a fresh map with the default roster and confirm each starter unit
      begins with the correct level-1 class skill in live UI/tooltips, not just
      in data/tests
- [ ] Level a base-class unit to level 10 and confirm the class level-10 skill
      is learned in live play with the expected level-up messaging
- [ ] Fill a unit's equipped skill slots, then learn another class skill and
      confirm it is stored in `earned_skills` without being auto-equipped
- [ ] With **Auto Promote** enabled on New Game, level a promotable unit to its
      class cap and confirm the promotion prompt appears automatically after the
      level-up flow finishes
- [ ] With **Auto Promote** disabled, level a promotable unit to its class cap
      and confirm no auto-prompt appears until a promotion item is used
- [ ] Use a `Master Seal` on a valid capped unit and confirm the promotion modal
      opens, the unit changes class, level resets to 1, EXP resets to 0, and
      the item is consumed only after confirm
- [ ] Cancel out of a promotion-item prompt once and confirm the item is **not**
      consumed and control returns cleanly to the action flow
- [ ] Use a class-restricted promotion item (`Orion Bolt`) on both a valid class
      and an invalid class, confirming only the legal unit can use it
- [ ] Use a class-group-restricted promotion item (`Guiding Ring`) on both a
      valid class-group unit and an invalid one, confirming only the legal unit
      can use it
- [ ] Promote at least one unit into each of these multi-option class families
      and confirm the correct class choice appears in the modal:
      Archer, Cavalier, Cleric, Knight, Mage, Mercenary
- [ ] After promotion, confirm newly granted weapon proficiencies appear at `E`
      rank and pre-existing ranks are preserved
- [ ] Level a promoted unit to promoted level 5 and then 15, confirming the
      promoted-class skills are learned at the right levels in live play
- [ ] Use a `Second Seal` on a tier-1 unit below level 10 and confirm it is not
      usable
- [ ] Use a `Second Seal` on a tier-1 unit at level 10 and confirm only that
      character's allowed tier-1 reclass set appears
- [ ] Use a `Second Seal` on a promoted unit below level 10 and confirm the
      options are demotions only, with no lateral tier-2 reclass options shown
- [ ] Use a `Second Seal` on a promoted unit at level 10+ and confirm lateral
      tier-2 options from other class lines appear
- [ ] Reclass into a shared promoted class option (for example a `Bow Knight`
      line-qualified entry) and confirm the chosen class line is respected
- [ ] Pick the current class with a `Second Seal` at max level and confirm the
      unit cleanly resets to level 1 without stat changes
- [ ] After any reclass or demotion, confirm the unit immediately has the new
      class's level-1 skill if applicable
- [ ] Save a retry snapshot after promotion or reclassing, trigger a restore,
      and confirm class, level, promotion state, skills, and weapon ranks come
      back correctly in live play

#### Playtester Comments
Mouse is not able to move camera
include level in map unit info
no way to disengage pair up
turn does not auto end when units are paired
currsor remains on attack target after attacking instead of returning to the attacking unit
paired units are defeated together instead of droping the support unit by itself on the map square


### Pair Up Pass 1 Playtest

Steps 1–4 + 6a + 6b of the Pair Up refactor are merged (see
`AGENT/Docs/pair_up_combat_refactor_answers_2026-05-23.md` for the design
inputs). The headless suite covers registry, snapshot, combat-context, and
bonus-resolver math, plus the ActionMenu visibility / emission contracts —
the items below cover the parts that only show up in live play.

Skip what is **NOT** yet implemented (will surface as missing entries — that
is expected, not a bug):

- Separate action (step 6c)
- Combat-forecast UI for Pair Up bonuses, DS/DG %, support portrait (step 5)
- Dual Strike / Dual Guard mechanics in live combat (step 7)
- AI handling for paired targets (step 8)
- Unit-details / map-HUD Pair Up surfaces (step 9)
- Dual Strike+ / Dual Guard+ `.tres` skills (step 10)
- Charm aura "support inherits lead's tile" helper (step 11)
- Per-turn `pair_up_action_this_turn` flag (deferred until a save system
  exists — Q8 reload-exploit protection)

NewGameScreen toggle:

- [ ] On New Game, confirm the screen shows a **Pair Up** Off/On selector
      between Leveling and Start
- [ ] Default is **On**; closing and reopening the New Game screen restores
      the last-chosen value
- [ ] Selecting **Off** and starting a map suppresses every Pair Up entry in
      the on-map ActionMenu, even when standing next to an unpaired ally

ActionMenu visibility (Pair Up **On**):

- [ ] Select an unpaired unit standing next to (4-cardinal) an unpaired ally
      and confirm the ActionMenu shows **Pair Up** in addition to the usual
      entries
- [ ] Move the same unit so no ally is adjacent and confirm **Pair Up**
      disappears from the menu (menu shrinks to fit)
- [ ] Already-paired adjacent ally hides **Pair Up** (visibility check
      filters by registry, not just adjacency)

Pair Up flow:

- [ ] Picking Pair Up enters targeting; the adjacent ally tile is
      highlighted with the heal overlay color (visual reuse from staff
      targeting is intentional)
- [ ] Cancelling out of targeting returns control to the ActionMenu without
      pairing
- [ ] Confirming on the ally pairs them; the support sprite disappears from
      the map and both units are greyed-out (DONE state)
- [ ] The lead remains on its original tile (Q2: lead-only on map)
- [ ] Trying to select the support unit afterwards: cursor cannot land on
      it (no tile) and it is absent from any cursor / Tab cycle

Swap:

- [ ] On a paired lead, the ActionMenu shows **Swap** (and hides Pair Up)
- [ ] On the paired support — which is now off-map and cannot be selected
      directly — there is nothing to verify; the registry has both ids but
      only the lead is reachable in the UI
- [ ] Picking Swap ends the lead's turn and trades roles in the registry
      (verified by exiting/re-entering combat preview if any other paired
      effect surfaces it — otherwise this is currently invisible until
      step 5 / 9 land UI surfaces for Pair Up state)

Combat math integration (step 4):

- [ ] Pair two units of a known class combination (e.g. Cavalier + Cleric)
      and check the lead's pre-combat preview shows higher effective stats
      than an unpaired comparison unit of the same class — **note**: the
      forecast UI in the existing combat preview is **not yet** Pair Up-
      aware (step 5), so the easiest check is to observe higher damage /
      hit rates against a known enemy
- [ ] If the comparison is ambiguous, swap to a more impactful class pair
      (Cavalier supporting a Hero lead gives `+1 str +1 def +1 spd` flat
      plus scaling — see `data/pair_up/pair_up_bonus_table.tres`)
- [ ] Confirm the support's contribution stops being applied after Wait /
      moving the lead — `clear_combat_modifiers()` runs at end of combat

Retry / snapshot round-trip:

- [ ] Pair two units, take fatal damage on the lead in a combat
- [ ] On the Game Over screen, hit Retry
- [ ] Confirm the pairing is restored: the ActionMenu still shows **Swap**
      on the lead, the support is still off-map
- [ ] Confirm the support is **not** rendered on its old tile after restore
      (snapshot captures `tile_position = (-1, -1)` for the support; if it
      reappears at its pre-pair tile, the snapshot was bypassed)

### M15 Part A — Hotseat Validation Playtest

Run this after the hotseat validation map and the first map selector build land.
Skipping it leaves the remaining M15 Part A acceptance criteria unverified and
makes future multi-map regression testing slower and more error-prone.

Reference plan: `AGENT/Docs/hotseat_test_map_plan_2026-05-21.md`

- [ ] Launch the hotseat validation map from the **map selector**, not by editing
      `GameMap.tscn` or changing `GameMap.map_data_path`
- [ ] Confirm blue phase still behaves normally: cursor starts on blue, blue units
      are selectable, and green units are not selectable during blue's turn
- [ ] Leave at least one blue unit unacted and press End Turn once; confirm the
      "some units have not acted" prompt appears, Cancel returns control, and
      Confirm advances the turn
- [ ] Confirm the green hotseat phase starts with an unlocked cursor and only green
      units are selectable
- [ ] Use a green combat unit to attack a **red** unit
- [ ] Use a green combat unit to attack a **yellow** unit, confirming both hostile
      factions are valid green targets
- [ ] Use the green staff unit to heal a valid ally in range, ideally once on a
      green ally and once on a blue ally, confirming same-alliance targeting
- [ ] End a green phase manually with End Turn and confirm control passes to red
- [ ] On a later green phase, act with every green unit and confirm the phase can
      auto-end cleanly when all green units are done
- [ ] Watch the red AI phase complete after green without hanging or skipping units
- [ ] Watch the yellow AI phase complete after red without hanging or skipping units
- [ ] Confirm the camera/control handoff back to blue feels normal when blue's
      phase resumes
- [ ] End the map by defeating the final hostile during a green hotseat action and
      confirm the map resolves immediately without waiting for End Turn
- [ ] Use the map selector to launch an all-non-blue-AI comparison map
      (`map_001_c3_factions`) and confirm it still behaves like the pre-hotseat
      faction-system build

---

## Completed

### ✅ Audio Bus Setup — Done

`default_bus_layout.tres` defines **Master** (bus 0, implicit), **Music** (bus 1),
and **SFX** (bus 2) — Music and SFX both route **Send → Master**.
`SettingsManager._apply_audio()` looks buses up by name, so the Music and SFX
volume sliders now drive real buses. (Godot auto-loads the default-named bus
layout; no `[audio]` entry in `project.godot` is needed.)

### ✅ Settings menu — Done (M5; rebuilt in Session M)

`scenes/ui/SettingsScreen.tscn` exists and is wired into `MainMenu`, `MapMenu`,
and `GameMap` (in-game via the map menu's Settings button or the `open_settings`
key). Kept here as a structural reference; the **authoritative** layout is the
`SettingsScreen.gd` header comment + the scene itself. Current structure:

```
SettingsScreen  (Control, full-rect)
  Dimmer        (ColorRect, full-rect, opaque — modal backdrop)
  Panel         (PanelContainer)
    ScrollContainer
      VBox
        Label "Settings"
        HBoxMaster / HBoxMusic / HBoxSFX  (Label + HSlider + Label)
        HSeparator
        OptCombatAnim                      (hidden — no system uses it yet)
        HBoxMovementSpeed / HBoxPhaseBanner / HBoxLevelUp / HBoxMouseTargeting
          (each: title Label + OptionButton)
        HSeparator
        LabelControls "Controls"
        KeybindList   (VBoxContainer — read-only rows built at runtime)
        HSeparator
        BtnBack       (Button)
```

There is **no** Permadeath or Leveling Method control on this screen — those are
per-save rules set on the New Game screen (`NewGameScreen.tscn`).

### ✅ Register `ConditionManager` autoload — Done 2026-05-13

`ConditionManager` is registered in `project.godot` after `DataManager`. Done via
direct file edit (no editor action needed).

### ✅ Input Map — Done

All actions are defined in `project.godot [input]`:

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

### ✅ Project Display & Rendering Settings — Done

`project.godot` sets viewport `1280×720`, stretch mode `canvas_items`, aspect
`keep`, and `Rendering/2D` pixel-snap (Snap 2D Vertices To Pixel).

### ✅ Tilesets — Done (generated by tool, not hand-built)

`assets/terrain_tileset.tres` and `assets/overlay_tileset.tres` exist. They are
**generated programmatically** by `scripts/tools/generate_tilesets.gd` — the tool
also creates the `terrain_type` custom data layer and assigns each tile's value, so
this is not actually a manual editor task. Re-run the tool after terrain/tile-art
changes:

```
godot --headless --path . --script res://scripts/tools/generate_tilesets.gd
```

`terrain_type` values: `plain`, `forest`, `mountain`, `fort`, `sea`, `desert`,
`wall`. Overlay tiles (blue=movement, red=attack, green=heal, dark-red=danger) are
identified by atlas position — no custom data.

### ✅ M5 UI scene wiring — Done

All MVP UI scenes (`HUD`, `ActionMenu`, `ItemMenu`, `AttackPreview`, `PhaseBanner`,
`LevelUpScreen`, `MapMenu`, `SettingsScreen`, `GameOverScreen`, `MainMenu`,
`NewGameScreen`) are built and wired. Signal connections are made in code
(`get_node_or_null` + `.connect()`), not via the editor's Node→Signals panel.

---

## Upcoming (not yet needed — listed for future reference)

### Sprite / Asset Import Settings

When real art assets arrive, each imported sprite needs **Import → Preset:
`2D Pixel`** (disables filtering/mipmaps for pixel art). Verify in the **Import**
panel after dropping files into `assets/sprites/`. Placeholder art is currently
generated by `scripts/tools/generate_placeholder_assets.gd`.

### M12 — Laguz Shift Gauge UI

A `ShiftGaugePanel` scene built in the editor as a `CanvasLayer` child of `HUD.tscn`.
A placeholder `ProgressBar` is acceptable for the M12 MVP. Full visual is marked
`[PLACEHOLDER]` in `GDD_10_Roadmap.md` (Milestone 12).

---

## How to Update This Document

Add a new entry whenever a task arises that:
- Requires clicking through Godot Project Settings, the editor UI, or the Import panel
- Cannot be completed by editing `.gd`, `.tres`, `.tscn`, or `.md` files directly
- Would be forgotten or unclear to a fresh contributor

Mark completed entries with `✅` / `[x]` and add a date note if helpful. When a task
turns out to be tool-scriptable rather than editor-only, note the tool command.
