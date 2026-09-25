---
Role: dated
Type: playtest
Status: Candidate preparation
Last verified: 2026-09-25
---

# v0.8.6 Windows Tester Checklist

v0.8.5 was withdrawn before native testing. Its browser pre-walk found the live-map
panels running into each other at 2× on smaller windows: at 900×760 and 560×900, 2×
left a canvas too small for any screen, and at 1280×720 the Objectives box covered
the unit panel. v0.8.6 fixes both. Viewport Scale is now limited by the window size,
and the map's panels move out of each other's way. v0.8.5's other checks never
reached a native tester, so they all carry over: the campaign font on a live map,
the Chapter 6 countdown in a **release** build with the normal AI, and a Load Game
list with saves in it.

**Run 1A and 1B first.** They are why this round exists. If either fails, stop
there and return what you have. 1C needs saves from later steps, so Section 5
tells you when to do it.

Return the completed checklist, the diagnostics ZIP (Section 5) and a screenshot
for every failed visual check. Name each screenshot after its checklist item,
for example `1A 560x900 2.0`.

## What is in the bundle

| File | Used in |
|---|---|
| `Project_Prometheus_v0.8.6.exe` (release) | All sections unless stated otherwise |
| `Project_Prometheus_v0.8.6_debug.exe` | Only to reproduce a failure the release build shows |
| `campaign-packs/free-roam.zip` | 1A, 2, 3 |
| `campaign-packs/internal.zip` | 3, 4 (private: see Section 4) |
| `interaction-duration-backup.zip` | 1B, 1C |
| `campaign_backup_v2.zip` | 1C, 5 |
| `campaign-packs/migration-v1.zip`, `migration-v2.zip`, `collision-a.zip`, `collision-b.zip` | 5 |
| `screenshot-album/`, `pack-gate-evidence/` and the two gate receipts | Section 6 (read only; you do not run these) |

**Scale settings.** In Settings, **Menu Scale** and **Viewport Scale** are separate
sliders. "At 0.5×" in this checklist means set **both** to 0.5×; "at 2×" means set
both to 2.0×. Anything not given a scale runs at 1.0× on both. **A fresh profile
does not start at 1.0×:** on a small window it picks a smaller Viewport Scale by
itself (0.5× at 900×760). Check both sliders before each step.

**Viewport Scale is limited by the window.** The game will not shrink the view
below 640×360 of its own units. When the window is too small for the scale you
chose, Settings shows both numbers, for example `2x (1x)`: you chose 2×, and 1× is
in use. Hovering the value explains why. Your choice is kept, and a larger window
gets it back.

**Scrolling menus.** At 1280×720 and 2×, menus have less room than their buttons
need, so some buttons, such as New Game's **Start** and Prep's **Begin**, are
below the visible part of the list. Scroll the list or use the arrow keys to reach
them. That is expected at this size.

**Window sizes.** Set the size in Settings or by resizing the window. It does not
need to be exact to the pixel; record the size you actually used.

## 0 — Identity and clean start

- [ ] `BUILD_INFO.json`, `SHA256SUMS.txt`, the executable's BUILD STAMP and the
  Main Menu all say v0.8.6 and name the same source commit.
- [ ] Start with a clean profile. New Game and Load Game both show a clear
  empty state.
- [ ] In **Manage Library → Import Package…**, import `free-roam.zip` as supplied. Do not unzip,
  edit or re-zip it.

## 1 — The v0.8.6 fixes and the v0.8.5 checks (run first)

### 1A — Campaign font and panels on a live map

This covers the v0.8.4 rejection, where text inside the Objectives box and the unit
panels overlapped with the free-roam font active, and the v0.8.5 finding, where the
panels themselves ran into each other at 2×.

Make `free-roam.zip` the active campaign and start any of its maps. Wait until
you can move the cursor over the map. A menu, a loading screen or the main menu
behind a map does not count. Select one of your units so the unit panel and the
terrain panel are both showing.

Take one screenshot per row below: 12 in total. For each, check the
**Objectives** box, the **selected-unit panel** and the **terrain panel**. Pass
means every line of text is readable, separate from the lines above and below it,
inside its own panel, not cut off at an edge, with no box characters where letters
should be.

| Window | 0.5× | 1.0× | 2× |
|---|---|---|---|
| 1280×720 | [ ] | [ ] | [ ] |
| 1920×1080 | [ ] | [ ] | [ ] |
| 900×760 | [ ] | [ ] | [ ] |
| 560×900 | [ ] | [ ] | [ ] |

- [ ] Every one of the 12 cases passes. List any that do not, with its screenshot.
- [ ] No two panels overlap in any case. Three of them look different on purpose.
  - **1280×720 at 2×:** while a unit is selected, the Objectives box shrinks to its
    **Objectives** title. Deselect the unit and move the cursor to an empty corner
    of the map. The full box comes back once nothing is in its way.
  - **900×760 and 560×900 at 2×:** the window limits the scale, so these look like
    1×. Open Settings: Viewport Scale reads `2x (1x)`. Resize the window to
    1920×1080: the view grows to 2× without touching the slider.
  - **560×900 at 1× and 2×:** the unit panel sits above the terrain panel instead of
    beside it.

### 1B — Hallowed Sear countdown, release build, normal AI

This duration has only ever been seen in a debug build, with the enemy turn
driven by hand (the F9 hotseat override). This time it must be seen in the
release build, with the enemy turn played by the AI. **Do not use F9 and do not
use the debug executable for this section.**

`interaction-duration-backup.zip` restores a Chapter 6 battle that has been
cut down to two units. They are Hallowed Bearer (BLUE, HP 24, tile 2,3) and one
Revenant (RED, HP 22, tile 8,3). The Revenant is set to wait on its own turn.
It still hits back when attacked, but a single exchange will not kill either unit.

Before you start, open **Settings** and set **Auto-End Turn** to **Off**. Hallowed
Bearer is BLUE's only unit, so with Auto-End Turn on, the attack itself ends BLUE's
phase and the AI plays RED's before you can open Unit Details. The first count you
could see would then already be `(1 phase)`. Turn it back on when 1B is done.

In this font the digit **1** looks like a small capital **I**. `(1 phase)` is
singular, and `(2 phases)` is plural, which is the easier way to tell them apart.

- [ ] From the Main Menu open **Manage Library**, choose **Restore…** and pick
  `interaction-duration-backup.zip`. The result says one package installed and two
  saves restored. Go to Load Game. Both rows first read `[Needs campaign] …
  Campaign package not installed.` That is known: the list was drawn before the
  restore finished. Press **Retry** on the **Resume battle** row. It becomes
  loadable (`Resume battle — Turn 1`). Load it. The map shows only those two
  units, at those HP and tiles. Say in Section 7 whether the stale
  "not installed" text confused you.
- [ ] Before attacking, note the Revenant's Resistance in Unit Details. Then move
  Hallowed Bearer next to the Revenant and attack it. If the attack misses, attack
  again on BLUE's next turn and start counting from the turn it hits. Once it hits, open
  the Revenant's Unit Details. It shows `Hallowed Sear` at `(2 phases)`, and
  Resistance shows `-3`. **Screenshot.**
- [ ] **From here on, do not attack again.** One more hit would kill the Revenant
  and end the test. On each later BLUE turn, give Hallowed Bearer **Wait** and end
  the phase. (If the Bearer misses twice before landing a hit, restore the backup
  and start 1B again. A third counter-attack could kill it.)
- [ ] End BLUE's phase from the map menu (**End Turn**) and let the AI play RED's phase. When BLUE's turn 2 begins,
  Unit Details shows `(1 phase)`. That is **one** step down, not two: both a BLUE
  and a RED phase went by, but only the phases of the side that applied it count.
  **Screenshot.**
- [ ] **Suspend & Quit** now, while the count is at `(1 phase)`, then **Continue**.
  Screenshot Unit Details and both units' HP and tiles, before and after. The
  count, the `-3` and both units' HP and tiles are unchanged.
- [ ] End BLUE's second phase and let RED play. When BLUE's turn 3 begins,
  Hallowed Sear is gone and Resistance is back to its value from before the hit.
  **Screenshot.**
- [ ] Record both units' HP and tiles at every screenshot above. The condition must
  have ended because its time ran out, not because a unit died or moved.

### 1C — Load Game with saves in it

v0.8.4 only ever showed Load Game empty. Do this check during Section 5, at the
point it tells you to. By then the list has real saves in it, some loadable and
one not.

- [ ] At 1280×720 and 1.0×, open Load Game. Take a screenshot that includes at least
  one save you can load and at least one that cannot, meaning it shows
  **Retry** / **Manage Campaigns** rather than loading. A freshly restored row that
  you have not pressed Retry on yet counts as one that cannot load. For each row,
  the save name, all three detail lines and the buttons (Load, Retry, Manage
  Campaigns, Delete, Export) are readable and do not clip or overlap one another.
  **Screenshot.**
- [ ] Record which campaign packs are installed and which font the screen is
  using. `internal.zip` names no font of its own, so with it active the screen
  uses the game's standard font.

## 2 — Carried from v0.8.4 (editor and font fixes)

- [ ] At 1920×1080, open **Manage Library**, select `free-roam.zip` and choose
  **Edit a Copy…**. This opens Campaign Editor on a working copy. Opening Campaign
  Editor from the Main Menu instead gives an empty editor with no working copy.
  In the working copy, The default
  Campaign record fits entirely in the window. Its **Rules** value wraps to at most
  six lines, ends in `…`, and shows the full value when you hover over it.
- [ ] Change one Campaign value and save it. The tab shows unsaved changes until
  the save finishes, then shows none. Close the editor and confirm Menu Scale is
  back to what it was.
- [ ] With `free-roam.zip` active, its font is used on Settings, the HUD, the Map
  Menu, Prep and the attack forecast. No text is clipped or overlapping, and no
  letters are replaced by boxes.
- [ ] With `free-roam.zip` active, Campaign Editor still uses the game's own
  standard font, not the campaign's.
- [ ] Switch back to no campaign pack. The standard font comes back everywhere,
  and the HUD, Map Menu and Prep have no clipped or overlapping text.

## 3 — Attack forecast and weapon relationships

These use the Proving Grounds campaign in `free-roam.zip`.

- [ ] **Chapter 3 — The Commander.** Attack the Bridge Fighter with Unit_06
  (Knight, Iron Lance). The attacker's column shows
  `▼ Weapon Triangle -10 Hit, -2 Dmg`. The defender's column shows both
  `▲ Weapon Triangle +10 Hit, +2 Dmg` and `▲ Weapon Effectiveness ×3 Might`.
- [ ] Look at that forecast at 1280×720 and 1920×1080 (three columns side by side),
  900×760 (More Info moves below the other two), and 560×900 (all three stacked).
  Set both scales to 1.0× first. At 900×760 a fresh profile picks 0.5×, and at 0.5×
  there is room for three columns, so More Info correctly stays beside the others.
  At 1280×720, repeat it at 0.5× and 2×. In every case the two defender rows are
  separate and readable. Nothing overlaps the terrain card, the totals or More
  Info. The whole forecast stays on screen. **Screenshot each.** Say whether the
  stacked 560×900 layout is still easy to compare.
- [ ] **Prologue:** Unit_02 (sword) against the lance dummy shows a disadvantage
  row under Unit_02 and an advantage row under the dummy. Unit_01 (lance) against
  a lance shows no row.
- [ ] **Chapter 1:** Unit_04 (Fire) against E2_Mage (Thunder) shows no row, because
  anima is neutral to anima.
- [ ] **Chapter 3:** Unit_04 (Fire) against the Chapel Bishop's light tome shows
  the magic-triangle rows, `+10 Hit/+2 Dmg` and `-10 Hit/-2 Dmg`.
- [ ] **Chapter 1:** equip Unit_01's Horseslayer, then attack E3_Cavalier. The
  forecast shows `▲ Weapon Effectiveness ×3 Might`, and the damage number
  changes by exactly what that row adds.
- [ ] You can reach every row with the mouse, and with the `F` key or pad button
  2 (More Info cycle). The on-screen hint says that Enter confirms the attack, and
  it does.

## 4 — Internal campaign: Chapter 6

`internal.zip` is private. Do not share it, stream it or include it in anything
public, and delete your copy when this round closes.

- [ ] Play the internal campaign to Chapter 6 with Hallowed Bearer and Free Company
  Axeman both alive. Their stats other than weapons are identical.
- [ ] Against the same Revenant, Hallowed Bearer's forecast shows
  `Hallowed Rites +5 Dmg` and the Axeman's shows `Undead Frailty +1 Dmg`. Record
  Hit, Dmg and Crit for both.
- [ ] Bearer's forecast does **not** show Undead Frailty. Open Hallowed Rites
  through More Info. It says `Overrides in this fight: Undead Frailty.` and
  contains no internal names with underscores, such as `undead_frailty`.
- [ ] Land a Hallowed hit. The Revenant's Unit Details names `Hallowed Sear` and
  shows `-3` with the phases left. The Resistance breakdown lists the same
  condition and adds up to the total shown. (The countdown itself is Section 1B.)

## 5 — Saves, packs, dialogs and diagnostics

- [ ] Restore `campaign_backup_v2.zip` through **Manage Library → Restore…**.
  **Before pressing Retry on its row, do Section 1C now**: the list then has this
  row still reading `[Needs campaign]` next to the 1B saves. If none of the 1B rows
  is loadable, press Retry on one of them first.
- [ ] Then press **Retry** on the `campaign_backup_v2.zip` row. Its save loads
  back to the right campaign and Prep screen.
- [ ] Import `migration-v1.zip` and `migration-v2.zip` and use their saves. When a
  save is refused, the message names the missing or mismatched content in plain
  language, not only an internal id.
- [ ] Import `collision-a.zip` and `collision-b.zip`. They share an id and a
  version number but have different content. Where both appear, the rows tell
  them apart with a short fingerprint. A save made with one is not silently
  loaded with the other.
- [ ] Check all four confirmation dialogs: **End Turn**, **Suspend & Quit**,
  **Quit to Menu** (when it would lose progress) and **replace a save**. Each one
  says what Enter will do and starts with the safe choice selected.
- [ ] Settings is usable below 600 px wide, and at 0.5× and 2×. It is one long
  scrolling list: reach the bottom rows with the mouse wheel, the scroll bar or the
  arrow keys, and say which of those worked.
- [ ] Export Diagnostics produces a readable ZIP of this session. It names v0.8.6,
  Windows, your GPU, display, DPI and window mode, and the packs installed and
  active.

## 6 — Automated pre-pass (included for reference; nothing to run)

Before handoff, these ran against the web export built from the same source
commit. Their receipts, reports and screenshots are in the bundle:

- **Supplemental Playwright gate** (`screenshot-album/`,
  `playwright-supplemental-gate-receipt.json`): 40 screen/size cases across
  Main Menu, Load Game, Settings, New Game, Prep, HUD, Results and Game Over. Its
  HUD shots are taken **without** a live map (the Main Menu shows behind them), so
  it does **not** cover 1A. Its Game Over shots show the placeholder title
  `Victory!` because the harness opens that screen without a battle result. Both
  are known and need no report.
- **Pack gate** (`pack-gate-evidence/`, `bundle-pack-gate-receipt.json`): all six
  packs import and every campaign entry reaches a live map. This checks that the
  maps can be reached, not how their text looks, so it does **not** cover 1A
  either.

Neither covers the Campaign Editor, native windowing/DPI, controller input or the
release-build countdown. Those are the manual checks above.

- [ ] Skim both evidence folders. Report anything you notice that is clipped,
  overlapping or showing boxes instead of letters.

## 7 — Your judgement

- [ ] With two relationship rows in one forecast, are both readable and useful?
- [ ] Does the More Info explanation make it clear why Undead Frailty is missing
  from Bearer's forecast, for someone who does not already know?
- [ ] Do the relationship names read as game language or as programmer labels?
- [ ] Do the condition name, its countdown and its `-3` explain the Resistance
  shown?
- [ ] In 1B, does it make sense to a player that the count went down once, not
  twice, over a BLUE phase and a RED phase?
- [ ] Anywhere a number appears in the pixel font, can you tell `1` from `I` at a
  glance? The v0.8.5 browser walk misread `(1 phase)` as `(2 phase)`.
- [ ] When the Objectives box shrinks to its title at 1280×720 and 2×, is it
  obvious that it will come back, and is the trade-off acceptable?
- [ ] Is the game playable, clear and polished as it stands? (This is not about
  whether the campaign is hard enough or balanced.)
- [ ] Return this checklist, the diagnostics ZIP, the screenshots, your Windows,
  GPU and display details, the BUILD STAMP, which sections you ran, and any save
  needed to reproduce a failure.
- [ ] Confirm you have deleted your copy of `internal.zip`.

Native acceptance stays pending until this evidence has been reviewed.
