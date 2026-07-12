# GDD_10 - Build Guide And Roadmap

**Status:** Active - build guide.
**Last verified:** 2026-07-12

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

> **Focused rerun build `v0.3.0.d` RETURNED 2026-07-10** (source `e19ac9b`) —
> the live vehicle for the items below. Handbook:
> [`playtest_checklist_v0.3.0.d.md`](../Docs/playtests/playtest_checklist_v0.3.0.d.md);
> manifest (size/SHA-256):
> [`playtest_build_v0.3.0.d.md`](../Docs/playtests/playtest_build_v0.3.0.d.md).
> Returned checklist:
> [`playtest_checklist_v0.3.0.d_returned_2026-07-10.md`](../Docs/playtests/playtest_checklist_v0.3.0.d_returned_2026-07-10.md).
> Triage + review plan:
> [`playtest_v0.3.0.d_results_triage_plan_2026-07-10.md`](../Docs/playtests/playtest_v0.3.0.d_results_triage_plan_2026-07-10.md).
> Suspend validated; gamepad/display stay open; MRD-7 routes to a
> stacked-plus-perimeter candidate.

| Order | Track ID | Work item | Why next |
|---:|---|---|---|
| 1 | `B6-INPUT` | Live-validate the V030D-GP controller defect fixes | v0.3.0.d return (2026-07-10): Settings repeat, New Game modal focus containment, joystick attack/Pair Up target cycling, and trigger zoom feel failed live. Headless fixes landed 2026-07-10: `ModalScreen` vertical repeat + focus containment, `MenuRepeatPolicy.clear()` wait-for-neutral latch, polled-stick target cycling through `MapCursor` targeting, and a conservative LT/RT zoom tune (`0.35` press threshold, `0.45s`→`0.18s` repeat range). Gate still needs live controller validation. Review/fix plan: [`playtest_v0.3.0.d_triage_review_2026-07-10.md`](../Code%20Reviews/playtest_v0.3.0.d_triage_review_2026-07-10.md). |
| 2 | `VAL-V023-DISPLAY` | Live-validate the V030D-DSP resize/readout fixes | v0.3.0.d return (2026-07-10): relaunch persistence passed, but one-axis drag still fails and maximized state labels as `Custom` instead of `Maximized`. Headless fixes landed 2026-07-10: resize detection now listens to the root Window as well as the viewport, and Settings refreshes its readout from a settled display-size signal even when no Resolution write-back occurs. Gate still needs live Windows validation. |
| 3 | `B6-MRD` | Live-review the MRD-7 stacked-perimeter candidate | The focused rerun rejected the single-layer treatment, accepted `stacked` and `border_through` as readable, and supplied a sketch for stacked fill plus a perimeter outline around the whole threatened area. `stacked_perimeter` landed headlessly 2026-07-10 with generated edge-mask sources and F8 cycle coverage. Next: live acceptance, then remove the temporary debug F8 cycle once accepted. |
| 4 | `UI-INSPECTION` | Route Main Menu 2.0x overlap evidence | v0.3.0.d returned a fresh screenshot showing Continue overlapping the title at 2.0x Menu Scale. Keep this under the existing `V027-05a` scale-safe Main Menu layout task. |

## Parallel Queue

The v0.3.0 return arrived and was triaged 2026-07-08 via the return triage kit
([`playtest_v0.3.0_results_triage_plan_2026-07-08.md`](../Docs/playtests/playtest_v0.3.0_results_triage_plan_2026-07-08.md));
the focused v0.3.0.d rerun returned 2026-07-10 and moved the remaining fixes
into the Next Work Queue above. The rows below stay safe parallel candidates.

| Priority | Track ID / area | To-do | Notes |
|---:|---|---|---|
| 1 | `VAL-V030-GAMEPAD` / `VAL-V023-DISPLAY` | Focused rerun intake DONE 2026-07-10. | v0.3.0.d returned checklist copied ([`playtest_checklist_v0.3.0.d_returned_2026-07-10.md`](../Docs/playtests/playtest_checklist_v0.3.0.d_returned_2026-07-10.md)), evidence archived, and triage/review plan written. Both gates stay open; see the Next Work Queue. |
| 2 | `B2-REGISTRY` plus `B3-TCV`, `B5-AI-COMPOSITION`, `B3-STAT-REGISTRY` | Continue the open-registry stream. | **`B2-REGISTRY` Slice 1 implemented 2026-07-12:** the shared registry entry/catalog/manager foundation and three export-safe starter families now load and validate headlessly. Earlier non-schema AI/stat slices also landed. F1 has been implemented and reserves `ai_awake`, `extra_stats`, and the stat profile id, so the old blanket "F1-gated" wording is retired; those consumers still require their serializer/snapshot fixtures in the same slice. Objective conditions remain sequenced after the typed variable store and predicate system. Next owner choice: follow the Band 2 plan into Action/Effect despite its `B3-REQ` dependency, or pull forward behavior-neutral DataManager load/validate seams. |
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
| `VAL-V023-DISPLAY` | Validation | v0.3.0.d returned 2026-07-10: relaunch persistence passed, but one-axis drag still fails and maximized state labels as `Custom`. Headless fixes for live readout refresh plus OS-window-size one-axis detection landed 2026-07-10; gate stays open for the next live Windows rerun. Triage: `playtest_v0.3.0.d_results_triage_plan_2026-07-10.md`. |
| `VAL-V030-GAMEPAD` | Validation | v0.3.0.d returned 2026-07-10: Settings scrolls and action menu feels good, but Settings repeat is missing, New Game focus leaks outside its modal, joystick cannot cycle attack/Pair Up targets, and trigger zoom still needs tuning. Headless fixes for repeat/focus/targeting plus a conservative trigger-feel tune landed 2026-07-10; gate stays open for live controller validation. Triage: `playtest_v0.3.0.d_results_triage_plan_2026-07-10.md`. |
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

| Track ID | Follow-up |
|---|---|
| `B0-GDD-ANCHORS` | Add exact feature-index section anchors during the numbered GDD chapter rewrites. |
| `B0-VOCAB-NAMING` | Normalize retired terms during the numbered GDD chapter rewrites. |
| `VAL-OBJECTIVE-MAPS` | Resolve the old contradiction where M16 marked Maps 002-005 done while the Phase 3 backlog left them open. |
| `VAL-M14-LEFTOVERS` | Move any real tactical-AI work to `B5-AI-MIN-SCORER` or `B7-AI-ADVANCED-VALUATION`. |
