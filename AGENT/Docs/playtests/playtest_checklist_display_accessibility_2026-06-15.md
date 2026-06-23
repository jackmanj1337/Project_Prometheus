# Playtester Checklist — Display & Accessibility (2026-06-15)

**Status:** Pending validation — focused checklist for the Display & Accessibility
features built 2026-06-15. **Last verified:** 2026-06-15

This is a **focused** checklist for one feature area, not a full handbook. Pair it
with the full `playtest_checklist_v0.1.5.0.md` for build setup, controls, and terms.

## Scope / why this needs a human

Everything here is a **visual or input** feature. The dev container is headless and
cannot open a window, so the automated suite covers only the *logic* (zoom math,
settings round-trips, layout apply, the confirm-or-revert countdown). The items below
— what actually appears on screen, scroll/drag feel, fullscreen switching — must be
verified on a **real (non-headless) build**.

## Build

- Source branch: `hud-panel-layout-item4` (stacks Display items 1–4 + the confirm
  dialog on top of `display-accessibility-controls`).
- Source commit: `3633d98`
- No prebuilt `.exe` is bundled with this checklist — export a debug build from the
  branch above, or request one.

## Where the settings live

- **In a map:** press `O` (Settings) or `M` → **Settings** to open the Settings
  screen. The **Edit HUD Layout** button is only enabled here.
- **From the title screen:** Settings is reachable too, but **Edit HUD Layout** is
  disabled there (it needs a live HUD).
- Settings persist to `user://settings.cfg` under a `[display]` / `[gameplay]`
  section. On Windows that's `%APPDATA%\Godot\app_userdata\<project>\settings.cfg`.

---

## Z — Map zoom

### Z1 — Keyboard zoom on a map
Load any map. Press `=` (zoom in), `-` (zoom out), `0` (reset).

**Expected**
- `=` magnifies the map in steps; `-` zooms out in steps; `0` snaps back to the
  default 1× view. Levels are 0.25× / 0.5× / 0.75× / 1× / 1.5× / 2× / 3× / 4×.
- Zoom **re-frames on the cursor's tile** (the tile under the cursor stays roughly
  centred), not the screen centre.

### Z2 — Scroll-wheel zoom
With the mouse over the map, scroll the wheel up and down.

**Expected**
- Wheel up zooms in one level per notch, wheel down zooms out — same levels as Z1.
- A scroll-to-zoom does **not** also move the cursor or trigger a click.

### Z3 — Map Zoom slider in Settings
Open Settings → **Map Zoom** slider. Drag it across its range.

**Expected**
- The label reads the current factor (e.g. `1.5x`). Closing Settings and returning to
  the map shows the map at that zoom.

### Z4 — Persistence
Set a non-default zoom, then **quit and relaunch** the game and load a map.

**Expected**
- The map loads at the last zoom you used (saved across restarts and between maps).

### Z5 — Edge clamp & small-map centring
Zoom in near a map edge; then zoom all the way out (0.25×) on a small map.

**Expected**
- At every zoom the view never shows blank space past the map edge.
- When zoomed out far enough that the whole map is smaller than the screen, the map
  sits **centred**, not pinned to a corner.

### Z6 — Combat preview while zoomed
Zoom to 2× (or 0.5×), then initiate an attack so the **combat forecast** panel appears
beside the defender.

**Expected**
- The forecast panel sits correctly **beside the defender** (not overlapping it or
  floating a tile away) at the current zoom — it tracks the on-screen tile size.

---

## R — Resolution & window mode (with confirm-or-revert)

### R1 — Resolution change shows the confirm dialog
Settings → **Resolution** → pick a different option (e.g. 1600×900).

**Expected**
- The window resizes immediately, and a **"Keep these display settings?"** dialog
  appears with a **15-second countdown** ("Reverting in N seconds…"), a **Keep**
  button, and a **Revert now** button.

### R2 — Keep
On the R1 dialog, click **Keep**.

**Expected**
- The dialog closes and the new resolution stays. Relaunching keeps it.

### R3 — Revert now
Change the resolution again; on the dialog click **Revert now**.

**Expected**
- The window returns to the previous resolution immediately and the Resolution
  dropdown snaps back to the previous option. The change is **not** saved.

### R4 — Auto-revert on timeout
Change the resolution again and **do nothing** — let the countdown run out.

**Expected**
- At 0, the resolution auto-reverts to the previous value (dropdown resets too). This
  is the safety net for a setting that makes the screen unreadable.

### R5 — Window mode (incl. fullscreen) also confirms
Settings → **Window Mode** → try **Fullscreen** and **Borderless**.

**Expected**
- Each mode change applies immediately **and** shows the same confirm dialog (Keep /
  Revert / 15s auto-revert). Fullscreen is the most important case — confirm it
  reverts cleanly if you wait out the timer.

### R6 — Oversized window stays reachable
On a monitor smaller than 1920×1080, in **Windowed** mode pick **1920×1080**.

**Expected**
- The window may be larger than the screen, but its **title bar stays reachable**
  (top-left clamped to the screen origin) — it is not centred off the top of the
  screen.

---

## U — UI scale

### U1 — Scale the whole UI
Settings → **UI Scale** slider (0.75× – 2.0×). Try the extremes.

**Expected**
- The **entire** UI (menus, HUD, Settings panel, text) scales uniformly. At 2×
  everything is large; at 0.75× compact. Applies live.

### U2 — No clipping
At 2× UI scale, open the Settings panel, the unit info panel, and the combat forecast.

**Expected**
- Text grows with its panels — no labels clipped or overflowing their boxes. (This is
  the reason UI scale uses window scaling rather than font-only scaling.)

### U3 — Persistence + composition with map zoom
Set UI scale to 1.5×, set map zoom to 2×, relaunch.

**Expected**
- Both persist. UI scale affects only the GUI; map zoom affects only the map. They
  combine without fighting each other.

---

## H — HUD panel layout (move & scale)

The movable panels are the five persistent readouts: **Phase** label, **Turn** label,
**Unit Info** (bottom-left), **Objective** (top-left), **Terrain** corner
(bottom-right). The contextual menus (action/item/attack-forecast) are **not** movable
by design.

### H1 — Enter the editor
In a map, open Settings (`O`) → **Edit HUD Layout**.

**Expected**
- The screen dims and a draggable frame appears over each of the five panels, with a
  toolbar: **Scale −**, a factor readout, **Scale +**, **Reset**, **Done**, **Cancel**.
- Opening Settings from the **title screen** shows **Edit HUD Layout** greyed out.

### H2 — Drag a panel
Drag the **Unit Info** frame to a new spot.

**Expected**
- The panel follows the drag; the frame tracks it. Release leaves it at the new
  position.

### H3 — Scale a panel
Click a panel's frame to select it (it highlights), then use **Scale +** / **Scale −**.

**Expected**
- That panel grows/shrinks in steps; the factor readout updates. Scale is clamped
  (roughly 0.5× – 2×) so a panel can't vanish or balloon.

### H4 — Done persists
Move/scale a couple of panels, click **Done**. Reload the map (or relaunch).

**Expected**
- The panels keep their new positions/sizes across map reloads and restarts.

### H5 — Cancel and Reset
Re-open the editor: drag a panel, click **Cancel** → it returns to where it was on
open. Re-open, click **Reset** → all panels return to the **authored** layout.

**Expected**
- Cancel discards this session's edits; Reset clears everything back to defaults.

### H6 — On-screen clamp
Try to drag a panel completely off the screen edge.

**Expected**
- It stops with a sliver still visible — a panel can't be lost off-screen.

---

## Notes / known limitations

- **Per-panel scale composes with global UI scale (U):** if UI scale is 1.5× and a
  panel is scaled 2× in the editor, the panel renders at the combined size. Expected.
- **Contextual menus are not movable** in this version (only the five persistent
  readouts). Not a bug.
- The handbook items above were **not** auto-verifiable in the dev container; the
  automated suite covers the underlying logic only. Report anything that looks wrong
  on the real build, with the resolution / UI-scale / zoom values in use.
