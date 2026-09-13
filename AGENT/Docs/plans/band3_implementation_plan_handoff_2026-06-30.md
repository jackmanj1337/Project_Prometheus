---
Role: dated
Type: plan
Status: Active - next-session handoff
Last verified: 2026-06-30
---

# Band 3 Implementation Plan — Next-Session Handoff

**Purpose.** Hand the next session everything it needs to write one combined
Band 3 core-authoring-foundations implementation plan, the same way the Band 1
and Band 2 plans were drafted. This doc does not write the plan; it scopes it,
lists read-first material, fixes the bootstrap order, names the decisions not to
reopen, and surfaces the owner questions.

**Deliverable to produce next session:**
`AGENT/Docs/plans/band3_core_authoring_foundations_implementation_plan_2026-07-XX.md`
(one combined plan with ordered slices), plus updated Band 3 control-plane rows,
a regenerated docs index, and a commit.

## Gating Reality

Plan now; implement after gates. Band 3 implementation must not start before:

- `B1-PKGA` (deterministic RNG) and `B1-F1` (save-schema manifest) land.
- `B2-REGISTRY` exists — every Band 3 vocabulary (`TCV`, `REQ`, stat, movement,
  resource types, roll resolvers) is a registry consumer.
- The relevant Band 2 services exist for the consumers that need them
  (`B2-ACTION-EFFECT` for `MET`/`PHB`, `B2-RESOURCE-LEDGER` for resource pools).

Writing the plan now is fine; it is a planning artifact, not a build authorization.

## Rows To Cover

From the Project Control Plane Band 3 block
([`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)):

- `B3-CAMPAIGN-RULES` — CampaignRules profiles and tunables.
- `B3-COMBAT-ROLL-RESOLVER` — **new this session.** Promote the Slice 1b built-in
  hit resolvers to registry entries and open the tier-2 sandboxed-expression /
  tier-3 handler author paths. See `[CRR-1..8]`.
- `B3-TCV` — typed campaign-variable store.
- `B3-REQ` — requirement / predicate system.
- `B3-MET` — map events / triggers framework.
- `B3-PHB` — prep-hub / option-panel framework.
- `B3-TEXT` — text indirection.
- `B3-MOVEMENT-VULN-REGISTRY` — already has a sub-plan; reuse, do not rewrite.
- `B3-STAT-REGISTRY` — already has a sub-plan; reuse, do not rewrite.
- `B3-RESOURCE-POOLS` — author resources and unit pools.
- `B3-CALENDAR-LITE` — keep optional/deferred unless a concrete v1 cadence
  consumer is named.

## Bootstrap Order (Do Not Get Wrong)

These dependencies decide the slice order inside the plan:

1. **Registry foundation first.** `B2-REGISTRY` underpins every Band 3 vocabulary.
   Nothing in Band 3 loads before it.
2. **`B3-TCV` before `B3-REQ`.** Variable definitions must validate before
   predicates depend on them. Plan their bootstrap carefully so a predicate can
   reference a variable that is already type-checked.
3. **`B3-REQ` before gated authoring features** (`MET` conditions, shop stock,
   objective predicates, perception, AI terms).
4. **`B3-STAT-REGISTRY` before** anything reading author stats in formulas
   (dynamic pricing, Charisma/Command content).
5. **`B3-CAMPAIGN-RULES` before `B3-COMBAT-ROLL-RESOLVER`.** The resolver registry
   promotion reads the `CampaignRules.hit_formula` selection that the Band 1
   Slice 1b seam introduces; the two built-ins already ship under `B1-PKGA`.
6. **`B2-ACTION-EFFECT` before `B3-MET`/`B3-PHB`** — both execute primitives
   through the shared runner, not private switches.

## Read First

1. This handoff.
2. [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
   Band 3 rows (now including `B3-COMBAT-ROLL-RESOLVER`).
3. [`band1_determinism_save_implementation_plan_2026-06-30.md`](band1_determinism_save_implementation_plan_2026-06-30.md)
   for F1 obligations and the Slice 1b roll-resolver seam.
4. [`band2_shared_runtime_contracts_implementation_plan_2026-06-30.md`](band2_shared_runtime_contracts_implementation_plan_2026-06-30.md)
   for registry/action/ledger prerequisites.
5. [`movement_vulnerability_registry_implementation_plan_2026-06-29.md`](movement_vulnerability_registry_implementation_plan_2026-06-29.md)
   — reuse as a Band 3 sub-plan.
6. [`stat_registry_implementation_plan_2026-06-29.md`](stat_registry_implementation_plan_2026-06-29.md)
   — reuse as a Band 3 sub-plan.
7. Registers named by the Band 3 rows:
   [`difficulty_death_mode_open_questions_2026-06-27.md`](../registers/difficulty_death_mode_open_questions_2026-06-27.md),
   [`typed_campaign_variable_store_open_questions_2026-06-27.md`](../registers/typed_campaign_variable_store_open_questions_2026-06-27.md),
   [`requirement_predicate_system_open_questions_2026-06-25.md`](../registers/requirement_predicate_system_open_questions_2026-06-25.md),
   [`map_events_triggers_open_questions_2026-06-21.md`](../registers/map_events_triggers_open_questions_2026-06-21.md),
   [`prep_hub_open_questions_2026-06-23.md`](../registers/prep_hub_open_questions_2026-06-23.md),
   [`dialogue_conversation_system_open_questions_2026-06-25.md`](../registers/dialogue_conversation_system_open_questions_2026-06-25.md),
   [`training_halls_open_questions_2026-06-27.md`](../registers/training_halls_open_questions_2026-06-27.md),
   and the new
   [`combat_roll_resolver_open_questions_2026-06-30.md`](../registers/combat_roll_resolver_open_questions_2026-06-30.md).

## Recommended Plan Shape

- Frontmatter: `Type: plan`, `Status: Active - implementation plan`,
  `Last verified: <date>`.
- Purpose, scope, non-goals.
- Dependency note: planning now; implementation after Band 1 and Band 2 gates.
- Ordered slices following the bootstrap order above. Each slice carries:
  files-to-touch, implementation steps, tests, F1/save rows, registry
  obligations, and DoD#2 obligations.
- Explicitly reuse the existing movement/vulnerability and stat-registry
  sub-plans by reference instead of restating them.
- After adding the plan: update the Band 3 control-plane rows to point at it, run
  `python3 AGENT/Docs/gen_docs_index.py`, `python3 AGENT/Docs/check_docs.py`, and
  `git diff --check`, then commit the plan and generated index together.

## Decisions Not To Reopen

- Author-facing vocabularies are open registries / data composition, not closed
  `enum` + `match`. No new closed switch for a growing content vocabulary.
- F1 owns saved-field manifest rows before any Band 3 feature adds saved state.
- `B3-TCV`/`B3-REQ` reuse the existing modifier + tags + F16 substrate; they
  assemble, they do not invent a parallel system.
- The hit-roll resolver design is settled at `[CRR-1..8]`: built-in presets +
  sandboxed expression (fork-only handlers); the registry promotion is the Band 3
  scope, the two built-ins ship under `B1-PKGA` Slice 1b. Do not re-derive it.
- `B3-CALENDAR-LITE` stays optional/deferred unless a concrete v1 consumer is
  named.

## Owner Questions To Surface

Raise these while drafting; do not assume answers:

- Does any Band 3 vocabulary need a per-map override scope in v1, or is
  campaign-default scope enough for the first plan (matches `[CRR-4]`)?
- Should the combined plan sequence `B3-COMBAT-ROLL-RESOLVER` as a late slice
  (after `B3-CAMPAIGN-RULES`) or split it into its own follow-on plan like the
  movement/stat sub-plans?
- Is `B3-RESOURCE-POOLS` in the first Band 3 plan, or deferred until a concrete
  training/shop consumer pulls it forward?

## Watchouts

- Do not start Band 3 implementation before `B2-REGISTRY` and the relevant Band 2
  services exist.
- Do not add saved Band 3 fields without F1 manifest rows.
- Keep `B3-TCV` → `B3-REQ` bootstrap order explicit in the slice sequence.
- Reuse, do not rewrite, the movement/vulnerability and stat-registry sub-plans.
