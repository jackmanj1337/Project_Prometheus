# Documentation Consolidation Decision Register

**Date opened:** 2026-06-12
**Status:** Active - owner answers required
**Related plan:** `AGENT/Docs/documentation_consolidation_plan_2026-06-12.md`

## How to Use This File

This file is the only place where unresolved choices discovered during the
documentation consolidation should be answered.

For each open item:

1. Replace `Pending` with the selected option or a short custom answer.
2. Add any constraints that matter.
3. Leave the recommendation and consequences in place for history.
4. After implementation, mark the item `Applied` and link the resulting dated
   decision/GDD change.

Do not resolve these choices indirectly by editing a GDD chapter.

## Settled Directions From 2026-06-12

These directions were given by the project owner. They are not open questions,
but some require the detailed choices listed later.

### SET-001 - Combat formulas

**Direction:** Plan migration to the Awakening corpus combat-stat formulas.

### SET-002 - Hit RNG

**Direction:** Plan migration to the corpus two-RN hit model. Update the
deterministic RNG design before implementation so its canonical draw order is
not based on the old single-roll rule.

### SET-003 - Weapon triangles

**Direction:** Adopt rank-scaled corpus triangle bonuses, but retain both
project triangles:

- Sword -> Axe -> Lance -> Sword
- Dark -> Anima -> Light -> Dark

The magic triangle uses the same rank-scaling table as the physical triangle.

### SET-004 - WEXP

**Direction:** Plan migration to corpus WEXP thresholds, caps, and rank
progression.

### SET-005 - Weapon-rank combat bonuses

**Direction:** Plan migration to corpus rank bonuses. Rank bonuses belong in
the regular combat engine. `s_rank_mastery` should no longer be modeled as an
equipped or pseudo skill.

### SET-006 - Promotion

**Direction:** Plan migration to the corpus promotion model.

### SET-007 - Reclass progression counters

**Direction:** Reclassing resets the value used to calculate EXP gain bonuses.
Also retain total lifetime levels gained for possible use by a future
autoscaling-enemy mode.

### SET-008 - Terrain

**Direction:** Plan migration to corpus terrain values and movement categories.

### SET-009 - Class definitions

**Direction:** Switch current class designs to the corpus versions as the
target. Add explicit roadmap work to design Light- and Dark-magic users for the
project's retained magic triangle.

### SET-010 - Pair Up and supports

**Direction:** Treat the corpus Pair Up/support model as the eventual target,
while continuing to distinguish current Pair Up pass 1 from unimplemented
layers.

## Open Documentation-Governance Decisions

### DOC-001 - Project/corpus authority boundary

**Question:** Can a later corpus edit automatically change project rules?

**Recommendation:** No. The numbered GDD owns project rules and target design.
The corpus owns Awakening reference behavior. Corpus behavior becomes a project
target only through an explicit adoption entry and GDD update.

**Why:** Automatic authority would allow an external-reference edit to change
combat math, scope, or migration behavior without a project decision.

**Answer:** Pending

### DOC-002 - Current and target behavior layout

**Question:** How should a canonical GDD section present implemented behavior
and approved future behavior?

**Options:**

- A. One section with explicit `Implemented` and `Target design` subsections.
- B. Separate current-state and target-design documents.
- C. Keep only target design in the GDD and derive current state from code.

**Recommendation:** A. It keeps feature information together without claiming
the target is already shipped.

**Answer:** Pending

### DOC-003 - Status vocabulary

**Question:** Adopt the plan's shared status labels?

**Proposed labels:** Implemented, Pending validation, Known issue, Target
design, Planned, Deferred, Open decision, Historical, Superseded.

**Recommendation:** Adopt them and prohibit unqualified phrases such as
"current," "complete," or "canonical" in status-bearing sections.

**Answer:** Pending

### DOC-004 - Roadmap ownership

**Question:** What should happen to `GDD_10a_Overview.md`?

**Options:**

- A. Retire it and make `GDD_10_Roadmap.md` own content, order, and status.
- B. Keep it as a manually maintained non-authoritative summary.
- C. Generate it mechanically from structured roadmap data.

**Recommendation:** A for the consolidation pass. Consider C only after the
roadmap structure is stable.

**Answer:** Pending

### DOC-005 - Feature-index location

**Question:** Where should the feature-oriented navigation table live?

**Options:**

- A. Inside `GDD_00_Overview.md`.
- B. New `GDD_Feature_Index.md`, linked prominently from `GDD_00`.

**Recommendation:** B. The index will become too large for the overview but
must remain part of the numbered/live GDD set.

**Answer:** Pending

### DOC-006 - Historical checklist and assumptions

**Question:** Retain `GDD_09_Checklist.md` and `GDD_Assumptions.md` in the live
GDD directory?

**Options:**

- A. Keep them in place with stronger historical headers.
- B. Move them to a historical/archive subfolder and repair links.
- C. Merge remaining useful context, then delete them.

**Recommendation:** B. They remain useful provenance but should not sit beside
live contracts as peers.

**Answer:** Pending

### DOC-007 - Manual-test playbook location

**Question:** Should `GDD_Manual_Tasks.md` remain in `AGENT/GDD`?

**Recommendation:** Move it under `AGENT/Docs` as an operational testing
playbook, then link it from `testing_guide.md` and the feature index. It is not a
game-design contract.

**Answer:** Pending

### DOC-008 - Superseded-document policy

**Question:** Should superseded plans be moved, or left at existing paths with
headers?

**Recommendation:** Initially leave them at existing paths with a standardized
supersession header. Moving many files immediately creates link churn and makes
Git history harder to follow. Perform archive moves later in dedicated batches.

**Answer:** Pending

### DOC-009 - Decision-log structure

**Question:** Continue appending unrelated addenda to
`design_decisions_log_2026-05-17.md`, or create a clearer structure?

**Options:**

- A. One permanent project decision log.
- B. Dated decision files plus a short index.
- C. Continue the current dated file with addenda.

**Recommendation:** B. Stable decision IDs and a central index make feature
navigation easier while keeping discussions scoped.

**Answer:** Pending

### DOC-010 - Location of the June reference contracts

**Question:** Should `gdd_update_reference_2026-06-12.md` and
`rng_determinism_design_2026-06-11.md` remain under `AGENT/GDD`?

**Recommendation:** Move both to `AGENT/Docs`. The update reference is an input
to consolidation. The RNG file is a supporting design contract until its
binding rules are integrated into the numbered GDD and decision log.

**Answer:** Pending

### DOC-011 - Documentation validation in CI

**Question:** Should link/lifecycle validation run in the commit hook and CI?

**Recommendation:** Add a fast documentation check to both. It should validate
links, required lifecycle headers, stable IDs, and forbidden legacy paths. Keep
it separate from the full Godot suite.

**Answer:** Pending

### DOC-012 - Legal/licensing release gate

**Question:** Should handbook/corpus permission, attribution, and derivative-use
review be a formal public-release gate?

**Recommendation:** Yes. Renaming FE-derived identifiers does not resolve rights
or attribution questions surrounding the source handbook/corpus.

**Answer:** Pending

## Open Rules and Migration Decisions

### RULE-001 - Exact two-RN model

**Question:** Which two-RN curve should the project adopt?

**Options:**

- A. Corpus recommendation: roll two integers 0-99 and compare their floored
  average with displayed hit.
- B. Use a mathematically equivalent true-hit lookup/curve.

**Recommendation:** A. It is direct, testable, and compatible with the
hash-chained event RNG once the roll order is updated.

**Impact:** Changes deterministic combat fixtures and consumes two hit draws per
strike instead of one.

**Answer:** Pending

### RULE-002 - S-rank bonus

**Question:** The corpus defines C/A rank bonuses but leaves S rank
source-defined. What should S rank grant?

**Recommendation:** Retain the current project extension of `+10 Hit, +5 Crit,
+1 Damage`, applied by the combat engine rather than `s_rank_mastery`.

**Impact:** Requires removing automatic mastery-skill grants and migrating any
existing runtime/save representation.

**Answer:** Pending

### RULE-003 - WEXP migration

**Question:** How should existing project WEXP totals migrate from
`0/100/200/300/400/500` thresholds to corpus thresholds?

**Options:**

- A. Preserve rank floor only.
- B. Preserve proportional progress within the current rank.
- C. Reset each track to the corpus baseline for the unit's class.

**Recommendation:** B. It preserves both earned rank and progress without
keeping obsolete numeric meaning.

**Answer:** Pending

### RULE-004 - WEXP gain timing

**Question:** Should corpus WEXP be granted per combat round/use, including
misses where applicable, or retain the current per-successful-hit model?

**Recommendation:** Adopt corpus-style per valid use with weapon-defined
exceptions. Add explicit hit/miss/staff gain fields only if the content needs
different values.

**Answer:** Pending

### RULE-005 - Promotion trigger timing

**Question:** With corpus promotion eligibility beginning at level 10, when
does automatic promotion occur?

**Options:**

- A. Seals permit level-10 promotion; automatic promotion remains at class cap.
- B. Both seal and automatic promotion become available at level 10.
- C. Remove automatic promotion and require a seal.

**Recommendation:** A. It preserves the current convenience setting while
making early promotion an explicit player tradeoff.

**Answer:** Pending

### RULE-006 - Reclass EXP counters

**Question:** Confirm the progression fields and semantics.

**Proposed model:**

- `displayed_level` - current class-track level
- `exp_basis_level` - resets according to reclass rules and drives EXP gain
- `lifetime_levels_gained` - monotonically increases and is reserved for
  analytics/future enemy autoscaling

**Recommendation:** Adopt this separation. Do not use
`lifetime_levels_gained` to reduce player EXP unless a future campaign rule
explicitly says so.

**Answer:** Pending

### RULE-007 - Class replacement scope

**Question:** When current starter classes adopt corpus versions, what happens
to project/tabletop-only promotion targets such as Sentinel, Bishop, Paragon,
and Mage Knight?

**Options:**

- A. Remove them from the main class lines and archive them as unadopted
  homebrew content.
- B. Keep them as additional project-specific promotion branches.
- C. Review each class individually.

**Recommendation:** C. A blanket rule may create three-target promotion trees
or preserve classes that conflict with the intended Awakening baseline.

**Answer:** Pending

### RULE-008 - Personal versus class growths during corpus class adoption

**Question:** The corpus class tables provide class growth modifiers while
current roster entries have authored personal growths. Should existing personal
growths remain?

**Recommendation:** Keep personal growths as character identity and replace
only class growth components with corpus values. Rebalance the starter roster
after combined growth totals are visible.

**Answer:** Pending

### RULE-009 - Light and Dark magic design scope

**Question:** Where should the project-specific Light/Dark class lines be
scheduled?

**Recommendation:** Add a dedicated design task before bulk class/content
migration. It should define class lines, promotion paths, tome access, skill
identity, and magic-triangle balance before resources are authored.

**Answer:** Pending

### RULE-010 - Terrain migration rollout

**Question:** Should the GDD immediately replace current terrain rules with
corpus values, or preserve both current and target tables until implementation?

**Recommendation:** Show both with explicit status until code/data/maps migrate:
`Implemented` for current values and `Target design` for corpus values.

**Impact:** Map 001 and validation maps will need pathfinding, healing, pacing,
and balance regression passes.

**Answer:** Pending

### RULE-011 - Existing terrain ID mapping

**Question:** Confirm project mappings for current IDs that do not map cleanly
to corpus terrain categories, especially `sea`, wall/building variants, and
throne art currently using Fort behavior.

**Recommendation:** Decide mappings during the terrain design pass rather than
assuming name equality.

**Answer:** Pending

### RULE-012 - Pair Up/support release scope

**Question:** Which corpus layers are required for 1.0?

**Layers:**

- Pair Up stat bonuses/actions
- Dual Strike
- Dual Guard
- adjacent support
- support-rank progression
- support conversations
- S-rank/marriage
- child units and inheritance

**Recommendation:** Keep Pair Up pass 1 in 1.0 only if campaign content uses it.
Schedule Dual Strike/Guard and support ranks separately. Treat marriage and
children as post-1.0 unless the short campaign specifically depends on them.

**Answer:** Pending

### RULE-013 - Project-specific magic triangle rank source

**Question:** Which rank determines the scaled bonus for hybrid weapons that
have a physical weapon family and a magic `triangle_family`?

**Recommendation:** Use the equipped weapon's trained WEXP track for the bonus
magnitude, while `triangle_family` determines only the relationship. This avoids
inventing a second hidden magic rank for a sword/lance/axe weapon.

**Answer:** Pending
