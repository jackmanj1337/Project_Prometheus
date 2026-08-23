---
Role: dated
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

**CRR-5 — Displayed hit % stays `compute_hit_pct`. RESOLVED.**
The number shown to the player is unchanged by the resolver; the resolver only
governs roll → hit/miss. An optional per-resolver `display_odds(hit, rn_count)`
transform (to surface "true odds" for the two-RN curve) is **deferred** — not v1.

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
