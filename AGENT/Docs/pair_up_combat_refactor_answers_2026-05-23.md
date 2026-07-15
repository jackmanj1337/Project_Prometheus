# Pair Up Combat Refactor — Answers (2026-05-23)

Companion to `pair_up_combat_refactor_questions_2026-05-23.md`. These answers
are the agreed inputs for the upcoming Pair Up / combat-context implementation
pass.

## Answers

### 1. Pair Up unit model
**Central `PairUpRegistry` autoload** maps `unit_id -> { partner_id, role }`.
- Single source of truth; no two-sided unit-field sync.
- Snapshot/restore serializes the registry directly.
- Units stay clean; AI and UI query the registry.

### 2. Map-state behavior outside combat
**Lead-only on map.** While paired:
- `support.tile = null` (support is off-grid).
- Targeting, AoE, pathing, and occupancy only see the lead.
- Support's full state (HP, items, statuses) is preserved.
- Open implementation note: pick "filter `tile == null`" vs. a separate
  `active_units_on_map` list when implementing.

### 3. Pair Up action flow
First implementation pass ships:
- **Pair Up (create)** — adjacent ally action, initiator becomes lead.
- **Separate** — paired lead's menu places support on an adjacent free tile;
  both end turn (Awakening behavior).
- **Swap roles** — lead and support trade roles without separating.

Deferred:
- **Shift** (transfer support to a different adjacent ally) — pass 2+.

### 4. Combat preview responsibilities
Forecast in pass 1 must show:
- Deterministic stat bonuses from the support unit (totals and breakdown).
- Dual Strike / Dual Guard activation chances (DS/DG land in pass 1 — see Q6).
- Support identity (portrait + name) so players can see *who* contributes.

Not in pass 1 forecast:
- Weapon-triangle / class-trait conditional modifiers from support (no such
  effects in design today).

### 5. Pair Up stat-bonus source
**Hybrid resolver:**
- `PairUpBonusTable` `.tres` resource provides a flat StatBlock per support class.
- Resolver adds a small scaling term derived from the support unit's live stats.
- Both preview and live combat call the same resolver function — single source
  of truth, no divergence.

### 6. Dual Strike / Dual Guard rollout order
**Both DS and DG land in pass 1.** Consistent with the forecast scope in Q4.
- Requires DS activation-chance formula decided before implementation.
- Requires DG damage-interrupt timing hook decided before implementation.
- Treated as stateless per-attack probability (no cooldown state — see Q8).

### 7. AI expectations
**AI-safe baseline only.**
- AI correctly handles paired *targets*: combat math, DS/DG resolution, forecast
  all work when AI attacks a paired player unit.
- AI's own units stay unpaired in pass 1.
- AI initiation, separation, and swap deferred to a later pass.

### 8. Save / snapshot behavior
Pass 1 snapshot persists:
- `PairUpRegistry` full table (unit_id -> { partner_id, role }).
- Support-unit `tile == null` markers, so restore does not place support units
  on the map.
- Per-turn "Pair Up / Separate / Swap performed this turn" action flag per unit
  (prevents reload from granting a free action).

Not persisted (no state to keep):
- DS / DG activation flags — stateless per-attack probability.

### 9. UI scope for the first pass
All four surfaces:
- Action menu — Pair Up / Separate / Swap entries with context-sensitive
  visibility.
- Unit details — partner, role, resolved bonus block (from Q5 resolver).
- Combat preview — items listed in Q4.
- Cursor / map HUD — visible paired-lead indicator (icon overlay or portrait
  stack) so pairings are visible without opening a menu.

### 10. Skill handling policy during transition
Status assignments for Pair Up-adjacent skills in the GDD:

| Skill | Status in pass 1 | Notes |
|---|---|---|
| Dual Strike+ | ready | Authored as DS rate modifier; DS mechanics live in pass 1. |
| Dual Guard+ | ready | Authored as DG rate modifier; DG mechanics live in pass 1. |
| Dual Support+ | disabled intentionally | Bonus-block modifier; deferred to pass 2. |
| Veteran | disabled intentionally | EXP modifier while paired; deferred. |
| Solidarity | disabled intentionally | Stat bonus while paired; deferred. |
| Deliverer | disabled intentionally | Movement modifier while paired; deferred. |

No currently-authored `.tres` skill is Pair Up-dependent, so no skill needs a
*temporary alternate effect*. Deferred skills should be left unauthored or
explicitly marked disabled in their resource until pass 2.

**Aura interaction rule (Charm and any future tile-distance aura):**
- While paired, the support unit is treated as occupying the lead's tile for
  proximity / aura checks.
- Implemented once in a shared "effective tile for proximity" helper so all
  aura skills follow the same rule.

## Implementation order (carried forward from questions doc)
1. Define `PairUpRegistry` autoload and snapshot format (Q1, Q8).
2. Add campaign settings and validators for Pair Up enable/disable.
3. Refactor combat context to include lead/support data cleanly (Q1, Q4, Q5).
4. Implement Q5 resolver (table + scaling formula); call site shared between
   preview and live combat.
5. Implement Q4 preview surface (stat bonuses, DS/DG %, support identity).
6. Wire on-map Pair Up, Separate, Swap actions (Q3) and per-turn action flag.
7. Implement DS and DG resolution in live combat (Q6).
8. Implement AI-safe handling for paired targets (Q7).
9. Implement UI surfaces: unit details, action menu, map HUD indicator (Q9).
10. Author Dual Strike+ and Dual Guard+ `.tres` skills; document the four
    deferred skills as intentionally disabled (Q10).
11. Add proximity-aura "effective tile" helper for Charm-style skills (Q10).

## Open items to settle during implementation (not blocking)
- Exact DS activation-chance formula.
- Exact DG damage-interrupt formula and timing hook.
- Exact PairUpBonusTable contents per class (balance pass).
- Scaling-term formula for Q5 hybrid resolver.
- "Filter `tile == null`" vs. dedicated `active_units_on_map` collection (Q2).
