> **Historical** — archived 2026-06-23 in the docs reorg (by-type layout). Kept for provenance; not an active doc. See `AGENT/Docs/INDEX.md`.

# Playtester Handbook and Checklist - v0.2.1

This document is written for testers who have not read the design documents or source
code. **Everything needed for this test pass is in this one file.**

v0.2.1 is a **fix-and-clarity** build on top of v0.2.0. The priority is **Part I**
(verifying the bugs reported last pass are fixed) and **Part II** (the new
character-sheet / More Info surfaces and the menu-scale split). **Part III** rechecks
the touched display controls. If you have time, run the **Part IV** regression pointer
over the existing maps using the v0.2.0 handbook — those systems did not change.

## What changed since v0.2.0

Bugs fixed (these were reported in the v0.2.0 return — please confirm each is gone):

- **Camera zoom jitter** at 3×/4× and a jump when trying to zoom past 4×.
- **Map Zoom slider** in Settings now changes the live map immediately.
- **Combat forecast** no longer overlaps the defender at high/low zoom.
- **F9 hotseat toggling** no longer reactivates units that already acted.
- **Seize objective text** now shows one-based tile coordinates.
- **HUD Reset** no longer misplaces an open Terrain More Info panel.

New / clarified:

- **Menu Scale** is now separate from HUD layout — scaling menus no longer moves the HUD,
  and menus stay centered at every scale.
- **Character sheet:** `Int` is now `Internal Lv`; **CON** and **LoS** rows added; a
  **class summary** section (class, tier, traits, weapons, skills); Pair Up duration reads
  `this combat`.
- **More Info:** **weapons show full stats** (Mt/Hit/Crit/Wt/range/rank/uses); the sheet
  selector is now **navigable by arrow keys / d-pad** with a `▶` highlight.
- **On-map HUD** names the **support partner** of a paired lead.
- **HUD layout editor** affordances: red/yellow panel outlines, `Scale Panel` buttons,
  and sample text that scales with the panel.
- **Map 950** carries a **Debuff Tonic (TEST)** so you can confirm lowered stats show red.

## Before you begin

### Required build and equipment

- Windows 10 or 11, 64-bit
- Keyboard and mouse (a gamepad/d-pad is optional but useful for the new selector check)
- Executable: `Project_Prometheus_v0.2.1_debug.exe`
- Expected file size: _see `AGENT/Docs/playtest_build_v0.2.1.md` (filled at export)._
- Expected SHA-256: _see the build manifest (filled at export)._
- Build manifest: `AGENT/Docs/playtest_build_v0.2.1.md`

The executable is a standalone debug build. It does not need Godot or an installer. Do
not disable antivirus to run it. If Windows blocks it, record the exact message and
contact the person who supplied the build.

Optional PowerShell integrity check (compare against the manifest hash):

```powershell
Get-FileHash .\Project_Prometheus_v0.2.1_debug.exe -Algorithm SHA256
```

### Tester information

- **Tester name:** _Enter name._
- **Test date:** _Enter date._
- **Windows version:** _Enter version._
- **Primary resolution:** _Enter resolution._
- **Monitor size (if smaller than 1920×1080):** _Enter, for the oversized-window check._
- **Input method:** _Keyboard/mouse, gamepad, or both._
- **Build hash verified:** _Yes / No._

### How to record results

Complete the sections in order. Only check **This item works as expected** after every
expectation in that item passes. Record failures as:

`Map / Unit or UI / Step / Actual / Expected / Repro`

For visual failures, include the window resolution and a screenshot (`Win+Shift+S`). If a
check cannot be performed, leave it unchecked and write `NOT RUN` with the reason. Do not
check an item merely because no problem was noticed.

If the game crashes or stops accepting input, record the active map, unit, last action,
and visible screen. Close the game, preserve `godot.log`, relaunch, and continue.

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
| Open or cycle More Info | `F` (forward) |
| Move the More Info selection | arrow keys / d-pad (new in v0.2.1) |
| Toggle danger/threat overlay | `Q` or middle-click |
| Zoom map in / out / reset | `=` / `-` / `0`, or mouse wheel |
| Force Level Up / Growth Boost (debug) | `F10` / `F11` |
| Toggle all-faction hotseat override (debug) | `F9` |

When `Mouse Cursor` is enabled in Settings, moving the mouse can also move the map cursor.

### Terms used in this handbook

- **Phase / turn:** one faction's opportunity to act; a turn ends after every faction in
  the cycle has acted.
- **Lead / support:** when two units Pair Up, the lead stays on the map and acts; the
  support is hidden off-map and supplies bonuses.
- **DONE:** the unit has spent its action this phase and appears greyed out.
- **Combat preview / forecast:** the panel shown before confirming an attack.
- **One-based coordinates:** the displayed top-left tile is `(1, 1)`, even though internal
  map data starts at zero.
- **Effective (display):** the stat value including combat-only bonuses (e.g. Pair Up).
- **CON / LoS:** Constitution and Line of Sight — utility stats, intentionally uncapped.
- **Internal Lv:** hidden progression level used for EXP/reclass scaling (was shown as
  `Int`).
- **Menu Scale:** the Settings slider that scales menus/modals only (not the HUD).

---

# Part I — Bug-fix re-verification (priority)

These six items are the bugs reported in the v0.2.0 return. Any map works unless noted;
Map 950 (`Pair Up: On`, `Auto Promote: Off`, `Leveling: Fixed`) is a good fixture.

## 1.1 High-zoom camera is stable (V020-01)

Load any map. Zoom to **3×** then **4×** (`=`), and pan with the cursor left/right/down.
Then, at **4×**, press `=` again (try to zoom past the max).

**Expected**

- Panning at 3×/4× scrolls smoothly — no sudden camera jumps or jitter.
- Pressing zoom-in at 4× does nothing (no reframe/jump); the view stays put. `0` resets.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 1.2 Map Zoom slider applies live (V020-02)

Open Settings (`O`) on an active map → **Map Zoom** slider; drag it.

**Expected**

- The map zoom changes **immediately** as the slider moves (label and map agree). You do
  not have to close and reopen Settings or change maps for it to take effect.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 1.3 Combat forecast never covers the defender (V020-03)

Zoom to **2×**, then **0.5×**, and at each zoom initiate an attack — including against a
defender near a **map edge**.

**Expected**

- The forecast panel sits **beside** the defender and never overlaps the defender's tile
  at any zoom or position. Near an edge it flips to the other side / above-or-below rather
  than covering the defender.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 1.4 F9 toggling does not revive spent units (V020-04, debug build)

On a map with AI (e.g. Map 001), let it reach the **enemy (Red) phase**. While Red acts,
toggle `F9` on/off **several times** during that single phase. Note units that have
already acted (greyed / DONE).

**Expected**

- Units that already spent their action **stay DONE** across every F9 toggle — control
  switches between you and the AI, but spent units are never reset to ready.
- The phase does not end early, freeze, or skip back to Blue prematurely.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 1.5 Seize objective uses one-based coordinates (V020-05)

Launch **Map 002 - Seize** and open the objective list (HUD).

**Expected**

- The Seize tile is listed as **`(16, 3)`** — the same one-based coordinate the Terrain
  panel and this handbook use — **not** the zero-based `(15, 2)`.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 1.6 HUD Reset keeps Terrain More Info aligned (V020-06)

In a map, hover terrain and open **Terrain More Info** (`F`) so the expanded box is
showing. Open Settings → **Edit HUD Layout** → **Reset** (and **Done**).

**Expected**

- After Reset, the expanded Terrain More Info box stays correctly anchored to the compact
  Terrain panel — its top is not shoved up to where the compact panel's top would be.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

---

# Part II — New character-sheet, More Info & scale surfaces

Open the character sheet with `I` on the unit under the cursor.

## 2.1 Internal Lv label (V020-07)

Press `I` on any unit and read the stat block.

**Expected**

- The hidden-level row reads **`Internal Lv`** (not `Int`), with the same number as before.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.2 CON and LoS on the sheet (V020-15)

On any unit's sheet, find the utility-stat row after Movement.

**Expected**

- **Con** (Constitution) and **LoS** (Line of Sight) are both shown with their values.
- Selecting each shows a More Info description; their **Class cap reads `—`** (both are
  intentionally uncapped).
- At small Menu Scale the rows are not clipped or crowded off the sheet.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.3 Class summary section (V020-11)

Look at the top of the sheet and the new class row.

**Expected**

- The title uses the **class display name** (e.g. `Cavalier`, not `cavalier`).
- A selectable **class row** lists tier, traits, allowed weapon families, and class skill
  unlocks; selecting it shows the class **description** in the side panel.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.4 Weapon stats in More Info (V020-10)

On a unit holding a weapon, select that weapon in the inventory list (click it or
navigate to it).

**Expected**

- The side panel shows the weapon's full stats: **Mt, Hit, Crit, Wt, range, required rank
  + family, and uses** (plus any effect tags) — not just a generic "a weapon" blurb.
- An item (non-weapon) shows its own description.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.5 Directional More Info selector (V020-10)

On the character sheet, use the **arrow keys / d-pad** to move the selection between
entries (class, stats, inventory, skills, weapon ranks). `F` still cycles forward.

**Expected**

- A **`▶` marker** appears on the selected row and moves as you press the directional keys
  (both directions); the side panel updates to match.
- Clicking a row still works and also moves the marker.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.6 Pair Up duration wording (V020-08, Map 950)

Pair `M950_Hero_SkillCap` (lead) with `M950_Cavalier` (support). On the next Blue phase,
press `I` on the Hero and select **Strength**; read the Bonuses list.

**Expected**

- The Pair Up bonus reads `Pair Up  +3  (this combat)` — **not** a bare `(—)` / `(-)`.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.7 Support partner named on the HUD (V020-09, Map 950)

With the same pair, hover the **lead** on the map and read the unit-info HUD panel.

**Expected**

- Below the `Paired +N …` line, a **`Support: M950_Cavalier`** line names the off-map
  partner.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.8 Menu Scale is independent of the HUD (V020-16)

Open Settings → **Menu Scale** and try the extremes (small and large).

**Expected**

- Menus/modals (Main Menu, New Game, Settings, Map Menu, action/item menus, combat
  forecast, character sheet, level-up/promotion modals) scale and stay **centered** at
  every scale.
- The on-map **HUD does not move or resize** with Menu Scale — HUD size/position is owned
  only by Edit HUD Layout.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.9 HUD layout editor affordances (V020-12)

In a map, Settings → **Edit HUD Layout**. Click a panel frame to select it.

**Expected**

- Each panel frame has a **bright-red outline**; the **selected** frame's outline is
  **yellow**.
- The scale buttons read **`Scale Panel −` / `Scale Panel +`**.
- Each frame shows **sample text** whose size visibly tracks that panel's scale (so you
  can judge font size). The sample text appears only in the editor, never in normal play.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.10 Debuff Tonic shows red effective stats (V020-14, Map 950)

On Map 950, `M950_Cavalier` carries **`Debuff Tonic (TEST)`**. Use it (Action Menu →
Item), then press `I` and select **Strength**.

**Expected**

- Strength drops by **4** for 4 turns; the **Effective value renders red**, and the
  Bonuses list shows the tonic with its `-4` and remaining duration.
- After four full turns the modifier drops and Effective returns to base.
- (This is a validation-only item; it is intentionally not in the normal roster/shop.)

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

---

# Part III — Display controls recheck

## 3.1 Borderless vs Fullscreen (V020-13 — explanation)

Settings → **Window Mode** offers **Windowed**, **Borderless**, and **Fullscreen**.

- **Borderless** = a window the size of your desktop with no title bar or borders. It
  keeps the desktop resolution, alt-tabs quickly, and is best for multi-monitor setups.
- **Fullscreen** = exclusive fullscreen; the game takes over the whole display. It can be
  slightly smoother but switches away from other apps more slowly.

Try each. Each change shows the **"Keep these display settings?"** confirm dialog with a
**15-second** countdown, **Keep**, and **Revert now** (the safety net from v0.2.0).

**Expected**

- Both modes apply immediately and both show the confirm-or-revert dialog. Waiting out the
  timer reverts cleanly; **Keep** persists across relaunch.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 3.2 Resolution + oversized-window clamp (recheck)

Settings → **Resolution**: pick a different option (e.g. 1600×900), confirm the dialog
appears. On a monitor smaller than 1920×1080, in **Windowed** mode pick **1920×1080**.

**Expected**

- Resolution change shows the confirm dialog; **Keep / Revert now / 15s auto-revert** all
  behave. An oversized window keeps its **title bar reachable** (clamped to the top-left),
  not centred off the top of the screen.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

---

# Part IV — Regression pointer (existing maps & systems)

The maps and core systems did not change in v0.2.1. If you have time after Parts I–III,
run the **full per-map regression** from the v0.2.0 handbook
(`AGENT/Docs/playtest_checklist_v0.2.0.md`, Part II: Maps 001–005, 900, 950) to catch any
incidental regression. Report anything that behaves worse than that handbook describes.

The most likely places a v0.2.1 change could have regressed something:

- The **character sheet** (`I`) — stats, breakdown colours, pairing navigation, More Info.
- The **HUD** — unit info, terrain, objective, the layout editor.
- **Menus** centering at various Menu Scales.
- **Map zoom** + **combat forecast** placement.
- **Map 950** roster, items, and the new Debuff Tonic.

- [ ] **Regression pass run (or `NOT RUN` with reason).**

**Tester comments:** _Enter comments here._

---

# Error-log check

After the pass, close the game and inspect:

`%APPDATA%\Godot\app_userdata\Fire Emblem RPG\logs\godot.log`

Report any line containing `ERROR`, `SCRIPT ERROR`, a `DataManager: …` error, a
`push_error`, or a crash stack trace, with the active map. If the file is absent, record
`LOG FILE NOT FOUND`. (Expected, harmless: pre-M9 skill stub warnings such as
`armsthrift`, `dash`, `disarm`, and a generic `ObjectDB instances leaked at exit`.)

- [ ] **No unexpected errors in `godot.log`.**

**Tester comments:** _Enter comments here._

---

# Known deferred issues

Do not report the unchanged behavior below as a v0.2.1 regression:

- Camera limits do not include viewport-aware overscan for edge panels.
- Mouse-follow camera catch-up remains abrupt.
- Clicking the Map Menu backdrop does not dismiss the menu.
- `Q` toggles the full danger zone; per-enemy threat inspection is not implemented.
- **Weapon names in the combat preview** are not yet shown (the character sheet now shows
  full weapon stats, but the in-combat forecast does not name the weapon yet).
- The directional More Info selector exists on the **character sheet**; the combat forecast
  and terrain More Info still use `F`-cycling only.
- **Aura skills** remain placeholders (M9) — they do not contribute to the stat breakdown.
- Contextual menus (action/item/forecast) are **not** movable in the HUD layout editor.

---

# What to send back

1. This completed handbook with every applicable checkbox marked.
2. Tester comments for every failed or unclear item.
3. Error-log output for any validation error, and the `godot.log` file (or a note that it
   was not found).
4. Screenshots for any visual failure (zoom, forecast placement, HUD layout, menu
   centering, character-sheet colours) — Parts I–III are visual, so screenshots help.
5. Exact repro steps using the failure format at the top of this document.
6. The resolution / Menu Scale / zoom values in use when a display issue appears.
