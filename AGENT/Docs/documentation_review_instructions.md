# Documentation Review Instructions

> **Status: Superseded (2026-06-14)** by `AGENT/Review Procedures/02_Documentation_Pillar.md`,
> which folds this content in as Pillar 2 of the full project audit
> (`AGENT/Review Procedures/00_Master_Review_Procedure.md`). Kept for provenance
> only. Do not use for new reviews.

Companion to `code_review_instructions.txt`. Where the code review judges *code*,
this judges the *docs* — the numbered GDD, the decision/governance system, and the
operational guides. The structural CI (`check_docs.py`, DOC-011) already covers broken
paths, missing headers, duplicate roadmap IDs, and stale dates. **A review must not
re-do the script's job** — assume it is green and go after what a script cannot judge:
truth, governance compliance, and navigability.

## Scope

Default: the live set — `AGENT/GDD/GDD_00`–`08`, `GDD_10_Roadmap.md`,
`GDD_Feature_Index.md`, `GDD_Adoption_Matrix.md`, `AGENT/Docs/decision_index.md`, the
governance + lifecycle docs, and the active guides. (Or specify a subset / a single
chapter / a diff.) Historical and Superseded files are out of scope unless a live doc
still links to one as authority.

## Before you start

1. Run `python3 AGENT/Docs/check_docs.py` and confirm it passes. If it fails, those are
   structural defects — list them, but they are the script's findings, not yours.
2. Read `documentation_governance_2026-06-13.md` (status vocab + section template) and
   `documentation_lifecycle_2026-06-13.md` (per-file disposition). These are the rubric.

## Review document structure

Save as a dated markdown file: `AGENT/Docs/documentation_review_YYYY-MM-DD.md`.

### 1. Executive Summary
- Overall documentation-health rating (1–10).
- 2–3 sentences: biggest strengths and the single most important concern.
- One line confirming `check_docs.py` status (pass/fail).

### 2. Issues Found
For each issue:

**[SEVERITY: Critical / High / Medium / Low]**
- **Location:** `file.md:line` (or a section heading).
- **Problem:** what is wrong and why it misleads a reader or contributor.
- **Evidence:** the doc quote *and* the code/data/decision it contradicts
  (`script.gd:line`, a `data/…` resource, or a decision ID). A drift finding without
  a cited counter-source is just an opinion — cite both sides.
- **Root cause:** why it likely drifted (e.g. behavior changed without the paired
  GDD+roadmap update PL#8 requires).
- **Recommended fix:** the concrete edit, plus which status label/section it lands in.

Severity guide (doc-specific):
- **Critical** = a live doc states a rule that contradicts a *ratified decision* or
  shipped+tested behavior, such that following the doc produces wrong work; or a
  retired/deleted file is still cited as authority.
- **High** = doc↔code drift on an Implemented claim (doc says X, code does Y); a
  feature-index/anchor pointing at the wrong owner or a non-existent file the script
  missed; a missing or wrong status label that hides whether work is shipped.
- **Medium** = governance-vocabulary violation (prohibited word in a status section,
  off-template section, inconsistent decision-status labels); a real gap a contributor
  would hit; a rule documented in two places that can drift apart (single-source-of-
  truth violation).
- **Low** = stale phrasing, weak cross-linking, naming/format inconsistency.

### 3. Governance & Lifecycle Compliance
A short checklist pass, citing line numbers for any miss:
- [ ] Every status-bearing section uses one approved label + `Last verified`.
- [ ] The prohibited words ("current", "complete", "canonical") do not appear *as a
      status* in a status-bearing line (split-status "current X / target Y" framing is
      a smell to flag even where technically paired with a label).
- [ ] Major GDD sections follow the DOC-002 template (Summary / Specs / Known gaps / Anchors).
- [ ] `decision_index.md` statuses use one consistent vocabulary and case.
- [ ] No live doc links a Historical/Superseded/deleted file as authority.
- [ ] One rule has one owner (no rule fully duplicated across two live chapters).

### 4. Coverage & Automation Gaps
Which governance rules are **stated but unenforced** by `check_docs.py`? The rules most
likely to rot are the ones no script checks. Recommend either a new check or accept the
gap explicitly.

### 5. Positive Observations
At least 3 things done well and worth preserving.

### 6. Prioritized Action Plan
Numbered, ordered by impact vs. effort. Separate "fix the doc" from "fix the checker".

## Constraints
- **Document only — do not edit the docs** in the review pass (the review is the
  deliverable). A follow-up commit applies fixes.
- Every drift claim cites both the doc line and the contradicting source. Spot-check
  concrete, falsifiable claims (counts, file names, profile lists, formula constants)
  against `code/`, `scripts/`, `data/` — not vibes.
- State your spot-check sample; flag any claim you did **not** verify as an assumption.
- Respect PL#8: if a doc is wrong because behavior changed without the paired update,
  say so — that is the root cause to name.
