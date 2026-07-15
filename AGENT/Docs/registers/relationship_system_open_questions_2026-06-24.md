---
Type: register
Status: RESOLVED 2026-06-24
Last verified: 2026-06-24
Register: REL-1..9
Resolved-in: 2026-06-24f
---

# Relationship System (#5) — Player-Facing Design + Open Questions

**Started:** 2026-06-24 (session 2026-06-24f) — head of sync-cluster **A3** (roster identity &
relationships), the do-first cluster in the Phase-A define-all sweep (biggest F1-schema risk).
**Status:** RESOLVED 2026-06-24f. The FE-style ranked **relationship** system (C/B/A/S-style
ranks + optional conversations + mechanical bonuses). **Named "relationship", not "support"** — the
codebase already uses `support`/`PairUpRegistry.ROLE_SUPPORT` for the **pair-up combat partner**
role; reusing the word would collide. **Reuses the `[PXP]` track engine** (resolved 2026-06-23l,
**not yet built**) — this firming hands the PXP build one extra requirement (REL-9) so the engine is
extracted pair-agnostic from day one rather than retrofitted.
**Pattern:** mirrors `[IEQ]`/`[PXP]`/`[CEX]`. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

This is the schema keystone of A3; **Avatar (#20)** and **Recruit/Capture (#4 ⇄ A4)** are walked
next and lean on this (top-rank exclusivity REL-8; conversation/flag hooks REL-6).

---

## 1. State today (code-grounded — verified 2026-06-24f)
- **No relationship system exists.** No ranks, no relationship store, no conversations.
- **`[PXP]` engine** (resolved, unbuilt): accumulator → named `CampaignRules` rank profile
  (ordered `{name, threshold}`) → on-crossing triggers (`grant_skill`; vocab "extensible: stat
  unlock, flag set, etc."); gain sources `active_use`/`class_exp_share`/`per_map_carry`/
  `action_gated`. Stored per-unit in `UnitData.proficiency_xp` (keyed by track-id).
- **Adjacent bonus systems** (do not collide with relationship benefits): `PairUpBonusTable`/
  `PairUpBonusResolver` (pair-up combat bonuses), the **Charm aura** helper in `PairUpRegistry`,
  and `UnitData.active_modifiers` (the generic modifier/aura vocab).
- **Class EXP:** `Unit.add_exp` (single entry point) — 0–100 cyclic, growth-roll + promotion
  payload. Deliberately **not** rebuilt on the track engine (REL-1).

---

## 2. Resolved decisions

### [REL-1] Engine reuse — **RESOLVED: reuse the PXP resolver, not its storage; class EXP stays separate**
Relationship ranks ride the **same resolver** as proficiency (accumulator → named profile →
on-crossing triggers), so rank tiers become `CampaignRules`-authored for free. But a relationship
is an **edge between two units**, not a per-unit value — so it does **not** live in
`UnitData.proficiency_xp` (REL-2). **Class EXP is NOT rebuilt on this engine**: its threshold
payload diverges (cyclic 100-EXP thresholds + per-stat growth rolls + promotion vs ordered named
one-time ranks + triggers), it is the most-exercised progression path (protect it), and reworking it
reduces no F1 risk. The seam stays `[PXP-5]` `class_exp_share` — class EXP *feeds* progression, it
doesn't *become* it (see also REL-4 class-EXP share).

### [REL-2] Storage — **RESOLVED: complete, pair-keyed roster graph**
A **complete** relationship graph: every co-deployed pair can accrue. Stored as a **pair-keyed**
roster table (denormalized both-sides for O(1) queries, the pattern `PairUpRegistry` already uses).
Snapshots/saves with the roster; reserved in the F1 schema (REL-9).

### [REL-3] Rank model — **RESOLVED: a CampaignRules "relationship" profile**
A named rank profile (`[PXP-3]`) — authored names + thresholds (e.g. C/B/A/S). The top rank may be
exclusive (REL-8).

### [REL-4] Gain sources — **RESOLVED: three new pair-keyed source kinds**
New gain-source kinds feeding the pair-keyed accumulator (none of the per-unit PXP sources fit):
- **`co_deployment_survival`** — on map completion, every **co-deployed surviving pair** gains a flat
  amount. (Pair-keyed variant of `per_map_carry`.)
- **`end_turn_proximity`** — at **player-phase end**, each pair within radius **R** gains
  `f(distance)` — **closer = more**, with **pair-up or rescue counting as distance 0 (max)**. R, the
  falloff curve, and the max are `CampaignRules` knobs.
- **`class_exp_relationship_share`** — when a unit gains class EXP (`Unit.add_exp` hook), qualifying
  edges gain a **flat or % of the class EXP**. Uses the **same proximity machinery** as
  `end_turn_proximity` but with **independent knobs** (own radius/curve/toggle).

### [REL-5] Anti-grind — **RESOLVED: per-map cap**
A `CampaignRules` **max-points-per-pair-per-map** cap. Prevents farming via parked-adjacent units
passing turns (end-of-turn proximity is otherwise farmable by design).

### [REL-6] On-crossing — **RESOLVED: extend the PXP trigger vocab; conversations optional**
Crossing a threshold fires PXP on-crossing triggers; relationship adds verbs **`unlock_conversation`**
and **`set_flag`** to the `[PXP-4]` vocab. The graph is complete but **conversations are sparse,
optional authored hooks** — a crossing only plays a scene where an author wrote one.

### [REL-7] Benefit payload — **RESOLVED: per-unit directional, rank-scaled, proximity-gated aura**
Each unit authors a **list of benefits it confers to everyone it has a relationship with**
(**directional + per-unit** — A grants A's list to its partners, B grants B's; sidesteps FE pairwise
affinity tables). Benefits:
- **Vocab:** authored entries against the existing modifier/aura vocab (`UnitData.active_modifiers`,
  Charm-aura machinery) — not a new payload type.
- **Range:** **proximity-gated aura** — applies only while the partner is within range, **reusing the
  same radius primitive** as REL-4 (one primitive now powers proximity gain, class-EXP share, AND the
  benefit aura).
- **Scaling:** **by rank** (authored per-rank values; none at rank 0, growing C→B→A→S).
- **Stacking:** a **separate, independently-stacking** source — does **not** feed or replace the
  pair-up bonus or Charm. (Three distinct sources may co-apply; see REL-9 reconciliation.)

### [REL-8] Top-rank exclusivity — **RESOLVED: exclusive top rank, authored toggle**
A unit may hold the **top rank with only one partner** (the FE "S-rank/marriage" slot); reaching the
top elsewhere is blocked at the cap below. Whether the top rank is exclusive is a **`CampaignRules`
toggle** (campaigns without romance disable it). **Avatar (#20) hooks this slot** — confirm in that
walk.

### [REL-9] PXP-build dependency + schema + reconciliation — **RESOLVED: hand the unbuilt PXP build a requirement**
- **PXP-build requirement:** make the threshold/profile/trigger **resolver pair-agnostic**; add the
  REL-4 **gain-source kinds** and the REL-6 **on-crossing verbs**. Reconcile-don't-break (the default
  weapon profile is unaffected).
- **F1 reservation:** the pair-keyed relationship graph (REL-2), the per-pair per-map gain counters
  (REL-5), and the `CampaignRules` relationship profile + gain knobs + exclusivity toggle. Reserve in
  the Phase-B F1 lock once the sweep completes.
- **Bonus-source reconciliation:** relationship benefit (REL-7), pair-up bonus, and Charm are **three
  independent stacking auras**. Decided independent here; balance of multi-relationship aura stacking
  is a tuning forward-surface, not a blocker.

---

## 3. Forward surfaces (authoring/tuning, not open decisions)
- Exact proximity falloff curve shape (linear vs stepped) — a `CampaignRules` knob, set at authoring.
- Multi-relationship aura-stacking balance (a well-bonded army gets many auras) — tune via per-rank
  benefit magnitudes + the proximity radius.
- Non-combat relationship gain avenues (e.g. base/hub conversations) — later growth, ride REL-6.

## 4. Notes
- **Naming:** "relationship" throughout; `support`/`ROLE_SUPPORT` remain the pair-up combat role.
- **A3 hand-off:** Avatar (#20) uses REL-8 exclusivity + the conversation hook; Recruit/Capture
  (#4 ⇄ A4) uses REL-6 `set_flag`/`unlock_conversation` for support-gated recruitment, with the
  conversation/MET side firmed in the A4 pass.
- **DoD:** GDD section + roadmap flip + `check_docs.py` profile/field checks land **with the build**
  (per the `[PXP]` staged-build DoD), not at firming time.
