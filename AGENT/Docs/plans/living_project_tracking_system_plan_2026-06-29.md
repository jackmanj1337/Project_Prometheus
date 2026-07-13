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

## Owner Decisions - 2026-06-29

These decisions update the original recommendation and remove the open questions
that blocked execution planning.

| Topic | Decision |
|---|---|
| Control-plane location | A separate control-plane home is acceptable, but only if it has a distinct job from `GDD_10_Roadmap.md`. Recommendation updated below: use a separate machine-auditable Project Control Plane manifest, while `GDD_10` becomes the human build guide and next-work narrative. |
| Campaign sharing/exporting | In v1. Campaign packaging/import/export is no longer a loose stretch item; it belongs on the v1 path after the campaign/save spine exists. |
| Side activities | Not needed for v1. `ActivityRegistry` / `ActivityRunner`, activity templates, and public scripting VM remain deferred unless a later owner decision changes v1 scope. |
| Scope of overhaul | This phase is not done until the whole active project documentation set uses one vocabulary, one organizational pattern, and one naming convention. Pretty consolidation is insufficient. |

## Recommendation

Do **not** merge every design into a single document or make
`GDD_10_Roadmap.md` carry all detail. That would recreate the problem: one long
file with stale status prose.

Use a **single control plane** instead:

1. `GDD_00` through `GDD_08` stay the design/rules contract.
2. A separate Project Control Plane manifest becomes the one row-per-work-item
   tracker and audit target.
3. `GDD_10_Roadmap.md` becomes the human build guide: band narrative, next-work
   queue, release/validation summaries, and links into the control plane.
4. `GDD_Feature_Index.md` becomes the feature lookup table.
5. `AGENT/Docs/REGISTERS.md` remains the generated decision-register catalog.
6. `AGENT/Docs/plans/` and `AGENT/Docs/design/` remain source docs, but they do
   not own schedule status unless a tracker row points to them.
7. The **Project Control Plane** ties all of those together with one row
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
| Project Control Plane manifest | Single row-per-work-item tracker: band, status, dependencies, source docs, GDD owner, tests, next action. | Become a prose build guide or duplicate long design text. |
| `GDD_10_Roadmap.md` | Human build guide: dependency-band narrative, next-build queue, validation/release summaries, and links to control-plane rows. | Duplicate the full control-plane table or carry old milestone prose as active schedule. |
| `GDD_Feature_Index.md` | Feature lookup: feature -> GDD owner -> tracker row -> registers/plans/tests/code. | Become a roadmap. |
| `AGENT/Docs/REGISTERS.md` | Generated catalog of open/resolved register decisions. | Replace the build guide. |
| `AGENT/Docs/INDEX.md` | Generated active-doc lookup. | Replace feature/work tracking. |
| `AGENT/Docs/plans/*` | Implementation plans, triage inputs, inventories, and migration plans. | Own active status without a tracker row. |
| `AGENT/Docs/design/*` | Design contracts and architecture decisions. | Own implementation sequencing. |
| `AGENT/Docs/playtests/*` | Playtest manifests, checklists, and validation queues. | Hide release blockers outside the control plane. |

## Project Control Plane Row Schema

Create the canonical tracker as
`AGENT/Docs/plans/project_control_plane_2026-06-29.md` during the rewrite. Keep
`GDD_10_Roadmap.md` as the build-guide narrative that links to control-plane
rows instead of duplicating the table. This gives the two docs distinct jobs:
the control plane is complete and audit-friendly; `GDD_10` is readable and
execution-focused.

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

1. Create `AGENT/Docs/plans/project_control_plane_2026-06-29.md`.
2. Seed it from the dependency bands:
   - Bands 1-5 as v1-core,
   - Band 6 as v1-lean/stretch, including campaign sharing/exporting,
   - Band 7 as optional after stable core,
   - Band 8 as post-v1/parked.
3. Add separate queues for:
   - validation/live-verify,
   - release gates,
   - pre-release cleanup,
   - content/data packs,
   - polish/art/audio.
4. Point each row to existing docs instead of copying detail.
5. Rewrite `GDD_10_Roadmap.md` as the human build guide that links to the
   control-plane rows.
6. Mark stale milestone sections as Historical or move them to archive once their
   active rows are represented.

Deliverables:
- `AGENT/Docs/plans/project_control_plane_2026-06-29.md`
- `GDD_10_Roadmap.md` rewritten as the build guide.

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

This must be stronger than prose. The rewrite should produce machine-checkable
artifacts and CI/pre-commit checks that make the new structure hard to bypass.

### Enforcement Artifacts

| Artifact | Purpose |
|---|---|
| `project_control_plane_2026-06-29.md` | Human-readable canonical tracker. Must use a strict table schema. |
| `project_control_plane_schema_2026-06-29.json` or equivalent Python schema in `check_docs.py` | Machine-readable row schema: required columns, allowed statuses, allowed bands, path fields, and tracker ID pattern. |
| `gdd10_active_work_coverage_matrix_2026-06-29.md` | Transition audit proving old `GDD_10` rows are mapped, archived, or superseded. |
| `doc_role_manifest_2026-06-29.json` or equivalent table | Active docs by role: GDD contract, build guide, control plane, feature index, register, implementation plan, design contract, playtest/validation, archive. |
| `project_vocabulary_manifest_2026-06-29.md` | Preferred terms, retired aliases, tracker prefixes, band names, and naming conventions. |
| `check_docs.py` checks | Durable enforcement in pre-commit and CI. |

The JSON files are optional if the checks can read Markdown reliably, but the
rules must be executable. Prefer structured sidecar files if Markdown parsing
becomes brittle.

### Checks To Add When Ratified

Extend `AGENT/Docs/check_docs.py` in the same commit that ratifies the
control-plane schema.

| Check | Fails when |
|---|---|
| Control-plane schema | A tracker row misses a required column, has an invalid status/band, or uses a malformed Track ID. |
| Track ID uniqueness | Two rows use the same Track ID. |
| Track ID reachability | `GDD_10` and `GDD_Feature_Index` reference a Track ID that does not exist. |
| Active work coverage | A non-Implemented / non-Historical active work item from the coverage matrix has no tracker row or accepted archive/supersession mapping. |
| Source path validity | A tracker row points to a missing GDD owner, register, plan, design doc, test, or playtest file. |
| Active doc ownership | An active plan/design doc is not referenced by a tracker row, feature-index row, generated-index exception, or archive/supersession marker. |
| Save-state discipline | A save-affecting tracker row has no F1 manifest reference and no explicit `no_save_guard`. |
| Registry discipline | An author-facing vocabulary row has no registry family reference and no explicit engine-only closed-list exception. |
| Role separation | `GDD_10` duplicates the full control-plane table, or the control-plane manifest contains long-form design prose. |
| Vocabulary bans | Retired aliases appear in active prose outside Historical/Superseded sections. |
| Required generated indexes | Adding/moving/retitling active docs without regenerating `INDEX.md` / `REGISTERS.md` fails. Existing check 18 continues to cover this. |

### Transition Tools

Build temporary scripts if manual auditing becomes error-prone:

1. `extract_gdd10_open_rows.py`: reads `GDD_10_Roadmap.md` and emits candidate
   coverage rows for open/deferred/validation/release-blocking bullets and
   checklist items.
2. `check_control_plane_links.py`: validates tracker IDs, paths, and back-links
   before the logic is folded into `check_docs.py`.
3. `find_untracked_active_docs.py`: lists active `AGENT/Docs/design` and
   `AGENT/Docs/plans` files that are not referenced from the control plane,
   feature index, or approved exception list.
4. `scan_retired_vocabulary.py`: searches active docs for retired aliases after
   the vocabulary manifest is ratified.

Temporary scripts can live under `AGENT/Docs/tools/` or be folded directly into
`check_docs.py`. Once stable, prefer one durable check path over multiple ad hoc
scripts.

DoD#2 note: these checks should land only when the control-plane schema is
ratified, not in this planning document.

### Phase 6 - Vocabulary / Naming Unification

Goal: finish the overhaul instead of leaving old names and organization patterns
in place.

Steps:

1. Build a vocabulary map from active docs:
   - preferred feature names,
   - retired aliases,
   - tracker ID prefixes,
   - band names,
   - source-doc role names.
2. Normalize active docs to the preferred terms.
3. Add a glossary section or guide if repeated terms need a durable home.
4. Move old names into historical notes only.
5. Add `check_docs.py` guards for mechanical vocabulary bans once the map is
   ratified.

## Build Guide Shape

Rewrite `GDD_10_Roadmap.md` into these sections:

1. **How To Use This Build Guide**
2. **Active Build Bands**
3. **Project Control Plane Link And Reading Rules**
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
| 6 | V1-lean/stretch | Campaign sharing/export/import, rescue/capture expansion, fog, destructibles, minimum supports, bonus EXP/training, map readability, input/gamepad. |
| 7 | Optional after stable core | Arena, battalion/gambit slice, stationary weapons, forging, PvP hotseat, advanced AI. |
| 8 | Post-v1 / parked | Side activities, ActivityRunner, activity templates, public builder, public scripting VM, online, perception/masking, hex, ML AI, Laguz, Awakening supplement. |

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
| Campaign sharing/exporting | Track as v1 Band 6 work tied to campaign packaging, import/export validation, and content-pack policy. |
| Side activities and ActivityRunner | Track as Band 8 parked unless owner later changes v1 scope. |
| Vocabulary drift and duplicate naming | Create a vocabulary map and add checks once naming is ratified. |

## Execution DoD

The rewrite is done when:

1. The Project Control Plane has a row for every active work
   item.
2. Every old GDD_10 open row is mapped, archived, or explicitly marked
   historical/superseded.
3. `GDD_00` navigation names the control plane and `GDD_10` build guide as the
   build-start points, with distinct jobs.
4. `GDD_Feature_Index.md` points each feature to its tracker row.
5. `GDD_01`-`GDD_08` reflect the resolved register decisions at summary level.
6. Active docs use one vocabulary, one tracker schema, one band model, and one
   naming convention.
7. Old aliases and old milestone labels are either removed from active prose or
   clearly marked Historical/Superseded.
8. `AGENT/Docs/INDEX.md` and `AGENT/Docs/REGISTERS.md` are regenerated.
9. `python3 AGENT/Docs/check_docs.py` passes.

## Questions Before Execution

No question blocks starting the coverage audit.

Remaining execution question:

1. Should old M8-M16 prose be archived aggressively after mapping, or kept as a
   historical appendix for one transition pass? Recommendation: keep it as a
   historical appendix for one transition pass, then archive once the control
   plane and feature index are proven usable.

## Pushback / Risks

The only pushback is on the definition of "done": this should not end at a
better-looking roadmap. The phase should not be accepted until active docs use
one vocabulary, one tracker schema, one band model, and one naming convention,
with checks added for the mechanical parts. Otherwise, old plans and new plans
will drift again under different names.
