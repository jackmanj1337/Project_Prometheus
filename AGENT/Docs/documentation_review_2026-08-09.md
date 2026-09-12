---
Role: dated
---

# Documentation Review — 2026-08-09

> **Status:** Active — documentation review report
> **Last verified:** 2026-08-09
> **Pillar:** 2 — Documentation
> **Procedure:** `AGENT/Review Procedures/02_Documentation_Pillar.md`
> **Snapshot:** `agent/integration` at `41c0e5fc1116a9a01aed3afc48dbc92f021d018d`
> **Previous review:** `AGENT/Docs/documentation_review_2026-07-15.md`

**Score:** 6/10

## Executive summary

The documentation system is structurally strong: all 43 automated checks pass, the
July decision-index and feature-ownership defects are repaired, and the generated
indexes make a large live corpus navigable. The remaining weakness is truth at
runtime transaction and native-platform boundaries. Two live GDD passages describe
known-broken behavior as shipped: campaign resume is not atomic across content
activation, and physical Escape still does not obey the documented two-stage
FileDialog contract on Windows. The active lifecycle rubric also still inventories
the pre-typed documentation layout, which weakens the authority-hygiene rule it is
supposed to define.

`python3 AGENT/Docs/check_docs.py`: **PASS, 43/43 checks**.

## Coverage

Reviewed the complete numbered GDD set (`GDD_00` through the split `GDD_08`
companions), `GDD_10_Roadmap.md`, `GDD_Feature_Index.md`,
`GDD_Adoption_Matrix.md`, the decision index, documentation governance/lifecycle,
the generated active-document indexes, `README.md`, and the active guides. Truth
spot-checks concentrated on campaign-package activation and resume, save contracts,
native text entry, responsive UI, skill/content-family adoption, and the July
findings. Historical evidence was consulted only where a live claim made it relevant.

## Issues

### High — Campaign restore's “all-or-nothing” GDD claim stops at the wrong transaction boundary `[CROSS]`

**Location:** `AGENT/GDD/GDD_01_Data_Contracts.md:684-690`.

**Problem:** The live CampaignManager contract says a restore validates before any
state write and leaves no half-restored campaign. That is true only inside
`CampaignManager.restore_campaign_state`; the player-facing resume operation first
activates the saved content package and can reject later without restoring the
previous content session. A contributor following the GDD can therefore preserve or
extend the defect while believing the transaction contract is already satisfied.

**Evidence:** The GDD's absolute restore claim is at
`GDD_01_Data_Contracts.md:684-690`. The audited runtime calls content activation at
`scripts/autoloads/GameState.gd:1057` and retains later rejection paths through
`:1087`; the complete evidence and call-boundary analysis is in
`AGENT/Code Reviews/code_review_2026-08-09.md:29-58`. CampaignManager itself stages
only its own fields (`scripts/autoloads/CampaignManager.gd:757-847`), so its local
guarantee cannot roll back DataManager's earlier session swap.

**Root cause:** The GDD documents the inner campaign-position transaction as though
it were the outer Continue/Load transaction.

**Recommended fix:** Mark package-backed resume **Known issue** and scope the
all-or-nothing promise explicitly to `CampaignManager.restore_campaign_state` until
the outer content + campaign transaction is fixed. After the code fix, document and
test one commit boundary for package identity, registries, catalogues, campaign
position, rules, convoy, and roster.

**Classification:** Recurring from the July restore finding and shared with Pillar
1. The exact runtime also affects frozen v0.7.1 candidate `0db30fd1`; deduplicate it
into Pillar 1's release-intake item rather than creating a second blocker.

### High — The live New Game contract calls failed Windows FileDialog behavior shipped

**Location:** `AGENT/GDD/GDD_07_Screens_Panels.md:181-185`.

**Problem:** The screen catalogue states that physical Escape is two-stage while a
FileDialog filename field has focus. Repeated real-Windows returns show that the first
Escape closes the whole dialog. This is exactly the kind of platform behavior that a
headless structural pass cannot promote from intended design to Implemented truth.

**Evidence:** The GDD says the first Escape leaves the field and focuses the tree and
only the second closes the dialog (`GDD_07_Screens_Panels.md:181-185`). The v0.5.8
owner return records **FAIL** and the opposite behavior at
`AGENT/Docs/playtests/playtest_v0.5.8_owner_return_2026-07-29.md:21,44-46`.
The later carry-forward identifies the same Windows failure and its viewport-boundary
cause at `AGENT/Docs/playtests/playtest_v0.6.0_carryforward_2026-07-29.md:65-66,
154-180`; the v0.7.0 checklist still labels it unproven at
`AGENT/Docs/playtests/playtest_checklist_v0.7.0.md:165-168`.

**Root cause:** Intended and headless-tested behavior was written into a catalog entry
without reconciling the authoritative native-platform return or using **Pending
validation**/**Known issue**.

**Recommended fix:** Mark the two-stage Escape clause **Known issue** and link the
display-gated tracker row. Restore **Implemented** only after a Windows return proves
the event order. Keep the printable X/Z behavior separately Implemented; it did pass.

**Classification:** Already tracked by
`IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29` / V070-06. It affects the frozen
candidate but is not a new v0.7.1 intake item.

### Medium — The active lifecycle authority still describes the pre-typed Docs layout

**Location:**
`AGENT/Docs/governance/documentation_lifecycle_2026-06-13.md:63-73,94-108`.

**Problem:** The live governance rubric calls flattened paths such as
`AGENT/Docs/decision_index.md`, `testing_guide.md`, and root-level plan/design files
active homes, and its historical counts remain 78 session notes / 21 reviews. The
actual system now uses `decisions/`, `guides/`, `plans/`, `design/`, and typed
`archive/` directories with generated `INDEX.md`/`REGISTERS.md`. A reader using this
document to decide what is live or where it belongs receives stale lifecycle data.

**Evidence:** The stale active inventory is at lifecycle lines 63-73 and its
keep-in-place historical inventory at lines 94-108. The enforced layout is stated in
`AGENTS.md:249-254`; actual authoritative paths include
`AGENT/Docs/decisions/decision_index.md`, `AGENT/Docs/guides/testing_guide.md`, and
`AGENT/Docs/plans/awakening_compatability_refactor_plan_2026-05-22.md`.

**Root cause:** The June migration table remained marked Active after the later typed
documentation-system redesign, but was not rewritten or superseded.

**Recommended fix:** Either rewrite it as the present lifecycle policy using the
typed layout and generated indexes, or mark it **Historical** and point governance
readers to `documentation_system_design_2026-06-23.md` plus the generated indexes.

**Classification:** Integration-only documentation/systemic; no frozen-candidate
runtime effect.

## Governance and lifecycle compliance

- Status vocabulary and section-local verification markers pass the implemented
  checker. The FileDialog clause demonstrates the remaining semantic failure mode:
  a catalog entry can make an unlabelled shipped-behavior assertion under a broad
  chapter status.
- DOC-002 enforcement now covers the campaign/save companion sections that failed in
  July. Legacy non-catalog chapters remain an explicit migration backlog rather than
  being falsely reported compliant.
- The decision index now correctly separates `Decision state` from `Delivery status`,
  uses ratified vocabularies, and passes check 36. July's mixed `Applied`/`Answered`
  finding is resolved.
- Feature ownership is normalized and mechanically checked. July's contradictory
  campaign-sharing rows have been narrowed into distinct campaign-loop and
  package/public-authoring owners.
- No sampled live GDD or guide cited an archived document as binding authority. The
  lifecycle file is itself stale authority, which is the third finding above.

## Coverage and automation gaps

1. Catalog entries can assert shipped behavior without an entry-local status. The
   checker cannot prove truth, but a `Known issue` tracker/link convention for failed
   playtest clauses would make reconciliation mechanically visible.
2. Active governance documents have no freshness/owner check comparable to GDD
   section verification. A narrow check could forbid obsolete flattened Docs paths
   in the lifecycle authority and require it to link the generated layout owner.
3. Master-procedure check 12 still enforces anchored scores only for rollups, not all
   pillar reports. This run follows the convention manually.
4. Semantic transaction scope cannot be inferred from prose. The practical guard is
   a DoD#1 review that requires outer player-flow contracts to cite the orchestration
   test, not only the inner object's unit tests.

## Positive observations

1. All 43 structural checks pass, up from 35 in July, including decision vocabulary,
   GDD section governance, feature ownership, open-registry rules, dangling deferrals,
   and generated manifests.
2. The July decision-index issue is fully resolved with independent, enforced
   decision-state and delivery-status columns.
3. The July feature-index/roadmap campaign reconciliation is substantially repaired;
   shipped campaign loop behavior and remaining public-authoring work now have
   distinct rows and anchors.
4. The package contract correctly documents one self-contained active content set and
   whole-session DataManager activation; it does not reintroduce illegal cross-pack id
   collision or defaults-overlay language.
5. Generated `INDEX.md` and `REGISTERS.md` give the large typed corpus a useful
   retrieval surface, and the dangling-deferral check keeps open work connected to a
   live tracker or owner.

## Prioritized action plan

### Fix the docs

1. Mark outer campaign resume **Known issue** and distinguish it from the inner
   CampaignManager restore guarantee.
2. Mark native two-stage FileDialog Escape **Known issue** until Windows evidence
   passes; preserve the independently passing printable-key claim.
3. Rewrite or retire the stale lifecycle migration table.

### Fix the checker

1. Add a lifecycle-layout guard after the lifecycle authority is rewritten.
2. Add a mechanical convention linking failed live behavioral clauses to their
   tracker row without pretending a checker can validate runtime truth.
3. Extend anchored-score enforcement to new pillar reports without rewriting
   historical reports.

## Delta vs previous review

Resolved since 2026-07-15: the feature-index campaign rows and roadmap narrative were
reconciled; missing section-local verification markers and campaign DOC-002 shapes
are now enforced; the decision index has a ratified two-column lifecycle schema; and
the stale Load Game/Prep wording is gone. New/clarified: the outer resume transaction
still exceeds the GDD's inner guarantee, native FileDialog failure remains documented
as shipped, and the June lifecycle table did not follow the typed Docs redesign.
There is no Critical finding, but two false shipped-behavior claims keep the score at
6/10.

## Frozen v0.7.1 applicability

- Campaign resume and FileDialog Escape both affect the frozen candidate's runtime,
  but each is already owned by an existing code/playtest finding. This pillar adds
  documentation correction, not duplicate release blockers.
- The lifecycle-layout finding is documentation-systemic and integration-only.

## Procedure friction

- The procedure calls the entire set exhaustive but then asks for concrete
  truth spot-checks. This report treats structural/governance coverage as exhaustive
  and runtime truth as risk-based sampling; the procedure should state that boundary.
- `AGENT/Docs/documentation_review_*.md` also matches governance-era reviews. As with
  the code glob, comparison requires semantic selection, not lexical last-file wins.
- The catalog exception makes chapter-level status legal, but it gives no convention
  for one known-broken behavior inside an otherwise implemented screen. A blessed
  entry-local `Known issue` form would remove that ambiguity.
