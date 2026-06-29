---
Type: plan
Status: Active - planning input
Last verified: 2026-06-29
---

# Living Project Tracking System Plan

**Started:** 2026-06-29. Created before the unified GDD rewrite.

**Purpose.** Define how to rewrite the GDD and living project docs so every
active design, implementation plan, release gate, validation item, and deferred
feature can be found and tracked through one system.

This plan does not rewrite the GDD yet. It defines the documentation system the
rewrite should produce.

## Recommendation

Do **not** merge every design into one giant GDD or make `GDD_10_Roadmap.md`
carry all detail. That would recreate the problem: one long file with stale
status prose.

Use a **single control plane** instead:

1. `GDD_00` through `GDD_08` stay the design/rules contract.
2. `GDD_10_Roadmap.md` becomes the build guide and work-order owner.
3. `GDD_Feature_Index.md` becomes the feature lookup table.
4. `AGENT/Docs/REGISTERS.md` remains the generated decision-register catalog.
5. `AGENT/Docs/plans/` and `AGENT/Docs/design/` remain source docs, but they do
   not own schedule status unless a tracker row points to them.
6. A new **Project Control Plane** table ties all of those together with one row
   per active work item.

The control plane should be easy to scan and hard to bypass. It should answer:

- what is the item,
- what band is it in,
- what blocks it,
- where is the design authority,
- where is the implementation plan,
- what GDD sections must change,
- what tests/checks prove it,
- what is the next action.

## Proposed Source-Of-Truth Model

| Doc | Role after rewrite | Must not do |
|---|---|---|
| `GDD_00_Overview.md` | Authority model, navigation, release definition, and "where to start" page. | Store feature detail or work queues. |
| `GDD_01`-`GDD_08` | Design/rule contracts by domain. Each feature gets a short status-bearing section or pointer. | Duplicate long register deliberations. |
| `GDD_10_Roadmap.md` | Single build guide: dependency bands, active work queue, release gates, validation queue, and next-build handoff. | Carry old milestone prose as active schedule. |
| `GDD_Feature_Index.md` | Feature lookup: feature -> GDD owner -> tracker row -> registers/plans/tests/code. | Become a roadmap. |
| `AGENT/Docs/REGISTERS.md` | Generated catalog of open/resolved register decisions. | Replace the build guide. |
| `AGENT/Docs/INDEX.md` | Generated active-doc lookup. | Replace feature/work tracking. |
| `AGENT/Docs/plans/*` | Implementation plans, triage inputs, inventories, and migration plans. | Own active status without a tracker row. |
| `AGENT/Docs/design/*` | Design contracts and architecture decisions. | Own implementation sequencing. |
| `AGENT/Docs/playtests/*` | Playtest manifests, checklists, and validation queues. | Hide release blockers outside the control plane. |

## Project Control Plane Row Schema

Create a table in `GDD_10_Roadmap.md` or a companion plan file that `GDD_10`
links as the schedule authority. Recommendation: keep the active table in
`GDD_10_Roadmap.md` so DoD#1 stays simple.

| Field | Meaning |
|---|---|
| Track ID | Stable id such as `B1-F1`, `B4-IEQ`, `VAL-V021-12`, or `REL-LEG`. |
| Band | Dependency band from `planned_unimplemented_feature_triage_2026-06-28.md`. |
| Status | Governance vocabulary only: Planned, Target design, Pending validation, Deferred, Open decision, Known issue, Historical, Superseded, Implemented. |
| Work item | Human-readable name. |
| Scope | One-sentence build scope. |
| Blocks / depends on | Track IDs or named contracts that must land first. |
| GDD owner | `GDD_01`-`GDD_08` section(s) that hold the rule/design contract. |
| Decision source | Register, decision record, or design doc that resolved the behavior. |
| Build source | Implementation plan, contract, or "needs plan" marker. |
| Save/registry impact | F1 manifest rows and registry families touched. |
| Test/validation | Required automated tests, doc checks, manual playtest, or release gate. |
| Next action | The next concrete planning/build step. |

## Rewrite Phases

### Phase 0 - Coverage Audit

Goal: prove every live GDD_10 open row is accounted for before rewriting.

Steps:

1. Extract every open, deferred, validation, and release-blocking row from
   `GDD_10_Roadmap.md`.
2. Classify each row as one of:
   - feature/system work,
   - build foundation,
   - content/data work,
   - validation or live-verify item,
   - release gate,
   - pre-release cleanup,
   - historical/superseded row.
3. Map every row to:
   - a dependency band,
   - an umbrella parent row,
   - or an explicit "not feature triage" bucket.
4. Add missing rows from the triage back into the coverage matrix.
5. Keep old milestone prose untouched until the coverage matrix has no unmapped
   active rows.

Deliverable: `AGENT/Docs/plans/gdd10_active_work_coverage_matrix_2026-06-29.md`.

### Phase 1 - Control Plane Skeleton

Goal: create the tracking structure before moving details.

Steps:

1. Add the Project Control Plane table to `GDD_10_Roadmap.md`.
2. Seed it from the dependency bands:
   - Bands 1-5 as v1-core,
   - Band 6 as v1-lean/stretch,
   - Band 7 as optional after stable core,
   - Band 8 as post-v1/parked.
3. Add separate queues for:
   - validation/live-verify,
   - release gates,
   - pre-release cleanup,
   - content/data packs,
   - polish/art/audio.
4. Point each row to existing docs instead of copying detail.
5. Mark stale milestone sections as Historical or move them to archive once their
   active rows are represented.

Deliverable: `GDD_10_Roadmap.md` rewritten as the build guide.

### Phase 2 - GDD Chapter Rewrite

Goal: make `GDD_01`-`GDD_08` match the resolved design corpus.

Order:

1. `GDD_01_Architecture.md`: save schema, registries, action/effect primitive,
   resource ledger, occupancy, death lifecycle, projection, determinism.
2. `GDD_02_Core_Mechanics.md`: combat resolution, conditions, Source+Style
   combat effects, EXP, death mode, difficulty effects.
3. `GDD_03_Units_Classes.md`: roster, class/proficiency, extra stats, avatar,
   relationship hooks, promotion/reclass content implications.
4. `GDD_04_Weapons_Items.md`: IEQ, convoy, shop/economy, source/equip model,
   story items, broken weapons, forging deferral.
5. `GDD_05_Skills.md`: skill model expansion, dynamic grants, loadout caps,
   action grants, Secondary Movement, utility staves, battalions if kept as
   planned/deferred.
6. `GDD_06_Maps_Objectives.md`: MET, map objects, doors/chests, destructibles,
   villages, recruit/talk, objective predicates, spawn occupancy, fog.
7. `GDD_07_UI_UX.md`: PHB panels, dialogue presentation, map readability,
   input/gamepad/key rebinding, web debug, validation/polish queues.
8. `GDD_08_Enemy_AI.md`: AI composition, profile registry, first build,
   valuation, perception/masking deferral.

Rule: each chapter section should be short and point to source docs for the
long-form register/history.

### Phase 3 - Feature Index and Register Wiring

Goal: make feature lookup reliable.

Steps:

1. Update `GDD_Feature_Index.md` so every active work item has:
   - tracker ID,
   - GDD owner,
   - register/design source,
   - implementation plan,
   - test home,
   - code/data owner when known.
2. Update register headers only if their status/source metadata is wrong.
3. Run `python3 AGENT/Docs/gen_docs_index.py` after doc moves/additions.
4. Keep `REGISTERS.md` and `INDEX.md` generated.

### Phase 4 - Archive Or Supersede Stale Planning Docs

Goal: reduce active-doc noise without deleting history.

Steps:

1. For each active plan/design doc, choose one:
   - keep active and link from a tracker row,
   - mark as historical input and archive,
   - supersede by a newer design/plan and archive.
2. Add the required archive marker in the first 10 lines when moving.
3. Regenerate docs indexes in the same change.
4. Do not archive registers just because they are resolved; resolved registers
   remain decision evidence unless a governance rule says otherwise.

### Phase 5 - Enforcement

Goal: make the system durable.

Checks to add when ratified:

1. Every non-Implemented / non-Historical GDD_10 row has a tracker ID.
2. Every tracker row has a GDD owner and a source doc.
3. Every active plan/design doc is referenced by at least one tracker row,
   feature-index row, or generated index exception.
4. Every new save-affecting tracker row references an F1 manifest row or says
   `no_save_guard`.
5. Every author-facing vocabulary row references a registry family or explicitly
   declares an engine-only closed-list exception.

DoD#2 note: these checks should land only when the control-plane schema is
ratified, not in this planning document.

## Build Guide Shape

Rewrite `GDD_10_Roadmap.md` into these sections:

1. **How To Use This Build Guide**
2. **Active Build Bands**
3. **Project Control Plane**
4. **Next Build Queue**
5. **Validation Queue**
6. **Release Gates**
7. **Pre-Release Cleanup**
8. **Deferred / Parked Work**
9. **Historical Milestone Summary**
10. **Appendix: Old Milestone Mapping**

The old M8-M16 material should become an appendix or archived historical source
once each active task has a control-plane row.

## Initial Band Mapping

Use the reprioritized triage as the seed:

| Band | Meaning | Examples |
|---|---|---|
| 1 | Determinism and save gate | Package A, F1 lock, SaveCodec, campaign envelope. |
| 2 | Shared contracts | Registries, action/effect runner, resource ledger, occupancy, death, projection. |
| 3 | Core authoring foundations | F4/F6/TCV/F16/MET/PHB/F13/F14/F7. |
| 4 | Campaign loop vertical slice | IEQ/PXP, convoy, shop, map objects, dialogue v1, recruit, difficulty/death mode. |
| 5 | Tactical v1 enrichment | Conditions, Source+Style, skill effects/grants, staves, Secondary Movement, action grant, AI first build. |
| 6 | V1-lean/stretch | Rescue/capture expansion, fog, destructibles, minimum supports, bonus EXP/training, map readability, input/gamepad. |
| 7 | Optional after stable core | Arena, battalion/gambit slice, stationary weapons, forging, PvP hotseat, advanced AI, extra activity templates. |
| 8 | Post-v1 / parked | Public builder, public scripting VM, online, perception/masking, hex, ML AI, Laguz, Awakening supplement. |

## Known Gaps To Close In The Coverage Audit

These are known from the first comparison against `GDD_10_Roadmap.md`:

| Gap | Recommended handling |
|---|---|
| v0.2.3 live-verify and V021 rows | Put in the Validation Queue, not the feature bands. |
| Pre-release debug cleanup | Put in Release Gates / Pre-Release Cleanup with blocker status. |
| Detailed M11 class/weapon/item/skill `.tres` checklist | Put under content/data packs; link to GDD_03/GDD_04/GDD_05. |
| Maps 002-005 | Put under campaign content, probably Band 4/5 depending required systems. |
| Art/audio/polish placeholders | Keep in polish queue; do not mix with systems bands. |
| Full character sheet / More Info / minimap / richer forecast UI | Put in UI/UX queue, mostly Band 6 unless needed by v1 validation. |
| Public identity rename / legal | Keep as release gates; do not bury in feature bands. |

## Execution DoD

The rewrite is done when:

1. `GDD_10_Roadmap.md` has a Project Control Plane row for every active work
   item.
2. Every old GDD_10 open row is mapped, archived, or explicitly marked
   historical/superseded.
3. `GDD_00` navigation names the control plane as the build-start point.
4. `GDD_Feature_Index.md` points each feature to its tracker row.
5. `GDD_01`-`GDD_08` reflect the resolved register decisions at summary level.
6. `AGENT/Docs/INDEX.md` and `AGENT/Docs/REGISTERS.md` are regenerated.
7. `python3 AGENT/Docs/check_docs.py` passes.

## Questions Before Execution

No question blocks writing the plan. Before the rewrite itself, these owner
choices would help:

1. Should the active Project Control Plane live inside `GDD_10_Roadmap.md`
   as recommended, or should it be a separate `AGENT/Docs/plans/` manifest that
   `GDD_10` points to?
2. Should v1 include campaign sharing/importing? That decides whether campaign
   packaging stays Band 6 or moves later.
3. Should v1 include exactly one side activity? That decides whether
   `ActivityRegistry` / `ActivityRunner` moves from optional to Band 6.
4. Should old M8-M16 prose be archived aggressively after mapping, or kept as a
   historical appendix for one transition pass?
