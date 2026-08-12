---
Type: design
Status: Proposed — owner questions open in the SKF register
Last verified: 2026-08-08
Tracker: DISCUSS-SKILL-STATUS-FEEDBACK-2026-07-23
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Skill and Status Feedback — Research Packet

This packet specializes the resolved combat-feedback vocabulary in
[`combat_feedback_vocabulary_research_2026-08-07.md`](combat_feedback_vocabulary_research_2026-08-07.md).
It does not redefine channels, visibility, timing, choreography, or settings categories.
The live decisions are the stable `SKF-n` questions in
[`skill_status_feedback_open_questions_2026-08-08.md`](../registers/skill_status_feedback_open_questions_2026-08-08.md).

## Scope

The remaining design problem is the presentation contract for six cases:

1. an activated skill resolves;
2. an always-on passive changes a calculation;
3. a reaction or counter interrupts normal resolution;
4. an immunity or cancellation prevents an effect;
5. a random activation roll fails; and
6. a status is applied, refreshed, expires, is removed, or fails to apply.

Skill mechanics, loadout categories, trigger order, reaction mechanics, and status
semantics are already settled elsewhere. `SKF` decides what the player is told, not what
the simulation does.

## Inherited CFB contract

| Concern | Inherited decision | SKF consequence |
|---|---|---|
| Event versus state | An activation is an event; a condition that remains active is state. | A status application may create an event callout/log entry and separately update the persistent status marker. |
| Primary callout | `[CFB-9]` owns the above-head callout choreography. | SKF supplies cause/outcome copy and priority only; it does not invent another toast or banner. |
| Reviewable history | `[CFB-3]` owns a non-modal, chronological combat log. | Every visible resolved outcome can be reconstructed after animation completes. |
| Persistent state | `[CFB-6]` owns one cycling field icon and full character-sheet detail. | SKF defines badge identity, ordering, stack/duration text, and transition copy. |
| Attribution | `[CFB-10]` and `[CFB-11]` name source, cause, and actual resolved target. | Redirects, immunities, and counters cannot be rendered as unattributed damage or silence. |
| Visibility | `[CFB-4]`/`[CFB-8]` suppress events that fail the viewer's `visible_to` gate. | The log is not an information-leak back door. |
| Categories | `[CFB-12]` owns category-level notification controls; `[CFB-13]` removes disabled beats from the time budget. | Per-skill toggles are out of scope; authors classify content into the shared categories. |
| Motion | `[CFB-18]` uses property swap plus priority lookup; it does not commit to animation compositing. | Skill feedback requests semantic animation roles and must have a static fallback. |

## Evidence translated into design constraints

Microsoft's Xbox Accessibility Guideline 103 says gameplay-critical cues should use
more than one sensory method and warns that colour alone is insufficient. It also treats
haptics as supplemental because a device may not provide them or a player may disable
them. Therefore a skill/status outcome needs readable text or a named icon in addition to
colour, sound, or rumble; haptics may reinforce an event but cannot carry its meaning.
[Source: XAG 103](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/103)

XAG 102 explicitly includes in-game notifications and active-play text in its contrast
scope. Above-head cause/outcome copy therefore needs its own contrast-preserving backing
or outline rather than assuming the map beneath it is dark or quiet.
[Source: XAG 102](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/102)

XAG 117 requires players to be able to pause or stop moving, blinking, scrolling, and
auto-updating content, and calls out players who cannot read before content changes. The
persistent log is consequently not optional compensation for a short callout: it is the
stable route when motion is reduced or event density exceeds reading speed.
[Source: XAG 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117)

Apple's accessibility guidance recommends reducing automatic, repetitive, peripheral,
zooming, and scaling motion when Reduce Motion is active, often substituting fades.
Prometheus is cross-platform and cannot assume one OS setting is exposed everywhere, so
its own motion setting must select the same semantic fallback: static badge/text plus fade,
without bounce, zoom, shake, or peripheral travel.
[Source: Apple accessibility guidance](https://developer.apple.com/design/human-interface-guidelines/accessibility/)

W3C's status-message guidance establishes a useful non-web principle: a status change
should be exposed without moving focus to it. Skill feedback must not steal map focus,
open the log, or interrupt controller navigation merely to announce that something
happened.
[Source: WCAG 2.2 status messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html)

## Proposed message grammar

All channels derive from one localized semantic record. They do not concatenate raw ids
or build sentences independently.

| Outcome | Above-head compact form | Combat-log full form | Persistent-state change |
|---|---|---|---|
| Activated | `{cause_name}` | `{source_name}: {cause_name} activated on {target_name}.` | None unless the effect also creates state. |
| Passive contribution | Normally no separate callout | `{source_name}'s {cause_name}: {effect_summary}.` when the contribution changes a visible result | Character sheet lists the passive under its settled skill category. |
| Counter/reaction | `{cause_name}` before the reaction animation | `{source_name}'s {cause_name} reacted to {target_name}.` | None unless a resulting state persists. |
| Negated/immune | `{outcome_name}` with cause badge | `{target_name}: {attempted_cause} was blocked by {blocking_cause}.` | Existing immunity state remains inspectable. |
| Failed random proc | Open question; default recommendation is silence | Optional diagnostic only, never default player log noise | None. |
| Status applied | `{status_name}` | `{source_name} applied {status_name} to {target_name}.` | Add/refresh the field icon and sheet row. |
| Status expired/removed | Compact removal mark only if tactically relevant | `{status_name} expired on {target_name}.` or `{source_name} removed ...` | Remove/update the icon and sheet row. |

The grammar distinguishes an attempted cause from the blocking cause. “Immune” alone is
insufficient when several skills, items, terrain effects, or rules could explain why.

## Passive-skill budget

Always-on modifiers are the high-volume hazard. Repeating “Faire” or “Aura” on every
arithmetic step would bury reactions and status changes. The recommended rule is:

- the character sheet always exposes equipped/personal/class/granted passive identity;
- forecasts expose passives that change a displayed number through an inspectable
  breakdown;
- the event choreography calls a passive out only when it creates a discrete event or
  crosses a tactically meaningful boundary;
- the combat log records a passive contribution only when it changes the visible
  resolved outcome and the player has enabled that category.

This preserves attribution without turning every derived stat into an event.

## Status-state contract

The cycling field marker answers only “this unit has active state.” The character sheet
must answer the rest for every active condition: localized name, icon, source when known,
remaining duration or expiry rule, stacks/intensity when the mechanic has them, effect
summary, and removal rule. “Permanent,” “until map end,” and an unknown/hidden duration
are distinct authored values, not the same blank label.

Ordering should be deterministic. The recommended order is immediate danger first,
action denial second, forced behavior/targeting third, numeric penalties, numeric bonuses,
then informational states; ties use authored priority and stable id. This is a presentation
priority registry, not a closed status enum.

## Runtime seam implied by the packet

`SKF` needs one open feedback-event record feeding every channel and one state snapshot
feeding the icon/sheet. The event must carry semantic localization keys and structured
arguments, not final English strings. At minimum it needs source, actual target, attempted
cause, resolved/blocking cause, outcome, category, visibility, and optional magnitude/state
transition. The status snapshot needs stable id, source, duration/expiry, stack/intensity,
and presentation priority.

This deliberately does not authorize implementation. `ConditionManager` remains a stub,
and the broad skill/condition build is still its separately tracked milestone.

## Validation fixtures for the eventual build

- One visible activation with source, cause, actual target, and matching log order.
- One hidden activation that emits no player channel under the viewer's visibility gate.
- One immunity where attempted and blocking causes are different and both are named.
- Ten passive contributions in one exchange without ten redundant callouts.
- Apply, refresh, stack, expire, cleanse, and permanent status transitions.
- More simultaneous statuses than fit in one field-marker cycle.
- Long localized names and right-to-left text without sentence-fragment concatenation.
- Reduced-motion mode with identical information and no bounce, zoom, shake, or focus move.
- Sound and haptics disabled while the visual/text route remains sufficient.

## Owner decisions

The research recommendations are intentionally not ratified here. Decide `SKF-1..12` in
the linked register; every question records which `CFB` choices it inherits and the
runtime/UI seam that consumes the answer.
