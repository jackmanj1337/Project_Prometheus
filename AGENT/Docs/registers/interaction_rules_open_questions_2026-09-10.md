---
Type: register
Status: RESOLVED
Last verified: 2026-09-10
Register: ITR-1..7
Resolved-in: 2026-09-10
---

# Authored Trait Interactions — Open Questions

**Started:** 2026-09-10. **Status: RESOLVED** — all seven closed on owner direction the
day they were opened; they are recorded here as the citable boundary for
`AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10`, not as a live walk.

**Design:** `design/candidate_systems_2026-06-23.md` §C.
**Runtime:** `InteractionRuleResolver`; data `CampaignRules.interaction_profiles`.

> **Why this register exists rather than more `[CEX]` entries.** These seven were first
> written into `candidate_systems_open_questions_2026-06-23.md` as `[CEX-18..23, 25]`.
> Six of those numbers were already allocated — `CEX-18/19` to story-item questions and
> `CEX-20..23` to the weapon-source/equip model, which is cited from `[CEX-5..8]`,
> `[CEX-24]`, the F1 save reservations and `[STY]`. The collision was corrected on
> 2026-09-10 by moving the new resolutions here; that register keeps the originals and
> carries the full note. Only `[CEX-25]` (collision ownership) was correctly numbered,
> and it moves here as `[ITR-7]` so the set stays together.
>
> *One-in-one-out:* this adds a register **instance**, not a document class or a
> mechanism, so it does not increase the number of distinct things an agent maintains.
> The rule binds classes; nothing is retired for it, and that is the written reason.

**Relation to `[CEX-9..12, 17]`.** Superseded as the foundation boundary. `[CEX-9..12]`
survive as design intent for the built-in default pack — what a GBA-style ruleset looks
like once authored — not as behavior the migration must preserve, which the owner
withdrew on 2026-09-10. `[CEX-17]` is unbuilt and therefore still live; see `[ITR-5]`.

---

### [ITR-1] Scope and subjects — **[RESOLVED 2026-09-10]**
**RESOLVED:** `InteractionRuleResolver` is context-agnostic. A caller supplies a named
context and named subjects; profiles declare which contexts and subject bindings they
accept. Combat may bind `source`, `target`, and `equipped_source`; movement or economy
may bind different subjects without changing the evaluator.

**Binding is the caller's job, and the existing code gets this wrong.**
`_triangle_accuracy(attacker, defender)` re-reads `attacker.get_equipped_weapon()` and
discards the `weapon` its caller `compute_hit_pct` already resolved. Latent today, and
visibly wrong under `[CAU-1A]`'s live source cycling. The adapter binds subjects from the
caller's context and never re-reads the unit.

### [ITR-2] Trait vocabulary — **[RESOLVED 2026-09-10]**
**RESOLVED:** rules compose existing or engine-added predicates and registries. A pack
may use a newly registered `undead` trait beside `armoured`, `mounted`, or `dragon`.
Relationship data does not create an independent bag-of-tags system and does not admit
unknown ids merely because they are strings. `RequirementSystem` is the sole selector
language; interaction rules reference it and do not embed a trait-specific mini-language.

### [ITR-3] Effects and scaling — **[RESOLVED 2026-09-10]**
**RESOLVED:** a match emits registered effect compositions. Literal parameters and
registered formula references share the caller's context. No stat-name switch, WEXP-only
scaler, or built-in advantage payload belongs in the generic evaluator.

Formula safety reuses `[CRR-3]` (preset selection + sandboxed expression, GDScript
rejected) and `[CRR-7]` (determinism constraints) rather than defining a second sandbox.

### [ITR-4] Multiple matches — **[RESOLVED 2026-09-10]**
**RESOLVED:** authors own general priority and stacking. Each rule declares `priority`
and `stack_group`; the group declares `first|highest|lowest|sum|multiply|all`, with
stable declaration order as the last tie-breaker. A profile can explicitly stop lower
priority groups. Validation rejects ambiguous or unsupported composition rather than
silently choosing a winner.

**Arity is authored, not preserved (owner, 2026-09-10).** Today `_is_effective()` is
first-match-wins, so a weapon tagged both `effective_mounted` and `effective_armoured`
against a target in both groups yields exactly 3×. As rules, the same pair stacks
naturally. Whether a pack wants 3×, 6× or 9× is its choice. The engine's obligation is
that the composition be **legible and deterministic** — group and policy visible in the
authored data and in the provenance record — not that it reproduce the old number.

### [ITR-5] Sufficiency of the composition vocabulary — **[RESOLVED 2026-09-10]**
**RESOLVED: two profiles, not a transform policy.** `first|highest|lowest|sum|multiply|all`
all *select or aggregate* matches; none *transforms* one. `[CEX-17]` (reaver) needs
"invert the winner of another rule, then multiply its magnitude" — parity across both
combatants' weapons, inverting advantage↔disadvantage and doubling. That is not
expressible in the policy list.

It is expressed instead as a **mirrored profile at higher priority that suppresses the
base group**, with the parity condition as a predicate reading a property of both
subjects and the multiplier applied per rule. A transform policy is rejected: it is a
small door into a general rewriting system, and the evaluator stays dumb by design.

**Slice 3 must carry reaver as a worked example in its contract.** Reaver is the only
authored feature already ruled that the vocabulary has to carry, so "we checked it fits"
must be demonstrated there rather than discovered in slice 7.

### [ITR-6] One truth for consumers — **[RESOLVED 2026-09-10]**
**RESOLVED:** resolution returns provenance-rich records naming matched and suppressed
rules, predicate traces, formula results, and effect payloads. Execution, forecast,
preview, AI, and diagnostics consume that result; none may independently re-evaluate a
shadow version of the relationship.

**Two existing violations are in scope, both found 2026-09-10.**
1. `preview_combat()` and `project_exchange()` are separate implementations of the same
   math and have already drifted — the projection path applies `damage_multiplier` and
   passes a weapon to `target.dodge()`; the live path does neither. `project_exchange`
   has **no non-test caller**. Slice 4 converges them; do not retire it, it is the
   closest thing to `[CAU-5]`'s `distribution` fidelity level.
2. `_current_triangle_profile()` reads `/root/GameState` per hit and per damage
   computation (as does `_current_hit_formula()`). Resolve once in
   `_build_combat_context()`, which already builds the transaction and sink every path
   shares, or this ruling is decorative.

**Readout (owner, 2026-09-10): authored presentation over a generic fallback.** A profile
may declare label, glyph, color and display order; anything it does not declare renders
generically from the provenance record. A forked pack inherits its parent's presentation;
the editor supplies defaults for a profile authored from scratch. This owns two code
facts: `preview_combat()` returns `attacker_triangle: String` (one value, three legal
words), and `AttackPreview` has two marker slots per side. Both change in slice 6.

`MoreInfoContent.COMBAT_FIELDS["triangle"]` is a hardcoded string and is **already false**
against the shipping table — it claims "Tomes follow fire>wind>thunder>fire" when
`WEAPON_TRIANGLE` makes the anima trio mutually neutral and only dark/light polarize it.
It is generated from the authored data in slice 6, not corrected in place.

### [ITR-7] Collision ownership — **[RESOLVED 2026-09-10]**
**RESOLVED after whole-project scan:** the serialized family is `interaction_profiles`,
not `relationships`; `RelationshipSystem` remains reserved for B6 social/support state.
RequirementSystem owns selection, shared effects own mutations and transactions, bounded
value terms/formula registries own arithmetic, and domain adapters own legal
contexts/phases/targets. The generic resolver owns only rule matching, priority/stacking,
parameter resolution, suppression provenance, and result composition. The effectiveness
migrations in the movement/vulnerability and predicate-combat plans are absorbed here
rather than built as parallel paths.

> **Amended 2026-09-10 (second pass).** Two boundaries moved once combat order became
> author-configurable:
> - The **predicate-driven combat operations plan is re-scoped, not absorbed.** Its
>   generic rule selection/composition is still absorbed here, but its immutable-phase
>   model is now the data model for `[ACM]`.
> - **`[CRR-1..8]` was missed by the original scan** and had already ruled hit resolution
>   author-selectable, with `CRR-8` deferring "registry + author tiers". `[ACM]` owns that
>   deferred half; it is not a new system.
>
> The naming boundary itself is unchanged and remains the most load-bearing line here.

---

## Adoption proof

Completion requires an authored pack loaded through `select_campaign()` and played. It
must **register a new non-weapon trait** and **position a node in the weapon hierarchy**,
define separate profiles, and demonstrate authored priority/stacking, formula scaling,
and an extra effect. A magic triangle is a useful fixture, not the objective, and
balance/fun is not its gate.

> **Corrected 2026-09-10.** The first wording asked the pack to "add a weapon hierarchy
> node" as its registration proof. The magic fixture does not do that: `fire`, `thunder`,
> `wind`, `light` and `dark` already ship as combat families, and
> `GameConstants.combat_family_to_wexp_track()` already folds the anima trio into an
> `elemental_magic` track — the REN-1-safe name. A magic triangle over existing families
> proves the evaluator, not registration. The trait half carries that.

The wider gate — replicating whole rulesets from multiple games accurately — belongs to
`[ACM]`, not here.
