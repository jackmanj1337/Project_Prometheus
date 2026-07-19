---
Type: plan
Status: Planned - owner decision walkthrough
Last verified: 2026-07-19
---

# Waiting-Work Open Decisions Walkthrough Handoff - 2026-07-19

## Purpose

Use the next session to settle every owner decision that blocks useful work while
the v0.5.2 Windows report is outstanding. Do not begin player-visible AI adoption
until this walkthrough is recorded. Returned v0.5.2 evidence preempts the waiting
stream at the next green commit.

The decision audit found one genuinely open set: tactical adoption of
`B5-AI-MIN-SCORER`. `B3-CAMPAIGN-RULES`, `B3-PHB`, and bounded save/package/
ledger hardening already have sufficient owner direction and do not need another
gameplay-design walkthrough.

Track ownership and delivery status remain in the
[`Project Control Plane`](project_control_plane_2026-06-29.md); this handoff only
organizes the next owner conversation and does not create a new track.

## Start-of-session checks

1. Check `AGENT/Incoming/v0.5.2/` before discussion. If the report has arrived,
   triage it first.
2. Work from a new `agent/**` task branch based on `agent/integration`; do not add
   feature work to the tagged v0.5.2 release branch.
3. Reconcile the tracker before answering: the scorer decision document says
   `WeaponAttackScorer` already has compatibility and opt-in tactical primitives,
   while the control-plane row still says Planned. Confirm the code and update
   stale status text only when evidence supports it.
4. Read the sources listed under References. Record answers in this document and
   then promote them to the owning GDD/decision record in the same docs change.

## Decisions to settle

### AI-1 - First adoption scope

Choose the first player-visible tactical preset boundary:

- **A — target only (recommended):** score already-legal targets after the
  existing movement and weapon choices.
- B — tile plus target.
- C — tile plus target plus weapon.

Recommendation: **A**. It is the smallest deterministic surface and does not
front-run hypothetical equipment or joint movement forecasting.

Owner answer: ____________________

### AI-2 - Profiles and rollout

Choose whether to add a new opt-in tactical profile or change an existing shipped
profile.

Recommendation: add one explicitly named, versioned tactical profile. Keep
`basic`, `passive`, `healer`, `hunter`, and `shipped_compatibility` unchanged until
golden map traces and live play approve adoption.

Also decide:

- May aggressive units accept lethal trades? ____________________
- May bosses spend rare/signature weapons more freely? ____________________
- May passive/guard units leave position to secure a kill? ____________________

Owner answer: ____________________

### AI-3 - Expected damage and kill priority

Choose the first formula:

- **A — hit-adjusted expected damage plus guaranteed-kill priority (recommended).**
- B — include expected critical bonus immediately.
- C — exact bounded kill probability across the full exchange immediately.

Recommendation: **A**, with exact kill probability deferred until the ordered
exchange forecast exists. Omit probabilistic proc skills from the first adoption.

Decide whether a guaranteed kill categorically outranks a probable kill: ______

Owner answer: ____________________

### AI-4 - Survival and sacrifice

Choose lethal-counter handling:

- A — hard reject any lethal risk.
- **B — dominant but non-absolute penalty (recommended).**
- C — wholly profile-weighted with no common floor.

Recommendation: **B**, with a profile multiplier later. First adoption considers
the selected defender's counter only; multi-enemy exposure remains a later
tile-scoring concern.

Decide whether an ordinary unit may trade for a healer, boss, or objective unit:
____________________

Owner answer: ____________________

### AI-5 - Ordered forecast ownership

Choose whether the scorer reconstructs combat order or consumes a shared ordered
dry-run exchange.

Recommendation: `CombatResolver.preview_combat()` (or its shared projection seam)
owns one side-effect-free ordered exchange covering first-strike effects,
follow-ups, multi-strikes, weapon breakage, and death stopping later strikes. The
scorer must not duplicate combat sequencing.

Owner answer: ____________________

### AI-6 - Weapon conservation

Choose the value source:

- A — fixed engine weights by rank.
- **B — authored base value with a profile multiplier (recommended).**
- C — replacement-cost/remaining-use formula only.

Recommendation: **B**, never display-name inference. Because first adoption is
target-only, implement this contract only when weapon selection enters scope.

Decide:

- May a final use be spent for a guaranteed kill? ____________________
- Do enemy inventories persist between maps? ____________________
- Are droppable/player-reward weapons conserved differently? ____________________

Owner answer: ____________________

### AI-7 - Target and objective value ownership

Choose authored, inferred, or mixed target value.

Recommendation: mixed—authored role/objective tags override deterministic inferred
defaults. Objective criticality belongs to the objective system; scorer terms read
that context instead of hardcoding objective types.

Decide the owning layer for weights: faction/profile is recommended, with optional
map/campaign data selecting a versioned preset.

Owner answer: ____________________

### AI-8 - Deterministic tie-breaking

Approve or replace this recommended chain:

1. Higher bounded tactical score.
2. Higher guaranteed-kill/kill result.
3. Lower movement/path cost when movement enters scope.
4. Stable target `unit_id`.
5. Destination coordinates in row-major order.
6. Inventory slot, then stable weapon id when weapon choice enters scope.

Recommendation: tactical presets use the stable chain across save/load within a
supported protocol/version. Compatibility mode alone preserves caller order.

Owner answer: ____________________

### AI-9 - Performance budget

Set measurable limits before tile/weapon/threat expansion:

- Maximum candidates per acting unit: ____________________
- Maximum forecasts per acting unit: ____________________
- Target AI phase time on the benchmark map/hardware: ____________________
- Allow deterministic cache by snapshot and candidate tuple? Yes / No
- Allow work across frames if decision order is unchanged? Yes / No

Recommendation: target-only adoption first, add candidate-count telemetry and a
benchmark fixture, then choose numeric budgets from measurements instead of guesses.

Owner answer: ____________________

### AI-10 - Compatibility, save migration, and explanation

Recommendation:

- Keep `shipped_compatibility` immutable.
- Give every tactical weight set a versioned preset id.
- Select the preset through an AI profile; campaign/map data may select profiles.
- Old saves remain on compatibility behavior unless they already identify a
  tactical profile; no silent migration.
- Serialize an id only if the selected profile is not already durably reconstructible
  from campaign/map/package identity. Do not add redundant save state.
- Provide optional structured score-component diagnostics for tests/designers, with
  no per-candidate release-log spam.
- Acceptance requires purity/determinism tests, compatibility parity, approved golden
  action traces, and later live play—not merely absence of crashes.

Owner answer: ____________________

### AI-11 - Explicit deferrals

Confirm these remain outside the first adoption:

- general status and skill utility;
- alternate weapon selection and durability valuation;
- joint destination/terrain/exposure scoring;
- retreat analysis, formations, and coordinated multi-unit search;
- hidden-information/perception modeling;
- learned evaluation or sampled RNG outcomes;
- scored staves, AoE, gambits, capture, refresh, and other Slice 3B actions.

Recommendation: confirm all deferrals. Add each later family through registered
terms and explicit fixtures rather than expanding the first slice implicitly.

Owner answer: ____________________

## Tracks already decision-ready

### `B3-CAMPAIGN-RULES`

No new owner choice is required for the foundation slice. Implement author-defined
profiles and `locked|start|mid_run` tunables, preserve shipped defaults and existing
mandates, and leave difficulty/death-mode content to Band 4. Before coding, refresh
the older plan against the now-implemented F1/save and campaign-rule authority seams.

### `B3-PHB`

`PHB-1..7` are resolved: flat opt-in node panels, node-scoped availability, battle
nodes first with pure hubs supported by schema, free navigation with one Begin
Battle/advance commit, cosmetic theme/location, and immediate party-state
transactions. Framework plus an inert fixture needs no additional owner decision.

### Headless hardening

Malformed/legacy save and package fixtures, write-failure injection, ledger/suspend
determinism comparisons, serializer ownership audits, and UI harness measurement
need no gameplay decisions. Do not visually tune the v0.5.2 surfaces while its
screenshots are outstanding.

## Session exit

1. Copy selected answers into the decision record table in
   `weapon_attack_scorer_preimplementation_decisions_2026-07-16.md`.
2. Update `GDD_08`, the control-plane row, and any save-contract documentation only
   for decisions actually ratified.
3. Run `python3 AGENT/Docs/gen_docs_index.py` and documentation checks.
4. If all blocking answers are settled, write the bounded Slice 3A requirement/
   evidence matrix before production code. Otherwise choose `B3-CAMPAIGN-RULES`,
   `B3-PHB`, or headless hardening while waiting.

## References

- [`weapon_attack_scorer_preimplementation_decisions_2026-07-16.md`](weapon_attack_scorer_preimplementation_decisions_2026-07-16.md)
- [`b5_ai_min_scorer_slice3a_handoff_2026-07-16.md`](b5_ai_min_scorer_slice3a_handoff_2026-07-16.md)
- [`playtest_waiting_work_queue_handoff_2026-07-16.md`](playtest_waiting_work_queue_handoff_2026-07-16.md)
- [`band3_core_authoring_foundations_implementation_plan_2026-06-30.md`](band3_core_authoring_foundations_implementation_plan_2026-06-30.md)
- [`prep_hub_open_questions_2026-06-23.md`](../registers/prep_hub_open_questions_2026-06-23.md)
- [`difficulty_death_mode_open_questions_2026-06-27.md`](../registers/difficulty_death_mode_open_questions_2026-06-27.md)
