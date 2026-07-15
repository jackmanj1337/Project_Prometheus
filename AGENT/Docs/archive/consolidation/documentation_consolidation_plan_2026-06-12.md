> **Historical** — archived 2026-06-23 in the docs reorg (by-type layout). Kept for provenance; not an active doc. See `AGENT/Docs/INDEX.md`.

# Documentation Consolidation and Living-GDD Plan

**Date:** 2026-06-12
**Status:** Draft for staged implementation
**Decision register:** `AGENT/Docs/documentation_consolidation_decisions_2026-06-12.md`

## 1. Goal

Make the numbered GDD the practical entry point for designing, building,
testing, and maintaining the game without erasing useful history or copying
the same rule into several places.

After consolidation, a contributor working on a feature or fix should be able
to answer these questions quickly:

1. What is implemented now?
2. What is the approved target behavior?
3. What remains planned, deferred, broken, or unverified?
4. Which code, data, tests, validation maps, and operational guides own it?
5. Which decisions explain intentional differences from the Awakening corpus?
6. What documentation must change when the feature changes?

## 2. Problems Being Solved

### 2.1 Competing authority claims

The repository currently has rules and status information in:

- numbered GDD chapters
- dated decision logs and design notes
- the Awakening reference corpus
- implementation and refactor plans
- roadmap overview and detailed roadmap files
- assumptions and historical checklists
- manual test notes and playtest findings
- code, data resources, and tests

Several of these files use terms such as "canonical" or "authoritative" for
different scopes. Without a strict scope boundary, a later reference update can
appear to change live project rules without an explicit project decision.

### 2.2 Current behavior and target design are mixed

Some chapters describe shipped behavior, future design, historical migration,
and implementation examples in the same section. Readers can mistake a target
rule for working code or treat a historical field name as current.

### 2.3 Roadmap information is duplicated

`GDD_10_Roadmap.md` contains milestone content while
`GDD_10a_Overview.md` contains ordering and a large completion history. Both
must be updated together, and both currently claim part of roadmap authority.

### 2.4 Historical plans remain discoverable as instructions

Old implementation plans, handoff files, assumptions, and checklist entries
contain valuable rationale but can still be reached from current documents
without a clear supersession warning.

### 2.5 Feature information is difficult to traverse

Working on one feature can require manually searching:

- a GDD rule chapter
- an architecture chapter
- roadmap entries
- a dated decision
- a validation-map plan
- manual test steps
- code and resource files

The information should remain in the document that owns it, but the GDD needs
an index that connects those owners.

## 3. Consolidation Principles

### 3.1 One owner per fact

Every durable fact gets one authoritative home. Other documents link to it and
summarize only when the summary is necessary for navigation.

Examples:

- combat rules belong in `GDD_02`
- class definitions and progression relationships belong in `GDD_03`
- resource/API contracts belong in `GDD_01`
- roadmap status and dependencies belong in the canonical roadmap
- test commands belong in `AGENT/Docs/testing_guide.md`
- detailed manual acceptance steps belong in the manual-test playbook
- historical evidence remains in audits, reviews, and session notes

### 3.2 Decisions do not remain hidden in plans

A proposal in an audit, review, corpus file, or implementation plan does not
become a project rule by being copied into the GDD.

When consolidation encounters a choice:

1. Add it to the companion decision register.
2. Record the conflicting sources and affected chapters.
3. Add a recommendation and consequences.
4. Leave the normative GDD unchanged until the owner answers.
5. After an answer, record the settled decision and update all affected
   canonical sections in one logical change.

### 3.3 Preserve history without preserving ambiguity

**Owner policy (DOC-004/006/008/010, 2026-06-13):** superseded and historical
documents are **moved or removed now**, not left in place with headers. Useful
content is merged into its owning GDD/decision home first; the original is then
retrieved through Git history if ever needed. Specifically:

- `GDD_10a_Overview.md` is retired; the roadmap owns content/order/status (DOC-004).
- `GDD_09_Checklist.md` and `GDD_Assumptions.md` are merged then deleted (DOC-006).
- Superseded plans are moved/removed in dedicated batches now (DOC-008).
- `gdd_update_reference_2026-06-12.md` and `rng_determinism_design_2026-06-11.md`
  move to `AGENT/Docs` now; the update reference is later archived once applied,
  and the RNG contract merges into the GDD feature-design home (DOC-010).

**Gate:** no move or deletion happens before the file lifecycle / link-migration
table (Phase 1) is reviewed, so no useful content or live inbound link is lost.
Each move/delete is applied atomically with all link repairs.

Current documents must stop linking to superseded plans as implementation
instructions.

### 3.4 Separate status from authority

A file may be authoritative for a target design even when the target is not
implemented. Every canonical section therefore needs explicit status language.

**Ratified (DOC-003, 2026-06-13):** the vocabulary below is adopted; one example
per label and the **split-status** rule (a feature may carry separate
`Implemented` and `Target design` lines during migration) live in
`documentation_governance_2026-06-13.md`. Unqualified words ("current,"
"complete," "canonical") are prohibited in status-bearing sections; each carries
a `Last verified` date.

- **Implemented** - code/data exists and automated coverage is current.
- **Pending validation** - implementation exists but required live validation
  is incomplete.
- **Known issue** - implementation exists but has a confirmed defect.
- **Target design** - approved behavior that is not fully implemented.
- **Planned** - approved work with a roadmap owner.
- **Deferred** - intentionally postponed and not part of current completion.
- **Open decision** - blocked on an entry in the decision register.
- **Historical** - retained only for provenance.
- **Superseded** - replaced by a named newer source.

### 3.5 Avoid copying operational procedures into the GDD

The GDD should explain what the product and system must do. Operational guides
should explain how to perform repository tasks.

The GDD may link to:

- environment setup
- testing guide
- map authoring guide
- sprite importer guide
- release/export procedure

It should not duplicate those guides.

## 4. Proposed Information Architecture

The exact treatment of `GDD_10a`, the feature index, and historical files is
tracked in the decision register. The proposed model is:

### 4.1 `AGENT/GDD/GDD_00_Overview.md`

Owns:

- project vision and release definition
- documentation governance and authority
- status vocabulary
- document map
- feature index or link to the feature index
- current high-level baseline
- known-issue summary
- platform targets

It must be the starting page for a new contributor.

### 4.2 `GDD_01` through `GDD_08`

Own the live system contracts:

- `GDD_01` - architecture, data contracts, serialization, integration seams
- `GDD_02` - core rules and calculations
- `GDD_03` - units, classes, progression, promotion, and reclassing
- `GDD_04` - weapons, items, economy-facing item rules
- `GDD_05` - skill rules, triggers, precedence, and implementation status
- `GDD_06` - maps, terrain, objectives, and authored map contracts
- `GDD_07` - UI/UX behavior and accessibility contracts
- `GDD_08` - AI behavior, parity obligations, and performance constraints

Each major section should distinguish:

1. implemented behavior
2. approved target behavior
3. remaining work or known issue
4. code/data/test anchors

### 4.3 Canonical roadmap

One roadmap should own:

- work order
- milestone scope
- dependencies
- release gates
- feature status
- links to the canonical GDD contract

Completion history should be concise. Detailed implementation history belongs
in session notes and Git.

### 4.4 Awakening reference corpus

The corpus owns normalized Awakening reference data and formulas. It does not
own Project Prometheus implementation status.

The project adoption matrix should record, for each relevant corpus area:

- not reviewed
- adopted target
- adopted with project variation
- rejected
- deferred
- implemented

Every "adopted with project variation" entry must link to the numbered GDD
section that defines the variation.

### 4.5 `AGENT/Docs`

Owns operational and supporting material:

- decision records
- active implementation plans
- environment and testing guides
- authoring/import guides
- audits and analyses
- release procedures

Plans must identify their status and replacement when completed or superseded.

### 4.6 Historical areas

- `AGENT/Code Reviews` - dated findings and evidence, never current rules
- `AGENT/Session Notes` - dated work record and handoff context
- `GDD_09_Checklist.md` - historical MVP build sequence unless retired
- `GDD_Assumptions.md` - historical assumptions unless retired
- `Content Expansion/Old_Deferred` - archived source material, never live rules

## 5. Feature Navigation Model

Create a feature-oriented index in a **dedicated file** (`DOC-005`, resolved
2026-06-13: `AGENT/GDD/GDD_Feature_Index.md`), linked prominently from `GDD_00`.
Each feature row should contain:

| Field | Purpose |
|---|---|
| Feature | Stable searchable name |
| Current status | Implemented, pending validation, known issue, target, planned, deferred |
| Rule owner | Exact numbered GDD heading |
| Architecture owner | Exact `GDD_01` heading where applicable |
| Roadmap owner | Milestone or backlog ID |
| Code/data anchors | Main scripts/resources, not an exhaustive file list |
| Automated coverage | Test suite names |
| Manual coverage | Validation map and manual-test heading |
| Decisions | Relevant dated decision IDs |
| Reference source | Corpus or handbook section when relevant |

The index is navigation, not a second specification. Rule details must remain
in the owning chapter.

Initial feature groups:

- combat calculations and RNG
- weapon triangle and rank bonuses
- WEXP and equipment legality
- EXP, leveling, promotion, and reclass
- classes and class skills
- Pair Up and support systems
- terrain and movement categories
- objectives and map authoring
- faction scheduling and controllers
- status conditions
- skills
- inventory, trade, convoy, shops, and economy
- save, retry, suspend, and rewind
- UI, input, settings, and accessibility
- AI behavior
- campaign flow and recruitment
- online play

## 6. Contradiction Resolution Procedure

Use this procedure for every discrepancy found during consolidation.

### Step 1 - Record the claim pair

Capture:

- source A and exact heading
- source B and exact heading
- whether code/tests agree with either source
- gameplay or maintenance impact

### Step 2 - Classify the discrepancy

Choose one:

- stale documentation
- implemented behavior differs from approved target
- two competing target designs
- current behavior versus future target
- terminology-only mismatch
- historical text presented as current
- corpus/project variation

### Step 3 - Determine whether a decision is needed

No decision is needed when:

- a later dated decision already settles the issue
- one side is demonstrably historical
- the GDD simply describes an old field or file path
- code/tests implement an already ratified rule

A decision is needed when:

- two plausible target behaviors remain
- scope or release timing changes
- adopting the corpus changes project-specific behavior
- migration behavior affects existing saves/content
- deleting or retiring a document changes workflow ownership

### Step 4 - Update the decision register

Do not resolve the choice inside the consolidation plan. Add a `DOC-*` or
`RULE-*` entry to the companion register with a recommendation.

### Step 5 - Apply an answered decision atomically

One logical documentation change should:

1. record or link the settled decision
2. update the authoritative GDD section
3. update the roadmap status/dependency if needed
4. update the adoption matrix if corpus-related
5. mark old statements superseded
6. update tests/manual coverage references if behavior changes
7. add a session-note entry

Code changes may be a separate implementation commit, but the documentation
must then label the rule as target design until code and tests land.

## 7. Migration Work Plan

### Phase 0 - Ratify governance choices — COMPLETE (2026-06-13)

All `DOC-*` and `RULE-*` register entries are answered, and the June update
reference (D-A…E, RNG-1…4, OPEN-1…13, pipeline order, parking-lot #8/#9) is
imported and dispositioned in
`decision_record_2026-06-13_june_reference_import.md`. The governance outputs are
ratified in `documentation_governance_2026-06-13.md`:

- project/corpus authority boundary — DOC-001 (numbered GDD owns rules; corpus is
  reference; supersedes D-C)
- status vocabulary + split-status rule — DOC-003
- GDD section template — DOC-002
- decision-record schema + unique ID namespace — DOC-009
- roadmap ownership (retire `GDD_10a`) — DOC-004
- feature-index location (`GDD_Feature_Index.md`) — DOC-005
- archive/supersession policy (move/remove now, gated on Phase 1 table) — DOC-006/008/010
- location of active design contracts — DOC-010

Exit criterion **met**: contributors can tell which file wins without inspecting
Git history.

**Remaining readiness-gate work before Phase 2 / destructive moves:** build the
Phase 1 file lifecycle / link-migration table, update the RNG contract to two-RN
(RULE-001, Package A prerequisite), then proceed.

### Phase 1 - Inventory and freeze the source map

Build a temporary inventory table of every documentation file with:

- category
- status
- authority scope
- replacement, if any
- inbound links from current documents
- action: keep, merge, move, supersede, archive, or delete

Prioritize files referenced by `GDD_00`, `GDD_01`, `GDD_10`, and
`GDD_Manual_Tasks`.

Exit criterion: every document has an explicit intended lifecycle.

### Phase 2 - Establish the GDD entry point

Update `GDD_00` with:

- ratified authority model
- status vocabulary
- revised document index
- implemented versus target distinction
- feature navigation
- known issues and pending-validation summary
- release definition and platform targets

Do not import detailed operational procedures.

Exit criterion: a new session can start from `GDD_00` and reach the correct
owner for any major feature.

### Phase 3 - Consolidate system chapters

**Sequencing rule (review fix, 2026-06-13):** corpus adoption must not lag the
GDD rewrite. For any chapter that imports corpus-derived rules, its
**adoption-matrix rows (Phase 4) are completed before or in the same commit as
the chapter rewrite** — recording corpus version, exact source headings, adopted
rules, rejected rules, project variations, and implementation status. This
enforces DOC-001's explicit-adoption boundary so "adopt corpus formulas" can
never be copied in without provenance.

Process `GDD_01` through `GDD_08` one chapter at a time. For each chapter:

1. compare it with code, tests, decisions, active plans, and corpus adoption
2. complete the adoption-matrix rows for this chapter's corpus-derived rules
   (Phase 4) before or with the rewrite
3. remove obsolete claims from current sections
4. retain approved future behavior as explicit target design
5. add code/data/test anchors
6. move procedural detail to the appropriate guide
7. add unresolved choices to the decision register
8. mark historical source documents superseded after their useful content is
   incorporated

Recommended order:

1. `GDD_02` combat, RNG, WEXP, EXP, promotion, reclass, terrain
2. `GDD_03` class corpus adoption and magic-class design gaps
3. `GDD_04` weapon families, rank bonuses, and item/economy rules
4. `GDD_05` skill acquisition, proc precedence, Pair Up/support dependencies
5. `GDD_01` architecture contracts needed by those rules
6. `GDD_06` terrain/map/objective schemas
7. `GDD_07` UI capacity, input parity, and accessibility
8. `GDD_08` AI parity and performance constraints

Exit criterion: each live rule or target rule has one numbered-GDD owner.

### Phase 4 - Reconcile the Awakening corpus

**Runs interleaved with Phase 3, not after it** (review fix, 2026-06-13): each
chapter's adoption-matrix rows are completed before/with that chapter's rewrite.
This phase entry defines the matrix structure and coverage; the per-chapter rows
land during Phase 3.

Expand `project_adoption_matrix.md` from a short list into a systematic index.

At minimum cover:

- stat and combat formulas
- hit RNG model
- physical and project-specific magic triangles
- WEXP thresholds and rank bonuses
- promotion and reclass rules
- terrain and movement categories
- starter and future class definitions
- class skill acquisition
- Pair Up, Dual Strike, Dual Guard, supports, marriage, and child systems
- weapons, items, and effectiveness

For every adopted target:

- link to the numbered GDD
- record any project variation
- distinguish target adoption from implementation status

Exit criterion: no corpus section can silently override a project variation.

### Phase 5 - Consolidate roadmap and task tracking

Apply the answered roadmap decision:

- choose one canonical roadmap owner
- preserve only concise completion history
- assign stable IDs to open bugs, preparation tasks, systems, and release gates
- ensure every target GDD section has a roadmap owner or explicit "not
  scheduled" status
- move confirmed playtest bugs from prose notes into the bug/work bucket
- keep pending validation separate from confirmed defects

Exit criterion: every planned or broken feature has one tracking entry.

### Phase 6 - Clean supporting documents

For each active guide:

- verify paths and commands
- remove copied rules that belong in the GDD
- link back to the authoritative GDD section
- add a last-verified date and responsible workflow

For each historical plan/audit:

- add a supersession header where needed
- remove current-document links that imply it is still active
- preserve evidence and rationale

Exit criterion: search results clearly distinguish instructions from history.

### Phase 7 - Add lightweight documentation validation

Create repository checks that can run without interpreting prose:

- verify repository-relative Markdown links and file paths
- reject links to known renamed/deleted paths
- detect duplicate active roadmap IDs
- verify required headers on active plans and superseded documents
- verify feature-index targets exist
- detect stale `Last refreshed` dates only when a status-bearing file changed
- optionally flag legacy field names outside explicitly historical sections

Do not build a complicated documentation generator before the ownership model
is stable.

Exit criterion: common structural drift fails locally or in CI.

## 8. Focused Work Procedure

### 8.1 Session start

1. Read the latest session note.
2. Open `GDD_00`.
3. Find the feature in the feature index.
4. Read only the linked canonical GDD sections, current roadmap item, relevant
   tests, and active implementation plan.
5. Check the decision register for blockers.

This prevents broad historical searches from becoming accidental design input.

### 8.2 Before implementation

Create or update a scoped implementation plan when the change is non-trivial.
The plan must state:

- canonical rule section
- current versus target behavior
- exact scope and exclusions
- affected code/data
- automated and manual verification
- documentation files that must change
- unresolved decision IDs

No implementation should begin while a behavior-defining decision remains
unanswered unless the work is explicitly exploratory.

### 8.3 During implementation

- Keep one logical behavior change per commit where practical.
- Update tests with the behavior change.
- Do not rewrite unrelated historical files.
- If implementation reveals a new design choice, add it to the decision
  register and pause only the affected branch of work.
- If code must temporarily differ from the target, document the gap as a
  roadmap item rather than changing the target prose to match an intermediate
  state.

### 8.4 Definition of done for a feature change

A feature change is complete only when:

- code/data and tests agree
- the owning GDD section reflects implemented and target status
- roadmap status/dependencies are updated
- adoption matrix is updated when corpus-derived
- manual validation steps are updated when player flow changed
- active implementation plan status is updated
- session notes record the work and commits

### 8.5 Bug-fix procedure

1. Record a stable bug ID and reproducible failure.
2. Link the violated GDD/UI contract.
3. Add an automated regression test when reasonable.
4. Fix and verify.
5. Update manual coverage only if the validation flow changed.
6. Remove the bug from the active list; preserve the result in session notes
   and Git rather than a permanent "done bugs" table.

### 8.6 Documentation-only change procedure

Verify:

- every changed claim has an authority source
- current and target behavior are not conflated
- all links and paths exist
- no open decision was silently resolved
- superseded text points to its replacement
- the decision register and roadmap remain synchronized

## 9. Documentation Change Matrix

Use this as the default impact checklist:

| Change type | Required documentation review |
|---|---|
| Combat/game rule | `GDD_02`, relevant content chapter, decision log, tests |
| Resource/API/schema | `GDD_01`, owning rule chapter, migration notes, tests |
| Class/content adoption | `GDD_03`/`04`/`05`, adoption matrix, roadmap |
| Map/objective behavior | `GDD_06`, map authoring guide, manual validation |
| UI/input/settings | `GDD_07`, testing guide/manual tasks, accessibility backlog |
| AI behavior | `GDD_08`, parity checklist, AI tests |
| Save/runtime state | `GDD_01` snapshot contract, affected rule chapter, schema version |
| New feature/status change | canonical roadmap, feature index, owning GDD section |
| Playtest finding | active bug/task tracker, manual playbook if coverage changes |
| Settled decision | decision record, all affected canonical sections |

## 10. Initial Corpus-Adoption Work Packages

The owner has approved these as target directions. Exact open details remain in
the decision register.

### Package A - Combat and RNG

- **Prerequisite (RULE-001):** update the deterministic RNG roll-order contract,
  fixed roll-order fixture, and save-compat notes to the **two-RN** model (draw
  two 0–99, floor the average, compare to resolved hit; crit only after a
  successful hit; skill activations at their trigger slots) **before** `RngService`
  is built. The companion RNG contract currently still defines one hit draw.
- adopt corpus-derived combat-stat formulas
- adopt two-RN hit resolution
- ratify the combat modifier pipeline order (base → permanent → pair-up →
  combat-duration skills → conditions → terrain → triangle → S-rank → clamps);
  corpus formulas slot into this order
- apply combat rulings: weapon breakage cancels remaining strikes (OPEN-3);
  fort/throne heal = max(1, floor(0.10 × max HP)) (OPEN-7); simultaneous
  victory/defeat = defeat first, then acting faction (OPEN-6); condition/skill
  precedence (OPEN-2)
- retain the project magic triangle
- use rank-scaled triangle bonuses for both physical and magic triangles

### Package B - WEXP and rank bonuses

- adopt corpus WEXP thresholds and class caps
- define migration from current numeric values
- move rank bonuses into the combat engine
- retire `s_rank_mastery` as a pseudo/equipped skill
- settle the project S-rank extension

### Package C - Progression

- adopt corpus promotion and class-transition targets
- define seal versus automatic-promotion timing
- reset the EXP-gain basis on reclass
- retain a lifetime-level counter for future enemy autoscaling

### Package D - Terrain and movement

- adopt corpus terrain values and movement categories
- define project mappings for existing terrain IDs
- rebalance and retest existing maps

### Package E - Classes and magic

- move current classes to corpus definitions
- decide treatment of project-only promotion paths
- add explicit design tasks for Light and Dark magic class lines
- preserve the project magic triangle in weapon and class design

### Package F - Pair Up and support

- treat the complete corpus model as the long-term target
- keep Pair Up pass 1 stat bonuses/actions IN 1.0 (Implemented); value migration
  to corpus numbers is Planned (RULE-012)
- schedule Dual Strike + Dual Guard together as later combat work
- defer adjacent support, relationship ranks, conversations, marriage, and child
  systems to post-1.0 (OPEN-1 / RULE-012)
- assign release scope and milestone ownership for each layer

### Package G - Project and release decisions

Release-defining decisions from the June reference that the prior plan omitted
(review fix, 2026-06-13). Each needs a roadmap owner:

- **1.0 definition** (D-B): offline non-pipeline features + one short campaign;
  re-scope M11 (campaign content = 1.0, full coverage = post-1.0).
- **Public-identity rename gate** (D-A): data-pass rename no later than first
  public release candidate.
- **Legal/licensing gate** (DOC-012 / OPEN-12): blocking pre-1.0 review of
  handbook/corpus derivative-works rights and attribution — separate from the
  rename.
- **Renderer / platform targets** (OPEN-8/11): Compatibility (OpenGL); desktop
  primary, Steam Deck letterboxed at first verification, web as playtest channel,
  gamepad with the rebind milestone, mobile deferred.
- **Campaign prerequisites** (D-D): deployment screen, shops, recruit mechanic
  as dependency edges to the campaign milestone.
- **CampaignRules stub** (update reference §5): create with known fields,
  including `exp_gaining_factions` (OPEN-4, default Blue+Green).
- **New backlog items:** broken-weapon degraded mode (OPEN-5); doc-lifecycle
  definition-of-done rule (PL#8) added to `AGENTS.md` and paired with DOC-011 CI
  checks. SFX deferred to the Phase 3 audio milestone (PL#9).

## 11. Recommended Commit Sequence

Each step should leave links and authority statements internally consistent.

1. `Define documentation governance and status vocabulary`
2. `Add feature-oriented GDD navigation`
3. `Consolidate combat and progression design contracts`
4. `Reconcile class and content adoption contracts`
5. `Consolidate maps UI and AI design contracts`
6. `Unify roadmap ownership and active task tracking`
7. `Mark superseded documentation and repair links`
8. `Add documentation consistency checks`

Do not combine corpus rule migrations with unrelated historical cleanup.

## 12. Plan Completion Criteria

The consolidation project is complete when:

- `GDD_00` provides an unambiguous starting point and authority model
- every current or target feature has one owning GDD section
- the feature index reaches rules, roadmap, code/data, and verification
- corpus adoption and project variations are explicit
- one roadmap owns scope, order, status, and dependencies
- open decisions exist only in the decision register
- historical files cannot be mistaken for current instructions
- operational guides do not duplicate normative rules
- documentation validation catches broken links and common lifecycle errors
- the feature definition of done requires synchronized documentation
