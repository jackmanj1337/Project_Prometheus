---
Role: dated
Type: plan
Status: Active - implementation plan
Last verified: 2026-07-28
---

# Predicate-Driven Combat Operations Implementation Plan

**Tracker:** `PREDICATE-COMBAT-OPERATIONS-PLAN-2026-07-28`  
**Source decision:** `Project_Prometheus_Campaign_Pack_FE/docs/fed20_review_decisions.md`  
**Control-plane ownership:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
rows `B3-REQ` and `B3-MOVEMENT-VULN-REGISTRY`  
**Purpose:** let campaign data compose bounded combat rules from the shared
Requirement/Predicate system without pack scripts or combat-specific type switches.

## Decision

Combat rules are typed consumers of `B3-REQ`, not a second condition language.
Predicates and fixed-point value terms remain pure. A separate open
`combat_operations` registry applies validated changes to a staged combat result at
named phases. Forecast and committed resolution execute the same pipeline.

```text
immutable combat snapshot
→ ordered phase
→ shared predicate/value-term evaluation
→ registered bounded operation
→ next immutable phase snapshot
→ one engine-owned combat commit
```

This preserves the existing author-extensibility rule: data may compose registered
primitives, but cannot introduce executable expressions or scripts.

## Dependencies and ownership

- `B3-REQ` owns boolean trees, comparisons, fixed-point arithmetic, complexity
  budgets, subject binding, validation, and deterministic evaluation.
- `B3-MOVEMENT-VULN-REGISTRY` owns vulnerability/effectiveness group ids and the
  migration from legacy `effective_*` tags.
- The combat pipeline owns phase snapshots, legal operation targets, application
  ordering, preview parity, and the final commit.
- Skills/items/conditions may contribute rules, but do not mutate intermediate
  combat state directly.

Implementation begins after the shared predicate evaluator exists. The operation
registry may be scaffolded alongside it, but must not duplicate its AST or math
evaluator.

## Typed combat context

Add read-only bindings usable by the shared evaluator:

- `actor` and `target`;
- `actor_weapon` and `target_weapon`;
- `event`, including attack kind, damage class, range, critical state, and source;
- the immutable value snapshot for the current combat phase.

Each phase declares which subjects and value terms are readable. Validation rejects
forward reads, such as reading final damage during the hit phase.

Initial predicate adapters required by the FEd20 fixture are:

- `target_has_trait(trait_id)`;
- `target_has_vulnerability(group_id)`;
- `target_equipped_weapon_has_family(family_id)`; and
- `target_has_effect(effect_id)`.

These adapters register with `B3-REQ`; they are not hardcoded branches inside the
combat resolver.

## Phase model

Seed a developer phase registry with stable ids:

1. `base_weapon_might`;
2. `triangle_might_modifier`;
3. `effectiveness_filter`;
4. `effective_weapon_might_multiplier`;
5. `attack_and_defence`;
6. `critical_multiplier`; and
7. `post_damage`.

Every rule declares a phase, explicit priority, stable rule id, predicate tree, and
registered operation. Rules in one phase read the same immutable input snapshot.
Collect applicable operations first, sort by priority then rule id, validate their
combination, apply them, and publish the next phase snapshot. JSON order is never
semantic.

Phase definitions also declare legal operation targets and collision policy.
Incompatible exclusive operations reject content rather than silently selecting one.

## Combat operation registry

Initial bounded primitives:

- `add(target, fixed_point_value)`;
- `multiply(target, fixed_point_value)`;
- `set_if_unset(target, value)` for explicitly approved defaulting seams;
- `suppress_effectiveness_group(group_id)`; and
- `suppress_rule(rule_id)` for narrow, validated counters when group suppression is
  insufficient.

Operation parameters may be literals or shared fixed-point value-term trees. Each
operation definition declares allowed phases, targets, parameter schema, combination
behavior, preview text, and deterministic application semantics. Unknown operations,
targets, parameters, or phase/operation combinations reject the pack.

Do not add a generic `set arbitrary path`, callback, expression string, or pack-code
operation.

## FEd20 acceptance fixture

Use the internal FEd20 pack only as a private validation fixture. Its rule must be
expressible as:

```text
effective_weapon_might =
  (weapon_might + triangle_might_modifier) × 3

damage =
  attack_stat + effective_weapon_might + attack_bonuses
  - defence_stat - defence_bonuses

critical_damage = damage × 3
```

Required fixture cases:

- bow or wind magic versus the `flying` vulnerability group;
- armourslayer, horseslayer, and dragon-effective weapons through registered groups;
- Swordslayer through `target_equipped_weapon_has_family(sword)`;
- Delphi Shield suppressing only `flying` effectiveness while retaining movement,
  UI identity, and unrelated vulnerabilities;
- triangle modification occurring before effectiveness multiplication; and
- critical multiplication remaining a later, separate phase.

Do not copy FE-derived fixture content into a public build or public source tree. The
public test suite should use generic synthetic ids and values that exercise the same
contracts; private integration verification may point at the internal pack.

## Implementation slices

### Slice 1 — contracts and registries

- Extend `B3-REQ` with the combat context adapter and allowed-term validation.
- Register phase and operation definitions through the existing registry manifest.
- Add structural validation, complexity budgets, and useful author errors.

### Slice 2 — staged resolver

- Refactor `CombatResolver` calculations into immutable phase snapshots.
- Route both forecast and execution through one evaluator.
- Preserve current public game behavior with developer preset rules before adding new
  author data.

### Slice 3 — effectiveness migration

- Complete `effective_against`/vulnerability-group migration from the movement and
  vulnerability plan.
- Replace the closed `_is_effective()` tag switch with predicate-driven rules.
- Move the default multiplier and ordering into the developer combat preset.

### Slice 4 — equipment predicates and suppression

- Add equipped-weapon-family context reads.
- Add group-specific suppression with provenance so UI can explain why a bonus was
  suppressed.
- Validate multi-group and multi-source interactions.

### Slice 5 — migration, documentation, and private fixture

- Convert existing game content to the developer preset.
- Update GDD combat/authoring sections and roadmap status in the same behavior commit.
- Add the required automated documentation/schema guard with the ratified rule.
- Verify the private FEd20 fixture without admitting it to public exports.

## Validation and definition of done

- Pure predicate/value evaluation cannot mutate units, weapons, RNG, or staged output.
- Fixed-point math is used end to end; no implicit binary-float policy is introduced.
- Unknown ids and illegal phase reads fail at load with the rule id and JSON path.
- Same-phase output is independent of document order.
- Preview and execution produce identical hit, damage, effectiveness, suppression, and
  critical results from the same snapshot.
- Existing effectiveness, Giantkiller, Nullify/Dragonskin, triangle, counterattack,
  and attack-preview tests remain green under migrated developer presets.
- Synthetic tests cover custom predicates and operation composition without editing
  `CombatResolver`.
- Save/rewind state does not persist derived phase snapshots; deterministic replay
  recomputes them from saved combat inputs and registered profile ids.
- The public export guard confirms no internal FEd20 material enters a public build.

## Explicit non-goals

- arbitrary pack scripts or expression strings;
- using predicates as mutation operations;
- allowing authored phase order to replace the engine-owned phase registry;
- solving unrelated skill, condition, or support systems in this slice; and
- activating the FEd20 pack before all of its independent schema and provenance gates
  pass.
