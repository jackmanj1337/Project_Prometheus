---
Type: register
Status: OPEN
Last verified: 2026-06-26
Register: RDR-1..9
Resolved-in: —
---

# `redirect` — Combat Effect-Redirect Primitive — Open Questions

**Started:** 2026-06-26 (session 2026-06-26e), from the **candidate G** walk in
`design/candidate_systems_2026-06-23.md`. **Owner timing:** discuss **before A5** (it co-owns the A5
death/removal-disposition ordering — see RDR-8).

**Status (OPEN):** the **conceptual model and end-shape are firmed** (recorded in candidate G); this
register tracks the **residual forks** the dedicated build-walk must settle. The model:

> `redirect` is an **effect interceptor** — it subscribes to incoming **effect-application events** on
> its holder and, for events matching a `[REQ]` predicate, emits a **transformed effect at a selected
> target-set**. "Reflect" (bounce at the dealer) is the **preset** `target = {source}`. Authored once as
> an engine primitive, composed as data (the `[EXT]` "one model = A" pattern). Determinism **class-2**
> (state-mutation: deterministic, ordered, safe-point, fixed-point, Package-A RNG).

**Firmed by the walk (NOT open — recorded here for context):**
- Subject = damage · conditions · other combat effects (general).
- Carrier = any source (status condition · equipment · class trait all GRANT the one effect).
- `fires_on_death` = a per-effect author flag, engine default = dying-thorns.
- Termination = emitted effects are flagged **non-redirectable → one bounce only**.
- Name = `redirect` (general); `reflect` = the back-to-source preset; disambiguated from the `[DLG-9]`
  visual reflect.

---

## RDR-1 — Magnitude-division policy across N targets  `[OPEN]`
When the selector matches multiple targets, does each take the **full** redirected magnitude, or is the
total **split** among them? **Recommendation:** default **full-to-each**, and — since magnitude is
already a `[REQ-16]` term — expose **`target_count`** as a term variable so an author can divide
(`incoming / target_count`) when they want a split. Covers both with no new machinery. *Confirm + name
the variable.*

## RDR-2 — Reflected-condition / other-effect transform  `[OPEN]`
For non-damage subjects: does `redirect` re-apply the **identity** effect (same condition id) or a
**mapped** id, and how do a condition's **magnitude/duration** transform? **Recommendation:** identity by
default; allow a `{from_id → to_id}` map; numeric parts (duration/potency) ride a `[REQ-16]` term over
the incoming value. Depends on the M8 condition data shape (RDR-6).

## RDR-3 — Read point: pre- vs post-mitigation, and the return pipeline  `[OPEN]`
Does `redirect` read the raw incoming value or the **post-mitigation actual** applied to the holder, and
does the emitted effect pass through the **target's** own pipeline? **Recommendation:** read
**post-mitigation actual** (deterministic, already computed — the `unit_damaged` amount), and apply the
emitted effect **through the target's pipeline** (target's defenses + the `[REQ-15]` lethal/floor
projection apply). Avoids double-mitigation. *Confirm.*

## RDR-4 — `anchor` enum  `[OPEN]`
From whom/where is the selector's spatial scope + predicate measured? Candidate values: **`source`**
(the dealer) · **`holder`** (the redirector) · **`tile`** (a fixed point). Finalize the set; confirm
whether `source` should be the documented default (matches the `reflect` preset).

## RDR-5 — Stacking + combat-preview combination  `[OPEN]`
Independent-fire is firmed (each effect emits its own; no auto-sum). **Open:** how the **combat preview**
presents the combined redirected total across **all** affected targets before commit (reuses the
preview-must-reflect-combined-effect requirement noted for candidate systems generally). Presentation +
ordering of the preview lines.

## RDR-6 — "Other combat effects" enumeration  `[OPEN]`
Exactly **which** effect kinds are redirectable depends on the **M8** effect taxonomy
(`ConditionManager` is a stub until then). Enumerate the redirectable kinds (damage · conditions ·
knockback/displacement? · stat-shred?) when M8 fixes the taxonomy. Gates RDR-2.

## RDR-7 — Foundation dependencies on the M8 build  `[OPEN]`
General `redirect` is **not buildable on current stubs.** It requires the M8 build to expose **(a)** a
uniform, **source-bearing** `effect_applied(kind, magnitude, source, target)` event to intercept, and
**(b)** a **shared unit-selector** (`anchor` + `scope` + `[REQ]` predicate) — the **same** selector the
spell/style AoE system needs (build once, both consume). The interception hook belongs in
**`CombatResolver`**, not `Unit.take_damage` (which today carries no source). *Action: register these as
explicit requirements on the M8 / effect-resolution build, and coordinate the selector with the AoE
owner.*

## RDR-8 — A5 death-ordering co-input  `[OPEN]`
A redirected hit can kill the target(s); with multi-target selection, **one resolution can flag several
deaths.** The lethal blow defers disposition to a safe point, `redirect` fires per `fires_on_death`, then
all flagged deaths resolve in **A5's** defined order. *Action: feed `redirect`'s multi-kill /
simultaneous-death case into the **A5** death/removal-disposition ordering decision — this is why it is
walked pre-A5.*

## RDR-9 — Selector reaching the holder / allies (guardian / damage-share)  `[OPEN]`
Because the selector is a general predicate, `target` can include **allies** (→ damage-share / guardian)
or even the **holder**. Confirm the semantics are intended and safe: loop-safety is already covered by
the one-bounce non-redirectable flag (RDR / termination), but confirm a self-including selector cannot
produce a surprising self-hit, and decide whether `redirect`-to-ally needs its own preview/consent
treatment.

---

## Next step
Dedicated build-walk **before A5** to settle RDR-1..9, with RDR-7 (M8 foundation requirements) and RDR-8
(A5 ordering co-input) raised against those owners now so the dependencies are not discovered late.
