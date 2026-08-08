# Weapon-Attack Scorer — Pre-implementation Decisions

**Status:** Owner decisions ratified 2026-07-19; implementation not yet authorized
**Date:** 2026-07-16 (decisions recorded 2026-07-19)
**Owner:** GDD_08 §Weapon-Attack Scoring Track

> Owner answers for every open decision were settled in the 2026-07-19 walkthrough
> and are recorded in [Decision record — ratified 2026-07-19](#decision-record--ratified-2026-07-19).
> The factor assessment and per-decision discussion below are retained as the
> record of what was considered; where a section's recommendation conflicts with a
> ratified answer, the ratified answer governs.

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

Superseded 2026-07-19. The original sequence assumed a target-only first adoption;
the ratified scope is joint `(tile, target, source)` with exact kill probability, so
the work no longer fits one bounded slice. Sequence it as three slices instead — each
is a prerequisite of the next regardless, so this adds no total work and yields three
verifiable checkpoints rather than one long uninterruptible build.

**Slice A — ordered exchange projection (no AI changes).**

1. Add `CombatResolver.project_exchange()` beside `preview_combat()`, reusing
   `_build_combat_context` / `_collect_combat_modifiers` / snapshot-restore.
2. Model first-strike effects, follow-ups, multi-strikes, weapon breakage, and death
   stopping later strikes. `preview_combat()` is left untouched (see AI-5).
3. Symmetric style slots on both combatants, defender's pinned null (see STY-8 note).
4. Proc handling is a parameter, defaulting to exclude (see AI-11 note).
5. Deterministic cache keyed `(attacker, defender, source, attacker_terrain_bucket)` —
   deliberately excluding the tile (see AI-9).

**Slice B — weight registry and target scoring.**

6. Authored weight registry plus named versioned presets; `shipped_compatibility`
   stays immutable and remains the live default.
7. Unit value applied symmetrically (target gain and actor loss on one scale), with
   inferred defaults reading objective criticality via a new registry handler.
8. Target-only scoring on top of Slice A, behind the new opt-in profile.
9. Verify bounds, determinism, compatibility parity, and golden traces per shipped
   preset before proceeding.

**Slice C — joint search.**

10. Candidate generation over `(tile, target, source)`, with a reserved always-null
    style field.
11. Threat/exposure scoring, so tile choice carries real signal.
12. Weapon conservation over `[STY-5]` cost sets.
13. Candidate-count and phase-time telemetry plus a benchmark fixture map; set the
    numeric budgets from those measurements (see AI-9c).

Deferred beyond these slices: statuses and skill utility, retreat analysis,
formations and coordinated multi-unit planning, hidden-information modeling, learned
evaluation, and scored staves/AoE/gambits/capture.

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

## Decision record — ratified 2026-07-19

Settled in the owner walkthrough driven by
`waiting_work_open_decisions_walkthrough_handoff_2026-07-19.md`. Decision ids `AI-n`
are that handoff's numbering; the numbered sections above use their own numbering.

| Decision | Selected option | Rationale | Owner/source | Tests required |
| --- | --- | --- | --- | --- |
| First adoption scope (AI-1) | Joint `(tile, target, source)` | Build the joint search once rather than growing it in three passes | GDD_08 | Candidate enumeration |
| Profiles adopting it (AI-2) | One new versioned tactical profile; five shipped profiles unchanged | Nothing regresses without an author opting in | UnitData/profile contract | Profile behavior |
| Expected damage/kill formula (AI-3) | Exact bounded kill probability across the ordered exchange | Most accurate; makes Slice A a hard prerequisite | GDD_02 combat math | Formula fixtures |
| Kill priority (AI-3a) | Authored weight, high by default — not structural | Keeps the no-structural-rules architecture; presets may gamble | GDD_08 | Per-preset weight fixtures |
| Survival/sacrifice rule (AI-4) | Wholly preset-weighted; no common floor | A preset must be able to express a unit that accepts lethal trades | GDD_08 | Lethal-counter fixtures, per preset |
| Sacrifice for high-value targets (AI-4a) | Emergent from unit value; no special rule | One mechanism instead of a tagged exception | GDD_08 | Trade scenarios |
| Strike sequencing contract (AI-5) | New `project_exchange()` sibling; `preview_combat()` untouched | Purely additive, so shipped UI cannot regress mid-playtest | CombatResolver | Ordered-exchange fixtures |
| Weapon conservation (AI-6) | Authored base value × preset multiplier, over `[STY-5]` cost sets | Never display-name inference; boss behavior is multiplier ≈ 0 | GDD_04/CampaignRules | Durability/value, cost-set fixtures |
| Final weapon use (AI-6a) | Emergent from the weights | Consistent with AI-4a | GDD_04 | Last-use scenarios |
| Droppable weapons (AI-6b) | Per-preset/per-enemy knob; default treats droppables normally | Author opts in per encounter; default keeps enemies fighting at strength | GDD_04 | Droppable conservation |
| Unit/objective value (AI-7) | Mixed: authored tags override inferred defaults; inferred defaults read win/loss conditions | Objective criticality is automatic, not an authoring chore | M16/GDD_08 | Objective scenarios |
| Weight ownership (AI-7a) | Faction/profile, with optional map and per-placement override | Reuses the existing placement-override pattern | GDD_08 | Precedence fixtures |
| Tie-break chain (AI-8) | Approved minus "higher kill result"; reserved style slot appended | Kill value already sits in the score per AI-3a; a structural step would contradict it | Determinism contract | Permutation/save-load |
| Performance budget (AI-9) | Cache required (tile-excluded key); resumable search shape run synchronously; numbers set from measurement | Guessing budgets before joint-search counts are known is meaningless | Performance constraints | Benchmark map, telemetry |
| Compatibility/save migration (AI-10) | Confirmed, with loose weight overrides permitted in save data | Pre-v1: no migration burden; missing/unknown data fails fast and loud | GDD_01 snapshot contract | Old-save/replay parity, unknown-key rejection |
| Debug explanation surface (AI-10) | Structured opt-in score-component diagnostics; no per-candidate release logging | Joint search with exact kill probability is undebuggable without it | GDD_07/debug tooling | Breakdown integrity |
| Deferral list (AI-11) | Threat/exposure scoring pulled INTO scope; all other deferrals confirmed | Without exposure, tile choice has no signal beyond path cost | GDD_08 | Exposure fixtures |

### Cross-cutting decisions

- **Weights-and-presets architecture.** Every scoring term is an authored weight;
  presets are named recommended weight vectors. No floors, no lexicographic rules, no
  hardcoded exceptions. Consequence: golden action traces **per shipped preset** are
  the only safety net against a suicidal weight vector, so they are an acceptance
  gate, not a nicety. An unshipped preset a designer authors is unverified until
  traced.
- **Style axis reserved, not implemented.** Candidates carry a `style` field pinned to
  null until Band 5 ships styles. Adding them later is a candidate-generator change
  rather than a signature change that invalidates every trace fixture.
- **`[STY-8]` unchanged.** Counters continue to carry no style. `project_exchange()`
  must nevertheless be internally symmetric, with the defender's style slot pinned
  null and a comment explaining why, so counter styles retrofit cheaply if wanted.
  The non-lethal-counter case is separable — a damage clamp, not a style — and needs
  no decision now.
- **Proc skills excluded, but parameterised.** `SkillHandler.apply_trigger()` skips
  any skill with an `activation_chance_stat` when `preview = true`, so the scorer is
  blind to procs and reasons from exactly what the player's forecast shows. Proc
  handling must be a **parameter** on `project_exchange()` (`exclude` default vs
  `expected_value`), never the hardcoded preview flag, so a future higher-difficulty
  AI is a new argument rather than a refactor of the forecast path.
- **Pre-v1 data policy.** Missing or unknown AI weight data fails quickly and loudly.
  This deliberately departs from the `ai_profile` precedent at `GameState.gd`, which
  defaults to `"basic"` on load; comment the difference at the read site so it is not
  "fixed" later.

### Code findings that resolved or reshaped decisions

- **`WeaponAttackScorer` is not on any shipping branch.** It exists only on
  `agent/codex/2026-07-16/recover-stale-main-ai-scorer`, whose merge-base with `main`
  is `26c6a16` (2026-06-14). The control-plane "Planned" row is correct for every
  branch anyone builds from. Recovering that branch is a rebase, and matters less
  under the ratified scope since it only implements `choose_target`.
- **`preview_combat()` returns a flat aggregate, not an ordered sequence.** It cannot
  express death stopping later strikes, so it is insufficient for AI-3 and is not the
  seam the scorer consumes. Its internals are already side-effect-free and correct to
  reuse.
- **Enemy inventories do not persist between maps.** `GameMap._spawn_enemy_units()`
  builds every hostile fresh from `enemy_placements`, and
  `_resolve_placement_unit_data()` calls `.duplicate(true)` on both branches. Weapon
  conservation therefore has within-map meaning only.
- **`ObjectiveCondition` exposes `unit_ids` directly**, and
  `ObjectiveConditionRegistry` is a true open registry. Objective criticality is a
  field read behind a new registry handler kind, not an inverse problem over
  predicates — and the scorer must never `match` on condition type.
- **The unit serializer is an explicit allowlist.** `GameState.gd` writes
  `ai_profile` at one site and reads it at another. Any new per-unit AI state is
  silently dropped across suspend/resume unless added at both.

