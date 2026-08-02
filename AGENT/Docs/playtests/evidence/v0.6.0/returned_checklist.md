# v0.6.0 Windows Verification Checklist

**Status:** Ready after bundle metadata is filled
**Date:** 2026-08-01
**Return this completed checklist, ALL Godot logs (current + rotated), and screenshots together.**

v0.6.0 is a **combined visual-validation build** for two feature sets that are code-complete
and headless-green but need a real Windows visual/input pass the container cannot run:

- **Viewport expand + anchoring** (`IMPL-VIEWPORT-ANCHORING`) — the display now expands to fill
  the window (a bigger display shows more map tiles), menus are anchor-centred, and there is a
  new **Viewport Scale** setting.
- **Text entry + FileDialog Escape** (`IMPL-FILEDIALOG-ESCAPE-TEXTINPUT`) — constrained
  on-screen text entry and the first-Escape-drops-focus fix.

Report each finding against its branch tag ([VIEWPORT] / [TEXTENTRY] / [CARRY]) so a defect is
traceable. A failure in one area does not block the other — they merge back independently.

**Two build-specific watch items** (not bugs, confirm they look acceptable):
- Menu/HUD scale is now a *product* of the global factor and any zoom; at non-default factors,
  check text stays crisp (no blur) rather than assuming it.
- The HUD scales with the global factor now. At the smallest factor it must stay legible.

---

## Bundle integrity

- [x] `Project_Prometheus_v0.6.0_debug.exe` matches `SHA256SUMS.txt`.
- [x] Main Menu shows `v0.6.0`; startup BUILD STAMP matches `BUILD_INFO.json`.
- [ ] Import the bundled `two-map-skirmish-1.0.zip` successfully.
- [ ] Import the bundled `branching-skirmish-1.0.zip` successfully.

---

## A. [VIEWPORT] Expand model, anchoring, and Viewport Scale

Run on as many of these as you have: **16:9 desktop, 16:10 (Steam-Deck-ish), ultrawide, and
web** if built. Screenshot HUD / a centred menu / the tactical map on each.

### A1. No letterboxing / expand behaves

- [x] No black bars on any window aspect (16:10, ultrawide, resized) — the view fills the window.
- [x] On a non-16:9 window the map shows MORE tiles along the wider axis, not the same view
      stretched.
- [x] Free-drag the window to several sizes/aspects: the window keeps whatever size you set (no
      snap back to 16:9), and it never grows past the screen so the title bar stays reachable.

### A2. Viewport Scale setting (NEW — Settings › Display)

- [x] A **Viewport Scale** slider is present, defaulting to a value that reproduces the pre-v0.6
      view (≈1.5x on 1080p, 2.0x on 1440p — i.e. the game looks unchanged on first launch).
- [ ] Dragging it LOWER shows more, smaller tiles; HIGHER shows fewer, larger tiles. The label
      updates live and the change applies on release.
- [x] The chosen value persists across a relaunch.
- [x] At the LOWEST factor (0.5) on the smallest window, the HUD is still legible and menus
      still fit (design floor: everything must be playable down to a 1280×720 reference).

### A3. Menu / modal centring at every scale

Open Settings, Unit Details, a Map Menu, Results, and a contextual Action Menu.

- [ ] Every centred menu is actually centred, at Menu Scale 0.5, 1.0, and 2.0 AND at low/high
      Viewport Scale — no menu drifts off-centre or off-screen.
- [ ] Menus keep the SAME on-screen size when you change Viewport Scale (menu scale is
      reconciled against, not multiplied by, the global factor).
- [x] Resize the window while a menu is open — it stays centred (no lag, no one-frame jump).
- [x] A scroll-panel menu (e.g. Unit Details at 2.0) fits and scrolls on a small window.

manage campaign screen does not adjust to centered, The open file window is draggable and manually reziable when it doesn't need to be but it does start out centered but doesn't auto adjust to the screen as it moves. When launching the new game screen from an auto set 1440p at 2x viewport and menu scale the background of the new game screen was out of alignment but manually resizing the screen fixed it. large menus easily overflowed the screen at large viewport scaled

The debug label, the turn counter, the unit info hud, and the phase banner all seem to not be responding properly to different window sizes. The reset Hud layout also resets things without accounting for the current window size if the screen is maximised.

The active phase label also remains unreachable.



We need to discuss and potentially redesign this feature, possibly in coordination with the data driven authorable menus. 

My draft idea, don't discuss now but add this plan to a discussion item in the task tracker later. There should be three layers that lay on top of each other but don't interact

base layer - The window
- This is defined by the OS or the browser and is simply how large the canvas we have to work with is.
first layer - The map (holds units and terain)
- map zoom decides how many tiles per inch/pixel are displayed
second layer - Map HUD (objectives)
- aranged by the user in the `Edit HUD Layout menud`
	- each one has its own scale
	- position should not be stored in absolute numbers but rather as a percentage of the hight and width (probably, this might be dumb or hard)
	- eventually these might get a transparency value as well
Third layer - temporary windows (Settings, new game, victory screen)
- Centered menus should define how much size they take up as a percentage of the screen and their borders should stick to that percentage.
- The size of text and buttons should be detirmined solely by the menu scale slider Which will cause some menus or sections of menus to scroll or text to wrap more agressively.
- non centered things such as the combat preview and the action menu should still cap their size at some point and fall back on more agressive text wrapping and scrolling to ensure edge case menus don't get parts pushed off screen.
### A4. Pixel / motion

- [x] Move a unit across the map: no per-sprite motion shimmer (`snap_2d_transforms_to_pixel`).
- [x] Text is crisp at the default Viewport Scale; note any blur at non-default factors × zoom.

Per-sprite motion blur was not noticable right now, but make a note to check back on it once we have actually art.

---

## B. [TEXTENTRY] Text entry and FileDialog Escape

Use the Import/Export dialogs on Campaign Library, Load Game, and New Game (status import).

### B1. FileDialog Escape ownership (the core fix)

- [ ] X / Z and any mapped Confirm/Cancel characters TYPE normally in a filename field.
- [ ] First physical Escape removes filename focus **and focus lands ON THE FILE LIST** (this is
      newly possible; before v0.6 the fix was inert). Dialog stays open.
- [ ] Second physical Escape closes the dialog.
- [ ] **Report the `escape_consumed_by` value from the log** for the first Escape — this tells
      us which of the four Escape stages actually consumed it, so the three redundant stages can
      be deleted on evidence rather than guessed.
`x` and `z` type into the field after using the arrow keys to get in but they don't spawn a moveable cursor and start typing from the beginning of the file name and none of the other keys including `wasd` do anything unless you click the input box or use `tab` to get in there and then a normal text cursor appears. `escape` still closes the entire file dialog. 

### B2. On-screen (grid) text entry

- [ ] The on-screen keyboard appears when a constrained text field gains focus.
- [ ] Leaving the field (click elsewhere or Tab) WITHDRAWS the keyboard — it does not stay
      floating over the dialog.
- [ ] Characters chosen on the grid appear in the target field (not just the overlay).
- [ ] The space key renders as a visible, labelled key (not a blank button).
- [ ] A character the field rejects renders disabled with an explanatory tooltip.
When setting the input to on screen grid, after opening the file selector, trying to do anything other than exit the file selector causes the game to stop responding and then shutdown.


# Playtester comments
I loaded just the branching skirmish without the two map skirmish and there were no units on the first map. The prep screen said I was deploying two units but there were no units of any faction and ending the turn did not prompt the `confirm end even though you still have units` or a victory or defeat screen. Then I loaded the two map skirmish and it did not have any units either. The default maps still had units.

---

## Carry-forward — MUST carry all five (from `playtest_v0.6.0_carryforward_2026-07-29.md`)

These slipped through v0.5.6/5.7/5.8. Rows 1–2 can ONLY be satisfied by returning the log
bundle; on-screen prompts looking right is NOT evidence.

### [CARRY] 1. Controller hot-plug telemetry (needs the log bundle)

Sequence: connect → use controller → disconnect → use keyboard → reconnect → use controller.

- [x] Prompts switch keyboard → controller → keyboard → controller.
- [ ] The log records EVERY transition: `connected=true`, then `connected=false`, then
      `connected=true`.
- [ ] Disconnect records retain controller name/GUID; no stale active-pad state survives.

Xbox controller was connected and disconected multiple times in a session and the prompts changed correctly each time. There was another controler related bug where sometimes after pressing `A` and confirming an attack or confirming the end of turn the joystick and triggers wouldn't do anything and the level up menu didn't show up. tried to replicate after map ended on the same map and nothing happened/

### [CARRY] 2. Logging / telemetry presence (needs the log bundle)

Inspected in `godot.log` (+ rotated logs) and the user-data dir — nothing to see on screen.

- [ ] No `[V030 TRACE]` lines anywhere in the log, and no v0.3.0 resize-trace file on disk.
- [ ] BUILD STAMP, runtime environment, `PLAYTEST CONTEXT`, and controller telemetry all
      present in the log.

### [CARRY] 3. Cancel / Escape ownership

Covered by §B1 above — record the same result here so the carry-forward is formally closed.

- [ ] First Escape drops focus (dialog open); second Escape closes. (See §B1.) 
	- FAILED
- [ ] While a real pad is in hand, note the latent double-bind: `[input]` binds `confirm=joy(1,0)`
      and `cancel=joy(2,1)` (`BACKLOG-INPUTMAP-CONFIRM-CANCEL-DOUBLEBIND-2026-07-24`) — does joypad
      button 1 do anything odd on accept/back?

### [CARRY] 4. Package save validation (give the concrete path)

In `two-map-skirmish-1.0`: the "missing package" half has never been runnable because prior
checklists omitted the folder path. The Windows path is:

```
%APPDATA%\Godot\app_userdata\Fire Emblem RPG\campaign_packs\installed\<package_id>\
```

(Confirm the exact `<package_id>` folder on the test machine.)

- [x] Ordinary load activates the saved catalogue with no false missing-item error.
- [x] Import the pack, make a save, fully close the game, MOVE (don't delete) the package folder
      above to the desktop, restart, load that save: it fails with a clear missing-package
      message and does NOT partially restore; shipped content stays usable.
- [x] Move the folder back, restart, confirm the save loads normally again.

it said "Could not load the campaign save. Progress was not resumed" If that was intended, then things worked well, if that was not intended then it didn't. If in the future it could give a slightly more helpfull error that would be nice.

### [CARRY] 5. Retry-after-Save + controller navigation (regression only)

Already passed in v0.5.6; re-run as a regression check on the restructured `MapResultsScreen`. A
failure reopens B4, it does not block this build.

- [x] Retry stays available and warns that the advanced save remains; Cancel leaves Results
      unchanged; Confirm returns through Prep to the just-completed map at round zero.
- [x] Loading the earlier saved timeline still resumes the advanced successor; winning the
      retried map advances exactly once.
- [x] Results, Defeat, Rewind, Prep, FileDialogs, and dropdowns move exactly ONE item per
      controller press, with no focus left behind a modal. Include the successor-dropdown case
      (navigation stays inside the dropdown until it closes) — that one failed in v0.5.6.

---

## What to return

1. This checklist, completed.
2. **The log bundle** — current `godot.log`, all rotated timestamped logs, and a note whether a
   v0.3.0 resize-trace file exists in the user-data dir. Rows 1–2 above are worthless without it.
3. Screenshots for §A (each aspect: HUD, a centred menu, the map) and any defect.
4. The `escape_consumed_by` value from §B1.
