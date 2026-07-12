---
Type: playtest
Status: Returned results - triaged in `playtest_v0.3.1_results_triage_plan_2026-07-12.md`
Last verified: 2026-07-12
---

# Playtester Handbook and Checklist - v0.3.1 (Focused Rerun)

> **What this build is.** v0.3.1 is a **focused rerun** that carries the fixes
> made after the v0.3.0.d live return. It is not a new feature build. The v0.3.0.d
> pass confirmed Suspend & Continue on real hardware but failed the gamepad and
> display gates and rejected the single-layer overlay look. This build exists to
> confirm those specific fixes on real hardware and to pick the shipped overlay
> look. Use it with `playtest_build_v0.3.1.md`, which records the exact file size
> and SHA-256.

This document is written for a tester who has not read the design documents or
the source. **Everything needed for this pass is in this one file.** It is
narrow on purpose: do the sections below, keep every log, and return them.

> **What changed since v0.3.0.d — what you are checking now.**
>
> - **Settings now repeats when you hold a direction** (it only scrolled before).
> - **Rebinding a key while holding a direction no longer scrolls the list.**
> - **New Game focus is now contained** — focus should never jump to a Main Menu
>   button behind the New Game panel.
> - **The left stick now cycles attack / Pair Up targets** (only the d-pad did).
> - **Trigger zoom is less sensitive and repeats more slowly.**
> - **Maximizing now reads `Maximized (WxH)`** instead of `Custom`.
> - **One-axis window edge drags now try to update the readout** (this is the
>   holdout that most needs your log — see §4).
> - **A new overlay look, "stacked + perimeter", is on the F8 cycle** (§5).

> **Please read — deliberate changes that are NOT bugs.** Do not file these as
> defects; only report if they behave *differently* than described here.
>
> - **This build prints extra diagnostic lines to the log.** You will see lines
>   tagged `V030-NG-FOCUS` and `V030-DSP-TRACE`. These are intentional
>   instrumentation for the two holdouts. **Do not trim them from the log.**
> - **F8 cycles the map overlay look (§5).** F8 is a temporary debug key in this
>   build only, used to compare overlay treatments. It is not a shipped feature.
> - **A too-large windowed request can show a smaller applied size.** In Windowed
>   mode the game clamps a request larger than your usable screen. Desktop
>   visible around the window is expected.

## Before You Begin

### Required build and equipment

- Windows 10 or 11, 64-bit.
- Keyboard and mouse.
- **A real controller is required** for §1, §2, and §3 (Xbox-layout or Steam Deck
  controls). A second pad, and/or a Nintendo/PlayStation-layout pad, is a bonus
  — it exercises the button-label swapping.
- A monitor you can run in Windowed mode and drag/resize for §4.
- Executable: `Project_Prometheus_v0.3.1_debug.exe`.
- Expected file size / SHA-256: recorded in
  `AGENT/Docs/playtests/playtest_build_v0.3.1.md`. Verify before running.

The executable is a standalone debug build. It needs no Godot install and no
installer. Do not disable antivirus to run it. If Windows blocks it, record the
exact message and contact the person who supplied the build.

Optional PowerShell integrity check (compare against the manifest hash):

```powershell
Get-FileHash .\Project_Prometheus_v0.3.1_debug.exe -Algorithm SHA256
```

### Tester information

- **Tester name:** Jacob Jackman
- **Test date:** 2026.07.10
- **Windows version / device:** 11
- **Controller model(s):** _Enter (e.g. Xbox Series, DualSense, Switch Pro)._
- **Monitor native resolution / size:** _Enter (for the §4 windowed checks)._
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

The two holdouts (§2 New Game focus, §4 one-axis drag) rely on diagnostics baked
into this build, so **the log matters more than a guess.** If either misbehaves,
the log is the evidence — do not paraphrase it.

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

- [ ] **BUILD STAMP block pasted and each launch's `godot.log` attached.**

**Tester comments:** _Paste the first BUILD STAMP block here._

---

## 1. Controller Menu Fixes

Use a real controller for this section.

1. Open Settings with **Start -> Settings**.
2. **Hold** down on the d-pad, then **hold** down on the left stick, past the
   visible Settings rows. Watch that focus keeps *stepping* on its own while held
   (not just a single move), and the list scrolls to keep the focused row visible.
3. Move left/right on a slider row (e.g. a volume slider) and confirm left/right
   still adjusts the focused control — only up/down should change rows.
4. Go to the keybinding rows. Start rebinding a key, and while the "Press key..."
   prompt is up, **hold a direction**. Confirm the list does **not** scroll while
   you are capturing — the direction should be captured as the new binding, not
   move focus.
5. Open the Action Menu and Unit Details. Hold a direction on the d-pad, then on
   the left stick, long enough to feel the repeat cadence.
6. If you have a second pad, connect it. Use each pad and confirm the on-screen
   prompts follow the pad you actually used.

Expected:

- Held direction **repeats steadily** in Settings, Action Menu, and Unit Details
  — not too fast, and never stalling after the first step.
- Left/right stays with the focused slider/option; only up/down changes rows.
- During a keybind capture, holding a direction does **not** scroll the list.
- Prompt labels follow the last active pad's brand.

- [ ] Controller menu fixes pass.

Notes: The settings menu scrolls, but I would still like some more visual padding above and bellow the focus marker so you can see what you are moving toward. The keybinding buttons go sequentially left right then down as opposed to the straight down the stats do, we dont have to fix that right away but it should at the very least be a note on the ui pass. the repeat on the character sheet and the action menu works but is still a little fast. The character sheet also dosn't scroll like the settings menu does, and it should have the same kind of padding. View Support and view lead also get skipped by the focus selector both on keyboard and game pad. we should also decrease the repeat speed/sensitivity for the map zoom triggers
## 2. New Game Focus Containment

The v0.3.0.d return showed focus escaping from the New Game panel to Main Menu
buttons behind it. This build contains focus inside the panel. The build still
logs `V030-NG-FOCUS` lines, so the log is the evidence if anything slips.

1. Set **Settings -> Input Prompts** to **Auto**.
2. Return to Main Menu and open **New Game**.
3. Using only the controller **d-pad**, press down one step at a time:
   Map -> Permadeath -> Auto Promote -> Leveling -> Pair Up -> Start -> Back.
4. Repeat with the **left stick**, using deliberate taps and full releases.
5. Switch once from keyboard/mouse to controller while New Game is open, then
   repeat the same down-chain.

Expected:

- The focus highlight stays visible on a New Game row on every step.
- Focus **never** lands on a Main Menu button (Continue, New Game, Settings,
  Quit) while the New Game panel is open.
- One down press moves exactly one row.

If the highlight leaves the New Game panel: **stop immediately**, note the exact
row transition, take a screenshot, and return the `godot.log` containing the
`V030-NG-FOCUS` lines from that launch.

- [ ] New Game focus stays contained, or the log captures the failure.

Notes: steps well, but the main selector still moves while selecting from a sub menu.

## 3. Targeting With The Left Stick

The v0.3.0.d return reported the left stick could not change attack / Pair Up
targets, only the d-pad. This build routes stick movement through targeting.

1. Start a New Game and enter a map.
2. Select a unit and choose **Attack** so target selection begins.
3. Cycle targets with the **d-pad** left/right, then with the **left stick**.
   Hold the stick to confirm it steps between targets with a steady repeat.
4. Repeat for **Pair Up** target selection (move a unit next to an ally and
   choose Pair Up).

Expected:

- Both the d-pad and the left stick cycle between valid targets.
- Holding the stick repeats at the same steady cadence as the d-pad, and stops
  when you release to centre.

- [x] Stick target cycling passes for attack and Pair Up.

Notes: game pad works the same as the keyboard, but we should make a note to work on making the selector itself more intuitive

## 4. Display: Maximize, One-Axis Drag, And Persistence

Run this on Windows in **Windowed** mode with Settings open.

1. Pick a known windowed preset such as **1920x1080**.
2. Drag a corner (or two edges) to a clearly custom two-axis size. Confirm the
   readout updates to `client WxH` and the dropdown shows `Custom (WxH)`.
3. Reset to the preset. Now drag **only the right or left edge** so width changes
   much more than height (the picture mainly grows black bars).
4. Reset again if needed. Drag **only the top or bottom edge** so height changes
   much more than width.
5. **Maximize** the Windowed window and confirm the readout says
   `Maximized (WxH)` — not `Custom`.
6. Restore/un-maximize and confirm the saved windowed readout returns.
7. Quit the game, relaunch, reopen Settings, and confirm the custom dragged size
   persisted.

Expected:

- Maximize shows `Maximized (WxH)` (this was the v0.3.0.d miss) but does **not**
  persist that size.
- Every genuine OS edge drag that changes client size writes a `client WxH`
  value and a matching `Custom (WxH)` dropdown entry — **including one-axis
  drags** (this is the holdout still under verification).
- Relaunch returns to the saved custom windowed size.

If a one-axis drag does not update the readout, return the log with the
`V030-DSP-TRACE` lines from that launch. The trace shows whether the resize event
reached the game at all — that is exactly what we need to see.

- [ ] Maximize readout, one-axis drag, and relaunch persistence pass, or the log
  captures the failure.

Notes: maximize works perfectly. Relaunch launches the game back at the size displayed by the custom resolution but does not preserve the black bars.

## 5. MRD-7 Shared-Cell Overlay — Pick The Shipped Look

The v0.3.0.d tester rejected the single-layer look and sketched "stacked fill
plus a perimeter outline around the whole threatened area." That candidate,
**stacked + perimeter**, is now on the F8 cycle. Pick the shipped look.

Run this on a map with at least one watched enemy and one player unit whose
movement or target range overlaps that watched threat.

1. Use **R3 / Q / middle mouse** over an enemy to add a watched threat and show
   its **"D"** marker.
2. Select a player unit whose movement range overlaps that threat.
3. Press **F8** to cycle
   `single_layer -> border_through -> stacked -> stacked_perimeter`. The log
   prints `MRD shared-cell overlay mode: ...` after each cycle.
4. Repeat once while entering attack / staff / pair-up targeting.

Expected:

- The watched-threat paint and "D" marker stay visible through selection and
  targeting in every mode.
- `stacked` reads as a blended threat + movement/target tile.
- `stacked_perimeter` adds a darker outline around the outer edge of the whole
  threatened area, on top of the stacked fill.

**Your call:** tell us whether `stacked_perimeter` reads most clearly and should
be the shipped default (or name another mode). A screenshot of each candidate in
the same overlap situation is ideal.

- [ ] MRD-7 presentation picked (name it in the notes), or screenshots/log notes
  explain why none is acceptable.

Notes (which mode you picked, and why): Can we try to change stacked perimiter to have a dark and bright red strong outline that goes around the special watch list and the entire danger area with both lines showing up over the units and the dark line showing up over the bright line.

## 6. Suspend & Continue — Light Regression Check

Suspend & Continue **passed** on v0.3.0.d hardware. This is only a quick
regression pass; report only if something that worked before is now broken.

1. Enter a map, move a unit to **DONE**, and if possible form a **Pair Up**.
2. On the **blue player phase**, use **Suspend & Quit**, then choose **Continue**.
3. Confirm DONE units still read DONE, Pair Up supports stay hidden/off-map, and
   the turn counter is correct.

- [x] Suspend/Continue still works (or note any regression).

Notes:

## 7. Recorded Requests — Do Not Re-File

These are already tracked. Do **not** log them as new defects unless the
behavior is now *worse* than the original v0.3.0 return:

- Cursor-traced manual pathing is tracked as `[MRD-8]`, deferred with
  perception/fog design.
- Main Menu 2.0x overlap (Continue overlapping the title) is routed to
  `UI-INSPECTION`.
- Real-controller sensitivity sliders are `B6-INPUT` backlog, after the default
  LT/RT threshold change in §1.

---

## Gate Result Summary

Only fill this out after the relevant section passes completely.

- [ ] `VAL-V030-GAMEPAD` can close: §1 menu fixes, §2 New Game focus, and §3
  stick targeting pass on real hardware, or the only remaining issue is fully
  captured in logs.
- [ ] `VAL-V023-DISPLAY` can close: §4 passes on real Windows hardware —
  maximize readout, one-axis drag, and relaunch persistence.
- [ ] MRD-7 shared-cell presentation chosen in §5.
- [x] Suspend/Continue shows no regression (§6).

**Overall tester verdict:** _Pass / Pass-with-notes / Fail — one line._

**Return with this handbook:** the completed checkboxes above, the per-launch
`godot.log` files (with `V030-NG-FOCUS` and `V030-DSP-TRACE` lines intact), and
any screenshots.
