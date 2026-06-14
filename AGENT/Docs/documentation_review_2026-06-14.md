# Documentation Review — 2026-06-14

**Pillar:** 2 (Documentation) of the full project audit.
**Procedure:** `AGENT/Review Procedures/02_Documentation_Pillar.md` (Active; supersedes
`documentation_review_instructions.md`).
**Snapshot:** branch `awakening-compatability-refactor`, commit `e924bb4`.
Working tree dirty — 3 untracked files unrelated to the doc set
(`AGENT/Docs/950MERC Promotion.png.import`, `scripts/resources/CampaignRules.gd.uid`,
`scripts/tests/test_unit_inventory_refs.gd.uid`). [CROSS — Pillar 3/4: untracked `.uid`
sidecars, PL#9 enforcement candidate in master §10.]
**Scope:** live set — `GDD_00`–`08`, `GDD_10_Roadmap.md`, `GDD_Feature_Index.md`,
`GDD_Adoption_Matrix.md`, `decision_index.md`, governance + lifecycle docs, active guides,
`README.md`.
**Method:** truth/drift/governance/navigability judgment only — `check_docs.py`'s
structural job is assumed green and not re-reported.

---

## 1. Executive Summary

**Documentation-health rating: 8 / 10** (unchanged from 2026-06-13).

The doc set remains in strong post-consolidation shape: explicit authority order, a
disciplined and now machine-enforced status vocabulary, a routing-only feature index, and
a per-file lifecycle table. All three findings from the 2026-06-13 review are confirmed
**fixed** (see Delta, §7). The score holds rather than rises because this pass surfaced one
new **High** doc↔code drift on a ratified decision (OPEN-7 fort heal) and confirmed — with
evidence the prior review only flagged as an assumption — that the DOC-002 section template
is **not uniformly applied** across the GDD (GDD_06/07/08 diverge), and that this rule is
unenforced by the checker. The biggest standing risk is the same as last time: governance
rules a script *can* check that it still does not (template conformance; decision-index
vocabulary).

`check_docs.py` (DOC-011): **PASS** — confirmed green at `e924bb4` (baseline per master §3;
its structural checks are not re-reported here as findings).

---

## 2. Issues Found

### [High] Fort/throne heal: doc guarantees a 1-HP minimum the shipped code does not apply
- **Location:** `AGENT/GDD/GDD_02_Core_Mechanics.md:61-63` vs
  `scripts/core/TurnManager.gd:196-197`.
- **Problem:** OPEN-7 (Status **Answered**, a ratified decision) specifies the terrain heal
  as `heal = max(1, floor(0.10 × max_hp))` and the doc explicitly states it "guarantees at
  least 1." The shipped terrain heal omits the `max(1, …)` floor, so any unit with
  `max_hp` 1–9 heals `floor(0.10 × max_hp) = 0` on a fort/throne. `Unit.heal()`
  (`scripts/units/Unit.gd:423-424`) returns early when `amount <= 0`, so the floor that the
  decision promises never takes effect for those units. Following the doc would lead a
  contributor to assume the guarantee already holds.
- **Evidence:**
  - Doc: `GDD_02:61-63` — ``heal = max(1, floor(0.10 × max_hp))`` … "guarantees at least 1."
  - Code: `TurnManager.gd:197` — `var heal_amount: int = floori(u.data.max_hp * GameConstants.PERCENT_HP_HEAL_FRACTION)` (no `max`/`maxi`). `GameConstants.gd:85` `PERCENT_HP_HEAL_FRACTION = 0.10`.
  - The same rule's *staff* path **does** apply the floor: `SkillHandler.gd:239`
    `var amount: int = maxi(1, floori(unit.data.max_hp * …))` — so the rule is implemented
    inconsistently between staff heal and terrain heal.
- **Root cause:** PL#8-style miss at the code level: the OPEN-7 floor was applied to the
  staff-heal path but not the terrain-regen path; the doc states the full ratified rule, so
  the doc is correct and the code is the tracked gap (authority order item 3, `GDD_00:29-30`).
  Secondary: the code comment `TurnManager.gd:196` cites `GDD_02:76`, but after the Stage 3
  rewrite the rule lives at `GDD_02:61-63` — a stale line-number cite.
- **Recommended fix:** This is primarily a **code** fix (apply `maxi(1, …)` at
  `TurnManager.gd:197`) and is owned by **Pillar 1** — tag `[CROSS]`. The doc itself is
  accurate; do not change it. If the code is deliberately not guaranteeing a minimum, then
  the doc lands a **Known gap** note under GDD_02 §Terrain ("terrain heal does not yet apply
  the OPEN-7 minimum-1 floor") plus a `GDD_10_Roadmap.md` bug-tracker row (PL#8). Either way,
  refresh the `TurnManager.gd:196` line cite to `GDD_02:61`.

### [Medium] DOC-002 section template is not uniformly applied (GDD_06/07/08)
- **Location:** `AGENT/GDD/GDD_06_Maps_Objectives.md`, `GDD_07_UI_UX.md`,
  `GDD_08_Enemy_AI.md` vs `documentation_governance_2026-06-13.md:60-90`.
- **Problem:** Governance (DOC-002) states "Every major GDD feature section uses this
  template" with mandatory `### Summary` and `### Specs` and near-always `### Known gaps` /
  `### Anchors`. GDD_02–05 conform well, but GDD_06/07/08 systematically use a flatter
  layout (`## Section` + `Status:`/`Last verified:` + free `### Sub-detail` headings) with
  very few of the named template fields. This is no longer an "assumption" (as the prior
  review flagged it) — it is now measured.
- **Evidence (heading counts per chapter — `Status:` lines vs template fields present):**
  - GDD_06: 8 `Status:` / **2** `### Summary` / **1** `### Specs` / **1** `### Anchors`.
  - GDD_07: 7 `Status:` / **1** `### Summary` / **1** `### Specs` / **1** `### Anchors`.
  - GDD_08: 7 `Status:` / **2** `### Summary` / **3** `### Specs` / **3** `### Anchors`.
  - vs GDD_02: 18 / 12 / 18 / 18 and GDD_04: 10 / 7 / 10 / 10 (conformant).
  - Concrete sample: `GDD_07:31-137` (Input System, Cursor System, Screens and Panels) carry
    `Status:`/`Last verified:` but go straight to `### Action Definitions` / `### Mouse
    Behavior` / per-screen headings — no `### Summary` / `### Specs` / `### Anchors`.
- **Root cause:** The UI/maps/AI chapters were rewritten with a per-screen / per-table
  layout that fits the material better than Summary/Specs, but DOC-002 was written as a hard
  "every section" rule with no carve-out for catalog-style chapters. The rule and the
  practice diverged without anyone reconciling them.
- **Recommended fix:** Pick one and apply (these are governance/doc edits, status label
  **Active** for the governance doc; PL#8 not triggered — no behavior change):
  (a) Amend DOC-002 to allow a "catalog section" variant (screen/table-oriented sections may
  use `Status:`/`Last verified:` + detail subsections without the four named fields), and
  list which chapters use it; **or**
  (b) Bring GDD_06/07/08 sections up to the template.
  Recommend (a) — the flatter layout is genuinely more readable for UI/maps/AI, and a written
  rule that the live docs ignore is worse than an honest carve-out.

### [Low] `decision_index.md` Status column carries a one-off "Canonical" value
- **Location:** `AGENT/Docs/decision_index.md:123`.
- **Problem:** The "Combat modifier pipeline order" row uses Status `Canonical order
  ratified`. "Canonical" is one of the three governance-prohibited status words. Governance
  (`documentation_governance_2026-06-13.md:55-58`) scopes the prohibition + `check_docs.py`
  checks 7–8 to GDD_00–08 only, so the index is technically out of the enforced zone, and
  this is the **single** non-conforming value among ~30 rows (the rest read `Applied` /
  `Answered` / `Applied (Target design)` etc.). But it reintroduces exactly the word the
  governance is built to avoid, in the project's central decision navigator.
- **Evidence:** `decision_index.md:123` `| Combat modifier pipeline order | Canonical order
  ratified | Applied | JUN | …`. Compare the rest of the column: 13× `Applied`, 20× `Applied
  (Target design)`, 9× `Answered`, etc. (one consistent vocabulary except this row).
- **Root cause:** This row predates / sits outside the DOC-013 sweep that cleaned the GDD
  status lines; the index column was never normalized to the label vocabulary.
- **Recommended fix:** Reword to a governance label, e.g. Status `Applied` (the row already
  notes "ratified" in the title and "Summary in GDD_02 §Modifier Pipeline" in notes). Lands
  as an index-hygiene edit, no PL#8.

### [Low] Jun-14 content edits to GDD chapters did not bump `Last verified`
- **Location:** `GDD_02` (mtime 2026-06-14 02:26), `GDD_03` (02:26), `GDD_07` (06:04) —
  all 75 `Last verified:` lines across GDD_00–08 still read `2026-06-13`.
- **Problem:** `check_docs.py`'s stale-date check passed (the dates are not past any
  threshold), so this is not a structural failure — but three chapters were edited on Jun-14
  while every verified-date stayed Jun-13. `Last verified` is meant to assert "a human
  re-checked this section on this date"; an edit without a bump weakens that signal.
- **Evidence:** file mtimes (GDD_02/03/07 = Jun 14) vs `grep "Last verified"` → 75/75 lines
  `2026-06-13`. (Assumption: mtime reflects a content edit, not just a touch; I did not diff
  every Jun-14 commit. Flagged as an assumption per §8.)
- **Root cause:** No mechanism ties an edit to a verified-date bump; it is honor-system.
- **Recommended fix:** Low priority. When a section is next touched, bump its section's
  `Last verified`. Longer term this is a checker candidate (see §4).

---

## 3. Governance & Lifecycle Compliance (§4 checklist)

- [x] **Every status-bearing section: one approved label + `Last verified`** — pass (sampled
      GDD_00, 02, 04, 07; `check_docs.py` checks 3/6/8 back this).
- [x] **Prohibited words ("current"/"complete"/"canonical") absent as a status in GDD_00–08**
      — **pass** (regression-fixed since 2026-06-13; `grep -niE 'Status:.*(current|complete|canonical)'`
      over GDD_00–08 returns nothing — see Delta §7). One residual "Canonical" lives in
      `decision_index.md:123`, which is *out of the GDD scope* the prohibition enforces, filed
      as a Low above.
- [ ] **Major GDD sections follow the DOC-002 template** — **fail** (Issue 2; GDD_06/07/08
      diverge systematically).
- [x] **`decision_index.md` statuses use one consistent vocabulary** — substantially pass;
      one outlier (`Canonical order ratified`, Low above). The `Answered` / `Applied` /
      `Applied (Target design)` spread is the DOC-009 workflow, not inconsistency.
- [x] **No live doc links a Historical/Superseded/deleted file as authority** — pass.
      `GDD_00:76-89` cites the four retired files only as deletion notes (correctly exempt);
      the lifecycle table's E-special correctly keeps `awakening_compatability_refactor_plan`
      as **Active** (home of `AWR-` IDs), and the feature index / decision index cite it for
      AWR milestones — consistent, not a retired-file citation.
- [ ] **One rule, one owner** — pass for the previously-flagged case (S-rank constants are
      now a pointer in GDD_02:322-323 → GDD_04; see Delta). No new full-duplication found in
      the sampled set.

**Spot-check sample (doc claim ↔ source), all verified accurate except where noted:**
- "8 registered maps" (`GDD_00:144`) — `data/maps/map_registry.json` has 8 entries; 8
  `data/maps/map_*` dirs present. ✓
- "6 starter classes … being migrated to corpus (Target design, AWR-2)" (`GDD_00:133-134`) —
  24 `.tres` in `data/classes/` (the corpus set); the 6-starter framing as a migration
  target is consistent with AWR-2. ✓
- AI profiles `basic`/`passive`/`healer` (`GDD_00:139`, feature index) —
  `DataManager.gd:16 _VALID_AI_PROFILES := ["basic","passive","healer"]`. ✓
- Feature-index code anchors (bare filenames) resolve: `CombatResolver.gd` → `scripts/core/`,
  `PairUpRegistry.gd` → `scripts/autoloads/`, `GridManager.gd`/`TurnManager.gd`/`EnemyAI.gd`
  → `scripts/core/`, `ConditionManager.gd` → `scripts/autoloads/`, `CampaignRules.gd` →
  `scripts/resources/`. The index uses bare names (no dir paths), so all 8 sampled resolve. ✓
- "Status conditions — Target design (M8)" + `ConditionManager.gd` (stub) — file is 37 lines
  and referenced by no non-test production script; consistent with a stub. ✓
- Two-RN hit model (`GDD_02:221,242,269`) labelled **Split — exchange flow Implemented;
  two-RN Target design (RULE-001)**, and "not yet implemented (Package A)" — matches code:
  no two-RN logic in `CombatResolver.gd`. The Split labelling is honest. ✓
- Fort heal formula (`GDD_02:61-63`) — **drift**, see Issue 1 (High).

---

## 4. Coverage & Automation Gaps (§5 — PL#9 backlog feed)

Governance rules that are **stated but unenforced** by `check_docs.py` (the ones that rot):

1. **DOC-002 template conformance — unenforced, and now violated (Issue 2).** No check
   asserts that a `## Major Section` carrying a `Status:` line also carries `### Summary` +
   `### Specs`. A check would have surfaced GDD_06/07/08 immediately. *Caveat:* only worth
   adding **after** the (a)/(b) decision in Issue 2 — if catalog sections are blessed, the
   check needs an opt-out marker. Recommend: resolve Issue 2 first, then encode whichever
   rule wins. Medium-cost regex check.
2. **decision-index status vocabulary — unenforced (Issue 3).** Checks 7–8 stop at GDD_08;
   the index Status column is honor-system, which is how "Canonical order ratified" survived.
   A cheap extension: assert the index's Status cells draw from the governance label set
   (allowing the `(Target design)` / `(governance)` qualifiers). Low cost.
3. **`Last verified` bump-on-edit — unenforced (Issue 4).** The stale-date check is a
   *floor*, not a *freshness* check; an edited file can keep an old verified date. A git-aware
   check (does the section's verified date predate the file's last content commit?) would
   catch it but needs subprocess/git — higher cost; accept-the-gap is reasonable for now.
4. **`.uid` sidecar tracking — unenforced (master §10).** Two untracked `.uid` files sit in
   the working tree at this snapshot (header). This is master §10's named PL#9 candidate and
   a [CROSS] item for Pillar 3/4; noted here because the dirty tree affects the audit
   snapshot.

Accept-the-gap is defensible for #3; #1 and #2 are the cheap, high-rot wins.

---

## 5. Positive Observations

1. **The prior review's loop actually closed.** All three 2026-06-13 findings were fixed
   *and* the two recommended checker additions (checks 7–8) landed and pass — the
   rule→doc→CI loop the procedure asks for was completed, not just documented. This is the
   single best signal in the set.
2. **Honest split-status labelling on mid-refactor features.** `GDD_02:221` (combat) and the
   feature index carry both an `Implemented` half and a `Target design` half with the
   ratified "project/corpus" phrasing (DOC-013), and explicitly say "two-RN … not yet
   implemented (Package A)." A reader can tell shipped from aspirational at a glance — the
   exact thing the governance was built for.
3. **Authority order resolves cross-doc conflicts unambiguously** (`GDD_00:23-36`): ratified
   decision → numbered GDD → code → roadmap → corpus, with the superseded D-C direction
   called out inline. The OPEN-7 drift (Issue 1) is correctly classifiable *because* this
   order exists — code is the tracked gap, doc is the rule.
4. **Routing-only feature index holds the line** (`GDD_Feature_Index.md:5,47`): it still
   refuses to be a second spec ("routing table, not a coverage claim"), and every sampled
   code anchor resolves to a real file. Navigability is genuinely good.
5. **Lifecycle table keeps retired files honestly non-authoritative.** `GDD_00:76-89` lists
   the four deleted/moved files only as deletion notes, and the live docs cite the still-Active
   `awakening_compatability_refactor_plan` correctly as the `AWR-` home — no authority-hygiene
   violations found.

---

## 6. Prioritized Action Plan

**Fix the docs / code:**
1. **[High, CROSS→Pillar 1]** Resolve the OPEN-7 fort-heal drift (Issue 1): apply
   `maxi(1, …)` at `TurnManager.gd:197` (the doc is correct), or — if intentional — add a
   GDD_02 Known-gap note + roadmap bug row (PL#8). Refresh the stale `GDD_02:76` line cite in
   the `TurnManager.gd:196` comment regardless.
2. **[Medium]** Decide and apply DOC-002 template policy for catalog chapters (Issue 2):
   recommend amending governance to bless a catalog-section variant and naming GDD_06/07/08
   as using it.
3. **[Low]** Normalize `decision_index.md:123` Status to a governance label (Issue 3).
4. **[Low]** Bump `Last verified` on the next touch of GDD_02/03/07 (Issue 4).

**Fix the checker (so the above don't recur):**
5. After resolving Issue 2, encode the chosen DOC-002 template rule in `check_docs.py`
   (with a catalog opt-out if (a) wins).
6. Extend checks 7–8 to validate `decision_index.md` Status cells against the label set
   (closes Issue 3's class, low cost).

> Per PL#8: items 1 (if doc-side) and 2 touch governance/GDD sections — pair any GDD edit
> with the matching `GDD_10_Roadmap.md` status flip in the same commit. Items 3, 5, 6 are
> index/checker edits and do not touch a GDD section.

---

## 7. Delta vs Previous Review (`documentation_review_2026-06-13.md`)

This is the **second** dated documentation review. The first was
`documentation_review_2026-06-13.md` (the only other dated review;
`documentation_review_instructions.md` is the now-Superseded instructions file, not a review).

**Fixed (3 of 3 prior findings — all verified at `e924bb4`):**
- ✅ *Issue 1 (Medium) — "current" in Status lines.* `grep -niE 'Status:.*(current|complete|canonical)'`
  over GDD_00–08 now returns nothing; DOC-013 "project/corpus" phrasing applied, and
  `check_docs.py` checks 7–8 enforce it going forward.
- ✅ *Issue 2 (Medium) — S-rank constants duplicated.* `GDD_02:322-323` now reads "values
  owned by GDD_04 §S-Rank Weapon Bonus (not restated here)"; the literal `+10/+5/+1` triple
  lives only in GDD_04. One rule, one owner — confirmed.
- ✅ *Issue 3 (Low) — `UnitData.ai_profile` comment.* `scripts/resources/UnitData.gd:66` now
  reads `"basic"|"passive"|"healer" implemented; future: "territorial"|"guard_tile"|"boss"` —
  `healer` moved to the implemented list, matching `DataManager.gd:16`.

**New this pass:**
- 🆕 [High] OPEN-7 fort-heal drift (Issue 1) — not caught last time (prior review spot-checked
  the heal *formula text* but not its code application).
- 🆕 [Medium] DOC-002 template non-conformance in GDD_06/07/08 (Issue 2) — the prior review
  flagged template conformance as an unaudited **assumption**; this pass measured it and
  confirms the divergence.
- 🆕 [Low] `decision_index.md:123` "Canonical" status (Issue 3).
- 🆕 [Low] Jun-14 edits without `Last verified` bump (Issue 4).

**Regressed:** none.
**Still-open (carried, now resolved-or-restated):** the §5 coverage gap "governance rules
unchecked by the script" persists in a *narrower* form — the two cheapest (prohibited words,
approved label) were closed by checks 7–8; the next tier (template conformance, index
vocabulary) is now the standing gap.

**Score trend:** 8 → **8** (held). The three fixes would normally raise it, but the new High
drift + the now-confirmed template gap offset the gain.

---

## 8. Procedure friction

- **§2/§7 "first dated review" wording vs reality.** The dispatch brief told me to treat this
  as the first dated review "if none exists besides the now-Superseded instructions file." One
  *does* exist (`documentation_review_2026-06-13.md`), so I computed a real delta. No real
  friction, but the brief's default assumption was wrong for this snapshot — worth the
  orchestrator double-checking the delta target before dispatch.
- **Feature-index anchor format is ambiguous to verify.** Anchors are bare filenames
  (`CombatResolver.gd`), not paths. My first existence check used guessed directories and
  produced false "MISS" results until I re-checked by basename. The procedure says verify
  anchors resolve "to the right owner/file" — for bare-name anchors that means a basename
  search, and a contributor (or a future checker) could mis-flag these. A note in the pillar
  doc that index anchors are by-basename would save the round-trip; or the index could carry
  full paths (which would also make anchors machine-checkable — a PL#9 candidate).
- **DOC-002 "every section" vs reality is a judgment call the rubric doesn't pre-resolve.**
  The pillar §3 says "major GDD sections follow the DOC-002 template," but governance writes
  it as an absolute while three live chapters don't. The procedure gives no guidance on
  whether a defensible deviation is a finding or an accepted variant, so I filed it as Medium
  with both fix options. A line in the pillar doc on how to treat "rule says always, practice
  says sometimes" would make this less of a coin-flip.
- **Dirty snapshot.** The tree was dirty at the pinned commit (3 untracked files). Master §3
  says note it explicitly; I did, but the doc pillar has nothing to say about whether a dirty
  tree changes its own conclusions (it doesn't, here — the untracked files are assets/UIDs, a
  Pillar 3/4 concern). Minor: the pillar doc could state that dirty-tree handling is the
  orchestrator's job, not each pillar's.
