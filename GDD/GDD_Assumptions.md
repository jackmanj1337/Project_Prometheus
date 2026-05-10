# GDD Assumptions — For Designer Review

These are decisions made without explicit instruction, based on GBA Fire Emblem
conventions (primarily The Blazing Blade / FE7). Review each item and override
anything that doesn't match your vision. Each assumption notes which GDD file
it affects.

---

## Display & Technical

| # | Assumption | Rationale | Affects |
|---|---|---|---|
| 1 | Resolution is 1280×720 | Modern standard; scales well to most desktop monitors | GDD_01, GDD_07 |
| 2 | Tile size is 64×64 pixels | Clean integer scaling at 1280×720 gives ~20×11 visible tiles | GDD_01, GDD_06 |
| 3 | Camera does not use position smoothing | Instant camera snapping matches GBA FE feel | GDD_01, GDD_06 |
| 4 | Camera scrolls when cursor is within 2 tiles of viewport edge | Standard FE behavior | GDD_06 |
| 5 | No diagonal movement for cursor or units | Matches handbook rule and GBA FE | GDD_02 |
| 6 | Viewport stretches to fill window with `canvas_items` mode | Maintains pixel-perfect look at any window size | GDD_01 |

---

## Input

| # | Assumption | Rationale | Affects |
|---|---|---|---|
| 7 | Z = confirm, X = cancel (keyboard) | Standard GBA emulator / FE fan convention | GDD_07 |
| 8 | Mouse hover moves cursor instantly (no delay) | Feels more natural for desktop; key repeat still applies to keyboard | GDD_07 |
| 9 | Right-click always acts as cancel | Consistent with most strategy games | GDD_07 |
| 10 | Q / middle-click shows enemy danger zone (hold to display) | Common in modern FE titles; useful tactical info | GDD_07 |
| 11 | Tab cycles to next unacted player unit | Quality-of-life feature present in GBA FE | GDD_07 |
| 12 | Key repeat starts after 0.25s delay, repeats every 0.10s | GBA FE feel; not too slow, not too twitchy | GDD_07 |

---

## Turn Structure

| # | Assumption | Rationale | Affects |
|---|---|---|---|
| 13 | Player always goes first each round | Matches handbook rule explicitly | GDD_02 |
| 14 | A unit can move then act, or act in place, but not act then move | Standard FE rule | GDD_02 |
| 15 | Equipping a different weapon does not end the turn | Matches handbook rule | GDD_02 |
| 16 | Moving is undoable until an action is taken | GBA FE convention; handbook says "unless unit reveals hidden enemy" — hidden enemies deferred to Phase 2 fog of war | GDD_02, GDD_07 |
| 17 | End Turn requires confirmation if any player units haven't acted | QoL; prevents accidental early end of turn | GDD_07, GDD_09 |
| 18 | Turn counter increments at the start of each Player Phase | Standard FE convention | GDD_02 |

---

## Combat

| # | Assumption | Rationale | Affects |
|---|---|---|---|
| 19 | Hit and crit chance are clamped to 0–100% | Prevents display and logic issues with extreme stats | GDD_02 |
| 20 | Damage is clamped to minimum 0 (never heals the defender) | Matches handbook rule explicitly | GDD_02 |
| 21 | All exchanges in a combat round are determined upfront before any damage is applied | Prevents mid-combat stat changes (e.g. death of one unit) from altering the sequence | GDD_01 |
| 22 | RNG uses a single roll per hit and per crit (not the two-roll average system from GBA FE) | The handbook specifies percentile dice (one roll). Two-roll averaging can be added as an option later | GDD_02 |
| 23 | Weapon triangle applies to both hit rate AND damage simultaneously | Matches handbook: ±10 accuracy and ±2 damage | GDD_02 |
| 24 | Terrain bonuses apply only to the defender, not the attacker | Matches handbook | GDD_02 |
| 25 | Bows have range_min = 2; archers cannot attack or receive a counterattack at range 1 | Matches handbook and GBA FE | GDD_03, GDD_04 |
| 26 | Javelin and other thrown weapons lose durability only on a hit (not a miss) | Matches handbook "melee and thrown weapons only lose durability when they strike an enemy" | GDD_04 |
| 27 | Staves lose durability on every use, including misses | Matches handbook | GDD_04 |
| 28 | The attack preview shows exact percentages, not a hidden number | More transparent than GBA FE; matches the handbook's tabletop spirit where players see all values | GDD_07 |

---

## Units & Classes

| # | Assumption | Rationale | Affects |
|---|---|---|---|
| 29 | MVP uses 6 classes: Soldier, Mercenary, Archer, Mage, Cleric, Knight | Best spread of archetypes (tank, balanced melee, ranged physical, magic, healer, armored) | GDD_03 |
| 30 | Default leveling method is growth rates assigned per class | Most common FE system; most interesting for long campaigns | GDD_02, GDD_03 |
| 31 | Maximum inventory size is 8 slots per unit | The handbook has no hard limit; 8 is standard GBA FE and feels right | GDD_04 |
| 32 | Maximum skills per unit is 4 | Matches handbook rule explicitly | GDD_05 |
| 33 | Enemies use static stat blocks (base stats + growth formula) rather than random level-up rolls | Makes enemy stats predictable and designable; players can learn enemy patterns | GDD_06 |
| 34 | Unit portraits are 64×64 pixels in the HUD | GBA FE used ~48×48; 64×64 fits the 1280×720 layout better | GDD_07 |
| 35 | Dead units' UnitData is never deleted from the roster | Explicitly requested; enables future revival events and allows players to review fallen units | GDD_02 |

---

## Map Design

| # | Assumption | Rationale | Affects |
|---|---|---|---|
| 36 | MVP map is 20×15 tiles (Rout objective, 8 enemies) | Small enough for quick testing, large enough to feel like a real map | GDD_06 |
| 37 | The MVP map has no doors, chests, or fog of war | Keeps scope minimal; these are Phase 2 features | GDD_06 |
| 38 | Player start tiles are fixed; no pre-battle deployment screen for MVP | Deployment screen is Phase 2; auto-placement keeps MVP simpler | GDD_06 |
| 39 | The boss (E8) sits on a Throne tile and heals each turn | Creates a natural urgency for the player to push forward | GDD_06 |
| 40 | Wall tiles are treated as impassable by all units including flying | Flying units ignoring walls is a Phase 2 consideration per-map | GDD_06, GDD_02 |

---

## UI & UX

| # | Assumption | Rationale | Affects |
|---|---|---|---|
| 41 | Unit Info Panel is in the bottom-left corner | GBA FE convention | GDD_07 |
| 42 | Terrain Info Panel is in the bottom-right corner | GBA FE convention | GDD_07 |
| 43 | Phase banner slides in from the right, holds, then exits left | GBA FE visual style | GDD_07 |
| 44 | Action menu appears adjacent to the selected unit, repositioned if near screen edge | GBA FE convention; avoids covering the unit | GDD_07 |
| 45 | Units that have acted this turn are visually darkened/greyscale | GBA FE convention; makes it easy to see who can still act | GDD_07 |
| 46 | Game Over allows retry without any permanent consequences | Permadeath flag is only set if permadeath is ON, and only if the unit dies on a non-retry run | GDD_07 |
| 47 | Victory screen shows rewards then returns to a placeholder (no campaign map yet) | Campaign flow is Phase 2 | GDD_07 |

---

## Enemy AI

| # | Assumption | Rationale | Affects |
|---|---|---|---|
| 48 | Basic AI prioritizes kill shots above all else, then lowest HP targets | Most common FE AI behavior; creates pressure on weakened units | GDD_08 |
| 49 | Basic AI prefers attack tiles with higher terrain DEF as a tiebreaker | Gives enemies slightly smarter positioning without being overwhelming | GDD_08 |
| 50 | Basic AI does not avoid enemy danger zones or plan ahead more than one turn | Keeps MVP AI simple; smarter profiles are Phase 2 | GDD_08 |
| 51 | Enemy turns are animated at the same speed as player movement | Lets the player follow what's happening; 0.12s per tile | GDD_08 |
| 52 | There is a 0.3s pause between each enemy unit's turn | Prevents the enemy phase from feeling like a blur | GDD_08 |
| 53 | Enemies do not use healing items in the MVP AI | Item use logic added in Phase 2 boss AI profile | GDD_08 |

---

## Out of Scope Assumptions (Deferred to Phase 2)

These topics came up during design and were intentionally left out of MVP:

| Topic | Decision |
|---|---|
| Save / load system | No saves in MVP; game is a single session |
| Campaign structure | No chapter select; game launches directly into Map 001 |
| Character creation UI | MVP uses a default roster; full creation screen is Phase 2 |
| Pre-battle deployment | Units are auto-placed; player assignment screen is Phase 2 |
| Shops | No shops in MVP; starting equipment only |
| Ally NPC phase | Not implemented; mentioned in TurnManager for future hook |
| Laguz shift system | Architecturally noted; fully deferred |
| Status conditions | Data structures defined; logic deferred |
| Fog of war | Architecture noted; fully deferred |
| Story / dialogue | Completely out of scope |
| Music and sound effects | Placeholder silence for all MVP audio |
