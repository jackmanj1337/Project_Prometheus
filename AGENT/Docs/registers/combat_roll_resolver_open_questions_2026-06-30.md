---
Type: register
Status: RESOLVED 2026-06-30
Last verified: 2026-06-30
Register: CRR-1..8
Resolved-in: 2026-06-30
---

# Combat Roll Resolver — Author-Selectable Hit Formula — Open Questions

**Started:** 2026-06-30
**Status:** [CRR-1..8] **RESOLVED 2026-06-30** (owner decisions captured) —
build-ready as a Band 1 Slice 1b seam plus a Band 3 follow-on.
**Corrected in place 2026-09-10:** `CRR-5` is narrowed and `CRR-8`'s deferred half is
reassigned — see both entries. Prompted by the owner ruling that combat math and its
order become author-configurable (`registers/authored_combat_math_open_questions_2026-09-10.md`,
`[ACM]`). Only the built-in seam was ever built: `_hit_two_roll` / `_hit_single_roll`
selected by `CampaignRules.hit_formula`.
**Source:** owner request to make the hit-roll formula author-writeable
(choose 1-roll / 2-roll / write their own).
**Pattern:** open registry over closed enum — engine provides the roll primitive
and a fixed set of built-in resolvers; authors compose more. Aligns with the
AGENTS.md author-extensibility principle and the ratified data-only authoring +
sandboxed-scripting ceiling.
**Companions:** [`rng_determinism_design_2026-06-11.md`](../design/rng_determinism_design_2026-06-11.md)
(RNG-1..4, RULE-001 two-RN model), the Band 1 Slice 1b roll migration in
[`band1_determinism_save_implementation_plan_2026-06-30.md`](../plans/band1_determinism_save_implementation_plan_2026-06-30.md),
and the [`requirement_predicate_system_open_questions_2026-06-25.md`](requirement_predicate_system_open_questions_2026-06-25.md)
sandbox-evaluation idiom.

---

## State today (code-grounded)

- The hit roll is a single raw draw: `(randi() % 100) < hit_pct` in
  `CombatResolver._resolve_single_attack` (`scripts/core/CombatResolver.gd:450`),
  flagged `# rng-allow: pre-M9a`. Crit is the same shape at line 457.
- The displayed hit percentage is computed separately and cleanly by
  `compute_hit_pct` (`scripts/core/CombatResolver.gd:322`); the roll only
  compares against that number.
- `GDD_02` ratifies the two-RN model as **RULE-001**, and the RNG design doc
  marks the single-roll rule "**Superseded by RULE-001**." Making the formula
  author-selectable therefore **reframes** RULE-001 rather than replacing it.

---

## Decisions

**CRR-1 — Hit resolution becomes an author-selectable resolver. RESOLVED.**
RULE-001 (two-RN true hit) is demoted from "the hit rule" to the **default
preset** among author-selectable resolvers. `single_roll` ships as a second
built-in preset. This is a governance change: when the seam lands (Band 1 Slice
1b), update `GDD_02`, the `GDD_01` canonical-roll-order note, the RNG design doc,
and the decision log in the **same** implementation commit (DoD#1), reframing
RULE-001 as the default rather than deleting it.

**CRR-2 — Resolver contract = declared fixed `rn_count` + a pure predicate over
pre-drawn RNs. RESOLVED.**
The engine draws `rn_count` integers in `[0, 100)` from the combat event's seeded
RNG in canonical order, then calls a **pure** function
`did_hit(displayed_hit: int, rns: Array[int]) -> bool`. The formula never draws
RNs itself. This preserves RNG-1 (fixed, ordered draws per event), RNG-2 (replay
/ suspend), and RNG-4 (host-authoritative online result payloads).
- `single_roll`: `rn_count = 1`, `rns[0] < displayed_hit`.
- `two_roll` (RULE-001 default): `rn_count = 2`,
  `(rns[0] + rns[1]) / 2 < displayed_hit`.

**CRR-3 — Author tiers = preset selection + sandboxed expression; GDScript
handler is fork-only. RESOLVED (owner).**
1. **Pick a preset** (`single_roll` / `two_roll`) — pure data.
2. **Sandboxed expression string** over `rns` and `hit`, evaluated with Godot
   `Expression` (e.g. `(rns[0] + rns[1]) / 2 < hit`) — fits the data-only +
   scripting-ceiling decision; the expression cannot draw RNs, read globals, or
   mutate state.
3. **Registered GDScript handler** — fork tier only (MIT + Commons-Clause source
   = full access by fork). Not exposed to data-only authors.

**CRR-4 — Selection lives in `CampaignRules.hit_formula`. RESOLVED.**
Campaign-default scope. Per-map override is deferred unless a concrete content
case needs it. The selection is saved state and **requires an F1 manifest row**
(lands with the Slice 6 CampaignRules consolidation). For a custom expression,
the saved value is the resolver id; the expression string is authoring data, not
per-save state.

**CRR-5 — Displayed hit % stays `compute_hit_pct`. RESOLVED, then NARROWED 2026-09-10.**
The number shown to the player is unchanged by the resolver; the resolver only
governs roll → hit/miss. An optional per-resolver `display_odds(hit, rn_count)`
transform (to surface "true odds" for the two-RN curve) is **deferred** — not v1.

> **Narrowed 2026-09-10.** Naming `compute_hit_pct` as the readout authority does not
> survive `[ACM-1]`: once the hit pipeline is authored, a fixed function cannot be where
> the displayed number comes from, or the forecast and the fight would compute hit
> differently — which is exactly what `[ITR-6]` forbids. **The displayed number comes
> from the authored pipeline's own result.**
>
> The *intent* of this ruling survives and is the stronger half: the player sees the
> **displayed** odds, and the resolver's internal true-hit curve is not exposed unless a
> pack opts into a `display_odds` transform. That separation stands. Only the named
> function changes.

**CRR-6 — Generalizes to any 0–100 check; hit is the first consumer. RESOLVED
(forward-note).**
Crit (`CombatResolver.gd:457`) and skill activation (`SkillHandler`) are the same
`probability-check` shape. Build hit first; reserve the resolver family name so
crit/activation can adopt it without a second mechanism. Do not convert them in
the Slice 1b pass.

**CRR-7 — Determinism constraints on custom predicates. RESOLVED.**
A custom resolver MUST: declare a fixed `rn_count`; be a pure function of
`(displayed_hit, rns)`; read no time, no globals, no live unit/map state; and
have no side effects. The sandboxed `Expression` evaluator enforces the no-RN /
no-state / no-side-effect bounds structurally. A resolver that violates these
breaks replay, suspend, and online parity.

**CRR-8 — Sequencing: built-in seam in Band 1 Slice 1b; registry + author tiers
in Band 3. RESOLVED (owner).**
`RegistryManager` is Band 2, after Slice 1b. So Slice 1b builds the roll behind
the CRR-2 pure-predicate seam with the two built-ins selected by
`CampaignRules.hit_formula` (two engine built-ins = a bounded built-in set, not a
content-growth enum). The registry promotion (resolvers become `RegistryEntry`
data) and the tier-2 sandboxed-expression / tier-3 handler paths land later as
`B3-COMBAT-ROLL-RESOLVER`, after `B2-REGISTRY` and `B3-CAMPAIGN-RULES`.

> **Reassigned 2026-09-10.** The deferred half — the registry and the author tiers — is
> owned by `AUTHORED-COMBAT-PIPELINE-2026-09-10` (`[ACM]`), not by a separate
> `B3-COMBAT-ROLL-RESOLVER` build. The owner ruling that all combat math becomes
> author-configurable **does not open a new system for hit**; it completes this. Two
> consequences worth stating so the pipeline row does not reinvent them:
> - **`CRR-3` and `CRR-7` are the authored-formula safety model for the whole pipeline.**
>   Preset selection plus sandboxed expression, GDScript rejected, fixed `rn_count`, pure
>   function of its inputs, no globals, no side effects. Do not define a second sandbox.
> - **`CRR-6` predicted the generalization.** It reserved the resolver family for crit and
>   skill activation. `[ACM-7]` asks whether it extends once more, to the `[REQ-10]`
>   chance gate, so that combat rolls and requirement chances are one mechanism rather
>   than three registries for one primitive.

---

## Build obligations

- Band 1 Slice 1b: implement the pure-predicate roll seam + `single_roll` /
  `two_roll` built-ins + `CampaignRules.hit_formula`; reframe RULE-001 in the
  governance docs in the same commit.
- F1: reserve a `campaign.hit_formula` manifest row (Slice 3 / Slice 6).
- Tests: roll-resolver unit tests (both built-ins reproduce their literal
  outcomes for fixed `rns`), determinism replay still green, projection/preview
  shows the unchanged displayed hit.
- Band 3 `B3-COMBAT-ROLL-RESOLVER`: registry promotion + sandboxed expression
  tier + handler tier + sandbox-bounds tests.
