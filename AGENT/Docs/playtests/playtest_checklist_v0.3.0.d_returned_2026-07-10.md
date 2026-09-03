---
Role: dated
Type: playtest
Status: Returned results - triaged in `playtest_v0.3.0.d_results_triage_plan_2026-07-10.md`
Last verified: 2026-07-10
---

# Playtester Handbook and Checklist - v0.3.0.d (Focused Rerun)

Returned evidence archived 2026-07-10:
`godot_log_v0.3.0.d_focus_returned_2026-07-10.log`,
`godot_log_v0.3.0.d_display_mrd_returned_2026-07-10.log`, and
`v030d_*_2026-07-10.png` screenshots in `AGENT/Docs/archive/evidence/`.

> **What this build is.** v0.3.0.d is a **focused rerun** of v0.3.0. It is not a
> new feature build. All v0.3.0 recovery fixes are landed; this pass exists to
> confirm those fixes on real hardware and to capture logs for the two holdouts
> that could not be reproduced in automated tests. Use it with
> `playtest_build_v0.3.0.d.md`, which records the exact file size and SHA-256.

This document is written for a tester who has not read the design documents or
the source. **Everything needed for this pass is in this one file.** It is
narrow on purpose: do the sections below, keep every log, and return them.

> **Please read — deliberate changes that are NOT bugs.** Do not file these as
> defects; only report if they behave *differently* than described here.
>
> - **This build prints extra diagnostic lines to the log.** You will see lines
>   tagged `V030-NG-FOCUS` and `V030-DSP-TRACE`. These are intentional
>   instrumentation for the two holdouts. **Do not trim them from the log.**
> - **F8 cycles the map overlay look (§5).** F8 is a temporary debug key in this
>   build only, used to compare two overlay treatments. It is not a shipped
>   feature.
> - **A too-large windowed request can show a smaller applied size.** In Windowed
>   mode the game clamps a request larger than your usable screen. Desktop
>   visible around the window is expected.

## Before You Begin

### Required build and equipment

- Windows 10 or 11, 64-bit.
- Keyboard and mouse.
- **A real controller is required** for §1 and §2 (Xbox-layout or Steam Deck
  controls). A second pad, and/or a Nintendo/PlayStation-layout pad, is a bonus
  — it exercises the button-label swapping.
- A monitor you can run in Windowed mode and drag/resize for §4.
- Executable: `Project_Prometheus_v0.3.0.d_debug.exe`.
- Expected file size / SHA-256: `101496496` bytes /
  `cff6a6bcb67c8f7b58471b462d54bc8bfafa115112dea463bce244d5d7627efd`
  (also recorded in `AGENT/Docs/playtests/playtest_build_v0.3.0.d.md`). Verify
  before running.

The executable is a standalone debug build. It needs no Godot install and no
installer. Do not disable antivirus to run it. If Windows blocks it, record the
exact message and contact the person who supplied the build.

Optional PowerShell integrity check (compare against the manifest hash):

```powershell
Get-FileHash .\Project_Prometheus_v0.3.0.d_debug.exe -Algorithm SHA256
```

### Tester information

- **Tester name:** _Enter name._
- **Test date:** _Enter date._
- **Windows version / device:** 11
- **Controller model(s):** Xbox
- **Monitor native resolution / size:** 4k
- **Menu Scale in use:** _Enter (Settings shows it; note it on any visual issue)._
- **Build hash verified:** _Yes / No._

### How to record results

Complete the sections in order. Only check an item after every expectation in
it passes. Record a failure as:

`Map / Unit or UI / Step / Actual / Expected / Repro`

For a visual or focus failure, include the window resolution, the Menu Scale in
use, and a screenshot (`Win+Shift+S`). If a check cannot be performed, leave it
unchecked and write `NOT RUN` with the reason. Do not check an item merely
because nothing was noticed.

### The log is the deliverable

The two holdouts (§2 New Game focus, §4 one-axis drag) already pass in automated
tests, so **the log matters more than a guess.** If either misbehaves, the log
is the evidence — do not paraphrase it.

The log lives in your Windows **user-data folder** under `%APPDATA%`, not beside
the exe:

- Every launch, the game prints a framed **BUILD STAMP** as the first lines of
  the log. It includes a **`log=`** line with the **exact full path** to the log
  file. Copy the path from that line.
- **Typical shape:** `%APPDATA%\Godot\app_userdata\<project>\logs\godot.log`.
  Paste **`%APPDATA%`** into the Windows Explorer address bar, then drill down
  `Godot\app_userdata\<project>\logs\`.
- The log is written **per launch.** If a step tells you to quit and reopen,
  **copy the log first** so you do not overwrite the evidence.

### Required return artifacts

- The whole `godot.log` from **each** launch used below (not just the last one).
- The BUILD STAMP block pasted into your report.
- Screenshots for any visual or focus failure.
- Your controller model(s), Windows version, monitor native resolution, Menu
  Scale, and exact repro steps.

- [x] **BUILD STAMP block pasted and each launch's `godot.log` attached.**

**Tester comments:** === BUILD STAMP ===
version=0.3.0.d  commit=e19ac9b  built_at=2026-07-09T15:55:07Z
started_at=2026-07-10T00:21:01Z
exe=E:/Utilities/ObsidianPortable/Project_Prometheus_v0.3.0.d_debug.exe
user_data_dir=C:/Users/jackm/AppData/Roaming/Godot/app_userdata/Fire Emblem RPG
log=C:/Users/jackm/AppData/Roaming/Godot/app_userdata/Fire Emblem RPG/logs/godot.log
=== END BUILD STAMP ===
=== BUILD STAMP ===
version=0.3.0.d  commit=e19ac9b  built_at=2026-07-09T15:55:07Z
started_at=2026-07-10T00:21:41Z
exe=E:/Utilities/ObsidianPortable/Project_Prometheus_v0.3.0.d_debug.exe
user_data_dir=C:/Users/jackm/AppData/Roaming/Godot/app_userdata/Fire Emblem RPG
log=C:/Users/jackm/AppData/Roaming/Godot/app_userdata/Fire Emblem RPG/logs/godot.log
=== END BUILD STAMP ===

Extra note, the main menu still has `Continue` overlaping with the title when menu scaling is 2x.

---

## 1. Controller Fix Rerun

Use a real controller for this section.

1. Open Settings with **Start -> Settings**.
2. Move down past the visible Settings rows using the d-pad, then again with the
   left stick.
3. Confirm the list scrolls to keep the focused row visible.
4. Open the Action Menu and Unit Details. Hold a direction on the d-pad, then on
   the left stick, long enough to feel the repeat cadence.
5. Use **LT/RT** on the map: a short tap, a light pull, and a full hold.
6. If you have a second pad, connect it. Use each pad and confirm the on-screen
   prompts follow the pad you actually used.

Expected:

- Settings and Unit Details scroll with the focused row.
- Custom menus repeat steadily — not too fast, and never stalling.
- Light trigger contact below a real press does **not** zoom; a deliberate pull
  does.
- Prompt labels follow the last active pad's brand.

- [ ] Controller fixes pass.

Notes: Settings menu scrolls, but could use more padding above and bellow the focus indicator. Also, no repeat behavior was noticed in the settings menu. Joystick was also noticed to be unable to change attack or pair up target but dpad could. trigger zoom is better, but could stand to be less sensitive or have a slower repeat. action menu was good.
## 2. New Game Focus Holdout

This is the live-only holdout. The headless focus chain already passes, so the
log is more important than guessing.

1. Set **Settings -> Input Prompts** to **Auto**.
2. Return to Main Menu and open **New Game**.
3. Using only the controller **d-pad**, press down one step at a time:
   Map -> Permadeath -> Auto Promote -> Leveling -> Pair Up -> Start -> Back.
4. Repeat with the **left stick**, using deliberate taps and full releases.
5. Switch once from keyboard/mouse to controller while New Game is open, then
   repeat the same down-chain.

Expected:

- The focus highlight stays visible on every row.
- One down press moves exactly one row.
- No press disappears into a hidden focus owner or snaps focus back to Start.

If the highlight disappears: **stop immediately**, note the exact row transition,
take a screenshot, and return the `godot.log` containing the `V030-NG-FOCUS`
lines from that launch.

- [ ] New Game focus passes, or the log captures the failure.

Notes: Map to permadeath has an invisible step, but permadeath to promote is working fine. promote to leveling, leveling to pair up, and pair up to start, all still have invisible steps. All behavior repeats regardless of input.

## 3. Suspend And Continue Rerun

Play into a battle, then exercise mid-map suspend/resume with attention to the
2026-07-09 fixes.

1. Start a New Game and enter a map. Move at least one unit to **DONE** (fully
   used), and if possible form a **Pair Up** so there is an off-map support.
2. On the **blue player phase**, use **Suspend & Quit**.
3. Choose **Continue** from the Main Menu.
4. Then quit the game entirely, relaunch, and choose **Continue** again.

Expected:

- Done units resume showing DONE visuals and cannot look falsely ready.
- Pair Up supports stay hidden/off-map after Continue.
- Suspend & Quit is offered **only** on the blue player phase.
- The turn counter restores immediately to the correct value.
- Relaunching after a suspend still offers Continue and resumes correctly.

- [x] Suspend/Continue fixes pass.

Notes: Everything works as described, but can we diagnose why suspend on a red turn caused problems and fix it so that multiplayer games can be saved at any time?

## 4. Display: One-Axis Drag And Persistence

Run this on Windows in **Windowed** mode with Settings open.

1. Pick a known windowed preset such as **1920x1080**.
2. Drag a corner (or two edges) to a clearly custom two-axis size. Confirm the
   readout updates to `client WxH` and the dropdown shows `Custom (WxH)`.
3. Reset to the preset. Now drag **only the right or left edge** so width changes
   much more than height (the picture mainly grows black bars).
4. Reset again if needed. Drag **only the top or bottom edge** so height changes
   much more than width.
5. **Maximize** the Windowed window and confirm the readout says
   `Maximized (WxH)`.
6. Restore/un-maximize and confirm the saved windowed readout returns.
7. Quit the game, relaunch, reopen Settings, and confirm the custom dragged size
   persisted.

Expected:

- Every genuine OS edge drag that changes client size writes a `client WxH`
  value and a matching `Custom (WxH)` dropdown entry — including one-axis drags.
- Maximize shows `Maximized (WxH)` but does **not** persist that size.
- Relaunch returns to the saved custom windowed size.

If a one-axis drag does not update the readout, return the log with the
`V030-DSP-TRACE` lines from that launch.

- [ ] One-axis drag, maximize readout, and relaunch persistence pass, or the log
  captures the failure.

Notes: One axis drag still fails the same as last time. os maximised shows the correct size but does not label it as maximized but just as custom, which is fine. relaunch preserves size

## 5. MRD-7 Shared-Cell Overlay Comparison

Run this on a map with at least one watched enemy and one player unit whose
movement or target range overlaps that watched threat.

1. Use **R3 / Q / middle mouse** over an enemy to add a watched threat and show
   its **"D"** marker.
2. Select a player unit whose movement range overlaps that threat.
3. Press **F8** to cycle `single_layer -> border_through -> stacked`. The log
   prints `MRD shared-cell overlay mode: ...` after each cycle.
4. Repeat once while entering attack / staff / pair-up targeting.

Expected:

- The watched-threat paint and "D" marker stay visible through selection and
  targeting in every mode.
- `border_through` reads as the threat colour with a strong movement/target
  border.
- `stacked` reads as a blended threat + movement/target tile.

**Your call:** tell us which of `border_through` or `stacked` reads more clearly
so we can make it the shipped default. A screenshot of each in the same overlap
situation is ideal.

- [x] MRD-7 presentation picked (name it in the notes), or screenshots/log notes
  explain why neither is acceptable.

Notes (which mode you picked, and why): Border through is ok, single layer is bad, and stacked is ok, but I provided a sketch of what I would like to try. Essentially stacked with a perimeter line going around the entire threat area. We may eventually also try replacing the range indicators with textures such as diagonal lines and threat could be one slant and movement range could be an opposite slant.

## 6. Recorded Requests — Do Not Re-File

These are already tracked. Do **not** log them as new defects unless the
behavior is now *worse* than the original v0.3.0 return:

- Cursor-traced manual pathing is tracked as `[MRD-8]`, deferred with
  perception/fog design.
- Main Menu 2.0x overlap is routed to `UI-INSPECTION`.
- Real-controller sensitivity sliders are `B6-INPUT` backlog, after the default
  LT/RT threshold fix in §1.

---

## Gate Result Summary

Only fill this out after the relevant section passes completely.

- [ ] `VAL-V030-GAMEPAD` can close: §1 controller fixes and §2 New Game focus
  pass on real hardware, or the only remaining issue is fully captured in logs.
- [ ] `VAL-V023-DISPLAY` can close: §4 passes on real Windows hardware —
  one-axis drag, maximize readout, and relaunch persistence.
- [ ] Suspend/Continue can move off pending live validation after §3 passes.
- [ ] MRD-7 shared-cell presentation chosen in §5.

**Overall tester verdict:** _Pass / Pass-with-notes / Fail — one line._

**Return with this handbook:** the completed checkboxes above, the per-launch
`godot.log` files (with `V030-NG-FOCUS` and `V030-DSP-TRACE` lines intact), and
any screenshots.
