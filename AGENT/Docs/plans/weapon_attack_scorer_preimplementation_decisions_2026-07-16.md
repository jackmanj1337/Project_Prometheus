# Weapon-Attack Scorer — Pre-implementation Decisions

**Status:** Planning input — proposed factors and unresolved choices; not a gameplay contract
**Date:** 2026-07-16
**Owner:** GDD_08 §Weapon-Attack Scoring Track

## Purpose and existing baseline

This document collects the factors the tactical AI scorer could evaluate and the
decisions that should be settled before a shipped AI profile adopts them. It does not
authorize implementation or change the roadmap status.

`WeaponAttackScorer` currently has two presets:

- `shipped_compatibility` is the live default. It considers Manhattan distance only
  and preserves candidate order for equal-distance ties. It does not request a combat
  forecast, so shipped AI decisions remain unchanged.
- `tactical_forecast` is an opt-in primitive. It considers forecast total damage,
  target HP, a guaranteed-kill bonus, counterattack availability and total counter-
  damage, plus a small distance penalty. Its integer result is clamped to
  `[-1,000,000, 1,000,000]`. No shipped profile selects it.

GridManager filters legal/hostile targets before scoring. Movement-tile selection,
weapon selection, action selection, and multi-unit planning remain outside the scorer.

## Rating scale

- **Difficulty:** Low, Medium, High, or Very high. This includes forecast-model work,
  integration, deterministic tests, tuning, and likely performance cost.
- **Impact:** Low, Medium, High, Very high, or Critical correctness. This estimates
  how visibly the factor improves tactical decisions once tuned.

## Candidate-factor assessment

| Factor currently ignored | Difficulty | Impact | Main dependency or concern |
| --- | --- | --- | --- |
| Hit probability | Low | Very high | Convert raw damage to expected damage without using RNG. |
| Crit probability | Low–Medium | Medium | Expected crit damage and kill probability need a defined formula. |
| Attacker current/max HP | Low | High | Required to compare counter-damage with survivability. |
| Lethal-counter risk | Low–Medium | Very high | Must account for hit chance, strike order, and multiple strikes. |
| Strike order, including Vantage | Medium | High | Later strikes must not count after either unit would already be dead. |
| Weapon durability and mid-combat breakage | Medium | High | Forecast must stop strikes that cannot occur after breakage. |
| Weapon value or rarity | Low–Medium | Medium | Requires campaign-defined conservation values, not hard-coded names. |
| Limited/last weapon uses | Medium | Medium–High | Consuming the final use can remove future attack options. |
| Terrain DEF and avoid | Medium | High | Primarily useful when destination and attack are scored jointly. |
| Terrain healing | Medium | Medium | Requires post-action/end-turn timing and profile-specific patience. |
| Movement cost | Low | Medium | Existing path cost can be reused as a tie-break or opportunity cost. |
| Post-attack enemy threat ranges | High | Very high | Requires evaluating attacks from multiple enemies against each destination. |
| Target strength | Medium | Medium–High | Needs a stable unit-value model that avoids double-counting forecast danger. |
| Target role (healer, damage dealer, boss, etc.) | Medium | Medium–High | Roles need authored tags or a deterministic inference rule. |
| Target level/EXP value | Low–Medium | Medium | Risks making AI behavior serve progression rather than its faction's goal. |
| Target objective importance | High | Very high | Requires objective-specific context from TurnManager/objective data. |
| Pair Up, Dual Strike, and Dual Guard | High | Medium–High | Forecast must model support participation and altered survival odds. |
| Probabilistic skills | High | High | Use expected value; chained procs and conditional probabilities are complex. |
| Stateful skills | High | High | Dry-run forecasts must model counters/charges without mutating live state. |
| Status effects | Medium–High | High | Damage, control, debuffs, duration, and immunity need comparable utility values. |
| Usable items | High | Medium–High | Expands scope from attack scoring into action selection and conservation. |
| Friendly-fire/alliance logic | Low | Critical correctness | Keep as a legality gate before scoring; avoid duplicating policy in weights. |
| Alternate weapon selection | High | Very high | Multiplies candidates and needs safe hypothetical-equipment forecasts. |
| Movement destination selection | High | Very high | Jointly score `(tile, target, weapon)` to make terrain/exposure meaningful. |
| Long-term positioning | Very high | High | Requires future-turn estimates rather than one-exchange evaluation. |
| Retreat routes/trap avoidance | High | Medium–High | Measure future safe reachable tiles and enemy zone control. |
| Formations and coordinated behavior | Very high | High | Unit decisions become order-dependent and require faction-level planning. |
| Map-objective progress | High | Very high | Changes movement and action priorities globally, not just target preference. |
| Actual hit/crit RNG outcomes | Do not add | Negative | Sampling makes choices unstable; use deterministic probabilities/expectation. |

## Decisions required before tactical adoption

### 1. Scope of the first adoption

Choose one:

- **A — Target only (recommended first slice):** score already-legal targets after
  movement. Smallest integration surface, but cannot improve destination or weapon
  choice.
- **B — Tile + target:** score every legal `(destination, target)` pair. Unlocks
  terrain and exposure decisions at a moderate candidate-count increase.
- **C — Tile + target + weapon:** evaluate every usable weapon too. Highest immediate
  quality, but forecast and performance complexity rise substantially.

Question: Is the first goal to improve visible target choice safely, or to replace the
whole move/attack selection pipeline?

### 2. Which profiles adopt tactical scoring

Options:

- Add a new profile and leave `basic`, `passive`, and `healer` unchanged.
- Opt `basic` into tactical scoring while retaining `shipped_compatibility` as a
  campaign/save-level compatibility option.
- Give each profile a weight preset: cautious, basic, aggressive, boss.

Recommended: introduce one explicitly tactical profile first. Do not silently change
`basic` until authored maps have been replayed and accepted against golden decisions.

Questions:

- Should `aggressive` ignore all self-damage, only nonlethal self-damage, or merely
  reduce its penalty?
- May bosses spend rare weapons/items more freely, or should they conserve them more?
- Should passive/guard units ever leave position to secure a kill?

### 3. Expected-value and kill model

Options for ordinary damage:

- `damage × hit_probability` (simple expected damage).
- Include expected crit bonus: `damage × hit + extra_crit_damage × crit_probability`.
- Compute an exact bounded kill probability across all forecast strikes.

Recommended progression: hit-adjusted expected damage first, then exact kill
probability once strike order is modeled. Guaranteed kills should outrank merely high
expected damage unless a profile explicitly permits gambling.

Questions:

- How much should a probable kill trail a guaranteed kill: slightly, or categorically?
- Does the AI know displayed combat probabilities exactly, or should some profiles
  behave with imperfect information?
- Are proc skills included as expected value, worst/best case, or omitted initially?

### 4. Survival and acceptable sacrifice

Define whether survival is:

- A hard gate: reject any attack with a possible/likely lethal counter.
- A dominant score penalty: sacrifice remains possible for sufficiently valuable kills.
- Profile-weighted: cautious avoids risk; aggressive accepts it.

Recommended: use a dominant but non-absolute lethal-risk penalty, then expose the
weight by profile. Hard rejection can prevent necessary objective plays.

Questions:

- Is trading an ordinary unit for a healer, boss, or objective unit acceptable?
- Should low-HP units become more cautious, more desperate, or unchanged?
- Should danger from enemies other than the selected defender count in the first slice?

### 5. Strike sequencing contract

Before lethal-risk scoring, define a deterministic forecast sequence covering:

- Vantage and other first-strike effects.
- Brave/multiple strikes and follow-ups.
- Weapon breakage between strikes.
- Death stopping all later strikes.
- Defensive/proc skills and Pair Up interventions when those systems are adopted.

Question: Should `CombatResolver.preview_combat()` expose an ordered dry-run exchange
list, or should the scorer reconstruct sequence from aggregate forecast fields?

Recommended: expose one shared ordered dry-run forecast. Reconstructing combat inside
the scorer risks drift from actual resolution.

### 6. Weapon conservation

Choose the conservation source:

- Fixed weights by rank/rarity.
- Authored `ai_value`/`conservation_weight` on weapon data.
- Replacement-cost and remaining-use formula.
- Profile/campaign rules layered over authored values.

Recommended: authored base value plus profile multiplier. Never infer importance from
display names.

Questions:

- May the AI consume a final weapon use for a guaranteed kill?
- Are enemy inventories expected to persist across maps?
- Should bosses preserve signature weapons or showcase them?
- How should infinite-use, droppable, or player-reward weapons be valued?

### 7. Terrain, exposure, and retreat

Questions:

- Score raw terrain bonuses, or their forecasted effect against likely attackers?
- Count every enemy that can threaten the destination, only the strongest, or expected
  combined damage until the unit dies?
- Does blocking a chokepoint or protecting an ally have positional value?
- How many future movement steps define a viable retreat route?
- Can the AI intentionally enter danger to advance an objective?

Recommended first model: destination terrain bonus plus maximum expected incoming
damage from one hostile. Add combined-threat and retreat analysis only after profiling.

### 8. Target and objective value

Choose whether target value is authored, inferred, or mixed:

- Authored role/objective tags are explicit and tunable.
- Inference from stats, inventory, and skills reduces authoring but can be brittle.
- Mixed model uses authored overrides with deterministic inferred defaults.

Recommended: mixed model, with objective criticality supplied by the objective system
rather than embedded in scorer constants.

Questions:

- Which roles exist, and can one unit have several roles?
- Should AI know hidden inventories, reinforcements, or objective state?
- How are protect, seize, escape, defend, and rout priorities compared?
- Who owns the weights: campaign rules, map data, faction profile, or global constants?

### 9. Status and skill utility

Questions:

- What common unit represents immediate damage, delayed damage, movement denial,
  stat debuffs, healing prevention, and action denial?
- Does utility scale by duration and remaining map time?
- How are immunity and cleansing availability included?
- Are rare high-impact procs represented by expected value or a profile-specific risk
  preference?
- How are limited-use skill counters represented in a side-effect-free forecast?

Recommended: defer general status/skill utility until core damage and survival scoring
is stable. Add each status family with explicit fixtures rather than one universal
guess at utility.

### 10. Deterministic tie-breaking

The compatibility preset intentionally preserves caller order. Tactical adoption must
choose and document a stable tie-break chain, for example:

1. Higher bounded tactical score.
2. Higher kill probability.
3. Lower movement/path cost.
4. Stable target identity.
5. Destination coordinates in a declared order.
6. Weapon inventory slot or stable weapon ID.

Questions:

- What is the stable unit identity across save/load and online snapshots?
- Should authored candidate order retain any priority?
- Must tactical decisions remain identical across engine upgrades, or only within a
  supported version/protocol?

### 11. Performance budget

Joint tile/target/weapon scoring can produce `move tiles × targets × weapons × threat
attackers` forecasts per acting unit.

Decide:

- Maximum candidate and forecast counts per unit.
- Whether forecasts can be cached by snapshot state and candidate tuple.
- Whether low-value candidates may be pruned before full forecasting.
- Target phase-time budget on the largest authored map and slowest supported hardware.
- Whether expensive planning may be spread over frames without changing decisions.

Recommended: establish a benchmark map and deterministic candidate-count telemetry
before tile/weapon/threat expansion.

### 12. Compatibility, rollout, and observability

Questions:

- Where is the preset selected: profile, map, campaign rules, save data, or global
  setting?
- Must old saves pin `shipped_compatibility`, or may a version migration opt them in?
- Do replays/snapshots serialize the preset and weight version?
- How will designers inspect why one candidate won?
- What constitutes acceptance: no crashes, smarter fixtures, or approved golden-map
  action traces?

Recommended:

- Keep `shipped_compatibility` immutable.
- Give tactical weights a versioned preset ID rather than changing a preset in place.
- Add an optional debug breakdown containing each bounded component and tie-break.
- Capture golden action traces for representative maps before enabling tactical scoring.

## Recommended implementation sequence

1. Lock the target-only scope, profile rollout, expected-damage formula, survival rule,
   tie-break chain, and compatibility/save policy.
2. Extend the shared combat forecast with ordered, side-effect-free exchanges if needed.
3. Add hit-adjusted damage, attacker survival, lethal-counter risk, and strike order.
4. Verify component bounds, repeatability, compatibility parity, and profile-specific
   golden target decisions.
5. Add weapon/durability choice only after hypothetical equipment forecasts are safe.
6. Expand to joint tile/target scoring with terrain and one-enemy exposure.
7. Integrate objective/role value through authored data and objective-system context.
8. Add statuses and probabilistic/stateful skills incrementally.
9. Consider retreat analysis and coordinated multi-unit planning only after performance
   measurements show the simpler model is insufficient.

## Minimum acceptance gates for any adopted tactical preset

- Every score component and final score has explicit bounds with extreme-value tests.
- Identical snapshot state produces identical candidate ordering and action choice.
- Preview/scoring performs no HP, durability, inventory, skill-counter, or RNG mutation.
- Compatibility preset decisions remain unchanged by exhaustive and golden-trace tests.
- Legal-target/alliance checks remain outside and precede scoring.
- Tie-break identity and ordering are stable across save/load.
- The largest benchmark map stays within the agreed candidate-count and phase-time budget.
- GDD_08, GDD_10, feature index, and tests change status together only for behavior that
  is actually adopted by a shipped profile.

## Decision record template

Before implementation, record answers in this form:

| Decision | Selected option | Rationale | Owner/source | Tests required |
| --- | --- | --- | --- | --- |
| First adoption scope | TBD | — | GDD_08 | Candidate enumeration |
| Profiles adopting it | TBD | — | UnitData/profile contract | Profile behavior |
| Expected damage/kill formula | TBD | — | GDD_02 combat math | Formula fixtures |
| Survival/sacrifice rule | TBD | — | GDD_08 | Lethal-counter fixtures |
| Tie-break chain | TBD | — | Determinism contract | Permutation/save-load |
| Weapon conservation policy | TBD | — | GDD_04/CampaignRules | Durability/value |
| Objective/role ownership | TBD | — | M16/GDD_08 | Objective scenarios |
| Performance budget | TBD | — | Performance constraints | Benchmark map |
| Compatibility/save migration | TBD | — | GDD_01 snapshot contract | Old-save/replay parity |
| Debug explanation surface | TBD | — | GDD_07/debug tooling | Breakdown integrity |

