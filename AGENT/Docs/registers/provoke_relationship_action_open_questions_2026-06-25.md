---
Role: dated
Type: register
Status: RESOLVED 2026-06-25p
Last verified: 2026-06-25
Register: PRV-1..7
Resolved-in: 2026-06-25p
---

# Provoke / Runtime Faction-Relationship MET Action (`[STY-17]` transition side, A4) — Player-Facing Design + Open Questions

**Started:** 2026-06-25p (third A4 sub-cluster, after Village `[VIL]` and Recruit conversation `[RCV]`).
**Status:** [PRV-1..7] **RESOLVED 2026-06-25p** (end-shape-first; all owner calls taken).
**A4 — Story / event-driven map content.** `[STY-17]` (A1) firmed the **directed 3-state relationship
matrix** + resolver and **reserved a runtime override store**, explicitly handing A4 the **transition
mechanism**: a `[MET]` action that changes a relationship at runtime, plus a reactive AI "provoke."
This pass firms that transition primitive + its two callers. **`[STY-17]`'s matrix/resolver and the
authored-data side are NOT relitigated.**

**Method (owner pref `feedback_feature_walk_end_shape_first`):** end-shape via questions first.
Owner calls (2026-06-25p): granularity = **faction-pair + per-unit override**; persistence =
**map-local default + campaign option** (mirrors F6); reactive provoke = **pin the hook here as a
shared primitive** (MET action + a `provoke_on_attacked` flag are its two callers).

**Source:** `[STY-17]` "dynamic provoked transitions — owned by A4 + AI (pinned 2026-06-25c)" + its
F1 "reserve a runtime faction-relationship-override store"; the atlas A4 bullet.

**Code grounding:** `GameState.are_hostile(a,b)` is today **binary + symmetric** over a runtime-mutable
`_alliance_groups` dict (populated from `MapData.factions`). `[STY-17]` upgrades this to directed
`relationship(from,to) ∈ {hostile|neutral|allied}` with `are_hostile()` a shim. `FactionData` carries
`alliance_group`/stance authoring. MET (`[MET-1..9]`) owns the action runner + deferred-safe-point
timing; `set_ai` (`[MET-3]`/`[AIP-8]`) is the precedent for an event-driven faction-state action.

---

## Verdict

> **One runtime transition primitive, two callers.** `[STY-17]` owns the matrix + resolver + authored
> data; **PRV owns the runtime override store + a single `set_relationship(from, to, stance, scope)`
> primitive.** The **`set_relationship` MET action** (scripted) and a reactive **`provoke_on_attacked`
> stance flag** (combat-reactive) are its two callers — not two mechanisms. The store has **two layers
> (faction-pair edges + per-unit overrides)** and **two scopes (map-local default + campaign)**.

---

## Register

### [PRV-1] One `set_relationship(from, to, stance, scope)` primitive  **[RESOLVED]**
PRV owns the runtime transition primitive that writes the `[STY-17]`-reserved override store; the
resolver reads it. `[STY-17]` keeps the matrix + `relationship()` resolver + authored data. Both
provoke sources (PRV-3 action, PRV-4 reactive flag) call this one primitive — **no parallel path.**
- **Resolution:** RESOLVED 2026-06-25p — single primitive; STY-17 owns matrix, PRV owns transitions.

### [PRV-2] Granularity = faction-pair edges + a per-unit stance override layer  **[RESOLVED]**
The override store has **two layers**, checked in order by an extended resolver:
1. **per-unit override** (a specific unit's stance toward a faction differs from its own faction's),
2. **runtime faction-pair override** (directed edge), then
3. the `[STY-17]` authored matrix, then the alliance-group default.
So "the one villager I attacked turns hostile while the rest of green stays neutral" = a per-unit
override. **Resolver extension:** `[STY-17]`'s faction-keyed `relationship(from,to)` gains a
**unit-aware entry** `relationship_for(actor_unit, target)` that checks the per-unit layer first then
falls back to the faction resolver. (Extends STY-17's resolver signature; does not relitigate it.)
- **Resolution:** RESOLVED 2026-06-25p — faction-pair + per-unit layers; unit-aware resolver entry.

### [PRV-3] The `set_relationship` MET action (scripted caller)  **[RESOLVED]**
Params: `{ from, to, stance ∈ {hostile|neutral|allied}, scope ∈ {map|campaign}, target: faction-pair
| unit, mutual?: bool }`. **Directed by default** (sets the `from→to` edge only, per the directed
matrix); `mutual:true` is a convenience that sets both directions. **Trigger-agnostic** — runs from
any MET trigger (`turn_reached`, `flag`, `talk`, `unit_died`, village Visit) like other actions; runs
at the deferred safe point (`[MET-8]`). Joins the MET action vocabulary alongside `set_ai`.
- **Resolution:** RESOLVED 2026-06-25p — directed `set_relationship` action; `mutual` convenience;
  faction-pair or unit target; trigger-agnostic.

### [PRV-4] Reactive `provoke_on_attacked` stance flag (combat-reactive caller)  **[RESOLVED]**
A `neutral` faction/unit may carry **`provoke_on_attacked`**: when one of its units is attacked by
faction X, it calls `set_relationship(self → X, hostile, map)`. A **per-unit vs whole-faction** authoring
choice picks whether attacking one neutral unit provokes **just that unit** (per-unit override — the
lone-villager case, default for individual NPCs) or **its whole faction** (default for armies). **Pin
the flag + the hook now**; the full AI *initiate/target* behavior firms with the AI pass — this register
reconciles `[STY-17]`'s "AI provoke" as a **caller of PRV-1**, not a separate system.
- **Resolution:** RESOLVED 2026-06-25p — reactive flag is a second caller of the primitive; per-unit
  vs faction provoke is authorable; AI behavior firms with the AI pass.

### [PRV-5] Stance values = the full 3-state set (not just →hostile)  **[RESOLVED]**
The action/primitive sets any of `hostile | neutral | allied` — provoke (`→hostile`) is the common
case, but it also expresses "make peace" (`→neutral`/`allied`) and "a faction joins mid-battle"
(`→allied`). **Counterattack vs stance stays the `[STY-17]` lean:** being attacked triggers a counter
**regardless** of stance (self-defense); stance only gates whether a unit *initiates*.
- **Resolution:** RESOLVED 2026-06-25p — general 3-state set; counter-regardless-of-stance retained.

### [PRV-6] Persistence/scope = map-local default + campaign option (mirrors F6)  **[RESOLVED]**
Most runtime changes are **map-local** (snapshot with the map save, reset next map); a **`campaign`**
scope persists across maps ("the kingdom declares war", in the campaign save). Mirrors the F6 two-scope
flag model. **F1 reserve:** the runtime faction-relationship-override store with **both scopes** AND
**both layers** (faction-pair + per-unit). This firms `[STY-17]`'s "reserve a runtime override store"
into a concrete two-scope, two-layer shape.
- **Resolution:** RESOLVED 2026-06-25p — map default + campaign option; F1 reserves both scopes ×
  both layers.

### [PRV-7] AI re-evaluation timing  **[RESOLVED]**
`EnemyAI` already reads `relationship()` per activation (a `[STY-17]` consumer); a mid-map flip is
picked up on the **next activation**, exactly like the `set_ai` action. No new mechanism — the action
runs at the MET deferred safe point, the AI sees fresh stance next time it plans.
- **Resolution:** RESOLVED 2026-06-25p — fresh read per activation; no new re-eval machinery.

---

## Reconciliation note — provoke (stance) vs recruit (team)
These are **distinct axes**, not to be conflated: **recruit** (`[RCR-1]`) flips a unit's **`team`**
(which faction it belongs to → persistent roster); **provoke** changes the **relationship stance**
between factions (or a unit's per-unit override) — a provoked neutral villager keeps its faction but
becomes hostile. Different store, different save surface.

## F1 schema-lock reservations (this register)
- The **runtime relationship-override store**: a faction-pair-edge layer **+** a per-unit-override
  layer (PRV-2), each in a **map scope** (snapshots with the map) **and** a **campaign scope** (PRV-6).
- Authoring (not save): the `provoke_on_attacked` flag + its per-unit/faction granularity choice
  (PRV-4); `set_relationship` action params (PRV-3).

## Cross-references
- Consumes / extends: `[STY-17]` (matrix + resolver — extended with a unit-aware entry, not
  relitigated), F1 (runtime-override store reserve, now concretized), `[MET-1..9]` (action runner +
  deferred timing), `set_ai`/`[AIP-8]` (event-driven faction-state precedent; AI provoke firms with
  the AI pass), F6 (two-scope persistence mirror).
- Distinct from `[RCR-1]` recruit `team` flip (see reconciliation note).
