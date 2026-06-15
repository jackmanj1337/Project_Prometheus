# Playtester Handbook and Checklist - v0.1.4

This document is written for testers who have not read the design documents
or source code. Everything needed for this test pass is included below.

## Before you begin

### Required build and equipment

- Windows 10 or 11, 64-bit
- Keyboard and mouse
- Executable: `Project_Prometheus_v0.1.4_debug.exe`
- Expected file size: `101,199,464` bytes
- Expected SHA-256:
  `b8aa878399b9315ab78496acaf0b24cc88dabda12d55c9fd09665f7a0dc4ee16`

The executable is a standalone debug build. It does not need Godot or an
installer. Do not disable antivirus or other security software to run it. If
Windows blocks or quarantines it, record the exact message and contact the
person who supplied the build.

Optional PowerShell integrity check:

```powershell
Get-FileHash .\Project_Prometheus_v0.1.4_debug.exe -Algorithm SHA256
```

The result must match the expected SHA-256 above.

### Tester information

- **Tester name:** _Enter name._
- **Test date:** _Enter date._
- **Windows version:** _Enter version._
- **Primary resolution:** _Enter resolution._
- **Input method:** _Keyboard/mouse or other._
- **Build hash verified:** _Yes / No._

### How to record results

Complete the sections in order. Checks are grouped by the map that provides
the fastest reliable setup. State-changing, map-ending, and Retry checks are
placed last so earlier checks can reuse the same run.

Only check **This item works as expected** after every expectation in that
item passes. Record failures as:

`Map / Unit or UI / Step / Actual / Expected / Repro`

For visual failures, include the window resolution and a screenshot.
On Windows, `Win+Shift+S` opens the Snipping Tool.

If a check cannot be performed, leave it unchecked and write `NOT RUN` with
the reason. Do not check an item merely because no problem was noticed.

If the game crashes or stops accepting input, record the active map, unit,
last action, and visible screen. Close the game, preserve `godot.log`, relaunch
the executable, and continue with the next independent check.

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
| Toggle Force Level Up debug aid | `F10` |
| Toggle Growth Boost debug aid | `F11` |

Settings contains a read-only list of most controls. `F`, `F10`, and `F11`
are listed here because they are required by this handbook.
When `Mouse Cursor` is enabled in Settings, moving the mouse can also move the
map cursor.

### Basic play flow

1. From the Main Menu, choose `New Game`.
2. Choose the requested map and settings, then choose `Start`.
3. Move the cursor onto a Blue unit and Confirm to select it.
4. Move within the highlighted movement area and Confirm a destination.
5. Choose an action such as `Attack`, `Item`, `Pair Up`, or `Wait`.
6. For an attack, choose a target, review the forecast, and Confirm again to
   resolve combat. Cancel backs out without committing the attack.
7. To end a phase early, press `M`, choose `End Turn`, and confirm the warning
   if units have not acted.
8. To abandon a run, press `M`, choose `Exit to Main Menu`, and confirm.
9. After Victory or Defeat, `Retry` reloads that map's original starting state.

To identify a named unit, move the cursor over units and read the HUD name.
Press `I` to confirm the unit's name, class, level, stats, skills, and weapon
ranks. Unit and enemy names used below appear exactly as written in the game.

`F10` is a toggle, not a one-use command. While enabled, the HUD debug banner
includes `force-levelup`. Press `F10` again immediately after the requested
level-up so later checks use normal experience.

### Terms used in this handbook

- **Phase:** one faction's opportunity to act. A full turn/round ends after
  every faction in the map's cycle has completed its phase.
- **Blue / Green / Red / Yellow:** faction colors. Blue and Green may be
  allied, but they remain separate factions.
- **Rout:** defeat every unit in the specified opposing faction or alliance.
- **Lead / support:** when two units Pair Up, the lead stays on the map and
  acts; the support is hidden off-map and supplies bonuses.
- **DONE:** the unit has spent its action for the current phase and appears
  greyed out.
- **Combat preview / forecast:** the panel shown before confirming an attack.
- **HP / Atk / Hit / Crit:** health, attack power, hit chance, and critical-hit
  chance.
- **Str / Mag / Skl / Spd / Def / Res / Lck:** Strength, Magic, Skill, Speed,
  Defense, Resistance, and Luck.
- **Battle Speed:** the value used to determine follow-up attacks. A unit
  needs at least 5 more Battle Speed than its opponent to follow up.
- **`floor(value)`:** round down to the nearest whole number.
- **More Info:** contextual details opened or cycled with `F`.
- **Fixed growth:** deterministic leveling. `Fixed N / 100` shows progress
  toward that stat's next increase.
- **Configured/authored condition:** a victory or defeat rule explicitly set
  for that map. The game must not invent an unlisted Rout condition.
- **One-based coordinates:** the displayed top-left tile is `(1, 1)`, even
  though internal map data starts at zero.

## Coverage limits

- The current Map 950 fixture verifies the fifth equipped-skill slot, but it
  does not contain a unit learning a sixth skill. Sixth-skill overflow remains
  covered by automated tests rather than this live pass.
- Current class weapon-rank caps are verified by automated tests. The build
  does not provide a fast live fixture near enough to the A-rank cap to make a
  manual cap test practical.
- The deferred issues near the end are known limitations, not failed checks.

---

## 1. Non-map-specific UI commentary

Complete these checks before launching the first map.

### 1.1 Version label

Open the executable.

**Expected**

- The Main Menu opens without an engine error.
- A small grey `v0.1.4` label appears at the bottom-right.
- A missing or different version means the tester has a stale build.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 1.2 New Game options and remembered values

Open New Game and confirm the `Map`, `Pair Up`, `Auto Promote`, and
`Leveling Method` controls are present. Change `Pair Up` and `Auto Promote`,
close the panel, and reopen it.

**Expected**

- All expected controls are present.
- The changed values are remembered after closing and reopening the panel.
- Leave `Pair Up: On` and `Auto Promote: Off` for the first map pass.

- [ ] **This item works as expected.**

**Tester comments:** Map settings are only remembered when map is started and exited, but not when settings are altered but exited before starting the map.

### 1.3 Settings round-trip

Open Settings, change `mouse_cursor`, back out, and reopen Settings.

**Expected**

- The changed value persists.
- Backing out and reopening does not leave the menu stuck or visually corrupt.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 1.4 Mouse wheel does not affect the background

Open New Game. Hover over the title, every dropdown, and empty panel space.
Scroll up and down five times in each location, then close the panel.

**Expected**

- The New Game panel does not scroll.
- The title-screen background or camera does not drift.
- Closing New Game returns to the same Main Menu view.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 1.5 New Game panel centering

Check the New Game panel at `1280x720`. If resizing is available, check it
again at another resolution.

**Expected**

- The panel has visually equal left and right margins.
- The `New Game` heading is centered.
- The panel remains centered after the viewport width changes.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### General non-map UI comments

_Enter comments about menu readability, wording, focus, or navigation that do
not belong to a specific check._

---

## 2. Map 001 - Rout

Use `Map 001 - Rout` for baseline map UI, combat preview, Pair Up flow, and
authored Rout defeat. Keep `Pair Up: On`.

### 2.1 Launch and one-based terrain coordinates

Launch the map through New Game. Move the cursor to the upper-left map tile,
then one tile to the right.

**Expected**

- The normal default campaign roster loads.
- The Terrain panel shows `Tile (1, 1)` at the upper-left tile.
- One tile to the right shows `Tile (2, 1)`.
- Terrain name, defense, and dodge remain readable.
- The display never exposes internal zero-based coordinates such as
  `Tile (0, 0)`.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 2.2 Movement cancel restores unit and cursor

Select a Blue unit, confirm a legal move, and wait for the Action Menu. Press
Cancel (`B`, `Esc`, or right-click).

**Expected**

- The unit returns to its original tile.
- The cursor returns to the same original tile.
- The movement overlay reappears for another destination choice.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 2.3 Terrain More Info layout

Hover terrain and open More Info. Check at least one terrain entry with a long
description, movement costs, and action text. Close More Info afterward.

**Expected**

- The compact Terrain panel stays at the bottom-right.
- A separate details box opens above it.
- The details box has a bounded height and scrolls instead of growing
  off-screen.
- The details box does not cover the compact terrain stats.
- Closing More Info removes only the details box.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 2.4 Combat preview base layout and no-counter state

Open a combat preview against an enemy that can counter. Then preview an enemy
that cannot counter. An easy no-counter setup is an Archer attacking a
melee-only enemy from two tiles away.

**Expected**

- The panel sizes to its content instead of stretching vertically.
- Both sides show readable Name, HP, Damage, Hit, and Crit information.
- The forecast is populated rather than blank.
- `No counter` remains visible when appropriate.
- Unused defender Hit and Crit rows collapse without blank space or overlap.

- [x] **This item works as expected.**

**Tester comments:**  combat preview window shifts position with the right edge centered on the attacking unit, possibly overlapping  with the unit info window or the objecive widow.

### 2.5 Combat preview More Info and narrow resolution

Open a combat preview and cycle More Info. Use a matchup that displays both
weapon-triangle and effectiveness information if one is available. A sword
against a lance, or a lance against a sword, provides a triangle matchup. If
no effective weapon is available, write `NOT AVAILABLE` for that substep and
continue. Repeat at `960x540` if window resizing is available.

**Expected**

- The base forecast remains visible while More Info is open.
- Description, triangle, effectiveness, crit, and Vantage rows do not overlap.
- Every visible row remains readable and on-screen.
- At `960x540`, the preview stays bounded and does not expand to nearly the
  full viewport height.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 2.6 Pair creation, DONE state, and hidden-support handling

Move a Blue unit next to an unpaired Blue ally. Choose `Pair Up`, target the
ally, and then cycle through available units. Finish every remaining Blue
unit's action.

**Expected**

- Same-faction Pair Up is available.
- The support sprite leaves the map and the lead remains on its tile.
- Both units become DONE/greyed.
- Unit cycling never selects the support's off-map position.
- The hidden support is not counted as waiting, so the phase ends normally
  when all visible Blue units are done.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 2.7 Swap costs the action

On the next Blue phase, select the paired lead and choose `Swap`.

**Expected**

- Lead and support roles trade places.
- The new lead remains on the original map tile.
- Both units become DONE.
- The pairing remains valid after the action.

- [ ] **This item works as expected.**

**Tester comments:** Choosing the swap action does not change the lead unit, only expending the paired unit's activation with the original lead remaining on the map.

### 2.8 Authored allied Rout defeat

Do this last because it ends the run. Allow every allied unit to be defeated.

**Expected**

- A defeat screen appears because Map 001 explicitly authors allied Rout
  defeat.
- The game does not remain on an unwinnable map.

- [ ] **This item works as expected.**

**Tester comments:** After non paired allies were killed, red units left paired archer alone and made a beeline for (1,1) and blue phase stopped auto-completing. Red only attacked the archer after moving adjacent, but the paired ally did not return and map did not end.

---

## 3. Map 002 - Seize

Use one run for all three checks. Do not Seize until every Red unit has been
defeated. The Seize point is the throne at displayed coordinate `(16, 3)`;
the boss begins on it. Move the Cavalier and one other Blue unit toward the
throne while fighting so both eligibility checks fit within the turn limit.

### 3.1 Routing Red does not win

Defeat every Red unit without using Seize.

**Expected**

- The map remains active.
- No victory screen appears.
- Hostile Rout is not configured as a Blue victory condition.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 3.2 Seize eligibility is unit-specific

After defeating Red, move a Blue unit other than the Cavalier onto `(16, 3)`
and open the Action Menu. Cancel the Action Menu to undo that move. Then move
the default Cavalier onto the same tile.

**Expected**

- The non-Cavalier is not offered `Seize`.
- The Cavalier is offered `Seize`.
- Only the configured eligible unit can complete the objective.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 3.3 Seize resolves the map

After the Red units are defeated, move the eligible Cavalier onto the Seize
tile and choose `Seize`.

**Expected**

- The victory screen appears immediately.
- The objective does not require another End Turn.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

---

## 4. Map 003 - Defeat Boss

This map is won by defeating the named boss, not by routing every enemy. The
boss is `Bandit Chief`, who begins near the right side of the map. Use the HUD
name or `I` to identify him.

### 4.1 Boss defeat wins while another enemy remains

Keep at least one non-boss Red unit alive. Defeat `Bandit Chief`.

**Expected**

- Victory appears immediately when the boss is defeated.
- The remaining non-boss enemy does not need to be defeated.
- The map does not require another End Turn.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 4.2 Protected Cavalier death causes defeat

Choose `Retry` after the victory, or relaunch Map 003. Allow the default
Cavalier to be defeated while `Bandit Chief` is still alive.

**Expected**

- Defeat appears immediately because the Cavalier is the protected unit.
- The game does not remain on an unwinnable map.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

---

## 5. Map 004 - Escape

This section needs three short runs because each objective branch ends or
invalidates the others. The Escape tiles are the three right-edge tiles at
displayed coordinates `(17, 3)`, `(17, 4)`, and `(17, 5)`.

### Run 1: single escape followed by required-unit defeat

### 5.1 One required unit escaping is not enough

Launch Map 004. The required units are the default Cavalier and Mercenary.
Move one required unit onto an Escape tile and choose `Escape`.

**Expected**

- That unit is removed from the map and recorded as escaped.
- The map remains active because the other required unit has not escaped.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 5.2 Required-unit death causes immediate defeat

Continue Run 1 and allow the remaining required unit to die.

**Expected**

- The defeat screen appears immediately.
- The map does not remain in an unwinnable state.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### Run 2: paired escape

### 5.3 Paired lead and support escape together

Restart Map 004. Pair the two required units, move the lead onto an Escape
tile on the next Blue phase, and choose `Escape`. Pair Up spends both units'
actions, so moving on that same phase is not expected.

**Expected**

- Both lead and support are removed.
- Both are counted as escaped.
- No off-map support remains as a ghost objective unit.
- The victory screen appears when both requirements are satisfied.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### Run 3: enemy Rout is not victory

### 5.4 Routing Red while a required unit remains does not win

Restart Map 004. Defeat every Red unit while at least one required Escape unit
is still on the map.

**Expected**

- The map remains active.
- No victory screen appears.
- Rout is not inferred on an Escape map.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

---

## 6. Map 005 - Defend

The two Defend tiles are displayed coordinates `(4, 6)` and `(4, 7)`, near
the Blue starting area. Victory requires surviving six complete turns while
an allied unit occupies at least one of those tiles when Turn 7 begins.

### 6.1 Survive six turns while holding a Defend tile

Keep the default Cavalier alive. Place any Blue unit on `(4, 6)` or `(4, 7)`
before the end of Turn 6 and keep that unit there through the remaining
faction phase. Use `M` -> `End Turn` to advance when ready.

**Expected**

- No victory appears at the start of Turns 2 through 6.
- The HUD turn number advances once per complete Blue/Red cycle.
- Victory appears when control would return to Blue for Turn 7, provided a
  living allied unit still occupies a Defend tile.
- Defeating Red early does not replace the configured Survive/Defend
  objective with an automatic Rout victory.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

---

## 7. Map 900 - Hotseat Validation

Complete this section in one uninterrupted faction cycle. It covers faction
ownership, controller handoff, turn counting, camera memory, danger zones, and
the two closed hotseat regressions.

### 7.1 Blue startup and cross-faction Pair Up restriction

At the start of Blue's phase, confirm the HUD reads `Turn 1`. Move a Blue unit
next to a Green unit and open the Action Menu.

**Expected**

- Blue starts under Player 1 control.
- Blue units are selectable and Green units are not.
- `Pair Up` is not offered between Blue and Green. They are allied, but they
  belong to different factions.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 7.2 Full faction cycle, labels, and handoff

End Blue, play/end Green, and watch Red and Yellow act. Check the HUD and phase
banner as each phase starts.

**Expected**

- Blue: `Blue - Player 1`
- Green: `Green - Player 2`
- Red: `Red Raiders - AI`
- Yellow: `Yellow Rogues - AI`
- A `PHASE` suffix or capitalization difference is acceptable if faction and
  controller ownership agree.
- The HUD remains on `Turn 1` during Green, Red, and Yellow.
- Red and Yellow complete in order without a hang.
- Control returns cleanly to Blue.
- The HUD changes to `Turn 2` only when Blue returns.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 7.3 Green combat preview uses the active side

During Green's phase, use a Green combat unit to target a hostile Red or Yellow
unit.

**Expected**

- The normal populated combat preview opens.
- The preview uses Green as the active attacker.
- It does not open a partial More Info panel with missing combat data.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 7.4 Faction-specific camera and danger zone

During Blue's phase, pan to a memorable view before ending the phase. During
Green's phase, move the cursor toward another map edge until the camera pans
elsewhere, then press `Q`. Finish the faction cycle.

**Expected**

- Green's danger overlay shows units hostile to Green, not a stale Blue view.
- Red and Yellow phases do not overwrite the saved player camera views.
- Blue's saved view is restored when Blue control returns.

- [ ] **This item works as expected.**

**Tester comments:** Could not test, as all scrollable tiles fit within the single screen.
### General Map 900 comments

_Enter comments about faction readability, controller handoff, AI pacing, or
camera behavior that do not belong to a specific check._

---

## 8. Map 950 - Promotion Validation

First run setup:

- `Pair Up: On`
- `Auto Promote: Off`
- `Leveling Method: Fixed`
- Use the authored 12-unit fixed roster.

Apply the Strength Tonic early. Its four-turn duration can expire while the
other checks are completed. Save the Victory/Retry check for the end of the
first run. The final Auto Promote check requires one restart.

### 8.1 Roster and promoted General skills

Launch Map 950 and inspect `M950_General`, a level-20 promoted
Knight-to-General.

**Expected**

- The fixed roster contains 12 units.
- The General has both `bastion` and `iron_wall` equipped.
- Neither skill is missing or only present as an unshown earned skill.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 8.2 Growth and fixed-growth details

Inspect any growing player unit and open More Info for several stat rows.
Record at least one `Fixed N / 100` value. Leave this checkbox open until a
later Map 950 level-up, then inspect the same stat again.

**Expected**

- Each stat shows `Base` and `Effective`.
- Each stat shows `Growth N%`.
- Each stat shows `Fixed N / 100`.
- In `growth_fixed` mode, the fixed value advances on level-up and returns to
  `0` when that stat increases.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 8.3 Four Battle Speed does not follow up

Preview `M950_Mage` attacking `M950_E1_Soldier`, `M950_E2_Soldier`, or
`M950_E3_Soldier` without Pair Up or temporary stat modifiers.

**Expected**

- The Mage's authored Battle Speed is 7.
- The Soldier's authored Battle Speed is 3.
- The Mage attacks once, not twice, because a difference of 4 is below the
  current follow-up threshold of 5.

- [ ] **This item works as expected.**

**Tester comments:**  Both combatants only attack once, but cannot confirm exact combat speed values, as they are not displayed in combat preview.

### 8.4 Strength Tonic modifier and expiration

Use `M950_Mercenary` -> Action Menu -> Item -> `Strength Tonic`. Inspect the
Strength row immediately, then inspect it again after four full turns.

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

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 8.5 Pair Up bonuses match preview and live combat

Move `M950_Hero_SkillCap` and `M950_Cavalier` near the same melee target.
Before pairing, record the Hero's forecast and cancel. Pair the Hero as lead
with the Cavalier as support. Advance to the next Blue phase, then preview and
complete the same attack. Pair Up spends both units' actions, so attacking on
the pairing phase is not expected.

The support bonus is:

- Flat Cavalier bonus: `+1 Str`, `+1 Def`, `+1 Spd`
- Scaling bonus: `floor(support stat / 4)` for Str, Mag, Skl, Spd, Def, Res,
  and Lck

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

- The paired forecast improves by the authored support contribution where
  those stats affect combat.
- Preview Atk, Hit, and follow-up calculations reflect the bonuses.
- Live damage matches the preview, except for normal miss or critical RNG.
- A result such as `preview says 12, live fight deals 9` is a failure.

- [ ] **This item works as expected.**

**Tester comments:** Testing was difficult, as enemies are weak enough that they often died before post pairup attack could be previewed, but no change in stats was seen post-pairup, whether on unit info, nor did combat preview numbers change.

### 8.6 Demotion stats, skills, and menu layout

Record `M950_General`'s Strength, Defense, Speed, Skill, Movement, displayed
level, and skills. Use the General's `Second Seal` and choose the tier-1
`Soldier` option.

**Expected**

- The Second Seal is usable and the long option list remains on-screen.
- Every option is reachable by keyboard or mouse scrolling.
- Option labels use `old +/-delta -> new / cap`.
- Class base contributions are replaced rather than stacked.
- Personal earned gains are preserved.
- Strength, Defense, Speed, Skill, and Movement change by the class-base
  difference.
- Displayed level resets to 1.
- The new class's level-1 skill is granted.

- [x] **This item works as expected.**

**Tester comments:** Stats changed, but Soldier had no starting skill, but General's existing skills remained. reclassing to Mercenary correctly granted armsthrift. 

### 8.7 Promotion item becomes usable at level 20

Select `M950_Lvl19_Merc` before leveling and open the Action Menu. Turn on
`F10`, complete a successful EXP-granting combat against
`M950_E1_Soldier`, then turn `F10` off. On the next turn, open the Action Menu
and use the Master Seal.

**Expected before level 20**

- `Item` is hidden because the Master Seal has no legal use yet.

**Expected at level 20**

- `Item` appears on the next selection.
- The item list shows `Master Seal (1)`.
- Confirming it opens the promotion modal.
- `Hero`, `Sentinel`, and `Bow Knight` are offered.

- [x] **This item works as expected.**

**Tester comments:** The correct options are presented but promotion window is not centered running off right hand edge of screen (950MERC Promotion.png)

### 8.8 Fifth equipped-skill slot

Before leveling, inspect `M950_Hero_SkillCap`.

**Expected before level 15**

- Equipped skills are `armsthrift`, `patience`, `dash`, and `discipline`.
- One of the five default equipped-skill slots is open.

Use `F10`, complete a successful EXP-granting combat to earn level 15, turn
`F10` off, and inspect the unit again.

**Expected after level 15**

- The level-up screen reports `disarm` learned.
- `disarm` appears with the existing four equipped skills.
- No existing skill is overwritten and no crash occurs.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 8.9 Staff use honors Force Level Up

Use `F10` to enable Force Level Up. Have `M950_Cleric` successfully use a
staff, then disable Force Level Up with `F10`.

**Expected**

- The debug indicator shows Force Level Up while enabled.
- A successful staff use triggers the forced level-up path.
- Disabling the aid removes the active debug state.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 8.10 Retry restores the original class state

Do this last in the first run. After demoting `M950_General` to Soldier,
defeat every Red unit. On the Victory screen, choose `Retry`, then inspect the
General. Victory and Defeat use the same map-start Retry snapshot.

**Expected**

- The unit returns to General at its original displayed level.
- Original stats, weapon ranks, inventory, and skills are restored.
- No Soldier state remains.
- The error log does not report a snapshot rejection or `push_error`.

- [x] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 8.11 Auto Promote at the level cap

Return to New Game, set `Auto Promote: On`, and relaunch Map 950. Use
`M950_Lvl19_Merc` to gain level 20 again. Turn on `F10` before the successful
combat and turn it off after the level-up flow.

**Expected**

- The promotion modal opens immediately after the level-up animation.
- The Master Seal does not need to be selected manually.
- The modal offers `Hero`, `Sentinel`, and `Bow Knight`.

- [x] **This item works as expected.**

**Tester comments:** Promotion window encounters the same placement bug as encountered in step 8.7

### General Map 950 comments

_Enter comments about progression clarity, class-choice wording, stat-change
presentation, or menu readability that do not belong to a specific check._

---

## 9. All-map error-log check

The Windows executable may not display a separate debug console. After the
test pass, close the game and inspect:

`%APPDATA%\Godot\app_userdata\Fire Emblem RPG\logs\godot.log`

Paste that path into Windows Explorer's address bar. If the file does not
exist, record `LOG FILE NOT FOUND`; that is useful build feedback.

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

These messages indicate content/configuration defects even if the game does
not crash. Record the complete message and the active map. Also report any
line containing `ERROR`, `SCRIPT ERROR`, or a crash stack trace.

- [ ] **This item works as expected.**

**Tester comments:** 11829 instances of the following error
ERROR: DataManager: unknown weapon id 'iron_axe'
   at: push_error (core/variant/variant_utility.cpp:1024)

---

## 10. Known deferred issues

Do not report the unchanged behavior below as a v0.1.4 regression:

- Camera limits do not include viewport-aware overscan for edge panels.
- Mouse-follow camera catch-up remains abrupt.
- Clicking the Map Menu backdrop does not dismiss the menu.
- `Q` toggles the full danger zone; per-enemy threat inspection is not
  implemented.

Report behavior in these areas only if it is worse than described.

### Deferred-issue comments

It would be nice if the danger zone overlay was able to remain visible but distinct when moving a player controlled unit.

---

## 11. What to send back

Return:

1. This completed handbook with every applicable checkbox marked.
2. Tester comments for every failed or unclear item.
3. Error-log output for any validation error.
4. Screenshots for combat-preview, terrain, camera, or menu-layout failures.
5. Exact repro steps using the failure format at the top of this document.
6. The `godot.log` file, or a note that it was not found.
