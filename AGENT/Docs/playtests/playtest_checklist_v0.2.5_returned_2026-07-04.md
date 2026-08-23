---
Role: dated
Type: playtest
Status: Returned results - triaged in `playtest_v0.2.5_results_triage_plan_2026-07-04.md`
Last verified: 2026-07-04
---

> Returned 2026-07-03 (tester comments inline below). Screenshot evidence moved to
> `AGENT/Docs/archive/evidence/`: `levelup_first_show_narrow_panel_1080p_2026-07-03.png`
> ("first level up screen"), `promotion_picker_baseline_1x_2026-07-03.png`
> ("first autopromote"), `promotion_picker_2x_top_bottom_cutoff_2026-07-03.png`
> ("2x zoom auto promote"), `promotion_picker_0p5x_2026-07-03.png`
> ("0.5x zoom auto promote"), `windowed_4k_clamp_desktop_gap_2026-07-03.png`
> ("4k windowed mode"), `unit_details_horizontal_scrollbar_back_button_2026-07-01.png`
> ("zoomed in inventory scroll wheel"). `godot.log` was NOT returned with this pass.

# Playtester Handbook and Checklist - v0.2.5

This document is written for testers who have not read the design documents or source
code. **Everything needed for this test pass is in this one file.**

> **What this build is.** v0.2.5 is a **focused re-test** of the display and input problems
> originally reported on v0.2.3. It is identical to v0.2.4 except for two additional repairs
> to the Menu Scale slider (§1.1). **Part I re-checks each repaired item** and is the
> priority: it is the gate that lets us close the display work. **Part II** is a short
> confirmation of the surrounding display surfaces. **Part III** is the regression pointer.

## What was repaired since v0.2.4

Two follow-up fixes applied on top of the v0.2.4 repair set. Both map to the updated §1.1
check below.

- **Menu Scale vertical drift (V023-01 follow-up):** The v0.2.4 column lock held the slider
  horizontally but rows above it still changed height during a live drag, causing the slider
  to drift **vertically** under the cursor. `SettingsScreen.apply_menu_scale` now captures
  the Menu Scale row's on-screen y before the re-scale and restores it via the panel
  `ScrollContainer.scroll_vertical` one deferred-layout frame later.
- **Migration guard:** `SettingsManager`'s `menu_scale_schema_version` migration now shifts
  only indices that were **actually stored** in `settings.cfg`. A config file predating the
  menu-scale setting no longer has its in-memory `1.0x` default silently bumped to `1.25x`.
  (§1.9)

## What was repaired since v0.2.3 (still in this build)

All eight v0.2.4 repairs are included unchanged. Each maps to the Part I check referenced.

- **Menu Scale (Settings):** added a **0.5×** option for large displays; the Menu Scale
  **slider no longer moves under your cursor** while you drag it. (§1.1)
- **Character sheet:** now uses a **fixed centered frame that scrolls**, and it scales with
  Menu Scale like the other menus — including after you switch to a paired unit. (§1.2)
- **Action / item / weapon menus:** now **re-anchor to the tile when you zoom** the map, so
  they stop drifting away from the cursor. (§1.3)
- **Combat forecast (AttackPreview):** weapon rows should be **visible**; a no-advantage
  weapon triangle / effectiveness now shows a gray **`■ Neutral`** marker instead of a
  blank row; and the **More Info** text area is larger so it stops clipping. (§1.4)
- **Level-up screen:** **zooming / scrolling the wheel no longer dismisses it** — it stays
  up until you confirm or cancel. (§1.5)
- **Windowed resolutions:** picking a resolution at or above your monitor size now **clamps
  so the OS title bar stays reachable** (it no longer looks like fake fullscreen). (§1.6)
- **Archer description:** reworded so bow range reads as coming from the equipped weapon.
  (§1.7)
- **Terrain More Info:** **clicking** the panel now cycles its pages reliably, including the
  Movement-cost page. (§1.8)

## Before you begin

### Required build and equipment

- Windows 10 or 11, 64-bit
- Keyboard and mouse (a gamepad/d-pad is optional but useful for the selector check)
- A monitor that can show **1440p or 4K** is useful for §1.6 and §2.3 (otherwise mark those
  `NOT RUN`)
- Executable: `Project_Prometheus_v0.2.5_debug.exe`
- Expected file size: _see `AGENT/Docs/playtests/playtest_build_v0.2.5.md`._
- Expected SHA-256: _see the build manifest._
- Build manifest: `AGENT/Docs/playtests/playtest_build_v0.2.5.md`

The executable is a standalone debug build. It does not need Godot or an installer. Do not
disable antivirus to run it. If Windows blocks it, record the exact message and contact the
person who supplied the build.

Optional PowerShell integrity check (compare against the manifest hash):

```powershell
Get-FileHash .\Project_Prometheus_v0.2.5_debug.exe -Algorithm SHA256
```

### Tester information

- **Tester name:** _Enter name._
- **Test date:** _Enter date._
- **Windows version:** 11
- **Primary resolution:** 1920x1080
- **Monitor native resolution / size:** 3840x2160
- **Input method:** _Keyboard/mouse, gamepad, or both._
- **Build hash verified:** _Yes / No._

### How to record results

Complete the sections in order. Only check **This item works as expected** after every
expectation in that item passes. Record failures as:

`Map / Unit or UI / Step / Actual / Expected / Repro`

For visual failures, include the window resolution **and the Menu Scale in use**, and a
screenshot (`Win+Shift+S`). Crispness is judged by eye — a "soft/blurry text" failure
should say which menu and which scale. If a check cannot be performed, leave it unchecked
and write `NOT RUN` with the reason. Do not check an item merely because no problem was
noticed.

If the game crashes or stops accepting input, record the active map, unit, last action, and
visible screen. Close the game, preserve `godot.log`, relaunch, and continue.

### Controls

| Action | Keyboard / mouse |
|---|---|
| Move cursor or menu selection | `WASD` or arrow keys |
| Confirm / select | `Z`, `Enter`, `Space`, or left-click |
| Cancel / back | `X`, `Esc`, or right-click |
| Next / previous available unit | `Tab` / `Shift+Tab` |
| Open or close Map Menu | `M` |
| Open Settings directly | `O` |
| Inspect the unit under the cursor | `I` |
| Open or cycle More Info / terrain pages | `F` |
| Move the More Info selection | arrow keys / d-pad |
| Toggle danger/threat overlay | `Q` or middle-click |
| Zoom map in / out / reset | `=` / `-` / `0`, or mouse wheel |
| Force Level Up / Growth Boost (debug) | `F10` / `F11` |
| Toggle all-faction hotseat override (debug) | `F9` |

### Terms used in this handbook

- **Menu Scale:** the Settings slider that scales menus/modals only (not the HUD). In this
  build it runs **0.5× to 2.0×**.
- **Crisp / soft:** "crisp" = text edges are sharp; "soft" = blurry/fuzzy, as if zoomed.
- **Contextual menu:** the action/item/weapon menu that opens next to a unit after you move
  it (as opposed to full-screen menus like Settings that sit centered).
- **Letterbox / pillarbox:** black bars added top/bottom or left/right to keep the game's
  16:9 shape on a differently-shaped window.

---

# Part I — Repaired display & input surfaces (priority)

Any map works for these checks unless a specific map is named.

## 1.1 Menu Scale: 0.5× option, stable slider (horizontal AND vertical) (V023-01)

Open **Settings** (`O`) → **Menu Scale**. Click and hold the slider handle; drag it slowly
across the full range from 0.5× to 2.0× while **watching where the handle sits under your
cursor**. Confirm a **0.5×** value exists at the low end. Also change scale, close Settings,
reopen it, and confirm your choice stuck.

**Expected**

- There is a selectable **0.5×** step (below 0.75×), and the top is still **2.0×**.
- While you change the scale, the **Menu Scale slider handle does not slide sideways (left/
  right) under your cursor** — the control column stays put while only the text size changes.
- While you change the scale, the **Menu Scale slider row does not drift up or down** under
  your cursor — its vertical position should remain stable throughout the entire drag,
  including at the extremes of the range (0.5× and 2.0×). _(This is the new check added in
  v0.2.5: on v0.2.4 the row shifted vertically because rows above it changed height with the
  scale factor.)_
- At **0.5×**, menus are small but still **crisp** and readable (design feedback welcome if
  anything is too small).
- Your selected scale **persists** after closing and reopening Settings.

- [ ] **This item works as expected.**

**Tester comments:** size looks good, menu scale bar doesn't jump around vertically, but when moving between scales greater than 1x with the mouse the immediate jump in scale seems to cause the bar to readjust where the line between sizes should be causing it to flicker back and forth between sizes. We should also consider changing the spacing or using more aggressive wrapping at high zoom levels so that we don't trigger horizontal scroll wheels. 

## 1.2 Character sheet: centered, scales, and scrolls (V023-02a)

Press **`I`** on a unit to open the character sheet. At **1.0×, 1.5×, and 2.0×** Menu
Scale, check it. Then, on a map with a **paired unit** (e.g. Map 950 — Pair
`M950_Hero_SkillCap` with `M950_Cavalier`), open the sheet and switch between the lead and
support sheets.

**Expected**

- The sheet **scales with Menu Scale** like the other menus (it is not stuck at one size).
- It stays **centered** in the window, and stays centered after you switch to the paired
  unit's sheet (it should not drift off-center as you change units).
- When the content is taller than the frame, the panel keeps a **fixed frame and scrolls** —
  the top and bottom are both reachable and nothing is clipped where you can't scroll to it.

- [ ] **This item works as expected.**

**Tester comments:** centered and scales well, but can we do some text wrapping or something to avoid the sideways scroll bar? The back button is also much wider than it needs to be. Lets also make stats have just one more info section with the numbers at the top and prose at the bottom, then we can make the box the full height of the page and not cut off shorter descriptions.

## 1.3 Contextual menus re-anchor when you zoom (V023-03)

Select a unit, move it, and open its **action menu** (and from it an item/weapon submenu).
With the menu open, **zoom the map** (`=` / `-`, or the mouse wheel) and also change **Map
Zoom** in Settings while a menu is open.

**Expected**

- The action/item/weapon menu stays **anchored at/near the unit's tile** and **re-places
  itself after the zoom** — it does not stay frozen at its old screen position or drift far
  from the cursor/unit.

- [ ] **This item works as expected.**

**Tester comments:** better, but at close in zoom levels the menu does still jump around a bit
## 1.4 Combat forecast: weapon rows, Neutral markers, More Info fit (V023-04)

> **This is the highest-priority check in the build.** A previous tester reported the
> **weapon name row missing entirely**. Look carefully.

Initiate an attack to bring up the combat forecast. Read both combatants' rows. Then open
**More Info** (`F` or click a row) and cycle through the fields, including the weapon
triangle and effectiveness entries. Do this at a normal zoom and again **zoomed in (2×)**.

**Expected**

- Under **each** combatant's name is their **weapon name** (or **"Unarmed"**). The weapon
  row is present and readable for both attacker and defender.
- When there is **no** weapon-triangle advantage or effectiveness, that row shows a visible
  gray **`■ Neutral`** marker — not a blank/empty row.
- The **More Info** description text is **fully visible / scrollable** — not cut off at the
  bottom — including when zoomed in to 2×.

- [x] **This item works as expected.**

**Tester comments:** Lets talk about this a bit more, We need to think about how we can make the combat preview author extensible/modifiable. example, what if a author doesn't want to use a weapon advantage system and instead wants to base it entirely on class tag such as air, water, or land units. I also don't like the look of the second Neutral row for effectiveness. Consider changing effectiveness to be changing the per hit damage value to green if its doing extra damage and have a full breakdown available in the more info page. We should also make the attack preview have the same reposition on map zoom that the wait menu has.

## 1.5 Level-up screen ignores wheel/zoom (V023-05)

Select a unit and press **`F10`** to force a level-up. With the stat-gain screen showing,
**scroll the mouse wheel** and press the **zoom keys** (`=` / `-` / `0`). Then dismiss it
normally (confirm / left-click).

**Expected**

- Scrolling the wheel or pressing zoom **does nothing to the level-up screen and does not
  dismiss it** — the map behind does not zoom either.
- The screen dismisses **only** on confirm / cancel / left-click, and all stat lines are
  visible and crisp.
- _(Watch for a stretched/narrow panel — reported once on v0.2.3, unreproduced. If you see
  it, record the resolution and Menu Scale.)_

- [ ] **This item works as expected.**

**Tester comments:** first level up screen recorded and it was the same long and skinny as last time. menu scale was 1x resolution was 1920x1080 windowed. picture is in incoming folder. Second level up was normal. Restarted map and issue repeated itself. left click does not dismiss level up screen but keyboard does. Autopromote screen for the level 19 unit on the promotion validation map on max menu zoom cuts off the top and bottom of the menu quite badly. Second seal works well enough at both ends of the zoom scale but perhaps could expand in height, width, or just reduce some of the padding on the labels so that more of the class information is viewable at once. Or maybe we change the entire picking a class ui format to show a list of all available class names in a list on the left hand side that can scroll if needed, and a more info style pannel on the right that gives a better brakedown of the class with the things such as the prose class description, stat change information, weapons, skills, ect... possibly eventually even having a little animation that cycles through all the classes animations.

As a side note, double check what the skill cap in this build is and how many skills the skill cap hero on the promotion validation map has. Also give a few units some extra weapons so we can verify that weapon selection actually works.

## 1.6 Windowed resolution keeps the title bar reachable (V023-06)

In **Windowed** mode, open Settings → **Resolution** and pick a resolution **equal to or
larger than your monitor** (e.g. pick 1440p/4K on a 1080p/1440p monitor).

**Expected**

- The window **clamps to a size that fits inside your usable screen with the OS title bar
  reachable** — it does not turn into a borderless-looking window that hides the title bar.
- The confirm dialog (Keep / Revert / auto-revert) still works.
- Borderless and Fullscreen (tested separately if you like) still behave as their own modes.
- _If your monitor is the largest resolution offered, note that and mark `NOT RUN` for the
  "larger than monitor" part._

- [ ] **This item works as expected.**

**Tester comments:** testing 4k windowed mode does look visibly different from fullscreen or borderless, you can see the title bar, but there is still area where you can see the desktop around the screen. We should have a full discussion of how resolution, window mode, display size, and the OS window resizing works and all interacts.

## 1.7 Archer description wording (V023-08a)

Press `I` on an **Archer** (or any bow class), select the class row to open its **More
Info**, and read the description.

**Expected**

- The description presents bow range as coming from the **equipped weapon** — it no longer
  says the class "cannot attack adjacent / range 1" as a fixed class rule.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 1.8 Terrain More Info click paging (V023-09a)

Hover a tile and open **Terrain More Info** (`F`). Now use **mouse clicks** on the terrain
panel to cycle its pages: click through Hidden → Description → **Movement** (the move-cost
table) → Hidden. Pay attention to clicking **while the Movement page is showing**.

**Expected**

- Clicking anywhere inside the compact terrain panel or the expanded More Info page **cycles
  to the next page every time**, including advancing **off the Movement page** back to
  Hidden. (On v0.2.3 the click failed specifically on the Movement page.)

- [ ] **This item works as expected.**

**Tester comments:** repeats 0.2.3 behavior and clicking in the more info page while the mouse is in click mode will move it to movement cost, but not dismiss it. Consider again the possibility of making it one page that uses the tile type and coordinate as a label and simply cycles through all the more info options with the tactics info as another option.

## 1.9 Previously saved 1.0× Menu Scale survives an upgrade (migration guard)

> This check only applies if you have a **previously saved `settings.cfg`** from a build
> older than v0.2.4 (or any build where you never changed Menu Scale from the default).
> If you have no prior save file, mark `NOT RUN`.

Launch the game without changing Menu Scale (or with a save file from before menu-scale was
a setting). Open **Settings** → **Menu Scale** and read the value.

**Expected**

- The slider shows **1.0×** (the default) — it has **not** been silently bumped to **1.25×**
  or any other value by the migration. _(On v0.2.4 a settings.cfg predating the menu-scale
  field could be migrated to 1.25x instead of keeping the 1.0x default.)_

- [ ] **This item works as expected (or `NOT RUN` — no prior save file).**

**Tester comments:** NOT RUN 
Please explain how the settings.cfg works and how it used and how it might work accross versions.

---

# Part II — Surrounding display confirmation

These share the display/renderer code touched by the repairs. Quick confirmation only.

## 2.1 Renderer & crispness sanity

Load any map. At a couple of Menu Scales, open several menus (Main Menu, Settings, Map Menu,
an action menu, the combat forecast, the character sheet) and read the text.

**Expected**

- The game looks correct (no black screen, missing sprites, garbled tiles, wrong colours),
  and menu/label text is **crisp** at every scale.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.2 Centered menus stay centered

At a few Menu Scales, open the full-screen menus (Main Menu, New Game, Settings, Map Menu)
and, in windowed mode, resize the window with one open.

**Expected**

- These panels stay **centered** at every scale and after a resize.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.3 Native 1440p / 4K resolutions present

Settings → **Resolution** (Windowed).

**Expected**

- The list includes **2560×1440** and **3840×2160** alongside the smaller options, and a
  supported one applies via the confirm dialog. _(Mark `NOT RUN` if your monitor is below
  1440p.)_

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.4 Letterboxing on an odd-shaped window

In Windowed mode, drag the window to a very wide, then very tall, shape.

**Expected**

- The game keeps its 16:9 picture with **black bars** filling the leftover space; the HUD
  and menus stay on-screen and undistorted.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

---

# Part III — Regression pointer

The repairs touch menus, the combat forecast, the character sheet, terrain paging, and
display/window handling. If you have time after Parts I–II, run the **full per-map
regression** from the v0.2.0 handbook
(`AGENT/Docs/archive/playtests/playtest_checklist_v0.2.0.md`, Part II: Maps 001–005, 900,
950), watching especially:

- **Menus** at various Menu Scales (centering, crispness, fit, the new 0.5×).
- **The character sheet** (`I`) — scaling, scrolling, centering, paired-unit swaps.
- **The combat forecast** — weapon rows and Neutral markers.
- **Terrain paging** — key `F` and mouse clicks.
- **Window/resolution handling** — windowed clamp, borderless, fullscreen.

- [ ] **Regression pass run (or `NOT RUN` with reason).**

**Tester comments:** _Enter comments here._

---

# Error-log check

After the pass, close the game and inspect:

`%APPDATA%\Godot\app_userdata\Fire Emblem RPG\logs\godot.log`

Report any line containing `ERROR`, `SCRIPT ERROR`, a `DataManager: …` error, a
`push_error`, or a crash stack trace, with the active map. If the file is absent, record
`LOG FILE NOT FOUND`. **Please return the `godot.log` file this pass** — it was not included
with the v0.2.3 return and was requested again in v0.2.4. (Expected, harmless: pre-M9 skill
stub warnings such as `armsthrift`, `dash`, `disarm`, and a generic
`ObjectDB instances leaked at exit`.)

- [ ] **No unexpected errors in `godot.log`.**

**Tester comments:** _Enter comments here._

---

# Known deferred issues

Do not report the unchanged behavior below as a v0.2.5 regression — these are known and
scheduled for later work:

- **Character-sheet page layout** (a paged sheet instead of one long scroll) is a later UI
  pass (`V023-02b`). This build only fixes scaling/centering/scrolling.
- **HUD Layout editor** does not yet size its edit frame to include the expanded terrain
  More Info footprint (`V023-07`).
- **Class More Info** does not yet list full unit/equipment trait aggregation or the active
  movement-rule source (`V023-08b`).
- **Terrain More Info** shows actions for the selected unit only, not a full "all actions +
  requirements" list (`V023-09b`).
- **Map Menu** does not yet close on right-click / backdrop tap in all cases (`V023-10`).
- **HUD panel scale is still soft** in the HUD Layout editor — the crisp rework is menus
  only (V021-04).
- **Aura skills** remain placeholders (M9) and do not contribute to the stat breakdown.

---

# What to send back

1. This completed handbook with every applicable checkbox marked.
2. Tester comments for every failed or unclear item — **especially §1.1 (slider vertical
   drift), §1.4 (weapon row), and §1.5 (wheel input)**, which are the changes we most need
   confirmed.
3. The **`godot.log` file** (or a note that it was not found), and the Error-log results.
4. Screenshots for any visual failure — for crispness/scale issues include the **Menu Scale
   and window resolution** in use.
5. Exact repro steps using the failure format at the top of this document.
6. Your overall read on the **0.5× Menu Scale** readability on your display.
