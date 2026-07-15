# Playtest Checklist — v0.1.3

Use this against the v0.1.3 build (`builds/Project_Prometheus_v0.1.3_debug.exe`).
Each item lists the **exact** steps, the **expected** numeric / visual result,
and the **fail signal** to write down if you see something different. Stats
quoted are the authored values in the v0.1.3 fixtures; deviations are bugs.

Record failures as: `Map / Unit / Step / Actual / Expected / Repro`.

----

## A. First-launch smoke

1. **Title screen shows v0.1.3.** Open the .exe; bottom-right of the Main Menu
   reads `v0.1.3` in a small grey label.
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

### C5. Equipped-skill cap is exceeded gracefully (W3d)

1. On `Map 950`, select `unit_12_hero_skill_cap` (Level 14 Hero). Open
   Unit Details.
   - **Expected equipped:** `armsthrift`, `patience`, `dash`, `discipline`
     (4 skills, exactly at the equip cap).
2. Walk them into combat and earn the level to 15.
   - **Expected:** Level-up screen reports `disarm` learned.
     `data.earned_skills` now lists 5 ids; `data.skills` is unchanged at 4.
     No crash, no overwrite. The new skill is dormant (not equipped) until
     the player swaps one out.
3. Verify by re-inspecting the unit: the "earned skills" / unequipped list
   shows `disarm` separately from the equipped four.

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

----

## E. Combat preview + More Info (workstream 5)

### E1. Preview panel sizes to content (already in 09c)

1. Move an attacker adjacent to a defender. Open the combat preview.
   - **Expected:** panel hugs the rows it actually contains, not stretched
     vertically. Both sides' base forecast is readable.

### E2. More Info column does not cover the base forecast (already in 09c)

1. Open preview, press `More Info` / cycle.
   - **Expected:** the base forecast stays visible while the More Info
     description shows. Triangle, effectiveness, crit, Vantage rows do not
     stack on top of each other.

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

## F. Map HUD / camera / input (workstream 6 — NOT in v0.1.3, defer to v0.1.4)

These are deferred. **Do not regression-test them against v0.1.3**; they
remain known issues:

- Map details still show zero-based tile coordinates.
- Terrain HUD does not grow upward or scroll on expansion.
- Camera limits do not include viewport-aware overscan for edge panels.
- Mouse-follow camera catch-up is still snappy.
- Mouse-wheel over New Game UI still talks to the underlying camera.
- Movement Cancel does not snap the cursor back to the selected unit.
- Map-menu backdrop click does not dismiss the menu.
- No per-enemy threat inspect; `Q` is the only toggle.
- New Game options panel is not horizontally centered under its title.

Note any *worse* behavior in these areas (a regression vs. v0.1.2) but do
not treat them as v0.1.3 failures.

----

## G. Validation hardening (silent, watch debug console)

The data layer is stricter in v0.1.3. While playing, the debug log should
not emit `DataManager: ...` errors. If you see any push_error like:

- `tilemap_scene_path '...' is missing`
- `reward_items item '...' not found`
- `seize condition in group '...' tile (X, Y) is outside the grid`
- `enemy placement ai_profile '...' is not valid`
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

## What to send back

1. The filled checklist (`[x]` per item, with the fail-signal note when
   something is off).
2. Any debug-console output captured during play.
3. A screenshot for any visual regression in section E.
4. Specific repros for anything in section G.
