# Documentation Review - 2026-07-15

> **Status:** Active - documentation review report
> **Last verified:** 2026-07-15
> **Pillar:** 2 - Documentation
> **Procedure:** `AGENT/Review Procedures/02_Documentation_Pillar.md`
> **Snapshot:** branch `agent/codex/2026-07-15/prep-save-followup`, commit `08b3b5c2aa5dfb1e773a87d07890b9c7629ef1b3`
> **Previous review:** `AGENT/Docs/governance/documentation_review_2026-07-05.md`

**Score:** 6/10

## Executive Summary

The campaign/save implementation is documented in substantial depth and its concrete
contracts generally match the shipped code. The main weakness is reconciliation:
several high-traffic tracker passages still call the newly implemented campaign
sharing, results, and branch-choice work planned or missing. The new campaign GDD
sections also omit required dated verification markers and the DOC-002 feature
template, gaps which the green checker does not detect.

`python3 AGENT/Docs/check_docs.py`: **PASS, 35/35 checks** (master-audit baseline).

## Spot-Check Sample

Reviewed the complete live numbered GDD set (`GDD_00` through the split `GDD_08`
companions), `GDD_10_Roadmap.md`, `GDD_Feature_Index.md`,
`GDD_Adoption_Matrix.md`, `AGENT/Docs/decisions/decision_index.md`, the governance
and lifecycle contracts, and all active guides. Truth spot-checks concentrated on
the campaign graph, deployment, named save slots, rewind, portable save/status
records, campaign archive installation/export, Tier-2 activation, and defeat/results
surfaces against their scripts, resources, and tests. Claims outside that sample
were assessed for governance and navigation only, not re-proven against runtime
behavior.

## Issues

### High - Feature index still labels shipped campaign sharing and status records as future work

**Location:** `AGENT/GDD/GDD_Feature_Index.md:53`

**Problem:** The feature-index row for campaign sharing/export/import and status
records says `Planned / Deferred split` and lists only target test anchors. That is
now false and conflicts with another row in the same index, which calls package
selection and status carry-forward Implemented (`GDD_Feature_Index.md:49`). A
contributor using the feature index will route already-shipped work as a future
slice.

**Evidence:** The owning live contract marks archive validation/storage, export,
installed-pack activation, exact save identity, and player-facing transfer
Implemented (`AGENT/GDD/GDD_01_Runtime_Contracts.md:285-345`), while the data
contract marks status records and the Tier-2 catalogue/pipeline Implemented
(`AGENT/GDD/GDD_01_Data_Contracts.md:431-519`). Concrete implementation anchors
include `scripts/resources/CampaignPackInstaller.gd`,
`scripts/resources/CampaignPackExporter.gd`,
`scripts/resources/CampaignTier2RuntimeAdapter.gd`, and
`scripts/save/CampaignStatusRecord.gd`, with matching campaign-pack and status-record
test suites in the 98-suite green baseline.

**Root cause:** DoD#1 reconciliation updated the owner GDD and roadmap but missed the
second, older feature-index row for the same capability.

**Recommended fix:** Merge rows 49 and 53 or narrow them to distinct ownership.
Mark package transfer and status records **Implemented**, retain public builder and
content-resynchronization work as **Deferred**/**Planned**, and replace target-only
anchors with the shipped files/tests.

### High - Roadmap's next-work narrative contradicts its implemented rows

**Location:** `AGENT/GDD/GDD_10_Roadmap.md:81-83`, `:92`, and `:115-121`

**Problem:** The Next Work Queue says branch-node choice and a dedicated results
screen "remain" gaps, then its table says both are Implemented. The campaign-package
narrative similarly says the package "remains incomplete" midway through a paragraph
that ends by declaring the track Implemented. This is split status without labels
and makes the roadmap's immediate queue unreliable.

**Evidence:** The same roadmap records branch choice, `MapResultsScreen`, and defeat
recovery as Implemented at line 121. Runtime behavior is anchored by
`scripts/ui/MapResultsScreen.gd` and `scripts/ui/GameOverScreen.gd`; the latter exposes
Retry, latest/selected save load, Rewind, and Main Menu (`GameOverScreen.gd:32-40,
158-176`). Package import/export and activation are described as shipped by the
owner contract at `GDD_01_Runtime_Contracts.md:285-345`.

**Root cause:** Chronological implementation notes were appended without rewriting
the queue's earlier gap summary, a DoD#1 roadmap-update miss.

**Recommended fix:** Rewrite lines 74-116 as a present-state summary. Land the
completed branch/results/package capabilities under **Implemented** and name only
builder editing/repair and compatibility-resynchronization as **Planned** or
**Deferred**.

### Medium - New campaign GDD sections omit required `Last verified` markers

**Location:** `AGENT/GDD/GDD_01_Data_Contracts.md:348,433,453,470,523,627` and
`AGENT/GDD/GDD_07_Screens_Panels.md:71,895`

**Problem:** Each cited section carries its own `Status:` assertion but has no
section-level `Last verified:` marker. A date embedded inside an Implemented label
does not satisfy DOC-003's explicit status-plus-dated-marker contract.

**Evidence:** Governance requires every status-bearing section to carry an approved
label plus `Last verified: YYYY-MM-DD`
(`AGENT/Docs/governance/documentation_governance_2026-06-13.md:13-28`). The cited
sections have Status lines, while `GDD_01_Data_Contracts.md` has no `Last verified:`
line at all and `GDD_07_Screens_Panels.md` has markers only for its chapter catalog
and prep section (lines 22 and 179).

**Root cause:** New sections copied milestone dates into prose/status text while the
checker validates only broader chapter structure.

**Recommended fix:** Add a distinct `Last verified: 2026-07-15` to every cited
status-bearing section. These remain **Implemented**; this is metadata repair, not a
behavior-status change.

### Medium - Campaign data-contract features do not follow DOC-002

**Location:** `AGENT/GDD/GDD_01_Data_Contracts.md:346-679`

**Problem:** CampaignData, CampaignStatusRecord, Tier-1 asset references, package
manifest/Tier-2 catalogue, CampaignManager, and deployment are major feature
contracts, but none is organized as Summary / Specs / Known gaps / Anchors. GDD_01
is not one of the catalog chapters granted the DOC-002a exception.

**Evidence:** DOC-002 requires those headings for major feature sections
(`AGENT/Docs/governance/documentation_governance_2026-06-13.md:65-104`); DOC-002a
limits the catalog variant to GDD_06/07/08. The campaign block instead uses long
undifferentiated prose and inline code, with implementation anchors scattered or
absent.

**Root cause:** Fast-moving implementation contracts were appended to the split data
chapter without completing the documentation-template pass.

**Recommended fix:** Group the related campaign subsections under one compliant
major section (or make each independently compliant), preserving **Implemented**
status and explicitly separating remaining builder/resync gaps.

### Medium - Decision index does not use the vocabulary it claims

**Location:** `AGENT/Docs/decisions/decision_index.md:8-10,35-65,71-103`

**Problem:** The index says its Status column uses governance vocabulary, but the
column mixes `Applied`, `Answered`, `Settled (target)`, `Retained`, and composite
forms such as `Applied (Split)`. This obscures whether a decision is approved,
implemented, planned, or merely reflected in prose, and it is not one consistent
case/vocabulary.

**Evidence:** The approved labels are enumerated at
`documentation_governance_2026-06-13.md:18-28`; `Applied`, `Answered`, `Settled`, and
`Retained` are absent. Governance separately describes "answered -> applied" as a
workflow (`:134-137`), suggesting lifecycle and feature status have been collapsed
into one column.

**Root cause:** The decision lifecycle needs a distinct schema from feature status,
but the index promises the feature-status vocabulary.

**Recommended fix:** Ratify and document a decision-lifecycle vocabulary, or split
`Decision state` (Answered/Applied/Superseded) from `Delivery status`
(Implemented/Target design/Planned/etc.). Add a checker once chosen.

### Low - Load Game contract still says Prep manual save is waiting

**Location:** `AGENT/GDD/GDD_07_Screens_Panels.md:73-78`

**Problem:** The Load Game section says `CampaignManager.write_campaign_slot` "waits
for" the Prep surface, although the same chapter marks Prep/manual save Implemented
at lines 175-199.

**Evidence:** `scripts/ui/PrepScreen.gd` calls the campaign-slot seam, and the roadmap
records Prep manual-save Slice 3 as Implemented (`GDD_10_Roadmap.md:177`).

**Root cause:** Slice-3 transitional wording survived the Prep implementation.

**Recommended fix:** Replace the sentence with present-tense ownership: Prep writes
fresh between-map manual slots; Load Game loads/deletes/transfers them. Keep both
sections **Implemented**.

## Governance & Lifecycle Compliance

- Status labels: broadly readable, but the campaign sections miss dated markers and
  the decision index uses an unratified mixed vocabulary.
- Prohibited status words: structural baseline PASS; the roadmap nevertheless uses
  hidden present-state phrasing ("remain") that creates the same ambiguity DOC-003
  is intended to prevent.
- DOC-002: older major feature sections are generally structured; the new GDD_01
  campaign block is nonconforming. GDD_06/07/08 catalog organization was accepted
  under DOC-002a and was not treated as a finding.
- Single source of truth: the duplicate campaign-loop/sharing feature-index rows now
  disagree on status.
- Navigability: sampled links resolve, and the campaign owner anchors are easy to
  reach; row 53 routes readers to future rather than shipped anchors.
- Authority hygiene: no sampled live document cited a Historical/Superseded file as
  binding authority.
- Lifecycle: the live governance review remains under `AGENT/Docs/governance/`, while
  the procedure's output path names `AGENT/Docs/`; this report follows the explicit
  output path for this run.

## Coverage & Automation Gaps

1. `check_docs.py` does not require a nearby `Last verified:` for every `Status:`
   line in split companion chapters. Add a section-aware check across all live
   `GDD_00`-`08` files.
2. DOC-002 conformance is stated but unenforced. A heading-state check can require
   Summary/Specs/Known gaps/Anchors for major non-catalog sections, with an explicit
   DOC-002a allowlist for GDD_06/07/08.
3. Decision-index status values are not validated. Add the check only after its
   lifecycle vocabulary is ratified; the current governance text is internally
   ambiguous about feature status versus answered/applied workflow.
4. DoD#1 cannot reliably detect semantic contradictions. A practical partial guard
   could require every changed `GDD_Feature_Index` row to contain shipped anchors
   when its owner roadmap track becomes Implemented, but human reconciliation is
   still necessary.
5. The checker does not detect duplicate feature-index ownership/status rows. A
   stable feature/track-ID uniqueness rule would catch the campaign row split.

## Positive Observations

1. The previous review's inline `unit_data` spawn-seam drift is fixed in both data
   and map owners (`GDD_01_Data_Contracts.md:309` and
   `GDD_06_Maps_Objectives.md:256`).
2. The previous Map 950 skill-cap playbook error is fixed: the guide now correctly
   states that `unit_12_hero_skill_cap` starts with five skills
   (`manual_test_playbook.md:334`).
3. The save, rewind, package, and status-record contracts cite concrete code and test
   surfaces and agree with the sampled implementations on document shape, exact pack
   identity, ledger persistence, and transactional boundaries.
4. The feature index's save/retry/suspend/rewind row is unusually useful: it gives a
   concise shipped-state summary and directs readers to both runtime and UI owners.
5. Generated documentation checks remain green at 35/35 despite the large campaign
   branch, so paths, indexes, manifests, and other mechanically checkable structure
   stayed intact.

## Prioritized Action Plan

### Fix the docs

1. Reconcile feature-index rows 49/53 and roadmap lines 74-116 with shipped campaign
   sharing, status, branch-choice, and results behavior.
2. Add `Last verified` markers and DOC-002 structure to the new GDD_01 campaign
   contracts.
3. Ratify a decision-index lifecycle schema and normalize its Status column.
4. Remove the stale "waits for" wording from the Load Game contract.

### Fix the checker

1. Enforce section-local Status + Last verified pairs in every split live GDD file.
2. Add DOC-002/DOC-002a heading-shape validation.
3. After governance is clarified, validate decision-index status values.
4. Add duplicate feature/track ownership detection to the feature index.

## Delta Vs Previous Review

Resolved since 2026-07-05: the inline enemy-placement `unit_data` seam is now in both
owner GDDs, and the Map 950 five-skill fixture text is correct. New in this branch:
campaign implementation advanced faster than its high-level index/queue cleanup;
the new campaign contracts also exposed section-level status and DOC-002 checker
blind spots. No prior Critical issue remains open, and this review found no new
Critical issue.

## Procedure Friction

- The procedure names governance/lifecycle/decision-index files at old flat paths;
  their live locations are now under `AGENT/Docs/governance/` and
  `AGENT/Docs/decisions/`.
- The procedure's in-scope list says `GDD_00`-`08`, but the live set now includes
  split companion chapters (`GDD_01_Data_Contracts`, `GDD_01_Runtime_Contracts`,
  `GDD_07_Input_Cursor`, and `GDD_07_Screens_Panels`). They were included here.
- The procedure's abbreviated approved-label checklist omits labels that governance
  explicitly allows (`Pending validation`, `Planned`, `Deferred`, and `Open
  decision`). The governance source was treated as authoritative.
- The requested prior-report glob at `AGENT/Docs/documentation_review_*.md` does not
  match the live previous report in `AGENT/Docs/governance/`; the latest dated live
  report was used.
