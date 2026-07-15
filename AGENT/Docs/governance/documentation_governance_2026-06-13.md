# Documentation Governance Standards

**Date opened:** 2026-06-13
**Status:** Active - ratified governance for the documentation consolidation
**Related:** `documentation_consolidation_decisions_2026-06-12.md`

This file holds the ratified governance outputs of the consolidation. The numbered
GDD and the decision system must follow these standards. Sections are added here
as the matching DOC decision is resolved.

## Status Vocabulary (DOC-003, ratified 2026-06-13)

Status-bearing sections MUST use one of the labels below plus a dated marker
(`Last verified: YYYY-MM-DD`). The unqualified words "current," "complete," and
"canonical" are PROHIBITED in any status-bearing section, because they hide
whether behavior is shipped, planned, or merely aspirational.

| Label | Means | Example |
| --- | --- | --- |
| **Implemented** | In code and covered by passing tests. | "Pair Up pass 1 stat bonuses - Implemented" |
| **Pending validation** | Coded but not yet verified by test or playtest. | "Two-RN hit model - Pending validation" |
| **Known issue** | Implemented but with a confirmed defect. | "Combat preview render - Known issue (2026-06-10)" |
| **Target design** | Approved future behavior, not yet built. | "Corpus combat formulas - Target design" |
| **Planned** | Scheduled with a roadmap owner; design not finalized. | "Light/Dark magic class lines - Planned (roadmap ID)" |
| **Deferred** | Explicitly postponed, not scheduled. | "Marriage/child units - Deferred (post-1.0)" |
| **Open decision** | Blocked awaiting a decision. | "Terrain ID mappings - Open decision" |
| **Historical** | Past record kept for provenance, non-authoritative. | "GDD_09 checklist - Historical" |
| **Superseded** | Replaced by a newer decision/design. | "Single-roll hit RNG - Superseded by RULE-001" |

### Split status

A single feature MAY carry two statuses at once during the migration period:
an `Implemented` line for behavior that ships today and a `Target design` line
for the corpus-derived behavior being migrated to. Example:

```
## Combat Formulas
Status: Implemented (project formulas, v0.1.4)
Target design: corpus formulas - Target design (see SET-001)
Last verified: 2026-06-13
```

This directly supports DOC-002's summary+spec layout and RULE-010's
"show both terrain tables until migration" direction.

### Split-status phrasing (DOC-013, ratified 2026-06-13)

When a split-status line names the two halves, the "ships today" half is labelled
**project** and the migration target **corpus** (or the specific target's name) — e.g.
`Status: **Split** — project values **Implemented**; corpus values **Target design**`.
The word **current** is NOT used for this purpose: it is one of the three prohibited
status words (DOC-003), and "project vs corpus" already names the real axis (DOC-001
authority boundary) without the shipped/aspirational ambiguity "current" hides.

**Enforcement:** `check_docs.py` checks 7 (prohibited status words) and 8 (approved
label present) enforce this on the numbered chapters GDD_00–08. The GDD_10 roadmap and
the indices are out of scope — they use their own tracker vocabulary ("COMPLETE",
"Stub created", "Seed").

## GDD Section Template (DOC-002, ratified 2026-06-13)

Every major GDD feature section uses this template. DOC-002's direction: a brief
**Summary** of what the feature does, then a larger **Specs** body, plus a dated
status marker. Fields:

```
## <Feature>
Status: <label>            # split status allowed (Implemented + Target design)
Last verified: YYYY-MM-DD

### Summary
One short paragraph: what this feature does, in player/system terms.

### Specs
The full detail: rules, formulas, tables, edge cases. This is the larger body.
Use Implemented / Target design subsections when current and target differ.

### Known gaps
Open issues, pending validation, or deferred parts (link decision IDs).

### Anchors
Code/data: <main scripts/resources>
Tests: <suite names>
Roadmap: <milestone/backlog ID>
Decisions: <DOC-/RULE-/AWR- IDs>
Reference: <corpus/handbook section, if any>
```

`Status` and `Last verified` are mandatory. `Summary` and `Specs` are mandatory.
`Known gaps` and `Anchors` are required when they apply (almost always).

### Catalog-section variant (DOC-002a, ratified 2026-06-14)

Some chapters are **catalogs** — many small, uniform entries (terrain tiles, UI
screens, AI behaviours) rather than a few large feature systems. GDD_06 (Maps/
Objectives), GDD_07 (UI/UX), and GDD_08 (Enemy AI) are catalogs. For these, the
per-entry `### Summary`/`### Specs` split is noise: a row in a table *is* the spec.

A catalog chapter is compliant when it: (1) carries the chapter-level `Status` +
`Last verified` header; (2) opens with a chapter `### Summary`; (3) presents its
entries as a table or a consistent per-entry block; and (4) keeps a chapter-level
`### Known gaps` and `### Anchors`. The per-entry Summary/Specs split is **not**
required. This is a blessed deviation, not a gap — flagged by the 2026-06-14
documentation audit (Pillar 2) and chosen over forcing the feature template onto
catalog content.

## Decision-Record Schema & ID Namespace (DOC-009, ratified 2026-06-13)

**Structure:** dated decision-record files plus a central index.

- **Index:** `AGENT/Docs/decisions/decision_index.md` — one row per decision ID with status
  and a link to its home. Loaded when navigating decisions.
- **Record files:** dated `AGENT/Docs/decision_record_YYYY-MM-DD_<slug>.md` for
  decisions made in a session. The consolidation register
  (`documentation_consolidation_decisions_2026-06-12.md`) remains the home for
  the `DOC-`, `RULE-`, and `SET-` series.

**Globally unique ID format:** `PREFIX-NNN`. Each prefix is unique and registered
in the index. Active prefixes:

| Prefix | Scope |
|--------|-------|
| `DOC-` | Documentation-governance decisions |
| `RULE-` | Rules / migration decisions |
| `SET-` | Settled owner directions |
| `OPEN-` | June-reference open questions (now resolved; kept as aliases) |
| `RNG-` | RNG/determinism contract decisions |
| `AWR-` | Awakening-refactor roadmap milestones |

Legacy short forms (`D1`, `A1`, `Decision 1`, `D-A`…`D-E`) are **deprecated
aliases**; the index maps each to its canonical record. New ad-hoc decisions take
a dated record file and a new registered prefix if they don't fit an existing one.

**Workflow (answered → applied):**

1. Answer the item in its home file with a dated resolution.
2. Add/update its row in `decision_index.md` (status, links, supersedes).
3. When the decision is reflected in code/GDD/roadmap, mark it `Applied` and link
   the resulting GDD section or commit.
4. Supersession is recorded as a link both ways (e.g. D-C → superseded by DOC-001).
