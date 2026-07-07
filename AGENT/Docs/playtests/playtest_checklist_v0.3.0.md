# Playtester Handbook and Checklist - v0.3.0

This is the live-validation checklist for the v0.3.0 feature build. It starts
with the controller items that cannot be proven headless; expand this file when
the final v0.3.0 build contents are locked.

## Before You Begin

Required:

- Windows 10 or 11, 64-bit
- Keyboard and mouse
- A standard Xbox-layout controller or Steam Deck controls
- Executable: `Project_Prometheus_v0.3.0_debug.exe` once the build is cut

Record:

- Tester name:
- Test date:
- Windows version / device:
- Controller model:
- Display resolution:
- Build hash verified:

## Controller Controls Under Test

| Action | Controller |
|---|---|
| Move cursor / menu selection | D-pad or left stick |
| Confirm / select | Pad A |
| Cancel / back | Pad B |
| More Info | Pad X |
| Inspect unit | Pad Y |
| Previous / next available unit | LB / RB |
| Peek range | View / Back hold |
| Map Menu | Start |
| Danger / threat resolver | R3 |
| Zoom out / in | LT / RT hold |
| Zoom reset | L3 |

Debug actions and direct Settings hotkey access are intentionally keyboard-only.
Use **Start → Settings** on controller.

## 1. Controller Mapping Sanity

On a map, use only the controller for this section.

**Expected**

- D-pad and left stick both move the map cursor in the expected directions.
- Pad A selects units, confirms movement, and activates focused menu buttons.
- Pad B backs out of selections/menus without soft-locking.
- Start opens the Map Menu, and Pad B closes it.
- LB/RB cycle through available units.
- Pad Y opens/closes unit details.
- Pad X cycles More Info where the active screen supports it.

- [ ] **This item works as expected.**

**Tester comments:** _Record any button that maps incorrectly or does nothing._

## 2. Left-Stick Feel

Move the map cursor with the left stick for at least 30 seconds. Try light
tilts, full tilts, diagonals, and releasing back to neutral.

**Expected**

- A deliberate tilt moves one tile immediately.
- Holding a direction repeats after a short delay, then continues at a steady
  tile-by-tile cadence.
- Releasing the stick stops movement promptly.
- Diagonals choose one dominant direction and do not jitter between axes.
- The cursor does not drift when the stick is at rest.

- [ ] **This item works as expected.**

**Tester comments:** _Note if deadzone, repeat speed, or diagonal behavior feels wrong._

## 3. Held Trigger Zoom

Use LT/RT to zoom out/in. Try short taps, half pulls, and full holds.

**Expected**

- A trigger press steps zoom once immediately.
- Holding a trigger repeats zoom steps without needing repeated taps.
- A fuller trigger pull feels faster than a light pull, without racing past the
  intended zoom level too easily.
- Zoom clamps cleanly at min/max and does not jitter or reframe unexpectedly.
- L3 resets zoom to 1.0x.

- [ ] **This item works as expected.**

**Tester comments:** _Record the trigger feel, especially if LT/RT are too sensitive._

## 4. Threat / Peek / Menu Comfort

Use R3, View/Back, and Start on a real controller.

**Expected**

- R3 on empty terrain cycles the danger/threat display.
- R3 over a hostile attack-capable enemy toggles that enemy in the watch set.
- Holding View/Back shows the hovered unit's reach; releasing it restores the
  previous overlay.
- Start opens the Map Menu reliably, and controller focus is visible enough to
  choose End Turn / Settings / Quit.
- No overlay or menu text overlaps in a way that blocks the selected tile/unit.

- [ ] **This item works as expected.**

**Tester comments:** _Include screenshots for visual overlap or focus confusion._

## 5. Mixed Input Regression

Switch between controller and keyboard/mouse during one map.

**Expected**

- Keyboard/mouse controls still work after using the controller.
- Controller controls still work after using keyboard/mouse.
- Menus do not receive double inputs from one button press.
- The cursor does not keep moving after switching devices.

- [ ] **This item works as expected.**

**Tester comments:** _Record the last device used before any input lock-up or double action._
