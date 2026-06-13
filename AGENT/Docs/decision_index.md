# Decision Index

**Date opened:** 2026-06-13
**Status:** Active — central navigation index for all project decisions (DOC-009).
**Schema:** `documentation_governance_2026-06-13.md` → "Decision-Record Schema & ID
Namespace (DOC-009)".

One row per decision ID. `Status` uses the governance vocabulary; `Applied` records
where a decision is reflected in the numbered GDD / roadmap / code (blank = answered
but not yet applied to the GDD). Homes:

- **REG** = `documentation_consolidation_decisions_2026-06-12.md` (DOC-/RULE-/SET-)
- **JUN** = `decision_record_2026-06-13_june_reference_import.md` (D-A…E, OPEN-, RNG-, PL#, pipeline)
- **GOV** = `documentation_governance_2026-06-13.md`
- **RNG** = `rng_determinism_design_2026-06-11.md`
- **AWR** = `awakening_compatability_refactor_plan_2026-05-22.md`

## ID Namespace (DOC-009)

| Prefix | Scope |
|--------|-------|
| `DOC-` | Documentation-governance decisions |
| `RULE-` | Rules / migration decisions |
| `SET-` | Settled owner directions |
| `OPEN-` | June-reference open questions (resolved; kept as aliases) |
| `RNG-` | RNG / determinism contract decisions |
| `AWR-` | Awakening-refactor roadmap milestones |
| `D-A…E` | **Deprecated aliases** for June ratified decisions (mapped below) |
| `PL#` | Parking-lot items from the June reference |

## DOC — documentation governance

| ID | Title | Status | Home | Applied / Supersession |
|----|-------|--------|------|------------------------|
| DOC-001 | Project/corpus authority boundary | Applied | REG | GDD owns rules, corpus is reference. **Supersedes D-C.** Applied to GDD_00 authority order (Stage 2.1). |
| DOC-002 | Current/target layout (section template) | Applied (governance) | REG | Template in GOV; apply to GDD chapters in Stage 3. |
| DOC-003 | Status vocabulary | Applied (governance) | REG | Vocabulary in GOV; apply to GDD chapters in Stage 3. |
| DOC-004 | Roadmap ownership | Answered | REG | Retire GDD_10a; GDD_10 owns. Apply in Stage 4. |
| DOC-005 | Feature-index location | Applied | REG | `AGENT/GDD/GDD_Feature_Index.md` seeded (Stage 1.4). |
| DOC-006 | Historical checklist/assumptions | Answered | REG | Merge+delete GDD_09 & GDD_Assumptions. Apply in Stage 5.2. |
| DOC-007 | Manual-test playbook location | Answered | REG | Move GDD_Manual_Tasks → `AGENT/Docs/manual_test_playbook.md`. Stage 5.2. |
| DOC-008 | Superseded-document policy | Answered | REG | Move/remove now, gated on lifecycle table. Stage 5. |
| DOC-009 | Decision-log structure | Applied | REG | Dated records + this index. |
| DOC-010 | Location of June reference contracts | Answered | REG | Move both to Docs; archive update-ref (Stage 5.2), merge RNG into GDD home (Stage 3.1). |
| DOC-011 | Documentation validation in CI | Answered | REG | Implement in Stage 6. |
| DOC-012 | Legal/licensing release gate | Answered | REG | Blocking pre-1.0 gate; pairs with OPEN-12. Roadmap owner in Stage 4.3. |

## RULE — rules / migration

| ID | Title | Status | Home | Applied / Notes |
|----|-------|--------|------|-----------------|
| RULE-001 | Exact two-RN hit model | Applied (Target design) | REG | Option A (two 0–99, floor avg). **Supersedes single-roll hit.** Documented in GDD_02 §Combat Resolution & GDD_01 §Determinism (Stage 3.1); code is Package A. |
| RULE-002 | S-rank bonus | Answered | REG | +10 Hit/+5 Crit/+1 Dmg via combat engine; retire `s_rank_mastery`. |
| RULE-003 | WEXP migration | Answered | REG | Option B (proportional within rank); runtime conversion formula recorded. |
| RULE-004 | WEXP gain timing | Answered | REG | Per valid use; may change in a balance pass. |
| RULE-005 | Promotion trigger timing | Answered | REG | Seal@10 + optional auto-promote@cap; mandatory modal blocks all controllers, no cancel. |
| RULE-006 | Reclass EXP counters | Answered | REG | `displayed_level` / `exp_basis_level` / `lifetime_levels_gained`. |
| RULE-007 | Class replacement scope | Answered | REG | Full corpus classes; archive project-only classes. |
| RULE-008 | Personal vs class growths | Answered | REG | Replace personal growths; effective = corpus archetype + corpus class. |
| RULE-009 | Light/Dark magic design scope | Answered | REG | Dedicated design task before bulk class migration. Owns OPEN-10. |
| RULE-010 | Terrain migration rollout | Answered | REG | Show both tables (Implemented + Target design) until migration. |
| RULE-011 | Existing terrain ID mapping | Deferred | REG | Roadmap owner **AWR-8**; GDD terrain ID section stays Open decision until then. |
| RULE-012 | Pair Up/support release scope | Answered | REG | Pair Up pass 1 IN 1.0; Dual Strike/Guard later; supports 4–8 post-1.0. |
| RULE-013 | Magic-triangle rank source | Answered | REG | Equipped weapon's trained WEXP track sets magnitude; `triangle_family` sets relationship. |

## SET — settled owner directions

| ID | Title | Status | Home |
|----|-------|--------|------|
| SET-001 | Combat formulas → corpus | Settled (target) | REG |
| SET-002 | Hit RNG → two-RN (see RULE-001) | Settled (target) | REG |
| SET-003 | Weapon triangles (retain both, rank-scaled) | Settled (target) | REG |
| SET-004 | WEXP → corpus thresholds/caps | Settled (target) | REG |
| SET-005 | Weapon-rank combat bonuses → engine | Settled (target) | REG |
| SET-006 | Promotion → corpus model | Settled (target) | REG |
| SET-007 | Reclass progression counters | Settled (target) | REG |
| SET-008 | Terrain → corpus values/categories | Settled (target) | REG |
| SET-009 | Class definitions → corpus + Light/Dark task | Settled (target) | REG |
| SET-010 | Pair Up/supports → corpus eventual target | Settled (target) | REG |

## D — June ratified decisions (deprecated short aliases)

| ID | Title | Status | Home | Canonical / Notes |
|----|-------|--------|------|-------------------|
| D-A | Public identity rename | Retained | JUN | Data-pass rename ≤ first public RC. Separate from OPEN-12/DOC-012. |
| D-B | 1.0 definition | Retained (applied to GDD_00) | JUN | Offline non-pipeline features + one short campaign; M11 re-scoped. In GDD_00 Release Definition (Stage 2.1). |
| D-C | Rules authority | **Superseded by DOC-001** | JUN | Reversed: GDD owns rules, corpus is reference. |
| D-D | Campaign prerequisites | Retained | JUN | Deployment screen, shops, recruit mechanic → roadmap edges. |
| D-E | Reclass growth to caps | Retained | JUN | Second Seal growth to caps; caps are the balance lever. Note in GDD_03. |

## RNG — determinism contract

| ID | Title | Status | Home | Notes |
|----|-------|--------|------|-------|
| RNG-1 | Hash-chained context-seeded dice | Applied (Target design) | RNG→GDD_01 | Roll order amended by RULE-001. In GDD_01 §Determinism (3.1). |
| RNG-2 | RNG state in snapshot contract | Applied (Target design) | RNG→GDD_01 | Blocks reload-scumming. In GDD_01 §Determinism (3.1). |
| RNG-3 | Accepted exploits priced by rewind charges | Applied (Target design) | RNG→GDD_01 | In GDD_01 §Determinism (3.1). |
| RNG-4 | Online play host-authoritative | Applied (Target design) | RNG→GDD_01 | M15B; engine-local determinism. In GDD_01 §Determinism (3.1). |

## OPEN — June open questions (all resolved 2026-06-13)

| ID | Title | Status | Home | Resolution |
|----|-------|--------|------|------------|
| OPEN-1 | Supports in/out | Deferred (post-1.0) | JUN | Committed feature, post-1.0; confirms RULE-012. |
| OPEN-2 | Condition/skill precedence | Applied | JUN | Conditions ≠ skills; one general rule. In GDD_02 §Status Conditions (3.1); per-skill exceptions in GDD_05. |
| OPEN-3 | Mid-exchange weapon breakage | Applied | JUN | Cancels remaining strikes. In GDD_02 §Combat Resolution + §Durability (3.1). |
| OPEN-4 | Enemy/AI EXP | Answered (in GDD_02) | JUN | `CampaignRules.exp_gaining_factions`, default Blue+Green. Noted GDD_02 §EXP (3.1); CampaignRules contract is GDD_01 (3.5). |
| OPEN-5 | Durability soft-lock | Answered + backlog | JUN | Accept for now; backlog item noted GDD_02 §Durability (3.1). |
| OPEN-6 | Simultaneous victory/defeat | Applied | JUN | Defeat before victory; tie → acting faction. In GDD_02 §Win/Loss Evaluation (3.1). |
| OPEN-7 | Fort/throne heal rounding | Applied | JUN | `max(1, floor(0.10 × max_hp))`. In GDD_02 §Terrain (3.1). |
| OPEN-8 | Renderer backend | Answered (applied to GDD_00) | JUN | Compatibility (OpenGL); recorded in GDD_00 Platform Targets (Stage 2.1). |
| OPEN-9 | Soldier class | Deferred (AWR-2) | JUN | Placeholder enemy-only Soldier on Map 001 until class migration. |
| OPEN-10 | Cleric "Light E" | Deferred (RULE-009) | JUN | Decided by Light/Dark design pass. |
| OPEN-11 | Steam Deck 16:10 | Answered (applied to GDD_00) | JUN | Letterbox; revisit once UI-scale setting exists. In GDD_00 Platform Targets (Stage 2.1). |
| OPEN-12 | Handbook licensing/attribution | Answered (pre-1.0 gate) | JUN | Blocking pre-1.0 gate; owned with DOC-012; rename does not resolve it. |
| OPEN-13 | Suspend-file lifecycle | Answered | JUN | Persists until map resolves, then deleted; no delete-on-load. |

## Other ratifications

| ID | Title | Status | Home | Notes |
|----|-------|--------|------|-------|
| Combat modifier pipeline order | Canonical order ratified | Applied | JUN | base → permanent → pair-up → combat-duration skills → conditions → terrain → triangle → S-rank → clamps. Summary in GDD_02 §Modifier Pipeline (3.1); binding contract home GDD_01 (3.5). |
| PL#8 | Doc-lifecycle DoD rule | Applied | JUN | Same-commit GDD + roadmap update. **Applied to AGENTS.md** (Stage 2.2). |
| PL#9 | Minimal SFX | Answered (deferred) | JUN | Wait for Phase 3 audio milestone. |

## AWR — roadmap milestones referenced by decisions

| ID | Title | Status | Home | Notes |
|----|-------|--------|------|-------|
| AWR-2 | Class corpus migration | Roadmap milestone | AWR | Owns OPEN-9 (Soldier identity). |
| AWR-8 | Terrain corpus migration & ID mapping | Roadmap milestone | AWR | Owns RULE-011; exact slot set in roadmap rewrite (Stage 4). |

> Full `AWR-` milestone list lives in the AWR plan; only IDs referenced by other
> decisions are mirrored here.
