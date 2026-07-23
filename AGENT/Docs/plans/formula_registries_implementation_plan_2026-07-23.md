---
Type: implementation plan
Status: Planned — approved contract; implementation not started
Last verified: 2026-07-23
Decision source: campaign_data_ownership_research_findings_2026-07-23.md
Tracker: IMPL-FORMULA-REGISTRY-V1, IMPL-FORMULA-REGISTRY-EXTENSIONS
---

# Separate Formula Registries — Implementation Plan

## Outcome

Pack data selects bounded, reviewed engine formulas through separate family
registries. Unknown ids or invalid parameters reject a pack before activation.
There is no universal expression VM, arbitrary loop, pack script, filesystem access,
runtime-object lookup, or data-authored mutation authority.

## Current-state inventory

- `CombatResolver.DEFAULT_HIT_FORMULA`, `hit_rn_count`, `did_hit`,
  `_current_hit_formula`, `_hit_two_roll`, `_hit_single_roll`; unknown live ids
  currently fall back and must not be accepted from packs.
- `CombatResolver.compute_damage`, `compute_hit_pct`, `calculate_exp`, triangle,
  effectiveness, follow-up and crit calculations are hardcoded candidates.
- `WeaponData.range_min_formula`, `range_max_formula`, `_eval_formula`,
  `_stat_value` implement integer or `STAT/divisor` grammar with a closed stat
  switch; `StatRegistry` is the replacement vocabulary seam.
- `CostSpec.fixed`, `formula_term`, `scope`, `subject_binding`; formula terms are
  reserved/rejected. `ResourceLedger.quote`, `commit`, `refund`, `_resolve_wallet`
  owns mutation.
- `Unit._GROWTH_STATS`/level-up methods and `CampaignRules.leveling_method` own
  growth selection; `AIProfileRegistry` and EnemyAI scoring selectors own AI.
- `RegistryCatalog`, objective/item/action/occupancy registries already demonstrate
  data entries selecting engine-side validation/preview/commit handlers.

## Family contracts

All definitions use `{id, schema_version, parameters}`; the engine registry owns an
immutable handler descriptor: allowed parameter schema, input schema, output bounds,
determinism contract, preview function, and (only where permitted) commit function.

| Family | Allowed inputs/output | Determinism and failure | v1 |
|---|---|---|---|
| Hit roll | displayed hit + declared RNG event; boolean | Fixed RN count/order per id; bounds 0..100; preview reports probability without draws; error aborts action. | Required: register `two_roll`, `single_roll`. |
| Range | registered stat snapshot + bounded integer parameters; min/max integer | Zero RNG/mutation; clamp declared by handler; invalid divisor/stat rejects pack. | Required: literal and stat-divisor replace string parser. |
| Cost | transaction values + immutable context bindings; signed bounded deltas | Zero RNG; quote pure; only ledger commit mutates; overflow/unknown binding fails. | Required: fixed plus the first safe `formula_term`. |
| Requirement/predicate | immutable subject/context facts; boolean + reason | Zero RNG/mutation; bounded composition depth; unknown fact/operator fails. | Required for migrated objective/item/action references. |
| Damage | combat snapshot; bounded integer | Zero RNG/mutation; preview/runtime same handler. | Later; registered shipped default before alternatives. |
| Growth | immutable unit/class/rule snapshot + declared RNG event; stat deltas | Fixed stat and draw order; bounded deltas; preview exposes distribution only. | Later unless base-pack extraction needs an alternate. |
| AI scoring | immutable projected candidate; bounded score/breakdown | Zero RNG/mutation; stable tie order; no world traversal outside supplied snapshot. | Later; preserve `AIProfileRegistry`. |

Each evaluator receives a purpose-built value dictionary, never a Node, Callable,
path, singleton, or unrestricted Variant graph. Numeric operations check type,
overflow, division by zero, NaN/Inf and family bounds. Registry ids and parameters
are validated while building the candidate catalogue.

## Incremental slices and dependencies

1. **`IMPL-FORMULA-REGISTRY-V1`** depends on zero-content inactive-session
   foundation. Add common descriptor/error/result conventions but separate registry
   instances. Register current hit defaults without behavior change; make pack
   validation reject unknown ids. Replace range strings with adapted registered
   definitions while reading old strings only at the compatibility/import boundary.
   Promote fixed cost and a bounded arithmetic term; route requirement primitive
   selection through the same activation validation. Exit: a base-pack candidate
   validates hit/range/cost/requirements and preview/runtime parity fixtures pass.
2. **Adoption inside base-pack extraction.** Pack documents select registered ids;
   runtime defaults remain equivalent. Remove compatibility selectors only after all
   baked data has migrated.
3. **`IMPL-FORMULA-REGISTRY-EXTENSIONS`** depends on base-pack extraction and is
   independently scheduled: register damage, growth and AI scoring defaults, then
   allow alternatives one family at a time. It does not block zero-content v1.

## Test and failure matrix

- Golden deterministic hit vectors assert RN count/order and unchanged outcomes.
- Range literal/stat-divisor fixtures cover unknown stat, zero divisor and bounds.
- Cost quote/commit/refund proves preview purity and single mutation authority.
- Unknown family/id, extra/missing/wrong-type parameters, deep predicates, overflow,
  filesystem-looking strings and runtime objects fail activation with document path.
- Save/load retains selected durable ids and resolved parameters; pack update cannot
  change an active run without the persistence plan's compatibility/migration path.
- Windows validation only checks author/player diagnostics and displayed preview
  parity; no visual redesign is required.

## Documentation, enforcement, exclusions

Product work targets `agent/integration`. Update GDD 02/03/04/05/06 and GDD 10 /
Feature Index with each adopted family. Add a `check_docs.py` rule when formula-family
vocabulary becomes mechanical: each declared family must name its determinism,
preview, parameter and failure contracts. Supersede the ad-hoc range grammar and
unknown-hit fallback as authoring contracts, while preserving their import behavior.
Do not implement scripting, a universal AST/VM, arbitrary formulas, dynamic access,
new balance algorithms, or AI-search expansion.
