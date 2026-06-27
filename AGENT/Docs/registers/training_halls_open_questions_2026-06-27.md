---
Type: register
Status: RESOLVED 2026-06-27
Last verified: 2026-06-27
Register: THL-1..7
Resolved-in: 2026-06-27d
---

# Training Halls (#19) — Character-Investment Prep Service — Player-Facing Design + Open Questions

**Started:** 2026-06-27 (session 2026-06-27d). The pre-F1 sweep item #19 (a `[PVP-3]` build dependency +
persistent per-character state). A **PHB prep service** where a character **spends resources for
NON-TRANSFERABLE per-character benefits** (class XP · weapon XP · stat bonuses · skills · other effects).
The **proficiency-XP slice is already firmed (`[PXP-9]`)**; this walk generalizes it to **all** benefit
types — almost entirely **reuse**. Branch `docs-reorg-2026-06-23`. Legend: **[OPEN]** / **[RESOLVED]**.

---

## Substrate reality
- **`[PXP-9]` RESOLVED** the container + offer pattern: a **PHB option panel** with per-entry
  `{track, xp_amount, cost}` spending resources → `advance_proficiency`. Training-hall = that, generalized.
- **No permanent stat-gain mechanism exists** (only temporary modifiers) → the **stat purchase is the one
  new operation** (also the missing FE stat-booster primitive).
- **F7 per-unit pools** (`[CEX-1..4]`, RESOLVED) + the **gold ledger** (`party_gold`) + `[TCV]` custom
  variables already provide the resource substrate.

---

## [THL-1] Container & offer model — **RESOLVED**
A **PHB opt-in prep panel** (`[PHB]`), on-map-placeable via the `[SAC]` dual-surface. Generalize `[PXP-9]`'s
entry to an **offer = `{benefit_type, params, cost, gate?, cap?}`**. One uniform panel, many benefit
types. (One of the queued hub-option panels alongside shop/arena.)

## [THL-2] Benefit types route to existing systems (reuse) — **RESOLVED**
Each benefit grants via the system that already owns it — **NON-TRANSFERABLE, baked into `UnitData`** (not
items/convoy):
- **`class_xp` / level** → `Unit.add_exp` (the **same mechanism as Bonus-EXP `[BEA]`** — one "buy EXP"
  path, two panels).
- **`weapon_xp` / proficiency** → `[PXP-9]` `advance_proficiency` (firmed).
- **`stat`** → the new permanent stat-gain primitive (`[THL-3]`).
- **`skill`** → add to `earned_skills`, equip via the `[LDC]` cap.
- **`other_effects`** → author-composed effects (the `[STY]`/effect vocabulary, or a granted source) —
  open-ended, reuses the effect system.

## [THL-3] Stat purchase = a shared permanent stat-gain primitive — **RESOLVED**
**Owner:** a **new shared `apply_permanent_stat_gain(stat, n, cap)`** raising the **stored** stat
(base / `extra_stats` per `[STM]`), **capped** by an authored training cap (**default = the class stat
cap**). **The SAME primitive backs FE-style stat-booster items** (Energy Drop) — so training-hall unlocks
stat-boosters for free. Permanent + baked (not a removable modifier).

## [THL-4] Resource model = author-defined, two scopes (roster-shared + per-unit) — **RESOLVED**
**Owner (expanded):** training costs draw from **author-defined resources at two scopes**:
- **Roster-shared** — a **party multi-resource wallet**: `gold` (`party_gold`, exists) **+ author-defined**
  (e.g. *professor / activity points*). **Extends `[SHP-1]`'s resource-keyed cost** (which deferred
  "resources beyond `party_gold` … added when a system needs them, e.g. training points" — *this* is that
  system).
- **Per-unit** — the **F7 pools** (`[CEX-1..4]`): e.g. *motivation points*, stamina.
A cost references resource(s) by **`{id, scope}`** and draws from the party wallet or the unit's pool.
Reuses F7 pools + the gold ledger + `[TCV]` (custom resource declaration). **General capability** (not
training-only): any system can charge a roster or per-unit resource.

## [THL-5] Caps & gating — reuse — **RESOLVED**
Per-offer **F16 `[REQ]` gate** (class / level / flag / trait to unlock an offer — reuse). **Purchase
limits = the PHB `one_shot`/`restock_every_n` cadence + an optional author per-offer cap** (e.g. "this
stat-up buyable 3× per unit"); the **resource cost is the main limiter** (`[THL-1]` `cap?`).

## [THL-6] Save / F1 schema reserve — **forward to Phase B (F1 lock)**
Reserve: the **roster multi-resource wallet** (`party_gold` → a `{resource_id: amount}` dict) +
**per-offer purchase counts** (only if author caps used). The **baked stat gains** ride `[STM]`
`extra_stats`/base (already reserved); per-unit pools ride F7 (reserved); proficiency/skill grants ride
already-reserved fields. So the **only new save surface = the party resource wallet + optional purchase
counts**.

## [THL-7] Composition / cross-refs — **RESOLVED**
`[PHB]` (container) + `[SAC]` (on-map placement) · `[PXP-9]` (weapon XP) · `[BEA]`/`add_exp` (class XP) ·
`[STM]` (stat — `[THL-3]` primitive, shared with stat-booster items) · `[SKL]`/`[LDC]` (skill) · **F7
pools `[CEX-1..4]`** + gold ledger + `[TCV]` (the two-scope resource model) · `[REQ]` (gates) · `[PVP-3]`
(the buy-phase consumer this unblocks).
