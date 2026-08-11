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

- [ ] `Project_Prometheus_v0.6.0_debug.exe` matches `SHA256SUMS.txt`.
- [ ] Main Menu shows `v0.6.0`; startup BUILD STAMP matches `BUILD_INFO.json`.
- [ ] Import the bundled `two-map-skirmish-1.0.zip` successfully.
- [ ] Import the bundled `branching-skirmish-1.0.zip` successfully.

---

## A. [VIEWPORT] Expand model, anchoring, and Viewport Scale

Run on as many of these as you have: **16:9 desktop, 16:10 (Steam-Deck-ish), ultrawide, and
web** if built. Screenshot HUD / a centred menu / the tactical map on each.

### A1. No letterboxing / expand behaves

- [ ] No black bars on any window aspect (16:10, ultrawide, resized) — the view fills the window.
- [ ] On a non-16:9 window the map shows MORE tiles along the wider axis, not the same view
      stretched.
- [ ] Free-drag the window to several sizes/aspects: the window keeps whatever size you set (no
      snap back to 16:9), and it never grows past the screen so the title bar stays reachable.

### A2. Viewport Scale setting (NEW — Settings › Display)

- [ ] A **Viewport Scale** slider is present, defaulting to a value that reproduces the pre-v0.6
      view (≈1.5x on 1080p, 2.0x on 1440p — i.e. the game looks unchanged on first launch).
- [ ] Dragging it LOWER shows more, smaller tiles; HIGHER shows fewer, larger tiles. The label
      updates live and the change applies on release.
- [ ] The chosen value persists across a relaunch.
- [ ] At the LOWEST factor (0.5) on the smallest window, the HUD is still legible and menus
      still fit (design floor: everything must be playable down to a 1280×720 reference).

### A3. Menu / modal centring at every scale

Open Settings, Unit Details, a Map Menu, Results, and a contextual Action Menu.

- [ ] Every centred menu is actually centred, at Menu Scale 0.5, 1.0, and 2.0 AND at low/high
      Viewport Scale — no menu drifts off-centre or off-screen.
- [ ] Menus keep the SAME on-screen size when you change Viewport Scale (menu scale is
      reconciled against, not multiplied by, the global factor).
- [ ] Resize the window while a menu is open — it stays centred (no lag, no one-frame jump).
- [ ] A scroll-panel menu (e.g. Unit Details at 2.0) fits and scrolls on a small window.

### A4. Pixel / motion

- [ ] Move a unit across the map: no per-sprite motion shimmer (`snap_2d_transforms_to_pixel`).
- [ ] Text is crisp at the default Viewport Scale; note any blur at non-default factors × zoom.

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

### B2. On-screen (grid) text entry

- [ ] The on-screen keyboard appears when a constrained text field gains focus.
- [ ] Leaving the field (click elsewhere or Tab) WITHDRAWS the keyboard — it does not stay
      floating over the dialog.
- [ ] Characters chosen on the grid appear in the target field (not just the overlay).
- [ ] The space key renders as a visible, labelled key (not a blank button).
- [ ] A character the field rejects renders disabled with an explanatory tooltip.

---

## Carry-forward — MUST carry all five (from `playtest_v0.6.0_carryforward_2026-07-29.md`)

These slipped through v0.5.6/5.7/5.8. Rows 1–2 can ONLY be satisfied by returning the log
bundle; on-screen prompts looking right is NOT evidence.

### [CARRY] 1. Controller hot-plug telemetry (needs the log bundle)

Sequence: connect → use controller → disconnect → use keyboard → reconnect → use controller.

- [ ] Prompts switch keyboard → controller → keyboard → controller.
- [ ] The log records EVERY transition: `connected=true`, then `connected=false`, then
      `connected=true`.
- [ ] Disconnect records retain controller name/GUID; no stale active-pad state survives.

### [CARRY] 2. Logging / telemetry presence (needs the log bundle)

Inspected in `godot.log` (+ rotated logs) and the user-data dir — nothing to see on screen.

- [ ] No `[V030 TRACE]` lines anywhere in the log, and no v0.3.0 resize-trace file on disk.
- [ ] BUILD STAMP, runtime environment, `PLAYTEST CONTEXT`, and controller telemetry all
      present in the log.

### [CARRY] 3. Cancel / Escape ownership

Covered by §B1 above — record the same result here so the carry-forward is formally closed.

- [ ] First Escape drops focus (dialog open); second Escape closes. (See §B1.)
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

- [ ] Ordinary load activates the saved catalogue with no false missing-item error.
- [ ] Import the pack, make a save, fully close the game, MOVE (don't delete) the package folder
      above to the desktop, restart, load that save: it fails with a clear missing-package
      message and does NOT partially restore; shipped content stays usable.
- [ ] Move the folder back, restart, confirm the save loads normally again.

### [CARRY] 5. Retry-after-Save + controller navigation (regression only)

Already passed in v0.5.6; re-run as a regression check on the restructured `MapResultsScreen`. A
failure reopens B4, it does not block this build.

- [ ] Retry stays available and warns that the advanced save remains; Cancel leaves Results
      unchanged; Confirm returns through Prep to the just-completed map at round zero.
- [ ] Loading the earlier saved timeline still resumes the advanced successor; winning the
      retried map advances exactly once.
- [ ] Results, Defeat, Rewind, Prep, FileDialogs, and dropdowns move exactly ONE item per
      controller press, with no focus left behind a modal. Include the successor-dropdown case
      (navigation stays inside the dropdown until it closes) — that one failed in v0.5.6.

---

## What to return

1. This checklist, completed.
2. **The log bundle** — current `godot.log`, all rotated timestamped logs, and a note whether a
   v0.3.0 resize-trace file exists in the user-data dir. Rows 1–2 above are worthless without it.
3. Screenshots for §A (each aspect: HUD, a centred menu, the map) and any defect.
4. The `escape_consumed_by` value from §B1.
