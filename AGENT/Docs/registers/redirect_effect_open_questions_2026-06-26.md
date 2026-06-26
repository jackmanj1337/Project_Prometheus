---
Type: register
Status: RESOLVED 2026-06-26
Last verified: 2026-06-26
Register: RDR-1..13
Resolved-in: 2026-06-26 — full design-walk (session 2026-06-26f); RDR-1..13 settled (RDR-12 `event`-context binding + RDR-13 resource coupling added later same session from composition stress-tests). Remaining items are forward-reqs on other owners (F5/M8 effect event, A5 death-ordering, `[STY-9]` selector, F16/REQ `event` subject, candidate-A/F7 cost-pool model) + a spawned sibling primitive `cover` (`[CVR]`), not open design forks on `redirect` itself.
---

# `redirect` — Combat Effect-Redirect Primitive — Open Questions

**Started:** 2026-06-26 (session 2026-06-26e), from the **candidate G** walk in
`design/candidate_systems_2026-06-23.md`. **Walked + RESOLVED 2026-06-26** (session 2026-06-26f).
**Owner timing:** discussed **before A5** (it co-owns the A5 death/removal-disposition ordering — RDR-8).

**Status (RESOLVED):** the model + all 11 forks are settled (resolutions inline). What remains are
**forward-reqs on other owners** — the **F5/M8** uniform effect event (RDR-7), the **A5** death-ordering
co-input (RDR-8), the **`[STY-9]`** shared selector — and a **spawned sibling primitive `cover`**
(register `[CVR]`, `registers/cover_intercept_open_questions_2026-06-26.md`), not open design questions on
`redirect`.

## Model (firmed)
> `redirect` is an **effect interceptor** — it subscribes to incoming **effect-application events** on its
> holder and, for events matching a `[REQ]` predicate, **(a)** optionally **absorbs** a portion of the
> effect off the holder (pre-application reduction, RDR-10) and **(b)** emits a **transformed effect at a
> selected target-set** (post-application). "Reflect" (bounce at the dealer) is the **preset**
> `target = {source}`; **full-absorb + bounce** = the parry/full-reflect fantasy. It may **gate on and
> drain a resource pool** (RDR-13 — uses/charges, mana, a depleting barrier). Authored once as an engine
> primitive, composed as data (`[EXT]` "one model = A"). Determinism **class-2** (state-mutation:
> deterministic, ordered, safe-point, fixed-point, Package-A RNG).

## Deterministic resolution order (the spine RDR-1..13 hang off)
1. Intercept the effect-application event on the holder; evaluate the `[REQ]` **trigger** predicate **and
   the resource gate** (pool ≥ activation cost, RDR-13). Fail → passthrough (holder takes full, no absorb,
   no drain).
2. Resolve the **target-set** via the `[STY-9]` selector (anchor + scope + `target_filter`); determine
   `N_intended` (matches that are real units) and `N_valid` (still alive/on-map).
3. Compute **`absorb`** (RDR-10; may be bounded by a pool read, RDR-13) and the **redirected
   magnitude(s)** (RDR-1).
4. **Gate absorb** on target availability (RDR-11, default *proportional*) → **`effective_absorb`** (this
   is the value `absorbed_value` resolves to).
5. **Deplete resources** (RDR-13): drain `cost.pool` by `cost.amount` (a term — e.g. `absorbed_value` for
   a barrier, or a fixed `1` for uses), clamped to available.
6. Apply to holder: `holder_takes = incoming − effective_absorb` (through the holder's normal pipeline).
7. **Emit** the redirected effect to each valid target through that target's pipeline, flagged
   **non-redirectable** (RDR-3 termination).
8. Resolve deaths **snapshot-then-resolve** in A5's order (RDR-8).

---

## RDR-1 — Magnitude division across N targets  `[RESOLVED]`
**Full-to-each** by default; expose **`target_count`** as a `[REQ-16]` term variable so an author can
split (`incoming / target_count`; `div on_zero` is already a required REQ-16 choice). `target_count == 0`
→ graceful **no-op** (no error).

## RDR-2 — Reflected-condition / other-effect transform  `[RESOLVED]` (scope widened — see RDR-6)
**Identity** re-apply by default + optional `{from_id → to_id}` map; scalar parts (potency/duration) via a
`[REQ-16]` term over the incoming value. Emitted effects go through the target's **normal** application
(F5 immunity/stack rules apply — not `redirect`'s job). Reflecting a **condition requires the source
recorded on the condition instance** → forward-req on M8 (RDR-7). **Non-scalar** effects (displacement /
forced-move, in scope per RDR-6) use a **per-kind transform** — e.g. re-emit the displacement with
`target = source`, direction **recomputed from the new actor**; absorb on non-scalar is **all-or-nothing**
(RDR-10).

## RDR-3 — Read point + return pipeline + termination  `[RESOLVED]`
Read the **post-mitigation actual** value applied to the holder; emit the bounce **through the target's
own pipeline** (target defenses + the `[REQ-15]` lethal/floor projection apply). True-damage is an F5
damage-property, not `redirect`-specific. **Fires on the event, not on damage>0** — a flat magnitude term
bounces even off a landed 0-damage hit; **misses do not fire** (no effect-application event). The
**non-redirectable flag rides the emitted effect instance** through the whole pipeline, so a bounce can
never re-trigger a `redirect` (one bounce — kills thorns-vs-thorns + radiate cascades; non-negotiable).

## RDR-4 — `anchor` + selector  `[RESOLVED]`
`anchor ∈ {source, holder}`, **default `source`**. **`tile` dropped** — a literal coordinate is
meaningless for a reactive interceptor (holder's/source's tile is already `holder`/`source` + scope). The
selector is **`[STY-9]`** (AoE shapes + `target_filter`, already on A1's path for gambits/staves/arts) —
**reused, not bespoke**; composes `GridManager._tiles_in_range` + `_get_units()` underneath.

## RDR-5 — Stacking + combat-preview  `[RESOLVED]`
Multiple `redirect`s on one holder fire **independently** (no auto-sum), in a **deterministic order**
(stable sort, reuse the M8 condition order). The **combat preview** (the **attacker's** forecast) must
show: the holder's **reduced incoming** (absorb), **all affected targets + combined redirected total**,
**`fires_on_death`** outcomes (no hidden dying-thorns), and **proportional-absorb** when some targets are
missing. Chance-based magnitudes show **odds**, not a committed number (reuse the `[REQ-10]` rule).
Redirect is **visible when the holder is visible** (no hidden-thorns gotcha; a concealed variant could be
a later author flag).

## RDR-6 — Redirectable effect-kind set  `[RESOLVED]` (owner: include non-scalar)
v1 redirects **damage + scalar conditions AND non-scalar displacement / forced-move** (owner call
2026-06-26). Non-scalar kinds carry a **per-kind transform** (RDR-2) and **all-or-nothing absorb**
(RDR-10). Final enum is pinned against the **M8** effect taxonomy when it lands (RDR-7); couples to the
DSP displacement system for the forced-move case.

## RDR-7 — Foundation forward-reqs (M8 / `[STY-9]`)  `[RESOLVED as forward-reqs]`
General `redirect` is **not buildable on current stubs** (`ConditionManager.gd` = 37-line no-op until M8;
`Unit.take_damage` carries **no source**). Requirements raised on the owners:
- **F5 / M8 build:** expose a **uniform, source-bearing `effect_applied(kind, magnitude, source, target,
  flags)` event** with a **`redirectable` flag**, and **store the source on every condition instance**
  (needed for the RDR-2 condition bounce + the per-tick opt-in, RDR — Q3). *(Added to the atlas F5 row.)*
- **Selector:** reuse **`[STY-9]`** — coordinate with the A1 source/style build.
- **Hook:** the interceptor registers in **`CombatResolver`** (the only place that knows
  attacker→defender and owns death timing), **not** `Unit.take_damage`.

## RDR-8 — A5 death-ordering co-input  `[RESOLVED as A5 input]`
A redirected/absorbed exchange can flag **several** deaths in one resolution (multi-target + dying-thorns).
**Rule fed to A5's "simultaneous deaths (AoE wipe)" case:** **snapshot-then-resolve** — apply all HP
changes, then collect all units at 0 HP, then run disposition in a **deterministic order**
(turn-order/unit-id); each death's triggers see the **snapshot**, so mutual kills both die (neither
"saves" the other). Dying-thorns emit **during resolution, pre-disposition**. **Kill-credit / EXP** for a
redirect kill is attributed to the **holder** even if the holder is dead → flagged to A5 EXP economy +
the objective system. *(Noted on the atlas A5 death-disposition bullet.)*

## RDR-9 — Selector reaching the holder / allies; scope boundary  `[RESOLVED]`
The **holder is excluded** from the target-set by default (it already took the hit; opt-in flag to
include). Selector reaching **allies = damage-share / radiate (additive)** — supported. **Scope
boundary:** `redirect` is **post-application + additive** — it RADIATES / SHARES / REFLECTS-BACK but
**cannot ABSORB-REASSIGN** the original hit ("take the hit *instead of* my ally"). That pre-application
**reassignment** is a **sibling primitive `cover`** (owner: spec now → register **`[CVR]`**).
**Note:** `redirect.absorb=1.0 + target={ally}` is *not* `cover` — it emits a **new, transformed** effect
(holder-attributed, fresh application), whereas `cover` reassigns the **original** effect's target (ally's
own mitigation vs the original attacker, original attribution).

## RDR-10 — `absorb` parameter  `[RESOLVED]` (owner-added 2026-06-26)
A `[REQ-16]` term = the portion of the incoming effect **removed from the holder before it lands**
(pre-application reduction), clamped to `[0, incoming]`. `absorb = 0` → pure **additive thorns**;
`absorb = full` → **parry / full-reflect** (holder unharmed, whole effect redirected); partial → split.
A new term variable **`absorbed_value`** is exposed to the emission magnitude term so an author can
"redirect exactly what I absorbed" (absorb and bounce-magnitude stay orthogonal but couplable). On
**non-scalar** effects (RDR-6) absorb is **all-or-nothing** (negate the whole shove or none — no
fractional displacement).

## RDR-11 — Absorb when the target is unavailable  `[RESOLVED]` (owner-added 2026-06-26)
A per-effect enum **`absorb_on_unavailable: proportional (default) | gated | unconditional`**, evaluated
when the target-set has missing/invalid targets (source dead, environmental/no-unit source, allies gone):
- **`proportional` (DEFAULT):** `effective_absorb = absorb × (N_valid / N_intended)`, where `N_intended`
  = selector matches that correspond to a real unit (environmental/no-unit → contributes 0) and `N_valid`
  = those still alive/on-map at emission. By **count**, not magnitude (full-to-each already breaks
  magnitude conservation). `N_intended == 0` → 0 absorb (holder takes full — collapses to conservation).
  All targets present (the normal reflect-to-source case) → full absorb, untouched.
- **`gated`:** ≥1 valid target → full absorb, else none (binary all-or-nothing gate).
- **`unconditional` (ward):** absorb always applies; the redirected portion is simply lost with no target
  (the reflect doubles as flat damage-reduction / armor-vs-environment).

The gate keys on **target availability**, not on the emitted magnitude being >0 (a 0-magnitude bounce to a
live target still counts as "landed").

## RDR-12 — `event`-context binding for the trigger/terms  `[RESOLVED as forward-req on F16/REQ]`
The `[REQ]` vocabulary has subjects for *speaker/participant/unit/party/item* but **no `event` subject** —
yet `redirect` triggers and terms must read fields of the **intercepted event**. Surfaced by the
composition stress-tests (reflect-spells / criteria). **Forward-req on F16/REQ:** add an **`event`
context subject** exposing the intercepted event's fields:
- `event.kind` (damage / condition / displacement …), `event.damage_class` (physical/magic),
  `event.magnitude` (→ the **`incoming_value`** term variable), `event.is_crit`, `event.range`,
  `event.source` (a unit subject → then `[REQ-11]` reads the source's equipped weapon
  `combat_family`/`effect_tags`), `event.condition_id` / `event.stacks` (for condition subjects).
- The **term-side** variables `incoming_value`, `absorbed_value` (= the effective post-RDR-11 absorb),
  and `target_count` are already specified (RDR-1/10/11); RDR-12 adds the **predicate-side** `event.*`
  reads. This is the single genuinely-new vocabulary surface the composition needs — everything else is
  existing `[REQ]` / `[REQ-16]` / `[STY-9]`.

## RDR-13 — Resource coupling (uses / drain / magnitude-bound)  `[RESOLVED]` (owner-added 2026-06-26)
`redirect` may declare a **`cost: { pool, amount, subject }`** clause, reusing the generic cost/pool model
(candidate A shared pools / the generalized `uses` field / F7 pools) — **not** a bespoke counter:
- **`amount`** is a `[REQ-16]` term, so one clause covers **fixed uses** (`amount: 1`), **scaled cost**
  (`amount: incoming_value × 0.5` → reflect a spell paid in mana), and a **depleting barrier**
  (`amount: absorbed_value` → drain a pool by what was absorbed; pair with `absorb: min(incoming_value,
  pool(holder, barrier))` so the barrier bounds and depletes — at 0 it passes through).
- **`subject`** = `holder` (a unit pool: HP / stamina / mana) or `granting_item` (the granting item's
  `uses`/durability), so an equipment-granted `redirect` can spend item charges.
- **Determinism:** the **gate** (`pool ≥ cost`) is a pure read+compare on the **decision** path; the
  **drain** is the **class-2 side-effect** (same as MET actions mutate). No new determinism surface.
- **Dependency:** works against **existing** pools now (HP, item `uses`); **author-defined** pools
  (stamina/mana) ride **candidate A** (not yet firmed). Refill of a "uses" pool = the candidate-A
  CampaignRules refill rule (per-map / per-turn / hub-rest / never). *(Noted on the atlas.)*

---

## Worked-example recipes (double as build acceptance tests)
Author data in the Option-A data-tree style (illustrative, not pinned syntax):
- **"Absorb and reflect the first 5 points of damage"** (per-hit): `absorb: { min: [incoming_value, 5] }`,
  `magnitude: absorbed_value`, `target: {anchor: source}`. *(A 5-point **total** depleting shield = the
  RDR-13 barrier recipe.)*
- **"Reflect the first two stacks of a condition"**: `trigger.all: [{kind: condition, condition_id:
  poison}, {lt: [condition_count(holder, poison), 2]}]`, `absorb: {min: [incoming_value, {sub: [2,
  condition_count(holder, poison)]}]}`, `magnitude: absorbed_value`, `transform: {condition_id: poison}`.
- **"Reflect spells but not physical weapons"**: `trigger: {eq: [event.damage_class, magic]}` (or
  `item_has_tag(event.source.equipped, spell)`), `magnitude: incoming_value`.
- **"Reflect only attacks meeting criteria"**: `trigger` = any `[REQ]` tree — e.g. `{eq: [event.range,
  1]}` (melee), `{lt: [hp_pct(holder), 50]}`, `{eq: [event.is_crit, true]}`, `{gt: [stat(event.source,
  atk), stat(holder, def)]}`.
- **"3 reflects per battle, then spent"**: `cost: {pool: redirect_charges, amount: 1}` (max 3, refill
  per-map). **"Reflect a spell, paid in mana"**: `cost: {pool: mana, amount: {mul: [incoming_value,
  0.5]}}`. **"5-point depleting barrier"**: the RDR-13 barrier recipe above.
- **"Absorb and send the blow at the attacker's own ally, once"** (friendly fire): `absorb: full`,
  `target: { anchor: source, scope: …, target_filter: allies_of(source) }`, `cost: {pool: redirect_uses,
  amount: 1}`. Delivers as a **fresh emit** (the new target's defense applies, **no dodge-roll / no
  counter**). To instead make the new target a real defender that can **evade + counter**, use the
  **phase-0 `[RCT]`** forced swap (put that unit in the line of fire), not redirect. (See the three-phase
  family in `[RCT]`/`[CVR]`.)

---

## New edge cases surfaced by the walk (folded in above)
- **Source attribution:** environmental/trap/terrain damage has **no unit source** → `target={source}`
  resolves to 0 intended → no bounce, and proportional-absorb → 0 (holder takes full) unless
  `unconditional`. Pair-up/summon/battalion source = whatever `CombatResolver`/those systems attribute.
- **Dead/absent source or ally at emission** → that target is **dropped** (validity resolved at emission),
  feeding `N_valid` in RDR-11.
- **Beneficial effects:** `redirect` mechanically sees all effect-applications; the **default `reflect`
  preset predicate scopes to hostile**, so heals/buffs are not bounced unless an author widens the trigger.
- **DoT-tick (Q3):** the preset reflects **direct applications only**; **per-tick** reflection is
  author-opt-in and carries the RDR-7 "conditions store their source" requirement (+ dead-source → no-op).
- **Determinism/replay:** the selector iteration order + the multi-redirect firing order must be
  deterministic (stable sort); class-2, fixed-point, Package-A RNG.

## Next step
- `redirect` design is settled; build rides the M8 / A1 path once the forward-reqs land.
- **Walk the spawned `cover` sibling** — register `[CVR]` (pre-application effect-reassignment).
- Confirm the forward-reqs are picked up by their owners (all now on the atlas): **RDR-7** (F5
  `effect_applied` event), **RDR-8** (A5 death-ordering), **RDR-12** (F16/REQ `event` subject), **RDR-13**
  (candidate-A/F7 cost-pool model — and that `redirect` works against existing HP/item-`uses` pools
  before candidate A firms).
