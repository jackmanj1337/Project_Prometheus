---
Role: dated
Type: register
Status: RESOLVED — all 12 walked 2026-08-13 (11 resolved, 1 closed by precedence)
Last verified: 2026-08-13
Register: SKF-1..12
Tracker: DISCUSS-SKILL-STATUS-FEEDBACK-2026-07-23
---

# Skill and Status Feedback Open Questions (`SKF`)

Research and recommendations:
[`skill_status_feedback_research_2026-08-08.md`](../design/skill_status_feedback_research_2026-08-08.md).
The resolved shared vocabulary is `CFB-1..18`; these questions specialize it and do not
reopen it.

## Precedence walk, 2026-08-13 — read this before walking the rest

The mandatory precedence check ran first and is recorded in
[`skf_drc_precedence_diff_2026-08-13.md`](../design/skf_drc_precedence_diff_2026-08-13.md).
It found one question already answered, three arguing against ratified text, two claiming an
inheritance that does not exist, and three constraints ratified after this packet was written.
The owner walked those findings the same day; the rulings below bind the remaining walk.

**`[SKF-5]` is CLOSED by precedence, not walked.** `[CFB-1]` already ruled silence on a failed
activation-chance roll — same question, same answer. The only residue is whether a debug/verbose
diagnostic mode exists as a product concept, which is a tooling question and not `SKF`'s.

**`[SKF-2]` and `[SKF-6]` do not inherit an attribution ruling — there isn't one.** This packet's
research doc cites `[CFB-10]`/`[CFB-11]` as naming source, cause and resolved target. Neither item
does: `CFB-10` is the resolution pipeline and Phase A/D callout placement, `CFB-11` is callout
scope. Attribution lives in an *unnumbered* section of the `CFB` research doc, and the redirect
requirement belongs to `[CVR-4]`, which that same doc calls designed-but-unbuilt with zero rendered
paths. **So `SKF-2`/`SKF-6` are the first place attribution gets decided**, and whatever they rule
becomes the contract `CVR-4`'s unbuilt forecast requirement must satisfy. Walk them with that
weight. The same defect applies to the "semantic animation roles" that `SKF-11`/`SKF-12` attribute
to `[CFB-18]`: `CFB-18` ruled texture swap plus priority-ordered clip lookup and contains no such
concept, so animation role is **new vocabulary proposed ahead of a rig that does not exist**.

### Owner rulings, 2026-08-13

- **`[SKF-1]` — RESOLVED. Author-set category defaults.** `[CFB-11]`'s callout scope stands
  unchanged. `SKF-1`'s boundary test becomes an author-set default for the **initial state** of
  `[CFB-12]`'s notification-category checkboxes, which the player may override freely.
  This narrowly amends `[CFB-5]`: its ban was on a **per-skill** visibility override and that ban
  stands — what changes is that the **category-level** defaults become authored rather than
  engine-fixed. `[CFB-13]` follows for free, since a default-off category costs no time budget
  until the player enables it.
- **Settings scope — RESOLVED.** Notification-category settings are stored **per campaign**,
  persist across runs of that campaign, and do **not** apply to sibling campaigns in the same
  pack. A campaign's first run seeds from the authored defaults above; the player's changes stick
  for that campaign thereafter. **Deliberately different from `[CAU-4]`**, which scopes its
  confirmation presets as global player settings with an optional campaign/run override. Two
  settings families, two scoping models, on purpose — do not harmonize them.
- **`[SKF-3]` — RESOLVED. Activation order, presentation priority breaks ties.** `[CFB-9]`'s
  activation order remains the spine; resolved priority with stable-id ties orders only genuinely
  simultaneous activations. Callout order therefore always equals log order. `SKF-3`'s other
  clause — a blocking reaction appears immediately before the event it changes — was already ruled
  by `[CFB-2]`, which places negations in the `[CFB-10]` Phase A sequence before the strike.
- **`[SKF-12]` missing-metadata posture — RESOLVED. Adopt `[DLUX-10]`'s model verbatim.** Feedback
  metadata defaults to `optional`: a missing field uses the registered stable fallback and emits a
  structured **author-time** warning, while the player sees the silent fallback `[CFB-16]` ruled.
  An author may mark a field `required`, and pack validation then fails before play. This resolves
  the apparent `SKF-12`/`CFB-16` conflict as an author-time versus runtime split, and reuses a
  contract that already exists rather than inventing a second one. `SKF-12`'s required-field *list*
  is still open — and per `[CFB-17]`, presentation priority and animation role must not become the
  redundant hand-maintained flags `CFB-17` banned.
- **Dwell budget under `[L10N-7]` — RESOLVED. Floor plus bounded scaling.** A minimum dwell per
  callout, extended proportionally once rendered text exceeds a threshold, up to a hard cap, plus a
  player-side speed multiplier following `[CFB-15]`'s per-player per-context precedent. Satisfies
  XAG 117 for long localized names while keeping worst-case exchange length bounded, so `[CFB-13]`
  can still budget it. This is a **new question neither register asked**, created by `[L10N-7]`'s
  1.4× extent five days after this packet was written; it governs the base budget, and `SKF-11`
  inherits it.
- **Direction metadata under `[L10N-12]` — RESOLVED. Decompose the components.** Both `SKF`
  channels are *mixed*: the anchor is map-anchored and must never flip sides, while the internal
  icon/text layout is reading order and must mirror in RTL. Rather than widen `L10N-12`'s contract,
  split each channel into a map-anchored positioner declaring non-mirroring, containing a
  badge/text component declaring mirroring. `[L10N-12]` is unchanged and each component still makes
  one honest declaration.

### Owner rulings, 2026-08-13 (second walk — the remaining eight)

Walked in the diff's recommended order, attribution first.

- **`[SKF-2]` — RESOLVED. The record carries full attribution; each channel projects a declared
  subset.** The event record **always** carries source, cause, attempted cause, blocking cause,
  intended target and actual resolved target. A channel declares which of those fields it renders,
  so `[CFB-9]`'s above-head callout may stay terse while `[CFB-3]`'s log stays complete. **One
  field is forced onto every channel that fires:** where the actual resolved target differs from the
  intended target — the `RDR`/`CVR`/`RCT` interceptor families — the substitution is always
  rendered. This is the first ruling on attribution anywhere in the project, and it is the contract
  `[CVR-4]`'s designed-but-unbuilt pre-commit forecast must satisfy. Keeping the callout's field set
  declarable is what stops `[L10N-7]`'s 1.4× extent from consuming the dwell budget ruled above.
- **`[SKF-6]` — RESOLVED. An external cause is the discriminator.** Three outcomes exist in the
  record: `immune` (the target cannot receive it), `negated` (another cause cancelled it), and
  `no_effect` (a valid resolution that changed nothing). `immune` and `negated` always fire a
  callout, as `[CFB-2]` already ruled. **`no_effect` is log-only** — no callout. The line is whether
  an *external cause* explains the non-event: a target property or a blocker does, a resolution
  landing with zero delta does not, which puts `no_effect` on `[CFB-1]`'s side of the boundary. It
  still resolved, so unlike a failed proc it keeps its log record for reconstruction. Rejected:
  firing `no_effect` only for player-initiated attempts — that forks feedback by actor, which
  `CFB`'s ratified parity principle bans outright.
- **`[SKF-4]` — RESOLVED. Number-changing contributions, itemized by source.** Re-scoped per the
  diff: `[CAU-5]`/`[CAU-9]` already own the breakdown surface, so the question is what the
  registered preview handler must include. Every modifier that changes a displayed number is
  itemized by its source. A contribution that resolved to zero delta collapses into a single
  on-demand "applied, no change" affordance rather than vanishing — truthful without flooding the
  360×640 floor's 4.3 rows. Live callout and log stay reserved for discrete events per `[SKF-1]`.
  Rejected: an author-set significance threshold, which would be a second visibility vocabulary
  beside `[EPUX-02]`'s.
- **`[SKF-7]` — RESOLVED. Stacking and removal are both derived from declaration.** `[CAU-8]`
  already carries source, effects and expiration. The residue: stacking is a **declared property**
  in the status registry (`no_stack` | `refresh` | `additive_stacks` | `independent_instances`) and
  the detail page renders that declaration; the removal rule is **derived from the same predicate
  the engine uses to remove the status**, so displayed text cannot drift from behavior. Authored
  copy overrides for flavor only. Follows `[CFB-17]` — the declaration is the real thing, not a
  redundant parallel flag.
- **`[SKF-8]` residue — RESOLVED. An open registry of priority bands, seeded with the six.**
  Immediate danger, action denial, forced behavior/targeting, numeric penalties, numeric bonuses,
  informational ship as **data** in an open band registry; a pack may add or reorder bands with no
  engine edit. Sort is band → authored priority → stable id. Cycling behavior itself is `[CAU-8]`'s,
  not redefined here. The closed enum was the smell the project's open-registry principle names.
- **`[SKF-9]` — RESOLVED. A mechanical delta test.** A status transition emits feedback when
  duration, stack count, intensity, or the effect set **actually changes value**. A refresh with no
  delta is `no_effect` and is log-only, falling straight out of `[SKF-6]`. This **deletes the
  undefined term "tactically meaningful"** from this register: no authored judgment, no per-status
  tuning, and the rule is testable. Rejected: an authored per-transition significance flag, which is
  the per-status visibility override `[CFB-5]` refused authors in v1.
- **`[SKF-10]` — RESOLVED. Four explicit duration kinds; `unknown` is a real rendered value.** If a
  status renders at all, its duration renders as exactly one of `permanent`, `until_map_end`,
  `condition_based` (naming the condition), or `unknown`. Never a fabricated turn count, never an
  ambiguous blank. **`unknown` is distinct from `[CFB-8]`'s redaction** and does not extend it:
  `CFB-8` removes an entire event a viewer cannot perceive, whereas a visible status whose remaining
  duration is unknowable is a different case that needs its own truthful value. Hiding a status whose
  effects the player can plainly see would read as a bug — the failure mode `[CFB-2]` rejected
  silence for.
- **`[SKF-11]` residue — RESOLVED. No new authoring vocabulary; reduced motion is a presenter
  transform.** Same badge, text, ordering and dwell rendered statically with a short fade — no
  bounce, zoom, shake, peripheral travel, and no focus change (`[CAU-10]` already bans the focus
  steal). The static fallback is selected by `[CFB-18]`'s existing priority-ordered clip lookup with
  motion clips excluded. **"Animation role" is dropped**, not deferred: it was new vocabulary
  mis-attributed to `CFB-18`, proposed ahead of a rig `CFB-18` records does not exist, and it would
  have been exactly the hand-maintained field `[CFB-17]` banned.
- **`[SKF-12]` required-field list — RESOLVED. Minimal required set, the rest derived.** Required:
  `status_id`/`skill_id`, `display_name_key`, `description_key`, notification category (authored per
  `[SKF-1]`), and outcome-copy keys for `immune`/`negated`/`no_effect`. **Derived, declarable only as
  an override:** icon/badge from authored asset presence per `[CFB-17]`, and presentation priority
  from `[SKF-8]`'s band registry. `[L10N-9]`'s split is structural here — the registry id is never
  translated and the display key is a separate field. Animation role is absent, per `SKF-11` above.

**Register closed.** All twelve are resolved or closed by precedence, satisfying the exit condition
below. `[CAU-5]`/`[CAU-8]` narrowed `SKF-4` and `SKF-7` before the walk — see the diff.

**`[DLUX-4]` draws this register's outer boundary, in its favour:** skill activation, critical,
immunity, status and resolution callouts belong **exclusively** to the combat-notification system
and must not be duplicated in dialogue. One combat event may independently emit a mechanical
notification *and* invoke an authored narrative bark; neither proxies for the other, and only the
bark enters dialogue history.

## Activation and attribution

### [SKF-1] Which skill resolutions earn an above-head callout? — **RESOLVED 2026-08-13**

**Recommendation:** call out activated skills, reactions/counters, negations, and discrete
status transitions; suppress routine passive arithmetic unless it creates a discrete event
or crosses a tactically meaningful boundary.

**Inherited:** `CFB-9` choreography, `CFB-12` categories, `CFB-13` disabled-beat timing.
**Consumer:** feedback-event routing policy and authored presentation priority.

### [SKF-2] What minimum attribution does every resolved event owe? — **RESOLVED 2026-08-13**

**Recommendation:** source, displayed cause, and actual resolved target; a negation also
names the attempted cause and the blocking cause.

**Inherited:** `CFB-4`/`CFB-8` visibility.
**NOT inherited — decided here:** attribution. No `CFB-n` item rules it; the earlier citation of
`CFB-10`/`CFB-11` was wrong (see the precedence walk above). **Related:** `[CVR-4]`'s
designed-but-unbuilt requirement that a redirected hit show the actual defender pre-commit.
**Consumer:** localized event arguments, above-head badge, and combat-log formatter.

### [SKF-3] How should simultaneous or nested skill events order? — **RESOLVED 2026-08-13**

**Recommendation:** simulation resolution order is the log order; callouts use resolved
priority with stable-id ties, never arrival timing. A blocking reaction appears immediately
before the event it changes.

**Inherited:** `CFB-9` choreography, `CFB-2` blocking-reaction placement, `CFB-10` phase
structure. Animation selection is `CFB-18` alone — the earlier `CFB-14..18` citation was wrong.
**Consumer:** feedback queue and animation-role priority lookup.

## Passive and failed effects

### [SKF-4] When is an always-on passive surfaced during combat? — **RESOLVED 2026-08-13**

**Recommendation:** always in character-sheet identity, in inspectable forecast/result
breakdowns when it changes a displayed number, and in live callout/log only for a discrete
event or tactically meaningful boundary.

**Inherited:** `CFB-3` log and `CFB-6` on-demand detail tiers.
**Consumer:** forecast breakdown, result attribution, and passive event budget.

### [SKF-5] Should a failed random activation roll be shown? — **CLOSED BY PRECEDENCE ([CFB-1])**

**Recommendation:** silent by default. It produced no state change and logging every failed
roll would reveal hidden checks and overwhelm resolved events. Permit it only in a debug or
explicitly verbose diagnostic mode, never the normal player log.

**Inherited:** `CFB-3` log, `CFB-12` categories.
**Consumer:** skill dispatcher feedback policy and diagnostic settings.

### [SKF-6] How are immunity, cancellation, and no-effect distinguished? — **RESOLVED 2026-08-13**

**Recommendation:** three semantic outcomes: `immune` (target cannot receive it), `negated`
(another cause cancelled it), and `no_effect` (valid resolution changed nothing). Each names
the attempted cause; `negated` also names the blocker.

**Inherited:** `CFB-2`'s always-on immunity/negation ruling and its no-silent-negation principle.
**NOT inherited — decided here:** attribution, as for `SKF-2`. Note `no_effect` must state where it
sits relative to `[CFB-1]`'s silence, since a resolution that changed nothing is that boundary.
**Consumer:** feedback-event outcome vocabulary and localized copy keys.

## Status lifecycle

### [SKF-7] What information belongs in full status detail? — **RESOLVED 2026-08-13**

**Recommendation:** name, icon, effect summary, source when known, duration/expiry rule,
stacks/intensity when present, and removal rule. Never infer “permanent” from a blank duration.

**Inherited:** `CFB-6` cycling marker plus character-sheet detail.
**Consumer:** condition state snapshot and character-sheet status section.

### [SKF-8] How are active statuses ordered in the cycling field marker? — **RESOLVED 2026-08-13**

**Recommendation:** immediate danger, action denial, forced behavior/targeting, numeric
penalties, numeric bonuses, informational state; then authored priority and stable id.
Keep this an open data registry rather than a status enum.

**Inherited:** `CFB-6` single cycling marker.
**Consumer:** status presentation-priority registry and field marker.

### [SKF-9] Which status transitions produce event feedback? — **RESOLVED 2026-08-13**

**Recommendation:** application, failed/blocked application, tactically meaningful refresh
or stack change, expiry, and active removal. Suppress refreshes that change no duration,
stack, intensity, or effect.

**Inherited:** event/state split, `CFB-3`, `CFB-9`, `CFB-12`.
**Consumer:** ConditionManager transition emitter and event deduplication.

### [SKF-10] How are hidden or unknown durations represented? — **RESOLVED 2026-08-13**

**Recommendation:** explicit localized values for permanent, until-map-end, condition-based,
and unknown/hidden. Never render a fabricated turn count or an ambiguous blank.

**Inherited:** `CFB-4`/`CFB-8` viewer visibility.
**Consumer:** status snapshot visibility projection and detail copy.

## Accessibility and authoring

### [SKF-11] What is the reduced-motion fallback for skill feedback? — **RESOLVED 2026-08-13**

**Recommendation:** the same badge, text, ordering, and dwell budget rendered statically
with a short fade; no bounce, zoom, shake, peripheral travel, or focus change.

**Inherited:** `CFB-9`/`CFB-13` time budget, as amended by the 2026-08-13 dwell ruling above.
**NOT inherited:** `CFB-18` contains no "semantic animation role" concept — it ruled texture swap
plus priority-ordered clip lookup. Animation role is new vocabulary proposed here.
**Consumer:** feedback presenter and animation-role fallback registry.

### [SKF-12] What must authors supply for a feedback-capable skill or status? — **RESOLVED 2026-08-13**

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
