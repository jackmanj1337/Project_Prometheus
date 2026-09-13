---
Role: dated
---

# Playtester Handbook and Checklist - v0.2.8

This document is written for testers who have not read the design documents or source
code. **Everything needed for this test pass is in this one file.**

> **What this build is.** v0.2.8 is a **rerun build** that exists to **close the display
> gate**. The v0.2.7 return closed most of the list; only **three items failed** and were
> fixed since — so Part I here is just **§1.3, §1.4 and §1.6**. Everything else from the
> earlier handbooks is **not** retested (see the note just below). Part III is the light
> regression pointer and the **log request** — the log return worked great last time,
> please do it again (§3.2).

> **Already PASSED — not retested in this build:** §1.1 Menu Scale and §1.5 promotion
> picker (both passed live in v0.2.7), §1.2 character sheet, §1.7 terrain paging, **all of
> Part II** (Map 950 promotion-validation content), and the full regression pass. Do not
> re-run these unless you happen to notice a regression while doing the checks below — if
> so, note it in §3.1.

## What changed since v0.2.7 (what you are re-verifying)

Each of your three v0.2.7 failure reports was reproduced, diagnosed, and fixed. This
build asks you to confirm the fixes **live**:

- **Action menu at zoom (§1.3):** you reported the menu *"gradually moves more over the
  unit the more you zoom in."* Confirmed — the menu was offset a fixed distance from the
  tile's **left** edge, so a magnified tile swallowed it. It now anchors to the zoomed
  tile's **far edge plus a small constant gap**, so it should hug the unit **without
  covering it** at every zoom level.
- **Combat forecast (§1.4):** two fixes. (1) The *"extra space in the tinted window"* on
  the **first** open — the panel now re-sizes itself one frame after it appears, so the
  first open should look identical to every later open. (2) The **left-wall**
  misplacement — the root cause was a stale camera transform when the cursor scrolled the
  map in the same frame; that write is now flushed, plus the panel automatically
  re-anchors itself one frame after any zoom (the automated version of your manual
  "zoom past max" workaround). Please check **both walls** at max zoom this time.
- **Windowed sizing (§1.6):** three fixes. (1) The menu **stretch** after switching
  windowed 1440p → 4K at 2.0× Menu Scale — menus now re-apply their scale whenever the
  window size changes. (2) The applied-size readout going **stale after an OS
  drag-resize** — dragging the window edge now **writes the new size back into the saved
  Resolution setting** (this is new behaviour, see the §1.6 explainer). (3) Your ask to
  **gray out Resolution outside Windowed mode** — done, the readout pins to your native
  size there.

## Before you begin

### Required build and equipment

- Windows 10 or 11, 64-bit
- Keyboard and mouse
- A monitor that can show **1440p or 4K** is useful for §1.6 (otherwise mark the 4K
  sub-checks `NOT RUN`)
- Executable: `Project_Prometheus_v0.2.8_debug.exe`
- Expected file size / SHA-256: _see `AGENT/Docs/playtests/playtest_build_v0.2.8.md`._

The executable is a standalone debug build. It does not need Godot or an installer. Do not
disable antivirus to run it. If Windows blocks it, record the exact message and contact the
person who supplied the build.

Optional PowerShell integrity check (compare against the manifest hash):

```powershell
Get-FileHash .\Project_Prometheus_v0.2.8_debug.exe -Algorithm SHA256
```

### Tester information

- **Tester name:** Jacob Jackman
- **Test date:** _Enter date._
- **Windows version:** _Enter version._
- **Primary resolution:** _Enter resolution._
- **Monitor native resolution / size:** _Enter (for the §1.6 windowed checks)._
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

# Part I — Display rerun (§1.3 / §1.4 / §1.6 only)

Any map works for these checks. This is a **rerun of the three items that failed in
v0.2.7 only** — everything that already passed is listed in the note near the top and is
not repeated here.

## 1.3 Contextual menu anchoring at high zoom (V027-02)

Select a unit, move it, open its **action menu**. With the menu open, step through the
**whole zoom range** (`=` / `-` or the mouse wheel), pausing at several levels between 1×
and max. In v0.2.7 the menu crept **over the unit** as zoom rose; it now anchors to the
zoomed tile's **far edge plus a constant gap**, so it should sit just outside the unit's
tile at every zoom.

**Expected**

- At **every** zoom level, the menu sits **just beside the unit's tile** — close enough to
  read as attached, but **never covering the unit**, even at maximum zoom (where the tile
  itself is very large on screen).
- The gap between the tile edge and the menu stays **small and roughly constant** as you
  zoom — the menu neither drifts over the unit (the v0.2.7 bug) nor leaps a full magnified
  tile away (the older v0.2.5 bug).
- The menu does **not jitter or flip sides** on small zoom or cursor changes.

- [x] **This item works as expected.**

**Tester comments:** _Note the zoom level if the menu still overlaps the unit or drifts._

## 1.4 Combat forecast: first-open sizing + BOTH walls at max zoom (V027-03)

Two sub-checks — do both.

**(a) First open of the session.** From a **fresh boot**, initiate the session's very
first attack and look at the forecast panel. In v0.2.7 the **first** open had extra empty
tinted space below the information; the panel now re-runs its sizing one frame after it
appears.

**(b) Both walls at max zoom.** Initiate attacks with the defender near the **left wall**
of the map, then near the **right wall**. With the forecast visible, **zoom to maximum**
in each spot, and also try opening the forecast **while the camera is still scrolling**
to the fight (move the cursor to the wall and confirm the attack quickly). In v0.2.7 the
right wall was fixed but the **left wall** still misplaced; the root cause (a stale
camera transform during same-frame cursor scrolls) is fixed, and the panel additionally
**re-anchors itself one frame later** as a self-heal — so you should never need the old
manual "keep zooming past max" workaround.

**Expected**

- **(a)** The first forecast of a session is sized to its contents — **no extra dead
  space** below the rows — and looks identical to the second and later opens.
- **(b)** The forecast panel sits **beside the defender** at **both** the left and right
  walls at max zoom — it does **not** overlap the defender or sit stranded elsewhere, and
  it settles correctly **on its own** (at worst within a single frame; no extra no-op zoom
  steps needed).

- [x] **This item works as expected.**

**Tester comments:** _Note the wall, zoom level, and whether the first open showed dead space._

## 1.6 Windowed sizing: resize re-scale, drag write-back, gray-out (V027-04/05c)

**Read this first — the explainer, corrected since v0.2.7:**

- **Resolution only matters in Windowed mode.** The **Resolution** dropdown is only used
  when **Window Mode = Windowed**. In **Borderless** and **Fullscreen** the game fills
  your monitor at its native size — and to make that self-evident, the Resolution
  dropdown is now **grayed out** outside Windowed mode and the readout beside it shows
  **`native WxH`** (your monitor's size). Your saved windowed choice is preserved and the
  row re-enables when you switch back to Windowed.
- **Request → clamp → applied.** In Windowed mode you **request** a size and the game
  **clamps** it to fit the usable screen (leaving room for the title bar and taskbar).
  The **"→ applied W×H"** readout next to Resolution shows the size you actually got. A
  4K windowed request on a 4K monitor showing a smaller applied size (desktop visible
  around the window) is **expected, not a bug** — use Borderless/Fullscreen to fill the
  monitor.
- **Resizing via the OS — new behaviour, and a correction.** If you drag the **window's
  edge** yourself, the game now **writes that new size back into the saved Resolution
  setting** — the setting follows the real window. If the dragged size is not one of the
  presets, the dropdown shows a **`Custom (WxH)`** entry as the selected value (picking
  any preset replaces it). The window is **NOT re-centred** after a drag-resize — you
  just placed it, so it stays put. (The v0.2.7 handbook claimed a drag re-centres the
  window; that was wrong — our error, not a behaviour change.)

**Now test it** (in **Settings → Window Mode = Windowed** unless a step says otherwise):

1. **Resolution-switch re-scale:** set **Menu Scale to 2.0×**, then switch Resolution
   **1440p → 4K** (or between the two largest sizes your monitor allows). In v0.2.7 this
   stretched the Settings menu off the right edge of the screen once per boot; menus now
   re-apply their scale on any window-size change.
2. **Drag write-back:** drag the window's edge to a clearly non-preset size. Watch the
   **applied readout** and the **Resolution dropdown**.
3. **Gray-out:** switch Window Mode to **Borderless**, then **Fullscreen**, and look at
   the Resolution row. Switch back to **Windowed**.

**Expected**

- **(1)** After the 1440p → 4K switch at 2.0× Menu Scale, the Settings menu is **sized and
  centred correctly** — no stretching off the edge of the screen, no slider wiggle needed
  to recover, including on the **first** switch after boot.
- **(2)** After a drag-resize, the **applied W×H readout updates** to the real new size,
  and the **Resolution dropdown now shows that size** — as a **`Custom (WxH)`** entry if
  it isn't a preset. The window stays **where you put it** (no re-centre). The written-back
  size **persists**: quit and relaunch, and the window comes back at the dragged size.
- **(3)** In Borderless and Fullscreen the Resolution dropdown is **grayed out** and the
  readout shows **`native WxH`**. Switching back to Windowed re-enables the dropdown with
  your last windowed size (including a `Custom` one) intact.

- [ ] **This item works as expected.**

**Tester comments:** borderless and fullscreen work well. However the custom WxH readout doesn't seem to be updating live all the time. Please investigate and include a more detailed explanation about what exactly is being measured. There was also a problem discovered where if you are in a windowed mode and have the settings menu open then use the windows fullscreen button in the top right corner the menu does the old thing where the menu does not stay centered but recenters on adjusting the size. Lets also revisit the idea of being able to change the full viewport window ratio so that when we ship a steam deck or mobile version we don't have to deal with black bars.

---

# Part II — Promotion-validation content (Map 950)

**Skipped in this rerun — passed in v0.2.6.** If you notice a content problem while
playing, record it in §3.1.

---

# Part III — Regression and logs

## 3.1 Quick regression

Play a few turns on any map: move, attack, use an item, end the turn, open/close each menu.
Report anything that regressed versus normal play. (The full regression pass already
passed — this is just a light sanity check while you run Part I.)

- [x] **No regressions noticed.**

**Tester comments:** _Enter comments here._

## 3.2 Return the log — same flow that worked last time

The v0.2.7 log return worked perfectly — please do exactly the same again. The log lives
in your Windows **user-data folder** under `%APPDATA%`, not beside the exe.

- **Let the log tell you where it is — this is authoritative.** Every launch, the game prints
  a framed **BUILD STAMP** as the very first lines of the log. That block includes a **`log=`**
  line showing the **exact, full path** to the log file. **Copy the path from that `log=`
  line** — it is the source of truth for where your log is.
- **Typical path shape** (so you can find it before you've opened the log):
  `%APPDATA%\Godot\app_userdata\<project>\logs\godot.log`. You can paste **`%APPDATA%`** into
  the **Windows Explorer address bar** to jump straight to the `Roaming` folder, then drill
  down `Godot\app_userdata\<project>\logs\`.
- **Open `godot.log` and copy the first block** — it starts with `=== BUILD STAMP ===` and
  lists the version, a commit id, a `started_at` time, and the exact `log=` path. Paste that
  block into your report (it confirms which build you ran and where the log lives), and
  **attach the whole `godot.log` file**.
- The log is written **per launch** (a fresh one starts each time you run the game), so copy
  it **before relaunching** if you hit a problem.

- [ ] **`godot.log` attached, with the BUILD STAMP block pasted into the report.**

**Tester comments:** _Paste the BUILD STAMP block here (the `log=` line is the exact path)._

---

Thank you. These three checks are the last items holding the display gate — a clean Part I
here closes it.
