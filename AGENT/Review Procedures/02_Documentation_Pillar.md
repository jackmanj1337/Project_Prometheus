# Pillar 2 — Documentation Review

> **Status:** Active — supersedes `AGENT/Docs/documentation_review_instructions.md`
> **Last verified:** 2026-06-14
> **Part of:** `AGENT/Review Procedures/00_Master_Review_Procedure.md`

Where Pillar 1 judges *code*, this judges the *docs* — the numbered GDD, the
decision/governance system, and the operational guides. The structural CI
(`check_docs.py`, DOC-011) already covers broken paths, missing headers, duplicate
roadmap IDs, and stale dates. **This review must not re-do the script's job** —
assume it is green (master §3) and go after what a script cannot judge: **truth,
governance compliance, and navigability.**

## 1. Mandate & non-goals

**In scope (the live set):** `AGENT/GDD/GDD_00`–`08`, `GDD_10_Roadmap.md`,
`GDD_Feature_Index.md`, `GDD_Adoption_Matrix.md`, `AGENT/Docs/decision_index.md`,
the governance + lifecycle docs, and the active guides. Historical/Superseded
files are out of scope unless a live doc still links one as authority.

**Out of scope:** code correctness (Pillar 1); whether tests/CI actually pass
(Pillar 4); the *review-procedure* docs themselves and process adherence
(Pillar 5).

## 2. Before you start

1. Confirm `python3 AGENT/Docs/check_docs.py` is green (from master §3). If it is
   red, those are the script's structural findings — list them as such, not yours.
2. Read `AGENT/Docs/documentation_governance_2026-06-13.md` (status vocab +
   section template) and `AGENT/Docs/documentation_lifecycle_2026-06-13.md`
   (per-file disposition). These are the rubric.

## 3. Procedure (exhaustive)

For each live doc, judge:

- **Truth / drift:** does the doc match shipped+tested behavior, the relevant
  `data/…` resource, and ratified decisions? Spot-check concrete claims (counts,
  file names, profile lists, formula constants) against `code/`, `scripts/`,
  `data/`.
- **Status correctness:** every status-bearing section carries one approved label
  (Implemented / Known issue / Target design / Historical / Superseded) +
  `Last verified`; no hidden status via prohibited words.
- **Template conformance:** major GDD sections follow the DOC-002 template
  (Summary / Specs / Known gaps / Anchors).
- **Single source of truth:** no rule fully duplicated across two live chapters
  (it will drift). One rule, one owner.
- **Navigability:** feature-index and anchors point at the right owner/file;
  cross-links resolve to the intended target.
- **Authority hygiene:** no live doc cites a Historical/Superseded/deleted file as
  authority.

## 4. Governance & lifecycle compliance checklist

Cite line numbers for any miss:
- [ ] Every status-bearing section: one approved label + `Last verified`.
- [ ] Prohibited words ("current"/"complete"/"canonical") absent as a *status*;
      flag split-status "current X / target Y" framing as a smell even if paired.
- [ ] Major GDD sections follow the DOC-002 template.
- [ ] `decision_index.md` statuses use one consistent vocabulary and case.
- [ ] No live doc links a Historical/Superseded/deleted file as authority.
- [ ] One rule has one owner (no full duplication across live chapters).

## 5. Coverage & automation gaps

Which governance rules are **stated but unenforced** by `check_docs.py`? The rules
no script checks are the ones that rot. Recommend a new check or explicitly accept
the gap. (Feed concrete ones to the rollup's PL#9 backlog.)

## 6. Severity guide (doc-specific)

Maps onto the master rubric (§5):
- **Critical** = a live doc contradicts a ratified decision or shipped behavior
  such that following it produces wrong work; or a retired file is cited as authority.
- **High** = doc↔code drift on an Implemented claim; an index/anchor pointing at
  the wrong owner or a non-existent file the script missed; a missing/wrong status
  label that hides whether work shipped.
- **Medium** = governance-vocabulary violation; a real gap a contributor hits; a
  rule documented in two places that can diverge.
- **Low** = stale phrasing, weak cross-linking, naming/format inconsistency.

## 7. Output report

**Path:** `AGENT/Docs/documentation_review_YYYY-MM-DD.md`. Sections: Executive
summary + 1–10 health score + one line confirming `check_docs.py` status; Issues
(Location / Problem / **Evidence** citing both the doc line and the contradicting
source / Root cause / Recommended fix incl. which status label it lands in);
Governance & lifecycle compliance (§4); Coverage & automation gaps (§5); ≥3
Positive observations; Prioritized action plan separating "fix the doc" from "fix
the checker"; **Delta vs previous review**. Tag cross-pillar items `[CROSS]`.

## 8. Constraints

- Document only — do not edit docs in the review pass.
- Every drift claim cites both the doc line and the contradicting source.
- State your spot-check sample; flag any unverified claim as an assumption.
- Respect PL#8: if a doc is wrong because behavior changed without the paired
  GDD+roadmap update, name that as the root cause.

## 9. Sub-agent dispatch brief

> You are the **Documentation** pillar of the full project audit. Follow
> `AGENT/Review Procedures/02_Documentation_Pillar.md` exactly. Review the live
> doc set at commit `<SHA>`. Assume `check_docs.py` is green (baseline:
> `<results>`); do not re-run its checks as findings. Document only. Compute
> deltas against `<prev documentation_review path>`. Produce the report at
> `AGENT/Docs/documentation_review_<DATE>.md` and return its path, your 1–10
> score, and your top 3 findings.
