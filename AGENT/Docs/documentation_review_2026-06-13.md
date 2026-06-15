# Documentation Review — 2026-06-13

**Scope:** live set — `AGENT/GDD/GDD_00`–`08`, `GDD_10_Roadmap.md`,
`GDD_Feature_Index.md`, `GDD_Adoption_Matrix.md`, `AGENT/Docs/decision_index.md`,
governance + lifecycle docs.
**Method:** `documentation_review_instructions.md`. Structural CI assumed and re-run.
**Reviewer:** Claude (per `code_review_instructions.txt` companion process).

> **Resolution (2026-06-13):** all findings applied in the same session. Issue 1 →
> project/corpus phrasing (DOC-013) across 13 status lines + 1 invalid label
> ("Not reviewed" → "Open decision"); Issue 2 → S-rank constants deduped to GDD_04;
> Issue 3 → `UnitData.gd:60` comment fixed; §4 → `check_docs.py` checks 7–8 added and
> passing. These are doc-governance fixes (no behavior change), so no PL#8 roadmap flip.

---

## 1. Executive Summary

**Documentation-health rating: 8 / 10.**

Post-consolidation the docs are in strong shape: a single explicit authority order,
a disciplined status vocabulary, a per-file lifecycle table, and a routing-only
feature index that resists turning into a second spec. The biggest remaining risk is
**self-enforcement drift** — the governance rules most prone to rot (the prohibited
status words, the approved-label set) are *stated* but **not** enforced by
`check_docs.py`, and the GDD already bends one of them. A few concrete rule constants
are stated in two chapters at once, which is where future balance edits will diverge.

`check_docs.py` (DOC-011): **PASS** — all 6 structural checks green.

---

## 2. Issues Found

### [Medium] "current" used as the de-facto status word in status-bearing lines
- **Location:** `GDD_02_Core_Mechanics.md:40,122,284,306,447,501`;
  `GDD_03_Units_Classes.md:70,156`; `GDD_04_Weapons_Items.md:188`; and the chapter
  headers `GDD_03:3`, etc.
- **Problem:** Governance prohibits the unqualified words "current", "complete",
  "canonical" in status-bearing sections (`GDD_00:42-43`,
  `documentation_governance_2026-06-13.md:13-16`) precisely because they hide whether
  behavior is shipped or aspirational. The split-status lines route around this with
  `Status: **Split** — current values **Implemented**; corpus values **Target
  design**`. The approved label (`Implemented`) is present, but "current" is doing the
  semantic work of naming today's behavior — the exact ambiguity the rule targets.
- **Evidence:** `GDD_02:40` `Status: **Split** — current values **Implemented**; corpus
  values **Target design** (RULE-010)`. Governance forbids the bare word; the doc uses
  it ~12× in `Status:` lines.
- **Root cause:** "Split status" was ratified (governance:30-44) without a worked
  example of how to phrase the two halves, so authors reached for "current" as the
  natural antonym of "corpus/target".
- **Recommended fix:** Either (a) amend governance to bless `current X / target Y` as
  the sanctioned split-status phrasing, or (b) reword to label-only:
  `Status: **Split** — project values **Implemented**; corpus values **Target
  design**`. Pick one and apply across the Split lines. Recommend (b) — "project" vs
  "corpus" is already the authority axis (DOC-001) and carries no time ambiguity.

### [Medium] S-rank bonus constants stated in two live chapters
- **Location:** `GDD_02_Core_Mechanics.md:322` and `GDD_04_Weapons_Items.md:195`.
- **Problem:** Both chapters state the literal constants `+10 Hit, +5 Crit, +1 Damage`.
  The feature index names **GDD_04 §S-Rank Weapon Bonus** as the rule owner, so GDD_02
  is duplicating an owned rule. A balance pass (RULE-004 explicitly anticipates one)
  that edits one chapter and not the other produces a silent contradiction the CI
  cannot catch.
- **Evidence:** `GDD_04:195` `**Bonus (project extension):** +10 Hit, +5 Crit, +1
  Damage`; `GDD_02:322` restates the same triple under the modifier-pipeline section.
- **Root cause:** GDD_02 owns the *pipeline order* (`…→ S-rank bonus → clamps`,
  line 172) and inlined the values for readability rather than referencing the owner.
- **Recommended fix:** In GDD_02:322 replace the constants with a pointer:
  "applies the S-rank bonus (values owned by GDD_04 §S-Rank Weapon Bonus)". Keep the
  numbers in exactly one place (GDD_04).

### [Low] `UnitData.ai_profile` doc-comment contradicts shipped behavior
- **Location:** `scripts/resources/UnitData.gd:60`.
- **Problem:** The field's canonical comment reads `"basic"|"passive" for MVP; future:
  "territorial"|"guard_tile"|"healer"|"boss"` — listing `healer` as *future*. But
  `healer` is implemented and validated: `EnemyAI.gd:58`,
  `DataManager.gd:16 _VALID_AI_PROFILES := ["basic","passive","healer"]`,
  `test_enemy_ai.gd`, and the feature index lists AI "basic profiles Implemented".
- **Evidence:** doc-comment says future; `_VALID_AI_PROFILES` and the GDD say shipped.
- **Root cause:** profile list grew (healer landed) without updating the field comment —
  a PL#8-style miss at the code-comment level.
- **Recommended fix:** Move `healer` out of the "future" list in the comment:
  `"basic"|"passive"|"healer"; future: "territorial"|"guard_tile"|"boss"`.

---

## 3. Governance & Lifecycle Compliance

- [x] Every status-bearing section carries one approved label + `Last verified` — **pass**
      (sampled GDD_00–04; CI check 3 confirms headers).
- [ ] Prohibited words absent from status lines — **fail** (Issue 1; "current" in
      ~12 `Status:` lines).
- [x] DOC-002 section template (Summary/Specs/Known gaps/Anchors) — **pass** on sampled
      sections; not exhaustively audited across all 80+ sections (assumption flagged).
- [x] `decision_index.md` statuses consistent — **pass**. The Status column uses
      `Answered` / `Applied` / `Applied (governance)` / `Applied (Target design)`, which
      is the DOC-009 workflow, not an inconsistency. (Mixed-case `OPEN`/`open` tokens
      elsewhere in the file are ID prefixes and prose, not statuses.)
- [x] No live doc links a deleted/Historical file as authority — **pass** (CI check 1;
      GDD_00:76-89 cites the retired files only as deletion notes, exempted correctly).
- [ ] One rule, one owner — **fail** (Issue 2; S-rank constants in GDD_02 and GDD_04).

**Spot-checks verified accurate** (doc claim ↔ source):
- "6 starter classes (Cavalier, Mercenary, Archer, Mage, Cleric, Knight)" (`GDD_00:133`)
  — all 6 `.tres` present in `data/classes/`; the extra 19 are corpus/promoted classes,
  consistent with the AWR-2 Target framing. ✓
- AI profiles `basic`/`passive`/`healer` (`GDD_08`, feature index) — match
  `EnemyAI.gd:57-59` + `DataManager.gd:16`. ✓
- "8 registered maps" (`GDD_00:144`) — 8 `data/maps/map_*` directories present. ✓
- "retire `s_rank_mastery`" Target (RULE-002, `GDD_04:188`) — `s_rank_mastery` still
  present in `SkillHandler.gd`/`Unit.gd`, so the Target is real and not yet done. ✓
- `CampaignRules` stub (feature index, GDD_01) — `scripts/resources/CampaignRules.gd`
  exists. ✓

---

## 4. Coverage & Automation Gaps (DOC-011)

`check_docs.py` enforces *structure* (paths, headers, dup roadmap headings, stale
dates) but not *vocabulary* — the two cheapest, highest-rot governance rules go
unchecked, which is exactly why Issue 1 slipped in:

1. **Prohibited-word check (new check 7).** Flag `current|complete|canonical` appearing
   in a status-bearing line (a line containing `**Status:` or `Status:` + `Last
   verified` block). ~15 lines of regex; would have caught Issue 1.
2. **Approved-label check (new check 8).** Assert every `Status:` line contains at least
   one label from the governance set (`Implemented|Pending validation|Known issue|
   Target design|Planned|Deferred|Open decision|Historical|Superseded|Split|Reference|
   Active`). Catches typos and unlabeled statuses the header check (3) does not.

Both are pure-text checks needing no git/subprocess and fit the existing `_fail`
harness. Accept-the-gap is the alternative, but these are the rules a human reviewer
should not have to babysit.

---

## 5. Positive Observations

1. **Explicit authority order (`GDD_00:23-36`).** Ratified-decision → numbered GDD →
   code → roadmap → corpus, with the superseded D-C direction called out inline. This
   resolves the single hardest question in a doc set ("when two docs disagree, who
   wins?") unambiguously.
2. **Split-status discipline.** Carrying an `Implemented` line *and* a `Target design`
   line through the corpus migration (governance:30-44) is the right model for a
   codebase mid-refactor — it stops "is this shipped?" from being guesswork.
3. **Routing-only feature index.** `GDD_Feature_Index.md` explicitly refuses to be a
   second spec ("not a coverage claim", "routing table"), which is the failure mode
   most feature indices fall into. Owner + roadmap + anchors per feature is exactly the
   navigation a contributor needs.
4. **Lifecycle table with atomic link-repair gate** (`documentation_lifecycle`) — no
   move orphans a live link, and `check_docs.py` backs it with a banned-path check.

---

## 6. Prioritized Action Plan

**Fix the docs:**
1. Resolve Issue 1 — choose split-status phrasing (recommend "project"/"corpus") and
   reword the ~12 `Status:` lines. Low effort, removes a standing governance violation.
2. Resolve Issue 2 — replace S-rank constants in GDD_02:322 with a pointer to GDD_04.
   Trivial; removes a future drift point.
3. Resolve Issue 3 — one-line fix to `UnitData.gd:60` comment.

**Fix the checker (so the above don't recur):**
4. Add check 7 (prohibited words) and check 8 (approved label) to `check_docs.py`.
   After landing, run it to confirm it now flags any residual Issue-1 lines, then fix
   them in the same pass — closing the loop between rule, doc, and CI.

> Per PL#8, each doc edit above is a behavior/spec change to a GDD section; pair it with
> the matching `GDD_10_Roadmap.md` status flip in the same commit. The checker change
> (4) is the DOC-011 script and does not touch a GDD section.
