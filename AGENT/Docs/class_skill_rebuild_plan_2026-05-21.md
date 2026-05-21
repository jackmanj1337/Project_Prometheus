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

## Milestones (small commits) — STATUS

- **M1 — Schema. ✅ DONE.** `ClassData.gd`, `UnitData.gd`, `DataManager.gd`; all
  6 class `.tres` migrated; `test_data_layer` / `test_data_manager` updated.
- **M2 — Level-up engine. ✅ DONE.** Growth selection by team + personal growths,
  cap clamping, skill auto-grant in `Unit.gd`; `test_unit_stats` coverage added.
- **M3 — Level-up UI. ✅ DONE.** `LevelUpScreen.gd` learned-skill line +
  `test_level_up_screen` coverage.
- **M4 — Skill resources. ✅ DONE (data only).** 11 skill `.tres` created from the
  FE:A wiki. `*_plus_2` use `stat_bonus`; the other 8 effect_ids registered in
  `SkillHandler` as M9 stubs. **Effect logic itself is NOT implemented** — it
  rides with the codebase's existing M9 skill-effects milestone.
- **M5 — Class & roster data. ✅ DONE.** 5 retained classes rewritten with doc
  FE:A values; `cavalier.tres` added; `unit_01_soldier.tres` renamed/reclassed to
  Cavalier; all 6 roster units given personal `growth_rates`.
- **M6 — Promotion. PLANNED, NOT STARTED.** Full detailed handoff plan —
  schema, flow, promoted-class data, commit breakdown, Second Seal estimate —
  in `m6_promotion_plan_2026-05-21.md`.

## Implementation notes & follow-up assumptions (REVIEW)

- **N1 — Skill effects deferred to M9.** Per the codebase's own roadmap,
  `SkillHandler` stubs `stat_bonus`/`charm`/`anathema`/`daunt`; the 8 new
  base-class effects join them as stubs. The 11 skills are real, equippable, and
  auto-granted at level-up — they just have no combat effect until M9.
- **N2 — Cavalier proficiency fixed to Lance.** The doc lets Cavalier choose
  Axe/Lance/Sword; MVP picks Lance so the existing `unit_01` iron-lance loadout
  stays valid. Mage keeps all three anima types (doc says choose two).
- **N3 — `unit_01` Cavalier keeps its hand-authored stats.** Only `class_id` and
  `growth_rates` changed; base stats were NOT re-derived from Cavalier base
  stats, to avoid rebalancing existing maps. Its movement (6) is below the
  Cavalier base (7) as a result.
- **N4 — Roster personal `growth_rates` are placeholder values** chosen to read
  sensibly per class; they are not tuned and should be reviewed.
- **N5 — `soldier.tres` retained unchanged** (interim M1 schema, non-doc values)
  for the enemy units that still reference it.
- **N6 — Level-1 skill grant.** `_grant_level_skills` only fires on level-up
  transitions; a unit created at level 1 does not auto-receive its level-1
  class skill. `unit_01` was hand-given `discipline`. A "grant level-1 unlocks
  at unit creation" hook is a suggested follow-up.
