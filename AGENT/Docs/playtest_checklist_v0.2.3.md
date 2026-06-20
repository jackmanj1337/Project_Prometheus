# Playtester Handbook and Checklist - v0.2.3

This document is written for testers who have not read the design documents or source
code. **Everything needed for this test pass is in this one file.**

> **Important — this build contains TWO rounds of unplayed work.** The last playtested
> build was **v0.2.1**. Since then a feature round (v0.2.2, never built for playtest) and
> the v0.2.3 display work both landed. So this pass covers both. **Part I (display &
> crisp scaling) is the priority** — it is the v0.2.3 headline and the renderer changed
> underneath it. **Part II** covers the unplayed v0.2.2 gameplay/UI features. **Part III**
> is the regression pointer.

## What changed since v0.2.1

**Display & rendering (v0.2.3 — the priority):**

- **Renderer switched to "Compatibility"** (the GL-based renderer). This is an
  under-the-hood change shared with the upcoming web build — the whole game must still
  look and run correctly.
- **Crisp Menu Scale.** Menus no longer get blurry when scaled. Scaling now resizes the
  *type* (fonts/metrics) instead of zooming the rendered image, so menu text stays sharp
  at every Menu Scale from 0.75× to 2.0×.
- **Native 1440p / 4K** resolution options added (`2560×1440`, `3840×2160`).
- Explicit **letterboxing** policy on non-16:9 windows.

**Gameplay / UI (v0.2.2, unplayed):**

- **F9 hotseat** now rolls an AI unit back to its start if you grab control mid-move.
- **Terrain More Info** is now *paged*: `F` cycles Hidden → Description → Movement.
- **Movement types**: fliers cross water/mountains freely (blocked only by walls); the
  terrain Movement page has a **Flying** row; class More Info names the movement type.
- **Class summary** moved into class **More Info** (the inline row is now name + tier).
- **Combat forecast** now names each combatant's **weapon** ("Unarmed" if none).
- **Map Menu** backdrop click dismisses the menu.
- **Cancel over an unselected unit** opens that unit's character sheet.
- **Mouse Cursor** setting is now **Follow / Click / Off** (Click = tap-to-move,
  tap-again-to-confirm; touch-friendly).
- Character-sheet **arrow/d-pad selector** now moves Up/Down vertically (was inverted).
- Pair-up bonus durations use clearer wording (e.g. **until separated**).
- HUD-layout editor: input no longer leaks to the map; sample text stays inside panels.

## Before you begin

### Required build and equipment

- Windows 10 or 11, 64-bit
- Keyboard and mouse (a gamepad/d-pad is optional but useful for the selector check)
- A monitor that can show **1440p or 4K** is useful for Part I §1.9 (otherwise mark it
  `NOT RUN`)
- Executable: `Project_Prometheus_v0.2.3_debug.exe`
- Expected file size: _see `AGENT/Docs/playtest_build_v0.2.3.md`._
- Expected SHA-256: _see the build manifest._
- Build manifest: `AGENT/Docs/playtest_build_v0.2.3.md`

The executable is a standalone debug build. It does not need Godot or an installer. Do
not disable antivirus to run it. If Windows blocks it, record the exact message and
contact the person who supplied the build.

Optional PowerShell integrity check (compare against the manifest hash):

```powershell
Get-FileHash .\Project_Prometheus_v0.2.3_debug.exe -Algorithm SHA256
```

### Tester information

- **Tester name:** _Enter name._
- **Test date:** _Enter date._
- **Windows version:** _Enter version._
- **Primary resolution:** _Enter resolution._
- **Monitor native resolution / size:** _Enter (for the 1440p/4K + oversized-window checks)._
- **Input method:** _Keyboard/mouse, gamepad, or both._
- **Build hash verified:** _Yes / No._

### How to record results

Complete the sections in order. Only check **This item works as expected** after every
expectation in that item passes. Record failures as:

`Map / Unit or UI / Step / Actual / Expected / Repro`

For visual failures, include the window resolution **and the Menu Scale in use**, and a
screenshot (`Win+Shift+S`). Crispness is judged by eye — a "soft/blurry text" failure
should say which menu and which scale. If a check cannot be performed, leave it unchecked
and write `NOT RUN` with the reason. Do not check an item merely because no problem was
noticed.

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
| Open or cycle More Info / terrain pages | `F` |
| Move the More Info selection | arrow keys / d-pad |
| Toggle danger/threat overlay | `Q` or middle-click |
| Zoom map in / out / reset | `=` / `-` / `0`, or mouse wheel |
| Force Level Up / Growth Boost (debug) | `F10` / `F11` |
| Toggle all-faction hotseat override (debug) | `F9` |

The **Mouse Cursor** setting (`Follow` / `Click` / `Off`) controls how the mouse drives
the on-map cursor: Follow = hover moves it; Click = first click moves it, second click on
the same tile confirms; Off = mouse motion never moves it (clicks still act).

### Terms used in this handbook

- **Menu Scale:** the Settings slider that scales menus/modals only (not the HUD), from
  0.75× to 2.0×.
- **Crisp / soft:** "crisp" = text edges are sharp; "soft" = blurry/fuzzy, as if zoomed.
- **Letterbox / pillarbox:** black bars added top/bottom or left/right to keep the game's
  16:9 shape on a differently-shaped window.
- **Phase / turn:** one faction's opportunity to act; a turn ends after every faction has
  acted.
- **Lead / support:** when two units Pair Up, the lead stays on the map; the support is
  hidden off-map and supplies bonuses.
- **DONE:** the unit has spent its action this phase and appears greyed out.
- **Movement type:** the single category (flying / mounted / armoured / light / infantry)
  that decides a unit's terrain move costs.

---

# Part I — Display, renderer & crisp scaling (priority)

This is the v0.2.3 headline and the closeout gate. Any map works for these checks.

## 1.1 Renderer sanity (Compatibility)

Launch the game and load any map. Look at sprites, tiles, the HUD, fonts, and overlays
(danger zone `Q`, movement range), and compare against your memory of v0.2.1.

**Expected**

- The game launches to the Main Menu and plays normally. No black screen, missing
  sprites, garbled tiles, wrong colours, or missing text anywhere.
- Performance feels at least as smooth as v0.2.1.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 1.2 Menu text stays crisp at LARGE scale (the headline)

Settings (`O`) → **Menu Scale**. Step it up to **1.25×, 1.5×, 1.75×, 2.0×**. At each
step, open several menus and read the text closely: Main Menu, New Game, Settings, Map
Menu, an action/item menu (select a unit → move → wait for the menu), the combat
forecast, the character sheet (`I`), and a level-up (`F10`).

**Expected**

- At **every** scale, menu/label text is **crisp** — sharp edges, not blurry or fuzzy.
  (In v0.2.1 this text got softer the larger you scaled; that should be gone.)

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 1.3 Menu text stays crisp AND readable at SMALL scale

Set **Menu Scale to 0.75×** (the smallest). Open the same menus as §1.2.

**Expected**

- Text is **smaller but still crisp** (not blurry).
- Text is still **comfortably readable** — nothing is so small it's illegible, and rows
  are not overlapping. (If anything is too small to read, say which menu — this is design
  feedback we want.)

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 1.4 Centered menus stay centered at every scale

At a few different Menu Scales, open the Main Menu, New Game, Settings, the Map Menu, and
the character sheet. Then, in windowed mode, **resize the window** with one open.

**Expected**

- These panels stay **centered** in the window at every scale and after a resize — not
  drifting to a corner or off-screen.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 1.5 Contextual menus stay anchored to the cursor

At a large Menu Scale, select a unit, move it, and open the **action menu** (and from it,
an item/weapon submenu).

**Expected**

- These contextual menus appear **at/near the cursor or unit** (their normal anchored
  spot) and grow from there — they are **not** yanked to the center of the screen like the
  full-screen menus in §1.4.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 1.6 Settings & character sheet: scroll frame holds, text scales

At **1.5×** and **2.0×**, open **Settings** and the **character sheet** (`I`), both of
which scroll.

**Expected**

- The text inside scales up and stays crisp; the panel keeps a sensible fixed frame and
  **scrolls** to reach overflow content. Nothing is clipped off where you can't scroll to
  it; rows are not crammed on top of each other.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 1.7 Level-up screen scales cleanly

At a few Menu Scales, trigger a level-up with **`F10`** on a selected unit and watch the
stat-gain screen.

**Expected**

- The level-up panel sizes to its contents with even padding (no text touching the panel
  edge, no oversized empty panel), stays centered, and all stat lines are visible and
  crisp at every scale.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 1.8 Long menus still fit top-to-bottom at 2.0×

Set **Menu Scale to 2.0×** and open the **character sheet** (`I`) on a unit with several
skills/items (so it's tall).

**Expected**

- The whole sheet fits on screen — its **top and bottom are both reachable/visible**, not
  cut off past the screen edge. (It may auto-reduce its size slightly to fit; that's
  intended.)

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 1.9 Native 1440p / 4K resolutions

Settings → **Resolution**. (Use **Windowed** mode.)

**Expected**

- The list includes **2560×1440** and **3840×2160** in addition to the smaller options.
- On a monitor that supports it, selecting one applies via the **"Keep these display
  settings?"** confirm dialog (Keep / Revert now / 15-second auto-revert), and the window
  resizes accordingly. On a monitor that can't fit it, the window stays usable (title bar
  reachable) — record what happens.
- _If your monitor is below 1440p, mark this `NOT RUN` and note your resolution._

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 1.10 Letterboxing on an odd-shaped window

In **Windowed** mode, drag the window to a deliberately non-16:9 shape (very wide, or
very tall/narrow).

**Expected**

- The game keeps its 16:9 picture with **black bars** filling the leftover space
  (pillarbox on a wide window, letterbox on a tall one). The HUD and menus stay on-screen
  — nothing is pushed off an edge or stretched/distorted.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

---

# Part II — Unplayed v0.2.2 gameplay & UI features

## 2.1 F9 mid-move rollback (V021-01, debug build)

On a map with AI (e.g. Map 001), reach the **enemy (Red) phase**. While an enemy unit is
**mid-move** (walking to its destination), press **`F9`** to grab control. Then toggle
`F9` a few times during the same phase.

**Expected**

- A unit interrupted mid-move is **rolled back to where it started** that activation and
  is still ready — it does **not** end up teleported to its destination without having
  spent its turn.
- Units that already finished acting stay **DONE** across every toggle; the AI does not
  re-move them. The phase doesn't end early or freeze.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.2 HUD editor input capture + reset reflow (V021-02)

In a map: Settings → **Edit HUD Layout**. With it open, try pressing map keys (move
cursor, `M`, `I`) and `Esc`. Then hover terrain, open **Terrain More Info** (`F`), and use
the editor's **Reset** then **Done**.

**Expected**

- While the editor is open, map keys do **nothing** (input is captured); `Esc`/Cancel
  routes to the editor's own Cancel, not through to closing Settings or driving the map.
- After Reset + Done, the Terrain More Info box stays correctly anchored to the compact
  terrain panel (not shoved up or detached).

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.3 HUD editor sample text stays inside panels (V021-03)

In Edit HUD Layout, select panels and scale them up/down.

**Expected**

- The sample text in each panel frame stays **inside the frame** (clipped/wrapped), never
  spilling outside the panel rectangle.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.4 Character-sheet selector moves the right way (V021-06)

Press `I` on a unit. Use the **arrow keys / d-pad** to move the `▶` selector around the
sheet (class, the two-column stat block, inventory, skills, weapon ranks).

**Expected**

- **Up/Down** move the selection **vertically** (e.g. from a stat to the row above/below,
  keeping the same column); **Left/Right** step through entries in order. `F` still cycles
  forward. The side panel updates to match. (Previously Up/Down moved sideways — that's
  fixed.)

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.5 Map HUD pair-up line (V021-07, Map 950)

On Map 950, Pair `M950_Hero_SkillCap` (lead) with `M950_Cavalier` (support). Hover the
lead and read the unit-info HUD panel.

**Expected**

- The pair line reads only **`Support: M950_Cavalier`** (the per-stat `+N` deltas are
  gone from the map HUD), and it is **not cut off** the bottom/edge of the panel. (The
  full per-stat breakdown still lives on the `I` sheet.)

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.6 Duration wording on the sheet (V021-09, Map 950)

With the pair from §2.5, press `I` on the Hero, select **Strength**, read the Bonuses
list. Then on `M950_Cavalier` use the **Debuff Tonic (TEST)** (Action → Item) and check a
lowered stat's bonus line.

**Expected**

- The Pair Up bonus reads **`until separated`** (not `this combat` or a bare `—`).
- The tonic's debuff reads a countdown like **`x turns`** / `N turns`.
- An always-on stat skill (if any) shows no expiry (a dash), not "this combat".

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.7 Class summary lives in More Info (V021-10)

Press `I` on a unit. Look at the class row, then **select it** to open its More Info.

**Expected**

- The inline class row is compact: **class name + tier** only.
- Selecting it shows the relocated detail in the side panel: description, **movement
  type**, traits, allowed weapon families, and class skill unlocks.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.8 Movement types, especially flying (V021-11)

Hover terrain and open the **Movement** page (`F` until the move-cost table shows). Then
test a flier (e.g. a Pegasus/Wyvern class unit if present) moving over **water/sea,
mountains, and a wall**.

**Expected**

- The Movement page lists a **Flying** row alongside Mounted/Armoured/Light.
- A flier crosses water/sea/mountain at low cost (treats them as open) but **cannot cross
  walls**. Ground units are unaffected (same costs as before).

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.9 Terrain More Info paging (V021-05)

Hover a tile and press **`F`** repeatedly.

**Expected**

- `F` cycles **Hidden → Description (+ tile actions) → Movement table → Hidden**. The
  compact terrain readout (Def/Dodge) stays visible throughout; "Hidden" fully removes the
  More Info box to free map area.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.10 Combat forecast names the weapons (V021-14)

Initiate an attack to show the combat forecast.

**Expected**

- Under each combatant's name is the **weapon name** they'll fight with (or **"Unarmed"**
  if none).

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.11 Map Menu backdrop click dismisses it (V021-13)

Open the Map Menu (`M`) and **left-click outside** the menu panel (on the darkened
backdrop).

**Expected**

- The Map Menu closes. (Clicking inside the panel still works normally.)

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.12 Cancel over a unit opens its sheet (V021-16)

In the free-roam state (no unit selected), put the cursor **over an unselected unit** and
press **Cancel** (`X` / right-click). Then move to an **empty tile** and press Cancel.

**Expected**

- Cancel over a unit opens that unit's **character sheet**.
- Cancel over an empty tile opens the **Map Menu** (unchanged).

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

## 2.13 Mouse Cursor modes (V021-17)

Settings → **Mouse Cursor**. Try each value:
- **Follow:** move the mouse over the map.
- **Click:** click an empty tile, then click the **same** tile again. Also click the
  terrain panel's corner area.
- **Off:** move the mouse over the map.

**Expected**

- **Follow:** the map cursor tracks the mouse hover.
- **Click:** hover does nothing; the **first** click moves the cursor to that tile, a
  **second** click on the same tile confirms (selects). Clicking the terrain corner cycles
  its More Info pages.
- **Off:** mouse motion never moves the cursor (clicks still act as confirm/cancel).

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

---

# Part III — Regression pointer (existing maps & systems)

The maps and core combat systems were not the focus of this build, but the renderer
change (§1.1) and the v0.2.2 UI changes touch a lot. If you have time after Parts I–II,
run the **full per-map regression** from the v0.2.0 handbook
(`AGENT/Docs/playtest_checklist_v0.2.0.md`, Part II: Maps 001–005, 900, 950).

Most likely places a v0.2.2/v0.2.3 change could have regressed something:

- **Anything visual** (the renderer changed) — sprites, tiles, fonts, overlays.
- **Menus** at various Menu Scales (centering, crispness, fit).
- **The character sheet** (`I`) — selector, class More Info, stat colours, durations.
- **The HUD** — terrain paging, pair-up line, the layout editor.
- **Terrain move costs** — especially fliers and the desert exception.
- **Mouse control** in each Mouse Cursor mode.

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

Do not report the unchanged behavior below as a v0.2.3 regression:

- **HUD panel scale is still soft** when scaled in the HUD Layout editor — the crisp
  rework in this build is **menus only**; the HUD's own scaling is a later item (V021-04).
- Terrain corner-snap can loosen when the terrain panel is resized in the editor (V021-04,
  editor-only cosmetic).
- The directional selector exists on the **character sheet** only; the combat forecast and
  terrain More Info still use `F`-cycling (V021-15).
- Class-skill entries in class More Info are not yet individually clickable (V021-12).
- **Aura skills** remain placeholders (M9) — they do not contribute to the stat breakdown.
- Contextual menus (action/item/forecast) are **not** movable in the HUD layout editor.
- Mouse-follow camera catch-up remains abrupt; `Q` toggles the full danger zone (no
  per-enemy threat inspection yet).

---

# What to send back

1. This completed handbook with every applicable checkbox marked.
2. Tester comments for every failed or unclear item.
3. Error-log output for any validation error, and the `godot.log` file (or a note that it
   was not found).
4. Screenshots for any visual failure — **for crispness/scale issues include the Menu
   Scale and window resolution** in use.
5. Exact repro steps using the failure format at the top of this document.
6. Your overall read on **0.75× readability** and whether any menu felt too small or too
   large at the scales you tried (this build's scaling is new — design feedback welcome).
