# Documentation Consolidation Handoff

**Date:** 2026-06-13
**Status:** Ready for next-session decision work
**Review:** `AGENT/Docs/documentation_consolidation_preimplementation_review_2026-06-13.md`

## Current State

The consolidation plan has been reviewed but is not ready for destructive file
moves or numbered-GDD rewrites. A read-only documentation inventory is safe.

Two review commits are complete:

- `7313ad7` - `Review documentation consolidation readiness`
- `7af677f` - `Record consolidation review session`

Both commit hooks passed all 38 automated suites.

## Preserve This Worktree State

The following pre-existing changes were deliberately left untouched:

- modified owner answers in
  `AGENT/Docs/documentation_consolidation_decisions_2026-06-12.md`
- untracked `AGENT/GDD/gdd_update_reference_2026-06-12.md`
- untracked `AGENT/GDD/rng_determinism_design_2026-06-11.md`
- untracked combat-preview screenshots and `.import` files in `AGENT/Docs`

Do not delete, overwrite, or fold these into an unrelated commit.

## Next Session Start

Read in this order:

1. latest session note:
   `AGENT/Session Notes/2026-06-13b.md`
2. this handoff
3. pre-implementation review
4. decision register
5. consolidation plan
6. June GDD update reference
7. RNG determinism contract

## First Work Package

Keep the first package documentation-only and non-destructive:

1. Import D-A through D-E, RNG-1 through RNG-4, and OPEN-1 through OPEN-13
   from the June update reference into the new decision system.
2. Give each imported item one disposition:
   `Retained`, `Superseded`, `Answered`, `Deferred` with roadmap owner, or
   `Open decision`.
3. Make DOC-001 explicitly supersede both D-C and the older compatibility
   plan's corpus-canon statements.
4. Mark ambiguous owner answers as `Needs clarification` instead of `Applied`.
5. Update the consolidation plan so adoption-matrix rows precede or accompany
   each corpus-derived GDD rewrite.
6. Add the two-RN RNG-contract update as a Package A prerequisite.

Do not move or delete files in this package.

## Recommended Clarifications

Use these defaults unless the owner chooses otherwise:

- **DOC-003:** Adopt the proposed status vocabulary after adding one concrete
  usage example per status.
- **DOC-007:** Explicitly accept moving the manual playbook to
  `AGENT/Docs/manual_test_playbook.md`.
- **RULE-003:** Preserve proportional progress within the old rank:
  `new_floor + floor(old_progress_ratio * new_rank_span)`, clamped below the
  next threshold.
- **RULE-005:** Split multiplayer promotion interruption into a separate
  UI/control decision. The unit owner's modal takes control after the triggering
  action fully commits; other controllers remain blocked until selection.
- **RULE-008:** Replace the current authored personal-growth component with the
  selected corpus archetype growth package, while retaining additive corpus
  class growths.
- **RULE-011:** Keep terrain-ID mappings open and assign the terrain design pass
  a roadmap ID before terrain implementation.
- **RULE-012:** Treat Pair Up pass 1 actions/stat bonuses as the current layer.
  Schedule Dual Strike and Dual Guard together as later combat work. Keep
  relationship ranks, conversations, marriage, and children outside 1.0 unless
  campaign design makes them required.

## Required Governance Artifacts

Before numbered-GDD rewriting or deletion, create:

1. A ratified status vocabulary with examples.
2. A standard GDD section template:
   `Status`, `Last verified`, `Summary`, `Implemented behavior`,
   `Target design`, `Known gaps`, and `Anchors`.
3. A permanent decision index path and globally unique ID format.
4. A file lifecycle table containing:
   current path, status, authority scope, merge/move/delete target, retained
   headings, inbound references, and acceptance check.
5. A repository-wide link/reference inventory including root documentation,
   inline paths, and code/data references.

## RNG Correction

RULE-001 changes the binding deterministic roll order:

1. Draw two integers from 0 through 99.
2. Floor their average.
3. Compare that value with resolved hit.
4. Draw crit only after a successful hit.
5. Draw skill activations at their defined trigger slots.

Update the RNG contract, fixed roll-order fixture, and save-compatibility notes
before implementing `RngService`.

## Stop Conditions

Pause the affected work if:

- an imported decision has two plausible current meanings
- a file's useful content has no confirmed merge target
- a move would leave unresolved inbound references
- a corpus rule lacks an exact source heading or project-variation entry
- implementation behavior would be selected without an answered decision

## Completion Gate

The consolidation can proceed to numbered-GDD rewrites only when every item in
the pre-implementation review's readiness gate is complete. File deletion starts
only after the lifecycle and link-migration table is reviewed.
