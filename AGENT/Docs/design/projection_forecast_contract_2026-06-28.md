---
Role: dated
Type: design
Status: Active - architecture contract
Last verified: 2026-07-13
---

# Projection / Forecast Contract

**Started:** 2026-06-28. Created from the H3 review walk in
`AGENT/Code Reviews/design_review_unimplemented_systems_2026-06-28.md`.

**Purpose.** This is the master contract for every system that needs to answer
"what would happen if this resolved?" without changing live game state. It is a
shared contract, not a new feature vocabulary.

**Managed by:** [`design_review_foundation_fix_todo_2026-06-28.md`](design_review_foundation_fix_todo_2026-06-28.md).

**Non-goal.** This does not merge combat preview, condition preview, AI
valuation, perception masking, and effect forecasts into one UI or one data
format. Each consumer may present different information. They must share the
same projection rules and context shape so previews cannot drift from
resolution.

## 1. Definition

**Projection** is a side-effect-free evaluation of a proposed action, effect,
condition tick, or state transition.

Projection is used by:
- player-facing previews and forecasts,
- AI valuation,
- requirement predicates that ask about projected outcomes,
- perception/fog filters that control what an actor can know,
- interceptor/redirect/cover dry-runs,
- validation of whether an action can be committed.

**Resolution** is the commit path that mutates state. Projection may call shared
pure calculators used by resolution, but it must not commit state itself.

## 2. Core Invariants

1. **No live mutation.** Projection never writes to `GameState`, `UnitData`,
   `map_objects_state`, event latches, objective state, RNG history, inventory,
   resources, or UI state.
2. **No committed RNG draws.** Projection may show odds, read already-latched
   chance outcomes, or use a dry-run RNG stream, but it never advances the
   committed `RngService` history.
3. **Commit path stays authoritative.** `resolve_combat()` and the eventual
   action/effect commit runner remain the only paths that change state. If
   projection and commit disagree, projection is wrong.
4. **Delegate; do not re-derive.** F5 condition projections ask F5. Combat
   projections ask combat. Effect projections ask the effect pipeline. A
   predicate does not hand-roll damage, poison, redirects, cover, or floor/kill
   rules.
5. **Same pipeline, filtered view.** Hidden information is handled by applying a
   view/knowledge filter to projection inputs or outputs, never by changing real
   resolution rules.
6. **Stable ordering.** Multi-target, AoE, multi-effect, and interceptor
   projections enumerate targets/effects in deterministic order so previews,
   AI, and tests agree.
7. **Explicit partial knowledge.** A result may be exact, hidden, approximate,
   or unknown. Do not encode unknown as `0`, `false`, or a guessed exact value.
8. **Projection explains its limits.** Output carries flags describing omitted
   information, uncertain rolls, hidden targets, blocked actions, and any
   consumer-visible warnings.

**v0.4 combat-adapter enforcement boundary.** The lightweight per-call runtime
guard snapshots only committed `RngService` history and `GameState.party_gold`,
because Attack Preview invokes projection on cursor movement. Regression coverage
separately proves byte-identical actor/target HP, active modifiers, counters, and
inventory. The no-live-mutation invariant is broader than the cheap runtime guard.

## 3. ProjectionContext

Every projection call takes a context object. Exact GDScript names are a build
detail, but the data must be present.

Required context:
- `kind`: `combat`, `effect`, `condition_tick`, `action`, `movement`,
  `objective`, or a registered sub-kind.
- `audience`: `player`, `ai`, `debug`, `validator`, or `test`.
- `actor`: acting unit id when one exists.
- `subject`: the unit/object/item being evaluated when different from actor.
- `targets`: target unit ids, object ids, tile coords, or item refs.
- `source`: weapon, item, skill, style, condition, map object, event action, or
  other registered source.
- `action_spec`: the proposed action/effect payload.
- `state_view`: live state plus any hypothetical patches already applied for
  this projection chain.
- `knowledge_policy`: what this audience is allowed to know.
- `rng_mode`: `none`, `odds_only`, `read_latched`, or `dry_run_stream`.
- `pipeline_flags`: whether to include interceptors, cover, redirects,
  perception filters, terrain entry effects, conditions, and event triggers.

Optional context:
- `forecast_fidelity`: campaign/difficulty forecast channel selection.
- `reason`: UI/debug label for why projection was requested.
- `parent_projection_id`: groups nested projections, e.g. AoE effect over many
  targets.
- `budget`: safety cap for recursive formulas or projection depth.

## 4. ProjectionResult

Every projection returns a result object. Consumers may render a subset, but the
shape should be stable.

Required result:
- `valid`: whether the action/effect can be committed.
- `failure_reason`: structured id + parameters when invalid.
- `visible_outcome`: audience-filtered outcome.
- `knowledge_flags`: exact / approximate / hidden / unknown per field.
- `state_deltas`: side-effect-free description of expected changes.
- `events`: events that would be emitted on commit, marked projected.
- `rng_summary`: odds or dry-run labels, with no committed draws.
- `warnings`: over-cap, hidden info, possible interceptor, resource shortfall,
  target may change, etc.

Debug/test-only result:
- `real_outcome`: unfiltered projected outcome, available only to debug/test or
  internal invariant checks. Player and AI display must not rely on this unless
  their `knowledge_policy` allows it.

## 5. Consumer Rules

### Combat Preview

Combat forecast calls the projection layer with `kind: combat`. It includes the
full strike sequence, early exits, counters, interceptors, redirect/cover, F5
condition effects, on-hit/on-kill effects, and source/style multi-effects when
those are part of the proposed commit.

Combat preview must not duplicate strike-loop math.

### F5 Conditions

Condition projections call F5 for `next_tick_damage`, `would_kill`,
`would_floor`, expiration, stack behavior, and source-bearing effect events.
Predicates and UI consume those F5 results; they do not inspect potency and
guess.

### AI Valuation

AI valuation uses the same projection layer as player preview, but with
`audience: ai` and the AI forecast-fidelity channel. If the campaign makes AI
knowledge different from player knowledge, the difference is expressed in
`knowledge_policy`, not in a separate AI damage formula.

### Perception / Fog

Perception filters projection inputs and visible outputs only. They never
change `resolve_combat()` or other commit semantics. A forced commit still
resolves against real state.

### Source + Style Effects

Source/style previews project every `EffectSpec` in listed order, including
per-effect gates and target filters. AoE forecasts return a grouped result with
one per-target child result.

### Interceptors, Redirect, Cover

Any interceptor family that can alter the outcome must be included in dry-run
projection by default. A consumer may omit one only with an explicit
`pipeline_flags` reason and must mark the result as incomplete.

### Requirements / Predicates

F16 predicates may ask projection questions, but only through registered
projection terms. They do not call feature-specific private math.

## 6. Relation To The Action Contract

The projection contract answers "what would happen?"

The action/effect primitive contract answers "how do we commit it?"

They must share source ids, subjects, target references, validation errors, and
result ids. Projection results should be comparable with commit results in tests,
but projection does not run commit hooks.

## 7. Test Obligations

When the projection layer is built, tests should cover:
- combat preview equals committed combat deltas for deterministic cases,
- stochastic combat preview reports odds without advancing RNG history,
- F5 poison/lethal/floor projection matches committed tick behavior,
- AI valuation and player preview use the same core projection with different
  knowledge policies,
- interceptor/redirect/cover dry-run matches committed outcome,
- AoE/multi-effect projection order is deterministic,
- hidden/unknown values are not rendered as exact zero/false values,
- projection leaves save state, event latches, resources, and RNG history
  unchanged.

## 8. Docs That Should Point Here

When these plans/registers are next edited for implementation, add a short
cross-reference back to this contract:
- F5 condition/status build notes.
- AI valuation / engagement brain.
- Perception masking and fog forecast fidelity.
- Source + Style combined preview.
- Interceptor, redirect, and cover dry-run paths.
- Requirement predicate projection terms.
- AttackPreview / effect-forecast UI work.
- Any future action preview, shop preview, arena preview, or scripted-action
  dry-run.

## 9. Build Timing

Create the projection service before implementing a second independent forecast
path. The first feature that needs complex forecast behavior may build the
initial slice, but the slice must use this context/result contract so later
consumers attach without replacing it.
