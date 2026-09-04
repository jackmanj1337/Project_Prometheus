---
Role: dated
Type: playtest
Status: Ready
Last verified: 2026-09-03
---

# v0.7.16 Windows Tester Checklist

**Revision B** checklist form, carried forward. Read Section 0 first — two steps in it
are easy to get wrong in a way that silently invalidates a later section.

**This round is deliberately short, and its most important item is a MEASUREMENT, not a
pass/fail check.** Every defect you reported in v0.7.15 has been fixed except one: the
phase banner. That one could not be fixed, because it does not reproduce anywhere except
on a real Windows machine loading a real save. Section 2 asks you to capture what the
build sees while it happens. **If you only have time for one section, do Section 2.**

Return this completed checklist, every requested screenshot, and the complete Godot log
directory. **Record observed text and behaviour, not only ticks** — the wording of a
dialog is often the thing under test.

## What changed since v0.7.15

- **The campaign now opens on a "Prologue - Drill Yard"**: one enemy, 1 HP, no defences,
  a small map. You asked for Chapter 1 to stop being a full battle before every save
  test. Chapter 1 is unchanged and still sits behind the prologue.
- **Migration v1/v2 packs now load your saves.** Both of the saves you returned were
  driven through the rebuilt fixtures and preview with zero diagnostics.
- **The disabled-save error spam is gone**, and the Load Game dialog now explains a
  migration refusal in words instead of printing a `migration_*` code at you.
- **Nested modals, Compact Settings rows, slider endcaps, the manual-save replacement
  picker and the Prep return** are all fixed but have never been seen on a real display.
  Sections 3-6 are that first look.
- **The phase banner is NOT fixed.** See Section 2.

**Already known, please do not spend time on it:** the slider border art stretches rather
than tiling at very large scales, and Menu Density has no visible effect on the Settings
screen itself.

**Please do NOT re-test** dropdown keyboard/controller operation, Proving Grounds
import/progression, backup and restore, renewal ticking, or suspend/reload HP. All passed
last round and a regression smoke in Section 7 is enough.

---

## Section 0 — Setup you need before starting

### 0.1 Where your files live

Godot user-data directory (saves, settings, and logs):

```
%APPDATA%\Godot\app_userdata\Project Prometheus
```

Paste that into the Explorer address bar. The log directory is the `logs` subfolder
inside it. **Every section below depends on returning that whole `logs` folder.**

### 0.2 How to reach the narrow window size

Section 4 asks for approximately **360 x 640**. You cannot get there from in-game
Settings: the Resolution dropdown's smallest preset is 1280 x 720. Instead:

1. Set Window Mode to **Windowed** in Settings (not Borderless or Fullscreen).
2. Drag the window's left or right border inward until it is roughly 360 px wide, then
   drag the bottom border to roughly 640 px tall.
3. Exact numbers are not required — anything under 600 px wide puts the game in its
   Compact size class, which is what that section tests.

Record the size you actually reached: ______________ x ______________

### 0.3 Keep test files out of the game's folder

Any file you export must be written **outside** the Godot user-data directory. Do not
overwrite the supplied fixture ZIPs in `campaign-packs/`.

### 0.4 Install the campaign pack first

**Do this before Section 2.** Import `campaign-packs/free-roam-proving-grounds.zip`
through Campaign Library. Until a pack is installed, New Game is disabled and reads
"New Game (No Data Packs Installed)", so Sections 2, 3, 5 and 6 cannot run.

There is no pre-install step to preserve this round. Earlier rounds asked you to check
the pre-install button label before importing anything; that check is **not** in this
checklist, and Section 4 does not depend on it. Run the sections in the order they are
numbered.

---

## Section 1 — Build identity

- [ ] The log begins with a BUILD STAMP reading version `0.7.16` and the commit recorded
  in `BUILD_INFO.json`. Record what you see: ______________________________________
- [ ] The executable matches `SHA256SUMS.txt` (`certutil -hashfile
  Project_Prometheus_v0.7.16.exe SHA256`).
- [ ] Windows version, GPU, display resolution, controller model:

  ______________________________________________________________________

---

## Section 2 — Phase banner trace (THE POINT OF THIS ROUND)

You reported that after loading a battle, the blue banner stayed on screen for the whole
player phase, and that at fullscreen it covered only the first third of the window with
its label centred inside that undersized panel.

**The width defect is understood. The one that stays on screen is not**, and it does not
reproduce in any automated environment we have — not headless, not in a browser. So this
build carries instrumentation that prints what the banner is doing, and this section is
you turning it on and reproducing the bug once. **Do not skip a case because the bug did
not appear in it; a case where it did NOT happen is evidence too.**

### 2.1 Turn the trace on

Double-click **`run-with-banner-trace.bat`**, supplied beside the executable in this
bundle. It sets one environment variable and launches the game. Nothing else changes, and
the game is otherwise identical to a normal launch.

If you would rather do it by hand, open Command Prompt in the game folder and run:

```
set PROMETHEUS_BANNER_TRACE=1
Project_Prometheus_v0.7.16.exe
```

- [ ] The log now contains lines beginning `BANNER_TRACE`. If it does not, stop and say
  so — the rest of this section cannot work.

### 2.2 The case that matters: a resumed load

1. Start the Prologue, then Chapter 1, and play until you are a turn or two in.
2. Save, quit to the Main Menu, and **Load** that save.
3. Watch the banner after the map appears. Let the player phase run its full length
   without ending it.

- [ ] Did the blue banner stay visible for the whole player phase?  YES / NO
- [ ] If it stayed: roughly how long, and did it disappear on its own or only when the
  phase ended? ______________________________________________________
- [ ] Screenshot the stuck banner. Name it `banner-resumed-load.png`.

### 2.3 Fullscreen width

4. With the same map open, switch to Fullscreen and trigger a phase change.

- [ ] Screenshot it. Name it `banner-fullscreen.png`.
- [ ] Roughly what fraction of the window width does the banner panel cover?
  ______________

### 2.4 Two cases we need in order to rule things out

5. **Resize during the animation.** Trigger a phase change and drag the window border
   while the banner is sliding.
   - [ ] Does the banner end up in the wrong place, or stay stuck? ______________
6. **Two phases quickly.** End your phase and let the enemy phase start immediately after
   a player phase banner, without waiting for the first to finish.
   - [ ] Does either banner stay on screen? ______________

### 2.5 What to return

- [ ] The **whole `logs` folder** from this session. The `BANNER_TRACE` lines are the
  measurement; the checklist answers above tell us which lines to read.
- [ ] Both screenshots.

**Copy the `logs` folder somewhere safe now, before you carry on to Section 3.** The
game keeps only the **five** most recent log files and deletes the rest, so five more
launches would discard the trace this section exists to capture.

---

## Section 3 — The new prologue

- [ ] New Game → the campaign's first entry reads **"Prologue - Drill Yard"**.
- [ ] It is a small map with **one** enemy.
- [ ] You can reach and defeat that enemy on the **first turn**.
- [ ] Roughly how long did the prologue take, start to victory? ______________
- [ ] "Chapter 1 - First Blood" is still there, after the prologue, and is the full
  battle you remember.

---

## Section 4 — Compact Settings rows and slider rendering

At the ~360 x 640 window from step 0.2. Settings is reachable from the Main Menu, so
it does not matter whether a campaign is loaded or a pack is installed.

- [ ] In Settings at this width, each row puts its **label above its control**, stacked
  vertically — not a label and control squeezed side by side.
- [ ] No label is cut off, and no control is pushed off the right edge.
- [ ] Screenshot it. Name it `compact-settings.png`.
- [ ] Sliders show a visible trough, a filled portion, and rounded end caps at both ends.
- [ ] Screenshot a slider at large scale. Name it `slider.png`.
- [ ] Return to a normal window size: the rows go back to label-beside-control, and
  nothing stays stretched or clipped.

---

## Section 5 — Nested dialogs

- [ ] From the Main Menu open **Load Game**, then open a dialog from inside it (for
  example a delete confirmation).
- [ ] The inner dialog appears **on top** and is the thing that takes your input.
- [ ] Closing the inner dialog returns you to Load Game, still open, with focus back on
  a control you can use with the keyboard.
- [ ] Nothing flickers, and Load Game does not close and reopen underneath.

---

## Section 6 — Manual save replacement, and returning from Prep

- [ ] Save manually into a slot that already has a save. You are asked which save to
  replace, in a picker — not a bare yes/no.
- [ ] Record the exact wording: ______________________________________________
- [ ] Cancelling leaves the existing save untouched.
- [ ] Enter Prep from the campaign map, then back out. You land back on the **campaign
  map**.
- [ ] Enter Prep from a free-roam node revisit, then back out. You land back where you
  came from, not on a different screen.

---

## Section 7 — Regression smoke and migration confirmation

Quick confirmations only. Do not re-test these in depth.

- [ ] Import `campaign-packs/migration-v1.0.0.zip`, then load the save it is for. It
  loads, and the Load Game dialog shows **no raw `migration_*` codes**.
- [ ] Import `migration-v2.0.0.zip` and repeat.
- [ ] If any dialog explains why a save cannot be loaded, record the sentence:

  ______________________________________________________________________

- [ ] Nothing in the log looks like an error storm — a handful of lines is expected, a
  screenful is not. Roughly how many error lines? ______________
- [ ] The free-roam Proving Grounds pack still imports and reaches a map.

---

## Afterwards

Return: this checklist, `banner-resumed-load.png`, `banner-fullscreen.png`,
`compact-settings.png`, `slider.png`, and the complete `logs` folder.

**If Section 2 produced BANNER_TRACE lines, this round did its job even if nothing else
got done.**
