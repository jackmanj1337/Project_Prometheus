---
Role: dated
---

# Scenes, Data and Assets Review — 2026-09-14

**Score:** 8/10

Luna W3/W6 inspected both Proving Grounds manifests/catalogues/campaign graphs;
Pack 0 map registry, map_001, default roster, cavalier, iron_sword, aegis and registries;
FE cavalier and source registry; extractor/schema/adapter correspondences; MainMenu,
NewGame and CampaignLibrary scene wiring; editor asset validation and FE asset tools.
Pinned SHAs and assigned-path counts: [rollup](full_review_rollup_2026-09-14.md).

## Known authored-content gap, not a new defect

`extract_proving_grounds_pack.gd:281-284` emits empty advancement_edge_refs;
`:315-327` explicitly reports source promotes_to as an extraction gap. Source
`data/classes/cavalier.tres:29` has promotion destinations, while neither sampled pack
has advancement_edge/route documents. The adapter already supports these documents.
Thus successful ordinary activation does not prove promotion coverage, including the
FE map_950 fixture's intended success case. Owners already exist:
`FE-PACK-CLASS-ADVANCEMENT-2026-08-31` and `IMPL-ZERO-CONTENT-BASE-PACK`.
Do not call a planned capability an untracked implementation failure or duplicate it.

## Positive observations

Both sampled campaign node sets resolve through their own map registries. Pack 0
includes the deliberate drill/free-roam variant; FE main remains linear. Cross-pack
ID reuse is valid because one self-contained pack is active at a time. The full
engine run executed the authored-pack proofs; inherited pack pytest counts are 6/32.

MainMenu and related modal theme/resource paths resolve in the inspected raw scenes.
The two library instances are real and have distinct entry wiring; their intended
scope is already owned by `V0719-DUPLICATE-LIBRARY-SCREEN-2026-09-14`, not a new
missing-resource finding. Native appearance is not established by scene inspection.

FE official-art pipeline tooling explicitly labels its outputs internal-only and
not wired pack assets (`tools/test_fe_art_pipeline.py:160-166`,
`tools/fe_gap_naming.py:15-17`). The sampled pack contains no asset registry wiring
those files. Source registry entries retain disputed/unchecked provenance labels.
These observations are not a legal judgment or permission for public distribution.

## Coverage and delta limits

Extractor, CampaignTier2RuntimeAdapter/Validators, EntitySchemaRegistry and DataManager
supported the content sample. EditorAssetManager requires admitted media extensions,
path and sha256; FE tools retain source/geometry/naming/confidence/output hash metadata.
No new confirmed content defect was found in this bounded sample.

Excluded: visual inspection of binary art/fonts/audio, all FE asset variants, every
resource's semantic behavior, host rendering, generated imports/builds and frozen
checkouts. The 3,151 FE pillar-3 assignments are mostly assets, not 3,151 semantic
reviews. *(Corrected 2026-09-14 at closeout: recounted at the pinned FE SHA as 3,012
`assets/` plus 139 `packs/` paths; the draft said 3,143.)* August's 10/10 claim is not comparable to this explicitly sampled workspace
review. The score reflects consistent sampled wiring with known adoption gaps and
substantial disclosed visual exclusions.
