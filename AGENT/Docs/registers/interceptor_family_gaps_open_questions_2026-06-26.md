---
Role: dated
Type: register
Status: RESOLVED 2026-06-26
Last verified: 2026-06-26
Register: ICP-1..6
Resolved-in: 2026-06-26 — gap-closing pass (session 2026-06-26i) over the three-phase interceptor family (`[RDR]`+`[CVR]`+`[RCT]`). Capability gaps closed by composition (RDR-14 `gain`, RDR-2 `emit.kind`, CVR-7 ward); the items below are the **residual** gaps — each resolved to a closure path, mostly **forward-reqs on adjacent systems** plus two design decisions and one deferred item.
---

# Interceptor Family — Residual Gaps & Closure Paths — Open Questions

**Started:** 2026-06-26 (session 2026-06-26i), from a deliberate gap-audit of the interceptor family
(`redirect` `[RDR]`, `cover` `[CVR]`, `reactive-reposition` `[RCT]`).

**Status (RESOLVED — closure paths set):** the **capability** gaps closed by composition, recorded in the
sibling registers:
- **Lifesteal / absorb-into-resource** → `[RDR-14]` **`gain`** clause (fill HP/mana/custom pool by a term).
- **Output-kind change** (damage→heal, debuff→buff) → `[RDR-2]` **`emit.kind`** field (default = incoming).
- **In-place ward** (reduce an effect on a third party, no transfer) → `[CVR-7]` **`share_disposition:
  negate`**.
- **Board re-evaluation** (each phase sees prior-phase mutations) → stated as a family rule in `[RCT-6]`.

Together these complete the operation set — **block · reduce · reflect · redirect · absorb · convert ·
split · copy · ward** — leaving only *delay* (ICP-3). The residual gaps below are **not** core-model
forks; they are dependencies + two decisions + one deferral.

---

## ICP-1 — Per-strike vs per-exchange granularity  `[RESOLVED — design + forward-req]`
A brave weapon / follow-up is **multiple `effect_applied` events**, so `redirect`/`cover` fire **per
strike** — a `uses: 1` or a "first 5 points" / "first 2 stacks" would consume/count **per hit**, not per
attack. `[RCT]` (phase-0) is inherently per-exchange; phases 1/2 are not.
- **Closure:** a **`trigger_scope: per_strike (default) | per_exchange`** field. `per_exchange` rides a
  **latch keyed to `exchange_id`** (reuse the `[REQ-10]` roll-once-and-latch pattern).
- **Forward-req:** the `effect_applied` event must carry **`exchange_id` + `strike_index`** (extends the
  RDR-7 / RDR-12 event surface). The latch is transient (per atomic exchange — no save surface).
- **Cost:** small-moderate (one field + the event identifiers + a per-exchange latch).

## ICP-2 — Universal effect event (environmental / tile / untargeted)  `[RESOLVED — forward-req]`
Lava/gas/aura ticks and debuff-staff effects must flow through the **same** `effect_applied` event or the
family can't see them.
- **Closure (sharpens RDR-7):** M8 routes **all** effect application through `effect_applied`, with a
  **nullable `source`**. Then self-`absorb`/`gain`/`redirect` compose (the bounce is a no-op when `source`
  is null — environmental damage can still be absorbed/warded); `cover`/`[RCT]` correctly **do not** fire
  (no attacker / no targeting event). *(Atlas F5 row sharpened.)*
- **Cost:** none beyond M8 honoring the universal-event shape.

## ICP-3 — Delayed / stored release  `[PARTIAL — composable half done; auto-release deferred]`
"Bank the absorbed damage, release it next turn / on my next attack."
- **Composable half (done):** `[RDR-14]` `gain` banks into a custom `stored` pool; a **separate** on-attack
  effect (`[F11]`) reads + spends it. Covers "store now, spend on my next attack."
- **Residual:** a **self-scheduled auto-release** (fire on its own after N turns) needs a
  **deferred-effect / scheduling** mechanism — that is **`[MET]`-timing** territory, not the interceptor
  family. **Deferred:** when a delayed-effect primitive is wanted, compose `gain`-into-pool + a
  `turn_reached`/countdown MET action that applies the stored effect.
- **Cost:** moderate, and only for the auto-release variant (a scheduled MET action consuming the pool).

## ICP-4 — Forecast = pure dry-run of all three phases (incl. counter)  `[RESOLVED — forward-req]`
The attacker's combat forecast must simulate **swap → cover → redirect → counter** to show the truth
(real defender, reduced/absorbed numbers, bounces, dying-thorns, the new defender's counter).
- **Closure:** extend the **projection/preview API** already pinned on F5 by `[REQ-15]` to run the whole
  interception pipeline in **dry-run** (pure, no side-effects, no resource spend). Reuses the RDR-5/CVR-4
  "preview shows the post-reaction state" principle.
- **Cost:** engineering (a dry-run mode over the same deterministic pipeline); no new design.

## ICP-5 — Rewind / undo across the reaction window  `[RESOLVED — forward-req]`
An `[RCT]` swap mutates positions at target-declaration; undoing the attack must also undo the swap (and
any cover/redirect side-effects + resource spend).
- **Closure:** the action/undo system treats **declare → reactions → resolution → counter as one atomic,
  undoable transaction.** The `[REQ-10]` latch already assumes a rewind-safe model, so the hook exists;
  the reaction must be folded into that transaction. F1 reserves the transaction boundary.
- **Cost:** depends on the undo/rewind infrastructure; design is just "one transaction."

## ICP-6 — Layered cover (two protectors split one hit)  `[DEFERRED — minor]`
Per-phase priority (`[CVR-3]`) picks **one** protector per hit; two protectors each taking part of one hit
is not expressible. Judged **minor** (rare; a stacked-cover want can be revisited if it shows up in play).
No closure planned.

---

## Net
Three small additions (`gain`, `emit.kind`, `share_disposition`) closed the capability gaps. The residual
items are **two forward-reqs on M8** (ICP-1 event identifiers, ICP-2 universal event), **two forward-reqs
on cross-cutting infra** (ICP-4 projection dry-run, ICP-5 undo transaction), **one deferred design**
(ICP-3 auto-release → MET), and **one minor deferral** (ICP-6). None reopen the family's core model.

## Cross-references
- Closers: `[RDR-14]`, `[RDR-2]` (`emit.kind`), `[CVR-7]`, `[RCT-6]` (board re-eval rule).
- Forward-reqs: F5/M8 (`effect_applied` universal + `exchange_id`/`strike_index`; projection dry-run),
  F1 (undo transaction boundary), `[MET]` (delayed auto-release), F7/candidate-A (the `stored` pool).
