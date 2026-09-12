---
Role: topic
Type: governance
Status: Implemented
Last verified: 2026-08-21
---

# Documentation Lifecycle and Link-Migration Policy

**Date opened:** 2026-06-13
**Status:** Implemented — present lifecycle policy for the typed documentation tree.
**Layout owner:**
[`documentation_system_design_2026-06-23.md`](documentation_system_design_2026-06-23.md)
**Retrieval manifests:** [`../INDEX.md`](../INDEX.md) and
[`../REGISTERS.md`](../REGISTERS.md)

## Purpose

Every live document has one type, one lifecycle state, and one discoverable home. A
move, rename, archive, or supersession must repair live inbound links in the same
commit. Historical evidence remains available without competing with live authority.

This file owns lifecycle and link-migration procedure. The layout and type taxonomy
are ratified by DSR-1 through DSR-5 in the layout owner above. Documentation status
vocabulary remains owned by
[`documentation_governance_2026-06-13.md`](documentation_governance_2026-06-13.md).

## Live homes and retrieval

`AGENT/Docs/` is grouped by type:

| Home | Content |
|---|---|
| `guides/` | Active operational runbooks |
| `governance/` | Documentation-system and release-governance rules |
| `decisions/` | Decision records and `decision_index.md` |
| `registers/` | Open-question and ruling registers |
| `design/` | Design and research documents |
| `plans/` | Active implementation plans and handoffs |
| `playtests/` | Build notes, checklists, returns, findings, and triage |
| `archive/` | Historical or superseded evidence, grouped by subtype |

Tooling stays at the `AGENT/Docs/` root. `INDEX.md` is the entry point for active
documents, `REGISTERS.md` resolves `[XXX-n]` families, and
`decisions/decision_index.md` resolves governance and project decision IDs. The two
generated manifests must be regenerated with `python3 AGENT/Docs/gen_docs_index.py`
after a document is added, moved, retitled, retyped, or changes lifecycle metadata.

## Document role vocabulary

*Moved here 2026-08-23 from `../plans/doc_role_manifest_2026-06-29.md` when that
manifest was retired. The manifest's Named Documents catalogue and Enforcement Hooks
table were not carried over: `Role:` front matter (check `[48]`) and `check_docs.py`
itself are the live owners of what those two tables restated.*

1. A document has one primary role.
2. A document can link to other roles, but it must not silently take over their
   job.
3. Work status lives in the Project Control Plane unless a GDD chapter carries
   the short design-section status required by governance.
4. Generated indexes are navigation only and are never hand-edited.
5. Resolved registers stay decision evidence. Do not archive them just because
   their open questions are resolved.
6. Session notes are a frozen dated corpus. The retired practice does not own active plans.
7. Every live document declares `Role: topic` (subject-sorted and maintained) or
   `Role: dated` (time-sorted input/evidence) in front matter. Archive paths and the frozen
   session-note tree declare the dated role without rewriting historical files.

### Role table

| Role ID | Allowed paths | Owns | Must not own | Control-plane rule |
|---|---|---|---|---|
| `authority_index` | `AGENT/GDD/GDD_00_Overview.md` | Authority model, release definition, navigation entry points. | Feature detail, work queues, register deliberation. | May link to tracker rows but does not duplicate them. |
| `design_contract` | Numbered `AGENT/GDD/GDD_01*.md` through `AGENT/GDD/GDD_08_Enemy_AI.md` contracts, including approved GDD 01/07 companions | Short rule/design contracts by domain. | Long deliberation history or full build schedule. | Every active feature should point to one or more GDD owners. |
| `build_guide` | `AGENT/GDD/GDD_10_Roadmap.md` | Human build guide, dependency-band narrative, next-work queue, release/validation summaries. | Full control-plane table, stale milestone checklist detail. | Links to Track IDs; does not own row schema. |
| `control_plane` | `AGENT/Docs/plans/project_control_plane_2026-06-29.md` | Row-per-work-item tracker, dependencies, owners, sources, tests, next actions. | Long-form design explanation, historical session narrative. | Source for Track IDs and tracker schema. |
| `feature_index` | `AGENT/GDD/GDD_Feature_Index.md` | Feature lookup from feature name to GDD owner, Track ID, decisions, plans, tests, and code/data anchors. | Roadmap sequencing or deliberation. | References Track IDs after wiring pass. |
| `generated_index` | `AGENT/Docs/INDEX.md`, `AGENT/Docs/REGISTERS.md` | Generated navigation. | Hand-authored status, schedule, or exceptions. | Must be regenerated after active-doc add/move/retitle/header changes. |
| `decision_index` | `AGENT/Docs/decisions/decision_index.md` | Governance and decision ID lookup. | Feature scheduling. | Referenced by GDD and tracker rows when decision IDs matter. |
| `decision_register` | `AGENT/Docs/registers/*.md` | Open-question answers, resolved design decisions, rationale, and cross-links. | Active build order after a tracker row exists. | Register rows supply `Decision source` values. |
| `implementation_plan` | `AGENT/Docs/plans/*.md` except the control plane and generated transition artifacts | Build plans, inventories, triage inputs, migration plans. | Owning live status without a tracker row. | Active plans need a Track ID or explicit exception. |
| `design_source` | `AGENT/Docs/design/*.md` | Architecture contracts, design visions, research, and source evidence. | Schedule ownership. | Active design docs need a Track ID, feature-index row, or source exception. |
| `playtest_validation` | `AGENT/Docs/playtests/*.md` | Build manifests, playtest checklists, validation queues, and returned-test evidence. | Hiding release blockers outside the tracker. | Blocking validation needs a `VAL-*` or `REL-*` row. |
| `operational_guide` | `AGENT/Docs/guides/*.md` | How-to runbooks for setup, testing, map authoring, and tools. | Design authority or work status. | Linked from tracker rows only when needed for execution. |
| `governance` | `AGENT/Docs/governance/*.md` | Documentation rules, lifecycle, reviews, and system design. | Feature-specific implementation schedule. | New mechanical rules require `check_docs.py` coverage in the same change. |
| `review_procedure` | `AGENT/Review Procedures/*.md`, `AGENT/Code Reviews/*.md` | Review methods and review outputs. | Active roadmap ownership. | Findings that create work must get tracker rows. |
| `session_note` | frozen `AGENT/Session Notes/*.md`, `AGENT/Session Notes/INDEX.md` | Historical session evidence only. | Active source of truth for design or schedule; new files. | The practice is retired; useful content migrates by stable ID before phase-4 deletion. |
| `archive` | `AGENT/Docs/archive/**` | Historical or superseded evidence. | Active work ownership. | Files need the required archive marker in the first 10 lines. |

## Lifecycle operations

- **Add:** choose the correct typed home and declare valid front matter when the file
  uses it. Add every open task, handoff, or plan to `coordination/tasks.json`; a local
  document is not the cross-branch work registry.
- **Rewrite in place:** keep the path when the authority scope is unchanged. Update
  status and verification metadata with the content.
- **Move or rename:** use `git mv`; repair every live inbound link and regenerate the
  manifests in the same commit. Historical prose may retain an old path when it is
  clearly evidence rather than an instruction.
- **Supersede:** move the old document under the matching `archive/` subtype when
  practical and add a `> **Superseded** by [...]` marker in its first ten lines.
- **Archive:** preserve dated evidence under `archive/` with a `Historical`,
  `ARCHIVED`, or `Superseded` marker in its first ten lines. Do not delete provenance
  merely because its action is finished.
- **Delete:** reserve deletion for duplicate or invalid artifacts whose useful history
  remains recoverable in Git. Repair live links atomically.

## Authority and link rules

1. Live GDD contracts and governance documents must not cite archived material as
   binding instructions.
2. A superseded document points to its successor; the successor does not need to keep
   the old document in its operational reading path.
3. Moves and renames are incomplete until live links, checker path lists, and generated
   manifests agree with the new location.
4. `AGENT/Docs/` is documentation, not a `res://` asset tree. Runtime assets belong
   outside it.
5. Session notes and code reviews are historical evidence. Their indexes provide
   retrieval; they are not current rules or task ownership.

## Mechanical gates

`python3 AGENT/Docs/check_docs.py` enforces the parts of this policy that are
mechanically decidable: broken and retired paths, generated-manifest parity, archive
markers and supersession targets, type vocabulary, register cataloguing, and this
authority's typed-home links. Semantic authority still requires review.

## Completed migration

The June 2026 flattened-tree migration that originally occupied this file is finished.
The numbered GDD consolidation, typed `AGENT/Docs/` move, generated manifests, and
archive-marker checks have landed. Historical migration detail remains recoverable in
Git; it is not retained here as a second, obsolete map of the live tree.
