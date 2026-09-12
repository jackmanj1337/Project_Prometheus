---
Role: dated
Type: design
Status: Proposed — vocabulary and interaction skeleton; owner walk in progress, see the register
Last verified: 2026-08-08
Tracker: DISCUSS-SKILL-STATUS-FEEDBACK-2026-07-23, DISCUSS-COMBAT-ACTIONS-UX-2026-07-24, DISCUSS-DIFFICULTY-DEATH-UX-2026-07-23
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Combat Feedback Vocabulary — Research and Interaction Skeleton

This is the shared `CFB` doc the 2026-08-07 handoff called for
([`combat_feedback_research_session_handoff_2026-08-07.md`](../plans/combat_feedback_research_session_handoff_2026-08-07.md)):
one vocabulary, written once, that `DISCUSS-SKILL-STATUS-FEEDBACK` (`SKF`),
`DISCUSS-COMBAT-ACTIONS-UX` (`CAU`), and `DISCUSS-DIFFICULTY-DEATH-UX` (`DUX`) all read rather
than each inventing its own. It does not itself close any of the three rows — the owner walk is
tracked in the follow-on register,
[`combat_feedback_vocabulary_open_questions_2026-08-07.md`](../registers/combat_feedback_vocabulary_open_questions_2026-08-07.md)
(started 2026-08-08), where `CFB-1..N`'s status actually lives (see `AGENT/Docs/REGISTERS.md`
conventions: this doc keeps `Type: design` deliberately, so it indexes correctly and does not get
mis-swept into the register catalog the way two earlier docs using a nonstandard `Type:` value
were — see the note
at the end).

## Scope and method

The question all three rows share: **when the engine does something to a unit that the player
did not directly command, how does the player learn that it happened, why, and to whom?**

This doc answers that question in the abstract — an event taxonomy, a channel taxonomy, an
attribution contract, and an interaction skeleton — and leaves per-family specifics (which
exact events `CAU`'s named actions raise, `SKF`'s per-skill copy, `DUX`'s New-Game surface) to
the packets built on top of it.

**Explicitly out of scope, per the handoff:** every mechanical register feeding this trio —
`SKL-1..6`, `LDC-1..9`, `DIF-1..7`, `DTH-1..12`, `STY-1..17`, `DSP-1..17`, `BAT-1..16`, `AGT`,
`SMV`, `RDR`/`CVR`/`RCT`, `VAL-1..13` — is RESOLVED and treated here as an input, not reopened.

External research was accessed 2026-08-07. No competitor artwork is reproduced; citations are
text-only observations used to inform, not to copy.

## The one thing to get right

**Two different vocabularies are needed, not one, and the codebase currently has zero of either.**

- **Event feedback** — something just happened (a skill activated, a counter fired, a status
  was applied, an effect was negated). Has a lifetime of seconds; the right channels are ones
  that appear and disappear (floating text, a log line, occasionally a banner).
- **State feedback** — something is currently true (a unit is Poisoned, is Provoked, has an
  active Pair-Up bonus). Has a lifetime of turns; the right channel is a persistent marker the
  player can check at a glance or on demand (a status icon, a panel).

Conflating them is the mistake this doc exists to prevent. A skill activating is an *event*; the
buff it leaves behind is *state*. Both need feedback, on different channels, and neither
currently has one — see the audit below.

**Second structural point:** the event taxonomy must be an **open, author-extensible vocabulary
that composes with the trigger vocabulary `SkillData.gd` already defines**
(`scripts/resources/SkillData.gd:5-11` — `passive|start_of_turn|on_attack|on_defend|on_hit|
on_kill|on_damaged|on_combat_start|on_combat_end|on_move|on_level_up|player_activated`, plus
Phase-2 triggers), **not a hardcoded per-kind `EventBus` signal added one at a time.** This is
the project's own standing architecture principle (`AGENTS.md`, Project_Prometheus section:
*"author-facing extension points are OPEN REGISTRIES, not closed type-switches"*) applied one
layer up: skills and statuses are exactly a vocabulary that will grow with content, so the
feedback layer describing them must grow by adding data, not by editing an engine `match`. One
generic tagged event, not N signals — detailed below.

## Comparable systems

| System | Observed behavior | Strength | Failure / mismatch | Prometheus question informed |
|---|---|---|---|---|
| Fire Emblem combat forecast | The pre-commit forecast shows stats, damage, hit%, crit% for both sides, but explicitly **does not** predict damage changes from skills or Specials — only the post-battle HP values account for them. [Combat forecast](https://fireemblemwiki.org/wiki/Combat_forecast) | Sets an honest expectation: the forecast is a floor, not a promise. | Players can be surprised by a skill's effect even though the forecast was "correct." | Whether Prometheus's own pre-combat preview should carry the same disclaimer, or try harder to fold skill effects in — a `CAU`/forecast-UI question, not decided here. |
| Into the Breach enemy-intent telegraphing | Every enemy action for the coming turn is shown before it happens; the developers cut interesting attack patterns specifically because they were hard to telegraph clearly. [UI design: "sacrifice cool ideas for clarity"](https://www.gamedeveloper.com/design/-i-into-the-breach-i-dev-on-ui-design-sacrifice-cool-ideas-for-the-sake-of-clarity-every-time-) | Total transparency before commitment; nothing about an engine-triggered effect is ever a surprise. | Total pre-commitment transparency is a much larger scope commitment than Prometheus's FE-style hidden-AI model supports without a redesign. | Motivates the visibility-gate question below (§ "nothing happened") rather than adopting full telegraphing. |
| Divinity: Original Sin 2 status icons + combat log | Status effects render as icons next to the portrait in and out of battle; a combat log exists, but vanilla lacks per-message-type filtering — that had to be added by a community mod (Epip). [Status effects](https://divinity.fandom.com/wiki/Status_Effects_(Divinity:_Original_Sin)), [Epip combat-log filtering](https://www.pinewood.team/epip/) | Confirms status-as-icon and event-as-log as two separate, standard channels — matches the split above. | An unfiltered log degrades once event volume rises (exactly the clutter risk called out in the open questions below). | Motivates deciding filtering/volume control up front rather than retrofitting it. |
| XCOM 2 shot-chance breakdown | Both XCOM and XCOM 2 let the player inspect *why* a hit chance is what it is, before committing to the shot. [Shot breakdown feature](https://www.nexusmods.com/xcom2/mods/121) | Attribution-before-commitment for the one number players care about most. | Vanilla exposes this only for the player's own shots, not for reconstructing what an enemy's completed action did or why — no equivalent post-hoc explanation. | Reinforces that a **combat log** (post-hoc, not just pre-commit) is the missing piece for Prometheus, especially for AI turns. |
| Fell Seal: Arbiter's Mark counters | Each class has one equippable counter ability (e.g. evade-all, counter-ranged-with-basic-attack), single-slot regardless of source class. [Counters](https://fellseal.fandom.com/wiki/Counters) | Closest genre analogue to Prometheus's own `RCT`/`CVR`/`RDR` interceptor family. | Available sources did not surface how (or whether) a counter trigger is called out distinctly from a normal attack in its UI — an evidence gap, not a finding; flag rather than assume. | Prometheus cannot assume "counters are just attacks, no special feedback needed" is safe without deciding it explicitly — see attribution contract below. |

**Comparative conclusion:** no comparable system solves this with one channel. Every one splits
pre-commit prediction, in-the-moment event feedback, and persistent status display into distinct
surfaces. Prometheus's gap is that it currently has a fragment of the first (partial forecast,
per `CVR-4`) and a fragment of the second (floating text, HP-only) and none of the third.

## Current-state interaction audit

Exact anchors below describe the branch at `6adb33d`.

| Channel / system | Current state | Gap |
|---|---|---|
| Floating text (`CombatHUD.gd`) | `CanvasLayer` spawning transient `Label`s; listens only to `EventBus.combat_resolved` and `unit_healed` (`CombatHUD.gd:8-9`); reads `exchange.hit/.damage/.crit` (`:13-24`); spawn/tween/fade `:31-47`. | Scoped to HP mutation only. No skill, status, counter, or immunity feeds it. |
| Combat log | **Does not exist.** `TransitionTelemetry.gd` records `combat_resolved` for debug telemetry (`:33,228-231`) but is not player-facing. | The one channel every comparable system above treats as necessary is entirely absent. |
| Banners (`PhaseBanner.gd`, `RuleFlipNotification.gd`) | Reserved for phase changes (`EventBus.phase_changed`) and rule flips (`EventBus.campaign_rule_flipped`); suppressible/auto-hiding. | Not wired to any skill/status/counter event; correctly scarce today, a budget worth preserving deliberately (see open questions). |
| Unit panel / status icons | **Does not exist.** Buffs/debuffs are text-only, and only inside the deliberately-opened `UnitDetailsScreen._format_mods_block` (`:580-604`) — no on-field iconography, no hover/tooltip during play. `ConditionManager.gd` is an explicit all-stub autoload: every method (`apply_condition`, `remove_condition`, `tick_conditions`, `has_condition`, `clear_all_conditions`) is `pass`/`return false` "until M8" (`ConditionManager.gd:3,14-33`). | State feedback has no substrate to render *from* yet, independent of any UI decision. |
| Skill/status apply sites | `SkillHandler._dispatch` (`:27-118`) has **zero `EventBus` references in the file**. Every handler (`_apply_renewal`, `_apply_wrath`, `_apply_faire`, etc.) mutates a passed `context` dict silently and returns `bool`. ~30 entries route to `_apply_unimplemented` (`:48-82`), which `push_warning`s once and no-ops (`:494-501`) — an engine-completeness stub, not a feedback gap. | Even fully-implemented skill effects (`_apply_renewal`, `_apply_wrath`, ...) are silent today; there is no apply-site hook to remove once M9 lands, only one to add. |
| `EventBus` signal roster | 29 signals (`EventBus.gd:6-120`): unit lifecycle, `combat_resolved`, phase/campaign-rule, promotion/reclass, pair-up, fog, victory/defeat. **No** `skill_activated`, `status_applied`, `counter_fired`, `immunity_absorbed`, or equivalent exists. | Confirms the "add one generic tagged event, not N signals" recommendation is a real choice being made now, not a retrofit later. |
| Attribution | `combat_resolved`'s `exchanges` carry `attacker`/`defender`/`weapon`, but `CombatHUD` only reads damage/crit/miss from it — the weapon/skill name is discarded before rendering (`CombatHUD.gd:16-24`). The only place a *cause* is named in text is `UnitDetailsScreen._format_mods_block` (`:584-592`), inside an opened inspection screen, not live play. `CVR-4` (`cover_intercept_open_questions_2026-06-26.md:82-88`) already requires a redirected hit to visibly show the actual (protector) defender pre-commit — a **designed but unbuilt** attribution requirement. | Attribution exists in exactly one data path today (`CVR-4`, on paper) and zero rendered paths. |
| AI-driven vs. player-driven parity | Both paths converge on one resolver (`CombatResolver.resolve_combat`/`apply_combat_result`, `:1283,1439`). The only AI-specific signal is `ai_unit_acting`, consumed solely to pan the camera (`GameMap.gd:132,211`; `EnemyAI.gd:70-74`). | No asymmetry to preserve or fix beyond camera-follow — a clean starting condition (see principle below). |
| Fog of war / perception | Not part of the audit's file list, but load-bearing: `PER-9` (RESOLVED) defines a **two-channel** forecast-fidelity model — player-view vs. AI-view, communicated via a `CampaignRules` constant, with a debug reveal-all override (`perception_masking_open_questions_2026-06-27.md:131`, sibling of `[FOW-3]`). | Any new event channel (log line, banner) about a currently-not-visible unit must compose with this, not bypass it — an info leak risk noted explicitly in the open questions below. |

## Proposed vocabulary

### Event record (open taxonomy, one shape)

A combat-feedback event is one record, not one signal per kind:

```
kind        : String   # reuses/extends SkillData.trigger's vocabulary — data, not enum
source      : Node      # the acting unit, or null for a non-unit cause (terrain, item)
cause_id    : String    # skill id / item id / effect id — the "why"
target      : Node       # primary affected unit
targets     : Array      # for multi-target effects (gambits, AoE)
magnitude   : Variant   # optional — damage/heal amount, stat delta; absent for non-numeric events
outcome     : String    # "applied" | "negated" | "no_effect" | "failed_to_proc"
visible_to  : per PER-9's two-channel model — computed at emit time, not at render time
```

One `EventBus.combat_feedback(event: Dictionary)` signal (or a small typed `Resource`, matching
how `SkillData` itself is authored) replaces the instinct to add `skill_activated`,
`counter_fired`, `immunity_absorbed`, etc. as separate signals. New skill/status content adds new
`kind`/`cause_id` values, never a new signal or a new `match` arm in a UI script — the same
discipline `SkillData.trigger` already models.

### Channel taxonomy and a selection rule

| Channel | Lifetime | Best for | Build status |
|---|---|---|---|
| Floating text | ~1s, unit-anchored | Numeric, single-target, instant (damage/heal deltas from a skill, a poison tick) | Exists (`CombatHUD`), scope needs widening to the new generic event |
| Combat log | Persistent, reviewable | Anything needing attribution, anything happening off-screen or during an AI turn, anything without one number to float | Does not exist — the one clear gap every comparable system flags |
| Status icon / unit panel | Turns, until removed | *State*, not events — "this is currently true" | Does not exist; blocked on `ConditionManager` leaving stub status (M8/M9), a `B5`-side dependency this doc does not reopen |
| Banner | Seconds, blocking-adjacent | Rare, dramatic, campaign-significant (a revival, a full negation of a signature skill) | Exists as a pattern (`PhaseBanner`/`RuleFlipNotification`); budget must stay small or it stops meaning "significant" |

Proposed default rule: route by `outcome` and `magnitude` presence — numeric + single-target →
floating text; anything else that resolved → log line (floating text may *also* fire, doesn't
replace the log); `negated`/`no_effect` → log line always, floating text only if magnitude would
otherwise have been visible (see below); state changes → icon, never floating text or log alone.

### The "nothing happened" case deserves feedback

An **immunity or negation** is the highest-value case precisely because absence of an effect is
invisible by default. `SkillData`'s own `on_combat_start_negate` pre-pass (`:8-9`, reserved for
cancellers like Nihil) is a concrete existing mechanism that can silently prevent another skill
from firing. If the player used an item or the engine attempted an effect and it was blocked,
saying nothing reads as a bug, not as "working as intended." This is the case genre research
above did not surface any comparable system covering as its own headline, and Prometheus should
not skip it by default.

### The "didn't proc" case is a genuine open question, not a default

`SkillData.activation_chance_stat`/`activation_divisor` (`:12-14`) model a real per-skill
activation roll — a die that can miss even though nothing was blocked. Unlike immunity, no
external cause explains the non-event; "nothing happened" may just mean "nothing happened."
Whether that deserves any feedback at all (a floating "—", a log line, or genuine silence) is
left to the owner walk below rather than decided here.

### Attribution contract

Owed, at minimum, whenever an event resolves with an `outcome` other than `failed_to_proc`:
source unit + `cause_id`'s display name. When an interceptor family (`RDR`/`CVR`/`RCT`)
redirects or substitutes the target, the *actual* resolved target must be shown, not the
originally-targeted one — this is not a new requirement, it is `CVR-4` finally getting a render
path.

### AI-driven vs. player-driven parity

**Principle: feedback is channel-driven, not actor-driven.** The audit found no existing
asymmetry to design around beyond camera-follow (`ai_unit_acting`), and the resolver is already
unified. The same event taxonomy, the same channel-selection rule, fires regardless of who
triggered it. Camera-pan-to-actor stays AI-specific (the player already looks where they
clicked); nothing else should fork.

## Interaction skeleton

```mermaid
flowchart TD
  eff[Engine effect resolves\nskill / status tick / counter / interceptor] --> tag[Tag one event record\nkind, source, cause_id, target, magnitude, outcome]
  tag --> gate{Visible under PER-9\ntwo-channel model?}
  gate -- No --> drop[No channel fires\n(or a redacted log line — open question)]
  gate -- Yes --> route{Route by outcome + magnitude}
  route -- numeric, single target --> float[Floating text]
  route -- anything resolved --> log[Combat log line]
  route -- negated / no_effect --> logonly[Combat log line\n+ floating text only if a number would have shown]
  route -- state change --> icon[Status icon updates]
  route -- rare/dramatic (owner-flagged) --> banner[Banner]
  float --> done([Rendered])
  log --> done
  logonly --> done
  icon --> done
  banner --> done
```

Every node above composes with, and does not replace, `PER-9`'s existing visibility model —
the gate is evaluated once per event, not per channel.

## What this doc deliberately does not settle

Per-row scope stays with the packets, per the handoff's own table:

- **`SKF`** — per-skill/status copy, the combat log's exact content grammar, activation/passive/
  counter/immunity/failure wording.
- **`CAU`** — targeting/selection/feedback UX for the named action family (combat arts, gambits,
  reposition/shove/swap/pivot, dancer/refresh, secondary movement, rescue, utility staves); may
  split per-action when picked up.
- **`DUX`** — New Game placement/copy/defaults/warnings/mutability for difficulty and death mode,
  not the modes themselves (`DIF-1..7`).

## Open questions for the owner walk

Numbered and tracked as `CFB-n` in the follow-on register,
[`combat_feedback_vocabulary_open_questions_2026-08-07.md`](../registers/combat_feedback_vocabulary_open_questions_2026-08-07.md)
— that register is the live source of truth for status; this section is deliberately not
duplicated here so the two documents cannot drift apart. The first owner walk (2026-08-08) already
resolved several of the original eight questions and added ten more from a concrete choreography
proposal (the above-head skill callout + directional attack animation model); one item (animation
composition/reuse hooks) was explicitly deferred to next-session research rather than decided
without enough information.

## Later validation fixtures

Once channels exist: a turn with zero engine-triggered events (log stays empty, not blank-with-
error); a turn with 10+ stacked events on one unit (counter → redirect → status apply → floating
text collision); an AI turn with an immunity the player cannot see resolve live (log is the only
route); a hidden-unit event under both `PER-9` channels; long/localized skill and status names in
the log and on icon tooltips; controller/keyboard access to a non-modal combat log during the
opponent's turn without stealing input focus from the map.

---

**Note on `Type:` values.** `campaign_library_ux_research_2026-07-23.md`,
`campaign_library_ux_decisions_2026-07-24.md`, and `campaign_library_owner_questions_2026-07-23.md`
use `Type: design research` / `Type: design decisions` / `Type: owner decision packet` —
none of which match `gen_docs_index.py`'s canonical type taxonomy (`guide, governance,
decision-record, register, design, plan, playtest, handoff, reference`). An explicit `Type:`
fence always wins over the heuristic, so these three docs are silently absent from both
`INDEX.md` and `REGISTERS.md` today. Not fixed here — flagged for a separate small pass — but
this doc and its planned follow-on register use `design` and `register` respectively so as not
to add a fourth.
