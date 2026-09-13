---
Role: dated
---

# Playtester Handbook and Checklist - v0.2.7

This document is written for testers who have not read the design documents or source
code. **Everything needed for this test pass is in this one file.**

> **What this build is.** v0.2.7 is a **rerun build** that exists to **close the display
> gate**. It re-checks only the display/input items that were still open (or newly fixed)
> after the v0.2.6 return. Everything that already passed in v0.2.6 is **not** retested here
> (see the note just below). Part III is the regression pointer and the **log request** —
> the log-location guidance has been corrected (see §3.2, please return the log this time).

> **Already PASSED in v0.2.6 — not retested in this build:** §1.2 character sheet, §1.7
> terrain paging, **all of Part II** (Map 950 promotion-validation content), and the **Part
> III regression pass**. Do not re-run these unless you happen to notice a regression while
> doing the checks below — if so, note it in §3.1.

## What to re-verify since v0.2.6

Each item maps to the Part I check referenced. All of these were fixed **after** the v0.2.6
return; this build asks you to confirm them **live**.

- **Menu Scale slider (§1.1):** the **first** time you apply **2.0×** after booting, the
  menu should **centre correctly on the first apply** (no off-centre first frame, no
  wiggle-to-settle). Still no **horizontal scrollbar**, and there is now **padding on the
  right** between the options and the scrollbar. The **hotseat debug** keybind now appears in
  the in-game controls list.
- **Contextual menu at high zoom (§1.3):** the action/item/weapon menu anchoring was
  reworked for **high** zoom levels (it was fine below ~1.5× but off above that). Re-walk it
  at **2×–4×** zoom.
- **Combat forecast at max zoom (§1.4):** the forecast anchoring was fixed for the **right
  wall + max zoom** case (it used to overlap/mis-place until you kept zooming past max).
  Re-walk it there. Hit/Crit rows now render **dashes** when a value is unavailable so the
  advantage icons stay aligned.
- **Promotion picker (§1.5):** the authored panel size was **raised** so that at **2.0×**
  Menu Scale **at least one full class option is visible in the frame**, and keyboard focus
  now **scrolls the frame** to the highlighted option.
- **Windowed size readout (§1.6):** unchanged behaviour, but this build adds a plain-language
  **explainer** (see the preamble in §1.6) of what the resolutions do and how resizing the OS
  window affects the applied size.

## Before you begin

### Required build and equipment

- Windows 10 or 11, 64-bit
- Keyboard and mouse (a gamepad/d-pad is optional but useful for the selector checks)
- A monitor that can show **1440p or 4K** is useful for §1.1, §1.6 (otherwise mark those
  `NOT RUN`)
- Executable: `Project_Prometheus_v0.2.7_debug.exe`
- Expected file size / SHA-256: _see `AGENT/Docs/playtests/playtest_build_v0.2.7.md`._

The executable is a standalone debug build. It does not need Godot or an installer. Do not
disable antivirus to run it. If Windows blocks it, record the exact message and contact the
person who supplied the build.

Optional PowerShell integrity check (compare against the manifest hash):

```powershell
Get-FileHash .\Project_Prometheus_v0.2.7_debug.exe -Algorithm SHA256
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

# Part I — Display & input rerun (priority)

Any map works for these checks unless a specific map is named. **Map 950 — Promotion
Validation** is the best map for §1.5 (it has a promotable roster and grind units). This is a
**rerun of the remaining/new items only** — the items that passed in v0.2.6 are listed in the
note near the top and are not repeated here.

## 1.1 Menu Scale: first-apply centering, scrollbar padding, controls list (V026-01)

Open **Settings** (`O`) → **Menu Scale**. Do this test at a high window resolution
(1440p/4K if available). First, **right after booting the game**, move the slider to **2.0×**
in one action and let go — watch the **first** apply. Then drag the slider slowly across the
full 0.5×–2.0× range and release at a few values. Also open the game's **controls list** and
look for the **hotseat debug** entry.

**Expected**

- **First apply at 2.0× after boot:** the menu **centres correctly on the very first apply**
  — it does **not** render off-centre for a frame, and you should **not** have to wiggle the
  slider back and forth for the width/centring to "settle." (In v0.2.6 the first 2.0× apply
  after boot was off-centre and only settled after wiggling.)
- While dragging, the value **does not flicker back and forth** between sizes; the label
  previews the target factor and the whole screen re-scales **once, when you release**.
- At high Menu Scale, the Settings panel **does not show a horizontal scrollbar** — rows fit
  within the (now wider) panel; long labels may shorten with an ellipsis rather than
  overflow sideways.
- There is now **padding between the options and the scrollbar** on the right — the option
  rows are **not pressed right up against** the scrollbar.
- The **hotseat debug** keybind now **appears in the in-game controls list** (it was missing
  in v0.2.6).
- Your selected scale **persists** after closing and reopening Settings.

- [ ] **This item works as expected.**

**Two specific asks from your v0.2.6 report:**

- **(a) Finish your cut-off sentence.** In v0.2.6 your comment ended mid-sentence: *"…moved
  menu scale from 0.5x to 2x and the same centering issue reoccured and this time"* — please
  **finish that sentence** and tell us exactly what you saw when the centering issue recurred
  on the new map.
- **(b) Pin down the "still flickers slightly" report.** You wrote the value label *"still
  flickers slightly if you hover near the border."* We **could not reproduce it**. Please try
  again and, if it happens, name the **EXACT slider/pointer position** and what you were
  doing — dragging or just hovering, and at **which value** — when it flickered.

**Tester comments:** _If it still flickers, note at which scale values and per ask (b) above._

## 1.3 Contextual menu anchoring at high zoom (V026-03)

Select a unit, move it, open its **action menu**. With the menu open, **zoom the map in to
high levels** (`=` or the mouse wheel) and move the cursor a little. Re-walk this specifically
across the **2×–4× zoom** range (this is where it was still off in v0.2.6 — below ~1.5× it was
already fine).

**Expected**

- The menu **stays close to the unit** even at **2×–4× zoom** (it does not leap a full
  magnified tile away) and **does not jitter / flip sides** on small zoom or cursor changes.

- [ ] **This item works as expected.**

**Tester comments:** _Note the zoom level if any mis-placement remains._

## 1.4 Combat forecast anchoring at the right wall + max zoom (V026-04)

Initiate an attack to bring up the combat forecast, positioned so the defender is **near the
right wall of the map**. With the forecast visible, **zoom the map to maximum**. Re-walk this
specific case (right wall + max zoom) — in v0.2.6 the panel overlapped/mis-placed there and
only normalised if you kept trying to zoom past max.

**Expected**

- The forecast panel **re-anchors** beside the defender when you zoom, including at the
  **right wall at max zoom** — it does **not** overlap the defender or sit mis-placed, and it
  should be correct **without** needing extra no-op zoom steps to settle.
- When Hit or Crit is unavailable, the forecast shows a **dash** for that row (rather than the
  row disappearing) so the advantage icons stay lined up.

- [ ] **This item works as expected.**

**Tester comments:** _Note the zoom level and defender position if anything remains off._

## 1.5 Promotion picker fits a full class option at 2.0× (V026-05) — use Map 950

On **Map 950 — Promotion Validation**, promote a level-10+ unit (e.g. use the Master Seal on
`M950_Lvl19_Merc`) to bring up the **promotion picker**. Set **Menu Scale to 2.0×** first.
Move the selection through the class list with the **directional keys**.

**Expected**

- At **2.0×** Menu Scale, **at least one full class option is visible within the frame** —
  the panel is now sized so a whole class entry fits (previously you could not see an entire
  class at once). The top and bottom of the picker are **not cut off**.
- Moving the highlight with the **keyboard scrolls the frame** so the focused option is
  brought into view — keyboard focus is not limited to only the top option.

- [ ] **This item works as expected.**

**Tester comments:** _Note the Menu Scale used and whether a full option fit in the frame._

## 1.6 Windowed size: applied-size readout, with an explainer (V026-06)

**Read this first — what the resolutions actually do (you asked for this in v0.2.6):**

- **Resolution only matters in Windowed mode.** The **Resolution** dropdown is only used when
  **Window Mode = Windowed**. In **Borderless** and **Fullscreen** the game just fills your
  monitor at its native size, and the Resolution setting is ignored.
- **Request → clamp → applied.** In Windowed mode you **request** a size, and the game
  **clamps** it to fit inside the usable part of the screen — it has to leave room for the
  Windows **title bar** and **taskbar**. The small **"→ applied W×H"** readout next to the
  Resolution dropdown shows the size you **actually got** after clamping. So on a 4K monitor,
  a **4K windowed request shows a smaller applied size** (with some desktop visible around
  the window) — that is **expected, not a bug**. To fill the whole monitor, switch to
  **Borderless** or **Fullscreen**.
- **Resizing via the OS.** If you drag the **window's edge** to resize it yourself, the game
  writes that **new applied size back into the readout** and **re-centres** the window on the
  screen. So the readout always reflects the real current window, whether the size came from
  the dropdown or from you dragging the border.

**Now test it.** In **Settings → Window Mode = Windowed**, pick a **Resolution at or above
your monitor size** (e.g. 4K on a 4K/1440p monitor). Look at the row next to the Resolution
dropdown, then also try **dragging the window's edge** to resize it.

**Expected**

- A small **"→ applied W×H"** readout appears next to Resolution showing the size the window
  was actually given (it will be **smaller** than the request so the title bar stays
  reachable). Desktop showing **around** the window in this case is **expected**, not a bug —
  switch to **Borderless/Fullscreen** to fill the monitor.
- Dragging the OS window edge updates the **applied W×H** readout to the new size and
  re-centres the window.

- [ ] **This item works as expected.**

**Tester comments:** _Enter the requested vs applied sizes shown (and the size after any drag-resize)._

---

# Part II — Promotion-validation content (Map 950)

**Skipped in this rerun — passed in v0.2.6.** Part II (§2.1 skill cap / weapon selection and
§2.2 grinding and stat caps) is **not retested** in v0.2.7. If you notice a content problem
on Map 950 while doing §1.5, record it in §3.1.

---

# Part III — Regression and logs

## 3.1 Quick regression

Play a few turns on any map: move, attack, use an item, end the turn, open/close each menu.
Report anything that regressed versus normal play. (The full v0.2.6 regression pass already
passed — this is just a light sanity check while you run Part I.)

- [ ] **No regressions noticed.**

**Tester comments:** _Enter comments here._

## 3.2 Return the log — it lives in your Windows user-data folder

**We need the log back this time** (it was missed on the last few returns). Note: the earlier
guidance that said the log sits **next to the .exe** (via a `._sc_` marker) was **wrong** — an
exported Godot build ignores that marker, so the log is written to your Windows **user-data
folder** under `%APPDATA%`, not beside the game.

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

Thank you. Part I is the gate that closes the display/input work; §3.2 (returning the log)
is the single most-requested item — please don't skip it.
