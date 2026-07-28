---
Type: plan
Status: Active - implementation plan
Last verified: 2026-07-28
---

# Class EXP And PXP Boundary Plan

**Started:** 2026-06-29.

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
row `B4-PXP`.

**Purpose.** Record the implementation direction for class EXP, action EXP, and
the Proficiency / XP Framework (PXP) after reviewing whether class EXP should
merge into PXP.

## Decision

Do not merge class EXP storage or level-up lifecycle into PXP for the next
build.

Class EXP remains the unit-level progression path:

```text
UnitData.exp
UnitData.level
Unit.add_exp(amount)
level_up()
```

PXP owns proficiency tracks:

```text
UnitData.proficiency_xp[track_id]
advance_proficiency(track_id, amount)
```

The shared direction is not merged storage. The shared direction is common
authoring idioms: authored award amounts, profile-backed curves, validated
award sources, threshold/cap helpers where useful, and shared prep-service
benefit plumbing.

## Why Not Merge Class EXP Into PXP Now

Class EXP is not just numeric track progress. Crossing 100 EXP mutates the unit
lifecycle:

- increments level,
- rolls growth RNG,
- applies stat increases,
- clamps caps,
- opens level-up UI,
- checks class skill unlocks,
- updates internal level,
- changes promotion/reclass eligibility.

That makes class EXP higher risk than weapon/item/source proficiency. PXP
thresholds can grant ranks or events; class EXP thresholds can rewrite several
core unit fields and must stay deterministic across save/retry/suspend.

Merging now would also create unresolved design questions:

- Is the class track global, per class, per class line, or per unit lifecycle?
- Is `level` stored, derived, or duplicated beside a track total?
- How do repeated 100-EXP rollovers fit a rank-profile system built for named
  thresholds?
- Does PXP then own growth rolls, promotion, reclass, and level-up UI hooks?

Those answers would increase the blast radius of the first PXP build.

## Implementation Direction

1. **Keep class EXP state separate.**
   - Preserve `UnitData.exp`, `level`, `internal_level`, and `Unit.add_exp()`.
   - Preserve existing level-up/growth/promotion/reclass tests as class EXP
     authority tests.

2. **Make class EXP awards data-driven.**
   - Move combat EXP curve selection out of `CombatResolver` into a campaign
     rule/profile input.
   - Move staff/action EXP out of hardcoded staff logic into authored action
     data such as `exp_award`.
   - Ship today's combat table and staff value as developer presets.

3. **Build PXP for proficiency tracks.**
   - PXP owns weapon, item, source, and action proficiency tracks.
   - PXP owns rank profiles, proficiency thresholds, per-track caps, and
     on-crossing proficiency events.
   - PXP may read class EXP events as gain sources, such as `class_exp_share`,
     but it does not replace class EXP state.

4. **Share lower-level helpers only when useful.**
   - Award validation can share one `{benefit, amount, source}` shape.
   - Prep services can route `add_exp` and `advance_proficiency` through sibling
     benefit handlers.
   - Threshold/cap/profile parsing may share utilities after both paths prove
     the same need.

5. **Defer a generic progression primitive.**
   - If duplicate award/profile code becomes painful, introduce a lower-level
     progression helper consumed by both class EXP and PXP.
   - Do not make that helper the first PXP milestone.

6. **Keep progression pressure as sibling durable unit state.**
   - A campaign/rule profile may select a generic pressure profile; with no selected
     profile, no pressure field or behavior is created.
   - Durable pressure is not PXP and does not replace class EXP, level, or class.
     The profile-selected internal-level formula computes internal level from an
     immutable snapshot and supplies it as an input to EXP-related formulas.
   - Only the registered committed advancement-route trigger may update pressure.
     Preview, cancellation, validation failure, and ordinary promotion under the
     compatibility preset do not mutate it.
   - Save, suspend, Retry, Rewind, migration, and deterministic route-result events
     carry the pressure state and selected profile/formula versions.

7. **Use the generic advancement route for class changes.**
   - Fixed promotion, branching promotion, and reclass share one validate/select/
     commit path over `ClassAdvancement` edges and bounded operation registries.
   - Reclass destinations remain unit-owned. Selected class and edge variant ids are
     durable state; a cancelled or failed transition changes neither progression nor
     earned skills.
   - Class-authored `skill_unlocks` grant durable `earned_skills` through the bounded
     transition/level-up operation; PXP does not own those skills.

## Training And Bonus EXP Implication

Training halls and Bonus EXP should treat class EXP and PXP as sibling benefit
types:

```text
{ benefit: "class_exp", amount, cost } -> Unit.add_exp(amount)
{ benefit: "proficiency_xp", track, amount, cost } -> advance_proficiency(track, amount)
```

This keeps authoring consistent without making class leveling a proficiency
track.

## Validation

- Existing class EXP, level-up, promotion, and reclass tests keep passing under
  the developer preset.
- Combat EXP preset matches today's resolver table.
- Staff/action EXP preset matches today's staff award.
- Authored action EXP can grant class EXP without editing staff-specific code.
- PXP tests prove proficiency gain does not mutate class level unless an
  explicit authored benefit calls `add_exp`.
- Training/Bonus EXP tests cover both `class_exp` and `proficiency_xp` benefit
  handlers.
- No-profile fixtures preserve existing behavior; pressure-profile fixtures update
  once per qualifying commit, clamp and round by the selected profile, survive
  save/Retry/Rewind/suspend, and provide the same computed internal-level input to
  preview and execution.
- Fixed/branching advancement, variant migration, earned-skill grants, and cancelled/
  failed transition tests all use the same route path.

## Future Revisit Trigger

Revisit a shared progression primitive only if two conditions are true:

- class EXP award profiles and PXP profiles duplicate enough code to create real
  maintenance cost;
- the save schema and PXP track migration are already stable.

Until then, keep the boundary explicit.
