# GDD — Manual Tasks Reference

Tasks here need action inside the Godot editor (or a tool run) — they are not done
by editing `.gd` / `.tres` / `.tscn` / `.md` files directly. Each entry notes what
breaks if it is skipped. Check items off as completed (`- [ ]` → `- [x]`).

> Last verified against the project docs: 2026-05-24. Broad regression sweep +
> detailed class/Pair Up/More Info/hotseat passes are pending below.

---

## Pending

### Post-2026-05-19 Regression Sweep

Run this as the first broad live regression pass before drilling into the
deeper feature-specific sections below. It covers every player-facing feature
cluster added after the 2026-05-19 playtest wave: map selector / launch-state,
objective + faction UI, hotseat, class-skill progression, Pair Up pass 1,
camera/debug controls, and More Info surfaces.

Use these maps for coverage:
- `Map 001` — baseline combat/UI/Pair Up/More Info checks
- `Map 900 - Hotseat Validation` — hotseat + selector launch-state checks
- `Map 950 - Promotion Validation` — promotion / reclass / class-skill checks

Launch / selector / roster state:

- [ ] Open New Game and confirm the map selector lists at least the baseline
      map, the faction-demo map, the hotseat validation map, and the promotion
      validation map, with no blank/duplicate entries
- [ ] Launch `Map 001` from the selector and confirm it starts normally without
      requiring a scene edit or manual `GameMap.map_data_path` change
- [ ] Launch `Map 900 - Hotseat Validation` from the selector and confirm the
      authored fixed test roster loads instead of the default campaign roster
- [ ] Return to New Game, switch back to a default-roster map, start again, and
      confirm the fixed test roster from map 900 does **not** leak into the new
      run
- [ ] Launch `Map 950 - Promotion Validation` from the selector and confirm the
      authored promotion/reclass test roster loads successfully
- [ ] Change the Pair Up toggle and Auto Promote toggle in New Game, back out,
      reopen New Game, and confirm the last-selected values persist in the UI

Faction / objective / phase UI:

- [ ] Start a normal blue-player map and confirm the HUD phase label shows the
      authored faction label (not a stale hardcoded `PLAYER PHASE` string where
      faction data should drive it)
- [ ] Confirm the HUD objective panel appears on maps with authored conditions
      and lists the current side's win/lose conditions in readable text
- [ ] On a map with a non-blue hostile phase, confirm the phase/banner labels
      use the authored faction display names rather than collapsing everything
      to `ENEMY`
- [ ] On a seize-capable map, move the correct unit onto the seize tile and
      confirm the ActionMenu offers `Seize`; use it and confirm the map resolves
      immediately when that objective should win the map
- [ ] On a map with an authored escape unit/tile case (if available in the
      current roster/maps), confirm the correct unit gets `Escape` only on the
      proper tile and the action resolves cleanly

Hotseat / multi-faction control:

- [ ] Launch `Map 900 - Hotseat Validation` and confirm blue starts under manual
      control while green/red/yellow do not become selectable during blue's
      phase
- [ ] End blue's phase and confirm control passes to green with an unlocked
      cursor and green-only selection
- [ ] During green's hotseat phase, attack a red unit and a yellow unit in
      separate checks and confirm both count as hostile targets
- [ ] During green's hotseat phase, heal a same-alliance target and confirm
      allied non-green units are valid for staff targeting when the alliance
      rules allow it
- [ ] End a hotseat-controlled phase manually and confirm control passes to the
      next faction without hanging, soft-locking, or leaving the prior faction
      selectable
- [ ] On a later hotseat phase, act with every locally controlled unit and
      confirm the phase auto-ends when all those units are done
- [ ] Let red and yellow AI phases run to completion and confirm they act in
      order and hand control back to blue cleanly afterward

Camera / cursor / control regressions:

- [ ] Move the mouse to the screen edge and confirm the camera nudges/pans in a
      bounded way instead of freezing or running away
- [ ] Disable mouse cursor control in Settings, move the mouse, and confirm the
      cursor no longer drifts from mouse motion
- [ ] End the player phase after manually panning to a custom view, let the
      enemy phase run, then return to player phase and confirm the camera
      restores to the player's saved end-turn view
- [ ] Attack an enemy, resolve combat, and confirm the cursor focus returns to
      the acting unit instead of remaining stranded on the target
- [ ] Open the map HUD unit panel on several units and confirm the displayed
      level is visible in live UI

Debug / testing aids:

- [ ] Press `F10` during a safe debug playtest and confirm force-level-up still
      works on the intended unit/event path
- [ ] Press `F11` during a safe debug playtest and confirm the growth-boost aid
      toggles, the HUD debug banner updates, and the label clearly shows the
      `growth+300` state
- [ ] With debug aids inactive, confirm the HUD does **not** falsely show a
      stale growth/debug state from a previous toggle

Class / skill / progression surfaces:

- [ ] Start a fresh default-roster map and confirm each starter unit already has
      its level-1 class skill without needing to level first
- [ ] On level-up, confirm any newly learned class skill is announced in the
      level-up UI rather than being granted silently
- [ ] Open the unit details surface on a few units and confirm weapon-rank/WEXP
      information appears correctly, with unavailable tracks dimmed rather than
      omitted confusingly
- [ ] Promote a valid capped unit and confirm displayed level resets to `1`,
      class changes correctly, and the promoted class's level-1/5/15 progression
      behaves as expected when leveling continues
- [ ] Reclass or demote with a `Second Seal` and confirm the unit's displayed
      level, internal progression behavior, class line, and immediate level-1
      class-skill grant all behave correctly in live play
- [ ] After promotion or reclass, trigger a retry/snapshot restore and confirm
      the changed class state survives the round-trip

Pair Up pass 1:

- [ ] On New Game with Pair Up `Off`, start a map and confirm no Pair Up entry
      appears in the ActionMenu and a rejected pair attempt cannot burn an
      action indirectly
- [ ] On New Game with Pair Up `On`, pair two units and confirm the support goes
      off-map, the lead stays on-map, and both units end in the expected DONE
      state
- [ ] Use `Swap` on a paired lead and confirm the turn ends and the pairing
      remains valid afterward
- [ ] Use `Separate` on a paired lead, choose a legal adjacent tile, and confirm
      the support is restored there, the pairing clears, and both turns end
- [ ] Kill a paired lead during the player phase and confirm the support drops
      onto the lead's tile and is immediately expended for the round
- [ ] Kill a paired lead during an enemy phase and confirm the support drops
      back onto the map and is available again on the next round start
- [ ] Pair two units with a known stat-bonus combination and confirm the lead's
      live combat numbers improve versus the unpaired baseline

More Info / inspection mode:

- [ ] Run the new More Info surfaces on `Map 001` and confirm all three hosts
      are reachable: character sheet, combat preview, and terrain HUD
- [ ] Confirm the character sheet shows effective stat values plus the base /
      modifier / total breakdown without visual corruption
- [ ] Confirm the combat preview now shows crit, weapon triangle, and
      effectiveness markers in live play
- [ ] Confirm the terrain HUD expands with `F`, shows terrain descriptions for
      live terrain ids, and never falls back to placeholder text on common
      tiles
- [ ] Specifically stress preview positioning near screen edges and confirm the
      panel stays readable and on-screen

Recommended follow-through:

- [ ] After completing this broad regression sweep, continue with the detailed
      sections below:
      `Class / Skill Live Playtest`, `Pair Up Pass 1 Playtest`,
      `More Info Phase 1 Live Playtest`, and `M15 Part A — Hotseat Validation Playtest`

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
can't get the debug stat growth boost label to show up (try binding to f11)
lets change the stat boost to +300 to each stat.
when pair up is disabled, it still shows up in the action menu and you can still click it and try to select someone and confirm and it burns an action, but doesn't actually pair anyone up.
cavalier has wrong movement
eventually, you should be able to use the more info button on a stat and see the base and what modifiers are currently changing it and by how much.

#### Current Action Items
- [x] Make mouse-driven cursor movement pan the camera in a controlled way instead of freezing camera follow
- [x] Include the unit's displayed level in the map HUD unit-info panel
- [x] Implement the Pair Up **Separate** action for paired leads
- [x] Confirm Pair Up actions still trigger auto-end when they expend the last locally-controlled units
- [x] Return the cursor focus to the acting unit after combat resolves
- [x] On lead-unit death, drop the paired support onto the lead's tile
- [x] If the lead dies during the player phase, mark the dropped support unit expended for that round
- [x] If the lead dies during an enemy phase, restore the support on-map and have it ready again at the next round start
- [x] Make the debug growth-boost state obvious in the HUD / debug banner and verify the hotkey path works in live play
- [x] Raise the temporary debug growth boost from `+50` to `+300` per stat
- [x] Hide / hard-gate Pair Up creation when the campaign setting disables Pair Up so a rejected attempt never burns an action
- [x] Correct Cavalier movement to the intended value
- [x] Expand the **More info** stat-inspection milestone so each stat can show its base value plus every active modifier and delta
- [x] Move the **More info** stat-inspection milestone up the priority queue because it is useful for playtest verification and debugging


### Pair Up Pass 1 Playtest

Steps 1–4 + 6a + 6b of the Pair Up refactor are merged (see
`AGENT/Docs/pair_up_combat_refactor_answers_2026-05-23.md` for the design
inputs). The headless suite covers registry, snapshot, combat-context, and
bonus-resolver math, plus the ActionMenu visibility / emission contracts —
the items below cover the parts that only show up in live play.

Skip what is **NOT** yet implemented (will surface as missing entries — that
is expected, not a bug):

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

Separate:

- [ ] On a paired lead, the ActionMenu shows **Separate** when at least one
      adjacent legal drop tile exists for the support
- [ ] Picking Separate enters targeting and highlights the legal adjacent drop
      tiles
- [ ] Confirming a drop tile restores the support on that tile, makes the
      support sprite visible again, clears the pairing, and ends both units'
      turns

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

### More Info Phase 1 Live Playtest

Run this before treating the new More Info surfaces as signed off. The headless
tests cover the data contracts, selector cycling, terrain expansion, and the
camera-pan helper, but live play is still needed for viewport/layout behaviour,
input-priority feel, and copy quality.

General binding / priority:

- [ ] Press `F` on the open map with no combat preview or character sheet open
      and confirm the terrain HUD toggles between compact and expanded mode
- [ ] With the character sheet open, press `F` and confirm the character-sheet
      More Info selector advances instead of the terrain HUD expanding
- [ ] With the combat preview visible, press `F` and confirm the combat-preview
      More Info selector advances instead of the character sheet or terrain HUD
- [ ] With the combat preview visible **and** the character sheet still open in
      the background, press `F` and confirm the preview keeps priority every
      time until it closes
- [ ] After closing the combat preview, press `F` again and confirm priority
      falls back to the character sheet if it is still open
- [ ] After closing all higher-priority surfaces, press `F` again and confirm
      control falls back to the terrain HUD

Character sheet — opening / selection:

- [ ] Open the character sheet from the map and confirm the side panel starts in
      its hint state (no stale description carried over from a previous open)
- [ ] Click each stat row once (`HP`, `Str`, `Mag`, `Skl`, `Spd`, `Def`,
      `Res`, `Lck`, `Mov`) and confirm the side panel title matches the clicked
      row and the description matches that stat rather than a generic fallback
- [ ] Click at least one inventory entry, one skill, and one weapon-rank row
      and confirm each opens the side panel with the expected category text
- [ ] Press `F` repeatedly on the character sheet and confirm the selector
      advances in a stable, readable order and wraps back to the first entry
      after the last one
- [ ] Close the character sheet and reopen it, then press `F` once and confirm
      the selector restarts from the first entry rather than resuming an old
      index

Character sheet — stat breakdown correctness:

- [ ] On a unit with no active stat modifiers, open a stat and confirm the
      breakdown shows the base/effective values plus a clear "no modifiers"
      state rather than blank space
- [ ] On a unit with a positive temporary modifier active, open the affected
      stat and confirm the modifier list names the source, shows a positive
      signed delta, and shows duration text
- [ ] On a unit with a negative temporary modifier active (if available in the
      current build), confirm the affected stat shows a negative signed delta
      and the final effective value reflects it
- [ ] On a stat unaffected by the active modifier, confirm that modifier does
      **not** appear in the breakdown for unrelated stats
- [ ] If multiple modifiers affect the same stat, confirm every contributing
      source is shown clearly enough to explain the final number during
      debugging/playtest

Combat preview — opening / content:

- [ ] Enter attack targeting against an enemy who can counter and confirm the
      preview shows both attacker and defender columns with Name, HP, Damage,
      Hit, Crit, triangle marker, and effectiveness marker rows present in the
      expected places
- [ ] Target an enemy who **cannot** counter and confirm the defender damage row
      reads `No counter`, the preview stays stable, and no blank-row layout bug
      appears
- [ ] Target a matchup with weapon-triangle advantage and confirm the correct
      side shows `▲ Advantage` in green
- [ ] Target a matchup with weapon-triangle disadvantage and confirm the correct
      side shows `▼ Disadvantage` in red
- [ ] Target a neutral matchup and confirm no misleading triangle marker is
      shown on the surface, while `F` can still cycle to the triangle entry and
      explain the mechanic
- [ ] Target an effectiveness matchup and confirm the correct side shows
      `Effective ×N` with the expected multiplier
- [ ] Target a non-effective matchup and confirm no misleading effectiveness
      marker is shown on the surface, while `F` can still cycle to the
      effectiveness entry and explain the mechanic
- [ ] Target a defender with `Vantage` and confirm the defender name row shows
      the `Vantage` annotation without breaking the rest of the line layout

Combat preview — selector behaviour:

- [ ] Click each visible combat-preview row at least once and confirm the side
      panel title/description always match the clicked field
- [ ] Press `F` repeatedly while the preview is visible and confirm the selector
      visits every row in a stable order, including neutral triangle /
      non-effective entries that are only reachable by cycling
- [ ] Close the preview, reopen it on another target, press `F` once, and
      confirm the selector restarts from the first entry instead of preserving
      the previous target's selection

Combat preview — positioning / camera edge cases:

- [ ] Target an enemy near the center of the screen and confirm the preview
      appears adjacent to the defender rather than in the old fixed corner
- [ ] Target an enemy near the right edge and confirm the preview either fits on
      the right, flips to the left, or pans the camera just enough to keep the
      full panel visible without clipping
- [ ] Target an enemy near the left edge and confirm the preview still remains
      fully visible on-screen
- [ ] Target an enemy near the top edge and confirm the preview does not clip
      above the viewport
- [ ] Target an enemy near the bottom edge and confirm the preview does not clip
      below the viewport
- [ ] On a narrow-looking setup where the panel is wide (for example a target
      with the side panel open), confirm camera pan still keeps both the
      preview and battlefield readable instead of overshooting or hiding the
      defender awkwardly
- [ ] Cancel out of preview after any camera pan and confirm control returns
      cleanly to targeting with no stuck camera/input state

Terrain HUD — compact / expanded content:

- [ ] On the open map, move the cursor across at least `plain`, `forest`,
      `mountain`, `fort`, `sea`, `desert`, and `wall` tiles; press `F` on each
      and confirm expanded mode shows a terrain description instead of the
      placeholder text
- [ ] In compact mode, confirm only the compact terrain rows are visible and
      the hint label invites `F` for more info
- [ ] In expanded mode, confirm the description row, move-cost row, and
      actions row appear in a readable layout and the compact-mode hint hides
- [ ] Collapse back to compact mode and confirm all expanded-only rows hide
      again immediately
- [ ] On `wall`, confirm move costs render as `—` rather than `999`
- [ ] On `desert`, confirm the move-cost row reflects the intended special-case
      behaviour (mounted/armoured worse than foot, light units easier if shown)

Terrain HUD — unit-sensitive behaviour:

- [ ] With no unit selected, expand the terrain HUD and confirm the actions row
      hides entirely instead of showing an empty header
- [ ] Select a unit, move the cursor over a normal tile with no location action,
      and confirm the actions row stays hidden
- [ ] Select a unit and move the cursor over a tile that should support a
      location-specific action for that unit (for example `Seize` or `Escape`);
      confirm the actions row appears and lists the expected action label
- [ ] Move the cursor from a tile with actions to one without while expanded and
      confirm the actions row disappears immediately rather than leaving stale
      text behind
- [ ] Deselect the unit while the terrain HUD is expanded and confirm the
      actions row hides immediately

Cross-surface cleanup / stale-state checks:

- [ ] Open each More Info surface, make a selection, close it, then reopen it
      later and confirm it starts from the default hint/first-step state rather
      than showing stale text from the prior visit
- [ ] While moving the cursor rapidly between tiles, confirm the terrain HUD
      never shows stale terrain name, stale move costs, or stale actions from a
      previous tile
- [ ] After attacking, cancelling targeting, or closing the character sheet,
      confirm there is no leftover More Info panel still visible on the map

Copy / UX sanity:

- [ ] While using all three surfaces, note any descriptions that are technically
      correct but unclear, misleading, or too generic for playtest/debugging
- [ ] Specifically flag any wording that sounds like "available right now" when
      it is really describing what a unit could do **on that tile**
- [ ] Flag any screen position where the preview or side panel feels too cramped
      to read comfortably even if it is technically visible

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
