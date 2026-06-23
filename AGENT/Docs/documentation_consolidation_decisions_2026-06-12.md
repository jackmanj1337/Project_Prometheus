# Documentation Consolidation Decision Register

**Date opened:** 2026-06-12
**Status:** Active - owner answers required
**Related plan:** `AGENT/Docs/archive/consolidation/documentation_consolidation_plan_2026-06-12.md`

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

**Answer:** the numbered GDD should own project design rules with the corpus being used as refrence for building out features. The purpose of this consolidation session is to sort out contradictions and move towards one unified goal.

### DOC-002 - Current and target behavior layout

**Question:** How should a canonical GDD section present implemented behavior
and approved future behavior?

**Options:**

- A. One section with explicit `Implemented` and `Target design` subsections.
- B. Separate current-state and target-design documents.
- C. Keep only target design in the GDD and derive current state from code.

**Recommendation:** A. It keeps feature information together without claiming
the target is already shipped.

**Answer:** Have the GDD contain the design and a dated status marker. The design should contain a brief summary of what a feature does and then a larger section with the specs.

### DOC-003 - Status vocabulary

**Question:** Adopt the plan's shared status labels?

**Proposed labels:** Implemented, Pending validation, Known issue, Target
design, Planned, Deferred, Open decision, Historical, Superseded.

**Recommendation:** Adopt them and prohibit unqualified phrases such as
"current," "complete," or "canonical" in status-bearing sections.

**Answer:** Resolved 2026-06-13. Adopt the nine labels with one example each, and
prohibit unqualified phrases ("current," "complete," "canonical") in
status-bearing sections. A feature may carry a **split status** (separate
`Implemented` and `Target design` lines) during the migration period. The
ratified table lives in `AGENT/Docs/documentation_governance_2026-06-13.md`.
Status: **Applied** to governance artifact (not yet applied to numbered GDD).

### DOC-004 - Roadmap ownership

**Question:** What should happen to `GDD_10a_Overview.md`?

**Options:**

- A. Retire it and make `GDD_10_Roadmap.md` own content, order, and status.
- B. Keep it as a manually maintained non-authoritative summary.
- C. Generate it mechanically from structured roadmap data.

**Recommendation:** A for the consolidation pass. Consider C only after the
roadmap structure is stable.

**Answer:** Lets retire it and make the roadmap own content, order and status. Old documents such as 10a_overview should be removed and will be accessed through GitHub history if they are needed.

### DOC-005 - Feature-index location

**Question:** Where should the feature-oriented navigation table live?

**Options:**

- A. Inside `GDD_00_Overview.md`.
- B. New `GDD_Feature_Index.md`, linked prominently from `GDD_00`.

**Recommendation:** B. The index will become too large for the overview but
must remain part of the numbered/live GDD set.

**Answer:** A dedicated index should be fine

### DOC-006 - Historical checklist and assumptions

**Question:** Retain `GDD_09_Checklist.md` and `GDD_Assumptions.md` in the live
GDD directory?

**Options:**

- A. Keep them in place with stronger historical headers.
- B. Move them to a historical/archive subfolder and repair links.
- C. Merge remaining useful context, then delete them.

**Recommendation:** B. They remain useful provenance but should not sit beside
live contracts as peers.

**Answer:** Merge and delete them. They can be manually retrieved through github if needed.

### DOC-007 - Manual-test playbook location

**Question:** Should `GDD_Manual_Tasks.md` remain in `AGENT/GDD`?

**Recommendation:** Move it under `AGENT/Docs` as an operational testing
playbook, then link it from `testing_guide.md` and the feature index. It is not a
game-design contract.

**Answer:** Accepted 2026-06-13. Move `GDD_Manual_Tasks.md` to
`AGENT/Docs/guides/manual_test_playbook.md` and re-link from `testing_guide.md` and the
feature index. Status: **Needs clarification -> Answered** (move executed only
during the lifecycle/link-migration package, not now).

### DOC-008 - Superseded-document policy

**Question:** Should superseded plans be moved, or left at existing paths with
headers?

**Recommendation:** Initially leave them at existing paths with a standardized
supersession header. Moving many files immediately creates link churn and makes
Git history harder to follow. Perform archive moves later in dedicated batches.

**Answer:** Lets move/remove them now so that they don't get forgotten

### DOC-009 - Decision-log structure

**Question:** Continue appending unrelated addenda to
`design_decisions_log_2026-05-17.md`, or create a clearer structure?

**Options:**

- A. One permanent project decision log.
- B. Dated decision files plus a short index.
- C. Continue the current dated file with addenda.

**Recommendation:** B. Stable decision IDs and a central index make feature
navigation easier while keeping discussions scoped.

**Answer:** B Sounds fine

### DOC-010 - Location of the June reference contracts

**Question:** Should `gdd_update_reference_2026-06-12.md` and
`rng_determinism_design_2026-06-11.md` remain under `AGENT/GDD`?

**Recommendation:** Move both to `AGENT/Docs`. The update reference is an input
to consolidation. The RNG file is a supporting design contract until its
binding rules are integrated into the numbered GDD and decision log.

**Answer:** You can move them to Docs for now. But eventually the update reference should get marked as completed and discarded/archived and the RNG doc should get merged into where ever other feature designs go.

### DOC-011 - Documentation validation in CI

**Question:** Should link/lifecycle validation run in the commit hook and CI?

**Recommendation:** Add a fast documentation check to both. It should validate
links, required lifecycle headers, stable IDs, and forbidden legacy paths. Keep
it separate from the full Godot suite.

**Answer:** Sounds good

### DOC-012 - Legal/licensing release gate

**Question:** Should handbook/corpus permission, attribution, and derivative-use
review be a formal public-release gate?

**Recommendation:** Yes. Renaming FE-derived identifiers does not resolve rights
or attribution questions surrounding the source handbook/corpus.

**Answer:** Yes, make a note that this should be reviewed and resolved before the 1.0 release

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

**Answer:** A is fine

### RULE-002 - S-rank bonus

**Question:** The corpus defines C/A rank bonuses but leaves S rank
source-defined. What should S rank grant?

**Recommendation:** Retain the current project extension of `+10 Hit, +5 Crit,
+1 Damage`, applied by the combat engine rather than `s_rank_mastery`.

**Impact:** Requires removing automatic mastery-skill grants and migrating any
existing runtime/save representation.

**Answer:** The recommendation looks good

### RULE-003 - WEXP migration

**Question:** How should existing project WEXP totals migrate from
`0/100/200/300/400/500` thresholds to corpus thresholds?

**Options:**

- A. Preserve rank floor only.
- B. Preserve proportional progress within the current rank.
- C. Reset each track to the corpus baseline for the unit's class.

**Recommendation:** B. It preserves both earned rank and progress without
keeping obsolete numeric meaning.

**Answer:** Option B, defined 2026-06-13. There is no persistent player save data
to migrate; this formula governs in-session/runtime conversion and any future
save migration. Formula:

```
ratio     = (old_wexp - old_rank_floor) / (old_next_floor - old_rank_floor)
new_span  = corpus_next_floor - corpus_rank_floor
new_wexp  = corpus_rank_floor + floor(ratio * new_span)
new_wexp  = min(new_wexp, corpus_next_floor - 1)   # never auto-promote a rank
```

Boundary handling: a unit already at max rank stays at the corpus max-rank floor;
`ratio` is clamped to `[0, 1)` so rounding never crosses the next threshold.
Status: **Answered**.

### RULE-004 - WEXP gain timing

**Question:** Should corpus WEXP be granted per combat round/use, including
misses where applicable, or retain the current per-successful-hit model?

**Recommendation:** Adopt corpus-style per valid use with weapon-defined
exceptions. Add explicit hit/miss/staff gain fields only if the content needs
different values.

**Answer:** Lets start with the recomendation and leave a note that this may get changed with game balance passes later.

### RULE-005 - Promotion trigger timing

**Question:** With corpus promotion eligibility beginning at level 10, when
does automatic promotion occur?

**Options:**

- A. Seals permit level-10 promotion; automatic promotion remains at class cap.
- B. Both seal and automatic promotion become available at level 10.
- C. Remove automatic promotion and require a seal.

**Recommendation:** A. It preserves the current convenience setting while
making early promotion an explicit player tradeoff.

**Answer:** Lets go with the basis of seals can promote at 10, but campaign settings can allow for automatic promotion when the unit reaches the level cap for their current class. Note that the promotion menu should pop up instantly even interupting other players turns, with control only shifting back to the original player after the unit owner has picked a new class.

**UI/control sub-decision (clarified 2026-06-13):** The promotion modal opens only
**after the triggering action fully commits** (combat resolves and EXP is applied).
While open, **all controllers are blocked** until the owning player selects a class.
Promotion is **mandatory once triggered — no cancel** (a seal/level-cap trigger
always resolves to a class choice). This keeps the deterministic event stream and
online sync unambiguous: the interrupt point is the post-commit eligibility check,
not mid-action. Status: **Answered**.

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

**Answer:** recomendation looks good

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

**Answer:** Lets transfer completely to corpus based classes and archive the old classes

### RULE-008 - Personal versus class growths during corpus class adoption

**Question:** The corpus class tables provide class growth modifiers while
current roster entries have authored personal growths. Should existing personal
growths remain?

**Recommendation:** Keep personal growths as character identity and replace
only class growth components with corpus values. Rebalance the starter roster
after combined growth totals are visible.

**Answer:** Use new corpus data. It should contain archetypal examples of character growth stats that should be usable for this testing period.

**Clarified 2026-06-13:** For the testing period, **replace** each unit's authored
personal growths. Effective growth = `corpus_archetype_growth + corpus_class_growth`.
Authored personal growths are dropped (recoverable via git history) and the roster
is rebalanced once combined totals are visible. Status: **Answered**.

### RULE-009 - Light and Dark magic design scope

**Question:** Where should the project-specific Light/Dark class lines be
scheduled?

**Recommendation:** Add a dedicated design task before bulk class/content
migration. It should define class lines, promotion paths, tome access, skill
identity, and magic-triangle balance before resources are authored.

**Answer:** Lets go with the recomendation

### RULE-010 - Terrain migration rollout

**Question:** Should the GDD immediately replace current terrain rules with
corpus values, or preserve both current and target tables until implementation?

**Recommendation:** Show both with explicit status until code/data/maps migrate:
`Implemented` for current values and `Target design` for corpus values.

**Impact:** Map 001 and validation maps will need pathfinding, healing, pacing,
and balance regression passes.

**Answer:** The recomendation is fine

### RULE-011 - Existing terrain ID mapping

**Question:** Confirm project mappings for current IDs that do not map cleanly
to corpus terrain categories, especially `sea`, wall/building variants, and
throne art currently using Fort behavior.

**Recommendation:** Decide mappings during the terrain design pass rather than
assuming name equality.

**Answer:** Deferred with owner 2026-06-13. The complete terrain ID-mapping pass
is assigned roadmap ID **AWR-8 (Terrain corpus migration & ID mapping)** under the
existing `AWR-` milestone scheme in
`awakening_compatability_refactor_plan_2026-05-22.md`; its exact slot in the AWR
sequence is set during the roadmap rewrite. Until then the GDD terrain
ID-mapping section stays **Open decision** (sea, wall/building variants, and
Fort-behavior throne art resolved in AWR-8, not by name equality).
Status: **Deferred (roadmap owner AWR-8)**.

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

**Answer:** Lets seperate out dual strike, dual guard, and stat bonuses from the other support stuff  and work on that later

**Scoped 2026-06-13 — 1.0 layer breakdown:**

- **IN 1.0:** Layer 1, Pair Up stat bonuses/actions (already **Implemented**,
  pass 1). Migrating its values to exact corpus numbers is **Planned** (later AWR
  Pair Up pass), not required for 1.0.
- **Later combat work (Target design):** Dual Strike (layer 2) and Dual Guard
  (layer 3), scheduled together under the AWR combat foundation.
- **Post-1.0 (Deferred):** adjacent support (4), support-rank progression (5),
  support conversations (6), S-rank/marriage (7), child units/inheritance (8) —
  unless short-campaign content makes one explicitly required.

Status: **Answered**.

### RULE-013 - Project-specific magic triangle rank source

**Question:** Which rank determines the scaled bonus for hybrid weapons that
have a physical weapon family and a magic `triangle_family`?

**Recommendation:** Use the equipped weapon's trained WEXP track for the bonus
magnitude, while `triangle_family` determines only the relationship. This avoids
inventing a second hidden magic rank for a sword/lance/axe weapon.

**Answer:** This sounds fine

### DOC-013 - Split-status phrasing ("project" vs "corpus", not "current")

**Question:** Split-status `Status:` lines across GDD_02–05/08 named the shipped half
with the word "current" (e.g. "current values **Implemented**; corpus values **Target
design**"). DOC-003 prohibits the bare word "current" in status-bearing sections. How
should the two halves be phrased?

**Recommendation (clarifies DOC-003):** Use **project** for the shipped half and
**corpus** (or the named target) for the migration half — the DOC-001 authority axis,
with no shipped/aspirational ambiguity. Enforce via `check_docs.py` checks 7–8 on
GDD_00–08.

**Answer (2026-06-13):** Adopt project/corpus phrasing. Applied: ~13 status lines
reworded; governance addendum added under DOC-003; checks 7–8 added to `check_docs.py`.
Status: **Applied**. Detail in `documentation_governance_2026-06-13.md` §Split-status
phrasing.

