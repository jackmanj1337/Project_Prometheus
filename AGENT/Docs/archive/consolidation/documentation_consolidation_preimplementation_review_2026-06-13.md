> **Historical** — archived 2026-06-23 in the docs reorg (by-type layout). Kept for provenance; not an active doc. See `AGENT/Docs/INDEX.md`.

# Documentation Consolidation Pre-Implementation Review

**Date:** 2026-06-13
**Reviewed:**

- `documentation_consolidation_decisions_2026-06-12.md`
- `documentation_consolidation_plan_2026-06-12.md`
- their current decision, GDD, roadmap, corpus, and testing inputs

## Executive Summary

The consolidation direction is sound, but the plan is not ready for destructive
moves or numbered-GDD rewrites. A read-only inventory can begin now. The gaps
below should be closed before Phase 2 or later work starts.

## Findings

### [HIGH] Earlier decisions and open questions are not fully migrated

- **Evidence:** The new register says it is the only place for unresolved
  choices (`documentation_consolidation_decisions_2026-06-12.md:9`), but
  `gdd_update_reference_2026-06-12.md:21` contains D-A through D-E and
  `gdd_update_reference_2026-06-12.md:246` contains OPEN-1 through OPEN-13.
- **Conflict:** D-C says the corpus is authoritative
  (`gdd_update_reference_2026-06-12.md:37`), while DOC-001 says the numbered GDD
  owns project rules
  (`documentation_consolidation_decisions_2026-06-12.md:86`). The older
  compatibility plan also calls the corpus the gameplay canon
  (`awakening_compatability_refactor_plan_2026-05-22.md:39`).
- **Risk:** The authority rewrite could preserve two incompatible ratified
  rules, and unresolved behavior could be lost when the update reference is
  archived or deleted.
- **Required fix:** Import every D-A through D-E, RNG-1 through RNG-4, and
  OPEN-1 through OPEN-13 item into the new decision system. Mark each as
  retained, superseded, answered, deferred with a roadmap owner, or still open.
  DOC-001 must explicitly supersede D-C and the older corpus-canon statements.

### [HIGH] The governance model is not yet ratified enough to template the GDD

- **Evidence:** DOC-003 explicitly requests examples before confirmation
  (`documentation_consolidation_decisions_2026-06-12.md:115`). DOC-002 asks how
  implemented and target behavior coexist, but its answer only requests a dated
  status marker and a summary/spec layout
  (`documentation_consolidation_decisions_2026-06-12.md:99`).
- **Risk:** Contributors can apply different status meanings and recreate the
  current/target ambiguity the project is trying to remove.
- **Required fix:** Add one example for every status label, then ratify the
  vocabulary. Define a standard major-section template with fields for
  `Status`, `Last verified`, `Summary`, `Implemented behavior`,
  `Target design`, `Known gaps`, and `Anchors`. Clarify whether a feature can
  carry separate implementation and target statuses.

### [HIGH] Destructive file handling conflicts with the plan and lacks a move map

- **Evidence:** DOC-004 removes `GDD_10a`, DOC-006 merges and deletes
  `GDD_09`/`GDD_Assumptions`, and DOC-008 says to move or remove superseded
  documents now. The plan still says superseded files should normally be
  retained with headers
  (`documentation_consolidation_plan_2026-06-12.md:106`) and postpones cleanup
  until Phases 5 and 6.
- **Risk:** Useful material or live links can be lost. Current non-session
  references include `README.md`, `GDD_00`, `GDD_10`, `testing_guide.md`, and
  several active validation plans.
- **Required fix:** Before deletion, create a file-by-file lifecycle table with
  the destination or merge target, retained headings, inbound references, and
  deletion acceptance check. Apply each move/delete atomically with all live
  link repairs. Name the new manual playbook path before moving
  `GDD_Manual_Tasks.md`.

### [HIGH] Corpus adoption is sequenced after GDD rewriting

- **Evidence:** Phase 3 rewrites `GDD_01` through `GDD_08`
  (`documentation_consolidation_plan_2026-06-12.md:397`), while the systematic
  adoption matrix is not expanded until Phase 4
  (`documentation_consolidation_plan_2026-06-12.md:423`).
- **Risk:** Broad directions such as "adopt corpus formulas" can be copied into
  the GDD without recording exact source sections, corpus version, or project
  variations. This violates DOC-001's explicit-adoption boundary.
- **Required fix:** For each work package, complete its adoption-matrix rows
  before or in the same commit as its GDD rewrite. Record the corpus version,
  exact headings, adopted rules, rejected rules, project variations, and
  implementation status.

### [HIGH] The ratified RNG contract still defines one hit draw

- **Evidence:** RULE-001 adopts two RN
  (`documentation_consolidation_decisions_2026-06-12.md:242`), but the ratified
  RNG contract draws one hit roll per strike
  (`rng_determinism_design_2026-06-11.md:217`). Its fixed-value test freezes that
  old order (`rng_determinism_design_2026-06-11.md:393`).
- **Risk:** GDD, tests, and future RNG implementation will disagree about the
  deterministic event stream.
- **Required fix:** Make the RNG contract update an explicit prerequisite for
  Package A. Specify two 0-99 draws, floor the average, compare it to resolved
  hit, then draw crit and skill activations only when appropriate. Update the
  roll-order fixture and save-compatibility notes before code work begins.

### [MEDIUM] Several answers are still ambiguous or intentionally deferred

- **DOC-007:** "likely for the best" should become an explicit accepted option.
- **RULE-003:** Define the proportional WEXP formula and boundary handling even
  if there is no persistent player save.
- **RULE-005:** Split cross-player promotion interruption into a UI/control
  decision covering queueing, ownership, cancellation, and online behavior.
- **RULE-008:** State explicitly whether archetype growths replace current
  personal growths. The corpus says archetypes are a unit component added to
  class growths (`awakening_archetypes.md:49`).
- **RULE-011:** Give the later terrain-mapping pass a roadmap ID and keep the
  affected GDD section `Open decision`.
- **RULE-012:** State which Pair Up/support layers are required for 1.0 and
  whether stat bonuses are current, replacement work, or future work.

These entries should be marked `Needs clarification`, not treated as fully
answered.

### [MEDIUM] The permanent decision-record structure is not specified

- **Evidence:** DOC-009 selects dated decision files plus an index, but no path,
  filename pattern, schema, or ID namespace is defined.
- **Risk:** Existing identifiers already overlap (`D1`, `Decision 1`, `A1`,
  `RNG-1`, `DOC-001`, and `RULE-001`). A central index cannot reliably validate
  or link them without globally unique keys.
- **Required fix:** Define the decision index path, dated record filename
  pattern, globally unique ID format, required metadata, supersession links,
  and the workflow that moves an answered register item to `Applied`.

### [MEDIUM] Inventory and validation scope is too narrow

- **Evidence:** Phase 1 asks for inbound links from current documents
  (`documentation_consolidation_plan_2026-06-12.md:364`), but root files and
  non-Markdown references can also point at moved documents. `README.md:19`
  currently links to `GDD_10a`.
- **Risk:** Moves may leave onboarding, code comments, resources, or scripts
  with stale paths even if Markdown-to-Markdown links pass.
- **Required fix:** Inventory all tracked documentation, including
  `README.md`, `AGENTS.md`, and `CLAUDE.md`, and search the whole repository for
  path references. Define whether CI validates Markdown links only, inline
  backtick paths, heading anchors, and references in code/data.

### [MEDIUM] Release and project-level decisions are absent from completion work

- **Evidence:** D-A public identity, D-B the 1.0 definition, D-D campaign
  prerequisites, and D-E reclass growth are present in the June update
  reference but absent from the consolidation packages and completion criteria.
  DOC-012 adds a legal gate, but the plan does not name its roadmap owner.
- **Risk:** The rewritten GDD can become internally cleaner while still omitting
  release-defining decisions and gates.
- **Required fix:** Add a project/release package covering the 1.0 definition,
  rename gate, legal/licensing gate, platform/renderer decisions, campaign
  prerequisites, and their roadmap IDs.

## Recommended Readiness Gate

Before Phase 2 or any deletion:

1. Migrate and classify all old decisions and open questions.
2. Ratify the status vocabulary and GDD section template.
3. Define the decision-record schema and unique ID namespace.
4. Produce the file lifecycle/link-migration table.
5. Reorder adoption-matrix work to precede each corpus-derived GDD rewrite.
6. Update the RNG contract for two-RN.
7. Reopen or split the ambiguous answers listed above.

Phase 1's read-only inventory is safe to start before these are complete.
