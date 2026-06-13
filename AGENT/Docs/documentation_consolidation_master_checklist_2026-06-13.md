# Documentation Consolidation — Master Checklist (Complete)

**Date:** 2026-06-13
**Supersedes:** `documentation_consolidation_handoff_2026-06-13b.md` (which only covered
Phases 1–3; this document covers the full Phase 1→7 + Package G scope).
**Status:** Decisions complete. This is the end-to-end execution checklist that, when
finished, satisfies every completion criterion in the plan §12.

## Purpose

The earlier handoff was a correct *start* but stopped at "Phase 2 + interleaved
Phase 3/4". Executing only that leaves the roadmap split (`GDD_10a` still live),
supporting guides still duplicating rules, no link validation, and the Package G
release decisions with no roadmap home — i.e. not a single source of truth. This
checklist is the complete sequence.

## Source documents (reading order)

1. This checklist
2. `documentation_governance_2026-06-13.md` — standards you apply (status vocab,
   section template, decision-record schema + ID namespace)
3. `decision_record_2026-06-13_june_reference_import.md` — D-A…E, RNG-1…4,
   OPEN-1…13, pipeline order, PL#8/#9
4. `documentation_consolidation_decisions_2026-06-12.md` — DOC-/RULE- register
5. `documentation_consolidation_plan_2026-06-12.md` — the full plan (§7 phases,
   §10 packages, §12 completion criteria)

## Scope boundary

This checklist covers **documentation consolidation**. The corpus-adoption work
packages B–F (plan §10) involve game *code* changes; only their **documentation
obligations** (adoption-matrix rows + GDD target-design prose) are in scope here and
land inside Stage 3. The code for B–F is separate implementation work tracked on the
roadmap. Package A's **RNG-contract** step *is* in scope (it is a doc), and is a
prerequisite for the later `RngService` implementation.

---

# STAGE 1 — Foundations (readiness gate, before any destructive move)

### [x] 1.1 Phase 1 — file lifecycle / link-migration table — DONE 2026-06-13 (`documentation_lifecycle_2026-06-13.md`)

Create `AGENT/Docs/documentation_lifecycle_2026-06-13.md`: one row per tracked doc —
current path, status label, authority scope, action (keep/merge/move/supersede/
delete), merge target, retained headings, inbound refs, acceptance check. Start from
the inbound-reference sweep in **Appendix A** (do not re-search).

Exit: every document has an explicit lifecycle; no planned move would orphan a live
inbound link.

### [x] 1.2 Update the RNG contract to two-RN (RULE-001) — DONE 2026-06-13 (`rng_determinism_design_2026-06-11.md` §5/§6/§11/T7; file kept untracked pending 3.1 move/merge)

In `rng_determinism_design_2026-06-11.md`: hit = two 0–99 draws, floor the average,
compare to resolved hit; crit only after a successful hit; skill activations at their
trigger slots. Update the fixed roll-order fixture (currently one-roll) and the
save-compatibility notes. Must precede any `RngService` code.

Exit: contract, fixture, and save notes all describe the two-RN order.

### [x] 1.3 Seed `AGENT/Docs/decision_index.md` — DONE 2026-06-13

Per the DOC-009 schema: one row per existing DOC-/RULE-/SET-/OPEN-/RNG-/AWR- ID with
status + link + supersession. Record **D-C → superseded by DOC-001**.

Exit: every known decision ID is discoverable from one index.

### [x] 1.4 Seed `AGENT/GDD/GDD_Feature_Index.md` — DONE 2026-06-13

The DOC-005 dedicated index; columns per plan §5. Start from the initial feature
groups in plan §5 (combat/RNG, weapon triangle, WEXP, EXP/promotion/reclass, classes/
skills, Pair Up/support, terrain, objectives, faction scheduling, conditions, skills,
economy, save/retry/suspend/rewind, UI/input/accessibility, AI, campaign, online).

Exit: file exists; will be linked from `GDD_00` in Stage 2.

---

# STAGE 2 — Entry point (Phase 2)

### [x] 2.1 Rewrite `GDD_00_Overview.md` — DONE 2026-06-13

Owns: project vision + 1.0 release definition (D-B); authority model (DOC-001 — GDD
owns rules, corpus is reference); status vocabulary (DOC-003); GDD section template
(DOC-002); document map; link to `GDD_Feature_Index.md`; high-level baseline;
known-issue + pending-validation summary; platform targets (OPEN-8/11). No operational
procedures duplicated.

Exit: a new session can start from `GDD_00` and reach the correct owner for any major
feature.

### [x] 2.2 Add the PL#8 doc-lifecycle DoD rule to `AGENTS.md` — DONE 2026-06-13

Same-commit rule: a feature change updates the affected GDD sections **and** flips the
roadmap status in the same commit. (Pairs with the DOC-011 CI checks in Stage 6.)

---

# STAGE 3 — System chapters + corpus adoption (Phases 3 ⨉ 4, interleaved)

**Sequencing rule:** for any chapter importing corpus-derived rules, its
adoption-matrix rows are completed **before or in the same commit as** the chapter
rewrite (enforces DOC-001 provenance).

### [x] 3.0 Establish the adoption-matrix structure — DONE 2026-06-13 (moved to `AGENT/GDD/GDD_Adoption_Matrix.md`; corpus links repaired)

Expand `AGENT/GDD/Content Expansion/New_Content_Expansion/project_adoption_matrix.md`
from a short list into the systematic index defined in plan §4.4 (columns: not
reviewed / adopted target / adopted with project variation / rejected / deferred /
implemented; every "project variation" links to its numbered GDD section). Decide and
record its final home/location during this step.

Then, per chapter in the recommended order, do: (a) complete this chapter's adoption
rows, (b) rewrite using the section template + status labels with `Last verified`
dates, (c) add code/data/test anchors, (d) move procedural detail to the owning guide,
(e) mark superseded source docs and apply their gated move/merge (Stage 1 table), (f)
record any new choice in the register.

- [x] 3.1 **`GDD_02` Core Mechanics** — DONE 2026-06-13. Rewrote with section template +
  status labels; applied two-RN (RULE-001), pipeline order, OPEN-2/3/6/7, WEXP/EXP/
  promotion-timing decisions as split status. **RNG contract merged:** binding rules →
  `GDD_01 §Determinism, Snapshot & Online Contract` + `GDD_02 §Combat Resolution & Hit
  RNG`; file moved to `AGENT/Docs/` and re-scoped as the implementation plan (DOC-010).
- [x] 3.2 **`GDD_03` Units & Classes** — DONE 2026-06-13. Section template + status
  labels; corpus class adoption (SET-009/RULE-007/008) as Target; progression counters
  (RULE-006/SET-007); promotion targets (SET-006) w/ timing cross-ref to GDD_02 (RULE-005);
  reclass + growth-to-caps (D-E); Light/Dark (RULE-009) + Soldier (OPEN-9) deferred;
  Cleric Light (OPEN-10) Open decision. Compressed 6 stat blocks → 1 reference table
  (.tres authoritative).
- [x] 3.3 **`GDD_04` Weapons & Items** — DONE 2026-06-13. Section template + status labels;
  weapon families + rank-scaled triangle bonus table (SET-003/RULE-013), WEXP thresholds/
  gain/migration (SET-004/RULE-003/004), S-rank engine move + retire `s_rank_mastery`
  (SET-005/RULE-002), effectiveness, items/economy/forging, broken-weapon backlog (OPEN-5).
  Combat application cross-referenced to GDD_02; schemas to GDD_01.
- [x] 3.4 **`GDD_05` Skills** — DONE 2026-06-13. Section template + status labels; added
  §Pair Up & Support System (pass 1 Implemented; value migration Planned RULE-012/SET-010;
  Dual Strike/Guard Target; supports 4–8 Deferred OPEN-1) and §Skill Acquisition,
  §Skill Activation & RNG (proc draws from event RNG, RNG-1/OPEN-2), §Condition/Skill
  Precedence (per-skill exceptions, OPEN-2). Cleric Light E Open decision cross-ref to
  GDD_03 (RULE-009). `s_rank_mastery` retirement cross-ref to GDD_04.
- [x] 3.5 **`GDD_01` Architecture** — DONE 2026-06-13. Added header status block +
  ownership statement; added **§CampaignRules Contract** (live GameState rule fields
  Implemented; consolidation + `exp_gaining_factions` OPEN-4 / rewind charges RNG-3 /
  follow-up override Target, code stub deferred to Stage 4.3). Two-RN save-compat note +
  RngService autoload-order insertion already present in §Determinism/Implementation Notes
  (3.1); resource/serialization schemas retained as Reference tracking the code.
- [x] 3.6 **`GDD_06` Maps & Objectives** — DONE 2026-06-13. Header + status labels; added
  §Terrain & Movement schema with split tables (project Implemented + corpus Target,
  SET-008/RULE-010), terrain ID mapping Open decision (RULE-011/AWR-8); status-labeled
  Objective System, Map 001 reference, Phase 3 maps (M16), Doors/Chests + Fog (Planned).
  Combat effects cross-referenced to GDD_02; schemas to GDD_01.
- [x] 3.7 **`GDD_07` UI/UX** — DONE 2026-06-13. Header + status labels across input/cursor/
  screens/state-machine/feedback sections; added §Accessibility & Input Parity contract
  (keyboard/mouse + hotseat parity Implemented; key rebind + UI-scale Planned). Platform
  targets cross-referenced to GDD_00 (OPEN-11); SettingsManager schema to GDD_01.
- [x] 3.8 **`GDD_08` Enemy AI** — DONE 2026-06-13. Header + status labels; added
  §AI Determinism & Parity (deterministic decisions, stable tie-breaks, host-authoritative
  online RNG-4, EXP parity OPEN-4), §Performance Constraints (per-unit Dijkstra budget +
  scaling guardrails), §Enemy Generation & Autolevel (Not reviewed). Tactical scoring
  Planned. EXP gating cross-referenced to GDD_02/GDD_01.

Exit: each live rule or target rule has exactly one numbered-GDD owner, and no corpus
section can silently override a project variation. **Stage 3 COMPLETE 2026-06-13.**

---

# STAGE 4 — Roadmap & task tracking consolidation (Phase 5)

### [ ] 4.1 Make `GDD_10_Roadmap.md` the single roadmap owner; retire `GDD_10a`

Merge any unique ordering/history from `GDD_10a_Overview.md` into the roadmap (concise
completion history only), then **delete `GDD_10a`** and repair its inbound links
(`README.md:19`, `GDD_00:22,36`, internal `GDD_09:52`) per the Stage 1 table (DOC-004).

### [ ] 4.2 Stable IDs + bug/task hygiene

Assign stable IDs to open bugs, prep tasks, systems, and release gates. Move confirmed
playtest bugs out of prose notes into the work bucket; keep pending-validation separate
from confirmed defects. Ensure every target GDD section has a roadmap owner or explicit
"not scheduled".

### [ ] 4.3 Land the Package G release decisions as roadmap owners

- [ ] **1.0 definition** (D-B) + re-scope M11 (campaign content = 1.0; full coverage
  post-1.0).
- [ ] **Public-identity rename gate** (D-A) — data-pass rename no later than first
  public RC.
- [ ] **Legal/licensing gate** (DOC-012 / OPEN-12) — blocking pre-1.0 review,
  separate from the rename.
- [ ] **Renderer / platform targets** (OPEN-8/11) — Compatibility (OpenGL); desktop
  primary, Steam Deck letterboxed at first verification, web as playtest channel,
  gamepad with the rebind milestone, mobile deferred.
- [ ] **Campaign prerequisites** (D-D) — deployment screen, shops, recruit mechanic as
  dependency edges to the campaign milestone.
- [ ] **`CampaignRules` stub** (update reference §5) — create with known fields incl.
  `exp_gaining_factions` (OPEN-4, default Blue+Green). Code stub + `GDD_01` contract.
- [ ] **New backlog items** — broken-weapon degraded mode (OPEN-5); SFX deferred to the
  Phase 3 audio milestone (PL#9).

Exit: every planned or broken feature has exactly one tracking entry.

---

# STAGE 5 — Supporting documents cleanup (Phase 6)

### [ ] 5.1 Active guides

For `testing_guide.md`, map authoring guide, sprite importer guide, environment setup,
release/export procedure: verify paths/commands, remove copied rules that belong in the
GDD, link back to the authoritative GDD section, add `Last verified` date + responsible
workflow.

### [ ] 5.2 Execute the remaining gated moves/merges (Stage 1 table)

- [ ] `GDD_09_Checklist.md` → merge useful content, then **delete** + repair links
  (DOC-006).
- [ ] `GDD_Assumptions.md` → merge, then **delete** + repair links (DOC-006).
- [ ] `GDD_Manual_Tasks.md` → move to `AGENT/Docs/manual_test_playbook.md` + repair
  links (DOC-007: `GDD_00:25`, `testing_guide.md:46,150,175,183`,
  `GDD_10_Roadmap.md:1337`, `Play_tester_comments.md:4`).
- [ ] `gdd_update_reference_2026-06-12.md` → archive once fully applied (DOC-010).
  (Its companion `rng_determinism_design` was merged in 3.1.)

### [ ] 5.3 Historical plans/audits

Add supersession headers where needed; remove current-document links that imply a
superseded plan is still active; preserve evidence and rationale.

Exit: search results clearly distinguish instructions from history.

---

# STAGE 6 — Documentation validation checks (Phase 7 / DOC-011)

### [ ] 6.1 Add lightweight repo checks (no prose interpretation)

- verify repository-relative Markdown links and file paths
- reject links to known renamed/deleted paths
- detect duplicate active roadmap IDs
- verify required headers on active plans and superseded docs
- verify feature-index targets exist
- flag stale `Last verified` only when a status-bearing file changed
- (optional) flag legacy field names outside explicitly historical sections

Exit: common structural drift fails locally or in CI.

---

# STAGE 7 — Completion verification (plan §12)

### [ ] 7.1 Confirm every completion criterion

- [ ] `GDD_00` gives an unambiguous starting point + authority model
- [ ] every current/target feature has one owning GDD section
- [ ] the feature index reaches rules, roadmap, code/data, verification
- [ ] corpus adoption + project variations are explicit
- [ ] one roadmap owns scope/order/status/dependencies
- [ ] open decisions live only in the register
- [ ] historical files can't be mistaken for current instructions
- [ ] operational guides don't duplicate normative rules
- [ ] doc validation catches broken links + lifecycle errors
- [ ] feature DoD requires synchronized documentation

---

## Commit-sequence mapping (plan §11)

| Plan commit | Covered by |
|---|---|
| 1. Define governance + status vocabulary | done (Phase 0) + Stage 2 GDD_00 |
| 2. Add feature-oriented navigation | Stage 1.3/1.4, Stage 2 |
| 3. Consolidate combat & progression | Stage 3.1–3.2 |
| 4. Reconcile class & content adoption | Stage 3.3–3.4 + matrix |
| 5. Consolidate maps/UI/AI | Stage 3.5–3.8 |
| 6. Unify roadmap ownership + task tracking | Stage 4 |
| 7. Mark superseded docs + repair links | Stage 5 |
| 8. Add documentation consistency checks | Stage 6 |

Do not combine corpus rule migrations with unrelated historical cleanup.

## Apply-as-you-go reminders

- Every numbered-GDD section uses the section template + a status label with a
  `Last verified` date. No "current/complete/canonical".
- Corpus rules need an adoption-matrix row **before/with** the GDD edit (DOC-001).
- Moves/deletes happen **only after** the Stage 1 table is reviewed, applied
  atomically with link repairs (DOC-006/008).
- Honor PL#8 (Stage 2.2): update affected GDD sections + flip roadmap status in the
  same commit.

## Stop conditions

Pause the affected branch if: a file's useful content has no confirmed merge target; a
move would orphan a live inbound reference; a corpus rule lacks an exact source heading
or project-variation entry; or implementation behavior would be chosen without an
answered decision.

## Preserve this worktree state (until its Stage action runs)

- `AGENT/GDD/gdd_update_reference_2026-06-12.md` (untracked; archived in Stage 5.2)
- ~~`AGENT/GDD/rng_determinism_design_2026-06-11.md`~~ — **DONE (3.1):** moved to
  `AGENT/Docs/`, binding rules merged into GDD_01/02, re-scoped as implementation plan,
  now tracked. Archived once `RngService` + tests land.
- combat-preview screenshots + `.import` files in `AGENT/Docs`

---

## Appendix A — inbound-reference inventory (swept 2026-06-13, carried from handoff_b)

Live = onboarding/active GDD/guide that must be repaired on move. Historical = audits /
superseded plans / session notes (annotate optional, no repair needed). Self-referential
consolidation docs are omitted — they update naturally.

### `GDD_10a_Overview.md` → retire (roadmap owns content/order/status, DOC-004)
- **Live:** `README.md:19`; `GDD_00_Overview.md:22,36`
- Historical: `gdd_codebase_alignment_audit_2026-06-11.md:23,68,70,156`;
  `campaign_rules_firming_notes_2026-05-25.md:86`;
  `playtest_triage_execution_plan_2026-05-26.md:195`;
  internal: `GDD_09_Checklist.md:52`, `GDD_Assumptions`/`GDD_Manual_Tasks` rows in 10a
  itself (162–163), rng/update-reference (both being moved)

### `GDD_09_Checklist.md` → merge then delete (DOC-006)
- **Live:** `GDD_00_Overview.md:20,37`; `GDD_01_Architecture.md:30`;
  `GDD_10_Roadmap.md:13,41` plus backlog refs `1627,1644,1655,1656,1659,1660,1695`
  ("GDD_09 Phase 2 backlog" — reword to the roadmap's own backlog)
- Historical: `code_review_2026-05-18.md` (many); `code_review_2026-05-21b.md:54`;
  `gdd_codebase_alignment_audit_2026-06-11.md:24,62,69`

### `GDD_Assumptions.md` → merge then delete (DOC-006)
- **Live:** `GDD_00_Overview.md:24,37`
- Historical: `gdd_codebase_alignment_audit_2026-06-11.md:24,63`; `GDD_10a:162`
  (10a retiring); internal `GDD_Assumptions.md:42` self

### `GDD_Manual_Tasks.md` → move to `AGENT/Docs/manual_test_playbook.md` (DOC-007)
- **Live:** `GDD_00_Overview.md:25`; `testing_guide.md:46,150,175,183`;
  `GDD_10_Roadmap.md:1337`; `Play_tester_comments.md:4`
- Historical: `promotion_reclass_test_map_plan_2026-05-23.md` (several);
  `hotseat_test_map_plan_2026-05-21.md:213`; `playtest_fix_plan_2026-06-09.md:6,41`;
  `playtest_triage_execution_plan_2026-05-26.md:194`; `handoff_2026-06-09d.md:62,130`;
  `GDD_10a:48,163` (retiring)

### `gdd_update_reference_2026-06-12.md` → move to `AGENT/Docs` now, archive once applied (DOC-010)
- Only referenced by consolidation docs (self-updating) + the RNG companion

### `rng_determinism_design_2026-06-11.md` → move to `AGENT/Docs`, later merge into GDD feature home (DOC-010)
- Only referenced by consolidation docs + the update reference

**Note:** `README.md:19` is the highest-priority external link (onboarding) — it points
at both `GDD_10_Roadmap.md` (stays) and `GDD_10a_Overview.md` (retires).
