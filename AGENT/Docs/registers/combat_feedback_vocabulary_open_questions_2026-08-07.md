---
Role: dated
Type: register
Status: RESOLVED — all CFB-1..18 decided; SKF/CAU/DUX packets not yet started
Last verified: 2026-08-08
Register: CFB-1..18
---

# Combat Feedback Vocabulary — Owner Questions and Decisions

**Started:** 2026-08-08, the first owner walk of
[`combat_feedback_vocabulary_research_2026-08-07.md`](../design/combat_feedback_vocabulary_research_2026-08-07.md),
the shared `CFB` doc the `SKF`/`CAU`/`DUX` rows all read. This register is the live source of
truth for `CFB-n` status — the research doc's own "open questions" section now just points here
rather than duplicating.

**Closed across two sessions, both 2026-08-08** — session 1 resolved most of the
presentation/choreography shape and deliberately deferred one hard question (animation reuse,
`[CFB-18]`) to research rather than guess at an engine-architecture commitment; session 2 did that
research and walked the remaining items to a decision. Several resolutions are design-only,
blocked on other registers for actual implementation (`[CFB-6]` on `ConditionManager`/M8-M9,
`[CFB-18]`/`[CFB-14]` on a rig existing at all) — that is expected and does not reopen them; see
each item's own note.

## Resolved decisions — 2026-08-08

### [CFB-1] Failed activation-chance roll gets no feedback — **RESOLVED**
Silence. `SkillData.activation_chance_stat`/`activation_divisor` model a real per-skill roll that
can miss; a miss is genuinely "nothing happened," unlike an immunity/negation (`[CFB-2]`, still
open) where an external cause explains the non-event. Established by the choreography decision
below, which only shows skills "that activate."

### [CFB-5] Callout-volume/clutter control — **RESOLVED, reframed**
Originally framed as an author-authored per-skill channel override. Resolved instead as a
**player-facing settings checkbox list** disabling notification categories — see `[CFB-12]`.
Authors do not get a per-skill visibility override in v1.

### [CFB-9] Combat choreography model — **RESOLVED (provisional — "for now")**
One cycle, repeated independently for every strike in an exchange (initial attack, counter,
follow-up/double):
1. Every skill/bonus that activates for this strike shows its name + icon above its holder's
   head, one at a time, in activation order (icon may be transparent if none authored).
2. The attacking unit backs up slightly, runs partway into the defender's tile (a stylized clash
   position — the unit's logical tile never changes), plays an impact sound, holds one frame, then
   retreats to its resting position, alongside "Hit XX" / "No Damage" / "Miss" text.
3. On a Miss, the defending unit backs up half a tile away from the attacker before returning, so
   the units never visually overlap.

Explicitly a first pass, expected to be revised once real art/animation work starts.

### [CFB-10] Resolution pipeline + start/end callout placement — **RESOLVED**
Code-verified pipeline (`CombatResolver.gd`): **Phase A** (once per exchange, before any strike) —
pair-up bonuses → `active_modifiers` → allied `on_combat_apply_modifiers` auras → equip-item
modifiers → `on_combat_start_negate` pre-pass → `on_combat_start` (Vantage gets flagged here) —
**then** strike order (Vantage-flip / attacker / counter / follow-up, each running the per-strike
`on_attack → on_hit → on_damaged → on_kill` sequence) — **then Phase D** (once per exchange, after
every strike) — `on_combat_end`.

Both Phase A and Phase D get **exactly one callout section**, once per whole exchange — not
repeated per strike. This mirrors the code structure directly: both phases are already dispatched
once, attacker-then-defender, outside the strike loop.

Note: `on_defend` is spec vocabulary with **zero dispatch code anywhere** in `CombatResolver.gd`
or `SkillHandler.gd` — do not design its ordering relative to `on_attack`; it does not exist yet.

### [CFB-11] Callout scope = every Phase A/D modifier source, not just skills — **RESOLVED**
Pair-up bonuses, the generic `active_modifiers` bucket, ally auras
(`on_combat_apply_modifiers`), equip-item modifiers, and actual `SkillData` triggers **all** get a
callout. No "is this a real skill" filtering.

### [CFB-12] Player-facing notification-category checkboxes — **RESOLVED**
Proposed groups: **Skill activations**, **Pair-Up bonuses**, **Equipment bonuses**, **Ally aura
effects**, **Status effects** (reserved row, inert until `ConditionManager` leaves stub status
under M8/M9).

The generic `active_modifiers` bucket **folds into "Skill activations"** — no separate row.
Confirmed 2026-08-08, consistent with `[CFB-2]`'s decision to categorize immunity/negation under
its cause's existing bucket rather than inventing new categories for things a player cannot
visually distinguish from a skill.

### [CFB-14] Reserve a seam for a future detailed/cinematic renderer — **RESOLVED**
A later, higher-fidelity "Full" battle-scene renderer (in the spirit of classic Fire Emblem /
Fire Emblem Engage's close-up combat view) consumes the **same** ordered per-exchange event stream
as the `[CFB-9]` "Simple" choreography. Adding it later is a new presentation implementation, not
a new event/data model. See the research doc's comparable-systems section for what could and
couldn't be confirmed about recent FE titles' own animation settings.

### [CFB-15] Per-player, per-context detail/speed setting — **RESOLVED**
Three tiers — **Off** (fast, no choreography, closest to today's instant `combat_resolved`) /
**Simple** (`[CFB-9]`, built now) / **Full** (`[CFB-14]`'s seam, not built) — set independently
**per local player/seat**, for three contexts:
- their own turn
- not their turn, but one of their units is the attacker or the defender in this exchange
- not their turn and neither unit is theirs (spectate)

"Involved" is scoped to **attacker/defender only** for now — explicitly does not (yet) cover
indirect participants from the unbuilt redirect/cover/reactive-reposition interceptor family;
revisit once that family is built. The `[CFB-12]` category checkboxes only apply when the tier is
`Simple` or `Full` — `Off` skips everything, categories included.

### [CFB-16] Full-tier gating — **RESOLVED**
**Coarse:** `Full` is only offered as a selectable tier at all if the active campaign pack declares
(via `[CFB-17]` asset presence) any cinematic art — no dead option pointing at nothing.

**Fine:** within an offered `Full` tier, a specific unit/strike lacking the asset for that specific
combination falls back to `Simple` automatically, **silently** — confirmed 2026-08-08, no
one-time notice. Keeps a partially-covered pack from nagging the player about an authoring gap
that isn't theirs to fix.

### [CFB-17] Author capability declaration = asset presence, not a separate flag — **RESOLVED**
A class/weapon/skill record either has an authored on-map-attack-asset reference and/or a
cinematic-art reference, or it doesn't — that presence **is** the author's declaration. No
redundant boolean flag to keep in sync with the actual assets, matching how `SkillData
.release_available` already keeps unfinished content inert without a second bookkeeping field. A
derived pack-level summary badge (for a campaign-library "supports cinematic battles" indicator)
can be computed from that presence later if wanted, not hand-authored.

The `[CFB-9]` approach-toward-enemy-square animation is an **engine-guaranteed default** requiring
no authored assets at all — a zero-content pack never has a broken or missing animation state,
just the plainest one.

### [CFB-18] Animation-selection hooks (source / method / skill trigger / crit) — **RESOLVED**
Two mechanisms, composed, no `AnimationTree` blend-graph work required for anything currently in
scope:
1. **Property/texture swap on a shared rig** for weapon- and effect-art reskins (the owner's named
   cases — simple/fancy axe, fire/lightning spell). One shared clip drives a weapon-slot node's
   motion; only the texture it displays changes per equipped item.
2. **Priority-ordered clip lookup** (skill-specific → crit → weapon/method default → engine
   generic) for a specific method, active skill trigger, or crit swapping in a distinct
   swing/animation. Resolution keys unchanged from the original framing: `cause_id`, the strike's
   weapon/method, crit status.

**True additive compositing** (`AnimationNodeBlendTree` Add node + track filters — real, available
in Godot 4.6, but genuine blend-graph engine work) is explicitly deferred, not ruled out: nothing
presently in scope needs two animations playing simultaneously rather than one clip substituting
for another. Revisit only if a concrete case arises (e.g. a persistent buff-aura visual concurrent
with an attack).

Basis: classic FE cannot be cited as precedent for a cheaper mechanism — its own authoring
convention is a full separate animation per weapon type in the general case (ad hoc reskinning
only works for near-identical weapons like sword/axe, not lances), and crits are typically
distinct full animations too. FE's actual answer to "avoid re-authoring per variant" is that it
doesn't. This is greenfield work — no `AnimationPlayer`/`AnimationTree`/`AnimatedSprite2D` exists
in the codebase today (`Unit.tscn` is one static `Sprite2D`, team-tinted by `modulate`), so
`[CFB-18]`'s decision is now a prerequisite for `[CSA-8]` (Unit → `AnimatedSprite2D`), not
downstream of it — there is no rig yet for the hook to attach to; the WeaponData/SkillData/
ClassData animation-reference field(s) this decision implies are also still unbuilt, to add as
part of implementation.

## Still open — carried to next session

### [CFB-2] Immunity/negation feedback threshold — **RESOLVED**
Always-on, same treatment as `[CFB-11]`'s modifier sources — not the silent `[CFB-1]` treatment.
Slots into the same choreography position as any other pre-damage skill: the `[CFB-10]` Phase A
callout sequence, before the strike itself, since an immunity/negation is by definition a
pre-strike effect (`on_combat_start_negate`). It is subject to the same `[CFB-12]` player-facing
notification-category checkboxes as any other combat effect — categorized under whichever bucket
its cause belongs to (typically Skill activations, since negation is a skill-triggered effect), not
a new standalone category. Disabling that category suppresses its callout the same way it would
suppress the skill firing normally.

### [CFB-3] Combat log surface style — **RESOLVED**
Opened on demand, not an always-open sidebar or overlay — consistent with the reconstruction-aid
role (`[CFB-9]`'s live choreography already carries the real-time channel).

**Merged with the rewind system, not a standalone panel.** The on-demand log shares its surface
with the existing round-0/round-start/activation history already tracked by
`MapLedger` (`scripts/save/MapLedger.gd` — `REASON_ROUND_START`/`REASON_ACTIVATION` reason-tagged
entries) and already presented to the player via `RewindSelector`
(`scripts/ui/RewindSelector.gd`, the shared map-menu/defeat-overlay retained-history picker). Each
ledger entry becomes a block in the unified view, marking a return point; `[CFB]` event-stream
content renders inside/between those blocks so a block is both "what happened" and "where you
could rewind to," not two separate UIs a player has to reconcile. This does not change
`MapLedger`'s push/prune/rewind mechanics (`persistence_undo_implementation_plan_2026-07-15.md`
Phase 2/3) — it is a consumer of the existing entries, not a new ledger.

**Implementation detail flagged, not blocking:** the `[CFB]` event record (`kind`/`source`/
`cause_id`/.../`outcome`) does not currently carry which `MapLedger` entry/index it occurred
within — an anchor field will need adding so events can be grouped under the correct block. Left
for the implementation pass, not re-litigated here.

**Seam reserved, not built:** an "extra seam for dialogue logs" — a future non-combat log content
type (conversation/dialogue history) rendering in the same on-demand panel alongside combat
blocks. No dialogue-log system exists yet to hang this on (not found under `TEXT-*` or elsewhere);
recorded here as forward intent for whoever builds it, not a `[CFB]` deliverable.

### [CFB-4] Log content symmetric with `PER-9`, or per-viewer — **RESOLVED**
Per-viewer, gated by the event record's existing `visible_to` field (`PER-9`'s two-channel
model, computed at emit time) — the same gate every other `[CFB]` channel already uses. No
separate rule for the log; resolved jointly with `[CFB-8]` below since they are the same question.

### [CFB-6] Status icon placement and interaction — **RESOLVED (design), blocked on build**
One small icon in a unit corner (not `[CFB-9]`'s above-head callout row), **cycling** through
every currently-active status one at a time rather than a multi-icon strip — the at-a-glance
tier is "something is active," not necessarily "everything active, all at once, unscaled." A new
section in the character sheet (`UnitDetailsScreen` or its successor) lists every active status
with a full-detail "more info" page per status — the on-demand/full tier. Still blocked on
`ConditionManager` leaving stub status (M8/M9) for actual implementation; the design does not
wait on that, matching how `[CFB-18]` was decided ahead of its own prerequisite (`[CSA-8]`).

### [CFB-7] Banner budget — **RESOLVED**
The budget is zero: **no combat event uses the banner channel.** Banners stay exactly as scoped
today — phase changes (`PhaseBanner`) and campaign rule flips (`RuleFlipNotification`) — and
`[CFB]` does not add a combat use case, not even for a revival or a signature-skill negation.
Those stay on the above-head callout channel (`[CFB-9]`)/combat log like any other event. The
research doc's proposed vocabulary listed a "rare/dramatic (owner-flagged) → banner" routing
branch for combat events; that branch is decided unused, not removed from the doc's narrative
text (the doc's own convention keeps `CFB-n` status here, not duplicated there), but the channel
taxonomy table there should be read with this resolution in mind — banner is not a live
destination for any `[CFB]` event under this decision.

### [CFB-8] Hidden-actor event redaction — **RESOLVED**
Same answer as `[CFB-4]`, decided jointly: gated by `visible_to`, not shown at all when a viewer's
units could not perceive it — no redacted placeholder line. An event a viewer's `PER-9` channel
does not clear does not exist for that viewer on any channel (floating text, log, banner, icon
alike), matching the "gate is evaluated once per event, not per channel" principle the interaction
skeleton already states.

### [CFB-13] Does disabling a notification category also skip its time budget? — **RESOLVED**
Confirmed 2026-08-08: disabling a category skips the beat entirely, not just its callout — the
choreography's per-category time budget is cut along with the visual/text when a player turns a
category off.

## Status

All eighteen `CFB-n` items are now **RESOLVED**. `SKF`/`CAU`/`DUX` packets have not been started —
`SKF`-adjacent choreography decisions above will need to be checked against `CAU`'s named action
family once that packet opens.
