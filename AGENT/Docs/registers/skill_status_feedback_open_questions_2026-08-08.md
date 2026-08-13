---
Type: register
Status: OPEN
Last verified: 2026-08-08
Register: SKF-1..12
Tracker: DISCUSS-SKILL-STATUS-FEEDBACK-2026-07-23
---

# Skill and Status Feedback Open Questions (`SKF`)

Research and recommendations:
[`skill_status_feedback_research_2026-08-08.md`](../design/skill_status_feedback_research_2026-08-08.md).
The resolved shared vocabulary is `CFB-1..18`; these questions specialize it and do not
reopen it.

## Activation and attribution

### [SKF-1] Which skill resolutions earn an above-head callout? — **OPEN**

**Recommendation:** call out activated skills, reactions/counters, negations, and discrete
status transitions; suppress routine passive arithmetic unless it creates a discrete event
or crosses a tactically meaningful boundary.

**Inherited:** `CFB-9` choreography, `CFB-12` categories, `CFB-13` disabled-beat timing.
**Consumer:** feedback-event routing policy and authored presentation priority.

### [SKF-2] What minimum attribution does every resolved event owe? — **OPEN**

**Recommendation:** source, displayed cause, and actual resolved target; a negation also
names the attempted cause and the blocking cause.

**Inherited:** `CFB-10` attribution, `CFB-11` redirects, `CFB-4`/`CFB-8` visibility.
**Consumer:** localized event arguments, above-head badge, and combat-log formatter.

### [SKF-3] How should simultaneous or nested skill events order? — **OPEN**

**Recommendation:** simulation resolution order is the log order; callouts use resolved
priority with stable-id ties, never arrival timing. A blocking reaction appears immediately
before the event it changes.

**Inherited:** `CFB-9` choreography and `CFB-14..18` animation-selection decisions.
**Consumer:** feedback queue and animation-role priority lookup.

## Passive and failed effects

### [SKF-4] When is an always-on passive surfaced during combat? — **OPEN**

**Recommendation:** always in character-sheet identity, in inspectable forecast/result
breakdowns when it changes a displayed number, and in live callout/log only for a discrete
event or tactically meaningful boundary.

**Inherited:** `CFB-3` log and `CFB-6` on-demand detail tiers.
**Consumer:** forecast breakdown, result attribution, and passive event budget.

### [SKF-5] Should a failed random activation roll be shown? — **OPEN**

**Recommendation:** silent by default. It produced no state change and logging every failed
roll would reveal hidden checks and overwhelm resolved events. Permit it only in a debug or
explicitly verbose diagnostic mode, never the normal player log.

**Inherited:** `CFB-3` log, `CFB-12` categories.
**Consumer:** skill dispatcher feedback policy and diagnostic settings.

### [SKF-6] How are immunity, cancellation, and no-effect distinguished? — **OPEN**

**Recommendation:** three semantic outcomes: `immune` (target cannot receive it), `negated`
(another cause cancelled it), and `no_effect` (valid resolution changed nothing). Each names
the attempted cause; `negated` also names the blocker.

**Inherited:** `CFB-10` attribution and the no-silent-negation principle.
**Consumer:** feedback-event outcome vocabulary and localized copy keys.

## Status lifecycle

### [SKF-7] What information belongs in full status detail? — **OPEN**

**Recommendation:** name, icon, effect summary, source when known, duration/expiry rule,
stacks/intensity when present, and removal rule. Never infer “permanent” from a blank duration.

**Inherited:** `CFB-6` cycling marker plus character-sheet detail.
**Consumer:** condition state snapshot and character-sheet status section.

### [SKF-8] How are active statuses ordered in the cycling field marker? — **OPEN**

**Recommendation:** immediate danger, action denial, forced behavior/targeting, numeric
penalties, numeric bonuses, informational state; then authored priority and stable id.
Keep this an open data registry rather than a status enum.

**Inherited:** `CFB-6` single cycling marker.
**Consumer:** status presentation-priority registry and field marker.

### [SKF-9] Which status transitions produce event feedback? — **OPEN**

**Recommendation:** application, failed/blocked application, tactically meaningful refresh
or stack change, expiry, and active removal. Suppress refreshes that change no duration,
stack, intensity, or effect.

**Inherited:** event/state split, `CFB-3`, `CFB-9`, `CFB-12`.
**Consumer:** ConditionManager transition emitter and event deduplication.

### [SKF-10] How are hidden or unknown durations represented? — **OPEN**

**Recommendation:** explicit localized values for permanent, until-map-end, condition-based,
and unknown/hidden. Never render a fabricated turn count or an ambiguous blank.

**Inherited:** `CFB-4`/`CFB-8` viewer visibility.
**Consumer:** status snapshot visibility projection and detail copy.

## Accessibility and authoring

### [SKF-11] What is the reduced-motion fallback for skill feedback? — **OPEN**

**Recommendation:** the same badge, text, ordering, and dwell budget rendered statically
with a short fade; no bounce, zoom, shake, peripheral travel, or focus change.

**Inherited:** `CFB-9`/`CFB-13` time budget and `CFB-18` semantic animation roles.
**Consumer:** feedback presenter and animation-role fallback registry.

### [SKF-12] What must authors supply for a feedback-capable skill or status? — **OPEN**

**Recommendation:** localized display name and description, notification category, semantic
icon/badge id, presentation priority, animation role, and outcome-copy keys. Engine defaults
must be visible validator warnings, not silent generic English strings.

**Inherited:** the project's open-registry architecture and all CFB channel choices.
**Consumer:** Tier-2 schemas, pack validator, localization catalogue, and feedback registry.

## Exit condition

Close this register only when all twelve questions are resolved or deliberately deferred
with a named dependency. Then update `DISCUSS-SKILL-STATUS-FEEDBACK-2026-07-23`; the broad
skill/condition implementation row may consume the decisions, but this packet does not
authorize that build by itself.
