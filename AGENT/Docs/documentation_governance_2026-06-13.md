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
