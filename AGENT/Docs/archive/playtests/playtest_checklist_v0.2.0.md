> **Historical** — archived 2026-06-23 in the docs reorg (by-type layout). Kept for provenance; not an active doc. See `AGENT/Docs/INDEX.md`.

# Playtester Handbook and Checklist - v0.2.0

This document is written for testers who have not read the design documents or source
code. **Everything needed for this test pass is in this one file** — there is no
separate handbook to read alongside it.

This is a **combined** pass: v0.2.0 is a feature release (a minor-version bump, not just
bug fixes), so it covers both the **new features added since v0.1.5.0** (Part I) and a
**regression pass** over the existing maps and systems (Part II).

## What's new since v0.1.5.0

v0.2.0 bundles everything from the interim v0.1.6.0 build plus a wave of new features:

- **Character-sheet stat breakdown** — the `I` inspect sheet now shows, per stat, the
  personal base + class base + class cap, the effective value (green when raised, red
  when lowered), and a Bonuses list with each source. Pair Up bonuses are visible here.
- **Effective compact stats** — the compact stat block on the `I` sheet now already
  includes Pair Up and other combat-only sources, without opening More Info.
- **On-map Pair Up badge** — a paired lead shows a small `PU` marker on the map.
- **Paired-partner navigation** — the character sheet adds `View Support` / `View Lead`
  to jump between paired units.
- **New Game map selector** — the map dropdown reopens on the last-launched map; rule
  toggles still persist on change.
- **Display & Accessibility controls** — map zoom (0.25×–4×), windowed/fullscreen and
  resolution selection with a 15-second confirm-or-revert safety dialog, global UI scale
  (0.75×–2×), and a per-panel HUD layout editor.
- **Reclass option lines wrap** (no horizontal scrollbar) and **defender Battle Speed is
  shown on no-counter previews** (both carried from v0.1.6.0).
- **F9 all-faction hotseat debug override** (debug builds only).

Part I checks these. Part II re-verifies the maps and systems that did not change.

## Before you begin

### Required build and equipment

- Windows 10 or 11, 64-bit
- Keyboard and mouse
- Executable: `Project_Prometheus_v0.2.0_debug.exe`
- Expected file size: `101,241,976` bytes
- Expected SHA-256:
  `0d73ef80690d929ba2e3d3f3ade6bc7fef6414c2fc8508a1ba3c13db0eac8b7c`
- Build manifest: `AGENT/Docs/playtest_build_v0.2.0.md`

The executable is a standalone debug build. It does not need Godot or an installer. Do
not disable antivirus or other security software to run it. If Windows blocks or
quarantines it, record the exact message and contact the person who supplied the build.

Optional PowerShell integrity check:

```powershell
Get-FileHash .\Project_Prometheus_v0.2.0_debug.exe -Algorithm SHA256
```

The result must match the expected SHA-256 above.

### Tester information

- **Tester name:** _Enter name._
- **Test date:** _Enter date._
- **Windows version:** _Enter version._
- **Primary resolution:** _Enter resolution._
- **Monitor size (if smaller than 1920×1080):** _Enter, for the oversized-window check._
- **Input method:** _Keyboard/mouse or other._
- **Build hash verified:** _Yes / No._

### How to record results

Complete the sections in order. Within each map, checks are grouped so earlier ones set
up later ones; state-changing, map-ending, and Retry checks are placed last so earlier
checks can reuse the same run.

Only check **This item works as expected** after every expectation in that item passes.
Record failures as:

`Map / Unit or UI / Step / Actual / Expected / Repro`

For visual failures, include the window resolution and a screenshot. On Windows,
`Win+Shift+S` opens the Snipping Tool.

If a check cannot be performed, leave it unchecked and write `NOT RUN` with the reason.
Do not check an item merely because no problem was noticed.

If the game crashes or stops accepting input, record the active map, unit, last action,
and visible screen. Close the game, preserve `godot.log`, relaunch the executable, and
continue with the next independent check.

### Controls

| Action | Keyboard / mouse |
|---|---|
| Move cursor or menu selection | `WASD` or arrow keys |
| Confirm / select | `Z`, `Enter`, `Space`, or left-click |
| Cancel / back | `X`, `Esc`, or right-click |
| Next available unit | `Tab` |
| Previous available unit | `Shift+Tab` |
| Open or close Map Menu | `M` |
| Open Settings directly | `O` |
| Inspect the unit under the cursor | `I` |
| Open or cycle More Info | `F` |
| Toggle danger/threat overlay | `Q` or middle-click |
| Zoom map in / out | `=` / `-`, or mouse wheel up / down |
| Reset map zoom to 1× | `0` |
| Toggle Force Level Up debug aid | `F10` |
| Toggle Growth Boost debug aid | `F11` |
| Toggle all-faction hotseat override (debug) | `F9` |

Settings contains a read-only list of most controls. `F`, `F9`, `F10`, and `F11` are
listed here because they are required by this handbook. When `Mouse Cursor` is enabled
in Settings, moving the mouse can also move the map cursor.

### Basic play flow

1. From the Main Menu, choose `New Game`.
2. Choose the requested map and settings, then choose `Start`.
3. Move the cursor onto a Blue unit and Confirm to select it.
4. Move within the highlighted movement area and Confirm a destination.
5. Choose an action such as `Attack`, `Item`, `Pair Up`, or `Wait`.
6. For an attack, choose a target, review the forecast, and Confirm again to resolve
   combat. Cancel backs out without committing the attack.
7. To end a phase early, press `M`, choose `End Turn`, and confirm the warning if units
   have not acted.
8. To abandon a run, press `M`, choose `Exit to Main Menu`, and confirm.
9. After Victory or Defeat, `Retry` reloads that map's original starting state.

To identify a named unit, move the cursor over units and read the HUD name. Press `I` to
confirm the unit's name, class, level, stats, skills, and weapon ranks. Unit and enemy
names used below appear exactly as written in the game.

`F10` is a toggle, not a one-use command. While enabled, the HUD debug banner includes
`force-levelup`. Press `F10` again immediately after the requested level-up so later
checks use normal experience.

### Terms used in this handbook

- **Phase:** one faction's opportunity to act. A full turn/round ends after every
  faction in the map's cycle has completed its phase.
- **Blue / Green / Red / Yellow:** faction colors. Blue and Green may be allied, but they
  remain separate factions.
- **Rout:** defeat every unit in the specified opposing faction or alliance.
- **Lead / support:** when two units Pair Up, the lead stays on the map and acts; the
  support is hidden off-map and supplies bonuses.
- **DONE:** the unit has spent its action for the current phase and appears greyed out.
- **Combat preview / forecast:** the panel shown before confirming an attack.
- **HP / Atk / Hit / Crit:** health, attack power, hit chance, and critical-hit chance.
- **Str / Mag / Skl / Spd / Def / Res / Lck:** Strength, Magic, Skill, Speed, Defense,
  Resistance, and Luck.
- **Battle Speed:** the value used to determine follow-up attacks. A unit needs at least
  5 more Battle Speed than its opponent to follow up.
- **`floor(value)`:** round down to the nearest whole number.
- **More Info:** contextual details opened or cycled with `F`.
- **Fixed growth:** deterministic leveling. `Fixed N / 100` shows progress toward that
  stat's next increase.
- **Configured/authored condition:** a victory or defeat rule explicitly set for that
  map. The game must not invent an unlisted Rout condition.
- **One-based coordinates:** the displayed top-left tile is `(1, 1)`, even though
  internal map data starts at zero.
- **Effective (display):** the stat value including combat-only bonuses (e.g. Pair Up)
  that the engine only applies inside a fight but the sheet now shows up front.

## Coverage limits

- The current Map 950 fixture verifies the fifth equipped-skill slot, but it does not
  contain a unit learning a sixth skill. Sixth-skill overflow remains covered by
  automated tests rather than this live pass.
- Current class weapon-rank caps are verified by automated tests. The build does not
  provide a fast live fixture near enough to the A-rank cap to make a manual cap test
  practical.
- The deferred issues near the end are known limitations, not failed checks.
- The whole of **Part I** is visual/input behaviour that automated tests cannot cover in
  the headless build — it needs your eyes on the real window.

---

# Part I — New features in this build

These are the focus of v0.2.0. Map 950 (`Pair Up: On`, `Auto Promote: Off`,
`Leveling Method: Fixed`) is the fastest fixture for the character-sheet checks; the
display/zoom/HUD checks work on any map.

## A. Character sheet stat breakdown

Open with `I` on the unit under the cursor. The compact stat block is always visible;
selecting a stat (click it or cycle with `F`) opens its full breakdown.

### A.1 Compact stats show effective totals (Map 950)

Pair `M950_Hero_SkillCap` as **lead** with `M950_Cavalier` as **support**. On the next
Blue phase, put the cursor on the **Hero** and press `I`.

**Expected**

- The compact stat block shows the **effective** values **including Pair Up** — e.g.
  Strength already reflects the `+3` — **without** opening More Info. The numbers match
  the per-stat breakdown (A.2) and the HUD.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### A.2 Per-stat breakdown (Map 950)

On the Hero's sheet, select **Strength**.

**Expected**

- The breakdown shows `Personal base`, `Class base  +N  (Hero)`, and `Class cap N`.
- **Effective** is shown in **green** (a bonus is raising it).
- **Bonuses** lists `Pair Up  +3  (this combat)` for Strength (and the matching
  `+3 Spd / +2 Skl / +3 Def / +1 Lck` on those stats).

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### A.3 NO_CAP_DEFINED placeholder (Map 950)

After demoting `M950_General` to `Soldier` (the Second Seal flow in B.6 below), press `I`
on that unit and inspect any combat stat.

**Expected**

- The Class cap line reads a loud `NO_CAP_DEFINED` (Soldier is an intentional cap-less
  placeholder). Every non-placeholder class shows a real cap number; uncapped stats
  (MOV/CON/LoS) show `—`.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### A.4 Tonic shows in the breakdown + green (Map 950)

Apply `Strength Tonic` to a unit (see B.4 for the item flow), then press `I` and select
Strength.

**Expected**

- Effective is **green**; Bonuses lists the tonic with its `+4` and remaining duration.
- After four full turns the modifier drops and Effective returns to Base.
- (A **red** Effective for a net debuff is covered by automated tests; verify live only
  if the build exposes a stat-lowering source.)

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## B. Paired-unit visibility & navigation

### B.1 On-map `PU` badge (any map, `Pair Up: On`)

Pair two units. Look at the **lead** on the map.

**Expected**

- A small yellow `PU` badge sits at the lead's upper-right corner. The support is hidden
  off-map (it has no badge of its own). The badge reads clearly over common map
  backgrounds and faction tints.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### B.2 Badge tracks pairing changes

Separate the pair, then re-pair; then create a pair and **Swap** roles.

**Expected**

- The badge disappears when unpaired and reappears when paired. After a Swap, the badge
  follows the **new** lead (the unit now on the map).

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### B.3 View Support / View Lead jump

Press `I` on a paired **lead**.

**Expected**

- A **View Support** button appears on the sheet. Clicking it opens the **support
  partner's** sheet, where the button now reads **View Lead** and returns to the lead.
- On an **unpaired** unit, the button is absent.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## C. New Game map selector semantics

### C.1 Rule toggles persist immediately

Main Menu → `New Game`. Toggle a rule (e.g. `Pair Up`), back out to the Main Menu, and
re-open `New Game`.

**Expected**

- The rule toggle keeps the value you set — rule toggles persist on change.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### C.2 Map dropdown reopens on the last-launched map

In `New Game`, pick a map, press `Start`, play briefly, then exit to the Main Menu and
re-open `New Game`. Also try: open `New Game`, change the **Map** dropdown but press
**Back** (not Start), then re-open.

**Expected**

- The **Map** dropdown reopens on the **last configured/launched** map, not the first in
  the list. A map choice only "sticks" once you press `Start`; backing out without Start
  does not change the remembered map.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## D. Map zoom

### D.1 Keyboard zoom

Load any map. Press `=` (in), `-` (out), `0` (reset).

**Expected**

- Steps through `0.25× / 0.5× / 0.75× / 1× / 1.5× / 2× / 3× / 4×`; `0` snaps to 1×.
- Zoom **re-frames on the cursor's tile** (the tile under the cursor stays roughly
  centred), not the screen centre.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### D.2 Scroll-wheel zoom

With the mouse over the map, scroll up/down.

**Expected**

- Wheel up zooms in one level per notch, wheel down out — same levels as D.1. A
  scroll-to-zoom does **not** also move the cursor or trigger a click.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### D.3 Map Zoom slider in Settings

Settings → **Map Zoom** slider; drag across its range.

**Expected**

- The label reads the current factor (e.g. `1.5x`); closing Settings shows the map at
  that zoom.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### D.4 Persistence

Set a non-default zoom, **quit and relaunch**, load a map.

**Expected**

- The map loads at the last zoom used (saved across restarts and between maps).

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### D.5 Edge clamp & small-map centring

Zoom in near a map edge; then zoom all the way out (0.25×) on a small map.

**Expected**

- At every zoom the view never shows blank space past the map edge.
- When the whole map is smaller than the screen, the map sits **centred**, not pinned to
  a corner.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### D.6 Combat preview while zoomed

Zoom to 2× (or 0.5×), then initiate an attack so the **combat forecast** appears beside
the defender.

**Expected**

- The forecast sits correctly **beside the defender** (not overlapping or a tile away) at
  the current zoom — it tracks the on-screen tile size.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## E. Resolution & window mode (confirm-or-revert)

### E.1 Resolution change shows the confirm dialog

Settings → **Resolution** → pick a different option (e.g. 1600×900).

**Expected**

- The window resizes immediately and a **"Keep these display settings?"** dialog appears
  with a **15-second countdown** ("Reverting in N seconds…"), **Keep**, and **Revert now**.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### E.2 Keep

On the E.1 dialog, click **Keep**.

**Expected**

- The dialog closes and the new resolution stays. Relaunching keeps it.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### E.3 Revert now

Change resolution again; click **Revert now**.

**Expected**

- The window returns to the previous resolution immediately and the dropdown snaps back.
  The change is **not** saved.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### E.4 Auto-revert on timeout

Change resolution again and **do nothing** — let the countdown run out.

**Expected**

- At 0, the resolution auto-reverts (dropdown resets too). This is the safety net for a
  setting that makes the screen unreadable.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### E.5 Window mode (incl. fullscreen) also confirms

Settings → **Window Mode** → try **Fullscreen** and **Borderless**.

**Expected**

- Each change applies immediately **and** shows the same confirm dialog (Keep / Revert /
  15s auto-revert). Confirm Fullscreen reverts cleanly if you wait out the timer.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### E.6 Oversized window stays reachable

On a monitor smaller than 1920×1080, in **Windowed** mode pick **1920×1080**.

**Expected**

- The window may be larger than the screen, but its **title bar stays reachable**
  (top-left clamped to the screen origin) — not centred off the top of the screen.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## F. UI scale

### F.1 Scale the whole UI

Settings → **UI Scale** slider (0.75× – 2.0×). Try the extremes.

**Expected**

- The **entire** UI (menus, HUD, Settings panel, text) scales uniformly and applies live.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### F.2 No clipping

At 2× UI scale, open the Settings panel, the unit info panel, and the combat forecast.

**Expected**

- Text grows with its panels — no labels clipped or overflowing.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### F.3 Persistence + composition with map zoom

Set UI scale to 1.5×, map zoom to 2×, relaunch.

**Expected**

- Both persist. UI scale affects only the GUI; map zoom only the map. They combine
  without fighting each other.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## G. HUD panel layout (move & scale)

The movable panels are the five persistent readouts: **Phase** label, **Turn** label,
**Unit Info** (bottom-left), **Objective** (top-left), **Terrain** corner (bottom-right).
Contextual menus (action/item/attack-forecast) are **not** movable by design.

### G.1 Enter the editor

In a map, Settings (`O`) → **Edit HUD Layout**.

**Expected**

- The screen dims; a draggable frame appears over each of the five panels, with a
  toolbar: **Scale −**, a factor readout, **Scale +**, **Reset**, **Done**, **Cancel**.
- Opening Settings from the **title screen** shows **Edit HUD Layout** greyed out.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### G.2 Drag a panel

Drag the **Unit Info** frame to a new spot.

**Expected**

- The panel follows the drag; release leaves it at the new position.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### G.3 Scale a panel

Click a panel's frame to select it (it highlights), then use **Scale +** / **Scale −**.

**Expected**

- That panel grows/shrinks in steps; the readout updates. Scale is clamped (~0.5× – 2×)
  so a panel can't vanish or balloon.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### G.4 Done persists

Move/scale a couple of panels, click **Done**, reload the map (or relaunch).

**Expected**

- The panels keep their new positions/sizes across reloads and restarts.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### G.5 Cancel and Reset

Re-open the editor: drag a panel, click **Cancel** → it returns to where it was on open.
Re-open, click **Reset** → all panels return to the **authored** layout.

**Expected**

- Cancel discards this session's edits; Reset clears everything back to defaults.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### G.6 On-screen clamp

Try to drag a panel completely off the screen edge.

**Expected**

- It stops with a sliver still visible — a panel can't be lost off-screen.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## H. F9 debug hotseat override (debug build only)

A debug aid for testing AI maps by hand. It only functions in this debug build.

### H.1 Toggle all factions to hotseat mid-game

On a map with AI (e.g. Map 001), during your Blue phase press `F9`.

**Expected**

- The HUD debug banner shows `hotseat-all`. When the enemy (Red) phase begins, **you**
  control Red units through the normal cursor/menus instead of the AI.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### H.2 Toggle F9 off during an AI-owned phase

While `hotseat-all` is on and it is Red's phase (you are controlling Red), press `F9`.

**Expected**

- The banner drops `hotseat-all`. Any half-open menu, in-progress selection, or attack
  preview is backed out cleanly, and **Red resumes under its normal AI** for the rest of
  the phase — no stuck cursor, no half-moved unit.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### H.3 Repeated toggling does not break the phase

During a single enemy phase, toggle `F9` on/off a few times.

**Expected**

- Control switches between you and the AI each time without the phase ending early,
  freezing, or skipping back to Blue prematurely.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

---

# Part II — Regression pass (existing maps & systems)

These re-verify behaviour that did not change in v0.2.0. If you are short on time, Part I
is the priority; but a feature build can still regress old systems, so run these too.

## 1. Non-map-specific UI commentary

Complete these before launching the first map.

### 1.1 Version label

Open the executable.

**Expected**

- The Main Menu opens without an engine error.
- A small grey `v0.2.0` label appears at the bottom-right.
- A missing or different version means the tester has a stale build.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 1.2 New Game options and remembered values

Open New Game and confirm the `Map`, `Pair Up`, `Auto Promote`, and `Leveling Method`
controls are present. Change `Pair Up` and `Auto Promote`, close the panel, and reopen
it. (This overlaps Part I §C — record any discrepancy there.)

**Expected**

- All expected controls are present.
- The changed values are remembered after closing and reopening the panel.
- Leave `Pair Up: On` and `Auto Promote: Off` for the first map pass.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 1.3 Settings round-trip

Open Settings, change `mouse_cursor`, back out, and reopen Settings.

**Expected**

- The changed value persists.
- Backing out and reopening does not leave the menu stuck or visually corrupt.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 1.4 Mouse wheel does not affect the background

Open New Game. Hover over the title, every dropdown, and empty panel space. Scroll up and
down five times in each location, then close the panel.

**Expected**

- The New Game panel does not scroll.
- The title-screen background or camera does not drift.
- Closing New Game returns to the same Main Menu view.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 1.5 New Game panel centering

Check the New Game panel at `1280x720`. If resizing is available, check it again at
another resolution.

**Expected**

- The panel has visually equal left and right margins.
- The `New Game` heading is centered.
- The panel remains centered after the viewport width changes.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### General non-map UI comments

_Enter comments about menu readability, wording, focus, or navigation that do not belong
to a specific check._

---

## 2. Map 001 - Rout

Use `Map 001 - Rout` for baseline map UI, combat preview, Pair Up flow, and authored Rout
defeat. Keep `Pair Up: On`.

### 2.1 Launch and one-based terrain coordinates

Launch the map through New Game. Move the cursor to the upper-left map tile, then one tile
to the right.

**Expected**

- The normal default campaign roster loads.
- The Terrain panel shows `Tile (1, 1)` at the upper-left tile.
- One tile to the right shows `Tile (2, 1)`.
- Terrain name, defense, and dodge remain readable.
- The display never exposes internal zero-based coordinates such as `Tile (0, 0)`.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 2.2 Movement cancel restores unit and cursor

Select a Blue unit, confirm a legal move, and wait for the Action Menu. Press Cancel (`X`,
`Esc`, or right-click).

**Expected**

- The unit returns to its original tile.
- The cursor returns to the same original tile.
- The movement overlay reappears for another destination choice.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 2.3 Terrain More Info layout

Hover terrain and open More Info. Check at least one terrain entry with a long
description, movement costs, and action text. Close More Info afterward.

**Expected**

- The compact Terrain panel stays at the bottom-right.
- A separate details box opens above it.
- The details box has a bounded height and scrolls instead of growing off-screen.
- The details box does not cover the compact terrain stats.
- Closing More Info removes only the details box.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 2.4 Combat preview base layout and no-counter state

Open a combat preview against an enemy that can counter. Then preview an enemy that cannot
counter (an Archer attacking a melee-only enemy from two tiles away).

**Expected**

- The panel sizes to its content instead of stretching vertically.
- Both sides show readable Name, HP, Damage, Hit, and Crit information.
- The forecast is populated rather than blank.
- `No counter` remains visible when appropriate.
- Unused defender Hit and Crit rows collapse without blank space or overlap.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 2.5 Combat preview More Info and narrow resolution

Open a combat preview and cycle More Info. Use a sword-vs-lance (or lance-vs-sword)
matchup for the triangle. If no effective weapon is available, write `NOT AVAILABLE` for
that substep. Repeat at `960x540` if window resizing is available.

**Expected**

- The base forecast remains visible while More Info is open.
- Description, triangle, effectiveness, crit, and Vantage rows do not overlap.
- Every visible row remains readable and on-screen.
- At `960x540`, the preview stays bounded and does not expand to nearly the full viewport
  height.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 2.6 Pair creation, DONE state, and hidden-support handling

Move a Blue unit next to an unpaired Blue ally. Choose `Pair Up`, target the ally, then
cycle through available units. Finish every remaining Blue unit's action.

**Expected**

- Same-faction Pair Up is available.
- The support sprite leaves the map and the lead remains on its tile (and shows the `PU`
  badge — Part I §B.1).
- Both units become DONE/greyed.
- Unit cycling never selects the support's off-map position.
- The hidden support is not counted as waiting, so the phase ends normally when all
  visible Blue units are done.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 2.7 Swap costs the action

On the next Blue phase, select the paired lead and choose `Swap`.

**Expected**

- Lead and support roles trade places.
- The new lead remains on the original map tile.
- Both units become DONE.
- The pairing remains valid after the action.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 2.8 Authored allied Rout defeat

Do this last because it ends the run. Allow every allied unit to be defeated.

**Expected**

- A defeat screen appears because Map 001 explicitly authors allied Rout defeat.
- The game does not remain on an unwinnable map.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

---

## 3. Map 002 - Seize

Use one run for all three checks. Do not Seize until every Red unit has been defeated. The
Seize point is the throne at displayed coordinate `(16, 3)`; the boss begins on it. Move
the Cavalier and one other Blue unit toward the throne while fighting so both eligibility
checks fit within the turn limit.

### 3.1 Routing Red does not win

Defeat every Red unit without using Seize.

**Expected**

- The map remains active.
- No victory screen appears.
- Hostile Rout is not configured as a Blue victory condition.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 3.2 Seize eligibility is unit-specific

After defeating Red, move a Blue unit other than the Cavalier onto `(16, 3)` and open the
Action Menu. Cancel the Action Menu to undo that move. Then move the default Cavalier onto
the same tile.

**Expected**

- The non-Cavalier is not offered `Seize`.
- The Cavalier is offered `Seize`.
- Only the configured eligible unit can complete the objective.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 3.3 Seize resolves the map

After the Red units are defeated, move the eligible Cavalier onto the Seize tile and
choose `Seize`.

**Expected**

- The victory screen appears immediately.
- The objective does not require another End Turn.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

---

## 4. Map 003 - Defeat Boss

This map is won by defeating the named boss, not by routing every enemy. The boss is
`Bandit Chief`, who begins near the right side of the map. Use the HUD name or `I` to
identify him.

### 4.1 Boss defeat wins while another enemy remains

Keep at least one non-boss Red unit alive. Defeat `Bandit Chief`.

**Expected**

- Victory appears immediately when the boss is defeated.
- The remaining non-boss enemy does not need to be defeated.
- The map does not require another End Turn.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 4.2 Protected Cavalier death causes defeat

Choose `Retry` after the victory, or relaunch Map 003. Allow the default Cavalier to be
defeated while `Bandit Chief` is still alive.

**Expected**

- Defeat appears immediately because the Cavalier is the protected unit.
- The game does not remain on an unwinnable map.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

---

## 5. Map 004 - Escape

Three short runs, because each objective branch ends or invalidates the others. The Escape
tiles are the three right-edge tiles at displayed coordinates `(17, 3)`, `(17, 4)`, and
`(17, 5)`.

### 5.1 One required unit escaping is not enough (Run 1)

Launch Map 004. The required units are the default Cavalier and Mercenary. Move one
required unit onto an Escape tile and choose `Escape`.

**Expected**

- That unit is removed from the map and recorded as escaped.
- The map remains active because the other required unit has not escaped.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 5.2 Required-unit death causes immediate defeat (Run 1)

Continue Run 1 and allow the remaining required unit to die.

**Expected**

- The defeat screen appears immediately.
- The map does not remain in an unwinnable state.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 5.3 Paired lead and support escape together (Run 2)

Restart Map 004. Pair the two required units, move the lead onto an Escape tile on the
next Blue phase, and choose `Escape`. Pair Up spends both units' actions, so moving on
that same phase is not expected.

**Expected**

- Both lead and support are removed.
- Both are counted as escaped.
- No off-map support remains as a ghost objective unit.
- The victory screen appears when both requirements are satisfied.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 5.4 Routing Red while a required unit remains does not win (Run 3)

Restart Map 004. Defeat every Red unit while at least one required Escape unit is still on
the map.

**Expected**

- The map remains active.
- No victory screen appears.
- Rout is not inferred on an Escape map.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

---

## 6. Map 005 - Defend

The two Defend tiles are displayed coordinates `(4, 6)` and `(4, 7)`, near the Blue
starting area. Victory requires surviving six complete turns while an allied unit occupies
at least one of those tiles when Turn 7 begins.

### 6.1 Survive six turns while holding a Defend tile

Keep the default Cavalier alive. Place any Blue unit on `(4, 6)` or `(4, 7)` before the
end of Turn 6 and keep that unit there through the remaining faction phase. Use
`M` → `End Turn` to advance when ready.

**Expected**

- No victory appears at the start of Turns 2 through 6.
- The HUD turn number advances once per complete Blue/Red cycle.
- Victory appears when control would return to Blue for Turn 7, provided a living allied
  unit still occupies a Defend tile.
- Defeating Red early does not replace the configured Survive/Defend objective with an
  automatic Rout victory.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

---

## 7. Map 900 - Hotseat Validation

Complete this section in one uninterrupted faction cycle. It covers faction ownership,
controller handoff, turn counting, camera memory, and danger zones. (For the **debug** F9
override, see Part I §H — different feature.)

### 7.1 Blue startup and cross-faction Pair Up restriction

At the start of Blue's phase, confirm the HUD reads `Turn 1`. Move a Blue unit next to a
Green unit and open the Action Menu.

**Expected**

- Blue starts under Player 1 control.
- Blue units are selectable and Green units are not.
- `Pair Up` is not offered between Blue and Green. They are allied, but they belong to
  different factions.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 7.2 Full faction cycle, labels, and handoff

End Blue, play/end Green, and watch Red and Yellow act. Check the HUD and phase banner as
each phase starts.

**Expected**

- Blue: `Blue - Player 1`
- Green: `Green - Player 2`
- Red: `Red Raiders - AI`
- Yellow: `Yellow Rogues - AI`
- A `PHASE` suffix or capitalization difference is acceptable if faction and controller
  ownership agree.
- The HUD remains on `Turn 1` during Green, Red, and Yellow.
- Red and Yellow complete in order without a hang.
- Control returns cleanly to Blue.
- The HUD changes to `Turn 2` only when Blue returns.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 7.3 Green combat preview uses the active side

During Green's phase, use a Green combat unit to target a hostile Red or Yellow unit.

**Expected**

- The normal populated combat preview opens.
- The preview uses Green as the active attacker.
- It does not open a partial More Info panel with missing combat data.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 7.4 Faction-specific camera and danger zone

During Blue's phase, pan to a memorable view before ending the phase. During Green's
phase, move the cursor toward another map edge until the camera pans elsewhere, then press
`Q`. Finish the faction cycle.

**Expected**

- Green's danger overlay shows units hostile to Green, not a stale Blue view.
- Red and Yellow phases do not overwrite the saved player camera views.
- Blue's saved view is restored when Blue control returns.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### General Map 900 comments

_Enter comments about faction readability, controller handoff, AI pacing, or camera
behavior that do not belong to a specific check._

---

## 8. Map 950 - Promotion Validation

First run setup:

- `Pair Up: On`
- `Auto Promote: Off`
- `Leveling Method: Fixed`
- Use the authored 12-unit fixed roster.

Apply the Strength Tonic early. Its four-turn duration can expire while the other checks
are completed. Save the Victory/Retry check for the end of the first run. The final Auto
Promote check requires one restart.

### 8.1 Roster and promoted General skills

Launch Map 950 and inspect `M950_General`, a level-20 promoted Knight-to-General.

**Expected**

- The fixed roster contains 12 units.
- The General has both `bastion` and `iron_wall` equipped.
- Neither skill is missing or only present as an unshown earned skill.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 8.2 Growth and fixed-growth details

Inspect any growing player unit and open More Info for several stat rows. Record at least
one `Fixed N / 100` value. Leave this open until a later Map 950 level-up, then inspect
the same stat again.

**Expected**

- Each stat shows `Base` and `Effective`.
- Each stat shows `Growth N%`.
- Each stat shows `Fixed N / 100`.
- In `growth_fixed` mode, the fixed value advances on level-up and returns to `0` when
  that stat increases.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 8.3 Four Battle Speed does not follow up

Preview `M950_Mage` attacking `M950_E1_Soldier`, `M950_E2_Soldier`, or `M950_E3_Soldier`
without Pair Up or temporary stat modifiers. Open More Info (`F`) and cycle to the
**Damage** field.

**Expected**

- The Damage field's More Info shows each side's **Battle Speed**, the follow-up
  threshold, and who (if anyone) doubles. (Defender Battle Speed now shows even on
  no-counter previews.)
- The Mage's Battle Speed reads 7; the Soldier's reads 3.
- The Mage attacks once, not twice, because a difference of 4 is below the follow-up
  threshold of 5.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 8.4 Strength Tonic modifier and expiration

Use `M950_Mercenary` → Action Menu → Item → `Strength Tonic`. Inspect the Strength row
immediately, then again after four full turns. (Cross-check the new breakdown in Part I
§A.4.)

**Expected immediately**

- The tonic is consumed.
- Strength gains `+4` for `4 turns`.
- The detail panel shows:

```text
Base <N>   Effective <N+4>
Growth <X>%
Fixed <Y> / 100
Modifiers:
  Strength Tonic  +4  (4 turns)
```

**Expected after four turns**

- Effective Strength returns to Base.
- The Strength Tonic modifier line disappears.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 8.5 Pair Up bonuses match preview and live combat

Move `M950_Hero_SkillCap` and `M950_Cavalier` near the same melee target. Before pairing,
record the Hero's forecast and cancel. Pair the Hero as lead with the Cavalier as support.
Advance to the next Blue phase, then preview and complete the same attack. Pair Up spends
both units' actions, so attacking on the pairing phase is not expected.

The support bonus is:

- Flat Cavalier bonus: `+1 Str`, `+1 Def`, `+1 Spd`
- Scaling bonus: `floor(support stat / 4)` for Str, Mag, Skl, Spd, Def, Res, and Lck

With the authored Cavalier stats, the expected contributions are:

```text
Str: +1 + floor(10 / 4) = +3
Def: +1 + floor(10 / 4) = +3
Spd: +1 + floor( 9 / 4) = +3
Skl:      floor( 8 / 4) = +2
Lck:      floor( 4 / 4) = +1
Mag:      floor( 0 / 4) = +0
Res:      floor( 1 / 4) = +0
```

**Expected**

- After pairing, inspect the Hero (the lead): the Pair Up bonus is visible both on the
  unit-info panel and **on the `I` character sheet** (Part I §A) —
  `+3 Str +3 Spd +2 Skl +3 Def +1 Lck`. The support stays off-map.
- The paired forecast improves by the authored support contribution where those stats
  affect combat.
- Preview Atk, Hit, and follow-up calculations reflect the bonuses.
- Live damage matches the preview, except for normal miss or critical RNG.
- A result such as `preview says 12, live fight deals 9` is a failure.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 8.6 Demotion stats, skills, and menu layout

Record `M950_General`'s Strength, Defense, Speed, Skill, Movement, displayed level, and
skills. Use the General's `Second Seal` and choose the tier-1 `Soldier` option.

**Expected**

- The Second Seal is usable and the long option list remains on-screen, with each option
  line **wrapping** rather than producing a horizontal scrollbar.
- Every option is reachable by keyboard or mouse scrolling.
- Option labels use `old +/-delta -> new / cap`.
- Class base contributions are replaced rather than stacked.
- Personal earned gains are preserved.
- Strength, Defense, Speed, Skill, and Movement change by the class-base difference.
- Displayed level resets to 1.
- A class that authors a level-1 skill grants it. **Note:** the placeholder `Soldier`
  intentionally has **no** level-1 skill, so reclassing to Soldier grants none — by
  design. (To see a granted skill, reclass to `Mercenary`, which grants `armsthrift`.)
  The General's previously-earned skills are preserved either way.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 8.7 Promotion item becomes usable at level 20

Select `M950_Lvl19_Merc` before leveling and open the Action Menu. Turn on `F10`, complete
a successful EXP-granting combat against `M950_E1_Soldier`, then turn `F10` off. On the
next turn, open the Action Menu and use the Master Seal.

**Expected before level 20**

- `Item` is hidden because the Master Seal has no legal use yet.

**Expected at level 20**

- `Item` appears on the next selection.
- The item list shows `Master Seal (1)`.
- Confirming it opens the promotion modal.
- `Hero`, `Sentinel`, and `Bow Knight` are offered.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 8.8 Fifth equipped-skill slot

Before leveling, inspect `M950_Hero_SkillCap`.

**Expected before level 15**

- Equipped skills are `armsthrift`, `patience`, `dash`, and `discipline`.
- One of the five default equipped-skill slots is open.

Use `F10`, complete a successful EXP-granting combat to earn level 15, turn `F10` off, and
inspect the unit again.

**Expected after level 15**

- The level-up screen reports `disarm` learned.
- `disarm` appears with the existing four equipped skills.
- No existing skill is overwritten and no crash occurs.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 8.9 Staff use honors Force Level Up

Use `F10` to enable Force Level Up. Have `M950_Cleric` successfully use a staff, then
disable Force Level Up with `F10`.

**Expected**

- The debug indicator shows Force Level Up while enabled.
- A successful staff use triggers the forced level-up path.
- Disabling the aid removes the active debug state.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 8.10 Retry restores the original class state

Do this last in the first run. After demoting `M950_General` to Soldier, defeat every Red
unit. On the Victory screen, choose `Retry`, then inspect the General. Victory and Defeat
use the same map-start Retry snapshot.

**Expected**

- The unit returns to General at its original displayed level.
- Original stats, weapon ranks, inventory, and skills are restored.
- No Soldier state remains.
- The error log does not report a snapshot rejection or `push_error`.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 8.11 Auto Promote at the level cap

Return to New Game, set `Auto Promote: On`, and relaunch Map 950. Use `M950_Lvl19_Merc` to
gain level 20 again. Turn on `F10` before the successful combat and turn it off after the
level-up flow.

**Expected**

- The promotion modal opens immediately after the level-up animation.
- The Master Seal does not need to be selected manually.
- The modal offers `Hero`, `Sentinel`, and `Bow Knight`.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### General Map 950 comments

_Enter comments about progression clarity, class-choice wording, stat-change
presentation, or menu readability that do not belong to a specific check._

---

## 9. All-map error-log check

The Windows executable may not display a separate debug console. After the test pass,
close the game and inspect:

`%APPDATA%\Godot\app_userdata\Fire Emblem RPG\logs\godot.log`

Paste that path into Windows Explorer's address bar. If the file does not exist, record
`LOG FILE NOT FOUND`; that is useful build feedback.

### 9.1 No data-validation errors

**Expected**

No `DataManager: ...` error or `push_error` appears. Examples include:

- `tilemap_scene_path '...' is missing`
- `reward_items item '...' not found`
- `seize condition in group '...' tile (X, Y) is outside the grid`
- `enemy placement ai_profile '...' is not valid`
- `duplicate unit_id '...'`
- `unit '...' hp ... exceeds max_hp ...`
- `snapshot ... is not a Dictionary`

These messages indicate content/configuration defects even if the game does not crash.
Record the complete message and the active map. Also report any line containing `ERROR`,
`SCRIPT ERROR`, or a crash stack trace.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

---

## 10. Known deferred issues

Do not report the unchanged behavior below as a v0.2.0 regression:

- Camera limits do not include viewport-aware overscan for edge panels.
- Mouse-follow camera catch-up remains abrupt.
- Clicking the Map Menu backdrop does not dismiss the menu.
- `Q` toggles the full danger zone; per-enemy threat inspection is not implemented.
- **Weapon names in the combat preview** are not yet shown (planned enhancement).
- **Aura skills** remain placeholders (M9) — they do not contribute to the stat
  breakdown.
- Contextual menus (action/item/forecast) are **not** movable in the HUD layout editor.

Report behavior in these areas only if it is worse than described.

### Deferred-issue comments

_Enter observations here._

---

## 11. What to send back

Return:

1. This completed handbook with every applicable checkbox marked.
2. Tester comments for every failed or unclear item.
3. Error-log output for any validation error.
4. Screenshots for combat-preview, terrain, camera, display/zoom, HUD-layout, or
   menu-layout failures (Part I is visual — screenshots help a lot).
5. Exact repro steps using the failure format at the top of this document.
6. The `godot.log` file, or a note that it was not found.
7. The resolution / UI-scale / zoom values in use when a display issue appears.

---

## 12. About this build — features and roadmap

Context for what you are testing. This is an early tactical-RPG build; names and numbers
are placeholders and will change.

### Implemented and playable now

- **Grid tactical combat** — move and act; terrain affects movement cost, defense, dodge.
- **Combat math** — damage, hit %, crit %, the weapon triangle (sword/lance/axe and the
  magic triangle), effectiveness vs. unit types (flying / armoured / mounted / dragon /
  beast), and follow-up "doubling" by Battle Speed.
- **Weapon proficiency (WEXP)** and rank-gated equipment.
- **EXP and leveling** in two modes — Random growths and Fixed growths.
- **Promotion** (Master Seal) and **Reclass** (Second Seal), with stat and skill changes.
- **Classes and class skills** — a curated set of skills works; many advanced skills are
  placeholders (see "being tested" below).
- **Pair Up** — support stat bonuses (now surfaced on the character sheet and an on-map
  badge), plus the Pair Up / Swap / Separate actions.
- **Items and staves** — healing, stat tonics, consumables; inventory and equip.
- **Objective types** — Rout, Seize, Defeat Boss, Escape, and Defend/Survive, with
  per-faction win/lose conditions authored per map.
- **Multiple factions and 2-player local hotseat**, with AI profiles (basic, stationary,
  and healer) that use real pathfinding.
- **Display & accessibility** — map zoom, windowed/fullscreen and resolution with a
  confirm-or-revert safety dialog, global UI scale, and a per-panel HUD layout editor.
  **(New in v0.2.0.)**
- **HUD and overlays** — combat preview with More Info, terrain info, objective list,
  the danger-zone (threat) overlay, and the comprehensive `I` stat breakdown.
- **Menus** — Main Menu, New Game (per-run rules: Pair Up, Auto Promote, Leveling,
  Permadeath), Settings (audio, movement speed, banners, mouse cursor, display, and
  more), and **Retry** from the map's starting state.

### Being tested / in validation (focus of this build)

- The **new v0.2.0 features** in Part I — character-sheet breakdown, paired-unit
  visibility, New Game map semantics, and the whole Display & Accessibility set.
- **Heads-up:** skills labelled "implement in M9" are **placeholders** — they appear on a
  unit but do nothing in combat yet. Don't test those for effect; their warning lines in
  `godot.log` are expected.

### Future plans (roughly ordered — subject to change)

1. **Full skill content** — make the placeholder skills actually work.
2. **Status conditions** — poison, silence, berserk, and the rest.
3. **Extra-turn system** — Canto (move again after acting), Dancer/refresh, Galeforce.
4. **Content expansion** — more classes, weapons, items, and skills.
5. **Campaign layer** — pre-battle deployment, a shop, recruiting allied units, and a
   suspend-save (between-map save/load).
6. **Laguz / shapeshifters** — deferred until after the campaign layer.
7. **Deeper support system** — Dual Strike / Dual Guard and support conversations —
   deferred.
8. **Online play** — the hotseat foundation is being built to extend to networked play
   (post-1.0).
9. **Platforms** — web playtest channel, Steam Deck verification, and gamepad support.
10. **Pre-1.0 housekeeping** — rename the placeholder (Fire Emblem-derived) names to
    project-owned ones and complete a licensing review.
