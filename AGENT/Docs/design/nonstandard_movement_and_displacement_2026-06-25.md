---
Type: design
Status: Active framing / driver
Last verified: 2026-06-25
---

# Non-Standard Movement & Displacement — Player Flow & Authoring Surface

**Started:** 2026-06-25 (session 2026-06-25e/f). A2 displacement sub-cluster.
**Status:** Active framing / driver — the **player-facing edge-case rulings** and the **designer
authoring surface** for every way a unit's position changes **outside the regular move action**.
**Navigation/illustration, NOT a second spec** (per DOC-005 the authoritative decisions live in
`registers/displacement_carry_open_questions_2026-06-25.md` `[DSP-1..16]`). Where a rule has an ID,
it is cited; this doc adds no rulings of its own.

---

## 1. Why one framework
"Move a unit without a normal move action" shows up in many features — rescue/carry, shove/swap/pivot/
smite, Warp/Rescue staves, Dance-granted moves, trap/event repositioning, terrain collapse. Rather than
each feature inventing its own rules, **all of them resolve through one `DisplacementService`**
(`[DSP-1]`) and obey **one shared ruleset**. This doc is the map of that ruleset for players and authors.

## 2. Taxonomy — position change outside the regular move action

| # | Category | Player-facing examples | Substrate |
|---|---|---|---|
| 1 | **Self, post-action** | Secondary Movement (move after acting) | F10 skill (`[SMV]`) — *is* a move, second window |
| 2 | **Cooperative** (move an ally) | Rescue pickup · Drop / Give / Take · Shove/Swap an ally · Dance-granted move · Warp / Rescue staff | DSP carry · `displace` effect · STY `teleport`/`fetch` |
| 3 | **Forced** (move a foe) | Knockback · Smite · pull / draw-in · Capture pickup | `displace` effect · DSP carry |
| 4 | **Reactive / out-of-turn** | An enemy gambit shoves you on enemy phase · on-hit knockback that fires on a counter · a "shove the attacker" reaction skill | `displace` on any phase (`[DSP-12]`) |
| 5 | **Environmental / system** | Trap / warp tiles · MET event repositioning · terrain collapse (DTR) under a unit | tile/event calls `DisplacementService` |
| 6 | **Negation** | Sleep/stun (can't move) · `immobile` (immune to *being* moved) | F5 conditions (`[DSP-13]`) |

Category 4 is the "out of turn" half; categories 2–6 are the "without a move action" half.

## 3. The shared invariants (`[DSP-15]`)
1. **Atomic & discrete** — happens *between* actions, never mid-path; resolved instantly.
2. **Action-economy neutral** — a non-standard position change neither spends nor restores the moved
   unit's action (the engine's existing *teleported-but-still-READY* state). Shoved-before-acting still
   acts; shoved-after-acting stays done; being carried doesn't cost the carried unit's action.
3. **Destination default-valid, author-overridable** — by default the destination must satisfy the
   **moved** unit's own `is_passable` / movement-type / occupancy rules (walls block; a non-flier can't
   be dropped where it couldn't stand). An author MAY opt a specific displacement into placing a unit on
   normally-illegal terrain (`force_onto_invalid`, `[DSP-14]`) — the one sanctioned way to create an
   "illegal" placement, with defined consequences.
4. **Forced entry == normal entry for tile consequences** — a unit arriving by force obeys exactly the
   tile rules a unit that *walked* there would. On-entry terrain effects apply; **action-gated
   objectives (Seize/Escape are `TileActions`, not auto-triggers) never fire from being placed.** No
   forced-movement-specific objective exemptions.
5. **Phase-agnostic mechanic** — the same primitive runs on any phase; *who may invoke it off-turn* is
   author-gated (`[DSP-12]`), and off-turn displacement **never interrupts an in-progress exchange**.
6. **Undo parity** — your own pre-confirm displacement/carry undoes like a move; an opponent's forced
   movement of your units does not.

## 4. The resolution pipeline (author-composable; `[DSP-13]`/`[DSP-14]`)
A `displace` resolves in stages. Each stage is **optional and author-configured** — a plain shove uses
none of the resistance stages and the `fail` destination outcome.

```
displace(target, mode, distance) →
  ┌ RESISTANCE  (any subset; [DSP-13]) ───────────────────────────────┐
  │  a. immobile tag?  → blocked, unless effect has ignores_immobile    │  deterministic
  │  b. static stat contest?  → potency vs target weight/Con            │  deterministic
  │  c. accuracy roll?  → to-hit % like an attack (RngService)          │  stochastic
  └────────────────────────────────────────────────────────────────────┘
        │ passes
        ▼
  compute destination tile (mode: push/pull/swap/to_side/blink, distance)
        │
  ┌ DESTINATION HANDLING  (non-exclusive set; [DSP-14]) ───────────────┐
  │  blocked/occupied/impassable → one or more of:                      │
  │    • fail            (no move — default)                            │
  │    • collision_damage(scaled by terrain hardness / occupant)        │
  │    • chain_push      (the blocker is displaced too)                 │
  │    • force_onto_invalid (place on normally-illegal terrain)         │
  └────────────────────────────────────────────────────────────────────┘
        ▼
  DisplacementService.relocate(target, dest)  → on-entry tile effects (invariant 4)
```

- **Resistance stages stack:** an author can require *all* of tag-immunity + a stat contest + an
  accuracy roll, or any one of them, or none. Stages a/b are deterministic; only the accuracy roll
  touches `RngService` (so most displacement stays deterministic, easing preview + replay).
- **Distance under resistance** (build-detail option): a stat contest may **reduce** distance (a heavy
  unit gets shoved 1 instead of 2) rather than only binary-block — reserved on the payload.

## 5. Player-facing edge-case rulings (worked examples)
- **Shove an enemy onto a hazard tile** → the hazard's on-entry effect applies (invariant 4). Shoving a
  foe into a fire tile burns them — a real tactic.
- **Shove a foe toward a wall / off the map** → default `fail` (invariant 3 / `[DSP-14]` default). An
  author can instead grant that source `collision_damage` (smite-into-wall) or `force_onto_invalid`
  (knock into deep water → stranded + hazard) — opt-in, per displacement source.
- **Shove/Warp a unit onto an Escape tile** → nothing auto-happens; the unit must still spend its
  Escape action (invariant 4). No "shove an ally to the exit to win."
- **A unit that already acted is shoved/swapped/rescued** → it moves; it stays *done* (invariant 2). No
  action is refunded.
- **An enemy gambit knocks your unit back on enemy phase** → allowed (`[DSP-12]`); your unit still gets
  its full next turn (invariant 2). It is not undoable (invariant 6).
- **A counter from a knockback weapon** → the knockback fires as an on-hit effect *after* the exchange
  resolves; it never cancels the attack or denies the counter (`[DSP-12]`).
- **Drop a carried unit** → must be a tile valid for the **dropped** unit's movement type (a flier can
  carry a foot unit over water but must drop it on land); adjacent, in the F10 window (`[DSP-6]`).
- **Carrier defeated while carrying** → carried unit drops to an adjacent valid tile; capture's
  `sleep`-wake rules then apply (`[DSP-5]`).
- **Pull/draw-in an enemy off a defensive tile** → legal; it loses that tile's terrain bonus by
  standing elsewhere. (No mid-exchange interrupt — see `[DSP-12]`.)

## 6. Author-lever catalog
| Lever | Where | What it controls |
|---|---|---|
| **carry profile** | F4 `CampaignRules` (`[DSP-4]`) | capacity stat, weight stat, while-carrying penalties |
| **`displace` payload** | source/style `EffectSpec` (`[DSP-7]`) | mode (`push/pull/swap/to_side/blink`), distance/potency, direction source |
| **resistance stages** | per-effect (`[DSP-13]`) | `immobile` tag · `ignores_immobile` bypass · static stat contest · to-hit accuracy |
| **destination outcomes** | per-effect (`[DSP-14]`) | non-exclusive set: `fail` · `collision_damage` · `chain_push` · `force_onto_invalid` |
| **off-turn eligibility** | per source/skill (`[DSP-12]`) | whether this displace may fire on enemy phase / as a reaction |
| **`target_filter`** | per-effect (`[STY-17]`) | ally-shove vs enemy-knockback |
| **F10 second-move eligibility** | per skill (`[SMV]` `secondary_move_actions`) | whether the displacing action opens a post-move window |

## 7. Build staging (recommended v1 slice; `[DSP-13]`/`[DSP-14]`)
Design reserves the **full** composable surface; the **v1 build** ships the safe, deterministic subset
and graduates the rest as author levers later:
- **Resistance v1:** `immobile` tag + `ignores_immobile` bypass (binary, deterministic). **Reserve**
  the static stat contest and the to-hit accuracy (the latter is the only piece that adds an RNG path —
  it reuses `RngService` + the combat hit calc when it lands).
- **Destination v1:** `fail` only. **Reserve** `collision_damage`, `chain_push`, `force_onto_invalid`.
This keeps v1 free of new RNG/board-legality complexity while the authoring surface is fully designed.

## Cross-refs
`[DSP-1..16]` (authoritative) · `[STY-7/10/16/17]` (effect axis + preview + relationship matrix) ·
`[SMV]` (F10 window) · `[RCR-5]` (capture carry) · F4 `CampaignRules` · F5 `ConditionManager` ·
`RngService` (the accuracy stage) · Pair-Up `OFF_MAP_TILE` (carry attach).
