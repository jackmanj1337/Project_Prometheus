# GDD_10 - Build Guide And Roadmap

**Status:** Active - build guide.
**Last verified:** 2026-07-13

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
> stay open on narrowed defects; MRD-7 routes to a dual-outline candidate.

| Order | Track ID | Work item | Why next |
|---:|---|---|---|
| 1 | `B6-INPUT` | Fix the narrowed V031-GP defects | v0.3.1 return (2026-07-12): Settings repeat/scroll and keybind-capture containment now pass live, and stick attack/Pair Up targeting passes. Remaining defects: focus behind an open dropdown still moves while picking from the sub-menu (V031-GP-02 — headless-fixed 2026-07-12: `ModalScreen` polling/containment stands down while an embedded popup is visible and re-latches to neutral on close), the character sheet does not scroll with focus and skips View Support / View Lead on keyboard and pad (V031-GP-05 — headless-fixed 2026-07-12: the pair button is a selectable entry and selection scrolls its owning section into view; V031-GP-01 lookahead landed with it), repeat cadence still slightly fast in character sheet/Action Menu (V031-GP-03), LT/RT zoom still too sensitive (V031-GP-04), and scrolling lists need focus lookahead padding (V031-GP-01). V031-GP-03/04 headless-fixed 2026-07-12: menus moved to their own slower `MENU_KEY_REPEAT_DELAY/RATE` (0.30s/0.15s) and zoom dropped strength scaling for one constant 0.45s cadence (owner decision) — live feel confirmation rides the next rerun. |
| 2 | `VAL-V023-DISPLAY` | Fix the one-axis drag event stall | v0.3.1 return (2026-07-12): maximize reads `Maximized (WxH)` live and relaunch returns to the last saved size. The one-axis drag holdout narrowed: the trace shows stepwise write-back to `1125x633`, then all size events stop mid-drag while the window kept growing (V031-DSP-01); a degenerate `491x1913` size was also persisted (V031-DSP-01b — owner declined a clamp 2026-07-12, dragged sizes are honored as-is). Headless-fixed 2026-07-12: write-back now updates memory/readout per event but coalesces the disk save behind a 0.75s settle timer (flushed on quit), and a 0.5s `DisplayServer` size poll feeds missed signals into the same refresh path. Needs the live Windows one-axis drag rerun to close. |
| 3 | `B6-MRD` | Live-review the MRD-7 dual-outline candidate | v0.3.1 return: no prior F8 mode accepted; the tester specified a refined candidate (V031-MRD-01, colors confirmed 2026-07-12): a dark-red outline around the watched-threat area drawn OVER a bright-red outline around the entire danger area, both above units. `dual_outline` landed headlessly 2026-07-12 as the fifth F8 mode — a `ThreatPerimeterOverlay` draw surface above unit sprites stroking pure edge-mask segments, stacked fill underneath. Next: live acceptance, then remove the temporary F8 cycle. |
| 4 | `UI-INSPECTION` | Route v0.3.1 UI-pass notes | Carry the keybind-grid focus order note (V031-GP-06, left-right-then-down vs straight down) and focus scroll-margin styling alongside the existing `V027-05a` 2.0x Main Menu overlap task. |

## Parallel Queue

The v0.3.0 return arrived and was triaged 2026-07-08 via the return triage kit
([`playtest_v0.3.0_results_triage_plan_2026-07-08.md`](../Docs/playtests/playtest_v0.3.0_results_triage_plan_2026-07-08.md));
the focused v0.3.0.d rerun returned 2026-07-10 and moved the remaining fixes
into the Next Work Queue above. The rows below stay safe parallel candidates.

| Priority | Track ID / area | To-do | Notes |
|---:|---|---|---|
| 1 | `VAL-V030-GAMEPAD` / `VAL-V023-DISPLAY` | Focused rerun intake DONE 2026-07-12. | v0.3.1 returned checklist copied ([`playtest_checklist_v0.3.1_returned_2026-07-12.md`](../Docs/playtests/playtest_checklist_v0.3.1_returned_2026-07-12.md)), evidence archived, and triage plan written. Both gates stay open on narrowed defects; see the Next Work Queue. |
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
| `VAL-V023-DISPLAY` | Validation | v0.3.1 returned 2026-07-12: maximize readout and relaunch-to-saved-size pass live; one-axis drag narrowed to a mid-drag size-event stall (V031-DSP-01) plus a degenerate persisted size (V031-DSP-01b). Gate stays open pending the record-only/settle-then-persist fix and the next live Windows rerun. Triage: `playtest_v0.3.1_results_triage_plan_2026-07-12.md`. |
| `VAL-V030-GAMEPAD` | Validation | v0.3.1 returned 2026-07-12: Settings repeat/scroll, keybind-capture containment, and stick attack/Pair Up targeting pass live. Remaining: dropdown sub-menu focus standdown (V031-GP-02), character-sheet scroll + skipped View Support/View Lead (V031-GP-05), and cadence/zoom tunes (`V031-GP-03/04`). Gate stays open for the next live controller rerun. Triage: `playtest_v0.3.1_results_triage_plan_2026-07-12.md`. |
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
| `VAL-M14-LEFTOVERS` | Move any real tactical-AI work to `B5-AI-MIN-SCORER` or `B7-AI-ADVANCED-VALUATION`. |
