# Playtester Handbook and Checklist - v0.2.9

This document is written for testers who have not read the design documents or source
code. **Everything needed for this test pass is in this one file.**

> **What this build is.** v0.2.9 is a **rerun build** that exists to **close the display
> gate**. The v0.2.8 return closed **§1.3 and §1.4** (they passed live) — so the only
> Part I item left is **§1.6 (Windowed sizing)**, and this build fixes the two things you
> flagged there. Everything else from the earlier handbooks is **not** retested (see the
> note just below). Part III is the light regression pointer and the **log request** — the
> log return has worked the last two times, please do it again (§3.2).

> **Already PASSED — not retested in this build:** §1.3 contextual-menu anchoring at zoom
> and §1.4 combat forecast (both passed live in v0.2.8), §1.1 Menu Scale, §1.5 promotion
> picker, §1.2 character sheet, §1.7 terrain paging, **all of Part II** (Map 950
> promotion-validation content), and the full regression pass. Do not re-run these unless
> you happen to notice a regression while doing the checks below — if so, note it in §3.1.

## What changed since v0.2.8 (what you are re-verifying)

Your two v0.2.8 §1.6 reports were reproduced, diagnosed, and fixed. This build asks you
to confirm the fixes **live**:

- **The custom-size readout was confusing (§1.6a).** You noted *"the custom WxH readout
  doesn't seem to be updating live all the time"* and asked for a clearer explanation of
  what is being measured. The cause: the readout was comparing a size you had **already
  been given** (a custom size from dragging the window) against the game's *request* math,
  so it could invent a nonsense second number like `Custom (3840x2071) → applied
  3563x2004`. It now labels a dragged/observed size plainly as **`client WxH`** and never
  runs it back through the request clamp. The **size vocabulary** is spelled out in the
  §1.6 explainer below.
- **The Windows maximize button un-centered the menu (§1.6b).** You reported that using
  the **Windows maximize button** (top-right of the title bar) with the Settings menu open
  made the menu *"do the old thing where it does not stay centered but recenters on
  adjusting the size."* Two fixes: (1) the menu now **re-centers reactively** the instant
  the window finishes resizing, so it stays centered through a maximize with no wiggle;
  and (2) **maximize is now treated as a window state, not a saved resolution** — it no
  longer overwrites your saved Resolution with the maximized size, and **un-maximizing
  restores your chosen windowed size**.

## Before you begin

### Required build and equipment

- Windows 10 or 11, 64-bit
- Keyboard and mouse
- A monitor that can show **1440p or 4K** is useful for §1.6 (otherwise mark the 4K
  sub-checks `NOT RUN`)
- Executable: `Project_Prometheus_v0.2.9_debug.exe`
- Expected file size / SHA-256: _see `AGENT/Docs/playtests/playtest_build_v0.2.9.md`._

The executable is a standalone debug build. It does not need Godot or an installer. Do not
disable antivirus to run it. If Windows blocks it, record the exact message and contact the
person who supplied the build.

Optional PowerShell integrity check (compare against the manifest hash):

```powershell
Get-FileHash .\Project_Prometheus_v0.2.9_debug.exe -Algorithm SHA256
```

### Tester information

- **Tester name:** _Enter name._
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
- **Windowed mode:** a normal titled, movable window (as opposed to Borderless or
  Fullscreen, which fill the monitor). The **Resolution** dropdown only matters here.

---

# Part I — Display rerun (§1.6 only)

The Settings screen is all you need for this part. Open it from the title screen or in a
map with `O`. This is a **rerun of the one item that was still open after v0.2.8** — §1.3
and §1.4 already passed and are not repeated here.

## 1.6 Windowed sizing: size readout + Windows maximize (V028-02 / V028-03)

**Read this first — the size vocabulary (what the numbers next to Resolution mean):**

- **preset request** — a size you pick from the **Resolution** dropdown. It is a
  *request*: in Windowed mode the game **clamps** it to fit your usable screen (leaving
  room for the title bar and taskbar), so the readout shows **`→ applied W×H`** *only when
  the clamp actually changed it*. A 4K windowed request on a 4K monitor showing a smaller
  applied size (desktop visible around the window) is **expected, not a bug** — use
  Borderless/Fullscreen to fill the monitor.
- **client size** — the actual window interior (the game view) the OS gave you. When you
  **drag the window edge** yourself, that new size is already a client size, so the game
  shows it as **`client W×H`** and writes it back into the saved Resolution. It is **not**
  re-run through the request clamp (that was the source of the confusing
  `Custom (3840x2071) → applied 3563x2004` you saw — fixed).
- **native display size** — your monitor's full size, shown as **`native W×H`** while
  Borderless/Fullscreen have the Resolution row grayed out.

**Now test it** (in **Settings → Window Mode = Windowed** unless a step says otherwise):

**(a) Custom-size readout after a drag-resize.** Drag the window's **edge** to a clearly
non-preset size. Watch the **readout** next to Resolution and the **Resolution dropdown**.

**(b) Windows maximize button.** With the **Settings menu open** in Windowed mode, click
the **maximize button** in the top-right of the window title bar. Watch the Settings panel
as it maximizes. Then click the same button again (or the restore button) to **un-maximize**.
For a sharper test, set **Menu Scale to 2.0×** first, then maximize.

**Expected**

- **(a)** After the drag, the readout shows the new size as **`client W×H`** (the real
  interior size), and the **Resolution dropdown shows that size** as a **`Custom (W×H)`**
  entry if it isn't a preset. There is **no** nonsense second "applied" number derived
  from a size you were already given. Picking any preset afterward replaces the `Custom`
  entry. The window stays **where you put it** (no re-centre), and the dragged size
  **persists**: quit and relaunch and the window returns at that size.
- **(b)** The Settings panel **stays centered** the whole time you maximize — **no drift,
  no wiggle, no need to nudge a slider to fix it** (this was the recurring bug). When you
  **un-maximize**, the window returns to your **chosen windowed size**, and the saved
  Resolution is **not** left showing a giant maximized `Custom` value.

- [ ] **This item works as expected.**

**Tester comments:** _Enter the dragged client size + the exact dropdown/readout text (a
screenshot helps), and whether the panel stayed centered through maximize/un-maximize._

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

- [ ] **No regressions noticed.**

**Tester comments:** _Enter comments here._

## 3.2 Return the log — same flow that worked last time

The log return has worked the last two builds — please do exactly the same again. The log
lives in your Windows **user-data folder** under `%APPDATA%`, not beside the exe.

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

Thank you. This one §1.6 check is the last item holding the display gate — a clean Part I
here closes it.
