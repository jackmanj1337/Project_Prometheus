# M7 — Second Seal Reclassing & Demotion Plan (implemented, 2026-05-21)

Detailed implementation plan for the Second Seal milestone that follows M6
promotion. This plan is saved for later; it is **not** the next implementation
step. It depends on the M6 promotion work and on the small level-1 skill grant
follow-up noted in `class_skill_rebuild_plan_2026-05-21.md`.

## Status

Implemented on branch `class-skill-rebuild` after:
- **M6 — Promotion**
- **F1 — level-1 class skill grant at unit creation / class reset**

Hotseat is now the next saved milestone after the class/skill track.

## Scope

Second Seal lets a unit change class without gaining promotion bonuses. It
covers:
- Tier-1 lateral reclassing
- Tier-2 demotion to Tier-1
- Tier-2 lateral reclassing into a different Tier-2 class line
- Special-class handling
- Max-level self-reset into the current class
- The item flow, target-picker UI, and validation

**Out of scope:** promotion (M6), free skill swapping, class rebalance, and any
change to the underlying promotion data tables beyond what M6 already adds.

## Locked decisions (user, 2026-05-21)

1. **Stat model:** when swapping classes, keep the unit's current stats and
   only remove the source class's promotion bonuses if leaving a promoted
   class. Tier-1 classes have no promotion bonuses to remove. Second Seal never
   grants the target class's promotion bonuses.
2. **Tier-1 rule:** a first-tier unit can use a Second Seal starting at
   **level 10** to change into another first-tier class in that character's
   class set. It cannot use Second Seal to promote into Tier 2.
3. **Tier-2 demotion rule:** a second-tier unit can use a Second Seal at
   **any level** to demote into a first-tier class of any class line.
4. **Tier-2 lateral rule:** a second-tier unit at **level 10** can use a
   Second Seal to change into a second-tier class belonging to a **different**
   class line.
5. **Special-class rule:** a special-class unit that cannot promote is treated
   as first-tier until **level 30**. At level 30 it is treated as second-tier
   for Second Seal rules.
6. **Max-level self-reset:** a unit at max level in any class can use a Second
   Seal and choose its current class to reset its level to **1** with no stat
   change.

## Design decisions inferred from the locked rules

These are not new gameplay rules; they are the implementation details needed to
make the locked rules coherent.

1. **Second Seal resets displayed level to 1.** On any successful reclass,
   `level = 1`, `exp = 0`, and `growth_accumulators = {}`. This follows the
   self-reset rule and Awakening's general seal flow.
2. **`effective_level` keeps accumulating.** Reclassing does not rewind total
   progression; it only resets the current class level counter.
3. **Weapon ranks are never deleted.** Reclassing adds any newly-needed weapon
   proficiencies at `E` rank but does not erase stored ranks for weapons the
   new class cannot currently use.
4. **Skills are retained.** `earned_skills` and equipped `skills` stay intact.
   Reclassing changes future skill unlocks by changing the active class.
5. **Reclassing into a level-1 class should grant that class's level-1 skill.**
   This depends on follow-up **F1**. If F1 is not landed separately, M7 must
   absorb that fix before the item ships.

## Required schema changes

### `scripts/resources/UnitData.gd`

| Field | Change |
|-------|--------|
| `reclass_options: Array[String] = []` | **new** — the character's allowed Tier-1 class set for lateral Tier-1 reclassing. |
| `class_line_id: String = ""` | **new** — tracks the unit's current class line so shared promoted classes like `bow_knight` are not ambiguous. |

- `reclass_options` stores **Tier-1** class ids only.
- `class_line_id` should be initialised from the starting Tier-1 class for
  existing units and updated whenever a successful class change happens.

### `scripts/resources/ClassData.gd`

| Field | Change |
|-------|--------|
| `is_special_class: bool = false` | **new** — marks non-promoting special classes that use the level-30 Second Seal rule. |

- Do **not** infer "special class" from `promotes_to.is_empty()`. That would
  incorrectly catch legacy or enemy-only classes such as `soldier`.

### Validation / snapshots

- `DataManager` validates all `reclass_options` ids against loaded classes.
- `DataManager` validates that `class_line_id` and `reclass_options` entries
  point at Tier-1 classes where required.
- `test_data_layer.gd` and `test_snapshot_coverage.gd` add
  `reclass_options` and `class_line_id` to the allowlist.
- `GameState` snapshot save/load includes both new `UnitData` fields.

## Tier model for Second Seal

Second Seal needs an **effective seal tier** separate from `ClassData.tier`.

### Effective seal tier

`Unit._effective_second_seal_tier()`:
- returns `2` when `class_data.is_special_class` and `data.level >= 30`
- returns `1` when `class_data.is_special_class` and `data.level < 30`
- otherwise returns `class_data.tier`

Notes:
- This does **not** change `data.is_promoted` by itself.
- A level-30 special class is treated like Tier 2 for **eligibility and target
  pools only**.

## Eligibility and target rules

### `Unit.can_use_second_seal() -> bool`

True when any of these are true:
- effective seal tier is 1 and `data.level >= 10`
- effective seal tier is 2
- `data.level >= class_data.max_level` for the self-reset case

### `Unit.get_second_seal_options() -> Array[Dictionary]`

Each option should include at least:
- `class_id`
- `class_line_id`
- `label`
- `target_tier`
- `is_self_reset`

#### Effective Tier 1 options

When effective seal tier is 1 and `data.level >= 10`:
- include every class in `data.reclass_options`
- include **Tier-1 only**
- exclude Tier-2 classes entirely
- include the current class **only** when `data.level >= class_data.max_level`

This matches the rule that Tier-1 Second Seal can reclass laterally but cannot
be used as a promotion shortcut.

#### Effective Tier 2 options at levels 1–9

When effective seal tier is 2 and `data.level < 10`:
- include all Tier-1 classes
- include the current class only when `data.level >= class_data.max_level`
- exclude all other Tier-2 classes

This is the demotion-only window.

#### Effective Tier 2 options at level 10+

When effective seal tier is 2 and `data.level >= 10`:
- include all Tier-1 classes
- include all Tier-2 classes whose `class_line_id` differs from the unit's
  current `class_line_id`
- include the current class only when `data.level >= class_data.max_level`

This creates three valid outcomes:
- demote into any Tier-1 line
- laterally reclass into a different Tier-2 line
- reset the current class at max level

## Shared-class line handling

Shared promoted classes make line-based validation ambiguous:
- `bow_knight` can come from Archer or Mercenary
- `dark_knight` can come from Mage or Dark Mage

M7 should not guess the current line from `class_id` alone.

### Rule

`data.class_line_id` is the authoritative current line for Second Seal checks.

### Update rules

- Starting Tier-1 units: `class_line_id = class_id`
- Promotion in M6: preserve or set the Tier-1 source line
- Tier-1 reclass: `class_line_id = target_class_id`
- Tier-2 demotion to Tier-1: `class_line_id = target_class_id`
- Tier-2 lateral reclass: `class_line_id = chosen target line`

### UI implication

If a target promoted class can belong to multiple lines, the picker should show
line-qualified labels, e.g.:
- `Bow Knight (Archer line)`
- `Bow Knight (Mercenary line)`

If the target line matters, the option data should carry both `class_id` and
`class_line_id`.

## Shared helper

M6 should factor class switching so M7 can reuse it.

Recommended helper:
- `Unit._apply_class_change(target_class_id: String, target_line_id: String, mode: String) -> void`

Modes:
- `promote`
- `reclass`

### `Unit.reclass(target_class_id: String, target_line_id: String = "")`

1. Validate that the chosen target is present in `get_second_seal_options()`.
2. If the selected option is the max-level self-reset case
   (`target_class_id == data.class_id` and target line unchanged), skip all
   stat changes and only reset the class level state.
3. Load the source and target `ClassData`.
4. If this is **not** the self-reset case and the source class has `tier == 2`,
   subtract the source class's `promotion_stat_bonuses` from the unit's current
   stats.
5. Do **not** add the target class's `promotion_stat_bonuses`.
6. Clamp all affected stats to the target class's `stat_caps`.
7. Set `data.class_id = target_class_id`.
8. Set `data.class_line_id` to the resolved target line.
9. Set `data.is_promoted = target_class.tier == 2`.
10. Set `data.level = 1`, `data.exp = 0`,
   `data.growth_accumulators = {}`.
11. Leave `data.effective_level` unchanged.
12. Add any target-class proficiencies not already in `data.proficiencies` at
    `{"rank": "E", "wexp": 0}`.
13. Emit `EventBus.unit_reclassed(unit, old_class_id, new_class_id)`.
14. If F1 is present, grant the target class's level-1 skill immediately.

### HP handling

When subtracting a source Tier-2 class's HP promotion bonus:
- reduce `max_hp`
- clamp `hp` to the new `max_hp`

This avoids illegal current HP after demotion or Tier-2 lateral reclassing.

## Item flow

### New item effect

Create a Second Seal item, e.g. `data/items/second_seal.tres`:
- `effect_id = "reclass"`

`ItemHandler`:
- validates `unit.can_use_second_seal()`
- opens the reclass picker on success
- consumes the item only after a confirmed valid reclass
- gives feedback and does nothing on invalid targets

## UI changes

### Reclass picker

Preferred approach:
- extend `PromotionScreen` into a more generic class-change picker, or
- create `ReclassScreen` reusing its layout patterns

The screen should:
- list only legal options from `get_second_seal_options()`
- show target class name and class line where relevant
- clearly mark `Reset to Lv 1` when the current class is selected
- show that Second Seal does **not** grant promotion bonuses
- block map input while open, matching the promotion flow

For each option, show:
- class name
- tier
- weapon types
- level-1 / later skill unlocks for the target class
- a short note such as `Demote`, `Reclass`, or `Reset`

## Data work

After M6 exists:
- add `reclass_options` to each playable roster unit
- initialise `class_line_id` on all roster units
- add `is_special_class = true` only to intended special classes
- create `second_seal.tres`

No enemy migration is required unless enemies are meant to use Second Seal.

## Suggested commit breakdown

- **M7.1** — Schema: `UnitData.reclass_options`, `UnitData.class_line_id`,
  `ClassData.is_special_class`, snapshot/validation updates.
- **M7.2** — Shared class-change helper + `can_use_second_seal()` +
  `get_second_seal_options()` + headless tests.
- **M7.3** — `Unit.reclass()` implementation, stat adjustment rules,
  proficiency carry/add rules, `EventBus.unit_reclassed`, tests.
- **M7.4** — `ItemHandler` `reclass` effect + `second_seal.tres`.
- **M7.5** — Reclass picker UI and map flow integration.
- **M7.6** — Roster data authoring: `reclass_options`, `class_line_id`,
  special-class flags, manual verification.

## Test plan

### Headless unit tests

- Tier-1 unit below level 10 cannot use Second Seal.
- Tier-1 unit at level 10 can target only Tier-1 classes in its
  `reclass_options`.
- Tier-1 unit cannot use Second Seal to enter Tier 2.
- Tier-2 unit below level 10 can demote to Tier 1 but cannot laterally reclass
  to another Tier-2 line.
- Tier-2 unit at level 10 can target Tier-2 classes from different lines.
- A level-30 special class is treated as effective Tier 2; a level-29 one is
  not.
- Choosing the current class at max level resets `level` to 1 and leaves stats
  unchanged.
- Demoting from Tier 2 removes the source `promotion_stat_bonuses` and clamps
  to the Tier-1 target caps.
- Tier-2 lateral reclass removes the source bonuses and adds no new bonuses.
- `effective_level` is preserved.
- Missing target proficiencies are added at `E`; existing ranks are preserved.
- Shared promoted classes respect `class_line_id` rather than guessing from
  `class_id`.
- Invalid `reclass_options` ids are caught by `DataManager`.

### Manual verification

- A level-10 base-class unit can use a Second Seal to move into another allowed
  base class and immediately function on-map.
- A promoted unit can demote at low level and keep sensible stats.
- A promoted level-10 unit can reclass into another promoted class line.
- A max-level unit can pick its current class and cleanly reset to level 1.
- A special-class unit follows the level-10 / level-30 rules exactly.

## Risks / implementation notes

- **R1 — ambiguous class lines.** Without `class_line_id`, shared promoted
  classes break the "different line" rule.
- **R2 — stat underflow / HP inconsistency.** Removing source promotion bonuses
  can push HP or capped stats below current values; tests must cover this.
- **R3 — F1 dependency.** If level-1 class skills are still not auto-granted,
  reclassing into a new class at level 1 will feel broken.
- **R4 — broad demotion target pool.** "Any class line" is mechanically broad.
  That is accepted in this plan, but it may need balance review later.

## Relationship to M6

M7 should reuse M6's class-switch seam rather than duplicating logic.

Recommendation:
- land M6 first
- then land F1
- then implement M7
