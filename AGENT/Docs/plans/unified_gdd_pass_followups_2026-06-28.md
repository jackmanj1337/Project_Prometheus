---
Type: plan
Status: Active - planning note
Last verified: 2026-06-29
---

# Unified GDD Pass Followups

**Started:** 2026-06-28. Created from L2 in
[`design_review_unimplemented_systems_2026-06-28.md`](../../Code%20Reviews/design_review_unimplemented_systems_2026-06-28.md).

**Purpose.** This note exists so the later unified GDD/v1-definition pass finds
known navigation cleanup work without rewriting roadmap text now.

## Required Cleanup

| Source | Problem | Recommended fix during unified GDD pass |
|---|---|---|
| L2 review finding | `GDD_10_Roadmap.md` still contains older navigation statements such as "All other registers remain OPEN" and an older campaign critical path, while later registers, generated indexes, and the feature atlas supersede parts of that prose. | During the unified GDD/v1 pass, explicitly retire, supersede, or rewrite stale navigation blocks so GDD_10 points to the generated register index, feature atlas, and new foundation-fix docs as the active scheduling inputs. Do not patch isolated sentences now unless they are already being edited for that pass. <!-- retired-vocabulary: historical-quotation --> |
| Pre-GDD triage reprioritization 2026-06-28 + owner update 2026-06-29 | The planned/unimplemented feature list is now dependency-banded into v1-core Bands 1-5, v1-lean/stretch Band 6, optional Band 7, and post-v1/parked Band 8. Owner update: campaign sharing/exporting is v1; side activities are not. | During the unified GDD/v1 pass, use `plans/planned_unimplemented_feature_triage_2026-06-28.md` as the scheduling source. Track campaign sharing/export/import in Band 6; keep ActivityRunner, activity templates, and public scripting VM parked unless the owner later changes scope. |
| Minigame activity specs 2026-06-28c | The old triage phrase "mini-game module seam / casino/fishing/garden" blurs three different decisions: the shared ActivityRegistry/ActivityRunner seam, validated activity templates, and a future public scripting VM. | During the unified GDD/v1 pass, keep those three separate and mark all three post-v1/parked under the 2026-06-29 owner decision. Do not include side activities in v1. <!-- retired-vocabulary: historical-quotation --> |
| Map-completion counters 2026-06-28 | Some prep/activity ideas need calendar-like cadence without a real calendar: garden/brewing completion after N map clears, restocks, and territory-pressure/encroaching-army mechanics. | During the unified GDD/v1 pass, consider a small generic counter pair (`total_maps_played`, `story_maps_played`) exposed through TCV/REQ/MET. Treat it as calendar-lite cadence, not a bespoke garden/brewing subsystem and not a full overworld calendar. |
| Living project tracking owner update 2026-06-29 | The overhaul is not done until active docs use one vocabulary, one organizational pattern, and one naming convention. | Add a vocabulary/naming normalization phase to the unified GDD pass and create checks for mechanical naming rules once the vocabulary map is ratified. |

## Search Tags

- unified GDD pass
- v1 definition
- roadmap cleanup
- stale navigation
- design review L2
- minigame activity seam
- ActivityRegistry
- campaign sharing/exporting
- reprioritized dependency bands
- vocabulary unification
- total maps played
- story maps played
- calendar-lite cadence
