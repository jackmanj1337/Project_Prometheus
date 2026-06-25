---
Type: register
Status: OPEN
Last verified: 2026-06-25
Register: DSP-1..11
Resolved-in: 2026-06-25e (DSP-1..5,7 resolved; DSP-6,8,9,10 leans; DSP-11 reserve)
---

# Displacement & Carry — Shared Spatial Primitive (rescue · capture-carry · shove/swap/pivot)

**Started:** 2026-06-25 (session 2026-06-25e). First sub-cluster of **A2 — Map action-economy &
movement assists** (owner call 2026-06-25e: *displacement primitive first*, mirroring A1's
foundation-first split). Branch `docs-reorg-2026-06-23`.

**Thesis.** Three A2 agenda items — **Rescue (#6/H3)**, **Capture carry/jail/release (`[RCR-5]`)**, and
**Movement assists (#17: shove/swap/pivot/smite)** — are all *relocate-a-unit* operations. They share
**one occupancy-mutation primitive** and either the **carry** state (rescue, capture) or the **push**
displacement rule (shove/swap/pivot/smite). This register firms that shared foundation so the three
features do not each grow their own occupancy/displacement code. The remaining A2 sub-clusters
(**action-grant / Dancer**, **battalion entity `[STY-11]`**) are separate passes.

**Code-grounded substrate.** Pair-Up already solves "two units, one tile": `PairUpRegistry` stores a
`unit_id -> {partner_id, role}` map and sets the support unit's `tile_position` to a negative-coord
`OFF_MAP_TILE (-1,-1)` sentinel while paired, so only the lead occupies a real cell; it is snapshotted
with `GameState._map_start_snapshot` so Retry rewinds it. `GridManager.get_unit_at(tile)` is the single
occupancy lookup (tile-position equality), and pathfinding already respects occupants. Carry is the
same shape — the carried unit goes off-map, attached to the carrier — so DSP mirrors the proven Pair-Up
plumbing rather than inventing new occupancy state.

**Pattern:** mirrors `[CEX]`/`[STY]`/`[RCR]`/`[SMV]`. Legend: **[OPEN]** / **[RESOLVED]**.

---

## 1. State today (code-grounded)
- **Not implemented.** No `rescue`, `carry`, `shove`, `displace`, or `grant_extra_turn` in `scripts/`
  (grep clean). Pair-Up **is** built (`PairUpRegistry`, `PairUpBonusResolver`) and provides the off-map
  attach + snapshot convention DSP reuses.
- **F10 Secondary Movement** (`[SMV-1..11]`, firmed 2026-06-24a) is the post-move action window
  carry-pickup/drop and the push actions open/close; it is a parameterized **skill**, not built yet.
- **A1 `[STY]`** (design complete 2026-06-24n) provides the **`EffectSpec{kind,payload,target_filter,
  gate}`** axis and the **source `effects` set**; DSP-7 adds a **`displace`** effect kind onto it.

## 2. What this pass produced
The shared occupancy primitive (DSP-1/2), the rescue/pair-up relationship + carry gating (DSP-3/4), the
capture-carry deltas (DSP-5), the push family as a `displace` **effect kind** layerable into sources/
styles **and** exposed as standalone skill-actions (DSP-7), and the remaining detail leans (DSP-6,8–11).

---

## 3. Resolved decisions

### [DSP-1] Single occupancy-mutation primitive — **RESOLVED**
One `DisplacementService.relocate(unit, dest_tile)` (autoload/service) is the **only** path that moves a
unit between cells outside ordinary pathed movement. It validates terrain passability + occupancy
(`GridManager.get_unit_at`), writes `tile_position`, and emits the unit-moved signal. **Both** carry-drop
placement (DSP-6) and every `displace` effect (DSP-7) call it, so occupancy invariants live in one place.

### [DSP-2] Carry attach = reuse the Pair-Up off-map sentinel — **RESOLVED**
A carried unit's `tile_position` is set to the Pair-Up **`OFF_MAP_TILE (-1,-1)`** sentinel (so no tile
query returns it and it cannot be targeted/acted), with a `carrier_id ⇄ carried_id` pointer pair stored
in a **`CarryRegistry`** that mirrors `PairUpRegistry` (separate registry per DSP-3, same off-map +
snapshot convention). Snapshotted with the `GameState` map-start snapshot so Retry rewinds carries, same
as pairings.

### [DSP-3] Rescue is DISTINCT from Pair-Up, sharing the attach substrate — **RESOLVED**
(owner 2026-06-25e) Rescue is its own mechanic — **no combat bonus** (unlike a Pair-Up support's stat
contribution), **carried unit inert** (off-map, can't act/be targeted), **droppable** — but reuses the
DSP-2 off-map-attach + snapshot plumbing. **Exclusivity prior:** a unit may **not** simultaneously be in
a Pair-Up and carrying/being-carried; the two registries cross-check on entry (build-time guard). Rescue
≈ FE-classic Rescue alongside Awakening-style Pair-Up.

### [DSP-4] Carry gating = an F4 author-profile rule — **RESOLVED**
(owner 2026-06-25e) Whether A can carry B is governed by an **`CampaignRules` "carry" profile** (F4), not
hardcoded: a **capacity stat** (default Con/Aid à la FE), **weight = the carried unit's Con**, and
author-set **while-carrying penalties** (default lean: carrier cannot act and takes a move penalty while
carrying). Data-driven, matching how the flexible triangle (`[CEX-9..12]`) and pools (`[CEX-1..4]`) were
firmed. The concrete default formula is an authoring default, overridable per campaign.

### [DSP-5] Capture-carry = the rescue substrate + deltas — **RESOLVED**
(owner 2026-06-25e; settles `[RCR-5]`'s A2 hand-off) Capture reuses the **same** carry plumbing (DSP-2,
DSP-6, DSP-4 gating) with deltas: the carried unit is an **enemy** under the `[STY-6]` **`sleep`**
condition; it is **freed if the carrier is defeated** (dropped to an adjacent valid tile, then subject to
the normal `sleep` wake/tick rules via F5); and it is **delivered to the roster/jail** on map-clear via
the `[RCR]` recruited-state path. One carry engine; capture is a flavored case, not a parallel system.

### [DSP-7] Push family = a `displace` EFFECT KIND, usable as skill-actions AND layered into sources/styles — **RESOLVED**
(owner 2026-06-25e) Shove/swap/pivot/smite are **not** a separate action family. They are a new
**`displace`** kind on the A1 `[STY]` **`EffectSpec`** axis (`EffectSpec{kind:"displace", payload, …}`),
resolved by `DisplacementService` (DSP-1). It is surfaced **two ways**:
1. **Standalone skill-granted actions** — preset `SkillData` (`effect_id` carrying a `displace`
   EffectSpec), granted via the skill-grant mechanisms exactly like `[SMV]`. Player-facing presets:
   **shove** (push target 1 away), **smite** (same directional rule, **higher potency** — push 2),
   **swap** (exchange the actor's and target's tiles), **pivot** (actor relocates relative to the
   target). Smite is *shove with a distance/potency param*, not a distinct mechanic.
2. **Layered into an attack** — a `displace` EffectSpec may sit in a source's `effects` set or be added
   by a **style**, so a weapon can `strike + displace` (knockback) or a style can bolt a shove onto an
   attack. This rides the existing `[STY]` `select → combined preview → re-derived targeting → resolve`
   pipeline and the **effect-forecast preview** (`[STY-10]`); `target_filter` (`[STY-17]` matrix) picks
   ally-shove vs enemy-knockback.
- **`payload`** carries the displacement **mode** (`push | pull | swap | to_side`), **distance/potency**,
  and **direction source** (away-from-actor / actor-facing — 4-way v1, matching `[STY-9]`).
- **Cross-cutting:** this **extends A1's `EffectSpec.kind`** with `displace` (the same kind of
  deliberate A1 touch as the F5 pull-forward). Recorded as an A1→A2 amendment (see Notes).

---

## 4. Detail leans (firm at build unless a fork emerges)

### [DSP-6] Drop / Give-Take handoff through the F10 window — **[LEAN]**
Drop places the carried unit on an **adjacent valid tile** (via DSP-1), inside the **F10 post-move
window** so a carrier can move-then-drop. **Give/Take** handoff between two adjacent carriers is
supported (FE Rescue→Take→Drop chain). Drop range / whether you may drop onto your own vacated tile →
build detail.

### [DSP-8] Push collision = blocked, no chain v1 — **[LEAN]**
A `displace` whose destination is impassable or occupied **fails** (the action/effect is not offered, or
the displace component no-ops while the rest of the attack resolves). **No chain-collision or
collision-damage v1** (matches FE). Collision damage = a later growth on the `displace` payload.

### [DSP-9] Action economy × F10 — **[LEAN]**
A standalone carry-pickup, a drop, and a standalone push skill **each cost the unit's action** (like an
attack). When `displace` is an **attack effect** it rides the parent attack's action (**no extra cost**),
consistent with `[STY-8]` "a style is the attack." The F10 second-move window opens per the acting
skill's `secondary_move_actions` config — same rule as `[SMV]`.

### [DSP-10] Forced-move landing effects — **[LEAN]**
Landing-tile **terrain/trap** effects apply to a displaced or dropped unit (so shoving an enemy onto a
hazard is a real tactic). **ZoC / attack-of-opportunity** on forced movement is **deferred** (no ZoC in
the engine yet).

## 5. Save / F1 reservations  *(reserve at the Phase-B lock)*
### [DSP-11] — **[RESERVE]**
- **`carrier_id` / `carried_id` pointer pair** per unit (mirrors the Pair-Up partner pointer) + the
  `CarryRegistry` snapshot.
- **Captured/jail state** — coordinate the reserve with `[RCR]` (roster) + `[STY-6]` `sleep` + **F5**
  conditions + the `[STY-12]` active-conditions reserve (don't double-reserve `sleep`).
- The **`displace` EffectSpec** is **source/style data-def, not save state** (like `[STY]` `effects`).

---

## Out of scope for DSP (other A2 sub-clusters)
- **Dancer / refresh (#8)** + the M10 `grant_extra_turn` substrate → the **A2 action-grant** pass.
- **Battalion entity (`[STY-11]`)** — data model, endurance, passive `StatContributions`, leveling,
  adjutant/pair-up variant → the **A2 battalion** pass.
- **A1 leans pointing at A2:** `[STY-8]` battalion action-economy edge-cases, `[STY-17]`
  counter-vs-stance → settle with the relevant A2 sub-cluster (battalion / action-grant).

## Notes
- **A1 amendment (DSP-7):** A1's `[STY]` `EffectSpec.kind` enum gains **`displace`**. Note it against
  `[STY-16]` (multi-effect combos) when DSP graduates, so the A1 build picks it up.
- **DoD (at build):** GDD_02 (combat/displacement) + GDD_05 (skills/`StyleDef`/effect kinds) + the
  carry/rescue UX, the `CampaignRules` carry profile (F4), `DisplacementService` + `CarryRegistry` +
  tests, and the GDD_10 roadmap status flip — all **with the build**.
- **Cross-refs:** `[RCR-5]` capture-carry (settled here) · `[STY-6]` `sleep` · `[STY-9]` AoE/direction
  vocab · `[STY-10]` effect-forecast preview · `[STY-16]` EffectSpec set · `[STY-17]` relationship
  matrix / `target_filter` · `[SMV]` F10 window · Pair-Up (`PairUpRegistry`, `OFF_MAP_TILE`) · F4
  `CampaignRules` · F5 `ConditionManager`.
