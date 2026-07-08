# GDD_10 - Build Guide And Roadmap

**Status:** Active - build guide.
**Last verified:** 2026-07-08

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

| Order | Track ID | Work item | Why next |
|---:|---|---|---|
| 1 | `B1-SUSPEND` | Fix the returned V030-SUS-01 suspend/resume defects | v0.3.0 return (2026-07-08): after Continue units cannot move, pair-up supports render at the off-map placeholder, debug red-team control + resume corrupts input, and the turn counter restores wrong. Top defect in [`playtest_v0.3.0_results_triage_plan_2026-07-08.md`](../Docs/playtests/playtest_v0.3.0_results_triage_plan_2026-07-08.md); failing-first repro tests in `test_suspend_map_runtime.gd`, then fix. |
| 2 | `B6-INPUT` | Fix the returned V030-GP-01/02/03 + V030-INP-02 controller failures | v0.3.0 return: controller focus cannot scroll Settings, menus lack directional repeat, New Game focus highlight gaps, menu stick cadence too fast, LT/RT zoom too sensitive, and prompts brand from the first-connected pad instead of the pad in use. Gate blockers for `VAL-V030-GAMEPAD`; Q1/Q2 DECIDED 2026-07-08 in [`playtest_v0.3.0_triage_review_2026-07-08.md`](../Code Reviews/playtest_v0.3.0_triage_review_2026-07-08.md) (relabel Input Mode → Input Prompts, behavior unchanged; brand-correct words now, glyphs ride `UI-INSPECTION`). |
| 3 | `VAL-V023-DISPLAY` | Fix V030-DSP-01 section 1.6 residue, then a focused rerun | v0.3.0 return live-validated the v0.2.8 fix core (custom client readout, no re-clamp, reactive centering, no maximize persistence). Remaining: one-axis drag readout, stale maximized `client WxH` label (Q4 DECIDED 2026-07-08: show live `Maximized (WxH)`), and an explicit relaunch-persistence check in the rerun handbook. |

## While Waiting For v0.3.0 Return

The v0.3.0 return arrived and was triaged 2026-07-08 via the return triage kit
([`playtest_v0.3.0_results_triage_plan_2026-07-08.md`](../Docs/playtests/playtest_v0.3.0_results_triage_plan_2026-07-08.md));
the fix passes moved into the Next Work Queue above. Owner review Q1-Q5 was
DECIDED the same day (see the triage review's Walkthrough Decisions); the
remaining rows stay safe parallel candidates.

| Priority | Track ID / area | To-do | Notes |
|---:|---|---|---|
| 1 | `VAL-V030-GAMEPAD` / `VAL-V023-DISPLAY` | Return intake DONE 2026-07-08. | Kit executed: returned checklist copied ([`playtest_checklist_v0.3.0_returned_2026-07-08.md`](../Docs/playtests/playtest_checklist_v0.3.0_returned_2026-07-08.md)), evidence archived, triage plan + owner review written. Both gates stay open; see the Next Work Queue. |
| 2 | `B2-REGISTRY` plus `B3-TCV`, `B5-AI-COMPOSITION`, `B3-STAT-REGISTRY` | Start the open-registry debt stream. | Convert the known closed vocabularies toward registries: objective conditions `[TCV-4]`, AI profiles `[AIP]`, and stat names/model `[STM]`. Best technical progress; use a separate commit stream from v0.3.0 validation. |
| 3 | `UI-INSPECTION` | Prototype draft UI assets headlessly. | Build a mockup-only Godot `Control` scene/script that copies curated draft UI sheets into a temporary Theme, renders static Action Menu / UnitDetails / AttackPreview / shop-or-convoy list screenshots at supported menu scales, and checks for nonblank output, clipping, and bad slice margins. Keep it separate from production UI until the screenshots survive review. |
| 4 | `CLEAN-OBJDB-LEAK` | Clean benign test fixture leaks. | Optional cleanup from the ObjectDB audit; reduces noisy suite exits without changing player behavior. |
| 5 | `REL-PACKAGING` | Draft the release packaging flow. | Define shipped files, hashes, tags, manifests, checklist pairing, and future public/playtest packaging steps. |

## Validation And Release Queues

These are not blocked by the full Band 1-5 build path, but they should not be
lost during foundation work.

| Track ID | Queue | Action |
|---|---|---|
| `VAL-V023-DISPLAY` | Validation | v0.3.0 returned 2026-07-08: v0.2.8 fix core held live (client readout, no re-clamp, centering, no maximize persistence); gate stays open on V030-DSP-01 (one-axis drag readout, maximized label, relaunch persistence). Fix, then a section-1.6-only rerun. Triage: `playtest_v0.3.0_results_triage_plan_2026-07-08.md`. |
| `VAL-V030-GAMEPAD` | Validation | v0.3.0 returned 2026-07-08: mapping and mixed-input pass, but menu focus scroll/repeat (V030-GP-01), menu stick cadence (V030-GP-02), and trigger sensitivity (V030-GP-03) fail live. Gate stays open; fix under `B6-INPUT`, then a focused controller rerun. Triage: `playtest_v0.3.0_results_triage_plan_2026-07-08.md`. |
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
