---
Type: register
Status: RESOLVED 2026-06-26
Last verified: 2026-06-26
Register: CVR-1..6
Resolved-in: 2026-06-26 — full design-walk (session 2026-06-26g); CVR-1..6 settled. Substitution = **per-hit intercept** (owner; distinct from `[PRV]` provoke); scope = **damage + conditions + displacement** (owner). Remaining items are forward-reqs (a **pre-mitigation defender-resolution hook** in `CombatResolver`; the M8 event; A5 death-ordering) shared with `[RDR]`.
---

# `cover` — Pre-Application Effect-Reassignment Primitive — Open Questions

**Started:** 2026-06-26 (session 2026-06-26f). **Spawned by** the `redirect` walk (`[RDR-9]`). **Walked +
RESOLVED 2026-06-26** (session 2026-06-26g). **Sibling of** `redirect` (`[RDR]`,
`registers/redirect_effect_open_questions_2026-06-26.md`) — same `[EXT]` interceptor family, opposite phase.

## Model (firmed)
> `cover` is a **pre-mitigation** interceptor: for an incoming effect targeting a *protected* unit, a
> **protector** (chosen by the `[STY-9]` selector) **takes the effect instead** — the blow is reassigned
> before mitigation, so the **protector's own DEF/RES (or immunity, or displacement)** resolves it. The
> protected unit takes nothing (or a `share`, CVR-2).

**Substitution = PER-HIT intercept (owner 2026-06-26).** To-hit/crit are decided vs the **original
target** (the declared defender); on a landing hit, the **damage magnitude is computed with the
PROTECTOR's mitigation** and applied to the protector. **NOT whole-exchange** (the protector does not
become the defender for accuracy/counter purposes — that re-targets aggro, which is `[PRV]` provoke's job;
see the distinction note). *(Minor build-time detail: accuracy is rolled vs the original target's avoid,
not the protector's — no re-roll; flagged if it should instead roll vs the protector.)*

### Distinct from `[PRV]` provoke (different layer + timing)
- **Provoke** = diplomacy/**aggro**; changes the relationship matrix so an AI *decides* to attack someone
  (pre-decision; `set_relationship` + `provoke_on_attacked`).
- **Cover** = combat-resolution **damage interception**; the attacker's choice stands, the protector eats
  the landed blow (mid-resolution).
- They **stack** — a provoked enemy charges the healer; the knight covers the hit.

## Why it is a distinct primitive, not a `redirect` mode (the `[RDR-9]` boundary)
`redirect` is **post-mitigation + additive** (the holder took the hit; a new transformed holder-attributed
effect is emitted elsewhere). `cover` is **pre-mitigation + reassignment** — the **original** effect's
defender changes before it resolves (protector's mitigation, original damage type/on-hit, original
kill-attribution). `redirect.absorb=1.0 + target={ally}` *looks* like cover but emits a new
holder-attributed effect; cover is the real "take the hit **instead of**."

## Shared with `redirect` (reuse, not re-walked)
- Trigger = `[REQ]` predicate + the **`event` subject** (RDR-12).
- Who-protects-whom = the **`[STY-9]`** selector (anchor + scope + `target_filter`).
- **Resource coupling** (RDR-13): a `cost: {pool, amount, subject}` clause (cover can cost uses/stamina).
- Determinism **class-2**; the M8 source-bearing data (RDR-7) is the same dependency.
- **One-hop termination:** a cover reassignment is flagged **non-coverable** (no cover-chains).

---

## CVR-1 — Reassignment phase + interaction with `redirect`  `[RESOLVED]`
`cover` hooks a **pre-mitigation defender-resolution** point in `CombatResolver` — **upstream** of
`redirect`'s post-mitigation `effect_applied` hook. Order when both apply: cover swaps the defender to the
protector → the protector's mitigation runs → if the **protector** has a `redirect`, it fires
post-mitigation on the damage the protector took; the **ally's** `redirect` does **not** fire (the ally
took nothing). Cover reassignments are **non-coverable** (one hop). *Forward-req: the combat pipeline must
expose this pre-mitigation defender hook — earlier than the RDR-7 `effect_applied` event.*

## CVR-2 — Partial vs full cover  `[RESOLVED]`
Default **full** (the protector takes the whole effect). A **`share`** `[REQ-16]` fraction term splits it
(protector takes `share × incoming`, the ally takes the rest — **each through their own mitigation**,
since the swap is pre-mitigation). Non-scalar (displacement, CVR-6) is **all-or-nothing** (no partial
shove). Mirrors `redirect`'s absorb-as-term.

## CVR-3 — Eligibility / range / priority  `[RESOLVED]`
The **`[STY-9]`** selector defines who-can-cover-whom (e.g. "adjacent allies"). When several units can
cover one hit, a **deterministic priority** picks one: an author key (e.g. highest cover-priority /
lowest-HP / nearest), fallback **nearest → unit-id**. The coverer must be **valid** (alive, present, not
the original target). An optional **`cover_if_lethal`** flag (default **true** = sacrifice — the protector
takes a blow that would kill it; mirror/inverse of `redirect.fires_on_death`) lets an author forbid
suicidal cover. No valid protector → cover doesn't trigger, the ally takes the hit normally (no-op).
Resource gate (RDR-13) applies (insufficient pool → no cover).

## CVR-4 — Mitigation + attribution + preview  `[RESOLVED]`
The reassigned hit uses the **protector's** mitigation (DEF/RES, terrain) vs the **original attacker**,
keeps the **original** damage type / on-hit / effect-tags, and **kill-credit + EXP go to the original
attacker** (they killed the protector). The **ally gets no EXP** (took nothing). The attacker's combat
**forecast must show the protector as the actual defender** (the target visibly changes pre-commit), and
**AI target-evaluation reads the same forecast** (so the AI knows the hit lands on the protector).

## CVR-5 — Death / disposition (A5)  `[RESOLVED]`
If the protector dies taking the blow, it rides the **`[RDR-8]` snapshot-then-resolve** A5 rule (mutual
kills both die; deterministic disposition order); kill-credit → the original attacker. The ally is
**unharmed**, with **no turn/position change**. Feeds the same A5 "simultaneous deaths" case.

## CVR-6 — Coverable effect kinds  `[RESOLVED]` (owner: damage + conditions + displacement)
- **Damage** — per-hit intercept (CVR-1/4).
- **Conditions** — the protector takes the condition **instead** (identity; the protector's
  immunity/resist applies); the ally is spared.
- **Displacement / forced-move** — the displacement **vector** is reassigned to the protector: the
  **protector is displaced by that vector from the protector's own tile**, the ally stays put, obeying
  **DSP** collision/validity (blocked/off-map → DSP partial/fizzle). All-or-nothing. (Per-kind transform,
  mirroring `[RDR-2]`.) *(Alternative an author could want — pure negation, ally unmoved + protector
  unaffected — is just immunity, not "instead of"; not the default.)*
- Final enum pinned against the M8 taxonomy (shared with `[RDR-6]`).

---

## Forward-reqs (shared owners with `[RDR]`)
- **`CombatResolver`:** a **pre-mitigation defender-resolution hook** for the cover swap (earlier than
  RDR-7's post-mitigation `effect_applied` event) — *added to the atlas combat/F5 note.*
- **A5:** cover deaths ride the `[RDR-8]` snapshot-then-resolve rule (already on the atlas A5 bullet).
- **`[STY-9]`** selector + **RDR-12** `event` subject + **RDR-13** cost-pool model — all reused.

## Next step
`cover` design is settled; build rides the same M8 / A1 / `CombatResolver` path as `redirect`, once the
pre-mitigation defender hook + the shared forward-reqs land.
