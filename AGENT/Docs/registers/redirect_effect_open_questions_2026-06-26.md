---
Type: register
Status: RESOLVED 2026-06-26
Last verified: 2026-06-26
Register: RDR-1..11
Resolved-in: 2026-06-26 — full design-walk (session 2026-06-26f); RDR-1..11 settled. Remaining items are forward-reqs on other owners (F5/M8 effect event, A5 death-ordering, `[STY-9]` selector) + a spawned sibling primitive `cover` (`[CVR]`), not open design forks on `redirect` itself.
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
> `target = {source}`; **full-absorb + bounce** = the parry/full-reflect fantasy. Authored once as an
> engine primitive, composed as data (`[EXT]` "one model = A"). Determinism **class-2** (state-mutation:
> deterministic, ordered, safe-point, fixed-point, Package-A RNG).

## Deterministic resolution order (the spine RDR-1..11 hang off)
1. Intercept the effect-application event on the holder; evaluate the `[REQ]` **trigger** predicate. No
   match → passthrough (holder takes full, no absorb).
2. Resolve the **target-set** via the `[STY-9]` selector (anchor + scope + `target_filter`); determine
   `N_intended` (matches that are real units) and `N_valid` (still alive/on-map).
3. Compute **`absorb`** (RDR-10) and the **redirected magnitude(s)** (RDR-1).
4. **Gate absorb** on target availability (RDR-11, default *proportional*).
5. Apply to holder: `holder_takes = incoming − effective_absorb` (through the holder's normal pipeline).
6. **Emit** the redirected effect to each valid target through that target's pipeline, flagged
   **non-redirectable** (RDR-3 termination).
7. Resolve deaths **snapshot-then-resolve** in A5's order (RDR-8).

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
- `redirect` design is settled; build rides the M8 / A1 path once RDR-7's forward-reqs land.
- **Walk the spawned `cover` sibling** — register `[CVR]` (pre-application effect-reassignment).
- Confirm RDR-7 (F5 event) + RDR-8 (A5 ordering) are picked up by those owners (now noted on the atlas).
