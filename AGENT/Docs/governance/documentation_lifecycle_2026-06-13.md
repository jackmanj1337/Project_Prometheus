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
