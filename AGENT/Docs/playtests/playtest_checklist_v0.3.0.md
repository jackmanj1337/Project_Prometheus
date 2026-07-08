# Playtester Handbook and Checklist - v0.3.0

> **Release checklist.** The v0.3.0 release-delta and full-scan blocker fixes are
> landed. This handbook is the live validation vehicle for `VAL-V030-GAMEPAD` and
> the remaining `VAL-V023-DISPLAY` §1.6 gate. Use it with
> `playtest_build_v0.3.0.md`, which records the final file size and SHA-256.

This document is written for testers who have not read the design documents or
source code. **Everything needed for this test pass is in this one file.**

> **What this build is.** v0.3.0 is the first **feature build** since the v0.2.x
> display reruns. It bundles a large batch of work that has never been in a
> tester's hands, so this pass is broad. It covers, in order:
>
> 1. **Controller support** (Part I / `VAL-V030-GAMEPAD`) — full gamepad
>    mapping, stick/trigger feel.
> 2. **Input mode + on-screen prompts** (Part II) — the new Settings *Input Mode*
>    row and the button-prompt swapping between keyboard and controller.
> 3. **Key rebinding** (Part III) — the new Settings capture UI.
> 4. **Suspend & Continue** (Part IV) — save a battle mid-map and resume it.
> 5. **Map readability** (Part V) — threat overlay, range peek, path arrows,
>    terrain dimming, on keyboard/mouse.
> 6. **Combat hit feel** (Part VI) — a heads-up about a deliberate hit-math change.
> 7. **Display close-out §1.6** (Part VII / `VAL-V023-DISPLAY`) — the last item
>    holding the display gate.
> 8. **Regression + logs** (Part VIII).

> **Please read — deliberate changes that are NOT bugs.** Two things changed on
> purpose. Do not file them as defects; only report if they behave *differently*
> than described here:
>
> - **Hit rates feel different (Part VI).** The default hit roll is now a "true
>   hit" (two-number average), so displayed hit chances between ~30–70% land
>   closer to what the number says than the old single-roll did. This is intended.
> - **A 4K windowed request can show a smaller applied size (Part VII).** In
>   Windowed mode the game clamps a too-large request to fit your usable screen.
>   Desktop visible around the window is expected — use Borderless/Fullscreen to
>   fill the monitor.

## Before You Begin

### Required build and equipment

- Windows 10 or 11, 64-bit
- Keyboard and mouse
- A standard Xbox-layout controller or Steam Deck controls (Parts I–III). A
  Nintendo- or PlayStation-layout pad is a **bonus** — it exercises the button-
  label swapping in Part II.
- A monitor that can show **1440p or 4K** is useful for Part VII (otherwise mark
  the 4K sub-checks `NOT RUN`).
- Executable: `Project_Prometheus_v0.3.0_debug.exe`.
- Expected file size / SHA-256: `101406640` bytes /
  `d003060b300e28ab8e7a0e94234505ef17f62562b51ac49b937de66f1222c5da`
  (also recorded in `AGENT/Docs/playtests/playtest_build_v0.3.0.md`).

The executable is a standalone debug build. It does not need Godot or an
installer. Do not disable antivirus to run it. If Windows blocks it, record the
exact message and contact the person who supplied the build.

Optional PowerShell integrity check (compare against the manifest hash):

```powershell
Get-FileHash .\Project_Prometheus_v0.3.0_debug.exe -Algorithm SHA256
```

### Tester information

- **Tester name:** _Enter name._
- **Test date:** _Enter date._
- **Windows version / device:** _Enter version._
- **Controller model(s):** _Enter (e.g. Xbox Series, DualSense, Switch Pro)._
- **Primary resolution:** _Enter resolution._
- **Monitor native resolution / size:** _Enter (for the Part VII windowed checks)._
- **Build hash verified:** _Yes / No._

### How to record results

Complete the sections in order. Only check **This item works as expected** after
every expectation in that item passes. Record failures as:

`Map / Unit or UI / Step / Actual / Expected / Repro`

For visual failures, include the window resolution **and the Menu Scale in use**,
and a screenshot (`Win+Shift+S`). If a check cannot be performed, leave it
unchecked and write `NOT RUN` with the reason. Do not check an item merely
because no problem was noticed.

If the game crashes or stops accepting input, record the active map, unit, last
action, and visible screen. Close the game, **preserve `godot.log` (see §12.2)**,
relaunch, and continue.

### Controls — keyboard / mouse

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
| Toggle threat/danger overlay | `Q` or middle-click |
| Peek a unit's range (hold) | `E` |
| Zoom map in / out / reset | `=` / `-` / `0`, or mouse wheel |
| Force Level Up / Growth Boost (debug) | `F10` / `F11` |

### Controls — controller

| Action | Controller |
|---|---|
| Move cursor / menu selection | D-pad or left stick |
| Confirm / select | Pad A |
| Cancel / back | Pad B |
| More Info | Pad X |
| Inspect unit | Pad Y |
| Previous / next available unit | LB / RB |
| Peek range (hold) | View / Back |
| Map Menu | Start |
| Danger / threat resolver | R3 |
| Zoom out / in (hold) | LT / RT |
| Zoom reset | L3 |

Debug actions and the direct Settings hotkey (`O`) are intentionally
keyboard-only. On controller use **Start → Settings**.

### Terms used in this handbook

- **Menu Scale:** the Settings slider that scales menus/modals only (not the
  HUD). It runs **0.5× to 2.0×**.
- **Input Mode:** the new Settings row that tells the game which control scheme
  to assume for on-screen prompts and menu focus (**Auto**, **Keyboard & Mouse**,
  **Gamepad**, or **Touch**). **Auto** follows the last device you used.
- **Windowed mode:** a normal titled, movable window (as opposed to Borderless or
  Fullscreen, which fill the monitor). The **Resolution** dropdown only matters here.
- **Watch set:** the set of enemies you have marked to keep their threat range
  shown. Marked enemies get a small **"D"** marker.

---

# Part I — Controller

Use a controller for this whole part. If **Input Mode** is set to **Auto**
(default), simply picking up the controller and pressing a button switches the
game into gamepad prompts. This part closes `VAL-V030-GAMEPAD` only when it runs
on real controller hardware; headless tests already cover the code path, but
they cannot prove stick feel, deadzones, device labeling, focus comfort, or
visual overlap.

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

---

# Part II — Input Mode & On-Screen Prompts

This part checks the new **Input Mode** Settings row and the button prompts that
swap between keyboard keys and controller buttons.

## 6. Input Mode Selector

Open **Settings** (`O`, or Start → Settings) and find the **Input Mode** row.

**Expected**

- The dropdown lists **Auto**, **Keyboard & Mouse**, **Gamepad**, and **Touch**.
- On a desktop PC, **Touch** is shown but **grayed out / disabled** (it is not
  hidden) — you cannot select it.
- Selecting **Keyboard & Mouse** or **Gamepad** explicitly, then closing and
  reopening Settings, keeps your choice (it persists).
- With **Auto** selected, using the keyboard makes the game behave as keyboard
  mode and using the controller switches it to gamepad mode, with no manual step.

- [ ] **This item works as expected.**

**Tester comments:** _Note any mode that is missing, selectable when it should be
grayed out, or not remembered after reopening Settings._

## 7. On-Screen Prompt Swapping

Trigger a **level-up** (`F10` debug force-level-up is fine) to see the
"Press … to continue" prompt, and open **More Info** (`F` / Pad X) on a forecast,
character sheet, or terrain panel to see its hint text. Do this once with the
keyboard active and once with the controller active. **If you have a Nintendo- or
PlayStation-layout pad, repeat with it.**

**Expected**

- With the keyboard active, prompts show a **key** (e.g. "Press F …").
- With an Xbox-layout controller active, the same prompts show the **button**
  (e.g. "Press X …").
- Prompts update **live** when you switch devices while a prompt is on screen —
  you do not have to reopen the panel.
- On a **Nintendo** pad, the printed A/B and X/Y **labels** match the physical
  button that actually confirms/cancels (Nintendo swaps A/B and X/Y positions vs
  Xbox). On a **PlayStation** pad, prompts print the ✕ ○ □ △ symbols. The button
  that acts is correct **regardless of the label** — a wrong-looking label that
  still works is a cosmetic note, not an input failure.

- [ ] **This item works as expected.**

**Tester comments:** _For a non-Xbox pad, record its model and whether the printed
labels matched the buttons that actually confirmed/cancelled._

---

# Part III — Key Rebinding

Open **Settings** and find the controls / keybinding rows.

## 8. Rebinding, Conflicts, and Reset

Confirm normal gameplay rows include **More Info**, **Peek Range**, and **Zoom In /
Zoom Out / Reset Zoom**.

Try rebinding an action (e.g. change **Confirm** or **Toggle Threat Range**),
both a keyboard key and — if listed — a controller button. Then deliberately
bind two different actions to the **same** key to create a conflict.

**Expected**

- Starting a capture and pressing a new key/button **stages** the change; it does
  **not** take effect live mid-edit.
- Binding two actions to the same key marks **both** rows in **red** and
  **disables Apply** until you resolve it.
- **Clear** empties a slot; **Revert** discards all pending edits; **Reset
  Controls** restores the defaults.
- After **Apply**, the rebound key/button actually performs the action in a map.
- Debug rows (force level-up, etc.) are shown but **not editable**.
- Closing Settings and reopening keeps your applied bindings.

- [ ] **This item works as expected.**

**Tester comments:** _Record the action you rebound, whether the conflict blocked
Apply, and whether the new binding worked in-map._

---

# Part IV — Suspend & Continue

This is the new mid-battle save. It lets you stop a map partway and resume later.

## 9. Suspend a Battle and Resume It

Start a map (New Game, or any map launch). Take a few turns — move units, attack,
maybe use an item — so the state is clearly mid-battle. Then, **on your own turn
(not mid-animation)**, open the **Map Menu** (`M` / Start) and choose
**Suspend & Quit**. This returns you to the Main Menu. Now choose **Continue**.

**Expected**

- **Suspend & Quit** is available on your turn and returns you to the Main Menu
  without a crash.
- The Main Menu **Continue** button is enabled after a suspend (and does
  something sensible — an error dialog, not a crash — if there is no save).
- **Continue** drops you back into the **same map** with:
  - your units and enemies in the **same positions** with the **same HP**,
  - the **same turn/phase** you left on,
  - any **Pair Up** state intact,
  - your **threat watch set** (marked "D" enemies) still marked.
- Finishing the map (win or lose) **clears** the suspend — after a completed map,
  **Continue** no longer resumes that battle.
- Relaunching the game after a suspend (without finishing the map) still offers
  **Continue** and resumes correctly.

- [ ] **This item works as expected.**

**Tester comments:** _Record anything that came back wrong after Continue —
position, HP, whose turn it is, Pair Up, or the watch set. If Continue failed,
note the exact dialog text._

---

# Part V — Map Readability (keyboard / mouse)

Part I already covered the controller versions of these. Here, confirm they work
on **keyboard/mouse**. Use a map with several enemies.

## 10. Threat Overlay, Peek, Path Arrows, Terrain Dim

**Expected**

- **`Q`** (or **middle-click**) cycles the danger/threat overlay display.
- Pointing at a hostile, attack-capable enemy and toggling it adds a **"D"**
  marker and keeps its threat range shown (the watch set).
- **Holding `E`** over a unit shows *that unit's* reach; releasing restores the
  previous overlay.
- Plotting a move shows **path arrows** from the unit to the hovered destination.
- In **Settings**, the **Terrain Dim** slider (0%–50%) visibly dims the terrain
  under overlays as you raise it, and the percentage label tracks the slider.

- [ ] **This item works as expected.**

**Tester comments:** _Note any overlay that fails to toggle, a watch marker that
does not stick, missing path arrows, or a Terrain Dim slider that does nothing._

---

# Part VI — Combat Hit Feel (heads-up + light check)

**No setup needed — this is mostly a heads-up.** As noted at the top, the default
hit roll is now a **"true hit"**: the game averages two random numbers instead of
rolling one, which pulls mid-range displayed hit chances (roughly 30–70%) closer
to the number shown. High and low displayed chances feel about the same as before.

Play a few combats and just sanity-check the feel.

**Expected**

- Displayed hit percentages still show and read the same way.
- Outcomes are believable for the number shown (a 65% shot hits more often than it
  misses; a 5% shot almost never lands).
- No combat softlocks, wrong-target hits, or damage that ignores the forecast.

- [ ] **This reads as intended (not a bug).**

**Tester comments:** _Only report if hit results seem to contradict the displayed
percentage over many combats._

---

# Part VII — Display close-out (§1.6 Windowed sizing)

This is the **last item holding the display gate** and the reason the earlier
v0.2.x reruns existed. The v0.2.8 return already passed the action-menu
anchoring and combat-forecast display checks; only §1.6 windowed sizing remains.
The Settings screen is all you need. Open it with `O`.

## 11. Windowed Sizing: Size Readout + Windows Maximize (V028-02 / V028-03)

**Read this first — the size vocabulary (what the numbers next to Resolution mean):**

- **preset request** — a size you pick from the **Resolution** dropdown. It is a
  *request*: in Windowed mode the game **clamps** it to fit your usable screen
  (leaving room for the title bar and taskbar), so the readout shows
  **`→ applied W×H`** *only when the clamp actually changed it*. A 4K windowed
  request on a 4K monitor showing a smaller applied size (desktop visible around
  the window) is **expected, not a bug** — use Borderless/Fullscreen to fill the
  monitor.
- **client size** — the actual window interior (the game view) the OS gave you.
  When you **drag the window edge** yourself, that new size is already a client
  size, so the game shows it as **`client W×H`** and writes it back into the
  saved Resolution. It is **not** re-run through the request clamp.
- **native display size** — your monitor's full size, shown as **`native W×H`**
  while Borderless/Fullscreen have the Resolution row grayed out.

**Now test it** (in **Settings → Window Mode = Windowed** unless a step says otherwise):

**(a) Custom-size readout after a drag-resize.** Drag the window's **edge** to a
clearly non-preset size. Watch the **readout** next to Resolution and the
**Resolution dropdown**.

**(b) Windows maximize button.** With the **Settings menu open** in Windowed
mode, click the **maximize button** in the top-right of the window title bar.
Watch the Settings panel as it maximizes. Then click the same button again (or the
restore button) to **un-maximize**. For a sharper test, set **Menu Scale to 2.0×**
first, then maximize.

**Expected**

- **(a)** After the drag, the readout shows the new size as **`client W×H`** (the
  real interior size), and the **Resolution dropdown shows that size** as a
  **`Custom (W×H)`** entry if it isn't a preset. There is **no** nonsense second
  "applied" number derived from a size you were already given. Picking any preset
  afterward replaces the `Custom` entry. The window stays **where you put it** (no
  re-centre), and the dragged size **persists**: quit and relaunch and the window
  returns at that size.
- **(b)** The Settings panel **stays centered** the whole time you maximize — **no
  drift, no wiggle, no need to nudge a slider to fix it**. When you
  **un-maximize**, the window returns to your **chosen windowed size**, and the
  saved Resolution is **not** left showing a giant maximized `Custom` value.

- [ ] **This item works as expected.**

**Tester comments:** _Enter the dragged client size + the exact dropdown/readout
text (a screenshot helps), and whether the panel stayed centered through
maximize/un-maximize._

---

# Part VIII — Feature Sweep, Regressions, and Logs

## 12.1 Full feature sweep

After Parts I-VII, spend at least 20-30 minutes playing normally. Use this as a
coverage map: each row names what to test and the fastest way to stress it. If
time is short, prioritize the rows marked **High attention** in §12.2.

| Area | How best to test it | Expected / watch for |
|---|---|---|
| Main Menu | Launch, read the version label, start New Game, return via Quit. | Version reads `v0.3.0`; buttons focus/click correctly; no stale Continue unless a suspend exists. |
| Map start | Start a fresh map after changing settings. | Units/enemies spawn once, camera/cursor start sensible, no crash or duplicate map load. |
| Turn flow | Move several units, end turn, watch enemy phase, regain player phase. | Units cannot act twice; enemy phase completes; phase banners and active-unit cycling stay sane. |
| Movement/cancel | Select units, preview paths, cancel before and after choosing a tile. | Paths/arrows clear correctly; cancel returns to the prior state without losing input. |
| Combat forecast | Preview melee and ranged attacks from both screen edges. | Forecast appears on screen, values fit, More Info cycles cleanly, chosen target matches forecast. |
| Combat resolution | Fight several combats, including misses and kills if possible. | HP, deaths, EXP, and map occupancy update correctly; no softlock after combat. |
| Items / inventory | Open item and weapon menus; use or equip what is available. | Menus open/close, disabled options stay disabled, inventory text does not clip. |
| Unit details | Open unit details on player and enemy units; cycle More Info. | Stats, skills, inventory, Back focus, and prompt text stay readable at 1.0x and 2.0x Menu Scale. |
| Pair Up | Pair and unpair units if the current map/setup allows it. | Lead/support state survives combat, turn changes, and suspend/resume. Mark `NOT RUN` if no pair-up setup is available. |
| Level-up modal | Trigger a level-up naturally or with `F10`; close it with keyboard and controller. | Prompt matches active input mode; modal blocks map input until dismissed, then releases cleanly. |
| Settings persistence | Change display, input mode, keybinds, and terrain dim; close/reopen Settings and relaunch. | Applied settings persist; Revert/Reset do what they say; no stale prompt or focus state. |
| Game over / quit paths | Lose a unit/map if practical, or use menu quit paths. | Game-over/quit screens accept input and return to the correct place without corrupting Continue. |

- [ ] **Full feature sweep completed or every skipped row is marked `NOT RUN`
  with a reason.**

**Tester comments:** _Enter row-by-row notes here. Include map, unit, step,
actual result, expected result, and repro for any failure._

## 12.2 Regression tests needing special attention

These deserve extra focus because they were recent release blockers, high-risk
fixes, or areas where automated tests cannot prove the real player experience.

| Regression | Why it matters | Best stress test |
|---|---|---|
| **Windowed sizing / maximize (§11)** | This is the remaining `VAL-V023-DISPLAY` gate from the v0.2.x returns. | Repeat §11 at 1.0x and 2.0x Menu Scale; drag to a custom size, maximize, restore, quit, relaunch. |
| **Real controller feel (§1-5)** | Headless tests cover routing, not stick deadzone, trigger feel, pad labels, or comfort. | Use only a controller for a full turn cycle; try light stick tilt, held stick, held LT/RT, Start menu, R3, and View/Back. |
| **Input mode prompt refresh (§6-7)** | Recent fix added live prompt/focus updates after settings changes. | Leave a prompt visible, switch Input Mode and physical device, and confirm the prompt changes without reopening the screen. |
| **Keybind conflict coverage (§8)** | Rebind rows now come from the live InputMap; missing actions caused unbindable controls and hidden conflicts. | Confirm More Info, Peek Range, and all zoom rows exist; deliberately create a conflict; verify Apply is blocked. |
| **Suspend/Continue state (§9)** | Suspend touches save data, map reconstruction, RNG state, Pair Up, and watch-set persistence. | Suspend after moving, attacking, toggling a watch marker, and pairing if possible; relaunch the exe before Continue. |
| **Fresh-map RNG startup** | A release-blocker fix moved fresh maps onto a real per-map seed. | Start a fresh map, fight several combats, use Retry/New Game if available, and watch for repeated identical outcomes or stale state. |
| **Threat/readability overlays (§10)** | Watch sets, peek overlays, path arrows, and terrain dim share overlay precedence. | Toggle Q/R3, hold E/View, move the cursor between units, plot/cancel paths, and change Terrain Dim while overlays are visible. |
| **Combat forecast and UI scaling** | Prior display returns found forecast/menu placement and clipping bugs. | Open forecasts and unit details at both screen edges with Menu Scale 0.5x, 1.0x, and 2.0x; include screenshots for any clipping. |

- [ ] **High-attention regressions were stressed, with notes for every failure
  or `NOT RUN` item.**

**Tester comments:** _Enter comments here._

## 12.3 Return the log

The log lives in your Windows **user-data folder** under `%APPDATA%`, not beside
the exe.

- **Let the log tell you where it is — this is authoritative.** Every launch, the
  game prints a framed **BUILD STAMP** as the very first lines of the log. That
  block includes a **`log=`** line showing the **exact, full path** to the log
  file. **Copy the path from that `log=` line.**
- **Typical path shape:**
  `%APPDATA%\Godot\app_userdata\<project>\logs\godot.log`. Paste **`%APPDATA%`**
  into the **Windows Explorer address bar** to jump to the `Roaming` folder, then
  drill down `Godot\app_userdata\<project>\logs\`.
- **Open `godot.log` and copy the first block** — it starts with
  `=== BUILD STAMP ===` and lists the version, a commit id, a `started_at` time,
  and the exact `log=` path. Paste that block into your report and **attach the
  whole `godot.log` file**.
- The log is written **per launch**, so copy it **before relaunching** if you hit
  a problem.

- [ ] **`godot.log` attached, with the BUILD STAMP block pasted into the report.**

**Tester comments:** _Paste the BUILD STAMP block here (the `log=` line is the
exact path)._

---

## 12.4 Gate result summary

Only fill this out after the relevant section passes completely.

- [ ] **`VAL-V030-GAMEPAD` can close:** Part I controller checks passed on real
  hardware, with any controller model notes recorded above.
- [ ] **`VAL-V023-DISPLAY` can close:** Part VII §1.6 windowed sizing passed on a
  real Windows display, including maximize/un-maximize behavior.

**Tester comments:** _If either gate stays open, write the failing item number
and repro here._

---

Thank you. This build folds several months of feature work — controller support,
input handling, suspend/resume, map readability, and the display close-out — into
one pass, so thorough notes here are especially valuable.
