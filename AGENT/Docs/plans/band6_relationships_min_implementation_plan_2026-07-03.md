---
Role: dated
Type: plan
Status: Active - implementation plan
Last verified: 2026-07-03
---

# Band 6 Relationships Minimum Implementation Plan

**Started:** 2026-07-03.

**Track IDs:** `B6-RELATIONSHIP-MIN`.

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
Band 6 rows. Drafted from the settled **Q9** walkthrough decision (2026-07-01)
and the RESOLVED register `[REL-1..9]`.

## Purpose

Build the minimal FE-style **relationship** substrate: a pair-keyed bond graph,
data-driven ranks (`RelationshipProfileDef`), pair-keyed gain sources with
anti-grind caps, per-unit rank-scaled proximity benefit auras, and optional
conversation-unlock hooks fired through TCV/the existing dialogue system. The v1
demo has a small roster, so support content is cheap and fuller pairwise coverage
stays affordable later without engine change (Q9).

Everything growable is registry/`CampaignRules` data — ranks, gain-source knobs,
on-crossing verbs, and per-unit benefit lists are authored, not hardcoded. Adding
a rank, a gain source knob, or a benefit is content, not an engine edit ([EXT]).

This is a build plan only. It does not authorize starting before the gates land.

## Scope

1. **Pair-keyed relationship graph (`[REL-2]`).** A complete, both-sides-
   denormalized bond table (the pattern `PairUpRegistry` already uses); every
   co-deployed pair can accrue. Snapshots/saves with the roster.
2. **Data-driven ranks (`[REL-3]`).** A `CampaignRules` "relationship" rank
   profile (ordered `{name, threshold}`, e.g. C/B/A/S) resolved by the reused
   `[PXP]` accumulator→profile→trigger resolver. Optional exclusive top rank.
3. **Pair-keyed gain sources + anti-grind (`[REL-4]`, `[REL-5]`).** Three new
   gain-source kinds (`co_deployment_survival`, `end_turn_proximity`,
   `class_exp_relationship_share`) feeding the pair accumulator, plus a
   per-pair-per-map cap.
4. **Benefit aura payload (`[REL-7]`).** Per-unit directional, rank-scaled,
   proximity-gated benefit list against the existing modifier/aura vocab.
5. **On-crossing hooks (`[REL-6]`).** Extend the PXP trigger vocab with
   `unlock_conversation` + `set_flag`; conversations are sparse optional authored
   hooks fired via TCV conditions through the existing event/dialogue system.

## Non-Goals

- **No new progression engine.** Relationship ranks **reuse the `[PXP]` resolver**
  (accumulator → named profile → on-crossing triggers), not its per-unit storage
  (`[REL-1]`). Class EXP (`Unit.add_exp`) is **not** rebuilt on this engine.
- **No dense support UI.** Support logs, affinity grids, and rich relationship
  screens are deferred (`[REL]` §3). v1 = the substrate + optional conversation
  unlock + the benefit aura.
- No bespoke relationship-scripting engine. Conversations ride TCV conditions +
  the existing dialogue system.
- Do not collide with the pair-up combat role: the word is **"relationship"**;
  `support` / `ROLE_SUPPORT` stay the pair-up combat partner role (`[REL]` §4).
- Relationship benefit, pair-up bonus, and Charm are **three independent stacking
  auras** — do not fold relationship benefit into either (`[REL-7]`/`[REL-9]`).

## Source Docs

- [`band5_plus_preimplementation_questions_review_2026-06-30.md`](../../Code%20Reviews/band5_plus_preimplementation_questions_review_2026-06-30.md)
  → "Walkthrough Decisions (2026-07-01)" **Q9**.
- [`relationship_system_open_questions_2026-06-24.md`](../registers/relationship_system_open_questions_2026-06-24.md)
  (`[REL-1..9]` RESOLVED — the design this plan implements).
- The `[PXP]` proficiency-track design (resolved 2026-06-23l, **not yet built**) —
  the resolver this plan reuses; `[REL-9]` hands the PXP build the pair-agnostic +
  gain-source + trigger-verb requirements.
- [`provoke_relationship_action_open_questions_2026-06-25.md`](../registers/provoke_relationship_action_open_questions_2026-06-25.md)
  (adjacent — a later gain avenue that rides `[REL-6]`, not v1 scope).

## Decisions Not To Reopen

- Reuse the PXP resolver, **not** its storage; class EXP stays separate (`[REL-1]`).
- The graph is **complete + pair-keyed**, denormalized both-sides for O(1) queries
  (`[REL-2]`).
- Ranks are a `CampaignRules` named profile (`[REL-3]`); the top rank may be
  exclusive via a `CampaignRules` toggle (`[REL-8]`).
- Gain sources are the three pair-keyed kinds (`[REL-4]`); anti-grind is a
  per-pair-per-map cap baked in from slice 1 (`[REL-5]`).
- Benefits are per-unit directional lists, rank-scaled, proximity-gated, using the
  **same radius primitive** as proximity gain (`[REL-7]`) — one primitive powers
  proximity gain, class-EXP share, and the benefit aura.
- On-crossing adds `unlock_conversation` + `set_flag` to the PXP vocab (`[REL-6]`);
  conversations are optional authored hooks.
- The one PXP-build requirement (`[REL-9]`): the resolver is extracted
  **pair-agnostic** from day one, not retrofitted.

## Dependency Note

Plan now; implement after gates. Minimum upstream gates:

- **`[PXP]` engine (unbuilt)** — the hard gate. `[REL-9]` requires the PXP build
  land pair-agnostic with the REL-4 gain kinds + REL-6 verbs. **If PXP is built
  before this, confirm it honored `[REL-9]`; if PXP is unbuilt, this plan's Slice 1
  extracts the resolver pair-agnostic as part of the PXP build.**
- `B1-F1` — the pair-keyed graph, per-pair per-map gain counters, and the
  `CampaignRules` relationship profile/knobs/exclusivity toggle are F1-reserved
  (`[REL-9]`).
- `B4-DIALOGUE-V1` — the conversation-unlock hook fires through the existing
  event/dialogue system.
- `B4-PXP` / `B3-STAT-REGISTRY` — `class_exp_relationship_share` hooks
  `Unit.add_exp`; benefit auras use the modifier/aura vocab.
- The proximity radius primitive (`[REL-4]`/`[REL-7]`) — one primitive; build once.

## Existing Code Touchpoints

Verified 2026-07-03:

- **No relationship system exists** (`[REL]` §1) — no ranks, store, or
  conversations. This is net-new, built on the (unbuilt) PXP resolver.
- `PairUpRegistry` / `PairUpBonusTable` / `PairUpBonusResolver` — the pair-up
  **combat** role + the both-sides-denormalized pattern the graph copies. The
  Charm aura helper lives here too. Relationship benefit must **not** feed these.
- `UnitData.active_modifiers` — the generic modifier/aura vocab the benefit
  payload authors against (no new payload type, `[REL-7]`).
- `Unit.add_exp` — the single class-EXP entry point `class_exp_relationship_share`
  hooks (class EXP feeds, does not become, relationship progression).
- `UnitData.proficiency_xp` — per-unit PXP storage the relationship graph
  **deliberately does not use** (a relationship is an edge, not a per-unit value).
- Tests to create: `test_relationship_graph.gd`, `test_relationship_gain.gd`,
  `test_relationship_benefit.gd`; extend `test_pair_up_*` for non-collision.

## Slice 0 - Preflight: Extract The PXP Resolver Pair-Agnostic

**Goal:** satisfy `[REL-9]` — the accumulator→profile→trigger resolver is
pair-agnostic before relationship rides it.

Implementation checklist:

- Confirm the `[PXP]` engine's resolver takes a generic subject key (unit id OR
  pair key), not a hardcoded per-unit lookup. If PXP is already built per-unit,
  this slice refactors it pair-agnostic (reconcile-don't-break: the default weapon
  proficiency profile is unaffected).
- Confirm the on-crossing trigger vocab is extensible (verbs are data).
- Reserve the F1 rows (graph, per-pair per-map counters, relationship profile +
  knobs + exclusivity toggle).

Tests: the existing PXP proficiency profile still resolves unchanged after the
pair-agnostic extraction (regression).

## Slice 1 - Pair-Keyed Graph + Rank Profile + Anti-Grind Cap

**Goal:** the bond store, ranks resolved through PXP, and the anti-grind cap baked
in from the start.

Files to create or touch:

- `scripts/resources/RelationshipGraph.gd` (pair-keyed, both-sides denormalized)
- `scripts/resources/RelationshipProfileDef.gd` (ordered `{name, threshold}`)
- `scripts/resources/CampaignRules.gd` (relationship profile + cap + exclusivity
  toggle knobs)
- `scripts/tests/test_relationship_graph.gd`

Implementation steps:

1. `RelationshipGraph`: a pair-keyed table (stable unit id pair → accumulated
   points), denormalized both-sides for O(1) queries. Snapshots/saves with the
   roster.
2. `RelationshipProfileDef` = a `CampaignRules` named rank profile (`[PXP-3]`):
   authored names + thresholds (C/B/A/S). Resolve a pair's rank via the PXP
   resolver (accumulator vs profile).
3. Anti-grind: a `CampaignRules` **max-points-per-pair-per-map** cap, enforced in
   the accumulator from slice 1 (per-pair per-map counter, F1-saved).
4. Exclusive top rank (`[REL-8]`): a `CampaignRules` toggle; when on, a unit may
   hold the top rank with only one partner (block the crossing at the cap for
   others). Avatar (#20) hooks this slot later.

Tests:

- A pair accrues points and crosses C/B/A per the authored thresholds.
- The per-pair per-map cap stops farming (parked-adjacent units stop gaining once
  capped; resets next map).
- Both-sides queries agree (A↔B is one bond).
- With the exclusivity toggle on, a second top-rank crossing is blocked.
- Adding a rank name/threshold is data (no engine edit).

F1 obligations: graph + per-pair per-map counters + relationship profile/cap/
toggle rows — must exist before code.

DoD#1 obligations: update `GDD_03`/`GDD_05` (relationship system) + flip
`GDD_10_Roadmap`.

DoD#2 obligations: `check_docs.py` profile/field checks land WITH the build (per
the `[PXP]` staged-build DoD) — guard the relationship profile fields + the
gain-source / on-crossing-verb value-sets.

## Slice 2 - Pair-Keyed Gain Sources

**Goal:** the three ways a bond grows, all feeding the capped accumulator.

Files to create or touch:

- `scripts/autoloads/` relationship-gain hooks (map-completion, player-phase-end,
  `Unit.add_exp`)
- the proximity radius primitive (shared, `[REL-4]`/`[REL-7]`)
- `scripts/tests/test_relationship_gain.gd`

Implementation steps:

1. `co_deployment_survival` — on map completion, every co-deployed surviving pair
   gains a flat `CampaignRules` amount (pair-keyed `per_map_carry` variant).
2. `end_turn_proximity` — at player-phase end, each pair within radius **R** gains
   `f(distance)` (closer = more; pair-up/rescue = distance 0 = max). R, falloff,
   and max are `CampaignRules` knobs. Build the **proximity radius primitive** here
   (reused by class-EXP share + the benefit aura).
3. `class_exp_relationship_share` — on `Unit.add_exp`, qualifying edges gain a flat
   or % of the class EXP, using the same proximity machinery with **independent
   knobs** (own radius/curve/toggle).
4. All three route through the capped accumulator (Slice 1) — no source bypasses
   the anti-grind cap.

Tests:

- Two surviving co-deployed units gain on map completion; a dead partner's pair
  does not.
- End-turn proximity gives more the closer the pair; pair-up counts as max.
- Class-EXP share adds to qualifying nearby edges with its independent knobs.
- Every source is capped by the per-pair per-map limit.
- Adding/removing a gain-source knob is `CampaignRules` data.

F1 obligations: gain counters covered by Slice 1's per-pair per-map rows.

DoD#1 obligations: update `GDD_03`/`GDD_07` + flip `GDD_10_Roadmap`.

DoD#2 obligations: guard the gain-source-kind value-set matches the GDD.

## Slice 3 - Benefit Aura + On-Crossing Hooks

**Goal:** ranks pay off mechanically (the benefit aura) and narratively (optional
conversation unlock).

Files to create or touch:

- `scripts/resources/UnitData.gd` (per-unit directional benefit list authoring)
- the benefit-aura applier (reuses the proximity primitive + `active_modifiers`)
- the PXP on-crossing trigger vocab (`unlock_conversation`, `set_flag`)
- `scripts/tests/test_relationship_benefit.gd`

Implementation steps:

1. Each unit authors a **list of benefits it confers** to everyone it has a
   relationship with (directional + per-unit, `[REL-7]`), as entries against the
   existing modifier/aura vocab — not a new payload type.
2. Apply the benefit as a **proximity-gated aura** (same radius primitive as
   Slice 2), **rank-scaled** (none at rank 0, growing C→B→A→S). It stacks
   **independently** of pair-up bonus and Charm.
3. On-crossing: extend the PXP trigger vocab with `unlock_conversation` and
   `set_flag`. A crossing fires a conversation **only where an author wrote one**
   (sparse optional hooks) via a TCV condition ("pair X at rank B") through the
   existing event/dialogue system (`B4-DIALOGUE-V1`).
4. Recruit/Capture support-gating (`[REL]` §4 A4 hand-off) uses the same
   `set_flag`/`unlock_conversation` — do not build a second path.

Tests:

- A rank-C benefit applies only while the partner is within range; drops when out
  of range; scales up at rank B/A.
- The benefit stacks with (does not replace) pair-up bonus + Charm (three auras
  co-apply).
- Crossing a threshold with an authored `unlock_conversation` fires it via TCV;
  a crossing with no authored hook does nothing.
- `set_flag` on crossing sets a TCV flag a later condition reads.
- Adding a benefit entry / on-crossing verb usage is data (no engine edit).

F1 obligations: none new (benefits are authored content; crossing state derives
from the graph).

DoD#1 obligations: update `GDD_03`/`GDD_05` (benefits + conversations) + flip
`GDD_10_Roadmap`.

DoD#2 obligations: guard the on-crossing verb value-set (`grant_skill`,
`unlock_conversation`, `set_flag`, …) matches the GDD.

## Implementation Commit Order

1. Slice 0 preflight — PXP resolver pair-agnostic (`[REL-9]`).
2. Slice 1 pair-keyed graph + rank profile + anti-grind cap.
3. Slice 2 the three pair-keyed gain sources (+ the shared proximity primitive).
4. Slice 3 benefit aura + on-crossing conversation/flag hooks.

The whole plan gates on the `[PXP]` engine (`[REL-9]`); Slice 3's conversations
additionally gate on `B4-DIALOGUE-V1`. Build the proximity radius primitive once
in Slice 2 and reuse it in Slice 3.

## Verification Checklist

Same as the Band 2/3/4/5 plans. Run after each implementation slice:

```bash
python3 AGENT/Docs/check_docs.py
git diff --check
./run_tests.sh
```

Docs-only edits to this plan require:

```bash
python3 AGENT/Docs/gen_docs_index.py
python3 AGENT/Docs/check_docs.py
```
