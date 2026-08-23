---
Role: topic
---

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

## Ratified Is Not Frozen (DOC-014, ratified 2026-08-13)

**Every descriptor asserting that something is decided means *decided on the evidence available
at the time*. None of them means permanent.** Any may be reopened and thrown out when a
sufficiently good reason is discovered — and when one is, **take it**. A decision that turns out
to have standardized nothing, duplicated a mechanism that already existed, or hardened a bespoke
structure where a shared one belongs is not made correct by having been ratified.

**This rule is about the meaning, not the word.** These docs use eleven different descriptors for
the same idea, and the rule binds all of them equally — no register escapes it by having picked a
different label. Counts are live occurrences outside `archive/` as of 2026-08-13:

| Descriptor | Uses | Typical home |
|---|---|---|
| `RESOLVED` | 1756 | register items |
| `Ratified` | 406 | decision index, `EPUX`-style walks |
| `Accepted` | 292 | design-doc headers, owner rulings |
| `CLOSED` | 270 | whole registers |
| `firmed` | 171 | cluster walks |
| `locked` | 163 | schema locks (F1) |
| `confirmed` | 152 | owner confirmations *(also means test-verified — see below)* |
| `decided` | 143 | prose rulings |
| `settled` | 136 | prose rulings |
| `Approved` | 95 | `DLUX`-style owner rulings |
| `Adopted` | 42 | owner walks |

`Target design` from the status table above is also in scope — it is *"approved future behavior,"*
which is a decision.

**Out of scope, because they assert observation rather than a decision:** `Implemented`,
`Pending validation`, and `Known issue` are build/verification states. `confirmed` and `locked`
appear in both senses — "confirmed as default" is a decision and reopenable; "confirmed
modal-input defect" is an observation and is not a decision to reopen. Read the sense, not the
token. Reopening a decision that has already been *implemented* is permitted by this rule; the
implementation cost is an input to whether the reason is sufficient, never a veto on considering
it.

This does **not** weaken the precedence-check rule, and the two must be read together, because
they draw a line between two things that look identical from the outside:

| | What it is | Verdict |
|---|---|---|
| **Re-litigating from ignorance** | A packet argues against ratified text because nobody read the ratified text. The author does not know they are reopening anything. | **Prohibited.** This is what the precedence check exists to catch — see `TSV` (2026-08-13), which argued against ratified `EPUX` decisions three times and lost all three. |
| **Reopening from discovery** | The precedence check ran, the ratified position is understood and stated, and a genuinely better structure is found anyway. | **Encouraged.** Do it, and record what is being reopened and why. |

**The discriminator is whether the precedence check came first.** You may only reopen what you
have demonstrably read. A reopening must name the decision, quote what it ruled, and state the
reason that outranks it; "I would have done it differently" is not such a reason, while "these
four mechanisms differ only in policy and share every hard part" is.

**Worked example — the one that produced this rule.** `DRC-33` had the map-end orchestrator
borrowing transaction primitives *from* the dialogue runner; `DLUX` §7.3 ruled the general action
journal owns atomicity. The precedence diff caught the inversion, and the fix under discussion was
narrow: name the journal, amend one sentence. Examining it properly showed something larger —
**four** ratified staging/rollback mechanisms (`MapLedger`, `EPUX-24`'s transaction core,
`EPUX-06`'s activity snapshot, and the journal) differing along axes that are *policy* (retention,
charging, who may trigger) while sharing every part that is *hard* (overlay reads, commit
ordering, RNG determinism, save participation). Four implementations of the hard part is where
bugs live. The result was two named primitives — staged transaction and snapshot — with policy
layered on top, which reopened none of the four rulings and unified all of them.

**Corollary — schedule the search, do not only wait for it.** Reopenings of this kind surfaced by
accident, in the middle of a walk about something else. A deliberate optimization pass runs after
the current planning programme completes, looking for exactly this shape: bespoke structures that
should be standardized, and repeated mechanisms that should be one. Tracked as
`OPTIMIZATION-PASS-RATIFIED-DECISIONS-2026-08-13`. Findings from it are taken, not filed.

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

### Mechanical enforcement rollout (2026-07-15)

`check_docs.py` requires every status-bearing section in the live split GDD_01 and
GDD_07 companions to carry a `Last verified` marker inside that same Markdown
section. It strictly checks the full DOC-002 heading shape for the campaign/save
data and runtime companion sections closed by the campaign follow-up. Other legacy
non-catalog chapters remain a visible migration backlog; the checker does not
pretend they were silently restructured. GDD_06/07/08 retain the explicit
DOC-002a catalogue exception and are not forced into per-entry Summary/Specs pairs.

The Feature Index uses its normalized Feature name as the stable row identity and
Track IDs as delivery ownership. Duplicate Feature identities or an exact duplicate
status/GDD-owner/Track-ID signature fail the checker, preventing a copied ownership
row from silently diverging.

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

**Decision lifecycle and delivery workflow (ratified 2026-07-15):**
The decision index tracks two independent columns. They must not be collapsed into
composite values or inferred from each other:

| Column | Allowed values | Meaning |
| --- | --- | --- |
| **Decision state** | `Open`, `Ratified`, `Superseded`, `Historical` | Whether the authoritative owner has accepted the decision and whether it still governs. An answer that has not reached that owner remains `Open`; there is no `Answered` state. |
| **Delivery status** | `Not scheduled`, `Target design`, `Planned`, `In implementation`, `Implemented`, `Pending validation`, `Deferred`, `Not applicable` | How far the tracked implementation or documentation slice has progressed. This does not change whether the decision itself is ratified. |

**Workflow (open → ratified → delivered):**

1. Record the open item in its home file and index it as `Open`.
2. After the authoritative owner accepts a dated resolution, set its decision
   state to `Ratified` and choose the honest delivery status for the tracked slice.
3. Update delivery status as code/GDD/roadmap work advances, linking the evidence
   in the row notes. Partially delivered work is not `Implemented`.
4. Set replaced decisions to `Superseded` and link both directions. Use
   `Historical` for deprecated aliases or provenance-only records.

`check_docs.py` enforces the exact headers and both vocabularies in the index.
