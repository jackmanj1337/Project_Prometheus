# Awakening Compatability Refactor Plan

> **Historical** — the compatibility gap analysis this plan describes was resolved
> through the documentation consolidation project (Stages 1–5, 2026-06-13). The
> adoption matrix and GDD chapters are now the authoritative result. Retained for
> the gap analysis rationale. Do not use as a live action list.

## Purpose
Assess the new Awakening content expansion in `AGENT/GDD/Content Expansion/New_Content_Expansion/`
against the current game implementation and identify the work needed to make the
project compatible with the systems described there.

## Executive Summary
This is not a simple content import. The new corpus assumes **Fire Emblem
Awakening mechanical canon** across progression, combat, skills, class rules,
enemy generation, Pair Up, inheritance, and DLC compatibility. The current
project is built around the existing project GDD and a narrower TTRPG-inspired
ruleset already encoded in the runtime.

The main problem is **rules-model incompatibility**. If the new content is
loaded into the current data layer without refactoring the engine first, the
project will accept data that it cannot represent correctly, and the resulting
behavior will be quietly wrong rather than loudly failing.

## Source Material Reviewed
- `AGENT/GDD/Content Expansion/New_Content_Expansion/awakening_project_index.md`
- `AGENT/GDD/Content Expansion/New_Content_Expansion/awakening_master_index.md`
- `AGENT/GDD/Content Expansion/New_Content_Expansion/awakening_core_systems.md`
- `AGENT/GDD/Content Expansion/New_Content_Expansion/awakening_classes_base.md`
- `AGENT/GDD/Content Expansion/New_Content_Expansion/awakening_classes_promoted.md`
- `AGENT/GDD/Content Expansion/New_Content_Expansion/awakening_classes_special.md`
- `AGENT/GDD/Content Expansion/New_Content_Expansion/awakening_skills.md`
- `AGENT/GDD/Content Expansion/New_Content_Expansion/awakening_items.md`
- `AGENT/GDD/Content Expansion/New_Content_Expansion/awakening_appendices.md`

## Current Implementation Baseline
- Class data is modeled in `scripts/resources/ClassData.gd`.
- Unit progression and class changing live in `scripts/units/Unit.gd`.
- Combat logic lives in `scripts/core/CombatResolver.gd`.
- Skill dispatch lives in `scripts/skills/SkillHandler.gd`.
- Item dispatch lives in `scripts/items/ItemHandler.gd`.
- Data validation and load shape live in `scripts/autoloads/DataManager.gd`.

## Resolved Decisions
- The Awakening corpus is the new gameplay canon where it conflicts with the
  older project GDD.
- `level` remains the displayed level.
- `internal_level` will be added as an explicit hidden progression value.
- Repeated Second Seal pressure will be tracked separately from `internal_level`.
- Special classes will use explicit data-driven rules instead of being forced
  into normal base/promoted handling.
- Any unit may access any playable class by default.
- The final product will not contain gender-locked or gender-differentiated
  classes.
- `special_qualities` remains for broad trait and movement behavior.
- `vulnerability_groups` will be added for combat effectiveness targeting.
- `mounted` and `flying` may appear in both `special_qualities` and
  `vulnerability_groups`.
- canonical vulnerability groups for the current pass are `mounted`, `flying`,
  `armoured`, `dragon`, `beast`, and `monster`
- Numeric `wexp` is the source of truth; displayed rank is derived from
  threshold tables.
- `effective_level` should be fully replaced by `internal_level`, not kept as a
  parallel migration field
- `class_availability` should control in-game menu visibility only and remain a
  soft filter that map and campaign creators can override by direct assignment
- the unit details / character sheet should show every stored weapon track with
  any WEXP, including derived rank, current WEXP, next threshold, and a dimmed
  presentation when the track is currently unavailable

## Main Compatibility Problems

### 1. Rules Source Conflict
The current project GDD describes a custom FE tabletop adaptation. The new
Awakening corpus describes a normalized implementation of Awakening itself.

Problems this causes:
- class balance assumptions no longer match
- existing skills may keep the same names but different behavior
- current promotion and reclass rules are only partially aligned
- future bug reports become ambiguous because there are now two rule sources

Resolution:
- resolved: the Awakening corpus is now the canonical gameplay rules source
- the older project GDD should be treated as superseded where it conflicts
- migration work should target Awakening-correct behavior, not the prior
  tabletop-adaptation behavior

### 2. Progression Model Mismatch
The corpus requires displayed level and internal level as separate values, plus
Awakening-specific promotion and Second Seal behavior. The current unit model
has `level` plus `effective_level`, which is not the same thing.

Problems this causes:
- EXP scaling and enemy scaling will be wrong
- reclass level resets will look correct in UI but behave incorrectly internally
- child recruitment scaling cannot be implemented on the current model
- special classes using the level-30 rule cannot be expressed cleanly

Required refactor:
- replace or augment `effective_level` with explicit internal-level state
- centralize level conversion rules instead of splitting them across promotion,
  reclass, and combat EXP logic
- add tests for promotion, demotion, and reclass edge cases before migrating data

Resolved direction:
- `level` = displayed level
- `internal_level` = hidden canonical Awakening progression value
- repeated reclass pressure is separate from `internal_level`
- base classes use `internal_level = level`
- promoted classes use `internal_level = 20 + level`
- promotion resets displayed level to `1` and sets internal level to `21`
- repeated Second Seal behavior should preserve hidden progression pressure
- special classes should use explicit class-data rules

### 3. Class Schema Is Too Small
`ClassData.gd` can represent tier, promotions, growths, caps, skills, and
qualities, but the new corpus needs more structure than that.

Missing or underspecified data:
- Awakening class-family and reclass-set identity
- class-specific WEXP baselines per weapon type
- special-class legality and DLC gating
- vulnerability-group mapping separate from broad quality tags
- enemy-only or NPC-only restrictions

Problems this causes:
- reclass graphs cannot be generated from current data safely
- normalized special-class handling turns into scattered special cases
- imported classes would need ad hoc metadata in unrelated fields

Required refactor:
- expand class schema first
- add validation for graph legality, class-family membership, and class-role flags
- keep conversion helpers separate from runtime combat code

Resolved direction:
- add `class_category`
- add `class_family_id`
- add `internal_level_rule`
- add `vulnerability_groups`
- add `class_availability`
- keep `tier` as a meaningful numeric progression-depth field for future higher
  tiers
- do not add gender-lock or gender-replacement fields
- do not add `reclass_group_ids` in the first pass
- treat `class_availability` as a soft menu and legality filter, not a hard ban
  on direct designer-authored assignment
- universal playable-class access replaces Awakening-style per-character class
  pools for this project

Current status:
- done: `internal_level` replaced `effective_level`
- done: class-side `internal_level_rule`, `vulnerability_groups`, and
  `class_availability`
- done: unit-details WEXP/rank display for stored tracks
- still deferred: broader class-family/reclass identity and DLC/special-class
  access policy beyond the current soft availability field

### 4. Weapon and WEXP Model Mismatch
The corpus normalizes weapon rank as numeric WEXP with explicit thresholds,
carryover, retention, and inheritance behavior. The current project stores
`rank` plus `wexp`, but its runtime assumptions are simpler and not Awakening-complete.

Problems this causes:
- class base WEXP on promotion and reclass is not fully modeled
- beaststone and dragonstone families are not represented in valid weapon types
- inheritance and enemy weapon-rank assignment cannot be imported faithfully
- any automated content conversion will silently flatten legal rank states

Required refactor:
- make numeric WEXP the authoritative runtime value
- derive rank labels from thresholds instead of storing both as peers
- extend weapon typing and legality checks before importing stones or special weapons

Resolved direction:
- numeric `wexp` is the source of truth
- displayed weapon rank is always derived from threshold tables
- weapon identity and WEXP progression must be separate runtime concepts
- canonical WEXP tracks should be `sword`, `lance`, `axe`, `bow`,
  `elemental_magic`, `light`, `dark`, `staff`, `beaststone`, and
  `dragonstone`
- fire, thunder, and wind variants should collapse into the shared
  `elemental_magic` WEXP track and keep any elemental behavior in separate
  metadata
- light magic should remain its own WEXP track instead of collapsing into
  `elemental_magic`
- hybrid weapons should keep their combat behavior metadata while pointing at
  the physical track they actually train
- migration should treat existing `fire`, `thunder`, `wind`, and `light`
  proficiencies as legacy weapon-family data that maps into the new magic-track
  model

Recommended schema direction:
- `WeaponData` should separate:
  - equip/combat family
  - `wexp_track`
  - optional subtype metadata for elemental or special handling
- `ClassData` should replace the current ordered proficiency list with explicit
  numeric dictionaries keyed by WEXP track:
  - `weapon_wexp_bases`
  - `weapon_wexp_caps`
  - optional family-allowance metadata if combat-family filtering differs from
    WEXP-track access
- `UnitData` should store one authoritative numeric WEXP dictionary keyed by
  WEXP track, with rank labels derived on demand
- legacy save/content migration should normalize:
  - `fire`/`thunder`/`wind` -> `elemental_magic`
  - `light` -> `light`
  - `dark` -> `dark`
  - `staff` -> `staff`
- class entry logic should follow the corpus distinction between stored WEXP
  and class-limited active WEXP so promotion, reclassing, and enemy loadout
  assignment do not flatten legal states

Current status:
- done: weapon family and WEXP progression split
- done: authored data migration to `combat_family` / `wexp_track` /
  `weapon_wexp`
- done: stored WEXP persists even when the current class cannot actively use the
  track

### 5. Combat Engine Does Not Match Awakening
The corpus expects Awakening-specific combat sequencing, hidden behavior, Pair
Up interactions, Dual Strike, Dual Guard, effective damage rules, and proc
ordering. The current combat engine does not implement that full stack.

Known gaps or likely conflicts:
- no Pair Up lead/support model
- no Dual Strike or Dual Guard resolution
- many Awakening skills rely on timing hooks the current trigger set does not express
- current hit resolution is not modeled as Awakening's 2RN behavior
- effectiveness and class vulnerability handling are simpler than the corpus

Problems this causes:
- imported skills will look implemented but resolve on the wrong trigger window
- combat previews will disagree with real combat once Pair Up exists
- balancing around Awakening formulas will be impossible

Required refactor:
- define a new combat-context schema before adding Awakening-only mechanics
- implement combat timing tests first, then port mechanics in layers
- treat Pair Up as a foundational subsystem, not a skill effect

Immediate next pass:
- Pair Up scaffolding and combat-context refactor should be the next
  implementation pass
- Pair Up must be campaign-configurable so campaigns can disable it in settings
- Pair Up-related skills imported before full Pair Up support should receive an
  alternate effect or remain explicitly disabled

Next-session preparation:
- use `AGENT/Docs/archive/reference/pair_up_combat_refactor_questions_2026-05-23.md` as the
  starting question list before coding the next pass

### 6. Skill System Needs More Than More Skills
The existing skill handler is extensible, but the corpus expects a larger rules
surface than simple proc dispatch.

Missing capability areas:
- offensive proc exclusivity groups
- rally stacking and map-state interactions
- support-driven activation or scaling
- Pair Up and adjacent-support conditional logic
- inheritance legality filters
- DLC skill item acquisition rules

Problems this causes:
- skill behavior becomes order-dependent and fragile if added ad hoc
- preview logic will diverge from live combat if trigger semantics are inconsistent
- legality checking will be spread across UI, items, and unit code

Required refactor:
- formalize skill categories and exclusivity rules in data
- move more legality checks into shared validators
- add targeted unit tests per trigger family before bulk skill import

### 7. Item System Is Far Below Corpus Scope
`ItemHandler.gd` currently implements only healing, promotion, and reclass item
flows. The new item corpus includes tonics, permanent boosters, seals, keys,
DLC skill items, valuables, and utility items with special rules.

Problems this causes:
- most imported items would load as dead data
- temporary buffs need duration and stacking policy decisions
- permanent boosters need cap enforcement against class caps
- key and world-map utility items require systems that do not exist yet

Required refactor:
- split item effects into gameplay domains instead of a single small match block
- add validation that every imported effect id is implemented
- defer non-battle economy items unless the campaign layer exists

### 8. Child, Support, and Inheritance Systems Are Missing
The corpus includes child mechanics, skill inheritance, class inheritance,
recruitment scaling, and Avatar-specific rules. None of that exists in the
current runtime model.

Problems this causes:
- these systems cannot be approximated with current `UnitData`
- legality rules depend on parent identity and support state the game does not store
- balancing and recruitment examples in the corpus cannot be tested

Recommendation:
- treat this as a separate milestone after core progression compatibility
- do not let inheritance requirements leak into the initial class/content import

### 9. Enemy Generation Model Is Too Simple
The corpus expects deterministic enemy generation inputs, autoleveling,
difficulty scaling, class skill assignment, and equipment assignment. Current
enemy support is much lighter.

Problems this causes:
- enemies built from imported class data will not match corpus examples
- special classes and Risen-style monsters need generation rules not present now
- testing enemy balance against the corpus will produce misleading results

Required refactor:
- separate authored enemy units from generated enemy templates
- introduce an enemy-generation service with test fixtures from the appendices

### 10. Data Import Risk Is High
The new corpus is markdown reference data, not project-native `.tres` content.
It is also broad enough that manual transcription errors are likely.

Problems this causes:
- typos in ids, weapon types, class links, or skill links will be common
- schema drift between documents and runtime resources will accumulate quickly
- the content folder name itself contains typos, which is a warning sign for path stability

Required refactor:
- define import schemas before converting any content
- build validators and conversion scripts instead of hand-authoring everything
- keep imported Awakening data isolated from existing project data until validated

## Recommended Implementation Order

### Phase 0. Canon Decision
Choose one:
- replace the current forward-looking class/content design with Awakening canon
- keep current gameplay canon and use the new corpus only as optional inspiration

Without this, the refactor will drift.

### Phase 1. Compatibility Layer Design
- write canonical runtime schemas for classes, units, weapons, skills, and items
- define which Awakening concepts are first-class runtime concepts
- document exact mappings from corpus terms to code terms

### Phase 2. Progression Refactor
- add explicit internal level support
- rework promotion and Second Seal logic around shared level-state helpers
- add tests for displayed level, internal level, and class-change flows

### Phase 3. Class and Weapon Schema Expansion
- extend `ClassData` and `WeaponData`
- add validators in `DataManager`
- support stones, special classes, vulnerability groups, and class-family metadata
- perform the one-time repo data migration to the new weapon-family and
  WEXP-track schema in the same pass
- add unit tests for schema validation, WEXP derivation, and hybrid/special
  weapon behavior before moving on

### Phase 4. Combat Refactor
- update hit logic, combat order hooks, and effectiveness handling
- add Pair Up scaffolding even if support content is still disabled
- convert skill trigger timing to an explicit sequence model
- keep this as an explicit follow-up to the schema/migration pass; do not fold
  combat-sequence changes into the data-model refactor

### Phase 5. Skill and Item Refactor
- expand legality checking and resolver categories
- add tonic, booster, key, DLC-skill-item, and utility-effect support in layers
- keep each item family behind tests before data import

### Phase 6. Content Pipeline
- create parser or conversion scripts from markdown corpus to project resources
- import classes first, then weapons, then skills, then items
- reject imports that violate graph or trigger validation
- treat corpus import tooling as a later milestone after schema, migration,
  validation, and combat foundations are stable

### Phase 7. Advanced Systems
- enemy generation
- support and Pair Up scaling
- child and inheritance systems
- DLC compatibility flags

## Suggested Milestones
1. `AWR-0` Canon decision and runtime schema spec
2. `AWR-1` Internal-level and class-change refactor
3. `AWR-2` Class and weapon schema expansion
4. `AWR-3` Combat compatibility foundation
5. `AWR-4` Skill-system compatibility pass
6. `AWR-5` Item-system compatibility pass
7. `AWR-6` Corpus import tooling and validation
8. `AWR-7` Advanced Awakening-only systems

## Risks That Need Explicit Decisions
- whether child and DLC systems are in scope at all
- whether markdown corpus import is automated or manual

## Open Questions
- the exact schema shape for class-side numeric weapon baseline data and class
  maximum WEXP data
- how much of staff behavior should remain in generic weapon logic versus a
  dedicated staff resolver

## Recorded Next-Step To-Do
- Implement the class/weapon/unit schema refactor, one-time repo data
  migration, and unit tests together as a single bounded pass.
- Schedule a dedicated combat refactor immediately after the schema/migration
  pass to handle combat timing, effectiveness, and Pair Up scaffolding.
- In that combat refactor, include Pair Up scaffolding in the first pass, but
  keep full Pair Up mechanics campaign-configurable through settings so
  campaigns can disable the feature cleanly.
- Until Pair Up mechanics exist, give Pair Up-related skills explicit
  non-Pair-Up alternate effects or keep them disabled by explicit rule; do not
  ship them with dead or misleading behavior.
- Build markdown-corpus content import tooling later, after the runtime schema
  and combat foundation are stable enough to validate imported data correctly.
- whether combat-family allowances should live directly in `ClassData` or be
  derived from WEXP-track access plus optional exception metadata
- whether future weapon-family expansion should remain constant-driven for the
  first compatibility pass or move into fully data-driven family definitions

## Recommendation
Do not start by importing classes or skills. Start by refactoring the runtime
model to support the new rules vocabulary, especially internal levels, class
graph metadata, WEXP authority, combat timing, and Pair Up scaffolding.

If the project does not intend to become an Awakening-accurate simulator, the
better path is to treat this corpus as a reference library and selectively
adapt content instead of attempting full mechanical compatibility.
