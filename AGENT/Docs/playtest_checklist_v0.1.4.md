# Playtester Handbook and Checklist - v0.1.4

Use this handbook with:

- Build: `builds/Project_Prometheus_v0.1.4_debug.exe`
- Build details: `AGENT/Docs/playtest_build_v0.1.4.md`

Complete the sections in order. Checks are grouped by the map that provides
the fastest reliable setup. State-changing, map-ending, and retry checks are
placed last so earlier checks can reuse the same run.

Only check **This item works as expected** after every expectation in that
item passes. Record failures as:

`Map / Unit or UI / Step / Actual / Expected / Repro`

For visual failures, include the window resolution and a screenshot.

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

- [ ] **This item works as expected.**

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

**Tester comments:** _Enter comments here._

### 1.3 Settings round-trip

Open Settings, change `mouse_cursor`, back out, and reopen Settings.

**Expected**

- The changed value persists.
- Backing out and reopening does not leave the menu stuck or visually corrupt.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 1.4 Mouse wheel does not affect the background

Open New Game. Hover over the title, every dropdown, and empty panel space.
Scroll up and down five times in each location, then close the panel.

**Expected**

- The New Game panel does not scroll.
- The title-screen background or camera does not drift.
- Closing New Game returns to the same Main Menu view.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 1.5 New Game panel centering

Check the New Game panel at `1280x720`. If resizing is available, check it
again at another resolution.

**Expected**

- The panel has visually equal left and right margins.
- The `New Game` heading is centered.
- The panel remains centered after the viewport width changes.

- [ ] **This item works as expected.**

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

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 2.2 Movement cancel restores unit and cursor

Select a Blue unit, confirm a legal move, and wait for the Action Menu. Press
Cancel (`B`, `Esc`, or right-click).

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
- The details box has a bounded height and scrolls instead of growing
  off-screen.
- The details box does not cover the compact terrain stats.
- Closing More Info removes only the details box.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 2.4 Combat preview base layout and no-counter state

Open a combat preview against an enemy that can counter. Then preview an enemy
that cannot counter.

**Expected**

- The panel sizes to its content instead of stretching vertically.
- Both sides show readable Name, HP, Damage, Hit, and Crit information.
- The forecast is populated rather than blank.
- `No counter` remains visible when appropriate.
- Unused defender Hit and Crit rows collapse without blank space or overlap.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 2.5 Combat preview More Info and narrow resolution

Open a combat preview and cycle More Info. Use a matchup that displays both
weapon-triangle and effectiveness information if one is available. Repeat at
`960x540` if window resizing is available.

**Expected**

- The base forecast remains visible while More Info is open.
- Description, triangle, effectiveness, crit, and Vantage rows do not overlap.
- Every visible row remains readable and on-screen.
- At `960x540`, the preview stays bounded and does not expand to nearly the
  full viewport height.

- [ ] **This item works as expected.**

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

- A defeat screen appears because Map 001 explicitly authors allied Rout
  defeat.
- The game does not remain on an unwinnable map.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

---

## 3. Map 002 - Seize

Use one run for all three checks. Do not Seize until every Red unit has been
defeated.

### 3.1 Seize eligibility is unit-specific

Move the default Cavalier, whose `can_seize` flag is enabled, onto the authored
Seize tile. Check the Action Menu, cancel, and then place a different Blue unit
on the same tile.

**Expected**

- The Cavalier is offered `Seize`.
- A different Blue unit is not offered `Seize`.
- Eligibility comes from the unit's authored `can_seize` flag.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 3.2 Routing Red does not win

Defeat every Red unit without using Seize.

**Expected**

- The map remains active.
- No victory screen appears.
- Hostile Rout is not inferred as a Blue victory condition.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 3.3 Seize resolves the map

After the Red units are defeated, move the eligible Cavalier onto the Seize
tile and choose `Seize`.

**Expected**

- The victory screen appears immediately.
- The objective does not require another End Turn.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

---

## 4. Map 004 - Escape

This section needs three short runs because each objective branch ends or
invalidates the others.

### Run 1: single escape followed by required-unit defeat

### 4.1 One required unit escaping is not enough

Launch Map 004. The required units are the default Cavalier and Mercenary.
Move one required unit onto an Escape tile and choose `Escape`.

**Expected**

- That unit is removed from the map and recorded as escaped.
- The map remains active because the other required unit has not escaped.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 4.2 Required-unit death causes immediate defeat

Continue Run 1 and allow the remaining required unit to die.

**Expected**

- The defeat screen appears immediately.
- The map does not remain in an unwinnable state.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### Run 2: paired escape

### 4.3 Paired lead and support escape together

Restart Map 004. Pair the two required units, move the lead onto an Escape
tile, and choose `Escape`.

**Expected**

- Both lead and support are removed.
- Both are counted as escaped.
- No off-map support remains as a ghost objective unit.
- The victory screen appears when both requirements are satisfied.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### Run 3: enemy Rout is not victory

### 4.4 Routing Red while a required unit remains does not win

Restart Map 004. Defeat every Red unit while at least one required Escape unit
is still on the map.

**Expected**

- The map remains active.
- No victory screen appears.
- Rout is not inferred on an Escape map.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

---

## 5. Map 900 - Hotseat Validation

Complete this section in one uninterrupted faction cycle. It covers faction
ownership, controller handoff, turn counting, camera memory, danger zones, and
the two closed hotseat regressions.

### 5.1 Blue startup and cross-faction Pair Up restriction

At the start of Blue's phase, confirm the HUD reads `Turn 1`. Move a Blue unit
next to a Green unit and open the Action Menu.

**Expected**

- Blue starts under Player 1 control.
- Blue units are selectable and Green units are not.
- `Pair Up` is not offered between Blue and Green. They are allied, but they
  belong to different factions.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 5.2 Full faction cycle, labels, and handoff

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

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 5.3 Green combat preview uses the active side

During Green's phase, use a Green combat unit to target a hostile Red or Yellow
unit.

**Expected**

- The normal populated combat preview opens.
- The preview uses Green as the active attacker.
- It does not open a partial More Info panel with missing combat data.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 5.4 Faction-specific camera and danger zone

During Blue's phase, pan to a memorable view before ending the phase. During
Green's phase, pan elsewhere and press `Q`. Finish the faction cycle.

**Expected**

- Green's danger overlay shows units hostile to Green, not a stale Blue view.
- Red and Yellow phases do not overwrite the saved player camera views.
- Blue's saved view is restored when Blue control returns.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### General Map 900 comments

_Enter comments about faction readability, controller handoff, AI pacing, or
camera behavior that do not belong to a specific check._

---

## 6. Map 950 - Promotion Validation

First run setup:

- `Pair Up: On`
- `Auto Promote: Off`
- Use the authored 12-unit fixed roster.

Apply the Strength Tonic early. Its four-turn duration can expire while the
other checks are completed. Save the intentional defeat/Retry check for the
end of the first run. The final Auto Promote check requires one restart.

### 6.1 Roster and promoted General skills

Launch Map 950 and inspect `M950_General`, a level-20 promoted
Knight-to-General.

**Expected**

- The fixed roster contains 12 units.
- The General has both `bastion` and `iron_wall` equipped.
- Neither skill is missing or only present as an unshown earned skill.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 6.2 Growth and fixed-growth details

Inspect any growing player unit and open More Info for several stat rows.

**Expected**

- Each stat shows `Base` and `Effective`.
- Each stat shows `Growth N%`.
- Each stat shows `Fixed N / 100`.
- In `growth_fixed` mode, the fixed value advances on level-up and returns to
  `0` when that stat increases.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 6.3 Four Battle Speed does not follow up

Preview `M950_Mage` attacking `M950_E1_Soldier`, `M950_E2_Soldier`, or
`M950_E3_Soldier` without Pair Up or temporary stat modifiers.

**Expected**

- The Mage's authored Battle Speed is 7.
- The Soldier's authored Battle Speed is 3.
- The Mage attacks once, not twice, because a difference of 4 is below the
  current follow-up threshold of 5.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 6.4 Strength Tonic modifier and expiration

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

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 6.5 Pair Up bonuses match preview and live combat

Move `M950_Hero_SkillCap` and `M950_Cavalier` near the same melee target.
Before pairing, record the Hero's forecast and cancel. Pair the Hero as lead
with the Cavalier as support, then preview and complete the same attack.

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

**Tester comments:** _Enter comments here._

### 6.6 Reclass stats, skills, and menu layout

Record `M950_Knight`'s Strength, Defense, Speed, Skill, Movement, displayed
level, and skills. Use a `Second Seal` to reclass into a tier-1 option such as
Soldier.

**Expected**

- The reclass menu remains on-screen and every option is reachable.
- Option labels use `old +/-delta -> new / cap`.
- Class base contributions are replaced rather than stacked.
- Personal earned gains are preserved.
- Strength, Defense, Speed, Skill, and Movement change by the class-base
  difference.
- Displayed level resets to 1.
- The new class's level-1 skill is granted.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 6.7 Promotion item becomes usable at level 20

Select `M950_Lvl19_Merc` before leveling and open the Action Menu. Then defeat
`M950_E1_Soldier` and continue until the Mercenary reaches level 20. On the
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

### 6.8 Fifth equipped-skill slot

Before leveling, inspect `M950_Hero_SkillCap`.

**Expected before level 15**

- Equipped skills are `armsthrift`, `patience`, `dash`, and `discipline`.
- One of the five default equipped-skill slots is open.

Earn the level to 15 and inspect the unit again.

**Expected after level 15**

- The level-up screen reports `disarm` learned.
- `disarm` appears with the existing four equipped skills.
- No existing skill is overwritten and no crash occurs.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 6.9 Staff use honors Force Level Up

Use `F10` to enable Force Level Up. Have `M950_Cleric` successfully use a
staff, then disable Force Level Up with `F10`.

**Expected**

- The debug indicator shows Force Level Up while enabled.
- A successful staff use triggers the forced level-up path.
- Disabling the aid removes the active debug state.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 6.10 Retry restores the original class state

Do this last in the first run. After reclassing `M950_Knight`, allow any Blue
unit to die, choose `Retry`, and inspect the Knight.

**Expected**

- The Knight returns to the original class and displayed level.
- Original stats, weapon ranks, inventory, and skills are restored.
- No reclass state remains.
- The debug console does not report a snapshot rejection or `push_error`.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

### 6.11 Auto Promote at the level cap

Return to New Game, set `Auto Promote: On`, and relaunch Map 950. Use
`M950_Lvl19_Merc` to gain level 20 again.

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

## 7. All-map debug-console check

Keep the debug console visible when practical throughout the entire pass.

### 7.1 No data-validation errors

**Expected**

No `DataManager: ...` error or `push_error` appears. Examples include:

- `tilemap_scene_path '...' is missing`
- `reward_items item '...' not found`
- `seize condition in group '...' tile (X, Y) is outside the grid`
- `enemy placement ai_profile '...' is not valid`
- `duplicate unit_id '...'`
- `unit '...' hp ... exceeds max_hp ...`
- `snapshot ... is not a Dictionary`

These messages indicate content-authoring defects even if the game does not
crash. Record the complete message and the active map.

- [ ] **This item works as expected.**

**Tester comments:** _Enter comments here._

---

## 8. Known deferred issues

Do not report the unchanged behavior below as a v0.1.4 regression:

- Camera limits do not include viewport-aware overscan for edge panels.
- Mouse-follow camera catch-up remains abrupt.
- Clicking the Map Menu backdrop does not dismiss the menu.
- `Q` toggles the full danger zone; per-enemy threat inspection is not
  implemented.

Report behavior in these areas only if it is worse than described.

### Deferred-issue comments

_Enter observations here._

---

## 9. What to send back

Return:

1. This completed handbook with every applicable checkbox marked.
2. Tester comments for every failed or unclear item.
3. Debug-console output for any validation error.
4. Screenshots for combat-preview, terrain, camera, or menu-layout failures.
5. Exact repro steps using the failure format at the top of this document.
