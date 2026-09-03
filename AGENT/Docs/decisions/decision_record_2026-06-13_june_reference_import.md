---
Role: topic
---

# Decision Record — June Update-Reference Import (2026-06-13)

**Date:** 2026-06-13
**Status:** Active decision record
**Source imported:** `AGENT/GDD/gdd_update_reference_2026-06-12.md`
**Companion:** `rng_determinism_design_2026-06-11.md`
**Register:** `documentation_consolidation_decisions_2026-06-12.md`

This record imports every decision and open question from the June update
reference into the decision system and gives each a disposition, per the
2026-06-13 pre-implementation review readiness gate (item 1) and handoff first
work package. Dispositions: **Retained**, **Superseded**, **Answered**,
**Deferred** (with roadmap owner), **Open decision**.

## Ratified decisions (D-A … D-E, RNG-1 … RNG-4)

| ID | Disposition | Notes |
|----|-------------|-------|
| **D-A** Public identity rename | **Retained** | All FE-derived names are placeholders; rename is a data pass. Rename decision gate no later than first public release-candidate. Related: OPEN-12 / DOC-012 (licensing is a *separate*, additional gate). |
| **D-B** 1.0 definition | **Retained** | 1.0 = all offline non-pipeline features + one short campaign. M15 Part B (online) post-1.0. M11 re-scoped: campaign content = 1.0, full coverage = post-1.0. |
| **D-C** Rules authority | **Superseded by DOC-001** | D-C made the Awakening corpus authoritative for game rules. **DOC-001 reverses this:** the numbered GDD owns project design rules; the corpus is a *reference* for building features. Any corpus rule becomes a project target only via an explicit adoption-matrix entry + GDD update. The GDD_00 authority order must be written from DOC-001, not D-C. |
| **D-D** Campaign prerequisites | **Retained** | Deployment screen, shops, recruit mechanic are campaign-mode prerequisites. Adds dependency edges to the roadmap. |
| **D-E** Reclass growth to caps | **Retained** | Second Seal growth up to stat caps is sanctioned; stat caps are the balance lever; no anti-grind guards. Note in GDD_03 Promotion/Reclass. |
| **RNG-1 … RNG-4** | **Retained, roll order amended by RULE-001** | Hash-chained context-seeded dice; RNG state in snapshot; exploits priced by rewind charges; host-authoritative online; committed non-undoable actions advance the timeline; level-up growth chained per unit+level; online determinism engine-local. **RULE-001 changes the hit draw to two RN** — the RNG contract, fixed roll-order fixture, and save-compat notes must be updated before `RngService` is built (Package A prerequisite). |

## Open questions (OPEN-1 … OPEN-13) — resolved 2026-06-13

| ID | Disposition | Resolution |
|----|-------------|------------|
| **OPEN-1** Supports in/out | **Answered → Deferred (campaign-rules layer)** | Yes, supports are a committed feature, but post-1.0. Confirms RULE-012: layers 4–8 (adjacent support, ranks, conversations, marriage, children) are post-1.0. |
| **OPEN-2** Condition/skill precedence | **Answered** | Conditions are **not** skills: Nihil/skill-negators never block conditions. A condition that disables acting (e.g. Sleep, Stun) also suppresses that unit's combat-start skills. One general rule; exceptions logged per-skill in GDD_05. |
| **OPEN-3** Mid-exchange weapon breakage | **Answered** | Breakage **cancels that unit's remaining strikes** in the exchange (consistent with attacks-determined-upfront and the deterministic roll order). Weapon is gone after combat. |
| **OPEN-4** Enemy/AI EXP | **Answered (CampaignRules)** | Build a faction-gated `add_exp()` and expose the choice to campaign designers via a `CampaignRules.exp_gaining_factions` field. **Default: Blue (player) + Green (ally) gain EXP; Red (enemy) does not.** Designers may override per campaign. |
| **OPEN-5** Durability soft-lock | **Answered + new backlog item** | Accept the edge case for now. New backlog item: **broken-weapon degraded mode** — an *optional* rule where a 0-use weapon stays usable with a stat penalty and infinite uses while broken, repairable later at special shops / with special items. (Likely a CampaignRules toggle.) |
| **OPEN-6** Simultaneous victory/defeat | **Answered** | Evaluate **defeat before victory**. If multiple groups still satisfy victory in one pass, prefer the **acting faction's** group; otherwise declare the existing draw. |
| **OPEN-7** Fort/throne heal rounding | **Answered** | `heal = max(1, floor(0.10 * max_hp))` — matches Renewal rounding. |
| **OPEN-8** Renderer backend | **Answered** | Ship **Compatibility (OpenGL)**; required for web export; nothing here needs Forward+. Record in GDD_00 tech-stack table. |
| **OPEN-9** Soldier class | **Deferred (roadmap AWR-2 class migration)** | Resolve Soldier's identity when the corpus class set lands. Interim: Map 001 keeps E1/E6 as a **placeholder enemy-only Soldier**; GDD_03 marks the class **Open decision (pending AWR-2)**. Avoids authoring a bespoke class that gets archived under RULE-007. |
| **OPEN-10** Cleric "Light E" | **Deferred (RULE-009 Light/Dark design pass)** | The Cleric's Light access is decided by the dedicated Light/Dark magic design task. Mark the rank **Open decision** until then — do not author a one-off tome or drop it prematurely. |
| **OPEN-11** Steam Deck 16:10 | **Answered; revisited 2026-07-31** | The initial **letterbox** choice was explicitly temporary. With UI scale delivered, `UI-VIEWPORT-ASPECT` completed the promised revisit: use the **expand** model with a persisted Viewport Scale setting and a 1280×720 authored floor. Native Steam Deck validation remains outstanding; it validates the delivered policy rather than reopening letterbox versus expand. |
| **OPEN-12** Handbook licensing/attribution | **Answered (pre-1.0 gate, with DOC-012)** | A **formal blocking pre-1.0 release gate**: research the source handbook/corpus license for derivative digital works and decide attribution. **D-A's rename is separate and does NOT resolve this.** Owned alongside DOC-012. |
| **OPEN-13** Suspend-file lifecycle | **Answered** | Suspend file **persists until the map resolves**, then is deleted. Reload-scumming is already blocked by the RNG-2 hash chain, so no delete-on-load. (Companion §8.2 assumes this.) |

## Other ratifications

| Item | Disposition | Resolution |
|------|-------------|------------|
| Combat modifier pipeline order | **Answered (ratified)** | Canonical order: base stats → permanent modifiers → pair-up bonuses → combat-duration skill mods → conditions → terrain → weapon triangle → S-rank bonus → clamps. The corpus combat migration (SET-001/003, RULE-002) must slot into this order. Goes in GDD_01; enforced before M9b authoring. |
| Parking-lot #8 — Doc-lifecycle rule | **Answered (adopted)** | Standing rule: a milestone's definition-of-done includes updating affected GDD_01–08 sections and flipping the roadmap status in the **same commit**. Pairs with DOC-011 (CI doc validation). To be added to `AGENTS.md` / standing agent instructions during implementation. |
| Parking-lot #9 — Minimal SFX | **Answered (deferred)** | **Wait for the Phase 3 audio milestone** — no interim SFX. (Owner chose to defer rather than add the four placeholder sounds.) |

## New backlog items created by this import

1. **CampaignRules `exp_gaining_factions`** field (from OPEN-4) — default Blue + Green; faction-gated `add_exp()`. Slot with the CampaignRules stub (§5 of the update reference).
2. **Broken-weapon degraded mode** (from OPEN-5) — optional rule, stat penalty + infinite uses while broken, repair via special shops/items. Bucket E / feature list; likely CampaignRules-toggled.

Both should be added to the roadmap feature list during the roadmap-consolidation phase.

## Archive note

Once these dispositions are reflected in the numbered GDD, roadmap, and adoption
matrix, `gdd_update_reference_2026-06-12.md` becomes **Historical** and is
archived per DOC-010. The RNG contract merges into the GDD feature design home
(also DOC-010).
