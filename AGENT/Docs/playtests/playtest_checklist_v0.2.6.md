# Playtester Handbook and Checklist - v0.2.6

This document is written for testers who have not read the design documents or source
code. **Everything needed for this test pass is in this one file.**

> **What this build is.** v0.2.6 is the **fix build** for the problems reported on v0.2.5.
> Part I re-checks each repaired item — it is the priority and the gate that lets us close
> the display/input work. Part II checks the promotion-validation content (Map 950). Part
> III is the regression pointer and the **log request** (the log now lives **next to the
> game .exe** — see §3.2, please return it this time).

## What was repaired since v0.2.5

Each item maps to the Part I check referenced.

- **Menu Scale slider (§1.1):** the scale now applies when you **release** the slider, so
  it no longer flickers between sizes while you drag; the Settings panel is **wider** and no
  longer shows a **horizontal scrollbar** at high scales.
- **Character sheet (§1.2):** long lines now **wrap** instead of forcing a sideways
  scrollbar; the **Back** button is no longer full-width; the stats **More Info** panel now
  puts the **numbers on top and the description below**, filling the full height.
- **Contextual menu at close zoom (§1.3):** the action/item/weapon menu now **hugs the
  unit** at high zoom and keeps its side, instead of jumping around.
- **Combat forecast (§1.4):** the attack preview now **re-anchors when you zoom**, the same
  way the action menu does.
- **Level-up & promotion (§1.5):** the **first** level-up on a map is now a normal-shaped
  panel (it used to render tall and narrow); a **left-click dismisses** the level-up screen
  (previously only the keyboard did); the **promotion picker fits on screen at 2.0×** Menu
  Scale (it used to cut off the top and bottom) and scrolls if the class list is long.
- **Windowed size readout (§1.6):** Settings now shows the **actually-applied window size**
  next to the Resolution dropdown, so a clamped 4K-in-a-window request is self-explaining.
- **Terrain More Info (§1.8):** **clicking** the panel now cycles its pages reliably,
  including the Movement-cost page.

## Before you begin

### Required build and equipment

- Windows 10 or 11, 64-bit
- Keyboard and mouse (a gamepad/d-pad is optional but useful for the selector checks)
- A monitor that can show **1440p or 4K** is useful for §1.1, §1.6 (otherwise mark those
  `NOT RUN`)
- Executable: `Project_Prometheus_v0.2.6_debug.exe`
- **The `._sc_` file that ships beside the .exe must be kept in the same folder** — it is
  what makes the game write its save and log next to itself (see §3.2). Do not delete it.
- Expected file size / SHA-256: _see `AGENT/Docs/playtests/playtest_build_v0.2.6.md`._

The executable is a standalone debug build. It does not need Godot or an installer. Do not
disable antivirus to run it. If Windows blocks it, record the exact message and contact the
person who supplied the build.

Optional PowerShell integrity check (compare against the manifest hash):

```powershell
Get-FileHash .\Project_Prometheus_v0.2.6_debug.exe -Algorithm SHA256
```

### Tester information

- **Tester name:** _Enter name._
- **Test date:** _Enter date._
- **Windows version:** _Enter version._
- **Primary resolution:** _Enter resolution._
- **Monitor native resolution / size:** _Enter (for the 1440p/4K + windowed checks)._
- **Input method:** _Keyboard/mouse, gamepad, or both._
- **Build hash verified:** _Yes / No._

### How to record results

Complete the sections in order. Only check **This item works as expected** after every
expectation in that item passes. Record failures as:

`Map / Unit or UI / Step / Actual / Expected / Repro`

For visual failures, include the window resolution **and the Menu Scale in use**, and a
screenshot (`Win+Shift+S`). If a check cannot be performed, leave it unchecked and write
`NOT RUN` with the reason. Do not check an item merely because no problem was noticed.

If the game crashes or stops accepting input, record the active map, unit, last action, and
visible screen. Close the game, **preserve `godot.log` (see §3.2)**, relaunch, and continue.

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
| Toggle danger/threat overlay | `Q` or middle-click |
| Zoom map in / out / reset | `=` / `-` / `0`, or mouse wheel |
| Force Level Up / Growth Boost (debug) | `F10` / `F11` |

### Terms used in this handbook

- **Menu Scale:** the Settings slider that scales menus/modals only (not the HUD). It runs
  **0.5× to 2.0×**.
- **Contextual menu:** the action/item/weapon menu that opens next to a unit after you move
  it (as opposed to full-screen menus like Settings that sit centered).

---

# Part I — Repaired display & input surfaces (priority)

Any map works for these checks unless a specific map is named. **Map 950 — Promotion
Validation** is the best map for §1.5 (it has a promotable roster and grind units).

## 1.1 Menu Scale: apply-on-release, no horizontal scrollbar (V025-01)

Open **Settings** (`O`) → **Menu Scale**. Click and hold the slider and drag it slowly
across the full 0.5×–2.0× range, then release. Try this at a high window resolution
(1440p/4K if available).

**Expected**

- While dragging, the value **does not flicker back and forth** between sizes; the label
  previews the target factor and the whole screen re-scales **once, when you release**.
- At high Menu Scale, the Settings panel **does not show a horizontal scrollbar** — rows fit
  within the (now wider) panel; long labels may shorten with an ellipsis rather than
  overflow sideways.
- Your selected scale **persists** after closing and reopening Settings.

- [ ] **This item works as expected.**

**Tester comments:** _If it still flickers, note at which scale values._

## 1.2 Character sheet: wrap, Back button, More Info layout (V025-02)

Press **`I`** on a unit (Map 950 units have full inventories). Check at **1.0× and 2.0×**
Menu Scale. Open the stats **More Info** (`F` or click a stat).

**Expected**

- Long inventory / weapon-rank lines **wrap** within the column — **no horizontal
  scrollbar** appears.
- The **Back** button is a normal button width (centered), **not stretched** across the
  whole column.
- In the stats More Info panel, the **numbers (the stat breakdown) are at the top** and the
  **description text is below** it, and the panel is **full page height** so a short
  description does not shrink the box.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 1.3 Contextual menu hugs the unit at close zoom (V025-03)

Select a unit, move it, open its **action menu**. **Zoom the map all the way in** (`=` or
the mouse wheel) with the menu open, and move the cursor a little.

**Expected**

- The menu **stays close to the unit** at high zoom (it does not leap a full magnified tile
  away) and **does not jitter / flip sides** on small zoom or cursor changes.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 1.4 Combat forecast re-anchors when you zoom (V025-04)

Initiate an attack to bring up the combat forecast. With it visible, **zoom the map** in and
out.

**Expected**

- The forecast panel **re-anchors** beside the defender when you zoom (the same way the
  action menu does) — it does not stay frozen at its old position.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 1.5 Level-up and promotion (V025-05) — use Map 950

On **Map 950 — Promotion Validation**, level up a unit (grind a red unit, or use `F10`
Force Level Up), and promote a level-10+ unit (e.g. use the Master Seal on
`M950_Lvl19_Merc`). Check the promotion picker at **2.0×** Menu Scale.

**Expected**

- **First level-up per map:** the level-up panel is a **normal, roughly-square shape** —
  **not** a tall, narrow sliver. (Restart the map and check the first one again.)
- **Left-click dismisses** the level-up panel (not only the keyboard). Right-click also
  advances. The mouse **wheel** does not dismiss it.
- **Promotion picker at 2.0×:** the whole picker **fits on screen** — the top and bottom are
  **not cut off** — and it **scrolls** if the class list is long.

- [ ] **This item works as expected.**

**Tester comments:** _Note the Menu Scale used for the promotion check._

## 1.6 Windowed size: applied-size readout (V025-06)

In **Settings → Window Mode = Windowed**, pick a **Resolution at or above your monitor
size** (e.g. 4K on a 4K/1440p monitor). Look at the row next to the Resolution dropdown.

**Expected**

- A small **"→ applied W×H"** readout appears next to Resolution showing the size the window
  was actually given (it will be **smaller** than the request so the title bar stays
  reachable). Desktop showing **around** the window in this case is **expected**, not a bug
  — switch to **Borderless/Fullscreen** to fill the monitor.

- [ ] **This item works as expected.**

**Tester comments:** _Enter the requested vs applied sizes shown._

## 1.7 Terrain More Info: click paging (V025-08)

Hover a tile, press **`F`** to open terrain More Info, then **click** the panel to cycle its
pages — including onto the **Movement-cost** page.

**Expected**

- **Clicking** the panel cycles pages **reliably**, including the Movement page, and cycles
  back to close. (Previously a click on the Movement page did nothing.)

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

---

# Part II — Promotion-validation content (Map 950)

These check the content added for promotion/level-up testing.

## 2.1 Skill cap and weapon selection (V025-05e)

Inspect **`M950_Hero_SkillCap`** (`I`). Then, in combat prep or on the map, open a unit's
**weapon** selection for the hero and for `M950_Lvl19_Merc`.

**Expected**

- `M950_Hero_SkillCap` shows **five** skills (it now sits **at** the skill cap). If it would
  learn a sixth, the level-up line explains the slots are full.
- The hero and the Lvl19 merc each carry **more than one weapon**, so the weapon-selection
  menu offers a **choice**.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.2 Grinding and stat caps

Map 950 now has **10 extra weak red "Grind" units**. Use them to level a single unit
repeatedly (kill them, or use `F10`).

**Expected**

- You can farm enough level-ups to **push a stat to its class cap**, and the stat **stops at
  the cap** (it does not exceed it).

- [ ] **This item works as expected.**

**Tester comments:** _Note which unit/stat you drove to a cap._

---

# Part III — Regression and logs

## 3.1 Quick regression

Play a few turns on any map: move, attack, use an item, end the turn, open/close each menu.
Report anything that regressed versus normal play.

- [ ] **No regressions noticed.**

**Tester comments:** _Enter comments here._

## 3.2 Return the log — it now lives NEXT TO THE .EXE

**This build writes its log beside the game, and we need it back this time** (it was missed
on the last three returns). Because of the `._sc_` file shipped next to the `.exe`, the game
stores its data **in its own folder**, not in `%APPDATA%`.

- After playing (especially if anything looked wrong), close the game and find:
  **`logs\godot.log`** inside the game's folder (next to the `.exe`). If you don't see a
  `logs` folder there, the `._sc_` file may have been removed — check `%APPDATA%\Godot\
  app_userdata\Fire Emblem RPG\logs\godot.log` as a fallback.
- **Open `godot.log` and copy the first block** — it starts with `=== BUILD STAMP ===` and
  lists the version, a commit id, a `started_at` time, and the exact `log=` path. Paste that
  block into your report (it confirms which build you ran and that the log is live), and
  **attach the whole `godot.log` file**.
- The log is grabbed **per launch** (a new one starts each time you run the game), so copy
  it **before relaunching** if you hit a problem.

- [ ] **`godot.log` attached, with the BUILD STAMP block pasted into the report.**

**Tester comments:** _Paste the BUILD STAMP block here._

---

Thank you. Part I is the gate that closes the display/input work; §3.2 (returning the log)
is the single most-requested item — please don't skip it.
