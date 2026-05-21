# Class & Skill System Rebuild — Plan (2026-05-21)

## Goal

Rebuild `ClassData`, the level-up engine, and the level-up UI so the data model
matches the style of `AGENT/GDD/Content Expansion/awakening_classes_and_skills.md`:
FE:A-accurate base stats, per-class **stat caps**, a **player/enemy growth-rate
split**, and **per-class skills auto-learned at fixed levels**.

## Locked decisions (user, 2026-05-21)

1. Skills are **auto-learned at fixed levels** — no player choice.
2. **All base classes learn 2 skills**: one at level 1, one at level 10, per the
   doc's intent and FE:A standard. The doc's `Primary: — / Secondary: —` blanks
   are an unfinished reconciliation pass (doc line 51); we fill them from FE:A.
3. Class data **adopts the doc's FE:A values**.
4. The **`soldier` MVP class is swapped for `Cavalier`** as a player class.
5. Skill definitions are **pulled from the FE:A wiki** for now (see table below).
6. The level-up routine **reads class data for the skills to grant at the new
   level** — that lookup *is* the skill tool; no separate editor utility.
7. **Per-unit growth rates are stored on `UnitData`** ("unit base stat gains").
   Player level-ups use class growths **plus** the unit's personal growths.

Promotion mechanics remain **out of scope** for this rebuild (M6). The schema is
made promotion-ready only.

## Assumptions — REVIEW BEFORE IMPLEMENTATION

- **A1 — `soldier.tres` is kept, not deleted.** It is still referenced by enemy
  units in `map_001_rout` and `map_900_hotseat_validation`. It is migrated to the
  new schema but is treated as a non-doc legacy enemy class. Only the *player
  roster* swaps from Soldier to Cavalier. *If rejected: a separate task must
  re-class every enemy that currently uses `soldier`.*
- **A2 — Personal growth split.** Player units level on
  `class.player_growth_rates + unit.growth_rates`; enemy/generic units level on
  `class.enemy_growth_rates` alone (the doc's stated enemy auto-level rule).
- **A3 — Growth table chosen by team.** `team == "blue"` → player path; all
  other teams → enemy path.
- **A4 — Skill unlock levels.** Level 1 and level 10 for base classes.
- **A5 — One skill unlock per level** (`skill_unlocks` is a `level → skill_id`
  map).
- **A6 — Stat caps cover the 8 growth stats only** (HP, STR, MAG, SKL, SPD, LUK,
  DEF, RES); MOV/CON/LoS stay uncapped, matching the doc's cap tables.
- **A7 — Gender stat-cap variants** (doc: Great Lord) are not modelled.
- **A8 — Fixed weapon proficiencies** for MVP; the doc's "choose one/two" is
  deferred.
- **A9 — Complex skill effects are best-effort.** Stat-boost skills are wired
  fully; conditional skills (terrain fighters, Focus, Armsthrift, Healtouch) get
  correct data resources, with effect parity flagged for review (see M4).

## Base-class skills (pulled from FE:A wiki, 2026-05-21)

Source: tanasmanor.net FE:A skill list / fireemblem.fandom.com.

| Class | Level 1 skill | Level 10 skill |
|-------|---------------|----------------|
| Archer | Skill +2 — `skill_plus_2` | Prescience — `prescience` |
| Cavalier | Discipline — `discipline` | Outdoor Fighter — `outdoor_fighter` |
| Cleric | Miracle — `miracle` *(exists)* | Healtouch — `healtouch` |
| Knight | Defense +2 — `defense_plus_2` | Indoor Fighter — `indoor_fighter` |
| Mage | Magic +2 — `magic_plus_2` | Focus — `focus` |
| Mercenary | Armsthrift — `armsthrift` | Patience — `patience` |

11 new skill resources required; `miracle` already exists.

## Schema changes

### `scripts/resources/ClassData.gd`

| Field | Change |
|-------|--------|
| `growth_rates` → `player_growth_rates` | rename |
| `enemy_growth_rates: Dictionary` | new |
| `stat_caps: Dictionary` | new — 8 growth-stat keys |
| `skill_unlocks: Dictionary` | new — `{ level:int → skill_id:String }` |
| `tier: int = 1` | new — 1 base, 2 promoted |
| `promotion_stat_increases` → `promotion_stat_bonuses` | rename (used by M6) |
| `starting_skills`, `promotion_skill`, `occult_skill` | removed |

### `scripts/resources/UnitData.gd`

- `growth_rates: Dictionary` — **new**, the unit's personal growth rates, added
  on top of class player growths at level-up.

### `scripts/autoloads/DataManager.gd`

- Validate `skill_unlocks` ids against loaded skills.
- Validate `stat_caps` / growth dicts carry the 8 expected stat keys.

## Engine changes — `scripts/units/Unit.gd`

1. `level_up()` picks the growth source by team (A2/A3) and, for players, sums
   class `player_growth_rates` with `data.growth_rates`.
2. `_increment_stat()` clamps each stat to `class.stat_caps[stat]` (closes the
   existing TODO at line 603); a capped stat is omitted from the `changes` dict.
3. New `_grant_level_skills()` runs after stat gains: looks up
   `class.skill_unlocks` for the new level, appends unknown ids to `data.skills`.
4. The `unit_leveled_up` payload gains a `learned_skills` array.

## UI changes — `scripts/ui/LevelUpScreen.gd`

- Render a "Learned <Skill>!" line when a queued level-up carries
  `learned_skills`.

## Milestones (small commits)

- **M1 — Schema.** `ClassData.gd`, `UnitData.gd`, `DataManager.gd`; migrate all
  6 class `.tres` to the new schema; update `test_data_layer` / `test_data_manager`.
- **M2 — Level-up engine.** Growth selection + personal growths, cap clamping,
  skill auto-grant in `Unit.gd`; `test_unit_stats` + new coverage.
- **M3 — Level-up UI.** `LevelUpScreen.gd` learned-skill line; `test_level_up_screen`.
- **M4 — Skill resources.** Create the 11 new skill `.tres`; wire effects —
  `*_plus_2` reuse the existing `stat_bonus` effect; `prescience`/`patience` as
  combat hit/avoid modifiers; `discipline`, `outdoor_fighter`, `indoor_fighter`,
  `focus`, `armsthrift`, `healtouch` get resources + dispatch entries (effect
  parity best-effort, A9).
- **M5 — Class & roster data.** Rewrite the 6 class `.tres` with doc FE:A stats,
  caps, and split growths; add `cavalier.tres`; populate roster units'
  `growth_rates`; swap `unit_01_soldier` to a Cavalier unit.
- **M6 — Promotion (later, not this rebuild).** Promoted-class `.tres`, level-20
  promotion flow, `promotion_stat_bonuses` application.

## Open items flagged for review

- A1 (keep `soldier.tres`) — confirm, or schedule enemy re-classing.
- A9 — confirm best-effort skill-effect parity is acceptable for M4, or split a
  dedicated skill-effects milestone.
