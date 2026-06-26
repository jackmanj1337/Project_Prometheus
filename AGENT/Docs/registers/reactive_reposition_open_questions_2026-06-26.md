---
Type: register
Status: RESOLVED 2026-06-26
Last verified: 2026-06-26
Register: RCT-1..6
Resolved-in: 2026-06-26 — design-walk (session 2026-06-26h) from the "general swaps in for the healer" scenario. Design settled; the one flagged cost is RCT-1 (a NEW pre-resolution reaction trigger, which bumps the F11 "no new triggers" discipline → needs build-time architecture sign-off).
---

# `reactive-reposition` — Phase-0 Interceptor (on-targeted DSP reposition) — Open Questions

**Started:** 2026-06-26 (session 2026-06-26h), from an owner scenario: *"I attack the healer; the adjacent
general swaps map locations with the healer, the attack now goes against the general's evade/defense and
triggers their skills, and the general stays in the square."* **Third sibling** of `redirect` (`[RDR]`)
and `cover` (`[CVR]`) — the **earliest** phase of the interceptor family.

## Model (firmed)
> On a `[REQ]`+`event` trigger at **target-declaration (pre-resolution)**, a `[STY-9]`-selected reactor
> performs a **`[DSP]` reposition** (swap / shove / pull / pivot / step-in-front). **Then the engine's
> normal targeting + combat resolution runs against whoever now occupies the targeted tile** — so
> **evade, defense, on-defend skills, and counterattack are all the new occupant's, automatically**, with
> no special defender-reassignment hook. "The general stays in the square" = the DSP move is a real
> position change (persists).

### Why phase-0 ≠ cover (phase-1)
Cover reassigns the *defender of an in-flight attack* (per-hit: to-hit vs the ally, mitigation vs the
protector, **no counter**, ally's evade). Phase-0 **moves a unit into the tile** so the **whole exchange**
is the new occupant's (full evade + skills + **counter**) — for free, via standard resolution. Full
substitution is the reason to use phase-0; partial substitution is cover; emit-elsewhere is redirect.

## Three-phase interceptor family (the unifying picture)
| Phase | Primitive | Hook | What substitutes | Counter / Evade |
|---|---|---|---|---|
| **0** | `reactive-reposition` (this) | target-declaration (pre-resolution) | everything (unit in the tile) | counter **yes** · evade = new occupant's |
| **1** | `cover` `[CVR]` | pre-mitigation defender-resolution | mitigation + HP only | counter no (default) · evade = ally's |
| **2** | `redirect` `[RDR]` | post-mitigation `effect_applied` | emits a new effect elsewhere | n/a (emit, not exchange) |

All three share the `[STY-9]` selector, the `[REQ]`+`event` trigger (RDR-12), the RDR-13 cost model, and a
one-hop termination guard; they differ only in **when** they hook.

---

## RCT-1 — The pre-resolution reaction window (the one new cost)  `[RESOLVED — design; trigger needs sign-off]`
Phase-0 needs a **new reaction trigger** that fires **after a target is declared, before the exchange
resolves**. The atlas **F11** row holds a deliberate *"no new triggers — discipline"* line, so this is the
one piece that is **not free**: it adds a pre-combat reaction phase. **Forward-req / owner-architecture
call at build time.** The **combat forecast must reflect the post-reaction state** (show the real defender
after the swap) — reuse the `[RDR-5]`/`[CVR-4]` preview principle and the AI target-eval reading the same
forecast (no feel-bad surprise swaps).

## RCT-2 — Reaction action = the `[DSP]` vocabulary  `[RESOLVED]`
The action reuses **`[DSP-1..17]`** (swap default; `shove`/`pull`/`pivot`/`step-in-front` variants),
incl. its collision/validity rules. An **illegal reposition fizzles** (no-op; the attack proceeds against
the original target). **Forced/hostile** repositions are allowed — e.g. **swap the targeted ally with an
*attacker-allied* unit**, putting that unit in the line of fire (it then defends with its own evade and
**can counter**) — this is the clean "retarget the attack to a different, possibly attacker-allied, target
*with full defense + counter*" case (vs `[RDR]` emit, which delivers damage but no dodge/counter).

## RCT-3 — Persistence  `[RESOLVED]`
A `persist` flag: **`stay`** (default — the reactor remains in the tile; the owner scenario) vs
**`revert-after`** (positions restore after the exchange — a temporary bodyguard).

## RCT-4 — Full substitution is automatic  `[RESOLVED]`
Because the reactor physically occupies the targeted tile, the **standard combat path** gives it evade,
defense, on-defend skills, and **counterattack** — no special hook, and **range stays valid** (same tile).
This is phase-0's advantage over cover. A downstream `cover`/`redirect` on the **new occupant** can still
fire in its own phase.

## RCT-5 — Eligibility / priority / cost / trigger  `[RESOLVED]`
Who-can-react = the **`[STY-9]`** selector; multiple eligible reactors resolved by the **`[CVR-3]`**
deterministic priority (author key, fallback nearest→unit-id). Reactor must be valid (alive, present).
**Cost** = the **RDR-13** `cost: {pool, amount, subject}` clause (once/battle, costs stamina…). The
**trigger** is a `[REQ]`+`event` predicate (only vs melee, % chance, once/turn, HP gate…).

## RCT-6 — Family interactions + termination  `[RESOLVED]`
Phases resolve in order **0 → 1 → 2** for one incoming attack: a reposition (0) can be followed by the new
occupant's cover (1) and redirect (2). A reposition is **non-re-reactable** within the same attack (one
hop — mirrors the RDR/CVR termination guard) to prevent swap chains/loops. Deaths from a phase-0 exchange
ride the `[RDR-8]` snapshot-then-resolve A5 rule.

## Next step
Design settled; build rides the same M8 / A1 / `CombatResolver` path as `[RDR]`/`[CVR]`, **plus** the
RCT-1 pre-resolution reaction window (the F11 new-trigger sign-off). Reuses `[DSP]` wholesale.
