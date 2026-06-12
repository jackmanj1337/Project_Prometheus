# Playtest Checklist — v0.1.4

Use this against the v0.1.4 build
(`builds/Project_Prometheus_v0.1.4_debug.exe`).
Artifact hash and source details are in
`AGENT/Docs/playtest_build_v0.1.4.md`.

This build includes every v0.1.3a check plus the June 10-12 fixes: visible and
bounded combat forecasts, scroll-bounded terrain More Info, multi-faction
camera/danger-zone corrections, stricter Pair Up targeting, full-round turn
counting, authored-only Rout defeat, `can_seize`-only Seize eligibility, a
five-skill equip cap, a five-Battle-Speed follow-up threshold, and A-rank caps
for the currently authored classes.

Record failures as: `Map / Unit / Step / Actual / Expected / Repro`.

----

## A. First-launch smoke

1. **Title screen shows v0.1.4.** Open the .exe; bottom-right of the Main Menu
   reads `v0.1.4` in a small grey label.
   - Fail signal: missing label, or wrong version string. Means you are
     running a stale build.

2. **New Game options load with last-selected defaults.** New Game → confirm
   `Map` selector, `Pair Up` toggle, `Auto Promote` toggle, `Leveling Method`,
   etc. are present and remember their last value across opening / closing
   the New Game panel.

3. **Settings round-trip.** Open Settings, change `mouse_cursor`, back out,
   open again — value persists.

----

## B. Objective correctness (workstream 2 fixes — 2026-06-09b)

### B1. Seize map (Map 002) — exclusive Seize victory

1. Launch `Map 002`. Select the lead unit that can Seize.
2. Defeat every Red unit *without* using Seize.
   - **Expected:** Map does NOT end. No victory screen. Hostile rout alone is
     not a Blue win on this map.
   - Fail: victory triggers anyway.
3. Step onto the authored Seize tile and choose `Seize` from the Action Menu.
   - **Expected:** victory screen.

### B2. Escape map (Map 004) — required units + paired escape

1. Launch `Map 004`. Note the two named required Escape units.
2. Move one required unit onto the Escape tile and pick `Escape`.
   - **Expected:** that unit is removed and recorded as escaped, the map does
     not yet resolve.
3. Kill one required unit instead of escaping it.
   - **Expected:** immediate defeat screen.
4. Pair a lead with a support, then escape the lead.
   - **Expected:** *both* lead and support are removed and counted as
     escaped, no remaining "support left on map" ghost.
5. Defeat every Red unit while a required Escape unit is still on the map.
   - **Expected:** no auto-win. Routing reds is not an Escape-map victory.

----

## C. Progression and class state (workstream 3)

### C1. Level-20 General has the right skills (W3a)

1. Launch `Map 950 - Promotion Validation`. The roster now contains 12 units.
2. Select `M950_General` (level 20, promoted Knight → General). Open `Inspect`
   / Unit Details.
   - **Expected equipped skills:** `bastion` (General lvl 5 unlock) and
     `iron_wall` (General lvl 15 unlock). Both must be in the equipped skill
     list — not just earned.
   - Fail: General lists no skills, or only one.

### C2. Reclass replaces class base stats while preserving earned gains (W3 done in b)

1. On `Map 950`, select `M950_Knight` (level 9 Knight). Note current
   Strength / Defense / Speed / Skill.
2. Use a `Second Seal` to reclass them into a tier-1 option (e.g. Soldier).
   - **Expected:** Strength / Defense / Speed / Skill / Movement adjust by
     the *difference* between Knight and Soldier class base contributions.
     Personal level-up gains are preserved. New class's level-1 skill is
     granted. Displayed level resets to 1.
   - The reclass option labels show each stat as
     `old +/-delta -> new / cap`.

### C3. Promotion-item usability refresh (W3b)

1. Select `unit_11_lvl19_mercenary` (Level 19 Mercenary with Master Seal).
   Open Action Menu.
   - **Expected:** `Item` button **hidden** — they are level 19, not yet
     eligible to promote.
2. Walk them into combat and kill a Soldier (E1) to gain at least one level.
   Continue until they hit level 20.
3. On the *next* turn, select them again and open Action Menu.
   - **Expected:** `Item` button now visible. Picking it shows
     `Master Seal (1)`. Confirming opens the promotion modal with both
     `Hero` and `Sentinel` and `Bow Knight` options.
   - Fail: Item button still hidden after hitting level 20.

### C4. Auto Promote at cap (W3c)

1. Restart New Game with `Auto Promote: On`. Replay step C3.
   - **Expected:** the moment Level 19 → 20 finishes its level-up animation,
     the promotion modal opens automatically without needing to use the seal.

### C5. Fifth equipped-skill slot is used (updated default)

1. On `Map 950`, select `unit_12_hero_skill_cap` (Level 14 Hero). Open
   Unit Details.
   - **Expected equipped:** `armsthrift`, `patience`, `dash`, `discipline`
     (4 skills, with one of the 5 default equip slots still open).
2. Walk them into combat and earn the level to 15.
   - **Expected:** Level-up screen reports `disarm` learned.
     `data.earned_skills` and `data.skills` now list all 5 ids. No crash and
     no existing skill is overwritten.
3. Verify by re-inspecting the unit: `disarm` appears with the other four
   equipped skills. A sixth learned skill would remain unequipped.

### C6. Retry restores state after an in-map class change (W3e)

1. On `Map 950`, use a Second Seal on a tier-1 unit (e.g. `M950_Cavalier`)
   to reclass.
2. Continue play until any Blue unit dies and Game Over fires.
3. Press `Retry`.
   - **Expected:** the reclassed unit reverts to its original class,
     class_line_id, level, internal_level, stats, weapon_wexp, and skills.
     No leftover Mercenary state on a Cavalier.
   - Fail: unit stays in its reclassed state, or the snapshot rejects with
     a `push_error` line in the debug console.

----

## D. Pair Up (workstream 4)

### D1. Pair creation marks both units done (W4a)

1. On any map with `Pair Up: On`, move a Blue lead adjacent to a Blue ally.
   Pick `Pair Up` → target the ally.
   - **Expected:** support sprite disappears (off-map), lead remains visible.
     Both units' end-of-action color/state changes to DONE (greyed). Phase
     auto-end (if all other Blue units are done) fires normally.
   - Fail: hidden support stays "actionable," phase refuses to advance.

### D2. Swap turns lead and support, costs the action (already in 09c)

1. Pair two units, then on the lead's turn pick `Swap`.
   - **Expected:** roles flip (the lead becomes support, support becomes
     lead). Both units marked DONE. Lead stays on its original tile.

### D3. Pair Up bonus context unified for preview and resolution (W4b)

Pair a Hero lead with a Cavalier support. Engage an enemy at melee.

- **Expected Cavalier flat bonuses** (`pair_up_bonus_table.tres`):
  `+1 Str / +1 Def / +1 Spd`.
- **Expected scaling bonuses** (divisor 4, scaling stats:
  strength, magic, defense, resistance, skill, speed, luck):
  add `floor(support.<stat> / 4)` to each.

  Example: Cavalier with Str 12 / Spd 7 / Skl 4 / Def 7 contributes:
  ```
  Str:  flat +1 + floor(12/4)=3 → +4
  Def:  flat +1 + floor( 7/4)=1 → +2
  Spd:  flat +1 + floor( 7/4)=1 → +2
  Skl:  flat  0 + floor( 4/4)=1 → +1
  ```

- **Expected preview vs resolution:** the combat preview's Atk, Hit, AS-based
  follow-up calc, and final damage all reflect those bonuses. The live fight
  must deal damage matching the preview's `attacker_damage` (modulo crit /
  miss RNG). If you ever see "preview says 12, fight does 9," log this as a
  W4b regression.

### D4. Pair Up requires the same faction

1. Launch `Map 900 - Hotseat Validation`.
2. During Blue's phase, move a Blue unit adjacent to a Green unit.
   - **Expected:** `Pair Up` is not offered. Blue and Green are allies, but
     they are different armies.
3. On a normal map, move two Blue units together.
   - **Expected:** same-faction Pair Up remains available.

### D5. Paired support does not block phase completion

1. Pair two Blue units, then finish every remaining Blue unit's action.
   - **Expected:** the phase ends normally. The hidden support is not counted
     as a separate waiting unit.
2. Before ending the phase, cycle units with the next-unit input.
   - **Expected:** selection never jumps to the support's off-map position.

----

## E. Combat preview + More Info (workstream 5)

### E1. Preview panel sizes to content (already in 09c)

1. Move an attacker adjacent to a defender. Open the combat preview.
   - **Expected:** panel hugs the rows it actually contains, not stretched
     vertically. Both sides' Name, HP, Damage, Hit, and Crit rows are visible.
     This specifically guards the blank-forecast regression from June 10.
2. Preview an enemy that cannot counter.
   - **Expected:** `No counter` remains visible while unused defender Hit and
     Crit rows collapse without leaving blank overlapping controls.

### E2. More Info column does not cover the base forecast (already in 09c)

1. Open preview, press `More Info` / cycle.
   - **Expected:** the base forecast stays visible while the More Info
     description shows. Triangle, effectiveness, crit, Vantage rows do not
     stack on top of each other.
2. Repeat with triangle and effectiveness rows visible together.
   - **Expected:** every row remains readable and the panel stays on-screen.
3. Repeat at `960x540` if window resizing is available.
   - **Expected:** the preview remains bounded and does not return to the
     near-full-height June 9 layout.

### E3. Character stat details show active modifiers (W5b)

1. On `Map 950`, select `M950_Mercenary`. Open Action Menu → Item →
   `Strength Tonic`.
   - **Expected:** `+4 Strength (4 turns)` modifier applied. The Strength
     Tonic is consumed.
2. Inspect the unit.
   - **Expected lines on the Strength stat detail panel:**
     ```
     Base <N>   Effective <N+4>
     Growth <X>%
     Fixed <Y> / 100
     Modifiers:
       Strength Tonic  +4  (4 turns)
     ```
   - Where `<N>` is the Mercenary's pre-tonic Strength (the same number the
     stats panel showed before drinking it). `<X>` is the effective Strength
     growth (class + personal), and `<Y>` is the current fixed-growth
     accumulator out of 100.
   - Fail: modifier line missing, "No active modifiers" still shown,
     Effective unchanged, or duration text wrong.

3. End four turns. The tonic should expire — Effective drops back to Base,
   and the Modifiers line disappears.

### E4. Effective growth and fixed-growth progress (W5b + W3 09c)

1. Inspect any growing player unit. For each stat row, the detail panel must
   show **two** lines below `Base / Effective`:
   - `Growth N%`  — class player_growth + unit growth_rates contribution.
   - `Fixed N / 100`  — the fixed-growth accumulator. `N` advances on every
     level-up in `growth_fixed` mode and resets to `0` when the stat ticks.

----

## F. Map HUD / camera / input (workstream 6)

v0.1.4 retains the four v0.1.3a quick wins and adds the terrain More Info
layout correction. The remaining visual/input items stay deferred.

### F1. Map details show one-based tile coordinates (W6a)

1. Launch any map. Move the cursor over the upper-left tile.
   - **Expected:** the Terrain panel reads `Tile (1, 1)`. The terrain name,
     defense, and dodge lines are unchanged.
2. Move the cursor right by one tile.
   - **Expected:** `Tile (2, 1)`.
3. Move the cursor to a player_start tile that you know is internally at
   `(0, 0)` (the top-left start on a small map).
   - **Expected:** `Tile (1, 1)` shown — internal storage is still zero-based,
     this is a display-only `+1`.
   - Fail signal: `Tile (0, 0)`, missing line, or coords disagree with the
     map's visible row/column count.

### F2. Movement Cancel snaps cursor back to the acting unit (W6f)

1. Select any Blue unit and walk the cursor to a legal destination tile
   (anywhere along the blue movement overlay).
2. Confirm the move so the Action Menu opens. The unit is now on the new
   tile and the cursor is parked on top of it.
3. Press Cancel (B / Esc / right-click) on the Action Menu.
   - **Expected:** the unit teleports back to its pre-move tile **and the
     cursor follows it** — both the unit and the cursor are on the original
     starting tile. The movement overlay re-appears so a new destination can
     be chosen.
   - Fail signal: the unit returns to its starting tile but the cursor stays
     on the cancelled destination. Previously the player had to manually
     move the cursor back; that is the regression to watch for.

### F3. Mouse-wheel over New Game UI does not move the camera (W6e)

1. From the title screen, open `New Game`.
2. Hover the mouse over the New Game panel — over the title, over each
   dropdown, and over empty space inside the panel.
3. Scroll the mouse wheel up and down five times each in each spot.
   - **Expected:** the panel itself does not scroll (it isn't a scroll
     view), and the background camera state does **not** drift. Closing
     New Game returns you to the same Main Menu view you started in.
   - Fail signal: any visible camera/viewport shift in the title screen
     while wheeling over the New Game panel.

### F4. New Game options panel is horizontally centered (W6i)

1. Open `New Game` at the default 1280×720 viewport.
   - **Expected:** the options panel sits centered horizontally, with equal
     left/right margin between the panel and the screen edges. The panel
     title "New Game" sits centered at the top of the panel.
2. If you can resize the window (e.g. fullscreen vs windowed at a different
   resolution), re-open New Game and confirm the panel is still centered.
   - **Expected:** centering is anchor-driven, so it should hold at any
     viewport width.
   - Fail signal: panel hugs the left side of the screen, or is off-center
     by a visible amount.

### F5. Terrain More Info is separate and scroll-bounded (W6b)

1. Hover any terrain tile and open More Info.
   - **Expected:** the compact Terrain panel remains at bottom-right and a
     separate details box appears above it.
2. Check a terrain entry with longer description, movement-cost, and action
   text.
   - **Expected:** the details box has a fixed visible height and scrolls.
     It does not grow off the top of the screen or cover the compact terrain
     stats.
3. Close More Info.
   - **Expected:** the details box disappears and the compact Terrain panel
     remains.

### F.deferred — Still deferred to a later build

These W6 items remain known issues for v0.1.4; do not treat them as
regressions:

- Camera limits do not include viewport-aware overscan for edge panels (W6c).
- Mouse-follow camera catch-up is still snappy (W6d).
- Map-menu backdrop click does not dismiss the menu (W6g).
- No per-enemy threat inspect; `Q` is the only toggle (W6h).

Note any *worse* behavior in these areas, but do not treat the unchanged
behavior as a v0.1.4 failure.

----

## G. Validation hardening (silent, watch debug console)

The data layer is stricter in v0.1.4. While playing, the debug log
should not emit `DataManager: ...` errors. If you see any push_error like:

- `tilemap_scene_path '...' is missing`
- `reward_items item '...' not found`
- `seize condition in group '...' tile (X, Y) is outside the grid`
- `enemy placement ai_profile '...' is not valid`
- `duplicate unit_id '...'`
- `unit '...' hp ... exceeds max_hp ...`
- `snapshot ... is not a Dictionary`

…it is a content-authoring bug, not a runtime crash. Capture the message
and the map you saw it on.

----

## H. Closed May fixes — recheck if you have time

Recheck and re-open ONLY if these regress:

- Map 900 hotseat handoff still works.
- Hotseat combat preview dispatch still binds to the active side.
- Map 950 reclass-menu does not overflow.
- Staff use still force-levels the wielder when `debug_force_levelup` is on.

----

## I. v0.1.4 rules and multi-faction changes

### I1. Turn number advances after the full faction cycle

1. Launch `Map 900 - Hotseat Validation`; confirm the HUD begins at `Turn 1`.
2. End Blue, play/end Green, then watch Red and Yellow act.
   - **Expected:** the HUD remains `Turn 1` throughout Green, Red, and Yellow.
3. When control returns to Blue:
   - **Expected:** the HUD changes to `Turn 2`.
   - Fail signal: the number changes when Blue first ends, or changes more
     than once during the cycle.

### I2. Phase labels include controller ownership

On Map 900, check the HUD/banner through one cycle:

- Blue: `Blue - Player 1`
- Green: `Green - Player 2`
- Red: `Red Raiders - AI`
- Yellow: `Yellow Rogues - AI`

Capitalization and the added `PHASE` suffix may differ between HUD and banner;
the faction and controller text must agree.

### I3. Camera and danger zone are faction-specific

1. During Blue's phase, pan to a memorable view, then end the phase.
2. During Green's phase, pan somewhere different and press `Q`.
   - **Expected:** the danger overlay shows units hostile to Green, not a
     stale Blue-only perspective.
3. Finish the cycle.
   - **Expected:** Blue's saved camera view is restored when Blue returns.
     Green's view must not overwrite it during Red or Yellow phases.

### I4. Four Battle Speed is no longer a follow-up

1. On Map 950, preview `M950_Mage` attacking an `M950_E1/E2/E3_Soldier`
   without Pair Up or stat modifiers.
   - Authored Battle Speed is 7 for the Mage and 3 for the Soldier.
   - **Expected:** the Mage attacks once, not twice, because the advantage is
     4 and the follow-up threshold is now 5.

### I5. Seize and Rout use authored rules only

1. Repeat B1 with the default Cavalier, whose `can_seize` flag is true.
   - **Expected:** Seize is available on the objective tile.
2. Put a different Blue unit on that tile.
   - **Expected:** Seize is not available.
3. On Map 001, allow every allied unit to be defeated.
   - **Expected:** defeat triggers because that map explicitly authors allied
     Rout defeat. Maps without an authored Rout condition must not infer one.

----

## What to send back

1. The filled checklist (`[x]` per item, with the fail-signal note when
   something is off).
2. Any debug-console output captured during play.
3. A screenshot for any visual regression in section E or F.
4. Specific repros for anything in section G.
