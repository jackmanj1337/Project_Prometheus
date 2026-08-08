---
Type: design
Status: Proposed — CAU owner walk not yet started
Last verified: 2026-08-08
Tracker: DISCUSS-COMBAT-ACTIONS-UX-2026-07-24
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Combat Actions UX — Research and Interaction Contract

Governance: [Project Control Plane](../plans/project_control_plane_2026-06-29.md).

This packet specializes the resolved shared feedback vocabulary in
[`combat_feedback_vocabulary_research_2026-08-07.md`](combat_feedback_vocabulary_research_2026-08-07.md)
for combat arts, gambits, displacement, refresh, secondary movement, rescue carry/drop,
and utility staves. Mechanical decisions in `STY`, `DSP`, `BAT`, `AGT`, and `SMV` are inputs;
this packet does not reopen them.

## Finding

The named actions differ mechanically but share one player-facing transaction:

1. choose an action and source;
2. see valid targets and an honest preview;
3. choose any required destination or affected area;
4. confirm once;
5. resolve atomically and emit the same ordered feedback stream as ordinary combat.

The UI should therefore consume one open `ActionPreview`/`ActionExecution` contract rather than
one menu scene per action kind. Adding a campaign-authored action must add data and registered
preview/resolution handlers, not another closed `match` in `ActionMenu`.

## Action-family audit

| Family | Selection shape | Preview owed before confirmation | CFB specialization |
|---|---|---|---|
| Combat art / weapon art | source, target | cost, durability/charge, hit/damage deltas, retaliation and movement consequences | Uses `[CFB-9]` strike choreography; callouts name the art as a cause |
| Gambit / battalion | source, origin target, affected footprint | every affected tile/unit, per-target outcome uncertainty, resource spend | One action header; per-target events remain ordered under `[CFB-10]` |
| Shove / swap / pivot / reposition | source, target, destination(s) | origin-to-destination arrows, collision/invalid result, landing effects | Movement animation replaces strike motion; log records actual final tiles |
| Refresh / dancer | source, target | whether the target can receive another action and any secondary effect | No fake attack choreography; one above-head cause callout then state change |
| Secondary movement | acting unit, destination | remaining range and action-ending consequences | Map range overlay owns it; log only records consequential effects |
| Rescue carry/drop | source, target, optional destination | resulting lead/carried identities, stat/action restrictions, legal drop cells | Persistent carried state belongs in unit status/details, not transient text alone |
| Warp / Rescue staff | source, target, destination | staff cost/range, legal landing cells, success rule | Source callout plus movement path/landing; never imply damage choreography |
| Hammerne / utility item target | source, inventory target | exact item, before/after durability, cost | Confirmation summary is the primary proof; log records the mutation |

## Shared interaction contract

The preview model should expose data, not presentation instructions:

```text
action_id, source_unit_id, primary_target_id
selectable_targets, selectable_tiles, affected_units, affected_tiles
costs, predicted_mutations, uncertainty, invalid_reasons
feedback_category, choreography_kind
```

`choreography_kind` is an open registry (`strike`, `displacement`, `state_change`, `transfer`,
and future pack-provided values), not a type switch. The resolved action returns actual mutations
and tagged CFB events. Preview and resolution must share the same rule handler so a legal preview
cannot disagree with execution.

## Constraints inherited from resolved decisions

- `[CFB-9]` attack motion applies only to strike-like actions. A refresh or Hammerne use must not
  run toward its target merely because it shares an action menu.
- `[CFB-12]` category settings suppress their entire timing beat. They never suppress selection,
  preview, costs, or confirmation evidence.
- `[CFB-3]` records resolved events in the unified rewind/log surface. Preview is not history.
- `DSP-16` owns displacement preview/RNG. This packet only decides how that evidence is shown.
- Hidden information stays behind the resolved `PER-9` viewer gate; area previews must not reveal
  unseen units merely because their tile lies in a footprint.
- Cancellation before confirmation changes nothing. After confirmation, the action is one atomic
  transaction even when it affects several targets.

## Implementation seams after the owner walk

- `ActionPreviewService`: registered preview handlers returning the shared record.
- `ActionTargetingController`: target/tile/area selection state, input-method independent.
- `ActionConfirmationPanel`: one summary surface for costs, mutations, and uncertainty.
- `ActionExecutionService`: commits through the same registered handler and emits ordered CFB
  events plus a ledger anchor.
- Presentation renderers keyed by `choreography_kind`; none owns game rules.

The stable owner questions are in
[`combat_actions_ux_open_questions_2026-08-08.md`](../registers/combat_actions_ux_open_questions_2026-08-08.md).
