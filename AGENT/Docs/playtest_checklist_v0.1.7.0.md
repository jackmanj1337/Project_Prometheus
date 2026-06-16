# Playtester Handbook — v0.1.7.0 (combined feature playtest)

**Status:** Pending validation — combined checklist covering **everything added since
the last full playtest (v0.1.5.0)**: the character-sheet stat breakdown, the Display &
Accessibility controls (map zoom, resolution/window mode with confirm-or-revert, UI
scale, HUD panel layout), and the 2026-06-16 playtest-feedback features (effective
compact stats, the on-map Pair Up badge, paired-partner navigation, New Game map
selector semantics, and the F9 debug hotseat override).
**Last verified:** 2026-06-16

This consolidates three previously separate focused checklists into one pass:
`playtest_checklist_v0.1.6.0.md` (character sheet), the
`playtest_checklist_display_accessibility_2026-06-15.md` (Display & Accessibility), and
the 2026-06-16 feedback slice. It supersedes those three for testing the v0.1.7.0 build.

## Scope / why this needs a human

The dev container is headless and cannot open a window, so the automated suite covers
the **logic** only (stat math, settings round-trips, zoom math, layout apply, the
confirm-revert countdown, F9 controller handoff). Everything in this handbook is a
**visual or input** behaviour — what actually appears on screen, scroll/drag feel,
fullscreen switching, colour, on-map markers — and must be verified on the **real
(non-headless) Windows build**.

## Distribution bundle (what the tester needs)

Hand the tester **all three** together — this combined checklist does not repeat the
v0.1.5.0 map-by-map base checks (movement, victory/defeat rules, etc.) that did not
change:

1. `Project_Prometheus_v0.1.7.0_debug.exe` (the build).
2. **This** file (`playtest_checklist_v0.1.7.0.md`) — every new/changed feature.
3. `playtest_checklist_v0.1.5.0.md` — the full handbook: build setup, controls, terms,
   and every map check whose behaviour did not change since v0.1.5.0.

## Build

- Executable: `Project_Prometheus_v0.1.7.0_debug.exe`
- Source commit: `__COMMIT__`
- Expected file size: `101,241,976` bytes
- Expected SHA-256:
  `f8e5015cd0bbaae96071c936cc71196676ba7c65b14fc34e4895fd1fd57200fb`
- Manifest: `AGENT/Docs/playtest_build_v0.1.7.0.md`

Optional PowerShell integrity check:

```powershell
Get-FileHash .\Project_Prometheus_v0.1.7.0_debug.exe -Algorithm SHA256
```

The result must match the expected SHA-256 above.

## New controls since v0.1.5.0

These are in addition to the control table in the v0.1.5.0 handbook.

| Action | Keyboard / mouse |
|---|---|
| Zoom map in / out | `=` / `-`, or mouse wheel up / down |
| Reset map zoom to 1× | `0` |
| Toggle all-faction hotseat override (debug) | `F9` |

`F9`, like `F10`/`F11`, is a debug aid and only does anything in this debug build.

## Tester information

- **Tester name:** _Enter name._
- **Test date:** _Enter date._
- **Windows version:** _Enter version._
- **Primary resolution:** _Enter resolution._
- **Monitor size (if smaller than 1920×1080):** _Enter, for the R6 clamp check._
- **Input method:** _Keyboard/mouse or other._
- **Build hash verified:** _Yes / No._

## How to record results

Complete the sections in order; checks are grouped so earlier ones set up later ones.
Only check **This item works as expected** after every expectation in that item passes.
Record failures as `Map / Unit or UI / Step / Actual / Expected / Repro`. For visual
failures, include the window resolution and a screenshot (`Win+Shift+S`). If a check
cannot be performed, write `NOT RUN` with the reason — do not check an item merely
because no problem was noticed. On a crash, preserve `godot.log`, relaunch, and continue.

---

## A — Character sheet stat breakdown

Open with `I` on the unit under the cursor. The compact stat block is always visible;
selecting a stat (click it or cycle with `F`) opens its full breakdown.

### A1 — Compact stats already show effective totals (Map 950, `Pair Up: On`)
Pair `M950_Hero_SkillCap` as **lead** with `M950_Cavalier` as **support**. On the next
Blue phase, put the cursor on the **Hero** and press `I`.

**Expected**
- The compact stat block shows the **effective** values **including Pair Up** — e.g.
  Strength already reflects the `+3` — **without** opening More Info. The numbers match
  what the per-stat breakdown (A2) and the HUD show.

### A2 — Per-stat breakdown (Map 950)
On the Hero's sheet, select **Strength**.

**Expected**
- The breakdown shows `Personal base`, `Class base  +N  (Hero)`, and `Class cap N`.
- **Effective** is shown in **green** (a bonus is raising it).
- **Bonuses** lists `Pair Up  +3  (this combat)` for Strength (and the matching
  `+3 Spd / +2 Skl / +3 Def / +1 Lck` on those stats).

### A3 — NO_CAP_DEFINED placeholder (Map 950)
After demoting `M950_General` to `Soldier` (Second Seal flow, §8.6 of the v0.1.5.0
handbook), press `I` on that unit and inspect any combat stat.

**Expected**
- The Class cap line reads a loud `NO_CAP_DEFINED` (Soldier is an intentional cap-less
  placeholder). Every non-placeholder class shows a real cap number; uncapped stats
  (MOV/CON/LoS) show `—`.

### A4 — Tonic shows in the breakdown + green (Map 950)
Apply `Strength Tonic` to a unit, then press `I` and select Strength.

**Expected**
- Effective is **green**; Bonuses lists the tonic with its `+4` and remaining duration.
- After four full turns the modifier drops and Effective returns to Base.
- (A **red** Effective for a net debuff is covered by automated tests; verify live only
  if the build exposes a stat-lowering source.)

---

## B — Paired-unit visibility & navigation

### B1 — On-map `PU` badge (Map 950 or any map, `Pair Up: On`)
Pair two units. Look at the **lead** on the map.

**Expected**
- A small yellow `PU` badge sits at the lead's upper-right corner. The support is hidden
  off-map (it has no badge of its own). The badge reads clearly over common map
  backgrounds and faction tints.

### B2 — Badge tracks pairing changes
Separate the pair, then re-pair; then create a pair and **Swap** roles.

**Expected**
- The badge disappears when unpaired and reappears when paired. After a Swap, the badge
  follows the **new** lead (the unit that is now on the map).

### B3 — View Support / View Lead jump (Map 950)
Press `I` on a paired **lead**.

**Expected**
- A **View Support** button appears on the sheet. Clicking it opens the **support
  partner's** sheet, where the button now reads **View Lead** and returns to the lead.
- On an **unpaired** unit, the button is absent.

---

## C — New Game map selector semantics

### C1 — Rule toggles persist immediately
Main Menu → `New Game`. Toggle a rule (e.g. `Pair Up`), back out to the Main Menu, and
re-open `New Game`.

**Expected**
- The rule toggle keeps the value you set — rule toggles persist on change.

### C2 — Map dropdown reopens on the last-launched map
In `New Game`, pick a map, press `Start`, play briefly, then exit to the Main Menu and
re-open `New Game`. Also try: open `New Game`, change the **Map** dropdown but press
**Back** (not Start), then re-open.

**Expected**
- The **Map** dropdown reopens on the **last configured/launched** map, not the first in
  the list. A map choice only "sticks" once you press `Start`; backing out without Start
  does not change the remembered map.

---

## D — Map zoom

### D1 — Keyboard zoom
Load any map. Press `=` (in), `-` (out), `0` (reset).

**Expected**
- Steps through `0.25× / 0.5× / 0.75× / 1× / 1.5× / 2× / 3× / 4×`; `0` snaps to 1×.
- Zoom **re-frames on the cursor's tile** (the tile under the cursor stays roughly
  centred), not the screen centre.

### D2 — Scroll-wheel zoom
With the mouse over the map, scroll up/down.

**Expected**
- Wheel up zooms in one level per notch, wheel down out — same levels as D1. A
  scroll-to-zoom does **not** also move the cursor or trigger a click.

### D3 — Map Zoom slider in Settings
Settings → **Map Zoom** slider; drag across its range.

**Expected**
- The label reads the current factor (e.g. `1.5x`); closing Settings shows the map at
  that zoom.

### D4 — Persistence
Set a non-default zoom, **quit and relaunch**, load a map.

**Expected**
- The map loads at the last zoom used (saved across restarts and between maps).

### D5 — Edge clamp & small-map centring
Zoom in near a map edge; then zoom all the way out (0.25×) on a small map.

**Expected**
- At every zoom the view never shows blank space past the map edge.
- When the whole map is smaller than the screen, the map sits **centred**, not pinned to
  a corner.

### D6 — Combat preview while zoomed
Zoom to 2× (or 0.5×), then initiate an attack so the **combat forecast** appears beside
the defender.

**Expected**
- The forecast sits correctly **beside the defender** (not overlapping or a tile away) at
  the current zoom — it tracks the on-screen tile size.

---

## E — Resolution & window mode (confirm-or-revert)

### E1 — Resolution change shows the confirm dialog
Settings → **Resolution** → pick a different option (e.g. 1600×900).

**Expected**
- The window resizes immediately and a **"Keep these display settings?"** dialog appears
  with a **15-second countdown** ("Reverting in N seconds…"), **Keep**, and **Revert now**.

### E2 — Keep
On the E1 dialog, click **Keep**.

**Expected**
- The dialog closes and the new resolution stays. Relaunching keeps it.

### E3 — Revert now
Change resolution again; click **Revert now**.

**Expected**
- The window returns to the previous resolution immediately and the dropdown snaps back.
  The change is **not** saved.

### E4 — Auto-revert on timeout
Change resolution again and **do nothing** — let the countdown run out.

**Expected**
- At 0, the resolution auto-reverts (dropdown resets too). This is the safety net for a
  setting that makes the screen unreadable.

### E5 — Window mode (incl. fullscreen) also confirms
Settings → **Window Mode** → try **Fullscreen** and **Borderless**.

**Expected**
- Each change applies immediately **and** shows the same confirm dialog (Keep / Revert /
  15s auto-revert). Confirm Fullscreen reverts cleanly if you wait out the timer.

### E6 — Oversized window stays reachable
On a monitor smaller than 1920×1080, in **Windowed** mode pick **1920×1080**.

**Expected**
- The window may be larger than the screen, but its **title bar stays reachable**
  (top-left clamped to the screen origin) — not centred off the top of the screen.

---

## F — UI scale

### F1 — Scale the whole UI
Settings → **UI Scale** slider (0.75× – 2.0×). Try the extremes.

**Expected**
- The **entire** UI (menus, HUD, Settings panel, text) scales uniformly and applies live.

### F2 — No clipping
At 2× UI scale, open the Settings panel, the unit info panel, and the combat forecast.

**Expected**
- Text grows with its panels — no labels clipped or overflowing.

### F3 — Persistence + composition with map zoom
Set UI scale to 1.5×, map zoom to 2×, relaunch.

**Expected**
- Both persist. UI scale affects only the GUI; map zoom only the map. They combine
  without fighting each other.

---

## G — HUD panel layout (move & scale)

The movable panels are the five persistent readouts: **Phase** label, **Turn** label,
**Unit Info** (bottom-left), **Objective** (top-left), **Terrain** corner (bottom-right).
Contextual menus (action/item/attack-forecast) are **not** movable by design.

### G1 — Enter the editor
In a map, Settings (`O`) → **Edit HUD Layout**.

**Expected**
- The screen dims; a draggable frame appears over each of the five panels, with a
  toolbar: **Scale −**, a factor readout, **Scale +**, **Reset**, **Done**, **Cancel**.
- Opening Settings from the **title screen** shows **Edit HUD Layout** greyed out.

### G2 — Drag a panel
Drag the **Unit Info** frame to a new spot.

**Expected**
- The panel follows the drag; release leaves it at the new position.

### G3 — Scale a panel
Click a panel's frame to select it (it highlights), then use **Scale +** / **Scale −**.

**Expected**
- That panel grows/shrinks in steps; the readout updates. Scale is clamped (~0.5× – 2×)
  so a panel can't vanish or balloon.

### G4 — Done persists
Move/scale a couple of panels, click **Done**, reload the map (or relaunch).

**Expected**
- The panels keep their new positions/sizes across reloads and restarts.

### G5 — Cancel and Reset
Re-open the editor: drag a panel, click **Cancel** → it returns to where it was on open.
Re-open, click **Reset** → all panels return to the **authored** layout.

### G6 — On-screen clamp
Try to drag a panel completely off the screen edge.

**Expected**
- It stops with a sliver still visible — a panel can't be lost off-screen.

---

## H — F9 debug hotseat override (debug build only)

This is a **debug aid** for testing AI maps by hand. It only functions in this debug build.

### H1 — Toggle all factions to hotseat mid-game
On a map with AI (e.g. Map 001), during your Blue phase press `F9`.

**Expected**
- The HUD debug banner shows `hotseat-all`. When the enemy (Red) phase begins, **you**
  control Red units through the normal cursor/menus instead of the AI.

### H2 — Toggle F9 off during an AI-owned phase
While `hotseat-all` is on and it is Red's phase (you are controlling Red), press `F9` again.

**Expected**
- The banner drops `hotseat-all`. Any half-open menu, in-progress selection, or attack
  preview is backed out cleanly, and **Red resumes under its normal AI** for the rest of
  the phase — no stuck cursor, no half-moved unit.

### H3 — Repeated toggling does not break the phase
During a single enemy phase, toggle `F9` on/off a few times.

**Expected**
- Control switches between you and the AI each time without the phase ending early,
  freezing, or skipping back to Blue prematurely.

---

## Unchanged / still deferred

- **2.4 — weapon names in the combat preview.** Enhancement, not implemented; do not
  report as a regression.
- **Aura stat contributions** — aura skills remain M9 stubs (they affect hit/dodge/crit,
  not base stats), so they do not appear in the stat breakdown. By design.
- **Per-panel HUD scale composes with global UI scale (F):** a panel scaled 2× in the
  editor with UI scale 1.5× renders at the combined size. Expected.
- The §10 known-deferred issues from the v0.1.5.0 handbook are unchanged. The base
  map-by-map checks (movement, victory/defeat rules, terrain, Pair Up combat) were
  re-verified passing through v0.1.6.0 and are not repeated here — use the v0.1.5.0
  handbook if you want to re-run them.
