# GDD_10 - Build Guide And Roadmap

**Status:** Active - build guide.
**Last verified:** 2026-07-14

This document is the human-readable build guide. It explains build order,
near-term focus, release/validation queues, and where to find detail.

The row-per-work-item tracker is the Project Control Plane:
[`AGENT/Docs/plans/project_control_plane_2026-06-29.md`](../Docs/plans/project_control_plane_2026-06-29.md).
Use Track IDs from that document when updating work status.

The legacy Phase 2 roadmap was archived at
[`AGENT/Docs/archive/plans/gdd10_legacy_phase2_roadmap_2026-06-29.md`](../Docs/archive/plans/gdd10_legacy_phase2_roadmap_2026-06-29.md).
It is historical source detail, not the active schedule.

---

## How To Use This Guide

1. Start from the Project Control Plane for exact row status, dependencies,
   source docs, tests, and next action.
2. Use this file to understand build order and the next practical work queue.
3. When feature behavior changes, update the owning `GDD_01`-`GDD_08`
   section and the matching control-plane row in the same change.
4. When adding, moving, or retitling docs, regenerate `AGENT/Docs/INDEX.md` and
   `AGENT/Docs/REGISTERS.md`.
5. When adding a mechanical documentation rule, extend
   `AGENT/Docs/check_docs.py` in the same change.

## Authority Map

| Need | Go to |
|---|---|
| Exact work rows, dependencies, source docs, tests, and next action | [`project_control_plane_2026-06-29.md`](../Docs/plans/project_control_plane_2026-06-29.md) |
| What old `GDD_10` rows mapped to | [`gdd10_active_work_coverage_matrix_2026-06-29.md`](../Docs/plans/gdd10_active_work_coverage_matrix_2026-06-29.md) |
| Dependency-band scope source | [`planned_unimplemented_feature_triage_2026-06-28.md`](../Docs/plans/planned_unimplemented_feature_triage_2026-06-28.md) |
| Document role rules | [`doc_role_manifest_2026-06-29.md`](../Docs/plans/doc_role_manifest_2026-06-29.md) |
| Preferred terms and retired aliases | [`project_vocabulary_manifest_2026-06-29.md`](../Docs/plans/project_vocabulary_manifest_2026-06-29.md) |
| Feature lookup by domain | [`GDD_Feature_Index.md`](GDD_Feature_Index.md) |
| Open/resolved register lookup | [`AGENT/Docs/REGISTERS.md`](../Docs/REGISTERS.md) |

## V1 Scope Snapshot

| Scope | Meaning | Tracker rows |
|---|---|---|
| V1-core | Conservative first playable campaign path. | Bands 1-5 |
| V1-lean/stretch | Valuable v1-adjacent work after core prerequisites. Campaign sharing/export/import is in v1 by owner decision. | Band 6 |
| Optional after stable core | Useful systems that add test permutations after the campaign loop works. | Band 7 |
| Post-v1 / parked | Later work or parked experiments. Side activities, public scripting VM, online play, Laguz, and Awakening are here. | Band 8 |

## Build Order

The dependency order is not a calendar. Later design can continue while earlier
bands are implemented, but implementation should not consume missing
foundations or add unmanifested save state.

| Band | Name | Build purpose | Exit check |
|---|---|---|---|
| 0 | Scope and tracking | Finish the tracking system, role/vocabulary discipline, `GDD_10` rewrite, and feature-index wiring. | `GDD_10` links to Track IDs; feature index can route features to rows. |
| 1 | Determinism and save gate | Package A, F1, SaveCodec, campaign/save envelope, suspend foundations. | New save state has F1 rows and fixture obligations. |
| 2 | Shared authoring/runtime contracts | Registries, action/effect runner, resource ledger, occupancy, death lifecycle, projection, load seams. | Feature consumers can call shared APIs instead of adding closed switches. |
| 3 | Core authoring foundations | CampaignRules profiles, TCV, predicates, MET, PHB, text, stat registry, resource pools. | Story/event/economy/map content can be authored through registries and predicates. |
| 4 | Campaign loop vertical slice | IEQ, PXP, convoy, shop, map objects, DCH, villages, dialogue v1, recruit, difficulty/death mode, deployment. | A short campaign can move map -> victory/defeat -> prep -> next map with save coverage. |
| 5 | Tactical v1 enrichment | Conditions, skills/effects, Source+Style, action grants, secondary movement, AI composition, minimum scorer, utility staves. | V1 maps have enough tactical variety without optional-system overload. |
| 6 | V1-lean/stretch packs | Campaign sharing/export/import, CampaignStatusRecord, property capture, rescue/carry, fog, destructibles, relationship minimum, prep progression, map readability, input, web debug. | Each slice has prerequisites from Bands 1-5 and can be staged. |
| 7 | Optional after stable core | Arena, battalions, stationary weapons, forging, PvP, property recruitment/production, AI recruitment choices, advanced AI valuation. | Schedule only after the campaign loop is stable enough to absorb extra cases. |
| 8 | Post-v1 / parked | Side activities, public builder, content resync, remote play, Laguz, Awakening, hex, perception, ML, Vision Pro. | Revisit after first stable campaign release or owner scope change. |

## Next Work Queue

### B1-CST campaign / save spine

The largest unblocked bottleneck: all three dependencies are Implemented and
eleven open tracks wait on it. Sequenced slices are in
[`b1_cst_save_spine_handoff_2026-07-14.md`](../Docs/plans/b1_cst_save_spine_handoff_2026-07-14.md).
A returned v0.4.0 playtest preempts this work.

| Order | Track ID | To-do | Decision state |
|---:|---|---|---|
| 1 | `B1-CST` Slice 1 | **Implemented 2026-07-14:** `CampaignData`/`CampaignNode` progression graph, the shipped `proving_grounds` campaign, DataManager catalogue loading, and loud structural/reference validation. | Graph is authored JSON per [CST-3]; nodes bind by `map_id` until `B4-ENCOUNTER-MODEL` splits map/encounter. |
| 2 | `B1-CST` Slice 2 | **Implemented 2026-07-14:** `CampaignManager` autoload walks the graph (active campaign, current node, cleared nodes), resolves a node's `map_id` through the new `DataManager.get_map_registry_entry`, and drives the map launch; victory/defeat/results route through the existing `EventBus` map signals and `GameOverScreen` gained the campaign "Next" route. Handoff: [`b1_cst_slice2_prep_results_flow_handoff_2026-07-14.md`](../Docs/plans/b1_cst_slice2_prep_results_flow_handoff_2026-07-14.md). | A win RECORDS a result; the position advances only when the results surface commits it, so Retry cannot double-advance. Persists nothing (Slice 3 owns the envelope). Prep/deployment screens stay with `B4-PREP-DEPLOYMENT`; branch-node choice stays with the campaign selector. |
| 3 | `B1-CST` Slice 3 | Full campaign saves: campaign envelope, Continue/Load against the `SaveManager` disk seam, autosave and manual slots. | Target design. Every new persisted field registers in the F1 manifest in the same commit. |

### v0.3.3 returned-playtest defects

The v0.3.3 focused rerun returned on 2026-07-14. The permanent checklist and
root-cause packet are
[`playtest_checklist_v0.3.3_returned_2026-07-14.md`](../Docs/playtests/playtest_checklist_v0.3.3_returned_2026-07-14.md)
and
[`playtest_v0.3.3_results_triage_plan_2026-07-14.md`](../Docs/playtests/playtest_v0.3.3_results_triage_plan_2026-07-14.md).

| Order | Track ID | To-do | Decision state |
|---:|---|---|---|
| 1 | `VAL-V030-GAMEPAD` | Implemented 2026-07-14: raw joy-axis zoom no longer bypasses the 0.85 threshold or double-consumes a pull; final live validation remains. | Single-owner polling fix implemented with event-path regression coverage. |
| 2 | `B6-MRD` | Implemented 2026-07-14: watch sets, danger mode, markers, pruning, and versioned suspend state are isolated by controlling faction. | Watch state belongs to the controlling faction; no player/seat ownership. |
| 3 | `UI-INSPECTION` | v0.3.6 passed Action Menu shrink-wrap, ornament clearance, reopen growth, and edge clamping live. | Accepted for now; recheck visual spacing during the broader UI redesign pass. |
| 4 | `UI-INSPECTION` | v0.3.6 passed bounded Settings/Unit Details focus traversal live, including mixed-height lookahead and endpoint clamps. | Accepted for now; recheck focus-scroll context during the broader UI redesign pass. |

Menu threat retention and `dual_outline` passed. `VAL-V030-GAMEPAD` remains
Pending validation; the repaired UI surfaces passed the v0.3.6 focused rerun,
with polish retained under `UI-INSPECTION`. The next-session execution packet is
[`v0.3.3_playtest_fix_handoff_2026-07-14.md`](../Docs/plans/v0.3.3_playtest_fix_handoff_2026-07-14.md).

### v0.4.0 release gate

v0.4.0 is bounded to the seven Band 2 shared-contract slices. The release
checklist is [`v0.4.0_release_checklist_2026-07-13.md`](../Docs/plans/v0.4.0_release_checklist_2026-07-13.md).
All seven rows are implemented; the next session is a full-delta code review
against that checklist. Metadata/export work starts only after review findings
are resolved. Band 3 consumers are outside this release boundary.

> **Focused rerun build `v0.3.1` RETURNED 2026-07-12** (source `c7ce311`) —
> the live vehicle for the items below. Handbook:
> [`playtest_checklist_v0.3.1.md`](../Docs/playtests/playtest_checklist_v0.3.1.md);
> manifest (size/SHA-256):
> [`playtest_build_v0.3.1.md`](../Docs/playtests/playtest_build_v0.3.1.md).
> Returned checklist:
> [`playtest_checklist_v0.3.1_returned_2026-07-12.md`](../Docs/playtests/playtest_checklist_v0.3.1_returned_2026-07-12.md).
> Triage plan:
> [`playtest_v0.3.1_results_triage_plan_2026-07-12.md`](../Docs/playtests/playtest_v0.3.1_results_triage_plan_2026-07-12.md).
> Suspend and maximize readout hold; stick targeting passes; gamepad/display
> v0.3.2 closes the display gate and accepts MRD-7 `dual_outline`; the gamepad
> gate stays open only for zoom feel, with menu-overlay retention and scale-aware
> menu focus lookahead routed as bounded follow-ups.

| Order | Track ID | Work item | Why next |
|---:|---|---|---|
| 1 | `VAL-V030-GAMEPAD` | Fix the v0.3.3 trigger double-consumption defect | Raw joy-axis events bypass the polling threshold and can step once below 0.85, then again when polling crosses it. Route analog triggers exclusively through the threshold-aware poller and retest. |
| 2 | `B6-MRD` | Decide and implement watch-view ownership | Menu threat retention and `dual_outline` passed, but one global watch set leaks markers across faction handoffs. Per-faction state is recommended; include suspend migration. |
| 3 | `UI-INSPECTION` | Fix the two v0.3.3 high-scale layout findings | Make Action Menu width content-driven at 2x and calculate lookahead from visual owner rows rather than leaf slider height. Keep the existing deferred keybind/Main Menu tasks queued. |

## Parallel Queue

The v0.3.0 return arrived and was triaged 2026-07-08 via the return triage kit
([`playtest_v0.3.0_results_triage_plan_2026-07-08.md`](../Docs/playtests/playtest_v0.3.0_results_triage_plan_2026-07-08.md));
the focused v0.3.0.d rerun returned 2026-07-10 and moved the remaining fixes
into the Next Work Queue above. The rows below stay safe parallel candidates.

| Priority | Track ID / area | To-do | Notes |
|---:|---|---|---|
| 1 | `VAL-V030-GAMEPAD` / `VAL-V023-DISPLAY` | v0.3.2 focused rerun intake DONE 2026-07-13. | Returned checklist and two logs moved to permanent docs/evidence homes; [`playtest_v0.3.2_results_triage_plan_2026-07-13.md`](../Docs/playtests/playtest_v0.3.2_results_triage_plan_2026-07-13.md) records root causes and decisions. Display is Implemented; gamepad remains Pending validation only for zoom feel. |
| 2 | `B2-ACTION-EFFECT`, `B2-RESOURCE-LEDGER`, `B2-OCCUPANCY`, `B2-DEATH-LIFECYCLE`, `B2-PROJECTION`, plus `B3-TCV`, `B5-AI-COMPOSITION`, `B3-STAT-REGISTRY` | Continue the open-registry stream. | **First five Band 2 consumer contracts implemented 2026-07-13; review blockers and cleanup fixed:** source registries now strict-replace with their self-contained campaign root; actions have typed validation/dry-run plus safe optional defaults; fixed party/unit wallets have atomic transactions and truthful failed-refund reporting; map-start placement uses registry-dispatched nearest-free occupancy, skips isolated failures without aborting boot, and clears runtime-only delayed requests; combat death uses one structured lifecycle/disposition funnel with resolver-level mutual-death coverage and no circular fallback; and Attack Preview enters the shared typed projection service and clears stale selection state on projection failure. Effect/condition/AI/perception projection adapters, requirement gates, formulas, pools, broader placement/death consumers, custody, and persistent delay remain deferred. F1 reserves `ai_awake`, `extra_stats`, and the stat profile id; those consumers still require serializer/snapshot fixtures. |
| 3 | `UI-INSPECTION` | Prototype draft UI assets headlessly. | Build a mockup-only Godot `Control` scene/script that copies curated draft UI sheets into a temporary Theme, renders static Action Menu / UnitDetails / AttackPreview / shop-or-convoy list screenshots at supported menu scales, and checks for nonblank output, clipping, and bad slice margins. Keep it separate from production UI until the screenshots survive review. |
| 4 | `CLEAN-OBJDB-LEAK` | Clean benign test fixture leaks. | Optional cleanup from the ObjectDB audit; reduces noisy suite exits without changing player behavior. |
| 5 | `REL-PACKAGING` | Draft the release packaging flow. | Define shipped files, hashes, tags, manifests, checklist pairing, and future public/playtest packaging steps. |

### Persistent build items (schema reserved; implementation sequencing remains)

| Track ID | Reserved item | Remaining prerequisite |
|---|---|---|
| `B5-AI-COMPOSITION` (step 3+) | The MVP dispositions + activation from `ai_first_build_design_2026-06-22.md` §9 steps 3-6: `territorial`/`tethered` (sleep+latch / leashed return-home), `flee` (±`goal_tile`), `seek_tile`, group-keyed aggro, and the MET `set_ai` action. (`weakest` already ships through `hunter`.) | F1 is implemented and reserves active-map AI wake/latch state. The build slice must now add the exact `ai_awake` serializer/snapshot representation and fixtures while coordinating `set_ai` with the unbuilt MET/action runner. |
| `B3-STAT-REGISTRY` (storage slice) | The author-extensible stat STORAGE model ([STM-3]): `UnitData.extra_stats` name->value dict, `ClassData` extra-stat bases/caps/growths, the `get_effective_stat` read-path fallback, and the author-declared stat registry on `CampaignRules`/manifest so adding a stat becomes one data entry (zero engine edit). | F1 is implemented with `roster.units[].extra_stats` and `campaign.rules.stat_profile_id` rows. The build slice must add their stat adapter, reference validation, old-save defaults, and codec round-trip fixtures together. |

## Validation And Release Queues

These are not blocked by the full Band 1-5 build path, but they should not be
lost during foundation work.

| Track ID | Queue | Action |
|---|---|---|
| `VAL-V023-DISPLAY` | Validation | **Implemented 2026-07-13:** v0.3.2 passed width-only and height-only resize tracking, one-second convergence, relaunch persistence, maximize labeling, and restore-to-saved-size. Evidence and routing: `playtest_v0.3.2_results_triage_plan_2026-07-13.md`. |
| `VAL-V030-GAMEPAD` | Validation | v0.3.2 passed dropdown standdown, character-sheet navigation/scrolling, menu cadence, and contextual-menu anchoring. Gate remains Pending validation only for asymmetric LT/RT zoom feel; source diagnosis points to uneven zoom ratios rather than separate trigger timers. Triage: `playtest_v0.3.2_results_triage_plan_2026-07-13.md`. |
| `REL-V023-MERGE` | Release gate | Merge the v0.2.3 branch to `main` only after validation passes. |
| `VAL-V022-CHECKBACKS` | Validation | Walk the v0.2.2 live-verify check-backs during playtest triage. |
| `VAL-PLAYTEST-RERUN` | Validation | Rerun outstanding playtest items before promoting them to defects. |
| `REL-REN` | Release gate | Owner must choose public naming direction before first public RC. |
| `REL-LEG` | Release gate | Owner must identify source corpus/license before public release. |
| `REL-PACKAGING` | Release gate | Draft release packaging flow after v0.2.3 process settles. |
| `REL-WEB-DEMO` | Release gate | Draft the slice-first playable web-demo plan after the campaign-loop foundations are accepted. |

## Cleanup Queue

Release hardening has three active cleanup rows. Keep them separate from feature
work until a non-debug release is being cut.

| Track ID | Cleanup |
|---|---|
| `CLEAN-DEBUG-AIDS` | Remove force-levelup and growth-boost debug aids. |
| `CLEAN-F9-HOTSEAT` | Remove F9 all-faction hotseat override. |
| `CLEAN-DEBUG-HUD` | Remove debug-mode HUD banner ecosystem. |

The stale `GDD_10` milestone body has been replaced by this Track-ID build
guide. Future cleanup should happen in the owning tracker row or numbered GDD
chapter rewrite, not by restoring legacy milestone order.

## Parked Or Post-v1 Work

Do not schedule these for v1 unless the owner explicitly changes scope:

| Track ID | Work |
|---|---|
| `B8-ACTIVITIES` | Side activities, ActivityRunner, activity templates, public scripting VM. |
| `B8-PUBLIC-BUILDER` | Public campaign builder / authoring GUI. |
| `B8-CONTENT-RESYNC` | Public content-pack compatibility/resync. |
| `B8-REMOTE-PLAY` | Remote / online play. |
| `B8-LAGUZ` | Laguz system. |
| `B8-AWAKENING` | Awakening supplement. |
| `B8-HEX` | Optional hex topology. |
| `B8-PERCEPTION` | Perception / masking. |
| `B8-ML-EVAL` | ML evaluation experiment. |
| `B8-VISION-PRO` | Apple Vision Pro reach. |

## Update Discipline

When work changes:

| Change | Required documentation update |
|---|---|
| Behavior changes | Update affected `GDD_01`-`GDD_08` section and the matching control-plane row. |
| Work status changes | Update the Project Control Plane row; keep this guide as a summary. |
| New feature or scope split appears | Add or adjust a Track ID in the Project Control Plane, then wire the feature index. |
| New active doc is added or moved | Regenerate `AGENT/Docs/INDEX.md`; if it is a register change, regenerate `REGISTERS.md` too. |
| Mechanical doc rule is ratified | Add `check_docs.py` enforcement in the same change. |
| Session ends | Add a session note and newest-first row in `AGENT/Session Notes/INDEX.md`. |

## Known Follow-ups

No completed Band 0 documentation task remains queued here. Future owner-heading or
scope changes must update the exact Feature Index links and their control-plane rows
in the same change.
