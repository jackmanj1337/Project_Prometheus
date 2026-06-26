---
Type: register
Status: OPEN
Last verified: 2026-06-26
Register: CVR-1..6
Resolved-in: —
---

# `cover` — Pre-Application Effect-Reassignment Primitive — Open Questions

**Started:** 2026-06-26 (session 2026-06-26f). **Spawned by** the `redirect` walk (`[RDR-9]`, owner call:
"spec a sibling `cover` primitive now"). **Sibling of** `redirect` (`[RDR]`,
`registers/redirect_effect_open_questions_2026-06-26.md`) — same `[EXT]` interceptor family, opposite phase.

**Status (OPEN):** model sketched, forks below; **owner-requested as a dedicated walk.**

## Model (sketch — confirm at the walk)
> `cover` is a **pre-application** interceptor: for an incoming effect targeting a *protected* unit, it
> **reassigns the original effect's target** to the cover-holder (or another unit) **before** the effect
> lands. The protected unit takes nothing (or less); the new target takes the **original** effect — with
> **that unit's own mitigation** against the **original attacker** and **original kill-attribution**.

**Why it is a distinct primitive, not a `redirect` mode** (the `[RDR-9]` boundary): `redirect` is
**post-application + additive** — the holder already took the hit, and a **new, transformed**
holder-attributed effect is emitted elsewhere. `cover` is **pre-application + reassignment** — the
**original** effect changes target before resolving (original damage type, mitigation source, on-hit
triggers, kill credit). `redirect.absorb=1.0 + target={ally}` *looks* like cover but is mechanically the
additive case; cover is the real "take the hit **instead of** my ally" (FE Aegis / guardian / cover).

## Shared with `redirect` (reuse, do not re-walk)
- Trigger = `[REQ]` predicate over the incoming event.
- Who-protects-whom = the **`[STY-9]`** selector (anchor + scope + filter) — e.g. "adjacent allies."
- Determinism **class-2**; hook in **`CombatResolver`** before the holder's pipeline; the M8
  source-bearing `effect_applied` event (RDR-7) is the same dependency.

---

## CVR-1 — Reassignment phase + interaction with `redirect`  `[OPEN]`
`cover` runs **before** the effect lands (changes target); `redirect` runs **after**. Define the order
when both apply (e.g. a covered ally that also has a `redirect`): does `cover` move the hit, then the new
bearer's `redirect` fire? Likely yes — pin the pipeline position relative to RDR's resolution spine.

## CVR-2 — Partial cover vs full cover  `[OPEN]`
Does the cover-bearer take the **whole** original effect, or a **fraction** (the rest still hits the
protected unit)? A `[REQ-16]` term over the incoming value (mirror of `redirect.absorb`) is the natural
shape — but on the **original** effect, so mitigation accounting differs. Confirm.

## CVR-3 — Eligibility / range / who can cover whom  `[OPEN]`
Adjacency? Same selector as redirect? Can a unit cover multiple allies; can multiple coverers contend for
one hit (priority order)? Does the coverer need to be able to *survive*/*act*? Reuse `[STY-9]` + a
priority rule.

## CVR-4 — Mitigation + attribution on the reassigned hit  `[OPEN]`
Confirm: the reassigned effect uses the **cover-bearer's** mitigation vs the **original attacker**, keeps
the **original** damage type / on-hit effects, and **kill-credit goes to the original attacker** (unlike
`redirect`, where credit is the holder's). Define what the attacker's combat preview shows (it now targets
a different unit than chosen).

## CVR-5 — Death / disposition interaction (A5)  `[OPEN]`
If the cover-bearer dies taking the hit, does the protected unit's slot/turn change? Feeds the same **A5**
death-disposition + snapshot-then-resolve rule as `[RDR-8]`.

## CVR-6 — Scope: which effect kinds can be covered  `[OPEN]`
Damage clearly; conditions/displacement? (mirror of `[RDR-6]`). Gated on the M8 taxonomy.

## Next step
Dedicated `cover` walk (CVR-1..6), reusing the `redirect` resolution spine and the `[STY-9]` selector;
coordinate CVR-5 with the A5 death-ordering decision alongside `[RDR-8]`.
