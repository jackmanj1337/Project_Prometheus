---
Type: plan
Status: Active - planning note
Last verified: 2026-06-28
---

# Unified GDD Pass Followups

**Started:** 2026-06-28. Created from L2 in
[`design_review_unimplemented_systems_2026-06-28.md`](../../Code%20Reviews/design_review_unimplemented_systems_2026-06-28.md).

**Purpose.** This note exists so the later unified GDD/v1-definition pass finds
known navigation cleanup work without rewriting roadmap text now.

## Required Cleanup

| Source | Problem | Recommended fix during unified GDD pass |
|---|---|---|
| L2 review finding | `GDD_10_Roadmap.md` still contains older navigation statements such as "All other registers remain OPEN" and an older campaign critical path, while later registers, generated indexes, and the feature atlas supersede parts of that prose. | During the unified GDD/v1 pass, explicitly retire, supersede, or rewrite stale navigation blocks so GDD_10 points to the generated register index, feature atlas, and new foundation-fix docs as the active scheduling inputs. Do not patch isolated sentences now unless they are already being edited for that pass. |

## Search Tags

- unified GDD pass
- v1 definition
- roadmap cleanup
- stale navigation
- design review L2
